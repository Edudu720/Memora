package br.fatec.memora.autenticacao.aplicacao;

import br.fatec.memora.autenticacao.dominio.ResultadoDoEvento;
import br.fatec.memora.autenticacao.dominio.TipoDeEvento;
import br.fatec.memora.autenticacao.infra.RepositorioSessao;
import br.fatec.memora.comum.RegistroDeAuditoria;
import java.time.Clock;
import java.time.Instant;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Encerra a sessão deste aparelho (T074, FR-024, FR-026).
 *
 * <h2>Revoga a família, não a linha</h2>
 *
 * A renovação cria uma linha de sessão nova a cada rotação, e a antiga fica
 * marcada como substituída. Revogar só a linha atual deixaria a família de pé
 * para o {@code ServicoDeSessao}, que decide pela linhagem — e o refresh token
 * que o aplicativo tem em mãos continuaria valendo por 60 dias.
 *
 * <p>Sair precisa significar sair. {@code revogarFamilia} é a operação que
 * corresponde a "este aparelho, desde que entrou".
 *
 * <h2>Por que não revoga todas as sessões da pessoa</h2>
 *
 * Porque a FR-024 pede "sair da conta", e a pessoa está saindo <b>deste</b>
 * aparelho. Derrubar o tablet dela junto com o celular é outra funcionalidade —
 * legítima, e provavelmente desejável um dia — mas ela precisa ser pedida, não
 * acontecer por efeito colateral. Quem quer derrubar tudo hoje troca a senha:
 * é isso que {@code ServicoDeRecuperacao} faz, de propósito.
 *
 * <h2>Sair é idempotente</h2>
 *
 * Chamar duas vezes não é erro. A segunda chamada não encontra sessão viva e
 * responde igual — o aplicativo pode ter perdido a resposta da primeira, e uma
 * segunda tentativa que falhasse deixaria a pessoa presa numa tela de saída que
 * não termina. Para quem não conseguiu sair, o pior desfecho não é sair duas
 * vezes; é continuar dentro.
 */
@Service
public class ServicoDeSaida {

    private final RepositorioSessao sessoes;
    private final RegistroDeAuditoria auditoria;
    private final Clock relogio;

    public ServicoDeSaida(
            RepositorioSessao sessoes, RegistroDeAuditoria auditoria, Clock relogio) {
        this.sessoes = sessoes;
        this.auditoria = auditoria;
        this.relogio = relogio;
    }

    /**
     * Encerra a sessão da família informada.
     *
     * <p>Quando {@code familiaId} é {@code null} — token emitido antes de a
     * T074 existir e ainda válido —, <b>todas</b> as sessões da pessoa são
     * revogadas. É o comportamento seguro para o caso ambíguo: na dúvida sobre
     * qual aparelho encerrar, encerrar demais protege; encerrar de menos deixa
     * alguém conectado achando que saiu. A janela é de 15 minutos, uma única vez,
     * na implantação.
     *
     * @param familiaId a linhagem a encerrar, ou {@code null}
     */
    @Transactional
    public void sair(UUID pessoaId, UUID familiaId) {
        Instant agora = relogio.instant();

        if (familiaId == null) {
            sessoes.revogarSessoesDaPessoa(pessoaId, agora);
        } else {
            sessoes.revogarFamiliaDaPessoa(familiaId, pessoaId, agora);
        }

        auditoria.registrar(pessoaId, TipoDeEvento.SAIDA, ResultadoDoEvento.SUCESSO, agora);
    }
}

package br.fatec.memora.autenticacao.aplicacao;

import br.fatec.memora.autenticacao.dominio.CanalContato;
import br.fatec.memora.autenticacao.dominio.EstadoDaConta;
import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioCanalContato;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.seguranca.ServicoDeSessao;
import br.fatec.memora.comum.ContextoDaRequisicao;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Renovação de sessão pelo refresh token (T048, FR-016).
 *
 * <h2>O que esta classe acrescenta ao {@link ServicoDeSessao}</h2>
 *
 * A rotação, a detecção de reuso e a revogação da família já são dele (T019).
 * Aqui se resolve o que falta para a resposta do contrato: <b>quem</b> é a
 * pessoa daquela sessão, com os canais dela, no formato de
 * {@link SessaoDaPessoa}.
 *
 * <h2>O motivo da recusa morre aqui dentro</h2>
 *
 * {@link ServicoDeSessao.MotivoDaRecusa} distingue token desconhecido, reuso,
 * sessão revogada e token expirado — para a <b>auditoria</b>. Nenhum deles
 * atravessa esta classe em direção ao cliente: a resposta é a mesma nos quatro
 * casos. Informar que o motivo foi "reuso detectado" contaria a quem roubou o
 * token que ele um dia foi válido, e que a conta existe.
 *
 * <h2>Por que a pessoa é procurada, e não presumida</h2>
 *
 * O cadastro devolve <b>sessão-chamariz</b> quando o canal já pertence a alguém:
 * um JWT assinado de verdade para um UUID que não existe (ver
 * {@link ServicoDeCadastro}). A regra que mantém isso seguro é que todo caminho
 * autenticado resolva o sujeito e recuse quando não encontrar — <b>assinatura
 * válida não é autorização</b>.
 *
 * <p>Neste endpoint a proteção principal é outra: o refresh do chamariz nunca é
 * gravado, então ele já morre em {@code TOKEN_DESCONHECIDO}. A busca da pessoa
 * abaixo é a segunda tranca, para o dia em que uma sessão sobreviver à conta.
 */
@Service
public class ServicoDeRenovacao {

    private static final Logger LOG = LoggerFactory.getLogger(ServicoDeRenovacao.class);

    private final ServicoDeSessao sessoes;
    private final RepositorioPessoaUsuaria pessoas;
    private final RepositorioCanalContato canais;
    private final Clock relogio;

    public ServicoDeRenovacao(
            ServicoDeSessao sessoes,
            RepositorioPessoaUsuaria pessoas,
            RepositorioCanalContato canais,
            Clock relogio) {
        this.sessoes = sessoes;
        this.pessoas = pessoas;
        this.canais = canais;
        this.relogio = relogio;
    }

    /**
     * O desfecho da renovação.
     *
     * <p>{@link Recusada} não carrega motivo, pelo que está explicado no
     * cabeçalho desta classe.
     */
    public sealed interface Resultado {

        record Renovada(SessaoDaPessoa sessao) implements Resultado {}

        record Recusada() implements Resultado {}
    }

    /** Rotaciona o token apresentado, ou recusa. */
    @Transactional
    public Resultado renovar(String refreshApresentado) {
        Instant agora = relogio.instant();
        String origemHash = ContextoDaRequisicao.atual().origemHash();

        ServicoDeSessao.ResultadoDaRenovacao resultado =
                sessoes.renovar(refreshApresentado, origemHash, agora);

        if (!(resultado instanceof ServicoDeSessao.ResultadoDaRenovacao.Renovada renovada)) {
            return new Resultado.Recusada();
        }

        ServicoDeSessao.SessaoEmitida sessao = renovada.sessao();
        Optional<PessoaUsuaria> pessoa = pessoas.findById(sessao.pessoaId());

        if (pessoa.isEmpty()) {
            // Nao deveria acontecer: fk_sessao_pessoa garante o vinculo. Se
            // acontecer, e defeito nosso — e o certo e recusar, nao devolver
            // sessao para uma conta que ninguem consegue mais identificar.
            LOG.error("Sessao renovada sem conta correspondente. Investigar o vinculo.");
            return new Resultado.Recusada();
        }

        // Compara com DESATIVADA em vez de usar permiteEntrar(): conta
        // PENDENTE_VERIFICACAO PRECISA renovar. Ela nao entra pela porta da
        // frente (ServicoDeEntrada recusa), mas esta no meio de confirmar o
        // canal, e o token de acesso vale 15 minutos. Recusar a renovacao aqui
        // deixaria sem sessao quem demorasse mais que isso para digitar o
        // codigo — e sem saida, porque o canal ja esta ocupado pela propria
        // conta pendente e um novo cadastro cairia no chamariz da FR-010. A
        // pessoa ficaria permanentemente fora, com o e-mail dela queimado.
        if (pessoa.get().getEstado() == EstadoDaConta.DESATIVADA) {
            // Simetria com o ServicoDeEntrada, e nao zelo extra: sem esta linha,
            // desativar a conta fecharia so a porta da frente. Quem ja tem o
            // refresh continuaria rotacionando a cada 15 min, e como a rotacao
            // reinicia os 60 dias de VALIDADE_DO_REFRESH, o acesso nunca
            // terminaria.
            //
            // A rotacao acima ja foi confirmada: o token velho morreu e o novo
            // nao chega a quem chamou, entao a familia fica orfa. Insistir com o
            // token velho cai na deteccao de reuso e derruba a familia inteira.
            return new Resultado.Recusada();
        }

        List<CanalContato> daPessoa = canais.findByPessoaId(sessao.pessoaId());

        return new Resultado.Renovada(SessaoDaPessoa.de(pessoa.get(), daPessoa, sessao));
    }
}

package br.fatec.memora.autenticacao.aplicacao;

import br.fatec.memora.autenticacao.dominio.EstadoDaConta;
import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioEventoAutenticacao;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Expurga contas assistidas abandonadas em {@link EstadoDaConta#PENDENTE_VERIFICACAO}
 * após o prazo de expiração (T065b, FR-004 a FR-007 da Feature 006).
 *
 * <h2>Por que este serviço existe</h2>
 *
 * No cadastro assistido (FR-062), a conta nasce {@code PENDENTE_VERIFICACAO} até
 * que a posse do canal seja confirmada. Se a pessoa ou o familiar abandonar o
 * aplicativo antes de digitar o código de 6 dígitos, o canal permanece ocupado.
 * Quando ela tenta se cadastrar novamente no dia seguinte com o mesmo e-mail ou
 * telefone, caía indefinidamente na resposta chamariz (FR-010) e não conseguia
 * entrar nem criar outra conta.
 *
 * <p>Este serviço libera o canal de duas formas complementares:
 *
 * <ol>
 *   <li><b>Sob demanda no cadastro</b> ({@link #expurgarSeExpirada(UUID, Instant)}):
 *       chamado por {@link ServicoDeCadastro} estritamente <i>após</i> o cálculo em
 *       tempo constante do hash Argon2id da senha. Se a conta dona do canal ainda
 *       estiver {@code PENDENTE_VERIFICACAO} e tiver mais de 24 horas, ela é
 *       expurgada na mesma transação e o novo cadastro prossegue normalmente. Contas
 *       {@code ATIVA} ou pendentes recentes ({@code <= 24h}) continuam recebendo o
 *       chamariz da FR-010.
 *   <li><b>Rotina agendada em background</b> ({@link #expurgarContasPendentesVencidas()}):
 *       remove periodicamente contas {@code PENDENTE_VERIFICACAO} vencidas que não
 *       sofreram nova tentativa de cadastro, evitando retenção indefinida de dados
 *       pessoais não confirmados.
 * </ol>
 *
 * <h2>Ordem de exclusão no banco</h2>
 *
 * As tabelas {@code canal_contato}, {@code sessao} e {@code codigo_verificacao}
 * possuem {@code ON DELETE CASCADE} apontando para {@code pessoa_usuaria(id)}.
 * Já {@code evento_autenticacao} possui {@code fk_evento_pessoa} <b>sem</b> cascata
 * (e seu gatilho {@code tg_evento_somente_insercao} bloqueia apenas {@code UPDATE}).
 * Por isso, o expurgo apaga primeiro os eventos daquela conta pendente e em seguida
 * remove {@code pessoa_usuaria} com {@code flush()} imediato.
 */
@Service
public class ServicoDeExpurgoDeContaPendente {

    private static final Logger LOG =
            LoggerFactory.getLogger(ServicoDeExpurgoDeContaPendente.class);

    private final RepositorioPessoaUsuaria pessoas;
    private final RepositorioEventoAutenticacao eventos;
    private final Clock relogio;
    private final Duration validadeMaximaPendente;

    @Autowired
    public ServicoDeExpurgoDeContaPendente(
            RepositorioPessoaUsuaria pessoas,
            RepositorioEventoAutenticacao eventos,
            Clock relogio,
            @Value("${memora.conta.expiracao-pendente:24h}") Duration validadeMaximaPendente) {
        this.pessoas = pessoas;
        this.eventos = eventos;
        this.relogio = relogio;
        this.validadeMaximaPendente = validadeMaximaPendente;
    }

    /**
     * Verifica se a conta identificada por {@code pessoaId} está em
     * {@link EstadoDaConta#PENDENTE_VERIFICACAO} há mais de {@code validadeMaximaPendente}
     * (24h por padrão) e, em caso afirmativo, expurga-a imediatamente.
     *
     * @return {@code true} se a conta estava pendente e expirada e foi expurgada;
     *         {@code false} se a conta está {@code ATIVA} ou ainda dentro da janela
     */
    @Transactional
    public boolean expurgarSeExpirada(UUID pessoaId, Instant agora) {
        Optional<PessoaUsuaria> pessoa = pessoas.findById(pessoaId);
        if (pessoa.isEmpty()) {
            return false;
        }
        return expurgarSeExpirada(pessoa.get(), agora);
    }

    /**
     * Avalia e expurga a conta caso esteja em {@link EstadoDaConta#PENDENTE_VERIFICACAO}
     * e tenha sido criada antes de {@code agora.minus(validadeMaximaPendente)}.
     */
    @Transactional
    public boolean expurgarSeExpirada(PessoaUsuaria pessoa, Instant agora) {
        if (pessoa.getEstado() != EstadoDaConta.PENDENTE_VERIFICACAO) {
            return false;
        }
        Instant limite = agora.minus(validadeMaximaPendente);
        if (!pessoa.getCriadaEm().isBefore(limite)) {
            return false;
        }
        expurgarContaPendente(pessoa);
        return true;
    }

    /**
     * Expurga uma conta que comprovadamente está em {@link EstadoDaConta#PENDENTE_VERIFICACAO}.
     */
    @Transactional
    public void expurgarContaPendente(UUID pessoaId) {
        pessoas.findById(pessoaId).ifPresent(this::expurgarContaPendente);
    }

    /**
     * Executa a remoção transacional na ordem exigida pelas chaves estrangeiras.
     */
    @Transactional
    public void expurgarContaPendente(PessoaUsuaria pessoa) {
        if (pessoa.getEstado() != EstadoDaConta.PENDENTE_VERIFICACAO) {
            throw new IllegalStateException(
                    "Recusado expurgar conta que nao esta em PENDENTE_VERIFICACAO.");
        }
        UUID id = pessoa.getId();
        eventos.deletarPorPessoaId(id);
        pessoas.delete(pessoa);
        pessoas.flush();
    }

    /**
     * Rotina agendada que expurga em lote contas {@code PENDENTE_VERIFICACAO}
     * vencidas há mais de 24 horas (FR-006).
     */
    @Scheduled(
            fixedDelayString = "${memora.conta.expurgo-intervalo-ms:3600000}",
            initialDelayString = "${memora.conta.expurgo-atraso-inicial-ms:60000}")
    @Transactional
    public int expurgarContasPendentesVencidas() {
        Instant limite = relogio.instant().minus(validadeMaximaPendente);
        return expurgarContasPendentesAnterioresA(limite);
    }

    /**
     * Expurga todas as contas {@link EstadoDaConta#PENDENTE_VERIFICACAO} criadas
     * antes do instante {@code limite}.
     *
     * @return quantidade de contas pendentes expurgadas
     */
    @Transactional
    public int expurgarContasPendentesAnterioresA(Instant limite) {
        List<PessoaUsuaria> vencidas =
                pessoas.buscarContasPorEstadoAnterioresA(
                        EstadoDaConta.PENDENTE_VERIFICACAO, limite);
        for (PessoaUsuaria conta : vencidas) {
            expurgarContaPendente(conta);
        }
        if (!vencidas.isEmpty()) {
            LOG.info(
                    "Expurgo agendado removeu {} conta(s) pendente(s) expirada(s).",
                    vencidas.size());
        }
        return vencidas.size();
    }
}

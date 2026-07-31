package br.fatec.memora.comum;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import br.fatec.memora.autenticacao.dominio.EventoAutenticacao;
import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.dominio.ResultadoDoEvento;
import br.fatec.memora.autenticacao.dominio.TipoDeEvento;
import br.fatec.memora.autenticacao.infra.RepositorioEventoAutenticacao;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.suporte.TesteComBanco;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Trilha de auditoria da autenticacao (T025, FR-039 e FR-040).
 *
 * <p>Contra PostgreSQL real, porque parte do que se verifica aqui e
 * transacional: um teste com banco em memoria e transacao de teste aprovaria o
 * caso que este arquivo existe para reprovar.
 */
@DisplayName("Registro de auditoria")
class RegistroDeAuditoriaTest extends TesteComBanco {

    /** Truncado para microssegundos: e a precisao do TIMESTAMPTZ. */
    private static final Instant AGORA = Instant.now().truncatedTo(ChronoUnit.MICROS);

    @Autowired private RegistroDeAuditoria auditoria;

    @Autowired private RepositorioEventoAutenticacao eventos;

    @Autowired private RepositorioPessoaUsuaria pessoas;

    @Autowired private PlatformTransactionManager gerenciadorDeTransacao;

    @AfterEach
    void limpar() {
        eventos.deleteAll();
        pessoas.deleteAll();
        ContextoDaRequisicao.limpar();
    }

    @Nested
    @DisplayName("Cobertura dos eventos")
    class Cobertura {

        /**
         * A FR-039 exige registrar <b>todo</b> evento de autenticacao. Este teste
         * percorre o enum inteiro: tipo novo acrescentado no futuro entra aqui
         * sozinho, e se o esquema nao aceitar, falha na hora.
         */
        @ParameterizedTest
        @EnumSource(TipoDeEvento.class)
        @DisplayName("todo tipo previsto pode ser registrado")
        void todoTipoPodeSerRegistrado(TipoDeEvento tipo) {
            PessoaUsuaria pessoa = pessoaSalva();

            EventoAutenticacao gravado =
                    auditoria.registrar(pessoa.getId(), tipo, ResultadoDoEvento.SUCESSO, AGORA);

            assertThat(eventos.findById(gravado.getId())).isPresent();
        }

        @ParameterizedTest
        @EnumSource(ResultadoDoEvento.class)
        @DisplayName("os dois desfechos sao registraveis")
        void ambosOsDesfechos(ResultadoDoEvento resultado) {
            auditoria.registrarSemConta(TipoDeEvento.FALHA_ENTRADA, resultado, AGORA);

            assertThat(eventos.findAll()).singleElement().satisfies(
                    evento -> assertThat(evento.getResultado()).isEqualTo(resultado));
        }

        @Test
        @DisplayName("tentativa contra conta inexistente e registrada sem id de conta")
        void semContaNaoInventaId() {
            auditoria.registrarSemConta(
                    TipoDeEvento.FALHA_ENTRADA, ResultadoDoEvento.FALHA, AGORA);

            assertThat(eventos.findAll())
                    .singleElement()
                    .satisfies(evento -> assertThat(evento.getPessoaId()).isNull());
        }
    }

    @Nested
    @DisplayName("Origem de rede")
    class Origem {

        @Test
        @DisplayName("vem do contexto da requisicao, ja resumida")
        void vemDoContexto() {
            ContextoDaRequisicao.definir(
                    new ContextoDaRequisicao("trace", "request", "resumo-da-origem"));

            auditoria.registrarSemConta(TipoDeEvento.ENTRADA, ResultadoDoEvento.SUCESSO, AGORA);

            assertThat(eventos.findAll())
                    .singleElement()
                    .satisfies(
                            evento ->
                                    assertThat(evento.getOrigemHash())
                                            .isEqualTo("resumo-da-origem"));
        }

        /**
         * Tarefa agendada e teste de unidade rodam fora de requisicao HTTP.
         * Perder a origem nesse caso e aceitavel; perder o evento nao seria.
         */
        @Test
        @DisplayName("fora de uma requisicao, o evento e gravado mesmo sem origem")
        void semRequisicaoAindaGrava() {
            auditoria.registrarSemConta(TipoDeEvento.SAIDA, ResultadoDoEvento.SUCESSO, AGORA);

            assertThat(eventos.findAll())
                    .singleElement()
                    .satisfies(evento -> assertThat(evento.getOrigemHash()).isNull());
        }
    }

    @Nested
    @DisplayName("Sobrevivencia ao rollback")
    class Rollback {

        /**
         * O caso que justifica {@code REQUIRES_NEW}. Uma entrada recusada desfaz
         * a transacao da operacao; se o registro da recusa fosse junto, a trilha
         * ficaria cega exatamente para o que ela existe para enxergar.
         */
        @Test
        @DisplayName("evento de recusa sobrevive a operacao desfeita")
        void recusaSobrevive() {
            TransactionTemplate transacao = new TransactionTemplate(gerenciadorDeTransacao);

            assertThatThrownBy(
                            () ->
                                    transacao.executeWithoutResult(
                                            status -> {
                                                auditoria.registrarMesmoComRollback(
                                                        null,
                                                        TipoDeEvento.FALHA_ENTRADA,
                                                        ResultadoDoEvento.FALHA,
                                                        AGORA);
                                                throw new IllegalStateException(
                                                        "operacao falhou depois de auditar");
                                            }))
                    .isInstanceOf(IllegalStateException.class);

            assertThat(eventos.findAll())
                    .singleElement()
                    .satisfies(
                            evento ->
                                    assertThat(evento.getTipo())
                                            .isEqualTo(TipoDeEvento.FALHA_ENTRADA));
        }

        /**
         * O complemento, e a razao de existirem dois metodos: o registro comum
         * <b>acompanha</b> a transacao. Sucesso desfeito nao pode deixar rastro
         * de sucesso.
         */
        @Test
        @DisplayName("evento comum e desfeito junto com a operacao")
        void comumEDesfeito() {
            TransactionTemplate transacao = new TransactionTemplate(gerenciadorDeTransacao);

            assertThatThrownBy(
                            () ->
                                    transacao.executeWithoutResult(
                                            status -> {
                                                auditoria.registrarSemConta(
                                                        TipoDeEvento.CADASTRO,
                                                        ResultadoDoEvento.SUCESSO,
                                                        AGORA);
                                                throw new IllegalStateException(
                                                        "operacao falhou depois de auditar");
                                            }))
                    .isInstanceOf(IllegalStateException.class);

            assertThat(eventos.findAll()).isEmpty();
        }
    }

    @Nested
    @DisplayName("FR-040 — nada sensivel na trilha")
    class NadaSensivel {

        /**
         * A garantia e estrutural, nao textual: nao existe assinatura em
         * {@link RegistroDeAuditoria} que aceite segredo. Este teste fixa o que
         * a coluna guarda, para que uma coluna nova de conteudo livre nao entre
         * despercebida.
         */
        @Test
        @DisplayName("o evento gravado so carrega quem, o que, o desfecho e quando")
        void apenasOsCamposPrevistos() {
            PessoaUsuaria pessoa = pessoaSalva();
            ContextoDaRequisicao.definir(new ContextoDaRequisicao("t", "r", "origem"));

            EventoAutenticacao gravado =
                    auditoria.registrar(
                            pessoa.getId(),
                            TipoDeEvento.ENTRADA,
                            ResultadoDoEvento.SUCESSO,
                            AGORA);

            assertThat(gravado.toString())
                    .doesNotContain("origem")
                    .doesNotContain("$argon2id");

            List<EventoAutenticacao> trilha = eventos.findAll();
            assertThat(trilha).singleElement().satisfies(
                    evento -> {
                        assertThat(evento.getPessoaId()).isEqualTo(pessoa.getId());
                        assertThat(evento.getTipo()).isEqualTo(TipoDeEvento.ENTRADA);
                        assertThat(evento.getResultado()).isEqualTo(ResultadoDoEvento.SUCESSO);
                        assertThat(evento.getOcorridoEm()).isEqualTo(AGORA);
                    });
        }
    }

    private PessoaUsuaria pessoaSalva() {
        return pessoas.save(new PessoaUsuaria("Ana", "$argon2id$hash-ficticio", AGORA));
    }
}

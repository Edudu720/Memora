package br.fatec.memora.autenticacao.seguranca;

import static org.assertj.core.api.Assertions.assertThat;

import br.fatec.memora.autenticacao.dominio.EventoAutenticacao;
import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.dominio.ResultadoDoEvento;
import br.fatec.memora.autenticacao.dominio.TipoDeEvento;
import br.fatec.memora.autenticacao.infra.RepositorioEventoAutenticacao;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.seguranca.LimitadorTentativas.Decisao;
import br.fatec.memora.suporte.TesteComBanco;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

/**
 * As duas camadas de limite de tentativas (T021, R4).
 *
 * <p>O estado das duas mora no banco, nunca em memoria local: um reinicio no
 * meio de um ataque nao pode zerar o contador.
 */
@DisplayName("Limitador de tentativas")
class LimitadorTentativasTest extends TesteComBanco {

    private static final Instant AGORA = Instant.now().truncatedTo(ChronoUnit.MICROS);
    private static final String ORIGEM = "hash-de-uma-origem";

    @Autowired
    private LimitadorTentativas limitador;

    @Autowired
    private RepositorioPessoaUsuaria pessoas;

    @Autowired
    private RepositorioEventoAutenticacao eventos;

    @AfterEach
    void limpar() {
        eventos.deleteAll();
        pessoas.deleteAll();
    }

    private PessoaUsuaria pessoaSalva() {
        return pessoas.saveAndFlush(new PessoaUsuaria("Ana", "hash", AGORA));
    }

    private void registrarFalhasDaOrigem(int quantidade) {
        for (int i = 0; i < quantidade; i++) {
            eventos.save(EventoAutenticacao.semConta(
                    TipoDeEvento.FALHA_ENTRADA, ResultadoDoEvento.FALHA, ORIGEM, AGORA));
        }
        eventos.flush();
    }

    @Nested
    @DisplayName("Camada por conta")
    class PorConta {

        @Test
        @DisplayName("conta sem falhas passa")
        void contaLimpaPassa() {
            assertThat(limitador.avaliar(pessoaSalva(), ORIGEM, AGORA))
                    .isInstanceOf(Decisao.Permitido.class);
        }

        @Test
        @DisplayName("conta bloqueada informa quantos segundos faltam")
        void contaBloqueadaInformaEspera() {
            PessoaUsuaria pessoa = pessoaSalva();
            pessoa.bloquearAte(AGORA.plus(Duration.ofMinutes(5)));

            Decisao decisao = limitador.avaliar(pessoa, ORIGEM, AGORA);

            assertThat(decisao)
                    .asInstanceOf(
                            org.assertj.core.api.InstanceOfAssertFactories.type(
                                    Decisao.Bloqueado.class))
                    .extracting(Decisao.Bloqueado::tentarNovamenteEmSegundos)
                    .isEqualTo(300L);
        }

        @Test
        @DisplayName("bloqueio vencido deixa de valer")
        void bloqueioVencidoNaoImpede() {
            PessoaUsuaria pessoa = pessoaSalva();
            pessoa.bloquearAte(AGORA.minus(Duration.ofMinutes(1)));

            assertThat(limitador.avaliar(pessoa, ORIGEM, AGORA))
                    .isInstanceOf(Decisao.Permitido.class);
        }

        @Test
        @DisplayName("a quinta falha seguida bloqueia por um minuto")
        void quintaFalhaBloqueia() {
            PessoaUsuaria pessoa = pessoaSalva();

            for (int i = 1; i < BloqueioProgressivo.FALHAS_ATE_BLOQUEAR; i++) {
                assertThat(limitador.registrarFalha(pessoa, AGORA))
                        .as("a falha %d nao deveria bloquear", i)
                        .isEmpty();
            }

            assertThat(limitador.registrarFalha(pessoa, AGORA))
                    .contains(Duration.ofMinutes(1));
            assertThat(pessoa.estaBloqueadaEm(AGORA)).isTrue();
        }

        @Test
        @DisplayName("registrar falha em identificador inexistente nao explode")
        void falhaSemContaEhTolerada() {
            assertThat(limitador.registrarFalha(null, AGORA)).isEmpty();
        }
    }

    @Nested
    @DisplayName("Camada por origem")
    class PorOrigem {

        @Test
        @DisplayName("rajada da mesma origem e recusada mesmo sem conta alvo")
        void rajadaDaOrigemEhRecusada() {
            registrarFalhasDaOrigem(LimitadorTentativas.FALHAS_POR_ORIGEM_NA_JANELA);

            Decisao decisao = limitador.avaliar(null, ORIGEM, AGORA);

            assertThat(decisao).isInstanceOf(Decisao.Bloqueado.class);
        }

        @Test
        @DisplayName("abaixo do limite a origem passa")
        void abaixoDoLimitePassa() {
            registrarFalhasDaOrigem(LimitadorTentativas.FALHAS_POR_ORIGEM_NA_JANELA - 1);

            assertThat(limitador.avaliar(null, ORIGEM, AGORA))
                    .isInstanceOf(Decisao.Permitido.class);
        }

        @Test
        @DisplayName("falha antiga sai da janela e deixa de contar")
        void janelaDeslizanteEsquece() {
            Instant muitoAntes =
                    AGORA.minus(LimitadorTentativas.JANELA_POR_ORIGEM).minus(Duration.ofMinutes(1));
            for (int i = 0; i < LimitadorTentativas.FALHAS_POR_ORIGEM_NA_JANELA * 2; i++) {
                eventos.save(EventoAutenticacao.semConta(
                        TipoDeEvento.FALHA_ENTRADA, ResultadoDoEvento.FALHA, ORIGEM, muitoAntes));
            }
            eventos.flush();

            assertThat(limitador.avaliar(null, ORIGEM, AGORA))
                    .isInstanceOf(Decisao.Permitido.class);
        }

        @Test
        @DisplayName("a rajada de uma origem nao afeta outra origem")
        void origensSaoIndependentes() {
            registrarFalhasDaOrigem(LimitadorTentativas.FALHAS_POR_ORIGEM_NA_JANELA * 2);

            assertThat(limitador.avaliar(null, "hash-de-outra-origem", AGORA))
                    .isInstanceOf(Decisao.Permitido.class);
        }

        @Test
        @DisplayName("origem desconhecida nao derruba a avaliacao")
        void origemNulaEhTolerada() {
            assertThat(limitador.avaliar(pessoaSalva(), null, AGORA))
                    .isInstanceOf(Decisao.Permitido.class);
        }
    }

    @Nested
    @DisplayName("As duas camadas juntas")
    class DuasCamadas {

        @Test
        @DisplayName("identificador inexistente com origem limpa passa — nao revela nada")
        void contaInexistenteComOrigemLimpaPassa() {
            // Recusar aqui seria um oraculo: bastaria comparar a resposta de um
            // identificador qualquer com a de um identificador cadastrado.
            assertThat(limitador.avaliar(null, ORIGEM, AGORA))
                    .isInstanceOf(Decisao.Permitido.class);
        }

        @Test
        @DisplayName("a camada por origem barra ate quem tem conta liberada")
        void origemBarraContaLimpa() {
            PessoaUsuaria pessoa = pessoaSalva();
            registrarFalhasDaOrigem(LimitadorTentativas.FALHAS_POR_ORIGEM_NA_JANELA);

            assertThat(limitador.avaliar(pessoa, ORIGEM, AGORA))
                    .isInstanceOf(Decisao.Bloqueado.class);
        }
    }
}

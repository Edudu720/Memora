package br.fatec.memora.autenticacao.seguranca;

import static org.assertj.core.api.Assertions.assertThat;

import br.fatec.memora.autenticacao.dominio.EventoAutenticacao;
import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.dominio.ResultadoDoEvento;
import br.fatec.memora.autenticacao.dominio.Sessao;
import br.fatec.memora.autenticacao.dominio.TipoDeEvento;
import br.fatec.memora.autenticacao.infra.RepositorioEventoAutenticacao;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioSessao;
import br.fatec.memora.autenticacao.seguranca.ServicoDeSessao.MotivoDaRecusa;
import br.fatec.memora.autenticacao.seguranca.ServicoDeSessao.ResultadoDaRenovacao;
import br.fatec.memora.autenticacao.seguranca.ServicoDeSessao.SessaoEmitida;
import br.fatec.memora.suporte.TesteComBanco;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

/**
 * Cenario V3 do quickstart: deteccao de reuso de refresh token (T020, R2).
 *
 * <pre>
 *   1. Autenticar e guardar o refresh token A
 *   2. Renovar com A, recebendo B                       -> sucesso
 *   3. Renovar de novo com A, simulando token roubado   -> recusado
 *   4. Toda a familia revogada; B tambem deixa de valer
 *   5. Evento reuso_token_detectado registrado
 * </pre>
 *
 * <p><b>O criterio de falha do cenario e o passo 4</b>: se B continuar
 * funcionando depois do reuso de A, o ladrao segue dentro da conta e a defesa
 * nao serviu para nada.
 *
 * <h2>Por que derrubar a familia inteira e nao apenas A</h2>
 *
 * Quando A e apresentado depois de ja ter sido trocado por B, existem duas
 * partes com a mesma credencial e <b>nao ha como saber qual e a pessoa dona da
 * conta</b>. Revogar so o token reusado deixaria quem roubou usando B, se foi
 * ele quem renovou primeiro. Derrubar tudo custa um novo login a pessoa legitima
 * e custa o acesso inteiro a quem roubou.
 */
@DisplayName("Cenario V3 — reuso de refresh token")
class ReusoDeTokenTest extends TesteComBanco {

    private static final Instant AGORA = Instant.now().truncatedTo(ChronoUnit.MICROS);
    private static final String ORIGEM = "hash-da-origem-do-ladrao";

    @Autowired
    private ServicoDeSessao servico;

    @Autowired
    private GeradorDeSegredoOpaco gerador;

    @Autowired
    private RepositorioSessao sessoes;

    @Autowired
    private RepositorioPessoaUsuaria pessoas;

    @Autowired
    private RepositorioEventoAutenticacao eventos;

    @AfterEach
    void limpar() {
        sessoes.deleteAll();
        eventos.deleteAll();
        pessoas.deleteAll();
    }

    @Test
    @DisplayName("reusar o token antigo derruba a familia inteira, inclusive o token novo")
    void reusoDerrubaAFamiliaInteira() {
        PessoaUsuaria pessoa = pessoas.saveAndFlush(new PessoaUsuaria("Ana", "hash", AGORA));

        // 1. Sessao aberta: refresh token A.
        SessaoEmitida a = servico.iniciar(pessoa.getId(), "Pixel 6", AGORA);

        // 2. Renovacao legitima: A vira B.
        ResultadoDaRenovacao renovacao = servico.renovar(a.refreshToken(), ORIGEM, AGORA);
        assertThat(renovacao).isInstanceOf(ResultadoDaRenovacao.Renovada.class);
        SessaoEmitida b = ((ResultadoDaRenovacao.Renovada) renovacao).sessao();

        // 3. A aparece de novo: alguem esta com uma copia.
        ResultadoDaRenovacao reuso = servico.renovar(a.refreshToken(), ORIGEM, AGORA);
        assertThat(reuso)
                .isEqualTo(new ResultadoDaRenovacao.Recusada(MotivoDaRecusa.REUSO_DETECTADO));

        // 4. O criterio de falha do cenario: B nao pode mais servir.
        ResultadoDaRenovacao comB = servico.renovar(b.refreshToken(), ORIGEM, AGORA);
        assertThat(comB)
                .as("B continuou funcionando depois do reuso de A")
                .isNotInstanceOf(ResultadoDaRenovacao.Renovada.class);

        UUID familia = sessoes
                .findByRefreshTokenHash(gerador.hashDe(a.refreshToken()))
                .orElseThrow()
                .getFamiliaId();
        assertThat(sessoes.findByFamiliaId(familia))
                .as("toda a familia deveria estar revogada")
                .isNotEmpty()
                .allMatch(Sessao::estaRevogada);
    }

    @Test
    @DisplayName("o reuso fica registrado na trilha de auditoria")
    void reusoGeraEventoNaTrilha() {
        PessoaUsuaria pessoa = pessoas.saveAndFlush(new PessoaUsuaria("Ana", "hash", AGORA));
        SessaoEmitida a = servico.iniciar(pessoa.getId(), "Pixel 6", AGORA);
        servico.renovar(a.refreshToken(), ORIGEM, AGORA);

        servico.renovar(a.refreshToken(), ORIGEM, AGORA);

        assertThat(eventos.findByPessoaIdOrderByOcorridoEmDesc(pessoa.getId()))
                .as("o evento mais grave da trilha nao pode faltar")
                .anyMatch(evento -> evento.getTipo() == TipoDeEvento.REUSO_TOKEN_DETECTADO
                        && evento.getResultado() == ResultadoDoEvento.FALHA);
    }

    @Test
    @DisplayName("o evento do reuso nao carrega o token, nem hasheado")
    void eventoDoReusoNaoCarregaOToken() {
        PessoaUsuaria pessoa = pessoas.saveAndFlush(new PessoaUsuaria("Ana", "hash", AGORA));
        SessaoEmitida a = servico.iniciar(pessoa.getId(), "Pixel 6", AGORA);
        servico.renovar(a.refreshToken(), ORIGEM, AGORA);

        servico.renovar(a.refreshToken(), ORIGEM, AGORA);

        EventoAutenticacao doReuso = eventos.findByPessoaIdOrderByOcorridoEmDesc(pessoa.getId())
                .stream()
                .filter(evento -> evento.getTipo() == TipoDeEvento.REUSO_TOKEN_DETECTADO)
                .findFirst()
                .orElseThrow();

        // FR-040: nem o token nem o resumo dele entram na trilha.
        assertThat(doReuso.toString())
                .doesNotContain(a.refreshToken(), gerador.hashDe(a.refreshToken()));
        assertThat(doReuso.getOrigemHash()).isEqualTo(ORIGEM);
    }

    @Test
    @DisplayName("a familia de outra pessoa nao e afetada")
    void reusoNaoAfetaOutrasSessoes() {
        PessoaUsuaria vitima = pessoas.saveAndFlush(new PessoaUsuaria("Ana", "hash", AGORA));
        PessoaUsuaria outra = pessoas.saveAndFlush(new PessoaUsuaria("Jose", "hash", AGORA));
        SessaoEmitida a = servico.iniciar(vitima.getId(), "Pixel 6", AGORA);
        SessaoEmitida daOutra = servico.iniciar(outra.getId(), "Moto G", AGORA);
        servico.renovar(a.refreshToken(), ORIGEM, AGORA);

        servico.renovar(a.refreshToken(), ORIGEM, AGORA);

        assertThat(servico.renovar(daOutra.refreshToken(), ORIGEM, AGORA))
                .isInstanceOf(ResultadoDaRenovacao.Renovada.class);
    }

    @Test
    @DisplayName("insistir no token reusado continua acusando reuso")
    void insistirNoReusoContinuaAcusandoReuso() {
        PessoaUsuaria pessoa = pessoas.saveAndFlush(new PessoaUsuaria("Ana", "hash", AGORA));
        SessaoEmitida a = servico.iniciar(pessoa.getId(), "Pixel 6", AGORA);
        servico.renovar(a.refreshToken(), ORIGEM, AGORA);
        servico.renovar(a.refreshToken(), ORIGEM, AGORA);

        // Depois da revogacao a sessao esta substituida E revogada. Acusar reuso
        // continua sendo a leitura certa: e o sinal que interessa a auditoria.
        assertThat(servico.renovar(a.refreshToken(), ORIGEM, AGORA))
                .isEqualTo(new ResultadoDaRenovacao.Recusada(MotivoDaRecusa.REUSO_DETECTADO));
    }
}

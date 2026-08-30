package br.fatec.memora.assistente;

import static org.assertj.core.api.Assertions.assertThat;

import br.fatec.memora.assistente.aplicacao.AutorizadorDeAcao;
import br.fatec.memora.assistente.dominio.ServicoConhecido;
import br.fatec.memora.assistente.infra.ClienteDaAssistente;
import br.fatec.memora.assistente.infra.ClienteDaAssistenteSimulado;
import br.fatec.memora.assistente.infra.RepositorioServicoConhecido;
import br.fatec.memora.suporte.TesteComBanco;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

/**
 * Cenario H3 — a sugestao do modelo nao e autorizacao (T016).
 *
 * <h2>Este e o teste que separa um assistente de um vetor</h2>
 *
 * Se ele passar com o {@code AutorizadorDeAcao} quebrado, alguem consegue abrir
 * o aplicativo do banco de uma pessoa idosa convencendo o modelo — e convencer
 * um modelo e barato: basta uma mensagem de golpe colada no chat.
 *
 * <h2>Por que o simulado, e nao um modelo real</h2>
 *
 * O cenario precisa que a assistente sugira abrir o banco. Um modelo real, bem
 * instruido, provavelmente <i>nao</i> sugeriria — e um teste que depende de o
 * modelo se comportar mal para provar que a defesa funciona nao prova nada.
 *
 * <p>Aqui a sugestao maliciosa e produzida sob comando, sempre. O portao e
 * exercido em toda execucao, e nao quando der sorte.
 */
@DisplayName("H3 — a sugestao do modelo nao e autorizacao")
class SugestaoNaoEhAutorizacaoTest extends TesteComBanco {

    @Autowired
    private AutorizadorDeAcao autorizador;

    @Autowired
    private ClienteDaAssistenteSimulado assistente;

    @Autowired
    private RepositorioServicoConhecido servicos;

    private final List<UUID> criados = new ArrayList<>();

    @BeforeEach
    void semear() {
        // Pacote ficticio: o catalogo real vem da migration V5, e reusar um
        // pacote de la faria este teste disputar a unicidade com o produto.
        criados.add(
                servicos
                        .save(
                                ServicoConhecido.cotidiano(
                                        "Video de teste",
                                        "com.teste.video",
                                        "Videos",
                                        Instant.now()))
                        .getId());
        criados.add(
                servicos
                        .save(
                                ServicoConhecido.sensivel(
                                        "Banco de teste",
                                        "Conta e pagamentos",
                                        Instant.now()))
                        .getId());
        assistente.limpar();
    }

    /** Apaga so o que criou: o container e compartilhado pela suite. */
    @AfterEach
    void limpar() {
        criados.forEach(servicos::deleteById);
        criados.clear();
        assistente.limpar();
    }

    @Test
    @DisplayName("o modelo sugere abrir o banco, e a acao NAO chega ao aplicativo")
    void sugestaoDeServicoSensivelMorreNoServidor() {
        assistente
                .responderCom("Claro, vou abrir seu banco agora!")
                .sugerirAbrir("com.banco.aplicativo");

        ClienteDaAssistente.Resposta resposta = conversar();

        // O modelo sugeriu — e isso e esperado, modelos podem ser convencidos.
        assertThat(resposta.sugestao()).isPresent();

        // O catalogo recusou. E este o portao.
        assertThat(autorizador.autorizar(resposta.sugestao())).isEmpty();
    }

    @Test
    @DisplayName("nem um pacote inventado pelo modelo vira acao")
    void pacoteAlucinadoNaoViraAcao() {
        assistente.sugerirAbrir("com.aplicativo.que.nao.existe");

        assertThat(autorizador.autorizar(conversar().sugestao())).isEmpty();
    }

    @Test
    @DisplayName("a mesma sugestao maliciosa, repetida, e recusada todas as vezes")
    void insistenciaNaoAbreCaminho() {
        assistente.sugerirAbrir("com.banco.aplicativo");

        for (int tentativa = 1; tentativa <= 5; tentativa++) {
            assertThat(autorizador.autorizar(conversar().sugestao()))
                    .as("tentativa %d", tentativa)
                    .isEmpty();
        }
    }

    @Test
    @DisplayName("aplicativo cotidiano continua funcionando — o portao nao barra tudo")
    void cotidianoPassa() {
        // Sem este caso, um autorizador que recusasse absolutamente tudo
        // passaria nos tres testes acima e a feature nao funcionaria.
        assistente.sugerirAbrir("com.teste.video");

        Optional<AutorizadorDeAcao.AcaoAutorizada> acao =
                autorizador.autorizar(conversar().sugestao());

        assertThat(acao).isPresent();
        assertThat(acao.get().nomeExibido()).isEqualTo("Video de teste");
    }

    private ClienteDaAssistente.Resposta conversar() {
        return assistente.conversar(
                new ClienteDaAssistente.Pedido(
                        "persona", "catalogo", List.of(), "como vejo meu saldo?"),
                trecho -> {});
    }
}

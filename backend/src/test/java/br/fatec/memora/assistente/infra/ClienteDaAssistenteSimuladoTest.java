package br.fatec.memora.assistente.infra;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Testes do simulado da assistente, incluindo recusa financeira (T087, FR-018, FR-031, FR-037).
 */
@DisplayName("ClienteDaAssistenteSimulado — recusa de pedidos financeiros e irreversíveis")
class ClienteDaAssistenteSimuladoTest {

    private ClienteDaAssistenteSimulado simulado;

    @BeforeEach
    void setUp() {
        simulado = new ClienteDaAssistenteSimulado();
    }

    @Test
    @DisplayName("recusa pedido financeiro com explicação e sem ação (T087, US3/AC4)")
    void recusaPedidoFinanceiro() {
        ClienteDaAssistente.Pedido pedido =
                new ClienteDaAssistente.Pedido("persona", "catalogo", List.of(), "transfere R$ 500 para o Carlos");

        List<String> trechos = new ArrayList<>();
        ClienteDaAssistente.Resposta resposta = simulado.conversar(pedido, trechos::add);

        assertThat(resposta.texto()).isEqualTo(ClienteDaAssistenteSimulado.RECUSA_FINANCEIRA_PADRAO);
        assertThat(resposta.sugestao()).isEmpty();
        assertThat(resposta.texto().toLowerCase()).contains("não posso fazer transferências");
        assertThat(resposta.texto().toLowerCase()).contains("programa de computador");
        assertThat(resposta.texto().toLowerCase()).contains("proteção do seu dinheiro");
    }

    @Test
    @DisplayName("atendimento comum segue resposta padrão")
    void atendimentoComumSeguePadrao() {
        ClienteDaAssistente.Pedido pedido =
                new ClienteDaAssistente.Pedido("persona", "catalogo", List.of(), "como vejo as mensagens");

        List<String> trechos = new ArrayList<>();
        ClienteDaAssistente.Resposta resposta = simulado.conversar(pedido, trechos::add);

        assertThat(resposta.texto()).isEqualTo(ClienteDaAssistenteSimulado.RESPOSTA_PADRAO);
    }
}

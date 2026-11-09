package br.fatec.memora.assistente.dominio;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Testes de integridade e sanitização de EventoDaAssistente (T079, FR-036).
 */
@DisplayName("EventoDaAssistente — sanitização do resumo de pedido")
class EventoDaAssistenteTest {

    @Test
    @DisplayName("sanitiza código de verificação numérico (FR-036, T079)")
    void sanitizaCodigoNumerico() {
        String resultado = EventoDaAssistente.truncar("meu código é 123456");
        assertThat(resultado).doesNotContain("123456");
        assertThat(resultado).contains("***");
    }

    @Test
    @DisplayName("sanitiza sequência de 4 ou mais dígitos")
    void sanitizaDigitosConsecutivos() {
        String resultado = EventoDaAssistente.truncar("o número que recebi foi 987654");
        assertThat(resultado).doesNotContain("987654");
        assertThat(resultado).contains("***");
    }

    @Test
    @DisplayName("sanitiza senha em texto")
    void sanitizaSenhaEmTexto() {
        String resultado = EventoDaAssistente.truncar("minha senha é segredo123");
        assertThat(resultado).doesNotContain("segredo123");
        assertThat(resultado).contains("***");
    }

    @Test
    @DisplayName("mantém texto comum sem segredos inalterado")
    void mantemTextoComumInalterado() {
        String texto = "como vejo as fotos do meu neto";
        String resultado = EventoDaAssistente.truncar(texto);
        assertThat(resultado).isEqualTo(texto);
    }

    @Test
    @DisplayName("corta texto maior que o limite de 120 caracteres")
    void cortaTextoMaiorQueLimite() {
        String textoLongo = "a".repeat(150);
        String resultado = EventoDaAssistente.truncar(textoLongo);
        assertThat(resultado).hasSize(120);
    }

    @Test
    @DisplayName("evento sobre serviço aplica sanitização")
    void eventoSobreServicoAplicaSanitizacao() {
        EventoDaAssistente evento = EventoDaAssistente.sobreServico(
                UUID.randomUUID(),
                TipoDeEventoDaAssistente.ACAO_EXECUTADA,
                UUID.randomUUID(),
                "meu código é 123456",
                "hash",
                Instant.now());

        assertThat(evento.getPedidoResumido()).isPresent();
        assertThat(evento.getPedidoResumido().get()).doesNotContain("123456");
    }
}


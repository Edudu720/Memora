package br.fatec.memora.autenticacao.seguranca;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.Base64;
import javax.crypto.SecretKey;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/** A chave que assina o token de acesso (T018). */
@DisplayName("Chave de assinatura do token")
class ConfiguracaoDeTokenTest {

    @Test
    @DisplayName("sem segredo configurado, sorteia uma chave para o desenvolvimento seguir")
    void semSegredoSorteiaChave() {
        SecretKey primeira = ConfiguracaoDeToken.chaveDe("");
        SecretKey segunda = ConfiguracaoDeToken.chaveDe("   ");

        assertThat(primeira.getEncoded()).hasSizeGreaterThanOrEqualTo(32);
        // Sorteada de novo a cada subida: e por isso que producao precisa
        // configurar a sua, ou toda sessao morre a cada implantacao.
        assertThat(primeira.getEncoded()).isNotEqualTo(segunda.getEncoded());
    }

    @Test
    @DisplayName("usa o segredo configurado quando ele existe")
    void usaOSegredoConfigurado() {
        byte[] bytes = new byte[32];
        for (int i = 0; i < bytes.length; i++) {
            bytes[i] = (byte) i;
        }
        String configurado = Base64.getEncoder().encodeToString(bytes);

        assertThat(ConfiguracaoDeToken.chaveDe(configurado).getEncoded()).isEqualTo(bytes);
    }

    @Test
    @DisplayName("segredo curto derruba a subida em vez de aceitar chave fraca")
    void segredoCurtoEhRecusado() {
        String curto = Base64.getEncoder().encodeToString(new byte[16]);

        // Aceitar em silencio seria o pior dos mundos: o sistema funcionaria e
        // os tokens seriam forjaveis. Melhor nao subir.
        assertThatThrownBy(() -> ConfiguracaoDeToken.chaveDe(curto))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("256 bits");
    }

    @Test
    @DisplayName("segredo que nao e base64 derruba a subida com mensagem clara")
    void segredoInvalidoEhRecusado() {
        assertThatThrownBy(() -> ConfiguracaoDeToken.chaveDe("isto nao e base64!!!"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("base64");
    }
}

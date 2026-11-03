package br.fatec.memora.autenticacao.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import br.fatec.memora.suporte.TesteComBanco;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

/**
 * O que a cadeia de segurança deixa abrir sem credencial, e só isso.
 *
 * <p>O {@code /actuator/health} foi liberado sem teste nenhum. Entrou também o
 * {@code /actuator/health/liveness}, que é o que o Render consulta o tempo todo:
 * diferente do {@code /actuator/health}, ele <b>não toca no banco</b>, e o banco
 * em produção é um Neon gratuito, que dorme sem uso e cobra tempo de computação
 * por consulta.
 *
 * <p>A outra metade importa tanto quanto: liberar {@code /actuator/**} abriria
 * variáveis de ambiente e informações da aplicação a qualquer um. Os casos
 * abaixo não perguntam se o endpoint existe ou não, e sim que ele <b>não abre</b>
 * sem token.
 *
 * <p>Usa o mesmo contexto que as demais classes de {@code autenticacao/api/}:
 * sem {@code @TestPropertySource}, para não pagar outro Hikari de 20 conexões.
 */
@AutoConfigureMockMvc
@DisplayName("Cadeia de segurança — o que abre sem credencial")
class ConfiguracaoDeSegurancaWebTest extends TesteComBanco {

    @Autowired private MockMvc mockMvc;

    @Nested
    @DisplayName("Saúde, para quem monitora")
    class Saude {

        @Test
        @DisplayName("o health responde 200 e UP sem token")
        void healthAbertoSemToken() throws Exception {
            mockMvc.perform(get("/actuator/health"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.status").value("UP"));
        }

        @Test
        @DisplayName("o liveness responde 200 e UP sem token")
        void livenessAbertoSemToken() throws Exception {
            mockMvc.perform(get("/actuator/health/liveness"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.status").value("UP"));
        }
    }

    @Nested
    @DisplayName("O resto não abre")
    class RestoFechado {

        @Test
        @DisplayName("/actuator/env não abre sem token")
        void envFechado() throws Exception {
            naoAbre("/actuator/env");
        }

        @Test
        @DisplayName("/actuator/info não abre sem token")
        void infoFechado() throws Exception {
            naoAbre("/actuator/info");
        }

        @Test
        @DisplayName("o readiness não abre sem token: só o liveness foi liberado")
        void readinessFechado() throws Exception {
            naoAbre("/actuator/health/readiness");
        }

        @Test
        @DisplayName("um caminho autenticado qualquer não abre sem token")
        void caminhoAutenticadoFechado() throws Exception {
            naoAbre("/v1/assistente/catalogo");
        }

        private void naoAbre(String caminho) throws Exception {
            int status = mockMvc.perform(get(caminho)).andReturn().getResponse().getStatus();

            assertThat(status)
                    .as("GET %s sem token nao pode responder 200 (respondeu %d)", caminho, status)
                    .isNotEqualTo(200);
        }
    }
}

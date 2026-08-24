package br.fatec.memora.autenticacao.api;

import br.fatec.memora.comum.CodigoDeErro;
import br.fatec.memora.comum.Erro;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import org.springframework.http.MediaType;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.security.access.AccessDeniedException;
import tools.jackson.databind.ObjectMapper;

/**
 * O que o servidor responde a quem chega sem credencial válida (T058).
 *
 * <h2>Por que não deixar o Spring responder</h2>
 *
 * O padrão do Spring Security devolve um corpo próprio — ou nenhum — e um
 * cabeçalho {@code WWW-Authenticate}. Nada disso é o contrato: o aplicativo tem
 * um caminho só para ler erro, o record {@link Erro}, e uma resposta fora dessa
 * forma cairia no tratamento de falha inesperada do lado dele.
 *
 * <p>O texto vem de {@link CodigoDeErro#SESSAO_EXPIRADA}, que é o que a pessoa
 * precisa ouvir: <i>"faz um tempinho que você não usa o Memora"</i>. A causa
 * técnica — token ausente, vencido, adulterado ou apontando para conta que não
 * existe — <b>não</b> é distinguida na resposta. Distinguir transformaria este
 * ponto em oráculo: "token de sujeito inexistente" contra "token vencido"
 * confirmaria a quem tentasse cadastrar com o e-mail alheio que recebeu um
 * chamariz.
 *
 * <p>Vale para os dois lados da porta: quem não se autenticou
 * ({@link AuthenticationEntryPoint}) e quem se autenticou mas não pode
 * ({@link AccessDeniedHandler}) recebem a mesma coisa quando não há identidade.
 */
public class RespostaDeNaoAutenticado implements AuthenticationEntryPoint, AccessDeniedHandler {

    private final ObjectMapper json;

    public RespostaDeNaoAutenticado(ObjectMapper json) {
        this.json = json;
    }

    @Override
    public void commence(
            HttpServletRequest requisicao,
            HttpServletResponse resposta,
            AuthenticationException falha)
            throws IOException {
        escrever(resposta);
    }

    @Override
    public void handle(
            HttpServletRequest requisicao,
            HttpServletResponse resposta,
            AccessDeniedException recusa)
            throws IOException {
        escrever(resposta);
    }

    private void escrever(HttpServletResponse resposta) throws IOException {
        if (resposta.isCommitted()) {
            return;
        }

        CodigoDeErro codigo = CodigoDeErro.SESSAO_EXPIRADA;
        resposta.setStatus(codigo.status().value());
        resposta.setContentType(MediaType.APPLICATION_JSON_VALUE);
        resposta.setCharacterEncoding(StandardCharsets.UTF_8.name());
        resposta.getWriter()
                .write(json.writeValueAsString(Erro.de(codigo, codigo.mensagemPadrao())));
    }
}

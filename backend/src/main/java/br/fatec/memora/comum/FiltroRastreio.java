package br.fatec.memora.comum;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Objects;
import java.util.UUID;
import java.util.regex.Pattern;
import javax.crypto.Mac;
import javax.crypto.SecretKey;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Marca toda requisição com Trace ID e Request ID, e resume a origem de rede
 * (T026).
 *
 * <h2>Dois identificadores, dois donos</h2>
 *
 * <table>
 *   <caption>Quem gera e para que serve</caption>
 *   <tr><th>Identificador</th><th>Origem</th><th>Responde a</th></tr>
 *   <tr>
 *     <td>Trace ID</td>
 *     <td>Sempre nosso</td>
 *     <td>"o que o servidor fez nesta operação?"</td>
 *   </tr>
 *   <tr>
 *     <td>Request ID</td>
 *     <td>Do cliente, se ele mandar</td>
 *     <td>"aquela tentativa da dona Maria às 14h virou o quê aqui?"</td>
 *   </tr>
 * </table>
 *
 * <p>O segundo é o que fecha o ciclo com o suporte. A pessoa não vai ler um
 * identificador na tela nem repetir um código de 32 caracteres ao telefone —
 * quem correlaciona é o aplicativo, que já sabe qual requisição enviou.
 *
 * <h2>Por que o Request ID do cliente é validado antes de ser aceito</h2>
 *
 * Ele vai para o log e volta no cabeçalho da resposta. Aceitá-lo como veio abre
 * dois buracos conhecidos: quebra de linha no valor <b>forja entradas de
 * log</b>, e {@code CR}/{@code LF} em cabeçalho de resposta é o clássico
 * <i>response splitting</i>. Por isso só passa o que casa com
 * {@link #FORMATO_ACEITO}; qualquer outra coisa é descartada em silêncio e um
 * identificador nosso é gerado no lugar. Descartar é melhor que sanear: valor
 * estranho aqui é sinal de cliente com defeito ou de tentativa, e nos dois casos
 * não há nada que valha a pena preservar.
 *
 * <h2>Por que a origem é HMAC e não SHA-256 puro</h2>
 *
 * O data-model pede o endereço "hasheado, para correlacionar abuso sem reter o
 * endereço". Resumo simples <b>não entrega isso</b>: o espaço de endereços IPv4
 * inteiro tem 4 bilhões de valores, e quem obtiver o banco reverte a coluna
 * inteira por força bruta em minutos, recuperando de onde cada pessoa acessou.
 *
 * <p>HMAC com um segredo do servidor fecha essa porta: sem a chave não há
 * dicionário a montar. A chave precisa ser <b>estável entre reinícios</b>, senão
 * a contagem por origem do {@code LimitadorTentativas} (R4) zera junto com o
 * processo — que é exatamente o que a R4 proíbe.
 *
 * <p>De onde a chave vem, e o que acontece quando ninguém a configura, está em
 * {@link ConfiguracaoDeRastreio}. Aqui ela chega pronta: este filtro não decide
 * política de segredo, só usa a chave que recebeu.
 */
@Order(Ordered.HIGHEST_PRECEDENCE)
public class FiltroRastreio extends OncePerRequestFilter {

    /** Cabeçalho lido do cliente e devolvido na resposta. */
    public static final String CABECALHO_REQUEST_ID = "X-Request-Id";

    /** Cabeçalho devolvido na resposta, sempre gerado por nós. */
    public static final String CABECALHO_TRACE_ID = "X-Trace-Id";

    /** Chaves no MDC, visíveis em toda linha de log da requisição. */
    public static final String MDC_TRACE_ID = "traceId";

    public static final String MDC_REQUEST_ID = "requestId";

    /**
     * Formato aceito para Request ID vindo do cliente.
     *
     * <p>Deliberadamente restrito: hexadecimal, hífen e sublinhado, até 64
     * caracteres. Cobre UUID e os formatos usuais de correlação, e não deixa
     * passar espaço, quebra de linha ou caractere de controle.
     */
    private static final Pattern FORMATO_ACEITO = Pattern.compile("[A-Za-z0-9_-]{1,64}");

    private static final String ALGORITMO_HMAC = "HmacSHA256";

    private final SecretKey chaveDeOrigem;

    public FiltroRastreio(SecretKey chaveDeOrigem) {
        this.chaveDeOrigem = Objects.requireNonNull(chaveDeOrigem, "chaveDeOrigem");
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest requisicao, HttpServletResponse resposta, FilterChain cadeia)
            throws ServletException, IOException {

        String traceId = novoIdentificador();
        String requestId = requestIdDoClienteOuNovo(requisicao);

        ContextoDaRequisicao.definir(
                new ContextoDaRequisicao(traceId, requestId, origemResumida(requisicao)));
        MDC.put(MDC_TRACE_ID, traceId);
        MDC.put(MDC_REQUEST_ID, requestId);

        // Antes da cadeia: depois que a resposta começa a ser escrita, cabeçalho
        // novo é ignorado em silêncio.
        resposta.setHeader(CABECALHO_TRACE_ID, traceId);
        resposta.setHeader(CABECALHO_REQUEST_ID, requestId);

        try {
            cadeia.doFilter(requisicao, resposta);
        } finally {
            // Sem exceção: a thread volta para o pool, e o que ficar aqui
            // reaparece na requisição de outra pessoa.
            MDC.remove(MDC_TRACE_ID);
            MDC.remove(MDC_REQUEST_ID);
            ContextoDaRequisicao.limpar();
        }
    }

    private String requestIdDoClienteOuNovo(HttpServletRequest requisicao) {
        String informado = requisicao.getHeader(CABECALHO_REQUEST_ID);
        if (informado != null && FORMATO_ACEITO.matcher(informado).matches()) {
            return informado;
        }
        return novoIdentificador();
    }

    private String novoIdentificador() {
        return UUID.randomUUID().toString();
    }

    /**
     * Resume o endereço de origem.
     *
     * <p>Usa {@code getRemoteAddr()} — o endereço da conexão. Cabeçalhos como
     * {@code X-Forwarded-For} <b>não</b> são consultados: qualquer cliente pode
     * enviá-los, e confiar neles daria a um atacante o poder de escolher a
     * própria identidade de origem, contornando a camada de limite por origem a
     * cada tentativa. Quando houver proxy reverso na frente, a confiança nele
     * precisa ser configurada de forma explícita, não presumida aqui.
     *
     * @return resumo em hexadecimal, ou {@code null} se o contêiner não informar
     *     endereço
     */
    private String origemResumida(HttpServletRequest requisicao) {
        String endereco = requisicao.getRemoteAddr();
        if (endereco == null || endereco.isBlank()) {
            return null;
        }

        try {
            Mac mac = Mac.getInstance(ALGORITMO_HMAC);
            mac.init(chaveDeOrigem);
            return HexFormat.of()
                    .formatHex(mac.doFinal(endereco.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException | InvalidKeyException impossivel) {
            // HmacSHA256 é obrigatório em toda implementação da plataforma Java,
            // e a chave é construída no próprio construtor.
            throw new IllegalStateException(ALGORITMO_HMAC + " indisponível", impossivel);
        }
    }
}

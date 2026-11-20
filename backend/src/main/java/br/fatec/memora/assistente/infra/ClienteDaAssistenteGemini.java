package br.fatec.memora.assistente.infra;

import br.fatec.memora.assistente.infra.AssistenteIndisponivel.Motivo;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpTimeoutException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Consumer;
import java.util.regex.Pattern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;
import tools.jackson.databind.node.ArrayNode;
import tools.jackson.databind.node.ObjectNode;

/**
 * A assistente de verdade, falando com o Gemini (T063).
 *
 * <h2>É a única classe que conhece o provedor</h2>
 *
 * Endereço, formato do corpo, nome da ferramenta, cabeçalho da chave e o jeito
 * de os trechos chegarem: tudo isso vive aqui, e nada fora desta classe importa
 * uma linha do Gemini. Trocar de provedor (ver ADR-002) é escrever outro
 * adaptador desta porta — o Hub, o autorizador, a trilha e as telas não notam.
 *
 * <h2>Por que REST direto e não o SDK oficial</h2>
 *
 * O SDK Java do Google ({@code com.google.genai:google-genai}) usa Jackson 2
 * ({@code com.fasterxml.jackson.databind}); o Spring Boot 4 trouxe o Jackson 3
 * ({@code tools.jackson.*}) e os dois pacotes coexistem sem se falar. Seria uma
 * dependência grande, com a árvore de transitivas dela, para fazer uma chamada
 * HTTP com um corpo JSON e ler um fluxo de linhas. O {@link HttpClient} do JDK
 * faz isso, e o corpo do pedido fica <b>visível neste arquivo</b> — numa
 * feature em que "o que viaja ao modelo" é questão de privacidade (FR-051), ler
 * o pedido inteiro num lugar só vale mais que a conveniência do SDK.
 *
 * <h2>O que viaja, e em que ordem (T065)</h2>
 *
 * <ol>
 *   <li>{@code systemInstruction}: a persona e, em seguida, o catálogo. É o
 *       lugar da FR-034 — a mensagem da pessoa <b>nunca</b> entra aqui, e é
 *       isso que impede "ignore as instruções" de ser lido como instrução;
 *   <li>{@code tools}: a única função, {@link #FUNCAO_SUGERIR};
 *   <li>{@code contents}: o histórico (papéis {@code user}/{@code model}) e, por
 *       último, a mensagem atual.
 * </ol>
 *
 * Do mais estável ao mais volátil, <b>de propósito</b>: o cache implícito do
 * Gemini reaproveita o <i>prefixo</i> idêntico entre pedidos, e persona e
 * catálogo são idênticos a cada turno de todas as pessoas. Não se usa a API de
 * cache explícito — ela cobra armazenamento, e o implícito é de graça. Qualquer
 * dado que varie por pessoa, posto antes do histórico, destruiria o prefixo.
 *
 * <h2>Sugestão só chega por chamada de ferramenta</h2>
 *
 * Esta classe <b>nunca interpreta prosa</b>. "Abra o aplicativo do banco"
 * escrito no texto do modelo é só texto; a {@link Sugestao} nasce apenas de uma
 * parte {@code functionCall} da resposta, com o nome da função que declaramos.
 * E ainda assim é <b>sugestão</b>: o {@code AutorizadorDeAcao} decide, e nada
 * aqui autoriza coisa alguma (FR-022).
 *
 * <h2>A chave</h2>
 *
 * Vai no cabeçalho {@code x-goog-api-key}, <b>nunca na URL</b>: URL aparece em
 * log de proxy, de exceção de biblioteca e de rastro de rede; cabeçalho, não.
 * Também não entra em mensagem de exceção nem em log — esta classe nem tem um
 * {@code toString} que a mostre.
 *
 * <h2>Falhas</h2>
 *
 * Cota esgotada (429, esperado no nível gratuito), 5xx, recusa, rede e prazo
 * viram {@link AssistenteIndisponivel}, que carrega só um motivo. O corpo de
 * erro do Google nem é lido: texto de serviço externo não vai à pessoa, e
 * também não precisamos dele para decidir nada.
 */
public class ClienteDaAssistenteGemini implements ClienteDaAssistente, AutoCloseable {

    /** Onde o Gemini mora. Configurável para o teste apontar para um servidor falso. */
    public static final String URL_BASE_PADRAO = "https://generativelanguage.googleapis.com/v1beta";

    /** O nome da única função declarada ao modelo. */
    static final String FUNCAO_SUGERIR = "sugerir_abrir_aplicativo";

    /** O único argumento dela. */
    static final String ARGUMENTO_PACOTE = "identificador_android";

    /** O cabeçalho da chave. */
    static final String CABECALHO_DA_CHAVE = "x-goog-api-key";

    private static final Logger LOG = LoggerFactory.getLogger(ClienteDaAssistenteGemini.class);

    private static final Pattern FORMATO_DO_MODELO = Pattern.compile("[A-Za-z0-9._-]+");
    private static final Pattern FORMATO_DA_CHAVE = Pattern.compile("[\\x21-\\x7E]+");

    /**
     * O que a função diz de si ao modelo.
     *
     * <p>Fica aqui, e não na persona, porque descreve o contrato da ferramenta.
     * Diz duas coisas que importam: que chamar a função <b>não abre nada</b>
     * (quem confirma é a pessoa, na tela — FR-015), e que serviço da lista de
     * "só ensina" nunca entra. Isto é orientação ao modelo, não segurança: a
     * segurança é o catálogo consultado depois.
     */
    private static final String DESCRICAO_DA_FUNCAO =
            "Propõe abrir um aplicativo da lista 'Aplicativos que você pode ensinar E abrir'. "
                    + "Chamar esta função NÃO abre nada: ela só faz o aplicativo pedir a "
                    + "confirmação da pessoa na tela. Use só depois de ensinar o caminho e "
                    + "quando a pessoa pedir ou disser que não está conseguindo, e escreva "
                    + "SEMPRE também, em texto, o que vai abrir. Nunca use para um serviço da "
                    + "lista 'Serviços que você SÓ ensina'.";

    private static final String DESCRICAO_DO_ARGUMENTO =
            "O identificador exato do aplicativo, copiado do que está entre parênteses na lista de "
                    + "aplicativos que você pode abrir. Nunca invente um.";

    private final JsonMapper json = JsonMapper.builder().build();
    private final HttpClient http;
    private final ScheduledThreadPoolExecutor vigia;
    private final String chave;
    private final String modelo;
    private final URI endereco;
    private final URI enderecoReserva;
    private final int tentativasPrimario;
    private final Duration esperaEntreTentativas;
    private final Duration leitura;

    /**
     * Cria o adaptador sem retentativa extra nem modelo reserva (compatibilidade
     * com chamadas diretas de uma tentativa).
     *
     * @param chave a chave da API; <b>nunca</b> aparece em mensagem, log ou URL
     * @param modelo o modelo, p.ex. {@code gemini-3.6-flash}
     * @param urlBase o endereço base da API
     * @param conexao quanto esperar para conectar
     * @param leitura quanto esperar <b>sem receber nada</b>: vale para o início
     *     da resposta e para cada trecho dela (o prazo recomeça a cada linha)
     * @throws IllegalStateException chave ou modelo ausente/malformado — falhar
     *     na subida é melhor que falhar na primeira pessoa a conversar
     */
    public ClienteDaAssistenteGemini(
            String chave, String modelo, String urlBase, Duration conexao, Duration leitura) {
        this(chave, modelo, "", urlBase, conexao, leitura, 1, Duration.ZERO);
    }

    /**
     * Cria o adaptador com retentativa curta antes do primeiro trecho e modelo
     * reserva opcional.
     *
     * @param chave a chave da API; <b>nunca</b> aparece em mensagem, log ou URL
     * @param modelo o modelo principal, p.ex. {@code gemini-3.6-flash}
     * @param modeloReserva modelo reserva opcional, p.ex. {@code gemini-3.5-flash-lite}
     *     (vazio ou igual ao principal desativa o fallback)
     * @param urlBase o endereço base da API
     * @param conexao quanto esperar para conectar
     * @param leitura quanto esperar <b>sem receber nada</b> em cada linha
     * @param tentativasPrimario número de tentativas no modelo principal (>= 1)
     * @param esperaEntreTentativas intervalo entre tentativas no principal (>= 0)
     */
    public ClienteDaAssistenteGemini(
            String chave,
            String modelo,
            String modeloReserva,
            String urlBase,
            Duration conexao,
            Duration leitura,
            int tentativasPrimario,
            Duration esperaEntreTentativas) {
        if (chave == null || chave.isBlank()) {
            throw new IllegalStateException(
                    "GEMINI_API_KEY nao configurada: o provedor 'gemini' precisa da chave da API "
                            + "(variavel de ambiente GEMINI_API_KEY). Sem ela a assistente nao "
                            + "responderia a ninguem.");
        }
        // A chave nunca e repetida na mensagem — nem a parte dela.
        if (!FORMATO_DA_CHAVE.matcher(chave.strip()).matches()) {
            throw new IllegalStateException(
                    "GEMINI_API_KEY com formato invalido: so caracteres ASCII visiveis, sem "
                            + "espacos nem quebras de linha (confira se nao colou a chave com "
                            + "um enter no fim).");
        }
        if (modelo == null || !FORMATO_DO_MODELO.matcher(modelo.strip()).matches()) {
            throw new IllegalStateException(
                    "memora.assistente.gemini.modelo invalido: use so letras, numeros, ponto, "
                            + "hifen e sublinhado.");
        }
        if (tentativasPrimario < 1) {
            throw new IllegalStateException(
                    "memora.assistente.gemini.tentativas-primario invalido: use inteiro maior "
                            + "ou igual a 1.");
        }
        if (esperaEntreTentativas == null || esperaEntreTentativas.isNegative()) {
            throw new IllegalStateException(
                    "memora.assistente.gemini.espera-retentativa-ms invalido: nao pode ser "
                            + "negativo.");
        }

        String modeloPrincipal = modelo.strip();
        String base = urlBase.strip();
        if (base.endsWith("/")) {
            base = base.substring(0, base.length() - 1);
        }

        URI reservaUri = null;
        if (modeloReserva != null && !modeloReserva.isBlank()) {
            String reservaLimpa = modeloReserva.strip();
            if (!FORMATO_DO_MODELO.matcher(reservaLimpa).matches()) {
                throw new IllegalStateException(
                        "memora.assistente.gemini.modelo-reserva invalido: use so letras, "
                                + "numeros, ponto, hifen e sublinhado.");
            }
            if (!reservaLimpa.equals(modeloPrincipal)) {
                reservaUri =
                        URI.create(base + "/models/" + reservaLimpa + ":streamGenerateContent?alt=sse");
            }
        }

        this.chave = chave.strip();
        this.modelo = modeloPrincipal;
        this.endereco =
                URI.create(base + "/models/" + modeloPrincipal + ":streamGenerateContent?alt=sse");
        this.enderecoReserva = reservaUri;
        this.tentativasPrimario = tentativasPrimario;
        this.esperaEntreTentativas = esperaEntreTentativas;
        this.leitura = leitura;
        this.http =
                HttpClient.newBuilder()
                        .connectTimeout(conexao)
                        .version(HttpClient.Version.HTTP_1_1)
                        .build();
        this.vigia =
                new ScheduledThreadPoolExecutor(
                        1,
                        tarefa -> {
                            Thread fio = new Thread(tarefa, "gemini-vigia-de-leitura");
                            fio.setDaemon(true);
                            return fio;
                        });
        this.vigia.setRemoveOnCancelPolicy(true);
    }

    @Override
    public Resposta conversar(Pedido pedido, Consumer<String> aoReceberTrecho) {
        String corpoJson = montarCorpo(pedido);
        AssistenteIndisponivel ultimaFalha = null;

        for (int tentativa = 1; tentativa <= tentativasPrimario; tentativa++) {
            AtomicBoolean enviouTrecho = new AtomicBoolean(false);
            try {
                return conversarComEndereco(
                        endereco, corpoJson, aoReceberTrecho, enviouTrecho);
            } catch (AssistenteIndisponivel falha) {
                ultimaFalha = falha;
                if (enviouTrecho.get()
                        || Thread.currentThread().isInterrupted()
                        || !ehElegivelFallback(falha.motivo())) {
                    throw falha;
                }
                if (falha.motivo() == Motivo.COTA_ESGOTADA) {
                    if (enderecoReserva != null) {
                        LOG.warn(
                                "Modelo principal {} atingiu cota ({}); acionando reserva.",
                                modelo,
                                falha.motivo());
                    } else {
                        LOG.warn(
                                "Modelo principal {} atingiu cota ({}); sem modelo reserva.",
                                modelo,
                                falha.motivo());
                    }
                    break;
                }
                if (tentativa < tentativasPrimario) {
                    LOG.warn(
                            "Tentativa {}/{} no modelo {} falhou ({}); repetindo.",
                            tentativa,
                            tentativasPrimario,
                            modelo,
                            falha.motivo());
                    aguardarRetentativa();
                } else if (enderecoReserva != null) {
                    LOG.warn(
                            "Modelo principal {} falhou apos {} tentativa(s) ({}); acionando reserva.",
                            modelo,
                            tentativasPrimario,
                            falha.motivo());
                } else {
                    LOG.warn(
                            "Modelo principal {} falhou apos {} tentativa(s) ({}); sem modelo reserva.",
                            modelo,
                            tentativasPrimario,
                            falha.motivo());
                }
            }
        }

        if (enderecoReserva != null) {
            return conversarComEndereco(
                    enderecoReserva, corpoJson, aoReceberTrecho, new AtomicBoolean(false));
        }
        throw ultimaFalha;
    }

    private Resposta conversarComEndereco(
            URI destino,
            String corpoJson,
            Consumer<String> aoReceberTrecho,
            AtomicBoolean enviouTrecho) {
        HttpRequest requisicao =
                HttpRequest.newBuilder(destino)
                        // Prazo ate o INICIO da resposta; o do fluxo e do vigia.
                        .timeout(leitura)
                        .header("Content-Type", "application/json")
                        .header("Accept", "text/event-stream")
                        .header(CABECALHO_DA_CHAVE, chave)
                        .POST(HttpRequest.BodyPublishers.ofString(corpoJson, StandardCharsets.UTF_8))
                        .build();

        HttpResponse<InputStream> resposta;
        try {
            resposta = http.send(requisicao, HttpResponse.BodyHandlers.ofInputStream());
        } catch (HttpTimeoutException estourou) {
            throw new AssistenteIndisponivel(Motivo.PRAZO, "sem inicio de resposta");
        } catch (IOException falhou) {
            throw new AssistenteIndisponivel(Motivo.REDE, falhou.getClass().getSimpleName());
        } catch (InterruptedException interrompido) {
            Thread.currentThread().interrupt();
            throw new AssistenteIndisponivel(Motivo.REDE, "interrompido");
        }

        try (InputStream corpo = resposta.body()) {
            int status = resposta.statusCode();
            if (status != 200) {
                // O corpo NAO e lido: e texto de servico externo, e nao precisamos
                // dele para decidir nada. O status basta para o log.
                throw porStatus(status);
            }
            return lerFluxo(corpo, aoReceberTrecho, enviouTrecho);
        } catch (IOException aoFechar) {
            // So o fechamento falhou; o que importa ja foi decidido acima.
            throw new AssistenteIndisponivel(Motivo.REDE, aoFechar.getClass().getSimpleName());
        }
    }

    private static boolean ehElegivelFallback(Motivo motivo) {
        return motivo == Motivo.COTA_ESGOTADA
                || motivo == Motivo.FALHA_DO_PROVEDOR
                || motivo == Motivo.REDE
                || motivo == Motivo.PRAZO;
    }

    private void aguardarRetentativa() {
        if (Thread.currentThread().isInterrupted()) {
            throw new AssistenteIndisponivel(Motivo.REDE, "interrompido");
        }
        if (esperaEntreTentativas.isZero()) {
            return;
        }
        try {
            Thread.sleep(esperaEntreTentativas.toMillis());
        } catch (InterruptedException interrompido) {
            Thread.currentThread().interrupt();
            throw new AssistenteIndisponivel(Motivo.REDE, "interrompido");
        }
    }

    /** Libera o cliente HTTP e o vigia de leitura. */
    @Override
    public void close() {
        vigia.shutdownNow();
        http.shutdownNow();
    }

    // ---------------------------------------------------------------- o pedido

    /** Monta o corpo exatamente como descrito na nota da classe. */
    String montarCorpo(Pedido pedido) {
        ObjectNode raiz = json.createObjectNode();

        ArrayNode instrucao = raiz.putObject("systemInstruction").putArray("parts");
        instrucao.addObject().put("text", pedido.persona());
        if (pedido.catalogo() != null && !pedido.catalogo().isBlank()) {
            instrucao.addObject().put("text", pedido.catalogo());
        }

        ObjectNode funcao = raiz.putArray("tools").addObject().putArray("functionDeclarations").addObject();
        funcao.put("name", FUNCAO_SUGERIR);
        funcao.put("description", DESCRICAO_DA_FUNCAO);
        ObjectNode parametros = funcao.putObject("parameters");
        parametros.put("type", "object");
        parametros
                .putObject("properties")
                .putObject(ARGUMENTO_PACOTE)
                .put("type", "string")
                .put("description", DESCRICAO_DO_ARGUMENTO);
        parametros.putArray("required").add(ARGUMENTO_PACOTE);

        raiz.putObject("toolConfig").putObject("functionCallingConfig").put("mode", "AUTO");

        ArrayNode conteudos = raiz.putArray("contents");
        for (Mensagem mensagem : conversaDoPedido(pedido)) {
            ObjectNode conteudo = conteudos.addObject();
            conteudo.put("role", mensagem.papel());
            conteudo.putArray("parts").addObject().put("text", mensagem.texto());
        }

        return json.writeValueAsString(raiz);
    }

    private record Mensagem(String papel, String texto) {}

    /**
     * O histórico e a mensagem atual, no formato que o Gemini aceita.
     *
     * <p>Três acertos, todos para o pedido não ser recusado por causa de um
     * detalhe de forma da conversa:
     * <ul>
     *   <li>turno em branco sai — o provedor recusa {@code parts} vazio;
     *   <li>a conversa precisa começar por {@code user}: o corte do histórico
     *       pelo teto de turnos pode deixar uma fala da Memora na frente;
     *   <li>falas seguidas do mesmo papel viram uma só (a pessoa que mandou duas
     *       mensagens sem a Memora responder no meio, por uma falha anterior).
     * </ul>
     *
     * A mensagem atual é <b>sempre</b> {@code user} e a última.
     */
    private static List<Mensagem> conversaDoPedido(Pedido pedido) {
        List<Mensagem> lista = new ArrayList<>();
        if (pedido.historico() != null) {
            for (Turno turno : pedido.historico()) {
                if (turno.texto() == null || turno.texto().isBlank()) {
                    continue;
                }
                acrescentar(
                        lista,
                        turno.autor() == Turno.Autor.MEMORA ? "model" : "user",
                        turno.texto());
            }
        }
        while (!lista.isEmpty() && lista.get(0).papel().equals("model")) {
            lista.remove(0);
        }
        acrescentar(lista, "user", pedido.mensagem());
        return lista;
    }

    private static void acrescentar(List<Mensagem> lista, String papel, String texto) {
        if (!lista.isEmpty() && lista.get(lista.size() - 1).papel().equals(papel)) {
            Mensagem anterior = lista.remove(lista.size() - 1);
            lista.add(new Mensagem(papel, anterior.texto() + "\n\n" + texto));
        } else {
            lista.add(new Mensagem(papel, texto));
        }
    }

    // ---------------------------------------------------------- a resposta

    private static AssistenteIndisponivel porStatus(int status) {
        if (status == 429) {
            return new AssistenteIndisponivel(Motivo.COTA_ESGOTADA, "http 429");
        }
        if (status >= 500) {
            return new AssistenteIndisponivel(Motivo.FALHA_DO_PROVEDOR, "http " + status);
        }
        return new AssistenteIndisponivel(Motivo.PEDIDO_RECUSADO, "http " + status);
    }

    /**
     * Lê o fluxo de eventos e monta a resposta.
     *
     * <p>Cada evento é uma linha {@code data: {json}}. O texto de cada parte
     * segue para o {@code aoReceberTrecho} assim que chega — a SC-007 pede tela
     * que se mexe.
     */
    private Resposta lerFluxo(
            InputStream corpo, Consumer<String> aoReceberTrecho, AtomicBoolean enviouTrecho) {
        StringBuilder texto = new StringBuilder();
        Optional<Sugestao> sugestao = Optional.empty();
        AtomicBoolean estourou = new AtomicBoolean(false);

        try (BufferedReader leitor =
                new BufferedReader(new InputStreamReader(corpo, StandardCharsets.UTF_8))) {
            while (true) {
                if (Thread.currentThread().isInterrupted()) {
                    fecharSemFalhar(corpo);
                    throw new AssistenteIndisponivel(Motivo.REDE, "cliente_desconectou");
                }
                // O prazo recomeca a cada linha: o que se vigia e o silencio.
                ScheduledFuture<?> guarda =
                        vigia.schedule(
                                () -> {
                                    estourou.set(true);
                                    fecharSemFalhar(corpo);
                                },
                                leitura.toMillis(),
                                TimeUnit.MILLISECONDS);
                String linha;
                try {
                    linha = leitor.readLine();
                } catch (IOException falhou) {
                    throw estourou.get()
                            ? new AssistenteIndisponivel(Motivo.PRAZO, "silencio no meio da resposta")
                            : new AssistenteIndisponivel(Motivo.REDE, falhou.getClass().getSimpleName());
                } finally {
                    guarda.cancel(false);
                }
                if (linha == null) {
                    break;
                }
                if (!linha.startsWith("data:")) {
                    continue;
                }
                String dado = linha.substring("data:".length()).strip();
                if (dado.isEmpty()) {
                    continue;
                }

                JsonNode evento;
                try {
                    evento = json.readTree(dado);
                } catch (JacksonException ilegivel) {
                    throw new AssistenteIndisponivel(Motivo.RESPOSTA_ILEGIVEL, "evento sem json");
                }
                if (evento.has("error")) {
                    throw porStatus(evento.path("error").path("code").asInt(500));
                }

                for (JsonNode parte : evento.path("candidates").path(0).path("content").path("parts")) {
                    if (parte.path("thought").asBoolean(false)) {
                        continue;
                    }
                    JsonNode trecho = parte.get("text");
                    if (trecho != null && trecho.isString() && !trecho.stringValue().isEmpty()) {
                        texto.append(trecho.stringValue());
                        enviouTrecho.set(true);
                        aoReceberTrecho.accept(trecho.stringValue());
                    }
                    if (sugestao.isEmpty() && parte.has("functionCall")) {
                        sugestao = sugestaoDe(parte.get("functionCall"));
                    }
                }
            }
        } catch (IOException aoFechar) {
            throw new AssistenteIndisponivel(Motivo.REDE, aoFechar.getClass().getSimpleName());
        }

        if (texto.isEmpty() && sugestao.isEmpty()) {
            // Bloqueio de seguranca do modelo, ou fluxo que acabou sem nada.
            throw new AssistenteIndisponivel(Motivo.RESPOSTA_VAZIA, null);
        }
        return new Resposta(texto.toString(), sugestao);
    }

    /**
     * Só a nossa função, com o argumento no formato esperado, vira sugestão.
     * Função de outro nome, ou argumento ausente ou de outro tipo, é ignorada —
     * o modelo não ganha ferramenta nova inventando o nome dela.
     */
    private static Optional<Sugestao> sugestaoDe(JsonNode chamada) {
        if (!FUNCAO_SUGERIR.equals(chamada.path("name").asString(""))) {
            return Optional.empty();
        }
        JsonNode pacote = chamada.path("args").path(ARGUMENTO_PACOTE);
        if (!pacote.isString() || pacote.stringValue().isBlank()) {
            return Optional.empty();
        }
        return Optional.of(new Sugestao(pacote.stringValue().strip()));
    }

    private static void fecharSemFalhar(InputStream corpo) {
        try {
            corpo.close();
        } catch (IOException ignorado) {
            // Fechar e a forma de acordar o readLine; se falhar, o prazo do
            // pedido inteiro ainda existe.
        }
    }
}

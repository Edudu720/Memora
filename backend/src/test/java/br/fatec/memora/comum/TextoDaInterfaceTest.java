package br.fatec.memora.comum;

import static org.assertj.core.api.Assertions.assertThat;

import br.fatec.memora.autenticacao.api.ControladorRecuperacao;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

/**
 * Portão do texto da interface no backend (feature 013, T033; FR-020).
 *
 * <p>Nenhuma mensagem devolvida à interface pelo backend pode conter emoji
 * (emojis pertencem apenas à fala da IA), palavras que diminuam a pessoa ou
 * blocos com mais de duas frases.
 */
@DisplayName("Portão de texto da interface — backend sem emojis nem textos longos")
class TextoDaInterfaceTest {

    private static final Pattern PICTOGRAMA = Pattern.compile("\\p{IsExtended_Pictographic}");

    private static final Pattern FIM_DE_FRASE = Pattern.compile("(\\.\\.\\.|[.!?…]+)(?=\\s|$)");

    private static final List<String> ABREVIACOES = List.of("Sr", "Sra", "Dr", "Dra", "nº");

    private static final List<Pattern> PROIBIDAS =
            List.of(
                    Pattern.compile("(?<![\\p{L}])idos[oa]s?(?![\\p{L}])", Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE),
                    Pattern.compile("(?<![\\p{L}])terceira idade(?![\\p{L}])", Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE),
                    Pattern.compile("(?<![\\p{L}])melhor idade(?![\\p{L}])", Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE),
                    Pattern.compile("(?<![\\p{L}])s[êe]nior(es)?(?![\\p{L}])", Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE),
                    Pattern.compile("(?<![\\p{L}])modo simplificado(?![\\p{L}])", Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE));

    @Nested
    @DisplayName("Autoteste das regras do portão")
    class Autoteste {

        @Test
        @DisplayName("detecta emoji em texto")
        void detectaEmoji() {
            assertThat(temEmoji("Oi 😊")).isTrue();
            assertThat(temEmoji("Feito ✅")).isTrue();
            assertThat(temEmoji("Olá, tudo bem?")).isFalse();
        }

        @Test
        @DisplayName("conta frases respeitando abreviações e números")
        void contaFrases() {
            assertThat(contarFrases("Uma. Duas. Três.")).isEqualTo(3);
            assertThat(contarFrases("Uma. Duas?")).isEqualTo(2);
            assertThat(contarFrases("Tudo certo!")).isEqualTo(1);
            assertThat(contarFrases("São 1.000 passos com o Dr. João.")).isEqualTo(1);
        }

        @Test
        @DisplayName("detecta termos proibidos sem falsos positivos")
        void detectaPalavrasProibidas() {
            assertThat(contemPalavraProibida("Feito para o idoso")).isTrue();
            assertThat(contemPalavraProibida("Na melhor idade")).isTrue();
            assertThat(contemPalavraProibida("Vamos ver juntos")).isFalse();
            assertThat(contemPalavraProibida("Idade informada")).isFalse();
        }
    }

    @Test
    @DisplayName("todos os CodigoDeErro têm no máximo 2 frases, sem emoji nem palavra proibida")
    void codigoDeErroEmConformidade() {
        List<String> falhas = new ArrayList<>();
        for (CodigoDeErro codigo : CodigoDeErro.values()) {
            String msg = codigo.mensagemPadrao();
            validarMensagem("CodigoDeErro." + codigo.name(), msg, falhas);
        }
        assertThat(falhas).isEmpty();
    }

    @Test
    @DisplayName("mensagem de recuperação aceita tem no máximo 2 frases, sem emoji nem palavra proibida")
    void mensagemRecuperacaoAceitaEmConformidade() {
        List<String> falhas = new ArrayList<>();
        validarMensagem(
                "ControladorRecuperacao.MENSAGEM_ACEITA",
                ControladorRecuperacao.MENSAGEM_ACEITA,
                falhas);
        assertThat(falhas).isEmpty();
    }

    @Test
    @DisplayName("nenhum controlador, serviço de cadastro ou classe comum contém emoji")
    void fontesDaInterfaceSemEmoji() throws IOException {
        Path raizJava = Path.of("src/main/java/br/fatec/memora").toAbsolutePath().normalize();
        assertThat(Files.isDirectory(raizJava))
                .as("Diretório fonte %s deve existir (rode na pasta backend/)", raizJava)
                .isTrue();

        List<Path> arquivos;
        try (Stream<Path> walk = Files.walk(raizJava)) {
            arquivos =
                    walk.filter(Files::isRegularFile)
                            .filter(p -> p.toString().endsWith(".java"))
                            .filter(TextoDaInterfaceTest::ehArquivoDeInterfaceOuErro)
                            .toList();
        }

        assertThat(arquivos).isNotEmpty();

        List<String> ocorrencias = new ArrayList<>();
        for (Path arquivo : arquivos) {
            List<String> linhas = Files.readAllLines(arquivo, StandardCharsets.UTF_8);
            for (int i = 0; i < linhas.size(); i++) {
                String linha = linhas.get(i);
                if (temEmoji(linha)) {
                    ocorrencias.add(raizJava.relativize(arquivo) + ":" + (i + 1) + " -> " + linha.trim());
                }
            }
        }

        assertThat(ocorrencias)
                .as("Mensagens devolvidas à tela pelo backend não podem conter emojis (FR-020)")
                .isEmpty();
    }

    private static boolean ehArquivoDeInterfaceOuErro(Path arquivo) {
        String caminho = arquivo.toString().replace('\\', '/');
        if (caminho.endsWith("/PersonaDaMemora.java")
                || caminho.endsWith("/ClienteDaAssistenteSimulado.java")) {
            return false;
        }
        return caminho.contains("/api/")
                || caminho.contains("/comum/")
                || caminho.endsWith("/ServicoDeCadastro.java")
                || caminho.contains("/localizador/");
    }

    private static void validarMensagem(String origem, String mensagem, List<String> falhas) {
        if (temEmoji(mensagem)) {
            falhas.add(origem + ": contém emoji -> " + mensagem);
        }
        int frases = contarFrases(mensagem);
        if (frases > 2) {
            falhas.add(origem + ": " + frases + " frases (máximo 2) -> " + mensagem);
        }
        if (contemPalavraProibida(mensagem)) {
            falhas.add(origem + ": contém palavra proibida -> " + mensagem);
        }
    }

    static boolean temEmoji(String texto) {
        return texto != null && PICTOGRAMA.matcher(texto).find();
    }

    static boolean contemPalavraProibida(String texto) {
        if (texto == null) return false;
        for (Pattern p : PROIBIDAS) {
            if (p.matcher(texto).find()) {
                return true;
            }
        }
        return false;
    }

    static int contarFrases(String texto) {
        if (texto == null) return 0;
        String t = texto.trim();
        if (t.isEmpty()) return 0;
        Matcher m = FIM_DE_FRASE.matcher(t);
        int frases = 0;
        int inicio = 0;
        while (m.find()) {
            String antes = t.substring(inicio, m.start());
            String trimmedAntes = antes.trim();
            String[] palavras = trimmedAntes.isEmpty() ? new String[0] : trimmedAntes.split("\\s+");
            String ultimaPalavra = palavras.length > 0 ? palavras[palavras.length - 1] : "";
            if (".".equals(m.group(0)) && ABREVIACOES.contains(ultimaPalavra)) {
                continue;
            }
            if (!trimmedAntes.isEmpty()) {
                frases++;
            }
            inicio = m.end();
        }
        if (!t.substring(inicio).trim().isEmpty()) {
            frases++;
        }
        return frases;
    }
}

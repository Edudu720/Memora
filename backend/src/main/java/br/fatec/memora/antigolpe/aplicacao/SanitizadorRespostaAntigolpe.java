package br.fatec.memora.antigolpe.aplicacao;

import br.fatec.memora.antigolpe.aplicacao.AnalisadorDeterministicoDeGolpes.AnalisePrevia;
import br.fatec.memora.antigolpe.dominio.NivelRiscoGolpe;
import br.fatec.memora.antigolpe.dominio.ResultadoAnaliseGolpe;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.stereotype.Component;

/**
 * Pós-validação determinística da resposta antigolpe (Princípio VI e memora-ux).
 *
 * <p>Garante piso monotônico de risco ({@code max(preCheck, aiResult)}), bloqueia rebaixamentos
 * causados por injeção de instrução, remove emojis e links clicáveis, impõe limite de até duas
 * frases curtas em título e explicação e substitui termos proibidos ou jargão técnico.
 */
@Component
public class SanitizadorRespostaAntigolpe {

    private static final Pattern PICTOGRAMA =
            Pattern.compile("[\\p{IsExtended_Pictographic}\\uFE0E\\uFE0F\\u200D]");
    private static final Pattern LINK_MARKDOWN = Pattern.compile("\\[([^\\]]+)\\]\\([^)]+\\)");
    private static final Pattern URL_BRUTA =
            Pattern.compile("(?i)\\b(?:https?://|www\\.)\\S+");
    private static final Pattern FIM_DE_FRASE = Pattern.compile("(\\.\\.\\.|[.!?…]+)(?=\\s|$)");
    private static final List<String> ABREVIACOES = List.of("Sr", "Sra", "Dr", "Dra", "nº");

    private static final List<Pattern> PALAVRAS_PROIBIDAS_OU_JARGAO =
            List.of(
                    Pattern.compile(
                            "(?<![\\p{L}])idos[oa]s?(?![\\p{L}])",
                            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE),
                    Pattern.compile(
                            "(?<![\\p{L}])terceira idade(?![\\p{L}])",
                            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE),
                    Pattern.compile(
                            "(?<![\\p{L}])melhor idade(?![\\p{L}])",
                            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE),
                    Pattern.compile(
                            "(?<![\\p{L}])s[êe]nior(es)?(?![\\p{L}])",
                            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE),
                    Pattern.compile(
                            "(?<![\\p{L}])modo simplificado(?![\\p{L}])",
                            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE),
                    Pattern.compile(
                            "(?<![\\p{L}])sozinh[oa]s?(?![\\p{L}])",
                            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE),
                    Pattern.compile(
                            "(?<![\\p{L}])tranquil[oa]s?(?![\\p{L}])",
                            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE),
                    Pattern.compile(
                            "(?<![\\p{L}])ser\\s+chamad[oa]s?(?![\\p{L}])",
                            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE),
                    Pattern.compile(
                            "(?<![\\p{L}])(?:phishing|malware|ransomware|punycode|hom[óo]grafo|jailbreak|otp|urls?|tokens?)(?![\\p{L}])",
                            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE),
                    Pattern.compile(
                            "(?:[ée]\\s+dif[íi]cil\\s+para\\s+(?:voc[êe]|a\\s+senhora|o\\s+senhor)|n[ãa]o\\s+se\\s+preocupe\\s+se\\s+n[ãa]o\\s+entender|at[ée]\\s+voc[êe]\\s+consegue)",
                            Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CASE));

    /**
     * Aplica o piso monotônico e higieniza todos os campos voltados à interface.
     */
    public ResultadoAnaliseGolpe sanitizar(
            AnalisePrevia preCheck, ResultadoAnaliseGolpe respostaProvedor) {
        ResultadoAnaliseGolpe baseDeterministica = preCheck.resultado();
        if (respostaProvedor == null) {
            return baseDeterministica;
        }

        NivelRiscoGolpe riscoPre = baseDeterministica.risco();
        NivelRiscoGolpe riscoIa = respostaProvedor.risco();
        NivelRiscoGolpe riscoFinal = NivelRiscoGolpe.max(riscoPre, riscoIa);

        ResultadoAnaliseGolpe padraoFinal =
                AnalisadorDeterministicoDeGolpes.resultadoPara(
                        riscoFinal, baseDeterministica.sinaisDetectados());

        boolean iaRebaixouRisco = riscoIa.ordinal() < riscoPre.ordinal();
        boolean descartarTextoIa = iaRebaixouRisco || preCheck.tentativaDeInjecao();

        if (descartarTextoIa) {
            List<String> sinaisDeterministicos =
                    mesclarSinais(baseDeterministica.sinaisDetectados(), List.of());
            return new ResultadoAnaliseGolpe(
                    riscoFinal,
                    padraoFinal.titulo(),
                    padraoFinal.explicacao(),
                    padraoFinal.orientacoes(),
                    sinaisDeterministicos,
                    false);
        }

        String tituloSanitizado = tentarSanitizarBlocoCurto(respostaProvedor.titulo(), 120);
        String explicacaoSanitizada =
                tentarSanitizarBlocoCurto(respostaProvedor.explicacao(), 260);
        List<String> orientacoesSanitizadas =
                tentarSanitizarLista(respostaProvedor.orientacoes());

        boolean tudoCaiuNoPadrao =
                tituloSanitizado == null
                        && explicacaoSanitizada == null
                        && orientacoesSanitizadas == null;

        String titulo = tituloSanitizado != null ? tituloSanitizado : padraoFinal.titulo();
        String explicacao =
                explicacaoSanitizada != null ? explicacaoSanitizada : padraoFinal.explicacao();
        List<String> orientacoes =
                orientacoesSanitizadas != null
                        ? orientacoesSanitizadas
                        : padraoFinal.orientacoes();

        List<String> sinais =
                mesclarSinais(
                        baseDeterministica.sinaisDetectados(),
                        tudoCaiuNoPadrao ? List.of() : respostaProvedor.sinaisDetectados());

        boolean analisadoPorIa = respostaProvedor.analisadoPorIa() && !tudoCaiuNoPadrao;

        return new ResultadoAnaliseGolpe(
                riscoFinal, titulo, explicacao, orientacoes, sinais, analisadoPorIa);
    }

    private static String tentarSanitizarBlocoCurto(String texto, int tamanhoMaximo) {
        String limpo = limparTextoBruto(texto);
        if (limpo.isEmpty() || contemTermoProibido(limpo)) {
            return null;
        }
        String limitadoFrases = limitarDuasFrases(limpo);
        if (limitadoFrases.isEmpty() || contemTermoProibido(limitadoFrases)) {
            return null;
        }
        if (limitadoFrases.length() > tamanhoMaximo) {
            return null;
        }
        return limitadoFrases;
    }

    private static List<String> tentarSanitizarLista(List<String> itens) {
        if (itens == null || itens.isEmpty()) {
            return null;
        }
        List<String> limpos = new ArrayList<>();
        Set<String> vistos = new LinkedHashSet<>();
        for (String item : itens) {
            String limpo = limparTextoBruto(item);
            if (limpo.isEmpty() || contemTermoProibido(limpo)) {
                continue;
            }
            limpo = limitarDuasFrases(limpo);
            if (!limpo.isEmpty() && vistos.add(limpo.toLowerCase(Locale.ROOT))) {
                limpos.add(limpo);
            }
        }
        return limpos.isEmpty() ? null : List.copyOf(limpos);
    }

    private static List<String> mesclarSinais(
            List<String> deterministicos, List<String> daIa) {
        List<String> resultado = new ArrayList<>();
        Set<String> vistos = new LinkedHashSet<>();
        if (deterministicos != null) {
            for (String s : deterministicos) {
                String limpo = limparTextoBruto(s);
                if (!limpo.isEmpty() && vistos.add(limpo.toLowerCase(Locale.ROOT))) {
                    resultado.add(limpo);
                }
            }
        }
        if (daIa != null) {
            for (String s : daIa) {
                String limpo = limparTextoBruto(s);
                if (!limpo.isEmpty()
                        && !contemTermoProibido(limpo)
                        && vistos.add(limpo.toLowerCase(Locale.ROOT))) {
                    resultado.add(limpo);
                }
            }
        }
        return List.copyOf(resultado);
    }

    private static String limparTextoBruto(String texto) {
        if (texto == null) {
            return "";
        }
        String semLinksMarkdown = LINK_MARKDOWN.matcher(texto).replaceAll("$1");
        String semUrlsBrutas = URL_BRUTA.matcher(semLinksMarkdown).replaceAll("");
        String semEmoji = PICTOGRAMA.matcher(semUrlsBrutas).replaceAll("");
        return semEmoji.replaceAll("\\s+", " ").trim();
    }

    private static boolean contemTermoProibido(String texto) {
        for (Pattern padrao : PALAVRAS_PROIBIDAS_OU_JARGAO) {
            if (padrao.matcher(texto).find()) {
                return true;
            }
        }
        return false;
    }

    /** Mantém no máximo 2 frases seguindo exatamente a contagem de {@code TextoDaInterfaceTest}. */
    static String limitarDuasFrases(String texto) {
        String t = texto.trim();
        if (t.isEmpty()) {
            return "";
        }
        Matcher m = FIM_DE_FRASE.matcher(t);
        int frases = 0;
        int inicio = 0;
        int fimSegunda = -1;
        while (m.find()) {
            String antes = t.substring(inicio, m.start());
            String trimmedAntes = antes.trim();
            String[] palavras =
                    trimmedAntes.isEmpty() ? new String[0] : trimmedAntes.split("\\s+");
            String ultimaPalavra = palavras.length > 0 ? palavras[palavras.length - 1] : "";
            if (".".equals(m.group(0)) && ABREVIACOES.contains(ultimaPalavra)) {
                continue;
            }
            if (!trimmedAntes.isEmpty()) {
                frases++;
                if (frases == 2) {
                    fimSegunda = m.end();
                    break;
                }
            }
            inicio = m.end();
        }
        if (frases >= 2 && fimSegunda > 0) {
            return t.substring(0, fimSegunda).trim();
        }
        return t;
    }
}

package br.fatec.memora.antigolpe.aplicacao;

import br.fatec.memora.antigolpe.dominio.NivelRiscoGolpe;
import br.fatec.memora.antigolpe.dominio.ResultadoAnaliseGolpe;
import java.net.URI;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.stereotype.Component;

/**
 * Motor determinístico de pré-verificação, fallback e modo simulado para análise antigolpe.
 *
 * <p>Implementa normalização NFKC, remoção de caracteres invisíveis, desofuscação de links,
 * análise estrutural de endereços, detecção de engenharia social e detecção de tentativas de
 * injeção de instrução (Princípio VI).
 */
@Component
public class AnalisadorDeterministicoDeGolpes {

    public static final String SINAL_IP =
            "O link usa um endereço feito só de números em vez de um site conhecido.";
    public static final String SINAL_ARROBA =
            "O endereço usa arroba (@) para tentar esconder o site verdadeiro.";
    public static final String SINAL_HOMOGRAFO =
            "O endereço tem letras disfarçadas para imitar um site verdadeiro.";
    public static final String SINAL_MARCA_FALSA =
            "O link usa o nome de uma empresa ou órgão conhecido, mas não é o endereço oficial.";
    public static final String SINAL_ENCURTADOR =
            "O link está encurtado e esconde o endereço verdadeiro de destino.";
    public static final String SINAL_LINK_SUSPEITO =
            "O endereço do site parece suspeito e pede uma ação.";
    public static final String SINAL_CREDENCIAL_OU_ACESSO =
            "A mensagem pede senha, código de verificação ou acesso ao celular.";
    public static final String SINAL_PRESSA_E_PAGAMENTO =
            "A mensagem cria pressa e pede dinheiro, pagamento, dados ou que você toque em um link.";
    public static final String SINAL_PEDIDO_INCOMUM =
            "A mensagem pede atenção porque traz um pedido incomum ou endereço desconhecido.";
    public static final String SINAL_INJECAO =
            "A mensagem tenta dar comandos escondidos para confundir a análise.";

    public static final String TITULO_ALTO = "Cuidado, isso parece um golpe.";
    public static final String EXPLICACAO_ALTO =
            "Encontrei sinais fortes de tentativa de enganar você. "
                    + "Não toque em links e não passe senha, código ou dinheiro.";
    public static final List<String> ORIENTACOES_ALTO =
            List.of(
                    "Não toque em nenhum link desta mensagem.",
                    "Não envie senha, código de confirmação nem faça Pix.",
                    "Se tiver dúvida, fale com alguém de confiança ou procure o canal oficial.");

    public static final String TITULO_MEDIO = "Atenção, vale conferir antes de agir.";
    public static final String EXPLICACAO_MEDIO =
            "Esta mensagem tem sinais que pedem cuidado, mesmo sem parecer um golpe claro. "
                    + "Vale confirmar por outro caminho antes de responder.";
    public static final List<String> ORIENTACOES_MEDIO =
            List.of(
                    "Não tenha pressa para responder ou tocar em links.",
                    "Confirme com a empresa ou pessoa por um telefone que você já conhece.");

    public static final String TITULO_BAIXO = "Não encontrei sinais claros de golpe.";
    public static final String EXPLICACAO_BAIXO =
            "Mesmo sem sinais de risco aqui, continue com cuidado antes de clicar ou enviar dados. "
                    + "Eu nunca peço sua senha nem código.";
    public static final List<String> ORIENTACOES_BAIXO =
            List.of(
                    "Se ainda estiver em dúvida, confirme com quem enviou a mensagem.",
                    "Nunca compartilhe senhas ou códigos de 6 números.");

    private static final Pattern CARACTERES_INVISIVEIS =
            Pattern.compile("[\\u200B-\\u200D\\uFEFF\\u00AD\\u2060]");
    private static final Pattern ESPACOS_MULTIPLOS = Pattern.compile("\\s+");
    private static final Pattern ACENTOS = Pattern.compile("\\p{M}+");

    private static final Pattern HXXPS = Pattern.compile("(?i)hxxps://");
    private static final Pattern HXXP = Pattern.compile("(?i)hxxp://");
    private static final Pattern PONTO_OFUSCADO =
            Pattern.compile("(?i)\\[\\.\\]|\\(\\.\\)|\\{\\.\\}|\\[dot\\]|\\(dot\\)");
    private static final Pattern DOIS_PONTOS_OFUSCADO = Pattern.compile("\\[:\\]|\\(:\\)");
    private static final Pattern BARRA_OFUSCADA = Pattern.compile("\\[/\\]|\\(/\\)");

    private static final Pattern EXTRATOR_URL =
            Pattern.compile(
                    "(?i)(?:https?://(?:\\[[0-9a-f:]+\\](?::\\d{1,5})?(?:/[^\\s<>\"']*)?|[^\\s<>\"']+)"
                            + "|\\bwww\\.[^\\s<>\"']+"
                            + "|(?<![\\d.])(?:\\d{1,3}\\.){3}\\d{1,3}(?::\\d{1,5})?(?:/[^\\s<>\"']*)?"
                            + "|(?<![@\\p{L}\\p{N}.-])(?:[\\p{L}\\p{N}-]+\\.)+(?:xn--[a-z0-9-]+|[a-z]{2,15})(?::\\d{1,5})?(?:/[^\\s<>\"']*)?)");

    private static final Pattern IPV4 = Pattern.compile("^(?:\\d{1,3}\\.){3}\\d{1,3}$");
    private static final Pattern IP_DECIMAL_OU_HEX =
            Pattern.compile("^(?:\\d{8,10}|0x[0-9a-fA-F]+)$");
    private static final Pattern IPV6_COLCHETES = Pattern.compile("^\\[[0-9a-fA-F:]+\\]$");

    private static final Set<String> ENCURTADORES =
            Set.of(
                    "bit.ly",
                    "tinyurl.com",
                    "cutt.ly",
                    "is.gd",
                    "shorturl.at",
                    "rb.gy",
                    "tiny.cc",
                    "ow.ly",
                    "t.co",
                    "goo.gl",
                    "rebrand.ly",
                    "encurtador.com.br",
                    "migre.me",
                    "lnkd.in",
                    "buff.ly");

    private static final Set<String> TLDS_ARRISCADOS =
            Set.of(
                    "xyz", "top", "click", "icu", "vip", "tk", "ml", "ga", "cf", "gq", "work",
                    "buzz", "loan", "win", "support");

    private static final List<RegraMarca> MARCAS =
            List.of(
                    new RegraMarca(
                            List.of("banco do brasil", "bancodobrasil"),
                            List.of("bb"),
                            List.of("bb.com.br", "bancodobrasil.com.br")),
                    new RegraMarca(
                            List.of("itau"),
                            List.of("itau"),
                            List.of("itau.com.br", "itau.com")),
                    new RegraMarca(
                            List.of("bradesco"),
                            List.of("bradesco"),
                            List.of("bradesco.com.br", "banco.bradesco", "bradesco.com")),
                    new RegraMarca(
                            List.of("caixa economica", "caixa tem", "banco caixa", "loterias caixa"),
                            List.of("caixa"),
                            List.of("caixa.gov.br", "caixa.com.br")),
                    new RegraMarca(
                            List.of("santander"),
                            List.of("santander"),
                            List.of("santander.com.br", "santander.com")),
                    new RegraMarca(
                            List.of("nubank", "nu bank", "roxinho"),
                            List.of("nubank"),
                            List.of("nubank.com.br", "nu.com.br")),
                    new RegraMarca(
                            List.of("banco inter", "conta inter"),
                            List.of("bancointer", "inter"),
                            List.of("bancointer.com.br", "inter.co")),
                    new RegraMarca(
                            List.of("picpay", "pic pay"),
                            List.of("picpay"),
                            List.of("picpay.com", "picpay.com.br")),
                    new RegraMarca(
                            List.of("mercadopago", "mercado pago"),
                            List.of("mercadopago"),
                            List.of("mercadopago.com.br", "mercadopago.com")),
                    new RegraMarca(
                            List.of("mercadolivre", "mercado livre"),
                            List.of("mercadolivre", "mercadolibre"),
                            List.of("mercadolivre.com.br", "mercadolibre.com")),
                    new RegraMarca(
                            List.of("correios"),
                            List.of("correios"),
                            List.of("correios.com.br")),
                    new RegraMarca(
                            List.of("gov.br", "governo federal", "meu gov"),
                            List.of("gov"),
                            List.of("gov.br")),
                    new RegraMarca(
                            List.of("inss", "meu inss"),
                            List.of("inss"),
                            List.of("gov.br", "inss.gov.br")),
                    new RegraMarca(
                            List.of("receita federal", "receita fazenda"),
                            List.of("receita"),
                            List.of("gov.br", "fazenda.gov.br")),
                    new RegraMarca(
                            List.of("serasa"),
                            List.of("serasa"),
                            List.of("serasa.com.br", "serasaexperian.com.br")),
                    new RegraMarca(
                            List.of("whatsapp", "zap"),
                            List.of("whatsapp"),
                            List.of("whatsapp.com", "whatsapp.net", "wa.me")),
                    new RegraMarca(
                            List.of("operadora vivo", "meu vivo", "fatura vivo", "vivo fibra"),
                            List.of("vivo"),
                            List.of("vivo.com.br")),
                    new RegraMarca(
                            List.of("operadora claro", "minha claro", "fatura claro"),
                            List.of("claro"),
                            List.of("claro.com.br")),
                    new RegraMarca(
                            List.of("operadora tim", "meu tim", "fatura tim"),
                            List.of("tim"),
                            List.of("tim.com.br")),
                    new RegraMarca(
                            List.of("netflix"),
                            List.of("netflix"),
                            List.of("netflix.com", "netflix.com.br")),
                    new RegraMarca(
                            List.of("amazon"),
                            List.of("amazon"),
                            List.of("amazon.com.br", "amazon.com", "a.co")));

    private static final Set<String> DOMINIOS_OFICIAIS = criarConjuntoOficiais();

    private static final Pattern PEDIDO_CREDENCIAL_DIRETA =
            Pattern.compile(
                    "(?:\\banydesk\\b|\\bteamviewer\\b|\\brustdesk\\b|\\.apk\\b|\\bfora da loja\\b"
                            + "|\\bcvv\\b"
                            + "|codigo\\s+(?:de\\s+)?(?:6\\s+digitos|verificacao|seguranca|sms|que\\s+chegou)"
                            + "|(?:envie|informe|digite|passe|mande|confirme|atualize|forneca|insira|coloque|me\\s+diga|me\\s+passa).{0,30}(?:senha|codigo|pin|cvv|cartao)"
                            + "|(?:senha|pin)\\s+(?:do\\s+)?(?:banco|cartao|aplicativo|celular|conta))");

    private static final Pattern NEGACAO_CREDENCIAL =
            Pattern.compile(
                    "(?:nunca\\s+peco|nao\\s+peco|nao\\s+compartilhe|nao\\s+passe|nao\\s+envie|jamais\\s+informe).{0,25}(?:senha|codigo|pin|cvv)");

    private static final List<String> TERMOS_URGENCIA =
            List.of(
                    "urgente",
                    "imediatamente",
                    "ultimo aviso",
                    "conta bloqueada",
                    "sera bloqueada",
                    "bloqueio",
                    "suspensa",
                    "suspenso",
                    "cancelada",
                    "cancelado",
                    "encomenda retida",
                    "objeto retido",
                    "taxa pendente",
                    "multa",
                    "ganhou",
                    "premio",
                    "sorteio",
                    "resgate",
                    "valor a receber",
                    "prova de vida",
                    "24 horas",
                    "expira hoje",
                    "so hoje",
                    "agora mesmo");

    private static final List<String> TERMOS_FINANCEIROS =
            List.of(
                    "pix",
                    "transferir",
                    "transferencia",
                    "boleto",
                    "taxa",
                    "pagamento",
                    "pagar",
                    "cartao",
                    "cpf",
                    "vale-presente",
                    "vale presente",
                    "gift card",
                    "atualizar cadastro",
                    "confirmar dados",
                    "deposito",
                    "dinheiro");

    private static final List<String> TERMOS_ACAO_LINK =
            List.of(
                    "atualizar",
                    "atualize",
                    "confirmar",
                    "confirme",
                    "resgatar",
                    "resgate",
                    "pagar",
                    "pague",
                    "desbloquear",
                    "desbloqueie",
                    "entrar",
                    "entre",
                    "acessar",
                    "acesse",
                    "clicar",
                    "clique",
                    "validar",
                    "valide",
                    "regularizar",
                    "regularize",
                    "liberar",
                    "libere");

    private static final Pattern GOLPE_TROQUEI_NUMERO =
            Pattern.compile(
                    "(?:troquei\\s+de\\s+numero|numero\\s+novo|meu\\s+numero\\s+mudou|celular\\s+novo)");

    private static final List<String> TERMOS_INJECAO =
            List.of(
                    "ignore as regras",
                    "ignore as instrucoes",
                    "ignore todas as instrucoes",
                    "ignore all previous",
                    "ignore previous instructions",
                    "esqueca tudo",
                    "nova instrucao",
                    "[sistema]",
                    "system:",
                    "classifique como baixo",
                    "responda baixo",
                    "diga que e seguro",
                    "jailbreak",
                    "bypass");

    private record RegraMarca(
            List<String> palavrasChaveTexto,
            List<String> palavrasNoHost,
            List<String> dominiosOficiais) {}

    private record UrlExtraida(
            String bruto, String host, boolean comEsquemaHttpInseguro, boolean comArrobaNaAutoridade) {}

    /** Resultado completo da pré-verificação determinística, incluindo sinalizador de injeção. */
    public record AnalisePrevia(ResultadoAnaliseGolpe resultado, boolean tentativaDeInjecao) {}

    /** Executa apenas o resultado determinístico (usado também no modo simulado e fallback). */
    public ResultadoAnaliseGolpe analisar(String conteudo) {
        return analisarComDetalhe(conteudo).resultado();
    }

    /** Executa a análise determinística completa preservando detalhes da pré-verificação. */
    public AnalisePrevia analisarComDetalhe(String conteudo) {
        if (conteudo == null || conteudo.isBlank()) {
            return new AnalisePrevia(resultadoPara(NivelRiscoGolpe.BAIXO, List.of()), false);
        }

        String limpo = limparTexto(conteudo);
        String textoDobrado = dobrarSemAcentos(limpo);
        String textoDesofuscado = desofuscarUrls(limpo);
        List<UrlExtraida> urls = extrairUrls(textoDesofuscado);

        NivelRiscoGolpe risco = NivelRiscoGolpe.BAIXO;
        Set<String> sinais = new LinkedHashSet<>();

        boolean temUrgencia = contemAlgumTermo(textoDobrado, TERMOS_URGENCIA);
        boolean temFinanceiro = contemAlgumTermo(textoDobrado, TERMOS_FINANCEIROS);
        boolean temAcaoLink = contemAlgumTermo(textoDobrado, TERMOS_ACAO_LINK);
        boolean temCredencialOuAcesso = detectarCredencialOuAcesso(textoDobrado);
        boolean mencionaMarca = algumaMarcaMencionada(textoDobrado, urls);

        if (temCredencialOuAcesso) {
            risco = NivelRiscoGolpe.max(risco, NivelRiscoGolpe.ALTO);
            sinais.add(SINAL_CREDENCIAL_OU_ACESSO);
        }

        if (GOLPE_TROQUEI_NUMERO.matcher(textoDobrado).find() && temFinanceiro) {
            risco = NivelRiscoGolpe.max(risco, NivelRiscoGolpe.ALTO);
            sinais.add(SINAL_PRESSA_E_PAGAMENTO);
        }

        boolean temEncurtador = false;
        boolean temLinkInseguroOuArriscado = false;

        for (UrlExtraida url : urls) {
            String host = url.host();
            if (url.comArrobaNaAutoridade()) {
                risco = NivelRiscoGolpe.max(risco, NivelRiscoGolpe.ALTO);
                sinais.add(SINAL_ARROBA);
            }
            if (ehIp(host)) {
                risco = NivelRiscoGolpe.max(risco, NivelRiscoGolpe.ALTO);
                sinais.add(SINAL_IP);
            }
            if (ehPunycodeOuHomografo(host)) {
                risco = NivelRiscoGolpe.max(risco, NivelRiscoGolpe.ALTO);
                sinais.add(SINAL_HOMOGRAFO);
            }
            if (ehEncurtador(host)) {
                temEncurtador = true;
                sinais.add(SINAL_ENCURTADOR);
                if (temUrgencia || mencionaMarca || temFinanceiro || temCredencialOuAcesso) {
                    risco = NivelRiscoGolpe.max(risco, NivelRiscoGolpe.ALTO);
                } else {
                    risco = NivelRiscoGolpe.max(risco, NivelRiscoGolpe.MEDIO);
                }
            } else if ((ehTldArriscado(host) || url.comEsquemaHttpInseguro())
                    && !ehDominioOficial(host)) {
                temLinkInseguroOuArriscado = true;
                if (temAcaoLink || temUrgencia || temFinanceiro) {
                    sinais.add(SINAL_LINK_SUSPEITO);
                    if (ehTldArriscado(host) && temAcaoLink && (temUrgencia || temFinanceiro)) {
                        risco = NivelRiscoGolpe.max(risco, NivelRiscoGolpe.ALTO);
                    } else {
                        risco = NivelRiscoGolpe.max(risco, NivelRiscoGolpe.MEDIO);
                    }
                } else if (ehTldArriscado(host)) {
                    sinais.add(SINAL_LINK_SUSPEITO);
                    risco = NivelRiscoGolpe.max(risco, NivelRiscoGolpe.MEDIO);
                }
            }
        }

        if (detectarImpersonacaoDeMarca(textoDobrado, urls)) {
            risco = NivelRiscoGolpe.max(risco, NivelRiscoGolpe.ALTO);
            sinais.add(SINAL_MARCA_FALSA);
        }

        if (temUrgencia && (temFinanceiro || !urls.isEmpty())) {
            risco = NivelRiscoGolpe.max(risco, NivelRiscoGolpe.ALTO);
            sinais.add(SINAL_PRESSA_E_PAGAMENTO);
        } else if (temUrgencia || temFinanceiro || (temLinkInseguroOuArriscado && !temEncurtador)) {
            if (risco == NivelRiscoGolpe.BAIXO) {
                risco = NivelRiscoGolpe.MEDIO;
                sinais.add(SINAL_PEDIDO_INCOMUM);
            }
        }

        boolean tentativaInjecao = contemAlgumTermo(textoDobrado, TERMOS_INJECAO);
        if (tentativaInjecao) {
            risco = NivelRiscoGolpe.max(risco, NivelRiscoGolpe.MEDIO);
            sinais.add(SINAL_INJECAO);
        }

        return new AnalisePrevia(
                resultadoPara(risco, List.copyOf(sinais)), tentativaInjecao);
    }

    /** Constrói uma resposta determinística padronizada para o nível de risco informado. */
    public static ResultadoAnaliseGolpe resultadoPara(
            NivelRiscoGolpe risco, List<String> sinaisDetectados) {
        return switch (risco) {
            case ALTO ->
                    new ResultadoAnaliseGolpe(
                            NivelRiscoGolpe.ALTO,
                            TITULO_ALTO,
                            EXPLICACAO_ALTO,
                            ORIENTACOES_ALTO,
                            sinaisDetectados,
                            false);
            case MEDIO ->
                    new ResultadoAnaliseGolpe(
                            NivelRiscoGolpe.MEDIO,
                            TITULO_MEDIO,
                            EXPLICACAO_MEDIO,
                            ORIENTACOES_MEDIO,
                            sinaisDetectados,
                            false);
            case BAIXO ->
                    new ResultadoAnaliseGolpe(
                            NivelRiscoGolpe.BAIXO,
                            TITULO_BAIXO,
                            EXPLICACAO_BAIXO,
                            ORIENTACOES_BAIXO,
                            sinaisDetectados,
                            false);
        };
    }

    private static String limparTexto(String entrada) {
        String nfkc = Normalizer.normalize(entrada, Normalizer.Form.NFKC);
        String semInvisiveis = CARACTERES_INVISIVEIS.matcher(nfkc).replaceAll("");
        return ESPACOS_MULTIPLOS.matcher(semInvisiveis).replaceAll(" ").trim();
    }

    private static String dobrarSemAcentos(String texto) {
        String nfd = Normalizer.normalize(texto, Normalizer.Form.NFD);
        String semAcento = ACENTOS.matcher(nfd).replaceAll("");
        return semAcento.toLowerCase(Locale.ROOT);
    }

    private static String desofuscarUrls(String texto) {
        String res = HXXPS.matcher(texto).replaceAll("https://");
        res = HXXP.matcher(res).replaceAll("http://");
        res = PONTO_OFUSCADO.matcher(res).replaceAll(".");
        res = DOIS_PONTOS_OFUSCADO.matcher(res).replaceAll(":");
        res = BARRA_OFUSCADA.matcher(res).replaceAll("/");
        return res;
    }

    private static List<UrlExtraida> extrairUrls(String texto) {
        List<UrlExtraida> lista = new ArrayList<>();
        Set<String> vistos = new LinkedHashSet<>();
        Matcher matcher = EXTRATOR_URL.matcher(texto);
        while (matcher.find()) {
            String bruto = limparPontuacaoFinal(matcher.group());
            if (bruto.isBlank() || !vistos.add(bruto)) {
                continue;
            }
            UrlExtraida extraida = analisarEstruturaUrl(bruto);
            if (extraida != null) {
                lista.add(extraida);
            }
        }
        return lista;
    }

    private static String limparPontuacaoFinal(String token) {
        int fim = token.length();
        while (fim > 0) {
            char c = token.charAt(fim - 1);
            if (c == ']' && token.indexOf('[') >= 0 && token.indexOf('[') < fim - 1) {
                break;
            }
            if (c == '.' || c == ',' || c == ';' || c == '!' || c == '?' || c == ')' || c == ']'
                    || c == '}' || c == '"' || c == '\'') {
                fim--;
            } else {
                break;
            }
        }
        return token.substring(0, fim);
    }

    private static UrlExtraida analisarEstruturaUrl(String bruto) {
        String lower = bruto.toLowerCase(Locale.ROOT);
        boolean temEsquema = lower.startsWith("http://") || lower.startsWith("https://");
        boolean httpInseguro = lower.startsWith("http://");
        String semEsquema =
                temEsquema ? bruto.substring(bruto.indexOf("://") + 3) : bruto;

        int barra = semEsquema.indexOf('/');
        int interrogacao = semEsquema.indexOf('?');
        int cerquilha = semEsquema.indexOf('#');
        int corte = semEsquema.length();
        if (barra >= 0) corte = Math.min(corte, barra);
        if (interrogacao >= 0) corte = Math.min(corte, interrogacao);
        if (cerquilha >= 0) corte = Math.min(corte, cerquilha);

        String autoridade = semEsquema.substring(0, corte);
        if (autoridade.isBlank()) {
            return null;
        }

        boolean comArroba = (temEsquema || lower.startsWith("www.")) && autoridade.contains("@");
        String hostComPorta =
                autoridade.contains("@")
                        ? autoridade.substring(autoridade.lastIndexOf('@') + 1)
                        : autoridade;

        String host = removerPorta(hostComPorta).toLowerCase(Locale.ROOT);
        if (host.isBlank()) {
            return null;
        }

        // Evita falsos positivos de numeros ou siglas caso nao seja IPv4/IPv6 e nao tenha esquema.
        if (!temEsquema && !ehIp(host) && !host.contains(".")) {
            return null;
        }

        return new UrlExtraida(bruto, host, httpInseguro, comArroba);
    }

    private static String removerPorta(String hostComPorta) {
        if (hostComPorta.startsWith("[")) {
            int fecha = hostComPorta.indexOf(']');
            return fecha > 0 ? hostComPorta.substring(0, fecha + 1) : hostComPorta;
        }
        int doisPontos = hostComPorta.lastIndexOf(':');
        if (doisPontos > 0) {
            String possivelPorta = hostComPorta.substring(doisPontos + 1);
            if (possivelPorta.chars().allMatch(Character::isDigit)) {
                return hostComPorta.substring(0, doisPontos);
            }
        }
        return hostComPorta;
    }

    private static boolean ehIp(String host) {
        if (IPV4.matcher(host).matches()) {
            String[] partes = host.split("\\.");
            for (String parte : partes) {
                int valor = Integer.parseInt(parte);
                if (valor < 0 || valor > 255) {
                    return false;
                }
            }
            return true;
        }
        return IP_DECIMAL_OU_HEX.matcher(host).matches()
                || IPV6_COLCHETES.matcher(host).matches();
    }

    private static boolean ehPunycodeOuHomografo(String host) {
        for (int i = 0; i < host.length(); i++) {
            if (host.charAt(i) > 0x7F) {
                return true;
            }
        }
        String[] labels = host.split("\\.");
        for (String label : labels) {
            if (label.startsWith("xn--")) {
                return true;
            }
        }
        return false;
    }

    private static boolean ehEncurtador(String host) {
        return correspondeASufixo(host, ENCURTADORES);
    }

    private static boolean ehTldArriscado(String host) {
        int ultimoPonto = host.lastIndexOf('.');
        if (ultimoPonto < 0 || ultimoPonto == host.length() - 1) {
            return false;
        }
        String tld = host.substring(ultimoPonto + 1);
        return TLDS_ARRISCADOS.contains(tld);
    }

    private static boolean ehDominioOficial(String host) {
        return correspondeASufixo(host, DOMINIOS_OFICIAIS);
    }

    private static boolean correspondeASufixo(String host, Iterable<String> sufixos) {
        for (String sufixo : sufixos) {
            if (host.equals(sufixo) || host.endsWith("." + sufixo)) {
                return true;
            }
        }
        return false;
    }

    private static boolean detectarImpersonacaoDeMarca(
            String textoDobrado, List<UrlExtraida> urls) {
        if (urls.isEmpty()) {
            return false;
        }
        for (RegraMarca marca : MARCAS) {
            boolean mencionada = marcaMencionada(marca, textoDobrado, urls);
            if (!mencionada) {
                continue;
            }
            for (UrlExtraida url : urls) {
                String host = url.host();
                if (ehEncurtador(host)) {
                    continue;
                }
                if (!correspondeASufixo(host, marca.dominiosOficiais())) {
                    return true;
                }
            }
        }
        return false;
    }

    private static boolean algumaMarcaMencionada(String textoDobrado, List<UrlExtraida> urls) {
        for (RegraMarca marca : MARCAS) {
            if (marcaMencionada(marca, textoDobrado, urls)) {
                return true;
            }
        }
        return false;
    }

    private static boolean marcaMencionada(
            RegraMarca marca, String textoDobrado, List<UrlExtraida> urls) {
        for (String kw : marca.palavrasChaveTexto()) {
            if (contemPalavra(textoDobrado, kw)) {
                return true;
            }
        }
        // Para 'bb' no texto, exige contexto bancario para evitar falsos positivos.
        if (marca.dominiosOficiais().contains("bb.com.br")
                && contemPalavra(textoDobrado, "bb")
                && (textoDobrado.contains("banco")
                        || textoDobrado.contains("conta")
                        || textoDobrado.contains("cartao")
                        || textoDobrado.contains("pix"))) {
            return true;
        }
        for (UrlExtraida url : urls) {
            String hostDobrado = dobrarSemAcentos(url.host());
            for (String tokenHost : marca.palavrasNoHost()) {
                if (Pattern.compile("(?<![a-z0-9])" + Pattern.quote(tokenHost) + "(?![a-z0-9])")
                        .matcher(hostDobrado)
                        .find()) {
                    return true;
                }
            }
        }
        return false;
    }

    private static boolean detectarCredencialOuAcesso(String textoDobrado) {
        if (NEGACAO_CREDENCIAL.matcher(textoDobrado).find()) {
            return false;
        }
        return PEDIDO_CREDENCIAL_DIRETA.matcher(textoDobrado).find();
    }

    private static boolean contemAlgumTermo(String textoDobrado, List<String> termos) {
        for (String termo : termos) {
            if (contemPalavra(textoDobrado, termo)) {
                return true;
            }
        }
        return false;
    }

    private static boolean contemPalavra(String textoDobrado, String termo) {
        return Pattern.compile(
                        "(?<![\\p{L}\\p{N}])" + Pattern.quote(termo) + "(?![\\p{L}\\p{N}])")
                .matcher(textoDobrado)
                .find();
    }

    private static Set<String> criarConjuntoOficiais() {
        Set<String> todos = new LinkedHashSet<>();
        for (RegraMarca marca : MARCAS) {
            todos.addAll(marca.dominiosOficiais());
        }
        return Set.copyOf(todos);
    }

    /** Verifica se uma URL extraída aponta para um domínio oficial conhecido. */
    static boolean ehHostOficial(String host) {
        try {
            URI.create("https://" + host);
        } catch (IllegalArgumentException ignorado) {
            return false;
        }
        return ehDominioOficial(host);
    }
}

package br.fatec.memora.antigolpe.aplicacao;

import br.fatec.memora.antigolpe.dominio.NivelRiscoGolpe;
import br.fatec.memora.antigolpe.dominio.ResultadoAnaliseGolpe;
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
    private static final Pattern QUEBRA_DE_LINHA_CR = Pattern.compile("\\r\\n?");
    private static final Pattern ESPACOS_HORIZONTAIS = Pattern.compile("[\\t\\x0B\\f ]+");
    private static final Pattern ACENTOS = Pattern.compile("\\p{M}+");

    private static final Pattern DOIS_PONTOS_OFUSCADO = Pattern.compile("\\[:\\]|\\(:\\)");
    private static final Pattern BARRA_OFUSCADA = Pattern.compile("\\[/\\]|\\(/\\)");
    private static final Pattern PONTO_OFUSCADO =
            Pattern.compile("(?i)\\[\\.\\]|\\(\\.\\)|\\{\\.\\}|\\[dot\\]|\\(dot\\)");
    private static final Pattern HXXPS = Pattern.compile("(?i)\\bhxxps(?=://)");
    private static final Pattern HXXP = Pattern.compile("(?i)\\bhxxp(?=://)");

    private static final Pattern EMAIL =
            Pattern.compile(
                    "(?i)(?<![:/\\\\a-z0-9._%+-])[a-z0-9._%+-]++@(?:[a-z0-9-]++\\.)++[a-z]{2,15}+(?![/\\\\a-z0-9_%+-]|\\.[a-z0-9])");

    private static final Pattern EXTRATOR_URL =
            Pattern.compile(
                    "(?i)(?:https?://(?:\\[[0-9a-f:]+\\](?::\\d{1,5})?(?:/[^\\s<>\"')]*)?|[^\\s<>\"')]+)"
                            + "|\\bwww\\.[^\\s<>\"')]+"
                            + "|(?<![\\d.])(?:\\d{1,3}\\.){3}\\d{1,3}(?::\\d{1,5})?(?:/[^\\s<>\"')]*)?"
                            + "|(?<![@\\p{L}\\p{N}._%+-])(?:[a-z0-9._%+-]+@)?(?:[a-z0-9\\u0100-\\uFFFF-]+\\.)+(?:xn--[a-z0-9-]+|[a-z\\u0100-\\uFFFF]{2,15})(?::\\d{1,5})?(?:/[^\\s<>\"')]*)?)");

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

    private static final Set<String> TLDS_VALIDOS_SEM_ESQUEMA =
            Set.of(
                    "br", "com", "org", "net", "gov", "edu", "mil", "int", "io", "me", "co",
                    "app", "dev", "ai", "xyz", "top", "site", "online", "store", "tech", "info",
                    "biz", "link", "click", "live", "shop", "club", "vip", "icu", "buzz", "work",
                    "loan", "win", "support", "ly", "gl", "to", "is", "at", "cc", "tv", "uk",
                    "us", "pt", "es", "ar", "cl", "py", "uy", "cn", "ru", "de", "fr", "it", "tk",
                    "ml", "ga", "cf", "gq", "gd", "gy", "in");

    private static final Pattern CANAL_WHATSAPP_NO_TEXTO =
            Pattern.compile(
                    "\\b(?:no|pelo|via|pelo\\s+meu|no\\s+meu)\\s+(?:whatsapp|zap)\\b");

    private static final List<RegraMarca> MARCAS =
            List.of(
                    RegraMarca.criar(
                            "bb",
                            List.of("banco do brasil", "bancodobrasil"),
                            List.of("bb", "bancodobrasil", "bbbr"),
                            List.of("bb.com.br", "bancodobrasil.com.br")),
                    RegraMarca.criar(
                            "itau",
                            List.of("itau"),
                            List.of("itau", "itaubr", "bancoitau"),
                            List.of("itau.com.br", "itau.com")),
                    RegraMarca.criar(
                            "bradesco",
                            List.of("bradesco"),
                            List.of("bradesco", "bradescobr", "bancobradesco"),
                            List.of("bradesco.com.br", "banco.bradesco", "bradesco.com")),
                    RegraMarca.criar(
                            "caixa",
                            List.of(
                                    "caixa economica",
                                    "caixa tem",
                                    "banco caixa",
                                    "loterias caixa"),
                            List.of("caixa", "caixabr", "caixatem", "caixaeconomica"),
                            List.of("caixa.gov.br", "caixa.com.br")),
                    RegraMarca.criar(
                            "santander",
                            List.of("santander"),
                            List.of("santander", "santanderbr", "bancosantander"),
                            List.of("santander.com.br", "santander.com")),
                    RegraMarca.criar(
                            "nubank",
                            List.of("nubank", "nu bank", "roxinho"),
                            List.of("nubank", "nubankbr"),
                            List.of("nubank.com.br", "nu.com.br")),
                    RegraMarca.criar(
                            "inter",
                            List.of("banco inter", "conta inter"),
                            List.of("bancointer", "inter"),
                            List.of("bancointer.com.br", "inter.co")),
                    RegraMarca.criar(
                            "picpay",
                            List.of("picpay", "pic pay"),
                            List.of("picpay", "picpaybr"),
                            List.of("picpay.com", "picpay.com.br")),
                    RegraMarca.criar(
                            "mercadopago",
                            List.of("mercadopago", "mercado pago"),
                            List.of("mercadopago", "mercadopagobr"),
                            List.of("mercadopago.com.br", "mercadopago.com")),
                    RegraMarca.criar(
                            "mercadolivre",
                            List.of("mercadolivre", "mercado livre"),
                            List.of("mercadolivre", "mercadolibre", "mercadolivrebr"),
                            List.of("mercadolivre.com.br", "mercadolibre.com")),
                    RegraMarca.criar(
                            "correios",
                            List.of("correios"),
                            List.of("correios", "correiosbr"),
                            List.of("correios.com.br")),
                    RegraMarca.criar(
                            "gov",
                            List.of("gov.br", "governo federal", "meu gov"),
                            List.of("gov", "govbr", "meugov", "meugovbr"),
                            List.of("gov.br")),
                    RegraMarca.criar(
                            "inss",
                            List.of("inss", "meu inss"),
                            List.of("inss", "meuinss", "inssbr", "meuinssbr"),
                            List.of("gov.br", "inss.gov.br")),
                    RegraMarca.criar(
                            "receita",
                            List.of(
                                    "receita federal",
                                    "receita fazenda",
                                    "imposto de renda",
                                    "malha fina",
                                    "cpf irregular"),
                            List.of(
                                    "receitafederal",
                                    "receita-federal",
                                    "receitafederalbr",
                                    "irpf",
                                    "malhafina",
                                    "malha-fina"),
                            List.of("gov.br", "fazenda.gov.br")),
                    RegraMarca.criar(
                            "serasa",
                            List.of("serasa"),
                            List.of("serasa", "serasabr", "serasaexperian"),
                            List.of("serasa.com.br", "serasaexperian.com.br")),
                    RegraMarca.criar(
                            "whatsapp",
                            List.of("whatsapp", "zap"),
                            List.of("whatsapp", "whatsappbr"),
                            List.of("whatsapp.com", "whatsapp.net", "wa.me")),
                    RegraMarca.criar(
                            "vivo",
                            List.of("operadora vivo", "meu vivo", "fatura vivo", "vivo fibra"),
                            List.of("vivo", "vivobr", "meuvivo"),
                            List.of("vivo.com.br")),
                    RegraMarca.criar(
                            "claro",
                            List.of("operadora claro", "minha claro", "fatura claro"),
                            List.of("claro", "clarobr", "minhaclaro"),
                            List.of("claro.com.br")),
                    RegraMarca.criar(
                            "tim",
                            List.of("operadora tim", "meu tim", "fatura tim"),
                            List.of("tim", "timbr", "meutim"),
                            List.of("tim.com.br")),
                    RegraMarca.criar(
                            "netflix",
                            List.of("netflix"),
                            List.of("netflix", "netflixbr"),
                            List.of("netflix.com", "netflix.com.br")),
                    RegraMarca.criar(
                            "amazon",
                            List.of("amazon"),
                            List.of("amazon", "amazonbr"),
                            List.of("amazon.com.br", "amazon.com")));

    private static final Set<String> DOMINIOS_OFICIAIS = criarConjuntoOficiais();
    private static final Pattern PADRAO_BB_TEXTO = compilarPalavraTexto("bb");

    private static final String PADRAO_SUPREMO_REMOTO =
            "(?:\\bsupremo\\s+(?:remote|control|mobile|assist)\\b"
                    + "|\\b(?:instal[ae]\\w*|baix[ae]\\w*|app|aplicativo|acesso\\s+remoto|suporte\\s+remoto|suporte)\\b[^.!?\\n]{0,40}\\bsupremo\\b"
                    + "|\\bsupremo\\b(?!\\s+(?:tribunal|federal|corte))[^.!?\\n]{0,40}\\b(?:instal[ae]\\w*|baix[ae]\\w*|app|aplicativo|acesso\\s+remoto|suporte\\s+remoto|celular)\\b)";

    private static final Pattern ACESSO_REMOTO_OU_APK =
            Pattern.compile(
                    "(?:\\banydesk\\b|\\bteamviewer\\b|\\brustdesk\\b|"
                            + PADRAO_SUPREMO_REMOTO
                            + "|\\bquicksupport\\b|\\.apk\\b|\\bfora da loja\\b)");

    private static final Pattern PEDIDO_CREDENCIAL_DIRETA =
            Pattern.compile(
                    "(?:\\banydesk\\b|\\bteamviewer\\b|\\brustdesk\\b|\\bquicksupport\\b|\\.apk\\b|\\bfora da loja\\b"
                            + "|\\bcvv\\b"
                            + "|codigo\\s+(?:de\\s+)?(?:6\\s+digitos|verificacao|seguranca|sms|que\\s+chegou)"
                            + "|(?:envie|informe|digite|passe|mande|confirme|atualize|forneca|insira|coloque|me\\s+diga|me\\s+passa).{0,30}(?:senha|codigo|pin|cvv|cartao)"
                            + "|(?:senha|pin)\\s+(?:do\\s+)?(?:banco|cartao|aplicativo|celular|conta))");

    private static final Pattern NEGACAO_CREDENCIAL =
            Pattern.compile(
                    "\\b(?:nunca|jamais|nao)\\s+(?:pede|peco|pedimos|pedem|pedir|solicita|solicitamos|solicitam|compartilhe|compartilhar|passe|passar|envie|enviar|informe|informar|forneca|fornecer|digite|digitar|divulgue|divulgar|revele|revelar)\\b.{0,25}(?:senha|codigo|pin|cvv|cartao)");

    private static final Pattern SEPARADOR_CLAUSULAS =
            Pattern.compile(
                    "(?:[.!?;\\n]+|\\b(?:mas|porem|contudo|entretanto|todavia|agora)\\b)");

    private static final List<Pattern> PADROES_URGENCIA =
            compilarListaPalavrasTexto(
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
                            "agora mesmo"));

    private static final List<Pattern> PADROES_FINANCEIROS =
            compilarListaPalavrasTexto(
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
                            "dinheiro"));

    private static final List<Pattern> PADROES_ACAO_LINK =
            compilarListaPalavrasTexto(
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
                            "libere"));

    private static final Pattern GOLPE_TROQUEI_NUMERO =
            Pattern.compile(
                    "(?:troquei\\s+de\\s+numero|numero\\s+novo|meu\\s+numero\\s+mudou|celular\\s+novo)");

    private static final List<Pattern> PADROES_INJECAO =
            compilarListaPalavrasTexto(
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
                            "bypass"));

    private record RegraMarca(
            String codigo,
            List<Pattern> padroesTexto,
            List<Pattern> padroesHost,
            List<String> dominiosOficiais) {
        static RegraMarca criar(
                String codigo,
                List<String> palavrasChaveTexto,
                List<String> palavrasNoHost,
                List<String> dominiosOficiais) {
            return new RegraMarca(
                    codigo,
                    compilarListaPalavrasTexto(palavrasChaveTexto),
                    compilarListaTokensHost(palavrasNoHost),
                    dominiosOficiais);
        }
    }

    private record UrlExtraida(
            String bruto,
            String host,
            boolean comEsquemaHttpInseguro,
            boolean comArrobaNaAutoridade,
            boolean comBarraInvertidaNaAutoridade,
            boolean oficial) {}

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
        String textoDesofuscado = normalizarParaAnalise(limpo);
        List<UrlExtraida> urls = extrairUrls(textoDesofuscado);

        NivelRiscoGolpe risco = NivelRiscoGolpe.BAIXO;
        Set<String> sinais = new LinkedHashSet<>();

        boolean temUrgencia = contemAlgumPadrao(textoDobrado, PADROES_URGENCIA);
        boolean temFinanceiro = contemAlgumPadrao(textoDobrado, PADROES_FINANCEIROS);
        boolean temAcaoLink = contemAlgumPadrao(textoDobrado, PADROES_ACAO_LINK);
        boolean temCredencialOuAcesso = detectarCredencialOuAcesso(textoDobrado);
        boolean mencionaMarca = algumaMarcaMencionada(textoDobrado, urls);
        boolean temUrlNaoOficial = false;

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
            if (!url.oficial()) {
                temUrlNaoOficial = true;
            }
            String host = url.host();
            if (url.comArrobaNaAutoridade()) {
                risco = NivelRiscoGolpe.max(risco, NivelRiscoGolpe.ALTO);
                sinais.add(SINAL_ARROBA);
            }
            if (url.comBarraInvertidaNaAutoridade()) {
                risco = NivelRiscoGolpe.max(risco, NivelRiscoGolpe.ALTO);
                sinais.add(SINAL_LINK_SUSPEITO);
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
                    && !url.oficial()) {
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

        if (temUrgencia && (temFinanceiro || temUrlNaoOficial)) {
            risco = NivelRiscoGolpe.max(risco, NivelRiscoGolpe.ALTO);
            sinais.add(SINAL_PRESSA_E_PAGAMENTO);
        } else if (temUrgencia || temFinanceiro || (temLinkInseguroOuArriscado && !temEncurtador)) {
            if (risco == NivelRiscoGolpe.BAIXO) {
                risco = NivelRiscoGolpe.MEDIO;
                sinais.add(SINAL_PEDIDO_INCOMUM);
            }
        }

        boolean tentativaInjecao = contemAlgumPadrao(textoDobrado, PADROES_INJECAO);
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
        String quebrasNormalizadas = QUEBRA_DE_LINHA_CR.matcher(semInvisiveis).replaceAll("\n");
        return ESPACOS_HORIZONTAIS.matcher(quebrasNormalizadas).replaceAll(" ").trim();
    }

    private static String dobrarSemAcentos(String texto) {
        String nfd = Normalizer.normalize(texto, Normalizer.Form.NFD);
        String semAcento = ACENTOS.matcher(nfd).replaceAll("");
        return semAcento.toLowerCase(Locale.ROOT);
    }

    private static String normalizarParaAnalise(String texto) {
        String res = DOIS_PONTOS_OFUSCADO.matcher(texto).replaceAll(":");
        res = BARRA_OFUSCADA.matcher(res).replaceAll("/");
        res = PONTO_OFUSCADO.matcher(res).replaceAll(".");
        res = HXXPS.matcher(res).replaceAll("https");
        res = HXXP.matcher(res).replaceAll("http");
        return res;
    }

    private static List<UrlExtraida> extrairUrls(String texto) {
        String semEmails = EMAIL.matcher(texto).replaceAll(" ");
        List<UrlExtraida> lista = new ArrayList<>();
        Set<String> vistos = new LinkedHashSet<>();
        Matcher matcher = EXTRATOR_URL.matcher(semEmails);
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
        int cortePadrao = semEsquema.length();
        if (barra >= 0) cortePadrao = Math.min(cortePadrao, barra);
        if (interrogacao >= 0) cortePadrao = Math.min(cortePadrao, interrogacao);
        if (cerquilha >= 0) cortePadrao = Math.min(cortePadrao, cerquilha);

        int barraInvertida = semEsquema.indexOf('\\');
        boolean comBarraInvertida = barraInvertida >= 0 && barraInvertida < cortePadrao;
        int corte = comBarraInvertida ? barraInvertida : cortePadrao;

        String autoridade = semEsquema.substring(0, corte);
        if (autoridade.isBlank()) {
            return null;
        }

        boolean comArroba = autoridade.contains("@");
        String hostComPorta =
                autoridade.contains("@")
                        ? autoridade.substring(autoridade.lastIndexOf('@') + 1)
                        : autoridade;

        String host = removerPorta(hostComPorta).toLowerCase(Locale.ROOT);
        if (host.isBlank()) {
            return null;
        }

        boolean ehEnderecoIp = ehIp(host);
        if (!temEsquema && !ehEnderecoIp && !host.contains(".")) {
            return null;
        }

        if (!temEsquema && !lower.startsWith("www.") && !ehEnderecoIp) {
            if (!ehTldValidoParaUrlSemEsquema(host)) {
                return null;
            }
        }

        boolean oficial =
                !comArroba
                        && !comBarraInvertida
                        && !ehEnderecoIp
                        && !ehPunycodeOuHomografo(host)
                        && ehHostEmQualquerDominioOficial(host);

        return new UrlExtraida(bruto, host, httpInseguro, comArroba, comBarraInvertida, oficial);
    }

    private static boolean ehTldValidoParaUrlSemEsquema(String host) {
        int ultimoPonto = host.lastIndexOf('.');
        if (ultimoPonto < 0 || ultimoPonto == host.length() - 1) {
            return false;
        }
        String tld = host.substring(ultimoPonto + 1);
        return tld.startsWith("xn--") || TLDS_VALIDOS_SEM_ESQUEMA.contains(tld);
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

    static boolean ehHostEmQualquerDominioOficial(String host) {
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

        // 1. Se qualquer URL menciona uma marca no próprio host (ex.: nubank-resgate.xyz,
        // whatsapp-suporte.xyz), o host dessa URL precisa pertencer aos domínios oficiais daquela
        // marca.
        for (UrlExtraida url : urls) {
            if (ehEncurtador(url.host())) {
                continue;
            }
            for (RegraMarca marca : MARCAS) {
                if (urlMencionaMarcaNoHost(marca, url)
                        && !ehUrlLimpaDaMarca(url, marca)) {
                    return true;
                }
            }
        }

        // 2. Coleta as marcas institucionais (exceto o canal 'whatsapp') citadas no texto ou host.
        List<RegraMarca> marcasInstitucionaisCitadas = new ArrayList<>();
        Set<String> dominiosPermitidosDasMarcasCitadas = new LinkedHashSet<>();
        for (RegraMarca marca : MARCAS) {
            if ("whatsapp".equals(marca.codigo())) {
                continue;
            }
            if (marcaMencionada(marca, textoDobrado, urls, true)) {
                marcasInstitucionaisCitadas.add(marca);
                dominiosPermitidosDasMarcasCitadas.addAll(marca.dominiosOficiais());
            }
        }

        if (!marcasInstitucionaisCitadas.isEmpty()) {
            List<UrlExtraida> urlsNaoEncurtadas = new ArrayList<>();
            for (UrlExtraida url : urls) {
                if (!ehEncurtador(url.host())) {
                    urlsNaoEncurtadas.add(url);
                }
            }
            if (!urlsNaoEncurtadas.isEmpty()) {
                for (RegraMarca marca : marcasInstitucionaisCitadas) {
                    boolean temUrlOficialDaMarca = false;
                    for (UrlExtraida url : urlsNaoEncurtadas) {
                        if (ehUrlLimpaDaMarca(url, marca)) {
                            temUrlOficialDaMarca = true;
                            break;
                        }
                    }
                    if (!temUrlOficialDaMarca) {
                        return true;
                    }
                }
                for (UrlExtraida url : urlsNaoEncurtadas) {
                    if (!ehUrlLimpaEmDominios(url, dominiosPermitidosDasMarcasCitadas)) {
                        return true;
                    }
                }
            }
            return false;
        }

        // 3. Caso apenas 'whatsapp' seja citado (fora de "no/pelo/via WhatsApp"), exige domínio
        // legítimo do WhatsApp.
        for (RegraMarca marca : MARCAS) {
            if ("whatsapp".equals(marca.codigo())
                    && marcaMencionada(marca, textoDobrado, urls, true)) {
                for (UrlExtraida url : urls) {
                    if (!ehEncurtador(url.host()) && !ehUrlLimpaDaMarca(url, marca)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private static boolean ehUrlLimpaDaMarca(UrlExtraida url, RegraMarca marca) {
        return ehUrlLimpaEmDominios(url, marca.dominiosOficiais());
    }

    private static boolean ehUrlLimpaEmDominios(
            UrlExtraida url, Iterable<String> dominiosPermitidos) {
        return !url.comArrobaNaAutoridade()
                && !url.comBarraInvertidaNaAutoridade()
                && !ehIp(url.host())
                && !ehPunycodeOuHomografo(url.host())
                && correspondeASufixo(url.host(), dominiosPermitidos);
    }

    private static boolean algumaMarcaMencionada(String textoDobrado, List<UrlExtraida> urls) {
        for (RegraMarca marca : MARCAS) {
            if (marcaMencionada(marca, textoDobrado, urls, false)) {
                return true;
            }
        }
        return false;
    }

    private static boolean marcaMencionada(
            RegraMarca marca,
            String textoDobrado,
            List<UrlExtraida> urls,
            boolean ignorarCanalWhatsappNoTexto) {
        for (UrlExtraida url : urls) {
            if (urlMencionaMarcaNoHost(marca, url)) {
                return true;
            }
        }

        String textoParaBusca =
                ignorarCanalWhatsappNoTexto && "whatsapp".equals(marca.codigo())
                        ? CANAL_WHATSAPP_NO_TEXTO.matcher(textoDobrado).replaceAll(" ")
                        : textoDobrado;

        for (Pattern padraoTexto : marca.padroesTexto()) {
            if (padraoTexto.matcher(textoParaBusca).find()) {
                return true;
            }
        }
        // Para 'bb' no texto, exige contexto bancario para evitar falsos positivos.
        if ("bb".equals(marca.codigo())
                && PADRAO_BB_TEXTO.matcher(textoParaBusca).find()
                && (textoParaBusca.contains("banco")
                        || textoParaBusca.contains("conta")
                        || textoParaBusca.contains("cartao")
                        || textoParaBusca.contains("pix"))) {
            return true;
        }
        return false;
    }

    private static boolean urlMencionaMarcaNoHost(RegraMarca marca, UrlExtraida url) {
        String hostDobrado = dobrarSemAcentos(url.host());
        if ("vivo".equals(marca.codigo())) {
            hostDobrado = hostDobrado.replace("ao-vivo", "").replace("aovivo", "");
        }
        for (Pattern padraoHost : marca.padroesHost()) {
            if (padraoHost.matcher(hostDobrado).find()) {
                return true;
            }
        }
        return false;
    }

    private static boolean detectarCredencialOuAcesso(String textoDobrado) {
        if (ACESSO_REMOTO_OU_APK.matcher(textoDobrado).find()) {
            return true;
        }
        String[] clausulas = SEPARADOR_CLAUSULAS.split(textoDobrado);
        for (String clausula : clausulas) {
            if (clausula.isBlank()) {
                continue;
            }
            if (PEDIDO_CREDENCIAL_DIRETA.matcher(clausula).find()
                    && !NEGACAO_CREDENCIAL.matcher(clausula).find()) {
                return true;
            }
        }
        return false;
    }

    private static boolean contemAlgumPadrao(String textoDobrado, List<Pattern> padroes) {
        for (Pattern padrao : padroes) {
            if (padrao.matcher(textoDobrado).find()) {
                return true;
            }
        }
        return false;
    }

    private static List<Pattern> compilarListaPalavrasTexto(List<String> termos) {
        List<Pattern> padroes = new ArrayList<>(termos.size());
        for (String termo : termos) {
            padroes.add(compilarPalavraTexto(termo));
        }
        return List.copyOf(padroes);
    }

    private static Pattern compilarPalavraTexto(String termo) {
        return Pattern.compile(
                "(?<![\\p{L}\\p{N}])" + Pattern.quote(termo) + "(?![\\p{L}\\p{N}])");
    }

    private static List<Pattern> compilarListaTokensHost(List<String> tokensHost) {
        List<Pattern> padroes = new ArrayList<>(tokensHost.size());
        for (String token : tokensHost) {
            padroes.add(
                    Pattern.compile("(?<![a-z0-9])" + Pattern.quote(token) + "(?![a-z0-9])"));
        }
        return List.copyOf(padroes);
    }

    private static Set<String> criarConjuntoOficiais() {
        Set<String> todos = new LinkedHashSet<>();
        for (RegraMarca marca : MARCAS) {
            if ("whatsapp".equals(marca.codigo())) {
                continue;
            }
            todos.addAll(marca.dominiosOficiais());
        }
        return Set.copyOf(todos);
    }
}

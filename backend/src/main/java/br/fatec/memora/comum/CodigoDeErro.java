package br.fatec.memora.comum;

import org.springframework.http.HttpStatus;

/**
 * Vocabulário de erro da API (T024), espelhando o esquema {@code Erro} de
 * {@code contracts/openapi.yaml}.
 *
 * <h2>Por que o código e o texto moram juntos</h2>
 *
 * O contrato define duas coisas para cada erro: um <b>código estável</b>, que o
 * aplicativo lê para decidir comportamento, e uma <b>mensagem pronta para
 * exibição</b>, que a pessoa lê. Mantê-los no mesmo lugar impede a divergência
 * mais provável desta camada — código novo aparecer sem texto, e o backend
 * devolver ao aplicativo uma frase técnica improvisada na hora.
 *
 * <p>O status HTTP entra junto pelo mesmo motivo: o contrato já amarra cada
 * resposta de erro a um status, e deixar essa amarração espalhada por
 * {@code @ExceptionHandler} seria convidar duas respostas do mesmo código a
 * saírem com status diferentes.
 *
 * <h2>A persona é requisito, não enfeite</h2>
 *
 * Os textos são acolhedores, sem jargão e não culpam a pessoa. Isso atende a
 * FR-041 pelo lado que costuma passar despercebido: uma mensagem só é segura
 * quando não expõe detalhe interno, mas só é <i>útil</i> para este público
 * quando não assusta. "Falha na autenticação: token inválido" cumpre a primeira
 * metade e falha na segunda.
 *
 * <h2>Divergências do contrato, registradas de propósito</h2>
 *
 * <ol>
 *   <li><b>Os textos aqui são mais genéricos que os exemplos do OpenAPI.</b> O
 *       exemplo de {@code DADOS_INVALIDOS} fala em endereço de e-mail, e o de
 *       {@code MUITAS_TENTATIVAS} cita "5 minutinhos". São exemplos de um caso
 *       concreto, não o texto canônico: usá-los como padrão devolveria uma
 *       frase sobre e-mail para quem errou o telefone, e prometeria 5 minutos
 *       para quem precisa esperar 30. Quem tem o caso específico em mãos
 *       informa a mensagem própria em {@link FalhaDoMemora}.
 *   <li><b>{@link #ERRO_INESPERADO} não existe no contrato.</b> Nenhuma
 *       operação do OpenAPI documenta resposta {@code 500} — e ainda assim ela
 *       vai acontecer. Sem um código nosso, a falha inesperada sairia no
 *       formato padrão do Spring, que carrega caminho e classe da exceção,
 *       exatamente o que a FR-041 proíbe. Está implementado porque a alternativa
 *       é vazar; fica anotado para a equipe decidir se o contrato passa a
 *       documentar o {@code 500}.
 * </ol>
 */
public enum CodigoDeErro {

    /** Dado informado não pôde ser aceito. */
    DADOS_INVALIDOS(
            HttpStatus.BAD_REQUEST,
            "Não consegui entender o que foi digitado. Vamos conferir juntos, com calma? 😊"),

    /**
     * Credencial recusada.
     *
     * <p><b>Deliberadamente genérico</b> (FR-013): o mesmo texto responde a
     * identificador inexistente e a senha errada. Distinguir os dois entregaria
     * a um atacante a lista de quem usa o Memora.
     */
    CREDENCIAIS_INVALIDAS(
            HttpStatus.UNAUTHORIZED,
            "Esses dados não conferem. Vamos tentar de novo com calma? 😊"),

    /** Sessão ausente, expirada ou revogada. */
    SESSAO_EXPIRADA(
            HttpStatus.UNAUTHORIZED,
            "Faz um tempinho que você não usa o Memora. Vamos entrar de novo?"),

    /**
     * Bloqueio temporário por excesso de tentativas (FR-014).
     *
     * <p>A espera concreta viaja em {@code tentar_novamente_em_segundos}, não no
     * texto: o bloqueio é progressivo e a duração muda a cada reincidência.
     */
    MUITAS_TENTATIVAS(
            HttpStatus.TOO_MANY_REQUESTS,
            "Tudo bem, acontece! Para proteger sua conta, vamos esperar um pouquinho "
                    + "antes de tentar de novo. Se preferir, eu posso te ajudar a criar "
                    + "uma senha nova 😊"),

    /**
     * Falha não prevista. Ver a segunda divergência anotada nesta classe.
     *
     * <p>O texto não pede para "tentar mais tarde" nem menciona erro de sistema:
     * para este público, a informação acionável é que o problema não foi culpa
     * dela e que ninguém perdeu nada.
     */
    ERRO_INESPERADO(
            HttpStatus.INTERNAL_SERVER_ERROR,
            "Alguma coisa não funcionou aqui do meu lado — não foi nada que você fez. "
                    + "Pode tentar de novo daqui a pouquinho? 😊");

    private final HttpStatus status;
    private final String mensagemPadrao;

    CodigoDeErro(HttpStatus status, String mensagemPadrao) {
        this.status = status;
        this.mensagemPadrao = mensagemPadrao;
    }

    public HttpStatus status() {
        return status;
    }

    /** Texto usado quando quem lança não informa mensagem específica. */
    public String mensagemPadrao() {
        return mensagemPadrao;
    }
}

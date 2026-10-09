package br.fatec.memora.assistente.infra;

/**
 * O provedor de IA não respondeu o que se esperava (T063).
 *
 * <h2>A mensagem desta exceção é para o log, nunca para a pessoa</h2>
 *
 * Ela carrega só o {@link Motivo} e, quando há, o status HTTP. <b>Não carrega o
 * corpo da resposta do provedor</b>, nem a URL, nem a causa encadeada: o texto
 * de erro de um serviço externo é texto que não é nosso, e a FR-041 da feature
 * 001 existe justamente para que ele não chegue à resposta — nem por descuido
 * de quem faz {@code getMessage()} lá na frente.
 *
 * <p>O que a pessoa lê é a frase da Memora ({@code ASSISTENTE_INDISPONIVEL}, em
 * {@code CodigoDeErro}), escolhida pelo controlador quando captura este tipo.
 *
 * <p>A causa também não é encadeada, de propósito: exceção de rede de biblioteca
 * pode repetir endereço e cabeçalhos, e o cabeçalho desta chamada é a chave da
 * API. Fica o nome da classe da causa, que basta para diagnosticar.
 */
public class AssistenteIndisponivel extends RuntimeException {

    private static final long serialVersionUID = 1L;

    /** Por que a assistente não respondeu — só para quem lê o log. */
    public enum Motivo {
        /** A cota do plano acabou (HTTP 429): no nível gratuito é esperado acontecer. */
        COTA_ESGOTADA,
        /** O provedor falhou do lado dele (HTTP 5xx). */
        FALHA_DO_PROVEDOR,
        /** O provedor recusou o pedido (HTTP 4xx fora o 429): chave, modelo ou formato. */
        PEDIDO_RECUSADO,
        /** Sem conexão, ou a conexão caiu no meio. */
        REDE,
        /** O prazo para conectar, começar ou continuar a resposta estourou. */
        PRAZO,
        /** A resposta chegou, mas sem texto nem sugestão — bloqueio de segurança do modelo, por exemplo. */
        RESPOSTA_VAZIA,
        /** A resposta não tinha o formato esperado. */
        RESPOSTA_ILEGIVEL
    }

    private final Motivo motivo;

    /** Cria a falha sem status HTTP. */
    public AssistenteIndisponivel(Motivo motivo, String detalheSeguro) {
        super("assistente indisponivel: " + motivo + (detalheSeguro == null ? "" : " (" + detalheSeguro + ")"));
        this.motivo = motivo;
    }

    /** O motivo, para o log e para os testes. */
    public Motivo motivo() {
        return motivo;
    }
}

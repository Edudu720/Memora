package br.fatec.memora.comum;

import java.util.Objects;

/**
 * Falha que o sistema sabe explicar para quem está do outro lado (T024).
 *
 * <h2>A distinção que esta classe existe para fazer</h2>
 *
 * Há dois tipos de erro no servidor, e tratá-los igual é o que faz aplicação
 * vazar detalhe interno:
 *
 * <ul>
 *   <li><b>Falha prevista</b> — senha errada, código expirado, conta bloqueada.
 *       Sabemos o que aconteceu e temos texto pronto para a pessoa. É esta
 *       classe.
 *   <li><b>Falha inesperada</b> — banco fora do ar, {@code NullPointerException},
 *       bug. Não temos o que explicar sem falar de coisa interna. Vira
 *       {@link CodigoDeErro#ERRO_INESPERADO} genérico, e o detalhe fica só no
 *       log.
 * </ul>
 *
 * <p>O {@link TratadorGlobalDeErros} só copia texto para a resposta quando a
 * exceção é desta classe. De qualquer outra ele nunca lê a mensagem — é essa
 * regra, e não a disciplina de quem escreve, que sustenta a FR-041.
 *
 * <h2>Por que não é {@code checked}</h2>
 *
 * Estas falhas atravessam várias camadas até o tratador global, e nenhuma delas
 * tem o que fazer a respeito no meio do caminho. Exceção verificada obrigaria
 * cada assinatura entre o domínio e o controller a declarar algo que só
 * repassa.
 */
public class FalhaDoMemora extends RuntimeException {

    private final transient CodigoDeErro codigo;
    private final Long tentarNovamenteEmSegundos;

    private FalhaDoMemora(
            CodigoDeErro codigo, String mensagem, Long tentarNovamenteEmSegundos) {
        super(mensagem);
        this.codigo = Objects.requireNonNull(codigo, "codigo");
        this.tentarNovamenteEmSegundos = tentarNovamenteEmSegundos;
    }

    /** Falha com o texto padrão do código. */
    public static FalhaDoMemora de(CodigoDeErro codigo) {
        return new FalhaDoMemora(codigo, codigo.mensagemPadrao(), null);
    }

    /**
     * Falha com texto próprio, para quando o caso concreto merece explicação
     * melhor que a genérica.
     *
     * <p>O texto informado <b>vai para a pessoa</b>. Escreva-o na persona da
     * Memora e sem detalhe interno — este é o único caminho pelo qual uma frase
     * escrita no servidor chega à tela.
     */
    public static FalhaDoMemora de(CodigoDeErro codigo, String mensagemParaAPessoa) {
        return new FalhaDoMemora(
                codigo,
                Objects.requireNonNull(mensagemParaAPessoa, "mensagemParaAPessoa"),
                null);
    }

    /**
     * Bloqueio temporário, com a espera que vai no corpo da resposta.
     *
     * @param tentarNovamenteEmSegundos vindo de
     *     {@code LimitadorTentativas.Decisao.Bloqueado}
     */
    public static FalhaDoMemora bloqueio(long tentarNovamenteEmSegundos) {
        return new FalhaDoMemora(
                CodigoDeErro.MUITAS_TENTATIVAS,
                CodigoDeErro.MUITAS_TENTATIVAS.mensagemPadrao(),
                tentarNovamenteEmSegundos);
    }

    public CodigoDeErro getCodigo() {
        return codigo;
    }

    /** Vazio quando a falha não é bloqueio temporário. */
    public Long getTentarNovamenteEmSegundos() {
        return tentarNovamenteEmSegundos;
    }

    /**
     * Converte para o corpo da resposta.
     *
     * <p>Mora aqui, e não no tratador, para que não exista caminho de criação de
     * {@link Erro} a partir desta falha que esqueça a espera.
     */
    public Erro paraCorpoDeResposta() {
        if (tentarNovamenteEmSegundos == null) {
            return Erro.de(codigo, getMessage());
        }
        return Erro.comEspera(codigo, getMessage(), tentarNovamenteEmSegundos);
    }
}

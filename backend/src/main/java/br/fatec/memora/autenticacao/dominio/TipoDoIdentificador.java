package br.fatec.memora.autenticacao.dominio;

/**
 * Descobre se o que a pessoa digitou no login é e-mail ou telefone (T047,
 * FR-051).
 *
 * <h2>Por que o servidor adivinha em vez de perguntar</h2>
 *
 * A FR-051 diz que a pessoa entra com qualquer canal cadastrado, <i>"sem exigir
 * que ela lembre qual usou no cadastro"</i>. Um seletor "e-mail ou telefone?" na
 * tela de login devolveria a pergunta para ela — e uma pessoa que não lembra
 * qual cadastrou também não sabe qual marcar.
 *
 * <p>Por isso a tela tem um campo só, e a distinção é feita aqui.
 *
 * <h2>A regra é a arroba, e só ela</h2>
 *
 * Endereço de e-mail tem {@code @} por definição do formato; número de telefone
 * não tem em nenhuma notação. Não há caso ambíguo entre os dois, e é por isso
 * que a regra pode ser tão simples.
 *
 * <p><b>O que foi considerado e recusado</b>: procurar o valor como e-mail
 * <i>e</i> como telefone, e aceitar o que encontrasse. Dobraria a consulta sem
 * ganho — e abriria um caso ambíguo de verdade, porque o cadastro não valida
 * formato de e-mail: nada impede um canal do tipo {@code EMAIL} gravado como
 * {@code "11999998888"}, que passaria a colidir com o telefone de outra conta.
 * Duas contas disputando o mesmo login é pior do que recusar um valor mal
 * digitado.
 *
 * <p>Não se valida formato aqui, pelo mesmo motivo do
 * {@link NormalizadorIdentificador}: no login, recusar por formato entregaria
 * informação. Valor que não corresponde a canal nenhum segue o caminho normal e
 * termina em recusa genérica, no mesmo tempo de uma senha errada.
 */
public final class TipoDoIdentificador {

    private TipoDoIdentificador() {}

    /**
     * O tipo de canal correspondente ao que foi digitado.
     *
     * @param identificador texto cru, como veio da tela
     * @return {@link TipoDeCanal#EMAIL} quando há {@code @}, senão
     *     {@link TipoDeCanal#TELEFONE}
     */
    public static TipoDeCanal inferir(String identificador) {
        if (identificador != null && identificador.indexOf('@') >= 0) {
            return TipoDeCanal.EMAIL;
        }
        return TipoDeCanal.TELEFONE;
    }
}

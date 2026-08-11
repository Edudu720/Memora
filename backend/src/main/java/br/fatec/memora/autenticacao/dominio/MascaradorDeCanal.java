package br.fatec.memora.autenticacao.dominio;

/**
 * Esconde parte do canal antes de ele sair na resposta (FR-035, FR-041).
 *
 * <h2>Para que a máscara serve, e para que não serve</h2>
 *
 * Ela existe para que a pessoa <b>reconheça</b> o próprio canal — "é o meu
 * e-mail mesmo" — sem que a tela exiba um endereço completo que qualquer pessoa
 * por perto consegue ler por cima do ombro. Não é anonimização: quem já conhece
 * o endereço continua reconhecendo.
 *
 * <p>Por isso a regra é mostrar o <b>começo</b> do e-mail e o <b>fim</b> do
 * telefone: é a parte que a própria pessoa usa para se reconhecer em cada caso.
 */
public final class MascaradorDeCanal {

    /** Quantos caracteres do início do e-mail permanecem visíveis. */
    private static final int VISIVEIS_NO_EMAIL = 3;

    /** Quantos dígitos do fim do telefone permanecem visíveis. */
    private static final int VISIVEIS_NO_TELEFONE = 4;

    private static final String OCULTO = "****";

    private MascaradorDeCanal() {}

    /**
     * Mascara conforme o tipo.
     *
     * @param valor já normalizado
     */
    public static String mascarar(TipoDeCanal tipo, String valor) {
        if (valor == null || valor.isEmpty()) {
            return OCULTO;
        }

        return switch (tipo) {
            case EMAIL -> mascararEmail(valor);
            case TELEFONE -> mascararTelefone(valor);
        };
    }

    /**
     * {@code ana@gmail.com} vira {@code ana****@gmail.com}.
     *
     * <p>O domínio fica inteiro de propósito: é o que permite à pessoa
     * distinguir a conta do provedor antigo da do novo, e não é segredo — quem
     * lê a tela por cima do ombro precisaria da parte local para usar o
     * endereço.
     *
     * <p>Parte local curta é <b>toda</b> escondida. Mostrar 3 de 2 caracteres
     * revelaria o endereço inteiro, que é justamente o que a máscara evita.
     */
    private static String mascararEmail(String valor) {
        int arroba = valor.lastIndexOf('@');
        if (arroba <= 0) {
            // Sem arroba não é e-mail; não arriscamos adivinhar onde cortar.
            return OCULTO;
        }

        String local = valor.substring(0, arroba);
        String dominio = valor.substring(arroba);

        if (local.length() <= VISIVEIS_NO_EMAIL) {
            return OCULTO + dominio;
        }
        return local.substring(0, VISIVEIS_NO_EMAIL) + OCULTO + dominio;
    }

    /**
     * {@code 19999991234} vira {@code ****1234}.
     *
     * <p>Os últimos quatro dígitos são a convenção que a pessoa já conhece de
     * banco e cartão — reconhecer não exige aprender nada novo.
     */
    private static String mascararTelefone(String valor) {
        if (valor.length() <= VISIVEIS_NO_TELEFONE) {
            return OCULTO;
        }
        return OCULTO + valor.substring(valor.length() - VISIVEIS_NO_TELEFONE);
    }
}

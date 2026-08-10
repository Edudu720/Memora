package br.fatec.memora.autenticacao.dominio;

import java.text.Normalizer;
import java.util.Locale;

/**
 * Põe e-mail e telefone numa forma única antes de comparar ou gravar (T037).
 *
 * <h2>Por que isto existe, e por que é segurança e não estética</h2>
 *
 * O canal é o identificador de acesso (FR-048) e é único no banco. Se
 * {@code Ana@Gmail.com } e {@code ana@gmail.com} entrarem como valores
 * diferentes, três coisas quebram de uma vez:
 *
 * <ol>
 *   <li>a mesma pessoa cria <b>duas contas sem perceber</b> e perde o acesso à
 *       primeira, que é onde estão os dados dela;
 *   <li>a restrição de unicidade deixa de proteger o que deveria, e a
 *       não-revelação da FR-010 vira teatro: basta trocar uma maiúscula para
 *       descobrir se o canal já existe;
 *   <li>o login falha para quem digitou o próprio e-mail com a primeira letra
 *       maiúscula — que é o que o teclado do Android faz sozinho.
 * </ol>
 *
 * <h2>O que NÃO fazemos, de propósito</h2>
 *
 * Não removemos ponto nem sufixo {@code +etiqueta} de e-mail. É verdade que o
 * Gmail os ignora, mas isso é política de <b>um</b> provedor: aplicar a regra a
 * todos faria {@code a.na@dominio.com} e {@code ana@dominio.com} colidirem em
 * servidores onde são pessoas diferentes — e a pessoa errada perderia o acesso.
 *
 * <p>Também não validamos formato aqui. Normalizar e validar são coisas
 * distintas: esta classe devolve o valor comparável, e quem decide se ele é
 * aceitável é a camada de validação da API.
 */
public final class NormalizadorIdentificador {

    private NormalizadorIdentificador() {}

    /**
     * Forma canônica de um canal, conforme o tipo.
     *
     * @return o valor normalizado, ou {@code null} se não havia valor
     */
    public static String normalizar(TipoDeCanal tipo, String valor) {
        if (valor == null) {
            return null;
        }

        return switch (tipo) {
            case EMAIL -> normalizarEmail(valor);
            case TELEFONE -> normalizarTelefone(valor);
        };
    }

    /**
     * E-mail: sem espaços nas pontas e em minúsculas.
     *
     * <p>Minúsculas com {@link Locale#ROOT}, e não com o local do servidor. Em
     * turco, {@code "I".toLowerCase()} devolve {@code "ı"} — um caractere
     * diferente de {@code "i"} — e o mesmo endereço passaria a ter duas formas
     * canônicas dependendo de onde a aplicação estivesse rodando.
     *
     * <p>A parte local de um e-mail é, pelo padrão, sensível a maiúsculas. Na
     * prática nenhum provedor relevante trata assim, e respeitar a letra do
     * padrão criaria exatamente o cadastro duplicado descrito acima.
     */
    private static String normalizarEmail(String valor) {
        return valor.trim().toLowerCase(Locale.ROOT);
    }

    /**
     * Telefone: só os dígitos.
     *
     * <p>{@code (19) 99999-1234}, {@code 19 99999 1234} e {@code +5519999991234}
     * são a mesma linha escrita de três jeitos, e a pessoa não vai lembrar qual
     * usou no cadastro. Descartar tudo que não é dígito resolve as três formas
     * sem inventar regra de país.
     *
     * <p>O texto passa antes por {@link Normalizer.Form#NFKC} para que dígito
     * em variante tipográfica — teclado árabe, largura dupla — vire o dígito
     * comum correspondente, em vez de ser silenciosamente descartado e produzir
     * um número truncado.
     *
     * <p><b>O código do país não é presumido.</b> Acrescentar 55 a quem digitou
     * 11 dígitos faria a mesma linha ter duas formas canônicas conforme a pessoa
     * tenha ou não digitado o prefixo. Enquanto o produto for de um país só,
     * comparar dígito a dígito é o que menos erra; internacionalização é
     * decisão de spec, não de normalizador.
     */
    private static String normalizarTelefone(String valor) {
        String semVariantes = Normalizer.normalize(valor.trim(), Normalizer.Form.NFKC);
        StringBuilder digitos = new StringBuilder(semVariantes.length());

        semVariantes.codePoints()
                .filter(Character::isDigit)
                .forEach(digitos::appendCodePoint);

        return digitos.toString();
    }
}

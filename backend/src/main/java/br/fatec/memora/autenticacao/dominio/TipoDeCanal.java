package br.fatec.memora.autenticacao.dominio;

/**
 * Meio de contato de uma conta.
 *
 * <p>A pessoa pode ter os dois (decisão D1), mas o cadastro exige apenas um —
 * escolher entre dois campos já é uma decisão a menos para quem está criando a
 * primeira conta da vida.
 *
 * <p>O contrato da API expõe estes valores em minúsculas ({@code email},
 * {@code telefone}). A conversão é da camada de API; aqui e no banco o valor é
 * o nome da constante.
 */
public enum TipoDeCanal {

    EMAIL,

    TELEFONE
}

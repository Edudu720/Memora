package br.fatec.memora.autenticacao.api;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

/**
 * Os corpos de requisição e resposta do cadastro, como o contrato os define
 * (T033).
 *
 * <h2>Por que num arquivo só</h2>
 *
 * São cinco records curtos que só existem juntos: nenhum faz sentido sozinho, e
 * espalhá-los em cinco arquivos obrigaria a abrir cinco abas para conferir uma
 * resposta contra o {@code openapi.yaml}. Ficam aqui, na ordem em que aparecem
 * no contrato.
 *
 * <h2>Nome que viaja escrito ao lado do campo</h2>
 *
 * Cada campo em {@code snake_case} traz seu {@link JsonProperty}, em vez de uma
 * estratégia global de nomes. É a mesma escolha já feita em
 * {@code comum/Erro.java}: com estratégia global, renomear um campo Java muda o
 * contrato em silêncio, e o teste que pegaria isso é justamente o que ninguém
 * escreve.
 */
public final class DtosDeCadastro {

    private DtosDeCadastro() {}

    /**
     * O que o aplicativo envia.
     *
     * <p>As restrições repetem as do contrato. <b>Não são a política de senha</b>
     * — {@code senha} só é verificada aqui contra o vazio, porque a regra real
     * mora em {@code PoliticaDeSenha} e devolve mensagem própria. Um
     * {@code @Size(min = 10)} aqui recusaria antes, com o texto genérico de
     * {@code DADOS_INVALIDOS}, e a pessoa não saberia que o problema era o
     * tamanho.
     */
    public record CadastroRequisicao(
            @JsonProperty("nome_tratamento") @NotBlank @Size(min = 2, max = 80)
                    String nomeTratamento,
            @JsonProperty("canal") @NotNull @Valid CanalRequisicao canal,
            @JsonProperty("senha") @NotBlank String senha,
            @JsonProperty("modo_assistido") Boolean modoAssistido,
            @JsonProperty("aparelho_descricao") @Size(max = 120) String aparelhoDescricao) {}

    /** Canal informado no cadastro. O valor chega cru e é normalizado no serviço. */
    public record CanalRequisicao(
            @JsonProperty("tipo") @NotBlank String tipo,
            @JsonProperty("valor") @NotBlank String valor) {}

    /** Sessão iniciada — o que o cadastro devolve, pela FR-009. */
    public record SessaoResposta(
            @JsonProperty("token_acesso") String tokenAcesso,
            @JsonProperty("refresh_token") String refreshToken,
            @JsonProperty("expira_em_segundos") long expiraEmSegundos,
            @JsonProperty("pessoa") PessoaResposta pessoa) {}

    /** Dados da pessoa. Nunca inclui hash de senha nem valor de canal completo. */
    public record PessoaResposta(
            @JsonProperty("id") UUID id,
            @JsonProperty("nome_tratamento") String nomeTratamento,
            @JsonProperty("canais") List<CanalResposta> canais,
            @JsonProperty("possui_senha") boolean possuiSenha) {}

    /** Canal como ele sai: mascarado, sempre. */
    public record CanalResposta(
            @JsonProperty("id") UUID id,
            @JsonProperty("tipo") String tipo,
            @JsonProperty("valor_mascarado") String valorMascarado,
            @JsonProperty("verificado") boolean verificado,
            @JsonProperty("principal") boolean principal) {}
}

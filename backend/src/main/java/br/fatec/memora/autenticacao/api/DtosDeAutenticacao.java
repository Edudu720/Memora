package br.fatec.memora.autenticacao.api;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;

/**
 * Os corpos de requisição e resposta da autenticação, como o contrato os define
 * (T033, T047, T048).
 *
 * <h2>Por que num arquivo só</h2>
 *
 * São records curtos que só existem juntos: nenhum faz sentido sozinho, e
 * espalhá-los em sete arquivos obrigaria a abrir sete abas para conferir uma
 * resposta contra o {@code openapi.yaml}. Ficam aqui, na ordem em que aparecem
 * no contrato.
 *
 * <p>A classe se chamava {@code DtosDeCadastro} quando o cadastro era o único
 * endpoint. {@link SessaoResposta} agora responde por três — cadastro, entrada e
 * renovação —, e manter o nome antigo faria parecer que entrada e renovação
 * devolvem outra coisa. Elas devolvem exatamente a mesma forma, e isso é
 * requisito: o aplicativo tem um caminho só para guardar sessão.
 *
 * <h2>Nome que viaja escrito ao lado do campo</h2>
 *
 * Cada campo em {@code snake_case} traz seu {@link JsonProperty}, em vez de uma
 * estratégia global de nomes. É a mesma escolha já feita em
 * {@code comum/Erro.java}: com estratégia global, renomear um campo Java muda o
 * contrato em silêncio, e o teste que pegaria isso é justamente o que ninguém
 * escreve.
 */
public final class DtosDeAutenticacao {

    private DtosDeAutenticacao() {}

    /**
     * O que o aplicativo envia no cadastro.
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

    /**
     * O que o aplicativo envia na entrada (T047).
     *
     * <p><b>Não há campo {@code tipo} aqui, e isso é a FR-051 em forma de DTO.</b>
     * A pessoa digita o que lembrar — e-mail ou telefone — e o servidor descobre
     * qual é. Pedir o tipo transferiria para ela a pergunta "com qual dos dois
     * você se cadastrou?", que é exatamente o que a FR-051 proíbe.
     *
     * <p>Assim como no cadastro, {@code senha} só é verificada contra o vazio:
     * recusar por tamanho aqui devolveria {@code DADOS_INVALIDOS} para quem
     * simplesmente errou a senha, revelando de quebra que a senha certa é mais
     * longa que a digitada.
     */
    public record EntrarRequisicao(
            @JsonProperty("identificador") @NotBlank String identificador,
            @JsonProperty("senha") @NotBlank String senha,
            @JsonProperty("aparelho_descricao") @Size(max = 120) String aparelhoDescricao) {}

    /** O que o aplicativo envia para renovar a sessão (T048). */
    public record RenovarRequisicao(
            @JsonProperty("refresh_token") @NotBlank String refreshToken) {}

    /** Sessão iniciada — o que cadastro, entrada e renovação devolvem. */
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

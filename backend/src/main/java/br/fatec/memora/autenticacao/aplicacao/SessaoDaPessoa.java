package br.fatec.memora.autenticacao.aplicacao;

import br.fatec.memora.autenticacao.dominio.CanalContato;
import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.dominio.TipoDeCanal;
import br.fatec.memora.autenticacao.seguranca.ServicoDeSessao;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

/**
 * Uma sessão aberta, com o que a resposta do contrato precisa saber sobre a
 * pessoa (T047, T048).
 *
 * <h2>Por que um record em vez de devolver as entidades</h2>
 *
 * O controlador precisa de nome, canais e tokens. Entregar a ele
 * {@link PessoaUsuaria} resolveria — e passaria a permitir que a camada de API
 * chame {@code getSenhaHash()}. Não por malícia: por autocompletar. Aqui esse
 * método não existe, então o hash não tem por onde escapar para uma resposta.
 *
 * <p>É a mesma razão pela qual {@code ServicoDeCadastro.Cadastrada} é plano.
 */
public record SessaoDaPessoa(
        UUID pessoaId,
        String nomeTratamento,
        boolean possuiSenha,
        List<Canal> canais,
        String tokenAcesso,
        String refreshToken,
        long expiraEmSegundos) {

    /**
     * Um canal da pessoa, como a resposta o descreve.
     *
     * @param valorNormalizado ainda em claro — quem mascara é a camada de API,
     *     no momento de montar o corpo. <b>Nunca sai daqui direto para a
     *     resposta.</b>
     */
    public record Canal(
            UUID id,
            TipoDeCanal tipo,
            String valorNormalizado,
            boolean verificado,
            boolean principal) {}

    /**
     * Monta a partir das entidades.
     *
     * <p>Os canais saem em ordem estável — o principal primeiro, depois por data
     * de criação. Sem ordenação explícita, a ordem seria a que o banco
     * devolvesse, e a tela de perfil trocaria os canais de lugar entre uma
     * abertura e outra do aplicativo, o que para este público parece defeito.
     */
    static SessaoDaPessoa de(
            PessoaUsuaria pessoa,
            List<CanalContato> canais,
            ServicoDeSessao.SessaoEmitida sessao) {

        List<Canal> ordenados =
                canais.stream()
                        .sorted(
                                Comparator.comparing(CanalContato::isPrincipal)
                                        .reversed()
                                        .thenComparing(CanalContato::getCriadoEm))
                        .map(
                                canal ->
                                        new Canal(
                                                canal.getId(),
                                                canal.getTipo(),
                                                canal.getValor(),
                                                canal.isVerificado(),
                                                canal.isPrincipal()))
                        .toList();

        return new SessaoDaPessoa(
                pessoa.getId(),
                pessoa.getNomeTratamento(),
                pessoa.getSenhaHash() != null,
                ordenados,
                sessao.tokenAcesso(),
                sessao.refreshToken(),
                sessao.expiraEmSegundos());
    }
}

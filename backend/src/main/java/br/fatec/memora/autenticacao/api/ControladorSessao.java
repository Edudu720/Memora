package br.fatec.memora.autenticacao.api;

import br.fatec.memora.autenticacao.api.DtosDeAutenticacao.CanalResposta;
import br.fatec.memora.autenticacao.api.DtosDeAutenticacao.EntrarRequisicao;
import br.fatec.memora.autenticacao.api.DtosDeAutenticacao.PessoaResposta;
import br.fatec.memora.autenticacao.api.DtosDeAutenticacao.RenovarRequisicao;
import br.fatec.memora.autenticacao.api.DtosDeAutenticacao.SessaoResposta;
import br.fatec.memora.autenticacao.aplicacao.ServicoDeEntrada;
import br.fatec.memora.autenticacao.aplicacao.ServicoDeRenovacao;
import br.fatec.memora.autenticacao.aplicacao.SessaoDaPessoa;
import br.fatec.memora.autenticacao.dominio.MascaradorDeCanal;
import br.fatec.memora.comum.CodigoDeErro;
import br.fatec.memora.comum.FalhaDoMemora;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Locale;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * {@code POST /v1/auth/entrar} e {@code POST /v1/auth/sessao/renovar} (T047,
 * T048).
 *
 * <h2>Onde as decisões moram — e não é aqui</h2>
 *
 * Esta classe traduz duas coisas: JSON do contrato para argumentos na entrada, e
 * resultado do serviço para status HTTP na saída. Quem decide se a senha confere,
 * se a conta está bloqueada e por quanto tempo são
 * {@link ServicoDeEntrada} e {@link ServicoDeRenovacao}.
 *
 * <p>A separação tem consequência prática: os serviços <b>devolvem</b> o
 * desfecho em vez de lançar exceção, porque a transação deles precisa ser
 * confirmada para que o contador de falhas sobreviva à recusa. A exceção nasce
 * aqui, depois do commit.
 *
 * <h2>Duas recusas, um texto só</h2>
 *
 * {@code Recusada} vira sempre {@code 401 CREDENCIAIS_INVALIDAS}, nas duas
 * operações. Não há ramificação por motivo neste arquivo — e não pode haver:
 * distinguir "não existe" de "senha errada" quebraria a FR-013, e distinguir
 * "token expirado" de "reuso detectado" contaria a quem roubou um token que ele
 * um dia foi válido.
 */
@RestController
@RequestMapping("/v1/auth")
public class ControladorSessao {

    private final ServicoDeEntrada entrada;
    private final ServicoDeRenovacao renovacao;

    public ControladorSessao(ServicoDeEntrada entrada, ServicoDeRenovacao renovacao) {
        this.entrada = entrada;
        this.renovacao = renovacao;
    }

    /** Entrada com identificador e senha (FR-011). */
    @PostMapping("/entrar")
    public ResponseEntity<SessaoResposta> entrar(
            @Valid @RequestBody EntrarRequisicao requisicao) {

        ServicoDeEntrada.Resultado resultado =
                entrada.entrar(
                        requisicao.identificador(),
                        requisicao.senha(),
                        requisicao.aparelhoDescricao());

        return switch (resultado) {
            case ServicoDeEntrada.Resultado.Autenticada autenticada ->
                    ResponseEntity.ok(corpoDe(autenticada.sessao()));

            // O 429 leva `tentar_novamente_em_segundos`; o texto acolhedor da
            // FR-015 vem do proprio CodigoDeErro.MUITAS_TENTATIVAS.
            case ServicoDeEntrada.Resultado.Bloqueada bloqueada ->
                    throw FalhaDoMemora.bloqueio(bloqueada.tentarNovamenteEmSegundos());

            case ServicoDeEntrada.Resultado.Recusada ignorada ->
                    throw FalhaDoMemora.de(CodigoDeErro.CREDENCIAIS_INVALIDAS);
        };
    }

    /**
     * Renovação da sessão pelo refresh token (FR-016).
     *
     * <p>É este endpoint que cumpre "reabrir o aplicativo e continuar
     * conectada": o token de acesso dura 15 minutos, e sem a renovação a pessoa
     * digitaria a senha a cada abertura.
     */
    @PostMapping("/sessao/renovar")
    public ResponseEntity<SessaoResposta> renovar(
            @Valid @RequestBody RenovarRequisicao requisicao) {

        ServicoDeRenovacao.Resultado resultado = renovacao.renovar(requisicao.refreshToken());

        return switch (resultado) {
            case ServicoDeRenovacao.Resultado.Renovada renovada ->
                    ResponseEntity.ok(corpoDe(renovada.sessao()));

            case ServicoDeRenovacao.Resultado.Recusada ignorada ->
                    throw FalhaDoMemora.de(CodigoDeErro.CREDENCIAIS_INVALIDAS);
        };
    }

    /**
     * Monta o corpo da resposta.
     *
     * <p>O valor do canal é mascarado <b>aqui</b>, no último ponto antes de
     * virar JSON. Mascarar antes, na camada de aplicação, faria o valor em claro
     * e o mascarado circularem juntos pelo sistema, e um dia alguém devolveria o
     * errado.
     */
    private SessaoResposta corpoDe(SessaoDaPessoa sessao) {
        List<CanalResposta> canais =
                sessao.canais().stream()
                        .map(
                                canal ->
                                        new CanalResposta(
                                                canal.id(),
                                                canal.tipo().name().toLowerCase(Locale.ROOT),
                                                MascaradorDeCanal.mascarar(
                                                        canal.tipo(), canal.valorNormalizado()),
                                                canal.verificado(),
                                                canal.principal()))
                        .toList();

        PessoaResposta pessoa =
                new PessoaResposta(
                        sessao.pessoaId(),
                        sessao.nomeTratamento(),
                        canais,
                        sessao.possuiSenha());

        return new SessaoResposta(
                sessao.tokenAcesso(),
                sessao.refreshToken(),
                sessao.expiraEmSegundos(),
                pessoa);
    }
}

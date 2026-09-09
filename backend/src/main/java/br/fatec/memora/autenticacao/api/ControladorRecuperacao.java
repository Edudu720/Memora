package br.fatec.memora.autenticacao.api;

import br.fatec.memora.autenticacao.api.DtosDeAutenticacao.CanalResposta;
import br.fatec.memora.autenticacao.api.DtosDeAutenticacao.PessoaResposta;
import br.fatec.memora.autenticacao.api.DtosDeAutenticacao.RecuperacaoAceitaResposta;
import br.fatec.memora.autenticacao.api.DtosDeAutenticacao.RecuperacaoConfirmarRequisicao;
import br.fatec.memora.autenticacao.api.DtosDeAutenticacao.RecuperacaoSolicitarRequisicao;
import br.fatec.memora.autenticacao.api.DtosDeAutenticacao.SessaoResposta;
import br.fatec.memora.autenticacao.aplicacao.ServicoDeRecuperacao;
import br.fatec.memora.autenticacao.aplicacao.SessaoDaPessoa;
import br.fatec.memora.autenticacao.dominio.MascaradorDeCanal;
import br.fatec.memora.autenticacao.dominio.PoliticaDeSenha;
import br.fatec.memora.comum.CodigoDeErro;
import br.fatec.memora.comum.FalhaDoMemora;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * {@code POST /v1/auth/recuperacao/solicitar} e {@code .../confirmar} (T066, T067).
 *
 * <h2>Os dois endpoints que as telas da US3 já chamavam</h2>
 *
 * A US3 foi construída de cima para baixo: as telas existem desde a PR #20 e o
 * {@code RepositorioAutenticacaoApi} já os invocava pelo cliente gerado —
 * compilando, e recebendo {@code 404}. Esta classe fecha esse buraco.
 *
 * <h2>Públicos, e não poderia ser diferente</h2>
 *
 * Quem esqueceu a senha não tem como se autenticar para pedir outra. É o mesmo
 * motivo do cadastro e da entrada, e o que sustenta a segurança aqui não é o
 * token: é o código enviado a um canal cuja posse já foi provada (FR-052).
 *
 * <h2>Onde a decisão mora — e, de novo, não é aqui</h2>
 *
 * O serviço <b>devolve</b> o desfecho em vez de lançar, porque a recusa precisa
 * persistir a tentativa errada no código: lançar de dentro desfaria a transação
 * e levaria o contador junto, e um código com tentativas ilimitadas é um código
 * de 6 dígitos que se adivinha. A exceção nasce aqui, depois do commit — como
 * em {@link ControladorSessao}.
 */
@RestController
@RequestMapping("/v1/auth/recuperacao")
public class ControladorRecuperacao {

    /**
     * O texto do {@code 202}, palavra por palavra como o contrato o publica.
     *
     * <p><b>É uma constante de propósito.</b> Ele precisa ser idêntico exista ou
     * não a conta (FR-019), e texto montado em dois pontos do código é texto que
     * um dia diverge em um deles. Repare no "se essa conta existir": a frase
     * assume a ambiguidade em vez de fingir certeza, porque prometer "enviamos"
     * a quem não tem conta faria a pessoa esperar por uma mensagem que nunca
     * chega.
     */
    public static final String MENSAGEM_ACEITA =
            "Se essa conta existir, enviamos um código de 6 números. "
                    + "Confira suas mensagens 😊";

    private final ServicoDeRecuperacao recuperacao;

    public ControladorRecuperacao(ServicoDeRecuperacao recuperacao) {
        this.recuperacao = recuperacao;
    }

    /**
     * Pede o código de recuperação (FR-019).
     *
     * <p>Responde {@code 202} <b>sempre</b>. A única saída diferente é o
     * {@code 429} da camada por origem — que não depende da conta e por isso não
     * conta nada sobre ela.
     */
    @PostMapping("/solicitar")
    public ResponseEntity<RecuperacaoAceitaResposta> solicitar(
            @Valid @RequestBody RecuperacaoSolicitarRequisicao requisicao) {

        Optional<Long> espera = recuperacao.solicitar(requisicao.identificador());

        if (espera.isPresent()) {
            throw FalhaDoMemora.bloqueio(espera.get());
        }

        return ResponseEntity.accepted()
                .body(new RecuperacaoAceitaResposta(MENSAGEM_ACEITA));
    }

    /**
     * Define a senha nova (FR-020, FR-021, FR-022).
     *
     * <p>A política de senha é aplicada <b>antes</b> de chamar o serviço, e
     * isso é deliberado: é o único erro desta operação cuja causa a pessoa pode
     * corrigir, e o único que não revela nada — "senha curta demais" vale para
     * quem tem conta e para quem não tem. Todos os outros caminhos saem por uma
     * recusa só.
     */
    @PostMapping("/confirmar")
    public ResponseEntity<SessaoResposta> confirmar(
            @Valid @RequestBody RecuperacaoConfirmarRequisicao requisicao) {

        recusarSenhaFraca(requisicao.novaSenha());

        ServicoDeRecuperacao.Resultado resultado =
                recuperacao.confirmar(
                        requisicao.identificador(),
                        requisicao.codigo(),
                        requisicao.novaSenha(),
                        requisicao.aparelhoDescricao());

        return switch (resultado) {
            case ServicoDeRecuperacao.Resultado.Trocada trocada ->
                    ResponseEntity.status(HttpStatus.OK).body(corpoDe(trocada.sessao()));

            case ServicoDeRecuperacao.Resultado.Bloqueada bloqueada ->
                    throw FalhaDoMemora.bloqueio(bloqueada.tentarNovamenteEmSegundos());

            // Codigo errado, vencido, ja usado, canal nao verificado, conta
            // inexistente, desativada ou pendente: uma recusa so. Separa-las
            // diria a quem esta tentando em que ponto ele errou.
            case ServicoDeRecuperacao.Resultado.Recusada ignorada ->
                    throw FalhaDoMemora.de(
                            CodigoDeErro.DADOS_INVALIDOS,
                            "Esse código não conferiu. Ele vale por 10 minutinhos — "
                                    + "se já passou, posso te enviar outro 😊");
        };
    }

    /**
     * A política de senha (FR-042), com o mesmo texto do cadastro.
     *
     * <p>As frases são as de {@code ServicoDeCadastro}, e precisam continuar
     * sendo: a pessoa que escolhe senha aqui está na mesma situação de quem
     * escolhe no cadastro, e receber duas explicações diferentes para a mesma
     * regra é o tipo de incoerência que faz alguém desistir.
     */
    private void recusarSenhaFraca(String senha) {
        PoliticaDeSenha.Recusa recusa = PoliticaDeSenha.avaliar(senha);
        if (recusa == null) {
            return;
        }

        String mensagem =
                switch (recusa) {
                    case CURTA ->
                            "Essa senha ficou curtinha. Que tal uma frase de que você goste, "
                                    + "com pelo menos "
                                    + PoliticaDeSenha.COMPRIMENTO_MINIMO
                                    + " letras? 😊";
                    case COMPROMETIDA ->
                            "Essa senha é bastante usada, e por isso não protege sua conta. "
                                    + "Vamos pensar em outra juntos? 😊";
                };

        throw FalhaDoMemora.de(CodigoDeErro.DADOS_INVALIDOS, mensagem);
    }

    /** Mesmo corpo das outras três operações que emitem sessão. */
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

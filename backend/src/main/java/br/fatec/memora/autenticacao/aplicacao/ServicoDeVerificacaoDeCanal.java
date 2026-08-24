package br.fatec.memora.autenticacao.aplicacao;

import br.fatec.memora.autenticacao.dominio.CanalContato;
import br.fatec.memora.autenticacao.dominio.CodigoVerificacao;
import br.fatec.memora.autenticacao.dominio.FinalidadeDoCodigo;
import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.dominio.ResultadoDoEvento;
import br.fatec.memora.autenticacao.dominio.TipoDeEvento;
import br.fatec.memora.autenticacao.infra.RepositorioCanalContato;
import br.fatec.memora.autenticacao.infra.RepositorioCodigoVerificacao;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.seguranca.GeradorDeCodigoNumerico;
import br.fatec.memora.comum.RegistroDeAuditoria;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Confirma que a pessoa controla um canal de contato (T058, R5, FR-052).
 *
 * <h2>O que este serviço protege</h2>
 *
 * A FR-062 descreve o golpe: um familiar cadastra a conta da pessoa idosa
 * informando <b>o próprio</b> contato como canal, e a partir daí controla a
 * recuperação de acesso — ou seja, a conta. A defesa é a FR-052: canal não
 * verificado nunca recebe código de recuperação.
 *
 * <p><b>Uma ressalva que precisa estar escrita.</b> Confirmar posse prova que
 * quem digitou o código <i>alcança</i> aquele canal — não prova de quem ele é.
 * No cadastro assistido o acompanhante está ao lado, com o próprio telefone na
 * mão, e digitaria o código sem esforço. Quem de fato mitiga a FR-062 é a
 * entrega do aparelho (FR-059) e a primeira entrada sozinha (FR-063), no lado do
 * aplicativo. Este serviço garante que existe um canal alcançável e confirmado,
 * o que é condição necessária — nunca suficiente.
 *
 * <h2>Por que o código é hasheado com Argon2, e não com SHA-256</h2>
 *
 * {@code GeradorDeSegredoOpaco} usa SHA-256 porque protege um valor de 256 bits
 * aleatórios, onde hash lento não compra nada. Aqui é o oposto: são 10<sup>6</sup>
 * possibilidades, e um resumo simples de um código de 6 dígitos se inverte por
 * força bruta em tempo desprezível — o próprio {@code CodigoVerificacao} avisa
 * isso no {@code toString}.
 *
 * <p>Argon2 a ~240 ms por tentativa resolve os dois lados: torna a inversão
 * offline cara e, de quebra, freia a força bruta <b>online</b>, que num espaço
 * de 6 dígitos é a ameaça mais concreta. O custo aparece apenas ao verificar,
 * que não é caminho quente.
 *
 * <h2>Um código válido por vez</h2>
 *
 * Pedir código novo invalida o anterior antes de emitir o substituto. Dois
 * códigos vivos ao mesmo tempo dobrariam a chance de acerto por tentativa e
 * criariam a confusão de a pessoa digitar o número da mensagem antiga.
 */
@Service
public class ServicoDeVerificacaoDeCanal {

    /** Prazo do código, como o contrato o publica (R5). */
    public static final Duration VALIDADE = Duration.ofMinutes(10);

    private final RepositorioCanalContato canais;
    private final RepositorioCodigoVerificacao codigos;
    private final RepositorioPessoaUsuaria pessoas;
    private final GeradorDeCodigoNumerico gerador;
    private final PasswordEncoder codificador;
    private final EnviadorDeCodigo enviador;
    private final RegistroDeAuditoria auditoria;
    private final Clock relogio;

    public ServicoDeVerificacaoDeCanal(
            RepositorioCanalContato canais,
            RepositorioCodigoVerificacao codigos,
            RepositorioPessoaUsuaria pessoas,
            GeradorDeCodigoNumerico gerador,
            PasswordEncoder codificador,
            EnviadorDeCodigo enviador,
            RegistroDeAuditoria auditoria,
            Clock relogio) {
        this.canais = canais;
        this.codigos = codigos;
        this.pessoas = pessoas;
        this.gerador = gerador;
        this.codificador = codificador;
        this.enviador = enviador;
        this.auditoria = auditoria;
        this.relogio = relogio;
    }

    /** Como uma verificação pode terminar. */
    public enum Resultado {
        /** Canal confirmado. */
        CONFIRMADO,

        /** Código errado, expirado, já usado, ou canal que não é de quem pediu. */
        RECUSADO
    }

    /**
     * Emite e envia um código para o canal, se ele for da pessoa que pediu.
     *
     * <p><b>Não conta a ninguém se o canal existe ou de quem ele é.</b> Canal
     * inexistente, canal de outra conta e canal já verificado saem todos pelo
     * mesmo caminho silencioso — quem chama devolve {@code 202} igual. O
     * contrato diz "código enviado, <i>se o canal for elegível</i>" justamente
     * para permitir isso: responder {@code 404} para canal alheio transformaria
     * o endpoint em oráculo de quais identificadores existem.
     */
    @Transactional
    public void solicitarCodigo(UUID pessoaId, UUID canalId) {
        Optional<CanalContato> canal = canalDaPessoa(pessoaId, canalId);
        if (canal.isEmpty() || canal.get().isVerificado()) {
            return;
        }

        Instant agora = relogio.instant();

        // Antes de emitir o substituto: ver "Um codigo valido por vez".
        codigos.invalidarPendentes(canalId, FinalidadeDoCodigo.VERIFICACAO_POSSE, agora);

        String codigoEmClaro = gerador.gerar();

        codigos.saveAndFlush(
                new CodigoVerificacao(
                        canalId,
                        FinalidadeDoCodigo.VERIFICACAO_POSSE,
                        codificador.encode(codigoEmClaro),
                        agora,
                        agora.plus(VALIDADE)));

        enviador.enviar(canal.get(), codigoEmClaro);
    }

    /**
     * Confere o código e, acertando, marca o canal como verificado.
     *
     * <p>Quando a conta está {@code PENDENTE_VERIFICACAO}, é aqui que o cadastro
     * assistido finalmente conclui (FR-062): o canal passa a verificado e a
     * conta vira {@code ATIVA} na mesma transação. Uma coisa sem a outra deixaria
     * a conta presa para sempre ou liberada sem canal confirmado.
     *
     * <p>Tentativa errada é contada no próprio código, e o quinto erro o
     * descarta — quem errar cinco vezes precisa pedir outro. Isso é o que
     * impede varrer 10<sup>6</sup> possibilidades com um código só.
     */
    @Transactional
    public Resultado verificar(UUID pessoaId, UUID canalId, String codigoInformado) {
        Instant agora = relogio.instant();

        Optional<CanalContato> canal = canalDaPessoa(pessoaId, canalId);
        if (canal.isEmpty()) {
            return Resultado.RECUSADO;
        }

        Optional<CodigoVerificacao> codigo =
                codigos.findFirstByCanalIdAndFinalidadeOrderByCriadoEmDesc(
                        canalId, FinalidadeDoCodigo.VERIFICACAO_POSSE);

        if (codigo.isEmpty() || !codigo.get().estaValidoEm(agora)) {
            return Resultado.RECUSADO;
        }

        if (!codificador.matches(codigoInformado, codigo.get().getCodigoHash())) {
            codigo.get().registrarTentativaErrada();
            codigos.saveAndFlush(codigo.get());
            return Resultado.RECUSADO;
        }

        codigo.get().marcarComoUsado(agora);
        codigos.saveAndFlush(codigo.get());

        canal.get().marcarComoVerificado(agora);
        canais.saveAndFlush(canal.get());

        concluirCadastroAssistidoSePendente(pessoaId, agora);

        auditoria.registrar(
                pessoaId, TipoDeEvento.CANAL_VERIFICADO, ResultadoDoEvento.SUCESSO, agora);

        return Resultado.CONFIRMADO;
    }

    /**
     * Libera a conta que esperava esta confirmação (T057).
     *
     * <p>Passa por {@code concluirVerificacaoPendente()}, que só age sobre conta
     * pendente: verificar um segundo canal numa conta já ativa não mexe no
     * estado, e numa conta desativada não a ressuscita.
     */
    private void concluirCadastroAssistidoSePendente(UUID pessoaId, Instant agora) {
        Optional<PessoaUsuaria> pessoa = pessoas.findById(pessoaId);
        if (pessoa.isPresent() && pessoa.get().concluirVerificacaoPendente()) {
            pessoas.saveAndFlush(pessoa.get());
        }
    }

    /**
     * O canal, se ele pertencer a quem está pedindo.
     *
     * <p>Esta é a checagem que impede alguém autenticado de verificar canal de
     * outra conta apenas por saber o {@link UUID} dele. O identificador vem da
     * URL, e nada na URL é confiável.
     */
    private Optional<CanalContato> canalDaPessoa(UUID pessoaId, UUID canalId) {
        return canais.findById(canalId)
                .filter(canal -> canal.getPessoaId().equals(pessoaId));
    }
}

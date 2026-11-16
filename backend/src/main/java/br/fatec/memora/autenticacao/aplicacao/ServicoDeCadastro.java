package br.fatec.memora.autenticacao.aplicacao;

import br.fatec.memora.autenticacao.dominio.CanalContato;
import br.fatec.memora.autenticacao.dominio.EstadoDaConta;
import br.fatec.memora.autenticacao.dominio.NormalizadorIdentificador;
import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.dominio.PoliticaDeSenha;
import br.fatec.memora.autenticacao.dominio.ResultadoDoEvento;
import br.fatec.memora.autenticacao.dominio.TipoDeCanal;
import br.fatec.memora.autenticacao.dominio.TipoDeEvento;
import br.fatec.memora.autenticacao.infra.RepositorioCanalContato;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.seguranca.EmissorDeTokenDeAcesso;
import br.fatec.memora.autenticacao.seguranca.GeradorDeSegredoOpaco;
import br.fatec.memora.autenticacao.seguranca.ServicoDeSessao;
import br.fatec.memora.comum.CodigoDeErro;
import br.fatec.memora.comum.FalhaDoMemora;
import br.fatec.memora.comum.RegistroDeAuditoria;
import java.time.Clock;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Cria a conta e já devolve sessão iniciada (T033, T035, FR-009, FR-010).
 *
 * <h2>A decisão que governa esta classe: o canal já existente</h2>
 *
 * A FR-010 proíbe revelar se um identificador já tem conta, e o cenário V2 do
 * quickstart é literal: <i>"falha se qualquer diferença observável em corpo,
 * código de status ou tempo"</i>. Como o cadastro responde {@code 201} com uma
 * sessão, cumprir isso obriga a devolver <b>uma sessão</b> também quando não há
 * nada a criar.
 *
 * <p>Três saídas foram consideradas, e duas são inaceitáveis:
 *
 * <ul>
 *   <li><b>Devolver a sessão da conta existente</b> — qualquer pessoa que saiba
 *       o seu e-mail entra na sua conta. Fora de questão.
 *   <li><b>Devolver texto aleatório no lugar dos tokens</b> — quem ataca
 *       decodifica o {@code token_acesso}: o real é um JWT de três segmentos, o
 *       falso é ruído. A diferença é observável, e a FR-010 cai.
 *   <li><b>Sessão-chamariz</b> — token assinado de verdade, para um identificador
 *       que não existe. É o que está implementado.
 * </ul>
 *
 * <h2>O que o chamariz é, exatamente</h2>
 *
 * Um JWT válido em assinatura e formato, emitido para um {@link UUID} sorteado
 * que não corresponde a conta nenhuma, mais um refresh que <b>não é gravado</b>.
 * Nada é criado no banco. O aplicativo recebe uma resposta indistinguível, e
 * descobre a situação no primeiro uso, quando o token não resolve para conta
 * alguma e a resposta é {@code 401} — que é exatamente o cenário 5 da User Story
 * 1, "sou levada ao login sem que o aplicativo revele se aquele identificador
 * existe".
 *
 * <p><b>A contrapartida, dita por extenso</b>: existe token assinado por nós
 * cujo sujeito não existe. Isso é seguro enquanto <b>todo</b> caminho autenticado
 * resolver o sujeito antes de confiar nele, e recusar quando não encontrar.
 * Assinatura válida não é autorização. Quem criar endpoint autenticado precisa
 * saber disso.
 *
 * <h2>Por que a senha é hasheada mesmo quando nada é criado</h2>
 *
 * O V2 mede <b>tempo</b>. O caminho real gasta ~240 ms em Argon2; pular o hash
 * no chamariz faria o cadastro contra canal existente responder ordens de
 * grandeza mais rápido, e a diferença de latência entregaria de graça o que o
 * corpo idêntico escondeu. O hash roda <b>antes</b> de qualquer consulta ao
 * canal, para que os dois caminhos façam o mesmo trabalho na mesma ordem.
 */
@Service
public class ServicoDeCadastro {

    private final RepositorioPessoaUsuaria pessoas;
    private final RepositorioCanalContato canais;
    private final PasswordEncoder codificador;
    private final GeradorDeSegredoOpaco gerador;
    private final ServicoDeSessao sessoes;
    private final EmissorDeTokenDeAcesso emissor;
    private final RegistroDeAuditoria auditoria;
    private final ServicoDeExpurgoDeContaPendente expurgoDeContaPendente;
    private final Clock relogio;

    public ServicoDeCadastro(
            RepositorioPessoaUsuaria pessoas,
            RepositorioCanalContato canais,
            PasswordEncoder codificador,
            GeradorDeSegredoOpaco gerador,
            ServicoDeSessao sessoes,
            EmissorDeTokenDeAcesso emissor,
            RegistroDeAuditoria auditoria,
            ServicoDeExpurgoDeContaPendente expurgoDeContaPendente,
            Clock relogio) {
        this.pessoas = pessoas;
        this.canais = canais;
        this.codificador = codificador;
        this.gerador = gerador;
        this.sessoes = sessoes;
        this.emissor = emissor;
        this.auditoria = auditoria;
        this.expurgoDeContaPendente = expurgoDeContaPendente;
        this.relogio = relogio;
    }

    /** O que o cadastro produz, já pronto para virar corpo de resposta. */
    public record Cadastrada(
            UUID pessoaId,
            String nomeTratamento,
            TipoDeCanal tipoDoCanal,
            String valorNormalizado,
            UUID canalId,
            String tokenAcesso,
            String refreshToken,
            long expiraEmSegundos) {}

    /**
     * Executa o cadastro.
     *
     * <p><b>Devolve o mesmo tipo nos dois caminhos.</b> Não existe sinalizador
     * de "era chamariz" no retorno: quem chama não pode se comportar de forma
     * diferente, porque comportamento diferente vira resposta diferente.
     *
     * @throws FalhaDoMemora quando a senha não atende à política (FR-042)
     */
    @Transactional
    public Cadastrada cadastrar(
            String nomeTratamento, TipoDeCanal tipo, String valorInformado, String senha,
            String aparelhoDescricao, boolean modoAssistido) {

        String valor = NormalizadorIdentificador.normalizar(tipo, valorInformado);
        recusarSenhaFraca(senha);

        // Antes da consulta ao canal, e nos dois caminhos: e o custo que iguala
        // os tempos. Ver o cabecalho desta classe.
        String senhaHash = codificador.encode(senha);
        String valorHash = gerador.hashDe(valor);
        Instant agora = relogio.instant();

        Optional<CanalContato> existente = canais.findByValorHash(valorHash);
        if (existente.isPresent()) {
            // T065b (FR-004, FR-005): se o canal pertence a uma conta assistida
            // abandonada em PENDENTE_VERIFICACAO ha mais de 24 horas, expurgamos
            // a conta obsoleta (depois do Argon2id acima) e liberamos o cadastro.
            // Contas ATIVA ou PENDENTE_VERIFICACAO recentes (<= 24h) caem no chamariz.
            boolean expurgada =
                    expurgoDeContaPendente.expurgarSeExpirada(
                            existente.get().getPessoaId(), agora);
            if (!expurgada) {
                return chamariz(nomeTratamento, tipo, valor, agora);
            }
        }
        return criar(
                nomeTratamento, tipo, valor, valorHash, senhaHash, aparelhoDescricao, agora,
                modoAssistido);
    }

    /**
     * A política de senha (FR-042), com mensagem própria por motivo.
     *
     * <p>O texto explica o que fazer sem culpar quem digitou — e sem enumerar
     * regra que a tela já mostrou.
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

    /**
     * O caminho real: conta, canal principal, sessão e trilha.
     *
     * <h2>O que {@code modoAssistido} muda aqui (T057, FR-062)</h2>
     *
     * A conta nasce {@link EstadoDaConta#PENDENTE_VERIFICACAO} em vez de
     * {@link EstadoDaConta#ATIVA}. Ela existe, tem canal e recebe sessão — mas
     * não entra e não recupera acesso enquanto a posse do canal não for
     * confirmada. O cenário V4 exige literalmente que "o cadastro assistido não
     * conclui sem posse confirmada", e esta é a única forma de cumprir isso sem
     * inverter a ordem: o canal só passa a existir <b>dentro</b> deste método, e
     * o endpoint que confirma posse exige o token que só é emitido no fim dele.
     *
     * <p>A sessão devolvida serve para um caminho e nenhum outro — confirmar o
     * canal. Quem escrever endpoint autenticado novo precisa recusar conta
     * pendente, por {@code PessoaAutenticada.estaPendenteDeVerificacao()}.
     *
     * <p><b>{@code modoAssistido} não cria vínculo nenhum</b> (FR-064). Nada do
     * acompanhante é gravado: nem identificador, nem permissão, nem registro de
     * que ele existiu. É um sinal de fluxo que muda o estado inicial da conta e
     * termina aí.
     */
    private Cadastrada criar(
            String nomeTratamento, TipoDeCanal tipo, String valor, String valorHash,
            String senhaHash, String aparelhoDescricao, Instant agora, boolean modoAssistido) {

        EstadoDaConta estadoInicial =
                modoAssistido ? EstadoDaConta.PENDENTE_VERIFICACAO : EstadoDaConta.ATIVA;

        PessoaUsuaria pessoa =
                pessoas.saveAndFlush(
                        new PessoaUsuaria(nomeTratamento, senhaHash, agora, estadoInicial));

        CanalContato canal =
                canais.saveAndFlush(
                        new CanalContato(pessoa.getId(), tipo, valor, valorHash, true, agora));

        ServicoDeSessao.SessaoEmitida sessao =
                sessoes.iniciar(pessoa.getId(), aparelhoDescricao, agora);

        // Na transacao em curso, e nao em transacao propria: o evento aponta
        // para conta criada aqui e ainda nao confirmada, e a chave estrangeira
        // nao a enxergaria de fora (ver RegistroDeAuditoria).
        auditoria.registrar(
                pessoa.getId(), TipoDeEvento.CADASTRO, ResultadoDoEvento.SUCESSO, agora);

        return new Cadastrada(
                pessoa.getId(),
                pessoa.getNomeTratamento(),
                tipo,
                valor,
                canal.getId(),
                sessao.tokenAcesso(),
                sessao.refreshToken(),
                sessao.expiraEmSegundos());
    }

    /**
     * O caminho que não cria nada e não conta isso a ninguém.
     *
     * <p>Nenhum dado do dono real do canal é lido. O que volta é construído a
     * partir do que <b>foi enviado</b> — o nome digitado agora, o canal digitado
     * agora — mais identificadores sorteados. Consultar a conta existente para
     * "parecer real" seria vazar os dados dela para quem não é ela.
     */
    private Cadastrada chamariz(
            String nomeTratamento, TipoDeCanal tipo, String valor, Instant agora) {

        UUID sujeitoInexistente = UUID.randomUUID();

        // Sem conta associada: a trilha precisa enxergar a tentativa (FR-039),
        // e informar id revelaria, pela propria existencia do vinculo, que
        // aquele canal tem dono.
        auditoria.registrarSemConta(
                TipoDeEvento.CADASTRO, ResultadoDoEvento.FALHA, agora);

        return new Cadastrada(
                sujeitoInexistente,
                nomeTratamento,
                tipo,
                valor,
                UUID.randomUUID(),
                // A familia tambem e sorteada, e tambem nao existe. O token do
                // chamariz precisa ter a MESMA forma do real (V2): um a menos
                // de campo bastaria para distinguir os dois caminhos olhando o
                // JWT decodificado, que qualquer um faz sem chave nenhuma.
                emissor.emitir(sujeitoInexistente, UUID.randomUUID(), agora),
                gerador.gerar(),
                EmissorDeTokenDeAcesso.VALIDADE.toSeconds());
    }
}

package br.fatec.memora.autenticacao.aplicacao;

import br.fatec.memora.autenticacao.dominio.CanalContato;
import br.fatec.memora.autenticacao.dominio.CodigoVerificacao;
import br.fatec.memora.autenticacao.dominio.FinalidadeDoCodigo;
import br.fatec.memora.autenticacao.dominio.NormalizadorIdentificador;
import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.dominio.ResultadoDoEvento;
import br.fatec.memora.autenticacao.dominio.TipoDeCanal;
import br.fatec.memora.autenticacao.dominio.TipoDeEvento;
import br.fatec.memora.autenticacao.dominio.TipoDoIdentificador;
import br.fatec.memora.autenticacao.infra.RepositorioCanalContato;
import br.fatec.memora.autenticacao.infra.RepositorioCodigoVerificacao;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioSessao;
import br.fatec.memora.autenticacao.seguranca.GeradorDeCodigoNumerico;
import br.fatec.memora.autenticacao.seguranca.GeradorDeSegredoOpaco;
import br.fatec.memora.autenticacao.seguranca.LimitadorTentativas;
import br.fatec.memora.autenticacao.seguranca.ServicoDeSessao;
import br.fatec.memora.autenticacao.seguranca.VerificadorCredenciais;
import br.fatec.memora.comum.ContextoDaRequisicao;
import br.fatec.memora.comum.RegistroDeAuditoria;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Recuperação de acesso: pedir o código e trocar a senha (T066, T067, T068).
 *
 * <h2>A recuperação é a porta dos fundos, e é por ela que se entra</h2>
 *
 * Quem quer a conta de alguém raramente adivinha a senha — pede uma nova. Por
 * isso este serviço concentra três defesas que não existem no login:
 *
 * <ol>
 *   <li><b>Só canal verificado recebe código</b> (FR-052). É aqui que a US5
 *       paga o que prometeu: sem posse confirmada, o acompanhante que cadastrou
 *       o próprio contato controlaria a recuperação da conta alheia para sempre
 *       (FR-062).
 *   <li><b>Trocar a senha revoga todas as sessões</b> (FR-021). Sem isso, quem
 *       já estava dentro continua dentro depois de a pessoa "recuperar" a conta.
 *   <li><b>A troca é avisada pelo canal</b> (FR-022), para que a pessoa descubra
 *       o golpe no minuto, e não na semana seguinte.
 * </ol>
 *
 * <h2>{@code 202} sempre, e o mesmo tempo sempre</h2>
 *
 * A FR-019 obriga a resposta idêntica exista ou não a conta, e o V2 reprova
 * "qualquer diferença observável em corpo, código de status <b>ou tempo</b>".
 * Corpo e status são fáceis; o tempo é onde este projeto já se queimou duas
 * vezes — no cadastro (11 ms contra 261 ms) e no login (18 ms contra 282 ms),
 * as duas medidas, nenhuma suposta.
 *
 * <p>A defesa é a mesma das outras duas vezes: <b>o Argon2 roda antes da
 * consulta que depende da existência da conta</b>, e portanto nos dois
 * caminhos. Em {@link #solicitar} o código é gerado e hasheado antes de o
 * serviço saber se há alguém para recebê-lo; em {@link #confirmar} quem iguala
 * os tempos é o {@link VerificadorCredenciais}, rodando contra hash fictício
 * quando não há código a conferir.
 *
 * <p>Um {@code if (pessoa == null) return;} adiantado seria correto em lógica e
 * quebraria a FR-019 na hora.
 *
 * <h2>Nenhum Argon2 dentro de transação</h2>
 *
 * O Hibernate toma a conexão na primeira consulta e só a devolve no commit. Um
 * hash de ~240 ms no meio segura uma conexão do pool sem tocar no banco, e
 * {@code confirmar} paga <b>dois</b> — conferir o código e codificar a senha
 * nova. Com {@code maximum-pool-size=20}, dez requisições simultâneas a um
 * endpoint <b>público</b> bastariam para cadastro e login esperarem por conexão.
 *
 * <p>Daí o {@link TransactionTemplate} em vez de {@code @Transactional}: as
 * transações são curtas e os hashes ficam entre elas. É a mesma correção que a
 * revisão da PR #15 aplicou em {@code ServicoDeEntrada} — repetida aqui de
 * propósito, porque o motivo é idêntico.
 *
 * <h2>Conta bloqueada recupera, sim</h2>
 *
 * A tela de bloqueio oferece "Criar uma senha nova" como saída. Recusar a
 * recuperação por causa do bloqueio transformaria essa saída em porta pintada na
 * parede: a pessoa que esqueceu a senha, errou cinco vezes e foi orientada a
 * trocá-la descobriria que também não pode trocá-la. Por isso
 * {@link #solicitar} não olha {@code bloqueada_ate}, e a confirmação bem
 * sucedida <b>limpa</b> o bloqueio — senão a troca resolveria metade do
 * problema e deixaria a pessoa do lado de fora assim mesmo.
 *
 * <p>O que continua valendo é a camada por origem do {@link LimitadorTentativas}
 * e a contagem de tentativas do próprio código, que é o que impede varrer
 * 10<sup>6</sup> possibilidades.
 */
@Service
public class ServicoDeRecuperacao {

    /** Prazo do código, igual ao da verificação de posse (R5). */
    public static final Duration VALIDADE = ServicoDeVerificacaoDeCanal.VALIDADE;

    private final RepositorioPessoaUsuaria pessoas;
    private final RepositorioCanalContato canais;
    private final RepositorioCodigoVerificacao codigos;
    private final RepositorioSessao sessoesGravadas;
    private final GeradorDeCodigoNumerico geradorDeCodigo;
    private final GeradorDeSegredoOpaco geradorDeHash;
    private final PasswordEncoder codificador;
    private final VerificadorCredenciais verificador;
    private final LimitadorTentativas limitador;
    private final ServicoDeSessao sessoes;
    private final EnviadorDeCodigo enviador;
    private final NotificadorDeConta notificador;
    private final RegistroDeAuditoria auditoria;
    private final Clock relogio;
    private final TransactionTemplate transacao;

    public ServicoDeRecuperacao(
            RepositorioPessoaUsuaria pessoas,
            RepositorioCanalContato canais,
            RepositorioCodigoVerificacao codigos,
            RepositorioSessao sessoesGravadas,
            GeradorDeCodigoNumerico geradorDeCodigo,
            GeradorDeSegredoOpaco geradorDeHash,
            PasswordEncoder codificador,
            VerificadorCredenciais verificador,
            LimitadorTentativas limitador,
            ServicoDeSessao sessoes,
            EnviadorDeCodigo enviador,
            NotificadorDeConta notificador,
            RegistroDeAuditoria auditoria,
            Clock relogio,
            PlatformTransactionManager gerenciadorDeTransacao) {
        this.pessoas = pessoas;
        this.canais = canais;
        this.codigos = codigos;
        this.sessoesGravadas = sessoesGravadas;
        this.geradorDeCodigo = geradorDeCodigo;
        this.geradorDeHash = geradorDeHash;
        this.codificador = codificador;
        this.verificador = verificador;
        this.limitador = limitador;
        this.sessoes = sessoes;
        this.enviador = enviador;
        this.notificador = notificador;
        this.auditoria = auditoria;
        this.relogio = relogio;
        this.transacao = new TransactionTemplate(gerenciadorDeTransacao);
    }

    /** O desfecho da confirmação. Ver {@code ServicoDeEntrada} sobre não lançar daqui. */
    public sealed interface Resultado {

        record Trocada(SessaoDaPessoa sessao) implements Resultado {}

        /** Código errado, vencido, já usado, ou conta que não recupera. Um só motivo. */
        record Recusada() implements Resultado {}

        /** @param tentarNovamenteEmSegundos vai no corpo do {@code 429} */
        record Bloqueada(long tentarNovamenteEmSegundos) implements Resultado {}
    }

    // ------------------------------------------------------------------------
    // T066 — solicitar
    // ------------------------------------------------------------------------

    /**
     * Emite e envia o código de recuperação, se houver a quem enviar (FR-019).
     *
     * <p><b>Não devolve nada, e é isso que a torna segura.</b> Sem valor de
     * retorno, quem chama não tem como se comportar de forma diferente — e
     * comportamento diferente vira resposta diferente. Conta inexistente, conta
     * desativada, conta que ainda espera confirmação de posse e canal não
     * verificado saem todos por este mesmo caminho silencioso.
     *
     * @return a espera em segundos quando a camada por origem barrou, ou vazio
     *     quando a solicitação seguiu o fluxo normal — o único caso em que o
     *     contrato prevê algo diferente de {@code 202}
     */
    public Optional<Long> solicitar(String identificadorInformado) {
        Instant agora = relogio.instant();
        String origemHash = ContextoDaRequisicao.atual().origemHash();

        // Camada por origem apenas: `null` no lugar da pessoa de proposito. A
        // camada por conta olha `bloqueada_ate`, e recusar aqui por bloqueio
        // fecharia justamente a saida que a tela de bloqueio oferece — alem de
        // responder diferente para conta existente, contando que ela existe.
        LimitadorTentativas.Decisao decisao = limitador.avaliar(null, origemHash, agora);
        if (decisao instanceof LimitadorTentativas.Decisao.Bloqueado bloqueado) {
            return Optional.of(bloqueado.tentarNovamenteEmSegundos());
        }

        // Antes da consulta, e nos dois caminhos: e o custo que iguala os
        // tempos. Fora de transacao, para nao prender conexao (ver o cabecalho).
        String codigoEmClaro = geradorDeCodigo.gerar();
        String codigoHash = codificador.encode(codigoEmClaro);
        String valorHash = hashDoIdentificador(identificadorInformado);

        Optional<CanalContato> destino =
                transacao.execute(status -> registrarCodigo(valorHash, codigoHash, agora));

        // O envio sai de fora da transacao: e chamada de rede, e uma conexao do
        // pool nao pode esperar por um provedor de e-mail.
        destino.ifPresent(canal -> enviador.enviar(canal, codigoEmClaro));

        return Optional.empty();
    }

    /**
     * Grava o código quando há canal elegível. Devolve o destino, ou vazio.
     *
     * <p>A elegibilidade é a FR-052 mais o estado da conta: canal
     * <b>verificado</b>, de conta que pode entrar. Conta
     * {@code PENDENTE_VERIFICACAO} não recupera — deixá-la recuperar concluiria
     * na prática o cadastro assistido que o V4 manda não concluir, e por um
     * caminho que nem exige a senha.
     */
    private Optional<CanalContato> registrarCodigo(
            String valorHash, String codigoHash, Instant agora) {

        Optional<CanalContato> canal = canais.findByValorHash(valorHash);
        if (canal.isEmpty() || !canal.get().isVerificado()) {
            return Optional.empty();
        }

        Optional<PessoaUsuaria> pessoa = pessoas.findById(canal.get().getPessoaId());
        if (pessoa.isEmpty() || !pessoa.get().getEstado().permiteEntrar()) {
            return Optional.empty();
        }

        // Um codigo valido por vez: dois vivos dobrariam a chance de acerto por
        // tentativa, e fariam a pessoa digitar o numero da mensagem antiga.
        codigos.invalidarPendentes(
                canal.get().getId(), FinalidadeDoCodigo.RECUPERACAO_ACESSO, agora);

        codigos.saveAndFlush(
                new CodigoVerificacao(
                        canal.get().getId(),
                        FinalidadeDoCodigo.RECUPERACAO_ACESSO,
                        codigoHash,
                        agora,
                        agora.plus(VALIDADE)));

        auditoria.registrar(
                pessoa.get().getId(),
                TipoDeEvento.RECUPERACAO_SOLICITADA,
                ResultadoDoEvento.SUCESSO,
                agora);

        return canal;
    }

    // ------------------------------------------------------------------------
    // T067 e T068 — confirmar
    // ------------------------------------------------------------------------

    /**
     * Confere o código, troca a senha e devolve sessão nova (FR-020, FR-021).
     *
     * <p>A política de senha <b>não</b> é validada aqui: quem a valida é o
     * controlador, antes de chamar, porque senha fraca é o único erro desta
     * operação que a pessoa consegue corrigir sabendo o motivo — e o único que
     * não conta nada sobre a existência da conta.
     */
    public Resultado confirmar(
            String identificadorInformado,
            String codigoInformado,
            String novaSenha,
            String aparelhoDescricao) {

        Instant agora = relogio.instant();
        String origemHash = ContextoDaRequisicao.atual().origemHash();

        LimitadorTentativas.Decisao decisao = limitador.avaliar(null, origemHash, agora);
        if (decisao instanceof LimitadorTentativas.Decisao.Bloqueado bloqueado) {
            return new Resultado.Bloqueada(bloqueado.tentarNovamenteEmSegundos());
        }

        String valorHash = hashDoIdentificador(identificadorInformado);
        Alvo alvo = transacao.execute(status -> localizar(valorHash, agora));

        // Os dois Argon2 da operacao, os dois fora de transacao. O `confere`
        // roda contra hash ficticio quando nao ha codigo — e por isso identificador
        // inexistente custa o mesmo que codigo errado.
        boolean codigoConfere = verificador.confere(codigoInformado, alvo.codigoHash());
        String senhaHash = codificador.encode(novaSenha);

        return transacao.execute(
                status -> concluir(alvo, codigoConfere, senhaHash, aparelhoDescricao, agora));
    }

    /**
     * O que a primeira transação apura: para quem é o código, e qual é o hash dele.
     *
     * <p>Carrega identificadores em vez das entidades: elas sairiam desanexadas
     * e a segunda transação não poderia gravá-las de qualquer forma.
     *
     * @param codigoHash {@code null} quando não há código a conferir — o que faz
     *     o {@link VerificadorCredenciais} gastar o tempo contra hash fictício
     */
    private record Alvo(UUID pessoaId, UUID canalId, UUID codigoId, String codigoHash) {

        static final Alvo NENHUM = new Alvo(null, null, null, null);

        boolean existe() {
            return pessoaId != null;
        }
    }

    private Alvo localizar(String valorHash, Instant agora) {
        Optional<CanalContato> canal = canais.findByValorHash(valorHash);
        if (canal.isEmpty() || !canal.get().isVerificado()) {
            return Alvo.NENHUM;
        }

        Optional<PessoaUsuaria> pessoa = pessoas.findById(canal.get().getPessoaId());
        if (pessoa.isEmpty() || !pessoa.get().getEstado().permiteEntrar()) {
            return Alvo.NENHUM;
        }

        Optional<CodigoVerificacao> codigo =
                codigos.findFirstByCanalIdAndFinalidadeOrderByCriadoEmDesc(
                        canal.get().getId(), FinalidadeDoCodigo.RECUPERACAO_ACESSO);

        if (codigo.isEmpty() || !codigo.get().estaValidoEm(agora)) {
            // Sem codigo utilizavel, mas a conta existe: ainda assim o hash
            // ficticio roda, e o tempo nao denuncia a diferenca.
            return Alvo.NENHUM;
        }

        return new Alvo(
                pessoa.get().getId(),
                canal.get().getId(),
                codigo.get().getId(),
                codigo.get().getCodigoHash());
    }

    private Resultado concluir(
            Alvo alvo,
            boolean codigoConfere,
            String senhaHash,
            String aparelhoDescricao,
            Instant agora) {

        if (!alvo.existe()) {
            return new Resultado.Recusada();
        }

        CodigoVerificacao codigo =
                codigos.findById(alvo.codigoId())
                        .orElseThrow(() -> new IllegalStateException("codigo de recuperacao sumiu"));

        if (!codigoConfere) {
            // Contado no proprio codigo: o quinto erro o descarta, e e isso que
            // impede varrer 10^6 possibilidades com um codigo so.
            codigo.registrarTentativaErrada();
            codigos.saveAndFlush(codigo);
            return new Resultado.Recusada();
        }

        codigo.marcarComoUsado(agora);
        codigos.saveAndFlush(codigo);

        return trocarSenha(alvo, senhaHash, aparelhoDescricao, agora);
    }

    /**
     * A troca em si: senha nova, tudo revogado, sessão nova.
     *
     * <h2>A ordem destas três linhas é o cenário V5</h2>
     *
     * A revogação vem <b>antes</b> de emitir a sessão nova. Invertida, a sessão
     * recém-criada seria revogada junto com as antigas e a pessoa sairia da
     * recuperação com um token morto — trocando um problema por outro.
     *
     * <p>E a revogação precisa ser de <b>todas</b> as sessões da pessoa, não só
     * da família da sessão atual: quem trocou a senha por suspeitar de invasão
     * está justamente tentando expulsar uma sessão que não é dela. Revogar só a
     * própria família deixaria o invasor dentro, com a senha nova a caminho.
     */
    private Resultado trocarSenha(
            Alvo alvo, String senhaHash, String aparelhoDescricao, Instant agora) {

        PessoaUsuaria pessoa =
                pessoas.findById(alvo.pessoaId())
                        .orElseThrow(() -> new IllegalStateException("conta da recuperacao sumiu"));

        pessoa.trocarSenhaHash(senhaHash);

        // Limpa falhas e `bloqueada_ate`: sem isto, quem chegou na recuperacao
        // vindo do bloqueio trocaria a senha e continuaria trancado do lado de
        // fora. Nao ressuscita estado de ciclo de vida — ver o metodo.
        pessoa.registrarEntradaBemSucedida(agora);
        pessoas.saveAndFlush(pessoa);

        sessoesGravadas.revogarSessoesDaPessoa(pessoa.getId(), agora);

        ServicoDeSessao.SessaoEmitida emitida =
                sessoes.iniciar(pessoa.getId(), aparelhoDescricao, agora);

        auditoria.registrar(
                pessoa.getId(), TipoDeEvento.SENHA_ALTERADA, ResultadoDoEvento.SUCESSO, agora);

        avisar(alvo.canalId(), pessoa.getNomeTratamento());

        List<CanalContato> daPessoa = canais.findByPessoaId(pessoa.getId());
        return new Resultado.Trocada(SessaoDaPessoa.de(pessoa, daPessoa, emitida));
    }

    /**
     * O aviso da FR-022.
     *
     * <p>Vai para o canal que recebeu o código, e não para todos os canais
     * verificados: é o único que já provou pertencer a quem está trocando a
     * senha nesta operação.
     */
    private void avisar(UUID canalId, String nomeTratamento) {
        canais.findById(canalId)
                .ifPresent(canal -> notificador.avisarSenhaAlterada(canal, nomeTratamento));
    }

    /**
     * O hash do identificador, pelo mesmo caminho do login.
     *
     * <p>A presença de {@code @} decide se é e-mail ou telefone (FR-051). Pedir
     * o tipo devolveria à pessoa a pergunta "com qual dos dois você se
     * cadastrou?", que é o que a FR-051 existe para evitar.
     */
    private String hashDoIdentificador(String identificadorInformado) {
        TipoDeCanal tipo = TipoDoIdentificador.inferir(identificadorInformado);
        String valor = NormalizadorIdentificador.normalizar(tipo, identificadorInformado);
        return geradorDeHash.hashDe(valor);
    }
}

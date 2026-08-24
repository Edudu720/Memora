package br.fatec.memora.autenticacao.aplicacao;

import br.fatec.memora.autenticacao.dominio.CanalContato;
import br.fatec.memora.autenticacao.dominio.EstadoDaConta;
import br.fatec.memora.autenticacao.dominio.NormalizadorIdentificador;
import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.dominio.ResultadoDoEvento;
import br.fatec.memora.autenticacao.dominio.TipoDeCanal;
import br.fatec.memora.autenticacao.dominio.TipoDeEvento;
import br.fatec.memora.autenticacao.dominio.TipoDoIdentificador;
import br.fatec.memora.autenticacao.infra.RepositorioCanalContato;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
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
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Entrada com identificador e senha (T047, T049, FR-011, FR-013, FR-014).
 *
 * <h2>A ordem das operações é a defesa, não uma preferência de estilo</h2>
 *
 * Todo caminho que termina em recusa precisa custar o mesmo tempo. Quem mede a
 * latência do login de fora consegue transformar o endereço em uma lista de
 * quem usa o Memora — e para este público, uma lista confirmada de pessoas
 * idosas é matéria-prima de golpe telefônico (R3).
 *
 * <p>Por isso {@link VerificadorCredenciais#confere} é chamado <b>sempre</b>,
 * inclusive quando não existe conta: ele roda o Argon2 contra um hash fictício e
 * gasta os mesmos ~240 ms. Um {@code if (pessoa == null) return recusar(...)}
 * antes dessa linha seria correto em lógica e quebraria a R3 na hora.
 *
 * <h2>Por que devolver resultado em vez de lançar exceção</h2>
 *
 * A recusa precisa <b>persistir</b> o contador de falhas: é ele que faz o
 * bloqueio progressivo existir. Lançar {@link br.fatec.memora.comum.FalhaDoMemora}
 * daqui desfaria a transação e levaria o contador junto — o limitador contaria
 * até um para sempre, e a FR-014 viraria enfeite. Quem traduz o resultado em
 * status HTTP é o controlador, depois que esta transação já foi confirmada.
 *
 * <h2>Qual canal serve para entrar</h2>
 *
 * <b>Qualquer canal cadastrado</b>, verificado ou não. A FR-051 pede
 * literalmente "qualquer um dos canais cadastrados", e é a FR-052 que restringe
 * canal não verificado — só que ela restringe a <b>recuperação de acesso</b>,
 * que é onde mora o golpe da FR-062. No login o que autentica é a senha; o canal
 * apenas localiza a conta.
 *
 * <p>Exigir canal verificado aqui deixaria toda conta recém-criada sem poder
 * entrar, porque o cadastro cria o canal como não verificado e o fluxo de
 * confirmação de posse só chega na US5. Decisão da equipe em 2026-08-15;
 * {@code data-model.md} e {@code openapi.yaml} foram corrigidos junto.
 */
@Service
public class ServicoDeEntrada {

    private final RepositorioPessoaUsuaria pessoas;
    private final RepositorioCanalContato canais;
    private final VerificadorCredenciais verificador;
    private final LimitadorTentativas limitador;
    private final GeradorDeSegredoOpaco gerador;
    private final ServicoDeSessao sessoes;
    private final RegistroDeAuditoria auditoria;
    private final Clock relogio;
    private final TransactionTemplate transacao;

    public ServicoDeEntrada(
            RepositorioPessoaUsuaria pessoas,
            RepositorioCanalContato canais,
            VerificadorCredenciais verificador,
            LimitadorTentativas limitador,
            GeradorDeSegredoOpaco gerador,
            ServicoDeSessao sessoes,
            RegistroDeAuditoria auditoria,
            Clock relogio,
            PlatformTransactionManager gerenciadorDeTransacao) {
        this.pessoas = pessoas;
        this.canais = canais;
        this.verificador = verificador;
        this.limitador = limitador;
        this.gerador = gerador;
        this.sessoes = sessoes;
        this.auditoria = auditoria;
        this.relogio = relogio;
        this.transacao = new TransactionTemplate(gerenciadorDeTransacao);
    }

    /**
     * O desfecho da tentativa.
     *
     * <p>{@link Recusada} não diz por quê, e isso é a FR-013: identificador
     * inexistente e senha errada produzem o <b>mesmo</b> valor, então nem o
     * controlador consegue responder de forma diferente aos dois.
     */
    public sealed interface Resultado {

        record Autenticada(SessaoDaPessoa sessao) implements Resultado {}

        record Recusada() implements Resultado {}

        /** @param tentarNovamenteEmSegundos vai no corpo do {@code 429} (FR-014) */
        record Bloqueada(long tentarNovamenteEmSegundos) implements Resultado {}
    }

    /**
     * Executa a tentativa de entrada.
     *
     * <h2>Três etapas, e o hash fora de transação nenhuma</h2>
     *
     * O método <b>não</b> é {@code @Transactional} inteiro, e isso é
     * disponibilidade, não estilo. O Hibernate toma a conexão na primeira
     * consulta e só a devolve no commit; com o Argon2 no meio, cada tentativa
     * de entrada segurava uma conexão do pool por ~240 ms sem tocar no banco.
     * Com {@code maximum-pool-size=20}, vinte requisições simultâneas a este
     * endpoint — público, e que paga o hash até para conta inexistente —
     * esgotavam o pool e faziam cadastro e renovação esperarem por conexão.
     *
     * <p>Daí a divisão: uma transação curta resolve a conta, o hash roda fora,
     * outra transação curta grava o desfecho. O que a R3 exige continua de pé,
     * porque o que ela mede é o hash rodar <b>sempre</b> — e ele roda.
     *
     * @param identificadorInformado e-mail ou telefone, cru como veio da tela
     * @param aparelhoDescricao rótulo do aparelho, para a pessoa reconhecer a
     *     sessão depois; opcional
     */
    public Resultado entrar(
            String identificadorInformado, String senha, String aparelhoDescricao) {

        Instant agora = relogio.instant();
        String origemHash = ContextoDaRequisicao.atual().origemHash();

        Preparacao preparacao =
                transacao.execute(status -> preparar(identificadorInformado, origemHash, agora));

        if (preparacao.bloqueada()) {
            return new Resultado.Bloqueada(preparacao.tentarNovamenteEmSegundos());
        }

        // Sempre, e antes de qualquer decisao sobre a conta. Ver o cabecalho.
        // Aqui nao ha transacao aberta, e portanto nenhuma conexao presa.
        boolean senhaConfere = verificador.confere(senha, preparacao.senhaHash());

        return transacao.execute(
                status -> concluir(preparacao.pessoaId(), senhaConfere, aparelhoDescricao, agora));
    }

    /**
     * O que a primeira transação apura: quem é a conta e se a porta está aberta.
     *
     * <p>Carrega apenas {@code pessoaId} e {@code senhaHash} em vez da entidade,
     * porque a entidade sairia da transação desanexada e o passo seguinte não
     * poderia gravá-la de qualquer forma.
     */
    private record Preparacao(
            UUID pessoaId, String senhaHash, boolean bloqueada, long tentarNovamenteEmSegundos) {

        /** Conta inexistente não tem id nem hash — o verificador sabe o que fazer. */
        static Preparacao daConta(PessoaUsuaria pessoa) {
            return new Preparacao(
                    pessoa == null ? null : pessoa.getId(),
                    pessoa == null ? null : pessoa.getSenhaHash(),
                    false,
                    0);
        }

        static Preparacao doBloqueio(long segundos) {
            return new Preparacao(null, null, true, segundos);
        }
    }

    private Preparacao preparar(String identificadorInformado, String origemHash, Instant agora) {
        PessoaUsuaria pessoa = contaDoIdentificador(identificadorInformado);

        LimitadorTentativas.Decisao decisao = limitador.avaliar(pessoa, origemHash, agora);
        if (decisao instanceof LimitadorTentativas.Decisao.Bloqueado bloqueado) {
            // Bloqueio ainda em vigor: nada a contar e, de proposito, nada a
            // gravar. Escrever um evento por tentativa dava a quem nao esta
            // autenticado uma escrita sem teto na trilha, no caminho que para
            // ele e o mais barato — este e o unico que nao paga o Argon2. Com
            // retencao de 12 meses, insistir era encher a tabela de graca.
            //
            // A trilha nao fica cega: as FALHA_ENTRADA que produziram o bloqueio
            // estao la, e o BLOQUEIO em si e escrito uma vez, quando aplicado,
            // em `recusar`. O que se perde e a contagem da insistencia depois de
            // fechada a porta, e ela nao vale uma escrita ilimitada (FR-039).
            return Preparacao.doBloqueio(bloqueado.tentarNovamenteEmSegundos());
        }

        return Preparacao.daConta(pessoa);
    }

    /**
     * O desfecho, na segunda transação.
     *
     * <p>A conta é recarregada porque a instância da primeira transação já veio
     * desanexada — gravar por cima dela não levaria a alteração ao banco.
     */
    private Resultado concluir(
            UUID pessoaId, boolean senhaConfere, String aparelhoDescricao, Instant agora) {

        PessoaUsuaria pessoa = pessoaId == null ? null : pessoas.findById(pessoaId).orElse(null);

        if (!senhaConfere) {
            // Cobre os dois casos que a FR-013 obriga a tratar igual: conta que
            // nao existe e senha que nao confere. Aqui `pessoa` pode ser nula.
            return recusar(pessoa, agora);
        }

        if (pessoa == null) {
            // Senha conferiu e a conta sumiu entre as duas transacoes. Nao
            // acontece na pratica — `confere` com hash nulo sempre devolve
            // false —, mas devolver sessao para conta nenhuma seria pior.
            return new Resultado.Recusada();
        }

        // Conta desativada nao entra. A verificacao vem DEPOIS do hash de
        // proposito: adiantada, ela responderia mais rapido que uma senha errada
        // e diria a quem mede que aquele identificador tem conta.
        if (pessoa.getEstado() == EstadoDaConta.DESATIVADA) {
            return recusar(pessoa, agora);
        }

        return autenticar(pessoa, aparelhoDescricao, agora);
    }

    /**
     * A conta dona do identificador, ou {@code null}.
     *
     * <p>A busca é pelo hash do valor, nunca pelo valor em claro: é o que
     * permite o índice sem manter uma coluna pesquisável com e-mail legível.
     */
    private PessoaUsuaria contaDoIdentificador(String identificadorInformado) {
        TipoDeCanal tipo = TipoDoIdentificador.inferir(identificadorInformado);
        String valor = NormalizadorIdentificador.normalizar(tipo, identificadorInformado);

        return canais.findByValorHash(gerador.hashDe(valor))
                .flatMap(canal -> pessoas.findById(canal.getPessoaId()))
                .orElse(null);
    }

    private UUID idDe(PessoaUsuaria pessoa) {
        return pessoa == null ? null : pessoa.getId();
    }

    /**
     * Contabiliza a falha e decide se ela fecha a porta por um tempo.
     *
     * <p>A auditoria é escrita <b>antes</b> de gravar a conta de propósito.
     * {@link RegistroDeAuditoria#registrarMesmoComRollback} abre transação
     * própria; fazer isso com a linha da pessoa já travada pela transação de
     * fora colocaria uma espera entre duas conexões do mesmo pool a cada senha
     * errada. Invertida a ordem, não há trava aberta quando a segunda transação
     * começa.
     */
    private Resultado recusar(PessoaUsuaria pessoa, Instant agora) {
        Optional<Duration> bloqueio = limitador.registrarFalha(pessoa, agora);

        auditoria.registrarMesmoComRollback(
                idDe(pessoa), TipoDeEvento.FALHA_ENTRADA, ResultadoDoEvento.FALHA, agora);

        if (bloqueio.isEmpty()) {
            gravar(pessoa);
            return new Resultado.Recusada();
        }

        auditoria.registrarMesmoComRollback(
                idDe(pessoa), TipoDeEvento.BLOQUEIO, ResultadoDoEvento.FALHA, agora);
        gravar(pessoa);

        // A tentativa que estoura o limite ja responde 429, e nao 401: o passo 2
        // do cenario V6 espera a espera na quinta senha errada, nao na sexta.
        return new Resultado.Bloqueada(bloqueio.get().toSeconds());
    }

    /** Sem conta, não há contador a persistir — só a camada por origem registrou. */
    private void gravar(PessoaUsuaria pessoa) {
        if (pessoa != null) {
            pessoas.saveAndFlush(pessoa);
        }
    }

    private Resultado autenticar(
            PessoaUsuaria pessoa, String aparelhoDescricao, Instant agora) {

        // Zera o contador de falhas: e o que impede que erros espalhados por
        // semanas somem ate bloquear quem nunca fez nada de errado.
        pessoa.registrarEntradaBemSucedida(agora);
        pessoas.saveAndFlush(pessoa);

        ServicoDeSessao.SessaoEmitida sessao =
                sessoes.iniciar(pessoa.getId(), aparelhoDescricao, agora);

        auditoria.registrar(
                pessoa.getId(), TipoDeEvento.ENTRADA, ResultadoDoEvento.SUCESSO, agora);

        List<CanalContato> daPessoa = canais.findByPessoaId(pessoa.getId());

        return new Resultado.Autenticada(SessaoDaPessoa.de(pessoa, daPessoa, sessao));
    }
}

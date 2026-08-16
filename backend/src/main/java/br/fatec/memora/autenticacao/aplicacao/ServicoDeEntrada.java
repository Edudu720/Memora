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
import org.springframework.transaction.annotation.Transactional;

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

    public ServicoDeEntrada(
            RepositorioPessoaUsuaria pessoas,
            RepositorioCanalContato canais,
            VerificadorCredenciais verificador,
            LimitadorTentativas limitador,
            GeradorDeSegredoOpaco gerador,
            ServicoDeSessao sessoes,
            RegistroDeAuditoria auditoria,
            Clock relogio) {
        this.pessoas = pessoas;
        this.canais = canais;
        this.verificador = verificador;
        this.limitador = limitador;
        this.gerador = gerador;
        this.sessoes = sessoes;
        this.auditoria = auditoria;
        this.relogio = relogio;
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
     * @param identificadorInformado e-mail ou telefone, cru como veio da tela
     * @param aparelhoDescricao rótulo do aparelho, para a pessoa reconhecer a
     *     sessão depois; opcional
     */
    @Transactional
    public Resultado entrar(
            String identificadorInformado, String senha, String aparelhoDescricao) {

        Instant agora = relogio.instant();
        String origemHash = ContextoDaRequisicao.atual().origemHash();

        PessoaUsuaria pessoa = contaDoIdentificador(identificadorInformado);

        LimitadorTentativas.Decisao decisao = limitador.avaliar(pessoa, origemHash, agora);
        if (decisao instanceof LimitadorTentativas.Decisao.Bloqueado bloqueado) {
            // Tentativa durante bloqueio ainda em vigor: nada a contar, mas a
            // trilha precisa enxergar a insistencia (FR-039).
            auditoria.registrarMesmoComRollback(
                    idDe(pessoa), TipoDeEvento.BLOQUEIO, ResultadoDoEvento.FALHA, agora);

            return new Resultado.Bloqueada(bloqueado.tentarNovamenteEmSegundos());
        }

        // Sempre, e antes de qualquer decisao sobre a conta. Ver o cabecalho.
        boolean senhaConfere = verificador.confere(senha, senhaHashDe(pessoa));

        if (!senhaConfere) {
            // Cobre os dois casos que a FR-013 obriga a tratar igual: conta que
            // nao existe e senha que nao confere. Aqui `pessoa` pode ser nula.
            return recusar(pessoa, agora);
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

    /** Conta inexistente não tem hash — e o verificador sabe o que fazer com isso. */
    private String senhaHashDe(PessoaUsuaria pessoa) {
        return pessoa == null ? null : pessoa.getSenhaHash();
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

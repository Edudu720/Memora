package br.fatec.memora.autenticacao.seguranca;

import br.fatec.memora.autenticacao.dominio.EventoAutenticacao;
import br.fatec.memora.autenticacao.dominio.ResultadoDoEvento;
import br.fatec.memora.autenticacao.dominio.Sessao;
import br.fatec.memora.autenticacao.dominio.TipoDeEvento;
import br.fatec.memora.autenticacao.infra.RepositorioEventoAutenticacao;
import br.fatec.memora.autenticacao.infra.RepositorioSessao;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Abre e rotaciona sessões, detectando reuso de refresh token (T018, T019, R2).
 *
 * <h2>O que a rotação compra</h2>
 *
 * Sem rotação, um refresh token roubado vale 60 dias em silêncio. Com rotação,
 * cada uso invalida o token anterior — então o ladrão e a pessoa dona da conta
 * não conseguem coexistir: no momento em que um dos dois usa um token que o
 * outro já trocou, o sistema descobre que há duas cópias.
 *
 * <p>É isso que transforma o roubo de token de "acesso permanente e silencioso"
 * em "sessão derrubada e pessoa avisada".
 *
 * <h2>Por que derrubar a família inteira</h2>
 *
 * Quando um token já substituído reaparece, <b>não há como saber qual das duas
 * partes é a legítima</b>. Quem renovou primeiro pode ter sido o ladrão. Revogar
 * apenas o token reapresentado deixaria o ladrão dentro da conta com o token
 * novo.
 *
 * <p>Derrubar tudo custa um login novo à pessoa dona da conta — incômodo real,
 * especialmente para este público — e custa o acesso inteiro a quem roubou. O
 * Princípio I resolve o empate: segurança vence conveniência.
 */
@Service
public class ServicoDeSessao {

    /**
     * Prazo do refresh, renovado a cada uso (R2).
     *
     * <p>Longo de propósito. O token de acesso curto protege a sessão; este é o
     * que permite a uma pessoa idosa reabrir o aplicativo semanas depois e
     * continuar conectada, sem digitar senha (FR-016).
     */
    public static final Duration VALIDADE_DO_REFRESH = Duration.ofDays(60);

    private final RepositorioSessao sessoes;
    private final RepositorioEventoAutenticacao eventos;
    private final GeradorDeSegredoOpaco gerador;
    private final EmissorDeTokenDeAcesso emissor;

    public ServicoDeSessao(
            RepositorioSessao sessoes,
            RepositorioEventoAutenticacao eventos,
            GeradorDeSegredoOpaco gerador,
            EmissorDeTokenDeAcesso emissor) {
        this.sessoes = sessoes;
        this.eventos = eventos;
        this.gerador = gerador;
        this.emissor = emissor;
    }

    /** O par de tokens entregue ao aplicativo. */
    public record SessaoEmitida(
            UUID pessoaId, String tokenAcesso, String refreshToken, long expiraEmSegundos) {}

    /**
     * Por que a renovação foi recusada.
     *
     * <p>Serve à <b>auditoria</b>, não ao cliente: a resposta da API é
     * {@code 401} em todos os casos. Dizer a quem chama que o motivo foi "reuso
     * detectado" entregaria de graça a informação de que aquele token um dia foi
     * válido.
     */
    public enum MotivoDaRecusa {
        TOKEN_DESCONHECIDO,
        REUSO_DETECTADO,
        SESSAO_REVOGADA,
        TOKEN_EXPIRADO
    }

    public sealed interface ResultadoDaRenovacao {

        record Renovada(SessaoEmitida sessao) implements ResultadoDaRenovacao {}

        record Recusada(MotivoDaRecusa motivo) implements ResultadoDaRenovacao {}
    }

    /**
     * Abre a primeira sessão de uma família — cadastro ou entrada.
     *
     * <p>O evento de {@code CADASTRO} ou {@code ENTRADA} é registrado por quem
     * chama, junto do resto do fluxo (T025).
     */
    @Transactional
    public SessaoEmitida iniciar(UUID pessoaId, String aparelhoDescricao, Instant agora) {
        String refresh = gerador.gerar();

        sessoes.saveAndFlush(Sessao.iniciarFamilia(
                pessoaId,
                gerador.hashDe(refresh),
                aparelhoDescricao,
                agora,
                agora.plus(VALIDADE_DO_REFRESH)));

        return emitir(pessoaId, refresh, agora);
    }

    /**
     * Rotaciona a sessão, ou recusa.
     *
     * @param refreshApresentado o token que o aplicativo enviou, em claro
     * @param origemHash endereço de rede hasheado, para a trilha
     */
    @Transactional
    public ResultadoDaRenovacao renovar(
            String refreshApresentado, String origemHash, Instant agora) {

        Optional<Sessao> encontrada =
                sessoes.findByRefreshTokenHash(gerador.hashDe(refreshApresentado));

        if (encontrada.isEmpty()) {
            return new ResultadoDaRenovacao.Recusada(MotivoDaRecusa.TOKEN_DESCONHECIDO);
        }

        Sessao sessao = encontrada.get();

        // A ordem das verificações importa. Depois de uma revogação por reuso, a
        // sessão fica substituída E revogada; se "revogada" fosse verificada
        // primeiro, a segunda apresentação do token roubado apareceria na
        // auditoria como sessão encerrada comum, e o sinal de roubo — o mais
        // grave que esta trilha registra — se perderia.
        if (sessao.foiSubstituida()) {
            return tratarReuso(sessao, origemHash, agora);
        }

        if (sessao.estaRevogada()) {
            return new ResultadoDaRenovacao.Recusada(MotivoDaRecusa.SESSAO_REVOGADA);
        }

        if (sessao.expirouEm(agora)) {
            return new ResultadoDaRenovacao.Recusada(MotivoDaRecusa.TOKEN_EXPIRADO);
        }

        return new ResultadoDaRenovacao.Renovada(rotacionar(sessao, agora));
    }

    private ResultadoDaRenovacao tratarReuso(Sessao sessao, String origemHash, Instant agora) {
        UUID pessoaId = sessao.getPessoaId();
        UUID familiaId = sessao.getFamiliaId();

        // Uma instrução só. Carregar as sessões, decidir e gravar uma a uma
        // abriria janela para a requisição concorrente do atacante passar no
        // meio da revogação.
        sessoes.revogarFamilia(familiaId, agora);

        eventos.save(EventoAutenticacao.de(
                pessoaId,
                TipoDeEvento.REUSO_TOKEN_DETECTADO,
                ResultadoDoEvento.FALHA,
                origemHash,
                agora));

        // A pessoa também precisa ser avisada (V3, passo 5). A notificação por
        // canal é do NotificadorDeConta, que nasce na T068; o evento acima é o
        // que garante que o aviso terá de onde partir.
        return new ResultadoDaRenovacao.Recusada(MotivoDaRecusa.REUSO_DETECTADO);
    }

    private SessaoEmitida rotacionar(Sessao anterior, Instant agora) {
        String refresh = gerador.gerar();

        Sessao nova = sessoes.saveAndFlush(Sessao.continuarFamilia(
                anterior.getPessoaId(),
                anterior.getFamiliaId(),
                gerador.hashDe(refresh),
                anterior.getAparelhoDescricao(),
                agora,
                agora.plus(VALIDADE_DO_REFRESH)));

        anterior.substituirPor(nova);
        sessoes.saveAndFlush(anterior);

        return emitir(anterior.getPessoaId(), refresh, agora);
    }

    private SessaoEmitida emitir(UUID pessoaId, String refresh, Instant agora) {
        return new SessaoEmitida(
                pessoaId,
                emissor.emitir(pessoaId, agora),
                refresh,
                EmissorDeTokenDeAcesso.VALIDADE.toSeconds());
    }
}

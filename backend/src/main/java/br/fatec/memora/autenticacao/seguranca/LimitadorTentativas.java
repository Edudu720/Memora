package br.fatec.memora.autenticacao.seguranca;

import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.dominio.TipoDeEvento;
import br.fatec.memora.autenticacao.infra.RepositorioEventoAutenticacao;
import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import org.springframework.stereotype.Component;

/**
 * Limite de tentativas em duas camadas independentes (T021, R4).
 *
 * <table>
 *   <caption>As duas camadas</caption>
 *   <tr><th>Camada</th><th>Alvo</th><th>Contra o que protege</th></tr>
 *   <tr>
 *     <td>Por conta</td>
 *     <td>Uma conta específica</td>
 *     <td>Alguém insistindo na senha de <i>uma</i> pessoa</td>
 *   </tr>
 *   <tr>
 *     <td>Por origem</td>
 *     <td>Um endereço de rede</td>
 *     <td>Varredura de <i>muitas</i> contas, uma tentativa em cada</td>
 *   </tr>
 * </table>
 *
 * <p>As duas são necessárias porque uma não vê o ataque da outra: a camada por
 * conta é cega para quem testa mil identificadores diferentes uma vez cada — o
 * padrão de quem chega com uma lista de credenciais vazadas.
 *
 * <h2>Onde mora o estado, e por quê não em memória</h2>
 *
 * A R4 exige estado <b>fora da memória local</b>: contador em memória se apaga a
 * cada reinício, e reiniciar o servidor no meio de um ataque zeraria a defesa.
 *
 * <p>As duas camadas já têm onde guardar isso no banco, sem tabela nova:
 *
 * <ul>
 *   <li>por conta — {@code pessoa_usuaria.falhas_consecutivas} e
 *       {@code bloqueada_ate};
 *   <li>por origem — contagem sobre {@code evento_autenticacao}, que a FR-039
 *       obriga a escrever de qualquer forma.
 * </ul>
 *
 * <p><b>Divergência da R4</b>: ela sugeria Bucket4j. Não foi usado — a
 * biblioteca traria uma dependência e uma tabela de estado próprias para
 * reimplementar contagem que a trilha de auditoria já mantém. Se o volume
 * crescer ao ponto de a contagem por janela pesar, a troca é localizada nesta
 * classe.
 *
 * <h2>Limitação conhecida</h2>
 *
 * A camada por conta só existe para conta que existe. Um {@code 429} depois de
 * cinco tentativas revela, portanto, que aquele identificador tem conta — o
 * oposto do que a R3 busca. A camada por origem atenua, porque quem varre
 * identificadores acaba recusado de qualquer jeito, mas não fecha a brecha:
 * para isso seria necessário contar falhas por <i>identificador</i>, inclusive
 * inexistente, e a trilha de auditoria deliberadamente não guarda identificador
 * (FR-040). Fica registrado para a equipe decidir.
 */
@Component
public class LimitadorTentativas {

    /**
     * Falhas toleradas de uma mesma origem dentro da janela.
     *
     * <p>O número é generoso de propósito. Este produto será usado em lugares
     * onde várias pessoas dividem a mesma saída de rede — casa de família, e
     * principalmente instituição de longa permanência. Um limite apertado
     * transformaria o erro de digitação de um residente em bloqueio para os
     * outros trinta.
     *
     * <p>Contra ataque, quem segura o caso dirigido é a camada por conta, que
     * corta na quinta tentativa. Esta camada existe para a varredura ampla, e
     * 50 tentativas em 15 minutos já é ordens de grandeza abaixo do que uma
     * varredura automatizada precisa.
     */
    public static final int FALHAS_POR_ORIGEM_NA_JANELA = 50;

    /** Janela deslizante da camada por origem. */
    public static final Duration JANELA_POR_ORIGEM = Duration.ofMinutes(15);

    /** Espera imposta à origem recusada. Curta: a origem pode ser compartilhada. */
    public static final Duration ESPERA_POR_ORIGEM = Duration.ofMinutes(5);

    private final RepositorioEventoAutenticacao eventos;
    private final BloqueioProgressivo escada;

    public LimitadorTentativas(
            RepositorioEventoAutenticacao eventos, BloqueioProgressivo escada) {
        this.eventos = eventos;
        this.escada = escada;
    }

    /** O que fazer com uma tentativa. */
    public sealed interface Decisao {

        /** Segue o fluxo normal de verificação. */
        record Permitido() implements Decisao {}

        /**
         * Recusa com espera.
         *
         * @param tentarNovamenteEmSegundos vai para o campo
         *     {@code tentar_novamente_em_segundos} da resposta {@code 429}
         */
        record Bloqueado(long tentarNovamenteEmSegundos) implements Decisao {}
    }

    /**
     * Decide se a tentativa pode prosseguir.
     *
     * @param pessoa a conta do identificador apresentado, ou {@code null} quando
     *     não existe conta — e nesse caso a decisão <b>não</b> pode depender
     *     disso, sob pena de virar oráculo de quem usa o Memora
     * @param origemHash endereço de rede hasheado, ou {@code null} quando
     *     indisponível
     */
    public Decisao avaliar(PessoaUsuaria pessoa, String origemHash, Instant agora) {
        if (pessoa != null && pessoa.estaBloqueadaEm(agora)) {
            long segundos = Duration.between(agora, pessoa.getBloqueadaAte()).toSeconds();
            return new Decisao.Bloqueado(segundos);
        }

        if (origemHash != null && origemExcedeuLimite(origemHash, agora)) {
            return new Decisao.Bloqueado(ESPERA_POR_ORIGEM.toSeconds());
        }

        return new Decisao.Permitido();
    }

    /**
     * Contabiliza uma tentativa recusada na conta e aplica o bloqueio devido.
     *
     * <p>Altera a entidade recebida; quem chama grava, na própria transação. O
     * registro do evento correspondente é da auditoria (T025), não daqui.
     *
     * @param pessoa a conta, ou {@code null} quando o identificador não existe —
     *     nesse caso não há contador a incrementar, e a tentativa fica registrada
     *     apenas pela camada por origem
     * @return o bloqueio aplicado, ou vazio se ainda não houve bloqueio
     */
    public Optional<Duration> registrarFalha(PessoaUsuaria pessoa, Instant agora) {
        if (pessoa == null) {
            return Optional.empty();
        }

        pessoa.registrarFalhaDeEntrada();

        Optional<Duration> bloqueio = escada.duracaoPara(pessoa.getFalhasConsecutivas());
        bloqueio.ifPresent(duracao -> pessoa.bloquearAte(agora.plus(duracao)));

        return bloqueio;
    }

    private boolean origemExcedeuLimite(String origemHash, Instant agora) {
        long falhasRecentes = eventos.countByOrigemHashAndTipoAndOcorridoEmAfter(
                origemHash, TipoDeEvento.FALHA_ENTRADA, agora.minus(JANELA_POR_ORIGEM));

        return falhasRecentes >= FALHAS_POR_ORIGEM_NA_JANELA;
    }
}

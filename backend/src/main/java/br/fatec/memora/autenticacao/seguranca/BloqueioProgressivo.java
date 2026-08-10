package br.fatec.memora.autenticacao.seguranca;

import java.time.Duration;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Component;

/**
 * Quanto tempo esperar depois de falhas consecutivas (FR-014, R4).
 *
 * <h2>Por que progressivo e nao permanente</h2>
 *
 * Bloqueio permanente puniria exatamente quem esta feature existe para servir.
 * Errar a senha cinco vezes seguidas, para uma pessoa que esta aprendendo a usar
 * o teclado do celular, e comportamento esperado — nao e sinal de ataque.
 *
 * <p>A escada resolve as duas necessidades ao mesmo tempo: a primeira espera e
 * de um minuto, curta o bastante para quem so se confundiu, e vai crescendo ate
 * uma hora, o que torna busca exaustiva inviavel.
 *
 * <h2>O texto importa tanto quanto o tempo</h2>
 *
 * A FR-015 exige que a mensagem explique o motivo, diga quando sera possivel
 * tentar de novo e ofereca a recuperacao — <b>sem tom de punicao</b>. Esta classe
 * decide apenas a duracao; o texto e da camada de apresentacao, e o cenario V6
 * reprova bloqueio tecnicamente correto com texto rispido.
 */
@Component
public class BloqueioProgressivo {

    /** Antes disto, nada acontece: e margem para erro de digitacao. */
    public static final int FALHAS_ATE_BLOQUEAR = 5;

    /** A escada da R4, do primeiro degrau ao teto. */
    private static final List<Duration> ESCADA = List.of(
            Duration.ofMinutes(1),
            Duration.ofMinutes(5),
            Duration.ofMinutes(15),
            Duration.ofMinutes(60));

    /**
     * Duracao do bloqueio para uma contagem de falhas consecutivas.
     *
     * @return vazio quando ainda nao ha bloqueio
     */
    public Optional<Duration> duracaoPara(int falhasConsecutivas) {
        if (falhasConsecutivas < FALHAS_ATE_BLOQUEAR) {
            return Optional.empty();
        }

        int degrau = falhasConsecutivas - FALHAS_ATE_BLOQUEAR;

        // Passado o ultimo degrau, a espera fica no teto. Deixar crescer sem
        // limite viraria bloqueio permanente por acumulo, que e o que esta
        // classe existe para evitar.
        return Optional.of(ESCADA.get(Math.min(degrau, ESCADA.size() - 1)));
    }
}

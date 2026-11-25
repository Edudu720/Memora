package br.fatec.memora.antigolpe.seguranca;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicReference;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Limitador de frequência em janela deslizante por conta para análises antigolpe.
 *
 * <p>Protege a cota do provedor de IA e evita abuso automatizado sem compartilhar a cota de
 * conversas da assistente.
 */
@Component
public class LimitadorAnaliseGolpe {

    static final Duration JANELA_HORA = Duration.ofHours(1);
    static final Duration JANELA_DIA = Duration.ofHours(24);
    static final Duration INTERVALO_EXPURGO = Duration.ofMinutes(5);

    private final Clock relogio;
    private final int maximoPorHora;
    private final int maximoPorDia;
    private final Map<UUID, Deque<Instant>> porConta = new ConcurrentHashMap<>();
    private final AtomicReference<Instant> ultimoExpurgo = new AtomicReference<>(Instant.EPOCH);

    @Autowired
    public LimitadorAnaliseGolpe(
            Clock relogio,
            @Value("${memora.antigolpe.analises-por-hora:20}") int maximoPorHora,
            @Value("${memora.antigolpe.analises-por-dia:60}") int maximoPorDia) {
        this.relogio = Objects.requireNonNull(relogio, "relogio");
        if (maximoPorHora < 1) {
            throw new IllegalArgumentException("maximoPorHora deve ser >= 1");
        }
        if (maximoPorDia < 1) {
            throw new IllegalArgumentException("maximoPorDia deve ser >= 1");
        }
        this.maximoPorHora = maximoPorHora;
        this.maximoPorDia = maximoPorDia;
    }

    /** Resultado da avaliação de limite para testes e inspeção direta. */
    public record Decisao(boolean permitido, long tentarNovamenteEmSegundos) {
        public static Decisao liberado() {
            return new Decisao(true, 0L);
        }

        public static Decisao bloqueado(long tentarNovamenteEmSegundos) {
            return new Decisao(false, Math.max(1L, tentarNovamenteEmSegundos));
        }
    }

    /**
     * Verifica a cota da conta usando o {@link Clock} configurado e lança
     * {@link LimiteAnaliseGolpeExcedido} quando o limite é ultrapassado.
     */
    public void verificarERegistrar(UUID pessoaId) {
        Decisao decisao = avaliarERegistrar(pessoaId, relogio.instant());
        if (!decisao.permitido()) {
            throw new LimiteAnaliseGolpeExcedido(decisao.tentarNovamenteEmSegundos());
        }
    }

    /**
     * Avalia a janela deslizante para {@code pessoaId} no instante {@code agora} e contabiliza a
     * chamada caso esteja permitida.
     */
    public Decisao avaliarERegistrar(UUID pessoaId, Instant agora) {
        Objects.requireNonNull(pessoaId, "pessoaId");
        Objects.requireNonNull(agora, "agora");

        expurgarContasInativasSeNecessario(agora);

        Decisao[] decisao = new Decisao[1];
        porConta.compute(
                pessoaId,
                (id, historicoAtual) -> {
                    Deque<Instant> historico =
                            historicoAtual != null ? historicoAtual : new ArrayDeque<>();
                    long espera = calcularEspera(historico, agora);
                    if (espera > 0L) {
                        decisao[0] = Decisao.bloqueado(espera);
                        return historico.isEmpty() ? null : historico;
                    }
                    historico.addLast(agora);
                    decisao[0] = Decisao.liberado();
                    return historico;
                });
        return decisao[0];
    }

    int contasRastreadas() {
        return porConta.size();
    }

    private void expurgarContasInativasSeNecessario(Instant agora) {
        Instant anterior = ultimoExpurgo.get();
        if (!agora.isBefore(anterior.plus(INTERVALO_EXPURGO))
                && ultimoExpurgo.compareAndSet(anterior, agora)) {
            expurgarContasInativas(agora);
        }
    }

    private void expurgarContasInativas(Instant agora) {
        Instant corteDia = agora.minus(JANELA_DIA);
        for (UUID id : porConta.keySet()) {
            porConta.computeIfPresent(
                    id,
                    (chave, historico) -> {
                        while (!historico.isEmpty()
                                && !historico.peekFirst().isAfter(corteDia)) {
                            historico.removeFirst();
                        }
                        return historico.isEmpty() ? null : historico;
                    });
        }
    }

    private long calcularEspera(Deque<Instant> historico, Instant agora) {
        Instant corteDia = agora.minus(JANELA_DIA);
        while (!historico.isEmpty() && !historico.peekFirst().isAfter(corteDia)) {
            historico.removeFirst();
        }

        if (historico.size() >= maximoPorDia) {
            Instant maisAntigoDia = historico.peekFirst();
            return segundosArredondadosParaCima(agora, maisAntigoDia.plus(JANELA_DIA));
        }

        Instant corteHora = agora.minus(JANELA_HORA);
        int naUltimaHora = 0;
        Instant maisAntigoHora = null;
        for (Instant instante : historico) {
            if (instante.isAfter(corteHora)) {
                if (maisAntigoHora == null) {
                    maisAntigoHora = instante;
                }
                naUltimaHora++;
            }
        }
        if (naUltimaHora >= maximoPorHora && maisAntigoHora != null) {
            return segundosArredondadosParaCima(agora, maisAntigoHora.plus(JANELA_HORA));
        }
        return 0L;
    }

    private static long segundosArredondadosParaCima(Instant agora, Instant limite) {
        return Math.max(1L, (Duration.between(agora, limite).toMillis() + 999L) / 1000L);
    }
}

package br.fatec.memora.emergencia.seguranca;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.HexFormat;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Component;

/**
 * Limitador de frequência para envios remotos de SOS (Feature 014, Princípio II).
 *
 * <p>Impede que o servidor seja usado como disparador aberto de e-mails para terceiros ou esgote
 * a cota SMTP compartilhada com a recuperação de senha, aplicando teto por conta e por
 * destinatário (armazenado apenas como hash SHA-256 sem PII).
 */
@Component
public class LimitadorDeEnvioSos {

    /** Teto de envios por hora por conta ou destinatário. */
    public static final int MAXIMO_POR_HORA = 3;

    /** Teto de envios em 24 horas por conta ou destinatário. */
    public static final int MAXIMO_POR_DIA = 10;

    static final Duration JANELA_HORA = Duration.ofHours(1);
    static final Duration JANELA_DIA = Duration.ofHours(24);

    private final Map<UUID, Deque<Instant>> porConta = new ConcurrentHashMap<>();
    private final Map<String, Deque<Instant>> porDestinoHash = new ConcurrentHashMap<>();

    /**
     * Resultado da avaliação de limite.
     *
     * @param permitido {@code true} quando o envio está dentro da cota e foi contabilizado
     * @param tentarNovamenteEmSegundos espera mínima sugerida para resposta {@code 429}
     */
    public record Decisao(boolean permitido, long tentarNovamenteEmSegundos) {
        public static Decisao liberado() {
            return new Decisao(true, 0L);
        }

        public static Decisao bloqueado(long tentarNovamenteEmSegundos) {
            return new Decisao(false, Math.max(1L, tentarNovamenteEmSegundos));
        }
    }

    /**
     * Verifica os limites por conta e por destino e, se ambos estiverem livres, registra o
     * acionamento no instante {@code agora}.
     */
    public Decisao verificarERegistrar(UUID pessoaId, String destino, Instant agora) {
        Deque<Instant> historicoConta =
                porConta.computeIfAbsent(pessoaId, ignored -> new ArrayDeque<>());
        String hashDestino = hashDestino(destino);
        Deque<Instant> historicoDestino =
                hashDestino != null
                        ? porDestinoHash.computeIfAbsent(hashDestino, ignored -> new ArrayDeque<>())
                        : null;

        // Ordena o bloqueio para evitar deadlock caso threads concorrentes avaliem os mesmos mapas.
        synchronized (this) {
            long esperaConta = calcularEspera(historicoConta, agora);
            long esperaDestino =
                    historicoDestino != null ? calcularEspera(historicoDestino, agora) : 0L;
            long maiorEspera = Math.max(esperaConta, esperaDestino);
            if (maiorEspera > 0L) {
                return Decisao.bloqueado(maiorEspera);
            }

            historicoConta.addLast(agora);
            if (historicoDestino != null) {
                historicoDestino.addLast(agora);
            }
            return Decisao.liberado();
        }
    }

    private static long calcularEspera(Deque<Instant> historico, Instant agora) {
        Instant corteDia = agora.minus(JANELA_DIA);
        while (!historico.isEmpty() && !historico.peekFirst().isAfter(corteDia)) {
            historico.removeFirst();
        }

        if (historico.size() >= MAXIMO_POR_DIA) {
            Instant maisAntigoDia = historico.peekFirst();
            return Math.max(1L, Duration.between(agora, maisAntigoDia.plus(JANELA_DIA)).toSeconds());
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
        if (naUltimaHora >= MAXIMO_POR_HORA && maisAntigoHora != null) {
            return Math.max(1L, Duration.between(agora, maisAntigoHora.plus(JANELA_HORA)).toSeconds());
        }
        return 0L;
    }

    private static String hashDestino(String destino) {
        if (destino == null) {
            return null;
        }
        String normalizado = destino.trim().toLowerCase(Locale.ROOT);
        if (normalizado.isEmpty()) {
            return null;
        }
        if (!normalizado.contains("@")) {
            String digitos = normalizado.replaceAll("\\D", "");
            if (!digitos.isEmpty()) {
                normalizado = digitos;
            }
        }
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] digito = md.digest(normalizado.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digito);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 indisponivel", e);
        }
    }
}

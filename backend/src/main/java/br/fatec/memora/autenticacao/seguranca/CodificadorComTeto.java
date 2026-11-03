package br.fatec.memora.autenticacao.seguranca;

import java.util.concurrent.Semaphore;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Limita quantos hashes de senha rodam ao mesmo tempo, sem mudar o que cada um
 * produz.
 *
 * <h2>Por que existe</h2>
 *
 * Cada hash Argon2id aloca {@link ConfiguracaoDeSenha#MEMORIA_KIB} KiB (64 MiB)
 * de heap. Numa imagem com 512 MB, o heap é de ~384 MB, e medimos que 5
 * cadastros simultâneos passam enquanto <b>10 derrubam a JVM</b> com
 * {@code OutOfMemoryError: Java heap space}. Como os endpoints de cadastro,
 * entrada e recuperação são públicos, isso seria negação de serviço por quem
 * mandasse dez requisições ao mesmo tempo.
 *
 * <h2>Fila, e não recusa</h2>
 *
 * Quem passa do teto <b>espera a vez</b>; ninguém leva erro. O semáforo é
 * justo (fair): sem isso, uma rajada poderia deixar uma requisição esperando
 * para sempre enquanto as recém-chegadas furam a fila. O preço é latência sob
 * carga, que é o preço certo — a alternativa era perder o processo.
 *
 * <h2>A R3 continua valendo</h2>
 *
 * O tempo constante com ou sem conta depende de o hash rodar <i>sempre</i>, e
 * ele roda: todo caminho passa por este mesmo codificador, existindo conta ou
 * não. A espera na fila é igual nos dois casos, porque quem espera não sabe, e
 * o teto não enxerga, se a conta existe.
 *
 * <p>{@link #upgradeEncoding} não faz hash, só consulta o formato do já
 * gravado, e por isso não ocupa permissão.
 */
final class CodificadorComTeto implements PasswordEncoder {

    private final PasswordEncoder interno;

    private final Semaphore permissoes;

    CodificadorComTeto(PasswordEncoder interno, int teto) {
        if (teto < 1) {
            throw new IllegalArgumentException(
                    "o teto de hashes simultaneos deve ser pelo menos 1, e veio " + teto);
        }
        this.interno = interno;
        this.permissoes = new Semaphore(teto, true);
    }

    @Override
    public String encode(CharSequence senhaEmClaro) {
        adquirir();
        try {
            return interno.encode(senhaEmClaro);
        } finally {
            permissoes.release();
        }
    }

    @Override
    public boolean matches(CharSequence senhaEmClaro, String hashGravado) {
        adquirir();
        try {
            return interno.matches(senhaEmClaro, hashGravado);
        } finally {
            permissoes.release();
        }
    }

    @Override
    public boolean upgradeEncoding(String hashGravado) {
        return interno.upgradeEncoding(hashGravado);
    }

    /**
     * Espera a vez. Interrompida, <b>não segue sem a permissão</b>: seguir
     * furaria o teto justamente quando a JVM está sendo encerrada às pressas.
     */
    private void adquirir() {
        try {
            permissoes.acquire();
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException(
                    "interrompido enquanto esperava a vez de calcular o hash de senha", e);
        }
    }
}

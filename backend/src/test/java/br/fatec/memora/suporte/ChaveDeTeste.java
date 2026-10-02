package br.fatec.memora.suporte;

import java.util.UUID;

/**
 * Chave de catálogo para serviço criado por teste.
 *
 * <p>A coluna {@code chave} tem {@code UNIQUE} (V8). Uma chave fixa faria o
 * segundo serviço de teste colidir com o primeiro — e, pior, faria testes que
 * existem para provar <b>outra</b> restrição (como o {@code ux_servico_pacote})
 * reprovarem pela {@code ux_servico_chave}, escondendo o que realmente
 * quebrou. Cada chamada devolve uma chave nova.
 *
 * <p>Formato: o do banco, {@code ^[a-z0-9-]+$}, até 40 caracteres. O prefixo
 * {@code t-} mais os 36 de um UUID dá 38.
 */
public final class ChaveDeTeste {

    private ChaveDeTeste() {
    }

    /** Uma chave válida e nunca usada antes. */
    public static String nova() {
        return "t-" + UUID.randomUUID();
    }
}

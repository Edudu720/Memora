package br.fatec.memora.autenticacao.seguranca;

import br.fatec.memora.autenticacao.dominio.EstadoDaConta;
import java.util.Objects;
import java.util.UUID;

/**
 * Quem está do outro lado de uma requisição autenticada (T058).
 *
 * <p>Guarda o mínimo: o identificador da conta e o estado dela. Nome, canais e
 * qualquer outro dado ficam de fora de propósito — este objeto atravessa o
 * {@code SecurityContext} de toda requisição autenticada, e o que não está aqui
 * não vaza por descuido em log de depuração.
 *
 * <p><b>A existência deste tipo já é uma afirmação</b>: só se constrói um
 * {@code PessoaAutenticada} depois de a conta ter sido encontrada no banco. Ver
 * {@link FiltroDeTokenDeAcesso} para o motivo de isso não ser opcional.
 */
/// @param familiaId de qual sessão veio o token; {@code null} em token emitido
///     antes de a T074 existir e ainda dentro dos 15 minutos de validade
public record PessoaAutenticada(UUID id, EstadoDaConta estado, UUID familiaId) {

    public PessoaAutenticada {
        Objects.requireNonNull(id, "id");
        Objects.requireNonNull(estado, "estado");
        // familiaId aceita nulo de proposito: ver o parametro.
    }

    /**
     * A conta ainda espera a confirmação de posse do canal (FR-062)?
     *
     * <p>Quem responde {@code true} só pode percorrer o caminho de confirmar
     * canal. Qualquer outro endpoint autenticado precisa recusá-la.
     */
    public boolean estaPendenteDeVerificacao() {
        return estado == EstadoDaConta.PENDENTE_VERIFICACAO;
    }
}

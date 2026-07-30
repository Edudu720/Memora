package br.fatec.memora.autenticacao.infra;

import br.fatec.memora.autenticacao.dominio.CanalContato;
import br.fatec.memora.autenticacao.dominio.TipoDeCanal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Acesso aos canais de contato (T014).
 *
 * <p>Cada consulta aqui corresponde a um índice declarado na migration V1.
 */
public interface RepositorioCanalContato extends JpaRepository<CanalContato, UUID> {

    /**
     * Localiza o canal pelo hash do valor — o caminho do login.
     *
     * <p>Usa {@code ix_canal_valor_hash}. Buscar pelo hash em vez do valor
     * evita comparar e-mail em claro a cada tentativa de entrada.
     */
    Optional<CanalContato> findByValorHash(String valorHash);

    /**
     * Verifica se o canal já pertence a alguma conta.
     *
     * <p>Usa {@code uq_canal_tipo_valor}.
     *
     * <p><b>O resultado nunca vira mensagem para quem está cadastrando.</b> A
     * FR-010 exige resposta {@code 201} idêntica quando o canal já existe;
     * responder "e-mail já cadastrado" transformaria o cadastro em oráculo de
     * quem usa o Memora.
     */
    boolean existsByTipoAndValor(TipoDeCanal tipo, String valor);

    /** Canais de uma conta, para escolher onde enviar código. */
    List<CanalContato> findByPessoaId(UUID pessoaId);

    /**
     * Canais de uma conta cuja posse já foi confirmada.
     *
     * <p>É a consulta da recuperação de acesso: canal não verificado
     * <b>nunca</b> recebe código (FR-052), porque seria o caminho do golpe
     * descrito na FR-062.
     */
    List<CanalContato> findByPessoaIdAndVerificadoTrue(UUID pessoaId);
}

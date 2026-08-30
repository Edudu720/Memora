package br.fatec.memora.assistente.infra;

import br.fatec.memora.assistente.dominio.CategoriaDoServico;
import br.fatec.memora.assistente.dominio.ServicoConhecido;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Acesso ao catálogo (T010).
 *
 * <p><b>É este repositório que autoriza.</b> A FR-022 exige que a decisão sobre
 * executar uma ação seja determinística e tomada fora do modelo; as consultas
 * abaixo são essa decisão.
 */
public interface RepositorioServicoConhecido extends JpaRepository<ServicoConhecido, UUID> {

    /**
     * Busca um serviço ativo pelo id — a consulta da autorização.
     *
     * <p>Filtra por {@code ativo} na própria consulta, e não depois: um serviço
     * tirado do ar precisa parar de ser autorizável no mesmo instante, sem
     * depender de quem chama lembrar de verificar.
     */
    Optional<ServicoConhecido> findByIdAndAtivoTrue(UUID id);

    /**
     * Serviços de uma categoria, para as duas portas do Hub (FR-043, FR-044).
     *
     * <p>Usa {@code ix_servico_categoria}.
     */
    List<ServicoConhecido> findByCategoriaAndAtivoTrueOrderByNomeExibido(
            CategoriaDoServico categoria);

    /** Todo o catálogo ativo, quando a tela pede as duas listas de uma vez. */
    List<ServicoConhecido> findByAtivoTrueOrderByNomeExibido();

    /**
     * Busca pelo pacote Android — <b>a consulta que decide a autorização</b>.
     *
     * <p>É por este nome que o modelo referencia um aplicativo, porque é o que
     * ele vê no catálogo do system prompt. O índice único parcial
     * {@code ux_servico_pacote} garante que só um serviço ativo responda.
     *
     * <p>Serviço sensível <b>nunca</b> aparece aqui: ele não tem pacote, por
     * restrição do banco. A FR-041 se cumpre por ausência de dado.
     */
    Optional<ServicoConhecido> findByIdentificadorAndroidAndAtivoTrue(String identificadorAndroid);
}

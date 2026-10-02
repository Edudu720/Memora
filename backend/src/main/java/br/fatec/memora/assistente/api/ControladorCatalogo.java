package br.fatec.memora.assistente.api;

import br.fatec.memora.assistente.dominio.CategoriaDoServico;
import br.fatec.memora.assistente.dominio.ServicoConhecido;
import br.fatec.memora.assistente.infra.RepositorioServicoConhecido;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * {@code GET /v1/assistente/catalogo} (T043).
 *
 * <h2>O que a pessoa precisa saber antes de tocar</h2>
 *
 * Cada item diz se a Memora <b>ensina</b> ou <b>ensina e abre</b> (FR-045).
 * Descobrir a diferença só ao chegar lá seria uma promessa quebrada — e a
 * diferença aqui não é detalhe de produto: ela é a proteção da FR-041.
 *
 * <h2>Por que {@code memora_pode_abrir} viaja, se a categoria já viaja</h2>
 *
 * Parece redundante, e é de propósito. É esse campo que a tela exibe, e derivá-lo
 * no aplicativo espalharia a regra da FR-041 por dois lugares que podem
 * divergir — o dia em que uma terceira categoria existir, a tela estaria
 * decidindo sozinha o que fazer com ela.
 *
 * <p>Ele também não é autorização: quem autoriza abrir é o
 * {@code AutorizadorDeAcao}, no momento da ação, consultando o banco de novo.
 * Este campo só diz o que <b>exibir</b>.
 */
@RestController
@RequestMapping("/v1/assistente")
public class ControladorCatalogo {

    private final RepositorioServicoConhecido servicos;

    /** Cria o controlador. */
    public ControladorCatalogo(RepositorioServicoConhecido servicos) {
        this.servicos = servicos;
    }

    /** Um serviço, como a pessoa o vê. */
    @JsonInclude(JsonInclude.Include.NON_NULL)
    public record ServicoResposta(
            @JsonProperty("id") UUID id,
            @JsonProperty("chave") String chave,
            @JsonProperty("nome_exibido") String nomeExibido,
            @JsonProperty("descricao_curta") String descricaoCurta,
            @JsonProperty("categoria") String categoria,
            @JsonProperty("memora_pode_abrir") boolean memoraPodeAbrir,
            @JsonProperty("identificador_android") String identificadorAndroid) {}

    /** O catálogo devolvido. */
    public record CatalogoResposta(
            @JsonProperty("servicos") List<ServicoResposta> servicos) {}

    /**
     * Lista os serviços ativos.
     *
     * @param categoria {@code sensivel} ou {@code cotidiano}; omitido, devolve
     *     as duas listas
     */
    @GetMapping("/catalogo")
    public CatalogoResposta listar(
            @RequestParam(required = false) String categoria) {

        List<ServicoConhecido> encontrados =
                categoria == null || categoria.isBlank()
                        ? servicos.findByAtivoTrueOrderByNomeExibido()
                        : servicos.findByCategoriaAndAtivoTrueOrderByNomeExibido(
                                categoriaDe(categoria));

        return new CatalogoResposta(encontrados.stream().map(this::corpoDe).toList());
    }

    /**
     * Traduz o parâmetro da URL.
     *
     * <p>Categoria desconhecida vira lista vazia, e não erro: a tela pediu algo
     * que o servidor não tem, e responder uma lista vazia é mais honesto do que
     * uma falha — não existe serviço daquela categoria mesmo.
     */
    private CategoriaDoServico categoriaDe(String valor) {
        return switch (valor.toLowerCase(Locale.ROOT)) {
            case "sensivel" -> CategoriaDoServico.SENSIVEL;
            case "cotidiano" -> CategoriaDoServico.COTIDIANO;
            default -> null;
        };
    }

    /**
     * Monta o corpo de um serviço.
     *
     * <p>{@code identificadorAndroid} sai apenas quando existe, e ele só existe
     * em serviço cotidiano. Serviço sensível chega ao aplicativo <b>sem o dado
     * necessário para abri-lo</b> — a FR-041 atravessa o contrato, e não só o
     * banco.
     */
    private ServicoResposta corpoDe(ServicoConhecido servico) {
        return new ServicoResposta(
                servico.getId(),
                servico.getChave(),
                servico.getNomeExibido(),
                servico.getDescricaoCurta(),
                servico.getCategoria().name().toLowerCase(Locale.ROOT),
                servico.podeSerAberto(),
                servico.getIdentificadorAndroid().orElse(null));
    }
}

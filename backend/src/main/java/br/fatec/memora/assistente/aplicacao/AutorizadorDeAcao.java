package br.fatec.memora.assistente.aplicacao;

import br.fatec.memora.assistente.dominio.ServicoConhecido;
import br.fatec.memora.assistente.infra.ClienteDaAssistente;
import br.fatec.memora.assistente.infra.RepositorioServicoConhecido;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Decide se uma sugestão da assistente vira ação (T014).
 *
 * <h2>Esta classe é o portão central da feature</h2>
 *
 * A FR-022 é literal: <i>"a validação do que pode ser executado MUST acontecer
 * fora do modelo de conversa, de forma determinística. A saída do modelo MUST
 * NOT ser a única autorização para agir."</i>
 *
 * <p>Aqui isso vira uma consulta ao banco. O modelo pode sugerir abrir o que
 * quiser — inclusive o aplicativo do banco, se alguém conseguir convencê-lo por
 * um texto colado no chat. A sugestão só vira ação se existir uma linha ativa e
 * cotidiana no catálogo.
 *
 * <p><b>Alguém pode convencer um modelo. Ninguém convence uma linha de
 * tabela.</b>
 *
 * <h2>Por que a recusa é silenciosa para a pessoa</h2>
 *
 * Sugestão recusada não vira aviso na tela. Dizer <i>"a Memora tentou abrir seu
 * banco e eu impedi"</i> assustaria quem não fez nada de errado, e ensinaria a
 * quem está tentando exatamente onde o limite está.
 *
 * <p>A recusa <b>não</b> é silenciosa para nós: ela vira {@code ACAO_RECUSADA}
 * na trilha, e uma sequência delas na mesma conta é o sinal que importa.
 *
 * <h2>O que esta classe deliberadamente não faz</h2>
 *
 * Não lê texto da resposta procurando intenção. Análise de prosa para decidir
 * segurança é frágil por natureza — e é justamente o que a FR-022 evita ao
 * exigir que a sugestão chegue estruturada.
 */
@Service
public class AutorizadorDeAcao {

    private final RepositorioServicoConhecido servicos;

    /** Cria o autorizador. */
    public AutorizadorDeAcao(RepositorioServicoConhecido servicos) {
        this.servicos = servicos;
    }

    /**
     * Converte uma sugestão em ação autorizada, ou em recusa.
     *
     * <p>Recusa quando o pacote não existe no catálogo, quando o serviço está
     * inativo, e quando ele é sensível — este último caso não chega a acontecer
     * por outro motivo: serviço sensível não tem pacote gravado, então a
     * consulta simplesmente não o encontra. A verificação explícita de
     * {@link ServicoConhecido#podeSerAberto()} permanece como segunda camada,
     * para o dia em que alguém afrouxar a restrição do banco.
     *
     * @param sugestao o que o modelo propôs, ou vazio se não propôs nada
     * @return a ação autorizada, ou vazio — e vazio significa <b>não faça</b>
     */
    @Transactional(readOnly = true)
    public Optional<AcaoAutorizada> autorizar(
            Optional<ClienteDaAssistente.Sugestao> sugestao) {

        if (sugestao.isEmpty()) {
            return Optional.empty();
        }

        String pacote = sugestao.get().identificadorAndroid();
        if (pacote == null || pacote.isBlank()) {
            return Optional.empty();
        }

        return servicos
                .findByIdentificadorAndroidAndAtivoTrue(pacote.strip())
                .filter(ServicoConhecido::podeSerAberto)
                .map(
                        servico ->
                                new AcaoAutorizada(
                                        servico.getId(),
                                        servico.getNomeExibido(),
                                        servico.getIdentificadorAndroid().orElseThrow()));
    }

    /**
     * Uma ação que <b>já passou</b> pelo catálogo.
     *
     * <p>A existência deste objeto é a autorização. O aplicativo não precisa, e
     * não deve, decidir de novo: duas decisões sobre a mesma coisa divergem na
     * primeira vez que alguém mexer em uma delas.
     *
     * <p>{@code identificadorAndroid} nunca é nulo aqui — serviço sensível não
     * chega a este ponto.
     */
    public record AcaoAutorizada(
            java.util.UUID servicoId, String nomeExibido, String identificadorAndroid) {
    }
}

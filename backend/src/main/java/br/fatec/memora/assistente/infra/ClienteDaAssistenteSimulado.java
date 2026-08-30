package br.fatec.memora.assistente.infra;

import java.util.Optional;
import java.util.function.Consumer;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Assistente de mentira, com roteiros fixos (T013).
 *
 * <h2>Não é um andaime — é ferramenta de teste de segurança</h2>
 *
 * A leitura óbvia é que este simulado existe só para trabalhar sem provedor
 * escolhido. Ele existe também, e principalmente, para <b>exercitar o portão da
 * FR-022</b>.
 *
 * <p>O cenário H3 do quickstart precisa que a assistente sugira abrir o
 * aplicativo do banco. Um modelo real, bem instruído, provavelmente <i>não</i>
 * sugeriria — e um teste que depende do modelo se comportar mal para provar que
 * a defesa funciona não prova nada. Aqui a sugestão maliciosa é produzida sob
 * comando, de forma determinística, quantas vezes for preciso.
 *
 * <p>É a diferença entre torcer para o portão ser testado e testá-lo.
 *
 * <h2>Restrito a desenvolvimento</h2>
 *
 * {@code @Profile("!producao")}, como o {@code EnviadorDeCodigoEmLog}. Com o
 * perfil {@code producao} este bean não existe, e sem um adaptador real a
 * aplicação <b>não sobe</b> — de propósito (R8). Subir sem provedor faria a
 * assistente responder erro a cada pergunta, e a falha apareceria para a pessoa
 * idosa em vez de para quem implanta.
 */
@Component
@Profile("!producao")
public class ClienteDaAssistenteSimulado implements ClienteDaAssistente {

    /** Resposta padrão, quando nada foi combinado para o teste. */
    static final String RESPOSTA_PADRAO =
            "Vamos com calma, um passo de cada vez. Primeiro, procure o "
                    + "quadradinho colorido na sua tela inicial 😊";

    private String proximoTexto = RESPOSTA_PADRAO;
    private Sugestao proximaSugestao;

    /**
     * Combina o texto da próxima resposta.
     *
     * @return este mesmo objeto, para encadear
     */
    public ClienteDaAssistenteSimulado responderCom(String texto) {
        this.proximoTexto = texto;
        return this;
    }

    /**
     * Faz a próxima resposta sugerir abrir um aplicativo.
     *
     * <p>Aceita <b>qualquer</b> pacote, inclusive de serviço sensível e
     * inclusive inexistente. Essa permissividade é o ponto: é assim que o teste
     * consegue simular tanto um modelo mal instruído quanto um modelo
     * comprometido por injeção de prompt.
     */
    public ClienteDaAssistenteSimulado sugerirAbrir(String identificadorAndroid) {
        this.proximaSugestao = new Sugestao(identificadorAndroid);
        return this;
    }

    /** Volta ao roteiro padrão, sem sugestão. */
    public ClienteDaAssistenteSimulado limpar() {
        this.proximoTexto = RESPOSTA_PADRAO;
        this.proximaSugestao = null;
        return this;
    }

    @Override
    public Resposta conversar(Pedido pedido, Consumer<String> aoReceberTrecho) {
        // Entrega em pedaços, como um provedor real entregaria: o controlador
        // e a tela precisam ser exercitados no modo em que vão funcionar, e não
        // num caminho especial que só existe no teste.
        for (String palavra : proximoTexto.split(" ")) {
            aoReceberTrecho.accept(palavra + " ");
        }
        return new Resposta(proximoTexto, Optional.ofNullable(proximaSugestao));
    }
}

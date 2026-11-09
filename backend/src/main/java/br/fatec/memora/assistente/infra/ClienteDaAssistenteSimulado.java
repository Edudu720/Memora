package br.fatec.memora.assistente.infra;

import java.util.Optional;
import java.util.function.Consumer;
import org.springframework.context.annotation.Conditional;
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
 *
 * <h2>E só existe quando é o provedor escolhido</h2>
 *
 * {@code @Conditional(ProvedorEscolhido.EhSimulado)}: com
 * {@code memora.assistente.provedor=gemini} este bean sai de cena e o adaptador
 * real entra no lugar (T064). Sem nada configurado — o caso de quem clona o
 * repositório e de todos os testes — continua sendo este.
 */
@Component
@Profile("!producao")
@Conditional(ProvedorEscolhido.EhSimulado.class)
public class ClienteDaAssistenteSimulado implements ClienteDaAssistente {

    /** Resposta padrão, quando nada foi combinado para o teste. */
    static final String RESPOSTA_PADRAO =
            "Vamos com calma, um passo de cada vez. Primeiro, procure o "
                    + "quadradinho colorido na sua tela inicial 😊";

    /** Resposta padrão de recusa financeira (T087, FR-018, FR-031, FR-037). */
    public static final String RECUSA_FINANCEIRA_PADRAO =
            "Não posso fazer transferências nem pagamentos. Eu sou um programa de computador feito "
                    + "para te ensinar a usar o celular com segurança, e por proteção do seu dinheiro eu nunca "
                    + "mexo com finanças nem com contas 😊";

    private String proximoTexto = RESPOSTA_PADRAO;
    private Sugestao proximaSugestao;
    private Pedido ultimoPedido;
    private AssistenteIndisponivel.Motivo proximaFalha;

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

    /**
     * Faz a assistente falhar como o provedor falharia (cota, 5xx, rede...).
     *
     * <p>Para provar o caminho de erro de ponta a ponta — o que a pessoa lê
     * quando o provedor cai — sem derrubar provedor nenhum.
     */
    public ClienteDaAssistenteSimulado falharCom(AssistenteIndisponivel.Motivo motivo) {
        this.proximaFalha = motivo;
        return this;
    }

    /** Volta ao roteiro padrão, sem sugestão. */
    public ClienteDaAssistenteSimulado limpar() {
        this.proximoTexto = RESPOSTA_PADRAO;
        this.proximaSugestao = null;
        this.ultimoPedido = null;
        this.proximaFalha = null;
        return this;
    }

    /**
     * O último pedido recebido, como o provedor o receberia.
     *
     * <p>Existe para o teste poder olhar o que viajaria ao modelo — o teto de
     * turnos e a ordem persona, catálogo, histórico (T065) — sem precisar de
     * rede.
     */
    public Pedido ultimoPedido() {
        return ultimoPedido;
    }

    @Override
    public Resposta conversar(Pedido pedido, Consumer<String> aoReceberTrecho) {
        this.ultimoPedido = pedido;
        if (proximaFalha != null) {
            // O texto que o provedor real traria nao existe aqui, e e de proposito:
            // a falha carrega so o motivo.
            throw new AssistenteIndisponivel(proximaFalha, null);
        }
        // Entrega em pedaços, como um provedor real entregaria: o controlador
        // e a tela precisam ser exercitados no modo em que vão funcionar, e não
        // num caminho especial que só existe no teste.
        String textoDevolvido = proximoTexto;
        Optional<Sugestao> sugestaoDevolvida = Optional.ofNullable(proximaSugestao);

        if (RESPOSTA_PADRAO.equals(proximoTexto) && proximaSugestao == null && ehPedidoFinanceiro(pedido)) {
            textoDevolvido = RECUSA_FINANCEIRA_PADRAO;
            sugestaoDevolvida = Optional.empty();
        }

        for (String palavra : textoDevolvido.split(" ")) {
            aoReceberTrecho.accept(palavra + " ");
        }
        return new Resposta(textoDevolvido, sugestaoDevolvida);
    }
    private static boolean ehPedidoFinanceiro(Pedido pedido) {
        if (pedido == null || pedido.mensagem() == null) {
            return false;
        }
        String texto = pedido.mensagem().toLowerCase(java.util.Locale.ROOT);
        return texto.contains("transfere")
                || texto.contains("transferir")
                || texto.contains("pix")
                || texto.contains("pagar")
                || texto.contains("r$")
                || texto.contains("apagar conta")
                || texto.contains("apagar dados");
    }
}
package br.fatec.memora.assistente.infra;

import java.util.List;
import java.util.Optional;
import java.util.function.Consumer;

/**
 * A porta por onde a assistente pensa (T012).
 *
 * <h2>Por que uma porta, e não a chamada direta a um provedor</h2>
 *
 * O provedor de IA <b>ainda não foi escolhido</b> (R2 do research). Esta
 * interface existe para que essa decisão não bloqueie a feature: todo o resto
 * do sistema conhece apenas este contrato, e o adaptador do provedor será a
 * única classe que importa o SDK dele.
 *
 * <p>A consequência prática é grande — Hub, catálogos, autorizador, trilha,
 * telas e todos os testes rodam contra {@link ClienteDaAssistenteSimulado}.
 *
 * <h2>A porta não decide nada</h2>
 *
 * Repare que {@link Resposta} carrega uma <b>sugestão</b>, e não uma ação. Quem
 * transforma sugestão em ação é o {@code AutorizadorDeAcao}, consultando o
 * catálogo — a FR-022. Nenhuma implementação desta porta, presente ou futura,
 * tem autoridade para autorizar coisa alguma.
 */
public interface ClienteDaAssistente {

    /**
     * Conversa com a assistente.
     *
     * @param pedido o que perguntar, com a persona e o catálogo já montados
     * @param aoReceberTrecho chamado a cada pedaço de texto, para o streaming
     *     que a SC-007 exige — o público do Memora é o que menos tolera tela
     *     parada
     * @return a resposta completa, com a sugestão se houver
     */
    Resposta conversar(Pedido pedido, Consumer<String> aoReceberTrecho);

    /**
     * O que se pergunta à assistente.
     *
     * @param persona a instrução de sistema, que a mensagem da pessoa
     *     <b>não</b> sobrescreve (FR-034)
     * @param catalogo os serviços que ela conhece, para não oferecer o que será
     *     recusado. É conveniência, <b>não</b> segurança: quem garante é o
     *     autorizador
     * @param historico a conversa até aqui, vinda do aparelho (FR-047)
     * @param mensagem o que a pessoa escreveu agora
     */
    record Pedido(
            String persona,
            String catalogo,
            List<Turno> historico,
            String mensagem) {
    }

    /** Um turno da conversa. */
    record Turno(Autor autor, String texto) {

        /** Quem falou. */
        public enum Autor {
            /** A pessoa. Conteúdo dela é <b>dado</b>, nunca instrução (FR-034). */
            PESSOA,
            /** A assistente. */
            MEMORA
        }
    }

    /**
     * O que a assistente respondeu.
     *
     * @param texto a resposta, já completa
     * @param sugestao o aplicativo que ela sugeriu abrir, se sugeriu.
     *     <b>Sugestão não é autorização</b> — ver {@code AutorizadorDeAcao}
     */
    record Resposta(String texto, Optional<Sugestao> sugestao) {

        /** Resposta sem sugestão de ação — o caso comum, e o desejável. */
        public static Resposta apenasTexto(String texto) {
            return new Resposta(texto, Optional.empty());
        }
    }

    /**
     * Um aplicativo que o modelo sugeriu abrir.
     *
     * <p>Identificado pelo pacote Android, que é como ele aparece no catálogo
     * enviado ao modelo. Que este pacote exista, esteja ativo e seja de um
     * serviço cotidiano é pergunta para o banco, não para a resposta.
     */
    record Sugestao(String identificadorAndroid) {
    }
}

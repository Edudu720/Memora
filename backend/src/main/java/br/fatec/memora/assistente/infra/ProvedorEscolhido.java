package br.fatec.memora.assistente.infra;

import java.util.Locale;
import org.springframework.context.annotation.Condition;
import org.springframework.context.annotation.ConditionContext;
import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.core.type.AnnotatedTypeMetadata;

/**
 * Quem responde pela assistente nesta execução (T064).
 *
 * <h2>Uma decisão só, tomada num lugar só</h2>
 *
 * O simulado e o adaptador do Gemini são beans mutuamente exclusivos, e a
 * exclusão não pode ser duas condições escritas separadas que "devem" concordar:
 * é assim que aparecem as duas ao mesmo tempo, ou nenhuma. As duas condições
 * abaixo perguntam à <b>mesma função</b>.
 *
 * <h2>As regras</h2>
 *
 * <ul>
 *   <li>Nada configurado: <b>simulado</b>. Quem clona o repositório, o CI e
 *       todos os testes seguem sem rede e sem chave.
 *   <li>{@code memora.assistente.provedor=gemini}: Gemini. Sem a chave, a
 *       subida falha (ver {@code ConfiguracaoDoProvedorDeIa}).
 *   <li><b>Perfil {@code producao}: sempre Gemini.</b> O simulado não existe lá
 *       (R8) e esta função recusa até quem pedir {@code simulado} de forma
 *       explícita — ignorar o pedido em silêncio deixaria a pessoa achar que o
 *       simulado está ligado, e responder com chamada real e gasto. Melhor
 *       derrubar a subida com a frase dizendo o porquê.
 *   <li>Valor desconhecido (um {@code gemni} digitado errado): falha na subida.
 *       Cair no simulado em silêncio é o pior desfecho possível — quem acredita
 *       estar testando o modelo real está falando com um roteiro fixo.
 * </ul>
 */
final class ProvedorEscolhido {

    /** A propriedade que escolhe, vinda de {@code MEMORA_ASSISTENTE_PROVEDOR}. */
    static final String PROPRIEDADE = "memora.assistente.provedor";

    /** Os adaptadores que existem. */
    enum Provedor {
        SIMULADO,
        GEMINI
    }

    private ProvedorEscolhido() {}

    /**
     * Resolve o provedor a partir do ambiente.
     *
     * @throws IllegalStateException para valor desconhecido, ou para
     *     {@code simulado} no perfil {@code producao}
     */
    static Provedor de(Environment ambiente) {
        boolean producao = ambiente.acceptsProfiles(Profiles.of("producao"));
        String pedido = ambiente.getProperty(PROPRIEDADE, "").strip().toLowerCase(Locale.ROOT);

        return switch (pedido) {
            case "" -> producao ? Provedor.GEMINI : Provedor.SIMULADO;
            case "simulado" -> {
                if (producao) {
                    throw new IllegalStateException(
                            "O perfil 'producao' nao admite o provedor 'simulado': ele responde "
                                    + "com roteiro fixo. Defina "
                                    + PROPRIEDADE
                                    + "=gemini (variavel MEMORA_ASSISTENTE_PROVEDOR) e GEMINI_API_KEY.");
                }
                yield Provedor.SIMULADO;
            }
            case "gemini" -> Provedor.GEMINI;
            default ->
                    throw new IllegalStateException(
                            "Provedor de IA desconhecido em "
                                    + PROPRIEDADE
                                    + ": '"
                                    + pedido
                                    + "'. Os validos sao 'simulado' (padrao fora de producao) e 'gemini'.");
        };
    }

    /** Verdadeira quando o adaptador do Gemini deve existir. */
    static class EhGemini implements Condition {
        @Override
        public boolean matches(ConditionContext contexto, AnnotatedTypeMetadata metadados) {
            return de(contexto.getEnvironment()) == Provedor.GEMINI;
        }
    }

    /** Verdadeira quando o simulado deve existir. */
    static class EhSimulado implements Condition {
        @Override
        public boolean matches(ConditionContext contexto, AnnotatedTypeMetadata metadados) {
            return de(contexto.getEnvironment()) == Provedor.SIMULADO;
        }
    }
}

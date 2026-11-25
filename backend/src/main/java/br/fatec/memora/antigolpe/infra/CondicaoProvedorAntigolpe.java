package br.fatec.memora.antigolpe.infra;

import java.util.Locale;
import org.springframework.context.annotation.Condition;
import org.springframework.context.annotation.ConditionContext;
import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.core.type.AnnotatedTypeMetadata;

/**
 * Seleciona o provedor de análise antigolpe espelhando as regras de {@code ProvedorEscolhido}.
 */
final class CondicaoProvedorAntigolpe {

    static final String PROPRIEDADE = "memora.assistente.provedor";

    enum Provedor {
        SIMULADO,
        GEMINI
    }

    private CondicaoProvedorAntigolpe() {}

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

    static class EhGemini implements Condition {
        @Override
        public boolean matches(ConditionContext contexto, AnnotatedTypeMetadata metadados) {
            return de(contexto.getEnvironment()) == Provedor.GEMINI;
        }
    }

    static class EhSimulado implements Condition {
        @Override
        public boolean matches(ConditionContext contexto, AnnotatedTypeMetadata metadados) {
            return de(contexto.getEnvironment()) == Provedor.SIMULADO;
        }
    }
}

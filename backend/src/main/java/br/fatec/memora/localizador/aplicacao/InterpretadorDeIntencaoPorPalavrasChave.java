package br.fatec.memora.localizador.aplicacao;

import br.fatec.memora.localizador.dominio.CategoriaServico;
import java.util.Locale;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Interpreta intenções expressas em linguagem natural pelo idoso usando
 * heurísticas determinísticas por palavras-chave (FR-003, FR-011).
 * Converte a necessidade em categoria e termos de busca no mapa sem chamadas a IA generativa.
 */
@Component
public class InterpretadorDeIntencaoPorPalavrasChave {

    private static final Logger LOG = LoggerFactory.getLogger(InterpretadorDeIntencaoPorPalavrasChave.class);

    public record IntencaoInterpretada(
            CategoriaServico categoria,
            String termoChave,
            String mensagemExplicativa) {}

    public IntencaoInterpretada interpretar(String consulta, CategoriaServico categoriaInformada) {
        if (consulta == null || consulta.trim().isBlank()) {
            CategoriaServico cat = categoriaInformada != null ? categoriaInformada : CategoriaServico.SAUDE;
            return new IntencaoInterpretada(
                    cat,
                    cat.getRotulo(),
                    "Buscando estabelecimentos de " + cat.getRotulo().toLowerCase() + " próximos a você");
        }

        String texto = consulta.toLowerCase(Locale.ROOT);
        LOG.debug("Classificando intenção local por palavras-chave para consulta de tamanho {}", texto.length());

        // 1. Emergência tem prioridade máxima absoluta
        if (contemQualquer(texto, "socorro", "ajuda", "urgente", "bombeiro", "bombeiros", "polícia", "policia", "samu", "ambulância", "ambulancia", "assalto", "fogo", "infarto", "avc")) {
            return new IntencaoInterpretada(
                    CategoriaServico.EMERGENCIA,
                    "emergência",
                    "Localizando prontos-socorros, SAMU e bombeiros mais próximos");
        }

        // 2. Saúde (vacina, posto, ubs, remédio, farmácia)
        if (contemQualquer(texto, "vacina", "posto", "ubs", "upa", "médico", "medico", "remédio", "remedio", "farmácia", "farmacia", "dor", "exame", "hospital", "pronto socorro")) {
            String termo = "posto de saúde";
            if (contemQualquer(texto, "farmácia", "farmacia", "remédio", "remedio")) {
                termo = "farmácia";
            }
            return new IntencaoInterpretada(
                    CategoriaServico.SAUDE,
                    termo,
                    "Buscando locais de saúde e " + termo + " próximos a você");
        }

        // 3. Serviços públicos ao cidadão
        if (contemQualquer(texto, "rg", "documento", "documentos", "poupatempo", "aposentadoria", "inss", "cras", "prefeitura", "certidão", "certidao")) {
            return new IntencaoInterpretada(
                    CategoriaServico.SERVICOS_PUBLICOS,
                    "serviços ao cidadão",
                    "Buscando serviços públicos e emissão de documentos próximos a você");
        }

        if (contemQualquer(texto, "banco", "dinheiro", "aposentadoria saque", "mercado", "supermercado", "correios", "encomenda", "lotérica", "loterica")) {
            String termo = "serviços cotidianos";
            if (contemQualquer(texto, "mercado", "supermercado")) termo = "supermercados";
            if (contemQualquer(texto, "banco", "lotérica", "loterica")) termo = "bancos e lotéricas";
            if (contemQualquer(texto, "correios")) termo = "correios";
            return new IntencaoInterpretada(
                    CategoriaServico.COTIDIANO,
                    termo,
                    "Buscando " + termo + " na região");
        }

        CategoriaServico cat = categoriaInformada != null ? categoriaInformada : CategoriaServico.SAUDE;
        return new IntencaoInterpretada(
                cat,
                consulta.trim(),
                "Pesquisando \"" + consulta.trim() + "\" em " + cat.getRotulo().toLowerCase());
    }

    private boolean contemQualquer(String texto, String... termos) {
        String textoNormalizado = " " + texto.replaceAll("[^a-záéíóúâêîôûãõç0-9]", " ") + " ";
        for (String termo : termos) {
            String termoNormalizado = termo.trim().toLowerCase(Locale.ROOT);
            if (termoNormalizado.length() <= 3) {
                // Para termos curtos (ex: "rg", "dor", "ubs", "upa"), busca como palavra isolada
                if (textoNormalizado.contains(" " + termoNormalizado + " ")) {
                    return true;
                }
            } else {
                if (texto.contains(termoNormalizado)) {
                    return true;
                }
            }
        }
        return false;
    }
}

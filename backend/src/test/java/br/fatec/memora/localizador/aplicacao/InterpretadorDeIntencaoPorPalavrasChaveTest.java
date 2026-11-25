package br.fatec.memora.localizador.aplicacao;

import static org.junit.jupiter.api.Assertions.*;

import br.fatec.memora.localizador.dominio.CategoriaServico;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class InterpretadorDeIntencaoPorPalavrasChaveTest {

    private final InterpretadorDeIntencaoPorPalavrasChave interpretador =
            new InterpretadorDeIntencaoPorPalavrasChave();

    @Test
    @DisplayName("Classifica intenção de saúde para consultas sobre vacina ou posto")
    void classificaSaude() {
        var res = interpretador.interpretar("onde tomo vacina da gripe?", null);
        assertEquals(CategoriaServico.SAUDE, res.categoria());
        assertTrue(res.mensagemExplicativa().contains("saúde") || res.mensagemExplicativa().contains("posto"));
    }

    @Test
    @DisplayName("Classifica intenção de serviços públicos para segunda via de RG ou aposentadoria")
    void classificaServicosPublicos() {
        var res = interpretador.interpretar("preciso tirar a 2 via do meu RG no poupatempo", null);
        assertEquals(CategoriaServico.SERVICOS_PUBLICOS, res.categoria());
        assertTrue(res.mensagemExplicativa().contains("serviços públicos"));
    }

    @Test
    @DisplayName("Classifica intenção de emergência para pedidos de socorro e bombeiros")
    void classificaEmergencia() {
        var res = interpretador.interpretar("socorro preciso de uma ambulância urgente", null);
        assertEquals(CategoriaServico.EMERGENCIA, res.categoria());
    }

    @Test
    @DisplayName("Classifica serviços cotidianos para banco, lotérica e correios")
    void classificaCotidiano() {
        var res = interpretador.interpretar("onde tem uma agência dos correios perto?", null);
        assertEquals(CategoriaServico.COTIDIANO, res.categoria());
    }
}

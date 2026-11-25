package br.fatec.memora.localizador.aplicacao;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import br.fatec.memora.localizador.api.dto.BuscarServicosRequest;
import br.fatec.memora.localizador.api.dto.BuscarServicosResponse;
import br.fatec.memora.localizador.dominio.CategoriaServico;
import br.fatec.memora.localizador.dominio.Endereco;
import br.fatec.memora.localizador.dominio.Estabelecimento;
import br.fatec.memora.localizador.dominio.FonteDados;
import br.fatec.memora.localizador.infra.ProvedorGeografico;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

class ServicoLocalizadorTest {

    private ProvedorGeografico provedorGeografico;
    private InterpretadorDeIntencaoPorPalavrasChave interpretadorIntencao;
    private ServicoLocalizador servicoLocalizador;

    @BeforeEach
    void setUp() {
        provedorGeografico = Mockito.mock(ProvedorGeografico.class);
        interpretadorIntencao = new InterpretadorDeIntencaoPorPalavrasChave();
        servicoLocalizador = new ServicoLocalizador(provedorGeografico, interpretadorIntencao);
    }

    @Test
    @DisplayName("Lança exceção quando não houver GPS nem região manual (AC-004)")
    void lancaExcecaoSemLocalizacao() {
        BuscarServicosRequest request = new BuscarServicosRequest(
                "Preciso de um médico",
                "SAUDE",
                null,
                null,
                5000);

        assertThrows(IllegalArgumentException.class, () -> servicoLocalizador.buscar(request));
    }

    @Test
    @DisplayName("Ordena estabelecimentos por proximidade física geodésica")
    void ordenaPorProximidade() {
        Estabelecimento maisLonge = new Estabelecimento(
                "id:longe",
                "Hospital Estadual de Sumaré",
                CategoriaServico.SAUDE,
                "Hospital",
                new Endereco("Av da Amizade", "2400", "Vila Nova", "Sumaré", "SP", "13175-490", "Av da Amizade, 2400"),
                -22.8200,
                -47.2700,
                null,
                null,
                "(19) 3883-8900",
                "24h",
                true,
                FonteDados.MINISTERIO_DA_SAUDE,
                null);

        Estabelecimento maisPerto = new Estabelecimento(
                "id:perto",
                "UBS Centro Americana",
                CategoriaServico.SAUDE,
                "Posto de Saúde",
                new Endereco("Rua Rui Barbosa", "100", "Centro", "Americana", "SP", "13465-000", "Rua Rui Barbosa, 100"),
                -22.7390,
                -47.3320,
                null,
                null,
                "(19) 3461-0000",
                "07h às 17h",
                true,
                FonteDados.MINISTERIO_DA_SAUDE,
                null);

        when(provedorGeografico.buscarPorCoordenadas(anyDouble(), anyDouble(), anyInt(), any(), any()))
                .thenReturn(List.of(maisLonge, maisPerto));

        BuscarServicosRequest request = new BuscarServicosRequest(
                "onde tomo vacina",
                "SAUDE",
                new BuscarServicosRequest.CoordenadaRequest(-22.7388, -47.3325),
                null,
                5000);

        BuscarServicosResponse response = servicoLocalizador.buscar(request);

        assertNotNull(response);
        assertEquals(2, response.totalEncontrado());
        assertEquals("UBS Centro Americana", response.estabelecimentos().get(0).nome());
        assertEquals("Hospital Estadual de Sumaré", response.estabelecimentos().get(1).nome());
        assertTrue(response.estabelecimentos().get(0).distanciaMetros() < response.estabelecimentos().get(1).distanciaMetros());
    }

    @Test
    @DisplayName("Suporta busca manual com geocodificação sem acesso ao GPS")
    void buscaManualSemGps() {
        when(provedorGeografico.geocodificarRegiao("Centro, Americana SP"))
                .thenReturn(new ProvedorGeografico.CoordenadasGeo(-22.7388, -47.3325, "Centro, Americana - SP"));

        when(provedorGeografico.buscarPorCoordenadas(anyDouble(), anyDouble(), anyInt(), any(), any()))
                .thenReturn(List.of());

        BuscarServicosRequest request = new BuscarServicosRequest(
                null,
                "SERVICOS_PUBLICOS",
                null,
                "Centro, Americana SP",
                5000);

        BuscarServicosResponse response = servicoLocalizador.buscar(request);

        assertNotNull(response);
        assertEquals("REGIAO_MANUAL", response.regiaoOrigem().modo());
        assertEquals("Centro, Americana - SP", response.regiaoOrigem().descricao());
    }

    @Test
    @DisplayName("Prioriza regiaoManual quando o usuario altera a regiao mesmo com coordenadas GPS anteriores")
    void priorizaRegiaoManualSobreCoordenadasGps() {
        when(provedorGeografico.geocodificarRegiao("Americana, Centro"))
                .thenReturn(new ProvedorGeografico.CoordenadasGeo(-22.7403, -47.3305, "Centro, Americana - SP"));
        when(provedorGeografico.buscarPorCoordenadas(anyDouble(), anyDouble(), anyInt(), any(), any()))
                .thenReturn(List.of());

        BuscarServicosRequest request = new BuscarServicosRequest(
                null,
                "SAUDE",
                new BuscarServicosRequest.CoordenadaRequest(-23.5505, -46.6333),
                "Americana, Centro",
                5000);

        BuscarServicosResponse response = servicoLocalizador.buscar(request);

        assertEquals("REGIAO_MANUAL", response.regiaoOrigem().modo());
        assertEquals("Centro, Americana - SP", response.regiaoOrigem().descricao());
        assertEquals(-22.7403, response.regiaoOrigem().latitude(), 0.0001);
        verify(provedorGeografico).geocodificarRegiao("Americana, Centro");
    }
}

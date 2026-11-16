package br.fatec.memora.localizador.api.dto;

import br.fatec.memora.localizador.dominio.CategoriaServico;
import br.fatec.memora.localizador.dominio.Endereco;
import br.fatec.memora.localizador.dominio.Estabelecimento;
import br.fatec.memora.localizador.dominio.FonteDados;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

/**
 * Contrato de saída com estabelecimentos normalizados e metadados transparentes.
 */
public record BuscarServicosResponse(
        @JsonProperty("consultaInterpretada")
        ConsultaInterpretadaDto consultaInterpretada,

        @JsonProperty("regiaoOrigem")
        RegiaoOrigemDto regiaoOrigem,

        @JsonProperty("totalEncontrado")
        int totalEncontrado,

        @JsonProperty("estabelecimentos")
        List<EstabelecimentoDto> estabelecimentos) {

    public record ConsultaInterpretadaDto(
            @JsonProperty("categoriaIdentificada") String categoriaIdentificada,
            @JsonProperty("termoChave") String termoChave,
            @JsonProperty("mensagemExplicativa") String mensagemExplicativa) {}

    public record RegiaoOrigemDto(
            @JsonProperty("descricao") String descricao,
            @JsonProperty("latitude") Double latitude,
            @JsonProperty("longitude") Double longitude,
            @JsonProperty("modo") String modo) {}

    public record EstabelecimentoDto(
            @JsonProperty("id") String id,
            @JsonProperty("nome") String nome,
            @JsonProperty("categoria") String categoria,
            @JsonProperty("subtituloTipo") String subtituloTipo,
            @JsonProperty("endereco") EnderecoDto endereco,
            @JsonProperty("latitude") Double latitude,
            @JsonProperty("longitude") Double longitude,
            @JsonProperty("distanciaMetros") Double distanciaMetros,
            @JsonProperty("distanciaFormatada") String distanciaFormatada,
            @JsonProperty("telefone") String telefone,
            @JsonProperty("horarioFuncionamento") String horarioFuncionamento,
            @JsonProperty("horarioConfirmado") boolean horarioConfirmado,
            @JsonProperty("fonte") String fonte,
            @JsonProperty("avisoTransparencia") String avisoTransparencia) {

        public static EstabelecimentoDto deDominio(Estabelecimento e) {
            EnderecoDto endDto = null;
            if (e.endereco() != null) {
                endDto = new EnderecoDto(
                        e.endereco().logradouro(),
                        e.endereco().numero(),
                        e.endereco().bairro(),
                        e.endereco().cidade(),
                        e.endereco().estado(),
                        e.endereco().cep(),
                        e.endereco().textoFormatado());
            }
            return new EstabelecimentoDto(
                    e.id(),
                    e.nome(),
                    e.categoria() != null ? e.categoria().name() : null,
                    e.subtituloTipo(),
                    endDto,
                    e.latitude(),
                    e.longitude(),
                    e.distanciaMetros(),
                    e.distanciaFormatada(),
                    e.telefone(),
                    e.horarioFuncionamento(),
                    e.horarioConfirmado(),
                    e.fonte() != null ? e.fonte().name() : FonteDados.OPEN_STREET_MAP.name(),
                    e.avisoTransparencia());
        }
    }

    public record EnderecoDto(
            @JsonProperty("logradouro") String logradouro,
            @JsonProperty("numero") String numero,
            @JsonProperty("bairro") String bairro,
            @JsonProperty("cidade") String cidade,
            @JsonProperty("estado") String estado,
            @JsonProperty("cep") String cep,
            @JsonProperty("textoFormatado") String textoFormatado) {}
}

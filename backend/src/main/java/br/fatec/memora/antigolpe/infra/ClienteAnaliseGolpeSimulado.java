package br.fatec.memora.antigolpe.infra;

import br.fatec.memora.antigolpe.aplicacao.AnalisadorDeterministicoDeGolpes;
import br.fatec.memora.antigolpe.dominio.ResultadoAnaliseGolpe;
import org.springframework.context.annotation.Conditional;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Adaptador simulado para execução local e testes sem chave de API nem chamadas externas.
 */
@Component
@Profile("!producao")
@Conditional(CondicaoProvedorAntigolpe.EhSimulado.class)
public class ClienteAnaliseGolpeSimulado implements ClienteAnaliseGolpe {

    private final AnalisadorDeterministicoDeGolpes analisador;

    public ClienteAnaliseGolpeSimulado(AnalisadorDeterministicoDeGolpes analisador) {
        this.analisador = analisador;
    }

    @Override
    public ResultadoAnaliseGolpe analisar(String conteudo) {
        ResultadoAnaliseGolpe resultado = analisador.analisar(conteudo);
        return new ResultadoAnaliseGolpe(
                resultado.risco(),
                resultado.titulo(),
                resultado.explicacao(),
                resultado.orientacoes(),
                resultado.sinaisDetectados(),
                false);
    }
}

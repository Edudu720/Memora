package br.fatec.memora.antigolpe.aplicacao;

import br.fatec.memora.antigolpe.api.dto.AnalisarGolpeResponse;
import br.fatec.memora.antigolpe.aplicacao.AnalisadorDeterministicoDeGolpes.AnalisePrevia;
import br.fatec.memora.antigolpe.dominio.ResultadoAnaliseGolpe;
import br.fatec.memora.antigolpe.infra.ClienteAnaliseGolpe;
import br.fatec.memora.antigolpe.seguranca.LimitadorAnaliseGolpe;
import br.fatec.memora.assistente.infra.AssistenteIndisponivel;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Caso de uso de análise de mensagens e links suspeitos contra golpes.
 *
 * <p>Executa o limitador por conta antes da chamada à IA, realiza pré-verificação determinística,
 * consulta o provedor configurado (enviando apenas o conteúdo colado, sem dados pessoais), aplica
 * fallback determinístico em indisponibilidade da IA e higieniza a resposta final antes de devolver
 * ao cliente. Nenhum conteúdo analisado é persistido ou registrado em log.
 */
@Service
public class ServicoAnaliseGolpe {

    private static final Logger LOG = LoggerFactory.getLogger(ServicoAnaliseGolpe.class);

    private final LimitadorAnaliseGolpe limitador;
    private final AnalisadorDeterministicoDeGolpes analisadorDeterministico;
    private final SanitizadorRespostaAntigolpe sanitizador;
    private final ClienteAnaliseGolpe clienteAnalise;

    public ServicoAnaliseGolpe(
            LimitadorAnaliseGolpe limitador,
            AnalisadorDeterministicoDeGolpes analisadorDeterministico,
            SanitizadorRespostaAntigolpe sanitizador,
            ClienteAnaliseGolpe clienteAnalise) {
        this.limitador = limitador;
        this.analisadorDeterministico = analisadorDeterministico;
        this.sanitizador = sanitizador;
        this.clienteAnalise = clienteAnalise;
    }

    public AnalisarGolpeResponse analisar(UUID pessoaId, String conteudo) {
        limitador.verificarERegistrar(pessoaId);

        AnalisePrevia preCheck = analisadorDeterministico.analisarComDetalhe(conteudo);

        ResultadoAnaliseGolpe resultadoProvedor;
        try {
            resultadoProvedor = clienteAnalise.analisar(conteudo);
        } catch (AssistenteIndisponivel indisponivel) {
            LOG.warn(
                    "Analise antigolpe usando fallback deterministico: {}",
                    indisponivel.motivo());
            resultadoProvedor = preCheck.resultado();
        }

        ResultadoAnaliseGolpe finalSanitizado =
                sanitizador.sanitizar(preCheck, resultadoProvedor);

        return new AnalisarGolpeResponse(
                finalSanitizado.risco(),
                finalSanitizado.titulo(),
                finalSanitizado.explicacao(),
                finalSanitizado.orientacoes(),
                finalSanitizado.sinaisDetectados(),
                finalSanitizado.analisadoPorIa());
    }
}

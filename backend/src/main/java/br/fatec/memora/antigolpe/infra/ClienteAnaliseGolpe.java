package br.fatec.memora.antigolpe.infra;

import br.fatec.memora.antigolpe.dominio.ResultadoAnaliseGolpe;

/**
 * Porta de saída para análise de golpes por IA ou modo simulado.
 *
 * <p>Recebe exclusivamente o conteúdo colado pela pessoa, garantindo estruturalmente que nenhum dado
 * pessoal de conta (nome, e-mail, telefone ou identificador) chegue ao provedor externo.
 */
public interface ClienteAnaliseGolpe {

    ResultadoAnaliseGolpe analisar(String conteudo);
}

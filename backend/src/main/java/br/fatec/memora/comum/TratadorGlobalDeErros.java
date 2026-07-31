package br.fatec.memora.comum;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.HandlerMethodValidationException;

/**
 * Converte qualquer exceção em resposta do contrato (T024, FR-041).
 *
 * <h2>A regra que sustenta a FR-041</h2>
 *
 * <b>Nenhum texto vindo de exceção que não seja nossa chega à resposta.</b> Só
 * {@link FalhaDoMemora} tem sua mensagem copiada para o corpo, porque só ela
 * carrega texto que alguém escreveu deliberadamente para ser lido por uma
 * pessoa. De todo o resto sai o texto padrão do {@link CodigoDeErro}.
 *
 * <p>A diferença aparece no caso que importa. Uma
 * {@code DataIntegrityViolationException} do Hibernate traz, na mensagem, o nome
 * da constraint e da tabela — {@code uq_canal_tipo_valor}. Repassá-la contaria
 * ao mundo como o banco é organizado e, pior, revelaria que aquele canal já
 * pertence a alguém, derrubando a FR-010 por um caminho lateral. Aqui ela vira
 * {@code ERRO_INESPERADO} genérico, e o detalhe fica no log.
 *
 * <h2>Detalhe não some, muda de lugar</h2>
 *
 * Toda falha inesperada é registrada com a exceção completa. Como o
 * {@link FiltroRastreio} colocou Trace ID e Request ID no MDC, a linha de log
 * carrega os dois: quem investiga parte do identificador que o aplicativo tem em
 * mãos e chega à causa, sem que nada disso tenha trafegado até o aparelho.
 *
 * <h2>Por que erro de validação não detalha o campo</h2>
 *
 * Seria natural devolver "campo senha: tamanho mínimo 10". Não devolvemos, por
 * dois motivos. O texto que o Jakarta Validation gera é técnico e em inglês —
 * jargão que este público não lê. E enumerar campo a campo o que o servidor
 * espera entrega o formato interno da requisição a quem estiver sondando. A
 * orientação específica de preenchimento é responsabilidade da tela, que valida
 * antes de enviar; o servidor revalida por autoridade (FR-038), não para ensinar.
 */
@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE)
public class TratadorGlobalDeErros {

    private static final Logger LOG = LoggerFactory.getLogger(TratadorGlobalDeErros.class);

    /** Falha prevista: já vem com código, status e texto próprios. */
    @ExceptionHandler(FalhaDoMemora.class)
    public ResponseEntity<Erro> tratarFalhaPrevista(FalhaDoMemora falha) {
        // Sem stack trace: não é defeito, é o sistema funcionando. Registrado
        // para que picos de recusa continuem observáveis.
        LOG.info("Falha prevista: {}", falha.getCodigo());

        return ResponseEntity.status(falha.getCodigo().status())
                .body(falha.paraCorpoDeResposta());
    }

    /** Corpo da requisição reprovado pelo Jakarta Validation. */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Erro> tratarCorpoInvalido(MethodArgumentNotValidException excecao) {
        LOG.info("Requisição reprovada na validação: {} violação(ões)", excecao.getErrorCount());
        return respostaPadrao(CodigoDeErro.DADOS_INVALIDOS);
    }

    /** Parâmetro de método reprovado na validação. */
    @ExceptionHandler(HandlerMethodValidationException.class)
    public ResponseEntity<Erro> tratarParametroInvalido(HandlerMethodValidationException excecao) {
        LOG.info("Parâmetro reprovado na validação: {} violação(ões)", excecao.getAllErrors().size());
        return respostaPadrao(CodigoDeErro.DADOS_INVALIDOS);
    }

    /**
     * JSON malformado, ausente ou com tipo incompatível.
     *
     * <p>Tratado como dado inválido, e não como erro inesperado: a mensagem
     * original diz em que posição do JSON o parser tropeçou e qual classe Java
     * esperava — descrição do formato interno, que não sai daqui.
     */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Erro> tratarCorpoIlegivel(HttpMessageNotReadableException excecao) {
        LOG.info("Corpo da requisição ilegível");
        return respostaPadrao(CodigoDeErro.DADOS_INVALIDOS);
    }

    /**
     * Rede de segurança: tudo que não foi previsto.
     *
     * <p>É o handler mais importante desta classe. Sem ele, a exceção subiria
     * para o tratamento padrão do Spring, cuja resposta inclui caminho da
     * requisição e, conforme a configuração, a mensagem da exceção.
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Erro> tratarFalhaInesperada(Exception excecao) {
        // Único lugar do sistema que registra exceção com stack trace. O Trace
        // ID vem junto pelo MDC.
        LOG.error("Falha inesperada ao processar a requisição", excecao);
        return respostaPadrao(CodigoDeErro.ERRO_INESPERADO);
    }

    private ResponseEntity<Erro> respostaPadrao(CodigoDeErro codigo) {
        return ResponseEntity.status(codigo.status())
                .body(Erro.de(codigo, codigo.mensagemPadrao()));
    }
}

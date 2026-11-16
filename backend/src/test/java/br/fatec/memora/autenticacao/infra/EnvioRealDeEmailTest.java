package br.fatec.memora.autenticacao.infra;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import br.fatec.memora.autenticacao.dominio.CanalContato;
import br.fatec.memora.autenticacao.dominio.TipoDeCanal;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import java.io.InputStream;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.mail.MailException;
import org.springframework.mail.MailSendException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessagePreparator;

/**
 * Testes unitários para os adaptadores SMTP de produção
 * ({@link EnviadorDeCodigoPorEmail} e {@link NotificadorDeContaPorEmail})
 * (T065a, T068; FR-008 a FR-011 da Feature 006).
 */
@DisplayName("T065a / T068 — envio real de código e avisos por e-mail em produção")
class EnvioRealDeEmailTest {

    private static final String HOST_SMTP = "smtp.memora.app";
    private static final String REMETENTE = "nao-responda@memora.app";
    private static final String CODIGO_SECRETO = "849201";

    private CarteiroEmMemoria carteiro;
    private ListAppender<ILoggingEvent> gravadorDeLog;
    private Logger loggerEnviador;
    private Logger loggerNotificador;

    @BeforeEach
    void preparar() {
        carteiro = new CarteiroEmMemoria();
        gravadorDeLog = new ListAppender<>();
        gravadorDeLog.start();

        loggerEnviador = (Logger) LoggerFactory.getLogger(EnviadorDeCodigoPorEmail.class);
        loggerNotificador = (Logger) LoggerFactory.getLogger(NotificadorDeContaPorEmail.class);
        loggerEnviador.addAppender(gravadorDeLog);
        loggerNotificador.addAppender(gravadorDeLog);
    }

    @AfterEach
    void desmontar() {
        loggerEnviador.detachAppender(gravadorDeLog);
        loggerNotificador.detachAppender(gravadorDeLog);
        gravadorDeLog.stop();
    }

    @Test
    @DisplayName(
            "EnviadorDeCodigoPorEmail envia mensagem SMTP sem links clicáveis e jamais registra o código em log")
    void enviadorDeCodigoEnviaEmailSemLinksESemVazarCodigoNoLog() {
        EnviadorDeCodigoPorEmail enviador =
                new EnviadorDeCodigoPorEmail(carteiro, HOST_SMTP, REMETENTE);
        enviador.validarConfiguracao();

        CanalContato canal =
                new CanalContato(
                        UUID.randomUUID(),
                        TipoDeCanal.EMAIL,
                        "dona.ana@gmail.com",
                        "hash-email",
                        false,
                        Instant.now());

        enviador.enviar(canal, CODIGO_SECRETO);

        assertThat(carteiro.enviadas).hasSize(1);
        SimpleMailMessage mensagem = carteiro.enviadas.getFirst();
        assertThat(mensagem.getFrom()).isEqualTo(REMETENTE);
        assertThat(mensagem.getTo()).containsExactly("dona.ana@gmail.com");
        assertThat(mensagem.getSubject()).contains("Memora");
        assertThat(mensagem.getText())
                .contains(CODIGO_SECRETO)
                .contains("10 minutos")
                .doesNotContain("http://")
                .doesNotContain("https://")
                .doesNotContain("www.");

        assertThat(mensagensDeLog())
                .allSatisfy(linha -> assertThat(linha).doesNotContain(CODIGO_SECRETO));
    }

    @Test
    @DisplayName(
            "NotificadorDeContaPorEmail envia aviso de senha alterada na voz da Memora sem links")
    void notificadorDeContaEnviaAvisoSemLinksComNomeDeTratamento() {
        NotificadorDeContaPorEmail notificador =
                new NotificadorDeContaPorEmail(carteiro, HOST_SMTP, REMETENTE);
        notificador.validarConfiguracao();

        CanalContato canal =
                new CanalContato(
                        UUID.randomUUID(),
                        TipoDeCanal.EMAIL,
                        "dona.ana@gmail.com",
                        "hash-email",
                        true,
                        Instant.now());

        notificador.avisarSenhaAlterada(canal, "Dona Ana");

        assertThat(carteiro.enviadas).hasSize(1);
        SimpleMailMessage mensagem = carteiro.enviadas.getFirst();
        assertThat(mensagem.getFrom()).isEqualTo(REMETENTE);
        assertThat(mensagem.getTo()).containsExactly("dona.ana@gmail.com");
        assertThat(mensagem.getSubject()).contains("senha");
        assertThat(mensagem.getText())
                .contains("Olá, Dona Ana!")
                .contains("Esqueci minha senha")
                .doesNotContain("http://")
                .doesNotContain("https://")
                .doesNotContain("www.");
    }

    @Test
    @DisplayName(
            "validação fail-fast interrompe a inicialização no perfil producao se host SMTP ou remetente estiverem vazios")
    void falhaRapidoQuandoConfiguracaoSmtpIncompleta() {
        assertThatThrownBy(
                        () ->
                                new EnviadorDeCodigoPorEmail(carteiro, "", REMETENTE)
                                        .validarConfiguracao())
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("spring.mail.host");

        assertThatThrownBy(
                        () ->
                                new EnviadorDeCodigoPorEmail(carteiro, HOST_SMTP, "   ")
                                        .validarConfiguracao())
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("memora.email.remetente");

        assertThatThrownBy(
                        () ->
                                new NotificadorDeContaPorEmail(carteiro, " ", REMETENTE)
                                        .validarConfiguracao())
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("spring.mail.host");

        assertThatThrownBy(
                        () ->
                                new NotificadorDeContaPorEmail(carteiro, HOST_SMTP, "")
                                        .validarConfiguracao())
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("memora.email.remetente");
    }

    @Test
    @DisplayName(
            "canais TELEFONE e falhas transitórias de rede SMTP são tratados sem expor código em claro")
    void trataCanalTelefoneEFalhaDeRedeSemExporCodigo() {
        EnviadorDeCodigoPorEmail enviador =
                new EnviadorDeCodigoPorEmail(carteiro, HOST_SMTP, REMETENTE);
        NotificadorDeContaPorEmail notificador =
                new NotificadorDeContaPorEmail(carteiro, HOST_SMTP, REMETENTE);

        CanalContato telefone =
                new CanalContato(
                        UUID.randomUUID(),
                        TipoDeCanal.TELEFONE,
                        "+5511999998888",
                        "hash-tel",
                        false,
                        Instant.now());

        enviador.enviar(telefone, CODIGO_SECRETO);
        notificador.avisarSenhaAlterada(telefone, "Dona Ana");
        assertThat(carteiro.enviadas).isEmpty();

        carteiro.falharCom = new MailSendException("Timeout simulado ao conectar ao servidor SMTP");
        CanalContato email =
                new CanalContato(
                        UUID.randomUUID(),
                        TipoDeCanal.EMAIL,
                        "dona.ana@gmail.com",
                        "hash-email",
                        false,
                        Instant.now());

        enviador.enviar(email, CODIGO_SECRETO);
        notificador.avisarSenhaAlterada(email, "Dona Ana");

        assertThat(mensagensDeLog())
                .allSatisfy(linha -> assertThat(linha).doesNotContain(CODIGO_SECRETO));
    }

    private List<String> mensagensDeLog() {
        return gravadorDeLog.list.stream().map(ILoggingEvent::getFormattedMessage).toList();
    }

    private static final class CarteiroEmMemoria implements JavaMailSender {

        final List<SimpleMailMessage> enviadas = new ArrayList<>();
        MailException falharCom;

        @Override
        public void send(SimpleMailMessage simpleMessage) throws MailException {
            if (falharCom != null) {
                throw falharCom;
            }
            enviadas.add(simpleMessage);
        }

        @Override
        public void send(SimpleMailMessage... simpleMessages) throws MailException {
            for (SimpleMailMessage m : simpleMessages) {
                send(m);
            }
        }

        @Override
        public MimeMessage createMimeMessage() {
            return new MimeMessage(Session.getDefaultInstance(new Properties()));
        }

        @Override
        public MimeMessage createMimeMessage(InputStream contentStream) throws MailException {
            throw new UnsupportedOperationException();
        }

        @Override
        public void send(MimeMessage mimeMessage) throws MailException {
            throw new UnsupportedOperationException();
        }

        @Override
        public void send(MimeMessage... mimeMessages) throws MailException {
            throw new UnsupportedOperationException();
        }

        @Override
        public void send(MimeMessagePreparator mimeMessagePreparator) throws MailException {
            throw new UnsupportedOperationException();
        }

        @Override
        public void send(MimeMessagePreparator... mimeMessagePreparators) throws MailException {
            throw new UnsupportedOperationException();
        }
    }
}

package br.fatec.memora.autenticacao.infra;

import br.fatec.memora.autenticacao.aplicacao.EnviadorDeCodigo;
import br.fatec.memora.autenticacao.dominio.CanalContato;
import br.fatec.memora.autenticacao.dominio.TipoDeCanal;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

/**
 * Adaptador real de produção para entrega de código de verificação por e-mail
 * via SMTP padrão (T065a, FR-008 a FR-011 da Feature 006).
 *
 * <h2>Regras inegociáveis de segurança e linguagem</h2>
 *
 * <ul>
 *   <li><b>Fail-fast na subida</b> ({@link #validarConfiguracao()}): no perfil
 *       {@code producao}, a ausência de {@code spring.mail.host} ou de
 *       {@code memora.email.remetente} interrompe imediatamente a inicialização
 *       com mensagem diagnóstica clara.
 *   <li><b>Zero código em log</b> (FR-011): {@code codigoEmClaro} jamais aparece
 *       em chamadas de log ({@code INFO}, {@code WARN}, {@code ERROR} ou
 *       {@code DEBUG}) nem em mensagens de exceção.
 *   <li><b>Zero links clicáveis</b> (FR-009, Constituição §V): o texto é escrito
 *       na voz da Memora, com os 6 dígitos em destaque e aviso explícito de que
 *       a Memora nunca pede senha nem envia links.
 * </ul>
 */
@Component
@Profile("producao")
public class EnviadorDeCodigoPorEmail implements EnviadorDeCodigo {

    private static final Logger LOG = LoggerFactory.getLogger(EnviadorDeCodigoPorEmail.class);

    private final JavaMailSender carteiro;
    private final String hostSmtp;
    private final String remetente;

    public EnviadorDeCodigoPorEmail(
            JavaMailSender carteiro,
            @Value("${spring.mail.host:}") String hostSmtp,
            @Value("${memora.email.remetente:}") String remetente) {
        this.carteiro = carteiro;
        this.hostSmtp = hostSmtp;
        this.remetente = remetente;
    }

    @PostConstruct
    public void validarConfiguracao() {
        if (hostSmtp == null || hostSmtp.isBlank()) {
            throw new IllegalStateException(
                    "Perfil 'producao' exige servidor SMTP configurado em 'spring.mail.host' "
                            + "(variavel SPRING_MAIL_HOST) para enviar codigos de verificacao.");
        }
        if (remetente == null || remetente.isBlank()) {
            throw new IllegalStateException(
                    "Perfil 'producao' exige endereco de remetente configurado em "
                            + "'memora.email.remetente' (variavel MEMORA_EMAIL_REMETENTE ou "
                            + "SPRING_MAIL_USERNAME).");
        }
    }

    @Override
    public void enviar(CanalContato canal, String codigoEmClaro) {
        if (canal.getTipo() == TipoDeCanal.TELEFONE) {
            LOG.warn(
                    "Solicitado envio de codigo para canal TELEFONE ({}), mas apenas o "
                            + "adaptador SMTP de e-mail esta ativo no perfil 'producao'.",
                    canal.getId());
            return;
        }

        SimpleMailMessage mensagem = new SimpleMailMessage();
        mensagem.setFrom(remetente.trim());
        mensagem.setTo(canal.getValor());
        mensagem.setSubject("Seu código de 6 números da Memora");
        mensagem.setText(montarCorpoSemLinks(codigoEmClaro));

        try {
            carteiro.send(mensagem);
            LOG.info("Codigo de verificacao enviado por e-mail para o canal {}.", canal.getId());
        } catch (MailException falha) {
            LOG.error(
                    "Falha ao enviar e-mail de codigo para o canal {} (motivo: {}).",
                    canal.getId(),
                    falha.getClass().getSimpleName());
        }
    }

    static String montarCorpoSemLinks(String codigoEmClaro) {
        return """
                Olá! Aqui é a Memora.

                O seu código de 6 números é:

                %s

                Este código vale por 10 minutos. Digite esses 6 números na tela do aplicativo Memora no seu celular.

                Se você não pediu este código, não precisa fazer nada: basta apagar esta mensagem.
                Lembre-se: a Memora nunca pede a sua senha e nunca envia links para você tocar.
                """
                .formatted(codigoEmClaro);
    }
}

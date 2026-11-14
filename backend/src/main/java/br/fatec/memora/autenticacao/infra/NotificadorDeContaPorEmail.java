package br.fatec.memora.autenticacao.infra;

import br.fatec.memora.autenticacao.aplicacao.NotificadorDeConta;
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
 * Adaptador real de produção para aviso de alteração de senha por e-mail via
 * SMTP padrão (T068, FR-022 da Feature 001; FR-008 a FR-011 da Feature 006).
 *
 * <p>Segue as mesmas garantias de {@link EnviadorDeCodigoPorEmail}: validação
 * <i>fail-fast</i> na inicialização do perfil {@code producao}, linguagem
 * acolhedora na voz da Memora e ausência total de links clicáveis para não
 * acostumar a pessoa usuária a tocar em links recebidos por mensagem.
 */
@Component
@Profile("producao")
public class NotificadorDeContaPorEmail implements NotificadorDeConta {

    private static final Logger LOG = LoggerFactory.getLogger(NotificadorDeContaPorEmail.class);

    private final JavaMailSender carteiro;
    private final String hostSmtp;
    private final String remetente;

    public NotificadorDeContaPorEmail(
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
                            + "(variavel SPRING_MAIL_HOST) para enviar avisos de seguranca da conta.");
        }
        if (remetente == null || remetente.isBlank()) {
            throw new IllegalStateException(
                    "Perfil 'producao' exige endereco de remetente configurado em "
                            + "'memora.email.remetente' (variavel MEMORA_EMAIL_REMETENTE ou "
                            + "SPRING_MAIL_USERNAME).");
        }
    }

    @Override
    public void avisarSenhaAlterada(CanalContato canal, String nomeTratamento) {
        if (canal.getTipo() == TipoDeCanal.TELEFONE) {
            LOG.warn(
                    "Solicitado aviso de senha alterada para canal TELEFONE ({}), mas apenas o "
                            + "adaptador SMTP de e-mail esta ativo no perfil 'producao'.",
                    canal.getId());
            return;
        }

        SimpleMailMessage mensagem = new SimpleMailMessage();
        mensagem.setFrom(remetente.trim());
        mensagem.setTo(canal.getValor());
        mensagem.setSubject("Aviso da Memora: sua senha foi alterada");
        mensagem.setText(montarAvisoSemLinks(nomeTratamento));

        try {
            carteiro.send(mensagem);
            LOG.info("Aviso de senha alterada enviado por e-mail para o canal {}.", canal.getId());
        } catch (MailException falha) {
            LOG.error(
                    "Falha ao enviar aviso de senha alterada para o canal {} (motivo: {}).",
                    canal.getId(),
                    falha.getClass().getSimpleName());
        }
    }

    static String montarAvisoSemLinks(String nomeTratamento) {
        String saudacao =
                (nomeTratamento == null || nomeTratamento.isBlank())
                        ? "Olá!"
                        : "Olá, " + nomeTratamento.trim() + "!";
        return """
                %s Aqui é a Memora.

                Estou passando para avisar que a senha da sua conta na Memora acabou de ser trocada.

                Se foi você quem trocou a senha agora há pouco, está tudo certo e você não precisa fazer nada.

                Se não foi você, abra o aplicativo Memora direto no seu celular e toque em "Esqueci minha senha" para criar uma senha nova.
                Lembre-se: a Memora nunca pede a sua senha e nunca envia links por mensagem ou e-mail.
                """
                .formatted(saudacao);
    }
}

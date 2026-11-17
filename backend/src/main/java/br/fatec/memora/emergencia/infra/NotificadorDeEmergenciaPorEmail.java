package br.fatec.memora.emergencia.infra;

import jakarta.annotation.PostConstruct;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

/**
 * Adaptador de produção para envio de alerta de emergência via e-mail (SMTP).
 */
@Component
@Profile("producao")
public class NotificadorDeEmergenciaPorEmail implements NotificadorDeEmergencia {

    private static final Logger LOG =
            LoggerFactory.getLogger(NotificadorDeEmergenciaPorEmail.class);
    private static final DateTimeFormatter HORA_BR =
            DateTimeFormatter.ofPattern("dd/MM/yyyy 'às' HH:mm", Locale.forLanguageTag("pt-BR"))
                    .withZone(ZoneId.of("America/Sao_Paulo"));

    private final JavaMailSender carteiro;
    private final String hostSmtp;
    private final String remetente;

    public NotificadorDeEmergenciaPorEmail(
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
                            + "para envio de notificacoes de emergencia.");
        }
        if (remetente == null || remetente.isBlank()) {
            throw new IllegalStateException(
                    "Perfil 'producao' exige remetente configurado em 'memora.email.remetente' "
                            + "para envio de notificacoes de emergencia.");
        }
    }

    @Override
    public ResultadoEntrega notificar(PedidoNotificacao pedido) {
        String destino = pedido.contatoDestino();
        if (destino == null || destino.isBlank()) {
            return ResultadoEntrega.falha("CONTATO_INEXISTENTE");
        }
        if (!destino.contains("@")) {
            LOG.warn(
                    "Contato de emergencia do evento {} nao possui e-mail para despacho SMTP.",
                    pedido.eventoId());
            return ResultadoEntrega.falha("CANAL_NAO_SUPORTADO_NO_SERVIDOR");
        }

        SimpleMailMessage mensagem = new SimpleMailMessage();
        mensagem.setFrom(remetente.trim());
        mensagem.setTo(destino.trim());
        mensagem.setSubject("Alerta SOS do Memora — pedido manual de ajuda");
        mensagem.setText(montarCorpoSemLinks(pedido));

        try {
            carteiro.send(mensagem);
            String entregaId = "smtp-" + UUID.randomUUID();
            LOG.info(
                    "Notificacao SOS enviada por e-mail. evento={} entregaId={}",
                    pedido.eventoId(),
                    entregaId);
            return ResultadoEntrega.sucesso(entregaId);
        } catch (MailException falha) {
            LOG.error(
                    "Falha ao enviar notificacao SOS do evento {} (motivo: {}).",
                    pedido.eventoId(),
                    falha.getClass().getSimpleName());
            return ResultadoEntrega.falha("FALHA_SMTP_" + falha.getClass().getSimpleName());
        }
    }

    static String montarCorpoSemLinks(PedidoNotificacao pedido) {
        String nome =
                (pedido.nomeSolicitante() == null || pedido.nomeSolicitante().isBlank())
                        ? "a pessoa usuária"
                        : pedido.nomeSolicitante().trim();
        String tipoTexto =
                pedido.tipo().name().equals("SOS_MANUAL")
                        ? "Pedido manual pelo botão SOS"
                        : "Alerta automático de detecção de queda";
        String linhaLocalizacao =
                (pedido.latitude() != null && pedido.longitude() != null)
                        ? String.format(
                                Locale.US,
                                "Localização aproximada autorizada: %.5f, %.5f",
                                pedido.latitude(),
                                pedido.longitude())
                        : "Localização não compartilhada neste envio.";

        return """
                Olá! Este é um aviso automático do Memora.

                %s solicitou ajuda (%s) em %s.
                %s

                Tente entrar em contato por telefone ou pessoalmente para verificar se está tudo bem.
                Se houver urgência médica, ligue para 192 (SAMU).
                """
                .formatted(nome, tipoTexto, HORA_BR.format(pedido.ocorridoEm()), linhaLocalizacao);
    }
}

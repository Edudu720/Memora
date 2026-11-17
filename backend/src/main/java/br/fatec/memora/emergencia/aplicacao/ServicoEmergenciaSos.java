package br.fatec.memora.emergencia.aplicacao;

import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.comum.CodigoDeErro;
import br.fatec.memora.comum.FalhaDoMemora;
import br.fatec.memora.emergencia.api.dto.SolicitarSosRequest;
import br.fatec.memora.emergencia.api.dto.SolicitarSosResponse;
import br.fatec.memora.emergencia.dominio.EventoEmergencia;
import br.fatec.memora.emergencia.dominio.StatusEventoEmergencia;
import br.fatec.memora.emergencia.dominio.TipoEventoEmergencia;
import br.fatec.memora.emergencia.infra.NotificadorDeEmergencia;
import br.fatec.memora.emergencia.infra.RepositorioEventoEmergencia;
import br.fatec.memora.emergencia.seguranca.LimitadorDeEnvioSos;
import java.time.Clock;
import java.time.Instant;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;
import java.util.regex.Pattern;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Orquestra o registro idempotente e o encaminhamento de eventos SOS (Feature 014).
 */
@Service
public class ServicoEmergenciaSos {

    private static final Logger LOG = LoggerFactory.getLogger(ServicoEmergenciaSos.class);

    static final String MENSAGEM_ENVIADO =
            "Sua solicitação foi encaminhada. Isso confirma o envio pelo sistema, "
                    + "mas não garante que o contato já leu.";

    static final String MENSAGEM_FALHA =
            "Não consegui avisar o seu contato agora. Tente ligar direto para ele ou "
                    + "para o 192.";

    static final String MENSAGEM_SEM_CONTATO =
            "Nenhum contato de emergência válido foi encontrado. Ligue diretamente "
                    + "para alguém de confiança ou para o 192.";

    static final String MENSAGEM_SEM_EMAIL_NO_SERVIDOR =
            "Seu contato ainda não tem e-mail cadastrado para o aviso automático. "
                    + "Use o celular para avisar ou ligue para o 192.";

    private static final Pattern PADRAO_EMAIL =
            Pattern.compile("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");

    private final RepositorioEventoEmergencia eventos;
    private final RepositorioPessoaUsuaria pessoas;
    private final NotificadorDeEmergencia notificador;
    private final LimitadorDeEnvioSos limitador;
    private final Clock relogio;

    public ServicoEmergenciaSos(
            RepositorioEventoEmergencia eventos,
            RepositorioPessoaUsuaria pessoas,
            NotificadorDeEmergencia notificador,
            LimitadorDeEnvioSos limitador,
            Clock relogio) {
        this.eventos = eventos;
        this.pessoas = pessoas;
        this.notificador = notificador;
        this.limitador = limitador;
        this.relogio = relogio;
    }

    /**
     * Processa uma solicitação SOS garantindo idempotência por {@code eventoId}
     * (FR-012, BR-009) e separação entre SOS manual e queda automática (FR-014).
     */
    @Transactional
    public SolicitarSosResponse registrarEEnviar(UUID pessoaId, SolicitarSosRequest request) {
        TipoEventoEmergencia tipo = interpretarTipo(request.tipo());

        Optional<EventoEmergencia> existenteOpt = eventos.findById(request.eventoId());
        if (existenteOpt.isPresent()) {
            EventoEmergencia existente = existenteOpt.get();
            if (!existente.getPessoaId().equals(pessoaId)) {
                throw FalhaDoMemora.de(
                        CodigoDeErro.DADOS_INVALIDOS,
                        "Não foi possível usar este identificador de pedido. Tente novamente.");
            }
            LOG.info(
                    "Solicitacao SOS idempotente reutilizada. eventoId={} status={}",
                    existente.getId(),
                    existente.getStatus());
            return paraResposta(existente);
        }

        Instant agora = relogio.instant();
        Double latitude = request.localizacao() != null ? request.localizacao().latitude() : null;
        Double longitude = request.localizacao() != null ? request.localizacao().longitude() : null;

        String destinoLimpo = limpar(request.contatoDestino());
        if (!contatoEhValido(destinoLimpo)) {
            EventoEmergencia eventoInvalido =
                    new EventoEmergencia(
                            request.eventoId(),
                            pessoaId,
                            tipo,
                            latitude,
                            longitude,
                            null,
                            null,
                            agora);
            eventoInvalido.marcarFalha("CONTATO_INVALIDO_OU_INEXISTENTE", agora);
            eventos.save(eventoInvalido);
            return new SolicitarSosResponse(
                    eventoInvalido.getId(),
                    eventoInvalido.getTipo().name(),
                    eventoInvalido.getStatus().name(),
                    MENSAGEM_SEM_CONTATO,
                    eventoInvalido.getOcorridoEm());
        }

        LimitadorDeEnvioSos.Decisao decisao =
                limitador.verificarERegistrar(pessoaId, destinoLimpo, agora);
        if (!decisao.permitido()) {
            LOG.warn(
                    "Limite de envios SOS atingido para pessoa {} (tentar novamente em {}s).",
                    pessoaId,
                    decisao.tentarNovamenteEmSegundos());
            throw FalhaDoMemora.limiteSos(decisao.tentarNovamenteEmSegundos());
        }

        String nomeContatoLimpo = limpar(request.contatoNome());
        EventoEmergencia evento =
                new EventoEmergencia(
                        request.eventoId(),
                        pessoaId,
                        tipo,
                        latitude,
                        longitude,
                        nomeContatoLimpo,
                        destinoLimpo,
                        agora);

        String nomeSolicitante =
                pessoas.findById(pessoaId).map(PessoaUsuaria::getNomeTratamento).orElse("");

        NotificadorDeEmergencia.ResultadoEntrega resultado =
                notificador.notificar(
                        new NotificadorDeEmergencia.PedidoNotificacao(
                                evento.getId(),
                                pessoaId,
                                nomeSolicitante,
                                evento.getTipo(),
                                evento.getOcorridoEm(),
                                evento.getContatoNome(),
                                evento.getContatoDestino(),
                                evento.getLatitude(),
                                evento.getLongitude()));

        Instant instantePosEnvio = relogio.instant();
        if (resultado.entregue()) {
            evento.marcarEnviado(resultado.entregaId(), instantePosEnvio);
        } else {
            evento.marcarFalha(
                    resultado.detalheTecnico() != null
                            ? resultado.detalheTecnico()
                            : "FALHA_DESPACHO",
                    instantePosEnvio);
        }

        // Minimização de PII de terceiros: o destino e o nome não ficam retidos após o despacho.
        evento.limparDadosDoContato();
        eventos.save(evento);
        return paraResposta(evento);
    }

    /** Limpeza periódica de coordenadas cuja retenção de 24h expirou (NFR-006). */
    @Scheduled(fixedDelay = 3_600_000L, initialDelay = 120_000L)
    public void expurgarLocalizacoesExpiradas() {
        int limpos = eventos.expurgarLocalizacoesExpiradas(relogio.instant());
        if (limpos > 0) {
            LOG.info("Expurgadas {} localizacoes expiradas de eventos SOS.", limpos);
        }
    }

    private SolicitarSosResponse paraResposta(EventoEmergencia evento) {
        String mensagem =
                switch (evento.getStatus()) {
                    case ENVIADO, CONFIRMADO_PELO_DESTINATARIO -> MENSAGEM_ENVIADO;
                    case PENDENTE, PROCESSANDO -> MENSAGEM_ENVIADO;
                    case FALHA -> {
                        String detalhe = evento.getDetalheTecnico();
                        if ("CONTATO_INVALIDO_OU_INEXISTENTE".equals(detalhe)) {
                            yield MENSAGEM_SEM_CONTATO;
                        } else if ("CANAL_NAO_SUPORTADO_NO_SERVIDOR".equals(detalhe)) {
                            yield MENSAGEM_SEM_EMAIL_NO_SERVIDOR;
                        } else {
                            yield MENSAGEM_FALHA;
                        }
                    }
                };
        return new SolicitarSosResponse(
                evento.getId(),
                evento.getTipo().name(),
                evento.getStatus().name(),
                mensagem,
                evento.getOcorridoEm());
    }

    private static TipoEventoEmergencia interpretarTipo(String bruto) {
        String normalizado = bruto == null ? "" : bruto.trim().toUpperCase(Locale.ROOT);
        try {
            return TipoEventoEmergencia.valueOf(normalizado);
        } catch (IllegalArgumentException e) {
            throw FalhaDoMemora.de(
                    CodigoDeErro.DADOS_INVALIDOS,
                    "Não consegui identificar o tipo do pedido de ajuda. Tente novamente.");
        }
    }

    private static boolean contatoEhValido(String destino) {
        if (destino == null || destino.isBlank()) {
            return false;
        }
        if (destino.contains("@")) {
            return PADRAO_EMAIL.matcher(destino).matches();
        }
        String digitos = destino.replaceAll("\\D", "");
        return digitos.length() >= 10 && digitos.length() <= 13;
    }

    private static String limpar(String s) {
        if (s == null) return null;
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }
}

package br.fatec.memora.emergencia.dominio;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Duration;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

/**
 * Registro persistente de um evento de emergência SOS ou de queda (Feature 014).
 */
@Entity
@Table(name = "evento_emergencia")
public class EventoEmergencia {

    /** Prazo máximo de retenção de coordenadas opcionais no servidor (24 horas). */
    public static final Duration RETENCAO_LOCALIZACAO = Duration.ofHours(24);

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    @Column(name = "pessoa_id", nullable = false, updatable = false)
    private UUID pessoaId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30, updatable = false)
    private TipoEventoEmergencia tipo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private StatusEventoEmergencia status;

    @Column(name = "latitude")
    private Double latitude;

    @Column(name = "longitude")
    private Double longitude;

    @Column(name = "contato_nome", length = 120)
    private String contatoNome;

    @Column(name = "contato_destino", length = 160)
    private String contatoDestino;

    @Column(name = "entrega_id", length = 120)
    private String entregaId;

    @Column(name = "detalhe_tecnico", length = 255)
    private String detalheTecnico;

    @Column(name = "ocorrido_em", nullable = false, updatable = false)
    private Instant ocorridoEm;

    @Column(name = "atualizado_em", nullable = false)
    private Instant atualizadoEm;

    @Column(name = "expira_localizacao_em")
    private Instant expiraLocalizacaoEm;

    /** Exigido pelo JPA. */
    protected EventoEmergencia() {
    }

    public EventoEmergencia(
            UUID id,
            UUID pessoaId,
            TipoEventoEmergencia tipo,
            Double latitude,
            Double longitude,
            String contatoNome,
            String contatoDestino,
            Instant ocorridoEm) {
        this.id = Objects.requireNonNull(id, "id");
        this.pessoaId = Objects.requireNonNull(pessoaId, "pessoaId");
        this.tipo = Objects.requireNonNull(tipo, "tipo");
        this.status = StatusEventoEmergencia.PROCESSANDO;
        this.latitude = latitude;
        this.longitude = longitude;
        this.contatoNome = limitar(contatoNome, 120);
        this.contatoDestino = limitar(contatoDestino, 160);
        this.ocorridoEm = Objects.requireNonNull(ocorridoEm, "ocorridoEm");
        this.atualizadoEm = ocorridoEm;
        this.expiraLocalizacaoEm =
                (latitude != null && longitude != null)
                        ? ocorridoEm.plus(RETENCAO_LOCALIZACAO)
                        : null;
    }

    public void marcarEnviado(String entregaId, Instant agora) {
        this.status = StatusEventoEmergencia.ENVIADO;
        this.entregaId = limitar(entregaId, 120);
        this.detalheTecnico = null;
        this.atualizadoEm = Objects.requireNonNull(agora, "agora");
    }

    public void marcarFalha(String detalheTecnico, Instant agora) {
        this.status = StatusEventoEmergencia.FALHA;
        this.detalheTecnico = limitar(detalheTecnico, 255);
        this.atualizadoEm = Objects.requireNonNull(agora, "agora");
    }

    public void limparLocalizacao() {
        this.latitude = null;
        this.longitude = null;
        this.expiraLocalizacaoEm = null;
    }

    /** Remove PII de terceiros após a tentativa de envio (minimização de dados, Feature 014). */
    public void limparDadosDoContato() {
        this.contatoNome = null;
        this.contatoDestino = null;
    }

    public UUID getId() {
        return id;
    }

    public UUID getPessoaId() {
        return pessoaId;
    }

    public TipoEventoEmergencia getTipo() {
        return tipo;
    }

    public StatusEventoEmergencia getStatus() {
        return status;
    }

    public Double getLatitude() {
        return latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public String getContatoNome() {
        return contatoNome;
    }

    public String getContatoDestino() {
        return contatoDestino;
    }

    public String getEntregaId() {
        return entregaId;
    }

    public String getDetalheTecnico() {
        return detalheTecnico;
    }

    public Instant getOcorridoEm() {
        return ocorridoEm;
    }

    public Instant getAtualizadoEm() {
        return atualizadoEm;
    }

    public Instant getExpiraLocalizacaoEm() {
        return expiraLocalizacaoEm;
    }

    private static String limitar(String texto, int maximo) {
        if (texto == null) return null;
        String limpo = texto.trim();
        if (limpo.isEmpty()) return null;
        return limpo.length() <= maximo ? limpo : limpo.substring(0, maximo);
    }
}

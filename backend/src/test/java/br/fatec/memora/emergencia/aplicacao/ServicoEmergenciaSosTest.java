package br.fatec.memora.emergencia.aplicacao;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import br.fatec.memora.autenticacao.dominio.EstadoDaConta;
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
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

@DisplayName("ServicoEmergenciaSos — regras de SOS manual, idempotência e privacidade")
class ServicoEmergenciaSosTest {

    private static final Instant AGORA = Instant.parse("2026-11-16T18:00:00Z");

    private RepositorioEventoEmergencia eventos;
    private RepositorioPessoaUsuaria pessoas;
    private NotificadorDeEmergencia notificador;
    private ServicoEmergenciaSos servico;

    private UUID pessoaId;
    private UUID eventoId;

    @BeforeEach
    void preparar() {
        eventos = mock(RepositorioEventoEmergencia.class);
        pessoas = mock(RepositorioPessoaUsuaria.class);
        notificador = mock(NotificadorDeEmergencia.class);
        servico =
                new ServicoEmergenciaSos(
                        eventos, pessoas, notificador, Clock.fixed(AGORA, ZoneOffset.UTC));

        pessoaId = UUID.randomUUID();
        eventoId = UUID.randomUUID();

        PessoaUsuaria ana =
                new PessoaUsuaria("Dona Ana", "hash", AGORA.minusSeconds(3600), EstadoDaConta.ATIVA);
        when(pessoas.findById(pessoaId)).thenReturn(Optional.of(ana));
        when(eventos.save(any())).thenAnswer(inv -> inv.getArgument(0));
    }

    @Test
    @DisplayName("envia SOS_MANUAL com localização autorizada e registra expiração em 24h")
    void acionamentoManualComLocalizacao() {
        when(eventos.findById(eventoId)).thenReturn(Optional.empty());
        when(notificador.notificar(any()))
                .thenReturn(NotificadorDeEmergencia.ResultadoEntrega.sucesso("ent-1"));

        SolicitarSosRequest req =
                new SolicitarSosRequest(
                        "SOS_MANUAL",
                        eventoId,
                        new SolicitarSosRequest.LocalizacaoRequest(-22.739, -47.331),
                        "Filha Maria",
                        "(19) 99999-8888");

        SolicitarSosResponse resp = servico.registrarEEnviar(pessoaId, req);

        assertThat(resp.eventoId()).isEqualTo(eventoId);
        assertThat(resp.tipo()).isEqualTo("SOS_MANUAL");
        assertThat(resp.status()).isEqualTo("ENVIADO");
        assertThat(resp.mensagem()).contains("encaminhada").contains("não garante");

        ArgumentCaptor<EventoEmergencia> captor = ArgumentCaptor.forClass(EventoEmergencia.class);
        verify(eventos).save(captor.capture());
        EventoEmergencia salvo = captor.getValue();
        assertThat(salvo.getLatitude()).isEqualTo(-22.739);
        assertThat(salvo.getLongitude()).isEqualTo(-47.331);
        assertThat(salvo.getExpiraLocalizacaoEm())
                .isEqualTo(AGORA.plus(EventoEmergencia.RETENCAO_LOCALIZACAO));
        assertThat(salvo.getEntregaId()).isEqualTo("ent-1");
    }

    @Test
    @DisplayName("permite envio sem localização e sem expiração pendente")
    void acionamentoSemLocalizacao() {
        when(eventos.findById(eventoId)).thenReturn(Optional.empty());
        when(notificador.notificar(any()))
                .thenReturn(NotificadorDeEmergencia.ResultadoEntrega.sucesso("ent-2"));

        SolicitarSosRequest req =
                new SolicitarSosRequest(
                        "SOS_MANUAL", eventoId, null, "Filha Maria", "maria@email.com");

        SolicitarSosResponse resp = servico.registrarEEnviar(pessoaId, req);

        assertThat(resp.status()).isEqualTo("ENVIADO");
        ArgumentCaptor<EventoEmergencia> captor = ArgumentCaptor.forClass(EventoEmergencia.class);
        verify(eventos).save(captor.capture());
        assertThat(captor.getValue().getLatitude()).isNull();
        assertThat(captor.getValue().getLongitude()).isNull();
        assertThat(captor.getValue().getExpiraLocalizacaoEm()).isNull();
    }

    @Test
    @DisplayName("previne duplicidade quando mesmo eventoId é enviado duas vezes pelo mesmo usuário")
    void previneDuplicidadePorIdempotencia() {
        EventoEmergencia existente =
                new EventoEmergencia(
                        eventoId,
                        pessoaId,
                        TipoEventoEmergencia.SOS_MANUAL,
                        null,
                        null,
                        "Maria",
                        "(19) 99999-8888",
                        AGORA.minusSeconds(10));
        existente.marcarEnviado("ent-anterior", AGORA.minusSeconds(9));
        when(eventos.findById(eventoId)).thenReturn(Optional.of(existente));

        SolicitarSosRequest req =
                new SolicitarSosRequest(
                        "SOS_MANUAL", eventoId, null, "Maria", "(19) 99999-8888");

        SolicitarSosResponse resp = servico.registrarEEnviar(pessoaId, req);

        assertThat(resp.eventoId()).isEqualTo(eventoId);
        assertThat(resp.status()).isEqualTo("ENVIADO");
        verify(notificador, never()).notificar(any());
        verify(eventos, never()).save(any());
    }

    @Test
    @DisplayName("recusa reutilização de eventoId pertencente a outro usuário")
    void recusaEventoIdDeOutroUsuario() {
        UUID outroUsuario = UUID.randomUUID();
        EventoEmergencia existente =
                new EventoEmergencia(
                        eventoId,
                        outroUsuario,
                        TipoEventoEmergencia.SOS_MANUAL,
                        null,
                        null,
                        "Maria",
                        "(19) 99999-8888",
                        AGORA);
        when(eventos.findById(eventoId)).thenReturn(Optional.of(existente));

        SolicitarSosRequest req =
                new SolicitarSosRequest(
                        "SOS_MANUAL", eventoId, null, "Maria", "(19) 99999-8888");

        assertThatThrownBy(() -> servico.registrarEEnviar(pessoaId, req))
                .isInstanceOf(FalhaDoMemora.class)
                .extracting(e -> ((FalhaDoMemora) e).getCodigo())
                .isEqualTo(CodigoDeErro.DADOS_INVALIDOS);
    }

    @Test
    @DisplayName("diferencia alerta QUEDA_AUTOMATICA de SOS_MANUAL")
    void distingueQuedaAutomatica() {
        when(eventos.findById(eventoId)).thenReturn(Optional.empty());
        when(notificador.notificar(any()))
                .thenReturn(NotificadorDeEmergencia.ResultadoEntrega.sucesso("ent-q"));

        SolicitarSosRequest req =
                new SolicitarSosRequest(
                        "QUEDA_AUTOMATICA", eventoId, null, "Filho Pedro", "19998887766");

        SolicitarSosResponse resp = servico.registrarEEnviar(pessoaId, req);

        assertThat(resp.tipo()).isEqualTo("QUEDA_AUTOMATICA");
        assertThat(resp.status()).isEqualTo("ENVIADO");
    }

    @Test
    @DisplayName("registra FALHA sem acionar notificador quando contato está ausente ou inválido")
    void contatoInexistenteOuInvalido() {
        when(eventos.findById(eventoId)).thenReturn(Optional.empty());

        SolicitarSosRequest reqSemContato =
                new SolicitarSosRequest("SOS_MANUAL", eventoId, null, null, "");

        SolicitarSosResponse resp = servico.registrarEEnviar(pessoaId, reqSemContato);

        assertThat(resp.status()).isEqualTo("FALHA");
        assertThat(resp.mensagem()).contains("192");
        verify(notificador, never()).notificar(any());

        ArgumentCaptor<EventoEmergencia> captor = ArgumentCaptor.forClass(EventoEmergencia.class);
        verify(eventos, times(1)).save(captor.capture());
        assertThat(captor.getValue().getStatus()).isEqualTo(StatusEventoEmergencia.FALHA);
    }

    @Test
    @DisplayName("registra FALHA técnica e orienta alternativa quando notificador falha")
    void falhaDeEntregaNoNotificador() {
        when(eventos.findById(eventoId)).thenReturn(Optional.empty());
        when(notificador.notificar(any()))
                .thenReturn(NotificadorDeEmergencia.ResultadoEntrega.falha("SMTP_TIMEOUT"));

        SolicitarSosRequest req =
                new SolicitarSosRequest("SOS_MANUAL", eventoId, null, "Filha", "filha@email.com");

        SolicitarSosResponse resp = servico.registrarEEnviar(pessoaId, req);

        assertThat(resp.status()).isEqualTo("FALHA");
        assertThat(resp.mensagem()).contains("192").doesNotContain("SMTP_TIMEOUT");

        ArgumentCaptor<EventoEmergencia> captor = ArgumentCaptor.forClass(EventoEmergencia.class);
        verify(eventos).save(captor.capture());
        assertThat(captor.getValue().getDetalheTecnico()).isEqualTo("SMTP_TIMEOUT");
    }

    @Test
    @DisplayName("explica ausência de e-mail sem vazar detalhe técnico quando canal SMTP recusa telefone")
    void canalNaoSuportadoSemEmailExplicaAlternativa() {
        when(eventos.findById(eventoId)).thenReturn(Optional.empty());
        when(notificador.notificar(any()))
                .thenReturn(NotificadorDeEmergencia.ResultadoEntrega.falha("CANAL_NAO_SUPORTADO_NO_SERVIDOR"));

        SolicitarSosRequest req =
                new SolicitarSosRequest("SOS_MANUAL", eventoId, null, "Filha", "11999998888");

        SolicitarSosResponse resp = servico.registrarEEnviar(pessoaId, req);

        assertThat(resp.status()).isEqualTo("FALHA");
        assertThat(resp.mensagem())
                .contains("e-mail")
                .contains("192")
                .doesNotContain("CANAL_NAO_SUPORTADO_NO_SERVIDOR");
    }
}

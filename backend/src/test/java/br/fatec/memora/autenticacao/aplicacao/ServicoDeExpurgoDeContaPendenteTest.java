package br.fatec.memora.autenticacao.aplicacao;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import br.fatec.memora.autenticacao.dominio.CanalContato;
import br.fatec.memora.autenticacao.dominio.EstadoDaConta;
import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.dominio.TipoDeCanal;
import br.fatec.memora.autenticacao.infra.RepositorioCanalContato;
import br.fatec.memora.autenticacao.infra.RepositorioEventoAutenticacao;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.seguranca.EmissorDeTokenDeAcesso;
import br.fatec.memora.autenticacao.seguranca.GeradorDeSegredoOpaco;
import br.fatec.memora.autenticacao.seguranca.ServicoDeSessao;
import br.fatec.memora.comum.RegistroDeAuditoria;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.InOrder;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Testes unitários de {@link ServicoDeExpurgoDeContaPendente} e da sua
 * integração em {@link ServicoDeCadastro} (T065b, FR-004 a FR-007 da Feature 006).
 */
@DisplayName("T065b — unidade de ServicoDeExpurgoDeContaPendente e ServicoDeCadastro")
class ServicoDeExpurgoDeContaPendenteTest {

    private static final Instant AGORA = Instant.parse("2026-11-14T12:00:00Z");

    private RepositorioPessoaUsuaria pessoas;
    private RepositorioCanalContato canais;
    private RepositorioEventoAutenticacao eventos;
    private PasswordEncoder codificador;
    private GeradorDeSegredoOpaco gerador;
    private ServicoDeSessao sessoes;
    private EmissorDeTokenDeAcesso emissor;
    private RegistroDeAuditoria auditoria;
    private Clock relogio;
    private ServicoDeExpurgoDeContaPendente servicoDeExpurgo;
    private ServicoDeCadastro servicoDeCadastro;

    @BeforeEach
    void preparar() {
        pessoas = mock(RepositorioPessoaUsuaria.class);
        canais = mock(RepositorioCanalContato.class);
        eventos = mock(RepositorioEventoAutenticacao.class);
        codificador = mock(PasswordEncoder.class);
        gerador = mock(GeradorDeSegredoOpaco.class);
        sessoes = mock(ServicoDeSessao.class);
        emissor = mock(EmissorDeTokenDeAcesso.class);
        auditoria = mock(RegistroDeAuditoria.class);
        relogio = Clock.fixed(AGORA, ZoneOffset.UTC);

        servicoDeExpurgo =
                new ServicoDeExpurgoDeContaPendente(
                        pessoas, eventos, relogio, Duration.ofHours(24));
        servicoDeCadastro =
                new ServicoDeCadastro(
                        pessoas,
                        canais,
                        codificador,
                        gerador,
                        sessoes,
                        emissor,
                        auditoria,
                        servicoDeExpurgo,
                        relogio);
    }

    @Test
    @DisplayName(
            "expurgarSeExpirada remove eventos antes da pessoa e faz flush quando conta PENDENTE_VERIFICACAO tem > 24h")
    void expurgaNaOrdemCorretaQuandoExpirada() {
        PessoaUsuaria expirada =
                new PessoaUsuaria(
                        "Dona Maria",
                        "hash-antigo",
                        AGORA.minus(Duration.ofHours(24).plusSeconds(1)),
                        EstadoDaConta.PENDENTE_VERIFICACAO);
        when(pessoas.findById(expirada.getId())).thenReturn(Optional.of(expirada));

        boolean resultado = servicoDeExpurgo.expurgarSeExpirada(expirada.getId(), AGORA);

        assertThat(resultado).isTrue();
        InOrder ordem = inOrder(eventos, pessoas);
        ordem.verify(eventos).deletarPorPessoaId(expirada.getId());
        ordem.verify(pessoas).delete(expirada);
        ordem.verify(pessoas).flush();
    }

    @Test
    @DisplayName(
            "expurgarSeExpirada retorna false e nada apaga para conta PENDENTE_VERIFICACAO com <= 24h ou conta ATIVA")
    void naoExpurgaContaRecenteOuAtiva() {
        PessoaUsuaria noLimite24h =
                new PessoaUsuaria(
                        "Dona Maria",
                        "hash",
                        AGORA.minus(Duration.ofHours(24)),
                        EstadoDaConta.PENDENTE_VERIFICACAO);
        PessoaUsuaria ativaAntiga =
                new PessoaUsuaria(
                        "Dona Maria",
                        "hash",
                        AGORA.minus(Duration.ofHours(72)),
                        EstadoDaConta.ATIVA);

        assertThat(servicoDeExpurgo.expurgarSeExpirada(noLimite24h, AGORA)).isFalse();
        assertThat(servicoDeExpurgo.expurgarSeExpirada(ativaAntiga, AGORA)).isFalse();
        verify(eventos, never()).deletarPorPessoaId(any());
        verify(pessoas, never()).delete(any());

        assertThatThrownBy(() -> servicoDeExpurgo.expurgarContaPendente(ativaAntiga))
                .isInstanceOf(IllegalStateException.class);
    }

    @Test
    @DisplayName(
            "ServicoDeCadastro calcula hash Argon2id ANTES de consultar o canal e expurga conta pendente > 24h criando nova conta")
    void cadastroCalculaHashAntesDeExpurgarECriaNovaConta() {
        PessoaUsuaria abandonada =
                new PessoaUsuaria(
                        "Dona Maria",
                        "hash-antigo",
                        AGORA.minus(Duration.ofHours(25)),
                        EstadoDaConta.PENDENTE_VERIFICACAO);
        CanalContato canalAntigo =
                new CanalContato(
                        abandonada.getId(),
                        TipoDeCanal.EMAIL,
                        "maria@gmail.com",
                        "hash-canal",
                        true,
                        AGORA.minus(Duration.ofHours(25)));

        when(codificador.encode(any())).thenReturn("novo-hash-argon2");
        when(gerador.hashDe("maria@gmail.com")).thenReturn("hash-canal");
        when(canais.findByValorHash("hash-canal")).thenReturn(Optional.of(canalAntigo));
        when(pessoas.findById(abandonada.getId())).thenReturn(Optional.of(abandonada));
        when(pessoas.saveAndFlush(any(PessoaUsuaria.class)))
                .thenAnswer(inv -> inv.getArgument(0));
        when(canais.saveAndFlush(any(CanalContato.class)))
                .thenAnswer(inv -> inv.getArgument(0));
        when(sessoes.iniciar(any(), any(), eq(AGORA)))
                .thenReturn(
                        new ServicoDeSessao.SessaoEmitida(
                                UUID.randomUUID(), "jwt-real", "refresh-real", 900L));

        ServicoDeCadastro.Cadastrada cadastrada =
                servicoDeCadastro.cadastrar(
                        "Dona Maria",
                        TipoDeCanal.EMAIL,
                        "maria@gmail.com",
                        "bolo de milho quentinho",
                        "Moto G",
                        false);

        InOrder ordem = inOrder(codificador, canais, eventos, pessoas);
        ordem.verify(codificador).encode("bolo de milho quentinho");
        ordem.verify(canais).findByValorHash("hash-canal");
        ordem.verify(eventos).deletarPorPessoaId(abandonada.getId());
        ordem.verify(pessoas).delete(abandonada);
        ordem.verify(pessoas).flush();
        ordem.verify(pessoas).saveAndFlush(any(PessoaUsuaria.class));

        assertThat(cadastrada.tokenAcesso()).isEqualTo("jwt-real");
        assertThat(cadastrada.pessoaId()).isNotEqualTo(abandonada.getId());
    }

    @Test
    @DisplayName(
            "rotina agendada expurgarContasPendentesVencidas remove em lote todas as contas pendentes anteriores a 24h")
    void rotinaAgendadaRemoveEmLote() {
        PessoaUsuaria c1 =
                new PessoaUsuaria(
                        "Conta 1",
                        "h1",
                        AGORA.minus(Duration.ofHours(30)),
                        EstadoDaConta.PENDENTE_VERIFICACAO);
        PessoaUsuaria c2 =
                new PessoaUsuaria(
                        "Conta 2",
                        "h2",
                        AGORA.minus(Duration.ofHours(48)),
                        EstadoDaConta.PENDENTE_VERIFICACAO);

        when(pessoas.buscarContasPorEstadoAnterioresA(
                        EstadoDaConta.PENDENTE_VERIFICACAO, AGORA.minus(Duration.ofHours(24))))
                .thenReturn(List.of(c1, c2));

        int total = servicoDeExpurgo.expurgarContasPendentesVencidas();

        assertThat(total).isEqualTo(2);
        verify(eventos).deletarPorPessoaId(c1.getId());
        verify(eventos).deletarPorPessoaId(c2.getId());
        verify(pessoas).delete(c1);
        verify(pessoas).delete(c2);
    }
}

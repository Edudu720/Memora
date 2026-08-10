package br.fatec.memora.autenticacao.seguranca;

import static org.assertj.core.api.Assertions.assertThat;

import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.dominio.Sessao;
import br.fatec.memora.autenticacao.infra.RepositorioEventoAutenticacao;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioSessao;
import br.fatec.memora.autenticacao.seguranca.ServicoDeSessao.MotivoDaRecusa;
import br.fatec.memora.autenticacao.seguranca.ServicoDeSessao.ResultadoDaRenovacao;
import br.fatec.memora.autenticacao.seguranca.ServicoDeSessao.SessaoEmitida;
import br.fatec.memora.suporte.TesteComBanco;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

/** Emissao e rotacao de sessao (T018, T019, R2). */
@DisplayName("Servico de sessao")
class ServicoDeSessaoTest extends TesteComBanco {

    private static final Instant AGORA = Instant.now().truncatedTo(ChronoUnit.MICROS);
    private static final String APARELHO = "Pixel 6";
    private static final String ORIGEM = "hash-de-origem";

    @Autowired
    private ServicoDeSessao servico;

    @Autowired
    private EmissorDeTokenDeAcesso emissor;

    @Autowired
    private GeradorDeSegredoOpaco gerador;

    @Autowired
    private RepositorioSessao sessoes;

    @Autowired
    private RepositorioPessoaUsuaria pessoas;

    @Autowired
    private RepositorioEventoAutenticacao eventos;

    @Autowired
    private JdbcTemplate jdbc;

    @AfterEach
    void limpar() {
        sessoes.deleteAll();
        eventos.deleteAll();
        pessoas.deleteAll();
    }

    private PessoaUsuaria pessoaSalva() {
        return pessoas.saveAndFlush(new PessoaUsuaria("Ana", "hash", AGORA));
    }

    @Test
    @DisplayName("iniciar devolve token de acesso valido para a pessoa")
    void iniciarDevolveTokenDeAcesso() {
        PessoaUsuaria pessoa = pessoaSalva();

        SessaoEmitida emitida = servico.iniciar(pessoa.getId(), APARELHO, AGORA);

        assertThat(emissor.pessoaDoToken(emitida.tokenAcesso())).contains(pessoa.getId());
        assertThat(emitida.expiraEmSegundos()).isEqualTo(900);
        assertThat(emitida.refreshToken()).isNotBlank();
    }

    @Test
    @DisplayName("iniciar abre uma familia nova")
    void iniciarAbreFamilia() {
        PessoaUsuaria pessoa = pessoaSalva();

        SessaoEmitida emitida = servico.iniciar(pessoa.getId(), APARELHO, AGORA);

        Sessao persistida =
                sessoes.findByRefreshTokenHash(gerador.hashDe(emitida.refreshToken())).orElseThrow();
        assertThat(persistida.getFamiliaId()).isEqualTo(persistida.getId());
        assertThat(persistida.foiSubstituida()).isFalse();
        assertThat(persistida.getAparelhoDescricao()).isEqualTo(APARELHO);
    }

    @Test
    @DisplayName("o refresh token nunca e gravado em texto puro")
    void refreshNaoVaiEmTextoPuroParaOBanco() {
        PessoaUsuaria pessoa = pessoaSalva();

        SessaoEmitida emitida = servico.iniciar(pessoa.getId(), APARELHO, AGORA);

        Integer emTextoPuro = jdbc.queryForObject(
                "SELECT count(*) FROM sessao WHERE refresh_token_hash = ?",
                Integer.class,
                emitida.refreshToken());
        assertThat(emTextoPuro).as("o valor em claro apareceu no banco").isZero();

        Integer hasheado = jdbc.queryForObject(
                "SELECT count(*) FROM sessao WHERE refresh_token_hash = ?",
                Integer.class,
                gerador.hashDe(emitida.refreshToken()));
        assertThat(hasheado).isEqualTo(1);
    }

    @Test
    @DisplayName("renovar troca o refresh e mantem a familia")
    void renovarRotacionaDentroDaFamilia() {
        PessoaUsuaria pessoa = pessoaSalva();
        SessaoEmitida primeira = servico.iniciar(pessoa.getId(), APARELHO, AGORA);
        UUID familia = sessoes
                .findByRefreshTokenHash(gerador.hashDe(primeira.refreshToken()))
                .orElseThrow()
                .getFamiliaId();

        ResultadoDaRenovacao resultado = servico.renovar(primeira.refreshToken(), ORIGEM, AGORA);

        assertThat(resultado).isInstanceOf(ResultadoDaRenovacao.Renovada.class);
        SessaoEmitida segunda = ((ResultadoDaRenovacao.Renovada) resultado).sessao();

        assertThat(segunda.refreshToken()).isNotEqualTo(primeira.refreshToken());
        assertThat(sessoes.findByFamiliaId(familia)).hasSize(2);
        assertThat(sessoes
                        .findByRefreshTokenHash(gerador.hashDe(segunda.refreshToken()))
                        .orElseThrow()
                        .getFamiliaId())
                .isEqualTo(familia);
    }

    @Test
    @DisplayName("renovar marca a sessao anterior como substituida")
    void renovarSubstituiAAnterior() {
        PessoaUsuaria pessoa = pessoaSalva();
        SessaoEmitida primeira = servico.iniciar(pessoa.getId(), APARELHO, AGORA);

        servico.renovar(primeira.refreshToken(), ORIGEM, AGORA);

        Sessao anterior =
                sessoes.findByRefreshTokenHash(gerador.hashDe(primeira.refreshToken())).orElseThrow();
        assertThat(anterior.foiSubstituida()).isTrue();
    }

    @Test
    @DisplayName("a sessao renovada ganha 60 dias de prazo (R2)")
    void renovacaoRenovaOPrazo() {
        PessoaUsuaria pessoa = pessoaSalva();
        SessaoEmitida primeira = servico.iniciar(pessoa.getId(), APARELHO, AGORA);
        Instant depois = AGORA.plus(Duration.ofDays(30));

        ResultadoDaRenovacao resultado = servico.renovar(primeira.refreshToken(), ORIGEM, depois);
        SessaoEmitida segunda = ((ResultadoDaRenovacao.Renovada) resultado).sessao();

        Sessao nova =
                sessoes.findByRefreshTokenHash(gerador.hashDe(segunda.refreshToken())).orElseThrow();
        assertThat(nova.getExpiraEm())
                .isEqualTo(depois.plus(ServicoDeSessao.VALIDADE_DO_REFRESH));
    }

    @Test
    @DisplayName("token desconhecido e recusado")
    void tokenDesconhecidoEhRecusado() {
        ResultadoDaRenovacao resultado = servico.renovar(gerador.gerar(), ORIGEM, AGORA);

        assertThat(resultado)
                .isEqualTo(new ResultadoDaRenovacao.Recusada(MotivoDaRecusa.TOKEN_DESCONHECIDO));
    }

    @Test
    @DisplayName("sessao expirada e recusada")
    void sessaoExpiradaEhRecusada() {
        PessoaUsuaria pessoa = pessoaSalva();
        Instant muitoAntes = AGORA.minus(Duration.ofDays(61));
        SessaoEmitida antiga = servico.iniciar(pessoa.getId(), APARELHO, muitoAntes);

        ResultadoDaRenovacao resultado = servico.renovar(antiga.refreshToken(), ORIGEM, AGORA);

        assertThat(resultado)
                .isEqualTo(new ResultadoDaRenovacao.Recusada(MotivoDaRecusa.TOKEN_EXPIRADO));
    }

    @Test
    @DisplayName("sessao revogada e recusada")
    void sessaoRevogadaEhRecusada() {
        PessoaUsuaria pessoa = pessoaSalva();
        SessaoEmitida emitida = servico.iniciar(pessoa.getId(), APARELHO, AGORA);
        Sessao sessao =
                sessoes.findByRefreshTokenHash(gerador.hashDe(emitida.refreshToken())).orElseThrow();
        sessao.revogar(AGORA);
        sessoes.saveAndFlush(sessao);

        ResultadoDaRenovacao resultado = servico.renovar(emitida.refreshToken(), ORIGEM, AGORA);

        assertThat(resultado)
                .isEqualTo(new ResultadoDaRenovacao.Recusada(MotivoDaRecusa.SESSAO_REVOGADA));
    }
}

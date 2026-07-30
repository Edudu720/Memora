package br.fatec.memora.autenticacao.infra;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import br.fatec.memora.autenticacao.dominio.CanalContato;
import br.fatec.memora.autenticacao.dominio.CodigoVerificacao;
import br.fatec.memora.autenticacao.dominio.EventoAutenticacao;
import br.fatec.memora.autenticacao.dominio.FinalidadeDoCodigo;
import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.dominio.ResultadoDoEvento;
import br.fatec.memora.autenticacao.dominio.Sessao;
import br.fatec.memora.autenticacao.dominio.TipoDeCanal;
import br.fatec.memora.autenticacao.dominio.TipoDeEvento;
import br.fatec.memora.suporte.TesteComBanco;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.transaction.annotation.Transactional;

/**
 * Repositorios da autenticacao contra PostgreSQL real (T014).
 *
 * <p>Os testes nao usam {@code @Transactional} na classe de proposito: varios
 * verificam <b>restricao do banco</b>, e restricao so aparece quando a instrucao
 * chega ao servidor. Transacao de teste com rollback esconderia parte disso.
 */
@DisplayName("Repositorios da autenticacao")
class RepositoriosDeAutenticacaoTest extends TesteComBanco {

    /**
     * Truncado para microssegundos porque e a precisao do TIMESTAMPTZ. Sem isso,
     * o nanossegundo que o Java carrega e o banco descarta faria a comparacao
     * falhar de forma intermitente.
     */
    private static final Instant AGORA = Instant.now().truncatedTo(ChronoUnit.MICROS);

    @Autowired
    private RepositorioPessoaUsuaria pessoas;

    @Autowired
    private RepositorioCanalContato canais;

    @Autowired
    private RepositorioSessao sessoes;

    @Autowired
    private RepositorioCodigoVerificacao codigos;

    @Autowired
    private RepositorioEventoAutenticacao eventos;

    @AfterEach
    void limpar() {
        // Ordem ditada pelas chaves estrangeiras: filhos antes dos pais.
        codigos.deleteAll();
        canais.deleteAll();
        sessoes.deleteAll();
        eventos.deleteAll();
        pessoas.deleteAll();
    }

    private PessoaUsuaria pessoaSalva() {
        return pessoas.save(new PessoaUsuaria("Ana", "$argon2id$hash-ficticio", AGORA));
    }

    @Nested
    @DisplayName("Conta")
    class Conta {

        @Test
        @DisplayName("o id e UUID sorteado, nao sequencial")
        void idNaoSequencial() {
            PessoaUsuaria primeira = pessoaSalva();
            PessoaUsuaria segunda = pessoaSalva();

            assertThat(primeira.getId()).isNotEqualTo(segunda.getId());
            assertThat(primeira.getId().version()).isEqualTo(4);
        }

        @Test
        @DisplayName("entrada bem-sucedida zera as falhas acumuladas")
        void entradaZeraFalhas() {
            PessoaUsuaria pessoa = pessoaSalva();
            pessoa.registrarFalhaDeEntrada();
            pessoa.registrarFalhaDeEntrada();
            pessoas.saveAndFlush(pessoa);

            pessoa.registrarEntradaBemSucedida(AGORA);
            pessoas.saveAndFlush(pessoa);

            PessoaUsuaria relida = pessoas.findById(pessoa.getId()).orElseThrow();
            assertThat(relida.getFalhasConsecutivas()).isZero();
            assertThat(relida.getUltimoAcessoEm()).isEqualTo(AGORA);
        }

        @Test
        @DisplayName("conta exclusivamente social pode ter senha nula (FR-053)")
        void senhaNulaEhPermitida() {
            PessoaUsuaria social = pessoas.saveAndFlush(new PessoaUsuaria("Jose", null, AGORA));

            assertThat(pessoas.findById(social.getId()).orElseThrow().getSenhaHash()).isNull();
        }
    }

    @Nested
    @DisplayName("Canal de contato")
    class Canal {

        @Test
        @DisplayName("o mesmo e-mail nao serve para duas contas")
        void unicidadeDeTipoEValor() {
            PessoaUsuaria primeira = pessoaSalva();
            PessoaUsuaria segunda = pessoaSalva();
            canais.saveAndFlush(canalDe(primeira, "ana@exemplo.com"));

            assertThatThrownBy(() -> canais.saveAndFlush(canalDe(segunda, "ana@exemplo.com")))
                    .isInstanceOf(DataIntegrityViolationException.class);
        }

        @Test
        @DisplayName("o login localiza a conta pelo hash do valor")
        void buscaPeloHash() {
            PessoaUsuaria pessoa = pessoaSalva();
            CanalContato canal = canais.saveAndFlush(canalDe(pessoa, "ana@exemplo.com"));

            assertThat(canais.findByValorHash(canal.getValorHash()))
                    .get()
                    .extracting(CanalContato::getPessoaId)
                    .isEqualTo(pessoa.getId());
        }

        @Test
        @DisplayName("canal nasce nao verificado — posse se prova")
        void nasceNaoVerificado() {
            CanalContato canal = canais.saveAndFlush(canalDe(pessoaSalva(), "ana@exemplo.com"));

            assertThat(canal.isVerificado()).isFalse();
            assertThat(canal.getVerificadoEm()).isNull();
        }

        @Test
        @DisplayName("a recuperacao ve apenas canal verificado (FR-052)")
        void somenteVerificadoApareceParaRecuperacao() {
            PessoaUsuaria pessoa = pessoaSalva();
            canais.saveAndFlush(canalDe(pessoa, "nao-verificado@exemplo.com"));

            CanalContato verificado = canalDe(pessoa, "verificado@exemplo.com");
            verificado.marcarComoVerificado(AGORA);
            canais.saveAndFlush(verificado);

            assertThat(canais.findByPessoaId(pessoa.getId())).hasSize(2);
            assertThat(canais.findByPessoaIdAndVerificadoTrue(pessoa.getId()))
                    .singleElement()
                    .extracting(CanalContato::getValor)
                    .isEqualTo("verificado@exemplo.com");
        }

        @Test
        @DisplayName("existsByTipoAndValor responde sem expor a conta")
        void existePorTipoEValor() {
            canais.saveAndFlush(canalDe(pessoaSalva(), "ana@exemplo.com"));

            assertThat(canais.existsByTipoAndValor(TipoDeCanal.EMAIL, "ana@exemplo.com")).isTrue();
            assertThat(canais.existsByTipoAndValor(TipoDeCanal.EMAIL, "outra@exemplo.com"))
                    .isFalse();
            // Mesmo valor, tipo diferente: nao colide.
            assertThat(canais.existsByTipoAndValor(TipoDeCanal.TELEFONE, "ana@exemplo.com"))
                    .isFalse();
        }

        private CanalContato canalDe(PessoaUsuaria pessoa, String valor) {
            return new CanalContato(
                    pessoa.getId(),
                    TipoDeCanal.EMAIL,
                    valor,
                    "hash-de-" + valor,
                    true,
                    AGORA);
        }
    }

    @Nested
    @DisplayName("Sessao")
    class SessaoDeAcesso {

        @Test
        @DisplayName("a primeira sessao abre a familia com o proprio id")
        void familiaNasceComAPrimeiraSessao() {
            Sessao inicial = sessoes.saveAndFlush(sessaoInicialDe(pessoaSalva()));

            assertThat(inicial.getFamiliaId()).isEqualTo(inicial.getId());
            assertThat(inicial.foiSubstituida()).isFalse();
            assertThat(inicial.estaUtilizavelEm(AGORA)).isTrue();
        }

        @Test
        @DisplayName("a renovacao mantem a familia e marca a anterior como substituida")
        void rotacaoPreservaFamilia() {
            PessoaUsuaria pessoa = pessoaSalva();
            Sessao anterior = sessoes.saveAndFlush(sessaoInicialDe(pessoa));

            Sessao nova = Sessao.continuarFamilia(
                    pessoa.getId(),
                    anterior.getFamiliaId(),
                    "hash-token-2",
                    "Pixel 6",
                    AGORA,
                    AGORA.plus(Duration.ofDays(60)));
            sessoes.saveAndFlush(nova);
            anterior.substituirPor(nova);
            sessoes.saveAndFlush(anterior);

            assertThat(nova.getFamiliaId()).isEqualTo(anterior.getFamiliaId());
            assertThat(sessoes.findByFamiliaId(anterior.getFamiliaId())).hasSize(2);

            Sessao anteriorRelida = sessoes.findById(anterior.getId()).orElseThrow();
            assertThat(anteriorRelida.foiSubstituida()).isTrue();
            // Token ja rotacionado nao serve mais, mesmo sem revogacao explicita.
            assertThat(anteriorRelida.estaUtilizavelEm(AGORA)).isFalse();
        }

        @Test
        @DisplayName("o refresh token e localizado pelo hash")
        void buscaPeloHashDoToken() {
            Sessao sessao = sessoes.saveAndFlush(sessaoInicialDe(pessoaSalva()));

            assertThat(sessoes.findByRefreshTokenHash(sessao.getRefreshTokenHash()))
                    .get()
                    .isEqualTo(sessao);
        }

        @Test
        @DisplayName("o mesmo hash de token nao se repete entre sessoes")
        void hashDeTokenEhUnico() {
            PessoaUsuaria pessoa = pessoaSalva();
            sessoes.saveAndFlush(sessaoInicialDe(pessoa));

            Sessao colidente = Sessao.iniciarFamilia(
                    pessoa.getId(),
                    "hash-token-1",
                    "Outro aparelho",
                    AGORA,
                    AGORA.plus(Duration.ofDays(60)));

            assertThatThrownBy(() -> sessoes.saveAndFlush(colidente))
                    .isInstanceOf(DataIntegrityViolationException.class);
        }

        @Test
        @Transactional
        @DisplayName("revogar a familia derruba todas as sessoes ativas dela (R2)")
        void revogacaoEmMassaPorFamilia() {
            PessoaUsuaria pessoa = pessoaSalva();
            Sessao primeira = sessoes.saveAndFlush(sessaoInicialDe(pessoa));
            Sessao segunda = Sessao.continuarFamilia(
                    pessoa.getId(),
                    primeira.getFamiliaId(),
                    "hash-token-2",
                    "Pixel 6",
                    AGORA,
                    AGORA.plus(Duration.ofDays(60)));
            sessoes.saveAndFlush(segunda);

            // Sessao de outra familia: nao pode ser afetada.
            Sessao deOutraFamilia = sessoes.saveAndFlush(
                    Sessao.iniciarFamilia(
                            pessoa.getId(),
                            "hash-token-outra-familia",
                            "Tablet",
                            AGORA,
                            AGORA.plus(Duration.ofDays(60))));

            int revogadas = sessoes.revogarFamilia(primeira.getFamiliaId(), AGORA);

            assertThat(revogadas).isEqualTo(2);
            assertThat(sessoes.findById(primeira.getId()).orElseThrow().estaRevogada()).isTrue();
            assertThat(sessoes.findById(segunda.getId()).orElseThrow().estaRevogada()).isTrue();
            assertThat(sessoes.findById(deOutraFamilia.getId()).orElseThrow().estaRevogada())
                    .isFalse();
        }

        @Test
        @Transactional
        @DisplayName("trocar a senha derruba todas as sessoes da conta (FR-021)")
        void revogacaoDeTodasAsSessoesDaPessoa() {
            PessoaUsuaria pessoa = pessoaSalva();
            PessoaUsuaria outra = pessoaSalva();
            sessoes.saveAndFlush(sessaoInicialDe(pessoa));
            sessoes.saveAndFlush(
                    Sessao.iniciarFamilia(
                            pessoa.getId(),
                            "hash-token-2",
                            "Tablet",
                            AGORA,
                            AGORA.plus(Duration.ofDays(60))));
            Sessao daOutraPessoa = sessoes.saveAndFlush(
                    Sessao.iniciarFamilia(
                            outra.getId(),
                            "hash-token-3",
                            "Pixel",
                            AGORA,
                            AGORA.plus(Duration.ofDays(60))));

            int revogadas = sessoes.revogarSessoesDaPessoa(pessoa.getId(), AGORA);

            assertThat(revogadas).isEqualTo(2);
            assertThat(sessoes.findById(daOutraPessoa.getId()).orElseThrow().estaRevogada())
                    .isFalse();
        }

        @Test
        @DisplayName("revogar duas vezes preserva a data original")
        void revogacaoEhIdempotente() {
            Sessao sessao = sessaoInicialDe(pessoaSalva());
            sessao.revogar(AGORA);
            sessao.revogar(AGORA.plus(Duration.ofHours(1)));

            assertThat(sessao.getRevogadaEm()).isEqualTo(AGORA);
        }

        private Sessao sessaoInicialDe(PessoaUsuaria pessoa) {
            return Sessao.iniciarFamilia(
                    pessoa.getId(),
                    "hash-token-1",
                    "Pixel 6",
                    AGORA,
                    AGORA.plus(Duration.ofDays(60)));
        }
    }

    @Nested
    @DisplayName("Codigo de verificacao")
    class Codigo {

        @Test
        @DisplayName("o codigo e de uso unico (FR-020)")
        void usoUnico() {
            CodigoVerificacao codigo = codigoDe(canalSalvo());
            codigo.marcarComoUsado(AGORA);
            codigo.marcarComoUsado(AGORA.plus(Duration.ofMinutes(5)));

            assertThat(codigo.getUsadoEm()).isEqualTo(AGORA);
            assertThat(codigo.estaValidoEm(AGORA)).isFalse();
        }

        @Test
        @DisplayName("codigo expirado deixa de valer")
        void expira() {
            CanalContato canal = canalSalvo();
            CodigoVerificacao codigo = codigos.saveAndFlush(
                    new CodigoVerificacao(
                            canal.getId(),
                            FinalidadeDoCodigo.VERIFICACAO_POSSE,
                            "hash-codigo",
                            AGORA,
                            AGORA.plus(Duration.ofMinutes(10))));

            assertThat(codigo.estaValidoEm(AGORA.plus(Duration.ofMinutes(9)))).isTrue();
            assertThat(codigo.estaValidoEm(AGORA.plus(Duration.ofMinutes(10)))).isFalse();
        }

        @Test
        @DisplayName("apos o limite de tentativas o codigo morre")
        void limiteDeTentativas() {
            CodigoVerificacao codigo = codigoDe(canalSalvo());

            for (int i = 0; i < CodigoVerificacao.MAXIMO_DE_TENTATIVAS; i++) {
                assertThat(codigo.excedeuTentativas()).isFalse();
                codigo.registrarTentativaErrada();
            }

            assertThat(codigo.excedeuTentativas()).isTrue();
            assertThat(codigo.estaValidoEm(AGORA)).isFalse();
        }

        @Test
        @DisplayName("o mais recente da finalidade e o que vale")
        void buscaOMaisRecente() {
            CanalContato canal = canalSalvo();
            codigos.saveAndFlush(codigoDe(canal, "hash-antigo", AGORA));
            codigos.saveAndFlush(
                    codigoDe(canal, "hash-novo", AGORA.plus(Duration.ofMinutes(1))));

            assertThat(codigos
                            .findFirstByCanalIdAndFinalidadeOrderByCriadoEmDesc(
                                    canal.getId(), FinalidadeDoCodigo.VERIFICACAO_POSSE)
                            .orElseThrow()
                            .getCodigoHash())
                    .isEqualTo("hash-novo");
        }

        @Test
        @Transactional
        @DisplayName("emitir substituto invalida os pendentes da mesma finalidade")
        void invalidarPendentes() {
            CanalContato canal = canalSalvo();
            codigos.saveAndFlush(codigoDe(canal, "hash-1", AGORA));
            codigos.saveAndFlush(codigoDe(canal, "hash-2", AGORA));
            // Outra finalidade: nao pode ser tocada.
            codigos.saveAndFlush(
                    new CodigoVerificacao(
                            canal.getId(),
                            FinalidadeDoCodigo.RECUPERACAO_ACESSO,
                            "hash-recuperacao",
                            AGORA,
                            AGORA.plus(Duration.ofMinutes(10))));

            int invalidados = codigos.invalidarPendentes(
                    canal.getId(), FinalidadeDoCodigo.VERIFICACAO_POSSE, AGORA);

            assertThat(invalidados).isEqualTo(2);
            assertThat(codigos.findByCanalIdAndFinalidade(
                            canal.getId(), FinalidadeDoCodigo.RECUPERACAO_ACESSO))
                    .singleElement()
                    .matches(c -> !c.foiUsado(), "continua pendente");
        }

        private CanalContato canalSalvo() {
            return canais.saveAndFlush(
                    new CanalContato(
                            pessoaSalva().getId(),
                            TipoDeCanal.EMAIL,
                            "ana@exemplo.com",
                            "hash-do-canal",
                            true,
                            AGORA));
        }

        private CodigoVerificacao codigoDe(CanalContato canal) {
            return codigoDe(canal, "hash-codigo", AGORA);
        }

        private CodigoVerificacao codigoDe(CanalContato canal, String hash, Instant criadoEm) {
            return new CodigoVerificacao(
                    canal.getId(),
                    FinalidadeDoCodigo.VERIFICACAO_POSSE,
                    hash,
                    criadoEm,
                    criadoEm.plus(Duration.ofMinutes(10)));
        }
    }

    @Nested
    @DisplayName("Trilha de auditoria")
    class Trilha {

        @Test
        @DisplayName("registra tentativa sem conta, sem inventar id (FR-039)")
        void eventoSemConta() {
            EventoAutenticacao evento = eventos.saveAndFlush(
                    EventoAutenticacao.semConta(
                            TipoDeEvento.FALHA_ENTRADA,
                            ResultadoDoEvento.FALHA,
                            "hash-origem",
                            AGORA));

            assertThat(eventos.findById(evento.getId()).orElseThrow().getPessoaId()).isNull();
        }

        @Test
        @DisplayName("conta falhas recentes por conta, para o bloqueio progressivo")
        void contagemPorJanela() {
            PessoaUsuaria pessoa = pessoaSalva();
            eventos.saveAndFlush(falhaDe(pessoa.getId(), AGORA.minus(Duration.ofHours(2))));
            eventos.saveAndFlush(falhaDe(pessoa.getId(), AGORA.minus(Duration.ofMinutes(1))));

            long recentes = eventos.countByPessoaIdAndTipoAndOcorridoEmAfter(
                    pessoa.getId(),
                    TipoDeEvento.FALHA_ENTRADA,
                    AGORA.minus(Duration.ofMinutes(15)));

            assertThat(recentes).isEqualTo(1);
        }

        @Test
        @DisplayName("conta falhas por origem de rede, para o limite sem conta (R4)")
        void contagemPorOrigem() {
            eventos.saveAndFlush(
                    EventoAutenticacao.semConta(
                            TipoDeEvento.FALHA_ENTRADA,
                            ResultadoDoEvento.FALHA,
                            "hash-origem-suspeita",
                            AGORA));

            long daOrigem = eventos.countByOrigemHashAndTipoAndOcorridoEmAfter(
                    "hash-origem-suspeita",
                    TipoDeEvento.FALHA_ENTRADA,
                    AGORA.minus(Duration.ofMinutes(15)));

            assertThat(daOrigem).isEqualTo(1);
        }

        private EventoAutenticacao falhaDe(UUID pessoaId, Instant quando) {
            return EventoAutenticacao.de(
                    pessoaId,
                    TipoDeEvento.FALHA_ENTRADA,
                    ResultadoDoEvento.FALHA,
                    "hash-origem",
                    quando);
        }
    }
}

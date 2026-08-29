package br.fatec.memora.assistente.aplicacao;

import static org.assertj.core.api.Assertions.assertThat;

import br.fatec.memora.assistente.dominio.ServicoConhecido;
import br.fatec.memora.assistente.infra.ClienteDaAssistente;
import br.fatec.memora.assistente.infra.RepositorioServicoConhecido;
import br.fatec.memora.suporte.TesteComBanco;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

/**
 * A sugestao do modelo passa por uma porta que ele nao controla (T015).
 *
 * <h2>O que estes testes provam</h2>
 *
 * A FR-022 exige que a autorizacao seja determinstica e tomada fora do modelo.
 * Cada caso abaixo entrega ao autorizador uma sugestao que um modelo poderia
 * produzir — inclusive uma que so um modelo comprometido produziria — e verifica
 * o que o catalogo responde.
 *
 * <p>Nenhum destes testes precisa de um modelo de verdade, e isso e proposital:
 * o portao tem que valer para <b>qualquer</b> resposta, inclusive as que nenhum
 * modelo bem instruido daria.
 */
@DisplayName("Autorizador de acao — a FR-022")
class AutorizadorDeAcaoTest extends TesteComBanco {

    @Autowired
    private AutorizadorDeAcao autorizador;

    @Autowired
    private RepositorioServicoConhecido servicos;

    private static final String PACOTE_COTIDIANO = "com.whatsapp";

    @BeforeEach
    void semear() {
        servicos.save(
                ServicoConhecido.cotidiano(
                        "WhatsApp", PACOTE_COTIDIANO, "Mensagens", Instant.now()));
        servicos.save(
                ServicoConhecido.sensivel("Meu INSS", "Beneficios e aposentadoria", Instant.now()));
    }

    @AfterEach
    void limpar() {
        servicos.deleteAll();
    }

    @Test
    @DisplayName("aplicativo cotidiano e ativo: autoriza")
    void cotidianoAtivoEhAutorizado() {
        Optional<AutorizadorDeAcao.AcaoAutorizada> acao = autorizar(PACOTE_COTIDIANO);

        assertThat(acao).isPresent();
        assertThat(acao.get().nomeExibido()).isEqualTo("WhatsApp");
        assertThat(acao.get().identificadorAndroid()).isEqualTo(PACOTE_COTIDIANO);
    }

    @Test
    @DisplayName("pacote que nao esta no catalogo: recusa")
    void desconhecidoEhRecusado() {
        assertThat(autorizar("com.banco.qualquer")).isEmpty();
    }

    @Test
    @DisplayName("servico tirado do ar deixa de ser autorizavel no mesmo instante")
    void inativoEhRecusado() {
        ServicoConhecido whatsapp =
                servicos.findByIdentificadorAndroidAndAtivoTrue(PACOTE_COTIDIANO).orElseThrow();
        whatsapp.desativar(Instant.now());
        servicos.save(whatsapp);

        // Nao depende de publicar versao nova do aplicativo: e o que a R6
        // buscava ao por o catalogo no banco em vez de num arquivo compilado.
        assertThat(autorizar(PACOTE_COTIDIANO)).isEmpty();
    }

    @Test
    @DisplayName("servico sensivel nao tem pacote, entao a consulta nao o encontra")
    void sensivelNaoEhAlcancavel() {
        // O aplicativo do Meu INSS existe e a pessoa o usa. O que nao existe e
        // uma linha no catalogo que ligue um pacote a ele — a restricao do banco
        // impede que exista. A FR-041 se cumpre por ausencia de dado.
        assertThat(autorizar("br.gov.meuinss")).isEmpty();
    }

    @Test
    @DisplayName("sem sugestao nenhuma: nada a autorizar")
    void semSugestaoNadaAcontece() {
        assertThat(autorizador.autorizar(Optional.empty())).isEmpty();
    }

    @Test
    @DisplayName("sugestao vazia ou em branco e recusada")
    void sugestaoVaziaEhRecusada() {
        assertThat(autorizar("")).isEmpty();
        assertThat(autorizar("   ")).isEmpty();
    }

    @Test
    @DisplayName("espaco em volta do pacote nao burla o catalogo")
    void pacoteComEspacoEhNormalizado() {
        assertThat(autorizar("  " + PACOTE_COTIDIANO + "  ")).isPresent();
    }

    private Optional<AutorizadorDeAcao.AcaoAutorizada> autorizar(String pacote) {
        return autorizador.autorizar(
                Optional.of(new ClienteDaAssistente.Sugestao(pacote)));
    }
}

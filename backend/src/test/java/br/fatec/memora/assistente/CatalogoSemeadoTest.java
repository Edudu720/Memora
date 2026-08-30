package br.fatec.memora.assistente;

import static org.assertj.core.api.Assertions.assertThat;

import br.fatec.memora.assistente.dominio.CategoriaDoServico;
import br.fatec.memora.assistente.dominio.ServicoConhecido;
import br.fatec.memora.assistente.infra.RepositorioServicoConhecido;
import br.fatec.memora.suporte.TesteComBanco;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

/**
 * O catalogo semeado pela V5 respeita a regra das categorias (T044).
 *
 * <h2>Por que testar dados de migration</h2>
 *
 * Migration de seed nao e codigo executado a cada requisicao, e por isso passa
 * despercebida na revisao. Mas ela e <b>o conteudo da autorizacao</b>: uma
 * linha errada aqui — um banco marcado como COTIDIANO, um pacote colado no
 * servico errado — vale mais que qualquer bug de logica, porque o
 * {@code AutorizadorDeAcao} vai obedecer.
 *
 * <p>A restricao {@code ck_servico_sensivel_nao_abre} ja recusaria a
 * combinacao proibida na propria insercao. Estes testes cobrem o que ela nao
 * alcanca: se os servicos certos estao la, e se nenhum servico sensivel
 * consegue responder a consulta de autorizacao.
 */
@DisplayName("O catalogo semeado")
class CatalogoSemeadoTest extends TesteComBanco {

    @Autowired
    private RepositorioServicoConhecido servicos;

    @Test
    @DisplayName("nenhum servico sensivel pode ser aberto")
    void nenhumSensivelAbre() {
        List<ServicoConhecido> sensiveis =
                servicos.findByCategoriaAndAtivoTrueOrderByNomeExibido(
                        CategoriaDoServico.SENSIVEL);

        assertThat(sensiveis).isNotEmpty();
        for (ServicoConhecido servico : sensiveis) {
            assertThat(servico.podeSerAberto())
                    .as("%s esta abrivel", servico.getNomeExibido())
                    .isFalse();
            assertThat(servico.getIdentificadorAndroid())
                    .as("%s tem pacote gravado", servico.getNomeExibido())
                    .isEmpty();
        }
    }

    @Test
    @DisplayName("Gov.br e Meu INSS estao no catalogo, como servicos que so se ensinam")
    void servicosDoGovernoSaoSensiveis() {
        // Decisao do Eduardo, 2026-08-29: Gov.br na V5, Meu INSS na V6. Banco e
        // saude continuam fora, aguardando a equipe.
        assertThat(
                        servicos
                                .findByCategoriaAndAtivoTrueOrderByNomeExibido(
                                        CategoriaDoServico.SENSIVEL)
                                .stream()
                                .map(ServicoConhecido::getNomeExibido))
                .contains("Gov.br", "Meu INSS");
    }

    @Test
    @DisplayName("todo servico cotidiano tem pacote, senao nao haveria o que abrir")
    void cotidianosTemPacote() {
        List<ServicoConhecido> cotidianos =
                servicos.findByCategoriaAndAtivoTrueOrderByNomeExibido(
                        CategoriaDoServico.COTIDIANO);

        assertThat(cotidianos).isNotEmpty();
        for (ServicoConhecido servico : cotidianos) {
            assertThat(servico.getIdentificadorAndroid())
                    .as("%s sem pacote", servico.getNomeExibido())
                    .isPresent();
            assertThat(servico.podeSerAberto()).isTrue();
        }
    }

    @Test
    @DisplayName("os aplicativos mais usados por pessoas 60+ estao no catalogo")
    void osMaisUsadosEstaoLa() {
        // WhatsApp tem 58,7% de penetracao entre pessoas de 60 anos ou mais no
        // Brasil, e o Instagram 26,3%. Um catalogo sem eles atenderia mal a
        // maior parte do publico do Memora.
        assertThat(
                        servicos.findByAtivoTrueOrderByNomeExibido().stream()
                                .map(ServicoConhecido::getNomeExibido))
                .contains("WhatsApp", "Instagram", "Facebook", "YouTube");
    }

    @Test
    @DisplayName("o pacote de cada aplicativo e o de verdade")
    void pacotesConferem() {
        // Pacote errado abre OUTRO aplicativo, ou nenhum. Um erro de digitacao
        // aqui e invisivel ate alguem tocar no botao.
        assertThat(pacoteDe("WhatsApp")).isEqualTo("com.whatsapp");
        assertThat(pacoteDe("Instagram")).isEqualTo("com.instagram.android");
        assertThat(pacoteDe("Facebook")).isEqualTo("com.facebook.katana");
        assertThat(pacoteDe("YouTube")).isEqualTo("com.google.android.youtube");
    }

    private String pacoteDe(String nome) {
        return servicos.findByAtivoTrueOrderByNomeExibido().stream()
                .filter(servico -> servico.getNomeExibido().equals(nome))
                .findFirst()
                .flatMap(ServicoConhecido::getIdentificadorAndroid)
                .orElseThrow(() -> new AssertionError(nome + " nao esta no catalogo"));
    }
}

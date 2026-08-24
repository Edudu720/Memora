package br.fatec.memora.autenticacao.infra;

import br.fatec.memora.autenticacao.aplicacao.EnviadorDeCodigo;
import br.fatec.memora.autenticacao.dominio.CanalContato;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Adaptador de desenvolvimento: escreve o código no log em vez de enviá-lo
 * (T058).
 *
 * <h2>Ele registra o código em claro, e isso é inaceitável em produção</h2>
 *
 * Todo o cuidado de {@code CodigoVerificacao} — hash, prazo, uso único — existe
 * para que o código não fique legível em lugar nenhum. Esta classe o escreve num
 * arquivo que costuma ser lido por mais gente, retido por mais tempo e copiado
 * para mais máquinas que o banco de dados.
 *
 * <p>Por isso ela é {@code @Profile("!producao")}. Com o perfil {@code producao}
 * ativo, este bean não existe, nenhum outro {@link EnviadorDeCodigo} foi
 * escrito ainda, e a aplicação <b>não sobe</b> — falha na subida, não na
 * primeira pessoa que tentar confirmar um canal.
 *
 * <p>Isso é deliberado, e diverge do padrão usado em {@code ConfiguracaoDeToken}
 * e {@code ConfiguracaoDeRastreio}, onde a falta de configuração sorteia um
 * valor e segue com um WARN. Lá o prejuízo é interno e reversível: sessões caem,
 * uma contagem zera. Aqui, seguir adiante significaria responder {@code 202}
 * — "código enviado" — a uma pessoa que nunca receberá código nenhum, e deixá-la
 * presa numa tela esperando uma mensagem que não vem.
 */
@Component
@Profile("!producao")
public class EnviadorDeCodigoEmLog implements EnviadorDeCodigo {

    private static final Logger LOG = LoggerFactory.getLogger(EnviadorDeCodigoEmLog.class);

    @PostConstruct
    void avisar() {
        LOG.warn(
                "Nenhum provedor de envio configurado: os codigos de verificacao serao "
                        + "escritos NO LOG, em claro. Isto e um adaptador de desenvolvimento "
                        + "e nao existe no perfil 'producao'.");
    }

    @Override
    public void enviar(CanalContato canal, String codigoEmClaro) {
        LOG.info(
                "Codigo de verificacao do canal {} ({}): {}",
                canal.getId(),
                canal.getTipo(),
                codigoEmClaro);
    }
}

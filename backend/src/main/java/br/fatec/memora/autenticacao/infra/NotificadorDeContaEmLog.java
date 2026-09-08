package br.fatec.memora.autenticacao.infra;

import br.fatec.memora.autenticacao.aplicacao.NotificadorDeConta;
import br.fatec.memora.autenticacao.dominio.CanalContato;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Escreve o aviso no log, em desenvolvimento (T068).
 *
 * <h2>A mesma lacuna do {@code EnviadorDeCodigoEmLog}, e o mesmo tratamento</h2>
 *
 * Não há provedor de e-mail nem de SMS no projeto (T065a). Este adaptador não
 * existe no perfil {@code producao}, e sem substituto a aplicação <b>não
 * sobe</b> lá — de propósito. Trocar senha sem avisar ninguém é pior que não
 * subir: a FR-022 seria uma linha de documentação, e o golpe que ela existe para
 * revelar passaria em silêncio.
 *
 * <h2>Diferente do código, aqui não há segredo a vazar</h2>
 *
 * O {@code EnviadorDeCodigoEmLog} imprime um código em claro e por isso carrega
 * um risco real. Este imprime só o identificador do canal — nunca o valor dele,
 * que é Confidencial pela FR-040. O que o log revela é que <i>houve</i> uma
 * troca de senha, e isso a trilha de auditoria já registra.
 */
@Component
@Profile("!producao")
public class NotificadorDeContaEmLog implements NotificadorDeConta {

    private static final Logger LOG = LoggerFactory.getLogger(NotificadorDeContaEmLog.class);

    @PostConstruct
    void avisar() {
        LOG.warn(
                "Nenhum provedor de notificacao configurado: os avisos de conta serao "
                        + "escritos NO LOG. Isto e um adaptador de desenvolvimento e nao "
                        + "existe no perfil 'producao'.");
    }

    @Override
    public void avisarSenhaAlterada(CanalContato canal, String nomeTratamento) {
        LOG.info(
                "Aviso de senha alterada para o canal {} ({}). Destinatario: {}",
                canal.getId(),
                canal.getTipo(),
                nomeTratamento);
    }
}

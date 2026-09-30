package br.fatec.memora.assistente.seguranca;

import br.fatec.memora.assistente.dominio.UsoDaAssistente;
import br.fatec.memora.assistente.infra.RepositorioUsoDaAssistente;
import java.time.Clock;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Teto diário de conversas por conta (R7 do research).
 *
 * <h2>Por que isto existe, se a spec não pediu</h2>
 *
 * É consequência direta de haver um endpoint autenticado que <b>gasta dinheiro
 * por chamada</b>. Sem teto, uma conta comprometida esgota a cota do provedor e
 * derruba a assistente para todo mundo — uma negação de serviço que se paga em
 * reais, e que ninguém percebe até a fatura.
 *
 * <p>Fica registrado como decisão de arquitetura. Ele <b>muda o que a pessoa
 * vê</b> quando alguém esbarra nele, e se a equipe entender que isso é
 * comportamento, o lugar de resolver é a spec.
 *
 * <h2>Estado no banco, como o LimitadorTentativas</h2>
 *
 * Contador em memória zera no reinício do processo, e quem quiser contorná-lo só
 * precisa esperar um deploy. O mesmo raciocínio que levou o limitador da feature
 * 001 para o banco vale aqui.
 *
 * <h2>Transação própria, e por quê</h2>
 *
 * {@link #registrarConversa} abre transação nova ({@code REQUIRES_NEW}) pelo
 * mesmo motivo que a auditoria de recusa: se a conversa falhar depois — o
 * provedor cair, a rede morrer —, o rollback dessa falha <b>não pode</b> devolver
 * a cota gasta. A chamada ao provedor já foi feita e já custou.
 *
 * <p>O preço é uma segunda conexão do pool durante a gravação, como já acontece
 * no {@code RegistroDeAuditoria}. É o que motivou
 * {@code spring.datasource.hikari.maximum-pool-size} estar explícito em 20.
 */
@Component
public class LimitePorConta {

    /**
     * Teto padrão de conversas por dia.
     *
     * <p>Decidido na FR-053 (2026-09-30): vinte, ajustável por
     * {@code memora.assistente.conversas-por-dia} sem nova versão do
     * aplicativo, e revisto depois do teste com as 5 pessoas de 65+. O pior dia
     * de uma conta comprometida é 20 × {@link UsoDaAssistente#TURNOS_POR_CONVERSA}
     * turnos.
     */
    public static final int TETO_PADRAO = 20;

    private final RepositorioUsoDaAssistente usos;
    private final Clock relogio;
    private final int teto;

    /** Cria o limitador. */
    public LimitePorConta(
            RepositorioUsoDaAssistente usos,
            Clock relogio,
            @Value("${memora.assistente.conversas-por-dia:" + TETO_PADRAO + "}") int teto) {
        this.usos = usos;
        this.relogio = relogio;
        this.teto = teto;
    }

    /**
     * Registra um turno e diz se ele pode seguir (FR-053).
     *
     * <p>Quem decide se o turno continua a conversa ou abre outra é
     * {@link UsoDaAssistente#registrarTurno}; aqui só se carrega, grava e
     * devolve.
     *
     * <p>⚠️ Não há trava de linha: dois turnos simultâneos da mesma conta leem o
     * mesmo estado, e o teto pode ser passado por um. Já era assim antes da
     * FR-053. Para uma pessoa digitando é inalcançável; para um robô, a
     * diferença é de uma conversa — e fechar isso é trava pessimista na
     * consulta, não mudança aqui.
     *
     * <p>Chame <b>antes</b> de falar com o provedor, e não depois: contar só o
     * que deu certo permitiria gastar a cota inteira em chamadas que falham no
     * fim, que é exatamente o que um atacante faria.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public UsoDaAssistente.Desfecho registrarTurno(UUID pessoaId) {
        LocalDate hoje = hoje();
        UsoDaAssistente uso =
                usos.findByPessoaIdAndDia(pessoaId, hoje)
                        .orElseGet(() -> UsoDaAssistente.primeiroDoDia(pessoaId, hoje));
        UsoDaAssistente.Desfecho desfecho = uso.registrarTurno(relogio.instant(), teto);
        if (desfecho != UsoDaAssistente.Desfecho.TETO_ATINGIDO) {
            usos.save(uso);
        }
        return desfecho;
    }

    /** Quantas conversas ainda cabem hoje. */
    @Transactional(readOnly = true)
    public int restantesHoje(UUID pessoaId) {
        int usadas =
                usos.findByPessoaIdAndDia(pessoaId, hoje())
                        .map(UsoDaAssistente::getConversas)
                        .orElse(0);
        return Math.max(0, teto - usadas);
    }

    /** O teto configurado. */
    public int teto() {
        return teto;
    }

    private LocalDate hoje() {
        return LocalDate.now(relogio);
    }
}

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
     * <p><b>Número provisório</b>: a pendência 3 do research pede que a equipe o
     * defina, e ninguém tem uso real para medir ainda. Vinte é generoso o
     * bastante para não incomodar quem usa o produto como ele foi pensado, e
     * baixo o bastante para uma conta comprometida não esvaziar a cota.
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

    /** A conta já esgotou a cota de hoje? */
    @Transactional(readOnly = true)
    public boolean atingiuOTeto(UUID pessoaId) {
        return usos.findByPessoaIdAndDia(pessoaId, hoje())
                .map(uso -> uso.atingiu(teto))
                .orElse(false);
    }

    /**
     * Conta mais uma conversa aberta hoje.
     *
     * <p>Chame <b>antes</b> de falar com o provedor, e não depois: contar só o
     * que deu certo permitiria gastar a cota inteira em chamadas que falham no
     * fim, que é exatamente o que um atacante faria.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void registrarConversa(UUID pessoaId) {
        LocalDate hoje = hoje();
        UsoDaAssistente uso =
                usos.findByPessoaIdAndDia(pessoaId, hoje)
                        .orElseGet(() -> UsoDaAssistente.primeiroDoDia(pessoaId, hoje));
        uso.registrarConversa();
        usos.save(uso);
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

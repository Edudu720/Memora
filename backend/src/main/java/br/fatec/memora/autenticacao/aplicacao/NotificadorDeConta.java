package br.fatec.memora.autenticacao.aplicacao;

import br.fatec.memora.autenticacao.dominio.CanalContato;

/**
 * Avisa a pessoa quando algo importante acontece com a conta dela (T068, FR-022).
 *
 * <h2>Por que a troca de senha precisa ser avisada</h2>
 *
 * A FR-022 existe para um caso específico: alguém trocou a senha, e não foi a
 * pessoa. Sem aviso, a única forma de ela descobrir é tentar entrar e não
 * conseguir — momento em que ela vai supor que errou a digitação, tentar mais
 * quatro vezes, e cair no bloqueio progressivo. O golpe fica invisível e a
 * pessoa fica trancada para fora, culpando a si mesma.
 *
 * <p>O aviso inverte isso: chega no canal <b>dela</b>, no instante da troca, e
 * diz o que aconteceu. Para o público desta feature, é a diferença entre
 * perceber em minutos e perceber em semanas.
 *
 * <h2>Onde esta porta mora, e por que não em {@code infra/}</h2>
 *
 * A T068 escreve {@code infra/NotificadorDeConta.java}, mas a porta fica aqui,
 * ao lado de {@link EnviadorDeCodigo}, e o adaptador é que vai para
 * {@code infra/}. É a mesma divisão que a feature já usa e o que o Princípio V
 * pede: a camada de aplicação declara o que precisa, a de infraestrutura resolve
 * como. Inverter faria a aplicação depender de infraestrutura para enxergar a
 * própria dependência.
 *
 * <h2>Isto não é canal de mão dupla</h2>
 *
 * O aviso <b>informa</b>; ele nunca pede nada. Nada do que sai por aqui pode
 * conter link de ação, código, ou pedido de confirmação — a FR-023 e o aviso
 * antigolpe da tela dizem à pessoa que o Memora nunca pede senha por mensagem,
 * e uma notificação que peça qualquer coisa desmente exatamente a lição que o
 * produto passa a vida ensinando.
 */
public interface NotificadorDeConta {

    /**
     * Avisa que a senha da conta acabou de ser alterada (FR-022).
     *
     * @param canal canal verificado de destino
     * @param nomeTratamento como a pessoa quer ser chamada, para o texto do aviso
     */
    void avisarSenhaAlterada(CanalContato canal, String nomeTratamento);
}

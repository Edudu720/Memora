package br.fatec.memora.autenticacao.aplicacao;

import br.fatec.memora.autenticacao.dominio.CanalContato;

/**
 * Entrega o código de verificação à pessoa, pelo canal dela (T058).
 *
 * <h2>Esta interface existe porque a feature 001 não especificou o envio</h2>
 *
 * Nenhuma tarefa do {@code tasks.md} implementa envio de e-mail ou SMS — o
 * {@code plan.md} cita "envio de código, provedores" ao desenhar a pasta
 * {@code infra/}, e nada mais. Sem provedor, o modo assistido não fecha o ciclo
 * de ponta a ponta: o código é criado, gravado hasheado e nunca chega a
 * ninguém.
 *
 * <p>A porta fica declarada aqui para que essa lacuna seja <b>uma dependência
 * que falta</b>, e não uma chamada esquecida no meio de um serviço. Trocar o
 * adaptador de desenvolvimento por um provedor real não toca em regra de
 * negócio nenhuma.
 *
 * <h2>O código em claro passa por aqui, e só por aqui</h2>
 *
 * Quem implementar esta interface recebe o único momento em que o código existe
 * legível — no banco ele já está hasheado. Implementação que registre esse valor
 * em log, métrica ou rastro de erro anula a proteção inteira: o log é lido por
 * mais gente e retido por mais tempo que o banco.
 */
public interface EnviadorDeCodigo {

    /**
     * Envia o código pelo canal informado.
     *
     * @param canal canal de destino, com o valor já normalizado
     * @param codigoEmClaro os 6 dígitos; nunca deve ser registrado nem devolvido
     */
    void enviar(CanalContato canal, String codigoEmClaro);
}

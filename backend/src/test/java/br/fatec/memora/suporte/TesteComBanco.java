package br.fatec.memora.suporte;

import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.PostgreSQLContainer;

/**
 * Base dos testes que precisam de banco de verdade.
 *
 * <h2>Por que PostgreSQL real e nao H2</h2>
 *
 * Metade do que este esquema garante nao existe em banco em memoria: o gatilho
 * que recusa alteracao na trilha de auditoria, as restricoes CHECK dos enums e o
 * comportamento de UUID e TIMESTAMPTZ. Testar contra H2 aprovaria migration que
 * quebra em producao.
 *
 * <h2>Um container para a suite inteira</h2>
 *
 * O container e {@code static} e iniciado no bloco estatico, sem
 * {@code @Container} — o padrao "singleton container". Assim o JUnit nao amarra
 * o ciclo de vida a uma classe, e todas as classes que herdam desta compartilham
 * a mesma instancia. O Ryuk do Testcontainers derruba tudo ao fim da JVM.
 *
 * <p>Subir um PostgreSQL por classe custaria cerca de 15 s cada.
 *
 * <h2>Por que {@code max_connections=200}</h2>
 *
 * O container e um so, mas os <b>contextos Spring</b> nao. Toda classe com
 * {@code @TestConfiguration} ou {@code @TestPropertySource} ganha contexto
 * proprio, e cada contexto abre o seu Hikari com
 * {@code maximum-pool-size=20} — o valor explicito que o {@code REQUIRES_NEW}
 * da auditoria obriga.
 *
 * <p>Com o padrao do PostgreSQL ({@code max_connections=100}, tres delas
 * reservadas ao superusuario), cinco contextos ja nao cabem. Foi exatamente o
 * que aconteceu ao acrescentar o {@code LimiteDeConversasTest}: ele virou o
 * quinto, e o CI reprovou com <b>{@code FATAL: sorry, too many clients
 * already}</b> — dezoito erros numa classe de recuperacao de acesso que nao
 * tinha sido tocada, porque o contexto <i>dela</i> foi o que nao conseguiu
 * subir.
 *
 * <p>O sintoma engana de proposito: ele aparece longe da causa, e na classe
 * errada. Se voltar a aparecer, a pergunta e "quantos contextos existem
 * agora?", e nao "o que essa classe quebrou?".
 *
 * <p>Isto e limite de <b>infraestrutura de teste</b>, nao do produto. O teto
 * de conexoes da aplicacao continua sendo o pool de 20.
 */
@SpringBootTest
public abstract class TesteComBanco {

    @ServiceConnection
    protected static final PostgreSQLContainer<?> POSTGRES =
            new PostgreSQLContainer<>("postgres:16")
                    .withCommand("postgres", "-c", "max_connections=200");

    static {
        POSTGRES.start();
    }
}

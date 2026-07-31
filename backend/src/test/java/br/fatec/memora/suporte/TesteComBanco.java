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
 */
@SpringBootTest
public abstract class TesteComBanco {

    @ServiceConnection
    protected static final PostgreSQLContainer<?> POSTGRES =
            new PostgreSQLContainer<>("postgres:16");

    static {
        POSTGRES.start();
    }
}

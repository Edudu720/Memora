package br.fatec.memora;

import br.fatec.memora.suporte.TesteComBanco;
import org.junit.jupiter.api.Test;

/**
 * O contexto sobe contra um PostgreSQL real e descartavel.
 *
 * <h2>Este teste vale mais do que parece</h2>
 *
 * Com {@code spring.jpa.hibernate.ddl-auto=validate}, subir o contexto obriga o
 * Hibernate a comparar <b>cada entidade</b> com o esquema criado pelo Flyway.
 * Coluna renomeada na migration e esquecida na entidade, tipo trocado, tabela
 * ausente: qualquer divergencia derruba esta subida.
 *
 * <p>Ou seja, este metodo vazio e o portao que mantem migration e entidade em
 * acordo.
 */
class MemoraApplicationTests extends TesteComBanco {

    @Test
    void contextLoads() {
    }
}

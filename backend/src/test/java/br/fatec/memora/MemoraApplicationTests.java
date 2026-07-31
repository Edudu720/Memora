package br.fatec.memora;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * O contexto sobe contra um PostgreSQL real e descartavel (Testcontainers),
 * o mesmo padrao dos testes de integracao das fases seguintes. Sem banco,
 * o Spring Data JPA nao consegue montar o datasource e o contexto nao carrega.
 */
@SpringBootTest
@Testcontainers
class MemoraApplicationTests {

	@Container
	@ServiceConnection
	static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");

	@Test
	void contextLoads() {
	}

}

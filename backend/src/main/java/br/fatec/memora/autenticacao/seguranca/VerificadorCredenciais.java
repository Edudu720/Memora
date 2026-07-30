package br.fatec.memora.autenticacao.seguranca;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Confere a senha sem revelar se a conta existe (T022, R3).
 *
 * <h2>O ataque que isto impede</h2>
 *
 * Mensagem de erro idêntica para "conta não existe" e "senha errada" não basta.
 * Se o servidor só executa o Argon2 quando encontra a conta, a resposta para
 * identificador inexistente volta em poucos milissegundos, e a resposta para
 * conta existente com senha errada leva os ~240 ms do hash. Essa diferença é
 * medível de fora, e transforma o endereço de login em uma lista de quem usa o
 * Memora.
 *
 * <p>Para o público desta feature isso não é abstrato: uma lista confirmada de
 * pessoas idosas cadastradas em um aplicativo de acessibilidade é matéria-prima
 * de golpe telefônico.
 *
 * <h2>A defesa</h2>
 *
 * Quando não há hash armazenado, a comparação roda contra um <b>hash
 * fictício</b>. O custo é o mesmo, então o tempo é o mesmo.
 *
 * <p>O hash fictício é produzido no construtor pelo <b>mesmo</b>
 * {@link PasswordEncoder} dos hashes reais. Escrevê-lo como constante no código
 * seria pior do que parece: um hash Argon2 carrega os próprios parâmetros, e um
 * fictício gerado com memória menor custaria menos que os reais — a diferença de
 * tempo voltaria por outra porta.
 */
@Component
public class VerificadorCredenciais {

    /**
     * Senha de mentira, usada só para produzir o hash fictício.
     *
     * <p>Não é segredo e não precisa ser: ela nunca confere com nada, porque só
     * é usada como o <i>lado armazenado</i> da comparação.
     */
    private static final String SENHA_DE_MENTIRA =
            "conta-inexistente-do-memora-nunca-confere";

    private final PasswordEncoder codificador;

    /** Mesmos parâmetros dos hashes reais, por construção. */
    private final String hashFicticio;

    public VerificadorCredenciais(PasswordEncoder codificador) {
        this.codificador = codificador;
        this.hashFicticio = codificador.encode(SENHA_DE_MENTIRA);
    }

    /**
     * Confere a senha apresentada.
     *
     * @param hashArmazenado hash da conta, ou {@code null} quando a conta não
     *     existe ou usa apenas login social
     * @return {@code true} somente quando a conta existe e a senha confere
     */
    public boolean confere(String senhaApresentada, String hashArmazenado) {
        if (hashArmazenado == null) {
            // Gasta o mesmo tempo e descarta o resultado. O `false` não vem de
            // um atalho: vem de a senha não conferir com o hash fictício.
            return codificador.matches(senhaApresentada, hashFicticio);
        }
        return codificador.matches(senhaApresentada, hashArmazenado);
    }
}

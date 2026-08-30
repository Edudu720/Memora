package br.fatec.memora.autenticacao.seguranca;

import java.security.SecureRandom;
import org.springframework.stereotype.Component;

/**
 * Sorteia o código de 6 dígitos que confirma posse de canal (T058, R5).
 *
 * <h2>Seis dígitos, e o que isso custa</h2>
 *
 * São 10<sup>6</sup> combinações — pouco, comparado a qualquer segredo
 * criptográfico. O tamanho não foi escolhido por segurança e sim por
 * usabilidade: é o que uma pessoa idosa consegue ler numa mensagem e digitar
 * noutra tela sem perder o fio. As três proteções que compensam o espaço
 * pequeno estão em {@code CodigoVerificacao}: prazo de 10 minutos, uso único e
 * limite de 5 tentativas.
 *
 * <h2>Zero à esquerda é dígito</h2>
 *
 * O sorteio é sobre o intervalo inteiro {@code [0, 999999]} e o resultado é
 * formatado com {@code %06d}. Descartar valores baixos para "ficar bonito" —
 * sortear de 100000 a 999999 — jogaria fora 10% do espaço e tornaria o primeiro
 * dígito previsivelmente diferente de zero.
 *
 * <h2>{@link SecureRandom}, não {@code Random}</h2>
 *
 * {@code Random} é um gerador linear cujo estado interno se reconstrói a partir
 * de duas saídas observadas. Quem pedisse dois códigos para um canal próprio
 * passaria a prever os códigos dos outros.
 */
@Component
public class GeradorDeCodigoNumerico {

    /** Quantidade de dígitos que a pessoa digita. Combina com o contrato. */
    public static final int DIGITOS = 6;

    private static final int LIMITE_EXCLUSIVO = 1_000_000;

    private final SecureRandom sorteio = new SecureRandom();

    /** Um código novo, sempre com {@value #DIGITOS} dígitos. */
    public String gerar() {
        return "%06d".formatted(sorteio.nextInt(LIMITE_EXCLUSIVO));
    }
}

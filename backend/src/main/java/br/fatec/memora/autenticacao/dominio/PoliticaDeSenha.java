package br.fatec.memora.autenticacao.dominio;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;

/**
 * A regra que decide se uma senha pode ser usada (T034, FR-042).
 *
 * <h2>Comprimento acima de complexidade — e por quê</h2>
 *
 * A FR-042 manda priorizar comprimento sobre complexidade simbólica, e para este
 * público isso não é preferência de estilo. Exigir maiúscula, número e símbolo
 * produz {@code Senha@123} — curta, previsível e presente em todo vazamento — e
 * empurra quem tem dificuldade com o teclado a escrever a senha num papel ao
 * lado do aparelho. Dez caracteres livres resistem mais e são digitáveis por
 * alguém de 78 anos.
 *
 * <p>Por isso aqui só existem <b>duas</b> regras, e nenhuma delas fala de
 * símbolo:
 *
 * <ol>
 *   <li>pelo menos {@value #COMPRIMENTO_MINIMO} caracteres;
 *   <li>não estar na lista de senhas notoriamente comprometidas.
 * </ol>
 *
 * <h2>As mesmas duas regras que a tela mostra</h2>
 *
 * O aplicativo exibe exatamente estas duas em {@code RegraDeSenha.todas}, com o
 * mesmo piso de 10. <b>Divergir daqui seria um defeito garantido</b>: a tela
 * habilitaria o botão e o servidor recusaria, e a pessoa ficaria sem entender o
 * que fez de errado. O servidor revalida por autoridade (FR-038), não porque
 * duvida da tela.
 *
 * <h2>Sobre a lista de comprometidas</h2>
 *
 * Vem de {@code seguranca/senhas-comprometidas.txt}, carregada uma vez. É
 * deliberadamente curta: cobre o topo de vazamento publicado e o que é comum no
 * Brasil, não o vazamento inteiro.
 *
 * <p><b>Decisão em aberto</b>: cobrir de verdade exigiria consultar um serviço
 * externo — por exemplo por <i>k-anonimato</i>, enviando só o prefixo do resumo
 * da senha. Isso acrescenta chamada de rede no caminho do cadastro e uma questão
 * de privacidade que ninguém decidiu ainda, e a pesquisa não trata do assunto.
 * A troca fica isolada nesta classe: quem decidir mexe só em
 * {@link #comprometida}.
 */
public final class PoliticaDeSenha {

    /**
     * Piso de comprimento.
     *
     * <p>Dez, e não oito: oito é o mínimo do NIST para senha com outras defesas
     * em volta, e aqui a senha é a única credencial de quem não usa gerenciador.
     */
    public static final int COMPRIMENTO_MINIMO = 10;

    private static final String ARQUIVO = "/seguranca/senhas-comprometidas.txt";

    private static final Set<String> COMPROMETIDAS = carregar();

    private PoliticaDeSenha() {}

    /** Por que uma senha foi recusada. */
    public enum Recusa {

        /** Menor que {@link #COMPRIMENTO_MINIMO}. */
        CURTA,

        /** Está na lista de senhas notoriamente comprometidas. */
        COMPROMETIDA
    }

    /**
     * Avalia a senha.
     *
     * <p>Devolve o motivo em vez de lançar exceção: quem chama precisa
     * transformá-lo em mensagem para a pessoa, e o motivo é dado, não falha.
     *
     * @return o motivo da recusa, ou {@code null} quando a senha serve
     */
    public static Recusa avaliar(String senha) {
        if (senha == null || senha.length() < COMPRIMENTO_MINIMO) {
            return Recusa.CURTA;
        }
        if (comprometida(senha)) {
            return Recusa.COMPROMETIDA;
        }
        return null;
    }

    /** Atalho para quem só precisa do sim ou não. */
    public static boolean aceita(String senha) {
        return avaliar(senha) == null;
    }

    /**
     * Comparação sem diferenciar maiúsculas.
     *
     * <p>{@code Senha123456} e {@code senha123456} são a mesma escolha do ponto
     * de vista de quem ataca: as duas estão em qualquer dicionário com as
     * variações de caixa aplicadas. Recusar as duas custa nada e fecha o desvio
     * mais óbvio da lista.
     */
    private static boolean comprometida(String senha) {
        return COMPROMETIDAS.contains(senha.toLowerCase(Locale.ROOT));
    }

    /**
     * Lê a lista do classpath.
     *
     * <p>Falha na subida se o arquivo sumir. Uma lista vazia por engano faria a
     * segunda regra virar decoração sem que nada acusasse — o tipo de defeito
     * que só aparece depois de um vazamento.
     */
    private static Set<String> carregar() {
        try (InputStream entrada = PoliticaDeSenha.class.getResourceAsStream(ARQUIVO)) {
            if (entrada == null) {
                throw new IllegalStateException("Lista de senhas comprometidas ausente: " + ARQUIVO);
            }

            Set<String> lidas = new HashSet<>();
            try (BufferedReader leitor =
                    new BufferedReader(new InputStreamReader(entrada, StandardCharsets.UTF_8))) {
                String linha;
                while ((linha = leitor.readLine()) != null) {
                    String senha = linha.trim();
                    if (!senha.isEmpty() && !senha.startsWith("#")) {
                        lidas.add(senha.toLowerCase(Locale.ROOT));
                    }
                }
            }

            if (lidas.isEmpty()) {
                throw new IllegalStateException("Lista de senhas comprometidas vazia: " + ARQUIVO);
            }
            return Set.copyOf(lidas);

        } catch (IOException falhaDeLeitura) {
            throw new UncheckedIOException(falhaDeLeitura);
        }
    }
}

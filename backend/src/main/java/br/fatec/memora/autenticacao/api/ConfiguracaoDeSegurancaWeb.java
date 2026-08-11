package br.fatec.memora.autenticacao.api;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Quem entra sem credencial, e quem não entra (T033).
 *
 * <h2>Fechado por padrão</h2>
 *
 * A última regra é {@code anyRequest().authenticated()}. Endpoint novo nasce
 * protegido: quem precisar abri-lo tem de escrever isso aqui, de propósito, e
 * essa linha aparece na revisão. O contrário — aberto por padrão, fechado por
 * lembrança — publica endpoint desprotegido no dia em que alguém esquecer.
 *
 * <p>O cadastro é público pelo motivo óbvio: quem ainda não tem conta não tem
 * como se autenticar para criá-la.
 *
 * <h2>Sem sessão de servidor, e por isso sem CSRF</h2>
 *
 * A autenticação é por token no cabeçalho, guardado pelo aplicativo em
 * armazenamento seguro (FR-036). Não há cookie de sessão — e CSRF é um ataque
 * que depende de o navegador anexar credencial sozinho. Sem cookie, não há o que
 * o atacante consiga fazer o navegador enviar.
 *
 * <p><b>Isto deixa de valer no dia em que existir cookie</b>, inclusive de
 * "lembrar de mim" ou de um painel web. Quem acrescentar cookie precisa
 * reativar a proteção na mesma mudança.
 *
 * <p>{@code STATELESS} não é redundante com o acima: sem ele o Spring cria
 * {@code HttpSession} ao autenticar, e passaria a existir o cookie que este
 * raciocínio inteiro presume não existir.
 */
@Configuration
public class ConfiguracaoDeSegurancaWeb {

    /** Caminho do cadastro, como o contrato o publica. */
    public static final String CAMINHO_CADASTRO = "/v1/auth/cadastro";

    @Bean
    SecurityFilterChain cadeiaDeSeguranca(HttpSecurity http) throws Exception {
        return http.csrf(csrf -> csrf.disable())
                .sessionManagement(
                        sessao -> sessao.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(
                        rotas ->
                                rotas.requestMatchers(HttpMethod.POST, CAMINHO_CADASTRO)
                                        .permitAll()
                                        .anyRequest()
                                        .authenticated())
                // Sem formulario de login e sem Basic: este servidor responde a
                // um aplicativo, e o desafio "WWW-Authenticate" do Basic faz o
                // navegador abrir uma caixa de dialogo que nao pertence a
                // lugar nenhum deste produto.
                .httpBasic(basico -> basico.disable())
                .formLogin(formulario -> formulario.disable())
                .anonymous(Customizer.withDefaults())
                .build();
    }
}

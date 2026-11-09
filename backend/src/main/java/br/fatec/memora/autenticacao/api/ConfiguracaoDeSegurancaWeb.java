package br.fatec.memora.autenticacao.api;

import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import br.fatec.memora.autenticacao.seguranca.EmissorDeTokenDeAcesso;
import br.fatec.memora.autenticacao.seguranca.FiltroDeTokenDeAcesso;
import jakarta.servlet.DispatcherType;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import tools.jackson.databind.ObjectMapper;

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
 * como se autenticar para criá-la. A entrada e a renovação são públicas pelo
 * mesmo motivo em outra forma — são elas que <b>produzem</b> a credencial, e
 * nenhuma delas confia em quem chama: uma exige a senha, a outra um refresh
 * token que confere com o hash gravado.
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

    /** Caminho da entrada (T047). */
    public static final String CAMINHO_ENTRAR = "/v1/auth/entrar";

    /**
     * Caminho da renovação de sessão (T048).
     *
     * <p>Público, e isso não é descuido: quem chega aqui está justamente com o
     * token de acesso vencido — exigir autenticação para renovar seria exigir o
     * que a operação existe para devolver. Quem autentica a chamada é o refresh
     * token no corpo, conferido contra o hash gravado.
     */
    public static final String CAMINHO_RENOVAR = "/v1/auth/sessao/renovar";

    /**
     * Caminho da solicitação de recuperação (T066).
     *
     * <p>Público pelo motivo mais direto de todos: quem esqueceu a senha não tem
     * como se autenticar para pedir outra. O que protege esta operação não é
     * token nenhum — é o código chegar num canal cuja posse já foi provada
     * (FR-052), e a resposta ser idêntica exista ou não a conta (FR-019).
     */
    public static final String CAMINHO_RECUPERACAO_SOLICITAR = "/v1/auth/recuperacao/solicitar";

    /**
     * Caminho da confirmação da senha nova (T067).
     *
     * <p>Também público, e pela mesma razão. Aqui quem autentica a chamada é o
     * código de 6 dígitos conferido contra o hash gravado — uso único, dez
     * minutos de prazo e cinco tentativas, as três proteções cobrindo as falhas
     * uma da outra.
     */
    public static final String CAMINHO_RECUPERACAO_CONFIRMAR = "/v1/auth/recuperacao/confirmar";

    /**
     * Traduz o token do cabeçalho em identidade (T058).
     *
     * <p>É um {@code @Bean} para receber as dependências pelo contêiner, mas
     * <b>não</b> deve ser registrado como filtro de servlet automático — daí o
     * {@link FilterRegistrationBean} logo abaixo. Sem ele, o Boot instala todo
     * bean de {@code Filter} também fora da cadeia do Spring Security, e o
     * filtro roda duas vezes por requisição.
     */
    @Bean
    FiltroDeTokenDeAcesso filtroDeTokenDeAcesso(
            EmissorDeTokenDeAcesso emissor, RepositorioPessoaUsuaria pessoas) {
        return new FiltroDeTokenDeAcesso(emissor, pessoas);
    }

    /** Impede o registro automático descrito em {@link #filtroDeTokenDeAcesso}. */
    @Bean
    FilterRegistrationBean<FiltroDeTokenDeAcesso> naoRegistrarFiltroDuasVezes(
            FiltroDeTokenDeAcesso filtro) {
        FilterRegistrationBean<FiltroDeTokenDeAcesso> registro =
                new FilterRegistrationBean<>(filtro);
        registro.setEnabled(false);
        return registro;
    }

    @Bean
    RespostaDeNaoAutenticado respostaDeNaoAutenticado(ObjectMapper json) {
        return new RespostaDeNaoAutenticado(json);
    }

    @Bean
    SecurityFilterChain cadeiaDeSeguranca(
            HttpSecurity http,
            FiltroDeTokenDeAcesso filtroDeToken,
            RespostaDeNaoAutenticado semCredencial)
            throws Exception {
        return http.csrf(csrf -> csrf.disable())
                .sessionManagement(
                        sessao -> sessao.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(
                        rotas ->
                                // O despacho ASYNC so existe depois de uma
                                // requisicao que ja passou pela cadeia e foi
                                // autorizada: e o fim do SSE da conversa. O
                                // FiltroDeTokenDeAcesso nao roda de novo nele,
                                // e sem esta linha cada conversa terminava
                                // com AuthorizationDeniedException no log
                                // (DespachoAssincronoDaConversaTest).
                                rotas.dispatcherTypeMatchers(DispatcherType.ASYNC)
                                        .permitAll()
                                        // So estes dois, e so GET: nada de
                                        // /actuator/**. O liveness e o que o
                                        // Render consulta, e nao toca no banco
                                        // (ver ConfiguracaoDeSegurancaWebTest).
                                        .requestMatchers(
                                                HttpMethod.GET,
                                                "/actuator/health",
                                                "/actuator/health/liveness")
                                        .permitAll()
                                        .requestMatchers(
                                                HttpMethod.POST,
                                                CAMINHO_CADASTRO,
                                                CAMINHO_ENTRAR,
                                                CAMINHO_RENOVAR,
                                                CAMINHO_RECUPERACAO_SOLICITAR,
                                                CAMINHO_RECUPERACAO_CONFIRMAR)
                                        .permitAll()
                                        .anyRequest()
                                        .authenticated())
                .addFilterBefore(filtroDeToken, UsernamePasswordAuthenticationFilter.class)
                .exceptionHandling(
                        erros ->
                                erros.authenticationEntryPoint(semCredencial)
                                        .accessDeniedHandler(semCredencial))
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

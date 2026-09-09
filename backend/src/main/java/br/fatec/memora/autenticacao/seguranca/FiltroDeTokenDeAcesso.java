package br.fatec.memora.autenticacao.seguranca;

import br.fatec.memora.autenticacao.dominio.EstadoDaConta;
import br.fatec.memora.autenticacao.dominio.PessoaUsuaria;
import br.fatec.memora.autenticacao.infra.RepositorioPessoaUsuaria;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Transforma o token do cabeçalho em identidade, ou em nada (T058).
 *
 * <h2>Assinatura válida não é autorização</h2>
 *
 * Este é o filtro que a {@code ServicoDeCadastro} avisa que precisaria existir.
 * O cadastro responde {@code 201} idêntica quando o canal já pertence a alguém
 * (FR-010), e para isso devolve uma <b>sessão-chamariz</b>: um JWT assinado por
 * nós, com assinatura e formato perfeitos, cujo sujeito é um {@link UUID}
 * sorteado que não corresponde a conta nenhuma.
 *
 * <p>A consequência é direta: existe token que este servidor emitiu, que passa
 * na verificação criptográfica, e que <b>não deve autenticar ninguém</b>. Por
 * isso o filtro não para em {@link EmissorDeTokenDeAcesso#pessoaDoToken}. Ele
 * resolve o sujeito no banco e só autentica se encontrar conta — e é essa
 * consulta, e não a assinatura, que separa a pessoa real do chamariz.
 *
 * <p>Quem escrever um caminho autenticado que confie no {@code subject} do JWT
 * sem passar por aqui transforma o chamariz em acesso: bastaria tentar cadastrar
 * com o e-mail de alguém para receber um token que aquele caminho aceitaria.
 *
 * <h2>Conta desativada não autentica</h2>
 *
 * O token de acesso vale 15 minutos e é autocontido — não há como revogá-lo
 * individualmente. Sem esta guarda, uma conta desativada continuaria entrando
 * pelos 15 minutos seguintes ao ato de desativar, com um token que já estava na
 * mão de quem quer que a tenha usado. É o mesmo raciocínio que a revisão da PR
 * #15 aplicou à renovação de sessão.
 *
 * <p>{@link EstadoDaConta#PENDENTE_VERIFICACAO} <b>autentica</b>, e isso é
 * deliberado: a conta assistida precisa justamente do caminho autenticado de
 * confirmar canal. Recusá-la aqui tornaria a FR-062 impossível de cumprir. Quem
 * decide o que ela pode fazer é cada endpoint, por
 * {@link PessoaAutenticada#estaPendenteDeVerificacao()} — fechado por padrão, e
 * aberto onde estiver escrito.
 *
 * <h2>Cabeçalho ausente não é falha</h2>
 *
 * Requisição sem token segue adiante <b>sem</b> autenticação, e quem recusa é a
 * cadeia de autorização. Responder {@code 401} daqui quebraria os caminhos
 * públicos — cadastro, entrada e renovação — que passam por este filtro como
 * qualquer outro.
 */
public class FiltroDeTokenDeAcesso extends OncePerRequestFilter {

    private static final String PREFIXO = "Bearer ";

    private final EmissorDeTokenDeAcesso emissor;
    private final RepositorioPessoaUsuaria pessoas;

    public FiltroDeTokenDeAcesso(
            EmissorDeTokenDeAcesso emissor, RepositorioPessoaUsuaria pessoas) {
        this.emissor = emissor;
        this.pessoas = pessoas;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest requisicao, HttpServletResponse resposta, FilterChain cadeia)
            throws ServletException, IOException {

        try {
            autenticarSePuder(requisicao);
            cadeia.doFilter(requisicao, resposta);
        } finally {
            // O contexto e um ThreadLocal, e a thread volta para o pool. Sem a
            // limpeza, a identidade de uma pessoa reaparece na requisicao da
            // seguinte — a mesma armadilha que ContextoDaRequisicao documenta.
            SecurityContextHolder.clearContext();
        }
    }

    private void autenticarSePuder(HttpServletRequest requisicao) {
        Optional<String> token = tokenDoCabecalho(requisicao);
        if (token.isEmpty()) {
            return;
        }

        Optional<EmissorDeTokenDeAcesso.SujeitoDoToken> sujeito =
                emissor.sujeitoDoToken(token.get());
        if (sujeito.isEmpty()) {
            return;
        }

        // A consulta que desarma o chamariz. Ver o cabecalho desta classe.
        Optional<PessoaUsuaria> pessoa = pessoas.findById(sujeito.get().pessoaId());
        if (pessoa.isEmpty()) {
            return;
        }

        EstadoDaConta estado = pessoa.get().getEstado();
        if (estado == EstadoDaConta.DESATIVADA) {
            return;
        }

        PessoaAutenticada autenticada =
                new PessoaAutenticada(pessoa.get().getId(), estado, sujeito.get().familiaId());

        UsernamePasswordAuthenticationToken autenticacao =
                new UsernamePasswordAuthenticationToken(autenticada, null, List.of());
        autenticacao.setDetails(
                new WebAuthenticationDetailsSource().buildDetails(requisicao));

        SecurityContextHolder.getContext().setAuthentication(autenticacao);
    }

    /**
     * Lê {@code Authorization: Bearer <token>}.
     *
     * <p>O nome do esquema é comparado sem diferenciar maiúsculas porque a RFC
     * 7235 o define assim; o valor, não.
     */
    private Optional<String> tokenDoCabecalho(HttpServletRequest requisicao) {
        String cabecalho = requisicao.getHeader(HttpHeaders.AUTHORIZATION);
        if (cabecalho == null || cabecalho.length() <= PREFIXO.length()) {
            return Optional.empty();
        }
        if (!cabecalho.regionMatches(true, 0, PREFIXO, 0, PREFIXO.length())) {
            return Optional.empty();
        }
        String valor = cabecalho.substring(PREFIXO.length()).trim();
        return valor.isEmpty() ? Optional.empty() : Optional.of(valor);
    }
}

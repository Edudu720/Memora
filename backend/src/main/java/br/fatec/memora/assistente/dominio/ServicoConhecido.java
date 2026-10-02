package br.fatec.memora.assistente.dominio;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/**
 * Um serviço que a Memora conhece — e o que ela pode fazer com ele (T008).
 *
 * <h2>Esta entidade é quem autoriza</h2>
 *
 * A FR-022 exige que a decisão sobre executar uma ação seja <b>determinística e
 * tomada fora do modelo</b>. É esta tabela que a toma: o modelo pode sugerir
 * abrir o que quiser, e a sugestão só vira ação se existir aqui uma linha ativa,
 * da categoria {@link CategoriaDoServico#COTIDIANO}.
 *
 * <p>Alguém pode convencer um modelo a pedir para abrir o aplicativo do banco.
 * Ninguém convence uma linha de tabela.
 *
 * <h2>Por que a fábrica é separada por categoria</h2>
 *
 * {@link #sensivel} não aceita identificador de aplicativo, e {@link #cotidiano}
 * o exige. Um construtor único com um parâmetro opcional deixaria passar, em
 * tempo de compilação, um serviço sensível com pacote preenchido — e aí a única
 * defesa seria a restrição do banco, que só reclama tarde, na inserção.
 *
 * <p>As duas defesas existem de propósito. A do banco é a que vale quando esta
 * classe for contornada por SQL avulso ou por uma migration distraída.
 */
@Entity
@Table(name = "servico_conhecido")
public class ServicoConhecido {

    @Id
    @Column(nullable = false, updatable = false)
    private UUID id;

    /**
     * Identificador estável do item, igual em qualquer banco (V8, feature 004).
     *
     * <p>É o que liga o item ao guia de passo a passo embarcado no aplicativo: o
     * {@code id} é um UUID sorteado em cada banco e não serve para isso. O
     * {@code id} continua sendo o que a trilha de auditoria referencia — a
     * chave só acrescenta um nome que não muda. ASCII minúsculo, números e
     * hífen; o banco recusa qualquer outra coisa e recusa repetição.
     */
    @Column(nullable = false, updatable = false, length = 40)
    private String chave;

    @Column(name = "nome_exibido", nullable = false, length = 80)
    private String nomeExibido;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private CategoriaDoServico categoria;

    /** Pacote Android. <b>Nulo quando {@link CategoriaDoServico#SENSIVEL}.</b> */
    @Column(name = "identificador_android", length = 255)
    private String identificadorAndroid;

    @Column(name = "descricao_curta", nullable = false, length = 200)
    private String descricaoCurta;

    @Column(nullable = false)
    private boolean ativo;

    @Column(name = "criado_em", nullable = false, updatable = false)
    private Instant criadoEm;

    @Column(name = "atualizado_em", nullable = false)
    private Instant atualizadoEm;

    /** Exigido pelo JPA. Não usar em código de aplicação. */
    protected ServicoConhecido() {
    }

    /**
     * Cria um serviço que a Memora <b>só ensina</b> — banco, governo, saúde.
     *
     * <p>Não há parâmetro para o identificador do aplicativo, e essa ausência é
     * a FR-041 no nível da API: não existe forma de construir um serviço
     * sensível abrível.
     */
    public static ServicoConhecido sensivel(
            String chave, String nomeExibido, String descricaoCurta, Instant agora) {
        return new ServicoConhecido(
                chave, CategoriaDoServico.SENSIVEL, nomeExibido, null, descricaoCurta, agora);
    }

    /**
     * Cria um serviço que a Memora ensina <b>e pode abrir</b>.
     *
     * @param identificadorAndroid o pacote, obrigatório — sem ele não há o que
     *     abrir, e a restrição do banco recusaria a linha
     */
    public static ServicoConhecido cotidiano(
            String chave,
            String nomeExibido,
            String identificadorAndroid,
            String descricaoCurta,
            Instant agora) {
        return new ServicoConhecido(
                chave,
                CategoriaDoServico.COTIDIANO,
                nomeExibido,
                Objects.requireNonNull(identificadorAndroid, "identificadorAndroid"),
                descricaoCurta,
                agora);
    }

    private ServicoConhecido(
            String chave,
            CategoriaDoServico categoria,
            String nomeExibido,
            String identificadorAndroid,
            String descricaoCurta,
            Instant agora) {
        this.id = UUID.randomUUID();
        this.chave = Objects.requireNonNull(chave, "chave");
        this.categoria = Objects.requireNonNull(categoria, "categoria");
        this.nomeExibido = Objects.requireNonNull(nomeExibido, "nomeExibido");
        this.identificadorAndroid = identificadorAndroid;
        this.descricaoCurta = Objects.requireNonNull(descricaoCurta, "descricaoCurta");
        this.ativo = true;
        this.criadoEm = Objects.requireNonNull(agora, "agora");
        this.atualizadoEm = agora;
    }

    /**
     * Este serviço pode ser aberto pela Memora, agora?
     *
     * <p>Exige as <b>duas</b> condições: categoria que permite e serviço ativo.
     * Um serviço tirado do ar — porque virou vetor de golpe, porque mudou de
     * dono — para de ser abrível sem que ninguém precise publicar versão nova
     * do aplicativo.
     */
    public boolean podeSerAberto() {
        return ativo && categoria.permiteAbrir() && identificadorAndroid != null;
    }

    /** Retira o serviço de circulação, preservando a trilha que aponta para ele. */
    public void desativar(Instant agora) {
        this.ativo = false;
        this.atualizadoEm = Objects.requireNonNull(agora, "agora");
    }

    public UUID getId() {
        return id;
    }

    public String getChave() {
        return chave;
    }

    public String getNomeExibido() {
        return nomeExibido;
    }

    public CategoriaDoServico getCategoria() {
        return categoria;
    }

    /** Vazio quando o serviço é sensível — e é assim que deve ser. */
    public Optional<String> getIdentificadorAndroid() {
        return Optional.ofNullable(identificadorAndroid);
    }

    public String getDescricaoCurta() {
        return descricaoCurta;
    }

    public boolean isAtivo() {
        return ativo;
    }

    public Instant getCriadoEm() {
        return criadoEm;
    }

    public Instant getAtualizadoEm() {
        return atualizadoEm;
    }

    @Override
    public boolean equals(Object outro) {
        if (this == outro) {
            return true;
        }
        return outro instanceof ServicoConhecido servico && Objects.equals(id, servico.id);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(id);
    }

    @Override
    public String toString() {
        return "ServicoConhecido[id=%s, chave=%s, nome=%s, categoria=%s, ativo=%s]"
                .formatted(id, chave, nomeExibido, categoria, ativo);
    }
}

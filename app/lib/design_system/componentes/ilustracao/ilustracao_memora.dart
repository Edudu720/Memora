import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// As ilustrações que o Memora tem.
///
/// Enum, e não caminho solto de arquivo: assim uma ilustração que não existe
/// **não compila**, em vez de virar um retângulo vazio no aparelho de alguém.
/// É o mesmo raciocínio dos tokens de cor.
enum Ilustracao {
  /// Casal idoso. Cabeçalho das boas-vindas e avatar do cadastro e do login.
  casalIdoso('casal_idoso'),

  /// Pessoa idosa olhando o próprio celular.
  pessoaComCelular('pessoa_com_celular'),

  /// A linha que atravessa a tela de boas-vindas. **Precisa de [cor]**.
  linhaJornada('linha_jornada', colorida: false),

  // ---------------------------------------------------------------------------
  // A Memora (feature 004, T010). Use pelo `MemoraPersonagem`, que escolhe a
  // expressão; a ilustração direta existe para a galeria e para os testes.
  // ---------------------------------------------------------------------------

  /// A Memora em repouso.
  memoraNeutra('memora_neutra'),

  /// A Memora falando — apresentação, conversa, ajuda guiada.
  memoraFalando('memora_falando'),

  /// A Memora comemorando — fim do passo a passo, conta criada.
  memoraComemorando('memora_comemorando'),

  /// A Memora preocupada — ao lado dos avisos de segurança.
  memoraPreocupada('memora_preocupada'),

  // ---------------------------------------------------------------------------
  // Portas do Hub (feature 004, T011)
  // ---------------------------------------------------------------------------

  /// "Conversar com a Memora": dois balões de fala.
  portaConversa('porta_conversa'),

  /// "Meus aplicativos": um celular com a grade.
  portaAplicativos('porta_aplicativos'),

  /// "Serviços sociais": prédio público e documento. **Sem logotipo** (R7).
  portaServicos('porta_servicos'),

  /// "Ajuda": a boia com o ponto de interrogação.
  portaAjuda('porta_ajuda'),

  /// "O que eu fiz por você": a prancheta marcada.
  portaRegistro('porta_registro'),

  // ---------------------------------------------------------------------------
  // Estados (feature 004, FR-006)
  // ---------------------------------------------------------------------------

  /// Nada para mostrar ainda.
  estadoVazio('estado_vazio'),

  /// Não deu para carregar — é a conexão, não a pessoa.
  estadoErro('estado_erro'),

  /// Aplicativo cujo ícone o aparelho não forneceu (R7).
  aplicativoGenerico('aplicativo_generico');

  const Ilustracao(this._arquivo, {this.colorida = true});

  final String _arquivo;

  /// O desenho tem cores próprias, e por isso vai sobre o medalhão claro nos
  /// temas escuros (R4 da feature 004). Só as de traço único, que recebem
  /// `cor`, não são coloridas.
  final bool colorida;

  /// Caminho do arquivo dentro de `assets/`.
  String get caminho => 'assets/ilustracoes/$_arquivo.svg';
}

/// Ilustração vetorial do Memora.
///
/// ## Por que vetor, e não imagem
///
/// As telas do protótipo estão no repositório em **390×844** — resolução 1x.
/// Recortar a ilustração dali daria ~150 px, e um aparelho 3x precisa de ~450
/// para não borrar. Vetor escala em qualquer densidade, e o arquivo é texto:
/// uma mudança na ilustração aparece no diff da revisão.
///
/// ## Por que fica fora do leitor de tela por padrão
///
/// Ilustração é decoração. Anunciar "imagem" ao TalkBack acrescenta uma parada
/// na navegação e não informa nada — e o público do Memora é justamente quem
/// mais depende dessa navegação ser curta. Quando a figura **é** informação,
/// passe [descricao]: aí ela é anunciada e a parada se paga.
///
/// ## Sobre [cor]
///
/// [Ilustracao.linhaJornada] é desenhada com `currentColor` e **depende** dela:
/// sem cor, sai preta, some no tema escuro e briga com o de alto contraste.
/// As ilustrações de pessoas têm cores próprias e não devem recebê-la — tingir
/// tudo de uma cor só apagaria o desenho.
class IlustracaoMemora extends StatelessWidget {
  /// Qual ilustração exibir.
  final Ilustracao ilustracao;

  /// Altura em pixels lógicos. A largura acompanha a proporção.
  final double? altura;

  /// Largura em pixels lógicos. A altura acompanha a proporção.
  final double? largura;

  /// Cor aplicada ao desenho inteiro. Só para ilustrações de traço único.
  final Color? cor;

  /// Como o desenho ocupa o espaço reservado.
  ///
  /// O padrão preserva a proporção. [BoxFit.fill] serve à linha da jornada,
  /// que é decoração e pode esticar na largura sem prejuízo.
  final BoxFit fit;

  /// O que a figura comunica, para quem não a vê.
  ///
  /// Nulo é o padrão e significa **decorativa**: o leitor de tela a ignora.
  final String? descricao;

  /// Cria uma ilustração.
  const IlustracaoMemora(
    this.ilustracao, {
    this.altura,
    this.largura,
    this.cor,
    this.fit = BoxFit.contain,
    this.descricao,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Widget desenho = SvgPicture.asset(
      ilustracao.caminho,
      height: altura,
      width: largura,
      fit: fit,
      colorFilter: cor == null ? null : ColorFilter.mode(cor!, BlendMode.srcIn),
      // Sem isto, o quadro fica em branco enquanto o arquivo carrega e a tela
      // "pula" quando ele chega. Reservar o espaço desde o primeiro quadro
      // evita o salto — que para quem já está lendo devagar é desorientador.
      placeholderBuilder: (BuildContext _) =>
          SizedBox(height: altura, width: largura),
    );

    if (descricao == null) {
      return ExcludeSemantics(child: desenho);
    }
    return Semantics(image: true, label: descricao, child: desenho);
  }
}

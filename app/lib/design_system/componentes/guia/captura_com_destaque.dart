import 'package:flutter/material.dart';

import '../../../features/aprendizado/domain/guia.dart';
import '../../../l10n/textos_guias.dart';
import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/raio.dart';

/// A captura de um passo, desenhada **na proporção dela**, com o anel de
/// destaque por cima em coordenadas **da imagem** (T133, FR-028c).
///
/// ## O defeito que isto conserta
///
/// O anel era posicionado sobre a **caixa** da moldura, e a imagem entrava
/// nela com `BoxFit.contain`. Com uma captura de proporção diferente da caixa,
/// a imagem ficava com faixas vazias dos lados e o anel caía fora do lugar que
/// a [RegiaoRelativa] aponta. Os desenhos provisórios (1:2) quase tinham a
/// proporção da moldura e escondiam isso; qualquer print de celular (9:20) o
/// mostra.
///
/// ## Como funciona
///
/// A proporção vem da própria imagem: o componente resolve o [ImageProvider] e
/// lê largura e altura quando ela chega. Enquanto ela não chega — ou quando
/// ela falha — vale [proporcaoDeReserva]. Com a proporção, a imagem é ajustada
/// à caixa disponível como `contain` e **centralizada**; o anel é um filho da
/// caixa da imagem, e a [RegiaoRelativa] se multiplica pelo tamanho **dela**.
///
/// ## Por que 9/20 de reserva
///
/// É a proporção dos prints de celular que a equipe vai mandar (720×1600 e
/// 1080×2400). Errar para mais estreito ou mais largo só dura o instante até a
/// imagem chegar, e 9/20 é o que menos "salta" quando ela chega.
///
/// ## Captura que não existe
///
/// Quando o arquivo falta, o componente mostra [pendente] (FR-028a) e avisa
/// por [aoMudarPendente]. Sem [pendente], mostra uma caixa vazia.
class CapturaComDestaque extends StatefulWidget {
  /// Chave da imagem desenhada. O retângulo dela é o "retângulo pintado" que o
  /// destaque precisa respeitar.
  static const Key chaveImagem = Key('captura.imagem');

  /// Chave do anel de destaque, igual em toda parte onde ele aparece.
  static const Key chaveDestaque = Key('passo.destaque');

  /// A proporção (largura ÷ altura) usada até a imagem chegar.
  static const double proporcaoDeReserva = 9 / 20;

  /// O passo: a captura, a região e a descrição para o leitor de tela.
  final Passo passo;

  /// De onde vem a imagem. Sem ele, o asset da captura do passo.
  ///
  /// Existe para o teste dar uma imagem de proporção conhecida sem depender de
  /// ler asset dentro de `testWidgets`, onde o relógio é falso.
  final ImageProvider? imagem;

  /// A proporção, quando já se sabe. Dispensa descobri-la pela imagem — mas a
  /// imagem continua sendo desenhada e, se ela falhar, o aviso continua valendo.
  final double? proporcao;

  /// O que mostrar no lugar da imagem quando ela não existe (FR-028a).
  final WidgetBuilder? pendente;

  /// Chamada quando a imagem falha (`true`). Nunca durante o `build`.
  final ValueChanged<bool>? aoMudarPendente;

  /// Chave do corpo do anel, para quem precisa medi-lo na tela (a ampliação
  /// leva o zoom até ele).
  final Key? chaveDoAnel;

  /// Cria a captura com o destaque.
  const CapturaComDestaque({
    required this.passo,
    this.imagem,
    this.proporcao,
    this.pendente,
    this.aoMudarPendente,
    this.chaveDoAnel,
    super.key,
  }) : assert(
         proporcao == null || proporcao > 0,
         'A proporção precisa ser positiva.',
       );

  @override
  State<CapturaComDestaque> createState() => _EstadoDaCapturaComDestaque();
}

class _EstadoDaCapturaComDestaque extends State<CapturaComDestaque> {
  ImageStream? _fluxo;
  late final ImageStreamListener _ouvinte = ImageStreamListener(
    _aoChegarImagem,
    onError: _aoFalhar,
  );

  /// A proporção lida da imagem, quando ela já chegou.
  double? _proporcaoLida;
  bool _falhou = false;

  ImageProvider get _provedor =>
      widget.imagem ?? AssetImage(widget.passo.captura.caminho);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolver();
  }

  @override
  void didUpdateWidget(CapturaComDestaque anterior) {
    super.didUpdateWidget(anterior);
    _resolver();
  }

  @override
  void dispose() {
    _fluxo?.removeListener(_ouvinte);
    super.dispose();
  }

  void _resolver() {
    final ImageStream novo = _provedor.resolve(
      createLocalImageConfiguration(context),
    );
    if (novo.key == _fluxo?.key) return;
    _fluxo?.removeListener(_ouvinte);
    _fluxo = novo;
    _proporcaoLida = null;
    if (_falhou) {
      _falhou = false;
      _avisarPendente(false);
    }
    novo.addListener(_ouvinte);
  }

  void _aoChegarImagem(ImageInfo info, bool sincrono) {
    final double largura = info.image.width.toDouble();
    final double altura = info.image.height.toDouble();
    // Cada ouvinte recebe o seu próprio ImageInfo, e é dele que descarta.
    info.dispose();
    if (!mounted || altura <= 0) return;
    setState(() => _proporcaoLida = largura / altura);
  }

  void _aoFalhar(Object erro, StackTrace? pilha) {
    if (!mounted) return;
    setState(() => _falhou = true);
    _avisarPendente(true);
  }

  void _avisarPendente(bool pendente) {
    final ValueChanged<bool>? aviso = widget.aoMudarPendente;
    if (aviso == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) aviso(pendente);
    });
  }

  /// Ajusta [proporcao] à [caixa] como `contain`, sem passar dela.
  static Size _tamanhoDaImagem(Size caixa, double proporcao) {
    double largura = caixa.width;
    double altura = largura / proporcao;
    if (altura > caixa.height) {
      altura = caixa.height;
      largura = altura * proporcao;
    }
    return Size(largura, altura);
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final double proporcao =
        widget.proporcao ??
        _proporcaoLida ??
        CapturaComDestaque.proporcaoDeReserva;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints restricoes) {
        final double largura = restricoes.maxWidth;
        // Sem altura limitada, a largura manda.
        final double altura = restricoes.hasBoundedHeight
            ? restricoes.maxHeight
            : largura / proporcao;
        final Size caixa = Size(largura, altura);

        if (_falhou) {
          return SizedBox.fromSize(
            size: caixa,
            child: widget.pendente?.call(context),
          );
        }

        final Size imagem = _tamanhoDaImagem(caixa, proporcao);
        final RegiaoRelativa regiao = widget.passo.destaque;

        return SizedBox.fromSize(
          size: caixa,
          child: Center(
            child: SizedBox.fromSize(
              size: imagem,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned.fill(
                    child: Image(
                      key: CapturaComDestaque.chaveImagem,
                      image: _provedor,
                      // A caixa já tem a proporção da imagem: preencher não
                      // distorce, e o retângulo do widget é o pintado.
                      fit: BoxFit.fill,
                      semanticLabel: widget.passo.descricaoDaCaptura,
                      errorBuilder:
                          (BuildContext _, Object erro, StackTrace? pilha) =>
                              const SizedBox.shrink(),
                    ),
                  ),
                  // O anel, em coordenadas da IMAGEM (FR-028c).
                  Positioned(
                    key: CapturaComDestaque.chaveDestaque,
                    left: imagem.width * regiao.x,
                    top: imagem.height * regiao.y,
                    width: imagem.width * regiao.largura,
                    height: imagem.height * regiao.altura,
                    child: Semantics(
                      label: TextosGuias.areaDestacada,
                      child: Container(
                        key: widget.chaveDoAnel,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(MemoraRaio.padrao),
                          border: Border.all(
                            color: cores.primaria,
                            width: MemoraDimensoes.bordaSelecao,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: cores.medalhao,
                              spreadRadius: MemoraDimensoes.bordaEnfase,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

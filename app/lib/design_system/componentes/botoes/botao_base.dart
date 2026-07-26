import 'package:flutter/material.dart';

import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/movimento.dart';
import '../../tokens/raio.dart';
import '../../tokens/tipografia.dart';
import '../../temas/memora_theme_extension.dart';

/// Variação visual de um botão do Memora.
///
/// Uso interno do Design System. Telas usam `BotaoPrimario`,
/// `BotaoSecundario`, `BotaoTerciario` ou `BotaoPerigo`.
enum EstiloBotao {
  /// Preenchido com a cor primária. Ação principal da tela.
  primario,

  /// Contornado. Ação alternativa.
  secundario,

  /// Apenas texto sublinhado. Ação de baixo peso.
  terciario,

  /// Preenchido com a cor de perigo. Ação destrutiva.
  perigo,
}

/// Base compartilhada dos botões do Memora.
///
/// Concentra num único lugar as garantias que **nenhum botão pode perder**:
/// altura mínima de toque, rótulo textual obrigatório, semântica de botão,
/// estados visuais distintos e crescimento com o texto ampliado.
///
/// Não é usada diretamente pelas telas — é a implementação por trás dos quatro
/// botões públicos.
class BotaoBase extends StatelessWidget {
  /// Texto do botão. **Obrigatório**: não existe botão apenas com ícone
  /// (FR-016).
  final String rotulo;

  /// Ação disparada ao toque. `null` deixa o botão desabilitado.
  final VoidCallback? aoTocar;

  /// Ícone opcional, exibido antes do rótulo.
  final IconData? icone;

  /// Quando verdadeiro, exibe indicador de progresso e bloqueia o toque.
  final bool carregando;

  /// Variação visual.
  final EstiloBotao estilo;

  /// Altura mínima. Nunca abaixo de [MemoraDimensoes.alvoMinimo].
  final double alturaMinima;

  /// Ocupa toda a largura disponível.
  final bool larguraTotal;

  /// Cria um botão base. Prefira os botões públicos do Design System.
  const BotaoBase({
    required this.rotulo,
    required this.estilo,
    required this.alturaMinima,
    this.aoTocar,
    this.icone,
    this.carregando = false,
    this.larguraTotal = true,
    super.key,
  }) : assert(
          alturaMinima >= MemoraDimensoes.alvoMinimo,
          'Nenhum botão pode ficar abaixo do alvo mínimo de toque.',
        );

  bool get _habilitado => aoTocar != null && !carregando;

  Color _corDeFundo(MemoraCores c) => switch (estilo) {
        EstiloBotao.primario => c.primaria,
        EstiloBotao.perigo => c.perigo,
        EstiloBotao.secundario => Colors.transparent,
        EstiloBotao.terciario => Colors.transparent,
      };

  Color _corDoConteudo(MemoraCores c) => switch (estilo) {
        EstiloBotao.primario => c.sobrePrimaria,
        EstiloBotao.perigo => c.sobrePerigo,
        EstiloBotao.secundario => c.primaria,
        EstiloBotao.terciario => c.primaria,
      };

  BoxBorder? _borda(MemoraCores c) => switch (estilo) {
        EstiloBotao.secundario => Border.all(color: c.primaria, width: 2),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final Color fundo = _corDeFundo(cores);
    final Color conteudo = _corDoConteudo(cores);

    // Desabilitado precisa continuar legível: reduzimos a saturação sem
    // apagar o texto, para a pessoa entender que a ação existe mas não está
    // disponível agora.
    final double opacidade = _habilitado ? 1.0 : 0.55;

    final Widget miolo = Row(
      mainAxisSize: larguraTotal ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (carregando) ...<Widget>[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(conteudo),
            ),
          ),
          const SizedBox(width: MemoraEspacamento.sm),
        ] else if (icone != null) ...<Widget>[
          Icon(icone, size: 22, color: conteudo),
          const SizedBox(width: MemoraEspacamento.sm),
        ],
        Flexible(
          child: Text(
            rotulo,
            textAlign: TextAlign.center,
            style: MemoraTipografia.rotuloBotao.copyWith(
              color: conteudo,
              decoration: estilo == EstiloBotao.terciario
                  ? TextDecoration.underline
                  : null,
              decorationColor: conteudo,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: _habilitado,
      label: rotulo,
      child: ExcludeSemantics(
        child: Opacity(
          opacity: opacidade,
          child: AnimatedContainer(
            duration: MemoraMovimento.rapido,
            // Altura MÍNIMA, nunca fixa: o botão cresce com o texto ampliado
            // até 200% sem cortar conteúdo (FR-026).
            constraints: BoxConstraints(
              minHeight: alturaMinima,
              minWidth: MemoraDimensoes.alvoMinimo,
            ),
            width: larguraTotal ? double.infinity : null,
            decoration: BoxDecoration(
              color: fundo,
              border: _borda(cores),
              borderRadius: BorderRadius.circular(MemoraRaio.pilula),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(MemoraRaio.pilula),
              child: InkWell(
                onTap: _habilitado ? aoTocar : null,
                borderRadius: BorderRadius.circular(MemoraRaio.pilula),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MemoraEspacamento.xl,
                    vertical: MemoraEspacamento.md,
                  ),
                  child: miolo,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

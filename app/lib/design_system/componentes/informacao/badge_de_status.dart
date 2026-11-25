import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../../tokens/tipografia.dart';
import '../texto/texto_memora.dart';

/// Tom visual do [BadgeDeStatus].
enum TomBadgeStatus {
  /// Estado saudável, concluído ou ativo.
  positivo,

  /// Alerta moderado que pede cautela sem o preenchimento sólido de erro.
  aviso,

  /// Atenção ou erro com destaque de alto contraste.
  atencao,

  /// Orientação ou destaque informativo.
  informativo,

  /// Estado neutro ou secundário.
  neutro,
}

/// Selo compacto **estritamente informativo** para estado de dados ou conexão.
///
/// Respeita o piso de `16 sp` (`MemoraTipografia.apoio`) e **não possui
/// callback de toque** (`002/FR-012`), utilizando formato de badge
/// (`MemoraRaio.badge`), nunca pílula interativa.
class BadgeDeStatus extends StatelessWidget {
  /// Texto exibido dentro do badge.
  final String rotulo;

  /// Ícone opcional exibido antes do texto (nunca substituir o texto).
  final IconData? icone;

  /// Tom semântico do badge.
  final TomBadgeStatus tom;

  /// Cria um badge de status informativo.
  const BadgeDeStatus({
    required this.rotulo,
    this.icone,
    this.tom = TomBadgeStatus.positivo,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;

    final (Color fundo, Color textoCor) = switch (tom) {
      TomBadgeStatus.positivo => (cores.saudeSuave, cores.sucessoTexto),
      TomBadgeStatus.aviso => (cores.superficie, cores.perigo),
      TomBadgeStatus.atencao => (cores.perigo, cores.sobrePerigo),
      TomBadgeStatus.informativo => (cores.destaque, cores.primaria),
      TomBadgeStatus.neutro => (cores.superficieSutil, cores.texto),
    };
    final Color corBorda = switch (tom) {
      TomBadgeStatus.aviso => cores.perigo,
      _ => ehAltoContraste ? cores.borda : cores.bordaSutil,
    };
    final double larguraBorda =
        ehAltoContraste || tom == TomBadgeStatus.aviso
            ? MemoraDimensoes.bordaEnfase
            : MemoraDimensoes.espessuraBordaSutil;

    return Semantics(
      button: false,
      readOnly: true,
      label: rotulo,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraEspacamento.md,
            vertical: MemoraEspacamento.xs,
          ),
          decoration: BoxDecoration(
            color: fundo,
            borderRadius: BorderRadius.circular(MemoraRaio.badge),
            border: Border.all(
              color: corBorda,
              width: larguraBorda,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icone != null) ...<Widget>[
                Icon(
                  icone,
                  size: MemoraDimensoes.iconePequeno,
                  color: textoCor,
                ),
                const SizedBox(width: MemoraEspacamento.xs),
              ],
              Flexible(
                child: Text(
                  rotulo,
                  textScaler: escalaTextoLimitada(context),
                  style: MemoraTipografia.apoio.copyWith(
                    color: textoCor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

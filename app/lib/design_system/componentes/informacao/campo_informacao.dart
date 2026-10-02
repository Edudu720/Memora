import 'package:flutter/material.dart';

import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../../tokens/tipografia.dart';
import '../../temas/memora_theme_extension.dart';
import '../texto/texto_memora.dart';

/// Exibe um dado da pessoa — nome, idade, e-mail — de forma inequivocamente
/// **não clicável**.
///
/// ## Por que este componente existe
///
/// No protótipo, a tela de Perfil mostrava nome, idade e e-mail como pílulas
/// azuis **idênticas aos botões do Hub**. A pessoa idosa não tinha como saber o
/// que respondia ao toque. Foi a falha de affordance mais grave encontrada na
/// análise (FR-012).
///
/// ## A regra visual que separa dado de ação
///
/// - **Ação** usa forma de pílula ([MemoraRaio.pilula]) e fundo preenchido.
/// - **Informação** nunca usa pílula nem fundo de cor primária.
///
/// ## Proibição estrutural
///
/// Este componente **não aceita callback de toque**, e isso é deliberado: não é
/// convenção que alguém possa contornar, é ausência de API. Se uma tela precisa
/// de ação, precisa usar um botão — e a diferença fica visível para quem usa o
/// aplicativo.
class CampoInformacao extends StatelessWidget {
  /// O que o dado representa. Ex.: "Nome", "Idade".
  final String rotulo;

  /// O conteúdo do dado. Ex.: "Ana", "72".
  final String valor;

  /// Ícone opcional, exibido antes do rótulo.
  final IconData? icone;

  /// Cria um campo de informação.
  const CampoInformacao({
    required this.rotulo,
    required this.valor,
    this.icone,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Semantics(
      // Explicitamente NÃO é botão. O teste de semântica garante que continue
      // assim mesmo depois de refatorações.
      button: false,
      readOnly: true,
      label: rotulo,
      value: valor,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: MemoraEspacamento.md,
            horizontal: MemoraEspacamento.lg,
          ),
          decoration: BoxDecoration(
            // Sem preenchimento de cor primária e sem pílula: é o que
            // diferencia informação de ação.
            color: cores.superficie,
            borderRadius: BorderRadius.circular(MemoraRaio.padrao),
            border: Border(
              left: BorderSide(color: cores.borda, width: MemoraEspacamento.xs),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (icone != null) ...<Widget>[
                    Icon(
                      icone,
                      size: MemoraDimensoes.iconePequeno,
                      color: cores.textoSuave,
                    ),
                    const SizedBox(width: MemoraEspacamento.sm),
                  ],
                  Flexible(
                    child: Text(
                      rotulo,
                      textScaler: escalaTextoLimitada(context),
                      style: MemoraTipografia.apoio.copyWith(
                        color: cores.textoSuave,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MemoraEspacamento.xs),
              Text(
                valor,
                textScaler: escalaTextoLimitada(context),
                style: MemoraTipografia.corpoForte.copyWith(color: cores.texto),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

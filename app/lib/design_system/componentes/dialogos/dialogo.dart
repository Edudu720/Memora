import 'package:flutter/material.dart';

import '../../preferencias/reducao_de_movimento.dart';
import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/movimento.dart';
import '../../tokens/raio.dart';
import '../botoes/botao_primario.dart';
import '../botoes/botao_secundario.dart';
import '../texto/texto_memora.dart';

/// Diálogo modal do Memora.
///
/// Surge **por cima**, no centro: esmaece e cresce de 96% a 100%, sem mover a
/// tela de trás (feature 013, FR-010). Com "reduzir movimento", já chega
/// inteiro.
///
/// Sempre oferece uma saída clara. Um modal sem saída visível deixa a pessoa
/// presa numa tela que ela não sabe fechar — e o gesto de voltar do sistema
/// não é conhecido por todo o público.
class DialogoMemora extends StatelessWidget {
  /// Título curto e direto.
  final String titulo;

  /// Explicação em linguagem comum.
  final String mensagem;

  /// Rótulo da ação principal.
  final String rotuloConfirmar;

  /// Acionada ao confirmar.
  final VoidCallback aoConfirmar;

  /// Rótulo da saída. Quando nulo, exibe apenas a ação principal.
  final String? rotuloFechar;

  /// Acionada ao fechar.
  final VoidCallback? aoFechar;

  /// Cria um diálogo.
  const DialogoMemora({
    required this.titulo,
    required this.mensagem,
    required this.rotuloConfirmar,
    required this.aoConfirmar,
    this.rotuloFechar,
    this.aoFechar,
    super.key,
  });

  /// Exibe o diálogo no `Navigator` que [context] encontra.
  ///
  /// **Não no de fora**, que é o padrão do `showDialog`. Desde a casca da
  /// feature 004 há um `Navigator` por destino, e quem fecha o diálogo com
  /// `Navigator.of(context).pop()` acha o do destino: com o diálogo no de
  /// fora, "Entendi" fechava a tela de trás e deixava o diálogo aberto
  /// (revisão da #38). No mesmo `Navigator`, o `pop()` fecha o diálogo — e um
  /// diálogo aberto dentro de um destino sai da árvore junto com a casca
  /// quando a sessão expira.
  static Future<void> mostrar(
    BuildContext context, {
    required DialogoMemora dialogo,
  }) {
    return mostrarConteudo<void>(
      context,
      construtor: (BuildContext _) => dialogo,
    );
  }

  /// Exibe um diálogo de **conteúdo livre** — um formulário, por exemplo —
  /// pela mesma sobreposição do [mostrar]: esmaece e cresce de 96% a 100%, e
  /// com "reduzir movimento" já chega inteiro (feature 013, FR-010 e FR-013).
  ///
  /// Quem tem um `Dialog` próprio, mais rico que o [DialogoMemora], abre por
  /// aqui em vez de chamar o `showDialog` cru, que ficaria sem a animação
  /// nova e com 150 ms fixos mesmo com "reduzir movimento" (T091). O
  /// [construtor] devolve o diálogo inteiro (normalmente um `Dialog`).
  ///
  /// Abre no `Navigator` que [context] encontra, pelo mesmo motivo do
  /// [mostrar].
  static Future<T?> mostrarConteudo<T>(
    BuildContext context, {
    required WidgetBuilder construtor,
  }) {
    final bool reduzir = context.reduzirMovimento;
    return showDialog<T>(
      context: context,
      useRootNavigator: false,
      // Surge e some em `padrao`; com "reduzir movimento", de uma vez (FR-013).
      animationStyle: AnimationStyle(
        duration: MemoraMovimento.efetiva(
          MemoraMovimento.padrao,
          reduzirMovimento: reduzir,
        ),
        reverseDuration: MemoraMovimento.efetiva(
          MemoraMovimento.padrao,
          reduzirMovimento: reduzir,
        ),
      ),
      builder: (BuildContext ctx) => _SurgeNoCentro(child: construtor(ctx)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Dialog(
      backgroundColor: cores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MemoraRaio.cartao),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(MemoraEspacamento.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextoMemora.tituloSecao(titulo),
              const SizedBox(height: MemoraEspacamento.md),
              TextoMemora(mensagem),
              const SizedBox(height: MemoraEspacamento.xl),
              BotaoPrimario(rotulo: rotuloConfirmar, aoTocar: aoConfirmar),
              if (rotuloFechar != null) ...<Widget>[
                const SizedBox(height: MemoraEspacamento.md),
                BotaoSecundario(rotulo: rotuloFechar!, aoTocar: aoFechar),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// O aumento leve de 96% a 100% do diálogo, junto do esmaecer que o Flutter já
/// faz. Acompanha a animação da própria rota, então vale para entrar e sair.
class _SurgeNoCentro extends StatelessWidget {
  const _SurgeNoCentro({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Animation<double>? animacao = ModalRoute.of(context)?.animation;
    if (animacao == null) return child;
    return ScaleTransition(
      scale: animacao
          .drive(CurveTween(curve: MemoraMovimento.curvaDeSobreposicao))
          .drive(
            Tween<double>(
              begin: MemoraMovimento.escalaDoDialogoAoSurgir,
              end: MemoraMovimento.escalaDoDialogoEmRepouso,
            ),
          ),
      child: child,
    );
  }
}

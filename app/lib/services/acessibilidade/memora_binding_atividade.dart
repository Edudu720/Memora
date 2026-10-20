import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Intercepta ações semânticas da plataforma para contar atividade acessível (T109, FR-017).
///
/// O TalkBack e leitores de tela acionam botões e controles via [performSemanticsAction],
/// que não gera eventos de ponteiro ([PointerDownEvent]). Este mixin assegura que
/// ações de acessibilidade sejam contabilizadas como atividade do usuário.
mixin MemoraBindingAtividade on WidgetsBinding {
  /// Callback global invocado a cada ação semântica registrada.
  static VoidCallback? aoRegistrarAtividadeGlobal;

  @override
  void performSemanticsAction(ui.SemanticsActionEvent action) {
    aoRegistrarAtividadeGlobal?.call();
    super.performSemanticsAction(action);
  }
}

/// Binding oficial do aplicativo Memora com suporte a atividade acessível.
class MemoraWidgetsFlutterBinding extends WidgetsFlutterBinding with MemoraBindingAtividade {
  /// Garante a inicialização do binding com [MemoraBindingAtividade].
  static WidgetsBinding ensureInitialized() {
    MemoraWidgetsFlutterBinding();
    return WidgetsBinding.instance;
  }
}

/// Rastreia atividade de interação global (toques, teclado e acessibilidade) no aplicativo.
///
/// Cobre:
/// - Toques em qualquer janela ou diálogo modal (T110), via [pointerRouter];
/// - Digitação e teclas de atalho (T109), via [HardwareKeyboard];
/// - Ações semânticas de leitores de tela / TalkBack (T109), via [MemoraBindingAtividade].
class RastreadorDeAtividadeGlobal {
  /// Callback disparado ao registrar qualquer atividade.
  final VoidCallback aoRegistrarAtividade;

  bool _ativo = false;

  /// Cria o rastreador.
  RastreadorDeAtividadeGlobal({required this.aoRegistrarAtividade});

  /// Inicia o monitoramento global de atividade.
  void iniciar() {
    if (_ativo) return;
    _ativo = true;

    GestureBinding.instance.pointerRouter.addGlobalRoute(_aoPointer);
    HardwareKeyboard.instance.addHandler(_aoKey);
    SemanticsBinding.instance.addSemanticsActionListener(_aoSemanticsAction);
    MemoraBindingAtividade.aoRegistrarAtividadeGlobal = aoRegistrarAtividade;
  }

  /// Encerra o monitoramento e libera os ouvintes.
  void parar() {
    if (!_ativo) return;
    _ativo = false;

    GestureBinding.instance.pointerRouter.removeGlobalRoute(_aoPointer);
    HardwareKeyboard.instance.removeHandler(_aoKey);
    SemanticsBinding.instance.removeSemanticsActionListener(_aoSemanticsAction);
    if (MemoraBindingAtividade.aoRegistrarAtividadeGlobal == aoRegistrarAtividade) {
      MemoraBindingAtividade.aoRegistrarAtividadeGlobal = null;
    }
  }

  void _aoPointer(PointerEvent e) {
    if (e is PointerDownEvent) {
      aoRegistrarAtividade();
    }
  }

  bool _aoKey(KeyEvent e) {
    if (e is KeyDownEvent) {
      aoRegistrarAtividade();
    }
    return false;
  }

  void _aoSemanticsAction(ui.SemanticsActionEvent _) {
    aoRegistrarAtividade();
  }
}

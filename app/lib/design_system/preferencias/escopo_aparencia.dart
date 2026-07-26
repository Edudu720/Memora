import 'package:flutter/material.dart';

import '../temas/memora_theme_extension.dart';
import '../temas/temas_memora.dart';
import '../tokens/dimensoes.dart';
import 'controlador_aparencia.dart';
import 'preferencia_aparencia.dart';

/// Disponibiliza o [ControladorAparencia] para toda a árvore de widgets e
/// reconstrói o que depende dele quando a aparência muda.
class EscopoAparencia extends InheritedNotifier<ControladorAparencia> {
  /// Cria o escopo de aparência.
  const EscopoAparencia({
    required ControladorAparencia controlador,
    required super.child,
    super.key,
  }) : super(notifier: controlador);

  /// Recupera o controlador mais próximo na árvore.
  ///
  /// Lança se não houver escopo: falhar alto e cedo é preferível a uma tela de
  /// configuração que silenciosamente não salva nada.
  static ControladorAparencia de(BuildContext context) {
    final EscopoAparencia? escopo =
        context.dependOnInheritedWidgetOfExactType<EscopoAparencia>();
    assert(escopo != null, 'EscopoAparencia não encontrado na árvore.');
    return escopo!.notifier!;
  }
}

/// Traduz uma [PreferenciaAparencia] nos valores que o [MaterialApp] espera.
@immutable
class AparenciaResolvida {
  /// Tema usado quando o aparelho está em modo claro.
  final ThemeData temaClaro;

  /// Tema usado quando o aparelho está em modo escuro.
  final ThemeData temaEscuro;

  /// Qual dos dois vale.
  final ThemeMode modo;

  const AparenciaResolvida._({
    required this.temaClaro,
    required this.temaEscuro,
    required this.modo,
  });

  /// Resolve os temas a partir da preferência.
  ///
  /// Quando a pessoa escolhe explicitamente, a escolha dela **prevalece sobre
  /// o modo do aparelho** (FR-020) — inclusive no alto contraste, que é
  /// aplicado independentemente de o sistema estar claro ou escuro.
  factory AparenciaResolvida.de(PreferenciaAparencia preferencia) {
    switch (preferencia.tema) {
      case EscolhaDeTema.seguirSistema:
        return AparenciaResolvida._(
          temaClaro: TemasMemora.porId(MemoraTemaId.claro),
          temaEscuro: TemasMemora.porId(MemoraTemaId.escuro),
          modo: ThemeMode.system,
        );
      case EscolhaDeTema.claro:
        return _fixo(MemoraTemaId.claro, ThemeMode.light);
      case EscolhaDeTema.escuro:
        return _fixo(MemoraTemaId.escuro, ThemeMode.dark);
      case EscolhaDeTema.altoContraste:
        return _fixo(MemoraTemaId.altoContraste, ThemeMode.dark);
    }
  }

  static AparenciaResolvida _fixo(MemoraTemaId id, ThemeMode modo) {
    final ThemeData tema = TemasMemora.porId(id);
    return AparenciaResolvida._(
      temaClaro: tema,
      temaEscuro: tema,
      modo: modo,
    );
  }
}

/// Aplica a ampliação de texto escolhida **dentro do aplicativo** por cima da
/// ampliação do sistema (FR-019).
///
/// O resultado combinado é limitado a [MemoraDimensoes.escalaTextoMax]: sem
/// teto, somar as duas ampliações estoura o layout e a pessoa fica sem saída.
///
/// Use no `builder` do [MaterialApp].
class AmpliacaoDeTexto extends StatelessWidget {
  /// Fator escolhido pela pessoa dentro do aplicativo.
  final double fatorDoAplicativo;

  /// Conteúdo do aplicativo.
  final Widget child;

  /// Cria o aplicador de ampliação.
  const AmpliacaoDeTexto({
    required this.fatorDoAplicativo,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MediaQueryData dados = MediaQuery.of(context);
    final double doSistema = dados.textScaler.scale(1);
    final double combinado = (doSistema * fatorDoAplicativo).clamp(
      MemoraDimensoes.escalaTextoMin,
      MemoraDimensoes.escalaTextoMax,
    );

    return MediaQuery(
      data: dados.copyWith(textScaler: TextScaler.linear(combinado)),
      child: child,
    );
  }
}

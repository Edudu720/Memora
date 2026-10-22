import 'package:memora/features/assistente/data/aceite_do_aviso.dart';

/// O aceite do aviso de privacidade (FR-051) em memória, para os testes.
///
/// `shared_preferences` não existe em teste de widget, e I/O real não completa
/// dentro de `testWidgets`. Conta quantas vezes foi gravado e apagado, para o
/// teste poder afirmar que a limpeza de sessão o levou.
class AceiteEmMemoria implements AceiteDoAviso {
  bool _aceito;

  /// Quantas vezes [registrar] foi chamado.
  int registros = 0;

  /// Quantas vezes [apagar] foi chamado.
  int apagamentos = 0;

  /// Cria o dublê. Por padrão a pessoa **já aceitou** — a maioria dos testes
  /// não trata do aviso e só precisa conversar. Quem testa o aviso passa
  /// `aceito: false`.
  AceiteEmMemoria({bool aceito = true}) : _aceito = aceito;

  @override
  Future<bool> aceitou() async => _aceito;

  @override
  Future<void> registrar() async {
    registros++;
    _aceito = true;
  }

  @override
  Future<void> apagar() async {
    apagamentos++;
    _aceito = false;
  }
}

import 'package:flutter/foundation.dart';

import 'preferencia_aparencia.dart';

/// Controla a aparência do aplicativo em tempo de execução.
///
/// ## Pré-visualização antes de confirmar (FR-023)
///
/// Mudança de aparência é aplicada **imediatamente** enquanto a pessoa
/// experimenta, mas só é **persistida** quando ela confirma. Isso importa para
/// este público: alguém que escolhe um tema difícil de enxergar precisa
/// conseguir voltar sem depender de ler a tela que acabou de ficar ilegível.
///
/// Fluxo: [preVisualizar] → [confirmar] ou [descartar].
class ControladorAparencia extends ChangeNotifier {
  final RepositorioPreferenciaAparencia _repositorio;

  PreferenciaAparencia _confirmada;
  PreferenciaAparencia? _emPreVisualizacao;

  /// Cria o controlador a partir do repositório de persistência.
  ControladorAparencia(
    this._repositorio, {
    PreferenciaAparencia inicial = PreferenciaAparencia.padrao,
  }) : _confirmada = inicial;

  /// A preferência que está valendo agora na tela — a pré-visualizada, se
  /// houver, senão a confirmada.
  PreferenciaAparencia get atual => _emPreVisualizacao ?? _confirmada;

  /// A última preferência efetivamente salva.
  PreferenciaAparencia get confirmada => _confirmada;

  /// Verdadeiro enquanto houver uma mudança sendo experimentada.
  bool get temPreVisualizacao => _emPreVisualizacao != null;

  /// Verdadeiro quando nada está personalizado.
  bool get ehPadrao => atual.ehPadrao;

  /// Lê a preferência salva no aparelho.
  ///
  /// Falha de leitura **não derruba o aplicativo**: mantém o padrão, porque
  /// não conseguir ler uma preferência visual nunca deve impedir alguém de
  /// usar o Memora.
  Future<void> carregar() async {
    try {
      _confirmada = await _repositorio.carregar();
    } on Object {
      // `Object` e não `Exception`: dado de tipo errado lança `TypeError`,
      // que é um `Error`, e o `main` espera este método antes do `runApp`.
      _confirmada = PreferenciaAparencia.padrao;
    }
    _emPreVisualizacao = null;
    notifyListeners();
  }

  /// Aplica uma mudança na tela **sem** persistir.
  void preVisualizar(PreferenciaAparencia preferencia) {
    _emPreVisualizacao = preferencia;
    notifyListeners();
  }

  /// Atalho para pré-visualizar apenas a troca de tema.
  void preVisualizarTema(EscolhaDeTema tema) =>
      preVisualizar(atual.copyWith(tema: tema));

  /// Atalho para pré-visualizar apenas a ampliação de texto.
  void preVisualizarEscalaTexto(double escala) =>
      preVisualizar(atual.copyWith(escalaTexto: escala));

  /// Atalho para pré-visualizar apenas "reduzir movimento".
  void preVisualizarReducaoDeMovimento({required bool reduzir}) =>
      preVisualizar(atual.copyWith(reduzirMovimento: reduzir));

  /// Atalho para pré-visualizar apenas a paleta de cor de destaque.
  void preVisualizarPaleta(String paleta) =>
      preVisualizar(atual.copyWith(paleta: paleta));

  /// Persiste a pré-visualização. Sem pré-visualização, não faz nada.
  Future<void> confirmar() async {
    final PreferenciaAparencia? pendente = _emPreVisualizacao;
    if (pendente == null) return;

    _confirmada = pendente;
    _emPreVisualizacao = null;
    notifyListeners();
    await _repositorio.salvar(_confirmada);
  }

  /// Abandona a pré-visualização e volta ao que estava salvo.
  void descartar() {
    if (_emPreVisualizacao == null) return;
    _emPreVisualizacao = null;
    notifyListeners();
  }

  /// Volta tudo ao padrão de fábrica e **já persiste** (FR-022).
  ///
  /// Não passa por pré-visualização de propósito: esta é a saída de emergência
  /// de quem se perdeu nas configurações, e precisa funcionar em um toque.
  Future<void> voltarAoPadrao() async {
    _emPreVisualizacao = null;
    _confirmada = PreferenciaAparencia.padrao;
    notifyListeners();
    await _repositorio.salvar(_confirmada);
  }
}

import 'package:flutter/foundation.dart';

import '../../../../l10n/textos_antigolpe.dart';
import '../../../assistente/domain/assistente.dart';
import '../../domain/entidades/analise_golpe.dart';
import '../../domain/repositorios/repositorio_analise_golpe.dart';
import '../../domain/servicos/analisador_local_de_golpes.dart';

/// Controlador de estado da tela de análise antigolpe.
class ControladorAnaliseGolpe extends ChangeNotifier {
  final RepositorioAnaliseGolpe _repositorio;

  bool _carregando = false;
  String? _erro;
  String? _erroCampo;
  AnaliseGolpe? _resultado;
  bool _descartado = false;
  int _requisicaoId = 0;

  /// Cria o controlador vinculado ao [repositorio].
  ControladorAnaliseGolpe({required RepositorioAnaliseGolpe repositorio})
    : _repositorio = repositorio;

  /// Verdadeiro enquanto uma análise está em andamento.
  bool get carregando => _carregando;

  /// Mensagem de erro geral quando a análise falha (ex.: sessão expirada).
  String? get erro => _erro;

  /// Mensagem de validação vinculada ao campo de texto.
  String? get erroCampo => _erroCampo;

  /// Último resultado obtido com sucesso (online ou fallback offline).
  AnaliseGolpe? get resultado => _resultado;

  /// Valida e envia [texto] para análise.
  Future<void> analisar(String texto) async {
    final String limpo = texto.trim();
    if (limpo.isEmpty) {
      _erroCampo = TextosAntigolpe.erroVazio;
      _erro = null;
      _resultado = null;
      _notificar();
      return;
    }
    if (limpo.length > AnalisadorLocalDeGolpes.limiteCaracteres) {
      _erroCampo = TextosAntigolpe.erroMuitoLongo;
      _erro = null;
      _resultado = null;
      _notificar();
      return;
    }

    final int idAtual = ++_requisicaoId;
    _carregando = true;
    _erro = null;
    _erroCampo = null;
    _notificar();

    try {
      final AnaliseGolpe analise = await _repositorio.analisar(limpo);
      if (_descartado || idAtual != _requisicaoId) return;
      _resultado = analise;
      _carregando = false;
      _notificar();
    } on FalhaDeChamadaDaAssistente catch (e) {
      if (_descartado || idAtual != _requisicaoId) return;
      _carregando = false;
      _erro = e.falha == FalhaDaAssistente.sessaoExpirada
          ? TextosAntigolpe.sessaoExpirada
          : TextosAntigolpe.erroInesperado;
      _notificar();
    } on ConteudoAnaliseInvalidoException catch (e) {
      if (_descartado || idAtual != _requisicaoId) return;
      _carregando = false;
      _erroCampo = e.mensagem;
      _notificar();
    } catch (_) {
      if (_descartado || idAtual != _requisicaoId) return;
      _carregando = false;
      _erro = TextosAntigolpe.erroInesperado;
      _notificar();
    }
  }

  /// Lê texto da área de transferência por meio de [leitorAreaTransferencia].
  Future<String?> colar(
    Future<String?> Function() leitorAreaTransferencia,
  ) async {
    String? textoLido;
    try {
      textoLido = await leitorAreaTransferencia();
    } catch (_) {
      textoLido = null;
    }
    if (_descartado) return null;

    if (textoLido == null || textoLido.trim().isEmpty) {
      _erroCampo = TextosAntigolpe.erroAreaTransferenciaVazia;
      _notificar();
      return null;
    }

    _erroCampo = null;
    _erro = null;
    _notificar();
    return textoLido;
  }

  /// Limpa a mensagem de validação quando a pessoa edita o texto.
  void aoAlterarTexto() {
    if (_erroCampo != null) {
      _erroCampo = null;
      _notificar();
    }
  }

  /// Limpa o resultado, erros e invalida qualquer análise em andamento.
  void limpar() {
    _requisicaoId++;
    _carregando = false;
    _erro = null;
    _erroCampo = null;
    _resultado = null;
    _notificar();
  }

  /// Limpa apenas o estado de erro atual.
  void limparErro() {
    if (_erro != null || _erroCampo != null) {
      _erro = null;
      _erroCampo = null;
      _notificar();
    }
  }

  void _notificar() {
    if (!_descartado) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _descartado = true;
    _requisicaoId++;
    super.dispose();
  }
}

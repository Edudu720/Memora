import 'package:flutter/foundation.dart';

import '../../../../l10n/textos_antigolpe.dart';
import '../../../assistente/domain/assistente.dart';
import '../../domain/entidades/analise_golpe.dart';
import '../../domain/repositorios/repositorio_analise_golpe.dart';
import '../../domain/servicos/analisador_local_de_golpes.dart';

/// Controlador de estado da tela de análise antigolpe.
class ControladorAnaliseGolpe extends ChangeNotifier {
  final RepositorioAnaliseGolpe _repositorio;

  String _texto = '';
  bool _carregando = false;
  String? _erro;
  String? _erroCampo;
  AnaliseGolpe? _resultado;
  bool _ultimoErroEhSessaoExpirada = false;
  bool _descartado = false;
  int _requisicaoId = 0;

  /// Cria o controlador vinculado ao [repositorio].
  ControladorAnaliseGolpe({required RepositorioAnaliseGolpe repositorio})
    : _repositorio = repositorio;

  /// Verdadeiro enquanto uma análise está em andamento.
  bool get carregando => _carregando;

  /// Mensagem de erro geral quando a análise falha (ex.: sessão expirada ou 429).
  String? get erro => _erro;

  /// Mensagem de validação vinculada ao campo de texto.
  String? get erroCampo => _erroCampo;

  /// Último resultado obtido com sucesso (online ou fallback offline).
  AnaliseGolpe? get resultado => _resultado;

  /// Verdadeiro quando o erro atual decorre de sessão expirada (`401`).
  bool get ultimoErroEhSessaoExpirada => _ultimoErroEhSessaoExpirada;

  /// Valida e envia [texto] para análise.
  Future<void> analisar(String texto) async {
    _texto = texto;
    final String limpo = texto.trim();
    if (limpo.isEmpty) {
      _erroCampo = TextosAntigolpe.erroVazio;
      _erro = null;
      _resultado = null;
      _ultimoErroEhSessaoExpirada = false;
      _notificar();
      return;
    }
    if (limpo.length > AnalisadorLocalDeGolpes.limiteCaracteres) {
      _erroCampo = TextosAntigolpe.erroMuitoLongo;
      _erro = null;
      _resultado = null;
      _ultimoErroEhSessaoExpirada = false;
      _notificar();
      return;
    }

    final int idAtual = ++_requisicaoId;
    _carregando = true;
    _erro = null;
    _erroCampo = null;
    _resultado = null;
    _ultimoErroEhSessaoExpirada = false;
    _notificar();

    try {
      final AnaliseGolpe analise = await _repositorio.analisar(limpo);
      if (_descartado || idAtual != _requisicaoId) return;
      _resultado = analise;
      _carregando = false;
      _ultimoErroEhSessaoExpirada = false;
      _notificar();
    } on FalhaDeChamadaDaAssistente catch (e) {
      if (_descartado || idAtual != _requisicaoId) return;
      _carregando = false;
      _resultado = null;
      _ultimoErroEhSessaoExpirada =
          e.falha == FalhaDaAssistente.sessaoExpirada;
      _erro = _ultimoErroEhSessaoExpirada
          ? TextosAntigolpe.sessaoExpirada
          : TextosAntigolpe.erroInesperado;
      _notificar();
    } on ConteudoAnaliseInvalidoException catch (e) {
      if (_descartado || idAtual != _requisicaoId) return;
      _carregando = false;
      _resultado = null;
      _ultimoErroEhSessaoExpirada = false;
      _erroCampo = e.mensagem;
      _notificar();
    } on FalhaAnaliseGolpe catch (e) {
      if (_descartado || idAtual != _requisicaoId) return;
      _carregando = false;
      _resultado = null;
      _ultimoErroEhSessaoExpirada = false;
      _erro = e.tipo == FalhaAnaliseGolpeTipo.limiteExcedido
          ? TextosAntigolpe.erroLimiteAnalises
          : (e.mensagem.isNotEmpty ? e.mensagem : TextosAntigolpe.erroInesperado);
      _notificar();
    } catch (_) {
      if (_descartado || idAtual != _requisicaoId) return;
      _carregando = false;
      _resultado = null;
      _ultimoErroEhSessaoExpirada = false;
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

    _texto = textoLido;
    _erroCampo = null;
    _erro = null;
    _resultado = null;
    _ultimoErroEhSessaoExpirada = false;
    _notificar();
    return textoLido;
  }

  /// Limpa erros e resultado desatualizado quando a pessoa altera o texto.
  void aoAlterarTexto([String? valor]) {
    final bool textoMudou = valor == null || valor != _texto;
    if (valor != null) {
      _texto = valor;
    }
    bool mudouEstado = false;
    if (_erroCampo != null) {
      _erroCampo = null;
      mudouEstado = true;
    }
    if (textoMudou) {
      if (_erro != null || _ultimoErroEhSessaoExpirada) {
        _erro = null;
        _ultimoErroEhSessaoExpirada = false;
        mudouEstado = true;
      }
      if (_resultado != null) {
        _resultado = null;
        mudouEstado = true;
      }
    }
    if (mudouEstado) {
      _notificar();
    }
  }

  /// Limpa o resultado, erros e invalida qualquer análise em andamento.
  void limpar() {
    _requisicaoId++;
    _texto = '';
    _carregando = false;
    _erro = null;
    _erroCampo = null;
    _resultado = null;
    _ultimoErroEhSessaoExpirada = false;
    _notificar();
  }

  /// Limpa apenas o estado de erro atual.
  void limparErro() {
    if (_erro != null || _erroCampo != null || _ultimoErroEhSessaoExpirada) {
      _erro = null;
      _erroCampo = null;
      _ultimoErroEhSessaoExpirada = false;
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

import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../l10n/textos_assistente.dart';
import '../domain/leitor_de_voz.dart';

/// Implementação nativa de ditado por voz baseada em `speech_to_text` (FR-013 / FR-004).
///
/// Exige processamento estritamente local (`onDevice: true`), entrega apenas
/// resultados em memória para o rascunho da conversa e jamais persiste áudio em
/// disco ou envia fala para servidores externos em fallback.
class LeitorDeVozSpeechToText implements LeitorDeVoz {
  final SpeechToText _speech;
  bool _inicializado = false;
  bool _escutando = false;
  bool _iniciandoEscuta = false;
  ResultadoDitado? _erroDuranteInicio;
  String? _localePreferido;
  void Function(ResultadoDitado)? _aoMudarEstado;

  /// Cria o leitor nativo de voz para a conversa.
  LeitorDeVozSpeechToText({
    SpeechToText? speech,
    void Function(ResultadoDitado)? aoMudarEstado,
  }) : _speech = speech ?? SpeechToText(),
       _aoMudarEstado = aoMudarEstado;

  @override
  Future<ResultadoDitado> verificarDisponibilidade() async {
    try {
      if (!_inicializado) {
        _inicializado = await _speech.initialize(
          onError: _tratarErro,
          onStatus: _tratarStatus,
        );
      }
      if (!_inicializado) {
        return const ResultadoDitado(
          estado: EstadoDitado.indisponivel,
          mensagem: TextosAssistente.vozOfflineIndisponivel,
        );
      }
      _localePreferido ??= await _escolherLocalePortugues();
      return const ResultadoDitado(estado: EstadoDitado.ocioso);
    } on Exception {
      _inicializado = false;
      return const ResultadoDitado(
        estado: EstadoDitado.indisponivel,
        mensagem: TextosAssistente.vozOfflineIndisponivel,
      );
    }
  }

  @override
  Future<ResultadoDitado> iniciarEscuta({
    required void Function(String textoParcial) aoReconhecer,
  }) async {
    final ResultadoDitado disponibilidade = await verificarDisponibilidade();
    if (!disponibilidade.disponivel) return disponibilidade;

    try {
      if (_escutando) {
        await _speech.stop();
      }
      _erroDuranteInicio = null;
      _iniciandoEscuta = true;
      _escutando = true;
      // FR-004: reconhecimento estritamente local no dispositivo (`onDevice: true`).
      // Nunca repetir chamada com `onDevice: false` em caso de falha ou ausência de pacote.
      await _speech.listen(
        onResult: (SpeechRecognitionResult resultado) {
          final String texto = resultado.recognizedWords.trim();
          if (texto.isNotEmpty) {
            aoReconhecer(texto);
          }
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          onDevice: true,
          localeId: _localePreferido ?? 'pt_BR',
        ),
      );
      _iniciandoEscuta = false;
      if (_erroDuranteInicio != null) {
        _escutando = false;
        return _erroDuranteInicio!;
      }
      return const ResultadoDitado(estado: EstadoDitado.ouvindo);
    } on Exception {
      _iniciandoEscuta = false;
      _escutando = false;
      return const ResultadoDitado(
        estado: EstadoDitado.indisponivel,
        mensagem: TextosAssistente.vozOfflineIndisponivel,
      );
    }
  }

  @override
  Future<void> pararEscuta() async {
    if (_escutando) {
      _escutando = false;
      await _speech.stop();
    }
  }

  Future<String?> _escolherLocalePortugues() async {
    try {
      final List<LocaleName> idiomas = await _speech.locales();
      for (final LocaleName item in idiomas) {
        final String norm = item.localeId.toLowerCase();
        if (norm == 'pt_br' || norm == 'pt-br') return item.localeId;
      }
      for (final LocaleName item in idiomas) {
        if (item.localeId.toLowerCase().startsWith('pt')) return item.localeId;
      }
    } on Exception {
      // Usa o padrão pt_BR caso o aparelho não liste idiomas antecipadamente.
    }
    return 'pt_BR';
  }

  void _tratarErro(SpeechRecognitionError erro) {
    _escutando = false;
    final String codigo = erro.errorMsg.toLowerCase();
    final bool indisponivelLocal = erro.permanent ||
        codigo.contains('offline') ||
        codigo.contains('language') ||
        codigo.contains('network') ||
        codigo.contains('recognizer') ||
        codigo.contains('error_client') ||
        codigo.contains('error_server');
    final ResultadoDitado resultado = ResultadoDitado(
      estado: indisponivelLocal ? EstadoDitado.indisponivel : EstadoDitado.erro,
      mensagem: indisponivelLocal
          ? TextosAssistente.vozOfflineIndisponivel
          : TextosAssistente.vozErro,
    );
    if (_iniciandoEscuta) {
      _erroDuranteInicio = resultado;
    }
    _aoMudarEstado?.call(resultado);
  }

  void _tratarStatus(String status) {
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _escutando = false;
      _aoMudarEstado?.call(const ResultadoDitado(estado: EstadoDitado.ocioso));
    }
  }

  @override
  void dispose() {
    _aoMudarEstado = null;
    if (_escutando) {
      _escutando = false;
      unawaited(_speech.cancel());
    }
  }
}

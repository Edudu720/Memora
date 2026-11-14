import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../domain/leitor_de_voz.dart';

/// Implementação nativa de ditado por voz baseada em `speech_to_text` (FR-013).
///
/// Captura a fala em tempo real com preferência por `pt_BR`, entrega apenas
/// resultados em memória para o rascunho da conversa e jamais persiste áudio em
/// disco ou grava conteúdo falado em logs.
class LeitorDeVozSpeechToText implements LeitorDeVoz {
  final SpeechToText _speech;
  bool _inicializado = false;
  bool _escutando = false;
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
        return const ResultadoDitado(estado: EstadoDitado.indisponivel);
      }
      _localePreferido ??= await _escolherLocalePortugues();
      return const ResultadoDitado(estado: EstadoDitado.ocioso);
    } on Exception {
      _inicializado = false;
      return const ResultadoDitado(estado: EstadoDitado.indisponivel);
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
      _escutando = true;
      await _speech.listen(
        onResult: (SpeechRecognitionResult resultado) {
          final String texto = resultado.recognizedWords.trim();
          if (texto.isNotEmpty) {
            aoReconhecer(texto);
          }
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          localeId: _localePreferido ?? 'pt_BR',
        ),
      );
      return const ResultadoDitado(estado: EstadoDitado.ouvindo);
    } on Exception {
      _escutando = false;
      return const ResultadoDitado(estado: EstadoDitado.erro);
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
    final EstadoDitado estado = erro.permanent
        ? EstadoDitado.indisponivel
        : EstadoDitado.erro;
    _aoMudarEstado?.call(ResultadoDitado(estado: estado));
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

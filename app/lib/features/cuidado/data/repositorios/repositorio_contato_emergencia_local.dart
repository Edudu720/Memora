import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entidades/contato_emergencia.dart';
import '../../domain/repositorios/repositorio_contato_emergencia.dart';

/// Implementação local do repositório de contato de emergência usando SharedPreferences.
class RepositorioContatoEmergenciaLocal implements RepositorioContatoEmergencia {
  /// Cria uma instância de [RepositorioContatoEmergenciaLocal].
  RepositorioContatoEmergenciaLocal([SharedPreferences? preferences])
      : _prefsInstancia = preferences;

  SharedPreferences? _prefsInstancia;
  static const String _chaveContato = 'memora_contato_emergencia';

  Future<SharedPreferences> get _prefs async =>
      _prefsInstancia ??= await SharedPreferences.getInstance();

  @override
  Future<ContatoEmergencia?> obterContato() async {
    final SharedPreferences prefs = await _prefs;
    final String? jsonString = prefs.getString(_chaveContato);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> mapa =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return ContatoEmergencia.fromJson(mapa);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> salvarContato(ContatoEmergencia contato) async {
    final SharedPreferences prefs = await _prefs;
    final String jsonString = jsonEncode(contato.toJson());
    await prefs.setString(_chaveContato, jsonString);
  }

  @override
  Future<void> removerContato() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.remove(_chaveContato);
  }
}

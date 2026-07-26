import 'package:shared_preferences/shared_preferences.dart';

import '../../design_system/preferencias/preferencia_aparencia.dart';

/// Persistência da preferência de aparência no próprio aparelho.
///
/// Usa armazenamento simples e **não criptografado**, por decisão explícita:
/// a preferência de aparência é classificada como **Interno**, não como
/// sensível. Credenciais continuam obrigatoriamente em armazenamento seguro,
/// conforme a Constituição.
///
/// Vive em `services/` para que o Design System não dependa de nenhum
/// mecanismo de armazenamento — ele conhece apenas a interface
/// [RepositorioPreferenciaAparencia].
class RepositorioPreferenciaAparenciaLocal
    implements RepositorioPreferenciaAparencia {
  static const String _chaveTema = 'aparencia.tema';
  static const String _chaveEscalaTexto = 'aparencia.escala_texto';

  final SharedPreferences _preferencias;

  /// Cria o repositório a partir de uma instância já aberta.
  const RepositorioPreferenciaAparenciaLocal(this._preferencias);

  /// Abre o armazenamento e devolve o repositório pronto para uso.
  static Future<RepositorioPreferenciaAparenciaLocal> abrir() async {
    return RepositorioPreferenciaAparenciaLocal(
      await SharedPreferences.getInstance(),
    );
  }

  @override
  Future<PreferenciaAparencia> carregar() async {
    final String? nomeTema = _preferencias.getString(_chaveTema);
    final double? escala = _preferencias.getDouble(_chaveEscalaTexto);

    return PreferenciaAparencia(
      tema: _temaPorNome(nomeTema),
      // copyWith limita a faixa; aqui garantimos o padrão quando ausente.
      escalaTexto: escala ?? PreferenciaAparencia.padrao.escalaTexto,
    ).copyWith();
  }

  @override
  Future<void> salvar(PreferenciaAparencia preferencia) async {
    await _preferencias.setString(_chaveTema, preferencia.tema.name);
    await _preferencias.setDouble(_chaveEscalaTexto, preferencia.escalaTexto);
  }

  /// Converte o nome salvo de volta para [EscolhaDeTema].
  ///
  /// Valor desconhecido — de uma versão futura ou de dado corrompido —
  /// retorna ao padrão em vez de quebrar o aplicativo.
  EscolhaDeTema _temaPorNome(String? nome) {
    if (nome == null) return PreferenciaAparencia.padrao.tema;
    for (final EscolhaDeTema tema in EscolhaDeTema.values) {
      if (tema.name == nome) return tema;
    }
    return PreferenciaAparencia.padrao.tema;
  }
}

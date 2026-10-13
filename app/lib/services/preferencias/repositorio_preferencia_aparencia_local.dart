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
  static const String _chaveReduzirMovimento = 'aparencia.reduzir_movimento';
  static const String _chavePaleta = 'aparencia.paleta';

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
    // Cada chave é lida com segurança, com o padrão **dela**: valor de outro
    // tipo (dado corrompido, versão antiga) faria `getBool` e companhia
    // lançarem `TypeError`, e uma chave ruim não pode derrubar o aplicativo
    // nem zerar as outras — quem está em 200% continua em 200%.
    final Object? tema = _ler(_chaveTema);
    final Object? escala = _ler(_chaveEscalaTexto);
    final Object? reduzir = _ler(_chaveReduzirMovimento);
    final Object? paleta = _ler(_chavePaleta);

    return PreferenciaAparencia(
      tema: _temaPorNome(tema is String ? tema : null),
      // copyWith limita a faixa; aqui garantimos o padrão quando ausente.
      escalaTexto: escala is num
          ? escala.toDouble()
          : PreferenciaAparencia.padrao.escalaTexto,
      reduzirMovimento: reduzir is bool
          ? reduzir
          : PreferenciaAparencia.padrao.reduzirMovimento,
      // Nome de paleta que não existe (retirada numa versão nova, ou dado
      // corrompido) volta ao padrão: o `copyWith` confere.
      paleta: paleta is String ? paleta : PreferenciaAparencia.paletaPadrao,
    ).copyWith();
  }

  Object? _ler(String chave) {
    try {
      return _preferencias.get(chave);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> salvar(PreferenciaAparencia preferencia) async {
    await _preferencias.setString(_chaveTema, preferencia.tema.name);
    await _preferencias.setDouble(_chaveEscalaTexto, preferencia.escalaTexto);
    await _preferencias.setBool(
      _chaveReduzirMovimento,
      preferencia.reduzirMovimento,
    );
    await _preferencias.setString(_chavePaleta, preferencia.paleta);
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

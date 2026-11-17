import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../assistente/data/abridor_de_aplicativo.dart';
import '../../data/catalogo_aplicativos_comuns.dart';
import '../../domain/entidades/atalho_aplicativo.dart';
import '../../domain/repositorios/i_repositorio_atalhos.dart';
import 'estado_tela_atalhos.dart';

/// Função injetável para abertura externa da página oficial na loja.
typedef AbridorDeUrlExterna = Future<bool> Function(Uri url);

/// Controlador da tela de atalhos diretos para aplicativos (Feature 015).
///
/// Orquestra o carregamento da lista de aplicativos comuns, o disparo seguro de
/// aplicativos instalados via [AbridorDeAplicativo] e o encaminhamento à
/// Google Play Store oficial para aplicativos não instalados.
class AtalhosAplicativosController extends ValueNotifier<EstadoTelaAtalhos> {
  final IRepositorioAtalhos _repositorio;
  final AbridorDeAplicativo? _abridor;
  final AbridorDeUrlExterna _abridorDeUrl;
  bool _descartado = false;

  /// Cria o controlador da tela de atalhos.
  AtalhosAplicativosController({
    required IRepositorioAtalhos repositorio,
    AbridorDeAplicativo? abridor,
    AbridorDeUrlExterna? abridorDeUrl,
  }) : _repositorio = repositorio,
       _abridor = abridor,
       _abridorDeUrl = abridorDeUrl ?? _abrirNaLojaDoSistema,
       super(const EstadoTelaAtalhos());

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }

  /// Carrega os aplicativos do repositório consultando quais estão instalados.
  Future<void> carregar() async {
    value = EstadoTelaAtalhos(aplicativos: value.aplicativos);
    final List<AtalhoAplicativo> obtidos = await _repositorio.obterAtalhos();
    if (_descartado) return;
    value = EstadoTelaAtalhos(
      carregando: false,
      aplicativos: obtidos,
    );
  }

  /// Solicita ao sistema operacional a abertura do aplicativo instalado.
  ///
  /// Só aceita pacotes pertencentes estritamente ao [CatalogoAplicativosComuns].
  Future<bool> abrirAplicativo(AtalhoAplicativo aplicativo) async {
    if (!CatalogoAplicativosComuns.pertenceAoCatalogo(aplicativo.pacoteAndroid)) {
      return false;
    }
    final AbridorDeAplicativo? abridor = _abridor;
    if (abridor == null) return false;
    try {
      return await abridor.abrir(aplicativo.pacoteAndroid);
    } catch (_) {
      return false;
    }
  }

  /// Abre a página oficial do aplicativo na Google Play Store.
  ///
  /// Só aceita pacotes pertencentes estritamente ao [CatalogoAplicativosComuns].
  Future<bool> abrirNaPlayStore(AtalhoAplicativo aplicativo) async {
    if (!CatalogoAplicativosComuns.pertenceAoCatalogo(aplicativo.pacoteAndroid)) {
      return false;
    }
    final Uri uriLoja = urlPlayStoreDe(aplicativo.pacoteAndroid);
    try {
      final bool abriuLoja = await _abridorDeUrl(uriLoja);
      if (abriuLoja) return true;
      if (_abridorDeUrl != _abrirNaLojaDoSistema) {
        return false;
      }
      return await _abridorDeUrl(urlWebPlayStoreDe(aplicativo.pacoteAndroid));
    } catch (_) {
      return false;
    }
  }

  /// URI do aplicativo na Google Play Store pelo protocolo `market://`.
  static Uri urlPlayStoreDe(String pacoteAndroid) {
    return Uri(
      scheme: 'market',
      host: 'details',
      queryParameters: <String, String>{'id': pacoteAndroid},
    );
  }

  /// URI web oficial da Google Play Store usada como fallback seguro.
  static Uri urlWebPlayStoreDe(String pacoteAndroid) {
    return Uri.https(
      'play.google.com',
      '/store/apps/details',
      <String, String>{'id': pacoteAndroid},
    );
  }

  static Future<bool> _abrirNaLojaDoSistema(Uri url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

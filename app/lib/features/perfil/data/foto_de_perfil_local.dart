import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/seguranca/limpeza_de_sessao.dart';
import '../domain/retrato_de_perfil.dart';

/// Onde a foto de perfil (ou avatar escolhido) fica guardada por conta (FR-006).
abstract interface class ArmazenamentoDeFotoDePerfil {
  /// Fluxo broadcast disparado sempre que o retrato de qualquer conta é
  /// alterado, removido ou expurgado neste aparelho (`022-avatares-no-chat`).
  Stream<void> get alteracoes;

  /// O retrato salvo para [idDaConta], ou `null` quando ausente ou ilegível.
  Future<RetratoDePerfil?> ler(String idDaConta);

  /// Grava uma foto própria já sanitizada para [idDaConta], substituindo
  /// qualquer escolha anterior dessa conta.
  Future<FotoPropriaDePerfil> salvarFoto(
    String idDaConta,
    Uint8List bytesJpegSanitizados,
  );

  /// Grava a escolha de [avatar] para [idDaConta], removendo eventual arquivo
  /// de foto anterior dessa conta.
  Future<AvatarIlustradoDePerfil> salvarAvatar(
    String idDaConta,
    AvatarIlustrado avatar,
  );

  /// Remove definitivamente o retrato de [idDaConta] deste aparelho.
  Future<void> apagar(String idDaConta);
}

/// Armazenamento local ligado ao ciclo de [DadoLocalDoAparelho]: preservado na
/// saída comum da conta e expurgado no `esquecerTudo` (FR-009).
abstract interface class FotoDePerfilDoAparelho
    implements ArmazenamentoDeFotoDePerfil, DadoLocalDoAparelho {}

/// Armazena metadados de escolha em `SharedPreferences` (por conta) e os
/// arquivos `.jpg` no diretório privado de suporte do aplicativo (`fotos_perfil`).
class FotoDePerfilLocal implements FotoDePerfilDoAparelho {
  /// Prefixo das chaves no `SharedPreferences`.
  static const String prefixoChave = 'memora.foto_perfil.v1.';

  /// Nome do subdiretório privado onde moram os arquivos `.jpg`.
  static const String subdiretorioFotos = 'fotos_perfil';

  final SharedPreferences _preferencias;
  final Future<Directory> Function() _diretorioBase;
  final DateTime Function() _agora;
  final StreamController<void> _alteracoes = StreamController<void>.broadcast();

  /// Cria o armazenamento real (com [diretorioBase] e [agora] injetáveis).
  FotoDePerfilLocal(
    this._preferencias, {
    Future<Directory> Function()? diretorioBase,
    DateTime Function()? agora,
  })  : _diretorioBase = diretorioBase ?? getApplicationSupportDirectory,
        _agora = agora ?? DateTime.now;

  @override
  Stream<void> get alteracoes => _alteracoes.stream;

  void _notificarAlteracao() {
    if (!_alteracoes.isClosed) {
      _alteracoes.add(null);
    }
  }

  static bool _semConta(String idDaConta) => idDaConta.trim().isEmpty;

  /// Codifica o identificador de conta com caracteres seguros `[a-zA-Z0-9_-]`
  /// para evitar qualquer possibilidade de *path traversal* (`../`, `/`, `\`).
  static String contaSegura(String idDaConta) {
    final String normalizado = idDaConta.trim();
    if (normalizado.isEmpty) {
      throw ArgumentError.value(
        idDaConta,
        'idDaConta',
        'sem id da conta o retrato nao tem de quem ser',
      );
    }
    return base64Url.encode(utf8.encode(normalizado)).replaceAll('=', '');
  }

  static String _chaveDaConta(String idDaConta) =>
      '$prefixoChave${contaSegura(idDaConta)}';

  Future<Directory> _garantirDiretorioFotos() async {
    final Directory base = await _diretorioBase();
    final Directory dir = Directory('${base.path}${Platform.pathSeparator}$subdiretorioFotos');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _caminhoArquivo(Directory dir, String nomeArquivo) =>
      '${dir.path}${Platform.pathSeparator}$nomeArquivo';

  @override
  Future<RetratoDePerfil?> ler(String idDaConta) async {
    if (_semConta(idDaConta)) return null;

    final String? bruto = _preferencias.getString(_chaveDaConta(idDaConta));
    if (bruto == null || bruto.isEmpty) return null;

    try {
      final Object? decodificado = jsonDecode(bruto);
      if (decodificado is! Map<String, dynamic>) return null;

      final String? tipo = decodificado['tipo'] as String?;
      if (tipo == 'avatar') {
        final AvatarIlustrado? avatar =
            AvatarIlustrado.porChave(decodificado['avatar'] as String?);
        return avatar == null ? null : AvatarIlustradoDePerfil(avatar);
      }

      if (tipo == 'foto') {
        final String? nomeArquivo = decodificado['arquivo'] as String?;
        if (nomeArquivo == null ||
            nomeArquivo.isEmpty ||
            nomeArquivo.contains('/') ||
            nomeArquivo.contains('\\') ||
            nomeArquivo.contains('..')) {
          return null;
        }
        final Directory dir = await _garantirDiretorioFotos();
        final File arquivo = File(_caminhoArquivo(dir, nomeArquivo));
        if (!arquivo.existsSync()) return null;

        final int tamanho = arquivo.lengthSync();
        if (tamanho <= 0) return null;

        final DateTime? atualizadaEm = DateTime.tryParse(
          (decodificado['atualizadaEm'] as String?) ?? '',
        );

        return FotoPropriaDePerfil(
          caminhoDoArquivo: arquivo.path,
          atualizadaEm: atualizadaEm ?? DateTime.fromMillisecondsSinceEpoch(0),
        );
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  @override
  Future<FotoPropriaDePerfil> salvarFoto(
    String idDaConta,
    Uint8List bytesJpegSanitizados,
  ) async {
    final String segura = contaSegura(idDaConta);
    final DateTime agora = _agora().toUtc();
    final String arquivoAnterior = _nomeArquivoAtual(idDaConta);

    final Directory dir = await _garantirDiretorioFotos();
    final String novoNome = '${segura}_${agora.microsecondsSinceEpoch}.jpg';
    final File destino = File(_caminhoArquivo(dir, novoNome));
    await destino.writeAsBytes(bytesJpegSanitizados, flush: true);

    final String json = jsonEncode(<String, String>{
      'tipo': 'foto',
      'arquivo': novoNome,
      'atualizadaEm': agora.toIso8601String(),
    });
    await _preferencias.setString(_chaveDaConta(idDaConta), json);

    if (arquivoAnterior.isNotEmpty && arquivoAnterior != novoNome) {
      await _apagarArquivoSeExistir(dir, arquivoAnterior);
    }

    _notificarAlteracao();
    return FotoPropriaDePerfil(
      caminhoDoArquivo: destino.path,
      atualizadaEm: agora,
    );
  }

  @override
  Future<AvatarIlustradoDePerfil> salvarAvatar(
    String idDaConta,
    AvatarIlustrado avatar,
  ) async {
    contaSegura(idDaConta);
    final String arquivoAnterior = _nomeArquivoAtual(idDaConta);

    final String json = jsonEncode(<String, String>{
      'tipo': 'avatar',
      'avatar': avatar.chave,
    });
    await _preferencias.setString(_chaveDaConta(idDaConta), json);

    if (arquivoAnterior.isNotEmpty) {
      final Directory dir = await _garantirDiretorioFotos();
      await _apagarArquivoSeExistir(dir, arquivoAnterior);
    }

    _notificarAlteracao();
    return AvatarIlustradoDePerfil(avatar);
  }

  @override
  Future<void> apagar(String idDaConta) async {
    if (_semConta(idDaConta)) return;

    final String arquivoAtual = _nomeArquivoAtual(idDaConta);
    await _preferencias.remove(_chaveDaConta(idDaConta));

    if (arquivoAtual.isNotEmpty) {
      final Directory dir = await _garantirDiretorioFotos();
      await _apagarArquivoSeExistir(dir, arquivoAtual);
    }
    _notificarAlteracao();
  }

  @override
  Future<void> esquecerDoAparelho() async {
    final List<String> chaves = _preferencias
        .getKeys()
        .where((String k) => k.startsWith(prefixoChave))
        .toList();
    for (final String chave in chaves) {
      await _preferencias.remove(chave);
    }

    final Directory base = await _diretorioBase();
    final Directory dir =
        Directory('${base.path}${Platform.pathSeparator}$subdiretorioFotos');
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
    _notificarAlteracao();
  }

  String _nomeArquivoAtual(String idDaConta) {
    final String? bruto = _preferencias.getString(_chaveDaConta(idDaConta));
    if (bruto == null || bruto.isEmpty) return '';
    try {
      final Object? decodificado = jsonDecode(bruto);
      if (decodificado is Map<String, dynamic> &&
          decodificado['tipo'] == 'foto') {
        final String? nome = decodificado['arquivo'] as String?;
        if (nome != null &&
            !nome.contains('/') &&
            !nome.contains('\\') &&
            !nome.contains('..')) {
          return nome;
        }
      }
    } catch (_) {
      return '';
    }
    return '';
  }

  Future<void> _apagarArquivoSeExistir(Directory dir, String nome) async {
    try {
      final File f = File(_caminhoArquivo(dir, nome));
      if (f.existsSync()) {
        f.deleteSync();
      }
    } catch (_) {
      // Melhor esforço ao limpar arquivo anterior.
    }
  }
}

/// Implementação leve em memória para testes de widget e fluxo sem plataforma.
class FotoDePerfilEmMemoria implements FotoDePerfilDoAparelho {
  final Map<String, RetratoDePerfil> _retratos = <String, RetratoDePerfil>{};
  final DateTime Function() _agora;
  final StreamController<void> _alteracoes = StreamController<void>.broadcast();

  /// Cria o armazenamento em memória.
  FotoDePerfilEmMemoria({DateTime Function()? agora})
      : _agora = agora ?? DateTime.now;

  @override
  Stream<void> get alteracoes => _alteracoes.stream;

  void _notificarAlteracao() {
    if (!_alteracoes.isClosed) {
      _alteracoes.add(null);
    }
  }

  @override
  Future<RetratoDePerfil?> ler(String idDaConta) async {
    if (FotoDePerfilLocal._semConta(idDaConta)) return null;
    return _retratos[idDaConta.trim()];
  }

  @override
  Future<FotoPropriaDePerfil> salvarFoto(
    String idDaConta,
    Uint8List bytesJpegSanitizados,
  ) async {
    final String chave = idDaConta.trim();
    FotoDePerfilLocal.contaSegura(chave);
    final DateTime agora = _agora().toUtc();
    final FotoPropriaDePerfil salvo = FotoPropriaDePerfil(
      caminhoDoArquivo: 'memoria://$chave/${agora.microsecondsSinceEpoch}.jpg',
      atualizadaEm: agora,
      bytesEmMemoria: Uint8List.fromList(bytesJpegSanitizados),
    );
    _retratos[chave] = salvo;
    _notificarAlteracao();
    return salvo;
  }

  @override
  Future<AvatarIlustradoDePerfil> salvarAvatar(
    String idDaConta,
    AvatarIlustrado avatar,
  ) async {
    final String chave = idDaConta.trim();
    FotoDePerfilLocal.contaSegura(chave);
    final AvatarIlustradoDePerfil salvo = AvatarIlustradoDePerfil(avatar);
    _retratos[chave] = salvo;
    _notificarAlteracao();
    return salvo;
  }

  @override
  Future<void> apagar(String idDaConta) async {
    if (FotoDePerfilLocal._semConta(idDaConta)) return;
    _retratos.remove(idDaConta.trim());
    _notificarAlteracao();
  }

  @override
  Future<void> esquecerDoAparelho() async {
    _retratos.clear();
    _notificarAlteracao();
  }
}

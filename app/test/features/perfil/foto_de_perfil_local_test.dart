import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/assistente/data/aceite_do_aviso.dart';
import 'package:memora/features/autenticacao/data/ultimo_acesso_local.dart';
import 'package:memora/features/perfil/data/foto_de_perfil_local.dart';
import 'package:memora/features/perfil/domain/retrato_de_perfil.dart';
import 'package:memora/services/ambiente/ambiente.dart';
import 'package:memora/services/ambiente/composicao.dart';
import 'package:memora/services/seguranca/cofre_de_credenciais.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FotoDePerfilLocal (FR-006, FR-007, FR-009)', () {
    late Directory tempDir;
    late SharedPreferences prefs;
    late int tickUs;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('memora_foto_perfil_');
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      tickUs = 1000000;
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    FotoDePerfilLocal criarStorage() => FotoDePerfilLocal(
          prefs,
          diretorioBase: () async => tempDir,
          agora: () {
            tickUs += 1000;
            return DateTime.fromMicrosecondsSinceEpoch(tickUs, isUtc: true);
          },
        );

    test('isola estritamente fotos e avatares entre contas diferentes',
        () async {
      final FotoDePerfilLocal storage = criarStorage();
      final Uint8List bytesA = Uint8List.fromList(<int>[1, 2, 3, 4]);

      final FotoPropriaDePerfil salvaA =
          await storage.salvarFoto('conta-A', bytesA);
      expect(File(salvaA.caminhoDoArquivo).existsSync(), isTrue);

      await storage.salvarAvatar('conta-B', AvatarIlustrado.memoraComemorando);

      final RetratoDePerfil? lidaA = await storage.ler('conta-A');
      final RetratoDePerfil? lidaB = await storage.ler('conta-B');
      final RetratoDePerfil? lidaC = await storage.ler('conta-C');

      expect(lidaA, isA<FotoPropriaDePerfil>());
      expect(
        (lidaA as FotoPropriaDePerfil).caminhoDoArquivo,
        salvaA.caminhoDoArquivo,
      );
      expect(lidaB, isA<AvatarIlustradoDePerfil>());
      expect(
        (lidaB as AvatarIlustradoDePerfil).avatar,
        AvatarIlustrado.memoraComemorando,
      );
      expect(lidaC, isNull);
    });

    test('bloqueia path traversal no idDaConta e rejeita id vazio', () async {
      final FotoDePerfilLocal storage = criarStorage();
      final Uint8List bytes = Uint8List.fromList(<int>[9, 8, 7]);

      final FotoPropriaDePerfil salva =
          await storage.salvarFoto('../../etc/passwd', bytes);

      expect(salva.caminhoDoArquivo.startsWith(tempDir.path), isTrue);
      expect(salva.caminhoDoArquivo.contains('..'), isFalse);

      await expectLater(
        () => storage.salvarFoto('   ', bytes),
        throwsArgumentError,
      );
      expect(await storage.ler('   '), isNull);
    });

    test('remove arquivo antigo ao trocar foto ou mudar para avatar', () async {
      final FotoDePerfilLocal storage = criarStorage();
      final FotoPropriaDePerfil primeira =
          await storage.salvarFoto('conta-1', Uint8List.fromList(<int>[1, 2]));
      final FotoPropriaDePerfil segunda =
          await storage.salvarFoto('conta-1', Uint8List.fromList(<int>[3, 4]));

      expect(File(primeira.caminhoDoArquivo).existsSync(), isFalse);
      expect(File(segunda.caminhoDoArquivo).existsSync(), isTrue);

      await storage.salvarAvatar('conta-1', AvatarIlustrado.casalIdoso);
      expect(File(segunda.caminhoDoArquivo).existsSync(), isFalse);
    });

    test('recua silenciosamente para null se arquivo no disco desaparecer',
        () async {
      final FotoDePerfilLocal storage = criarStorage();
      final FotoPropriaDePerfil salva =
          await storage.salvarFoto('conta-1', Uint8List.fromList(<int>[5, 6]));

      File(salva.caminhoDoArquivo).deleteSync();

      expect(await storage.ler('conta-1'), isNull);
    });

    test('apagar remove só a conta alvo; esquecerDoAparelho apaga tudo',
        () async {
      final FotoDePerfilLocal storage = criarStorage();
      final FotoPropriaDePerfil a =
          await storage.salvarFoto('conta-A', Uint8List.fromList(<int>[1]));
      final FotoPropriaDePerfil b =
          await storage.salvarFoto('conta-B', Uint8List.fromList(<int>[2]));

      await storage.apagar('conta-A');
      expect(File(a.caminhoDoArquivo).existsSync(), isFalse);
      expect(await storage.ler('conta-A'), isNull);
      expect(File(b.caminhoDoArquivo).existsSync(), isTrue);
      expect(await storage.ler('conta-B'), isA<FotoPropriaDePerfil>());

      await storage.esquecerDoAparelho();
      expect(await storage.ler('conta-B'), isNull);
      expect(
        Directory('${tempDir.path}${Platform.pathSeparator}fotos_perfil')
            .existsSync(),
        isFalse,
      );
      expect(
        prefs
            .getKeys()
            .where((String k) => k.startsWith(FotoDePerfilLocal.prefixoChave)),
        isEmpty,
      );
    });

    test(
        'Composicao.resolver liga a mesma guarda em limpeza (saída comum mantém, esquecerTudo apaga)',
        () async {
      final FotoDePerfilLocal storage = criarStorage();
      await storage.salvarFoto('conta-1', Uint8List.fromList(<int>[7, 8, 9]));

      final Composicao composicao = Composicao.resolver(
        ambiente: const Ambiente(
          urlBase: 'http://10.0.2.2:8080/v1',
          usaServidorReal: false,
        ),
        cofre: _CofreStub(),
        ultimoAcesso: _UltimoAcessoStub(),
        aceiteDoAviso: _AceiteStub(),
        fotoDePerfil: storage,
      );

      expect(identical(composicao.fotoDePerfil, storage), isTrue);

      await composicao.limpeza.executar();
      expect(await storage.ler('conta-1'), isA<FotoPropriaDePerfil>());

      await composicao.limpeza.executar(esquecerTudo: true);
      expect(await storage.ler('conta-1'), isNull);
    });
  });
}

class _CofreStub implements CofreDeCredenciais {
  @override
  Future<void> guardarSessao({
    required String tokenAcesso,
    required String refreshToken,
  }) async {}

  @override
  Future<void> limpar() async {}

  @override
  Future<String?> refreshToken() async => null;

  @override
  Future<String?> tokenAcesso() async => null;
}

class _UltimoAcessoStub implements UltimoAcesso {
  @override
  Future<void> esquecer() async {}

  @override
  Future<String?> identificador() async => null;

  @override
  Future<void> lembrar(String identificador) async {}
}

class _AceiteStub implements AceiteDoAviso {
  @override
  Future<bool> aceitou() async => false;

  @override
  Future<void> apagar() async {}

  @override
  Future<void> registrar() async {}
}

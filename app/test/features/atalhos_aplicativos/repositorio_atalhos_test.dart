import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/atalhos_aplicativos/data/catalogo_aplicativos_comuns.dart';
import 'package:memora/features/atalhos_aplicativos/data/repositorio_atalhos_aplicativos.dart';
import 'package:memora/features/atalhos_aplicativos/domain/entidades/atalho_aplicativo.dart';
import 'package:memora/services/aplicativos/consulta_de_aplicativos.dart';

void main() {
  group('CatalogoAplicativosComuns — escopo de apps comuns', () {
    test('contém estritamente os 7 aplicativos cotidianos homologados', () {
      expect(CatalogoAplicativosComuns.todos, hasLength(7));
      expect(
        CatalogoAplicativosComuns.todos.map((AtalhoAplicativo a) => a.chave),
        containsAllInOrder(<String>[
          'whatsapp',
          'youtube',
          'instagram',
          'facebook',
          'google_fotos',
          'telegram',
          'tiktok',
        ]),
      );
    });

    test('exclui estritamente serviços sociais, governamentais e financeiros', () {
      const List<String> chavesProibidas = <String>[
        'gov-br',
        'meu-inss',
        'e-titulo',
        'serasa',
        'fgts',
        'poupatempo',
        'carteira-digital',
        'correios',
        'carteira-de-trabalho',
      ];
      for (final AtalhoAplicativo app in CatalogoAplicativosComuns.todos) {
        expect(chavesProibidas, isNot(contains(app.chave)));
        expect(app.pacoteAndroid.contains('gov.br'), isFalse);
      }
    });

    test('todo pacote do catálogo é válido e está em <queries> no AndroidManifest', () {
      final File manifesto = File('android/app/src/main/AndroidManifest.xml');
      expect(manifesto.existsSync(), isTrue);
      final String xml = manifesto.readAsStringSync();

      for (final AtalhoAplicativo app in CatalogoAplicativosComuns.todos) {
        expect(pareceUmPacote(app.pacoteAndroid), isTrue);
        expect(
          xml.contains('<package android:name="${app.pacoteAndroid}"/>'),
          isTrue,
          reason:
              'Pacote ${app.pacoteAndroid} precisa estar em <queries> no AndroidManifest.xml',
        );
      }
    });
  });

  group('RepositorioAtalhosAplicativos', () {
    test('com consulta nula, devolve todos os 7 itens como não instalados', () async {
      const RepositorioAtalhosAplicativos repo = RepositorioAtalhosAplicativos();
      final List<AtalhoAplicativo> itens = await repo.obterAtalhos();

      expect(itens, hasLength(7));
      expect(itens.every((AtalhoAplicativo a) => !a.instalado), isTrue);
    });

    test('marca corretamente instalados, não instalados e ícones carregados', () async {
      final Uint8List pngFalso = Uint8List.fromList(<int>[1, 2, 3, 4]);
      final ConsultaDeAplicativosSimulada consulta =
          ConsultaDeAplicativosSimulada(
            instalados: <String>{
              'com.whatsapp',
              'com.google.android.youtube',
            },
            icones: <String, Uint8List>{
              'com.whatsapp': pngFalso,
            },
          );
      final RepositorioAtalhosAplicativos repo = RepositorioAtalhosAplicativos(
        consulta: consulta,
      );

      final List<AtalhoAplicativo> itens = await repo.obterAtalhos();
      final AtalhoAplicativo whatsapp = itens.firstWhere(
        (AtalhoAplicativo a) => a.chave == 'whatsapp',
      );
      final AtalhoAplicativo youtube = itens.firstWhere(
        (AtalhoAplicativo a) => a.chave == 'youtube',
      );
      final AtalhoAplicativo instagram = itens.firstWhere(
        (AtalhoAplicativo a) => a.chave == 'instagram',
      );

      expect(whatsapp.instalado, isTrue);
      expect(whatsapp.iconeBytes, equals(pngFalso));
      expect(youtube.instalado, isTrue);
      expect(youtube.iconeBytes, isNull);
      expect(instagram.instalado, isFalse);
      expect(instagram.iconeBytes, isNull);
    });

    test('falha na consulta é isolada e tratada como não instalado', () async {
      final RepositorioAtalhosAplicativos repo = RepositorioAtalhosAplicativos(
        consulta: _ConsultaQueFalha(),
      );

      final List<AtalhoAplicativo> itens = await repo.obterAtalhos();
      expect(itens, hasLength(7));
      expect(itens.every((AtalhoAplicativo a) => !a.instalado), isTrue);
    });
  });
}

class _ConsultaQueFalha implements ConsultaDeAplicativos {
  @override
  Future<bool> estaInstalado(String pacote) async => throw Exception('erro');

  @override
  Future<Uint8List?> iconeDe(String pacote) async => throw Exception('erro');
}

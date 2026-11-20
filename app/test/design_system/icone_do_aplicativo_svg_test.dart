import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

void main() {
  const List<String> chaves = <String>['e-titulo', 'fgts', 'instagram'];

  group('Contratos dos arquivos SVG em assets/icones_apps/', () {
    for (final String chave in chaves) {
      test('$chave.svg usa viewBox="0 0 48 48" e vetor puro seguro', () {
        final File arquivo = File('assets/icones_apps/$chave.svg');
        expect(
          arquivo.existsSync(),
          isTrue,
          reason: 'Arquivo ausente: ${arquivo.path}',
        );

        final String conteudo = arquivo.readAsStringSync();
        expect(conteudo, contains('<svg'));
        expect(conteudo, contains('viewBox="0 0 48 48"'));

        final String semXmlns = conteudo
            .toLowerCase()
            .replaceAll('xmlns="http://www.w3.org/2000/svg"', '');
        for (final String proibido in <String>[
          '<script',
          '<foreignobject',
          '<image',
          '<text',
          'javascript:',
          'http://',
          'https://',
          'onload=',
          'onerror=',
        ]) {
          expect(
            semXmlns.contains(proibido),
            isFalse,
            reason: '$chave.svg contém trecho proibido: $proibido',
          );
        }
      });
    }
  });

  group('IconeDoAplicativo renderiza os três ícones em SVG', () {
    for (final String chave in chaves) {
      for (final MemoraTemaId temaId in MemoraTemaId.values) {
        testWidgets('$chave renderiza SvgPicture no tema ${temaId.name}', (
          WidgetTester t,
        ) async {
          await t.pumpWidget(
            MaterialApp(
              theme: TemasMemora.porId(temaId),
              home: Scaffold(
                body: Center(
                  child: IconeDoAplicativo(chave: chave, tamanho: 64),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();

          expect(t.takeException(), isNull);
          expect(find.byType(SvgPicture), findsOneWidget);
          expect(
            t.widget<SvgPicture>(find.byType(SvgPicture)).excludeFromSemantics,
            isTrue,
          );
        });
      }
    }

    testWidgets('aceita fallback pelo nome exibido em tamanhos variados', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: const Scaffold(
            body: Column(
              children: <Widget>[
                IconeDoAplicativo(chave: '', nome: 'e-Título'),
                IconeDoAplicativo(chave: '', nome: 'FGTS', tamanho: 72),
                IconeDoAplicativo(chave: '', nome: 'Instagram', tamanho: 96),
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();

      expect(t.takeException(), isNull);
      expect(find.byType(SvgPicture), findsNWidgets(3));
    });
  });
}

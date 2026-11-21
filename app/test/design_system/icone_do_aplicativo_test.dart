import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

void main() {
  const List<String> chavesSvgOficiais = <String>[
    'meu-inss',
    'tiktok',
    'carteira-digital',
    'carteira-de-trabalho',
    'poupatempo',
    'youtube',
    'google-fotos',
  ];

  group('Contratos estáticos dos 7 SVGs compartilhados (T028)', () {
    test(
      'todos os 7 SVGs existem em assets/icones_apps/ e são autocontidos',
      () {
        for (final String chave in chavesSvgOficiais) {
          final File arquivo = File('assets/icones_apps/$chave.svg');
          expect(
            arquivo.existsSync(),
            isTrue,
            reason: 'Falta assets/icones_apps/$chave.svg',
          );
          final String xml = arquivo.readAsStringSync();
          expect(
            xml,
            contains('viewBox="0 0 48 48"'),
            reason: '$chave.svg deve declarar viewBox="0 0 48 48"',
          );
          final String minusculo = xml
              .toLowerCase()
              .replaceAll('http://www.w3.org/2000/svg', '');
          expect(minusculo.contains('<script'), isFalse);
          expect(minusculo.contains('<image'), isFalse);
          expect(minusculo.contains('<foreignobject'), isFalse);
          expect(minusculo.contains('<text'), isFalse);
          expect(minusculo.contains('http://'), isFalse);
          expect(minusculo.contains('https://'), isFalse);
        }
      },
    );

    test(
      'todos os pares gráficos dos 7 SVGs atingem contraste WCAG 2.2 >= 3,0:1 (T042)',
      () {
        double luminanciaRelativa(String hex) {
          final String limpo = hex.replaceFirst('#', '');
          double canal(int inicio) {
            final double c =
                int.parse(limpo.substring(inicio, inicio + 2), radix: 16) /
                255.0;
            return c <= 0.03928
                ? c / 12.92
                : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
          }

          return 0.2126 * canal(0) + 0.7152 * canal(2) + 0.0722 * canal(4);
        }

        double contraste(String a, String b) {
          final double l1 = luminanciaRelativa(a);
          final double l2 = luminanciaRelativa(b);
          final double maisClara = math.max(l1, l2);
          final double maisEscura = math.min(l1, l2);
          return (maisClara + 0.05) / (maisEscura + 0.05);
        }

        // Fundo direto sobre o qual cada cor de primeiro plano é desenhada.
        final Map<String, Map<String, String>> fundoPorCor =
            <String, Map<String, String>>{
              'meu-inss': <String, String>{
                '#FFD100': '#003882',
                '#FFFFFF': '#003882',
              },
              'tiktok': <String, String>{
                '#00F2FE': '#010101',
                '#FE2C55': '#010101',
                '#FFFFFF': '#010101',
              },
              'carteira-digital': <String, String>{
                '#FFFFFF': '#146342',
                '#146342': '#FFFFFF',
                '#C97600': '#FFFFFF',
              },
              'carteira-de-trabalho': <String, String>{
                '#FFD100': '#0B2545',
                '#FFFFFF': '#0B2545',
                '#0B2545': '#FFFFFF',
              },
              'poupatempo': <String, String>{
                '#1A1A1A': '#CC1414',
                '#FFFFFF': '#CC1414',
              },
              'youtube': <String, String>{'#FFFFFF': '#FF0000'},
              'google-fotos': <String, String>{
                '#C97600': '#FFFFFF',
                '#EA4335': '#FFFFFF',
                '#1E6FD9': '#FFFFFF',
                '#1E8E3E': '#FFFFFF',
              },
            };

        final RegExp regexCor = RegExp(
          r'(?:fill|stroke)="(#[0-9A-Fa-f]{6})"',
        );
        final RegExp regexFundoRaiz = RegExp(
          r'<rect[^>]*width="48"[^>]*fill="(#[0-9A-Fa-f]{6})"',
        );

        for (final String chave in chavesSvgOficiais) {
          final String xml = File('assets/icones_apps/$chave.svg')
              .readAsStringSync();
          final Match? matchRaiz = regexFundoRaiz.firstMatch(xml);
          expect(
            matchRaiz,
            isNotNull,
            reason: '$chave.svg deve declarar retângulo base de fundo',
          );
          final String fundoRaiz = matchRaiz!.group(1)!.toUpperCase();
          final Map<String, String> mapaFundos = fundoPorCor[chave]!;

          final Set<String> coresEncontradas = <String>{
            for (final RegExpMatch m in regexCor.allMatches(xml))
              m.group(1)!.toUpperCase(),
          };
          final Set<String> frentes = coresEncontradas.difference(<String>{
            fundoRaiz,
          });
          expect(
            frentes,
            isNotEmpty,
            reason: '$chave.svg precisa de elementos visíveis em primeiro plano',
          );

          for (final String cor in coresEncontradas) {
            if (cor == fundoRaiz && !mapaFundos.containsKey(cor)) continue;
            final String fundoEsperado = mapaFundos[cor] ?? fundoRaiz;
            final double razao = contraste(cor, fundoEsperado);
            expect(
              razao,
              greaterThanOrEqualTo(3.0),
              reason:
                  '$chave.svg: cor $cor sobre $fundoEsperado atingiu apenas '
                  '${razao.toStringAsFixed(2)}:1 (mínimo WCAG 2.2: 3.00:1)',
            );
          }
        }
      },
    );

    test('todos os 7 SVGs compartilhados estão registrados em LICENCAS.md', () {
      final File licencas = File('assets/ilustracoes/LICENCAS.md');
      expect(licencas.existsSync(), isTrue);
      final String conteudo = licencas.readAsStringSync();
      for (final String chave in chavesSvgOficiais) {
        expect(
          conteudo,
          contains('$chave.svg'),
          reason: '$chave.svg precisa constar em assets/ilustracoes/LICENCAS.md',
        );
      }
    });
  });

  group('Renderização do IconeDoAplicativo nos 3 temas (T029)', () {
    final Map<String, ThemeData> temas = <String, ThemeData>{
      'claro': TemasMemora.claro,
      'escuro': TemasMemora.escuro,
      'altoContraste': TemasMemora.altoContraste,
    };

    for (final MapEntry<String, ThemeData> entradaTema in temas.entries) {
      for (final String chave in chavesSvgOficiais) {
        testWidgets('$chave renderiza via SvgPicture no tema ${entradaTema.key}', (
          WidgetTester t,
        ) async {
          await t.pumpWidget(
            MaterialApp(
              theme: entradaTema.value,
              home: Scaffold(body: Center(child: IconeDoAplicativo(chave: chave))),
            ),
          );
          await t.pumpAndSettle();

          final Finder svgFinder = find.byType(SvgPicture);
          expect(svgFinder, findsOneWidget);
          expect(t.widget<SvgPicture>(svgFinder).excludeFromSemantics, isTrue);
          expect(t.takeException(), isNull);
        });
      }
    }

    testWidgets(
      'ícones reservados ao Item 13 e PNGs continuam intactos e sem erro',
      (WidgetTester t) async {
        for (final String chave in <String>[
          'instagram',
          'e-titulo',
          'fgts',
          'whatsapp',
        ]) {
          await t.pumpWidget(
            MaterialApp(
              theme: TemasMemora.claro,
              home: Scaffold(body: IconeDoAplicativo(chave: chave)),
            ),
          );
          await t.pump();
          expect(find.byType(IconeDoAplicativo), findsOneWidget);
          expect(t.takeException(), isNull);
        }
      },
    );

    testWidgets('chave desconhecida usa o fallback genérico do Memora', (
      WidgetTester t,
    ) async {
      await t.pumpWidget(
        MaterialApp(
          theme: TemasMemora.claro,
          home: const Scaffold(
            body: IconeDoAplicativo(chave: 'aplicativo-desconhecido'),
          ),
        ),
      );
      await t.pump();

      expect(find.byIcon(Icons.apps_rounded), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
    });
  });
}

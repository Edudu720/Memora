import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

import 'contraste_test.dart' show contraste;

/// Os ícones da barra inferior — T112, FR-015 da feature 004.
///
/// Dois portões. O primeiro lê os **arquivos**: grade, traço e cor são o que
/// faz os três pesarem igual, e um arquivo novo desenhado em outra grade
/// quebraria isso sem nenhum widget reclamar. O segundo monta a barra nos três
/// temas e confere o contraste do que ela **de fato** pinta.
void main() {
  group('Os arquivos — mesma grade, mesmo traço, nenhuma cor própria', () {
    for (final IconeDeNavegacao icone in IconeDeNavegacao.values) {
      for (final bool preenchido in <bool>[false, true]) {
        final String caminho = icone.caminho(preenchido: preenchido);

        test(caminho, () {
          final File arquivo = File(caminho);
          expect(arquivo.existsSync(), isTrue, reason: 'o par precisa existir');
          final String svg = arquivo.readAsStringSync();

          // A mesma grade: com viewBox diferente, o "mesmo tamanho" de
          // MemoraDimensoes.iconeDestaque deixaria de ser a mesma área.
          expect(svg, contains('viewBox="0 0 24 24"'));

          // O mesmo traço em todo elemento que traça — e que traça.
          final Iterable<RegExpMatch> tracos = RegExp(
            r'stroke-width="([^"]+)"',
          ).allMatches(svg);
          expect(tracos, isNotEmpty);
          for (final RegExpMatch t in tracos) {
            expect(t.group(1), '2', reason: 'o traço é de 2 em toda a barra');
          }

          // Cor fixa no arquivo é cor que o tema não alcança. O filtro do
          // widget só tinge o que é opaco, e `currentColor` não diz cor
          // nenhuma — o que o arquivo precisa dizer é a ausência.
          expect(
            RegExp(r'#[0-9a-fA-F]{3,8}\b').hasMatch(svg),
            isFalse,
            reason: 'sem cor própria: quem tinge é o tema',
          );
          expect(svg, contains('currentColor'));
          expect(svg, isNot(contains('rgb(')));
        });
      }
    }

    test('o pubspec declara a pasta, senão o app não acha os desenhos', () {
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('assets/icones/navegacao/'),
      );
    });
  });

  group('Contraste do que a barra pinta — WCAG 1.4.11', () {
    const Map<MemoraTemaId, MemoraCores> cores = <MemoraTemaId, MemoraCores>{
      MemoraTemaId.claro: MemoraCores.claro,
      MemoraTemaId.escuro: MemoraCores.escuro,
      MemoraTemaId.altoContraste: MemoraCores.altoContraste,
    };

    for (final MemoraTemaId id in MemoraTemaId.values) {
      testWidgets('tema ${id.name}: ícone atual e ícone inativo ≥ 3:1', (
        WidgetTester t,
      ) async {
        final MemoraCores c = cores[id]!;
        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.porId(id),
            home: Scaffold(
              bottomNavigationBar: NavegacaoInferior(
                indiceAtivo: 1,
                aoSelecionar: (_) {},
                itens: const <ItemNavegacao>[
                  ItemNavegacao(
                    icone: IconeDeNavegacao.ajustes,
                    rotulo: 'Ajustes',
                  ),
                  ItemNavegacao(
                    icone: IconeDeNavegacao.inicio,
                    rotulo: 'Início',
                  ),
                  ItemNavegacao(
                    icone: IconeDeNavegacao.perfil,
                    rotulo: 'Meu perfil',
                  ),
                ],
              ),
            ),
          ),
        );

        ColorFilter? filtroDe(int posicao) => t
            .widget<SvgPicture>(
              find.descendant(
                of: find.byKey(NavegacaoInferior.chaveDoIcone(posicao)),
                matching: find.byType(SvgPicture),
              ),
            )
            .colorFilter;

        // O que a barra pinta, e não o que a paleta tem: o filtro é lido do
        // widget. Se alguém trocar a cor do ícone, o par medido abaixo
        // deixa de ser o que está na tela e este teste reprova.
        const BlendMode modo = BlendMode.srcIn;
        expect(filtroDe(2), ColorFilter.mode(c.primaria, modo));
        expect(filtroDe(1), ColorFilter.mode(c.texto, modo));
        expect(filtroDe(3), ColorFilter.mode(c.texto, modo));

        // Atrás do ícone atual há a pílula; atrás dos outros, a barra.
        expect(
          contraste(c.primaria, c.destaque),
          greaterThanOrEqualTo(3),
          reason: 'ícone atual sobre a pílula',
        );
        expect(
          contraste(c.primaria, c.superficieAlt),
          greaterThanOrEqualTo(3),
          reason: 'ícone atual sobre a barra',
        );
        expect(
          contraste(c.texto, c.superficieAlt),
          greaterThanOrEqualTo(3),
          reason: 'ícone inativo sobre a barra',
        );

        // E a barra é mesmo da cor que se mediu.
        final Material barra = t.widget<Material>(
          find
              .descendant(
                of: find.byType(NavegacaoInferior),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(barra.color, c.superficieAlt);
      });
    }
  });
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

import 'contraste_test.dart' show contraste;

/// Os ícones da barra inferior — T057, FR-045 da feature 013 (R5).
///
/// Dois portões. O primeiro confere a **família**: os desenhos próprios da 004
/// (`assets/icones/navegacao/`) saíram, e cada destino usa o ícone arredondado
/// que vem com o Flutter, como o resto do aplicativo. O segundo monta a barra
/// nos três temas e confere o contraste do que ela **de fato** pinta.
void main() {
  group('A família — um estilo só (FR-045)', () {
    const Map<IconeDeNavegacao, IconData> esperados =
        <IconeDeNavegacao, IconData>{
          IconeDeNavegacao.ajustes: Icons.settings_rounded,
          IconeDeNavegacao.inicio: Icons.home_rounded,
          IconeDeNavegacao.perfil: Icons.person_rounded,
        };

    test('todo destino tem desenho, e é o arredondado', () {
      expect(esperados.keys.toSet(), IconeDeNavegacao.values.toSet());
      for (final IconeDeNavegacao icone in IconeDeNavegacao.values) {
        expect(icone.dados, esperados[icone], reason: icone.name);
      }
    });

    test('os três são da mesma fonte de ícones', () {
      final Set<String?> familias = <String?>{
        for (final IconeDeNavegacao icone in IconeDeNavegacao.values)
          icone.dados.fontFamily,
      };
      expect(familias, <String?>{'MaterialIcons'});
    });

    test('os SVG próprios saíram: pasta apagada e fora do pubspec', () {
      expect(Directory('assets/icones/navegacao').existsSync(), isFalse);
      expect(
        File('pubspec.yaml').readAsStringSync(),
        isNot(contains('assets/icones/navegacao/')),
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

        Color? corDoIcone(int posicao) => t
            .widget<Icon>(
              find.descendant(
                of: find.byKey(NavegacaoInferior.chaveDoIcone(posicao)),
                matching: find.byType(Icon),
              ),
            )
            .color;

        // O que a barra pinta, e não o que a paleta tem: a cor é lida do
        // widget. Se alguém trocar a cor do ícone, o par medido abaixo
        // deixa de ser o que está na tela e este teste reprova.
        expect(corDoIcone(2), c.primaria);
        expect(corDoIcone(1), c.texto);
        expect(corDoIcone(3), c.texto);

        // Atrás do ícone atual há a pílula; atrás dos outros, a barra.
        expect(
          contraste(c.primaria, c.destaque),
          greaterThanOrEqualTo(3),
          reason: 'ícone atual sobre a pílula',
        );
        expect(
          contraste(c.primaria, c.superficieBarra),
          greaterThanOrEqualTo(3),
          reason: 'ícone atual sobre a barra',
        );
        expect(
          contraste(c.texto, c.superficieBarra),
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
        expect(barra.color, c.superficieBarra);
      });
    }
  });
}

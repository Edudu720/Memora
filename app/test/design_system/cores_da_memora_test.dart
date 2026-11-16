import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/componentes/ilustracao/memora_animada/pintores/pintor_da_memora.dart';
import 'package:memora/design_system/design_system.dart';

import 'contraste_test.dart' show contraste;

/// As cores da Memora (feature 013, FR-007): seguem a paleta, e a silhueta
/// continua visível em cada paleta e tema.
///
/// O portão principal dos números é `validar_paleta.py`; este arquivo
/// confere o **código** (Dart), para os dois não divergirem em silêncio, e
/// prova que a paleta de fato chega ao desenho.
void main() {
  const Map<MemoraTemaId, MemoraCores> fundos = <MemoraTemaId, MemoraCores>{
    MemoraTemaId.claro: MemoraCores.claro,
    MemoraTemaId.escuro: MemoraCores.escuro,
    MemoraTemaId.altoContraste: MemoraCores.altoContraste,
  };

  group('contraste em cada paleta e tema', () {
    for (final MemoraTemaId tema in MemoraTemaId.values) {
      for (final String paleta in MemoraCores.paletas.keys) {
        test('${tema.name} / $paleta', () {
          final CoresDaMemora m = CoresDaMemora.para(tema, paleta: paleta);
          final MemoraCores f = fundos[tema]!;
          expect(contraste(m.corpo, f.fundo), greaterThanOrEqualTo(3));
          expect(contraste(m.corpo, f.superficie), greaterThanOrEqualTo(3));
          expect(contraste(m.aro, f.fundo), greaterThanOrEqualTo(3));
          expect(contraste(m.aro, f.superficie), greaterThanOrEqualTo(3));
          expect(contraste(m.contorno, m.corpo), greaterThanOrEqualTo(3));
          expect(contraste(m.olho, m.visor), greaterThanOrEqualTo(3));
        });
      }
    }
  });

  group('a Memora segue a paleta', () {
    test('a azul é a referência', () {
      final CoresDaMemora m = CoresDaMemora.para(MemoraTemaId.claro);
      expect(m.corpo, const Color(0xFF3565F3));
      expect(m.corpoSombra, const Color(0xFF264AA9));
      expect(m.corpoLuz, const Color(0xFF4F76E6));
      expect(m.contorno, const Color(0xFF0D1C50));
      expect(m.visor, const Color(0xFFD7E4FC));
    });

    test('a paleta muda corpo, contorno e visor, e só eles', () {
      final CoresDaMemora azul =
          CoresDaMemora.para(MemoraTemaId.claro, paleta: 'azul');
      for (final String nome in MemoraCores.paletas.keys) {
        if (nome == 'azul') continue;
        final CoresDaMemora outra =
            CoresDaMemora.para(MemoraTemaId.claro, paleta: nome);
        expect(outra.corpo, isNot(azul.corpo), reason: nome);
        expect(outra.contorno, isNot(azul.contorno), reason: nome);
        expect(outra.visor, isNot(azul.visor), reason: nome);
        // A identidade dela não muda.
        expect(outra.olho, azul.olho, reason: nome);
        expect(outra.bochecha, azul.bochecha, reason: nome);
        expect(outra.detalhe, azul.detalhe, reason: nome);
        expect(outra.escudo, azul.escudo, reason: nome);
      }
    });

    test('o alto contraste ignora a paleta', () {
      final CoresDaMemora padrao =
          CoresDaMemora.para(MemoraTemaId.altoContraste);
      for (final String nome in MemoraCores.paletas.keys) {
        final CoresDaMemora m =
            CoresDaMemora.para(MemoraTemaId.altoContraste, paleta: nome);
        expect(m.corpo, padrao.corpo, reason: nome);
        expect(m.contorno, padrao.contorno, reason: nome);
        expect(m.visor, padrao.visor, reason: nome);
      }
    });

    testWidgets('trocar a paleta muda o corpo que ela pinta; no alto contraste não',
        (WidgetTester t) async {
      Future<CoresDaMemora> pintada(MemoraTemaId tema, String paleta) async {
        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.porId(tema, paleta: paleta),
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: const Scaffold(
                body: MemoraAnimada(
                  expressao: PoseDaMemora.neutra,
                  tamanho: 96,
                ),
              ),
            ),
          ),
        );
        // O MaterialApp anima a troca de tema; espera ela terminar.
        await t.pump(const Duration(seconds: 1));
        final CustomPaint pintura = t.widget<CustomPaint>(
          find.descendant(
            of: find.byType(MemoraAnimada),
            matching: find.byType(CustomPaint),
          ),
        );
        return (pintura.painter! as PintorDaMemora).criarContexto(96).cores;
      }

      final Color azul = (await pintada(MemoraTemaId.claro, 'azul')).corpo;
      final Color verde = (await pintada(MemoraTemaId.claro, 'verde')).corpo;
      final Color rosa = (await pintada(MemoraTemaId.escuro, 'rosa')).corpo;
      expect(verde, isNot(azul), reason: 'a paleta chega ao desenho');
      expect(rosa, CoresDaMemora.para(MemoraTemaId.escuro, paleta: 'rosa').corpo);

      final Color acAzul =
          (await pintada(MemoraTemaId.altoContraste, 'azul')).corpo;
      final Color acVerde =
          (await pintada(MemoraTemaId.altoContraste, 'verde')).corpo;
      expect(acVerde, acAzul, reason: 'no alto contraste a paleta nao vale');
    });
  });
}

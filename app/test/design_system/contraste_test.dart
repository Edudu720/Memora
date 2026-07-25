import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

/// Luminância relativa segundo a WCAG 2.2.
double _luminancia(Color cor) {
  double canal(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * canal(cor.r) +
      0.7152 * canal(cor.g) +
      0.0722 * canal(cor.b);
}

/// Razão de contraste entre duas cores, de 1:1 a 21:1.
double contraste(Color a, Color b) {
  final double la = _luminancia(a);
  final double lb = _luminancia(b);
  final double claro = math.max(la, lb);
  final double escuro = math.min(la, lb);
  return (claro + 0.05) / (escuro + 0.05);
}

/// Um par a verificar. [minimoGrafico] marca pares de borda e ícone, que
/// exigem 3:1 em vez do mínimo de texto do tema.
class _Par {
  final String nome;
  final Color Function(MemoraCores) frente;
  final Color Function(MemoraCores) fundo;
  final bool grafico;

  const _Par(this.nome, this.frente, this.fundo, {this.grafico = false});
}

/// Os mesmos 16 pares por tema verificados em
/// `specs/002-design-system/ferramentas/validar_paleta.py`.
const List<_Par> _pares = <_Par>[
  _Par('texto sobre fundo', _texto, _fundo),
  _Par('texto sobre superficie', _texto, _superficie),
  _Par('texto sobre superficieAlt', _texto, _superficieAlt),
  _Par('textoSuave sobre fundo', _textoSuave, _fundo),
  _Par('textoSuave sobre superficie', _textoSuave, _superficie),
  _Par('primaria sobre fundo', _primaria, _fundo),
  _Par('primaria sobre superficie', _primaria, _superficie),
  _Par('sobrePrimaria sobre primaria', _sobrePrimaria, _primaria),
  _Par('sucesso sobre fundo', _sucesso, _fundo),
  _Par('sucesso sobre superficie', _sucesso, _superficie),
  _Par('perigo sobre fundo', _perigo, _fundo),
  _Par('perigo sobre superficie', _perigo, _superficie),
  _Par('sobrePerigo sobre perigo', _sobrePerigo, _perigo),
  _Par('borda sobre fundo', _borda, _fundo, grafico: true),
  _Par('borda sobre superficie', _borda, _superficie, grafico: true),
  _Par('primaria sobre superficieAlt', _primaria, _superficieAlt, grafico: true),
];

Color _fundo(MemoraCores c) => c.fundo;
Color _superficie(MemoraCores c) => c.superficie;
Color _superficieAlt(MemoraCores c) => c.superficieAlt;
Color _primaria(MemoraCores c) => c.primaria;
Color _sobrePrimaria(MemoraCores c) => c.sobrePrimaria;
Color _texto(MemoraCores c) => c.texto;
Color _textoSuave(MemoraCores c) => c.textoSuave;
Color _borda(MemoraCores c) => c.borda;
Color _sucesso(MemoraCores c) => c.sucesso;
Color _perigo(MemoraCores c) => c.perigo;
Color _sobrePerigo(MemoraCores c) => c.sobrePerigo;

void main() {
  group('Contraste WCAG 2.2 — SC-001 e SC-007', () {
    for (final MemoraTheme tema in MemoraTheme.todos) {
      group('tema ${tema.id.name}', () {
        for (final _Par par in _pares) {
          final double exigido =
              par.grafico ? 3.0 : tema.contrasteMinimoTexto;

          test('${par.nome} >= $exigido:1', () {
            final double razao =
                contraste(par.frente(tema.cores), par.fundo(tema.cores));

            expect(
              razao,
              greaterThanOrEqualTo(exigido),
              reason: 'Tema ${tema.id.name}: "${par.nome}" mede '
                  '${razao.toStringAsFixed(2)}:1, abaixo do mínimo de '
                  '$exigido:1. Rode '
                  'specs/002-design-system/ferramentas/validar_paleta.py '
                  'e ajuste o token antes de prosseguir.',
            );
          });
        }
      });
    }

    test('o validador cobre exatamente 48 pares', () {
      expect(_pares.length * MemoraTheme.todos.length, 48);
    });
  });

  group('Tipografia — piso de legibilidade', () {
    test('nenhum estilo fica abaixo de 16 sp', () {
      for (final estilo in MemoraTipografia.todos) {
        expect(
          estilo.fontSize,
          greaterThanOrEqualTo(MemoraTipografia.tamanhoMinimo),
          reason: 'Texto de ${estilo.fontSize} sp viola o piso de '
              '${MemoraTipografia.tamanhoMinimo} sp exigido pelo público-alvo.',
        );
      }
    });
  });

  group('Dimensões de acessibilidade', () {
    test('alvo mínimo é 48 dp', () {
      expect(MemoraDimensoes.alvoMinimo, 48);
    });

    test('alvo de decisão supera o mínimo', () {
      expect(
        MemoraDimensoes.alvoDecisao,
        greaterThan(MemoraDimensoes.alvoMinimo),
        reason: 'Pontos de decisão exigem alvo maior que o mínimo — os botões '
            'SIM/NÃO do protótipo mediam 24 px, metade do exigido.',
      );
    });
  });
}

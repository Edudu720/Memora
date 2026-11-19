import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/componentes/ilustracao/memora_animada/pintores/contexto_de_pintura.dart';
import 'package:memora/design_system/componentes/ilustracao/memora_animada/pintores/pintor_da_memora.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/design_system/tokens/abertura.dart';
import 'package:memora/features/abertura/presentation/abertura_memora.dart';

import '../../suporte/movimento.dart';

/// A abertura **nativa** do Android, desenhada pelo mesmo pintor da abertura
/// do aplicativo (feature 013, T094; FR-037).
///
/// ## O problema
///
/// Antes de o Flutter existir, o Android mostra um desenho parado
/// (`res/drawable*/memora_abertura*.xml`). Logo depois, a `AberturaMemora`
/// pinta a anfitriã segurando a barra. Se os dois desenhos não forem o mesmo
/// (pose, tamanho, lugar), a Memora "pula" na troca: foi o que a T092 achou,
/// com os braços acenando no Android e segurando a barra no aplicativo.
///
/// ## Como os desenhos do Android são feitos
///
/// Não à mão: o **gerador** abaixo monta a `AberturaMemora`, pega o
/// **primeiro quadro** que ela pinta (o que substitui o desenho do Android) e
/// passa o `PintorDaMemora` por um `Canvas` que, em vez de pintar, anota cada
/// forma. Cada forma vira um `<path>` do `VectorDrawable`, em polígono fino
/// (a curva amostrada a cada 0,25 dp e simplificada a 0,04 dp). Fica pulado, a
/// menos que `MEMORA_GERAR_ABERTURA` esteja ligado:
///
/// ```powershell
/// $env:MEMORA_GERAR_ABERTURA = "1"; cd app; flutter test test/features/abertura/abertura_nativa_test.dart
/// ```
///
/// Mudou a Memora (poses, geometria, camadas, cores)? Gere de novo.
///
/// O que o `VectorDrawable` não tem, e foi simplificado: o desfoque da sombra
/// no chão vira anéis de opacidade crescente (um degradê em degraus); a
/// perspectiva e o balanço não entram (no primeiro quadro valem zero).
///
/// ## O portão
///
/// Roda sempre e lê os desenhos que estão no repositório: a pose é a mesma
/// da abertura do aplicativo, o desenho do Android 12 cabe inteiro no círculo
/// que o sistema recorta, e o do Android 11 é o mesmo desenho, no mesmo
/// lugar.
void main() {
  movimentoLiberado();

  const String pastaRes = 'android/app/src/main/res';

  group('o gerador dos desenhos do Android', () {
    final String? ligado = Platform.environment['MEMORA_GERAR_ABERTURA'];

    testWidgets('gera memora_abertura*.xml do primeiro quadro da abertura', (
      WidgetTester t,
    ) async {
      for (final (MemoraTemaId tema, String pasta) in <(MemoraTemaId, String)>[
        (MemoraTemaId.claro, 'drawable'),
        (MemoraTemaId.escuro, 'drawable-night'),
      ]) {
        final _PrimeiroQuadro primeiro = await _primeiroQuadro(t, tema);
        for (final _Moldura moldura in _Moldura.todas) {
          final String xml = _gerar(primeiro, moldura, tema);
          final File f = File('$pastaRes/$pasta/${moldura.arquivo}');
          await t.runAsync(() async {
            await f.parent.create(recursive: true);
            await f.writeAsString(xml);
          });
        }
      }
    }, skip: ligado == null || ligado.isEmpty);
  });

  group('T094: o desenho do Android é o primeiro quadro da abertura', () {
    for (final String pasta in <String>['drawable', 'drawable-night']) {
      final File icone = File('$pastaRes/$pasta/memora_abertura_icone.xml');
      final File janela = File('$pastaRes/$pasta/memora_abertura.xml');

      testWidgets('$pasta: a mesma pose da abertura do aplicativo', (
        WidgetTester t,
      ) async {
        final PoseDaMemora pose = (await _primeiroQuadro(
          t,
          MemoraTemaId.claro,
        )).pose;
        for (final File f in <File>[icone, janela]) {
          expect(
            f.readAsStringSync(),
            contains('pose `${pose.name}`'),
            reason: '${f.path} foi gerado de outra pose: gere de novo',
          );
        }
      });

      test('$pasta: no Android 12, cabe inteiro no círculo de 192 dp do '
          'quadro de 288 dp', () {
        final _Vetor v = _Vetor.ler(icone.readAsStringSync());
        expect(v.lado, _Moldura.icone.lado);
        const Offset centro = Offset(144, 144);
        double pior = 0;
        // O anel mais de fora de um desfoque (o halo da antena, a sombra) tem
        // opacidade de 1%: que o recorte o apara, ninguém vê.
        for (final _Forma f in v.formas.where((_Forma f) => f.alfa >= 0.03)) {
          for (final Offset p in f.pontos) {
            pior = math.max(pior, (p - centro).distance + f.meiaEspessura);
          }
        }
        expect(
          pior,
          lessThanOrEqualTo(96),
          reason: 'o sistema recorta o que passa do círculo',
        );
      });

      test('$pasta: no Android 11, o mesmo desenho, centrado, com a Memora '
          'de ${MemoraAbertura.tamanhoDaMemora.toInt()} dp', () {
        final _Vetor a = _Vetor.ler(icone.readAsStringSync());
        final _Vetor b = _Vetor.ler(janela.readAsStringSync());
        expect(b.lado, _Moldura.janela.lado);
        expect(b.formas.length, a.formas.length);
        // O mesmo desenho, deslocado: o centro do quadro é o centro da
        // Memora nos dois (o do Android 11 é centrado na janela, como a
        // AberturaMemora). Compara a caixa de cada forma: a simplificação
        // pode escolher outro ponto da mesma curva.
        final Offset desvio = Offset(a.lado - b.lado, a.lado - b.lado) / 2;
        for (int i = 0; i < a.formas.length; i++) {
          final Rect ca = a.formas[i].caixa.shift(-desvio);
          final Rect cb = b.formas[i].caixa;
          final List<double> la = <double>[
            ca.left,
            ca.top,
            ca.right,
            ca.bottom,
          ];
          final List<double> lb = <double>[
            cb.left,
            cb.top,
            cb.right,
            cb.bottom,
          ];
          for (int k = 0; k < 4; k++) {
            expect(la[k], closeTo(lb[k], 0.1), reason: 'forma $i: $ca e $cb');
          }
        }
        // E nada que se veja fica fora do quadro (o mesmo 1% de cima).
        for (final _Forma f in b.formas.where((_Forma f) => f.alfa >= 0.03)) {
          for (final Offset p in f.pontos) {
            expect(p.dx, inInclusiveRange(0, b.lado));
            expect(p.dy, inInclusiveRange(0, b.lado));
          }
        }
      });
    }
  });
}

/// As duas molduras do mesmo desenho.
class _Moldura {
  final String arquivo;
  final double lado;
  final String para;

  const _Moldura(this.arquivo, this.lado, this.para);

  /// Onde a Memora começa, dentro do quadro: ela fica no centro.
  double get margem => (lado - MemoraAbertura.tamanhoDaMemora) / 2;

  /// O ícone da abertura do Android 12 ou mais novo: o sistema pede um quadro
  /// de 288 dp e mostra só o círculo de 192 dp do meio.
  static const _Moldura icone = _Moldura(
    'memora_abertura_icone.xml',
    288,
    'o icone da abertura do Android 12 ou mais novo '
        '(windowSplashScreenAnimatedIcon, values-v31): o sistema pede um quadro '
        'de 288 dp e mostra so o circulo de 192 dp do meio, onde a Memora cabe '
        'inteira',
  );

  /// O desenho centrado na janela do Android 11 ou mais antigo. A margem de
  /// 16 dp é para o halo da antena e a sombra desfocada no chão, que passam
  /// do quadro de 160 dp (no aplicativo nada os recorta); o centro continua
  /// sendo o da Memora.
  static const _Moldura janela = _Moldura(
    'memora_abertura.xml',
    192,
    'o desenho centrado na janela do Android 11 ou mais antigo '
        '(drawable-v21/launch_background.xml); a margem de 16 dp em volta e '
        'para o halo da antena e a sombra desfocada no chao',
  );

  static const List<_Moldura> todas = <_Moldura>[icone, janela];
}

/// O que a abertura pinta no primeiro quadro.
class _PrimeiroQuadro {
  final PoseDaMemora pose;
  final ContextoDePintura contexto;

  const _PrimeiroQuadro(this.pose, this.contexto);
}

/// Monta a abertura (com movimento, como a maioria das pessoas a vê) e devolve
/// o primeiro quadro que ela pinta: o que entra no lugar do desenho do
/// Android.
Future<_PrimeiroQuadro> _primeiroQuadro(
  WidgetTester t,
  MemoraTemaId tema,
) async {
  final Completer<int> carga = Completer<int>();
  await t.pumpWidget(
    MaterialApp(
      theme: TemasMemora.porId(tema),
      home: AberturaMemora<int>(
        carregar: () => carga.future,
        aoConcluir: (int _) {},
      ),
    ),
  );
  final Finder memora = find.byType(MemoraAnimada);
  final MemoraAnimada m = t.widget<MemoraAnimada>(memora);
  final CustomPaint pintura = t.widget<CustomPaint>(
    find.descendant(of: memora, matching: find.byType(CustomPaint)),
  );
  final ContextoDePintura q = (pintura.painter! as PintorDaMemora)
      .criarContexto(MemoraAbertura.tamanhoDaMemora);
  // Sai da árvore sem deixar relógio pendente.
  await t.pumpWidget(const SizedBox.shrink());
  return _PrimeiroQuadro(m.expressao, q);
}

// ---------------------------------------------------------------------------
// O gerador
// ---------------------------------------------------------------------------

String _gerar(_PrimeiroQuadro primeiro, _Moldura moldura, MemoraTemaId tema) {
  final ContextoDePintura q = primeiro.contexto;
  expect(q.balanco, 0, reason: 'a perspectiva do balanço não vai para o XML');
  final _Gravador g = _Gravador(
    _Afim.translacao(moldura.margem, moldura.margem),
  );
  final _ContextoGravado ctx = _ContextoGravado(q);
  PintorDaMemora(
    (double _) => ctx,
  ).paint(g, const Size.square(MemoraAbertura.tamanhoDaMemora));

  final String lado = _n(moldura.lado);
  final StringBuffer sb = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="utf-8"?>')
    ..writeln('<!--')
    ..writeln(
      '    GERADO, nao edite a mao. A abertura nativa do Android '
      '(feature 013, T094;',
    )
    ..writeln('    FR-037): ${moldura.para}.')
    ..writeln()
    ..writeln(
      '    E o primeiro quadro da AberturaMemora, pintado pelo mesmo '
      'PintorDaMemora: a',
    )
    ..writeln(
      '    anfitria na pose `${primeiro.pose.name}`, parada, segurando '
      'a barra com o trecho',
    )
    ..writeln(
      '    no meio (de onde a primeira passada do aplicativo parte), '
      'com a Memora de',
    )
    ..writeln(
      '    ${_n(MemoraAbertura.tamanhoDaMemora)} dp no centro do '
      'quadro de $lado dp. Tema ${tema.name}, paleta azul (as',
    )
    ..writeln('    preferencias ainda nao existem nessa hora).')
    ..writeln()
    ..writeln(
      '    Mudou a Memora? Gere de novo, os quatro de uma vez '
      '(drawable e drawable-night):',
    )
    ..writeln(
      '    MEMORA_GERAR_ABERTURA=1 flutter test '
      'test/features/abertura/abertura_nativa_test.dart',
    )
    ..writeln('-->')
    ..writeln(
      '<vector xmlns:android="http://schemas.android.com/apk/res/android"',
    )
    ..writeln('    xmlns:aapt="http://schemas.android.com/aapt"')
    ..writeln('    android:width="${lado}dp"')
    ..writeln('    android:height="${lado}dp"')
    ..writeln('    android:viewportWidth="$lado"')
    ..writeln('    android:viewportHeight="$lado">');

  // Formas seguidas com o mesmo recorte ficam no mesmo grupo.
  List<String> aberto = const <String>[];
  void fecharAte(int n) {
    while (aberto.length > n) {
      aberto = aberto.sublist(0, aberto.length - 1);
      sb.writeln('${'    ' * (aberto.length + 1)}</group>');
    }
  }

  for (final _Desenho d in g.desenhos) {
    int comum = 0;
    while (comum < aberto.length &&
        comum < d.recortes.length &&
        aberto[comum] == d.recortes[comum]) {
      comum++;
    }
    fecharAte(comum);
    while (aberto.length < d.recortes.length) {
      final String r = d.recortes[aberto.length];
      final String recuo = '    ' * (aberto.length + 1);
      sb
        ..writeln('$recuo<group>')
        ..writeln('$recuo    <clip-path android:pathData="$r"/>');
      aberto = <String>[...aberto, r];
    }
    d.escrever(sb, '    ' * (aberto.length + 1));
  }
  fecharAte(0);
  sb.writeln('</vector>');
  return sb.toString();
}

/// Um número curto: duas casas, sem zeros sobrando.
String _n(double v) {
  String s = v.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s == '-0' ? '0' : s;
}

String _cor(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

/// Uma transformação do plano: x' = a·x + c·y + e, y' = b·x + d·y + f.
class _Afim {
  final double a, b, c, d, e, f;

  const _Afim(this.a, this.b, this.c, this.d, this.e, this.f);

  const _Afim.translacao(double dx, double dy) : this(1, 0, 0, 1, dx, dy);

  /// Esta depois de [o] (o é aplicada primeiro).
  _Afim vezes(_Afim o) => _Afim(
    a * o.a + c * o.b,
    b * o.a + d * o.b,
    a * o.c + c * o.d,
    b * o.c + d * o.d,
    a * o.e + c * o.f + e,
    b * o.e + d * o.f + f,
  );

  Offset aplicar(Offset p) =>
      Offset(a * p.dx + c * p.dy + e, b * p.dx + d * p.dy + f);

  /// O quanto um comprimento cresce (a Memora só escala por igual).
  double get escala => math.sqrt((a * d - b * c).abs());
}

/// Um degradê linear, anotado ao lado da tinta (o `Shader` não se deixa ler).
class _Degrade {
  final Offset de;
  final Offset ate;
  final List<Color> cores;
  final List<double> paradas;

  const _Degrade(this.de, this.ate, this.cores, this.paradas);
}

final Expando<_Degrade> _degrades = Expando<_Degrade>('degradê');

/// O contexto do primeiro quadro, com os degradês anotados.
class _ContextoGravado extends ContextoDePintura {
  _ContextoGravado(ContextoDePintura q)
    : super(
        lado: q.lado,
        cores: q.cores,
        pose: q.pose,
        respira: q.respira,
        fala: q.fala,
        piscar: q.piscar,
        aceno: q.aceno,
        pulo: q.pulo,
        balanco: q.balanco,
        entrada: q.entrada,
        antena: q.antena,
        ajeita: q.ajeita,
        giro: q.giro,
        flutua: q.flutua,
        esticar: q.esticar,
        detalhada: q.detalhada,
        cicloDaBarra: q.cicloDaBarra,
      );

  @override
  Paint degrade(
    Rect caixa,
    Color a,
    Color b, {
    Alignment de = Alignment.topLeft,
    Alignment ate = Alignment.bottomRight,
  }) {
    final Paint p = super.degrade(caixa, a, b, de: de, ate: ate)..color = a;
    _degrades[p] = _Degrade(
      de.withinRect(caixa),
      ate.withinRect(caixa),
      <Color>[a, b],
      const <double>[0, 1],
    );
    return p;
  }

  /// O mesmo de [ContextoDePintura.luzNaBorda], com o degradê anotado.
  @override
  void luzNaBorda(
    Canvas canvas,
    Path forma,
    Rect caixa, {
    double espessura = 0.03,
    double forca = 1,
  }) {
    canvas.save();
    canvas.clipPath(forma);
    final Color luz = cores.luzDeContorno;
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = l(espessura)
      ..color = luz;
    _degrades[p] = _Degrade(
      Alignment.topLeft.withinRect(caixa),
      Alignment.bottomRight.withinRect(caixa),
      <Color>[
        luz.withValues(alpha: 0),
        luz.withValues(alpha: 0),
        luz.withValues(alpha: 0.85 * forca),
      ],
      const <double>[0, 0.5, 1],
    );
    canvas.drawPath(forma, p);
    canvas.restore();
  }
}

/// Uma forma anotada, pronta para virar `<path>`.
class _Desenho {
  final List<String> recortes;
  final String dados;
  final bool traco;
  final Color cor;
  final _Degrade? degrade;
  final double espessura;
  final StrokeCap ponta;
  final StrokeJoin juncao;

  const _Desenho({
    required this.recortes,
    required this.dados,
    required this.traco,
    required this.cor,
    this.degrade,
    this.espessura = 0,
    this.ponta = StrokeCap.butt,
    this.juncao = StrokeJoin.miter,
  });

  void escrever(StringBuffer sb, String recuo) {
    final String atributo = traco ? 'strokeColor' : 'fillColor';
    final StringBuffer a = StringBuffer();
    if (degrade == null) a.write(' android:$atributo="${_cor(cor)}"');
    if (traco) {
      a.write(' android:strokeWidth="${_n(espessura)}"');
      if (ponta != StrokeCap.butt) {
        a.write(' android:strokeLineCap="${ponta.name}"');
      }
      if (juncao != StrokeJoin.miter) {
        a.write(' android:strokeLineJoin="${juncao.name}"');
      }
    }
    a.write(' android:pathData="$dados"');
    final _Degrade? g = degrade;
    if (g == null) {
      sb.writeln('$recuo<path$a/>');
      return;
    }
    sb
      ..writeln('$recuo<path$a>')
      ..writeln('$recuo    <aapt:attr name="android:$atributo">')
      ..writeln(
        '$recuo        <gradient android:type="linear" '
        'android:startX="${_n(g.de.dx)}" android:startY="${_n(g.de.dy)}" '
        'android:endX="${_n(g.ate.dx)}" android:endY="${_n(g.ate.dy)}">',
      );
    for (int i = 0; i < g.cores.length; i++) {
      sb.writeln(
        '$recuo            <item android:offset="${_n(g.paradas[i])}" '
        'android:color="${_cor(g.cores[i])}"/>',
      );
    }
    sb
      ..writeln('$recuo        </gradient>')
      ..writeln('$recuo    </aapt:attr>')
      ..writeln('$recuo</path>');
  }
}

/// Um `Canvas` que não pinta: anota cada forma, já na moldura do XML.
class _Gravador implements Canvas {
  _Gravador(_Afim inicial) : _estado = _Estado(inicial, const <String>[]);

  final List<_Desenho> desenhos = <_Desenho>[];
  final List<_Estado> _pilha = <_Estado>[];
  _Estado _estado;

  @override
  void save() => _pilha.add(_estado);

  @override
  void saveLayer(Rect? bounds, Paint paint) {
    // Só a versão "só a cabeça" usa camada (para esmaecer o corpo), e ela não
    // é a da abertura.
    throw UnsupportedError('saveLayer não tem par no VectorDrawable');
  }

  @override
  void restore() => _estado = _pilha.removeLast();

  @override
  int getSaveCount() => _pilha.length + 1;

  @override
  void restoreToCount(int count) {
    while (getSaveCount() > count) {
      restore();
    }
  }

  void _compor(_Afim m) =>
      _estado = _Estado(_estado.matriz.vezes(m), _estado.recortes);

  @override
  void translate(double dx, double dy) => _compor(_Afim.translacao(dx, dy));

  @override
  void scale(double sx, [double? sy]) =>
      _compor(_Afim(sx, 0, 0, sy ?? sx, 0, 0));

  @override
  void rotate(double radians) {
    final double c = math.cos(radians);
    final double s = math.sin(radians);
    _compor(_Afim(c, s, -s, c, 0, 0));
  }

  @override
  void transform(Float64List m) =>
      _compor(_Afim(m[0], m[1], m[4], m[5], m[12], m[13]));

  void _recortar(Path forma) => _estado = _Estado(_estado.matriz, <String>[
    ..._estado.recortes,
    _dados(forma, _estado.matriz),
  ]);

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) => _recortar(path);

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) =>
      _recortar(Path()..addRRect(rrect));

  @override
  void clipRect(
    Rect rect, {
    ui.ClipOp clipOp = ui.ClipOp.intersect,
    bool doAntiAlias = true,
  }) {
    if (clipOp != ui.ClipOp.intersect) {
      throw UnsupportedError('recorte por diferença');
    }
    _recortar(Path()..addRect(rect));
  }

  @override
  void drawPath(Path path, Paint paint) => _anotar(path, paint);

  @override
  void drawRRect(RRect rrect, Paint paint) =>
      _anotar(Path()..addRRect(rrect), paint);

  @override
  void drawRect(Rect rect, Paint paint) =>
      _anotar(Path()..addRect(rect), paint);

  @override
  void drawCircle(Offset c, double radius, Paint paint) =>
      drawOval(Rect.fromCircle(center: c, radius: radius), paint);

  @override
  void drawOval(Rect rect, Paint paint) {
    final double? sigma = _sigmaDoDesfoque(paint);
    if (sigma == null) {
      _anotar(Path()..addOval(rect), paint);
      return;
    }
    // O desfoque vira anéis: do maior (fraco) ao menor (forte), cada um com
    // a opacidade que, somada à dos de fora, dá a de uma borda gaussiana.
    const List<double> bordas = <double>[2.2, 1.4, 0.6, -0.2, -1.0];
    const List<double> meios = <double>[1.8, 1.0, 0.2, -0.6, -1.6];
    final double alfa = paint.color.a;
    double acumulado = 0;
    for (int i = 0; i < bordas.length; i++) {
      final Rect r = rect.inflate(bordas[i] * sigma);
      if (r.width <= 0 || r.height <= 0) break;
      final double alvo = alfa * _normal(-meios[i]);
      final double esta = 1 - (1 - alvo) / (1 - acumulado);
      acumulado = alvo;
      _anotar(
        Path()..addOval(r),
        Paint()..color = paint.color.withValues(alpha: esta),
      );
    }
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) => _anotar(
    Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy),
    paint,
    traco: true,
  );

  void _anotar(Path forma, Paint paint, {bool traco = false}) {
    if (_sigmaDoDesfoque(paint) != null) {
      throw UnsupportedError('desfoque fora de oval');
    }
    final bool eTraco = traco || paint.style == PaintingStyle.stroke;
    final String dados = _dados(forma, _estado.matriz);
    if (dados.isEmpty) return;
    final _Degrade? g = _degrades[paint];
    if (g == null && paint.shader != null) {
      // Um degradê feito fora do `ContextoDePintura.degrade`: o gravador não
      // tem como lê-lo, e a forma sairia preta.
      throw UnsupportedError('degradê sem passar por ctx.degrade');
    }
    final _Afim m = _estado.matriz;
    desenhos.add(
      _Desenho(
        recortes: _estado.recortes,
        dados: dados,
        traco: eTraco,
        cor: paint.color,
        degrade: g == null
            ? null
            : _Degrade(m.aplicar(g.de), m.aplicar(g.ate), g.cores, g.paradas),
        espessura: paint.strokeWidth * m.escala,
        ponta: paint.strokeCap,
        juncao: paint.strokeJoin,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('o gravador não conhece ${invocation.memberName}');
}

class _Estado {
  final _Afim matriz;
  final List<String> recortes;

  const _Estado(this.matriz, this.recortes);
}

/// O sigma do desfoque da tinta, se houver (o `MaskFilter` só se deixa ler
/// pelo texto).
double? _sigmaDoDesfoque(Paint paint) {
  final MaskFilter? filtro = paint.maskFilter;
  if (filtro == null) return null;
  final Match? m = RegExp(
    r'MaskFilter\.blur\(BlurStyle\.normal, ([0-9.]+)\)',
  ).firstMatch(filtro.toString());
  if (m == null) throw UnsupportedError('desfoque $filtro');
  return double.parse(m.group(1)!);
}

/// A distribuição normal acumulada (aproximação de Abramowitz e Stegun).
double _normal(double x) {
  final double t = 1 / (1 + 0.2316419 * x.abs());
  final double d = 0.3989422804 * math.exp(-x * x / 2);
  final double p =
      d *
      t *
      (0.3193815 +
          t * (-0.3565638 + t * (1.781478 + t * (-1.821256 + t * 1.330274))));
  return x >= 0 ? 1 - p : p;
}

/// O `pathData` de [forma]: cada contorno amostrado a cada 0,25 dp e
/// simplificado (Douglas-Peucker, 0,04 dp), já na moldura do XML.
String _dados(Path forma, _Afim m) {
  final StringBuffer sb = StringBuffer();
  for (final ui.PathMetric contorno in forma.computeMetrics()) {
    if (contorno.length <= 0) continue;
    final int n = math.max(2, (contorno.length * m.escala / 0.25).ceil());
    final List<Offset> pontos = <Offset>[
      for (int i = 0; i <= n; i++)
        m.aplicar(
          contorno.getTangentForOffset(contorno.length * i / n)!.position,
        ),
    ];
    final List<Offset> simples = _simplificar(pontos, 0.04);
    if (contorno.isClosed &&
        simples.length > 2 &&
        (simples.first - simples.last).distance < 0.01) {
      simples.removeLast();
    }
    for (int i = 0; i < simples.length; i++) {
      sb.write(
        '${i == 0 ? 'M' : 'L'}${_n(simples[i].dx)},${_n(simples[i].dy)}',
      );
    }
    if (contorno.isClosed) sb.write('Z');
  }
  return sb.toString();
}

List<Offset> _simplificar(List<Offset> p, double tolerancia) {
  if (p.length < 3) return List<Offset>.of(p);
  final List<bool> fica = List<bool>.filled(p.length, false)
    ..[0] = true
    ..[p.length - 1] = true;
  final List<(int, int)> pendentes = <(int, int)>[(0, p.length - 1)];
  while (pendentes.isNotEmpty) {
    final (int i, int j) = pendentes.removeLast();
    double pior = 0;
    int onde = -1;
    for (int k = i + 1; k < j; k++) {
      final double d = _distanciaAoSegmento(p[k], p[i], p[j]);
      if (d > pior) {
        pior = d;
        onde = k;
      }
    }
    if (pior > tolerancia) {
      fica[onde] = true;
      pendentes
        ..add((i, onde))
        ..add((onde, j));
    }
  }
  return <Offset>[
    for (int k = 0; k < p.length; k++)
      if (fica[k]) p[k],
  ];
}

double _distanciaAoSegmento(Offset p, Offset a, Offset b) {
  final Offset ab = b - a;
  final double l2 = ab.dx * ab.dx + ab.dy * ab.dy;
  if (l2 == 0) return (p - a).distance;
  final double t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / l2).clamp(
    0.0,
    1.0,
  );
  return (p - (a + ab * t)).distance;
}

// ---------------------------------------------------------------------------
// A leitura dos desenhos, para o portão
// ---------------------------------------------------------------------------

/// Uma forma lida do XML: os pontos e metade da espessura do traço.
class _Forma {
  final List<Offset> pontos;
  final double meiaEspessura;

  /// A opacidade da cor lisa (1 num degradê).
  final double alfa;

  const _Forma(this.pontos, this.meiaEspessura, this.alfa);

  Rect get caixa => Rect.fromPoints(
    Offset(
      pontos.map((Offset p) => p.dx).reduce(math.min),
      pontos.map((Offset p) => p.dy).reduce(math.min),
    ),
    Offset(
      pontos.map((Offset p) => p.dx).reduce(math.max),
      pontos.map((Offset p) => p.dy).reduce(math.max),
    ),
  );
}

class _Vetor {
  final double lado;
  final List<_Forma> formas;

  const _Vetor(this.lado, this.formas);

  /// Lê o que o gerador escreve: `pathData` só com M, L e Z, em coordenadas
  /// do quadro (sem grupo que desloque nada).
  static _Vetor ler(String xml) {
    final double lado = double.parse(
      RegExp(r'android:viewportWidth="([0-9.]+)"').firstMatch(xml)!.group(1)!,
    );
    expect(
      xml,
      isNot(contains(RegExp(r'android:(translate|scale|rotation|pivot)'))),
      reason: 'o portão lê coordenadas do quadro',
    );
    final List<_Forma> formas = <_Forma>[];
    for (final Match m in RegExp(r'<path ([^>]*?)/?>').allMatches(xml)) {
      final String atributos = m.group(1)!;
      final String dados = RegExp(
        r'android:pathData="([^"]*)"',
      ).firstMatch(atributos)!.group(1)!;
      expect(dados, matches(RegExp(r'^[MLZ0-9.,\-]+$')));
      final Match? e = RegExp(
        r'android:strokeWidth="([0-9.]+)"',
      ).firstMatch(atributos);
      final List<Offset> pontos = <Offset>[
        for (final Match p in RegExp(
          r'(-?[0-9.]+),(-?[0-9.]+)',
        ).allMatches(dados))
          Offset(double.parse(p.group(1)!), double.parse(p.group(2)!)),
      ];
      final Match? cor = RegExp(
        r'android:(?:fill|stroke)Color="#([0-9A-F]{2})',
      ).firstMatch(atributos);
      formas.add(
        _Forma(
          pontos,
          e == null ? 0 : double.parse(e.group(1)!) / 2,
          cor == null ? 1 : int.parse(cor.group(1)!, radix: 16) / 255,
        ),
      );
    }
    return _Vetor(lado, formas);
  }
}

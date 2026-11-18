import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// Exportador oficial dos vetores 2.5D da `MemoraAnimada` e das dicas da
/// anfitriã (`TextosAnfitria.dicas`) para o site estático (`site/assets/memora/`).
///
/// Roda em Dart puro via `dart run tool/exportar_memora_site.dart` (sem
/// depender de `dart:ui`), lendo diretamente os fontes oficiais em `app/lib/`.
void main() {
  final Directory raiz = _localizarRaizDoRepositorio();
  final File arqDicas = File('${raiz.path}/app/lib/l10n/textos_anfitria.dart');
  final File arqCoresMemora = File(
    '${raiz.path}/app/lib/design_system/tokens/cores_da_memora.dart',
  );
  final File arqCoresDs = File(
    '${raiz.path}/app/lib/design_system/tokens/cores.dart',
  );
  final File arqGeometria = File(
    '${raiz.path}/app/lib/design_system/componentes/ilustracao/memora_animada/pintores/geometria.dart',
  );
  final File arqPoses = File(
    '${raiz.path}/app/lib/design_system/componentes/ilustracao/memora_animada/poses.dart',
  );

  for (final File f in <File>[
    arqDicas,
    arqCoresMemora,
    arqCoresDs,
    arqGeometria,
    arqPoses,
  ]) {
    if (!f.existsSync()) {
      stderr.writeln('ERRO: Arquivo oficial não encontrado: ${f.path}');
      exitCode = 1;
      return;
    }
  }

  final _DadosAnfitria anfitria = _lerAnfitria(
    arqDicas.readAsStringSync(),
  );
  final Map<String, Map<String, String>> paletas = _lerPaletasMemora(
    arqCoresMemora.readAsStringSync(),
    arqCoresDs.readAsStringSync(),
  );
  final _Geometria geometria = _lerGeometria(
    arqGeometria.readAsStringSync(),
  );
  final Map<String, _PoseSpec> poses = _lerPoses(
    arqPoses.readAsStringSync(),
  );

  final Directory dirSaida = Directory('${raiz.path}/site/assets/memora');
  dirSaida.createSync(recursive: true);

  final Map<String, String> partesBase = _renderizarPartesBase(geometria);
  final Map<String, Map<String, dynamic>> variacoes =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> metaPoses =
      <String, Map<String, dynamic>>{};

  for (final MapEntry<String, _PoseSpec> entrada in poses.entries) {
    final String nome = entrada.key;
    final _PoseSpec pose = entrada.value;
    final Map<String, dynamic> varPose = _renderizarVariacaoPose(
      nome,
      pose,
      geometria,
    );
    variacoes[nome] = varPose;
    final String svg = _montarSvgCompleto(nome, partesBase, varPose);
    File('${dirSaida.path}/$nome.svg').writeAsStringSync('$svg\n');

    metaPoses[nome] = <String, dynamic>{
      'inclinacaoCabecaGraus': _arredondar(pose.inclinacao * 180 / math.pi),
      'olhoAbertura': _arredondar(pose.olhoAbertura),
      'olhoFeliz': _arredondar(pose.olhoFeliz),
      'sorriso': _arredondar(pose.sorriso),
      'bocaAbertura': _arredondar(pose.bocaAbertura),
      'bocaVisivel': _arredondar(pose.bocaVisivel),
      'corpoVisivel': pose.corpo > 0.01,
      'escalaGlobal': pose.corpo > 0.01 ? 1.0 : 1.25,
      'partes': <String>[
        if (pose.corpo > 0.01) 'sombra',
        if (pose.corpo > 0.01) 'corpo',
        if (pose.corpo > 0.01) 'painel-peito',
        'antena',
        'cabeca',
        'visor',
        'rosto',
        'olhos',
        if (pose.bocaVisivel > 0.01) 'boca',
        if (pose.corpo > 0.01) 'braco-esquerdo',
        if (pose.corpo > 0.01) 'braco-direito',
        if (pose.escudo > 0.01) 'escudo',
        if (pose.livro > 0.01) 'livro',
        if (pose.barra > 0.01) 'barra',
      ],
    };
  }

  final Map<String, dynamic> payload = <String, dynamic>{
    'fonte': <String, String>{
      'pintor': 'PintorDaMemora',
      'poses': 'poses.dart',
      'cores': 'cores_da_memora.dart',
      'dicas': 'textos_anfitria.dart',
    },
    'grupos': const <String>[
      'sombra',
      'corpo',
      'painel-peito',
      'antena',
      'cabeca',
      'visor',
      'rosto',
      'olhos',
      'boca',
      'braco-esquerdo',
      'braco-direito',
      'escudo',
      'livro',
      'barra',
    ],
    'expressoes': poses.keys.toList(),
    'rotuloDaAcao': anfitria.rotuloDaAcao,
    'dicasDaAnfitria': anfitria.dicas,
    'paletas': paletas,
    'poses': metaPoses,
  };

  final File arqJson = File('${dirSaida.path}/memora.json');
  arqJson.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
  );

  final Map<String, dynamic> bundleJs = <String, dynamic>{
    ...payload,
    'base': partesBase,
    'variacoes': variacoes,
  };
  final String conteudoJs =
      '/**\n'
      ' * Gerado automaticamente por app/tool/exportar_memora_site.dart\n'
      ' * a partir de PintorDaMemora, poses.dart, cores_da_memora.dart e\n'
      ' * TextosAnfitria.dicas (T083/T086). Nao editar manualmente.\n'
      ' */\n'
      '(function (globalObj) {\n'
      "  'use strict';\n"
      '  var dados = ${jsonEncode(bundleJs)};\n'
      "  if (typeof module !== 'undefined' && module.exports) {\n"
      '    module.exports = dados;\n'
      '  }\n'
      '  if (globalObj) {\n'
      '    globalObj.MemoraDados = dados;\n'
      '  }\n'
      "})(typeof window !== 'undefined' ? window : globalThis);\n";

  final File arqBundleJs = File('${dirSaida.path}/memora-dados.js');
  arqBundleJs.writeAsStringSync(conteudoJs);

  stdout.writeln(
    'OK: Exportadas ${poses.length} expressoes (${poses.keys.join(', ')}), '
    '${anfitria.dicas.length} dicas da anfitria e ${paletas.length} paletas '
    '(${arqBundleJs.lengthSync()} bytes em memora-dados.js).',
  );
}

Directory _localizarRaizDoRepositorio() {
  Directory atual = Directory.current.absolute;
  for (int i = 0; i < 6; i++) {
    final bool temApp = Directory('${atual.path}/app/lib').existsSync();
    final bool temSite = Directory('${atual.path}/site').existsSync();
    if (temApp && temSite) {
      return atual;
    }
    if (atual.parent.path == atual.path) break;
    atual = atual.parent;
  }
  throw StateError(
    'Nao foi possivel localizar a raiz do repositorio Memora a partir de ${Directory.current.path}.',
  );
}

class _DadosAnfitria {
  final String rotuloDaAcao;
  final List<String> dicas;
  const _DadosAnfitria({required this.rotuloDaAcao, required this.dicas});
}

_DadosAnfitria _lerAnfitria(String fonte) {
  final Map<String, String> constantes = <String, String>{};
  final RegExp regConst = RegExp(
    r"static\s+const\s+String\s+(\w+)\s*=\s*((?:'(?:\\'|[^'])*'\s*)+);",
    dotAll: true,
  );
  for (final RegExpMatch m in regConst.allMatches(fonte)) {
    final String nome = m.group(1)!;
    final String bruto = m.group(2)!;
    final Iterable<RegExpMatch> partes = RegExp(
      r"'((?:\\'|[^'])*)'",
    ).allMatches(bruto);
    final String valor = partes
        .map((RegExpMatch p) => p.group(1)!.replaceAll(r"\'", "'"))
        .join();
    constantes[nome] = valor;
  }

  final String rotuloDaAcao = constantes['rotuloDaAcao'] ?? '';
  if (rotuloDaAcao.isEmpty) {
    throw FormatException('Nao foi possivel ler rotuloDaAcao em textos_anfitria.dart');
  }

  final RegExpMatch? matchLista = RegExp(
    r'static\s+const\s+List<String>\s+dicas\s*=\s*<String>\[([^\]]+)\]',
    dotAll: true,
  ).firstMatch(fonte);
  if (matchLista == null) {
    throw FormatException('Lista TextosAnfitria.dicas nao encontrada.');
  }

  final List<String> dicas = <String>[];
  for (final String item in matchLista.group(1)!.split(',')) {
    final String chave = item.trim();
    if (chave.isEmpty) continue;
    final String? texto = constantes[chave];
    if (texto == null || texto.isEmpty) {
      throw FormatException('Constante "$chave" referenciada em dicas nao encontrada.');
    }
    dicas.add(texto);
  }

  if (dicas.length < 12) {
    throw FormatException('Esperadas ao menos 12 dicas em TextosAnfitria.dicas, encontradas ${dicas.length}.');
  }
  return _DadosAnfitria(rotuloDaAcao: rotuloDaAcao, dicas: dicas);
}

String _extrairBlocoParenteses(String fonte, RegExp inicioPadrao, String rotulo) {
  final RegExpMatch? m = inicioPadrao.firstMatch(fonte);
  if (m == null) {
    throw FormatException('Bloco "$rotulo" nao encontrado.');
  }
  int prof = 1;
  int i = m.end;
  while (i < fonte.length && prof > 0) {
    final String ch = fonte[i];
    if (ch == '(') prof++;
    if (ch == ')') prof--;
    i++;
  }
  if (prof != 0) {
    throw FormatException('Parenteses desbalanceados em "$rotulo".');
  }
  return fonte.substring(m.end, i - 1);
}

int _extrairCorHexInt(String bloco, String campo) {
  final RegExpMatch? m = RegExp(
    r'\b' + RegExp.escape(campo) + r'\s*:\s*Color\((0x[0-9A-Fa-f]{8})\)',
  ).firstMatch(bloco);
  if (m == null) {
    throw FormatException('Cor "$campo" nao encontrada no bloco.');
  }
  return int.parse(m.group(1)!.substring(2), radix: 16);
}

int _extrairConstCorPrivada(String fonte, String nome) {
  final RegExpMatch? m = RegExp(
    r'static\s+const\s+Color\s+' +
        RegExp.escape(nome) +
        r'\s*=\s*Color\((0x[0-9A-Fa-f]{8})\)',
  ).firstMatch(fonte);
  if (m == null) {
    throw FormatException('Constante privada "$nome" nao encontrada.');
  }
  return int.parse(m.group(1)!.substring(2), radix: 16);
}

String _hexCss(int argb) {
  final int a = (argb >> 24) & 0xFF;
  final int r = (argb >> 16) & 0xFF;
  final int g = (argb >> 8) & 0xFF;
  final int b = argb & 0xFF;
  if (a == 0xFF) {
    return '#${r.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${g.toRadixString(16).padLeft(2, '0').toUpperCase()}'
        '${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';
  }
  if (a == 0) return 'transparent';
  final String alphaStr = (a / 255.0).toStringAsFixed(2);
  return 'rgba($r, $g, $b, $alphaStr)';
}

int _lerpArgb(int c1, int c2, double t) {
  final int a1 = (c1 >> 24) & 0xFF;
  final int r1 = (c1 >> 16) & 0xFF;
  final int g1 = (c1 >> 8) & 0xFF;
  final int b1 = c1 & 0xFF;

  final int a2 = (c2 >> 24) & 0xFF;
  final int r2 = (c2 >> 16) & 0xFF;
  final int g2 = (c2 >> 8) & 0xFF;
  final int b2 = c2 & 0xFF;

  final int a = (a1 + (a2 - a1) * t).round().clamp(0, 255);
  final int r = (r1 + (r2 - r1) * t).round().clamp(0, 255);
  final int g = (g1 + (g2 - g1) * t).round().clamp(0, 255);
  final int b = (b1 + (b2 - b1) * t).round().clamp(0, 255);
  return (a << 24) | (r << 16) | (g << 8) | b;
}

Map<String, Map<String, String>> _lerPaletasMemora(
  String fonteCoresMemora,
  String fonteCoresDs,
) {
  final String blocoAzul = _extrairBlocoParenteses(
    fonteCoresMemora,
    RegExp(r"'azul'\s*:\s*_PinturaDaPaleta\("),
    "Paleta 'azul' em cores_da_memora.dart",
  );
  final int corpo = _extrairCorHexInt(blocoAzul, 'corpo');
  final int sombra = _extrairCorHexInt(blocoAzul, 'sombra');
  final int luz = _extrairCorHexInt(blocoAzul, 'luz');
  final int contorno = _extrairCorHexInt(blocoAzul, 'contorno');
  final int visor = _extrairCorHexInt(blocoAzul, 'visor');

  final int bochecha = _extrairConstCorPrivada(fonteCoresMemora, '_bochecha');
  final int detalhe = _extrairConstCorPrivada(fonteCoresMemora, '_detalhe');
  final int escudo = _extrairConstCorPrivada(fonteCoresMemora, '_escudo');
  final int escudoLuz = _extrairConstCorPrivada(fonteCoresMemora, '_escudoLuz');
  final int painelBarra = _extrairConstCorPrivada(fonteCoresMemora, '_painelBarra');
  final int livro = _extrairConstCorPrivada(fonteCoresMemora, '_livro');
  final int livroPagina = _extrairConstCorPrivada(fonteCoresMemora, '_livroPagina');
  final int olho = _extrairConstCorPrivada(fonteCoresMemora, '_olho');
  final int branco = _extrairConstCorPrivada(fonteCoresMemora, '_branco');
  final int sombraNoClaro = _extrairConstCorPrivada(fonteCoresMemora, '_sombraNoClaro');
  final int sombraNoEscuro = _extrairConstCorPrivada(fonteCoresMemora, '_sombraNoEscuro');

  final String blocoDsAzul = _extrairBlocoParenteses(
    fonteCoresDs,
    RegExp(r"'azul'\s*:\s*PaletaDeDestaque\("),
    "Paleta 'azul' em cores.dart",
  );
  final int aroEscuro = _extrairCorHexInt(blocoDsAzul, 'primariaEscuro');

  final String blocoAlto = _extrairBlocoParenteses(
    fonteCoresMemora,
    RegExp(r'static\s+const\s+CoresDaMemora\s+altoContraste\s*=\s*CoresDaMemora\('),
    'CoresDaMemora.altoContraste',
  );

  final String brilhoHex = _hexCss(_lerpArgb(visor, branco, 0.55));
  final String luzContornoHex = _hexCss(_lerpArgb(luz, visor, 0.5));

  final Map<String, String> fixos = <String, String>{
    'olho': _hexCss(olho),
    'bochecha': _hexCss(bochecha),
    'detalhe': _hexCss(detalhe),
    'escudo': _hexCss(escudo),
    'escudoLuz': _hexCss(escudoLuz),
    'painelBarra': _hexCss(painelBarra),
    'livro': _hexCss(livro),
    'livroPagina': _hexCss(livroPagina),
  };

  return <String, Map<String, String>>{
    'claro': <String, String>{
      'corpo': _hexCss(corpo),
      'corpoSombra': _hexCss(sombra),
      'corpoLuz': _hexCss(luz),
      'contorno': _hexCss(contorno),
      'aro': _hexCss(contorno),
      'visor': _hexCss(visor),
      'sombraChao': _hexCss(sombraNoClaro),
      'brilho': brilhoHex,
      'luzDeContorno': luzContornoHex,
      ...fixos,
    },
    'escuro': <String, String>{
      'corpo': _hexCss(corpo),
      'corpoSombra': _hexCss(sombra),
      'corpoLuz': _hexCss(luz),
      'contorno': _hexCss(contorno),
      'aro': _hexCss(aroEscuro),
      'visor': _hexCss(visor),
      'sombraChao': _hexCss(sombraNoEscuro),
      'brilho': brilhoHex,
      'luzDeContorno': luzContornoHex,
      ...fixos,
    },
    'alto-contraste': <String, String>{
      'corpo': _hexCss(_extrairCorHexInt(blocoAlto, 'corpo')),
      'corpoSombra': _hexCss(_extrairCorHexInt(blocoAlto, 'corpoSombra')),
      'corpoLuz': _hexCss(_extrairCorHexInt(blocoAlto, 'corpoLuz')),
      'contorno': _hexCss(_extrairCorHexInt(blocoAlto, 'contorno')),
      'aro': _hexCss(_extrairCorHexInt(blocoAlto, 'aro')),
      'visor': _hexCss(_extrairCorHexInt(blocoAlto, 'visor')),
      'olho': _hexCss(_extrairCorHexInt(blocoAlto, 'olho')),
      'sombraChao': 'transparent',
      'brilho': _hexCss(_extrairCorHexInt(blocoAlto, 'brilho')),
      'luzDeContorno': _hexCss(_extrairCorHexInt(blocoAlto, 'luzDeContorno')),
      'bochecha': _hexCss(bochecha),
      'detalhe': _hexCss(detalhe),
      'escudo': _hexCss(escudo),
      'escudoLuz': _hexCss(escudoLuz),
      'painelBarra': _hexCss(painelBarra),
      'livro': _hexCss(livro),
      'livroPagina': _hexCss(livroPagina),
    },
  };
}

class _Pt {
  final double x;
  final double y;
  const _Pt(this.x, this.y);
}

class _Rect {
  final double left;
  final double top;
  final double right;
  final double bottom;
  const _Rect(this.left, this.top, this.right, this.bottom);
  double get width => right - left;
  double get height => bottom - top;
  double get cx => (left + right) / 2;
  double get cy => (top + bottom) / 2;
}

class _Geometria {
  final _Rect cabeca;
  final double raioDaCabeca;
  final _Rect visor;
  final double raioDoVisor;
  final _Pt pescoco;
  final _Pt bolinha;
  final double raioDaBolinha;
  final _Rect tronco;
  final _Pt ombroEsquerdo;
  final _Pt ombroDireito;
  final double bracoOmbro;
  final double bracoPunho;
  final _Rect painel;

  const _Geometria({
    required this.cabeca,
    required this.raioDaCabeca,
    required this.visor,
    required this.raioDoVisor,
    required this.pescoco,
    required this.bolinha,
    required this.raioDaBolinha,
    required this.tronco,
    required this.ombroEsquerdo,
    required this.ombroDireito,
    required this.bracoOmbro,
    required this.bracoPunho,
    required this.painel,
  });
}

_Rect _extrairRect(String fonte, String nome) {
  final RegExpMatch? m = RegExp(
    RegExp.escape(nome) +
        r'\s*=\s*Rect\.fromLTRB\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*\)',
  ).firstMatch(fonte);
  if (m == null) throw FormatException('Rect "$nome" nao encontrado em geometria.dart');
  return _Rect(
    double.parse(m.group(1)!),
    double.parse(m.group(2)!),
    double.parse(m.group(3)!),
    double.parse(m.group(4)!),
  );
}

_Pt _extrairOffset(String fonte, String nome) {
  final RegExpMatch? m = RegExp(
    RegExp.escape(nome) + r'\s*=\s*Offset\(\s*([\d.]+)\s*,\s*([\d.]+)\s*\)',
  ).firstMatch(fonte);
  if (m == null) throw FormatException('Offset "$nome" nao encontrado em geometria.dart');
  return _Pt(double.parse(m.group(1)!), double.parse(m.group(2)!));
}

double _extrairDouble(String fonte, String nome) {
  final RegExpMatch? m = RegExp(
    r'static\s+const\s+double\s+' + RegExp.escape(nome) + r'\s*=\s*([\d.]+)',
  ).firstMatch(fonte);
  if (m == null) throw FormatException('Double "$nome" nao encontrado em geometria.dart');
  return double.parse(m.group(1)!);
}

_Geometria _lerGeometria(String fonte) {
  return _Geometria(
    cabeca: _extrairRect(fonte, 'cabeca'),
    raioDaCabeca: _extrairDouble(fonte, 'raioDaCabeca'),
    visor: _extrairRect(fonte, 'visor'),
    raioDoVisor: _extrairDouble(fonte, 'raioDoVisor'),
    pescoco: _extrairOffset(fonte, 'pescoco'),
    bolinha: _extrairOffset(fonte, 'bolinha'),
    raioDaBolinha: _extrairDouble(fonte, 'raioDaBolinha'),
    tronco: _extrairRect(fonte, 'tronco'),
    ombroEsquerdo: _extrairOffset(fonte, 'ombroEsquerdo'),
    ombroDireito: _extrairOffset(fonte, 'ombroDireito'),
    bracoOmbro: _extrairDouble(fonte, 'bracoOmbro'),
    bracoPunho: _extrairDouble(fonte, 'bracoPunho'),
    painel: _extrairRect(fonte, 'painel'),
  );
}

class _BracoPose {
  final _Pt cotovelo;
  final _Pt mao;
  const _BracoPose(this.cotovelo, this.mao);
}

class _PoseSpec {
  final double inclinacao;
  final double olhoAbertura;
  final double olhoFeliz;
  final double olharX;
  final double olharY;
  final double sorriso;
  final double bocaAbertura;
  final double bocaVisivel;
  final double sobrancelha;
  final double bochecha;
  final _BracoPose bracoEsquerdo;
  final _BracoPose bracoDireito;
  final double dedo;
  final double escudo;
  final double livro;
  final double barra;
  final double corpo;

  const _PoseSpec({
    this.inclinacao = 0,
    this.olhoAbertura = 1,
    this.olhoFeliz = 0,
    this.olharX = 0,
    this.olharY = 0,
    this.sorriso = 0.6,
    this.bocaAbertura = 0,
    this.bocaVisivel = 1,
    this.sobrancelha = 0,
    this.bochecha = 1,
    required this.bracoEsquerdo,
    required this.bracoDireito,
    this.dedo = 0,
    this.escudo = 0,
    this.livro = 0,
    this.barra = 0,
    this.corpo = 1,
  });

  _PoseSpec copiar({
    double? inclinacao,
    double? olhoAbertura,
    double? olhoFeliz,
    double? olharX,
    double? olharY,
    double? sorriso,
    double? bocaAbertura,
    double? bocaVisivel,
    double? sobrancelha,
    double? bochecha,
    _BracoPose? bracoEsquerdo,
    _BracoPose? bracoDireito,
    double? dedo,
    double? escudo,
    double? livro,
    double? barra,
    double? corpo,
  }) {
    return _PoseSpec(
      inclinacao: inclinacao ?? this.inclinacao,
      olhoAbertura: olhoAbertura ?? this.olhoAbertura,
      olhoFeliz: olhoFeliz ?? this.olhoFeliz,
      olharX: olharX ?? this.olharX,
      olharY: olharY ?? this.olharY,
      sorriso: sorriso ?? this.sorriso,
      bocaAbertura: bocaAbertura ?? this.bocaAbertura,
      bocaVisivel: bocaVisivel ?? this.bocaVisivel,
      sobrancelha: sobrancelha ?? this.sobrancelha,
      bochecha: bochecha ?? this.bochecha,
      bracoEsquerdo: bracoEsquerdo ?? this.bracoEsquerdo,
      bracoDireito: bracoDireito ?? this.bracoDireito,
      dedo: dedo ?? this.dedo,
      escudo: escudo ?? this.escudo,
      livro: livro ?? this.livro,
      barra: barra ?? this.barra,
      corpo: corpo ?? this.corpo,
    );
  }
}

Map<String, _PoseSpec> _lerPoses(String fonte) {
  final RegExpMatch? matchEnum = RegExp(
    r'enum\s+PoseDaMemora\s*\{([^}]+)\}',
    dotAll: true,
  ).firstMatch(fonte);
  if (matchEnum == null) {
    throw FormatException('Enum PoseDaMemora nao encontrado em poses.dart.');
  }
  final String semComentarios = matchEnum
      .group(1)!
      .replaceAll(RegExp(r'///.*'), '');
  final List<String> nomesPoses = semComentarios
      .split(',')
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .toList();

  final Map<String, _BracoPose> bracos = <String, _BracoPose>{};
  final RegExp regBraco = RegExp(
    r'static\s+const\s+PosicaoDoBraco\s+(_\w+)\s*=\s*PosicaoDoBraco\(\s*'
    r'Offset\(\s*([\d.]+)\s*,\s*([\d.]+)\s*\)\s*,\s*'
    r'Offset\(\s*([\d.]+)\s*,\s*([\d.]+)\s*\)\s*,?\s*\)',
    dotAll: true,
  );
  for (final RegExpMatch m in regBraco.allMatches(fonte)) {
    bracos[m.group(1)!] = _BracoPose(
      _Pt(double.parse(m.group(2)!), double.parse(m.group(3)!)),
      _Pt(double.parse(m.group(4)!), double.parse(m.group(5)!)),
    );
  }

  final _PoseSpec neutra = _PoseSpec(
    bracoEsquerdo: bracos['_esquerdoBaixo']!,
    bracoDireito: bracos['_direitoBaixo']!,
  );

  final Map<String, _PoseSpec> resultado = <String, _PoseSpec>{};
  for (final String nome in nomesPoses) {
    if (nome == 'neutra') {
      resultado[nome] = neutra;
      continue;
    }
    final RegExpMatch? mCase = RegExp(
      r'case\s+PoseDaMemora\.' +
          RegExp.escape(nome) +
          r':[\s\S]*?return\s+_neutra\.copiar\(([\s\S]*?)\)\s*;',
    ).firstMatch(fonte);
    if (mCase == null) {
      throw FormatException('Caso de PoseDaMemora.$nome nao encontrado em poses.dart.');
    }
    final String args = mCase.group(1)!;

    double? numArg(String campo) {
      final RegExpMatch? m = RegExp(
        r'\b' + RegExp.escape(campo) + r'\s*:\s*([-+]?\d+(?:\.\d+)?)',
      ).firstMatch(args);
      return m != null ? double.parse(m.group(1)!) : null;
    }

    _BracoPose? bracoArg(String campo) {
      final String campoEscapado = RegExp.escape(campo);
      final RegExpMatch? mRef = RegExp(
        '\\b$campoEscapado\\s*:\\s*(_\\w+)',
      ).firstMatch(args);
      if (mRef != null && bracos.containsKey(mRef.group(1))) {
        return bracos[mRef.group(1)!];
      }
      final RegExpMatch? mInline = RegExp(
        '\\b$campoEscapado\\s*:\\s*(?:const\\s+)?PosicaoDoBraco\\(\\s*'
        '(?:const\\s+)?Offset\\(\\s*([\\d.]+)\\s*,\\s*([\\d.]+)\\s*\\)\\s*,\\s*'
        '(?:const\\s+)?Offset\\(\\s*([\\d.]+)\\s*,\\s*([\\d.]+)\\s*\\)\\s*,?\\s*\\)',
        dotAll: true,
      ).firstMatch(args);
      if (mInline != null) {
        return _BracoPose(
          _Pt(double.parse(mInline.group(1)!), double.parse(mInline.group(2)!)),
          _Pt(double.parse(mInline.group(3)!), double.parse(mInline.group(4)!)),
        );
      }
      return null;
    }

    resultado[nome] = neutra.copiar(
      inclinacao: numArg('inclinacaoDaCabeca'),
      olhoAbertura: numArg('olhoAbertura'),
      olhoFeliz: numArg('olhoFeliz'),
      olharX: numArg('olharX'),
      olharY: numArg('olharY'),
      sorriso: numArg('sorriso'),
      bocaAbertura: numArg('bocaAbertura'),
      bocaVisivel: numArg('bocaVisivel'),
      sobrancelha: numArg('sobrancelha'),
      bochecha: numArg('bochecha'),
      bracoEsquerdo: bracoArg('bracoEsquerdo'),
      bracoDireito: bracoArg('bracoDireito'),
      dedo: numArg('dedo'),
      escudo: numArg('escudo'),
      livro: numArg('livro'),
      barra: numArg('barra'),
      corpo: numArg('corpo'),
    );
  }
  return resultado;
}

double _arredondar(double v) => double.parse(v.toStringAsFixed(2));
String _n(double v) => v.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');

Map<String, String> _renderizarPartesBase(_Geometria g) {
  const double lado = 240.0;
  double l(double prop) => prop * lado;

  const String defs =
      '<linearGradient id="g-corpo" x1="0" y1="0" x2="1" y2="1">'
      '<stop offset="0%" stop-color="var(--memora-corpo-luz, #4F76E6)"/>'
      '<stop offset="100%" stop-color="var(--memora-corpo-sombra, #264AA9)"/>'
      '</linearGradient>'
      '<linearGradient id="g-cabeca" x1="0" y1="0" x2="1" y2="1">'
      '<stop offset="0%" stop-color="var(--memora-corpo-luz, #4F76E6)"/>'
      '<stop offset="100%" stop-color="var(--memora-corpo, #3565F3)"/>'
      '</linearGradient>'
      '<linearGradient id="g-visor" x1="0" y1="0" x2="0" y2="1">'
      '<stop offset="0%" stop-color="var(--memora-visor, #D7E4FC)"/>'
      '<stop offset="100%" stop-color="var(--memora-luz-contorno, #91AEF1)"/>'
      '</linearGradient>';

  final String sombra =
      '<ellipse cx="120" cy="${_n(l(0.978))}" rx="${_n(l(0.3))}" ry="${_n(l(0.034))}" fill="var(--memora-sombra-chao, rgba(13, 28, 80, 0.32))"/>'
      '<ellipse cx="120" cy="${_n(l(0.972))}" rx="${_n(l(0.16))}" ry="${_n(l(0.013))}" fill="var(--memora-sombra-chao, rgba(13, 28, 80, 0.32))"/>';

  final double tx = l(g.tronco.left);
  final double ty = l(g.tronco.top);
  final double tw = l(g.tronco.width);
  final double th = l(g.tronco.height);
  final double r = l(0.12);
  final String corpo =
      '<rect x="${_n(tx)}" y="${_n(ty)}" width="${_n(tw)}" height="${_n(th)}" rx="${_n(r)}" '
      'fill="none" stroke="var(--memora-aro, #0D1C50)" stroke-width="20" stroke-linejoin="round" opacity="var(--memora-tem-aro, 0)"/>'
      '<rect x="${_n(tx)}" y="${_n(ty)}" width="${_n(tw)}" height="${_n(th)}" rx="${_n(r)}" '
      'fill="url(#g-corpo)" stroke="var(--memora-contorno, #0D1C50)" stroke-width="12" paint-order="stroke" stroke-linejoin="round"/>'
      '<path d="M${_n(tx + tw * 0.14)} ${_n(ty + th * 0.42)} Q${_n(tx + tw * 0.1)} ${_n(ty + th * 0.22)} ${_n(tx + tw * 0.3)} ${_n(ty + th * 0.1)}" '
      'fill="none" stroke="var(--memora-corpo-luz, #4F76E6)" stroke-width="${_n(l(0.018))}" stroke-linecap="round" opacity="0.8"/>';

  final double px = l(g.painel.left);
  final double py = l(g.painel.top);
  final double pw = l(g.painel.width);
  final double ph = l(g.painel.height);
  final double cxDet = px + pw * 0.29;
  final double cyDet = py + ph / 2;
  final double rDet = ph * 0.3;
  final double iniBarra = px + pw * 0.55;
  final double fimBarra = px + pw * 0.9;
  final String painel =
      '<rect x="${_n(px)}" y="${_n(py)}" width="${_n(pw)}" height="${_n(ph)}" rx="${_n(l(0.025))}" fill="var(--memora-contorno, #0D1C50)"/>'
      '<circle cx="${_n(cxDet)}" cy="${_n(cyDet)}" r="${_n(rDet)}" fill="var(--memora-detalhe, #FAD66B)"/>'
      '<circle cx="${_n(cxDet - rDet * 0.3)}" cy="${_n(cyDet - rDet * 0.3)}" r="${_n(rDet * 0.28)}" fill="var(--memora-livro-pagina, #E8EEF8)" opacity="0.75"/>'
      '<line x1="${_n(iniBarra)}" y1="${_n(py + ph * 0.25)}" x2="${_n(fimBarra)}" y2="${_n(py + ph * 0.25)}" stroke="var(--memora-painel-barra, #9DBAF2)" stroke-width="${_n(ph * 0.13)}" stroke-linecap="round"/>'
      '<line x1="${_n(iniBarra)}" y1="${_n(py + ph * 0.5)}" x2="${_n(iniBarra + (fimBarra - iniBarra) * 0.55)}" y2="${_n(py + ph * 0.5)}" stroke="var(--memora-painel-barra, #9DBAF2)" stroke-width="${_n(ph * 0.13)}" stroke-linecap="round"/>'
      '<line x1="${_n(iniBarra)}" y1="${_n(py + ph * 0.75)}" x2="${_n(fimBarra)}" y2="${_n(py + ph * 0.75)}" stroke="var(--memora-painel-barra, #9DBAF2)" stroke-width="${_n(ph * 0.13)}" stroke-linecap="round"/>';

  final double baseAntY = l(g.cabeca.top + 0.02);
  final double bolX = l(g.bolinha.x);
  final double bolY = l(g.bolinha.y);
  final double rBol = l(g.raioDaBolinha);
  final String antena =
      '<line x1="${_n(bolX)}" y1="${_n(baseAntY)}" x2="${_n(bolX)}" y2="${_n(bolY)}" stroke="var(--memora-aro, #0D1C50)" stroke-width="${_n(l(0.03) + 5.5)}" stroke-linecap="round" opacity="var(--memora-tem-aro, 0)"/>'
      '<line x1="${_n(bolX)}" y1="${_n(baseAntY)}" x2="${_n(bolX)}" y2="${_n(bolY)}" stroke="var(--memora-contorno, #0D1C50)" stroke-width="${_n(l(0.03))}" stroke-linecap="round"/>'
      '<circle cx="${_n(bolX)}" cy="${_n(bolY)}" r="${_n(rBol)}" fill="var(--memora-detalhe, #FAD66B)" stroke="var(--memora-contorno, #0D1C50)" stroke-width="${_n(l(0.032))}" paint-order="stroke"/>'
      '<circle cx="${_n(bolX - rBol * 0.3)}" cy="${_n(bolY - rBol * 0.3)}" r="${_n(rBol * 0.3)}" fill="var(--memora-livro-pagina, #E8EEF8)" opacity="0.75"/>';

  final double hx = l(g.cabeca.left);
  final double hy = l(g.cabeca.top);
  final double hw = l(g.cabeca.width);
  final double hh = l(g.cabeca.height);
  final double hr = l(g.raioDaCabeca);
  final double fw = l(0.105);
  final double fh = l(0.25);
  final double fy = l(g.cabeca.cy + 0.01) - fh / 2;
  final double fEsqX = hx - l(0.012) - fw / 2;
  final double fDirX = hx + hw + l(0.012) - fw / 2;
  final String cabeca =
      '<rect x="${_n(fEsqX)}" y="${_n(fy)}" width="${_n(fw)}" height="${_n(fh)}" rx="${_n(fw / 2)}" fill="var(--memora-corpo-sombra, #264AA9)" stroke="var(--memora-contorno, #0D1C50)" stroke-width="8.4" paint-order="stroke"/>'
      '<rect x="${_n(fDirX)}" y="${_n(fy)}" width="${_n(fw)}" height="${_n(fh)}" rx="${_n(fw / 2)}" fill="var(--memora-corpo-sombra, #264AA9)" stroke="var(--memora-contorno, #0D1C50)" stroke-width="8.4" paint-order="stroke"/>'
      '<rect x="${_n(hx)}" y="${_n(hy)}" width="${_n(hw)}" height="${_n(hh)}" rx="${_n(hr)}" fill="none" stroke="var(--memora-aro, #0D1C50)" stroke-width="20" opacity="var(--memora-tem-aro, 0)"/>'
      '<rect x="${_n(hx)}" y="${_n(hy)}" width="${_n(hw)}" height="${_n(hh)}" rx="${_n(hr)}" fill="url(#g-cabeca)" stroke="var(--memora-contorno, #0D1C50)" stroke-width="12" paint-order="stroke"/>'
      '<path d="M${_n(hx + hw * 0.07)} ${_n(hy + hh * 0.36)} Q${_n(hx + hw * 0.06)} ${_n(hy + hh * 0.12)} ${_n(hx + hw * 0.27)} ${_n(hy + hh * 0.07)}" '
      'fill="none" stroke="var(--memora-brilho, #EEF4FE)" stroke-width="${_n(l(0.016))}" stroke-linecap="round" opacity="0.65"/>';

  final double vx = l(g.visor.left);
  final double vy = l(g.visor.top);
  final double vw = l(g.visor.width);
  final double vh = l(g.visor.height);
  final double vr = l(g.raioDoVisor);
  final String visor =
      '<rect x="${_n(vx)}" y="${_n(vy)}" width="${_n(vw)}" height="${_n(vh)}" rx="${_n(vr)}" fill="url(#g-visor)" stroke="var(--memora-contorno, #0D1C50)" stroke-width="${_n(l(0.04))}" paint-order="stroke"/>'
      '<path d="M${_n(vx + vw * 0.09)} ${_n(vy + vh * 0.30)} Q${_n(vx + vw * 0.09)} ${_n(vy + vh * 0.12)} ${_n(vx + vw * 0.22)} ${_n(vy + vh * 0.10)}" '
      'fill="none" stroke="var(--memora-livro-pagina, #E8EEF8)" stroke-width="${_n(l(0.014))}" stroke-linecap="round" opacity="0.85"/>'
      '<polygon points="${_n(vx + vw * 0.55)},${_n(vy)} ${_n(vx + vw * 0.72)},${_n(vy)} ${_n(vx + vw * 0.44)},${_n(vy + vh)} ${_n(vx + vw * 0.27)},${_n(vy + vh)}" fill="var(--memora-brilho, #EEF4FE)" opacity="0.22"/>';

  return <String, String>{
    'defs': defs,
    'sombra': sombra,
    'corpo': corpo,
    'painel': painel,
    'antena': antena,
    'cabeca': cabeca,
    'visor': visor,
  };
}

Map<String, dynamic> _renderizarVariacaoPose(
  String nome,
  _PoseSpec pose,
  _Geometria g,
) {
  const double lado = 240.0;
  double l(double prop) => prop * lado;

  final double mini = 1.0 - pose.corpo.clamp(0.0, 1.0);
  final double escalaGlobal = 1.0 + 0.25 * mini;
  final double txGlobal = 0.5 * (1.0 - escalaGlobal) * lado;
  final double tyGlobal = mini * 0.0825 * lado;

  final String transformGlobal = (mini > 0.001)
      ? 'translate(${_n(txGlobal)} ${_n(tyGlobal)}) scale(${escalaGlobal.toStringAsFixed(2)})'
      : '';

  final StringBuffer rostoOutras = StringBuffer();
  if (pose.bochecha > 0.01) {
    for (final double s in const <double>[-1, 1]) {
      rostoOutras.write(
        '<ellipse cx="${_n(l(0.5 + s * 0.183))}" cy="${_n(l(0.472))}" rx="${_n(l(0.041))}" ry="${_n(l(0.024))}" fill="var(--memora-bochecha, #FCB5AF)" opacity="${(0.9 * pose.bochecha).toStringAsFixed(2)}"/>',
      );
    }
  }
  if (pose.sobrancelha > 0.01) {
    for (final double s in const <double>[-1, 1]) {
      final double fx = l(0.5 + s * 0.155);
      final double fySob = l(0.318);
      final double mx = l(0.5 + s * 0.105);
      final double my = l(0.296);
      final double dx = l(0.5 + s * 0.055);
      final double dy = l(0.292 - 0.01 * pose.sobrancelha);
      rostoOutras.write(
        '<path d="M${_n(fx)} ${_n(fySob)} Q${_n(mx)} ${_n(my)} ${_n(dx)} ${_n(dy)}" fill="none" stroke="var(--memora-olho, #0E1F53)" stroke-width="${_n(l(0.02))}" stroke-linecap="round" opacity="${pose.sobrancelha.toStringAsFixed(2)}"/>',
      );
    }
  }

  final StringBuffer olhosSvg = StringBuffer();
  for (final double s in const <double>[-1, 1]) {
    final double cxO = l(0.5 + s * 0.105 + pose.olharX * 0.012);
    final double cyO = l(0.375 + pose.olharY * 0.012);
    if (pose.olhoFeliz >= 0.5) {
      olhosSvg.write(
        '<path d="M${_n(cxO - l(0.036))} ${_n(cyO + l(0.014))} Q${_n(cxO)} ${_n(cyO - l(0.034))} ${_n(cxO + l(0.036))} ${_n(cyO + l(0.014))}" '
        'fill="none" stroke="var(--memora-olho, #0E1F53)" stroke-width="${_n(l(0.022))}" stroke-linecap="round"/>',
      );
    } else {
      final double ryO = math.max(l(0.008), l(0.054) * pose.olhoAbertura);
      olhosSvg.write(
        '<ellipse cx="${_n(cxO)}" cy="${_n(cyO)}" rx="${_n(l(0.032))}" ry="${_n(ryO)}" fill="var(--memora-olho, #0E1F53)"/>',
      );
      if (pose.olhoAbertura > 0.45) {
        olhosSvg.write(
          '<circle cx="${_n(cxO - l(0.011))}" cy="${_n(cyO - ryO * 0.38)}" r="${_n(l(0.0095))}" fill="var(--memora-visor, #D7E4FC)"/>',
        );
      }
    }
  }

  String bocaSvg = '';
  if (pose.bocaVisivel > 0.01) {
    final double cxB = l(0.5 + pose.olharX * 0.01);
    final double cyB = l(0.46);
    final double meia = l(0.058 + 0.014 * pose.bocaAbertura);
    final String repouso;
    if (pose.bocaAbertura < 0.12) {
      repouso =
          '<path class="boca-repouso" d="M${_n(cxB - meia)} ${_n(cyB)} Q${_n(cxB)} ${_n(cyB + l(0.06) * pose.sorriso)} ${_n(cxB + meia)} ${_n(cyB)}" '
          'fill="none" stroke="var(--memora-olho, #0E1F53)" stroke-width="${_n(l(0.019))}" stroke-linecap="round"/>';
    } else {
      final double fundo = l(0.025 + 0.07 * pose.bocaAbertura) *
          (0.55 + 0.45 * pose.sorriso.abs());
      repouso =
          '<g class="boca-repouso">'
          '<path d="M${_n(cxB - meia)} ${_n(cyB)} Q${_n(cxB)} ${_n(cyB + l(0.012))} ${_n(cxB + meia)} ${_n(cyB)} Q${_n(cxB)} ${_n(cyB + fundo * 2)} ${_n(cxB - meia)} ${_n(cyB)} Z" fill="var(--memora-olho, #0E1F53)"/>'
          '<ellipse cx="${_n(cxB)}" cy="${_n(cyB + fundo * 1.15)}" rx="${_n(meia * 0.55)}" ry="${_n(fundo * 0.36)}" fill="var(--memora-bochecha, #FCB5AF)"/>'
          '</g>';
    }
    final double fundoFala = l(0.068);
    final double meiaFala = l(0.066);
    final String falando =
        '<g class="boca-falando" opacity="0">'
        '<path d="M${_n(cxB - meiaFala)} ${_n(cyB)} Q${_n(cxB)} ${_n(cyB + l(0.012))} ${_n(cxB + meiaFala)} ${_n(cyB)} Q${_n(cxB)} ${_n(cyB + fundoFala * 2)} ${_n(cxB - meiaFala)} ${_n(cyB)} Z" fill="var(--memora-olho, #0E1F53)"/>'
        '<ellipse cx="${_n(cxB)}" cy="${_n(cyB + fundoFala * 1.15)}" rx="${_n(meiaFala * 0.55)}" ry="${_n(fundoFala * 0.36)}" fill="var(--memora-bochecha, #FCB5AF)"/>'
        '</g>';
    bocaSvg = '$repouso$falando';
  }

  final double angCabecaDeg = pose.inclinacao * 180 / math.pi;
  final String rotCabeca = angCabecaDeg.abs() > 0.01
      ? 'rotate(${angCabecaDeg.toStringAsFixed(2)} ${_n(l(g.pescoco.x))} ${_n(l(g.pescoco.y))})'
      : '';

  String bracoSvg(_Pt ombro, _BracoPose b, bool esquerdo, double dedo) {
    if (pose.corpo <= 0.01) return '';
    final _Pt a = _Pt(l(ombro.x), l(ombro.y));
    final _Pt c = _Pt(l(b.cotovelo.x), l(b.cotovelo.y));
    final _Pt m = _Pt(l(b.mao.x), l(b.mao.y));
    final double wMedio = l((g.bracoOmbro + g.bracoPunho) / 2);
    final double ang = (math.atan2(m.y - c.y, m.x - c.x) - math.pi / 2) * 180 / math.pi;
    final double para = esquerdo ? 1.0 : -1.0;

    final StringBuffer out = StringBuffer();
    out.write(
      '<path d="M${_n(a.x)} ${_n(a.y)} L${_n(c.x)} ${_n(c.y)} L${_n(m.x)} ${_n(m.y)}" '
      'fill="none" stroke="var(--memora-aro, #0D1C50)" stroke-width="${_n(wMedio + 14)}" stroke-linecap="round" stroke-linejoin="round" opacity="var(--memora-tem-aro, 0)"/>',
    );
    out.write(
      '<path d="M${_n(a.x)} ${_n(a.y)} L${_n(c.x)} ${_n(c.y)} L${_n(m.x)} ${_n(m.y)}" '
      'fill="none" stroke="var(--memora-contorno, #0D1C50)" stroke-width="${_n(wMedio + 8)}" stroke-linecap="round" stroke-linejoin="round"/>',
    );
    out.write(
      '<path d="M${_n(a.x)} ${_n(a.y)} L${_n(c.x)} ${_n(c.y)} L${_n(m.x)} ${_n(m.y)}" '
      'fill="none" stroke="url(#g-corpo)" stroke-width="${_n(wMedio)}" stroke-linecap="round" stroke-linejoin="round"/>',
    );

    if (!esquerdo && dedo > 0.01) {
      final double dw = l(0.052);
      final double dl = l(0.16) * dedo;
      out.write(
        '<rect x="${_n(m.x - dw / 2 + l(0.004))}" y="${_n(m.y - l(0.025) - dl)}" width="${_n(dw)}" height="${_n(dl + l(0.02))}" rx="${_n(dw / 2)}" '
        'fill="url(#g-cabeca)" stroke="var(--memora-contorno, #0D1C50)" stroke-width="10" paint-order="stroke"/>',
      );
    }

    out.write(
      '<circle cx="${_n(m.x + para * l(0.046))}" cy="${_n(m.y - l(0.012))}" r="${_n(l(0.03))}" '
      'fill="url(#g-cabeca)" stroke="var(--memora-contorno, #0D1C50)" stroke-width="8" paint-order="stroke"/>',
    );
    out.write(
      '<g transform="translate(${_n(m.x)} ${_n(m.y)}) rotate(${ang.toStringAsFixed(1)})">'
      '<ellipse cx="0" cy="${_n(l(0.008))}" rx="${_n(l(0.054))}" ry="${_n(l(0.064))}" fill="url(#g-corpo)" stroke="var(--memora-contorno, #0D1C50)" stroke-width="10" paint-order="stroke"/>'
      '<circle cx="${_n(-l(0.018))}" cy="${_n(-l(0.022))}" r="${_n(l(0.011))}" fill="var(--memora-brilho, #EEF4FE)" opacity="0.85"/>'
      '</g>',
    );
    return out.toString();
  }

  String livroSvg = '';
  if (pose.livro > 0.01) {
    final double lx = l(0.195);
    final double ly = l(0.80);
    final double mw = l(0.175);
    final double mh = l(0.13);
    livroSvg =
        '<g transform="translate(${_n(lx)} ${_n(ly)}) rotate(-9.2)">'
        '<rect x="${_n(-mw - 2.4)}" y="${_n(-mh - 2.4)}" width="${_n(mw * 2 + 4.8)}" height="${_n(mh * 2 + 6)}" rx="4.8" fill="var(--memora-livro, #5E7FAE)" stroke="var(--memora-contorno, #0D1C50)" stroke-width="9.6" paint-order="stroke"/>'
        '<polygon points="${_n(-mw)},${_n(-mh * 0.9)} ${_n(-1.9)},${_n(-mh)} ${_n(-1.9)},${_n(mh)} ${_n(-mw)},${_n(mh * 0.9)}" fill="var(--memora-livro-pagina, #E8EEF8)"/>'
        '<polygon points="${_n(1.9)},${_n(-mh)} ${_n(mw)},${_n(-mh * 0.9)} ${_n(mw)},${_n(mh * 0.9)} ${_n(1.9)},${_n(mh)}" fill="var(--memora-escudo-luz, #D3E2F5)"/>'
        '</g>';
  }

  String escudoSvg = '';
  if (pose.escudo > 0.01) {
    final double ex = l(0.745);
    final double ey = l(0.80);
    final double mw = l(0.135);
    final double mh = l(0.16);
    final String pathEscudo =
        'M${_n(ex - mw)} ${_n(ey - mh * 0.9)} '
        'Q${_n(ex)} ${_n(ey - mh * 1.15)} ${_n(ex + mw)} ${_n(ey - mh * 0.9)} '
        'L${_n(ex + mw)} ${_n(ey + mh * 0.05)} '
        'Q${_n(ex + mw * 0.9)} ${_n(ey + mh * 0.7)} ${_n(ex)} ${_n(ey + mh)} '
        'Q${_n(ex - mw * 0.9)} ${_n(ey + mh * 0.7)} ${_n(ex - mw)} ${_n(ey + mh * 0.05)} Z';
    escudoSvg =
        '<path d="$pathEscudo" fill="var(--memora-escudo-luz, #D3E2F5)" stroke="var(--memora-contorno, #0D1C50)" stroke-width="10" paint-order="stroke"/>';
  }

  String barraSvg = '';
  if (pose.barra > 0.01) {
    final double ax = l(pose.bracoEsquerdo.mao.x);
    final double bx = l(pose.bracoDireito.mao.x);
    final double ay = l(pose.bracoEsquerdo.mao.y);
    final double larguraBarra = (bx - ax).abs() + l(0.06);
    final double alturaBarra = l(0.10);
    final double folga = l(0.02);
    final double larguraTrilho = (larguraBarra - folga * 2) * 0.4;
    final double alturaTrilho = alturaBarra - folga * 2;
    barraSvg =
        '<rect x="${_n(120 - larguraBarra / 2)}" y="${_n(ay - alturaBarra / 2)}" width="${_n(larguraBarra)}" height="${_n(alturaBarra)}" rx="${_n(alturaBarra / 2)}" fill="url(#g-visor)" stroke="var(--memora-contorno, #0D1C50)" stroke-width="9" paint-order="stroke"/>'
        '<rect x="${_n(120 - larguraTrilho / 2)}" y="${_n(ay - alturaTrilho / 2)}" width="${_n(larguraTrilho)}" height="${_n(alturaTrilho)}" rx="${_n(alturaTrilho / 2)}" fill="var(--memora-corpo, #3565F3)"/>';
  }

  return <String, dynamic>{
    'corpoVisivel': pose.corpo > 0.01,
    'transformGlobal': transformGlobal,
    'rotCabeca': rotCabeca,
    'rostoOutras': rostoOutras.toString(),
    'olhos': olhosSvg.toString(),
    'boca': bocaSvg,
    'bracoEsquerdo': bracoSvg(g.ombroEsquerdo, pose.bracoEsquerdo, true, 0),
    'bracoDireito': bracoSvg(g.ombroDireito, pose.bracoDireito, false, pose.dedo),
    'escudo': escudoSvg,
    'livro': livroSvg,
    'barra': barraSvg,
  };
}

String _montarSvgCompleto(
  String nome,
  Map<String, String> base,
  Map<String, dynamic> v,
) {
  final bool corpoVis = v['corpoVisivel'] == true;
  final String tg = (v['transformGlobal'] as String).isNotEmpty
      ? ' transform="${v['transformGlobal']}"'
      : '';
  final String rc = (v['rotCabeca'] as String).isNotEmpty
      ? ' transform="${v['rotCabeca']}"'
      : '';

  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 240" role="img" aria-hidden="true" data-expressao="$nome">'
      '<defs>${base['defs']}</defs>'
      '<g$tg>'
      '<g id="sombra">${corpoVis ? base['sombra'] : ''}</g>'
      '<g id="corpo">${corpoVis ? base['corpo'] : ''}</g>'
      '<g id="painel-peito">${corpoVis ? base['painel'] : ''}</g>'
      '<g data-parte="cabeca-conjunto"$rc>'
      '<g id="antena">${base['antena']}</g>'
      '<g id="cabeca">${base['cabeca']}</g>'
      '<g id="visor">${base['visor']}</g>'
      '<g id="rosto">${v['rostoOutras']}<g id="olhos">${v['olhos']}</g><g id="boca">${v['boca']}</g></g>'
      '</g>'
      '<g id="barra">${v['barra']}</g>'
      '<g id="livro">${v['livro']}</g>'
      '<g id="braco-esquerdo">${v['bracoEsquerdo']}</g>'
      '<g id="braco-direito">${v['bracoDireito']}</g>'
      '<g id="escudo">${v['escudo']}</g>'
      '</g>'
      '</svg>';
}

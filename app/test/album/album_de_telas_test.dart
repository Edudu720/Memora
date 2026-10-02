import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';

import '../features/autenticacao/fluxo_dentro_da_conta.dart';
import '../suporte/aparelhos.dart';
import '../suporte/fonte.dart';

/// O álbum de telas (T043, R13 da feature 004).
///
/// ## Para que serve
///
/// Existe para a **revisão de design** (SC-005) olhar as telas lado a lado com
/// o wireframe, sem montar emulador nem aparelho. Cada tela é desenhada em cada
/// tema, **com a Atkinson Hyperlegible Next carregada** — o `flutter test`
/// desenharia tudo com a fonte quadrada, e uma imagem assim não diz nada sobre
/// o que a pessoa vê — e salva como PNG em `build/album/<tema>/`.
///
/// ## O que ele **não** faz
///
/// **Não compara nada.** Não é teste de *golden*: o motor de texto do Windows
/// (as duas máquinas) e o do Linux (o CI) desenham o mesmo texto diferente, e
/// um portão que reprova por motivo que não é defeito ensina a equipe a
/// ignorá-lo (R13). Passa quando consegue desenhar e salvar; quem decide se
/// está bonito é gente.
///
/// ## Como a tela é fotografada
///
/// O aplicativo de verdade — o `FluxoAutenticacao`, entrando pelo login
/// simulado — é montado dentro de um `RepaintBoundary`, e é a imagem dele que
/// vai para o disco. Assim a barra inferior, o cabeçalho e os dados são os que
/// a pessoa vê, e não os de uma tela solta.
///
/// ⚠️ Gravar arquivo é I/O real, e dentro de `testWidgets` o relógio é falso:
/// só completa em `runAsync`. É por isso que a captura inteira vive nele.
///
/// ## Como rodar
///
/// Faz parte do `flutter test` comum. Para só o álbum:
///
/// ```powershell
/// cd app; flutter test test/album
/// ```
///
/// As imagens ficam em `app/build/album/`, que o Git ignora.
void main() {
  const Size aparelho = referencia;
  final Directory pasta = Directory('build/album');

  setUpAll(() async {
    await carregarAtkinson();
    await _carregarIcones();
    // Recomeça limpo: uma tela que deixou de existir não pode continuar no
    // álbum como se existisse.
    if (pasta.existsSync()) pasta.deleteSync(recursive: true);
  });

  /// Espera as ilustrações (SVG) carregarem.
  ///
  /// O `flutter_svg` lê o arquivo do disco, e I/O real não completa com o
  /// relógio falso: é preciso deixar o relógio de verdade correr um pouco, e
  /// bombear de novo para o quadro pegar o desenho pronto.
  Future<void> esperarOsDesenhos(WidgetTester t) async {
    for (int i = 0; i < 3; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  /// Fotografa o que está dentro de [chave] e grava em [arquivo].
  Future<void> salvar(WidgetTester t, GlobalKey chave, File arquivo) async {
    await esperarOsDesenhos(t);
    await t.runAsync(() async {
      final RenderRepaintBoundary limite =
          chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image imagem = await limite.toImage(pixelRatio: 2);
      final ByteData? bytes = await imagem.toByteData(
        format: ui.ImageByteFormat.png,
      );
      expect(bytes, isNotNull, reason: 'não consegui codificar ${arquivo.path}');
      await arquivo.parent.create(recursive: true);
      await arquivo.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  for (final MemoraTemaId tema in MemoraTemaId.values) {
    testWidgets('o Início e o Hub, no tema ${tema.name}', (
      WidgetTester t,
    ) async {
      final Combinacao c = (aparelho: aparelho, escala: 1.0, tema: tema);
      final GlobalKey chave = GlobalKey(debugLabel: 'album.${tema.name}');
      final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
      await fluxo.montar(t, em: c, capturavel: chave);

      final File inicio = File('${pasta.path}/${tema.name}/01_inicio.png');
      await salvar(t, chave, inicio);

      await FluxoDentroDaConta.irAoHub(t);
      final File hub = File('${pasta.path}/${tema.name}/02_hub.png');
      await salvar(t, chave, hub);

      for (final File f in <File>[inicio, hub]) {
        expect(f.existsSync(), isTrue, reason: '${f.path} não foi gravado');
        // PNG de verdade, e não um arquivo vazio.
        expect(
          f.lengthSync(),
          greaterThan(10 * 1024),
          reason: '${f.path} saiu pequeno demais para ser uma tela',
        );
      }
    });
  }
}

/// Carrega a fonte de ícones do Material.
///
/// Sem ela, todo `Icon` sai como um quadrado. Mora aqui, e não em
/// `suporte/fonte.dart`, porque só o álbum **olha**: a matriz mede com o
/// quadrado e não se importa com o glifo.
Future<void> _carregarIcones() async {
  final String? raiz = Platform.environment['FLUTTER_ROOT'];
  if (raiz == null) return;
  final File arquivo = File(
    '$raiz/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (!arquivo.existsSync()) return;
  final FontLoader carregador = FontLoader('MaterialIcons')
    ..addFont(
      Future<ByteData>.value(
        ByteData.sublistView(Uint8List.fromList(arquivo.readAsBytesSync())),
      ),
    );
  await carregador.load();
}

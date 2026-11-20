import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';
import 'package:memora/features/perfil/data/foto_de_perfil_local.dart';
import 'package:memora/features/perfil/data/seletor_de_imagem.dart';
import 'package:memora/features/perfil/domain/processador_de_imagem.dart';
import 'package:memora/features/perfil/domain/retrato_de_perfil.dart';
import 'package:memora/features/perfil/presentation/secao_foto_perfil.dart';
import 'package:memora/features/perfil/presentation/tela_perfil.dart';
import 'package:memora/features/perfil/presentation/tela_pre_visualizacao_foto.dart';
import 'package:memora/features/perfil/presentation/widgets/retrato_do_perfil.dart';
import 'package:memora/l10n/textos_perfil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SeletorFalso implements SeletorDeImagemDoAparelho {
  final List<OrigemDaFoto> chamadas = <OrigemDaFoto>[];
  Future<ResultadoDaSelecao> Function(OrigemDaFoto origem)? aoSelecionar;
  int chamadasConfiguracoes = 0;

  @override
  Future<ResultadoDaSelecao> selecionar(OrigemDaFoto origem) async {
    chamadas.add(origem);
    if (aoSelecionar != null) {
      return aoSelecionar!(origem);
    }
    return const SelecaoCancelada();
  }

  @override
  Future<bool> abrirConfiguracoesDoAparelho() async {
    chamadasConfiguracoes++;
    return true;
  }
}

Uint8List _criarJpegValido({int largura = 640, int altura = 480}) {
  final img.Image imagem = img.Image(width: largura, height: altura);
  img.fill(imagem, color: img.ColorRgb8(40, 120, 200));
  return Uint8List.fromList(img.encodeJpg(imagem, quality: 90));
}

Future<void> _tocar(WidgetTester t, Finder alvo) async {
  await t.ensureVisible(alvo);
  await t.pumpAndSettle();
  await t.tap(alvo);
  await t.pumpAndSettle();
}

void main() {
  late FotoDePerfilEmMemoria armazenamento;
  late _SeletorFalso seletor;

  setUp(() {
    armazenamento = FotoDePerfilEmMemoria();
    seletor = _SeletorFalso();
  });

  Widget montarPerfil(
    WidgetTester t, {
    Key? key,
    String nome = 'Dona Ana',
    String? idDaConta = 'conta-123',
    ThemeData? tema,
    double escala = 1.0,
    Size tamanho = const Size(390, 844),
    bool reduzirMovimento = true,
  }) {
    t.view.physicalSize = tamanho;
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    return MaterialApp(
      theme: tema ?? TemasMemora.claro,
      builder: (BuildContext context, Widget? child) {
        final MediaQueryData media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(escala),
            disableAnimations: reduzirMovimento,
          ),
          child: child!,
        );
      },
      home: TelaPerfil(
        key: key,
        nome: nome,
        canal: Future<String?>.value('ana@exemplo.com'),
        fotoDePerfil: armazenamento,
        seletorDeFoto: seletor,
        processadorDeFoto: const ProcessadorDeImagemDePerfil(emIsolate: false),
        idDaConta: idDaConta,
      ),
    );
  }

  group('US1 — Colocar foto de perfil ou avatar pela primeira vez', () {
    testWidgets(
      'exibe retrato padrão neutro por iniciais/silhueta e botão explícito',
      (WidgetTester t) async {
        final SemanticsHandle semantics = t.ensureSemantics();
        await t.pumpWidget(montarPerfil(t));
        await t.pumpAndSettle();

        expect(find.byKey(TelaPerfil.chaveDesenho), findsOneWidget);
        expect(find.text('DA'), findsOneWidget);
        expect(find.byType(MemoraPersonagem), findsNothing);
        expect(
          find.bySemanticsLabel(TextosPerfil.semanticaSemFoto),
          findsOneWidget,
        );

        final Finder botao = find.byKey(
          SecaoFotoPerfil.chaveBotaoColocarOuTrocar,
        );
        expect(botao, findsOneWidget);
        expect(find.text(TextosPerfil.botaoColocarFoto), findsOneWidget);
        expect(
          t.getSize(botao).height,
          greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo),
        );

        // Nome sem letras recua para ícone humano neutro
        await t.pumpWidget(
          montarPerfil(t, key: const ValueKey<String>('vazio'), nome: '   '),
        );
        await t.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byKey(TelaPerfil.chaveDesenho),
            matching: find.byIcon(Icons.person_outline_rounded),
          ),
          findsOneWidget,
        );
        semantics.dispose();
      },
    );

    testWidgets(
      'folha de escolha traz explicação integrada (FR-004) e salva foto da galeria após pré-visualização',
      (WidgetTester t) async {
        final Uint8List jpeg = _criarJpegValido();
        seletor.aoSelecionar = (_) async => SelecaoConfirmada(jpeg);

        await t.pumpWidget(montarPerfil(t));
        await t.pumpAndSettle();

        await _tocar(t, find.byKey(SecaoFotoPerfil.chaveBotaoColocarOuTrocar));

        // Explicação integrada visível antes de tocar em qualquer opção
        expect(find.text(TextosPerfil.avisoPrivacidadeFoto), findsOneWidget);
        expect(find.byKey(SecaoFotoPerfil.chaveOpcaoGaleria), findsOneWidget);
        expect(find.byKey(SecaoFotoPerfil.chaveOpcaoCamera), findsOneWidget);
        expect(find.byKey(SecaoFotoPerfil.chaveOpcaoAvatares), findsOneWidget);

        await _tocar(t, find.byKey(SecaoFotoPerfil.chaveOpcaoGaleria));

        expect(seletor.chamadas, <OrigemDaFoto>[OrigemDaFoto.galeria]);
        expect(find.byType(TelaPreVisualizacaoFoto), findsOneWidget);
        expect(
          find.text(TextosPerfil.tituloPreVisualizacaoFoto),
          findsOneWidget,
        );

        await _tocar(t, find.byKey(TelaPreVisualizacaoFoto.chaveConfirmar));

        expect(find.byType(TelaPreVisualizacaoFoto), findsNothing);
        expect(
          find.text(TextosPerfil.fotoAtualizadaComSucesso),
          findsOneWidget,
        );
        expect(find.text(TextosPerfil.botaoTrocarFoto), findsOneWidget);
        expect(find.byKey(SecaoFotoPerfil.chaveBotaoRemover), findsOneWidget);

        final RetratoDePerfil? salvo = await armazenamento.ler('conta-123');
        expect(salvo, isA<FotoPropriaDePerfil>());

        // Recria a tela e verifica persistência + TelaInicio inalterada (FR-010)
        await t.pumpWidget(montarPerfil(t, key: const ValueKey<int>(2)));
        await t.pumpAndSettle();
        expect(find.text(TextosPerfil.botaoTrocarFoto), findsOneWidget);
        expect(
          find.bySemanticsLabel(TextosPerfil.semanticaFotoPropria),
          findsOneWidget,
        );

        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaInicio(nome: 'Dona Ana', aoConversar: () {}),
          ),
        );
        await t.pumpAndSettle();
        expect(find.byType(RetratoDoPerfil), findsNothing);
        expect(find.byType(MemoraAnfitria), findsOneWidget);
      },
    );

    testWidgets('câmera salva foto e cancelamento retorna sem erro', (
      WidgetTester t,
    ) async {
      final Uint8List jpeg = _criarJpegValido();
      seletor.aoSelecionar = (OrigemDaFoto o) async => o == OrigemDaFoto.camera
          ? SelecaoConfirmada(jpeg)
          : const SelecaoCancelada();

      await t.pumpWidget(montarPerfil(t));
      await t.pumpAndSettle();

      // Cancelamento na galeria mantém estado padrão sem aviso de erro
      await _tocar(t, find.byKey(SecaoFotoPerfil.chaveBotaoColocarOuTrocar));
      await _tocar(t, find.byKey(SecaoFotoPerfil.chaveOpcaoGaleria));
      expect(
        find.byKey(SecaoFotoPerfil.chaveAvisoErroOuPermissao),
        findsNothing,
      );
      expect(await armazenamento.ler('conta-123'), isNull);

      // Câmera com confirmação
      await _tocar(t, find.byKey(SecaoFotoPerfil.chaveBotaoColocarOuTrocar));
      await _tocar(t, find.byKey(SecaoFotoPerfil.chaveOpcaoCamera));
      await _tocar(t, find.byKey(TelaPreVisualizacaoFoto.chaveConfirmar));

      expect(seletor.chamadas, <OrigemDaFoto>[
        OrigemDaFoto.galeria,
        OrigemDaFoto.camera,
      ]);
      expect(await armazenamento.ler('conta-123'), isA<FotoPropriaDePerfil>());
    });

    testWidgets(
      'avatar da Memora salva imediatamente sem chamar seletor nativo',
      (WidgetTester t) async {
        await t.pumpWidget(montarPerfil(t));
        await t.pumpAndSettle();

        await _tocar(t, find.byKey(SecaoFotoPerfil.chaveBotaoColocarOuTrocar));
        await _tocar(t, find.byKey(SecaoFotoPerfil.chaveOpcaoAvatares));

        // Duplo sinal visual via OpcaoSelecionavel / SuperficieTocavel
        expect(
          find.byType(OpcaoSelecionavel),
          findsNWidgets(AvatarIlustrado.values.length),
        );
        await _tocar(
          t,
          find.byKey(
            Key(
              'perfil.foto.avatar.${AvatarIlustrado.memoraComemorando.chave}',
            ),
          ),
        );

        expect(seletor.chamadas, isEmpty);
        final RetratoDePerfil? salvo = await armazenamento.ler('conta-123');
        expect(salvo, isA<AvatarIlustradoDePerfil>());
        expect(
          (salvo as AvatarIlustradoDePerfil).avatar,
          AvatarIlustrado.memoraComemorando,
        );
      },
    );
  });

  group('US2 — Trocar, remover, isolar por conta e bloquear concorrência', () {
    testWidgets(
      '"Escolher outra" volta à origem preservando o retrato anterior; remoção pede confirmação',
      (WidgetTester t) async {
        await armazenamento.salvarAvatar(
          'conta-123',
          AvatarIlustrado.memoraAcenando,
        );
        seletor.aoSelecionar = (_) async =>
            SelecaoConfirmada(_criarJpegValido());

        await t.pumpWidget(montarPerfil(t));
        await t.pumpAndSettle();

        expect(find.text(TextosPerfil.botaoTrocarFoto), findsOneWidget);
        final double fundoTrocar = t
            .getRect(find.byKey(SecaoFotoPerfil.chaveBotaoColocarOuTrocar))
            .bottom;
        final double topoRemover = t
            .getRect(find.byKey(SecaoFotoPerfil.chaveBotaoRemover))
            .top;
        expect(
          topoRemover - fundoTrocar,
          greaterThanOrEqualTo(MemoraEspacamento.sm),
        );

        // Trocar -> Galeria -> "Escolher outra" reabre folha -> fecha sem salvar foto nova
        await _tocar(t, find.byKey(SecaoFotoPerfil.chaveBotaoColocarOuTrocar));
        await _tocar(t, find.byKey(SecaoFotoPerfil.chaveOpcaoGaleria));
        await _tocar(t, find.byKey(TelaPreVisualizacaoFoto.chaveEscolherOutra));

        // Folha inferior reaberta
        expect(
          find.text(TextosPerfil.tituloEscolherOrigemFoto),
          findsOneWidget,
        );
        await _tocar(t, find.text('Fechar'));

        // Avatar anterior intacto
        expect(
          await armazenamento.ler('conta-123'),
          isA<AvatarIlustradoDePerfil>(),
        );

        // Remoção: cancelar mantém; confirmar apaga
        await _tocar(t, find.byKey(SecaoFotoPerfil.chaveBotaoRemover));
        expect(
          find.byKey(SecaoFotoPerfil.chaveConfirmacaoRemover),
          findsOneWidget,
        );

        await _tocar(t, find.text(TextosPerfil.botaoManterFoto));
        expect(await armazenamento.ler('conta-123'), isNotNull);

        await _tocar(t, find.byKey(SecaoFotoPerfil.chaveBotaoRemover));
        await _tocar(t, find.text(TextosPerfil.botaoConfirmarRemoverFoto));

        expect(await armazenamento.ler('conta-123'), isNull);
        expect(find.text(TextosPerfil.fotoRemovidaComSucesso), findsOneWidget);
        expect(find.text(TextosPerfil.botaoColocarFoto), findsOneWidget);
      },
    );

    testWidgets(
      'troca de idDaConta isola retratos e evita gravação após expiração externa',
      (WidgetTester t) async {
        await armazenamento.salvarAvatar('conta-A', AvatarIlustrado.memoraAcenando);

        await t.pumpWidget(montarPerfil(t, nome: 'Ana', idDaConta: 'conta-A'));
        await t.pumpAndSettle();
        expect(find.text(TextosPerfil.botaoTrocarFoto), findsOneWidget);

        // Conta B não enxerga nada de A
        await t.pumpWidget(montarPerfil(t, nome: 'Beto', idDaConta: 'conta-B'));
        await t.pumpAndSettle();
        expect(find.text(TextosPerfil.botaoColocarFoto), findsOneWidget);

        // Simula seleção lenta na conta B enquanto a conta muda/expira antes de retornar
        final Completer<ResultadoDaSelecao> pendente =
            Completer<ResultadoDaSelecao>();
        seletor.aoSelecionar = (_) => pendente.future;

        await _tocar(t, find.byKey(SecaoFotoPerfil.chaveBotaoColocarOuTrocar));
        await t.ensureVisible(find.byKey(SecaoFotoPerfil.chaveOpcaoGaleria));
        await t.tap(find.byKey(SecaoFotoPerfil.chaveOpcaoGaleria));
        await t.pump();

        expect(seletor.chamadas.length, 1);

        // Muda para conta-C (simulando troca/expiração)
        await t.pumpWidget(
          montarPerfil(t, nome: 'Clara', idDaConta: 'conta-C'),
        );
        await t.pump();

        pendente.complete(SelecaoConfirmada(_criarJpegValido()));
        await t.pumpAndSettle();

        expect(find.byType(TelaPreVisualizacaoFoto), findsNothing);
        expect(await armazenamento.ler('conta-B'), isNull);
        expect(await armazenamento.ler('conta-C'), isNull);
      },
    );
  });

  group('US3 — Permissões negadas, arquivos inválidos e acessibilidade', () {
    testWidgets(
      'permissão negada orienta em português, abre ajustes e permite avatar como fallback',
      (WidgetTester t) async {
        seletor.aoSelecionar = (OrigemDaFoto o) async => SelecaoSemPermissao(o);

        await t.pumpWidget(montarPerfil(t));
        await t.pumpAndSettle();

        await _tocar(t, find.byKey(SecaoFotoPerfil.chaveBotaoColocarOuTrocar));
        await _tocar(t, find.byKey(SecaoFotoPerfil.chaveOpcaoCamera));

        expect(
          find.byKey(SecaoFotoPerfil.chaveAvisoErroOuPermissao),
          findsOneWidget,
        );
        expect(find.text(TextosPerfil.erroPermissaoCamera), findsOneWidget);

        await _tocar(t, find.byKey(SecaoFotoPerfil.chaveBotaoAbrirAjustes));
        expect(seletor.chamadasConfiguracoes, 1);

        await _tocar(
          t,
          find.byKey(SecaoFotoPerfil.chaveBotaoUsarAvatarFallback),
        );
        await _tocar(
          t,
          find.byKey(
            Key('perfil.foto.avatar.${AvatarIlustrado.memoraComemorando.chave}'),
          ),
        );

        expect(
          await armazenamento.ler('conta-123'),
          isA<AvatarIlustradoDePerfil>(),
        );
      },
    );

    testWidgets(
      'arquivo inválido ou > 15 MB mantém foto anterior e exibe aviso claro',
      (WidgetTester t) async {
        await armazenamento.salvarAvatar(
          'conta-123',
          AvatarIlustrado.memoraPensando,
        );
        seletor.aoSelecionar = (_) async =>
            SelecaoConfirmada(Uint8List.fromList('NOT_AN_IMAGE_PDF'.codeUnits));

        await t.pumpWidget(montarPerfil(t));
        await t.pumpAndSettle();

        await _tocar(t, find.byKey(SecaoFotoPerfil.chaveBotaoColocarOuTrocar));
        await _tocar(t, find.byKey(SecaoFotoPerfil.chaveOpcaoGaleria));

        expect(
          find.text(TextosPerfil.erroImagemFormatoInvalido),
          findsOneWidget,
        );
        expect(
          await armazenamento.ler('conta-123'),
          isA<AvatarIlustradoDePerfil>(),
        );
      },
    );

    for (final (String nomeTema, ThemeData tema) in <(String, ThemeData)>[
      ('claro', TemasMemora.claro),
      ('escuro', TemasMemora.escuro),
      ('altoContraste', TemasMemora.altoContraste),
    ]) {
      testWidgets(
        'acessibilidade 200% + disableAnimations sem overflow no tema $nomeTema',
        (WidgetTester t) async {
          seletor.aoSelecionar = (_) async =>
              SelecaoConfirmada(_criarJpegValido());
          await armazenamento.salvarAvatar(
            'conta-123',
            AvatarIlustrado.memoraProtegendo,
          );

          await t.pumpWidget(
            montarPerfil(
              t,
              tema: tema,
              escala: 2.0,
              tamanho: const Size(320, 568),
            ),
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);

          expect(
            t
                .getSize(find.byKey(SecaoFotoPerfil.chaveBotaoColocarOuTrocar))
                .height,
            greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo),
          );
          expect(
            t.getSize(find.byKey(SecaoFotoPerfil.chaveBotaoRemover)).height,
            greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo),
          );

          // Folha de origem a 200% no menor aparelho
          await _tocar(
            t,
            find.byKey(SecaoFotoPerfil.chaveBotaoColocarOuTrocar),
          );
          expect(t.takeException(), isNull);

          // Pré-visualização a 200% com disableAnimations
          await _tocar(t, find.byKey(SecaoFotoPerfil.chaveOpcaoGaleria));
          expect(find.byType(TelaPreVisualizacaoFoto), findsOneWidget);
          expect(t.takeException(), isNull);
          expect(
            t
                .getSize(find.byKey(TelaPreVisualizacaoFoto.chaveConfirmar))
                .height,
            greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo),
          );
        },
      );
    }

    testWidgets(
      'T081: avatares usam desenhos vetoriais/ícones da 013 e TelaPerfil não exibe Memora extra',
      (WidgetTester t) async {
        await t.pumpWidget(montarPerfil(t));
        await t.pumpAndSettle();
        expect(find.byType(MemoraAnimada), findsNothing);
        expect(find.byType(Image), findsNothing);

        for (final AvatarIlustrado avatar in AvatarIlustrado.values) {
          await armazenamento.salvarAvatar('conta-123', avatar);
          await t.pumpWidget(
            KeyedSubtree(
              key: ValueKey<AvatarIlustrado>(avatar),
              child: montarPerfil(t),
            ),
          );
          await t.pumpAndSettle();

          expect(find.byType(DesenhoAvatarIlustrado), findsOneWidget);
          final DesenhoAvatarIlustrado desenho = t.widget<DesenhoAvatarIlustrado>(
            find.byType(DesenhoAvatarIlustrado),
          );
          expect(desenho.animado, isFalse, reason: avatar.chave);
          expect(find.byType(Image), findsNothing, reason: avatar.chave);
        }
      },
    );

    testWidgets(
      'feature 016: grade exibe apenas 4 avatares válidos e fallback legado abre no padrão neutro',
      (WidgetTester t) async {
        // 1) Verifica apenas os 4 avatares da Memora na seleção.
        expect(AvatarIlustrado.values, hasLength(4));
        await t.pumpWidget(montarPerfil(t));
        await t.pumpAndSettle();

        await _tocar(t, find.byKey(SecaoFotoPerfil.chaveBotaoColocarOuTrocar));
        await _tocar(t, find.byKey(SecaoFotoPerfil.chaveOpcaoAvatares));

        expect(find.text('Casal acolhedor'), findsNothing);
        expect(find.text('Pessoa com celular'), findsNothing);
        for (final AvatarIlustrado item in AvatarIlustrado.values) {
          expect(
            find.byKey(Key('perfil.foto.avatar.${item.chave}')),
            findsOneWidget,
          );
        }

        // Fecha a folha e testa persistência legada real em SharedPreferences.
        Navigator.of(t.element(find.byType(TelaPerfil))).pop();
        await t.pumpAndSettle();

        for (final String chaveAposentada in <String>[
          'casal_idoso',
          'pessoa_com_celular',
        ]) {
          SharedPreferences.setMockInitialValues(<String, Object>{
            '${FotoDePerfilLocal.prefixoChave}${FotoDePerfilLocal.contaSegura('conta-legada')}':
                jsonEncode(<String, String>{
                  'tipo': 'avatar',
                  'avatar': chaveAposentada,
                }),
          });
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final FotoDePerfilLocal local = FotoDePerfilLocal(prefs);

          final SemanticsHandle semantics = t.ensureSemantics();
          await t.pumpWidget(
            MaterialApp(
              theme: TemasMemora.claro,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: SecaoFotoPerfil(
                    nome: 'Dona Ana',
                    armazenamento: local,
                    idDaConta: 'conta-legada',
                    seletor: seletor,
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();

          expect(t.takeException(), isNull, reason: chaveAposentada);
          expect(find.text('DA'), findsOneWidget, reason: chaveAposentada);
          expect(
            find.bySemanticsLabel(TextosPerfil.semanticaSemFoto),
            findsOneWidget,
          );
          expect(find.text(TextosPerfil.botaoColocarFoto), findsOneWidget);
          semantics.dispose();

          // A pessoa continua conseguindo escolher e salvar um avatar válido.
          await _tocar(t, find.byKey(SecaoFotoPerfil.chaveBotaoColocarOuTrocar));
          await _tocar(t, find.byKey(SecaoFotoPerfil.chaveOpcaoAvatares));
          await _tocar(
            t,
            find.byKey(
              Key('perfil.foto.avatar.${AvatarIlustrado.memoraAcenando.chave}'),
            ),
          );
          final RetratoDePerfil? salvo = await local.ler('conta-legada');
          expect(salvo, isA<AvatarIlustradoDePerfil>());
          expect(
            (salvo as AvatarIlustradoDePerfil).avatar,
            AvatarIlustrado.memoraAcenando,
          );
        }
      },
    );
  });
}

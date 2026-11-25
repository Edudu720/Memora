import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/conversa_local.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/assistente/presentation/controladores/controlador_conversa.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/features/perfil/data/foto_de_perfil_local.dart';
import 'package:memora/features/perfil/domain/retrato_de_perfil.dart';
import 'package:memora/features/perfil/presentation/widgets/retrato_do_perfil.dart';
import 'package:memora/l10n/textos_perfil.dart';

import '../../suporte/aceite_em_memoria.dart';
import '../../suporte/aparelhos.dart';
import '../../suporte/escrita_da_resposta.dart';
import '../../suporte/movimento.dart';

class _RepositorioControlado implements RepositorioAssistente {
  int chamadasConversar = 0;
  void Function(String trecho)? aoReceberTrecho;
  Completer<RespostaDaAssistente>? respostaPendente;

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
    void Function(void Function() cancelar)? aoCriarCancelamento,
  }) {
    chamadasConversar++;
    this.aoReceberTrecho = aoReceberTrecho;
    final Completer<RespostaDaAssistente> c = Completer<RespostaDaAssistente>();
    respostaPendente = c;
    return c.future;
  }

  @override
  Future<List<ServicoDoCatalogo>> catalogo() => throw UnimplementedError();

  @override
  Future<void> registrarAcao({
    required String servicoId,
    required String pedidoResumido,
  }) => throw UnimplementedError();

  @override
  Future<List<AcaoRegistrada>> registro() => throw UnimplementedError();
}

class _ConversaEmMemoria implements ConversaLocal {
  List<MensagemDaConversa> _mensagens;

  _ConversaEmMemoria([List<MensagemDaConversa>? iniciais])
    : _mensagens = iniciais ?? <MensagemDaConversa>[];

  @override
  Future<List<MensagemDaConversa>> ler() async => _mensagens;

  @override
  Future<void> guardar(List<MensagemDaConversa> mensagens) async {
    _mensagens = List<MensagemDaConversa>.from(mensagens);
  }

  @override
  Future<void> apagar() async {
    _mensagens = <MensagemDaConversa>[];
  }
}

class _ArmazenamentoArquivoInexistente implements ArmazenamentoDeFotoDePerfil {
  final RetratoDePerfil? retrato;
  final bool lancarErroAoLer;

  _ArmazenamentoArquivoInexistente({this.retrato, this.lancarErroAoLer = false});

  @override
  Stream<void> get alteracoes => const Stream<void>.empty();

  @override
  Future<RetratoDePerfil?> ler(String idDaConta) async {
    if (lancarErroAoLer) {
      throw const FileSystemException('Falha simulada de leitura');
    }
    return retrato;
  }

  @override
  Future<FotoPropriaDePerfil> salvarFoto(
    String idDaConta,
    Uint8List bytesJpegSanitizados,
  ) => throw UnimplementedError();

  @override
  Future<AvatarIlustradoDePerfil> salvarAvatar(
    String idDaConta,
    AvatarIlustrado avatar,
  ) => throw UnimplementedError();

  @override
  Future<void> apagar(String idDaConta) async {}
}

class _ArmazenamentoComCompleters implements ArmazenamentoDeFotoDePerfil {
  final Map<String, Completer<RetratoDePerfil?>> leituras =
      <String, Completer<RetratoDePerfil?>>{};

  @override
  Stream<void> get alteracoes => const Stream<void>.empty();

  @override
  Future<RetratoDePerfil?> ler(String idDaConta) =>
      leituras.putIfAbsent(idDaConta, Completer<RetratoDePerfil?>.new).future;

  @override
  Future<FotoPropriaDePerfil> salvarFoto(
    String idDaConta,
    Uint8List bytesJpegSanitizados,
  ) => throw UnimplementedError();

  @override
  Future<AvatarIlustradoDePerfil> salvarAvatar(
    String idDaConta,
    AvatarIlustrado avatar,
  ) => throw UnimplementedError();

  @override
  Future<void> apagar(String idDaConta) async {}
}

Uint8List _criarJpegValido() {
  final img.Image imagem = img.Image(width: 16, height: 16);
  img.fill(imagem, color: img.ColorRgb8(16, 64, 248));
  return Uint8List.fromList(img.encodeJpg(imagem, quality: 90));
}

List<MensagemDaConversa> _historicoBase() => <MensagemDaConversa>[
  MensagemDaConversa(
    autor: AutorDaMensagem.pessoa,
    texto: 'Como eu mando uma foto no WhatsApp?',
    momento: DateTime(2026, 11, 22, 10),
  ),
  MensagemDaConversa(
    autor: AutorDaMensagem.memora,
    texto:
        'Claro, abra o WhatsApp e entre na conversa de quem vai receber a foto.',
    momento: DateTime(2026, 11, 22, 10, 1),
  ),
];

void main() {
  movimentoLiberado();

  Future<void> avancar(WidgetTester t, {int quadros = 5}) async {
    for (int i = 0; i < quadros; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> irAoTopo(WidgetTester t) async {
    final Finder rolavel = find.descendant(
      of: find.byType(ListView).first,
      matching: find.byType(Scrollable),
    );
    if (rolavel.evaluate().isNotEmpty) {
      t.state<ScrollableState>(rolavel.first).position.jumpTo(0);
      await t.pump();
    }
  }

  void verificarMarcadoresEstaticosNosBaloes(WidgetTester t) {
    final Finder nosBaloes = find.descendant(
      of: find.byType(BalaoDeFala),
      matching: find.byType(MemoraAnimada),
    );
    for (final Element el in nosBaloes.evaluate()) {
      expect((el.widget as MemoraAnimada).reageAoToque, isFalse);
      expect(MediaQuery.disableAnimationsOf(el), isTrue);
    }
    expect(
      find.byType(MemoraAnimada).evaluate().length -
          nosBaloes.evaluate().length,
      1,
      reason: 'Fora dos balões, apenas a Memora da BarraSuperior pode animar.',
    );
  }

  group('US1 — Avatares em todos os estados de balão do chat', () {
    testWidgets(
      'convite, histórico, escrevendo e streaming mostram rostos estáticos nos balões enquanto só a BarraSuperior anima',
      (WidgetTester t) async {
        vestir(t, referencia);
        final _RepositorioControlado repo = _RepositorioControlado();
        final FotoDePerfilEmMemoria fotos = FotoDePerfilEmMemoria();
        final ControladorConversa c = ControladorConversa(
          repo,
          _ConversaEmMemoria(),
          aceite: AceiteEmMemoria(),
        );
        addTearDown(c.dispose);

        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaConversa(
              controlador: c,
              fotoDePerfil: fotos,
              idDaConta: 'conta-1',
              nomeDaPessoa: 'Maria Silva',
            ),
          ),
        );
        await avancar(t);

        // 1. Convite antes da primeira mensagem.
        final BalaoDeFala convite = t.widget<BalaoDeFala>(
          find.byKey(TelaConversa.chaveConvite),
        );
        expect(convite.comRosto, isTrue);
        expect(convite.rostoAnimado, isFalse);
        verificarMarcadoresEstaticosNosBaloes(t);

        // 2. Enviar pergunta → balão da pessoa + balão escrevendo da Memora.
        await t.enterText(
          find.byKey(TelaConversa.chaveCampo),
          'Como aumento a letra?',
        );
        await t.pump();
        await t.tap(find.byKey(TelaConversa.chaveEnviar));
        await t.pump();

        expect(
          find.text('• • •  ${BalaoDeFala.textoEscrevendo}'),
          findsOneWidget,
        );
        verificarMarcadoresEstaticosNosBaloes(t);
        for (final Element el in find.byType(BalaoDeFala).evaluate()) {
          final BalaoDeFala b = el.widget as BalaoDeFala;
          expect(b.comRosto, isTrue);
          expect(b.rostoAnimado, isFalse);
        }

        // 3. Trecho chegando em streaming → apenas a Memora da barra fala.
        repo.aoReceberTrecho!('Abra os Ajustes do seu celular.');
        await t.pump();
        await t.pump(const Duration(milliseconds: 120));

        final MemoraAnimada topoStreaming = t.widget<MemoraAnimada>(
          find.descendant(
            of: find.byType(BarraSuperior),
            matching: find.byType(MemoraAnimada),
          ),
        );
        expect(topoStreaming.falando, isTrue);
        verificarMarcadoresEstaticosNosBaloes(t);

        // 4. Resposta concluída e escrita finalizada.
        repo.respostaPendente!.complete(
          const AssistenteRespondeu('Abra os Ajustes do seu celular.'),
        );
        await t.pump();
        await esperarAEscrita(t);
        expect(t.takeException(), isNull);
        verificarMarcadoresEstaticosNosBaloes(t);
      },
    );
  });

  group('US2 — Sincronização fiel com Meu Perfil', () {
    testWidgets(
      'espelha foto própria em memória, todos os 4 avatares ilustrados, iniciais e silhueta sem letras sem chamadas extras de rede',
      (WidgetTester t) async {
        vestir(t, referencia);
        final _RepositorioControlado repo = _RepositorioControlado();
        final FotoDePerfilEmMemoria fotos = FotoDePerfilEmMemoria();
        final Uint8List jpeg = _criarJpegValido();
        await fotos.salvarFoto('conta-1', jpeg);

        final ControladorConversa c = ControladorConversa(
          repo,
          _ConversaEmMemoria(_historicoBase()),
          aceite: AceiteEmMemoria(),
        );
        addTearDown(c.dispose);

        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaConversa(
              controlador: c,
              fotoDePerfil: fotos,
              idDaConta: 'conta-1',
              nomeDaPessoa: 'Maria Silva',
            ),
          ),
        );
        await avancar(t);

        final Finder balaoPessoa = find.byWidgetPredicate(
          (Widget w) => w is BalaoDeFala && w.autor == AutorDoBalao.pessoa,
        );
        expect(balaoPessoa, findsOneWidget);

        // Foto própria carregada em RetratoDoPerfil(40 dp).
        final Finder retratoNoBalao = find.descendant(
          of: balaoPessoa,
          matching: find.byType(RetratoDoPerfil),
        );
        expect(retratoNoBalao, findsOneWidget);
        expect(
          t.widget<RetratoDoPerfil>(retratoNoBalao).tamanho,
          MemoraDimensoes.pisoDeIlustracao,
        );
        expect(
          find.descendant(of: balaoPessoa, matching: find.byType(Image)),
          findsOneWidget,
        );
        expect(
          t.getCenter(retratoNoBalao).dx,
          greaterThan(
            t
                .getCenter(
                  find.descendant(of: balaoPessoa, matching: find.text('Você')),
                )
                .dx,
          ),
        );

        // Atualização ao vivo para cada um dos 4 avatares ilustrados.
        for (final AvatarIlustrado avatar in AvatarIlustrado.values) {
          await fotos.salvarAvatar('conta-1', avatar);
          await avancar(t);

          final Finder desenho = find.descendant(
            of: balaoPessoa,
            matching: find.byType(DesenhoAvatarIlustrado),
          );
          expect(desenho, findsOneWidget);
          expect(
            t.widget<DesenhoAvatarIlustrado>(desenho).avatar,
            avatar,
          );
          verificarMarcadoresEstaticosNosBaloes(t);
        }

        // Voltar para foto própria ao vivo via fluxo reativo.
        await fotos.salvarFoto('conta-1', jpeg);
        await avancar(t);
        expect(
          find.descendant(of: balaoPessoa, matching: find.byType(Image)),
          findsOneWidget,
        );

        // Remoção ao vivo → volta ao padrão neutro com iniciais "MS".
        await fotos.apagar('conta-1');
        await avancar(t);
        expect(
          find.descendant(of: balaoPessoa, matching: find.text('MS')),
          findsOneWidget,
        );

        // Nenhuma chamada ao repositório remoto foi feita por ler/atualizar retrato.
        expect(repo.chamadasConversar, 0);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'iniciais sem letras exibem silhueta neutra e iniciais largas (WM a 150%) ajustam com FittedBox sem corte',
      (WidgetTester t) async {
        vestir(t, const Size(320, 568));
        final FotoDePerfilEmMemoria fotos = FotoDePerfilEmMemoria();

        // 1. Nome sem letras -> silhueta Icons.person_outline_rounded.
        final ControladorConversa c1 = ControladorConversa(
          _RepositorioControlado(),
          _ConversaEmMemoria(_historicoBase()),
          aceite: AceiteEmMemoria(),
        );
        addTearDown(c1.dispose);

        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaConversa(
              controlador: c1,
              fotoDePerfil: fotos,
              idDaConta: 'conta-num',
              nomeDaPessoa: '1234',
            ),
          ),
        );
        await avancar(t);

        final Finder balaoPessoa = find.byWidgetPredicate(
          (Widget w) => w is BalaoDeFala && w.autor == AutorDoBalao.pessoa,
        );
        expect(
          find.descendant(
            of: balaoPessoa,
            matching: find.byIcon(Icons.person_outline_rounded),
          ),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);

        await t.pumpWidget(const SizedBox());

        // 2. Iniciais largas "WM" a 150% em 40 dp usando FittedBox sem overflow.
        final ControladorConversa c2 = ControladorConversa(
          _RepositorioControlado(),
          _ConversaEmMemoria(_historicoBase()),
          aceite: AceiteEmMemoria(),
        );
        addTearDown(c2.dispose);

        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: Builder(
              builder: (BuildContext ctx) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(
                  textScaler: const TextScaler.linear(1.5),
                ),
                child: TelaConversa(
                  controlador: c2,
                  fotoDePerfil: fotos,
                  idDaConta: 'conta-wm',
                  nomeDaPessoa: 'Walter Magalhães',
                ),
              ),
            ),
          ),
        );
        await avancar(t);
        await irAoTopo(t);

        expect(
          find.descendant(of: balaoPessoa, matching: find.text('WM')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: balaoPessoa, matching: find.byType(FittedBox)),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'recua silenciosamente para padrão neutro em arquivo ausente ou falha de leitura local',
      (WidgetTester t) async {
        vestir(t, referencia);
        final ControladorConversa c1 = ControladorConversa(
          _RepositorioControlado(),
          _ConversaEmMemoria(_historicoBase()),
          aceite: AceiteEmMemoria(),
        );
        addTearDown(c1.dispose);

        final _ArmazenamentoArquivoInexistente arquivoAusente =
            _ArmazenamentoArquivoInexistente(
              retrato: FotoPropriaDePerfil(
                caminhoDoArquivo:
                    '${Directory.systemTemp.path}/memora_nao_existe_${DateTime.now().microsecondsSinceEpoch}.jpg',
                atualizadaEm: DateTime.utc(2026),
              ),
            );

        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaConversa(
              controlador: c1,
              fotoDePerfil: arquivoAusente,
              idDaConta: 'conta-1',
              nomeDaPessoa: 'Maria Silva',
            ),
          ),
        );
        await avancar(t);
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await avancar(t);
        await irAoTopo(t);

        final Finder balaoPessoa = find.byWidgetPredicate(
          (Widget w) => w is BalaoDeFala && w.autor == AutorDoBalao.pessoa,
        );
        expect(
          find.descendant(of: balaoPessoa, matching: find.text('MS')),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);

        await t.pumpWidget(const SizedBox());

        // Armazenamento que lança exceção em ler().
        final ControladorConversa c2 = ControladorConversa(
          _RepositorioControlado(),
          _ConversaEmMemoria(_historicoBase()),
          aceite: AceiteEmMemoria(),
        );
        addTearDown(c2.dispose);
        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaConversa(
              controlador: c2,
              fotoDePerfil: _ArmazenamentoArquivoInexistente(
                lancarErroAoLer: true,
              ),
              idDaConta: 'conta-1',
              nomeDaPessoa: 'Maria Silva',
            ),
          ),
        );
        await avancar(t);
        expect(
          find.descendant(of: balaoPessoa, matching: find.text('MS')),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'descarta retrato ao trocar de conta (didUpdateWidget) e ao chamar esquecerDoAparelho()',
      (WidgetTester t) async {
        vestir(t, referencia);
        final FotoDePerfilEmMemoria fotos = FotoDePerfilEmMemoria();
        await fotos.salvarFoto('conta-a', _criarJpegValido());
        await fotos.salvarAvatar('conta-b', AvatarIlustrado.memoraPensando);

        final ControladorConversa c = ControladorConversa(
          _RepositorioControlado(),
          _ConversaEmMemoria(_historicoBase()),
          aceite: AceiteEmMemoria(),
        );
        addTearDown(c.dispose);

        String contaAtiva = 'conta-a';
        String nomeAtivo = 'Dona Ana';
        late StateSetter atualizarPai;

        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: StatefulBuilder(
              builder: (BuildContext _, StateSetter setState) {
                atualizarPai = setState;
                return TelaConversa(
                  controlador: c,
                  fotoDePerfil: fotos,
                  idDaConta: contaAtiva,
                  nomeDaPessoa: nomeAtivo,
                );
              },
            ),
          ),
        );
        await avancar(t);

        final Finder balaoPessoa = find.byWidgetPredicate(
          (Widget w) => w is BalaoDeFala && w.autor == AutorDoBalao.pessoa,
        );
        expect(
          find.descendant(of: balaoPessoa, matching: find.byType(Image)),
          findsOneWidget,
        );

        // Troca de conta → foto da conta A some e entra avatar da conta B.
        atualizarPai(() {
          contaAtiva = 'conta-b';
          nomeAtivo = 'Seu Carlos';
        });
        await avancar(t);
        expect(
          find.descendant(of: balaoPessoa, matching: find.byType(Image)),
          findsNothing,
        );
        expect(
          find.descendant(
            of: balaoPessoa,
            matching: find.byType(DesenhoAvatarIlustrado),
          ),
          findsOneWidget,
        );

        // esquecerDoAparelho() → volta imediatamente às iniciais da conta B.
        await fotos.esquecerDoAparelho();
        await avancar(t);
        expect(
          find.descendant(
            of: balaoPessoa,
            matching: find.byType(DesenhoAvatarIlustrado),
          ),
          findsNothing,
        );
        expect(
          find.descendant(of: balaoPessoa, matching: find.text('SC')),
          findsOneWidget,
        );
      },
    );
  });

  group('US3 — Semântica TalkBack, temas, movimento reduzido e matriz 4×3', () {
    testWidgets(
      'avatares decorativos ficam silenciosos na árvore de Semantics',
      (WidgetTester t) async {
        vestir(t, referencia);
        final SemanticsHandle h = t.ensureSemantics();
        final FotoDePerfilEmMemoria fotos = FotoDePerfilEmMemoria();
        await fotos.salvarFoto('conta-1', _criarJpegValido());

        final ControladorConversa c = ControladorConversa(
          _RepositorioControlado(),
          _ConversaEmMemoria(_historicoBase()),
          aceite: AceiteEmMemoria(),
        );
        addTearDown(c.dispose);

        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: TelaConversa(
              controlador: c,
              fotoDePerfil: fotos,
              idDaConta: 'conta-1',
              nomeDaPessoa: 'Maria Silva',
            ),
          ),
        );
        await avancar(t);

        expect(find.bySemanticsLabel(RegExp(r'^Você disse: ')), findsOneWidget);
        expect(
          find.bySemanticsLabel(RegExp(r'^Memora disse: ')),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(TextosPerfil.semanticaFotoPropria),
          findsNothing,
        );
        expect(
          find.bySemanticsLabel(TextosPerfil.semanticaSemFoto),
          findsNothing,
        );
        expect(
          find.bySemanticsLabel(RegExp('Avatar de perfil escolhido')),
          findsNothing,
        );
        h.dispose();
      },
    );

    for (final MemoraTemaId temaId in MemoraTemaId.values) {
      testWidgets(
        'exibe avatares sem erros no tema ${temaId.name} e com movimento reduzido',
        (WidgetTester t) async {
          vestir(t, referencia);
          final FotoDePerfilEmMemoria fotos = FotoDePerfilEmMemoria();
          await fotos.salvarAvatar(
            'conta-1',
            AvatarIlustrado.memoraProtegendo,
          );
          final ControladorConversa c = ControladorConversa(
            _RepositorioControlado(),
            _ConversaEmMemoria(_historicoBase()),
            aceite: AceiteEmMemoria(),
          );
          addTearDown(c.dispose);

          await t.pumpWidget(
            MaterialApp(
              theme: TemasMemora.porId(temaId),
              home: Builder(
                builder: (BuildContext ctx) => MediaQuery(
                  data: MediaQuery.of(ctx).copyWith(disableAnimations: true),
                  child: TelaConversa(
                    controlador: c,
                    fotoDePerfil: fotos,
                    idDaConta: 'conta-1',
                    nomeDaPessoa: 'Maria Silva',
                  ),
                ),
              ),
            ),
          );
          await avancar(t);

          expect(t.takeException(), isNull);
          expect(find.byType(DesenhoAvatarIlustrado), findsOneWidget);
          verificarMarcadoresEstaticosNosBaloes(t);
        },
      );
    }

    for (final Size aparelho in aparelhos) {
      for (final double escala in escalas) {
        testWidgets(
          'matriz 4×3 com avatares ativos: ${nomeDo(aparelho)}, escala $escala',
          (WidgetTester t) async {
            vestir(t, aparelho);
            final FotoDePerfilEmMemoria fotos = FotoDePerfilEmMemoria();
            await fotos.salvarFoto('conta-1', _criarJpegValido());
            final ControladorConversa c = ControladorConversa(
              _RepositorioControlado(),
              _ConversaEmMemoria(_historicoBase()),
              aceite: AceiteEmMemoria(),
            );
            addTearDown(c.dispose);

            await t.pumpWidget(
              MaterialApp(
                theme: TemasMemora.claro,
                home: Builder(
                  builder: (BuildContext ctx) => MediaQuery(
                    data: MediaQuery.of(ctx).copyWith(
                      textScaler: TextScaler.linear(escala),
                      disableAnimations: true,
                    ),
                    child: TelaConversa(
                      controlador: c,
                      fotoDePerfil: fotos,
                      idDaConta: 'conta-1',
                      nomeDaPessoa: 'Walter Magalhães',
                    ),
                  ),
                ),
              ),
            );
            await avancar(t);
            await irAoTopo(t);

            expect(t.takeException(), isNull);
            final bool esperaRosto = escala < MemoraDimensoes.escalaTextoAlta;
            for (final Element el in find.byType(BalaoDeFala).evaluate()) {
              expect((el.widget as BalaoDeFala).comRosto, esperaRosto);
            }
            if (!esperaRosto) {
              expect(
                find.descendant(
                  of: find.byType(BalaoDeFala),
                  matching: find.byType(RetratoDoPerfil),
                ),
                findsNothing,
              );
              expect(
                find.descendant(
                  of: find.byType(BalaoDeFala),
                  matching: find.byType(MemoraPersonagem),
                ),
                findsNothing,
              );
            } else {
              expect(
                find.descendant(
                  of: find.byType(BalaoDeFala),
                  matching: find.byType(RetratoDoPerfil),
                ),
                findsOneWidget,
              );
            }

            expect(
              t.getSize(find.byType(ListView).first).height,
              greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo),
            );
            await exigirAlcancavel(
              t,
              find.byKey(TelaConversa.chaveEnviar),
              aparelho: aparelho,
              contexto: '${nomeDo(aparelho)} ($escala)',
            );
          },
        );
      }
    }
  });

  group('Phase 7 — Convergência (T016, T017)', () {
    for (final MemoraTemaId temaId in MemoraTemaId.values) {
      testWidgets(
        'T016: fallback errorBuilder sem iniciais preserva fundo cores.primaria e ícone sobrePrimaria no tema ${temaId.name}',
        (WidgetTester t) async {
          vestir(t, referencia);
          final ThemeData themeData = TemasMemora.porId(temaId);
          final MemoraCores cores = themeData.extension<MemoraTheme>()!.cores;
          final _ArmazenamentoArquivoInexistente arquivoAusente =
              _ArmazenamentoArquivoInexistente(
                retrato: FotoPropriaDePerfil(
                  caminhoDoArquivo:
                      '${Directory.systemTemp.path}/memora_sem_iniciais_${temaId.name}_${DateTime.now().microsecondsSinceEpoch}.jpg',
                  atualizadaEm: DateTime.utc(2026),
                ),
              );
          final ControladorConversa c = ControladorConversa(
            _RepositorioControlado(),
            _ConversaEmMemoria(_historicoBase()),
            aceite: AceiteEmMemoria(),
          );
          addTearDown(c.dispose);

          await t.pumpWidget(
            MaterialApp(
              theme: themeData,
              home: TelaConversa(
                controlador: c,
                fotoDePerfil: arquivoAusente,
                idDaConta: 'conta-sem-letras',
                nomeDaPessoa: '1234',
              ),
            ),
          );
          await avancar(t);
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await avancar(t);
          await irAoTopo(t);

          final Finder balaoPessoa = find.byWidgetPredicate(
            (Widget w) => w is BalaoDeFala && w.autor == AutorDoBalao.pessoa,
          );
          final Finder icone = find.descendant(
            of: balaoPessoa,
            matching: find.byIcon(Icons.person_outline_rounded),
          );
          expect(icone, findsOneWidget);
          expect(t.widget<Icon>(icone).color, cores.sobrePrimaria);
          expect(
            find.descendant(
              of: balaoPessoa,
              matching: find.byWidgetPredicate(
                (Widget w) => w is ColoredBox && w.color == cores.primaria,
              ),
            ),
            findsOneWidget,
          );
          expect(t.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'T017: oculta avatares exatamente em 175% (1.75) e exibe corretamente em tela superior 412x915',
      (WidgetTester t) async {
        const Size telaGrande = Size(412, 915);
        for (final double escala in <double>[
          1.0,
          1.5,
          MemoraDimensoes.escalaTextoAlta,
        ]) {
          vestir(t, telaGrande);
          final FotoDePerfilEmMemoria fotos = FotoDePerfilEmMemoria();
          await fotos.salvarFoto('conta-1', _criarJpegValido());
          final ControladorConversa c = ControladorConversa(
            _RepositorioControlado(),
            _ConversaEmMemoria(_historicoBase()),
            aceite: AceiteEmMemoria(),
          );
          addTearDown(c.dispose);

          await t.pumpWidget(
            MaterialApp(
              theme: TemasMemora.claro,
              home: Builder(
                builder: (BuildContext ctx) => MediaQuery(
                  data: MediaQuery.of(ctx).copyWith(
                    textScaler: TextScaler.linear(escala),
                    disableAnimations: true,
                  ),
                  child: TelaConversa(
                    controlador: c,
                    fotoDePerfil: fotos,
                    idDaConta: 'conta-1',
                    nomeDaPessoa: 'Walter Magalhães',
                  ),
                ),
              ),
            ),
          );
          await avancar(t);
          await irAoTopo(t);

          expect(t.takeException(), isNull);
          final bool esperaRosto = escala < MemoraDimensoes.escalaTextoAlta;
          for (final Element el in find.byType(BalaoDeFala).evaluate()) {
            expect((el.widget as BalaoDeFala).comRosto, esperaRosto);
          }
          expect(
            find.descendant(
              of: find.byType(BalaoDeFala),
              matching: find.byType(RetratoDoPerfil),
            ),
            esperaRosto ? findsOneWidget : findsNothing,
          );
          await exigirAlcancavel(
            t,
            find.byKey(TelaConversa.chaveEnviar),
            aparelho: telaGrande,
            contexto: '412x915 ($escala)',
          );
          await t.pumpWidget(const SizedBox());
        }

        // Confirma o limiar exato 1.75 também na menor tela (320x568).
        const Size telaPequena = Size(320, 568);
        vestir(t, telaPequena);
        final FotoDePerfilEmMemoria fotosMin = FotoDePerfilEmMemoria();
        await fotosMin.salvarFoto('conta-1', _criarJpegValido());
        final ControladorConversa cMin = ControladorConversa(
          _RepositorioControlado(),
          _ConversaEmMemoria(_historicoBase()),
          aceite: AceiteEmMemoria(),
        );
        addTearDown(cMin.dispose);

        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: Builder(
              builder: (BuildContext ctx) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(
                  textScaler: const TextScaler.linear(
                    MemoraDimensoes.escalaTextoAlta,
                  ),
                  disableAnimations: true,
                ),
                child: TelaConversa(
                  controlador: cMin,
                  fotoDePerfil: fotosMin,
                  idDaConta: 'conta-1',
                  nomeDaPessoa: 'Walter Magalhães',
                ),
              ),
            ),
          ),
        );
        await avancar(t);
        await irAoTopo(t);

        expect(t.takeException(), isNull);
        for (final Element el in find.byType(BalaoDeFala).evaluate()) {
          expect((el.widget as BalaoDeFala).comRosto, isFalse);
        }
        expect(
          find.descendant(
            of: find.byType(BalaoDeFala),
            matching: find.byType(RetratoDoPerfil),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(BalaoDeFala),
            matching: find.byType(MemoraPersonagem),
          ),
          findsNothing,
        );
        await exigirAlcancavel(
          t,
          find.byKey(TelaConversa.chaveEnviar),
          aparelho: telaPequena,
          contexto: '320x568 (1.75)',
        );
      },
    );

    testWidgets(
      'T017: descarta leitura assíncrona antiga fora de ordem pela guarda _versaoRetrato',
      (WidgetTester t) async {
        vestir(t, referencia);
        final _ArmazenamentoComCompleters fotos = _ArmazenamentoComCompleters();
        final ControladorConversa c = ControladorConversa(
          _RepositorioControlado(),
          _ConversaEmMemoria(_historicoBase()),
          aceite: AceiteEmMemoria(),
        );
        addTearDown(c.dispose);

        String contaAtiva = 'conta-a';
        String nomeAtivo = 'Dona Ana';
        late StateSetter atualizarPai;

        await t.pumpWidget(
          MaterialApp(
            theme: TemasMemora.claro,
            home: StatefulBuilder(
              builder: (BuildContext _, StateSetter setState) {
                atualizarPai = setState;
                return TelaConversa(
                  controlador: c,
                  fotoDePerfil: fotos,
                  idDaConta: contaAtiva,
                  nomeDaPessoa: nomeAtivo,
                );
              },
            ),
          ),
        );
        await t.pump();
        expect(fotos.leituras.containsKey('conta-a'), isTrue);

        // Troca de conta antes de 'conta-a' responder.
        atualizarPai(() {
          contaAtiva = 'conta-b';
          nomeAtivo = 'Seu Carlos';
        });
        await t.pump();
        expect(fotos.leituras.containsKey('conta-b'), isTrue);

        // 'conta-b' resolve primeiro.
        fotos.leituras['conta-b']!.complete(
          const AvatarIlustradoDePerfil(AvatarIlustrado.memoraPensando),
        );
        await avancar(t);
        await irAoTopo(t);

        final Finder balaoPessoa = find.byWidgetPredicate(
          (Widget w) => w is BalaoDeFala && w.autor == AutorDoBalao.pessoa,
        );
        Finder desenhoAtual = find.descendant(
          of: balaoPessoa,
          matching: find.byType(DesenhoAvatarIlustrado),
        );
        expect(desenhoAtual, findsOneWidget);
        expect(
          t.widget<DesenhoAvatarIlustrado>(desenhoAtual).avatar,
          AvatarIlustrado.memoraPensando,
        );

        // 'conta-a' responde tarde (fora de ordem) e deve ser descartada.
        fotos.leituras['conta-a']!.complete(
          const AvatarIlustradoDePerfil(AvatarIlustrado.memoraComemorando),
        );
        await avancar(t);
        await irAoTopo(t);

        desenhoAtual = find.descendant(
          of: balaoPessoa,
          matching: find.byType(DesenhoAvatarIlustrado),
        );
        expect(desenhoAtual, findsOneWidget);
        expect(
          t.widget<DesenhoAvatarIlustrado>(desenhoAtual).avatar,
          AvatarIlustrado.memoraPensando,
        );
        expect(t.takeException(), isNull);
      },
    );
  });
}

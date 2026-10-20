import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/componentes/guia/passo_ilustrado.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/aprendizado/data/progresso_de_aprendizado.dart';
import 'package:memora/features/aprendizado/domain/guia.dart';
import 'package:memora/features/aprendizado/presentation/tela_passo_a_passo.dart';
import 'package:memora/features/assistente/data/catalogo_guardado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/l10n/textos_guias.dart';
import 'package:memora/services/aplicativos/consulta_de_aplicativos.dart';

import '../../suporte/aparelhos.dart';
import '../../suporte/estados_de_tela.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Guia de teste com 3 passos
  final Guia guiaTeste = Guia(
    chave: 'tiktok',
    titulo: 'Aprender a usar o TikTok',
    capturadoEm: DateTime(2026, 10, 1),
    versaoCapturada: '34.0.0',
    passos: const <Passo>[
      Passo(
        captura: CapturaDoGuia.paraTeste('tiktok', 1),
        destaque: RegiaoRelativa(x: 0.1, y: 0.1, largura: 0.8, altura: 0.2),
        texto: 'Toque na barra de pesquisa no alto da tela.',
        descricaoDaCaptura: 'Tela inicial do TikTok com lupa de busca.',
      ),
      Passo(
        captura: CapturaDoGuia.paraTeste('tiktok', 2),
        destaque: RegiaoRelativa(x: 0.2, y: 0.4, largura: 0.6, altura: 0.3),
        texto: 'Digite o que você quer assistir e toque em buscar.',
        descricaoDaCaptura: 'Teclado aberto com campo de texto.',
      ),
      Passo(
        captura: CapturaDoGuia.paraTeste('tiktok', 3),
        destaque: RegiaoRelativa(x: 0.1, y: 0.2, largura: 0.8, altura: 0.6),
        texto: 'Toque no primeiro vídeo para começar a assistir.',
        descricaoDaCaptura: 'Lista de resultados com vídeos.',
      ),
    ],
  );

  const ServicoDoCatalogo servicoCotidiano = ServicoDoCatalogo(
    id: 's-1',
    chave: 'tiktok',
    nomeExibido: 'TikTok',
    descricaoCurta: 'Vídeos curtos e divertidos',
    categoria: CategoriaDoServico.cotidiano,
    memoraPodeAbrir: true,
  );

  const ServicoDoCatalogo servicoSensivel = ServicoDoCatalogo(
    id: 's-2',
    chave: 'gov-br',
    nomeExibido: 'Gov.br',
    descricaoCurta: 'Serviços do governo federal',
    categoria: CategoriaDoServico.sensivel,
    memoraPodeAbrir: false,
  );

  Widget montarApp(Widget tela, {ThemeData? tema}) {
    return MaterialApp(
      theme: tema ?? TemasMemora.claro,
      home: tela,
    );
  }

  group('US4 — Cenários 3 a 6 da especificação (T066, T067)', () {
    testWidgets(
      'Cenário 3: Mostra um passo por vez com indicador "Passo N de M", '
      'selo "Exemplo" e texto explicativo com o rosto da Memora',
      (WidgetTester t) async {
        await t.pumpWidget(
          montarApp(
            TelaPassoAPasso(
              guia: guiaTeste,
              servico: servicoCotidiano,
              origemDoCatalogo: OrigemDoCatalogo.servidor,
            ),
          ),
        );
        await t.pumpAndSettle();

        // 1. Indicador textual "Passo 1 de 3"
        expect(find.text(TextosGuias.passo(1, 3)), findsOneWidget);

        // 2. Selo "Exemplo" obrigatório (FR-028)
        expect(find.text(TextosGuias.exemplo), findsOneWidget);

        // 3. Texto do primeiro passo
        expect(
          find.text('Toque na barra de pesquisa no alto da tela.'),
          findsOneWidget,
        );

        // 4. Rosto da Memora acompanhando a instrução (FR-003)
        expect(find.byType(MemoraPersonagem), findsOneWidget);

        // 5. Botões de avançar ("Continuar") e ações obrigatórias
        expect(find.byKey(PassoIlustrado.chaveContinuar), findsOneWidget);
        expect(find.text(TextosGuias.continuar), findsOneWidget);
        expect(find.byKey(PassoIlustrado.chaveTelaDiferente), findsOneWidget);
        expect(find.byKey(PassoIlustrado.chaveSair), findsOneWidget);
      },
    );

    testWidgets(
      'Cenário 4: Posso rever o passo anterior com "Voltar" sem perder o lugar',
      (WidgetTester t) async {
        await t.pumpWidget(
          montarApp(
            TelaPassoAPasso(
              guia: guiaTeste,
              servico: servicoCotidiano,
              origemDoCatalogo: OrigemDoCatalogo.servidor,
            ),
          ),
        );
        await t.pumpAndSettle();

        // Avança para o passo 2
        await t.ensureVisible(find.byKey(PassoIlustrado.chaveContinuar));
        await t.tap(find.byKey(PassoIlustrado.chaveContinuar));
        await t.pumpAndSettle();

        expect(find.text(TextosGuias.passo(2, 3)), findsOneWidget);
        expect(
          find.text('Digite o que você quer assistir e toque em buscar.'),
          findsOneWidget,
        );

        // Toca em "Voltar"
        await t.ensureVisible(find.byKey(PassoIlustrado.chaveVoltar));
        await t.tap(find.byKey(PassoIlustrado.chaveVoltar));
        await t.pumpAndSettle();

        // Voltou para o passo 1
        expect(find.text(TextosGuias.passo(1, 3)), findsOneWidget);
        expect(
          find.text('Toque na barra de pesquisa no alto da tela.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Cenário 5: Último passo parabeniza, oferece "Voltar ao Hub" e '
      '"Peça à Memora para abrir" para cotidiano com servidor ativo (FR-027)',
      (WidgetTester t) async {
        String? pedidoRecebido;
        bool voltouAoHub = false;

        await t.pumpWidget(
          montarApp(
            TelaPassoAPasso(
              guia: guiaTeste,
              servico: servicoCotidiano,
              origemDoCatalogo: OrigemDoCatalogo.servidor,
              aoPedirParaAbrir: (String pedido) => pedidoRecebido = pedido,
              aoVoltarAoHub: () => voltouAoHub = true,
            ),
          ),
        );
        await t.pumpAndSettle();

        // Passo 1 -> 2
        await t.ensureVisible(find.byKey(PassoIlustrado.chaveContinuar));
        await t.tap(find.byKey(PassoIlustrado.chaveContinuar));
        await t.pumpAndSettle();

        // Passo 2 -> 3 (Último passo)
        await t.ensureVisible(find.byKey(PassoIlustrado.chaveContinuar));
        await t.tap(find.byKey(PassoIlustrado.chaveContinuar));
        await t.pumpAndSettle();

        expect(find.text(TextosGuias.passo(3, 3)), findsOneWidget);
        expect(find.text(TextosGuias.parabens), findsOneWidget);
        expect(find.text(TextosGuias.voltarAoHub), findsOneWidget);
        expect(find.text(TextosGuias.pecaParaAbrir), findsOneWidget);

        // Toca em "Peça à Memora para abrir"
        await t.ensureVisible(find.byKey(PassoIlustrado.chavePedirParaAbrir));
        await t.tap(find.byKey(PassoIlustrado.chavePedirParaAbrir));
        await t.pumpAndSettle();

        expect(pedidoRecebido, TextosGuias.pedidoParaAbrir('TikTok'));

        // Toca em "Voltar ao Hub"
        await t.ensureVisible(find.byKey(PassoIlustrado.chaveContinuar));
        await t.tap(find.byKey(PassoIlustrado.chaveContinuar));
        await t.pumpAndSettle();

        expect(voltouAoHub, isTrue);
      },
    );

    testWidgets(
      'Cenário 5b: Sem conexão ou com catálogo guardado offline, '
      '"Peça à Memora para abrir" NÃO aparece (FR-027)',
      (WidgetTester t) async {
        await t.pumpWidget(
          montarApp(
            TelaPassoAPasso(
              guia: guiaTeste,
              servico: servicoCotidiano,
              origemDoCatalogo: OrigemDoCatalogo.guardado,
              aoPedirParaAbrir: (_) {},
            ),
          ),
        );
        await t.pumpAndSettle();

        // Navega até o último passo
        await t.ensureVisible(find.byKey(PassoIlustrado.chaveContinuar));
        await t.tap(find.byKey(PassoIlustrado.chaveContinuar));
        await t.pumpAndSettle();
        await t.ensureVisible(find.byKey(PassoIlustrado.chaveContinuar));
        await t.tap(find.byKey(PassoIlustrado.chaveContinuar));
        await t.pumpAndSettle();

        // Voltar ao Hub está visível, mas "Peça à Memora para abrir" NÃO está presente
        expect(find.text(TextosGuias.voltarAoHub), findsOneWidget);
        expect(find.text(TextosGuias.pecaParaAbrir), findsNothing);
      },
    );

    testWidgets(
      'Cenário 5c: Para serviço sensível (Gov.br), '
      '"Peça à Memora para abrir" NUNCA aparece (FR-031)',
      (WidgetTester t) async {
        await t.pumpWidget(
          montarApp(
            TelaPassoAPasso(
              guia: guiaTeste,
              servico: servicoSensivel,
              origemDoCatalogo: OrigemDoCatalogo.servidor,
              aoPedirParaAbrir: (_) {},
            ),
          ),
        );
        await t.pumpAndSettle();

        // Navega até o último passo
        await t.ensureVisible(find.byKey(PassoIlustrado.chaveContinuar));
        await t.tap(find.byKey(PassoIlustrado.chaveContinuar));
        await t.pumpAndSettle();
        await t.ensureVisible(find.byKey(PassoIlustrado.chaveContinuar));
        await t.tap(find.byKey(PassoIlustrado.chaveContinuar));
        await t.pumpAndSettle();

        expect(find.text(TextosGuias.voltarAoHub), findsOneWidget);
        expect(find.text(TextosGuias.pecaParaAbrir), findsNothing);
      },
    );
  });

  group('Defesa contra Engenharia Social e Golpes (FR-026)', () {
    testWidgets(
      '"A minha tela está diferente" mostra PRIMEIRO o aviso de golpe offline '
      'e só depois oferece a conversa com a Memora',
      (WidgetTester t) async {
        bool conversou = false;

        await t.pumpWidget(
          montarApp(
            TelaPassoAPasso(
              guia: guiaTeste,
              servico: servicoCotidiano,
              aoConversarSobreDiferenca: () => conversou = true,
            ),
          ),
        );
        await t.pumpAndSettle();

        // Toca em "A minha tela está diferente"
        await t.ensureVisible(find.byKey(PassoIlustrado.chaveTelaDiferente));
        await t.tap(find.byKey(PassoIlustrado.chaveTelaDiferente));
        await t.pumpAndSettle();

        // O diálogo abre com o alerta preventivo
        expect(find.byKey(TelaPassoAPasso.chaveDialogoDiferente), findsOneWidget);
        expect(find.text(TextosGuias.avisoTelaDiferente), findsOneWidget);
        expect(find.text(TextosGuias.conversarSobreDiferenca), findsOneWidget);

        // Toca para conversar
        await t.tap(find.text(TextosGuias.conversarSobreDiferenca));
        await t.pumpAndSettle();

        expect(conversou, isTrue);
      },
    );

    testWidgets(
      '"Sair do passo a passo" sai a qualquer momento',
      (WidgetTester t) async {
        bool saiu = false;

        await t.pumpWidget(
          montarApp(
            TelaPassoAPasso(
              guia: guiaTeste,
              servico: servicoCotidiano,
              aoSair: () => saiu = true,
            ),
          ),
        );
        await t.pumpAndSettle();

        await t.ensureVisible(find.byKey(PassoIlustrado.chaveSair));
        await t.tap(find.byKey(PassoIlustrado.chaveSair));
        await t.pumpAndSettle();

        expect(saiu, isTrue);
      },
    );
  });

  group('Revisão #47 — Aplicativo não instalado', () {
    testWidgets(
      'Começa por um passo de baixar na loja oficial quando não está instalado',
      (WidgetTester t) async {
        final ConsultaDeAplicativosSimulada consulta =
            ConsultaDeAplicativosSimulada(
          instalados: const <String>{}, // Não instalado
        );

        await t.pumpWidget(
          montarApp(
            TelaPassoAPasso(
              guia: guiaTeste,
              servico: servicoCotidiano,
              pacoteAndroid: 'com.zhiliaoapp.musically',
              consultaAplicativos: consulta,
            ),
          ),
        );
        await t.pumpAndSettle();

        // O total de passos passa a ser 4 (1 de instalação + 3 do guia)
        expect(find.text(TextosGuias.passo(1, 4)), findsOneWidget);
        expect(
          find.text(TextosGuias.baixarNaLojaOficial('TikTok')),
          findsOneWidget,
        );
      },
    );
  });

  group('FR-029 — Sem overlay ou SYSTEM_ALERT_WINDOW no AndroidManifest.xml', () {
    test('AndroidManifest.xml NÃO contém permissão SYSTEM_ALERT_WINDOW', () {
      final File manifesto = File('android/app/src/main/AndroidManifest.xml');
      expect(manifesto.existsSync(), isTrue);

      final String conteudo = manifesto.readAsStringSync();
      expect(
        conteudo.contains('SYSTEM_ALERT_WINDOW'),
        isFalse,
        reason:
            'FR-029: O Memora nunca deve pedir permissão para desenhar por cima '
            'de outros aplicativos.',
      );
    });
  });

  group('FR-006 — Estados de tela (Carregando, Vazio, Erro)', () {
    testWidgets(
      'A tela atende a FR-006 nos estados de carregando, vazio e erro',
      (WidgetTester t) async {
        await exigirOsEstadosDaFr006(
          t,
          tela: 'TelaPassoAPasso',
          montar: (EstadoDaTela estado) => switch (estado) {
            EstadoDaTela.carregando => montarApp(
                TelaPassoAPasso(
                  guia: guiaTeste,
                  estadoDeTeste: 'carregando',
                ),
              ),
            EstadoDaTela.vazio => montarApp(
                TelaPassoAPasso(
                  guia: guiaTeste,
                  estadoDeTeste: 'vazio',
                ),
              ),
            EstadoDaTela.erro => montarApp(
                TelaPassoAPasso(
                  guia: guiaTeste,
                  estadoDeTeste: 'erro',
                ),
              ),
          },
        );
      },
    );
  });

  group('Matriz completa — FR-044 (Aparelhos × Escalas × Temas)', () {
    for (final Combinacao c in matriz()) {
      testWidgets(
        'TelaPassoAPasso não estoura em ${nomeDa(c)}',
        (WidgetTester t) async {
          vestir(t, c.aparelho);
          await t.pumpWidget(
            naCombinacao(
              c,
              TelaPassoAPasso(
                guia: guiaTeste,
                servico: servicoCotidiano,
                origemDoCatalogo: OrigemDoCatalogo.servidor,
              ),
            ),
          );
          await t.pumpAndSettle();

          expect(
            t.takeException(),
            isNull,
            reason: 'Estouro de layout em ${nomeDa(c)}',
          );

          // Verifica se o botão de continuar é alcançável
          await exigirAlcancavel(
            t,
            find.byKey(PassoIlustrado.chaveContinuar),
            aparelho: c.aparelho,
            contexto: 'TelaPassoAPasso em ${nomeDa(c)}',
          );
        },
      );
    }
  });
}

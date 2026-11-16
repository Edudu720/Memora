import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/aprendizado/domain/guia.dart';
import 'package:memora/features/aprendizado/presentation/tela_seletor_de_secao.dart';

import '../../suporte/aparelhos.dart';

void main() {
  final Guia guiaExemplo = Guia(
    chave: 'gov-br',
    titulo: 'Gov.br',
    capturadoEm: DateTime(2026, 11, 13),
    versaoCapturada: '3.6.0',
    secoes: const <SecaoDoGuia>[
      SecaoDoGuia(
        chave: 'entrar',
        titulo: 'Entrar na conta Gov.br',
        subtitulo: 'Usar CPF e senha para acessar seus dados.',
        icone: Icons.login,
        passos: <Passo>[
          Passo(
            captura: CapturaDoGuia.govBr1,
            destaque: RegiaoRelativa(x: 0.1, y: 0.1, largura: 0.8, altura: 0.1),
            texto: 'Toque no botão azul Entrar.',
            descricaoDaCaptura: 'Tela inicial com botão Entrar.',
          ),
          Passo(
            captura: CapturaDoGuia.govBr2,
            destaque: RegiaoRelativa(x: 0.1, y: 0.4, largura: 0.8, altura: 0.1),
            texto: 'Digite seu CPF.',
            descricaoDaCaptura: 'Tela pedindo CPF.',
          ),
          Passo(
            captura: CapturaDoGuia.govBr3,
            destaque: RegiaoRelativa(x: 0.1, y: 0.4, largura: 0.8, altura: 0.1),
            texto: 'Digite sua senha oficial.',
            descricaoDaCaptura: 'Tela de senha vazia.',
            temCampoDeSenha: true,
          ),
        ],
      ),
      SecaoDoGuia(
        chave: 'certidoes',
        titulo: 'Baixar Certidões',
        subtitulo: 'Emitir documentos e comprovantes oficiais.',
        icone: Icons.description_outlined,
        passos: <Passo>[
          Passo(
            captura: CapturaDoGuia.govBr9,
            destaque: RegiaoRelativa(x: 0.1, y: 0.2, largura: 0.8, altura: 0.1),
            texto: 'Toque em Baixar certidões.',
            descricaoDaCaptura: 'Menu com opção de certidões.',
          ),
          Passo(
            captura: CapturaDoGuia.govBr10,
            destaque: RegiaoRelativa(x: 0.1, y: 0.3, largura: 0.8, altura: 0.1),
            texto: 'Escolha a certidão desejada.',
            descricaoDaCaptura: 'Lista de certidões disponíveis.',
          ),
          Passo(
            captura: CapturaDoGuia.govBr11,
            destaque: RegiaoRelativa(x: 0.1, y: 0.3, largura: 0.8, altura: 0.1),
            texto: 'Pronto, você já sabe baixar certidões.',
            descricaoDaCaptura: 'Lista final de certidões.',
          ),
        ],
      ),
    ],
  );

  group('TelaSeletorDeSecao', () {
    testWidgets('exibe todas as seções e abre a seção escolhida', (
      WidgetTester tester,
    ) async {
      SecaoDoGuia? escolhida;
      bool voltou = false;
      bool conversou = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: TemasMemora.porId(MemoraTemaId.claro),
          home: TelaSeletorDeSecao(
            guia: guiaExemplo,
            aoEscolherSecao: (SecaoDoGuia s) => escolhida = s,
            aoVoltar: () => voltou = true,
            aoConversar: () => conversou = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Entrar na conta Gov.br'), findsOneWidget);
      expect(find.text('Baixar Certidões'), findsOneWidget);
      expect(find.text('3 passos'), findsNWidgets(2));

      await tester.tap(find.byKey(TelaSeletorDeSecao.chaveDaSecao('certidoes')));
      await tester.pumpAndSettle();
      expect(escolhida?.chave, 'certidoes');

      await tester.ensureVisible(
        find.byKey(TelaSeletorDeSecao.chaveConversar),
      );
      await tester.tap(find.byKey(TelaSeletorDeSecao.chaveConversar));
      await tester.pumpAndSettle();
      expect(conversou, isTrue);

      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();
      expect(voltou, isTrue);
    });

    for (final Combinacao c in matriz()) {
      testWidgets('não estoura na matriz ${nomeDo(c.aparelho)} ${c.escala} ${c.tema.name}', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = c.aparelho;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: c.aparelho,
              textScaler: TextScaler.linear(c.escala),
            ),
            child: MaterialApp(
              theme: TemasMemora.porId(c.tema),
              home: TelaSeletorDeSecao(
                guia: guiaExemplo,
                aoEscolherSecao: (_) {},
                aoVoltar: () {},
                aoConversar: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(TelaSeletorDeSecao.chaveLista), findsOneWidget);
      });
    }
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/casca/casca_interna.dart';
import 'package:memora/features/casca/raizes_provisorias.dart';
import 'package:memora/l10n/textos_casca.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/l10n/textos_assistente.dart';
import 'package:memora/l10n/textos_autenticacao.dart';

import 'fluxo_dentro_da_conta.dart';

/// A inatividade (FR-017) e as telas que o Hub abre por cima de si.
///
/// Conversa, catalogo, registro e aparencia sao rotas do Navigator, nao filhas
/// do Hub. Duas coisas dependiam disso e estavam erradas: a expiracao deixava
/// a conversa por cima do login (o celular esquecido na mesa mostrando a
/// conversa), e a atividade dentro da conversa nao era contada (quem conversa
/// por 28 minutos era expulso sem ter ficado parado).
void main() {
  late FluxoDentroDaConta fluxo;

  setUp(() => fluxo = FluxoDentroDaConta());

  Future<void> abrirConversa(WidgetTester t) async {
    await FluxoDentroDaConta.tocar(
      t,
      find.byKey(TelaHub.chaveDaPorta(TextosAssistente.portaConversa)),
    );
    await FluxoDentroDaConta.avancar(t, 8);
    expect(
      find.byKey(TelaConversa.chaveCampo),
      findsOneWidget,
      reason: 'o cenario pressupoe a conversa aberta',
    );
  }

  const Duration prazo = Duration(seconds: 3);
  const Duration aviso = Duration(seconds: 1);

  testWidgets('expirar por inatividade fecha a conversa e mostra o login', (
    WidgetTester t,
  ) async {
    await fluxo.montar(t, inatividade: prazo, aviso: aviso);
    await abrirConversa(t);

    await t.pump(const Duration(seconds: 2));
    await FluxoDentroDaConta.avancar(t);
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(seconds: 1));

    expect(
      find.byKey(TelaConversa.chaveCampo),
      findsNothing,
      reason: 'a conversa nao pode ficar por cima do login (FR-017)',
    );
    expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
    expect(fluxo.dado.apagamentos, 1);
    // Sem Timer pendente: o controlador da conversa foi descartado com a rota
    // (o teste falharia ao fim se sobrasse cronometro).
  });

  testWidgets('tocar dentro da conversa conta como atividade', (
    WidgetTester t,
  ) async {
    await fluxo.montar(t, inatividade: prazo, aviso: aviso);
    await abrirConversa(t);

    // 5 s de conversa, com um toque a cada segundo: bem mais que o prazo de 3 s.
    for (int i = 0; i < 5; i++) {
      await t.pump(const Duration(seconds: 1));
      await t.tap(find.byKey(TelaConversa.chaveCampo));
      await FluxoDentroDaConta.avancar(t);
    }

    expect(
      find.byKey(TelaConversa.chaveCampo),
      findsOneWidget,
      reason: 'quem esta conversando nao pode ser expulso',
    );
    expect(
      find.text(TextosAutenticacao.tituloAvisoInatividade),
      findsNothing,
      reason: 'e nem avisado de inatividade',
    );
    expect(fluxo.dado.apagamentos, 0);

    // Parou de tocar: agora sim, expira.
    await t.pump(const Duration(seconds: 2));
    await FluxoDentroDaConta.avancar(t);
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(seconds: 1));

    expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
    expect(fluxo.dado.apagamentos, 1);
  });

  /// T026 da feature 004: com a casca, cada destino tem a própria pilha.
  /// A expiração precisa fechar **as três**, e não só a que está à vista.
  group('Uma tela aberta em cada destino da casca', () {
    Future<void> irPara(WidgetTester t, String rotulo) async {
      await FluxoDentroDaConta.tocar(
        t,
        find.descendant(
          of: find.byKey(CascaInterna.chaveDaBarra),
          matching: find.text(rotulo),
        ),
      );
    }

    testWidgets('expirar fecha as três pilhas, e só o login fica', (
      WidgetTester t,
    ) async {
      await fluxo.montar(t, inatividade: prazo, aviso: aviso);

      // Início: a conversa aberta.
      await abrirConversa(t);
      // Ajustes: a aparência aberta.
      await irPara(t, TextosCasca.destinoConfiguracoes);
      await FluxoDentroDaConta.tocar(
        t,
        find.byKey(AjustesProvisorios.chaveAparencia),
      );
      await FluxoDentroDaConta.avancar(t, 8);
      expect(
        find.byType(TelaAparencia),
        findsOneWidget,
        reason: 'o cenário pressupõe a aparência aberta em Ajustes',
      );
      // Perfil: à vista na hora da expiração.
      await irPara(t, TextosCasca.destinoPerfil);

      await t.pump(const Duration(seconds: 2));
      await FluxoDentroDaConta.avancar(t);
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(milliseconds: 50));
      await t.pump(const Duration(seconds: 1));

      expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
      expect(
        find.byKey(TelaConversa.chaveCampo),
        findsNothing,
        reason: 'a conversa, aberta no Início, ficou para trás do login',
      );
      expect(
        find.byType(TelaAparencia),
        findsNothing,
        reason: 'a aparência, aberta em Ajustes, ficou para trás do login',
      );
      expect(find.byType(PerfilProvisorio), findsNothing);
      expect(find.byType(NavegacaoInferior), findsNothing);
      expect(fluxo.dado.apagamentos, 1);
    });

    testWidgets('tocar numa tela aberta em Ajustes conta como atividade', (
      WidgetTester t,
    ) async {
      await fluxo.montar(t, inatividade: prazo, aviso: aviso);
      await irPara(t, TextosCasca.destinoConfiguracoes);
      await FluxoDentroDaConta.tocar(
        t,
        find.byKey(AjustesProvisorios.chaveAparencia),
      );
      await FluxoDentroDaConta.avancar(t, 8);

      for (int i = 0; i < 5; i++) {
        await t.pump(const Duration(seconds: 1));
        await t.tap(find.byType(TelaAparencia), warnIfMissed: false);
        await FluxoDentroDaConta.avancar(t);
      }
      expect(
        find.byType(TelaAparencia),
        findsOneWidget,
        reason: 'quem está ajustando a aparência não pode ser expulso',
      );
      expect(fluxo.dado.apagamentos, 0);
    });
  });
}

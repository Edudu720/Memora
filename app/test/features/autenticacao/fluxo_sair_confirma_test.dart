import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/l10n/textos_autenticacao.dart';

import 'fluxo_dentro_da_conta.dart';

/// Sair pelo Hub pede confirmacao (FR-025), pelo fluxo real.
///
/// O portao antigo (`saida_limpa_armazenamento_test.dart`) testa a `TelaPerfil`
/// isolada, e o aplicativo nao a mostra desde que o Hub existe: o botao do Hub
/// estava ligado direto na saida, e a FR-025 nao era cumprida em lugar nenhum
/// que a pessoa alcancasse. Aqui o caminho e o que ela de fato percorre.
void main() {
  late FluxoDentroDaConta fluxo;

  setUp(() => fluxo = FluxoDentroDaConta());

  Future<void> tocarSair(WidgetTester t) =>
      FluxoDentroDaConta.tocar(t, find.byKey(TelaHub.chaveSair));

  testWidgets('tocar em sair pergunta, e ainda nao saiu', (WidgetTester t) async {
    await fluxo.montar(t);

    await tocarSair(t);

    expect(find.byKey(TelaHub.chaveConfirmacaoSaida), findsOneWidget);
    expect(find.text(TextosAutenticacao.perguntaSair), findsOneWidget);
    expect(find.text(TextosAutenticacao.avisoSair), findsOneWidget);
    expect(find.byKey(TelaHub.chaveSaudacao), findsOneWidget,
        reason: 'antes do segundo toque a pessoa continua dentro');
    expect(fluxo.dado.apagamentos, 0,
        reason: 'nada pode ser apagado antes de a pessoa confirmar');
    expect(fluxo.cofre.limpezas, 0);
  });

  testWidgets('"ficar" mantem a pessoa dentro e devolve o botao',
      (WidgetTester t) async {
    await fluxo.montar(t);
    await tocarSair(t);

    await FluxoDentroDaConta.tocar(
      t,
      find.text(TextosAutenticacao.botaoFicar),
    );

    expect(find.byKey(TelaHub.chaveConfirmacaoSaida), findsNothing);
    expect(find.byKey(TelaHub.chaveSair), findsOneWidget);
    expect(find.byKey(TelaHub.chaveSaudacao), findsOneWidget);
    expect(fluxo.dado.apagamentos, 0);
    expect(fluxo.cofre.limpezas, 0);
  });

  testWidgets('confirmar sai: vai ao login e a limpeza roda',
      (WidgetTester t) async {
    await fluxo.montar(t);
    await tocarSair(t);

    await FluxoDentroDaConta.tocar(
      t,
      find.text(TextosAutenticacao.botaoConfirmarSaida),
    );
    await FluxoDentroDaConta.avancar(t, 6);

    expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
    expect(find.byKey(TelaHub.chaveSaudacao), findsNothing);
    expect(fluxo.dado.apagamentos, 1);
    expect(fluxo.cofre.limpezas, greaterThan(0));
  });
}

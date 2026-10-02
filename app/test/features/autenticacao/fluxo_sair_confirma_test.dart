import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/casca/casca_interna.dart';
import 'package:memora/features/casca/raizes_provisorias.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/features/inicio/presentation/tela_inicio.dart';
import 'package:memora/l10n/textos_autenticacao.dart';

import 'fluxo_dentro_da_conta.dart';

/// Sair pede confirmacao (FR-025), pelo fluxo real, na saida de Ajustes.
///
/// O portao antigo (`saida_limpa_armazenamento_test.dart`) testa a `TelaPerfil`
/// isolada, e o aplicativo nao a mostra desde que o Hub existe: o botao do Hub
/// estava ligado direto na saida, e a FR-025 nao era cumprida em lugar nenhum
/// que a pessoa alcancasse. Aqui o caminho e o que ela de fato percorre.
///
/// ## Onde mora a saida (FR-019 da feature 004, T041)
///
/// Em Ajustes (e, a partir da US7, em Ajustes -> Conta). **Nao** no Inicio nem
/// no Hub: um botao de sair do lado das portas custava a sessao inteira a um
/// toque errado. O portao e o mesmo -- a pergunta antes de sair --, e o
/// primeiro teste abaixo e o que prova que a saida nao voltou a esses dois.
/// Qualquer texto que fale em sair, e nao so o rotulo de hoje: um "Sair" escrito
/// por cima da constante passaria por um teste que procurasse a constante.
final RegExp _sair = RegExp('sair', caseSensitive: false);

void main() {
  late FluxoDentroDaConta fluxo;

  setUp(() => fluxo = FluxoDentroDaConta());

  Future<void> tocarSair(WidgetTester t) => FluxoDentroDaConta.tocarEmSair(t);

  testWidgets('nem o Inicio nem o Hub tem "Sair"', (WidgetTester t) async {
    await fluxo.montar(t);

    // Dentro da propria tela: o `IndexedStack` mantem Ajustes na arvore, e uma
    // busca solta acharia o "Sair" de la e passaria sem provar nada.
    expect(
      find.descendant(
        of: find.byType(TelaInicio),
        matching: find.textContaining(_sair),
      ),
      findsNothing,
      reason: 'o Inicio nao pode oferecer a saida (FR-019)',
    );

    await FluxoDentroDaConta.irAoHub(t);
    expect(find.byType(TelaHub), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TelaHub),
        matching: find.textContaining(_sair),
      ),
      findsNothing,
      reason: 'o Hub nao pode oferecer a saida (FR-019)',
    );
  });

  testWidgets('tocar em sair pergunta, e ainda nao saiu', (WidgetTester t) async {
    await fluxo.montar(t);

    await tocarSair(t);

    expect(find.byKey(AjustesProvisorios.chaveConfirmacao), findsOneWidget);
    expect(find.text(TextosAutenticacao.perguntaSair), findsOneWidget);
    expect(find.text(TextosAutenticacao.avisoSair), findsOneWidget);
    expect(
      find.byKey(CascaInterna.chaveDaBarra),
      findsOneWidget,
      reason: 'antes do segundo toque a pessoa continua dentro',
    );
    expect(
      fluxo.dado.apagamentos,
      0,
      reason: 'nada pode ser apagado antes de a pessoa confirmar',
    );
    expect(fluxo.cofre.limpezas, 0);
  });

  testWidgets('"ficar" mantem a pessoa dentro e devolve o botao', (
    WidgetTester t,
  ) async {
    await fluxo.montar(t);
    await tocarSair(t);

    await FluxoDentroDaConta.tocar(
      t,
      find.text(TextosAutenticacao.botaoFicar),
    );

    expect(find.byKey(AjustesProvisorios.chaveConfirmacao), findsNothing);
    expect(find.byKey(AjustesProvisorios.chaveSair), findsOneWidget);
    expect(find.byKey(CascaInterna.chaveDaBarra), findsOneWidget);
    expect(fluxo.dado.apagamentos, 0);
    expect(fluxo.cofre.limpezas, 0);
  });

  testWidgets('confirmar sai: vai ao login e a limpeza roda', (
    WidgetTester t,
  ) async {
    await fluxo.montar(t);
    await tocarSair(t);

    await FluxoDentroDaConta.tocar(
      t,
      find.text(TextosAutenticacao.botaoConfirmarSaida),
    );
    await FluxoDentroDaConta.avancar(t, 6);

    expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
    expect(find.byKey(TelaInicio.chaveSaudacao), findsNothing);
    expect(fluxo.dado.apagamentos, 1);
    expect(fluxo.cofre.limpezas, greaterThan(0));
  });
}

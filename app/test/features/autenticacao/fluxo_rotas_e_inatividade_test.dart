import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/assistente/presentation/telas/tela_conversa.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_login.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';
import 'package:memora/l10n/textos_assistente.dart';

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
    expect(find.byKey(TelaConversa.chaveCampo), findsOneWidget,
        reason: 'o cenario pressupoe a conversa aberta');
  }

  const Duration prazo = Duration(seconds: 3);
  const Duration aviso = Duration(seconds: 1);

  testWidgets('expirar por inatividade fecha a conversa e mostra o login',
      (WidgetTester t) async {
    await fluxo.montar(t, inatividade: prazo, aviso: aviso);
    await abrirConversa(t);

    await t.pump(const Duration(seconds: 2));
    await FluxoDentroDaConta.avancar(t);
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(milliseconds: 50));
    await t.pump(const Duration(seconds: 1));

    expect(find.byKey(TelaConversa.chaveCampo), findsNothing,
        reason: 'a conversa nao pode ficar por cima do login (FR-017)');
    expect(find.byKey(TelaLogin.chaveEntrar), findsOneWidget);
    expect(fluxo.dado.apagamentos, 1);
    // Sem Timer pendente: o controlador da conversa foi descartado com a rota
    // (o teste falharia ao fim se sobrasse cronometro).
  });

}

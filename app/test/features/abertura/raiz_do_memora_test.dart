import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/abertura/presentation/abertura_memora.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_boas_vindas.dart';
import 'package:memora/main.dart';
import 'package:memora/services/ambiente/ambiente.dart';
import 'package:memora/services/ambiente/composicao.dart';
import 'package:memora/services/seguranca/limpeza_de_sessao.dart';
import 'package:memora/services/seguranca/sessao_perdida.dart';

import '../../suporte/aceite_em_memoria.dart';
import '../autenticacao/dubles_autenticacao.dart';
import '../autenticacao/fluxo_dentro_da_conta.dart';

/// A raiz do aplicativo (feature 013, T037): a abertura vem **antes** do
/// aplicativo, e o que ela carrega é o que o aplicativo usa.
///
/// O `main()` em si não é testado (ele só chama o `runApp`); o que importa é
/// a [RaizDoMemora], que ele monta com [carregarAplicativo].
void main() {
  AplicativoCarregado carregado() {
    final UltimoAcessoEmMemoria ultimoAcesso = UltimoAcessoEmMemoria();
    return AplicativoCarregado(
      controlador: ControladorAparencia(PreferenciaEmMemoria()),
      ultimoAcesso: ultimoAcesso,
      composicao: Composicao(
        ambiente: const Ambiente(urlBase: '', usaServidorReal: false),
        autenticacao: RepositorioAutenticacaoSimulado(demora: Duration.zero),
        assistente: RepositorioAssistenteSimulado(demora: Duration.zero),
        aceiteDoAviso: AceiteEmMemoria(),
        sessaoPerdida: SessaoPerdida(),
        limpeza: LimpezaDeSessao(
          cofre: CofreQueRegistra(),
          ultimoAcesso: ultimoAcesso,
        ),
      ),
    );
  }

  testWidgets('a primeira tela é a abertura, e o aplicativo só entra depois '
      'de carregar', (WidgetTester t) async {
    final Completer<AplicativoCarregado> carga =
        Completer<AplicativoCarregado>();
    await t.pumpWidget(RaizDoMemora(carregar: () => carga.future));
    await t.pump();

    expect(find.byType(AberturaMemora<AplicativoCarregado>), findsOneWidget);
    expect(find.byType(MemoraAnimada), findsOneWidget);
    expect(find.byKey(TelaBoasVindas.chaveComecar), findsNothing);

    // Passa tempo de sobra com o carregamento pendente: continua na abertura.
    await t.pump(const Duration(seconds: 3));
    expect(find.byKey(TelaBoasVindas.chaveComecar), findsNothing);

    carga.complete(carregado());
    for (int i = 0; i < 60; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(AberturaMemora<AplicativoCarregado>), findsNothing);
    expect(find.byType(AplicativoMemora), findsOneWidget);
    expect(find.byKey(TelaBoasVindas.chaveComecar), findsOneWidget);
  });

  testWidgets('o aplicativo recebe o que a abertura carregou', (
    WidgetTester t,
  ) async {
    final AplicativoCarregado c = carregado();
    await t.pumpWidget(RaizDoMemora(carregar: () async => c));
    for (int i = 0; i < 60; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    final AplicativoMemora app = t.widget<AplicativoMemora>(
      find.byType(AplicativoMemora),
    );
    expect(app.controlador, same(c.controlador));
    expect(app.ultimoAcesso, same(c.ultimoAcesso));
    expect(app.composicao, same(c.composicao));
  });
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import 'package:memora/features/autenticacao/presentation/telas/tela_boas_vindas.dart';
import 'package:memora/features/casca/raizes_provisorias.dart';
import 'package:memora/main.dart';
import 'package:memora/services/ambiente/ambiente.dart';
import 'package:memora/services/ambiente/composicao.dart';
import 'package:memora/services/seguranca/limpeza_de_sessao.dart';
import '../../suporte/aceite_em_memoria.dart';

import '../autenticacao/dubles_autenticacao.dart';
import '../autenticacao/fluxo_dentro_da_conta.dart';

/// V1 — a pessoa não vê o andaime (FR-007 e SC-009 da feature 004, T028).
///
/// Até a feature 004 o aplicativo abria numa casca de demonstração, com abas
/// "Entrar", "Componentes" e "Aparência". Era o diagnóstico 2 da spec: quem
/// abria o Memora via a vitrine do Design System antes de ver o produto.
void main() {
  test('a casca de demonstração não existe mais em lib/', () {
    expect(Directory('lib/demonstracao').existsSync(), isFalse);
    final List<String> quemCita = <String>[
      for (final FileSystemEntity f in Directory(
        'lib',
      ).listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            f.readAsStringSync().contains('CasaDemonstracao('))
          f.path,
    ];
    expect(quemCita, isEmpty, reason: 'alguém ainda monta a casca antiga');
  });

  testWidgets('o aplicativo abre nas boas-vindas, sem aba de desenvolvimento', (
    WidgetTester t,
  ) async {
    final UltimoAcessoEmMemoria ultimoAcesso = UltimoAcessoEmMemoria();
    final ControladorAparencia aparencia = ControladorAparencia(
      PreferenciaEmMemoria(),
    );
    await t.pumpWidget(
      AplicativoMemora(
        controlador: aparencia,
        ultimoAcesso: ultimoAcesso,
        composicao: Composicao(
          ambiente: const Ambiente(urlBase: '', usaServidorReal: false),
          autenticacao: RepositorioAutenticacaoSimulado(demora: Duration.zero),
          assistente: RepositorioAssistenteSimulado(demora: Duration.zero),
          aceiteDoAviso: AceiteEmMemoria(),
          limpeza: LimpezaDeSessao(
            cofre: CofreQueRegistra(),
            ultimoAcesso: ultimoAcesso,
          ),
        ),
      ),
    );
    await t.pump();

    expect(find.byKey(TelaBoasVindas.chaveComecar), findsOneWidget);
    for (final String aba in <String>['Componentes', 'Aparência', 'Entrar']) {
      expect(
        find.text(aba),
        findsNothing,
        reason: 'aba "$aba" da casca antiga',
      );
    }
    expect(
      find.byType(NavegacaoInferior),
      findsNothing,
      reason: 'fora da conta não há para onde a barra levar',
    );
  });

  testWidgets('sem galeria disponível, Ajustes não tem linha que leve a ela', (
    WidgetTester t,
  ) async {
    // Fora do kDebugMode, `GaleriaMemora.paraDesenvolvimento()` devolve nulo
    // (R9 da 002) e quem monta Ajustes passa nulo adiante. Aqui se prova o
    // outro lado do contrato: nulo é nenhuma linha, e não uma linha que leva
    // a uma recusa.
    await t.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: AjustesProvisorios(aoAbrirAparencia: () {}, aoSair: () async {}),
      ),
    );
    expect(find.byKey(AjustesProvisorios.chaveGaleria), findsNothing);
    expect(find.byKey(AjustesProvisorios.chaveAparencia), findsOneWidget);
  });

  testWidgets(
    'dentro da conta, a barra inferior aparece e o Início é o destino',
    (WidgetTester t) async {
      final FluxoDentroDaConta fluxo = FluxoDentroDaConta();
      await fluxo.montar(t);
      expect(find.byType(NavegacaoInferior), findsOneWidget);
      expect(find.byKey(NavegacaoInferior.chaveDoTraco(2)), findsOneWidget);
    },
  );
}

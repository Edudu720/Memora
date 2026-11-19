import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/hub/presentation/telas/tela_hub.dart';

import '../autenticacao/fluxo_dentro_da_conta.dart';

/// Cada porta do Hub tem um desenho só dela (revisão de 2026-11-18).
///
/// O "Dispositivo de Cuidado" e o "Localizador de Serviços" repetiam o prédio
/// dos "Serviços sociais": para quem se guia pelo desenho, três portas
/// pareciam a mesma. O Henrique pediu, ao testar o APK 1.0.6, o coração verde
/// do atalho de Cuidado do Início para o Cuidado e o alfinete do mapa para o
/// Localizador. O Hub é montado pelo fluxo de verdade, como o aplicativo o
/// mostra — testar a lista de portas sozinha não provaria a tela.
void main() {
  late FluxoDentroDaConta fluxo;

  setUp(() => fluxo = FluxoDentroDaConta());

  Future<List<CartaoDePorta>> portasDoHub(WidgetTester t) async {
    await fluxo.montar(t);
    await FluxoDentroDaConta.irAoHub(t);
    expect(find.byType(TelaHub), findsOneWidget);
    return t
        .widgetList<CartaoDePorta>(
          find.descendant(
            of: find.byType(TelaHub),
            matching: find.byType(CartaoDePorta),
          ),
        )
        .toList();
  }

  Finder doCartao(String nome, Finder alvo) => find.descendant(
    of: find.byWidgetPredicate(
      (Widget w) => w is CartaoDePorta && w.nome == nome,
    ),
    matching: alvo,
  );

  testWidgets('nenhuma porta repete o desenho de outra', (
    WidgetTester t,
  ) async {
    final List<CartaoDePorta> portas = await portasDoHub(t);
    expect(portas.length, greaterThanOrEqualTo(5));

    final Map<Ilustracao, List<String>> porDesenho =
        <Ilustracao, List<String>>{};
    for (final CartaoDePorta p in portas) {
      porDesenho.putIfAbsent(p.ilustracao, () => <String>[]).add(p.nome);
    }
    final Iterable<List<String>> repetidas = porDesenho.values.where(
      (List<String> nomes) => nomes.length > 1,
    );
    expect(
      repetidas,
      isEmpty,
      reason: 'portas com o mesmo desenho: $repetidas',
    );
  });

  testWidgets('Serviços sociais com o prédio, Cuidado com o coração verde e '
      'Localizador com o alfinete', (WidgetTester t) async {
    final List<CartaoDePorta> portas = await portasDoHub(t);
    Ilustracao desenhoDe(String nome) =>
        portas.firstWhere((CartaoDePorta p) => p.nome == nome).ilustracao;

    expect(desenhoDe('Serviços sociais'), Ilustracao.portaServicos);
    expect(desenhoDe('Dispositivo de Cuidado'), Ilustracao.portaCuidado);
    expect(desenhoDe('Localizador de Serviços'), Ilustracao.portaLocalizador);

    final MemoraCores cores = TemasMemora.claro.extension<MemoraTheme>()!.cores;

    // O coração verde: o mesmo par de cores do atalho de Cuidado do Início.
    final Icon coracao = t.widget<Icon>(
      doCartao('Dispositivo de Cuidado', find.byIcon(Icons.favorite_rounded)),
    );
    expect(coracao.color, cores.sucessoTexto);

    expect(
      doCartao('Localizador de Serviços', find.byIcon(Icons.pin_drop_rounded)),
      findsOneWidget,
    );
    expect(
      doCartao(
        'Localizador de Serviços',
        find.byIcon(Icons.account_balance_rounded),
      ),
      findsNothing,
    );
  });
}

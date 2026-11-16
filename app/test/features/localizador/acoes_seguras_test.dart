import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/localizador/domain/entidades/categoria_servico.dart';
import 'package:memora/features/localizador/domain/entidades/endereco_servico.dart';
import 'package:memora/features/localizador/domain/entidades/estabelecimento_servico.dart';
import 'package:memora/features/localizador/presentation/widgets/cartao_estabelecimento.dart';
import 'package:memora/features/localizador/presentation/widgets/dialogo_confirmacao_ligacao.dart';
import 'package:memora/features/localizador/presentation/widgets/dialogo_confirmacao_rota.dart';

void main() {
  Widget montar(Widget child) {
    return MaterialApp(
      theme: TemasMemora.claro,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  // Fixture explícita para testar a confirmação segura de discagem em 2 etapas
  // sem depender de números inventados em RepositorioLocalizadorSimulado (FR-008).
  final EstabelecimentoServico est = EstabelecimentoServico(
    id: 'fixture-cartao-seguro',
    nome: 'Unidade de Saúde Exemplo',
    categoria: CategoriaServico.saude,
    subtituloTipo: 'Posto de Saúde',
    endereco: EnderecoServico.deTexto(
      'Rua das Flores, 100 - Centro, São Paulo - SP',
      cidade: 'São Paulo',
      estado: 'SP',
    ),
    latitude: -23.5505,
    longitude: -46.6333,
    distanciaMetros: 300,
    distanciaFormatada: '300 metros',
    telefone: '(11) 0000-0000',
    horarioFuncionamento: 'Segunda a Sexta, das 08:00 às 17:00',
    horarioConfirmado: true,
    fonte: 'Fixture de Teste',
  );

  testWidgets('Tocar em Como chegar abre confirmação prévia em duas etapas', (WidgetTester tester) async {
    bool confirmou = false;

    await tester.pumpWidget(
      montar(
        Builder(
          builder: (BuildContext context) {
            return CartaoEstabelecimento(
              estabelecimento: est,
              aoPedirRota: () {
                DialogoConfirmacaoRota.mostrar(
                  context,
                  nomeDestino: est.nome,
                  enderecoFormatado: est.endereco.textoFormatado,
                  aoConfirmar: () => confirmou = true,
                );
              },
            );
          },
        ),
      ),
    );

    expect(find.byKey(CartaoEstabelecimento.chaveRota(est.id)), findsOneWidget);

    // Toca no botão de rota
    await tester.tap(find.byKey(CartaoEstabelecimento.chaveRota(est.id)));
    await tester.pumpAndSettle();

    // Diálogo de confirmação deve estar na tela
    expect(find.byKey(DialogoConfirmacaoRota.chaveDialogo), findsOneWidget);
    expect(find.text('Ver como chegar?'), findsOneWidget);
    expect(find.textContaining('Deseja abrir o aplicativo de mapas'), findsOneWidget);
    expect(confirmou, isFalse);

    // Confirma
    await tester.tap(find.text('Abrir mapa e rotas'));
    await tester.pumpAndSettle();

    expect(confirmou, isTrue);
    expect(find.byKey(DialogoConfirmacaoRota.chaveDialogo), findsNothing);
  });

  testWidgets('Tocar em Ligar abre confirmação prévia com telefone destacado', (WidgetTester tester) async {
    bool ligou = false;

    await tester.pumpWidget(
      montar(
        Builder(
          builder: (BuildContext context) {
            return CartaoEstabelecimento(
              estabelecimento: est,
              aoPedirRota: () {},
              aoPedirLigacao: () {
                DialogoConfirmacaoLigacao.mostrar(
                  context,
                  nomeDestino: est.nome,
                  telefone: est.telefone!,
                  aoConfirmar: () => ligou = true,
                );
              },
            );
          },
        ),
      ),
    );

    expect(find.byKey(CartaoEstabelecimento.chaveLigar(est.id)), findsOneWidget);

    await tester.tap(find.byKey(CartaoEstabelecimento.chaveLigar(est.id)));
    await tester.pumpAndSettle();

    expect(find.byKey(DialogoConfirmacaoLigacao.chaveDialogo), findsOneWidget);
    expect(find.text('Fazer ligação telefônica?'), findsOneWidget);
    expect(find.textContaining(est.telefone!), findsAtLeastNWidgets(1));
    expect(ligou, isFalse);

    // Confirma
    await tester.tap(find.text('Ligar para ${est.telefone}'));
    await tester.pumpAndSettle();

    expect(ligou, isTrue);
    expect(find.byKey(DialogoConfirmacaoLigacao.chaveDialogo), findsNothing);
  });
}

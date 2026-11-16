import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:memora/design_system/design_system.dart';
import 'package:memora/features/localizador/data/repositorios/repositorio_localizador_simulado.dart';
import 'package:memora/features/localizador/domain/entidades/categoria_servico.dart';
import 'package:memora/features/localizador/domain/entidades/endereco_servico.dart';
import 'package:memora/features/localizador/domain/entidades/estabelecimento_servico.dart';
import 'package:memora/features/localizador/domain/repositorios/repositorio_localizador.dart';
import 'package:memora/features/localizador/presentation/controladores/controlador_localizador.dart';
import 'package:memora/features/localizador/presentation/telas/tela_localizador.dart';
import 'package:memora/features/localizador/presentation/widgets/cartao_estabelecimento.dart';
import 'package:memora/features/localizador/presentation/widgets/dialogo_permissao_localizacao.dart';
import 'package:memora/features/localizador/presentation/widgets/mapa_servicos_acessivel.dart';
import 'package:memora/features/localizador/presentation/widgets/seletor_categorias_chips.dart';

class _RepositorioEspiaoLocalizador implements RepositorioLocalizador {
  int chamadas = 0;
  bool falhar = false;

  @override
  Future<ResultadoBuscaServicos> buscarServicos({
    String? consulta,
    CategoriaServico? categoria,
    double? latitude,
    double? longitude,
    String? regiaoManual,
    int? raioMetros,
  }) async {
    chamadas++;
    if (falhar) {
      throw Exception('Falha de rede simulada');
    }
    return RepositorioLocalizadorSimulado().buscarServicos(
      consulta: consulta,
      categoria: categoria,
      latitude: latitude,
      longitude: longitude,
      regiaoManual: regiaoManual,
      raioMetros: raioMetros,
    );
  }
}

void main() {
  Widget montar(ControladorLocalizador controlador, {Size tamanho = const Size(390, 844)}) {
    return MaterialApp(
      theme: TemasMemora.claro,
      home: MediaQuery(
        data: MediaQueryData(size: tamanho),
        child: SizedBox(
          width: tamanho.width,
          height: tamanho.height,
          child: TelaLocalizador(controlador: controlador),
        ),
      ),
    );
  }

  testWidgets('Tela do Localizador renderiza diálogo de permissão pedagógico na abertura', (WidgetTester tester) async {
    final RepositorioLocalizadorSimulado repo = RepositorioLocalizadorSimulado();
    final ControladorLocalizador c = ControladorLocalizador(repositorio: repo);
    addTearDown(c.dispose);

    await tester.pumpWidget(montar(c));
    await tester.pump();

    // Diálogo deve estar presente
    expect(find.byKey(DialogoPermissaoLocalizacao.chaveDialogo), findsOneWidget);
    expect(find.text('Autorizar localização?'), findsOneWidget);

    // Cancelar permissão e seguir
    await tester.tap(find.text('Não agora (pesquisar manual)'));
    await tester.pumpAndSettle();

    expect(find.byKey(DialogoPermissaoLocalizacao.chaveDialogo), findsNothing);
    expect(find.byKey(TelaLocalizador.chaveTela), findsOneWidget);
    expect(find.byKey(TelaLocalizador.chaveCampoBusca), findsOneWidget);
    expect(find.byKey(TelaLocalizador.chaveBotaoBuscar), findsOneWidget);
  });

  testWidgets('Filtra estabelecimentos ao tocar nos chips de categoria', (WidgetTester tester) async {
    final RepositorioLocalizadorSimulado repo = RepositorioLocalizadorSimulado();
    final ControladorLocalizador c = ControladorLocalizador(repositorio: repo);
    addTearDown(c.dispose);

    await tester.pumpWidget(montar(c));
    await tester.pumpAndSettle();

    // Fecha o diálogo inicial
    if (find.byKey(DialogoPermissaoLocalizacao.chaveDialogo).evaluate().isNotEmpty) {
      await tester.tap(find.text('Não agora (pesquisar manual)'));
      await tester.pumpAndSettle();
    }

    // Toca no chip de Emergência
    await tester.tap(find.byKey(SeletorCategoriasChips.chaveChip(CategoriaServico.emergencia)));
    await tester.pumpAndSettle();

    expect(c.categoriaAtiva, CategoriaServico.emergencia);
    expect(find.text('Corpo de Bombeiros de Americana'), findsOneWidget);
  });

  testWidgets('Alterna para modo mapa e exibe botões de zoom acessíveis', (WidgetTester tester) async {
    final RepositorioLocalizadorSimulado repo = RepositorioLocalizadorSimulado();
    final ControladorLocalizador c = ControladorLocalizador(repositorio: repo);
    addTearDown(c.dispose);

    await tester.pumpWidget(montar(c));
    await tester.pumpAndSettle();

    if (find.byKey(DialogoPermissaoLocalizacao.chaveDialogo).evaluate().isNotEmpty) {
      await tester.tap(find.text('Não agora (pesquisar manual)'));
      await tester.pumpAndSettle();
    }

    // Toca no botão de alternar mapa/lista
    await tester.tap(find.byKey(TelaLocalizador.chaveAlternarMapaLista));
    await tester.pumpAndSettle();

    expect(c.emModoMapa, isTrue);
    expect(find.byType(MapaServicosAcessivel), findsOneWidget);
    expect(find.byKey(MapaServicosAcessivel.chaveZoomMais), findsOneWidget);
    expect(find.byKey(MapaServicosAcessivel.chaveZoomMenos), findsOneWidget);
  });

  testWidgets('Renderiza sem overflow em tela compacta 320x568', (WidgetTester tester) async {
    final RepositorioLocalizadorSimulado repo = RepositorioLocalizadorSimulado();
    final ControladorLocalizador c = ControladorLocalizador(repositorio: repo);
    addTearDown(c.dispose);

    await tester.pumpWidget(montar(c, tamanho: const Size(320, 568)));
    await tester.pumpAndSettle();

    if (find.byKey(DialogoPermissaoLocalizacao.chaveDialogo).evaluate().isNotEmpty) {
      await tester.tap(find.text('Não agora (pesquisar manual)'));
      await tester.pumpAndSettle();
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('Não dispara busca prematura na abertura e exibe banner de demonstração em lista e mapa', (WidgetTester tester) async {
    final _RepositorioEspiaoLocalizador espiao = _RepositorioEspiaoLocalizador();
    final ControladorLocalizador c = ControladorLocalizador(repositorio: espiao);
    addTearDown(c.dispose);

    await tester.pumpWidget(montar(c));
    await tester.pump();

    expect(find.byKey(DialogoPermissaoLocalizacao.chaveDialogo), findsOneWidget);
    expect(espiao.chamadas, 0);

    // Cancela o diálogo inicial — ainda sem busca automática
    await tester.tap(find.text('Não agora (pesquisar manual)'));
    await tester.pumpAndSettle();
    expect(espiao.chamadas, 0);

    // Antes de buscar, modo mapa não usa coordenadas fixas de Americana - SP (-22.7388, -47.3325)
    await tester.tap(find.byKey(TelaLocalizador.chaveAlternarMapaLista));
    await tester.pumpAndSettle();
    final MapaServicosAcessivel mapaSemBusca = tester.widget<MapaServicosAcessivel>(
      find.byType(MapaServicosAcessivel),
    );
    expect(mapaSemBusca.centroInicial, isNot(const LatLng(-22.7388, -47.3325)));

    // Ao informar região manual no modo demonstração, exibe banner na interface (mapa e lista)
    c.definirRegiaoManual('Campinas, SP');
    await tester.pumpAndSettle();
    expect(find.byKey(TelaLocalizador.chaveBannerDemonstracao), findsOneWidget);

    await tester.tap(find.byKey(TelaLocalizador.chaveAlternarMapaLista));
    await tester.pumpAndSettle();
    expect(find.byKey(TelaLocalizador.chaveBannerDemonstracao), findsOneWidget);
  });

  testWidgets('Exibe estado honesto com Tentar novamente e oculta texto de lista vazia quando busca falha', (WidgetTester tester) async {
    final _RepositorioEspiaoLocalizador espiao = _RepositorioEspiaoLocalizador()..falhar = true;
    final ControladorLocalizador c = ControladorLocalizador(repositorio: espiao);
    addTearDown(c.dispose);

    await tester.pumpWidget(montar(c));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Não agora (pesquisar manual)'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(TelaLocalizador.chaveBotaoBuscar));
    await tester.pumpAndSettle();

    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.text('Nenhum estabelecimento encontrado nesta categoria na região selecionada.'), findsNothing);
    expect(find.byKey(TelaLocalizador.chaveBannerDemonstracao), findsNothing);
  });

  testWidgets('Exibe transparência explícita sobre OpenStreetMap no diálogo de localização e busca manual', (WidgetTester tester) async {
    final RepositorioLocalizadorSimulado repo = RepositorioLocalizadorSimulado();
    final ControladorLocalizador c = ControladorLocalizador(repositorio: repo);
    addTearDown(c.dispose);

    await tester.pumpWidget(montar(c));
    await tester.pump();

    expect(find.byKey(DialogoPermissaoLocalizacao.chaveDialogo), findsOneWidget);
    expect(find.textContaining('OpenStreetMap'), findsOneWidget);
    expect(find.textContaining('Não enviamos dados pessoais da sua conta'), findsOneWidget);

    await tester.tap(find.text('Não agora (pesquisar manual)'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(TelaLocalizador.chaveBotaoRegiaoManual));
    await tester.pumpAndSettle();

    expect(find.textContaining('OpenStreetMap'), findsOneWidget);
    expect(find.textContaining('sem enviar dados pessoais da sua conta'), findsOneWidget);
  });

  testWidgets('Controles com ícone possuem texto visível e alvos respeitam espaçamento mínimo de 8 dp', (WidgetTester tester) async {
    final RepositorioLocalizadorSimulado repo = RepositorioLocalizadorSimulado();
    final ControladorLocalizador c = ControladorLocalizador(repositorio: repo);
    addTearDown(c.dispose);

    await tester.pumpWidget(montar(c));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Não agora (pesquisar manual)'));
    await tester.pumpAndSettle();

    final Finder alternador = find.byKey(TelaLocalizador.chaveAlternarMapaLista);
    expect(find.descendant(of: alternador, matching: find.text('Mapa')), findsOneWidget);
    final Size tamanhoAlternador = tester.getSize(alternador);
    expect(tamanhoAlternador.width, greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo));
    expect(tamanhoAlternador.height, greaterThanOrEqualTo(MemoraDimensoes.alvoMinimo));

    await tester.tap(alternador);
    await tester.pumpAndSettle();

    expect(find.descendant(of: alternador, matching: find.text('Lista')), findsOneWidget);

    final Finder zoomMais = find.byKey(MapaServicosAcessivel.chaveZoomMais);
    final Finder zoomMenos = find.byKey(MapaServicosAcessivel.chaveZoomMenos);
    expect(find.descendant(of: zoomMais, matching: find.text('Mais')), findsOneWidget);
    expect(find.descendant(of: zoomMenos, matching: find.text('Menos')), findsOneWidget);
    expect(
      tester.getTopLeft(zoomMenos).dy - tester.getBottomLeft(zoomMais).dy,
      greaterThanOrEqualTo(MemoraDimensoes.separacaoAlvo),
    );
  });

  testWidgets('CartaoEstabelecimento empilhado mantém separação mínima de 8 dp entre Rota e Ligar', (WidgetTester tester) async {
    const EstabelecimentoServico fixture = EstabelecimentoServico(
      id: 'cartao-estreito',
      nome: 'UBS Centro',
      categoria: CategoriaServico.saude,
      subtituloTipo: 'Posto de Saúde',
      endereco: EnderecoServico(textoFormatado: 'Rua Principal, 10'),
      telefone: '(19) 0000-0000',
      fonte: 'OpenStreetMap',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: TemasMemora.claro,
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: CartaoEstabelecimento(
              estabelecimento: fixture,
              aoPedirRota: () {},
              aoPedirLigacao: () {},
            ),
          ),
        ),
      ),
    );

    final Rect rotaRect = tester.getRect(find.byKey(CartaoEstabelecimento.chaveRota('cartao-estreito')));
    final Rect ligarRect = tester.getRect(find.byKey(CartaoEstabelecimento.chaveLigar('cartao-estreito')));
    expect(ligarRect.top - rotaRect.bottom, greaterThanOrEqualTo(MemoraDimensoes.separacaoAlvo));
  });
}

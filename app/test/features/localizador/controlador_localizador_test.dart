import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/localizador/data/fontes/servico_geolocalizacao_dispositivo.dart';
import 'package:memora/features/localizador/data/repositorios/repositorio_localizador_simulado.dart';
import 'package:memora/features/localizador/domain/entidades/categoria_servico.dart';
import 'package:memora/features/localizador/domain/entidades/estabelecimento_servico.dart';
import 'package:memora/features/localizador/domain/repositorios/repositorio_localizador.dart';
import 'package:memora/features/localizador/presentation/controladores/controlador_localizador.dart';

class _RepositorioFalhandoNaSegundaBusca implements RepositorioLocalizador {
  int chamadas = 0;

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
    if (chamadas >= 2) {
      throw Exception('Serviço indisponível');
    }
    final ResultadoBuscaServicos base =
        await RepositorioLocalizadorSimulado().buscarServicos(
      consulta: consulta,
      categoria: categoria,
      latitude: latitude,
      longitude: longitude,
      regiaoManual: regiaoManual,
      raioMetros: raioMetros,
    );
    return ResultadoBuscaServicos(
      categoriaIdentificada: base.categoriaIdentificada,
      termoChave: base.termoChave,
      mensagemExplicativa: base.mensagemExplicativa,
      descricaoRegiao: 'São Paulo - SP',
      latitudeRegiao: -23.5505,
      longitudeRegiao: -46.6333,
      estabelecimentos: <EstabelecimentoServico>[
        base.estabelecimentos.first,
      ],
    );
  }
}

void main() {
  late RepositorioLocalizadorSimulado repo;
  late ControladorLocalizador controlador;

  setUp(() {
    repo = RepositorioLocalizadorSimulado();
    controlador = ControladorLocalizador(repositorio: repo);
  });

  tearDown(() {
    controlador.dispose();
  });

  test('Inicia com categoria Saúde e modo lista', () {
    expect(controlador.categoriaAtiva, CategoriaServico.saude);
    expect(controlador.modoExibicao, ModoExibicaoLocalizador.lista);
    expect(controlador.emModoMapa, isFalse);
  });

  test('Alterna entre modo lista e modo mapa', () {
    controlador.alternarModoExibicao();
    expect(controlador.modoExibicao, ModoExibicaoLocalizador.mapa);
    expect(controlador.emModoMapa, isTrue);

    controlador.alternarModoExibicao();
    expect(controlador.modoExibicao, ModoExibicaoLocalizador.lista);
  });

  test('Mudar categoria recarrega serviços correspondentes', () async {
    controlador.selecionarCategoria(CategoriaServico.emergencia);
    expect(controlador.categoriaAtiva, CategoriaServico.emergencia);

    await Future<void>.delayed(Duration.zero);
    expect(controlador.estabelecimentos, isNotEmpty);
    expect(controlador.estabelecimentos.every((e) => e.categoria == CategoriaServico.emergencia), isTrue);
  });

  test('Definir região manual desativa flag de permissão e busca com a região informada', () async {
    controlador.definirRegiaoManual('Jardim Ipiranga, Americana SP');
    expect(controlador.precisaExplicarPermissao, isFalse);
    expect(controlador.regiaoManual, 'Jardim Ipiranga, Americana SP');

    await Future<void>.delayed(Duration.zero);
    expect(controlador.estabelecimentos, isNotEmpty);
    expect(controlador.ehDemonstracao, isTrue);
  });

  test('Limpa estabelecimentos anteriores e expõe mensagemErro quando segunda busca falha', () async {
    final ControladorLocalizador ctrl = ControladorLocalizador(
      repositorio: _RepositorioFalhandoNaSegundaBusca(),
    );
    addTearDown(ctrl.dispose);

    ctrl.definirRegiaoManual('São Paulo, SP');
    await Future<void>.delayed(Duration.zero);
    expect(ctrl.estabelecimentos, hasLength(1));
    expect(ctrl.ehDemonstracao, isFalse);
    expect(ctrl.latitudeRegiao, closeTo(-23.5505, 0.0001));
    expect(ctrl.longitudeRegiao, closeTo(-46.6333, 0.0001));
    expect(ctrl.mensagemErro, isNull);

    await ctrl.buscar();

    expect(ctrl.estabelecimentos, isEmpty);
    expect(ctrl.mensagemErro, isNotNull);
  });

  test('Não dispara buscar() quando permissão ou GPS falham sem região manual', () async {
    final _RepositorioFalhandoNaSegundaBusca espiao = _RepositorioFalhandoNaSegundaBusca();
    final ControladorLocalizador ctrl = ControladorLocalizador(
      repositorio: espiao,
      servicoGeo: _ServicoGeoFalso(StatusPermissaoLocalizacao.negada),
    );
    addTearDown(ctrl.dispose);

    await ctrl.autorizarPermissaoEBuscar();

    expect(ctrl.precisaExplicarPermissao, isFalse);
    expect(ctrl.posicaoAtual, isNull);
    expect(espiao.chamadas, 0);
    expect(ctrl.mensagemErro, isNull);

    final ControladorLocalizador ctrlSemSinal = ControladorLocalizador(
      repositorio: espiao,
      servicoGeo: _ServicoGeoFalso(StatusPermissaoLocalizacao.concedida),
    );
    addTearDown(ctrlSemSinal.dispose);

    await ctrlSemSinal.autorizarPermissaoEBuscar();

    expect(ctrlSemSinal.precisaExplicarPermissao, isFalse);
    expect(ctrlSemSinal.posicaoAtual, isNull);
    expect(espiao.chamadas, 0);
    expect(ctrlSemSinal.mensagemErro, isNull);

    final ControladorLocalizador ctrlComSinal = ControladorLocalizador(
      repositorio: espiao,
      servicoGeo: _ServicoGeoFalso(
        StatusPermissaoLocalizacao.concedida,
        posicao: const PosicaoSimples(-25.4284, -49.2733),
      ),
    );
    addTearDown(ctrlComSinal.dispose);

    await ctrlComSinal.autorizarPermissaoEBuscar();

    expect(ctrlComSinal.precisaExplicarPermissao, isFalse);
    expect(ctrlComSinal.posicaoAtual?.latitude, -25.4284);
    expect(espiao.chamadas, 1);
  });

  test('Mudar para região manual após autorizar GPS envia regiaoManual sem coordenadas antigas do GPS', () async {
    double? ultimaLat;
    double? ultimaLon;
    String? ultimaRegiao;

    final ControladorLocalizador ctrl = ControladorLocalizador(
      repositorio: _RepositorioCapturador(
        aoBuscar: (double? lat, double? lon, String? regiao) {
          ultimaLat = lat;
          ultimaLon = lon;
          ultimaRegiao = regiao;
        },
      ),
      servicoGeo: _ServicoGeoFalso(
        StatusPermissaoLocalizacao.concedida,
        posicao: const PosicaoSimples(-23.5505, -46.6333),
      ),
    );
    addTearDown(ctrl.dispose);

    await ctrl.autorizarPermissaoEBuscar();
    expect(ultimaLat, -23.5505);
    expect(ultimaLon, -46.6333);
    expect(ultimaRegiao, isNull);

    ctrl.definirRegiaoManual('Americana, Centro');
    await Future<void>.delayed(Duration.zero);

    expect(ultimaLat, isNull);
    expect(ultimaLon, isNull);
    expect(ultimaRegiao, 'Americana, Centro');

    ctrl.selecionarCategoria(CategoriaServico.servicosPublicos);
    await Future<void>.delayed(Duration.zero);

    expect(ultimaLat, isNull);
    expect(ultimaLon, isNull);
    expect(ultimaRegiao, 'Americana, Centro');
    expect(ctrl.mensagemErro, isNull);
  });
}

class _RepositorioCapturador implements RepositorioLocalizador {
  final void Function(double? lat, double? lon, String? regiao) aoBuscar;

  _RepositorioCapturador({required this.aoBuscar});

  @override
  Future<ResultadoBuscaServicos> buscarServicos({
    String? consulta,
    CategoriaServico? categoria,
    double? latitude,
    double? longitude,
    String? regiaoManual,
    int? raioMetros,
  }) async {
    aoBuscar(latitude, longitude, regiaoManual);
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

class _ServicoGeoFalso extends ServicoGeolocalizacaoDispositivo {
  final StatusPermissaoLocalizacao status;
  final PosicaoSimples? posicao;

  _ServicoGeoFalso(this.status, {this.posicao});

  @override
  Future<StatusPermissaoLocalizacao> solicitarPermissao() async => status;

  @override
  Future<PosicaoSimples?> obterPosicaoAtual() async => posicao;
}

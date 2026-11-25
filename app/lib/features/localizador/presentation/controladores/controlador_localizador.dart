import 'package:flutter/material.dart';

import '../../data/fontes/servico_geolocalizacao_dispositivo.dart';
import '../../domain/entidades/categoria_servico.dart';
import '../../domain/entidades/estabelecimento_servico.dart';
import '../../domain/repositorios/repositorio_localizador.dart';

/// Modos de visualização disponíveis na tela do Localizador.
enum ModoExibicaoLocalizador {
  /// Exibe os serviços em cartões verticais fáceis de ler.
  lista,

  /// Exibe os estabelecimentos em mapa acessível com controles de zoom.
  mapa,
}

/// Gerencia o estado da tela do Localizador de Serviços (FR-001 a FR-015).
class ControladorLocalizador extends ChangeNotifier {
  /// Repositório responsável por consultar serviços próximos.
  final RepositorioLocalizador repositorio;

  /// Serviço que verifica permissão e obtém a localização do aparelho.
  final ServicoGeolocalizacaoDispositivo servicoGeo;

  /// Cria o controlador de estado do Localizador de Serviços.
  ControladorLocalizador({
    required this.repositorio,
    ServicoGeolocalizacaoDispositivo? servicoGeo,
  }) : servicoGeo = servicoGeo ?? ServicoGeolocalizacaoDispositivo();

  CategoriaServico _categoriaAtiva = CategoriaServico.saude;
  ModoExibicaoLocalizador _modoExibicao = ModoExibicaoLocalizador.lista;
  List<EstabelecimentoServico> _estabelecimentos = <EstabelecimentoServico>[];
  bool _carregando = false;
  String? _mensagemErro;
  String? _mensagemExplicativa;
  String _descricaoRegiao = 'Escolha sua região';
  double? _latitudeRegiao;
  double? _longitudeRegiao;
  bool _ehDemonstracao = false;
  String _consultaTexto = '';
  String _regiaoManual = '';
  PosicaoSimples? _posicaoAtual;
  bool _precisaExplicarPermissao = true;

  /// Categoria selecionada no filtro atual.
  CategoriaServico get categoriaAtiva => _categoriaAtiva;

  /// Modo de visualização ativo (lista ou mapa).
  ModoExibicaoLocalizador get modoExibicao => _modoExibicao;

  /// Estabelecimentos retornados na última busca bem-sucedida.
  List<EstabelecimentoServico> get estabelecimentos => _estabelecimentos;

  /// Indica se há uma consulta em andamento.
  bool get carregando => _carregando;

  /// Mensagem amigável da última falha de carregamento, quando houver.
  String? get mensagemErro => _mensagemErro;

  /// Texto explicativo retornado pelo servidor para contextualizar a busca.
  String? get mensagemExplicativa => _mensagemExplicativa;

  /// Descrição legível da região atualmente consultada.
  String get descricaoRegiao => _descricaoRegiao;

  /// Latitude central da região consultada, quando disponível.
  double? get latitudeRegiao => _latitudeRegiao;

  /// Longitude central da região consultada, quando disponível.
  double? get longitudeRegiao => _longitudeRegiao;

  /// Indica se os dados exibidos pertencem ao modo demonstração.
  bool get ehDemonstracao => _ehDemonstracao;

  /// Texto atualmente digitado no campo de busca livre.
  String get consultaTexto => _consultaTexto;

  /// Nome da cidade ou bairro informado manualmente pelo usuário.
  String get regiaoManual => _regiaoManual;

  /// Última posição obtida do dispositivo, quando autorizada.
  PosicaoSimples? get posicaoAtual => _posicaoAtual;

  /// Indica se o diálogo educativo de localização ainda deve ser exibido.
  bool get precisaExplicarPermissao => _precisaExplicarPermissao;

  /// Atalho booleano indicando se o modo mapa está ativo.
  bool get emModoMapa => _modoExibicao == ModoExibicaoLocalizador.mapa;

  /// Alterna entre a visualização em lista e a visualização em mapa.
  void alternarModoExibicao() {
    _modoExibicao = _modoExibicao == ModoExibicaoLocalizador.lista
        ? ModoExibicaoLocalizador.mapa
        : ModoExibicaoLocalizador.lista;
    notifyListeners();
  }

  /// Seleciona uma nova [cat] e executa uma nova busca imediata.
  void selecionarCategoria(CategoriaServico cat) {
    if (_categoriaAtiva == cat) return;
    _categoriaAtiva = cat;
    buscar();
  }

  /// Atualiza o rascunho de consulta livre digitado pela pessoa.
  void definirConsultaTexto(String texto) {
    _consultaTexto = texto;
  }

  /// Define a cidade ou bairro manual e dispara nova busca na região informada.
  void definirRegiaoManual(String regiao) {
    final String limpa = regiao.trim();
    if (limpa.isEmpty) return;
    _regiaoManual = limpa;
    _precisaExplicarPermissao = false;
    buscar();
  }

  /// Oculta o diálogo prévio de permissão sem iniciar busca automática.
  void cancelarPedidoPermissao() {
    _precisaExplicarPermissao = false;
    notifyListeners();
  }

  /// Solicita permissão do aparelho, lê o GPS se concedido e busca serviços.
  Future<void> autorizarPermissaoEBuscar() async {
    _precisaExplicarPermissao = false;
    final StatusPermissaoLocalizacao status = await servicoGeo.solicitarPermissao();
    if (status == StatusPermissaoLocalizacao.concedida) {
      _posicaoAtual = await servicoGeo.obterPosicaoAtual();
    }
    if (_posicaoAtual == null && _regiaoManual.trim().isEmpty) {
      notifyListeners();
      return;
    }
    await buscar();
  }

  /// Consulta os serviços no repositório considerando filtros, região ou GPS.
  Future<void> buscar() async {
    _carregando = true;
    _mensagemErro = null;
    notifyListeners();

    try {
      final bool usarRegiaoManual = _regiaoManual.trim().isNotEmpty;
      final double? latEnvio = usarRegiaoManual
          ? null
          : (_posicaoAtual?.latitude ?? _latitudeRegiao);
      final double? lonEnvio = usarRegiaoManual
          ? null
          : (_posicaoAtual?.longitude ?? _longitudeRegiao);

      final ResultadoBuscaServicos resultado = await repositorio.buscarServicos(
        consulta: _consultaTexto.trim().isNotEmpty ? _consultaTexto.trim() : null,
        categoria: _categoriaAtiva,
        latitude: latEnvio,
        longitude: lonEnvio,
        regiaoManual: usarRegiaoManual ? _regiaoManual.trim() : null,
      );

      _estabelecimentos = resultado.estabelecimentos;
      _descricaoRegiao = resultado.descricaoRegiao;
      _latitudeRegiao = resultado.latitudeRegiao;
      _longitudeRegiao = resultado.longitudeRegiao;
      _ehDemonstracao = resultado.ehDemonstracao;
      _mensagemExplicativa = resultado.mensagemExplicativa;
    } catch (e) {
      _estabelecimentos = <EstabelecimentoServico>[];
      _mensagemExplicativa = null;
      _ehDemonstracao = false;
      _mensagemErro = 'Não foi possível carregar os serviços da região. Tente novamente ou informe outra cidade.';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }
}

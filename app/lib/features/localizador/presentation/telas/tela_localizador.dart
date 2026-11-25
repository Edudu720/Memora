import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entidades/categoria_servico.dart';
import '../../domain/entidades/estabelecimento_servico.dart';
import '../controladores/controlador_localizador.dart';
import '../widgets/cartao_estabelecimento.dart';
import '../widgets/dialogo_confirmacao_ligacao.dart';
import '../widgets/dialogo_confirmacao_rota.dart';
import '../widgets/dialogo_permissao_localizacao.dart';
import '../widgets/mapa_servicos_acessivel.dart';
import '../widgets/seletor_categorias_chips.dart';

/// Tela principal do Localizador de Serviços Essenciais (Feature 009).
class TelaLocalizador extends StatefulWidget {
  /// Chave raiz da tela do localizador.
  static const Key chaveTela = Key('tela_localizador');

  /// Chave do campo de pesquisa textual por serviços.
  static const Key chaveCampoBusca = Key('localizador.campo_busca');

  /// Chave do botão para disparar a pesquisa textual.
  static const Key chaveBotaoBuscar = Key('localizador.botao_buscar');

  /// Chave do botão que alterna entre lista e mapa.
  static const Key chaveAlternarMapaLista = Key('localizador.alternar_mapa_lista');

  /// Chave do botão que abre o diálogo de cidade ou bairro manual.
  static const Key chaveBotaoRegiaoManual = Key('localizador.botao_regiao_manual');

  /// Chave da lista vertical de estabelecimentos encontrados.
  static const Key chaveListaServicos = Key('localizador.lista_servicos');

  /// Chave do aviso exibido quando os resultados vêm do modo demonstração.
  static const Key chaveBannerDemonstracao = Key('localizador.banner_demonstracao');

  /// Ponto neutro no território nacional usado enquanto nenhuma região foi definida.
  static const LatLng centroMapaPadraoSemRegiao = LatLng(-14.2350, -51.9253);

  /// Controlador que coordena permissões, região e resultados exibidos.
  final ControladorLocalizador controlador;

  /// Callback executado ao tocar no botão de voltar no cabeçalho.
  final VoidCallback? aoVoltar;

  /// Cria a tela do Localizador de Serviços Essenciais.
  const TelaLocalizador({
    required this.controlador,
    this.aoVoltar,
    super.key,
  });

  @override
  State<TelaLocalizador> createState() => _TelaLocalizadorState();
}

class _TelaLocalizadorState extends State<TelaLocalizador> {
  late final TextEditingController _campoBusca = TextEditingController(
    text: widget.controlador.consultaTexto,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.controlador.precisaExplicarPermissao) {
      widget.controlador.buscar();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controlador.precisaExplicarPermissao && mounted) {
        DialogoPermissaoLocalizacao.mostrar(
          context,
          aoConfirmar: () {
            Navigator.of(context).pop();
            widget.controlador.autorizarPermissaoEBuscar();
          },
          aoCancelar: () {
            Navigator.of(context).pop();
            widget.controlador.cancelarPedidoPermissao();
          },
        );
      }
    });
  }

  @override
  void dispose() {
    _campoBusca.dispose();
    super.dispose();
  }

  Future<void> _abrirMapaExterno(EstabelecimentoServico est) async {
    final Uri uri = Uri.parse(
      est.latitude != null && est.longitude != null
          ? 'geo:${est.latitude},${est.longitude}?q=${est.latitude},${est.longitude}(${Uri.encodeComponent(est.nome)})'
          : 'geo:0,0?q=${Uri.encodeComponent(est.endereco.textoFormatado)}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Future<void> _fazerLigacao(String telefone) async {
    final String limpo = telefone.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri uri = Uri.parse('tel:$limpo');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _fecharTeclado([BuildContext? contextoDialogo]) {
    if (contextoDialogo != null) {
      FocusScope.of(contextoDialogo).unfocus();
    }
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
      FocusManager.instance.primaryFocus?.unfocus();
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    });
  }

  void _solicitarRegiaoManual(BuildContext context) {
    final TextEditingController campoRegiao = TextEditingController(
      text: widget.controlador.regiaoManual,
    );

    void confirmarRegiao(BuildContext ctx) {
      final String texto = campoRegiao.text.trim();
      _fecharTeclado(ctx);
      Navigator.of(ctx).pop();
      if (texto.isNotEmpty) {
        widget.controlador.definirRegiaoManual(texto);
      }
    }

    DialogoMemora.mostrarConteudo<void>(
      context,
      construtor: (BuildContext ctx) {
        return AlertDialog(
          scrollable: true,
          title: const TextoMemora(
            'Informar cidade ou bairro',
            estilo: EstiloTexto.corpoForte,
            cabecalho: true,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const TextoMemora.apoio(
                'Digite o nome da sua cidade ou do seu bairro para pesquisar serviços próximos:',
              ),
              const SizedBox(height: MemoraEspacamento.xs),
              const TextoMemora.apoio(
                'A cidade ou bairro digitado é consultado só neste momento, '
                'nos serviços de mapa Geoapify e OpenStreetMap, sem enviar '
                'dados pessoais da sua conta nem salvar histórico.',
              ),
              const SizedBox(height: MemoraEspacamento.sm),
              CampoTexto(
                key: const Key('localizador.campo_regiao_manual'),
                rotulo: 'Cidade ou bairro',
                textoAjuda: 'Exemplo: Americana, Centro',
                controlador: campoRegiao,
                acaoTeclado: TextInputAction.search,
                aoSubmeter: (_) => confirmarRegiao(ctx),
              ),
            ],
          ),
          actionsOverflowButtonSpacing: MemoraEspacamento.sm,
          actions: <Widget>[
            BotaoSecundario(
              rotulo: 'Cancelar',
              aoTocar: () {
                _fecharTeclado(ctx);
                Navigator.of(ctx).pop();
              },
            ),
            BotaoPrimario(
              key: const Key('localizador.confirmar_regiao_manual'),
              rotulo: 'Atualizar região',
              aoTocar: () => confirmarRegiao(ctx),
            ),
          ],
        );
      },
    );
  }

  LatLng _centroMapa(ControladorLocalizador c) {
    if (c.regiaoManual.trim().isNotEmpty &&
        c.latitudeRegiao != null &&
        c.longitudeRegiao != null) {
      return LatLng(c.latitudeRegiao!, c.longitudeRegiao!);
    }
    if (c.posicaoAtual != null) {
      return LatLng(c.posicaoAtual!.latitude, c.posicaoAtual!.longitude);
    }
    if (c.latitudeRegiao != null && c.longitudeRegiao != null) {
      return LatLng(c.latitudeRegiao!, c.longitudeRegiao!);
    }
    for (final EstabelecimentoServico est in c.estabelecimentos) {
      if (est.temCoordenadas) {
        return LatLng(est.latitude!, est.longitude!);
      }
    }
    return TelaLocalizador.centroMapaPadraoSemRegiao;
  }

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;

    return ListenableBuilder(
      listenable: widget.controlador,
      builder: (BuildContext context, _) {
        final ControladorLocalizador c = widget.controlador;
        final String rotuloAlternancia = c.emModoMapa ? 'Lista' : 'Mapa';

        return Scaffold(
          key: TelaLocalizador.chaveTela,
          backgroundColor: cores.fundo,
          appBar: BarraSuperior(
            titulo: 'Localizador de Serviços',
            aoVoltar: widget.aoVoltar,
            acao: Semantics(
              button: true,
              label: c.emModoMapa ? 'Ver resultados em lista' : 'Ver resultados no mapa',
              child: ExcludeSemantics(
                child: Material(
                  color: cores.superficieSutil,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MemoraRaio.pilula),
                    side: BorderSide(
                      color: ehAltoContraste ? cores.borda : cores.bordaSutil,
                      width: ehAltoContraste
                          ? MemoraDimensoes.bordaEnfase
                          : MemoraDimensoes.espessuraBordaSutil,
                    ),
                  ),
                  child: InkWell(
                    key: TelaLocalizador.chaveAlternarMapaLista,
                    onTap: c.alternarModoExibicao,
                    borderRadius: BorderRadius.circular(MemoraRaio.pilula),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: MemoraDimensoes.alvoMinimo,
                        minHeight: MemoraDimensoes.alvoMinimo,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MemoraEspacamento.sm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              c.emModoMapa ? Icons.list_alt_rounded : Icons.map_rounded,
                              color: cores.primaria,
                              size: MemoraDimensoes.iconePadrao,
                            ),
                            const SizedBox(width: MemoraEspacamento.xs),
                            TextoMemora(
                              rotuloAlternancia,
                              estilo: EstiloTexto.apoio,
                              cor: cores.primaria,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Barra de busca acessível em linguagem natural
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MemoraEspacamento.md,
                    vertical: MemoraEspacamento.xs,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      CampoTexto(
                        key: TelaLocalizador.chaveCampoBusca,
                        rotulo: 'O que você precisa encontrar?',
                        textoAjuda: 'Ex: farmácia, vacina, médico, correios',
                        controlador: _campoBusca,
                        aoMudar: c.definirConsultaTexto,
                        acaoTeclado: TextInputAction.search,
                        aoSubmeter: (_) {
                          _fecharTeclado();
                          c.buscar();
                        },
                      ),
                      const SizedBox(height: MemoraEspacamento.sm),
                      BotaoPrimario(
                        key: TelaLocalizador.chaveBotaoBuscar,
                        rotulo: 'Buscar serviços',
                        icone: Icons.search_rounded,
                        aoTocar: () {
                          _fecharTeclado();
                          c.buscar();
                        },
                      ),
                    ],
                  ),
                ),

                // Faixa de região com atalho para busca manual
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MemoraEspacamento.md),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.pin_drop_rounded,
                        size: MemoraDimensoes.iconePequeno,
                        color: cores.primaria,
                      ),
                      const SizedBox(width: MemoraEspacamento.xs),
                      Expanded(
                        child: TextoMemora.apoio(
                          'Região: ${c.descricaoRegiao}',
                        ),
                      ),
                      BotaoTerciario(
                        key: TelaLocalizador.chaveBotaoRegiaoManual,
                        rotulo: 'Mudar região',
                        aoTocar: () {
                          _fecharTeclado();
                          _solicitarRegiaoManual(context);
                        },
                      ),
                    ],
                  ),
                ),

                // Filtro em pílulas de categorias essenciais
                SeletorCategoriasChips(
                  categoriaSelecionada: c.categoriaAtiva,
                  aoSelecionar: (CategoriaServico cat) {
                    _fecharTeclado();
                    c.selecionarCategoria(cat);
                  },
                ),

                // Feedback explicativo ou erro
                if (c.mensagemExplicativa != null) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MemoraEspacamento.md,
                      vertical: MemoraEspacamento.xs,
                    ),
                    child: TextoMemora.apoio(
                      c.mensagemExplicativa!,
                    ),
                  ),
                ],

                if (c.ehDemonstracao) ...<Widget>[
                  Padding(
                    key: TelaLocalizador.chaveBannerDemonstracao,
                    padding: const EdgeInsets.symmetric(
                      horizontal: MemoraEspacamento.md,
                      vertical: MemoraEspacamento.xs,
                    ),
                    child: Cartao(
                      comBorda: true,
                      padding: const EdgeInsets.all(MemoraEspacamento.sm),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          BadgeDeStatus(
                            rotulo: 'Demonstração',
                            tom: TomBadgeStatus.atencao,
                          ),
                          SizedBox(width: MemoraEspacamento.sm),
                          Expanded(
                            child: TextoMemora.apoio(
                              'Exemplos ilustrativos sem consulta em tempo real. '
                              'Ligações telefônicas ficam desativadas neste modo.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Corpo principal: carregamento, erro honesto, mapa ou lista
                Expanded(
                  child: c.carregando
                      ? const Center(
                          child: Carregando(
                            mensagem: 'Buscando serviços próximos...',
                          ),
                        )
                      : c.mensagemErro != null
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.all(MemoraEspacamento.md),
                              child: MensagemErro(
                                mensagem: c.mensagemErro!,
                                rotuloTentarNovamente: 'Tentar novamente',
                                aoTentarNovamente: c.buscar,
                              ),
                            )
                          : c.emModoMapa
                              ? MapaServicosAcessivel(
                                  estabelecimentos: c.estabelecimentos,
                                  centroInicial: _centroMapa(c),
                                  aoSelecionar: (EstabelecimentoServico est) {
                                    DialogoConfirmacaoRota.mostrar(
                                      context,
                                      nomeDestino: est.nome,
                                      enderecoFormatado: est.endereco.textoFormatado,
                                      aoConfirmar: () => _abrirMapaExterno(est),
                                    );
                                  },
                                )
                              : c.estabelecimentos.isEmpty
                                  ? Center(
                                      child: SingleChildScrollView(
                                        child: EstadoVazio(
                                          titulo: c.regiaoManual.isEmpty &&
                                                  c.posicaoAtual == null
                                              ? 'Escolha uma região'
                                              : 'Nenhum lugar encontrado',
                                          explicacao: c.regiaoManual.isEmpty &&
                                                  c.posicaoAtual == null
                                              ? 'Toque em "Mudar região" ou permita a localização para buscar serviços próximos.'
                                              : 'Nenhum estabelecimento encontrado nesta categoria na região selecionada.',
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                  key: TelaLocalizador.chaveListaServicos,
                                  padding: const EdgeInsets.all(MemoraEspacamento.md),
                                  itemCount: c.estabelecimentos.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: MemoraEspacamento.md),
                                  itemBuilder: (BuildContext ctx, int i) {
                                    final EstabelecimentoServico est =
                                        c.estabelecimentos[i];
                                    return CartaoEstabelecimento(
                                      estabelecimento: est,
                                      aoPedirRota: () {
                                        DialogoConfirmacaoRota.mostrar(
                                          context,
                                          nomeDestino: est.nome,
                                          enderecoFormatado:
                                              est.endereco.textoFormatado,
                                          aoConfirmar: () =>
                                              _abrirMapaExterno(est),
                                        );
                                      },
                                      aoPedirLigacao: est.temTelefone
                                          ? () {
                                              DialogoConfirmacaoLigacao.mostrar(
                                                context,
                                                nomeDestino: est.nome,
                                                telefone: est.telefone!,
                                                aoConfirmar: () =>
                                                    _fazerLigacao(est.telefone!),
                                              );
                                            }
                                          : null,
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

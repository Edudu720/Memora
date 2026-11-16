import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/textos_guias.dart';
import '../../../services/aplicativos/consulta_de_aplicativos.dart';
import '../../assistente/data/catalogo_guardado.dart';
import '../../assistente/domain/assistente.dart';
import '../data/progresso_de_aprendizado.dart';
import '../domain/guia.dart';

/// A tela que guia a pessoa passo a passo por um aplicativo ou serviço (`T054`, `T066`, `US4`).
///
/// Integra [CabecalhoDeTela], [PassoIlustrado] protagonista com tipografia
/// editorial e barra fixa inferior em `cores.superficieBarra` com ações rápidas
/// `"Anterior"` e `"Próximo"`.
///
/// ## Princípios aplicados
///
/// 1. **Ensina dentro do Memora**: a explicação acontece inteira aqui, com capturas
///    marcadas como "Exemplo" e nunca pedindo `SYSTEM_ALERT_WINDOW` (FR-028, FR-029).
/// 2. **Acolhimento com a Memora**: o rosto da Memora acompanha a instrução de
///    cada passo (FR-003), parabenizando na última etapa.
/// 3. **Defesa contra engenharia social**: o botão "A minha tela está diferente"
///    alerta **primeiro, offline e no próprio guia**, que telas divergentes pedindo
///    senhas ou códigos podem ser tentativa de golpe (FR-026).
/// 4. **Sem atalho para abrir**: a oferta "Peça à Memora para abrir" só surge para
///    aplicativos cotidianos, quando o catálogo veio do servidor com conexão ativa
///    (FR-027), e leva à conversa — o guia **nunca abre nada diretamente**.
class TelaPassoAPasso extends StatefulWidget {
  /// Chave do diálogo de tela diferente.
  static const Key chaveDialogoDiferente = Key('passo.dialogo_diferente');

  /// Chave do botão no diálogo que vai para a conversa.
  static const Key chaveConversarSobreDiferenca =
      Key('passo.conversar_diferenca');

  /// O guia a ser percorrido.
  final Guia guia;

  /// A seção que a pessoa escolheu, nos guias extensos (FR-028d). Com ela, a
  /// tela percorre só os passos da seção.
  final SecaoDoGuia? secao;

  /// Os dados do catálogo correspondentes ao serviço (se houver).
  final ServicoDoCatalogo? servico;

  /// Nome do pacote Android para verificar se o app está instalado.
  final String? pacoteAndroid;

  /// A consulta para verificar se o aplicativo está instalado (revisão #47).
  final ConsultaDeAplicativos? consultaAplicativos;

  /// De onde veio o catálogo (servidor ou guardado offline).
  final OrigemDoCatalogo? origemDoCatalogo;

  /// Repositório da assistente, usado para conferir a origem se não fornecida.
  final RepositorioAssistente? repositorioAssistente;

  /// Armazenamento do progresso local no aparelho (`FR-042a/b`).
  final ProgressoDeAprendizado? progresso;

  /// Identificador da conta conectada.
  final String? idDaConta;

  /// Chamado ao tocar em "Voltar" na primeira etapa ou no cabeçalho.
  final VoidCallback? aoVoltar;

  /// Chamado ao tocar em "Voltar ao Hub" na etapa de parabéns.
  final VoidCallback? aoVoltarAoHub;

  /// Chamado ao tocar em "Sair do passo a passo" (`FR-026`).
  final VoidCallback? aoSair;

  /// Chamado ao tocar em "Peça à Memora para abrir" (`FR-027`).
  final void Function(String pedido)? aoPedirParaAbrir;

  /// Chamado para ir à conversa ao relatar tela diferente.
  final VoidCallback? aoConversarSobreDiferenca;

  /// Chamado ao tocar em "Ficou com alguma dúvida? Pode perguntar" no último passo.
  final void Function(String duvida)? aoTirarDuvida;

  /// Estado inicial fixado para testes de estado (`FR-006`).
  final String? estadoDeTeste;

  /// Cria a tela de passo a passo.
  const TelaPassoAPasso({
    required this.guia,
    this.secao,
    this.servico,
    this.pacoteAndroid,
    this.consultaAplicativos,
    this.origemDoCatalogo,
    this.repositorioAssistente,
    this.progresso,
    this.idDaConta,
    this.aoVoltar,
    this.aoVoltarAoHub,
    this.aoSair,
    this.aoPedirParaAbrir,
    this.aoConversarSobreDiferenca,
    this.aoTirarDuvida,
    this.estadoDeTeste,
    super.key,
  });

  @override
  State<TelaPassoAPasso> createState() => _TelaPassoAPassoState();
}

class _TelaPassoAPassoState extends State<TelaPassoAPasso> {
  int _posicao = 1; // 1-based index
  bool _inicializando = true;
  bool _descartado = false;
  OrigemDoCatalogo? _origem;
  List<Passo> _passos = <Passo>[];

  @override
  void initState() {
    super.initState();
    _origem = widget.origemDoCatalogo;
    _prepararPassos();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }

  Future<void> _prepararPassos() async {
    // 1. Determina a origem do catálogo se não fornecida
    if (_origem == null && widget.repositorioAssistente != null) {
      if (widget.repositorioAssistente is CatalogoGuardado) {
        try {
          final CatalogoComOrigem comOrigem =
              await (widget.repositorioAssistente as CatalogoGuardado)
                  .catalogoComOrigem();
          _origem = comOrigem.origem;
        } catch (_) {
          _origem = OrigemDoCatalogo.guardado;
        }
      } else {
        _origem = OrigemDoCatalogo.servidor;
      }
    }

    // 2. Se o aplicativo não estiver instalado, adiciona o passo de baixar na loja oficial (revisão #47)
    bool precisaPassoInstalar = false;
    final ConsultaDeAplicativos? consulta = widget.consultaAplicativos;
    final String? pacote = widget.pacoteAndroid;
    if (consulta != null && pacote != null && pacote.trim().isNotEmpty) {
      try {
        final bool instalado = await consulta.estaInstalado(pacote);
        if (!instalado) {
          precisaPassoInstalar = true;
        }
      } catch (_) {
        precisaPassoInstalar = false;
      }
    }

    final List<Passo> lista = <Passo>[];
    if (precisaPassoInstalar) {
      lista.add(
        Passo(
          captura: CapturaDoGuia.lojaOficial,
          destaque: const RegiaoRelativa(
            x: 0.05,
            y: 0.05,
            largura: 0.9,
            altura: 0.9,
          ),
          texto: TextosGuias.baixarNaLojaOficial(
            widget.servico?.nomeExibido ?? widget.guia.titulo,
          ),
          descricaoDaCaptura: TextosGuias.descricaoBaixarNaLojaOficial,
        ),
      );
    }
    lista.addAll(widget.secao?.passos ?? widget.guia.passos);

    if (!mounted || _descartado) return;
    setState(() {
      _passos = lista;
      _inicializando = false;
    });

    _registrarSeUltimo();
  }

  Future<void> _registrarSeUltimo() async {
    if (_descartado || !mounted) return;
    final int total = _passos.length;
    if (total == 0 || _posicao != total) return;

    final ProgressoDeAprendizado? prog = widget.progresso;
    final String? id = widget.idDaConta;
    if (prog == null || id == null || id.trim().isEmpty) return;

    // O progresso de um guia em seções é por seção: `<guia>:<seção>`.
    final String chaveDoProgresso = widget.secao != null
        ? '${widget.guia.chave}:${widget.secao!.chave}'
        : widget.guia.chave;

    try {
      await prog.registrarChegadaAoPasso(
        idDaConta: id,
        chave: chaveDoProgresso,
        numeroDoPasso: _posicao,
        totalDePassos: total,
      );
    } catch (_) {
      // Falha silenciosa: erro em disco local não interrompe a experiência da pessoa.
    }
  }

  void _avancar() {
    if (_posicao < _passos.length) {
      setState(() => _posicao++);
      _registrarSeUltimo();
    } else {
      // Último passo: voltar ao início
      _voltarAoHub();
    }
  }

  void _retroceder() {
    if (_posicao > 1) {
      setState(() => _posicao--);
    } else {
      _sairOuVoltar();
    }
  }

  void _sairOuVoltar() {
    widget.aoVoltar?.call();
  }

  void _voltarAoHub() {
    if (widget.aoVoltarAoHub != null) {
      widget.aoVoltarAoHub!.call();
    } else {
      _sairOuVoltar();
    }
  }

  void _sairDoPassoAPasso() {
    if (widget.aoSair != null) {
      widget.aoSair!.call();
    } else {
      _sairOuVoltar();
    }
  }

  Future<void> _mostrarDialogoTelaDiferente() async {
    await DialogoMemora.mostrar(
      context,
      dialogo: DialogoMemora(
        key: TelaPassoAPasso.chaveDialogoDiferente,
        titulo: TextosGuias.telaDiferente,
        mensagem: TextosGuias.avisoTelaDiferente,
        rotuloConfirmar: widget.aoConversarSobreDiferenca != null
            ? TextosGuias.conversarSobreDiferenca
            : TextosGuias.voltar,
        aoConfirmar: () {
          Navigator.of(context).pop();
          if (widget.aoConversarSobreDiferenca != null) {
            widget.aoConversarSobreDiferenca!.call();
          }
        },
        rotuloFechar: widget.aoConversarSobreDiferenca != null
            ? TextosGuias.voltar
            : null,
        aoFechar: widget.aoConversarSobreDiferenca != null
            ? () => Navigator.of(context).pop()
            : null,
      ),
    );
  }

  bool get _podePedirParaAbrir {
    final ServicoDoCatalogo? servico = widget.servico;
    if (servico == null) return false;
    // FR-031: Serviço sensível NUNCA pode ser aberto pela Memora
    if (servico.categoria != CategoriaDoServico.cotidiano) return false;
    if (!servico.memoraPodeAbrir) return false;
    // FR-027: Só com conexão e catálogo vindo do servidor
    if (_origem != OrigemDoCatalogo.servidor) return false;
    return widget.aoPedirParaAbrir != null;
  }

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final double escala = MediaQuery.textScalerOf(context).scale(1);
    final bool compacto = escala >= MemoraDimensoes.escalaColapsoGrade;

    // Suporte aos estados de tela da FR-006 (para testes de acessibilidade e segurança)
    if (widget.estadoDeTeste == 'carregando' || _inicializando) {
      return Scaffold(
        backgroundColor: cores.fundo,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CabecalhoDeTela(
                titulo: widget.guia.titulo,
                aoVoltar: _sairOuVoltar,
              ),
              const Expanded(
                child: Center(
                  child: Carregando(mensagem: TextosGuias.capturaCarregando),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.estadoDeTeste == 'erro') {
      return Scaffold(
        backgroundColor: cores.fundo,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CabecalhoDeTela(
                titulo: widget.guia.titulo,
                aoVoltar: _sairOuVoltar,
              ),
              Expanded(
                child: Center(
                  child: MensagemErro(
                    mensagem: TextosGuias.capturaFalhou,
                    aoTentarNovamente: _prepararPassos,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.estadoDeTeste == 'vazio' || _passos.isEmpty) {
      return Scaffold(
        backgroundColor: cores.fundo,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CabecalhoDeTela(
                titulo: widget.guia.titulo,
                aoVoltar: _sairOuVoltar,
              ),
              const Expanded(
                child: Center(
                  child: EstadoVazio(
                    titulo: 'Nenhum passo disponível',
                    explicacao: 'Este guia ainda não tem etapas cadastradas.',
                    icone: Icons.school_outlined,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final int indiceAtual = (_posicao - 1).clamp(0, _passos.length - 1);
    final Passo passoAtual = _passos[indiceAtual];
    final bool eUltimo = _posicao == _passos.length;

    final Widget botaoAnterior = BotaoSecundario(
      rotulo: 'Anterior',
      icone: compacto ? null : Icons.arrow_back,
      aoTocar: _posicao > 1 ? _retroceder : null,
    );

    final Widget botaoProximo = BotaoPrimario(
      rotulo: 'Próximo',
      icone: compacto ? null : Icons.arrow_forward,
      aoTocar: _avancar,
    );

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CabecalhoDeTela(
              titulo: widget.secao?.titulo ?? widget.guia.titulo,
              aoVoltar: _retroceder,
            ),
            PassoIlustrado(
              key: ValueKey<int>(_posicao),
              rolar: false,
              passo: passoAtual,
              posicao: _posicao,
              total: _passos.length,
              aoContinuar: _avancar,
              aoVoltar: _posicao > 1 ? _retroceder : null,
              aoSair: _sairDoPassoAPasso,
              aoTelaDiferente: _mostrarDialogoTelaDiferente,
              aoPedirParaAbrir: eUltimo && _podePedirParaAbrir
                  ? () => widget.aoPedirParaAbrir!(
                        TextosGuias.pedidoParaAbrir(
                          widget.servico?.nomeExibido ?? widget.guia.titulo,
                        ),
                      )
                  : null,
              aoTirarDuvida: eUltimo &&
                      (widget.aoTirarDuvida != null ||
                          widget.aoConversarSobreDiferenca != null)
                  ? () {
                      if (widget.aoTirarDuvida != null) {
                        final String nomeBase =
                            widget.servico?.nomeExibido ?? widget.guia.titulo;
                        widget.aoTirarDuvida!(
                          TextosGuias.rascunhoDuvida(
                            widget.secao != null
                                ? '$nomeBase (${widget.secao!.titulo})'
                                : nomeBase,
                          ),
                        );
                      } else {
                        widget.aoConversarSobreDiferenca!();
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: cores.superficieBarra,
          border: Border(
            top: BorderSide(
              color: ehAltoContraste ? cores.borda : cores.bordaSutil,
              width: ehAltoContraste
                  ? MemoraDimensoes.bordaEnfase
                  : MemoraDimensoes.espessuraBordaSutil,
            ),
          ),
          boxShadow: MemoraElevacao.listaSombrasBarra(cores),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MemoraEspacamento.lg,
              vertical: MemoraEspacamento.sm,
            ),
            child: Row(
              children: <Widget>[
                Expanded(child: botaoAnterior),
                const SizedBox(width: MemoraEspacamento.sm),
                Expanded(child: botaoProximo),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

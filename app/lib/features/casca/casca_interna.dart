import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/design_system.dart';
import '../../l10n/textos_casca.dart';
import '../../l10n/textos_sos.dart';
import '../cuidado/presentation/widgets/botao_sos_persistente.dart';

/// Os três destinos fixos da barra inferior (FR-015 da feature 004).
enum DestinoDaCasca {
  /// Ajustes: aparência, privacidade, conta.
  ajustes(TextosCasca.destinoConfiguracoes, IconeDeNavegacao.ajustes),

  /// Início: a raiz de onde se chega a todo o resto.
  inicio(TextosCasca.destinoInicio, IconeDeNavegacao.inicio),

  /// Meu perfil.
  perfil(TextosCasca.destinoPerfil, IconeDeNavegacao.perfil);

  const DestinoDaCasca(this.rotulo, this.icone);

  /// Nome escrito do destino.
  final String rotulo;

  /// Desenho do destino. Nunca sozinho: a barra sempre escreve o [rotulo].
  final IconeDeNavegacao icone;
}

/// A casca de quem está dentro da conta: a barra inferior e uma pilha de
/// telas por destino (R1 da feature 004).
///
/// ## Por que uma pilha por destino
///
/// Quem vai ao Perfil no meio de um passo a passo e volta ao Início encontra o
/// passo a passo onde deixou. Uma pilha só obrigaria a escolher entre perder o
/// lugar e empilhar destinos uns sobre os outros.
///
/// ## Por que mora dentro do fluxo de autenticação
///
/// Duas garantias da revisão de 2026-10-01 saem daqui **pela estrutura**, e
/// não por disciplina de quem escreve a próxima tela:
///
/// - **Nada fica por cima do login.** As pilhas vivem dentro da casca, e a
///   casca só existe enquanto a pessoa está dentro. Quando a sessão expira, o
///   fluxo troca de etapa, a casca sai da árvore e leva as três pilhas junto —
///   conversa, catálogo, passo a passo. O celular esquecido na mesa mostra o
///   login, e só ele (FR-017 da 001).
/// - **Todo toque conta como atividade.** Um `Listener` só, em volta da casca
///   inteira, enxerga o toque em qualquer tela de qualquer pilha. Antes, cada
///   rota precisava lembrar de se envolver num — e quem conversava por 28
///   minutos era expulso.
///
/// ## O "voltar" do aparelho
///
/// Desempilha a tela do destino atual; na raiz de um destino que não é o
/// Início, volta ao Início; na raiz do Início, **pergunta** antes de fechar o
/// Memora. Fechar em silêncio seria o aplicativo simplesmente sumir para quem
/// não sabe o que o gesto faz — e o Princípio II pede aviso sempre que a pessoa
/// sai do Memora.
class CascaInterna extends StatefulWidget {
  /// A raiz de cada destino.
  final Map<DestinoDaCasca, WidgetBuilder> raizes;

  /// Chamada a cada toque, em qualquer tela de qualquer pilha.
  final VoidCallback aoRegistrarAtividade;

  /// O que fecha o Memora, depois da confirmação. Trocável no teste.
  final Future<void> Function() aoFecharOMemora;

  /// Callback disparado pelo botão SOS persistente presente em todas as telas
  /// internas da conta (Feature 014). Quando nulo, o botão não é exibido.
  final VoidCallback? aoAcionarSos;

  /// Cria a casca.
  const CascaInterna({
    required this.raizes,
    required this.aoRegistrarAtividade,
    this.aoFecharOMemora = _fecharDeVerdade,
    this.aoAcionarSos,
    super.key,
  });

  static Future<void> _fecharDeVerdade() => fecharOAplicativo();

  /// Fecha o aplicativo de verdade. Quem pergunta antes (a casca e a
  /// apresentação) usa a mesma saída.
  static Future<void> fecharOAplicativo() => SystemNavigator.pop();

  /// Chave da barra inferior, para os testes.
  static const Key chaveDaBarra = Key('casca.barra');

  /// Chave da faixa superior dedicada ao botão SOS persistente.
  static const Key chaveFaixaSos = Key('casca.faixa_sos');

  /// Chave do botão SOS persistente, para os testes.
  static const Key chaveBotaoSos = Key('casca.sos');

  /// Chave da pergunta de fechar o Memora, para os testes.
  static const Key chavePerguntaDeFechar = Key('casca.fechar');

  @override
  State<CascaInterna> createState() => CascaInternaState();
}

/// O estado da casca, exposto para o fluxo empilhar telas no destino atual.
class CascaInternaState extends State<CascaInterna> {
  DestinoDaCasca _atual = DestinoDaCasca.inicio;
  int _barrasAssumindoSos = 0;

  final Map<DestinoDaCasca, GlobalKey<NavigatorState>> _navegadores =
      <DestinoDaCasca, GlobalKey<NavigatorState>>{
        for (final DestinoDaCasca d in DestinoDaCasca.values)
          d: GlobalKey<NavigatorState>(debugLabel: 'casca.${d.name}'),
      };

  /// O destino à vista.
  DestinoDaCasca get destinoAtual => _atual;

  NavigatorState get _navegadorAtual => _navegadores[_atual]!.currentState!;

  void _atualizarBarraAssumindoSos(bool assumindo) {
    final int proximo = _barrasAssumindoSos + (assumindo ? 1 : -1);
    final int limitado = proximo < 0 ? 0 : proximo;
    if (limitado == _barrasAssumindoSos || !mounted) return;
    setState(() => _barrasAssumindoSos = limitado);
  }

  /// Contexto do navegador da aba atualmente em exibição, útil para abrir
  /// diálogos presos ao ciclo de vida da casca.
  BuildContext? get contextoAtivo =>
      _navegadores[_atual]?.currentState?.overlay?.context ??
      _navegadores[_atual]?.currentContext;

  /// Empilha [rota] no destino à vista.
  ///
  /// É **por aqui** que o fluxo abre conversa, catálogo e registro. Empilhar
  /// no `Navigator` de fora poria a tela por cima da barra inferior, e fora da
  /// casca — onde ela sobreviveria à saída da conta.
  Future<T?> empilhar<T>(Route<T> rota) => _navegadorAtual.push<T>(rota);

  /// Vai para [destino]. Se já está nele, volta à raiz — o "me tira daqui" de
  /// quem se perdeu numa pilha funda.
  void irPara(DestinoDaCasca destino) {
    if (destino == _atual) {
      _navegadorAtual.popUntil((Route<dynamic> r) => r.isFirst);
      return;
    }
    setState(() => _atual = destino);
  }

  Future<void> _voltarDoAparelho() async {
    final NavigatorState navegador = _navegadorAtual;
    if (navegador.canPop()) {
      navegador.pop();
      return;
    }
    if (_atual != DestinoDaCasca.inicio) {
      setState(() => _atual = DestinoDaCasca.inicio);
      return;
    }
    bool fechar = false;
    await DialogoMemora.mostrar(
      context,
      dialogo: DialogoMemora(
        key: CascaInterna.chavePerguntaDeFechar,
        titulo: TextosCasca.tituloSairDoMemora,
        mensagem: TextosCasca.perguntaSairDoMemora,
        rotuloConfirmar: TextosCasca.botaoFecharMemora,
        aoConfirmar: () {
          fechar = true;
          Navigator.of(context).pop();
        },
        rotuloFechar: TextosCasca.botaoFicar,
        aoFechar: () => Navigator.of(context).pop(),
      ),
    );
    if (fechar) await widget.aoFecharOMemora();
  }

  @override
  Widget build(BuildContext context) {
    // Com o teclado aberto, a barra sai e o campo de escrever fica com a
    // altura (FR-015). Ela volta quando o teclado fecha.
    final bool tecladoAberto = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bool sosHabilitado = widget.aoAcionarSos != null && !tecladoAberto;
    final bool mostrarFaixaTopo = sosHabilitado && _barrasAssumindoSos == 0;
    final double escala = MediaQuery.textScalerOf(context).scale(1);
    final double alturaFaixaSos = escala >= MemoraDimensoes.escalaTextoAlta
        ? MemoraDimensoes.alvoDecisao + MemoraEspacamento.xs
        : MemoraDimensoes.alvoMinimo +
              MemoraEspacamento.sm +
              MemoraDimensoes.bordaEnfase;

    final Widget pilhaNavegadores = IndexedStack(
      index: _atual.index,
      children: <Widget>[
        for (final DestinoDaCasca d in DestinoDaCasca.values)
          Navigator(
            key: _navegadores[d],
            onGenerateRoute: (RouteSettings _) =>
                MaterialPageRoute<void>(builder: widget.raizes[d]!),
          ),
      ],
    );

    final Widget corpoNavegadores = sosHabilitado
        ? EscopoSosNaCasca(
            rotuloBotao: TextosSos.rotuloBotaoSos,
            construirBotao: (_) => BotaoSosPersistente(
              key: CascaInterna.chaveBotaoSos,
              aoTocar: widget.aoAcionarSos!,
            ),
            aoAlterarBarraAtiva: _atualizarBarraAssumindoSos,
            child: pilhaNavegadores,
          )
        : pilhaNavegadores;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool saiu, Object? _) {
        if (!saiu) _voltarDoAparelho();
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => widget.aoRegistrarAtividade(),
        child: Scaffold(
          backgroundColor: context.memora.cores.fundo,
          appBar: mostrarFaixaTopo
              ? PreferredSize(
                  preferredSize: Size.fromHeight(alturaFaixaSos),
                  child: _FaixaSosPersistente(
                    key: CascaInterna.chaveFaixaSos,
                    aoAcionarSos: widget.aoAcionarSos!,
                  ),
                )
              : null,
          body: corpoNavegadores,
          bottomNavigationBar: tecladoAberto
              ? null
              : NavegacaoInferior(
                  key: CascaInterna.chaveDaBarra,
                  indiceAtivo: _atual.index,
                  aoSelecionar: (int i) => irPara(DestinoDaCasca.values[i]),
                  itens: <ItemNavegacao>[
                    for (final DestinoDaCasca d in DestinoDaCasca.values)
                      ItemNavegacao(icone: d.icone, rotulo: d.rotulo),
                  ],
                ),
        ),
      ),
    );
  }
}

class _FaixaSosPersistente extends StatelessWidget {
  final VoidCallback aoAcionarSos;

  const _FaixaSosPersistente({
    required this.aoAcionarSos,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.fundo,
        border: Border(
          bottom: BorderSide(
            color: ehAltoContraste ? cores.borda : cores.bordaSutil,
            width: ehAltoContraste
                ? MemoraDimensoes.bordaEnfase
                : MemoraDimensoes.espessuraBordaSutil,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: MemoraEspacamento.md,
            right: MemoraEspacamento.md,
            bottom: MemoraEspacamento.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Flexible(
                child: BotaoSosPersistente(
                  key: CascaInterna.chaveBotaoSos,
                  aoTocar: aoAcionarSos,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

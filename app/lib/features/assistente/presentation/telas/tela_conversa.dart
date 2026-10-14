import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_assistente.dart';
import '../../domain/assistente.dart';
import '../controladores/controlador_conversa.dart';

/// A conversa com a Memora (T038, US2; redesenhada na T055, US3 da 004).
///
/// ## O aviso antigolpe fica no topo, e não sai — mas encolhe (FR-022, T118)
///
/// A FR-033 exige aviso permanente, e a posição não é detalhe: quem está sendo
/// enganado ao telefone é conduzido direto ao campo de escrever. Aviso embaixo
/// da conversa só é lido por quem já não precisava dele.
///
/// **Aberto até a primeira mensagem; depois, uma linha** com o escudo e o
/// núcleo ("senha" e "código"), que se toca para ler inteiro. Ele nunca some,
/// nem por gesto: o golpista pressiona a pessoa **durante** a conversa, e
/// "feche esse aviso" é o que ele pediria. O que a FR-022 pede de espaço — a
/// lista e o campo com pelo menos metade da altura — sai das frações abaixo, e
/// não de números de pixels (a lição do teto da conversa, PR #28).
///
/// ## Quem disse o quê (FR-020)
///
/// Cada fala é um `BalaoDeFala`: posição, rosto e nome escrito, nunca só cor.
///
/// ## A oferta de abrir passa por confirmação
///
/// Quando o controlador tem uma [ControladorConversa.acaoOferecida], ela chega
/// **já autorizada pelo servidor** (FR-022 da 003). Autorizado não é
/// consentido: a pessoa ainda precisa confirmar, e o texto diz exatamente o que
/// vai acontecer, incluindo que ela sairá do Memora (FR-015, FR-021). A
/// `ConfirmacaoMemora` já empilha as opções, com 56 dp e afastadas (FR-021 da
/// 004).
///
/// ## O teclado (FR-015, T056)
///
/// A barra inferior sai com o teclado — quem cuida disso é a casca. Aqui, a
/// lista rola de novo ao fim quando a altura muda, para a última mensagem não
/// ficar atrás do campo.
class TelaConversa extends StatefulWidget {
  /// Chave do campo de mensagem.
  static const Key chaveCampo = Key('conversa.campo');

  /// Chave do botão de enviar.
  static const Key chaveEnviar = Key('conversa.enviar');

  /// Chave do aviso antigolpe.
  static const Key chaveAviso = Key('conversa.aviso_antigolpe');

  /// Chave do botão que confirma abrir o aplicativo.
  static const Key chaveConfirmarAbrir = Key('conversa.confirmar_abrir');

  /// Chave do botão que recusa a oferta.
  static const Key chaveRecusarAbrir = Key('conversa.recusar_abrir');

  /// Controlador da tela.
  final ControladorConversa controlador;

  /// Volta ao Hub.
  final VoidCallback? aoVoltar;

  /// Cria a tela de conversa.
  const TelaConversa({required this.controlador, this.aoVoltar, super.key});

  @override
  State<TelaConversa> createState() => _TelaConversaState();
}

class _TelaConversaState extends State<TelaConversa>
    with WidgetsBindingObserver {
  // Nasce com o rascunho: quem chega do catálogo já vê a pergunta, sem esperar
  // a conversa guardada terminar de ser lida (T077).
  late final TextEditingController _campo = TextEditingController(
    text: widget.controlador.rascunho,
  );
  final ScrollController _rolagem = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controlador.addListener(_aoMudar);
    widget.controlador.iniciar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controlador.removeListener(_aoMudar);
    _campo.dispose();
    _rolagem.dispose();
    super.dispose();
  }

  /// O teclado subindo ou descendo muda a altura da lista: sem rolar de novo,
  /// a última mensagem ficava atrás do campo (FR-015, T056).
  @override
  void didChangeMetrics() => _rolarParaOFim();

  void _aoMudar() {
    // O controlador é dono do valor; o campo apenas o reflete. Importa depois
    // de enviar, quando o rascunho é limpo por quem não é a pessoa.
    if (_campo.text != widget.controlador.rascunho) {
      _campo.value = TextEditingValue(
        text: widget.controlador.rascunho,
        selection: TextSelection.collapsed(
          offset: widget.controlador.rascunho.length,
        ),
      );
    }
    _rolarParaOFim();
  }

  void _rolarParaOFim() {
    if (!_rolagem.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_rolagem.hasClients) return;
      _rolagem.jumpTo(_rolagem.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return ListenableBuilder(
      listenable: widget.controlador,
      builder: (BuildContext context, _) {
        final ControladorConversa c = widget.controlador;
        final bool primeiraVez = c.mensagens.isEmpty;
        // O teclado vem da janela (`View`): o `Scaffold` o tira do
        // `MediaQuery` que entrega ao corpo, e de dentro dele nunca o veríamos.
        final bool tecladoAberto =
            MediaQueryData.fromView(View.of(context)).viewInsets.bottom > 0;

        return Scaffold(
          backgroundColor: cores.fundo,
          appBar: BarraSuperior(
            titulo: TextosAssistente.tituloConversa,
            aoVoltar: widget.aoVoltar,
          ),
          body: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints restricoes) {
                // Os tetos das duas faixas são FRAÇÕES do que este aparelho
                // oferece, nunca números de pixels. Teto fixo só não estoura
                // no aparelho em que foi medido: 420 px cabem num 390x844 e
                // não cabem num 360x640, que estoura já em 100%.
                //
                // O aviso, com o respiro dele, toma NO MÁXIMO metade (FR-022);
                // o campo, com o dele, 36%. Os 14% que sobram são o piso da
                // lista de mensagens — a conversa nunca fica sem espaço
                // nenhum, que é o que a FR-027 quer dizer com "continua
                // utilizável". Na prática a lista ganha bem mais, porque
                // depois da primeira mensagem o aviso é uma linha.
                final double altura = restricoes.maxHeight;
                const double respiro = MemoraEspacamento.md * 2;

                return Column(
                  children: <Widget>[
                    // Permanente, e no topo. Ver a nota da classe.
                    Padding(
                      padding: const EdgeInsets.all(MemoraEspacamento.md),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              altura * MemoraDimensoes.tetoDoAvisoAberto -
                              respiro,
                        ),
                        child: KeyedSubtree(
                          key: TelaConversa.chaveAviso,
                          // A chave muda quando a primeira mensagem chega, e é
                          // isso que o recolhe: o aviso é recriado fechado, em
                          // uma linha. Voltar a abrir é com a pessoa.
                          child: AvisoCompacto(
                            key: ValueKey<bool>(primeiraVez),
                            titulo: TextosAssistente.tituloAvisoAntigolpe,
                            resumo: TextosAssistente.resumoAvisoAntigolpe,
                            textoCompleto: TextosAssistente.avisoAntigolpe,
                            comMemora: false,
                            abertoNoComeco: primeiraVez,
                            fechadoEmUmaLinha: true,
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: ListView(
                        controller: _rolagem,
                        padding: const EdgeInsets.symmetric(
                          horizontal: MemoraEspacamento.lg,
                        ),
                        children: <Widget>[
                          // O vazio é a Memora convidando, e não uma área em
                          // branco (FR-006).
                          if (primeiraVez) ...<Widget>[
                            const BalaoDeFala(
                              autor: AutorDoBalao.memora,
                              texto: TextosAssistente.convite,
                            ),
                            const SizedBox(height: MemoraEspacamento.md),
                          ],

                          for (final MensagemDaConversa m
                              in c.mensagens) ...<Widget>[
                            BalaoDeFala(
                              autor: m.autor == AutorDaMensagem.memora
                                  ? AutorDoBalao.memora
                                  : AutorDoBalao.pessoa,
                              texto: m.texto,
                            ),
                            const SizedBox(height: MemoraEspacamento.md),
                          ],

                          if (c.respondendo) ...<Widget>[
                            if (c.trechoEmCurso.isEmpty)
                              const BalaoDeFala.escrevendo()
                            else
                              BalaoDeFala(
                                autor: AutorDoBalao.memora,
                                texto: c.trechoEmCurso,
                              ),
                            const SizedBox(height: MemoraEspacamento.md),
                          ],

                          if (c.mensagemDeErro != null) ...<Widget>[
                            MensagemErro(
                              mensagem: c.mensagemDeErro!,
                              aoTentarNovamente: c.tentarNovamente,
                            ),
                            const SizedBox(height: MemoraEspacamento.md),
                          ],

                          // A oferta aparece DENTRO da conversa, e nao num
                          // dialogo por cima. Dialogo interrompe e some; aqui a
                          // pessoa pode reler o passo a passo acima antes de
                          // decidir — que e exatamente a decisao que a FR-014
                          // quer que ela tome com calma.
                          if (c.acaoOferecida != null) ...<Widget>[
                            ConfirmacaoMemora(
                              key: TelaConversa.chaveConfirmarAbrir,
                              pergunta: TextosAssistente.pedidoDeAbertura(
                                c.acaoOferecida!.nomeExibido,
                              ),
                              rotuloConfirmar: TextosAssistente.botaoAbrir(
                                c.acaoOferecida!.nomeExibido,
                              ),
                              rotuloRecusar:
                                  TextosAssistente.botaoPrefiroTentar,
                              aoConfirmar: c.confirmarAcao,
                              aoRecusar: c.recusarAcao,
                            ),
                            const SizedBox(height: MemoraEspacamento.md),
                          ],
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(MemoraEspacamento.md),
                      // Mesma regra do aviso, e pelo mesmo motivo (T070): o
                      // rótulo e a ajuda do `CampoTexto` crescem junto com o
                      // texto, e sozinhos empurravam o botão de enviar para
                      // fora da tela em 200%. Acima do teto, rolar esta faixa
                      // alcança o botão — mesma linguagem de interação que a
                      // lista de mensagens já usa.
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              altura *
                                  (tecladoAberto
                                      ? MemoraDimensoes.tetoDoCampoComTeclado
                                      : MemoraDimensoes.tetoDoCampoDaConversa) -
                              respiro,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              CampoTexto(
                                key: TelaConversa.chaveCampo,
                                rotulo: TextosAssistente.rotuloMensagem,
                                textoAjuda: TextosAssistente.ajudaMensagem,
                                controlador: _campo,
                                aoMudar: c.escrever,
                                habilitado: !c.respondendo,
                              ),
                              const SizedBox(height: MemoraEspacamento.md),
                              if (c.respondendo)
                                const Carregando(
                                  mensagem: TextosAssistente.pensando,
                                )
                              else
                                BotaoPrimario(
                                  key: TelaConversa.chaveEnviar,
                                  rotulo: TextosAssistente.botaoEnviar,
                                  icone: Icons.send,
                                  aoTocar: c.podeEnviar ? c.enviar : null,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

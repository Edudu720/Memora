import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../design_system/componentes/toque/superficie_tocavel.dart';
import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_assistente.dart';
import '../../domain/assistente.dart';
import '../../domain/leitor_de_voz.dart';
import '../controladores/controlador_conversa.dart';

/// A conversa com a Memora (T038, US2; redesenhada na T055, US3 da 004).
/// A conversa com a Memora (T042, Feature 007).
///
/// ## O aviso antigolpe fica no topo, e não sai — mas encolhe (FR-022, T118)
///
/// A FR-033 exige aviso permanente, e a posição não é detalhe: quem está sendo
/// enganado ao telefone é conduzido direto ao campo de escrever. Aviso embaixo
/// da conversa só é lido por quem já não precisava dele.
///
/// **Aberto até a primeira pergunta; depois, só o escudo** num canto (T130),
/// que se toca para ler os avisos inteiros. O núcleo ("senha" e "código") segue
/// no rótulo do escudo, para o leitor de tela — e quem enxerga deixa de ver a
/// frase sem tocar, risco aceito pelo Henrique em 2026-10-21. Ele nunca some,
/// nem por gesto: o golpista pressiona a pessoa **durante** a conversa, e
/// "feche esse aviso" é o que ele pediria. O que a FR-022 pede de espaço — a
/// lista e o campo com pelo menos metade da altura — sai das frações abaixo, e
/// não de números de pixels (a lição do teto da conversa, PR #28).
///
/// ## Quem disse o quê (FR-020)
///
/// Cada fala é um `BalaoDeFala`: posição, rosto e nome escrito, nunca só cor.
///
/// ## A espera e a escrita são do balão, e só dele (FR-020b, T132)
///
/// Enquanto a Memora responde, a espera é o balão dela se formando — nenhuma
/// frase embaixo do campo, que fica desabilitado, junto com o botão, no mesmo
/// lugar. Depois, a **última** fala dela vai aparecendo aos poucos; as antigas,
/// inclusive as lidas do disco, aparecem inteiras. O balão que mostra o texto
/// chegando e a mensagem final em que ele se transforma têm a mesma `key`:
/// a escrita continua de onde estava, sem recomeçar nem piscar.
///
/// ## O aviso de privacidade mora na mesma caixa (FR-051)
///
/// O que a pessoa escreve vai a um serviço de fora do Memora. O aviso disso e o
/// do golpe dividem **a mesma caixa**, e portanto a mesma permanência: onde um
/// encolher ou rolar, o outro vai junto — nunca um fica e o outro some. E,
/// antes da primeira mensagem, a explicação do aceite ocupa o lugar do campo:
/// quem não aceitou não tem por onde escrever.
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
/// Fluxo estruturado em três momentos:
/// 1. Antes do aceite (`precisaDoAceite`), apresenta `_ExplicacaoDoAceite` com
///    as chaves e garantias da FR-051 sem liberar o campo de envio.
/// 2. Após o aceite e sem histórico, recebe com `ExpressaoDaMemora.falando`,
///    convite editorial e grade 2x2 responsiva de sugestões de pergunta.
/// 3. Na conversa ativa, mantém `AvisoCompacto` permanente no topo, balões
///    limpos e barra inferior elevada com campo de texto, ditado por voz
///    opcional no rascunho (FR-013) e botão manual `"Perguntar"`.
class TelaConversa extends StatefulWidget {
  /// Chave do campo de mensagem.
  static const Key chaveCampo = Key('conversa.campo');

  /// Chave do botão de enviar.
  static const Key chaveEnviar = Key('conversa.enviar');

  /// Chave do botão acessível de ditado por voz ("Falar" / "Parar").
  static const Key chaveMicrofone = Key('conversa.microfone');

  /// Chave do diálogo prévio que explica a permissão de microfone.
  static const Key chaveDialogoPermissaoVoz = Key(
    'conversa.dialogo_permissao_voz',
  );

  /// Chave da faixa de estado ou fallback amigável do ditado por voz.
  static const Key chaveStatusVoz = Key('conversa.status_voz');

  /// Chave da grade de sugestões iniciais de pergunta.
  static const Key chaveSugestoes = Key('conversa.sugestoes');

  /// Chave do aviso antigolpe.
  static const Key chaveAviso = Key('conversa.aviso_antigolpe');

  /// Chave do aviso de privacidade (FR-051), que mora na mesma caixa.
  static const Key chaveAvisoPrivacidade = Key('conversa.aviso_privacidade');

  /// Chave da explicação que antecede a primeira mensagem (FR-051).
  static const Key chaveAceite = Key('conversa.aceite');

  /// Chave do botão que aceita a explicação.
  static const Key chaveAceitar = Key('conversa.aceitar');

  /// Chave do botão que recusa a explicação.
  static const Key chaveRecusarAceite = Key('conversa.recusar_aceite');

  /// Chave da caixa de erro da conversa.
  static const Key chaveErro = Key('conversa.erro');

  /// Chave do botão que confirma abrir o aplicativo.
  static const Key chaveConfirmarAbrir = Key('conversa.confirmar_abrir');

  /// Chave do botão que recusa a oferta.
  static const Key chaveRecusarAbrir = Key('conversa.recusar_abrir');

  /// Chave do botão de recomeçar a conversa (T085).
  static const Key chaveRecomecar = Key('conversa.recomecar');

  /// Chave do diálogo de confirmação de recomeço (T085).
  static const Key chaveConfirmarRecomeco = Key('conversa.confirmar_recomeco');

  /// Controlador da tela.
  final ControladorConversa controlador;

  /// Volta ao Hub.
  /// Volta ao Hub ou Início.
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

  int _ultimoTotalMensagens = 0;
  bool _ultimoRespondendo = false;
  String _ultimoTrecho = '';

  /// A posição, na conversa, da fala da Memora que **acabou de chegar**, e que
  /// portanto vai aparecendo aos poucos (FR-020b). Nenhuma, até chegar uma.
  ///
  /// Fala que já estava lá — a conversa lida do disco — nunca é marcada, e
  /// por isso nunca anima. É uma posição, e não "a última mensagem": quando a
  /// falha tira a pergunta da conversa, a última passa a ser uma fala antiga,
  /// que não pode recomeçar a ser escrita.
  int _emEscrita = -1;

  /// Há texto da Memora aparecendo aos poucos neste instante? Mexe a boca da
  /// Memora do topo (FR-025). Quem avisa é o próprio texto, ao começar e ao
  /// parar de escrever.
  bool _escrevendoNaTela = false;

  void _aoMudarEscrita(bool escrevendo) {
    if (!mounted || escrevendo == _escrevendoNaTela) return;
    setState(() => _escrevendoNaTela = escrevendo);
  }

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

    final ControladorConversa c = widget.controlador;
    final bool zerouConversa = _ultimoTotalMensagens > 0 && c.mensagens.isEmpty;
    if (c.jaPerguntou &&
        c.mensagens.length > _ultimoTotalMensagens &&
        c.mensagens.last.autor == AutorDaMensagem.memora) {
      _emEscrita = c.mensagens.length - 1;
    }
    final bool precisaRolar =
        c.mensagens.length != _ultimoTotalMensagens ||
        c.respondendo != _ultimoRespondendo ||
        c.trechoEmCurso != _ultimoTrecho ||
        c.acaoOferecida != null;
    _ultimoTotalMensagens = c.mensagens.length;
    _ultimoRespondendo = c.respondendo;
    _ultimoTrecho = c.trechoEmCurso;

    if (zerouConversa && !c.respondendo && c.mensagemDeErro == null) {
      _rolarParaOInicio();
    } else if (precisaRolar) {
      _rolarParaOFim();
    }
  }

  void _rolarParaOInicio() {
    if (!_rolagem.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_rolagem.hasClients) return;
      _rolagem.jumpTo(0);
    });
  }

  void _rolarParaOFim() {
    if (!_rolagem.hasClients) return;
    // A explicação do aceite é lida do começo. Descer ao fim levaria a pessoa
    // direto aos botões, sem passar pelo texto que eles respondem.
    if (widget.controlador.precisaDoAceite) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_rolagem.hasClients) return;
      _rolagem.jumpTo(_rolagem.position.maxScrollExtent);
    });
  }

  void _confirmarRecomeco(BuildContext context, ControladorConversa c) {
    DialogoMemora.mostrar(
      context,
      dialogo: DialogoMemora(
        key: TelaConversa.chaveConfirmarRecomeco,
        titulo: TextosAssistente.tituloRecomecar,
        mensagem: TextosAssistente.explicacaoRecomecar,
        rotuloConfirmar: TextosAssistente.botaoConfirmarRecomeco,
        aoConfirmar: () {
          Navigator.of(context).pop();
          c.apagarConversa();
        },
        rotuloFechar: TextosAssistente.botaoCancelarRecomeco,
        aoFechar: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// A chave da fala que está sendo escrita: ela amarra o texto que chega à
  /// mensagem final, na posição `indice` da conversa.
  void _acionarMicrofone(BuildContext context, ControladorConversa c) {
    if (c.respondendo) return;
    if (c.ouvindoVoz) {
      c.pararDitado();
      return;
    }
    if (!c.precisaExplicarPermissaoVoz) {
      c.iniciarDitado();
      return;
    }
    c.prepararPedidoPermissaoVoz();
    DialogoMemora.mostrar(
      context,
      dialogo: DialogoMemora(
        key: TelaConversa.chaveDialogoPermissaoVoz,
        titulo: TextosAssistente.tituloPermissaoVoz,
        mensagem: TextosAssistente.explicacaoPermissaoVoz,
        rotuloConfirmar: TextosAssistente.botaoConfirmarPermissaoVoz,
        aoConfirmar: () {
          Navigator.of(context).pop();
          c.iniciarDitado();
        },
        rotuloFechar: TextosAssistente.botaoRecusarPermissaoVoz,
        aoFechar: () {
          Navigator.of(context).pop();
          c.cancelarPedidoPermissaoVoz();
        },
      ),
    );
  }

  Key _chaveDaEscrita(int indice) => ValueKey<String>('conversa.fala.$indice');

  /// A fala `indice` da conversa.
  Widget _fala(ControladorConversa c, int indice) {
    final MensagemDaConversa m = c.mensagens[indice];
    final bool daMemora = m.autor == AutorDaMensagem.memora;
    // Só a fala que acabou de chegar, e só enquanto é a última: ao mandar a
    // próxima pergunta, ela aparece inteira. `!respondendo` evita que a mesma
    // chave exista em dois balões ao mesmo tempo.
    final bool escrevendo =
        daMemora &&
        indice == _emEscrita &&
        indice == c.mensagens.length - 1 &&
        !c.respondendo;

    return BalaoDeFala(
      key: escrevendo ? _chaveDaEscrita(indice) : null,
      autor: daMemora ? AutorDoBalao.memora : AutorDoBalao.pessoa,
      texto: m.texto,
      comRosto: false,
      escreverAosPoucos: escrevendo,
      aoEscrever: escrevendo ? _rolarParaOFim : null,
      // Sempre, para a Memora: se a fala deixar de ser a que escreve no meio
      // da escrita (a próxima pergunta), o aviso de "parou" ainda chega.
      aoMudarEscrita: daMemora ? _aoMudarEscrita : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;

    return ListenableBuilder(
      listenable: widget.controlador,
      builder: (BuildContext context, _) {
        final ControladorConversa c = widget.controlador;
        final bool primeiraVez = c.mensagens.isEmpty;
        // Aberto só até a primeira pergunta. "A conversa está vazia" sozinho
        // não serve: a falha devolve a pergunta ao campo e a tira da conversa
        // (FR-052), e o aviso se recriava aberto a cada erro do serviço de
        // fora — achado no celular em 2026-10-21.
        final bool avisoAberto = primeiraVez && !c.jaPerguntou;
        // O teclado vem da janela (`View`): o `Scaffold` o tira do
        // `MediaQuery` que entrega ao corpo, e de dentro dele nunca o veríamos.
        final bool tecladoAberto =
            MediaQueryData.fromView(View.of(context)).viewInsets.bottom > 0;
        final double escala = MediaQuery.textScalerOf(context).scale(1);

        return Scaffold(
          backgroundColor: cores.fundo,
          appBar: BarraSuperior(
            titulo: TextosAssistente.tituloConversa,
            aoVoltar: widget.aoVoltar,
            // A Memora desta tela é esta, pequena e no topo, e só ela: os
            // balões não levam rosto (FR-025, FR-042). Fala enquanto a
            // resposta aparece, e volta ao repouso quando termina.
            memora: ExpressaoDaMemora.neutra,
            memoraFalando:
                (c.respondendo && c.trechoEmCurso.isNotEmpty) ||
                _escrevendoNaTela,
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
                final bool mostrarRecomecar =
                    c.mensagens.isNotEmpty &&
                    !c.precisaDoAceite &&
                    !tecladoAberto;
                final double folgaVerticalAviso = c.precisaDoAceite
                    ? 0
                    : MemoraEspacamento.xs;
                final double folgaAceiteCompacto =
                    c.precisaDoAceite &&
                        escala >= MemoraDimensoes.escalaColapsoGrade
                    ? MemoraEspacamento.lg
                    : 0;
                final double tetoAviso =
                    altura * MemoraDimensoes.tetoDoAvisoAberto -
                    folgaVerticalAviso * 2 -
                    folgaAceiteCompacto;
                final bool listaCompacta =
                    c.precisaDoAceite &&
                    escala >= MemoraDimensoes.escalaColapsoGrade;

                return Column(
                  children: <Widget>[
                    // Permanente, e no topo. Ver a nota da classe. Recolhido, é
                    // só um escudo de 48 dp à direita; o botão de recomeçar
                    // divide a mesma faixa de 48 dp à esquerda, sem roubar
                    // altura da lista de mensagens.
                    Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[
                        if (mostrarRecomecar)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: MemoraEspacamento.md,
                              right:
                                  MemoraEspacamento.md +
                                  MemoraDimensoes.alvoMinimo +
                                  MemoraEspacamento.xs,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SuperficieTocavel(
                                key: TelaConversa.chaveRecomecar,
                                rotulo: TextosAssistente.rotuloRecomecar,
                                aoTocar: () => _confirmarRecomeco(context, c),
                                fundo: cores.superficieSutil,
                                borda: ehAltoContraste
                                    ? cores.borda
                                    : cores.bordaSutil,
                                larguraBorda: ehAltoContraste
                                    ? MemoraDimensoes.bordaEnfase
                                    : MemoraDimensoes.espessuraBordaSutil,
                                raio: BorderRadius.circular(MemoraRaio.pilula),
                                child: SizedBox(
                                  height: MemoraDimensoes.alvoMinimo,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: MemoraEspacamento.md,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Icon(
                                          Icons.restart_alt_rounded,
                                          color: cores.primaria,
                                          size: MemoraDimensoes.iconePadrao,
                                        ),
                                        const SizedBox(
                                          width: MemoraEspacamento.xs,
                                        ),
                                        Flexible(
                                          child: TextoMemora.apoio(
                                            TextosAssistente.rotuloRecomecar,
                                            cor: cores.primaria,
                                            maxLinhas: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: avisoAberto
                              ? EdgeInsets.symmetric(
                                  horizontal: MemoraEspacamento.md,
                                  vertical: folgaVerticalAviso,
                                )
                              : const EdgeInsets.symmetric(
                                  horizontal: MemoraEspacamento.md,
                                ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: tetoAviso > 0 ? tetoAviso : 0,
                            ),
                            // As duas chaves marcam a MESMA caixa: o aviso do golpe
                            // e o de privacidade não têm como se separar, e um não
                            // fica enquanto o outro some.
                            child: KeyedSubtree(
                              key: TelaConversa.chaveAviso,
                              child: KeyedSubtree(
                                key: TelaConversa.chaveAvisoPrivacidade,
                                // A chave muda quando a primeira pergunta é feita, e
                                // é isso que o recolhe: o aviso é recriado fechado,
                                // só o escudo. Voltar a abrir é com a pessoa.
                                child: AvisoCompacto(
                                  key: ValueKey<bool>(avisoAberto),
                                  titulo: TextosAssistente.tituloAvisoAntigolpe,
                                  resumo: TextosAssistente.resumoDosAvisos,
                                  textoCompleto: TextosAssistente.avisosInteiros,
                                  comMemora: false,
                                  abertoNoComeco: avisoAberto,
                                  fechadoSoEscudo: true,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Expanded(
                      child: ListView(
                        controller: _rolagem,
                        scrollCacheExtent: ScrollCacheExtent.pixels(
                          MediaQuery.sizeOf(context).height,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: listaCompacta
                              ? MemoraEspacamento.md
                              : MemoraEspacamento.lg,
                        ),
                        children: <Widget>[
                          // Antes da primeira mensagem, a explicação toma o
                          // lugar da conversa — e o campo some abaixo (FR-051).
                          if (c.precisaDoAceite) ...<Widget>[
                            _ExplicacaoDoAceite(
                              aoAceitar: c.aceitar,
                              aoRecusar:
                                  widget.aoVoltar ??
                                  () => Navigator.of(context).maybePop(),
                            ),
                            const SizedBox(height: MemoraEspacamento.md),
                          ] else ...<Widget>[
                            // O vazio é a Memora convidando, e não uma área em
                            // branco (FR-006).
                            if (primeiraVez) ...<Widget>[
                              const BalaoDeFala(
                                autor: AutorDoBalao.memora,
                                texto: TextosAssistente.convite,
                                comRosto: false,
                              ),
                              if (!c.respondendo &&
                                  c.mensagemDeErro == null) ...<Widget>[
                                const SizedBox(height: MemoraEspacamento.md),
                                _GradeSugestoesConversa(
                                  escala: escala,
                                  aoEscolherSugestao: c.escrever,
                                ),
                              ],
                              const SizedBox(height: MemoraEspacamento.md),
                            ],

                            for (int i = 0; i < c.mensagens.length; i++) ...<Widget>[
                              _fala(c, i),
                              const SizedBox(height: MemoraEspacamento.md),
                            ],

                            if (c.respondendo) ...<Widget>[
                              if (c.trechoEmCurso.isEmpty)
                                const BalaoDeFala.escrevendo(comRosto: false)
                              else
                                // A mesma chave da mensagem em que este texto
                                // vai se transformar: a posição que ela terá.
                                BalaoDeFala(
                                  key: _chaveDaEscrita(c.mensagens.length),
                                  autor: AutorDoBalao.memora,
                                  texto: c.trechoEmCurso,
                                  comRosto: false,
                                  escreverAosPoucos: true,
                                  emAndamento: true,
                                  aoEscrever: _rolarParaOFim,
                                  aoMudarEscrita: _aoMudarEscrita,
                                ),
                              const SizedBox(height: MemoraEspacamento.md),
                            ],

                            if (c.mensagemDeErro != null) ...<Widget>[
                              MensagemErro(
                                key: TelaConversa.chaveErro,
                                mensagem: c.mensagemDeErro!,
                                // Só as falhas passageiras oferecem tentar de
                                // novo (FR-052, FR-057): o limite do dia diz
                                // que volta amanhã, e um botão ali prometeria o
                                // contrário.
                                aoTentarNovamente: c.podeTentarDeNovo
                                    ? c.tentarNovamente
                                    : null,
                              ),
                              const SizedBox(height: MemoraEspacamento.md),
                            ],

                            // A oferta aparece DENTRO da conversa, e nao num
                            // dialogo por cima. Dialogo interrompe e some; aqui
                            // a pessoa pode reler o passo a passo acima antes de
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
                        ],
                      ),
                    ),

                    // Sem aceite não há campo nem botão: nada sai daqui até a
                    // pessoa dizer que entendeu (FR-051). Enquanto a leitura do
                    // aceite não termina, o campo aparece — e o botão de enviar
                    // fica desabilitado, porque quem barra é o controlador
                    // (`podeEnviar`), e não esta tela.
                    // A área inteira de escrever: campo e botão em uma única
                    // faixa elevada (FR-013, 002/FR-012). Quando o teclado não
                    // cabe, rola suavemente.
                    if (!c.precisaDoAceite)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              altura *
                              (tecladoAberto
                                  ? MemoraDimensoes.tetoDoCampoComTeclado
                                  : MemoraDimensoes.tetoDoCampoDaConversa),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: cores.superficieBarra,
                            border: Border(
                              top: BorderSide(
                                color: ehAltoContraste
                                    ? cores.borda
                                    : cores.bordaSutil,
                                width: ehAltoContraste
                                    ? MemoraDimensoes.bordaEnfase
                                    : MemoraDimensoes.espessuraBordaSutil,
                              ),
                            ),
                            boxShadow: MemoraElevacao.listaSombrasCartao(cores),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(MemoraEspacamento.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                if (c.ouvindoVoz || c.avisoVoz != null) ...<Widget>[
                                  _FaixaEstadoVoz(
                                    ouvindo: c.ouvindoVoz,
                                    mensagem: c.ouvindoVoz
                                        ? TextosAssistente.avisoOuvindoVoz
                                        : c.avisoVoz!,
                                  ),
                                  const SizedBox(height: MemoraEspacamento.sm),
                                ],
                                CampoTexto(
                                  key: TelaConversa.chaveCampo,
                                  rotulo: TextosAssistente.rotuloMensagem,
                                  textoAjuda: TextosAssistente.ajudaMensagem,
                                  controlador: _campo,
                                  aoMudar: c.escrever,
                                  habilitado: !c.respondendo,
                                ),
                                const SizedBox(height: MemoraEspacamento.md),
                                // Enquanto a Memora responde o botão fica no
                                // lugar, desabilitado (`podeEnviar` é falso): a
                                // espera aparece só no balão dela, e a faixa
                                // não muda de altura (FR-020b).
                                LayoutBuilder(
                                  builder: (
                                    BuildContext context,
                                    BoxConstraints box,
                                  ) {
                                    final bool emLinha =
                                        box.maxWidth >=
                                            MemoraDimensoes.larguraMinimaGrade &&
                                        escala <
                                            MemoraDimensoes.escalaColapsoGrade;

                                    final Widget botaoMicrofone = _BotaoMicrofone(
                                      key: TelaConversa.chaveMicrofone,
                                      ouvindo: c.ouvindoVoz,
                                      habilitado:
                                          !c.respondendo &&
                                          c.estadoDitado !=
                                              EstadoDitado.indisponivel,
                                      aoTocar: () =>
                                          _acionarMicrofone(context, c),
                                    );
                                    final Widget botaoEnviar = BotaoPrimario(
                                      key: TelaConversa.chaveEnviar,
                                      rotulo: TextosAssistente.botaoEnviar,
                                      icone: Icons.send_rounded,
                                      aoTocar: c.podeEnviar ? c.enviar : null,
                                    );

                                    if (emLinha) {
                                      return Row(
                                        children: <Widget>[
                                          botaoMicrofone,
                                          const SizedBox(
                                            width: MemoraEspacamento.sm,
                                          ),
                                          Expanded(child: botaoEnviar),
                                        ],
                                      );
                                    }
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: <Widget>[
                                        botaoEnviar,
                                        const SizedBox(
                                          height: MemoraEspacamento.sm,
                                        ),
                                        botaoMicrofone,
                                      ],
                                    );
                                  },
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

class _GradeSugestoesConversa extends StatelessWidget {
  final double escala;
  final ValueChanged<String> aoEscolherSugestao;

  const _GradeSugestoesConversa({
    required this.escala,
    required this.aoEscolherSugestao,
  });

  static const List<({String titulo, IconData icone})> _itens =
      <({String titulo, IconData icone})>[
        (
          titulo: TextosAssistente.sugestaoLetraMaior,
          icone: Icons.format_size_rounded,
        ),
        (
          titulo: TextosAssistente.sugestaoFotos,
          icone: Icons.photo_library_rounded,
        ),
        (
          titulo: TextosAssistente.sugestaoGolpe,
          icone: Icons.shield_rounded,
        ),
        (
          titulo: TextosAssistente.sugestaoWhatsapp,
          icone: Icons.chat_rounded,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: TelaConversa.chaveSugestoes,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const TextoMemora(
            TextosAssistente.tituloSugestoesConversa,
            estilo: EstiloTexto.corpoForte,
            cabecalho: true,
          ),
          const SizedBox(height: MemoraEspacamento.sm),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints box) {
              final bool emDuasColunas =
                  box.maxWidth >= MemoraDimensoes.larguraMinimaGrade &&
                  escala < MemoraDimensoes.escalaColapsoGrade;

              if (!emDuasColunas) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (int i = 0; i < _itens.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: MemoraEspacamento.sm),
                      TileAcaoRapida(
                        titulo: _itens[i].titulo,
                        icone: _itens[i].icone,
                        aoTocar: () => aoEscolherSugestao(_itens[i].titulo),
                      ),
                    ],
                  ],
                );
              }

              final List<Widget> linhas = <Widget>[];
              for (int i = 0; i < _itens.length; i += 2) {
                if (i > 0) linhas.add(const SizedBox(height: MemoraEspacamento.sm));
                linhas.add(
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: TileAcaoRapida(
                          titulo: _itens[i].titulo,
                          icone: _itens[i].icone,
                          aoTocar: () => aoEscolherSugestao(_itens[i].titulo),
                        ),
                      ),
                      const SizedBox(width: MemoraEspacamento.sm),
                      Expanded(
                        child: TileAcaoRapida(
                          titulo: _itens[i + 1].titulo,
                          icone: _itens[i + 1].icone,
                          aoTocar: () =>
                              aoEscolherSugestao(_itens[i + 1].titulo),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: linhas,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FaixaEstadoVoz extends StatelessWidget {
  final bool ouvindo;
  final String mensagem;

  const _FaixaEstadoVoz({required this.ouvindo, required this.mensagem});

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;

    return Semantics(
      liveRegion: true,
      readOnly: true,
      child: Cartao(
        key: TelaConversa.chaveStatusVoz,
        comBorda: true,
        padding: const EdgeInsets.symmetric(
          horizontal: MemoraEspacamento.md,
          vertical: MemoraEspacamento.xs,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              ouvindo ? Icons.graphic_eq_rounded : Icons.info_outline_rounded,
              size: MemoraDimensoes.iconePadrao,
              color: ehAltoContraste ? cores.texto : cores.primaria,
            ),
            const SizedBox(width: MemoraEspacamento.sm),
            Expanded(child: TextoMemora.apoio(mensagem)),
          ],
        ),
      ),
    );
  }
}

class _BotaoMicrofone extends StatelessWidget {
  final bool ouvindo;
  final bool habilitado;
  final VoidCallback aoTocar;

  const _BotaoMicrofone({
    required this.ouvindo,
    required this.habilitado,
    required this.aoTocar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;

    final String rotuloCurto = ouvindo
        ? TextosAssistente.botaoPararDitado
        : TextosAssistente.botaoFalar;
    final String dica = ouvindo
        ? TextosAssistente.dicaPararDitado
        : TextosAssistente.dicaFalar;

    final Color fundo = !habilitado
        ? cores.superficieAlt
        : (ouvindo
              ? cores.perigo
              : (ehAltoContraste ? cores.superficie : cores.superficieSutil));
    final Color conteudoCor = !habilitado
        ? cores.textoSuave
        : (ouvindo ? cores.sobrePerigo : cores.primaria);
    final Color corBorda = !habilitado
        ? cores.borda
        : (ehAltoContraste
              ? cores.borda
              : (ouvindo ? cores.perigo : cores.primaria));

    return SuperficieTocavel(
      rotulo: rotuloCurto,
      dica: dica,
      aoTocar: habilitado ? aoTocar : null,
      fundo: fundo,
      borda: corBorda,
      raio: BorderRadius.circular(MemoraRaio.pilula),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: MemoraDimensoes.alvoDecisao,
          minHeight: MemoraDimensoes.alvoDecisao,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MemoraEspacamento.md,
            vertical: MemoraEspacamento.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                ouvindo ? Icons.stop_circle_rounded : Icons.mic_rounded,
                size: MemoraDimensoes.iconePadrao,
                color: conteudoCor,
              ),
              const SizedBox(width: MemoraEspacamento.xs),
              TextoMemora(
                rotuloCurto,
                estilo: EstiloTexto.corpoForte,
                cor: conteudoCor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A explicação que antecede a primeira mensagem (FR-051).
///
/// Uma caixa de etapa: a frase que diz o que está acontecendo, o texto, e os
/// dois botões. O primário **aceita**; o secundário volta, e quem recusa
/// continua com o restante do Memora — Hub, catálogos e registro —, só sem a
/// conversa. Nenhum dos dois pode ser tratado como erro da pessoa.
/// Preserva o texto completo de privacidade e os botões de aceite e recusa,
/// garantindo que o título permaneça visível sem exigir rolagem prévia.
class _ExplicacaoDoAceite extends StatelessWidget {
  final VoidCallback aoAceitar;
  final VoidCallback aoRecusar;

  const _ExplicacaoDoAceite({required this.aoAceitar, required this.aoRecusar});

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final double escala = MediaQuery.textScalerOf(context).scale(1);

    return Cartao(
      key: TelaConversa.chaveAceite,
      comBorda: ehAltoContraste,
      padding: EdgeInsets.all(
        escala >= MemoraDimensoes.escalaTextoAlta
            ? MemoraEspacamento.sm
            : MemoraEspacamento.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const TextoMemora(
            TextosAssistente.tituloAceite,
            estilo: EstiloTexto.tituloSecao,
            cabecalho: true,
          ),
          const SizedBox(height: MemoraEspacamento.md),
          const TextoMemora(TextosAssistente.corpoDoAceite),
          const SizedBox(height: MemoraEspacamento.lg),
          BotaoPrimario(
            key: TelaConversa.chaveAceitar,
            rotulo: TextosAssistente.botaoAceitar,
            aoTocar: aoAceitar,
          ),
          const SizedBox(height: MemoraEspacamento.md),
          BotaoSecundario(
            key: TelaConversa.chaveRecusarAceite,
            rotulo: TextosAssistente.botaoRecusarAceite,
            aoTocar: aoRecusar,
          ),
        ],
      ),
    );
  }
}

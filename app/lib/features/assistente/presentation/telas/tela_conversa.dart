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
class TelaConversa extends StatefulWidget {
  /// Chave do campo de mensagem.
  static const Key chaveCampo = Key('conversa.campo');

  /// Chave do botão de enviar.
  static const Key chaveEnviar = Key('conversa.enviar');

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
    if (c.jaPerguntou &&
        c.mensagens.length > _ultimoTotalMensagens &&
        c.mensagens.last.autor == AutorDaMensagem.memora) {
      _emEscrita = c.mensagens.length - 1;
    }
    final bool precisaRolar = c.mensagens.length != _ultimoTotalMensagens ||
        c.respondendo != _ultimoRespondendo ||
        c.trechoEmCurso != _ultimoTrecho ||
        c.acaoOferecida != null;
    _ultimoTotalMensagens = c.mensagens.length;
    _ultimoRespondendo = c.respondendo;
    _ultimoTrecho = c.trechoEmCurso;

    if (precisaRolar) {
      _rolarParaOFim();
    }
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
  Key _chaveDaEscrita(int indice) => ValueKey<String>('conversa.fala.$indice');

  /// A fala `indice` da conversa.
  Widget _fala(ControladorConversa c, int indice) {
    final MensagemDaConversa m = c.mensagens[indice];
    final bool daMemora = m.autor == AutorDaMensagem.memora;
    // Só a fala que acabou de chegar, e só enquanto é a última: ao mandar a
    // próxima pergunta, ela aparece inteira. `!respondendo` evita que a mesma
    // chave exista em dois balões ao mesmo tempo.
    final bool escrevendo = daMemora &&
        indice == _emEscrita &&
        indice == c.mensagens.length - 1 &&
        !c.respondendo;

    return BalaoDeFala(
      key: escrevendo ? _chaveDaEscrita(indice) : null,
      autor: daMemora ? AutorDoBalao.memora : AutorDoBalao.pessoa,
      texto: m.texto,
      escreverAosPoucos: escrevendo,
      aoEscrever: escrevendo ? _rolarParaOFim : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

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

        return Scaffold(
          backgroundColor: cores.fundo,
          appBar: BarraSuperior(
            titulo: TextosAssistente.tituloConversa,
            aoVoltar: widget.aoVoltar,
            acao: (c.mensagens.isNotEmpty && !c.precisaDoAceite)
                ? Semantics(
                    button: true,
                    label: TextosAssistente.rotuloRecomecar,
                    child: ExcludeSemantics(
                      child: InkWell(
                        key: TelaConversa.chaveRecomecar,
                        onTap: () => _confirmarRecomeco(context, c),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: MemoraDimensoes.alvoMinimo,
                            minHeight: MemoraDimensoes.alvoMinimo,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: MemoraEspacamento.md,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(Icons.restart_alt, color: cores.primaria),
                                const SizedBox(width: MemoraEspacamento.xs),
                                Flexible(
                                  child: TextoMemora(
                                    'Recomeçar',
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
                  )
                : null,
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
                    // Permanente, e no topo. Ver a nota da classe. Recolhido, é
                    // só um escudo de 48 dp: sem o respiro de cima e de baixo,
                    // para devolver o espaço à conversa.
                    Padding(
                      padding: avisoAberto
                          ? const EdgeInsets.all(MemoraEspacamento.md)
                          : const EdgeInsets.symmetric(
                              horizontal: MemoraEspacamento.md,
                            ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              altura * MemoraDimensoes.tetoDoAvisoAberto -
                              respiro,
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

                    Expanded(
                      child: ListView(
                        controller: _rolagem,
                        padding: const EdgeInsets.symmetric(
                          horizontal: MemoraEspacamento.lg,
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
                              ),
                              const SizedBox(height: MemoraEspacamento.md),
                            ],

                            for (int i = 0;
                                i < c.mensagens.length;
                                i++) ...<Widget>[
                              _fala(c, i),
                              const SizedBox(height: MemoraEspacamento.md),
                            ],

                            if (c.respondendo) ...<Widget>[
                              if (c.trechoEmCurso.isEmpty)
                                const BalaoDeFala.escrevendo()
                              else
                                // A mesma chave da mensagem em que este texto
                                // vai se transformar: a posição que ela terá.
                                BalaoDeFala(
                                  key: _chaveDaEscrita(c.mensagens.length),
                                  autor: AutorDoBalao.memora,
                                  texto: c.trechoEmCurso,
                                  escreverAosPoucos: true,
                                  emAndamento: true,
                                  aoEscrever: _rolarParaOFim,
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
                    if (!c.precisaDoAceite)
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
                                        : MemoraDimensoes
                                              .tetoDoCampoDaConversa) -
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
                                // Enquanto a Memora responde o botão fica no
                                // lugar, desabilitado (`podeEnviar` é falso): a
                                // espera aparece só no balão dela, e a faixa
                                // não muda de altura (FR-020b).
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

/// A explicação que antecede a primeira mensagem (FR-051).
///
/// Uma caixa de etapa: a frase que diz o que está acontecendo, o texto, e os
/// dois botões. O primário **aceita**; o secundário volta, e quem recusa
/// continua com o restante do Memora — Hub, catálogos e registro —, só sem a
/// conversa. Nenhum dos dois pode ser tratado como erro da pessoa.
class _ExplicacaoDoAceite extends StatelessWidget {
  final VoidCallback aoAceitar;
  final VoidCallback aoRecusar;

  const _ExplicacaoDoAceite({required this.aoAceitar, required this.aoRecusar});

  @override
  Widget build(BuildContext context) {
    return CaixaDeEtapa(
      key: TelaConversa.chaveAceite,
      instrucao: TextosAssistente.tituloAceite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
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

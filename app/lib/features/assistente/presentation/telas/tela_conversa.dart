import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_assistente.dart';
import '../../domain/assistente.dart';
import '../controladores/controlador_conversa.dart';

/// A conversa com a Memora (T038, US2).
///
/// ## O aviso antigolpe fica no topo, e não sai
///
/// A FR-033 exige aviso permanente, e a posição não é detalhe: quem está sendo
/// enganado ao telefone é conduzido direto ao campo de escrever. Aviso embaixo
/// da conversa só é lido por quem já não precisava dele.
///
/// É o mesmo idioma da `TelaRecuperacao`, de propósito — um aviso que a pessoa
/// reconhece vale mais que um aviso bem escrito.
///
/// ## A oferta de abrir passa por confirmação
///
/// Quando o controlador tem uma [ControladorConversa.acaoOferecida], ela chega
/// **já autorizada pelo servidor** (FR-022). Autorizado não é consentido: a
/// pessoa ainda precisa confirmar, e o texto diz exatamente o que vai
/// acontecer, incluindo que ela sairá do Memora (FR-015, FR-021).
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
  const TelaConversa({
    required this.controlador,
    this.aoVoltar,
    super.key,
  });

  @override
  State<TelaConversa> createState() => _TelaConversaState();
}

class _TelaConversaState extends State<TelaConversa> {
  final TextEditingController _campo = TextEditingController();
  final ScrollController _rolagem = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controlador.addListener(_aoMudar);
    widget.controlador.iniciar();
  }

  @override
  void dispose() {
    widget.controlador.removeListener(_aoMudar);
    _campo.dispose();
    _rolagem.dispose();
    super.dispose();
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

        return Scaffold(
          backgroundColor: cores.fundo,
          appBar: BarraSuperior(
            titulo: TextosAssistente.tituloConversa,
            aoVoltar: widget.aoVoltar,
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                // Permanente, e no topo. Ver a nota da classe.
                Padding(
                  padding: const EdgeInsets.all(MemoraEspacamento.lg),
                  child: _AvisoAntigolpe(),
                ),

                Expanded(
                  child: ListView(
                    controller: _rolagem,
                    padding: const EdgeInsets.symmetric(
                      horizontal: MemoraEspacamento.lg,
                    ),
                    children: <Widget>[
                      if (c.mensagens.isEmpty)
                        const TextoMemora(TextosAssistente.convite),

                      for (final MensagemDaConversa m in c.mensagens) ...<Widget>[
                        _Balao(mensagem: m),
                        const SizedBox(height: MemoraEspacamento.md),
                      ],

                      if (c.respondendo) ...<Widget>[
                        _Balao(
                          mensagem: MensagemDaConversa(
                            autor: AutorDaMensagem.memora,
                            texto: c.trechoEmCurso.isEmpty
                                ? TextosAssistente.pensando
                                : c.trechoEmCurso,
                            momento: DateTime.now(),
                          ),
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
                          rotuloRecusar: TextosAssistente.botaoPrefiroTentar,
                          aoConfirmar: c.confirmarAcao,
                          aoRecusar: c.recusarAcao,
                        ),
                        const SizedBox(height: MemoraEspacamento.md),
                      ],
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(MemoraEspacamento.lg),
                  // Mesmo teto que o aviso, e pelo mesmo motivo (ver a nota
                  // do T070 em `_AvisoAntigolpe`): o rótulo e a ajuda do
                  // `CampoTexto` crescem junto com o texto, e sozinhos já
                  // empurravam o botão de enviar para fora da tela em 200%.
                  // Acima do teto, rolar esta faixa alcança o botão — mesma
                  // linguagem de interação que a lista de mensagens já usa.
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
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
                            const Carregando(mensagem: TextosAssistente.pensando)
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
            ),
          ),
        );
      },
    );
  }
}

/// O aviso permanente da FR-033.
///
/// Mesmo desenho do aviso da tela de recuperação: borda de perigo, escudo, sem
/// preenchimento forte. Informação de alta importância continua sendo
/// informação, e não usa a linguagem de ação.
class _AvisoAntigolpe extends StatelessWidget {
  /// Teto de altura, com o texto passando a rolar **dentro da própria caixa**
  /// depois dele.
  ///
  /// Achado ao escrever o T070: sem teto, este aviso sozinho vai de 364 px
  /// (escala 1.0) para **1324 px** em 390×844 na escala 2.0 — mais alto que a
  /// tela inteira, derrubando campo de mensagem e botão de enviar para fora
  /// dela. A FR-027 exige que a conversa continue utilizável em 200%, e o
  /// aviso não pode simplesmente encolher ou resumir o texto: a FR-033 exige
  /// o aviso completo, sempre.
  ///
  /// A rolagem interna resolve as duas coisas: o aviso continua permanente
  /// (nunca desaparece, nunca fecha) e o texto inteiro continua alcançável,
  /// só que sem competir pelo espaço do resto da tela. Em 100%, 364 px cabe
  /// com folga dentro do teto — a aparência de hoje não muda.
  ///
  /// 420 px foi medido só no aparelho de 390 dp de largura. Um aparelho bem
  /// mais estreito quebraria a linha em mais pedaços e poderia se aproximar
  /// do teto já em 100%; vale medir num aparelho estreito de verdade antes de
  /// considerar isto fechado.
  static const double _alturaMaxima = 420;

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Semantics(
      key: TelaConversa.chaveAviso,
      button: false,
      readOnly: true,
      label: TextosAssistente.tituloAvisoAntigolpe,
      value: TextosAssistente.avisoAntigolpe,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: _alturaMaxima),
          padding: const EdgeInsets.all(MemoraEspacamento.md),
          decoration: BoxDecoration(
            color: cores.superficieAlt,
            borderRadius: BorderRadius.circular(MemoraRaio.padrao),
            border: Border.all(color: cores.perigo, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.shield_outlined, size: 24, color: cores.perigo),
              const SizedBox(width: MemoraEspacamento.sm),
              Expanded(
                child: SingleChildScrollView(
                  child: TextoMemora.apoio(TextosAssistente.avisoAntigolpe),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uma fala da conversa.
///
/// Quem falou é dito por **posição, cor e rótulo** — nunca só por cor, que o
/// Princípio III proíbe como único portador de significado.
class _Balao extends StatelessWidget {
  final MensagemDaConversa mensagem;

  const _Balao({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final bool daMemora = mensagem.autor == AutorDaMensagem.memora;

    return Align(
      alignment: daMemora ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(MemoraEspacamento.md),
        decoration: BoxDecoration(
          color: daMemora ? cores.superficieAlt : cores.superficie,
          borderRadius: BorderRadius.circular(MemoraRaio.padrao),
          border: Border.all(color: cores.borda),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextoMemora.apoio(daMemora ? 'Memora' : 'Você'),
            const SizedBox(height: MemoraEspacamento.xs),
            TextoMemora(mensagem.texto),
          ],
        ),
      ),
    );
  }
}

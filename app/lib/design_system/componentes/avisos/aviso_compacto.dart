import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
import '../../tokens/elevacao.dart';
import '../../tokens/espacamento.dart';
import '../../tokens/raio.dart';
import '../botoes/botao_terciario.dart';
import '../ilustracao/memora_personagem.dart';
import '../texto/texto_memora.dart';

/// O aviso de segurança que fica sempre na tela, sem tomar a tela (R5).
///
/// ## O problema que ele resolve
///
/// Os avisos permanentes das features 001 e 003 estavam certos e grandes
/// demais: na conversa, com o texto ampliado, as faixas de aviso podiam tomar
/// quase 90% da altura, e a conversa ficava espremida no que sobrava. Aviso
/// que ocupa a tela inteira deixa de ser lido na terceira vez.
///
/// ## Compacto não é escondido
///
/// - **O [titulo] está sempre na árvore** — é o que os portões das FR-023 da
///   001 e FR-033 da 003 procuram. Fechado, ele está sempre à vista; aberto,
///   ele rola junto com o texto, porque fixo ele e o botão sozinhos já
///   passavam da metade da tela a 200% num 320×568.
/// - **O [resumo] aparece fechado**, inteiro, para o aviso dizer alguma coisa
///   mesmo sem ser aberto. Nunca cortado: o resumo é o que a maioria lê.
/// - **Aberto, não passa de [MemoraDimensoes.tetoDoAvisoAberto] da altura que
///   sobra da tela**, descontado o teclado; o resto rola por dentro. Fração, e
///   não pixel — a lição do teto da conversa.
/// - **Começa fechado a cada montagem**, salvo [abertoNoComeco]. Quem abriu
///   uma vez não deixa o aviso aberto para sempre, virando paisagem.
///
/// ## A conversa: aberto até a primeira mensagem, depois uma linha (T118)
///
/// Com [abertoNoComeco] e [fechadoEmUmaLinha], o aviso nasce aberto e, quando
/// quem usa o recria fechado (outra `key`), vira **uma linha**: o escudo e o
/// [resumo], que a pessoa toca para ler inteiro. Encolher é o que a revisão da
/// T044 pediu; **sumir** foi recusado — o golpista pressiona a pessoa durante
/// a conversa, e "feche esse aviso" é o que ele pediria. Por isso este
/// componente **não tem** como ser dispensado: nem botão, nem gesto.
///
/// ## A conversa, depois da primeira pergunta: só o escudo (T130)
///
/// Com [fechadoSoEscudo], fechado, o aviso **não tem texto nenhum na tela**:
/// é um escudo vermelho num canto, com alvo de 48 dp, que a pessoa toca para ler
/// os avisos inteiros. A linha com o núcleo ("senha" e "código") tomava espaço
/// demais num aparelho pequeno, e a decisão do Henrique (2026-10-21) foi trocá-la
/// pelo escudo — **risco aceito**: quem enxerga, e está sob pressão ao
/// telefone, deixa de ver a frase sem tocar.
///
/// O núcleo continua **para o leitor de tela**, no rótulo do escudo, e o aviso
/// continua sem poder sumir: nem botão, nem gesto.
///
/// ## É informação
///
/// Borda em `perigo` e fundo neutro, como o `AvisoAntigolpe` sempre foi:
/// preenchimento forte o leria como botão (FR-012 da 002). A única ação é o
/// "Ler o aviso inteiro", que é um botão terciário de verdade.
///
/// ## Não é um texto genérico
///
/// Este componente é a moldura. A frase de cada aviso continua num lugar só
/// (`l10n/`), dita sempre igual — é isso que a torna reconhecível.
class AvisoCompacto extends StatefulWidget {
  /// O que o aviso é, em poucas palavras. Sempre visível.
  final String titulo;

  /// Uma linha, visível fechado.
  final String resumo;

  /// O aviso inteiro, visível aberto.
  final String textoCompleto;

  /// O rosto preocupado da Memora ao lado do título.
  final bool comMemora;

  /// Nasce aberto, em vez de fechado.
  final bool abertoNoComeco;

  /// Fechado, mostra **uma linha** — o escudo e o [resumo], tocável — em vez
  /// do título, do resumo e do botão "Ler o aviso inteiro". O [resumo] precisa
  /// então carregar o núcleo do aviso, e conter o [titulo]: é a única coisa
  /// que a maioria vai ler (FR-049).
  final bool fechadoEmUmaLinha;

  /// Fechado, mostra **só o escudo**, num canto e sem moldura, em vez do
  /// título, do resumo e do botão "Ler o aviso inteiro". O [resumo] vai no
  /// rótulo do escudo, para o leitor de tela (FR-022, FR-049, T130). Prevalece
  /// sobre [fechadoEmUmaLinha].
  final bool fechadoSoEscudo;

  /// Cria o aviso.
  const AvisoCompacto({
    required this.titulo,
    required this.resumo,
    required this.textoCompleto,
    this.comMemora = true,
    this.abertoNoComeco = false,
    this.fechadoEmUmaLinha = false,
    this.fechadoSoEscudo = false,
    super.key,
  });

  /// Chave do controle de abrir e fechar, para os testes.
  static const Key chaveAlternar = Key('aviso_compacto.alternar');

  /// Chave da área do texto completo, para os testes.
  static const Key chaveTextoCompleto = Key('aviso_compacto.texto_completo');

  /// Rótulo do controle, fechado.
  static const String rotuloAbrir = 'Ler o aviso inteiro';

  /// Rótulo do controle, aberto.
  static const String rotuloFechar = 'Mostrar menos';

  @override
  State<AvisoCompacto> createState() => _AvisoCompactoState();
}

class _AvisoCompactoState extends State<AvisoCompacto> {
  late bool _aberto = widget.abertoNoComeco;

  void _alternar() => setState(() => _aberto = !_aberto);

  /// A linha única: escudo, núcleo do aviso e uma seta, tudo um alvo só.
  Widget _linha(MemoraCores cores) {
    return Semantics(
      button: true,
      onTap: _alternar,
      label: widget.resumo,
      hint: AvisoCompacto.rotuloAbrir,
      excludeSemantics: true,
      child: InkWell(
        key: AvisoCompacto.chaveAlternar,
        onTap: _alternar,
        borderRadius: BorderRadius.circular(MemoraRaio.padrao),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: MemoraDimensoes.alvoMinimo,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.shield_outlined,
                size: MemoraDimensoes.iconeDestaque,
                color: cores.perigo,
              ),
              const SizedBox(width: MemoraEspacamento.sm),
              Expanded(child: TextoMemora.apoio(widget.resumo)),
              const SizedBox(width: MemoraEspacamento.sm),
              Icon(
                Icons.expand_more_rounded,
                size: MemoraDimensoes.iconePadrao,
                color: cores.texto,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Só o escudo, no canto de cima à direita: um botão de 48 dp, sem texto.
  ///
  /// O resumo é o rótulo para o leitor de tela. `button: true` sozinho não
  /// basta: sem `onTap` na própria `Semantics`, o TalkBack anuncia o botão e o
  /// duplo-toque não ativa nada.
  Widget _soEscudo(MemoraCores cores) {
    return Align(
      alignment: Alignment.centerRight,
      heightFactor: 1,
      child: Semantics(
        button: true,
        onTap: _alternar,
        label: widget.resumo,
        hint: AvisoCompacto.rotuloAbrir,
        excludeSemantics: true,
        child: InkWell(
          key: AvisoCompacto.chaveAlternar,
          onTap: _alternar,
          customBorder: const CircleBorder(),
          // Tamanho fixo, e não "no mínimo": um `Center` dentro de um mínimo
          // se estica até o máximo que o pai oferece, e o escudo tomava a
          // altura toda que o aviso aberto teria.
          child: SizedBox(
            width: MemoraDimensoes.alvoMinimo,
            height: MemoraDimensoes.alvoMinimo,
            child: Center(
              child: Icon(
                Icons.shield_outlined,
                size: MemoraDimensoes.iconeDestaque,
                color: cores.perigo,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabeca(MemoraCores cores) {
    return Row(
      children: <Widget>[
        if (widget.comMemora) ...<Widget>[
          const MemoraPersonagem(
            expressao: ExpressaoDaMemora.preocupada,
            tamanho: MemoraDimensoes.pisoDeIlustracao,
          ),
          const SizedBox(width: MemoraEspacamento.sm),
        ] else ...<Widget>[
          Icon(
            Icons.shield_outlined,
            size: MemoraDimensoes.iconeDestaque,
            color: cores.perigo,
          ),
          const SizedBox(width: MemoraEspacamento.sm),
        ],
        Expanded(
          child: TextoMemora(
            widget.titulo,
            estilo: EstiloTexto.corpoForte,
            cabecalho: true,
          ),
        ),
      ],
    );
  }

  /// O botão de fechar do aviso aberto, com um teto de altura.
  ///
  /// Fixo, para a saída estar sempre à mão; mas limitado a uma fração do que
  /// o aviso tem ([alturaDoAviso]), para nunca tomar a caixa inteira — o texto
  /// rola no resto, e o botão rola dentro do teto dele só nos casos extremos
  /// (200% num aparelho baixo). A altura vem de fora da `Column`, porque a
  /// `Column` oferece altura infinita a quem não é flexível. Onde ela também é
  /// infinita (dentro de uma lista), não há teto a respeitar.
  Widget _botaoDeFecharComTeto(Widget botao, double alturaDoAviso) {
    if (!alturaDoAviso.isFinite) return botao;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: alturaDoAviso * MemoraDimensoes.tetoDoBotaoDoAvisoAberto,
      ),
      child: SingleChildScrollView(child: botao),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final bool modoPilula = !_aberto && widget.fechadoEmUmaLinha;
    // O que SOBRA da tela, e não a tela: a altura não diminui com o teclado,
    // e num 360x640 com o teclado aberto metade da tela era quase toda a área
    // útil (revisão da #38). O aviso vive dentro de lista que rola, onde a
    // altura que o pai oferece é infinita — por isso a conta parte da tela.
    //
    // O teclado vem da janela (`View`), e não do `MediaQuery`: o `Scaffold`
    // tira o teclado do `MediaQuery` que entrega ao corpo, e de dentro dele o
    // aviso nunca o veria.
    final double teclado = MediaQueryData.fromView(
      View.of(context),
    ).viewInsets.bottom;
    final double sobra = MediaQuery.sizeOf(context).height - teclado;
    final double teto = sobra * MemoraDimensoes.tetoDoAvisoAberto;

    if (!_aberto && widget.fechadoSoEscudo) return _soEscudo(cores);

    final Widget botao = Align(
      alignment: Alignment.centerLeft,
      child: BotaoTerciario(
        key: AvisoCompacto.chaveAlternar,
        rotulo: _aberto
            ? AvisoCompacto.rotuloFechar
            : AvisoCompacto.rotuloAbrir,
        aoTocar: _alternar,
      ),
    );

    return Container(
      width: double.infinity,
      constraints: _aberto ? BoxConstraints(maxHeight: teto) : null,
      padding: modoPilula
          ? const EdgeInsets.symmetric(
              horizontal: MemoraEspacamento.md,
              vertical: MemoraEspacamento.xs,
            )
          : const EdgeInsets.all(MemoraEspacamento.md),
      decoration: BoxDecoration(
        color: cores.superficie,
        borderRadius: BorderRadius.circular(
          modoPilula ? MemoraRaio.pilula : MemoraRaio.cartaoMedio,
        ),
        // A borda em perigo (ou enfática no alto contraste) garante
        // reconhecimento imediato sem recorrer a preenchimento pesado.
        border: Border.all(
          color: ehAltoContraste ? cores.borda : cores.perigo,
          width: ehAltoContraste
              ? MemoraDimensoes.bordaEnfase
              : MemoraDimensoes.espessuraBordaSutil,
        ),
        boxShadow: MemoraElevacao.listaSombrasCartao(cores),
      ),
      child: modoPilula
          ? _linha(cores)
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints restricoes) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Aberto, o título rola junto com o texto, e só o botão fica fixo.
                  // A primeira versão deixava título e botão fixos e o texto rolando
                  // entre os dois: a 200% num 320×568, as partes fixas sozinhas já
                  // passavam da metade da tela, e o aviso estourava 225 px. O título
                  // continua na árvore — que é o que os portões procuram.
                  if (_aberto)
                    Flexible(
                      child: SingleChildScrollView(
                        key: AvisoCompacto.chaveTextoCompleto,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _cabeca(cores),
                            const SizedBox(height: MemoraEspacamento.xs),
                            TextoMemora.apoio(widget.textoCompleto),
                          ],
                        ),
                      ),
                    )
                  else ...<Widget>[
                    _cabeca(cores),
                    const SizedBox(height: MemoraEspacamento.xs),
                    TextoMemora(widget.resumo),
                  ],
                  _aberto
                      ? _botaoDeFecharComTeto(botao, restricoes.maxHeight)
                      : botao,
                ],
              ),
            ),
    );
  }
}

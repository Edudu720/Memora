import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/dimensoes.dart';
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
/// - **O [resumo] aparece fechado**, numa linha, para o aviso dizer alguma
///   coisa mesmo sem ser aberto.
/// - **Aberto, não passa de [MemoraDimensoes.tetoDoAvisoAberto] da altura da
///   tela**; o resto rola por dentro. Fração, e não pixel — a lição do teto da
///   conversa.
/// - **Começa fechado a cada montagem.** Quem abriu uma vez não deixa o aviso
///   aberto para sempre, virando paisagem.
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

  /// Cria o aviso.
  const AvisoCompacto({
    required this.titulo,
    required this.resumo,
    required this.textoCompleto,
    this.comMemora = true,
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
  bool _aberto = false;

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

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final double teto =
        MediaQuery.sizeOf(context).height * MemoraDimensoes.tetoDoAvisoAberto;

    return Container(
      width: double.infinity,
      constraints: _aberto ? BoxConstraints(maxHeight: teto) : null,
      padding: const EdgeInsets.all(MemoraEspacamento.md),
      decoration: BoxDecoration(
        color: cores.superficieAlt,
        borderRadius: BorderRadius.circular(MemoraRaio.padrao),
        // A borda separa o bloco sem recorrer a preenchimento forte.
        border: Border.all(
          color: cores.perigo,
          width: MemoraDimensoes.bordaEnfase,
        ),
      ),
      child: Column(
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
                    TextoMemora(widget.textoCompleto),
                  ],
                ),
              ),
            )
          else ...<Widget>[
            _cabeca(cores),
            const SizedBox(height: MemoraEspacamento.xs),
            TextoMemora(widget.resumo, maxLinhas: 2),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: BotaoTerciario(
              key: AvisoCompacto.chaveAlternar,
              rotulo: _aberto
                  ? AvisoCompacto.rotuloFechar
                  : AvisoCompacto.rotuloAbrir,
              aoTocar: () => setState(() => _aberto = !_aberto),
            ),
          ),
        ],
      ),
    );
  }
}

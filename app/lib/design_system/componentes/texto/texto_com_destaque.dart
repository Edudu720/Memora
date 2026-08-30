import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/cores.dart';
import '../../tokens/tipografia.dart';
import 'texto_memora.dart';

/// Frase com palavras-chave realçadas, como nas telas do protótipo.
///
/// Marque o trecho com asteriscos: `'Você se sente *confiante* ao usar'`.
///
/// ## Por que asterisco, e não uma lista de trechos
///
/// A frase mora em `l10n/`, e quem a escreve pensa na frase inteira. Uma lista
/// de pedaços separaria o texto do lugar onde ele é realçado, e no dia da
/// tradução alguém teria que remontar os dois.
///
/// ## O destaque é peso e cor, nunca sublinhado
///
/// Sublinhado significa link em toda parte, e estas palavras **não são
/// tocáveis**. Para quem tem pouca familiaridade, tocar e não acontecer nada é
/// indistinguível de aparelho quebrado — por isso há teste garantindo que
/// nenhum destaque responde ao toque.
///
/// Ainda assim, cor primária em texto corrido é um risco conhecido: azul é a
/// cor das ações no Memora. Vale observar no V10, com as 5 pessoas de 65+ do
/// `quickstart.md`, se alguém tenta tocar nas palavras realçadas.
class TextoComDestaque extends StatelessWidget {
  /// O texto, com os trechos realçados entre asteriscos.
  final String texto;

  /// Papel do texto na interface.
  final EstiloTexto estilo;

  /// Cor do texto comum. Quando omitida, usa a do tema.
  final Color? cor;

  /// Cor dos trechos realçados. Quando omitida, usa a primária do tema.
  final Color? corDoDestaque;

  /// Alinhamento horizontal.
  final TextAlign? alinhamento;

  /// Cria um texto com destaques.
  const TextoComDestaque(
    this.texto, {
    this.estilo = EstiloTexto.corpo,
    this.cor,
    this.corDoDestaque,
    this.alinhamento,
    super.key,
  });

  /// Separa o texto em trechos, alternando comum e realçado.
  ///
  /// Um asterisco sozinho, sem par, fica no texto como caractere comum: perder
  /// a frase inteira por causa de um símbolo digitado a mais seria pior que
  /// exibir o símbolo.
  static List<(String, bool)> trechos(String texto) {
    final List<(String, bool)> resultado = <(String, bool)>[];
    final List<String> partes = texto.split('*');

    for (int i = 0; i < partes.length; i++) {
      if (partes[i].isEmpty) continue;
      // Índice ímpar é o que está *entre* asteriscos. O último pedaço nunca é
      // destaque quando a contagem é par — é o asterisco solto.
      final bool destaque =
          i.isOdd && (partes.length.isOdd || i < partes.length - 1);
      resultado.add((partes[i], destaque));
    }
    return resultado;
  }

  TextStyle get _base => switch (estilo) {
    EstiloTexto.tituloTela => MemoraTipografia.tituloTela,
    EstiloTexto.tituloSecao => MemoraTipografia.tituloSecao,
    EstiloTexto.corpo => MemoraTipografia.corpo,
    EstiloTexto.corpoForte => MemoraTipografia.corpoForte,
    EstiloTexto.apoio => MemoraTipografia.apoio,
  };

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;
    final Color corComum =
        cor ?? (estilo == EstiloTexto.apoio ? cores.textoSuave : cores.texto);
    final Color corRealce = corDoDestaque ?? cores.primaria;

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          for (final (String parte, bool destaque) in trechos(texto))
            TextSpan(
              text: parte,
              style: destaque
                  ? _base.copyWith(
                      color: corRealce,
                      fontWeight: FontWeight.w700,
                    )
                  : _base.copyWith(color: corComum),
            ),
        ],
      ),
      textAlign: alinhamento,
      // O mesmo teto de ampliação dos demais textos. Sem ele, este componente
      // divergiria do resto da tela em ampliação extrema.
      textScaler: escalaTextoLimitada(context),
      // O leitor de tela lê a frase inteira e corrida, sem os asteriscos e sem
      // anunciar a troca de estilo — o realce é informação visual, e repeti-la
      // em voz só atrapalharia.
      semanticsLabel: texto.replaceAll('*', ''),
    );
  }
}

import '../../assistente/domain/assistente.dart';

/// A busca de "Meus aplicativos" (T068).
///
/// Tem de achar o que a pessoa quis dizer, não o que ela digitou certinho:
/// quem escreve devagar, no teclado do celular, erra acento e maiúscula o
/// tempo todo. Por isso a comparação é por **trecho**, **sem acento** e **sem
/// diferenciar maiúscula** — "tik" acha TikTok, "video" acha "Ver vídeos".

/// Os caracteres acentuados que o português e os nomes de aplicativos trazem,
/// e o que cada um vira na comparação.
const Map<String, String> _semAcento = <String, String>{
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
  'ý': 'y',
  'ÿ': 'y',
};

/// Põe [texto] na forma de comparação: minúsculas, sem acento (inclusive o
/// acento "solto", como caractere combinante), com a pontuação virando espaço
/// e os espaços do começo, do fim e do meio reduzidos a um.
String normalizarParaBusca(String texto) {
  final StringBuffer saida = StringBuffer();
  for (final int runa in texto.toLowerCase().runes) {
    // U+0300 a U+036F: marcas combinantes (o acento digitado separado da letra).
    if (runa >= 0x0300 && runa <= 0x036F) continue;
    final String c = String.fromCharCode(runa);
    saida.write(_semAcento[c] ?? c);
  }
  return saida
      .toString()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .join(' ');
}

/// Os itens de [servicos] que respondem a [consulta], na ordem em que vieram.
///
/// - Consulta vazia (ou só espaços) devolve **todos**: apagar o que se
///   digitou volta à grade inteira.
/// - Procura no nome e na descrição curta.
/// - Mais de uma palavra: **todas** precisam aparecer (cada uma como trecho),
///   em qualquer ordem — "video tik" acha o TikTok se a descrição disser vídeo.
List<ServicoDoCatalogo> buscarServicos(
  List<ServicoDoCatalogo> servicos,
  String consulta,
) {
  final String normalizada = normalizarParaBusca(consulta);
  if (normalizada.isEmpty) return List<ServicoDoCatalogo>.of(servicos);

  final List<String> palavras = normalizada.split(' ');
  // A versão sem espaços ("govbr" acha "Gov.br"; "gov br" acha "Gov.br").
  final String colada = normalizada.replaceAll(' ', '');
  return servicos.where((ServicoDoCatalogo s) {
    final String alvo = normalizarParaBusca(
      '${s.nomeExibido} ${s.descricaoCurta}',
    );
    return palavras.every(alvo.contains) ||
        alvo.replaceAll(' ', '').contains(colada);
  }).toList();
}

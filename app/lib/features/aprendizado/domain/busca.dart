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

/// Põe [texto] na forma de comparação: minúsculas, sem acento e com os espaços
/// do começo, do fim e do meio reduzidos a um.
String normalizarParaBusca(String texto) {
  final StringBuffer saida = StringBuffer();
  for (final int runa in texto.toLowerCase().runes) {
    final String c = String.fromCharCode(runa);
    saida.write(_semAcento[c] ?? c);
  }
  return saida.toString().trim().split(RegExp(r'\s+')).join(' ');
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
  return servicos.where((ServicoDoCatalogo s) {
    final String alvo = normalizarParaBusca(
      '${s.nomeExibido} ${s.descricaoCurta}',
    );
    return palavras.every(alvo.contains);
  }).toList();
}

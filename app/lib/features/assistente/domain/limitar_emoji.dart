/// Garante no máximo um emoji por fala da assistente (FR-024, T041).
///
/// A instrução da persona no servidor já orienta o modelo a usar no máximo um
/// emoji por mensagem, mas a interface não pode depender só da obediência do
/// modelo. Esta função pura mantém apenas o primeiro emoji (incluindo emojis
/// compostos com modificador de tom de pele ou junção ZWJ) e remove os
/// seguintes sem deixar espaços sobrando.
String limitarEmoji(String texto) {
  final List<RegExpMatch> emojis = _regExpEmoji.allMatches(texto).toList();
  if (emojis.length <= 1) return texto;

  final StringBuffer saida = StringBuffer();
  int cursor = 0;

  void escreverTrecho(String trecho, {required bool aposRemocao}) {
    if (trecho.isEmpty) return;
    if (!aposRemocao) {
      saida.write(trecho);
      return;
    }

    int inicio = 0;
    final String acumulado = saida.toString();
    final bool inicioDeLinha =
        acumulado.isEmpty || acumulado.endsWith('\n') || acumulado.endsWith('\r');
    final bool terminaComEspaco = _terminaComEspacoHorizontal(acumulado);

    if (terminaComEspaco &&
        (_ehEspacoHorizontal(trecho[0]) ||
            _ehQuebraDeLinha(trecho[0]) ||
            _ehPontuacaoColada(trecho[0]))) {
      // Remove o espaço horizontal imediatamente anterior ao emoji removido
      // para evitar espaço duplo ou espaço antes de pontuação/quebra de linha.
      final String semEspaco = _removerEspacoHorizontalFinal(acumulado);
      saida
        ..clear()
        ..write(semEspaco);
      if (_ehEspacoHorizontal(trecho[0]) && !inicioDeLinha && !_terminaComQuebra(semEspaco)) {
        // Mantém exatamente um espaço separando as palavras dos dois lados.
        saida.write(' ');
      }
      while (inicio < trecho.length && _ehEspacoHorizontal(trecho[inicio])) {
        inicio++;
      }
    } else if (inicioDeLinha) {
      while (inicio < trecho.length && _ehEspacoHorizontal(trecho[inicio])) {
        inicio++;
      }
    }

    saida.write(trecho.substring(inicio));
  }

  for (int i = 1; i < emojis.length; i++) {
    final RegExpMatch atual = emojis[i];
    final String trecho = texto.substring(cursor, atual.start);
    escreverTrecho(trecho, aposRemocao: i > 1);
    cursor = atual.end;

    // Se dois emojis removidos estão separados apenas por espaços, já reduzimos
    // o rastro antes de seguir.
    if (saida.isNotEmpty &&
        cursor == texto.length &&
        _terminaComEspacoHorizontal(saida.toString())) {
      final String semEspaco = _removerEspacoHorizontalFinal(saida.toString());
      saida
        ..clear()
        ..write(semEspaco);
    }
  }

  final String cauda = texto.substring(cursor);
  if (cauda.isEmpty) {
    final String acumulado = saida.toString();
    if (_terminaComEspacoHorizontal(acumulado)) {
      final String semEspaco = _removerEspacoHorizontalFinal(acumulado);
      saida
        ..clear()
        ..write(semEspaco);
    }
  } else {
    escreverTrecho(cauda, aposRemocao: true);
  }

  return saida.toString();
}

/// A propriedade Unicode dos pictogramas fica numa constante separada porque o
/// lint `valid_regexps` analisa o literal com `unicode: false` e acusa falso
/// positivo sobre `\p{Extended_Pictographic}`.
const String _pictograma = r'\p{Extended_Pictographic}';

const String _tomDePele = r'[\u{1F3FB}-\u{1F3FF}]';
const String _variacao = r'[\uFE0F\uFE0E]';
const String _bandeira = r'[\u{1F1E6}-\u{1F1FF}]{2}';
const String _tecla = r'[0-9#*]\uFE0F?\u20E3';

final RegExp _regExpEmoji = RegExp(
  '(?:$_bandeira|$_tecla|$_pictograma$_variacao?$_tomDePele?)'
  r'(?:\u200D'
  '(?:$_bandeira|$_pictograma$_variacao?$_tomDePele?))*',
  unicode: true,
);

bool _ehEspacoHorizontal(String ch) => ch == ' ' || ch == '\t';

bool _ehQuebraDeLinha(String ch) => ch == '\n' || ch == '\r';

bool _terminaComQuebra(String s) =>
    s.endsWith('\n') || s.endsWith('\r');

bool _terminaComEspacoHorizontal(String s) =>
    s.isNotEmpty && _ehEspacoHorizontal(s[s.length - 1]);

bool _ehPontuacaoColada(String ch) =>
    ch == '.' ||
    ch == ',' ||
    ch == '!' ||
    ch == '?' ||
    ch == ';' ||
    ch == ':' ||
    ch == ')';

String _removerEspacoHorizontalFinal(String s) {
  int fim = s.length;
  while (fim > 0 && _ehEspacoHorizontal(s[fim - 1])) {
    fim--;
  }
  return s.substring(0, fim);
}

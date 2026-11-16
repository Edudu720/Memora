import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Portão do texto da interface (feature 010, T028; FR-016, FR-018, FR-020).
///
/// Todo texto que a pessoa lê segue a skill `memora-ux`:
/// - **no máximo duas frases curtas por bloco** — o limite é de texto, não de
///   caixa: com a letra a 200% a caixa cresce, e o que mantém o bloco curto é
///   a frase curta;
/// - **nenhuma palavra que diminua a pessoa** ("idoso", "terceira idade"…) nem
///   frase de incapacidade;
/// - **nenhum emoji na interface** — emoji fica só na fala da IA, e o leitor de
///   tela lê cada um em voz alta.
///
/// É uma varredura lexical das constantes `static const String` dos arquivos
/// de texto. Literais concatenados (`'a ' 'b'`) contam como um bloco só.
///
/// **A lista de arquivos cresce por fase** (research.md, R12): na Fase A ela
/// cobre só os arquivos que a PR #71 não altera; a T068 estende a todos os de
/// `lib/l10n/` e dos guias, depois que a #71 entrar.
void main() {
  group('O próprio portão (autoteste das regras)', () {
    test('conta frases pelos terminadores seguidos de espaço ou fim', () {
      expect(contarFrases('Oi.'), 1);
      expect(contarFrases('Oi'), 1);
      expect(contarFrases('Fica só aqui. Você não precisa informar.'), 2);
      expect(contarFrases('Uma. Duas! Três?'), 3);
      expect(contarFrases('Espere… Já volto.'), 2);
      expect(contarFrases('Estou pensando...'), 1);
    });

    test('número, endereço e abreviação não partem a frase', () {
      expect(contarFrases('São 1.000 passos no gov.br hoje.'), 1);
      expect(contarFrases('Fale com o Dr. Paulo amanhã.'), 1);
      expect(contarFrases('Abra o site www.gov.br e entre.'), 1);
    });

    test('acha palavra e frase proibidas, sem confundir com palavra parecida', () {
      expect(palavrasProibidasEm('Feito para o idoso'), isNotEmpty);
      expect(palavrasProibidasEm('Para a pessoa IDOSA'), isNotEmpty);
      expect(palavrasProibidasEm('Na melhor idade'), isNotEmpty);
      expect(palavrasProibidasEm('Plano sênior'), isNotEmpty);
      expect(palavrasProibidasEm('Isso é difícil para você'), isNotEmpty);
      expect(palavrasProibidasEm('Vamos ver juntos'), isEmpty);
      expect(palavrasProibidasEm('Idade'), isEmpty);
      expect(palavrasProibidasEm('Senha'), isEmpty);
    });

    test('acha emoji, mas não sinais comuns de texto', () {
      expect(temEmoji('Pronto 😊'), isTrue);
      expect(temEmoji('Feito ✅'), isTrue);
      expect(temEmoji('Joia 👍🏽'), isTrue);
      expect(temEmoji('Olá, tudo bem? É 1 de 3.'), isFalse);
      expect(temEmoji('Ação — e mais: “aspas” (x)'), isFalse);
    });

    test('junta literais concatenados e desfaz o escape de aspas', () {
      const String fonte = '''
  static const String a = 'Uma frase. '
      'Outra frase.';
  static const String b = "Com 'aspas' dentro";
  static const String c = 'D\\'água';
''';
      final Map<String, String> blocos = extrairBlocos(fonte);
      expect(blocos['a'], 'Uma frase. Outra frase.');
      expect(blocos['b'], "Com 'aspas' dentro");
      expect(blocos['c'], "D'água");
    });
  });

  group('Os textos da interface (Fase A)', () {
    for (final String arquivo in arquivosVarridos) {
      test('$arquivo: blocos curtos, sem palavra proibida e sem emoji', () {
        final File fonte = File('lib/l10n/$arquivo');
        expect(fonte.existsSync(), isTrue, reason: 'rode na pasta app/');

        final Map<String, String> blocos =
            extrairBlocos(fonte.readAsStringSync());
        expect(blocos, isNotEmpty, reason: 'nenhum texto encontrado');

        final List<String> reprovados = <String>[];
        blocos.forEach((String nome, String texto) {
          if (excecoes.containsKey('$arquivo:$nome')) return;
          final int frases = contarFrases(texto);
          if (frases > 2) {
            reprovados.add('$nome: $frases frases — "$texto"');
          }
          for (final String p in palavrasProibidasEm(texto)) {
            reprovados.add('$nome: palavra proibida "$p" — "$texto"');
          }
          if (temEmoji(texto)) {
            reprovados.add('$nome: emoji na interface — "$texto"');
          }
        });

        expect(
          reprovados,
          isEmpty,
          reason: 'Reescreva na voz da Memora (memora-ux): no máximo duas '
              'frases; o excedente vira etapa ou "Saber mais", mas o '
              'necessário para decidir continua visível (FR-017).\n'
              '${reprovados.join('\n')}',
        );
      });
    }
  });
}

/// Os arquivos que este portão cobre. **Fase A**: só os que a #71 não altera.
/// A T068 acrescenta `textos_assistente.dart`, `textos_casca.dart`,
/// `textos_guias.dart` e os guias de `features/aprendizado/data/guias/`.
const List<String> arquivosVarridos = <String>[
  'textos_ajuda.dart',
  'textos_apresentacao.dart',
  'textos_autenticacao.dart',
  'textos_configuracoes.dart',
  'textos_perfil.dart',
];

/// Exceções, sempre com o motivo. Chave: `arquivo:constante`.
/// Vazio de propósito: toda exceção nova precisa de justificativa na revisão.
const Map<String, String> excecoes = <String, String>{};

/// Abreviações que terminam em ponto sem encerrar a frase.
const List<String> _abreviacoes = <String>['Sr', 'Sra', 'Dr', 'Dra', 'nº'];

/// Conta as frases de um bloco: cada `.`, `!`, `?` ou `…` (ou `...`) seguido
/// de espaço ou do fim encerra uma; um resto sem terminador conta como mais
/// uma. Ponto colado em letra ou número (`1.000`, `gov.br`) não encerra.
int contarFrases(String texto) {
  final String t = texto.trim();
  if (t.isEmpty) return 0;
  final RegExp fim = RegExp(r'(\.\.\.|[.!?…]+)(?=\s|$)');
  int frases = 0;
  int inicio = 0;
  for (final RegExpMatch m in fim.allMatches(t)) {
    final String antes = t.substring(inicio, m.start);
    final String ultimaPalavra = antes.split(RegExp(r'\s+')).last;
    if (m.group(0) == '.' && _abreviacoes.contains(ultimaPalavra)) continue;
    if (antes.trim().isNotEmpty) frases++;
    inicio = m.end;
  }
  if (t.substring(inicio).trim().isNotEmpty) frases++;
  return frases;
}

/// Palavras e frases que nunca aparecem na tela (memora-ux, seção 4).
const List<String> _proibidas = <String>[
  r'idos[oa]s?',
  r'terceira idade',
  r'melhor idade',
  r's[êe]nior(es)?',
  r'(é|e) dif[íi]cil para (voc[êe]|a senhora|o senhor)',
  r'n[ãa]o se preocupe se n[ãa]o entender',
  r'at[ée] voc[êe] consegue',
  r'modo simplificado',
];

/// Devolve as palavras ou frases proibidas encontradas no texto.
List<String> palavrasProibidasEm(String texto) {
  final List<String> achadas = <String>[];
  for (final String padrao in _proibidas) {
    final RegExp re = RegExp(
      '(?<![\\p{L}])($padrao)(?![\\p{L}])',
      caseSensitive: false,
      unicode: true,
    );
    final RegExpMatch? m = re.firstMatch(texto);
    if (m != null) achadas.add(m.group(0)!);
  }
  return achadas;
}

/// Verdadeiro se houver emoji (pictograma) no texto.
bool temEmoji(String texto) =>
    RegExp(r'\p{Extended_Pictographic}', unicode: true).hasMatch(texto);

/// Extrai `static const String nome = <literais>;` de um arquivo de texto,
/// juntando literais concatenados e desfazendo o escape das aspas.
Map<String, String> extrairBlocos(String fonte) {
  final RegExp declaracao = RegExp(
    r'static\s+const\s+String\s+(\w+)\s*=\s*((?:\s*(?:' +
        _literalSimples +
        r'|' +
        _literalDuplo +
        r'))+)\s*;',
    dotAll: true,
  );
  final RegExp literal = RegExp(_literalSimples + r'|' + _literalDuplo);
  final Map<String, String> blocos = <String, String>{};
  for (final RegExpMatch d in declaracao.allMatches(fonte)) {
    final StringBuffer texto = StringBuffer();
    for (final RegExpMatch l in literal.allMatches(d.group(2)!)) {
      final String bruto = l.group(0)!;
      texto.write(
        bruto
            .substring(1, bruto.length - 1)
            .replaceAll(r"\'", "'")
            .replaceAll(r'\"', '"'),
      );
    }
    blocos[d.group(1)!] = texto.toString();
  }
  return blocos;
}

const String _literalSimples = r"'(?:[^'\\]|\\.)*'";
const String _literalDuplo = r'"(?:[^"\\]|\\.)*"';

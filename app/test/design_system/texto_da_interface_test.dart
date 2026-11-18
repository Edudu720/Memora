import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/l10n/textos_anfitria.dart';

/// Portão do texto da interface (feature 013, T028; FR-016, FR-018, FR-020).
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
      // Cada terminador no meio do texto, para que tirar um deles reprove.
      expect(contarFrases('Tudo bem? Vamos lá.'), 2);
      expect(contarFrases('Pronto! Vamos lá.'), 2);
      expect(contarFrases('Pronto. Vamos lá.'), 2);
      expect(contarFrases('Espere… Já volto.'), 2);
      expect(contarFrases('Estou pensando...'), 1);
    });

    test('número, endereço e abreviação não partem a frase', () {
      expect(contarFrases('São 1.000 passos no gov.br hoje.'), 1);
      expect(contarFrases('Fale com o Dr. Paulo amanhã.'), 1);
      expect(contarFrases('Abra o site www.gov.br e entre.'), 1);
    });

    test(
      'acha palavra e frase proibidas, sem confundir com palavra parecida',
      () {
        expect(palavrasProibidasEm('Feito para o idoso'), isNotEmpty);
        expect(palavrasProibidasEm('Para a pessoa IDOSA'), isNotEmpty);
        expect(palavrasProibidasEm('Na melhor idade'), isNotEmpty);
        expect(palavrasProibidasEm('Plano sênior'), isNotEmpty);
        expect(palavrasProibidasEm('Isso é difícil para você'), isNotEmpty);
        expect(palavrasProibidasEm('Vamos ver juntos'), isEmpty);
        expect(palavrasProibidasEm('Idade'), isEmpty);
        expect(palavrasProibidasEm('Senha'), isEmpty);
      },
    );

    test('acha texto que supõe o gênero da pessoa, e não o da Memora', () {
      expect(
        palavrasProibidasEm('da próxima vez você consiga sozinha.'),
        isNotEmpty,
      );
      expect(
        palavrasProibidasEm('Você fez tudo sozinho até agora'),
        isNotEmpty,
      );
      expect(palavrasProibidasEm('Quero entrar sozinha'), isNotEmpty);
      expect(palavrasProibidasEm('Prefiro tentar sozinha'), isNotEmpty);
      expect(palavrasProibidasEm('Como você quer ser chamada'), isNotEmpty);
      expect(palavrasProibidasEm('Acontece, fica tranquila.'), isNotEmpty);
      expect(palavrasProibidasEm('Estou quase pronta.'), isEmpty);
      expect(palavrasProibidasEm('O story passa sozinho.'), isEmpty);
      expect(palavrasProibidasEm('Quero entrar por conta própria'), isEmpty);
      expect(palavrasProibidasEm('Como posso te chamar'), isEmpty);
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

  group('As dicas da anfitriã (T085, FR-050)', () {
    late Map<String, String> blocos;

    setUpAll(() {
      blocos = extrairBlocos(
        File('lib/l10n/textos_anfitria.dart').readAsStringSync(),
      );
    });

    /// Os blocos que são dicas: tudo o que o arquivo declara, menos o rótulo
    /// da ação (que é o que o leitor de tela diz do toque, e não uma dica).
    Map<String, String> dicasDoArquivo() => <String, String>{
      for (final MapEntry<String, String> e in blocos.entries)
        if (e.key != 'rotuloDaAcao') e.key: e.value,
    };

    test('há de 12 a 16 dicas, todas diferentes', () {
      expect(TextosAnfitria.dicas.length, inInclusiveRange(12, 16));
      expect(TextosAnfitria.dicas.toSet().length, TextosAnfitria.dicas.length);
    });

    test('a lista traz todas as dicas escritas no arquivo, e só elas', () {
      expect(
        TextosAnfitria.dicas.toSet(),
        dicasDoArquivo().values.toSet(),
        reason:
            'dica escrita e fora de `dicas` nunca aparece; dica em '
            '`dicas` e fora do arquivo escapa deste portao de texto',
      );
    });

    test('pelo menos 3 dicas são lembrete antigolpe', () {
      final List<String> antigolpe = dicasDoArquivo().entries
          .where((MapEntry<String, String> e) => e.key.startsWith('antigolpe'))
          .map((MapEntry<String, String> e) => e.value)
          .toList();
      expect(antigolpe.length, greaterThanOrEqualTo(3));
      for (final String dica in antigolpe) {
        expect(TextosAnfitria.dicas, contains(dica));
      }
      expect(
        antigolpe.any((String d) => d.contains('Eu nunca peço')),
        isTrue,
        reason: 'o lembrete da FR-050 ("Eu nunca peço sua senha nem código")',
      );
    });

    test('o rótulo da ação é o que a FR-055 pede', () {
      expect(TextosAnfitria.rotuloDaAcao, 'Outra dica da Memora');
    });
  });

  group('Os textos da interface (T068: toda lib/l10n e guias)', () {
    test('todo arquivo em lib/l10n/ está coberto pela varredura', () {
      final Set<String> noDisco = Directory('lib/l10n')
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.dart'))
          .map((File f) => f.path.replaceAll('\\', '/').split('/').last)
          .toSet();
      expect(arquivosVarridos.toSet(), noDisco);
    });

    for (final String arquivo in arquivosVarridos) {
      test('$arquivo: blocos curtos, sem palavra proibida e sem emoji', () {
        final File fonte = File('lib/l10n/$arquivo');
        expect(fonte.existsSync(), isTrue, reason: 'rode na pasta app/');

        final String codigo = fonte.readAsStringSync();
        final Map<String, String> blocos = extrairBlocos(codigo);
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

        // Garante também ausência de emoji ou termo proibido em helpers (static String).
        final List<String> linhas = codigo.split('\n');
        for (int i = 0; i < linhas.length; i++) {
          final String semComentario = linhas[i].split('//').first;
          if (temEmoji(semComentario)) {
            reprovados.add('linha ${i + 1}: emoji fora de constante');
          }
          for (final String p in palavrasProibidasEm(semComentario)) {
            reprovados.add('linha ${i + 1}: palavra proibida "$p"');
          }
        }

        expect(
          reprovados,
          isEmpty,
          reason:
              'Reescreva na voz da Memora (memora-ux): no máximo duas '
              'frases; o excedente vira etapa ou "Saber mais", mas o '
              'necessário para decidir continua visível (FR-017).\n'
              '${reprovados.join('\n')}',
        );
      });
    }

    test(
      'todos os guias em features/aprendizado/data/guias/ respeitam o limite',
      () {
        final List<File> guias =
            Directory('lib/features/aprendizado/data/guias')
                .listSync()
                .whereType<File>()
                .where((File f) => f.path.endsWith('.dart'))
                .toList()
              ..sort((File a, File b) => a.path.compareTo(b.path));
        expect(guias, isNotEmpty);

        final RegExp literal = RegExp(_literalSimples + r'|' + _literalDuplo);
        final List<String> reprovados = <String>[];

        for (final File guia in guias) {
          final List<String> linhas = guia.readAsLinesSync();
          for (int i = 0; i < linhas.length; i++) {
            final String codigo = linhas[i].split('//').first;
            for (final RegExpMatch m in literal.allMatches(codigo)) {
              final String bruto = m.group(0)!;
              final String texto = bruto
                  .substring(1, bruto.length - 1)
                  .replaceAll(r"\'", "'")
                  .replaceAll(r'\"', '"');
              final int frases = contarFrases(texto);
              if (frases > 2) {
                reprovados.add(
                  '${guia.path}:${i + 1}: $frases frases — "$texto"',
                );
              }
              for (final String p in palavrasProibidasEm(texto)) {
                reprovados.add(
                  '${guia.path}:${i + 1}: proibida "$p" — "$texto"',
                );
              }
              if (temEmoji(texto)) {
                reprovados.add('${guia.path}:${i + 1}: emoji — "$texto"');
              }
            }
          }
        }

        expect(reprovados, isEmpty, reason: reprovados.join('\n'));
      },
    );
  });
}

/// Os arquivos que este portão cobre em `lib/l10n/`.
/// T068 estende a varredura sobre todos os arquivos de texto do aplicativo.
const List<String> arquivosVarridos = <String>[
  'textos_abertura.dart',
  'textos_ajuda.dart',
  'textos_anfitria.dart',
  'textos_apresentacao.dart',
  'textos_assistente.dart',
  'textos_autenticacao.dart',
  'textos_casca.dart',
  'textos_configuracoes.dart',
  'textos_cuidado.dart',
  'textos_guias.dart',
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
  // Gênero (decisão do Henrique, 2026-11-18): o texto fala com a pessoa sem
  // supor que ela é mulher ou homem. A Memora fala de si no feminino ("estou
  // quase pronta"), e coisa continua com o gênero dela ("o story passa
  // sozinho"); só a fala dirigida à pessoa é vigiada.
  r'voc[êe](\s+\S+){0,5}\s+sozinh[ao]s?',
  r'(quero|prefiro|vou)(\s+\S+){0,3}\s+sozinh[ao]s?',
  r'ser chamad[ao]s?',
  r'fica(r)? tranquil[ao]s?',
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

/// A propriedade Unicode dos pictogramas. Fica numa constante porque o lint
/// `valid_regexps` lê o literal como se o modo Unicode estivesse desligado e
/// acusa `\p{...}` de inválido — um falso positivo: com `unicode: true` a
/// expressão é válida, e o autoteste acima prova que ela acha cada emoji.
const String _pictograma = r'\p{Extended_Pictographic}';

/// Verdadeiro se houver emoji (pictograma) no texto.
bool temEmoji(String texto) =>
    RegExp(_pictograma, unicode: true).hasMatch(texto);

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

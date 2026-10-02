import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';

/// O elo entre o catálogo do banco e o catálogo do simulado.
///
/// Simulado e banco são mundos separados, e a divergência entre eles só tinha
/// aparecido rodando no emulador: a demonstração chegou a mostrar serviços que
/// a migration não tinha (CLAUDE.md, seção 4-B, "O simulado do aplicativo
/// precisa espelhar o catálogo do banco"). Este teste é o que passa a ligar os
/// dois — ele lê as migrations, extrai as `chave`s e compara com as do
/// `RepositorioAssistenteSimulado`, nomeando a chave que está só de um lado.
///
/// É `test` puro, e não `testWidgets`, porque I/O de arquivo real não completa
/// dentro de `testWidgets` (o relógio é falso).
///
/// A comparação com os guias embarcados **não** entra aqui ainda: é a T063, e
/// os guias só passam a existir na fase 5 da feature 004.

/// Onde estão as migrations, a partir de `app/`, que é onde o `flutter test`
/// roda.
const String pastaDasMigrations = '../backend/src/main/resources/db/migration';

/// O formato que a restrição `ck_servico_chave_formato` do banco aplica.
final RegExp formatoDaChave = RegExp(r'^[a-z0-9-]+$');

/// O tamanho que a coluna `chave VARCHAR(40)` aceita.
const int tamanhoMaximoDaChave = 40;

void main() {
  group('extrator de chaves das migrations', () {
    test('lê as duas formas: UPDATE ... SET chave e INSERT com a coluna chave',
        () {
      const String sql = '''
-- INSERT INTO servico_conhecido (chave) VALUES ('so-no-comentario');
ALTER TABLE servico_conhecido ADD COLUMN chave VARCHAR(40);

UPDATE servico_conhecido SET chave = 'whatsapp'     WHERE nome_exibido = 'WhatsApp';
update servico_conhecido set chave='youtube' where nome_exibido = 'YouTube';

INSERT INTO servico_conhecido
    (id, chave, nome_exibido, categoria, identificador_android,
     descricao_curta, ativo, criado_em, atualizado_em)
VALUES
    (gen_random_uuid(), 'tiktok', 'TikTok', 'COTIDIANO', 'com.zhiliaoapp.musically',
     'Ver videos curtos, com virgula, e (parenteses)', TRUE, now(), now()),
    (gen_random_uuid(), 'banco-do-brasil', 'Banco do Brasil', 'SENSIVEL', NULL,
     'O apostrofo de d''agua nao quebra', TRUE, now(), now());

-- outra tabela: a coluna chave aqui nao e do catalogo
INSERT INTO outra_tabela (id, chave) VALUES (1, 'nao-conta');

INSERT INTO servico_conhecido
    (id, nome_exibido, categoria, descricao_curta, ativo, criado_em, atualizado_em)
VALUES
    (gen_random_uuid(), 'Sem Chave', 'SENSIVEL', 'insert antigo, sem a coluna', TRUE, now(), now());
''';

      expect(
        extrairChavesDasMigrations(sql),
        <String>['whatsapp', 'youtube', 'tiktok', 'banco-do-brasil'],
      );
    });

    test('ignora comentário de linha, inclusive o que tem chave dentro', () {
      const String sql = '''
-- UPDATE servico_conhecido SET chave = 'comentada' WHERE nome_exibido = 'X';
UPDATE servico_conhecido SET chave = 'real' WHERE nome_exibido = 'Y'; -- 'fim'
''';

      expect(extrairChavesDasMigrations(sql), <String>['real']);
    });

    test('um valor da coluna chave que não é literal reprova, em vez de sumir',
        () {
      const String sql = '''
INSERT INTO servico_conhecido (id, chave)
VALUES (gen_random_uuid(), lower('Tiktok'));
''';

      expect(() => extrairChavesDasMigrations(sql), throwsFormatException);
    });
  });

  group('catálogo do banco × catálogo do simulado', () {
    final List<String> doSimulado = RepositorioAssistenteSimulado
        .catalogoDaDemonstracao
        .map((ServicoDoCatalogo s) => s.chave)
        .toList();

    test('as migrations existem onde o teste as procura', () {
      expect(
        Directory(pastaDasMigrations).existsSync(),
        isTrue,
        reason: 'Não achei $pastaDasMigrations. O `flutter test` precisa rodar '
            'com o diretório de trabalho em app/. Sem achar as migrations, a '
            'comparação abaixo passaria sem comparar nada.',
      );
    });

    test('toda chave das migrations está no simulado, e vice-versa', () {
      final Set<String> dasMigrations = chavesDasMigrationsEmDisco().toSet();
      final Set<String> noSimulado = doSimulado.toSet();

      expect(
        dasMigrations,
        isNotEmpty,
        reason: 'Nenhuma chave encontrada nas migrations: o extrator parou de '
            'enxergar o formato delas.',
      );

      final List<String> soNasMigrations =
          (dasMigrations.difference(noSimulado).toList()..sort());
      final List<String> soNoSimulado =
          (noSimulado.difference(dasMigrations).toList()..sort());

      // Os dois lados juntos, numa mensagem só: `expect` encadeado pararia no
      // primeiro e esconderia o outro (uma chave trocada aparece nos dois).
      final List<String> problemas = <String>[
        if (soNasMigrations.isNotEmpty)
          'está nas migrations e não no simulado: '
              '${soNasMigrations.join(', ')}',
        if (soNoSimulado.isNotEmpty)
          'está no simulado e não nas migrations: ${soNoSimulado.join(', ')}',
      ];

      expect(problemas, isEmpty, reason: problemas.join('\n'));
    });

    test('toda chave do simulado tem o formato e o tamanho que o banco exige',
        () {
      for (final String chave in doSimulado) {
        expect(
          formatoDaChave.hasMatch(chave),
          isTrue,
          reason: 'A chave "$chave" não casa com ^[a-z0-9-]+\$ — o banco a '
              'recusaria (ck_servico_chave_formato).',
        );
        expect(
          chave.length,
          lessThanOrEqualTo(tamanhoMaximoDaChave),
          reason: 'A chave "$chave" tem ${chave.length} caracteres; a coluna '
              'aceita $tamanhoMaximoDaChave.',
        );
      }
    });

    test('nenhuma chave se repete no simulado', () {
      final Set<String> vistas = <String>{};
      final List<String> repetidas = <String>[
        for (final String chave in doSimulado)
          if (!vistas.add(chave)) chave,
      ];

      expect(
        repetidas,
        isEmpty,
        reason: 'Chave repetida no simulado: ${repetidas.join(', ')} — o banco '
            'a recusaria (ux_servico_chave).',
      );
    });
  });
}

/// As chaves de todas as migrations em disco, na ordem dos arquivos.
List<String> chavesDasMigrationsEmDisco() {
  final List<File> arquivos = Directory(pastaDasMigrations)
      .listSync()
      .whereType<File>()
      .where((File f) => RegExp(r'[\\/]V\d+__[^\\/]*\.sql$').hasMatch(f.path))
      .toList()
    ..sort((File a, File b) => _versao(a.path).compareTo(_versao(b.path)));

  return <String>[
    for (final File arquivo in arquivos)
      ...extrairChavesDasMigrations(arquivo.readAsStringSync()),
  ];
}

int _versao(String caminho) =>
    int.parse(RegExp(r'[\\/]V(\d+)__').firstMatch(caminho)!.group(1)!);

/// Extrai as `chave`s de `servico_conhecido` de um trecho de SQL.
///
/// Entende duas formas, e só elas:
///
///  1. `UPDATE servico_conhecido SET chave = '<x>' ...`;
///  2. `INSERT INTO servico_conhecido (...colunas...) VALUES (...), (...)`,
///     quando a lista de colunas contém `chave`.
///
/// Um valor da coluna `chave` que não seja literal entre aspas **lança
/// [FormatException]**: ignorá-lo em silêncio faria a chave sumir da
/// comparação — exatamente o furo que este teste existe para fechar.
List<String> extrairChavesDasMigrations(String sql) {
  final String limpo = _semComentarios(sql);
  final List<_Achado> achados = <_Achado>[];

  final RegExp atualizacao = RegExp(
    r"UPDATE\s+servico_conhecido\s+SET\s+chave\s*=\s*'([^']*)'",
    caseSensitive: false,
  );
  for (final RegExpMatch m in atualizacao.allMatches(limpo)) {
    achados.add(_Achado(m.start, m.group(1)!));
  }

  final RegExp insercao = RegExp(
    r'INSERT\s+INTO\s+servico_conhecido\s*\(',
    caseSensitive: false,
  );
  for (final RegExpMatch m in insercao.allMatches(limpo)) {
    final int abre = m.end - 1;
    final int fecha = _fechamento(limpo, abre);
    final List<String> colunas = _separarNoNivelDeCima(
      limpo.substring(abre + 1, fecha),
    ).map((String c) => c.trim().toLowerCase()).toList();

    final int posicao = colunas.indexOf('chave');
    if (posicao < 0) continue;

    final Match? valores =
        RegExp(r'\s*VALUES\s*', caseSensitive: false).matchAsPrefix(
      limpo,
      fecha + 1,
    );
    if (valores == null) {
      throw FormatException(
        'INSERT em servico_conhecido com a coluna chave, mas sem VALUES '
        'logo depois da lista de colunas.',
      );
    }

    int cursor = valores.end;
    while (true) {
      if (cursor >= limpo.length || limpo[cursor] != '(') {
        throw FormatException(
          'Esperava a abertura de uma tupla de VALUES e achei '
          '"${limpo.substring(cursor, (cursor + 20).clamp(0, limpo.length))}".',
        );
      }
      final int fimDaTupla = _fechamento(limpo, cursor);
      final List<String> campos = _separarNoNivelDeCima(
        limpo.substring(cursor + 1, fimDaTupla),
      );
      if (campos.length != colunas.length) {
        throw FormatException(
          'Tupla com ${campos.length} valores para ${colunas.length} colunas: '
          '${limpo.substring(cursor, fimDaTupla + 1)}',
        );
      }
      achados.add(_Achado(cursor, _literal(campos[posicao])));

      cursor = fimDaTupla + 1;
      while (cursor < limpo.length && _ehEspaco(limpo[cursor])) {
        cursor++;
      }
      if (cursor < limpo.length && limpo[cursor] == ',') {
        cursor++;
        while (cursor < limpo.length && _ehEspaco(limpo[cursor])) {
          cursor++;
        }
        continue;
      }
      break;
    }
  }

  achados.sort((_Achado a, _Achado b) => a.posicao.compareTo(b.posicao));
  return <String>[for (final _Achado a in achados) a.chave];
}

class _Achado {
  final int posicao;
  final String chave;
  _Achado(this.posicao, this.chave);
}

bool _ehEspaco(String c) => c == ' ' || c == '\t' || c == '\n' || c == '\r';

/// Um valor SQL que precisa ser literal entre aspas simples.
String _literal(String bruto) {
  final String valor = bruto.trim();
  if (valor.length < 2 || !valor.startsWith("'") || !valor.endsWith("'")) {
    throw FormatException(
      'O valor da coluna chave não é um literal entre aspas simples: $valor',
    );
  }
  return valor.substring(1, valor.length - 1).replaceAll("''", "'");
}

/// Remove comentários `-- ...` até o fim da linha, respeitando aspas simples
/// (um `--` dentro de texto não é comentário).
String _semComentarios(String sql) {
  final StringBuffer saida = StringBuffer();
  bool emTexto = false;
  for (int i = 0; i < sql.length; i++) {
    final String c = sql[i];
    if (emTexto) {
      saida.write(c);
      if (c == "'") emTexto = false; // '' reabre logo em seguida, no mesmo laço
      continue;
    }
    if (c == "'") {
      emTexto = true;
      saida.write(c);
      continue;
    }
    if (c == '-' && i + 1 < sql.length && sql[i + 1] == '-') {
      while (i < sql.length && sql[i] != '\n') {
        i++;
      }
      saida.write('\n');
      continue;
    }
    saida.write(c);
  }
  return saida.toString();
}

/// O índice do parêntese que fecha o que abre em [abre], respeitando aspas
/// simples e parênteses aninhados (`gen_random_uuid()`, `now()`).
int _fechamento(String texto, int abre) {
  int profundidade = 0;
  bool emTexto = false;
  for (int i = abre; i < texto.length; i++) {
    final String c = texto[i];
    if (c == "'") {
      emTexto = !emTexto;
      continue;
    }
    if (emTexto) continue;
    if (c == '(') profundidade++;
    if (c == ')') {
      profundidade--;
      if (profundidade == 0) return i;
    }
  }
  throw FormatException('Parêntese aberto na posição $abre nunca se fecha.');
}

/// Separa por vírgula de nível de cima: fora de aspas e de parênteses.
List<String> _separarNoNivelDeCima(String conteudo) {
  final List<String> partes = <String>[];
  final StringBuffer atual = StringBuffer();
  int profundidade = 0;
  bool emTexto = false;
  for (int i = 0; i < conteudo.length; i++) {
    final String c = conteudo[i];
    if (c == "'") emTexto = !emTexto;
    if (!emTexto) {
      if (c == '(') profundidade++;
      if (c == ')') profundidade--;
      if (c == ',' && profundidade == 0) {
        partes.add(atual.toString());
        atual.clear();
        continue;
      }
    }
    atual.write(c);
  }
  partes.add(atual.toString());
  return partes;
}

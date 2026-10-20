import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/aprendizado/data/guias/guias.dart';
import 'package:memora/features/aprendizado/domain/guia.dart';
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
/// A segunda metade (T063) liga o catálogo aos guias embarcados e confere as
/// regras de produção de `contracts/guias.md`. Ainda **não existe guia
/// nenhum**: a lista [itensSemGuiaAnterioresA004] diz quais itens do catálogo
/// estão nesse estado, e cada guia que entrar (T070 em diante) a encolhe. A T076
/// a leva a zero e a apaga.

/// Onde estão as migrations, a partir de `app/`, que é onde o `flutter test`
/// roda.
const String pastaDasMigrations = '../backend/src/main/resources/db/migration';

/// O formato que a restrição `ck_servico_chave_formato` do banco aplica.
final RegExp formatoDaChave = RegExp(r'^[a-z0-9-]+$');

/// Os itens do catálogo anteriores à 004 que ainda não têm guia.
///
/// **A lista só pode encolher.** O teste reprova se um item daqui já tiver
/// guia (tire-o da lista) e se um item do catálogo sem guia não estiver aqui
/// (um item novo nasce com guia, ou não nasce — R8).
const Set<String> itensSemGuiaAnterioresA004 = <String>{
  'gov-br',
  'meu-inss',
};

/// O registro das capturas, a partir de `app/`.
const String caminhoDeCapturasMd = 'assets/guias/CAPTURAS.md';

/// O tamanho que a coluna `chave VARCHAR(40)` aceita.
const int tamanhoMaximoDaChave = 40;

void main() {
  group('extrator de chaves das migrations', () {
    test(
      'lê as duas formas: UPDATE ... SET chave e INSERT com a coluna chave',
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

        expect(extrairChavesDasMigrations(sql), <String>[
          'whatsapp',
          'youtube',
          'tiktok',
          'banco-do-brasil',
        ]);
      },
    );

    test('ignora comentário de linha, inclusive o que tem chave dentro', () {
      const String sql = '''
-- UPDATE servico_conhecido SET chave = 'comentada' WHERE nome_exibido = 'X';
UPDATE servico_conhecido SET chave = 'real' WHERE nome_exibido = 'Y'; -- 'fim'
''';

      expect(extrairChavesDasMigrations(sql), <String>['real']);
    });

    test(
      'um valor da coluna chave que não é literal reprova, em vez de sumir',
      () {
        const String sql = '''
INSERT INTO servico_conhecido (id, chave)
VALUES (gen_random_uuid(), lower('Tiktok'));
''';

        expect(() => extrairChavesDasMigrations(sql), throwsFormatException);
      },
    );
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
        reason:
            'Não achei $pastaDasMigrations. O `flutter test` precisa rodar '
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
        reason:
            'Nenhuma chave encontrada nas migrations: o extrator parou de '
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

    test(
      'toda chave do simulado tem o formato e o tamanho que o banco exige',
      () {
        for (final String chave in doSimulado) {
          expect(
            formatoDaChave.hasMatch(chave),
            isTrue,
            reason:
                'A chave "$chave" não casa com ^[a-z0-9-]+\$ — o banco a '
                'recusaria (ck_servico_chave_formato).',
          );
          expect(
            chave.length,
            lessThanOrEqualTo(tamanhoMaximoDaChave),
            reason:
                'A chave "$chave" tem ${chave.length} caracteres; a coluna '
                'aceita $tamanhoMaximoDaChave.',
          );
        }
      },
    );

    test('nenhuma chave se repete no simulado', () {
      final Set<String> vistas = <String>{};
      final List<String> repetidas = <String>[
        for (final String chave in doSimulado)
          if (!vistas.add(chave)) chave,
      ];

      expect(
        repetidas,
        isEmpty,
        reason:
            'Chave repetida no simulado: ${repetidas.join(', ')} — o banco '
            'a recusaria (ux_servico_chave).',
      );
    });
  });

  group('guias embarcados × catálogo (T063, contracts/guias.md)', () {
    final Set<String> dasMigrations = chavesDasMigrationsEmDisco().toSet();
    final Map<String, CategoriaDoServico> categorias =
        <String, CategoriaDoServico>{
          for (final ServicoDoCatalogo s
              in RepositorioAssistenteSimulado.catalogoDaDemonstracao)
            s.chave: s.categoria,
        };
    final String capturasMd = File(caminhoDeCapturasMd).readAsStringSync();

    test('CAPTURAS.md existe onde o teste a procura e tem a tabela', () {
      expect(linhasDeCapturas(capturasMd), isNotNull);
    });

    test('toda chave do catálogo tem guia — salvo a lista explícita', () {
      final Set<String> comGuia = todosOsGuias.map((Guia g) => g.chave).toSet();
      final List<String> semGuia =
          dasMigrations
              .where((String c) => !comGuia.contains(c))
              .where((String c) => !itensSemGuiaAnterioresA004.contains(c))
              .toList()
            ..sort();

      expect(
        semGuia,
        isEmpty,
        reason:
            'Chave sem guia: ${semGuia.join(', ')}. Item novo no catálogo '
            'nasce com guia (R8).',
      );
    });

    test('a lista de itens sem guia só encolhe', () {
      final Set<String> comGuia = todosOsGuias.map((Guia g) => g.chave).toSet();

      final List<String> jaTemGuia =
          itensSemGuiaAnterioresA004.where(comGuia.contains).toList()..sort();
      expect(
        jaTemGuia,
        isEmpty,
        reason:
            'Estes itens já têm guia: tire-os de '
            'itensSemGuiaAnterioresA004: ${jaTemGuia.join(', ')}.',
      );

      final List<String> inexistentes =
          itensSemGuiaAnterioresA004
              .where((String c) => !dasMigrations.contains(c))
              .toList()
            ..sort();
      expect(
        inexistentes,
        isEmpty,
        reason:
            'Estes nem existem nas migrations (erro de digitação?): '
            '${inexistentes.join(', ')}.',
      );
    });

    test('todo guia tem uma chave que existe nas migrations', () {
      final List<String> sobrando =
          todosOsGuias
              .map((Guia g) => g.chave)
              .where((String c) => !dasMigrations.contains(c))
              .toList()
            ..sort();

      expect(
        sobrando,
        isEmpty,
        reason: 'Guia sem item no catálogo: ${sobrando.join(', ')}.',
      );
    });

    test('nenhuma chave de guia se repete', () {
      final Set<String> vistas = <String>{};
      final List<String> repetidas = <String>[
        for (final Guia g in todosOsGuias)
          if (!vistas.add(g.chave)) g.chave,
      ];

      expect(repetidas, isEmpty, reason: repetidas.join(', '));
    });

    test('cada guia cumpre as regras de produção', () {
      final Set<String> linhas = linhasDeCapturas(capturasMd)!;
      final List<String> problemas = <String>[
        for (final Guia g in todosOsGuias)
          ...problemasDoGuia(
            g,
            categoria: categorias[g.chave],
            chavesEmCapturasMd: linhas,
            capturaExiste: (CapturaDoGuia c) => File(c.caminho).existsSync(),
          ),
      ];

      expect(problemas, isEmpty, reason: problemas.join('\n'));
    });

    test('capturas pendentes são registradas sem reprovar a construção (FR-028a)', () {
      final List<String> pendentes = <String>[
        for (final Guia g in todosOsGuias)
          ...capturasPendentesDoGuia(
            g,
            capturaExiste: (CapturaDoGuia c) => File(c.caminho).existsSync(),
          ),
      ];
      if (pendentes.isNotEmpty) {
        // ignore: avoid_print
        print('Capturas pendentes (FR-028a):\n${pendentes.join('\n')}');
      }
    });

    test('a pasta de capturas de cada guia está declarada em assets no pubspec.yaml', () {
      final String pubspec = File('pubspec.yaml').readAsStringSync();
      for (final Guia g in todosOsGuias) {
        final String declaracao = 'assets/guias/${g.chave}/';
        expect(
          pubspec.contains(declaracao),
          isTrue,
          reason:
              'A pasta "$declaracao" precisa estar declarada na seção assets do pubspec.yaml.',
        );
      }
    });
  });

  // O registro está vazio, então os testes acima passam sem examinar nenhum
  // guia. Estes montam guias errados de propósito e provam que cada regra
  // reprova — o portão só vale se o teste o pega quebrado.
  group('o verificador de guias pega cada defeito (guias montados de '
      'propósito)', () {
    const RegiaoRelativa regiao = RegiaoRelativa(
      x: 0.1,
      y: 0.1,
      largura: 0.2,
      altura: 0.2,
    );

    // ignore: invalid_use_of_visible_for_testing_member
    const CapturaDoGuia captura = CapturaDoGuia.paraTeste('exemplo', 1);

    Passo passo({
      String descricao = 'A tela inicial do aplicativo',
      bool senha = false,
    }) => Passo(
      captura: captura,
      destaque: regiao,
      texto: 'Toque no botão embaixo, no meio.',
      descricaoDaCaptura: descricao,
      temCampoDeSenha: senha,
    );

    Guia guia({
      String chave = 'exemplo',
      List<Passo>? passos,
      List<String> emMaos = const <String>[],
    }) => Guia(
      chave: chave,
      titulo: 'Aprender a usar o exemplo',
      passos: passos ?? <Passo>[passo(), passo(), passo()],
      capturadoEm: DateTime(2026, 10),
      versaoCapturada: '1.0',
      precisaTerEmMaos: emMaos,
    );

    List<String> problemas(
      Guia g, {
      CategoriaDoServico? categoria = CategoriaDoServico.cotidiano,
      Set<String> emCapturas = const <String>{'exemplo'},
      bool arquivoExiste = true,
    }) => problemasDoGuia(
      g,
      categoria: categoria,
      chavesEmCapturasMd: emCapturas,
      capturaExiste: (CapturaDoGuia _) => arquivoExiste,
    );

    test('um guia correto não tem problema', () {
      expect(problemas(guia()), isEmpty);
    });

    test('menos de 3 passos reprova', () {
      expect(
        problemas(guia(passos: <Passo>[passo(), passo()])),
        contains(contains('passos')),
      );
    });

    test('mais de 7 passos reprova', () {
      expect(
        problemas(guia(passos: List<Passo>.generate(8, (int _) => passo()))),
        contains(contains('passos')),
      );
    });

    test('3 e 7 passos são aceitos', () {
      expect(
        problemas(guia(passos: List<Passo>.generate(3, (int _) => passo()))),
        isEmpty,
      );
      expect(
        problemas(guia(passos: List<Passo>.generate(7, (int _) => passo()))),
        isEmpty,
      );
    });

    test('captura sem descrição reprova, inclusive só de espaços', () {
      expect(
        problemas(
          guia(
            passos: <Passo>[
              passo(),
              passo(descricao: ''),
              passo(),
            ],
          ),
        ),
        contains(contains('descrição')),
      );
      expect(
        problemas(
          guia(
            passos: <Passo>[
              passo(),
              passo(descricao: '  '),
              passo(),
            ],
          ),
        ),
        contains(contains('descrição')),
      );
    });

    test('guia sem linha em CAPTURAS.md reprova', () {
      expect(
        problemas(guia(), emCapturas: const <String>{}),
        contains(contains('CAPTURAS.md')),
      );
    });

    test('guia sem chave nas migrations reprova (categoria desconhecida)', () {
      expect(
        problemas(guia(), categoria: null),
        contains(contains('catálogo')),
      );
    });

    test('captura ausente entra na lista de pendentes em vez de reprovar (FR-028a)', () {
      final List<String> pendentes = capturasPendentesDoGuia(
        guia(),
        capturaExiste: (CapturaDoGuia _) => false,
      );
      expect(
        pendentes,
        contains(contains('assets/guias/exemplo/passo_1.png')),
      );
      expect(problemas(guia(), arquivoExiste: false), isEmpty);
    });

    test('serviço sensível sem "o que ter em mãos" reprova', () {
      expect(
        problemas(guia(), categoria: CategoriaDoServico.sensivel),
        contains(contains('precisaTerEmMaos')),
      );
      expect(
        problemas(
          guia(emMaos: <String>['Seu CPF']),
          categoria: CategoriaDoServico.sensivel,
        ),
        isEmpty,
      );
    });

    test('capturadoEm no futuro e versão em branco reprovam', () {
      final Guia futuro = Guia(
        chave: 'exemplo',
        titulo: 't',
        passos: <Passo>[passo(), passo(), passo()],
        capturadoEm: DateTime.now().add(const Duration(days: 30)),
        versaoCapturada: ' ',
      );

      expect(problemas(futuro), hasLength(2));
    });
  });

  test('CAPTURAS.md: lê as chaves da tabela e ignora cabeçalho e traço', () {
    const String md = '''
# Titulo

| Chave | Capturado em | Versão |
|---|---|---|
| — | — | — |
| tiktok | 2026-10-01 | 1.0 |
|whatsapp|2026-10-01|2.0|
texto solto | com barra
''';

    expect(linhasDeCapturas(md), <String>{'tiktok', 'whatsapp'});
  });
}

/// As chaves que têm linha na tabela de [capturasMd], ou `null` quando o texto
/// não tem tabela nenhuma (o arquivo mudou de formato).
Set<String>? linhasDeCapturas(String capturasMd) {
  final List<String> linhas = capturasMd
      .split('\n')
      .map((String l) => l.trim())
      .where((String l) => l.startsWith('|'))
      .toList();
  if (linhas.isEmpty) return null;

  final Set<String> chaves = <String>{};
  for (final String linha in linhas) {
    final List<String> celulas = linha
        .split('|')
        .map((String c) => c.trim())
        .toList();
    final String primeira = celulas.length > 1 ? celulas[1] : '';
    if (primeira.isEmpty ||
        primeira == '—' ||
        primeira.toLowerCase() == 'chave' ||
        RegExp(r'^[-: ]+$').hasMatch(primeira)) {
      continue;
    }
    chaves.add(primeira);
  }
  return chaves;
}

/// Tudo que `contracts/guias.md` manda reprovar num guia, em texto.
///
/// [categoria] é a do item de catálogo de mesma `chave`, ou `null` quando não
/// há item. O aviso da FR-032 nos passos com `temCampoDeSenha` é da tela, e é
/// conferido nos testes dela (T065, T067, T076) — aqui só se confere o que está
/// nos dados.
/// Lista as capturas pendentes de um guia (FR-028a).
List<String> capturasPendentesDoGuia(
  Guia guia, {
  required bool Function(CapturaDoGuia) capturaExiste,
}) {
  final String quem = 'Guia "${guia.chave}"';
  final List<String> pendentes = <String>[];
  for (int i = 0; i < guia.passos.length; i++) {
    final Passo p = guia.passos[i];
    if (!capturaExiste(p.captura)) {
      pendentes.add(
        '$quem, passo ${i + 1}: ${p.captura.caminho} pendente.',
      );
    }
  }
  return pendentes;
}

List<String> problemasDoGuia(
  Guia guia, {
  required CategoriaDoServico? categoria,
  required Set<String> chavesEmCapturasMd,
  required bool Function(CapturaDoGuia) capturaExiste,
}) {
  final String quem = 'Guia "${guia.chave}"';
  final List<String> problemas = <String>[];

  if (categoria == null) {
    problemas.add('$quem não tem item no catálogo (nas migrations).');
  }

  final int passos = guia.passos.length;
  if (passos < Guia.minimoDePassos || passos > Guia.maximoDePassos) {
    problemas.add(
      '$quem tem $passos passos; precisa de ${Guia.minimoDePassos} a '
      '${Guia.maximoDePassos}.',
    );
  }

  for (int i = 0; i < guia.passos.length; i++) {
    final Passo p = guia.passos[i];
    if (p.descricaoDaCaptura.trim().isEmpty) {
      problemas.add('$quem, passo ${i + 1}: captura sem descrição (FR-045).');
    }
    if (p.texto.trim().isEmpty) {
      problemas.add('$quem, passo ${i + 1}: sem texto.');
    }
    // FR-028a: captura ausente não reprova a construção (entra na lista de pendentes).
  }

  if (categoria == CategoriaDoServico.sensivel &&
      guia.precisaTerEmMaos.isEmpty) {
    problemas.add('$quem é de serviço sensível e não diz precisaTerEmMaos.');
  }

  if (!chavesEmCapturasMd.contains(guia.chave)) {
    problemas.add('$quem não tem linha em assets/guias/CAPTURAS.md.');
  }

  if (guia.versaoCapturada.trim().isEmpty) {
    problemas.add('$quem não registra a versão do aplicativo capturado.');
  }
  if (guia.capturadoEm.isAfter(DateTime.now())) {
    problemas.add('$quem tem capturadoEm no futuro.');
  }

  return problemas;
}

/// As chaves de todas as migrations em disco, na ordem dos arquivos.
List<String> chavesDasMigrationsEmDisco() {
  final List<File> arquivos =
      Directory(pastaDasMigrations)
          .listSync()
          .whereType<File>()
          .where(
            (File f) => RegExp(r'[\\/]V\d+__[^\\/]*\.sql$').hasMatch(f.path),
          )
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

    final Match? valores = RegExp(
      r'\s*VALUES\s*',
      caseSensitive: false,
    ).matchAsPrefix(limpo, fecha + 1);
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

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// V10 — a galeria mostra **todo** componente da biblioteca (FR-033).
///
/// ## Por que um teste de código-fonte, e não de árvore montada
///
/// A tentação é montar a galeria e procurar cada componente nela. Não
/// funciona: a `ListView` da galeria é preguiçosa e só constrói o que está na
/// dobra, então um componente ausente e um componente fora da tela ficam
/// indistinguíveis. Um portão que não distingue os dois aprova o errado.
///
/// O que dá para afirmar com certeza é o que está **escrito**: o barril
/// `design_system.dart` lista tudo que a biblioteca oferece, e
/// `galeria_memora.dart` lista o que a galeria mostra. Comparar as duas
/// listas responde exatamente a pergunta do V10.
///
/// ## O que este portão não pega
///
/// Ele prova que o componente **aparece** na galeria, não que aparece em
/// todos os estados. "Todos os estados" não tem definição verificável — o
/// `BotaoPrimario` tem quatro, o `Cartao` tem um —, e um teste que fingisse
/// verificar isso daria uma garantia que não tem. Os estados estão na galeria
/// por leitura de quem a escreve, e a revisão de UX é quem confere.
void main() {
  /// Componentes exportados que a galeria legitimamente não mostra.
  ///
  /// Cada entrada precisa de uma razão escrita. Lista curta é o ponto: ela é
  /// onde alguém esconde um componente esquecido dizendo que é exceção.
  const Map<String, String> foraDaGaleria = <String, String>{
    'galeria/galeria_memora.dart': 'e a propria galeria',
    'preferencias/controlador_aparencia.dart': 'e controlador, nao componente',
    'preferencias/escopo_aparencia.dart': 'e escopo, nao componente',
    'preferencias/reducao_de_movimento.dart':
        'e uma extensao de contexto (context.reduzirMovimento), nao componente',
    'preferencias/preferencia_aparencia.dart': 'e entidade, nao componente',
    'preferencias/tela_aparencia.dart':
        'e uma TELA inteira, com persistencia propria; montar uma tela dentro '
            'da galeria misturaria os dois niveis',
    'temas/memora_theme_extension.dart': 'e extensao de tema',
    'temas/temas_memora.dart': 'e o tema — a galeria troca entre os tres',
  };

  test('todo componente exportado aparece na galeria', () {
    final List<String> exportados =
        File('lib/design_system/design_system.dart')
            .readAsLinesSync()
            .where((String l) => l.startsWith("export '"))
            .map((String l) => l.split("'")[1])
            .where((String caminho) => !caminho.startsWith('tokens/'))
            .toList();

    expect(exportados, isNotEmpty,
        reason: 'se o barril mudar de forma, este teste para de olhar para '
            'qualquer coisa — e precisa ser reescrito, nao apagado');

    final String galeria =
        File('lib/design_system/galeria/galeria_memora.dart').readAsStringSync();

    final List<String> ausentes = <String>[];

    for (final String caminho in exportados) {
      if (foraDaGaleria.containsKey(caminho)) continue;

      // O nome do tipo, deduzido do arquivo: `botoes/botao_primario.dart`
      // vira `BotaoPrimario`. É a convenção do repositório inteiro, e quebrá-la
      // faria este teste apontar o arquivo — que é o que se quer saber.
      final String arquivo = caminho.split('/').last.replaceAll('.dart', '');
      final String tipo = arquivo
          .split('_')
          .map((String p) => p[0].toUpperCase() + p.substring(1))
          .join();

      if (!galeria.contains(tipo)) {
        ausentes.add('$tipo (de $caminho)');
      }
    }

    expect(
      ausentes,
      isEmpty,
      reason: 'componente na biblioteca e ausente da galeria. Documentacao '
          'incompleta e documentacao que ninguem confia — e o proximo a '
          'precisar dele vai escrever o segundo. Acrescente na galeria, ou '
          'declare em `foraDaGaleria` com a razao.',
    );
  });

  test('nenhuma excecao aponta para arquivo que nao existe mais', () {
    // Sem isto, a lista de excecoes vira um cemiterio: alguem apaga o
    // componente, a entrada fica, e o portao continua ignorando um nome que
    // um dia pode voltar significando outra coisa.
    final Set<String> exportados = File('lib/design_system/design_system.dart')
        .readAsLinesSync()
        .where((String l) => l.startsWith("export '"))
        .map((String l) => l.split("'")[1])
        .toSet();

    for (final String excecao in foraDaGaleria.keys) {
      expect(exportados, contains(excecao),
          reason: '`$excecao` esta na lista de excecoes e nao e mais '
              'exportado pelo design_system.dart');
    }
  });
}

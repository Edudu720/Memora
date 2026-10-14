import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/aprendizado/domain/busca.dart';

/// A busca de "Meus aplicativos" (T068): por trecho, sem acento, sem
/// diferenciar maiúscula.
void main() {
  const List<ServicoDoCatalogo> catalogo =
      RepositorioAssistenteSimulado.catalogoDaDemonstracao;

  List<String> nomes(String consulta) => buscarServicos(
    catalogo,
    consulta,
  ).map((ServicoDoCatalogo s) => s.nomeExibido).toList();

  ServicoDoCatalogo item(String nome, String descricao) => ServicoDoCatalogo(
    id: nome,
    chave: nome.toLowerCase(),
    nomeExibido: nome,
    descricaoCurta: descricao,
    categoria: CategoriaDoServico.cotidiano,
    memoraPodeAbrir: true,
  );

  final List<ServicoDoCatalogo> comTiktok = <ServicoDoCatalogo>[
    ...catalogo,
    item('TikTok', 'Ver vídeos curtos'),
  ];

  group('por trecho', () {
    test('"tik" acha o TikTok', () {
      expect(
        buscarServicos(
          comTiktok,
          'tik',
        ).map((ServicoDoCatalogo s) => s.nomeExibido),
        <String>['TikTok'],
      );
    });

    test('o trecho pode estar no meio do nome', () {
      expect(nomes('tub'), <String>['YouTube']);
      // "fotos" também está na descrição do Instagram: a busca olha os dois.
      expect(nomes('fotos'), <String>['Instagram', 'Google Fotos']);
    });
  });

  group('sem diferenciar maiúscula', () {
    test('"TIK", "Tik" e "tik" dão o mesmo', () {
      final List<String> minuscula = buscarServicos(
        comTiktok,
        'tik',
      ).map((ServicoDoCatalogo s) => s.chave).toList();

      for (final String escrita in <String>['TIK', 'Tik', 'tIk']) {
        expect(
          buscarServicos(
            comTiktok,
            escrita,
          ).map((ServicoDoCatalogo s) => s.chave).toList(),
          minuscula,
          reason: escrita,
        );
      }
      expect(minuscula, isNotEmpty);
    });
  });

  group('sem diferenciar acento', () {
    test('"video" acha "Vídeo", e "vídeo" acha "video"', () {
      final List<String> semAcento = nomes('video');
      final List<String> comAcento = nomes('vídeo');

      expect(semAcento, comAcento);
      // WhatsApp (chamada de vídeo), Instagram e YouTube falam em vídeo.
      expect(
        semAcento,
        containsAll(<String>['WhatsApp', 'Instagram', 'YouTube']),
      );
    });

    test('o acento vale no texto do catálogo e na consulta', () {
      final List<ServicoDoCatalogo> lista = <ServicoDoCatalogo>[
        item('Receitas', 'Cozinhar com a vovó'),
        item('Música', 'Ouvir canções'),
        item('Ação', 'Filmes'),
      ];

      expect(
        buscarServicos(
          lista,
          'voVO',
        ).map((ServicoDoCatalogo s) => s.nomeExibido),
        <String>['Receitas'],
      );
      expect(
        buscarServicos(
          lista,
          'musica',
        ).map((ServicoDoCatalogo s) => s.nomeExibido),
        <String>['Música'],
      );
      expect(
        buscarServicos(
          lista,
          'cancoes',
        ).map((ServicoDoCatalogo s) => s.nomeExibido),
        <String>['Música'],
      );
      expect(
        buscarServicos(
          lista,
          'ACAO',
        ).map((ServicoDoCatalogo s) => s.nomeExibido),
        <String>['Ação'],
      );
    });

    test('cedilha e til também', () {
      expect(normalizarParaBusca('Ação Coração Pão'), 'acao coracao pao');
      expect(normalizarParaBusca('ÁÉÍÓÚ ÀÂÊÔ Ü'), 'aeiou aaeo u');
    });
  });

  group('o que se digita de verdade', () {
    test('consulta vazia ou só de espaços devolve tudo, na mesma ordem', () {
      expect(buscarServicos(catalogo, ''), catalogo);
      expect(buscarServicos(catalogo, '   '), catalogo);
    });

    test('espaços sobrando no começo, no fim e no meio não atrapalham', () {
      expect(nomes('  tub  '), nomes('tub'));
      expect(nomes('ver   fotos'), nomes('ver fotos'));
    });

    test('várias palavras: todas precisam aparecer, em qualquer ordem', () {
      expect(nomes('google fotos'), <String>['Google Fotos']);
      expect(nomes('fotos google'), <String>['Google Fotos']);
      expect(nomes('google youtube'), isEmpty);
    });

    test('"govbr", "gov br" e "gov.br" acham o Gov.br', () {
      expect(nomes('govbr'), contains('Gov.br'));
      expect(nomes('gov br'), contains('Gov.br'));
      expect(nomes('gov.br'), contains('Gov.br'));
    });

    test('acento digitado como caractere combinante também é ignorado', () {
      final List<ServicoDoCatalogo> lista = <ServicoDoCatalogo>[
        item('TikTok', 'Ver vídeos curtos'),
      ];
      expect(
        buscarServicos(lista, 'vídeo').map((s) => s.nomeExibido),
        <String>['TikTok'],
      );
      expect(normalizarParaBusca('Vídeo'), 'video');
    });

    test('sem resultado devolve lista vazia, não erro', () {
      expect(nomes('xyzzy'), isEmpty);
    });

    test('mantém a ordem do catálogo e não altera a lista original', () {
      final List<ServicoDoCatalogo> original = List<ServicoDoCatalogo>.of(
        catalogo,
      );

      final List<String> achados = nomes('e');

      expect(
        achados,
        original
            .where((ServicoDoCatalogo s) => achados.contains(s.nomeExibido))
            .map((ServicoDoCatalogo s) => s.nomeExibido),
      );
      expect(catalogo, original);
    });
  });
}

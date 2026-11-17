import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/atalhos_aplicativos/data/repositorio_atalhos_aplicativos.dart';
import 'package:memora/features/atalhos_aplicativos/domain/entidades/atalho_aplicativo.dart';
import 'package:memora/services/aplicativos/consulta_de_aplicativos.dart';

void main() {
  group('RepositorioAtalhosAplicativos — fonte única do catálogo (R6)', () {
    test('contém os 7 aplicativos cotidianos do catálogo e exclui sensíveis', () async {
      final RepositorioAtalhosAplicativos repo = RepositorioAtalhosAplicativos(
        assistente: RepositorioAssistenteSimulado(demora: Duration.zero),
      );
      final List<AtalhoAplicativo> itens = await repo.obterAtalhos();

      expect(itens, hasLength(7));
      expect(
        itens.map((AtalhoAplicativo a) => a.chave),
        containsAll(<String>[
          'whatsapp',
          'youtube',
          'instagram',
          'facebook',
          'google-fotos',
          'telegram',
          'tiktok',
        ]),
      );

      const List<String> chavesProibidas = <String>[
        'gov-br',
        'meu-inss',
        'e-titulo',
        'serasa',
        'fgts',
        'poupatempo',
        'carteira-digital',
        'correios',
        'carteira-de-trabalho',
      ];
      for (final AtalhoAplicativo app in itens) {
        expect(chavesProibidas, isNot(contains(app.chave)));
        expect(app.pacoteAndroid.contains('gov.br'), isFalse);
      }
    });

    test('reflete desativação de aplicativo no catálogo do servidor (R6)', () async {
      final RepositorioAtalhosAplicativos repo = RepositorioAtalhosAplicativos(
        assistente: _CatalogoComUmDesativado(),
      );
      final List<AtalhoAplicativo> itens = await repo.obterAtalhos();

      expect(itens.map((AtalhoAplicativo a) => a.chave), equals(<String>['whatsapp']));
    });

    test('com consulta nula, devolve itens do servidor como não instalados', () async {
      final RepositorioAtalhosAplicativos repo = RepositorioAtalhosAplicativos(
        assistente: RepositorioAssistenteSimulado(demora: Duration.zero),
      );
      final List<AtalhoAplicativo> itens = await repo.obterAtalhos();

      expect(itens, hasLength(7));
      expect(itens.every((AtalhoAplicativo a) => !a.instalado), isTrue);
    });

    test('marca corretamente instalados, não instalados e ícones carregados', () async {
      final Uint8List pngFalso = Uint8List.fromList(<int>[1, 2, 3, 4]);
      final ConsultaDeAplicativosSimulada consulta =
          ConsultaDeAplicativosSimulada(
            instalados: <String>{
              'com.whatsapp',
              'com.google.android.youtube',
            },
            icones: <String, Uint8List>{
              'com.whatsapp': pngFalso,
            },
          );
      final RepositorioAtalhosAplicativos repo = RepositorioAtalhosAplicativos(
        assistente: RepositorioAssistenteSimulado(demora: Duration.zero),
        consulta: consulta,
      );

      final List<AtalhoAplicativo> itens = await repo.obterAtalhos();
      final AtalhoAplicativo whatsapp = itens.firstWhere(
        (AtalhoAplicativo a) => a.chave == 'whatsapp',
      );
      final AtalhoAplicativo youtube = itens.firstWhere(
        (AtalhoAplicativo a) => a.chave == 'youtube',
      );
      final AtalhoAplicativo instagram = itens.firstWhere(
        (AtalhoAplicativo a) => a.chave == 'instagram',
      );

      expect(whatsapp.instalado, isTrue);
      expect(whatsapp.iconeBytes, equals(pngFalso));
      expect(youtube.instalado, isTrue);
      expect(youtube.iconeBytes, isNull);
      expect(instagram.instalado, isFalse);
      expect(instagram.iconeBytes, isNull);
    });

    test('falha na consulta é isolada e tratada como não instalado', () async {
      final RepositorioAtalhosAplicativos repo = RepositorioAtalhosAplicativos(
        assistente: RepositorioAssistenteSimulado(demora: Duration.zero),
        consulta: _ConsultaQueFalha(),
      );

      final List<AtalhoAplicativo> itens = await repo.obterAtalhos();
      expect(itens, hasLength(7));
      expect(itens.every((AtalhoAplicativo a) => !a.instalado), isTrue);
    });
  });
}

class _CatalogoComUmDesativado implements RepositorioAssistente {
  @override
  Future<List<ServicoDoCatalogo>> catalogo() async => const <ServicoDoCatalogo>[
        ServicoDoCatalogo(
          id: 'whatsapp',
          chave: 'whatsapp',
          nomeExibido: 'WhatsApp',
          descricaoCurta: 'Mensagens e chamadas',
          categoria: CategoriaDoServico.cotidiano,
          memoraPodeAbrir: true,
          identificadorAndroid: 'com.whatsapp',
        ),
        ServicoDoCatalogo(
          id: 'tiktok',
          chave: 'tiktok',
          nomeExibido: 'TikTok',
          descricaoCurta: 'Vídeos curtos',
          categoria: CategoriaDoServico.cotidiano,
          memoraPodeAbrir: false,
          identificadorAndroid: 'com.zhiliaoapp.musically',
        ),
        ServicoDoCatalogo(
          id: 'gov-br',
          chave: 'gov-br',
          nomeExibido: 'Gov.br',
          descricaoCurta: 'Serviços públicos',
          categoria: CategoriaDoServico.sensivel,
          memoraPodeAbrir: false,
        ),
      ];

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
    void Function(void Function() cancelar)? aoCriarCancelamento,
  }) async => const AssistenteRespondeu('ok');

  @override
  Future<void> registrarAcao({
    required String servicoId,
    required String pedidoResumido,
  }) async {}

  @override
  Future<List<AcaoRegistrada>> registro() async => const <AcaoRegistrada>[];
}

class _ConsultaQueFalha implements ConsultaDeAplicativos {
  @override
  Future<bool> estaInstalado(String pacote) async => throw Exception('erro');

  @override
  Future<Uint8List?> iconeDe(String pacote) async => throw Exception('erro');
}

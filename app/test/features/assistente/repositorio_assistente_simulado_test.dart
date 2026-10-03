import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/assistente/data/repositorio_assistente_simulado.dart';
import 'package:memora/features/assistente/domain/assistente.dart';

/// O simulado reproduz as duas regras que a feature não pode errar.
///
/// Ele não é o servidor, e nenhum teste aqui prova o comportamento de produção.
/// O que estes testes protegem é o **andaime contra o qual as telas serão
/// construídas**: um simulado que oferecesse abrir o banco faria a tela ser
/// desenhada para um mundo que o servidor recusa, e o erro só apareceria na
/// integração.
void main() {
  late RepositorioAssistenteSimulado assistente;

  setUp(() {
    // Sem demora: aqui não estamos exercitando o estado de espera da tela.
    assistente = RepositorioAssistenteSimulado(demora: Duration.zero);
  });

  Future<RespostaDaAssistente> perguntar(String texto) => assistente.conversar(
        mensagem: texto,
        historico: const <MensagemDaConversa>[],
      );

  group('Serviço sensível — FR-041', () {
    test('nunca oferece abrir, mesmo com pedido direto', () async {
      for (final String pedido in <String>[
        'como vejo meu benefício do inss',
        'abre o banco pra mim',
        'quero fazer um pix',
        'preciso entrar no gov',
      ]) {
        final RespostaDaAssistente resposta = await perguntar(pedido);

        expect(resposta, isA<AssistenteRespondeu>());
        expect(
          (resposta as AssistenteRespondeu).acao,
          isNull,
          reason: 'ofereceu abrir para o pedido "$pedido"',
        );
      }
    });

    test('explica o motivo da recusa, e não apenas recusa', () async {
      final AssistenteRespondeu resposta =
          await perguntar('abre o banco pra mim') as AssistenteRespondeu;

      // A FR-042 pede o porquê. Recusa sem explicação soa como limitação do
      // produto, e não como a proteção que ela é.
      expect(resposta.texto.toLowerCase(), contains('não abro'));
      expect(resposta.texto.toLowerCase(), contains('suporte'));
    });

    test('nenhum serviço sensível do catálogo é abrível', () async {
      final List<ServicoDoCatalogo> catalogo = await assistente.catalogo();
      final Iterable<ServicoDoCatalogo> sensiveis = catalogo.where(
        (ServicoDoCatalogo s) => s.categoria == CategoriaDoServico.sensivel,
      );

      expect(sensiveis, isNotEmpty, reason: 'o catálogo precisa exercer o caso');
      for (final ServicoDoCatalogo servico in sensiveis) {
        expect(servico.memoraPodeAbrir, isFalse);
      }
    });
  });

  group('Ensinar vem antes de fazer — FR-014', () {
    test('a primeira resposta ensina e NÃO oferece abrir', () async {
      final AssistenteRespondeu resposta =
          await perguntar('como vejo as fotos do meu neto')
              as AssistenteRespondeu;

      // Este é o Princípio VII no andaime: oferecer executar antes de ensinar
      // entregaria o resultado de hoje e nenhuma autonomia amanhã.
      expect(resposta.acao, isNull);
      expect(resposta.texto, isNotEmpty);
    });

    test('a oferta aparece só quando a pessoa diz que não conseguiu', () async {
      final AssistenteRespondeu resposta =
          await perguntar('não consegui achar') as AssistenteRespondeu;

      expect(resposta.acao, isNotNull);
      expect(resposta.acao!.identificadorAndroid, isNotEmpty);
    });

    test('a resposta chega em pedaços, como o servidor entregaria', () async {
      final List<String> trechos = <String>[];

      await assistente.conversar(
        mensagem: 'como mando uma mensagem',
        historico: const <MensagemDaConversa>[],
        aoReceberTrecho: trechos.add,
      );

      // A tela precisa ser construída contra o modo em que vai funcionar. Um
      // simulado que devolvesse tudo de uma vez deixaria o estado de espera
      // sem exercício até a integração.
      expect(trechos.length, greaterThan(1));
    });
  });

  group('Registro — FR-023 e FR-025', () {
    test('só ação executada entra no registro', () async {
      expect(await assistente.registro(), isEmpty);

      await assistente.registrarAcao(
        servicoId: 'whatsapp',
        pedidoResumido: 'mandar mensagem para minha filha',
      );

      final List<AcaoRegistrada> registro = await assistente.registro();
      expect(registro, hasLength(1));
      expect(registro.first.nomeExibido, 'WhatsApp');
    });
  });

  group('Falhas', () {
    test('o limite diário não traz espera: diz que volta amanhã (T106)', () async {
      final RepositorioAssistenteSimulado limitado =
          RepositorioAssistenteSimulado(
        demora: Duration.zero,
        falhaForcada: FalhaDaAssistente.limiteDeConversas,
      );

      final RespostaDaAssistente resposta = await limitado.conversar(
        mensagem: 'oi',
        historico: const <MensagemDaConversa>[],
      );

      expect(resposta, isA<AssistenteFalhou>());
      expect(
        (resposta as AssistenteFalhou).falha,
        FalhaDaAssistente.limiteDeConversas,
      );
    });
  });
}

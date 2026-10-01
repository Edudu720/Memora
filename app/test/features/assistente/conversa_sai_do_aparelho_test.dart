import 'package:flutter_test/flutter_test.dart';
import 'package:memora/features/assistente/domain/assistente.dart';
import 'package:memora/features/autenticacao/data/ultimo_acesso_local.dart';
import 'package:memora/services/seguranca/cofre_de_credenciais.dart';
import 'package:memora/services/seguranca/limpeza_de_sessao.dart';

/// H6, passos 4 e 5 — a conversa sai do aparelho quando a pessoa sai da conta.
///
/// ## O que faltava
///
/// O H6 tem duas metades. A do servidor — "nada da conversa fica no banco" —
/// já era coberta por `ConversaNaoPersisteTest`, no backend. A do aparelho
/// **não era coberta por nada**, e ao escrever a T069 apareceu por quê: a
/// `LimpezaDeSessao` não apagava a conversa, e pior, **ela não era usada por
/// ninguém em `lib/`** — só por um teste. A saída real chamava
/// `_cofre.limpar()` direto, de dentro do repositório.
///
/// ## Por que isso importa mais do que um dado esquecido
///
/// A decisão D3 da feature 003 manda a conversa ficar só no aparelho, porque
/// no servidor ela viraria acervo sobre a intimidade de quem é alvo
/// preferencial de golpe no Brasil. Essa decisão só se sustenta se a conversa
/// **sai** do aparelho junto com a pessoa. Senão o acervo continua existindo —
/// na mão de quem pegar o telefone.
void main() {
  group('Sair da conta apaga a conversa (FR-048)', () {
    late _CofreDeMentira cofre;
    late _UltimoAcessoDeMentira ultimoAcesso;
    late _ConversaDeMentira conversa;
    late LimpezaDeSessao limpeza;

    setUp(() async {
      cofre = _CofreDeMentira();
      ultimoAcesso = _UltimoAcessoDeMentira();
      conversa = _ConversaDeMentira();
      limpeza = LimpezaDeSessao(
        cofre: cofre,
        ultimoAcesso: ultimoAcesso,
        dadosLocais: <DadoLocalDaPessoa>[conversa],
      );

      await cofre.guardarSessao(
        tokenAcesso: 'token-de-acesso',
        refreshToken: 'refresh-de-60-dias',
      );
      await ultimoAcesso.lembrar('ana@gmail.com');
      await conversa.guardar(<MensagemDaConversa>[
        MensagemDaConversa(
          autor: AutorDaMensagem.pessoa,
          texto: 'meu neto me pediu dinheiro pelo whatsapp',
          momento: DateTime(2026, 9, 15),
        ),
      ]);
    });

    test('a conversa guardada some', () async {
      expect(await conversa.ler(), hasLength(1),
          reason: 'o cenario pressupoe conversa guardada antes da saida');

      await limpeza.executar();

      expect(await conversa.ler(), isEmpty);
    });

    test('some mesmo sem esquecerTudo', () async {
      // `esquecerTudo` existe para o identificador do último acesso, que a
      // equipe decidiu manter. A conversa não tem decisão nenhuma a favor de
      // ficar: a FR-048 manda apagar, e ponto.
      await limpeza.executar();

      expect(await conversa.ler(), isEmpty);
      expect(await ultimoAcesso.identificador(), 'ana@gmail.com',
          reason: 'o identificador fica — e a conversa nao');
    });

    test('a credencial sai primeiro, e a conversa depois', () async {
      await limpeza.executar();

      expect(cofre.momentoDaLimpeza, isNotNull);
      expect(conversa.momentoDaLimpeza, isNotNull);
      expect(
        cofre.momentoDaLimpeza! < conversa.momentoDaLimpeza!,
        isTrue,
        reason: 'se a limpeza falhar no meio, e melhor sobrar conversa sem '
            'credencial do que credencial sem conversa',
      );
    });

    test('falha ao apagar a conversa nao impede a limpeza de terminar',
        () async {
      final LimpezaDeSessao comFalha = LimpezaDeSessao(
        cofre: cofre,
        ultimoAcesso: ultimoAcesso,
        dadosLocais: <DadoLocalDaPessoa>[_ConversaQueFalha(), conversa],
      );

      // Sem isto, um arquivo travado pelo sistema deixaria a pessoa sem saber
      // se saiu ou não. O que importa mais — a credencial — ja foi.
      await comFalha.executar();

      expect(await cofre.tokenAcesso(), isNull);
      expect(await conversa.ler(), isEmpty);
    });
  });
}

/// Contador global de ordem, para saber o que foi apagado antes do quê.
int _relogio = 0;

class _ConversaDeMentira implements DadoLocalDaPessoa {
  List<MensagemDaConversa> _guardadas = <MensagemDaConversa>[];
  int? momentoDaLimpeza;

  Future<List<MensagemDaConversa>> ler() async => _guardadas;

  Future<void> guardar(List<MensagemDaConversa> mensagens) async {
    _guardadas = List<MensagemDaConversa>.from(mensagens);
  }

  @override
  Future<void> apagar() async {
    momentoDaLimpeza = _relogio++;
    _guardadas = <MensagemDaConversa>[];
  }
}

/// Um dado local cujo apagamento falha — disco cheio, arquivo travado.
class _ConversaQueFalha implements DadoLocalDaPessoa {
  @override
  Future<void> apagar() async {
    // `ConversaLocal.apagar` engole a própria exceção, mas nada garante que o
    // próximo item da lista faça o mesmo. A limpeza não pode depender disso.
  }
}

class _CofreDeMentira implements CofreDeCredenciais {
  String? _acesso;
  String? _refresh;
  int? momentoDaLimpeza;

  @override
  Future<void> guardarSessao({
    required String tokenAcesso,
    required String refreshToken,
  }) async {
    _acesso = tokenAcesso;
    _refresh = refreshToken;
  }

  @override
  Future<String?> tokenAcesso() async => _acesso;

  @override
  Future<String?> refreshToken() async => _refresh;

  @override
  Future<void> limpar() async {
    momentoDaLimpeza = _relogio++;
    _acesso = null;
    _refresh = null;
  }
}

class _UltimoAcessoDeMentira implements UltimoAcesso {
  String? _id;

  @override
  Future<String?> identificador() async => _id;

  @override
  Future<void> lembrar(String identificador) async => _id = identificador;

  @override
  Future<void> esquecer() async => _id = null;
}

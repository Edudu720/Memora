import 'dart:async';

import 'package:dio/dio.dart';
import 'package:memora_api/memora_api.dart' as api;

import '../../../services/seguranca/cofre_de_credenciais.dart';
import '../../autenticacao/domain/autenticacao.dart';
import '../domain/assistente.dart';

/// Solta o corpo de uma resposta de erro que nunca vamos ler.
///
/// Com `ResponseType.stream` o corpo de um `401`, `400` ou `5xx` chega como
/// fluxo não consumido, e deixá-lo parado segura a conexão.
void soltarCorpoDaResposta(DioException excecao) {
  final Object? corpo = excecao.response?.data;
  if (corpo is ResponseBody) {
    unawaited(corpo.stream.drain<void>().catchError((Object _) {}));
  }
}

/// O ponto **único** da camada `data/` que renova a sessão em silêncio (T108).
///
/// O token de acesso vale 15 minutos. Quem está conversando passa disso sem
/// perceber, e a Memora não pode transformar "o relógio andou" em "faça login
/// de novo" — o que só é verdade quando a renovação também falha. Esta classe
/// envolve toda chamada autenticada da assistente (conversa, catálogo,
/// registro e ação): diante de `401`, renova e reenvia **uma vez**.
///
/// ## As renovações são em série, e é isto que protege a conta
///
/// O refresh token rotaciona: cada renovação gasta o atual e entrega outro. Se
/// duas chamadas levarem `401` ao mesmo tempo e cada uma renovasse por conta
/// própria, as duas apresentariam o **mesmo** refresh — e a segunda chegaria
/// com um token já gasto, que é o sinal que o servidor trata como roubo (V3),
/// derrubando a família inteira de sessões e expulsando a pessoa da conta. Por
/// isso há um [Future] de renovação em curso, e quem chega durante ele **espera
/// o mesmo**.
///
/// Há um caso mais fino: a chamada B pode levar o `401` **depois** de a
/// renovação da A terminar (a resposta dela demorou). Nesse momento já não há
/// renovação em curso — mas o token que B usou é o antigo, e o cofre já tem o
/// novo. Renovar de novo gastaria um refresh sem motivo; basta reenviar com o
/// token que o cofre tem. Por isso cada chamada lembra qual token usou.
///
/// ## Nunca mais de um reenvio
///
/// Um segundo `401`, depois de uma renovação bem-sucedida, não vira outra
/// renovação: a sessão nova também foi recusada — conta desativada, ou o token
/// de uma sessão que nunca existiu (a sessão-chamariz da FR-010 da 001) — e
/// insistir só faria o laço girar.
///
/// ## O que a renovação recusada vira
///
/// [FalhaDaAssistente.sessaoExpirada], e só ela. Falta de conexão **durante a
/// renovação** é [FalhaDaAssistente.semConexao]: a rede caiu, a sessão não, e
/// mandar a pessoa à entrada por causa disso seria fazê-la digitar a senha por
/// um problema que não é dela.
class ChamadaComRenovacao {
  final api.MemoraApi _api;
  final CofreDeCredenciais _cofre;
  final Future<ResultadoAutenticacao> Function() _renovar;

  Future<void>? _renovacaoEmCurso;

  /// Cria o envoltório.
  ///
  /// [cliente] precisa ser a **mesma** instância da autenticação: é nela que
  /// o token vai para o cabeçalho, e duas instâncias teriam dois tokens.
  /// [renovar] é o `renovarSessao` do repositório de autenticação, que já
  /// guarda o par novo no cofre — gravar o refresh antigo de volta faria a
  /// próxima renovação apresentar um token gasto.
  ChamadaComRenovacao({
    required api.MemoraApi cliente,
    required CofreDeCredenciais cofre,
    required Future<ResultadoAutenticacao> Function() renovar,
  }) : _api = cliente,
       _cofre = cofre,
       _renovar = renovar;

  /// Executa [chamada] com o token do cofre, renovando e reenviando se preciso.
  ///
  /// Lança [FalhaDeChamadaDaAssistente] para sessão perdida e para falta de
  /// conexão na renovação; qualquer outra falha do transporte sai como veio
  /// (`DioException`), para quem chama traduzi-la.
  Future<T> executar<T>(Future<T> Function() chamada) async {
    final String? tokenUsado = await _prepararToken();
    try {
      return await chamada();
    } on DioException catch (excecao) {
      if (!_foiRecusadoPorSessao(excecao)) rethrow;
      soltarCorpoDaResposta(excecao);
      await _renovarEmSerie(tokenUsado);
    }

    // Reenvio único. Fora do `try` de cima de propósito: um segundo 401 aqui
    // não passa por renovação nenhuma.
    await _prepararToken();
    try {
      return await chamada();
    } on DioException catch (excecao) {
      if (_foiRecusadoPorSessao(excecao)) {
        soltarCorpoDaResposta(excecao);
        throw const FalhaDeChamadaDaAssistente(
          FalhaDaAssistente.sessaoExpirada,
        );
      }
      rethrow;
    }
  }

  bool _foiRecusadoPorSessao(DioException excecao) =>
      excecao.response?.statusCode == 401;

  /// Põe o token do cofre no cliente e o devolve.
  ///
  /// Sem token não há sessão: é a mesma situação de um `401` que a renovação
  /// não resolveu, e a chamada nem sai — não vale uma ida à rede para ouvir o
  /// que já sabemos.
  Future<String?> _prepararToken() async {
    final String? token = await _cofre.tokenAcesso();
    if (token == null || token.isEmpty) {
      // Pode ser só o token de acesso ausente com refresh ainda vivo; deixar
      // seguir sem cabeçalho produz o `401` que aciona a renovação, e é ela
      // quem decide. Lançar aqui impediria a renovação em silêncio.
      return null;
    }
    _api.setBearerAuth('tokenDeAcesso', token);
    return token;
  }

  /// Renova uma vez por vez: quem chega durante uma renovação espera a dela.
  Future<void> _renovarEmSerie(String? tokenUsado) {
    final Future<void>? emCurso = _renovacaoEmCurso;
    if (emCurso != null) return emCurso;

    // `_renovacaoEmCurso` é atribuído **antes** de qualquer `await`: duas
    // chamadas que chegam no mesmo instante enxergam a mesma renovação.
    final Future<void> nova = _renovarDeVerdade(
      tokenUsado,
    ).whenComplete(() => _renovacaoEmCurso = null);
    _renovacaoEmCurso = nova;
    return nova;
  }

  Future<void> _renovarDeVerdade(String? tokenUsado) async {
    // Alguém já renovou depois de esta chamada sair com o token antigo.
    final String? atual = await _cofre.tokenAcesso();
    if (atual != null && atual.isNotEmpty && atual != tokenUsado) return;

    final ResultadoAutenticacao resultado = await _renovar();
    switch (resultado) {
      case AutenticacaoConcluida():
        return;
      case AutenticacaoFalhou(:final FalhaAutenticacao falha):
        throw FalhaDeChamadaDaAssistente(switch (falha) {
          FalhaAutenticacao.semConexao => FalhaDaAssistente.semConexao,
          FalhaAutenticacao.credenciaisInvalidas =>
            FalhaDaAssistente.sessaoExpirada,
          // Refresh recusado por qualquer outro motivo de sessão, ou falha que
          // a assistente não sabe nomear: não finja saber se a sessão caiu.
          FalhaAutenticacao.dadosInvalidos ||
          FalhaAutenticacao.muitasTentativas ||
          FalhaAutenticacao.inesperada => FalhaDaAssistente.inesperada,
        });
    }
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show immutable;
import 'package:memora_api/memora_api.dart' as api;

import '../domain/assistente.dart';

/// Um evento do fluxo de Server-Sent Events, já montado.
@immutable
class EventoSse {
  /// O campo `event:`. É o discriminador do que vem em [dados].
  final String nome;

  /// O campo `data:`, com as linhas múltiplas juntas por `\n`.
  final String dados;

  /// Cria um evento.
  const EventoSse(this.nome, this.dados);

  @override
  String toString() => 'EventoSse($nome, $dados)';
}

/// Lê um fluxo de bytes SSE e entrega um [EventoSse] por evento completo.
///
/// ## Por que isto é escrito à mão
///
/// O cliente gerado devolve a resposta inteira como `String`: serve ao
/// catálogo, não a uma conversa que precisa **aparecer à medida que chega**
/// (FR-052, SC-007). Esta é a única leitura do aplicativo que sai do pacote
/// gerado — e por isso há um teste que a prende ao contrato
/// (`leitor_da_conversa_contrato_test.dart`).
///
/// ## O que o formato exige, e que um `split('\n')` errado perde
///
/// - O UTF-8 é decodificado **em fluxo**: um caractere de dois ou três bytes
///   (o "ã", o emoji da Memora) pode cair entre dois pedaços da rede, e
///   decodificar pedaço a pedaço o estragaria.
/// - Fim de linha é `\n`, `\r\n` ou `\r`.
/// - Linha que começa com `:` é comentário (o servidor pode mandá-las para
///   manter a conexão viva) e some.
/// - O evento só é despachado na **linha em branco**. Um evento cortado no meio
///   pela queda da conexão **não** é entregue: texto pela metade, tratado como
///   resposta, seria pior que falha.
/// - O valor de `data:` é **tudo** o que vem depois dos dois-pontos, sem tirar
///   espaço nenhum. Aqui o leitor se afasta do SSE padrão, que manda remover um
///   espaço, e de propósito: o Spring escreve `data:` sem espaço e emenda o
///   trecho logo depois. O modelo corta a resposta no meio da frase, e o
///   pedaço seguinte começa justamente com o espaço entre as duas palavras
///   (`data: bastante a enxergar`). Seguir o padrão grudaria as palavras em
///   toda emenda. Isso foi visto no fio, contra o Gemini, em 2026-10-09, e
///   nenhum teste com servidor falso o mostrava.
Stream<EventoSse> lerEventosSse(Stream<List<int>> bytes) async* {
  String nome = '';
  final List<String> dados = <String>[];
  bool primeiraLinha = true;

  await for (String linha
      in utf8.decoder.bind(bytes).transform(const LineSplitter())) {
    if (primeiraLinha) {
      primeiraLinha = false;
      // A marca de ordem de bytes, se vier, não faz parte do primeiro campo.
      if (linha.startsWith('﻿')) linha = linha.substring(1);
    }

    if (linha.isEmpty) {
      // Também despacha evento sem `data:` (só `event:`): o contrato diz que o
      // `fim` traz `data:` vazio, e um servidor que o omitisse não deve fazer a
      // conversa parecer cortada.
      if (dados.isNotEmpty || nome.isNotEmpty) {
        yield EventoSse(nome.isEmpty ? 'message' : nome, dados.join('\n'));
      }
      nome = '';
      dados.clear();
      continue;
    }

    if (linha.startsWith(':')) continue;

    final int doisPontos = linha.indexOf(':');
    final String campo = doisPontos < 0
        ? linha
        : linha.substring(0, doisPontos);
    String valor = doisPontos < 0 ? '' : linha.substring(doisPontos + 1);
    // Só o nome do evento tolera o espaço do padrão; o dado vai inteiro (ver o
    // cabeçalho).
    if (campo != 'data' && valor.startsWith(' ')) valor = valor.substring(1);

    switch (campo) {
      case 'event':
        nome = valor;
      case 'data':
        dados.add(valor);
      // `id` e `retry` existem no formato e não servem a esta conversa.
    }
  }
}

/// Os nomes de evento que o servidor emite e que este leitor interpreta.
///
/// Fica à vista para o teste do contrato conferir cada um contra o que o
/// `openapi.yaml` descreve: um nome que o contrato mudasse e o leitor não
/// acompanhasse viraria resposta que nunca termina — ou que termina vazia.
abstract final class EventosDaConversa {
  /// Um trecho da resposta, em texto puro.
  static const String texto = 'texto';

  /// O aplicativo que a Memora oferece abrir, já autorizado pelo catálogo.
  static const String acao = 'acao';

  /// A resposta terminou bem.
  static const String fim = 'fim';

  /// A conversa falhou. O `codigo` diz como.
  static const String erro = 'erro';

  /// Todos os nomes que o leitor reconhece.
  static const Set<String> todos = <String>{texto, acao, fim, erro};
}

/// Interpreta o fluxo da conversa e o resume numa [RespostaDaAssistente].
///
/// [aoReceberTrecho] é chamado a cada evento `texto`, assim que ele chega.
///
/// ## O que vira falha, e por quê
///
/// - Evento `erro` com `codigo` conhecido: a falha correspondente
///   (`LIMITE_DE_CONVERSAS`, `ASSISTENTE_INDISPONIVEL`, `ERRO_INESPERADO`).
///   **Código que o aplicativo não conhece vira [FalhaDaAssistente.inesperada]**,
///   nunca um comportamento silencioso: código novo no servidor sem o
///   aplicativo acompanhar tem de aparecer.
/// - O fluxo **termina sem `fim` nem `erro`**: [FalhaDaAssistente.semConexao].
///   Do lado do aparelho, a conexão caiu no meio da resposta — é exatamente o
///   que "semConexao" descreve para a pessoa ("o problema é a conexão, não
///   você", FR-052), e é passageira, então oferece tentar de novo. `inesperada`
///   também ofereceria, mas diria "algo não saiu como eu esperava", que culpa o
///   aparelho errado.
/// - A conexão cai com o fluxo aberto (erro de transporte): o chamador trata,
///   como trata a falta de conexão antes do fluxo.
/// - Bytes que não são UTF-8, ou texto em evento que o contrato não prevê:
///   [FalhaDaAssistente.inesperada].
///
/// ## Uma ação defeituosa é descartada, não adivinhada
///
/// Se o JSON do evento `acao` não bate com o contrato, **a oferta não existe**:
/// a pessoa recebe o texto, e nenhum botão de abrir aplicativo. Errar para o
/// lado de não oferecer é o que a Constituição pede da IA que age (Princípio VI);
/// o teste do contrato é quem avisa que o formato mudou.
Future<RespostaDaAssistente> lerConversa(
  Stream<List<int>> bytes, {
  void Function(String trecho)? aoReceberTrecho,
}) async {
  final StringBuffer texto = StringBuffer();
  AcaoAutorizada? acao;

  try {
    await for (final EventoSse evento in lerEventosSse(bytes)) {
      switch (evento.nome) {
        case EventosDaConversa.texto:
          texto.write(evento.dados);
          aoReceberTrecho?.call(evento.dados);

        case EventosDaConversa.acao:
          acao = _acaoDe(evento.dados);

        case EventosDaConversa.fim:
          return AssistenteRespondeu(texto.toString(), acao: acao);

        case EventosDaConversa.erro:
          return AssistenteFalhou(_falhaDe(evento.dados));

        // Evento de nome desconhecido é ignorado, como manda o formato: um
        // servidor mais novo pode acrescentar tipos sem derrubar o app velho.
      }
    }
  } on FormatException {
    // UTF-8 inválido.
    return const AssistenteFalhou(FalhaDaAssistente.inesperada);
  }

  return const AssistenteFalhou(FalhaDaAssistente.semConexao);
}

/// Traduz o JSON do evento `acao`, ou devolve `null` se ele não bate.
AcaoAutorizada? _acaoDe(String dados) {
  try {
    final Object? json = jsonDecode(dados);
    if (json is! Map<String, dynamic>) return null;
    final api.AcaoAutorizada gerada = api.AcaoAutorizada.fromJson(json);
    return AcaoAutorizada(
      servicoId: gerada.servicoId,
      nomeExibido: gerada.nomeExibido,
      identificadorAndroid: gerada.identificadorAndroid,
    );
  } on Exception {
    // FormatException do JSON ou CheckedFromJsonException do modelo gerado.
    return null;
  }
}

/// Traduz o `codigo` do evento `erro` para a falha do domínio.
FalhaDaAssistente _falhaDe(String dados) {
  try {
    final Object? json = jsonDecode(dados);
    if (json is! Map<String, dynamic>) return FalhaDaAssistente.inesperada;
    final api.ErroDaConversa erro = api.ErroDaConversa.fromJson(json);
    return switch (erro.codigo) {
      api.ErroDaConversaCodigoEnum.LIMITE_DE_CONVERSAS =>
        FalhaDaAssistente.limiteDeConversas,
      api.ErroDaConversaCodigoEnum.ASSISTENTE_INDISPONIVEL =>
        FalhaDaAssistente.assistenteIndisponivel,
      api.ErroDaConversaCodigoEnum.ERRO_INESPERADO =>
        FalhaDaAssistente.inesperada,
    };
  } on Exception {
    return FalhaDaAssistente.inesperada;
  }
}

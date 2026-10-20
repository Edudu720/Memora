import 'package:flutter/foundation.dart' show immutable, visibleForTesting;

/// Uma captura de tela embarcada, e o caminho dela (T061, R6).
///
/// ## Por que não é uma `String`
///
/// Um passo que aponta para uma imagem que não existe tem de **não compilar**.
/// Por isso as capturas são constantes nomeadas desta classe — `Passo.captura`
/// só aceita uma [CapturaDoGuia] —, e o caminho se monta a partir da chave do
/// guia e do número do passo, no formato fixo do contrato
/// (`assets/guias/<chave>/passo_<N>.png`). Errar o nome de uma constante é erro
/// de compilação; apontar uma constante para arquivo que a equipe esqueceu de
/// pôr em `assets/` reprova em `catalogo_e_guias_test.dart`.
///
/// ## Por que não é um `enum`
///
/// O data-model descreve "enum de imagem", e a intenção é a mesma. Só que o
/// Dart não aceita `enum` sem nenhuma constante, e **ainda não existe captura
/// nenhuma** — elas vêm com os guias (T070 em diante). Uma constante de
/// enfeite só para o enum compilar poderia ser usada por engano num guia de
/// verdade. Acrescentar uma captura é acrescentar uma `static const` abaixo.
@immutable
final class CapturaDoGuia {
  /// A `chave` do guia a que a captura pertence.
  final String chave;

  /// O número do passo, a partir de 1.
  final int numero;

  const CapturaDoGuia._(this.chave, this.numero);

  /// Só para o teste montar de propósito um guia errado e provar que o portão
  /// o pega. Usar isto em `lib/` é avisado pelo `flutter analyze`.
  @visibleForTesting
  const CapturaDoGuia.paraTeste(String chave, int numero)
    : this._(chave, numero);

  /// O caminho do asset, relativo à raiz do aplicativo.
  String get caminho => 'assets/guias/$chave/passo_$numero.png';

  /// Captura para orientar a baixar na loja oficial (revisão da #47).
  static const CapturaDoGuia lojaOficial = CapturaDoGuia._('loja', 1);

  // WhatsApp (T071)
  /// Captura 1 do WhatsApp.
  static const CapturaDoGuia whatsapp1 = CapturaDoGuia._('whatsapp', 1);
  /// Captura 2 do WhatsApp.
  static const CapturaDoGuia whatsapp2 = CapturaDoGuia._('whatsapp', 2);
  /// Captura 3 do WhatsApp.
  static const CapturaDoGuia whatsapp3 = CapturaDoGuia._('whatsapp', 3);
  /// Captura 4 do WhatsApp.
  static const CapturaDoGuia whatsapp4 = CapturaDoGuia._('whatsapp', 4);

  // Instagram (T071)
  /// Captura 1 do Instagram.
  static const CapturaDoGuia instagram1 = CapturaDoGuia._('instagram', 1);
  /// Captura 2 do Instagram.
  static const CapturaDoGuia instagram2 = CapturaDoGuia._('instagram', 2);
  /// Captura 3 do Instagram.
  static const CapturaDoGuia instagram3 = CapturaDoGuia._('instagram', 3);
  /// Captura 4 do Instagram.
  static const CapturaDoGuia instagram4 = CapturaDoGuia._('instagram', 4);

  // YouTube (T071)
  /// Captura 1 do YouTube.
  static const CapturaDoGuia youtube1 = CapturaDoGuia._('youtube', 1);
  /// Captura 2 do YouTube.
  static const CapturaDoGuia youtube2 = CapturaDoGuia._('youtube', 2);
  /// Captura 3 do YouTube.
  static const CapturaDoGuia youtube3 = CapturaDoGuia._('youtube', 3);
  /// Captura 4 do YouTube.
  static const CapturaDoGuia youtube4 = CapturaDoGuia._('youtube', 4);

  // Facebook (T072)
  /// Captura 1 do Facebook.
  static const CapturaDoGuia facebook1 = CapturaDoGuia._('facebook', 1);
  /// Captura 2 do Facebook.
  static const CapturaDoGuia facebook2 = CapturaDoGuia._('facebook', 2);
  /// Captura 3 do Facebook.
  static const CapturaDoGuia facebook3 = CapturaDoGuia._('facebook', 3);
  /// Captura 4 do Facebook.
  static const CapturaDoGuia facebook4 = CapturaDoGuia._('facebook', 4);

  // Google Fotos (T072)
  /// Captura 1 do Google Fotos.
  static const CapturaDoGuia googleFotos1 = CapturaDoGuia._('google-fotos', 1);
  /// Captura 2 do Google Fotos.
  static const CapturaDoGuia googleFotos2 = CapturaDoGuia._('google-fotos', 2);
  /// Captura 3 do Google Fotos.
  static const CapturaDoGuia googleFotos3 = CapturaDoGuia._('google-fotos', 3);
  /// Captura 4 do Google Fotos.
  static const CapturaDoGuia googleFotos4 = CapturaDoGuia._('google-fotos', 4);

  // Telegram (T072)
  /// Captura 1 do Telegram.
  static const CapturaDoGuia telegram1 = CapturaDoGuia._('telegram', 1);
  /// Captura 2 do Telegram.
  static const CapturaDoGuia telegram2 = CapturaDoGuia._('telegram', 2);
  /// Captura 3 do Telegram.
  static const CapturaDoGuia telegram3 = CapturaDoGuia._('telegram', 3);
  /// Captura 4 do Telegram.
  static const CapturaDoGuia telegram4 = CapturaDoGuia._('telegram', 4);

  // As capturas entram aqui, uma `static const` por imagem, junto com o guia
  // que as usa. Exemplo, quando existir o primeiro:
  //
  //   static const CapturaDoGuia tiktok1 = CapturaDoGuia._('tiktok', 1);

  @override
  bool operator ==(Object other) =>
      other is CapturaDoGuia && other.chave == chave && other.numero == numero;

  @override
  int get hashCode => Object.hash(chave, numero);

  @override
  String toString() => 'CapturaDoGuia($caminho)';
}

/// Uma região da captura, em coordenadas relativas (0 a 1).
///
/// É onde o aplicativo desenha o destaque. Relativa de propósito: o destaque
/// acompanha o tema, tem contraste medido e escala com a tela, e a captura
/// pode ser trocada sem refazer o desenho (R6).
@immutable
class RegiaoRelativa {
  /// Borda esquerda, de 0 a 1.
  final double x;

  /// Borda de cima, de 0 a 1.
  final double y;

  /// Largura, de 0 (exclusive) a 1.
  final double largura;

  /// Altura, de 0 (exclusive) a 1.
  final double altura;

  /// Cria uma região. Uma região que sai da captura é erro de quem escreveu o
  /// guia, e aparece na hora, no modo de depuração.
  const RegiaoRelativa({
    required this.x,
    required this.y,
    required this.largura,
    required this.altura,
  }) : assert(x >= 0 && x <= 1, 'x fora de 0 a 1'),
       assert(y >= 0 && y <= 1, 'y fora de 0 a 1'),
       assert(largura > 0 && largura <= 1, 'largura fora de (0, 1]'),
       assert(altura > 0 && altura <= 1, 'altura fora de (0, 1]'),
       assert(x + largura <= 1.000001, 'a região passa da borda direita'),
       assert(y + altura <= 1.000001, 'a região passa da borda de baixo');

  @override
  bool operator ==(Object other) =>
      other is RegiaoRelativa &&
      other.x == x &&
      other.y == y &&
      other.largura == largura &&
      other.altura == altura;

  @override
  int get hashCode => Object.hash(x, y, largura, altura);
}

/// Uma tela do passo a passo.
@immutable
class Passo {
  /// A captura que a pessoa vê.
  final CapturaDoGuia captura;

  /// Onde tocar. Desenhado pelo aplicativo, por cima da captura.
  final RegiaoRelativa destaque;

  /// Uma ou duas frases, no imperativo gentil da voz da Memora. Uma ação por
  /// passo, dizendo **onde** está ("embaixo, no meio").
  final String texto;

  /// Este passo mostra um campo de senha?
  ///
  /// Quando sim, a tela mostra o aviso "a senha só se digita no aplicativo
  /// oficial, nunca no Memora" (FR-032).
  final bool temCampoDeSenha;

  /// O que a imagem mostra, para o leitor de tela (FR-045).
  final String descricaoDaCaptura;

  /// Cria um passo.
  const Passo({
    required this.captura,
    required this.destaque,
    required this.texto,
    required this.descricaoDaCaptura,
    this.temCampoDeSenha = false,
  });
}

/// O caminho de aprendizado de um item do catálogo.
///
/// É **conteúdo escrito pela equipe**, compilado no aplicativo: não é dado da
/// pessoa e não muda em uso. As regras de produção estão em
/// `specs/004-redesenho-das-telas/contracts/guias.md`, e quem as confere é
/// `catalogo_e_guias_test.dart` — não o construtor, para que o teste consiga
/// montar de propósito um guia errado e provar que o portão o pega.
@immutable
class Guia {
  /// O mínimo de passos: menos que isso não é caminho.
  static const int minimoDePassos = 3;

  /// O máximo de passos: mais que isso cansa e vira dois guias.
  static const int maximoDePassos = 7;

  /// Igual à `chave` de um item de `servico_conhecido`. Única entre os guias.
  final String chave;

  /// "Aprender a usar o TikTok". Vem de `l10n/textos_guias.dart`.
  final String titulo;

  /// O que ter em mãos antes de começar. Obrigatório para serviço sensível
  /// (FR-032); pode ser vazio para cotidiano.
  final List<String> precisaTerEmMaos;

  /// Os passos, em ordem.
  final List<Passo> passos;

  /// Quando as capturas foram feitas (R6): diz à revisão quando refazer.
  final DateTime capturadoEm;

  /// A versão do aplicativo do outro lado, como aparece na loja.
  final String versaoCapturada;

  /// Cria um guia.
  const Guia({
    required this.chave,
    required this.titulo,
    required this.passos,
    required this.capturadoEm,
    required this.versaoCapturada,
    this.precisaTerEmMaos = const <String>[],
  });
}

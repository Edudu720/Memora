import 'package:flutter/foundation.dart' show immutable, visibleForTesting;
import 'package:flutter/widgets.dart' show IconData;

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

  /// Extensão do arquivo de captura ('png' por padrão, ou 'jpg' para capturas otimizadas).
  final String extensao;

  const CapturaDoGuia._(this.chave, this.numero, [this.extensao = 'png']);

  /// Só para o teste montar de propósito um guia errado e provar que o portão
  /// o pega. Usar isto em `lib/` é avisado pelo `flutter analyze`.
  @visibleForTesting
  const CapturaDoGuia.paraTeste(String chave, int numero)
    : this._(chave, numero);

  /// O caminho do asset, relativo à raiz do aplicativo.
  String get caminho => 'assets/guias/$chave/passo_$numero.$extensao';

  /// Captura para orientar a baixar na loja oficial (revisão da #47).
  static const CapturaDoGuia lojaOficial = CapturaDoGuia._('loja', 1);

  // WhatsApp (T071)
  /// Captura 1 do WhatsApp.
  static const CapturaDoGuia whatsapp1 = CapturaDoGuia._('whatsapp', 1, 'jpg');
  /// Captura 2 do WhatsApp.
  static const CapturaDoGuia whatsapp2 = CapturaDoGuia._('whatsapp', 2, 'jpg');
  /// Captura 3 do WhatsApp.
  static const CapturaDoGuia whatsapp3 = CapturaDoGuia._('whatsapp', 3, 'jpg');
  /// Captura 4 do WhatsApp.
  static const CapturaDoGuia whatsapp4 = CapturaDoGuia._('whatsapp', 4, 'jpg');

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
  static const CapturaDoGuia facebook1 = CapturaDoGuia._('facebook', 1, 'jpg');
  /// Captura 2 do Facebook.
  static const CapturaDoGuia facebook2 = CapturaDoGuia._('facebook', 2, 'jpg');
  /// Captura 3 do Facebook.
  static const CapturaDoGuia facebook3 = CapturaDoGuia._('facebook', 3, 'jpg');
  /// Captura 4 do Facebook.
  static const CapturaDoGuia facebook4 = CapturaDoGuia._('facebook', 4, 'jpg');
  /// Captura 5 do Facebook.
  static const CapturaDoGuia facebook5 = CapturaDoGuia._('facebook', 5, 'jpg');
  /// Captura 6 do Facebook.
  static const CapturaDoGuia facebook6 = CapturaDoGuia._('facebook', 6, 'jpg');
  /// Captura 7 do Facebook.
  static const CapturaDoGuia facebook7 = CapturaDoGuia._('facebook', 7, 'jpg');
  /// Captura 8 do Facebook.
  static const CapturaDoGuia facebook8 = CapturaDoGuia._('facebook', 8, 'jpg');
  /// Captura 9 do Facebook.
  static const CapturaDoGuia facebook9 = CapturaDoGuia._('facebook', 9, 'jpg');
  /// Captura 10 do Facebook.
  static const CapturaDoGuia facebook10 = CapturaDoGuia._('facebook', 10, 'jpg');

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
  static const CapturaDoGuia telegram1 = CapturaDoGuia._('telegram', 1, 'jpg');
  /// Captura 2 do Telegram.
  static const CapturaDoGuia telegram2 = CapturaDoGuia._('telegram', 2, 'jpg');
  /// Captura 3 do Telegram.
  static const CapturaDoGuia telegram3 = CapturaDoGuia._('telegram', 3, 'jpg');
  /// Captura 4 do Telegram.
  static const CapturaDoGuia telegram4 = CapturaDoGuia._('telegram', 4, 'jpg');
  /// Captura 5 do Telegram.
  static const CapturaDoGuia telegram5 = CapturaDoGuia._('telegram', 5, 'jpg');
  /// Captura 6 do Telegram.
  static const CapturaDoGuia telegram6 = CapturaDoGuia._('telegram', 6, 'jpg');
  /// Captura 7 do Telegram.
  static const CapturaDoGuia telegram7 = CapturaDoGuia._('telegram', 7, 'jpg');
  /// Captura 8 do Telegram.
  static const CapturaDoGuia telegram8 = CapturaDoGuia._('telegram', 8, 'jpg');

  // TikTok (T070)
  /// Captura 1 do TikTok.
  static const CapturaDoGuia tiktok1 = CapturaDoGuia._('tiktok', 1);
  /// Captura 2 do TikTok.
  static const CapturaDoGuia tiktok2 = CapturaDoGuia._('tiktok', 2);
  /// Captura 3 do TikTok.
  static const CapturaDoGuia tiktok3 = CapturaDoGuia._('tiktok', 3);
  /// Captura 4 do TikTok.
  static const CapturaDoGuia tiktok4 = CapturaDoGuia._('tiktok', 4);

  // Gov.br (T078 + Feature 006 Seções)
  /// Captura 1 do Gov.br.
  static const CapturaDoGuia govBr1 = CapturaDoGuia._('gov-br', 1, 'jpg');
  /// Captura 2 do Gov.br.
  static const CapturaDoGuia govBr2 = CapturaDoGuia._('gov-br', 2, 'jpg');
  /// Captura 3 do Gov.br (com campo de senha vazio).
  static const CapturaDoGuia govBr3 = CapturaDoGuia._('gov-br', 3, 'jpg');
  /// Captura 4 do Gov.br.
  static const CapturaDoGuia govBr4 = CapturaDoGuia._('gov-br', 4, 'jpg');
  /// Captura 5 do Gov.br.
  static const CapturaDoGuia govBr5 = CapturaDoGuia._('gov-br', 5, 'jpg');
  /// Captura 6 do Gov.br.
  static const CapturaDoGuia govBr6 = CapturaDoGuia._('gov-br', 6, 'jpg');
  /// Captura 7 do Gov.br.
  static const CapturaDoGuia govBr7 = CapturaDoGuia._('gov-br', 7, 'jpg');
  /// Captura 8 do Gov.br.
  static const CapturaDoGuia govBr8 = CapturaDoGuia._('gov-br', 8, 'jpg');
  /// Captura 9 do Gov.br.
  static const CapturaDoGuia govBr9 = CapturaDoGuia._('gov-br', 9, 'jpg');
  /// Captura 10 do Gov.br.
  static const CapturaDoGuia govBr10 = CapturaDoGuia._('gov-br', 10, 'jpg');
  /// Captura 11 do Gov.br.
  static const CapturaDoGuia govBr11 = CapturaDoGuia._('gov-br', 11, 'jpg');
  /// Captura 12 do Gov.br.
  static const CapturaDoGuia govBr12 = CapturaDoGuia._('gov-br', 12, 'jpg');
  /// Captura 13 do Gov.br.
  static const CapturaDoGuia govBr13 = CapturaDoGuia._('gov-br', 13, 'jpg');
  /// Captura 14 do Gov.br.
  static const CapturaDoGuia govBr14 = CapturaDoGuia._('gov-br', 14, 'jpg');
  /// Captura 15 do Gov.br.
  static const CapturaDoGuia govBr15 = CapturaDoGuia._('gov-br', 15, 'jpg');
  /// Captura 16 do Gov.br.
  static const CapturaDoGuia govBr16 = CapturaDoGuia._('gov-br', 16, 'jpg');
  /// Captura 17 do Gov.br.
  static const CapturaDoGuia govBr17 = CapturaDoGuia._('gov-br', 17, 'jpg');
  /// Captura 18 do Gov.br.
  static const CapturaDoGuia govBr18 = CapturaDoGuia._('gov-br', 18, 'jpg');
  /// Captura 19 do Gov.br.
  static const CapturaDoGuia govBr19 = CapturaDoGuia._('gov-br', 19, 'jpg');
  /// Captura 20 do Gov.br.
  static const CapturaDoGuia govBr20 = CapturaDoGuia._('gov-br', 20, 'jpg');
  /// Captura 21 do Gov.br.
  static const CapturaDoGuia govBr21 = CapturaDoGuia._('gov-br', 21, 'jpg');
  /// Captura 22 do Gov.br.
  static const CapturaDoGuia govBr22 = CapturaDoGuia._('gov-br', 22, 'jpg');
  /// Captura 23 do Gov.br.
  static const CapturaDoGuia govBr23 = CapturaDoGuia._('gov-br', 23, 'jpg');
  /// Captura 24 do Gov.br.
  static const CapturaDoGuia govBr24 = CapturaDoGuia._('gov-br', 24, 'jpg');

  // Meu INSS (T079)
  /// Captura 1 do Meu INSS.
  static const CapturaDoGuia meuInss1 = CapturaDoGuia._('meu-inss', 1);
  /// Captura 2 do Meu INSS (com tela de senha oficial vazia).
  static const CapturaDoGuia meuInss2 = CapturaDoGuia._('meu-inss', 2);
  /// Captura 3 do Meu INSS.
  static const CapturaDoGuia meuInss3 = CapturaDoGuia._('meu-inss', 3);
  /// Captura 4 do Meu INSS.
  static const CapturaDoGuia meuInss4 = CapturaDoGuia._('meu-inss', 4);

  // e-Título (T081)
  /// Captura 1 do e-Título.
  static const CapturaDoGuia eTitulo1 = CapturaDoGuia._('e-titulo', 1);
  /// Captura 2 do e-Título.
  static const CapturaDoGuia eTitulo2 = CapturaDoGuia._('e-titulo', 2);
  /// Captura 3 do e-Título (com campo de senha oficial vazio).
  static const CapturaDoGuia eTitulo3 = CapturaDoGuia._('e-titulo', 3);
  /// Captura 4 do e-Título.
  static const CapturaDoGuia eTitulo4 = CapturaDoGuia._('e-titulo', 4);

  // Serasa (T081 + Feature 006 Seções)
  /// Captura 1 do Serasa.
  static const CapturaDoGuia serasa1 = CapturaDoGuia._('serasa', 1, 'jpg');
  /// Captura 2 do Serasa.
  static const CapturaDoGuia serasa2 = CapturaDoGuia._('serasa', 2, 'jpg');
  /// Captura 3 do Serasa.
  static const CapturaDoGuia serasa3 = CapturaDoGuia._('serasa', 3, 'jpg');
  /// Captura 4 do Serasa.
  static const CapturaDoGuia serasa4 = CapturaDoGuia._('serasa', 4, 'jpg');
  /// Captura 5 do Serasa.
  static const CapturaDoGuia serasa5 = CapturaDoGuia._('serasa', 5, 'jpg');
  /// Captura 6 do Serasa.
  static const CapturaDoGuia serasa6 = CapturaDoGuia._('serasa', 6, 'jpg');
  /// Captura 7 do Serasa.
  static const CapturaDoGuia serasa7 = CapturaDoGuia._('serasa', 7, 'jpg');
  /// Captura 8 do Serasa.
  static const CapturaDoGuia serasa8 = CapturaDoGuia._('serasa', 8, 'jpg');
  /// Captura 9 do Serasa.
  static const CapturaDoGuia serasa9 = CapturaDoGuia._('serasa', 9, 'jpg');
  /// Captura 10 do Serasa.
  static const CapturaDoGuia serasa10 = CapturaDoGuia._('serasa', 10, 'jpg');
  /// Captura 11 do Serasa.
  static const CapturaDoGuia serasa11 = CapturaDoGuia._('serasa', 11, 'jpg');
  /// Captura 12 do Serasa.
  static const CapturaDoGuia serasa12 = CapturaDoGuia._('serasa', 12, 'jpg');
  /// Captura 13 do Serasa.
  static const CapturaDoGuia serasa13 = CapturaDoGuia._('serasa', 13, 'jpg');
  /// Captura 14 do Serasa.
  static const CapturaDoGuia serasa14 = CapturaDoGuia._('serasa', 14, 'jpg');
  /// Captura 15 do Serasa.
  static const CapturaDoGuia serasa15 = CapturaDoGuia._('serasa', 15, 'jpg');
  /// Captura 16 do Serasa.
  static const CapturaDoGuia serasa16 = CapturaDoGuia._('serasa', 16, 'jpg');
  /// Captura 17 do Serasa.
  static const CapturaDoGuia serasa17 = CapturaDoGuia._('serasa', 17, 'jpg');
  /// Captura 18 do Serasa.
  static const CapturaDoGuia serasa18 = CapturaDoGuia._('serasa', 18, 'jpg');
  /// Captura 19 do Serasa.
  static const CapturaDoGuia serasa19 = CapturaDoGuia._('serasa', 19, 'jpg');
  /// Captura 20 do Serasa.
  static const CapturaDoGuia serasa20 = CapturaDoGuia._('serasa', 20, 'jpg');
  /// Captura 21 do Serasa.
  static const CapturaDoGuia serasa21 = CapturaDoGuia._('serasa', 21, 'jpg');
  /// Captura 22 do Serasa.
  static const CapturaDoGuia serasa22 = CapturaDoGuia._('serasa', 22, 'jpg');

  // FGTS (T081)
  /// Captura 1 do FGTS.
  static const CapturaDoGuia fgts1 = CapturaDoGuia._('fgts', 1);
  /// Captura 2 do FGTS (com campo de senha oficial Caixa vazio).
  static const CapturaDoGuia fgts2 = CapturaDoGuia._('fgts', 2);
  /// Captura 3 do FGTS.
  static const CapturaDoGuia fgts3 = CapturaDoGuia._('fgts', 3);
  /// Captura 4 do FGTS.
  static const CapturaDoGuia fgts4 = CapturaDoGuia._('fgts', 4);

  // Poupatempo (T081)
  /// Captura 1 do Poupatempo.
  static const CapturaDoGuia poupatempo1 = CapturaDoGuia._('poupatempo', 1);
  /// Captura 2 do Poupatempo (com campo de senha oficial vazio).
  static const CapturaDoGuia poupatempo2 = CapturaDoGuia._('poupatempo', 2);
  /// Captura 3 do Poupatempo.
  static const CapturaDoGuia poupatempo3 = CapturaDoGuia._('poupatempo', 3);
  /// Captura 4 do Poupatempo.
  static const CapturaDoGuia poupatempo4 = CapturaDoGuia._('poupatempo', 4);

  // Carteira Digital (T082)
  /// Captura 1 da Carteira Digital.
  static const CapturaDoGuia carteiraDigital1 = CapturaDoGuia._('carteira-digital', 1);
  /// Captura 2 da Carteira Digital (com campo de senha oficial Gov.br vazio).
  static const CapturaDoGuia carteiraDigital2 = CapturaDoGuia._('carteira-digital', 2);
  /// Captura 3 da Carteira Digital.
  static const CapturaDoGuia carteiraDigital3 = CapturaDoGuia._('carteira-digital', 3);
  /// Captura 4 da Carteira Digital.
  static const CapturaDoGuia carteiraDigital4 = CapturaDoGuia._('carteira-digital', 4);

  // Correios (T082 + Feature 006 Seções)
  /// Captura 1 dos Correios.
  static const CapturaDoGuia correios1 = CapturaDoGuia._('correios', 1, 'jpg');
  /// Captura 2 dos Correios.
  static const CapturaDoGuia correios2 = CapturaDoGuia._('correios', 2, 'jpg');
  /// Captura 3 dos Correios.
  static const CapturaDoGuia correios3 = CapturaDoGuia._('correios', 3, 'jpg');
  /// Captura 4 dos Correios.
  static const CapturaDoGuia correios4 = CapturaDoGuia._('correios', 4, 'jpg');
  /// Captura 5 dos Correios.
  static const CapturaDoGuia correios5 = CapturaDoGuia._('correios', 5, 'jpg');
  /// Captura 6 dos Correios.
  static const CapturaDoGuia correios6 = CapturaDoGuia._('correios', 6, 'jpg');
  /// Captura 7 dos Correios.
  static const CapturaDoGuia correios7 = CapturaDoGuia._('correios', 7, 'jpg');
  /// Captura 8 dos Correios (com campo de senha oficial vazio).
  static const CapturaDoGuia correios8 = CapturaDoGuia._('correios', 8, 'jpg');

  // Carteira de Trabalho Digital (T082)
  /// Captura 1 da Carteira de Trabalho Digital.
  static const CapturaDoGuia carteiraDeTrabalho1 = CapturaDoGuia._('carteira-de-trabalho', 1);
  /// Captura 2 da Carteira de Trabalho Digital (com campo de senha Gov.br vazio).
  static const CapturaDoGuia carteiraDeTrabalho2 = CapturaDoGuia._('carteira-de-trabalho', 2);
  /// Captura 3 da Carteira de Trabalho Digital.
  static const CapturaDoGuia carteiraDeTrabalho3 = CapturaDoGuia._('carteira-de-trabalho', 3);
  /// Captura 4 da Carteira de Trabalho Digital.
  static const CapturaDoGuia carteiraDeTrabalho4 = CapturaDoGuia._('carteira-de-trabalho', 4);

  // As capturas entram aqui, uma `static const` por imagem, junto com o guia
  // que as usa. Exemplo, quando existir o primeiro:
  //
  //   static const CapturaDoGuia tiktok1 = CapturaDoGuia._('tiktok', 1);

  @override
  bool operator ==(Object other) =>
      other is CapturaDoGuia &&
      other.chave == chave &&
      other.numero == numero &&
      other.extensao == extensao;

  @override
  int get hashCode => Object.hash(chave, numero, extensao);

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

/// Uma seção temática dentro de um guia extenso (ex.: "Baixar Certidões" no Gov.br).
///
/// Permite que a pessoa idosa escolha exatamente o assunto que deseja aprender
/// sem precisar percorrer dezenas de telas seguidas (Feature 006).
@immutable
class SecaoDoGuia {
  /// Chave única da seção dentro do guia (ex.: `'entrar-conta'`).
  final String chave;

  /// Título curto e literal exibido no cartão de escolha.
  final String titulo;

  /// Uma linha explicando o que a pessoa vai aprender nesta seção.
  final String subtitulo;

  /// Ícone que acompanha o título (nunca isolado — Constituição III).
  final IconData icone;

  /// Itens específicos para ter em mãos antes de iniciar esta seção.
  final List<String> precisaTerEmMaos;

  /// Passos da seção (entre [Guia.minimoDePassos] e [Guia.maximoDePassos]).
  final List<Passo> passos;

  /// Cria uma seção temática de um guia.
  const SecaoDoGuia({
    required this.chave,
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.passos,
    this.precisaTerEmMaos = const <String>[],
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

  /// Os passos, em ordem (usados quando [secoes] estiver vazio).
  final List<Passo> passos;

  /// Seções temáticas opcionais para serviços extensos (ex.: Gov.br, Serasa, Correios).
  final List<SecaoDoGuia> secoes;

  /// Quando as capturas foram feitas (R6): diz à revisão quando refazer.
  final DateTime capturadoEm;

  /// A versão do aplicativo do outro lado, como aparece na loja.
  final String versaoCapturada;

  /// Se o guia possui seções temáticas para escolha prévia.
  bool get temSecoes => secoes.isNotEmpty;

  /// Todos os passos do guia (diretos ou agrupados nas seções).
  List<Passo> get todosOsPassos => secoes.isEmpty
      ? passos
      : <Passo>[for (final SecaoDoGuia secao in secoes) ...secao.passos];

  /// Cria um guia.
  const Guia({
    required this.chave,
    required this.titulo,
    required this.capturadoEm,
    required this.versaoCapturada,
    this.passos = const <Passo>[],
    this.secoes = const <SecaoDoGuia>[],
    this.precisaTerEmMaos = const <String>[],
  });
}

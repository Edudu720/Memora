import 'package:flutter/foundation.dart' show immutable, visibleForTesting;
import 'package:flutter/widgets.dart' show IconData;

/// O formato do arquivo de uma captura (clarificação de 2026-11-12).
///
/// **WebP é o padrão**: os prints chegam da equipe nesse formato, e ele cabe no
/// teto de `assets/guias/` onde o PNG de um print de celular não cabe. **PNG é
/// a exceção, por captura**: quando o WebP perder nitidez no texto ao ampliar
/// (FR-028b), aquela imagem — e só ela — volta a PNG.
///
/// **JPG é exceção legada, temporária**: capturas JPG com a marcação pintada na
/// própria imagem, vindas da #71 (feature 006). São aceitas até serem
/// substituídas por um print com o destaque desenhado pelo aplicativo; não
/// entra captura nova nesse formato. As que existem estão listadas em
/// `capturasLegadasDaPr71`, no teste do contrato dos guias.
enum FormatoDaCaptura {
  /// O padrão.
  webp,

  /// Para a captura cujo texto borra no zoom em WebP.
  png,

  /// Legado da #71 (feature 006): JPG com marcação pintada, a substituir por
  /// print com destaque desenhado pelo app.
  jpg;

  /// A extensão do arquivo, sem o ponto.
  String get extensao => name;

  /// A imagem já traz a marcação pintada nela? Quando sim, o aplicativo **não
  /// desenha outro destaque** por cima (seria um segundo círculo, em outro
  /// lugar). Só o legado JPG da #71 é assim.
  bool get temMarcacaoPintada => this == FormatoDaCaptura.jpg;
}

/// Uma captura de tela embarcada, e o caminho dela (T061, R6).
///
/// ## Por que não é uma `String`
///
/// Um passo que aponta para uma imagem que não existe tem de **não compilar**.
/// Por isso as capturas são constantes nomeadas desta classe — `Passo.captura`
/// só aceita uma [CapturaDoGuia] —, e o caminho se monta a partir da chave do
/// guia, do número do passo e do [formato], no formato fixo do contrato
/// (`assets/guias/<chave>/passo_<N>.webp`, ou `.png` na exceção). Errar o nome
/// de uma constante é erro de compilação; apontar uma constante para arquivo
/// que a equipe esqueceu de pôr em `assets/` — ou com a extensão trocada —
/// reprova em `catalogo_e_guias_test.dart`.
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

  /// O formato do arquivo. Para pôr uma captura em PNG, passe
  /// `FormatoDaCaptura.png` como terceiro argumento da constante dela.
  final FormatoDaCaptura formato;

  const CapturaDoGuia._(
    this.chave,
    this.numero, [
    this.formato = FormatoDaCaptura.webp,
  ]);

  /// Só para o teste montar de propósito um guia errado e provar que o portão
  /// o pega. Usar isto em `lib/` é avisado pelo `flutter analyze`.
  @visibleForTesting
  const CapturaDoGuia.paraTeste(
    String chave,
    int numero, {
    FormatoDaCaptura formato = FormatoDaCaptura.webp,
  }) : this._(chave, numero, formato);

  /// O caminho do asset, relativo à raiz do aplicativo.
  String get caminho => 'assets/guias/$chave/passo_$numero.${formato.extensao}';

  /// Captura para orientar a baixar na loja oficial (revisão da #47).
  static const CapturaDoGuia lojaOficial = CapturaDoGuia._('loja', 1);

  // WhatsApp (T071)
  /// Captura 1 do WhatsApp.
  static const CapturaDoGuia whatsapp1 = CapturaDoGuia._(
    'whatsapp',
    1,
    FormatoDaCaptura.jpg,
  );

  /// Captura 2 do WhatsApp.
  static const CapturaDoGuia whatsapp2 = CapturaDoGuia._(
    'whatsapp',
    2,
    FormatoDaCaptura.jpg,
  );

  /// Captura 3 do WhatsApp.
  static const CapturaDoGuia whatsapp3 = CapturaDoGuia._(
    'whatsapp',
    3,
    FormatoDaCaptura.jpg,
  );

  /// Captura 4 do WhatsApp.
  static const CapturaDoGuia whatsapp4 = CapturaDoGuia._(
    'whatsapp',
    4,
    FormatoDaCaptura.jpg,
  );

  /// Captura 5 do WhatsApp.
  static const CapturaDoGuia whatsapp5 = CapturaDoGuia._(
    'whatsapp',
    5,
    FormatoDaCaptura.jpg,
  );

  // Instagram (T071)
  /// Captura 1 do Instagram.
  static const CapturaDoGuia instagram1 = CapturaDoGuia._('instagram', 1);

  /// Captura 2 do Instagram.
  static const CapturaDoGuia instagram2 = CapturaDoGuia._('instagram', 2);

  /// Captura 3 do Instagram.
  static const CapturaDoGuia instagram3 = CapturaDoGuia._('instagram', 3);

  /// Captura 4 do Instagram.
  static const CapturaDoGuia instagram4 = CapturaDoGuia._('instagram', 4);

  /// Captura 5 do Instagram.
  static const CapturaDoGuia instagram5 = CapturaDoGuia._('instagram', 5);

  /// Captura 6 do Instagram.
  static const CapturaDoGuia instagram6 = CapturaDoGuia._('instagram', 6);

  /// Captura 7 do Instagram.
  static const CapturaDoGuia instagram7 = CapturaDoGuia._('instagram', 7);

  /// Captura 8 do Instagram.
  static const CapturaDoGuia instagram8 = CapturaDoGuia._('instagram', 8);

  /// Captura 9 do Instagram.
  static const CapturaDoGuia instagram9 = CapturaDoGuia._('instagram', 9);

  /// Captura 10 do Instagram.
  static const CapturaDoGuia instagram10 = CapturaDoGuia._('instagram', 10);

  /// Captura 11 do Instagram (um story).
  static const CapturaDoGuia instagram11 = CapturaDoGuia._('instagram', 11);

  // YouTube (T071 + Feature 016)
  /// Captura 1 do YouTube.
  static const CapturaDoGuia youtube1 = CapturaDoGuia._('youtube', 1);

  /// Captura 2 do YouTube.
  static const CapturaDoGuia youtube2 = CapturaDoGuia._('youtube', 2);

  /// Captura 3 do YouTube.
  static const CapturaDoGuia youtube3 = CapturaDoGuia._('youtube', 3);

  /// Captura 4 do YouTube.
  static const CapturaDoGuia youtube4 = CapturaDoGuia._('youtube', 4);

  /// Captura 5 do YouTube.
  static const CapturaDoGuia youtube5 = CapturaDoGuia._('youtube', 5);

  /// Captura 6 do YouTube.
  static const CapturaDoGuia youtube6 = CapturaDoGuia._('youtube', 6);

  /// Captura 7 do YouTube.
  static const CapturaDoGuia youtube7 = CapturaDoGuia._('youtube', 7);

  // Facebook (T072)
  /// Captura 1 do Facebook.
  static const CapturaDoGuia facebook1 = CapturaDoGuia._(
    'facebook',
    1,
    FormatoDaCaptura.jpg,
  );

  /// Captura 2 do Facebook.
  static const CapturaDoGuia facebook2 = CapturaDoGuia._(
    'facebook',
    2,
    FormatoDaCaptura.jpg,
  );

  /// Captura 3 do Facebook.
  static const CapturaDoGuia facebook3 = CapturaDoGuia._(
    'facebook',
    3,
    FormatoDaCaptura.jpg,
  );

  /// Captura 4 do Facebook.
  static const CapturaDoGuia facebook4 = CapturaDoGuia._(
    'facebook',
    4,
    FormatoDaCaptura.jpg,
  );

  /// Captura 5 do Facebook.
  static const CapturaDoGuia facebook5 = CapturaDoGuia._(
    'facebook',
    5,
    FormatoDaCaptura.jpg,
  );

  /// Captura 6 do Facebook.
  static const CapturaDoGuia facebook6 = CapturaDoGuia._(
    'facebook',
    6,
    FormatoDaCaptura.jpg,
  );

  /// Captura 7 do Facebook.
  static const CapturaDoGuia facebook7 = CapturaDoGuia._(
    'facebook',
    7,
    FormatoDaCaptura.jpg,
  );

  /// Captura 8 do Facebook.
  static const CapturaDoGuia facebook8 = CapturaDoGuia._(
    'facebook',
    8,
    FormatoDaCaptura.jpg,
  );

  /// Captura 9 do Facebook.
  static const CapturaDoGuia facebook9 = CapturaDoGuia._(
    'facebook',
    9,
    FormatoDaCaptura.jpg,
  );

  /// Captura 10 do Facebook.
  static const CapturaDoGuia facebook10 = CapturaDoGuia._(
    'facebook',
    10,
    FormatoDaCaptura.jpg,
  );

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
  static const CapturaDoGuia telegram1 = CapturaDoGuia._(
    'telegram',
    1,
    FormatoDaCaptura.jpg,
  );

  /// Captura 2 do Telegram.
  static const CapturaDoGuia telegram2 = CapturaDoGuia._(
    'telegram',
    2,
    FormatoDaCaptura.jpg,
  );

  /// Captura 3 do Telegram.
  static const CapturaDoGuia telegram3 = CapturaDoGuia._(
    'telegram',
    3,
    FormatoDaCaptura.jpg,
  );

  /// Captura 4 do Telegram.
  static const CapturaDoGuia telegram4 = CapturaDoGuia._(
    'telegram',
    4,
    FormatoDaCaptura.jpg,
  );

  /// Captura 5 do Telegram.
  static const CapturaDoGuia telegram5 = CapturaDoGuia._(
    'telegram',
    5,
    FormatoDaCaptura.jpg,
  );

  /// Captura 6 do Telegram.
  static const CapturaDoGuia telegram6 = CapturaDoGuia._(
    'telegram',
    6,
    FormatoDaCaptura.jpg,
  );

  /// Captura 7 do Telegram.
  static const CapturaDoGuia telegram7 = CapturaDoGuia._(
    'telegram',
    7,
    FormatoDaCaptura.jpg,
  );

  /// Captura 8 do Telegram.
  static const CapturaDoGuia telegram8 = CapturaDoGuia._(
    'telegram',
    8,
    FormatoDaCaptura.jpg,
  );

  // TikTok (T070 + Feature 016)
  /// Captura 1 do TikTok.
  static const CapturaDoGuia tiktok1 = CapturaDoGuia._('tiktok', 1);

  /// Captura 2 do TikTok.
  static const CapturaDoGuia tiktok2 = CapturaDoGuia._('tiktok', 2);

  /// Captura 3 do TikTok.
  static const CapturaDoGuia tiktok3 = CapturaDoGuia._('tiktok', 3);

  /// Captura 4 do TikTok.
  static const CapturaDoGuia tiktok4 = CapturaDoGuia._('tiktok', 4);

  /// Captura 5 do TikTok.
  static const CapturaDoGuia tiktok5 = CapturaDoGuia._('tiktok', 5);

  /// Captura 6 do TikTok.
  static const CapturaDoGuia tiktok6 = CapturaDoGuia._('tiktok', 6);

  // Gov.br (T078 + Feature 006 Seções)
  /// Captura 1 do Gov.br.
  static const CapturaDoGuia govBr1 = CapturaDoGuia._(
    'gov-br',
    1,
    FormatoDaCaptura.jpg,
  );

  /// Captura 2 do Gov.br.
  static const CapturaDoGuia govBr2 = CapturaDoGuia._(
    'gov-br',
    2,
    FormatoDaCaptura.jpg,
  );

  /// Captura 3 do Gov.br (com campo de senha vazio).
  static const CapturaDoGuia govBr3 = CapturaDoGuia._(
    'gov-br',
    3,
    FormatoDaCaptura.jpg,
  );

  /// Captura 4 do Gov.br.
  static const CapturaDoGuia govBr4 = CapturaDoGuia._(
    'gov-br',
    4,
    FormatoDaCaptura.jpg,
  );

  /// Captura 5 do Gov.br.
  static const CapturaDoGuia govBr5 = CapturaDoGuia._(
    'gov-br',
    5,
    FormatoDaCaptura.jpg,
  );

  /// Captura 6 do Gov.br.
  static const CapturaDoGuia govBr6 = CapturaDoGuia._(
    'gov-br',
    6,
    FormatoDaCaptura.jpg,
  );

  /// Captura 7 do Gov.br.
  static const CapturaDoGuia govBr7 = CapturaDoGuia._(
    'gov-br',
    7,
    FormatoDaCaptura.jpg,
  );

  /// Captura 8 do Gov.br.
  static const CapturaDoGuia govBr8 = CapturaDoGuia._(
    'gov-br',
    8,
    FormatoDaCaptura.jpg,
  );

  /// Captura 9 do Gov.br.
  static const CapturaDoGuia govBr9 = CapturaDoGuia._(
    'gov-br',
    9,
    FormatoDaCaptura.jpg,
  );

  /// Captura 10 do Gov.br.
  static const CapturaDoGuia govBr10 = CapturaDoGuia._(
    'gov-br',
    10,
    FormatoDaCaptura.jpg,
  );

  /// Captura 11 do Gov.br.
  static const CapturaDoGuia govBr11 = CapturaDoGuia._(
    'gov-br',
    11,
    FormatoDaCaptura.jpg,
  );

  /// Captura 12 do Gov.br.
  static const CapturaDoGuia govBr12 = CapturaDoGuia._(
    'gov-br',
    12,
    FormatoDaCaptura.jpg,
  );

  /// Captura 13 do Gov.br.
  static const CapturaDoGuia govBr13 = CapturaDoGuia._(
    'gov-br',
    13,
    FormatoDaCaptura.jpg,
  );

  /// Captura 14 do Gov.br.
  static const CapturaDoGuia govBr14 = CapturaDoGuia._(
    'gov-br',
    14,
    FormatoDaCaptura.jpg,
  );

  /// Captura 15 do Gov.br.
  static const CapturaDoGuia govBr15 = CapturaDoGuia._(
    'gov-br',
    15,
    FormatoDaCaptura.jpg,
  );

  /// Captura 16 do Gov.br.
  static const CapturaDoGuia govBr16 = CapturaDoGuia._(
    'gov-br',
    16,
    FormatoDaCaptura.jpg,
  );

  /// Captura 17 do Gov.br.
  static const CapturaDoGuia govBr17 = CapturaDoGuia._(
    'gov-br',
    17,
    FormatoDaCaptura.jpg,
  );

  /// Captura 18 do Gov.br.
  static const CapturaDoGuia govBr18 = CapturaDoGuia._(
    'gov-br',
    18,
    FormatoDaCaptura.jpg,
  );

  /// Captura 19 do Gov.br.
  static const CapturaDoGuia govBr19 = CapturaDoGuia._(
    'gov-br',
    19,
    FormatoDaCaptura.jpg,
  );

  /// Captura 20 do Gov.br.
  static const CapturaDoGuia govBr20 = CapturaDoGuia._(
    'gov-br',
    20,
    FormatoDaCaptura.jpg,
  );

  /// Captura 21 do Gov.br.
  static const CapturaDoGuia govBr21 = CapturaDoGuia._(
    'gov-br',
    21,
    FormatoDaCaptura.jpg,
  );

  /// Captura 22 do Gov.br.
  static const CapturaDoGuia govBr22 = CapturaDoGuia._(
    'gov-br',
    22,
    FormatoDaCaptura.jpg,
  );

  /// Captura 23 do Gov.br.
  static const CapturaDoGuia govBr23 = CapturaDoGuia._(
    'gov-br',
    23,
    FormatoDaCaptura.jpg,
  );

  /// Captura 24 do Gov.br.
  static const CapturaDoGuia govBr24 = CapturaDoGuia._(
    'gov-br',
    24,
    FormatoDaCaptura.jpg,
  );

  // Meu INSS (T079 + Feature 016 Seções)
  /// Captura 1 do Meu INSS.
  static const CapturaDoGuia meuInss1 = CapturaDoGuia._('meu-inss', 1);

  /// Captura 2 do Meu INSS.
  static const CapturaDoGuia meuInss2 = CapturaDoGuia._('meu-inss', 2);

  /// Captura 3 do Meu INSS.
  static const CapturaDoGuia meuInss3 = CapturaDoGuia._('meu-inss', 3);

  /// Captura 4 do Meu INSS.
  static const CapturaDoGuia meuInss4 = CapturaDoGuia._('meu-inss', 4);

  /// Captura 5 do Meu INSS.
  static const CapturaDoGuia meuInss5 = CapturaDoGuia._('meu-inss', 5);

  /// Captura 6 do Meu INSS.
  static const CapturaDoGuia meuInss6 = CapturaDoGuia._('meu-inss', 6);

  /// Captura 7 do Meu INSS.
  static const CapturaDoGuia meuInss7 = CapturaDoGuia._('meu-inss', 7);

  /// Captura 8 do Meu INSS.
  static const CapturaDoGuia meuInss8 = CapturaDoGuia._('meu-inss', 8);

  /// Captura 9 do Meu INSS.
  static const CapturaDoGuia meuInss9 = CapturaDoGuia._('meu-inss', 9);

  /// Captura 10 do Meu INSS.
  static const CapturaDoGuia meuInss10 = CapturaDoGuia._('meu-inss', 10);

  /// Captura 11 do Meu INSS.
  static const CapturaDoGuia meuInss11 = CapturaDoGuia._('meu-inss', 11);

  /// Captura 12 do Meu INSS.
  static const CapturaDoGuia meuInss12 = CapturaDoGuia._('meu-inss', 12);

  /// Captura 13 do Meu INSS.
  static const CapturaDoGuia meuInss13 = CapturaDoGuia._('meu-inss', 13);

  /// Captura 14 do Meu INSS.
  static const CapturaDoGuia meuInss14 = CapturaDoGuia._('meu-inss', 14);

  /// Captura 15 do Meu INSS.
  static const CapturaDoGuia meuInss15 = CapturaDoGuia._('meu-inss', 15);

  /// Captura 16 do Meu INSS.
  static const CapturaDoGuia meuInss16 = CapturaDoGuia._('meu-inss', 16);

  /// Captura 17 do Meu INSS.
  static const CapturaDoGuia meuInss17 = CapturaDoGuia._('meu-inss', 17);

  /// Captura 18 do Meu INSS.
  static const CapturaDoGuia meuInss18 = CapturaDoGuia._('meu-inss', 18);

  /// Captura 19 do Meu INSS.
  static const CapturaDoGuia meuInss19 = CapturaDoGuia._('meu-inss', 19);

  // e-Título (T081)
  /// Captura 1 do e-Título (a entrada, com biometria).
  static const CapturaDoGuia eTitulo1 = CapturaDoGuia._('e-titulo', 1);

  /// Captura 2 do e-Título (o título de eleitor).
  static const CapturaDoGuia eTitulo2 = CapturaDoGuia._('e-titulo', 2);

  /// Captura 3 do e-Título (Onde votar).
  static const CapturaDoGuia eTitulo3 = CapturaDoGuia._('e-titulo', 3);

  /// Captura 4 do e-Título (ChatVote).
  static const CapturaDoGuia eTitulo4 = CapturaDoGuia._('e-titulo', 4);

  /// Captura 5 do e-Título (Notificações).
  static const CapturaDoGuia eTitulo5 = CapturaDoGuia._('e-titulo', 5);

  /// Captura 6 do e-Título (Mais opções).
  static const CapturaDoGuia eTitulo6 = CapturaDoGuia._('e-titulo', 6);

  // Serasa (T081 + Feature 006 Seções)
  /// Captura 1 do Serasa.
  static const CapturaDoGuia serasa1 = CapturaDoGuia._(
    'serasa',
    1,
    FormatoDaCaptura.jpg,
  );

  /// Captura 2 do Serasa.
  static const CapturaDoGuia serasa2 = CapturaDoGuia._(
    'serasa',
    2,
    FormatoDaCaptura.jpg,
  );

  /// Captura 3 do Serasa.
  static const CapturaDoGuia serasa3 = CapturaDoGuia._(
    'serasa',
    3,
    FormatoDaCaptura.jpg,
  );

  /// Captura 4 do Serasa.
  static const CapturaDoGuia serasa4 = CapturaDoGuia._(
    'serasa',
    4,
    FormatoDaCaptura.jpg,
  );

  /// Captura 5 do Serasa.
  static const CapturaDoGuia serasa5 = CapturaDoGuia._(
    'serasa',
    5,
    FormatoDaCaptura.jpg,
  );

  /// Captura 6 do Serasa.
  static const CapturaDoGuia serasa6 = CapturaDoGuia._(
    'serasa',
    6,
    FormatoDaCaptura.jpg,
  );

  /// Captura 7 do Serasa.
  static const CapturaDoGuia serasa7 = CapturaDoGuia._(
    'serasa',
    7,
    FormatoDaCaptura.jpg,
  );

  /// Captura 8 do Serasa.
  static const CapturaDoGuia serasa8 = CapturaDoGuia._(
    'serasa',
    8,
    FormatoDaCaptura.jpg,
  );

  /// Captura 9 do Serasa.
  static const CapturaDoGuia serasa9 = CapturaDoGuia._(
    'serasa',
    9,
    FormatoDaCaptura.jpg,
  );

  /// Captura 10 do Serasa.
  static const CapturaDoGuia serasa10 = CapturaDoGuia._(
    'serasa',
    10,
    FormatoDaCaptura.jpg,
  );

  /// Captura 11 do Serasa.
  static const CapturaDoGuia serasa11 = CapturaDoGuia._(
    'serasa',
    11,
    FormatoDaCaptura.jpg,
  );

  /// Captura 12 do Serasa.
  static const CapturaDoGuia serasa12 = CapturaDoGuia._(
    'serasa',
    12,
    FormatoDaCaptura.jpg,
  );

  /// Captura 13 do Serasa.
  static const CapturaDoGuia serasa13 = CapturaDoGuia._(
    'serasa',
    13,
    FormatoDaCaptura.jpg,
  );

  /// Captura 14 do Serasa.
  static const CapturaDoGuia serasa14 = CapturaDoGuia._(
    'serasa',
    14,
    FormatoDaCaptura.jpg,
  );

  /// Captura 15 do Serasa.
  static const CapturaDoGuia serasa15 = CapturaDoGuia._(
    'serasa',
    15,
    FormatoDaCaptura.jpg,
  );

  /// Captura 16 do Serasa.
  static const CapturaDoGuia serasa16 = CapturaDoGuia._(
    'serasa',
    16,
    FormatoDaCaptura.jpg,
  );

  /// Captura 17 do Serasa.
  static const CapturaDoGuia serasa17 = CapturaDoGuia._(
    'serasa',
    17,
    FormatoDaCaptura.jpg,
  );

  /// Captura 18 do Serasa.
  static const CapturaDoGuia serasa18 = CapturaDoGuia._(
    'serasa',
    18,
    FormatoDaCaptura.jpg,
  );

  /// Captura 19 do Serasa.
  static const CapturaDoGuia serasa19 = CapturaDoGuia._(
    'serasa',
    19,
    FormatoDaCaptura.jpg,
  );

  /// Captura 20 do Serasa.
  static const CapturaDoGuia serasa20 = CapturaDoGuia._(
    'serasa',
    20,
    FormatoDaCaptura.jpg,
  );

  /// Captura 21 do Serasa.
  static const CapturaDoGuia serasa21 = CapturaDoGuia._(
    'serasa',
    21,
    FormatoDaCaptura.jpg,
  );

  /// Captura 22 do Serasa.
  static const CapturaDoGuia serasa22 = CapturaDoGuia._(
    'serasa',
    22,
    FormatoDaCaptura.jpg,
  );

  // FGTS (T081)
  /// Captura 1 do FGTS.
  static const CapturaDoGuia fgts1 = CapturaDoGuia._('fgts', 1);

  /// Captura 2 do FGTS (com campo de senha oficial Caixa vazio).
  static const CapturaDoGuia fgts2 = CapturaDoGuia._('fgts', 2);

  /// Captura 3 do FGTS.
  static const CapturaDoGuia fgts3 = CapturaDoGuia._('fgts', 3);

  /// Captura 4 do FGTS.
  static const CapturaDoGuia fgts4 = CapturaDoGuia._('fgts', 4);

  /// Captura 5 do FGTS.
  static const CapturaDoGuia fgts5 = CapturaDoGuia._('fgts', 5);

  /// Captura 6 do FGTS.
  static const CapturaDoGuia fgts6 = CapturaDoGuia._('fgts', 6);

  /// Captura 7 do FGTS.
  static const CapturaDoGuia fgts7 = CapturaDoGuia._('fgts', 7);

  /// Captura 8 do FGTS.
  static const CapturaDoGuia fgts8 = CapturaDoGuia._('fgts', 8);

  /// Captura 9 do FGTS.
  static const CapturaDoGuia fgts9 = CapturaDoGuia._('fgts', 9);

  /// Captura 10 do FGTS.
  static const CapturaDoGuia fgts10 = CapturaDoGuia._('fgts', 10);

  /// Captura 11 do FGTS.
  static const CapturaDoGuia fgts11 = CapturaDoGuia._('fgts', 11);

  /// Captura 12 do FGTS.
  static const CapturaDoGuia fgts12 = CapturaDoGuia._('fgts', 12);

  // Poupatempo (T081 + Feature 016 Seções)
  /// Captura 1 do Poupatempo.
  static const CapturaDoGuia poupatempo1 = CapturaDoGuia._('poupatempo', 1);

  /// Captura 2 do Poupatempo.
  static const CapturaDoGuia poupatempo2 = CapturaDoGuia._('poupatempo', 2);

  /// Captura 3 do Poupatempo (com campo de senha oficial vazio).
  static const CapturaDoGuia poupatempo3 = CapturaDoGuia._('poupatempo', 3);

  /// Captura 4 do Poupatempo.
  static const CapturaDoGuia poupatempo4 = CapturaDoGuia._('poupatempo', 4);

  /// Captura 5 do Poupatempo.
  static const CapturaDoGuia poupatempo5 = CapturaDoGuia._('poupatempo', 5);

  /// Captura 6 do Poupatempo.
  static const CapturaDoGuia poupatempo6 = CapturaDoGuia._('poupatempo', 6);

  /// Captura 7 do Poupatempo.
  static const CapturaDoGuia poupatempo7 = CapturaDoGuia._('poupatempo', 7);

  /// Captura 8 do Poupatempo.
  static const CapturaDoGuia poupatempo8 = CapturaDoGuia._('poupatempo', 8);

  /// Captura 9 do Poupatempo.
  static const CapturaDoGuia poupatempo9 = CapturaDoGuia._('poupatempo', 9);

  /// Captura 10 do Poupatempo.
  static const CapturaDoGuia poupatempo10 = CapturaDoGuia._('poupatempo', 10);

  // Carteira Digital (T082 + Feature 016 Seções)
  /// Captura 1 da Carteira Digital.
  static const CapturaDoGuia carteiraDigital1 = CapturaDoGuia._(
    'carteira-digital',
    1,
  );

  /// Captura 2 da Carteira Digital.
  static const CapturaDoGuia carteiraDigital2 = CapturaDoGuia._(
    'carteira-digital',
    2,
  );

  /// Captura 3 da Carteira Digital.
  static const CapturaDoGuia carteiraDigital3 = CapturaDoGuia._(
    'carteira-digital',
    3,
  );

  /// Captura 4 da Carteira Digital.
  static const CapturaDoGuia carteiraDigital4 = CapturaDoGuia._(
    'carteira-digital',
    4,
  );

  /// Captura 5 da Carteira Digital.
  static const CapturaDoGuia carteiraDigital5 = CapturaDoGuia._(
    'carteira-digital',
    5,
  );

  /// Captura 6 da Carteira Digital.
  static const CapturaDoGuia carteiraDigital6 = CapturaDoGuia._(
    'carteira-digital',
    6,
  );

  /// Captura 7 da Carteira Digital.
  static const CapturaDoGuia carteiraDigital7 = CapturaDoGuia._(
    'carteira-digital',
    7,
  );

  /// Captura 8 da Carteira Digital.
  static const CapturaDoGuia carteiraDigital8 = CapturaDoGuia._(
    'carteira-digital',
    8,
  );

  /// Captura 9 da Carteira Digital.
  static const CapturaDoGuia carteiraDigital9 = CapturaDoGuia._(
    'carteira-digital',
    9,
  );

  /// Captura 10 da Carteira Digital.
  static const CapturaDoGuia carteiraDigital10 = CapturaDoGuia._(
    'carteira-digital',
    10,
  );

  // Correios (T082 + Feature 006 Seções)
  /// Captura 1 dos Correios.
  static const CapturaDoGuia correios1 = CapturaDoGuia._(
    'correios',
    1,
    FormatoDaCaptura.jpg,
  );

  /// Captura 2 dos Correios.
  static const CapturaDoGuia correios2 = CapturaDoGuia._(
    'correios',
    2,
    FormatoDaCaptura.jpg,
  );

  /// Captura 3 dos Correios.
  static const CapturaDoGuia correios3 = CapturaDoGuia._(
    'correios',
    3,
    FormatoDaCaptura.jpg,
  );

  /// Captura 4 dos Correios.
  static const CapturaDoGuia correios4 = CapturaDoGuia._(
    'correios',
    4,
    FormatoDaCaptura.jpg,
  );

  /// Captura 5 dos Correios.
  static const CapturaDoGuia correios5 = CapturaDoGuia._(
    'correios',
    5,
    FormatoDaCaptura.jpg,
  );

  /// Captura 6 dos Correios.
  static const CapturaDoGuia correios6 = CapturaDoGuia._(
    'correios',
    6,
    FormatoDaCaptura.jpg,
  );

  /// Captura 7 dos Correios.
  static const CapturaDoGuia correios7 = CapturaDoGuia._(
    'correios',
    7,
    FormatoDaCaptura.jpg,
  );

  /// Captura 8 dos Correios (com campo de senha oficial vazio).
  static const CapturaDoGuia correios8 = CapturaDoGuia._(
    'correios',
    8,
    FormatoDaCaptura.jpg,
  );

  // Carteira de Trabalho Digital (T082 + Feature 016 Seções)
  /// Captura 1 da Carteira de Trabalho Digital.
  static const CapturaDoGuia carteiraDeTrabalho1 = CapturaDoGuia._(
    'carteira-de-trabalho',
    1,
  );

  /// Captura 2 da Carteira de Trabalho Digital.
  static const CapturaDoGuia carteiraDeTrabalho2 = CapturaDoGuia._(
    'carteira-de-trabalho',
    2,
  );

  /// Captura 3 da Carteira de Trabalho Digital.
  static const CapturaDoGuia carteiraDeTrabalho3 = CapturaDoGuia._(
    'carteira-de-trabalho',
    3,
  );

  /// Captura 4 da Carteira de Trabalho Digital.
  static const CapturaDoGuia carteiraDeTrabalho4 = CapturaDoGuia._(
    'carteira-de-trabalho',
    4,
  );

  /// Captura 5 da Carteira de Trabalho Digital.
  static const CapturaDoGuia carteiraDeTrabalho5 = CapturaDoGuia._(
    'carteira-de-trabalho',
    5,
  );

  /// Captura 6 da Carteira de Trabalho Digital.
  static const CapturaDoGuia carteiraDeTrabalho6 = CapturaDoGuia._(
    'carteira-de-trabalho',
    6,
  );

  /// Captura 7 da Carteira de Trabalho Digital.
  static const CapturaDoGuia carteiraDeTrabalho7 = CapturaDoGuia._(
    'carteira-de-trabalho',
    7,
  );

  /// Captura 8 da Carteira de Trabalho Digital.
  static const CapturaDoGuia carteiraDeTrabalho8 = CapturaDoGuia._(
    'carteira-de-trabalho',
    8,
  );

  /// Captura 9 da Carteira de Trabalho Digital.
  static const CapturaDoGuia carteiraDeTrabalho9 = CapturaDoGuia._(
    'carteira-de-trabalho',
    9,
  );

  /// Captura 10 da Carteira de Trabalho Digital.
  static const CapturaDoGuia carteiraDeTrabalho10 = CapturaDoGuia._(
    'carteira-de-trabalho',
    10,
  );

  // As capturas entram aqui, uma `static const` por imagem, junto com o guia
  // que as usa. Exemplo, quando existir o primeiro:
  //
  //   static const CapturaDoGuia tiktok1 = CapturaDoGuia._('tiktok', 1);

  @override
  bool operator ==(Object other) =>
      other is CapturaDoGuia &&
      other.chave == chave &&
      other.numero == numero &&
      other.formato == formato;

  @override
  int get hashCode => Object.hash(chave, numero, formato);

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

/// Uma seção temática dentro de um guia extenso (FR-028d, T137).
///
/// Um guia de serviço grande (Gov.br, Serasa, Correios...) não cabe em 3 a 7
/// passos seguidos: a pessoa escolhe o assunto e percorre só a seção. Modelo
/// vindo da PR #67 (Eduardo).
@immutable
class SecaoDoGuia {
  /// Chave única da seção dentro do guia (ex.: `'entrar-conta'`). Compõe a
  /// chave do progresso: `<guia>:<seção>`.
  final String chave;

  /// Título curto e literal exibido no cartão de escolha.
  final String titulo;

  /// Uma linha explicando o que a pessoa vai aprender nesta seção.
  final String subtitulo;

  /// Ícone que acompanha o título (nunca isolado — Constituição III).
  final IconData icone;

  /// Itens específicos para ter em mãos antes desta seção.
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

  /// Os passos, em ordem (usados quando [secoes] está vazio).
  final List<Passo> passos;

  /// Seções temáticas, para o guia extenso (FR-028d). Quando existem, os
  /// [passos] ficam vazios e cada seção traz os seus.
  final List<SecaoDoGuia> secoes;

  /// Quando as capturas foram feitas (R6): diz à revisão quando refazer.
  final DateTime capturadoEm;

  /// A versão do aplicativo do outro lado, como aparece na loja.
  final String versaoCapturada;

  /// O guia tem seções para escolher antes do passo a passo?
  bool get temSecoes => secoes.isNotEmpty;

  /// Todos os passos do guia: os diretos, ou os de todas as seções em ordem.
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

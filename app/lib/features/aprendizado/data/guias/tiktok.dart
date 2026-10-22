import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de passo a passo do TikTok (T070).
final Guia guiaTiktok = Guia(
  chave: 'tiktok',
  titulo: TextosGuias.tituloTiktok,
  capturadoEm: DateTime(2026, 10),
  versaoCapturada: '36.5.0',
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.tiktok1,
      destaque: RegiaoRelativa(x: 0.85, y: 0.5, largura: 0.12, altura: 0.3),
      texto: TextosGuias.tiktokPasso1,
      descricaoDaCaptura: TextosGuias.tiktokCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.tiktok2,
      destaque: RegiaoRelativa(x: 0.2, y: 0.3, largura: 0.6, altura: 0.4),
      texto: TextosGuias.tiktokPasso2,
      descricaoDaCaptura: TextosGuias.tiktokCaptura2,
    ),
    Passo(
      captura: CapturaDoGuia.tiktok3,
      destaque: RegiaoRelativa(x: 0.85, y: 0.05, largura: 0.1, altura: 0.06),
      texto: TextosGuias.tiktokPasso3,
      descricaoDaCaptura: TextosGuias.tiktokCaptura3,
    ),
    Passo(
      captura: CapturaDoGuia.tiktok4,
      destaque: RegiaoRelativa(x: 0.05, y: 0.15, largura: 0.9, altura: 0.7),
      texto: TextosGuias.tiktokPasso4,
      descricaoDaCaptura: TextosGuias.tiktokCaptura4,
    ),
  ],
);


import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de passo a passo do Instagram (T071).
final Guia guiaInstagram = Guia(
  chave: 'instagram',
  titulo: TextosGuias.tituloInstagram,
  capturadoEm: DateTime(2026, 10),
  versaoCapturada: '350.0.0',
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.instagram1,
      destaque: RegiaoRelativa(x: 0.05, y: 0.92, largura: 0.15, altura: 0.06),
      texto: TextosGuias.instagramPasso1,
      descricaoDaCaptura: TextosGuias.instagramCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.instagram2,
      destaque: RegiaoRelativa(x: 0.1, y: 0.3, largura: 0.8, altura: 0.4),
      texto: TextosGuias.instagramPasso2,
      descricaoDaCaptura: TextosGuias.instagramCaptura2,
    ),
    Passo(
      captura: CapturaDoGuia.instagram3,
      destaque: RegiaoRelativa(x: 0.05, y: 0.65, largura: 0.12, altura: 0.06),
      texto: TextosGuias.instagramPasso3,
      descricaoDaCaptura: TextosGuias.instagramCaptura3,
    ),
    Passo(
      captura: CapturaDoGuia.instagram4,
      destaque: RegiaoRelativa(x: 0.45, y: 0.92, largura: 0.15, altura: 0.06),
      texto: TextosGuias.instagramPasso4,
      descricaoDaCaptura: TextosGuias.instagramCaptura4,
    ),
  ],
);


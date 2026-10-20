import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de passo a passo do Facebook (T072).
final Guia guiaFacebook = Guia(
  chave: 'facebook',
  titulo: TextosGuias.tituloFacebook,
  capturadoEm: DateTime(2026, 10),
  versaoCapturada: '480.0.0',
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.facebook1,
      destaque: RegiaoRelativa(x: 0.05, y: 0.05, largura: 0.15, altura: 0.06),
      texto: TextosGuias.facebookPasso1,
      descricaoDaCaptura: TextosGuias.facebookCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.facebook2,
      destaque: RegiaoRelativa(x: 0.1, y: 0.3, largura: 0.8, altura: 0.4),
      texto: TextosGuias.facebookPasso2,
      descricaoDaCaptura: TextosGuias.facebookCaptura2,
    ),
    Passo(
      captura: CapturaDoGuia.facebook3,
      destaque: RegiaoRelativa(x: 0.05, y: 0.7, largura: 0.25, altura: 0.06),
      texto: TextosGuias.facebookPasso3,
      descricaoDaCaptura: TextosGuias.facebookCaptura3,
    ),
    Passo(
      captura: CapturaDoGuia.facebook4,
      destaque: RegiaoRelativa(x: 0.8, y: 0.05, largura: 0.15, altura: 0.06),
      texto: TextosGuias.facebookPasso4,
      descricaoDaCaptura: TextosGuias.facebookCaptura4,
    ),
  ],
);


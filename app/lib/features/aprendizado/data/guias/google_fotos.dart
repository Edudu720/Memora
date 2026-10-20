import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de passo a passo do Google Fotos (T072).
final Guia guiaGoogleFotos = Guia(
  chave: 'google-fotos',
  titulo: TextosGuias.tituloGoogleFotos,
  capturadoEm: DateTime(2026, 10),
  versaoCapturada: '6.95.0',
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.googleFotos1,
      destaque: RegiaoRelativa(x: 0.05, y: 0.92, largura: 0.2, altura: 0.06),
      texto: TextosGuias.googleFotosPasso1,
      descricaoDaCaptura: TextosGuias.googleFotosCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.googleFotos2,
      destaque: RegiaoRelativa(x: 0.05, y: 0.2, largura: 0.9, altura: 0.5),
      texto: TextosGuias.googleFotosPasso2,
      descricaoDaCaptura: TextosGuias.googleFotosCaptura2,
    ),
    Passo(
      captura: CapturaDoGuia.googleFotos3,
      destaque: RegiaoRelativa(x: 0.05, y: 0.2, largura: 0.4, altura: 0.25),
      texto: TextosGuias.googleFotosPasso3,
      descricaoDaCaptura: TextosGuias.googleFotosCaptura3,
    ),
    Passo(
      captura: CapturaDoGuia.googleFotos4,
      destaque: RegiaoRelativa(x: 0.05, y: 0.05, largura: 0.15, altura: 0.06),
      texto: TextosGuias.googleFotosPasso4,
      descricaoDaCaptura: TextosGuias.googleFotosCaptura4,
    ),
  ],
);


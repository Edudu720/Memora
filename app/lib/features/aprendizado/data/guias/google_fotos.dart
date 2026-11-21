import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de passo a passo do Google Fotos (T072 + Feature 016).
final Guia guiaGoogleFotos = Guia(
  chave: 'google-fotos',
  titulo: TextosGuias.tituloGoogleFotos,
  capturadoEm: DateTime(2026, 11, 19),
  versaoCapturada: '6.95.0',
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.googleFotos1,
      // Aba Fotos na barra inferior.
      destaque: RegiaoRelativa(x: 0.17, y: 0.91, largura: 0.18, altura: 0.06),
      texto: TextosGuias.googleFotosPasso1,
      descricaoDaCaptura: TextosGuias.googleFotosCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.googleFotos2,
      // Aba Álbuns na barra inferior.
      destaque: RegiaoRelativa(x: 0.35, y: 0.91, largura: 0.18, altura: 0.06),
      texto: TextosGuias.googleFotosPasso2,
      descricaoDaCaptura: TextosGuias.googleFotosCaptura2,
    ),
    Passo(
      captura: CapturaDoGuia.googleFotos3,
      // Aba Criar na barra inferior.
      destaque: RegiaoRelativa(x: 0.49, y: 0.91, largura: 0.19, altura: 0.06),
      texto: TextosGuias.googleFotosPasso3,
      descricaoDaCaptura: TextosGuias.googleFotosCaptura3,
    ),
    Passo(
      captura: CapturaDoGuia.googleFotos4,
      // Item Backup concluído no painel da conta.
      destaque: RegiaoRelativa(x: 0.04, y: 0.51, largura: 0.92, altura: 0.085),
      texto: TextosGuias.googleFotosPasso4,
      descricaoDaCaptura: TextosGuias.googleFotosCaptura4,
    ),
  ],
);


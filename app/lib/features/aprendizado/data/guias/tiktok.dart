import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de passo a passo do TikTok (T070 + Feature 016).
final Guia guiaTiktok = Guia(
  chave: 'tiktok',
  titulo: TextosGuias.tituloTiktok,
  capturadoEm: DateTime(2026, 11, 19),
  versaoCapturada: '36.5.0',
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.tiktok1,
      // Coluna de botões de interação à direita.
      destaque: RegiaoRelativa(x: 0.85, y: 0.58, largura: 0.13, altura: 0.28),
      texto: TextosGuias.tiktokPasso1,
      descricaoDaCaptura: TextosGuias.tiktokCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.tiktok2,
      // Aba Amigos na barra inferior.
      destaque: RegiaoRelativa(x: 0.21, y: 0.935, largura: 0.17, altura: 0.06),
      texto: TextosGuias.tiktokPasso2,
      descricaoDaCaptura: TextosGuias.tiktokCaptura2,
    ),
    Passo(
      captura: CapturaDoGuia.tiktok3,
      // Botão redondo central da câmera.
      destaque: RegiaoRelativa(x: 0.39, y: 0.79, largura: 0.22, altura: 0.115),
      texto: TextosGuias.tiktokPasso3,
      descricaoDaCaptura: TextosGuias.tiktokCaptura3,
    ),
    Passo(
      captura: CapturaDoGuia.tiktok4,
      // Aba Loja na barra superior.
      destaque: RegiaoRelativa(x: 0.60, y: 0.025, largura: 0.13, altura: 0.05),
      texto: TextosGuias.tiktokPasso4,
      descricaoDaCaptura: TextosGuias.tiktokCaptura4,
    ),
    Passo(
      captura: CapturaDoGuia.tiktok5,
      // Aba Mensagens na barra inferior.
      destaque: RegiaoRelativa(x: 0.61, y: 0.935, largura: 0.19, altura: 0.06),
      texto: TextosGuias.tiktokPasso5,
      descricaoDaCaptura: TextosGuias.tiktokCaptura5,
    ),
    Passo(
      captura: CapturaDoGuia.tiktok6,
      // Aba Perfil no canto inferior direito.
      destaque: RegiaoRelativa(x: 0.82, y: 0.935, largura: 0.16, altura: 0.06),
      texto: TextosGuias.tiktokPasso6,
      descricaoDaCaptura: TextosGuias.tiktokCaptura6,
    ),
  ],
);


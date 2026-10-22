import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de aprendizado do e-Título (T081, US5).
final Guia guiaETitulo = Guia(
  chave: 'e-titulo',
  titulo: TextosGuias.tituloETitulo,
  versaoCapturada: '2.5.0',
  capturadoEm: DateTime(2026, 10),
  precisaTerEmMaos: const <String>[
    'Número do seu CPF ou Título de Eleitor',
    'Sua senha cadastrada no aplicativo e-Título',
  ],
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.eTitulo1,
      destaque: RegiaoRelativa(x: 0.15, y: 0.45, largura: 0.70, altura: 0.12),
      texto: TextosGuias.eTituloPasso1,
      descricaoDaCaptura: TextosGuias.eTituloCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.eTitulo2,
      destaque: RegiaoRelativa(x: 0.10, y: 0.35, largura: 0.80, altura: 0.10),
      texto: TextosGuias.eTituloPasso2,
      descricaoDaCaptura: TextosGuias.eTituloCaptura2,
    ),
    Passo(
      captura: CapturaDoGuia.eTitulo3,
      destaque: RegiaoRelativa(x: 0.10, y: 0.40, largura: 0.80, altura: 0.10),
      texto: TextosGuias.eTituloPasso3,
      descricaoDaCaptura: TextosGuias.eTituloCaptura3,
      temCampoDeSenha: true,
    ),
    Passo(
      captura: CapturaDoGuia.eTitulo4,
      destaque: RegiaoRelativa(x: 0.05, y: 0.15, largura: 0.90, altura: 0.65),
      texto: TextosGuias.eTituloPasso4,
      descricaoDaCaptura: TextosGuias.eTituloCaptura4,
    ),
  ],
);

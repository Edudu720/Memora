import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de aprendizado da Carteira Digital do gov.br (T080, T082, US5).
final Guia guiaCarteiraDigital = Guia(
  chave: 'carteira-digital',
  titulo: TextosGuias.tituloCarteiraDigital,
  versaoCapturada: '3.1.2',
  capturadoEm: DateTime(2026, 10),
  precisaTerEmMaos: const <String>[
    'Número do seu CPF',
    'Sua senha oficial da conta gov.br',
  ],
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.carteiraDigital1,
      destaque: RegiaoRelativa(x: 0.15, y: 0.70, largura: 0.70, altura: 0.10),
      texto: TextosGuias.carteiraDigitalPasso1,
      descricaoDaCaptura: TextosGuias.carteiraDigitalCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.carteiraDigital2,
      destaque: RegiaoRelativa(x: 0.10, y: 0.35, largura: 0.80, altura: 0.16),
      texto: TextosGuias.carteiraDigitalPasso2,
      descricaoDaCaptura: TextosGuias.carteiraDigitalCaptura2,
      temCampoDeSenha: true,
    ),
    Passo(
      captura: CapturaDoGuia.carteiraDigital3,
      destaque: RegiaoRelativa(x: 0.35, y: 0.88, largura: 0.30, altura: 0.08),
      texto: TextosGuias.carteiraDigitalPasso3,
      descricaoDaCaptura: TextosGuias.carteiraDigitalCaptura3,
    ),
    Passo(
      captura: CapturaDoGuia.carteiraDigital4,
      destaque: RegiaoRelativa(x: 0.08, y: 0.15, largura: 0.84, altura: 0.65),
      texto: TextosGuias.carteiraDigitalPasso4,
      descricaoDaCaptura: TextosGuias.carteiraDigitalCaptura4,
    ),
  ],
);

import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de passo a passo do Gov.br (T078, US5).
final Guia guiaGovBr = Guia(
  chave: 'gov-br',
  titulo: TextosGuias.tituloGovBr,
  capturadoEm: DateTime(2026, 10),
  versaoCapturada: '3.5.0',
  precisaTerEmMaos: const <String>[
    'Seu número de CPF',
    'Sua senha cadastrada',
  ],
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.govBr1,
      destaque: RegiaoRelativa(x: 0.1, y: 0.7, largura: 0.8, altura: 0.08),
      texto: TextosGuias.govBrPasso1,
      descricaoDaCaptura: TextosGuias.govBrCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.govBr2,
      destaque: RegiaoRelativa(x: 0.1, y: 0.45, largura: 0.8, altura: 0.08),
      texto: TextosGuias.govBrPasso2,
      descricaoDaCaptura: TextosGuias.govBrCaptura2,
    ),
    Passo(
      captura: CapturaDoGuia.govBr3,
      destaque: RegiaoRelativa(x: 0.1, y: 0.6, largura: 0.8, altura: 0.08),
      texto: TextosGuias.govBrPasso3,
      descricaoDaCaptura: TextosGuias.govBrCaptura3,
    ),
    Passo(
      captura: CapturaDoGuia.govBr4,
      destaque: RegiaoRelativa(x: 0.1, y: 0.45, largura: 0.8, altura: 0.08),
      texto: TextosGuias.govBrPasso4,
      descricaoDaCaptura: TextosGuias.govBrCaptura4,
      temCampoDeSenha: true,
    ),
    Passo(
      captura: CapturaDoGuia.govBr5,
      destaque: RegiaoRelativa(x: 0.1, y: 0.6, largura: 0.8, altura: 0.08),
      texto: TextosGuias.govBrPasso5,
      descricaoDaCaptura: TextosGuias.govBrCaptura5,
    ),
  ],
);

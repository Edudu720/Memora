import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de aprendizado do Serasa (T081, US5).
final Guia guiaSerasa = Guia(
  chave: 'serasa',
  titulo: TextosGuias.tituloSerasa,
  versaoCapturada: '10.12.0',
  capturadoEm: DateTime(2026, 10),
  precisaTerEmMaos: const <String>[
    'Número do seu CPF',
    'Sua senha cadastrada no Serasa',
  ],
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.serasa1,
      destaque: RegiaoRelativa(x: 0.15, y: 0.82, largura: 0.70, altura: 0.10),
      texto: TextosGuias.serasaPasso1,
      descricaoDaCaptura: TextosGuias.serasaCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.serasa2,
      destaque: RegiaoRelativa(x: 0.10, y: 0.35, largura: 0.80, altura: 0.18),
      texto: TextosGuias.serasaPasso2,
      descricaoDaCaptura: TextosGuias.serasaCaptura2,
      temCampoDeSenha: true,
    ),
    Passo(
      captura: CapturaDoGuia.serasa3,
      destaque: RegiaoRelativa(x: 0.20, y: 0.88, largura: 0.25, altura: 0.08),
      texto: TextosGuias.serasaPasso3,
      descricaoDaCaptura: TextosGuias.serasaCaptura3,
    ),
    Passo(
      captura: CapturaDoGuia.serasa4,
      destaque: RegiaoRelativa(x: 0.10, y: 0.20, largura: 0.80, altura: 0.40),
      texto: TextosGuias.serasaPasso4,
      descricaoDaCaptura: TextosGuias.serasaCaptura4,
    ),
  ],
);

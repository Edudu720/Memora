import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de passo a passo do Meu INSS (T079, US5).
final Guia guiaMeuInss = Guia(
  chave: 'meu-inss',
  titulo: TextosGuias.tituloMeuInss,
  capturadoEm: DateTime(2026, 10),
  versaoCapturada: '4.18.0',
  precisaTerEmMaos: const <String>[
    'Seu número de CPF',
    'Sua senha do Gov.br',
  ],
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.meuInss1,
      destaque: RegiaoRelativa(x: 0.1, y: 0.75, largura: 0.8, altura: 0.08),
      texto: TextosGuias.meuInssPasso1,
      descricaoDaCaptura: TextosGuias.meuInssCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.meuInss2,
      destaque: RegiaoRelativa(x: 0.1, y: 0.45, largura: 0.8, altura: 0.08),
      texto: TextosGuias.meuInssPasso2,
      descricaoDaCaptura: TextosGuias.meuInssCaptura2,
      temCampoDeSenha: true,
    ),
    Passo(
      captura: CapturaDoGuia.meuInss3,
      destaque: RegiaoRelativa(x: 0.05, y: 0.25, largura: 0.9, altura: 0.12),
      texto: TextosGuias.meuInssPasso3,
      descricaoDaCaptura: TextosGuias.meuInssCaptura3,
    ),
    Passo(
      captura: CapturaDoGuia.meuInss4,
      destaque: RegiaoRelativa(x: 0.05, y: 0.2, largura: 0.9, altura: 0.25),
      texto: TextosGuias.meuInssPasso4,
      descricaoDaCaptura: TextosGuias.meuInssCaptura4,
    ),
  ],
);

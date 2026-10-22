import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de aprendizado da Carteira de Trabalho Digital (T082, US5).
final Guia guiaCarteiraDeTrabalho = Guia(
  chave: 'carteira-de-trabalho',
  titulo: TextosGuias.tituloCarteiraDeTrabalho,
  versaoCapturada: '5.8.0',
  capturadoEm: DateTime(2026, 10),
  precisaTerEmMaos: const <String>[
    'Número do seu CPF',
    'Sua senha oficial da conta gov.br',
  ],
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.carteiraDeTrabalho1,
      destaque: RegiaoRelativa(x: 0.15, y: 0.50, largura: 0.70, altura: 0.12),
      texto: TextosGuias.carteiraDeTrabalhoPasso1,
      descricaoDaCaptura: TextosGuias.carteiraDeTrabalhoCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.carteiraDeTrabalho2,
      destaque: RegiaoRelativa(x: 0.10, y: 0.35, largura: 0.80, altura: 0.16),
      texto: TextosGuias.carteiraDeTrabalhoPasso2,
      descricaoDaCaptura: TextosGuias.carteiraDeTrabalhoCaptura2,
      temCampoDeSenha: true,
    ),
    Passo(
      captura: CapturaDoGuia.carteiraDeTrabalho3,
      destaque: RegiaoRelativa(x: 0.25, y: 0.88, largura: 0.25, altura: 0.08),
      texto: TextosGuias.carteiraDeTrabalhoPasso3,
      descricaoDaCaptura: TextosGuias.carteiraDeTrabalhoCaptura3,
    ),
    Passo(
      captura: CapturaDoGuia.carteiraDeTrabalho4,
      destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.60),
      texto: TextosGuias.carteiraDeTrabalhoPasso4,
      descricaoDaCaptura: TextosGuias.carteiraDeTrabalhoCaptura4,
    ),
  ],
);

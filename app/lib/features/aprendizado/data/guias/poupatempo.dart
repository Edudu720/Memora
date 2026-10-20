import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de aprendizado do Poupatempo (T081, US5).
final Guia guiaPoupatempo = Guia(
  chave: 'poupatempo',
  titulo: TextosGuias.tituloPoupatempo,
  versaoCapturada: '5.2.0',
  capturadoEm: DateTime(2026, 10),
  precisaTerEmMaos: const <String>[
    'Número do seu CPF',
    'Sua senha da conta gov.br ou do portal Poupatempo',
  ],
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.poupatempo1,
      destaque: RegiaoRelativa(x: 0.10, y: 0.18, largura: 0.80, altura: 0.10),
      texto: TextosGuias.poupatempoPasso1,
      descricaoDaCaptura: TextosGuias.poupatempoCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.poupatempo2,
      destaque: RegiaoRelativa(x: 0.10, y: 0.35, largura: 0.80, altura: 0.16),
      texto: TextosGuias.poupatempoPasso2,
      descricaoDaCaptura: TextosGuias.poupatempoCaptura2,
      temCampoDeSenha: true,
    ),
    Passo(
      captura: CapturaDoGuia.poupatempo3,
      destaque: RegiaoRelativa(x: 0.05, y: 0.25, largura: 0.90, altura: 0.40),
      texto: TextosGuias.poupatempoPasso3,
      descricaoDaCaptura: TextosGuias.poupatempoCaptura3,
    ),
    Passo(
      captura: CapturaDoGuia.poupatempo4,
      destaque: RegiaoRelativa(x: 0.08, y: 0.30, largura: 0.84, altura: 0.45),
      texto: TextosGuias.poupatempoPasso4,
      descricaoDaCaptura: TextosGuias.poupatempoCaptura4,
    ),
  ],
);

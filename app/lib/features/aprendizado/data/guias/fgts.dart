import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de aprendizado do FGTS (T081, US5).
final Guia guiaFgts = Guia(
  chave: 'fgts',
  titulo: TextosGuias.tituloFgts,
  versaoCapturada: '4.8.1',
  capturadoEm: DateTime(2026, 10),
  precisaTerEmMaos: const <String>[
    'Número do seu CPF',
    'Sua senha de 6 dígitos cadastrada na Caixa',
  ],
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.fgts1,
      destaque: RegiaoRelativa(x: 0.15, y: 0.50, largura: 0.70, altura: 0.10),
      texto: TextosGuias.fgtsPasso1,
      descricaoDaCaptura: TextosGuias.fgtsCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.fgts2,
      destaque: RegiaoRelativa(x: 0.10, y: 0.40, largura: 0.80, altura: 0.10),
      texto: TextosGuias.fgtsPasso2,
      descricaoDaCaptura: TextosGuias.fgtsCaptura2,
    ),
    Passo(
      captura: CapturaDoGuia.fgts3,
      destaque: RegiaoRelativa(x: 0.10, y: 0.40, largura: 0.80, altura: 0.12),
      texto: TextosGuias.fgtsPasso3,
      descricaoDaCaptura: TextosGuias.fgtsCaptura3,
      temCampoDeSenha: true,
    ),
    Passo(
      captura: CapturaDoGuia.fgts4,
      destaque: RegiaoRelativa(x: 0.08, y: 0.18, largura: 0.84, altura: 0.50),
      texto: TextosGuias.fgtsPasso4,
      descricaoDaCaptura: TextosGuias.fgtsCaptura4,
    ),
  ],
);

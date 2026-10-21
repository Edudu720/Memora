import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de passo a passo do Telegram (T072).
final Guia guiaTelegram = Guia(
  chave: 'telegram',
  titulo: TextosGuias.tituloTelegram,
  capturadoEm: DateTime(2026, 10),
  versaoCapturada: '11.1.0',
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.telegram1,
      destaque: RegiaoRelativa(x: 0.8, y: 0.85, largura: 0.16, altura: 0.08),
      texto: TextosGuias.telegramPasso1,
      descricaoDaCaptura: TextosGuias.telegramCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.telegram2,
      destaque: RegiaoRelativa(x: 0.05, y: 0.12, largura: 0.9, altura: 0.1),
      texto: TextosGuias.telegramPasso2,
      descricaoDaCaptura: TextosGuias.telegramCaptura2,
    ),
    Passo(
      captura: CapturaDoGuia.telegram3,
      destaque: RegiaoRelativa(x: 0.05, y: 0.9, largura: 0.75, altura: 0.08),
      texto: TextosGuias.telegramPasso3,
      descricaoDaCaptura: TextosGuias.telegramCaptura3,
    ),
    Passo(
      captura: CapturaDoGuia.telegram4,
      destaque: RegiaoRelativa(x: 0.82, y: 0.9, largura: 0.15, altura: 0.08),
      texto: TextosGuias.telegramPasso4,
      descricaoDaCaptura: TextosGuias.telegramCaptura4,
    ),
  ],
);


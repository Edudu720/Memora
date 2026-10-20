import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de passo a passo do WhatsApp (T071).
final Guia guiaWhatsapp = Guia(
  chave: 'whatsapp',
  titulo: TextosGuias.tituloWhatsapp,
  capturadoEm: DateTime(2026, 10),
  versaoCapturada: '2.24.19',
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.whatsapp1,
      destaque: RegiaoRelativa(x: 0.78, y: 0.85, largura: 0.18, altura: 0.1),
      texto: TextosGuias.whatsappPasso1,
      descricaoDaCaptura: TextosGuias.whatsappCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.whatsapp2,
      destaque: RegiaoRelativa(x: 0.05, y: 0.12, largura: 0.9, altura: 0.1),
      texto: TextosGuias.whatsappPasso2,
      descricaoDaCaptura: TextosGuias.whatsappCaptura2,
    ),
    Passo(
      captura: CapturaDoGuia.whatsapp3,
      destaque: RegiaoRelativa(x: 0.05, y: 0.9, largura: 0.75, altura: 0.08),
      texto: TextosGuias.whatsappPasso3,
      descricaoDaCaptura: TextosGuias.whatsappCaptura3,
    ),
    Passo(
      captura: CapturaDoGuia.whatsapp4,
      destaque: RegiaoRelativa(x: 0.82, y: 0.9, largura: 0.15, altura: 0.08),
      texto: TextosGuias.whatsappPasso4,
      descricaoDaCaptura: TextosGuias.whatsappCaptura4,
    ),
  ],
);


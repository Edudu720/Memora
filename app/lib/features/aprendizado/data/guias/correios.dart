import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de aprendizado dos Correios (T082, US5).
final Guia guiaCorreios = Guia(
  chave: 'correios',
  titulo: TextosGuias.tituloCorreios,
  versaoCapturada: '4.1.0',
  capturadoEm: DateTime(2026, 10),
  precisaTerEmMaos: const <String>[
    'Código de rastreamento do objeto (13 caracteres)',
    'Login e senha do idCorreios (opcional, para receber notificações)',
  ],
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.correios1,
      destaque: RegiaoRelativa(x: 0.10, y: 0.12, largura: 0.80, altura: 0.08),
      texto: TextosGuias.correiosPasso1,
      descricaoDaCaptura: TextosGuias.correiosCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.correios2,
      destaque: RegiaoRelativa(x: 0.10, y: 0.20, largura: 0.80, altura: 0.10),
      texto: TextosGuias.correiosPasso2,
      descricaoDaCaptura: TextosGuias.correiosCaptura2,
    ),
    Passo(
      captura: CapturaDoGuia.correios3,
      destaque: RegiaoRelativa(x: 0.10, y: 0.35, largura: 0.80, altura: 0.18),
      texto: TextosGuias.correiosPasso3,
      descricaoDaCaptura: TextosGuias.correiosCaptura3,
      temCampoDeSenha: true,
    ),
    Passo(
      captura: CapturaDoGuia.correios4,
      destaque: RegiaoRelativa(x: 0.08, y: 0.25, largura: 0.84, altura: 0.50),
      texto: TextosGuias.correiosPasso4,
      descricaoDaCaptura: TextosGuias.correiosCaptura4,
    ),
  ],
);

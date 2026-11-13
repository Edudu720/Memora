import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de aprendizado do e-Título (T081, US5; refeito na T135).
///
/// Entrar com a biometria e um passeio pelas abas: cada passo mostra uma tela
/// e destaca o que leva à próxima. As capturas são reais, com dados de exemplo
/// (FR-028), e os destaques foram medidos sobre elas. A entrada é pela
/// digital, sem campo de senha na tela — por isso nenhum passo tem o aviso da
/// FR-032.
final Guia guiaETitulo = Guia(
  chave: 'e-titulo',
  titulo: TextosGuias.tituloETitulo,
  // Escrita na própria tela de entrada da captura 1.
  versaoCapturada: '2026.10.27',
  capturadoEm: DateTime(2026, 11),
  precisaTerEmMaos: const <String>[
    'Número do seu CPF ou Título de Eleitor',
    'Sua senha cadastrada no aplicativo e-Título',
  ],
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.eTitulo1,
      // O botão laranja "Entrar com biometria", embaixo.
      destaque: RegiaoRelativa(x: 0.03, y: 0.94, largura: 0.94, altura: 0.05),
      texto: TextosGuias.eTituloPasso1,
      descricaoDaCaptura: TextosGuias.eTituloCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.eTitulo2,
      // A aba "Onde votar", embaixo.
      destaque: RegiaoRelativa(x: 0.26, y: 0.925, largura: 0.22, altura: 0.065),
      texto: TextosGuias.eTituloPasso2,
      descricaoDaCaptura: TextosGuias.eTituloCaptura2,
    ),
    Passo(
      captura: CapturaDoGuia.eTitulo3,
      // A aba "ChatVote", embaixo, no meio.
      destaque: RegiaoRelativa(x: 0.42, y: 0.935, largura: 0.16, altura: 0.06),
      texto: TextosGuias.eTituloPasso3,
      descricaoDaCaptura: TextosGuias.eTituloCaptura3,
    ),
    Passo(
      captura: CapturaDoGuia.eTitulo4,
      // A aba "Notificações", embaixo.
      destaque: RegiaoRelativa(x: 0.61, y: 0.935, largura: 0.17, altura: 0.06),
      texto: TextosGuias.eTituloPasso4,
      descricaoDaCaptura: TextosGuias.eTituloCaptura4,
    ),
    Passo(
      captura: CapturaDoGuia.eTitulo5,
      // A aba "Mais opções", embaixo, à direita.
      destaque: RegiaoRelativa(x: 0.80, y: 0.935, largura: 0.19, altura: 0.06),
      texto: TextosGuias.eTituloPasso5,
      descricaoDaCaptura: TextosGuias.eTituloCaptura5,
    ),
    Passo(
      captura: CapturaDoGuia.eTitulo6,
      // "Consultar Situação Eleitoral".
      destaque: RegiaoRelativa(x: 0.03, y: 0.43, largura: 0.94, altura: 0.085),
      texto: TextosGuias.eTituloPasso6,
      descricaoDaCaptura: TextosGuias.eTituloCaptura6,
    ),
  ],
);

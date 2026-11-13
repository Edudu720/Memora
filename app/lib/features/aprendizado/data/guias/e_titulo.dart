import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de aprendizado do e-Título (T081, US5; refeito na T135).
///
/// Um passeio pelas abas do aplicativo **depois de entrar**: cada passo mostra
/// uma tela e destaca a aba que leva à próxima. As capturas são reais, com os
/// dados de exemplo (FR-028). Os destaques foram medidos sobre elas.
final Guia guiaETitulo = Guia(
  chave: 'e-titulo',
  titulo: TextosGuias.tituloETitulo,
  versaoCapturada: 'a confirmar',
  capturadoEm: DateTime(2026, 11),
  precisaTerEmMaos: const <String>[
    'Número do seu CPF ou Título de Eleitor',
    'Sua senha cadastrada no aplicativo e-Título',
  ],
  passos: const <Passo>[
    Passo(
      captura: CapturaDoGuia.eTitulo1,
      // A aba "Onde votar", embaixo.
      destaque: RegiaoRelativa(x: 0.26, y: 0.925, largura: 0.22, altura: 0.065),
      texto: TextosGuias.eTituloPasso1,
      descricaoDaCaptura: TextosGuias.eTituloCaptura1,
    ),
    Passo(
      captura: CapturaDoGuia.eTitulo2,
      // A aba "ChatVote", embaixo, no meio.
      destaque: RegiaoRelativa(x: 0.42, y: 0.935, largura: 0.16, altura: 0.06),
      texto: TextosGuias.eTituloPasso2,
      descricaoDaCaptura: TextosGuias.eTituloCaptura2,
    ),
    Passo(
      captura: CapturaDoGuia.eTitulo3,
      // A aba "Notificações", embaixo.
      destaque: RegiaoRelativa(x: 0.61, y: 0.935, largura: 0.17, altura: 0.06),
      texto: TextosGuias.eTituloPasso3,
      descricaoDaCaptura: TextosGuias.eTituloCaptura3,
    ),
    Passo(
      captura: CapturaDoGuia.eTitulo4,
      // A aba "Mais opções", embaixo, à direita.
      destaque: RegiaoRelativa(x: 0.81, y: 0.935, largura: 0.18, altura: 0.06),
      texto: TextosGuias.eTituloPasso4,
      descricaoDaCaptura: TextosGuias.eTituloCaptura4,
    ),
    Passo(
      captura: CapturaDoGuia.eTitulo5,
      // "Consultar Situação Eleitoral".
      destaque: RegiaoRelativa(x: 0.03, y: 0.43, largura: 0.94, altura: 0.085),
      texto: TextosGuias.eTituloPasso5,
      descricaoDaCaptura: TextosGuias.eTituloCaptura5,
    ),
  ],
);

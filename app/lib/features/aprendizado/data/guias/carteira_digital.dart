import 'package:flutter/material.dart' show Icons;

import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de aprendizado da Carteira Digital de Trânsito (T080, T082 + Feature 016).
///
/// Dez capturas reais organizadas em 2 seções (6 + 4 passos).
final Guia guiaCarteiraDigital = Guia(
  chave: 'carteira-digital',
  titulo: TextosGuias.tituloCarteiraDigital,
  versaoCapturada: '3.1.2',
  capturadoEm: DateTime(2026, 11, 19),
  precisaTerEmMaos: const <String>[
    'Número do seu CPF',
    'Sua senha oficial da conta gov.br',
  ],
  secoes: const <SecaoDoGuia>[
    SecaoDoGuia(
      chave: 'habilitacao-e-credencial',
      titulo: TextosGuias.carteiraDigitalSecaoCnh,
      subtitulo: TextosGuias.carteiraDigitalSecaoCnhSubtitulo,
      icone: Icons.badge_rounded,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.carteiraDigital1,
          // Cartão "CONDUTOR" no alto da tela inicial.
          destaque: RegiaoRelativa(x: 0.03, y: 0.09, largura: 0.94, altura: 0.14),
          texto: TextosGuias.carteiraDigitalCnh1,
          descricaoDaCaptura: TextosGuias.carteiraDigitalCaptura1,
        ),
        Passo(
          captura: CapturaDoGuia.carteiraDigital2,
          // Menu lateral aberto com opções da conta.
          destaque: RegiaoRelativa(x: 0.03, y: 0.175, largura: 0.62, altura: 0.55),
          texto: TextosGuias.carteiraDigitalCnh2,
          descricaoDaCaptura: TextosGuias.carteiraDigitalCaptura2,
        ),
        Passo(
          captura: CapturaDoGuia.carteiraDigital3,
          // Quadrinho "CNH" na tela do condutor.
          destaque: RegiaoRelativa(x: 0.05, y: 0.485, largura: 0.43, altura: 0.145),
          texto: TextosGuias.carteiraDigitalCnh3,
          descricaoDaCaptura: TextosGuias.carteiraDigitalCaptura3,
        ),
        Passo(
          captura: CapturaDoGuia.carteiraDigital4,
          // CNH digital exibida na tela.
          destaque: RegiaoRelativa(x: 0.03, y: 0.11, largura: 0.94, altura: 0.72),
          texto: TextosGuias.carteiraDigitalCnh4,
          descricaoDaCaptura: TextosGuias.carteiraDigitalCaptura4,
        ),
        Passo(
          captura: CapturaDoGuia.carteiraDigital5,
          // Grade de atalhos em "Serviços para CNH".
          destaque: RegiaoRelativa(x: 0.04, y: 0.45, largura: 0.92, altura: 0.36),
          texto: TextosGuias.carteiraDigitalCnh5,
          descricaoDaCaptura: TextosGuias.carteiraDigitalCaptura5,
        ),
        Passo(
          captura: CapturaDoGuia.carteiraDigital6,
          // Opções da credencial de estacionamento.
          destaque: RegiaoRelativa(x: 0.04, y: 0.405, largura: 0.92, altura: 0.39),
          texto: TextosGuias.carteiraDigitalCnh6,
          descricaoDaCaptura: TextosGuias.carteiraDigitalCaptura6,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'veiculos-e-infracoes',
      titulo: TextosGuias.carteiraDigitalSecaoVeiculos,
      subtitulo: TextosGuias.carteiraDigitalSecaoVeiculosSubtitulo,
      icone: Icons.directions_car_rounded,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.carteiraDigital7,
          // Botão "RECARREGAR LISTA DE VEÍCULOS".
          destaque: RegiaoRelativa(x: 0.22, y: 0.565, largura: 0.56, altura: 0.055),
          texto: TextosGuias.carteiraDigitalVeiculos1,
          descricaoDaCaptura: TextosGuias.carteiraDigitalCaptura7,
        ),
        Passo(
          captura: CapturaDoGuia.carteiraDigital8,
          // Opções "Por Infrator" e "Por Veículo".
          destaque: RegiaoRelativa(x: 0.04, y: 0.195, largura: 0.92, altura: 0.22),
          texto: TextosGuias.carteiraDigitalVeiculos2,
          descricaoDaCaptura: TextosGuias.carteiraDigitalCaptura8,
        ),
        Passo(
          captura: CapturaDoGuia.carteiraDigital9,
          // Faixa amarela "Aderir ao SNE".
          destaque: RegiaoRelativa(x: 0.02, y: 0.15, largura: 0.96, altura: 0.12),
          texto: TextosGuias.carteiraDigitalVeiculos3,
          descricaoDaCaptura: TextosGuias.carteiraDigitalCaptura9,
        ),
        Passo(
          captura: CapturaDoGuia.carteiraDigital10,
          // Bloco "Informações do Cadastro Positivo".
          destaque: RegiaoRelativa(x: 0.04, y: 0.11, largura: 0.92, altura: 0.34),
          texto: TextosGuias.carteiraDigitalVeiculos4,
          descricaoDaCaptura: TextosGuias.carteiraDigitalCaptura10,
        ),
      ],
    ),
  ],
);

import 'package:flutter/material.dart' show Icons;

import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de aprendizado da Carteira de Trabalho Digital (T082 + Feature 016).
///
/// Dez capturas reais organizadas em 2 seções (6 + 4 passos).
final Guia guiaCarteiraDeTrabalho = Guia(
  chave: 'carteira-de-trabalho',
  titulo: TextosGuias.tituloCarteiraDeTrabalho,
  versaoCapturada: '8.11.0',
  capturadoEm: DateTime(2026, 11, 19),
  precisaTerEmMaos: const <String>[
    'Número do seu CPF',
    'Sua senha oficial da conta gov.br',
  ],
  secoes: const <SecaoDoGuia>[
    SecaoDoGuia(
      chave: 'entrar-e-contratos',
      titulo: TextosGuias.carteiraDeTrabalhoSecaoContratos,
      subtitulo: TextosGuias.carteiraDeTrabalhoSecaoContratosSubtitulo,
      icone: Icons.work_outline_rounded,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.carteiraDeTrabalho1,
          // Botão azul "Entrar com gov.br".
          destaque: RegiaoRelativa(x: 0.05, y: 0.57, largura: 0.90, altura: 0.06),
          texto: TextosGuias.carteiraDeTrabalhoContratos1,
          descricaoDaCaptura: TextosGuias.carteiraDeTrabalhoCaptura1,
        ),
        Passo(
          captura: CapturaDoGuia.carteiraDeTrabalho2,
          // Botão azul "Autorizar" do gov.br.
          destaque: RegiaoRelativa(x: 0.54, y: 0.895, largura: 0.34, altura: 0.055),
          texto: TextosGuias.carteiraDeTrabalhoContratos2,
          descricaoDaCaptura: TextosGuias.carteiraDeTrabalhoCaptura2,
        ),
        Passo(
          captura: CapturaDoGuia.carteiraDeTrabalho3,
          // Atalho "Contratos de Trabalho Digitais".
          destaque: RegiaoRelativa(x: 0.03, y: 0.45, largura: 0.44, altura: 0.15),
          texto: TextosGuias.carteiraDeTrabalhoContratos3,
          descricaoDaCaptura: TextosGuias.carteiraDeTrabalhoCaptura3,
        ),
        Passo(
          captura: CapturaDoGuia.carteiraDeTrabalho4,
          // Lista de contratos de trabalho.
          destaque: RegiaoRelativa(x: 0.03, y: 0.22, largura: 0.94, altura: 0.32),
          texto: TextosGuias.carteiraDeTrabalhoContratos4,
          descricaoDaCaptura: TextosGuias.carteiraDeTrabalhoCaptura4,
        ),
        Passo(
          captura: CapturaDoGuia.carteiraDeTrabalho5,
          // Botão azul "VOLTAR" em Outros vínculos.
          destaque: RegiaoRelativa(x: 0.04, y: 0.575, largura: 0.92, altura: 0.065),
          texto: TextosGuias.carteiraDeTrabalhoContratos5,
          descricaoDaCaptura: TextosGuias.carteiraDeTrabalhoCaptura5,
        ),
        Passo(
          captura: CapturaDoGuia.carteiraDeTrabalho6,
          // Botão azul "GERAR PDF" na base da tela.
          destaque: RegiaoRelativa(x: 0.04, y: 0.925, largura: 0.92, altura: 0.06),
          texto: TextosGuias.carteiraDeTrabalhoContratos6,
          descricaoDaCaptura: TextosGuias.carteiraDeTrabalhoCaptura6,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'beneficios-e-menu',
      titulo: TextosGuias.carteiraDeTrabalhoSecaoBeneficios,
      subtitulo: TextosGuias.carteiraDeTrabalhoSecaoBeneficiosSubtitulo,
      icone: Icons.account_balance_wallet_rounded,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.carteiraDeTrabalho7,
          // Aba "Benefícios" na barra inferior.
          destaque: RegiaoRelativa(x: 0.21, y: 0.94, largura: 0.20, altura: 0.055),
          texto: TextosGuias.carteiraDeTrabalhoBeneficios1,
          descricaoDaCaptura: TextosGuias.carteiraDeTrabalhoCaptura7,
        ),
        Passo(
          captura: CapturaDoGuia.carteiraDeTrabalho8,
          // Botão "ATUALIZAR INFORMAÇÕES PESSOAIS".
          destaque: RegiaoRelativa(x: 0.05, y: 0.70, largura: 0.90, altura: 0.06),
          texto: TextosGuias.carteiraDeTrabalhoBeneficios2,
          descricaoDaCaptura: TextosGuias.carteiraDeTrabalhoCaptura8,
        ),
        Passo(
          captura: CapturaDoGuia.carteiraDeTrabalho9,
          // Aba "Empréstimos" na barra inferior.
          destaque: RegiaoRelativa(x: 0.62, y: 0.935, largura: 0.19, altura: 0.06),
          texto: TextosGuias.carteiraDeTrabalhoBeneficios3,
          descricaoDaCaptura: TextosGuias.carteiraDeTrabalhoCaptura9,
        ),
        Passo(
          captura: CapturaDoGuia.carteiraDeTrabalho10,
          // Opção "Sair" no menu inferior.
          destaque: RegiaoRelativa(x: 0.03, y: 0.56, largura: 0.94, altura: 0.075),
          texto: TextosGuias.carteiraDeTrabalhoBeneficios4,
          descricaoDaCaptura: TextosGuias.carteiraDeTrabalhoCaptura10,
        ),
      ],
    ),
  ],
);

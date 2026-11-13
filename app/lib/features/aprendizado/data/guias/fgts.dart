import 'package:flutter/material.dart' show Icons;

import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de aprendizado do FGTS (T081, US5; refeito na T138).
///
/// Treze telas não cabem num guia de 7 passos, então ele se divide em quatro
/// seções (FR-028d), e a pessoa escolhe o assunto antes de começar. As
/// capturas são reais, do Galaxy S20 FE, com o saldo escondido pelo próprio
/// aplicativo e nenhum dado de conta (FR-028); os destaques foram medidos
/// sobre elas. A página principal (captura 6) aparece em três seções, cada
/// vez destacando uma aba diferente.
///
/// Nenhuma captura mostra campo de senha: a da Caixa vem depois do CPF, e o
/// passo 2 de "Entrar" avisa que ela só se digita no aplicativo oficial.
final Guia guiaFgts = Guia(
  chave: 'fgts',
  titulo: TextosGuias.tituloFgts,
  versaoCapturada: '5.11.0',
  capturadoEm: DateTime(2026, 11),
  precisaTerEmMaos: const <String>[
    'Número do seu CPF',
    'Sua senha da Caixa',
  ],
  secoes: const <SecaoDoGuia>[
    SecaoDoGuia(
      chave: 'entrar',
      titulo: TextosGuias.fgtsSecaoEntrar,
      subtitulo: TextosGuias.fgtsSecaoEntrarSubtitulo,
      icone: Icons.login,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.fgts1,
          // O botão laranja "Entrar no aplicativo".
          destaque: RegiaoRelativa(x: 0.05, y: 0.67, largura: 0.90, altura: 0.065),
          texto: TextosGuias.fgtsEntrar1,
          descricaoDaCaptura: TextosGuias.fgtsCaptura1,
        ),
        Passo(
          captura: CapturaDoGuia.fgts2,
          // O campo CPF e o botão "Próximo".
          destaque: RegiaoRelativa(x: 0.05, y: 0.295, largura: 0.90, altura: 0.13),
          texto: TextosGuias.fgtsEntrar2,
          descricaoDaCaptura: TextosGuias.fgtsCaptura2,
        ),
        Passo(
          captura: CapturaDoGuia.fgts3,
          // "Li e aceito os termos e condições" e "Continuar".
          destaque: RegiaoRelativa(x: 0.04, y: 0.81, largura: 0.92, altura: 0.185),
          texto: TextosGuias.fgtsEntrar3,
          descricaoDaCaptura: TextosGuias.fgtsCaptura3,
        ),
        Passo(
          captura: CapturaDoGuia.fgts4,
          // O botão "Pular".
          destaque: RegiaoRelativa(x: 0.05, y: 0.89, largura: 0.90, altura: 0.06),
          texto: TextosGuias.fgtsEntrar4,
          descricaoDaCaptura: TextosGuias.fgtsCaptura4,
        ),
        Passo(
          captura: CapturaDoGuia.fgts5,
          // "Ativar notificações" e "Agora não".
          destaque: RegiaoRelativa(x: 0.05, y: 0.795, largura: 0.90, altura: 0.15),
          texto: TextosGuias.fgtsEntrar5,
          descricaoDaCaptura: TextosGuias.fgtsCaptura5,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'saldo-e-saque',
      titulo: TextosGuias.fgtsSecaoSaque,
      subtitulo: TextosGuias.fgtsSecaoSaqueSubtitulo,
      icone: Icons.savings_outlined,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.fgts6,
          // "Toque para exibir o saldo", no alto.
          destaque: RegiaoRelativa(x: 0.04, y: 0.115, largura: 0.58, altura: 0.045),
          texto: TextosGuias.fgtsSaque1,
          descricaoDaCaptura: TextosGuias.fgtsCaptura6,
        ),
        Passo(
          captura: CapturaDoGuia.fgts6,
          // A aba "Saques", embaixo.
          destaque: RegiaoRelativa(x: 0.26, y: 0.945, largura: 0.22, altura: 0.05),
          texto: TextosGuias.fgtsSaque2,
          descricaoDaCaptura: TextosGuias.fgtsCaptura6,
        ),
        Passo(
          captura: CapturaDoGuia.fgts7,
          // "Solicitar saque".
          destaque: RegiaoRelativa(x: 0.04, y: 0.235, largura: 0.93, altura: 0.125),
          texto: TextosGuias.fgtsSaque3,
          descricaoDaCaptura: TextosGuias.fgtsCaptura7,
        ),
        Passo(
          captura: CapturaDoGuia.fgts8,
          // A lista de motivos.
          destaque: RegiaoRelativa(x: 0.03, y: 0.22, largura: 0.94, altura: 0.55),
          texto: TextosGuias.fgtsSaque4,
          descricaoDaCaptura: TextosGuias.fgtsCaptura8,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'conta-bancaria',
      titulo: TextosGuias.fgtsSecaoConta,
      subtitulo: TextosGuias.fgtsSecaoContaSubtitulo,
      icone: Icons.account_balance_outlined,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.fgts6,
          // A aba "Meus dados", embaixo.
          destaque: RegiaoRelativa(x: 0.51, y: 0.945, largura: 0.22, altura: 0.05),
          texto: TextosGuias.fgtsConta1,
          descricaoDaCaptura: TextosGuias.fgtsCaptura6,
        ),
        Passo(
          captura: CapturaDoGuia.fgts9,
          // "Conta bancária".
          destaque: RegiaoRelativa(x: 0.04, y: 0.285, largura: 0.94, altura: 0.11),
          texto: TextosGuias.fgtsConta2,
          descricaoDaCaptura: TextosGuias.fgtsCaptura9,
        ),
        Passo(
          captura: CapturaDoGuia.fgts10,
          // "Alterar conta bancária".
          destaque: RegiaoRelativa(x: 0.10, y: 0.60, largura: 0.79, altura: 0.065),
          texto: TextosGuias.fgtsConta3,
          descricaoDaCaptura: TextosGuias.fgtsCaptura10,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'saque-aniversario',
      titulo: TextosGuias.fgtsSecaoAniversario,
      subtitulo: TextosGuias.fgtsSecaoAniversarioSubtitulo,
      icone: Icons.cake_outlined,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.fgts6,
          // A aba "Mais", embaixo, à direita.
          destaque: RegiaoRelativa(x: 0.78, y: 0.945, largura: 0.20, altura: 0.05),
          texto: TextosGuias.fgtsAniversario1,
          descricaoDaCaptura: TextosGuias.fgtsCaptura6,
        ),
        Passo(
          captura: CapturaDoGuia.fgts11,
          // "Sistemática de saque".
          destaque: RegiaoRelativa(x: 0.03, y: 0.215, largura: 0.95, altura: 0.115),
          texto: TextosGuias.fgtsAniversario2,
          descricaoDaCaptura: TextosGuias.fgtsCaptura11,
        ),
        Passo(
          captura: CapturaDoGuia.fgts12,
          // O quadro "O que muda se eu fizer a opção?".
          destaque: RegiaoRelativa(x: 0.08, y: 0.645, largura: 0.84, altura: 0.305),
          texto: TextosGuias.fgtsAniversario3,
          descricaoDaCaptura: TextosGuias.fgtsCaptura12,
        ),
      ],
    ),
  ],
);

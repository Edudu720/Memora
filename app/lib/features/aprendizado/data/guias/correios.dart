import 'package:flutter/material.dart';

import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de aprendizado dos Correios organizado em seções (006-guias-servicos-sociais).
final Guia guiaCorreios = Guia(
  chave: 'correios',
  titulo: TextosGuias.tituloCorreios,6
  versaoCapturada: '2026.11',
  capturadoEm: DateTime(2026, 11),
  precisaTerEmMaos: const <String>[
    'Código de rastreamento do objeto (13 caracteres)',
    'Login e senha do Meu Correios (opcional, para receber notificações)',
  ],
  secoes: const <SecaoDoGuia>[
    SecaoDoGuia(
      chave: 'rastrear-encomenda',
      titulo: TextosGuias.correiosSecao1Titulo,
      subtitulo: TextosGuias.correiosSecao1Subtitulo,
      icone: Icons.local_shipping_outlined,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.correios1,
          destaque: RegiaoRelativa(x: 0.08, y: 0.18, largura: 0.84, altura: 0.45),
          texto: TextosGuias.correiosPasso1,
          descricaoDaCaptura: TextosGuias.correiosCaptura1,
        ),
        Passo(
          captura: CapturaDoGuia.correios2,
          destaque: RegiaoRelativa(x: 0.10, y: 0.20, largura: 0.80, altura: 0.14),
          texto: TextosGuias.correiosPasso2,
          descricaoDaCaptura: TextosGuias.correiosCaptura2,
        ),
        Passo(
          captura: CapturaDoGuia.correios3,
          destaque: RegiaoRelativa(x: 0.10, y: 0.25, largura: 0.80, altura: 0.35),
          texto: TextosGuias.correiosPasso3,
          descricaoDaCaptura: TextosGuias.correiosCaptura3,
        ),
        Passo(
          captura: CapturaDoGuia.correios4,
          destaque: RegiaoRelativa(x: 0.08, y: 0.22, largura: 0.84, altura: 0.55),
          texto: TextosGuias.correiosPasso4,
          descricaoDaCaptura: TextosGuias.correiosCaptura4,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'frete-meu-correios',
      titulo: TextosGuias.correiosSecao2Titulo,
      subtitulo: TextosGuias.correiosSecao2Subtitulo,
      icone: Icons.calculate_outlined,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.correios5,
          destaque: RegiaoRelativa(x: 0.08, y: 0.15, largura: 0.84, altura: 0.30),
          texto: TextosGuias.correiosPasso5,
          descricaoDaCaptura: TextosGuias.correiosCaptura5,
        ),
        Passo(
          captura: CapturaDoGuia.correios6,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.50),
          texto: TextosGuias.correiosPasso6,
          descricaoDaCaptura: TextosGuias.correiosCaptura6,
        ),
        Passo(
          captura: CapturaDoGuia.correios7,
          destaque: RegiaoRelativa(x: 0.08, y: 0.18, largura: 0.84, altura: 0.50),
          texto: TextosGuias.correiosPasso7,
          descricaoDaCaptura: TextosGuias.correiosCaptura7,
        ),
        Passo(
          captura: CapturaDoGuia.correios8,
          destaque: RegiaoRelativa(x: 0.10, y: 0.30, largura: 0.80, altura: 0.25),
          texto: TextosGuias.correiosPasso8,
          descricaoDaCaptura: TextosGuias.correiosCaptura8,
          temCampoDeSenha: true,
        ),
      ],
    ),
  ],
);

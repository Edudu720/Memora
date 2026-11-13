import 'package:flutter/material.dart';

import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de aprendizado do Serasa organizado em seções (006-guias-servicos-sociais).
final Guia guiaSerasa = Guia(
  chave: 'serasa',
  titulo: TextosGuias.tituloSerasa,
  versaoCapturada: '2026.11',
  capturadoEm: DateTime(2026, 11),
  precisaTerEmMaos: const <String>[
    'Número do seu CPF',
    'Sua senha cadastrada no Serasa',
  ],
  secoes: const <SecaoDoGuia>[
    SecaoDoGuia(
      chave: 'inicio-menu',
      titulo: TextosGuias.serasaSecao1Titulo,
      subtitulo: TextosGuias.serasaSecao1Subtitulo,
      icone: Icons.home_outlined,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.serasa1,
          destaque: RegiaoRelativa(x: 0.12, y: 0.35, largura: 0.76, altura: 0.18),
          texto: TextosGuias.serasaPasso1,
          descricaoDaCaptura: TextosGuias.serasaCaptura1,
        ),
        Passo(
          captura: CapturaDoGuia.serasa2,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.50),
          texto: TextosGuias.serasaPasso2,
          descricaoDaCaptura: TextosGuias.serasaCaptura2,
        ),
        Passo(
          captura: CapturaDoGuia.serasa3,
          destaque: RegiaoRelativa(x: 0.08, y: 0.18, largura: 0.84, altura: 0.60),
          texto: TextosGuias.serasaPasso3,
          descricaoDaCaptura: TextosGuias.serasaCaptura3,
        ),
        Passo(
          captura: CapturaDoGuia.serasa4,
          destaque: RegiaoRelativa(x: 0.08, y: 0.18, largura: 0.84, altura: 0.55),
          texto: TextosGuias.serasaPasso4,
          descricaoDaCaptura: TextosGuias.serasaCaptura4,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'serasa-score',
      titulo: TextosGuias.serasaSecao2Titulo,
      subtitulo: TextosGuias.serasaSecao2Subtitulo,
      icone: Icons.speed,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.serasa5,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.45),
          texto: TextosGuias.serasaPasso5,
          descricaoDaCaptura: TextosGuias.serasaCaptura5,
        ),
        Passo(
          captura: CapturaDoGuia.serasa6,
          destaque: RegiaoRelativa(x: 0.08, y: 0.18, largura: 0.84, altura: 0.55),
          texto: TextosGuias.serasaPasso6,
          descricaoDaCaptura: TextosGuias.serasaCaptura6,
        ),
        Passo(
          captura: CapturaDoGuia.serasa7,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.55),
          texto: TextosGuias.serasaPasso7,
          descricaoDaCaptura: TextosGuias.serasaCaptura7,
        ),
        Passo(
          captura: CapturaDoGuia.serasa8,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.55),
          texto: TextosGuias.serasaPasso8,
          descricaoDaCaptura: TextosGuias.serasaCaptura8,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'dividas-acordos',
      titulo: TextosGuias.serasaSecao3Titulo,
      subtitulo: TextosGuias.serasaSecao3Subtitulo,
      icone: Icons.receipt_long_outlined,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.serasa9,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.45),
          texto: TextosGuias.serasaPasso9,
          descricaoDaCaptura: TextosGuias.serasaCaptura9,
        ),
        Passo(
          captura: CapturaDoGuia.serasa10,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.55),
          texto: TextosGuias.serasaPasso10,
          descricaoDaCaptura: TextosGuias.serasaCaptura10,
        ),
        Passo(
          captura: CapturaDoGuia.serasa11,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.55),
          texto: TextosGuias.serasaPasso11,
          descricaoDaCaptura: TextosGuias.serasaCaptura11,
        ),
        Passo(
          captura: CapturaDoGuia.serasa12,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.55),
          texto: TextosGuias.serasaPasso12,
          descricaoDaCaptura: TextosGuias.serasaCaptura12,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'proteger-cpf',
      titulo: TextosGuias.serasaSecao4Titulo,
      subtitulo: TextosGuias.serasaSecao4Subtitulo,
      icone: Icons.shield_outlined,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.serasa13,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.50),
          texto: TextosGuias.serasaPasso13,
          descricaoDaCaptura: TextosGuias.serasaCaptura13,
        ),
        Passo(
          captura: CapturaDoGuia.serasa14,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.55),
          texto: TextosGuias.serasaPasso14,
          descricaoDaCaptura: TextosGuias.serasaCaptura14,
        ),
        Passo(
          captura: CapturaDoGuia.serasa15,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.55),
          texto: TextosGuias.serasaPasso15,
          descricaoDaCaptura: TextosGuias.serasaCaptura15,
        ),
        Passo(
          captura: CapturaDoGuia.serasa16,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.55),
          texto: TextosGuias.serasaPasso16,
          descricaoDaCaptura: TextosGuias.serasaCaptura16,
        ),
        Passo(
          captura: CapturaDoGuia.serasa17,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.55),
          texto: TextosGuias.serasaPasso17,
          descricaoDaCaptura: TextosGuias.serasaCaptura17,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'outros-servicos',
      titulo: TextosGuias.serasaSecao5Titulo,
      subtitulo: TextosGuias.serasaSecao5Subtitulo,
      icone: Icons.help_outline,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.serasa18,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.55),
          texto: TextosGuias.serasaPasso18,
          descricaoDaCaptura: TextosGuias.serasaCaptura18,
        ),
        Passo(
          captura: CapturaDoGuia.serasa19,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.55),
          texto: TextosGuias.serasaPasso19,
          descricaoDaCaptura: TextosGuias.serasaCaptura19,
        ),
        Passo(
          captura: CapturaDoGuia.serasa20,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.55),
          texto: TextosGuias.serasaPasso20,
          descricaoDaCaptura: TextosGuias.serasaCaptura20,
        ),
        Passo(
          captura: CapturaDoGuia.serasa21,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.55),
          texto: TextosGuias.serasaPasso21,
          descricaoDaCaptura: TextosGuias.serasaCaptura21,
        ),
        Passo(
          captura: CapturaDoGuia.serasa22,
          destaque: RegiaoRelativa(x: 0.08, y: 0.20, largura: 0.84, altura: 0.55),
          texto: TextosGuias.serasaPasso22,
          descricaoDaCaptura: TextosGuias.serasaCaptura22,
        ),
      ],
    ),
  ],
);

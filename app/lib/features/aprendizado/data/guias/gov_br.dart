import 'package:flutter/material.dart';

import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de aprendizado do Gov.br organizado em seções (006-guias-servicos-sociais).
final Guia guiaGovBr = Guia(
  chave: 'gov-br',
  titulo: TextosGuias.tituloGovBr,
  versaoCapturada: '2026.11',
  capturadoEm: DateTime(2026, 11),
  precisaTerEmMaos: const <String>[
    'Número do seu CPF',
    'Sua senha da conta Gov.br',
  ],
  secoes: const <SecaoDoGuia>[
    SecaoDoGuia(
      chave: 'entrar',
      titulo: TextosGuias.govBrSecao1Titulo,
      subtitulo: TextosGuias.govBrSecao1Subtitulo,
      icone: Icons.login,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.govBr1,
          destaque: RegiaoRelativa(
            x: 0.55,
            y: 0.08,
            largura: 0.35,
            altura: 0.08,
          ),
          texto: TextosGuias.govBrPasso1,
          descricaoDaCaptura: TextosGuias.govBrCaptura1,
        ),
        Passo(
          captura: CapturaDoGuia.govBr2,
          destaque: RegiaoRelativa(
            x: 0.10,
            y: 0.35,
            largura: 0.80,
            altura: 0.14,
          ),
          texto: TextosGuias.govBrPasso2,
          descricaoDaCaptura: TextosGuias.govBrCaptura2,
        ),
        Passo(
          captura: CapturaDoGuia.govBr3,
          destaque: RegiaoRelativa(
            x: 0.10,
            y: 0.35,
            largura: 0.80,
            altura: 0.16,
          ),
          texto: TextosGuias.govBrPasso3,
          descricaoDaCaptura: TextosGuias.govBrCaptura3,
          temCampoDeSenha: true,
        ),
        Passo(
          captura: CapturaDoGuia.govBr4,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.15,
            largura: 0.84,
            altura: 0.55,
          ),
          texto: TextosGuias.govBrPasso4,
          descricaoDaCaptura: TextosGuias.govBrCaptura4,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'minha-area',
      titulo: TextosGuias.govBrSecao2Titulo,
      subtitulo: TextosGuias.govBrSecao2Subtitulo,
      icone: Icons.folder_shared_outlined,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.govBr5,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.15,
            largura: 0.84,
            altura: 0.35,
          ),
          texto: TextosGuias.govBrPasso5,
          descricaoDaCaptura: TextosGuias.govBrCaptura5,
        ),
        Passo(
          captura: CapturaDoGuia.govBr6,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.25,
            largura: 0.84,
            altura: 0.45,
          ),
          texto: TextosGuias.govBrPasso6,
          descricaoDaCaptura: TextosGuias.govBrCaptura6,
        ),
        Passo(
          captura: CapturaDoGuia.govBr7,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.20,
            largura: 0.84,
            altura: 0.55,
          ),
          texto: TextosGuias.govBrPasso7,
          descricaoDaCaptura: TextosGuias.govBrCaptura7,
        ),
        Passo(
          captura: CapturaDoGuia.govBr8,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.18,
            largura: 0.84,
            altura: 0.60,
          ),
          texto: TextosGuias.govBrPasso8,
          descricaoDaCaptura: TextosGuias.govBrCaptura8,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'certidoes-agenda',
      titulo: TextosGuias.govBrSecao3Titulo,
      subtitulo: TextosGuias.govBrSecao3Subtitulo,
      icone: Icons.description_outlined,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.govBr9,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.18,
            largura: 0.84,
            altura: 0.55,
          ),
          texto: TextosGuias.govBrPasso9,
          descricaoDaCaptura: TextosGuias.govBrCaptura9,
        ),
        Passo(
          captura: CapturaDoGuia.govBr10,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.20,
            largura: 0.84,
            altura: 0.55,
          ),
          texto: TextosGuias.govBrPasso10,
          descricaoDaCaptura: TextosGuias.govBrCaptura10,
        ),
        Passo(
          captura: CapturaDoGuia.govBr11,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.20,
            largura: 0.84,
            altura: 0.55,
          ),
          texto: TextosGuias.govBrPasso11,
          descricaoDaCaptura: TextosGuias.govBrCaptura11,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'servicos-perfis',
      titulo: TextosGuias.govBrSecao4Titulo,
      subtitulo: TextosGuias.govBrSecao4Subtitulo,
      icone: Icons.search,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.govBr12,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.20,
            largura: 0.84,
            altura: 0.55,
          ),
          texto: TextosGuias.govBrPasso12,
          descricaoDaCaptura: TextosGuias.govBrCaptura12,
        ),
        Passo(
          captura: CapturaDoGuia.govBr13,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.20,
            largura: 0.84,
            altura: 0.55,
          ),
          texto: TextosGuias.govBrPasso13,
          descricaoDaCaptura: TextosGuias.govBrCaptura13,
        ),
        Passo(
          captura: CapturaDoGuia.govBr14,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.20,
            largura: 0.84,
            altura: 0.55,
          ),
          texto: TextosGuias.govBrPasso14,
          descricaoDaCaptura: TextosGuias.govBrCaptura14,
        ),
        Passo(
          captura: CapturaDoGuia.govBr15,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.20,
            largura: 0.84,
            altura: 0.55,
          ),
          texto: TextosGuias.govBrPasso15,
          descricaoDaCaptura: TextosGuias.govBrCaptura15,
        ),
        Passo(
          captura: CapturaDoGuia.govBr16,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.20,
            largura: 0.84,
            altura: 0.55,
          ),
          texto: TextosGuias.govBrPasso16,
          descricaoDaCaptura: TextosGuias.govBrCaptura16,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'aplicativos',
      titulo: TextosGuias.govBrSecao5Titulo,
      subtitulo: TextosGuias.govBrSecao5Subtitulo,
      icone: Icons.apps,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.govBr17,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.20,
            largura: 0.84,
            altura: 0.50,
          ),
          texto: TextosGuias.govBrPasso17,
          descricaoDaCaptura: TextosGuias.govBrCaptura17,
        ),
        Passo(
          captura: CapturaDoGuia.govBr18,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.20,
            largura: 0.84,
            altura: 0.55,
          ),
          texto: TextosGuias.govBrPasso18,
          descricaoDaCaptura: TextosGuias.govBrCaptura18,
        ),
        Passo(
          captura: CapturaDoGuia.govBr19,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.20,
            largura: 0.84,
            altura: 0.55,
          ),
          texto: TextosGuias.govBrPasso19,
          descricaoDaCaptura: TextosGuias.govBrCaptura19,
        ),
        Passo(
          captura: CapturaDoGuia.govBr20,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.20,
            largura: 0.84,
            altura: 0.55,
          ),
          texto: TextosGuias.govBrPasso20,
          descricaoDaCaptura: TextosGuias.govBrCaptura20,
        ),
        Passo(
          captura: CapturaDoGuia.govBr21,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.20,
            largura: 0.84,
            altura: 0.55,
          ),
          texto: TextosGuias.govBrPasso21,
          descricaoDaCaptura: TextosGuias.govBrCaptura21,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'ouvidoria',
      titulo: TextosGuias.govBrSecao6Titulo,
      subtitulo: TextosGuias.govBrSecao6Subtitulo,
      icone: Icons.support_agent,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.govBr22,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.20,
            largura: 0.84,
            altura: 0.55,
          ),
          texto: TextosGuias.govBrPasso22,
          descricaoDaCaptura: TextosGuias.govBrCaptura22,
        ),
        Passo(
          captura: CapturaDoGuia.govBr23,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.20,
            largura: 0.84,
            altura: 0.55,
          ),
          texto: TextosGuias.govBrPasso23,
          descricaoDaCaptura: TextosGuias.govBrCaptura23,
        ),
        Passo(
          captura: CapturaDoGuia.govBr24,
          destaque: RegiaoRelativa(
            x: 0.08,
            y: 0.20,
            largura: 0.84,
            altura: 0.55,
          ),
          texto: TextosGuias.govBrPasso24,
          descricaoDaCaptura: TextosGuias.govBrCaptura24,
        ),
      ],
    ),
  ],
);

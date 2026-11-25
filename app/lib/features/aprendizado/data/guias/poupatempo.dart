import 'package:flutter/material.dart' show Icons;

import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de aprendizado do Poupatempo (T081 + Feature 016).
///
/// Dez capturas reais divididas em 2 seções de 5 passos cada.
final Guia guiaPoupatempo = Guia(
  chave: 'poupatempo',
  titulo: TextosGuias.tituloPoupatempo,
  versaoCapturada: '5.2.0',
  capturadoEm: DateTime(2026, 11, 19),
  precisaTerEmMaos: const <String>[
    'Número do seu CPF',
    'Sua senha da conta gov.br ou do portal Poupatempo',
  ],
  secoes: const <SecaoDoGuia>[
    SecaoDoGuia(
      chave: 'entrar-e-servicos',
      titulo: TextosGuias.poupatempoSecaoEntrar,
      subtitulo: TextosGuias.poupatempoSecaoEntrarSubtitulo,
      icone: Icons.login_rounded,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.poupatempo1,
          // Botão azul "Entrar com o gov.br".
          destaque: RegiaoRelativa(x: 0.07, y: 0.585, largura: 0.86, altura: 0.055),
          texto: TextosGuias.poupatempoEntrar1,
          descricaoDaCaptura: TextosGuias.poupatempoCaptura1,
        ),
        Passo(
          captura: CapturaDoGuia.poupatempo2,
          // Campo CPF e botão "Continuar".
          destaque: RegiaoRelativa(x: 0.13, y: 0.34, largura: 0.74, altura: 0.145),
          texto: TextosGuias.poupatempoEntrar2,
          descricaoDaCaptura: TextosGuias.poupatempoCaptura2,
        ),
        Passo(
          captura: CapturaDoGuia.poupatempo3,
          // Campo "Digite sua senha atual" vazio e botão "Entrar".
          destaque: RegiaoRelativa(x: 0.13, y: 0.32, largura: 0.74, altura: 0.15),
          texto: TextosGuias.poupatempoEntrar3,
          descricaoDaCaptura: TextosGuias.poupatempoCaptura3,
          temCampoDeSenha: true,
        ),
        Passo(
          captura: CapturaDoGuia.poupatempo4,
          // Fileira de cartões "Serviços mais acessados".
          destaque: RegiaoRelativa(x: 0.03, y: 0.62, largura: 0.94, altura: 0.19),
          texto: TextosGuias.poupatempoEntrar4,
          descricaoDaCaptura: TextosGuias.poupatempoCaptura4,
        ),
        Passo(
          captura: CapturaDoGuia.poupatempo5,
          // Grade "Categorias disponíveis".
          destaque: RegiaoRelativa(x: 0.03, y: 0.185, largura: 0.94, altura: 0.49),
          texto: TextosGuias.poupatempoEntrar5,
          descricaoDaCaptura: TextosGuias.poupatempoCaptura5,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'buscar-agendar-e-carteira',
      titulo: TextosGuias.poupatempoSecaoAgenda,
      subtitulo: TextosGuias.poupatempoSecaoAgendaSubtitulo,
      icone: Icons.calendar_month_rounded,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.poupatempo6,
          // Barra "O que você está buscando?".
          destaque: RegiaoRelativa(x: 0.05, y: 0.075, largura: 0.90, altura: 0.055),
          texto: TextosGuias.poupatempoAgenda1,
          descricaoDaCaptura: TextosGuias.poupatempoCaptura6,
        ),
        Passo(
          captura: CapturaDoGuia.poupatempo7,
          // Cartões "Agendar" e "Consultar".
          destaque: RegiaoRelativa(x: 0.05, y: 0.088, largura: 0.90, altura: 0.27),
          texto: TextosGuias.poupatempoAgenda2,
          descricaoDaCaptura: TextosGuias.poupatempoCaptura7,
        ),
        Passo(
          captura: CapturaDoGuia.poupatempo8,
          // Calendário mensal da aba Agenda.
          destaque: RegiaoRelativa(x: 0.04, y: 0.02, largura: 0.92, altura: 0.36),
          texto: TextosGuias.poupatempoAgenda3,
          descricaoDaCaptura: TextosGuias.poupatempoCaptura8,
        ),
        Passo(
          captura: CapturaDoGuia.poupatempo9,
          // Lista "Serviços mais solicitados".
          destaque: RegiaoRelativa(x: 0.03, y: 0.075, largura: 0.94, altura: 0.32),
          texto: TextosGuias.poupatempoAgenda4,
          descricaoDaCaptura: TextosGuias.poupatempoCaptura9,
        ),
        Passo(
          captura: CapturaDoGuia.poupatempo10,
          // Cartão "Documentos" dentro da aba Carteira.
          destaque: RegiaoRelativa(x: 0.04, y: 0.50, largura: 0.92, altura: 0.165),
          texto: TextosGuias.poupatempoAgenda5,
          descricaoDaCaptura: TextosGuias.poupatempoCaptura10,
        ),
      ],
    ),
  ],
);

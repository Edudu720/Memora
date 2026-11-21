import 'package:flutter/material.dart' show Icons;

import '../../../../l10n/textos_guias.dart';
import '../../domain/guia.dart';

/// Guia de aprendizado do Meu INSS (T079 + Feature 016).
///
/// Dezenove capturas reais organizadas em 4 seções temáticas de 3 a 6 passos.
final Guia guiaMeuInss = Guia(
  chave: 'meu-inss',
  titulo: TextosGuias.tituloMeuInss,
  capturadoEm: DateTime(2026, 11, 19),
  versaoCapturada: '4.18.0',
  precisaTerEmMaos: const <String>[
    'Seu número de CPF',
    'Sua senha do Gov.br',
  ],
  secoes: const <SecaoDoGuia>[
    SecaoDoGuia(
      chave: 'entrar',
      titulo: TextosGuias.meuInssSecaoEntrar,
      subtitulo: TextosGuias.meuInssSecaoEntrarSubtitulo,
      icone: Icons.login_rounded,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.meuInss1,
          // Botão "Avançar" na base da tela de boas-vindas.
          destaque: RegiaoRelativa(x: 0.04, y: 0.925, largura: 0.92, altura: 0.06),
          texto: TextosGuias.meuInssEntrar1,
          descricaoDaCaptura: TextosGuias.meuInssCaptura1,
        ),
        Passo(
          captura: CapturaDoGuia.meuInss2,
          // Botão azul "Aceitar" na base da política de privacidade.
          destaque: RegiaoRelativa(x: 0.04, y: 0.925, largura: 0.92, altura: 0.06),
          texto: TextosGuias.meuInssEntrar2,
          descricaoDaCaptura: TextosGuias.meuInssCaptura2,
        ),
        Passo(
          captura: CapturaDoGuia.meuInss3,
          // Botão azul "Entrar com gov.br".
          destaque: RegiaoRelativa(x: 0.10, y: 0.245, largura: 0.80, altura: 0.055),
          texto: TextosGuias.meuInssEntrar3,
          descricaoDaCaptura: TextosGuias.meuInssCaptura3,
        ),
        Passo(
          captura: CapturaDoGuia.meuInss4,
          // Botão azul "Autorizar" na tela de compartilhamento gov.br.
          destaque: RegiaoRelativa(x: 0.54, y: 0.91, largura: 0.33, altura: 0.055),
          texto: TextosGuias.meuInssEntrar4,
          descricaoDaCaptura: TextosGuias.meuInssCaptura4,
        ),
        Passo(
          captura: CapturaDoGuia.meuInss5,
          // Opções "Não" e "Sim" da biometria.
          destaque: RegiaoRelativa(x: 0.04, y: 0.865, largura: 0.92, altura: 0.125),
          texto: TextosGuias.meuInssEntrar5,
          descricaoDaCaptura: TextosGuias.meuInssCaptura5,
        ),
        Passo(
          captura: CapturaDoGuia.meuInss6,
          // Opções "Não" e "Sim" das notificações.
          destaque: RegiaoRelativa(x: 0.04, y: 0.865, largura: 0.92, altura: 0.125),
          texto: TextosGuias.meuInssEntrar6,
          descricaoDaCaptura: TextosGuias.meuInssCaptura6,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'tela-inicial-e-busca',
      titulo: TextosGuias.meuInssSecaoInicio,
      subtitulo: TextosGuias.meuInssSecaoInicioSubtitulo,
      icone: Icons.search_rounded,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.meuInss7,
          // Bloco de cartões "Serviços para você".
          destaque: RegiaoRelativa(x: 0.04, y: 0.22, largura: 0.92, altura: 0.28),
          texto: TextosGuias.meuInssInicio1,
          descricaoDaCaptura: TextosGuias.meuInssCaptura7,
        ),
        Passo(
          captura: CapturaDoGuia.meuInss9,
          // Lista principal do menu lateral.
          destaque: RegiaoRelativa(x: 0.02, y: 0.12, largura: 0.94, altura: 0.42),
          texto: TextosGuias.meuInssInicio2,
          descricaoDaCaptura: TextosGuias.meuInssCaptura9,
        ),
        Passo(
          captura: CapturaDoGuia.meuInss10,
          // Barra de busca "Do que você precisa?".
          destaque: RegiaoRelativa(x: 0.05, y: 0.075, largura: 0.88, altura: 0.055),
          texto: TextosGuias.meuInssInicio3,
          descricaoDaCaptura: TextosGuias.meuInssCaptura10,
        ),
        Passo(
          captura: CapturaDoGuia.meuInss11,
          // Lista de notificações recebidas.
          destaque: RegiaoRelativa(x: 0.05, y: 0.15, largura: 0.90, altura: 0.36),
          texto: TextosGuias.meuInssInicio4,
          descricaoDaCaptura: TextosGuias.meuInssCaptura11,
        ),
        Passo(
          captura: CapturaDoGuia.meuInss12,
          // Opção "Tamanho da Fonte" em Meu Perfil.
          destaque: RegiaoRelativa(x: 0.05, y: 0.405, largura: 0.90, altura: 0.056),
          texto: TextosGuias.meuInssInicio5,
          descricaoDaCaptura: TextosGuias.meuInssCaptura12,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'extratos-e-pedidos',
      titulo: TextosGuias.meuInssSecaoExtratos,
      subtitulo: TextosGuias.meuInssSecaoExtratosSubtitulo,
      icone: Icons.description_rounded,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.meuInss13,
          // Lista Extratos, Comprovantes e Outros Documentos.
          destaque: RegiaoRelativa(x: 0.05, y: 0.23, largura: 0.90, altura: 0.21),
          texto: TextosGuias.meuInssExtratos1,
          descricaoDaCaptura: TextosGuias.meuInssCaptura13,
        ),
        Passo(
          captura: CapturaDoGuia.meuInss14,
          // Botão azul "Baixar Documento" no CNIS.
          destaque: RegiaoRelativa(x: 0.04, y: 0.925, largura: 0.92, altura: 0.06),
          texto: TextosGuias.meuInssExtratos2,
          descricaoDaCaptura: TextosGuias.meuInssCaptura14,
        ),
        Passo(
          captura: CapturaDoGuia.meuInss16,
          // Item "Pedir Novo Benefício por Incapacidade".
          destaque: RegiaoRelativa(x: 0.05, y: 0.235, largura: 0.90, altura: 0.09),
          texto: TextosGuias.meuInssExtratos3,
          descricaoDaCaptura: TextosGuias.meuInssCaptura16,
        ),
        Passo(
          captura: CapturaDoGuia.meuInss15,
          // Botão azul "Avançar" na explicação do benefício.
          destaque: RegiaoRelativa(x: 0.04, y: 0.925, largura: 0.92, altura: 0.06),
          texto: TextosGuias.meuInssExtratos4,
          descricaoDaCaptura: TextosGuias.meuInssCaptura15,
        ),
        Passo(
          captura: CapturaDoGuia.meuInss17,
          // Botão azul "Todos os Serviços" em Novo Pedido.
          destaque: RegiaoRelativa(x: 0.04, y: 0.915, largura: 0.92, altura: 0.065),
          texto: TextosGuias.meuInssExtratos5,
          descricaoDaCaptura: TextosGuias.meuInssCaptura17,
        ),
      ],
    ),
    SecaoDoGuia(
      chave: 'mais-servicos-e-ajuda',
      titulo: TextosGuias.meuInssSecaoAjuda,
      subtitulo: TextosGuias.meuInssSecaoAjudaSubtitulo,
      icone: Icons.support_agent_rounded,
      passos: <Passo>[
        Passo(
          captura: CapturaDoGuia.meuInss18,
          // Cartões de Destaques em Mais Serviços.
          destaque: RegiaoRelativa(x: 0.04, y: 0.175, largura: 0.92, altura: 0.40),
          texto: TextosGuias.meuInssAjuda1,
          descricaoDaCaptura: TextosGuias.meuInssCaptura18,
        ),
        Passo(
          captura: CapturaDoGuia.meuInss8,
          // Botão "Iniciar Atendimento" no chat da Helô.
          destaque: RegiaoRelativa(x: 0.21, y: 0.778, largura: 0.58, altura: 0.055),
          texto: TextosGuias.meuInssAjuda2,
          descricaoDaCaptura: TextosGuias.meuInssCaptura8,
        ),
        Passo(
          captura: CapturaDoGuia.meuInss19,
          // Opção "Ligue INSS (135)" na tela Ajuda.
          destaque: RegiaoRelativa(x: 0.05, y: 0.258, largura: 0.90, altura: 0.058),
          texto: TextosGuias.meuInssAjuda3,
          descricaoDaCaptura: TextosGuias.meuInssCaptura19,
        ),
      ],
    ),
  ],
);


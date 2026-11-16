import 'package:flutter/material.dart';

/// Categorias essenciais de serviços próximas para o idoso (FR-002).
enum CategoriaServico {
  /// Postos de saúde, hospitais, UPAs e farmácias.
  saude('Saúde', 'Postos de saúde, UPAs, hospitais e farmácias', Icons.local_hospital_outlined),

  /// Órgãos e atendimentos ao cidadão.
  servicosPublicos('Serviços públicos', 'Poupatempo, INSS, CRAS e prefeitura', Icons.account_balance_outlined),

  /// Atendimento imediato de urgência e emergência.
  emergencia('Emergência', 'Bombeiros, SAMU, delegacias e pronto-socorro', Icons.warning_amber_rounded),

  /// Serviços básicos do dia a dia.
  cotidiano('Serviços cotidianos', 'Supermercados, bancos, lotéricas e correios', Icons.storefront_outlined);

  /// Rótulo curto exibido nos filtros e cartões.
  final String rotulo;

  /// Exemplos de estabelecimentos pertencentes à categoria.
  final String descricao;

  /// Ícone representativo da categoria.
  final IconData icone;

  const CategoriaServico(this.rotulo, this.descricao, this.icone);

  /// Converte o código recebido da API para o valor do enum, se válido.
  static CategoriaServico? porCodigo(String? codigo) {
    if (codigo == null) return null;
    return switch (codigo.toUpperCase()) {
      'SAUDE' => CategoriaServico.saude,
      'SERVICOS_PUBLICOS' => CategoriaServico.servicosPublicos,
      'EMERGENCIA' => CategoriaServico.emergencia,
      'COTIDIANO' => CategoriaServico.cotidiano,
      _ => null,
    };
  }
}

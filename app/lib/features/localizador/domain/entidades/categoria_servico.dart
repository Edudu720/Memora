import 'package:flutter/material.dart';

/// Categorias essenciais de serviços próximas para o idoso (FR-002).
enum CategoriaServico {
  /// Postos de saúde, hospitais, UPAs e farmácias.
  saude('Saúde', 'Postos de saúde, UPAs, hospitais e farmácias', Icons.local_hospital_rounded),

  /// Órgãos e atendimentos ao cidadão.
  servicosPublicos('Serviços públicos', 'Poupatempo, INSS, CRAS e prefeitura', Icons.account_balance_rounded),

  /// Atendimento imediato de urgência e emergência.
  emergencia('Emergência', 'Bombeiros, SAMU, delegacias e pronto-socorro', Icons.warning_amber_rounded),

  /// Serviços básicos do dia a dia.
  cotidiano('Serviços cotidianos', 'Supermercados, bancos, lotéricas e correios', Icons.storefront_rounded);

  /// Rótulo curto exibido nos filtros e cartões.
  final String rotulo;

  /// Exemplos de estabelecimentos pertencentes à categoria.
  final String descricao;

  /// Ícone representativo da categoria.
  final IconData icone;

  const CategoriaServico(this.rotulo, this.descricao, this.icone);

  /// Código da categoria no contrato da API (`CategoriaServico` do backend).
  ///
  /// Não usar `name.toUpperCase()`: `servicosPublicos` viraria
  /// `SERVICOSPUBLICOS`, que o servidor não reconhece e troca por SAUDE.
  String get codigo => switch (this) {
    CategoriaServico.saude => 'SAUDE',
    CategoriaServico.servicosPublicos => 'SERVICOS_PUBLICOS',
    CategoriaServico.emergencia => 'EMERGENCIA',
    CategoriaServico.cotidiano => 'COTIDIANO',
  };

  /// Converte o código recebido da API para o valor do enum, se válido.
  static CategoriaServico? porCodigo(String? codigo) {
    if (codigo == null) return null;
    final String procurado = codigo.toUpperCase();
    for (final CategoriaServico categoria in CategoriaServico.values) {
      if (categoria.codigo == procurado) return categoria;
    }
    return null;
  }
}

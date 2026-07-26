import 'package:flutter/material.dart';

import '../../tokens/dimensoes.dart';
import '../../tokens/tipografia.dart';
import '../../temas/memora_theme_extension.dart';

/// Escala de texto do sistema, limitada ao teto acordado pelo Memora.
///
/// Todo componente que renderiza texto deve usar esta função. Sem o teto, o
/// Android permite fatores de ampliação que estouram qualquer layout — e a
/// pessoa fica sem saída, porque a própria tela de configuração deixa de ser
/// legível (research.md, R7).
TextScaler escalaTextoLimitada(BuildContext context) {
  return MediaQuery.textScalerOf(context).clamp(
    minScaleFactor: MemoraDimensoes.escalaTextoMin,
    maxScaleFactor: MemoraDimensoes.escalaTextoMax,
  );
}

/// Papel semântico de um texto na interface.
enum EstiloTexto {
  /// Título principal da tela.
  tituloTela,

  /// Título de seção ou agrupamento.
  tituloSecao,

  /// Texto padrão.
  corpo,

  /// Texto padrão com ênfase.
  corpoForte,

  /// Texto auxiliar. Nunca menor que 16 sp.
  apoio,
}

/// Texto do Memora, com escala limitada e cor vinda do tema.
///
/// ## Por que não usar `Text` direto
///
/// Duas garantias que o [Text] cru não dá:
///
/// 1. **Teto de ampliação.** A escala do sistema é limitada a
///    [MemoraDimensoes.escalaTextoMax]. Sem teto, o Android permite fatores
///    que estouram qualquer layout — e a pessoa fica sem saída, porque a
///    própria tela de configuração deixa de ser legível.
/// 2. **Cor sempre do tema.** Cor literal em tela é o começo da erosão que a
///    FR-002 existe para evitar.
///
/// O piso de 16 sp é garantido pelos próprios tokens de
/// [MemoraTipografia] e verificado em teste.
class TextoMemora extends StatelessWidget {
  /// Conteúdo exibido.
  final String texto;

  /// Papel do texto na interface.
  final EstiloTexto estilo;

  /// Cor. Quando omitida, usa a cor de texto do tema ativo.
  final Color? cor;

  /// Alinhamento horizontal.
  final TextAlign? alinhamento;

  /// Número máximo de linhas. `null` permite crescer indefinidamente —
  /// preferível a cortar conteúdo.
  final int? maxLinhas;

  /// Marca o texto como cabeçalho para leitores de tela.
  final bool cabecalho;

  /// Cria um texto do Memora.
  const TextoMemora(
    this.texto, {
    this.estilo = EstiloTexto.corpo,
    this.cor,
    this.alinhamento,
    this.maxLinhas,
    this.cabecalho = false,
    super.key,
  });

  /// Atalho para [EstiloTexto.tituloTela].
  const TextoMemora.tituloTela(
    this.texto, {
    this.cor,
    this.alinhamento,
    this.maxLinhas,
    super.key,
  })  : estilo = EstiloTexto.tituloTela,
        cabecalho = true;

  /// Atalho para [EstiloTexto.tituloSecao].
  const TextoMemora.tituloSecao(
    this.texto, {
    this.cor,
    this.alinhamento,
    this.maxLinhas,
    super.key,
  })  : estilo = EstiloTexto.tituloSecao,
        cabecalho = true;

  /// Atalho para [EstiloTexto.apoio].
  const TextoMemora.apoio(
    this.texto, {
    this.cor,
    this.alinhamento,
    this.maxLinhas,
    super.key,
  })  : estilo = EstiloTexto.apoio,
        cabecalho = false;

  TextStyle get _base => switch (estilo) {
        EstiloTexto.tituloTela => MemoraTipografia.tituloTela,
        EstiloTexto.tituloSecao => MemoraTipografia.tituloSecao,
        EstiloTexto.corpo => MemoraTipografia.corpo,
        EstiloTexto.corpoForte => MemoraTipografia.corpoForte,
        EstiloTexto.apoio => MemoraTipografia.apoio,
      };

  @override
  Widget build(BuildContext context) {
    final cores = context.memora.cores;
    final Color corFinal =
        cor ?? (estilo == EstiloTexto.apoio ? cores.textoSuave : cores.texto);

    final TextScaler escala = escalaTextoLimitada(context);

    return Semantics(
      header: cabecalho,
      child: Text(
        texto,
        style: _base.copyWith(color: corFinal),
        textAlign: alinhamento,
        maxLines: maxLinhas,
        textScaler: escala,
        overflow: maxLinhas == null ? null : TextOverflow.ellipsis,
      ),
    );
  }
}

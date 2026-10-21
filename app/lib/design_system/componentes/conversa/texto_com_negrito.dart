import 'package:flutter/material.dart';

import '../../temas/memora_theme_extension.dart';
import '../../tokens/tipografia.dart';
import '../texto/texto_memora.dart';

/// Um pedaço de texto, em negrito ou não (FR-020a).
@immutable
class TrechoDeTexto {
  /// O que se lê, **sem** as marcas.
  final String texto;

  /// Em negrito?
  final bool negrito;

  /// Cria um trecho.
  const TrechoDeTexto(this.texto, {this.negrito = false});

  @override
  bool operator ==(Object other) =>
      other is TrechoDeTexto && other.texto == texto && other.negrito == negrito;

  @override
  int get hashCode => Object.hash(texto, negrito);

  @override
  String toString() => 'TrechoDeTexto(${negrito ? '**' : ''}$texto)';
}

const String _marca = '**';

/// Separa o que está entre `**` do resto (FR-020a).
///
/// ## O que é e o que não é interpretado
///
/// **Só negrito.** Nenhuma outra formatação — itálico, lista, título, link — é
/// lida: o texto da Memora vem de um serviço de fora, e cada coisa que o
/// aplicativo interpretasse seria uma coisa a mais que esse texto poderia
/// fazer na tela.
///
/// - `**assim**` vira negrito, e os asteriscos somem;
/// - marca **sem par** (`**assim`) fica como texto comum, asteriscos e tudo;
/// - marca vazia (`****`) também fica como texto: não há o que destacar.
///
/// ## [emAndamento]: o texto ainda está chegando
///
/// No meio de uma resposta que está chegando, `**` aberto ainda vai fechar. Se
/// os asteriscos aparecessem até lá, a pessoa os veria piscar na tela. Por
/// isso, com [emAndamento], o `**` sem par vira "negrito até aqui" e um `*`
/// solto no fim — que pode estar virando `**` — é segurado. Quando a resposta
/// termina, vale a regra normal.
List<TrechoDeTexto> analisarNegrito(
  String texto, {
  bool emAndamento = false,
}) {
  final List<TrechoDeTexto> trechos = <TrechoDeTexto>[];
  final StringBuffer comum = StringBuffer();

  void fecharComum() {
    if (comum.isEmpty) return;
    trechos.add(TrechoDeTexto(comum.toString()));
    comum.clear();
  }

  int i = 0;
  while (i < texto.length) {
    final int abre = texto.indexOf(_marca, i);
    if (abre < 0) {
      comum.write(texto.substring(i));
      break;
    }

    comum.write(texto.substring(i, abre));
    final int fecha = texto.indexOf(_marca, abre + _marca.length);

    if (fecha < 0) {
      // Sem par.
      if (emAndamento) {
        fecharComum();
        final String resto = texto.substring(abre + _marca.length);
        if (resto.isNotEmpty) trechos.add(TrechoDeTexto(resto, negrito: true));
      } else {
        comum.write(texto.substring(abre));
      }
      i = texto.length;
      break;
    }

    if (fecha == abre + _marca.length) {
      // `****`: nada a destacar. Fica como veio.
      comum.write(_marca);
      i = abre + _marca.length;
      continue;
    }

    fecharComum();
    trechos.add(
      TrechoDeTexto(
        texto.substring(abre + _marca.length, fecha),
        negrito: true,
      ),
    );
    i = fecha + _marca.length;
  }
  fecharComum();

  if (emAndamento && trechos.isNotEmpty) {
    // Um `*` no fim pode ser o começo de `**`: segura até saber.
    final TrechoDeTexto ultimo = trechos.last;
    if (!ultimo.negrito && ultimo.texto.endsWith('*')) {
      final String sem = ultimo.texto.substring(0, ultimo.texto.length - 1);
      trechos.removeLast();
      if (sem.isNotEmpty) trechos.add(TrechoDeTexto(sem));
    }
  }

  return trechos;
}

/// O texto sem nenhuma marca — o que o leitor de tela recebe (FR-020a).
String textoSemMarcas(String texto, {bool emAndamento = false}) => analisarNegrito(
  texto,
  emAndamento: emAndamento,
).map((TrechoDeTexto t) => t.texto).join();

/// Texto corrido com trechos em negrito (FR-020a).
///
/// Mesmo estilo, escala e cor do [TextoMemora] do corpo: o que muda é só o
/// peso dos trechos entre `**`. Não carrega semântica própria — quem o usa
/// diz ao leitor de tela o texto sem marcas, e exclui este.
///
/// [caracteresVisiveis], quando dado, corta o texto nessa quantidade de
/// letras (do texto **sem marcas**): é como a resposta vai aparecendo aos
/// poucos sem que o corte caia no meio de uma marca (FR-020b).
class TextoComNegrito extends StatelessWidget {
  /// O texto, com as marcas.
  final String texto;

  /// O texto ainda está chegando? Ver [analisarNegrito].
  final bool emAndamento;

  /// Quantas letras mostrar. Nulo: todas.
  final int? caracteresVisiveis;

  /// Cria o texto.
  const TextoComNegrito(
    this.texto, {
    this.emAndamento = false,
    this.caracteresVisiveis,
    super.key,
  });

  /// Quantas letras o [texto] tem, sem as marcas.
  static int quantasLetras(String texto, {bool emAndamento = false}) =>
      textoSemMarcas(texto, emAndamento: emAndamento).characters.length;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = EstiloTexto.corpo.base.copyWith(
      color: context.memora.cores.texto,
    );
    final TextStyle forte = base.copyWith(
      fontWeight: MemoraTipografia.pesoDoNegrito,
    );

    int restantes = caracteresVisiveis ?? 1 << 30;
    final List<InlineSpan> pedacos = <InlineSpan>[];
    for (final TrechoDeTexto trecho in analisarNegrito(
      texto,
      emAndamento: emAndamento,
    )) {
      if (restantes <= 0) break;
      final Characters letras = trecho.texto.characters;
      final String visivel = letras.length <= restantes
          ? trecho.texto
          : letras.take(restantes).toString();
      restantes -= letras.length;
      pedacos.add(
        TextSpan(text: visivel, style: trecho.negrito ? forte : null),
      );
    }

    return Text.rich(
      TextSpan(children: pedacos),
      style: base,
      textScaler: escalaTextoLimitada(context),
    );
  }
}

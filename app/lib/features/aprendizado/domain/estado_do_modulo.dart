import 'guia.dart';

/// Indica se o módulo representado por [guia] foi concluído por completo.
///
/// Para guias divididos em seções, todas as seções precisam ter ao menos uma
/// conclusão (`<guia>:<secao>`). Para guias sem seções, basta a chave direta do
/// guia (`<guia>`).
bool moduloConcluido(Guia guia, Map<String, int> concluidos) {
  if (guia.temSecoes) {
    return guia.secoes.isNotEmpty &&
        guia.secoes.every(
          (SecaoDoGuia s) => (concluidos['${guia.chave}:${s.chave}'] ?? 0) > 0,
        );
  }
  return (concluidos[guia.chave] ?? 0) > 0;
}

/// Devolve a `chave` do módulo integralmente concluído mais recentemente.
///
/// Em guias com seções, o módulo só é elegível quando **todas** as suas seções
/// estão presentes em [ordens] com valor positivo, utilizando a maior ordem
/// entre as seções como instante efetivo de conclusão do módulo. Também
/// considera chaves diretas (sem `:`) ausentes de [guias] para manter
/// compatibilidade com cenários isolados.
String? chaveDoUltimoModuloConcluido(
  Map<String, int> ordens,
  Iterable<Guia> guias,
) {
  if (ordens.isEmpty) return null;

  String? ultimo;
  int maiorOrdem = -1;
  final Set<String> chavesConhecidas = <String>{};

  for (final Guia guia in guias) {
    chavesConhecidas.add(guia.chave);
    final int? ordemDoGuia = _ordemDoModuloConcluido(guia, ordens);
    if (ordemDoGuia != null && ordemDoGuia > maiorOrdem) {
      maiorOrdem = ordemDoGuia;
      ultimo = guia.chave;
    }
  }

  for (final MapEntry<String, int> e in ordens.entries) {
    if (e.key.contains(':') || chavesConhecidas.contains(e.key)) continue;
    if (e.value > 0 && e.value > maiorOrdem) {
      maiorOrdem = e.value;
      ultimo = e.key;
    }
  }

  return ultimo;
}

int? _ordemDoModuloConcluido(Guia guia, Map<String, int> ordens) {
  if (!guia.temSecoes) {
    final int? ordem = ordens[guia.chave];
    return (ordem != null && ordem > 0) ? ordem : null;
  }
  if (guia.secoes.isEmpty) return null;

  int maiorOrdem = -1;
  for (final SecaoDoGuia secao in guia.secoes) {
    final int? ordem = ordens['${guia.chave}:${secao.chave}'];
    if (ordem == null || ordem <= 0) return null;
    if (ordem > maiorOrdem) maiorOrdem = ordem;
  }
  return maiorOrdem;
}

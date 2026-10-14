import '../../domain/guia.dart';

/// Todos os guias embarcados no aplicativo, por `chave` (T061).
///
/// ## Está vazio, e o teste sabe
///
/// As capturas e os textos vêm com cada guia (T070 em diante). Enquanto isso, o
/// registro é vazio e `catalogo_e_guias_test.dart` carrega a lista explícita de
/// itens do catálogo que ainda não têm guia — ela diminui a cada guia que
/// entra, e o teste reprova se alguém esquecer de tirar o item dela.
///
/// Para acrescentar um guia: um arquivo `<chave>.dart` nesta pasta, com uma
/// constante `Guia`, e uma linha na lista abaixo. Nada mais registra guia.
const List<Guia> todosOsGuias = <Guia>[];

/// O guia do item de catálogo [chave], ou `null` quando ele ainda não tem.
///
/// `null` não é erro: o catálogo pode ser mais novo que o aplicativo, e nesse
/// caso tocar no item abre a conversa (`contracts/catalogo.md`).
Guia? guiaDe(String chave) {
  for (final Guia guia in todosOsGuias) {
    if (guia.chave == chave) return guia;
  }
  return null;
}

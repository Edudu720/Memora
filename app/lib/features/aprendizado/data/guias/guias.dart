import '../../domain/guia.dart';
import 'facebook.dart';
import 'google_fotos.dart';
import 'gov_br.dart';
import 'instagram.dart';
import 'meu_inss.dart';
import 'telegram.dart';
import 'whatsapp.dart';
import 'youtube.dart';

/// Todos os guias embarcados no aplicativo, por `chave` (T061).
///
/// As capturas e os textos vêm com cada guia (T070 em diante).
///
/// Para acrescentar um guia: um arquivo `<chave>.dart` nesta pasta, com uma
/// constante `Guia`, e uma linha na lista abaixo. Nada mais registra guia.
final List<Guia> todosOsGuias = <Guia>[
  guiaWhatsapp,
  guiaInstagram,
  guiaYoutube,
  guiaFacebook,
  guiaGoogleFotos,
  guiaTelegram,
  guiaGovBr,
  guiaMeuInss,
];

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

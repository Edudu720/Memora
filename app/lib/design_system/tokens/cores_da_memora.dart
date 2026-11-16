import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';

import '../temas/memora_theme_extension.dart';
import 'cores.dart';

/// As cores do personagem Memora (feature 013, FR-001 e FR-007).
///
/// ## Por que um arquivo separado de `cores.dart`
///
/// A feature do redesenho final reescreve `cores.dart`. Ficar ao lado dele, e
/// não dentro, evita conflito e deixa a integração para quando as duas
/// estiverem na mesma linha de desenvolvimento. O acesso é o mesmo de
/// qualquer token: `context.memora.personagem`.
///
/// ## O que muda com a paleta
///
/// A Memora **segue a paleta** que a pessoa escolheu em Aparência (decisão do
/// Henrique, 2026-11-15): [corpo], [corpoSombra], [corpoLuz], [contorno] e
/// [visor] vêm da paleta ativa. Olhos, bochechas, antena, escudo e o livro são
/// a **identidade** dela e ficam iguais em todas as paletas.
///
/// - Temas claro e escuro: o corpo é o mesmo; só o [aro] muda. No claro ele é
///   o próprio contorno; no escuro é a cor primária clara da paleta, o que
///   garante a silhueta sobre fundo escuro (o contorno é escuro e não
///   aparece contra `#101216`).
/// - Alto contraste: a paleta **não vale** (R15). A Memora usa o conjunto
///   fixo [altoContraste], com aro branco.
///
/// Os pares de contraste (silhueta ≥ 3:1 contra fundo e superfície, contorno
/// contra corpo, olho contra visor) são conferidos em cada paleta e tema por
/// `specs/002-design-system/ferramentas/validar_paleta.py`. **Mudou um valor
/// aqui? Mude lá e rode o validador.**
@immutable
class CoresDaMemora {
  /// A cor do corpo e da cabeça.
  final Color corpo;

  /// O lado do corpo longe da luz.
  final Color corpoSombra;

  /// O lado do corpo perto da luz.
  final Color corpoLuz;

  /// O contorno grosso do desenho.
  final Color contorno;

  /// A linha de fora, que garante a silhueta contra o fundo do tema.
  final Color aro;

  /// A "tela" do rosto.
  final Color visor;

  /// Olhos, sobrancelha, boca e o painel do peito. Fixos.
  final Color olho;

  /// As bochechas rosadas. Fixas.
  final Color bochecha;

  /// A bolinha da antena e o círculo do painel. Fixos.
  final Color detalhe;

  /// O escudo da expressão preocupada. Fixo.
  final Color escudo;

  /// A luz do escudo. Fixa.
  final Color escudoLuz;

  /// As barrinhas do painel do peito. Fixas.
  final Color painelBarra;

  /// A capa do livro da expressão "dica". Fixa.
  final Color livro;

  /// As páginas do livro. Fixas.
  final Color livroPagina;

  /// A sombra que a Memora faz no chão.
  final Color sombraChao;

  /// O brilho especular da anfitriã (T087): o ponto de luz forte no vidro e
  /// na quina da cabeça. Vem do visor da paleta, clareado.
  final Color brilho;

  /// A luz de contorno da anfitriã (T087): o fio de luz que desenha a borda
  /// do lado oposto à luz principal e a destaca do fundo. Mistura da luz do
  /// corpo com o visor da paleta.
  final Color luzDeContorno;

  /// Cria um conjunto de cores da Memora.
  const CoresDaMemora({
    required this.corpo,
    required this.corpoSombra,
    required this.corpoLuz,
    required this.contorno,
    required this.aro,
    required this.visor,
    required this.olho,
    required this.bochecha,
    required this.detalhe,
    required this.escudo,
    required this.escudoLuz,
    required this.painelBarra,
    required this.livro,
    required this.livroPagina,
    required this.sombraChao,
    required this.brilho,
    required this.luzDeContorno,
  });

  // ---- o que é fixo, em todas as paletas ----
  static const Color _bochecha = Color(0xFFFCB5AF);
  static const Color _detalhe = Color(0xFFFAD66B);
  static const Color _escudo = Color(0xFFA3BCDD);
  static const Color _escudoLuz = Color(0xFFD3E2F5);
  static const Color _painelBarra = Color(0xFF9DBAF2);
  static const Color _livro = Color(0xFF5E7FAE);
  static const Color _livroPagina = Color(0xFFE8EEF8);
  static const Color _olho = Color(0xFF0E1F53);

  static const Color _branco = Color(0xFFFFFFFF);
  static const Color _sombraNoClaro = Color(0x520D1C50);
  static const Color _sombraNoEscuro = Color(0x8C000000);

  /// Corpo, sombra, luz, contorno e visor de cada paleta pronta. As chaves são
  /// as de [MemoraCores.paletas]. **A azul é a referência do Henrique.**
  static const Map<String, _PinturaDaPaleta> _paletas =
      <String, _PinturaDaPaleta>{
        'azul': _PinturaDaPaleta(
          corpo: Color(0xFF3565F3),
          sombra: Color(0xFF264AA9),
          luz: Color(0xFF4F76E6),
          contorno: Color(0xFF0D1C50),
          visor: Color(0xFFD7E4FC),
        ),
        'verde': _PinturaDaPaleta(
          corpo: Color(0xFF2E9B52),
          sombra: Color(0xFF1D5530),
          luz: Color(0xFF3BAC61),
          contorno: Color(0xFF0A3017),
          visor: Color(0xFFD9F2E1),
        ),
        'roxo': _PinturaDaPaleta(
          corpo: Color(0xFF7C4FD6),
          sombra: Color(0xFF542DA1),
          luz: Color(0xFF906ED6),
          contorno: Color(0xFF24104A),
          visor: Color(0xFFE6DCFA),
        ),
        'laranja-terra': _PinturaDaPaleta(
          corpo: Color(0xFFD2641F),
          sombra: Color(0xFF81411A),
          luz: Color(0xFFD77638),
          contorno: Color(0xFF3E1A08),
          visor: Color(0xFFFBE3D3),
        ),
        'rosa': _PinturaDaPaleta(
          corpo: Color(0xFFD6457F),
          sombra: Color(0xFF9B2A57),
          luz: Color(0xFFD56492),
          contorno: Color(0xFF4A0F28),
          visor: Color(0xFFFBDDEA),
        ),
        'grafite': _PinturaDaPaleta(
          corpo: Color(0xFF5B6B82),
          sombra: Color(0xFF38414E),
          luz: Color(0xFF6A7A92),
          contorno: Color(0xFF141C2A),
          visor: Color(0xFFE1E7EF),
        ),
      };

  /// O conjunto do alto contraste: a paleta não vale aqui (R15).
  static const CoresDaMemora altoContraste = CoresDaMemora(
    corpo: Color(0xFF4F7CFF),
    corpoSombra: Color(0xFF2F52C4),
    corpoLuz: Color(0xFF7399FF),
    contorno: Color(0xFF0D1C50),
    aro: Color(0xFFFFFFFF),
    visor: Color(0xFFF0F5FF),
    olho: Color(0xFF050E33),
    bochecha: _bochecha,
    detalhe: _detalhe,
    escudo: _escudo,
    escudoLuz: _escudoLuz,
    painelBarra: _painelBarra,
    livro: _livro,
    livroPagina: _livroPagina,
    sombraChao: Color(0x00000000),
    brilho: Color(0xFFF8FAFF),
    luzDeContorno: Color(0xFF9DB8FF),
  );

  /// As cores da Memora para um tema e uma paleta.
  ///
  /// [paleta] é uma das chaves de [MemoraCores.paletas]; nula ou desconhecida
  /// vira `azul`, como em [MemoraCores.comPaleta]. No alto contraste ela é
  /// ignorada.
  static CoresDaMemora para(MemoraTemaId tema, {String? paleta}) {
    if (tema == MemoraTemaId.altoContraste) return altoContraste;
    final String nome = _paletas.containsKey(paleta) ? paleta! : 'azul';
    final _PinturaDaPaleta p = _paletas[nome]!;
    final bool escuro = tema == MemoraTemaId.escuro;
    return CoresDaMemora(
      corpo: p.corpo,
      corpoSombra: p.sombra,
      corpoLuz: p.luz,
      contorno: p.contorno,
      // No escuro o contorno some contra o fundo: o aro é a primária clara
      // da paleta, que já foi medida contra o fundo escuro.
      aro: escuro ? MemoraCores.paletas[nome]!.primariaEscuro : p.contorno,
      visor: p.visor,
      olho: _olho,
      bochecha: _bochecha,
      detalhe: _detalhe,
      escudo: _escudo,
      escudoLuz: _escudoLuz,
      painelBarra: _painelBarra,
      livro: _livro,
      livroPagina: _livroPagina,
      sombraChao: escuro ? _sombraNoEscuro : _sombraNoClaro,
      brilho: Color.lerp(p.visor, _branco, 0.55)!,
      luzDeContorno: Color.lerp(p.luz, p.visor, 0.5)!,
    );
  }

  /// Descobre qual paleta está ativa olhando a cor primária do tema.
  ///
  /// O [MemoraTheme] não guarda o nome da paleta, só as cores que ela
  /// produziu; cada paleta tem uma primária própria por tema, e é por ela que
  /// se acha de volta o nome.
  static String _paletaDe(MemoraTheme tema) {
    final bool escuro = tema.id == MemoraTemaId.escuro;
    for (final MapEntry<String, PaletaDeDestaque> e
        in MemoraCores.paletas.entries) {
      final Color primaria = escuro
          ? e.value.primariaEscuro
          : e.value.primariaClaro;
      if (primaria == tema.cores.primaria) return e.key;
    }
    return 'azul';
  }

  /// As cores da Memora do [tema] (com a paleta que ele carrega).
  static CoresDaMemora doTema(MemoraTheme tema) =>
      para(tema.id, paleta: _paletaDe(tema));

  /// Os nomes das paletas que a Memora conhece (os de [MemoraCores.paletas]).
  static Iterable<String> get nomesDasPaletas => _paletas.keys;
}

@immutable
class _PinturaDaPaleta {
  final Color corpo;
  final Color sombra;
  final Color luz;
  final Color contorno;
  final Color visor;

  const _PinturaDaPaleta({
    required this.corpo,
    required this.sombra,
    required this.luz,
    required this.contorno,
    required this.visor,
  });
}

/// Acesso às cores da Memora a partir do tema: `context.memora.personagem`.
extension CoresDaMemoraNoTema on MemoraTheme {
  /// As cores do personagem neste tema e paleta.
  CoresDaMemora get personagem => CoresDaMemora.doTema(this);
}

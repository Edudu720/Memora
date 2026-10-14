import 'package:flutter/foundation.dart' show immutable;

import '../temas/memora_theme_extension.dart';
import '../tokens/dimensoes.dart';

/// Qual tema a pessoa escolheu.
///
/// [seguirSistema] é o padrão: o aplicativo acompanha o modo claro ou escuro
/// do aparelho até que a pessoa escolha explicitamente (FR-020).
enum EscolhaDeTema {
  /// Acompanha o aparelho.
  seguirSistema,

  /// Sempre claro.
  claro,

  /// Sempre escuro.
  escuro,

  /// Sempre alto contraste.
  altoContraste;

  /// Nome legível, exibido à pessoa.
  String get rotulo => switch (this) {
        EscolhaDeTema.seguirSistema => 'Igual ao meu celular',
        EscolhaDeTema.claro => 'Claro',
        EscolhaDeTema.escuro => 'Escuro',
        EscolhaDeTema.altoContraste => 'Mais contraste',
      };

  /// Explicação curta, em linguagem comum.
  String get descricao => switch (this) {
        EscolhaDeTema.seguirSistema =>
          'O Memora fica igual ao resto do seu celular',
        EscolhaDeTema.claro => 'Fundo claro, letras escuras',
        EscolhaDeTema.escuro => 'Fundo escuro, letras claras',
        EscolhaDeTema.altoContraste =>
          'Preto e branco bem separados, para enxergar melhor',
      };

  /// Converte para o tema concreto, dado o modo escuro do aparelho.
  MemoraTemaId paraTemaId({required bool sistemaEscuro}) => switch (this) {
        EscolhaDeTema.seguirSistema =>
          sistemaEscuro ? MemoraTemaId.escuro : MemoraTemaId.claro,
        EscolhaDeTema.claro => MemoraTemaId.claro,
        EscolhaDeTema.escuro => MemoraTemaId.escuro,
        EscolhaDeTema.altoContraste => MemoraTemaId.altoContraste,
      };
}

/// Como a pessoa prefere que o Memora se pareça.
///
/// **Classificação: Interno.** Não é dado sensível e não exige armazenamento
/// seguro — diferente das credenciais da feature 001.
///
/// Nota de privacidade: escolher alto contraste ou ampliação máxima permite
/// inferir deficiência visual. Por isso esta preferência **permanece no
/// aparelho** e não é enviada ao servidor nesta fase.
@immutable
class PreferenciaAparencia {
  /// Tema escolhido.
  final EscolhaDeTema tema;

  /// Ampliação de texto escolhida **dentro do aplicativo**, aplicada por cima
  /// da ampliação do sistema (FR-019).
  ///
  /// Sempre entre [MemoraDimensoes.escalaTextoMin] e
  /// [MemoraDimensoes.escalaTextoMax].
  final double escalaTexto;

  /// Reduzir o movimento **dentro do aplicativo**, mesmo que o sistema não o
  /// peça (FR-039a, T093).
  ///
  /// Falso é o padrão, e quer dizer "quem decide é o aparelho": a configuração
  /// do sistema continua valendo. Verdadeiro **soma** à do sistema, nunca a
  /// desfaz — quem pediu menos movimento ao celular não o recebe de volta por
  /// ter deixado esta opção desligada.
  final bool reduzirMovimento;

  /// A paleta pronta de cor de destaque (FR-039, R15), pelo nome.
  ///
  /// Hoje só existe [paletaPadrao]: as cores das demais paletas esperam a
  /// medição do `validar_paleta.py` e entram nos tokens depois (T122). O que
  /// já vale é o contrato — um nome guardado de uma paleta que não existe
  /// (retirada numa versão nova, ou dado corrompido) volta ao padrão, em
  /// [paletaValida].
  final String paleta;

  /// Cria uma preferência de aparência.
  const PreferenciaAparencia({
    this.tema = EscolhaDeTema.seguirSistema,
    this.escalaTexto = MemoraDimensoes.escalaTextoMin,
    this.reduzirMovimento = false,
    this.paleta = paletaPadrao,
  });

  /// O estado de fábrica, para o qual "voltar ao padrão" retorna (FR-022).
  static const PreferenciaAparencia padrao = PreferenciaAparencia();

  /// A paleta do protótipo, a que o aplicativo sempre teve.
  static const String paletaPadrao = 'azul';

  /// As paletas que existem nesta versão do aplicativo.
  static const Set<String> paletasConhecidas = <String>{paletaPadrao};

  /// [nome] se for uma paleta que existe, senão [paletaPadrao].
  static String paletaValida(String? nome) =>
      nome != null && paletasConhecidas.contains(nome) ? nome : paletaPadrao;

  /// Verdadeiro quando nada foi personalizado.
  bool get ehPadrao =>
      tema == padrao.tema &&
      escalaTexto == padrao.escalaTexto &&
      reduzirMovimento == padrao.reduzirMovimento &&
      paleta == padrao.paleta;

  /// Retorna uma cópia com os campos informados substituídos.
  ///
  /// [escalaTexto] é sempre limitada ao intervalo permitido — um valor fora
  /// da faixa nunca chega a ser persistido. O mesmo vale para [paleta]: um
  /// nome que não existe vira o padrão.
  PreferenciaAparencia copyWith({
    EscolhaDeTema? tema,
    double? escalaTexto,
    bool? reduzirMovimento,
    String? paleta,
  }) {
    return PreferenciaAparencia(
      tema: tema ?? this.tema,
      escalaTexto: (escalaTexto ?? this.escalaTexto).clamp(
        MemoraDimensoes.escalaTextoMin,
        MemoraDimensoes.escalaTextoMax,
      ),
      reduzirMovimento: reduzirMovimento ?? this.reduzirMovimento,
      paleta: paletaValida(paleta ?? this.paleta),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PreferenciaAparencia &&
      other.tema == tema &&
      other.escalaTexto == escalaTexto &&
      other.reduzirMovimento == reduzirMovimento &&
      other.paleta == paleta;

  @override
  int get hashCode => Object.hash(tema, escalaTexto, reduzirMovimento, paleta);

  @override
  String toString() =>
      'PreferenciaAparencia(tema: ${tema.name}, escalaTexto: $escalaTexto, '
      'reduzirMovimento: $reduzirMovimento, paleta: $paleta)';
}

/// Contrato de persistência da preferência de aparência.
///
/// A interface vive no Design System; a implementação concreta vive em
/// `services/`, para que o Design System não dependa de nenhum mecanismo de
/// armazenamento.
abstract interface class RepositorioPreferenciaAparencia {
  /// Lê a preferência salva. Retorna [PreferenciaAparencia.padrao] quando não
  /// houver nada salvo.
  Future<PreferenciaAparencia> carregar();

  /// Persiste a preferência.
  Future<void> salvar(PreferenciaAparencia preferencia);
}

/// O que pode estar errado numa data de nascimento digitada (FR-042c).
enum ProblemaDaData {
  /// Falta preencher dia, mês ou ano, ou há algo que não é número.
  incompleta,

  /// O ano foi escrito com menos de quatro números.
  anoCurto,

  /// A data não existe no calendário: 31/02, mês 13, dia 0.
  impossivel,

  /// A data ainda não chegou.
  futura,

  /// A data dá mais de 120 anos.
  antiga,
}

/// O resultado de validar uma data: ou a data, ou o problema, nunca os dois.
class ResultadoDaData {
  /// A data válida, ou `null` quando há [problema].
  final DataDeNascimento? data;

  /// O que está errado, ou `null` quando há [data].
  final ProblemaDaData? problema;

  const ResultadoDaData._(this.data, this.problema);

  /// Resultado de uma data válida.
  const ResultadoDaData.valida(DataDeNascimento data) : this._(data, null);

  /// Resultado de uma data recusada.
  const ResultadoDaData.recusada(ProblemaDaData problema)
    : this._(null, problema);
}

/// A data de nascimento que a pessoa quis informar no Perfil (FR-042c).
///
/// É **opcional** e **só do aparelho**: nada aqui vai ao servidor. A idade
/// **nunca é gravada** — é calculada na hora de mostrar, por [idadeEm], para
/// não ficar velha no dia do aniversário.
class DataDeNascimento {
  /// Dia do mês, de 1 a 31.
  final int dia;

  /// Mês, de 1 a 12.
  final int mes;

  /// Ano com quatro dígitos.
  final int ano;

  const DataDeNascimento._(this.dia, this.mes, this.ano);

  /// Quantos anos a pessoa pode ter, no máximo.
  static const int idadeMaxima = 120;

  /// Valida o que a pessoa digitou. [hoje] é injetável para o teste.
  static ResultadoDaData validar({
    required String dia,
    required String mes,
    required String ano,
    required DateTime hoje,
  }) {
    final int? d = int.tryParse(dia.trim());
    final int? m = int.tryParse(mes.trim());
    final String anoLimpo = ano.trim();
    final int? a = int.tryParse(anoLimpo);
    if (d == null || m == null || a == null) {
      return const ResultadoDaData.recusada(ProblemaDaData.incompleta);
    }
    if (anoLimpo.length < 4) {
      return const ResultadoDaData.recusada(ProblemaDaData.anoCurto);
    }
    return _de(d, m, a, hoje);
  }

  /// Lê o que foi guardado (`aaaa-mm-dd`). `null` se estiver corrompido.
  static DataDeNascimento? deArmazenado(String? texto) {
    if (texto == null) return null;
    final List<String> partes = texto.split('-');
    if (partes.length != 3) return null;
    final int? a = int.tryParse(partes[0]);
    final int? m = int.tryParse(partes[1]);
    final int? d = int.tryParse(partes[2]);
    if (a == null || m == null || d == null) return null;
    if (!_existe(d, m, a)) return null;
    return DataDeNascimento._(d, m, a);
  }

  static ResultadoDaData _de(int d, int m, int a, DateTime hoje) {
    if (!_existe(d, m, a)) {
      return const ResultadoDaData.recusada(ProblemaDaData.impossivel);
    }
    final DataDeNascimento data = DataDeNascimento._(d, m, a);
    final DateTime inicioDeHoje = DateTime(hoje.year, hoje.month, hoje.day);
    if (DateTime(a, m, d).isAfter(inicioDeHoje)) {
      return const ResultadoDaData.recusada(ProblemaDaData.futura);
    }
    if (data.idadeEm(hoje) > idadeMaxima) {
      return const ResultadoDaData.recusada(ProblemaDaData.antiga);
    }
    return ResultadoDaData.valida(data);
  }

  static bool _existe(int d, int m, int a) {
    if (a < 1 || m < 1 || m > 12 || d < 1) return false;
    final DateTime construida = DateTime(a, m, d);
    return construida.year == a && construida.month == m && construida.day == d;
  }

  /// A idade completa em [hoje].
  ///
  /// Quem nasceu em 29 de fevereiro faz anos em 1º de março nos anos que não
  /// são bissextos: até lá, o aniversário "ainda não chegou".
  int idadeEm(DateTime hoje) {
    int idade = hoje.year - ano;
    final bool aindaNaoFezAnos =
        hoje.month < mes || (hoje.month == mes && hoje.day < dia);
    if (aindaNaoFezAnos) idade -= 1;
    return idade;
  }

  /// O texto guardado, `aaaa-mm-dd`.
  String paraArmazenar() =>
      '${ano.toString().padLeft(4, '0')}-'
      '${mes.toString().padLeft(2, '0')}-'
      '${dia.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is DataDeNascimento &&
      other.dia == dia &&
      other.mes == mes &&
      other.ano == ano;

  @override
  int get hashCode => Object.hash(dia, mes, ano);
}

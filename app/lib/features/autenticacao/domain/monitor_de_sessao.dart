import 'dart:async';

/// Encerra a sessão após inatividade prolongada, avisando antes (FR-017, T055).
///
/// ## Contra qual ameaça isto existe
///
/// A tabela de ameaças da spec lista a FR-017 como defesa contra **roubo de
/// referência de sessão**. Concretamente: o celular esquecido em cima da mesa,
/// emprestado ao neto, ou perdido. Não é sobre "faz semanas que não abro o
/// aplicativo" — para isso já existe a validade do refresh, de 60 dias.
///
/// É por isso que a contagem mede inatividade **dentro do uso**, e não tempo
/// absoluto desde o login. Quem está usando o Memora nunca é interrompido.
///
/// ## Por que existe aviso, e por que ele dura dois minutos
///
/// Sessão que cai sem avisar é indistinguível de defeito — e, no público do
/// Memora, "o aplicativo me expulsou" é motivo para desinstalar. O aviso
/// transforma isso numa pergunta respondível.
///
/// Dois minutos não é arredondamento: é o tempo de alguém com dificuldade
/// motora perceber o aviso, achar os óculos e acertar o botão. Um minuto, o
/// padrão de aplicativo bancário, expulsa exatamente quem este produto atende.
///
/// ## Sem Flutter aqui de propósito
///
/// Isto é regra de sessão, não interface. Mantê-lo em Dart puro deixa a regra
/// testável sem `pumpAndSettle` — que, como o projeto já descobriu, trava com
/// um `Carregando` na tela porque ele anima sem parar.
class MonitorDeSessao {
  /// Quanto tempo parado até a sessão cair.
  static const Duration inatividadePadrao = Duration(minutes: 30);

  /// Com quanta antecedência avisar.
  static const Duration avisoPadrao = Duration(minutes: 2);

  /// Tempo total de inatividade tolerado.
  final Duration inatividade;

  /// Antecedência do aviso.
  final Duration aviso;

  /// Chamado quando falta [aviso] para a sessão cair.
  ///
  /// Recebe quantos segundos ainda restam, para a tela poder dizer o número.
  final void Function(int segundosRestantes) aoAvisar;

  /// Chamado quando a sessão cai.
  final void Function() aoExpirar;

  Timer? _ateOAviso;
  Timer? _ateAExpiracao;
  bool _avisando = false;

  /// Cria o monitor.
  ///
  /// [aviso] precisa ser menor que [inatividade] — do contrário o aviso
  /// dispararia junto com a expiração, ou antes dela, e a pessoa seria
  /// desconectada no mesmo instante em que soubesse que isso ia acontecer.
  MonitorDeSessao({
    required this.aoAvisar,
    required this.aoExpirar,
    this.inatividade = inatividadePadrao,
    this.aviso = avisoPadrao,
  }) : assert(
          aviso < inatividade,
          'O aviso precisa vir antes da expiração, não junto com ela.',
        );

  /// Verdadeiro entre o aviso e a expiração.
  bool get avisando => _avisando;

  /// Começa a contar. Chamado quando a pessoa entra.
  void iniciar() => registrarAtividade();

  /// Zera a contagem.
  ///
  /// Chamado a cada toque na tela e pelo botão do aviso. Zerar no aviso é o que
  /// faz o *"estou aqui, pode continuar"* significar alguma coisa.
  void registrarAtividade() {
    _cancelar();
    _avisando = false;
    _ateOAviso = Timer(inatividade - aviso, _dispararAviso);
  }

  /// Para de contar, sem expirar. Chamado ao sair da conta.
  void parar() {
    _cancelar();
    _avisando = false;
  }

  void _dispararAviso() {
    _avisando = true;
    _ateAExpiracao = Timer(aviso, () {
      _avisando = false;
      aoExpirar();
    });
    aoAvisar(aviso.inSeconds);
  }

  void _cancelar() {
    _ateOAviso?.cancel();
    _ateOAviso = null;
    _ateAExpiracao?.cancel();
    _ateAExpiracao = null;
  }

  /// Libera os temporizadores.
  void dispose() => _cancelar();
}

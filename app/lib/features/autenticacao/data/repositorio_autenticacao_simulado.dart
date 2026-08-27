import '../domain/autenticacao.dart';

/// Implementação **provisória** que simula o servidor.
///
/// Existe para permitir construir e testar as telas sem o backend de pé. Será
/// substituída por `RepositorioAutenticacaoApi`, sobre o cliente gerado do
/// contrato OpenAPI.
///
/// **Não vai para produção.** A troca é de uma linha, porque as telas dependem
/// apenas de [RepositorioAutenticacao].
///
/// ## Por que ele imita o bloqueio progressivo
///
/// A tela de login precisa mostrar o estado bloqueado, e esse estado é o mais
/// difícil de acertar: é onde a FR-015 exige acolhimento e onde o teste do
/// cenário V6 bate. Um simulado que sempre aceita a senha deixaria esse caminho
/// sem exercício nenhum até o dia da integração — que é tarde demais.
///
/// A escada reproduz a do servidor: 5 falhas seguidas bloqueiam por 1 minuto, e
/// cada bloqueio seguinte sobe um degrau. Como no backend, **insistir durante a
/// espera não conta falha nova** — senão quem tentasse três vezes bloqueada
/// pularia dois degraus sem ter tido chance de acertar.
class RepositorioAutenticacaoSimulado implements RepositorioAutenticacao {
  /// Quantas falhas seguidas disparam o primeiro bloqueio.
  static const int falhasAteBloquear = 5;

  /// A escada de espera, em segundos — igual à do `BloqueioProgressivo`.
  static const List<int> escadaPadrao = <int>[60, 300, 900, 3600];

  /// Canais que fingimos já existir, para exercitar a FR-010.
  final Set<String> canaisJaCadastrados;

  /// Demora simulada, para a tela exercitar o estado de carregando.
  final Duration demora;

  /// Força uma falha específica, para testar os caminhos de erro.
  final FalhaAutenticacao? falhaForcada;

  /// Degraus de bloqueio, em segundos.
  final List<int> escadaDeBloqueio;

  /// Relógio, trocável no teste para a escada caber em milissegundos.
  final DateTime Function() agora;

  final Map<String, _ContaSimulada> _contas = <String, _ContaSimulada>{};

  int _falhasSeguidas = 0;
  int _bloqueiosAplicados = 0;
  DateTime? _bloqueadaAte;
  PessoaAutenticada? _ultimaSessao;

  /// Cria o repositório simulado.
  RepositorioAutenticacaoSimulado({
    Set<String>? canaisJaCadastrados,
    this.demora = const Duration(milliseconds: 700),
    this.falhaForcada,
    this.escadaDeBloqueio = escadaPadrao,
    DateTime Function()? agora,
  })  : canaisJaCadastrados = canaisJaCadastrados ?? <String>{},
        agora = agora ?? DateTime.now;

  /// Contas criadas nesta execução, para a demonstração poder entrar depois de
  /// cadastrar. Exposto só para leitura, e só para teste.
  Iterable<String> get identificadoresConhecidos => _contas.keys;

  @override
  Future<ResultadoAutenticacao> cadastrar(DadosDeCadastro dados) async {
    await Future<void>.delayed(demora);

    if (falhaForcada != null) {
      return AutenticacaoFalhou(
        falhaForcada!,
        tentarNovamenteEmSegundos:
            falhaForcada == FalhaAutenticacao.muitasTentativas ? 300 : null,
      );
    }

    final String chave = _normalizar(dados.canal);
    final String canalId = 'canal-${chave.hashCode.abs()}';
    final PessoaAutenticada pessoa = PessoaAutenticada(
      id: 'simulado-${dados.canal.hashCode.abs()}',
      nomeTratamento: dados.nomeTratamento,
      canalId: canalId,
    );

    // Canal já cadastrado devolve o MESMO resultado de um cadastro novo, e não
    // sobrescreve a conta existente. Qualquer diferença observável aqui
    // revelaria a existência da conta (FR-010).
    if (!canaisJaCadastrados.contains(chave) && !_contas.containsKey(chave)) {
      _contas[chave] = _ContaSimulada(
        senha: dados.senha,
        pessoa: pessoa,
        // A conta assistida existe mas nao entra ate a posse ser confirmada,
        // como o servidor faz com PENDENTE_VERIFICACAO.
        pendenteDeVerificacao: dados.modoAssistido,
        canalId: canalId,
      );
    }

    _ultimaSessao = pessoa;
    return AutenticacaoConcluida(pessoa);
  }

  @override
  Future<ResultadoAutenticacao> entrar(DadosDeEntrada dados) async {
    await Future<void>.delayed(demora);

    if (falhaForcada != null) {
      return AutenticacaoFalhou(
        falhaForcada!,
        tentarNovamenteEmSegundos:
            falhaForcada == FalhaAutenticacao.muitasTentativas
                ? escadaDeBloqueio.first
                : null,
      );
    }

    // Durante a espera a resposta é sempre a mesma, e NÃO conta falha nova.
    final int restante = segundosDeBloqueioRestantes;
    if (restante > 0) {
      return AutenticacaoFalhou(
        FalhaAutenticacao.muitasTentativas,
        tentarNovamenteEmSegundos: restante,
      );
    }

    final _ContaSimulada? conta = _contas[_normalizar(dados.identificador)];
    // Conta assistida que ainda nao confirmou o canal nao entra, e a recusa e a
    // mesma de senha errada: dizer "confirme seu canal" contaria a quem tentou
    // que aquele identificador tem conta (FR-013).
    final bool confere = conta != null &&
        conta.senha == dados.senha &&
        !conta.pendenteDeVerificacao;

    if (!confere) {
      _falhasSeguidas++;
      if (_falhasSeguidas >= falhasAteBloquear) {
        final int espera = escadaDeBloqueio[
            _bloqueiosAplicados.clamp(0, escadaDeBloqueio.length - 1)];
        _bloqueiosAplicados++;
        _falhasSeguidas = 0;
        _bloqueadaAte = agora().add(Duration(seconds: espera));
        // A tentativa que estoura o limite já responde bloqueio, não recusa —
        // é o passo 2 do cenário V6.
        return AutenticacaoFalhou(
          FalhaAutenticacao.muitasTentativas,
          tentarNovamenteEmSegundos: espera,
        );
      }
      // Recusa idêntica para conta inexistente e senha errada (FR-013).
      return const AutenticacaoFalhou(FalhaAutenticacao.credenciaisInvalidas);
    }

    _falhasSeguidas = 0;
    _bloqueiosAplicados = 0;
    _bloqueadaAte = null;
    _ultimaSessao = conta.pessoa;
    return AutenticacaoConcluida(conta.pessoa);
  }

  @override
  Future<ResultadoAutenticacao> renovarSessao() async {
    await Future<void>.delayed(demora);

    final PessoaAutenticada? pessoa = _ultimaSessao;
    if (pessoa == null) {
      return const AutenticacaoFalhou(FalhaAutenticacao.credenciaisInvalidas);
    }
    return AutenticacaoConcluida(pessoa);
  }

  @override
  Future<void> encerrarSessao() async => _ultimaSessao = null;

  /// O código que o simulado sempre "envia".
  ///
  /// Fixo de propósito: não há como ler um SMS numa demonstração, e sortear
  /// seis dígitos que ninguém consegue descobrir tornaria o modo assistido
  /// impossível de mostrar no aparelho. **O servidor real sorteia** — ver
  /// `GeradorDeCodigoNumerico`.
  static const String codigoDaDemonstracao = '123456';

  /// Códigos pedidos nesta execução, por canal. Só para teste.
  final Map<String, String> codigosEnviados = <String, String>{};

  @override
  Future<ResultadoDeCanal> enviarCodigoDeCanal(String canalId) async {
    await Future<void>.delayed(demora);

    if (falhaForcada != null) {
      return CanalFalhou(falhaForcada!);
    }

    // Responde igual exista o canal ou não, como o servidor: o `202` do
    // contrato existe justamente para este caminho não virar oráculo.
    codigosEnviados[canalId] = codigoDaDemonstracao;
    return const CanalConcluido();
  }

  @override
  Future<ResultadoDeCanal> confirmarCanal(String canalId, String codigo) async {
    await Future<void>.delayed(demora);

    if (falhaForcada != null) {
      return CanalFalhou(falhaForcada!);
    }

    if (codigo != codigoDaDemonstracao) {
      return const CanalFalhou(FalhaAutenticacao.dadosInvalidos);
    }

    final _ContaSimulada? conta = _contaDoCanal(canalId);
    if (conta == null) {
      return const CanalFalhou(FalhaAutenticacao.dadosInvalidos);
    }

    // Confirmar a posse é o que conclui o cadastro assistido: daqui em diante a
    // conta entra.
    conta.pendenteDeVerificacao = false;
    return const CanalConcluido();
  }

  /// Identificadores que pediram recuperação e para os quais um código
  /// **realmente** existe. Só para teste.
  ///
  /// Repare que este mapa fica vazio quando a conta não existe — e que
  /// [solicitarRecuperacao] devolve sucesso do mesmo jeito. É a FR-019 em
  /// miniatura: por fora as duas situações são indistinguíveis; por dentro
  /// só uma delas tem código.
  final Map<String, String> recuperacoesPedidas = <String, String>{};

  @override
  Future<ResultadoDeCanal> solicitarRecuperacao(String identificador) async {
    await Future<void>.delayed(demora);

    if (falhaForcada != null) {
      return CanalFalhou(falhaForcada!);
    }

    final String chave = _normalizar(identificador);
    final _ContaSimulada? conta = _contas[chave];

    // Conta pendente de verificação não recebe código: a recuperação só aceita
    // canal com posse confirmada (FR-052). Sem essa regra, o acompanhante que
    // cadastrasse o próprio contato controlaria a recuperação da conta alheia
    // para sempre, que é a FR-062 furada por caminho lateral.
    if (conta != null && !conta.pendenteDeVerificacao) {
      recuperacoesPedidas[chave] = codigoDaDemonstracao;
    }

    // Sucesso **sempre**, inclusive sem conta. Devolver falha aqui quando o
    // identificador não existe seria dizer "essa conta não existe" com outras
    // palavras — e a tela, que só sabe ler este resultado, contaria.
    return const CanalConcluido();
  }

  @override
  Future<ResultadoAutenticacao> confirmarRecuperacao({
    required String identificador,
    required String codigo,
    required String novaSenha,
  }) async {
    await Future<void>.delayed(demora);

    if (falhaForcada != null) {
      return AutenticacaoFalhou(
        falhaForcada!,
        tentarNovamenteEmSegundos:
            falhaForcada == FalhaAutenticacao.muitasTentativas
                ? escadaDeBloqueio.first
                : null,
      );
    }

    final String chave = _normalizar(identificador);
    final _ContaSimulada? conta = _contas[chave];
    final String? esperado = recuperacoesPedidas[chave];

    // Recusa única: código errado, nunca pedido e conta inexistente dizem a
    // mesma coisa. Esta é a etapa em que já não há o que esconder sobre a
    // existência da conta — mas há sobre **em que ponto** quem está tentando
    // chegou, e é isso que a recusa única nega.
    if (conta == null || esperado == null || codigo != esperado) {
      return const AutenticacaoFalhou(FalhaAutenticacao.dadosInvalidos);
    }

    // Uso único (FR-020): o código sai do mapa antes de a senha trocar.
    recuperacoesPedidas.remove(chave);

    final _ContaSimulada trocada = _ContaSimulada(
      senha: novaSenha,
      pessoa: conta.pessoa,
      canalId: conta.canalId,
    );
    _contas[chave] = trocada;

    // Trocar a senha limpa o bloqueio: quem chegou aqui provou posse do canal,
    // e continuar barrada depois disso seria punir a pessoa certa.
    _falhasSeguidas = 0;
    _bloqueiosAplicados = 0;
    _bloqueadaAte = null;
    _ultimaSessao = trocada.pessoa;

    return AutenticacaoConcluida(trocada.pessoa);
  }

  _ContaSimulada? _contaDoCanal(String canalId) {
    for (final _ContaSimulada conta in _contas.values) {
      if (conta.canalId == canalId) return conta;
    }
    return null;
  }

  /// Cria uma conta **sem passar pelo cadastro**, e sem abrir sessão.
  ///
  /// Existe para teste e demonstração. Dentro de `testWidgets` o relógio é
  /// falso: `await cadastrar(...)` fica esperando um temporizador que só anda
  /// quando alguém bombeia quadros, e o teste trava antes da primeira asserção.
  void registrarConta({
    required String identificador,
    required String senha,
    required String nome,
    bool pendenteDeVerificacao = false,
  }) {
    final String chave = _normalizar(identificador);
    final String canalId = 'canal-${chave.hashCode.abs()}';
    _contas[chave] = _ContaSimulada(
      senha: senha,
      pessoa: PessoaAutenticada(
        id: 'simulado-${chave.hashCode.abs()}',
        nomeTratamento: nome,
        canalId: canalId,
      ),
      pendenteDeVerificacao: pendenteDeVerificacao,
      canalId: canalId,
    );
  }

  /// Quantos segundos faltam do bloqueio, ou zero se não há bloqueio.
  int get segundosDeBloqueioRestantes {
    final DateTime? ate = _bloqueadaAte;
    if (ate == null) return 0;
    final int falta = ate.difference(agora()).inSeconds;
    return falta > 0 ? falta : 0;
  }

  String _normalizar(String valor) => valor.trim().toLowerCase();
}

class _ContaSimulada {
  final String senha;
  final PessoaAutenticada pessoa;

  /// A conta existe mas nao entra ate a posse do canal ser confirmada
  /// (FR-062). Deixa de ser verdade quando o codigo certo e digitado.
  bool pendenteDeVerificacao;

  final String canalId;

  _ContaSimulada({
    required this.senha,
    required this.pessoa,
    required this.canalId,
    this.pendenteDeVerificacao = false,
  });
}

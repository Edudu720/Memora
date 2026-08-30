import 'package:dio/dio.dart';
import 'package:memora_api/memora_api.dart' as api;

import '../../../services/seguranca/cofre_de_credenciais.dart';
import '../domain/autenticacao.dart';

/// Fala com o servidor pelo cliente **gerado** do contrato (T030, R8).
///
/// ## O que esta classe faz
///
/// Traduz, nos dois sentidos, entre o domínio do aplicativo e os tipos gerados
/// de `contracts/openapi.yaml` — e guarda a sessão no cofre. Nada mais. Regra de
/// negócio não mora aqui: quem decide o que a tela mostra é o controlador, e
/// quem decide o que o servidor faz é o servidor.
///
/// ## A tradução de erro é a parte que importa
///
/// O servidor devolve um `codigo` estável justamente para o aplicativo decidir
/// comportamento sem ler texto. Aqui esse código vira [FalhaAutenticacao]. **A
/// mensagem do servidor não é usada para decidir nada** — ela é texto para a
/// pessoa, e comparar texto para tomar decisão quebraria no dia em que alguém
/// melhorasse uma frase.
///
/// ## Sobre o cadastro com canal já existente
///
/// O servidor responde `201` **idêntica** ao cadastro novo, sem revelar que a
/// conta existe (FR-010). Este repositório não tenta adivinhar qual dos dois
/// aconteceu — não há como, e tentar seria reconstruir o vazamento que o
/// servidor evitou. A sessão devolvida nesse caso não resolve para conta
/// nenhuma, e o aplicativo descobre no primeiro uso, quando a resposta é `401` e
/// a pessoa é conduzida ao login (cenário 5 da US1).
class RepositorioAutenticacaoApi implements RepositorioAutenticacao {
  final api.MemoraApi _api;
  final CofreDeCredenciais _cofre;

  /// Cria o repositório sobre o cliente gerado.
  RepositorioAutenticacaoApi({
    required api.MemoraApi cliente,
    required CofreDeCredenciais cofre,
  })  : _api = cliente,
        _cofre = cofre;

  @override
  Future<ResultadoAutenticacao> cadastrar(DadosDeCadastro dados) async {
    try {
      final Response<api.SessaoResposta> resposta =
          await _api.getCadastroApi().authCadastroPost(
                cadastroRequisicao: api.CadastroRequisicao(
                  nomeTratamento: dados.nomeTratamento,
                  senha: dados.senha,
                  modoAssistido: dados.modoAssistido,
                  canal: api.CanalRequisicao(
                    tipo: _tipoDoContrato(dados.tipoCanal),
                    valor: dados.canal,
                  ),
                ),
              );

      final api.SessaoResposta? sessao = resposta.data;
      if (sessao == null) {
        return const AutenticacaoFalhou(FalhaAutenticacao.inesperada);
      }

      // Antes de devolver: se a gravacao falhar, a pessoa entra e a sessao some
      // no proximo inicio do aplicativo, sem nada explicar.
      await _cofre.guardarSessao(
        tokenAcesso: sessao.tokenAcesso,
        refreshToken: sessao.refreshToken,
      );

      return AutenticacaoConcluida(
        _pessoaDe(sessao, padraoDoNome: dados.nomeTratamento),
      );
    } on DioException catch (excecao) {
      return _falhaDe(excecao);
    }
  }

  @override
  Future<ResultadoAutenticacao> entrar(DadosDeEntrada dados) async {
    try {
      final Response<api.SessaoResposta> resposta =
          await _api.getSessoApi().authEntrarPost(
                entrarRequisicao: api.EntrarRequisicao(
                  identificador: dados.identificador,
                  senha: dados.senha,
                ),
              );

      final api.SessaoResposta? sessao = resposta.data;
      if (sessao == null) {
        return const AutenticacaoFalhou(FalhaAutenticacao.inesperada);
      }

      await _cofre.guardarSessao(
        tokenAcesso: sessao.tokenAcesso,
        refreshToken: sessao.refreshToken,
      );

      return AutenticacaoConcluida(_pessoaDe(sessao));
    } on DioException catch (excecao) {
      return _falhaDe(excecao);
    }
  }

  @override
  Future<ResultadoAutenticacao> renovarSessao() async {
    // Sem refresh guardado não há o que renovar. Vale devolver a recusa sem
    // tocar a rede: uma chamada com corpo vazio geraria um 400 e um evento de
    // auditoria para algo que já sabíamos aqui.
    final String? refresh = await _cofre.refreshToken();
    if (refresh == null || refresh.isEmpty) {
      return const AutenticacaoFalhou(FalhaAutenticacao.credenciaisInvalidas);
    }

    try {
      final Response<api.SessaoResposta> resposta =
          await _api.getSessoApi().authSessaoRenovarPost(
                authSessaoRenovarPostRequest:
                    api.AuthSessaoRenovarPostRequest(refreshToken: refresh),
              );

      final api.SessaoResposta? sessao = resposta.data;
      if (sessao == null) {
        return const AutenticacaoFalhou(FalhaAutenticacao.inesperada);
      }

      // A gravação do par novo NÃO é detalhe de arrumação. O refresh rotaciona
      // a cada uso: se guardarmos o antigo, a próxima renovação apresenta um
      // token já gasto — que é exatamente o sinal que o servidor trata como
      // roubo, derrubando a família inteira e expulsando a pessoa da conta.
      await _cofre.guardarSessao(
        tokenAcesso: sessao.tokenAcesso,
        refreshToken: sessao.refreshToken,
      );

      return AutenticacaoConcluida(_pessoaDe(sessao));
    } on DioException catch (excecao) {
      return _falhaDe(excecao);
    }
  }

  @override
  Future<void> encerrarSessao() async {
    // Só o cofre. `POST /v1/auth/sair` é a T074 e ainda não existe no servidor:
    // chamá-lo hoje daria 404, que o tratador converteria em DADOS_INVALIDOS e
    // deixaria a pessoa presa numa tela de erro ao tentar sair.
    await _cofre.limpar();
  }

  @override
  Future<ResultadoDeCanal> enviarCodigoDeCanal(String canalId) async {
    if (!await _autenticarChamada()) {
      return const CanalFalhou(FalhaAutenticacao.credenciaisInvalidas);
    }

    try {
      await _api.getCanaisDeContatoApi().canaisCanalIdCodigoPost(
            canalId: canalId,
          );
      return const CanalConcluido();
    } on DioException catch (excecao) {
      return _falhaDeCanal(excecao);
    }
  }

  @override
  Future<ResultadoDeCanal> confirmarCanal(String canalId, String codigo) async {
    if (!await _autenticarChamada()) {
      return const CanalFalhou(FalhaAutenticacao.credenciaisInvalidas);
    }

    try {
      await _api.getCanaisDeContatoApi().canaisCanalIdVerificarPost(
            canalId: canalId,
            canaisCanalIdVerificarPostRequest:
                api.CanaisCanalIdVerificarPostRequest(codigo: codigo),
          );
      return const CanalConcluido();
    } on DioException catch (excecao) {
      return _falhaDeCanal(excecao);
    }
  }

  /// Traduz a pessoa do contrato, com o canal principal junto.
  ///
  /// O canal escolhido é o marcado como `principal`; não havendo nenhum, cai no
  /// primeiro. Hoje a resposta traz sempre um só, mas a FR-050 prevê um segundo
  /// canal adicionado depois do primeiro acesso — e aí "o primeiro da lista"
  /// deixaria de ser o certo sem aviso nenhum.
  PessoaAutenticada _pessoaDe(
    api.SessaoResposta sessao, {
    String padraoDoNome = '',
  }) {
    final List<api.Canal> canais = sessao.pessoa.canais ?? const <api.Canal>[];
    final api.Canal? principal = canais.isEmpty
        ? null
        : canais.firstWhere(
            (api.Canal canal) => canal.principal ?? false,
            orElse: () => canais.first,
          );

    return PessoaAutenticada(
      id: sessao.pessoa.id ?? '',
      nomeTratamento: sessao.pessoa.nomeTratamento ?? padraoDoNome,
      canalId: principal?.id,
      canalVerificado: principal?.verificado ?? false,
    );
  }

  /// Põe o token de acesso no cliente gerado antes de uma chamada autenticada.
  ///
  /// Estes são os **primeiros** caminhos autenticados do aplicativo: até aqui
  /// todos os endpoints eram públicos, e por isso nada configurava o cabeçalho.
  ///
  /// O nome `tokenDeAcesso` não é escolha nossa — é a chave do `securityScheme`
  /// no `openapi.yaml`, e é por ela que o interceptor gerado casa o token com a
  /// operação. Mudá-la no contrato quebra isto em silêncio, sem erro de
  /// compilação.
  Future<bool> _autenticarChamada() async {
    final String? token = await _cofre.tokenAcesso();
    if (token == null || token.isEmpty) {
      return false;
    }
    _api.setBearerAuth('tokenDeAcesso', token);
    return true;
  }

  /// Converte a falha do transporte em falha de canal.
  ///
  /// Reaproveita a tradução de [_falhaDe] em vez de duplicar a tabela de
  /// códigos: o servidor devolve os mesmos, e duas tabelas divergiriam na
  /// primeira vez que alguém acrescentasse um.
  ResultadoDeCanal _falhaDeCanal(DioException excecao) {
    final ResultadoAutenticacao traduzida = _falhaDe(excecao);
    return switch (traduzida) {
      AutenticacaoFalhou(:final FalhaAutenticacao falha) => CanalFalhou(falha),
      // Inalcancavel: _falhaDe so produz falha. O ramo existe porque o switch e
      // exaustivo, e transformar sucesso em sucesso aqui seria mentira.
      AutenticacaoConcluida() =>
        const CanalFalhou(FalhaAutenticacao.inesperada),
    };
  }

  api.CanalRequisicaoTipoEnum _tipoDoContrato(TipoCanal tipo) => switch (tipo) {
        TipoCanal.email => api.CanalRequisicaoTipoEnum.email,
        TipoCanal.telefone => api.CanalRequisicaoTipoEnum.telefone,
      };

  /// Converte a falha do transporte em falha do domínio.
  ///
  /// Sem resposta é [FalhaAutenticacao.semConexao] — o caso mais comum no
  /// público do Memora, que costuma estar em rede instável e precisa de um texto
  /// diferente de "algo deu errado".
  ResultadoAutenticacao _falhaDe(DioException excecao) {
    final Response<dynamic>? resposta = excecao.response;
    if (resposta == null) {
      return const AutenticacaoFalhou(FalhaAutenticacao.semConexao);
    }

    final Map<String, dynamic> corpo = switch (resposta.data) {
      final Map<String, dynamic> mapa => mapa,
      _ => const <String, dynamic>{},
    };

    final String codigo = switch (corpo['codigo']) {
      final String texto => texto,
      _ => '',
    };

    final int? esperar = switch (corpo['tentar_novamente_em_segundos']) {
      final int segundos => segundos,
      _ => null,
    };

    return switch (codigo) {
      'DADOS_INVALIDOS' =>
        const AutenticacaoFalhou(FalhaAutenticacao.dadosInvalidos),
      'CREDENCIAIS_INVALIDAS' =>
        const AutenticacaoFalhou(FalhaAutenticacao.credenciaisInvalidas),
      'SESSAO_EXPIRADA' =>
        const AutenticacaoFalhou(FalhaAutenticacao.credenciaisInvalidas),
      'MUITAS_TENTATIVAS' => AutenticacaoFalhou(
          FalhaAutenticacao.muitasTentativas,
          tentarNovamenteEmSegundos: esperar,
        ),
      // Codigo desconhecido cai aqui de proposito: codigo novo no servidor nao
      // pode virar comportamento silencioso no aplicativo.
      _ => const AutenticacaoFalhou(FalhaAutenticacao.inesperada),
    };
  }
}

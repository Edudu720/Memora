import '../domain/autenticacao.dart';

/// Implementação **provisória** que simula o servidor.
///
/// Existe para permitir construir e testar as telas antes de o backend estar
/// de pé. Será substituída por `RepositorioAutenticacaoApi`, sobre o cliente
/// gerado do contrato OpenAPI, quando os endpoints da fase 2 existirem.
///
/// **Não vai para produção.** A troca é de uma linha, porque as telas dependem
/// apenas de [RepositorioAutenticacao].
class RepositorioAutenticacaoSimulado implements RepositorioAutenticacao {
  /// Canais que fingimos já existir, para exercitar a FR-010.
  final Set<String> canaisJaCadastrados;

  /// Demora simulada, para a tela exercitar o estado de carregando.
  final Duration demora;

  /// Força uma falha específica, para testar os caminhos de erro.
  final FalhaAutenticacao? falhaForcada;

  /// Cria o repositório simulado.
  RepositorioAutenticacaoSimulado({
    Set<String>? canaisJaCadastrados,
    this.demora = const Duration(milliseconds: 700),
    this.falhaForcada,
  }) : canaisJaCadastrados = canaisJaCadastrados ?? <String>{};

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

    // Canal já cadastrado devolve o MESMO resultado de um cadastro novo.
    // Qualquer diferença aqui revelaria a existência da conta (FR-010).
    return AutenticacaoConcluida(
      PessoaAutenticada(
        id: 'simulado-${dados.canal.hashCode.abs()}',
        nomeTratamento: dados.nomeTratamento,
      ),
    );
  }
}

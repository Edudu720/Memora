import 'package:memora_api/memora_api.dart' as api;

import '../../features/assistente/data/repositorio_assistente_simulado.dart';
import '../../features/assistente/domain/assistente.dart';
import '../../features/autenticacao/data/repositorio_autenticacao_api.dart';
import '../../features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import '../../features/autenticacao/domain/autenticacao.dart';
import '../seguranca/cofre_de_credenciais.dart';
import 'ambiente.dart';

/// Monta as dependências do aplicativo, uma vez, na subida.
///
/// ## O único lugar que sabe se o servidor é de verdade
///
/// Antes disto, o `RepositorioAutenticacaoSimulado` era instanciado dentro da
/// `CasaDemonstracao` — ou seja, um widget decidia com quem o aplicativo
/// conversa. Trocar por um servidor real significava editar uma tela, e
/// significava que não havia como ter os dois modos ao mesmo tempo.
///
/// Aqui a escolha é uma só, feita a partir do [Ambiente], e as telas recebem
/// pronto o que vão usar. Nenhuma delas sabe qual dos dois recebeu — e é
/// exatamente por isso que os testes de widget continuam podendo passar um
/// simulado sem tocar em nada.
///
/// ## O que ainda não tem lado real
///
/// A **assistente** continua simulada mesmo com `MEMORA_SERVIDOR_REAL=true`.
/// Não é descuido: o `repositorio_assistente_api.dart` é a tarefa T036 da
/// feature 003, adiada porque o contrato da assistente ainda não foi fundido
/// com o da 001 — e, acima disso, porque **não há provedor de IA escolhido**
/// (R2). Um cliente HTTP apontando para um endpoint que nenhum modelo atende
/// não seria integração, seria fachada.
///
/// [avisoDeIntegracaoParcial] existe para que isso apareça no log de quem
/// rodar contra o servidor, em vez de virar uma surpresa na demonstração.
class Composicao {
  /// De onde o aplicativo fala com o servidor.
  final Ambiente ambiente;

  /// Autenticação: real quando há servidor, simulada quando não.
  final RepositorioAutenticacao autenticacao;

  /// A assistente. **Sempre simulada por ora** — ver o cabeçalho.
  final RepositorioAssistente assistente;

  /// Cria a composição já resolvida.
  const Composicao({
    required this.ambiente,
    required this.autenticacao,
    required this.assistente,
  });

  /// Resolve as dependências a partir do ambiente.
  ///
  /// O [cofre] entra por parâmetro porque ele é assíncrono de abrir e porque o
  /// teste precisa poder dar o dele — credencial em teste nunca deve encostar
  /// no armazenamento seguro do aparelho.
  factory Composicao.resolver({
    required Ambiente ambiente,
    required CofreDeCredenciais cofre,
  }) {
    ambiente.exigirTlsForaDeDepuracao();

    final RepositorioAutenticacao autenticacao = ambiente.usaServidorReal
        ? RepositorioAutenticacaoApi(
            cliente: api.MemoraApi(basePathOverride: ambiente.urlBase),
            cofre: cofre,
          )
        : RepositorioAutenticacaoSimulado();

    return Composicao(
      ambiente: ambiente,
      autenticacao: autenticacao,
      assistente: RepositorioAssistenteSimulado(),
    );
  }

  /// O que dizer a quem rodou contra o servidor e vai encontrar simulado no meio.
  ///
  /// `null` quando não há ressalva a fazer.
  String? get avisoDeIntegracaoParcial {
    if (!ambiente.usaServidorReal) {
      return null;
    }
    return 'Servidor real em ${ambiente.urlBase}. A ASSISTENTE continua '
        'simulada: a T036 espera o provedor de IA (R2). Autenticação é real.';
  }
}

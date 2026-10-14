import 'package:memora_api/memora_api.dart' as api;

import '../../features/assistente/data/repositorio_assistente_simulado.dart';
import '../../features/assistente/domain/assistente.dart';
import '../../features/autenticacao/data/repositorio_autenticacao_api.dart';
import '../../features/autenticacao/data/repositorio_autenticacao_simulado.dart';
import '../../features/autenticacao/domain/autenticacao.dart';
import '../seguranca/cofre_de_credenciais.dart';
import 'ambiente.dart';
import '../../features/assistente/data/conversa_local.dart';
import '../../features/assistente/data/catalogo_guardado.dart';
import '../../features/aprendizado/data/progresso_de_aprendizado.dart';
import '../../features/autenticacao/data/ultimo_acesso_local.dart';
import '../../features/apresentacao/data/apresentacao_vista.dart';
import '../../features/perfil/data/data_de_nascimento_local.dart';
import '../seguranca/limpeza_de_sessao.dart';

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

  /// O que a saída da conta tira do aparelho (FR-026, FR-048).
  final LimpezaDeSessao limpeza;

  /// Onde o Perfil guarda a data de nascimento, por conta (T123, FR-042c).
  ///
  /// É a mesma instância que a [limpeza] esquece no `esquecerTudo`.
  final ArmazenamentoDaDataDeNascimento? dataDeNascimento;

  /// Quais contas já viram a apresentação inicial (FR-013, T048).
  ///
  /// É a mesma instância que a [limpeza] esquece no `esquecerTudo`.
  final ApresentacaoVista? apresentacaoVista;

  /// O que a pessoa já aprendeu a fazer, só no aparelho (T062, FR-042a/b).
  ///
  /// É a mesma instância que a [limpeza] apaga em **toda** saída.
  final ProgressoDeAprendizado? progresso;

  /// Cria a composição já resolvida.
  const Composicao({
    required this.ambiente,
    required this.autenticacao,
    required this.assistente,
    required this.limpeza,
    this.dataDeNascimento,
    this.apresentacaoVista,
    this.progresso,
  });

  /// Resolve as dependências a partir do ambiente.
  ///
  /// O [cofre] entra por parâmetro porque ele é assíncrono de abrir e porque o
  /// teste precisa poder dar o dele — credencial em teste nunca deve encostar
  /// no armazenamento seguro do aparelho.
  factory Composicao.resolver({
    required Ambiente ambiente,
    required CofreDeCredenciais cofre,
    required UltimoAcesso ultimoAcesso,
    DataDeNascimentoDoAparelho? dataDeNascimento,
    ApresentacaoVistaDoAparelho? apresentacaoVista,
    ProgressoDeAprendizado? progresso,
    bool guardarCatalogo = false,
  }) {
    final DataDeNascimentoDoAparelho datas =
        dataDeNascimento ?? DataDeNascimentoEmMemoria();
    final ApresentacaoVistaDoAparelho vistas =
        apresentacaoVista ?? ApresentacaoVistaEmMemoria();
    final ProgressoDeAprendizado aprendizado =
        progresso ?? ProgressoDeAprendizado();
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
      // O catálogo guardado (FR-024a) envolve a consulta do catálogo e escreve
      // em disco, que teste de widget não alcança: fica desligado por padrão e
      // o `main.dart` o liga. Ele NÃO entra em `dadosLocais` — não é da pessoa.
      assistente: guardarCatalogo
          ? CatalogoGuardado(RepositorioAssistenteSimulado())
          : RepositorioAssistenteSimulado(),
      dataDeNascimento: datas,
      apresentacaoVista: vistas,
      progresso: aprendizado,
      // O cofre tambem e limpo pelo `encerrarSessao` do repositorio, e
      // precisa ser: a ordem exige que o token que autentica a chamada de
      // saida so va embora depois que ela volta. Limpar duas vezes nao custa
      // nada e mantem esta lista sendo a resposta completa para "o que a
      // saida leva" — que e o valor de existir um lugar so.
      //
      // A saida leva em TODA saida: a conversa. Leva so no `esquecerTudo`: o
      // identificador do ultimo acesso e a data de nascimento do Perfil
      // (todas as contas do aparelho) e a apresentacao vista (idem). Estes
      // dois NAO sao `DadoLocalDaPessoa`: a pessoa nao digita nem ve de novo a
      // cada entrada.
      limpeza: LimpezaDeSessao(
        cofre: cofre,
        ultimoAcesso: ultimoAcesso,
        // O progresso de aprendizado sai em TODA saída (FR-042b), como a
        // conversa: revela o que a pessoa ainda não sabe fazer.
        dadosLocais: <DadoLocalDaPessoa>[ConversaLocal(), aprendizado],
        dadosDoAparelho: <DadoLocalDoAparelho>[datas, vistas],
      ),
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

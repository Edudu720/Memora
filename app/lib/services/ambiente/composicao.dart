import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memora_api/memora_api.dart' as api;

import '../../features/assistente/data/aceite_do_aviso.dart';
import '../../features/assistente/data/chamada_com_renovacao.dart';
import '../../features/assistente/data/repositorio_assistente_api.dart';
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
import '../../features/cuidado/data/repositorios/repositorio_contato_emergencia_local.dart';
import '../../features/perfil/data/data_de_nascimento_local.dart';
import '../../features/perfil/data/foto_de_perfil_local.dart';
import '../seguranca/limpeza_de_sessao.dart';
import '../seguranca/sessao_perdida.dart';

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
/// ## Um aplicativo, uma escolha
///
/// Com servidor real, a **assistente também é real**: não existe aplicativo
/// com conta de verdade e assistente de mentira (spec 003, clarificação de
/// 2026-10-09). Quem decide entre a resposta simulada e o provedor de IA é só
/// o servidor (`MEMORA_ASSISTENTE_PROVEDOR`), nunca o aparelho.
///
/// O `MemoraApi` é **uma instância só**, dividida entre a autenticação e a
/// assistente: é nele que o token de acesso vai para o cabeçalho, e a
/// renovação em silêncio da assistente precisa renovar o token que a própria
/// autenticação usa.
class Composicao {
  /// De onde o aplicativo fala com o servidor.
  final Ambiente ambiente;

  /// Autenticação: real quando há servidor, simulada quando não.
  final RepositorioAutenticacao autenticacao;

  /// A assistente: real quando há servidor, simulada quando não.
  final RepositorioAssistente assistente;

  /// Se a pessoa já aceitou o aviso de privacidade da conversa (FR-051).
  ///
  /// É o **mesmo objeto** que a [limpeza] apaga na saída: criar um aqui e outro
  /// lá seria o aceite sobreviver à saída da conta sem ninguém perceber.
  final AceiteDoAviso aceiteDoAviso;

  /// O que a saída da conta tira do aparelho (FR-026, FR-048).
  final LimpezaDeSessao limpeza;

  /// Onde o Perfil guarda a data de nascimento, por conta (T123, FR-042c).
  ///
  /// É a mesma instância que a [limpeza] esquece no `esquecerTudo`.
  final ArmazenamentoDaDataDeNascimento? dataDeNascimento;

  /// Onde o Perfil guarda a foto ou avatar escolhido, por conta (FR-006, 011).
  ///
  /// É a mesma instância que a [limpeza] esquece no `esquecerTudo` (FR-009).
  final ArmazenamentoDeFotoDePerfil? fotoDePerfil;

  /// Quais contas já viram a apresentação inicial (FR-013, T048).
  ///
  /// É a mesma instância que a [limpeza] esquece no `esquecerTudo`.
  final ApresentacaoVista? apresentacaoVista;

  /// O que a pessoa já aprendeu a fazer, só no aparelho (T062, FR-042a/b).
  ///
  /// É a mesma instância que a [limpeza] apaga em **toda** saída.
  final ProgressoDeAprendizado? progresso;

  /// Avisa que a sessão caiu no meio do uso (T111).
  ///
  /// É o **mesmo objeto** que a assistente aciona e que o fluxo escuta:
  /// criar um para cada lado seria a sessão perdida sem ninguém ouvir.
  final SessaoPerdida sessaoPerdida;

  /// Cria a composição já resolvida.
  const Composicao({
    required this.ambiente,
    required this.autenticacao,
    required this.assistente,
    required this.aceiteDoAviso,
    required this.limpeza,
    this.dataDeNascimento,
    this.fotoDePerfil,
    this.apresentacaoVista,
    this.progresso,
    required this.sessaoPerdida,
  });

  /// Os prazos do transporte que fala com o servidor.
  ///
  /// O cliente gerado, sozinho, espera **3 s** pela resposta. No plano
  /// gratuito do Render (0,1 de CPU) um cadastro ou uma entrada levam de 2,6 a
  /// 20 s, porque o Argon2 de ~240 ms vira segundos e os hashes simultâneos
  /// esperam na fila (medido em 2026-10-27). Com 3 s o servidor respondia e a
  /// pessoa via "Não consegui falar com a internet". A conversa tem prazo
  /// próprio, maior, no `RepositorioAssistenteApi`.
  @visibleForTesting
  static BaseOptions opcoesDoTransporte(String urlBase) => BaseOptions(
    baseUrl: urlBase,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 15),
  );

  /// Resolve as dependências a partir do ambiente.
  ///
  /// O [cofre] entra por parâmetro porque ele é assíncrono de abrir e porque o
  /// teste precisa poder dar o dele — credencial em teste nunca deve encostar
  /// no armazenamento seguro do aparelho.
  factory Composicao.resolver({
    required Ambiente ambiente,
    required CofreDeCredenciais cofre,
    required UltimoAcesso ultimoAcesso,
    required AceiteDoAviso aceiteDoAviso,
    DataDeNascimentoDoAparelho? dataDeNascimento,
    FotoDePerfilDoAparelho? fotoDePerfil,
    ApresentacaoVistaDoAparelho? apresentacaoVista,
    ProgressoDeAprendizado? progresso,
    SharedPreferences? preferencias,
    bool guardarCatalogo = false,
    @visibleForTesting Dio? dioDeTeste,
  }) {
    final DataDeNascimentoDoAparelho datas =
        dataDeNascimento ?? DataDeNascimentoEmMemoria();
    final FotoDePerfilDoAparelho fotos =
        fotoDePerfil ?? FotoDePerfilEmMemoria();
    final ApresentacaoVistaDoAparelho vistas =
        apresentacaoVista ?? ApresentacaoVistaEmMemoria();
    final ProgressoDeAprendizado aprendizado =
        progresso ?? ProgressoDeAprendizado();
    ambiente.exigirTlsForaDeDepuracao();

    final SessaoPerdida sessaoPerdida = SessaoPerdida();
    final RepositorioAutenticacao autenticacao;
    final RepositorioAssistente assistente;

    if (ambiente.usaServidorReal) {
      // [dioDeTeste] existe para o teste trocar o transporte e provar a
      // ligação inteira (assistente → renovação → aviso) sem rede.
      final api.MemoraApi cliente = api.MemoraApi(
        dio: dioDeTeste ?? Dio(opcoesDoTransporte(ambiente.urlBase)),
      );
      final RepositorioAutenticacaoApi autenticacaoReal =
          RepositorioAutenticacaoApi(cliente: cliente, cofre: cofre);
      autenticacao = autenticacaoReal;
      assistente = RepositorioAssistenteApi(
        cliente: cliente,
        chamadas: ChamadaComRenovacao(
          cliente: cliente,
          cofre: cofre,
          renovar: autenticacaoReal.renovarSessao,
          sessaoPerdida: sessaoPerdida,
        ),
      );
    } else {
      autenticacao = RepositorioAutenticacaoSimulado(
        preferencias: preferencias,
      );
      assistente = RepositorioAssistenteSimulado();
    }

    return Composicao(
      ambiente: ambiente,
      autenticacao: autenticacao,
      // O catálogo guardado (FR-024a) envolve a consulta do catálogo e escreve
      // em disco, que teste de widget não alcança: fica desligado por padrão e
      // o `main.dart` o liga. Ele NÃO entra em `dadosLocais` — não é da pessoa.
      // Envolve a assistente escolhida acima, real ou simulada.
      assistente: guardarCatalogo ? CatalogoGuardado(assistente) : assistente,
      aceiteDoAviso: aceiteDoAviso,
      sessaoPerdida: sessaoPerdida,
      dataDeNascimento: datas,
      fotoDePerfil: fotos,
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
        // conversa: revela o que a pessoa ainda não sabe fazer. O aceite do
        // aviso de privacidade também (FR-051): é de uma pessoa, não do
        // aparelho.
        dadosLocais: <DadoLocalDaPessoa>[
          ConversaLocal(),
          aprendizado,
          aceiteDoAviso,
          RepositorioContatoEmergenciaLocal(preferencias),
        ],
        dadosDoAparelho: <DadoLocalDoAparelho>[datas, vistas, fotos],
      ),
    );
  }
}

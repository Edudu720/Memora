import '../../domain/entidades/atalho_aplicativo.dart';

/// Estado imutável da tela de atalhos diretos para aplicativos.
class EstadoTelaAtalhos {
  /// Indica se a busca no catálogo e a verificação de instalação estão em andamento.
  final bool carregando;

  /// Indica se houve falha ao carregar o catálogo oficial do servidor (`FR-006`).
  final bool falha;

  /// Lista de aplicativos cotidianos ativos no catálogo com seu status atual.
  final List<AtalhoAplicativo> aplicativos;

  /// Mensagem eventual de aviso operacional.
  final String? mensagemAviso;

  /// Cria o estado da tela de atalhos.
  const EstadoTelaAtalhos({
    this.carregando = true,
    this.falha = false,
    this.aplicativos = const <AtalhoAplicativo>[],
    this.mensagemAviso,
  });

  /// Quantidade de aplicativos comuns instalados no dispositivo.
  int get totalInstalados =>
      aplicativos.where((AtalhoAplicativo app) => app.instalado).length;

  /// Total de aplicativos comuns liberados pelo servidor.
  int get totalSuportados => aplicativos.length;
}

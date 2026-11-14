/// Textos em português simples da área de Cuidado e sensores IoT.
abstract final class TextosCuidado {
  /// Título da tela do dispositivo.
  static const String tituloDispositivo = 'Dispositivo de Cuidado';

  /// Estados da conexão com o aparelho/simulador.
  static const String statusConectado = 'Dispositivo Conectado';
  static const String statusConectando = 'Conectando ao dispositivo...';
  static const String statusDesconectado = 'Dispositivo Desconectado';

  /// Resumos curtos para badge e painel herói.
  static const String badgeMonitoramentoAtivo = 'Monitoramento ativo';
  static const String badgeAguardandoVinculo = 'Aguardando vínculo';
  static const String modoMqtt = 'Dispositivo ESP32 (MQTT)';
  static const String modoSimulador = 'Simulador';
  static const String resumoMonitorando =
      'Monitorando movimentação e batimentos em tempo real.';
  static const String resumoAguardando =
      'Aguardando conexão com os sensores.';

  /// Botões de vínculo.
  static const String botaoConectar = 'Conectar agora';
  static const String botaoDesconectar = 'Desconectar';

  /// Cartão de frequência cardíaca.
  static const String tituloFrequenciaCardiaca = 'Frequência Cardíaca';
  static const String unidadeBpm = 'BPM';
  static const String statusLeituraAtiva = 'Leitura ativa';
  static const String statusAguardandoSensor = 'Aguardando sensor';
  static const String bpmMedicaoAtiva = 'Batimentos medidos em tempo real.';
  static const String bpmAguardandoDedo =
      'Posicione o dedo no sensor para medir';

  /// Cartão de movimentação.
  static const String tituloEstadoMovimento = 'Estado de Movimento';
  static const String rotuloNivelMovimento = 'Nível de movimento';
  static const String badgeEmMovimento = 'Em movimento';
  static const String badgeEmRepouso = 'Em repouso';
  static const String movimentoEmAtividade = 'Pessoa em movimento normal';
  static const String movimentoEmRepouso = 'Sem agitação no momento.';

  /// Ações rápidas da tela de cuidado.
  static const String tituloAcoesRapidas = 'Ações rápidas';
  static const String tituloContatoEmergencia = 'Contato de Emergência';
  static const String semContatoExplicacao =
      'Nenhum contato cadastrado. Cadastre alguém para receber uma mensagem pré-pronta no WhatsApp caso sofra uma queda.';
  static const String pistaAlterarContato = 'Alterar contato';
  static const String pistaCadastrarContato = 'Cadastrar contato';

  static const String tituloAtalhoConexao = 'Vínculo dos sensores';
  static const String subtituloAtalhoConectar = 'Ativar leitura do aparelho';
  static const String subtituloAtalhoDesconectar =
      'Encerrar escuta no momento';

  static const String tituloAtalhoSimulador = 'Modo demonstração';
  static const String subtituloSimuladorAtivo = 'Simulador ativo no aparelho';
  static const String subtituloTrocarSimulador = 'Alternar para simulador';
  static const String pistaAtalhoSimulador = 'Usar Simulador';

  static const String tituloAtalhoTecnico = 'Ajustes do sensor ESP32';
  static const String subtituloAtalhoTecnico = 'Broker MQTT e testes de alerta';
  static const String pistaAbrirTecnico = 'Ver detalhes';
  static const String pistaFecharTecnico = 'Ocultar';

  /// Seção recolhível técnica.
  static const String tituloConexaoEsp32Testes = 'Conexão ESP32 & Testes';
  static const String subtituloDetalhesTecnicos =
      'Detalhes técnicos do aparelho';
  static const String botaoUsarSimulador = 'Usar Simulador';
  static const String botaoSimuladorAtivo = 'Simulador Ativo';
  static const String botaoEsp32Ativo = 'ESP32 Ativo';
  static const String botaoUsarEsp32 = 'Usar ESP32';
  static const String rotuloBrokerMqtt = 'Broker MQTT';
  static const String ajudaBrokerMqtt =
      'Endereço do broker (ex.: broker.hivemq.com)';
  static const String rotuloTopicoBase = 'Tópico Base';
  static const String ajudaTopicoBase =
      'Prefixo dos tópicos (ex.: memora/iot/demonstracao-01)';
  static const String botaoReconectarEsp32 = 'Reconectar ao ESP32';
  static const String botaoSimularQueda = 'Simular Queda de Teste';

  /// Tela de verificação de queda e cronômetro.
  static const String prefixoCronometroQueda =
      'Chamando contato de emergência em';
  static const String badgeContagemQueda = 'Confirmação de segurança';
  static const String apoioCronometroQueda =
      'Ao zerar, prepararemos o pedido de ajuda.';
  static const String badgeAtencaoQueda = 'Queda possível detectada';
  static const String tituloVerificacaoQueda = 'Você está bem?';
  static const String subtituloVerificacaoQueda =
      'O sensor detectou um movimento brusco que pode ser uma queda.';
  static const String botaoEstouBem = 'Estou bem';
  static const String botaoPrecisoDeAjuda = 'Preciso de ajuda';
  static const String avisoAntigolpeQueda =
      'Aviso de segurança: O Memora nunca solicita senhas, transferências bancárias ou PIX em alertas.';

  /// Diálogo de contato de emergência.
  static const String subtituloDialogoContato =
      'Pessoa de confiança que receberá uma mensagem pré-pronta no WhatsApp se você sofrer uma queda e não responder.';
  static const String rotuloNomeContato = 'Nome do contato';
  static const String ajudaNomeContato =
      'Como a pessoa se chama (ex.: Filha Mariana)';
  static const String rotuloTelefoneContato = 'Telefone com DDD';
  static const String ajudaTelefoneContato = 'Número com DDD (ex.: 19 98765-4321)';
  static const String rotuloParentescoContato = 'Parentesco ou relação';
  static const String ajudaParentescoContato =
      'Qual o vínculo (ex.: Filho, Cuidador, Vizinho)';
  static const String erroTelefoneContato =
      'Por favor, preencha o nome e um telefone com DDD (10 ou 11 números).';
  static const String botaoSalvarContato = 'Salvar contato';
  static const String botaoCancelarContato = 'Cancelar';
}

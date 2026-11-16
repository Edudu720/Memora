/// Textos em português simples da área de Cuidado e sensores IoT.
abstract final class TextosCuidado {
  /// Título da tela do dispositivo.
  static const String tituloDispositivo = 'Dispositivo de Cuidado';

  /// Estados da conexão com o aparelho/simulador.
  static const String statusConectado = 'Dispositivo Conectado';
  /// Texto exibido para status conectando.
  static const String statusConectando = 'Conectando ao dispositivo...';
  /// Texto exibido para status desconectado.
  static const String statusDesconectado = 'Dispositivo Desconectado';

  /// Resumos curtos para badge e painel herói.
  static const String badgeMonitoramentoAtivo = 'Monitoramento ativo';
  /// Texto exibido para badge aguardando vinculo.
  static const String badgeAguardandoVinculo = 'Aguardando vínculo';
  /// Texto exibido para modo mqtt.
  static const String modoMqtt = 'Dispositivo ESP32 (MQTT)';
  /// Texto exibido para modo simulador.
  static const String modoSimulador = 'Simulador';
  /// Texto exibido para resumo monitorando.
  static const String resumoMonitorando =
      'Monitorando movimentação e batimentos em tempo real.';
  /// Texto exibido para resumo aguardando.
  static const String resumoAguardando =
      'Aguardando conexão com os sensores.';

  /// Botões de vínculo.
  static const String botaoConectar = 'Conectar agora';
  /// Texto exibido para botao desconectar.
  static const String botaoDesconectar = 'Desconectar';

  /// Cartão de frequência cardíaca.
  static const String tituloFrequenciaCardiaca = 'Frequência Cardíaca';
  /// Texto exibido para unidade bpm.
  static const String unidadeBpm = 'BPM';
  /// Texto exibido para status leitura ativa.
  static const String statusLeituraAtiva = 'Leitura ativa';
  /// Texto exibido para status aguardando sensor.
  static const String statusAguardandoSensor = 'Aguardando sensor';
  /// Texto exibido para bpm medicao ativa.
  static const String bpmMedicaoAtiva = 'Batimentos medidos em tempo real.';
  /// Texto exibido para bpm aguardando dedo.
  static const String bpmAguardandoDedo =
      'Posicione o dedo no sensor para medir';

  /// Cartão de movimentação.
  static const String tituloEstadoMovimento = 'Estado de Movimento';
  /// Texto exibido para rotulo nivel movimento.
  static const String rotuloNivelMovimento = 'Nível de movimento';
  /// Texto exibido para badge em movimento.
  static const String badgeEmMovimento = 'Em movimento';
  /// Texto exibido para badge em repouso.
  static const String badgeEmRepouso = 'Em repouso';
  /// Texto exibido para movimento em atividade.
  static const String movimentoEmAtividade = 'Pessoa em movimento normal';
  /// Texto exibido para movimento em repouso.
  static const String movimentoEmRepouso = 'Sem agitação no momento.';

  /// Ações rápidas da tela de cuidado.
  static const String tituloAcoesRapidas = 'Ações rápidas';
  /// Texto exibido para titulo contato emergencia.
  static const String tituloContatoEmergencia = 'Contato de Emergência';
  /// Texto exibido para sem contato explicacao.
  static const String semContatoExplicacao =
      'Nenhum contato cadastrado. Cadastre alguém para receber uma mensagem pré-pronta no WhatsApp caso sofra uma queda.';
  /// Texto exibido para pista alterar contato.
  static const String pistaAlterarContato = 'Alterar contato';
  /// Texto exibido para pista cadastrar contato.
  static const String pistaCadastrarContato = 'Cadastrar contato';

  /// Texto exibido para titulo atalho conexao.
  static const String tituloAtalhoConexao = 'Vínculo dos sensores';
  /// Texto exibido para subtitulo atalho conectar.
  static const String subtituloAtalhoConectar = 'Ativar leitura do aparelho';
  /// Texto exibido para subtitulo atalho desconectar.
  static const String subtituloAtalhoDesconectar =
      'Encerrar escuta no momento';

  /// Texto exibido para titulo atalho simulador.
  static const String tituloAtalhoSimulador = 'Modo demonstração';
  /// Texto exibido para subtitulo simulador ativo.
  static const String subtituloSimuladorAtivo = 'Simulador ativo no aparelho';
  /// Texto exibido para subtitulo trocar simulador.
  static const String subtituloTrocarSimulador = 'Alternar para simulador';
  /// Texto exibido para pista atalho simulador.
  static const String pistaAtalhoSimulador = 'Usar Simulador';

  /// Texto exibido para titulo atalho tecnico.
  static const String tituloAtalhoTecnico = 'Ajustes do sensor ESP32';
  /// Texto exibido para subtitulo atalho tecnico.
  static const String subtituloAtalhoTecnico = 'Broker MQTT e testes de alerta';
  /// Texto exibido para pista abrir tecnico.
  static const String pistaAbrirTecnico = 'Ver detalhes';
  /// Texto exibido para pista fechar tecnico.
  static const String pistaFecharTecnico = 'Ocultar';

  /// Seção recolhível técnica.
  static const String tituloConexaoEsp32Testes = 'Conexão ESP32 & Testes';
  /// Texto exibido para subtitulo detalhes tecnicos.
  static const String subtituloDetalhesTecnicos =
      'Detalhes técnicos do aparelho';
  /// Texto exibido para botao usar simulador.
  static const String botaoUsarSimulador = 'Usar Simulador';
  /// Texto exibido para botao simulador ativo.
  static const String botaoSimuladorAtivo = 'Simulador Ativo';
  /// Texto exibido para botao esp32 ativo.
  static const String botaoEsp32Ativo = 'ESP32 Ativo';
  /// Texto exibido para botao usar esp32.
  static const String botaoUsarEsp32 = 'Usar ESP32';
  /// Texto exibido para rotulo broker mqtt.
  static const String rotuloBrokerMqtt = 'Broker MQTT';
  /// Texto exibido para ajuda broker mqtt.
  static const String ajudaBrokerMqtt =
      'Endereço do broker (ex.: broker.hivemq.com)';
  /// Texto exibido para rotulo topico base.
  static const String rotuloTopicoBase = 'Tópico Base';
  /// Texto exibido para ajuda topico base.
  static const String ajudaTopicoBase =
      'Prefixo dos tópicos (ex.: memora/iot/demonstracao-01)';
  /// Texto exibido para botao reconectar esp32.
  static const String botaoReconectarEsp32 = 'Reconectar ao ESP32';
  /// Texto exibido para botao simular queda.
  static const String botaoSimularQueda = 'Simular Queda de Teste';

  /// Tela de verificação de queda e cronômetro.
  static const String prefixoCronometroQueda =
      'Chamando contato de emergência em';
  /// Texto exibido para badge contagem queda.
  static const String badgeContagemQueda = 'Confirmação de segurança';
  /// Texto exibido para apoio cronometro queda.
  static const String apoioCronometroQueda =
      'Ao zerar, prepararemos o pedido de ajuda.';
  /// Texto exibido para badge atencao queda.
  static const String badgeAtencaoQueda = 'Queda possível detectada';
  /// Texto exibido para titulo verificacao queda.
  static const String tituloVerificacaoQueda = 'Você está bem?';
  /// Texto exibido para subtitulo verificacao queda.
  static const String subtituloVerificacaoQueda =
      'O sensor detectou um movimento brusco que pode ser uma queda.';
  /// Texto exibido para botao estou bem.
  static const String botaoEstouBem = 'Estou bem';
  /// Texto exibido para botao preciso de ajuda.
  static const String botaoPrecisoDeAjuda = 'Preciso de ajuda';
  /// Texto exibido para aviso antigolpe queda.
  static const String avisoAntigolpeQueda =
      'Aviso de segurança: O Memora nunca solicita senhas, transferências bancárias ou PIX em alertas.';

  /// Diálogo de contato de emergência.
  static const String subtituloDialogoContato =
      'Pessoa de confiança que receberá uma mensagem pré-pronta no WhatsApp se você sofrer uma queda e não responder.';
  /// Texto exibido para rotulo nome contato.
  static const String rotuloNomeContato = 'Nome do contato';
  /// Texto exibido para ajuda nome contato.
  static const String ajudaNomeContato =
      'Como a pessoa se chama (ex.: Filha Mariana)';
  /// Texto exibido para rotulo telefone contato.
  static const String rotuloTelefoneContato = 'Telefone com DDD';
  /// Texto exibido para ajuda telefone contato.
  static const String ajudaTelefoneContato = 'Número com DDD (ex.: 19 98765-4321)';
  /// Texto exibido para rotulo parentesco contato.
  static const String rotuloParentescoContato = 'Parentesco ou relação';
  /// Texto exibido para ajuda parentesco contato.
  static const String ajudaParentescoContato =
      'Qual o vínculo (ex.: Filho, Cuidador, Vizinho)';
  /// Texto exibido para erro telefone contato.
  static const String erroTelefoneContato =
      'Por favor, preencha o nome e um telefone com DDD (10 ou 11 números).';
  /// Texto exibido para botao salvar contato.
  static const String botaoSalvarContato = 'Salvar contato';
  /// Texto exibido para botao cancelar contato.
  static const String botaoCancelarContato = 'Cancelar';
}

/// Status de conectividade do aplicativo com o dispositivo de cuidado.
enum StatusConexaoIot {
  /// Sem conexão ativa com o dispositivo.
  desconectado,

  /// Tentando estabelecer conexão com o dispositivo.
  conectando,

  /// Conectado e recebendo telemetria em tempo real.
  conectado,
}

/// Estado do fluxo de verificação de queda.
enum StatusConfirmacaoQueda {
  /// Alerta ativo, aguardando resposta do idoso no cronômetro.
  aguardandoConfirmacao,

  /// O idoso tocou em "Estou bem". Alarme cessado.
  canceladoPeloUsuario,

  /// O idoso tocou em "Preciso de ajuda". Socorro imediato.
  socorroAcionado,

  /// O tempo de 45 segundos expirou sem resposta. Socorro automático.
  tempoExpirado,
}

/// Modo de operação do provedor de telemetria.
enum ModoOperacaoIot {
  /// Geração simulada em memória para demonstração e testes offline.
  simulado,

  /// Conexão em tempo real com broker MQTT para o ESP32 físico.
  mqtt,
}

/// Enums de domínio para o módulo de cuidado e integração IoT.

/// Status de conectividade do aplicativo com o dispositivo de cuidado.
enum StatusConexaoIot {
  desconectado,
  conectando,
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

  /// Conexão em tempo real com broker MQTT (Wokwi ou ESP32 físico).
  mqtt,
}


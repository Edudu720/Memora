import 'package:flutter/foundation.dart';

/// Contato de emergência cadastrado para receber alertas em caso de queda sem confirmação.
@immutable
class ContatoEmergencia {
  /// Cria um contato de emergência.
  const ContatoEmergencia({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.parentesco,
    this.email = '',
    this.ativo = true,
  });

  /// Reconstrói um [ContatoEmergencia] a partir de um mapa JSON.
  factory ContatoEmergencia.fromJson(Map<String, dynamic> json) {
    return ContatoEmergencia(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      telefone: json['telefone'] as String? ?? '',
      parentesco: json['parentesco'] as String? ?? '',
      email: json['email'] as String? ?? '',
      ativo: json['ativo'] as bool? ?? true,
    );
  }

  /// Identificador único do contato.
  final String id;

  /// Nome da pessoa de confiança.
  final String nome;

  /// Telefone com DDD.
  final String telefone;

  /// Relação ou parentesco com a pessoa idosa.
  final String parentesco;

  /// E-mail opcional para notificações remotas do botão SOS em produção.
  final String email;

  /// Indica se o contato está ativo para acionamento.
  final bool ativo;

  /// Retorna o telefone limpo (somente números, normalizando DDI +55 se presente).
  String get telefoneNumeros {
    String limpo = telefone.replaceAll(RegExp(r'\D'), '');
    if (limpo.startsWith('55') && (limpo.length == 12 || limpo.length == 13)) {
      limpo = limpo.substring(2);
    }
    return limpo;
  }

  /// Retorna o telefone formatado com o DDI 55 (Brasil) para links de WhatsApp.
  String get telefoneWhatsapp {
    final String limpo = telefoneNumeros;
    if (limpo.length == 10 || limpo.length == 11) {
      return '55$limpo';
    }
    return limpo;
  }

  /// Validação: precisa ter nome preenchido e telefone com DDD (10 ou 11 dígitos).
  bool get ehValido {
    final String limpo = telefoneNumeros;
    return nome.trim().isNotEmpty && (limpo.length == 10 || limpo.length == 11);
  }

  /// Indica se o e-mail opcional tem formato válido para entrega remota.
  bool get temEmailValido {
    final String limpo = email.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(limpo);
  }

  /// Aceita campo em branco (opcional) ou e-mail válido.
  bool get emailValidoOuVazio => email.trim().isEmpty || temEmailValido;

  /// Melhor destino para envio via servidor: prioriza e-mail e usa telefone
  /// como fallback quando o e-mail ainda não foi cadastrado.
  String get destinoNotificacaoRemota =>
      temEmailValido ? email.trim() : telefone.trim();

  /// Converte este contato para mapa JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nome': nome,
      'telefone': telefone,
      'parentesco': parentesco,
      'email': email,
      'ativo': ativo,
    };
  }

  /// Cria uma cópia deste contato com os campos informados alterados.
  ContatoEmergencia copyWith({
    String? id,
    String? nome,
    String? telefone,
    String? parentesco,
    String? email,
    bool? ativo,
  }) {
    return ContatoEmergencia(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      parentesco: parentesco ?? this.parentesco,
      email: email ?? this.email,
      ativo: ativo ?? this.ativo,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContatoEmergencia &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nome == other.nome &&
          telefone == other.telefone &&
          parentesco == other.parentesco &&
          email == other.email &&
          ativo == other.ativo;

  @override
  int get hashCode => Object.hash(
        id,
        nome,
        telefone,
        parentesco,
        email,
        ativo,
      );
}
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
    this.ativo = true,
  });

  /// Reconstrói um [ContatoEmergencia] a partir de um mapa JSON.
  factory ContatoEmergencia.fromJson(Map<String, dynamic> json) {
    return ContatoEmergencia(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      telefone: json['telefone'] as String? ?? '',
      parentesco: json['parentesco'] as String? ?? '',
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

  /// Validação: precisa ter nome preenchido e telefone com DDD (10 ou 11 dígitos).
  bool get ehValido {
    final String limpo = telefoneNumeros;
    return nome.trim().isNotEmpty && (limpo.length == 10 || limpo.length == 11);
  }

  /// Converte este contato para mapa JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nome': nome,
      'telefone': telefone,
      'parentesco': parentesco,
      'ativo': ativo,
    };
  }

  /// Cria uma cópia deste contato com os campos informados alterados.
  ContatoEmergencia copyWith({
    String? id,
    String? nome,
    String? telefone,
    String? parentesco,
    bool? ativo,
  }) {
    return ContatoEmergencia(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      parentesco: parentesco ?? this.parentesco,
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
          ativo == other.ativo;

  @override
  int get hashCode => Object.hash(
        id,
        nome,
        telefone,
        parentesco,
        ativo,
      );
}
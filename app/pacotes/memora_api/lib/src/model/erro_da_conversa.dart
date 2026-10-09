//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'erro_da_conversa.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ErroDaConversa {
  /// Returns a new [ErroDaConversa] instance.
  ErroDaConversa({

    required  this.codigo,

    required  this.mensagem,
  });

      /// `LIMITE_DE_CONVERSAS` — teto diário da conta (FR-053); volta no dia seguinte, não se oferece tentar de novo. `ASSISTENTE_INDISPONIVEL` — o provedor está fora do ar, sem cota ou não respondeu no prazo (FR-057); oferece tentar de novo mais tarde. `ERRO_INESPERADO` — defeito nosso; o detalhe fica no log. 
  @JsonKey(
    
    name: r'codigo',
    required: true,
    includeIfNull: false,
  )


  final ErroDaConversaCodigoEnum codigo;



      /// Texto já pronto para a pessoa, na voz da Memora.
  @JsonKey(
    
    name: r'mensagem',
    required: true,
    includeIfNull: false,
  )


  final String mensagem;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ErroDaConversa &&
      other.codigo == codigo &&
      other.mensagem == mensagem;

    @override
    int get hashCode =>
        codigo.hashCode +
        mensagem.hashCode;

  factory ErroDaConversa.fromJson(Map<String, dynamic> json) => _$ErroDaConversaFromJson(json);

  Map<String, dynamic> toJson() => _$ErroDaConversaToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// `LIMITE_DE_CONVERSAS` — teto diário da conta (FR-053); volta no dia seguinte, não se oferece tentar de novo. `ASSISTENTE_INDISPONIVEL` — o provedor está fora do ar, sem cota ou não respondeu no prazo (FR-057); oferece tentar de novo mais tarde. `ERRO_INESPERADO` — defeito nosso; o detalhe fica no log. 
enum ErroDaConversaCodigoEnum {
    /// `LIMITE_DE_CONVERSAS` — teto diário da conta (FR-053); volta no dia seguinte, não se oferece tentar de novo. `ASSISTENTE_INDISPONIVEL` — o provedor está fora do ar, sem cota ou não respondeu no prazo (FR-057); oferece tentar de novo mais tarde. `ERRO_INESPERADO` — defeito nosso; o detalhe fica no log. 
@JsonValue(r'LIMITE_DE_CONVERSAS')
LIMITE_DE_CONVERSAS(r'LIMITE_DE_CONVERSAS'),
    /// `LIMITE_DE_CONVERSAS` — teto diário da conta (FR-053); volta no dia seguinte, não se oferece tentar de novo. `ASSISTENTE_INDISPONIVEL` — o provedor está fora do ar, sem cota ou não respondeu no prazo (FR-057); oferece tentar de novo mais tarde. `ERRO_INESPERADO` — defeito nosso; o detalhe fica no log. 
@JsonValue(r'ASSISTENTE_INDISPONIVEL')
ASSISTENTE_INDISPONIVEL(r'ASSISTENTE_INDISPONIVEL'),
    /// `LIMITE_DE_CONVERSAS` — teto diário da conta (FR-053); volta no dia seguinte, não se oferece tentar de novo. `ASSISTENTE_INDISPONIVEL` — o provedor está fora do ar, sem cota ou não respondeu no prazo (FR-057); oferece tentar de novo mais tarde. `ERRO_INESPERADO` — defeito nosso; o detalhe fica no log. 
@JsonValue(r'ERRO_INESPERADO')
ERRO_INESPERADO(r'ERRO_INESPERADO');

const ErroDaConversaCodigoEnum(this.value);

final String value;

@override
String toString() => value;
}



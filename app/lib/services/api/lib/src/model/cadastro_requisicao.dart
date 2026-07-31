//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:memora_api/src/model/canal_requisicao.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cadastro_requisicao.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CadastroRequisicao {
  /// Returns a new [CadastroRequisicao] instance.
  CadastroRequisicao({

    required  this.nomeTratamento,

    required  this.canal,

    required  this.senha,

     this.modoAssistido = false,

     this.aparelhoDescricao,
  });

      /// Como a pessoa quer ser chamada. **Nunca é credencial** (FR-003)
  @JsonKey(
    
    name: r'nome_tratamento',
    required: true,
    includeIfNull: false,
  )


  final String nomeTratamento;



  @JsonKey(
    
    name: r'canal',
    required: true,
    includeIfNull: false,
  )


  final CanalRequisicao canal;



      /// A política prioriza **comprimento** sobre complexidade simbólica (FR-042). Não exigimos maiúscula, número ou símbolo — exigências assim levam pessoas idosas a anotar a senha em papel, o que piora a segurança real.  Senhas notoriamente comprometidas são recusadas. 
  @JsonKey(
    
    name: r'senha',
    required: true,
    includeIfNull: false,
  )


  final String senha;



      /// Indica que houve acompanhante no cadastro (D3). Quando `true`, o servidor **exige canal com posse já confirmada** antes de concluir (FR-062).  Não cria vínculo, permissão ou acesso do acompanhante (FR-064) — é apenas um sinal de fluxo. 
  @JsonKey(
    defaultValue: false,
    name: r'modo_assistido',
    required: false,
    includeIfNull: false,
  )


  final bool? modoAssistido;



  @JsonKey(
    
    name: r'aparelho_descricao',
    required: false,
    includeIfNull: false,
  )


  final String? aparelhoDescricao;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CadastroRequisicao &&
      other.nomeTratamento == nomeTratamento &&
      other.canal == canal &&
      other.senha == senha &&
      other.modoAssistido == modoAssistido &&
      other.aparelhoDescricao == aparelhoDescricao;

    @override
    int get hashCode =>
        nomeTratamento.hashCode +
        canal.hashCode +
        senha.hashCode +
        modoAssistido.hashCode +
        aparelhoDescricao.hashCode;

  factory CadastroRequisicao.fromJson(Map<String, dynamic> json) => _$CadastroRequisicaoFromJson(json);

  Map<String, dynamic> toJson() => _$CadastroRequisicaoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


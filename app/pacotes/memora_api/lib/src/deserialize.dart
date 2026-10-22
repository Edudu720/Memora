import 'package:memora_api/src/model/acao_autorizada.dart';
import 'package:memora_api/src/model/acao_registrada.dart';
import 'package:memora_api/src/model/assistente_acao_post_request.dart';
import 'package:memora_api/src/model/assistente_catalogo_get200_response.dart';
import 'package:memora_api/src/model/assistente_conversa_post_request.dart';
import 'package:memora_api/src/model/assistente_registro_get200_response.dart';
import 'package:memora_api/src/model/auth_recuperacao_confirmar_post_request.dart';
import 'package:memora_api/src/model/auth_recuperacao_solicitar_post202_response.dart';
import 'package:memora_api/src/model/auth_recuperacao_solicitar_post_request.dart';
import 'package:memora_api/src/model/auth_sessao_renovar_post_request.dart';
import 'package:memora_api/src/model/auth_social_provedor_post_request.dart';
import 'package:memora_api/src/model/cadastro_requisicao.dart';
import 'package:memora_api/src/model/canais_canal_id_verificar_post_request.dart';
import 'package:memora_api/src/model/canal.dart';
import 'package:memora_api/src/model/canal_requisicao.dart';
import 'package:memora_api/src/model/entrar_requisicao.dart';
import 'package:memora_api/src/model/erro.dart';
import 'package:memora_api/src/model/erro_da_conversa.dart';
import 'package:memora_api/src/model/mensagem.dart';
import 'package:memora_api/src/model/pessoa_resposta.dart';
import 'package:memora_api/src/model/servico.dart';
import 'package:memora_api/src/model/sessao_resposta.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

  ReturnType deserialize<ReturnType, BaseType>(dynamic value, String targetType, {bool growable= true}) {
      switch (targetType) {
        case 'String':
          return '$value' as ReturnType;
        case 'int':
          return (value is int ? value : int.parse('$value')) as ReturnType;
        case 'bool':
          if (value is bool) {
            return value as ReturnType;
          }
          final valueString = '$value'.toLowerCase();
          return (valueString == 'true' || valueString == '1') as ReturnType;
        case 'double':
          return (value is double ? value : double.parse('$value')) as ReturnType;
        case 'AcaoAutorizada':
          return AcaoAutorizada.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AcaoRegistrada':
          return AcaoRegistrada.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AssistenteAcaoPostRequest':
          return AssistenteAcaoPostRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AssistenteCatalogoGet200Response':
          return AssistenteCatalogoGet200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AssistenteConversaPostRequest':
          return AssistenteConversaPostRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AssistenteRegistroGet200Response':
          return AssistenteRegistroGet200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AuthRecuperacaoConfirmarPostRequest':
          return AuthRecuperacaoConfirmarPostRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AuthRecuperacaoSolicitarPost202Response':
          return AuthRecuperacaoSolicitarPost202Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AuthRecuperacaoSolicitarPostRequest':
          return AuthRecuperacaoSolicitarPostRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AuthSessaoRenovarPostRequest':
          return AuthSessaoRenovarPostRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AuthSocialProvedorPostRequest':
          return AuthSocialProvedorPostRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CadastroRequisicao':
          return CadastroRequisicao.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CanaisCanalIdVerificarPostRequest':
          return CanaisCanalIdVerificarPostRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Canal':
          return Canal.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CanalRequisicao':
          return CanalRequisicao.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'EntrarRequisicao':
          return EntrarRequisicao.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Erro':
          return Erro.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ErroDaConversa':
          return ErroDaConversa.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Mensagem':
          return Mensagem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PessoaResposta':
          return PessoaResposta.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Servico':
          return Servico.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SessaoResposta':
          return SessaoResposta.fromJson(value as Map<String, dynamic>) as ReturnType;
        default:
          RegExpMatch? match;

          if (value is List && (match = _regList.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toList(growable: growable) as ReturnType;
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toSet() as ReturnType;
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
            targetType = match![1]!.trim(); // ignore: parameter_assignments
            return Map<String, BaseType>.fromIterables(
              value.keys as Iterable<String>,
              value.values.map((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable)),
            ) as ReturnType;
          }
          break;
    }
    throw Exception('Cannot deserialize');
  }
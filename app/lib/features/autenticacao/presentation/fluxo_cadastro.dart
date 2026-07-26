import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../domain/autenticacao.dart';
import 'controladores/controlador_cadastro.dart';
import 'telas/tela_boas_vindas.dart';
import 'telas/tela_cadastro.dart';

/// Liga as telas da User Story 1: boas-vindas, cadastro e entrada.
///
/// Ao concluir o cadastro a pessoa **já está autenticada** (FR-009) — não há
/// passagem pelo login.
class FluxoCadastro extends StatefulWidget {
  /// Repositório usado para criar a conta.
  ///
  /// Recebe a implementação por parâmetro para que a tela possa ser testada
  /// e demonstrada sem depender de o backend estar de pé.
  final RepositorioAutenticacao repositorio;

  /// Cria o fluxo de cadastro.
  const FluxoCadastro({required this.repositorio, super.key});

  @override
  State<FluxoCadastro> createState() => _FluxoCadastroState();
}

enum _Etapa { boasVindas, cadastro, dentro }

class _FluxoCadastroState extends State<FluxoCadastro> {
  late final ControladorCadastro _controlador =
      ControladorCadastro(widget.repositorio);

  _Etapa _etapa = _Etapa.boasVindas;
  PessoaAutenticada? _pessoa;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_etapa) {
      _Etapa.boasVindas => TelaBoasVindas(
          aoComecar: () => setState(() => _etapa = _Etapa.cadastro),
        ),
      _Etapa.cadastro => TelaCadastro(
          controlador: _controlador,
          aoVoltar: () => setState(() => _etapa = _Etapa.boasVindas),
          aoConcluir: (PessoaAutenticada pessoa) => setState(() {
            _pessoa = pessoa;
            _etapa = _Etapa.dentro;
          }),
        ),
      _Etapa.dentro => _TelaDentro(
          nome: _pessoa?.nomeTratamento ?? '',
          aoRecomecar: () => setState(() => _etapa = _Etapa.boasVindas),
        ),
    };
  }
}

/// Confirmação de que a pessoa entrou — provisória até o Hub existir.
class _TelaDentro extends StatelessWidget {
  final String nome;
  final VoidCallback aoRecomecar;

  const _TelaDentro({required this.nome, required this.aoRecomecar});

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MemoraEspacamento.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Icon(Icons.check_circle, size: 72, color: cores.sucesso),
              const SizedBox(height: MemoraEspacamento.xl),
              TextoMemora.tituloTela(
                'Prontinho, $nome!',
                alinhamento: TextAlign.center,
              ),
              const SizedBox(height: MemoraEspacamento.md),
              const TextoMemora(
                'Sua conta está criada e você já está dentro. '
                'Não precisou entrar de novo 😊',
                alinhamento: TextAlign.center,
              ),
              const SizedBox(height: MemoraEspacamento.xxxl),
              BotaoSecundario(
                rotulo: 'Ver de novo desde o começo',
                aoTocar: aoRecomecar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

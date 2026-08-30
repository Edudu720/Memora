import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_autenticacao.dart';

/// Conduz a pessoa a entrar sozinha, ao final do cadastro assistido
/// (T064, FR-063).
///
/// ## Por que fazer a pessoa entrar de novo logo após criar a conta
///
/// Parece contradizer a FR-009, que proíbe mandar ao login depois do cadastro —
/// e contradiria, se fosse o cadastro comum. Aqui é diferente: o cadastro foi
/// feito com outra pessoa segurando o aparelho, e a conta que ela vai usar
/// sozinha, amanhã, é a que ela ainda não abriu nenhuma vez.
///
/// A FR-063 chama isso de **confirmação de autonomia**: entrar uma vez, agora,
/// com quem ajudou ainda por perto, é o que transforma "criaram uma conta para
/// mim" em "eu tenho uma conta". Se ela não conseguir, o momento de descobrir
/// isso é este — não daqui a uma semana, sozinha.
///
/// ## O que esta tela deliberadamente não faz
///
/// Não oferece atalho para continuar sem entrar. A saída existe, e é o botão
/// físico de voltar do aparelho; oferecer um "pular" aqui converteria a
/// confirmação de autonomia em formalidade, e ela é o objetivo da User Story
/// inteira.
class TelaPrimeiraEntrada extends StatelessWidget {
  /// Chave do botão que leva ao login.
  static const Key chaveEntrar = Key('primeira_entrada.entrar');

  /// Como a pessoa quer ser chamada.
  final String nome;

  /// Chamada quando a pessoa decide entrar sozinha.
  final VoidCallback aoEntrarSozinha;

  /// Cria a tela de primeira entrada.
  const TelaPrimeiraEntrada({
    required this.nome,
    required this.aoEntrarSozinha,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MemoraEspacamento.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: MemoraEspacamento.xxl),
              Icon(Icons.emoji_events_outlined, size: 72, color: cores.sucesso),
              const SizedBox(height: MemoraEspacamento.xl),
              TextoMemora.tituloTela(
                nome.isEmpty
                    ? TextosAutenticacao.tituloPrimeiraEntrada
                    : '${TextosAutenticacao.tituloPrimeiraEntrada}, $nome',
                alinhamento: TextAlign.center,
              ),
              const SizedBox(height: MemoraEspacamento.lg),
              const TextoMemora(
                TextosAutenticacao.convitePrimeiraEntrada,
                alinhamento: TextAlign.center,
              ),
              const SizedBox(height: MemoraEspacamento.xxxl),
              BotaoPrimario(
                key: chaveEntrar,
                rotulo: TextosAutenticacao.botaoEntrarSozinha,
                icone: Icons.login,
                aoTocar: aoEntrarSozinha,
              ),
              const SizedBox(height: MemoraEspacamento.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

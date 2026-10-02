import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_casca.dart';
import '../../domain/hub.dart';

/// Todas as partes do Memora, numa tela (T038, FR-016 da feature 004).
///
/// ## A tela que o Início abre
///
/// O Hub não é mais a raiz de nada: o Início cumprimenta e leva ao que a
/// pessoa mais faz, e este é o "ver tudo". Por isso ele tem **"Voltar"** — a
/// raiz de um destino é que não tem —, no mesmo canto de todas as outras
/// telas (FR-001). O "Sair" que morava aqui foi para Ajustes → Conta
/// (FR-019): quem queria o Hub para escolher uma parte do aplicativo encontrava
/// ao lado dela a porta de saída, e um toque errado custava a sessão.
///
/// ## Ela mostra o que recebe, e só
///
/// A FR-003 da 003 e a FR-018 desta feature exigem que porta sem destino não
/// apareça. A tela não decide isso: ela exibe a lista que lhe passam, e
/// [PortaDoHub] torna o destino obrigatório. Quem sabe o que existe é quem
/// monta o fluxo.
///
/// ## Cabe sem rolar (FR-017)
///
/// Em 100% e 150% de ampliação, no menor aparelho suportado, nenhuma porta
/// fica para baixo da dobra. Em 200% rolar é aceitável — a lista rola, e o
/// começo dela já mostra que existe mais.
///
/// ## Porta é ação
///
/// Cada porta é um `CartaoDePorta`: pílula preenchida com desenho, nome e uma
/// linha do que há do outro lado. Cartão comum, o `Cartao`, é informação e
/// deliberadamente não aceita toque (FR-012 da 002).
class TelaHub extends StatelessWidget {
  /// Chave da lista de portas, para os testes.
  static const Key chaveLista = Key('hub.lista');

  /// Chave do estado vazio, para os testes.
  static const Key chaveVazio = Key('hub.vazio');

  /// Chave de uma porta, pelo rótulo.
  static Key chaveDaPorta(String rotulo) => Key('hub.porta.$rotulo');

  /// As portas construídas. Ver a nota sobre a FR-003.
  final List<PortaDoHub> portas;

  /// Volta ao Início.
  final VoidCallback aoVoltar;

  /// Cria o Hub.
  const TelaHub({required this.portas, required this.aoVoltar, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.memora.cores.fundo,
      body: SingleChildScrollView(
        key: chaveLista,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CabecalhoDeTela(titulo: TextosCasca.tituloHub, aoVoltar: aoVoltar),
            if (portas.isEmpty)
              const EstadoVazio(
                key: chaveVazio,
                titulo: TextosCasca.hubVazioTitulo,
                explicacao: TextosCasca.hubVazioExplicacao,
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MemoraEspacamento.lg,
                  0,
                  MemoraEspacamento.lg,
                  MemoraEspacamento.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final PortaDoHub porta in portas) ...<Widget>[
                      CartaoDePorta(
                        key: chaveDaPorta(porta.rotulo),
                        nome: porta.rotulo,
                        explicacao: porta.descricao,
                        ilustracao: porta.ilustracao,
                        aoAbrir: porta.aoAbrir,
                        principal: porta.principal,
                      ),
                      if (porta != portas.last)
                        const SizedBox(height: MemoraEspacamento.md),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

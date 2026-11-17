import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/textos_perfil.dart';
import '../data/data_de_nascimento_local.dart';
import '../domain/data_de_nascimento.dart';
import 'tela_data_de_nascimento.dart';

/// A parte do Perfil que cuida da idade (T123, FR-042c).
///
/// Existe como widget próprio para o `PerfilProvisorio` embuti-lo agora e a
/// tela definitiva do Perfil (T097) reaproveitá-lo.
///
/// - **Com data**: a idade como **informação** (nunca botão, FR-012 da 002),
///   e logo abaixo as ações de mudar e de tirar. Tirar pede confirmação.
/// - **Sem data**: um convite curto e um botão. A data é opcional e nada
///   depende dela.
///
/// A idade é calculada **aqui, na exibição**, a partir da data e de [agora].
class SecaoIdade extends StatefulWidget {
  /// Onde a data é guardada.
  final ArmazenamentoDaDataDeNascimento armazenamento;

  /// A conta de quem é o Perfil.
  final String idDaConta;

  /// O dia de hoje; injetável para o teste.
  final DateTime Function() agora;

  /// Cria a seção.
  const SecaoIdade({
    required this.armazenamento,
    required this.idDaConta,
    this.agora = DateTime.now,
    super.key,
  });

  /// Chave da idade mostrada.
  static const Key chaveIdade = Key('perfil.idade');

  /// Chave do convite.
  static const Key chaveConvite = Key('perfil.convite');

  /// Chave do botão que abre a tela de entrada, com ou sem data.
  static const Key chaveInformar = Key('perfil.informar');

  /// Chave do botão que tira a idade.
  static const Key chaveTirar = Key('perfil.tirar');

  /// Chave da confirmação de tirar.
  static const Key chaveConfirmacao = Key('perfil.confirmacao_tirar');

  @override
  State<SecaoIdade> createState() => _SecaoIdadeState();
}

class _SecaoIdadeState extends State<SecaoIdade> {
  bool _carregou = false;
  DataDeNascimento? _data;
  bool _confirmandoRetirada = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void didUpdateWidget(SecaoIdade antiga) {
    super.didUpdateWidget(antiga);
    // Outra conta no mesmo lugar da árvore: a data da anterior não vale.
    if (antiga.idDaConta != widget.idDaConta) {
      _data = null;
      _carregou = false;
      _confirmandoRetirada = false;
      _carregar();
    }
  }

  Future<void> _carregar() async {
    final String conta = widget.idDaConta;
    final DataDeNascimento? data = await widget.armazenamento.ler(conta);
    if (!mounted || conta != widget.idDaConta) return;
    setState(() {
      _data = data;
      _carregou = true;
    });
  }

  Future<void> _abrirEntrada() async {
    final bool? guardou = await Navigator.of(context).push<bool>(
      RotaMemora<bool>(
        builder: (BuildContext _) => TelaDataDeNascimento(
          armazenamento: widget.armazenamento,
          idDaConta: widget.idDaConta,
          inicial: _data,
          agora: widget.agora,
        ),
      ),
    );
    if (guardou == true && mounted) await _carregar();
  }

  Future<void> _tirar() async {
    await widget.armazenamento.apagar(widget.idDaConta);
    if (!mounted) return;
    setState(() {
      _data = null;
      _confirmandoRetirada = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Enquanto lê, nada: a leitura é local e dura um quadro, e mostrar o
    // convite antes da hora faria quem já informou ver a pergunta piscar.
    if (!_carregou) return const SizedBox.shrink();

    final DataDeNascimento? data = _data;
    if (data == null) {
      return Cartao(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const TextoMemora.apoio(
              TextosPerfil.convite,
              key: SecaoIdade.chaveConvite,
            ),
            const SizedBox(height: MemoraEspacamento.md),
            BotaoSecundario(
              key: SecaoIdade.chaveInformar,
              rotulo: TextosPerfil.botaoInformar,
              icone: Icons.cake_outlined,
              aoTocar: _abrirEntrada,
            ),
          ],
        ),
      );
    }

    return Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CampoInformacao(
            key: SecaoIdade.chaveIdade,
            rotulo: TextosPerfil.rotuloIdade,
            valor: TextosPerfil.idade(data.idadeEm(widget.agora())),
          ),
          const SizedBox(height: MemoraEspacamento.md),
          if (_confirmandoRetirada)
            ConfirmacaoMemora(
              key: SecaoIdade.chaveConfirmacao,
              pergunta: TextosPerfil.perguntaTirar,
              aviso: TextosPerfil.avisoTirar,
              rotuloConfirmar: TextosPerfil.botaoConfirmarTirar,
              rotuloRecusar: TextosPerfil.botaoManter,
              aoConfirmar: _tirar,
              aoRecusar: () => setState(() => _confirmandoRetirada = false),
            )
          else ...<Widget>[
            BotaoSecundario(
              key: SecaoIdade.chaveInformar,
              rotulo: TextosPerfil.botaoMudar,
              icone: Icons.edit_outlined,
              aoTocar: _abrirEntrada,
            ),
            const SizedBox(height: MemoraEspacamento.sm),
            BotaoTerciario(
              key: SecaoIdade.chaveTirar,
              rotulo: TextosPerfil.botaoTirar,
              aoTocar: () => setState(() => _confirmandoRetirada = true),
            ),
          ],
        ],
      ),
    );
  }
}

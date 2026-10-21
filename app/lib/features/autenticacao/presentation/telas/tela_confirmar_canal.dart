import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_autenticacao.dart';
import '../../domain/autenticacao.dart';
import '../../data/repositorio_autenticacao_simulado.dart';

/// Confirma a posse do canal com o código de 6 dígitos (FR-052, FR-062).
///
/// ## Esta tela não estava nas tarefas da fase 5, e precisa existir
///
/// A T057 exige que o cadastro assistido **não conclua** sem posse confirmada,
/// e a T058 cria os endpoints que confirmam. Nenhuma tarefa de aplicativo liga
/// as duas coisas: sem esta tela, a conta assistida nasce em espera e não há por
/// onde sair dela — a pessoa fica com uma conta que existe e não entra.
///
/// ## Por que o código é digitado, e nunca um link
///
/// A decisão R5 escolheu código em vez de link clicável, e o motivo é a defesa
/// contra engenharia social: ensinar uma pessoa idosa a clicar em link recebido
/// por mensagem é ensinar exatamente o hábito que o golpe usa. A regra que o
/// Memora ensina é *"nunca clique, sempre digite"*, e esta tela precisa ser
/// coerente com ela.
///
/// ## A recusa é uma só
///
/// Código errado, vencido e já usado mostram o mesmo texto, como no servidor.
/// Separá-los diria a quem está tentando adivinhar em que ponto chegou.
class TelaConfirmarCanal extends StatefulWidget {
  /// Chave do campo de código.
  static const Key chaveCodigo = Key('confirmar_canal.codigo');

  /// Chave do botão que confirma.
  static const Key chaveConfirmar = Key('confirmar_canal.confirmar');

  /// Chave do botão que pede outro código.
  static const Key chaveReenviar = Key('confirmar_canal.reenviar');

  /// Repositório que fala com o servidor.
  final RepositorioAutenticacao repositorio;

  /// Canal a confirmar.
  final String canalId;

  /// Canal como a pessoa o reconhece — o e-mail ou telefone que ela digitou.
  final String canalVisivel;

  /// Chamada quando a posse é confirmada.
  final VoidCallback aoConfirmar;

  /// Cria a tela de confirmação de canal.
  const TelaConfirmarCanal({
    required this.repositorio,
    required this.canalId,
    required this.canalVisivel,
    required this.aoConfirmar,
    super.key,
  });

  @override
  State<TelaConfirmarCanal> createState() => _TelaConfirmarCanalState();
}

class _TelaConfirmarCanalState extends State<TelaConfirmarCanal> {
  String _codigo = '';
  bool _enviando = false;
  String? _erro;
  String? _aviso;

  @override
  void initState() {
    super.initState();
    // Pede o primeiro código sozinho: chegar aqui já significa que a pessoa
    // precisa dele, e obrigá-la a tocar em "enviar" antes acrescentaria um
    // passo cuja única função seria explicar a si mesmo.
    WidgetsBinding.instance.addPostFrameCallback((_) => _pedirCodigo());
  }

  Future<void> _pedirCodigo({bool avisar = false}) async {
    final ResultadoDeCanal resultado =
        await widget.repositorio.enviarCodigoDeCanal(widget.canalId);
    if (!mounted) return;

    setState(() {
      _aviso = switch (resultado) {
        CanalConcluido() when avisar => TextosAutenticacao.codigoReenviado,
        CanalConcluido() => null,
        CanalFalhou() => null,
      };
      _erro = switch (resultado) {
        CanalFalhou(:final FalhaAutenticacao falha) => _mensagemDe(falha),
        CanalConcluido() => _erro,
      };
    });
  }

  Future<void> _confirmar() async {
    if (_enviando) return;
    setState(() {
      _enviando = true;
      _erro = null;
      _aviso = null;
    });

    final ResultadoDeCanal resultado =
        await widget.repositorio.confirmarCanal(widget.canalId, _codigo);
    if (!mounted) return;

    switch (resultado) {
      case CanalConcluido():
        widget.aoConfirmar();
      case CanalFalhou(:final FalhaAutenticacao falha):
        setState(() {
          _enviando = false;
          _erro = _mensagemDe(falha);
        });
    }
  }

  /// Texto por falha, na voz da Memora.
  ///
  /// `dadosInvalidos` é o caso comum aqui — é o que o servidor devolve para
  /// código errado, vencido, já usado e canal que não é seu.
  String _mensagemDe(FalhaAutenticacao falha) => switch (falha) {
        FalhaAutenticacao.dadosInvalidos => TextosAutenticacao.codigoNaoConfere,
        FalhaAutenticacao.semConexao => TextosAutenticacao.semConexao,
        FalhaAutenticacao.muitasTentativas =>
          TextosAutenticacao.credenciaisInvalidas,
        FalhaAutenticacao.credenciaisInvalidas =>
          TextosAutenticacao.sessaoExpirada,
        FalhaAutenticacao.inesperada => TextosAutenticacao.inesperada,
      };

  bool get _podeConfirmar =>
      !_enviando && _codigo.length == CampoCodigo.digitos;

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Scaffold(
      backgroundColor: cores.fundo,
      appBar: const BarraSuperior(
        titulo: TextosAutenticacao.tituloConfirmarCanal,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MemoraEspacamento.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextoMemora(
                TextosAutenticacao.pedidoConfirmarCanal(widget.canalVisivel),
              ),
              const SizedBox(height: MemoraEspacamento.xxl),
              CampoCodigo(
                key: TelaConfirmarCanal.chaveCodigo,
                rotulo: TextosAutenticacao.rotuloCodigo,
                erro: _erro,
                aoMudar: (String valor) => setState(() => _codigo = valor),
              ),
              if (widget.repositorio is RepositorioAutenticacaoSimulado) ...<Widget>[
                const SizedBox(height: MemoraEspacamento.sm),
                const TextoMemora.apoio(
                  'Código para demonstração: 123456',
                ),
              ],
              if (_aviso != null) ...<Widget>[
                const SizedBox(height: MemoraEspacamento.md),
                TextoMemora.apoio(_aviso!),
              ],
              const SizedBox(height: MemoraEspacamento.xxl),
              if (_enviando)
                const Carregando(mensagem: 'Estou conferindo...')
              else
                BotaoPrimario(
                  key: TelaConfirmarCanal.chaveConfirmar,
                  rotulo: TextosAutenticacao.botaoConfirmarCodigo,
                  icone: Icons.check,
                  aoTocar: _podeConfirmar ? _confirmar : null,
                ),
              const SizedBox(height: MemoraEspacamento.md),
              BotaoTerciario(
                key: TelaConfirmarCanal.chaveReenviar,
                rotulo: TextosAutenticacao.botaoReenviarCodigo,
                aoTocar: _enviando ? null : () => _pedirCodigo(avisar: true),
              ),
              const SizedBox(height: MemoraEspacamento.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

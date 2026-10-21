import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_autenticacao.dart';
import '../../domain/autenticacao.dart';
import '../controladores/controlador_recuperacao.dart';
import '../widgets/aviso_antigolpe.dart';
import '../widgets/regras_de_senha.dart';

/// Tela de recuperação de acesso (T070, US3).
///
/// ## Uma tela, três etapas
///
/// Pedir o número, digitá-lo junto com a senha nova, e a confirmação. Poderiam
/// ser três telas, e a razão de não serem é o [AvisoAntigolpe]: a FR-023 pede
/// aviso **permanente**, e um aviso duplicado em três arquivos é um aviso que
/// diverge no primeiro dia em que alguém melhorar a frase de um deles.
///
/// ## O aviso fica no topo, antes de qualquer campo
///
/// Não é ordem estética. Quem está sendo enganado ao telefone é conduzido
/// direto ao campo — "digita o código que chegou aí" —, e um aviso embaixo do
/// formulário só seria lido por quem já não precisava dele.
///
/// ## A terceira etapa existe para contar a FR-021
///
/// Trocar a senha derruba todas as outras sessões, e entrar em silêncio
/// desperdiçaria isso. Quem chega aqui pode estar recuperando a conta
/// **porque** alguém entrou nela: saber que os outros aparelhos saíram é a
/// diferença entre uma senha nova e a sensação de ter a conta de volta.
class TelaRecuperacao extends StatefulWidget {
  /// Chave do campo de identificador.
  static const Key chaveIdentificador = Key('recuperacao.identificador');

  /// Chave do botão que pede o número.
  static const Key chavePedirCodigo = Key('recuperacao.pedir_codigo');

  /// Chave da confirmação do pedido — o texto idêntico da FR-019.
  static const Key chaveConfirmacao = Key('recuperacao.confirmacao');

  /// Chave do campo do número recebido.
  static const Key chaveCodigo = Key('recuperacao.codigo');

  /// Chave do campo da senha nova.
  static const Key chaveSenhaNova = Key('recuperacao.senha_nova');

  /// Chave do botão que troca a senha.
  static const Key chaveTrocarSenha = Key('recuperacao.trocar_senha');

  /// Chave do botão que volta para pedir outro número.
  static const Key chavePedirOutro = Key('recuperacao.pedir_outro');

  /// Chave do botão que conclui e entra.
  static const Key chaveContinuar = Key('recuperacao.continuar');

  /// Controlador da tela.
  final ControladorRecuperacao controlador;

  /// Chamada quando a pessoa conclui a troca e segue para dentro.
  final void Function(PessoaAutenticada pessoa) aoConcluir;

  /// Acionada ao voltar.
  final VoidCallback? aoVoltar;

  /// Cria a tela de recuperação.
  const TelaRecuperacao({
    required this.controlador,
    required this.aoConcluir,
    this.aoVoltar,
    super.key,
  });

  @override
  State<TelaRecuperacao> createState() => _TelaRecuperacaoState();
}

class _TelaRecuperacaoState extends State<TelaRecuperacao> {
  final TextEditingController _campoIdentificador = TextEditingController();
  final TextEditingController _campoCodigo = TextEditingController();

  @override
  void initState() {
    super.initState();
    _campoIdentificador.text = widget.controlador.identificador;
    widget.controlador.addListener(_aoMudarEstado);
  }

  @override
  void dispose() {
    widget.controlador.removeListener(_aoMudarEstado);
    _campoIdentificador.dispose();
    _campoCodigo.dispose();
    super.dispose();
  }

  /// O controlador é dono dos valores; os campos apenas os refletem.
  ///
  /// Importa num momento que não vem da digitação: depois de um número
  /// recusado, o controlador limpa o código, e sem isto o valor já recusado
  /// continuaria na tela convidando a tocar no botão de novo.
  void _aoMudarEstado() {
    _sincronizar(_campoIdentificador, widget.controlador.identificador);
    _sincronizar(_campoCodigo, widget.controlador.codigo);
  }

  void _sincronizar(TextEditingController campo, String valor) {
    if (campo.text == valor) return;
    campo.value = TextEditingValue(
      text: valor,
      selection: TextSelection.collapsed(offset: valor.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return ListenableBuilder(
      listenable: widget.controlador,
      builder: (BuildContext context, _) {
        final ControladorRecuperacao c = widget.controlador;

        return Scaffold(
          backgroundColor: cores.fundo,
          appBar: BarraSuperior(
            titulo: TextosAutenticacao.tituloRecuperacao,
            // Concluída a troca não há para onde voltar: a senha já mudou, e
            // um "voltar" ali ofereceria desfazer o que não se desfaz.
            aoVoltar: c.etapa == EtapaRecuperacao.concluida
                ? null
                : widget.aoVoltar,
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(MemoraEspacamento.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Antes de tudo, inclusive do convite (FR-023).
                  const AvisoAntigolpe(),
                  const SizedBox(height: MemoraEspacamento.xxl),
                  ...switch (c.etapa) {
                    EtapaRecuperacao.pedirCodigo => _pedirCodigo(c, cores),
                    EtapaRecuperacao.definirSenha => _definirSenha(c),
                    EtapaRecuperacao.concluida => _concluida(c, cores),
                  },
                  const SizedBox(height: MemoraEspacamento.xxl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _pedirCodigo(ControladorRecuperacao c, MemoraCores cores) => <Widget>[
        Container(
          padding: const EdgeInsets.all(MemoraEspacamento.md),
          decoration: BoxDecoration(
            color: cores.superficie,
            borderRadius: BorderRadius.circular(MemoraRaio.cartao),
            border: Border.all(color: cores.borda),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: MemoraElevacao.sombra,
                blurRadius: MemoraElevacao.cartao,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            children: <Widget>[
              MemoraPersonagem(
                expressao: ExpressaoDaMemora.falando,
                tamanho: MemoraDimensoes.alvoDecisao,
              ),
              SizedBox(width: MemoraEspacamento.md),
              Expanded(
                child: TextoMemora(TextosAutenticacao.conviteRecuperacao),
              ),
            ],
          ),
        ),
        const SizedBox(height: MemoraEspacamento.lg),
        CaixaDeEtapa(
          instrucao: 'Informe o contato da sua conta',
          child: CampoTexto(
            key: TelaRecuperacao.chaveIdentificador,
            rotulo: TextosAutenticacao.rotuloIdentificador,
            textoAjuda: TextosAutenticacao.ajudaIdentificador,
            controlador: _campoIdentificador,
            tipoTeclado: TextInputType.emailAddress,
            aoMudar: c.informarIdentificador,
            habilitado: !c.enviando,
          ),
        ),
        if (c.mensagemDeErro != null) ...<Widget>[
          const SizedBox(height: MemoraEspacamento.lg),
          MensagemErro(mensagem: c.mensagemDeErro!),
        ],
        const SizedBox(height: MemoraEspacamento.xl),
        if (c.enviando)
          const Carregando(mensagem: TextosAutenticacao.pedindoCodigo)
        else
          BotaoPrimario(
            key: TelaRecuperacao.chavePedirCodigo,
            rotulo: TextosAutenticacao.botaoPedirCodigo,
            icone: Icons.arrow_forward,
            aoTocar: c.podePedirCodigo ? c.pedirCodigo : null,
          ),
      ];

  List<Widget> _definirSenha(ControladorRecuperacao c) => <Widget>[
        // A confirmação da FR-019 é a mesma frase exista a conta ou não.
        TextoMemora(
          c.confirmacaoDoPedido ?? '',
          key: TelaRecuperacao.chaveConfirmacao,
        ),
        const SizedBox(height: MemoraEspacamento.lg),
        CaixaDeEtapa(
          instrucao: 'Digite o número que você recebeu',
          child: CampoCodigo(
            key: TelaRecuperacao.chaveCodigo,
            rotulo: TextosAutenticacao.rotuloCodigo,
            controlador: _campoCodigo,
            erro: c.mensagemDeErro,
            aoMudar: c.informarCodigo,
          ),
        ),
        const SizedBox(height: MemoraEspacamento.lg),
        CaixaDeEtapa(
          instrucao: 'Crie sua nova senha',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              RegrasDeSenha(atendidas: c.regrasAtendidas),
              const SizedBox(height: MemoraEspacamento.md),
              CampoSenha(
                key: TelaRecuperacao.chaveSenhaNova,
                rotulo: TextosAutenticacao.rotuloSenhaNova,
                textoAjuda: TextosAutenticacao.ajudaSenhaNova,
                aoMudar: c.informarSenha,
              ),
            ],
          ),
        ),
        const SizedBox(height: MemoraEspacamento.xl),
        if (c.enviando)
          const Carregando(mensagem: TextosAutenticacao.trocandoSenha)
        else
          BotaoPrimario(
            key: TelaRecuperacao.chaveTrocarSenha,
            rotulo: TextosAutenticacao.botaoTrocarSenha,
            icone: Icons.check,
            aoTocar: c.podeTrocarSenha ? c.trocarSenha : null,
          ),
        const SizedBox(height: MemoraEspacamento.md),
        BotaoTerciario(
          key: TelaRecuperacao.chavePedirOutro,
          rotulo: TextosAutenticacao.botaoPedirOutroCodigo,
          aoTocar: c.enviando ? null : c.pedirOutroCodigo,
          larguraTotal: true,
        ),
      ];

  List<Widget> _concluida(ControladorRecuperacao c, MemoraCores cores) =>
      <Widget>[
        Center(
          child: Container(
            width: MemoraDimensoes.ilustracaoCabecalho,
            height: MemoraDimensoes.ilustracaoCabecalho,
            decoration: BoxDecoration(
              color: cores.sucesso.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: MemoraPersonagem(
                expressao: ExpressaoDaMemora.comemorando,
              ),
            ),
          ),
        ),
        const SizedBox(height: MemoraEspacamento.lg),
        Container(
          padding: const EdgeInsets.all(MemoraEspacamento.lg),
          decoration: BoxDecoration(
            color: cores.superficie,
            borderRadius: BorderRadius.circular(MemoraRaio.cartao),
            border: Border.all(color: cores.borda),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: MemoraElevacao.sombra,
                blurRadius: MemoraElevacao.cartao,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const TextoMemora(
            TextosAutenticacao.avisoSessoesEncerradas,
            alinhamento: TextAlign.center,
          ),
        ),
        const SizedBox(height: MemoraEspacamento.xl),
        BotaoPrimario(
          key: TelaRecuperacao.chaveContinuar,
          rotulo: TextosAutenticacao.botaoEntrarComSenhaNova,
          icone: Icons.arrow_forward,
          aoTocar: () => widget.aoConcluir(c.pessoa!),
        ),
      ];
}

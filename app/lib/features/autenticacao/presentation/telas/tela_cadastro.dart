import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/autenticacao.dart';
import '../controladores/controlador_cadastro.dart';
import '../widgets/regras_de_senha.dart';

/// Tela de criação de conta.
///
/// Ao concluir, a pessoa **já entra no aplicativo** (FR-009). O protótipo
/// mandava para o login logo após cadastrar — pedir a senha que a pessoa
/// acabou de criar é onde o idoso desiste.
///
/// Todos os componentes vêm do Design System: nenhum widget de interface é
/// construído aqui.
class TelaCadastro extends StatefulWidget {
  /// Chave do campo de nome, usada pelos testes.
  static const Key chaveNome = Key('cadastro.nome');

  /// Chave do campo de canal (e-mail ou telefone).
  static const Key chaveCanal = Key('cadastro.canal');

  /// Chave do campo de senha.
  static const Key chaveSenha = Key('cadastro.senha');

  /// Chave do botão que envia o cadastro.
  static const Key chaveEnviar = Key('cadastro.enviar');

  /// Chave do botão que pede o aparelho de volta, no modo assistido.
  static const Key chavePedirAparelho = Key('cadastro.pedir_aparelho');

  /// Controlador do formulário.
  final ControladorCadastro controlador;

  /// Chamada quando a conta é criada e a sessão já está iniciada.
  final void Function(PessoaAutenticada pessoa) aoConcluir;

  /// Acionada ao voltar.
  final VoidCallback? aoVoltar;

  /// Acionada quando o modo assistido chega na senha (FR-059).
  ///
  /// Opcional para que a tela continue montável sozinha em teste e na vitrine.
  /// Sem ela, o botão que pede o aparelho aparece desabilitado — nunca some:
  /// um modo assistido sem saída visível seria pior que um botão inerte.
  final VoidCallback? aoEntregarAparelho;

  /// Cria a tela de cadastro.
  const TelaCadastro({
    required this.controlador,
    required this.aoConcluir,
    this.aoVoltar,
    this.aoEntregarAparelho,
    super.key,
  });

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  @override
  void initState() {
    super.initState();
    widget.controlador.addListener(_aoMudarEstado);
  }

  @override
  void dispose() {
    widget.controlador.removeListener(_aoMudarEstado);
    super.dispose();
  }

  void _aoMudarEstado() {
    final ControladorCadastro c = widget.controlador;
    if (c.estado == EstadoCadastro.concluido && c.pessoa != null) {
      widget.aoConcluir(c.pessoa!);
    }
  }

  /// Texto de erro na persona da Memora: acolhedor e sem culpar a pessoa.
  String _mensagemDe(FalhaAutenticacao falha) => switch (falha) {
    FalhaAutenticacao.semConexao =>
      'Não consegui falar com a internet agora. Seus dados continuam '
          'aqui, é só tentar de novo.',
    FalhaAutenticacao.muitasTentativas =>
      'Tudo bem, acontece! Vamos esperar alguns minutinhos antes de '
          'tentar de novo.',
    FalhaAutenticacao.dadosInvalidos =>
      'Alguma informação não foi aceita. Pode conferir comigo?',
    FalhaAutenticacao.credenciaisInvalidas =>
      'Esses dados não conferem. Vamos tentar de novo com calma?',
    FalhaAutenticacao.inesperada =>
      'Algo não saiu como eu esperava. Vamos tentar mais uma vez?',
  };

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return ListenableBuilder(
      listenable: widget.controlador,
      builder: (BuildContext context, _) {
        final ControladorCadastro c = widget.controlador;

        return Scaffold(
          backgroundColor: cores.fundo,
          appBar: BarraSuperior(
            titulo: 'Criar minha conta',
            aoVoltar: widget.aoVoltar,
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(MemoraEspacamento.xl),
              child: CartaoComAvatar(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const TextoMemora(
                      'Vou te pedir só o necessário. Nada de CPF, banco ou '
                      'documento — eu nunca preciso disso 😊',
                    ),

                    // Modo assistido (decisão D3): perguntado logo no início.
                    const SizedBox(height: MemoraEspacamento.xl),
                    OpcaoSelecionavel(
                      rotulo: 'Tem alguém te ajudando agora?',
                      descricao: c.modoAssistido
                          ? 'Na hora da senha eu vou pedir o celular de volta '
                                'para você'
                          : 'Toque aqui se um filho ou neto estiver junto',
                      selecionada: c.modoAssistido,
                      aoSelecionar: () =>
                          c.definirModoAssistido(!c.modoAssistido),
                    ),

                    const SizedBox(height: MemoraEspacamento.xxl),
                    CampoTexto(
                      key: TelaCadastro.chaveNome,
                      rotulo: 'Como posso te chamar?',
                      textoAjuda: 'É assim que eu vou falar com você',
                      erro: c.erroNome,
                      aoMudar: c.informarNome,
                      habilitado: !c.enviando,
                    ),

                    const SizedBox(height: MemoraEspacamento.xl),
                    const TextoMemora.tituloSecao('Como você quer entrar?'),
                    const SizedBox(height: MemoraEspacamento.sm),
                    const TextoMemora.apoio(
                      'Escolha só um. O outro você pode adicionar depois.',
                    ),
                    const SizedBox(height: MemoraEspacamento.md),
                    for (final TipoCanal tipo in TipoCanal.values) ...<Widget>[
                      OpcaoSelecionavel(
                        rotulo: tipo.rotulo,
                        selecionada: c.tipoCanal == tipo,
                        aoSelecionar: () => c.escolherTipoCanal(tipo),
                      ),
                      const SizedBox(height: MemoraEspacamento.sm),
                    ],

                    const SizedBox(height: MemoraEspacamento.md),
                    CampoTexto(
                      key: TelaCadastro.chaveCanal,
                      rotulo: c.tipoCanal == TipoCanal.email
                          ? 'Seu e-mail'
                          : 'Seu telefone',
                      textoAjuda: c.tipoCanal == TipoCanal.email
                          ? 'Usamos para você entrar e recuperar a senha'
                          : 'Usamos para você entrar e recuperar a senha',
                      erro: c.erroCanal,
                      tipoTeclado: c.tipoCanal == TipoCanal.email
                          ? TextInputType.emailAddress
                          : TextInputType.phone,
                      aoMudar: c.informarCanal,
                      habilitado: !c.enviando,
                    ),

                    const SizedBox(height: MemoraEspacamento.xl),
                    // No modo assistido o formulário PARA aqui, e o campo de
                    // senha só aparece depois que o aparelho volta para a pessoa
                    // dona da conta (FR-059). Um aviso no lugar disso seria lido
                    // depois de a senha já ter sido digitada — tarde demais, com
                    // o acompanhante já tendo visto o que este modo protege.
                    if (!c.podeDigitarSenha)
                      BotaoPrimario(
                        key: TelaCadastro.chavePedirAparelho,
                        rotulo: 'Agora vamos criar a senha',
                        icone: Icons.arrow_forward,
                        aoTocar:
                            c.podePedirOAparelho &&
                                widget.aoEntregarAparelho != null
                            ? widget.aoEntregarAparelho
                            : null,
                      )
                    else ...<Widget>[
                      // Regras exibidas ANTES de digitar (FR-008).
                      RegrasDeSenha(atendidas: c.regrasAtendidas),
                      const SizedBox(height: MemoraEspacamento.md),
                      CampoSenha(
                        key: TelaCadastro.chaveSenha,
                        rotulo: 'Crie sua senha',
                        textoAjuda: 'Use uma frase que só você lembre',
                        aoMudar: c.informarSenha,
                        // No modo assistido, revelar a senha entregaria ao
                        // acompanhante o segredo que este modo protege (FR-060).
                        permitirRevelar: !c.modoAssistido,
                      ),
                    ],

                    if (c.estado == EstadoCadastro.comErro &&
                        c.falha != null) ...<Widget>[
                      const SizedBox(height: MemoraEspacamento.xl),
                      MensagemErro(
                        mensagem: _mensagemDe(c.falha!),
                        aoTentarNovamente: c.tentarNovamente,
                      ),
                    ],

                    const SizedBox(height: MemoraEspacamento.xxl),
                    // Enquanto a senha não pode ser digitada não existe o que
                    // enviar, e dois botões primários na mesma tela dividiriam a
                    // atenção de quem precisa de um caminho só.
                    if (c.podeDigitarSenha)
                      if (c.enviando)
                        const Carregando(mensagem: 'Estou criando sua conta...')
                      else
                        BotaoPrimario(
                          key: TelaCadastro.chaveEnviar,
                          rotulo: 'Criar minha conta',
                          icone: Icons.check,
                          aoTocar: c.podeEnviar ? c.enviar : null,
                        ),
                    const SizedBox(height: MemoraEspacamento.xxl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

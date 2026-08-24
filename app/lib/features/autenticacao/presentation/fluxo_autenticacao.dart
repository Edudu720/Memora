import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/textos_autenticacao.dart';
import '../data/ultimo_acesso_local.dart';
import '../domain/autenticacao.dart';
import '../domain/monitor_de_sessao.dart';
import 'controladores/controlador_cadastro.dart';
import 'controladores/controlador_login.dart';
import 'telas/tela_boas_vindas.dart';
import 'telas/tela_cadastro.dart';
import 'telas/tela_confirmar_canal.dart';
import 'telas/tela_entrega_do_aparelho.dart';
import 'telas/tela_login.dart';
import 'telas/tela_primeira_entrada.dart';

/// Liga as telas das User Stories 1 e 2.
///
/// ## O que este fluxo garante
///
/// Ao concluir o cadastro a pessoa **já está autenticada** (FR-009) — não há
/// passagem pelo login. Quem já tem conta chega ao login pelo caminho discreto
/// da tela de boas-vindas, e lá a sessão é renovada em silêncio antes de
/// qualquer campo aparecer (FR-016).
///
/// ## O monitor só existe enquanto a pessoa está dentro
///
/// A contagem de inatividade da FR-017 começa quando a pessoa entra e para
/// quando ela sai. Deixá-lo correndo na tela de login não faria sentido: não há
/// sessão para encerrar, e o aviso apareceria sobre um formulário vazio.
class FluxoAutenticacao extends StatefulWidget {
  /// Repositório usado para criar a conta e para entrar.
  ///
  /// Recebe a implementação por parâmetro para que as telas possam ser testadas
  /// e demonstradas sem depender de o backend estar de pé.
  final RepositorioAutenticacao repositorio;

  /// Onde fica o identificador do último acesso (FR-012).
  final UltimoAcesso ultimoAcesso;

  /// Quanto tempo parado até a sessão cair (FR-017).
  final Duration inatividade;

  /// Com quanta antecedência avisar antes de encerrar.
  final Duration avisoDeInatividade;

  /// Cria o fluxo de autenticação.
  const FluxoAutenticacao({
    required this.repositorio,
    required this.ultimoAcesso,
    this.inatividade = MonitorDeSessao.inatividadePadrao,
    this.avisoDeInatividade = MonitorDeSessao.avisoPadrao,
    super.key,
  });

  @override
  State<FluxoAutenticacao> createState() => _FluxoAutenticacaoState();
}

enum _Etapa {
  boasVindas,
  cadastro,
  entregaDoAparelho,
  confirmarCanal,
  primeiraEntrada,
  login,
  dentro,
}

class _FluxoAutenticacaoState extends State<FluxoAutenticacao> {
  late final ControladorCadastro _cadastro =
      ControladorCadastro(widget.repositorio);

  late final MonitorDeSessao _monitor = MonitorDeSessao(
    inatividade: widget.inatividade,
    aviso: widget.avisoDeInatividade,
    aoAvisar: _avisarDeInatividade,
    aoExpirar: _expirarPorInatividade,
  );

  /// Recriado a cada visita ao login: o controlador tenta renovar a sessão no
  /// `initState` da tela, e reaproveitar um que já concluiu deixaria estado
  /// velho decidindo o que a pessoa vê.
  ControladorLogin? _login;

  _Etapa _etapa = _Etapa.boasVindas;
  PessoaAutenticada? _pessoa;
  bool _avisoNaTela = false;

  /// Conta recém-criada em modo assistido, à espera da confirmação de canal.
  ///
  /// Guardada separada de [_pessoa] de propósito: ela **não** está dentro do
  /// aplicativo. A sessão existe e serve para confirmar o canal, e nada mais —
  /// o servidor recusa a entrada dela enquanto a posse não for confirmada.
  PessoaAutenticada? _aguardandoConfirmacao;

  @override
  void dispose() {
    _cadastro.dispose();
    _login?.dispose();
    _monitor.dispose();
    super.dispose();
  }

  void _irParaLogin() {
    _login?.dispose();
    setState(() {
      _login = ControladorLogin(widget.repositorio, widget.ultimoAcesso);
      _etapa = _Etapa.login;
    });
  }

  /// Conclusão do cadastro, que já é um acesso autenticado (FR-009).
  ///
  /// Lembrar o canal aqui é o que impede a pessoa de digitar o e-mail inteiro
  /// no primeiro login depois de criar a conta — a barreira que a FR-012 existe
  /// para remover. Deixar isso só no login criava justamente o buraco que ela
  /// deveria fechar.
  Future<void> _cadastrou(PessoaAutenticada pessoa) async {
    await widget.ultimoAcesso.lembrar(_cadastro.canal.trim().toLowerCase());
    if (!mounted) return;

    // Cadastro comum entra direto (FR-009). O assistido não: a conta existe,
    // mas o servidor a mantém em espera até a posse do canal ser confirmada
    // (FR-062), e entrar com ela seria recusado.
    if (_cadastro.modoAssistido && pessoa.canalId != null) {
      setState(() {
        _aguardandoConfirmacao = pessoa;
        _etapa = _Etapa.confirmarCanal;
      });
      return;
    }

    _entrou(pessoa);
  }

  /// Posse confirmada: o cadastro assistido finalmente concluiu (FR-062).
  ///
  /// Daqui a pessoa **não** vai para dentro do aplicativo, e sim para a
  /// primeira entrada sozinha (FR-063). Levá-la para dentro agora pularia
  /// justamente a confirmação de autonomia que a User Story 5 existe para
  /// produzir — e ela sairia dali sem nunca ter aberto a própria conta.
  void _canalConfirmado() {
    setState(() => _etapa = _Etapa.primeiraEntrada);
  }

  /// Encerra a sessão do cadastro e leva ao login (FR-063).
  ///
  /// Encerrar é o ponto: se a sessão continuasse de pé, "entrar sozinha" seria
  /// teatro — a pessoa tocaria um botão e já estaria dentro, sem digitar nada.
  Future<void> _entrarSozinha() async {
    await widget.repositorio.encerrarSessao();
    if (!mounted) return;
    setState(() => _aguardandoConfirmacao = null);
    _irParaLogin();
  }

  void _entrou(PessoaAutenticada pessoa) {
    setState(() {
      _pessoa = pessoa;
      _etapa = _Etapa.dentro;
    });
    _monitor.iniciar();
  }

  Future<void> _sair() async {
    _monitor.parar();
    await widget.repositorio.encerrarSessao();
    if (!mounted) return;
    _irParaLogin();
  }

  Future<void> _avisarDeInatividade(int segundosRestantes) async {
    if (!mounted || _avisoNaTela) return;
    _avisoNaTela = true;

    await DialogoMemora.mostrar(
      context,
      dialogo: DialogoMemora(
        titulo: TextosAutenticacao.tituloAvisoInatividade,
        mensagem: TextosAutenticacao.avisoInatividade(segundosRestantes),
        rotuloConfirmar: TextosAutenticacao.botaoContinuar,
        aoConfirmar: () {
          Navigator.of(context).pop();
          _monitor.registrarAtividade();
        },
      ),
    );

    _avisoNaTela = false;
  }

  Future<void> _expirarPorInatividade() async {
    await widget.repositorio.encerrarSessao();
    if (!mounted) return;

    // Fecha o aviso antes de trocar de tela: deixá-lo aberto por cima do login
    // ofereceria um "pode continuar" que já não continua nada.
    if (_avisoNaTela) {
      Navigator.of(context).pop();
      _avisoNaTela = false;
    }
    _irParaLogin();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_etapa) {
      _Etapa.boasVindas => TelaBoasVindas(
          aoComecar: () => setState(() => _etapa = _Etapa.cadastro),
          aoJaTerConta: _irParaLogin,
        ),
      _Etapa.cadastro => TelaCadastro(
          controlador: _cadastro,
          aoVoltar: () => setState(() => _etapa = _Etapa.boasVindas),
          aoConcluir: _cadastrou,
          aoEntregarAparelho: () =>
              setState(() => _etapa = _Etapa.entregaDoAparelho),
        ),
      _Etapa.entregaDoAparelho => TelaEntregaDoAparelho(
          aoReceberOAparelho: () {
            _cadastro.confirmarEntregaDoAparelho();
            setState(() => _etapa = _Etapa.cadastro);
          },
          aoAdiar: () => setState(() => _etapa = _Etapa.cadastro),
        ),
      _Etapa.confirmarCanal => TelaConfirmarCanal(
          repositorio: widget.repositorio,
          canalId: _aguardandoConfirmacao!.canalId!,
          canalVisivel: _cadastro.canal.trim(),
          aoConfirmar: _canalConfirmado,
        ),
      _Etapa.primeiraEntrada => TelaPrimeiraEntrada(
          nome: _aguardandoConfirmacao?.nomeTratamento ?? '',
          aoEntrarSozinha: _entrarSozinha,
        ),
      _Etapa.login => TelaLogin(
          controlador: _login!,
          aoVoltar: () => setState(() => _etapa = _Etapa.boasVindas),
          aoEntrar: _entrou,
        ),
      // Qualquer toque adia a expiração — inclusive rolar a tela, que é
      // atividade de quem está lendo, não de quem foi embora.
      _Etapa.dentro => Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _monitor.registrarAtividade(),
          child: _TelaDentro(
            nome: _pessoa?.nomeTratamento ?? '',
            aoSair: _sair,
          ),
        ),
    };
  }
}

/// Confirmação de que a pessoa entrou — provisória até o Hub existir.
class _TelaDentro extends StatelessWidget {
  final String nome;
  final Future<void> Function() aoSair;

  const _TelaDentro({required this.nome, required this.aoSair});

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
              const SizedBox(height: MemoraEspacamento.xxxl),
              Icon(Icons.check_circle, size: 72, color: cores.sucesso),
              const SizedBox(height: MemoraEspacamento.xl),
              TextoMemora.tituloTela(
                'Prontinho, $nome!',
                alinhamento: TextAlign.center,
              ),
              const SizedBox(height: MemoraEspacamento.md),
              const TextoMemora(
                'Você está dentro. Daqui em diante eu vou te mostrar o '
                'caminho — nunca fazer no seu lugar 😊',
                alinhamento: TextAlign.center,
              ),
              const SizedBox(height: MemoraEspacamento.xxxl),
              BotaoSecundario(rotulo: 'Sair da conta', aoTocar: aoSair),
              const SizedBox(height: MemoraEspacamento.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

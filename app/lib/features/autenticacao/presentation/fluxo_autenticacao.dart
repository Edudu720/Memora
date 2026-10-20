import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/textos_assistente.dart';
import '../../../l10n/textos_autenticacao.dart';
import '../../../l10n/textos_configuracoes.dart';
import '../data/ultimo_acesso_local.dart';
import '../domain/autenticacao.dart';
import '../domain/monitor_de_sessao.dart';
import 'controladores/controlador_cadastro.dart';
import 'controladores/controlador_login.dart';
import 'controladores/controlador_recuperacao.dart';
import 'telas/tela_boas_vindas.dart';
import 'telas/tela_cadastro.dart';
import 'telas/tela_confirmar_canal.dart';
import 'telas/tela_de_volta.dart';
import 'telas/tela_entrega_do_aparelho.dart';
import 'telas/tela_login.dart';
import '../../apresentacao/data/apresentacao_vista.dart';
import '../../apresentacao/presentation/fluxo_apresentacao.dart';
import '../../ajuda/data/compartilhar.dart';
import '../../ajuda/domain/assunto_de_ajuda.dart';
import '../../ajuda/presentation/ajuda_guiada_da_conversa.dart';
import '../../ajuda/presentation/tela_ajuda.dart';
import '../../ajuda/presentation/tela_assunto.dart';
import '../../assistente/data/abridor_de_aplicativo.dart';
import '../../assistente/data/conversa_local.dart';
import '../../assistente/domain/assistente.dart';
import '../../assistente/presentation/controladores/controlador_conversa.dart';
import '../../assistente/presentation/telas/tela_catalogo.dart';
import '../../assistente/presentation/telas/tela_conversa.dart';
import '../../assistente/presentation/telas/tela_registro.dart';
import '../../hub/domain/hub.dart';
import '../../perfil/data/data_de_nascimento_local.dart';
import '../../casca/casca_interna.dart';
import '../../casca/raizes_provisorias.dart';
import '../../configuracoes/presentation/tela_configuracoes.dart';
import '../../configuracoes/presentation/tela_conta.dart';
import '../../configuracoes/presentation/tela_privacidade.dart';
import '../../hub/presentation/telas/tela_hub.dart';
import '../../inicio/presentation/tela_inicio.dart';
import 'telas/tela_primeira_entrada.dart';
import 'telas/tela_recuperacao.dart';
import '../../../services/seguranca/limpeza_de_sessao.dart';
import '../../aprendizado/data/progresso_de_aprendizado.dart';
import '../../aprendizado/domain/guia.dart';
import '../../aprendizado/presentation/tela_passo_a_passo.dart';

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

  /// De onde vêm a conversa e o catálogo da assistente.
  ///
  /// **Opcional de propósito.** Sem ele, as portas da assistente não aparecem
  /// no Hub — é a FR-003 de novo: porta que não abre nada é pior que porta que
  /// não existe, e sem repositório não há o que listar.
  final RepositorioAssistente? assistente;

  /// O que a saída da conta tira do aparelho (FR-026, FR-048).
  ///
  /// Opcional porque o teste de widget que só exercita telas não precisa
  /// dela — mas, quando existe, ela roda em **toda** saída, inclusive a
  /// automática por inatividade.
  final LimpezaDeSessao? limpeza;

  /// Onde o Perfil guarda a data de nascimento, por conta (T123, FR-042c).
  ///
  /// Opcional: sem ele o fluxo usa uma guarda em memória, que existe para os
  /// testes. Em produção a `Composicao` exige a guarda real e o `main.dart` a
  /// repassa aqui.
  final ArmazenamentoDaDataDeNascimento? dataDeNascimento;

  /// Quais contas já viram a apresentação inicial (FR-013, T050).
  ///
  /// **Opcional de propósito**: sem ele a pessoa entra direto, como antes da
  /// 004 — é o que o teste de widget que só quer chegar ao Início espera.
  /// O aplicativo de verdade sempre o recebe da `Composicao`.
  final ApresentacaoVista? apresentacaoVista;

  /// Quem abre outro aplicativo, depois da confirmação da pessoa.
  ///
  /// Opcional: sem ele a Memora conversa e ensina, e não abre nada.
  final AbridorDeAplicativo? abridor;

  /// Quem manda o endereço oficial de download para fora do aplicativo (T089).
  ///
  /// **Nulo é "o assunto Compartilhar da Ajuda não existe"** (R12, FR-018):
  /// sem `MEMORA_URL_DOWNLOAD` no build não há o que compartilhar, e oferecer
  /// o botão seria porta que não abre nada. Vem de
  /// `Compartilhador.doAmbiente`, a única porta de entrada do endereço.
  final Compartilhador? compartilhador;

  /// Onde o progresso nos guias de aprendizado e guardado (FR-042a).
  final ProgressoDeAprendizado? progresso;

  /// Onde a conversa fica guardada no aparelho (FR-047).
  ///
  /// Trocável no teste de widget, onde I/O de arquivo real nunca completa.
  final ConversaLocal Function() conversaLocal;

  /// Quanto tempo parado até a sessão cair (FR-017).
  final Duration inatividade;

  /// Com quanta antecedência avisar antes de encerrar.
  final Duration avisoDeInatividade;

  /// Cria o fluxo de autenticação.
  const FluxoAutenticacao({
    required this.repositorio,
    this.assistente,
    this.abridor,
    this.conversaLocal = ConversaLocal.new,
    required this.ultimoAcesso,
    this.inatividade = MonitorDeSessao.inatividadePadrao,
    this.avisoDeInatividade = MonitorDeSessao.avisoPadrao,
    super.key,
    this.limpeza,
    this.dataDeNascimento,
    this.apresentacaoVista,
    this.compartilhador,
    this.progresso,
  });

  @override
  State<FluxoAutenticacao> createState() => _FluxoAutenticacaoState();
}

enum _Etapa {
  boasVindas,
  volta,
  cadastro,
  entregaDoAparelho,
  confirmarCanal,
  primeiraEntrada,
  login,
  recuperacao,

  /// Entrou, e o aplicativo confere se a conta já viu a apresentação.
  conferindoApresentacao,
  apresentacao,
  dentro,
}

class _FluxoAutenticacaoState extends State<FluxoAutenticacao> {
  late final ControladorCadastro _cadastro = ControladorCadastro(
    widget.repositorio,
  );

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

  /// Recriado a cada visita à recuperação, pelo mesmo motivo do login: um
  /// controlador que já concluiu uma troca abriria a tela na etapa final.
  ControladorRecuperacao? _recuperacao;

  _Etapa _etapa = _Etapa.boasVindas;
  _Etapa _etapaDeEntrada = _Etapa.boasVindas;

  @override
  void initState() {
    super.initState();
    _conferirUltimoAcessoInicial();
  }

  Future<void> _conferirUltimoAcessoInicial() async {
    final String? lembrado = await widget.ultimoAcesso.identificador();
    if (!mounted) return;
    if (lembrado != null && lembrado.trim().isNotEmpty) {
      setState(() {
        _etapaDeEntrada = _Etapa.volta;
        if (_etapa == _Etapa.boasVindas) {
          _etapa = _Etapa.volta;
        }
      });
    }
  }

  PessoaAutenticada? _pessoa;

  late final ArmazenamentoDaDataDeNascimento _datas =
      widget.dataDeNascimento ?? DataDeNascimentoEmMemoria();

  /// A casca de quem está dentro (R1 da feature 004). Toda tela que o fluxo
  /// abre vai para a pilha do destino à vista, por [_empilhar].
  final GlobalKey<CascaInternaState> _casca = GlobalKey<CascaInternaState>();

  /// O canal do último acesso, lido uma vez ao entrar, para o perfil (R10).
  Future<String?> _canal = Future<String?>.value();
  bool _avisoNaTela = false;

  /// Verdadeiro do instante em que a sessão expira até a pessoa entrar de novo.
  ///
  /// A expiração espera `encerrarSessao`, que no servidor real é uma chamada de
  /// rede — e, durante essa espera, a casca continua na tela e aceitando toque.
  /// Sem esta trava, um toque (ou o "Estou aqui" do aviso) reiniciava o
  /// monitor no meio da expiração, e ele seguia correndo depois do login: o
  /// aviso de inatividade aparecia **por cima do login**, e uma segunda
  /// expiração apagava o que a pessoa estava digitando (achado da revisão da
  /// PR #38, provado por `fluxo_expiracao_test.dart`).
  bool _expirando = false;

  /// Quantas vezes alguém entrou neste fluxo. A conferência da apresentação é
  /// uma leitura assíncrona: se a sessão expirar e **outra** pessoa (ou a mesma)
  /// entrar antes de a leitura antiga voltar, só a resposta da entrada atual
  /// decide o que se mostra — olhar a etapa não basta, porque ela volta a ser
  /// `conferindoApresentacao` com a entrada nova.
  int _geracaoDaEntrada = 0;

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
    _recuperacao?.dispose();
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

  /// Leva à recuperação de acesso, levando junto o identificador da tela de
  /// login (FR-012).
  ///
  /// Quem toca em "esqueci minha senha" costuma ter o campo já preenchido —
  /// pelo último acesso ou pela própria tentativa que acabou de falhar. Pedir
  /// de novo o que está na tela anterior desfaria a barreira que a FR-012
  /// removeu, justamente para quem já está com dificuldade.
  void _irParaRecuperacao() {
    _recuperacao?.dispose();
    setState(() {
      _recuperacao = ControladorRecuperacao(
        widget.repositorio,
        identificadorInicial: _login?.identificador ?? '',
      );
      _etapa = _Etapa.recuperacao;
    });
  }

  /// Senha trocada: a pessoa entra com a sessão que a troca emitiu.
  ///
  /// Lembrar o identificador aqui é o mesmo raciocínio do cadastro — trocar a
  /// senha é um acesso bem-sucedido, e quem acabou de recuperar a conta é
  /// exatamente quem não deveria ter que digitar o e-mail inteiro na próxima
  /// vez.
  Future<void> _recuperou(PessoaAutenticada pessoa) async {
    await widget.ultimoAcesso.lembrar(
      _recuperacao!.identificador.trim().toLowerCase(),
    );
    _etapaDeEntrada = _Etapa.volta;
    if (!mounted) return;
    _entrou(pessoa);
  }

  /// Conclusão do cadastro, que já é um acesso autenticado (FR-009).
  ///
  /// Lembrar o canal aqui é o que impede a pessoa de digitar o e-mail inteiro
  /// no primeiro login depois de criar a conta — a barreira que a FR-012 existe
  /// para remover. Deixar isso só no login criava justamente o buraco que ela
  /// deveria fechar.
  Future<void> _cadastrou(PessoaAutenticada pessoa) async {
    await widget.ultimoAcesso.lembrar(_cadastro.canal.trim().toLowerCase());
    _etapaDeEntrada = _Etapa.volta;
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

  /// A pessoa está autenticada. Antes da casca, passa pela apresentação — mas
  /// **só** se esta conta ainda não a viu (FR-013).
  ///
  /// A sessão e o monitor de inatividade valem desde já: a apresentação é
  /// tempo de sessão como qualquer outro, e celular esquecido nela expira.
  void _entrou(PessoaAutenticada pessoa) {
    _expirando = false;
    final int geracao = ++_geracaoDaEntrada;
    final ApresentacaoVista? vistas = widget.apresentacaoVista;
    setState(() {
      _pessoa = pessoa;
      _canal = widget.ultimoAcesso.identificador();
      _etapa = vistas == null ? _Etapa.dentro : _Etapa.conferindoApresentacao;
    });
    _monitor.iniciar();
    if (vistas != null) _conferirApresentacao(vistas, pessoa, geracao);
  }

  Future<void> _conferirApresentacao(
    ApresentacaoVista vistas,
    PessoaAutenticada pessoa,
    int geracao,
  ) async {
    bool jaViu;
    try {
      jaViu = await vistas.jaViu(pessoa.id);
    } catch (_) {
      // Sem conseguir ler, mostrar de novo custa uma tela pulável; não mostrar
      // seria decidir pela pessoa sem saber.
      jaViu = false;
    }
    // Ela pode ter saído, ou a sessão expirado, enquanto se lia — e outra
    // entrada pode ter começado outra conferência.
    if (!mounted ||
        geracao != _geracaoDaEntrada ||
        _etapa != _Etapa.conferindoApresentacao) {
      return;
    }
    setState(() => _etapa = jaViu ? _Etapa.dentro : _Etapa.apresentacao);
  }

  /// Sai da conta.
  ///
  /// [esquecerTudo] é o "Sair e esquecer este aparelho" de Ajustes → Conta
  /// (FR-041): além do que a saída comum leva, apaga o que só a leitura
  /// literal da FR-026 leva — o identificador do último acesso, a data de
  /// nascimento e a apresentação vista. A saída comum **não** o faz.
  Future<void> _sair({bool esquecerTudo = false}) async {
    _monitor.parar();
    await widget.repositorio.encerrarSessao();
    await widget.limpeza?.executar(esquecerTudo: esquecerTudo);
    if (!mounted) return;
    if (esquecerTudo) {
      _etapaDeEntrada = _Etapa.boasVindas;
    }
    _fecharRotasAbertas();
    _irParaLogin();
  }

  /// Conta o toque como atividade numa tela de dentro da conta que **não** é
  /// a casca: a apresentação. Sem isto, quem a lê devagar seria expulso.
  Widget _contandoAtividade(Widget tela) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _registrarAtividade(),
      child: tela,
    );
  }

  /// Uma rota aberta de dentro do fluxo.
  ///
  /// A atividade não é mais contada aqui: o `Listener` mora em volta da casca
  /// inteira e enxerga o toque em qualquer tela de qualquer pilha (R1 da 004).
  /// Antes, cada rota precisava lembrar de se envolver num — e quem conversava
  /// por 28 minutos era expulso. Num lugar só continua valendo: toda tela que
  /// o fluxo abre nasce aqui.
  Route<void> _rota({required WidgetBuilder builder}) {
    return MaterialPageRoute<void>(builder: builder);
  }

  /// Empilha [rota] no destino à vista da casca.
  ///
  /// **Nunca** no `Navigator` de fora: a tela ficaria por cima da barra
  /// inferior e fora da casca — onde sobreviveria à saída da conta.
  ///
  /// Sem casca — uma tela fora da conta, como a apresentação da US1 —, não há
  /// onde empilhar. Calar isso transformaria o toque numa porta que não abre
  /// nada (FR-003 da 003); o `assert` grita em desenvolvimento, e em produção
  /// o toque simplesmente não faz nada, em vez de derrubar o aplicativo
  /// (revisão da #38).
  void _empilhar(Route<void> rota) {
    final CascaInternaState? casca = _casca.currentState;
    assert(
      casca != null,
      '_empilhar sem casca: só há onde abrir telas com a pessoa dentro da conta',
    );
    casca?.empilhar<void>(rota);
  }

  /// Fecha o que ainda estiver por cima do fluxo no `Navigator` de fora.
  ///
  /// As telas da conta (conversa, catálogo, registro, aparência) não moram
  /// mais aqui: vivem nas pilhas da casca, e saem da árvore junto com ela
  /// quando a etapa troca (R1 da 004). O que pode sobrar no `Navigator` de
  /// fora é diálogo — e é isso que se fecha antes do login aparecer. Volta-se
  /// à rota **deste fluxo**, e não à primeira.
  void _fecharRotasAbertas() {
    final Route<dynamic>? rotaDoFluxo = ModalRoute.of(context);
    if (rotaDoFluxo == null) return;
    Navigator.of(context).popUntil((Route<dynamic> r) => r == rotaDoFluxo);
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
          _registrarAtividade();
        },
      ),
    );

    _avisoNaTela = false;
  }

  /// Conta atividade — salvo quando a sessão já está expirando.
  void _registrarAtividade() {
    if (_expirando) return;
    _monitor.registrarAtividade();
  }

  Future<void> _expirarPorInatividade() async {
    // Antes de qualquer espera: daqui em diante, nada reinicia a contagem.
    _expirando = true;
    _monitor.parar();
    await widget.repositorio.encerrarSessao();

    // A conversa sai aqui tambem, e nao so na saida deliberada. A FR-017
    // existe para o celular esquecido na mesa — e e exatamente nesse caso
    // que outra pessoa esta com o aparelho na mao. Apagar so no botao "sair"
    // protegeria justamente quem nao precisava de protecao.
    await widget.limpeza?.executar();
    if (!mounted) return;

    // Fecha o aviso antes de trocar de tela: deixá-lo aberto por cima do login
    // ofereceria um "pode continuar" que já não continua nada.
    if (_avisoNaTela) {
      Navigator.of(context).pop();
      _avisoNaTela = false;
    }
    _fecharRotasAbertas();
    _irParaLogin();
  }

  /// As portas que **de fato existem** hoje (FR-003 da 003, FR-018 da 004).
  ///
  /// Esta lista é curta de propósito, e vai crescer uma porta por entrega.
  /// Acrescentar aqui *Ajuda* antes de a tela existir daria à pessoa um botão
  /// que não abre nada — e porta que não abre é pior que porta que não existe,
  /// porque quem toca conclui que quebrou o aparelho.
  ///
  /// "Como eu vejo o Memora" **não é mais porta do Hub** (T039): a aparência é
  /// ajuste, e mora em Ajustes. Sem assistente, portanto, o Hub fica vazio — e
  /// por isso o Início nem oferece o caminho até ele ([_abrirHub]).
  List<PortaDoHub> _portasConstruidas() {
    final RepositorioAssistente? assistente = widget.assistente;
    if (assistente == null) return const <PortaDoHub>[];

    return <PortaDoHub>[
      // A ação principal do Hub: é a conversa a razão de o Memora existir.
      PortaDoHub(
        rotulo: TextosAssistente.portaConversa,
        descricao: TextosAssistente.descricaoConversa,
        ilustracao: Ilustracao.portaConversa,
        principal: true,
        aoAbrir: () => _abrirConversa(assistente),
      ),
      PortaDoHub(
        rotulo: TextosAssistente.portaAplicativos,
        descricao: TextosAssistente.descricaoAplicativos,
        ilustracao: Ilustracao.portaAplicativos,
        aoAbrir: () => _abrirCatalogo(assistente, CategoriaDoServico.cotidiano),
      ),
      PortaDoHub(
        rotulo: TextosAssistente.portaServicos,
        descricao: TextosAssistente.descricaoServicos,
        ilustracao: Ilustracao.portaServicos,
        aoAbrir: () => _abrirCatalogo(assistente, CategoriaDoServico.sensivel),
      ),
      PortaDoHub(
        rotulo: TextosAssistente.portaRegistro,
        descricao: TextosAssistente.descricaoRegistro,
        ilustracao: Ilustracao.portaRegistro,
        aoAbrir: () => _empilhar(
          _rota(
            builder: (BuildContext contexto) => TelaRegistro(
              repositorio: assistente,
              aoVoltar: () => Navigator.of(contexto).pop(),
            ),
          ),
        ),
      ),
      // A Ajuda (T090, FR-033). Fica dentro deste bloco porque a ajuda guiada
      // sai direto para a conversa (FR-034): sem assistente, ela levaria a
      // lugar nenhum — e o Hub sem assistente continua vazio.
      PortaDoHub(
        rotulo: TextosAssistente.portaAjuda,
        descricao: TextosAssistente.descricaoAjuda,
        ilustracao: Ilustracao.portaAjuda,
        aoAbrir: () => _abrirAjuda(assistente),
      ),
    ];
  }

  /// A Ajuda, com os assuntos que existem agora (T087, FR-033).
  void _abrirAjuda(RepositorioAssistente assistente) {
    final Compartilhador? compartilhador = widget.compartilhador;
    final ApresentacaoVista? vistas = widget.apresentacaoVista;
    _empilhar(
      _rota(
        builder: (BuildContext contexto) => TelaAjuda(
          assuntos: AssuntoDeAjuda.disponiveis(
            podeCompartilhar: compartilhador != null,
          ),
          aoAbrirAssunto: (AssuntoDeAjuda assunto) =>
              _abrirAssunto(assunto, assistente),
          // Rever a apresentação (FR-013) precisa de onde ela é guardada e de
          // quem é a pessoa: sem isso a porta não existe (FR-018).
          aoVerApresentacao: vistas == null || _pessoa == null
              ? null
              : () => _reverApresentacao(vistas),
          aoVoltar: () => Navigator.of(contexto).pop(),
        ),
      ),
    );
  }

  /// Abre um assunto da Ajuda. "A conversa" é a ajuda guiada; os outros, uma
  /// ideia por tela.
  void _abrirAssunto(AssuntoDeAjuda assunto, RepositorioAssistente assistente) {
    _empilhar(
      _rota(
        builder: (BuildContext contexto) => switch (assunto.id) {
          IdDoAssunto.conversa => AjudaGuiadaDaConversa(
            // Direto para a conversa de verdade (FR-034): a ajuda guiada sai da
            // pilha e a conversa entra no lugar, sem tela no meio e sem deixar
            // a ajuda guiada por baixo — "Voltar" da conversa leva à Ajuda.
            aoConversar: () {
              Navigator.of(contexto).pop();
              _abrirConversa(assistente);
            },
            aoVoltar: () => Navigator.of(contexto).pop(),
          ),
          _ => TelaAssunto(
            assunto: assunto,
            compartilhador: widget.compartilhador,
            aoVoltar: () => Navigator.of(contexto).pop(),
          ),
        },
      ),
    );
  }

  /// A apresentação outra vez, a partir da Ajuda (FR-013).
  ///
  /// É a mesma [FluxoApresentacao] da primeira entrada, empilhada na casca: ao
  /// fim ou ao "Pular" ela sai da pilha e a pessoa está de volta na Ajuda.
  void _reverApresentacao(ApresentacaoVista vistas) {
    _empilhar(
      _rota(
        builder: (BuildContext contexto) => FluxoApresentacao(
          nome: _pessoa?.nomeTratamento ?? '',
          idDaConta: _pessoa!.id,
          vista: vistas,
          aoConcluir: () => Navigator.of(contexto).pop(),
        ),
      ),
    );
  }

  /// Abre o Hub por cima do Início (T040).
  void _abrirHub() {
    _empilhar(
      _rota(
        builder: (BuildContext contexto) => TelaHub(
          portas: _portasConstruidas(),
          aoVoltar: () => Navigator.of(contexto).pop(),
        ),
      ),
    );
  }

  /// Abre o catálogo de uma categoria.
  ///
  /// Uma tela só serve às duas portas: elas mostram a mesma coisa com uma regra
  /// diferente, e duas telas quase iguais divergem na primeira melhoria feita
  /// em uma delas.
  void _abrirCatalogo(
    RepositorioAssistente assistente,
    CategoriaDoServico categoria,
  ) {
    _empilhar(
      _rota(
        builder: (BuildContext contexto) => TelaCatalogo(
          repositorio: assistente,
          categoria: categoria,
          // Se o item tiver guia de passo a passo embarcado, abre o guia;
          // caso contrário, vai para a conversa já perguntando (T069, FR-027).
          aoAbrirGuia: (Guia guia, ServicoDoCatalogo servico) => _abrirGuia(
            guia: guia,
            servico: servico,
            assistente: assistente,
          ),
          aoEscolher: (ServicoDoCatalogo servico) => _abrirConversa(
            assistente,
            rascunho: TextosAssistente.perguntaSobre(servico.nomeExibido),
          ),
          aoVoltar: () => Navigator.of(contexto).pop(),
        ),
      ),
    );
  }

  /// Abre o guia de aprendizado passo a passo (FR-027).
  void _abrirGuia({
    required Guia guia,
    required ServicoDoCatalogo servico,
    required RepositorioAssistente assistente,
  }) {
    _empilhar(
      _rota(
        builder: (BuildContext contexto) => TelaPassoAPasso(
          guia: guia,
          servico: servico,
          repositorioAssistente: assistente,
          progresso: widget.progresso,
          idDaConta: _pessoa?.id,
          aoPedirParaAbrir: (String pedido) => _abrirConversa(
            assistente,
            rascunho: pedido,
          ),
          aoConversarSobreDiferenca: () => _abrirConversa(
            assistente,
            rascunho: TextosAssistente.perguntaSobre(servico.nomeExibido),
          ),
          aoVoltar: () => Navigator.of(contexto).pop(),
          aoVoltarAoHub: () => Navigator.of(contexto).pop(),
          aoSair: () => Navigator.of(contexto).pop(),
        ),
      ),
    );
  }

  /// Abre a conversa, opcionalmente com uma pergunta já escrita.
  ///
  /// A pergunta fica no campo e não é enviada: quem envia é a pessoa.
  void _abrirConversa(
    RepositorioAssistente assistente, {
    String rascunho = '',
  }) {
    _empilhar(
      _rota(
        // Quem cria é dono: o controlador nasce e morre com a rota, e não
        // sobra cronômetro nem resposta em voo depois de a pessoa sair da
        // tela — ou da conta (FR-048).
        builder: (BuildContext contexto) => _DonaDaConversa(
          aoAbrir: _conversasAbertas.add,
          aoFechar: _conversasAbertas.remove,
          criar: () => ControladorConversa(
            assistente,
            widget.conversaLocal(),
            abridor: widget.abridor,
            rascunhoInicial: rascunho,
          ),
          aoVoltar: () => Navigator.of(contexto).pop(),
        ),
      ),
    );
  }

  /// As conversas abertas agora, em qualquer pilha da casca.
  ///
  /// Quem apaga a conversa em Privacidade precisa apagá-la também **da tela**:
  /// uma conversa aberta no Início guarda as mensagens na memória, e a
  /// próxima pergunta as regravaria no aparelho — desfazendo o apagar.
  final List<ControladorConversa> _conversasAbertas = <ControladorConversa>[];

  /// Apaga a conversa do aparelho e das telas que a estejam mostrando (T094).
  Future<void> _apagarConversa() async {
    // Primeiro as telas: o `_envio++` de cada controlador é síncrono e
    // invalida o que está em voo. Se o arquivo fosse apagado antes, uma
    // gravação em andamento poderia recriá-lo com a conversa antiga.
    for (final ControladorConversa c in List<ControladorConversa>.of(
      _conversasAbertas,
    )) {
      await c.apagarConversa();
    }
    // Por último o arquivo, e uma falha aqui SOBE para a tela de Privacidade.
    await widget.conversaLocal().apagar();
  }

  /// A tela de aparência, e a de acessibilidade, que dividem a mesma tela.
  void _abrirAjusteVisual(GrupoDeAjusteVisual grupo) {
    _empilhar(
      _rota(
        builder: (BuildContext contexto) => TelaAparencia(
          titulo: switch (grupo) {
            GrupoDeAjusteVisual.aparencia => TextosConfiguracoes.portaAparencia,
            GrupoDeAjusteVisual.acessibilidade =>
              TextosConfiguracoes.portaAcessibilidade,
          },
          grupo: grupo,
          aoVoltar: () => Navigator.of(contexto).pop(),
        ),
      ),
    );
  }

  void _abrirPrivacidade() {
    _empilhar(
      _rota(
        builder: (BuildContext contexto) => TelaPrivacidade(
          aoApagarConversa: _apagarConversa,
          aoVoltar: () => Navigator.of(contexto).pop(),
        ),
      ),
    );
  }

  void _abrirConta() {
    _empilhar(
      _rota(
        builder: (BuildContext contexto) => TelaConta(
          canal: _canal,
          aoSair: _sair,
          aoSairEEsquecer: () => _sair(esquecerTudo: true),
          aoVoltar: () => Navigator.of(contexto).pop(),
        ),
      ),
    );
  }

  /// A galeria, só no modo de desenvolvimento (R9 da 002). Fora dele, nulo —
  /// e a linha que levaria a ela não existe.
  VoidCallback? get _abrirGaleria {
    final Widget? galeria = GaleriaMemora.paraDesenvolvimento();
    if (galeria == null) return null;
    return () => _empilhar(
      _rota(
        builder: (BuildContext contexto) => Scaffold(
          appBar: BarraSuperior(
            titulo: 'Galeria',
            aoVoltar: () => Navigator.of(contexto).pop(),
          ),
          body: galeria,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (_etapa) {
      _Etapa.boasVindas => TelaBoasVindas(
        aoComecar: () => setState(() => _etapa = _Etapa.cadastro),
        aoJaTerConta: _irParaLogin,
      ),
      _Etapa.volta => TelaDeVolta(
        aoEntrar: _irParaLogin,
        aoCriarConta: () => setState(() => _etapa = _Etapa.cadastro),
      ),
      _Etapa.cadastro => TelaCadastro(
        controlador: _cadastro,
        aoVoltar: () => setState(() => _etapa = _etapaDeEntrada),
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
        aoVoltar: () => setState(() => _etapa = _etapaDeEntrada),
        aoEntrar: _entrou,
        aoRecuperar: _irParaRecuperacao,
        aoPrimeiroAcesso: () => setState(() => _etapa = _Etapa.cadastro),
      ),
      _Etapa.recuperacao => TelaRecuperacao(
        controlador: _recuperacao!,
        aoVoltar: () => setState(() => _etapa = _Etapa.login),
        aoConcluir: _recuperou,
      ),
      _Etapa.conferindoApresentacao => _contandoAtividade(
        const TelaPreparandoApresentacao(),
      ),
      _Etapa.apresentacao => _contandoAtividade(
        FluxoApresentacao(
          nome: _pessoa?.nomeTratamento ?? '',
          idDaConta: _pessoa!.id,
          vista: widget.apresentacaoVista!,
          aoConcluir: () => setState(() => _etapa = _Etapa.dentro),
        ),
      ),
      // A casca é quem conta a atividade: um `Listener` em volta dela inteira,
      // inclusive das telas empilhadas (R1 da 004). Qualquer toque adia a
      // expiração — inclusive rolar, que é de quem está lendo.
      _Etapa.dentro => CascaInterna(
        key: _casca,
        aoRegistrarAtividade: _registrarAtividade,
        raizes: <DestinoDaCasca, WidgetBuilder>{
          DestinoDaCasca.ajustes: (BuildContext _) => TelaConfiguracoes(
            aoAbrirAparencia: () =>
                _abrirAjusteVisual(GrupoDeAjusteVisual.aparencia),
            aoAbrirAcessibilidade: () =>
                _abrirAjusteVisual(GrupoDeAjusteVisual.acessibilidade),
            aoAbrirPrivacidade: _abrirPrivacidade,
            aoAbrirConta: _abrirConta,
            aoAbrirGaleria: _abrirGaleria,
          ),
          // O Início é a raiz, e o Hub se empilha sobre ele (T040). Cada
          // atalho só existe se leva a algum lugar (FR-018): sem assistente
          // não há conversa, e o Hub ficaria sem nenhuma porta.
          DestinoDaCasca.inicio: (BuildContext _) => TelaInicio(
            nome: _pessoa?.nomeTratamento ?? '',
            aoConversar: widget.assistente == null
                ? null
                : () => _abrirConversa(widget.assistente!),
            aoVerTudo: _portasConstruidas().isEmpty ? null : _abrirHub,
          ),
          DestinoDaCasca.perfil: (BuildContext _) => PerfilProvisorio(
            nome: _pessoa?.nomeTratamento ?? '',
            canal: _canal,
            dataDeNascimento: _datas,
            idDaConta: _pessoa?.id,
          ),
        },
      ),
    };
  }
}

/// Cria o [ControladorConversa] e o descarta quando a rota sai.
///
/// O `State` só é destruído depois da animação de saída, então a tela nunca
/// reconstrói sobre um controlador já descartado.
class _DonaDaConversa extends StatefulWidget {
  final ControladorConversa Function() criar;
  final VoidCallback aoVoltar;

  /// Avisam o fluxo de que há uma conversa aberta, e de quando ela fecha.
  final void Function(ControladorConversa) aoAbrir;
  final void Function(ControladorConversa) aoFechar;

  const _DonaDaConversa({
    required this.criar,
    required this.aoVoltar,
    required this.aoAbrir,
    required this.aoFechar,
  });

  @override
  State<_DonaDaConversa> createState() => _DonaDaConversaState();
}

class _DonaDaConversaState extends State<_DonaDaConversa> {
  late final ControladorConversa _controlador = widget.criar();

  @override
  void initState() {
    super.initState();
    widget.aoAbrir(_controlador);
  }

  @override
  void dispose() {
    widget.aoFechar(_controlador);
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TelaConversa(controlador: _controlador, aoVoltar: widget.aoVoltar);
  }
}

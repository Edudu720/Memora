import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../../features/aprendizado/domain/guia.dart';
import '../design_system.dart';

/// A galeria do Design System — T045, FR-033 e R9.
///
/// ## Para que ela serve
///
/// Documentação viva: todo componente, em todos os estados, nos três temas e
/// em toda a faixa de ampliação de texto. É o lugar onde se descobre que um
/// estado ficou feio **antes** de ele chegar numa tela real, e é o checklist
/// visual da revisão — "este componente existe? em que estados?" tem resposta
/// em um lugar só.
///
/// ## Por que não é Storybook
///
/// A R9 recusou: uma dependência a mais e um segundo ambiente de execução. A
/// galeria roda no mesmo motor do aplicativo de verdade, então o que se vê
/// aqui é o que a pessoa vê. Um catálogo que renderiza diferente do produto é
/// pior que catálogo nenhum, porque ele mente com autoridade.
///
/// ## Só em build de desenvolvimento
///
/// [paraDesenvolvimento] devolve `null` fora do modo de depuração. Quem
/// oferece o caminho até aqui precisa lidar com esse `null` — e o resultado
/// é que, num build de release, **não existe botão** que leve à galeria, em
/// vez de existir um botão que leva a uma recusa.
class GaleriaMemora extends StatefulWidget {
  /// Cria a galeria.
  const GaleriaMemora({super.key});

  /// A galeria, ou `null` num build que não é de desenvolvimento.
  static Widget? paraDesenvolvimento() =>
      kDebugMode ? const GaleriaMemora() : null;

  @override
  State<GaleriaMemora> createState() => _GaleriaMemoraState();
}

class _GaleriaMemoraState extends State<GaleriaMemora> {
  MemoraTemaId _tema = MemoraTemaId.claro;
  double _escala = MemoraDimensoes.escalaTextoMin;

  final TextEditingController _texto = TextEditingController(text: 'Ana Maria');
  final TextEditingController _senha = TextEditingController();
  final TextEditingController _codigo = TextEditingController();

  bool _opcaoMarcada = true;
  int _abaAtiva = 0;
  int _filtroAtivo = 0;
  String _ultimoToque = 'nenhum';

  @override
  void dispose() {
    _texto.dispose();
    _senha.dispose();
    _codigo.dispose();
    super.dispose();
  }

  void _tocou(String o) => setState(() => _ultimoToque = o);

  @override
  Widget build(BuildContext context) {
    // A galeria troca o tema **só para dentro dela**. Trocar a preferência
    // real do aplicativo faria o visitante sair daqui com a aparência mudada
    // sem ter pedido — e a `TelaAparencia`, que é a forma legítima de mudar,
    // está listada aqui embaixo como mais um componente.
    final ThemeData tema = TemasMemora.porId(_tema);

    return Theme(
      data: tema,
      child: Builder(
        builder: (BuildContext context) {
          final MemoraCores cores = context.memora.cores;

          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(_escala),
            ),
            child: Scaffold(
              backgroundColor: cores.fundo,
              body: SafeArea(
                child: Column(
                  children: <Widget>[
                    // `Flexible` com `Expanded` embaixo, e nao um filho fixo:
                    // a faixa de controles cresce com a ampliacao, e em 200%
                    // ela estourava a tela por 18 px. Medida absoluta nao sabe
                    // quanto de tela existe — a mesma licao que a revisao da
                    // PR #27 deixou, agora dentro da propria galeria.
                    //
                    // Com flex 1 contra 2, os controles ficam em no maximo um
                    // terco da altura e rolam por dentro depois disso.
                    Flexible(
                      child: SingleChildScrollView(
                        child: _Controles(
                          tema: _tema,
                          escala: _escala,
                          aoTrocarTema: (MemoraTemaId t) =>
                              setState(() => _tema = t),
                          aoTrocarEscala: (double e) =>
                              setState(() => _escala = e),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: ListView(
                        padding: const EdgeInsets.all(MemoraEspacamento.lg),
                        children: _secoes(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _secoes(BuildContext context) {
    return <Widget>[
      const _Secao('Texto', 'Cinco estilos, e nada fora deles.'),
      const TextoMemora.tituloTela('Título de tela'),
      const SizedBox(height: MemoraEspacamento.sm),
      const TextoMemora.tituloSecao('Título de seção'),
      const SizedBox(height: MemoraEspacamento.sm),
      const TextoMemora('Corpo — o texto comum, que a pessoa lê para entender '
          'o que está acontecendo.'),
      const SizedBox(height: MemoraEspacamento.sm),
      const TextoMemora('Corpo forte', estilo: EstiloTexto.corpoForte),
      const SizedBox(height: MemoraEspacamento.sm),
      const TextoMemora.apoio('Apoio — explica, sem competir com o corpo.'),
      const SizedBox(height: MemoraEspacamento.sm),
      const TextoComDestaque(
        'Destaque dentro da frase: o código é *482913* e ele vence hoje.',
      ),

      const _Secao('Ação', 'Pílula e preenchimento. Informação nunca usa '
          'nenhum dos dois — é assim que dá para saber, de longe, o que '
          'responde ao toque.'),
      BotaoPrimario(rotulo: 'Continuar', aoTocar: () => _tocou('primário')),
      const SizedBox(height: MemoraEspacamento.md),
      BotaoPrimario(
        rotulo: 'Continuar com ícone',
        icone: Icons.arrow_forward,
        aoTocar: () => _tocou('primário com ícone'),
      ),
      const SizedBox(height: MemoraEspacamento.md),
      const BotaoPrimario(rotulo: 'Enviando...', carregando: true),
      const SizedBox(height: MemoraEspacamento.md),
      const BotaoPrimario(rotulo: 'Desabilitado'),
      const SizedBox(height: MemoraEspacamento.md),
      BotaoSecundario(rotulo: 'Voltar', aoTocar: () => _tocou('secundário')),
      const SizedBox(height: MemoraEspacamento.md),
      const BotaoSecundario(rotulo: 'Secundário desabilitado'),
      const SizedBox(height: MemoraEspacamento.md),
      BotaoTerciario(
        rotulo: 'Agora não',
        aoTocar: () => _tocou('terciário'),
      ),
      const SizedBox(height: MemoraEspacamento.md),
      BotaoPerigo(
        rotulo: 'Apagar minha conta',
        icone: Icons.delete_outline,
        aoTocar: () => _tocou('perigo'),
      ),
      const SizedBox(height: MemoraEspacamento.md),
      _UltimoToque(valor: _ultimoToque),

      const _Secao('Informação', 'Sem pílula, sem preenchimento e **sem '
          'callback de toque**: a ausência de API é o que garante que um dado '
          'não vire botão por engano.'),
      ListaInformacao(
        titulo: 'Seus dados',
        campos: const <CampoInformacao>[
          CampoInformacao(rotulo: 'Nome', valor: 'Ana Maria Ferreira'),
          CampoInformacao(
            rotulo: 'E-mail',
            valor: 'ana.maria@email.com',
            icone: Icons.mail_outline,
          ),
        ],
      ),
      const SizedBox(height: MemoraEspacamento.md),
      const DestaqueInformacao(
        rotulo: 'Seu código',
        valor: '482913',
        icone: Icons.vpn_key_outlined,
      ),

      const _Secao('Campos', 'Normal, com erro, senha e código.'),
      CampoTexto(
        rotulo: 'Como posso te chamar?',
        textoAjuda: 'É assim que eu vou falar com você',
        controlador: _texto,
      ),
      const SizedBox(height: MemoraEspacamento.lg),
      const CampoTexto(
        rotulo: 'Seu e-mail',
        textoAjuda: 'Usamos para você entrar',
        erro: 'Faltou o @ nesse endereço',
      ),
      const SizedBox(height: MemoraEspacamento.lg),
      const CampoTexto(
        rotulo: 'Campo desabilitado',
        textoAjuda: 'Não dá para digitar agora',
        habilitado: false,
      ),
      const SizedBox(height: MemoraEspacamento.lg),
      CampoSenha(
        rotulo: 'Crie uma senha',
        textoAjuda: 'Pelo menos 8 letras ou números',
        controlador: _senha,
      ),
      const SizedBox(height: MemoraEspacamento.lg),
      const CampoSenha(
        rotulo: 'Senha sem olhinho (FR-060)',
        textoAjuda: 'No cadastro assistido não há como revelar',
        permitirRevelar: false,
      ),
      const SizedBox(height: MemoraEspacamento.lg),
      CampoCodigo(
        rotulo: 'Digite o código que chegou',
        textoAjuda: 'São 6 números',
        controlador: _codigo,
      ),

      const _Secao('Seleção'),
      OpcaoSelecionavel(
        rotulo: 'Tem alguém te ajudando agora?',
        descricao: 'Toque aqui se um filho ou neto estiver junto',
        selecionada: _opcaoMarcada,
        aoSelecionar: () => setState(() => _opcaoMarcada = !_opcaoMarcada),
      ),
      const SizedBox(height: MemoraEspacamento.md),
      OpcaoSelecionavel(
        rotulo: 'Sem descrição',
        selecionada: !_opcaoMarcada,
        aoSelecionar: () => setState(() => _opcaoMarcada = !_opcaoMarcada),
      ),

      const _Secao('Confirmação', 'A variante irreversível tem tom grave, e '
          'reservá-lo ao que é de fato irreversível é o que faz esse tom '
          'continuar significando alguma coisa.'),
      ConfirmacaoMemora(
        pergunta: 'Quer mesmo sair da sua conta?',
        aviso: 'Você vai precisar da senha para voltar',
        rotuloConfirmar: 'Sim, sair',
        rotuloRecusar: 'Ficar',
        aoConfirmar: () => _tocou('saiu'),
        aoRecusar: () => _tocou('ficou'),
      ),
      const SizedBox(height: MemoraEspacamento.lg),
      ConfirmacaoMemora.irreversivel(
        pergunta: 'Apagar sua conta para sempre?',
        aviso: 'Isso não tem como ser desfeito',
        rotuloConfirmar: 'Apagar tudo',
        rotuloRecusar: 'Não apagar',
        aoConfirmar: () => _tocou('apagou'),
        aoRecusar: () => _tocou('desistiu'),
      ),

      const _Secao('Retorno ao usuário'),
      const Carregando(mensagem: 'Estou pensando...'),
      const SizedBox(height: MemoraEspacamento.lg),
      MensagemErro(
        mensagem: 'Não consegui falar com a internet agora.',
        aoTentarNovamente: () => _tocou('tentou de novo'),
      ),
      const SizedBox(height: MemoraEspacamento.lg),
      const MensagemErro(mensagem: 'Erro sem botão de tentar de novo.'),
      const SizedBox(height: MemoraEspacamento.lg),
      EstadoVazio(
        titulo: 'Nenhuma conversa ainda',
        explicacao: 'Quando você me perguntar alguma coisa, ela aparece aqui.',
        icone: Icons.chat_bubble_outline,
        rotuloAcao: 'Conversar com a Memora',
        aoAgir: () => _tocou('foi conversar'),
      ),
      const SizedBox(height: MemoraEspacamento.lg),
      const EstadoVazio(
        titulo: 'Estado vazio sem ação',
        explicacao: 'Nem todo vazio tem para onde mandar a pessoa.',
        icone: Icons.folder_open_outlined,
      ),

      const _Secao('Cartões e ilustração'),
      const Cartao(child: TextoMemora('Um cartão comum.')),
      const SizedBox(height: MemoraEspacamento.lg),
      const CartaoComAvatar(
        child: TextoMemora('Um cartão com a Memora ao lado, que é como ela '
            'aparece quando está falando com você.'),
      ),
      const SizedBox(height: MemoraEspacamento.lg),
      const Row(
        children: <Widget>[
          AvatarMemora(tamanho: MemoraDimensoes.iconeEstadoVazio),
          SizedBox(width: MemoraEspacamento.lg),
          IlustracaoMemora(
            Ilustracao.pessoaComCelular,
            altura: MemoraDimensoes.iconeCelebracao,
            descricao: 'Pessoa segurando um celular',
          ),
        ],
      ),

      const _Secao('Caixa de etapa', 'Uma por etapa: a frase do que fazer no '
          'topo, e embaixo o que se toca. É informação — a caixa não responde '
          'ao toque, só o que está dentro dela.'),
      const CaixaDeEtapa(
        instrucao: 'Escreva aqui o seu e-mail',
        child: CampoTexto(
          rotulo: 'Seu e-mail',
          textoAjuda: 'Usamos para você entrar',
        ),
      ),
      const SizedBox(height: MemoraEspacamento.md),
      const CaixaDeEtapa(
        instrucao: 'Leia com calma, e só depois siga em frente',
        child: TextoMemora('Uma caixa também guarda uma explicação, sem '
            'nenhum campo dentro dela.'),
      ),

      const _Secao(
        'A Memora e as ilustrações',
        'O rosto dela em seis expressões PNG oficiais, e as ilustrações '
            'coloridas sempre sobre o medalhão claro — nos três temas.',
      ),
      Wrap(
        spacing: MemoraEspacamento.md,
        runSpacing: MemoraEspacamento.md,
        children: <Widget>[
          for (final ExpressaoDaMemora e in ExpressaoDaMemora.values)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                MemoraPersonagem(expressao: e),
                const SizedBox(height: MemoraEspacamento.xs),
                TextoMemora.apoio(e.name),
              ],
            ),
        ],
      ),
      const SizedBox(height: MemoraEspacamento.lg),
      const Wrap(
        spacing: MemoraEspacamento.md,
        runSpacing: MemoraEspacamento.md,
        children: <Widget>[
          MedalhaoDeIlustracao(
            Ilustracao.portaConversa,
            tamanho: MemoraDimensoes.ilustracaoCartao,
          ),
          MedalhaoDeIlustracao(
            Ilustracao.portaAplicativos,
            tamanho: MemoraDimensoes.ilustracaoCartao,
          ),
          MedalhaoDeIlustracao(
            Ilustracao.portaServicos,
            tamanho: MemoraDimensoes.ilustracaoCartao,
          ),
          MedalhaoDeIlustracao(
            Ilustracao.portaAjuda,
            tamanho: MemoraDimensoes.ilustracaoCartao,
          ),
          MedalhaoDeIlustracao(
            Ilustracao.portaRegistro,
            tamanho: MemoraDimensoes.ilustracaoCartao,
          ),
          MedalhaoDeIlustracao(
            Ilustracao.estadoVazio,
            tamanho: MemoraDimensoes.ilustracaoCartao,
          ),
          MedalhaoDeIlustracao(
            Ilustracao.estadoErro,
            tamanho: MemoraDimensoes.ilustracaoCartao,
          ),
          MedalhaoDeIlustracao(
            Ilustracao.aplicativoGenerico,
            tamanho: MemoraDimensoes.ilustracaoCartao,
          ),
        ],
      ),
      const SizedBox(height: MemoraEspacamento.lg),
      const Wrap(
        spacing: MemoraEspacamento.md,
        runSpacing: MemoraEspacamento.md,
        children: <Widget>[
          IconeDoAplicativo(chave: 'whatsapp'),
          IconeDoAplicativo(chave: 'facebook'),
          IconeDoAplicativo(chave: 'instagram'),
          IconeDoAplicativo(chave: 'youtube'),
          IconeDoAplicativo(chave: 'google-fotos'),
          IconeDoAplicativo(chave: 'telegram'),
          IconeDoAplicativo(chave: 'gov-br'),
          IconeDoAplicativo(chave: 'meu-inss'),
        ],
      ),

      const _Secao('Portas', 'Ação, então pílula e preenchimento — e não '
          'cartão. No máximo uma principal por tela. A desabilitada só existe '
          'aqui: porta que não abre não é mostrada (FR-018).'),
      CartaoDePorta(
        nome: 'Conversar com a Memora',
        explicacao: 'Pergunte do seu jeito, que eu te mostro o caminho',
        ilustracao: Ilustracao.portaConversa,
        principal: true,
        aoAbrir: () => _tocou('porta principal'),
      ),
      const SizedBox(height: MemoraEspacamento.md),
      CartaoDePorta(
        nome: 'Meus aplicativos',
        explicacao: 'Aprender a usar os aplicativos do dia a dia',
        ilustracao: Ilustracao.portaAplicativos,
        aoAbrir: () => _tocou('porta'),
      ),
      const SizedBox(height: MemoraEspacamento.md),
      const CartaoDePorta(
        nome: 'Porta desabilitada',
        explicacao: 'Assim ela apareceria, se aparecesse',
        ilustracao: Ilustracao.portaAjuda,
        aoAbrir: null,
      ),

      const _Secao('Avisos', 'Sempre na tela, sem tomar a tela. Toque em '
          '"Ler o aviso inteiro".'),
      const AvisoCompacto(
        titulo: 'O Memora nunca pede a sua senha',
        resumo: 'Nem por mensagem, nem por ligação.',
        textoCompleto: 'Se alguém ligar dizendo ser do Memora e pedir a sua '
            'senha ou o número que chegou no seu celular, desligue. Ninguém do '
            'Memora pede isso, nunca.',
      ),
      const SizedBox(height: MemoraEspacamento.md),
      const AvisoCompacto(
        titulo: 'Aviso sem a Memora',
        resumo: 'Com o escudo no lugar do rosto.',
        textoCompleto: 'Para os lugares onde o rosto dela já está na tela.',
        comMemora: false,
      ),
      const SizedBox(height: MemoraEspacamento.md),
      const AvisoCompacto(
        titulo: 'Aviso só com o escudo',
        resumo: 'Eu nunca peço sua senha nem código.',
        textoCompleto: 'Fechado, é só o escudo num canto (48 dp): o resumo vai '
            'no rótulo para o leitor de tela. Toque para ler o aviso inteiro.',
        comMemora: false,
        fechadoSoEscudo: true,
      ),

      const _Secao('Conversa', 'Quem disse é dito por posição, rosto e nome — '
          'nunca só pela cor.'),
      BalaoDeFala(
        autor: AutorDoBalao.memora,
        // O que está entre `**` vai em negrito (FR-020a): o nome do aplicativo.
        texto: 'Quer que eu abra o **WhatsApp** para você?',
        opcoes: <OpcaoDoBalao>[
          OpcaoDoBalao(
            rotulo: 'Sim, pode abrir',
            aoEscolher: () => _tocou('sim'),
          ),
          const OpcaoDoBalao(
            rotulo: 'Opção já escolhida',
            aoEscolher: null,
          ),
        ],
      ),
      const SizedBox(height: MemoraEspacamento.md),
      const BalaoDeFala(
        autor: AutorDoBalao.pessoa,
        texto: 'Não consegui abrir.',
      ),
      const SizedBox(height: MemoraEspacamento.md),
      const BalaoDeFala.escrevendo(),

      const _Secao(
        'Passo a passo',
        'Guia ilustrado com moldura, destaque, selo de exemplo e indicador textual.',
      ),
      const IndicadorDePasso(posicao: 2, total: 4),
      const SizedBox(height: MemoraEspacamento.md),
      PassoIlustrado(
        passo: const Passo(
          captura: CapturaDoGuia.lojaOficial,
          destaque: RegiaoRelativa(x: 0.2, y: 0.3, largura: 0.6, altura: 0.2),
          texto: 'Toque no botão de pesquisa no canto superior.',
          descricaoDaCaptura: 'Tela inicial do aplicativo com a lupa no topo.',
        ),
        posicao: 2,
        total: 4,
        aoContinuar: () {},
        aoVoltar: () {},
        aoTelaDiferente: () {},
      ),
      const SizedBox(height: MemoraEspacamento.lg),

      const _Secao('Sobreposições', 'Diálogo e folha inferior abrem por cima '
          'do conteúdo — toque para ver.'),
      BotaoSecundario(
        rotulo: 'Abrir diálogo',
        aoTocar: () => DialogoMemora.mostrar(
          context,
          dialogo: DialogoMemora(
            titulo: 'Tudo certo!',
            mensagem: 'Sua senha nova já está valendo.',
            rotuloConfirmar: 'Entendi',
            aoConfirmar: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      const SizedBox(height: MemoraEspacamento.md),
      BotaoSecundario(
        rotulo: 'Abrir folha inferior',
        aoTocar: () => FolhaInferior.mostrar(
          context,
          folha: const FolhaInferior(
            titulo: 'Como eu te ajudo',
            child: TextoMemora('Eu mostro o caminho. Quem faz é você — assim, '
                'da próxima vez, você consegue sozinha.'),
          ),
        ),
      ),

      const _Secao('Navegação'),
      CabecalhoDeTela(
        titulo: 'Cabeçalho com voltar e a Memora',
        aoVoltar: () => _tocou('voltou'),
        memora: ExpressaoDaMemora.neutra,
      ),
      const CabecalhoDeTela(
        titulo: 'Cabeçalho na raiz, com ilustração',
        ilustracao: Ilustracao.portaAjuda,
      ),
      const BarraSuperior(titulo: 'Barra sem voltar'),
      const SizedBox(height: MemoraEspacamento.md),
      BarraSuperior(titulo: 'Barra com voltar', aoVoltar: () => _tocou('voltou')),
      const SizedBox(height: MemoraEspacamento.lg),
      NavegacaoInferior(
        itens: const <ItemNavegacao>[
          ItemNavegacao(icone: IconeDeNavegacao.ajustes, rotulo: 'Ajustes'),
          ItemNavegacao(icone: IconeDeNavegacao.inicio, rotulo: 'Início'),
          ItemNavegacao(icone: IconeDeNavegacao.perfil, rotulo: 'Meu perfil'),
        ],
        indiceAtivo: _abaAtiva,
        aoSelecionar: (int i) => setState(() => _abaAtiva = i),
      ),

      const _Secao(
        'Blocos Memora 2.0',
        'PainelHeroi e BadgeDeStatus são passivos (002/FR-012); CartaoHeroi, '
            'TileAcaoRapida e ChipFiltro são acionáveis com pista explícita.',
      ),
      PainelHeroi(
        titulo: 'Frequência cardíaca',
        valorDestaque: '74 bpm',
        subtitulo: 'Última leitura hoje às 10:15',
        badgeStatus: const BadgeDeStatus(
          rotulo: 'Relógio conectado',
          icone: Icons.watch_rounded,
          tom: TomBadgeStatus.positivo,
        ),
        visualEsquerda: MemoraPersonagem(
          expressao: ExpressaoDaMemora.neutra,
          tamanho: MemoraDimensoes.alvoDecisao,
        ),
      ),
      const SizedBox(height: MemoraEspacamento.md),
      CartaoHeroi(
        titulo: 'Conversar com a Memora',
        subtitulo: 'Tire dúvidas com calma, passo a passo',
        rotuloAcao: 'Começar conversa',
        icone: Icons.chat_bubble_outline_rounded,
        visualEsquerda: const MemoraPersonagem(
          expressao: ExpressaoDaMemora.falando,
          tamanho: MemoraDimensoes.alvoDecisao,
        ),
        aoTocar: () => _tocou('heroi'),
      ),
      const SizedBox(height: MemoraEspacamento.md),
      if (_escala >= MemoraDimensoes.escalaTextoAlta) ...<Widget>[
        TileAcaoRapida(
          icone: Icons.apps_rounded,
          titulo: 'Aplicativos',
          subtitulo: 'Guias práticos',
          variacao: VarianteBadge.primario,
          pistaAcao: 'Explorar',
          aoTocar: () => _tocou('tile_primario'),
        ),
        const SizedBox(height: MemoraEspacamento.md),
        TileAcaoRapida(
          icone: Icons.favorite_outline_rounded,
          titulo: 'Cuidado',
          subtitulo: 'Relógio e avisos',
          variacao: VarianteBadge.saude,
          pistaAcao: 'Ver saúde',
          aoTocar: () => _tocou('tile_saude'),
        ),
      ] else
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: TileAcaoRapida(
                icone: Icons.apps_rounded,
                titulo: 'Aplicativos',
                subtitulo: 'Guias práticos',
                variacao: VarianteBadge.primario,
                pistaAcao: 'Explorar',
                aoTocar: () => _tocou('tile_primario'),
              ),
            ),
            const SizedBox(width: MemoraEspacamento.md),
            Expanded(
              child: TileAcaoRapida(
                icone: Icons.favorite_outline_rounded,
                titulo: 'Cuidado',
                subtitulo: 'Relógio e avisos',
                variacao: VarianteBadge.saude,
                pistaAcao: 'Ver saúde',
                aoTocar: () => _tocou('tile_saude'),
              ),
            ),
          ],
        ),
      const SizedBox(height: MemoraEspacamento.md),
      Wrap(
        spacing: MemoraEspacamento.sm,
        runSpacing: MemoraEspacamento.sm,
        children: <Widget>[
          ChipFiltro(
            rotulo: 'Todos',
            selecionado: _filtroAtivo == 0,
            aoTocar: () => setState(() => _filtroAtivo = 0),
          ),
          ChipFiltro(
            rotulo: 'Saúde',
            icone: Icons.health_and_safety_outlined,
            selecionado: _filtroAtivo == 1,
            aoTocar: () => setState(() => _filtroAtivo = 1),
          ),
        ],
      ),
      const SizedBox(height: MemoraEspacamento.md),
      const LinhaDeLista(
        titulo: 'Dado informativo sem ação',
        subtitulo: 'Sem seta e sem resposta ao toque',
      ),
      const SizedBox(height: MemoraEspacamento.sm),
      LinhaDeLista(
        titulo: 'Item de lista navegável',
        subtitulo: 'Exibe seta e semântica de botão',
        direita: const BadgeDeStatus(
          rotulo: 'Novo',
          tom: TomBadgeStatus.informativo,
        ),
        aoTocar: () => _tocou('linha'),
      ),

      const SizedBox(height: MemoraEspacamento.xxl),
    ];
  }
}

/// A faixa que troca tema e ampliação sem sair da galeria.
class _Controles extends StatelessWidget {
  final MemoraTemaId tema;
  final double escala;
  final ValueChanged<MemoraTemaId> aoTrocarTema;
  final ValueChanged<double> aoTrocarEscala;

  const _Controles({
    required this.tema,
    required this.escala,
    required this.aoTrocarTema,
    required this.aoTrocarEscala,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MemoraEspacamento.lg),
      decoration: BoxDecoration(
        color: cores.superficie,
        border: Border(
          bottom: BorderSide(
            color: cores.borda,
            width: MemoraDimensoes.bordaEnfase,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const TextoMemora.tituloSecao('Galeria do Design System'),
          const SizedBox(height: MemoraEspacamento.md),
          // `Wrap`, e não `Row`: são seis controles com rótulo escrito, e em
          // 200% eles não cabem lado a lado. `Row` estouraria a largura — que
          // é exatamente o defeito que a auditoria da ampliação encontrou.
          Wrap(
            spacing: MemoraEspacamento.sm,
            runSpacing: MemoraEspacamento.sm,
            children: <Widget>[
              for (final MemoraTemaId t in MemoraTemaId.values)
                _Pastilha(
                  rotulo: switch (t) {
                    MemoraTemaId.claro => 'Claro',
                    MemoraTemaId.escuro => 'Escuro',
                    MemoraTemaId.altoContraste => 'Alto contraste',
                  },
                  ativa: t == tema,
                  aoTocar: () => aoTrocarTema(t),
                ),
            ],
          ),
          const SizedBox(height: MemoraEspacamento.sm),
          Wrap(
            spacing: MemoraEspacamento.sm,
            runSpacing: MemoraEspacamento.sm,
            children: <Widget>[
              for (final double e in <double>[1.0, 1.5, 2.0])
                _Pastilha(
                  rotulo: '${(e * 100).toInt()}%',
                  ativa: e == escala,
                  aoTocar: () => aoTrocarEscala(e),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Um seletor da faixa de controles.
///
/// Não usa `BotaoSecundario` de propósito: a galeria precisa mostrar o estado
/// "escolhido", e o Design System não tem botão com estado selecionado — se
/// tivesse, ele estaria listado aqui em vez disto.
class _Pastilha extends StatelessWidget {
  final String rotulo;
  final bool ativa;
  final VoidCallback aoTocar;

  const _Pastilha({
    required this.rotulo,
    required this.ativa,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Semantics(
      button: true,
      selected: ativa,
      label: rotulo,
      onTap: aoTocar,
      child: ExcludeSemantics(
        child: Material(
          color: ativa ? cores.primaria : cores.superficieAlt,
          borderRadius: BorderRadius.circular(MemoraRaio.pilula),
          child: InkWell(
            onTap: aoTocar,
            borderRadius: BorderRadius.circular(MemoraRaio.pilula),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: MemoraDimensoes.alvoMinimo,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MemoraEspacamento.lg,
                  vertical: MemoraEspacamento.sm,
                ),
                child: Center(
                  child: TextoMemora(
                    rotulo,
                    estilo: EstiloTexto.corpoForte,
                    cor: ativa ? cores.sobrePrimaria : cores.texto,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cabeçalho de seção da galeria.
class _Secao extends StatelessWidget {
  final String titulo;
  final String? explicacao;

  const _Secao(this.titulo, [this.explicacao]);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: MemoraEspacamento.xxl,
        bottom: MemoraEspacamento.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextoMemora.tituloSecao(titulo),
          if (explicacao != null) ...<Widget>[
            const SizedBox(height: MemoraEspacamento.xs),
            TextoMemora.apoio(explicacao!),
          ],
        ],
      ),
    );
  }
}

/// Mostra qual foi o último componente tocado.
///
/// Serve para provar que o que parece clicável **é** clicável, e que o que
/// parece informação não responde a toque nenhum.
class _UltimoToque extends StatelessWidget {
  final String valor;

  const _UltimoToque({required this.valor});

  @override
  Widget build(BuildContext context) {
    return CampoInformacao(rotulo: 'Último toque', valor: valor);
  }
}

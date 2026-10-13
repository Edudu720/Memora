import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/assistente.dart';

/// O último catálogo recebido, guardado no aparelho (T069a, FR-024a).
///
/// Envolve um [RepositorioAssistente] e muda **uma** coisa: [catalogo]. "Meus
/// aplicativos" e "Serviços sociais" vêm do servidor, e sem internet ficariam
/// em branco — enquanto os guias, que são locais, funcionam. Com isto, sem
/// conexão a pessoa ainda vê o último catálogo que o aparelho recebeu.
///
/// ## As quatro regras
///
/// 1. **Substitui, nunca mescla.** Cada resposta nova troca a guardada inteira.
///    Mesclar manteria vivo um item que o servidor tirou do ar, e tirar do ar
///    é o jeito de recolher algo sem publicar versão nova (R6 da 003).
/// 2. **Resposta malformada não substitui.** Vazia, com `chave` fora do formato
///    do banco, com `chave` ou `id` repetidos, ou com serviço sensível marcado
///    como abrível (a FR-041 proíbe): nada disso apaga o guardado.
///    Uma resposta vazia é tratada como malformada de propósito — um servidor
///    que de repente "não conhece nada" é muito mais provavelmente um defeito
///    do que uma decisão.
/// 3. **Sem conexão, devolve o guardado.** E, sem nada guardado, **repassa a
///    falha**: a tela diz que precisa de internet uma vez, em vez de mostrar
///    uma grade vazia.
/// 4. **Não é [DadoLocalDaPessoa].** O catálogo é o mesmo para todo mundo e não
///    diz nada sobre ninguém; sair da conta não o apaga. O tipo ser outro
///    impede que alguém o ponha na lista da `LimpezaDeSessao` sem perceber.
///
/// Todo o resto da interface passa direto para o repositório de dentro.
class CatalogoGuardado implements RepositorioAssistente {
  /// Nome do arquivo dentro do diretório privado.
  static const String nomeDoArquivo = 'catalogo_guardado.json';

  /// A mesma restrição que o banco aplica à `chave` (`ck_servico_chave_formato`).
  static final RegExp _formaDaChave = RegExp(r'^[a-z0-9-]+$');

  static const int _tamanhoMaximoDaChave = 40;

  final RepositorioAssistente _interno;
  final Future<Directory> Function() _diretorio;
  final DateTime Function() _agora;

  Future<void> _fila = Future<void>.value();

  /// Envolve [interno]. [diretorio] e [agora] só mudam no teste.
  CatalogoGuardado(
    RepositorioAssistente interno, {
    Future<Directory> Function()? diretorio,
    DateTime Function()? agora,
  }) : _interno = interno,
       _diretorio = diretorio ?? getApplicationDocumentsDirectory,
       _agora = agora ?? DateTime.now;

  @override
  Future<List<ServicoDoCatalogo>> catalogo() async =>
      (await catalogoComOrigem()).servicos;

  /// Como [catalogo], mas dizendo **de onde** o catálogo veio.
  ///
  /// A oferta "Peça à Memora para abrir" só pode aparecer com catálogo do
  /// [OrigemDoCatalogo.servidor] (T066): o guardado pode estar velho, e
  /// oferecer abrir algo que o servidor já tirou do ar desfaria a R6.
  Future<CatalogoComOrigem> catalogoComOrigem() async {
    final List<ServicoDoCatalogo> recebido;
    try {
      recebido = await _interno.catalogo();
    } on Exception {
      final CatalogoRecebido? guardado = await lerGuardado();
      if (guardado != null) {
        return CatalogoComOrigem(guardado.servicos, OrigemDoCatalogo.guardado);
      }
      rethrow;
    }

    final String? defeito = _defeitoDe(recebido);
    if (defeito != null) {
      final CatalogoRecebido? guardado = await lerGuardado();
      if (guardado != null) {
        return CatalogoComOrigem(guardado.servicos, OrigemDoCatalogo.guardado);
      }
      throw FormatException('Catálogo malformado e nada guardado: $defeito');
    }

    await _naFila(() => _gravar(recebido));
    return CatalogoComOrigem(recebido, OrigemDoCatalogo.servidor);
  }

  /// O que está guardado, ou `null` quando não há nada (ou o arquivo está
  /// ilegível, o que dá no mesmo).
  Future<CatalogoRecebido?> lerGuardado() => _naFila(_ler);

  // O resto passa direto: o catálogo é a única coisa que muda.

  @override
  Future<RespostaDaAssistente> conversar({
    required String mensagem,
    required List<MensagemDaConversa> historico,
    void Function(String trecho)? aoReceberTrecho,
  }) => _interno.conversar(
    mensagem: mensagem,
    historico: historico,
    aoReceberTrecho: aoReceberTrecho,
  );

  @override
  Future<void> registrarAcao({
    required String servicoId,
    required String pedidoResumido,
  }) => _interno.registrarAcao(
    servicoId: servicoId,
    pedidoResumido: pedidoResumido,
  );

  @override
  Future<List<AcaoRegistrada>> registro() => _interno.registro();

  // ---------------------------------------------------------------------------

  /// Por que esta resposta não pode substituir a guardada, ou `null` se pode.
  static String? _defeitoDe(List<ServicoDoCatalogo> servicos) {
    if (servicos.isEmpty) return 'resposta vazia';

    final Set<String> chaves = <String>{};
    final Set<String> ids = <String>{};
    for (final ServicoDoCatalogo s in servicos) {
      if (s.id.trim().isEmpty) return 'item sem id';
      if (s.nomeExibido.trim().isEmpty) return 'item sem nome (${s.chave})';
      if (!_formaDaChave.hasMatch(s.chave) ||
          s.chave.length > _tamanhoMaximoDaChave) {
        return 'chave "${s.chave}" fora do formato';
      }
      // Serviço sensível que "pode abrir" contradiz a FR-041, que o banco
      // garante por restrição. Se chegou assim, algo está errado.
      if (s.categoria == CategoriaDoServico.sensivel && s.memoraPodeAbrir) {
        return 'serviço sensível marcado como abrível (${s.chave})';
      }
      if (!chaves.add(s.chave)) return 'chave repetida: ${s.chave}';
      if (!ids.add(s.id)) return 'id repetido: ${s.id}';
    }
    return null;
  }

  Future<T> _naFila<T>(Future<T> Function() tarefa) {
    final Future<T> resultado = _fila.then((_) => tarefa());
    _fila = resultado.then<void>((_) {}, onError: (Object _) {});
    return resultado;
  }

  Future<File> _arquivo() async =>
      File('${(await _diretorio()).path}/$nomeDoArquivo');

  Future<CatalogoRecebido?> _ler() async {
    try {
      final dynamic bruto = jsonDecode(await (await _arquivo()).readAsString());
      if (bruto is! Map<String, dynamic>) return null;

      final dynamic quando = bruto['recebidoEm'];
      final dynamic itens = bruto['servicos'];
      if (quando is! String || itens is! List) return null;
      final DateTime? recebidoEm = DateTime.tryParse(quando);
      if (recebidoEm == null) return null;

      final List<ServicoDoCatalogo> servicos = <ServicoDoCatalogo>[];
      for (final dynamic item in itens) {
        final ServicoDoCatalogo? servico = _servicoDe(item);
        // Um item ilegível invalida o arquivo todo: devolver "metade do
        // catálogo" seria mostrar à pessoa um catálogo que nunca existiu.
        if (servico == null) return null;
        servicos.add(servico);
      }
      if (_defeitoDe(servicos) != null) return null;
      return CatalogoRecebido(servicos: servicos, recebidoEm: recebidoEm);
    } on Exception {
      return null;
    }
  }

  /// Grava substituindo o arquivo inteiro, por temporário e renomeação: uma
  /// queda no meio deixa o catálogo anterior, não um arquivo pela metade.
  Future<void> _gravar(List<ServicoDoCatalogo> servicos) async {
    try {
      final File arquivo = await _arquivo();
      final File temporario = File('${arquivo.path}.tmp');
      await temporario.writeAsString(
        jsonEncode(<String, dynamic>{
          'recebidoEm': _agora().toUtc().toIso8601String(),
          'servicos': servicos.map(_mapaDe).toList(),
        }),
        flush: true,
      );
      await temporario.rename(arquivo.path);
    } on Exception {
      // Não conseguir guardar não pode impedir a pessoa de ver o catálogo que
      // acabou de chegar. Fica só sem o guardado desta vez.
    }
  }

  static Map<String, dynamic> _mapaDe(ServicoDoCatalogo s) => <String, dynamic>{
    'id': s.id,
    'chave': s.chave,
    'nomeExibido': s.nomeExibido,
    'descricaoCurta': s.descricaoCurta,
    'categoria': s.categoria.name,
    'memoraPodeAbrir': s.memoraPodeAbrir,
  };

  static ServicoDoCatalogo? _servicoDe(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final dynamic id = json['id'];
    final dynamic chave = json['chave'];
    final dynamic nome = json['nomeExibido'];
    final dynamic descricao = json['descricaoCurta'];
    final dynamic categoria = json['categoria'];
    final dynamic abre = json['memoraPodeAbrir'];
    if (id is! String ||
        chave is! String ||
        nome is! String ||
        descricao is! String ||
        categoria is! String ||
        abre is! bool) {
      return null;
    }

    final CategoriaDoServico? cat = CategoriaDoServico.values
        .where((CategoriaDoServico c) => c.name == categoria)
        .firstOrNull;
    if (cat == null) return null;

    return ServicoDoCatalogo(
      id: id,
      chave: chave,
      nomeExibido: nome,
      descricaoCurta: descricao,
      categoria: cat,
      memoraPodeAbrir: abre,
    );
  }
}

/// O que o [CatalogoGuardado] tem guardado: a última resposta completa e
/// quando ela chegou (`data-model.md`).
class CatalogoRecebido {
  /// A última resposta completa, como veio.
  final List<ServicoDoCatalogo> servicos;

  /// Quando foi recebida.
  final DateTime recebidoEm;

  /// Cria o registro.
  const CatalogoRecebido({required this.servicos, required this.recebidoEm});
}

/// De onde veio o catálogo que a tela está mostrando.
enum OrigemDoCatalogo {
  /// Resposta boa do servidor, agora.
  servidor,

  /// O último catálogo guardado no aparelho (sem conexão ou resposta ruim).
  guardado,
}

/// Um catálogo e a sua [origem].
class CatalogoComOrigem {
  /// Os serviços.
  final List<ServicoDoCatalogo> servicos;

  /// De onde vieram.
  final OrigemDoCatalogo origem;

  /// Cria o par.
  const CatalogoComOrigem(this.servicos, this.origem);
}

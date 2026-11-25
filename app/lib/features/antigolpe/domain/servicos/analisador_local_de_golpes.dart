import '../../../../l10n/textos_antigolpe.dart';
import '../entidades/analise_golpe.dart';
import '../repositorios/repositorio_analise_golpe.dart';

/// Motor heurístico determinístico local para análise de mensagens e links
/// suspeitos sem depender de internet ou servidor.
///
/// Atua como fallback automático quando o backend está indisponível ou sem
/// conexão, classificando riscos por pontuação transparente de sinais.
class AnalisadorLocalDeGolpes {
  /// Limite máximo aceito para o texto enviado à análise.
  static const int limiteCaracteres = 2000;

  /// Cria o analisador local determinístico.
  const AnalisadorLocalDeGolpes();

  static final RegExp _caracteresInvisiveis = RegExp(
    r'[\u200B-\u200F\u202A-\u202E\u2060-\u206F\uFEFF\u00AD]',
  );

  static final RegExp _marcasCombinantes = RegExp(r'[\u0300-\u036F]');

  static const List<String> _encurtadores = <String>[
    'bit.ly',
    'tinyurl.com',
    't.co',
    'is.gd',
    'cutt.ly',
    'rb.gy',
    'shorturl.at',
    'encurtador.com.br',
    'ow.ly',
    'goo.gl',
    'lnkd.in',
    'tiny.cc',
    'migre.me',
    'abre.ai',
    'v.gd',
    'shrtco.de',
    'rebrand.ly',
    's.id',
  ];

  static const Set<String> _tldsSuspeitos = <String>{
    'xyz',
    'top',
    'click',
    'tk',
    'ml',
    'ga',
    'cf',
    'gq',
    'buzz',
    'info',
    'vip',
    'icu',
    'club',
    'cfd',
    'sbs',
    'cyou',
    'work',
    'support',
    'online',
    'site',
    'shop',
    'loan',
    'win',
  };

  /// Conjunto de TLDs válidos para reconhecer domínios sem esquema (`http(s)://`)
  /// sem confundir frases com ponto sem espaço (`"Consulta cancelada.Amanha"`).
  static const Set<String> _tldsValidosSemEsquema = <String>{
    'br',
    'com',
    'org',
    'net',
    'gov',
    'edu',
    'mil',
    'io',
    'me',
    'co',
    'app',
    'dev',
    'xyz',
    'top',
    'site',
    'online',
    'store',
    'tech',
    'info',
    'biz',
    'link',
    'click',
    'live',
    'shop',
    'club',
    'vip',
    'icu',
    'buzz',
    'work',
    'loan',
    'win',
    'support',
    'ly',
    'gl',
    'to',
    'is',
    'at',
    'uk',
    'us',
    'pt',
    'es',
    'ar',
    'cl',
    'py',
    'uy',
    'cn',
    'ru',
    'tk',
    'ml',
    'ga',
    'cf',
    'gq',
    'cfd',
    'sbs',
    'cyou',
    'ai',
    'gd',
    'gy',
    'in',
    'id',
    'cc',
    're',
    'bradesco',
  };

  /// Domínios oficiais conhecidos de bancos, órgãos públicos e serviços citados
  /// com frequência em golpes no Brasil (sincronizados com o backend).
  static const Set<String> _dominiosOficiais = <String>{
    'gov.br',
    'inss.gov.br',
    'meu.inss.gov.br',
    'receita.fazenda.gov.br',
    'fazenda.gov.br',
    'bcb.gov.br',
    'valoresareceber.bcb.gov.br',
    'caixa.gov.br',
    'caixa.com.br',
    'bb.com.br',
    'bancodobrasil.com.br',
    'itau.com.br',
    'itau.com',
    'bradesco.com.br',
    'banco.bradesco',
    'bradesco.com',
    'santander.com.br',
    'santander.com',
    'nubank.com.br',
    'nu.com.br',
    'bancointer.com.br',
    'inter.co',
    'correios.com.br',
    'serasa.com.br',
    'serasaexperian.com.br',
    'mercadolivre.com.br',
    'mercadolibre.com',
    'mercadopago.com.br',
    'mercadopago.com',
    'magazineluiza.com.br',
    'magalu.com',
    'amazon.com.br',
    'amazon.com',
    'vivo.com.br',
    'claro.com.br',
    'tim.com.br',
    'netflix.com',
    'netflix.com.br',
  };

  /// Domínios legítimos do próprio WhatsApp (canal de mensagens, não isenta
  /// personificação de bancos ou órgãos públicos nem alertas de urgência).
  static const Set<String> _dominiosWhatsapp = <String>{
    'whatsapp.com',
    'whatsapp.net',
    'wa.me',
  };

  /// Regras de marcas e órgãos públicos vigiados com seus respectivos domínios
  /// oficiais para validação específica por marca citada.
  static const List<_RegraMarcaLocal> _regrasMarcas = <_RegraMarcaLocal>[
    _RegraMarcaLocal(
      termos: <String>['banco do brasil', 'bancodobrasil', 'bb'],
      dominiosOficiais: <String>['bb.com.br', 'bancodobrasil.com.br'],
    ),
    _RegraMarcaLocal(
      termos: <String>['itau'],
      dominiosOficiais: <String>['itau.com.br', 'itau.com'],
    ),
    _RegraMarcaLocal(
      termos: <String>['bradesco'],
      dominiosOficiais: <String>[
        'bradesco.com.br',
        'banco.bradesco',
        'bradesco.com',
      ],
    ),
    _RegraMarcaLocal(
      termos: <String>['santander'],
      dominiosOficiais: <String>['santander.com.br', 'santander.com'],
    ),
    _RegraMarcaLocal(
      termos: <String>[
        'caixa',
        'caixa economica',
        'caixa tem',
        'loterias caixa',
      ],
      dominiosOficiais: <String>['caixa.gov.br', 'caixa.com.br'],
    ),
    _RegraMarcaLocal(
      termos: <String>['nubank', 'nu bank', 'roxinho'],
      dominiosOficiais: <String>['nubank.com.br', 'nu.com.br'],
    ),
    _RegraMarcaLocal(
      termos: <String>['banco inter', 'conta inter'],
      dominiosOficiais: <String>['bancointer.com.br', 'inter.co'],
    ),
    _RegraMarcaLocal(
      termos: <String>['gov.br', 'govbr', 'governo federal', 'meu gov'],
      dominiosOficiais: <String>['gov.br'],
    ),
    _RegraMarcaLocal(
      termos: <String>[
        'receita federal',
        'receita fazenda',
        'imposto de renda',
        'malha fina',
        'cpf irregular',
      ],
      dominiosOficiais: <String>[
        'gov.br',
        'fazenda.gov.br',
        'receita.fazenda.gov.br',
      ],
    ),
    _RegraMarcaLocal(
      termos: <String>['inss', 'meu inss'],
      dominiosOficiais: <String>['gov.br', 'inss.gov.br', 'meu.inss.gov.br'],
    ),
    _RegraMarcaLocal(
      termos: <String>['banco central', 'valores a receber'],
      dominiosOficiais: <String>[
        'bcb.gov.br',
        'valoresareceber.bcb.gov.br',
        'gov.br',
      ],
    ),
    _RegraMarcaLocal(
      termos: <String>['correios'],
      dominiosOficiais: <String>['correios.com.br'],
    ),
    _RegraMarcaLocal(
      termos: <String>['serasa'],
      dominiosOficiais: <String>['serasa.com.br', 'serasaexperian.com.br'],
    ),
    _RegraMarcaLocal(
      termos: <String>['mercado livre', 'mercadolivre'],
      dominiosOficiais: <String>['mercadolivre.com.br', 'mercadolibre.com'],
    ),
    _RegraMarcaLocal(
      termos: <String>['mercado pago', 'mercadopago'],
      dominiosOficiais: <String>['mercadopago.com.br', 'mercadopago.com'],
    ),
    _RegraMarcaLocal(
      termos: <String>['magalu', 'magazine luiza'],
      dominiosOficiais: <String>['magazineluiza.com.br', 'magalu.com'],
    ),
    _RegraMarcaLocal(
      termos: <String>['amazon'],
      dominiosOficiais: <String>['amazon.com.br', 'amazon.com'],
    ),
    _RegraMarcaLocal(
      termos: <String>[
        'operadora vivo',
        'meu vivo',
        'fatura vivo',
        'vivo fibra',
      ],
      dominiosOficiais: <String>['vivo.com.br'],
    ),
    _RegraMarcaLocal(
      termos: <String>['operadora claro', 'minha claro', 'fatura claro'],
      dominiosOficiais: <String>['claro.com.br'],
    ),
    _RegraMarcaLocal(
      termos: <String>['operadora tim', 'meu tim', 'fatura tim'],
      dominiosOficiais: <String>['tim.com.br'],
    ),
    _RegraMarcaLocal(
      termos: <String>['netflix'],
      dominiosOficiais: <String>['netflix.com', 'netflix.com.br'],
    ),
  ];

  static const List<String> _impostoresDeHost = <String>[
    'banco-brasil',
    'bancodobrasil',
    'bb-seguro',
    'govbr',
    'g0v',
    'correios-taxa',
    'correiosbr',
    'c0rreios',
    'caixa-atualizacao',
    'caixa-seguro',
    'caixabr',
    'itau-seguro',
    'itau-token',
    'itaubr',
    'bradesco-alerta',
    'bradescobr',
    'santander-alerta',
    'santanderbr',
    'nubank-resgate',
    'nubankbr',
    'serasa-limpa',
    'serasabr',
    'inss-beneficio',
    'meuinss',
    'meu-inss',
    'pix-resgate',
    'whatsapp-suporte',
    'receita-regularizar',
    'receitafederal',
    'receita-federal',
    'receita_federal',
  ];

  static const List<String> _termosUrgenciaAmeaca = <String>[
    'bloqueado',
    'bloqueada',
    'bloqueio',
    'suspenso',
    'suspensa',
    'suspensao',
    'cancelado',
    'cancelada',
    'cancelamento',
    'ultimo aviso',
    'urgente',
    'urgencia',
    '24 horas',
    '24h',
    'em minutos',
    'taxa pendente',
    'alfandega',
    'multa',
    'protesto',
    'cpf irregular',
    'cpf bloqueado',
    'divida ativa',
    'sera encerrada',
    'imediato',
    'imediatamente',
    'vencendo hoje',
    'ultimas horas',
    'compra nao reconhecida',
  ];

  /// Credenciais sensíveis e meios de pagamento diretos.
  static const List<String> _termosCredencialEstrita = <String>[
    'senha',
    'codigo',
    '6 digitos',
    'seis digitos',
    'token',
    'chave pix',
    'pix',
    'boleto',
    'transferencia',
    'deposito',
    'cvv',
  ];

  /// Chamadas de ação e recadastramento que agravam mensagens sem domínio oficial.
  static const List<String> _termosAcaoCadastro = <String>[
    'clique aqui',
    'acesse o link',
    'toque no link',
    'atualize seu cadastro',
    'atualizar cadastro',
    'recadastramento',
    'prova de vida',
    'confirmar dados',
    'validar acesso',
    'liberar conta',
    'desbloquear',
    'regularizar',
  ];

  static const List<String> _termosPremioIsca = <String>[
    'premio',
    'premiado',
    'sorteio',
    'ganhou',
    'resgate',
    'resgatar',
    'brinde',
    'dinheiro esquecido',
    'valores a receber',
    'beneficio liberado',
    'indenizacao',
    'bonus',
    'presente gratis',
  ];

  static const List<String> _termosRedirecionamento = <String>[
    'central de atendimento',
    'ligue para 0800',
    'ligue agora',
    'fale no whatsapp',
    'chame no whatsapp',
    'suporte tecnico',
  ];

  static const List<String> _termosAcessoRemotoOuApk = <String>[
    'anydesk',
    'teamviewer',
    'rustdesk',
    'quicksupport',
    '.apk',
    'acesso remoto',
  ];

  static final RegExp _padraoSupremoRemoto = RegExp(
    r'\bsupremo\s+(?:remote|control|mobile|assist)\b'
    r'|\b(?:instal[ae]\w*|baix[ae]\w*|app|aplicativo|acesso\s+remoto|suporte\s+remoto|suporte)\b[^.!?\n]{0,40}\bsupremo\b'
    r'|\bsupremo\b(?!\s+(?:tribunal|federal|corte))[^.!?\n]{0,40}\b(?:instal[ae]\w*|baix[ae]\w*|app|aplicativo|acesso\s+remoto|suporte\s+remoto|celular)\b',
  );

  static const List<String> _termosTrocaDeNumero = <String>[
    'troquei de numero',
    'mudei de numero',
    'mudou de numero',
    'numero novo',
    'novo numero',
    'salva esse numero',
    'salve meu numero',
    'agenda esse numero',
  ];

  /// Analisa [conteudo] localmente e devolve [AnaliseGolpe] offline.
  AnaliseGolpe analisar(
    String conteudo, {
    OrigemAnalise origem = OrigemAnalise.localOffline,
  }) {
    final String textoLimpo = conteudo.trim();
    if (textoLimpo.isEmpty) {
      throw const ConteudoAnaliseInvalidoException(TextosAntigolpe.erroVazio);
    }
    if (textoLimpo.length > limiteCaracteres) {
      throw const ConteudoAnaliseInvalidoException(
        TextosAntigolpe.erroMuitoLongo,
      );
    }

    final String semInvisiveis = textoLimpo.replaceAll(
      _caracteresInvisiveis,
      '',
    );
    final String textoReconstruido = _reconstruirLinksOfuscados(semInvisiveis);
    final String textoSemEmails = _removerEmailsSemEsquema(textoReconstruido);
    final String normalizado = _normalizar(textoSemEmails);
    final List<_UrlExtraida> urls = _extrairUrls(textoSemEmails);

    int pontuacao = 0;
    final List<String> sinais = <String>[];

    bool temIp = false;
    bool temUserinfo = false;
    bool temPunycode = false;
    bool temHomografo = false;
    bool temEncurtador = false;
    bool temTldSuspeito = false;
    bool temHttpSemTls = false;
    bool temLinkNaoOficial = false;
    bool temImpostorNoHost = false;
    bool todosLinksOficiais = urls.isNotEmpty;

    for (final _UrlExtraida url in urls) {
      final String host = url.host;
      final bool temNaoAscii = RegExp(r'[^\x00-\x7F]').hasMatch(host);
      final bool oficial =
          !temNaoAscii &&
          !url.temUserinfo &&
          !url.temBarraInvertida &&
          _ehDominioOficial(host);

      if (!oficial) {
        todosLinksOficiais = false;
        temLinkNaoOficial = true;
      }

      if (_ehIp(host)) {
        temIp = true;
      }
      if (url.temUserinfo || url.temBarraInvertida) {
        temUserinfo = true;
      }
      if (host.contains('xn--')) {
        temPunycode = true;
      }
      if (temNaoAscii) {
        temHomografo = true;
      }
      if (_ehEncurtador(host)) {
        temEncurtador = true;
      }
      if (_temTldSuspeito(host)) {
        temTldSuspeito = true;
      }
      if (!oficial &&
          (_impostorNoHost(host) ||
              (url.temBarraInvertida &&
                  _impostorNoHost(url.autoridadeOriginal)))) {
        temImpostorNoHost = true;
      }
      if (url.ehHttpInseguro && !oficial) {
        temHttpSemTls = true;
      }
    }

    if (temIp) {
      pontuacao += 4;
      sinais.add(TextosAntigolpe.sinalIp);
    }
    if (temUserinfo) {
      pontuacao += 4;
      sinais.add(TextosAntigolpe.sinalArroba);
    }
    if (temPunycode) {
      pontuacao += 3;
      sinais.add(TextosAntigolpe.sinalPunycode);
    }
    if (temHomografo) {
      pontuacao += 4;
      sinais.add(TextosAntigolpe.sinalHomografo);
    }
    if (temEncurtador) {
      pontuacao += 2;
      sinais.add(TextosAntigolpe.sinalEncurtador);
    }
    if (temTldSuspeito) {
      pontuacao += 2;
      sinais.add(TextosAntigolpe.sinalTldSuspeito);
    }

    final bool citaMarca = _citaMarcaVigiada(normalizado);
    final bool temMarcaComLinkFalso = _detectarMarcaComLinkIncompativel(
      normalizado,
      urls,
    );
    if (temImpostorNoHost || temMarcaComLinkFalso) {
      pontuacao += 4;
      sinais.add(TextosAntigolpe.sinalMarcaFalsa);
    }

    final bool temAcessoRemotoOuApk =
        _contemQualquer(normalizado, _termosAcessoRemotoOuApk) ||
        _padraoSupremoRemoto.hasMatch(normalizado);
    if (temAcessoRemotoOuApk) {
      pontuacao += 4;
      sinais.add(TextosAntigolpe.sinalAcessoRemotoOuApk);
    }

    final bool temTrocaDeNumero = _contemQualquer(
      normalizado,
      _termosTrocaDeNumero,
    );
    if (temTrocaDeNumero) {
      pontuacao += 2;
      sinais.add(TextosAntigolpe.sinalTrocaDeNumero);
    }

    final bool temUrgencia = _contemQualquer(
      normalizado,
      _termosUrgenciaAmeaca,
    );
    if (temUrgencia && !todosLinksOficiais) {
      pontuacao += 2;
      sinais.add(TextosAntigolpe.sinalUrgencia);
    } else if (temUrgencia && todosLinksOficiais) {
      pontuacao += 1;
    }

    final bool temCredencialOuDinheiro = _contemCredencialNaoNegada(
      normalizado,
      incluirAcoesCadastro: !todosLinksOficiais,
    );
    if (temCredencialOuDinheiro) {
      pontuacao += 2;
      sinais.add(TextosAntigolpe.sinalCredencialOuDinheiro);
      if (temLinkNaoOficial ||
          (temUrgencia && !todosLinksOficiais) ||
          temTrocaDeNumero) {
        pontuacao += 1;
      }
    }

    final bool temPremioIsca = _contemQualquer(normalizado, _termosPremioIsca);
    if (temPremioIsca && !todosLinksOficiais) {
      pontuacao += 2;
      sinais.add(TextosAntigolpe.sinalPremio);
    }

    final bool temRedirecionamento = _contemQualquer(
      normalizado,
      _termosRedirecionamento,
    );
    if (temRedirecionamento && (temUrgencia || temCredencialOuDinheiro)) {
      pontuacao += 2;
      sinais.add(TextosAntigolpe.sinalRedirecionamento);
    }

    if (temHttpSemTls &&
        (temCredencialOuDinheiro ||
            temUrgencia ||
            citaMarca ||
            temImpostorNoHost)) {
      pontuacao += 1;
      sinais.add(TextosAntigolpe.sinalHttpSemProtecao);
    }

    final NivelRisco risco = switch (pontuacao) {
      >= 4 => NivelRisco.altoRisco,
      >= 2 => NivelRisco.atencao,
      _ => NivelRisco.seguro,
    };

    final String titulo = switch (risco) {
      NivelRisco.seguro => TextosAntigolpe.localSeguroTitulo,
      NivelRisco.atencao => TextosAntigolpe.localAtencaoTitulo,
      NivelRisco.altoRisco => TextosAntigolpe.localAltoRiscoTitulo,
    };

    final String explicacao = switch (risco) {
      NivelRisco.seguro =>
        todosLinksOficiais
            ? TextosAntigolpe.localDominioOficialExplicacao
            : TextosAntigolpe.localSeguroExplicacao,
      NivelRisco.atencao => TextosAntigolpe.localAtencaoExplicacao,
      NivelRisco.altoRisco => TextosAntigolpe.localAltoRiscoExplicacao,
    };

    final List<String> orientacoes = switch (risco) {
      NivelRisco.seguro => const <String>[
        TextosAntigolpe.orientacaoSeguro1,
        TextosAntigolpe.orientacaoSeguro2,
        TextosAntigolpe.orientacaoSeguro3,
      ],
      NivelRisco.atencao => const <String>[
        TextosAntigolpe.orientacaoAtencao1,
        TextosAntigolpe.orientacaoAtencao2,
        TextosAntigolpe.orientacaoAtencao3,
      ],
      NivelRisco.altoRisco => const <String>[
        TextosAntigolpe.orientacaoAltoRisco1,
        TextosAntigolpe.orientacaoAltoRisco2,
        TextosAntigolpe.orientacaoAltoRisco3,
      ],
    };

    return AnaliseGolpe(
      risco: risco,
      origem: origem,
      titulo: titulo,
      explicacao: explicacao,
      orientacoes: orientacoes,
      sinaisDetectados: List<String>.unmodifiable(sinais),
      analisadoPorIa: false,
    );
  }

  static String _reconstruirLinksOfuscados(String texto) {
    return texto
        .replaceAll(_caracteresInvisiveis, '')
        .replaceAll('[:]', ':')
        .replaceAll('(:)', ':')
        .replaceAll('[/]', '/')
        .replaceAll('(/)', '/')
        .replaceAll('[.]', '.')
        .replaceAll('(.)', '.')
        .replaceAll('{.}', '.')
        .replaceAll(RegExp(r'\[dot\]|\(dot\)', caseSensitive: false), '.')
        .replaceAll(RegExp(r'\bhxxps(?=://)', caseSensitive: false), 'https')
        .replaceAll(RegExp(r'\bhxxp(?=://)', caseSensitive: false), 'http');
  }

  static final RegExp _padraoEmail = RegExp(
    r'(?<![:/\\a-zA-Z0-9._%+-])[a-zA-Z0-9._%+-]+@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,15}(?![/\\a-zA-Z0-9_%+-]|\.[a-zA-Z0-9])',
  );

  static String _removerEmailsSemEsquema(String texto) {
    return texto.replaceAll(_padraoEmail, ' ');
  }

  static String _normalizar(String texto) {
    const String acentos = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const String semAcentos = 'aaaaaeeeeiiiiooooouuuucn';
    final String lower = texto
        .replaceAll(_caracteresInvisiveis, '')
        .toLowerCase()
        .replaceAll(_marcasCombinantes, '');
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < lower.length; i++) {
      final String ch = lower[i];
      final int idx = acentos.indexOf(ch);
      buffer.write(idx >= 0 ? semAcentos[idx] : ch);
    }
    return buffer.toString();
  }

  static List<_UrlExtraida> _extrairUrls(String texto) {
    final RegExp regex = RegExp(
      r'''(?:https?://|www\.)[^\s<>"')]+|(?<![a-zA-Z0-9\u0080-\uFFFF._%+@-])(?:[a-zA-Z0-9._%+-]+@)?(?:[a-zA-Z0-9\u0100-\uFFFF-]+\.)+[a-zA-Z\u0100-\uFFFF]{2,}(?:/[^\s<>"')]*)?''',
      caseSensitive: false,
    );

    final List<_UrlExtraida> encontradas = <_UrlExtraida>[];
    for (final RegExpMatch match in regex.allMatches(texto)) {
      final String bruto = match
          .group(0)!
          .replaceAll(RegExp(r'[.,;:!?]+$'), '');
      if (bruto.isEmpty) continue;

      final bool tinhaEsquemaOuWww = RegExp(
        r'^(?:https?://|www\.)',
        caseSensitive: false,
      ).hasMatch(bruto);
      final bool ehHttp = bruto.toLowerCase().startsWith('http://');

      final String semEsquema = bruto.replaceFirst(
        RegExp(r'^https?://', caseSensitive: false),
        '',
      );
      final String autoridadeBruta = semEsquema.split(RegExp(r'[/?#]')).first;
      if (autoridadeBruta.isEmpty) continue;

      final bool temBarraInvertida = autoridadeBruta.contains(r'\');
      final String autoridadeEfetiva = temBarraInvertida
          ? autoridadeBruta.split(r'\').first
          : autoridadeBruta;
      final bool temUserinfo = autoridadeEfetiva.contains('@');

      String host = (temUserinfo
              ? autoridadeEfetiva.split('@').last
              : autoridadeEfetiva)
          .split(':')
          .first
          .toLowerCase()
          .replaceAll(RegExp(r'[.,;:!?]+$'), '');

      if (host.startsWith('www.')) {
        host = host.substring(4);
      }
      if (host.isEmpty) continue;

      if (!tinhaEsquemaOuWww && !_ehIp(host)) {
        final int ultimoPonto = host.lastIndexOf('.');
        if (ultimoPonto <= 0 || ultimoPonto == host.length - 1) continue;
        final String tld = host.substring(ultimoPonto + 1);
        if (!_tldsValidosSemEsquema.contains(tld) && !tld.startsWith('xn--')) {
          continue;
        }
      }

      encontradas.add(
        _UrlExtraida(
          host: host,
          autoridadeOriginal: autoridadeBruta.toLowerCase(),
          temUserinfo: temUserinfo,
          temBarraInvertida: temBarraInvertida,
          ehHttpInseguro: ehHttp,
        ),
      );
    }

    return encontradas;
  }

  static bool _ehIp(String host) {
    final RegExp ip = RegExp(r'^\d{1,3}(?:\.\d{1,3}){3}$');
    return ip.hasMatch(host);
  }

  static bool _ehDominioOficial(String host) {
    return _pertenceAoConjunto(host, _dominiosOficiais);
  }

  static bool _pertenceAoConjunto(String host, Iterable<String> dominios) {
    for (final String dominio in dominios) {
      if (host == dominio || host.endsWith('.$dominio')) {
        return true;
      }
    }
    return false;
  }

  static bool _ehUrlLimpaSemArmadilha(_UrlExtraida url) {
    final bool temNaoAscii = RegExp(r'[^\x00-\x7F]').hasMatch(url.host);
    return !temNaoAscii &&
        !url.temUserinfo &&
        !url.temBarraInvertida &&
        !_ehIp(url.host) &&
        !url.host.contains('xn--');
  }

  static bool _ehEncurtador(String host) {
    for (final String enc in _encurtadores) {
      if (host == enc || host.endsWith('.$enc')) {
        return true;
      }
    }
    return false;
  }

  static bool _temTldSuspeito(String host) {
    final int ponto = host.lastIndexOf('.');
    if (ponto < 0 || ponto == host.length - 1) return false;
    final String tld = host.substring(ponto + 1);
    return _tldsSuspeitos.contains(tld);
  }

  static bool _impostorNoHost(String host) {
    final String norm = _normalizar(host);
    for (final String padrao in _impostoresDeHost) {
      if (norm.contains(padrao)) return true;
    }
    const List<String> marcasNoHost = <String>[
      'itau',
      'bradesco',
      'santander',
      'caixa',
      'nubank',
      'correios',
      'serasa',
      'inss',
      'govbr',
      'mercadopago',
      'mercadolivre',
    ];
    for (final String marca in marcasNoHost) {
      if (norm.contains(marca)) return true;
    }
    if (norm.contains('whatsapp') &&
        !_pertenceAoConjunto(host, _dominiosWhatsapp)) {
      return true;
    }
    if (!norm.contains('ao-vivo') &&
        RegExp(
          r'(?<![a-z0-9])vivo(?![a-z0-9])|vivobr|vivo-fatura|vivo-2via',
        ).hasMatch(norm)) {
      return true;
    }
    return false;
  }

  static bool _citaMarcaVigiada(String normalizado) {
    for (final _RegraMarcaLocal regra in _regrasMarcas) {
      if (_contemQualquer(normalizado, regra.termos)) return true;
    }
    return false;
  }

  static bool _detectarMarcaComLinkIncompativel(
    String normalizado,
    List<_UrlExtraida> urls,
  ) {
    if (urls.isEmpty) return false;
    final List<_RegraMarcaLocal> citadas = <_RegraMarcaLocal>[
      for (final _RegraMarcaLocal regra in _regrasMarcas)
        if (_contemQualquer(normalizado, regra.termos)) regra,
    ];
    if (citadas.isEmpty) return false;

    final Set<String> dominiosPermitidos = <String>{
      for (final _RegraMarcaLocal regra in citadas) ...regra.dominiosOficiais,
    };

    for (final _RegraMarcaLocal regra in citadas) {
      final bool temUrlDaMarca = urls.any(
        (_UrlExtraida u) =>
            _ehUrlLimpaSemArmadilha(u) &&
            _pertenceAoConjunto(u.host, regra.dominiosOficiais),
      );
      if (!temUrlDaMarca) return true;
    }

    for (final _UrlExtraida url in urls) {
      if (!_ehUrlLimpaSemArmadilha(url) ||
          !_pertenceAoConjunto(url.host, dominiosPermitidos)) {
        return true;
      }
    }
    return false;
  }

  static bool _contemCredencialNaoNegada(
    String normalizado, {
    required bool incluirAcoesCadastro,
  }) {
    final List<String> termos = <String>[
      ..._termosCredencialEstrita,
      if (incluirAcoesCadastro) ..._termosAcaoCadastro,
    ];
    final List<String> clausulas = normalizado.split(
      RegExp(r'[.!?;:\n]+|\bmas\b|\bporem\b|\bentretanto\b|\bcontudo\b'),
    );
    final RegExp avisoProtetivo = RegExp(
      r'\b(?:nunca|jamais|nao)\s+(?:pede|peco|pedimos|pedem|pedir|solicita|solicitamos|solicitam|compartilhe|compartilhar|informe|informar|envie|enviar|passe|passar|forneca|fornecer|digite|digitar|divulgue|divulgar|revele|revelar)\b',
    );
    for (final String clausula in clausulas) {
      final String trecho = clausula.trim();
      if (trecho.isEmpty) continue;
      if (!_contemQualquer(trecho, termos)) continue;
      final bool ehAvisoProtetivo =
          avisoProtetivo.hasMatch(trecho) &&
          !_contemQualquer(trecho, _termosAcaoCadastro);
      if (!ehAvisoProtetivo) {
        return true;
      }
    }
    return false;
  }

  static bool _contemTermoComFronteira(String texto, String termo) {
    final bool iniciaAlfanum = RegExp(r'^[a-z0-9]').hasMatch(termo);
    final bool terminaAlfanum = RegExp(r'[a-z0-9]$').hasMatch(termo);
    final String prefixo = iniciaAlfanum ? '(?<![a-z0-9])' : '';
    final String sufixo = terminaAlfanum ? '(?![a-z0-9])' : '';
    return RegExp('$prefixo${RegExp.escape(termo)}$sufixo').hasMatch(texto);
  }

  static bool _contemQualquer(String normalizado, List<String> termos) {
    for (final String termo in termos) {
      if (_contemTermoComFronteira(normalizado, termo)) return true;
    }
    return false;
  }
}

class _UrlExtraida {
  final String host;
  final String autoridadeOriginal;
  final bool temUserinfo;
  final bool temBarraInvertida;
  final bool ehHttpInseguro;

  const _UrlExtraida({
    required this.host,
    required this.autoridadeOriginal,
    required this.temUserinfo,
    required this.temBarraInvertida,
    required this.ehHttpInseguro,
  });
}

class _RegraMarcaLocal {
  final List<String> termos;
  final List<String> dominiosOficiais;

  const _RegraMarcaLocal({
    required this.termos,
    required this.dominiosOficiais,
  });
}

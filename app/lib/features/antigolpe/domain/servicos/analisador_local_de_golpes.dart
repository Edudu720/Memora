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
  };

  /// Domínios oficiais conhecidos de bancos, órgãos públicos e serviços citados
  /// com frequência em golpes no Brasil.
  static const Set<String> _dominiosOficiais = <String>{
    'bb.com.br',
    'itau.com.br',
    'bradesco.com.br',
    'santander.com.br',
    'caixa.gov.br',
    'nubank.com.br',
    'bancointer.com.br',
    'inter.co',
    'gov.br',
    'receita.fazenda.gov.br',
    'meu.inss.gov.br',
    'bcb.gov.br',
    'valoresareceber.bcb.gov.br',
    'correios.com.br',
    'serasa.com.br',
    'whatsapp.com',
    'mercadolivre.com.br',
    'mercadopago.com.br',
    'magazineluiza.com.br',
    'magalu.com',
  };

  /// Marcas e termos associados que, quando aparecem com link não oficial ou no
  /// próprio host, indicam possível tentativa de falsificação.
  static const List<String> _marcasVigiadas = <String>[
    'banco do brasil',
    'bb',
    'itau',
    'bradesco',
    'santander',
    'caixa',
    'nubank',
    'banco inter',
    'gov.br',
    'govbr',
    'receita federal',
    'inss',
    'correios',
    'serasa',
    'whatsapp',
    'banco central',
    'valores a receber',
    'mercado livre',
    'mercado pago',
    'magalu',
  ];

  static const List<String> _impostoresDeHost = <String>[
    'banco-brasil',
    'bancodobrasil',
    'bb-seguro',
    'govbr',
    'g0v',
    'correios-taxa',
    'c0rreios',
    'caixa-atualizacao',
    'caixa-seguro',
    'itau-seguro',
    'itau-token',
    'bradesco-alerta',
    'santander-alerta',
    'nubank-resgate',
    'serasa-limpa',
    'inss-beneficio',
    'pix-resgate',
    'whatsapp-suporte',
    'receita-regularizar',
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
    'divida ativa',
    'sera encerrada',
    'imediato',
    'imediatamente',
    'vencendo hoje',
    'ultimas horas',
    'compra nao reconhecida',
  ];

  static const List<String> _termosCredencialDinheiro = <String>[
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

  /// Analisa [conteudo] localmente e devolve [AnaliseGolpe] offline.
  AnaliseGolpe analisar(String conteudo) {
    final String textoLimpo = conteudo.trim();
    if (textoLimpo.isEmpty) {
      throw const ConteudoAnaliseInvalidoException(TextosAntigolpe.erroVazio);
    }
    if (textoLimpo.length > limiteCaracteres) {
      throw const ConteudoAnaliseInvalidoException(
        TextosAntigolpe.erroMuitoLongo,
      );
    }

    final String textoReconstruido = _reconstruirLinksOfuscados(textoLimpo);
    final String normalizado = _normalizar(textoReconstruido);
    final List<_UrlExtraida> urls = _extrairUrls(textoReconstruido);

    int pontuacao = 0;
    final List<String> sinais = <String>[];

    bool temIp = false;
    bool temUserinfo = false;
    bool temPunycode = false;
    bool temEncurtador = false;
    bool temTldSuspeito = false;
    bool temHttpSemTls = false;
    bool temLinkNaoOficial = false;
    bool temImpostorNoHost = false;
    bool todosLinksOficiais = urls.isNotEmpty;

    for (final _UrlExtraida url in urls) {
      final String host = url.host;
      final bool oficial = _ehDominioOficial(host);
      if (!oficial) {
        todosLinksOficiais = false;
        temLinkNaoOficial = true;
      }

      if (_ehIp(host)) {
        temIp = true;
      }
      if (url.temUserinfo) {
        temUserinfo = true;
      }
      if (host.contains('xn--')) {
        temPunycode = true;
      }
      if (_ehEncurtador(host)) {
        temEncurtador = true;
      }
      if (_temTldSuspeito(host)) {
        temTldSuspeito = true;
      }
      if (!oficial && _impostorNoHost(host)) {
        temImpostorNoHost = true;
      }
      if (url.ehHttpInseguro && !oficial) {
        temHttpSemTls = true;
      }
    }

    if (temIp) {
      pontuacao += 4;
      sinais.add(
        'O link aponta para um número de endereço (IP), algo comum em golpes.',
      );
    }
    if (temUserinfo) {
      pontuacao += 4;
      sinais.add(
        'O link usa "@" para disfarçar o endereço verdadeiro do site.',
      );
    }
    if (temPunycode) {
      pontuacao += 3;
      sinais.add(
        'O endereço do site usa caracteres especiais disfarçados.',
      );
    }
    if (temEncurtador) {
      pontuacao += 2;
      sinais.add(
        'O link é encurtado e esconde o endereço final da página.',
      );
    }
    if (temTldSuspeito) {
      pontuacao += 2;
      sinais.add(
        'O site usa uma terminação incomum para serviços oficiais.',
      );
    }

    final bool citaMarca = _citaMarcaVigiada(normalizado);
    if (temImpostorNoHost || (citaMarca && temLinkNaoOficial)) {
      pontuacao += 3;
      sinais.add(
        'Cita marca ou órgão conhecido junto com um endereço fora do site oficial.',
      );
    }

    final bool temUrgencia = _contemQualquer(normalizado, _termosUrgenciaAmeaca);
    if (temUrgencia) {
      pontuacao += 2;
      sinais.add(
        'Usa tom de pressa, ameaça ou bloqueio para apressar sua decisão.',
      );
    }

    final bool temCredencialOuDinheiro = _contemQualquer(
      normalizado,
      _termosCredencialDinheiro,
    );
    if (temCredencialOuDinheiro) {
      pontuacao += 2;
      sinais.add(
        'Pede senha, código de verificação, dados pessoais ou transferência.',
      );
      if (temLinkNaoOficial || temUrgencia) {
        pontuacao += 1;
      }
    }

    final bool temPremioIsca = _contemQualquer(normalizado, _termosPremioIsca);
    if (temPremioIsca && !todosLinksOficiais) {
      pontuacao += 2;
      sinais.add(
        'Promete prêmio, brinde ou dinheiro fácil para chamar atenção.',
      );
    }

    final bool temRedirecionamento = _contemQualquer(
      normalizado,
      _termosRedirecionamento,
    );
    if (temRedirecionamento && (temUrgencia || temCredencialOuDinheiro)) {
      pontuacao += 2;
      sinais.add(
        'Pede para ligar ou chamar em outro número diante de um suposto problema.',
      );
    }

    if (temHttpSemTls && (temCredencialOuDinheiro || temUrgencia || citaMarca)) {
      pontuacao += 1;
      sinais.add(
        'O link usa conexão sem proteção (http em vez de https).',
      );
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
        'Continue confirmando quem enviou antes de responder.',
        'Nunca compartilhe senhas ou códigos recebidos por mensagem.',
        'Se ainda tiver dúvida, confira pelo canal oficial do serviço.',
      ],
      NivelRisco.atencao => const <String>[
        'Não toque em links antes de confirmar quem enviou.',
        'Não informe senha, código de verificação nem dados pessoais.',
        'Confira no aplicativo oficial do serviço ou fale com alguém de confiança.',
      ],
      NivelRisco.altoRisco => const <String>[
        'Não toque em nenhum link nem responda esta mensagem.',
        'Nunca envie senha, código de 6 dígitos, foto de documento ou PIX.',
        'Apague ou bloqueie o remetente e confirme pelo telefone oficial do cartão.',
      ],
    };

    return AnaliseGolpe(
      risco: risco,
      origem: OrigemAnalise.localOffline,
      titulo: titulo,
      explicacao: explicacao,
      orientacoes: orientacoes,
      sinaisDetectados: List<String>.unmodifiable(sinais),
      analisadoPorIa: false,
    );
  }

  static String _reconstruirLinksOfuscados(String texto) {
    return texto
        .replaceAll(RegExp(r'\bhxxps://', caseSensitive: false), 'https://')
        .replaceAll(RegExp(r'\bhxxp://', caseSensitive: false), 'http://')
        .replaceAll('[.]', '.')
        .replaceAll('(.)', '.');
  }

  static String _normalizar(String texto) {
    const String acentos = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const String semAcentos = 'aaaaaeeeeiiiiooooouuuucn';
    final String lower = texto.toLowerCase();
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
      r'''(?:https?://|www\.)[^\s<>"')]+|(?:[a-zA-Z0-9-]+\.)+(?:com\.br|gov\.br|org\.br|net\.br|com|br|net|org|xyz|top|click|tk|ml|ga|cf|gq|buzz|info|vip|icu|club|cfd|sbs|cyou|work|support|online|site|shop|ly|co|me|ai|gd|at|in|id|cc|re)(?:@[^\s<>"')]+)?(?:/[^\s<>"')]*)?''',
      caseSensitive: false,
    );

    final List<_UrlExtraida> encontradas = <_UrlExtraida>[];
    for (final RegExpMatch match in regex.allMatches(texto)) {
      final String bruto = match.group(0)!.replaceAll(RegExp(r'[.,;:!?]+$'), '');
      if (bruto.isEmpty) continue;

      final bool ehHttp = bruto.toLowerCase().startsWith('http://');
      final String comEsquema =
          RegExp(r'^https?://', caseSensitive: false).hasMatch(bruto)
          ? bruto
          : 'https://$bruto';

      final Uri? uri = Uri.tryParse(comEsquema);
      String host = '';
      bool temUserinfo = false;
      if (uri != null && uri.host.isNotEmpty) {
        host = uri.host.toLowerCase();
        temUserinfo = uri.userInfo.isNotEmpty;
      } else {
        final String semEsquema = comEsquema.replaceFirst(
          RegExp(r'^https?://', caseSensitive: false),
          '',
        );
        final String autoridade = semEsquema.split('/').first;
        if (autoridade.contains('@')) {
          temUserinfo = true;
          host = autoridade.split('@').last.split(':').first.toLowerCase();
        } else {
          host = autoridade.split(':').first.toLowerCase();
        }
      }

      if (host.startsWith('www.')) {
        host = host.substring(4);
      }
      if (host.isEmpty) continue;

      encontradas.add(
        _UrlExtraida(
          host: host,
          temUserinfo: temUserinfo,
          ehHttpInseguro: ehHttp,
        ),
      );
    }

    // Também captura URLs com IP puro caso não casem com a lista de TLDs acima.
    final RegExp regexIp = RegExp(
      r'https?://(?:\d{1,3}\.){3}\d{1,3}(?::\d+)?(?:/[^\s]*)?',
      caseSensitive: false,
    );
    for (final RegExpMatch match in regexIp.allMatches(texto)) {
      final String bruto = match.group(0)!;
      final Uri? uri = Uri.tryParse(bruto);
      if (uri == null || uri.host.isEmpty) continue;
      final String host = uri.host.toLowerCase();
      if (!encontradas.any((_UrlExtraida u) => u.host == host)) {
        encontradas.add(
          _UrlExtraida(
            host: host,
            temUserinfo: uri.userInfo.isNotEmpty,
            ehHttpInseguro: bruto.toLowerCase().startsWith('http://'),
          ),
        );
      }
    }

    return encontradas;
  }

  static bool _ehIp(String host) {
    final RegExp ip = RegExp(r'^\d{1,3}(?:\.\d{1,3}){3}$');
    return ip.hasMatch(host);
  }

  static bool _ehDominioOficial(String host) {
    for (final String oficial in _dominiosOficiais) {
      if (host == oficial || host.endsWith('.$oficial')) {
        return true;
      }
    }
    return false;
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
      'banco',
      'itau',
      'bradesco',
      'santander',
      'caixa',
      'nubank',
      'correios',
      'serasa',
      'inss',
      'receita',
      'govbr',
      'whatsapp',
      'mercadopago',
      'mercadolivre',
    ];
    for (final String marca in marcasNoHost) {
      if (norm.contains(marca)) return true;
    }
    return false;
  }

  static bool _citaMarcaVigiada(String normalizado) {
    for (final String marca in _marcasVigiadas) {
      final RegExp re = RegExp(
        '(?<![a-z0-9])${RegExp.escape(marca)}(?![a-z0-9])',
      );
      if (re.hasMatch(normalizado)) return true;
    }
    return false;
  }

  static bool _contemQualquer(String normalizado, List<String> termos) {
    for (final String termo in termos) {
      if (normalizado.contains(termo)) return true;
    }
    return false;
  }
}

class _UrlExtraida {
  final String host;
  final bool temUserinfo;
  final bool ehHttpInseguro;

  const _UrlExtraida({
    required this.host,
    required this.temUserinfo,
    required this.ehHttpInseguro,
  });
}

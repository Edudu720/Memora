import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design_system/design_system.dart';
import '../../../l10n/textos_perfil.dart';
import '../data/data_de_nascimento_local.dart';
import '../domain/data_de_nascimento.dart';

/// A tela em que a pessoa conta quando nasceu (T123, FR-042c).
///
/// Três campos numéricos **separados** — dia, mês e ano — em vez de um seletor
/// de calendário: quem nasceu em 1948 teria de voltar século a século num
/// calendário feito para marcar consultas. Dia e mês, a pessoa sabe de cor.
///
/// Os campos ficam **um embaixo do outro**: lado a lado, rótulo e ajuda não
/// cabem num 320 dp com o texto a 200%.
///
/// Termina com `pop(true)` quando guardou e `pop(null)` quando desistiu.
class TelaDataDeNascimento extends StatefulWidget {
  /// Onde a data é guardada.
  final ArmazenamentoDaDataDeNascimento armazenamento;

  /// A conta a que a data pertence.
  final String idDaConta;

  /// O que preencher de início, se já houver data.
  final DataDeNascimento? inicial;

  /// O dia de hoje; injetável para o teste.
  final DateTime Function() agora;

  /// Cria a tela.
  const TelaDataDeNascimento({
    required this.armazenamento,
    required this.idDaConta,
    this.inicial,
    this.agora = DateTime.now,
    super.key,
  });

  /// Chave do campo do dia.
  static const Key chaveDia = Key('perfil.data.dia');

  /// Chave do campo do mês.
  static const Key chaveMes = Key('perfil.data.mes');

  /// Chave do campo do ano.
  static const Key chaveAno = Key('perfil.data.ano');

  /// Chave do botão de guardar.
  static const Key chaveGuardar = Key('perfil.data.guardar');

  /// Chave do aviso de que não foi possível guardar.
  static const Key chaveErroAoGuardar = Key('perfil.data.erro_ao_guardar');

  /// Chave do botão de cancelar.
  static const Key chaveCancelar = Key('perfil.data.cancelar');

  @override
  State<TelaDataDeNascimento> createState() => _TelaDataDeNascimentoState();
}

class _TelaDataDeNascimentoState extends State<TelaDataDeNascimento> {
  late final TextEditingController _dia = TextEditingController(
    text: widget.inicial?.dia.toString() ?? '',
  );
  late final TextEditingController _mes = TextEditingController(
    text: widget.inicial?.mes.toString() ?? '',
  );
  late final TextEditingController _ano = TextEditingController(
    text: widget.inicial?.ano.toString() ?? '',
  );

  ProblemaDaData? _problema;
  bool _guardando = false;
  bool _falhou = false;

  @override
  void dispose() {
    _dia.dispose();
    _mes.dispose();
    _ano.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final ResultadoDaData resultado = DataDeNascimento.validar(
      dia: _dia.text,
      mes: _mes.text,
      ano: _ano.text,
      hoje: widget.agora(),
    );
    final DataDeNascimento? data = resultado.data;
    if (data == null) {
      setState(() => _problema = resultado.problema);
      return;
    }
    setState(() {
      _problema = null;
      _falhou = false;
      _guardando = true;
    });
    try {
      await widget.armazenamento.guardar(widget.idDaConta, data);
    } catch (_) {
      // Sem isto os dois botões ficariam desabilitados para sempre.
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _falhou = true;
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  bool _vazio(TextEditingController c) => int.tryParse(c.text.trim()) == null;

  /// O mês digitado não existe (0, 13...): o erro é do Mês, e não do Dia.
  bool _mesForaDoCalendario() {
    final int? mes = int.tryParse(_mes.text.trim());
    return mes != null && (mes < 1 || mes > 12);
  }

  /// O erro do campo, se for dele.
  ///
  /// Cada problema aponta para o campo que a pessoa precisa olhar: o que não
  /// existe no calendário é o dia ou o mês; o que ainda não chegou ou ficou
  /// longe demais é o ano; o que falta é o primeiro campo vazio.
  String? _erroDia() => switch (_problema) {
    ProblemaDaData.incompleta when _vazio(_dia) => TextosPerfil.erroIncompleta,
    ProblemaDaData.impossivel when !_mesForaDoCalendario() =>
      TextosPerfil.erroImpossivel,
    _ => null,
  };

  String? _erroMes() => switch (_problema) {
    ProblemaDaData.incompleta when !_vazio(_dia) && _vazio(_mes) =>
      TextosPerfil.erroIncompleta,
    ProblemaDaData.impossivel when _mesForaDoCalendario() =>
      TextosPerfil.erroImpossivel,
    _ => null,
  };

  String? _erroAno() => switch (_problema) {
    ProblemaDaData.incompleta when !_vazio(_dia) && !_vazio(_mes) =>
      TextosPerfil.erroIncompleta,
    ProblemaDaData.anoCurto => TextosPerfil.erroAnoCurto,
    ProblemaDaData.futura => TextosPerfil.erroFutura,
    ProblemaDaData.antiga => TextosPerfil.erroAntiga,
    _ => null,
  };

  Widget _campo({
    required Key chave,
    required String rotulo,
    required String ajuda,
    required TextEditingController controlador,
    required int tamanho,
    required String? erro,
  }) {
    return CampoTexto(
      key: chave,
      rotulo: rotulo,
      textoAjuda: ajuda,
      controlador: controlador,
      tipoTeclado: TextInputType.number,
      formatadores: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(tamanho),
      ],
      erro: erro,
      habilitado: !_guardando,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.memora.cores.fundo,
      appBar: BarraSuperior(
        titulo: TextosPerfil.tituloEntrada,
        aoVoltar: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MemoraEspacamento.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CaixaDeEtapa(
              instrucao: TextosPerfil.instrucaoCamposData,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _campo(
                    chave: TelaDataDeNascimento.chaveDia,
                    rotulo: TextosPerfil.rotuloDia,
                    ajuda: TextosPerfil.ajudaDia,
                    controlador: _dia,
                    tamanho: 2,
                    erro: _erroDia(),
                  ),
                  const SizedBox(height: MemoraEspacamento.xl),
                  _campo(
                    chave: TelaDataDeNascimento.chaveMes,
                    rotulo: TextosPerfil.rotuloMes,
                    ajuda: TextosPerfil.ajudaMes,
                    controlador: _mes,
                    tamanho: 2,
                    erro: _erroMes(),
                  ),
                  const SizedBox(height: MemoraEspacamento.xl),
                  _campo(
                    chave: TelaDataDeNascimento.chaveAno,
                    rotulo: TextosPerfil.rotuloAno,
                    ajuda: TextosPerfil.ajudaAno,
                    controlador: _ano,
                    tamanho: 4,
                    erro: _erroAno(),
                  ),
                ],
              ),
            ),
            if (_falhou) ...<Widget>[
              const SizedBox(height: MemoraEspacamento.lg),
              const TextoMemora(
                TextosPerfil.erroAoGuardar,
                key: TelaDataDeNascimento.chaveErroAoGuardar,
                estilo: EstiloTexto.corpoForte,
              ),
            ],
            const SizedBox(height: MemoraEspacamento.lg),
            CaixaDeEtapa(
              instrucao: TextosPerfil.instrucaoAcoesData,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  BotaoPrimario(
                    key: TelaDataDeNascimento.chaveGuardar,
                    rotulo: TextosPerfil.botaoGuardar,
                    icone: Icons.check_rounded,
                    carregando: _guardando,
                    aoTocar: _guardando ? null : _guardar,
                  ),
                  const SizedBox(height: MemoraEspacamento.md),
                  BotaoSecundario(
                    key: TelaDataDeNascimento.chaveCancelar,
                    rotulo: TextosPerfil.botaoCancelar,
                    aoTocar:
                        _guardando ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

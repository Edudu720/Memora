import 'package:flutter/material.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entidades/contato_emergencia.dart';

/// Modal para cadastrar ou editar o contato de emergência.
class DialogoContatoEmergencia extends StatefulWidget {
  /// Cria o diálogo de contato de emergência.
  const DialogoContatoEmergencia({
    this.contatoAtual,
    required this.aoSalvar,
    super.key,
  });

  /// Contato já cadastrado para edição, se houver.
  final ContatoEmergencia? contatoAtual;

  /// Callback acionado ao salvar um contato válido.
  final ValueChanged<ContatoEmergencia> aoSalvar;

  /// Exibe o diálogo modal para cadastro ou edição do contato de emergência.
  static Future<void> exibir({
    required BuildContext context,
    ContatoEmergencia? contatoAtual,
    required ValueChanged<ContatoEmergencia> aoSalvar,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => DialogoContatoEmergencia(
        contatoAtual: contatoAtual,
        aoSalvar: aoSalvar,
      ),
    );
  }

  @override
  State<DialogoContatoEmergencia> createState() =>
      _DialogoContatoEmergenciaState();
}

class _DialogoContatoEmergenciaState extends State<DialogoContatoEmergencia> {
  late final TextEditingController _controladorNome;
  late final TextEditingController _controladorTelefone;
  late final TextEditingController _controladorParentesco;

  String? _erroValidacao;

  @override
  void initState() {
    super.initState();
    _controladorNome = TextEditingController(text: widget.contatoAtual?.nome ?? '');
    _controladorTelefone =
        TextEditingController(text: widget.contatoAtual?.telefone ?? '');
    _controladorParentesco =
        TextEditingController(text: widget.contatoAtual?.parentesco ?? '');
  }

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorTelefone.dispose();
    _controladorParentesco.dispose();
    super.dispose();
  }

  void _salvar() {
    final ContatoEmergencia novoContato = ContatoEmergencia(
      id: widget.contatoAtual?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nome: _controladorNome.text.trim(),
      telefone: _controladorTelefone.text.trim(),
      parentesco: _controladorParentesco.text.trim(),
    );

    if (!novoContato.ehValido) {
      setState(() {
        _erroValidacao =
            'Por favor, preencha o nome e um telefone com DDD (10 ou 11 números).';
      });
      return;
    }

    widget.aoSalvar(novoContato);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final MemoraCores cores = context.memora.cores;

    return Dialog(
      backgroundColor: cores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MemoraRaio.padrao),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MemoraEspacamento.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Contato de Emergência',
              style: MemoraTipografia.tituloSecao.copyWith(
                color: cores.texto,
                fontWeight: FontWeight.bold,
              ),
              textScaler: escalaTextoLimitada(context),
            ),
            const SizedBox(height: MemoraEspacamento.xs),
            Text(
              'Pessoa de confiança que avisaremos se você sofrer uma queda e não responder.',
              style: MemoraTipografia.apoio.copyWith(
                color: cores.textoSuave,
              ),
              textScaler: escalaTextoLimitada(context),
            ),
            const SizedBox(height: MemoraEspacamento.md),
            CampoTexto(
              rotulo: 'Nome do contato',
              textoAjuda: 'Como a pessoa se chama (ex.: Filha Mariana)',
              controlador: _controladorNome,
            ),
            const SizedBox(height: MemoraEspacamento.sm),
            CampoTexto(
              rotulo: 'Telefone com DDD',
              textoAjuda: 'Número com DDD (ex.: 19 98765-4321)',
              tipoTeclado: TextInputType.phone,
              controlador: _controladorTelefone,
            ),
            const SizedBox(height: MemoraEspacamento.sm),
            CampoTexto(
              rotulo: 'Parentesco ou relação',
              textoAjuda: 'Qual o vínculo (ex.: Filho, Cuidador, Vizinho)',
              controlador: _controladorParentesco,
            ),
            if (_erroValidacao != null) ...<Widget>[
              const SizedBox(height: MemoraEspacamento.sm),
              Text(
                _erroValidacao!,
                style: MemoraTipografia.apoio.copyWith(
                  color: cores.perigo,
                  fontWeight: FontWeight.bold,
                ),
                textScaler: escalaTextoLimitada(context),
              ),
            ],
            const SizedBox(height: MemoraEspacamento.lg),
            BotaoPrimario(
              rotulo: 'Salvar contato',
              aoTocar: _salvar,
            ),
            const SizedBox(height: MemoraEspacamento.sm),
            BotaoSecundario(
              rotulo: 'Cancelar',
              aoTocar: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
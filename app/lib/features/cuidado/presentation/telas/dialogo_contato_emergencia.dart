import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../../../l10n/textos_cuidado.dart';
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
  late final TextEditingController _controladorEmail;
  late final TextEditingController _controladorParentesco;

  String? _erroValidacao;

  @override
  void initState() {
    super.initState();
    _controladorNome =
        TextEditingController(text: widget.contatoAtual?.nome ?? '');
    _controladorTelefone =
        TextEditingController(text: widget.contatoAtual?.telefone ?? '');
    _controladorEmail =
        TextEditingController(text: widget.contatoAtual?.email ?? '');
    _controladorParentesco =
        TextEditingController(text: widget.contatoAtual?.parentesco ?? '');
  }

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorTelefone.dispose();
    _controladorEmail.dispose();
    _controladorParentesco.dispose();
    super.dispose();
  }

  void _salvar() {
    final ContatoEmergencia novoContato = ContatoEmergencia(
      id: widget.contatoAtual?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      nome: _controladorNome.text.trim(),
      telefone: _controladorTelefone.text.trim(),
      email: _controladorEmail.text.trim(),
      parentesco: _controladorParentesco.text.trim(),
    );

    if (!novoContato.ehValido) {
      setState(() {
        _erroValidacao = TextosCuidado.erroTelefoneContato;
      });
      return;
    }

    if (!novoContato.emailValidoOuVazio) {
      setState(() {
        _erroValidacao = TextosCuidado.erroEmailContato;
      });
      return;
    }

    widget.aoSalvar(novoContato);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final MemoraTheme tema = context.memora;
    final MemoraCores cores = tema.cores;
    final bool ehAltoContraste = tema.id == MemoraTemaId.altoContraste;
    final double escala = MediaQuery.textScalerOf(context).scale(1);

    return Dialog(
      backgroundColor: cores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MemoraRaio.cartao),
        side: ehAltoContraste
            ? BorderSide(
                color: cores.borda,
                width: MemoraDimensoes.bordaEnfase,
              )
            : BorderSide.none,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MemoraEspacamento.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (escala < MemoraDimensoes.escalaTextoAlta) ...<Widget>[
                  Container(
                    width: MemoraDimensoes.badgeAtalhoRapido,
                    height: MemoraDimensoes.badgeAtalhoRapido,
                    decoration: BoxDecoration(
                      color: ehAltoContraste
                          ? cores.superficieSutil
                          : cores.saudeSuave,
                      borderRadius: BorderRadius.circular(MemoraRaio.badge),
                      border: ehAltoContraste
                          ? Border.all(
                              color: cores.borda,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.contact_phone_rounded,
                      color: cores.sucessoTexto,
                      size: MemoraDimensoes.iconePadrao,
                    ),
                  ),
                  const SizedBox(width: MemoraEspacamento.sm),
                ],
                const Expanded(
                  child: TextoMemora(
                    TextosCuidado.tituloContatoEmergencia,
                    estilo: EstiloTexto.tituloSecao,
                    cabecalho: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MemoraEspacamento.xs),
            TextoMemora.apoio(
              TextosCuidado.subtituloDialogoContato,
              cor: cores.textoSuave,
            ),
            const SizedBox(height: MemoraEspacamento.md),
            CampoTexto(
              rotulo: TextosCuidado.rotuloNomeContato,
              textoAjuda: TextosCuidado.ajudaNomeContato,
              controlador: _controladorNome,
            ),
            const SizedBox(height: MemoraEspacamento.sm),
            CampoTexto(
              rotulo: TextosCuidado.rotuloTelefoneContato,
              textoAjuda: TextosCuidado.ajudaTelefoneContato,
              tipoTeclado: TextInputType.phone,
              controlador: _controladorTelefone,
            ),
            const SizedBox(height: MemoraEspacamento.sm),
            CampoTexto(
              rotulo: TextosCuidado.rotuloEmailContato,
              textoAjuda: TextosCuidado.ajudaEmailContato,
              tipoTeclado: TextInputType.emailAddress,
              controlador: _controladorEmail,
            ),
            const SizedBox(height: MemoraEspacamento.sm),
            CampoTexto(
              rotulo: TextosCuidado.rotuloParentescoContato,
              textoAjuda: TextosCuidado.ajudaParentescoContato,
              controlador: _controladorParentesco,
            ),
            if (_erroValidacao != null) ...<Widget>[
              const SizedBox(height: MemoraEspacamento.sm),
              BadgeDeStatus(
                rotulo: _erroValidacao!,
                icone: Icons.error_outline_rounded,
                tom: TomBadgeStatus.atencao,
              ),
            ],
            const SizedBox(height: MemoraEspacamento.lg),
            BotaoPrimario(
              rotulo: TextosCuidado.botaoSalvarContato,
              aoTocar: _salvar,
            ),
            const SizedBox(height: MemoraEspacamento.sm),
            BotaoSecundario(
              rotulo: TextosCuidado.botaoCancelarContato,
              aoTocar: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

/// Vitrine provisória dos componentes, para testar no aparelho.
///
/// **Não é a galeria da T045.** Esta tela existe apenas para permitir tocar nos
/// componentes durante o desenvolvimento; a galeria definitiva mostrará todos
/// os estados nos três temas e ficará restrita a builds de desenvolvimento.
class TelaComponentes extends StatefulWidget {
  /// Cria a vitrine de componentes.
  const TelaComponentes({super.key});

  @override
  State<TelaComponentes> createState() => _TelaComponentesState();
}

class _TelaComponentesState extends State<TelaComponentes> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _senha = TextEditingController();
  final TextEditingController _codigo = TextEditingController();
  String? _erroEmail;
  String _ultimaResposta = 'Nenhuma resposta ainda';

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    _codigo.dispose();
    super.dispose();
  }

  void _responder(String resposta) {
    setState(() => _ultimaResposta = resposta);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.memora.cores.fundo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(MemoraEspacamento.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const TextoMemora.tituloTela('Componentes'),

              const SizedBox(height: MemoraEspacamento.xxl),
              const TextoMemora.tituloSecao('Informação × Ação'),
              const SizedBox(height: MemoraEspacamento.md),
              const ListaInformacao(
                campos: <CampoInformacao>[
                  CampoInformacao(
                    rotulo: 'Nome',
                    valor: 'Ana',
                    icone: Icons.person_outline,
                  ),
                  CampoInformacao(
                    rotulo: 'Idade',
                    valor: '72 anos',
                    icone: Icons.cake_outlined,
                  ),
                ],
              ),
              const SizedBox(height: MemoraEspacamento.md),
              const DestaqueInformacao(
                rotulo: 'Seu plano',
                valor: 'Premium',
                icone: Icons.star_outline,
              ),
              const SizedBox(height: MemoraEspacamento.md),
              BotaoPrimario(
                rotulo: 'Isto é um botão',
                icone: Icons.touch_app,
                aoTocar: () => _responder('Você tocou no botão primário'),
              ),

              const SizedBox(height: MemoraEspacamento.xxl),
              const TextoMemora.tituloSecao('Confirmação da Memora'),
              const SizedBox(height: MemoraEspacamento.md),
              ConfirmacaoMemora(
                pergunta: 'Quer que eu abra o Instagram para você?',
                rotuloConfirmar: 'Sim, pode abrir',
                rotuloRecusar: 'Agora não',
                aoConfirmar: () => _responder('Você disse: pode abrir'),
                aoRecusar: () => _responder('Você disse: agora não'),
              ),
              const SizedBox(height: MemoraEspacamento.md),
              ConfirmacaoMemora.irreversivel(
                pergunta: 'Quer apagar todas as suas fotos?',
                aviso: 'Depois de apagar, não dá para trazer de volta.',
                rotuloConfirmar: 'Sim, quero apagar',
                rotuloRecusar: 'Não, deixa como está',
                aoConfirmar: () => _responder('Apagou (de mentirinha)'),
                aoRecusar: () => _responder('Você desistiu de apagar'),
              ),
              const SizedBox(height: MemoraEspacamento.md),
              Cartao(child: TextoMemora('Resposta: $_ultimaResposta')),

              const SizedBox(height: MemoraEspacamento.xxl),
              const TextoMemora.tituloSecao('Campos'),
              const SizedBox(height: MemoraEspacamento.md),
              CampoTexto(
                rotulo: 'Seu e-mail',
                textoAjuda: 'Usamos para você entrar e recuperar a senha',
                controlador: _email,
                erro: _erroEmail,
                tipoTeclado: TextInputType.emailAddress,
                aoMudar: (String valor) => setState(() {
                  _erroEmail = valor.contains('@') || valor.isEmpty
                      ? null
                      : 'Não consegui entender esse e-mail. Pode conferir?';
                }),
              ),
              const SizedBox(height: MemoraEspacamento.lg),
              CampoSenha(
                rotulo: 'Crie sua senha',
                textoAjuda: 'Use uma frase que só você lembre',
                controlador: _senha,
              ),
              const SizedBox(height: MemoraEspacamento.lg),
              CampoSenha(
                rotulo: 'Senha no modo assistido',
                textoAjuda: 'Aqui não existe o botão de mostrar',
                permitirRevelar: false,
              ),
              const SizedBox(height: MemoraEspacamento.lg),
              CampoCodigo(rotulo: 'Código que enviamos', controlador: _codigo),

              const SizedBox(height: MemoraEspacamento.xxl),
              const TextoMemora.tituloSecao('Retorno ao usuário'),
              const SizedBox(height: MemoraEspacamento.md),
              const Carregando(mensagem: 'Estou entrando na sua conta...'),
              const SizedBox(height: MemoraEspacamento.lg),
              MensagemErro(
                mensagem: 'Não consegui conectar à internet.',
                aoTentarNovamente: () => _responder('Tentou de novo'),
              ),
              const SizedBox(height: MemoraEspacamento.lg),
              EstadoVazio(
                titulo: 'Nenhuma conversa ainda',
                explicacao:
                    'Quando você falar comigo, tudo fica guardado aqui.',
                rotuloAcao: 'Falar com a Memora',
                aoAgir: () => _responder('Abriu a conversa'),
              ),
              const SizedBox(height: MemoraEspacamento.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

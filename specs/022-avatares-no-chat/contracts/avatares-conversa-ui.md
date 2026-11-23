# Contrato de Interface UI: Avatares nos Balões de Conversa

**Feature**: `022-avatares-no-chat` | **Date**: 2026-11-22

---

## 1. `BalaoDeFala` (`app/lib/design_system/componentes/conversa/balao_de_fala.dart`)

### Assinatura pública

```dart
class BalaoDeFala extends StatelessWidget {
  final AutorDoBalao autor;
  final String? texto;
  final List<OpcaoDoBalao> opcoes;
  final bool escreverAosPoucos;
  final bool emAndamento;
  final VoidCallback? aoEscrever;
  final ValueChanged<bool>? aoMudarEscrita;
  final bool comRosto;
  final ExpressaoDaMemora expressaoDaMemora;
  final Widget? avatarPessoa;   // NOVO: widget decorativo para AutorDoBalao.pessoa
  final bool rostoAnimado;      // NOVO: default true; false desliga animações e toque no rosto
  ...
}
```

Construtor nomeado `BalaoDeFala.escrevendo({this.comRosto = true, this.rostoAnimado = true, super.key})` mantém compatibilidade com todos os pontos existentes.

### Garantias de contrato
1. **Isolamento do Design System**: `BalaoDeFala` NÃO importa nada de `features/`. Quando `autor == AutorDoBalao.pessoa`, renderiza `avatarPessoa ?? _RostoDaPessoa(cores: cores)`.
2. **Posicionamento simétrico**:
   - `autor == AutorDoBalao.memora` e `comRosto == true`: `[rosto, SizedBox(width: MemoraEspacamento.sm), balao]`, alinhado à esquerda (`MainAxisAlignment.start`).
   - `autor == AutorDoBalao.pessoa` e `comRosto == true`: `[balao, SizedBox(width: MemoraEspacamento.sm), rosto]`, alinhado à direita (`MainAxisAlignment.end`).
   - `comRosto == false`: `[balao]` ocupando largura plena disponível.
3. **Controle de animação e predicado de teste (`rostoAnimado`)**:
   - Quando `rostoAnimado == false` e `autor == AutorDoBalao.memora`, o `MemoraPersonagem` recebe `reageAoToque: false` e é envolvido em `MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), ...)`.
   - Nenhuma fala na lista dispara animação de entrada, respiração ou aceno ao toque quando `rostoAnimado == false`.
   - **Invariante verificável em testes de conversa** (incluindo quando o usuário seleciona `AvatarIlustrado` no Perfil): fora de `BalaoDeFala`, há no máximo `1` `MemoraAnimada` na tela (a da `BarraSuperior`); dentro de qualquer `BalaoDeFala` da lista de conversa, toda `MemoraAnimada` presente possui `reageAoToque == false` e ancestral `MediaQuery` com `disableAnimations == true`.
4. **Semântica**:
   - A árvore de `Semantics` do texto continua exclusivamente no `Container` do `balao` (`"Memora disse: ..."`, `"Você disse: ..."`, `"Memora está escrevendo…"`).
   - O slot `rosto` (`MemoraPersonagem` sem `descricao`, `_RostoDaPessoa` com `ExcludeSemantics`, ou `avatarPessoa` envolvido em `ExcludeSemantics`) permanece completamente invisível a leitores de tela.

---

## 2. `TelaConversa` (`app/lib/features/assistente/presentation/telas/tela_conversa.dart`)

### Assinatura pública

```dart
class TelaConversa extends StatefulWidget {
  final ControladorConversa controlador;
  final VoidCallback? aoVoltar;
  final ArmazenamentoDeFotoDePerfil? fotoDePerfil; // NOVO (opcional)
  final String? idDaConta;                         // NOVO (opcional)
  final String? nomeDaPessoa;                      // NOVO (opcional)
  ...
}
```

### Garantias de contrato
1. **Regra de exibição por escala tipográfica**:
   - `final bool mostrarRosto = escala < MemoraDimensoes.escalaTextoAlta;` (`1.75`).
   - Aplica-se uniformemente a: balão de convite (`chaveConvite`), balões de histórico/mensagens (`_fala`), balão `BalaoDeFala.escrevendo` e balão de resposta em streaming.
2. **Configuração do rosto nos balões da conversa**:
   - Em todo balão da conversa com `mostrarRosto == true`: `comRosto: true` e `rostoAnimado: false`.
   - A única Memora com animação ativa e boca sincronizada com a fala continua sendo a `BarraSuperior(memora: ExpressaoDaMemora.neutra, memoraFalando: ...)`.
3. **Construção do `avatarPessoa` e zero layout shift**:
   - Tamanho fixo vinculado ao token `MemoraDimensoes.pisoDeIlustracao` (`40 dp`), reservando exatamente o mesmo quadrado antes e depois da resolução do `Future` local de retrato (zero salto visual / *layout shift* ao carregar `FotoPropriaDePerfil` ou `AvatarIlustrado`).
   - Em `RetratoDoPerfil._padraoNeutro`, as iniciais puramente decorativas são protegidas por ajuste proporcional (`FittedBox(fit: BoxFit.scaleDown)` / sem estourar `40 dp` na escala `150%`).
   - Se `(fotoDePerfil != null && (idDaConta?.trim().isNotEmpty ?? false)) || _temNomeValido(nomeDaPessoa)`: retorna `ExcludeSemantics(child: RetratoDoPerfil(nome: nomeDaPessoa ?? '', retrato: _retrato, tamanho: MemoraDimensoes.pisoDeIlustracao))`.
   - Caso contrário (tela montada em isolamento sem conta nem nome): passa `avatarPessoa: null`, renderizando `_RostoDaPessoa`.
4. **Sincronização reativa**:
   - `TelaConversa` nunca escreve nem apaga fotos; apenas lê via `fotoDePerfil.ler(idDaConta)` e reage a `fotoDePerfil.alteracoes`.

---

## 3. `ArmazenamentoDeFotoDePerfil` (`app/lib/features/perfil/data/foto_de_perfil_local.dart`)

- Exige `Stream<void> get alteracoes;` em `FotoDePerfilLocal` e `FotoDePerfilEmMemoria`.
- Emite notificação após conclusão bem-sucedida de escrita/remoção em disco ou memória (protegida por `if (!_alteracoes.isClosed) _alteracoes.add(null)`) para que ouvintes re-consultem `ler(idDaConta)` com consistência.

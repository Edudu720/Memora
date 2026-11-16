# Modelo de Dados Visuais, Entidades de Voz e Tokens — Feature 007

Este documento define as extensões estruturais nos tokens/componentes do Design System (`app/lib/design_system/`) e os contratos de domínio/estado da entrada por voz (`app/lib/features/assistente/`). Não altera esquema de banco nem endpoints do backend.

---

## 1. Extensões em `MemoraCores` (`app/lib/design_system/tokens/cores.dart`)

| Token | Propósito | Claro (Base Azul) | Escuro (Base Azul) | Alto Contraste (Base Azul) | Regra WCAG / Paleta |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `fundo` *(refinado)* | Canvas de fundo das telas | `#F4F6FA` | `#0F141E` | `#000000` | Contraste `>= 4.5:1` com `texto`, separa do cartão `#FFFFFF` |
| `superficie` | Fundo padrão dos cartões | `#FFFFFF` | `#182030` | `#0A0A0A` | Contraste `>= 4.5:1` / `>= 7.0:1` com `texto` |
| `superficieSutil` | Fundo de badges tonais, cabeçalho de etapa e balão da pessoa | `#EEF2FA` | `#222C40` | `#141414` | Varia por paleta em `PaletaDeDestaque` |
| `superficieBarra` | Fundo da `NavegacaoInferior` e barra de digitação inferior | `#FFFFFF` | `#161E2C` | `#000000` | Substitui `#D8D8D8` chapado |
| `bordaSutil` | Divisores `1 px` não-interativos e separadores leves | `#E2E8F0` | `#2B364B` | `#FFFFFF` | Decorativo no Claro/Escuro; `>= 3:1` no Alto Contraste |
| `borda` *(mantido)* | Borda obrigatória de inputs, foco, opções e cartões em Alto Contraste | `#596475` | `#8EA0BD` | `#FFFFFF` | Sempre `>= 3.0:1` contra `fundo` e `superficie` |
| `gradienteHeroiInicio` | Stop inicial de `CartaoHeroi` (`Início` / `Hub`) | `#155EEF` | `#1E40AF` | Igual a `primaria` (sólido) | Par validado com `sobreGradienteHeroi >= 4.5:1` (`7.0:1` AC) |
| `gradienteHeroiFim` | Stop final de `CartaoHeroi` | `#0B3BC2` | `#162E7A` | Igual a `primaria` (sólido) | Par validado com `sobreGradienteHeroi >= 4.5:1` (`7.0:1` AC) |
| `sobreGradienteHeroi` | Texto e ícones sobre o gradiente herói | `#FFFFFF` | `#FFFFFF` | Igual a `sobrePrimaria` | Sempre `>= 4.5:1` contra ambos os stops |
| `gradienteSaudeInicio` | Stop inicial de `PainelHeroi` em `Cuidado` | `#0E7490` | `#0F5266` | Igual a `primaria` | Inspirado em `7fe4db`, contrastando `>= 4.5:1` com `sobreGradienteSaude` |
| `gradienteSaudeFim` | Stop final de `PainelHeroi` em `Cuidado` | `#155EEF` | `#183C8C` | Igual a `primaria` | Mesma exigência contra `sobreGradienteSaude` |
| `sobreGradienteSaude` | Texto e ícones sobre gradiente de Saúde | `#FFFFFF` | `#FFFFFF` | Igual a `sobrePrimaria` | Sempre `>= 4.5:1` contra ambos os stops |
| `saudeSuave` | Fundo tonal de badges de vitais / sucesso leve | `#E6F6F4` | `#123532` | `#0A0A0A` | Usado em `BadgeDeStatus` e métricas de `Cuidado` |
| `sucessoTexto` | Texto de selos positivos (`"✓ Eu te ensino"`, `"Normal"`) | `#0F6A43` | `#6EE7B7` | `#80FFAA` | `>= 4.5:1` sobre `superficie` e `saudeSuave` |

> Todas as 6 paletas existentes (`azul`, `verde`, `roxo`, `laranja-terra`, `rosa`, `grafite`) em `PaletaDeDestaque` recebem `superficieSutilClaro/Escuro`, `gradienteHeroiInicioClaro/Escuro`, `gradienteHeroiFimClaro/Escuro` e `sobreGradienteHeroiClaro/Escuro`, aplicadas via `comPaleta(...)` (mantendo o isolamento no modo `altoContraste`) e validadas em `validar_paleta.py` e `contraste_test.dart`.

---

## 2. Extensões em `MemoraRaio`, `MemoraElevacao`, `MemoraDimensoes` e Uso Tipográfico

| Arquivo | Novo Token / Ajuste | Valor (dp/px) | Uso / Escala Tipográfica Associada |
| :--- | :--- | :--- | :--- |
| `raio.dart` | `cartaoDestaque` *(novo alias explícito)* | `24.0` | `CartaoHeroi`, `PainelHeroi`, `TelaVerificacaoQueda` (`MemoraRaio.cartao` permanece `24.0`) |
| `raio.dart` | `cartaoMedio` *(novo)* | `20.0` | `TileAcaoRapida` e sub-blocos compactos |
| `raio.dart` | `badge` *(novo)* | `14.0` | Badges quadrados arredondados em grades (`design-1`, `7fe4db`) |
| `elevacao.dart` | `sombraCartaoDifusa`, `sombraContato`, `listaSombrasCartao(MemoraCores)` | `blur 16, offset (0, 4)` + `blur 3, offset (0, 1)` | Sombras difusas para `Cartao`, `TileAcaoRapida` e `CaixaDeEtapa`; lista vazia no `altoContraste` |
| `elevacao.dart` | `sombraBarra`, `listaSombrasBarra(MemoraCores)` | `blur 20, offset (0, -4)` | Elevação limpa da `NavegacaoInferior` e barra inferior de chat |
| `dimensoes.dart` | `badgeAtalhoRapido` | `48.0` | Container do ícone em `TileAcaoRapida` e `LinhaDeLista` |
| `dimensoes.dart` | `espessuraBordaSutil` | `1.0` | Divisores leves e contorno de cartão no Claro/Escuro |
| `dimensoes.dart` | `indicadorAtivoBarra` | `3.0` | Barra indicadora superior da aba ativa em `NavegacaoInferior` |
| `tipografia.dart` *(mapeamento nos novos widgets)* | Títulos herói / atalho / status | `tituloSecao (24)`, `corpoForte (18)`, `apoio (16)` | `CartaoHeroi`/`PainelHeroi` (`tituloSecao` + `destaque` para BPM), `TileAcaoRapida` (`corpoForte` + `apoio`), `BadgeDeStatus` (`apoio` com piso `16 sp`), `LinhaDeLista` (`corpoForte` + `apoio`), `ChipFiltro` (`apoio` em negrito) |

---

## 3. Evolução Retrocompatível de `ExpressaoDaMemora` (`memora_personagem.dart`)

| Membro do Enum | Status | Asset PNG Oficial | Fundo / Uso Principal |
| :--- | :--- | :--- | :--- |
| `neutra` | *Mantido (sem quebra)* | `assets/ilustracoes/memora_perfil_robo.png` | `TelaBoasVindas`, `TelaInicio`, `TelaPerfil`, `TelaHub` |
| `falando` | *Mantido (sem quebra)* | `assets/ilustracoes/memora_ajuda_robo.png` | `TelaConversa` (recepção), `TelaAjuda`, `AjudaGuiadaDaConversa` |
| `comemorando` | *Mantido (sem quebra)* | `assets/ilustracoes/memora_conclusao_robo.png` | Fim do `TelaPassoAPasso`, confirmação de cadastro/recuperação |
| `preocupada` | *Mantido (sem quebra)* | `assets/ilustracoes/memora_alerta_robo.png` | `AvisoCompacto`, `TelaVerificacaoQueda`, `MensagemErro` |
| `dica` | **Novo** | `assets/ilustracoes/memora_dica_robo.png` | `TelaSeletorDeSecao`, `FluxoApresentacao`, dicas de estudo |
| `mini` | **Novo** | `assets/ilustracoes/memora_mini_robo.png` | `BalaoDeFala` (avatar da Memora), cabeçalho compacto de `TelaConversa` e `TelaInicio` |

> Invariante preservado: em temas escuros ou Alto Contraste, `MemoraPersonagem` continua aplicando círculo/medalhão claro atrás do robô azul para impedir perda de contraste do personagem (`memora_personagem.dart:L48`).

---

## 4. Domínio & Estado do Ditado por Voz (`FR-013`)

### `EstadoDitado` (`app/lib/features/assistente/domain/leitor_de_voz.dart`)
- `ocioso`: pronto para iniciar escuta quando a pessoa tocar em `"Falar"`.
- `aguardandoPermissao`: exibindo diálogo explicativo do motivo da permissão de microfone (Princípio II) ou consulta ao sistema operacional.
- `ouvindo`: captura ativa em curso (rótulo alterna para `"Parar"`, feedback visual claro + anúncio semântico).
- `indisponivel`: permissão negada pelo usuário ou dispositivo sem serviço de reconhecimento de fala (digitação permanece 100% utilizável).
- `erro`: falha temporária na escuta com mensagem simples em português sem termos técnicos.

### Interface `LeitorDeVoz`
- Métodos: `Future<bool> verificarDisponibilidade()`, `Future<ResultadoDitado> iniciarEscuta({required void Function(String textoParcial) aoReconhecer})`, `Future<void> pararEscuta()`, `void dispose()`.
- Regras:
  - Resultado preenche apenas o campo de rascunho (`ControladorConversa.escrever`) — **zero envio automático**.
  - Nenhum arquivo de áudio gravado em armazenamento permanente; zero log de fala em produção.

---

## 5. Hierarquia Visual por Modo de Tema

```text
Modo Claro:
  Canvas (fundo #F4F6FA) ──> Cartão Branco (#FFFFFF + sombra difusa) ──> Badge Tonal (#EEF2FA) / Herói Gradiente

Modo Escuro:
  Canvas (#0F141E) ──> Cartão Grafite Elevado (#182030 + bordaSutil #2B364B) ──> Herói Gradiente Escuro

Modo Alto Contraste:
  Canvas (#000000) ──> Cartão (#0A0A0A + Border.all(cores.borda, 2px) sem sombra) ──> Herói Sólido >= 7:1
```

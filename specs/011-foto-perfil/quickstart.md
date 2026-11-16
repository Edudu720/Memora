# Quickstart & Validation Guide: Foto de Perfil (`011-foto-perfil`)

**Date**: 2026-11-16 | **Branch**: `feature/011-foto-perfil` | **Spec**: [spec.md](file:///c:/Users/Eduardo/Memora/specs/011-foto-perfil/spec.md)

## Pré-requisitos

- Flutter SDK `3.47+` (observado no workspace: `Flutter 3.47.7` / `Dart 3.13.5`)
- Dependências do app atualizadas após Fase de Implementação (`cd app && flutter pub get`)
- Nenhum backend rodando é necessário para validar a feature (`Q1: A` — armazenamento 100% local no aparelho; funciona offline).

## Comandos de Verificação Automatizada

```powershell
# Na pasta app/
flutter analyze
flutter test test/features/perfil/
flutter test test/features/autenticacao/saida_limpa_armazenamento_test.dart
flutter test
```

## Cenários de Validação Ponta a Ponta (Mapeamento SC-001 a SC-006)

### V1 — Colocar foto da galeria ou câmera com enquadramento `1:1` e pré-visualização (`US1`, `FR-001`–`FR-005`, `SC-001`, `SC-002`)
1. Abrir **Meu perfil** em uma conta sem retrato salvo → verificar o **Retrato Padrão** neutro (sem o robô da Memora no lugar do usuário) e o botão explícito **"Colocar foto de perfil"**.
2. Tocar em **"Colocar foto de perfil"** → confirmar a exibição da folha com a explicação de privacidade integrada no topo (`FR-004`) e as três opções rotuladas com ícone + texto (**Galeria**, **Câmera**, **Avatares da Memora**).
3. Selecionar imagem retangular válida (JPEG/PNG/WebP `<= 15 MB`) → confirmar abertura da tela de pré-visualização com recorte quadrado centralizado e dois botões (**"Usar esta foto"** e **"Escolher outra"**).
4. Confirmar **"Usar esta foto"** → verificar atualização imediata do retrato em **Meu perfil**, persistência ao trocar de aba e após recarregar com `idDaConta`.
5. Verificar que a saudação da tela **Início** permanece inalterada (`FR-010`).

### V2 — Escolher Avatar ilustrado da Memora sem permissões (`US1`, `FR-003`, `FR-004`)
1. Tocar para colocar/trocar foto → selecionar **"Escolher avatar da Memora"**.
2. Confirmar que o seletor de câmera/galeria nativa **não** é acionado e nenhuma permissão é solicitada.
3. Escolher um avatar da lista e confirmar exibição imediata e persistência no Perfil.

### V3 — Sanitização de EXIF/GPS e limites de segurança (`FR-005`, `SC-003`)
1. Enviar ao processador uma imagem JPEG contendo blocos EXIF sintéticos (coordenadas GPS + modelo do dispositivo + tag de orientação rotacionada).
2. Verificar que a saída gravada é um JPEG quadrado com largura e altura `<= 512 px`, orientação aplicada corretamente e **zero bytes/segmentos de metadados EXIF/GPS**.
3. Enviar arquivo `> 15 MB`, arquivo texto/PDF renomeado para `.jpg` e arquivo corrompido → verificar rejeição limpa, estado anterior preservado e mensagem compreensível em português (`SC-004`).

### V4 — Troca, remoção com confirmação e concorrência (`US2`, `FR-008`, `FR-012`)
1. Com foto/avatar salvo, tocar em **"Trocar foto"** e escolher outro item → comprovar substituição limpa (arquivo antigo removido do diretório privado).
2. Tocar em **"Remover foto"** → cancelar na confirmação (nada muda); repetir e confirmar → arquivo/registro apagado definitivamente e retorno ao Retrato Padrão.
3. Disparar toques repetidos enquanto seleção/remoção está em andamento → garantir que apenas uma operação executa por vez.

### V5 — Isolamento entre contas e limpeza de sessão (`FR-007`, `FR-009`, `SC-006`)
1. Salvar foto na `conta-A`, sair da sessão comum (`esquecerTudo: false`) e entrar na `conta-B` → `conta-B` vê apenas o seu próprio Retrato Padrão (jamais a foto da `conta-A`).
2. Voltar à `conta-A` no mesmo aparelho → a foto da `conta-A` continua preservada.
3. Executar **"Sair e esquecer este aparelho"** (`esquecerTudo: true`) → verificar que todas as chaves `memora.foto_perfil.v1.*` e todo o conteúdo de `<appSupportDir>/fotos_perfil/` foram removidos.

### V6 — Permissões negadas e acessibilidade (`US3`, `FR-002`, `FR-011`, `SC-005`)
1. Simular negação de permissão de câmera/galeria → comprovar aviso empático em português oferecendo botão para abrir configurações do aparelho e atalho para escolher avatar da Memora.
2. Renderizar todos os estados da tela de Perfil, folha de escolha, grade de avatares e pré-visualização nos 3 temas (**claro**, **escuro** e **alto contraste**) e `textScaler` `2.0` (`200%`), validando área de toque `>= 48×48 dp`, contraste WCAG 2.2 AA, semântica para leitores de tela e ausência de erro de `RenderFlex overflow`.

### Validação Manual no Aparelho Android *(antes do merge final)*
- Instalar APK de depuração em dispositivo Android: testar escolha real pela Galeria (Android Photo Picker), captura pela Câmera, recusa seguida de abertura de Configurações do app e verificação de funcionamento em modo avião.

# Reproducao de MP3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Permitir tocar, pausar/continuar e parar MP3s baixados dentro do Tube2MP3.

**Architecture:** O `TMainForm` mantera o caminho do arquivo selecionado e controlara um `TMediaPlayer` VCL. A selecao do historico e o fim de um download chamarao um metodo unico para trocar o arquivo atual, parar qualquer reproducao anterior e atualizar a interface.

**Tech Stack:** Delphi 10.4, VCL, `Vcl.MPlayer`, Win32.

## Global Constraints

- Usar apenas o mecanismo multimedia nativo do Windows, sem DLLs, executaveis ou bibliotecas externas.
- Tocar o ultimo arquivo concluido e os arquivos existentes selecionados no historico.
- Desabilitar os controles sem um MP3 existente e liberar o player no fechamento do formulario.

---

### Task 1: Adicionar player e controles no formulario

**Files:**
- Modify: `src/Presentation/Tube2MP3.Presentation.Main.pas`
- Modify: `src/Presentation/Tube2MP3.Presentation.Main.dfm`
- Test: `tests/ValidateProject.ps1`

**Interfaces:**
- Produces: `SetPlaybackFile(const AFilePath: string)`, `UpdatePlaybackControls`, `StopPlayback` e os eventos `btnPlayClick`, `btnPauseClick`, `btnStopClick`, `lvHistorySelectItem`.

- [ ] **Step 1: Write the failing test**

Adicionar ao `tests/ValidateProject.ps1` verificacoes para `Vcl.MPlayer`, `mediaPlayer: TMediaPlayer`, `btnPlay`, `btnPause`, `btnStop` e os tres manipuladores de clique.

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File tests\ValidateProject.ps1`
Expected: falha informando que as declaracoes do player ainda nao existem.

- [ ] **Step 3: Write minimal implementation**

Declarar `mediaPlayer: TMediaPlayer`, `FPlaybackFile: string` e os metodos privados no formulario. Inserir a area "Reproducao" entre status e historico, mover o historico para baixo e associar os botoes aos eventos. `btnPlayClick` abre o MP3 atual e chama `mediaPlayer.Play`; `btnPauseClick` alterna `Pause` e `Play`; `btnStopClick` chama `StopPlayback`. `SetPlaybackFile` para a musica atual, recebe um caminho existente e atualiza o rotulo e botoes. `FormDestroy` chama `StopPlayback`.

- [ ] **Step 4: Run test to verify it passes**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File tests\ValidateProject.ps1`
Expected: `PROJECT VALIDATION PASSED`.

- [ ] **Step 5: Commit**

Run: `git add src/Presentation/Tube2MP3.Presentation.Main.pas src/Presentation/Tube2MP3.Presentation.Main.dfm tests/ValidateProject.ps1`

Run: `git commit -m "Add MP3 playback controls"`

### Task 2: Conectar download e historico ao player

**Files:**
- Modify: `src/Presentation/Tube2MP3.Presentation.Main.pas`
- Test: `tests/ValidateProject.ps1`

**Interfaces:**
- Consumes: `SetPlaybackFile(const AFilePath: string)` e `lvHistorySelectItem` da Task 1.
- Produces: ultimo download e item selecionado preparados para reproducao.

- [ ] **Step 1: Write the failing test**

Adicionar verificacoes para `SetPlaybackFile(FilePath)` no bloco de conclusao do download e `SetPlaybackFile(Path)` no evento de selecao do historico.

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File tests\ValidateProject.ps1`
Expected: falha indicando que um dos fluxos ainda nao seleciona o arquivo do player.

- [ ] **Step 3: Write minimal implementation**

Depois de registrar e listar o download concluido, chamar `SetPlaybackFile(FilePath)`. No evento `lvHistorySelectItem`, ler `Item.SubItems[3]`; quando houver selecao, chamar `SetPlaybackFile(Path)`. Manter o duplo clique atual para revelar o arquivo no Explorer.

- [ ] **Step 4: Run test to verify it passes**

Run: `.\build.bat`
Expected: `PROJECT VALIDATION PASSED`, `ALL TESTS PASSED` e `Build e testes concluidos.`

- [ ] **Step 5: Commit**

Run: `git add src/Presentation/Tube2MP3.Presentation.Main.pas tests/ValidateProject.ps1`

Run: `git commit -m "Connect downloaded files to MP3 player"`

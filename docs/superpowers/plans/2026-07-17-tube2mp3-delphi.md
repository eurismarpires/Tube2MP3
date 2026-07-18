# Tube2MP3 Delphi MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar um MVP VCL compilável que analisa e baixa áudio com yt-dlp/FFmpeg e mantém histórico local.

**Architecture:** Formulário VCL fino sobre serviços focados. Processos externos usam pipes e Job Object; dados locais usam FireDAC SQLite, JSON e arquivo de log.

**Tech Stack:** Delphi 10.4 Sydney, VCL, Win32, FireDAC SQLite, System.JSON, WinAPI, yt-dlp e FFmpeg.

## Global Constraints

- Windows 10/11 e Delphi 10.4 Sydney.
- Dependências externas em `bin/yt-dlp.exe` e `bin/ffmpeg.exe`.
- Operações longas fora da thread da interface.
- Nenhum download automático de executáveis de terceiros.

---

### Task 1: Regras puras e testes

**Files:**
- Create: `tests/Tube2MP3Tests.dpr`
- Create: `src/Domain/Tube2MP3.Domain.Models.pas`
- Create: `src/Application/Tube2MP3.Application.Helpers.pas`

**Interfaces:**
- Produces: `IsSupportedYouTubeUrl`, `FormatDuration`, `TryParseProgress`.

- [ ] Criar testes para URLs válidas/inválidas, duração e progresso.
- [ ] Compilar e confirmar falha pela ausência das unidades.
- [ ] Implementar as funções mínimas.
- [ ] Compilar e executar os testes, esperando exit code 0.

### Task 2: Infraestrutura local

**Files:**
- Create: `src/Infrastructure/Tube2MP3.Infrastructure.Logger.pas`
- Create: `src/Infrastructure/Tube2MP3.Infrastructure.Settings.pas`
- Create: `src/Infrastructure/Tube2MP3.Infrastructure.History.pas`

**Interfaces:**
- Produces: `TFileLogger`, `TAppSettings`, `THistoryRepository`.

- [ ] Implementar log thread-safe.
- [ ] Implementar leitura e gravação JSON com valores padrão.
- [ ] Implementar schema SQLite e consultas de histórico.

### Task 3: Integração yt-dlp

**Files:**
- Create: `src/Infrastructure/Tube2MP3.Infrastructure.ProcessRunner.pas`
- Create: `src/Infrastructure/Tube2MP3.Infrastructure.YtDlp.pas`

**Interfaces:**
- Produces: `TProcessRunner.Execute`, `TProcessRunner.Cancel`, `TYtDlpService.GetVideoInfo`, `TYtDlpService.DownloadAudio`.

- [ ] Executar processo com stdout/stderr em pipe e Job Object.
- [ ] Interpretar JSON de metadados.
- [ ] Montar download MP3 e emitir progresso por callback.

### Task 4: Interface VCL e projeto

**Files:**
- Create: `Tube2MP3.dpr`
- Create: `Tube2MP3.dproj`
- Create: `src/Presentation/Tube2MP3.Presentation.Main.pas`
- Create: `src/Presentation/Tube2MP3.Presentation.Main.dfm`

**Interfaces:**
- Consumes: todos os serviços anteriores.

- [ ] Criar interface, estados e eventos.
- [ ] Executar análise/download em threads.
- [ ] Carregar histórico e thumbnail.
- [ ] Salvar pasta e bitrate escolhidos.

### Task 5: Documentação, build e pacote

**Files:**
- Create: `README.md`
- Create: `bin/README.txt`
- Create: `build.bat`

- [ ] Compilar testes.
- [ ] Compilar Win32 Debug e Release via MSBuild.
- [ ] Corrigir todos os erros de compilação.
- [ ] Criar ZIP contendo projeto, fontes, testes e documentação.

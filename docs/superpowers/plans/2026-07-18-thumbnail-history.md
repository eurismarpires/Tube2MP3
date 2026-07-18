# Thumbnails do Historico Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Armazenar thumbnails localmente e exibi-las ao selecionar itens novos ou antigos do historico.

**Architecture:** `THistoryItem` recebera `ThumbnailPath`, e `THistoryRepository` migrara bancos existentes para persistir esse campo. O formulario salvara thumbnails durante o download e buscara, em segundo plano, a thumbnail de itens antigos que ainda nao possuam arquivo local.

**Tech Stack:** Delphi 10.4, VCL, FireDAC SQLite, `THTTPClient`.

## Global Constraints

- Salvar imagens em `data\thumbnails`, nunca como BLOBs no SQLite.
- Preservar as alteracoes locais existentes em `src\Presentation\Tube2MP3.Presentation.Main.dfm`.
- Falhas de imagem ou rede nao podem impedir a reproducao do MP3.

---

### Task 1: Persistir o caminho da thumbnail

**Files:**
- Modify: `src/Domain/Tube2MP3.Domain.Models.pas`
- Modify: `src/Infrastructure/Tube2MP3.Infrastructure.History.pas`
- Modify: `tests/Tube2MP3Tests.dpr`

**Interfaces:**
- Produces: `THistoryItem.ThumbnailPath` e `THistoryRepository.UpdateThumbnailPath(AId: Integer; const APath: string)`.

- [ ] **Step 1: Write the failing test**

Criar um banco temporario, inserir um `THistoryItem` com `ThumbnailPath`, ler o item e confirmar o valor. Atualizar o caminho e confirmar o novo valor.

- [ ] **Step 2: Run test to verify it fails**

Run: `.\build.bat`
Expected: erro de compilacao para `ThumbnailPath` ou `UpdateThumbnailPath` inexistentes.

- [ ] **Step 3: Write minimal implementation**

Adicionar `ThumbnailPath` ao record. Criar ou migrar a coluna `thumbnail_path`, incluir o campo no insert e select, e implementar o update por `id`.

- [ ] **Step 4: Run test to verify it passes**

Run: `.\build.bat`
Expected: `ALL TESTS PASSED`.

### Task 2: Cache e carregamento no formulario

**Files:**
- Modify: `src/Presentation/Tube2MP3.Presentation.Main.pas`
- Modify: `tests/ValidateProject.ps1`

**Interfaces:**
- Consumes: `THistoryItem.ThumbnailPath` e `THistoryRepository.UpdateThumbnailPath`.
- Produces: `SaveThumbnail`, `LoadThumbnailFromFile` e `LoadHistoryThumbnail`.

- [ ] **Step 1: Write the failing validation**

Exigir os metodos de cache e a chamada de `LoadHistoryThumbnail` no evento de selecao do historico.

- [ ] **Step 2: Run validation to verify it fails**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File tests\ValidateProject.ps1`
Expected: falha por declaracoes ausentes.

- [ ] **Step 3: Write minimal implementation**

Salvar a imagem analisada em `data\thumbnails` apos o novo item ser criado. Ao selecionar um historico, carregar o arquivo existente; sem cache, buscar metadados pela URL em thread, salvar a imagem e atualizar o banco. So atualizar a interface se o item continuar selecionado.

- [ ] **Step 4: Run full verification**

Run: `.\build.bat`
Expected: `PROJECT VALIDATION PASSED`, `ALL TESTS PASSED` e `Build e testes concluidos.`

- [ ] **Step 5: Commit**

Run: `git add src/Domain/Tube2MP3.Domain.Models.pas src/Infrastructure/Tube2MP3.Infrastructure.History.pas src/Presentation/Tube2MP3.Presentation.Main.pas tests/Tube2MP3Tests.dpr tests/ValidateProject.ps1 docs/superpowers/plans/2026-07-18-thumbnail-history.md`

Run: `git commit -m "Cache history thumbnails"`

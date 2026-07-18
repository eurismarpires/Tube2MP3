# Tube2MP3 — MVP Delphi/VCL

Aplicativo desktop para Windows que analisa um vídeo do YouTube e extrai o áudio em MP3. O projeto usa Delphi 10.4 Sydney, VCL, yt-dlp, FFmpeg e SQLite/FireDAC.

## Recursos do MVP

- validação de URLs do YouTube;
- metadados via `yt-dlp --dump-single-json --no-playlist`;
- título, canal, duração e thumbnail quando o formato da imagem for reconhecido pela VCL;
- bitrates de 64, 128, 192, 256 e 320 kbps;
- progresso, velocidade e tempo restante em tempo real;
- cancelamento do processo e de seus subprocessos;
- seleção e abertura da pasta de destino;
- histórico SQLite com FireDAC;
- configurações em JSON e logs em arquivo;
- interface responsiva durante análise, download e conversão.

## Dependências

1. Baixe uma versão atual do `yt-dlp.exe` no projeto oficial.
2. Baixe uma distribuição do FFmpeg para Windows.
3. Coloque os arquivos exatamente assim:

```text
bin\yt-dlp.exe
bin\ffmpeg.exe
```

O SQLite é vinculado estaticamente por `FireDAC.Phys.SQLiteWrapper.Stat`; não é necessário distribuir `sqlite3.dll`.

O aplicativo não baixa nem atualiza executáveis de terceiros automaticamente. O YouTube muda com frequência, portanto mantenha o `yt-dlp.exe` atualizado.

## Compilação

Carregue o ambiente em um Prompt de Comando:

```bat
call "C:\Program Files (x86)\Embarcadero\Studio\21.0\bin\rsvars.bat"
```

Debug Win32:

```bat
msbuild Tube2MP3.dproj /t:Build /p:Config=Debug /p:Platform=Win32
```

Release Win32:

```bat
msbuild Tube2MP3.dproj /t:Build /p:Config=Release /p:Platform=Win32
```

Ou execute `build.bat`. O executável do aplicativo é gerado na raiz do projeto para funcionar diretamente pelo Delphi:

```text
Tube2MP3.exe
```

Ao executar pela raiz, o programa localiza a pasta `bin` do projeto. Para distribuir somente o executável, coloque uma pasta `bin` ao lado dele com `yt-dlp.exe` e `ffmpeg.exe`.

## Testes

Os testes não acessam a rede:

```bat
dcc32 -B -Ework\tests tests\Tube2MP3Tests.dpr
work\tests\Tube2MP3Tests.exe
```

## Dados locais

- banco: `data\tube2mp3.db`;
- configurações: `settings.json`;
- logs: `logs\application.log`.

Esses arquivos e pastas são criados automaticamente.

## Uso

1. Cole uma URL do YouTube e clique em **Analisar**.
2. Confira os metadados.
3. Escolha a pasta e a qualidade.
4. Clique em **Baixar MP3**.
5. Dê duplo clique em um item do histórico para localizar o arquivo no Explorer.

Converter para 320 kbps não melhora uma fonte de qualidade inferior. O yt-dlp baixa o melhor fluxo de áudio disponível e o FFmpeg gera o bitrate selecionado.

## Observação legal

Use o aplicativo somente para conteúdo cujo download seja permitido, conteúdo próprio ou conteúdo para o qual você possua autorização. Respeite direitos autorais, licenças aplicáveis e os Termos de Serviço do YouTube. O projeto não contorna DRM e não concede direitos sobre conteúdo de terceiros.

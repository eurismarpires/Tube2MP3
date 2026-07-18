# Tube2MP3 Delphi MVP — Design

## Objetivo

Aplicativo desktop Windows em Delphi 10.4 Sydney/VCL para analisar uma URL de vídeo do YouTube, exibir metadados, baixar o melhor áudio disponível, convertê-lo para MP3 e registrar o resultado localmente.

## Arquitetura

- `Presentation`: formulário VCL e atualização da interface.
- `Domain`: modelos de vídeo, progresso e histórico.
- `Application`: validação de URL e orquestração dos casos de uso.
- `Infrastructure`: execução de processos, integração com yt-dlp/FFmpeg, SQLite, settings JSON e logs.

O processo externo é executado em thread de trabalho com pipes para capturar cada linha de saída. O cancelamento encerra a árvore de processo por meio de um Job Object do Windows. Atualizações visuais são enviadas à thread principal com `TThread.Queue`.

## Fluxos

1. Analisar: validar URL, executar `yt-dlp --dump-single-json --no-playlist`, converter o JSON para `TVideoInfo` e tentar carregar a thumbnail.
2. Baixar: selecionar pasta e bitrate, executar yt-dlp com extração de áudio e FFmpeg, interpretar linhas de progresso e registrar conclusão no SQLite.
3. Cancelar: sinalizar cancelamento e encerrar o Job Object associado ao processo.
4. Inicialização: criar pastas, carregar `settings.json`, inicializar banco e listar histórico.

## Persistência

O SQLite fica em `data/tube2mp3.db`. A tabela `downloads` contém título, URL, canal, duração, qualidade, tamanho, caminho, status e data. As configurações ficam em `settings.json`. Logs ficam em `logs/application.log`.

## Erros e segurança

URLs fora de `youtube.com`, `www.youtube.com`, `m.youtube.com` e `youtu.be` são recusadas. Argumentos de processo são corretamente delimitados. Mensagens técnicas completas vão para o log e mensagens curtas são apresentadas ao usuário. O README informa que o usuário deve respeitar direitos autorais e os Termos de Serviço.

## Testes e verificação

Um executável de testes valida URL, duração e parser de progresso sem rede. A verificação final compila testes e aplicativo em Win32 Debug e Release usando o ambiente do Delphi 10.4.

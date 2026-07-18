# Thumbnails do Historico - Design

## Objetivo

Exibir a thumbnail correspondente ao item selecionado no historico, inclusive apos reiniciar o aplicativo e sem depender de conexao depois que a imagem tiver sido armazenada localmente.

## Armazenamento

Cada thumbnail sera salva em `data\thumbnails` com um nome baseado no identificador do registro do historico. A tabela `downloads` recebera a coluna opcional `thumbnail_path`; bancos existentes serao atualizados com `ALTER TABLE` apenas quando a coluna ainda nao existir.

## Fluxos

1. Ao baixar um novo MP3, a thumbnail ja analisada sera baixada em segundo plano, salva localmente e associada ao registro criado no historico.
2. Ao selecionar um item que ja possui `thumbnail_path`, o aplicativo carregara o arquivo local imediatamente.
3. Ao selecionar um item antigo sem thumbnail local, o aplicativo usara sua URL do YouTube para buscar os metadados, baixar a thumbnail em segundo plano e gravar o caminho no banco.
4. Enquanto nao houver imagem local, a area de thumbnail ficara vazia. Erros de rede ou de imagem nao impedem a reproducao do MP3.

## Limites

O cache atende novos downloads e itens antigos somente quando forem selecionados. Imagens sao arquivos no disco, nao BLOBs no SQLite. Nenhuma dependencia externa alem das que o projeto ja usa sera adicionada.

## Verificacao

Testes cobrem o modelo com `ThumbnailPath` e a persistencia do campo no repositorio. A verificacao final compila testes e aplicativo Win32.

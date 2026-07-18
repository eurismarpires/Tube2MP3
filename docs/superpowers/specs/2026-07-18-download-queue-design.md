# Fila de Downloads - Design

## Objetivo

Permitir adicionar varios videos para download e processa-los automaticamente, um por vez, na ordem em que foram inseridos.

## Estado da fila

Cada item mantem URL, titulo, canal, duracao, bitrate, pasta de destino e status. Os status sao `Pendente`, `Baixando`, `Concluido`, `Falhou` e `Cancelado`.

## Interface

Uma grade "Fila de downloads" exibira titulo, qualidade e status. O video analisado entra na fila pelo comando de download. Acoes adicionais removem o item pendente selecionado ou limpam todos os itens pendentes.

## Processamento

Somente um item usa yt-dlp por vez. Quando um item termina, falha ou e cancelado, o proximo item pendente inicia automaticamente. Cancelar interrompe apenas o item em execucao; os demais permanecem na fila.

## Limites

A fila existe somente enquanto o aplicativo estiver aberto. O historico continua sendo salvo apenas para downloads concluidos.

## Verificacao

Testes cobrem a selecao do proximo item pendente e os estados da fila. O aplicativo deve compilar em Win32.

# Reproducao de MP3 - Design

## Objetivo

Permitir que o usuario toque, pause/continue e pare os MP3s baixados sem sair do Tube2MP3.

## Abordagem

O formulario principal usara `TMediaPlayer` da VCL, apoiado pelo mecanismo multimedia nativo do Windows. Esta abordagem nao adiciona DLLs, executaveis ou bibliotecas externas ao projeto.

## Interface

Uma area "Reproducao" ficara entre o status do download e o historico. Ela exibira o nome do arquivo selecionado e os botoes `Tocar`, `Pausar` e `Parar`.

Os botoes permanecem desabilitados enquanto nao houver um arquivo MP3 existente selecionado. Durante a reproducao, `Pausar` alterna entre pausar e continuar.

## Fluxo

1. Ao concluir um download, seu caminho se torna o arquivo atual do player.
2. Ao selecionar uma linha do historico, o caminho registrado naquela linha se torna o arquivo atual, desde que o arquivo ainda exista.
3. Tocar abre o arquivo atual e inicia a reproducao.
4. Pausar interrompe temporariamente a reproducao; um novo clique continua do mesmo ponto.
5. Parar encerra a reproducao e retorna o player ao inicio.
6. Ao fechar o aplicativo ou trocar de arquivo, a reproducao atual e parada e o arquivo e fechado.

## Tratamento de erros

Se o arquivo nao existir, o aplicativo informara o usuario e mantera os controles desabilitados. Falhas do mecanismo nativo serao registradas em `logs/application.log` e mostradas em uma mensagem curta.

## Verificacao

O projeto deve continuar compilando em Win32. A verificacao estrutural confirmara a declaracao do `TMediaPlayer`, os controles da interface e os manipuladores dos tres botoes.

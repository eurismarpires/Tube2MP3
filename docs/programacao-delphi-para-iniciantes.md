# Programacao Delphi Para Iniciantes

Este guia explica a programacao do projeto Tube2MP3 para quem esta comecando em Delphi. A ideia nao e ensinar toda a linguagem de uma vez, mas mostrar como um aplicativo real em Delphi/VCL e organizado, como as partes conversam entre si e onde olhar quando quiser alterar alguma funcionalidade.

## 1. O Que E Delphi

Delphi e uma linguagem e ambiente de desenvolvimento para criar aplicativos Windows, APIs, servicos e outros tipos de software. A linguagem usada pelo Delphi e baseada em Object Pascal.

No Tube2MP3, o Delphi esta sendo usado para criar um aplicativo desktop Windows com VCL. VCL significa Visual Component Library. Ela fornece formularios, botoes, caixas de texto, listas, imagens, dialogs e outros componentes visuais.

Quando voce abre o projeto no Delphi, o arquivo principal e:

```text
Tube2MP3.dproj
```

Esse arquivo guarda configuracoes do projeto, como plataforma Win32, modo Debug/Release, arquivos compilados e units usadas.

## 2. Arquivos Principais Do Projeto

O projeto tem esta estrutura principal:

```text
Tube2MP3.dpr
Tube2MP3.dproj
src\
  Application\
  Domain\
  Infrastructure\
  Presentation\
tests\
bin\
docs\
```

Cada pasta tem uma responsabilidade:

`Presentation`: tela do aplicativo, botoes, eventos e interacao com o usuario.

`Application`: funcoes auxiliares e regras simples usadas pela aplicacao.

`Domain`: modelos de dados, como informacoes do video e item do historico.

`Infrastructure`: acesso a arquivos, banco SQLite, logs, processos externos, yt-dlp e ffmpeg.

`tests`: testes automatizados simples para validar partes importantes.

`bin`: executaveis externos necessarios em tempo de execucao, como `yt-dlp.exe` e `ffmpeg.exe`.

## 3. O Arquivo .dpr

O arquivo [Tube2MP3.dpr](../Tube2MP3.dpr) e o ponto de entrada do programa. Ele e parecido com o `main` de outras linguagens.

Trecho simplificado:

```pascal
program Tube2MP3;

uses
  Vcl.Forms,
  FireDAC.VCLUI.Wait,
  Tube2MP3.Presentation.Main in 'src\Presentation\Tube2MP3.Presentation.Main.pas' {MainForm};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Tube2MP3';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
```

O que acontece aqui:

`Application.Initialize`: prepara a aplicacao VCL.

`Application.CreateForm`: cria o formulario principal.

`Application.Run`: inicia o loop da interface grafica. A partir daqui, o programa fica esperando eventos, como clique de botao, digitacao e fechamento da janela.

A unit `FireDAC.VCLUI.Wait` registra componentes internos do FireDAC para aplicativos VCL. Sem ela, o projeto pode abrir erros de "Object factory missing".

## 4. Units Em Delphi

Em Delphi, cada arquivo `.pas` normalmente declara uma `unit`.

Exemplo:

```pascal
unit Tube2MP3.Application.Helpers;

interface

function FormatDuration(ASeconds: Integer): string;

implementation

function FormatDuration(ASeconds: Integer): string;
begin
  Result := '...';
end;

end.
```

A `interface` mostra o que outras units podem usar.

A `implementation` contem o codigo interno.

O `uses` importa outras units. Ele e parecido com `import`, `include` ou `using` em outras linguagens.

## 5. Formularios E Eventos

A tela principal esta em:

```text
src\Presentation\Tube2MP3.Presentation.Main.pas
src\Presentation\Tube2MP3.Presentation.Main.dfm
```

O `.pas` contem o codigo.

O `.dfm` contem a definicao visual da tela: botoes, labels, edit boxes, list view, tamanhos, posicoes e eventos ligados aos componentes.

A classe principal e:

```pascal
TMainForm = class(TForm)
```

Ela herda de `TForm`, que e a classe base de uma janela VCL.

Quando o usuario clica em **Analisar**, o Delphi chama:

```pascal
procedure TMainForm.btnAnalyzeClick(Sender: TObject);
```

Quando clica em **Baixar MP3**, chama:

```pascal
procedure TMainForm.btnDownloadClick(Sender: TObject);
```

Esse e o padrao mais comum em VCL: componentes visuais disparam eventos, e voce escreve procedures para responder a esses eventos.

## 6. Classes, Objetos E Construtores

O projeto usa classes para organizar responsabilidades.

Exemplo:

```pascal
TYtDlpService = class
private
  FYtDlpPath: string;
  FFmpegPath: string;
public
  constructor Create(const AYtDlpPath, AFFmpegPath: string; ALogger: TFileLogger);
  function GetVideoInfo(const AUrl: string): TVideoInfo;
end;
```

Uma classe pode ter campos, metodos e construtores.

`private`: so a propria classe acessa.

`public`: outras partes do programa podem acessar.

`constructor Create`: metodo usado para criar e inicializar o objeto.

No formulario principal, o servico e criado assim:

```pascal
FYtDlp := TYtDlpService.Create(
  TPath.Combine(FBasePath, 'bin\yt-dlp.exe'),
  TPath.Combine(FBasePath, 'bin\ffmpeg.exe'),
  FLogger
);
```

Isso significa: "crie um servico que sabe onde estao o yt-dlp, o ffmpeg e o logger".

## 7. Records: Dados Simples

O arquivo [Tube2MP3.Domain.Models.pas](../src/Domain/Tube2MP3.Domain.Models.pas) define os modelos principais.

Exemplo:

```pascal
TVideoInfo = record
  Title: string;
  Channel: string;
  Duration: Integer;
  ThumbnailUrl: string;
end;
```

`record` e uma estrutura de dados simples. Ele agrupa valores relacionados.

No projeto existem records para:

`TVideoInfo`: dados do video analisado.

`TDownloadProgress`: progresso do download.

`THistoryItem`: item salvo no historico.

## 8. Fluxo Do Botao Analisar

Quando o usuario clica em **Analisar**, o metodo `btnAnalyzeClick` faz este fluxo:

1. Le a URL digitada.
2. Valida se parece uma URL do YouTube.
3. Limpa dados antigos da tela.
4. Marca a interface como ocupada.
5. Cria uma thread para nao travar a janela.
6. Chama `FYtDlp.GetVideoInfo(Url)`.
7. Atualiza titulo, canal, duracao e thumbnail.

O ponto importante e que a analise roda em uma thread separada:

```pascal
FWorker := TThread.CreateAnonymousThread(
  procedure
  begin
    Info := FYtDlp.GetVideoInfo(Url);
  end);
```

Isso evita congelar a interface enquanto o `yt-dlp.exe` consulta o YouTube.

## 9. Threads E Interface Grafica

Em aplicativos VCL, voce nao deve atualizar componentes visuais diretamente de uma thread secundaria.

Por isso o projeto usa:

```pascal
TThread.Queue(nil,
  procedure
  begin
    lblTitle.Caption := Info.Title;
  end);
```

`TThread.Queue` agenda o codigo para rodar na thread principal da interface.

Regra pratica:

Codigo pesado pode rodar em thread secundaria.

Alteracao de tela deve voltar para a thread principal.

## 10. yt-dlp E ffmpeg

O projeto nao baixa videos sozinho. Ele chama dois programas externos:

```text
bin\yt-dlp.exe
bin\ffmpeg.exe
```

`yt-dlp.exe`: analisa e baixa audio/video do YouTube.

`ffmpeg.exe`: converte o audio para MP3.

O servico responsavel por isso esta em:

```text
src\Infrastructure\Tube2MP3.Infrastructure.YtDlp.pas
```

Para analisar um video, ele executa:

```text
yt-dlp.exe --dump-single-json --no-playlist --no-warnings URL
```

Esse comando retorna JSON com titulo, canal, duracao e outros metadados.

Para baixar MP3, ele executa o `yt-dlp` com parametros de extracao de audio e aponta onde esta o `ffmpeg`.

## 11. Executando Processos Externos

A unit:

```text
src\Infrastructure\Tube2MP3.Infrastructure.ProcessRunner.pas
```

tem a classe `TProcessRunner`.

Ela usa APIs do Windows, como `CreateProcess`, para executar programas externos escondidos, capturar a saida de texto e permitir cancelamento.

Isso e mais avancado, mas a ideia principal e:

1. Monta a linha de comando.
2. Abre o processo.
3. Le a saida do processo.
4. Envia cada linha para um callback.
5. Retorna o codigo de saida.

No download, cada linha de progresso do `yt-dlp` passa por:

```pascal
TryParseProgress(ALine, P)
```

Se a linha tiver percentual, velocidade e ETA, a tela e atualizada.

## 12. Funcoes Auxiliares

A unit [Tube2MP3.Application.Helpers.pas](../src/Application/Tube2MP3.Application.Helpers.pas) contem funcoes pequenas e reutilizaveis.

Exemplos:

`IsSupportedYouTubeUrl`: verifica se a URL e do YouTube.

`FormatDuration`: transforma segundos em texto, como `05:36`.

`TryParseProgress`: interpreta linhas de progresso do `yt-dlp`.

`QuoteArg`: coloca aspas em argumentos de linha de comando.

Esse tipo de unit ajuda a deixar a tela principal menor e mais facil de entender.

## 13. Historico Com SQLite E FireDAC

O historico e salvo em SQLite:

```text
data\tube2mp3.db
```

A unit responsavel e:

```text
src\Infrastructure\Tube2MP3.Infrastructure.History.pas
```

Ela usa FireDAC, que e a biblioteca de acesso a banco de dados do Delphi.

Ao iniciar, o projeto cria a tabela se ela ainda nao existir:

```sql
CREATE TABLE IF NOT EXISTS downloads (...)
```

Para gravar um item, usa parametros:

```pascal
Q.ParamByName('title').AsString := AItem.Title;
Q.ParamByName('url').AsString := AItem.Url;
Q.ExecSQL;
```

Parametros sao importantes porque evitam problemas com aspas no texto e ajudam a prevenir SQL injection.

Para ler o historico, o projeto executa:

```sql
SELECT * FROM downloads ORDER BY id DESC LIMIT 200
```

Depois monta os itens no `TListView`.

## 14. Configuracoes Em JSON

As configuracoes ficam em:

```text
settings.json
```

A unit responsavel e:

```text
src\Infrastructure\Tube2MP3.Infrastructure.Settings.pas
```

Ela salva coisas como:

`DownloadFolder`: pasta de destino.

`Bitrate`: qualidade escolhida.

Ao fechar o aplicativo, o projeto salva as configuracoes atuais.

Ao abrir, carrega o arquivo de configuracao.

## 15. Logs

Os logs ficam em:

```text
logs\application.log
```

A classe responsavel e:

```text
TFileLogger
```

Ela grava mensagens com data, hora e nivel:

```text
2026-07-18 02:40:22.034 [INFO] Iniciando download...
```

Logs ajudam muito quando o usuario diz "deu erro", porque mostram o que aconteceu antes do problema.

## 16. Tratamento De Erros

Delphi usa `try/except` para tratar erros.

Exemplo:

```pascal
try
  Info := FYtDlp.GetVideoInfo(Url);
except
  on E: Exception do
  begin
    ErrorText := E.Message;
  end;
end;
```

Quando algo da errado, o projeto:

1. Captura a exception.
2. Grava no log.
3. Mostra uma mensagem para o usuario.
4. Libera a interface para tentar novamente.

Tambem existe `try/finally`, usado para garantir liberacao de memoria:

```pascal
Q := TFDQuery.Create(nil);
try
  Q.Open;
finally
  Q.Free;
end;
```

Mesmo se der erro, o `finally` executa.

## 17. Memoria E Free

Em Delphi classico, muitos objetos precisam ser liberados manualmente com `Free`.

Exemplo:

```pascal
FRunner := TProcessRunner.Create;
...
FRunner.Free;
```

O padrao comum e:

```pascal
Objeto := TAlgumaClasse.Create;
try
  // usa o objeto
finally
  Objeto.Free;
end;
```

Isso evita vazamento de memoria.

## 18. Testes

Os testes ficam em:

```text
tests\Tube2MP3Tests.dpr
```

Eles validam funcoes importantes sem acessar a internet.

Exemplo:

```pascal
Check(FormatDuration(65) = '01:05', 'minute duration');
```

O projeto tambem tem:

```text
tests\ValidateProject.ps1
```

Esse script verifica regras estruturais, como:

1. O `.dproj` referencia o `.dpr` corretamente.
2. Arquivos Delphi estao com BOM UTF-8.
3. FireDAC esta com units obrigatorias registradas.
4. Units que usam `TFDQuery` incluem `FireDAC.DApt`.

Para rodar tudo:

```bat
build.bat
```

## 19. Como Alterar O Projeto Com Seguranca

Para um iniciante, um bom fluxo e:

1. Entenda em qual camada a mudanca entra.
2. Se for tela, olhe `Presentation`.
3. Se for regra auxiliar, olhe `Application`.
4. Se for dados simples, olhe `Domain`.
5. Se for arquivo, banco, log ou processo externo, olhe `Infrastructure`.
6. Faça uma mudanca pequena.
7. Rode `build.bat`.
8. Teste pelo Delphi.
9. Leia `logs\application.log` se algo falhar.

Evite mudar muitas coisas ao mesmo tempo. Em Delphi, varios erros aparecem so em tempo de execucao, entao mudancas pequenas sao mais faceis de depurar.

## 20. Caminho Mental Do Aplicativo

O fluxo completo do Tube2MP3 e:

```text
Usuario cola URL
  -> TMainForm valida URL
  -> TYtDlpService chama yt-dlp para analisar
  -> JSON vira TVideoInfo
  -> Tela mostra titulo/canal/duracao/thumbnail
  -> Usuario escolhe pasta e bitrate
  -> TYtDlpService chama yt-dlp + ffmpeg
  -> Progresso atualiza a tela
  -> MP3 final e localizado
  -> THistoryRepository grava no SQLite
  -> LoadHistory atualiza o historico visual
```

Esse desenho e uma boa forma de entender onde cada bug pode estar.

Se a URL nao valida, procure em `Application.Helpers`.

Se a tela nao atualiza, procure em `Presentation.Main`.

Se o download falha, procure em `Infrastructure.YtDlp` ou `ProcessRunner`.

Se o historico nao grava, procure em `Infrastructure.History`.

Se a configuracao nao salva, procure em `Infrastructure.Settings`.

## 21. Conceitos Delphi Que Este Projeto Ensina

Este projeto pratica varios conceitos importantes:

`program`: ponto de entrada.

`unit`: organizacao de codigo.

`uses`: importacao de dependencias.

`class`: objeto com estado e comportamento.

`record`: estrutura simples de dados.

`procedure`: metodo que executa uma acao e nao retorna valor.

`function`: metodo que retorna valor.

`constructor`: inicializacao de objeto.

`destructor`: limpeza de objeto.

`try/except`: tratamento de erros.

`try/finally`: garantia de limpeza.

`TThread`: execucao em segundo plano.

`TThread.Queue`: volta para a thread da interface.

`FireDAC`: acesso a banco de dados.

`TListView`: lista visual em modo tabela.

`TPath`: manipulacao segura de caminhos.

`TJSONObject`: leitura de JSON.

## 22. Proximos Passos Para Estudar

Depois de entender este projeto, bons proximos temas sao:

1. Criar uma tela simples VCL do zero.
2. Entender propriedades e eventos no Object Inspector.
3. Praticar `try/finally` com objetos.
4. Fazer consultas SQLite com FireDAC.
5. Criar testes para funcoes auxiliares.
6. Aprender a separar UI, regra de negocio e infraestrutura.
7. Usar Git para salvar cada mudanca pequena.

O mais importante: leia o codigo com calma e siga o fluxo de um clique. Em aplicativos VCL, quase tudo comeca em um evento de componente.

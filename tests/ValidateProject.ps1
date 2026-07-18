$ErrorActionPreference = 'Stop'

[xml]$project = Get-Content -Raw (Join-Path $PSScriptRoot '..\Tube2MP3.dproj')
$ns = New-Object System.Xml.XmlNamespaceManager($project.NameTable)
$ns.AddNamespace('m', 'http://schemas.microsoft.com/developer/msbuild/2003')

$compile = $project.SelectSingleNode('//m:DelphiCompile', $ns)
if ($compile.Include -ne '$(MainSource)') {
    throw 'DelphiCompile deve referenciar $(MainSource) para evitar DPR duplicado na IDE.'
}
if ($compile.MainSource -ne 'MainSource') {
    throw 'DelphiCompile deve marcar o item principal com MainSource.'
}

$sourceFiles = @(
    Get-ChildItem (Join-Path $PSScriptRoot '..\src') -Recurse -File |
        Where-Object Extension -in '.pas', '.dfm'
)
$sourceFiles += Get-Item (Join-Path $PSScriptRoot '..\Tube2MP3.dpr')

$dprText = Get-Content -Raw (Join-Path $PSScriptRoot '..\Tube2MP3.dpr')
$usesFireDAC = Get-ChildItem (Join-Path $PSScriptRoot '..\src') -Recurse -File -Filter '*.pas' |
    Select-String -Pattern 'FireDAC\.' -Quiet
if ($usesFireDAC -and $dprText -notmatch 'FireDAC\.VCLUI\.Wait') {
    throw 'Projeto usa FireDAC, mas Tube2MP3.dpr nao registra FireDAC.VCLUI.Wait.'
}

Get-ChildItem (Join-Path $PSScriptRoot '..\src') -Recurse -File -Filter '*.pas' |
    ForEach-Object {
        $text = Get-Content -Raw $_.FullName
        if ($text -match '\bTFDQuery\b' -and $text -notmatch 'FireDAC\.DApt') {
            throw "Unit usa TFDQuery, mas nao inclui FireDAC.DApt: $($_.FullName)"
        }
    }

foreach ($file in $sourceFiles) {
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $hasUtf8Bom = $bytes.Length -ge 3 -and
        $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    if (-not $hasUtf8Bom) {
        throw "Arquivo Delphi sem BOM UTF-8: $($file.FullName)"
    }
}

$mainFormPath = Join-Path $PSScriptRoot '..\src\Presentation\Tube2MP3.Presentation.Main.pas'
$mainFormText = Get-Content -Raw $mainFormPath
$requiredPlaybackMembers = @(
    'Vcl.MPlayer',
    'mediaPlayer: TMediaPlayer',
    'btnPlay: TButton',
    'btnPause: TButton',
    'btnStop: TButton',
    'procedure btnPlayClick(Sender: TObject)',
    'procedure btnPauseClick(Sender: TObject)',
    'procedure btnStopClick(Sender: TObject)',
    'procedure lvHistorySelectItem(Sender: TObject; Item: TListItem;',
    'SetPlaybackFile(FilePath)',
    'SetPlaybackFile(Path)'
)
foreach ($member in $requiredPlaybackMembers) {
    if ($mainFormText -notlike "*$member*") {
        throw "Player MP3 incompleto: declaracao ausente '$member'."
    }
}

$requiredQueueMembers = @(
    'FQueue: TList<TQueuedDownload>',
    'FQueueView: TListView',
    'FQueueRunning: Boolean',
    'procedure RefreshQueue',
    'procedure EnqueueDownload(const AUrl, AFolder: string; ABitrate: Integer;',
    'procedure StartNextQueuedDownload',
    'procedure UpdateQueueItemStatus(AIndex: Integer; const AStatus: string)',
    'procedure FinishQueuedDownload(AIndex: Integer; const AStatus: string)',
    'EnqueueDownload(Url, Folder, Bitrate, Video)',
    'StartNextQueuedDownload',
    'FinishQueuedDownload(QueueIndex, ''Concluido'')',
    'FinishQueuedDownload(QueueIndex, ''Falhou'')',
    'FinishQueuedDownload(QueueIndex, ''Cancelado'')'
)
foreach ($member in $requiredQueueMembers) {
    if ($mainFormText -notlike "*$member*") {
        throw "Fila de downloads incompleta: declaracao ausente '$member'."
    }
}

$requiredResponsiveMembers = @(
    'procedure FormResize(Sender: TObject)',
    'procedure LayoutMainControls',
    'OnResize = FormResize',
    'LayoutMainControls;'
)
foreach ($member in $requiredResponsiveMembers) {
    if (($mainFormText + (Get-Content -Raw (Join-Path $PSScriptRoot '..\src\Presentation\Tube2MP3.Presentation.Main.dfm'))) -notlike "*$member*") {
        throw "Layout responsivo incompleto: declaracao ausente '$member'."
    }
}

if ($mainFormText -like '*ClientHeight := 880*') {
    throw 'Layout alto demais: nao force ClientHeight 880 em tempo de execucao.'
}

Write-Host 'PROJECT VALIDATION PASSED'

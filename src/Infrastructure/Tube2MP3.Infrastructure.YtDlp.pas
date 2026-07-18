unit Tube2MP3.Infrastructure.YtDlp;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.IOUtils, System.Types,
  Tube2MP3.Domain.Models, Tube2MP3.Infrastructure.ProcessRunner,
  Tube2MP3.Infrastructure.Logger;

type
  TProgressCallback = reference to procedure(const AProgress: TDownloadProgress);

  TYtDlpService = class
  private
    FYtDlpPath: string;
    FFmpegPath: string;
    FLogger: TFileLogger;
    FRunner: TProcessRunner;
    function JsonString(AObject: TJSONObject; const AName: string): string;
    function JsonInteger(AObject: TJSONObject; const AName: string): Int64;
    function FindRecentMp3(const ADestination: string; AStartedAt: TDateTime): string;
  public
    constructor Create(const AYtDlpPath, AFFmpegPath: string; ALogger: TFileLogger);
    destructor Destroy; override;
    function GetVideoInfo(const AUrl: string): TVideoInfo;
    function DownloadAudio(const AUrl, ADestination: string; ABitrate: Integer;
      const AOnProgress: TProgressCallback): string;
    procedure Cancel;
  end;

implementation

uses
  Tube2MP3.Application.Helpers;

constructor TYtDlpService.Create(const AYtDlpPath, AFFmpegPath: string;
  ALogger: TFileLogger);
begin
  inherited Create;
  FYtDlpPath := AYtDlpPath;
  FFmpegPath := AFFmpegPath;
  FLogger := ALogger;
  FRunner := TProcessRunner.Create;
end;

destructor TYtDlpService.Destroy;
begin
  FRunner.Free;
  inherited;
end;

procedure TYtDlpService.Cancel;
begin
  FRunner.Cancel;
end;

function TYtDlpService.JsonString(AObject: TJSONObject;
  const AName: string): string;
var
  V: TJSONValue;
begin
  Result := '';
  V := AObject.GetValue(AName);
  if (V <> nil) and not (V is TJSONNull) then
    Result := V.Value;
end;

function TYtDlpService.JsonInteger(AObject: TJSONObject;
  const AName: string): Int64;
begin
  Result := StrToInt64Def(JsonString(AObject, AName), 0);
end;

function TYtDlpService.FindRecentMp3(const ADestination: string;
  AStartedAt: TDateTime): string;
var
  Files: TStringDynArray;
  FileName: string;
  BestTime, FileTime: TDateTime;
begin
  Result := '';
  BestTime := 0;
  if not TDirectory.Exists(ADestination) then
    Exit;
  Files := TDirectory.GetFiles(ADestination, '*.mp3');
  for FileName in Files do
  begin
    FileTime := TFile.GetLastWriteTime(FileName);
    if (FileTime >= AStartedAt) and ((Result = '') or (FileTime > BestTime)) then
    begin
      Result := FileName;
      BestTime := FileTime;
    end;
  end;
end;

function TYtDlpService.GetVideoInfo(const AUrl: string): TVideoInfo;
var
  Output: string;
  ExitCode: Cardinal;
  Obj: TJSONObject;
begin
  Result := Default(TVideoInfo);
  if not FileExists(FYtDlpPath) then
    raise Exception.Create('yt-dlp.exe não encontrado em:' + sLineBreak + FYtDlpPath);
  FLogger.Info('Analisando URL: ' + AUrl);
  ExitCode := FRunner.Execute(FYtDlpPath,
    '--dump-single-json --no-playlist --no-warnings ' + QuoteArg(AUrl),
    ExtractFileDir(FYtDlpPath), nil, Output);
  if ExitCode <> 0 then
    raise Exception.Create('Não foi possível analisar o vídeo.' + sLineBreak + Trim(Output));
  Obj := TJSONObject.ParseJSONValue(Trim(Output)) as TJSONObject;
  try
    if Obj = nil then
      raise Exception.Create('O yt-dlp retornou metadados inválidos.');
    Result.Title := JsonString(Obj, 'title');
    Result.Channel := JsonString(Obj, 'channel');
    if Result.Channel = '' then
      Result.Channel := JsonString(Obj, 'uploader');
    Result.Duration := JsonInteger(Obj, 'duration');
    Result.ThumbnailUrl := JsonString(Obj, 'thumbnail');
    Result.UploadDate := JsonString(Obj, 'upload_date');
    Result.ViewCount := JsonInteger(Obj, 'view_count');
  finally
    Obj.Free;
  end;
  FLogger.Info('Metadados obtidos: ' + Result.Title);
end;

function TYtDlpService.DownloadAudio(const AUrl, ADestination: string;
  ABitrate: Integer; const AOnProgress: TProgressCallback): string;
var
  Args, Output, FinalPath: string;
  ExitCode: Cardinal;
  StartedAt: TDateTime;
begin
  if not FileExists(FYtDlpPath) then
    raise Exception.Create('yt-dlp.exe não encontrado em:' + sLineBreak + FYtDlpPath);
  if not FileExists(FFmpegPath) then
    raise Exception.Create('ffmpeg.exe não encontrado em:' + sLineBreak + FFmpegPath);
  ForceDirectories(ADestination);
  FinalPath := '';
  StartedAt := Now;
  Args := '--no-playlist --newline --progress --extract-audio --audio-format mp3 ' +
    '--audio-quality ' + IntToStr(ABitrate) + 'K ' +
    '--ffmpeg-location ' + QuoteArg(FFmpegPath) + ' ' +
    '--output ' + QuoteArg(TPath.Combine(ADestination, '%(title).180B.%(ext)s')) + ' ' +
    '--print ' + QuoteArg('after_move:__FILE__%(filepath)s') + ' ' + QuoteArg(AUrl);
  FLogger.Info(Format('Iniciando download (%d kbps): %s', [ABitrate, AUrl]));
  ExitCode := FRunner.Execute(FYtDlpPath, Args, ExtractFileDir(FYtDlpPath),
    procedure(const ALine: string)
    var
      P: TDownloadProgress;
    begin
      if Pos('__FILE__', ALine) = 1 then
        FinalPath := Copy(ALine, Length('__FILE__') + 1, MaxInt)
      else if TryParseProgress(ALine, P) and Assigned(AOnProgress) then
        AOnProgress(P);
    end, Output);
  if FRunner.Cancelled then
    raise EAbort.Create('Download cancelado.');
  if ExitCode <> 0 then
    raise Exception.Create('Falha no download ou conversão.' + sLineBreak + Trim(Output));
  FinalPath := Trim(FinalPath);
  if (FinalPath <> '') and (FinalPath[1] = '"') and (FinalPath[Length(FinalPath)] = '"') then
    FinalPath := Copy(FinalPath, 2, Length(FinalPath) - 2);
  if (FinalPath = '') or not FileExists(FinalPath) then
    FinalPath := FindRecentMp3(ADestination, StartedAt);
  if (FinalPath = '') or not FileExists(FinalPath) then
    raise Exception.Create('O download terminou, mas o arquivo MP3 não foi localizado.' +
      sLineBreak + Trim(Output));
  FLogger.Info('Download concluído: ' + FinalPath);
  Result := FinalPath;
end;

end.

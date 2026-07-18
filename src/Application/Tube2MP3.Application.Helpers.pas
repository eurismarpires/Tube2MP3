unit Tube2MP3.Application.Helpers;

interface

uses
  System.SysUtils, System.IOUtils, System.Types,
  System.Net.URLClient,
  System.RegularExpressions,
  Tube2MP3.Domain.Models;

function IsSupportedYouTubeUrl(const AUrl: string): Boolean;
function FormatDuration(ASeconds: Integer): string;
function TryParseProgress(const ALine: string; out AProgress: TDownloadProgress): Boolean;
function QuoteArg(const AValue: string): string;
function ResolveExistingAudioFile(const AFilePath: string): string;

implementation

function IsSupportedYouTubeUrl(const AUrl: string): Boolean;
var
  Uri: TURI;
  Host: string;
begin
  try
    Uri := TURI.Create(Trim(AUrl));
    Host := LowerCase(Uri.Host);
    Result := ((Uri.Scheme = 'http') or (Uri.Scheme = 'https')) and
      ((Host = 'youtube.com') or (Host = 'www.youtube.com') or
       (Host = 'm.youtube.com') or (Host = 'youtu.be'));
  except
    Result := False;
  end;
end;

function FormatDuration(ASeconds: Integer): string;
begin
  if ASeconds < 0 then
    ASeconds := 0;
  if ASeconds >= 3600 then
    Result := Format('%d:%.2d:%.2d', [ASeconds div 3600,
      (ASeconds mod 3600) div 60, ASeconds mod 60])
  else
    Result := Format('%.2d:%.2d', [ASeconds div 60, ASeconds mod 60]);
end;

function TryParseProgress(const ALine: string; out AProgress: TDownloadProgress): Boolean;
var
  Match: TMatch;
  function GroupValue(AIndex: Integer): string;
  begin
    if (AIndex >= 0) and (AIndex < Match.Groups.Count) and Match.Groups[AIndex].Success then
      Result := Match.Groups[AIndex].Value
    else
      Result := '';
  end;
begin
  AProgress := Default(TDownloadProgress);
  Match := TRegEx.Match(ALine,
    '\[download\]\s+([0-9]+(?:[.,][0-9]+)?)%\s+of\s+(\S+)(?:\s+at\s+(\S+))?(?:\s+ETA\s+(\S+))?',
    [roIgnoreCase]);
  Result := Match.Success;
  if Result then
  begin
    AProgress.Percent := StrToFloatDef(StringReplace(GroupValue(1),
      '.', FormatSettings.DecimalSeparator, []), 0);
    AProgress.Downloaded := GroupValue(2);
    AProgress.Speed := GroupValue(3);
    AProgress.Eta := GroupValue(4);
    AProgress.Status := 'Baixando';
  end;
end;

function QuoteArg(const AValue: string): string;
begin
  Result := '"' + StringReplace(AValue, '"', '\"', [rfReplaceAll]) + '"';
end;

function ResolveExistingAudioFile(const AFilePath: string): string;
var
  Folder, ExpectedName, Candidate: string;
  Candidates: TStringDynArray;
  I: Integer;
  Matches: Boolean;
begin
  if FileExists(AFilePath) then
    Exit(AFilePath);
  Folder := ExtractFileDir(AFilePath);
  ExpectedName := ExtractFileName(AFilePath);
  if (ExpectedName = '') or (Pos('?', ExpectedName) = 0) or
    not TDirectory.Exists(Folder) then
    Exit('');
  Candidates := TDirectory.GetFiles(Folder, '*.mp3');
  for Candidate in Candidates do
  begin
    if Length(ExtractFileName(Candidate)) <> Length(ExpectedName) then
      Continue;
    Matches := True;
    for I := 1 to Length(ExpectedName) do
      if (ExpectedName[I] <> '?') and
        not SameText(string(ExpectedName[I]), string(ExtractFileName(Candidate)[I])) then
      begin
        Matches := False;
        Break;
      end;
    if Matches then
      Exit(Candidate);
  end;
  Result := '';
end;

end.

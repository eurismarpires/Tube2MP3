program Tube2MP3Tests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.IOUtils, System.Generics.Collections,
  Tube2MP3.Application.Helpers in 'src\Application\Tube2MP3.Application.Helpers.pas',
  Tube2MP3.Domain.Models in 'src\Domain\Tube2MP3.Domain.Models.pas',
  Tube2MP3.Infrastructure.History in 'src\Infrastructure\Tube2MP3.Infrastructure.History.pas';

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure Run;
var
  P: TDownloadProgress;
  Folder, ActualPath, StoredPath, DatabasePath: string;
  History: THistoryRepository;
  HistoryItem: THistoryItem;
  HistoryItems: TList<THistoryItem>;
begin
  Check(IsSupportedYouTubeUrl('https://www.youtube.com/watch?v=abc123'), 'youtube URL');
  Check(IsSupportedYouTubeUrl('https://youtu.be/abc123'), 'youtu.be URL');
  Check(not IsSupportedYouTubeUrl('https://example.com/watch?v=abc123'), 'foreign host');
  Check(not IsSupportedYouTubeUrl('not a URL'), 'invalid URL');
  Check(FormatDuration(0) = '00:00', 'zero duration');
  Check(FormatDuration(65) = '01:05', 'minute duration');
  Check(FormatDuration(3661) = '1:01:01', 'hour duration');
  Check(TryParseProgress('[download]  56.2% of 10.00MiB at 2.30MiB/s ETA 00:18', P), 'parse progress');
  Check(Abs(P.Percent - 56.2) < 0.01, 'progress percent');
  Check(P.Speed = '2.30MiB/s', 'progress speed');
  Check(P.Eta = '00:18', 'progress eta');
  Check(TryParseProgress('[download] 100.0% of 4.00MiB', P), 'parse progress without optional fields');
  Check(Abs(P.Percent - 100.0) < 0.01, 'progress percent without optional fields');
  Check(P.Speed = '', 'progress speed without optional fields');
  Check(P.Eta = '', 'progress eta without optional fields');
  Folder := TPath.Combine(TPath.GetTempPath, 'Tube2MP3Tests-' +
    TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(Folder);
  try
    ActualPath := TPath.Combine(Folder, 'ELE VEM' + Char($2503) +
      'JEFFERSON.mp3');
    StoredPath := TPath.Combine(Folder, 'ELE VEM?JEFFERSON.mp3');
    TFile.WriteAllText(ActualPath, 'test');
    Check(ResolveExistingAudioFile(StoredPath) = ActualPath,
      'resolve historical audio path with replaced character');
  finally
    TDirectory.Delete(Folder, True);
  end;
  Folder := TPath.Combine(TPath.GetTempPath, 'Tube2MP3HistoryTests-' +
    TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(Folder);
  try
    DatabasePath := TPath.Combine(Folder, 'history.db');
    History := THistoryRepository.Create(DatabasePath);
    try
      HistoryItem := Default(THistoryItem);
      HistoryItem.Title := 'thumbnail test';
      HistoryItem.Url := 'https://youtu.be/abc123';
      HistoryItem.FilePath := 'C:\temp\audio.mp3';
      HistoryItem.Status := 'Concluido';
      HistoryItem.CreatedAt := Now;
      HistoryItem.ThumbnailPath := 'C:\temp\thumbnail.jpg';
      History.Add(HistoryItem);
      HistoryItems := History.GetAll;
      try
        Check(HistoryItems[0].ThumbnailPath = HistoryItem.ThumbnailPath,
          'persist thumbnail path');
        History.UpdateThumbnailPath(HistoryItems[0].Id, 'C:\temp\updated.jpg');
      finally
        HistoryItems.Free;
      end;
      HistoryItems := History.GetAll;
      try
        Check(HistoryItems[0].ThumbnailPath = 'C:\temp\updated.jpg',
          'update thumbnail path');
      finally
        HistoryItems.Free;
      end;
    finally
      History.Free;
    end;
  finally
    TDirectory.Delete(Folder, True);
  end;
end;

begin
  try
    Run;
    Writeln('ALL TESTS PASSED');
  except
    on E: Exception do
    begin
      Writeln('TEST FAILED: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.

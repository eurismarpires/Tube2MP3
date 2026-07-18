program Tube2MP3Tests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Tube2MP3.Application.Helpers in 'src\Application\Tube2MP3.Application.Helpers.pas',
  Tube2MP3.Domain.Models in 'src\Domain\Tube2MP3.Domain.Models.pas';

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure Run;
var
  P: TDownloadProgress;
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

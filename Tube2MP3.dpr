program Tube2MP3;

uses
  Vcl.Forms,
  FireDAC.VCLUI.Wait,
  Tube2MP3.Presentation.Main in 'src\Presentation\Tube2MP3.Presentation.Main.pas' {MainForm},
  Tube2MP3.Domain.Models in 'src\Domain\Tube2MP3.Domain.Models.pas',
  Tube2MP3.Application.Helpers in 'src\Application\Tube2MP3.Application.Helpers.pas',
  Tube2MP3.Infrastructure.Logger in 'src\Infrastructure\Tube2MP3.Infrastructure.Logger.pas',
  Tube2MP3.Infrastructure.Settings in 'src\Infrastructure\Tube2MP3.Infrastructure.Settings.pas',
  Tube2MP3.Infrastructure.History in 'src\Infrastructure\Tube2MP3.Infrastructure.History.pas',
  Tube2MP3.Infrastructure.ProcessRunner in 'src\Infrastructure\Tube2MP3.Infrastructure.ProcessRunner.pas',
  Tube2MP3.Infrastructure.YtDlp in 'src\Infrastructure\Tube2MP3.Infrastructure.YtDlp.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Tube2MP3';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

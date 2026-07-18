unit Tube2MP3.Infrastructure.Logger;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs;

type
  TFileLogger = class
  private
    FFileName: string;
    FLock: TCriticalSection;
    procedure Write(const ALevel, AMessage: string);
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    procedure Info(const AMessage: string);
    procedure Error(const AMessage: string);
  end;

implementation

constructor TFileLogger.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
  ForceDirectories(ExtractFileDir(FFileName));
  FLock := TCriticalSection.Create;
end;

destructor TFileLogger.Destroy;
begin
  FLock.Free;
  inherited;
end;

procedure TFileLogger.Write(const ALevel, AMessage: string);
var
  F: TextFile;
begin
  FLock.Acquire;
  try
    AssignFile(F, FFileName);
    if FileExists(FFileName) then
      Append(F)
    else
      Rewrite(F);
    try
      Writeln(F, FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' [' +
        ALevel + '] ' + AMessage);
    finally
      CloseFile(F);
    end;
  finally
    FLock.Release;
  end;
end;

procedure TFileLogger.Info(const AMessage: string);
begin
  Write('INFO', AMessage);
end;

procedure TFileLogger.Error(const AMessage: string);
begin
  Write('ERROR', AMessage);
end;

end.

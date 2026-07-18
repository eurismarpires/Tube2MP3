unit Tube2MP3.Infrastructure.ProcessRunner;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.SyncObjs;

type
  TLineCallback = reference to procedure(const ALine: string);

  TProcessRunner = class
  private
    FLock: TCriticalSection;
    FJob: THandle;
    FCancelled: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function Execute(const AExecutable, AArguments, AWorkingDir: string;
      const AOnLine: TLineCallback; out AOutput: string): Cardinal;
    procedure Cancel;
    property Cancelled: Boolean read FCancelled;
  end;

implementation

constructor TProcessRunner.Create;
begin
  inherited;
  FLock := TCriticalSection.Create;
  FJob := 0;
end;

destructor TProcessRunner.Destroy;
begin
  Cancel;
  FLock.Free;
  inherited;
end;

procedure TProcessRunner.Cancel;
begin
  FLock.Acquire;
  try
    FCancelled := True;
    if FJob <> 0 then
      TerminateJobObject(FJob, ERROR_CANCELLED);
  finally
    FLock.Release;
  end;
end;

function TProcessRunner.Execute(const AExecutable, AArguments,
  AWorkingDir: string; const AOnLine: TLineCallback; out AOutput: string): Cardinal;
var
  Security: TSecurityAttributes;
  ReadPipe, WritePipe: THandle;
  Startup: TStartupInfo;
  ProcessInfo: TProcessInformation;
  JobInfo: TJobObjectExtendedLimitInformation;
  CommandLine: string;
  Buffer: array[0..4095] of AnsiChar;
  BytesRead: Cardinal;
  Pending, WaitResult: Cardinal;
  Chunk, TextBuffer, Line: string;
  LineEnd: Integer;
begin
  Result := Cardinal(-1);
  AOutput := '';
  ReadPipe := 0;
  WritePipe := 0;
  ZeroMemory(@Security, SizeOf(Security));
  Security.nLength := SizeOf(Security);
  Security.bInheritHandle := True;
  if not CreatePipe(ReadPipe, WritePipe, @Security, 0) then
    RaiseLastOSError;
  try
    SetHandleInformation(ReadPipe, HANDLE_FLAG_INHERIT, 0);
    ZeroMemory(@Startup, SizeOf(Startup));
    Startup.cb := SizeOf(Startup);
    Startup.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    Startup.wShowWindow := SW_HIDE;
    Startup.hStdOutput := WritePipe;
    Startup.hStdError := WritePipe;
    Startup.hStdInput := GetStdHandle(STD_INPUT_HANDLE);
    ZeroMemory(@ProcessInfo, SizeOf(ProcessInfo));
    CommandLine := '"' + AExecutable + '" ' + AArguments;
    FCancelled := False;
    FLock.Acquire;
    try
      FJob := CreateJobObject(nil, nil);
      if FJob = 0 then
        RaiseLastOSError;
      ZeroMemory(@JobInfo, SizeOf(JobInfo));
      JobInfo.BasicLimitInformation.LimitFlags := JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
      if not SetInformationJobObject(FJob, JobObjectExtendedLimitInformation,
        @JobInfo, SizeOf(JobInfo)) then
        RaiseLastOSError;
    finally
      FLock.Release;
    end;
    if not CreateProcess(nil, PChar(CommandLine), nil, nil, True,
      CREATE_NO_WINDOW, nil, PChar(AWorkingDir), Startup, ProcessInfo) then
      RaiseLastOSError;
    CloseHandle(WritePipe);
    WritePipe := 0;
    try
      AssignProcessToJobObject(FJob, ProcessInfo.hProcess);
      TextBuffer := '';
      repeat
        Pending := 0;
        if PeekNamedPipe(ReadPipe, nil, 0, nil, @Pending, nil) and (Pending > 0) then
        begin
          if ReadFile(ReadPipe, Buffer, SizeOf(Buffer), BytesRead, nil) and
            (BytesRead > 0) then
          begin
            SetString(Chunk, PAnsiChar(@Buffer[0]), BytesRead);
            TextBuffer := TextBuffer + UTF8ToString(RawByteString(Chunk));
            LineEnd := Pos(#10, TextBuffer);
            while LineEnd > 0 do
            begin
              Line := TrimRight(Copy(TextBuffer, 1, LineEnd - 1));
              Delete(TextBuffer, 1, LineEnd);
              AOutput := AOutput + Line + sLineBreak;
              if Assigned(AOnLine) then
                AOnLine(Line);
              LineEnd := Pos(#10, TextBuffer);
            end;
          end;
        end;
        WaitResult := WaitForSingleObject(ProcessInfo.hProcess, 25);
      until WaitResult <> WAIT_TIMEOUT;
      while ReadFile(ReadPipe, Buffer, SizeOf(Buffer), BytesRead, nil) and
        (BytesRead > 0) do
      begin
        SetString(Chunk, PAnsiChar(@Buffer[0]), BytesRead);
        TextBuffer := TextBuffer + UTF8ToString(RawByteString(Chunk));
      end;
      if TextBuffer <> '' then
      begin
        AOutput := AOutput + TextBuffer;
        if Assigned(AOnLine) then
          AOnLine(Trim(TextBuffer));
      end;
      GetExitCodeProcess(ProcessInfo.hProcess, Result);
    finally
      CloseHandle(ProcessInfo.hThread);
      CloseHandle(ProcessInfo.hProcess);
      FLock.Acquire;
      try
        if FJob <> 0 then
        begin
          CloseHandle(FJob);
          FJob := 0;
        end;
      finally
        FLock.Release;
      end;
    end;
  finally
    if WritePipe <> 0 then CloseHandle(WritePipe);
    if ReadPipe <> 0 then CloseHandle(ReadPipe);
  end;
end;

end.

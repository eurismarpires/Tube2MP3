unit Tube2MP3.Infrastructure.Settings;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.IOUtils;

type
  TAppSettings = class
  private
    FFileName: string;
  public
    DownloadFolder: string;
    Bitrate: Integer;
    constructor Create(const AFileName: string);
    procedure Load;
    procedure Save;
  end;

implementation

constructor TAppSettings.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
  DownloadFolder := TPath.GetDocumentsPath;
  Bitrate := 192;
end;

procedure TAppSettings.Load;
var
  Obj: TJSONObject;
  Value: TJSONValue;
begin
  if not FileExists(FFileName) then
    Exit;
  Obj := TJSONObject.ParseJSONValue(TFile.ReadAllText(FFileName, TEncoding.UTF8))
    as TJSONObject;
  try
    if Obj = nil then
      Exit;
    Value := Obj.GetValue('downloadFolder');
    if Value <> nil then
      DownloadFolder := Value.Value;
    Value := Obj.GetValue('bitrate');
    if Value <> nil then
      Bitrate := StrToIntDef(Value.Value, 192);
  finally
    Obj.Free;
  end;
end;

procedure TAppSettings.Save;
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  try
    Obj.AddPair('downloadFolder', DownloadFolder);
    Obj.AddPair('bitrate', TJSONNumber.Create(Bitrate));
    TFile.WriteAllText(FFileName, Obj.Format(2), TEncoding.UTF8);
  finally
    Obj.Free;
  end;
end;

end.

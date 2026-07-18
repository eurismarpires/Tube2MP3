unit Tube2MP3.Infrastructure.History;

interface

uses
  System.SysUtils, System.Generics.Collections,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Stan.Async,
  FireDAC.Stan.Intf, FireDAC.Stan.Param, FireDAC.Phys, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.DApt,
  Tube2MP3.Domain.Models;

type
  THistoryRepository = class
  private
    FConnection: TFDConnection;
    procedure EnsureThumbnailColumn;
  public
    constructor Create(const ADatabasePath: string);
    destructor Destroy; override;
    procedure Add(const AItem: THistoryItem);
    procedure UpdateThumbnailPath(AId: Integer; const APath: string);
    function GetAll: TList<THistoryItem>;
  end;

implementation

constructor THistoryRepository.Create(const ADatabasePath: string);
begin
  inherited Create;
  ForceDirectories(ExtractFileDir(ADatabasePath));
  FConnection := TFDConnection.Create(nil);
  FConnection.LoginPrompt := False;
  FConnection.Params.DriverID := 'SQLite';
  FConnection.Params.Database := ADatabasePath;
  FConnection.Connected := True;
  FConnection.ExecSQL(
    'CREATE TABLE IF NOT EXISTS downloads (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, url TEXT NOT NULL,' +
    'channel TEXT, duration INTEGER, quality INTEGER, size INTEGER, file_path TEXT,' +
    'status TEXT NOT NULL, created_at DATETIME DEFAULT CURRENT_TIMESTAMP)');
  EnsureThumbnailColumn;
end;

procedure THistoryRepository.EnsureThumbnailColumn;
var
  Q: TFDQuery;
  HasColumn: Boolean;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'PRAGMA table_info(downloads)';
    Q.Open;
    HasColumn := False;
    while not Q.Eof do
    begin
      if SameText(Q.FieldByName('name').AsString, 'thumbnail_path') then
      begin
        HasColumn := True;
        Break;
      end;
      Q.Next;
    end;
    if not HasColumn then
      FConnection.ExecSQL('ALTER TABLE downloads ADD COLUMN thumbnail_path TEXT');
  finally
    Q.Free;
  end;
end;

destructor THistoryRepository.Destroy;
begin
  FConnection.Free;
  inherited;
end;

procedure THistoryRepository.Add(const AItem: THistoryItem);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'INSERT INTO downloads ' +
      '(title,url,channel,duration,quality,size,file_path,thumbnail_path,status,created_at) ' +
      'VALUES (:title,:url,:channel,:duration,:quality,:size,:file_path,:thumbnail_path,:status,:created_at)';
    Q.ParamByName('title').AsString := AItem.Title;
    Q.ParamByName('url').AsString := AItem.Url;
    Q.ParamByName('channel').AsString := AItem.Channel;
    Q.ParamByName('duration').AsInteger := AItem.Duration;
    Q.ParamByName('quality').AsInteger := AItem.Quality;
    Q.ParamByName('size').AsLargeInt := AItem.Size;
    Q.ParamByName('file_path').AsString := AItem.FilePath;
    Q.ParamByName('thumbnail_path').AsString := AItem.ThumbnailPath;
    Q.ParamByName('status').AsString := AItem.Status;
    Q.ParamByName('created_at').AsDateTime := AItem.CreatedAt;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure THistoryRepository.UpdateThumbnailPath(AId: Integer; const APath: string);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'UPDATE downloads SET thumbnail_path = :thumbnail_path WHERE id = :id';
    Q.ParamByName('thumbnail_path').AsString := APath;
    Q.ParamByName('id').AsInteger := AId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

function THistoryRepository.GetAll: TList<THistoryItem>;
var
  Q: TFDQuery;
  Item: THistoryItem;
begin
  Result := TList<THistoryItem>.Create;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := FConnection;
    Q.SQL.Text := 'SELECT * FROM downloads ORDER BY id DESC LIMIT 200';
    Q.Open;
    while not Q.Eof do
    begin
      Item := Default(THistoryItem);
      Item.Id := Q.FieldByName('id').AsInteger;
      Item.Title := Q.FieldByName('title').AsString;
      Item.Url := Q.FieldByName('url').AsString;
      Item.Channel := Q.FieldByName('channel').AsString;
      Item.Duration := Q.FieldByName('duration').AsInteger;
      Item.Quality := Q.FieldByName('quality').AsInteger;
      Item.Size := Q.FieldByName('size').AsLargeInt;
      Item.FilePath := Q.FieldByName('file_path').AsString;
      Item.ThumbnailPath := Q.FieldByName('thumbnail_path').AsString;
      Item.Status := Q.FieldByName('status').AsString;
      Item.CreatedAt := Q.FieldByName('created_at').AsDateTime;
      Result.Add(Item);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

end.

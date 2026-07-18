unit Tube2MP3.Presentation.Main;

interface

uses
  Winapi.Windows, Winapi.ShellAPI,
  System.SysUtils, System.Classes, System.IOUtils, System.Threading, System.UITypes,
  System.Net.HttpClient, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Clipbrd,
  Tube2MP3.Domain.Models, Tube2MP3.Infrastructure.Logger,
  Tube2MP3.Infrastructure.Settings, Tube2MP3.Infrastructure.History,
  Tube2MP3.Infrastructure.YtDlp;

type
  TMainForm = class(TForm)
    pnlTop: TPanel;
    lblUrl: TLabel;
    edtUrl: TEdit;
    btnPaste: TButton;
    btnAnalyze: TButton;
    imgThumbnail: TImage;
    lblTitleCaption: TLabel;
    lblTitle: TLabel;
    lblChannelCaption: TLabel;
    lblChannel: TLabel;
    lblDurationCaption: TLabel;
    lblDuration: TLabel;
    lblFolderCaption: TLabel;
    edtFolder: TEdit;
    btnFolder: TButton;
    lblQuality: TLabel;
    cbBitrate: TComboBox;
    btnDownload: TButton;
    btnCancel: TButton;
    progressBar: TProgressBar;
    lblStatus: TLabel;
    lblSpeed: TLabel;
    lblHistory: TLabel;
    lvHistory: TListView;
    btnOpenFolder: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnPasteClick(Sender: TObject);
    procedure btnAnalyzeClick(Sender: TObject);
    procedure btnFolderClick(Sender: TObject);
    procedure btnDownloadClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnOpenFolderClick(Sender: TObject);
    procedure lvHistoryDblClick(Sender: TObject);
  private
    FBasePath: string;
    FLogger: TFileLogger;
    FSettings: TAppSettings;
    FHistory: THistoryRepository;
    FYtDlp: TYtDlpService;
    FWorker: TThread;
    FVideo: TVideoInfo;
    procedure SetBusy(ABusy: Boolean; const AStatus: string);
    procedure LoadHistory;
    procedure LoadThumbnail(const AUrl: string);
    procedure StopWorker;
    function SelectedBitrate: Integer;
    function GetLocalFileSize(const AFileName: string): Int64;
    function FindProjectBase: string;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  Tube2MP3.Application.Helpers, Vcl.FileCtrl, Vcl.Imaging.jpeg,
  Vcl.Imaging.pngimage;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Caption := 'Tube2MP3';
  FBasePath := FindProjectBase;
  FLogger := TFileLogger.Create(TPath.Combine(FBasePath, 'logs\application.log'));
  FSettings := TAppSettings.Create(TPath.Combine(FBasePath, 'settings.json'));
  try
    FSettings.Load;
  except
    on E: Exception do FLogger.Error('Falha ao carregar configurações: ' + E.Message);
  end;
  edtFolder.Text := FSettings.DownloadFolder;
  cbBitrate.Items.Text := '64 kbps'#13#10'128 kbps'#13#10'192 kbps'#13#10+
    '256 kbps'#13#10'320 kbps';
  cbBitrate.ItemIndex := cbBitrate.Items.IndexOf(IntToStr(FSettings.Bitrate) + ' kbps');
  if cbBitrate.ItemIndex < 0 then cbBitrate.ItemIndex := 2;
  FYtDlp := TYtDlpService.Create(TPath.Combine(FBasePath, 'bin\yt-dlp.exe'),
    TPath.Combine(FBasePath, 'bin\ffmpeg.exe'), FLogger);
  try
    FHistory := THistoryRepository.Create(TPath.Combine(FBasePath,
      'data\tube2mp3.db'));
    LoadHistory;
  except
    on E: Exception do
    begin
      FLogger.Error('Falha ao inicializar banco: ' + E.Message);
      MessageDlg('Não foi possível abrir o histórico: ' + E.Message,
        mtWarning, [mbOK], 0);
    end;
  end;
  SetBusy(False, 'Pronto');
end;

function TMainForm.FindProjectBase: string;
var
  Candidate, Parent: string;
  I: Integer;
begin
  Candidate := ExcludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  for I := 0 to 5 do
  begin
    if FileExists(TPath.Combine(Candidate, 'Tube2MP3.dproj')) then
      Exit(IncludeTrailingPathDelimiter(Candidate));
    Parent := ExtractFileDir(Candidate);
    if Parent = Candidate then Break;
    Candidate := Parent;
  end;
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

procedure TMainForm.StopWorker;
begin
  if Assigned(FWorker) then
  begin
    FYtDlp.Cancel;
    FWorker.WaitFor;
    FWorker.Free;
    FWorker := nil;
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  StopWorker;
  if Assigned(FSettings) then
  begin
    FSettings.DownloadFolder := edtFolder.Text;
    FSettings.Bitrate := SelectedBitrate;
    try
      FSettings.Save;
    except
      on E: Exception do FLogger.Error('Falha ao salvar configurações: ' + E.Message);
    end;
  end;
  FHistory.Free;
  FYtDlp.Free;
  FSettings.Free;
  FLogger.Free;
end;

procedure TMainForm.SetBusy(ABusy: Boolean; const AStatus: string);
begin
  btnAnalyze.Enabled := not ABusy;
  btnDownload.Enabled := (not ABusy) and (FVideo.Title <> '');
  btnCancel.Enabled := ABusy;
  btnFolder.Enabled := not ABusy;
  edtUrl.Enabled := not ABusy;
  lblStatus.Caption := AStatus;
end;

function TMainForm.SelectedBitrate: Integer;
begin
  Result := StrToIntDef(Copy(cbBitrate.Text, 1, Pos(' ', cbBitrate.Text) - 1), 192);
end;

function TMainForm.GetLocalFileSize(const AFileName: string): Int64;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    Result := Stream.Size;
  finally
    Stream.Free;
  end;
end;

procedure TMainForm.btnPasteClick(Sender: TObject);
begin
  edtUrl.Text := Clipboard.AsText;
end;

procedure TMainForm.btnAnalyzeClick(Sender: TObject);
var
  Url: string;
begin
  Url := Trim(edtUrl.Text);
  if not IsSupportedYouTubeUrl(Url) then
  begin
    MessageDlg('Cole uma URL válida do YouTube.', mtWarning, [mbOK], 0);
    Exit;
  end;
  StopWorker;
  FVideo := Default(TVideoInfo);
  imgThumbnail.Picture.Assign(nil);
  lblTitle.Caption := '-';
  lblChannel.Caption := '-';
  lblDuration.Caption := '-';
  progressBar.Position := 0;
  SetBusy(True, 'Analisando vídeo...');
  FWorker := TThread.CreateAnonymousThread(
    procedure
    var
      Info: TVideoInfo;
      ErrorText: string;
    begin
      try
        Info := FYtDlp.GetVideoInfo(Url);
        TThread.Queue(nil,
          procedure
          begin
            FVideo := Info;
            lblTitle.Caption := Info.Title;
            lblChannel.Caption := Info.Channel;
            lblDuration.Caption := FormatDuration(Info.Duration);
            SetBusy(False, 'Vídeo analisado');
            LoadThumbnail(Info.ThumbnailUrl);
          end);
      except
        on E: Exception do
        begin
          ErrorText := E.Message;
          FLogger.Error('Análise: ' + ErrorText);
          TThread.Queue(nil,
            procedure
            begin
              SetBusy(False, 'Falha na análise');
              MessageDlg(ErrorText, mtError, [mbOK], 0);
            end);
        end;
      end;
    end);
  FWorker.FreeOnTerminate := False;
  FWorker.Start;
end;

procedure TMainForm.LoadThumbnail(const AUrl: string);
begin
  if AUrl = '' then Exit;
  TTask.Run(
    procedure
    var
      Client: THTTPClient;
      Stream: TMemoryStream;
      Bytes: TBytes;
    begin
      Client := THTTPClient.Create;
      Stream := TMemoryStream.Create;
      try
        Client.Get(AUrl, Stream);
        SetLength(Bytes, Stream.Size);
        Stream.Position := 0;
        if Length(Bytes) > 0 then
          Stream.ReadBuffer(Bytes[0], Length(Bytes));
        TThread.Queue(nil,
          procedure
          var
            ImageStream: TBytesStream;
          begin
            ImageStream := TBytesStream.Create(Bytes);
            try
              try
                imgThumbnail.Picture.LoadFromStream(ImageStream);
              except
                imgThumbnail.Picture.Assign(nil);
              end;
            finally
              ImageStream.Free;
            end;
          end);
      except
        on E: Exception do FLogger.Error('Thumbnail: ' + E.Message);
      end;
      Stream.Free;
      Client.Free;
    end);
end;

procedure TMainForm.btnFolderClick(Sender: TObject);
var
  Folder: string;
begin
  Folder := edtFolder.Text;
  if SelectDirectory('Escolha a pasta de destino', '', Folder) then
    edtFolder.Text := Folder;
end;

procedure TMainForm.btnDownloadClick(Sender: TObject);
var
  Url, Folder: string;
  Bitrate: Integer;
  Video: TVideoInfo;
begin
  Url := Trim(edtUrl.Text);
  Folder := Trim(edtFolder.Text);
  Bitrate := SelectedBitrate;
  Video := FVideo;
  if (Video.Title = '') or not IsSupportedYouTubeUrl(Url) then Exit;
  if Folder = '' then
  begin
    MessageDlg('Escolha a pasta de destino.', mtWarning, [mbOK], 0);
    Exit;
  end;
  StopWorker;
  progressBar.Position := 0;
  lblSpeed.Caption := '';
  SetBusy(True, 'Preparando download...');
  FWorker := TThread.CreateAnonymousThread(
    procedure
    var
      FilePath, ErrorText: string;
      Item: THistoryItem;
    begin
      try
        FilePath := FYtDlp.DownloadAudio(Url, Folder, Bitrate,
          procedure(const P: TDownloadProgress)
          begin
            TThread.Queue(nil,
              procedure
              begin
                progressBar.Position := Round(P.Percent);
                lblStatus.Caption := Format('Baixando: %.1f%%', [P.Percent]);
                lblSpeed.Caption := P.Speed + '  Restante: ' + P.Eta;
              end);
          end);
        Item := Default(THistoryItem);
        Item.Title := Video.Title;
        Item.Url := Url;
        Item.Channel := Video.Channel;
        Item.Duration := Video.Duration;
        Item.Quality := Bitrate;
        Item.FilePath := FilePath;
        Item.Status := 'Concluído';
        Item.CreatedAt := Now;
        if FileExists(FilePath) then Item.Size := GetLocalFileSize(FilePath);
        TThread.Queue(nil,
          procedure
          begin
            if Assigned(FHistory) then FHistory.Add(Item);
            progressBar.Position := 100;
            SetBusy(False, 'Download concluído');
            LoadHistory;
          end);
      except
        on E: EAbort do
        begin
          TThread.Queue(nil,
            procedure
            begin
              SetBusy(False, 'Download cancelado');
            end);
        end;
        on E: Exception do
        begin
          ErrorText := E.Message;
          FLogger.Error('Download: ' + ErrorText);
          TThread.Queue(nil,
            procedure
            begin
              SetBusy(False, 'Falha no download');
              MessageDlg(ErrorText, mtError, [mbOK], 0);
            end);
        end;
      end;
    end);
  FWorker.FreeOnTerminate := False;
  FWorker.Start;
end;

procedure TMainForm.btnCancelClick(Sender: TObject);
begin
  FYtDlp.Cancel;
  lblStatus.Caption := 'Cancelando...';
  btnCancel.Enabled := False;
end;

procedure TMainForm.LoadHistory;
var
  Items: TList<THistoryItem>;
  H: THistoryItem;
  L: TListItem;
begin
  if not Assigned(FHistory) then Exit;
  Items := FHistory.GetAll;
  lvHistory.Items.BeginUpdate;
  try
    lvHistory.Items.Clear;
    for H in Items do
    begin
      L := lvHistory.Items.Add;
      L.Caption := H.Title;
      L.SubItems.Add(IntToStr(H.Quality) + ' kbps');
      L.SubItems.Add(FormatDateTime('dd/mm/yyyy hh:nn', H.CreatedAt));
      L.SubItems.Add(H.Status);
      L.SubItems.Add(H.FilePath);
    end;
  finally
    lvHistory.Items.EndUpdate;
    Items.Free;
  end;
end;

procedure TMainForm.btnOpenFolderClick(Sender: TObject);
begin
  if System.SysUtils.DirectoryExists(edtFolder.Text) then
    ShellExecute(Handle, 'open', PChar(edtFolder.Text), nil, nil, SW_SHOWNORMAL);
end;

procedure TMainForm.lvHistoryDblClick(Sender: TObject);
var
  Path: string;
begin
  if lvHistory.Selected = nil then Exit;
  Path := lvHistory.Selected.SubItems[3];
  if FileExists(Path) then
    ShellExecute(Handle, 'open', PChar('/select,"' + Path + '"'), nil, nil,
      SW_SHOWNORMAL);
end;

end.

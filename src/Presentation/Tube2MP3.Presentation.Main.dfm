object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Tube2MP3'
  ClientHeight = 700
  ClientWidth = 960
  Color = clBtnFace
  Constraints.MinHeight = 650
  Constraints.MinWidth = 850
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 17
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 960
    Height = 700
    Align = alClient
    BevelOuter = bvNone
    Padding.Left = 20
    Padding.Top = 16
    Padding.Right = 20
    Padding.Bottom = 16
    TabOrder = 0
    object lblUrl: TLabel
      Left = 20
      Top = 16
      Width = 166
      Height = 21
      Caption = 'Cole um link do YouTube'
      Font.Height = -16
      Font.Style = [fsBold]
      ParentFont = False
    end
    object imgThumbnail: TImage
      Left = 20
      Top = 92
      Width = 280
      Height = 158
      Center = True
      Proportional = True
      Stretch = True
    end
    object lblTitleCaption: TLabel
      Left = 320
      Top = 94
      Width = 35
      Height = 17
      Caption = 'Título'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblTitle: TLabel
      Left = 320
      Top = 116
      Width = 610
      Height = 42
      AutoSize = False
      Caption = '-'
      WordWrap = True
    end
    object lblChannelCaption: TLabel
      Left = 320
      Top = 168
      Width = 35
      Height = 17
      Caption = 'Canal'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblChannel: TLabel
      Left = 320
      Top = 190
      Width = 9
      Height = 17
      Caption = '-'
    end
    object lblDurationCaption: TLabel
      Left = 320
      Top = 218
      Width = 50
      Height = 17
      Caption = 'Duração'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblDuration: TLabel
      Left = 382
      Top = 218
      Width = 9
      Height = 17
      Caption = '-'
    end
    object lblFolderCaption: TLabel
      Left = 20
      Top = 270
      Width = 96
      Height = 17
      Caption = 'Pasta de destino'
    end
    object lblQuality: TLabel
      Left = 20
      Top = 326
      Width = 59
      Height = 17
      Caption = 'Qualidade'
    end
    object lblStatus: TLabel
      Left = 20
      Top = 414
      Width = 39
      Height = 17
      Caption = 'Pronto'
    end
    object lblSpeed: TLabel
      Left = 720
      Top = 414
      Width = 4
      Height = 17
      Alignment = taRightJustify
    end
    object lblHistory: TLabel
      Left = 20
      Top = 454
      Width = 58
      Height = 21
      Caption = 'Histórico'
      Font.Height = -16
      Font.Style = [fsBold]
      ParentFont = False
    end
    object edtUrl: TEdit
      Left = 20
      Top = 43
      Width = 716
      Height = 25
      TabOrder = 0
      TextHint = 'https://www.youtube.com/watch?v=...'
    end
    object btnPaste: TButton
      Left = 744
      Top = 41
      Width = 88
      Height = 29
      Caption = 'Colar'
      TabOrder = 1
      OnClick = btnPasteClick
    end
    object btnAnalyze: TButton
      Left = 840
      Top = 41
      Width = 90
      Height = 29
      Caption = 'Analisar'
      Default = True
      TabOrder = 2
      OnClick = btnAnalyzeClick
    end
    object edtFolder: TEdit
      Left = 20
      Top = 291
      Width = 812
      Height = 25
      TabOrder = 3
    end
    object btnFolder: TButton
      Left = 840
      Top = 289
      Width = 90
      Height = 29
      Caption = 'Escolher...'
      TabOrder = 4
      OnClick = btnFolderClick
    end
    object cbBitrate: TComboBox
      Left = 20
      Top = 347
      Width = 130
      Height = 25
      Style = csDropDownList
      TabOrder = 5
    end
    object btnDownload: TButton
      Left = 168
      Top = 344
      Width = 130
      Height = 31
      Caption = 'Baixar MP3'
      TabOrder = 6
      OnClick = btnDownloadClick
    end
    object btnCancel: TButton
      Left = 306
      Top = 344
      Width = 100
      Height = 31
      Caption = 'Cancelar'
      TabOrder = 7
      OnClick = btnCancelClick
    end
    object btnOpenFolder: TButton
      Left = 800
      Top = 344
      Width = 130
      Height = 31
      Caption = 'Abrir pasta'
      TabOrder = 8
      OnClick = btnOpenFolderClick
    end
    object progressBar: TProgressBar
      Left = 20
      Top = 390
      Width = 910
      Height = 16
      TabOrder = 9
    end
    object lvHistory: TListView
      Left = 20
      Top = 481
      Width = 910
      Height = 198
      Anchors = [akLeft, akTop, akRight, akBottom]
      Columns = <
        item
          Caption = 'Título'
          Width = 400
        end
        item
          Caption = 'Qualidade'
          Width = 90
        end
        item
          Caption = 'Data'
          Width = 130
        end
        item
          Caption = 'Status'
          Width = 90
        end
        item
          Caption = 'Arquivo'
          Width = 300
        end>
      ReadOnly = True
      RowSelect = True
      TabOrder = 10
      ViewStyle = vsReport
      OnDblClick = lvHistoryDblClick
    end
  end
end

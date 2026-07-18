unit Tube2MP3.Domain.Models;

interface

uses
  System.SysUtils;

type
  TVideoInfo = record
    Title: string;
    Channel: string;
    Duration: Integer;
    ThumbnailUrl: string;
    UploadDate: string;
    ViewCount: Int64;
  end;

  TDownloadProgress = record
    Percent: Double;
    Speed: string;
    Eta: string;
    Downloaded: string;
    Status: string;
  end;

  THistoryItem = record
    Id: Integer;
    Title: string;
    Url: string;
    Channel: string;
    Duration: Integer;
    Quality: Integer;
    Size: Int64;
    FilePath: string;
    ThumbnailPath: string;
    Status: string;
    CreatedAt: TDateTime;
  end;

implementation

end.

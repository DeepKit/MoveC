unit uEmbeddedImages;

{
  嵌入式图像数据单元

  作者：Augment Agent
  版本：1.1.0
  日期：2025-08-22
}

interface

uses
  System.SysUtils, System.IOUtils,
  uSQLiteDB; // Use the new, reliable database unit

type
  // 嵌入式图像管理器
  TEmbeddedImageManager = class
  private
    FDB: TSQLiteDatabase;
  public
    constructor Create;
    destructor Destroy; override;

    // 获取图像信息
    function GetImageData(const ImageKey: string): TBytes;
    function GetImageExtension(const ImageKey: string): string;
    function GetImageDisplayName(const ImageKey: string): string;

    // 实用方法
    function GetAvailableImages: TArray<string>;
    function HasImage(const ImageKey: string): Boolean;
  end;

implementation

{ TEmbeddedImageManager }

constructor TEmbeddedImageManager.Create;
var
  DBPath: string;
begin
  inherited Create;
  // The database is expected to be in the same directory as the executable
  DBPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'data.db');
  FDB := TSQLiteDatabase.Create(DBPath);
  FDB.Initialize;
end;

destructor TEmbeddedImageManager.Destroy;
begin
  if Assigned(FDB) then
    FDB.Free;
  inherited Destroy;
end;

function TEmbeddedImageManager.GetImageData(const ImageKey: string): TBytes;
begin
  // Load image data from the database
  if Assigned(FDB) then
    Result := FDB.LoadImageData(ImageKey)
  else
    SetLength(Result, 0);
end;

function TEmbeddedImageManager.GetImageExtension(const ImageKey: string): string;
var
  Key: string;
begin
  Key := UpperCase(ImageKey);

  if (Key = 'WECHAT') or (Key = 'ALIPAY') or (Key = 'BTC') or (Key = 'USDT_TP') then
    Result := '.png'
  else if (Key = 'USDT') or (Key = 'ABOUTME') then
    Result := '.jpg'
  else
    Result := '';
end;

function TEmbeddedImageManager.GetImageDisplayName(const ImageKey: string): string;
var
  Key: string;
begin
  Key := UpperCase(ImageKey);

  if Key = 'WECHAT' then
    Result := '微信二维码'
  else if Key = 'ALIPAY' then
    Result := '支付宝二维码'
  else if Key = 'BTC' then
    Result := 'BTC二维码'
  else if Key = 'USDT' then
    Result := 'USDT二维码'
  else if Key = 'ABOUTME' then
    Result := '开发者照片'
  else if Key = 'USDT_TP' then
    Result := 'TP钱包USDT二维码'
  else
    Result := ImageKey;
end;

function TEmbeddedImageManager.GetAvailableImages: TArray<string>;
begin
  // Updated to include all 6 images
  SetLength(Result, 6);
  Result[0] := 'WECHAT';
  Result[1] := 'ALIPAY';
  Result[2] := 'BTC';
  Result[3] := 'USDT';
  Result[4] := 'ABOUTME';
  Result[5] := 'USDT_TP';
end;

function TEmbeddedImageManager.HasImage(const ImageKey: string): Boolean;
var
  Key: string;
  AvailableImages: TArray<string>;
  AvailableImage: string;
begin
  Result := False;
  Key := UpperCase(ImageKey);

  AvailableImages := GetAvailableImages;
  for AvailableImage in AvailableImages do
  begin
    if Key = AvailableImage then
    begin
      Result := True;
      Break;
    end;
  end;
end;

end.

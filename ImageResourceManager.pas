unit ImageResourceManager;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.IniFiles,
  System.Hash, Vcl.Graphics, Vcl.Imaging.pngimage, Vcl.Imaging.jpeg,
  Winapi.Windows, BasicProtection;

type
  // 图像资源信息
  TImageResourceInfo = record
    ResourceName: string;      // 资源名称
    OriginalFileName: string;  // 原始文件名
    FileSize: Int64;          // 文件大小
    MD5Hash: string;          // MD5哈希值
    SHA256Hash: string;       // SHA256哈希值
    EncryptedData: TBytes;    // 加密后的图像数据
    CreatedAt: TDateTime;     // 创建时间
    LastVerified: TDateTime;  // 最后验证时间
  end;

  // 图像资源管理器
  TImageResourceManager = class
  private
    FDatabasePath: string;
    FResourcesIni: TMemIniFile;
    FIsInitialized: Boolean;
    
    function GetDatabasePath: string;
    function ResourcesFile: string;
    function CalculateMD5(const Data: TBytes): string;
    function CalculateSHA256(const Data: TBytes): string;
    function EncryptImageData(const Data: TBytes): TBytes;
    function DecryptImageData(const Data: TBytes): TBytes;
    function LoadImageFromFile(const FileName: string): TBytes;
    function SaveImageToDatabase(const ResourceName: string; const ImageData: TBytes; const OriginalFileName: string): Boolean;
    function LoadImageFromDatabase(const ResourceName: string): TBytes;
    function VerifyImageIntegrity(const ResourceName: string): Boolean;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 初始化
    function Initialize: Boolean;
    procedure Finalize;
    
    // 图像资源管理
    function ImportImageFromFile(const FileName, ResourceName: string): Boolean;
    function ExportImageToStream(const ResourceName: string; Stream: TMemoryStream): Boolean;
    function GetImageAsBitmap(const ResourceName: string): TBitmap;
    function GetImageInfo(const ResourceName: string): TImageResourceInfo;
    function GetAllImageNames: TArray<string>;
    
    // 安全验证
    function VerifyAllImages: Boolean;
    function GetImageCount: Integer;
    function GetTotalSize: Int64;
    
    // 防篡改检查
    function CheckIntegrity: Boolean;
    function RepairCorruptedImages: Integer;
    
    property IsInitialized: Boolean read FIsInitialized;
  end;

implementation

uses
  System.NetEncoding;

constructor TImageResourceManager.Create;
begin
  inherited;
  FDatabasePath := '';
  FResourcesIni := nil;
  FIsInitialized := False;
end;

destructor TImageResourceManager.Destroy;
begin
  Finalize;
  inherited;
end;

function TImageResourceManager.GetDatabasePath: string;
var
  AppDataPath: string;
begin
  AppDataPath := GetEnvironmentVariable('LOCALAPPDATA');
  if AppDataPath = '' then
    AppDataPath := TPath.Combine(GetEnvironmentVariable('USERPROFILE'), 'AppData\Local');
  Result := TPath.Combine(AppDataPath, 'DiskCleanup');
end;

function TImageResourceManager.ResourcesFile: string;
begin
  Result := TPath.Combine(FDatabasePath, 'image_resources.ini');
end;

function TImageResourceManager.Initialize: Boolean;
begin
  Result := False;
  try
    if FIsInitialized then
      Exit(True);
      
    FDatabasePath := GetDatabasePath;
    
    // 创建数据目录
    if not TDirectory.Exists(FDatabasePath) then
      TDirectory.CreateDirectory(FDatabasePath);
    
    // 初始化资源文件
    FResourcesIni := TMemIniFile.Create(ResourcesFile, TEncoding.UTF8);
    
    FIsInitialized := True;
    Result := True;
    
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('Image resource manager initialization failed: ' + E.Message));
      Finalize;
    end;
  end;
end;

procedure TImageResourceManager.Finalize;
begin
  try
    if Assigned(FResourcesIni) then
    begin
      FResourcesIni.UpdateFile;
      FResourcesIni.Free;
      FResourcesIni := nil;
    end;
  except
    // 忽略错误
  end;
  
  FIsInitialized := False;
end;

function TImageResourceManager.CalculateMD5(const Data: TBytes): string;
begin
  Result := THashMD5.GetHashString(TEncoding.UTF8.GetString(Data));
end;

function TImageResourceManager.CalculateSHA256(const Data: TBytes): string;
begin
  Result := THashSHA2.GetHashString(TEncoding.UTF8.GetString(Data), SHA256);
end;

function TImageResourceManager.EncryptImageData(const Data: TBytes): TBytes;
begin
  // 使用BasicProtection中的加密方法
  Result := TBasicProtection.EncryptData(Data);
end;

function TImageResourceManager.DecryptImageData(const Data: TBytes): TBytes;
begin
  // 使用BasicProtection中的解密方法
  Result := TBasicProtection.DecryptData(Data);
end;

function TImageResourceManager.LoadImageFromFile(const FileName: string): TBytes;
var
  FileStream: TFileStream;
begin
  SetLength(Result, 0);
  
  if not TFile.Exists(FileName) then
    Exit;
    
  try
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(Result, FileStream.Size);
      FileStream.ReadBuffer(Result[0], FileStream.Size);
    finally
      FileStream.Free;
    end;
  except
    SetLength(Result, 0);
  end;
end;

function TImageResourceManager.SaveImageToDatabase(const ResourceName: string; const ImageData: TBytes; const OriginalFileName: string): Boolean;
var
  EncryptedData: TBytes;
  MD5Hash, SHA256Hash: string;
  EncodedData: string;
  DataFile: string;
begin
  Result := False;
  
  if not FIsInitialized or not Assigned(FResourcesIni) then
    Exit;
    
  try
    // 计算哈希值
    MD5Hash := CalculateMD5(ImageData);
    SHA256Hash := CalculateSHA256(ImageData);
    
    // 加密图像数据
    EncryptedData := EncryptImageData(ImageData);
    
    // Base64编码
    EncodedData := TNetEncoding.Base64.EncodeBytesToString(EncryptedData);
    
    // 保存到数据文件
    DataFile := TPath.Combine(FDatabasePath, ResourceName + '.dat');
    TFile.WriteAllText(DataFile, EncodedData, TEncoding.UTF8);
    
    // 保存元数据到INI文件
    FResourcesIni.WriteString(ResourceName, 'original_filename', OriginalFileName);
    FResourcesIni.WriteInt64(ResourceName, 'file_size', Length(ImageData));
    FResourcesIni.WriteString(ResourceName, 'md5_hash', MD5Hash);
    FResourcesIni.WriteString(ResourceName, 'sha256_hash', SHA256Hash);
    FResourcesIni.WriteString(ResourceName, 'data_file', DataFile);
    FResourcesIni.WriteDateTime(ResourceName, 'created_at', Now);
    FResourcesIni.WriteDateTime(ResourceName, 'last_verified', Now);
    
    FResourcesIni.UpdateFile;
    
    Result := True;
    
  except
    on E: Exception do
      OutputDebugString(PChar('Save image to database failed: ' + E.Message));
  end;
end;

function TImageResourceManager.LoadImageFromDatabase(const ResourceName: string): TBytes;
var
  DataFile, EncodedData: string;
  EncryptedData: TBytes;
begin
  SetLength(Result, 0);
  
  if not FIsInitialized or not Assigned(FResourcesIni) then
    Exit;
    
  try
    DataFile := FResourcesIni.ReadString(ResourceName, 'data_file', '');
    if (DataFile = '') or not TFile.Exists(DataFile) then
      Exit;
      
    // 读取Base64编码的数据
    EncodedData := TFile.ReadAllText(DataFile, TEncoding.UTF8);
    
    // Base64解码
    EncryptedData := TNetEncoding.Base64.DecodeStringToBytes(EncodedData);
    
    // 解密图像数据
    Result := DecryptImageData(EncryptedData);
    
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('Load image from database failed: ' + E.Message));
      SetLength(Result, 0);
    end;
  end;
end;

function TImageResourceManager.ImportImageFromFile(const FileName, ResourceName: string): Boolean;
var
  ImageData: TBytes;
begin
  Result := False;

  if not TFile.Exists(FileName) then
  begin
    OutputDebugString(PChar('Image file not found: ' + FileName));
    Exit;
  end;

  try
    ImageData := LoadImageFromFile(FileName);
    if Length(ImageData) = 0 then
    begin
      OutputDebugString(PChar('Failed to load image data from: ' + FileName));
      Exit;
    end;

    Result := SaveImageToDatabase(ResourceName, ImageData, ExtractFileName(FileName));

    if Result then
      OutputDebugString(PChar('Successfully imported image: ' + ResourceName + ' from ' + FileName))
    else
      OutputDebugString(PChar('Failed to save image to database: ' + ResourceName));

  except
    on E: Exception do
      OutputDebugString(PChar('Import image failed: ' + E.Message));
  end;
end;

function TImageResourceManager.ExportImageToStream(const ResourceName: string; Stream: TMemoryStream): Boolean;
var
  ImageData: TBytes;
begin
  Result := False;

  if not Assigned(Stream) then
    Exit;

  try
    ImageData := LoadImageFromDatabase(ResourceName);
    if Length(ImageData) = 0 then
      Exit;

    Stream.Clear;
    Stream.WriteBuffer(ImageData[0], Length(ImageData));
    Stream.Position := 0;

    Result := True;

  except
    on E: Exception do
      OutputDebugString(PChar('Export image to stream failed: ' + E.Message));
  end;
end;

function TImageResourceManager.GetImageAsBitmap(const ResourceName: string): TBitmap;
var
  ImageData: TBytes;
  Stream: TMemoryStream;
  PNG: TPngImage;
  JPEG: TJPEGImage;
  FileExt: string;
begin
  Result := nil;

  try
    ImageData := LoadImageFromDatabase(ResourceName);
    if Length(ImageData) = 0 then
      Exit;

    Stream := TMemoryStream.Create;
    try
      Stream.WriteBuffer(ImageData[0], Length(ImageData));
      Stream.Position := 0;

      // 根据原始文件扩展名确定图像格式
      FileExt := LowerCase(ExtractFileExt(FResourcesIni.ReadString(ResourceName, 'original_filename', '')));

      Result := TBitmap.Create;

      if FileExt = '.png' then
      begin
        PNG := TPngImage.Create;
        try
          PNG.LoadFromStream(Stream);
          Result.Assign(PNG);
        finally
          PNG.Free;
        end;
      end
      else if (FileExt = '.jpg') or (FileExt = '.jpeg') then
      begin
        JPEG := TJPEGImage.Create;
        try
          JPEG.LoadFromStream(Stream);
          Result.Assign(JPEG);
        finally
          JPEG.Free;
        end;
      end
      else
      begin
        // 尝试直接加载为位图
        Stream.Position := 0;
        Result.LoadFromStream(Stream);
      end;

    finally
      Stream.Free;
    end;

  except
    on E: Exception do
    begin
      OutputDebugString(PChar('Get image as bitmap failed: ' + E.Message));
      if Assigned(Result) then
      begin
        FreeAndNil(Result);
      end;
    end;
  end;
end;

function TImageResourceManager.GetImageInfo(const ResourceName: string): TImageResourceInfo;
begin
  FillChar(Result, SizeOf(Result), 0);

  if not FIsInitialized or not Assigned(FResourcesIni) then
    Exit;

  try
    Result.ResourceName := ResourceName;
    Result.OriginalFileName := FResourcesIni.ReadString(ResourceName, 'original_filename', '');
    Result.FileSize := FResourcesIni.ReadInt64(ResourceName, 'file_size', 0);
    Result.MD5Hash := FResourcesIni.ReadString(ResourceName, 'md5_hash', '');
    Result.SHA256Hash := FResourcesIni.ReadString(ResourceName, 'sha256_hash', '');
    Result.CreatedAt := FResourcesIni.ReadDateTime(ResourceName, 'created_at', 0);
    Result.LastVerified := FResourcesIni.ReadDateTime(ResourceName, 'last_verified', 0);
  except
    on E: Exception do
      OutputDebugString(PChar('Get image info failed: ' + E.Message));
  end;
end;

function TImageResourceManager.GetAllImageNames: TArray<string>;
var
  Sections: TStringList;
  I: Integer;
begin
  SetLength(Result, 0);

  if not FIsInitialized or not Assigned(FResourcesIni) then
    Exit;

  Sections := TStringList.Create;
  try
    FResourcesIni.ReadSections(Sections);
    SetLength(Result, Sections.Count);

    for I := 0 to Sections.Count - 1 do
      Result[I] := Sections[I];

  finally
    Sections.Free;
  end;
end;

function TImageResourceManager.VerifyImageIntegrity(const ResourceName: string): Boolean;
var
  ImageData: TBytes;
  CurrentMD5, CurrentSHA256: string;
  StoredMD5, StoredSHA256: string;
begin
  Result := False;

  try
    ImageData := LoadImageFromDatabase(ResourceName);
    if Length(ImageData) = 0 then
      Exit;

    // 计算当前哈希值
    CurrentMD5 := CalculateMD5(ImageData);
    CurrentSHA256 := CalculateSHA256(ImageData);

    // 获取存储的哈希值
    StoredMD5 := FResourcesIni.ReadString(ResourceName, 'md5_hash', '');
    StoredSHA256 := FResourcesIni.ReadString(ResourceName, 'sha256_hash', '');

    // 验证完整性
    Result := (CurrentMD5 = StoredMD5) and (CurrentSHA256 = StoredSHA256);

    if Result then
    begin
      // 更新最后验证时间
      FResourcesIni.WriteDateTime(ResourceName, 'last_verified', Now);
      FResourcesIni.UpdateFile;
    end;

  except
    on E: Exception do
      OutputDebugString(PChar('Verify image integrity failed: ' + E.Message));
  end;
end;

function TImageResourceManager.VerifyAllImages: Boolean;
var
  ImageNames: TArray<string>;
  I: Integer;
  AllValid: Boolean;
begin
  AllValid := True;

  try
    ImageNames := GetAllImageNames;

    for I := 0 to High(ImageNames) do
    begin
      if not VerifyImageIntegrity(ImageNames[I]) then
      begin
        AllValid := False;
        OutputDebugString(PChar('Image integrity check failed: ' + ImageNames[I]));
      end;
    end;

  except
    on E: Exception do
    begin
      OutputDebugString(PChar('Verify all images failed: ' + E.Message));
      AllValid := False;
    end;
  end;

  Result := AllValid;
end;

function TImageResourceManager.GetImageCount: Integer;
begin
  Result := Length(GetAllImageNames);
end;

function TImageResourceManager.GetTotalSize: Int64;
var
  ImageNames: TArray<string>;
  I: Integer;
begin
  Result := 0;

  try
    ImageNames := GetAllImageNames;

    for I := 0 to High(ImageNames) do
      Result := Result + FResourcesIni.ReadInt64(ImageNames[I], 'file_size', 0);

  except
    on E: Exception do
      OutputDebugString(PChar('Get total size failed: ' + E.Message));
  end;
end;

function TImageResourceManager.CheckIntegrity: Boolean;
begin
  Result := VerifyAllImages;
end;

function TImageResourceManager.RepairCorruptedImages: Integer;
var
  ImageNames: TArray<string>;
  I: Integer;
  RepairedCount: Integer;
begin
  RepairedCount := 0;

  try
    ImageNames := GetAllImageNames;

    for I := 0 to High(ImageNames) do
    begin
      if not VerifyImageIntegrity(ImageNames[I]) then
      begin
        OutputDebugString(PChar('Found corrupted image: ' + ImageNames[I]));
        // 这里可以实现修复逻辑，比如从备份恢复
        // 目前只是记录损坏的图像
      end;
    end;

  except
    on E: Exception do
      OutputDebugString(PChar('Repair corrupted images failed: ' + E.Message));
  end;

  Result := RepairedCount;
end;

end.

program SimpleImageImport;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.Hash,
  System.IniFiles,
  System.NetEncoding,
  BasicProtection;

type
  // 简化的图像资源管理器
  TSimpleImageManager = class
  private
    FDatabasePath: string;
    FResourcesIni: TMemIniFile;
    
    function GetDatabasePath: string;
    function ResourcesFile: string;
    function CalculateMD5(const Data: TBytes): string;
    function CalculateSHA256(const Data: TBytes): string;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    function Initialize: Boolean;
    procedure Finalize;
    function ImportImageFromFile(const FileName, ResourceName: string): Boolean;
    function VerifyImageIntegrity(const ResourceName: string): Boolean;
    function GetAllImageNames: TArray<string>;
    function GetImageCount: Integer;
    function GetTotalSize: Int64;
  end;

constructor TSimpleImageManager.Create;
begin
  inherited;
  FDatabasePath := '';
  FResourcesIni := nil;
end;

destructor TSimpleImageManager.Destroy;
begin
  Finalize;
  inherited;
end;

function TSimpleImageManager.GetDatabasePath: string;
var
  AppDataPath: string;
begin
  AppDataPath := GetEnvironmentVariable('LOCALAPPDATA');
  if AppDataPath = '' then
    AppDataPath := TPath.Combine(GetEnvironmentVariable('USERPROFILE'), 'AppData\Local');
  Result := TPath.Combine(AppDataPath, 'DiskCleanup');
end;

function TSimpleImageManager.ResourcesFile: string;
begin
  Result := TPath.Combine(FDatabasePath, 'image_resources.ini');
end;

function TSimpleImageManager.Initialize: Boolean;
begin
  Result := False;
  try
    FDatabasePath := GetDatabasePath;
    
    if not TDirectory.Exists(FDatabasePath) then
      TDirectory.CreateDirectory(FDatabasePath);
    
    FResourcesIni := TMemIniFile.Create(ResourcesFile, TEncoding.UTF8);
    Result := True;
    
  except
    on E: Exception do
      Writeln('Initialization failed: ' + E.Message);
  end;
end;

procedure TSimpleImageManager.Finalize;
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
end;

function TSimpleImageManager.CalculateMD5(const Data: TBytes): string;
var
  Hash: THashMD5;
begin
  Hash := THashMD5.Create;
  Hash.Update(Data);
  Result := Hash.HashAsString;
end;

function TSimpleImageManager.CalculateSHA256(const Data: TBytes): string;
var
  Hash: THashSHA2;
begin
  Hash := THashSHA2.Create(SHA256);
  Hash.Update(Data);
  Result := Hash.HashAsString;
end;

function TSimpleImageManager.ImportImageFromFile(const FileName, ResourceName: string): Boolean;
var
  ImageData, EncryptedData: TBytes;
  MD5Hash, SHA256Hash, EncodedData: string;
  DataFile: string;
  FileStream: TFileStream;
begin
  Result := False;
  
  if not TFile.Exists(FileName) then
  begin
    Writeln('File not found: ' + FileName);
    Exit;
  end;
  
  try
    // 读取文件数据
    FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(ImageData, FileStream.Size);
      FileStream.ReadBuffer(ImageData[0], FileStream.Size);
    finally
      FileStream.Free;
    end;
    
    // 计算哈希值
    MD5Hash := CalculateMD5(ImageData);
    SHA256Hash := CalculateSHA256(ImageData);
    
    // 加密数据
    EncryptedData := TBasicProtection.EncryptData(ImageData);
    
    // Base64编码
    EncodedData := TNetEncoding.Base64.EncodeBytesToString(EncryptedData);
    
    // 保存到数据文件
    DataFile := TPath.Combine(FDatabasePath, ResourceName + '.dat');
    TFile.WriteAllText(DataFile, EncodedData, TEncoding.UTF8);
    
    // 保存元数据
    FResourcesIni.WriteString(ResourceName, 'original_filename', ExtractFileName(FileName));
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
      Writeln('Import failed: ' + E.Message);
  end;
end;

function TSimpleImageManager.VerifyImageIntegrity(const ResourceName: string): Boolean;
var
  DataFile, EncodedData: string;
  EncryptedData, ImageData: TBytes;
  CurrentMD5, CurrentSHA256, StoredMD5, StoredSHA256: string;
begin
  Result := False;
  
  try
    DataFile := FResourcesIni.ReadString(ResourceName, 'data_file', '');
    if (DataFile = '') or not TFile.Exists(DataFile) then
      Exit;
      
    // 读取并解密数据
    EncodedData := TFile.ReadAllText(DataFile, TEncoding.UTF8);
    EncryptedData := TNetEncoding.Base64.DecodeStringToBytes(EncodedData);
    ImageData := TBasicProtection.DecryptData(EncryptedData);
    
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
      FResourcesIni.WriteDateTime(ResourceName, 'last_verified', Now);
      FResourcesIni.UpdateFile;
    end;
    
  except
    on E: Exception do
      Writeln('Verify failed: ' + E.Message);
  end;
end;

function TSimpleImageManager.GetAllImageNames: TArray<string>;
var
  Sections: TStringList;
  I: Integer;
begin
  SetLength(Result, 0);
  
  if not Assigned(FResourcesIni) then
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

function TSimpleImageManager.GetImageCount: Integer;
begin
  Result := Length(GetAllImageNames);
end;

function TSimpleImageManager.GetTotalSize: Int64;
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
    // 忽略错误
  end;
end;

// 主程序
procedure ImportAllImages;
var
  ImageManager: TSimpleImageManager;
  PicsPath: string;
  ImageFiles: TArray<string>;
  I: Integer;
  FileName, ResourceName, FileExt: string;
  SuccessCount, FailCount: Integer;
begin
  Writeln('=== Simple Image Import with Protection ===');
  Writeln('');
  
  PicsPath := TPath.Combine(GetCurrentDir, 'pics');
  
  if not TDirectory.Exists(PicsPath) then
  begin
    Writeln('Error: pics directory not found: ' + PicsPath);
    Exit;
  end;
  
  ImageManager := TSimpleImageManager.Create;
  try
    if ImageManager.Initialize then
    begin
      Writeln('Image manager initialized');
      Writeln('Scanning: ' + PicsPath);
      Writeln('');
      
      ImageFiles := TDirectory.GetFiles(PicsPath, '*.*', TSearchOption.soTopDirectoryOnly);
      
      SuccessCount := 0;
      FailCount := 0;
      
      for I := 0 to High(ImageFiles) do
      begin
        FileName := ImageFiles[I];
        FileExt := LowerCase(ExtractFileExt(FileName));
        
        if (FileExt = '.png') or (FileExt = '.jpg') or (FileExt = '.jpeg') or 
           (FileExt = '.bmp') or (FileExt = '.gif') then
        begin
          ResourceName := ChangeFileExt(ExtractFileName(FileName), '');
          
          Write(Format('Importing: %-20s -> %-15s ', [ExtractFileName(FileName), ResourceName]));
          
          if ImageManager.ImportImageFromFile(FileName, ResourceName) then
          begin
            Inc(SuccessCount);
            Writeln('✓ Success');
          end
          else
          begin
            Inc(FailCount);
            Writeln('✗ Failed');
          end;
        end;
      end;
      
      Writeln('');
      Writeln('=== Import Summary ===');
      Writeln(Format('Successfully imported: %d', [SuccessCount]));
      Writeln(Format('Failed imports: %d', [FailCount]));
      Writeln(Format('Total images in database: %d', [ImageManager.GetImageCount]));
      Writeln(Format('Total database size: %d bytes', [ImageManager.GetTotalSize]));
      
    end
    else
      Writeln('Failed to initialize image manager');
  finally
    ImageManager.Free;
  end;
end;

procedure VerifyAllImages;
var
  ImageManager: TSimpleImageManager;
  ImageNames: TArray<string>;
  I: Integer;
  AllValid: Boolean;
begin
  Writeln('');
  Writeln('=== Verifying Image Integrity ===');
  Writeln('');
  
  ImageManager := TSimpleImageManager.Create;
  try
    if ImageManager.Initialize then
    begin
      ImageNames := ImageManager.GetAllImageNames;
      AllValid := True;
      
      for I := 0 to High(ImageNames) do
      begin
        Write(Format('%2d. %-20s ', [I + 1, ImageNames[I]]));
        
        if ImageManager.VerifyImageIntegrity(ImageNames[I]) then
          Writeln('✓ VALID')
        else
        begin
          Writeln('✗ CORRUPTED');
          AllValid := False;
        end;
      end;
      
      Writeln('');
      if AllValid then
        Writeln('🛡️  All images passed integrity check')
      else
        Writeln('⚠️  WARNING: Some images failed integrity check!');
        
    end;
  finally
    ImageManager.Free;
  end;
end;

begin
  try
    Writeln('SIMPLE IMAGE IMPORT & PROTECTION');
    Writeln('================================');
    Writeln('');
    
    ImportAllImages;
    VerifyAllImages;
    
    Writeln('');
    Writeln('Images are now securely stored with anti-tampering protection!');
    
  except
    on E: Exception do
      Writeln('Error: ' + E.Message);
  end;
  
  Writeln('');
  Writeln('Press Enter to exit...');
  Readln;
end.

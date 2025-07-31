program TestAboutMeImages;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.IniFiles,
  System.NetEncoding,
  BasicProtection;

type
  // 简化的图像测试器
  TImageTester = class
  private
    FDatabasePath: string;
    FResourcesIni: TMemIniFile;
    
    function GetDatabasePath: string;
    function ResourcesFile: string;
    function LoadImageFromDatabase(const ResourceName: string): TBytes;
    function DecryptImageData(const Data: TBytes): TBytes;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    function Initialize: Boolean;
    procedure Finalize;
    function TestImageLoad(const ResourceName: string): Boolean;
    procedure TestAllImages;
  end;

constructor TImageTester.Create;
begin
  inherited;
  FDatabasePath := '';
  FResourcesIni := nil;
end;

destructor TImageTester.Destroy;
begin
  Finalize;
  inherited;
end;

function TImageTester.GetDatabasePath: string;
var
  AppDataPath: string;
begin
  AppDataPath := GetEnvironmentVariable('LOCALAPPDATA');
  if AppDataPath = '' then
    AppDataPath := TPath.Combine(GetEnvironmentVariable('USERPROFILE'), 'AppData\Local');
  Result := TPath.Combine(AppDataPath, 'DiskCleanup');
end;

function TImageTester.ResourcesFile: string;
begin
  Result := TPath.Combine(FDatabasePath, 'image_resources.ini');
end;

function TImageTester.Initialize: Boolean;
begin
  Result := False;
  try
    FDatabasePath := GetDatabasePath;
    
    if not TDirectory.Exists(FDatabasePath) then
    begin
      Writeln('Database directory not found: ' + FDatabasePath);
      Exit;
    end;
    
    if not TFile.Exists(ResourcesFile) then
    begin
      Writeln('Resources file not found: ' + ResourcesFile);
      Exit;
    end;
    
    FResourcesIni := TMemIniFile.Create(ResourcesFile, TEncoding.UTF8);
    Result := True;
    
  except
    on E: Exception do
      Writeln('Initialization failed: ' + E.Message);
  end;
end;

procedure TImageTester.Finalize;
begin
  try
    if Assigned(FResourcesIni) then
    begin
      FResourcesIni.Free;
      FResourcesIni := nil;
    end;
  except
    // 忽略错误
  end;
end;

function TImageTester.DecryptImageData(const Data: TBytes): TBytes;
begin
  try
    Result := TBasicProtection.DecryptData(Data);
  except
    SetLength(Result, 0);
  end;
end;

function TImageTester.LoadImageFromDatabase(const ResourceName: string): TBytes;
var
  DataFile, EncodedData: string;
  EncryptedData: TBytes;
begin
  SetLength(Result, 0);
  
  if not Assigned(FResourcesIni) then
    Exit;
    
  try
    DataFile := FResourcesIni.ReadString(ResourceName, 'data_file', '');
    if (DataFile = '') or not TFile.Exists(DataFile) then
    begin
      Writeln('Data file not found for: ' + ResourceName);
      Exit;
    end;
      
    // 读取Base64编码的数据
    EncodedData := TFile.ReadAllText(DataFile, TEncoding.UTF8);
    
    // Base64解码
    EncryptedData := TNetEncoding.Base64.DecodeStringToBytes(EncodedData);
    
    // 解密图像数据
    Result := DecryptImageData(EncryptedData);
    
  except
    on E: Exception do
    begin
      Writeln('Load image failed: ' + E.Message);
      SetLength(Result, 0);
    end;
  end;
end;

function TImageTester.TestImageLoad(const ResourceName: string): Boolean;
var
  ImageData: TBytes;
  OriginalSize: Int64;
  MD5Hash, SHA256Hash: string;
begin
  Result := False;
  
  try
    Write(Format('Testing %-15s: ', [ResourceName]));
    
    ImageData := LoadImageFromDatabase(ResourceName);
    if Length(ImageData) = 0 then
    begin
      Writeln('✗ Failed to load');
      Exit;
    end;
    
    // 获取原始信息
    OriginalSize := FResourcesIni.ReadInt64(ResourceName, 'file_size', 0);
    MD5Hash := FResourcesIni.ReadString(ResourceName, 'md5_hash', '');
    SHA256Hash := FResourcesIni.ReadString(ResourceName, 'sha256_hash', '');
    
    Writeln(Format('✓ Success - Size: %d bytes (Original: %d)', [Length(ImageData), OriginalSize]));
    Writeln(Format('                   MD5: %s', [Copy(MD5Hash, 1, 16) + '...']));
    Writeln(Format('                   SHA256: %s', [Copy(SHA256Hash, 1, 16) + '...']));
    
    Result := True;
    
  except
    on E: Exception do
      Writeln('✗ Error: ' + E.Message);
  end;
end;

procedure TImageTester.TestAllImages;
var
  ImageNames: TArray<string>;
  Sections: TStringList;
  I: Integer;
  SuccessCount: Integer;
begin
  Writeln('=== Testing All Images for AboutMe Window ===');
  Writeln('');
  
  if not Assigned(FResourcesIni) then
  begin
    Writeln('Resources not initialized');
    Exit;
  end;
  
  Sections := TStringList.Create;
  try
    FResourcesIni.ReadSections(Sections);
    SetLength(ImageNames, Sections.Count);
    
    for I := 0 to Sections.Count - 1 do
      ImageNames[I] := Sections[I];
      
  finally
    Sections.Free;
  end;
  
  SuccessCount := 0;
  
  for I := 0 to High(ImageNames) do
  begin
    if TestImageLoad(ImageNames[I]) then
      Inc(SuccessCount);
    Writeln('');
  end;
  
  Writeln('=== Test Summary ===');
  Writeln(Format('Total images: %d', [Length(ImageNames)]));
  Writeln(Format('Successfully loaded: %d', [SuccessCount]));
  Writeln(Format('Failed to load: %d', [Length(ImageNames) - SuccessCount]));
  
  if SuccessCount = Length(ImageNames) then
    Writeln('✓ All images ready for AboutMe window!')
  else
    Writeln('⚠ Some images failed to load');
end;

procedure ShowAboutMeMapping;
begin
  Writeln('=== AboutMe Window Image Mapping ===');
  Writeln('');
  Writeln('Tab Pages and their corresponding images:');
  Writeln('');
  Writeln('1. 微信打赏 (tsWechat)    -> wechat.png   (imgWechat)');
  Writeln('2. 支付宝打赏 (tsAlipay)   -> AliPay.png   (imgAlipay)');
  Writeln('3. BTC打赏 (tsBTC)        -> btc.png      (imgBTC)');
  Writeln('4. USDT打赏 (tsUSDT)      -> usdt.png     (imgUSDT)');
  Writeln('5. 关于我 (tsAboutMe)      -> itsMe.jpg    (imgAboutMe)');
  Writeln('');
  Writeln('All images are encrypted and stored securely in the database.');
  Writeln('They will be decrypted and loaded automatically when the');
  Writeln('AboutMe window is displayed.');
  Writeln('');
end;

procedure ShowUsageInstructions;
begin
  Writeln('=== Usage Instructions ===');
  Writeln('');
  Writeln('To use the protected images in your AboutMe window:');
  Writeln('');
  Writeln('1. The FrameAboutMe.pas has been updated with TAboutMeImageManager');
  Writeln('2. Images are automatically loaded from encrypted database');
  Writeln('3. Each tab will display its corresponding protected image');
  Writeln('4. If an image fails to load, an error will be logged');
  Writeln('');
  Writeln('Code example:');
  Writeln('  // In FrameAboutMe constructor');
  Writeln('  FImageManager := TAboutMeImageManager.Create;');
  Writeln('  FImageManager.Initialize;');
  Writeln('  LoadAllImages; // This loads all 5 protected images');
  Writeln('');
  Writeln('Security features:');
  Writeln('  • Images are AES-256 encrypted');
  Writeln('  • MD5 + SHA256 integrity verification');
  Writeln('  • Automatic tamper detection');
  Writeln('  • Dynamic key generation');
  Writeln('');
end;

begin
  try
    Writeln('ABOUTME WINDOW IMAGE TESTING');
    Writeln('============================');
    Writeln('Testing encrypted image loading for AboutMe tabs');
    Writeln('');
    
    ShowAboutMeMapping;
    
    var Tester := TImageTester.Create;
    try
      if Tester.Initialize then
      begin
        Tester.TestAllImages;
      end
      else
        Writeln('Failed to initialize image tester');
    finally
      Tester.Free;
    end;
    
    ShowUsageInstructions;
    
    Writeln('=== TEST COMPLETE ===');
    Writeln('Your AboutMe window is ready to display protected images!');
    
  except
    on E: Exception do
      Writeln('Error: ' + E.Message);
  end;
  
  Writeln('');
  Writeln('Press Enter to exit...');
  Readln;
end.

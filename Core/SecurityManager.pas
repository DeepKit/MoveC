unit SecurityManager;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Win.Registry, Winapi.WinSock, ISecurityManager2, BasicProtection,
  ConfigManager;

type
  // 安全管理器具体实现
  TSecurityManager = class(TInterfacedObject, ISecurityManager)
  private
    FConfigManager: TConfigManager;

    // 开发模式标志（生产环境应设为False）
    const DEVELOPMENT_MODE = True;
    
    // 内部方法
    function GetCPUInfo: string;
    function GetDiskSerialNumber: string;
    function GetMACAddress: string;
    function GetBIOSInfo: string;
    function GetMotherboardInfo: string;
    function GetSystemFingerprint: string;
    function FormatMachineCode(const ARawCode: string): string;
    function LoadStoredHash: string;
    procedure SaveExecutableHash;
    function CheckExecutableIntegrity: Boolean;
    function CheckConfigIntegrity: Boolean;
    
  public
    constructor Create(AConfigManager: TConfigManager = nil);
    destructor Destroy; override;
    
    // ISecurityManager 接口实现
    function PerformSelfCheck: Boolean;
    function ValidateFileIntegrity(const AFilePath: string): Boolean;
    function EncryptSensitiveData(const AData: string): string;
    function DecryptSensitiveData(const AEncryptedData: string): string;
    function GenerateMachineFingerprint: string;
    function IsRunningAsAdmin: Boolean;
    
    // 公共方法（用于测试和调试）
    function GetCPUInfoPublic: string;
    function GetDiskSerialNumberPublic: string;
    function GetMACAddressPublic: string;
    function GetBIOSInfoPublic: string;
    function GetMotherboardInfoPublic: string;
    function FormatMachineCodePublic(const ARawCode: string): string;
  end;

implementation

uses
  Vcl.Forms, Winapi.ShellAPI;

constructor TSecurityManager.Create(AConfigManager: TConfigManager);
begin
  inherited Create;
  
  if Assigned(AConfigManager) then
    FConfigManager := AConfigManager
  else
    FConfigManager := TConfigManager.Create;
end;

destructor TSecurityManager.Destroy;
begin
  if Assigned(FConfigManager) then
    FConfigManager.Free;
  inherited;
end;

// 获取CPU信息
function TSecurityManager.GetCPUInfo: string;
var
  Reg: TRegistry;
begin
  Result := '';
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey('HARDWARE\DESCRIPTION\System\CentralProcessor\0', False) then
    begin
      if Reg.ValueExists('ProcessorNameString') then
        Result := Reg.ReadString('ProcessorNameString')
      else if Reg.ValueExists('Identifier') then
        Result := Reg.ReadString('Identifier');
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;

  // 如果无法获取，使用备用方法
  if Result = '' then
    Result := 'CPU_' + IntToStr(GetTickCount);
end;

// 获取磁盘序列号
function TSecurityManager.GetDiskSerialNumber: string;
var
  VolumeSerialNumber: DWORD;
  MaxComponentLength: DWORD;
  FileSystemFlags: DWORD;
  VolumeNameBuffer: array[0..MAX_PATH-1] of Char;
  FileSystemNameBuffer: array[0..MAX_PATH-1] of Char;
begin
  Result := '';

  if GetVolumeInformation(
    PChar('C:\'),
    VolumeNameBuffer,
    SizeOf(VolumeNameBuffer),
    @VolumeSerialNumber,
    MaxComponentLength,
    FileSystemFlags,
    FileSystemNameBuffer,
    SizeOf(FileSystemNameBuffer)) then
  begin
    Result := IntToHex(VolumeSerialNumber, 8);
  end
  else
    Result := 'DISK_' + IntToStr(GetTickCount);
end;

// 获取MAC地址
function TSecurityManager.GetMACAddress: string;
var
  WSAData: TWSAData;
  HostName: array[0..255] of AnsiChar;
  HostEnt: PHostEnt;
  Addr: TInAddr;
begin
  Result := '';

  if WSAStartup($0101, WSAData) = 0 then
  try
    if gethostname(HostName, SizeOf(HostName)) = 0 then
    begin
      HostEnt := gethostbyname(HostName);
      if HostEnt <> nil then
      begin
        Addr.S_addr := Longint(PLongint(HostEnt^.h_addr_list^)^);
        Result := inet_ntoa(Addr);
      end;
    end;
  finally
    WSACleanup;
  end;

  // 如果无法获取，使用备用标识
  if Result = '' then
    Result := 'MAC_' + IntToStr(GetTickCount);
end;

// 获取BIOS信息
function TSecurityManager.GetBIOSInfo: string;
var
  Reg: TRegistry;
begin
  Result := '';
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey('HARDWARE\DESCRIPTION\System\BIOS', False) then
    begin
      if Reg.ValueExists('BIOSVersion') then
        Result := Reg.ReadString('BIOSVersion')
      else if Reg.ValueExists('SystemManufacturer') then
        Result := Reg.ReadString('SystemManufacturer');
      Reg.CloseKey;
    end;
    
    // 尝试另一个位置
    if Result = '' then
    begin
      if Reg.OpenKey('HARDWARE\DESCRIPTION\System', False) then
      begin
        if Reg.ValueExists('SystemBiosVersion') then
          Result := Reg.ReadString('SystemBiosVersion');
        Reg.CloseKey;
      end;
    end;
  finally
    Reg.Free;
  end;

  // 如果无法获取，使用备用方法
  if Result = '' then
    Result := 'BIOS_' + IntToStr(GetTickCount);
end;

// 获取主板信息
function TSecurityManager.GetMotherboardInfo: string;
var
  Reg: TRegistry;
begin
  Result := '';
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey('HARDWARE\DESCRIPTION\System\BIOS', False) then
    begin
      if Reg.ValueExists('BaseBoardManufacturer') then
        Result := Reg.ReadString('BaseBoardManufacturer')
      else if Reg.ValueExists('BaseBoardProduct') then
        Result := Reg.ReadString('BaseBoardProduct');
      Reg.CloseKey;
    end;
    
    // 尝试另一个位置
    if Result = '' then
    begin
      if Reg.OpenKey('SYSTEM\CurrentControlSet\Control\SystemInformation', False) then
      begin
        if Reg.ValueExists('SystemManufacturer') then
          Result := Reg.ReadString('SystemManufacturer');
        Reg.CloseKey;
      end;
    end;
  finally
    Reg.Free;
  end;

  // 如果无法获取，使用备用方法
  if Result = '' then
    Result := 'MOBO_' + IntToStr(GetTickCount);
end;

// 格式化机器码为易读格式
function TSecurityManager.FormatMachineCode(const ARawCode: string): string;
var
  CleanCode: string;
  I: Integer;
begin
  // 移除非字母数字字符并转换为大写
  CleanCode := '';
  for I := 1 to Length(ARawCode) do
  begin
    if CharInSet(ARawCode[I], ['0'..'9', 'A'..'Z', 'a'..'z']) then
      CleanCode := CleanCode + UpCase(ARawCode[I]);
  end;
  
  // 确保至少有16个字符
  while Length(CleanCode) < 16 do
    CleanCode := CleanCode + '0';
  
  // 截取前16个字符并格式化为 XXXX-XXXX-XXXX-XXXX
  CleanCode := Copy(CleanCode, 1, 16);
  Result := Copy(CleanCode, 1, 4) + '-' + 
            Copy(CleanCode, 5, 4) + '-' + 
            Copy(CleanCode, 9, 4) + '-' + 
            Copy(CleanCode, 13, 4);
end;

// 获取系统指纹
function TSecurityManager.GetSystemFingerprint: string;
var
  CPUInfo, DiskInfo, MACInfo, BIOSInfo, MotherboardInfo: string;
  Combined: string;
  RawFingerprint: string;
begin
  CPUInfo := GetCPUInfo;
  DiskInfo := GetDiskSerialNumber;
  MACInfo := GetMACAddress;
  BIOSInfo := GetBIOSInfo;
  MotherboardInfo := GetMotherboardInfo;

  Combined := CPUInfo + '|' + DiskInfo + '|' + MACInfo + '|' + BIOSInfo + '|' + MotherboardInfo;
  RawFingerprint := TBasicProtection.CalculateHMAC(Combined);
  
  // 格式化为易读的机器码格式 (XXXX-XXXX-XXXX-XXXX)
  Result := FormatMachineCode(RawFingerprint);
end;

// 加载存储的哈希值
function TSecurityManager.LoadStoredHash: string;
begin
  try
    Result := FConfigManager.GetString('Security', 'ExeHash', '');
  except
    Result := '';
  end;
end;

// 保存可执行文件哈希值
procedure TSecurityManager.SaveExecutableHash;
var
  ExeHash: string;
begin
  try
    ExeHash := TBasicProtection.CalculateFileHash(Application.ExeName);
    FConfigManager.SetString('Security', 'ExeHash', ExeHash);
    FConfigManager.SaveConfig;
  except
    // 忽略保存错误
  end;
end;

// 检查可执行文件完整性
function TSecurityManager.CheckExecutableIntegrity: Boolean;
var
  CurrentHash, StoredHash: string;
  ExePath: string;
  CriticalFiles: TArray<string>;
  I: Integer;
begin
  Result := True;
  
  try
    ExePath := Application.ExeName;
    
    // 检查主程序文件
    if not FileExists(ExePath) then
    begin
      Result := False;
      Exit;
    end;
    
    CurrentHash := TBasicProtection.CalculateFileHash(ExePath);
    StoredHash := LoadStoredHash;
    
    if StoredHash = '' then
    begin
      // 首次运行，保存哈希值
      SaveExecutableHash;
      Result := True;
    end
    else
    begin
      Result := SameText(CurrentHash, StoredHash);
      if not Result then
      begin
        // 记录完整性验证失败
        if Assigned(FConfigManager) then
          FConfigManager.LogOperation('SECURITY', 'Executable integrity check failed', 
            ExePath, '', 'FAILED', 'Hash mismatch: Expected=' + StoredHash + ', Actual=' + CurrentHash);
      end;
    end;
    
    // 检查关键组件文件
    if Result then
    begin
      CriticalFiles := TArray<string>.Create(
        ExtractFilePath(ExePath) + 'Core\SecurityManager.pas',
        ExtractFilePath(ExePath) + 'Core\BasicProtection.pas',
        ExtractFilePath(ExePath) + 'Core\ConfigManager.pas'
      );
      
      for I := 0 to Length(CriticalFiles) - 1 do
      begin
        if FileExists(CriticalFiles[I]) then
        begin
          if not ValidateFileIntegrity(CriticalFiles[I]) then
          begin
            Result := False;
            if Assigned(FConfigManager) then
              FConfigManager.LogOperation('SECURITY', 'Critical file integrity check failed', 
                CriticalFiles[I], '', 'FAILED', 'File hash verification failed');
            Break;
          end;
        end;
      end;
    end;
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('SECURITY', 'Executable integrity check exception', 
          ExePath, '', 'ERROR', E.Message);
    end;
  end;
end;

// 检查配置完整性
function TSecurityManager.CheckConfigIntegrity: Boolean;
var
  ConfigData, ConfigHMAC, CalculatedHMAC: string;
  SecuritySettings, MigrationSettings: string;
begin
  Result := True;
  
  try
    // 收集关键配置数据
    ConfigData := FConfigManager.GetString('Application', 'Language', '') + '|' +
                  IntToStr(FConfigManager.GetInteger('Application', 'SecurityLevel', 1)) + '|' +
                  FConfigManager.GetString('Application', 'LastBackupId', '');
    
    // 添加安全配置
    SecuritySettings := BoolToStr(FConfigManager.GetBoolean('Security', 'EnableIntegrityCheck', True)) + '|' +
                       BoolToStr(FConfigManager.GetBoolean('Security', 'EnableEncryption', True)) + '|' +
                       IntToStr(FConfigManager.GetInteger('Security', 'EncryptionLevel', 256));
    
    // 添加迁移配置
    MigrationSettings := BoolToStr(FConfigManager.GetBoolean('Migration', 'CreateBackupBeforeMigration', True)) + '|' +
                        BoolToStr(FConfigManager.GetBoolean('Migration', 'ValidateDependencies', True)) + '|' +
                        BoolToStr(FConfigManager.GetBoolean('Migration', 'RequireAdminRights', True));
    
    ConfigData := ConfigData + '|' + SecuritySettings + '|' + MigrationSettings;
    
    ConfigHMAC := FConfigManager.GetString('Security', 'ConfigHMAC', '');
    
    if ConfigHMAC = '' then
    begin
      // 首次运行，计算并保存HMAC
      CalculatedHMAC := TBasicProtection.CalculateHMAC(ConfigData);
      FConfigManager.SetString('Security', 'ConfigHMAC', CalculatedHMAC);
      FConfigManager.SaveConfig;
      Result := True;
    end
    else
    begin
      Result := TBasicProtection.VerifyDataIntegrity(ConfigData, ConfigHMAC);
      if not Result then
      begin
        // 记录配置完整性验证失败
        if Assigned(FConfigManager) then
          FConfigManager.LogOperation('SECURITY', 'Configuration integrity check failed', 
            FConfigManager.ConfigPath, '', 'FAILED', 'Configuration HMAC verification failed');
        
        // 在开发模式下，重新计算并保存HMAC
        if DEVELOPMENT_MODE then
        begin
          CalculatedHMAC := TBasicProtection.CalculateHMAC(ConfigData);
          FConfigManager.SetString('Security', 'ConfigHMAC', CalculatedHMAC);
          FConfigManager.SaveConfig;
          Result := True;
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('SECURITY', 'Configuration integrity check exception', 
          FConfigManager.ConfigPath, '', 'ERROR', E.Message);
    end;
  end;
end;

// 执行自检
function TSecurityManager.PerformSelfCheck: Boolean;
begin
  Result := True;

  try
    // 1. 检查主程序文件完整性
    try
      if not CheckExecutableIntegrity then
      begin
        if not DEVELOPMENT_MODE then
        begin
          Result := False;
          Exit;
        end;
        // 开发模式：只记录但不阻止启动
      end;
    except
      if not DEVELOPMENT_MODE then
      begin
        Result := False;
        Exit;
      end;
      // 开发模式：忽略完整性检查异常
    end;

    // 2. 检查配置数据完整性
    try
      if not CheckConfigIntegrity then
      begin
        if not DEVELOPMENT_MODE then
        begin
          Result := False;
          Exit;
        end;
        // 开发模式：只记录但不阻止启动
      end;
    except
      if not DEVELOPMENT_MODE then
      begin
        Result := False;
        Exit;
      end;
      // 开发模式：忽略配置检查异常
    end;

    // 3. 检查管理员权限
    try
      var RequireAdmin := FConfigManager.GetBoolean('Migration', 'RequireAdminRights', not DEVELOPMENT_MODE);
      if RequireAdmin then
      begin
        if not IsRunningAsAdmin then
        begin
          if not DEVELOPMENT_MODE then
          begin
            Result := False;
            Exit;
          end;
          // 开发模式：不强制要求管理员权限
        end;
      end;
    except
      if not DEVELOPMENT_MODE then
      begin
        Result := False;
        Exit;
      end;
      // 开发模式：忽略权限检查异常
    end;

  except
    on E: Exception do
    begin
      if not DEVELOPMENT_MODE then
        Result := False;
      // 开发模式：即使出现异常也允许启动
    end;
  end;
end;

// 验证文件完整性
function TSecurityManager.ValidateFileIntegrity(const AFilePath: string): Boolean;
var
  CurrentHash, StoredHash: string;
  HashKey: string;
begin
  Result := True;
  
  try
    if not FileExists(AFilePath) then
    begin
      Result := False;
      Exit;
    end;
    
    CurrentHash := TBasicProtection.CalculateFileHash(AFilePath);
    HashKey := 'FileHash_' + ExtractFileName(AFilePath);
    StoredHash := FConfigManager.GetString('FileHashes', HashKey, '');
    
    if StoredHash = '' then
    begin
      // 首次验证，保存哈希值
      FConfigManager.SetString('FileHashes', HashKey, CurrentHash);
      FConfigManager.SaveConfig;
      Result := True;
    end
    else
    begin
      Result := SameText(CurrentHash, StoredHash);
    end;
  except
    Result := False;
  end;
end;

// 加密敏感数据
function TSecurityManager.EncryptSensitiveData(const AData: string): string;
begin
  Result := TBasicProtection.EncryptSensitiveData(AData);
end;

// 解密敏感数据
function TSecurityManager.DecryptSensitiveData(const AEncryptedData: string): string;
begin
  Result := TBasicProtection.DecryptSensitiveData(AEncryptedData);
end;

// 生成机器指纹
function TSecurityManager.GenerateMachineFingerprint: string;
begin
  Result := GetSystemFingerprint;
end;

// 检查是否以管理员身份运行
function TSecurityManager.IsRunningAsAdmin: Boolean;
var
  hToken: THandle;
  TokenElevation: DWORD;
  dwSize: DWORD;
begin
  Result := False;

  if OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hToken) then
  try
    // 简化的管理员检查
    if GetTokenInformation(hToken, TTokenInformationClass(20), @TokenElevation,
       SizeOf(TokenElevation), dwSize) then
    begin
      Result := TokenElevation <> 0;
    end;
  finally
    CloseHandle(hToken);
  end;
end;

// 公共方法实现（调用私有方法）
function TSecurityManager.GetCPUInfoPublic: string;
begin
  Result := GetCPUInfo;
end;

function TSecurityManager.GetDiskSerialNumberPublic: string;
begin
  Result := GetDiskSerialNumber;
end;

function TSecurityManager.GetMACAddressPublic: string;
begin
  Result := GetMACAddress;
end;

function TSecurityManager.GetBIOSInfoPublic: string;
begin
  Result := GetBIOSInfo;
end;

function TSecurityManager.GetMotherboardInfoPublic: string;
begin
  Result := GetMotherboardInfo;
end;

function TSecurityManager.FormatMachineCodePublic(const ARawCode: string): string;
begin
  Result := FormatMachineCode(ARawCode);
end;

end.

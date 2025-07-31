unit DonationManager;

interface

uses
  System.SysUtils, System.Classes, System.StrUtils, IDonationManager2, DataTypes, ISecurityManager2,
  ConfigManager, BasicProtection;

type
  // 打赏管理器具体实现
  TDonationManager = class(TInterfacedObject, IDonationManager)
  private
    FSecurityManager: ISecurityManager;
    FConfigManager: TConfigManager;
    
    // 硬编码备用地址（安全防线）
    const
      BACKUP_BTC_ADDRESS = 'bc1qze0ggsrdtjqwjpjfufydsuyjxc08tgcq5xkct3';
      BACKUP_USDT_ADDRESS = 'TH1NazpoEpUqcEotGzLPHs13SbLDJKKCys';
      BACKUP_WECHAT_DESC = '微信收款码';
      BACKUP_ALIPAY_DESC = '支付宝收款码';
    
    // 内部方法
    function GetAddressTypeString(AType: TDonationAddressType): string;
    function LoadAddressFromConfig(AType: TDonationAddressType): TDonationAddressInfo;
    function LoadAddressFromDatabase(AType: TDonationAddressType): TDonationAddressInfo;
    procedure SaveAddressToConfig(const AAddress: TDonationAddressInfo);
    procedure SaveAddressToDatabase(const AAddress: TDonationAddressInfo);
    function GetBackupAddressInfo(AType: TDonationAddressType): TDonationAddressInfo;
    function ValidateAddressFormat(AType: TDonationAddressType; const AAddress: string): Boolean;
    procedure InitializeDefaultAddresses;
    function DetectTampering(AType: TDonationAddressType; const AAddress: TDonationAddressInfo): Boolean;
    procedure LogSecurityEvent(const AEvent, ADetails: string);
    
  public
    constructor Create(ASecurityManager: ISecurityManager; AConfigManager: TConfigManager = nil);
    destructor Destroy; override;
    
    // IDonationManager 接口实现
    function LoadDonationAddress(AType: TDonationAddressType): TDonationAddressInfo;
    function ValidateAddressIntegrity(const AAddress: TDonationAddressInfo): Boolean;
    function GetBackupAddress(AType: TDonationAddressType): string;
    function LoadQRCodeImage(AType: TDonationAddressType): TBytes;
    
    // 扩展功能
    function UpdateDonationAddress(AType: TDonationAddressType; const AAddress, ADescription: string; const AQRCodeData: TBytes): Boolean;
    function ResetToBackupAddress(AType: TDonationAddressType): Boolean;
    function GetAddressHistory(AType: TDonationAddressType): TArray<string>;
  end;

implementation

uses
  Vcl.Forms, System.DateUtils;

constructor TDonationManager.Create(ASecurityManager: ISecurityManager; AConfigManager: TConfigManager);
begin
  inherited Create;
  
  FSecurityManager := ASecurityManager;
  
  if Assigned(AConfigManager) then
    FConfigManager := AConfigManager
  else
    FConfigManager := TConfigManager.Create;
    
  InitializeDefaultAddresses;
end;

destructor TDonationManager.Destroy;
begin
  if Assigned(FConfigManager) then
    FConfigManager.Free;
  inherited;
end;

// 获取地址类型字符串
function TDonationManager.GetAddressTypeString(AType: TDonationAddressType): string;
begin
  case AType of
    datWechat: Result := 'Wechat';
    datAlipay: Result := 'Alipay';
    datBTC: Result := 'BTC';
    datUSDT: Result := 'USDT';
  else
    Result := 'Unknown';
  end;
end;

// 从配置加载地址
function TDonationManager.LoadAddressFromConfig(AType: TDonationAddressType): TDonationAddressInfo;
var
  TypeStr: string;
  EncryptedAddress, AddressHash: string;
  QRCodeHex: string;
begin
  TypeStr := GetAddressTypeString(AType);
  
  Result.AddressType := AType;
  Result.IsValid := False;
  
  try
    // 加载加密的地址
    EncryptedAddress := FConfigManager.GetString('DonationAddresses', TypeStr + '_Address', '');
    if EncryptedAddress = '' then
    begin
      Result := GetBackupAddressInfo(AType);
      Exit;
    end;
    
    // 解密地址
    Result.Address := FSecurityManager.DecryptSensitiveData(EncryptedAddress);
    
    // 加载描述
    Result.Description := FConfigManager.GetString('DonationAddresses', TypeStr + '_Description', '');
    
    // 加载二维码数据
    QRCodeHex := FConfigManager.GetString('DonationAddresses', TypeStr + '_QRCode', '');
    if QRCodeHex <> '' then
    begin
      // 将十六进制字符串转换为字节数组
      SetLength(Result.QRCodeData, Length(QRCodeHex) div 2);
      for var I := 0 to Length(Result.QRCodeData) - 1 do
        Result.QRCodeData[I] := StrToInt('$' + Copy(QRCodeHex, I * 2 + 1, 2));
    end;
    
    // 验证完整性
    AddressHash := FConfigManager.GetString('DonationAddresses', TypeStr + '_Hash', '');
    if AddressHash <> '' then
    begin
      var CalculatedHash := TBasicProtection.CalculateHMAC(Result.Address);
      Result.IsValid := SameText(AddressHash, CalculatedHash);
    end
    else
    begin
      Result.IsValid := True; // 首次加载
    end;
    
    // 如果验证失败，检测篡改并使用备用地址
    if not Result.IsValid then
    begin
      LogSecurityEvent('ADDRESS_TAMPERED', Format('地址类型: %s, 原地址: %s', [TypeStr, Result.Address]));
      Result := GetBackupAddressInfo(AType);
    end;
    
  except
    on E: Exception do
    begin
      LogSecurityEvent('ADDRESS_LOAD_ERROR', Format('地址类型: %s, 错误: %s', [TypeStr, E.Message]));
      // 加载失败，使用备用地址
      Result := GetBackupAddressInfo(AType);
    end;
  end;
end;

// 从数据库加载地址
function TDonationManager.LoadAddressFromDatabase(AType: TDonationAddressType): TDonationAddressInfo;
var
  TypeStr: string;
  DatabaseManager: TDatabaseManager;
  DonationAddresses: TArray<TDonationAddress>;
begin
  TypeStr := GetAddressTypeString(AType);
  Result.AddressType := AType;
  Result.IsValid := False;
  
  try
    DatabaseManager := FConfigManager.GetDatabaseManager;
    if Assigned(DatabaseManager) and DatabaseManager.IsInitialized then
    begin
      DonationAddresses := DatabaseManager.GetDonationAddresses(True);
      
      for var Address in DonationAddresses do
      begin
        if SameText(Address.AddressType, TypeStr) then
        begin
          Result.Address := Address.AddressValue;
          Result.Description := Address.Description;
          Result.IsValid := True;
          SetLength(Result.QRCodeData, 0); // 数据库版本暂不存储二维码
          Break;
        end;
      end;
    end;
    
    // 如果数据库中没有找到，尝试从配置文件加载
    if not Result.IsValid then
      Result := LoadAddressFromConfig(AType);
      
  except
    on E: Exception do
    begin
      LogSecurityEvent('DATABASE_LOAD_ERROR', Format('地址类型: %s, 错误: %s', [TypeStr, E.Message]));
      Result := LoadAddressFromConfig(AType);
    end;
  end;
end;

// 保存地址到配置
procedure TDonationManager.SaveAddressToConfig(const AAddress: TDonationAddressInfo);
var
  TypeStr: string;
  EncryptedAddress, AddressHash, QRCodeHex: string;
begin
  TypeStr := GetAddressTypeString(AAddress.AddressType);
  
  try
    // 加密地址
    EncryptedAddress := FSecurityManager.EncryptSensitiveData(AAddress.Address);
    
    // 计算哈希
    AddressHash := TBasicProtection.CalculateHMAC(AAddress.Address);
    
    // 转换二维码数据为十六进制
    QRCodeHex := '';
    for var I := 0 to Length(AAddress.QRCodeData) - 1 do
      QRCodeHex := QRCodeHex + IntToHex(AAddress.QRCodeData[I], 2);
    
    // 保存到配置
    FConfigManager.SetString('DonationAddresses', TypeStr + '_Address', EncryptedAddress);
    FConfigManager.SetString('DonationAddresses', TypeStr + '_Description', AAddress.Description);
    FConfigManager.SetString('DonationAddresses', TypeStr + '_Hash', AddressHash);
    FConfigManager.SetString('DonationAddresses', TypeStr + '_QRCode', QRCodeHex);
    FConfigManager.SetString('DonationAddresses', TypeStr + '_LastUpdated', DateTimeToStr(Now));
    
    FConfigManager.SaveConfig;
    
    LogSecurityEvent('ADDRESS_UPDATED', Format('地址类型: %s, 新地址: %s', [TypeStr, AAddress.Address]));
    
  except
    on E: Exception do
    begin
      LogSecurityEvent('ADDRESS_SAVE_ERROR', Format('地址类型: %s, 错误: %s', [TypeStr, E.Message]));
    end;
  end;
end;

// 保存地址到数据库
procedure TDonationManager.SaveAddressToDatabase(const AAddress: TDonationAddressInfo);
var
  TypeStr: string;
  DatabaseManager: TDatabaseManager;
begin
  TypeStr := GetAddressTypeString(AAddress.AddressType);
  
  try
    DatabaseManager := FConfigManager.GetDatabaseManager;
    if Assigned(DatabaseManager) and DatabaseManager.IsInitialized then
    begin
      DatabaseManager.SetDonationAddress(TypeStr, AAddress.Address, AAddress.Description, True, 0);
      LogSecurityEvent('DATABASE_ADDRESS_UPDATED', Format('地址类型: %s', [TypeStr]));
    end;
  except
    on E: Exception do
    begin
      LogSecurityEvent('DATABASE_SAVE_ERROR', Format('地址类型: %s, 错误: %s', [TypeStr, E.Message]));
    end;
  end;
end;

// 获取备用地址信息
function TDonationManager.GetBackupAddressInfo(AType: TDonationAddressType): TDonationAddressInfo;
begin
  Result.AddressType := AType;
  Result.IsValid := True;
  SetLength(Result.QRCodeData, 0); // 备用地址没有二维码数据
  
  case AType of
    datWechat:
      begin
        Result.Address := '';
        Result.Description := BACKUP_WECHAT_DESC;
      end;
    datAlipay:
      begin
        Result.Address := '';
        Result.Description := BACKUP_ALIPAY_DESC;
      end;
    datBTC:
      begin
        Result.Address := BACKUP_BTC_ADDRESS;
        Result.Description := 'BTC收款地址（备用）';
      end;
    datUSDT:
      begin
        Result.Address := BACKUP_USDT_ADDRESS;
        Result.Description := 'USDT收款地址(TRC20)（备用）';
      end;
  else
    begin
      Result.Address := '';
      Result.Description := '未知类型';
      Result.IsValid := False;
    end;
  end;
end;

// 验证地址格式
function TDonationManager.ValidateAddressFormat(AType: TDonationAddressType; const AAddress: string): Boolean;
begin
  Result := True; // 基础验证
  
  if AAddress = '' then
  begin
    Result := (AType = datWechat) or (AType = datAlipay); // 微信和支付宝可以为空
    Exit;
  end;
  
  case AType of
    datBTC:
      begin
        // BTC地址基本验证
        Result := (Length(AAddress) >= 26) and (Length(AAddress) <= 62) and
                  (StartsText('1', AAddress) or StartsText('3', AAddress) or StartsText('bc1', AAddress));
      end;
    datUSDT:
      begin
        // USDT(TRC20)地址基本验证
        Result := (Length(AAddress) = 34) and StartsText('T', AAddress);
      end;
    datWechat, datAlipay:
      begin
        // 微信和支付宝暂不验证具体格式
        Result := True;
      end;
  end;
end;

// 初始化默认地址
procedure TDonationManager.InitializeDefaultAddresses;
var
  AddressType: TDonationAddressType;
  AddressInfo: TDonationAddressInfo;
begin
  // 检查是否已有配置，如果没有则创建默认配置
  for AddressType := Low(TDonationAddressType) to High(TDonationAddressType) do
  begin
    var TypeStr := GetAddressTypeString(AddressType);
    var ExistingAddress := FConfigManager.GetString('DonationAddresses', TypeStr + '_Address', '');
    
    if ExistingAddress = '' then
    begin
      // 创建默认地址配置
      AddressInfo := GetBackupAddressInfo(AddressType);
      if AddressInfo.Address <> '' then
      begin
        SaveAddressToConfig(AddressInfo);
        SaveAddressToDatabase(AddressInfo);
      end;
    end;
  end;
end;

// 检测篡改
function TDonationManager.DetectTampering(AType: TDonationAddressType; const AAddress: TDonationAddressInfo): Boolean;
var
  TypeStr: string;
  StoredHash, CalculatedHash: string;
  LastUpdated: string;
begin
  Result := False;
  TypeStr := GetAddressTypeString(AType);
  
  try
    // 计算当前地址的哈希
    CalculatedHash := TBasicProtection.CalculateHMAC(AAddress.Address);
    
    // 获取存储的哈希
    StoredHash := FConfigManager.GetString('DonationAddresses', TypeStr + '_Hash', '');
    
    if StoredHash <> '' then
    begin
      // 比较哈希值
      if not SameText(StoredHash, CalculatedHash) then
      begin
        Result := True;
        LastUpdated := FConfigManager.GetString('DonationAddresses', TypeStr + '_LastUpdated', '');
        LogSecurityEvent('TAMPERING_DETECTED', 
          Format('地址类型: %s, 存储哈希: %s, 计算哈希: %s, 最后更新: %s', 
            [TypeStr, StoredHash, CalculatedHash, LastUpdated]));
      end;
    end;
    
  except
    on E: Exception do
    begin
      LogSecurityEvent('TAMPERING_CHECK_ERROR', Format('地址类型: %s, 错误: %s', [TypeStr, E.Message]));
      Result := True; // 检查失败时假设被篡改
    end;
  end;
end;

// 记录安全事件
procedure TDonationManager.LogSecurityEvent(const AEvent, ADetails: string);
begin
  try
    if Assigned(FConfigManager) then
      FConfigManager.LogOperation('DONATION_SECURITY', AEvent, '', '', 'SECURITY_EVENT', ADetails);
  except
    // 忽略日志记录错误
  end;
end;

// 加载打赏地址
function TDonationManager.LoadDonationAddress(AType: TDonationAddressType): TDonationAddressInfo;
begin
  // 优先从数据库加载，然后是配置文件
  Result := LoadAddressFromDatabase(AType);
  
  // 如果加载失败或验证失败，返回备用地址
  if not Result.IsValid then
  begin
    LogSecurityEvent('FALLBACK_TO_BACKUP', Format('地址类型: %s', [GetAddressTypeString(AType)]));
    Result := GetBackupAddressInfo(AType);
  end;
  
  // 检测篡改
  if DetectTampering(AType, Result) then
  begin
    LogSecurityEvent('AUTO_RESTORE_BACKUP', Format('地址类型: %s', [GetAddressTypeString(AType)]));
    Result := GetBackupAddressInfo(AType);
  end;
end;

// 验证地址完整性
function TDonationManager.ValidateAddressIntegrity(const AAddress: TDonationAddressInfo): Boolean;
var
  TypeStr: string;
  StoredHash, CalculatedHash: string;
begin
  Result := False;
  
  try
    // 验证地址格式
    if not ValidateAddressFormat(AAddress.AddressType, AAddress.Address) then
    begin
      LogSecurityEvent('INVALID_ADDRESS_FORMAT', 
        Format('地址类型: %s, 地址: %s', [GetAddressTypeString(AAddress.AddressType), AAddress.Address]));
      Exit;
    end;
    
    // 计算当前地址的哈希
    CalculatedHash := TBasicProtection.CalculateHMAC(AAddress.Address);
    
    // 获取存储的哈希
    TypeStr := GetAddressTypeString(AAddress.AddressType);
    StoredHash := FConfigManager.GetString('DonationAddresses', TypeStr + '_Hash', '');
    
    if StoredHash = '' then
    begin
      // 如果没有存储的哈希，认为是有效的（首次验证）
      Result := True;
    end
    else
    begin
      // 比较哈希值
      Result := SameText(StoredHash, CalculatedHash);
      if not Result then
      begin
        LogSecurityEvent('INTEGRITY_CHECK_FAILED', 
          Format('地址类型: %s, 存储哈希: %s, 计算哈希: %s', [TypeStr, StoredHash, CalculatedHash]));
      end;
    end;
    
  except
    on E: Exception do
    begin
      LogSecurityEvent('INTEGRITY_CHECK_ERROR', 
        Format('地址类型: %s, 错误: %s', [GetAddressTypeString(AAddress.AddressType), E.Message]));
      Result := False;
    end;
  end;
end;

// 获取备用地址
function TDonationManager.GetBackupAddress(AType: TDonationAddressType): string;
var
  BackupInfo: TDonationAddressInfo;
begin
  BackupInfo := GetBackupAddressInfo(AType);
  Result := BackupInfo.Address;
end;

// 加载二维码图片
function TDonationManager.LoadQRCodeImage(AType: TDonationAddressType): TBytes;
var
  AddressInfo: TDonationAddressInfo;
begin
  AddressInfo := LoadDonationAddress(AType);
  Result := AddressInfo.QRCodeData;
  
  // 如果没有二维码数据，返回空数组
  if Length(Result) = 0 then
    SetLength(Result, 0);
end;

// 更新打赏地址
function TDonationManager.UpdateDonationAddress(AType: TDonationAddressType; const AAddress, ADescription: string; const AQRCodeData: TBytes): Boolean;
var
  AddressInfo: TDonationAddressInfo;
begin
  Result := False;
  
  try
    // 验证地址格式
    if not ValidateAddressFormat(AType, AAddress) then
    begin
      LogSecurityEvent('UPDATE_INVALID_FORMAT', 
        Format('地址类型: %s, 地址: %s', [GetAddressTypeString(AType), AAddress]));
      Exit;
    end;
    
    // 创建地址信息
    AddressInfo.AddressType := AType;
    AddressInfo.Address := AAddress;
    AddressInfo.Description := ADescription;
    AddressInfo.QRCodeData := AQRCodeData;
    AddressInfo.IsValid := True;
    
    // 保存到配置和数据库
    SaveAddressToConfig(AddressInfo);
    SaveAddressToDatabase(AddressInfo);
    
    Result := True;
    LogSecurityEvent('ADDRESS_UPDATED_SUCCESS', 
      Format('地址类型: %s, 新地址: %s', [GetAddressTypeString(AType), AAddress]));
    
  except
    on E: Exception do
    begin
      LogSecurityEvent('UPDATE_ADDRESS_ERROR', 
        Format('地址类型: %s, 错误: %s', [GetAddressTypeString(AType), E.Message]));
    end;
  end;
end;

// 重置为备用地址
function TDonationManager.ResetToBackupAddress(AType: TDonationAddressType): Boolean;
var
  BackupInfo: TDonationAddressInfo;
begin
  Result := False;
  
  try
    BackupInfo := GetBackupAddressInfo(AType);
    if BackupInfo.IsValid then
    begin
      SaveAddressToConfig(BackupInfo);
      SaveAddressToDatabase(BackupInfo);
      Result := True;
      
      LogSecurityEvent('RESET_TO_BACKUP', 
        Format('地址类型: %s, 备用地址: %s', [GetAddressTypeString(AType), BackupInfo.Address]));
    end;
    
  except
    on E: Exception do
    begin
      LogSecurityEvent('RESET_BACKUP_ERROR', 
        Format('地址类型: %s, 错误: %s', [GetAddressTypeString(AType), E.Message]));
    end;
  end;
end;

// 获取地址历史
function TDonationManager.GetAddressHistory(AType: TDonationAddressType): TArray<string>;
var
  TypeStr: string;
  DatabaseManager: TDatabaseManager;
  OperationLogs: TArray<TOperationLog>;
  HistoryList: TArray<string>;
  StartDate: TDateTime;
begin
  SetLength(Result, 0);
  TypeStr := GetAddressTypeString(AType);
  
  try
    DatabaseManager := FConfigManager.GetDatabaseManager;
    if Assigned(DatabaseManager) and DatabaseManager.IsInitialized then
    begin
      StartDate := Now - 365; // 查询一年内的历史
      OperationLogs := DatabaseManager.GetOperationLogs(StartDate, Now, 'DONATION_SECURITY');
      
      SetLength(HistoryList, 0);
      for var Log in OperationLogs do
      begin
        if ContainsText(Log.OperationDetail, TypeStr) then
        begin
          SetLength(HistoryList, Length(HistoryList) + 1);
          HistoryList[High(HistoryList)] := Format('[%s] %s: %s', 
            [DateTimeToStr(Log.CreatedAt), Log.OperationDetail, Log.ErrorMessage]);
        end;
      end;
      
      Result := HistoryList;
    end;
    
  except
    on E: Exception do
    begin
      LogSecurityEvent('GET_HISTORY_ERROR', 
        Format('地址类型: %s, 错误: %s', [TypeStr, E.Message]));
    end;
  end;
end;

end.
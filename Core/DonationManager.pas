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
    procedure SaveAddressToConfig(const AAddress: TDonationAddressInfo);
    function GetBackupAddressInfo(AType: TDonationAddressType): TDonationAddressInfo;
    function ValidateAddressFormat(AType: TDonationAddressType; const AAddress: string): Boolean;
    procedure InitializeDefaultAddresses;
    
  public
    constructor Create(ASecurityManager: ISecurityManager; AConfigManager: TConfigManager = nil);
    destructor Destroy; override;
    
    // IDonationManager 接口实现
    function LoadDonationAddress(AType: TDonationAddressType): TDonationAddressInfo;
    function ValidateAddressIntegrity(const AAddress: TDonationAddressInfo): Boolean;
    function GetBackupAddress(AType: TDonationAddressType): string;
    function LoadQRCodeImage(AType: TDonationAddressType): TBytes;
  end;

implementation

uses
  Vcl.Forms;

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
    
    // 如果验证失败，使用备用地址
    if not Result.IsValid then
    begin
      Result := GetBackupAddressInfo(AType);
    end;
    
  except
    // 加载失败，使用备用地址
    Result := GetBackupAddressInfo(AType);
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
    
    FConfigManager.SaveConfig;
    
  except
    // 保存失败，忽略错误
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
        Result.Description := 'BTC收款地址';
      end;
    datUSDT:
      begin
        Result.Address := BACKUP_USDT_ADDRESS;
        Result.Description := 'USDT收款地址(TRC20)';
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
  Result := True; // 简化验证
  
  if AAddress = '' then
  begin
    Result := False;
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
        Result := Length(AAddress) > 0;
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
        SaveAddressToConfig(AddressInfo);
    end;
  end;
end;

// 加载打赏地址
function TDonationManager.LoadDonationAddress(AType: TDonationAddressType): TDonationAddressInfo;
begin
  Result := LoadAddressFromConfig(AType);
  
  // 如果加载失败或验证失败，返回备用地址
  if not Result.IsValid then
  begin
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
      Exit;
    
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
    end;
    
  except
    Result := False;
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

end.

unit DonationManager;

interface

uses
  System.SysUtils, System.Classes, DataTypes, ConfigManager, EncryptionService;

type
  TDonationAddress = record
    AddressType: string; // 'Bitcoin', 'Ethereum', 'Alipay', 'WeChat'
    Address: string;
    QRCodeData: TBytes;
    IsEncrypted: Boolean;
    Checksum: string;
  end;
  
  TDonationManager = class
  private
    FConfigManager: TConfigManager;
    FEncryptionService: TEncryptionService;
    FAddresses: TArray<TDonationAddress>;
    
    function EncryptAddress(const AAddress: string): string;
    function DecryptAddress(const AEncryptedAddress: string): string;
    function CalculateChecksum(const AData: string): string;
    function VerifyChecksum(const AData, AChecksum: string): Boolean;
    
  public
    constructor Create(AConfigManager: TConfigManager = nil);
    destructor Destroy; override;
    
    function LoadAddresses: Boolean;
    function SaveAddresses: Boolean;
    function AddDonationAddress(const AType, AAddress: string; const AQRCode: TBytes): Boolean;
    function GetDonationAddress(const AType: string): TDonationAddress;
    function GetAllAddresses: TArray<TDonationAddress>;
    function VerifyIntegrity: Boolean;
  end;

implementation

uses
  System.Hash, System.NetEncoding;

constructor TDonationManager.Create(AConfigManager: TConfigManager);
begin
  inherited Create;
  
  if Assigned(AConfigManager) then
    FConfigManager := AConfigManager
  else
    FConfigManager := TConfigManager.Create;
    
  FEncryptionService := TEncryptionService.Create(FConfigManager);
  
  LoadAddresses;
end;

destructor TDonationManager.Destroy;
begin
  FEncryptionService.Free;
  
  if Assigned(FConfigManager) then
    FConfigManager.Free;
    
  inherited;
end;

function TDonationManager.EncryptAddress(const AAddress: string): string;
var
  AddressBytes, EncryptedBytes: TBytes;
  Key: string;
begin
  try
    Key := 'DonationKey2024'; // 简化的固定密钥
    AddressBytes := TEncoding.UTF8.GetBytes(AAddress);
    EncryptedBytes := FEncryptionService.EncryptData(AddressBytes, Key);
    Result := TNetEncoding.Base64.EncodeBytesToString(EncryptedBytes);
  except
    Result := AAddress; // 加密失败时返回原文
  end;
end;

function TDonationManager.DecryptAddress(const AEncryptedAddress: string): string;
var
  EncryptedBytes, DecryptedBytes: TBytes;
  Key: string;
begin
  try
    Key := 'DonationKey2024';
    EncryptedBytes := TNetEncoding.Base64.DecodeStringToBytes(AEncryptedAddress);
    DecryptedBytes := FEncryptionService.DecryptData(EncryptedBytes, Key);
    Result := TEncoding.UTF8.GetString(DecryptedBytes);
  except
    Result := AEncryptedAddress; // 解密失败时返回原文
  end;
end;

function TDonationManager.CalculateChecksum(const AData: string): string;
var
  Hash: THashSHA256;
begin
  Hash := THashSHA256.Create;
  Hash.Update(AData);
  Result := Hash.HashAsString;
end;

function TDonationManager.VerifyChecksum(const AData, AChecksum: string): Boolean;
var
  CalculatedChecksum: string;
begin
  CalculatedChecksum := CalculateChecksum(AData);
  Result := SameText(CalculatedChecksum, AChecksum);
end;

function TDonationManager.LoadAddresses: Boolean;
begin
  Result := True;
  
  try
    // 简化实现：创建默认地址
    SetLength(FAddresses, 4);
    
    FAddresses[0].AddressType := 'Bitcoin';
    FAddresses[0].Address := EncryptAddress('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa');
    FAddresses[0].IsEncrypted := True;
    FAddresses[0].Checksum := CalculateChecksum(FAddresses[0].Address);
    
    FAddresses[1].AddressType := 'Ethereum';
    FAddresses[1].Address := EncryptAddress('0x742d35Cc6634C0532925a3b8D4C0C8b3C2e1e1e1');
    FAddresses[1].IsEncrypted := True;
    FAddresses[1].Checksum := CalculateChecksum(FAddresses[1].Address);
    
    FAddresses[2].AddressType := 'Alipay';
    FAddresses[2].Address := EncryptAddress('example@alipay.com');
    FAddresses[2].IsEncrypted := True;
    FAddresses[2].Checksum := CalculateChecksum(FAddresses[2].Address);
    
    FAddresses[3].AddressType := 'WeChat';
    FAddresses[3].Address := EncryptAddress('wxpay_example');
    FAddresses[3].IsEncrypted := True;
    FAddresses[3].Checksum := CalculateChecksum(FAddresses[3].Address);
    
  except
    Result := False;
  end;
end;

function TDonationManager.SaveAddresses: Boolean;
begin
  Result := True; // 简化实现
end;

function TDonationManager.AddDonationAddress(const AType, AAddress: string; const AQRCode: TBytes): Boolean;
var
  NewAddress: TDonationAddress;
begin
  Result := False;
  
  try
    NewAddress.AddressType := AType;
    NewAddress.Address := EncryptAddress(AAddress);
    NewAddress.QRCodeData := AQRCode;
    NewAddress.IsEncrypted := True;
    NewAddress.Checksum := CalculateChecksum(NewAddress.Address);
    
    SetLength(FAddresses, Length(FAddresses) + 1);
    FAddresses[High(FAddresses)] := NewAddress;
    
    Result := SaveAddresses;
    
  except
    Result := False;
  end;
end;

function TDonationManager.GetDonationAddress(const AType: string): TDonationAddress;
var
  I: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  for I := 0 to Length(FAddresses) - 1 do
  begin
    if SameText(FAddresses[I].AddressType, AType) then
    begin
      Result := FAddresses[I];
      if Result.IsEncrypted then
        Result.Address := DecryptAddress(Result.Address);
      Break;
    end;
  end;
end;

function TDonationManager.GetAllAddresses: TArray<TDonationAddress>;
var
  I: Integer;
begin
  SetLength(Result, Length(FAddresses));
  
  for I := 0 to Length(FAddresses) - 1 do
  begin
    Result[I] := FAddresses[I];
    if Result[I].IsEncrypted then
      Result[I].Address := DecryptAddress(Result[I].Address);
  end;
end;

function TDonationManager.VerifyIntegrity: Boolean;
var
  I: Integer;
begin
  Result := True;
  
  try
    for I := 0 to Length(FAddresses) - 1 do
    begin
      if not VerifyChecksum(FAddresses[I].Address, FAddresses[I].Checksum) then
      begin
        Result := False;
        Break;
      end;
    end;
    
    if Assigned(FConfigManager) then
      FConfigManager.LogOperation('DONATION', 'Integrity check', '', '', Result.ToString, 
        Format('Verified %d addresses', [Length(FAddresses)]));
    
  except
    Result := False;
  end;
end;

end.
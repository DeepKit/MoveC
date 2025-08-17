unit EncryptionService;

interface

uses
  System.SysUtils, System.Classes, DataTypes, ConfigManager;

type
  TEncryptionService = class
  private
    FConfigManager: TConfigManager;
    
  public
    constructor Create(AConfigManager: TConfigManager = nil);
    destructor Destroy; override;
    
    function EncryptData(const AData: TBytes; const AKey: string): TBytes;
    function DecryptData(const AData: TBytes; const AKey: string): TBytes;
    function GenerateKey: string;
    function CalculateHMAC(const AData: TBytes; const AKey: string): string;
    function VerifyIntegrity(const AData: TBytes; const AKey, AHMAC: string): Boolean;
  end;

implementation

uses
  System.Hash, System.NetEncoding;

constructor TEncryptionService.Create(AConfigManager: TConfigManager);
begin
  inherited Create;
  
  if Assigned(AConfigManager) then
    FConfigManager := AConfigManager
  else
    FConfigManager := TConfigManager.Create;
end;

destructor TEncryptionService.Destroy;
begin
  if Assigned(FConfigManager) then
    FConfigManager.Free;
    
  inherited;
end;

function TEncryptionService.EncryptData(const AData: TBytes; const AKey: string): TBytes;
var
  I: Integer;
  KeyBytes: TBytes;
begin
  // 简化的XOR加密实现
  KeyBytes := TEncoding.UTF8.GetBytes(AKey);
  SetLength(Result, Length(AData));
  
  for I := 0 to Length(AData) - 1 do
    Result[I] := AData[I] xor KeyBytes[I mod Length(KeyBytes)];
end;

function TEncryptionService.DecryptData(const AData: TBytes; const AKey: string): TBytes;
begin
  // XOR加密的解密就是再次XOR
  Result := EncryptData(AData, AKey);
end;

function TEncryptionService.GenerateKey: string;
begin
  Result := THashMD5.GetHashString(FormatDateTime('yyyymmddhhnnsszzz', Now) + IntToStr(Random(MaxInt)));
end;

function TEncryptionService.CalculateHMAC(const AData: TBytes; const AKey: string): string;
var
  Hash: THashSHA256;
  KeyData: TBytes;
begin
  KeyData := TEncoding.UTF8.GetBytes(AKey);
  Hash := THashSHA256.Create;
  Hash.Update(KeyData);
  Hash.Update(AData);
  Result := Hash.HashAsString;
end;

function TEncryptionService.VerifyIntegrity(const AData: TBytes; const AKey, AHMAC: string): Boolean;
var
  CalculatedHMAC: string;
begin
  CalculatedHMAC := CalculateHMAC(AData, AKey);
  Result := SameText(CalculatedHMAC, AHMAC);
end;

end.
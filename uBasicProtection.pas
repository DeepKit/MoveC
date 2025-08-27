unit uBasicProtection;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Hash, System.NetEncoding, System.IOUtils,
  System.AnsiStrings, System.DateUtils;

const
  // Windows Crypto API 常量
  PROV_RSA_FULL = 1;
  PROV_RSA_AES = 24;
  CRYPT_VERIFYCONTEXT = $F0000000;
  CRYPT_EXPORTABLE = $00000001;
  CALG_SHA_256 = $0000800c;
  CALG_AES_256 = $00006610;
  KP_MODE = 4;
  KP_IV = 1;
  CRYPT_MODE_CBC = 1;
  MS_ENH_RSA_AES_PROV = 'Microsoft Enhanced RSA and AES Cryptographic Provider';

type
  HCRYPTPROV = THandle;
  HCRYPTKEY = THandle;
  HCRYPTHASH = THandle;

// Windows Crypto API 函数声明
function CryptAcquireContext(var phProv: HCRYPTPROV; pszContainer: PAnsiChar;
  pszProvider: PAnsiChar; dwProvType: DWORD; dwFlags: DWORD): BOOL; stdcall; external 'advapi32.dll' name 'CryptAcquireContextA';

function CryptReleaseContext(hProv: HCRYPTPROV; dwFlags: DWORD): BOOL; stdcall; external 'advapi32.dll';

function CryptGenRandom(hProv: HCRYPTPROV; dwLen: DWORD; pbBuffer: PByte): BOOL; stdcall; external 'advapi32.dll';

function CryptCreateHash(hProv: HCRYPTPROV; Algid: DWORD; hKey: HCRYPTKEY;
  dwFlags: DWORD; var phHash: HCRYPTHASH): BOOL; stdcall; external 'advapi32.dll';

function CryptHashData(hHash: HCRYPTHASH; pbData: PByte; dwDataLen: DWORD;
  dwFlags: DWORD): BOOL; stdcall; external 'advapi32.dll';

function CryptDeriveKey(hProv: HCRYPTPROV; Algid: DWORD; hBaseData: HCRYPTHASH;
  dwFlags: DWORD; var phKey: HCRYPTKEY): BOOL; stdcall; external 'advapi32.dll';

function CryptSetKeyParam(hKey: HCRYPTKEY; dwParam: DWORD; pbData: PByte;
  dwFlags: DWORD): BOOL; stdcall; external 'advapi32.dll';

function CryptEncrypt(hKey: HCRYPTKEY; hHash: HCRYPTHASH; Final: BOOL;
  dwFlags: DWORD; pbData: PByte; var pdwDataLen: DWORD; dwBufLen: DWORD): BOOL; stdcall; external 'advapi32.dll';

function CryptDecrypt(hKey: HCRYPTKEY; hHash: HCRYPTHASH; Final: BOOL;
  dwFlags: DWORD; pbData: PByte; var pdwDataLen: DWORD): BOOL; stdcall; external 'advapi32.dll';

function CryptDestroyKey(hKey: HCRYPTKEY): BOOL; stdcall; external 'advapi32.dll';

function CryptDestroyHash(hHash: HCRYPTHASH): BOOL; stdcall; external 'advapi32.dll';

type
  TBasicProtection = class
  private
    class function GetDynamicKey: string;
    class function GenerateRandomIV: TBytes;
    class function BytesToHex(const ABytes: TBytes): string;
    class function HexToBytes(const AHex: string): TBytes;
    class function PadData(const AData: TBytes; ABlockSize: Integer): TBytes;
    class function UnpadData(const AData: TBytes): TBytes;
  public
    class function EncryptSensitiveData(const AData: string; const APassword: string = '@2241114'): string;
    class function DecryptSensitiveData(const AEncryptedData: string; const APassword: string = '@2241114'): string;
    class function EncryptBinaryData(const AData: TBytes; const APassword: string = '@2241114'): TBytes;
    class function DecryptBinaryData(const AEncryptedData: TBytes; const APassword: string = '@2241114'): TBytes;
    class function CalculateHMAC(const AData: string; const APassword: string = '@2241114'): string;
    class function VerifyDataIntegrity(const AData, AHMAC: string; const APassword: string = '@2241114'): Boolean;
    class function CalculateFileHash(const AFileName: string): string;
    class function CalculateDataHash(const AData: TBytes): string;
  end;

implementation

// 动态密钥生成（基于密码和系统信息）
class function TBasicProtection.GetDynamicKey: string;
var
  ExePath: string;
  Part1, Part2, Part3: string;
begin
  ExePath := ParamStr(0);
  Part1 := ChangeFileExt(ExtractFileName(ExePath), '');
  Part2 := IntToStr(DateTimeToUnix(TFile.GetLastWriteTime(ExePath)));
  Part3 := 'SecureKey2024';
  Result := Copy(Part1 + Part2 + Part3, 1, 32);
  
  // 填充到32字节
  while Length(Result) < 32 do
    Result := Result + '0';
end;

// 生成随机IV (使用Windows CryptoAPI)
class function TBasicProtection.GenerateRandomIV: TBytes;
var
  hProv: HCRYPTPROV;
begin
  SetLength(Result, 16); // AES块大小为16字节
  
  if CryptAcquireContext(hProv, nil, nil, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT) then
  try
    if not CryptGenRandom(hProv, 16, @Result[0]) then
      raise Exception.Create('生成随机IV失败');
  finally
    CryptReleaseContext(hProv, 0);
  end
  else
    raise Exception.Create('获取加密上下文失败');
end;

// 数据填充（PKCS7）
class function TBasicProtection.PadData(const AData: TBytes; ABlockSize: Integer): TBytes;
var
  PadLength: Integer;
  I: Integer;
begin
  PadLength := ABlockSize - (Length(AData) mod ABlockSize);
  if PadLength = 0 then
    PadLength := ABlockSize;
    
  SetLength(Result, Length(AData) + PadLength);
  Move(AData[0], Result[0], Length(AData));
  
  for I := Length(AData) to High(Result) do
    Result[I] := PadLength;
end;

// 移除填充
class function TBasicProtection.UnpadData(const AData: TBytes): TBytes;
var
  PadLength: Integer;
  I: Integer;
begin
  if Length(AData) = 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  
  PadLength := AData[High(AData)];
  
  // 验证填充的正确性
  for I := Length(AData) - PadLength to High(AData) do
  begin
    if AData[I] <> PadLength then
      raise Exception.Create('无效的数据填充');
  end;
  
  SetLength(Result, Length(AData) - PadLength);
  if Length(Result) > 0 then
    Move(AData[0], Result[0], Length(Result));
end;

// AES-256-CBC加密 (使用Windows CryptoAPI)
class function TBasicProtection.EncryptSensitiveData(const AData: string; const APassword: string = '@2241114'): string;
var
  hProv: HCRYPTPROV;
  hKey: HCRYPTKEY;
  hHash: HCRYPTHASH;
  DataBytes, EncryptedData, IV, PaddedData: TBytes;
  DataLen: DWORD;
  KeyBytes: TBytes;
begin
  if AData = '' then
  begin
    Result := '';
    Exit;
  end;

  KeyBytes := TEncoding.UTF8.GetBytes(APassword + GetDynamicKey);
  DataBytes := TEncoding.UTF8.GetBytes(AData);
  IV := GenerateRandomIV;
  
  // 获取AES加密上下文
  if not CryptAcquireContext(hProv, nil, MS_ENH_RSA_AES_PROV, PROV_RSA_AES, CRYPT_VERIFYCONTEXT) then
    raise Exception.Create('获取AES加密上下文失败');
  
  try
    // 创建哈希对象用于密钥派生
    if not CryptCreateHash(hProv, CALG_SHA_256, 0, 0, hHash) then
      raise Exception.Create('创建哈希对象失败');
    
    try
      // 添加密钥数据到哈希
      if not CryptHashData(hHash, @KeyBytes[0], Length(KeyBytes), 0) then
        raise Exception.Create('哈希密钥数据失败');
      
      // 从哈希派生AES-256密钥
      if not CryptDeriveKey(hProv, CALG_AES_256, hHash, CRYPT_EXPORTABLE, hKey) then
        raise Exception.Create('派生AES密钥失败');
      
      try
        // 设置CBC模式
        var Mode: DWORD := CRYPT_MODE_CBC;
        if not CryptSetKeyParam(hKey, KP_MODE, @Mode, 0) then
          raise Exception.Create('设置CBC模式失败');
        
        // 设置IV
        if not CryptSetKeyParam(hKey, KP_IV, @IV[0], 0) then
          raise Exception.Create('设置IV失败');
        
        // 手动填充数据
        PaddedData := PadData(DataBytes, 16);
        SetLength(EncryptedData, Length(PaddedData));
        Move(PaddedData[0], EncryptedData[0], Length(PaddedData));
        DataLen := Length(EncryptedData);
        
        // 执行AES-256-CBC加密
        if not CryptEncrypt(hKey, 0, True, 0, @EncryptedData[0], DataLen, Length(EncryptedData)) then
          raise Exception.Create('AES加密失败');
        
        // 调整加密数据长度
        SetLength(EncryptedData, DataLen);
        
        // 返回 IV + 加密数据 的十六进制表示
        Result := BytesToHex(IV) + '|' + BytesToHex(EncryptedData);
        
      finally
        CryptDestroyKey(hKey);
      end;
    finally
      CryptDestroyHash(hHash);
    end;
  finally
    CryptReleaseContext(hProv, 0);
  end;
end;

// AES-256-CBC解密
class function TBasicProtection.DecryptSensitiveData(const AEncryptedData: string; const APassword: string = '@2241114'): string;
var
  hProv: HCRYPTPROV;
  hKey: HCRYPTKEY;
  hHash: HCRYPTHASH;
  Parts: TArray<string>;
  IV, EncryptedBytes, DecryptedData: TBytes;
  DataLen: DWORD;
  KeyBytes: TBytes;
begin
  Result := '';
  
  if AEncryptedData = '' then
    Exit;
  
  // 分离IV和加密数据
  Parts := AEncryptedData.Split(['|']);
  if Length(Parts) <> 2 then
    raise Exception.Create('加密数据格式错误');
  
  IV := HexToBytes(Parts[0]);
  EncryptedBytes := HexToBytes(Parts[1]);
  
  KeyBytes := TEncoding.UTF8.GetBytes(APassword + GetDynamicKey);
  
  // 获取AES解密上下文
  if not CryptAcquireContext(hProv, nil, MS_ENH_RSA_AES_PROV, PROV_RSA_AES, CRYPT_VERIFYCONTEXT) then
    raise Exception.Create('获取AES解密上下文失败');
  
  try
    // 创建哈希对象用于密钥派生
    if not CryptCreateHash(hProv, CALG_SHA_256, 0, 0, hHash) then
      raise Exception.Create('创建哈希对象失败');
    
    try
      // 添加密钥数据到哈希
      if not CryptHashData(hHash, @KeyBytes[0], Length(KeyBytes), 0) then
        raise Exception.Create('哈希密钥数据失败');
      
      // 从哈希派生AES-256密钥
      if not CryptDeriveKey(hProv, CALG_AES_256, hHash, CRYPT_EXPORTABLE, hKey) then
        raise Exception.Create('派生AES密钥失败');
      
      try
        // 设置CBC模式
        var Mode: DWORD := CRYPT_MODE_CBC;
        if not CryptSetKeyParam(hKey, KP_MODE, @Mode, 0) then
          raise Exception.Create('设置CBC模式失败');
        
        // 设置IV
        if not CryptSetKeyParam(hKey, KP_IV, @IV[0], 0) then
          raise Exception.Create('设置IV失败');
        
        // 准备解密数据
        DecryptedData := Copy(EncryptedBytes);
        DataLen := Length(DecryptedData);
        
        // 执行AES-256-CBC解密
        if not CryptDecrypt(hKey, 0, True, 0, @DecryptedData[0], DataLen) then
          raise Exception.Create('AES解密失败');
        
        // 调整解密数据长度并移除填充
        SetLength(DecryptedData, DataLen);
        DecryptedData := UnpadData(DecryptedData);
        Result := TEncoding.UTF8.GetString(DecryptedData);
        
      finally
        CryptDestroyKey(hKey);
      end;
    finally
      CryptDestroyHash(hHash);
    end;
  finally
    CryptReleaseContext(hProv, 0);
  end;
end;

// 二进制数据加密
class function TBasicProtection.EncryptBinaryData(const AData: TBytes; const APassword: string = '@2241114'): TBytes;
var
  hProv: HCRYPTPROV;
  hKey: HCRYPTKEY;
  hHash: HCRYPTHASH;
  EncryptedData, IV, PaddedData: TBytes;
  DataLen: DWORD;
  KeyBytes: TBytes;
begin
  if Length(AData) = 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  KeyBytes := TEncoding.UTF8.GetBytes(APassword + GetDynamicKey);
  IV := GenerateRandomIV;
  
  if not CryptAcquireContext(hProv, nil, MS_ENH_RSA_AES_PROV, PROV_RSA_AES, CRYPT_VERIFYCONTEXT) then
    raise Exception.Create('获取AES加密上下文失败');
  
  try
    if not CryptCreateHash(hProv, CALG_SHA_256, 0, 0, hHash) then
      raise Exception.Create('创建哈希对象失败');
    
    try
      if not CryptHashData(hHash, @KeyBytes[0], Length(KeyBytes), 0) then
        raise Exception.Create('哈希密钥数据失败');
      
      if not CryptDeriveKey(hProv, CALG_AES_256, hHash, CRYPT_EXPORTABLE, hKey) then
        raise Exception.Create('派生AES密钥失败');
      
      try
        var Mode: DWORD := CRYPT_MODE_CBC;
        if not CryptSetKeyParam(hKey, KP_MODE, @Mode, 0) then
          raise Exception.Create('设置CBC模式失败');
        
        if not CryptSetKeyParam(hKey, KP_IV, @IV[0], 0) then
          raise Exception.Create('设置IV失败');
        
        // 手动填充数据
        PaddedData := PadData(AData, 16);
        SetLength(EncryptedData, Length(PaddedData));
        Move(PaddedData[0], EncryptedData[0], Length(PaddedData));
        DataLen := Length(EncryptedData);
        
        if not CryptEncrypt(hKey, 0, True, 0, @EncryptedData[0], DataLen, Length(EncryptedData)) then
          raise Exception.Create('AES加密失败');
        
        SetLength(EncryptedData, DataLen);
        
        // 返回 IV + 加密数据
        SetLength(Result, Length(IV) + Length(EncryptedData));
        Move(IV[0], Result[0], Length(IV));
        Move(EncryptedData[0], Result[Length(IV)], Length(EncryptedData));
        
      finally
        CryptDestroyKey(hKey);
      end;
    finally
      CryptDestroyHash(hHash);
    end;
  finally
    CryptReleaseContext(hProv, 0);
  end;
end;

// 二进制数据解密
class function TBasicProtection.DecryptBinaryData(const AEncryptedData: TBytes; const APassword: string = '@2241114'): TBytes;
var
  hProv: HCRYPTPROV;
  hKey: HCRYPTKEY;
  hHash: HCRYPTHASH;
  IV, EncryptedBytes, DecryptedData: TBytes;
  DataLen: DWORD;
  KeyBytes: TBytes;
begin
  SetLength(Result, 0);
  
  if Length(AEncryptedData) < 16 then // 至少需要IV
    Exit;
  
  // 分离IV和加密数据
  SetLength(IV, 16);
  Move(AEncryptedData[0], IV[0], 16);
  
  SetLength(EncryptedBytes, Length(AEncryptedData) - 16);
  Move(AEncryptedData[16], EncryptedBytes[0], Length(EncryptedBytes));
  
  KeyBytes := TEncoding.UTF8.GetBytes(APassword + GetDynamicKey);
  
  if not CryptAcquireContext(hProv, nil, MS_ENH_RSA_AES_PROV, PROV_RSA_AES, CRYPT_VERIFYCONTEXT) then
    raise Exception.Create('获取AES解密上下文失败');
  
  try
    if not CryptCreateHash(hProv, CALG_SHA_256, 0, 0, hHash) then
      raise Exception.Create('创建哈希对象失败');
    
    try
      if not CryptHashData(hHash, @KeyBytes[0], Length(KeyBytes), 0) then
        raise Exception.Create('哈希密钥数据失败');
      
      if not CryptDeriveKey(hProv, CALG_AES_256, hHash, CRYPT_EXPORTABLE, hKey) then
        raise Exception.Create('派生AES密钥失败');
      
      try
        var Mode: DWORD := CRYPT_MODE_CBC;
        if not CryptSetKeyParam(hKey, KP_MODE, @Mode, 0) then
          raise Exception.Create('设置CBC模式失败');
        
        if not CryptSetKeyParam(hKey, KP_IV, @IV[0], 0) then
          raise Exception.Create('设置IV失败');
        
        DecryptedData := Copy(EncryptedBytes);
        DataLen := Length(DecryptedData);
        
        if not CryptDecrypt(hKey, 0, True, 0, @DecryptedData[0], DataLen) then
          raise Exception.Create('AES解密失败');
        
        SetLength(DecryptedData, DataLen);
        Result := UnpadData(DecryptedData);
        
      finally
        CryptDestroyKey(hKey);
      end;
    finally
      CryptDestroyHash(hHash);
    end;
  finally
    CryptReleaseContext(hProv, 0);
  end;
end;

// HMAC-SHA256校验
class function TBasicProtection.CalculateHMAC(const AData: string; const APassword: string = '@2241114'): string;
var
  Key: string;
begin
  Key := APassword + GetDynamicKey + '_HMAC';
  
  // 使用SHA256计算HMAC
  Result := THashSHA2.GetHMAC(AData, Key);
end;

// 数据完整性验证
class function TBasicProtection.VerifyDataIntegrity(const AData, AHMAC: string; const APassword: string = '@2241114'): Boolean;
begin
  Result := SameText(CalculateHMAC(AData, APassword), AHMAC);
end;

// 文件哈希计算
class function TBasicProtection.CalculateFileHash(const AFileName: string): string;
var
  FileStream: TFileStream;
begin
  if not TFile.Exists(AFileName) then
    raise Exception.Create('文件不存在: ' + AFileName);

  FileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    Result := THashSHA2.GetHashString(FileStream);
  finally
    FileStream.Free;
  end;
end;

// 数据哈希计算
class function TBasicProtection.CalculateDataHash(const AData: TBytes): string;
var
  DataString: string;
begin
  DataString := TEncoding.UTF8.GetString(AData);
  Result := THashSHA2.GetHashString(DataString);
end;

// 字节数组转十六进制字符串
class function TBasicProtection.BytesToHex(const ABytes: TBytes): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Length(ABytes) - 1 do
    Result := Result + IntToHex(ABytes[I], 2);
end;

// 十六进制字符串转字节数组
class function TBasicProtection.HexToBytes(const AHex: string): TBytes;
var
  I: Integer;
begin
  SetLength(Result, Length(AHex) div 2);
  for I := 0 to Length(Result) - 1 do
    Result[I] := StrToInt('$' + Copy(AHex, I * 2 + 1, 2));
end;

end.
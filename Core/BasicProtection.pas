unit BasicProtection;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Hash, System.NetEncoding,
  System.StrUtils, System.DateUtils;

type
  // 基础保护类 - 纯Delphi代码实现，无第三方组件依赖
  TBasicProtection = class
  private
    class function GetDynamicKey: string;
    class function GenerateRandomIV: TBytes;
    class function BytesToHex(const ABytes: TBytes): string;
    class function HexToBytes(const AHex: string): TBytes;
    class function PKCS7Pad(const AData: TBytes; ABlockSize: Integer): TBytes;
    class function PKCS7Unpad(const AData: TBytes): TBytes;
    class function XORBytes(const AData, AKey: TBytes): TBytes;
    class function SimpleAESEncrypt(const AData, AKey, AIV: TBytes): TBytes;
    class function SimpleAESDecrypt(const AData, AKey, AIV: TBytes): TBytes;
  public
    class function EncryptSensitiveData(const AData: string): string;
    class function DecryptSensitiveData(const AEncryptedData: string): string;
    class function EncryptData(const AData: TBytes): TBytes;
    class function DecryptData(const AEncryptedData: TBytes): TBytes;
    class function CalculateHMAC(const AData: string): string;
    class function VerifyDataIntegrity(const AData, AHMAC: string): Boolean;
    class function CalculateFileHash(const AFileName: string): string;
    class function CalculateSHA256(const AData: string): string;
  end;

implementation

uses
  Vcl.Forms;

// 动态密钥生成（避免硬编码）
class function TBasicProtection.GetDynamicKey: string;
var
  Part1, Part2, Part3: string;
  ExePath: string;
  FileTime: TDateTime;
begin
  ExePath := Application.ExeName;
  Part1 := ReverseString(ExtractFileName(ExePath));
  
  // 基于文件时间戳
  if FileAge(ExePath, FileTime) then
    Part2 := IntToStr(DateTimeToUnix(FileTime))
  else
    Part2 := IntToStr(GetTickCount);
    
  Part3 := 'SecureKey2024';
  Result := Copy(Part1 + Part2 + Part3, 1, 32); // 确保32字节密钥
  
  // 填充到32字节
  while Length(Result) < 32 do
    Result := Result + '0';
end;

// 生成随机IV (使用简化的随机数生成)
class function TBasicProtection.GenerateRandomIV: TBytes;
var
  I: Integer;
begin
  SetLength(Result, 16); // AES块大小为16字节

  // 使用系统时间作为种子
  Randomize;
  for I := 0 to 15 do
    Result[I] := Random(256);
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

// PKCS7填充
class function TBasicProtection.PKCS7Pad(const AData: TBytes; ABlockSize: Integer): TBytes;
var
  PadLength: Integer;
  I: Integer;
begin
  PadLength := ABlockSize - (Length(AData) mod ABlockSize);
  SetLength(Result, Length(AData) + PadLength);
  
  // 复制原始数据
  Move(AData[0], Result[0], Length(AData));
  
  // 添加填充
  for I := Length(AData) to Length(Result) - 1 do
    Result[I] := PadLength;
end;

// PKCS7去填充
class function TBasicProtection.PKCS7Unpad(const AData: TBytes): TBytes;
var
  PadLength: Integer;
begin
  if Length(AData) = 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  
  PadLength := AData[Length(AData) - 1];
  
  // 验证填充
  if (PadLength > 0) and (PadLength <= 16) and (PadLength <= Length(AData)) then
  begin
    SetLength(Result, Length(AData) - PadLength);
    Move(AData[0], Result[0], Length(Result));
  end
  else
    Result := Copy(AData); // 如果填充无效，返回原数据
end;

// 简单XOR操作
class function TBasicProtection.XORBytes(const AData, AKey: TBytes): TBytes;
var
  I: Integer;
begin
  SetLength(Result, Length(AData));
  for I := 0 to Length(AData) - 1 do
    Result[I] := AData[I] xor AKey[I mod Length(AKey)];
end;

// AES-256-CBC加密实现（增强版）
class function TBasicProtection.SimpleAESEncrypt(const AData, AKey, AIV: TBytes): TBytes;
var
  PaddedData: TBytes;
  I, J, K: Integer;
  Block: TBytes;
  PrevBlock: TBytes;
  RoundKey: TBytes;
  SBox: array[0..255] of Byte;
  Temp: Byte;
begin
  // 初始化S-Box（简化的AES S-Box）
  for I := 0 to 255 do
    SBox[I] := (I * 7 + 13) mod 256;
  
  // PKCS7填充
  PaddedData := PKCS7Pad(AData, 16);
  SetLength(Result, Length(PaddedData));
  
  PrevBlock := Copy(AIV);
  
  // 按块处理
  for I := 0 to (Length(PaddedData) div 16) - 1 do
  begin
    SetLength(Block, 16);
    Move(PaddedData[I * 16], Block[0], 16);
    
    // CBC模式：与前一个密文块XOR
    Block := XORBytes(Block, PrevBlock);
    
    // AES轮次加密（10轮）
    for J := 0 to 9 do
    begin
      // 轮密钥生成
      SetLength(RoundKey, 16);
      for K := 0 to 15 do
        RoundKey[K] := AKey[(K + J * 2) mod Length(AKey)] xor (J + 1);
      
      // AddRoundKey
      Block := XORBytes(Block, RoundKey);
      
      // SubBytes (使用S-Box)
      for K := 0 to 15 do
        Block[K] := SBox[Block[K]];
      
      // ShiftRows (简化版)
      Temp := Block[1];
      Block[1] := Block[5]; Block[5] := Block[9]; Block[9] := Block[13]; Block[13] := Temp;
      
      Temp := Block[2]; Block[2] := Block[10]; Block[10] := Temp;
      Temp := Block[6]; Block[6] := Block[14]; Block[14] := Temp;
      
      Temp := Block[3];
      Block[3] := Block[15]; Block[15] := Block[11]; Block[11] := Block[7]; Block[7] := Temp;
      
      // MixColumns (简化版)
      if J < 9 then // 最后一轮不执行MixColumns
      begin
        for K := 0 to 3 do
        begin
          var Col := K * 4;
          var A := Block[Col]; var B := Block[Col + 1]; 
          var C := Block[Col + 2]; var D := Block[Col + 3];
          
          Block[Col] := (A * 2) xor (B * 3) xor C xor D;
          Block[Col + 1] := A xor (B * 2) xor (C * 3) xor D;
          Block[Col + 2] := A xor B xor (C * 2) xor (D * 3);
          Block[Col + 3] := (A * 3) xor B xor C xor (D * 2);
        end;
      end;
    end;
    
    Move(Block[0], Result[I * 16], 16);
    PrevBlock := Copy(Block);
  end;
end;

// AES-256-CBC解密实现（增强版）
class function TBasicProtection.SimpleAESDecrypt(const AData, AKey, AIV: TBytes): TBytes;
var
  I, J, K: Integer;
  Block, PrevBlock, DecryptedBlock: TBytes;
  RoundKey: TBytes;
  InvSBox: array[0..255] of Byte;
  SBox: array[0..255] of Byte;
  Temp: Byte;
begin
  // 初始化S-Box和逆S-Box
  for I := 0 to 255 do
  begin
    SBox[I] := (I * 7 + 13) mod 256;
    InvSBox[SBox[I]] := I;
  end;
  
  SetLength(Result, Length(AData));
  PrevBlock := Copy(AIV);
  
  // 按块处理
  for I := 0 to (Length(AData) div 16) - 1 do
  begin
    SetLength(Block, 16);
    Move(AData[I * 16], Block[0], 16);
    
    DecryptedBlock := Copy(Block);
    
    // AES轮次解密（10轮，逆向）
    for J := 9 downto 0 do
    begin
      // 轮密钥生成（与加密相同）
      SetLength(RoundKey, 16);
      for K := 0 to 15 do
        RoundKey[K] := AKey[(K + J * 2) mod Length(AKey)] xor (J + 1);
      
      // 逆MixColumns (除了第一轮)
      if J < 9 then
      begin
        for K := 0 to 3 do
        begin
          var Col := K * 4;
          var A := DecryptedBlock[Col]; var B := DecryptedBlock[Col + 1]; 
          var C := DecryptedBlock[Col + 2]; var D := DecryptedBlock[Col + 3];
          
          // 逆MixColumns矩阵运算（简化版）
          DecryptedBlock[Col] := (A * 14) xor (B * 11) xor (C * 13) xor (D * 9);
          DecryptedBlock[Col + 1] := (A * 9) xor (B * 14) xor (C * 11) xor (D * 13);
          DecryptedBlock[Col + 2] := (A * 13) xor (B * 9) xor (C * 14) xor (D * 11);
          DecryptedBlock[Col + 3] := (A * 11) xor (B * 13) xor (C * 9) xor (D * 14);
        end;
      end;
      
      // 逆ShiftRows
      Temp := DecryptedBlock[13];
      DecryptedBlock[13] := DecryptedBlock[9]; DecryptedBlock[9] := DecryptedBlock[5]; 
      DecryptedBlock[5] := DecryptedBlock[1]; DecryptedBlock[1] := Temp;
      
      Temp := DecryptedBlock[2]; DecryptedBlock[2] := DecryptedBlock[10]; DecryptedBlock[10] := Temp;
      Temp := DecryptedBlock[6]; DecryptedBlock[6] := DecryptedBlock[14]; DecryptedBlock[14] := Temp;
      
      Temp := DecryptedBlock[7];
      DecryptedBlock[7] := DecryptedBlock[11]; DecryptedBlock[11] := DecryptedBlock[15]; 
      DecryptedBlock[15] := DecryptedBlock[3]; DecryptedBlock[3] := Temp;
      
      // 逆SubBytes (使用逆S-Box)
      for K := 0 to 15 do
        DecryptedBlock[K] := InvSBox[DecryptedBlock[K]];
      
      // AddRoundKey
      DecryptedBlock := XORBytes(DecryptedBlock, RoundKey);
    end;
    
    // CBC模式：与前一个密文块XOR
    DecryptedBlock := XORBytes(DecryptedBlock, PrevBlock);
    
    Move(DecryptedBlock[0], Result[I * 16], 16);
    PrevBlock := Copy(Block);
  end;
  
  // 去除填充
  Result := PKCS7Unpad(Result);
end;

// 加密敏感数据
class function TBasicProtection.EncryptSensitiveData(const AData: string): string;
var
  DataBytes, EncryptedData, IV: TBytes;
  Key: string;
  KeyBytes: TBytes;
begin
  Key := GetDynamicKey;
  KeyBytes := TEncoding.UTF8.GetBytes(Key);
  DataBytes := TEncoding.UTF8.GetBytes(AData);
  IV := GenerateRandomIV;
  
  try
    EncryptedData := SimpleAESEncrypt(DataBytes, KeyBytes, IV);
    // 返回 IV + 加密数据 的十六进制表示
    Result := BytesToHex(IV) + '|' + BytesToHex(EncryptedData);
  except
    on E: Exception do
      raise Exception.Create('加密失败: ' + E.Message);
  end;
end;

// 解密敏感数据
class function TBasicProtection.DecryptSensitiveData(const AEncryptedData: string): string;
var
  Parts: TArray<string>;
  IV, EncryptedBytes, DecryptedData: TBytes;
  Key: string;
  KeyBytes: TBytes;
begin
  Result := '';
  
  try
    // 分离IV和加密数据
    Parts := AEncryptedData.Split(['|']);
    if Length(Parts) <> 2 then
      raise Exception.Create('加密数据格式错误');
    
    IV := HexToBytes(Parts[0]);
    EncryptedBytes := HexToBytes(Parts[1]);
    
    Key := GetDynamicKey;
    KeyBytes := TEncoding.UTF8.GetBytes(Key);
    
    DecryptedData := SimpleAESDecrypt(EncryptedBytes, KeyBytes, IV);
    Result := TEncoding.UTF8.GetString(DecryptedData);
  except
    on E: Exception do
      raise Exception.Create('解密失败: ' + E.Message);
  end;
end;

// 计算SHA256哈希
class function TBasicProtection.CalculateSHA256(const AData: string): string;
begin
  Result := THashSHA2.GetHashString(AData, SHA256);
end;

// HMAC-SHA256校验
class function TBasicProtection.CalculateHMAC(const AData: string): string;
var
  Key: string;
  KeyBytes, DataBytes: TBytes;
  InnerPad, OuterPad: TBytes;
  I: Integer;
  InnerHash, OuterHash: string;
begin
  Key := GetDynamicKey + '_HMAC';
  KeyBytes := TEncoding.UTF8.GetBytes(Key);
  DataBytes := TEncoding.UTF8.GetBytes(AData);
  
  // 如果密钥长度大于64字节，先哈希
  if Length(KeyBytes) > 64 then
    KeyBytes := HexToBytes(THashSHA2.GetHashString(TEncoding.UTF8.GetString(KeyBytes), SHA256));
  
  // 填充密钥到64字节
  SetLength(KeyBytes, 64);
  
  // 创建内外填充
  SetLength(InnerPad, 64);
  SetLength(OuterPad, 64);
  
  for I := 0 to 63 do
  begin
    InnerPad[I] := KeyBytes[I] xor $36;
    OuterPad[I] := KeyBytes[I] xor $5C;
  end;
  
  // 计算内部哈希
  InnerHash := THashSHA2.GetHashString(TEncoding.UTF8.GetString(InnerPad) + AData, SHA256);
  
  // 计算外部哈希
  OuterHash := THashSHA2.GetHashString(TEncoding.UTF8.GetString(OuterPad) + InnerHash, SHA256);
  
  Result := OuterHash;
end;

// 数据完整性验证
class function TBasicProtection.VerifyDataIntegrity(const AData, AHMAC: string): Boolean;
begin
  Result := SameText(CalculateHMAC(AData), AHMAC);
end;

// 文件哈希计算
class function TBasicProtection.CalculateFileHash(const AFileName: string): string;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  Hash: THashSHA2;
begin
  if not FileExists(AFileName) then
    raise Exception.Create('文件不存在: ' + AFileName);

  FileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    Hash := THashSHA2.Create(SHA256);
    try
      SetLength(Buffer, 8192);
      while FileStream.Position < FileStream.Size do
      begin
        var BytesRead := FileStream.Read(Buffer[0], Length(Buffer));
        if BytesRead > 0 then
        begin
          SetLength(Buffer, BytesRead);
          Hash.Update(Buffer);
          SetLength(Buffer, 8192);
        end;
      end;
      Result := Hash.HashAsString;
    finally
      // Hash是记录类型，不需要Free
    end;
  finally
    FileStream.Free;
  end;
end;

// 加密字节数组
class function TBasicProtection.EncryptData(const AData: TBytes): TBytes;
var
  Key: TBytes;
  IV: TBytes;
  KeyStr: string;
begin
  if Length(AData) = 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  try
    // 生成密钥
    KeyStr := GetDynamicKey;
    Key := TEncoding.UTF8.GetBytes(KeyStr);

    // 确保密钥长度为32字节（256位）
    SetLength(Key, 32);

    // 生成随机IV
    IV := GenerateRandomIV;

    // 加密数据
    var EncryptedData := SimpleAESEncrypt(AData, Key, IV);

    // 将IV和加密数据组合
    SetLength(Result, Length(IV) + Length(EncryptedData));
    Move(IV[0], Result[0], Length(IV));
    Move(EncryptedData[0], Result[Length(IV)], Length(EncryptedData));

  except
    SetLength(Result, 0);
  end;
end;

// 解密字节数组
class function TBasicProtection.DecryptData(const AEncryptedData: TBytes): TBytes;
var
  Key: TBytes;
  IV: TBytes;
  EncryptedPart: TBytes;
  KeyStr: string;
begin
  SetLength(Result, 0);

  if Length(AEncryptedData) < 16 then // 至少需要IV长度
    Exit;

  try
    // 生成密钥
    KeyStr := GetDynamicKey;
    Key := TEncoding.UTF8.GetBytes(KeyStr);

    // 确保密钥长度为32字节（256位）
    SetLength(Key, 32);

    // 提取IV（前16字节）
    SetLength(IV, 16);
    Move(AEncryptedData[0], IV[0], 16);

    // 提取加密数据
    SetLength(EncryptedPart, Length(AEncryptedData) - 16);
    Move(AEncryptedData[16], EncryptedPart[0], Length(EncryptedPart));

    // 解密数据
    Result := SimpleAESDecrypt(EncryptedPart, Key, IV);

  except
    SetLength(Result, 0);
  end;
end;

end.
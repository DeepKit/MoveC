unit uPBKDF2;

{
  PBKDF2 密钥派生函数模块 - Password-Based Key Derivation Function 2
  
  功能：
  - 标准 PBKDF2-HMAC-SHA256 实现
  - 可配置迭代次数（推荐 >= 100000）
  - 安全的随机盐生成
  - 密钥长度可配置
  
  符合规范：
  - RFC 2898 (PKCS #5)
  - NIST SP 800-132
  
  作者: MoveC Team
  版本: 1.0
  日期: 2025-12-02
}

interface

uses
  System.SysUtils, System.Classes, System.Hash;

type
  // PBKDF2 配置
  TPBKDF2Config = record
    Iterations: Integer;    // 迭代次数（推荐 >= 100000）
    DerivedKeyLength: Integer; // 派生密钥长度（字节）
  end;

  // PBKDF2 实现类
  TPBKDF2 = class
  private
    class function HMAC_SHA256(const Key, Data: TBytes): TBytes;
    class function XorBytes(const A, B: TBytes): TBytes;
    class function F(const Password, Salt: TBytes; Iterations, BlockNum: Integer): TBytes;
    class function IntToBytesBE(Value: Integer): TBytes;
  public
    // 生成随机盐（16字节）
    class function GenerateSalt: TBytes;
    class function GenerateSaltHex: string;
    
    // PBKDF2 派生密钥
    class function DeriveKey(const Password, Salt: TBytes; Iterations, DerivedKeyLength: Integer): TBytes; overload;
    class function DeriveKey(const Password, Salt: string; Iterations, DerivedKeyLength: Integer): TBytes; overload;
    
    // 便捷方法
    class function DeriveKeyHex(const Password, Salt: string; Iterations, DerivedKeyLength: Integer): string;
    class function DeriveKey256(const Password, Salt: string; Iterations: Integer = 100000): TBytes;
    class function DeriveKey256Hex(const Password, Salt: string; Iterations: Integer = 100000): string;
    
    // 验证密码
    class function VerifyPassword(const Password, Salt, ExpectedKeyHex: string;
      Iterations, DerivedKeyLength: Integer): Boolean;
    
    // 默认配置
    class function GetDefaultConfig: TPBKDF2Config;
    
    // 工具方法
    class function BytesToHex(const B: TBytes): string;
    class function HexToBytes(const Hex: string): TBytes;
  end;

implementation

uses
  Winapi.Windows;

const
  SHA256_BLOCK_SIZE = 64;
  SHA256_DIGEST_SIZE = 32;

{ TPBKDF2 }

class function TPBKDF2.GetDefaultConfig: TPBKDF2Config;
begin
  Result.Iterations := 100000;  // OWASP 推荐值
  Result.DerivedKeyLength := 32; // 256 bits
end;

class function TPBKDF2.GenerateSalt: TBytes;
var
  Provider: HCRYPTPROV;
begin
  SetLength(Result, 16); // 128 bits
  
  // 使用 Windows CSPRNG
  if CryptAcquireContext(@Provider, nil, nil, PROV_RSA_AES, CRYPT_VERIFYCONTEXT) then
  begin
    try
      if not CryptGenRandom(Provider, 16, @Result[0]) then
        raise Exception.Create('随机数生成失败');
    finally
      CryptReleaseContext(Provider, 0);
    end;
  end
  else
  begin
    // 回退方案：使用时间和随机数
    var Seed: Int64 := GetTickCount64 xor Int64(@Result);
    for var I := 0 to 15 do
    begin
      Randomize;
      Result[I] := Random(256) xor ((Seed shr (I * 4)) and $FF);
    end;
  end;
end;

class function TPBKDF2.GenerateSaltHex: string;
begin
  Result := BytesToHex(GenerateSalt);
end;

class function TPBKDF2.BytesToHex(const B: TBytes): string;
const
  HexChars: array[0..15] of Char = '0123456789ABCDEF';
var
  I: Integer;
begin
  SetLength(Result, Length(B) * 2);
  for I := 0 to High(B) do
  begin
    Result[I * 2 + 1] := HexChars[(B[I] shr 4) and $F];
    Result[I * 2 + 2] := HexChars[B[I] and $F];
  end;
end;

class function TPBKDF2.HexToBytes(const Hex: string): TBytes;
var
  I, N: Integer;
begin
  N := Length(Hex) div 2;
  SetLength(Result, N);
  for I := 0 to N - 1 do
    Result[I] := StrToInt('$' + Copy(Hex, I * 2 + 1, 2));
end;

class function TPBKDF2.IntToBytesBE(Value: Integer): TBytes;
begin
  SetLength(Result, 4);
  Result[0] := (Value shr 24) and $FF;
  Result[1] := (Value shr 16) and $FF;
  Result[2] := (Value shr 8) and $FF;
  Result[3] := Value and $FF;
end;

class function TPBKDF2.HMAC_SHA256(const Key, Data: TBytes): TBytes;
var
  KeyPad: TBytes;
  IKeyPad, OKeyPad: TBytes;
  Hash1, Hash2: THashSHA2;
  I: Integer;
begin
  // 如果密钥大于块大小，先哈希
  if Length(Key) > SHA256_BLOCK_SIZE then
  begin
    Hash1 := THashSHA2.Create(SHA256);
    Hash1.Update(Key);
    KeyPad := Hash1.HashAsBytes;
  end
  else
    KeyPad := Copy(Key);
  
  // 填充密钥到块大小
  SetLength(KeyPad, SHA256_BLOCK_SIZE);
  
  // 计算内外填充
  SetLength(IKeyPad, SHA256_BLOCK_SIZE);
  SetLength(OKeyPad, SHA256_BLOCK_SIZE);
  
  for I := 0 to SHA256_BLOCK_SIZE - 1 do
  begin
    IKeyPad[I] := KeyPad[I] xor $36;
    OKeyPad[I] := KeyPad[I] xor $5C;
  end;
  
  // 内层哈希: H(IKeyPad || Data)
  Hash1 := THashSHA2.Create(SHA256);
  Hash1.Update(IKeyPad);
  Hash1.Update(Data);
  var InnerHash := Hash1.HashAsBytes;
  
  // 外层哈希: H(OKeyPad || InnerHash)
  Hash2 := THashSHA2.Create(SHA256);
  Hash2.Update(OKeyPad);
  Hash2.Update(InnerHash);
  Result := Hash2.HashAsBytes;
end;

class function TPBKDF2.XorBytes(const A, B: TBytes): TBytes;
var
  I: Integer;
begin
  if Length(A) <> Length(B) then
    raise Exception.Create('XOR操作要求数组长度相同');
    
  SetLength(Result, Length(A));
  for I := 0 to High(A) do
    Result[I] := A[I] xor B[I];
end;

class function TPBKDF2.F(const Password, Salt: TBytes; Iterations, BlockNum: Integer): TBytes;
var
  U, Acc: TBytes;
  I: Integer;
  BlockBytes: TBytes;
begin
  // U_1 = PRF(Password, Salt || INT_32_BE(BlockNum))
  BlockBytes := IntToBytesBE(BlockNum);
  SetLength(U, Length(Salt) + 4);
  Move(Salt[0], U[0], Length(Salt));
  Move(BlockBytes[0], U[Length(Salt)], 4);
  
  U := HMAC_SHA256(Password, U);
  Acc := Copy(U);
  
  // U_i = PRF(Password, U_{i-1})
  // Result = U_1 XOR U_2 XOR ... XOR U_Iterations
  for I := 2 to Iterations do
  begin
    U := HMAC_SHA256(Password, U);
    Acc := XorBytes(Acc, U);
  end;
  
  Result := Acc;
end;

class function TPBKDF2.DeriveKey(const Password, Salt: TBytes;
  Iterations, DerivedKeyLength: Integer): TBytes;
var
  BlockCount: Integer;
  DerivedKey: TBytes;
  Block: TBytes;
  I, Remaining: Integer;
begin
  if Iterations < 1 then
    raise Exception.Create('迭代次数必须大于0');
  if DerivedKeyLength < 1 then
    raise Exception.Create('派生密钥长度必须大于0');
  
  // 计算需要的块数
  BlockCount := (DerivedKeyLength + SHA256_DIGEST_SIZE - 1) div SHA256_DIGEST_SIZE;
  
  SetLength(DerivedKey, 0);
  
  // 生成每个块
  for I := 1 to BlockCount do
  begin
    Block := F(Password, Salt, Iterations, I);
    SetLength(DerivedKey, Length(DerivedKey) + Length(Block));
    Move(Block[0], DerivedKey[Length(DerivedKey) - Length(Block)], Length(Block));
  end;
  
  // 截取到请求的长度
  SetLength(Result, DerivedKeyLength);
  Move(DerivedKey[0], Result[0], DerivedKeyLength);
end;

class function TPBKDF2.DeriveKey(const Password, Salt: string;
  Iterations, DerivedKeyLength: Integer): TBytes;
begin
  Result := DeriveKey(
    TEncoding.UTF8.GetBytes(Password),
    TEncoding.UTF8.GetBytes(Salt),
    Iterations,
    DerivedKeyLength
  );
end;

class function TPBKDF2.DeriveKeyHex(const Password, Salt: string;
  Iterations, DerivedKeyLength: Integer): string;
begin
  Result := BytesToHex(DeriveKey(Password, Salt, Iterations, DerivedKeyLength));
end;

class function TPBKDF2.DeriveKey256(const Password, Salt: string; Iterations: Integer): TBytes;
begin
  Result := DeriveKey(Password, Salt, Iterations, 32);
end;

class function TPBKDF2.DeriveKey256Hex(const Password, Salt: string; Iterations: Integer): string;
begin
  Result := BytesToHex(DeriveKey256(Password, Salt, Iterations));
end;

class function TPBKDF2.VerifyPassword(const Password, Salt, ExpectedKeyHex: string;
  Iterations, DerivedKeyLength: Integer): Boolean;
var
  DerivedKeyHex: string;
begin
  DerivedKeyHex := DeriveKeyHex(Password, Salt, Iterations, DerivedKeyLength);
  Result := SameText(DerivedKeyHex, ExpectedKeyHex);
end;

end.

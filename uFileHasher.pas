unit uFileHasher;

{
  文件哈希计算单元
  
  功能：
  1. 计算文件的 MD5 哈希值
  2. 计算文件的 SHA-256 哈希值
  3. HMAC-SHA256 签名计算
  4. 支持大文件分块计算
  
  使用方法：
  - TFileHasher.ComputeMD5(FilePath) - 计算 MD5
  - TFileHasher.ComputeSHA256(FilePath) - 计算 SHA-256
  - TFileHasher.ComputeHMACSHA256(FilePath, Key) - HMAC-SHA256
  
  更新记录：
  - 2025-12-02: 添加 HMAC-SHA256 支持
}

interface

uses
  System.SysUtils, System.Classes, System.Hash, System.IOUtils;

type
  TFileHasher = class
  private
    class function HMACPad(const Key: TBytes; PadByte: Byte): TBytes; static;
  public
    // 计算文件的 MD5 哈希值
    class function ComputeMD5(const FilePath: string): string;
    
    // 计算文件的 SHA-256 哈希值
    class function ComputeSHA256(const FilePath: string): string;
    
    // 计算字节数组的 MD5 哈希值
    class function ComputeMD5FromBytes(const Data: TBytes): string;
    
    // 计算字节数组的 SHA-256 哈希值
    class function ComputeSHA256FromBytes(const Data: TBytes): string;
    
    // HMAC-SHA256 计算（字节数组）
    class function ComputeHMACSHA256(const Data: TBytes; const Key: string): string; overload;
    class function ComputeHMACSHA256(const Data: TBytes; const Key: TBytes): string; overload;
    
    // HMAC-SHA256 计算（文件）
    class function ComputeFileHMACSHA256(const FilePath: string; const Key: string): string;
    
    // HMAC-SHA256 验证
    class function VerifyHMACSHA256(const Data: TBytes; const Key: string; 
      const ExpectedHMAC: string): Boolean;
    class function VerifyFileHMACSHA256(const FilePath: string; const Key: string;
      const ExpectedHMAC: string): Boolean;
    
    // 比较两个文件是否相同（基于 SHA-256）
    class function FilesAreIdentical(const FilePath1, FilePath2: string): Boolean;
  end;

implementation

const
  // 缓冲区大小（1MB）
  BUFFER_SIZE = 1024 * 1024;

class function TFileHasher.ComputeMD5(const FilePath: string): string;
var
  FileStream: TFileStream;
  Hash: THashMD5;
  Buffer: TBytes;
  BytesRead: Integer;
begin
  Result := '';
  
  if not TFile.Exists(FilePath) then
    Exit;
    
  try
    FileStream := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyNone);
    try
      Hash := THashMD5.Create;
      SetLength(Buffer, BUFFER_SIZE);
      
      repeat
        BytesRead := FileStream.Read(Buffer[0], BUFFER_SIZE);
        if BytesRead > 0 then
          Hash.Update(Buffer, BytesRead);
      until BytesRead < BUFFER_SIZE;
      
      Result := Hash.HashAsString;
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
      Result := '';
  end;
end;

class function TFileHasher.ComputeSHA256(const FilePath: string): string;
var
  FileStream: TFileStream;
  Hash: THashSHA2;
  Buffer: TBytes;
  BytesRead: Integer;
begin
  Result := '';
  
  if not TFile.Exists(FilePath) then
    Exit;
    
  try
    FileStream := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyNone);
    try
      Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
      SetLength(Buffer, BUFFER_SIZE);
      
      repeat
        BytesRead := FileStream.Read(Buffer[0], BUFFER_SIZE);
        if BytesRead > 0 then
          Hash.Update(Buffer, BytesRead);
      until BytesRead < BUFFER_SIZE;
      
      Result := Hash.HashAsString;
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
      Result := '';
  end;
end;

class function TFileHasher.ComputeMD5FromBytes(const Data: TBytes): string;
var
  Hash: THashMD5;
begin
  Hash := THashMD5.Create;
  Hash.Update(Data);
  Result := Hash.HashAsString;
end;

class function TFileHasher.ComputeSHA256FromBytes(const Data: TBytes): string;
var
  Hash: THashSHA2;
begin
  Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
  Hash.Update(Data);
  Result := Hash.HashAsString;
end;

class function TFileHasher.FilesAreIdentical(const FilePath1, FilePath2: string): Boolean;
var
  Hash1, Hash2: string;
begin
  Result := False;
  
  // 首先检查文件是否存在
  if not TFile.Exists(FilePath1) or not TFile.Exists(FilePath2) then
    Exit;
    
  // 比较文件大小
  if TFile.GetSize(FilePath1) <> TFile.GetSize(FilePath2) then
    Exit;
    
  // 比较哈希值
  Hash1 := ComputeSHA256(FilePath1);
  Hash2 := ComputeSHA256(FilePath2);
  
  Result := (Hash1 <> '') and (Hash2 <> '') and SameText(Hash1, Hash2);
end;

{ HMAC-SHA256 实现 }

class function TFileHasher.HMACPad(const Key: TBytes; PadByte: Byte): TBytes;
const
  BLOCK_SIZE = 64;  // SHA256 块大小
var
  I: Integer;
begin
  SetLength(Result, BLOCK_SIZE);
  for I := 0 to BLOCK_SIZE - 1 do
  begin
    if I < Length(Key) then
      Result[I] := Key[I] xor PadByte
    else
      Result[I] := PadByte;
  end;
end;

class function TFileHasher.ComputeHMACSHA256(const Data: TBytes; const Key: string): string;
begin
  Result := ComputeHMACSHA256(Data, TEncoding.UTF8.GetBytes(Key));
end;

class function TFileHasher.ComputeHMACSHA256(const Data: TBytes; const Key: TBytes): string;
const
  BLOCK_SIZE = 64;  // SHA256 块大小
  IPAD = $36;
  OPAD = $5C;
var
  WorkingKey: TBytes;
  InnerPad, OuterPad: TBytes;
  InnerData, OuterData: TBytes;
  InnerHash: TBytes;
  Hash: THashSHA2;
begin
  Result := '';
  
  try
    // 如果密钥太长，先哈希
    if Length(Key) > BLOCK_SIZE then
    begin
      Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
      Hash.Update(Key);
      WorkingKey := Hash.HashAsBytes;
    end
    else
    begin
      SetLength(WorkingKey, Length(Key));
      Move(Key[0], WorkingKey[0], Length(Key));
    end;
    
    // 生成内层和外层填充
    InnerPad := HMACPad(WorkingKey, IPAD);
    OuterPad := HMACPad(WorkingKey, OPAD);
    
    // 内层哈希: SHA256(innerPad || data)
    SetLength(InnerData, Length(InnerPad) + Length(Data));
    Move(InnerPad[0], InnerData[0], Length(InnerPad));
    if Length(Data) > 0 then
      Move(Data[0], InnerData[Length(InnerPad)], Length(Data));
    
    Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
    Hash.Update(InnerData);
    InnerHash := Hash.HashAsBytes;
    
    // 外层哈希: SHA256(outerPad || innerHash)
    SetLength(OuterData, Length(OuterPad) + Length(InnerHash));
    Move(OuterPad[0], OuterData[0], Length(OuterPad));
    Move(InnerHash[0], OuterData[Length(OuterPad)], Length(InnerHash));
    
    Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
    Hash.Update(OuterData);
    Result := Hash.HashAsString;
  except
    Result := '';
  end;
end;

class function TFileHasher.ComputeFileHMACSHA256(const FilePath: string; 
  const Key: string): string;
var
  FileStream: TFileStream;
  FileData: TBytes;
begin
  Result := '';
  
  if not TFile.Exists(FilePath) then
    Exit;
    
  try
    FileStream := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyNone);
    try
      SetLength(FileData, FileStream.Size);
      if FileStream.Size > 0 then
        FileStream.ReadBuffer(FileData[0], FileStream.Size);
      Result := ComputeHMACSHA256(FileData, Key);
    finally
      FileStream.Free;
    end;
  except
    Result := '';
  end;
end;

class function TFileHasher.VerifyHMACSHA256(const Data: TBytes; const Key: string;
  const ExpectedHMAC: string): Boolean;
var
  ComputedHMAC: string;
begin
  ComputedHMAC := ComputeHMACSHA256(Data, Key);
  Result := (ComputedHMAC <> '') and SameText(ComputedHMAC, ExpectedHMAC);
end;

class function TFileHasher.VerifyFileHMACSHA256(const FilePath: string; 
  const Key: string; const ExpectedHMAC: string): Boolean;
var
  ComputedHMAC: string;
begin
  ComputedHMAC := ComputeFileHMACSHA256(FilePath, Key);
  Result := (ComputedHMAC <> '') and SameText(ComputedHMAC, ExpectedHMAC);
end;

end.

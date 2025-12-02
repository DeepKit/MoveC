unit uFileHasher;

{
  文件哈希计算单元
  
  功能：
  1. 计算文件的 MD5 哈希值
  2. 计算文件的 SHA-256 哈希值
  3. 支持大文件分块计算
  
  使用方法：
  - TFileHasher.ComputeMD5(FilePath) - 计算 MD5
  - TFileHasher.ComputeSHA256(FilePath) - 计算 SHA-256
}

interface

uses
  System.SysUtils, System.Classes, System.Hash, System.IOUtils;

type
  TFileHasher = class
  public
    // 计算文件的 MD5 哈希值
    class function ComputeMD5(const FilePath: string): string;
    
    // 计算文件的 SHA-256 哈希值
    class function ComputeSHA256(const FilePath: string): string;
    
    // 计算字节数组的 MD5 哈希值
    class function ComputeMD5FromBytes(const Data: TBytes): string;
    
    // 计算字节数组的 SHA-256 哈希值
    class function ComputeSHA256FromBytes(const Data: TBytes): string;
    
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

end.

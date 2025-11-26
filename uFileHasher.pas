unit uFileHasher;

interface

uses
  System.SysUtils, System.Classes, System.Hash, System.Math;

type
  // 哈希计算选项
  THashOption = (
    hoFullHash,       // 全量哈希
    hoSampleHash,     // 抽样哈希（头部+尾部）
    hoQuickHash       // 快速哈希（仅头部）
  );

  // 文件哈希器
  TFileHasher = class
  public
    // 计算文件 SHA-256 哈希
    class function ComputeSHA256(const AFilePath: string; 
      AOption: THashOption = hoFullHash): string;
    
    // 验证文件哈希
    class function VerifyFile(const AFilePath, AExpectedHash: string;
      AOption: THashOption = hoFullHash): Boolean;
    
    // 比较两个文件是否相同
    class function CompareFiles(const AFile1, AFile2: string;
      AOption: THashOption = hoFullHash): Boolean;
  end;

implementation

uses
  System.IOUtils;

const
  BUFFER_SIZE = 65536;         // 64KB 缓冲区
  SAMPLE_SIZE = 1048576;       // 抽样大小 1MB
  QUICK_HASH_SIZE = 65536;     // 快速哈希 64KB

{ TFileHasher }

class function TFileHasher.ComputeSHA256(const AFilePath: string; 
  AOption: THashOption): string;
var
  FileStream: TFileStream;
  Buffer: TBytes;
  BytesRead: Integer;
  HashSHA2: THashSHA2;
  FileSize: Int64;
  ReadSize: Int64;
  HeadSize, TailSize: Int64;
begin
  Result := '';
  
  if not TFile.Exists(AFilePath) then
    raise Exception.CreateFmt('文件不存在: %s', [AFilePath]);

  try
    FileStream := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyNone);
    try
      FileSize := FileStream.Size;
      HashSHA2 := THashSHA2.Create(SHA256);
      SetLength(Buffer, BUFFER_SIZE);

      case AOption of
        hoFullHash:
        begin
          // 全量哈希：读取整个文件
          repeat
            BytesRead := FileStream.Read(Buffer[0], BUFFER_SIZE);
            if BytesRead > 0 then
              HashSHA2.Update(Buffer, BytesRead);
          until BytesRead = 0;
        end;

        hoSampleHash:
        begin
          // 抽样哈希：读取头部和尾部各 SAMPLE_SIZE
          if FileSize <= SAMPLE_SIZE * 2 then
          begin
            // 文件太小，使用全量哈希
            repeat
              BytesRead := FileStream.Read(Buffer[0], BUFFER_SIZE);
              if BytesRead > 0 then
                HashSHA2.Update(Buffer, BytesRead);
            until BytesRead = 0;
          end
          else
          begin
            // 读取头部
            ReadSize := 0;
            while (ReadSize < SAMPLE_SIZE) do
            begin
              BytesRead := FileStream.Read(Buffer[0], 
                Min(BUFFER_SIZE, SAMPLE_SIZE - ReadSize));
              if BytesRead > 0 then
              begin
                HashSHA2.Update(Buffer, BytesRead);
                Inc(ReadSize, BytesRead);
              end
              else
                Break;
            end;

            // 跳转到尾部
            FileStream.Seek(-SAMPLE_SIZE, soEnd);
            
            // 读取尾部
            ReadSize := 0;
            while (ReadSize < SAMPLE_SIZE) do
            begin
              BytesRead := FileStream.Read(Buffer[0], 
                Min(BUFFER_SIZE, SAMPLE_SIZE - ReadSize));
              if BytesRead > 0 then
              begin
                HashSHA2.Update(Buffer, BytesRead);
                Inc(ReadSize, BytesRead);
              end
              else
                Break;
            end;
          end;
        end;

        hoQuickHash:
        begin
          // 快速哈希：仅读取头部 QUICK_HASH_SIZE
          ReadSize := Min(FileSize, QUICK_HASH_SIZE);
          BytesRead := FileStream.Read(Buffer[0], ReadSize);
          if BytesRead > 0 then
            HashSHA2.Update(Buffer, BytesRead);
        end;
      end;

      Result := HashSHA2.HashAsString;
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      raise Exception.CreateFmt('计算文件哈希失败 [%s]: %s', 
        [AFilePath, E.Message]);
    end;
  end;
end;

class function TFileHasher.VerifyFile(const AFilePath, AExpectedHash: string;
  AOption: THashOption): Boolean;
var
  ActualHash: string;
begin
  try
    ActualHash := ComputeSHA256(AFilePath, AOption);
    Result := SameText(ActualHash, AExpectedHash);
  except
    Result := False;
  end;
end;

class function TFileHasher.CompareFiles(const AFile1, AFile2: string;
  AOption: THashOption): Boolean;
var
  Hash1, Hash2: string;
begin
  try
    // 首先比较文件大小
    if TFile.GetSize(AFile1) <> TFile.GetSize(AFile2) then
    begin
      Result := False;
      Exit;
    end;

    // 计算并比较哈希
    Hash1 := ComputeSHA256(AFile1, AOption);
    Hash2 := ComputeSHA256(AFile2, AOption);
    Result := SameText(Hash1, Hash2);
  except
    Result := False;
  end;
end;

end.

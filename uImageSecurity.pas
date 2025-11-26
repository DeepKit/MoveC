unit uImageSecurity;

interface

uses
  System.SysUtils, System.Classes, System.Hash, System.NetEncoding,
  Vcl.Dialogs, Winapi.ShellAPI, Winapi.Windows;

type
  TImageSecurity = class
  private
    class function GetEncryptionKey: string;
    class function SimpleXOREncrypt(const Data: TBytes; const Key: string): TBytes;
    class function SimpleXORDecrypt(const Data: TBytes; const Key: string): TBytes;
  public
    // MD5计算
    class function CalculateMD5(const Data: TBytes): string;
    
    // 加密解密
    class function EncryptImageData(const ImageData: TBytes): TBytes;
    class function DecryptImageData(const EncryptedData: TBytes): TBytes;
    
    // MD5校验
    class function VerifyImageIntegrity(const DecryptedData: TBytes; const ExpectedMD5: string): Boolean;
    
    // 安全响应
    class procedure HandleSecurityViolation(const ImageKey: string; const Reason: string);
  end;

implementation

const
  // 简单的加密密钥（实际项目中应该使用更复杂的密钥管理）
  ENCRYPTION_KEY = 'MoveC_Image_Security_2025';
  
  // 官网下载地址
  DOWNLOAD_URL = 'https://your-website.com/download';

class function TImageSecurity.GetEncryptionKey: string;
begin
  Result := ENCRYPTION_KEY;
end;

class function TImageSecurity.SimpleXOREncrypt(const Data: TBytes; const Key: string): TBytes;
var
  I: Integer;
  KeyBytes: TBytes;
  KeyIndex: Integer;
begin
  SetLength(Result, Length(Data));
  KeyBytes := TEncoding.UTF8.GetBytes(Key);
  KeyIndex := 0;
  
  for I := 0 to High(Data) do
  begin
    Result[I] := Data[I] xor KeyBytes[KeyIndex];
    KeyIndex := (KeyIndex + 1) mod Length(KeyBytes);
  end;
end;

class function TImageSecurity.SimpleXORDecrypt(const Data: TBytes; const Key: string): TBytes;
begin
  // XOR加密是对称的，解密和加密使用相同算法
  Result := SimpleXOREncrypt(Data, Key);
end;

class function TImageSecurity.CalculateMD5(const Data: TBytes): string;
var
  Hash: THashMD5;
begin
  Hash := THashMD5.Create;
  Hash.Update(Data);
  Result := Hash.HashAsString;
end;

class function TImageSecurity.EncryptImageData(const ImageData: TBytes): TBytes;
begin
  Result := SimpleXOREncrypt(ImageData, GetEncryptionKey);
end;

class function TImageSecurity.DecryptImageData(const EncryptedData: TBytes): TBytes;
begin
  Result := SimpleXORDecrypt(EncryptedData, GetEncryptionKey);
end;

class function TImageSecurity.VerifyImageIntegrity(const DecryptedData: TBytes; const ExpectedMD5: string): Boolean;
var
  ActualMD5: string;
begin
  ActualMD5 := CalculateMD5(DecryptedData);
  Result := SameText(ActualMD5, ExpectedMD5);
end;

class procedure TImageSecurity.HandleSecurityViolation(const ImageKey: string; const Reason: string);
var
  ErrorMsg: string;
  Response: Integer;
begin
  ErrorMsg := Format('安全检查失败！'#13#10#13#10 +
    '图像: %s'#13#10 +
    '原因: %s'#13#10#13#10 +
    '检测到程序文件可能被篡改，为了您的安全，程序将退出。'#13#10 +
    '请从官方网站下载最新版本。'#13#10#13#10 +
    '是否现在访问官方下载页面？', [ImageKey, Reason]);
    
  Response := MessageBox(0, PChar(ErrorMsg), '安全警告', MB_YESNO or MB_ICONERROR or MB_TOPMOST);
  
  if Response = IDYES then
  begin
    // 打开官方下载页面
    ShellExecute(0, 'open', PChar(DOWNLOAD_URL), nil, nil, SW_SHOWNORMAL);
  end;
  
  // 强制退出程序
  ExitProcess(1);
end;

end.

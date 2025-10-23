unit uAntiTamperPackage;

{
  防篡改机制打包模块
  
  功能：
  1. 图像数据加密/解密
  2. MD5完整性校验
  3. 篡改检测和安全响应
  4. 数据库表结构管理
  
  使用方法：
  1. 在项目中引用此单元
  2. 调用 TAntiTamperPackage.SetupDatabase() 初始化数据库
  3. 使用 TAntiTamperPackage.SaveSecureImage() 保存加密图像
  4. 使用 TAntiTamperPackage.LoadSecureImage() 加载并校验图像
  
  依赖：
  - FireDAC组件
  - System.Hash单元
}

interface

uses
  System.SysUtils, System.Classes, System.Hash, System.NetEncoding,
  Vcl.Dialogs, Vcl.Graphics, Vcl.ExtCtrls, Winapi.ShellAPI, Winapi.Windows,
  FireDAC.Comp.Client, FireDAC.Stan.Param, Data.DB;

type
  // 安全配置
  TAntiTamperConfig = record
    EncryptionKey: string;        // 加密密钥
    DownloadURL: string;          // 官网下载地址
    TableName: string;            // 数据库表名
    EnableLogging: Boolean;       // 是否启用日志
    LogFileName: string;          // 日志文件名
  end;

  // 防篡改包主类
  TAntiTamperPackage = class
  private
    class var FConfig: TAntiTamperConfig;
    class var FInitialized: Boolean;
    
    // 内部方法
    class function SimpleXOREncrypt(const Data: TBytes; const Key: string): TBytes;
    class function SimpleXORDecrypt(const Data: TBytes; const Key: string): TBytes;
    class procedure WriteLog(const AMessage: string);
    
  public
    // 初始化配置
    class procedure Initialize(const AConfig: TAntiTamperConfig);
    
    // 数据库表结构管理
    class function SetupDatabase(AConnection: TFDConnection): Boolean;
    class function UpgradeDatabase(AConnection: TFDConnection): Boolean;
    
    // MD5计算
    class function CalculateMD5(const Data: TBytes): string;
    
    // 加密解密
    class function EncryptImageData(const ImageData: TBytes): TBytes;
    class function DecryptImageData(const EncryptedData: TBytes): TBytes;
    
    // MD5校验
    class function VerifyImageIntegrity(const DecryptedData: TBytes; const ExpectedMD5: string): Boolean;
    
    // 安全图像操作
    class function SaveSecureImage(AConnection: TFDConnection; const AImageKey: string; 
      const AImageData: TBytes; const AAddressText: string = ''; const ADescription: string = ''): Boolean;
    class function LoadSecureImage(ATable: TFDTable; const AImageKey: string; 
      AImage: TImage; out AAddressText: string): Boolean;
    
    // 安全响应
    class procedure HandleSecurityViolation(const ImageKey: string; const Reason: string);
    
    // 工具方法
    class function GetDefaultConfig: TAntiTamperConfig;
  end;

implementation

// 默认配置
class function TAntiTamperPackage.GetDefaultConfig: TAntiTamperConfig;
begin
  Result.EncryptionKey := 'Default_AntiTamper_Key_2025';
  Result.DownloadURL := 'https://your-website.com/download';
  Result.TableName := 'images';
  Result.EnableLogging := True;
  Result.LogFileName := 'antitamper_debug.log';
end;

class procedure TAntiTamperPackage.Initialize(const AConfig: TAntiTamperConfig);
begin
  FConfig := AConfig;
  FInitialized := True;
  WriteLog('防篡改包初始化完成');
end;

class procedure TAntiTamperPackage.WriteLog(const AMessage: string);
var
  LogFile: TextFile;
begin
  if not FInitialized or not FConfig.EnableLogging then
    Exit;
    
  try
    AssignFile(LogFile, FConfig.LogFileName);
    if FileExists(FConfig.LogFileName) then
      Append(LogFile)
    else
      Rewrite(LogFile);
    WriteLn(LogFile, Format('[%s] %s', [DateTimeToStr(Now), AMessage]));
    CloseFile(LogFile);
  except
  end;
end;

class function TAntiTamperPackage.SimpleXOREncrypt(const Data: TBytes; const Key: string): TBytes;
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

class function TAntiTamperPackage.SimpleXORDecrypt(const Data: TBytes; const Key: string): TBytes;
begin
  // XOR加密是对称的，解密和加密使用相同算法
  Result := SimpleXOREncrypt(Data, Key);
end;

class function TAntiTamperPackage.CalculateMD5(const Data: TBytes): string;
var
  Hash: THashMD5;
begin
  Hash := THashMD5.Create;
  Hash.Update(Data);
  Result := Hash.HashAsString;
end;

class function TAntiTamperPackage.EncryptImageData(const ImageData: TBytes): TBytes;
begin
  if not FInitialized then
    raise Exception.Create('防篡改包未初始化');
  Result := SimpleXOREncrypt(ImageData, FConfig.EncryptionKey);
end;

class function TAntiTamperPackage.DecryptImageData(const EncryptedData: TBytes): TBytes;
begin
  if not FInitialized then
    raise Exception.Create('防篡改包未初始化');
  Result := SimpleXORDecrypt(EncryptedData, FConfig.EncryptionKey);
end;

class function TAntiTamperPackage.VerifyImageIntegrity(const DecryptedData: TBytes; const ExpectedMD5: string): Boolean;
var
  ActualMD5: string;
begin
  ActualMD5 := CalculateMD5(DecryptedData);
  Result := SameText(ActualMD5, ExpectedMD5);
  
  if not Result then
    WriteLog(Format('MD5校验失败: 期望=%s, 实际=%s', [ExpectedMD5, ActualMD5]));
end;

class function TAntiTamperPackage.SetupDatabase(AConnection: TFDConnection): Boolean;
var
  Query: TFDQuery;
begin
  Result := False;
  try
    Query := TFDQuery.Create(nil);
    try
      Query.Connection := AConnection;
      
      // 创建表结构
      Query.SQL.Text :=
        'CREATE TABLE IF NOT EXISTS ' + FConfig.TableName + ' (' +
        '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
        '  image_key TEXT NOT NULL UNIQUE,' +
        '  image_data BLOB NOT NULL,' +
        '  address_text TEXT,' +
        '  description TEXT,' +
        '  md5_hash TEXT NOT NULL,' +
        '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,' +
        '  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
        ')';
      Query.ExecSQL;
      
      WriteLog('防篡改数据表创建成功');
      Result := True;
      
    finally
      Query.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLog('创建防篡改数据表失败: ' + E.Message);
      Result := False;
    end;
  end;
end;

class function TAntiTamperPackage.UpgradeDatabase(AConnection: TFDConnection): Boolean;
var
  Query: TFDQuery;
begin
  Result := False;
  try
    Query := TFDQuery.Create(nil);
    try
      Query.Connection := AConnection;
      
      // 为现有表添加md5_hash字段
      try
        Query.SQL.Text := 'ALTER TABLE ' + FConfig.TableName + ' ADD COLUMN md5_hash TEXT';
        Query.ExecSQL;
        WriteLog('md5_hash字段添加成功');
      except
        WriteLog('md5_hash字段可能已存在');
      end;
      
      Result := True;
      
    finally
      Query.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLog('升级数据库失败: ' + E.Message);
      Result := False;
    end;
  end;
end;

class function TAntiTamperPackage.SaveSecureImage(AConnection: TFDConnection; const AImageKey: string; 
  const AImageData: TBytes; const AAddressText: string; const ADescription: string): Boolean;
var
  Query: TFDQuery;
  EncryptedData: TBytes;
  OriginalMD5: string;
  RecordExists: Boolean;
begin
  Result := False;
  try
    if Length(AImageData) = 0 then
    begin
      WriteLog('图像数据为空: ' + AImageKey);
      Exit;
    end;
    
    // 计算原始图像数据的MD5
    OriginalMD5 := CalculateMD5(AImageData);
    WriteLog(Format('图像 %s 的MD5: %s', [AImageKey, OriginalMD5]));
    
    // 加密图像数据
    EncryptedData := EncryptImageData(AImageData);
    
    Query := TFDQuery.Create(nil);
    try
      Query.Connection := AConnection;
      
      // 检查记录是否存在
      Query.SQL.Text := 'SELECT COUNT(*) as cnt FROM ' + FConfig.TableName + ' WHERE image_key = :key';
      Query.ParamByName('key').AsString := AImageKey;
      Query.Open;
      RecordExists := Query.FieldByName('cnt').AsInteger > 0;
      Query.Close;
      
      if RecordExists then
      begin
        // 更新现有记录
        Query.SQL.Text :=
          'UPDATE ' + FConfig.TableName + ' SET image_data = :data, address_text = :addr, description = :desc, md5_hash = :md5, updated_at = CURRENT_TIMESTAMP ' +
          'WHERE image_key = :key';
      end
      else
      begin
        // 插入新记录
        Query.SQL.Text :=
          'INSERT INTO ' + FConfig.TableName + ' (image_key, image_data, address_text, description, md5_hash) ' +
          'VALUES (:key, :data, :addr, :desc, :md5)';
      end;

      Query.ParamByName('key').AsString := AImageKey;
      Query.ParamByName('data').AsBytes := EncryptedData;
      Query.ParamByName('addr').AsString := AAddressText;
      Query.ParamByName('desc').AsString := ADescription;
      Query.ParamByName('md5').AsString := OriginalMD5;
      
      Query.ExecSQL;
      WriteLog(Format('安全图像保存成功: %s', [AImageKey]));
      Result := True;
      
    finally
      Query.Free;
    end;
    
  except
    on E: Exception do
    begin
      WriteLog(Format('保存安全图像失败: %s - %s', [AImageKey, E.Message]));
      Result := False;
    end;
  end;
end;

class function TAntiTamperPackage.LoadSecureImage(ATable: TFDTable; const AImageKey: string; 
  AImage: TImage; out AAddressText: string): Boolean;
var
  EncryptedData: TBytes;
  DecryptedData: TBytes;
  ExpectedMD5: string;
  MemoryStream: TMemoryStream;
begin
  Result := False;
  AAddressText := '';
  
  try
    if not Assigned(AImage) then
    begin
      WriteLog('Image控件未分配: ' + AImageKey);
      Exit;
    end;
    
    if not ATable.Active then
    begin
      WriteLog('数据表未激活: ' + AImageKey);
      Exit;
    end;
    
    // 查找记录
    if ATable.Locate('image_key', AImageKey, []) then
    begin
      WriteLog('在数据库中找到记录: ' + AImageKey);
      
      // 获取字段
      var ImageField := ATable.FieldByName('image_data');
      var AddressField := ATable.FieldByName('address_text');
      var MD5Field := ATable.FieldByName('md5_hash');
      
      if not ImageField.IsNull then
      begin
        MemoryStream := TMemoryStream.Create;
        try
          // 从Blob字段加载加密数据
          TBlobField(ImageField).SaveToStream(MemoryStream);
          MemoryStream.Position := 0;
          
          // 读取加密数据
          SetLength(EncryptedData, MemoryStream.Size);
          MemoryStream.ReadBuffer(EncryptedData[0], MemoryStream.Size);
          
          WriteLog(Format('加密数据长度: %d bytes - %s', [Length(EncryptedData), AImageKey]));
          
          // 解密数据
          DecryptedData := DecryptImageData(EncryptedData);
          WriteLog(Format('解密数据长度: %d bytes - %s', [Length(DecryptedData), AImageKey]));
          
          // MD5校验
          ExpectedMD5 := MD5Field.AsString;
          if not VerifyImageIntegrity(DecryptedData, ExpectedMD5) then
          begin
            WriteLog(Format('MD5校验失败: %s', [AImageKey]));
            HandleSecurityViolation(AImageKey, 'MD5校验失败，图像数据可能被篡改');
            Exit;
          end;
          
          WriteLog(Format('MD5校验通过: %s', [AImageKey]));
          
          // 从解密数据加载图像
          MemoryStream.Clear;
          MemoryStream.WriteBuffer(DecryptedData[0], Length(DecryptedData));
          MemoryStream.Position := 0;
          
          AImage.Picture.LoadFromStream(MemoryStream);
          WriteLog(Format('安全图像加载成功: %s, 尺寸: %dx%d', [AImageKey, AImage.Picture.Width, AImage.Picture.Height]));
          
          // 获取地址文本
          if not AddressField.IsNull then
            AAddressText := AddressField.AsString;
            
          Result := True;
          
        finally
          MemoryStream.Free;
        end;
      end
      else
      begin
        WriteLog('图像字段为空: ' + AImageKey);
      end;
    end
    else
    begin
      WriteLog('数据库中未找到记录: ' + AImageKey);
    end;
    
  except
    on E: Exception do
    begin
      WriteLog(Format('加载安全图像时出错: %s - %s', [AImageKey, E.Message]));
      Result := False;
    end;
  end;
end;

class procedure TAntiTamperPackage.HandleSecurityViolation(const ImageKey: string; const Reason: string);
var
  ErrorMsg: string;
  Response: Integer;
begin
  WriteLog(Format('安全违规: %s - %s', [ImageKey, Reason]));
  
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
    ShellExecute(0, 'open', PChar(FConfig.DownloadURL), nil, nil, SW_SHOWNORMAL);
  end;
  
  // 强制退出程序
  WriteLog('程序因安全违规退出');
  ExitProcess(1);
end;

class function TAntiTamperPackage.SetupDatabase(AConnection: TFDConnection): Boolean;
var
  Query: TFDQuery;
begin
  Result := False;
  try
    Query := TFDQuery.Create(nil);
    try
      Query.Connection := AConnection;

      // 创建表结构
      Query.SQL.Text :=
        'CREATE TABLE IF NOT EXISTS ' + FConfig.TableName + ' (' +
        '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
        '  image_key TEXT NOT NULL UNIQUE,' +
        '  image_data BLOB NOT NULL,' +
        '  address_text TEXT,' +
        '  description TEXT,' +
        '  md5_hash TEXT NOT NULL,' +
        '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,' +
        '  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
        ')';
      Query.ExecSQL;

      WriteLog('防篡改数据表创建成功');
      Result := True;

    finally
      Query.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLog('创建防篡改数据表失败: ' + E.Message);
      Result := False;
    end;
  end;
end;

class function TAntiTamperPackage.UpgradeDatabase(AConnection: TFDConnection): Boolean;
var
  Query: TFDQuery;
begin
  Result := False;
  try
    Query := TFDQuery.Create(nil);
    try
      Query.Connection := AConnection;

      // 为现有表添加md5_hash字段
      try
        Query.SQL.Text := 'ALTER TABLE ' + FConfig.TableName + ' ADD COLUMN md5_hash TEXT';
        Query.ExecSQL;
        WriteLog('md5_hash字段添加成功');
      except
        WriteLog('md5_hash字段可能已存在');
      end;

      Result := True;

    finally
      Query.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLog('升级数据库失败: ' + E.Message);
      Result := False;
    end;
  end;
end;

end.

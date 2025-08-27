unit uSQLiteDB;

interface

uses
  Windows, SysUtils, Classes, System.IOUtils, Data.DB,
  System.Hash, uBasicProtection;

type
  TSQLiteDatabase = class
  private
    FConnection: TFDConnection;
    FQuery: TFDQuery;
    FDatabasePath: string;
    FPassword: string;
    FConnected: Boolean;
    
    procedure InitializeDatabase;
    procedure CreateTables;
    procedure ExecuteSQL(const ASQL: string);
    function TableExists(const ATableName: string): Boolean;
    procedure LogError(const AMessage: string);
    procedure LogInfo(const AMessage: string);
    function GenerateDataHash(const AData: TBytes): string;
    function ValidateDataHash(const AData: TBytes; const AStoredHash: string): Boolean;
    
  public
    constructor Create(const ADatabasePath: string; const APassword: string = '@2241114');
    destructor Destroy; override;
    
    // 连接管理
    function Connect: Boolean;
    procedure Disconnect;
    function IsConnected: Boolean;
    
    // 图像数据操作
    function SaveImageData(const AImageKey: string; const AImageData: TBytes; const ADescription: string = ''): Boolean;
    function LoadImageData(const AImageKey: string; out AImageData: TBytes): Boolean;
    function ImageExists(const AImageKey: string): Boolean;
    function DeleteImage(const AImageKey: string): Boolean;
    
    // 文本数据操作
    function SaveTextData(const ATextKey: string; const ATextData: string; const ADescription: string = ''): Boolean;
    function LoadTextData(const ATextKey: string; out ATextData: string): Boolean;
    function TextExists(const ATextKey: string): Boolean;
    function DeleteText(const ATextKey: string): Boolean;
    
    // 数据完整性
    function ValidateAllData: Boolean;
    function GetDataStatistics: string;
    
    // 属性
    property DatabasePath: string read FDatabasePath;
    property Connected: Boolean read FConnected;
  end;

implementation

constructor TSQLiteDatabase.Create(const ADatabasePath: string; const APassword: string = '@2241114');
begin
  inherited Create;
  FDatabasePath := ADatabasePath;
  FPassword := APassword;
  FConnected := False;
  
  // 创建FireDAC组件
  FConnection := TFDConnection.Create(nil);
  FQuery := TFDQuery.Create(nil);
  FQuery.Connection := FConnection;
  
  // 初始化数据库
  InitializeDatabase;
  
  LogInfo('数据库对象创建完成: ' + FDatabasePath);
end;

destructor TSQLiteDatabase.Destroy;
begin
  try
    Disconnect;
    FQuery.Free;
    FConnection.Free;
  except
    // 忽略析构时的错误
  end;
  inherited;
end;

procedure TSQLiteDatabase.InitializeDatabase;
begin
  try
    // 配置SQLite连接
    FConnection.DriverName := 'SQLite';
    FConnection.Params.Clear;
    FConnection.Params.Add('Database=' + FDatabasePath);
    FConnection.Params.Add('LockingMode=Normal');
    FConnection.Params.Add('Synchronous=Normal');
    FConnection.Params.Add('JournalMode=WAL');
    FConnection.Params.Add('ForeignKeys=On');
    
    // 如果有密码，设置加密
    if FPassword <> '' then
    begin
      // 注意：FireDAC的SQLite加密需要商业版或特殊配置
      // 这里使用基本配置，实际加密在应用层处理
      FConnection.Params.Add('StringFormat=Unicode');
    end;
    
    // 连接到数据库
    if Connect then
    begin
      CreateTables;
      LogInfo('数据库初始化完成');
    end
    else
    begin
      LogError('数据库初始化失败');
    end;
    
  except
    on E: Exception do
    begin
      LogError('初始化数据库时发生异常: ' + E.Message);
      raise;
    end;
  end;
end;

function TSQLiteDatabase.Connect: Boolean;
begin
  Result := False;
  
  try
    if not FConnection.Connected then
    begin
      FConnection.Connected := True;
      FConnected := FConnection.Connected;
      
      if FConnected then
        LogInfo('数据库连接成功')
      else
        LogError('数据库连接失败');
    end
    else
    begin
      FConnected := True;
    end;
    
    Result := FConnected;
    
  except
    on E: Exception do
    begin
      LogError('连接数据库时发生异常: ' + E.Message);
      FConnected := False;
      Result := False;
    end;
  end;
end;

procedure TSQLiteDatabase.Disconnect;
begin
  try
    if FConnection.Connected then
    begin
      FConnection.Connected := False;
      FConnected := False;
      LogInfo('数据库连接已关闭');
    end;
  except
    on E: Exception do
    begin
      LogError('关闭数据库连接时发生异常: ' + E.Message);
    end;
  end;
end;

function TSQLiteDatabase.IsConnected: Boolean;
begin
  Result := FConnected and FConnection.Connected;
end;

procedure TSQLiteDatabase.CreateTables;
begin
  try
    LogInfo('开始创建数据库表');
    
    // 创建图像数据表
    if not TableExists('secure_images') then
    begin
      ExecuteSQL(
        'CREATE TABLE secure_images (' +
        '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
        '  image_key TEXT NOT NULL UNIQUE,' +
        '  encrypted_data BLOB NOT NULL,' +
        '  data_hash TEXT NOT NULL,' +
        '  description TEXT,' +
        '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,' +
        '  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
        ')'
      );
      LogInfo('创建图像数据表成功');
    end;
    
    // 创建文本数据表
    if not TableExists('secure_texts') then
    begin
      ExecuteSQL(
        'CREATE TABLE secure_texts (' +
        '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
        '  text_key TEXT NOT NULL UNIQUE,' +
        '  encrypted_data TEXT NOT NULL,' +
        '  data_hash TEXT NOT NULL,' +
        '  description TEXT,' +
        '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,' +
        '  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
        ')'
      );
      LogInfo('创建文本数据表成功');
    end;
    
    // 创建索引
    ExecuteSQL('CREATE INDEX IF NOT EXISTS idx_images_key ON secure_images(image_key)');
    ExecuteSQL('CREATE INDEX IF NOT EXISTS idx_texts_key ON secure_texts(text_key)');
    
    LogInfo('数据库表创建完成');
    
  except
    on E: Exception do
    begin
      LogError('创建数据库表时发生异常: ' + E.Message);
      raise;
    end;
  end;
end;

function TSQLiteDatabase.TableExists(const ATableName: string): Boolean;
begin
  Result := False;
  
  try
    FQuery.SQL.Text := 'SELECT name FROM sqlite_master WHERE type=''table'' AND name=:table_name';
    FQuery.ParamByName('table_name').AsString := ATableName;
    FQuery.Open;
    
    Result := not FQuery.IsEmpty;
    FQuery.Close;
    
  except
    on E: Exception do
    begin
      LogError('检查表是否存在时发生异常: ' + E.Message);
      Result := False;
    end;
  end;
end;

procedure TSQLiteDatabase.ExecuteSQL(const ASQL: string);
begin
  try
    FQuery.SQL.Text := ASQL;
    FQuery.ExecSQL;
  except
    on E: Exception do
    begin
      LogError('执行SQL时发生异常: ' + ASQL + ' - ' + E.Message);
      raise;
    end;
  end;
end;

function TSQLiteDatabase.SaveImageData(const AImageKey: string; const AImageData: TBytes; const ADescription: string = ''): Boolean;
var
  EncryptedData: TBytes;
  DataHash: string;
begin
  Result := False;
  
  try
    if not IsConnected then
      Exit;
    
    if Length(AImageData) = 0 then
    begin
      LogError('图像数据为空: ' + AImageKey);
      Exit;
    end;
    
    // 加密图像数据
    EncryptedData := TBasicProtection.EncryptBinaryData(AImageData, FPassword);
    
    // 计算原始数据哈希
    DataHash := GenerateDataHash(AImageData);
    
    // 检查是否已存在
    if ImageExists(AImageKey) then
    begin
      // 更新现有记录
      FQuery.SQL.Text := 
        'UPDATE secure_images SET ' +
        '  encrypted_data = :encrypted_data, ' +
        '  data_hash = :data_hash, ' +
        '  description = :description, ' +
        '  updated_at = CURRENT_TIMESTAMP ' +
        'WHERE image_key = :image_key';
    end
    else
    begin
      // 插入新记录
      FQuery.SQL.Text := 
        'INSERT INTO secure_images (image_key, encrypted_data, data_hash, description) ' +
        'VALUES (:image_key, :encrypted_data, :data_hash, :description)';
    end;
    
    FQuery.ParamByName('image_key').AsString := AImageKey;
    FQuery.ParamByName('encrypted_data').AsBlob := EncryptedData;
    FQuery.ParamByName('data_hash').AsString := DataHash;
    FQuery.ParamByName('description').AsString := ADescription;
    
    FQuery.ExecSQL;
    Result := True;
    
    LogInfo(Format('保存图像数据成功: %s (%d 字节)', [AImageKey, Length(AImageData)]));
    
  except
    on E: Exception do
    begin
      LogError('保存图像数据时发生异常: ' + AImageKey + ' - ' + E.Message);
      Result := False;
    end;
  end;
end;

function TSQLiteDatabase.LoadImageData(const AImageKey: string; out AImageData: TBytes): Boolean;
var
  EncryptedData: TBytes;
  StoredHash: string;
begin
  Result := False;
  SetLength(AImageData, 0);
  
  try
    if not IsConnected then
      Exit;
    
    FQuery.SQL.Text := 'SELECT encrypted_data, data_hash FROM secure_images WHERE image_key = :image_key';
    FQuery.ParamByName('image_key').AsString := AImageKey;
    FQuery.Open;
    
    if not FQuery.IsEmpty then
    begin
      // 读取加密数据
      EncryptedData := FQuery.FieldByName('encrypted_data').AsBytes;
      StoredHash := FQuery.FieldByName('data_hash').AsString;
      
      // 解密数据
      AImageData := TBasicProtection.DecryptBinaryData(EncryptedData, FPassword);
      
      // 验证数据完整性
      if ValidateDataHash(AImageData, StoredHash) then
      begin
        Result := True;
        LogInfo(Format('加载图像数据成功: %s (%d 字节)', [AImageKey, Length(AImageData)]));
      end
      else
      begin
        SetLength(AImageData, 0);
        LogError('图像数据完整性验证失败: ' + AImageKey);
      end;
    end
    else
    begin
      LogError('图像数据不存在: ' + AImageKey);
    end;
    
    FQuery.Close;
    
  except
    on E: Exception do
    begin
      LogError('加载图像数据时发生异常: ' + AImageKey + ' - ' + E.Message);
      Result := False;
      SetLength(AImageData, 0);
    end;
  end;
end;

function TSQLiteDatabase.SaveTextData(const ATextKey: string; const ATextData: string; const ADescription: string = ''): Boolean;
var
  EncryptedData: string;
  DataHash: string;
  TextBytes: TBytes;
begin
  Result := False;
  
  try
    if not IsConnected then
      Exit;
    
    if ATextData.Trim = '' then
    begin
      LogError('文本数据为空: ' + ATextKey);
      Exit;
    end;
    
    // 加密文本数据
    EncryptedData := TBasicProtection.EncryptSensitiveData(ATextData, FPassword);
    
    // 计算原始数据哈希
    TextBytes := TEncoding.UTF8.GetBytes(ATextData);
    DataHash := GenerateDataHash(TextBytes);
    
    // 检查是否已存在
    if TextExists(ATextKey) then
    begin
      // 更新现有记录
      FQuery.SQL.Text := 
        'UPDATE secure_texts SET ' +
        '  encrypted_data = :encrypted_data, ' +
        '  data_hash = :data_hash, ' +
        '  description = :description, ' +
        '  updated_at = CURRENT_TIMESTAMP ' +
        'WHERE text_key = :text_key';
    end
    else
    begin
      // 插入新记录
      FQuery.SQL.Text := 
        'INSERT INTO secure_texts (text_key, encrypted_data, data_hash, description) ' +
        'VALUES (:text_key, :encrypted_data, :data_hash, :description)';
    end;
    
    FQuery.ParamByName('text_key').AsString := ATextKey;
    FQuery.ParamByName('encrypted_data').AsString := EncryptedData;
    FQuery.ParamByName('data_hash').AsString := DataHash;
    FQuery.ParamByName('description').AsString := ADescription;
    
    FQuery.ExecSQL;
    Result := True;
    
    LogInfo(Format('保存文本数据成功: %s (%d 字符)', [ATextKey, Length(ATextData)]));
    
  except
    on E: Exception do
    begin
      LogError('保存文本数据时发生异常: ' + ATextKey + ' - ' + E.Message);
      Result := False;
    end;
  end;
end;

function TSQLiteDatabase.LoadTextData(const ATextKey: string; out ATextData: string): Boolean;
var
  EncryptedData: string;
  StoredHash: string;
  TextBytes: TBytes;
begin
  Result := False;
  ATextData := '';
  
  try
    if not IsConnected then
      Exit;
    
    FQuery.SQL.Text := 'SELECT encrypted_data, data_hash FROM secure_texts WHERE text_key = :text_key';
    FQuery.ParamByName('text_key').AsString := ATextKey;
    FQuery.Open;
    
    if not FQuery.IsEmpty then
    begin
      // 读取加密数据
      EncryptedData := FQuery.FieldByName('encrypted_data').AsString;
      StoredHash := FQuery.FieldByName('data_hash').AsString;
      
      // 解密数据
      ATextData := TBasicProtection.DecryptSensitiveData(EncryptedData, FPassword);
      
      // 验证数据完整性
      TextBytes := TEncoding.UTF8.GetBytes(ATextData);
      if ValidateDataHash(TextBytes, StoredHash) then
      begin
        Result := True;
        LogInfo(Format('加载文本数据成功: %s (%d 字符)', [ATextKey, Length(ATextData)]));
      end
      else
      begin
        ATextData := '';
        LogError('文本数据完整性验证失败: ' + ATextKey);
      end;
    end
    else
    begin
      LogError('文本数据不存在: ' + ATextKey);
    end;
    
    FQuery.Close;
    
  except
    on E: Exception do
    begin
      LogError('加载文本数据时发生异常: ' + ATextKey + ' - ' + E.Message);
      Result := False;
      ATextData := '';
    end;
  end;
end;

function TSQLiteDatabase.ImageExists(const AImageKey: string): Boolean;
begin
  Result := False;
  
  try
    if not IsConnected then
      Exit;
    
    FQuery.SQL.Text := 'SELECT COUNT(*) as cnt FROM secure_images WHERE image_key = :image_key';
    FQuery.ParamByName('image_key').AsString := AImageKey;
    FQuery.Open;
    
    Result := FQuery.FieldByName('cnt').AsInteger > 0;
    FQuery.Close;
    
  except
    on E: Exception do
    begin
      LogError('检查图像是否存在时发生异常: ' + AImageKey + ' - ' + E.Message);
      Result := False;
    end;
  end;
end;

function TSQLiteDatabase.TextExists(const ATextKey: string): Boolean;
begin
  Result := False;
  
  try
    if not IsConnected then
      Exit;
    
    FQuery.SQL.Text := 'SELECT COUNT(*) as cnt FROM secure_texts WHERE text_key = :text_key';
    FQuery.ParamByName('text_key').AsString := ATextKey;
    FQuery.Open;
    
    Result := FQuery.FieldByName('cnt').AsInteger > 0;
    FQuery.Close;
    
  except
    on E: Exception do
    begin
      LogError('检查文本是否存在时发生异常: ' + ATextKey + ' - ' + E.Message);
      Result := False;
    end;
  end;
end;

function TSQLiteDatabase.DeleteImage(const AImageKey: string): Boolean;
begin
  Result := False;
  
  try
    if not IsConnected then
      Exit;
    
    FQuery.SQL.Text := 'DELETE FROM secure_images WHERE image_key = :image_key';
    FQuery.ParamByName('image_key').AsString := AImageKey;
    FQuery.ExecSQL;
    
    Result := True;
    LogInfo('删除图像数据成功: ' + AImageKey);
    
  except
    on E: Exception do
    begin
      LogError('删除图像数据时发生异常: ' + AImageKey + ' - ' + E.Message);
      Result := False;
    end;
  end;
end;

function TSQLiteDatabase.DeleteText(const ATextKey: string): Boolean;
begin
  Result := False;
  
  try
    if not IsConnected then
      Exit;
    
    FQuery.SQL.Text := 'DELETE FROM secure_texts WHERE text_key = :text_key';
    FQuery.ParamByName('text_key').AsString := ATextKey;
    FQuery.ExecSQL;
    
    Result := True;
    LogInfo('删除文本数据成功: ' + ATextKey);
    
  except
    on E: Exception do
    begin
      LogError('删除文本数据时发生异常: ' + ATextKey + ' - ' + E.Message);
      Result := False;
    end;
  end;
end;

function TSQLiteDatabase.ValidateAllData: Boolean;
var
  ImageCount, TextCount: Integer;
  ValidImages, ValidTexts: Integer;
begin
  Result := False;
  ValidImages := 0;
  ValidTexts := 0;
  
  try
    if not IsConnected then
      Exit;
    
    LogInfo('开始验证所有数据完整性');
    
    // 验证图像数据
    FQuery.SQL.Text := 'SELECT image_key FROM secure_images';
    FQuery.Open;
    ImageCount := FQuery.RecordCount;
    
    FQuery.First;
    while not FQuery.Eof do
    begin
      var ImageData: TBytes;
      if LoadImageData(FQuery.FieldByName('image_key').AsString, ImageData) then
        Inc(ValidImages);
      FQuery.Next;
    end;
    FQuery.Close;
    
    // 验证文本数据
    FQuery.SQL.Text := 'SELECT text_key FROM secure_texts';
    FQuery.Open;
    TextCount := FQuery.RecordCount;
    
    FQuery.First;
    while not FQuery.Eof do
    begin
      var TextData: string;
      if LoadTextData(FQuery.FieldByName('text_key').AsString, TextData) then
        Inc(ValidTexts);
      FQuery.Next;
    end;
    FQuery.Close;
    
    Result := (ValidImages = ImageCount) and (ValidTexts = TextCount);
    
    LogInfo(Format('数据完整性验证完成: 图像 %d/%d, 文本 %d/%d', [ValidImages, ImageCount, ValidTexts, TextCount]));
    
  except
    on E: Exception do
    begin
      LogError('验证数据完整性时发生异常: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TSQLiteDatabase.GetDataStatistics: string;
var
  ImageCount, TextCount: Integer;
  DatabaseSize: Int64;
begin
  Result := '';
  
  try
    if not IsConnected then
    begin
      Result := '数据库未连接';
      Exit;
    end;
    
    // 获取图像数量
    FQuery.SQL.Text := 'SELECT COUNT(*) as cnt FROM secure_images';
    FQuery.Open;
    ImageCount := FQuery.FieldByName('cnt').AsInteger;
    FQuery.Close;
    
    // 获取文本数量
    FQuery.SQL.Text := 'SELECT COUNT(*) as cnt FROM secure_texts';
    FQuery.Open;
    TextCount := FQuery.FieldByName('cnt').AsInteger;
    FQuery.Close;
    
    // 获取数据库文件大小
    if TFile.Exists(FDatabasePath) then
      DatabaseSize := TFile.GetSize(FDatabasePath)
    else
      DatabaseSize := 0;
    
    Result := Format('数据库统计信息:' + sLineBreak +
                     '- 图像数量: %d' + sLineBreak +
                     '- 文本数量: %d' + sLineBreak +
                     '- 数据库大小: %.2f KB' + sLineBreak +
                     '- 数据库路径: %s',
                     [ImageCount, TextCount, DatabaseSize / 1024, FDatabasePath]);
    
  except
    on E: Exception do
    begin
      Result := '获取统计信息失败: ' + E.Message;
    end;
  end;
end;

function TSQLiteDatabase.GenerateDataHash(const AData: TBytes): string;
begin
  Result := TBasicProtection.CalculateDataHash(AData);
end;

function TSQLiteDatabase.ValidateDataHash(const AData: TBytes; const AStoredHash: string): Boolean;
var
  CalculatedHash: string;
begin
  CalculatedHash := GenerateDataHash(AData);
  Result := SameText(CalculatedHash, AStoredHash);
end;

procedure TSQLiteDatabase.LogError(const AMessage: string);
begin
  OutputDebugString(PChar('[ERROR] SQLiteDB: ' + AMessage));
end;

procedure TSQLiteDatabase.LogInfo(const AMessage: string);
begin
  OutputDebugString(PChar('[INFO] SQLiteDB: ' + AMessage));
end;

end.
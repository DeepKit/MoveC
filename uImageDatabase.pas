unit uImageDatabase;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Stan.Async,
  FireDAC.DApt, FireDAC.UI.Intf, FireDAC.VCLUI.Wait, FireDAC.Comp.UI,
  FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat,
  FireDAC.Stan.Param, System.Hash, System.NetEncoding, uBasicProtection, uImageSecurity;

function BytesToRawByteString(const ABytes: TBytes): RawByteString;

type
  TImageDatabase = class
  private
    FConnection: TFDConnection;
    FQuery: TFDQuery;
    FDatabasePath: string;
    FPassword: string;
    FConnected: Boolean;
    
    procedure InitializeDatabase;
    procedure CreateTables;
    procedure LogError(const AMessage: string);
    procedure LogInfo(const AMessage: string);
    
  public
    constructor Create(const ADatabasePath: string; const APassword: string = '@2241114');
    destructor Destroy; override;
    
    // 连接管理
    function Connect: Boolean;
    procedure Disconnect;
    function IsConnected: Boolean;
    
    // 图像数据操作
    function SaveImageData(const AImageKey: string; const AImageData: TBytes; const ADescription: string = ''; const AAddressText: string = ''): Boolean;
    function LoadImageData(const AImageKey: string; out AImageData: TBytes): Boolean;
    function LoadImageAndText(const AImageKey: string; out AImageData: TBytes; out AAddressText: string): Boolean;
    function ImageExists(const AImageKey: string): Boolean;
    function DeleteImage(const AImageKey: string): Boolean;
    function GetImageList: TStringList;

    // 获取项目根目录下的数据库路径
    class function GetProjectDatabasePath: string;
    
    // 属性
    property DatabasePath: string read FDatabasePath;
    property Connected: Boolean read FConnected;
  end;

implementation

function BytesToRawByteString(const ABytes: TBytes): RawByteString;
begin
  SetLength(Result, Length(ABytes));
  if Length(ABytes) > 0 then
    Move(ABytes[0], Result[1], Length(ABytes));
end;

constructor TImageDatabase.Create(const ADatabasePath: string; const APassword: string = '');
begin
  inherited Create;
  FDatabasePath := ADatabasePath;
  FPassword := APassword;
  FConnected := False;

  // 创建FireDAC组件
  FConnection := TFDConnection.Create(nil);
  FQuery := TFDQuery.Create(nil);
  FQuery.Connection := FConnection;

  // 预配置SQLite驱动
  FConnection.DriverName := 'SQLite';

  LogInfo('图像数据库对象创建完成: ' + FDatabasePath);
end;

destructor TImageDatabase.Destroy;
begin
  try
    Disconnect;
    FQuery.Free;
    FConnection.Free;
  except
    // 忽略析构时的错误
  end;
  LogInfo('图像数据库对象已销毁');
  inherited;
end;

procedure TImageDatabase.LogError(const AMessage: string);
begin
  // 简单的日志记录
  OutputDebugString(PChar('[ERROR] ' + AMessage));
  // 同时输出到控制台
  Writeln('[ERROR] ', AMessage);
end;

procedure TImageDatabase.LogInfo(const AMessage: string);
begin
  // 简单的日志记录
  OutputDebugString(PChar('[INFO] ' + AMessage));
  // 同时输出到控制台
  Writeln('[INFO] ', AMessage);
end;

// 旧的加密解密方法已删除，现在使用TImageSecurity类

procedure TImageDatabase.InitializeDatabase;
var
  DatabaseDir: string;
begin
  try
    // 确保数据库目录存在
    DatabaseDir := ExtractFilePath(FDatabasePath);
    if (DatabaseDir <> '') and not TDirectory.Exists(DatabaseDir) then
    begin
      TDirectory.CreateDirectory(DatabaseDir);
      LogInfo('创建数据库目录: ' + DatabaseDir);
    end;
    
    // 配置SQLite连接
    FConnection.DriverName := 'SQLite';
    FConnection.Params.Clear;
    FConnection.Params.Add('DriverID=SQLite');
    FConnection.Params.Add('Database=' + FDatabasePath);
    FConnection.Params.Add('LockingMode=Normal');
    FConnection.Params.Add('Synchronous=Normal');
    FConnection.Params.Add('JournalMode=WAL');
    FConnection.Params.Add('ForeignKeys=On');
    FConnection.Params.Add('StringFormat=Unicode');
    
    LogInfo('数据库配置完成');
    
  except
    on E: Exception do
    begin
      LogError('初始化数据库配置时发生异常: ' + E.Message);
      raise;
    end;
  end;
end;

function TImageDatabase.Connect: Boolean;
var
  RetryCount: Integer;
  WaitTime: Integer;
begin
  Result := False;
  RetryCount := 0;

  while (RetryCount < 3) and (not Result) do
  begin
    try
      // 如果已经连接，先断开
      if FConnection.Connected then
      begin
        FConnection.Connected := False;
        Sleep(100); // 等待连接完全关闭
      end;

      LogInfo(Format('尝试连接数据库 (第%d次)', [RetryCount + 1]));

      // 检查数据库文件是否存在
      if not TFile.Exists(FDatabasePath) then
      begin
        LogError('数据库文件不存在: ' + FDatabasePath);
        Break;
      end;

      // 检查文件是否可读写
      try
        var TestFile := TFileStream.Create(FDatabasePath, fmOpenReadWrite or fmShareDenyNone);
        TestFile.Free;
        LogInfo('数据库文件访问权限正常');
      except
        on E: Exception do
        begin
          LogError('数据库文件访问权限错误: ' + E.Message);
          Inc(RetryCount);
          Sleep(200);
          Continue;
        end;
      end;

      // 重新初始化数据库配置
      InitializeDatabase;

      // 尝试连接
      FConnection.Connected := True;
      FConnected := FConnection.Connected;

      if FConnected then
      begin
        CreateTables;
        LogInfo('数据库连接成功');
        Result := True;
      end
      else
      begin
        LogError('数据库连接失败，但没有异常');
        Inc(RetryCount);
        WaitTime := 200 * (RetryCount + 1);
        Sleep(WaitTime);
      end;

    except
      on E: Exception do
      begin
        LogError(Format('连接数据库时发生异常 (第%d次): %s', [RetryCount + 1, E.Message]));
        FConnected := False;
        Inc(RetryCount);

        if RetryCount < 3 then
        begin
          WaitTime := 300 * RetryCount;
          LogInfo(Format('等待%dms后重试', [WaitTime]));
          Sleep(WaitTime);
        end;
      end;
    end;
  end;

  if not Result then
  begin
    LogError('数据库连接失败，已尝试3次');
  end;
end;

procedure TImageDatabase.Disconnect;
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

function TImageDatabase.IsConnected: Boolean;
begin
  Result := FConnected and FConnection.Connected;
end;

procedure TImageDatabase.CreateTables;
begin
  try
    // 创建图像数据表
    FQuery.SQL.Text :=
      'CREATE TABLE IF NOT EXISTS images (' +
      '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
      '  image_key TEXT NOT NULL UNIQUE,' +
      '  image_data BLOB NOT NULL,' +
      '  address_text TEXT,' +
      '  description TEXT,' +
      '  md5_hash TEXT NOT NULL,' +
      '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,' +
      '  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
      ')';
    FQuery.ExecSQL;

    // 创建索引
    FQuery.SQL.Text := 'CREATE INDEX IF NOT EXISTS idx_images_key ON images(image_key)';
    FQuery.ExecSQL;

    // 为现有数据库添加md5_hash字段（如果不存在）
    try
      FQuery.SQL.Text := 'ALTER TABLE images ADD COLUMN md5_hash TEXT';
      FQuery.ExecSQL;
      LogInfo('md5_hash字段添加成功');
    except
      on E: Exception do
      begin
        // 字段可能已存在，忽略错误
        LogInfo('md5_hash字段可能已存在: ' + E.Message);
      end;
    end;

    LogInfo('数据库表创建完成');

  except
    on E: Exception do
    begin
      LogError('创建数据库表时发生异常: ' + E.Message);
      raise;
    end;
  end;
end;

function TImageDatabase.SaveImageData(const AImageKey: string; const AImageData: TBytes; const ADescription: string; const AAddressText: string): Boolean;
var
  EncryptedData: TBytes;
  OriginalMD5: string;
begin
  Result := False;

  try
    if not IsConnected then
    begin
      LogError('数据库未连接');
      Exit;
    end;

    if Length(AImageData) = 0 then
    begin
      LogError('图像数据为空');
      Exit;
    end;

    // 计算原始图像数据的MD5
    OriginalMD5 := TImageSecurity.CalculateMD5(AImageData);
    LogInfo(Format('图像 %s 的MD5: %s', [AImageKey, OriginalMD5]));

    // 加密图像数据
    EncryptedData := TImageSecurity.EncryptImageData(AImageData);
    
    // 检查图像是否已存在
    FQuery.SQL.Text := 'SELECT COUNT(*) FROM images WHERE image_key = :key';
    FQuery.ParamByName('key').AsString := AImageKey;
    FQuery.Open;
    
    try
      if FQuery.Fields[0].AsInteger > 0 then
      begin
        // 更新现有记录
        FQuery.Close;
        FQuery.SQL.Text :=
          'UPDATE images SET image_data = :data, address_text = :addr, description = :desc, md5_hash = :md5, updated_at = CURRENT_TIMESTAMP ' +
          'WHERE image_key = :key';
      end
      else
      begin
        // 插入新记录
        FQuery.Close;
        FQuery.SQL.Text :=
          'INSERT INTO images (image_key, image_data, address_text, description, md5_hash) ' +
          'VALUES (:key, :data, :addr, :desc, :md5)';
      end;

      FQuery.ParamByName('key').AsString := AImageKey;
      FQuery.ParamByName('data').AsBlob := BytesToRawByteString(EncryptedData);
      FQuery.ParamByName('addr').AsString := AAddressText;
      FQuery.ParamByName('desc').AsString := ADescription;
      FQuery.ParamByName('md5').AsString := OriginalMD5;
      FQuery.ExecSQL;
      
      Result := True;
      LogInfo(Format('图像数据已保存: %s (%d 字节)', [AImageKey, Length(AImageData)]));
      
    finally
      FQuery.Close;
    end;
    
  except
    on E: Exception do
    begin
      LogError('保存图像数据时发生异常: ' + AImageKey + ' - ' + E.Message);
      Result := False;
    end;
  end;
end;

function TImageDatabase.LoadImageData(const AImageKey: string; out AImageData: TBytes): Boolean;
var
  EncryptedData: TBytes;
  ExpectedMD5: string;
begin
  SetLength(AImageData, 0);
  Result := False;

  try
    if not IsConnected then
    begin
      LogError('数据库未连接');
      Exit;
    end;

    FQuery.SQL.Text := 'SELECT image_data, md5_hash FROM images WHERE image_key = :key';
    FQuery.ParamByName('key').AsString := AImageKey;
    FQuery.Open;

    try
      if not FQuery.IsEmpty then
      begin
        // 获取加密的数据和MD5
        EncryptedData := FQuery.FieldByName('image_data').AsBytes;
        ExpectedMD5 := FQuery.FieldByName('md5_hash').AsString;

        if Length(EncryptedData) > 0 then
        begin
          // 解密数据
          AImageData := TImageSecurity.DecryptImageData(EncryptedData);

          // MD5校验
          if not TImageSecurity.VerifyImageIntegrity(AImageData, ExpectedMD5) then
          begin
            LogError(Format('图像 %s MD5校验失败', [AImageKey]));
            TImageSecurity.HandleSecurityViolation(AImageKey, 'MD5校验失败，图像数据可能被篡改');
            Exit;
          end;

          Result := Length(AImageData) > 0;
          
          if Result then
            LogInfo(Format('图像数据加载成功: %s (%d 字节)', [AImageKey, Length(AImageData)]))
          else
            LogError('图像数据解密失败: ' + AImageKey);
        end
        else
        begin
          LogError('数据库中的图像数据为空: ' + AImageKey);
        end;
      end
      else
      begin
        LogError('图像不存在: ' + AImageKey);
      end;
      
    finally
      FQuery.Close;
    end;
    
  except
    on E: Exception do
    begin
      LogError('加载图像数据时发生异常: ' + AImageKey + ' - ' + E.Message);
      SetLength(AImageData, 0);
      Result := False;
    end;
  end;
end;

function TImageDatabase.ImageExists(const AImageKey: string): Boolean;
begin
  Result := False;
  
  try
    if not IsConnected then
    begin
      LogError('数据库未连接');
      Exit;
    end;
    
    FQuery.SQL.Text := 'SELECT COUNT(*) FROM images WHERE image_key = :key';
    FQuery.ParamByName('key').AsString := AImageKey;
    FQuery.Open;
    
    try
      Result := FQuery.Fields[0].AsInteger > 0;
    finally
      FQuery.Close;
    end;
    
  except
    on E: Exception do
    begin
      LogError('检查图像是否存在时发生异常: ' + AImageKey + ' - ' + E.Message);
      Result := False;
    end;
  end;
end;

function TImageDatabase.DeleteImage(const AImageKey: string): Boolean;
begin
  Result := False;
  
  try
    if not IsConnected then
    begin
      LogError('数据库未连接');
      Exit;
    end;
    
    FQuery.SQL.Text := 'DELETE FROM images WHERE image_key = :key';
    FQuery.ParamByName('key').AsString := AImageKey;
    FQuery.ExecSQL;
    
    Result := True;
    LogInfo('图像已删除: ' + AImageKey);
    
  except
    on E: Exception do
    begin
      LogError('删除图像时发生异常: ' + AImageKey + ' - ' + E.Message);
      Result := False;
    end;
  end;
end;

function TImageDatabase.GetImageList: TStringList;
begin
  Result := TStringList.Create;
  
  try
    if not IsConnected then
    begin
      LogError('数据库未连接');
      Exit;
    end;
    
    FQuery.SQL.Text := 'SELECT image_key, description FROM images ORDER BY image_key';
    FQuery.Open;
    
    try
      while not FQuery.Eof do
      begin
        Result.Add(FQuery.FieldByName('image_key').AsString);
        FQuery.Next;
      end;
    finally
      FQuery.Close;
    end;
    
    LogInfo(Format('获取图像列表完成: %d 个图像', [Result.Count]));
    
  except
    on E: Exception do
    begin
      LogError('获取图像列表时发生异常: ' + E.Message);
      Result.Clear;
    end;
  end;
end;

function TImageDatabase.LoadImageAndText(const AImageKey: string; out AImageData: TBytes; out AAddressText: string): Boolean;
var
  EncryptedData: TBytes;
  ExpectedMD5: string;
begin
  SetLength(AImageData, 0);
  AAddressText := '';
  Result := False;

  try
    if not IsConnected then
    begin
      LogError('数据库未连接');
      Exit;
    end;

    FQuery.SQL.Text := 'SELECT image_data, address_text, md5_hash FROM images WHERE image_key = :key';
    FQuery.ParamByName('key').AsString := AImageKey;
    FQuery.Open;

    try
      if not FQuery.IsEmpty then
      begin
        // 获取加密的数据和MD5
        EncryptedData := FQuery.FieldByName('image_data').AsBytes;
        AAddressText := FQuery.FieldByName('address_text').AsString;
        ExpectedMD5 := FQuery.FieldByName('md5_hash').AsString;

        if Length(EncryptedData) > 0 then
        begin
          // 解密数据
          AImageData := TImageSecurity.DecryptImageData(EncryptedData);

          // MD5校验
          if not TImageSecurity.VerifyImageIntegrity(AImageData, ExpectedMD5) then
          begin
            LogError(Format('图像 %s MD5校验失败', [AImageKey]));
            TImageSecurity.HandleSecurityViolation(AImageKey, 'MD5校验失败，图像数据可能被篡改');
            Exit;
          end;

          Result := Length(AImageData) > 0;
          LogInfo(Format('图像 %s 加载并校验成功', [AImageKey]));

          if Result then
            LogInfo(Format('图像和文本加载成功: %s (%d 字节)', [AImageKey, Length(AImageData)]))
          else
            LogError('图像数据解密失败: ' + AImageKey);
        end
        else
        begin
          LogError('数据库中的图像数据为空: ' + AImageKey);
        end;
      end
      else
      begin
        LogError('图像不存在: ' + AImageKey);
      end;

    finally
      FQuery.Close;
    end;

  except
    on E: Exception do
    begin
      LogError('加载图像和文本时发生异常: ' + AImageKey + ' - ' + E.Message);
      SetLength(AImageData, 0);
      AAddressText := '';
      Result := False;
    end;
  end;
end;

class function TImageDatabase.GetProjectDatabasePath: string;
var
  ExePath, ProjectPath: string;
begin
  // 获取可执行文件路径
  ExePath := ExtractFilePath(ParamStr(0));

  // 尝试找到项目根目录（包含.dpr文件的目录）
  ProjectPath := ExePath;

  // 如果在Win32或Win64子目录中，向上查找
  if (Pos('\Win32\', ProjectPath) > 0) or (Pos('\Win64\', ProjectPath) > 0) then
  begin
    ProjectPath := ExtractFilePath(ExcludeTrailingPathDelimiter(ProjectPath)); // 移除Debug
    ProjectPath := ExtractFilePath(ExcludeTrailingPathDelimiter(ProjectPath)); // 移除Win32/Win64
  end;

  // 返回项目根目录下的MoveC.db路径
  Result := IncludeTrailingPathDelimiter(ProjectPath) + 'MoveC.db';
end;

end.

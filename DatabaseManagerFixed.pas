unit DatabaseManagerFixed;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.IniFiles,
  System.Generics.Collections, Winapi.Windows, BasicProtection, DataTypes,
  ChineseConstants;

type
  // 修正版数据库管理器 - 使用INI文件和Unicode常量
  TDatabaseManagerFixed = class
  private
    FDatabasePath: string;
    FIsInitialized: Boolean;
    FLanguageIni: TMemIniFile;
    FConfigIni: TMemIniFile;
    
    function GetDatabasePath: string;
    procedure InitializeDefaultLanguageStrings;
    function LanguageStringsFile: string;
    function ConfigSettingsFile: string;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 数据库初始化
    function Initialize: Boolean;
    procedure Finalize;
    
    // 多语言字符串管理
    function SetLanguageString(const LanguageCode, StringKey, StringValue: string): Boolean;
    function GetLanguageString(const LanguageCode, StringKey: string; const DefaultValue: string = ''): string;
    function GetAllLanguageStrings(const LanguageCode: string): TArray<TLanguageStringItem>;
    function DeleteLanguageString(const LanguageCode, StringKey: string): Boolean;
    
    // 配置管理
    function SetConfig(const Category, Key, Value: string): Boolean;
    function GetConfig(const Category, Key: string; const DefaultValue: string = ''): string;
    
    // 属性
    property DatabasePath: string read FDatabasePath;
    property IsInitialized: Boolean read FIsInitialized;
  end;

implementation

constructor TDatabaseManagerFixed.Create;
begin
  inherited;
  FDatabasePath := '';
  FIsInitialized := False;
  FLanguageIni := nil;
  FConfigIni := nil;
end;

destructor TDatabaseManagerFixed.Destroy;
begin
  Finalize;
  inherited;
end;

function TDatabaseManagerFixed.GetDatabasePath: string;
var
  AppDataPath: string;
begin
  AppDataPath := GetEnvironmentVariable('LOCALAPPDATA');
  if AppDataPath = '' then
    AppDataPath := TPath.Combine(GetEnvironmentVariable('USERPROFILE'), 'AppData\Local');
  Result := TPath.Combine(AppDataPath, 'DiskCleanup');
end;

function TDatabaseManagerFixed.LanguageStringsFile: string;
begin
  Result := TPath.Combine(FDatabasePath, 'language_strings.ini');
end;

function TDatabaseManagerFixed.ConfigSettingsFile: string;
begin
  Result := TPath.Combine(FDatabasePath, 'config_settings.ini');
end;

function TDatabaseManagerFixed.Initialize: Boolean;
begin
  Result := False;
  try
    if FIsInitialized then
      Exit(True);
      
    FDatabasePath := GetDatabasePath;
    
    // 创建数据目录
    if not TDirectory.Exists(FDatabasePath) then
      TDirectory.CreateDirectory(FDatabasePath);
    
    // 初始化INI文件对象
    FLanguageIni := TMemIniFile.Create(LanguageStringsFile, TEncoding.UTF8);
    FConfigIni := TMemIniFile.Create(ConfigSettingsFile, TEncoding.UTF8);
    
    // 初始化默认数据
    InitializeDefaultLanguageStrings;
    
    FIsInitialized := True;
    Result := True;
    
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('Database initialization failed: ' + E.Message));
      Finalize;
    end;
  end;
end;

procedure TDatabaseManagerFixed.Finalize;
begin
  try
    if Assigned(FLanguageIni) then
    begin
      FLanguageIni.UpdateFile;
      FLanguageIni.Free;
      FLanguageIni := nil;
    end;
    
    if Assigned(FConfigIni) then
    begin
      FConfigIni.UpdateFile;
      FConfigIni.Free;
      FConfigIni := nil;
    end;
  except
    // 忽略错误
  end;
  
  FIsInitialized := False;
end;

procedure TDatabaseManagerFixed.InitializeDefaultLanguageStrings;
begin
  if not Assigned(FLanguageIni) then
    Exit;
    
  // 使用ChineseConstants中的Unicode常量
  SetLanguageString('zh-CN', 'app_title', APP_TITLE);
  SetLanguageString('zh-CN', 'app_version', APP_VERSION);
  SetLanguageString('zh-CN', 'menu_file', MENU_FILE);
  SetLanguageString('zh-CN', 'menu_exit', MENU_EXIT);
  SetLanguageString('zh-CN', 'menu_tools', MENU_TOOLS);
  SetLanguageString('zh-CN', 'menu_system_check', MENU_SYSTEM_CHECK);
  SetLanguageString('zh-CN', 'menu_language', MENU_LANGUAGE);
  SetLanguageString('zh-CN', 'menu_help', MENU_HELP);
  SetLanguageString('zh-CN', 'menu_about', MENU_ABOUT);
  SetLanguageString('zh-CN', 'btn_copy', BTN_COPY);
  SetLanguageString('zh-CN', 'btn_delete', BTN_DELETE);
  SetLanguageString('zh-CN', 'btn_backup', BTN_BACKUP);
  SetLanguageString('zh-CN', 'btn_cancel', BTN_CANCEL);
  SetLanguageString('zh-CN', 'btn_ok', BTN_OK);
  SetLanguageString('zh-CN', 'btn_yes', BTN_YES);
  SetLanguageString('zh-CN', 'btn_no', BTN_NO);
  SetLanguageString('zh-CN', 'btn_close', BTN_CLOSE);
  SetLanguageString('zh-CN', 'tab_backup', TAB_BACKUP);
  SetLanguageString('zh-CN', 'tab_about', TAB_ABOUT);
  SetLanguageString('zh-CN', 'status_ready', STATUS_READY);
  SetLanguageString('zh-CN', 'status_copying', STATUS_COPYING);
  SetLanguageString('zh-CN', 'status_complete', STATUS_COMPLETE);
  SetLanguageString('zh-CN', 'progress_title', PROGRESS_TITLE);
  SetLanguageString('zh-CN', 'confirm_delete', CONFIRM_DELETE);
  SetLanguageString('zh-CN', 'language_changed', LANGUAGE_CHANGED);
  SetLanguageString('zh-CN', 'donation_title', DONATION_TITLE);
  SetLanguageString('zh-CN', 'machine_code', MACHINE_CODE);
end;

function TDatabaseManagerFixed.SetLanguageString(const LanguageCode, StringKey, StringValue: string): Boolean;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FLanguageIni) then
    Exit;

  try
    FLanguageIni.WriteString(LanguageCode, StringKey, StringValue);
    FLanguageIni.UpdateFile;
    Result := True;
  except
    on E: Exception do
      OutputDebugString(PChar('SetLanguageString failed: ' + E.Message));
  end;
end;

function TDatabaseManagerFixed.GetLanguageString(const LanguageCode, StringKey: string; const DefaultValue: string = ''): string;
begin
  Result := DefaultValue;
  if not FIsInitialized or not Assigned(FLanguageIni) then
    Exit;

  try
    Result := FLanguageIni.ReadString(LanguageCode, StringKey, DefaultValue);
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('GetLanguageString failed: ' + E.Message));
      Result := DefaultValue;
    end;
  end;
end;

function TDatabaseManagerFixed.GetAllLanguageStrings(const LanguageCode: string): TArray<TLanguageStringItem>;
var
  Keys: TStringList;
  StringList: TArray<TLanguageStringItem>;
  StringItem: TLanguageStringItem;
  I: Integer;
begin
  SetLength(Result, 0);
  if not FIsInitialized or not Assigned(FLanguageIni) then
    Exit;

  Keys := TStringList.Create;
  try
    FLanguageIni.ReadSection(LanguageCode, Keys);
    SetLength(StringList, Keys.Count);

    for I := 0 to Keys.Count - 1 do
    begin
      StringItem.LanguageCode := LanguageCode;
      StringItem.StringKey := Keys[I];
      StringItem.StringValue := FLanguageIni.ReadString(LanguageCode, Keys[I], '');
      StringItem.CreatedAt := Now;
      StringItem.UpdatedAt := Now;

      StringList[I] := StringItem;
    end;

    Result := StringList;
  finally
    Keys.Free;
  end;
end;

function TDatabaseManagerFixed.DeleteLanguageString(const LanguageCode, StringKey: string): Boolean;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FLanguageIni) then
    Exit;

  try
    FLanguageIni.DeleteKey(LanguageCode, StringKey);
    FLanguageIni.UpdateFile;
    Result := True;
  except
    on E: Exception do
      OutputDebugString(PChar('DeleteLanguageString failed: ' + E.Message));
  end;
end;

function TDatabaseManagerFixed.SetConfig(const Category, Key, Value: string): Boolean;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FConfigIni) then
    Exit;

  try
    FConfigIni.WriteString(Category, Key, Value);
    FConfigIni.UpdateFile;
    Result := True;
  except
    on E: Exception do
      OutputDebugString(PChar('SetConfig failed: ' + E.Message));
  end;
end;

function TDatabaseManagerFixed.GetConfig(const Category, Key: string; const DefaultValue: string = ''): string;
begin
  Result := DefaultValue;
  if not FIsInitialized or not Assigned(FConfigIni) then
    Exit;

  try
    Result := FConfigIni.ReadString(Category, Key, DefaultValue);
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('GetConfig failed: ' + E.Message));
      Result := DefaultValue;
    end;
  end;
end;

end.

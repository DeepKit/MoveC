unit LanguageManager;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.IOUtils,
  System.Generics.Collections, Winapi.Windows, LanguageTypes, DatabaseManager, DataTypes,
  System.Win.Registry;

type
  // 多语言管理器
  TLanguageManager = class
  private
    FCurrentLanguage: TLanguageCode;
    FLanguageStrings: TDictionary<string, string>;
    FLanguageList: TArray<TLanguageInfo>;
    FDatabaseManager: TDatabaseManager;
    
    procedure InitializeLanguageList;
    procedure LoadDefaultStrings(ALanguage: TLanguageCode);
    function GetLanguageCodeString(ALanguage: TLanguageCode): string;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 语言管理
    function LoadLanguage(ALanguage: TLanguageCode): Boolean;
    function GetAvailableLanguages: TArray<TLanguageInfo>;
    function GetCurrentLanguage: TLanguageCode;
    function GetCurrentLanguageName: string;
    
    // 字符串获取
    function GetString(const AKey: string): string; overload;
    function GetString(const AKey: string; const ADefault: string): string; overload;
    function GetFormattedString(const AKey: string; const AArgs: array of const): string;
    
    // 系统集成
    function DetectSystemLanguage: TLanguageCode;
    procedure SaveLanguagePreference(ALanguage: TLanguageCode);
    function LoadLanguagePreference: TLanguageCode;
    
    // 属性
    property CurrentLanguage: TLanguageCode read FCurrentLanguage;
    property LanguageStrings: TDictionary<string, string> read FLanguageStrings;
  end;

  // 全局语言管理器实例
  function LanguageMgr: TLanguageManager;

implementation

uses
  Vcl.Forms;

var
  GLanguageManager: TLanguageManager;

// 获取全局语言管理器实例
function LanguageMgr: TLanguageManager;
begin
  if not Assigned(GLanguageManager) then
    GLanguageManager := TLanguageManager.Create;
  Result := GLanguageManager;
end;

constructor TLanguageManager.Create;
begin
  inherited;
  FLanguageStrings := TDictionary<string, string>.Create;
  
  // 初始化数据库管理器
  FDatabaseManager := TDatabaseManager.Create;
  FDatabaseManager.Initialize;
  
  // 初始化语言列表
  InitializeLanguageList;
  
  // 加载用户首选语言或系统语言
  FCurrentLanguage := LoadLanguagePreference;
  if not LoadLanguage(FCurrentLanguage) then
  begin
    // 如果加载失败，尝试加载简体中文
    FCurrentLanguage := lcChineseSimplified;
    LoadLanguage(FCurrentLanguage);
  end;
end;

destructor TLanguageManager.Destroy;
begin
  FLanguageStrings.Free;
  if Assigned(FDatabaseManager) then
    FDatabaseManager.Free;
  inherited;
end;

// 初始化语言列表
procedure TLanguageManager.InitializeLanguageList;
begin
  SetLength(FLanguageList, 4);
  
  FLanguageList[0].Code := lcChineseSimplified;
  FLanguageList[0].Name := '简体中文';
  FLanguageList[0].NativeName := '简体中文';
  FLanguageList[0].FileName := 'zh-CN.json';
  
  FLanguageList[1].Code := lcChineseTraditional;
  FLanguageList[1].Name := '繁體中文';
  FLanguageList[1].NativeName := '繁體中文';
  FLanguageList[1].FileName := 'zh-TW.json';
  
  FLanguageList[2].Code := lcEnglish;
  FLanguageList[2].Name := 'English';
  FLanguageList[2].NativeName := 'English';
  FLanguageList[2].FileName := 'en-US.json';
  
  FLanguageList[3].Code := lcJapanese;
  FLanguageList[3].Name := '日本語';
  FLanguageList[3].NativeName := '日本語';
  FLanguageList[3].FileName := 'ja-JP.json';
end;

// 获取语言代码字符串
function TLanguageManager.GetLanguageCodeString(ALanguage: TLanguageCode): string;
begin
  case ALanguage of
    lcChineseSimplified: Result := 'zh-CN';
    lcChineseTraditional: Result := 'zh-TW';
    lcEnglish: Result := 'en-US';
    lcJapanese: Result := 'ja-JP';
    else Result := 'zh-CN';
  end;
end;

// 加载语言
function TLanguageManager.LoadLanguage(ALanguage: TLanguageCode): Boolean;
var
  LanguageCode: string;
  StringItems: TArray<TLanguageStringItem>;
  I: Integer;
begin
  Result := False;
  
  // 清空当前字符串
  FLanguageStrings.Clear;
  
  // 获取语言代码字符串
  LanguageCode := GetLanguageCodeString(ALanguage);
  
  try
    if Assigned(FDatabaseManager) then
    begin
      // 从数据库加载语言字符串
      StringItems := FDatabaseManager.GetAllLanguageStrings(LanguageCode);
      
      if Length(StringItems) > 0 then
      begin
        // 将字符串加载到字典中
        for I := 0 to High(StringItems) do
        begin
          FLanguageStrings.AddOrSetValue(StringItems[I].StringKey, StringItems[I].StringValue);
        end;
        
        FCurrentLanguage := ALanguage;
        Result := True;
      end
      else
      begin
        // 如果数据库中没有数据，使用默认字符串
        LoadDefaultStrings(ALanguage);
        FCurrentLanguage := ALanguage;
        Result := True;
      end;
    end
    else
    begin
      // 如果数据库管理器不可用，使用默认字符串
      LoadDefaultStrings(ALanguage);
      FCurrentLanguage := ALanguage;
      Result := True;
    end;
    
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('加载语言失败: ' + E.Message));
      // 如果数据库加载失败，使用默认字符串
      LoadDefaultStrings(ALanguage);
      FCurrentLanguage := ALanguage;
      Result := True;
    end;
  end;
end;

// 获取可用语言列表
function TLanguageManager.GetAvailableLanguages: TArray<TLanguageInfo>;
begin
  Result := FLanguageList;
end;

// 获取当前语言
function TLanguageManager.GetCurrentLanguage: TLanguageCode;
begin
  Result := FCurrentLanguage;
end;

// 获取当前语言名称
function TLanguageManager.GetCurrentLanguageName: string;
var
  I: Integer;
begin
  Result := 'Unknown';
  for I := 0 to High(FLanguageList) do
  begin
    if FLanguageList[I].Code = FCurrentLanguage then
    begin
      Result := FLanguageList[I].Name;
      Break;
    end;
  end;
end;

// 获取字符串
function TLanguageManager.GetString(const AKey: string): string;
begin
  if FLanguageStrings.ContainsKey(AKey) then
    Result := FLanguageStrings[AKey]
  else
    Result := AKey; // 如果找不到，返回键名
end;

// 获取字符串（带默认值）
function TLanguageManager.GetString(const AKey: string; const ADefault: string): string;
begin
  if FLanguageStrings.ContainsKey(AKey) then
    Result := FLanguageStrings[AKey]
  else
    Result := ADefault;
end;

// 获取格式化字符串
function TLanguageManager.GetFormattedString(const AKey: string; const AArgs: array of const): string;
begin
  Result := Format(GetString(AKey), AArgs);
end;

// 检测系统语言
function TLanguageManager.DetectSystemLanguage: TLanguageCode;
begin
  // 简化实现，默认返回简体中文
  Result := lcChineseSimplified;
end;

// 保存语言首选项
procedure TLanguageManager.SaveLanguagePreference(ALanguage: TLanguageCode);
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKey('Software\DiskCleanup', True) then
    begin
      Registry.WriteInteger('Language', Ord(ALanguage));
      Registry.CloseKey;
    end;
  except
    // 忽略注册表错误
  end;
  Registry.Free;
end;

// 加载语言首选项
function TLanguageManager.LoadLanguagePreference: TLanguageCode;
var
  Registry: TRegistry;
  LangValue: Integer;
begin
  Result := DetectSystemLanguage; // 默认使用系统语言
  
  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKey('Software\DiskCleanup', False) then
    begin
      if Registry.ValueExists('Language') then
      begin
        LangValue := Registry.ReadInteger('Language');
        if (LangValue >= Ord(Low(TLanguageCode))) and (LangValue <= Ord(High(TLanguageCode))) then
          Result := TLanguageCode(LangValue);
      end;
      Registry.CloseKey;
    end;
  except
    // 忽略注册表错误，使用默认值
  end;
  Registry.Free;
end;

// 加载默认字符串
procedure TLanguageManager.LoadDefaultStrings(ALanguage: TLanguageCode);
begin
  FLanguageStrings.Clear;

  case ALanguage of
    lcChineseSimplified:
    begin
      FLanguageStrings.AddOrSetValue('app_title', 'C盘超级清理');
      FLanguageStrings.AddOrSetValue('menu_file', '文件(&F)');
      FLanguageStrings.AddOrSetValue('menu_exit', '退出(&X)');
      FLanguageStrings.AddOrSetValue('menu_tools', '工具(&T)');
      FLanguageStrings.AddOrSetValue('menu_system_check', '系统检查(&S)');
      FLanguageStrings.AddOrSetValue('menu_language', '语言设置(&L)');
      FLanguageStrings.AddOrSetValue('menu_help', '帮助(&H)');
      FLanguageStrings.AddOrSetValue('menu_about', '关于(&A)');
      FLanguageStrings.AddOrSetValue('btn_copy', '复制文件');
      FLanguageStrings.AddOrSetValue('btn_delete', '删除并链接');
      FLanguageStrings.AddOrSetValue('btn_backup', '创建备份');
      FLanguageStrings.AddOrSetValue('btn_cancel', '取消');
      FLanguageStrings.AddOrSetValue('btn_ok', '确定');
      FLanguageStrings.AddOrSetValue('btn_yes', '是');
      FLanguageStrings.AddOrSetValue('btn_no', '否');
      FLanguageStrings.AddOrSetValue('btn_close', '关闭');
      FLanguageStrings.AddOrSetValue('tab_backup', '备份管理');
      FLanguageStrings.AddOrSetValue('tab_about', '关于开发者');
      FLanguageStrings.AddOrSetValue('status_ready', '就绪');
      FLanguageStrings.AddOrSetValue('status_copying', '正在复制...');
      FLanguageStrings.AddOrSetValue('status_complete', '操作完成');
      FLanguageStrings.AddOrSetValue('progress_title', '操作进度');
      FLanguageStrings.AddOrSetValue('confirm_delete', '确定要删除选中的文件吗？');
      FLanguageStrings.AddOrSetValue('language_changed', '语言设置已更改，部分界面将在重启后生效。');
      FLanguageStrings.AddOrSetValue('donation_title', '支持开发者');
      FLanguageStrings.AddOrSetValue('machine_code', '机器码');
    end;

    lcEnglish:
    begin
      FLanguageStrings.AddOrSetValue('app_title', 'Disk Cleanup Tool');
      FLanguageStrings.AddOrSetValue('menu_file', 'File(&F)');
      FLanguageStrings.AddOrSetValue('menu_exit', 'Exit(&X)');
      FLanguageStrings.AddOrSetValue('menu_tools', 'Tools(&T)');
      FLanguageStrings.AddOrSetValue('menu_system_check', 'System Check(&S)');
      FLanguageStrings.AddOrSetValue('menu_language', 'Language(&L)');
      FLanguageStrings.AddOrSetValue('menu_help', 'Help(&H)');
      FLanguageStrings.AddOrSetValue('menu_about', 'About(&A)');
      FLanguageStrings.AddOrSetValue('btn_copy', 'Copy Files');
      FLanguageStrings.AddOrSetValue('btn_delete', 'Delete & Link');
      FLanguageStrings.AddOrSetValue('btn_backup', 'Create Backup');
      FLanguageStrings.AddOrSetValue('btn_cancel', 'Cancel');
      FLanguageStrings.AddOrSetValue('btn_ok', 'OK');
      FLanguageStrings.AddOrSetValue('btn_yes', 'Yes');
      FLanguageStrings.AddOrSetValue('btn_no', 'No');
      FLanguageStrings.AddOrSetValue('btn_close', 'Close');
      FLanguageStrings.AddOrSetValue('tab_backup', 'Backup Management');
      FLanguageStrings.AddOrSetValue('tab_about', 'About Developer');
      FLanguageStrings.AddOrSetValue('status_ready', 'Ready');
      FLanguageStrings.AddOrSetValue('status_copying', 'Copying...');
      FLanguageStrings.AddOrSetValue('status_complete', 'Operation Complete');
      FLanguageStrings.AddOrSetValue('progress_title', 'Operation Progress');
      FLanguageStrings.AddOrSetValue('confirm_delete', 'Are you sure you want to delete the selected files?');
      FLanguageStrings.AddOrSetValue('language_changed', 'Language settings changed. Some interface will take effect after restart.');
      FLanguageStrings.AddOrSetValue('donation_title', 'Support Developer');
      FLanguageStrings.AddOrSetValue('machine_code', 'Machine Code');
    end;

    else
      // 默认使用简体中文
      LoadDefaultStrings(lcChineseSimplified);
  end;
end;

initialization

finalization
  if Assigned(GLanguageManager) then
    GLanguageManager.Free;

end.

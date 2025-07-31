unit LanguageManager;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, LanguageTypes;

type
  // 语言管理器类
  TLanguageManager = class
  private
    FCurrentLanguage: TLanguageType;
    FLanguageResources: TDictionary<TLanguageType, TDictionary<string, string>>;
    FResourcePath: string;
    
    procedure LoadLanguageResource(ALanguageType: TLanguageType);
    function GetResourceFileName(ALanguageType: TLanguageType): string;
    procedure CreateDefaultLanguageFile(ALanguageType: TLanguageType; const AFileName: string);
    
  public
    constructor Create(const AResourcePath: string = '');
    destructor Destroy; override;
    
    // 语言管理
    procedure SetCurrentLanguage(ALanguageType: TLanguageType);
    function GetCurrentLanguage: TLanguageType;
    function GetCurrentLanguageInfo: TLanguageInfo;
    
    // 字符串获取
    function GetString(const AKey: string): string; overload;
    function GetString(const AKey: string; const ADefault: string): string; overload;
    function GetFormattedString(const AKey: string; const AArgs: array of const): string;
    function HasString(const AKey: string): Boolean;
    
    // 资源管理
    procedure LoadAllLanguages;
    procedure ReloadCurrentLanguage;
    function GetAvailableLanguages: TArray<TLanguageType>;
    
    // 属性
    property CurrentLanguage: TLanguageType read FCurrentLanguage write SetCurrentLanguage;
    property ResourcePath: string read FResourcePath;
  end;

// 全局语言管理器实例
function GetLanguageManager: TLanguageManager;

// 便捷函数
function _T(const AKey: string): string; overload;
function _T(const AKey: string; const ADefault: string): string; overload;
function _F(const AKey: string; const AArgs: array of const): string;

implementation

uses
  System.IOUtils, System.IniFiles;

var
  GLanguageManager: TLanguageManager;

function GetLanguageManager: TLanguageManager;
begin
  if not Assigned(GLanguageManager) then
    GLanguageManager := TLanguageManager.Create;
  Result := GLanguageManager;
end;

function _T(const AKey: string): string;
begin
  Result := GetLanguageManager.GetString(AKey);
end;

function _T(const AKey: string; const ADefault: string): string;
begin
  Result := GetLanguageManager.GetString(AKey, ADefault);
end;

function _F(const AKey: string; const AArgs: array of const): string;
begin
  Result := GetLanguageManager.GetFormattedString(AKey, AArgs);
end;

constructor TLanguageManager.Create(const AResourcePath: string);
begin
  inherited Create;
  
  if AResourcePath = '' then
    FResourcePath := ExtractFilePath(ParamStr(0)) + 'Languages'
  else
    FResourcePath := AResourcePath;
    
  FLanguageResources := TDictionary<TLanguageType, TDictionary<string, string>>.Create;
  
  // 设置默认语言
  FCurrentLanguage := GetSystemLanguageType;
  
  // 确保语言资源目录存在
  if not DirectoryExists(FResourcePath) then
    ForceDirectories(FResourcePath);
    
  // 加载当前语言资源
  LoadLanguageResource(FCurrentLanguage);
end;

destructor TLanguageManager.Destroy;
var
  LangType: TLanguageType;
begin
  for LangType in FLanguageResources.Keys do
    FLanguageResources[LangType].Free;
    
  FLanguageResources.Free;
  inherited Destroy;
end;

procedure TLanguageManager.SetCurrentLanguage(ALanguageType: TLanguageType);
begin
  if FCurrentLanguage <> ALanguageType then
  begin
    FCurrentLanguage := ALanguageType;
    LoadLanguageResource(ALanguageType);
  end;
end;

function TLanguageManager.GetCurrentLanguage: TLanguageType;
begin
  Result := FCurrentLanguage;
end;

function TLanguageManager.GetCurrentLanguageInfo: TLanguageInfo;
begin
  Result := GetLanguageInfo(FCurrentLanguage);
end;

function TLanguageManager.GetString(const AKey: string): string;
begin
  Result := GetString(AKey, AKey);
end;

function TLanguageManager.GetString(const AKey: string; const ADefault: string): string;
var
  LanguageDict: TDictionary<string, string>;
begin
  Result := ADefault;
  
  if FLanguageResources.TryGetValue(FCurrentLanguage, LanguageDict) then
  begin
    if not LanguageDict.TryGetValue(AKey, Result) then
      Result := ADefault;
  end;
end;

function TLanguageManager.GetFormattedString(const AKey: string; const AArgs: array of const): string;
var
  FormatStr: string;
begin
  FormatStr := GetString(AKey);
  try
    Result := Format(FormatStr, AArgs);
  except
    Result := FormatStr;
  end;
end;

function TLanguageManager.HasString(const AKey: string): Boolean;
var
  LanguageDict: TDictionary<string, string>;
begin
  Result := False;
  
  if FLanguageResources.TryGetValue(FCurrentLanguage, LanguageDict) then
    Result := LanguageDict.ContainsKey(AKey);
end;

procedure TLanguageManager.LoadLanguageResource(ALanguageType: TLanguageType);
var
  FileName: string;
  IniFile: TIniFile;
  Sections, Keys: TStringList;
  LanguageDict: TDictionary<string, string>;
  I, J: Integer;
  Section, Key, Value: string;
begin
  FileName := GetResourceFileName(ALanguageType);
  
  // 如果已经加载过，先释放
  if FLanguageResources.ContainsKey(ALanguageType) then
  begin
    FLanguageResources[ALanguageType].Free;
    FLanguageResources.Remove(ALanguageType);
  end;
  
  LanguageDict := TDictionary<string, string>.Create;
  FLanguageResources.Add(ALanguageType, LanguageDict);
  
  // 如果文件不存在，创建默认的语言文件
  if not FileExists(FileName) then
  begin
    CreateDefaultLanguageFile(ALanguageType, FileName);
  end;
  
  // 加载语言文件
  if FileExists(FileName) then
  begin
    IniFile := TIniFile.Create(FileName);
    Sections := TStringList.Create;
    Keys := TStringList.Create;
    try
      IniFile.ReadSections(Sections);
      
      for I := 0 to Sections.Count - 1 do
      begin
        Section := Sections[I];
        Keys.Clear;
        IniFile.ReadSection(Section, Keys);
        
        for J := 0 to Keys.Count - 1 do
        begin
          Key := Keys[J];
          Value := IniFile.ReadString(Section, Key, '');
          
          if Section = 'General' then
            LanguageDict.AddOrSetValue(Key, Value)
          else
            LanguageDict.AddOrSetValue(Section + '.' + Key, Value);
        end;
      end;
    finally
      Keys.Free;
      Sections.Free;
      IniFile.Free;
    end;
  end;
end;

function TLanguageManager.GetResourceFileName(ALanguageType: TLanguageType): string;
var
  LangInfo: TLanguageInfo;
begin
  LangInfo := GetLanguageInfo(ALanguageType);
  Result := TPath.Combine(FResourcePath, LangInfo.LanguageCode + '.ini');
end;

procedure TLanguageManager.LoadAllLanguages;
var
  LangType: TLanguageType;
begin
  for LangType := Low(TLanguageType) to High(TLanguageType) do
    LoadLanguageResource(LangType);
end;

procedure TLanguageManager.ReloadCurrentLanguage;
begin
  LoadLanguageResource(FCurrentLanguage);
end;

function TLanguageManager.GetAvailableLanguages: TArray<TLanguageType>;
var
  LangList: TList<TLanguageType>;
  LangType: TLanguageType;
  FileName: string;
begin
  LangList := TList<TLanguageType>.Create;
  try
    for LangType := Low(TLanguageType) to High(TLanguageType) do
    begin
      FileName := GetResourceFileName(LangType);
      if FileExists(FileName) then
        LangList.Add(LangType);
    end;
    
    Result := LangList.ToArray;
  finally
    LangList.Free;
  end;
end;

procedure TLanguageManager.CreateDefaultLanguageFile(ALanguageType: TLanguageType; const AFileName: string);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(AFileName);
  try
    // 写入基本的默认字符串
    IniFile.WriteString('General', 'AppTitle', 'C盘瘦身工具 v3.0 Enterprise');
    IniFile.WriteString('General', 'AppVersion', '企业版');
    IniFile.WriteString('General', 'Ready', '就绪');
    IniFile.WriteString('General', 'Processing', '处理中');
    IniFile.WriteString('General', 'Completed', '已完成');
    IniFile.WriteString('General', 'Error', '错误');
    IniFile.WriteString('General', 'Warning', '警告');
    IniFile.WriteString('General', 'Information', '信息');
    
    // 菜单项
    IniFile.WriteString('Menu', 'File', '文件');
    IniFile.WriteString('Menu', 'Edit', '编辑');
    IniFile.WriteString('Menu', 'Tools', '工具');
    IniFile.WriteString('Menu', 'Help', '帮助');
    
    // 按钮
    IniFile.WriteString('Button', 'OK', '确定');
    IniFile.WriteString('Button', 'Cancel', '取消');
    IniFile.WriteString('Button', 'Apply', '应用');
    IniFile.WriteString('Button', 'Close', '关闭');
    
  finally
    IniFile.Free;
  end;
end;

initialization

finalization
  if Assigned(GLanguageManager) then
    GLanguageManager.Free;

end.

unit DependencyAnalyzer;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.StrUtils, System.Generics.Collections,
  Winapi.Windows, System.Win.Registry, Winapi.ShlObj, DataTypes, ConfigManager;

type
  // 依赖类型
  TDependencyType = (dtUnknown, dtRegistry, dtShortcut, dtConfig, dtLibrary, dtService, dtProcess);
  
  // 依赖级别
  TDependencyLevel = (dlLow, dlMedium, dlHigh, dlCritical);
  
  // 依赖信息
  TDependencyInfo = record
    DependencyType: TDependencyType;
    Level: TDependencyLevel;
    SourcePath: string;
    TargetPath: string;
    Description: string;
    RegistryKey: string;
    ValueName: string;
    CanRelocate: Boolean;
    RequiresUpdate: Boolean;
    UpdateMethod: string;
  end;
  
  // 依赖分析结果
  TDependencyAnalysisResult = record
    FilePath: string;
    Dependencies: TArray<TDependencyInfo>;
    TotalDependencies: Integer;
    CriticalDependencies: Integer;
    HighDependencies: Integer;
    MediumDependencies: Integer;
    LowDependencies: Integer;
    CanSafelyMove: Boolean;
    RequiresRegistryUpdate: Boolean;
    RequiresShortcutUpdate: Boolean;
    RequiresConfigUpdate: Boolean;
    Recommendations: TArray<string>;
  end;
  
  // 依赖关系分析器
  TDependencyAnalyzer = class
  private
    FConfigManager: TConfigManager;
    FRegistryKeys: TStringList;
    FShortcutPaths: TStringList;
    FConfigPaths: TStringList;
    FSystemLibraries: TStringList;
    
    // 内部分析方法
    function AnalyzeRegistryDependencies(const AFilePath: string): TArray<TDependencyInfo>;
    function AnalyzeShortcutDependencies(const AFilePath: string): TArray<TDependencyInfo>;
    function AnalyzeConfigDependencies(const AFilePath: string): TArray<TDependencyInfo>;
    function AnalyzeLibraryDependencies(const AFilePath: string): TArray<TDependencyInfo>;
    function AnalyzeServiceDependencies(const AFilePath: string): TArray<TDependencyInfo>;
    function AnalyzeProcessDependencies(const AFilePath: string): TArray<TDependencyInfo>;
    
    // 辅助方法
    procedure InitializeSearchPaths;
    function SearchRegistryForPath(const AFilePath: string): TArray<TDependencyInfo>;
    function FindShortcutsPointingTo(const AFilePath: string): TArray<TDependencyInfo>;
    function FindConfigFilesReferencing(const AFilePath: string): TArray<TDependencyInfo>;
    function GetLibraryDependencies(const AFilePath: string): TArray<TDependencyInfo>;
    function IsSystemLibrary(const AFilePath: string): Boolean;
    function GetDependencyLevelString(ALevel: TDependencyLevel): string;
    function GetDependencyTypeString(AType: TDependencyType): string;
    function CombineDependencies(const AArrays: array of TArray<TDependencyInfo>): TArray<TDependencyInfo>;
    function CalculateRelocatability(const ADependencies: TArray<TDependencyInfo>): Boolean;
    function GenerateRecommendations(const ADependencies: TArray<TDependencyInfo>): TArray<string>;
    
  public
    constructor Create(AConfigManager: TConfigManager = nil);
    destructor Destroy; override;
    
    // 主要分析方法
    function AnalyzeFile(const AFilePath: string): TDependencyAnalysisResult;
    function AnalyzeDirectory(const ADirPath: string; ARecursive: Boolean = False): TArray<TDependencyAnalysisResult>;
    function BatchAnalyze(const AFilePaths: TArray<string>): TArray<TDependencyAnalysisResult>;
    
    // 依赖检查方法
    function HasCriticalDependencies(const AFilePath: string): Boolean;
    function CanSafelyRelocate(const AFilePath: string): Boolean;
    function GetRelocationRequirements(const AFilePath: string): TArray<string>;
    
    // 更新和修复方法
    function UpdateDependencies(const AOldPath, ANewPath: string): Boolean;
    function ValidateDependencies(const AFilePath: string): Boolean;
    function RepairBrokenDependencies(const AFilePath: string): Integer;
    
    // 统计和报告
    function GetDependencyStatistics(const AResults: TArray<TDependencyAnalysisResult>): string;
    function GenerateDependencyReport(const AResults: TArray<TDependencyAnalysisResult>): string;
  end;

implementation

uses
  Winapi.TlHelp32, System.DateUtils, System.RegularExpressions, Vcl.Forms;

constructor TDependencyAnalyzer.Create(AConfigManager: TConfigManager);
begin
  inherited Create;
  
  if Assigned(AConfigManager) then
    FConfigManager := AConfigManager
  else
    FConfigManager := TConfigManager.Create;
    
  FRegistryKeys := TStringList.Create;
  FShortcutPaths := TStringList.Create;
  FConfigPaths := TStringList.Create;
  FSystemLibraries := TStringList.Create;
  
  InitializeSearchPaths;
end;

destructor TDependencyAnalyzer.Destroy;
begin
  FRegistryKeys.Free;
  FShortcutPaths.Free;
  FConfigPaths.Free;
  FSystemLibraries.Free;
  
  if Assigned(FConfigManager) then
    FConfigManager.Free;
    
  inherited;
end;

// 初始化搜索路径
procedure TDependencyAnalyzer.InitializeSearchPaths;
var
  WindowsDir, ProgramFilesDir, CommonStartMenu, UserStartMenu: string;
begin
  WindowsDir := GetEnvironmentVariable('WINDIR');
  ProgramFilesDir := GetEnvironmentVariable('ProgramFiles');
  
  // 注册表搜索路径
  FRegistryKeys.Add('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths');
  FRegistryKeys.Add('HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Applications');
  FRegistryKeys.Add('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall');
  FRegistryKeys.Add('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services');
  FRegistryKeys.Add('HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run');
  FRegistryKeys.Add('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run');
  
  // 快捷方式搜索路径
  CommonStartMenu := '';
  UserStartMenu := '';
  
  // 获取开始菜单路径
  var Buffer: array[0..MAX_PATH] of Char;
  if SHGetFolderPath(0, CSIDL_COMMON_STARTMENU, 0, SHGFP_TYPE_CURRENT, Buffer) = S_OK then
    CommonStartMenu := Buffer;
  if SHGetFolderPath(0, CSIDL_STARTMENU, 0, SHGFP_TYPE_CURRENT, Buffer) = S_OK then
    UserStartMenu := Buffer;
  
  if CommonStartMenu <> '' then
    FShortcutPaths.Add(CommonStartMenu);
  if UserStartMenu <> '' then
    FShortcutPaths.Add(UserStartMenu);
  
  FShortcutPaths.Add(GetEnvironmentVariable('USERPROFILE') + '\Desktop');
  FShortcutPaths.Add(GetEnvironmentVariable('PUBLIC') + '\Desktop');
  
  // 配置文件搜索路径
  FConfigPaths.Add(GetEnvironmentVariable('APPDATA'));
  FConfigPaths.Add(GetEnvironmentVariable('LOCALAPPDATA'));
  FConfigPaths.Add(GetEnvironmentVariable('PROGRAMDATA'));
  FConfigPaths.Add(WindowsDir);
  FConfigPaths.Add(WindowsDir + '\System32');
  
  // 系统库文件
  FSystemLibraries.Add(WindowsDir + '\System32');
  FSystemLibraries.Add(WindowsDir + '\SysWOW64');
  FSystemLibraries.Add(WindowsDir + '\WinSxS');
end;

// 分析注册表依赖
function TDependencyAnalyzer.AnalyzeRegistryDependencies(const AFilePath: string): TArray<TDependencyInfo>;
var
  Results: TList<TDependencyInfo>;
  Reg: TRegistry;
  Keys, Values: TStringList;
  I, J: Integer;
  FileName, KeyName, ValueName, ValueData: string;
  Dependency: TDependencyInfo;
begin
  Results := TList<TDependencyInfo>.Create;
  Reg := TRegistry.Create(KEY_READ);
  Keys := TStringList.Create;
  Values := TStringList.Create;
  
  try
    FileName := ExtractFileName(AFilePath);
    
    // 搜索HKEY_LOCAL_MACHINE
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    
    for var RegKey in FRegistryKeys do
    begin
      if not StartsText('HKEY_LOCAL_MACHINE\', RegKey) then
        Continue;
        
      KeyName := Copy(RegKey, Length('HKEY_LOCAL_MACHINE\') + 1, MaxInt);
      
      try
        if Reg.OpenKeyReadOnly(KeyName) then
        begin
          Reg.GetKeyNames(Keys);
          Reg.GetValueNames(Values);
          
          // 检查子键
          for I := 0 to Keys.Count - 1 do
          begin
            if ContainsText(Keys[I], FileName) or ContainsText(Keys[I], ExtractFileNameWithoutExt(AFilePath)) then
            begin
              Dependency.DependencyType := dtRegistry;
              Dependency.Level := dlHigh;
              Dependency.SourcePath := AFilePath;
              Dependency.TargetPath := '';
              Dependency.Description := '注册表键引用';
              Dependency.RegistryKey := RegKey + '\' + Keys[I];
              Dependency.ValueName := '';
              Dependency.CanRelocate := True;
              Dependency.RequiresUpdate := True;
              Dependency.UpdateMethod := '更新注册表键名';
              
              Results.Add(Dependency);
            end;
          end;
          
          // 检查值
          for J := 0 to Values.Count - 1 do
          begin
            try
              ValueData := Reg.ReadString(Values[J]);
              if ContainsText(ValueData, AFilePath) or ContainsText(ValueData, FileName) then
              begin
                Dependency.DependencyType := dtRegistry;
                Dependency.Level := dlHigh;
                Dependency.SourcePath := AFilePath;
                Dependency.TargetPath := ValueData;
                Dependency.Description := '注册表值引用';
                Dependency.RegistryKey := RegKey;
                Dependency.ValueName := Values[J];
                Dependency.CanRelocate := True;
                Dependency.RequiresUpdate := True;
                Dependency.UpdateMethod := '更新注册表值';
                
                Results.Add(Dependency);
              end;
            except
              // 忽略读取错误
            end;
          end;
          
          Reg.CloseKey;
        end;
      except
        // 忽略访问错误
      end;
    end;
    
    // 搜索HKEY_CURRENT_USER
    Reg.RootKey := HKEY_CURRENT_USER;
    
    for var RegKey in FRegistryKeys do
    begin
      if not StartsText('HKEY_CURRENT_USER\', RegKey) then
        Continue;
        
      KeyName := Copy(RegKey, Length('HKEY_CURRENT_USER\') + 1, MaxInt);
      
      try
        if Reg.OpenKeyReadOnly(KeyName) then
        begin
          Reg.GetValueNames(Values);
          
          for J := 0 to Values.Count - 1 do
          begin
            try
              ValueData := Reg.ReadString(Values[J]);
              if ContainsText(ValueData, AFilePath) or ContainsText(ValueData, FileName) then
              begin
                Dependency.DependencyType := dtRegistry;
                Dependency.Level := dlMedium;
                Dependency.SourcePath := AFilePath;
                Dependency.TargetPath := ValueData;
                Dependency.Description := '用户注册表值引用';
                Dependency.RegistryKey := RegKey;
                Dependency.ValueName := Values[J];
                Dependency.CanRelocate := True;
                Dependency.RequiresUpdate := True;
                Dependency.UpdateMethod := '更新用户注册表值';
                
                Results.Add(Dependency);
              end;
            except
              // 忽略读取错误
            end;
          end;
          
          Reg.CloseKey;
        end;
      except
        // 忽略访问错误
      end;
    end;
    
    SetLength(Result, Results.Count);
    for I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
    Reg.Free;
    Keys.Free;
    Values.Free;
  end;
end;

// 分析快捷方式依赖
function TDependencyAnalyzer.AnalyzeShortcutDependencies(const AFilePath: string): TArray<TDependencyInfo>;
var
  Results: TList<TDependencyInfo>;
  SearchFiles: TArray<string>;
  I: Integer;
  Dependency: TDependencyInfo;
  ShortcutContent: string;
begin
  Results := TList<TDependencyInfo>.Create;
  
  try
    for var ShortcutPath in FShortcutPaths do
    begin
      if not DirectoryExists(ShortcutPath) then
        Continue;
        
      try
        SearchFiles := TDirectory.GetFiles(ShortcutPath, '*.lnk', TSearchOption.soAllDirectories);
        
        for I := 0 to Length(SearchFiles) - 1 do
        begin
          try
            // 简化的快捷方式内容检查
            if FileExists(SearchFiles[I]) then
            begin
              // 这里应该使用COM接口读取快捷方式，简化实现直接检查文件名
              if ContainsText(ExtractFileName(SearchFiles[I]), ExtractFileNameWithoutExt(AFilePath)) then
              begin
                Dependency.DependencyType := dtShortcut;
                Dependency.Level := dlMedium;
                Dependency.SourcePath := AFilePath;
                Dependency.TargetPath := SearchFiles[I];
                Dependency.Description := '快捷方式引用';
                Dependency.RegistryKey := '';
                Dependency.ValueName := '';
                Dependency.CanRelocate := True;
                Dependency.RequiresUpdate := True;
                Dependency.UpdateMethod := '更新快捷方式目标';
                
                Results.Add(Dependency);
              end;
            end;
          except
            // 忽略单个文件错误
          end;
        end;
        
      except
        // 忽略目录访问错误
      end;
    end;
    
    SetLength(Result, Results.Count);
    for I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
  end;
end;

// 分析配置文件依赖
function TDependencyAnalyzer.AnalyzeConfigDependencies(const AFilePath: string): TArray<TDependencyInfo>;
var
  Results: TList<TDependencyInfo>;
  SearchFiles: TArray<string>;
  I: Integer;
  Dependency: TDependencyInfo;
  ConfigContent: string;
  ConfigExtensions: TArray<string>;
begin
  Results := TList<TDependencyInfo>.Create;
  
  try
    ConfigExtensions := TArray<string>.Create('*.ini', '*.cfg', '*.conf', '*.xml', '*.json', '*.yaml', '*.yml');
    
    for var ConfigPath in FConfigPaths do
    begin
      if not DirectoryExists(ConfigPath) then
        Continue;
        
      for var Extension in ConfigExtensions do
      begin
        try
          SearchFiles := TDirectory.GetFiles(ConfigPath, Extension, TSearchOption.soTopDirectoryOnly);
          
          for I := 0 to Length(SearchFiles) - 1 do
          begin
            try
              if TFile.GetSize(SearchFiles[I]) > 10 * 1024 * 1024 then // 跳过大于10MB的文件
                Continue;
                
              ConfigContent := TFile.ReadAllText(SearchFiles[I]);
              
              if ContainsText(ConfigContent, AFilePath) or 
                 ContainsText(ConfigContent, ExtractFileName(AFilePath)) then
              begin
                Dependency.DependencyType := dtConfig;
                Dependency.Level := dlMedium;
                Dependency.SourcePath := AFilePath;
                Dependency.TargetPath := SearchFiles[I];
                Dependency.Description := '配置文件引用';
                Dependency.RegistryKey := '';
                Dependency.ValueName := '';
                Dependency.CanRelocate := True;
                Dependency.RequiresUpdate := True;
                Dependency.UpdateMethod := '更新配置文件路径';
                
                Results.Add(Dependency);
              end;
              
            except
              // 忽略单个文件错误
            end;
          end;
          
        except
          // 忽略搜索错误
        end;
      end;
    end;
    
    SetLength(Result, Results.Count);
    for I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
  end;
end;

// 分析库依赖
function TDependencyAnalyzer.AnalyzeLibraryDependencies(const AFilePath: string): TArray<TDependencyInfo>;
var
  Results: TList<TDependencyInfo>;
  Dependency: TDependencyInfo;
begin
  Results := TList<TDependencyInfo>.Create;
  
  try
    // 检查是否为系统库
    if IsSystemLibrary(AFilePath) then
    begin
      Dependency.DependencyType := dtLibrary;
      Dependency.Level := dlCritical;
      Dependency.SourcePath := AFilePath;
      Dependency.TargetPath := '';
      Dependency.Description := '系统库文件';
      Dependency.RegistryKey := '';
      Dependency.ValueName := '';
      Dependency.CanRelocate := False;
      Dependency.RequiresUpdate := False;
      Dependency.UpdateMethod := '不建议移动系统库';
      
      Results.Add(Dependency);
    end;
    
    // 检查DLL依赖（简化实现）
    if SameText(ExtractFileExt(AFilePath), '.exe') then
    begin
      // 这里应该使用PE解析器分析DLL依赖，简化实现
      Dependency.DependencyType := dtLibrary;
      Dependency.Level := dlLow;
      Dependency.SourcePath := AFilePath;
      Dependency.TargetPath := '';
      Dependency.Description := '可能的DLL依赖';
      Dependency.RegistryKey := '';
      Dependency.ValueName := '';
      Dependency.CanRelocate := True;
      Dependency.RequiresUpdate := False;
      Dependency.UpdateMethod := '检查运行时依赖';
      
      Results.Add(Dependency);
    end;
    
    SetLength(Result, Results.Count);
    for var I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
  end;
end;

// 分析服务依赖
function TDependencyAnalyzer.AnalyzeServiceDependencies(const AFilePath: string): TArray<TDependencyInfo>;
var
  Results: TList<TDependencyInfo>;
  Reg: TRegistry;
  Services: TStringList;
  I: Integer;
  ServicePath: string;
  Dependency: TDependencyInfo;
begin
  Results := TList<TDependencyInfo>.Create;
  Reg := TRegistry.Create(KEY_READ);
  Services := TStringList.Create;
  
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    
    if Reg.OpenKeyReadOnly('SYSTEM\CurrentControlSet\Services') then
    begin
      Reg.GetKeyNames(Services);
      
      for I := 0 to Services.Count - 1 do
      begin
        try
          if Reg.OpenKeyReadOnly('SYSTEM\CurrentControlSet\Services\' + Services[I]) then
          begin
            if Reg.ValueExists('ImagePath') then
            begin
              ServicePath := Reg.ReadString('ImagePath');
              
              // 清理服务路径中的参数
              if Pos(' ', ServicePath) > 0 then
                ServicePath := Copy(ServicePath, 1, Pos(' ', ServicePath) - 1);
              
              ServicePath := StringReplace(ServicePath, '"', '', [rfReplaceAll]);
              
              if SameText(ServicePath, AFilePath) or 
                 SameText(ExpandFileName(ServicePath), AFilePath) then
              begin
                Dependency.DependencyType := dtService;
                Dependency.Level := dlCritical;
                Dependency.SourcePath := AFilePath;
                Dependency.TargetPath := '';
                Dependency.Description := '系统服务: ' + Services[I];
                Dependency.RegistryKey := 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\' + Services[I];
                Dependency.ValueName := 'ImagePath';
                Dependency.CanRelocate := True;
                Dependency.RequiresUpdate := True;
                Dependency.UpdateMethod := '更新服务注册表路径';
                
                Results.Add(Dependency);
              end;
            end;
            
            Reg.CloseKey;
          end;
        except
          // 忽略单个服务错误
        end;
      end;
      
      Reg.CloseKey;
    end;
    
    SetLength(Result, Results.Count);
    for I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
    Reg.Free;
    Services.Free;
  end;
end;

// 分析进程依赖
function TDependencyAnalyzer.AnalyzeProcessDependencies(const AFilePath: string): TArray<TDependencyInfo>;
var
  Results: TList<TDependencyInfo>;
  Snapshot: THandle;
  ProcessEntry: TProcessEntry32;
  Dependency: TDependencyInfo;
begin
  Results := TList<TDependencyInfo>.Create;
  
  try
    Snapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if Snapshot = INVALID_HANDLE_VALUE then
      Exit;
      
    try
      ProcessEntry.dwSize := SizeOf(TProcessEntry32);
      
      if Process32First(Snapshot, ProcessEntry) then
      begin
        repeat
          if SameText(ProcessEntry.szExeFile, ExtractFileName(AFilePath)) then
          begin
            Dependency.DependencyType := dtProcess;
            Dependency.Level := dlCritical;
            Dependency.SourcePath := AFilePath;
            Dependency.TargetPath := '';
            Dependency.Description := '正在运行的进程';
            Dependency.RegistryKey := '';
            Dependency.ValueName := '';
            Dependency.CanRelocate := False;
            Dependency.RequiresUpdate := False;
            Dependency.UpdateMethod := '需要停止进程后才能移动';
            
            Results.Add(Dependency);
            Break; // 找到一个就够了
          end;
        until not Process32Next(Snapshot, ProcessEntry);
      end;
      
    finally
      CloseHandle(Snapshot);
    end;
    
    SetLength(Result, Results.Count);
    for var I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
  end;
end;

// 检查是否为系统库
function TDependencyAnalyzer.IsSystemLibrary(const AFilePath: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  
  for I := 0 to FSystemLibraries.Count - 1 do
  begin
    if StartsText(FSystemLibraries[I], AFilePath) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

// 获取依赖级别字符串
function TDependencyAnalyzer.GetDependencyLevelString(ALevel: TDependencyLevel): string;
begin
  case ALevel of
    dlLow: Result := '低';
    dlMedium: Result := '中';
    dlHigh: Result := '高';
    dlCritical: Result := '严重';
  else
    Result := '未知';
  end;
end;

// 获取依赖类型字符串
function TDependencyAnalyzer.GetDependencyTypeString(AType: TDependencyType): string;
begin
  case AType of
    dtRegistry: Result := '注册表';
    dtShortcut: Result := '快捷方式';
    dtConfig: Result := '配置文件';
    dtLibrary: Result := '库文件';
    dtService: Result := '系统服务';
    dtProcess: Result := '运行进程';
  else
    Result := '未知';
  end;
end;

// 合并依赖数组
function TDependencyAnalyzer.CombineDependencies(const AArrays: array of TArray<TDependencyInfo>): TArray<TDependencyInfo>;
var
  TotalCount, CurrentIndex, I, J: Integer;
begin
  TotalCount := 0;
  
  // 计算总数
  for I := 0 to Length(AArrays) - 1 do
    TotalCount := TotalCount + Length(AArrays[I]);
  
  SetLength(Result, TotalCount);
  CurrentIndex := 0;
  
  // 复制所有依赖
  for I := 0 to Length(AArrays) - 1 do
  begin
    for J := 0 to Length(AArrays[I]) - 1 do
    begin
      Result[CurrentIndex] := AArrays[I][J];
      Inc(CurrentIndex);
    end;
  end;
end;

// 计算可重定位性
function TDependencyAnalyzer.CalculateRelocatability(const ADependencies: TArray<TDependencyInfo>): Boolean;
var
  I: Integer;
begin
  Result := True;
  
  for I := 0 to Length(ADependencies) - 1 do
  begin
    if (ADependencies[I].Level = dlCritical) and (not ADependencies[I].CanRelocate) then
    begin
      Result := False;
      Break;
    end;
  end;
end;

// 生成建议
function TDependencyAnalyzer.GenerateRecommendations(const ADependencies: TArray<TDependencyInfo>): TArray<string>;
var
  Recommendations: TList<string>;
  I: Integer;
  HasRegistry, HasShortcut, HasConfig, HasService, HasProcess: Boolean;
begin
  Recommendations := TList<string>.Create;
  
  try
    HasRegistry := False;
    HasShortcut := False;
    HasConfig := False;
    HasService := False;
    HasProcess := False;
    
    // 分析依赖类型
    for I := 0 to Length(ADependencies) - 1 do
    begin
      case ADependencies[I].DependencyType of
        dtRegistry: HasRegistry := True;
        dtShortcut: HasShortcut := True;
        dtConfig: HasConfig := True;
        dtService: HasService := True;
        dtProcess: HasProcess := True;
      end;
    end;
    
    // 生成建议
    if HasProcess then
      Recommendations.Add('移动前需要停止相关进程');
    
    if HasService then
      Recommendations.Add('移动前需要停止相关系统服务');
    
    if HasRegistry then
      Recommendations.Add('移动后需要更新注册表引用');
    
    if HasShortcut then
      Recommendations.Add('移动后需要更新快捷方式目标');
    
    if HasConfig then
      Recommendations.Add('移动后需要更新配置文件路径');
    
    if Length(ADependencies) = 0 then
      Recommendations.Add('未发现明显依赖，可以安全移动');
    
    SetLength(Result, Recommendations.Count);
    for I := 0 to Recommendations.Count - 1 do
      Result[I] := Recommendations[I];
    
  finally
    Recommendations.Free;
  end;
end;

// 分析单个文件
function TDependencyAnalyzer.AnalyzeFile(const AFilePath: string): TDependencyAnalysisResult;
var
  RegistryDeps, ShortcutDeps, ConfigDeps, LibraryDeps, ServiceDeps, ProcessDeps: TArray<TDependencyInfo>;
  AllDeps: TArray<TDependencyInfo>;
  I: Integer;
begin
  Result.FilePath := AFilePath;
  Result.TotalDependencies := 0;
  Result.CriticalDependencies := 0;
  Result.HighDependencies := 0;
  Result.MediumDependencies := 0;
  Result.LowDependencies := 0;
  Result.CanSafelyMove := True;
  Result.RequiresRegistryUpdate := False;
  Result.RequiresShortcutUpdate := False;
  Result.RequiresConfigUpdate := False;
  
  if not FileExists(AFilePath) then
  begin
    SetLength(Result.Dependencies, 0);
    SetLength(Result.Recommendations, 1);
    Result.Recommendations[0] := '文件不存在';
    Exit;
  end;
  
  try
    // 执行各种依赖分析
    RegistryDeps := AnalyzeRegistryDependencies(AFilePath);
    ShortcutDeps := AnalyzeShortcutDependencies(AFilePath);
    ConfigDeps := AnalyzeConfigDependencies(AFilePath);
    LibraryDeps := AnalyzeLibraryDependencies(AFilePath);
    ServiceDeps := AnalyzeServiceDependencies(AFilePath);
    ProcessDeps := AnalyzeProcessDependencies(AFilePath);
    
    // 合并所有依赖
    AllDeps := CombineDependencies([RegistryDeps, ShortcutDeps, ConfigDeps, LibraryDeps, ServiceDeps, ProcessDeps]);
    Result.Dependencies := AllDeps;
    Result.TotalDependencies := Length(AllDeps);
    
    // 统计依赖级别
    for I := 0 to Length(AllDeps) - 1 do
    begin
      case AllDeps[I].Level of
        dlLow: Inc(Result.LowDependencies);
        dlMedium: Inc(Result.MediumDependencies);
        dlHigh: Inc(Result.HighDependencies);
        dlCritical: Inc(Result.CriticalDependencies);
      end;
      
      // 检查更新需求
      case AllDeps[I].DependencyType of
        dtRegistry: Result.RequiresRegistryUpdate := True;
        dtShortcut: Result.RequiresShortcutUpdate := True;
        dtConfig: Result.RequiresConfigUpdate := True;
      end;
    end;
    
    // 计算可重定位性
    Result.CanSafelyMove := CalculateRelocatability(AllDeps);
    
    // 生成建议
    Result.Recommendations := GenerateRecommendations(AllDeps);
    
    // 记录分析日志
    if Assigned(FConfigManager) then
    begin
      FConfigManager.LogOperation('DEPENDENCY_ANALYSIS', 'File analyzed', AFilePath, '', 'SUCCESS', 
        Format('Dependencies: %d, Critical: %d', [Result.TotalDependencies, Result.CriticalDependencies]));
    end;
    
  except
    on E: Exception do
    begin
      SetLength(Result.Dependencies, 0);
      SetLength(Result.Recommendations, 1);
      Result.Recommendations[0] := '分析异常: ' + E.Message;
      
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('DEPENDENCY_ANALYSIS', 'Analysis error', AFilePath, '', 'ERROR', E.Message);
    end;
  end;
end;

// 分析目录
function TDependencyAnalyzer.AnalyzeDirectory(const ADirPath: string; ARecursive: Boolean = False): TArray<TDependencyAnalysisResult>;
var
  Files: TArray<string>;
  Results: TList<TDependencyAnalysisResult>;
  I: Integer;
begin
  Results := TList<TDependencyAnalysisResult>.Create;
  
  try
    if ARecursive then
      Files := TDirectory.GetFiles(ADirPath, '*', TSearchOption.soAllDirectories)
    else
      Files := TDirectory.GetFiles(ADirPath);
    
    for I := 0 to Length(Files) - 1 do
    begin
      Results.Add(AnalyzeFile(Files[I]));
    end;
    
    SetLength(Result, Results.Count);
    for I := 0 to Results.Count - 1 do
      Result[I] := Results[I];
    
  finally
    Results.Free;
  end;
end;

// 批量分析
function TDependencyAnalyzer.BatchAnalyze(const AFilePaths: TArray<string>): TArray<TDependencyAnalysisResult>;
var
  I: Integer;
begin
  SetLength(Result, Length(AFilePaths));
  
  for I := 0 to Length(AFilePaths) - 1 do
  begin
    Result[I] := AnalyzeFile(AFilePaths[I]);
  end;
end;

// 检查是否有严重依赖
function TDependencyAnalyzer.HasCriticalDependencies(const AFilePath: string): Boolean;
var
  AnalysisResult: TDependencyAnalysisResult;
begin
  AnalysisResult := AnalyzeFile(AFilePath);
  Result := AnalysisResult.CriticalDependencies > 0;
end;

// 检查是否可以安全重定位
function TDependencyAnalyzer.CanSafelyRelocate(const AFilePath: string): Boolean;
var
  AnalysisResult: TDependencyAnalysisResult;
begin
  AnalysisResult := AnalyzeFile(AFilePath);
  Result := AnalysisResult.CanSafelyMove;
end;

// 获取重定位需求
function TDependencyAnalyzer.GetRelocationRequirements(const AFilePath: string): TArray<string>;
var
  AnalysisResult: TDependencyAnalysisResult;
begin
  AnalysisResult := AnalyzeFile(AFilePath);
  Result := AnalysisResult.Recommendations;
end;

// 更新依赖
function TDependencyAnalyzer.UpdateDependencies(const AOldPath, ANewPath: string): Boolean;
var
  AnalysisResult: TDependencyAnalysisResult;
  I: Integer;
  Reg: TRegistry;
  UpdateCount: Integer;
begin
  Result := True;
  UpdateCount := 0;
  
  try
    AnalysisResult := AnalyzeFile(AOldPath);
    
    Reg := TRegistry.Create(KEY_WRITE);
    try
      for I := 0 to Length(AnalysisResult.Dependencies) - 1 do
      begin
        if AnalysisResult.Dependencies[I].RequiresUpdate then
        begin
          case AnalysisResult.Dependencies[I].DependencyType of
            dtRegistry:
            begin
              // 更新注册表值
              try
                if StartsText('HKEY_LOCAL_MACHINE\', AnalysisResult.Dependencies[I].RegistryKey) then
                  Reg.RootKey := HKEY_LOCAL_MACHINE
                else if StartsText('HKEY_CURRENT_USER\', AnalysisResult.Dependencies[I].RegistryKey) then
                  Reg.RootKey := HKEY_CURRENT_USER;
                
                var KeyPath := AnalysisResult.Dependencies[I].RegistryKey;
                if StartsText('HKEY_LOCAL_MACHINE\', KeyPath) then
                  KeyPath := Copy(KeyPath, Length('HKEY_LOCAL_MACHINE\') + 1, MaxInt)
                else if StartsText('HKEY_CURRENT_USER\', KeyPath) then
                  KeyPath := Copy(KeyPath, Length('HKEY_CURRENT_USER\') + 1, MaxInt);
                
                if Reg.OpenKey(KeyPath, False) then
                begin
                  var OldValue := Reg.ReadString(AnalysisResult.Dependencies[I].ValueName);
                  var NewValue := StringReplace(OldValue, AOldPath, ANewPath, [rfReplaceAll, rfIgnoreCase]);
                  
                  if NewValue <> OldValue then
                  begin
                    Reg.WriteString(AnalysisResult.Dependencies[I].ValueName, NewValue);
                    Inc(UpdateCount);
                  end;
                  
                  Reg.CloseKey;
                end;
              except
                Result := False;
              end;
            end;
            
            // 其他类型的依赖更新可以在这里实现
            dtShortcut, dtConfig:
            begin
              // 这里可以实现快捷方式和配置文件的更新
              // 简化实现，暂时跳过
            end;
          end;
        end;
      end;
      
    finally
      Reg.Free;
    end;
    
    if Assigned(FConfigManager) then
    begin
      FConfigManager.LogOperation('DEPENDENCY_UPDATE', 'Dependencies updated', AOldPath, ANewPath, 
        Result.ToString, Format('Updated %d dependencies', [UpdateCount]));
    end;
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('DEPENDENCY_UPDATE', 'Update error', AOldPath, ANewPath, 'ERROR', E.Message);
    end;
  end;
end;

// 验证依赖
function TDependencyAnalyzer.ValidateDependencies(const AFilePath: string): Boolean;
var
  AnalysisResult: TDependencyAnalysisResult;
  I: Integer;
begin
  Result := True;
  
  try
    AnalysisResult := AnalyzeFile(AFilePath);
    
    for I := 0 to Length(AnalysisResult.Dependencies) - 1 do
    begin
      case AnalysisResult.Dependencies[I].DependencyType of
        dtShortcut, dtConfig:
        begin
          if not FileExists(AnalysisResult.Dependencies[I].TargetPath) then
          begin
            Result := False;
            Break;
          end;
        end;
      end;
    end;
    
  except
    Result := False;
  end;
end;

// 修复损坏的依赖
function TDependencyAnalyzer.RepairBrokenDependencies(const AFilePath: string): Integer;
begin
  Result := 0;
  // 这里可以实现依赖修复逻辑
  // 简化实现，返回0表示没有修复任何依赖
end;

// 获取依赖统计
function TDependencyAnalyzer.GetDependencyStatistics(const AResults: TArray<TDependencyAnalysisResult>): string;
var
  TotalFiles, TotalDeps, TotalCritical, TotalHigh, TotalMedium, TotalLow: Integer;
  SafeToMoveCount, RequiresRegistryCount, RequiresShortcutCount, RequiresConfigCount: Integer;
  I: Integer;
  Stats: TStringList;
begin
  TotalFiles := Length(AResults);
  TotalDeps := 0;
  TotalCritical := 0;
  TotalHigh := 0;
  TotalMedium := 0;
  TotalLow := 0;
  SafeToMoveCount := 0;
  RequiresRegistryCount := 0;
  RequiresShortcutCount := 0;
  RequiresConfigCount := 0;
  
  for I := 0 to Length(AResults) - 1 do
  begin
    TotalDeps := TotalDeps + AResults[I].TotalDependencies;
    TotalCritical := TotalCritical + AResults[I].CriticalDependencies;
    TotalHigh := TotalHigh + AResults[I].HighDependencies;
    TotalMedium := TotalMedium + AResults[I].MediumDependencies;
    TotalLow := TotalLow + AResults[I].LowDependencies;
    
    if AResults[I].CanSafelyMove then
      Inc(SafeToMoveCount);
    if AResults[I].RequiresRegistryUpdate then
      Inc(RequiresRegistryCount);
    if AResults[I].RequiresShortcutUpdate then
      Inc(RequiresShortcutCount);
    if AResults[I].RequiresConfigUpdate then
      Inc(RequiresConfigCount);
  end;
  
  Stats := TStringList.Create;
  try
    Stats.Add('依赖关系分析统计');
    Stats.Add('═══════════════════════');
    Stats.Add(Format('分析文件数: %d', [TotalFiles]));
    Stats.Add(Format('总依赖数: %d', [TotalDeps]));
    Stats.Add('');
    Stats.Add('依赖级别分布:');
    Stats.Add(Format('  严重: %d (%.1f%%)', [TotalCritical, TotalCritical * 100.0 / TotalDeps]));
    Stats.Add(Format('  高: %d (%.1f%%)', [TotalHigh, TotalHigh * 100.0 / TotalDeps]));
    Stats.Add(Format('  中: %d (%.1f%%)', [TotalMedium, TotalMedium * 100.0 / TotalDeps]));
    Stats.Add(Format('  低: %d (%.1f%%)', [TotalLow, TotalLow * 100.0 / TotalDeps]));
    Stats.Add('');
    Stats.Add('移动安全性:');
    Stats.Add(Format('  可安全移动: %d (%.1f%%)', [SafeToMoveCount, SafeToMoveCount * 100.0 / TotalFiles]));
    Stats.Add(Format('  需要注册表更新: %d', [RequiresRegistryCount]));
    Stats.Add(Format('  需要快捷方式更新: %d', [RequiresShortcutCount]));
    Stats.Add(Format('  需要配置文件更新: %d', [RequiresConfigCount]));
    
    Result := Stats.Text;
  finally
    Stats.Free;
  end;
end;

// 生成依赖报告
function TDependencyAnalyzer.GenerateDependencyReport(const AResults: TArray<TDependencyAnalysisResult>): string;
var
  Report: TStringList;
  I, J: Integer;
begin
  Report := TStringList.Create;
  try
    Report.Add('依赖关系分析报告');
    Report.Add('═══════════════════════');
    Report.Add(Format('生成时间: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
    Report.Add('');
    
    Report.Add(GetDependencyStatistics(AResults));
    Report.Add('');
    
    Report.Add('详细分析结果:');
    Report.Add('─────────────────────────');
    
    for I := 0 to Length(AResults) - 1 do
    begin
      Report.Add('');
      Report.Add(Format('文件: %s', [AResults[I].FilePath]));
      Report.Add(Format('总依赖数: %d', [AResults[I].TotalDependencies]));
      Report.Add(Format('可安全移动: %s', [BoolToStr(AResults[I].CanSafelyMove, True)]));
      
      if Length(AResults[I].Dependencies) > 0 then
      begin
        Report.Add('依赖详情:');
        for J := 0 to Length(AResults[I].Dependencies) - 1 do
        begin
          Report.Add(Format('  - %s (%s): %s', [
            GetDependencyTypeString(AResults[I].Dependencies[J].DependencyType),
            GetDependencyLevelString(AResults[I].Dependencies[J].Level),
            AResults[I].Dependencies[J].Description
          ]));
        end;
      end;
      
      if Length(AResults[I].Recommendations) > 0 then
      begin
        Report.Add('建议:');
        for J := 0 to Length(AResults[I].Recommendations) - 1 do
        begin
          Report.Add('  • ' + AResults[I].Recommendations[J]);
        end;
      end;
    end;
    
    Result := Report.Text;
  finally
    Report.Free;
  end;
end;

end.
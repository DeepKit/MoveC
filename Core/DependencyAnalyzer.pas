unit DependencyAnalyzer;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.StrUtils, 
  System.Generics.Collections, System.Win.Registry, Winapi.Windows,
  Winapi.ShlObj, Winapi.ActiveX, Winapi.ComObj, DataTypes, BasicProtection;

type
  // 依赖关系类型
  TDependencyType = (
    dtUnknown,           // 未知依赖
    dtRegistryKey,       // 注册表键依赖
    dtRegistryValue,     // 注册表值依赖
    dtShortcut,          // 快捷方式依赖
    dtServiceDependency, // 服务依赖
    dtDLLDependency,     // DLL依赖
    dtConfigFile,        // 配置文件依赖
    dtDataFile,          // 数据文件依赖
    dtTempFile,          // 临时文件依赖
    dtLogFile,           // 日志文件依赖
    dtCacheFile          // 缓存文件依赖
  );

  // 依赖关系信息
  TDependencyInfo = record
    DependencyType: TDependencyType;
    SourcePath: string;      // 依赖源路径
    TargetPath: string;      // 依赖目标路径
    Description: string;     // 依赖描述
    IsCritical: Boolean;     // 是否关键依赖
    CanBreak: Boolean;       // 是否可以断开
    BreakRisk: Integer;      // 断开风险等级 (0-100)
    RepairMethod: string;    // 修复方法
  end;

  // 依赖分析结果
  TDependencyAnalysisResult = record
    FilePath: string;
    Dependencies: TArray<TDependencyInfo>;
    TotalDependencies: Integer;
    CriticalDependencies: Integer;
    SafeToMove: Boolean;
    SafeToDelete: Boolean;
    RequiresUpdate: Boolean;
    UpdateInstructions: TArray<string>;
  end;

  // 依赖关系分析器
  TDependencyAnalyzer = class
  private
    FRegistryRoots: TArray<HKEY>;
    FCommonRegistryPaths: TStringList;
    FSystemDirectories: TStringList;
    FKnownServicePaths: TStringList;
    
    // 注册表依赖分析
    function AnalyzeRegistryDependencies(const AFilePath: string): TArray<TDependencyInfo>;
    function SearchRegistryForFile(const AFilePath: string; ARootKey: HKEY; 
      const AKeyPath: string): TArray<TDependencyInfo>;
    function CheckRegistryValue(const AFilePath: string; AReg: TRegistry; 
      const AValueName: string; const AKeyPath: string): TDependencyInfo;
    
    // 快捷方式依赖分析
    function AnalyzeShortcutDependencies(const AFilePath: string): TArray<TDependencyInfo>;
    function FindShortcutsPointingToFile(const AFilePath: string): TArray<string>;
    function ResolveShortcutTarget(const AShortcutPath: string): string;
    
    // 服务依赖分析
    function AnalyzeServiceDependencies(const AFilePath: string): TArray<TDependencyInfo>;
    function FindServicesUsingFile(const AFilePath: string): TArray<string>;
    function GetServiceInfo(const AServiceName: string): TDependencyInfo;
    
    // DLL依赖分析
    function AnalyzeDLLDependencies(const AFilePath: string): TArray<TDependencyInfo>;
    function GetDLLDependencies(const AFilePath: string): TArray<string>;
    function CheckDLLUsage(const ADLLPath: string): TArray<string>;
    
    // 配置文件依赖分析
    function AnalyzeConfigDependencies(const AFilePath: string): TArray<TDependencyInfo>;
    function FindConfigFilesReferencingFile(const AFilePath: string): TArray<string>;
    function AnalyzeConfigFileContent(const AConfigPath, ATargetPath: string): TDependencyInfo;
    
    // 辅助方法
    procedure InitializeKnowledgeBase;
    function IsSystemCriticalFile(const AFilePath: string): Boolean;
    function CalculateBreakRisk(const ADependency: TDependencyInfo): Integer;
    function GenerateRepairMethod(const ADependency: TDependencyInfo): string;
    function MergeDependencies(const ADependencies: array of TArray<TDependencyInfo>): TArray<TDependencyInfo>;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 主要分析方法
    function AnalyzeFileDependencies(const AFilePath: string): TDependencyAnalysisResult;
    function AnalyzeDirectoryDependencies(const ADirectoryPath: string): TArray<TDependencyAnalysisResult>;
    function BatchAnalyzeDependencies(const AFilePaths: TArray<string>): TArray<TDependencyAnalysisResult>;
    
    // 依赖修复和更新
    function GenerateUpdateScript(const AAnalysisResult: TDependencyAnalysisResult; 
      const ANewPath: string): TArray<string>;
    function ValidateDependencyUpdate(const AOldPath, ANewPath: string): Boolean;
    function UpdateDependencies(const AOldPath, ANewPath: string): Boolean;
    
    // 工具方法
    class function DependencyTypeToString(AType: TDependencyType): string;
    class function RiskLevelToString(ARiskLevel: Integer): string;
    class function RiskLevelToColor(ARiskLevel: Integer): Integer;
  end;

implementation

uses
  Vcl.Graphics, System.Win.ComObj;constructor 
TDependencyAnalyzer.Create;
begin
  inherited Create;
  
  FCommonRegistryPaths := TStringList.Create;
  FSystemDirectories := TStringList.Create;
  FKnownServicePaths := TStringList.Create;
  
  InitializeKnowledgeBase;
end;

destructor TDependencyAnalyzer.Destroy;
begin
  FCommonRegistryPaths.Free;
  FSystemDirectories.Free;
  FKnownServicePaths.Free;
  
  inherited;
end;

procedure TDependencyAnalyzer.InitializeKnowledgeBase;
begin
  // 初始化注册表根键
  SetLength(FRegistryRoots, 4);
  FRegistryRoots[0] := HKEY_LOCAL_MACHINE;
  FRegistryRoots[1] := HKEY_CURRENT_USER;
  FRegistryRoots[2] := HKEY_CLASSES_ROOT;
  FRegistryRoots[3] := HKEY_USERS;
  
  // 常见的注册表路径
  FCommonRegistryPaths.Clear;
  FCommonRegistryPaths.Add('SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths');
  FCommonRegistryPaths.Add('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall');
  FCommonRegistryPaths.Add('SOFTWARE\Microsoft\Windows\CurrentVersion\Run');
  FCommonRegistryPaths.Add('SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce');
  FCommonRegistryPaths.Add('SOFTWARE\Classes');
  FCommonRegistryPaths.Add('SYSTEM\CurrentControlSet\Services');
  FCommonRegistryPaths.Add('SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options');
  
  // 系统目录
  FSystemDirectories.Clear;
  FSystemDirectories.Add(GetEnvironmentVariable('WINDIR'));
  FSystemDirectories.Add(GetEnvironmentVariable('WINDIR') + '\System32');
  FSystemDirectories.Add(GetEnvironmentVariable('WINDIR') + '\SysWOW64');
  FSystemDirectories.Add(GetEnvironmentVariable('ProgramFiles'));
  FSystemDirectories.Add(GetEnvironmentVariable('ProgramFiles(x86)'));
  
  // 已知服务路径
  FKnownServicePaths.Clear;
  FKnownServicePaths.Add(GetEnvironmentVariable('WINDIR') + '\System32');
  FKnownServicePaths.Add(GetEnvironmentVariable('WINDIR') + '\SysWOW64');
end;

function TDependencyAnalyzer.AnalyzeFileDependencies(const AFilePath: string): TDependencyAnalysisResult;
var
  RegistryDeps, ShortcutDeps, ServiceDeps, DLLDeps, ConfigDeps: TArray<TDependencyInfo>;
  AllDependencies: TArray<TDependencyInfo>;
  CriticalCount: Integer;
  I: Integer;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  Result.FilePath := AFilePath;
  
  if not FileExists(AFilePath) then
  begin
    Result.SafeToMove := True;
    Result.SafeToDelete := True;
    Result.RequiresUpdate := False;
    Exit;
  end;
  
  try
    // 分析各种类型的依赖关系
    RegistryDeps := AnalyzeRegistryDependencies(AFilePath);
    ShortcutDeps := AnalyzeShortcutDependencies(AFilePath);
    ServiceDeps := AnalyzeServiceDependencies(AFilePath);
    DLLDeps := AnalyzeDLLDependencies(AFilePath);
    ConfigDeps := AnalyzeConfigDependencies(AFilePath);
    
    // 合并所有依赖关系
    AllDependencies := MergeDependencies([RegistryDeps, ShortcutDeps, ServiceDeps, DLLDeps, ConfigDeps]);
    
    Result.Dependencies := AllDependencies;
    Result.TotalDependencies := Length(AllDependencies);
    
    // 统计关键依赖
    CriticalCount := 0;
    for I := 0 to Length(AllDependencies) - 1 do
    begin
      if AllDependencies[I].IsCritical then
        Inc(CriticalCount);
    end;
    Result.CriticalDependencies := CriticalCount;
    
    // 判断安全性
    Result.SafeToDelete := (CriticalCount = 0) and not IsSystemCriticalFile(AFilePath);
    Result.SafeToMove := (CriticalCount <= 2) and not IsSystemCriticalFile(AFilePath);
    Result.RequiresUpdate := Result.TotalDependencies > 0;
    
    // 生成更新指令
    if Result.RequiresUpdate then
    begin
      var InstructionList := TList<string>.Create;
      try
        InstructionList.Add('文件移动后需要更新以下依赖关系：');
        
        for var Dependency in AllDependencies do
        begin
          if Dependency.IsCritical then
            InstructionList.Add('• [关键] ' + Dependency.Description + ' - ' + Dependency.RepairMethod)
          else
            InstructionList.Add('• ' + Dependency.Description + ' - ' + Dependency.RepairMethod);
        end;
        
        SetLength(Result.UpdateInstructions, InstructionList.Count);
        for I := 0 to InstructionList.Count - 1 do
          Result.UpdateInstructions[I] := InstructionList[I];
          
      finally
        InstructionList.Free;
      end;
    end;
    
  except
    on E: Exception do
    begin
      // 分析失败，设置为不安全
      Result.SafeToMove := False;
      Result.SafeToDelete := False;
      Result.RequiresUpdate := True;
      SetLength(Result.UpdateInstructions, 1);
      Result.UpdateInstructions[0] := '依赖分析失败: ' + E.Message;
    end;
  end;
end;

function TDependencyAnalyzer.AnalyzeRegistryDependencies(const AFilePath: string): TArray<TDependencyInfo>;
var
  ResultList: TList<TDependencyInfo>;
  RootKey: HKEY;
  RegistryPath: string;
  Dependencies: TArray<TDependencyInfo>;
begin
  ResultList := TList<TDependencyInfo>.Create;
  try
    // 搜索各个注册表根键
    for RootKey in FRegistryRoots do
    begin
      for RegistryPath in FCommonRegistryPaths do
      begin
        try
          Dependencies := SearchRegistryForFile(AFilePath, RootKey, RegistryPath);
          for var Dependency in Dependencies do
            ResultList.Add(Dependency);
        except
          // 忽略注册表访问错误
        end;
      end;
    end;
    
    // 转换为数组
    SetLength(Result, ResultList.Count);
    for var I := 0 to ResultList.Count - 1 do
      Result[I] := ResultList[I];
      
  finally
    ResultList.Free;
  end;
end;

function TDependencyAnalyzer.SearchRegistryForFile(const AFilePath: string; ARootKey: HKEY; 
  const AKeyPath: string): TArray<TDependencyInfo>;
var
  Reg: TRegistry;
  SubKeys, ValueNames: TStringList;
  ResultList: TList<TDependencyInfo>;
  Dependency: TDependencyInfo;
  I: Integer;
begin
  ResultList := TList<TDependencyInfo>.Create;
  SubKeys := TStringList.Create;
  ValueNames := TStringList.Create;
  
  try
    Reg := TRegistry.Create(KEY_READ);
    try
      Reg.RootKey := ARootKey;
      
      if Reg.OpenKeyReadOnly(AKeyPath) then
      begin
        try
          // 检查当前键的值
          Reg.GetValueNames(ValueNames);
          for I := 0 to ValueNames.Count - 1 do
          begin
            Dependency := CheckRegistryValue(AFilePath, Reg, ValueNames[I], AKeyPath);
            if Dependency.DependencyType <> dtUnknown then
              ResultList.Add(Dependency);
          end;
          
          // 递归检查子键（限制深度避免性能问题）
          Reg.GetKeyNames(SubKeys);
          for I := 0 to Min(SubKeys.Count - 1, 50) do // 限制最多检查50个子键
          begin
            var SubKeyDeps := SearchRegistryForFile(AFilePath, ARootKey, AKeyPath + '\' + SubKeys[I]);
            for var SubDep in SubKeyDeps do
              ResultList.Add(SubDep);
          end;
          
        finally
          Reg.CloseKey;
        end;
      end;
      
    finally
      Reg.Free;
    end;
    
    // 转换为数组
    SetLength(Result, ResultList.Count);
    for I := 0 to ResultList.Count - 1 do
      Result[I] := ResultList[I];
      
  finally
    ResultList.Free;
    SubKeys.Free;
    ValueNames.Free;
  end;
end;

function TDependencyAnalyzer.CheckRegistryValue(const AFilePath: string; AReg: TRegistry; 
  const AValueName: string; const AKeyPath: string): TDependencyInfo;
var
  ValueData: string;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  Result.DependencyType := dtUnknown;
  
  try
    if AReg.ValueExists(AValueName) then
    begin
      case AReg.GetDataType(AValueName) of
        rdString, rdExpandString:
          begin
            ValueData := AReg.ReadString(AValueName);
            
            // 检查值是否包含目标文件路径
            if ContainsText(ValueData, AFilePath) or 
               ContainsText(ValueData, ExtractFileName(AFilePath)) then
            begin
              Result.DependencyType := dtRegistryValue;
              Result.SourcePath := AKeyPath + '\' + AValueName;
              Result.TargetPath := AFilePath;
              Result.Description := Format('注册表值引用: %s = %s', [AValueName, ValueData]);
              
              // 判断是否关键
              Result.IsCritical := ContainsText(AKeyPath, 'Run') or 
                                 ContainsText(AKeyPath, 'Services') or
                                 ContainsText(AKeyPath, 'App Paths');
              
              Result.CanBreak := not Result.IsCritical;
              Result.BreakRisk := CalculateBreakRisk(Result);
              Result.RepairMethod := GenerateRepairMethod(Result);
            end;
          end;
      end;
    end;
  except
    // 忽略读取错误
  end;
end;fun
ction TDependencyAnalyzer.AnalyzeShortcutDependencies(const AFilePath: string): TArray<TDependencyInfo>;
var
  ShortcutPaths: TArray<string>;
  ResultList: TList<TDependencyInfo>;
  Dependency: TDependencyInfo;
begin
  ResultList := TList<TDependencyInfo>.Create;
  try
    // 查找指向该文件的快捷方式
    ShortcutPaths := FindShortcutsPointingToFile(AFilePath);
    
    for var ShortcutPath in ShortcutPaths do
    begin
      FillChar(Dependency, SizeOf(Dependency), 0);
      Dependency.DependencyType := dtShortcut;
      Dependency.SourcePath := ShortcutPath;
      Dependency.TargetPath := AFilePath;
      Dependency.Description := Format('快捷方式引用: %s', [ExtractFileName(ShortcutPath)]);
      Dependency.IsCritical := ContainsText(ShortcutPath, 'Desktop') or 
                              ContainsText(ShortcutPath, 'Start Menu');
      Dependency.CanBreak := True;
      Dependency.BreakRisk := CalculateBreakRisk(Dependency);
      Dependency.RepairMethod := GenerateRepairMethod(Dependency);
      
      ResultList.Add(Dependency);
    end;
    
    // 转换为数组
    SetLength(Result, ResultList.Count);
    for var I := 0 to ResultList.Count - 1 do
      Result[I] := ResultList[I];
      
  finally
    ResultList.Free;
  end;
end;

function TDependencyAnalyzer.FindShortcutsPointingToFile(const AFilePath: string): TArray<string>;
var
  SearchPaths: TArray<string>;
  ResultList: TList<string>;
  Files: TArray<string>;
  TargetPath: string;
begin
  ResultList := TList<string>.Create;
  try
    // 定义搜索路径
    SearchPaths := TArray<string>.Create(
      GetEnvironmentVariable('USERPROFILE') + '\Desktop',
      GetEnvironmentVariable('APPDATA') + '\Microsoft\Windows\Start Menu',
      GetEnvironmentVariable('ALLUSERSPROFILE') + '\Microsoft\Windows\Start Menu',
      GetEnvironmentVariable('USERPROFILE') + '\Links'
    );
    
    for var SearchPath in SearchPaths do
    begin
      if DirectoryExists(SearchPath) then
      begin
        try
          Files := TDirectory.GetFiles(SearchPath, '*.lnk', TSearchOption.soAllDirectories);
          
          for var ShortcutFile in Files do
          begin
            try
              TargetPath := ResolveShortcutTarget(ShortcutFile);
              if SameText(TargetPath, AFilePath) then
                ResultList.Add(ShortcutFile);
            except
              // 忽略快捷方式解析错误
            end;
          end;
        except
          // 忽略目录访问错误
        end;
      end;
    end;
    
    // 转换为数组
    SetLength(Result, ResultList.Count);
    for var I := 0 to ResultList.Count - 1 do
      Result[I] := ResultList[I];
      
  finally
    ResultList.Free;
  end;
end;

function TDependencyAnalyzer.ResolveShortcutTarget(const AShortcutPath: string): string;
var
  ShellLink: IShellLink;
  PersistFile: IPersistFile;
  TargetPath: array[0..MAX_PATH-1] of Char;
  FindData: TWin32FindData;
begin
  Result := '';
  
  try
    // 创建Shell Link对象
    ShellLink := CreateComObject(CLSID_ShellLink) as IShellLink;
    PersistFile := ShellLink as IPersistFile;
    
    // 加载快捷方式文件
    if SUCCEEDED(PersistFile.Load(PWideChar(AShortcutPath), STGM_READ)) then
    begin
      // 获取目标路径
      if SUCCEEDED(ShellLink.GetPath(TargetPath, MAX_PATH, FindData, SLGP_UNCPRIORITY)) then
      begin
        Result := TargetPath;
      end;
    end;
  except
    // 忽略COM错误
  end;
end;

function TDependencyAnalyzer.AnalyzeServiceDependencies(const AFilePath: string): TArray<TDependencyInfo>;
var
  ServiceNames: TArray<string>;
  ResultList: TList<TDependencyInfo>;
  Dependency: TDependencyInfo;
begin
  ResultList := TList<TDependencyInfo>.Create;
  try
    // 查找使用该文件的服务
    ServiceNames := FindServicesUsingFile(AFilePath);
    
    for var ServiceName in ServiceNames do
    begin
      Dependency := GetServiceInfo(ServiceName);
      if Dependency.DependencyType <> dtUnknown then
      begin
        Dependency.TargetPath := AFilePath;
        ResultList.Add(Dependency);
      end;
    end;
    
    // 转换为数组
    SetLength(Result, ResultList.Count);
    for var I := 0 to ResultList.Count - 1 do
      Result[I] := ResultList[I];
      
  finally
    ResultList.Free;
  end;
end;

function TDependencyAnalyzer.FindServicesUsingFile(const AFilePath: string): TArray<string>;
var
  Reg: TRegistry;
  ServiceKeys: TStringList;
  ResultList: TList<string>;
  ImagePath: string;
  I: Integer;
begin
  ResultList := TList<string>.Create;
  ServiceKeys := TStringList.Create;
  
  try
    Reg := TRegistry.Create(KEY_READ);
    try
      Reg.RootKey := HKEY_LOCAL_MACHINE;
      
      if Reg.OpenKeyReadOnly('SYSTEM\CurrentControlSet\Services') then
      begin
        try
          Reg.GetKeyNames(ServiceKeys);
          
          for I := 0 to ServiceKeys.Count - 1 do
          begin
            if Reg.OpenKeyReadOnly('SYSTEM\CurrentControlSet\Services\' + ServiceKeys[I]) then
            begin
              try
                if Reg.ValueExists('ImagePath') then
                begin
                  ImagePath := Reg.ReadString('ImagePath');
                  
                  // 清理路径中的参数
                  if StartsText('"', ImagePath) then
                  begin
                    var QuotePos := Pos('"', Copy(ImagePath, 2, Length(ImagePath)));
                    if QuotePos > 0 then
                      ImagePath := Copy(ImagePath, 2, QuotePos - 1);
                  end
                  else
                  begin
                    var SpacePos := Pos(' ', ImagePath);
                    if SpacePos > 0 then
                      ImagePath := Copy(ImagePath, 1, SpacePos - 1);
                  end;
                  
                  // 展开环境变量
                  if ContainsText(ImagePath, '%') then
                  begin
                    var Buffer: array[0..MAX_PATH-1] of Char;
                    if ExpandEnvironmentStrings(PChar(ImagePath), Buffer, MAX_PATH) > 0 then
                      ImagePath := Buffer;
                  end;
                  
                  // 检查是否匹配目标文件
                  if SameText(ImagePath, AFilePath) then
                    ResultList.Add(ServiceKeys[I]);
                end;
              finally
                Reg.CloseKey;
              end;
            end;
          end;
          
        finally
          Reg.CloseKey;
        end;
      end;
      
    finally
      Reg.Free;
    end;
    
    // 转换为数组
    SetLength(Result, ResultList.Count);
    for I := 0 to ResultList.Count - 1 do
      Result[I] := ResultList[I];
      
  finally
    ResultList.Free;
    ServiceKeys.Free;
  end;
end;

function TDependencyAnalyzer.GetServiceInfo(const AServiceName: string): TDependencyInfo;
var
  Reg: TRegistry;
  DisplayName, Description: string;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  Result.DependencyType := dtUnknown;
  
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    
    if Reg.OpenKeyReadOnly('SYSTEM\CurrentControlSet\Services\' + AServiceName) then
    begin
      try
        Result.DependencyType := dtServiceDependency;
        Result.SourcePath := 'SERVICE:' + AServiceName;
        
        // 获取服务显示名称
        if Reg.ValueExists('DisplayName') then
          DisplayName := Reg.ReadString('DisplayName')
        else
          DisplayName := AServiceName;
        
        // 获取服务描述
        if Reg.ValueExists('Description') then
          Description := Reg.ReadString('Description')
        else
          Description := '系统服务';
        
        Result.Description := Format('服务依赖: %s (%s)', [DisplayName, Description]);
        Result.IsCritical := True; // 服务依赖通常是关键的
        Result.CanBreak := False;  // 不建议断开服务依赖
        Result.BreakRisk := CalculateBreakRisk(Result);
        Result.RepairMethod := GenerateRepairMethod(Result);
        
      finally
        Reg.CloseKey;
      end;
    end;
    
  finally
    Reg.Free;
  end;
end;functio
n TDependencyAnalyzer.AnalyzeDLLDependencies(const AFilePath: string): TArray<TDependencyInfo>;
var
  DLLDependencies: TArray<string>;
  UsageFiles: TArray<string>;
  ResultList: TList<TDependencyInfo>;
  Dependency: TDependencyInfo;
begin
  ResultList := TList<TDependencyInfo>.Create;
  try
    // 如果是DLL文件，检查哪些程序使用了它
    if SameText(ExtractFileExt(AFilePath), '.dll') then
    begin
      UsageFiles := CheckDLLUsage(AFilePath);
      
      for var UsageFile in UsageFiles do
      begin
        FillChar(Dependency, SizeOf(Dependency), 0);
        Dependency.DependencyType := dtDLLDependency;
        Dependency.SourcePath := UsageFile;
        Dependency.TargetPath := AFilePath;
        Dependency.Description := Format('DLL依赖: %s 使用 %s', 
          [ExtractFileName(UsageFile), ExtractFileName(AFilePath)]);
        Dependency.IsCritical := IsSystemCriticalFile(UsageFile);
        Dependency.CanBreak := not Dependency.IsCritical;
        Dependency.BreakRisk := CalculateBreakRisk(Dependency);
        Dependency.RepairMethod := GenerateRepairMethod(Dependency);
        
        ResultList.Add(Dependency);
      end;
    end
    else if SameText(ExtractFileExt(AFilePath), '.exe') then
    begin
      // 如果是EXE文件，检查它依赖的DLL
      DLLDependencies := GetDLLDependencies(AFilePath);
      
      for var DLLPath in DLLDependencies do
      begin
        FillChar(Dependency, SizeOf(Dependency), 0);
        Dependency.DependencyType := dtDLLDependency;
        Dependency.SourcePath := AFilePath;
        Dependency.TargetPath := DLLPath;
        Dependency.Description := Format('DLL依赖: %s 需要 %s', 
          [ExtractFileName(AFilePath), ExtractFileName(DLLPath)]);
        Dependency.IsCritical := IsSystemCriticalFile(DLLPath);
        Dependency.CanBreak := False; // 程序依赖的DLL不能断开
        Dependency.BreakRisk := CalculateBreakRisk(Dependency);
        Dependency.RepairMethod := GenerateRepairMethod(Dependency);
        
        ResultList.Add(Dependency);
      end;
    end;
    
    // 转换为数组
    SetLength(Result, ResultList.Count);
    for var I := 0 to ResultList.Count - 1 do
      Result[I] := ResultList[I];
      
  finally
    ResultList.Free;
  end;
end;

function TDependencyAnalyzer.GetDLLDependencies(const AFilePath: string): TArray<string>;
var
  ResultList: TList<string>;
begin
  ResultList := TList<string>.Create;
  try
    // 简化实现：基于常见的系统DLL
    // 实际实现需要解析PE文件的导入表
    if SameText(ExtractFileExt(AFilePath), '.exe') then
    begin
      ResultList.Add(GetEnvironmentVariable('WINDIR') + '\System32\kernel32.dll');
      ResultList.Add(GetEnvironmentVariable('WINDIR') + '\System32\user32.dll');
      ResultList.Add(GetEnvironmentVariable('WINDIR') + '\System32\gdi32.dll');
      ResultList.Add(GetEnvironmentVariable('WINDIR') + '\System32\ntdll.dll');
    end;
    
    // 转换为数组
    SetLength(Result, ResultList.Count);
    for var I := 0 to ResultList.Count - 1 do
      Result[I] := ResultList[I];
      
  finally
    ResultList.Free;
  end;
end;

function TDependencyAnalyzer.CheckDLLUsage(const ADLLPath: string): TArray<string>;
var
  ResultList: TList<string>;
  SearchDirs: TArray<string>;
  Files: TArray<string>;
begin
  ResultList := TList<string>.Create;
  try
    // 简化实现：在常见目录中搜索可能使用该DLL的程序
    SearchDirs := TArray<string>.Create(
      GetEnvironmentVariable('ProgramFiles'),
      GetEnvironmentVariable('ProgramFiles(x86)'),
      ExtractFilePath(ADLLPath)
    );
    
    for var SearchDir in SearchDirs do
    begin
      if DirectoryExists(SearchDir) then
      begin
        try
          Files := TDirectory.GetFiles(SearchDir, '*.exe', TSearchOption.soTopDirectoryOnly);
          
          // 简化检查：假设同目录下的EXE文件可能使用该DLL
          for var ExeFile in Files do
          begin
            if SameText(ExtractFilePath(ExeFile), ExtractFilePath(ADLLPath)) then
              ResultList.Add(ExeFile);
          end;
        except
          // 忽略目录访问错误
        end;
      end;
    end;
    
    // 转换为数组
    SetLength(Result, ResultList.Count);
    for var I := 0 to ResultList.Count - 1 do
      Result[I] := ResultList[I];
      
  finally
    ResultList.Free;
  end;
end;

function TDependencyAnalyzer.AnalyzeConfigDependencies(const AFilePath: string): TArray<TDependencyInfo>;
var
  ConfigFiles: TArray<string>;
  ResultList: TList<TDependencyInfo>;
  Dependency: TDependencyInfo;
begin
  ResultList := TList<TDependencyInfo>.Create;
  try
    // 查找可能引用该文件的配置文件
    ConfigFiles := FindConfigFilesReferencingFile(AFilePath);
    
    for var ConfigFile in ConfigFiles do
    begin
      Dependency := AnalyzeConfigFileContent(ConfigFile, AFilePath);
      if Dependency.DependencyType <> dtUnknown then
        ResultList.Add(Dependency);
    end;
    
    // 转换为数组
    SetLength(Result, ResultList.Count);
    for var I := 0 to ResultList.Count - 1 do
      Result[I] := ResultList[I];
      
  finally
    ResultList.Free;
  end;
end;

function TDependencyAnalyzer.FindConfigFilesReferencingFile(const AFilePath: string): TArray<string>;
var
  SearchDirs: TArray<string>;
  ConfigExtensions: TArray<string>;
  ResultList: TList<string>;
  Files: TArray<string>;
  Content: string;
begin
  ResultList := TList<string>.Create;
  try
    // 定义搜索目录
    SearchDirs := TArray<string>.Create(
      ExtractFilePath(AFilePath),
      GetEnvironmentVariable('APPDATA'),
      GetEnvironmentVariable('LOCALAPPDATA'),
      GetEnvironmentVariable('ProgramData')
    );
    
    // 定义配置文件扩展名
    ConfigExtensions := TArray<string>.Create('*.ini', '*.cfg', '*.conf', '*.config', '*.xml', '*.json');
    
    for var SearchDir in SearchDirs do
    begin
      if DirectoryExists(SearchDir) then
      begin
        for var Extension in ConfigExtensions do
        begin
          try
            Files := TDirectory.GetFiles(SearchDir, Extension, TSearchOption.soTopDirectoryOnly);
            
            for var ConfigFile in Files do
            begin
              try
                // 检查文件内容是否包含目标文件路径
                Content := TFile.ReadAllText(ConfigFile);
                if ContainsText(Content, AFilePath) or 
                   ContainsText(Content, ExtractFileName(AFilePath)) then
                begin
                  ResultList.Add(ConfigFile);
                end;
              except
                // 忽略文件读取错误
              end;
            end;
          except
            // 忽略目录访问错误
          end;
        end;
      end;
    end;
    
    // 转换为数组
    SetLength(Result, ResultList.Count);
    for var I := 0 to ResultList.Count - 1 do
      Result[I] := ResultList[I];
      
  finally
    ResultList.Free;
  end;
end;

function TDependencyAnalyzer.AnalyzeConfigFileContent(const AConfigPath, ATargetPath: string): TDependencyInfo;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  
  try
    if FileExists(AConfigPath) then
    begin
      Result.DependencyType := dtConfigFile;
      Result.SourcePath := AConfigPath;
      Result.TargetPath := ATargetPath;
      Result.Description := Format('配置文件引用: %s', [ExtractFileName(AConfigPath)]);
      Result.IsCritical := ContainsText(AConfigPath, 'system') or 
                          ContainsText(AConfigPath, 'config');
      Result.CanBreak := True;
      Result.BreakRisk := CalculateBreakRisk(Result);
      Result.RepairMethod := GenerateRepairMethod(Result);
    end
    else
    begin
      Result.DependencyType := dtUnknown;
    end;
  except
    Result.DependencyType := dtUnknown;
  end;
end;// 辅助方法实现

function TDependencyAnalyzer.IsSystemCriticalFile(const AFilePath: string): Boolean;
var
  FileName: string;
  FilePath: string;
begin
  FileName := LowerCase(ExtractFileName(AFilePath));
  FilePath := LowerCase(AFilePath);
  
  // 检查关键系统文件
  Result := (FileName = 'ntoskrnl.exe') or (FileName = 'kernel32.dll') or
            (FileName = 'user32.dll') or (FileName = 'gdi32.dll') or
            (FileName = 'ntdll.dll') or (FileName = 'advapi32.dll');
  
  // 检查系统目录
  if not Result then
  begin
    for var SysDir in FSystemDirectories do
    begin
      if StartsText(LowerCase(SysDir), FilePath) then
      begin
        Result := True;
        Break;
      end;
    end;
  end;
end;

function TDependencyAnalyzer.CalculateBreakRisk(const ADependency: TDependencyInfo): Integer;
begin
  Result := 30; // 基础风险
  
  case ADependency.DependencyType of
    dtRegistryKey, dtRegistryValue:
      begin
        if ADependency.IsCritical then
          Result := Result + 40
        else
          Result := Result + 20;
      end;
    dtShortcut:
      Result := Result + 10;
    dtServiceDependency:
      Result := Result + 50;
    dtDLLDependency:
      begin
        if ADependency.IsCritical then
          Result := Result + 45
        else
          Result := Result + 25;
      end;
    dtConfigFile:
      Result := Result + 15;
  else
    Result := Result + 10;
  end;
  
  // 限制在0-100范围内
  Result := Max(0, Min(100, Result));
end;

function TDependencyAnalyzer.GenerateRepairMethod(const ADependency: TDependencyInfo): string;
begin
  case ADependency.DependencyType of
    dtRegistryKey, dtRegistryValue:
      Result := '更新注册表中的路径引用';
    dtShortcut:
      Result := '更新快捷方式的目标路径';
    dtServiceDependency:
      Result := '更新服务配置中的可执行文件路径';
    dtDLLDependency:
      Result := '确保DLL文件在系统路径中可访问';
    dtConfigFile:
      Result := '更新配置文件中的路径设置';
  else
    Result := '手动检查和更新相关配置';
  end;
end;

function TDependencyAnalyzer.MergeDependencies(const ADependencies: array of TArray<TDependencyInfo>): TArray<TDependencyInfo>;
var
  ResultList: TList<TDependencyInfo>;
  I, J: Integer;
begin
  ResultList := TList<TDependencyInfo>.Create;
  try
    // 合并所有依赖数组
    for I := 0 to Length(ADependencies) - 1 do
    begin
      for J := 0 to Length(ADependencies[I]) - 1 do
      begin
        ResultList.Add(ADependencies[I][J]);
      end;
    end;
    
    // 转换为数组
    SetLength(Result, ResultList.Count);
    for I := 0 to ResultList.Count - 1 do
      Result[I] := ResultList[I];
      
  finally
    ResultList.Free;
  end;
end;// 批量分析和更
新方法
function TDependencyAnalyzer.AnalyzeDirectoryDependencies(const ADirectoryPath: string): TArray<TDependencyAnalysisResult>;
var
  Files: TArray<string>;
  ResultList: TList<TDependencyAnalysisResult>;
begin
  ResultList := TList<TDependencyAnalysisResult>.Create;
  try
    if DirectoryExists(ADirectoryPath) then
    begin
      Files := TDirectory.GetFiles(ADirectoryPath, '*', TSearchOption.soTopDirectoryOnly);
      
      for var FilePath in Files do
      begin
        var Analysis := AnalyzeFileDependencies(FilePath);
        ResultList.Add(Analysis);
      end;
    end;
    
    // 转换为数组
    SetLength(Result, ResultList.Count);
    for var I := 0 to ResultList.Count - 1 do
      Result[I] := ResultList[I];
      
  finally
    ResultList.Free;
  end;
end;

function TDependencyAnalyzer.BatchAnalyzeDependencies(const AFilePaths: TArray<string>): TArray<TDependencyAnalysisResult>;
var
  ResultList: TList<TDependencyAnalysisResult>;
begin
  ResultList := TList<TDependencyAnalysisResult>.Create;
  try
    for var FilePath in AFilePaths do
    begin
      var Analysis := AnalyzeFileDependencies(FilePath);
      ResultList.Add(Analysis);
    end;
    
    // 转换为数组
    SetLength(Result, ResultList.Count);
    for var I := 0 to ResultList.Count - 1 do
      Result[I] := ResultList[I];
      
  finally
    ResultList.Free;
  end;
end;

function TDependencyAnalyzer.GenerateUpdateScript(const AAnalysisResult: TDependencyAnalysisResult; 
  const ANewPath: string): TArray<string>;
var
  ScriptList: TList<string>;
begin
  ScriptList := TList<string>.Create;
  try
    ScriptList.Add('REM 依赖关系更新脚本');
    ScriptList.Add('REM 原路径: ' + AAnalysisResult.FilePath);
    ScriptList.Add('REM 新路径: ' + ANewPath);
    ScriptList.Add('');
    
    for var Dependency in AAnalysisResult.Dependencies do
    begin
      case Dependency.DependencyType of
        dtRegistryValue:
          ScriptList.Add(Format('reg add "%s" /v "%s" /d "%s" /f', 
            [ExtractFilePath(Dependency.SourcePath), 
             ExtractFileName(Dependency.SourcePath), 
             StringReplace(Dependency.TargetPath, AAnalysisResult.FilePath, ANewPath, [rfIgnoreCase])]));
        dtShortcut:
          ScriptList.Add(Format('REM 更新快捷方式: %s', [Dependency.SourcePath]));
        dtConfigFile:
          ScriptList.Add(Format('REM 更新配置文件: %s', [Dependency.SourcePath]));
      end;
    end;
    
    // 转换为数组
    SetLength(Result, ScriptList.Count);
    for var I := 0 to ScriptList.Count - 1 do
      Result[I] := ScriptList[I];
      
  finally
    ScriptList.Free;
  end;
end;

function TDependencyAnalyzer.ValidateDependencyUpdate(const AOldPath, ANewPath: string): Boolean;
begin
  // 简化验证：检查新路径是否存在
  Result := FileExists(ANewPath) or DirectoryExists(ExtractFilePath(ANewPath));
end;

function TDependencyAnalyzer.UpdateDependencies(const AOldPath, ANewPath: string): Boolean;
var
  Analysis: TDependencyAnalysisResult;
begin
  Result := False;
  
  try
    // 分析依赖关系
    Analysis := AnalyzeFileDependencies(AOldPath);
    
    if Analysis.TotalDependencies = 0 then
    begin
      Result := True; // 没有依赖关系，更新成功
      Exit;
    end;
    
    // 这里应该实现实际的依赖更新逻辑
    // 由于涉及注册表和文件修改，这里只返回验证结果
    Result := ValidateDependencyUpdate(AOldPath, ANewPath);
    
  except
    Result := False;
  end;
end;// 工具
方法
class function TDependencyAnalyzer.DependencyTypeToString(AType: TDependencyType): string;
begin
  case AType of
    dtUnknown: Result := '未知依赖';
    dtRegistryKey: Result := '注册表键';
    dtRegistryValue: Result := '注册表值';
    dtShortcut: Result := '快捷方式';
    dtServiceDependency: Result := '服务依赖';
    dtDLLDependency: Result := 'DLL依赖';
    dtConfigFile: Result := '配置文件';
    dtDataFile: Result := '数据文件';
    dtTempFile: Result := '临时文件';
    dtLogFile: Result := '日志文件';
    dtCacheFile: Result := '缓存文件';
  else
    Result := '其他依赖';
  end;
end;

class function TDependencyAnalyzer.RiskLevelToString(ARiskLevel: Integer): string;
begin
  if ARiskLevel >= 80 then
    Result := '极高风险'
  else if ARiskLevel >= 60 then
    Result := '高风险'
  else if ARiskLevel >= 40 then
    Result := '中等风险'
  else if ARiskLevel >= 20 then
    Result := '低风险'
  else
    Result := '极低风险';
end;

class function TDependencyAnalyzer.RiskLevelToColor(ARiskLevel: Integer): Integer;
begin
  if ARiskLevel >= 80 then
    Result := clRed
  else if ARiskLevel >= 60 then
    Result := clMaroon
  else if ARiskLevel >= 40 then
    Result := clOlive
  else if ARiskLevel >= 20 then
    Result := clYellow
  else
    Result := clGreen;
end;

end.
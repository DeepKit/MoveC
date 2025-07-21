unit FileAnalyzer;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Win.Registry, System.IOUtils, System.StrUtils,
  System.Generics.Collections, DataTypes, IFileAnalyzer2;

type
  // 文件分析器具体实现
  TFileAnalyzer = class(TInterfacedObject, IFileAnalyzer)
  private
    // 系统关键目录列表
    FSystemDirectories: TArray<string>;
    FSystemFileExtensions: TArray<string>;
    FUnsafeDirectories: TArray<string>;
    
    procedure InitializeSystemPaths;
    function IsSystemDirectory(const APath: string): Boolean;
    function IsSystemFile(const AFilePath: string): Boolean;
    function IsExecutableFile(const AFilePath: string): Boolean;
    function CheckFileInUse(const AFilePath: string): Boolean;
    function AnalyzeFileType(const AFilePath: string): TSymlinkFeasibility;
    function CheckRegistryDependencies(const AFilePath: string): TArray<string>;
    function CheckShortcutDependencies(const AFilePath: string): TArray<string>;
    function CheckApplicationDependencies(const AFilePath: string): TArray<string>;
    function RequiresSystemRestart(const AFilePath: string): Boolean;
    function CanCreateSymbolicLink(const AFilePath: string): Boolean;
    function GetFeasibilityReason(const AFilePath: string; AFeasibility: TSymlinkFeasibility): string;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // IFileAnalyzer 接口实现
    function AnalyzeFile(const AFilePath: string): TFileAnalysisResult;
    function AnalyzeDirectory(const ADirPath: string): TArray<TFileAnalysisResult>;
    function CheckDependencies(const AFilePath: string): TArray<string>;
    function EvaluateSymlinkFeasibility(const AFilePath: string): TSymlinkFeasibility;
  end;

implementation

uses
  Vcl.Forms, Winapi.TlHelp32, Winapi.PsAPI;

constructor TFileAnalyzer.Create;
begin
  inherited Create;
  InitializeSystemPaths;
end;

destructor TFileAnalyzer.Destroy;
begin
  inherited;
end;

// 初始化系统路径
procedure TFileAnalyzer.InitializeSystemPaths;
var
  WindowsDir, SystemDir, ProgramFilesDir: string;
begin
  WindowsDir := GetEnvironmentVariable('WINDIR');
  SystemDir := WindowsDir + '\System32';
  ProgramFilesDir := GetEnvironmentVariable('ProgramFiles');
  
  // 系统关键目录
  FSystemDirectories := [
    WindowsDir,
    SystemDir,
    WindowsDir + '\SysWOW64',
    WindowsDir + '\WinSxS',
    WindowsDir + '\Boot',
    WindowsDir + '\Fonts',
    WindowsDir + '\Cursors',
    WindowsDir + '\Media',
    WindowsDir + '\Resources',
    WindowsDir + '\assembly'
  ];
  
  // 系统文件扩展名
  FSystemFileExtensions := [
    '.dll', '.sys', '.exe', '.ocx', '.cpl', '.drv', '.scr',
    '.msc', '.msi', '.cab', '.inf', '.cat', '.manifest'
  ];
  
  // 不安全目录（绝对不能移动）
  FUnsafeDirectories := [
    WindowsDir + '\System32',
    WindowsDir + '\SysWOW64',
    WindowsDir + '\WinSxS',
    WindowsDir + '\Boot',
    ProgramFilesDir + '\Windows NT',
    ProgramFilesDir + '\WindowsApps'
  ];
end;

// 检查是否为系统目录
function TFileAnalyzer.IsSystemDirectory(const APath: string): Boolean;
var
  SystemDir: string;
begin
  Result := False;
  
  for SystemDir in FSystemDirectories do
  begin
    if StartsText(SystemDir, APath) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

// 检查是否为系统文件
function TFileAnalyzer.IsSystemFile(const AFilePath: string): Boolean;
var
  FileExt: string;
  SystemExt: string;
begin
  Result := False;
  
  // 检查路径
  if IsSystemDirectory(ExtractFilePath(AFilePath)) then
  begin
    Result := True;
    Exit;
  end;
  
  // 检查扩展名
  FileExt := LowerCase(ExtractFileExt(AFilePath));
  for SystemExt in FSystemFileExtensions do
  begin
    if SameText(FileExt, SystemExt) then
    begin
      // 进一步检查是否在系统目录中
      if IsSystemDirectory(ExtractFilePath(AFilePath)) then
      begin
        Result := True;
        Break;
      end;
    end;
  end;
  
  // 检查文件属性
  if not Result then
  begin
    var FileAttrs := GetFileAttributes(PChar(AFilePath));
    if (FileAttrs <> INVALID_FILE_ATTRIBUTES) and (FileAttrs and FILE_ATTRIBUTE_SYSTEM <> 0) then
      Result := True;
  end;
end;

// 检查是否为可执行文件
function TFileAnalyzer.IsExecutableFile(const AFilePath: string): Boolean;
var
  FileExt: string;
begin
  FileExt := LowerCase(ExtractFileExt(AFilePath));
  Result := (FileExt = '.exe') or (FileExt = '.com') or (FileExt = '.bat') or 
            (FileExt = '.cmd') or (FileExt = '.scr') or (FileExt = '.msi');
end;

// 检查文件是否正在使用
function TFileAnalyzer.CheckFileInUse(const AFilePath: string): Boolean;
var
  FileHandle: THandle;
begin
  Result := False;
  
  if not FileExists(AFilePath) then
    Exit;
    
  // 尝试以独占模式打开文件
  FileHandle := CreateFile(
    PChar(AFilePath),
    GENERIC_READ or GENERIC_WRITE,
    0, // 不共享
    nil,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0
  );
  
  if FileHandle = INVALID_HANDLE_VALUE then
  begin
    // 如果无法独占打开，可能正在使用
    var LastError := GetLastError;
    Result := (LastError = ERROR_SHARING_VIOLATION) or 
              (LastError = ERROR_ACCESS_DENIED);
  end
  else
  begin
    CloseHandle(FileHandle);
    Result := False;
  end;
end;

// 分析文件类型安全性
function TFileAnalyzer.AnalyzeFileType(const AFilePath: string): TSymlinkFeasibility;
var
  UnsafeDir: string;
begin
  // 检查是否在绝对不安全的目录中
  for UnsafeDir in FUnsafeDirectories do
  begin
    if StartsText(UnsafeDir, AFilePath) then
    begin
      Result := sfCannotMove;
      Exit;
    end;
  end;
  
  // 检查是否为系统文件
  if IsSystemFile(AFilePath) then
  begin
    Result := sfCannotMove;
    Exit;
  end;
  
  // 检查是否为可执行文件
  if IsExecutableFile(AFilePath) then
  begin
    if IsSystemDirectory(ExtractFilePath(AFilePath)) then
      Result := sfCannotMove
    else
      Result := sfRisky; // 用户程序需要谨慎处理
    Exit;
  end;
  
  // 检查是否正在使用
  if CheckFileInUse(AFilePath) then
  begin
    Result := sfRisky;
    Exit;
  end;
  
  // 默认为可链接
  Result := sfCanLink;
end;

// 检查注册表依赖
function TFileAnalyzer.CheckRegistryDependencies(const AFilePath: string): TArray<string>;
var
  Dependencies: TStringList;
  Reg: TRegistry;
  FileName: string;
begin
  Dependencies := TStringList.Create;
  try
    FileName := ExtractFileName(AFilePath);
    
    Reg := TRegistry.Create(KEY_READ);
    try
      Reg.RootKey := HKEY_LOCAL_MACHINE;
      
      // 检查软件注册表项
      if Reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', False) then
      begin
        var SubKeys := TStringList.Create;
        try
          Reg.GetKeyNames(SubKeys);
          for var I := 0 to SubKeys.Count - 1 do
          begin
            if Reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\' + SubKeys[I], False) then
            begin
              if Reg.ValueExists('InstallLocation') then
              begin
                var InstallPath := Reg.ReadString('InstallLocation');
                if StartsText(InstallPath, AFilePath) then
                begin
                  if Reg.ValueExists('DisplayName') then
                    Dependencies.Add('程序: ' + Reg.ReadString('DisplayName'));
                end;
              end;
              Reg.CloseKey;
            end;
          end;
        finally
          SubKeys.Free;
        end;
        Reg.CloseKey;
      end;
      
    finally
      Reg.Free;
    end;
    
    Result := Dependencies.ToStringArray;
  finally
    Dependencies.Free;
  end;
end;

// 检查快捷方式依赖
function TFileAnalyzer.CheckShortcutDependencies(const AFilePath: string): TArray<string>;
var
  Dependencies: TStringList;
  SearchRec: TSearchRec;
  DesktopPath, StartMenuPath: string;
begin
  Dependencies := TStringList.Create;
  try
    // 获取桌面和开始菜单路径
    DesktopPath := GetEnvironmentVariable('USERPROFILE') + '\Desktop';
    StartMenuPath := GetEnvironmentVariable('APPDATA') + '\Microsoft\Windows\Start Menu';
    
    // 搜索桌面快捷方式
    if FindFirst(DesktopPath + '\*.lnk', faAnyFile and not faDirectory, SearchRec) = 0 then
    begin
      repeat
        // 这里简化处理，实际应该解析.lnk文件
        if ContainsText(SearchRec.Name, ChangeFileExt(ExtractFileName(AFilePath), '')) then
          Dependencies.Add('桌面快捷方式: ' + SearchRec.Name);
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
    
    Result := Dependencies.ToStringArray;
  finally
    Dependencies.Free;
  end;
end;

// 检查应用程序依赖
function TFileAnalyzer.CheckApplicationDependencies(const AFilePath: string): TArray<string>;
var
  Dependencies: TStringList;
begin
  Dependencies := TStringList.Create;
  try
    // 检查是否为DLL文件
    if SameText(ExtractFileExt(AFilePath), '.dll') then
    begin
      Dependencies.Add('可能被其他程序调用的动态链接库');
    end;
    
    // 检查是否为驱动文件
    if SameText(ExtractFileExt(AFilePath), '.sys') then
    begin
      Dependencies.Add('系统驱动文件');
    end;
    
    // 检查是否为服务文件
    if IsExecutableFile(AFilePath) then
    begin
      // 简化检查，实际应该查询服务管理器
      if ContainsText(AFilePath, 'service') or ContainsText(AFilePath, 'svc') then
        Dependencies.Add('可能的系统服务');
    end;
    
    Result := Dependencies.ToStringArray;
  finally
    Dependencies.Free;
  end;
end;

// 检查是否需要系统重启
function TFileAnalyzer.RequiresSystemRestart(const AFilePath: string): Boolean;
begin
  Result := False;
  
  // 系统文件通常需要重启
  if IsSystemFile(AFilePath) then
  begin
    Result := True;
    Exit;
  end;
  
  // 正在使用的文件可能需要重启
  if CheckFileInUse(AFilePath) then
  begin
    Result := True;
    Exit;
  end;
  
  // 驱动文件需要重启
  if SameText(ExtractFileExt(AFilePath), '.sys') then
  begin
    Result := True;
    Exit;
  end;
end;

// 检查是否可以创建符号链接
function TFileAnalyzer.CanCreateSymbolicLink(const AFilePath: string): Boolean;
begin
  Result := True;
  
  // 系统关键文件不能创建符号链接
  if IsSystemFile(AFilePath) then
  begin
    Result := False;
    Exit;
  end;
  
  // 正在使用的文件不能立即创建符号链接
  if CheckFileInUse(AFilePath) then
  begin
    Result := False;
    Exit;
  end;
  
  // 简化检查：假设NTFS文件系统支持符号链接
  var DriveLetter := UpperCase(ExtractFileDrive(AFilePath));
  if DriveLetter = 'A:' then // 软盘不支持
    Result := False;
end;

// 获取安全性原因说明
function TFileAnalyzer.GetFeasibilityReason(const AFilePath: string; AFeasibility: TSymlinkFeasibility): string;
begin
  case AFeasibility of
    sfCanLink:
      Result := '移动并创建符号链接不会影响程序运行';
    sfRisky:
      begin
        if IsExecutableFile(AFilePath) then
          Result := '移动可能影响程序运行，但符号链接通常可以解决依赖问题'
        else if CheckFileInUse(AFilePath) then
          Result := '文件正在使用中，移动后符号链接可能需要重启程序生效'
        else
          Result := '移动可能影响程序运行，建议测试后确认';
      end;
    sfCannotMove:
      begin
        if IsSystemFile(AFilePath) then
          Result := '移动会导致系统或程序无法正常运行'
        else
          Result := '移动会严重影响程序运行，禁止移动';
      end;
  else
    Result := '无法评估对程序运行的影响';
  end;
end;

// 分析单个文件
function TFileAnalyzer.AnalyzeFile(const AFilePath: string): TFileAnalysisResult;
begin
  Result.FilePath := AFilePath;
  
  if not FileExists(AFilePath) then
  begin
    Result.SymlinkFeasibility := sfCannotMove;
    Result.Reason := '文件不存在';
    Exit;
  end;
  
  // 评估符号链接可行性
  Result.SymlinkFeasibility := AnalyzeFileType(AFilePath);
  
  // 检查依赖关系
  Result.Dependencies := CheckDependencies(AFilePath);
  
  // 获取文件大小
  try
    Result.Size := TFile.GetSize(AFilePath);
  except
    Result.Size := 0;
  end;
  
  // 其他属性
  Result.IsSystemFile := IsSystemFile(AFilePath);
  Result.RequiresRestart := RequiresSystemRestart(AFilePath);
  Result.CanCreateSymlink := CanCreateSymbolicLink(AFilePath);
  Result.Reason := GetFeasibilityReason(AFilePath, Result.SymlinkFeasibility);
end;

// 分析目录
function TFileAnalyzer.AnalyzeDirectory(const ADirPath: string): TArray<TFileAnalysisResult>;
var
  Results: TList<TFileAnalysisResult>;
  SearchRec: TSearchRec;
  FilePath: string;
begin
  Results := TList<TFileAnalysisResult>.Create;
  try
    if FindFirst(ADirPath + '\*', faAnyFile and not faVolumeID, SearchRec) = 0 then
    begin
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          FilePath := TPath.Combine(ADirPath, SearchRec.Name);
          
          if (SearchRec.Attr and faDirectory) = faDirectory then
          begin
            // 递归分析子目录
            var SubResults := AnalyzeDirectory(FilePath);
            for var SubResult in SubResults do
              Results.Add(SubResult);
          end
          else
          begin
            // 分析文件
            Results.Add(AnalyzeFile(FilePath));
          end;
        end;
      until FindNext(SearchRec) <> 0;
      FindClose(SearchRec);
    end;
    
    Result := Results.ToArray;
  finally
    Results.Free;
  end;
end;

// 检查依赖关系
function TFileAnalyzer.CheckDependencies(const AFilePath: string): TArray<string>;
var
  AllDependencies: TStringList;
  RegDeps, ShortcutDeps, AppDeps: TArray<string>;
begin
  AllDependencies := TStringList.Create;
  try
    // 检查注册表依赖
    RegDeps := CheckRegistryDependencies(AFilePath);
    for var Dep in RegDeps do
      AllDependencies.Add(Dep);
    
    // 检查快捷方式依赖
    ShortcutDeps := CheckShortcutDependencies(AFilePath);
    for var Dep in ShortcutDeps do
      AllDependencies.Add(Dep);
    
    // 检查应用程序依赖
    AppDeps := CheckApplicationDependencies(AFilePath);
    for var Dep in AppDeps do
      AllDependencies.Add(Dep);
    
    Result := AllDependencies.ToStringArray;
  finally
    AllDependencies.Free;
  end;
end;

// 评估符号链接可行性
function TFileAnalyzer.EvaluateSymlinkFeasibility(const AFilePath: string): TSymlinkFeasibility;
begin
  Result := AnalyzeFileType(AFilePath);
end;

end.

unit uRegistryScanner;

{
  注册表垃圾扫描器 - Registry Garbage Scanner
  
  功能：
  - 扫描无效软件路径引用
  - 扫描无效COM/ActiveX组件
  - 扫描无效文件类型关联
  - 扫描无效卸载程序条目
  - 仅报告，不自动删除（安全策略）
  
  作者: MoveC Team
  版本: 1.0
  日期: 2025-12-02
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  System.Generics.Collections, Winapi.Windows, System.Win.Registry;

type
  // 注册表问题类型
  TRegistryIssueType = (
    ritInvalidPath,        // 无效路径引用
    ritInvalidCOM,         // 无效COM组件
    ritInvalidFileType,    // 无效文件类型关联
    ritInvalidUninstall,   // 无效卸载条目
    ritOrphanedKey,        // 孤立注册表键
    ritEmptyKey            // 空键
  );
  
  // 风险等级
  TRiskLevel = (
    rlLow,       // 低风险 - 可以安全删除
    rlMedium,    // 中风险 - 建议手动确认
    rlHigh       // 高风险 - 不建议删除
  );
  
  // 注册表问题记录
  TRegistryIssue = record
    IssueType: TRegistryIssueType;
    RiskLevel: TRiskLevel;
    KeyPath: string;
    ValueName: string;
    ValueData: string;
    Description: string;
    ReferencedPath: string;   // 被引用的无效路径
    ScanTime: TDateTime;
  end;
  
  // 扫描进度事件
  TRegistryScanProgress = procedure(const Message: string; 
    Progress: Integer; IssueCount: Integer) of object;

  TRegistryScanner = class
  private
    FIssues: TList<TRegistryIssue>;
    FOnProgress: TRegistryScanProgress;
    FCancelled: Boolean;
    FScannedKeys: Integer;
    FScanDepth: Integer;
    
    procedure ReportProgress(const AMessage: string; AProgress: Integer);
    procedure AddIssue(AType: TRegistryIssueType; ARisk: TRiskLevel;
      const AKeyPath, AValueName, AValueData, ADescription: string;
      const AReferencedPath: string = '');
    
    // 扫描方法
    procedure ScanUninstallEntries;
    procedure ScanCOMComponents;
    procedure ScanFileAssociations;
    procedure ScanSharedDLLs;
    procedure ScanMRULists;
    procedure ScanStartupEntries;
    
    // 辅助方法
    function IsValidPath(const APath: string): Boolean;
    function ExtractPathFromValue(const AValue: string): string;
    function IssueTypeToString(AType: TRegistryIssueType): string;
    function RiskLevelToString(ARisk: TRiskLevel): string;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 扫描操作
    procedure StartScan;
    procedure CancelScan;
    procedure ClearResults;
    
    // 获取结果
    function GetAllIssues: TArray<TRegistryIssue>;
    function GetIssuesByType(AType: TRegistryIssueType): TArray<TRegistryIssue>;
    function GetIssuesByRisk(ARisk: TRiskLevel): TArray<TRegistryIssue>;
    function GetIssueCount: Integer;
    
    // 导出报告
    procedure ExportReport(const AFileName: string);
    procedure ExportReportHTML(const AFileName: string);
    
    // 属性
    property OnProgress: TRegistryScanProgress read FOnProgress write FOnProgress;
    property Cancelled: Boolean read FCancelled;
    property ScannedKeys: Integer read FScannedKeys;
  end;

implementation

uses
  uLogManager;

{ TRegistryScanner }

constructor TRegistryScanner.Create;
begin
  inherited Create;
  FIssues := TList<TRegistryIssue>.Create;
  FCancelled := False;
  FScannedKeys := 0;
  FScanDepth := 0;
end;

destructor TRegistryScanner.Destroy;
begin
  FIssues.Free;
  inherited;
end;

procedure TRegistryScanner.ReportProgress(const AMessage: string; AProgress: Integer);
begin
  if Assigned(FOnProgress) then
    FOnProgress(AMessage, AProgress, FIssues.Count);
end;

procedure TRegistryScanner.AddIssue(AType: TRegistryIssueType; ARisk: TRiskLevel;
  const AKeyPath, AValueName, AValueData, ADescription: string;
  const AReferencedPath: string);
var
  Issue: TRegistryIssue;
begin
  Issue.IssueType := AType;
  Issue.RiskLevel := ARisk;
  Issue.KeyPath := AKeyPath;
  Issue.ValueName := AValueName;
  Issue.ValueData := AValueData;
  Issue.Description := ADescription;
  Issue.ReferencedPath := AReferencedPath;
  Issue.ScanTime := Now;
  FIssues.Add(Issue);
end;

function TRegistryScanner.IsValidPath(const APath: string): Boolean;
var
  CleanPath: string;
begin
  Result := False;
  if APath = '' then Exit;
  
  CleanPath := Trim(APath);
  
  // 移除引号
  if (Length(CleanPath) > 1) and (CleanPath[1] = '"') then
  begin
    Delete(CleanPath, 1, 1);
    var QuotePos := Pos('"', CleanPath);
    if QuotePos > 0 then
      CleanPath := Copy(CleanPath, 1, QuotePos - 1);
  end;
  
  // 检查环境变量
  if Pos('%', CleanPath) > 0 then
    CleanPath := ExpandEnvironmentStrings(CleanPath);
  
  // 检查是否是有效路径
  if CleanPath = '' then Exit;
  
  // 检查文件或目录是否存在
  Result := TFile.Exists(CleanPath) or TDirectory.Exists(CleanPath);
end;

function ExpandEnvironmentStrings(const APath: string): string;
var
  Buffer: array[0..MAX_PATH] of Char;
begin
  if Winapi.Windows.ExpandEnvironmentStrings(PChar(APath), Buffer, MAX_PATH) > 0 then
    Result := Buffer
  else
    Result := APath;
end;

function TRegistryScanner.ExtractPathFromValue(const AValue: string): string;
var
  S: string;
  SpacePos: Integer;
begin
  Result := '';
  S := Trim(AValue);
  if S = '' then Exit;
  
  // 处理引号路径
  if S[1] = '"' then
  begin
    Delete(S, 1, 1);
    var QuotePos := Pos('"', S);
    if QuotePos > 0 then
      Result := Copy(S, 1, QuotePos - 1)
    else
      Result := S;
  end
  else
  begin
    // 查找第一个空格（参数分隔）
    SpacePos := Pos(' ', S);
    if SpacePos > 0 then
      Result := Copy(S, 1, SpacePos - 1)
    else
      Result := S;
  end;
  
  // 展开环境变量
  if Pos('%', Result) > 0 then
    Result := ExpandEnvironmentStrings(Result);
end;

function TRegistryScanner.IssueTypeToString(AType: TRegistryIssueType): string;
begin
  case AType of
    ritInvalidPath: Result := '无效路径引用';
    ritInvalidCOM: Result := '无效COM组件';
    ritInvalidFileType: Result := '无效文件类型关联';
    ritInvalidUninstall: Result := '无效卸载条目';
    ritOrphanedKey: Result := '孤立注册表键';
    ritEmptyKey: Result := '空键';
  else
    Result := '未知';
  end;
end;

function TRegistryScanner.RiskLevelToString(ARisk: TRiskLevel): string;
begin
  case ARisk of
    rlLow: Result := '低';
    rlMedium: Result := '中';
    rlHigh: Result := '高';
  else
    Result := '未知';
  end;
end;

procedure TRegistryScanner.StartScan;
begin
  FCancelled := False;
  FScannedKeys := 0;
  FIssues.Clear;
  
  LogInfo('RegistryScanner', '开始注册表扫描...');
  
  ReportProgress('正在扫描卸载程序条目...', 0);
  if not FCancelled then ScanUninstallEntries;
  
  ReportProgress('正在扫描COM组件...', 20);
  if not FCancelled then ScanCOMComponents;
  
  ReportProgress('正在扫描文件关联...', 40);
  if not FCancelled then ScanFileAssociations;
  
  ReportProgress('正在扫描共享DLL...', 60);
  if not FCancelled then ScanSharedDLLs;
  
  ReportProgress('正在扫描最近使用列表...', 80);
  if not FCancelled then ScanMRULists;
  
  ReportProgress('正在扫描启动项...', 90);
  if not FCancelled then ScanStartupEntries;
  
  ReportProgress('扫描完成', 100);
  LogInfo('RegistryScanner', Format('扫描完成，发现 %d 个问题', [FIssues.Count]));
end;

procedure TRegistryScanner.CancelScan;
begin
  FCancelled := True;
end;

procedure TRegistryScanner.ClearResults;
begin
  FIssues.Clear;
  FScannedKeys := 0;
end;

procedure TRegistryScanner.ScanUninstallEntries;
const
  UninstallKeys: array[0..1] of string = (
    'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
  );
var
  Reg: TRegistry;
  KeyPath: string;
  SubKeys: TStringList;
  I, J: Integer;
  UninstallString, DisplayIcon, InstallLocation: string;
  Path: string;
begin
  Reg := TRegistry.Create(KEY_READ);
  SubKeys := TStringList.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    
    for I := 0 to High(UninstallKeys) do
    begin
      if FCancelled then Exit;
      
      if Reg.OpenKeyReadOnly(UninstallKeys[I]) then
      begin
        Reg.GetKeyNames(SubKeys);
        Reg.CloseKey;
        
        for J := 0 to SubKeys.Count - 1 do
        begin
          if FCancelled then Exit;
          Inc(FScannedKeys);
          
          KeyPath := UninstallKeys[I] + '\' + SubKeys[J];
          if Reg.OpenKeyReadOnly(KeyPath) then
          begin
            // 检查卸载命令
            UninstallString := Reg.ReadString('UninstallString');
            if UninstallString <> '' then
            begin
              Path := ExtractPathFromValue(UninstallString);
              if (Path <> '') and not IsValidPath(Path) then
              begin
                AddIssue(ritInvalidUninstall, rlLow,
                  'HKLM\' + KeyPath, 'UninstallString', UninstallString,
                  '卸载程序路径不存在', Path);
              end;
            end;
            
            // 检查显示图标
            DisplayIcon := Reg.ReadString('DisplayIcon');
            if DisplayIcon <> '' then
            begin
              Path := ExtractPathFromValue(DisplayIcon);
              if (Path <> '') and not IsValidPath(Path) then
              begin
                AddIssue(ritInvalidUninstall, rlLow,
                  'HKLM\' + KeyPath, 'DisplayIcon', DisplayIcon,
                  '显示图标路径不存在', Path);
              end;
            end;
            
            // 检查安装位置
            InstallLocation := Reg.ReadString('InstallLocation');
            if (InstallLocation <> '') and not TDirectory.Exists(InstallLocation) then
            begin
              AddIssue(ritInvalidUninstall, rlLow,
                'HKLM\' + KeyPath, 'InstallLocation', InstallLocation,
                '安装位置不存在', InstallLocation);
            end;
            
            Reg.CloseKey;
          end;
        end;
      end;
    end;
  finally
    SubKeys.Free;
    Reg.Free;
  end;
end;

procedure TRegistryScanner.ScanCOMComponents;
var
  Reg: TRegistry;
  SubKeys: TStringList;
  I: Integer;
  KeyPath, InprocServer, LocalServer: string;
  Path: string;
begin
  Reg := TRegistry.Create(KEY_READ);
  SubKeys := TStringList.Create;
  try
    Reg.RootKey := HKEY_CLASSES_ROOT;
    
    if Reg.OpenKeyReadOnly('CLSID') then
    begin
      Reg.GetKeyNames(SubKeys);
      Reg.CloseKey;
      
      // 限制扫描数量以提高性能
      for I := 0 to Min(SubKeys.Count - 1, 5000) do
      begin
        if FCancelled then Exit;
        if (I mod 100 = 0) then
          ReportProgress(Format('扫描COM组件 (%d/%d)...', [I, SubKeys.Count]), 
            20 + (I * 20 div SubKeys.Count));
        
        Inc(FScannedKeys);
        KeyPath := 'CLSID\' + SubKeys[I];
        
        // 检查 InprocServer32
        if Reg.OpenKeyReadOnly(KeyPath + '\InprocServer32') then
        begin
          InprocServer := Reg.ReadString('');
          if InprocServer <> '' then
          begin
            Path := ExtractPathFromValue(InprocServer);
            if (Path <> '') and (Pos('.dll', LowerCase(Path)) > 0) and 
               not IsValidPath(Path) then
            begin
              AddIssue(ritInvalidCOM, rlMedium,
                'HKCR\' + KeyPath + '\InprocServer32', '(默认)', InprocServer,
                'COM DLL不存在', Path);
            end;
          end;
          Reg.CloseKey;
        end;
        
        // 检查 LocalServer32
        if Reg.OpenKeyReadOnly(KeyPath + '\LocalServer32') then
        begin
          LocalServer := Reg.ReadString('');
          if LocalServer <> '' then
          begin
            Path := ExtractPathFromValue(LocalServer);
            if (Path <> '') and not IsValidPath(Path) then
            begin
              AddIssue(ritInvalidCOM, rlMedium,
                'HKCR\' + KeyPath + '\LocalServer32', '(默认)', LocalServer,
                'COM服务器不存在', Path);
            end;
          end;
          Reg.CloseKey;
        end;
      end;
    end;
  finally
    SubKeys.Free;
    Reg.Free;
  end;
end;

procedure TRegistryScanner.ScanFileAssociations;
var
  Reg: TRegistry;
  SubKeys: TStringList;
  I: Integer;
  KeyPath, Command, DefaultValue: string;
  Path: string;
begin
  Reg := TRegistry.Create(KEY_READ);
  SubKeys := TStringList.Create;
  try
    Reg.RootKey := HKEY_CLASSES_ROOT;
    
    if Reg.OpenKeyReadOnly('') then
    begin
      Reg.GetKeyNames(SubKeys);
      Reg.CloseKey;
      
      for I := 0 to SubKeys.Count - 1 do
      begin
        if FCancelled then Exit;
        if not SubKeys[I].StartsWith('.') then Continue;  // 只处理扩展名
        
        Inc(FScannedKeys);
        
        // 获取关联的程序类型
        if Reg.OpenKeyReadOnly(SubKeys[I]) then
        begin
          DefaultValue := Reg.ReadString('');
          Reg.CloseKey;
          
          if DefaultValue <> '' then
          begin
            // 检查 shell\open\command
            KeyPath := DefaultValue + '\shell\open\command';
            if Reg.OpenKeyReadOnly(KeyPath) then
            begin
              Command := Reg.ReadString('');
              if Command <> '' then
              begin
                Path := ExtractPathFromValue(Command);
                if (Path <> '') and not IsValidPath(Path) then
                begin
                  AddIssue(ritInvalidFileType, rlLow,
                    'HKCR\' + KeyPath, '(默认)', Command,
                    Format('文件类型 %s 关联的程序不存在', [SubKeys[I]]), Path);
                end;
              end;
              Reg.CloseKey;
            end;
          end;
        end;
      end;
    end;
  finally
    SubKeys.Free;
    Reg.Free;
  end;
end;

procedure TRegistryScanner.ScanSharedDLLs;
var
  Reg: TRegistry;
  ValueNames: TStringList;
  I: Integer;
begin
  Reg := TRegistry.Create(KEY_READ);
  ValueNames := TStringList.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    
    if Reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows\CurrentVersion\SharedDLLs') then
    begin
      Reg.GetValueNames(ValueNames);
      
      for I := 0 to ValueNames.Count - 1 do
      begin
        if FCancelled then Exit;
        Inc(FScannedKeys);
        
        if not TFile.Exists(ValueNames[I]) then
        begin
          AddIssue(ritInvalidPath, rlLow,
            'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\SharedDLLs',
            ValueNames[I], IntToStr(Reg.ReadInteger(ValueNames[I])),
            '共享DLL不存在', ValueNames[I]);
        end;
      end;
      
      Reg.CloseKey;
    end;
  finally
    ValueNames.Free;
    Reg.Free;
  end;
end;

procedure TRegistryScanner.ScanMRULists;
var
  Reg: TRegistry;
  SubKeys, ValueNames: TStringList;
  I, J: Integer;
  KeyPath, Value, Path: string;
begin
  Reg := TRegistry.Create(KEY_READ);
  SubKeys := TStringList.Create;
  ValueNames := TStringList.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    
    // 扫描最近文档
    if Reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs') then
    begin
      Reg.GetKeyNames(SubKeys);
      Reg.CloseKey;
      
      for I := 0 to SubKeys.Count - 1 do
      begin
        if FCancelled then Exit;
        Inc(FScannedKeys);
        
        KeyPath := 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs\' + SubKeys[I];
        if Reg.OpenKeyReadOnly(KeyPath) then
        begin
          Reg.GetValueNames(ValueNames);
          // 只报告大量无效条目
          Reg.CloseKey;
        end;
      end;
    end;
    
    // 扫描运行历史
    if Reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU') then
    begin
      Reg.GetValueNames(ValueNames);
      
      for I := 0 to ValueNames.Count - 1 do
      begin
        if FCancelled then Exit;
        if ValueNames[I] = 'MRUList' then Continue;
        
        Value := Reg.ReadString(ValueNames[I]);
        if Value <> '' then
        begin
          // 移除末尾的 \1
          if Value.EndsWith('\1') then
            Value := Copy(Value, 1, Length(Value) - 2);
          
          Path := ExtractPathFromValue(Value);
          // 只报告明显的文件路径
          if (Path <> '') and (Pos(':\', Path) > 0) and 
             (Pos('.', Path) > 0) and not IsValidPath(Path) then
          begin
            AddIssue(ritInvalidPath, rlLow,
              'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU',
              ValueNames[I], Value,
              '运行历史中的路径不存在', Path);
          end;
        end;
      end;
      
      Reg.CloseKey;
    end;
  finally
    ValueNames.Free;
    SubKeys.Free;
    Reg.Free;
  end;
end;

procedure TRegistryScanner.ScanStartupEntries;
const
  StartupKeys: array[0..3] of string = (
    'SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
    'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
    'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run',
    'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce'
  );
var
  Reg: TRegistry;
  ValueNames: TStringList;
  I, J: Integer;
  Value, Path: string;
  RootKey: HKEY;
  RootName: string;
begin
  Reg := TRegistry.Create(KEY_READ);
  ValueNames := TStringList.Create;
  try
    for J := 0 to 1 do  // 0=HKLM, 1=HKCU
    begin
      if J = 0 then
      begin
        Reg.RootKey := HKEY_LOCAL_MACHINE;
        RootName := 'HKLM';
      end
      else
      begin
        Reg.RootKey := HKEY_CURRENT_USER;
        RootName := 'HKCU';
      end;
      
      for I := 0 to High(StartupKeys) do
      begin
        if FCancelled then Exit;
        
        if Reg.OpenKeyReadOnly(StartupKeys[I]) then
        begin
          Reg.GetValueNames(ValueNames);
          
          for var K := 0 to ValueNames.Count - 1 do
          begin
            Inc(FScannedKeys);
            Value := Reg.ReadString(ValueNames[K]);
            if Value <> '' then
            begin
              Path := ExtractPathFromValue(Value);
              if (Path <> '') and not IsValidPath(Path) then
              begin
                AddIssue(ritInvalidPath, rlMedium,
                  RootName + '\' + StartupKeys[I],
                  ValueNames[K], Value,
                  '启动项程序不存在', Path);
              end;
            end;
          end;
          
          Reg.CloseKey;
        end;
      end;
    end;
  finally
    ValueNames.Free;
    Reg.Free;
  end;
end;

function TRegistryScanner.GetAllIssues: TArray<TRegistryIssue>;
begin
  Result := FIssues.ToArray;
end;

function TRegistryScanner.GetIssuesByType(AType: TRegistryIssueType): TArray<TRegistryIssue>;
var
  Filtered: TList<TRegistryIssue>;
  Issue: TRegistryIssue;
begin
  Filtered := TList<TRegistryIssue>.Create;
  try
    for Issue in FIssues do
      if Issue.IssueType = AType then
        Filtered.Add(Issue);
    Result := Filtered.ToArray;
  finally
    Filtered.Free;
  end;
end;

function TRegistryScanner.GetIssuesByRisk(ARisk: TRiskLevel): TArray<TRegistryIssue>;
var
  Filtered: TList<TRegistryIssue>;
  Issue: TRegistryIssue;
begin
  Filtered := TList<TRegistryIssue>.Create;
  try
    for Issue in FIssues do
      if Issue.RiskLevel = ARisk then
        Filtered.Add(Issue);
    Result := Filtered.ToArray;
  finally
    Filtered.Free;
  end;
end;

function TRegistryScanner.GetIssueCount: Integer;
begin
  Result := FIssues.Count;
end;

procedure TRegistryScanner.ExportReport(const AFileName: string);
var
  Report: TStringList;
  Issue: TRegistryIssue;
begin
  Report := TStringList.Create;
  try
    Report.Add('========================================');
    Report.Add('MoveC 注册表扫描报告');
    Report.Add('========================================');
    Report.Add('扫描时间: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    Report.Add('发现问题: ' + IntToStr(FIssues.Count) + ' 个');
    Report.Add('扫描键数: ' + IntToStr(FScannedKeys));
    Report.Add('');
    Report.Add('========================================');
    Report.Add('问题详情');
    Report.Add('========================================');
    Report.Add('');
    
    for Issue in FIssues do
    begin
      Report.Add('----------------------------------------');
      Report.Add('类型: ' + IssueTypeToString(Issue.IssueType));
      Report.Add('风险: ' + RiskLevelToString(Issue.RiskLevel));
      Report.Add('位置: ' + Issue.KeyPath);
      Report.Add('值名: ' + Issue.ValueName);
      Report.Add('数据: ' + Issue.ValueData);
      Report.Add('描述: ' + Issue.Description);
      if Issue.ReferencedPath <> '' then
        Report.Add('引用: ' + Issue.ReferencedPath);
      Report.Add('');
    end;
    
    Report.Add('========================================');
    Report.Add('注意事项');
    Report.Add('========================================');
    Report.Add('1. 本报告仅供参考，不建议直接删除注册表条目');
    Report.Add('2. 删除注册表条目可能导致系统或软件异常');
    Report.Add('3. 建议在修改前备份注册表');
    Report.Add('4. 高风险条目请勿删除');
    
    Report.SaveToFile(AFileName, TEncoding.UTF8);
  finally
    Report.Free;
  end;
end;

procedure TRegistryScanner.ExportReportHTML(const AFileName: string);
var
  HTML: TStringList;
  Issue: TRegistryIssue;
  RiskColor: string;
begin
  HTML := TStringList.Create;
  try
    HTML.Add('<!DOCTYPE html>');
    HTML.Add('<html><head>');
    HTML.Add('<meta charset="utf-8">');
    HTML.Add('<title>MoveC 注册表扫描报告</title>');
    HTML.Add('<style>');
    HTML.Add('body { font-family: "Microsoft YaHei", sans-serif; margin: 20px; }');
    HTML.Add('h1 { color: #333; }');
    HTML.Add('.summary { background: #f5f5f5; padding: 15px; border-radius: 5px; }');
    HTML.Add('.issue { border: 1px solid #ddd; margin: 10px 0; padding: 10px; border-radius: 5px; }');
    HTML.Add('.low { border-left: 4px solid #4CAF50; }');
    HTML.Add('.medium { border-left: 4px solid #FF9800; }');
    HTML.Add('.high { border-left: 4px solid #f44336; }');
    HTML.Add('.label { font-weight: bold; color: #666; }');
    HTML.Add('.path { font-family: monospace; background: #f0f0f0; padding: 2px 5px; }');
    HTML.Add('</style></head><body>');
    
    HTML.Add('<h1>MoveC 注册表扫描报告</h1>');
    HTML.Add('<div class="summary">');
    HTML.Add('<p><b>扫描时间:</b> ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + '</p>');
    HTML.Add('<p><b>发现问题:</b> ' + IntToStr(FIssues.Count) + ' 个</p>');
    HTML.Add('<p><b>扫描键数:</b> ' + IntToStr(FScannedKeys) + '</p>');
    HTML.Add('</div>');
    
    HTML.Add('<h2>问题详情</h2>');
    
    for Issue in FIssues do
    begin
      case Issue.RiskLevel of
        rlLow: RiskColor := 'low';
        rlMedium: RiskColor := 'medium';
        rlHigh: RiskColor := 'high';
      else
        RiskColor := 'low';
      end;
      
      HTML.Add('<div class="issue ' + RiskColor + '">');
      HTML.Add('<p><span class="label">类型:</span> ' + IssueTypeToString(Issue.IssueType) + '</p>');
      HTML.Add('<p><span class="label">风险:</span> ' + RiskLevelToString(Issue.RiskLevel) + '</p>');
      HTML.Add('<p><span class="label">位置:</span> <span class="path">' + Issue.KeyPath + '</span></p>');
      HTML.Add('<p><span class="label">描述:</span> ' + Issue.Description + '</p>');
      if Issue.ReferencedPath <> '' then
        HTML.Add('<p><span class="label">无效路径:</span> <span class="path">' + Issue.ReferencedPath + '</span></p>');
      HTML.Add('</div>');
    end;
    
    HTML.Add('<h2>注意事项</h2>');
    HTML.Add('<ul>');
    HTML.Add('<li>本报告仅供参考，不建议直接删除注册表条目</li>');
    HTML.Add('<li>删除注册表条目可能导致系统或软件异常</li>');
    HTML.Add('<li>建议在修改前备份注册表</li>');
    HTML.Add('<li>高风险条目请勿删除</li>');
    HTML.Add('</ul>');
    
    HTML.Add('</body></html>');
    
    HTML.SaveToFile(AFileName, TEncoding.UTF8);
  finally
    HTML.Free;
  end;
end;

end.

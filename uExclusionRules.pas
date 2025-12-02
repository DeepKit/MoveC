unit uExclusionRules;

{
  自定义排除规则 - Exclusion Rules Manager
  
  功能：
  - 用户自定义扫描/清理排除规则
  - 支持路径匹配、通配符、正则表达式
  - 内置系统关键目录保护
  - 规则导入导出
  - 规则优先级管理
  
  作者: MoveC Team
  版本: 1.0
  日期: 2025-12-02
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.IniFiles,
  System.Generics.Collections, System.RegularExpressions,
  Winapi.Windows;

type
  // 规则类型
  TExclusionRuleType = (
    ertExactPath,      // 精确路径匹配
    ertWildcard,       // 通配符匹配 (*, ?)
    ertRegex,          // 正则表达式
    ertExtension,      // 文件扩展名
    ertSizeGreater,    // 大于指定大小
    ertSizeLess,       // 小于指定大小
    ertAgeOlderDays,   // 超过N天
    ertAgeNewerDays    // 少于N天
  );
  
  // 规则适用范围
  TExclusionScope = (
    esAll,             // 所有操作
    esScan,            // 仅扫描
    esCleanup,         // 仅清理
    esMigration        // 仅迁移
  );
  
  // 排除规则记录
  TExclusionRule = record
    ID: Integer;
    Name: string;
    Pattern: string;           // 匹配模式
    RuleType: TExclusionRuleType;
    Scope: TExclusionScope;
    Enabled: Boolean;
    IsSystem: Boolean;         // 系统内置规则（不可删除）
    Priority: Integer;         // 优先级（数字越小越优先）
    Description: string;
    NumericValue: Int64;       // 用于大小/天数规则
  end;

  TExclusionRulesManager = class
  private
    FRules: TList<TExclusionRule>;
    FConfigFile: string;
    FNextID: Integer;
    FSystemRulesLoaded: Boolean;
    
    function GetConfigFile: string;
    procedure LoadSystemRules;
    procedure LoadUserRules;
    procedure SaveUserRules;
    function MatchWildcard(const APath, APattern: string): Boolean;
    function RuleTypeToString(AType: TExclusionRuleType): string;
    function StringToRuleType(const S: string): TExclusionRuleType;
    function ScopeToString(AScope: TExclusionScope): string;
    function StringToScope(const S: string): TExclusionScope;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 规则管理
    function AddRule(const AName, APattern: string; AType: TExclusionRuleType;
      AScope: TExclusionScope = esAll; APriority: Integer = 100): Integer;
    procedure UpdateRule(const Rule: TExclusionRule);
    procedure DeleteRule(RuleID: Integer);
    function GetRule(RuleID: Integer): TExclusionRule;
    function GetAllRules: TArray<TExclusionRule>;
    function GetActiveRules(AScope: TExclusionScope): TArray<TExclusionRule>;
    
    // 匹配检查
    function ShouldExclude(const APath: string; AScope: TExclusionScope): Boolean;
    function ShouldExcludeFile(const APath: string; AFileSize: Int64;
      AFileDate: TDateTime; AScope: TExclusionScope): Boolean;
    function GetMatchingRule(const APath: string; AScope: TExclusionScope): TExclusionRule;
    
    // 导入导出
    procedure ExportRules(const AFileName: string);
    procedure ImportRules(const AFileName: string);
    
    // 实用方法
    procedure EnableRule(RuleID: Integer; AEnabled: Boolean);
    procedure SetRulePriority(RuleID: Integer; APriority: Integer);
    procedure ResetToDefaults;
  end;
  
  // 全局单例
  function ExclusionRules: TExclusionRulesManager;

implementation

uses
  uLogManager;

var
  _ExclusionRules: TExclusionRulesManager = nil;

function ExclusionRules: TExclusionRulesManager;
begin
  if _ExclusionRules = nil then
    _ExclusionRules := TExclusionRulesManager.Create;
  Result := _ExclusionRules;
end;

{ TExclusionRulesManager }

constructor TExclusionRulesManager.Create;
begin
  inherited Create;
  FRules := TList<TExclusionRule>.Create;
  FConfigFile := GetConfigFile;
  FNextID := 1;
  FSystemRulesLoaded := False;
  
  LoadSystemRules;
  LoadUserRules;
end;

destructor TExclusionRulesManager.Destroy;
begin
  SaveUserRules;
  FRules.Free;
  inherited;
end;

function TExclusionRulesManager.GetConfigFile: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'ExclusionRules.ini');
end;

procedure TExclusionRulesManager.LoadSystemRules;

  procedure AddSystemRule(const AName, APattern, ADesc: string;
    AType: TExclusionRuleType; APriority: Integer = 10);
  var
    Rule: TExclusionRule;
  begin
    Rule.ID := FNextID;
    Inc(FNextID);
    Rule.Name := AName;
    Rule.Pattern := APattern;
    Rule.RuleType := AType;
    Rule.Scope := esAll;
    Rule.Enabled := True;
    Rule.IsSystem := True;
    Rule.Priority := APriority;
    Rule.Description := ADesc;
    Rule.NumericValue := 0;
    FRules.Add(Rule);
  end;

begin
  if FSystemRulesLoaded then Exit;
  
  // Windows 系统关键目录
  AddSystemRule('Windows目录', 'C:\Windows', '系统核心目录，禁止操作', ertExactPath, 1);
  AddSystemRule('Windows子目录', 'C:\Windows\*', '系统核心目录', ertWildcard, 1);
  AddSystemRule('Program Files', 'C:\Program Files', '程序安装目录', ertExactPath, 2);
  AddSystemRule('Program Files (x86)', 'C:\Program Files (x86)', '32位程序目录', ertExactPath, 2);
  AddSystemRule('ProgramData', 'C:\ProgramData', '程序数据目录', ertExactPath, 3);
  
  // 用户关键目录
  AddSystemRule('用户配置', '*\AppData\Local\Microsoft', '系统配置目录', ertWildcard, 5);
  AddSystemRule('桌面配置', '*\Desktop.ini', '桌面配置文件', ertWildcard, 10);
  
  // 系统文件
  AddSystemRule('系统DLL', '*.dll', '动态链接库', ertExtension, 5);
  AddSystemRule('系统EXE', '*.exe', '可执行文件（扫描时跳过）', ertExtension, 20);
  AddSystemRule('系统SYS', '*.sys', '系统驱动', ertExtension, 5);
  
  // 隐藏系统文件
  AddSystemRule('系统卷信息', '*\System Volume Information', '系统还原点', ertWildcard, 1);
  AddSystemRule('回收站', '*\$Recycle.Bin', '回收站目录', ertWildcard, 1);
  AddSystemRule('NTFS元数据', '*\$*', 'NTFS元数据文件', ertWildcard, 1);
  
  // MoveC 自身保护
  AddSystemRule('MoveC程序', '*\MoveC\*', 'MoveC程序目录', ertWildcard, 1);
  AddSystemRule('MoveC数据库', '*.db', 'MoveC数据库文件', ertExtension, 5);
  
  FSystemRulesLoaded := True;
end;

procedure TExclusionRulesManager.LoadUserRules;
var
  IniFile: TIniFile;
  RuleCount, I: Integer;
  Rule: TExclusionRule;
  Section: string;
begin
  if not TFile.Exists(FConfigFile) then Exit;
  
  IniFile := TIniFile.Create(FConfigFile);
  try
    FNextID := IniFile.ReadInteger('General', 'NextID', FNextID);
    RuleCount := IniFile.ReadInteger('General', 'RuleCount', 0);
    
    for I := 0 to RuleCount - 1 do
    begin
      Section := Format('Rule_%d', [I]);
      
      Rule.ID := IniFile.ReadInteger(Section, 'ID', 0);
      Rule.Name := IniFile.ReadString(Section, 'Name', '');
      Rule.Pattern := IniFile.ReadString(Section, 'Pattern', '');
      Rule.RuleType := StringToRuleType(IniFile.ReadString(Section, 'RuleType', 'ExactPath'));
      Rule.Scope := StringToScope(IniFile.ReadString(Section, 'Scope', 'All'));
      Rule.Enabled := IniFile.ReadBool(Section, 'Enabled', True);
      Rule.IsSystem := False;  // 用户规则
      Rule.Priority := IniFile.ReadInteger(Section, 'Priority', 100);
      Rule.Description := IniFile.ReadString(Section, 'Description', '');
      Rule.NumericValue := IniFile.ReadInt64(Section, 'NumericValue', 0);
      
      if (Rule.Name <> '') and (Rule.Pattern <> '') then
      begin
        if Rule.ID >= FNextID then
          FNextID := Rule.ID + 1;
        FRules.Add(Rule);
      end;
    end;
  finally
    IniFile.Free;
  end;
end;

procedure TExclusionRulesManager.SaveUserRules;
var
  IniFile: TIniFile;
  I, UserRuleIdx: Integer;
  Rule: TExclusionRule;
  Section: string;
begin
  IniFile := TIniFile.Create(FConfigFile);
  try
    IniFile.WriteInteger('General', 'NextID', FNextID);
    
    // 只保存用户规则
    UserRuleIdx := 0;
    for I := 0 to FRules.Count - 1 do
    begin
      Rule := FRules[I];
      if not Rule.IsSystem then
      begin
        Section := Format('Rule_%d', [UserRuleIdx]);
        
        IniFile.WriteInteger(Section, 'ID', Rule.ID);
        IniFile.WriteString(Section, 'Name', Rule.Name);
        IniFile.WriteString(Section, 'Pattern', Rule.Pattern);
        IniFile.WriteString(Section, 'RuleType', RuleTypeToString(Rule.RuleType));
        IniFile.WriteString(Section, 'Scope', ScopeToString(Rule.Scope));
        IniFile.WriteBool(Section, 'Enabled', Rule.Enabled);
        IniFile.WriteInteger(Section, 'Priority', Rule.Priority);
        IniFile.WriteString(Section, 'Description', Rule.Description);
        IniFile.WriteInt64(Section, 'NumericValue', Rule.NumericValue);
        
        Inc(UserRuleIdx);
      end;
    end;
    
    IniFile.WriteInteger('General', 'RuleCount', UserRuleIdx);
    IniFile.UpdateFile;
  finally
    IniFile.Free;
  end;
end;

function TExclusionRulesManager.RuleTypeToString(AType: TExclusionRuleType): string;
begin
  case AType of
    ertExactPath: Result := 'ExactPath';
    ertWildcard: Result := 'Wildcard';
    ertRegex: Result := 'Regex';
    ertExtension: Result := 'Extension';
    ertSizeGreater: Result := 'SizeGreater';
    ertSizeLess: Result := 'SizeLess';
    ertAgeOlderDays: Result := 'AgeOlderDays';
    ertAgeNewerDays: Result := 'AgeNewerDays';
  else
    Result := 'ExactPath';
  end;
end;

function TExclusionRulesManager.StringToRuleType(const S: string): TExclusionRuleType;
begin
  if SameText(S, 'Wildcard') then Result := ertWildcard
  else if SameText(S, 'Regex') then Result := ertRegex
  else if SameText(S, 'Extension') then Result := ertExtension
  else if SameText(S, 'SizeGreater') then Result := ertSizeGreater
  else if SameText(S, 'SizeLess') then Result := ertSizeLess
  else if SameText(S, 'AgeOlderDays') then Result := ertAgeOlderDays
  else if SameText(S, 'AgeNewerDays') then Result := ertAgeNewerDays
  else Result := ertExactPath;
end;

function TExclusionRulesManager.ScopeToString(AScope: TExclusionScope): string;
begin
  case AScope of
    esAll: Result := 'All';
    esScan: Result := 'Scan';
    esCleanup: Result := 'Cleanup';
    esMigration: Result := 'Migration';
  else
    Result := 'All';
  end;
end;

function TExclusionRulesManager.StringToScope(const S: string): TExclusionScope;
begin
  if SameText(S, 'Scan') then Result := esScan
  else if SameText(S, 'Cleanup') then Result := esCleanup
  else if SameText(S, 'Migration') then Result := esMigration
  else Result := esAll;
end;

function TExclusionRulesManager.MatchWildcard(const APath, APattern: string): Boolean;
var
  RegexPattern: string;
begin
  // 将通配符模式转换为正则表达式
  RegexPattern := APattern;
  RegexPattern := StringReplace(RegexPattern, '\', '\\', [rfReplaceAll]);
  RegexPattern := StringReplace(RegexPattern, '.', '\.', [rfReplaceAll]);
  RegexPattern := StringReplace(RegexPattern, '*', '.*', [rfReplaceAll]);
  RegexPattern := StringReplace(RegexPattern, '?', '.', [rfReplaceAll]);
  RegexPattern := '^' + RegexPattern + '$';
  
  try
    Result := TRegEx.IsMatch(APath, RegexPattern, [roIgnoreCase]);
  except
    Result := False;
  end;
end;

function TExclusionRulesManager.AddRule(const AName, APattern: string;
  AType: TExclusionRuleType; AScope: TExclusionScope; APriority: Integer): Integer;
var
  Rule: TExclusionRule;
begin
  Rule.ID := FNextID;
  Inc(FNextID);
  Rule.Name := AName;
  Rule.Pattern := APattern;
  Rule.RuleType := AType;
  Rule.Scope := AScope;
  Rule.Enabled := True;
  Rule.IsSystem := False;
  Rule.Priority := APriority;
  Rule.Description := '';
  Rule.NumericValue := 0;
  
  FRules.Add(Rule);
  SaveUserRules;
  
  Result := Rule.ID;
end;

procedure TExclusionRulesManager.UpdateRule(const Rule: TExclusionRule);
var
  I: Integer;
begin
  for I := 0 to FRules.Count - 1 do
  begin
    if FRules[I].ID = Rule.ID then
    begin
      if not FRules[I].IsSystem then  // 不允许修改系统规则
      begin
        FRules[I] := Rule;
        SaveUserRules;
      end;
      Exit;
    end;
  end;
end;

procedure TExclusionRulesManager.DeleteRule(RuleID: Integer);
var
  I: Integer;
begin
  for I := FRules.Count - 1 downto 0 do
  begin
    if (FRules[I].ID = RuleID) and not FRules[I].IsSystem then
    begin
      FRules.Delete(I);
      SaveUserRules;
      Exit;
    end;
  end;
end;

function TExclusionRulesManager.GetRule(RuleID: Integer): TExclusionRule;
var
  I: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for I := 0 to FRules.Count - 1 do
  begin
    if FRules[I].ID = RuleID then
    begin
      Result := FRules[I];
      Exit;
    end;
  end;
end;

function TExclusionRulesManager.GetAllRules: TArray<TExclusionRule>;
begin
  Result := FRules.ToArray;
end;

function TExclusionRulesManager.GetActiveRules(AScope: TExclusionScope): TArray<TExclusionRule>;
var
  ActiveRules: TList<TExclusionRule>;
  Rule: TExclusionRule;
begin
  ActiveRules := TList<TExclusionRule>.Create;
  try
    for Rule in FRules do
    begin
      if Rule.Enabled and ((Rule.Scope = esAll) or (Rule.Scope = AScope)) then
        ActiveRules.Add(Rule);
    end;
    
    // 按优先级排序
    ActiveRules.Sort(TComparer<TExclusionRule>.Construct(
      function(const L, R: TExclusionRule): Integer
      begin
        Result := L.Priority - R.Priority;
      end
    ));
    
    Result := ActiveRules.ToArray;
  finally
    ActiveRules.Free;
  end;
end;

function TExclusionRulesManager.ShouldExclude(const APath: string;
  AScope: TExclusionScope): Boolean;
var
  Rule: TExclusionRule;
begin
  Result := False;
  
  for Rule in FRules do
  begin
    if not Rule.Enabled then Continue;
    if (Rule.Scope <> esAll) and (Rule.Scope <> AScope) then Continue;
    
    case Rule.RuleType of
      ertExactPath:
        if SameText(APath, Rule.Pattern) then
        begin
          Result := True;
          Exit;
        end;
        
      ertWildcard:
        if MatchWildcard(APath, Rule.Pattern) then
        begin
          Result := True;
          Exit;
        end;
        
      ertRegex:
        try
          if TRegEx.IsMatch(APath, Rule.Pattern, [roIgnoreCase]) then
          begin
            Result := True;
            Exit;
          end;
        except
          // 无效正则，跳过
        end;
        
      ertExtension:
        if SameText(ExtractFileExt(APath), Rule.Pattern) or
           SameText('*' + ExtractFileExt(APath), Rule.Pattern) then
        begin
          Result := True;
          Exit;
        end;
    end;
  end;
end;

function TExclusionRulesManager.ShouldExcludeFile(const APath: string;
  AFileSize: Int64; AFileDate: TDateTime; AScope: TExclusionScope): Boolean;
var
  Rule: TExclusionRule;
  DaysOld: Integer;
begin
  // 先检查路径规则
  Result := ShouldExclude(APath, AScope);
  if Result then Exit;
  
  // 检查大小和日期规则
  for Rule in FRules do
  begin
    if not Rule.Enabled then Continue;
    if (Rule.Scope <> esAll) and (Rule.Scope <> AScope) then Continue;
    
    case Rule.RuleType of
      ertSizeGreater:
        if AFileSize > Rule.NumericValue then
        begin
          Result := True;
          Exit;
        end;
        
      ertSizeLess:
        if AFileSize < Rule.NumericValue then
        begin
          Result := True;
          Exit;
        end;
        
      ertAgeOlderDays:
        begin
          DaysOld := Trunc(Now - AFileDate);
          if DaysOld > Rule.NumericValue then
          begin
            Result := True;
            Exit;
          end;
        end;
        
      ertAgeNewerDays:
        begin
          DaysOld := Trunc(Now - AFileDate);
          if DaysOld < Rule.NumericValue then
          begin
            Result := True;
            Exit;
          end;
        end;
    end;
  end;
end;

function TExclusionRulesManager.GetMatchingRule(const APath: string;
  AScope: TExclusionScope): TExclusionRule;
var
  Rule: TExclusionRule;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  for Rule in FRules do
  begin
    if not Rule.Enabled then Continue;
    if (Rule.Scope <> esAll) and (Rule.Scope <> AScope) then Continue;
    
    case Rule.RuleType of
      ertExactPath:
        if SameText(APath, Rule.Pattern) then
        begin
          Result := Rule;
          Exit;
        end;
        
      ertWildcard:
        if MatchWildcard(APath, Rule.Pattern) then
        begin
          Result := Rule;
          Exit;
        end;
        
      ertRegex:
        try
          if TRegEx.IsMatch(APath, Rule.Pattern, [roIgnoreCase]) then
          begin
            Result := Rule;
            Exit;
          end;
        except
        end;
        
      ertExtension:
        if SameText(ExtractFileExt(APath), Rule.Pattern) or
           SameText('*' + ExtractFileExt(APath), Rule.Pattern) then
        begin
          Result := Rule;
          Exit;
        end;
    end;
  end;
end;

procedure TExclusionRulesManager.ExportRules(const AFileName: string);
var
  IniFile: TIniFile;
  I: Integer;
  Rule: TExclusionRule;
  Section: string;
begin
  IniFile := TIniFile.Create(AFileName);
  try
    IniFile.WriteInteger('Export', 'RuleCount', FRules.Count);
    IniFile.WriteString('Export', 'Version', '1.0');
    IniFile.WriteDateTime('Export', 'ExportTime', Now);
    
    for I := 0 to FRules.Count - 1 do
    begin
      Rule := FRules[I];
      Section := Format('Rule_%d', [I]);
      
      IniFile.WriteString(Section, 'Name', Rule.Name);
      IniFile.WriteString(Section, 'Pattern', Rule.Pattern);
      IniFile.WriteString(Section, 'RuleType', RuleTypeToString(Rule.RuleType));
      IniFile.WriteString(Section, 'Scope', ScopeToString(Rule.Scope));
      IniFile.WriteBool(Section, 'Enabled', Rule.Enabled);
      IniFile.WriteBool(Section, 'IsSystem', Rule.IsSystem);
      IniFile.WriteInteger(Section, 'Priority', Rule.Priority);
      IniFile.WriteString(Section, 'Description', Rule.Description);
      IniFile.WriteInt64(Section, 'NumericValue', Rule.NumericValue);
    end;
    
    IniFile.UpdateFile;
  finally
    IniFile.Free;
  end;
end;

procedure TExclusionRulesManager.ImportRules(const AFileName: string);
var
  IniFile: TIniFile;
  RuleCount, I: Integer;
  Rule: TExclusionRule;
  Section: string;
begin
  if not TFile.Exists(AFileName) then Exit;
  
  IniFile := TIniFile.Create(AFileName);
  try
    RuleCount := IniFile.ReadInteger('Export', 'RuleCount', 0);
    
    for I := 0 to RuleCount - 1 do
    begin
      Section := Format('Rule_%d', [I]);
      
      Rule.ID := FNextID;
      Inc(FNextID);
      Rule.Name := IniFile.ReadString(Section, 'Name', '');
      Rule.Pattern := IniFile.ReadString(Section, 'Pattern', '');
      Rule.RuleType := StringToRuleType(IniFile.ReadString(Section, 'RuleType', 'ExactPath'));
      Rule.Scope := StringToScope(IniFile.ReadString(Section, 'Scope', 'All'));
      Rule.Enabled := IniFile.ReadBool(Section, 'Enabled', True);
      Rule.IsSystem := False;  // 导入的规则都是用户规则
      Rule.Priority := IniFile.ReadInteger(Section, 'Priority', 100);
      Rule.Description := IniFile.ReadString(Section, 'Description', '');
      Rule.NumericValue := IniFile.ReadInt64(Section, 'NumericValue', 0);
      
      if (Rule.Name <> '') and (Rule.Pattern <> '') then
        FRules.Add(Rule);
    end;
    
    SaveUserRules;
  finally
    IniFile.Free;
  end;
end;

procedure TExclusionRulesManager.EnableRule(RuleID: Integer; AEnabled: Boolean);
var
  I: Integer;
  Rule: TExclusionRule;
begin
  for I := 0 to FRules.Count - 1 do
  begin
    if FRules[I].ID = RuleID then
    begin
      Rule := FRules[I];
      Rule.Enabled := AEnabled;
      FRules[I] := Rule;
      if not Rule.IsSystem then
        SaveUserRules;
      Exit;
    end;
  end;
end;

procedure TExclusionRulesManager.SetRulePriority(RuleID: Integer; APriority: Integer);
var
  I: Integer;
  Rule: TExclusionRule;
begin
  for I := 0 to FRules.Count - 1 do
  begin
    if FRules[I].ID = RuleID then
    begin
      Rule := FRules[I];
      Rule.Priority := APriority;
      FRules[I] := Rule;
      if not Rule.IsSystem then
        SaveUserRules;
      Exit;
    end;
  end;
end;

procedure TExclusionRulesManager.ResetToDefaults;
begin
  // 删除所有用户规则
  for var I := FRules.Count - 1 downto 0 do
  begin
    if not FRules[I].IsSystem then
      FRules.Delete(I);
  end;
  
  // 删除配置文件
  if TFile.Exists(FConfigFile) then
    TFile.Delete(FConfigFile);
  
  FNextID := 1000;  // 用户规则从1000开始
end;

initialization

finalization
  if _ExclusionRules <> nil then
  begin
    _ExclusionRules.Free;
    _ExclusionRules := nil;
  end;

end.

unit uConflictResolver;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  System.Generics.Defaults, System.JSON, System.Threading, System.SyncObjs, System.Math, 
  System.DateUtils, uFileSyncComparerSimple, uSyncDatabase, uFileHasher;

type
  // 冲突类型
  TConflictType = (ctContent, ctTimestamp, ctSize, ctPermission, ctLock, ctVersion);
  
  // 冲突严重程度
  TConflictSeverity = (csLow, csMedium, csHigh, csCritical);
  
  // 解决策略
  TConflictResolutionStrategy = (crsSourcePriority, crsTargetPriority, crsNewerPriority, 
    crsLargerPriority, crsSmallerPriority, crsAskUser, crsKeepBoth, crsSkip, crsAutoResolve);
  
  // 冲突记录
  TConflictRecord = record
    ID: string;
    FilePath: string;
    SourcePath: string;
    TargetPath: string;
    ConflictType: TConflictType;
    Severity: TConflictSeverity;
    SourceSize: Int64;
    TargetSize: Int64;
    SourceModified: TDateTime;
    TargetModified: TDateTime;
    SourceHash: string;
    TargetHash: string;
    DetectedTime: TDateTime;
    Description: string;
    Resolved: Boolean;
    ResolutionStrategy: TConflictResolutionStrategy;
    ResolutionTime: TDateTime;
    ResolutionAction: string;
  end;
  
  // 解决建议
  TConflictSuggestion = record
    Strategy: TConflictResolutionStrategy;
    Confidence: Double; // 0.0 - 1.0
    Reason: string;
    RiskLevel: TConflictSeverity;
  end;

  // 文件信息记录
  TFileInfo = record
    FullName: string;
    Size: Int64;
    LastWriteTime: TDateTime;
  end;

type
  TConflictDetectedEvent = procedure(const AConflict: TConflictRecord) of object;
  TConflictResolvedEvent = procedure(const AConflict: TConflictRecord) of object;
  TConflictResolutionRequest = procedure(const AConflict: TConflictRecord; 
    var ASuggestedStrategy: TConflictResolutionStrategy) of object;

type
  TConflictResolver = class
  private
    FDatabase: TSyncDatabase;
    FConflictHistory: TDictionary<string, TConflictRecord>;
    FResolutionRules: TDictionary<TConflictType, TConflictResolutionStrategy>;
    FAutoResolveEnabled: Boolean;
    FLock: TCriticalSection;
    
    // 事件
    FOnConflictDetected: TConflictDetectedEvent;
    FOnConflictResolved: TConflictResolvedEvent;
    FOnResolutionRequest: TConflictResolutionRequest;
    
    // 内部方法
    function DetectConflict(const ASourceInfo, ATargetInfo: TFileInfo; const ARelativePath: string): TConflictRecord;
    function AnalyzeConflictSeverity(const AConflict: TConflictRecord): TConflictSeverity;
    function GenerateSuggestions(const AConflict: TConflictRecord): TArray<TConflictSuggestion>;
    function GetBestSuggestion(const ASuggestions: TArray<TConflictSuggestion>): TConflictSuggestion;
    function ApplyResolution(var AConflict: TConflictRecord; const AStrategy: TConflictResolutionStrategy): Boolean;
    function BackupFile(const AFilePath: string): string;
    function CompareFileContent(const ASourcePath, ATargetPath: string): Boolean;
    procedure LogConflict(const AConflict: TConflictRecord);
    procedure UpdateConflictHistory(const AConflict: TConflictRecord);
    
  public
    constructor Create(ADatabase: TSyncDatabase);
    destructor Destroy; override;
    
    // 主要功能
    function ScanForConflicts(const ASourcePath, ATargetPath: string): TArray<TConflictRecord>;
    function ResolveConflict(const AConflictID: string; const AStrategy: TConflictResolutionStrategy): Boolean;
    function AutoResolveConflicts(const AConflicts: TArray<TConflictRecord>): TArray<TConflictRecord>;
    
    // 批量处理
    function ResolveAllConflicts(const ASourcePath, ATargetPath: string): TArray<TConflictRecord>;
    procedure BatchResolveConflicts(const AConflictIDs: TArray<string>; const AStrategy: TConflictResolutionStrategy);
    
    // 规则管理
    procedure SetResolutionRule(const AConflictType: TConflictType; const AStrategy: TConflictResolutionStrategy);
    function GetResolutionRule(const AConflictType: TConflictType): TConflictResolutionStrategy;
    procedure LoadResolutionRules;
    procedure SaveResolutionRules;
    
    // 历史记录
    function GetConflictHistory(const ACount: Integer = 100): TArray<TConflictRecord>;
    function GetUnresolvedConflicts: TArray<TConflictRecord>;
    procedure ClearConflictHistory;
    
    // 统计信息
    function GetConflictStatistics: TDictionary<string, Integer>;
    
    // 配置
    property AutoResolveEnabled: Boolean read FAutoResolveEnabled write FAutoResolveEnabled;
    
    // 事件
    property OnConflictDetected: TConflictDetectedEvent read FOnConflictDetected write FOnConflictDetected;
    property OnConflictResolved: TConflictResolvedEvent read FOnConflictResolved write FOnConflictResolved;
    property OnResolutionRequest: TConflictResolutionRequest read FOnResolutionRequest write FOnResolutionRequest;
  end;

implementation

{ TConflictResolver }

constructor TConflictResolver.Create(ADatabase: TSyncDatabase);
begin
  inherited Create;
  FDatabase := ADatabase;
  FConflictHistory := TDictionary<string, TConflictRecord>.Create;
  FResolutionRules := TDictionary<TConflictType, TConflictResolutionStrategy>.Create;
  FLock := TCriticalSection.Create;
  FAutoResolveEnabled := False;
  
  // 设置默认解决规则
  FResolutionRules.AddOrSetValue(ctContent, crsAskUser);
  FResolutionRules.AddOrSetValue(ctTimestamp, crsNewerPriority);
  FResolutionRules.AddOrSetValue(ctSize, crsAskUser);
  FResolutionRules.AddOrSetValue(ctPermission, crsSourcePriority);
  FResolutionRules.AddOrSetValue(ctLock, crsSkip);
  FResolutionRules.AddOrSetValue(ctVersion, crsNewerPriority);
  
  LoadResolutionRules;
end;

destructor TConflictResolver.Destroy;
begin
  SaveResolutionRules;
  FreeAndNil(FLock);
  FreeAndNil(FResolutionRules);
  FreeAndNil(FConflictHistory);
  inherited Destroy;
end;

function TConflictResolver.ScanForConflicts(const ASourcePath, ATargetPath: string): TArray<TConflictRecord>;
var
  Comparer: TFileSyncComparer;
  Diffs: TArray<TFileDiff>;
  ConflictList: TList<TConflictRecord>;
  Diff: TFileDiff;
  Conflict: TConflictRecord;
  SourceInfo, TargetInfo: TFileInfo;
begin
  ConflictList := TList<TConflictRecord>.Create;
  Comparer := TFileSyncComparer.Create;
  
  try
    // 获取文件差异
    Diffs := Comparer.CompareDirectories(ASourcePath, ATargetPath);
    
    // 检测冲突
    for Diff in Diffs do
    begin
      if Diff.DiffType = fdtConflict then
      begin
        SourceInfo.FullName := Diff.SourceFullPath;
        SourceInfo.Size := TFile.GetSize(Diff.SourceFullPath);
        SourceInfo.LastWriteTime := TFile.GetLastWriteTime(Diff.SourceFullPath);
        
        TargetInfo.FullName := Diff.TargetFullPath;
        TargetInfo.Size := TFile.GetSize(Diff.TargetFullPath);
        TargetInfo.LastWriteTime := TFile.GetLastWriteTime(Diff.TargetFullPath);
        
        Conflict := DetectConflict(SourceInfo, TargetInfo, Diff.RelativePath);
        ConflictList.Add(Conflict);
        LogConflict(Conflict);
      end;
    end;
    
    Result := ConflictList.ToArray;
  finally
    Comparer.Free;
    ConflictList.Free;
  end;
end;

function TConflictResolver.DetectConflict(const ASourceInfo, ATargetInfo: TFileInfo; const ARelativePath: string): TConflictRecord;
var
  Hasher: TFileHasher;
begin
  Result.ID := TGuid.NewGuid.ToString;
  Result.FilePath := ARelativePath;
  Result.SourcePath := ASourceInfo.FullName;
  Result.TargetPath := ATargetInfo.FullName;
  Result.SourceSize := ASourceInfo.Size;
  Result.TargetSize := ATargetInfo.Size;
  Result.SourceModified := ASourceInfo.LastWriteTime;
  Result.TargetModified := ATargetInfo.LastWriteTime;
  Result.DetectedTime := Now;
  Result.Resolved := False;
  Result.ResolutionStrategy := crsAskUser;
  Result.ResolutionTime := 0;
  Result.ResolutionAction := '';
  
  // 检测冲突类型
  if Result.SourceSize <> Result.TargetSize then
  begin
    Result.ConflictType := ctSize;
    Result.Description := Format('文件大小不同：源文件 %d 字节，目标文件 %d 字节', 
      [Result.SourceSize, Result.TargetSize]);
  end
  else if Abs(Result.SourceModified - Result.TargetModified) > (1.0 / 24.0 / 60.0) then // 1分钟差异
  begin
    Result.ConflictType := ctTimestamp;
    Result.Description := Format('文件修改时间不同：源文件 %s，目标文件 %s', 
      [FormatDateTime('yyyy-mm-dd hh:nn:ss', Result.SourceModified),
       FormatDateTime('yyyy-mm-dd hh:nn:ss', Result.TargetModified)]);
  end
  else
  begin
    // 检查内容是否不同
    if CompareFileContent(Result.SourcePath, Result.TargetPath) then
    begin
      Result.ConflictType := ctContent;
      Result.Description := '文件内容不同（哈希值不匹配）';
    end
    else
    begin
      Result.ConflictType := ctVersion;
      Result.Description := '文件版本冲突';
    end;
  end;
  
  // 分析严重程度
  Result.Severity := AnalyzeConflictSeverity(Result);
  
  // 计算哈希值
  Hasher := TFileHasher.Create;
  try
    Result.SourceHash := Hasher.ComputeSHA256(Result.SourcePath);
    Result.TargetHash := Hasher.ComputeSHA256(Result.TargetPath);
  finally
    Hasher.Free;
  end;
end;

function TConflictResolver.AnalyzeConflictSeverity(const AConflict: TConflictRecord): TConflictSeverity;
var
  TimeDiff: Double;
  SizeDiffRatio: Double;
begin
  Result := csLow;
  
  case AConflict.ConflictType of
    ctLock:
      Result := csHigh;
      
    ctPermission:
      Result := csMedium;
      
    ctContent:
      begin
        if AConflict.SourceHash = AConflict.TargetHash then
          Result := csLow
        else
          Result := csHigh;
      end;
      
    ctTimestamp:
      begin
        TimeDiff := Abs(AConflict.SourceModified - AConflict.TargetModified);
        if TimeDiff > 1.0 then // 超过1天
          Result := csMedium
        else if TimeDiff > (1.0 / 24.0) then // 超过1小时
          Result := csLow;
      end;
      
    ctSize:
      begin
        if (AConflict.SourceSize > 0) and (AConflict.TargetSize > 0) then
        begin
          SizeDiffRatio := Abs(AConflict.SourceSize - AConflict.TargetSize) / 
                          Max(AConflict.SourceSize, AConflict.TargetSize);
          if SizeDiffRatio > 0.5 then // 大小差异超过50%
            Result := csHigh
          else if SizeDiffRatio > 0.1 then // 大小差异超过10%
            Result := csMedium;
        end;
      end;
      
    ctVersion:
      Result := csMedium;
  end;
end;

function TConflictResolver.GenerateSuggestions(const AConflict: TConflictRecord): TArray<TConflictSuggestion>;
var
  SuggestionList: TList<TConflictSuggestion>;
  Suggestion: TConflictSuggestion;
  TimeDiff: Double;
begin
  SuggestionList := TList<TConflictSuggestion>.Create;
  
  try
    // 基于冲突类型生成建议
    
    // 时间优先策略
    if AConflict.ConflictType in [ctTimestamp, ctVersion] then
    begin
      Suggestion.Strategy := crsNewerPriority;
      TimeDiff := AConflict.SourceModified - AConflict.TargetModified;
      if TimeDiff > 0 then
        Suggestion.Reason := '源文件较新，建议保留源文件'
      else
        Suggestion.Reason := '目标文件较新，建议保留目标文件';
      Suggestion.Confidence := 0.8;
      Suggestion.RiskLevel := csLow;
      SuggestionList.Add(Suggestion);
    end;
    
    // 大小优先策略
    if AConflict.ConflictType = ctSize then
    begin
      if AConflict.SourceSize > AConflict.TargetSize then
      begin
        Suggestion.Strategy := crsLargerPriority;
        Suggestion.Reason := '源文件较大，可能包含更多内容';
      end
      else
      begin
        Suggestion.Strategy := crsSmallerPriority;
        Suggestion.Reason := '目标文件较小，可能是精简版本';
      end;
      Suggestion.Confidence := 0.6;
      Suggestion.RiskLevel := csMedium;
      SuggestionList.Add(Suggestion);
    end;
    
    // 保留两个文件
    if AConflict.Severity >= csMedium then
    begin
      Suggestion.Strategy := crsKeepBoth;
      Suggestion.Reason := '冲突较严重，建议保留两个文件';
      Suggestion.Confidence := 0.9;
      Suggestion.RiskLevel := csLow;
      SuggestionList.Add(Suggestion);
    end;
    
    // 用户选择
    Suggestion.Strategy := crsAskUser;
    Suggestion.Reason := '需要用户手动决定';
    Suggestion.Confidence := 0.5;
    Suggestion.RiskLevel := csLow;
    SuggestionList.Add(Suggestion);
    
    Result := SuggestionList.ToArray;
  finally
    SuggestionList.Free;
  end;
end;

function TConflictResolver.GetBestSuggestion(const ASuggestions: TArray<TConflictSuggestion>): TConflictSuggestion;
var
  BestSuggestion: TConflictSuggestion;
  Suggestion: TConflictSuggestion;
begin
  BestSuggestion.Confidence := 0.0;
  
  for Suggestion in ASuggestions do
  begin
    if Suggestion.Confidence > BestSuggestion.Confidence then
      BestSuggestion := Suggestion;
  end;
  
  Result := BestSuggestion;
end;

function TConflictResolver.ResolveConflict(const AConflictID: string; const AStrategy: TConflictResolutionStrategy): Boolean;
var
  Conflict: TConflictRecord;
begin
  Result := False;
  
  FLock.Enter;
  try
    if not FConflictHistory.ContainsKey(AConflictID) then Exit;
    
    Conflict := FConflictHistory[AConflictID];
    if Conflict.Resolved then Exit; // 已解决的冲突
    
    Result := ApplyResolution(Conflict, AStrategy);
    
    if Result then
    begin
      Conflict.Resolved := True;
      Conflict.ResolutionStrategy := AStrategy;
      Conflict.ResolutionTime := Now;
      UpdateConflictHistory(Conflict);
      
      if Assigned(FOnConflictResolved) then
        FOnConflictResolved(Conflict);
    end;
  finally
    FLock.Leave;
  end;
end;

function TConflictResolver.ApplyResolution(var AConflict: TConflictRecord; const AStrategy: TConflictResolutionStrategy): Boolean;
begin
  Result := False;
  
  case AStrategy of
    crsSourcePriority:
      begin
        try
          // 复制源文件覆盖目标文件
          TFile.Copy(AConflict.SourcePath, AConflict.TargetPath, True);
          AConflict.ResolutionAction := '源文件覆盖目标文件';
          Result := True;
        except
          on E: Exception do
            AConflict.ResolutionAction := '操作失败: ' + E.Message;
        end;
      end;
      
    crsTargetPriority:
      begin
        try
          // 复制目标文件覆盖源文件
          TFile.Copy(AConflict.TargetPath, AConflict.SourcePath, True);
          AConflict.ResolutionAction := '目标文件覆盖源文件';
          Result := True;
        except
          on E: Exception do
            AConflict.ResolutionAction := '操作失败: ' + E.Message;
        end;
      end;
      
    crsNewerPriority:
      begin
        if AConflict.SourceModified > AConflict.TargetModified then
          Result := ApplyResolution(AConflict, crsSourcePriority)
        else
          Result := ApplyResolution(AConflict, crsTargetPriority);
      end;
      
    crsLargerPriority:
      begin
        if AConflict.SourceSize > AConflict.TargetSize then
          Result := ApplyResolution(AConflict, crsSourcePriority)
        else
          Result := ApplyResolution(AConflict, crsTargetPriority);
      end;
      
    crsSmallerPriority:
      begin
        if AConflict.SourceSize < AConflict.TargetSize then
          Result := ApplyResolution(AConflict, crsSourcePriority)
        else
          Result := ApplyResolution(AConflict, crsTargetPriority);
      end;
      
    crsKeepBoth:
      begin
        try
          // 备份目标文件，然后复制源文件
          var BackupPath := BackupFile(AConflict.TargetPath);
          TFile.Copy(AConflict.SourcePath, AConflict.TargetPath, True);
          AConflict.ResolutionAction := '保留两个文件，目标文件备份至: ' + BackupPath;
          Result := True;
        except
          on E: Exception do
            AConflict.ResolutionAction := '操作失败: ' + E.Message;
        end;
      end;
      
    crsSkip:
      begin
        AConflict.ResolutionAction := '跳过处理';
        Result := True;
      end;
      
    crsAskUser:
      begin
        // 触发用户选择事件
        if Assigned(FOnResolutionRequest) then
        begin
          var UserStrategy := AStrategy;
          FOnResolutionRequest(AConflict, UserStrategy);
          if UserStrategy <> crsAskUser then
            Result := ApplyResolution(AConflict, UserStrategy);
        end;
      end;
      
    crsAutoResolve:
      begin
        // 自动选择最佳策略
        var Suggestions := GenerateSuggestions(AConflict);
        var BestSuggestion := GetBestSuggestion(Suggestions);
        Result := ApplyResolution(AConflict, BestSuggestion.Strategy);
      end;
  end;
end;

function TConflictResolver.BackupFile(const AFilePath: string): string;
var
  BackupPath: string;
  Counter: Integer;
begin
  BackupPath := AFilePath + '.backup.' + FormatDateTime('yyyymmddhhnnss', Now);
  Counter := 1;
  
  while TFile.Exists(BackupPath) do
  begin
    BackupPath := AFilePath + '.backup.' + FormatDateTime('yyyymmddhhnnss', Now) + '.' + Counter.ToString;
    Inc(Counter);
  end;
  
  TFile.Copy(AFilePath, BackupPath);
  Result := BackupPath;
end;

function TConflictResolver.CompareFileContent(const ASourcePath, ATargetPath: string): Boolean;
var
  SourceHash, TargetHash: string;
  Hasher: TFileHasher;
begin
  Hasher := TFileHasher.Create;
  try
    SourceHash := Hasher.ComputeSHA256(ASourcePath);
    TargetHash := Hasher.ComputeSHA256(ATargetPath);
    Result := SourceHash <> TargetHash;
  finally
    Hasher.Free;
  end;
end;

procedure TConflictResolver.LogConflict(const AConflict: TConflictRecord);
begin
  FLock.Enter;
  try
    FConflictHistory.AddOrSetValue(AConflict.ID, AConflict);
    
    // 保存到数据库
    if Assigned(FDatabase) then
    begin
      // TODO: 实现数据库保存逻辑
    end;
    
    if Assigned(FOnConflictDetected) then
      FOnConflictDetected(AConflict);
  finally
    FLock.Leave;
  end;
end;

procedure TConflictResolver.UpdateConflictHistory(const AConflict: TConflictRecord);
begin
  FLock.Enter;
  try
    FConflictHistory.AddOrSetValue(AConflict.ID, AConflict);
    
    // 更新数据库
    if Assigned(FDatabase) then
    begin
      // TODO: 实现数据库更新逻辑
    end;
  finally
    FLock.Leave;
  end;
end;

function TConflictResolver.AutoResolveConflicts(const AConflicts: TArray<TConflictRecord>): TArray<TConflictRecord>;
var
  ResolvedList: TList<TConflictRecord>;
  Conflict: TConflictRecord;
begin
  ResolvedList := TList<TConflictRecord>.Create;
  
  try
    for Conflict in AConflicts do
    begin
      if not Conflict.Resolved then
      begin
        var Suggestions := GenerateSuggestions(Conflict);
        var BestSuggestion := GetBestSuggestion(Suggestions);
        
        if (BestSuggestion.Confidence >= 0.8) and (FAutoResolveEnabled) then
        begin
          if ResolveConflict(Conflict.ID, BestSuggestion.Strategy) then
            ResolvedList.Add(Conflict);
        end;
      end;
    end;
    
    Result := ResolvedList.ToArray;
  finally
    ResolvedList.Free;
  end;
end;

function TConflictResolver.ResolveAllConflicts(const ASourcePath, ATargetPath: string): TArray<TConflictRecord>;
var
  Conflicts: TArray<TConflictRecord>;
begin
  Conflicts := ScanForConflicts(ASourcePath, ATargetPath);
  Result := AutoResolveConflicts(Conflicts);
end;

procedure TConflictResolver.BatchResolveConflicts(const AConflictIDs: TArray<string>; const AStrategy: TConflictResolutionStrategy);
var
  ConflictID: string;
begin
  for ConflictID in AConflictIDs do
  begin
    ResolveConflict(ConflictID, AStrategy);
  end;
end;

procedure TConflictResolver.SetResolutionRule(const AConflictType: TConflictType; const AStrategy: TConflictResolutionStrategy);
begin
  FLock.Enter;
  try
    FResolutionRules.AddOrSetValue(AConflictType, AStrategy);
  finally
    FLock.Leave;
  end;
end;

function TConflictResolver.GetResolutionRule(const AConflictType: TConflictType): TConflictResolutionStrategy;
begin
  FLock.Enter;
  try
    if FResolutionRules.ContainsKey(AConflictType) then
      Result := FResolutionRules[AConflictType]
    else
      Result := crsAskUser;
  finally
    FLock.Leave;
  end;
end;

procedure TConflictResolver.LoadResolutionRules;
begin
  // TODO: 从配置文件或数据库加载规则
end;

procedure TConflictResolver.SaveResolutionRules;
begin
  // TODO: 保存规则到配置文件或数据库
end;

function TConflictResolver.GetConflictHistory(const ACount: Integer = 100): TArray<TConflictRecord>;
var
  HistoryList: TList<TConflictRecord>;
  ConflictArray: TArray<TConflictRecord>;
  I: Integer;
begin
  HistoryList := TList<TConflictRecord>.Create;
  
  try
    FLock.Enter;
    try
      ConflictArray := FConflictHistory.Values.ToArray;
      // 按时间排序
      TArray.Sort<TConflictRecord>(ConflictArray, 
        TComparer<TConflictRecord>.Construct(
          function(const A, B: TConflictRecord): Integer
          begin
            Result := CompareDateTime(B.DetectedTime, A.DetectedTime);
          end));
      
      for I := 0 to Min(ACount - 1, High(ConflictArray)) do
      begin
        HistoryList.Add(ConflictArray[I]);
      end;
    finally
      FLock.Leave;
    end;
    
    Result := HistoryList.ToArray;
  finally
    HistoryList.Free;
  end;
end;

function TConflictResolver.GetUnresolvedConflicts: TArray<TConflictRecord>;
var
  UnresolvedList: TList<TConflictRecord>;
  Conflict: TConflictRecord;
begin
  UnresolvedList := TList<TConflictRecord>.Create;
  
  try
    FLock.Enter;
    try
      for Conflict in FConflictHistory.Values do
      begin
        if not Conflict.Resolved then
          UnresolvedList.Add(Conflict);
      end;
    finally
      FLock.Leave;
    end;
    
    Result := UnresolvedList.ToArray;
  finally
    UnresolvedList.Free;
  end;
end;

procedure TConflictResolver.ClearConflictHistory;
begin
  FLock.Enter;
  try
    FConflictHistory.Clear;
  finally
    FLock.Leave;
  end;
end;

function TConflictResolver.GetConflictStatistics: TDictionary<string, Integer>;
var
  Stats: TDictionary<string, Integer>;
  Conflict: TConflictRecord;
begin
  Stats := TDictionary<string, Integer>.Create;
  
  FLock.Enter;
  try
    Stats.AddOrSetValue('Total', FConflictHistory.Count);
    Stats.AddOrSetValue('Resolved', 0);
    Stats.AddOrSetValue('Unresolved', 0);
    
    for Conflict in FConflictHistory.Values do
    begin
      if Conflict.Resolved then
        Stats[Conflict.Resolved.ToString] := Stats[Conflict.Resolved.ToString] + 1
      else
        Stats['Unresolved'] := Stats['Unresolved'] + 1;
    end;
  finally
    FLock.Leave;
  end;
  
  Result := Stats;
end;

end.

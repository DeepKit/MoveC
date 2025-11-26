unit uFileSyncComparer;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  System.Threading, System.Diagnostics, System.Hash, uFileHasher, uSyncDatabase;

type
  // 文件差异类型
  TFileDiffType = (fdtIdentical, fdtSourceNewer, fdtTargetNewer, fdtSourceOnly, fdtTargetOnly, fdtConflict);
  
  // 文件差异信息
  TFileDiff = record
    RelativePath: string;
    SourceFullPath: string;
    TargetFullPath: string;
    DiffType: TFileDiffType;
    SourceSize: Int64;
    TargetSize: Int64;
    SourceModified: TDateTime;
    TargetModified: TDateTime;
    SourceHash: string;
    TargetHash: string;
    SizeDifference: Int64;
    TimeDifference: TTimeSpan;
    Reason: string;
  end;
  
  // 同步操作建议
  TSyncAction = (saCopyToTarget, saCopyToSource, saUpdateTarget, saUpdateSource, saDeleteFromTarget, 
                 saDeleteFromSource, saSkip, saAskUser);
  
  // 同步建议
  TSyncRecommendation = record
    Diff: TFileDiff;
    RecommendedAction: TSyncAction;
    Confidence: Double; // 0.0 - 1.0
    Explanation: string;
  end;

type
  TFileSyncComparer = class
  private
    FFileHasher: TFileHasher;
    FMaxConcurrency: Integer;
    FHashCache: TDictionary<string, string>;
    FCacheLock: TCriticalSection;
    
    function CalculateFileHash(const AFilePath: string): string;
    function GetFileHashCached(const AFilePath: string): string;
    function CompareFileMetadata(const ASourceInfo, ATargetInfo: TFileInfo): TFileDiffType;
    function CompareFileHashes(const ASourceHash, ATargetHash: string): Boolean;
    function AnalyzeFileDiff(const ASourceInfo, ATargetInfo: TFileInfo; const ARelativePath: string): TFileDiff;
    function RecommendSyncAction(const ADiff: TFileDiff): TSyncRecommendation;
    function GetConflictReason(const ADiff: TFileDiff): string;
    function CalculateConfidence(const ADiff: TFileDiff; const AAction: TSyncAction): Double;
    
  public
    constructor Create(const AMaxConcurrency: Integer = 4);
    destructor Destroy; override;
    
    // 主要比较功能
    function CompareDirectories(const ASourcePath, ATargetPath: string; 
      const AFilterRules: string = ''; const AProgressCallback: TProc<Integer, string> = nil): TArray<TFileDiff>;
    
    // 批量比较
    function CompareFileLists(const ASourceFiles, ATargetFiles: TArray<TFileInfo>; 
      const ABasePath: string): TArray<TFileDiff>;
    
    // 生成同步建议
    function GenerateSyncRecommendations(const ADiffs: TArray<TFileDiff>): TArray<TSyncRecommendation>;
    
    // 增量同步扫描
    function ScanForChanges(const ASourcePath, ATargetPath: string; 
      const ALastSyncTime: TDateTime): TArray<TFileDiff>;
    
    // 统计信息
    function GetComparisonStatistics(const ADiffs: TArray<TFileDiff>): TDictionary<string, Integer>;
    
    // 清理缓存
    procedure ClearHashCache;
    
    property MaxConcurrency: Integer read FMaxConcurrency write FMaxConcurrency;
  end;

implementation

{ TFileSyncComparer }

constructor TFileSyncComparer.Create(const AMaxConcurrency: Integer = 4);
begin
  inherited Create;
  FFileHasher := TFileHasher.Create;
  FMaxConcurrency := AMaxConcurrency;
  FHashCache := TDictionary<string, string>.Create;
  FCacheLock := TCriticalSection.Create;
end;

destructor TFileSyncComparer.Destroy;
begin
  ClearHashCache;
  FreeAndNil(FCacheLock);
  FreeAndNil(FFileHasher);
  inherited Destroy;
end;

function TFileSyncComparer.CalculateFileHash(const AFilePath: string): string;
begin
  if not TFile.Exists(AFilePath) then
  begin
    Result := '';
    Exit;
  end;
  
  try
    // 使用 SHA256 哈希算法
    Result := FFileHasher.CalculateFileHash(AFilePath, THashAlgorithm.SHA256);
  except
    on E: Exception do
    begin
      Result := '';
      // 可以记录日志
    end;
  end;
end;

function TFileSyncComparer.GetFileHashCached(const AFilePath: string): string;
var
  FileTime: TDateTime;
  CacheKey: string;
begin
  if not TFile.Exists(AFilePath) then
  begin
    Result := '';
    Exit;
  end;
  
  // 生成缓存键（文件路径 + 修改时间）
  FileTime := TFile.GetLastWriteTime(AFilePath);
  CacheKey := AFilePath + '|' + FileTime.ToString;
  
  FCacheLock.Enter;
  try
    if FHashCache.TryGetValue(CacheKey, Result) then
      Exit;
    
    // 计算哈希并缓存
    Result := CalculateFileHash(AFilePath);
    if Result <> '' then
      FHashCache.AddOrSetValue(CacheKey, Result);
  finally
    FCacheLock.Leave;
  end;
end;

function TFileSyncComparer.CompareFileMetadata(const ASourceInfo, ATargetInfo: TFileInfo): TFileDiffType;
var
  SizeDiff: Int64;
  TimeDiff: TTimeSpan;
begin
  Result := fdtIdentical;
  
  // 比较文件大小
  SizeDiff := ASourceInfo.Size - ATargetInfo.Size;
  if SizeDiff <> 0 then
  begin
    // 大小不同，直接判断为有差异
    if ASourceInfo.LastWriteTime > ATargetInfo.LastWriteTime then
      Result := fdtSourceNewer
    else if ASourceInfo.LastWriteTime < ATargetInfo.LastWriteTime then
      Result := fdtTargetNewer
    else
      Result := fdtConflict; // 大小不同但时间相同，可能是冲突
    Exit;
  end;
  
  // 比较修改时间
  TimeDiff := ASourceInfo.LastWriteTime - ATargetInfo.LastWriteTime;
  if Abs(TimeDiff.TotalMilliseconds) > 1000 then // 1秒容差
  begin
    if TimeDiff.TotalMilliseconds > 0 then
      Result := fdtSourceNewer
    else
      Result := fdtTargetNewer;
  end;
end;

function TFileSyncComparer.CompareFileHashes(const ASourceHash, ATargetHash: string): Boolean;
begin
  Result := (ASourceHash <> '') and (ATargetHash <> '') and (ASourceHash = ATargetHash);
end;

function TFileSyncComparer.AnalyzeFileDiff(const ASourceInfo, ATargetInfo: TFileInfo; const ARelativePath: string): TFileDiff;
begin
  Result.RelativePath := ARelativePath;
  Result.SourceFullPath := ASourceInfo.FullName;
  Result.TargetFullPath := ATargetInfo.FullName;
  
  // 基本信息
  Result.SourceSize := ASourceInfo.Size;
  Result.TargetSize := ATargetInfo.Size;
  Result.SourceModified := ASourceInfo.LastWriteTime;
  Result.TargetModified := ATargetInfo.LastWriteTime;
  
  // 计算差异
  Result.SizeDifference := Result.SourceSize - Result.TargetSize;
  Result.TimeDifference := Result.SourceModified - Result.TargetModified;
  
  // 获取哈希值（仅在需要时计算）
  if Result.SourceSize = Result.TargetSize then
  begin
    Result.SourceHash := GetFileHashCached(Result.SourceFullPath);
    Result.TargetHash := GetFileHashCached(Result.TargetFullPath);
    
    if CompareFileHashes(Result.SourceHash, Result.TargetHash) then
    begin
      Result.DiffType := fdtIdentical;
      Result.Reason := '文件内容相同';
      Exit;
    end;
  end;
  
  // 分析差异类型
  Result.DiffType := CompareFileMetadata(ASourceInfo, ATargetInfo);
  Result.Reason := GetConflictReason(Result);
end;

function TFileSyncComparer.GetConflictReason(const ADiff: TFileDiff): string;
begin
  case ADiff.DiffType of
    fdtIdentical:
      Result := '文件完全相同';
    fdtSourceNewer:
      Result := Format('源文件较新（%s）', [ADiff.TimeDifference.ToString]);
    fdtTargetNewer:
      Result := Format('目标文件较新（%s）', [Abs(ADiff.TimeDifference.TotalSeconds).ToString + '秒']);
    fdtSourceOnly:
      Result := '仅存在于源目录';
    fdtTargetOnly:
      Result := '仅存在于目标目录';
    fdtConflict:
      begin
        if ADiff.SizeDifference <> 0 then
          Result := Format('文件大小不同（差异：%d 字节）', [ADiff.SizeDifference])
        else if ADiff.SourceHash <> ADiff.TargetHash then
          Result := '文件内容不同（哈希值不匹配）'
        else
          Result := '未知冲突';
      end;
  end;
end;

function TFileSyncComparer.RecommendSyncAction(const ADiff: TFileDiff): TSyncRecommendation;
begin
  Result.Diff := ADiff;
  
  case ADiff.DiffType of
    fdtIdentical:
      begin
        Result.RecommendedAction := saSkip;
        Result.Confidence := 1.0;
        Result.Explanation := '文件已同步，无需操作';
      end;
      
    fdtSourceNewer:
      begin
        Result.RecommendedAction := saUpdateTarget;
        Result.Confidence := 0.9;
        Result.Explanation := '源文件较新，建议更新目标文件';
      end;
      
    fdtTargetNewer:
      begin
        Result.RecommendedAction := saUpdateSource;
        Result.Confidence := 0.9;
        Result.Explanation := '目标文件较新，建议更新源文件';
      end;
      
    fdtSourceOnly:
      begin
        Result.RecommendedAction := saCopyToTarget;
        Result.Confidence := 0.95;
        Result.Explanation := '文件仅存在于源目录，建议复制到目标目录';
      end;
      
    fdtTargetOnly:
      begin
        Result.RecommendedAction := saDeleteFromTarget;
        Result.Confidence := 0.7;
        Result.Explanation := '文件仅存在于目标目录，可能是已删除的文件';
      end;
      
    fdtConflict:
      begin
        Result.RecommendedAction := saAskUser;
        Result.Confidence := 0.3;
        Result.Explanation := '检测到冲突，需要用户手动处理：' + ADiff.Reason;
      end;
  end;
  
  // 根据文件大小和时间差调整置信度
  Result.Confidence := CalculateConfidence(ADiff, Result.RecommendedAction);
end;

function TFileSyncComparer.CalculateConfidence(const ADiff: TFileDiff; const AAction: TSyncAction): Double;
var
  BaseConfidence: Double;
  TimeDiffHours: Double;
  SizeRatio: Double;
begin
  BaseConfidence := 0.5;
  
  case AAction of
    saSkip, saCopyToTarget:
      BaseConfidence := 1.0;
    saUpdateTarget, saUpdateSource:
      BaseConfidence := 0.9;
    saDeleteFromTarget, saDeleteFromSource:
      BaseConfidence := 0.6;
    saAskUser:
      BaseConfidence := 0.3;
  end;
  
  // 根据时间差调整置信度
  TimeDiffHours := Abs(ADiff.TimeDifference.TotalHours);
  if TimeDiffHours > 24 then
    BaseConfidence := BaseConfidence + 0.1 // 时间差大，置信度略高
  else if TimeDiffHours < 0.01 then
    BaseConfidence := BaseConfidence - 0.2; // 时间差很小，可能是同步冲突
  
  // 根据大小差异调整
  if (ADiff.SourceSize > 0) and (ADiff.TargetSize > 0) then
  begin
    SizeRatio := Min(ADiff.SourceSize, ADiff.TargetSize) / Max(ADiff.SourceSize, ADiff.TargetSize);
    if SizeRatio < 0.5 then
      BaseConfidence := BaseConfidence - 0.1; // 大小差异很大，降低置信度
  end;
  
  Result := Max(0.0, Min(1.0, BaseConfidence));
end;

function TFileSyncComparer.CompareDirectories(const ASourcePath, ATargetPath: string; 
  const AFilterRules: string = ''; const AProgressCallback: TProc<Integer, string> = nil): TArray<TFileDiff>;
var
  SourceFiles, TargetFiles: TArray<TFileInfo>;
  SourceDict, TargetDict: TDictionary<string, TFileInfo>;
  DiffList: TList<TFileDiff>;
  SourceInfo, TargetInfo: TFileInfo;
  RelativePath: string;
  Diff: TFileDiff;
begin
  // 扫描目录
  if Assigned(AProgressCallback) then
    AProgressCallback(10, '扫描源目录...');
  
  SourceFiles := TDirectory.GetFiles(ASourcePath, '*.*', TSearchOption.soAllDirectories)
    .Select(function(const Path: string): TFileInfo
      begin
        Result := TFileInfo.Create(Path);
      end).ToArray;
  
  if Assigned(AProgressCallback) then
    AProgressCallback(30, '扫描目标目录...');
  
  TargetFiles := TDirectory.GetFiles(ATargetPath, '*.*', TSearchOption.soAllDirectories)
    .Select(function(const Path: string): TFileInfo
      begin
        Result := TFileInfo.Create(Path);
      end).ToArray;
  
  if Assigned(AProgressCallback) then
    AProgressCallback(50, '比较文件...');
  
  Result := CompareFileLists(SourceFiles, TargetFiles, ASourcePath);
  
  if Assigned(AProgressCallback) then
    AProgressCallback(100, '比较完成');
end;

function TFileSyncComparer.CompareFileLists(const ASourceFiles, ATargetFiles: TArray<TFileInfo>; 
  const ABasePath: string): TArray<TFileDiff>;
var
  SourceDict, TargetDict: TDictionary<string, TFileInfo>;
  DiffList: TList<TFileDiff>;
  SourceInfo, TargetInfo: TFileInfo;
  RelativePath: string;
  Diff: TFileDiff;
begin
  SourceDict := TDictionary<string, TFileInfo>.Create;
  TargetDict := TDictionary<string, TFileInfo>.Create;
  DiffList := TList<TFileDiff>.Create;
  
  try
    // 构建源文件字典
    for SourceInfo in ASourceFiles do
    begin
      RelativePath := SourceInfo.FullName.Substring(Length(ABasePath));
      if RelativePath.StartsWith('\') then
        RelativePath := RelativePath.Substring(1);
      SourceDict.AddOrSetValue(RelativePath, SourceInfo);
    end;
    
    // 构建目标文件字典
    for TargetInfo in ATargetFiles do
    begin
      RelativePath := TargetInfo.FullName.Substring(Length(ABasePath));
      if RelativePath.StartsWith('\') then
        RelativePath := RelativePath.Substring(1);
      TargetDict.AddOrSetValue(RelativePath, TargetInfo);
    end;
    
    // 比较源文件
    for RelativePath in SourceDict.Keys do
    begin
      SourceInfo := SourceDict[RelativePath];
      
      if TargetDict.TryGetValue(RelativePath, TargetInfo) then
      begin
        // 文件在两边都存在
        Diff := AnalyzeFileDiff(SourceInfo, TargetInfo, RelativePath);
        DiffList.Add(Diff);
      end
      else
      begin
        // 文件只在源目录存在
        Diff.RelativePath := RelativePath;
        Diff.SourceFullPath := SourceInfo.FullName;
        Diff.TargetFullPath := '';
        Diff.DiffType := fdtSourceOnly;
        Diff.SourceSize := SourceInfo.Size;
        Diff.TargetSize := 0;
        Diff.SourceModified := SourceInfo.LastWriteTime;
        Diff.TargetModified := 0;
        Diff.Reason := '仅存在于源目录';
        DiffList.Add(Diff);
      end;
    end;
    
    // 检查目标目录中多余的文件
    for RelativePath in TargetDict.Keys do
    begin
      if not SourceDict.ContainsKey(RelativePath) then
      begin
        TargetInfo := TargetDict[RelativePath];
        Diff.RelativePath := RelativePath;
        Diff.SourceFullPath := '';
        Diff.TargetFullPath := TargetInfo.FullName;
        Diff.DiffType := fdtTargetOnly;
        Diff.SourceSize := 0;
        Diff.TargetSize := TargetInfo.Size;
        Diff.SourceModified := 0;
        Diff.TargetModified := TargetInfo.LastWriteTime;
        Diff.Reason := '仅存在于目标目录';
        DiffList.Add(Diff);
      end;
    end;
    
    Result := DiffList.ToArray;
  finally
    SourceDict.Free;
    TargetDict.Free;
    DiffList.Free;
  end;
end;

function TFileSyncComparer.GenerateSyncRecommendations(const ADiffs: TArray<TFileDiff>): TArray<TSyncRecommendation>;
var
  I: Integer;
  RecList: TList<TSyncRecommendation>;
begin
  RecList := TList<TSyncRecommendation>.Create;
  try
    for I := 0 to High(ADiffs) do
    begin
      RecList.Add(RecommendSyncAction(ADiffs[I]));
    end;
    Result := RecList.ToArray;
  finally
    RecList.Free;
  end;
end;

function TFileSyncComparer.ScanForChanges(const ASourcePath, ATargetPath: string; 
  const ALastSyncTime: TDateTime): TArray<TFileDiff>;
var
  AllDiffs: TArray<TFileDiff>;
  ChangedList: TList<TFileDiff>;
  Diff: TFileDiff;
begin
  // 获取所有差异
  AllDiffs := CompareDirectories(ASourcePath, ATargetPath);
  
  // 筛选出有变化的文件
  ChangedList := TList<TFileDiff>.Create;
  try
    for Diff in AllDiffs do
    begin
      // 检查是否有文件在最后同步时间之后被修改
      if (Diff.DiffType <> fdtIdentical) and
         ((Diff.SourceModified > ALastSyncTime) or (Diff.TargetModified > ALastSyncTime)) then
      begin
        ChangedList.Add(Diff);
      end;
    end;
    
    Result := ChangedList.ToArray;
  finally
    ChangedList.Free;
  end;
end;

function TFileSyncComparer.GetComparisonStatistics(const ADiffs: TArray<TFileDiff>): TDictionary<string, Integer>;
var
  Diff: TFileDiff;
begin
  Result := TDictionary<string, Integer>.Create;
  
  // 初始化统计
  Result.AddOrSetValue('Total', Length(ADiffs));
  Result.AddOrSetValue('Identical', 0);
  Result.AddOrSetValue('SourceNewer', 0);
  Result.AddOrSetValue('TargetNewer', 0);
  Result.AddOrSetValue('SourceOnly', 0);
  Result.AddOrSetValue('TargetOnly', 0);
  Result.AddOrSetValue('Conflict', 0);
  
  // 统计各类差异
  for Diff in ADiffs do
  begin
    case Diff.DiffType of
      fdtIdentical:
        Result[Diff.DiffType.ToString] := Result[Diff.DiffType.ToString] + 1;
      fdtSourceNewer:
        Result[Diff.DiffType.ToString] := Result[Diff.DiffType.ToString] + 1;
      fdtTargetNewer:
        Result[Diff.DiffType.ToString] := Result[Diff.DiffType.ToString] + 1;
      fdtSourceOnly:
        Result[Diff.DiffType.ToString] := Result[Diff.DiffType.ToString] + 1;
      fdtTargetOnly:
        Result[Diff.DiffType.ToString] := Result[Diff.DiffType.ToString] + 1;
      fdtConflict:
        Result[Diff.DiffType.ToString] := Result[Diff.DiffType.ToString] + 1;
    end;
  end;
end;

procedure TFileSyncComparer.ClearHashCache;
begin
  FCacheLock.Enter;
  try
    FHashCache.Clear;
  finally
    FCacheLock.Leave;
  end;
end;

end.

unit uFileSyncComparerSimple;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  uFileHasher, uSyncDatabase;

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
    TimeDifference: Double; // 以毫秒为单位
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
    
    function CalculateFileHash(const AFilePath: string): string;
    function CompareFileTimes(const ASourceTime, ATargetTime: TDateTime): TFileDiffType;
    function CompareFileSizes(const ASourceSize, ATargetSize: Int64): TFileDiffType;
    function GetFileModifiedTime(const AFilePath: string): TDateTime;
    function GetFileSize(const AFilePath: string): Int64;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 主要比较功能
    function CompareDirectories(const ASourcePath, ATargetPath: string): TArray<TFileDiff>;
    function CompareFiles(const ASourceFile, ATargetFile: string): TFileDiff;
    
    // 生成同步建议
    function GenerateRecommendations(const ADiffs: TArray<TFileDiff>): TArray<TSyncRecommendation>;
    
    // 属性
    property MaxConcurrency: Integer read FMaxConcurrency write FMaxConcurrency;
  end;

implementation

constructor TFileSyncComparer.Create;
begin
  inherited Create;
  FFileHasher := TFileHasher.Create;
  FHashCache := TDictionary<string, string>.Create;
  FMaxConcurrency := 4; // 默认并发数
end;

destructor TFileSyncComparer.Destroy;
begin
  FHashCache.Free;
  FFileHasher.Free;
  inherited Destroy;
end;

function TFileSyncComparer.CalculateFileHash(const AFilePath: string): string;
begin
  // 使用缓存提高性能
  if FHashCache.TryGetValue(AFilePath, Result) then
    Exit;
    
  try
    if TFile.Exists(AFilePath) then
      Result := FFileHasher.ComputeSHA256(AFilePath)
    else
      Result := '';
      
    FHashCache.AddOrSetValue(AFilePath, Result);
  except
    Result := '';
  end;
end;

function TFileSyncComparer.GetFileModifiedTime(const AFilePath: string): TDateTime;
begin
  try
    if TFile.Exists(AFilePath) then
      Result := TFile.GetLastWriteTime(AFilePath)
    else
      Result := 0;
  except
    Result := 0;
  end;
end;

function TFileSyncComparer.GetFileSize(const AFilePath: string): Int64;
begin
  try
    if TFile.Exists(AFilePath) then
      Result := TFile.GetSize(AFilePath)
    else
      Result := -1;
  except
    Result := -1;
  end;
end;

function TFileSyncComparer.CompareFileTimes(const ASourceTime, ATargetTime: TDateTime): TFileDiffType;
var
  TimeDiff: Double;
begin
  Result := fdtIdentical;
  
  if (ASourceTime = 0) and (ATargetTime = 0) then
    Exit;
    
  if ASourceTime = 0 then
  begin
    Result := fdtTargetOnly;
    Exit;
  end;
  
  if ATargetTime = 0 then
  begin
    Result := fdtSourceOnly;
    Exit;
  end;
  
  // 计算时间差（毫秒）
  TimeDiff := (ASourceTime - ATargetTime) * 24 * 60 * 60 * 1000;
  
  if Abs(TimeDiff) < 1000 then // 1秒内认为是相同的
    Result := fdtIdentical
  else if TimeDiff > 0 then
    Result := fdtSourceNewer
  else
    Result := fdtTargetNewer;
end;

function TFileSyncComparer.CompareFileSizes(const ASourceSize, ATargetSize: Int64): TFileDiffType;
begin
  Result := fdtIdentical;
  
  if (ASourceSize = -1) and (ATargetSize = -1) then
    Exit;
    
  if ASourceSize = -1 then
  begin
    Result := fdtTargetOnly;
    Exit;
  end;
  
  if ATargetSize = -1 then
  begin
    Result := fdtSourceOnly;
    Exit;
  end;
  
  if ASourceSize <> ATargetSize then
    Result := fdtConflict;
end;

function TFileSyncComparer.CompareFiles(const ASourceFile, ATargetFile: string): TFileDiff;
var
  SourceTime, TargetTime: TDateTime;
  SourceSize, TargetSize: Int64;
  SourceHash, TargetHash: string;
  TimeDiff: TFileDiffType;
  SizeDiff: TFileDiffType;
begin
  Result.RelativePath := ExtractFileName(ASourceFile);
  Result.SourceFullPath := ASourceFile;
  Result.TargetFullPath := ATargetFile;
  
  // 获取文件信息
  SourceTime := GetFileModifiedTime(ASourceFile);
  TargetTime := GetFileModifiedTime(ATargetFile);
  SourceSize := GetFileSize(ASourceFile);
  TargetSize := GetFileSize(ATargetFile);
  
  Result.SourceModified := SourceTime;
  Result.TargetModified := TargetTime;
  Result.SourceSize := SourceSize;
  Result.TargetSize := TargetSize;
  Result.SizeDifference := SourceSize - TargetSize;
  Result.TimeDifference := (SourceTime - TargetTime) * 24 * 60 * 60 * 1000;
  
  // 比较文件
  TimeDiff := CompareFileTimes(SourceTime, TargetTime);
  SizeDiff := CompareFileSizes(SourceSize, TargetSize);
  
  // 如果文件不存在
  if TimeDiff = fdtSourceOnly then
  begin
    Result.DiffType := fdtSourceOnly;
    Result.Reason := '文件仅存在于源目录';
    Exit;
  end;
  
  if TimeDiff = fdtTargetOnly then
  begin
    Result.DiffType := fdtTargetOnly;
    Result.Reason := '文件仅存在于目标目录';
    Exit;
  end;
  
  // 比较文件大小
  if SizeDiff = fdtConflict then
  begin
    Result.DiffType := fdtConflict;
    Result.Reason := '文件大小不同';
    Exit;
  end;
  
  // 如果大小相同，比较时间
  if TimeDiff <> fdtIdentical then
  begin
    Result.DiffType := TimeDiff;
    if TimeDiff = fdtSourceNewer then
      Result.Reason := '源文件更新'
    else
      Result.Reason := '目标文件更新';
    Exit;
  end;
  
  // 如果时间和大小都相同，计算哈希值进行最终确认
  SourceHash := CalculateFileHash(ASourceFile);
  TargetHash := CalculateFileHash(ATargetFile);
  
  Result.SourceHash := SourceHash;
  Result.TargetHash := TargetHash;
  
  if (SourceHash <> '') and (TargetHash <> '') and (SourceHash <> TargetHash) then
  begin
    Result.DiffType := fdtConflict;
    Result.Reason := '文件内容不同（哈希值不匹配）';
  end
  else
  begin
    Result.DiffType := fdtIdentical;
    Result.Reason := '文件完全相同';
  end;
end;

function TFileSyncComparer.CompareDirectories(const ASourcePath, ATargetPath: string): TArray<TFileDiff>;
var
  SourceFiles, TargetFiles: TArray<string>;
  SourceDict, TargetDict: TDictionary<string, string>;
  AllFiles: TStringList;
  Diff: TFileDiff;
  Diffs: TList<TFileDiff>;
  RelativePath: string;
  I: Integer;
begin
  Diffs := TList<TFileDiff>.Create;
  try
    // 获取文件列表
    SourceFiles := TDirectory.GetFiles(ASourcePath, '*', TSearchOption.soAllDirectories);
    TargetFiles := TDirectory.GetFiles(ATargetPath, '*', TSearchOption.soAllDirectories);
    
    // 创建字典以便快速查找
    SourceDict := TDictionary<string, string>.Create;
    TargetDict := TDictionary<string, string>.Create;
    
    try
      // 填充源文件字典
      for I := 0 to High(SourceFiles) do
      begin
        RelativePath := SourceFiles[I].Substring(Length(ASourcePath));
        if RelativePath.StartsWith('\') then
          RelativePath := RelativePath.Substring(1);
        SourceDict.AddOrSetValue(RelativePath, SourceFiles[I]);
      end;
      
      // 填充目标文件字典
      for I := 0 to High(TargetFiles) do
      begin
        RelativePath := TargetFiles[I].Substring(Length(ATargetPath));
        if RelativePath.StartsWith('\') then
          RelativePath := RelativePath.Substring(1);
        TargetDict.AddOrSetValue(RelativePath, TargetFiles[I]);
      end;
      
      // 获取所有文件路径
      AllFiles := TStringList.Create;
      try
        // 添加源文件
        for RelativePath in SourceDict.Keys do
          if AllFiles.IndexOf(RelativePath) = -1 then
            AllFiles.Add(RelativePath);
            
        // 添加目标文件
        for RelativePath in TargetDict.Keys do
          if AllFiles.IndexOf(RelativePath) = -1 then
            AllFiles.Add(RelativePath);
        
        // 比较每个文件
        for I := 0 to AllFiles.Count - 1 do
        begin
          RelativePath := AllFiles[I];
          
          var SourceFile: string;
          var TargetFile: string;
          
          SourceDict.TryGetValue(RelativePath, SourceFile);
          TargetDict.TryGetValue(RelativePath, TargetFile);
          
          if (SourceFile = '') then SourceFile := 'nonexistent';
          if (TargetFile = '') then TargetFile := 'nonexistent';
          
          Diff := CompareFiles(SourceFile, TargetFile);
          Diff.RelativePath := RelativePath;
          
          if Diff.DiffType <> fdtIdentical then
            Diffs.Add(Diff);
        end;
        
      finally
        AllFiles.Free;
      end;
      
    finally
      SourceDict.Free;
      TargetDict.Free;
    end;
    
    Result := Diffs.ToArray;
  finally
    Diffs.Free;
  end;
end;

function TFileSyncComparer.GenerateRecommendations(const ADiffs: TArray<TFileDiff>): TArray<TSyncRecommendation>;
var
  Recommendations: TList<TSyncRecommendation>;
  Rec: TSyncRecommendation;
  Diff: TFileDiff;
begin
  Recommendations := TList<TSyncRecommendation>.Create;
  try
    for Diff in ADiffs do
    begin
      Rec.Diff := Diff;
      Rec.Confidence := 1.0;
      
      case Diff.DiffType of
        fdtSourceOnly:
          begin
            Rec.RecommendedAction := saCopyToTarget;
            Rec.Explanation := '复制新文件到目标目录';
          end;
          
        fdtTargetOnly:
          begin
            Rec.RecommendedAction := saSkip; // 或者 saDeleteFromTarget
            Rec.Explanation := '目标目录中存在源目录没有的文件';
          end;
          
        fdtSourceNewer:
          begin
            Rec.RecommendedAction := saUpdateTarget;
            Rec.Explanation := '源文件较新，更新目标文件';
          end;
          
        fdtTargetNewer:
          begin
            Rec.RecommendedAction := saSkip; // 或者 saUpdateSource
            Rec.Explanation := '目标文件较新，跳过同步';
          end;
          
        fdtConflict:
          begin
            Rec.RecommendedAction := saAskUser;
            Rec.Confidence := 0.5;
            Rec.Explanation := '文件冲突，需要用户决定';
          end;
          
        fdtIdentical:
          begin
            Rec.RecommendedAction := saSkip;
            Rec.Explanation := '文件相同，无需操作';
          end;
      end;
      
      Recommendations.Add(Rec);
    end;
    
    Result := Recommendations.ToArray;
  finally
    Recommendations.Free;
  end;
end;

end.

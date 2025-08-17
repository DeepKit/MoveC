unit SmartFileEvaluator;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.StrUtils, System.DateUtils,
  System.Generics.Collections, System.Math, System.RegularExpressions,
  Winapi.Windows, DataTypes;

type
  // 文件重要性评分结果
  TFileImportanceScore = record
    FilePath: string;
    TotalScore: Double;        // 总分 (0-100，越低越重要，越应该保留)
    PathScore: Double;         // 路径重要性分数
    TimeScore: Double;         // 时间相关分数
    NameScore: Double;         // 文件名分数
    UsageScore: Double;        // 使用频率分数
    ConfidenceLevel: Double;   // 决策信心度 (0-100)
    RecommendDelete: Boolean;  // 是否推荐删除
    Reason: string;           // 决策理由
  end;

  // 智能决策模式
  TDecisionMode = (dmConservative, dmStandard, dmAggressive);

  // 路径重要性配置
  TPathImportanceConfig = record
    ProtectedPaths: TArray<string>;      // 受保护路径 (绝不删除)
    ImportantPaths: TArray<string>;      // 重要路径 (优先保留)
    TempPaths: TArray<string>;           // 临时路径 (优先删除)
    DownloadPaths: TArray<string>;       // 下载路径 (可删除)
  end;

  // 用户习惯学习数据
  TUserHabits = record
    FrequentPaths: TDictionary<string, Integer>;     // 常用路径及使用频率
    PreferredFileTypes: TDictionary<string, Double>; // 偏好文件类型
    DeletionHistory: TList<string>;                  // 删除历史
    LastUpdateTime: TDateTime;                       // 最后更新时间
  end;

  // 智能文件评估器
  TSmartFileEvaluator = class
  private
    FDecisionMode: TDecisionMode;
    FPathConfig: TPathImportanceConfig;
    FUserHabits: TUserHabits;
    FConfidenceThreshold: Double;  // 自动删除的信心阈值
    
    // 评分算法
    function CalculatePathScore(const FilePath: string): Double;
    function CalculateTimeScore(const FilePath: string): Double;
    function CalculateNameScore(const FilePath: string): Double;
    function CalculateUsageScore(const FilePath: string): Double;
    function CalculateConfidenceLevel(const Score: TFileImportanceScore): Double;
    
    // 路径分析
    function GetPathImportanceLevel(const FilePath: string): Integer;
    function IsProtectedPath(const FilePath: string): Boolean;
    function IsTemporaryPath(const FilePath: string): Boolean;
    function IsDownloadPath(const FilePath: string): Boolean;
    function IsUserDocumentPath(const FilePath: string): Boolean;
    function IsProgramPath(const FilePath: string): Boolean;
    
    // 文件名分析
    function HasCopyIndicators(const FileName: string): Boolean;
    function HasBackupIndicators(const FileName: string): Boolean;
    function HasTempIndicators(const FileName: string): Boolean;
    function HasVersionIndicators(const FileName: string): Boolean;
    
    // 时间分析
    function GetFileAge(const FilePath: string): Integer; // 天数
    function GetLastAccessAge(const FilePath: string): Integer;
    
    // 用户习惯分析
    procedure UpdateUserHabits(const FilePath: string; Action: string);
    function GetPathUsageFrequency(const FilePath: string): Integer;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 主要评估方法
    function EvaluateFile(const FilePath: string): TFileImportanceScore;
    function EvaluateFileGroup(const FilePaths: TArray<string>): TArray<TFileImportanceScore>;
    function GetRecommendedKeepFile(const FilePaths: TArray<string>): string;
    
    // 批量智能决策
    function MakeAutomaticDecisions(const DuplicateGroups: TArray<TArray<string>>): TArray<TArray<Boolean>>;
    function GetDeletionConfidence(const FilePath: string): Double;
    
    // 配置和学习
    procedure SetDecisionMode(Mode: TDecisionMode);
    procedure LoadUserHabits(const ConfigPath: string);
    procedure SaveUserHabits(const ConfigPath: string);
    procedure LearnFromUserAction(const FilePath: string; WasDeleted: Boolean);
    
    // 安全检查
    function IsSafeToDelete(const FilePath: string): Boolean;
    function GetDeletionRisk(const FilePath: string): string;
    
    property DecisionMode: TDecisionMode read FDecisionMode write SetDecisionMode;
    property ConfidenceThreshold: Double read FConfidenceThreshold write FConfidenceThreshold;
  end;

  // 辅助函数
  function GetDefaultPathConfig: TPathImportanceConfig;
  function ScoreToPercentage(Score: Double): Integer;

implementation

uses
  System.JSON, System.Variants;

{ TSmartFileEvaluator }

constructor TSmartFileEvaluator.Create;
begin
  inherited Create;
  FDecisionMode := dmStandard;
  FConfidenceThreshold := 80.0; // 80%信心度以上才自动删除
  FPathConfig := GetDefaultPathConfig;
  
  // 初始化用户习惯数据
  FUserHabits.FrequentPaths := TDictionary<string, Integer>.Create;
  FUserHabits.PreferredFileTypes := TDictionary<string, Double>.Create;
  FUserHabits.DeletionHistory := TList<string>.Create;
  FUserHabits.LastUpdateTime := Now;
end;

destructor TSmartFileEvaluator.Destroy;
begin
  FUserHabits.FrequentPaths.Free;
  FUserHabits.PreferredFileTypes.Free;
  FUserHabits.DeletionHistory.Free;
  inherited Destroy;
end;

function TSmartFileEvaluator.EvaluateFile(const FilePath: string): TFileImportanceScore;
begin
  Result.FilePath := FilePath;
  
  // 计算各项分数 (分数越低越重要)
  Result.PathScore := CalculatePathScore(FilePath);
  Result.TimeScore := CalculateTimeScore(FilePath);
  Result.NameScore := CalculateNameScore(FilePath);
  Result.UsageScore := CalculateUsageScore(FilePath);
  
  // 计算总分 (加权平均)
  Result.TotalScore := (Result.PathScore * 0.4) +      // 路径权重40%
                      (Result.TimeScore * 0.2) +       // 时间权重20%
                      (Result.NameScore * 0.3) +       // 文件名权重30%
                      (Result.UsageScore * 0.1);       // 使用频率权重10%
  
  // 计算信心度
  Result.ConfidenceLevel := CalculateConfidenceLevel(Result);
  
  // 决定是否推荐删除
  case FDecisionMode of
    dmConservative: Result.RecommendDelete := (Result.TotalScore > 70) and (Result.ConfidenceLevel > 90);
    dmStandard:     Result.RecommendDelete := (Result.TotalScore > 60) and (Result.ConfidenceLevel > 80);
    dmAggressive:   Result.RecommendDelete := (Result.TotalScore > 50) and (Result.ConfidenceLevel > 70);
  end;
  
  // 生成决策理由
  if Result.RecommendDelete then
  begin
    if Result.NameScore > 80 then
      Result.Reason := '文件名表明这是副本或备份文件'
    else if Result.PathScore > 80 then
      Result.Reason := '位于临时或下载目录'
    else if Result.TimeScore > 80 then
      Result.Reason := '文件较旧且长时间未使用'
    else
      Result.Reason := '综合评估建议删除';
  end
  else
  begin
    if Result.PathScore < 30 then
      Result.Reason := '位于重要系统或程序目录'
    else if Result.TimeScore < 30 then
      Result.Reason := '最近修改或访问的文件'
    else if Result.NameScore < 30 then
      Result.Reason := '原始文件名，非副本'
    else
      Result.Reason := '综合评估建议保留';
  end;
end;

function TSmartFileEvaluator.CalculatePathScore(const FilePath: string): Double;
var
  LowerPath: string;
  PathLevel: Integer;
begin
  LowerPath := LowerCase(FilePath);
  PathLevel := GetPathImportanceLevel(FilePath);
  
  case PathLevel of
    0: Result := 0;    // 受保护路径，绝不删除
    1: Result := 10;   // 程序目录，很重要
    2: Result := 20;   // 用户文档，重要
    3: Result := 40;   // 普通用户目录
    4: Result := 70;   // 下载目录，可删除
    5: Result := 90;   // 临时目录，优先删除
    else Result := 50; // 未知路径，中等重要性
  end;
  
  // 根据路径深度调整 (路径越深，重要性可能越低)
  var PathDepth := Length(FilePath.Split(['\']));
  if PathDepth > 6 then
    Result := Result + Min(10, (PathDepth - 6) * 2);
end;

function TSmartFileEvaluator.CalculateTimeScore(const FilePath: string): Double;
var
  FileAge, AccessAge: Integer;
begin
  FileAge := GetFileAge(FilePath);
  AccessAge := GetLastAccessAge(FilePath);
  
  // 文件年龄评分
  if FileAge < 7 then
    Result := 0      // 一周内的文件，很重要
  else if FileAge < 30 then
    Result := 20     // 一月内的文件，重要
  else if FileAge < 90 then
    Result := 40     // 三月内的文件，一般
  else if FileAge < 365 then
    Result := 60     // 一年内的文件，可删除
  else
    Result := 80;    // 超过一年的文件，优先删除
    
  // 访问时间调整
  if AccessAge > 180 then // 超过半年未访问
    Result := Result + 15
  else if AccessAge > 30 then // 超过一月未访问
    Result := Result + 5;
    
  Result := Min(100, Result);
end;

function TSmartFileEvaluator.CalculateNameScore(const FilePath: string): Double;
var
  FileName: string;
begin
  FileName := LowerCase(ExtractFileName(FilePath));
  Result := 30; // 基础分数
  
  // 检查副本指示符
  if HasCopyIndicators(FileName) then
    Result := Result + 40;
    
  // 检查备份指示符
  if HasBackupIndicators(FileName) then
    Result := Result + 35;
    
  // 检查临时文件指示符
  if HasTempIndicators(FileName) then
    Result := Result + 50;
    
  // 检查版本指示符
  if HasVersionIndicators(FileName) then
    Result := Result + 20;
    
  // 检查特殊字符 (通常表示自动生成的文件)
  if ContainsText(FileName, '~') or ContainsText(FileName, '$') then
    Result := Result + 25;
    
  Result := Min(100, Result);
end;

function TSmartFileEvaluator.CalculateUsageScore(const FilePath: string): Double;
var
  UsageFreq: Integer;
  DirPath: string;
begin
  DirPath := ExtractFileDir(FilePath);
  UsageFreq := GetPathUsageFrequency(DirPath);
  
  // 使用频率越高，删除分数越低
  if UsageFreq > 100 then
    Result := 10
  else if UsageFreq > 50 then
    Result := 20
  else if UsageFreq > 10 then
    Result := 40
  else if UsageFreq > 0 then
    Result := 60
  else
    Result := 80; // 从未使用过的路径
end;

function TSmartFileEvaluator.GetRecommendedKeepFile(const FilePaths: TArray<string>): string;
var
  BestScore: Double;
  BestFile: string;
  Score: TFileImportanceScore;
begin
  BestScore := 1000; // 初始化为很大的值
  BestFile := '';
  
  for var FilePath in FilePaths do
  begin
    Score := EvaluateFile(FilePath);
    if Score.TotalScore < BestScore then
    begin
      BestScore := Score.TotalScore;
      BestFile := FilePath;
    end;
  end;
  
  Result := BestFile;
end;

function TSmartFileEvaluator.MakeAutomaticDecisions(const DuplicateGroups: TArray<TArray<string>>): TArray<TArray<Boolean>>;
var
  i, j: Integer;
  KeepFile: string;
  Decisions: TArray<TArray<Boolean>>;
begin
  SetLength(Decisions, Length(DuplicateGroups));
  
  for i := 0 to Length(DuplicateGroups) - 1 do
  begin
    SetLength(Decisions[i], Length(DuplicateGroups[i]));
    
    // 找到应该保留的文件
    KeepFile := GetRecommendedKeepFile(DuplicateGroups[i]);
    
    // 设置删除决策
    for j := 0 to Length(DuplicateGroups[i]) - 1 do
    begin
      if DuplicateGroups[i][j] = KeepFile then
        Decisions[i][j] := False  // 保留
      else
      begin
        var Score := EvaluateFile(DuplicateGroups[i][j]);
        Decisions[i][j] := Score.RecommendDelete and (Score.ConfidenceLevel >= FConfidenceThreshold);
      end;
    end;
  end;
  
  Result := Decisions;
end;

// 路径分析方法
function TSmartFileEvaluator.GetPathImportanceLevel(const FilePath: string): Integer;
begin
  if IsProtectedPath(FilePath) then
    Result := 0
  else if IsProgramPath(FilePath) then
    Result := 1
  else if IsUserDocumentPath(FilePath) then
    Result := 2
  else if IsDownloadPath(FilePath) then
    Result := 4
  else if IsTemporaryPath(FilePath) then
    Result := 5
  else
    Result := 3; // 普通路径
end;

function TSmartFileEvaluator.IsProtectedPath(const FilePath: string): Boolean;
begin
  Result := False;
  for var ProtectedPath in FPathConfig.ProtectedPaths do
  begin
    if StartsText(ProtectedPath, FilePath) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TSmartFileEvaluator.IsTemporaryPath(const FilePath: string): Boolean;
begin
  Result := False;
  for var TempPath in FPathConfig.TempPaths do
  begin
    if ContainsText(LowerCase(FilePath), LowerCase(TempPath)) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TSmartFileEvaluator.HasCopyIndicators(const FileName: string): Boolean;
var
  CopyPatterns: TArray<string>;
begin
  CopyPatterns := ['copy', '副本', 'duplicate', 'dup', '复制', '拷贝', ' - 副本', '(2)', '(3)', '(4)', '(5)'];
  
  Result := False;
  for var Pattern in CopyPatterns do
  begin
    if ContainsText(FileName, Pattern) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TSmartFileEvaluator.HasBackupIndicators(const FileName: string): Boolean;
var
  BackupPatterns: TArray<string>;
begin
  BackupPatterns := ['backup', 'bak', '备份', '.old', '.orig', '.bkp', '~'];
  
  Result := False;
  for var Pattern in BackupPatterns do
  begin
    if ContainsText(FileName, Pattern) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TSmartFileEvaluator.GetFileAge(const FilePath: string): Integer;
begin
  try
    Result := DaysBetween(Now, TFile.GetLastWriteTime(FilePath));
  except
    Result := 0;
  end;
end;

// 辅助函数
function GetDefaultPathConfig: TPathImportanceConfig;
begin
  // 受保护路径
  Result.ProtectedPaths := [
    'C:\Windows',
    'C:\Program Files',
    'C:\Program Files (x86)',
    'C:\ProgramData'
  ];
  
  // 重要路径
  Result.ImportantPaths := [
    'C:\Users\%USERNAME%\Documents',
    'C:\Users\%USERNAME%\Desktop',
    'C:\Users\%USERNAME%\Pictures'
  ];
  
  // 临时路径
  Result.TempPaths := [
    '\Temp\',
    '\tmp\',
    '\AppData\Local\Temp\',
    '\Windows\Temp\',
    '\Temporary Internet Files\'
  ];
  
  // 下载路径
  Result.DownloadPaths := [
    '\Downloads\',
    '\下载\',
    '\Download\'
  ];
end;

function TSmartFileEvaluator.HasTempIndicators(const FileName: string): Boolean;
var
  TempPatterns: TArray<string>;
begin
  TempPatterns := ['temp', 'tmp', '临时', '.temp', '.tmp', '~$'];

  Result := False;
  for var Pattern in TempPatterns do
  begin
    if ContainsText(FileName, Pattern) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TSmartFileEvaluator.HasVersionIndicators(const FileName: string): Boolean;
var
  VersionPattern: TRegEx;
begin
  // 匹配版本号模式，如 v1.0, ver2.1, 版本1等
  VersionPattern := TRegEx.Create('(v\d+\.?\d*|ver\d+\.?\d*|版本\d+|_v\d+|_\d+\.\d+)', [roIgnoreCase]);
  Result := VersionPattern.IsMatch(FileName);
end;

function TSmartFileEvaluator.GetLastAccessAge(const FilePath: string): Integer;
begin
  try
    Result := DaysBetween(Now, TFile.GetLastAccessTime(FilePath));
  except
    Result := 0;
  end;
end;

function TSmartFileEvaluator.IsDownloadPath(const FilePath: string): Boolean;
begin
  Result := False;
  for var DownloadPath in FPathConfig.DownloadPaths do
  begin
    if ContainsText(LowerCase(FilePath), LowerCase(DownloadPath)) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TSmartFileEvaluator.IsUserDocumentPath(const FilePath: string): Boolean;
var
  LowerPath: string;
begin
  LowerPath := LowerCase(FilePath);
  Result := ContainsText(LowerPath, '\documents\') or
            ContainsText(LowerPath, '\desktop\') or
            ContainsText(LowerPath, '\pictures\') or
            ContainsText(LowerPath, '\music\') or
            ContainsText(LowerPath, '\videos\') or
            ContainsText(LowerPath, '\文档\') or
            ContainsText(LowerPath, '\桌面\') or
            ContainsText(LowerPath, '\图片\') or
            ContainsText(LowerPath, '\音乐\') or
            ContainsText(LowerPath, '\视频\');
end;

function TSmartFileEvaluator.IsProgramPath(const FilePath: string): Boolean;
var
  LowerPath: string;
begin
  LowerPath := LowerCase(FilePath);
  Result := ContainsText(LowerPath, '\program files\') or
            ContainsText(LowerPath, '\program files (x86)\') or
            ContainsText(LowerPath, '\programdata\') or
            ContainsText(LowerPath, '\.exe') or
            ContainsText(LowerPath, '\.dll') or
            ContainsText(LowerPath, '\.sys');
end;

function TSmartFileEvaluator.GetPathUsageFrequency(const FilePath: string): Integer;
begin
  if FUserHabits.FrequentPaths.TryGetValue(LowerCase(FilePath), Result) then
    Exit
  else
    Result := 0;
end;

function TSmartFileEvaluator.CalculateConfidenceLevel(const Score: TFileImportanceScore): Double;
var
  Confidence: Double;
begin
  Confidence := 50; // 基础信心度

  // 路径信心度调整
  if Score.PathScore > 80 then
    Confidence := Confidence + 30  // 明显的临时路径
  else if Score.PathScore < 20 then
    Confidence := Confidence + 25; // 明显的重要路径

  // 文件名信心度调整
  if Score.NameScore > 80 then
    Confidence := Confidence + 25  // 明显的副本文件
  else if Score.NameScore < 20 then
    Confidence := Confidence + 20; // 明显的原始文件

  // 时间信心度调整
  if Score.TimeScore > 80 then
    Confidence := Confidence + 15  // 很旧的文件
  else if Score.TimeScore < 20 then
    Confidence := Confidence + 15; // 很新的文件

  Result := Min(100, Confidence);
end;

function TSmartFileEvaluator.EvaluateFileGroup(const FilePaths: TArray<string>): TArray<TFileImportanceScore>;
var
  i: Integer;
begin
  SetLength(Result, Length(FilePaths));
  for i := 0 to Length(FilePaths) - 1 do
    Result[i] := EvaluateFile(FilePaths[i]);
end;

function TSmartFileEvaluator.GetDeletionConfidence(const FilePath: string): Double;
var
  Score: TFileImportanceScore;
begin
  Score := EvaluateFile(FilePath);
  Result := Score.ConfidenceLevel;
end;

function TSmartFileEvaluator.IsSafeToDelete(const FilePath: string): Boolean;
var
  Score: TFileImportanceScore;
begin
  Score := EvaluateFile(FilePath);
  Result := Score.RecommendDelete and (Score.ConfidenceLevel >= FConfidenceThreshold);

  // 额外安全检查
  if Result then
  begin
    // 检查文件是否被占用
    try
      var TestFile := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyNone);
      TestFile.Free;
    except
      Result := False; // 文件被占用，不安全删除
    end;

    // 检查是否是受保护路径
    if IsProtectedPath(FilePath) then
      Result := False;
  end;
end;

function TSmartFileEvaluator.GetDeletionRisk(const FilePath: string): string;
var
  Score: TFileImportanceScore;
begin
  Score := EvaluateFile(FilePath);

  if Score.TotalScore < 30 then
    Result := '高风险：重要文件，不建议删除'
  else if Score.TotalScore < 50 then
    Result := '中风险：需要谨慎考虑'
  else if Score.TotalScore < 70 then
    Result := '低风险：可以考虑删除'
  else
    Result := '安全：建议删除';

  if Score.ConfidenceLevel < 70 then
    Result := Result + '（信心度较低）';
end;

procedure TSmartFileEvaluator.SetDecisionMode(Mode: TDecisionMode);
begin
  FDecisionMode := Mode;

  // 根据模式调整信心阈值
  case Mode of
    dmConservative: FConfidenceThreshold := 90;
    dmStandard:     FConfidenceThreshold := 80;
    dmAggressive:   FConfidenceThreshold := 70;
  end;
end;

procedure TSmartFileEvaluator.UpdateUserHabits(const FilePath: string; Action: string);
var
  DirPath: string;
  CurrentCount: Integer;
begin
  DirPath := LowerCase(ExtractFileDir(FilePath));

  // 更新路径使用频率
  if FUserHabits.FrequentPaths.TryGetValue(DirPath, CurrentCount) then
    FUserHabits.FrequentPaths[DirPath] := CurrentCount + 1
  else
    FUserHabits.FrequentPaths.Add(DirPath, 1);

  // 记录删除历史
  if SameText(Action, 'delete') then
    FUserHabits.DeletionHistory.Add(FilePath);

  FUserHabits.LastUpdateTime := Now;
end;

procedure TSmartFileEvaluator.LearnFromUserAction(const FilePath: string; WasDeleted: Boolean);
begin
  if WasDeleted then
    UpdateUserHabits(FilePath, 'delete')
  else
    UpdateUserHabits(FilePath, 'keep');
end;

procedure TSmartFileEvaluator.LoadUserHabits(const ConfigPath: string);
var
  JsonStr: string;
  JsonObj: TJSONObject;
  PathsArray: TJSONArray;
  i: Integer;
begin
  if not TFile.Exists(ConfigPath) then
    Exit;

  try
    JsonStr := TFile.ReadAllText(ConfigPath);
    JsonObj := TJSONObject.ParseJSONValue(JsonStr) as TJSONObject;
    try
      // 加载常用路径
      if JsonObj.TryGetValue('frequent_paths', PathsArray) then
      begin
        FUserHabits.FrequentPaths.Clear;
        for i := 0 to PathsArray.Count - 1 do
        begin
          var PathObj := PathsArray.Items[i] as TJSONObject;
          var Path := PathObj.GetValue('path').Value;
          var Count := StrToIntDef(PathObj.GetValue('count').Value, 0);
          FUserHabits.FrequentPaths.Add(Path, Count);
        end;
      end;

      // 可以继续加载其他用户习惯数据...

    finally
      JsonObj.Free;
    end;
  except
    // 忽略加载错误
  end;
end;

procedure TSmartFileEvaluator.SaveUserHabits(const ConfigPath: string);
var
  JsonObj: TJSONObject;
  PathsArray: TJSONArray;
  PathObj: TJSONObject;
begin
  try
    JsonObj := TJSONObject.Create;
    try
      // 保存常用路径
      PathsArray := TJSONArray.Create;
      for var Path in FUserHabits.FrequentPaths.Keys do
      begin
        PathObj := TJSONObject.Create;
        PathObj.AddPair('path', Path);
        PathObj.AddPair('count', TJSONNumber.Create(FUserHabits.FrequentPaths[Path]));
        PathsArray.AddElement(PathObj);
      end;
      JsonObj.AddPair('frequent_paths', PathsArray);

      JsonObj.AddPair('last_update', DateTimeToStr(FUserHabits.LastUpdateTime));

      TFile.WriteAllText(ConfigPath, JsonObj.ToString);
    finally
      JsonObj.Free;
    end;
  except
    // 忽略保存错误
  end;
end;

function ScoreToPercentage(Score: Double): Integer;
begin
  Result := Round(Score);
  if Result < 0 then Result := 0;
  if Result > 100 then Result := 100;
end;

end.

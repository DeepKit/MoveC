unit MigrationPlanner;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.StrUtils, System.Generics.Collections,
  Winapi.Windows, DataTypes, ConfigManager, DependencyAnalyzer, RebootDetector;

type
  // 迁移策略
  TMigrationStrategy = (msMove, msCopy, msSymlink, msSkip);
  
  // 迁移优先级
  TMigrationPriority = (mpLow, mpNormal, mpHigh, mpCritical);
  
  // 迁移风险级别
  TMigrationRisk = (mrLow, mrMedium, mrHigh, mrCritical);
  
  // 迁移项目信息
  TMigrationItem = record
    SourcePath: string;
    TargetPath: string;
    Strategy: TMigrationStrategy;
    Priority: TMigrationPriority;
    Risk: TMigrationRisk;
    Size: Int64;
    FileCount: Integer;
    EstimatedTime: Integer; // 预估时间（秒）
    Dependencies: TArray<string>;
    RequiresReboot: Boolean;
    RequiresBackup: Boolean;
    CanRollback: Boolean;
    Warnings: TArray<string>;
    Recommendations: TArray<string>;
    SafetyScore: Integer; // 0-100，安全分数
  end;
  
  // 迁移计划
  TMigrationPlan = record
    PlanId: string;
    CreatedTime: TDateTime;
    SourceDrive: string;
    TargetDrive: string;
    TotalSize: Int64;
    TotalFiles: Integer;
    EstimatedDuration: Integer; // 预估总时间（秒）
    Items: TArray<TMigrationItem>;
    TotalItems: Integer;
    HighRiskItems: Integer;
    CriticalItems: Integer;
    RequiresReboot: Boolean;
    SpaceRequired: Int64;
    SpaceAvailable: Int64;
    SpaceSufficient: Boolean;
    OverallRisk: TMigrationRisk;
    OverallSafety: Integer; // 0-100，总体安全分数
    Prerequisites: TArray<string>;
    PostActions: TArray<string>;
    RollbackPlan: TArray<string>;
  end;
  
  // 迁移计划生成器
  TMigrationPlanner = class
  private
    FConfigManager: TConfigManager;
    FSafetyEvaluator: TFileSafetyEvaluator;
    FDependencyAnalyzer: TDependencyAnalyzer;
    FRebootDetector: TRebootDetector;
    FExcludePaths: TStringList;
    FIncludePaths: TStringList;
    
    // 内部分析方法
    function AnalyzeDirectory(const ASourcePath, ATargetPath: string): TMigrationItem;
    function CalculateSize(const APath: string): Int64;
    function CountFiles(const APath: string): Integer;
    function EstimateTransferTime(ASize: Int64): Integer;
    function DetermineMigrationStrategy(const AItem: TMigrationItem): TMigrationStrategy;
    function CalculateRisk(const AItem: TMigrationItem): TMigrationRisk;
    function CalculatePriority(const AItem: TMigrationItem): TMigrationPriority;
    function CheckSpaceRequirements(const APlan: TMigrationPlan): Boolean;
    function GeneratePrerequisites(const APlan: TMigrationPlan): TArray<string>;
    function GeneratePostActions(const APlan: TMigrationPlan): TArray<string>;
    function GenerateRollbackPlan(const APlan: TMigrationPlan): TArray<string>;
    
    // 辅助方法
    procedure InitializeDefaultPaths;
    function IsExcludedPath(const APath: string): Boolean;
    function IsIncludedPath(const APath: string): Boolean;
    function GetMigrationStrategyString(AStrategy: TMigrationStrategy): string;
    function GetMigrationPriorityString(APriority: TMigrationPriority): string;
    function GetMigrationRiskString(ARisk: TMigrationRisk): string;
    function FormatSize(ASize: Int64): string;
    function FormatDuration(ASeconds: Integer): string;
    
  public
    constructor Create(AConfigManager: TConfigManager = nil);
    destructor Destroy; override;
    
    // 主要规划方法
    function CreateMigrationPlan(const ASourceDrive, ATargetDrive: string; 
      const APaths: TArray<string>): TMigrationPlan;
    function ValidateMigrationPlan(const APlan: TMigrationPlan): Boolean;
    function OptimizeMigrationPlan(var APlan: TMigrationPlan): Boolean;
    
    // 计划管理
    function SaveMigrationPlan(const APlan: TMigrationPlan; const AFileName: string): Boolean;
    function LoadMigrationPlan(const AFileName: string): TMigrationPlan;
    function ComparePlans(const APlan1, APlan2: TMigrationPlan): string;
    
    // 配置管理
    procedure AddExcludePath(const APath: string);
    procedure RemoveExcludePath(const APath: string);
    procedure AddIncludePath(const APath: string);
    procedure RemoveIncludePath(const APath: string);
    procedure ClearExcludePaths;
    procedure ClearIncludePaths;
    
    // 报告生成
    function GeneratePlanSummary(const APlan: TMigrationPlan): string;
    function GenerateDetailedReport(const APlan: TMigrationPlan): string;
    function GenerateRiskAssessment(const APlan: TMigrationPlan): string;
  end;

implementation

uses
  System.DateUtils, System.Math, System.JSON, Vcl.Forms;

constructor TMigrationPlanner.Create(AConfigManager: TConfigManager);
begin
  inherited Create;
  
  if Assigned(AConfigManager) then
    FConfigManager := AConfigManager
  else
    FConfigManager := TConfigManager.Create;
    
  FSafetyEvaluator := TFileSafetyEvaluator.Create(FConfigManager);
  FDependencyAnalyzer := TDependencyAnalyzer.Create(FConfigManager);
  FRebootDetector := TRebootDetector.Create(FConfigManager);
  
  FExcludePaths := TStringList.Create;
  FIncludePaths := TStringList.Create;
  
  InitializeDefaultPaths;
end;

destructor TMigrationPlanner.Destroy;
begin
  FSafetyEvaluator.Free;
  FDependencyAnalyzer.Free;
  FRebootDetector.Free;
  FExcludePaths.Free;
  FIncludePaths.Free;
  
  if Assigned(FConfigManager) then
    FConfigManager.Free;
    
  inherited;
end;// 初
始化默认路径
procedure TMigrationPlanner.InitializeDefaultPaths;
begin
  // 默认排除的系统关键路径
  FExcludePaths.Add('C:\Windows');
  FExcludePaths.Add('C:\Program Files');
  FExcludePaths.Add('C:\Program Files (x86)');
  FExcludePaths.Add('C:\ProgramData');
  FExcludePaths.Add('C:\System Volume Information');
  FExcludePaths.Add('C:\$Recycle.Bin');
  FExcludePaths.Add('C:\Recovery');
  FExcludePaths.Add('C:\Boot');
  FExcludePaths.Add('C:\bootmgr');
  FExcludePaths.Add('C:\pagefile.sys');
  FExcludePaths.Add('C:\hiberfil.sys');
  FExcludePaths.Add('C:\swapfile.sys');
  
  // 默认包含的用户数据路径
  FIncludePaths.Add('C:\Users');
  FIncludePaths.Add('C:\Temp');
  FIncludePaths.Add('C:\tmp');
end;

// 检查是否为排除路径
function TMigrationPlanner.IsExcludedPath(const APath: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  
  for I := 0 to FExcludePaths.Count - 1 do
  begin
    if StartsText(FExcludePaths[I], APath) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

// 检查是否为包含路径
function TMigrationPlanner.IsIncludedPath(const APath: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  
  for I := 0 to FIncludePaths.Count - 1 do
  begin
    if StartsText(FIncludePaths[I], APath) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

// 分析目录
function TMigrationPlanner.AnalyzeDirectory(const ASourcePath, ATargetPath: string): TMigrationItem;
var
  SafetyResult: TFileSafetyResult;
  DependencyResult: TDependencyAnalysisResult;
  RebootResult: TRebootDetectionResult;
begin
  Result.SourcePath := ASourcePath;
  Result.TargetPath := ATargetPath;
  Result.Strategy := msMove;
  Result.Priority := mpNormal;
  Result.Risk := mrMedium;
  Result.Size := 0;
  Result.FileCount := 0;
  Result.EstimatedTime := 0;
  SetLength(Result.Dependencies, 0);
  Result.RequiresReboot := False;
  Result.RequiresBackup := True;
  Result.CanRollback := True;
  SetLength(Result.Warnings, 0);
  SetLength(Result.Recommendations, 0);
  Result.SafetyScore := 50;
  
  if not DirectoryExists(ASourcePath) then
  begin
    SetLength(Result.Warnings, 1);
    Result.Warnings[0] := '源目录不存在';
    Result.Risk := mrCritical;
    Result.SafetyScore := 0;
    Exit;
  end;
  
  try
    // 计算大小和文件数
    Result.Size := CalculateSize(ASourcePath);
    Result.FileCount := CountFiles(ASourcePath);
    Result.EstimatedTime := EstimateTransferTime(Result.Size);
    
    // 安全评估
    SafetyResult := FSafetyEvaluator.EvaluateFile(ASourcePath);
    Result.SafetyScore := 100 - SafetyResult.RiskScore;
    
    // 依赖分析
    DependencyResult := FDependencyAnalyzer.AnalyzeFile(ASourcePath);
    if DependencyResult.TotalDependencies > 0 then
    begin
      SetLength(Result.Dependencies, DependencyResult.TotalDependencies);
      for var I := 0 to DependencyResult.TotalDependencies - 1 do
      begin
        Result.Dependencies[I] := DependencyResult.Dependencies[I].Description;
      end;
    end;
    
    // 重启检测
    RebootResult := FRebootDetector.DetectRebootRequirement(ASourcePath);
    Result.RequiresReboot := RebootResult.RequiresReboot;
    
    // 确定迁移策略
    Result.Strategy := DetermineMigrationStrategy(Result);
    
    // 计算风险和优先级
    Result.Risk := CalculateRisk(Result);
    Result.Priority := CalculatePriority(Result);
    
    // 生成警告和建议
    var Warnings := TList<string>.Create;
    var Recommendations := TList<string>.Create;
    
    try
      if Result.RequiresReboot then
        Warnings.Add('迁移后需要重启系统');
      
      if DependencyResult.CriticalDependencies > 0 then
        Warnings.Add('存在严重依赖关系');
      
      if Result.Size > 10 * 1024 * 1024 * 1024 then // 大于10GB
        Warnings.Add('目录较大，迁移时间较长');
      
      if SafetyResult.SafetyLevel = fslDangerous then
        Warnings.Add('安全评估为危险级别');
      
      if Result.Strategy = msSymlink then
        Recommendations.Add('建议使用符号链接方式迁移');
      
      if Result.RequiresBackup then
        Recommendations.Add('建议在迁移前创建备份');
      
      if DependencyResult.RequiresRegistryUpdate then
        Recommendations.Add('迁移后需要更新注册表');
      
      SetLength(Result.Warnings, Warnings.Count);
      for var I := 0 to Warnings.Count - 1 do
        Result.Warnings[I] := Warnings[I];
      
      SetLength(Result.Recommendations, Recommendations.Count);
      for var I := 0 to Recommendations.Count - 1 do
        Result.Recommendations[I] := Recommendations[I];
      
    finally
      Warnings.Free;
      Recommendations.Free;
    end;
    
  except
    on E: Exception do
    begin
      SetLength(Result.Warnings, 1);
      Result.Warnings[0] := '分析异常: ' + E.Message;
      Result.Risk := mrHigh;
      Result.SafetyScore := 20;
    end;
  end;
end;

// 计算目录大小
function TMigrationPlanner.CalculateSize(const APath: string): Int64;
var
  SearchRec: TSearchRec;
  FilePath: string;
begin
  Result := 0;
  
  try
    if FindFirst(TPath.Combine(APath, '*'), faAnyFile, SearchRec) = 0 then
    begin
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          FilePath := TPath.Combine(APath, SearchRec.Name);
          
          if (SearchRec.Attr and faDirectory) <> 0 then
          begin
            // 递归计算子目录大小
            Result := Result + CalculateSize(FilePath);
          end
          else
          begin
            // 累加文件大小
            Result := Result + SearchRec.Size;
          end;
        end;
      until FindNext(SearchRec) <> 0;
      
      FindClose(SearchRec);
    end;
  except
    // 忽略访问错误
  end;
end;

// 计算文件数量
function TMigrationPlanner.CountFiles(const APath: string): Integer;
var
  SearchRec: TSearchRec;
  FilePath: string;
begin
  Result := 0;
  
  try
    if FindFirst(TPath.Combine(APath, '*'), faAnyFile, SearchRec) = 0 then
    begin
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          FilePath := TPath.Combine(APath, SearchRec.Name);
          
          if (SearchRec.Attr and faDirectory) <> 0 then
          begin
            // 递归计算子目录文件数
            Result := Result + CountFiles(FilePath);
          end
          else
          begin
            // 累加文件数
            Inc(Result);
          end;
        end;
      until FindNext(SearchRec) <> 0;
      
      FindClose(SearchRec);
    end;
  except
    // 忽略访问错误
  end;
end;

// 估算传输时间
function TMigrationPlanner.EstimateTransferTime(ASize: Int64): Integer;
const
  // 假设传输速度为100MB/s
  TRANSFER_SPEED = 100 * 1024 * 1024;
begin
  if ASize <= 0 then
    Result := 0
  else
    Result := Max(1, ASize div TRANSFER_SPEED);
end;

// 确定迁移策略
function TMigrationPlanner.DetermineMigrationStrategy(const AItem: TMigrationItem): TMigrationStrategy;
begin
  Result := msMove; // 默认移动
  
  // 根据安全分数和依赖情况确定策略
  if AItem.SafetyScore < 30 then
    Result := msSkip // 安全分数太低，跳过
  else if Length(AItem.Dependencies) > 5 then
    Result := msSymlink // 依赖太多，使用符号链接
  else if AItem.Size > 50 * 1024 * 1024 * 1024 then // 大于50GB
    Result := msSymlink // 文件太大，使用符号链接
  else if AItem.RequiresReboot then
    Result := msCopy; // 需要重启，先复制
end;

// 计算风险级别
function TMigrationPlanner.CalculateRisk(const AItem: TMigrationItem): TMigrationRisk;
var
  RiskScore: Integer;
begin
  RiskScore := 0;
  
  // 根据各种因素计算风险分数
  if AItem.SafetyScore < 30 then
    RiskScore := RiskScore + 40;
  
  if Length(AItem.Dependencies) > 10 then
    RiskScore := RiskScore + 30;
  
  if AItem.RequiresReboot then
    RiskScore := RiskScore + 20;
  
  if AItem.Size > 100 * 1024 * 1024 * 1024 then // 大于100GB
    RiskScore := RiskScore + 10;
  
  // 根据风险分数确定级别
  if RiskScore >= 80 then
    Result := mrCritical
  else if RiskScore >= 60 then
    Result := mrHigh
  else if RiskScore >= 30 then
    Result := mrMedium
  else
    Result := mrLow;
end;

// 计算优先级
function TMigrationPlanner.CalculatePriority(const AItem: TMigrationItem): TMigrationPriority;
begin
  Result := mpNormal; // 默认普通优先级
  
  // 根据风险和大小确定优先级
  case AItem.Risk of
    mrCritical: Result := mpCritical;
    mrHigh: Result := mpHigh;
    mrMedium: Result := mpNormal;
    mrLow: Result := mpLow;
  end;
  
  // 大文件降低优先级
  if AItem.Size > 10 * 1024 * 1024 * 1024 then // 大于10GB
  begin
    if Result > mpLow then
      Result := TMigrationPriority(Ord(Result) - 1);
  end;
end;// 创建迁移计
划
function TMigrationPlanner.CreateMigrationPlan(const ASourceDrive, ATargetDrive: string; 
  const APaths: TArray<string>): TMigrationPlan;
var
  Items: TList<TMigrationItem>;
  I: Integer;
  Item: TMigrationItem;
  TotalSize, TotalTime: Int64;
  TotalFiles, HighRiskCount, CriticalCount: Integer;
  RequiresReboot: Boolean;
  OverallRiskScore: Integer;
begin
  Result.PlanId := FormatDateTime('yyyymmdd_hhnnss', Now) + '_' + IntToStr(Random(1000));
  Result.CreatedTime := Now;
  Result.SourceDrive := ASourceDrive;
  Result.TargetDrive := ATargetDrive;
  Result.TotalSize := 0;
  Result.TotalFiles := 0;
  Result.EstimatedDuration := 0;
  Result.TotalItems := 0;
  Result.HighRiskItems := 0;
  Result.CriticalItems := 0;
  Result.RequiresReboot := False;
  Result.SpaceRequired := 0;
  Result.SpaceAvailable := 0;
  Result.SpaceSufficient := False;
  Result.OverallRisk := mrLow;
  Result.OverallSafety := 100;
  
  Items := TList<TMigrationItem>.Create;
  
  try
    TotalSize := 0;
    TotalFiles := 0;
    TotalTime := 0;
    HighRiskCount := 0;
    CriticalCount := 0;
    RequiresReboot := False;
    OverallRiskScore := 0;
    
    // 分析每个路径
    for I := 0 to Length(APaths) - 1 do
    begin
      if IsExcludedPath(APaths[I]) then
        Continue;
      
      var TargetPath := StringReplace(APaths[I], ASourceDrive, ATargetDrive, [rfIgnoreCase]);
      Item := AnalyzeDirectory(APaths[I], TargetPath);
      
      Items.Add(Item);
      
      TotalSize := TotalSize + Item.Size;
      TotalFiles := TotalFiles + Item.FileCount;
      TotalTime := TotalTime + Item.EstimatedTime;
      
      if Item.Risk = mrHigh then
        Inc(HighRiskCount)
      else if Item.Risk = mrCritical then
        Inc(CriticalCount);
      
      if Item.RequiresReboot then
        RequiresReboot := True;
      
      OverallRiskScore := OverallRiskScore + Ord(Item.Risk);
    end;
    
    // 设置计划属性
    Result.TotalSize := TotalSize;
    Result.TotalFiles := TotalFiles;
    Result.EstimatedDuration := TotalTime;
    Result.TotalItems := Items.Count;
    Result.HighRiskItems := HighRiskCount;
    Result.CriticalItems := CriticalCount;
    Result.RequiresReboot := RequiresReboot;
    Result.SpaceRequired := TotalSize;
    
    // 检查目标磁盘空间
    var FreeBytes: Int64;
    if GetDiskFreeSpaceEx(PChar(ATargetDrive), FreeBytes, nil, nil) then
    begin
      Result.SpaceAvailable := FreeBytes;
      Result.SpaceSufficient := FreeBytes > TotalSize * 2; // 需要2倍空间以确保安全
    end;
    
    // 计算总体风险
    if Items.Count > 0 then
    begin
      var AvgRisk := OverallRiskScore div Items.Count;
      Result.OverallRisk := TMigrationRisk(Min(Ord(mrCritical), AvgRisk));
      Result.OverallSafety := Max(0, 100 - (OverallRiskScore * 25 div Items.Count));
    end;
    
    // 转换为数组
    SetLength(Result.Items, Items.Count);
    for I := 0 to Items.Count - 1 do
      Result.Items[I] := Items[I];
    
    // 生成先决条件、后续操作和回退计划
    Result.Prerequisites := GeneratePrerequisites(Result);
    Result.PostActions := GeneratePostActions(Result);
    Result.RollbackPlan := GenerateRollbackPlan(Result);
    
    // 记录计划创建日志
    if Assigned(FConfigManager) then
    begin
      FConfigManager.LogOperation('MIGRATION_PLANNING', 'Plan created', ASourceDrive, ATargetDrive, 'SUCCESS', 
        Format('Items: %d, Size: %s, Risk: %s', [Result.TotalItems, FormatSize(Result.TotalSize), GetMigrationRiskString(Result.OverallRisk)]));
    end;
    
  finally
    Items.Free;
  end;
end;

// 验证迁移计划
function TMigrationPlanner.ValidateMigrationPlan(const APlan: TMigrationPlan): Boolean;
begin
  Result := True;
  
  try
    // 检查基本有效性
    if APlan.TotalItems = 0 then
    begin
      Result := False;
      Exit;
    end;
    
    // 检查空间充足性
    if not APlan.SpaceSufficient then
    begin
      Result := False;
      Exit;
    end;
    
    // 检查关键风险项目
    if APlan.CriticalItems > APlan.TotalItems div 2 then
    begin
      Result := False;
      Exit;
    end;
    
    // 检查源路径存在性
    for var I := 0 to Length(APlan.Items) - 1 do
    begin
      if not DirectoryExists(APlan.Items[I].SourcePath) then
      begin
        Result := False;
        Exit;
      end;
    end;
    
    if Assigned(FConfigManager) then
    begin
      FConfigManager.LogOperation('MIGRATION_PLANNING', 'Plan validated', APlan.PlanId, '', 
        Result.ToString, 'Plan validation completed');
    end;
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('MIGRATION_PLANNING', 'Validation error', APlan.PlanId, '', 'ERROR', E.Message);
    end;
  end;
end;

// 优化迁移计划
function TMigrationPlanner.OptimizeMigrationPlan(var APlan: TMigrationPlan): Boolean;
var
  OptimizedItems: TArray<TMigrationItem>;
  I, J: Integer;
begin
  Result := True;
  
  try
    // 按优先级和风险排序
    OptimizedItems := APlan.Items;
    
    // 简单的冒泡排序，按优先级降序，风险升序
    for I := 0 to Length(OptimizedItems) - 2 do
    begin
      for J := I + 1 to Length(OptimizedItems) - 1 do
      begin
        var ShouldSwap := False;
        
        // 优先级高的在前
        if OptimizedItems[I].Priority < OptimizedItems[J].Priority then
          ShouldSwap := True
        // 同优先级时，风险低的在前
        else if (OptimizedItems[I].Priority = OptimizedItems[J].Priority) and 
                (OptimizedItems[I].Risk > OptimizedItems[J].Risk) then
          ShouldSwap := True;
        
        if ShouldSwap then
        begin
          var Temp := OptimizedItems[I];
          OptimizedItems[I] := OptimizedItems[J];
          OptimizedItems[J] := Temp;
        end;
      end;
    end;
    
    APlan.Items := OptimizedItems;
    
    // 重新计算预估时间（考虑并行处理）
    var TotalTime := 0;
    for I := 0 to Length(APlan.Items) - 1 do
    begin
      // 小文件可以并行处理，大文件需要串行
      if APlan.Items[I].Size < 1024 * 1024 * 1024 then // 小于1GB
        TotalTime := TotalTime + APlan.Items[I].EstimatedTime div 2
      else
        TotalTime := TotalTime + APlan.Items[I].EstimatedTime;
    end;
    
    APlan.EstimatedDuration := TotalTime;
    
    if Assigned(FConfigManager) then
    begin
      FConfigManager.LogOperation('MIGRATION_PLANNING', 'Plan optimized', APlan.PlanId, '', 'SUCCESS', 
        Format('New duration: %s', [FormatDuration(APlan.EstimatedDuration)]));
    end;
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('MIGRATION_PLANNING', 'Optimization error', APlan.PlanId, '', 'ERROR', E.Message);
    end;
  end;
end;

// 检查空间需求
function TMigrationPlanner.CheckSpaceRequirements(const APlan: TMigrationPlan): Boolean;
begin
  Result := APlan.SpaceSufficient and (APlan.SpaceAvailable > APlan.SpaceRequired * 1.2);
end;

// 生成先决条件
function TMigrationPlanner.GeneratePrerequisites(const APlan: TMigrationPlan): TArray<string>;
var
  Prerequisites: TList<string>;
  I: Integer;
begin
  Prerequisites := TList<string>.Create;
  
  try
    Prerequisites.Add('确保目标磁盘有足够空间');
    Prerequisites.Add('关闭所有可能使用源文件的程序');
    Prerequisites.Add('创建系统还原点');
    
    if APlan.RequiresReboot then
      Prerequisites.Add('准备在迁移后重启系统');
    
    if APlan.CriticalItems > 0 then
      Prerequisites.Add('备份重要数据');
    
    if APlan.OverallRisk >= mrHigh then
      Prerequisites.Add('建议在非工作时间执行迁移');
    
    // 检查特定依赖
    for I := 0 to Length(APlan.Items) - 1 do
    begin
      if Length(APlan.Items[I].Dependencies) > 0 then
      begin
        Prerequisites.Add('检查并处理依赖关系');
        Break;
      end;
    end;
    
    SetLength(Result, Prerequisites.Count);
    for I := 0 to Prerequisites.Count - 1 do
      Result[I] := Prerequisites[I];
    
  finally
    Prerequisites.Free;
  end;
end;

// 生成后续操作
function TMigrationPlanner.GeneratePostActions(const APlan: TMigrationPlan): TArray<string>;
var
  PostActions: TList<string>;
  I: Integer;
begin
  PostActions := TList<string>.Create;
  
  try
    PostActions.Add('验证迁移结果');
    PostActions.Add('测试应用程序功能');
    PostActions.Add('检查符号链接有效性');
    
    if APlan.RequiresReboot then
      PostActions.Add('重启系统');
    
    PostActions.Add('清理临时文件');
    PostActions.Add('更新备份策略');
    
    // 检查是否需要更新注册表
    for I := 0 to Length(APlan.Items) - 1 do
    begin
      if Length(APlan.Items[I].Dependencies) > 0 then
      begin
        PostActions.Add('更新相关配置和注册表');
        Break;
      end;
    end;
    
    SetLength(Result, PostActions.Count);
    for I := 0 to PostActions.Count - 1 do
      Result[I] := PostActions[I];
    
  finally
    PostActions.Free;
  end;
end;

// 生成回退计划
function TMigrationPlanner.GenerateRollbackPlan(const APlan: TMigrationPlan): TArray<string>;
var
  RollbackPlan: TList<string>;
  I: Integer;
begin
  RollbackPlan := TList<string>.Create;
  
  try
    RollbackPlan.Add('停止所有相关应用程序');
    RollbackPlan.Add('删除创建的符号链接');
    RollbackPlan.Add('从目标位置复制文件回源位置');
    RollbackPlan.Add('恢复原始目录结构');
    RollbackPlan.Add('更新相关配置');
    
    if APlan.RequiresReboot then
      RollbackPlan.Add('重启系统以完成回退');
    
    RollbackPlan.Add('验证回退结果');
    RollbackPlan.Add('清理残留文件');
    
    SetLength(Result, RollbackPlan.Count);
    for I := 0 to RollbackPlan.Count - 1 do
      Result[I] := RollbackPlan[I];
    
  finally
    RollbackPlan.Free;
  end;
end;// 保存迁移计划

function TMigrationPlanner.SaveMigrationPlan(const APlan: TMigrationPlan; const AFileName: string): Boolean;
var
  JSONObj, ItemsArray, ItemObj, DepsArray, WarningsArray, RecsArray: TJSONObject;
  I, J: Integer;
  JSONStr: string;
begin
  Result := True;
  
  try
    JSONObj := TJSONObject.Create;
    try
      // 基本信息
      JSONObj.AddPair('PlanId', APlan.PlanId);
      JSONObj.AddPair('CreatedTime', DateTimeToStr(APlan.CreatedTime));
      JSONObj.AddPair('SourceDrive', APlan.SourceDrive);
      JSONObj.AddPair('TargetDrive', APlan.TargetDrive);
      JSONObj.AddPair('TotalSize', TJSONNumber.Create(APlan.TotalSize));
      JSONObj.AddPair('TotalFiles', TJSONNumber.Create(APlan.TotalFiles));
      JSONObj.AddPair('EstimatedDuration', TJSONNumber.Create(APlan.EstimatedDuration));
      JSONObj.AddPair('TotalItems', TJSONNumber.Create(APlan.TotalItems));
      JSONObj.AddPair('HighRiskItems', TJSONNumber.Create(APlan.HighRiskItems));
      JSONObj.AddPair('CriticalItems', TJSONNumber.Create(APlan.CriticalItems));
      JSONObj.AddPair('RequiresReboot', TJSONBool.Create(APlan.RequiresReboot));
      JSONObj.AddPair('SpaceRequired', TJSONNumber.Create(APlan.SpaceRequired));
      JSONObj.AddPair('SpaceAvailable', TJSONNumber.Create(APlan.SpaceAvailable));
      JSONObj.AddPair('SpaceSufficient', TJSONBool.Create(APlan.SpaceSufficient));
      JSONObj.AddPair('OverallRisk', TJSONNumber.Create(Ord(APlan.OverallRisk)));
      JSONObj.AddPair('OverallSafety', TJSONNumber.Create(APlan.OverallSafety));
      
      // 迁移项目
      ItemsArray := TJSONObject.Create;
      for I := 0 to Length(APlan.Items) - 1 do
      begin
        ItemObj := TJSONObject.Create;
        ItemObj.AddPair('SourcePath', APlan.Items[I].SourcePath);
        ItemObj.AddPair('TargetPath', APlan.Items[I].TargetPath);
        ItemObj.AddPair('Strategy', TJSONNumber.Create(Ord(APlan.Items[I].Strategy)));
        ItemObj.AddPair('Priority', TJSONNumber.Create(Ord(APlan.Items[I].Priority)));
        ItemObj.AddPair('Risk', TJSONNumber.Create(Ord(APlan.Items[I].Risk)));
        ItemObj.AddPair('Size', TJSONNumber.Create(APlan.Items[I].Size));
        ItemObj.AddPair('FileCount', TJSONNumber.Create(APlan.Items[I].FileCount));
        ItemObj.AddPair('EstimatedTime', TJSONNumber.Create(APlan.Items[I].EstimatedTime));
        ItemObj.AddPair('RequiresReboot', TJSONBool.Create(APlan.Items[I].RequiresReboot));
        ItemObj.AddPair('RequiresBackup', TJSONBool.Create(APlan.Items[I].RequiresBackup));
        ItemObj.AddPair('CanRollback', TJSONBool.Create(APlan.Items[I].CanRollback));
        ItemObj.AddPair('SafetyScore', TJSONNumber.Create(APlan.Items[I].SafetyScore));
        
        ItemsArray.AddPair('Item' + IntToStr(I), ItemObj);
      end;
      JSONObj.AddPair('Items', ItemsArray);
      
      JSONStr := JSONObj.ToString;
      TFile.WriteAllText(AFileName, JSONStr, TEncoding.UTF8);
      
    finally
      JSONObj.Free;
    end;
    
    if Assigned(FConfigManager) then
    begin
      FConfigManager.LogOperation('MIGRATION_PLANNING', 'Plan saved', APlan.PlanId, AFileName, 'SUCCESS', 
        Format('File size: %d bytes', [Length(JSONStr)]));
    end;
    
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('MIGRATION_PLANNING', 'Save error', APlan.PlanId, AFileName, 'ERROR', E.Message);
    end;
  end;
end;

// 加载迁移计划
function TMigrationPlanner.LoadMigrationPlan(const AFileName: string): TMigrationPlan;
var
  JSONStr: string;
  JSONObj, ItemsObj, ItemObj: TJSONObject;
  ItemsArray: TJSONArray;
  I: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  
  try
    if not FileExists(AFileName) then
    begin
      Result.PlanId := 'ERROR_FILE_NOT_FOUND';
      Exit;
    end;
    
    JSONStr := TFile.ReadAllText(AFileName, TEncoding.UTF8);
    JSONObj := TJSONObject.ParseJSONValue(JSONStr) as TJSONObject;
    
    try
      // 基本信息
      Result.PlanId := JSONObj.GetValue('PlanId').Value;
      Result.CreatedTime := StrToDateTime(JSONObj.GetValue('CreatedTime').Value);
      Result.SourceDrive := JSONObj.GetValue('SourceDrive').Value;
      Result.TargetDrive := JSONObj.GetValue('TargetDrive').Value;
      Result.TotalSize := (JSONObj.GetValue('TotalSize') as TJSONNumber).AsInt64;
      Result.TotalFiles := (JSONObj.GetValue('TotalFiles') as TJSONNumber).AsInt;
      Result.EstimatedDuration := (JSONObj.GetValue('EstimatedDuration') as TJSONNumber).AsInt;
      Result.TotalItems := (JSONObj.GetValue('TotalItems') as TJSONNumber).AsInt;
      Result.HighRiskItems := (JSONObj.GetValue('HighRiskItems') as TJSONNumber).AsInt;
      Result.CriticalItems := (JSONObj.GetValue('CriticalItems') as TJSONNumber).AsInt;
      Result.RequiresReboot := (JSONObj.GetValue('RequiresReboot') as TJSONBool).AsBoolean;
      Result.SpaceRequired := (JSONObj.GetValue('SpaceRequired') as TJSONNumber).AsInt64;
      Result.SpaceAvailable := (JSONObj.GetValue('SpaceAvailable') as TJSONNumber).AsInt64;
      Result.SpaceSufficient := (JSONObj.GetValue('SpaceSufficient') as TJSONBool).AsBoolean;
      Result.OverallRisk := TMigrationRisk((JSONObj.GetValue('OverallRisk') as TJSONNumber).AsInt);
      Result.OverallSafety := (JSONObj.GetValue('OverallSafety') as TJSONNumber).AsInt;
      
      // 迁移项目
      ItemsObj := JSONObj.GetValue('Items') as TJSONObject;
      SetLength(Result.Items, Result.TotalItems);
      
      for I := 0 to Result.TotalItems - 1 do
      begin
        ItemObj := ItemsObj.GetValue('Item' + IntToStr(I)) as TJSONObject;
        
        Result.Items[I].SourcePath := ItemObj.GetValue('SourcePath').Value;
        Result.Items[I].TargetPath := ItemObj.GetValue('TargetPath').Value;
        Result.Items[I].Strategy := TMigrationStrategy((ItemObj.GetValue('Strategy') as TJSONNumber).AsInt);
        Result.Items[I].Priority := TMigrationPriority((ItemObj.GetValue('Priority') as TJSONNumber).AsInt);
        Result.Items[I].Risk := TMigrationRisk((ItemObj.GetValue('Risk') as TJSONNumber).AsInt);
        Result.Items[I].Size := (ItemObj.GetValue('Size') as TJSONNumber).AsInt64;
        Result.Items[I].FileCount := (ItemObj.GetValue('FileCount') as TJSONNumber).AsInt;
        Result.Items[I].EstimatedTime := (ItemObj.GetValue('EstimatedTime') as TJSONNumber).AsInt;
        Result.Items[I].RequiresReboot := (ItemObj.GetValue('RequiresReboot') as TJSONBool).AsBoolean;
        Result.Items[I].RequiresBackup := (ItemObj.GetValue('RequiresBackup') as TJSONBool).AsBoolean;
        Result.Items[I].CanRollback := (ItemObj.GetValue('CanRollback') as TJSONBool).AsBoolean;
        Result.Items[I].SafetyScore := (ItemObj.GetValue('SafetyScore') as TJSONNumber).AsInt;
      end;
      
    finally
      JSONObj.Free;
    end;
    
    if Assigned(FConfigManager) then
    begin
      FConfigManager.LogOperation('MIGRATION_PLANNING', 'Plan loaded', Result.PlanId, AFileName, 'SUCCESS', 
        Format('Items: %d', [Result.TotalItems]));
    end;
    
  except
    on E: Exception do
    begin
      Result.PlanId := 'ERROR_LOAD_FAILED';
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('MIGRATION_PLANNING', 'Load error', '', AFileName, 'ERROR', E.Message);
    end;
  end;
end;

// 比较计划
function TMigrationPlanner.ComparePlans(const APlan1, APlan2: TMigrationPlan): string;
var
  Comparison: TStringList;
begin
  Comparison := TStringList.Create;
  
  try
    Comparison.Add('迁移计划比较');
    Comparison.Add('═══════════════════════');
    Comparison.Add(Format('计划1: %s (创建于 %s)', [APlan1.PlanId, DateTimeToStr(APlan1.CreatedTime)]));
    Comparison.Add(Format('计划2: %s (创建于 %s)', [APlan2.PlanId, DateTimeToStr(APlan2.CreatedTime)]));
    Comparison.Add('');
    
    Comparison.Add('基本信息对比:');
    Comparison.Add(Format('  项目数量: %d vs %d', [APlan1.TotalItems, APlan2.TotalItems]));
    Comparison.Add(Format('  总大小: %s vs %s', [FormatSize(APlan1.TotalSize), FormatSize(APlan2.TotalSize)]));
    Comparison.Add(Format('  预估时间: %s vs %s', [FormatDuration(APlan1.EstimatedDuration), FormatDuration(APlan2.EstimatedDuration)]));
    Comparison.Add(Format('  高风险项: %d vs %d', [APlan1.HighRiskItems, APlan2.HighRiskItems]));
    Comparison.Add(Format('  严重项: %d vs %d', [APlan1.CriticalItems, APlan2.CriticalItems]));
    Comparison.Add(Format('  需要重启: %s vs %s', [BoolToStr(APlan1.RequiresReboot, True), BoolToStr(APlan2.RequiresReboot, True)]));
    Comparison.Add(Format('  总体安全: %d%% vs %d%%', [APlan1.OverallSafety, APlan2.OverallSafety]));
    
    Comparison.Add('');
    Comparison.Add('建议:');
    if APlan1.OverallSafety > APlan2.OverallSafety then
      Comparison.Add('  计划1 更安全')
    else if APlan2.OverallSafety > APlan1.OverallSafety then
      Comparison.Add('  计划2 更安全')
    else
      Comparison.Add('  两个计划安全性相当');
    
    if APlan1.EstimatedDuration < APlan2.EstimatedDuration then
      Comparison.Add('  计划1 更快')
    else if APlan2.EstimatedDuration < APlan1.EstimatedDuration then
      Comparison.Add('  计划2 更快')
    else
      Comparison.Add('  两个计划耗时相当');
    
    Result := Comparison.Text;
    
  finally
    Comparison.Free;
  end;
end;/
/ 配置管理方法
procedure TMigrationPlanner.AddExcludePath(const APath: string);
begin
  if FExcludePaths.IndexOf(APath) = -1 then
    FExcludePaths.Add(APath);
end;

procedure TMigrationPlanner.RemoveExcludePath(const APath: string);
var
  Index: Integer;
begin
  Index := FExcludePaths.IndexOf(APath);
  if Index >= 0 then
    FExcludePaths.Delete(Index);
end;

procedure TMigrationPlanner.AddIncludePath(const APath: string);
begin
  if FIncludePaths.IndexOf(APath) = -1 then
    FIncludePaths.Add(APath);
end;

procedure TMigrationPlanner.RemoveIncludePath(const APath: string);
var
  Index: Integer;
begin
  Index := FIncludePaths.IndexOf(APath);
  if Index >= 0 then
    FIncludePaths.Delete(Index);
end;

procedure TMigrationPlanner.ClearExcludePaths;
begin
  FExcludePaths.Clear;
end;

procedure TMigrationPlanner.ClearIncludePaths;
begin
  FIncludePaths.Clear;
end;

// 辅助方法
function TMigrationPlanner.GetMigrationStrategyString(AStrategy: TMigrationStrategy): string;
begin
  case AStrategy of
    msMove: Result := '移动';
    msCopy: Result := '复制';
    msSymlink: Result := '符号链接';
    msSkip: Result := '跳过';
  else
    Result := '未知';
  end;
end;

function TMigrationPlanner.GetMigrationPriorityString(APriority: TMigrationPriority): string;
begin
  case APriority of
    mpLow: Result := '低';
    mpNormal: Result := '普通';
    mpHigh: Result := '高';
    mpCritical: Result := '严重';
  else
    Result := '未知';
  end;
end;

function TMigrationPlanner.GetMigrationRiskString(ARisk: TMigrationRisk): string;
begin
  case ARisk of
    mrLow: Result := '低风险';
    mrMedium: Result := '中等风险';
    mrHigh: Result := '高风险';
    mrCritical: Result := '严重风险';
  else
    Result := '未知风险';
  end;
end;

function TMigrationPlanner.FormatSize(ASize: Int64): string;
const
  KB = 1024;
  MB = KB * 1024;
  GB = MB * 1024;
  TB = GB * Int64(1024);
begin
  if ASize >= TB then
    Result := Format('%.2f TB', [ASize / TB])
  else if ASize >= GB then
    Result := Format('%.2f GB', [ASize / GB])
  else if ASize >= MB then
    Result := Format('%.2f MB', [ASize / MB])
  else if ASize >= KB then
    Result := Format('%.2f KB', [ASize / KB])
  else
    Result := Format('%d B', [ASize]);
end;

function TMigrationPlanner.FormatDuration(ASeconds: Integer): string;
var
  Hours, Minutes, Seconds: Integer;
begin
  Hours := ASeconds div 3600;
  Minutes := (ASeconds mod 3600) div 60;
  Seconds := ASeconds mod 60;
  
  if Hours > 0 then
    Result := Format('%d小时%d分钟', [Hours, Minutes])
  else if Minutes > 0 then
    Result := Format('%d分钟%d秒', [Minutes, Seconds])
  else
    Result := Format('%d秒', [Seconds]);
end;

// 报告生成方法
function TMigrationPlanner.GeneratePlanSummary(const APlan: TMigrationPlan): string;
var
  Summary: TStringList;
begin
  Summary := TStringList.Create;
  
  try
    Summary.Add('迁移计划摘要');
    Summary.Add('═══════════════════════');
    Summary.Add(Format('计划ID: %s', [APlan.PlanId]));
    Summary.Add(Format('创建时间: %s', [DateTimeToStr(APlan.CreatedTime)]));
    Summary.Add(Format('源驱动器: %s', [APlan.SourceDrive]));
    Summary.Add(Format('目标驱动器: %s', [APlan.TargetDrive]));
    Summary.Add('');
    
    Summary.Add('基本统计:');
    Summary.Add(Format('  迁移项目: %d 个', [APlan.TotalItems]));
    Summary.Add(Format('  总大小: %s', [FormatSize(APlan.TotalSize)]));
    Summary.Add(Format('  文件数量: %s 个', [FormatFloat('#,##0', APlan.TotalFiles)]));
    Summary.Add(Format('  预估时间: %s', [FormatDuration(APlan.EstimatedDuration)]));
    Summary.Add('');
    
    Summary.Add('风险评估:');
    Summary.Add(Format('  总体风险: %s', [GetMigrationRiskString(APlan.OverallRisk)]));
    Summary.Add(Format('  安全分数: %d/100', [APlan.OverallSafety]));
    Summary.Add(Format('  高风险项: %d 个', [APlan.HighRiskItems]));
    Summary.Add(Format('  严重项: %d 个', [APlan.CriticalItems]));
    Summary.Add(Format('  需要重启: %s', [BoolToStr(APlan.RequiresReboot, True)]));
    Summary.Add('');
    
    Summary.Add('空间需求:');
    Summary.Add(Format('  需要空间: %s', [FormatSize(APlan.SpaceRequired)]));
    Summary.Add(Format('  可用空间: %s', [FormatSize(APlan.SpaceAvailable)]));
    Summary.Add(Format('  空间充足: %s', [BoolToStr(APlan.SpaceSufficient, True)]));
    
    Result := Summary.Text;
    
  finally
    Summary.Free;
  end;
end;

function TMigrationPlanner.GenerateDetailedReport(const APlan: TMigrationPlan): string;
var
  Report: TStringList;
  I, J: Integer;
begin
  Report := TStringList.Create;
  
  try
    Report.Add('详细迁移计划报告');
    Report.Add('═══════════════════════');
    Report.Add(Format('生成时间: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
    Report.Add('');
    
    // 添加摘要
    Report.Add(GeneratePlanSummary(APlan));
    Report.Add('');
    
    // 先决条件
    if Length(APlan.Prerequisites) > 0 then
    begin
      Report.Add('先决条件:');
      for I := 0 to Length(APlan.Prerequisites) - 1 do
        Report.Add('  • ' + APlan.Prerequisites[I]);
      Report.Add('');
    end;
    
    // 详细项目列表
    Report.Add('迁移项目详情:');
    Report.Add('─────────────────────────');
    
    for I := 0 to Length(APlan.Items) - 1 do
    begin
      Report.Add('');
      Report.Add(Format('项目 %d:', [I + 1]));
      Report.Add(Format('  源路径: %s', [APlan.Items[I].SourcePath]));
      Report.Add(Format('  目标路径: %s', [APlan.Items[I].TargetPath]));
      Report.Add(Format('  策略: %s', [GetMigrationStrategyString(APlan.Items[I].Strategy)]));
      Report.Add(Format('  优先级: %s', [GetMigrationPriorityString(APlan.Items[I].Priority)]));
      Report.Add(Format('  风险: %s', [GetMigrationRiskString(APlan.Items[I].Risk)]));
      Report.Add(Format('  大小: %s', [FormatSize(APlan.Items[I].Size)]));
      Report.Add(Format('  文件数: %s', [FormatFloat('#,##0', APlan.Items[I].FileCount)]));
      Report.Add(Format('  预估时间: %s', [FormatDuration(APlan.Items[I].EstimatedTime)]));
      Report.Add(Format('  安全分数: %d/100', [APlan.Items[I].SafetyScore]));
      
      if Length(APlan.Items[I].Dependencies) > 0 then
      begin
        Report.Add('  依赖关系:');
        for J := 0 to Length(APlan.Items[I].Dependencies) - 1 do
          Report.Add('    - ' + APlan.Items[I].Dependencies[J]);
      end;
      
      if Length(APlan.Items[I].Warnings) > 0 then
      begin
        Report.Add('  警告:');
        for J := 0 to Length(APlan.Items[I].Warnings) - 1 do
          Report.Add('    ⚠ ' + APlan.Items[I].Warnings[J]);
      end;
      
      if Length(APlan.Items[I].Recommendations) > 0 then
      begin
        Report.Add('  建议:');
        for J := 0 to Length(APlan.Items[I].Recommendations) - 1 do
          Report.Add('    💡 ' + APlan.Items[I].Recommendations[J]);
      end;
    end;
    
    // 后续操作
    if Length(APlan.PostActions) > 0 then
    begin
      Report.Add('');
      Report.Add('后续操作:');
      for I := 0 to Length(APlan.PostActions) - 1 do
        Report.Add('  • ' + APlan.PostActions[I]);
    end;
    
    // 回退计划
    if Length(APlan.RollbackPlan) > 0 then
    begin
      Report.Add('');
      Report.Add('回退计划:');
      for I := 0 to Length(APlan.RollbackPlan) - 1 do
        Report.Add('  • ' + APlan.RollbackPlan[I]);
    end;
    
    Result := Report.Text;
    
  finally
    Report.Free;
  end;
end;

function TMigrationPlanner.GenerateRiskAssessment(const APlan: TMigrationPlan): string;
var
  Assessment: TStringList;
  I: Integer;
  LowRisk, MediumRisk, HighRisk, CriticalRisk: Integer;
begin
  Assessment := TStringList.Create;
  
  try
    Assessment.Add('风险评估报告');
    Assessment.Add('═══════════════════════');
    Assessment.Add(Format('评估时间: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
    Assessment.Add(Format('计划ID: %s', [APlan.PlanId]));
    Assessment.Add('');
    
    // 统计各风险级别
    LowRisk := 0;
    MediumRisk := 0;
    HighRisk := 0;
    CriticalRisk := 0;
    
    for I := 0 to Length(APlan.Items) - 1 do
    begin
      case APlan.Items[I].Risk of
        mrLow: Inc(LowRisk);
        mrMedium: Inc(MediumRisk);
        mrHigh: Inc(HighRisk);
        mrCritical: Inc(CriticalRisk);
      end;
    end;
    
    Assessment.Add('风险分布:');
    Assessment.Add(Format('  低风险: %d 项 (%.1f%%)', [LowRisk, LowRisk * 100.0 / APlan.TotalItems]));
    Assessment.Add(Format('  中等风险: %d 项 (%.1f%%)', [MediumRisk, MediumRisk * 100.0 / APlan.TotalItems]));
    Assessment.Add(Format('  高风险: %d 项 (%.1f%%)', [HighRisk, HighRisk * 100.0 / APlan.TotalItems]));
    Assessment.Add(Format('  严重风险: %d 项 (%.1f%%)', [CriticalRisk, CriticalRisk * 100.0 / APlan.TotalItems]));
    Assessment.Add('');
    
    Assessment.Add('总体评估:');
    Assessment.Add(Format('  总体风险级别: %s', [GetMigrationRiskString(APlan.OverallRisk)]));
    Assessment.Add(Format('  安全分数: %d/100', [APlan.OverallSafety]));
    
    if APlan.OverallSafety >= 80 then
      Assessment.Add('  评估结果: 迁移风险较低，可以执行')
    else if APlan.OverallSafety >= 60 then
      Assessment.Add('  评估结果: 迁移风险中等，建议谨慎执行')
    else if APlan.OverallSafety >= 40 then
      Assessment.Add('  评估结果: 迁移风险较高，需要额外预防措施')
    else
      Assessment.Add('  评估结果: 迁移风险很高，不建议执行');
    
    Assessment.Add('');
    
    // 风险缓解建议
    Assessment.Add('风险缓解建议:');
    if CriticalRisk > 0 then
      Assessment.Add('  • 严重风险项目建议跳过或使用符号链接');
    if HighRisk > 0 then
      Assessment.Add('  • 高风险项目建议先备份再迁移');
    if APlan.RequiresReboot then
      Assessment.Add('  • 安排在系统维护时间窗口执行');
    if not APlan.SpaceSufficient then
      Assessment.Add('  • 确保目标磁盘有足够空间');
    
    Assessment.Add('  • 创建完整的系统备份');
    Assessment.Add('  • 准备回退计划');
    Assessment.Add('  • 在测试环境中先行验证');
    
    Result := Assessment.Text;
    
  finally
    Assessment.Free;
  end;
end;

end.
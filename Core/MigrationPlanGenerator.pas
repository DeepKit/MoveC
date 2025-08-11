unit MigrationPlanGenerator;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.StrUtils, 
  System.Generics.Collections, System.DateUtils, Winapi.Windows,
  DataTypes, BasicProtection, FileClassificationSystem, 
  FileSafetyEvaluator, DependencyAnalyzer, RebootDetector;

type
  // 迁移策略
  TMigrationStrategy = (
    msMove,           // 移动文件
    msCopy,           // 复制文件
    msSymbolicLink,   // 创建符号链接
    msHardLink,       // 创建硬链接
    msSkip,           // 跳过文件
    msDelete          // 删除文件
  );

  // 迁移优先级
  TMigrationPriority = (
    mpLow,            // 低优先级
    mpNormal,         // 普通优先级
    mpHigh,           // 高优先级
    mpCritical        // 关键优先级
  );

  // 迁移阶段
  TMigrationPhase = (
    mpPreparation,    // 准备阶段
    mpAnalysis,       // 分析阶段
    mpExecution,      // 执行阶段
    mpVerification,   // 验证阶段
    mpCleanup         // 清理阶段
  );

  // 迁移项目
  TMigrationItem = record
    SourcePath: string;
    TargetPath: string;
    Strategy: TMigrationStrategy;
    Priority: TMigrationPriority;
    Phase: TMigrationPhase;
    FileSize: Int64;
    EstimatedTime: Integer; // 预计时间（秒）
    RequiresReboot: Boolean;
    Dependencies: TArray<string>;
    RiskLevel: Integer; // 0-100
    Description: string;
    BackupRequired: Boolean;
    VerificationMethod: string;
  end;

  // 迁移计划
  TMigrationPlan = record
    PlanName: string;
    CreatedTime: TDateTime;
    SourceDirectory: string;
    TargetDirectory: string;
    TotalItems: Integer;
    TotalSize: Int64;
    EstimatedDuration: Integer; // 预计总时间（秒）
    RequiredSpace: Int64;
    AvailableSpace: Int64;
    SpaceUtilization: Double; // 空间利用率
    RiskAssessment: string;
    Items: TArray<TMigrationItem>;
    Prerequisites: TArray<string>;
    PostActions: TArray<string>;
    RollbackPlan: TArray<string>;
  end;

  // 空间分析结果
  TSpaceAnalysisResult = record
    SourcePath: string;
    TargetPath: string;
    RequiredSpace: Int64;
    AvailableSpace: Int64;
    FreeSpaceAfter: Int64;
    SpaceUtilization: Double;
    IsSpaceSufficient: Boolean;
    RecommendedCleanup: TArray<string>;
    SpaceOptimizations: TArray<string>;
  end;

  // 可行性评估结果
  TFeasibilityResult = record
    IsFeasible: Boolean;
    ConfidenceLevel: Integer; // 0-100
    BlockingIssues: TArray<string>;
    Warnings: TArray<string>;
    Recommendations: TArray<string>;
    EstimatedSuccessRate: Integer; // 0-100
    RiskFactors: TArray<string>;
    MitigationStrategies: TArray<string>;
  end;

  // 迁移计划生成器
  TMigrationPlanGenerator = class
  private
    FFileClassifier: TFileClassificationSystem;
    FSafetyEvaluator: TFileSafetyEvaluator;
    FDependencyAnalyzer: TDependencyAnalyzer;
    FRebootDetector: TRebootDetector;
    
    FDefaultStrategies: TDictionary<TFileCategory, TMigrationStrategy>;
    FPriorityRules: TDictionary<TFileCategory, TMigrationPriority>;
    FPhaseRules: TDictionary<TMigrationStrategy, TMigrationPhase>;
    
    // 核心分析方法
    function AnalyzeSourceDirectory(const ASourcePath: string): TArray<TMigrationItem>;
    function DetermineOptimalStrategy(const AFilePath: string): TMigrationStrategy;
    function CalculatePriority(const AFilePath: string; const AStrategy: TMigrationStrategy): TMigrationPriority;
    function AssignPhase(const AStrategy: TMigrationStrategy; const APriority: TMigrationPriority): TMigrationPhase;
    function EstimateTransferTime(const AFilePath: string; const AStrategy: TMigrationStrategy): Integer;
    function CalculateRiskLevel(const AFilePath: string; const AStrategy: TMigrationStrategy): Integer;
    
    // 空间计算方法
    function CalculateRequiredSpace(const AItems: TArray<TMigrationItem>): Int64;
    function GetAvailableSpace(const ATargetPath: string): Int64;
    function AnalyzeSpaceUtilization(const ASourcePath, ATargetPath: string; 
      const ARequiredSpace: Int64): TSpaceAnalysisResult;
    
    // 依赖关系处理
    function ResolveDependencies(var AItems: TArray<TMigrationItem>): Boolean;
    function SortByDependencies(const AItems: TArray<TMigrationItem>): TArray<TMigrationItem>;
    function ValidateDependencyChain(const AItems: TArray<TMigrationItem>): Boolean;
    
    // 计划优化
    function OptimizePlan(var APlan: TMigrationPlan): Boolean;
    function GroupByPhase(const AItems: TArray<TMigrationItem>): TDictionary<TMigrationPhase, TArray<TMigrationItem>>;
    function BalanceLoad(var AItems: TArray<TMigrationItem>): Boolean;
    
    // 风险评估
    function AssessOverallRisk(const AItems: TArray<TMigrationItem>): string;
    function GeneratePrerequisites(const AItems: TArray<TMigrationItem>): TArray<string>;
    function GeneratePostActions(const AItems: TArray<TMigrationItem>): TArray<string>;
    function GenerateRollbackPlan(const AItems: TArray<TMigrationItem>): TArray<string>;
    
    procedure InitializeDefaultRules;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 主要生成方法
    function GenerateMigrationPlan(const ASourcePath, ATargetPath: string; 
      const APlanName: string = ''): TMigrationPlan;
    function GenerateCustomPlan(const ASourcePath, ATargetPath: string; 
      const ACustomRules: TDictionary<string, TMigrationStrategy>): TMigrationPlan;
    
    // 空间分析
    function AnalyzeSpaceRequirements(const ASourcePath, ATargetPath: string): TSpaceAnalysisResult;
    function ValidateSpaceAvailability(const ATargetPath: string; const ARequiredSpace: Int64): Boolean;
    function GetSpaceOptimizationSuggestions(const ATargetPath: string): TArray<string>;
    
    // 可行性评估
    function EvaluateFeasibility(const ASourcePath, ATargetPath: string): TFeasibilityResult;
    function ValidateMigrationPlan(const APlan: TMigrationPlan): TFeasibilityResult;
    function EstimateSuccessRate(const APlan: TMigrationPlan): Integer;
    
    // 计划管理
    function SavePlan(const APlan: TMigrationPlan; const AFilePath: string): Boolean;
    function LoadPlan(const AFilePath: string): TMigrationPlan;
    function ComparePlans(const APlan1, APlan2: TMigrationPlan): string;
    
    // 工具方法
    class function StrategyToString(AStrategy: TMigrationStrategy): string;
    class function PriorityToString(APriority: TMigrationPriority): string;
    class function PhaseToString(APhase: TMigrationPhase): string;
    class function FormatFileSize(ASize: Int64): string;
    class function FormatDuration(ASeconds: Integer): string;
  end;

implementation

uses
  System.JSON, Vcl.Graphics;cons
tructor TMigrationPlanGenerator.Create;
begin
  inherited Create;
  
  FFileClassifier := TFileClassificationSystem.Create;
  FSafetyEvaluator := TFileSafetyEvaluator.Create;
  FDependencyAnalyzer := TDependencyAnalyzer.Create;
  FRebootDetector := TRebootDetector.Create;
  
  FDefaultStrategies := TDictionary<TFileCategory, TMigrationStrategy>.Create;
  FPriorityRules := TDictionary<TFileCategory, TMigrationPriority>.Create;
  FPhaseRules := TDictionary<TMigrationStrategy, TMigrationPhase>.Create;
  
  InitializeDefaultRules;
end;

destructor TMigrationPlanGenerator.Destroy;
begin
  FFileClassifier.Free;
  FSafetyEvaluator.Free;
  FDependencyAnalyzer.Free;
  FRebootDetector.Free;
  
  FDefaultStrategies.Free;
  FPriorityRules.Free;
  FPhaseRules.Free;
  
  inherited;
end;

procedure TMigrationPlanGenerator.InitializeDefaultRules;
begin
  // 默认迁移策略
  FDefaultStrategies.Clear;
  FDefaultStrategies.Add(fcSystemFile, msSymbolicLink);      // 系统文件使用符号链接
  FDefaultStrategies.Add(fcProgramFile, msMove);             // 程序文件移动
  FDefaultStrategies.Add(fcUserDocument, msMove);            // 用户文档移动
  FDefaultStrategies.Add(fcMediaFile, msMove);               // 媒体文件移动
  FDefaultStrategies.Add(fcTemporaryFile, msDelete);         // 临时文件删除
  FDefaultStrategies.Add(fcCacheFile, msDelete);             // 缓存文件删除
  FDefaultStrategies.Add(fcLogFile, msMove);                 // 日志文件移动
  FDefaultStrategies.Add(fcBackupFile, msMove);              // 备份文件移动
  FDefaultStrategies.Add(fcConfigFile, msCopy);              // 配置文件复制
  FDefaultStrategies.Add(fcDatabaseFile, msMove);            // 数据库文件移动
  FDefaultStrategies.Add(fcArchiveFile, msMove);             // 压缩文件移动
  FDefaultStrategies.Add(fcDevelopmentFile, msMove);         // 开发文件移动
  FDefaultStrategies.Add(fcWebFile, msMove);                 // 网页文件移动
  FDefaultStrategies.Add(fcFontFile, msSymbolicLink);        // 字体文件符号链接
  FDefaultStrategies.Add(fcDriverFile, msSkip);              // 驱动文件跳过
  
  // 优先级规则
  FPriorityRules.Clear;
  FPriorityRules.Add(fcSystemFile, mpCritical);              // 系统文件关键优先级
  FPriorityRules.Add(fcDriverFile, mpCritical);              // 驱动文件关键优先级
  FPriorityRules.Add(fcProgramFile, mpHigh);                 // 程序文件高优先级
  FPriorityRules.Add(fcConfigFile, mpHigh);                  // 配置文件高优先级
  FPriorityRules.Add(fcDatabaseFile, mpHigh);                // 数据库文件高优先级
  FPriorityRules.Add(fcUserDocument, mpNormal);              // 用户文档普通优先级
  FPriorityRules.Add(fcMediaFile, mpNormal);                 // 媒体文件普通优先级
  FPriorityRules.Add(fcArchiveFile, mpNormal);               // 压缩文件普通优先级
  FPriorityRules.Add(fcDevelopmentFile, mpNormal);           // 开发文件普通优先级
  FPriorityRules.Add(fcWebFile, mpNormal);                   // 网页文件普通优先级
  FPriorityRules.Add(fcFontFile, mpNormal);                  // 字体文件普通优先级
  FPriorityRules.Add(fcLogFile, mpLow);                      // 日志文件低优先级
  FPriorityRules.Add(fcBackupFile, mpLow);                   // 备份文件低优先级
  FPriorityRules.Add(fcTemporaryFile, mpLow);                // 临时文件低优先级
  FPriorityRules.Add(fcCacheFile, mpLow);                    // 缓存文件低优先级
  
  // 阶段规则
  FPhaseRules.Clear;
  FPhaseRules.Add(msDelete, mpPreparation);                  // 删除在准备阶段
  FPhaseRules.Add(msCopy, mpAnalysis);                       // 复制在分析阶段
  FPhaseRules.Add(msMove, mpExecution);                      // 移动在执行阶段
  FPhaseRules.Add(msSymbolicLink, mpExecution);              // 符号链接在执行阶段
  FPhaseRules.Add(msHardLink, mpExecution);                  // 硬链接在执行阶段
  FPhaseRules.Add(msSkip, mpVerification);                   // 跳过在验证阶段
end;

function TMigrationPlanGenerator.GenerateMigrationPlan(const ASourcePath, ATargetPath: string; 
  const APlanName: string): TMigrationPlan;
var
  Items: TArray<TMigrationItem>;
  SpaceAnalysis: TSpaceAnalysisResult;
begin
  // 初始化计划
  FillChar(Result, SizeOf(Result), 0);
  
  if APlanName <> '' then
    Result.PlanName := APlanName
  else
    Result.PlanName := Format('迁移计划_%s', [FormatDateTime('yyyymmdd_hhnnss', Now)]);
  
  Result.CreatedTime := Now;
  Result.SourceDirectory := ASourcePath;
  Result.TargetDirectory := ATargetPath;
  
  if not DirectoryExists(ASourcePath) then
  begin
    Result.RiskAssessment := '源目录不存在';
    Exit;
  end;
  
  try
    // 分析源目录
    Items := AnalyzeSourceDirectory(ASourcePath);
    
    // 解析依赖关系
    if not ResolveDependencies(Items) then
    begin
      Result.RiskAssessment := '依赖关系解析失败';
      Exit;
    end;
    
    // 按依赖关系排序
    Items := SortByDependencies(Items);
    
    // 优化计划
    Result.Items := Items;
    if not OptimizePlan(Result) then
    begin
      Result.RiskAssessment := '计划优化失败';
    end;
    
    // 计算统计信息
    Result.TotalItems := Length(Result.Items);
    Result.TotalSize := CalculateRequiredSpace(Result.Items);
    Result.RequiredSpace := Result.TotalSize;
    Result.AvailableSpace := GetAvailableSpace(ATargetPath);
    
    if Result.AvailableSpace > 0 then
      Result.SpaceUtilization := (Result.RequiredSpace / Result.AvailableSpace) * 100
    else
      Result.SpaceUtilization := 0;
    
    // 计算预计时间
    Result.EstimatedDuration := 0;
    for var Item in Result.Items do
      Result.EstimatedDuration := Result.EstimatedDuration + Item.EstimatedTime;
    
    // 空间分析
    SpaceAnalysis := AnalyzeSpaceUtilization(ASourcePath, ATargetPath, Result.RequiredSpace);
    
    // 风险评估
    Result.RiskAssessment := AssessOverallRisk(Result.Items);
    
    // 生成前置条件、后续操作和回退计划
    Result.Prerequisites := GeneratePrerequisites(Result.Items);
    Result.PostActions := GeneratePostActions(Result.Items);
    Result.RollbackPlan := GenerateRollbackPlan(Result.Items);
    
  except
    on E: Exception do
    begin
      Result.RiskAssessment := '计划生成失败: ' + E.Message;
    end;
  end;
end;

function TMigrationPlanGenerator.AnalyzeSourceDirectory(const ASourcePath: string): TArray<TMigrationItem>;
var
  Files: TArray<string>;
  ResultList: TList<TMigrationItem>;
  Item: TMigrationItem;
begin
  ResultList := TList<TMigrationItem>.Create;
  try
    // 获取所有文件
    Files := TDirectory.GetFiles(ASourcePath, '*', TSearchOption.soAllDirectories);
    
    for var FilePath in Files do
    begin
      // 初始化迁移项目
      FillChar(Item, SizeOf(Item), 0);
      Item.SourcePath := FilePath;
      Item.TargetPath := StringReplace(FilePath, ASourcePath, '', [rfIgnoreCase]);
      
      // 确定迁移策略
      Item.Strategy := DetermineOptimalStrategy(FilePath);
      
      // 计算优先级
      Item.Priority := CalculatePriority(FilePath, Item.Strategy);
      
      // 分配阶段
      Item.Phase := AssignPhase(Item.Strategy, Item.Priority);
      
      // 获取文件大小
      try
        if FileExists(FilePath) then
          Item.FileSize := TFile.GetSize(FilePath)
        else
          Item.FileSize := 0;
      except
        Item.FileSize := 0;
      end;
      
      // 估算传输时间
      Item.EstimatedTime := EstimateTransferTime(FilePath, Item.Strategy);
      
      // 检查是否需要重启
      var RebootResult := FRebootDetector.DetectRebootRequirement(FilePath);
      Item.RequiresReboot := RebootResult.RequiresReboot <> rrNotRequired;
      
      // 分析依赖关系
      var DependencyResult := FDependencyAnalyzer.AnalyzeFileDependencies(FilePath);
      SetLength(Item.Dependencies, Length(DependencyResult.Dependencies));
      for var I := 0 to Length(DependencyResult.Dependencies) - 1 do
        Item.Dependencies[I] := DependencyResult.Dependencies[I].SourcePath;
      
      // 计算风险级别
      Item.RiskLevel := CalculateRiskLevel(FilePath, Item.Strategy);
      
      // 生成描述
      var Classification := FFileClassifier.ClassifyFile(FilePath);
      Item.Description := Format('%s - %s', [
        TFileClassificationSystem.CategoryToString(Classification.Category),
        StrategyToString(Item.Strategy)
      ]);
      
      // 确定是否需要备份
      Item.BackupRequired := Classification.RequiresBackup or (Item.RiskLevel > 50);
      
      // 设置验证方法
      case Item.Strategy of
        msMove, msCopy:
          Item.VerificationMethod := '文件大小和修改时间验证';
        msSymbolicLink, msHardLink:
          Item.VerificationMethod := '链接目标验证';
        msDelete:
          Item.VerificationMethod := '文件不存在验证';
        msSkip:
          Item.VerificationMethod := '无需验证';
      end;
      
      ResultList.Add(Item);
    end;
    
    // 转换为数组
    SetLength(Result, ResultList.Count);
    for var I := 0 to ResultList.Count - 1 do
      Result[I] := ResultList[I];
      
  finally
    ResultList.Free;
  end;
end;f
unction TMigrationPlanGenerator.DetermineOptimalStrategy(const AFilePath: string): TMigrationStrategy;
var
  Classification: TFileClassificationResult;
  SafetyResult: TFileSafetyResult;
  DefaultStrategy: TMigrationStrategy;
begin
  // 分类文件
  Classification := FFileClassifier.ClassifyFile(AFilePath);
  
  // 获取默认策略
  if FDefaultStrategies.TryGetValue(Classification.Category, DefaultStrategy) then
    Result := DefaultStrategy
  else
    Result := msMove; // 默认移动
  
  // 根据安全评估调整策略
  SafetyResult := FSafetyEvaluator.EvaluateFileSafety(AFilePath);
  
  case SafetyResult.SafetyLevel of
    fslCritical:
      begin
        // 关键文件跳过或使用符号链接
        if Result = msMove then
          Result := msSymbolicLink
        else if Result = msDelete then
          Result := msSkip;
      end;
    fslDangerous:
      begin
        // 危险文件使用复制而不是移动
        if Result = msMove then
          Result := msCopy;
      end;
    fslSafe:
      begin
        // 安全文件可以删除临时和缓存文件
        if (Classification.Category = fcTemporaryFile) or 
           (Classification.Category = fcCacheFile) then
          Result := msDelete;
      end;
  end;
  
  // 根据文件大小调整策略
  try
    var FileSize := TFile.GetSize(AFilePath);
    
    // 大文件（>1GB）优先使用硬链接或符号链接
    if (FileSize > 1024 * 1024 * 1024) and (Result = msMove) then
    begin
      if Classification.Category = fcMediaFile then
        Result := msHardLink
      else
        Result := msSymbolicLink;
    end;
    
    // 小文件（<1KB）直接复制
    if (FileSize < 1024) and (Result = msSymbolicLink) then
      Result := msCopy;
      
  except
    // 无法获取文件大小，保持原策略
  end;
end;

function TMigrationPlanGenerator.CalculatePriority(const AFilePath: string; 
  const AStrategy: TMigrationStrategy): TMigrationPriority;
var
  Classification: TFileClassificationResult;
  SafetyResult: TFileSafetyResult;
  DefaultPriority: TMigrationPriority;
begin
  // 分类文件
  Classification := FFileClassifier.ClassifyFile(AFilePath);
  
  // 获取默认优先级
  if FPriorityRules.TryGetValue(Classification.Category, DefaultPriority) then
    Result := DefaultPriority
  else
    Result := mpNormal;
  
  // 根据安全级别调整优先级
  SafetyResult := FSafetyEvaluator.EvaluateFileSafety(AFilePath);
  
  case SafetyResult.SafetyLevel of
    fslCritical:
      Result := mpCritical;
    fslDangerous:
      if Result < mpHigh then
        Result := mpHigh;
  end;
  
  // 根据策略调整优先级
  case AStrategy of
    msDelete:
      if Result > mpLow then
        Result := mpLow; // 删除操作降低优先级
    msSkip:
      Result := mpLow; // 跳过操作最低优先级
    msSymbolicLink, msHardLink:
      if Result < mpHigh then
        Result := mpHigh; // 链接操作提高优先级
  end;
end;

function TMigrationPlanGenerator.AssignPhase(const AStrategy: TMigrationStrategy; 
  const APriority: TMigrationPriority): TMigrationPhase;
var
  DefaultPhase: TMigrationPhase;
begin
  // 获取默认阶段
  if FPhaseRules.TryGetValue(AStrategy, DefaultPhase) then
    Result := DefaultPhase
  else
    Result := mpExecution;
  
  // 根据优先级调整阶段
  case APriority of
    mpCritical:
      begin
        // 关键优先级在分析阶段处理
        if Result = mpExecution then
          Result := mpAnalysis;
      end;
    mpLow:
      begin
        // 低优先级在清理阶段处理
        if (Result = mpExecution) and (AStrategy = msDelete) then
          Result := mpCleanup;
      end;
  end;
end;

function TMigrationPlanGenerator.EstimateTransferTime(const AFilePath: string; 
  const AStrategy: TMigrationStrategy): Integer;
var
  FileSize: Int64;
  BaseTime: Integer;
begin
  Result := 1; // 最少1秒
  
  try
    if FileExists(AFilePath) then
      FileSize := TFile.GetSize(AFilePath)
    else
      FileSize := 0;
  except
    FileSize := 0;
  end;
  
  // 基础时间计算（假设传输速度100MB/s）
  if FileSize > 0 then
    BaseTime := Max(1, FileSize div (100 * 1024 * 1024))
  else
    BaseTime := 1;
  
  // 根据策略调整时间
  case AStrategy of
    msMove:
      Result := BaseTime; // 移动时间
    msCopy:
      Result := BaseTime * 2; // 复制需要更多时间
    msSymbolicLink, msHardLink:
      Result := 1; // 链接操作很快
    msDelete:
      Result := 1; // 删除操作很快
    msSkip:
      Result := 0; // 跳过不需要时间
  end;
  
  // 添加系统开销
  Result := Result + 1;
end;

function TMigrationPlanGenerator.CalculateRiskLevel(const AFilePath: string; 
  const AStrategy: TMigrationStrategy): Integer;
var
  SafetyResult: TFileSafetyResult;
  RebootResult: TRebootDetectionResult;
  DependencyResult: TDependencyAnalysisResult;
  Risk: Integer;
begin
  Risk := 0;
  
  // 基于安全评估的风险
  SafetyResult := FSafetyEvaluator.EvaluateFileSafety(AFilePath);
  Risk := Risk + (100 - SafetyResult.SafetyScore);
  
  // 基于重启需求的风险
  RebootResult := FRebootDetector.DetectRebootRequirement(AFilePath);
  case RebootResult.RequiresReboot of
    rrRecommended: Risk := Risk + 10;
    rrRequired: Risk := Risk + 20;
    rrCritical: Risk := Risk + 40;
  end;
  
  // 基于依赖关系的风险
  DependencyResult := FDependencyAnalyzer.AnalyzeFileDependencies(AFilePath);
  Risk := Risk + (DependencyResult.CriticalDependencies * 5);
  
  // 基于策略的风险
  case AStrategy of
    msMove: Risk := Risk + 10;
    msDelete: Risk := Risk + 20;
    msCopy: Risk := Risk + 5;
    msSymbolicLink, msHardLink: Risk := Risk + 15;
    msSkip: Risk := Risk + 0;
  end;
  
  // 限制在0-100范围内
  Result := Max(0, Min(100, Risk));
end;

function TMigrationPlanGenerator.CalculateRequiredSpace(const AItems: TArray<TMigrationItem>): Int64;
begin
  Result := 0;
  
  for var Item in AItems do
  begin
    case Item.Strategy of
      msMove, msSymbolicLink, msHardLink:
        // 移动和链接不需要额外空间
        Continue;
      msCopy:
        // 复制需要完整空间
        Result := Result + Item.FileSize;
      msDelete, msSkip:
        // 删除和跳过不需要空间
        Continue;
    end;
  end;
end;

function TMigrationPlanGenerator.GetAvailableSpace(const ATargetPath: string): Int64;
var
  FreeBytes, TotalBytes: Int64;
  DrivePath: string;
begin
  Result := 0;
  
  try
    // 获取目标路径的驱动器
    DrivePath := ExtractFileDrive(ATargetPath);
    if DrivePath = '' then
      DrivePath := ExtractFileDrive(GetCurrentDir);
    
    if DrivePath <> '' then
    begin
      if GetDiskFreeSpaceEx(PChar(DrivePath), FreeBytes, TotalBytes, nil) then
        Result := FreeBytes;
    end;
  except
    Result := 0;
  end;
end;fu
nction TMigrationPlanGenerator.AnalyzeSpaceUtilization(const ASourcePath, ATargetPath: string; 
  const ARequiredSpace: Int64): TSpaceAnalysisResult;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  Result.SourcePath := ASourcePath;
  Result.TargetPath := ATargetPath;
  Result.RequiredSpace := ARequiredSpace;
  Result.AvailableSpace := GetAvailableSpace(ATargetPath);
  Result.FreeSpaceAfter := Result.AvailableSpace - ARequiredSpace;
  
  if Result.AvailableSpace > 0 then
    Result.SpaceUtilization := (ARequiredSpace / Result.AvailableSpace) * 100
  else
    Result.SpaceUtilization := 0;
  
  Result.IsSpaceSufficient := Result.FreeSpaceAfter > 0;
  
  // 生成清理建议
  var CleanupList := TList<string>.Create;
  try
    if not Result.IsSpaceSufficient then
    begin
      CleanupList.Add('清理回收站以释放空间');
      CleanupList.Add('删除临时文件');
      CleanupList.Add('清理系统缓存');
      CleanupList.Add('卸载不需要的程序');
    end;
    
    SetLength(Result.RecommendedCleanup, CleanupList.Count);
    for var I := 0 to CleanupList.Count - 1 do
      Result.RecommendedCleanup[I] := CleanupList[I];
      
  finally
    CleanupList.Free;
  end;
  
  // 生成优化建议
  var OptimizationList := TList<string>.Create;
  try
    OptimizationList.Add('使用符号链接减少空间占用');
    OptimizationList.Add('压缩大文件以节省空间');
    OptimizationList.Add('分批迁移以减少峰值空间需求');
    
    SetLength(Result.SpaceOptimizations, OptimizationList.Count);
    for var I := 0 to OptimizationList.Count - 1 do
      Result.SpaceOptimizations[I] := OptimizationList[I];
      
  finally
    OptimizationList.Free;
  end;
end;

function TMigrationPlanGenerator.ResolveDependencies(var AItems: TArray<TMigrationItem>): Boolean;
var
  I, J: Integer;
  DependencyFound: Boolean;
begin
  Result := True;
  
  // 验证依赖关系的完整性
  for I := 0 to Length(AItems) - 1 do
  begin
    for var Dependency in AItems[I].Dependencies do
    begin
      DependencyFound := False;
      
      for J := 0 to Length(AItems) - 1 do
      begin
        if SameText(AItems[J].SourcePath, Dependency) then
        begin
          DependencyFound := True;
          Break;
        end;
      end;
      
      if not DependencyFound then
      begin
        // 依赖项不在迁移列表中，可能需要特殊处理
        // 这里简化处理，记录但不阻止迁移
      end;
    end;
  end;
end;

function TMigrationPlanGenerator.SortByDependencies(const AItems: TArray<TMigrationItem>): TArray<TMigrationItem>;
var
  SortedList: TList<TMigrationItem>;
  ProcessedPaths: TStringList;
  
  procedure AddItemWithDependencies(const AItem: TMigrationItem);
  var
    I: Integer;
  begin
    // 如果已经处理过，跳过
    if ProcessedPaths.IndexOf(AItem.SourcePath) >= 0 then
      Exit;
    
    // 先处理依赖项
    for var Dependency in AItem.Dependencies do
    begin
      for I := 0 to Length(AItems) - 1 do
      begin
        if SameText(AItems[I].SourcePath, Dependency) then
        begin
          AddItemWithDependencies(AItems[I]);
          Break;
        end;
      end;
    end;
    
    // 添加当前项
    SortedList.Add(AItem);
    ProcessedPaths.Add(AItem.SourcePath);
  end;

begin
  SortedList := TList<TMigrationItem>.Create;
  ProcessedPaths := TStringList.Create;
  
  try
    // 按依赖关系递归添加
    for var Item in AItems do
      AddItemWithDependencies(Item);
    
    // 转换为数组
    SetLength(Result, SortedList.Count);
    for var I := 0 to SortedList.Count - 1 do
      Result[I] := SortedList[I];
      
  finally
    SortedList.Free;
    ProcessedPaths.Free;
  end;
end;

function TMigrationPlanGenerator.ValidateDependencyChain(const AItems: TArray<TMigrationItem>): Boolean;
var
  ItemPaths: TStringList;
  I, J: Integer;
begin
  Result := True;
  ItemPaths := TStringList.Create;
  
  try
    // 收集所有项目路径
    for var Item in AItems do
      ItemPaths.Add(Item.SourcePath);
    
    // 验证每个依赖项是否存在
    for I := 0 to Length(AItems) - 1 do
    begin
      for var Dependency in AItems[I].Dependencies do
      begin
        if ItemPaths.IndexOf(Dependency) < 0 then
        begin
          // 依赖项不在列表中
          Result := False;
          Break;
        end;
      end;
      
      if not Result then
        Break;
    end;
    
  finally
    ItemPaths.Free;
  end;
end;f
unction TMigrationPlanGenerator.OptimizePlan(var APlan: TMigrationPlan): Boolean;
var
  PhaseGroups: TDictionary<TMigrationPhase, TArray<TMigrationItem>>;
  OptimizedItems: TList<TMigrationItem>;
begin
  Result := True;
  
  try
    // 按阶段分组
    PhaseGroups := GroupByPhase(APlan.Items);
    OptimizedItems := TList<TMigrationItem>.Create;
    
    try
      // 按阶段顺序重新组织
      var Phases: TArray<TMigrationPhase> := [mpPreparation, mpAnalysis, mpExecution, mpVerification, mpCleanup];
      
      for var Phase in Phases do
      begin
        if PhaseGroups.ContainsKey(Phase) then
        begin
          var PhaseItems := PhaseGroups[Phase];
          
          // 在每个阶段内按优先级排序
          TArray.Sort<TMigrationItem>(PhaseItems, TComparer<TMigrationItem>.Construct(
            function(const Left, Right: TMigrationItem): Integer
            begin
              Result := Ord(Right.Priority) - Ord(Left.Priority); // 高优先级在前
            end));
          
          // 添加到优化列表
          for var Item in PhaseItems do
            OptimizedItems.Add(Item);
        end;
      end;
      
      // 更新计划
      SetLength(APlan.Items, OptimizedItems.Count);
      for var I := 0 to OptimizedItems.Count - 1 do
        APlan.Items[I] := OptimizedItems[I];
      
      // 负载均衡
      BalanceLoad(APlan.Items);
      
    finally
      OptimizedItems.Free;
      PhaseGroups.Free;
    end;
    
  except
    Result := False;
  end;
end;

function TMigrationPlanGenerator.GroupByPhase(const AItems: TArray<TMigrationItem>): TDictionary<TMigrationPhase, TArray<TMigrationItem>>;
var
  PhaseMap: TDictionary<TMigrationPhase, TList<TMigrationItem>>;
  Phase: TMigrationPhase;
  ItemList: TList<TMigrationItem>;
begin
  Result := TDictionary<TMigrationPhase, TArray<TMigrationItem>>.Create;
  PhaseMap := TDictionary<TMigrationPhase, TList<TMigrationItem>>.Create;
  
  try
    // 初始化阶段列表
    for Phase := Low(TMigrationPhase) to High(TMigrationPhase) do
      PhaseMap.Add(Phase, TList<TMigrationItem>.Create);
    
    // 按阶段分组
    for var Item in AItems do
    begin
      if PhaseMap.TryGetValue(Item.Phase, ItemList) then
        ItemList.Add(Item);
    end;
    
    // 转换为数组字典
    for Phase in PhaseMap.Keys do
    begin
      ItemList := PhaseMap[Phase];
      var ItemArray: TArray<TMigrationItem>;
      SetLength(ItemArray, ItemList.Count);
      
      for var I := 0 to ItemList.Count - 1 do
        ItemArray[I] := ItemList[I];
      
      Result.Add(Phase, ItemArray);
    end;
    
  finally
    // 清理临时列表
    for ItemList in PhaseMap.Values do
      ItemList.Free;
    PhaseMap.Free;
  end;
end;

function TMigrationPlanGenerator.BalanceLoad(var AItems: TArray<TMigrationItem>): Boolean;
var
  I: Integer;
  TotalTime, AverageTime: Integer;
  CurrentBatch: TList<TMigrationItem>;
  BatchTime: Integer;
begin
  Result := True;
  
  try
    // 计算总时间和平均时间
    TotalTime := 0;
    for var Item in AItems do
      TotalTime := TotalTime + Item.EstimatedTime;
    
    if Length(AItems) > 0 then
      AverageTime := TotalTime div Length(AItems)
    else
      AverageTime := 0;
    
    // 简单的负载均衡：确保没有单个项目占用过多时间
    for I := 0 to Length(AItems) - 1 do
    begin
      if AItems[I].EstimatedTime > AverageTime * 3 then
      begin
        // 对于耗时过长的项目，可以考虑分批处理
        // 这里简化处理，只是标记
        AItems[I].Description := AItems[I].Description + ' [大文件]';
      end;
    end;
    
  except
    Result := False;
  end;
end;

function TMigrationPlanGenerator.AssessOverallRisk(const AItems: TArray<TMigrationItem>): string;
var
  TotalRisk, HighRiskCount, CriticalCount: Integer;
  AverageRisk: Double;
begin
  TotalRisk := 0;
  HighRiskCount := 0;
  CriticalCount := 0;
  
  for var Item in AItems do
  begin
    TotalRisk := TotalRisk + Item.RiskLevel;
    
    if Item.RiskLevel > 70 then
      Inc(HighRiskCount);
    
    if Item.Priority = mpCritical then
      Inc(CriticalCount);
  end;
  
  if Length(AItems) > 0 then
    AverageRisk := TotalRisk / Length(AItems)
  else
    AverageRisk := 0;
  
  // 生成风险评估报告
  if AverageRisk < 30 then
    Result := Format('低风险迁移 (平均风险: %.1f%%, 高风险项目: %d)', [AverageRisk, HighRiskCount])
  else if AverageRisk < 60 then
    Result := Format('中等风险迁移 (平均风险: %.1f%%, 高风险项目: %d)', [AverageRisk, HighRiskCount])
  else
    Result := Format('高风险迁移 (平均风险: %.1f%%, 高风险项目: %d, 关键项目: %d)', 
      [AverageRisk, HighRiskCount, CriticalCount]);
end;

function TMigrationPlanGenerator.GeneratePrerequisites(const AItems: TArray<TMigrationItem>): TArray<string>;
var
  PrereqList: TList<string>;
  HasSystemFiles, HasLargeFiles, HasCriticalFiles: Boolean;
begin
  PrereqList := TList<string>.Create;
  try
    HasSystemFiles := False;
    HasLargeFiles := False;
    HasCriticalFiles := False;
    
    // 分析项目特征
    for var Item in AItems do
    begin
      if Item.Priority = mpCritical then
        HasCriticalFiles := True;
      
      if Item.FileSize > 1024 * 1024 * 1024 then // > 1GB
        HasLargeFiles := True;
      
      if Item.Strategy = msSymbolicLink then
        HasSystemFiles := True;
    end;
    
    // 生成前置条件
    PrereqList.Add('确保目标磁盘有足够的可用空间');
    PrereqList.Add('关闭所有可能使用目标文件的应用程序');
    PrereqList.Add('创建系统还原点');
    
    if HasCriticalFiles then
    begin
      PrereqList.Add('以管理员权限运行迁移程序');
      PrereqList.Add('备份重要的系统配置文件');
    end;
    
    if HasLargeFiles then
    begin
      PrereqList.Add('确保网络连接稳定（如果涉及网络存储）');
      PrereqList.Add('预留足够的时间完成大文件传输');
    end;
    
    if HasSystemFiles then
    begin
      PrereqList.Add('确认目标位置支持符号链接');
      PrereqList.Add('检查文件系统兼容性');
    end;
    
    // 转换为数组
    SetLength(Result, PrereqList.Count);
    for var I := 0 to PrereqList.Count - 1 do
      Result[I] := PrereqList[I];
      
  finally
    PrereqList.Free;
  end;
end;fun
ction TMigrationPlanGenerator.GeneratePostActions(const AItems: TArray<TMigrationItem>): TArray<string>;
var
  ActionList: TList<string>;
  HasRebootItems, HasRegistryChanges, HasServiceChanges: Boolean;
begin
  ActionList := TList<string>.Create;
  try
    HasRebootItems := False;
    HasRegistryChanges := False;
    HasServiceChanges := False;
    
    // 分析后续操作需求
    for var Item in AItems do
    begin
      if Item.RequiresReboot then
        HasRebootItems := True;
      
      if Length(Item.Dependencies) > 0 then
      begin
        for var Dependency in Item.Dependencies do
        begin
          if ContainsText(Dependency, 'REGISTRY') then
            HasRegistryChanges := True;
          if ContainsText(Dependency, 'SERVICE') then
            HasServiceChanges := True;
        end;
      end;
    end;
    
    // 生成后续操作
    ActionList.Add('验证所有文件已正确迁移到目标位置');
    ActionList.Add('更新应用程序配置中的文件路径');
    ActionList.Add('测试相关应用程序的正常运行');
    
    if HasRegistryChanges then
    begin
      ActionList.Add('更新注册表中的文件路径引用');
      ActionList.Add('刷新系统注册表缓存');
    end;
    
    if HasServiceChanges then
    begin
      ActionList.Add('重启相关的系统服务');
      ActionList.Add('验证服务正常运行');
    end;
    
    if HasRebootItems then
    begin
      ActionList.Add('重启系统以完成所有更改');
      ActionList.Add('重启后验证系统稳定性');
    end;
    
    ActionList.Add('清理临时文件和备份');
    ActionList.Add('更新系统索引和搜索数据库');
    
    // 转换为数组
    SetLength(Result, ActionList.Count);
    for var I := 0 to ActionList.Count - 1 do
      Result[I] := ActionList[I];
      
  finally
    ActionList.Free;
  end;
end;

function TMigrationPlanGenerator.GenerateRollbackPlan(const AItems: TArray<TMigrationItem>): TArray<string>;
var
  RollbackList: TList<string>;
begin
  RollbackList := TList<string>.Create;
  try
    // 生成回退计划
    RollbackList.Add('停止所有正在进行的迁移操作');
    RollbackList.Add('从备份恢复原始文件位置');
    RollbackList.Add('恢复注册表备份');
    RollbackList.Add('重启相关服务到原始状态');
    RollbackList.Add('删除已创建的符号链接和硬链接');
    RollbackList.Add('恢复原始目录结构');
    RollbackList.Add('验证系统功能正常');
    RollbackList.Add('如果需要，使用系统还原点恢复');
    
    // 转换为数组
    SetLength(Result, RollbackList.Count);
    for var I := 0 to RollbackList.Count - 1 do
      Result[I] := RollbackList[I];
      
  finally
    RollbackList.Free;
  end;
end;

// 可行性评估方法
function TMigrationPlanGenerator.EvaluateFeasibility(const ASourcePath, ATargetPath: string): TFeasibilityResult;
var
  SpaceAnalysis: TSpaceAnalysisResult;
  BlockingList, WarningList, RecommendList, RiskList, MitigationList: TList<string>;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  Result.IsFeasible := True;
  Result.ConfidenceLevel := 80; // 默认80%信心
  Result.EstimatedSuccessRate := 85; // 默认85%成功率
  
  BlockingList := TList<string>.Create;
  WarningList := TList<string>.Create;
  RecommendList := TList<string>.Create;
  RiskList := TList<string>.Create;
  MitigationList := TList<string>.Create;
  
  try
    // 检查源目录
    if not DirectoryExists(ASourcePath) then
    begin
      BlockingList.Add('源目录不存在');
      Result.IsFeasible := False;
      Result.ConfidenceLevel := 0;
    end;
    
    // 检查目标目录
    if not DirectoryExists(ExtractFilePath(ATargetPath)) then
    begin
      WarningList.Add('目标目录不存在，需要创建');
      Result.ConfidenceLevel := Result.ConfidenceLevel - 10;
    end;
    
    // 空间分析
    SpaceAnalysis := AnalyzeSpaceRequirements(ASourcePath, ATargetPath);
    if not SpaceAnalysis.IsSpaceSufficient then
    begin
      BlockingList.Add('目标磁盘空间不足');
      Result.IsFeasible := False;
      Result.ConfidenceLevel := Result.ConfidenceLevel - 30;
    end;
    
    // 权限检查
    try
      var TestFile := ATargetPath + '\test_write_permission.tmp';
      TFile.WriteAllText(TestFile, 'test');
      DeleteFile(TestFile);
    except
      WarningList.Add('目标目录可能没有写入权限');
      Result.ConfidenceLevel := Result.ConfidenceLevel - 15;
    end;
    
    // 文件系统兼容性
    var SourceDrive := ExtractFileDrive(ASourcePath);
    var TargetDrive := ExtractFileDrive(ATargetPath);
    
    if not SameText(SourceDrive, TargetDrive) then
    begin
      WarningList.Add('跨驱动器迁移可能需要更多时间');
      Result.ConfidenceLevel := Result.ConfidenceLevel - 5;
    end;
    
    // 生成建议
    RecommendList.Add('在迁移前创建完整备份');
    RecommendList.Add('在非高峰时间执行迁移');
    RecommendList.Add('分批执行大规模迁移');
    
    // 风险因素
    RiskList.Add('文件可能正在被其他程序使用');
    RiskList.Add('系统文件迁移可能影响系统稳定性');
    RiskList.Add('网络中断可能导致迁移失败');
    
    // 缓解策略
    MitigationList.Add('使用文件锁检测避免冲突');
    MitigationList.Add('创建系统还原点');
    MitigationList.Add('实施断点续传机制');
    
    // 转换为数组
    SetLength(Result.BlockingIssues, BlockingList.Count);
    for var I := 0 to BlockingList.Count - 1 do
      Result.BlockingIssues[I] := BlockingList[I];
    
    SetLength(Result.Warnings, WarningList.Count);
    for var I := 0 to WarningList.Count - 1 do
      Result.Warnings[I] := WarningList[I];
    
    SetLength(Result.Recommendations, RecommendList.Count);
    for var I := 0 to RecommendList.Count - 1 do
      Result.Recommendations[I] := RecommendList[I];
    
    SetLength(Result.RiskFactors, RiskList.Count);
    for var I := 0 to RiskList.Count - 1 do
      Result.RiskFactors[I] := RiskList[I];
    
    SetLength(Result.MitigationStrategies, MitigationList.Count);
    for var I := 0 to MitigationList.Count - 1 do
      Result.MitigationStrategies[I] := MitigationList[I];
    
    // 调整成功率
    if not Result.IsFeasible then
      Result.EstimatedSuccessRate := 0
    else if Result.ConfidenceLevel < 50 then
      Result.EstimatedSuccessRate := 30
    else if Result.ConfidenceLevel < 70 then
      Result.EstimatedSuccessRate := 60;
    
  finally
    BlockingList.Free;
    WarningList.Free;
    RecommendList.Free;
    RiskList.Free;
    MitigationList.Free;
  end;
end;// 
空间分析和计划管理方法
function TMigrationPlanGenerator.AnalyzeSpaceRequirements(const ASourcePath, ATargetPath: string): TSpaceAnalysisResult;
var
  RequiredSpace: Int64;
begin
  // 计算源目录大小
  RequiredSpace := 0;
  
  try
    var Files := TDirectory.GetFiles(ASourcePath, '*', TSearchOption.soAllDirectories);
    for var FilePath in Files do
    begin
      try
        RequiredSpace := RequiredSpace + TFile.GetSize(FilePath);
      except
        // 忽略无法访问的文件
      end;
    end;
  except
    RequiredSpace := 0;
  end;
  
  Result := AnalyzeSpaceUtilization(ASourcePath, ATargetPath, RequiredSpace);
end;

function TMigrationPlanGenerator.ValidateSpaceAvailability(const ATargetPath: string; const ARequiredSpace: Int64): Boolean;
var
  AvailableSpace: Int64;
begin
  AvailableSpace := GetAvailableSpace(ATargetPath);
  Result := AvailableSpace >= ARequiredSpace;
end;

function TMigrationPlanGenerator.GetSpaceOptimizationSuggestions(const ATargetPath: string): TArray<string>;
var
  SuggestionList: TList<string>;
begin
  SuggestionList := TList<string>.Create;
  try
    SuggestionList.Add('使用符号链接代替文件复制');
    SuggestionList.Add('压缩大型媒体文件');
    SuggestionList.Add('删除重复文件');
    SuggestionList.Add('清理临时文件和缓存');
    SuggestionList.Add('移动到外部存储设备');
    SuggestionList.Add('使用云存储服务');
    
    SetLength(Result, SuggestionList.Count);
    for var I := 0 to SuggestionList.Count - 1 do
      Result[I] := SuggestionList[I];
      
  finally
    SuggestionList.Free;
  end;
end;

function TMigrationPlanGenerator.ValidateMigrationPlan(const APlan: TMigrationPlan): TFeasibilityResult;
begin
  // 基于现有计划进行可行性评估
  Result := EvaluateFeasibility(APlan.SourceDirectory, APlan.TargetDirectory);
  
  // 根据计划内容调整评估
  if APlan.TotalItems = 0 then
  begin
    Result.IsFeasible := False;
    SetLength(Result.BlockingIssues, 1);
    Result.BlockingIssues[0] := '迁移计划为空';
  end;
  
  if APlan.RequiredSpace > APlan.AvailableSpace then
  begin
    Result.IsFeasible := False;
    var NewBlockingIssues: TArray<string>;
    SetLength(NewBlockingIssues, Length(Result.BlockingIssues) + 1);
    for var I := 0 to Length(Result.BlockingIssues) - 1 do
      NewBlockingIssues[I] := Result.BlockingIssues[I];
    NewBlockingIssues[Length(Result.BlockingIssues)] := '所需空间超过可用空间';
    Result.BlockingIssues := NewBlockingIssues;
  end;
end;

function TMigrationPlanGenerator.EstimateSuccessRate(const APlan: TMigrationPlan): Integer;
var
  BaseRate, RiskPenalty, ComplexityPenalty: Integer;
  HighRiskCount: Integer;
begin
  BaseRate := 90; // 基础成功率90%
  
  // 计算高风险项目数量
  HighRiskCount := 0;
  for var Item in APlan.Items do
  begin
    if Item.RiskLevel > 70 then
      Inc(HighRiskCount);
  end;
  
  // 风险惩罚
  RiskPenalty := HighRiskCount * 5;
  
  // 复杂度惩罚
  ComplexityPenalty := 0;
  if APlan.TotalItems > 1000 then
    ComplexityPenalty := ComplexityPenalty + 10;
  if APlan.TotalSize > 100 * 1024 * 1024 * 1024 then // > 100GB
    ComplexityPenalty := ComplexityPenalty + 10;
  
  Result := Max(0, Min(100, BaseRate - RiskPenalty - ComplexityPenalty));
end;

function TMigrationPlanGenerator.SavePlan(const APlan: TMigrationPlan; const AFilePath: string): Boolean;
var
  JSONObj, ItemObj: TJSONObject;
  ItemsArray: TJSONArray;
begin
  Result := False;
  
  try
    JSONObj := TJSONObject.Create;
    try
      // 基本信息
      JSONObj.AddPair('PlanName', APlan.PlanName);
      JSONObj.AddPair('CreatedTime', DateTimeToStr(APlan.CreatedTime));
      JSONObj.AddPair('SourceDirectory', APlan.SourceDirectory);
      JSONObj.AddPair('TargetDirectory', APlan.TargetDirectory);
      JSONObj.AddPair('TotalItems', TJSONNumber.Create(APlan.TotalItems));
      JSONObj.AddPair('TotalSize', TJSONNumber.Create(APlan.TotalSize));
      JSONObj.AddPair('EstimatedDuration', TJSONNumber.Create(APlan.EstimatedDuration));
      JSONObj.AddPair('RiskAssessment', APlan.RiskAssessment);
      
      // 迁移项目
      ItemsArray := TJSONArray.Create;
      for var Item in APlan.Items do
      begin
        ItemObj := TJSONObject.Create;
        ItemObj.AddPair('SourcePath', Item.SourcePath);
        ItemObj.AddPair('TargetPath', Item.TargetPath);
        ItemObj.AddPair('Strategy', StrategyToString(Item.Strategy));
        ItemObj.AddPair('Priority', PriorityToString(Item.Priority));
        ItemObj.AddPair('Phase', PhaseToString(Item.Phase));
        ItemObj.AddPair('FileSize', TJSONNumber.Create(Item.FileSize));
        ItemObj.AddPair('EstimatedTime', TJSONNumber.Create(Item.EstimatedTime));
        ItemObj.AddPair('RequiresReboot', TJSONBool.Create(Item.RequiresReboot));
        ItemObj.AddPair('RiskLevel', TJSONNumber.Create(Item.RiskLevel));
        ItemObj.AddPair('Description', Item.Description);
        ItemObj.AddPair('BackupRequired', TJSONBool.Create(Item.BackupRequired));
        ItemObj.AddPair('VerificationMethod', Item.VerificationMethod);
        
        ItemsArray.AddElement(ItemObj);
      end;
      JSONObj.AddPair('Items', ItemsArray);
      
      // 保存到文件
      TFile.WriteAllText(AFilePath, JSONObj.ToString, TEncoding.UTF8);
      Result := True;
      
    finally
      JSONObj.Free;
    end;
    
  except
    Result := False;
  end;
end;

function TMigrationPlanGenerator.LoadPlan(const AFilePath: string): TMigrationPlan;
var
  JSONText: string;
  JSONObj, ItemObj: TJSONObject;
  ItemsArray: TJSONArray;
  Item: TMigrationItem;
  I: Integer;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  
  if not FileExists(AFilePath) then
    Exit;
  
  try
    JSONText := TFile.ReadAllText(AFilePath, TEncoding.UTF8);
    JSONObj := TJSONObject.ParseJSONValue(JSONText) as TJSONObject;
    
    if JSONObj <> nil then
    begin
      try
        // 读取基本信息
        Result.PlanName := JSONObj.GetValue('PlanName').Value;
        Result.CreatedTime := StrToDateTime(JSONObj.GetValue('CreatedTime').Value);
        Result.SourceDirectory := JSONObj.GetValue('SourceDirectory').Value;
        Result.TargetDirectory := JSONObj.GetValue('TargetDirectory').Value;
        Result.TotalItems := (JSONObj.GetValue('TotalItems') as TJSONNumber).AsInt;
        Result.TotalSize := (JSONObj.GetValue('TotalSize') as TJSONNumber).AsInt64;
        Result.EstimatedDuration := (JSONObj.GetValue('EstimatedDuration') as TJSONNumber).AsInt;
        Result.RiskAssessment := JSONObj.GetValue('RiskAssessment').Value;
        
        // 读取迁移项目
        ItemsArray := JSONObj.GetValue('Items') as TJSONArray;
        SetLength(Result.Items, ItemsArray.Count);
        
        for I := 0 to ItemsArray.Count - 1 do
        begin
          ItemObj := ItemsArray.Items[I] as TJSONObject;
          
          FillChar(Item, SizeOf(Item), 0);
          Item.SourcePath := ItemObj.GetValue('SourcePath').Value;
          Item.TargetPath := ItemObj.GetValue('TargetPath').Value;
          Item.FileSize := (ItemObj.GetValue('FileSize') as TJSONNumber).AsInt64;
          Item.EstimatedTime := (ItemObj.GetValue('EstimatedTime') as TJSONNumber).AsInt;
          Item.RequiresReboot := (ItemObj.GetValue('RequiresReboot') as TJSONBool).AsBoolean;
          Item.RiskLevel := (ItemObj.GetValue('RiskLevel') as TJSONNumber).AsInt;
          Item.Description := ItemObj.GetValue('Description').Value;
          Item.BackupRequired := (ItemObj.GetValue('BackupRequired') as TJSONBool).AsBoolean;
          Item.VerificationMethod := ItemObj.GetValue('VerificationMethod').Value;
          
          Result.Items[I] := Item;
        end;
        
      finally
        JSONObj.Free;
      end;
    end;
    
  except
    // 加载失败，返回空计划
    FillChar(Result, SizeOf(Result), 0);
  end;
end;fun
ction TMigrationPlanGenerator.ComparePlans(const APlan1, APlan2: TMigrationPlan): string;
var
  ComparisonList: TList<string>;
begin
  ComparisonList := TList<string>.Create;
  try
    ComparisonList.Add('=== 迁移计划对比 ===');
    ComparisonList.Add('');
    
    // 基本信息对比
    ComparisonList.Add(Format('计划名称: %s vs %s', [APlan1.PlanName, APlan2.PlanName]));
    ComparisonList.Add(Format('项目数量: %d vs %d', [APlan1.TotalItems, APlan2.TotalItems]));
    ComparisonList.Add(Format('总大小: %s vs %s', [FormatFileSize(APlan1.TotalSize), FormatFileSize(APlan2.TotalSize)]));
    ComparisonList.Add(Format('预计时间: %s vs %s', [FormatDuration(APlan1.EstimatedDuration), FormatDuration(APlan2.EstimatedDuration)]));
    ComparisonList.Add(Format('空间利用率: %.1f%% vs %.1f%%', [APlan1.SpaceUtilization, APlan2.SpaceUtilization]));
    ComparisonList.Add('');
    
    // 风险评估对比
    ComparisonList.Add('风险评估:');
    ComparisonList.Add('  计划1: ' + APlan1.RiskAssessment);
    ComparisonList.Add('  计划2: ' + APlan2.RiskAssessment);
    ComparisonList.Add('');
    
    // 推荐选择
    var RecommendedPlan: Integer;
    if APlan1.TotalItems < APlan2.TotalItems then
      RecommendedPlan := 1
    else if APlan1.EstimatedDuration < APlan2.EstimatedDuration then
      RecommendedPlan := 1
    else
      RecommendedPlan := 2;
    
    ComparisonList.Add(Format('推荐选择: 计划%d', [RecommendedPlan]));
    
    Result := string.Join(sLineBreak, ComparisonList.ToArray);
    
  finally
    ComparisonList.Free;
  end;
end;

function TMigrationPlanGenerator.GenerateCustomPlan(const ASourcePath, ATargetPath: string; 
  const ACustomRules: TDictionary<string, TMigrationStrategy>): TMigrationPlan;
begin
  // 临时保存原始规则
  var OriginalStrategies := TDictionary<TFileCategory, TMigrationStrategy>.Create;
  try
    for var Pair in FDefaultStrategies do
      OriginalStrategies.Add(Pair.Key, Pair.Value);
    
    // 应用自定义规则（这里简化处理，实际需要更复杂的映射）
    // 生成计划
    Result := GenerateMigrationPlan(ASourcePath, ATargetPath);
    
    // 恢复原始规则
    FDefaultStrategies.Clear;
    for var Pair in OriginalStrategies do
      FDefaultStrategies.Add(Pair.Key, Pair.Value);
      
  finally
    OriginalStrategies.Free;
  end;
end;

// 工具方法
class function TMigrationPlanGenerator.StrategyToString(AStrategy: TMigrationStrategy): string;
begin
  case AStrategy of
    msMove: Result := '移动';
    msCopy: Result := '复制';
    msSymbolicLink: Result := '符号链接';
    msHardLink: Result := '硬链接';
    msSkip: Result := '跳过';
    msDelete: Result := '删除';
  else
    Result := '未知';
  end;
end;

class function TMigrationPlanGenerator.PriorityToString(APriority: TMigrationPriority): string;
begin
  case APriority of
    mpLow: Result := '低';
    mpNormal: Result := '普通';
    mpHigh: Result := '高';
    mpCritical: Result := '关键';
  else
    Result := '未知';
  end;
end;

class function TMigrationPlanGenerator.PhaseToString(APhase: TMigrationPhase): string;
begin
  case APhase of
    mpPreparation: Result := '准备阶段';
    mpAnalysis: Result := '分析阶段';
    mpExecution: Result := '执行阶段';
    mpVerification: Result := '验证阶段';
    mpCleanup: Result := '清理阶段';
  else
    Result := '未知阶段';
  end;
end;

class function TMigrationPlanGenerator.FormatFileSize(ASize: Int64): string;
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

class function TMigrationPlanGenerator.FormatDuration(ASeconds: Integer): string;
var
  Hours, Minutes, Seconds: Integer;
begin
  Hours := ASeconds div 3600;
  Minutes := (ASeconds mod 3600) div 60;
  Seconds := ASeconds mod 60;
  
  if Hours > 0 then
    Result := Format('%d小时%d分钟%d秒', [Hours, Minutes, Seconds])
  else if Minutes > 0 then
    Result := Format('%d分钟%d秒', [Minutes, Seconds])
  else
    Result := Format('%d秒', [Seconds]);
end;

end.func
tion TMigrationPlanGenerator.AnalyzeSpaceUtilization(const ASourcePath, ATargetPath: string; 
  const ARequiredSpace: Int64): TSpaceAnalysisResult;
var
  AvailableSpace: Int64;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  Result.SourcePath := ASourcePath;
  Result.TargetPath := ATargetPath;
  Result.RequiredSpace := ARequiredSpace;
  
  // 获取可用空间
  AvailableSpace := GetAvailableSpace(ATargetPath);
  Result.AvailableSpace := AvailableSpace;
  
  // 计算剩余空间
  Result.FreeSpaceAfter := AvailableSpace - ARequiredSpace;
  Result.IsSpaceSufficient := Result.FreeSpaceAfter > 0;
  
  // 计算空间利用率
  if AvailableSpace > 0 then
    Result.SpaceUtilization := (ARequiredSpace / AvailableSpace) * 100
  else
    Result.SpaceUtilization := 0;
  
  // 生成清理建议
  if not Result.IsSpaceSufficient then
  begin
    var CleanupList := TList<string>.Create;
    try
      CleanupList.Add('清理临时文件');
      CleanupList.Add('清理回收站');
      CleanupList.Add('清理系统缓存');
      CleanupList.Add('卸载不需要的程序');
      CleanupList.Add('压缩大文件');
      
      SetLength(Result.RecommendedCleanup, CleanupList.Count);
      for var I := 0 to CleanupList.Count - 1 do
        Result.RecommendedCleanup[I] := CleanupList[I];
    finally
      CleanupList.Free;
    end;
  end;
  
  // 生成空间优化建议
  var OptimizationList := TList<string>.Create;
  try
    if Result.SpaceUtilization > 80 then
      OptimizationList.Add('考虑使用符号链接减少空间占用');
    
    if Result.SpaceUtilization > 90 then
      OptimizationList.Add('建议选择更大的目标驱动器');
    
    OptimizationList.Add('使用硬链接处理大文件');
    OptimizationList.Add('压缩不常用的文件');
    
    SetLength(Result.SpaceOptimizations, OptimizationList.Count);
    for var I := 0 to OptimizationList.Count - 1 do
      Result.SpaceOptimizations[I] := OptimizationList[I];
  finally
    OptimizationList.Free;
  end;
end;

function TMigrationPlanGenerator.ResolveDependencies(var AItems: TArray<TMigrationItem>): Boolean;
var
  I, J: Integer;
  DependencyFound: Boolean;
begin
  Result := True;
  
  // 验证依赖关系的完整性
  for I := 0 to Length(AItems) - 1 do
  begin
    for var Dependency in AItems[I].Dependencies do
    begin
      DependencyFound := False;
      
      // 查找依赖项是否在迁移列表中
      for J := 0 to Length(AItems) - 1 do
      begin
        if SameText(AItems[J].SourcePath, Dependency) then
        begin
          DependencyFound := True;
          Break;
        end;
      end;
      
      // 如果依赖项不在列表中，可能需要调整策略
      if not DependencyFound then
      begin
        // 对于外部依赖，调整为复制而不是移动
        if AItems[I].Strategy = msMove then
          AItems[I].Strategy := msCopy;
      end;
    end;
  end;
end;

function TMigrationPlanGenerator.SortByDependencies(const AItems: TArray<TMigrationItem>): TArray<TMigrationItem>;
var
  SortedList: TList<TMigrationItem>;
  ProcessedPaths: TStringList;
  
  procedure AddItemWithDependencies(const AItem: TMigrationItem);
  var
    I: Integer;
  begin
    // 如果已经处理过，跳过
    if ProcessedPaths.IndexOf(AItem.SourcePath) >= 0 then
      Exit;
    
    // 先处理依赖项
    for var Dependency in AItem.Dependencies do
    begin
      for I := 0 to Length(AItems) - 1 do
      begin
        if SameText(AItems[I].SourcePath, Dependency) then
        begin
          AddItemWithDependencies(AItems[I]);
          Break;
        end;
      end;
    end;
    
    // 添加当前项
    SortedList.Add(AItem);
    ProcessedPaths.Add(AItem.SourcePath);
  end;

begin
  SortedList := TList<TMigrationItem>.Create;
  ProcessedPaths := TStringList.Create;
  
  try
    // 递归添加项目及其依赖
    for var Item in AItems do
      AddItemWithDependencies(Item);
    
    // 转换为数组
    SetLength(Result, SortedList.Count);
    for var I := 0 to SortedList.Count - 1 do
      Result[I] := SortedList[I];
      
  finally
    SortedList.Free;
    ProcessedPaths.Free;
  end;
end;

function TMigrationPlanGenerator.ValidateDependencyChain(const AItems: TArray<TMigrationItem>): Boolean;
var
  PathIndex: TDictionary<string, Integer>;
  I, J, DepIndex: Integer;
begin
  Result := True;
  PathIndex := TDictionary<string, Integer>.Create;
  
  try
    // 建立路径索引
    for I := 0 to Length(AItems) - 1 do
      PathIndex.Add(AItems[I].SourcePath, I);
    
    // 验证每个项目的依赖关系
    for I := 0 to Length(AItems) - 1 do
    begin
      for var Dependency in AItems[I].Dependencies do
      begin
        if PathIndex.TryGetValue(Dependency, DepIndex) then
        begin
          // 依赖项应该在当前项之前处理
          if DepIndex > I then
          begin
            Result := False;
            Break;
          end;
        end;
      end;
      
      if not Result then
        Break;
    end;
    
  finally
    PathIndex.Free;
  end;
end;f
unction TMigrationPlanGenerator.OptimizePlan(var APlan: TMigrationPlan): Boolean;
var
  PhaseGroups: TDictionary<TMigrationPhase, TArray<TMigrationItem>>;
  OptimizedItems: TList<TMigrationItem>;
begin
  Result := True;
  OptimizedItems := TList<TMigrationItem>.Create;
  
  try
    // 按阶段分组
    PhaseGroups := GroupByPhase(APlan.Items);
    
    try
      // 按阶段顺序重新组织
      var PhaseOrder: array[0..4] of TMigrationPhase = (
        mpPreparation, mpAnalysis, mpExecution, mpVerification, mpCleanup
      );
      
      for var Phase in PhaseOrder do
      begin
        var PhaseItems: TArray<TMigrationItem>;
        if PhaseGroups.TryGetValue(Phase, PhaseItems) then
        begin
          // 在每个阶段内按优先级排序
          TArray.Sort<TMigrationItem>(PhaseItems, 
            TComparer<TMigrationItem>.Construct(
              function(const Left, Right: TMigrationItem): Integer
              begin
                Result := Ord(Right.Priority) - Ord(Left.Priority); // 高优先级在前
              end
            )
          );
          
          // 添加到优化列表
          for var Item in PhaseItems do
            OptimizedItems.Add(Item);
        end;
      end;
      
      // 负载均衡
      var ItemsArray: TArray<TMigrationItem>;
      SetLength(ItemsArray, OptimizedItems.Count);
      for var I := 0 to OptimizedItems.Count - 1 do
        ItemsArray[I] := OptimizedItems[I];
      
      BalanceLoad(ItemsArray);
      
      // 更新计划
      APlan.Items := ItemsArray;
      
    finally
      PhaseGroups.Free;
    end;
    
  finally
    OptimizedItems.Free;
  end;
end;

function TMigrationPlanGenerator.GroupByPhase(const AItems: TArray<TMigrationItem>): TDictionary<TMigrationPhase, TArray<TMigrationItem>>;
var
  PhaseMap: TDictionary<TMigrationPhase, TList<TMigrationItem>>;
  Phase: TMigrationPhase;
  ItemList: TList<TMigrationItem>;
begin
  Result := TDictionary<TMigrationPhase, TArray<TMigrationItem>>.Create;
  PhaseMap := TDictionary<TMigrationPhase, TList<TMigrationItem>>.Create;
  
  try
    // 初始化阶段列表
    for Phase := Low(TMigrationPhase) to High(TMigrationPhase) do
      PhaseMap.Add(Phase, TList<TMigrationItem>.Create);
    
    // 按阶段分组
    for var Item in AItems do
    begin
      if PhaseMap.TryGetValue(Item.Phase, ItemList) then
        ItemList.Add(Item);
    end;
    
    // 转换为数组
    for Phase := Low(TMigrationPhase) to High(TMigrationPhase) do
    begin
      if PhaseMap.TryGetValue(Phase, ItemList) then
      begin
        var ItemArray: TArray<TMigrationItem>;
        SetLength(ItemArray, ItemList.Count);
        for var I := 0 to ItemList.Count - 1 do
          ItemArray[I] := ItemList[I];
        
        Result.Add(Phase, ItemArray);
      end;
    end;
    
  finally
    // 清理临时列表
    for Phase := Low(TMigrationPhase) to High(TMigrationPhase) do
    begin
      if PhaseMap.TryGetValue(Phase, ItemList) then
        ItemList.Free;
    end;
    PhaseMap.Free;
  end;
end;

function TMigrationPlanGenerator.BalanceLoad(var AItems: TArray<TMigrationItem>): Boolean;
var
  I: Integer;
  TotalTime, AverageTime: Integer;
  CurrentBatchTime: Integer;
  BatchSize: Integer;
begin
  Result := True;
  
  if Length(AItems) = 0 then
    Exit;
  
  // 计算总时间和平均时间
  TotalTime := 0;
  for var Item in AItems do
    TotalTime := TotalTime + Item.EstimatedTime;
  
  AverageTime := TotalTime div Length(AItems);
  BatchSize := Max(1, Length(AItems) div 10); // 分成10个批次
  
  // 简单的负载均衡：重新排列大文件
  TArray.Sort<TMigrationItem>(AItems,
    TComparer<TMigrationItem>.Construct(
      function(const Left, Right: TMigrationItem): Integer
      begin
        // 先按阶段排序
        Result := Ord(Left.Phase) - Ord(Right.Phase);
        if Result = 0 then
        begin
          // 同阶段内按文件大小排序（大文件优先）
          if Left.FileSize > Right.FileSize then
            Result := -1
          else if Left.FileSize < Right.FileSize then
            Result := 1
          else
            Result := 0;
        end;
      end
    )
  );
end;

function TMigrationPlanGenerator.AssessOverallRisk(const AItems: TArray<TMigrationItem>): string;
var
  TotalRisk, HighRiskCount, CriticalCount: Integer;
  AverageRisk: Double;
  RiskFactors: TStringList;
begin
  TotalRisk := 0;
  HighRiskCount := 0;
  CriticalCount := 0;
  RiskFactors := TStringList.Create;
  
  try
    for var Item in AItems do
    begin
      TotalRisk := TotalRisk + Item.RiskLevel;
      
      if Item.RiskLevel > 70 then
        Inc(HighRiskCount);
      
      if Item.RequiresReboot then
        Inc(CriticalCount);
      
      if Item.RiskLevel > 80 then
        RiskFactors.Add(Format('高风险文件: %s', [ExtractFileName(Item.SourcePath)]));
    end;
    
    if Length(AItems) > 0 then
      AverageRisk := TotalRisk / Length(AItems)
    else
      AverageRisk := 0;
    
    // 生成风险评估报告
    if AverageRisk < 30 then
      Result := '低风险 - 迁移操作相对安全'
    else if AverageRisk < 50 then
      Result := '中等风险 - 建议创建备份后执行'
    else if AverageRisk < 70 then
      Result := '高风险 - 需要谨慎操作并准备回退方案'
    else
      Result := '极高风险 - 强烈建议专业人员操作';
    
    if HighRiskCount > 0 then
      Result := Result + Format(' (包含%d个高风险文件)', [HighRiskCount]);
    
    if CriticalCount > 0 then
      Result := Result + Format(' (需要重启%d个文件)', [CriticalCount]);
    
  finally
    RiskFactors.Free;
  end;
end;

function TMigrationPlanGenerator.GeneratePrerequisites(const AItems: TArray<TMigrationItem>): TArray<string>;
var
  Prerequisites: TStringList;
  HasSystemFiles, HasLargeFiles, HasRebootFiles: Boolean;
begin
  Prerequisites := TStringList.Create;
  try
    HasSystemFiles := False;
    HasLargeFiles := False;
    HasRebootFiles := False;
    
    // 分析文件特征
    for var Item in AItems do
    begin
      if Item.RiskLevel > 70 then
        HasSystemFiles := True;
      
      if Item.FileSize > 1024 * 1024 * 1024 then // > 1GB
        HasLargeFiles := True;
      
      if Item.RequiresReboot then
        HasRebootFiles := True;
    end;
    
    // 生成前置条件
    Prerequisites.Add('确保目标驱动器有足够的可用空间');
    Prerequisites.Add('关闭所有可能使用目标文件的应用程序');
    Prerequisites.Add('创建系统还原点');
    
    if HasSystemFiles then
    begin
      Prerequisites.Add('以管理员权限运行程序');
      Prerequisites.Add('备份重要的系统文件');
    end;
    
    if HasLargeFiles then
    begin
      Prerequisites.Add('确保网络连接稳定（如果涉及网络存储）');
      Prerequisites.Add('预留足够的操作时间');
    end;
    
    if HasRebootFiles then
    begin
      Prerequisites.Add('准备重启系统');
      Prerequisites.Add('保存所有未保存的工作');
    end;
    
    // 转换为数组
    SetLength(Result, Prerequisites.Count);
    for var I := 0 to Prerequisites.Count - 1 do
      Result[I] := Prerequisites[I];
      
  finally
    Prerequisites.Free;
  end;
end;f
unction TMigrationPlanGenerator.GeneratePostActions(const AItems: TArray<TMigrationItem>): TArray<string>;
var
  PostActions: TStringList;
  HasSymbolicLinks, HasRebootFiles, HasDeletedFiles: Boolean;
begin
  PostActions := TStringList.Create;
  try
    HasSymbolicLinks := False;
    HasRebootFiles := False;
    HasDeletedFiles := False;
    
    // 分析操作类型
    for var Item in AItems do
    begin
      if (Item.Strategy = msSymbolicLink) or (Item.Strategy = msHardLink) then
        HasSymbolicLinks := True;
      
      if Item.RequiresReboot then
        HasRebootFiles := True;
      
      if Item.Strategy = msDelete then
        HasDeletedFiles := True;
    end;
    
    // 生成后续操作
    PostActions.Add('验证所有文件迁移完成');
    PostActions.Add('测试应用程序功能正常');
    PostActions.Add('更新相关的配置文件');
    
    if HasSymbolicLinks then
    begin
      PostActions.Add('验证符号链接和硬链接正常工作');
      PostActions.Add('更新应用程序路径配置');
    end;
    
    if HasRebootFiles then
    begin
      PostActions.Add('重启系统以完成文件操作');
      PostActions.Add('重启后验证系统功能');
    end;
    
    if HasDeletedFiles then
    begin
      PostActions.Add('清空回收站释放空间');
      PostActions.Add('运行磁盘清理工具');
    end;
    
    PostActions.Add('删除临时备份文件');
    PostActions.Add('更新系统索引');
    
    // 转换为数组
    SetLength(Result, PostActions.Count);
    for var I := 0 to PostActions.Count - 1 do
      Result[I] := PostActions[I];
      
  finally
    PostActions.Free;
  end;
end;

function TMigrationPlanGenerator.GenerateRollbackPlan(const AItems: TArray<TMigrationItem>): TArray<string>;
var
  RollbackSteps: TStringList;
begin
  RollbackSteps := TStringList.Create;
  try
    RollbackSteps.Add('停止所有正在进行的迁移操作');
    RollbackSteps.Add('从备份恢复已修改的文件');
    
    // 按相反顺序回退操作
    for var I := Length(AItems) - 1 downto 0 do
    begin
      var Item := AItems[I];
      
      case Item.Strategy of
        msMove:
          RollbackSteps.Add(Format('将文件从 %s 移回 %s', [Item.TargetPath, Item.SourcePath]));
        msCopy:
          RollbackSteps.Add(Format('删除复制的文件 %s', [Item.TargetPath]));
        msSymbolicLink, msHardLink:
          RollbackSteps.Add(Format('删除链接 %s 并恢复原文件', [Item.TargetPath]));
        msDelete:
          RollbackSteps.Add(Format('从备份恢复已删除的文件 %s', [Item.SourcePath]));
      end;
    end;
    
    RollbackSteps.Add('恢复注册表备份');
    RollbackSteps.Add('重启系统（如果需要）');
    RollbackSteps.Add('验证系统功能正常');
    RollbackSteps.Add('清理回退过程中的临时文件');
    
    // 转换为数组
    SetLength(Result, RollbackSteps.Count);
    for var I := 0 to RollbackSteps.Count - 1 do
      Result[I] := RollbackSteps[I];
      
  finally
    RollbackSteps.Free;
  end;
end;

// 可行性评估方法
function TMigrationPlanGenerator.EvaluateFeasibility(const ASourcePath, ATargetPath: string): TFeasibilityResult;
var
  BlockingIssues, Warnings, Recommendations: TStringList;
  SpaceAnalysis: TSpaceAnalysisResult;
  SourceSize, TargetSpace: Int64;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  Result.IsFeasible := True;
  Result.ConfidenceLevel := 100;
  Result.EstimatedSuccessRate := 90;
  
  BlockingIssues := TStringList.Create;
  Warnings := TStringList.Create;
  Recommendations := TStringList.Create;
  
  try
    // 检查源目录
    if not DirectoryExists(ASourcePath) then
    begin
      BlockingIssues.Add('源目录不存在');
      Result.IsFeasible := False;
      Result.ConfidenceLevel := 0;
    end;
    
    // 检查目标目录
    if not DirectoryExists(ExtractFilePath(ATargetPath)) then
    begin
      if not ForceDirectories(ExtractFilePath(ATargetPath)) then
      begin
        BlockingIssues.Add('无法创建目标目录');
        Result.IsFeasible := False;
        Result.ConfidenceLevel := Result.ConfidenceLevel - 50;
      end;
    end;
    
    // 空间分析
    if Result.IsFeasible then
    begin
      SpaceAnalysis := AnalyzeSpaceRequirements(ASourcePath, ATargetPath);
      
      if not SpaceAnalysis.IsSpaceSufficient then
      begin
        BlockingIssues.Add('目标驱动器空间不足');
        Result.IsFeasible := False;
        Result.ConfidenceLevel := Result.ConfidenceLevel - 30;
      end
      else if SpaceAnalysis.SpaceUtilization > 90 then
      begin
        Warnings.Add('目标驱动器空间使用率将超过90%');
        Result.ConfidenceLevel := Result.ConfidenceLevel - 20;
        Result.EstimatedSuccessRate := Result.EstimatedSuccessRate - 10;
      end;
    end;
    
    // 权限检查
    try
      var TestFile := ATargetPath + '\test_write_permission.tmp';
      TFile.WriteAllText(TestFile, 'test');
      DeleteFile(TestFile);
    except
      Warnings.Add('目标目录可能没有写入权限');
      Result.ConfidenceLevel := Result.ConfidenceLevel - 15;
    end;
    
    // 生成建议
    if Result.IsFeasible then
    begin
      Recommendations.Add('建议在操作前创建完整备份');
      Recommendations.Add('建议在非工作时间执行迁移');
      
      if SpaceAnalysis.SpaceUtilization > 70 then
        Recommendations.Add('考虑清理目标驱动器以获得更多空间');
    end
    else
    begin
      Recommendations.Add('解决所有阻塞问题后重新评估');
      Recommendations.Add('考虑选择其他目标位置');
    end;
    
    // 转换为数组
    SetLength(Result.BlockingIssues, BlockingIssues.Count);
    for var I := 0 to BlockingIssues.Count - 1 do
      Result.BlockingIssues[I] := BlockingIssues[I];
    
    SetLength(Result.Warnings, Warnings.Count);
    for var I := 0 to Warnings.Count - 1 do
      Result.Warnings[I] := Warnings[I];
    
    SetLength(Result.Recommendations, Recommendations.Count);
    for var I := 0 to Recommendations.Count - 1 do
      Result.Recommendations[I] := Recommendations[I];
    
  finally
    BlockingIssues.Free;
    Warnings.Free;
    Recommendations.Free;
  end;
end;

function TMigrationPlanGenerator.AnalyzeSpaceRequirements(const ASourcePath, ATargetPath: string): TSpaceAnalysisResult;
var
  Files: TArray<string>;
  TotalSize: Int64;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  Result.SourcePath := ASourcePath;
  Result.TargetPath := ATargetPath;
  
  try
    // 计算源目录大小
    Files := TDirectory.GetFiles(ASourcePath, '*', TSearchOption.soAllDirectories);
    TotalSize := 0;
    
    for var FilePath in Files do
    begin
      try
        TotalSize := TotalSize + TFile.GetSize(FilePath);
      except
        // 忽略无法访问的文件
      end;
    end;
    
    Result.RequiredSpace := TotalSize;
    Result.AvailableSpace := GetAvailableSpace(ATargetPath);
    Result.FreeSpaceAfter := Result.AvailableSpace - Result.RequiredSpace;
    Result.IsSpaceSufficient := Result.FreeSpaceAfter > 0;
    
    if Result.AvailableSpace > 0 then
      Result.SpaceUtilization := (Result.RequiredSpace / Result.AvailableSpace) * 100
    else
      Result.SpaceUtilization := 0;
    
  except
    on E: Exception do
    begin
      Result.IsSpaceSufficient := False;
      // 设置错误信息到优化建议中
      SetLength(Result.SpaceOptimizations, 1);
      Result.SpaceOptimizations[0] := '空间分析失败: ' + E.Message;
    end;
  end;
end;// 工具方
法实现
class function TMigrationPlanGenerator.StrategyToString(AStrategy: TMigrationStrategy): string;
begin
  case AStrategy of
    msMove: Result := '移动';
    msCopy: Result := '复制';
    msSymbolicLink: Result := '符号链接';
    msHardLink: Result := '硬链接';
    msSkip: Result := '跳过';
    msDelete: Result := '删除';
  else
    Result := '未知';
  end;
end;

class function TMigrationPlanGenerator.PriorityToString(APriority: TMigrationPriority): string;
begin
  case APriority of
    mpLow: Result := '低';
    mpNormal: Result := '普通';
    mpHigh: Result := '高';
    mpCritical: Result := '关键';
  else
    Result := '未知';
  end;
end;

class function TMigrationPlanGenerator.PhaseToString(APhase: TMigrationPhase): string;
begin
  case APhase of
    mpPreparation: Result := '准备阶段';
    mpAnalysis: Result := '分析阶段';
    mpExecution: Result := '执行阶段';
    mpVerification: Result := '验证阶段';
    mpCleanup: Result := '清理阶段';
  else
    Result := '未知阶段';
  end;
end;

class function TMigrationPlanGenerator.FormatFileSize(ASize: Int64): string;
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

class function TMigrationPlanGenerator.FormatDuration(ASeconds: Integer): string;
var
  Hours, Minutes, Seconds: Integer;
begin
  Hours := ASeconds div 3600;
  Minutes := (ASeconds mod 3600) div 60;
  Seconds := ASeconds mod 60;
  
  if Hours > 0 then
    Result := Format('%d小时%d分钟%d秒', [Hours, Minutes, Seconds])
  else if Minutes > 0 then
    Result := Format('%d分钟%d秒', [Minutes, Seconds])
  else
    Result := Format('%d秒', [Seconds]);
end;

// 计划管理方法
function TMigrationPlanGenerator.SavePlan(const APlan: TMigrationPlan; const AFilePath: string): Boolean;
var
  JSONObj, ItemObj: TJSONObject;
  ItemsArray: TJSONArray;
  I: Integer;
begin
  Result := False;
  
  try
    JSONObj := TJSONObject.Create;
    try
      // 基本信息
      JSONObj.AddPair('PlanName', APlan.PlanName);
      JSONObj.AddPair('CreatedTime', DateTimeToStr(APlan.CreatedTime));
      JSONObj.AddPair('SourceDirectory', APlan.SourceDirectory);
      JSONObj.AddPair('TargetDirectory', APlan.TargetDirectory);
      JSONObj.AddPair('TotalItems', TJSONNumber.Create(APlan.TotalItems));
      JSONObj.AddPair('TotalSize', TJSONNumber.Create(APlan.TotalSize));
      JSONObj.AddPair('EstimatedDuration', TJSONNumber.Create(APlan.EstimatedDuration));
      JSONObj.AddPair('RequiredSpace', TJSONNumber.Create(APlan.RequiredSpace));
      JSONObj.AddPair('AvailableSpace', TJSONNumber.Create(APlan.AvailableSpace));
      JSONObj.AddPair('SpaceUtilization', TJSONNumber.Create(APlan.SpaceUtilization));
      JSONObj.AddPair('RiskAssessment', APlan.RiskAssessment);
      
      // 迁移项目
      ItemsArray := TJSONArray.Create;
      for I := 0 to Length(APlan.Items) - 1 do
      begin
        ItemObj := TJSONObject.Create;
        ItemObj.AddPair('SourcePath', APlan.Items[I].SourcePath);
        ItemObj.AddPair('TargetPath', APlan.Items[I].TargetPath);
        ItemObj.AddPair('Strategy', TJSONNumber.Create(Ord(APlan.Items[I].Strategy)));
        ItemObj.AddPair('Priority', TJSONNumber.Create(Ord(APlan.Items[I].Priority)));
        ItemObj.AddPair('Phase', TJSONNumber.Create(Ord(APlan.Items[I].Phase)));
        ItemObj.AddPair('FileSize', TJSONNumber.Create(APlan.Items[I].FileSize));
        ItemObj.AddPair('EstimatedTime', TJSONNumber.Create(APlan.Items[I].EstimatedTime));
        ItemObj.AddPair('RequiresReboot', TJSONBool.Create(APlan.Items[I].RequiresReboot));
        ItemObj.AddPair('RiskLevel', TJSONNumber.Create(APlan.Items[I].RiskLevel));
        ItemObj.AddPair('Description', APlan.Items[I].Description);
        ItemObj.AddPair('BackupRequired', TJSONBool.Create(APlan.Items[I].BackupRequired));
        ItemObj.AddPair('VerificationMethod', APlan.Items[I].VerificationMethod);
        
        ItemsArray.AddElement(ItemObj);
      end;
      JSONObj.AddPair('Items', ItemsArray);
      
      // 保存到文件
      TFile.WriteAllText(AFilePath, JSONObj.ToString, TEncoding.UTF8);
      Result := True;
      
    finally
      JSONObj.Free;
    end;
    
  except
    Result := False;
  end;
end;

function TMigrationPlanGenerator.LoadPlan(const AFilePath: string): TMigrationPlan;
var
  JSONText: string;
  JSONObj, ItemObj: TJSONObject;
  ItemsArray: TJSONArray;
  I: Integer;
begin
  // 初始化结果
  FillChar(Result, SizeOf(Result), 0);
  
  try
    if not FileExists(AFilePath) then
      Exit;
    
    JSONText := TFile.ReadAllText(AFilePath, TEncoding.UTF8);
    JSONObj := TJSONObject.ParseJSONValue(JSONText) as TJSONObject;
    
    if JSONObj = nil then
      Exit;
    
    try
      // 读取基本信息
      Result.PlanName := JSONObj.GetValue('PlanName').Value;
      Result.CreatedTime := StrToDateTime(JSONObj.GetValue('CreatedTime').Value);
      Result.SourceDirectory := JSONObj.GetValue('SourceDirectory').Value;
      Result.TargetDirectory := JSONObj.GetValue('TargetDirectory').Value;
      Result.TotalItems := (JSONObj.GetValue('TotalItems') as TJSONNumber).AsInt;
      Result.TotalSize := (JSONObj.GetValue('TotalSize') as TJSONNumber).AsInt64;
      Result.EstimatedDuration := (JSONObj.GetValue('EstimatedDuration') as TJSONNumber).AsInt;
      Result.RequiredSpace := (JSONObj.GetValue('RequiredSpace') as TJSONNumber).AsInt64;
      Result.AvailableSpace := (JSONObj.GetValue('AvailableSpace') as TJSONNumber).AsInt64;
      Result.SpaceUtilization := (JSONObj.GetValue('SpaceUtilization') as TJSONNumber).AsDouble;
      Result.RiskAssessment := JSONObj.GetValue('RiskAssessment').Value;
      
      // 读取迁移项目
      ItemsArray := JSONObj.GetValue('Items') as TJSONArray;
      SetLength(Result.Items, ItemsArray.Count);
      
      for I := 0 to ItemsArray.Count - 1 do
      begin
        ItemObj := ItemsArray.Items[I] as TJSONObject;
        
        Result.Items[I].SourcePath := ItemObj.GetValue('SourcePath').Value;
        Result.Items[I].TargetPath := ItemObj.GetValue('TargetPath').Value;
        Result.Items[I].Strategy := TMigrationStrategy((ItemObj.GetValue('Strategy') as TJSONNumber).AsInt);
        Result.Items[I].Priority := TMigrationPriority((ItemObj.GetValue('Priority') as TJSONNumber).AsInt);
        Result.Items[I].Phase := TMigrationPhase((ItemObj.GetValue('Phase') as TJSONNumber).AsInt);
        Result.Items[I].FileSize := (ItemObj.GetValue('FileSize') as TJSONNumber).AsInt64;
        Result.Items[I].EstimatedTime := (ItemObj.GetValue('EstimatedTime') as TJSONNumber).AsInt;
        Result.Items[I].RequiresReboot := (ItemObj.GetValue('RequiresReboot') as TJSONBool).AsBoolean;
        Result.Items[I].RiskLevel := (ItemObj.GetValue('RiskLevel') as TJSONNumber).AsInt;
        Result.Items[I].Description := ItemObj.GetValue('Description').Value;
        Result.Items[I].BackupRequired := (ItemObj.GetValue('BackupRequired') as TJSONBool).AsBoolean;
        Result.Items[I].VerificationMethod := ItemObj.GetValue('VerificationMethod').Value;
      end;
      
    finally
      JSONObj.Free;
    end;
    
  except
    // 加载失败，返回空计划
    FillChar(Result, SizeOf(Result), 0);
  end;
end;

function TMigrationPlanGenerator.ComparePlans(const APlan1, APlan2: TMigrationPlan): string;
var
  Comparison: TStringList;
begin
  Comparison := TStringList.Create;
  try
    Comparison.Add('=== 迁移计划对比 ===');
    Comparison.Add('');
    
    // 基本信息对比
    Comparison.Add(Format('计划名称: %s vs %s', [APlan1.PlanName, APlan2.PlanName]));
    Comparison.Add(Format('文件总数: %d vs %d', [APlan1.TotalItems, APlan2.TotalItems]));
    Comparison.Add(Format('总大小: %s vs %s', [FormatFileSize(APlan1.TotalSize), FormatFileSize(APlan2.TotalSize)]));
    Comparison.Add(Format('预计时间: %s vs %s', [FormatDuration(APlan1.EstimatedDuration), FormatDuration(APlan2.EstimatedDuration)]));
    Comparison.Add(Format('空间利用率: %.1f%% vs %.1f%%', [APlan1.SpaceUtilization, APlan2.SpaceUtilization]));
    Comparison.Add('');
    
    // 风险评估对比
    Comparison.Add('风险评估:');
    Comparison.Add('  计划1: ' + APlan1.RiskAssessment);
    Comparison.Add('  计划2: ' + APlan2.RiskAssessment);
    Comparison.Add('');
    
    // 推荐
    if APlan1.TotalItems < APlan2.TotalItems then
      Comparison.Add('推荐: 计划1文件数量较少，操作相对简单')
    else if APlan1.TotalItems > APlan2.TotalItems then
      Comparison.Add('推荐: 计划2文件数量较少，操作相对简单')
    else
      Comparison.Add('推荐: 两个计划文件数量相同，建议选择风险较低的计划');
    
    Result := Comparison.Text;
    
  finally
    Comparison.Free;
  end;
end;

end.
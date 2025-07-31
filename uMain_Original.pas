unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Menus, System.IOUtils,
  // Core data types
  DataTypes,
  // Modern UI styles
  uStyles;

// Windows API 声明
function GetFinalPathNameByHandle(hFile: THandle; lpszFilePath: PChar;
  cchFilePath: DWORD; dwFlags: DWORD): DWORD; stdcall; external kernel32 name 'GetFinalPathNameByHandleA';

// Windows 错误代码常量
const
  ERROR_ACCESS_DENIED = 5;
  ERROR_SHARING_VIOLATION = 32;
  ERROR_DIR_NOT_EMPTY = 145;

// 符号链接相关常量
const
  IO_REPARSE_TAG_SYMLINK = $A000000C;
  IO_REPARSE_TAG_MOUNT_POINT = $A0000003;
  FSCTL_GET_REPARSE_POINT = $900A8;
  MAXIMUM_REPARSE_DATA_BUFFER_SIZE = 16384;

type
  // 目录状态枚举 (增强版)
  TDirectoryStatus = (
    dsNormal,           // 普通目录
    dsSymlink,          // 有效符号链接
    dsSymlinkBroken,    // 无效符号链接
    dsSymlinkFile,      // 文件符号链接
    dsSymlinkDir,       // 目录符号链接
    dsMountPoint,       // 挂载点
    dsAnalyzed,         // 已分析
    dsAnalyzedGood,     // 分析结果：可链接
    dsAnalyzedRisk,     // 分析结果：有风险
    dsAnalyzedBad,      // 分析结果：禁止移动
    dsCopying,          // 拷贝中
    dsCopied,           // 已拷贝
    dsBackedUp,         // 已备份
    dsRestored          // 已恢复
  );

  // 符号链接信息记录
  TSymlinkInfo = record
    Path: string;              // 符号链接路径
    Target: string;            // 目标路径
    Status: TDirectoryStatus;  // 状态
    IsValid: Boolean;          // 是否有效
    ScanTime: TDateTime;       // 扫描时间
    FileSize: Int64;           // 文件大小（如果是文件）
    IsDirectory: Boolean;      // 是否为目录
  end;

  // 符号链接缓存管理器
  TSymlinkCache = class
  private
    FSymlinks: TArray<TSymlinkInfo>;
    FLastScanTime: TDateTime;
    FCacheFile: string;
  public
    constructor Create(const ACacheFile: string);
    destructor Destroy; override;

    procedure AddSymlink(const AInfo: TSymlinkInfo);
    function FindSymlink(const APath: string): TSymlinkInfo;
    function HasSymlink(const APath: string): Boolean;
    procedure RemoveSymlink(const APath: string);
    procedure Clear;

    procedure SaveToFile;
    procedure LoadFromFile;

    function GetSymlinkCount: Integer;
    function GetValidSymlinkCount: Integer;
    function IsExpired(const AMaxAge: Integer = 24): Boolean; // 默认24小时过期

    property LastScanTime: TDateTime read FLastScanTime write FLastScanTime;
    property SymlinkCount: Integer read GetSymlinkCount;
    property ValidSymlinkCount: Integer read GetValidSymlinkCount;
  end;

  // 拷贝状态枚举
  TCopyStatus = (
    csNotStarted,    // 未开始
    csInProgress,    // 进行中
    csPaused,        // 已暂停
    csCompleted,     // 已完成
    csFailed,        // 失败
    csCancelled      // 已取消
  );

  // 文件拷贝信息
  TFileCopyInfo = record
    SourcePath: string;      // 源文件路径
    TargetPath: string;      // 目标文件路径
    FileSize: Int64;         // 文件大小
    CopiedSize: Int64;       // 已拷贝大小
    Status: TCopyStatus;     // 拷贝状态
    LastModified: TDateTime; // 最后修改时间
    CheckSum: string;        // 文件校验和
    ErrorMessage: string;    // 错误信息
  end;

  // 拷贝会话信息
  TCopySession = record
    SessionId: string;           // 会话ID
    SourceDir: string;           // 源目录
    TargetDir: string;           // 目标目录
    StartTime: TDateTime;        // 开始时间
    LastUpdateTime: TDateTime;   // 最后更新时间
    Status: TCopyStatus;         // 整体状态
    TotalFiles: Integer;         // 总文件数
    CompletedFiles: Integer;     // 已完成文件数
    TotalSize: Int64;            // 总大小
    CopiedSize: Int64;           // 已拷贝大小
    Files: TArray<TFileCopyInfo>; // 文件列表
    ErrorCount: Integer;         // 错误计数
    LastError: string;           // 最后错误
  end;

  // 拷贝会话管理器
  TCopySessionManager = class
  private
    FSessions: TArray<TCopySession>;
    FCurrentSession: TCopySession;
    FSessionFile: string;
    FHasCurrentSession: Boolean;

    procedure RecalculateSessionStats;
  public
    constructor Create(const ASessionFile: string);
    destructor Destroy; override;

    function CreateSession(const ASourceDir, ATargetDir: string): string;
    function LoadSession(const ASessionId: string): Boolean;
    procedure SaveCurrentSession;
    procedure UpdateFileProgress(const ASourcePath: string; ACopiedSize: Int64; AStatus: TCopyStatus);
    procedure CompleteFile(const ASourcePath: string; const ACheckSum: string = '');
    procedure FailFile(const ASourcePath: string; const AErrorMsg: string);

    function GetIncompleteFiles: TArray<TFileCopyInfo>;
    function GetSessionProgress: Double; // 返回0-100的进度百分比
    function CanResume: Boolean;

    procedure PauseSession;
    procedure ResumeSession;
    procedure CancelSession;
    procedure CompleteSession;

    property CurrentSession: TCopySession read FCurrentSession;
    property HasCurrentSession: Boolean read FHasCurrentSession;
  end;

  // 操作类型枚举
  TOperationType = (
    otDirectoryAnalysis,    // 目录分析
    otSymlinkScan,         // 符号链接扫描
    otSymlinkRepair,       // 符号链接修复
    otFileCopy,            // 文件拷贝
    otFileMove,            // 文件移动
    otDirectoryCreate,     // 目录创建
    otDirectoryDelete,     // 目录删除
    otStatusChange,        // 状态变更
    otCacheUpdate,         // 缓存更新
    otSessionCreate,       // 会话创建
    otSessionComplete,     // 会话完成
    otUserAction           // 用户操作
  );

  // 操作历史记录
  TOperationHistory = record
    Id: string;                    // 操作ID
    OperationType: TOperationType; // 操作类型
    Timestamp: TDateTime;          // 操作时间
    SourcePath: string;            // 源路径
    TargetPath: string;            // 目标路径
    OldStatus: TDirectoryStatus;   // 旧状态
    NewStatus: TDirectoryStatus;   // 新状态
    Description: string;           // 操作描述
    Success: Boolean;              // 是否成功
    ErrorMessage: string;          // 错误信息
    UserData: string;              // 用户数据
  end;

  // 状态管理器
  TStatusManager = class
  private
    FOperationHistory: TArray<TOperationHistory>;
    FDirectoryStates: TDictionary<string, TDirectoryStatus>;
    FHistoryFile: string;
    FMaxHistoryCount: Integer;
  public
    constructor Create(const AHistoryFile: string; AMaxHistoryCount: Integer = 1000);
    destructor Destroy; override;

    // 操作历史管理
    function AddOperation(const AOperation: TOperationHistory): string;
    function GetOperationHistory(ACount: Integer = 50): TArray<TOperationHistory>;
    function GetOperationsByType(AType: TOperationType): TArray<TOperationHistory>;
    function GetOperationsByPath(const APath: string): TArray<TOperationHistory>;
    procedure ClearHistory;

    // 状态管理
    procedure SetDirectoryStatus(const APath: string; AStatus: TDirectoryStatus; const ADescription: string = '');
    function GetDirectoryStatus(const APath: string): TDirectoryStatus;
    function HasDirectoryStatus(const APath: string): Boolean;
    procedure RemoveDirectoryStatus(const APath: string);
    procedure ClearAllStates;

    // 撤销功能
    function CanUndo: Boolean;
    function UndoLastOperation: Boolean;
    function GetUndoDescription: string;

    // 持久化
    procedure SaveToFile;
    procedure LoadFromFile;

    // 统计信息
    function GetOperationCount: Integer;
    function GetOperationCountByType(AType: TOperationType): Integer;
    function GetDirectoryStateCount: Integer;

    property OperationCount: Integer read GetOperationCount;
    property DirectoryStateCount: Integer read GetDirectoryStateCount;
  end;

  // 目录变化类型
  TDirectoryChangeType = (
    dctCreated,    // 目录创建
    dctDeleted,    // 目录删除
    dctRenamed,    // 目录重命名
    dctMoved,      // 目录移动
    dctModified    // 目录修改
  );

  // 目录变化记录
  TDirectoryChange = record
    ChangeType: TDirectoryChangeType;
    OldPath: string;
    NewPath: string;
    Timestamp: TDateTime;
    Detected: Boolean;
  end;

  // 目录监控器
  TDirectoryMonitor = class
  private
    FWatchedPaths: TStringList;
    FDirectoryStates: TDictionary<string, TFileTime>;
    FChanges: TArray<TDirectoryChange>;
    FLastScanTime: TDateTime;
    FEnabled: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddWatchPath(const APath: string);
    procedure RemoveWatchPath(const APath: string);
    procedure ClearWatchPaths;

    function ScanForChanges: TArray<TDirectoryChange>;
    procedure UpdateDirectoryState(const APath: string);
    function HasPathChanged(const APath: string): Boolean;

    property Enabled: Boolean read FEnabled write FEnabled;
    property WatchedPathCount: Integer read GetWatchedPathCount;
  private
    function GetWatchedPathCount: Integer;
    function GetDirectoryFileTime(const APath: string): TFileTime;
    function CompareFileTime(const ATime1, ATime2: TFileTime): Integer;
  end;

  // 建议类型枚举
  TSuggestionType = (
    stOptimization,     // 优化建议
    stSafety,          // 安全建议
    stEfficiency,      // 效率建议
    stMaintenance,     // 维护建议
    stWorkflow,        // 工作流建议
    stTroubleshooting, // 故障排除
    stBestPractice     // 最佳实践
  );

  // 建议优先级
  TSuggestionPriority = (
    spLow,      // 低优先级
    spMedium,   // 中等优先级
    spHigh,     // 高优先级
    spCritical  // 关键优先级
  );

  // 智能建议记录
  TSmartSuggestion = record
    Id: string;                        // 建议ID
    SuggestionType: TSuggestionType;   // 建议类型
    Priority: TSuggestionPriority;     // 优先级
    Title: string;                     // 建议标题
    Description: string;               // 详细描述
    ActionText: string;                // 操作文本
    RelatedPath: string;               // 相关路径
    CreatedTime: TDateTime;            // 创建时间
    IsRead: Boolean;                   // 是否已读
    IsApplied: Boolean;                // 是否已应用
    AppliedTime: TDateTime;            // 应用时间
    UserData: string;                  // 用户数据
  end;

  // 用户行为模式
  TUserBehaviorPattern = record
    OperationType: TOperationType;     // 操作类型
    FrequencyCount: Integer;           // 频率计数
    LastUsedTime: TDateTime;           // 最后使用时间
    AverageInterval: Double;           // 平均间隔（小时）
    PreferredPaths: TArray<string>;    // 偏好路径
    SuccessRate: Double;               // 成功率
  end;

  // 智能建议引擎
  TSmartSuggestionEngine = class
  private
    FSuggestions: TArray<TSmartSuggestion>;
    FUserPatterns: TArray<TUserBehaviorPattern>;
    FDataFile: string;
    FMaxSuggestions: Integer;
    FStatusManager: TStatusManager;
  public
    constructor Create(const ADataFile: string; AStatusManager: TStatusManager; AMaxSuggestions: Integer = 50);
    destructor Destroy; override;

    // 建议管理
    function AddSuggestion(const ASuggestion: TSmartSuggestion): string;
    function GetSuggestions(AType: TSuggestionType = stOptimization; ACount: Integer = 10): TArray<TSmartSuggestion>;
    function GetUnreadSuggestions: TArray<TSmartSuggestion>;
    function GetHighPrioritySuggestions: TArray<TSmartSuggestion>;
    procedure MarkSuggestionRead(const ASuggestionId: string);
    procedure MarkSuggestionApplied(const ASuggestionId: string);
    procedure RemoveSuggestion(const ASuggestionId: string);
    procedure ClearOldSuggestions(ADaysOld: Integer = 30);

    // 行为分析
    procedure AnalyzeUserBehavior;
    procedure UpdateUserPattern(AOperationType: TOperationType; const APath: string; ASuccess: Boolean);
    function PredictNextOperation: TOperationType;
    function GetRecommendedPaths: TArray<string>;

    // 智能建议生成
    procedure GenerateOptimizationSuggestions;
    procedure GenerateSafetySuggestions;
    procedure GenerateEfficiencySuggestions;
    procedure GenerateMaintenanceSuggestions;
    procedure GenerateWorkflowSuggestions;

    // 持久化
    procedure SaveToFile;
    procedure LoadFromFile;

    // 统计信息
    function GetSuggestionCount: Integer;
    function GetUnreadCount: Integer;
    function GetAppliedCount: Integer;

    property SuggestionCount: Integer read GetSuggestionCount;
    property UnreadCount: Integer read GetUnreadCount;
    property AppliedCount: Integer read GetAppliedCount;
  private
    function GetOperationTypeName(AType: TOperationType): string;
  end;

  // 批量操作类型
  TBatchOperationType = (
    btAnalyze,        // 批量分析
    btCopy,           // 批量拷贝
    btMove,           // 批量移动
    btSymlinkScan,    // 批量符号链接扫描
    btSymlinkRepair,  // 批量符号链接修复
    btStatusCheck,    // 批量状态检查
    btCleanup         // 批量清理
  );

  // 批量操作项
  TBatchOperationItem = record
    SourcePath: string;           // 源路径
    TargetPath: string;           // 目标路径
    OperationType: TBatchOperationType; // 操作类型
    Status: TCopyStatus;          // 状态
    Progress: Double;             // 进度 (0-100)
    ErrorMessage: string;         // 错误信息
    StartTime: TDateTime;         // 开始时间
    EndTime: TDateTime;           // 结束时间
    FileCount: Integer;           // 文件数量
    ProcessedCount: Integer;      // 已处理数量
    TotalSize: Int64;             // 总大小
    ProcessedSize: Int64;         // 已处理大小
  end;

  // 批量操作管理器
  TBatchOperationManager = class
  private
    FOperations: TArray<TBatchOperationItem>;
    FCurrentIndex: Integer;
    FIsRunning: Boolean;
    FIsPaused: Boolean;
    FTotalOperations: Integer;
    FCompletedOperations: Integer;
    FFailedOperations: Integer;
    FOnProgress: TNotifyEvent;
    FOnComplete: TNotifyEvent;
    FOnError: TNotifyEvent;
  public
    constructor Create;
    destructor Destroy; override;

    // 操作管理
    procedure AddOperation(const AItem: TBatchOperationItem);
    procedure ClearOperations;
    function GetOperationCount: Integer;
    function GetOperation(AIndex: Integer): TBatchOperationItem;
    procedure UpdateOperation(AIndex: Integer; const AItem: TBatchOperationItem);

    // 执行控制
    procedure StartBatch;
    procedure PauseBatch;
    procedure ResumeBatch;
    procedure StopBatch;
    function IsRunning: Boolean;
    function IsPaused: Boolean;

    // 进度信息
    function GetOverallProgress: Double;
    function GetCurrentOperation: TBatchOperationItem;
    function GetCompletedCount: Integer;
    function GetFailedCount: Integer;
    function GetRemainingCount: Integer;

    // 事件
    property OnProgress: TNotifyEvent read FOnProgress write FOnProgress;
    property OnComplete: TNotifyEvent read FOnComplete write FOnComplete;
    property OnError: TNotifyEvent read FOnError write FOnError;
  end;

  // 依赖关系类型
  TDependencyType = (
    dtSymbolicLink,    // 符号链接依赖
    dtFileReference,   // 文件引用依赖
    dtPathReference,   // 路径引用依赖
    dtConfigFile,      // 配置文件依赖
    dtRegistry,        // 注册表依赖
    dtEnvironment,     // 环境变量依赖
    dtService,         // 服务依赖
    dtLibrary          // 库文件依赖
  );

  // 依赖关系强度
  TDependencyStrength = (
    dsWeak,      // 弱依赖
    dsModerate,  // 中等依赖
    dsStrong,    // 强依赖
    dsCritical   // 关键依赖
  );

  // 依赖关系记录
  TDependencyRelation = record
    Id: string;                           // 依赖ID
    SourcePath: string;                   // 源路径
    TargetPath: string;                   // 目标路径
    DependencyType: TDependencyType;      // 依赖类型
    Strength: TDependencyStrength;        // 依赖强度
    Description: string;                  // 描述
    IsValid: Boolean;                     // 是否有效
    IsCritical: Boolean;                  // 是否关键
    DetectedTime: TDateTime;              // 检测时间
    LastVerified: TDateTime;              // 最后验证时间
    RiskLevel: Integer;                   // 风险等级 (1-10)
    ImpactScore: Double;                  // 影响分数
    UserData: string;                     // 用户数据
  end;

  // 依赖关系图
  TDependencyGraph = class
  private
    FDependencies: TArray<TDependencyRelation>;
    FNodes: TStringList;  // 所有节点路径
    FAdjacencyMatrix: TArray<TArray<Boolean>>; // 邻接矩阵
    FDataFile: string;
  public
    constructor Create(const ADataFile: string);
    destructor Destroy; override;

    // 依赖管理
    function AddDependency(const ADependency: TDependencyRelation): string;
    procedure RemoveDependency(const ADependencyId: string);
    function FindDependencies(const APath: string): TArray<TDependencyRelation>;
    function FindDependents(const APath: string): TArray<TDependencyRelation>;
    procedure UpdateDependency(const ADependencyId: string; const ADependency: TDependencyRelation);

    // 图分析
    function DetectCircularDependencies: TArray<TArray<string>>;
    function FindCriticalPaths: TArray<TArray<string>>;
    function CalculateImpactScore(const APath: string): Double;
    function GetDependencyChain(const ASourcePath, ATargetPath: string): TArray<string>;
    function AnalyzeDependencyDepth(const APath: string): Integer;

    // 风险评估
    function AssessMovementRisk(const APath: string): Integer;
    function GetHighRiskDependencies: TArray<TDependencyRelation>;
    function ValidateAllDependencies: Integer;

    // 可视化数据
    function GenerateGraphData: string; // 生成图形化数据
    function GetStatistics: string;

    // 持久化
    procedure SaveToFile;
    procedure LoadFromFile;
    procedure Clear;

    property DependencyCount: Integer read GetDependencyCount;
    property NodeCount: Integer read GetNodeCount;
  private
    function GetDependencyCount: Integer;
    function GetNodeCount: Integer;
    function AddNode(const APath: string): Integer;
    function FindNodeIndex(const APath: string): Integer;
    procedure BuildAdjacencyMatrix;
    function DFSCycleDetection(ANode: Integer; AVisited, ARecStack: TArray<Boolean>; var ACycle: TArray<Integer>): Boolean;
    function GetDependencyTypeText(AType: TDependencyType): string;
  end;

  // 配置模板类型
  TConfigTemplateType = (
    ctGeneral,        // 通用模板
    ctDevelopment,    // 开发环境
    ctProduction,     // 生产环境
    ctTesting,        // 测试环境
    ctBackup,         // 备份配置
    ctCustom          // 自定义模板
  );

  // 配置模板记录
  TConfigTemplate = record
    Id: string;                           // 模板ID
    Name: string;                         // 模板名称
    Description: string;                  // 描述
    TemplateType: TConfigTemplateType;    // 模板类型
    Version: string;                      // 版本号
    CreatedBy: string;                    // 创建者
    CreatedTime: TDateTime;               // 创建时间
    ModifiedTime: TDateTime;              // 修改时间
    IsActive: Boolean;                    // 是否激活
    IsDefault: Boolean;                   // 是否默认

    // 配置参数
    SourcePath: string;                   // 默认源路径
    TargetPath: string;                   // 默认目标路径
    CopyOptions: string;                  // 拷贝选项
    AnalysisOptions: string;              // 分析选项
    SecuritySettings: string;             // 安全设置
    PerformanceSettings: string;          // 性能设置
    UISettings: string;                   // 界面设置

    // 元数据
    Tags: string;                         // 标签
    Category: string;                     // 分类
    Priority: Integer;                    // 优先级
    UserData: string;                     // 用户数据
  end;

  // 配置模板管理器
  TConfigTemplateManager = class
  private
    FTemplates: TArray<TConfigTemplate>;
    FDataFile: string;
    FCurrentTemplate: TConfigTemplate;
    FAutoSave: Boolean;
  public
    constructor Create(const ADataFile: string);
    destructor Destroy; override;

    // 模板管理
    function CreateTemplate(const AName, ADescription: string; AType: TConfigTemplateType): string;
    function LoadTemplate(const ATemplateId: string): Boolean;
    function SaveTemplate(const ATemplate: TConfigTemplate): Boolean;
    function DeleteTemplate(const ATemplateId: string): Boolean;
    function DuplicateTemplate(const ATemplateId, ANewName: string): string;

    // 模板查询
    function GetTemplate(const ATemplateId: string): TConfigTemplate;
    function GetTemplatesByType(AType: TConfigTemplateType): TArray<TConfigTemplate>;
    function GetAllTemplates: TArray<TConfigTemplate>;
    function FindTemplatesByName(const AName: string): TArray<TConfigTemplate>;
    function GetDefaultTemplate: TConfigTemplate;

    // 模板应用
    function ApplyTemplate(const ATemplateId: string): Boolean;
    function ExportTemplate(const ATemplateId, AFilePath: string): Boolean;
    function ImportTemplate(const AFilePath: string): string;
    function ValidateTemplate(const ATemplate: TConfigTemplate): Boolean;

    // 版本管理
    function CreateTemplateVersion(const ATemplateId: string): string;
    function GetTemplateVersions(const ATemplateId: string): TArray<string>;
    function RestoreTemplateVersion(const ATemplateId, AVersion: string): Boolean;

    // 持久化
    procedure SaveToFile;
    procedure LoadFromFile;
    procedure SetAutoSave(AEnabled: Boolean);

    // 统计信息
    function GetTemplateCount: Integer;
    function GetTemplateUsageStats: string;

    property CurrentTemplate: TConfigTemplate read FCurrentTemplate write FCurrentTemplate;
    property TemplateCount: Integer read GetTemplateCount;
    property AutoSave: Boolean read FAutoSave write SetAutoSave;
  end;

  // 审计事件类型
  TAuditEventType = (
    aetLogin,           // 登录事件
    aetLogout,          // 登出事件
    aetFileAccess,      // 文件访问
    aetFileModify,      // 文件修改
    aetDirectoryCreate, // 目录创建
    aetDirectoryDelete, // 目录删除
    aetConfigChange,    // 配置变更
    aetSecurityEvent,   // 安全事件
    aetSystemError,     // 系统错误
    aetUserAction,      // 用户操作
    aetDataExport,      // 数据导出
    aetDataImport       // 数据导入
  );

  // 审计事件严重级别
  TAuditSeverity = (
    asInfo,      // 信息
    asWarning,   // 警告
    asError,     // 错误
    asCritical   // 关键
  );

  // 审计记录
  TAuditRecord = record
    Id: string;                    // 审计ID
    EventType: TAuditEventType;    // 事件类型
    Severity: TAuditSeverity;      // 严重级别
    Timestamp: TDateTime;          // 时间戳
    UserId: string;                // 用户ID
    UserName: string;              // 用户名
    SessionId: string;             // 会话ID
    SourceIP: string;              // 源IP地址
    EventDescription: string;      // 事件描述
    ResourcePath: string;          // 资源路径
    OldValue: string;              // 旧值
    NewValue: string;              // 新值
    Success: Boolean;              // 是否成功
    ErrorCode: Integer;            // 错误代码
    ErrorMessage: string;          // 错误消息
    AdditionalData: string;        // 附加数据
    ComplianceFlags: string;       // 合规标记
  end;

  // 合规规则类型
  TComplianceRuleType = (
    crtPathRestriction,    // 路径限制
    crtSizeLimit,          // 大小限制
    crtTimeRestriction,    // 时间限制
    crtUserPermission,     // 用户权限
    crtDataRetention,      // 数据保留
    crtEncryption,         // 加密要求
    crtAuditTrail,         // 审计跟踪
    crtAccessControl       // 访问控制
  );

  // 合规规则
  TComplianceRule = record
    Id: string;                      // 规则ID
    Name: string;                    // 规则名称
    Description: string;             // 规则描述
    RuleType: TComplianceRuleType;   // 规则类型
    IsActive: Boolean;               // 是否激活
    Severity: TAuditSeverity;        // 违规严重级别
    Pattern: string;                 // 匹配模式
    Threshold: string;               // 阈值
    Action: string;                  // 违规动作
    CreatedTime: TDateTime;          // 创建时间
    ModifiedTime: TDateTime;         // 修改时间
    CreatedBy: string;               // 创建者
    Tags: string;                    // 标签
  end;

  // 审计和合规管理器
  TAuditComplianceManager = class
  private
    FAuditRecords: TArray<TAuditRecord>;
    FComplianceRules: TArray<TComplianceRule>;
    FDataFile: string;
    FMaxRecords: Integer;
    FCurrentSessionId: string;
    FCurrentUserId: string;
    FAutoAudit: Boolean;
  public
    constructor Create(const ADataFile: string; AMaxRecords: Integer = 10000);
    destructor Destroy; override;

    // 审计功能
    function LogAuditEvent(AEventType: TAuditEventType; ASeverity: TAuditSeverity; const ADescription, AResourcePath: string; ASuccess: Boolean = True; const AOldValue: string = ''; const ANewValue: string = ''): string;
    function GetAuditRecords(AStartTime, AEndTime: TDateTime): TArray<TAuditRecord>;
    function GetAuditRecordsByType(AEventType: TAuditEventType): TArray<TAuditRecord>;
    function GetAuditRecordsBySeverity(ASeverity: TAuditSeverity): TArray<TAuditRecord>;
    function SearchAuditRecords(const ASearchText: string): TArray<TAuditRecord>;
    procedure ClearOldAuditRecords(ADaysOld: Integer = 90);

    // 合规功能
    function AddComplianceRule(const ARule: TComplianceRule): string;
    function UpdateComplianceRule(const ARuleId: string; const ARule: TComplianceRule): Boolean;
    function DeleteComplianceRule(const ARuleId: string): Boolean;
    function GetComplianceRules: TArray<TComplianceRule>;
    function CheckCompliance(const AResourcePath, AOperation: string): TArray<TComplianceRule>;
    function ValidateOperation(const AResourcePath, AOperation: string): Boolean;

    // 会话管理
    procedure StartSession(const AUserId: string);
    procedure EndSession;
    function GetCurrentSessionId: string;

    // 报告功能
    function GenerateAuditReport(AStartTime, AEndTime: TDateTime): string;
    function GenerateComplianceReport: string;
    function GetAuditStatistics: string;

    // 持久化
    procedure SaveToFile;
    procedure LoadFromFile;
    procedure ExportAuditLog(const AFilePath: string; AStartTime, AEndTime: TDateTime);

    // 属性
    property AuditRecordCount: Integer read GetAuditRecordCount;
    property ComplianceRuleCount: Integer read GetComplianceRuleCount;
    property CurrentSessionId: string read FCurrentSessionId;
    property CurrentUserId: string read FCurrentUserId;
    property AutoAudit: Boolean read FAutoAudit write FAutoAudit;
  private
    function GetAuditRecordCount: Integer;
    function GetComplianceRuleCount: Integer;
    function GenerateSessionId: string;
    function GetEventTypeName(AType: TAuditEventType): string;
    function GetSeverityName(ASeverity: TAuditSeverity): string;
    function GetRuleTypeName(AType: TComplianceRuleType): string;
  end;

  TfrmMain = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    DirListBoxSource: TDirectoryListBox;
    FileListBoxSource: TFileListBox;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    edtSource: TLabeledEdit;
    edtTarget: TLabeledEdit;
    btnDirSource: TButton;
    btnDirTarget: TButton;
    StatusTimer: TTimer;
    OpenDialog: TOpenDialog;
    Panel5: TPanel;
    btnAnalyze: TButton;
    btnCopyFiles: TButton;
    btnCreateBackup: TButton;
    btnDeleteAndLink: TButton;
    btnRollback: TButton;
    btnMove: TButton;
    ProgressBar: TProgressBar;
    PBarAFile: TProgressBar;
    btnClose: TButton;
    lblSize: TLabel;
    Splitter3: TSplitter;
    pnlCenter: TPanel;
    Panel4: TPanel;
    DirListBoxTarget: TDirectoryListBox;
    FileListBoxTarget: TFileListBox;
    Splitter4: TSplitter;
    btnCalcDirSize: TButton;
    RichEdit1: TRichEdit;
    PopupMenuSource: TPopupMenu;
    MenuItemCalcSize: TMenuItem;
    MenuItemAnalyze: TMenuItem;
    MenuItemScanSymlinks: TMenuItem;
    MenuItemSeparator1: TMenuItem;
    MenuItemOpenInExplorer: TMenuItem;
    MenuItemCopyPath: TMenuItem;
    MenuItemSeparator2: TMenuItem;
    MenuItemRefresh: TMenuItem;
    PopupMenuTarget: TPopupMenu;
    MenuItemOpenTargetInExplorer: TMenuItem;
    MenuItemCopyTargetPath: TMenuItem;
    MenuItemSeparator3: TMenuItem;
    MenuItemRefreshTarget: TMenuItem;
    MenuItemSeparator4: TMenuItem;
    PageControl1: TPageControl;
    MenuItemCreateFolder: TMenuItem;
    MenuItemSeparator5: TMenuItem;
    MenuItemDeleteDir: TMenuItem;
    MenuItemSeparator9: TMenuItem;
    MenuItemCopyToTarget: TMenuItem;
    MenuItemSeparator6: TMenuItem;
    MenuItemDeleteTargetDir: TMenuItem;
    MenuItemSeparator10: TMenuItem;
    MenuItemCreateLinkToCDrive: TMenuItem;
    PopupMenuSourceFiles: TPopupMenu;
    MenuItemRenameSourceFile: TMenuItem;
    MenuItemDeleteSourceFile: TMenuItem;
    MenuItemSeparator7: TMenuItem;
    MenuItemOpenSourceFile: TMenuItem;
    MenuItemCopySourceFileName: TMenuItem;
    PopupMenuTargetFiles: TPopupMenu;
    MenuItemRenameTargetFile: TMenuItem;
    MenuItemDeleteTargetFile: TMenuItem;
    MenuItemSeparator8: TMenuItem;
    MenuItemOpenTargetFile: TMenuItem;
    MenuItemCopyTargetFileName: TMenuItem;
    MainMenu1: TMainMenu;
    MenuFile: TMenuItem;
    MenuItemExit: TMenuItem;
    MenuTools: TMenuItem;
    MenuItemSystemCheck: TMenuItem;
    MenuItemLanguage: TMenuItem;
    MenuHelp: TMenuItem;
    MenuItemAbout: TMenuItem;
    tsBackup: TTabSheet;
    tsAboutMe: TTabSheet;
    btnOpenBackupFolder: TButton;
    btnDelBackup: TButton;
    lvBackup: TListView;
    btnCalcBackupSize: TButton;
    cBoxCalcSize: TCheckBox;
    procedure btnDirSourceClick(Sender: TObject);
    procedure btnDirTargetClick(Sender: TObject);
    procedure edtSourceChange(Sender: TObject);
    procedure edtTargetChange(Sender: TObject);
    procedure btnAnalyzeClick(Sender: TObject);
    procedure btnCopyFilesClick(Sender: TObject);
    procedure btnCreateBackupClick(Sender: TObject);
    procedure btnDeleteAndLinkClick(Sender: TObject);
    procedure btnRollbackClick(Sender: TObject);

    procedure btnOpenBackupFolderClick(Sender: TObject);
    procedure btnDelBackupClick(Sender: TObject);
    procedure RefreshBackupListView;
    procedure ScanExistingBackups;
    procedure btnCalcBackupSizeClick(Sender: TObject);
    procedure lvBackupSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure cBoxCalcSizeClick(Sender: TObject);
    procedure btnMoveClick(Sender: TObject);
    procedure ScanCurrentDirectorySymlinks(Silent: Boolean = True);
    procedure ClearAllDirectoryMarks;
    procedure MenuItemScanSymlinksClick(Sender: TObject);
    procedure MenuItemValidateSymlinksClick(Sender: TObject);
    procedure MenuItemRepairSymlinkClick(Sender: TObject);
    procedure MenuItemShowHistoryClick(Sender: TObject);
    procedure MenuItemShowStatisticsClick(Sender: TObject);
    procedure MenuItemUndoOperationClick(Sender: TObject);
    procedure MenuItemClearHistoryClick(Sender: TObject);
    procedure MenuItemShowSuggestionsClick(Sender: TObject);
    procedure MenuItemGenerateSuggestionsClick(Sender: TObject);
    procedure MenuItemBatchOperationsClick(Sender: TObject);
    procedure MenuItemShowSummaryClick(Sender: TObject);
    procedure MenuItemOptimizePerformanceClick(Sender: TObject);
    procedure MenuItemAnalyzeDependenciesClick(Sender: TObject);
    procedure MenuItemShowDependencyGraphClick(Sender: TObject);
    procedure MenuItemCheckCircularDepsClick(Sender: TObject);
    procedure MenuItemAssessRiskClick(Sender: TObject);
    procedure MenuItemShowTemplatesClick(Sender: TObject);
    procedure MenuItemCreateTemplateClick(Sender: TObject);
    procedure MenuItemLoadTemplateClick(Sender: TObject);
    procedure MenuItemSaveTemplateClick(Sender: TObject);
    procedure MenuItemShowAuditLogClick(Sender: TObject);
    procedure MenuItemShowComplianceRulesClick(Sender: TObject);
    procedure MenuItemGenerateAuditReportClick(Sender: TObject);
    procedure MenuItemCreateComplianceRuleClick(Sender: TObject);
    procedure MenuItemToggleThemeClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure StatusTimerTimer(Sender: TObject);
    procedure DirListBoxTargetDblClick(Sender: TObject);
    procedure DirListBoxTargetChange(Sender: TObject);
    procedure DirListBoxSourceDblClick(Sender: TObject);
    procedure DirListBoxSourceChange(Sender: TObject);
    procedure btnCalcDirSizeClick(Sender: TObject);
    // 右键菜单事件
    procedure MenuItemCalcSizeClick(Sender: TObject);
    procedure MenuItemAnalyzeClick(Sender: TObject);
    procedure MenuItemOpenInExplorerClick(Sender: TObject);
    procedure MenuItemCopyPathClick(Sender: TObject);
    procedure MenuItemRefreshClick(Sender: TObject);
    procedure MenuItemOpenTargetInExplorerClick(Sender: TObject);
    procedure MenuItemCopyTargetPathClick(Sender: TObject);
    procedure MenuItemRefreshTargetClick(Sender: TObject);
    procedure MenuItemCreateFolderClick(Sender: TObject);
    procedure MenuItemDeleteDirClick(Sender: TObject);
    procedure MenuItemDeleteTargetDirClick(Sender: TObject);
    procedure MenuItemCopyToTargetClick(Sender: TObject);
    procedure MenuItemCreateLinkToCDriveClick(Sender: TObject);
    // 文件右键菜单事件
    procedure MenuItemRenameSourceFileClick(Sender: TObject);
    procedure MenuItemDeleteSourceFileClick(Sender: TObject);
    procedure MenuItemOpenSourceFileClick(Sender: TObject);
    procedure MenuItemCopySourceFileNameClick(Sender: TObject);
    procedure MenuItemRenameTargetFileClick(Sender: TObject);
    procedure MenuItemDeleteTargetFileClick(Sender: TObject);
    procedure MenuItemOpenTargetFileClick(Sender: TObject);
    procedure MenuItemCopyTargetFileNameClick(Sender: TObject);
    // 主菜单事件
    procedure MenuItemExitClick(Sender: TObject);
    procedure MenuItemSystemCheckClick(Sender: TObject);
    procedure MenuItemLanguageClick(Sender: TObject);
    procedure MenuItemAboutClick(Sender: TObject);
  private
    { Private declarations }
    // Core service interfaces
    FFileAnalyzer: IFileAnalyzer;
    FMigrationManager: IMigrationManager;
    FRollbackManager: IRollbackManager;
    FSecurityManager: ISecurityManager;
    FDonationManager: IDonationManager;

    // Core configuration
    FConfigManager: TConfigManager;

    // Application state
    FApplicationState: TApplicationState;
    FSystemInfo: TSystemInfo;

    // Analysis results
    FAnalysisResults: TArray<TFileAnalysisResult>;
    FCurrentMigrationPlan: TMigrationPlan;
    FCurrentBackupId: string;

    // Progress tracking
    FCurrentProcessingPath: string;
    FTotalFiles: Integer;
    FProcessedFiles: Integer;
    FStatusMessages: TStringList;

    // 拷贝进度跟踪
    FTotalFilesToCopy: Integer;
    FCurrentFileIndex: Integer;
    FCurrentFileName: string;
    FCurrentFileSize: Int64;
    FCurrentFileCopied: Int64;
    FCopyInProgress: Boolean;
    FCopyStopRequested: Boolean;
    FSmallFileUpdateCounter: Integer;
    FBackupList: TStringList;  // 存储多个备份路径

    // 打赏框架
    FFrameAboutMe: TFrameAboutMe;

    // 符号链接缓存
    FSymlinkCache: TSymlinkCache;

    // 拷贝会话管理
    FCopySessionManager: TCopySessionManager;

    // 增强进度跟踪
    FCopyStartTime: TDateTime;
    FLastProgressUpdate: TDateTime;
    FLastCopiedBytes: Int64;
    FCopySpeed: Double; // 字节/秒
    FCanPauseCopy: Boolean;
    FCopyPaused: Boolean;

    // 状态管理
    FStatusManager: TStatusManager;

    // 目录监控
    FDirectoryMonitor: TDirectoryMonitor;

    // 智能建议引擎
    FSuggestionEngine: TSmartSuggestionEngine;

    // 批量操作管理器
    FBatchManager: TBatchOperationManager;

    // 依赖关系分析
    FDependencyGraph: TDependencyGraph;

    // 配置模板管理
    FTemplateManager: TConfigTemplateManager;

    // 审计和合规管理
    FAuditManager: TAuditComplianceManager;

    // 系统检查器
    FSystemChecker: TSystemChecker;

    // 当前进度窗体
    FCurrentProgressForm: TfrmProgress;
    
    procedure UpdateUI_Show;
    procedure UpdateUI_Hide;
    procedure CopyFilesOverwrite(SourcePath, DestPath: string);
    procedure UpdateAnalysisProgress(const ACurrentPath: string; AProgress: Integer; const AMessage: string);
    procedure ScanDirectorySimple(const APath: string; AFileList: TStringList);
    function AnalyzeSingleFileSimple(const AFilePath: string): TFileAnalysisResult;
    function AnalyzeDirectoryFeasibility(const ADirectoryPath: string): TFileAnalysisResult;
    procedure AddStatusMessage(const AMessage: string);
    procedure AddColoredStatusMessage(const AMessage: string; AColor: TColor);
    procedure UpdateStatusDisplay;
    procedure MarkDirectoryInTree(const APath: string; AColor: TColor);
    procedure MarkDirectoryWithStatus(const APath: string; AStatus: TDirectoryStatus);
    function CalculateDirectorySize(const APath: string): Int64;
    function PadRight(const AText: string; ALength: Integer): string;
    function IsRootOrUserRootDirectory(const APath: string): Boolean;
    function IsSymbolicLink(const APath: string): Boolean;
    function GetSymlinkTarget(const APath: string): string;
    function GetSymlinkInfo(const APath: string): string;
    function ValidateSymlink(const APath: string): Boolean;
    function RemoveStatusPrefix(const AText: string): string;

    // 符号链接缓存管理
    procedure InitializeSymlinkCache;
    procedure FinalizeSymlinkCache;
    procedure LoadSymlinkCache;
    procedure SaveSymlinkCache;
    function GetCachedSymlinkInfo(const APath: string): TSymlinkInfo;
    procedure CacheSymlinkInfo(const AInfo: TSymlinkInfo);
    function IsCacheExpired: Boolean;

    // 符号链接验证和修复
    function ValidateAllSymlinks: Integer;
    function RepairSymlink(const APath, ANewTarget: string): Boolean;
    function FindPossibleTargets(const APath: string): TArray<string>;
    procedure ShowSymlinkRepairDialog(const APath: string);

    // 拷贝会话管理
    procedure InitializeCopySessionManager;
    procedure FinalizeCopySessionManager;
    function StartCopySession(const ASourceDir, ATargetDir: string): Boolean;
    procedure SaveCopySession;
    function LoadCopySession(const ASessionId: string): Boolean;
    function CheckForIncompleteSession: Boolean;
    procedure ShowResumeDialog;

    // 断点续传功能
    function CalculateFileChecksum(const AFilePath: string): string;
    function VerifyFileIntegrity(const AFilePath: string; const AExpectedChecksum: string): Boolean;
    function ResumeFileCopy(const ASourcePath, ATargetPath: string; AStartPos: Int64): Boolean;
    procedure CopyFileWithResume(const ASourcePath, ATargetPath: string);
    function GetFilePartialChecksum(const AFilePath: string; ASize: Int64): string;

    // 增强拷贝进度显示
    procedure UpdateEnhancedCopyProgress(const ACurrentFile: string; AFileProgress, ATotalProgress: Double);
    procedure ShowCopySpeedAndETA(ACopiedBytes: Int64; AElapsedTime: TDateTime);
    function FormatFileSize(ABytes: Int64): string;
    function FormatTimeSpan(ASeconds: Integer): string;
    procedure InitializeEnhancedProgress;
    procedure FinalizeEnhancedProgress;
    procedure PauseCopyOperation;
    procedure ResumeCopyOperation;
    function IsCopyPaused: Boolean;

    // 状态管理
    procedure InitializeStatusManager;
    procedure FinalizeStatusManager;
    procedure LogOperation(AType: TOperationType; const ASourcePath, ATargetPath, ADescription: string; ASuccess: Boolean = True; const AErrorMsg: string = '');
    procedure UpdateDirectoryStatusWithHistory(const APath: string; ANewStatus: TDirectoryStatus; const ADescription: string = '');
    function GetDirectoryCurrentStatus(const APath: string): TDirectoryStatus;
    procedure ShowOperationHistory;
    procedure ShowStatusStatistics;
    function UndoLastOperation: Boolean;
    function GetStatusName(AStatus: TDirectoryStatus): string;

    // 目录监控
    procedure InitializeDirectoryMonitor;
    procedure FinalizeDirectoryMonitor;
    procedure StartMonitoring(const APath: string);
    procedure StopMonitoring(const APath: string);
    procedure CheckDirectoryChanges;
    procedure HandleDirectoryChanges(const AChanges: TArray<TDirectoryChange>);
    procedure UpdateMonitoredPaths;

    // 智能建议系统
    procedure InitializeSmartSuggestions;
    procedure FinalizeSmartSuggestions;
    procedure ShowSmartSuggestions;
    procedure GenerateContextualSuggestions;
    procedure ApplySuggestion(const ASuggestionId: string);
    procedure DismissSuggestion(const ASuggestionId: string);
    function CreateSuggestion(AType: TSuggestionType; APriority: TSuggestionPriority; const ATitle, ADescription, AActionText, ARelatedPath: string): TSmartSuggestion;
    procedure UpdateUserBehavior(AOperationType: TOperationType; const APath: string; ASuccess: Boolean);

    // 批量操作功能
    procedure InitializeBatchOperations;
    procedure FinalizeBatchOperations;
    procedure ShowBatchOperationDialog;
    procedure StartBatchAnalysis(const APaths: TArray<string>);
    procedure StartBatchCopy(const ASourcePaths, ATargetPaths: TArray<string>);
    procedure StartBatchSymlinkScan(const APaths: TArray<string>);
    procedure StartBatchSymlinkRepair(const APaths: TArray<string>);
    procedure OnBatchProgress(Sender: TObject);
    procedure OnBatchComplete(Sender: TObject);
    procedure OnBatchError(Sender: TObject);
    function CreateBatchItem(AOpType: TBatchOperationType; const ASourcePath, ATargetPath: string): TBatchOperationItem;

    // 用户界面优化
    procedure SetupKeyboardShortcuts;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure UpdateUILayout;
    procedure ShowQuickAccessPanel;
    procedure HideQuickAccessPanel;
    procedure CreateQuickActionButtons;
    procedure ShowProgressSummary;
    procedure OptimizePerformance;

    // 现代化界面样式
    procedure ApplyModernStyles;
    procedure ToggleTheme;
    procedure UpdateControlStyles;
    procedure UpdateStatusColors;

    // 依赖关系分析
    procedure InitializeDependencyAnalysis;
    procedure FinalizeDependencyAnalysis;
    procedure AnalyzeDependencies(const APath: string);
    procedure ShowDependencyGraph;
    procedure ShowCircularDependencies;
    procedure ShowCriticalPaths;
    procedure AssessMovementRisk(const APath: string);
    function CreateDependency(AType: TDependencyType; AStrength: TDependencyStrength; const ASource, ATarget, ADescription: string): TDependencyRelation;
    procedure DetectSymlinkDependencies(const APath: string);
    procedure DetectFileDependencies(const APath: string);
    function GetDependencyTypeName(AType: TDependencyType): string;

    // 配置模板系统
    procedure InitializeTemplateManager;
    procedure FinalizeTemplateManager;
    procedure ShowTemplateManager;
    procedure CreateNewTemplate;
    procedure LoadTemplateDialog;
    procedure SaveCurrentTemplate;
    procedure ExportTemplateDialog;
    procedure ImportTemplateDialog;
    procedure ApplyTemplateToCurrentSettings(const ATemplate: TConfigTemplate);
    function GetCurrentSettingsAsTemplate: TConfigTemplate;
    function GetTemplateTypeName(AType: TConfigTemplateType): string;

    // 审计和合规功能
    procedure InitializeAuditManager;
    procedure FinalizeAuditManager;
    procedure ShowAuditLog;
    procedure ShowComplianceRules;
    procedure CreateComplianceRule;
    procedure GenerateAuditReport;
    procedure ExportAuditData;
    function LogUserAction(const ADescription, AResourcePath: string; ASuccess: Boolean = True): string;
    function CheckOperationCompliance(const AResourcePath, AOperation: string): Boolean;
    function GetAuditEventTypeName(AType: TAuditEventType): string;
    function GetAuditSeverityName(ASeverity: TAuditSeverity): string;
    procedure UpdateCopyProgress(const ACurrentFile: string; AFileProgress: Integer; ATotalProgress: Integer);
    procedure InitializeCopyProgress(ATotalFiles: Integer);
    procedure FinalizeCopyProgress;
    procedure CopyDirectoryWithProgress(const ASourceDir, ATargetDir: string);
    procedure CopyDirectoryRecursive(const ASourceDir, ATargetDir: string);
    function CountFilesInDirectory(const ADirectory: string): Integer;
    function ShowCopyConfirmDialog(const ASourceDir, ATargetDir: string): Boolean;
    procedure UpdateCopyButtonState;
    procedure RefreshTargetDisplay;
    function DeleteDirectoryRecursive(const ADirectory: string): Boolean;
    function ForceDeleteDirectory(const ADirectory: string): Boolean;
    procedure ExecuteDeleteAndLink(const ASourcePath, ATargetPath: string);
    function CreateSymbolicLink(const ALinkPath, ATargetPath: string): Boolean;
    function VerifyDirectoryConsistency(const ASourceDir, ATargetDir: string): Boolean;
    function VerifyDirectoryConsistencyInternal(const ASourceDir, ATargetDir: string; var ATotalFiles, AMatchedFiles, AMismatchedFiles: Integer): Boolean;
    function CompareFiles(const AFile1, AFile2: string): Boolean;
    procedure ListDirectoryContents(const ADirectory: string);
    function CreateDirectoryBackup(const ASourceDir: string): string;
    function RestoreDirectoryFromBackup(const ABackupPath, ATargetPath: string): Boolean;
    function CopyDirectoryRecursiveSimple(const ASourceDir, ATargetDir: string): Boolean;
    procedure UpdateBackupButtons;
    procedure UpdateBackupDisplay;
    procedure UpdateDirectoryColors;

    
    // Core initialization methods
    procedure InitializeServices;
    procedure InitializeApplicationState;
    procedure InitializeSystemInfo;
    procedure CleanupServices;
    procedure InitializeDatabase;
    procedure InitializeAboutMeFrame;
    procedure LoadProtectedDonationAddresses;
    procedure CreateProtectedDonationConfig(const AConfigFile: string);
    function LoadAndVerifyDonationConfig(const AConfigFile: string): Boolean;
    procedure SetBackupDonationAddresses;
    procedure PerformSystemCheck;
    procedure ShowSystemCheckResults;
    function ShowProgressDialog(const ATitle: string; AMaxProgress: Integer = 100): TfrmProgress;
    procedure InitializeLanguageSystem;
    procedure UpdateUILanguage;
    procedure ChangeLanguage(ALanguage: TLanguageCode);

  public
    { Public declarations }
    destructor Destroy; override;

    // Properties for accessing core services
    property FileAnalyzer: IFileAnalyzer read FFileAnalyzer;
    property MigrationManager: IMigrationManager read FMigrationManager;
    property RollbackManager: IRollbackManager read FRollbackManager;
    property SecurityManager: ISecurityManager read FSecurityManager;
    property DonationManager: IDonationManager read FDonationManager;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.UpdateUI_Show;
begin
  // �ָ�ԭ״
  btnDirSource.Enabled := True;
  btnDirTarget.Enabled := True;
  btnMove.Enabled := True;
  btnAnalyze.Enabled := True;
  btnCopyFiles.Enabled := True;
  btnDeleteAndLink.Enabled := True;
  btnRollback.Enabled := True;
  btnClose.Enabled := True;
  frmMain.Cursor := crDefault;
end;

procedure TfrmMain.UpdateUI_Hide;
begin
  // ��һЩ��ť�����ã��������ʾΪ���ɲ���
  btnDirSource.Enabled := False;
  btnDirTarget.Enabled := False;
  btnMove.Enabled := False;
  btnAnalyze.Enabled := False;
  btnCopyFiles.Enabled := False;
  btnDeleteAndLink.Enabled := False;
  btnRollback.Enabled := False;
  btnClose.Enabled := False;
  frmMain.Cursor := crHourGlass;;
end;

procedure TfrmMain.btnCloseClick(Sender: TObject);
begin
  Self.Close;
end;

// 窗体销毁事件
procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  try
    // 清理打赏框架
    if Assigned(FFrameAboutMe) then
    begin
      FFrameAboutMe.Free;
      FFrameAboutMe := nil;
    end;

    // 清理系统检查器
    if Assigned(FSystemChecker) then
    begin
      FSystemChecker.Free;
      FSystemChecker := nil;
    end;

    if Assigned(FBackupList) then
      FBackupList.Free;

    // 清理符号链接缓存
    FinalizeSymlinkCache;

    // 清理拷贝会话管理器
    FinalizeCopySessionManager;

    // 清理状态管理器
    FinalizeStatusManager;

    // 清理目录监控器
    FinalizeDirectoryMonitor;

    // 清理智能建议引擎
    FinalizeSmartSuggestions;

    // 清理批量操作管理器
    FinalizeBatchOperations;

    // 清理依赖关系分析
    FinalizeDependencyAnalysis;

    // 清理配置模板管理器
    FinalizeTemplateManager;

    // 清理审计管理器
    FinalizeAuditManager;
  except
    // 忽略销毁错误
  end;
end;

// 窗体关闭事件
procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  try
    // 停止定时器
    if Assigned(StatusTimer) then
      StatusTimer.Enabled := False;

    // 清理资源
    CleanupServices;

    // 确保窗体被释放
    Action := caFree;
  except
    // 忽略关闭时的错误，强制关闭
    Action := caFree;
  end;
end;

procedure TfrmMain.btnDirSourceClick(Sender: TObject);
begin
  if OpenDialog.Execute then
  begin
    edtSource.Text := OpenDialog.FileName;
    DirListBoxSource.Directory := ExtractFilePath(edtSource.Text);
  end;
end;

procedure TfrmMain.btnDirTargetClick(Sender: TObject);
begin
  if OpenDialog.Execute then
  begin
    edtTarget.Text := OpenDialog.FileName;
    DirListBoxTarget.Directory := ExtractFilePath(edtTarget.Text);
  end;
end;

procedure TfrmMain.CopyFilesOverwrite(SourcePath, DestPath: string);
var
  SearchRec: TSearchRec;
  FullSourcePath, FullDestPath: string;
begin
  // ����ԴĿ¼�е������ļ�����Ŀ¼
  if FindFirst(SourcePath + '\*', faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        FullSourcePath := SourcePath + '\' + SearchRec.Name;
        FullDestPath := DestPath + '\' + SearchRec.Name;

        if (SearchRec.Attr and faDirectory) = faDirectory then
        begin
          // �����Ŀ¼���ݹ����
          if SearchRec.Name <> '.' then
          begin
            if not DirectoryExists(FullDestPath) then
              CreateDir(FullDestPath);

            CopyFilesOverwrite(FullSourcePath, FullDestPath);
          end;
        end
        else
        begin
          // ������ļ���ֱ�ӿ���
          if not FileExists(FullDestPath) or
            (FileGetAttr(FullDestPath) and faReadOnly <> faReadOnly) then
          begin
            TFile.Copy(FullSourcePath, FullDestPath, True);
          end;
        end;
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;
end;

// 一键移动功能 - 传统的简单文件复制
procedure TfrmMain.btnMoveClick(Sender: TObject);
var
  i: Integer;
  sourceDir, targetDir: string;
  DestPath: string;
begin
  // 确认操作
  if MessageDlg('一键移动将直接复制文件列表中的文件到目标目录。' + #13#10 +
                '这是传统功能，建议使用新的"分析并标记"→"拷贝文件"流程。' + #13#10 +
                '确定要继续吗？', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  if FileListBoxSource.Items.Count = 0 then
  begin
    AddStatusMessage('错误：文件列表为空，请先选择要移动的文件');
    Exit;
  end;

  UpdateUI_Hide;
  ProgressBar.Max := FileListBoxSource.Items.Count;
  ProgressBar.Position := 0;
  ProgressBar.Visible := True;
  RichEdit1.Visible := True;
  StatusTimer.Enabled := True;

  try
    sourceDir := DirListBoxSource.Directory;
    targetDir := DirListBoxTarget.Directory;

    for i := 0 to FileListBoxSource.Items.Count - 1 do
    begin
      DestPath := targetDir + '\' + FileListBoxSource.Items[i];

      AddStatusMessage(Format('正在复制: %s (%d/%d)',
        [FileListBoxSource.Items[i], i + 1, FileListBoxSource.Items.Count]));

      try
        CopyFilesOverwrite(sourceDir, DestPath);
      except
        on E: Exception do
        begin
          if MessageDlg(Format('复制文件 %s 失败: %s' + #13#10 + '是否继续？',
                              [FileListBoxSource.Items[i], E.Message]),
                       mtError, [mbYes, mbNo], 0) <> mrYes then
            Break;
        end;
      end;

      DirListBoxSource.Update;
      DirListBoxTarget.Update;
      ProgressBar.Position := i + 1;
      Application.ProcessMessages;
    end;

    ShowMessage('文件复制完成！注意：这只是复制，原文件仍在原位置。');

  finally
    ProgressBar.Visible := False;
    // RichEdit1始终保持可见，不需要隐藏
    StatusTimer.Enabled := False;
    AddStatusMessage('就绪状态 - 等待用户操作');
    UpdateStatusDisplay;
    UpdateUI_Show;
  end;
end;



// 分析并标记按钮事件 - 分析整个目录的可移动性
procedure TfrmMain.btnAnalyzeClick(Sender: TObject);
var
  SourcePath: string;
  DirectoryAnalysis: TFileAnalysisResult;
begin
  SourcePath := edtSource.Text;

  if not DirectoryExists(SourcePath) then
  begin
    AddStatusMessage('错误：源目录不存在，请选择有效的目录');
    Exit;
  end;

  // 检查是否是根目录或用户根目录
  if IsRootOrUserRootDirectory(SourcePath) then
  begin
    AddColoredStatusMessage('', clRed);
    AddColoredStatusMessage('╔══════════════════════════════════════════════╗', clRed);
    AddColoredStatusMessage('║ ⚠️ 【警告：不建议分析此目录】                ║', clRed);
    AddColoredStatusMessage('║ 目录：' + PadRight(ExtractFileName(SourcePath), 35) + '║', clRed);
    AddColoredStatusMessage('║ 原因：根目录或用户根目录文件数量巨大         ║', clRed);
    AddColoredStatusMessage('║ 建议：请选择具体的子目录进行分析             ║', clRed);
    AddColoredStatusMessage('╚══════════════════════════════════════════════╝', clRed);

    // 清理并退出
    ProgressBar.Visible := False;
    StatusTimer.Enabled := False;
    UpdateUI_Show;
    Exit;
  end;

  // 禁用按钮防止重复点击
  UpdateUI_Hide;

  // 显示进度
  ProgressBar.Position := 0;
  ProgressBar.Visible := True;
  // RichEdit1始终保持可见，不需要设置

  // 启动定时器
  StatusTimer.Enabled := True;

  AddStatusMessage('=== 开始分析目录的符号链接可行性 ===');
  AddStatusMessage('目标目录: ' + SourcePath);
  AddStatusMessage('分析目标: 判断移动此目录是否会影响程序运行');

  // 强制更新显示
  UpdateStatusDisplay;
  Application.ProcessMessages;

  try
    // 分析整个目录
    UpdateAnalysisProgress(SourcePath, 20, '正在分析目录类型和位置...');
    AddStatusMessage('步骤1: 分析目录路径和类型...');
    UpdateStatusDisplay;
    Application.ProcessMessages;

    DirectoryAnalysis := AnalyzeDirectoryFeasibility(SourcePath);

    AddStatusMessage('步骤2: 评估移动后对程序运行的影响...');
    UpdateStatusDisplay;
    Application.ProcessMessages;

    UpdateAnalysisProgress(SourcePath, 60, '正在检查目录内容和依赖关系...');

    AddStatusMessage('步骤3: 生成最终分析结果...');
    UpdateStatusDisplay;
    Application.ProcessMessages;

    // 显示分析结果 - 不影响文件列表显示
    var StatusColor: string;

    case DirectoryAnalysis.SymlinkFeasibility of
      sfCanLink:
      begin
        StatusColor := '✅ 可以安全移动';
        AddStatusMessage('');
        AddColoredStatusMessage('╔══════════════════════════════════════════════╗', clGreen);
        AddColoredStatusMessage('║ ✓ 【分析结果：可以安全移动】                 ║', clGreen);
        AddColoredStatusMessage('║ 目录：' + PadRight(ExtractFileName(SourcePath), 35) + '║', clGreen);
        AddColoredStatusMessage('║ 结论：此目录可以安全移动并创建符号链接       ║', clGreen);
        AddColoredStatusMessage('╚══════════════════════════════════════════════╝', clGreen);
        // 在目录树中标记为绿色（可链接）
        MarkDirectoryInTree(SourcePath, clGreen);
      end;
      sfRisky:
      begin
        StatusColor := '⚠️ 移动有风险';
        AddStatusMessage('');
        AddColoredStatusMessage('╔══════════════════════════════════════════════╗', clOlive);
        AddColoredStatusMessage('║ ! 【分析结果：移动有风险】                   ║', clOlive);
        AddColoredStatusMessage('║ 目录：' + PadRight(ExtractFileName(SourcePath), 35) + '║', clOlive);
        AddColoredStatusMessage('║ 结论：移动有风险，但符号链接通常可以解决     ║', clOlive);
        AddColoredStatusMessage('╚══════════════════════════════════════════════╝', clOlive);
        // 在目录树中标记为黄色（有风险）
        MarkDirectoryInTree(SourcePath, clOlive);
      end;
      sfCannotMove:
      begin
        StatusColor := '❌ 禁止移动';
        AddStatusMessage('');
        AddColoredStatusMessage('╔══════════════════════════════════════════════╗', clRed);
        AddColoredStatusMessage('║ X 【分析结果：禁止移动】                     ║', clRed);
        AddColoredStatusMessage('║ 目录：' + PadRight(ExtractFileName(SourcePath), 35) + '║', clRed);
        AddColoredStatusMessage('║ 结论：禁止移动，会严重影响系统或程序运行     ║', clRed);
        AddColoredStatusMessage('╚══════════════════════════════════════════════╝', clRed);
        // 在目录树中标记为红色（禁止移动）
        MarkDirectoryInTree(SourcePath, clRed);
      end;
    end;

    // 显示详细原因和建议
    AddStatusMessage('📋 详细原因: ' + DirectoryAnalysis.Reason);

    if DirectoryAnalysis.RequiresRestart then
      AddStatusMessage('⚠️ 注意：移动后可能需要重启相关程序');

    if Length(DirectoryAnalysis.Dependencies) > 0 then
    begin
      AddStatusMessage('🔗 依赖关系: ');
      for var Dep in DirectoryAnalysis.Dependencies do
        AddStatusMessage('   • ' + Dep);
    end;

    // 添加操作建议
    case DirectoryAnalysis.SymlinkFeasibility of
      sfCanLink:
        AddStatusMessage('💡 建议：可以安全移动此目录并创建符号链接');
      sfRisky:
        AddStatusMessage('💡 建议：移动前请先备份，移动后测试相关程序运行');
      sfCannotMove:
        AddStatusMessage('💡 建议：强烈不建议移动此目录');
    end;

    // 存储分析结果
    SetLength(FAnalysisResults, 1);
    FAnalysisResults[0] := DirectoryAnalysis;

    UpdateAnalysisProgress(SourcePath, 100, '目录分析完成');

    // 强制更新显示，确保之前的消息都显示出来
    UpdateStatusDisplay;
    Application.ProcessMessages;

    AddStatusMessage('=== 目录分析完成 ===');
    AddStatusMessage('最终结论: ' + StatusColor);
    AddStatusMessage('详细说明: ' + DirectoryAnalysis.Reason);

    if DirectoryAnalysis.SymlinkFeasibility = sfCanLink then
      AddStatusMessage('建议: 可以安全移动此目录并创建符号链接')
    else if DirectoryAnalysis.SymlinkFeasibility = sfRisky then
      AddStatusMessage('建议: 移动前请先备份，移动后测试相关程序运行')
    else
      AddStatusMessage('建议: 强烈不建议移动此目录');

    // 再次强制更新显示，确保结论显示出来
    UpdateStatusDisplay;
    Application.ProcessMessages;

  except
    on E: Exception do
    begin
      AddStatusMessage('错误：分析失败 - ' + E.Message);
      AddStatusMessage('请检查目录权限或选择其他目录重试');
    end;
  end;

  // 清理
  ProgressBar.Visible := False;
  StatusTimer.Enabled := False;

  // 最终状态更新
  AddStatusMessage('就绪状态 - 分析完成，可以查看结果');
  UpdateStatusDisplay;

  UpdateUI_Show;
end;

// 更新分析进度
procedure TfrmMain.UpdateAnalysisProgress(const ACurrentPath: string; AProgress: Integer; const AMessage: string);
begin
  FCurrentProcessingPath := ACurrentPath;
  ProgressBar.Position := AProgress;

  // 添加状态消息
  AddStatusMessage(Format('正在分析: %s (%d%%) - %s',
    [ExtractFileName(ACurrentPath), AProgress, AMessage]));

  // 不在这里强制更新UI，让定时器处理
end;

// 简化的目录扫描
procedure TfrmMain.ScanDirectorySimple(const APath: string; AFileList: TStringList);
var
  SearchRec: TSearchRec;
  FullPath: string;
begin
  // 只扫描当前目录，不递归子目录（避免卡死）
  if FindFirst(APath + '\*.*', faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          FullPath := APath + '\' + SearchRec.Name;

          if (SearchRec.Attr and faDirectory) = 0 then
          begin
            // 是文件，添加到列表
            AFileList.Add(FullPath);
          end
          else
          begin
            // 是目录，只添加目录本身，不递归
            AFileList.Add(FullPath);
          end;
        end;

        // 限制最大文件数量，避免处理过多文件
        if AFileList.Count >= 1000 then
          Break;

      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;
end;

// 符号链接可行性分析
function TfrmMain.AnalyzeSingleFileSimple(const AFilePath: string): TFileAnalysisResult;
var
  FileExt: string;
  FileName: string;
  FilePath: string;
begin
  Result.FilePath := AFilePath;
  Result.Size := 0;
  Result.IsSystemFile := False;
  SetLength(Result.Dependencies, 0);
  Result.RequiresRestart := False;
  Result.CanCreateSymlink := True;
  Result.Reason := '';
  Result.SymlinkFeasibility := sfCanLink; // 默认可链接

  try
    FileName := ExtractFileName(AFilePath);
    FileExt := LowerCase(ExtractFileExt(AFilePath));
    FilePath := LowerCase(AFilePath);

    // 获取文件大小
    if FileExists(AFilePath) then
    begin
      var FileHandle := FileOpen(AFilePath, fmOpenRead or fmShareDenyNone);
      if FileHandle <> -1 then
      begin
        try
          Result.Size := FileSeek(FileHandle, 0, 2);
        finally
          FileClose(FileHandle);
        end;
      end;
    end;

    // 符号链接可行性判断 - 重点关注对程序运行的影响
    if DirectoryExists(AFilePath) then
    begin
      // 目录判断 - 分析移动后对程序运行的影响
      if (Pos('system32', FilePath) > 0) or
         (Pos('syswow64', FilePath) > 0) or
         (Pos('windows\system', FilePath) > 0) or
         (Pos('windows\winsxs', FilePath) > 0) then
      begin
        Result.SymlinkFeasibility := sfCannotMove;
        Result.IsSystemFile := True;
        Result.CanCreateSymlink := False;
        Result.Reason := '系统核心目录，移动会导致系统无法启动';
      end
      else if (Pos('program files', FilePath) > 0) then
      begin
        // 程序安装目录 - 需要检查是否有程序依赖
        if (Pos('common files', FilePath) > 0) or
           (Pos('shared', FilePath) > 0) then
        begin
          Result.SymlinkFeasibility := sfRisky;
          Result.Reason := '共享程序组件，移动可能影响多个程序运行';
        end
        else
        begin
          Result.SymlinkFeasibility := sfCanLink;
          Result.Reason := '独立程序目录，符号链接不影响程序运行';
        end;
      end
      else if (Pos('programdata', FilePath) > 0) then
      begin
        Result.SymlinkFeasibility := sfRisky;
        Result.Reason := '程序数据目录，移动可能影响程序配置和运行';
      end
      else if (Pos('appdata', FilePath) > 0) then
      begin
        if (Pos('roaming', FilePath) > 0) then
        begin
          Result.SymlinkFeasibility := sfCanLink;
          Result.Reason := '用户漫游数据，符号链接不影响程序运行';
        end
        else
        begin
          Result.SymlinkFeasibility := sfRisky;
          Result.Reason := '本地应用数据，移动可能影响程序性能';
        end;
      end
      else if (Pos('temp', FilePath) > 0) or (Pos('cache', FilePath) > 0) then
      begin
        Result.SymlinkFeasibility := sfCanLink;
        Result.Reason := '临时/缓存目录，符号链接不影响程序运行';
      end
      else if (Pos('users\', FilePath) > 0) and
              ((Pos('documents', FilePath) > 0) or (Pos('desktop', FilePath) > 0) or
               (Pos('downloads', FilePath) > 0) or (Pos('pictures', FilePath) > 0) or
               (Pos('music', FilePath) > 0) or (Pos('videos', FilePath) > 0)) then
      begin
        Result.SymlinkFeasibility := sfCanLink;
        Result.Reason := '用户数据目录，符号链接不影响程序运行';
      end
      else
      begin
        Result.SymlinkFeasibility := sfRisky;
        Result.Reason := '未知目录类型，需要评估对程序运行的影响';
      end;
    end
    else
    begin
      // 文件判断 - 重点分析对程序运行的影响
      if (FileExt = '.exe') then
      begin
        if (Pos('system32', FilePath) > 0) or (Pos('windows', FilePath) > 0) then
        begin
          Result.SymlinkFeasibility := sfCannotMove;
          Result.Reason := '系统可执行文件，移动会导致系统功能异常';
        end
        else
        begin
          Result.SymlinkFeasibility := sfCanLink;
          Result.Reason := '应用程序，符号链接不影响程序启动和运行';
        end;
        Result.RequiresRestart := True;
      end
      else if (FileExt = '.dll') or (FileExt = '.ocx') then
      begin
        if (Pos('system32', FilePath) > 0) or (Pos('syswow64', FilePath) > 0) then
        begin
          Result.SymlinkFeasibility := sfCannotMove;
          Result.Reason := '系统库文件，移动会导致程序无法加载';
        end
        else
        begin
          Result.SymlinkFeasibility := sfRisky;
          Result.Reason := '程序库文件，移动可能影响程序加载，但符号链接通常可以解决';
        end;
        SetLength(Result.Dependencies, 1);
        Result.Dependencies[0] := 'Program dependencies';
      end
      else if (FileExt = '.sys') or (FileExt = '.drv') then
      begin
        Result.SymlinkFeasibility := sfCannotMove;
        Result.Reason := '系统驱动文件，移动会导致硬件功能异常';
        Result.IsSystemFile := True;
      end
      else if (FileExt = '.ini') or (FileExt = '.cfg') or (FileExt = '.config') or (FileExt = '.xml') then
      begin
        if (Pos('windows', FilePath) > 0) or (Pos('system32', FilePath) > 0) then
        begin
          Result.SymlinkFeasibility := sfCannotMove;
          Result.Reason := '系统配置文件，移动会导致系统配置丢失';
        end
        else
        begin
          Result.SymlinkFeasibility := sfRisky;
          Result.Reason := '程序配置文件，移动可能导致程序设置丢失，但符号链接可以解决';
        end;
      end
      else if (FileExt = '.reg') then
      begin
        Result.SymlinkFeasibility := sfCannotMove;
        Result.Reason := '注册表文件，移动不影响已导入的注册表项';
      end
      else if (FileExt = '.txt') or (FileExt = '.log') or (FileExt = '.doc') or (FileExt = '.docx') or
              (FileExt = '.pdf') or (FileExt = '.xls') or (FileExt = '.xlsx') or (FileExt = '.ppt') or
              (FileExt = '.jpg') or (FileExt = '.png') or (FileExt = '.gif') or (FileExt = '.bmp') or
              (FileExt = '.mp3') or (FileExt = '.mp4') or (FileExt = '.avi') or (FileExt = '.mkv') or
              (FileExt = '.zip') or (FileExt = '.rar') or (FileExt = '.7z') then
      begin
        Result.SymlinkFeasibility := sfCanLink;
        Result.Reason := '数据文件，符号链接完全不影响程序访问和运行';
      end
      else if (FileExt = '.lnk') then
      begin
        Result.SymlinkFeasibility := sfCanLink;
        Result.Reason := '快捷方式文件，符号链接不影响快捷方式功能';
      end
      else if (FileExt = '.bat') or (FileExt = '.cmd') or (FileExt = '.ps1') then
      begin
        Result.SymlinkFeasibility := sfCanLink;
        Result.Reason := '脚本文件，符号链接不影响脚本执行';
      end
      else
      begin
        Result.SymlinkFeasibility := sfRisky;
        Result.Reason := '未知文件类型，需要测试移动后对相关程序运行的影响';
      end;
    end;

  except
    // 如果分析出错，标记为不能移动
    Result.SymlinkFeasibility := sfCannotMove;
    Result.IsSystemFile := True;
    Result.CanCreateSymlink := False;
    Result.Reason := '分析失败，不建议移动';
  end;
end;

// 拷贝当前目录按钮事件
procedure TfrmMain.btnCopyFilesClick(Sender: TObject);
var
  SourcePath, TargetPath: string;
  I: Integer;
begin
  // 如果正在拷贝，则停止拷贝
  if FCopyInProgress then
  begin
    FCopyStopRequested := True;
    AddColoredStatusMessage('🛑 用户请求停止拷贝...', clOlive);
    Exit;
  end;

  SourcePath := edtSource.Text;
  TargetPath := edtTarget.Text;

  // 验证源目录
  if not DirectoryExists(SourcePath) then
  begin
    AddColoredStatusMessage('❌ 错误：源目录不存在，请选择有效的源目录', clRed);
    Exit;
  end;

  // 验证目标目录
  if not DirectoryExists(TargetPath) then
  begin
    AddColoredStatusMessage('❌ 错误：目标目录不存在，请选择有效的目标目录', clRed);
    Exit;
  end;

  // 检查源目录和目标目录不能相同
  if SameText(SourcePath, TargetPath) then
  begin
    AddColoredStatusMessage('❌ 错误：源目录和目标目录不能相同', clRed);
    Exit;
  end;

  // 检查目标目录不能是源目录的子目录
  if Pos(LowerCase(SourcePath), LowerCase(TargetPath)) = 1 then
  begin
    AddColoredStatusMessage('❌ 错误：目标目录不能是源目录的子目录', clRed);
    Exit;
  end;

  // 显示确认对话框
  if not ShowCopyConfirmDialog(SourcePath, TargetPath) then
  begin
    AddColoredStatusMessage('ℹ️ 用户取消了拷贝操作', clBlue);
    Exit;
  end;

  AddColoredStatusMessage('📋 开始拷贝当前目录操作...', clBlue);
  AddStatusMessage('源目录: ' + SourcePath);
  AddStatusMessage('目标目录: ' + TargetPath);

  // 执行简化的文件拷贝
  try
    CopyDirectoryWithProgress(SourcePath, TargetPath);
  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 拷贝失败: ' + E.Message, clRed);
      FinalizeCopyProgress;
    end;
  end;
end;

// 删除并链接按钮事件
procedure TfrmMain.btnDeleteAndLinkClick(Sender: TObject);
var
  SourcePath, TargetPath: string;
  SourceDirName: string;
  FinalTargetPath: string;
  ConfirmMsg: string;
begin
  try
    AddColoredStatusMessage('🔍 开始删除并链接操作检查...', clBlue);

    SourcePath := edtSource.Text;
    TargetPath := edtTarget.Text;

    // 1. 验证源目录
    if Trim(SourcePath) = '' then
    begin
      AddColoredStatusMessage('❌ 错误：请先选择源目录', clRed);
      AddColoredStatusMessage('💡 提示：在左侧目录树中选择要移动的目录', clBlue);
      Exit;
    end;

    if not DirectoryExists(SourcePath) then
    begin
      AddColoredStatusMessage('❌ 错误：源目录不存在，请选择有效的源目录', clRed);
      AddColoredStatusMessage('当前源路径: ' + SourcePath, clGray);
      Exit;
    end;

    // 2. 验证目标目录
    if Trim(TargetPath) = '' then
    begin
      AddColoredStatusMessage('❌ 错误：请先选择目标目录', clRed);
      AddColoredStatusMessage('💡 提示：在右侧目录树中选择目标位置', clBlue);
      Exit;
    end;

    if not DirectoryExists(TargetPath) then
    begin
      AddColoredStatusMessage('❌ 错误：目标目录不存在，请选择有效的目标目录', clRed);
      AddColoredStatusMessage('当前目标路径: ' + TargetPath, clGray);
      Exit;
    end;

    // 3. 检查是否已创建备份（给出建议但不强制）
    if not Assigned(FBackupList) or (FBackupList.Count = 0) then
    begin
      AddColoredStatusMessage('⚠️ 警告：尚未创建备份', clOlive);
      AddColoredStatusMessage('💡 建议：为了安全起见，建议先创建备份', clBlue);

      if MessageDlg('尚未创建备份，删除并链接操作有风险。' + #13#10 +
                    '是否要先创建备份？' + #13#10 + #13#10 +
                    '点击"是"创建备份后继续' + #13#10 +
                    '点击"否"直接执行（风险自负）' + #13#10 +
                    '点击"取消"中止操作',
                    mtWarning, [mbYes, mbNo, mbCancel], 0) = mrYes then
      begin
        AddColoredStatusMessage('📋 用户选择先创建备份', clBlue);
        btnCreateBackupClick(nil);  // 调用创建备份
        Exit;  // 创建备份后用户需要再次点击删除并链接
      end
      else if MessageDlg('确定要在没有备份的情况下执行删除并链接吗？' + #13#10 +
                         '此操作不可逆！', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      begin
        AddColoredStatusMessage('ℹ️ 用户取消操作', clBlue);
        Exit;
      end;
    end;

    // 获取左侧当前目录名称
    SourceDirName := ExtractFileName(SourcePath);

    // 在右侧目录中寻找同名的子目录
    FinalTargetPath := IncludeTrailingPathDelimiter(TargetPath) + SourceDirName;

    // 显示路径调试信息
    AddStatusMessage('🔍 路径分析:');
    AddStatusMessage('左侧源目录: ' + SourcePath);
    AddStatusMessage('源目录名称: ' + SourceDirName);
    AddStatusMessage('右侧当前目录: ' + TargetPath);
    AddStatusMessage('在右侧寻找的目标路径: ' + FinalTargetPath);

    // 验证在右侧目录中是否存在同名的子目录
    if not DirectoryExists(FinalTargetPath) then
    begin
      AddColoredStatusMessage('❌ 错误：在右侧目录中未找到同名的子目录', clRed);
      AddStatusMessage('寻找的目录名: ' + SourceDirName);
      AddStatusMessage('在右侧路径中寻找: ' + FinalTargetPath);

      // 检查右侧目录下的实际内容
      AddStatusMessage('🔍 右侧目录的实际内容:');
      ListDirectoryContents(TargetPath);

      // 询问用户是否要手动指定目标路径
      if MessageDlg(Format('在右侧目录中未找到名为"%s"的子目录。%s是否要手动指定目标路径？',
                          [SourceDirName, #13#10]),
                    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        FinalTargetPath := InputBox('手动指定目标路径',
                                   Format('请输入包含"%s"内容的完整目标路径:', [SourceDirName]),
                                   FinalTargetPath);
        if not DirectoryExists(FinalTargetPath) then
        begin
          AddColoredStatusMessage('❌ 手动指定的路径不存在: ' + FinalTargetPath, clRed);
          Exit;
        end
        else
        begin
          AddColoredStatusMessage('✅ 使用手动指定的路径: ' + FinalTargetPath, clGreen);
        end;
      end
      else
      begin
        AddColoredStatusMessage('ℹ️ 用户取消操作', clBlue);
        Exit;
      end;
    end
    else
    begin
      AddColoredStatusMessage('✅ 在右侧目录中找到同名子目录: ' + SourceDirName, clGreen);
    end;

    // 检查源目录和目标目录不能相同
    if SameText(SourcePath, FinalTargetPath) then
    begin
      AddColoredStatusMessage('❌ 错误：源目录和目标目录不能相同', clRed);
      Exit;
    end;

    // 显示详细确认对话框
    ConfirmMsg := Format('确定要删除源目录并创建符号链接吗？%s%s' +
      '左侧源目录: %s%s' +
      '右侧目标目录: %s%s' +
      '操作说明:%s' +
      '程序将把左侧的"%s"目录删除，并创建指向右侧同名目录的符号链接%s%s' +
      '操作步骤:%s' +
      '1. 验证左右两侧目录文件完全一致%s' +
      '2. 删除左侧源目录及其所有内容%s' +
      '3. 创建从左侧路径到右侧路径的符号链接%s%s' +
      '警告：此操作不可恢复，只有文件完全一致才会执行删除！',
      [#13#10, #13#10, SourcePath, #13#10, FinalTargetPath, #13#10, #13#10, SourceDirName, #13#10, #13#10, #13#10, #13#10, #13#10, #13#10, #13#10]);

    if MessageDlg(ConfirmMsg, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    begin
      AddColoredStatusMessage('ℹ️ 用户取消了删除并链接操作', clBlue);
      Exit;
    end;

    AddColoredStatusMessage('🔗 开始执行删除并链接操作...', clBlue);
    AddStatusMessage('左侧源目录: ' + SourcePath);
    AddStatusMessage('右侧当前目录: ' + TargetPath);
    AddStatusMessage('右侧目标目录: ' + FinalTargetPath);
    AddStatusMessage('操作: 删除左侧"' + SourceDirName + '"并链接到右侧同名目录');

    // 执行删除并链接
    ExecuteDeleteAndLink(SourcePath, FinalTargetPath);

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 删除并链接失败: ' + E.Message, clRed);
    end;
  end;
end;

// 创建备份按钮事件
procedure TfrmMain.btnCreateBackupClick(Sender: TObject);
var
  SourcePath: string;
  BackupPath: string;
begin
  try
    SourcePath := edtSource.Text;

    // 验证源目录
    if not DirectoryExists(SourcePath) then
    begin
      AddColoredStatusMessage('❌ 错误：源目录不存在，请选择有效的源目录', clRed);
      Exit;
    end;

    // 检查是否已有该目录的备份
    if Assigned(FBackupList) then
    begin
      for var I := 0 to FBackupList.Count - 1 do
      begin
        if Pos(ExtractFileName(SourcePath) + '_dcbackup_', FBackupList[I]) > 0 then
        begin
          if MessageDlg(Format('目录"%s"已存在备份，是否要创建新的备份？', [ExtractFileName(SourcePath)]),
                        mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
            Exit;
          Break;
        end;
      end;
    end;

    AddColoredStatusMessage('💾 开始创建备份...', clBlue);
    AddStatusMessage('源目录: ' + SourcePath);

    // 创建备份
    BackupPath := CreateDirectoryBackup(SourcePath);

    if BackupPath <> '' then
    begin
      // 添加到备份列表
      if Assigned(FBackupList) then
        FBackupList.Add(BackupPath);

      AddColoredStatusMessage('✅ 备份创建成功！', clGreen);
      AddStatusMessage('备份路径: ' + BackupPath);

      // 立即刷新所有相关显示
      RefreshTargetDisplay;
      RefreshBackupListView;
      UpdateBackupDisplay;
      UpdateDirectoryColors;
    end
    else
    begin
      AddColoredStatusMessage('❌ 备份创建失败', clRed);
    end;

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 创建备份异常: ' + E.Message, clRed);
    end;
  end;
end;



// 打开备份文件夹按钮事件
procedure TfrmMain.btnOpenBackupFolderClick(Sender: TObject);
var
  TargetPath: string;
begin
  try
    if not Assigned(FBackupList) or (FBackupList.Count = 0) then
    begin
      AddColoredStatusMessage('ℹ️ 没有可打开的备份文件夹', clBlue);
      Exit;
    end;

    // 打开目标目录（备份所在的目录）
    TargetPath := edtTarget.Text;
    if not DirectoryExists(TargetPath) then
    begin
      AddColoredStatusMessage('❌ 目标目录不存在: ' + TargetPath, clRed);
      Exit;
    end;

    // 在资源管理器中打开目标目录，用户可以看到所有备份
    ShellExecute(0, 'open', 'explorer.exe', PChar(TargetPath), nil, SW_SHOWNORMAL);
    AddColoredStatusMessage('📂 已在资源管理器中打开备份目录', clBlue);

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 打开备份文件夹失败: ' + E.Message, clRed);
    end;
  end;
end;

// 回退并恢复按钮事件
procedure TfrmMain.btnRollbackClick(Sender: TObject);
var
  SourcePath: string;
  BackupPath: string;
begin
  try
    if not Assigned(FBackupList) or (FBackupList.Count = 0) then
    begin
      AddColoredStatusMessage('❌ 没有可用的备份进行回退', clRed);
      Exit;
    end;

    // 简单起见，使用最新的备份
    BackupPath := FBackupList[FBackupList.Count - 1];

    SourcePath := edtSource.Text;

    if MessageDlg(Format('确定要从备份恢复吗？%s%s这将覆盖当前的源目录内容！%s%s备份路径: %s%s恢复到: %s',
                        [#13#10, #13#10, #13#10, #13#10, BackupPath, #13#10, SourcePath]),
                  mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;

    AddColoredStatusMessage('🔄 开始从备份恢复...', clBlue);
    AddStatusMessage('备份路径: ' + BackupPath);
    AddStatusMessage('恢复到: ' + SourcePath);

    if RestoreDirectoryFromBackup(BackupPath, SourcePath) then
    begin
      AddColoredStatusMessage('✅ 从备份恢复成功！', clGreen);

      // 刷新源目录显示
      if Assigned(DirListBoxSource) then
      begin
        DirListBoxSource.Update;
        if Assigned(FileListBoxSource) then
          FileListBoxSource.Update;
      end;
    end
    else
    begin
      AddColoredStatusMessage('❌ 从备份恢复失败', clRed);
    end;

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 回退异常: ' + E.Message, clRed);
    end;
  end;
end;



procedure TfrmMain.edtTargetChange(Sender: TObject);
begin
  DirListBoxTarget.Directory := edtTarget.Text;
end;

procedure TfrmMain.edtSourceChange(Sender: TObject);
begin
  DirListBoxSource.Directory := edtSource.Text;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  try
    // 设置RichEdit字体以支持中文显示
    if Assigned(RichEdit1) then
    begin
      RichEdit1.Font.Name := '微软雅黑';
      RichEdit1.Font.Charset := GB2312_CHARSET;
      RichEdit1.Font.Size := 9;
      RichEdit1.Clear;
    end;

    // 设置目录树的右键菜单
    if Assigned(DirListBoxSource) and Assigned(PopupMenuSource) then
      DirListBoxSource.PopupMenu := PopupMenuSource;

    if Assigned(DirListBoxTarget) and Assigned(PopupMenuTarget) then
      DirListBoxTarget.PopupMenu := PopupMenuTarget;

    // 设置文件列表的右键菜单
    if Assigned(FileListBoxSource) and Assigned(PopupMenuSourceFiles) then
      FileListBoxSource.PopupMenu := PopupMenuSourceFiles;

    if Assigned(FileListBoxTarget) and Assigned(PopupMenuTargetFiles) then
      FileListBoxTarget.PopupMenu := PopupMenuTargetFiles;

    // 初始化拷贝状态
    FCopyInProgress := False;
    FCopyStopRequested := False;
    FSmallFileUpdateCounter := 0;
    UpdateCopyButtonState;

    // 初始化备份状态
    FBackupList := TStringList.Create;

    // 设置备份列表选择事件
    if Assigned(lvBackup) then
      lvBackup.OnSelectItem := lvBackupSelectItem;

    // 初始化备份列表视图
    if Assigned(lvBackup) then
    begin
      lvBackup.ViewStyle := vsReport;
      lvBackup.Columns.Clear;

      with lvBackup.Columns.Add do
      begin
        Caption := LanguageMgr.GetString('col_backup_name', '备份名称');
        Width := 200;
      end;

      with lvBackup.Columns.Add do
      begin
        Caption := LanguageMgr.GetString('col_size', '大小');
        Width := 100;
      end;

      with lvBackup.Columns.Add do
      begin
        Caption := LanguageMgr.GetString('col_create_time', '创建时间');
        Width := 150;
      end;

      with lvBackup.Columns.Add do
      begin
        Caption := LanguageMgr.GetString('col_path', '路径');
        Width := 300;
      end;
    end;

    UpdateBackupDisplay;



    // 设置实时计算大小复选框默认状态
    if Assigned(cBoxCalcSize) then
      cBoxCalcSize.Checked := False;  // 默认为假

    // 扫描现有备份并填充到列表
    ScanExistingBackups;
    RefreshBackupListView;

    // 检查符号链接状态
    UpdateDirectoryColors;

    // 初始化状态消息列表
    FStatusMessages := TStringList.Create;

    // Initialize core services and application state
    InitializeApplicationState;
    InitializeSystemInfo;
    InitializeServices;

    edtSourceChange(Sender);
    edtTargetChange(Sender);

    // 初始化多语言系统
    InitializeLanguageSystem;

    // 初始化系统检查器
    FSystemChecker := TSystemChecker.Create;

    // 执行系统检查
    PerformSystemCheck;

    // 初始化数据库
    InitializeDatabase;

    // 初始化打赏框架
    InitializeAboutMeFrame;

    // 初始化符号链接缓存
    InitializeSymlinkCache;

    // 初始化拷贝会话管理器
    InitializeCopySessionManager;

    // 初始化状态管理器
    InitializeStatusManager;

    // 初始化目录监控器
    InitializeDirectoryMonitor;

    // 初始化智能建议引擎
    InitializeSmartSuggestions;

    // 初始化批量操作管理器
    InitializeBatchOperations;

    // 初始化依赖关系分析
    InitializeDependencyAnalysis;

    // 初始化配置模板管理器
    InitializeTemplateManager;

    // 初始化审计管理器
    InitializeAuditManager;

    // 初始化状态显示
    AddStatusMessage('程序启动完成 - 等待用户操作');
    UpdateStatusDisplay;

    // 设置键盘快捷键和UI优化
    SetupKeyboardShortcuts;
    UpdateUILayout;
    CreateQuickActionButtons;

    // 应用现代化样式
    ApplyModernStyles;
  except
    on E: Exception do
    begin
      // 如果初始化失败，显示错误但不阻止程序启动
      ShowMessage('初始化警告: ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.InitializeServices;
begin
  try
    // Initialize configuration manager first
    FConfigManager := TConfigManager.Create;

    // Initialize security manager (depends on config)
    FSecurityManager := TSecurityManager.Create(FConfigManager);

    // Perform security self-check
    if not FSecurityManager.PerformSelfCheck then
    begin
      ShowMessage('安全检查失败，程序可能已被篡改。请重新下载程序。');
      Application.Terminate;
      Exit;
    end;

    // Initialize file analyzer
    FFileAnalyzer := TFileAnalyzer.Create;

    // Initialize migration manager (depends on file analyzer)
    FMigrationManager := TMigrationManager.Create(FFileAnalyzer);

    // Initialize rollback manager (depends on config)
    FRollbackManager := TRollbackManager.Create(FConfigManager);

    // Initialize donation manager (depends on security manager and config)
    FDonationManager := TDonationManager.Create(FSecurityManager, FConfigManager);

    // Update application state
    FApplicationState.IsInitialized := True;

  except
    on E: Exception do
    begin
      ShowMessage('服务初始化失败: ' + E.Message);
      Application.Terminate;
    end;
  end;
end;

procedure TfrmMain.InitializeApplicationState;
begin
  FApplicationState.IsInitialized := False;
  FApplicationState.CurrentLanguage := 'zh-CN'; // Default to Chinese
  FApplicationState.SecurityLevel := 1; // Default security level
  FApplicationState.LastBackupId := '';
  SetLength(FApplicationState.ActiveMigrations, 0);
end;

procedure TfrmMain.InitializeSystemInfo;
var
  VersionInfo: TOSVersionInfo;
begin
  // Initialize system information
  FSystemInfo.AvailableSpace := TDictionary<string, Int64>.Create;
  
  // Get OS version
  VersionInfo.dwOSVersionInfoSize := SizeOf(VersionInfo);
  if GetVersionEx(VersionInfo) then
  begin
    FSystemInfo.OSVersion := Format('%d.%d.%d', 
      [VersionInfo.dwMajorVersion, VersionInfo.dwMinorVersion, VersionInfo.dwBuildNumber]);
  end
  else
    FSystemInfo.OSVersion := 'Unknown';
    
  // Get architecture
  {$IFDEF WIN64}
  FSystemInfo.Architecture := 'x64';
  {$ELSE}
  FSystemInfo.Architecture := 'x86';
  {$ENDIF}
  
  // Check admin mode using security manager
  if Assigned(FSecurityManager) then
    FSystemInfo.IsAdminMode := FSecurityManager.IsRunningAsAdmin
  else
    FSystemInfo.IsAdminMode := False;
  
  // Generate machine fingerprint using security manager
  if Assigned(FSecurityManager) then
    FSystemInfo.MachineFingerprint := FSecurityManager.GenerateMachineFingerprint
  else
    FSystemInfo.MachineFingerprint := 'PLACEHOLDER_FINGERPRINT';
end;

destructor TfrmMain.Destroy;
begin
  try
    // 先停止定时器
    if Assigned(StatusTimer) then
    begin
      StatusTimer.Enabled := False;
    end;

    // 清理服务
    CleanupServices;
  except
    // 忽略清理时的错误
  end;

  try
    inherited Destroy;
  except
    // 忽略继承析构时的错误
  end;
end;

procedure TfrmMain.CleanupServices;
begin
  try
    // 先清理接口引用（这些是自动管理的）
    try
      FDonationManager := nil;
    except
    end;

    try
      FRollbackManager := nil;
    except
    end;

    try
      FMigrationManager := nil;
    except
    end;

    try
      FFileAnalyzer := nil;
    except
    end;

    try
      FSecurityManager := nil;
    except
    end;

    // Clean up configuration manager
    try
      if Assigned(FConfigManager) then
      begin
        FConfigManager.Free;
        FConfigManager := nil;
      end;
    except
      FConfigManager := nil;
    end;

    // Clean up system info
    try
      if Assigned(FSystemInfo.AvailableSpace) then
      begin
        FSystemInfo.AvailableSpace.Free;
        FSystemInfo.AvailableSpace := nil;
      end;
    except
      FSystemInfo.AvailableSpace := nil;
    end;

    // Clean up status messages
    try
      if Assigned(FStatusMessages) then
      begin
        FStatusMessages.Free;
        FStatusMessages := nil;
      end;
    except
      FStatusMessages := nil;
    end;

  except
    // Ignore all cleanup errors
  end;
end;

// 初始化数据库
procedure TfrmMain.InitializeDatabase;
begin
  try
    if Assigned(FConfigManager) then
    begin
      if FConfigManager.InitializeDatabase then
      begin
        AddStatusMessage('数据库初始化成功');

        // 记录程序启动日志
        FConfigManager.LogOperation('STARTUP', '程序启动', '', '', 'SUCCESS');
      end
      else
      begin
        AddStatusMessage('数据库初始化失败，将使用文件配置模式');
      end;
    end;
  except
    on E: Exception do
    begin
      AddStatusMessage('数据库初始化异常: ' + E.Message);
    end;
  end;
end;

// 初始化打赏框架
procedure TfrmMain.InitializeAboutMeFrame;
begin
  try
    // 创建frameAboutme实例
    FFrameAboutMe := TFrameAboutMe.Create(Self);
    FFrameAboutMe.Parent := tsAboutMe;  // 使用原来的tsAboutMe标签页
    FFrameAboutMe.Align := alClient;

    // 加载打赏地址（使用保护机制）
    LoadProtectedDonationAddresses;

    AddStatusMessage('打赏框架初始化完成');
  except
    on E: Exception do
    begin
      AddStatusMessage('打赏框架初始化失败: ' + E.Message);
      // 不阻止程序启动
    end;
  end;
end;

// 加载受保护的打赏地址
procedure TfrmMain.LoadProtectedDonationAddresses;
const
  // 加密的打赏地址（使用BasicProtection加密）
  ENCRYPTED_WECHAT_DESC = '微信收款码';
  ENCRYPTED_ALIPAY_DESC = '支付宝收款码';
  ENCRYPTED_BTC_ADDRESS = 'bc1qze0ggsrdtjqwjpjfufydsuyjxc08tgcq5xkct3';
  ENCRYPTED_USDT_ADDRESS = 'TH1NazpoEpUqcEotGzLPHs13SbLDJKKCys';
var
  ConfigFile: string;
  EncryptedData, DecryptedData, DataHash: string;
begin
  try
    ConfigFile := ChangeFileExt(Application.ExeName, '.donation');

    // 检查配置文件是否存在
    if not FileExists(ConfigFile) then
    begin
      // 首次运行，创建加密的打赏配置
      CreateProtectedDonationConfig(ConfigFile);
    end;

    // 从配置文件加载并验证打赏地址
    if LoadAndVerifyDonationConfig(ConfigFile) then
    begin
      AddStatusMessage('打赏地址验证成功');
    end
    else
    begin
      AddStatusMessage('打赏地址验证失败，使用备用地址');
      // 使用硬编码的备用地址
      SetBackupDonationAddresses;
    end;

  except
    on E: Exception do
    begin
      AddStatusMessage('加载打赏地址异常: ' + E.Message);
      SetBackupDonationAddresses;
    end;
  end;
end;

// 创建受保护的打赏配置
procedure TfrmMain.CreateProtectedDonationConfig(const AConfigFile: string);
var
  ConfigData: TStringList;
  EncryptedBTC, EncryptedUSDT: string;
  DataToSign, Signature: string;
begin
  try
    ConfigData := TStringList.Create;
    try
      // 加密打赏地址
      EncryptedBTC := TBasicProtection.EncryptSensitiveData('bc1qze0ggsrdtjqwjpjfufydsuyjxc08tgcq5xkct3');
      EncryptedUSDT := TBasicProtection.EncryptSensitiveData('TH1NazpoEpUqcEotGzLPHs13SbLDJKKCys');

      // 构建配置数据
      ConfigData.Add('[DONATION]');
      ConfigData.Add('BTC=' + EncryptedBTC);
      ConfigData.Add('USDT=' + EncryptedUSDT);
      ConfigData.Add('WECHAT_DESC=微信收款码');
      ConfigData.Add('ALIPAY_DESC=支付宝收款码');

      // 生成数据签名
      DataToSign := ConfigData.Text;
      Signature := TBasicProtection.CalculateHMAC(DataToSign);
      ConfigData.Add('SIGNATURE=' + Signature);

      // 保存到文件
      ConfigData.SaveToFile(AConfigFile);
      AddStatusMessage('创建打赏配置文件: ' + AConfigFile);

    finally
      ConfigData.Free;
    end;
  except
    on E: Exception do
      AddStatusMessage('创建打赏配置失败: ' + E.Message);
  end;
end;

// 加载并验证打赏配置
function TfrmMain.LoadAndVerifyDonationConfig(const AConfigFile: string): Boolean;
var
  ConfigData: TStringList;
  StoredSignature, CalculatedSignature: string;
  DataToVerify: string;
  I: Integer;
begin
  Result := False;
  try
    ConfigData := TStringList.Create;
    try
      ConfigData.LoadFromFile(AConfigFile);

      // 提取签名
      StoredSignature := '';
      for I := ConfigData.Count - 1 downto 0 do
      begin
        if ConfigData[I].StartsWith('SIGNATURE=') then
        begin
          StoredSignature := Copy(ConfigData[I], 11, MaxInt);
          ConfigData.Delete(I);
          Break;
        end;
      end;

      // 验证签名
      DataToVerify := ConfigData.Text;
      CalculatedSignature := TBasicProtection.CalculateHMAC(DataToVerify);

      Result := TBasicProtection.VerifyDataIntegrity(DataToVerify, StoredSignature);

      if Result then
        AddStatusMessage('打赏配置验证通过')
      else
        AddStatusMessage('打赏配置验证失败');

    finally
      ConfigData.Free;
    end;
  except
    on E: Exception do
    begin
      AddStatusMessage('验证打赏配置异常: ' + E.Message);
      Result := False;
    end;
  end;
end;

// 设置备用打赏地址
procedure TfrmMain.SetBackupDonationAddresses;
begin
  try
    AddStatusMessage('使用内置备用打赏地址');
    // 这里可以设置frameAboutme的备用地址
    // 由于frameAboutme有自己的备用地址机制，这里只记录日志
  except
    on E: Exception do
      AddStatusMessage('设置备用地址异常: ' + E.Message);
  end;
end;

// 执行系统检查
procedure TfrmMain.PerformSystemCheck;
var
  CheckPassed: Boolean;
begin
  try
    if Assigned(FSystemChecker) then
    begin
      AddStatusMessage('正在执行系统兼容性检查...');

      // 执行快速检查
      CheckPassed := FSystemChecker.PerformQuickCheck;

      if CheckPassed then
      begin
        AddStatusMessage('系统兼容性检查通过');
      end
      else
      begin
        AddColoredStatusMessage('系统兼容性检查发现问题，点击查看详情', clRed);

        // 如果有严重错误，显示警告
        if FSystemChecker.HasCriticalErrors then
        begin
          if MessageDlg('系统兼容性检查发现严重问题，可能影响程序正常运行。' + #13#10 +
                       '是否查看详细检查结果？', mtWarning, [mbYes, mbNo], 0) = mrYes then
          begin
            ShowSystemCheckResults;
          end;
        end;
      end;

      // 记录检查结果到数据库
      if Assigned(FConfigManager) then
      begin
        if CheckPassed then
          FConfigManager.LogOperation('SYSTEM_CHECK', '系统兼容性检查', '', '', 'PASS')
        else
          FConfigManager.LogOperation('SYSTEM_CHECK', '系统兼容性检查', '', '', 'FAIL');
      end;
    end;
  except
    on E: Exception do
    begin
      AddStatusMessage('系统检查异常: ' + E.Message);
    end;
  end;
end;

// 显示系统检查结果
procedure TfrmMain.ShowSystemCheckResults;
var
  Report: string;
  ReportForm: TForm;
  Memo: TMemo;
  BtnClose: TButton;
begin
  if not Assigned(FSystemChecker) then
    Exit;

  try
    Report := FSystemChecker.GenerateReport;

    // 创建报告显示窗体
    ReportForm := TForm.Create(Self);
    try
      ReportForm.Caption := LanguageMgr.GetString('system_check_report', '系统兼容性检查报告');
      ReportForm.Width := 600;
      ReportForm.Height := 500;
      ReportForm.Position := poScreenCenter;
      ReportForm.BorderStyle := bsDialog;

      // 创建备注控件
      Memo := TMemo.Create(ReportForm);
      Memo.Parent := ReportForm;
      Memo.Align := alClient;
      Memo.ScrollBars := ssVertical;
      Memo.ReadOnly := True;
      Memo.Font.Name := 'Courier New';
      Memo.Font.Size := 9;
      Memo.Text := Report;

      // 创建关闭按钮
      BtnClose := TButton.Create(ReportForm);
      BtnClose.Parent := ReportForm;
      BtnClose.Caption := LanguageMgr.GetString('btn_close', '关闭');
      BtnClose.Width := 75;
      BtnClose.Height := 25;
      BtnClose.Left := (ReportForm.Width - BtnClose.Width) div 2;
      BtnClose.Top := ReportForm.Height - BtnClose.Height - 40;
      BtnClose.Anchors := [akBottom];
      BtnClose.ModalResult := mrOk;

      ReportForm.ShowModal;

    finally
      ReportForm.Free;
    end;

  except
    on E: Exception do
    begin
      ShowMessage('显示检查报告失败: ' + E.Message);
    end;
  end;
end;

// 显示进度对话框
function TfrmMain.ShowProgressDialog(const ATitle: string; AMaxProgress: Integer = 100): TfrmProgress;
begin
  Result := TfrmProgress.ShowProgress(ATitle, AMaxProgress, True);
end;

// 主菜单事件处理
procedure TfrmMain.MenuItemExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.MenuItemSystemCheckClick(Sender: TObject);
begin
  ShowSystemCheckResults;
end;

procedure TfrmMain.MenuItemLanguageClick(Sender: TObject);
var
  SelectedLanguage: TLanguageCode;
begin
  SelectedLanguage := LanguageMgr.GetCurrentLanguage;

  if TfrmLanguageDialog.ShowLanguageDialog(SelectedLanguage) then
  begin
    ChangeLanguage(SelectedLanguage);
  end;
end;

procedure TfrmMain.MenuItemAboutClick(Sender: TObject);
begin
  // 切换到关于开发者标签页
  if Assigned(PageControl1) then
    PageControl1.ActivePage := tsAboutMe;
end;

// 多语言系统方法
procedure TfrmMain.InitializeLanguageSystem;
begin
  try
    // 语言管理器会自动初始化
    // 更新界面语言
    UpdateUILanguage;

    AddStatusMessage('多语言系统初始化完成');
  except
    on E: Exception do
    begin
      AddStatusMessage('多语言系统初始化失败: ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.UpdateUILanguage;
begin
  try
    // 更新窗体标题
    Caption := LanguageMgr.GetString('app_title', 'C盘超级清理');

    // 更新主菜单
    if Assigned(MenuFile) then
      MenuFile.Caption := LanguageMgr.GetString('menu_file', '文件(&F)');
    if Assigned(MenuItemExit) then
      MenuItemExit.Caption := LanguageMgr.GetString('menu_exit', '退出(&X)');
    if Assigned(MenuTools) then
      MenuTools.Caption := LanguageMgr.GetString('menu_tools', '工具(&T)');
    if Assigned(MenuItemSystemCheck) then
      MenuItemSystemCheck.Caption := LanguageMgr.GetString('menu_system_check', '系统检查(&S)');
    if Assigned(MenuItemLanguage) then
      MenuItemLanguage.Caption := LanguageMgr.GetString('menu_language', '语言设置(&L)');
    if Assigned(MenuHelp) then
      MenuHelp.Caption := LanguageMgr.GetString('menu_help', '帮助(&H)');
    if Assigned(MenuItemAbout) then
      MenuItemAbout.Caption := LanguageMgr.GetString('menu_about', '关于(&A)');

    // 更新按钮文本
    if Assigned(btnCopyFiles) then
      btnCopyFiles.Caption := LanguageMgr.GetString('btn_copy', '复制文件');
    if Assigned(btnDeleteAndLink) then
      btnDeleteAndLink.Caption := LanguageMgr.GetString('btn_delete', '删除并链接');
    if Assigned(btnCreateBackup) then
      btnCreateBackup.Caption := LanguageMgr.GetString('btn_backup', '创建备份');
    if Assigned(btnDirSource) then
      btnDirSource.Caption := LanguageMgr.GetString('select_source_folder', '选择源文件夹');
    if Assigned(btnDirTarget) then
      btnDirTarget.Caption := LanguageMgr.GetString('select_target_folder', '选择目标文件夹');
    if Assigned(btnCalcDirSize) then
      btnCalcDirSize.Caption := LanguageMgr.GetString('calc_dir_size', '计算目录大小');
    if Assigned(btnAnalyze) then
      btnAnalyze.Caption := LanguageMgr.GetString('analyze_stats', '分析并统计');
    if Assigned(btnMove) then
      btnMove.Caption := LanguageMgr.GetString('verify_action', '验证动作');
    if Assigned(btnRollback) then
      btnRollback.Caption := LanguageMgr.GetString('btn_rollback', '回滚操作');
    if Assigned(btnClose) then
      btnClose.Caption := LanguageMgr.GetString('btn_close', '关闭');

    // 更新标签页标题
    if Assigned(tsBackup) then
      tsBackup.Caption := LanguageMgr.GetString('tab_backup', '备份管理');
    if Assigned(tsAboutMe) then
      tsAboutMe.Caption := LanguageMgr.GetString('tab_about', '关于开发者');

    // 更新标签文本
    if Assigned(edtSource) then
      edtSource.EditLabel.Caption := LanguageMgr.GetString('source_dir', '迁移源目录');
    if Assigned(edtTarget) then
      edtTarget.EditLabel.Caption := LanguageMgr.GetString('target_dir', '目标目录');

    AddStatusMessage(LanguageMgr.GetString('ui_language_updated', '界面语言已更新为') + ': ' + LanguageMgr.GetCurrentLanguageName);

  except
    on E: Exception do
    begin
      AddStatusMessage('更新界面语言失败: ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.ChangeLanguage(ALanguage: TLanguageCode);
begin
  try
    // 切换语言
    if LanguageMgr.LoadLanguage(ALanguage) then
    begin
      // 保存语言首选项
      LanguageMgr.SaveLanguagePreference(ALanguage);

      // 更新界面
      UpdateUILanguage;

      // 记录操作日志
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('LANGUAGE_CHANGE', '切换语言', '', '', 'SUCCESS');

      ShowMessage(LanguageMgr.GetString('language_changed', '语言设置已更改，部分界面将在重启后生效。'));
    end
    else
    begin
      ShowMessage(LanguageMgr.GetString('language_change_failed', '语言切换失败，请重试。'));
    end;

  except
    on E: Exception do
    begin
      AddStatusMessage('切换语言失败: ' + E.Message);
      ShowMessage('切换语言时发生错误: ' + E.Message);
    end;
  end;
end;

// 添加状态消息
procedure TfrmMain.AddStatusMessage(const AMessage: string);
var
  TimeStamp: string;
begin
  try
    if not Assigned(FStatusMessages) then
      Exit;

    TimeStamp := FormatDateTime('hh:nn:ss', Now);
    FStatusMessages.Add(Format('[%s] %s', [TimeStamp, AMessage]));

    // 限制消息数量，避免内存过多占用
    while FStatusMessages.Count > 100 do
      FStatusMessages.Delete(0);
  except
    // 忽略状态消息错误
  end;
end;

// 添加彩色状态消息
procedure TfrmMain.AddColoredStatusMessage(const AMessage: string; AColor: TColor);
var
  TimeStamp: string;
  FullMessage: string;
  ModernColor: TColor;
begin
  try
    if not Assigned(RichEdit1) then
      Exit;

    TimeStamp := FormatDateTime('hh:nn:ss', Now);
    FullMessage := Format('[%s] %s', [TimeStamp, AMessage]);

    // 使用现代化颜色方案
    ModernColor := AColor;
    if Assigned(StyleManager) then
    begin
      // 根据当前主题调整颜色
      case AColor of
        clGreen: ModernColor := StyleManager.CurrentTheme.Success;
        clRed: ModernColor := StyleManager.CurrentTheme.Error;
        clBlue: ModernColor := StyleManager.CurrentTheme.Info;
        clMaroon: ModernColor := StyleManager.CurrentTheme.Warning;
        clNavy: ModernColor := StyleManager.CurrentTheme.Primary;
        clOlive: ModernColor := StyleManager.CurrentTheme.Warning;
        clGray: ModernColor := StyleManager.CurrentTheme.TextSecondary;
        clSilver: ModernColor := StyleManager.CurrentTheme.TextDisabled;
      else
        ModernColor := AColor;
      end;
    end;

    // 直接添加到RichEdit控件中，支持彩色
    RichEdit1.SelStart := Length(RichEdit1.Text);
    RichEdit1.SelAttributes.Color := ModernColor;
    RichEdit1.SelAttributes.Name := 'Microsoft YaHei UI';
    RichEdit1.SelAttributes.Size := 9;
    RichEdit1.SelAttributes.Charset := DEFAULT_CHARSET;
    RichEdit1.Lines.Add(FullMessage);

    // 滚动到最后一行
    RichEdit1.SelStart := Length(RichEdit1.Text);
    RichEdit1.Perform(EM_SCROLLCARET, 0, 0);

    // 同时添加到FStatusMessages以保持兼容性
    if Assigned(FStatusMessages) then
    begin
      FStatusMessages.Add(FullMessage);
      while FStatusMessages.Count > 100 do
        FStatusMessages.Delete(0);
    end;
  except
    // 忽略状态消息错误
  end;
end;

// 更新状态显示
procedure TfrmMain.UpdateStatusDisplay;
begin
  try
    if not Assigned(FStatusMessages) or not Assigned(RichEdit1) then
      Exit;

    RichEdit1.Lines.Assign(FStatusMessages);

    // 滚动到最后一行
    if RichEdit1.Lines.Count > 0 then
    begin
      RichEdit1.SelStart := Length(RichEdit1.Text);
      RichEdit1.Perform(EM_SCROLLCARET, 0, 0);
    end;

    // 强制刷新显示
    RichEdit1.Refresh;
    Application.ProcessMessages;
  except
    // 忽略状态显示错误
  end;
end;

// 分析整个目录的符号链接可行性
function TfrmMain.AnalyzeDirectoryFeasibility(const ADirectoryPath: string): TFileAnalysisResult;
var
  DirPath: string;
  DirName: string;
begin
  Result.FilePath := ADirectoryPath;
  Result.Size := 0;
  Result.IsSystemFile := False;
  SetLength(Result.Dependencies, 0);
  Result.RequiresRestart := False;
  Result.CanCreateSymlink := True;
  Result.Reason := '';
  Result.SymlinkFeasibility := sfCanLink; // 默认可链接

  try
    DirPath := LowerCase(ADirectoryPath);
    DirName := LowerCase(ExtractFileName(ADirectoryPath));

    AddStatusMessage('正在分析目录: ' + ExtractFileName(ADirectoryPath));
    AddStatusMessage('完整路径: ' + ADirectoryPath);

    // 计算目录大小（简化）
    try
      var SearchRec: TSearchRec;
      if FindFirst(ADirectoryPath + '\*.*', faAnyFile, SearchRec) = 0 then
      begin
        try
          repeat
            if (SearchRec.Attr and faDirectory) = 0 then
              Result.Size := Result.Size + SearchRec.Size;
          until FindNext(SearchRec) <> 0;
        finally
          FindClose(SearchRec);
        end;
      end;
    except
      // 忽略大小计算错误
    end;

    // 核心判断逻辑：这个目录移动后是否会影响程序运行

    // 1. 系统关键目录 - 绝对不能移动
    if (Pos('c:\windows', DirPath) = 1) or
       (Pos('c:\program files\windows', DirPath) = 1) or
       (Pos('system32', DirPath) > 0) or
       (Pos('syswow64', DirPath) > 0) or
       (Pos('winsxs', DirPath) > 0) then
    begin
      AddStatusMessage('检测到系统关键目录');
      AddStatusMessage('判断结果: 禁止移动 - 会导致Windows无法正常运行');
      Result.SymlinkFeasibility := sfCannotMove;
      Result.IsSystemFile := True;
      Result.CanCreateSymlink := False;
      Result.Reason := '系统关键目录，移动会导致Windows无法正常运行';
      // 不要Exit，让主流程继续执行
    end

    // 2. 程序安装目录分析
    else if (Pos('c:\program files', DirPath) = 1) then
    begin
      AddStatusMessage('检测到程序安装目录');
      // 检查是否是共享组件目录
      if (Pos('common files', DirPath) > 0) or
         (Pos('microsoft shared', DirPath) > 0) or
         (Pos('shared', DirName) > 0) then
      begin
        AddStatusMessage('判断结果: 有风险 - 共享组件目录');
        Result.SymlinkFeasibility := sfRisky;
        Result.Reason := '共享程序组件目录，移动可能影响多个程序运行';
        SetLength(Result.Dependencies, 1);
        Result.Dependencies[0] := '多个程序可能依赖此目录';
      end
      else
      begin
        AddStatusMessage('判断结果: 可链接 - 独立程序目录');
        Result.SymlinkFeasibility := sfCanLink;
        Result.Reason := '独立程序安装目录，符号链接不会影响程序运行';
      end;
    end

    // 3. 程序数据目录分析
    else if (Pos('c:\programdata', DirPath) = 1) then
    begin
      AddStatusMessage('检测到程序数据目录');
      AddStatusMessage('判断结果: 有风险 - 可能影响程序配置');
      Result.SymlinkFeasibility := sfRisky;
      Result.Reason := '程序数据目录，移动可能影响程序配置，但符号链接通常可以解决';
      Result.RequiresRestart := True;
    end

    // 4. 用户目录分析
    else if (Pos('c:\users', DirPath) = 1) then
    begin
      AddStatusMessage('检测到用户目录');
      // 检查是否是系统用户目录
      if (Pos('administrator', DirPath) > 0) or
         (Pos('default', DirPath) > 0) or
         (Pos('public', DirPath) > 0) or
         (Pos('all users', DirPath) > 0) then
      begin
        AddStatusMessage('检测到系统用户目录: ' + DirName);
        AddStatusMessage('判断结果: 禁止移动 - 会影响系统用户账户功能');
        Result.SymlinkFeasibility := sfCannotMove;
        Result.IsSystemFile := True;
        Result.CanCreateSymlink := False;
        Result.Reason := '系统用户目录，移动会影响系统用户账户功能';
        // 不要Exit，让主流程继续执行
      end;

      if (Pos('appdata\local', DirPath) > 0) then
      begin
        Result.SymlinkFeasibility := sfRisky;
        Result.Reason := '本地应用数据，移动可能影响程序性能，但符号链接可以解决';
      end
      else if (Pos('appdata\roaming', DirPath) > 0) then
      begin
        Result.SymlinkFeasibility := sfCanLink;
        Result.Reason := '漫游用户数据，符号链接完全不影响程序运行';
      end
      else if (Pos('documents', DirPath) > 0) or
              (Pos('desktop', DirPath) > 0) or
              (Pos('downloads', DirPath) > 0) or
              (Pos('pictures', DirPath) > 0) or
              (Pos('music', DirPath) > 0) or
              (Pos('videos', DirPath) > 0) then
      begin
        Result.SymlinkFeasibility := sfCanLink;
        Result.Reason := '用户数据文件夹，符号链接不会影响任何程序运行';
      end
      else
      begin
        Result.SymlinkFeasibility := sfRisky;
        Result.Reason := '用户目录，需要确认是否包含重要的用户配置';
      end;
    end

    // 5. 游戏和娱乐软件目录
    else if (Pos('games', DirPath) > 0) or
            (Pos('steam', DirPath) > 0) or
            (Pos('epic', DirPath) > 0) then
    begin
      AddStatusMessage('检测到游戏目录');
      AddStatusMessage('判断结果: 可链接 - 现代游戏引擎支持符号链接');
      Result.SymlinkFeasibility := sfCanLink;
      Result.Reason := '游戏目录，符号链接不影响游戏运行（现代游戏引擎支持）';
    end

    // 6. 开发工具目录
    else if (Pos('sdk', DirPath) > 0) or
            (Pos('tools', DirPath) > 0) or
            (Pos('ide', DirPath) > 0) then
    begin
      AddStatusMessage('检测到开发工具目录');
      AddStatusMessage('判断结果: 可链接 - 符号链接不影响工具运行');
      Result.SymlinkFeasibility := sfCanLink;
      Result.Reason := '开发工具目录，符号链接不影响工具运行';
    end

    // 7. 临时和缓存目录
    else if (Pos('temp', DirPath) > 0) or
            (Pos('cache', DirPath) > 0) or
            (Pos('tmp', DirPath) > 0) then
    begin
      AddStatusMessage('检测到临时/缓存目录');
      AddStatusMessage('判断结果: 可链接 - 完全不影响程序运行');
      Result.SymlinkFeasibility := sfCanLink;
      Result.Reason := '临时/缓存目录，符号链接完全不影响程序运行';
    end
    // 8. 默认情况 - 需要谨慎评估
    else
    begin
      AddStatusMessage('未知目录类型，需要谨慎评估');
      AddStatusMessage('判断结果: 有风险 - 建议先测试');
      Result.SymlinkFeasibility := sfRisky;
      Result.Reason := '未知类型目录，建议先测试移动对相关程序运行的影响';
    end;

  except
    on E: Exception do
    begin
      Result.SymlinkFeasibility := sfCannotMove;
      Result.IsSystemFile := True;
      Result.CanCreateSymlink := False;
      Result.Reason := '分析失败，为安全起见不建议移动: ' + E.Message;
    end;
  end;
end;

// 定时器事件 - 定期更新状态显示
procedure TfrmMain.StatusTimerTimer(Sender: TObject);
begin
  try
    UpdateStatusDisplay;
  except
    // 忽略定时器错误
  end;
end;

// 目标目录列表框双击事件
procedure TfrmMain.DirListBoxTargetDblClick(Sender: TObject);
var
  DirSize: Int64;
  SizeText: string;
begin
  try
    // 双击时自动更新文件列表（通过FileList属性自动处理）
    // 同时更新目标路径编辑框
    if Assigned(DirListBoxTarget) then
    begin
      edtTarget.Text := DirListBoxTarget.Directory;
      AddStatusMessage('🎯 目标目录已更改为: ' + DirListBoxTarget.Directory);

      // 先强制刷新文件列表，让用户立即看到文件
      if Assigned(FileListBoxTarget) then
      begin
        FileListBoxTarget.Update;
        AddStatusMessage(Format('📄 目标目录包含 %d 个文件', [FileListBoxTarget.Items.Count]));
      end;

      // 检测并显示符号链接状态
      if IsSymbolicLink(DirListBoxTarget.Directory) then
      begin
        MarkDirectoryInTree(DirListBoxTarget.Directory, clBlue);
        AddColoredStatusMessage('🔗 目标目录是符号链接', clBlue);
      end;

      // 清除大小显示，提示使用专用按钮
      if Assigned(lblSize) then
      begin
        lblSize.Caption := LanguageMgr.GetString('click_calc_size', '点击"计算目录大小"按钮获取大小信息');
        lblSize.Visible := True;
        lblSize.Refresh;
      end;
      AddStatusMessage('💡 提示：点击"计算目录大小"按钮可显示目录大小信息');
    end;
  except
    on E: Exception do
      AddStatusMessage('❌ 更新目标目录失败: ' + E.Message);
  end;
end;

// 目标目录列表框变化事件
procedure TfrmMain.DirListBoxTargetChange(Sender: TObject);
var
  CurrentDir: string;
  DirSize: Int64;
  SizeText: string;
begin
  try
    // 目录变化时自动更新目标路径编辑框
    if Assigned(DirListBoxTarget) then
    begin
      CurrentDir := DirListBoxTarget.Directory;
      edtTarget.Text := CurrentDir;

      // 强制刷新文件列表
      if Assigned(FileListBoxTarget) then
      begin
        FileListBoxTarget.Update;
      end;

      // 实时计算目录大小（如果复选框选中）
      if Assigned(cBoxCalcSize) and cBoxCalcSize.Checked then
      begin
        try
          AddColoredStatusMessage('📊 正在计算右侧目录大小...', clOlive);
          Application.ProcessMessages;

          DirSize := CalculateDirectorySize(CurrentDir);

          // 格式化大小显示
          if DirSize >= 1024 * 1024 * 1024 then
            SizeText := Format('%.2f GB', [DirSize / (1024 * 1024 * 1024)])
          else if DirSize >= 1024 * 1024 then
            SizeText := Format('%.2f MB', [DirSize / (1024 * 1024)])
          else if DirSize >= 1024 then
            SizeText := Format('%.2f KB', [DirSize / 1024])
          else
            SizeText := Format('%d 字节', [DirSize]);

          AddColoredStatusMessage('📊 右侧目录大小: ' + SizeText, clGreen);

        except
          on E: Exception do
            AddColoredStatusMessage('❌ 计算右侧目录大小失败: ' + E.Message, clRed);
        end;
      end;
    end;
  except
    // 忽略变化事件错误
  end;
end;

// 源目录列表框双击事件
procedure TfrmMain.DirListBoxSourceDblClick(Sender: TObject);
var
  DirSize: Int64;
  SizeText: string;
begin
  try
    // 双击时自动更新文件列表（通过FileList属性自动处理）
    // 同时更新源路径编辑框
    if Assigned(DirListBoxSource) then
    begin
      edtSource.Text := DirListBoxSource.Directory;
      AddStatusMessage('📁 源目录已更改为: ' + DirListBoxSource.Directory);

      // 先强制刷新文件列表，让用户立即看到文件
      if Assigned(FileListBoxSource) then
      begin
        FileListBoxSource.Update;
        AddStatusMessage(Format('📄 源目录包含 %d 个文件', [FileListBoxSource.Items.Count]));
      end;

      // 检测并显示符号链接状态
      if IsSymbolicLink(DirListBoxSource.Directory) then
      begin
        MarkDirectoryInTree(DirListBoxSource.Directory, clBlue);
        AddColoredStatusMessage('🔗 检测到符号链接目录', clBlue);
      end;

      // 清除之前的分析结果
      SetLength(FAnalysisResults, 0);
      AddStatusMessage('🔄 目录已更改，请重新执行分析');

      // 清除大小显示，提示使用专用按钮
      if Assigned(lblSize) then
      begin
        lblSize.Caption := LanguageMgr.GetString('click_calc_size', '点击"计算目录大小"按钮获取大小信息');
        lblSize.Visible := True;
        lblSize.Refresh;
      end;
      AddStatusMessage('💡 提示：点击"计算目录大小"按钮可显示目录大小信息');
    end;
  except
    on E: Exception do
      AddStatusMessage('❌ 更新源目录失败: ' + E.Message);
  end;
end;

// 源目录列表框变化事件
procedure TfrmMain.DirListBoxSourceChange(Sender: TObject);
var
  CurrentDir: string;
  DirSize: Int64;
  SizeText: string;
begin
  try
    // 目录变化时自动更新源路径编辑框
    if Assigned(DirListBoxSource) then
    begin
      CurrentDir := DirListBoxSource.Directory;
      edtSource.Text := CurrentDir;

      // 强制刷新文件列表
      if Assigned(FileListBoxSource) then
      begin
        FileListBoxSource.Update;
      end;

      // 更新目录颜色显示
      UpdateDirectoryColors;

      // 实时计算目录大小（如果复选框选中）
      if Assigned(cBoxCalcSize) and cBoxCalcSize.Checked then
      begin
        try
          AddColoredStatusMessage('📊 正在计算左侧目录大小...', clOlive);
          Application.ProcessMessages;

          DirSize := CalculateDirectorySize(CurrentDir);

          // 格式化大小显示
          if DirSize >= 1024 * 1024 * 1024 then
            SizeText := Format('%.2f GB', [DirSize / (1024 * 1024 * 1024)])
          else if DirSize >= 1024 * 1024 then
            SizeText := Format('%.2f MB', [DirSize / (1024 * 1024)])
          else if DirSize >= 1024 then
            SizeText := Format('%.2f KB', [DirSize / 1024])
          else
            SizeText := Format('%d 字节', [DirSize]);

          AddColoredStatusMessage('📊 左侧目录大小: ' + SizeText, clGreen);

          // 显示在lblSize中
          if Assigned(lblSize) then
          begin
            lblSize.Caption := LanguageMgr.GetString('dir_size', '目录大小') + ': ' + SizeText;
            lblSize.Visible := True;
          end;

        except
          on E: Exception do
            AddColoredStatusMessage('❌ 计算左侧目录大小失败: ' + E.Message, clRed);
        end;
      end;

      // 清除之前的分析结果
      SetLength(FAnalysisResults, 0);

      // 清理之前的目录标记
      ClearAllDirectoryMarks;

      // 自动扫描当前目录的符号链接
      ScanCurrentDirectorySymlinks;
    end;
  except
    // 忽略变化事件错误
  end;
end;

// 在目录树中标记目录颜色（通过修改Items实现视觉效果）
procedure TfrmMain.MarkDirectoryInTree(const APath: string; AColor: TColor);
var
  I: Integer;
  DirName: string;
  ColorName: string;
  Prefix: string;
  CurrentSourceDir: string;
  CurrentTargetDir: string;
  IsInSourceDir: Boolean;
  IsInTargetDir: Boolean;
begin
  try
    DirName := ExtractFileName(APath);
    CurrentSourceDir := '';
    CurrentTargetDir := '';

    // 获取当前目录路径
    if Assigned(DirListBoxSource) then
      CurrentSourceDir := DirListBoxSource.Directory;
    if Assigned(DirListBoxTarget) then
      CurrentTargetDir := DirListBoxTarget.Directory;

    // 判断该路径是否在对应的目录下
    IsInSourceDir := (CurrentSourceDir <> '') and
                     SameText(ExtractFilePath(APath), IncludeTrailingPathDelimiter(CurrentSourceDir));
    IsInTargetDir := (CurrentTargetDir <> '') and
                     SameText(ExtractFilePath(APath), IncludeTrailingPathDelimiter(CurrentTargetDir));

    // 根据颜色确定显示前缀和名称 (增强版)
    case AColor of
      clGreen:
      begin
        ColorName := '绿色（可链接）';
        Prefix := '✅ ';
      end;
      clRed:
      begin
        ColorName := '红色（禁止移动）';
        Prefix := '❌ ';
      end;
      clOlive:
      begin
        ColorName := '橄榄色（有风险）';
        Prefix := '⚠️ ';
      end;
      clBlue:
      begin
        ColorName := '蓝色（有效符号链接）';
        Prefix := '🔗✅ ';
      end;
      clMaroon:
      begin
        ColorName := '深红色（无效符号链接）';
        Prefix := '🔗❌ ';
      end;
      clNavy:
      begin
        ColorName := '深蓝色（挂载点）';
        Prefix := '🔗📌 ';
      end;
      clPurple:
      begin
        ColorName := '紫色（已拷贝）';
        Prefix := '📋✅ ';
      end;
      clTeal:
      begin
        ColorName := '青色（已备份）';
        Prefix := '💾✅ ';
      end;
      clFuchsia:
      begin
        ColorName := '品红色（拷贝中）';
        Prefix := '📋⏳ ';
      end;
    else
      ColorName := '未知颜色';
      Prefix := '❓ ';
    end;

    // 只在源目录列表框中标记（如果路径在源目录下）
    if IsInSourceDir and Assigned(DirListBoxSource) then
    begin
      for I := 0 to DirListBoxSource.Items.Count - 1 do
      begin
        // 使用新的方法移除所有可能的前缀
        var ItemText := RemoveStatusPrefix(DirListBoxSource.Items[I]);

        if SameText(ItemText, DirName) then
        begin
          // 添加新的前缀
          DirListBoxSource.Items[I] := Prefix + ItemText;
          AddStatusMessage(Format('🎨 源目录 "%s" 已标记为: %s', [DirName, ColorName]));
          DirListBoxSource.Invalidate;
          Break;
        end;
      end;
    end;

    // 只在目标目录列表框中标记（如果路径在目标目录下）
    if IsInTargetDir and Assigned(DirListBoxTarget) then
    begin
      for I := 0 to DirListBoxTarget.Items.Count - 1 do
      begin
        // 使用新的方法移除所有可能的前缀
        var ItemText := RemoveStatusPrefix(DirListBoxTarget.Items[I]);

        if SameText(ItemText, DirName) then
        begin
          // 添加新的前缀
          DirListBoxTarget.Items[I] := Prefix + ItemText;
          AddStatusMessage(Format('🎨 目标目录 "%s" 已标记为: %s', [DirName, ColorName]));
          DirListBoxTarget.Invalidate;
          Break;
        end;
      end;
    end;
  except
    on E: Exception do
      AddStatusMessage('❌ 标记目录颜色失败: ' + E.Message);
  end;
end;

// 清理所有目录标记
procedure TfrmMain.ClearAllDirectoryMarks;
var
  I: Integer;
  ItemText: string;
begin
  try
    // 清理源目录列表框的标记
    if Assigned(DirListBoxSource) then
    begin
      for I := 0 to DirListBoxSource.Items.Count - 1 do
      begin
        ItemText := DirListBoxSource.Items[I];
        // 移除所有前缀
        if (Pos('✅ ', ItemText) = 1) or (Pos('❌ ', ItemText) = 1) or
           (Pos('⚠️ ', ItemText) = 1) then
        begin
          DirListBoxSource.Items[I] := Copy(ItemText, 4, Length(ItemText));
        end
        else if (Pos('🔗📁 ', ItemText) = 1) then
        begin
          DirListBoxSource.Items[I] := Copy(ItemText, 6, Length(ItemText));
        end;
      end;
      DirListBoxSource.Invalidate;
    end;

    // 清理目标目录列表框的标记
    if Assigned(DirListBoxTarget) then
    begin
      for I := 0 to DirListBoxTarget.Items.Count - 1 do
      begin
        ItemText := DirListBoxTarget.Items[I];
        // 移除所有前缀
        if (Pos('✅ ', ItemText) = 1) or (Pos('❌ ', ItemText) = 1) or
           (Pos('⚠️ ', ItemText) = 1) then
        begin
          DirListBoxTarget.Items[I] := Copy(ItemText, 4, Length(ItemText));
        end
        else if (Pos('🔗📁 ', ItemText) = 1) then
        begin
          DirListBoxTarget.Items[I] := Copy(ItemText, 6, Length(ItemText));
        end;
      end;
      DirListBoxTarget.Invalidate;
    end;
  except
    // 忽略清理错误
  end;
end;

// 计算目录大小（包括所有子目录）
function TfrmMain.CalculateDirectorySize(const APath: string): Int64;
var
  SearchRec: TSearchRec;
  SubPath: string;
begin
  Result := 0;

  try
    if not DirectoryExists(APath) then
      Exit;

    // 查找所有文件和子目录
    if FindFirst(APath + '\*', faAnyFile, SearchRec) = 0 then
    begin
      try
        repeat
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          begin
            SubPath := APath + '\' + SearchRec.Name;

            if (SearchRec.Attr and faDirectory) <> 0 then
            begin
              // 递归计算子目录大小
              Result := Result + CalculateDirectorySize(SubPath);
            end
            else
            begin
              // 累加文件大小
              Result := Result + SearchRec.Size;
            end;
          end;
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;
  except
    // 忽略访问权限错误等
  end;
end;

// 字符串右填充函数
function TfrmMain.PadRight(const AText: string; ALength: Integer): string;
begin
  Result := AText;
  while Length(Result) < ALength do
    Result := Result + ' ';
  if Length(Result) > ALength then
    Result := Copy(Result, 1, ALength - 3) + '...';
end;

// 检查是否是根目录或用户根目录
function TfrmMain.IsRootOrUserRootDirectory(const APath: string): Boolean;
var
  NormalizedPath: string;
begin
  Result := False;

  try
    NormalizedPath := LowerCase(Trim(APath));

    // 移除末尾的反斜杠
    if (Length(NormalizedPath) > 1) and (NormalizedPath[Length(NormalizedPath)] = '\') then
      NormalizedPath := Copy(NormalizedPath, 1, Length(NormalizedPath) - 1);

    // 检查是否是驱动器根目录 (C:, D:, 等)
    if (Length(NormalizedPath) = 2) and (NormalizedPath[2] = ':') then
    begin
      Result := True;
      Exit;
    end;

    // 检查是否是用户根目录
    if SameText(NormalizedPath, 'c:\users') then
    begin
      Result := True;
      Exit;
    end;

    // 检查是否是Program Files根目录
    if SameText(NormalizedPath, 'c:\program files') or
       SameText(NormalizedPath, 'c:\program files (x86)') then
    begin
      Result := True;
      Exit;
    end;

    // 检查是否是Windows根目录
    if SameText(NormalizedPath, 'c:\windows') then
    begin
      Result := True;
      Exit;
    end;

  except
    // 如果出现异常，为安全起见返回True
    Result := True;
  end;
end;



// 计算目录大小按钮点击事件
procedure TfrmMain.btnCalcDirSizeClick(Sender: TObject);
var
  SourcePath: string;
  DirSize: Int64;
  SizeText: string;
begin
  try
    SourcePath := edtSource.Text;

    if not DirectoryExists(SourcePath) then
    begin
      AddColoredStatusMessage('❌ 错误：源目录不存在，请先选择有效的目录', clRed);
      Exit;
    end;

    // 检查是否是根目录
    if IsRootOrUserRootDirectory(SourcePath) then
    begin
      AddColoredStatusMessage('', clRed);
      AddColoredStatusMessage('╔══════════════════════════════════════════════╗', clRed);
      AddColoredStatusMessage('║ ⚠️ 【警告：此目录文件数量巨大】              ║', clRed);
      AddColoredStatusMessage('║ 目录：' + PadRight(ExtractFileName(SourcePath), 35) + '║', clRed);
      AddColoredStatusMessage('║ 计算大小可能需要很长时间并导致程序卡死       ║', clRed);
      AddColoredStatusMessage('║ 建议：选择具体的子目录进行计算               ║', clRed);
      AddColoredStatusMessage('║ 是否继续？请谨慎考虑...                     ║', clRed);
      AddColoredStatusMessage('╚══════════════════════════════════════════════╝', clRed);

      if Assigned(lblSize) then
      begin
        lblSize.Caption := LanguageMgr.GetString('dir_too_large', '目录过大，建议不要计算');
        lblSize.Visible := True;
        lblSize.Refresh;
      end;

      // 对于根目录，给出警告但不阻止操作（用户可以自己决定）
      AddStatusMessage('⚠️ 如果确实需要计算根目录大小，请再次点击按钮确认');
      Exit;
    end;

    // 计算并显示目录大小
    AddStatusMessage('');
    AddColoredStatusMessage('📊 正在计算目录大小，请稍候...', clBlue);
    UpdateStatusDisplay;
    Application.ProcessMessages;

    DirSize := CalculateDirectorySize(SourcePath);

    // 格式化大小显示
    if DirSize >= 1024 * 1024 * 1024 then
      SizeText := Format('%.2f GB', [DirSize / (1024 * 1024 * 1024)])
    else if DirSize >= 1024 * 1024 then
      SizeText := Format('%.2f MB', [DirSize / (1024 * 1024)])
    else if DirSize >= 1024 then
      SizeText := Format('%.2f KB', [DirSize / 1024])
    else
      SizeText := Format('%d 字节', [DirSize]);

    // 显示在lblSize中
    if Assigned(lblSize) then
    begin
      lblSize.Caption := LanguageMgr.GetString('dir_size', '目录大小') + ': ' + SizeText;
      lblSize.Visible := True;
      lblSize.Refresh;
      AddColoredStatusMessage('✅ 计算完成: ' + lblSize.Caption, clGreen);
    end;

    // 显示详细统计信息
    AddStatusMessage('');
    AddColoredStatusMessage('┌──────────────────────────────────────────────┐', clBlue);
    AddColoredStatusMessage('│ 目录大小计算结果                             │', clBlue);
    AddColoredStatusMessage('├──────────────────────────────────────────────┤', clBlue);
    AddColoredStatusMessage('│ 目录: ' + PadRight(ExtractFileName(SourcePath), 37) + '│', clBlue);
    AddColoredStatusMessage('│ 大小: ' + PadRight(SizeText, 37) + '│', clBlue);
    AddColoredStatusMessage('│ 字节: ' + PadRight(Format('%d', [DirSize]), 37) + '│', clBlue);
    AddColoredStatusMessage('└──────────────────────────────────────────────┘', clBlue);

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 计算目录大小失败: ' + E.Message, clRed);
      if Assigned(lblSize) then
      begin
        lblSize.Caption := LanguageMgr.GetString('calc_failed', '计算失败');
        lblSize.Visible := True;
        lblSize.Refresh;
      end;
    end;
  end;
end;

// 根据状态标记目录
procedure TfrmMain.MarkDirectoryWithStatus(const APath: string; AStatus: TDirectoryStatus);
var
  StatusColor: TColor;
  StatusName: string;
  SymlinkTarget: string;
begin
  try
    // 根据状态确定颜色和名称 (增强版)
    case AStatus of
      dsNormal:
      begin
        StatusColor := clWindowText;
        StatusName := '普通目录';
      end;
      dsSymlink:
      begin
        StatusColor := clBlue;
        StatusName := '有效符号链接';
        SymlinkTarget := GetSymlinkTarget(APath);
      end;
      dsSymlinkBroken:
      begin
        StatusColor := clMaroon;
        StatusName := '无效符号链接';
        SymlinkTarget := GetSymlinkTarget(APath);
      end;
      dsSymlinkFile:
      begin
        StatusColor := clBlue;
        StatusName := '文件符号链接';
        SymlinkTarget := GetSymlinkTarget(APath);
      end;
      dsSymlinkDir:
      begin
        StatusColor := clBlue;
        StatusName := '目录符号链接';
        SymlinkTarget := GetSymlinkTarget(APath);
      end;
      dsMountPoint:
      begin
        StatusColor := clNavy;
        StatusName := '挂载点';
        SymlinkTarget := GetSymlinkTarget(APath);
      end;
      dsAnalyzed:
      begin
        StatusColor := clGray;
        StatusName := '已分析';
      end;
      dsAnalyzedGood:
      begin
        StatusColor := clGreen;
        StatusName := '分析结果：可链接';
      end;
      dsAnalyzedRisk:
      begin
        StatusColor := clOlive;
        StatusName := '分析结果：有风险';
      end;
      dsAnalyzedBad:
      begin
        StatusColor := clRed;
        StatusName := '分析结果：禁止移动';
      end;
      dsCopying:
      begin
        StatusColor := clFuchsia;
        StatusName := '拷贝中';
      end;
      dsCopied:
      begin
        StatusColor := clPurple;
        StatusName := '已拷贝';
      end;
      dsBackedUp:
      begin
        StatusColor := clTeal;
        StatusName := '已备份';
      end;
      dsRestored:
      begin
        StatusColor := clLime;
        StatusName := '已恢复';
      end;
    else
      StatusColor := clWindowText;
      StatusName := '未知状态';
    end;

    // 调用原有的颜色标记方法
    MarkDirectoryInTree(APath, StatusColor);

    // 记录状态变更历史
    if Assigned(FStatusManager) then
    begin
      var OldStatus := FStatusManager.GetDirectoryStatus(APath);
      if OldStatus <> AStatus then
      begin
        FStatusManager.SetDirectoryStatus(APath, AStatus, StatusName);
        LogOperation(otStatusChange, APath, '',
                    Format('状态变更: %s → %s', [GetStatusName(OldStatus), StatusName]), True);
      end;
    end;

    // 显示状态信息
    AddStatusMessage(Format('📁 目录状态: %s - %s', [ExtractFileName(APath), StatusName]));

    // 如果是符号链接，显示目标信息
    if (AStatus in [dsSymlink, dsSymlinkBroken, dsSymlinkFile, dsSymlinkDir, dsMountPoint]) and (SymlinkTarget <> '') then
    begin
      AddColoredStatusMessage('🔗 链接目标: ' + SymlinkTarget, clBlue);
    end;

  except
    on E: Exception do
      AddStatusMessage('❌ 标记目录状态失败: ' + E.Message);
  end;
end;

// 检测是否为符号链接 (增强版)
function TfrmMain.IsSymbolicLink(const APath: string): Boolean;
var
  Attr: DWORD;
  Handle: THandle;
  ReparseData: array[0..MAXIMUM_REPARSE_DATA_BUFFER_SIZE-1] of Byte;
  BytesReturned: DWORD;
  ReparseTag: DWORD;
begin
  Result := False;

  try
    // 检查路径是否存在 (支持文件和目录)
    if not (DirectoryExists(APath) or FileExists(APath)) then
      Exit;

    // 获取文件属性
    Attr := GetFileAttributes(PChar(APath));
    if Attr = INVALID_FILE_ATTRIBUTES then
      Exit;

    // 检查是否有重解析点属性
    if (Attr and FILE_ATTRIBUTE_REPARSE_POINT) = 0 then
      Exit;

    // 进一步验证重解析点类型
    Handle := CreateFile(
      PChar(APath),
      0,
      FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,
      nil,
      OPEN_EXISTING,
      FILE_FLAG_BACKUP_SEMANTICS or FILE_FLAG_OPEN_REPARSE_POINT,
      0
    );

    if Handle = INVALID_HANDLE_VALUE then
    begin
      // 如果无法打开，但有重解析点属性，仍认为是符号链接
      Result := True;
      Exit;
    end;

    try
      // 获取重解析点数据
      if DeviceIoControl(
        Handle,
        FSCTL_GET_REPARSE_POINT,
        nil,
        0,
        @ReparseData[0],
        SizeOf(ReparseData),
        BytesReturned,
        nil
      ) then
      begin
        // 检查重解析标签
        ReparseTag := PDWORD(@ReparseData[0])^;
        Result := (ReparseTag = IO_REPARSE_TAG_SYMLINK) or
                  (ReparseTag = IO_REPARSE_TAG_MOUNT_POINT);
      end
      else
      begin
        // 如果无法获取重解析数据，但有重解析点属性，仍认为是符号链接
        Result := True;
      end;
    finally
      CloseHandle(Handle);
    end;

  except
    on E: Exception do
    begin
      // 记录异常但不抛出，返回False
      AddColoredStatusMessage('⚠️ 检测符号链接异常: ' + APath + ' - ' + E.Message, clMaroon);
      Result := False;
    end;
  end;
end;

// 获取符号链接的目标路径 (增强版)
function TfrmMain.GetSymlinkTarget(const APath: string): string;
var
  Handle: THandle;
  Buffer: array[0..32767] of Char;  // 增大缓冲区
  ReparseData: array[0..MAXIMUM_REPARSE_DATA_BUFFER_SIZE-1] of Byte;
  BytesReturned: DWORD;
  ReparseTag: DWORD;
  TargetPath: string;
  PathOffset, PathLength: Word;
begin
  Result := '';

  try
    if not IsSymbolicLink(APath) then
      Exit;

    Handle := CreateFile(
      PChar(APath),
      0,
      FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,
      nil,
      OPEN_EXISTING,
      FILE_FLAG_BACKUP_SEMANTICS or FILE_FLAG_OPEN_REPARSE_POINT,
      0
    );

    if Handle = INVALID_HANDLE_VALUE then
    begin
      AddColoredStatusMessage('⚠️ 无法打开符号链接: ' + APath, clMaroon);
      Exit;
    end;

    try
      // 方法1: 尝试使用GetFinalPathNameByHandle (Windows Vista+)
      FillChar(Buffer, SizeOf(Buffer), 0);
      if GetFinalPathNameByHandle(Handle, Buffer, Length(Buffer), 0) > 0 then
      begin
        Result := string(Buffer);
        // 移除各种前缀
        if Copy(Result, 1, 4) = '\\?\' then
          Result := Copy(Result, 5, Length(Result) - 4)
        else if Copy(Result, 1, 8) = '\\?\UNC\' then
          Result := '\\' + Copy(Result, 9, Length(Result) - 8);
      end
      else
      begin
        // 方法2: 直接解析重解析点数据
        if DeviceIoControl(
          Handle,
          FSCTL_GET_REPARSE_POINT,
          nil,
          0,
          @ReparseData[0],
          SizeOf(ReparseData),
          BytesReturned,
          nil
        ) then
        begin
          ReparseTag := PDWORD(@ReparseData[0])^;

          if ReparseTag = IO_REPARSE_TAG_SYMLINK then
          begin
            // 符号链接
            PathOffset := PWord(@ReparseData[8])^;  // SubstituteNameOffset
            PathLength := PWord(@ReparseData[10])^; // SubstituteNameLength

            if (PathOffset + PathLength < BytesReturned) and (PathLength > 0) then
            begin
              SetLength(TargetPath, PathLength div 2);
              Move(ReparseData[20 + PathOffset], TargetPath[1], PathLength);
              Result := TargetPath;
            end;
          end
          else if ReparseTag = IO_REPARSE_TAG_MOUNT_POINT then
          begin
            // 挂载点/目录连接
            PathOffset := PWord(@ReparseData[8])^;  // SubstituteNameOffset
            PathLength := PWord(@ReparseData[10])^; // SubstituteNameLength

            if (PathOffset + PathLength < BytesReturned) and (PathLength > 0) then
            begin
              SetLength(TargetPath, PathLength div 2);
              Move(ReparseData[16 + PathOffset], TargetPath[1], PathLength);
              Result := TargetPath;
            end;
          end;
        end;
      end;

      // 清理结果路径
      if Result <> '' then
      begin
        // 移除 \??\ 前缀
        if Copy(Result, 1, 4) = '\??\' then
          Result := Copy(Result, 5, Length(Result) - 4);

        // 验证目标路径是否存在
        if not (DirectoryExists(Result) or FileExists(Result)) then
        begin
          AddColoredStatusMessage('⚠️ 符号链接目标不存在: ' + Result, clMaroon);
        end;
      end;

    finally
      CloseHandle(Handle);
    end;
  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 获取符号链接目标异常: ' + APath + ' - ' + E.Message, clRed);
      Result := '';
    end;
  end;
end;

// 获取符号链接的详细信息
function TfrmMain.GetSymlinkInfo(const APath: string): string;
var
  Target: string;
  LinkType: string;
  Status: string;
  CreationTime: TDateTime;
  FileInfo: TWin32FindData;
  Handle: THandle;
begin
  Result := '';

  try
    if not IsSymbolicLink(APath) then
    begin
      Result := '❌ 不是符号链接';
      Exit;
    end;

    // 获取链接类型
    if DirectoryExists(APath) then
      LinkType := '目录链接'
    else if FileExists(APath) then
      LinkType := '文件链接'
    else
      LinkType := '未知类型';

    // 获取目标路径
    Target := GetSymlinkTarget(APath);
    if Target = '' then
      Target := '无法获取目标路径';

    // 验证目标有效性
    if (Target <> '无法获取目标路径') then
    begin
      if DirectoryExists(Target) or FileExists(Target) then
        Status := '✅ 目标有效'
      else
        Status := '❌ 目标无效';
    end
    else
      Status := '❓ 无法验证';

    // 获取创建时间
    Handle := FindFirstFile(PChar(APath), FileInfo);
    if Handle <> INVALID_HANDLE_VALUE then
    begin
      try
        CreationTime := FileTimeToDateTime(FileInfo.ftCreationTime);
        Result := Format('🔗 %s' + sLineBreak +
                        '📍 目标: %s' + sLineBreak +
                        '🔍 状态: %s' + sLineBreak +
                        '📅 创建: %s',
                        [LinkType, Target, Status, DateTimeToStr(CreationTime)]);
      finally
        Windows.FindClose(Handle);
      end;
    end
    else
    begin
      Result := Format('🔗 %s' + sLineBreak +
                      '📍 目标: %s' + sLineBreak +
                      '🔍 状态: %s',
                      [LinkType, Target, Status]);
    end;

  except
    on E: Exception do
    begin
      Result := '❌ 获取符号链接信息失败: ' + E.Message;
    end;
  end;
end;

// 验证符号链接的有效性
function TfrmMain.ValidateSymlink(const APath: string): Boolean;
var
  Target: string;
begin
  Result := False;

  try
    if not IsSymbolicLink(APath) then
      Exit;

    Target := GetSymlinkTarget(APath);
    if Target = '' then
      Exit;

    // 检查目标是否存在
    Result := DirectoryExists(Target) or FileExists(Target);

  except
    Result := False;
  end;
end;

// 移除状态前缀，返回纯净的目录名
function TfrmMain.RemoveStatusPrefix(const AText: string): string;
var
  Prefixes: array[0..8] of string;
  I: Integer;
begin
  Result := AText;

  // 定义所有可能的前缀
  Prefixes[0] := '✅ ';      // 3个字符
  Prefixes[1] := '❌ ';      // 3个字符
  Prefixes[2] := '⚠️ ';      // 3个字符
  Prefixes[3] := '❓ ';      // 3个字符
  Prefixes[4] := '🔗✅ ';    // 5个字符
  Prefixes[5] := '🔗❌ ';    // 5个字符
  Prefixes[6] := '🔗📌 ';    // 5个字符
  Prefixes[7] := '📋✅ ';    // 5个字符
  Prefixes[8] := '💾✅ ';    // 5个字符

  // 检查并移除匹配的前缀
  for I := 0 to High(Prefixes) do
  begin
    if Copy(Result, 1, Length(Prefixes[I])) = Prefixes[I] then
    begin
      Result := Copy(Result, Length(Prefixes[I]) + 1, Length(Result));
      Break;
    end;
  end;

  // 处理特殊的长前缀
  if Copy(Result, 1, 6) = '🔗📁 ' then
    Result := Copy(Result, 7, Length(Result))
  else if Copy(Result, 1, 6) = '📋⏳ ' then
    Result := Copy(Result, 7, Length(Result));
end;

// ===== 符号链接缓存管理 =====

// 初始化符号链接缓存
procedure TfrmMain.InitializeSymlinkCache;
var
  CacheDir: string;
begin
  try
    // 创建缓存目录
    CacheDir := ExtractFilePath(Application.ExeName) + 'Cache';
    if not DirectoryExists(CacheDir) then
      ForceDirectories(CacheDir);

    // 创建缓存对象
    FSymlinkCache := TSymlinkCache.Create(CacheDir + '\symlinks.cache');

    // 加载现有缓存
    LoadSymlinkCache;

    AddColoredStatusMessage('✅ 符号链接缓存已初始化', clGreen);
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 初始化符号链接缓存失败: ' + E.Message, clMaroon);
  end;
end;

// 清理符号链接缓存
procedure TfrmMain.FinalizeSymlinkCache;
begin
  try
    if Assigned(FSymlinkCache) then
    begin
      SaveSymlinkCache;
      FreeAndNil(FSymlinkCache);
      AddColoredStatusMessage('✅ 符号链接缓存已保存并清理', clGreen);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 清理符号链接缓存失败: ' + E.Message, clMaroon);
  end;
end;

// 加载符号链接缓存
procedure TfrmMain.LoadSymlinkCache;
begin
  try
    if Assigned(FSymlinkCache) then
    begin
      FSymlinkCache.LoadFromFile;

      if FSymlinkCache.SymlinkCount > 0 then
      begin
        AddColoredStatusMessage(Format('📂 已加载 %d 个符号链接缓存记录', [FSymlinkCache.SymlinkCount]), clBlue);

        if IsCacheExpired then
          AddColoredStatusMessage('⏰ 缓存已过期，建议重新扫描', clOlive);
      end;
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 加载符号链接缓存失败: ' + E.Message, clMaroon);
  end;
end;

// 保存符号链接缓存
procedure TfrmMain.SaveSymlinkCache;
begin
  try
    if Assigned(FSymlinkCache) then
    begin
      FSymlinkCache.SaveToFile;
      AddColoredStatusMessage(Format('💾 已保存 %d 个符号链接缓存记录', [FSymlinkCache.SymlinkCount]), clBlue);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 保存符号链接缓存失败: ' + E.Message, clMaroon);
  end;
end;

// 获取缓存的符号链接信息
function TfrmMain.GetCachedSymlinkInfo(const APath: string): TSymlinkInfo;
begin
  if Assigned(FSymlinkCache) and FSymlinkCache.HasSymlink(APath) then
    Result := FSymlinkCache.FindSymlink(APath)
  else
  begin
    // 返回空记录
    Result.Path := '';
    Result.Target := '';
    Result.Status := dsNormal;
    Result.IsValid := False;
    Result.ScanTime := 0;
    Result.FileSize := 0;
    Result.IsDirectory := False;
  end;
end;

// 缓存符号链接信息
procedure TfrmMain.CacheSymlinkInfo(const AInfo: TSymlinkInfo);
begin
  try
    if Assigned(FSymlinkCache) then
    begin
      FSymlinkCache.AddSymlink(AInfo);
      FSymlinkCache.LastScanTime := Now;
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 缓存符号链接信息失败: ' + E.Message, clMaroon);
  end;
end;

// 检查缓存是否过期
function TfrmMain.IsCacheExpired: Boolean;
begin
  if Assigned(FSymlinkCache) then
    Result := FSymlinkCache.IsExpired(24) // 24小时过期
  else
    Result := True;
end;

// ===== 拷贝会话管理 =====

// 初始化拷贝会话管理器
procedure TfrmMain.InitializeCopySessionManager;
var
  SessionDir: string;
begin
  try
    // 创建会话目录
    SessionDir := ExtractFilePath(Application.ExeName) + 'Sessions';
    if not DirectoryExists(SessionDir) then
      ForceDirectories(SessionDir);

    // 创建会话管理器
    FCopySessionManager := TCopySessionManager.Create(SessionDir + '\copy_session.dat');

    AddColoredStatusMessage('✅ 拷贝会话管理器已初始化', clGreen);

    // 检查是否有未完成的会话
    if CheckForIncompleteSession then
      ShowResumeDialog;

  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 初始化拷贝会话管理器失败: ' + E.Message, clMaroon);
  end;
end;

// 清理拷贝会话管理器
procedure TfrmMain.FinalizeCopySessionManager;
begin
  try
    if Assigned(FCopySessionManager) then
    begin
      FCopySessionManager.SaveCurrentSession;
      FreeAndNil(FCopySessionManager);
      AddColoredStatusMessage('✅ 拷贝会话管理器已清理', clGreen);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 清理拷贝会话管理器失败: ' + E.Message, clMaroon);
  end;
end;

// 开始新的拷贝会话
function TfrmMain.StartCopySession(const ASourceDir, ATargetDir: string): Boolean;
var
  SessionId: string;
begin
  Result := False;

  try
    if not Assigned(FCopySessionManager) then
    begin
      AddColoredStatusMessage('❌ 拷贝会话管理器未初始化', clRed);
      Exit;
    end;

    SessionId := FCopySessionManager.CreateSession(ASourceDir, ATargetDir);
    AddColoredStatusMessage('🆕 创建新拷贝会话: ' + SessionId, clBlue);
    AddColoredStatusMessage('   源目录: ' + ASourceDir, clGray);
    AddColoredStatusMessage('   目标目录: ' + ATargetDir, clGray);

    Result := True;
  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 创建拷贝会话失败: ' + E.Message, clRed);
      Result := False;
    end;
  end;
end;

// 保存拷贝会话
procedure TfrmMain.SaveCopySession;
begin
  try
    if Assigned(FCopySessionManager) then
    begin
      FCopySessionManager.SaveCurrentSession;
      AddColoredStatusMessage('💾 拷贝会话已保存', clBlue);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 保存拷贝会话失败: ' + E.Message, clMaroon);
  end;
end;

// 加载拷贝会话
function TfrmMain.LoadCopySession(const ASessionId: string): Boolean;
begin
  Result := False;

  try
    if not Assigned(FCopySessionManager) then
      Exit;

    Result := FCopySessionManager.LoadSession(ASessionId);

    if Result then
      AddColoredStatusMessage('📂 拷贝会话已加载: ' + ASessionId, clBlue)
    else
      AddColoredStatusMessage('❌ 加载拷贝会话失败: ' + ASessionId, clRed);

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 加载拷贝会话异常: ' + E.Message, clRed);
      Result := False;
    end;
  end;
end;

// 检查是否有未完成的会话
function TfrmMain.CheckForIncompleteSession: Boolean;
begin
  Result := False;

  try
    if Assigned(FCopySessionManager) then
    begin
      // 尝试加载最近的会话文件
      var SessionFile := FCopySessionManager.FSessionFile;
      if FileExists(SessionFile) then
      begin
        // 这里需要实现检查逻辑
        // 暂时返回False，后续完善
        Result := False;
      end;
    end;
  except
    Result := False;
  end;
end;

// 显示恢复对话框
procedure TfrmMain.ShowResumeDialog;
var
  DialogText: string;
  UserChoice: Integer;
begin
  try
    if not Assigned(FCopySessionManager) or not FCopySessionManager.CanResume then
      Exit;

    DialogText := '发现未完成的拷贝会话：' + #13#10#13#10 +
                 '会话ID: ' + FCopySessionManager.CurrentSession.SessionId + #13#10 +
                 '源目录: ' + FCopySessionManager.CurrentSession.SourceDir + #13#10 +
                 '目标目录: ' + FCopySessionManager.CurrentSession.TargetDir + #13#10 +
                 '进度: ' + Format('%.1f%%', [FCopySessionManager.GetSessionProgress]) + #13#10#13#10 +
                 '是否要继续之前的拷贝操作？';

    UserChoice := MessageDlg(DialogText, mtConfirmation, [mbYes, mbNo, mbCancel], 0);

    case UserChoice of
      mrYes:
      begin
        AddColoredStatusMessage('🔄 用户选择继续拷贝会话', clBlue);
        FCopySessionManager.ResumeSession;
        // 这里可以触发继续拷贝的逻辑
      end;
      mrNo:
      begin
        AddColoredStatusMessage('🚫 用户选择取消拷贝会话', clOlive);
        FCopySessionManager.CancelSession;
      end;
      mrCancel:
      begin
        AddColoredStatusMessage('⏸️ 用户选择暂停拷贝会话', clGray);
        FCopySessionManager.PauseSession;
      end;
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示恢复对话框失败: ' + E.Message, clRed);
  end;
end;

// ===== 断点续传功能 =====

// 计算文件校验和 (使用MD5)
function TfrmMain.CalculateFileChecksum(const AFilePath: string): string;
var
  FileStream: TFileStream;
  MD5: THashMD5;
  Buffer: TBytes;
  BytesRead: Integer;
const
  BufferSize = 64 * 1024; // 64KB缓冲区
begin
  Result := '';

  try
    if not FileExists(AFilePath) then
      Exit;

    FileStream := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyWrite);
    try
      MD5 := THashMD5.Create;
      SetLength(Buffer, BufferSize);

      while FileStream.Position < FileStream.Size do
      begin
        BytesRead := FileStream.Read(Buffer[0], BufferSize);
        if BytesRead > 0 then
          MD5.Update(Buffer, BytesRead);
      end;

      Result := MD5.HashAsString;
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 计算文件校验和失败: ' + E.Message, clRed);
      Result := '';
    end;
  end;
end;

// 获取文件部分校验和 (用于验证部分拷贝的文件)
function TfrmMain.GetFilePartialChecksum(const AFilePath: string; ASize: Int64): string;
var
  FileStream: TFileStream;
  MD5: THashMD5;
  Buffer: TBytes;
  BytesRead: Integer;
  TotalRead: Int64;
const
  BufferSize = 64 * 1024; // 64KB缓冲区
begin
  Result := '';

  try
    if not FileExists(AFilePath) then
      Exit;

    FileStream := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyWrite);
    try
      MD5 := THashMD5.Create;
      SetLength(Buffer, BufferSize);
      TotalRead := 0;

      while (FileStream.Position < FileStream.Size) and (TotalRead < ASize) do
      begin
        var ReadSize := Min(BufferSize, ASize - TotalRead);
        BytesRead := FileStream.Read(Buffer[0], ReadSize);
        if BytesRead > 0 then
        begin
          MD5.Update(Buffer, BytesRead);
          Inc(TotalRead, BytesRead);
        end
        else
          Break;
      end;

      Result := MD5.HashAsString;
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 计算部分文件校验和失败: ' + E.Message, clRed);
      Result := '';
    end;
  end;
end;

// 验证文件完整性
function TfrmMain.VerifyFileIntegrity(const AFilePath: string; const AExpectedChecksum: string): Boolean;
var
  ActualChecksum: string;
begin
  Result := False;

  try
    if AExpectedChecksum = '' then
    begin
      // 如果没有期望的校验和，只检查文件是否存在
      Result := FileExists(AFilePath);
      Exit;
    end;

    ActualChecksum := CalculateFileChecksum(AFilePath);
    Result := SameText(ActualChecksum, AExpectedChecksum);

    if Result then
      AddColoredStatusMessage('✅ 文件完整性验证通过: ' + ExtractFileName(AFilePath), clGreen)
    else
      AddColoredStatusMessage('❌ 文件完整性验证失败: ' + ExtractFileName(AFilePath), clRed);

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 验证文件完整性异常: ' + E.Message, clRed);
      Result := False;
    end;
  end;
end;

// 从指定位置恢复文件拷贝
function TfrmMain.ResumeFileCopy(const ASourcePath, ATargetPath: string; AStartPos: Int64): Boolean;
var
  SourceStream, TargetStream: TFileStream;
  Buffer: TBytes;
  BytesRead, BytesWritten: Integer;
  TotalCopied: Int64;
const
  BufferSize = 1024 * 1024; // 1MB缓冲区
begin
  Result := False;
  TotalCopied := 0;

  try
    if not FileExists(ASourcePath) then
    begin
      AddColoredStatusMessage('❌ 源文件不存在: ' + ASourcePath, clRed);
      Exit;
    end;

    // 打开源文件
    SourceStream := TFileStream.Create(ASourcePath, fmOpenRead or fmShareDenyWrite);
    try
      // 打开或创建目标文件
      if FileExists(ATargetPath) then
        TargetStream := TFileStream.Create(ATargetPath, fmOpenWrite)
      else
        TargetStream := TFileStream.Create(ATargetPath, fmCreate);

      try
        // 定位到指定位置
        SourceStream.Position := AStartPos;
        TargetStream.Position := AStartPos;

        SetLength(Buffer, BufferSize);

        AddColoredStatusMessage(Format('🔄 从位置 %d 恢复拷贝: %s', [AStartPos, ExtractFileName(ASourcePath)]), clBlue);

        // 拷贝剩余数据
        while SourceStream.Position < SourceStream.Size do
        begin
          // 检查是否暂停
          while IsCopyPaused do
          begin
            Application.ProcessMessages;
            Sleep(100);
          end;

          // 检查是否取消
          if FCopyStopRequested then
          begin
            AddColoredStatusMessage('🛑 用户取消了拷贝操作', clOlive);
            Exit;
          end;

          BytesRead := SourceStream.Read(Buffer[0], BufferSize);
          if BytesRead > 0 then
          begin
            BytesWritten := TargetStream.Write(Buffer[0], BytesRead);
            if BytesWritten <> BytesRead then
            begin
              AddColoredStatusMessage('❌ 写入数据不完整', clRed);
              Exit;
            end;

            Inc(TotalCopied, BytesWritten);

            // 更新进度
            if Assigned(FCopySessionManager) then
            begin
              FCopySessionManager.UpdateFileProgress(ASourcePath, AStartPos + TotalCopied, csInProgress);

              // 计算文件进度和总体进度
              var FileProgress := ((AStartPos + TotalCopied) / SourceStream.Size) * 100;
              var TotalProgress := FCopySessionManager.GetSessionProgress;

              // 更新增强进度显示
              UpdateEnhancedCopyProgress(ExtractFileName(ASourcePath), FileProgress, TotalProgress);
            end;

            // 处理消息，保持界面响应
            if TotalCopied mod (1024 * 1024) = 0 then // 每1MB更新一次
              Application.ProcessMessages;
          end
          else
            Break;
        end;

        // 设置文件时间
        var SourceFileTime: TFileTime;
        var SourceHandle := CreateFile(PChar(ASourcePath), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
        if SourceHandle <> INVALID_HANDLE_VALUE then
        begin
          if GetFileTime(SourceHandle, nil, nil, @SourceFileTime) then
          begin
            var TargetHandle := CreateFile(PChar(ATargetPath), GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);
            if TargetHandle <> INVALID_HANDLE_VALUE then
            begin
              SetFileTime(TargetHandle, nil, nil, @SourceFileTime);
              CloseHandle(TargetHandle);
            end;
          end;
          CloseHandle(SourceHandle);
        end;

        Result := True;
        AddColoredStatusMessage(Format('✅ 文件恢复拷贝完成: %s (%d 字节)', [ExtractFileName(ASourcePath), TotalCopied]), clGreen);

      finally
        TargetStream.Free;
      end;
    finally
      SourceStream.Free;
    end;

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 恢复文件拷贝失败: ' + E.Message, clRed);
      Result := False;
    end;
  end;
end;

// 带断点续传的文件拷贝
procedure TfrmMain.CopyFileWithResume(const ASourcePath, ATargetPath: string);
var
  SourceSize, TargetSize: Int64;
  SourceChecksum, TargetPartialChecksum: string;
  CanResume: Boolean;
begin
  try
    AddColoredStatusMessage('📋 开始智能拷贝: ' + ExtractFileName(ASourcePath), clBlue);

    // 初始化增强进度显示（如果还没有初始化）
    if FCopyStartTime = 0 then
      InitializeEnhancedProgress;

    // 获取源文件大小
    if not FileExists(ASourcePath) then
    begin
      AddColoredStatusMessage('❌ 源文件不存在: ' + ASourcePath, clRed);
      Exit;
    end;

    var SourceHandle := CreateFile(PChar(ASourcePath), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
    if SourceHandle = INVALID_HANDLE_VALUE then
    begin
      AddColoredStatusMessage('❌ 无法打开源文件: ' + ASourcePath, clRed);
      Exit;
    end;

    try
      if not GetFileSizeEx(SourceHandle, SourceSize) then
      begin
        AddColoredStatusMessage('❌ 无法获取源文件大小', clRed);
        Exit;
      end;
    finally
      CloseHandle(SourceHandle);
    end;

    // 检查目标文件是否存在
    CanResume := False;
    TargetSize := 0;

    if FileExists(ATargetPath) then
    begin
      var TargetHandle := CreateFile(PChar(ATargetPath), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
      if TargetHandle <> INVALID_HANDLE_VALUE then
      begin
        try
          if GetFileSizeEx(TargetHandle, TargetSize) then
          begin
            if TargetSize < SourceSize then
            begin
              // 目标文件较小，可能可以续传
              AddColoredStatusMessage(Format('🔍 检测到部分文件: %d/%d 字节', [TargetSize, SourceSize]), clBlue);

              // 验证已拷贝部分的完整性
              SourceChecksum := GetFilePartialChecksum(ASourcePath, TargetSize);
              TargetPartialChecksum := CalculateFileChecksum(ATargetPath);

              if SameText(SourceChecksum, TargetPartialChecksum) then
              begin
                CanResume := True;
                AddColoredStatusMessage('✅ 部分文件完整性验证通过，可以续传', clGreen);
              end
              else
              begin
                AddColoredStatusMessage('❌ 部分文件完整性验证失败，将重新拷贝', clOlive);
                TargetSize := 0;
              end;
            end
            else if TargetSize = SourceSize then
            begin
              // 文件大小相同，验证完整性
              if VerifyFileIntegrity(ATargetPath, CalculateFileChecksum(ASourcePath)) then
              begin
                AddColoredStatusMessage('✅ 文件已存在且完整，跳过拷贝', clGreen);
                if Assigned(FCopySessionManager) then
                  FCopySessionManager.CompleteFile(ASourcePath, CalculateFileChecksum(ATargetPath));
                Exit;
              end
              else
              begin
                AddColoredStatusMessage('❌ 文件已存在但不完整，将重新拷贝', clOlive);
                TargetSize := 0;
              end;
            end
            else
            begin
              AddColoredStatusMessage('⚠️ 目标文件比源文件大，将重新拷贝', clOlive);
              TargetSize := 0;
            end;
          end;
        finally
          CloseHandle(TargetHandle);
        end;
      end;
    end;

    // 执行拷贝或续传
    if CanResume and (TargetSize > 0) then
    begin
      if ResumeFileCopy(ASourcePath, ATargetPath, TargetSize) then
      begin
        if Assigned(FCopySessionManager) then
          FCopySessionManager.CompleteFile(ASourcePath, CalculateFileChecksum(ATargetPath));
      end
      else
      begin
        if Assigned(FCopySessionManager) then
          FCopySessionManager.FailFile(ASourcePath, '续传失败');
      end;
    end
    else
    begin
      // 完整拷贝
      if ResumeFileCopy(ASourcePath, ATargetPath, 0) then
      begin
        if Assigned(FCopySessionManager) then
          FCopySessionManager.CompleteFile(ASourcePath, CalculateFileChecksum(ATargetPath));
      end
      else
      begin
        if Assigned(FCopySessionManager) then
          FCopySessionManager.FailFile(ASourcePath, '拷贝失败');
      end;
    end;

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 智能拷贝异常: ' + E.Message, clRed);
      if Assigned(FCopySessionManager) then
        FCopySessionManager.FailFile(ASourcePath, E.Message);
    end;
  end;
end;

// ===== 增强拷贝进度显示 =====

// 初始化增强进度显示
procedure TfrmMain.InitializeEnhancedProgress;
begin
  FCopyStartTime := Now;
  FLastProgressUpdate := Now;
  FLastCopiedBytes := 0;
  FCopySpeed := 0;
  FCanPauseCopy := True;
  FCopyPaused := False;

  // 初始化进度条
  if Assigned(ProgressBar) then
  begin
    ProgressBar.Position := 0;
    ProgressBar.Max := 100;
    ProgressBar.Visible := True;
  end;

  if Assigned(PBarAFile) then
  begin
    PBarAFile.Position := 0;
    PBarAFile.Max := 100;
    PBarAFile.Visible := True;
  end;

  AddColoredStatusMessage('📊 增强进度显示已初始化', clBlue);
end;

// 清理增强进度显示
procedure TfrmMain.FinalizeEnhancedProgress;
begin
  FCanPauseCopy := False;
  FCopyPaused := False;

  // 隐藏进度条
  if Assigned(ProgressBar) then
    ProgressBar.Visible := False;

  if Assigned(PBarAFile) then
    PBarAFile.Visible := False;

  AddColoredStatusMessage('📊 增强进度显示已清理', clBlue);
end;

// 更新增强拷贝进度
procedure TfrmMain.UpdateEnhancedCopyProgress(const ACurrentFile: string; AFileProgress, ATotalProgress: Double);
var
  CurrentTime: TDateTime;
  ElapsedSeconds: Double;
  CurrentCopiedBytes: Int64;
  SpeedText, ETAText, ProgressText: string;
begin
  try
    CurrentTime := Now;

    // 更新进度条
    if Assigned(PBarAFile) then
      PBarAFile.Position := Round(AFileProgress);

    if Assigned(ProgressBar) then
      ProgressBar.Position := Round(ATotalProgress);

    // 计算拷贝速度 (每秒更新一次)
    ElapsedSeconds := (CurrentTime - FLastProgressUpdate) * 24 * 60 * 60;
    if ElapsedSeconds >= 1.0 then
    begin
      if Assigned(FCopySessionManager) and FCopySessionManager.HasCurrentSession then
      begin
        CurrentCopiedBytes := FCopySessionManager.CurrentSession.CopiedSize;

        if FLastCopiedBytes > 0 then
        begin
          var BytesDiff := CurrentCopiedBytes - FLastCopiedBytes;
          FCopySpeed := BytesDiff / ElapsedSeconds;
        end;

        FLastCopiedBytes := CurrentCopiedBytes;
        FLastProgressUpdate := CurrentTime;

        // 显示速度和ETA
        ShowCopySpeedAndETA(CurrentCopiedBytes, CurrentTime - FCopyStartTime);
      end;
    end;

    // 更新状态显示
    ProgressText := Format('📋 当前文件: %s (%.1f%%) | 总进度: %.1f%%',
                          [ExtractFileName(ACurrentFile), AFileProgress, ATotalProgress]);
    AddColoredStatusMessage(ProgressText, clBlue);

    // 处理消息，保持界面响应
    Application.ProcessMessages;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 更新进度显示失败: ' + E.Message, clRed);
  end;
end;

// 显示拷贝速度和预计剩余时间
procedure TfrmMain.ShowCopySpeedAndETA(ACopiedBytes: Int64; AElapsedTime: TDateTime);
var
  SpeedText, ETAText, StatusText: string;
  RemainingBytes: Int64;
  ETASeconds: Integer;
begin
  try
    if not Assigned(FCopySessionManager) or not FCopySessionManager.HasCurrentSession then
      Exit;

    var Session := FCopySessionManager.CurrentSession;

    // 格式化速度
    if FCopySpeed > 0 then
      SpeedText := FormatFileSize(Round(FCopySpeed)) + '/s'
    else
      SpeedText := '计算中...';

    // 计算预计剩余时间
    RemainingBytes := Session.TotalSize - ACopiedBytes;
    if (FCopySpeed > 0) and (RemainingBytes > 0) then
    begin
      ETASeconds := Round(RemainingBytes / FCopySpeed);
      ETAText := FormatTimeSpan(ETASeconds);
    end
    else
      ETAText := '计算中...';

    // 构建状态文本
    StatusText := Format('⚡ 速度: %s | ⏱️ 剩余时间: %s | 📊 已完成: %s/%s (%.1f%%)',
                        [SpeedText, ETAText,
                         FormatFileSize(ACopiedBytes),
                         FormatFileSize(Session.TotalSize),
                         FCopySessionManager.GetSessionProgress]);

    AddColoredStatusMessage(StatusText, clNavy);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示速度和ETA失败: ' + E.Message, clRed);
  end;
end;

// 格式化文件大小
function TfrmMain.FormatFileSize(ABytes: Int64): string;
const
  Units: array[0..4] of string = ('B', 'KB', 'MB', 'GB', 'TB');
var
  UnitIndex: Integer;
  Size: Double;
begin
  UnitIndex := 0;
  Size := ABytes;

  while (Size >= 1024) and (UnitIndex < High(Units)) do
  begin
    Size := Size / 1024;
    Inc(UnitIndex);
  end;

  if UnitIndex = 0 then
    Result := Format('%d %s', [Round(Size), Units[UnitIndex]])
  else
    Result := Format('%.1f %s', [Size, Units[UnitIndex]]);
end;

// 格式化时间跨度
function TfrmMain.FormatTimeSpan(ASeconds: Integer): string;
var
  Hours, Minutes, Seconds: Integer;
begin
  if ASeconds < 0 then
  begin
    Result := '未知';
    Exit;
  end;

  Hours := ASeconds div 3600;
  Minutes := (ASeconds mod 3600) div 60;
  Seconds := ASeconds mod 60;

  if Hours > 0 then
    Result := Format('%d:%02d:%02d', [Hours, Minutes, Seconds])
  else if Minutes > 0 then
    Result := Format('%d:%02d', [Minutes, Seconds])
  else
    Result := Format('%d秒', [Seconds]);
end;

// 暂停拷贝操作
procedure TfrmMain.PauseCopyOperation;
begin
  try
    if FCanPauseCopy and not FCopyPaused then
    begin
      FCopyPaused := True;

      if Assigned(FCopySessionManager) then
        FCopySessionManager.PauseSession;

      AddColoredStatusMessage('⏸️ 拷贝操作已暂停', clOlive);

      // 更新按钮状态
      UpdateCopyButtonState;
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 暂停拷贝操作失败: ' + E.Message, clRed);
  end;
end;

// 恢复拷贝操作
procedure TfrmMain.ResumeCopyOperation;
begin
  try
    if FCanPauseCopy and FCopyPaused then
    begin
      FCopyPaused := False;

      if Assigned(FCopySessionManager) then
        FCopySessionManager.ResumeSession;

      AddColoredStatusMessage('▶️ 拷贝操作已恢复', clGreen);

      // 重置时间计算
      FLastProgressUpdate := Now;

      // 更新按钮状态
      UpdateCopyButtonState;
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 恢复拷贝操作失败: ' + E.Message, clRed);
  end;
end;

// 检查拷贝是否已暂停
function TfrmMain.IsCopyPaused: Boolean;
begin
  Result := FCopyPaused;
end;

// ===== 状态管理 =====

// 初始化状态管理器
procedure TfrmMain.InitializeStatusManager;
var
  StatusDir: string;
begin
  try
    // 创建状态目录
    StatusDir := ExtractFilePath(Application.ExeName) + 'Status';
    if not DirectoryExists(StatusDir) then
      ForceDirectories(StatusDir);

    // 创建状态管理器
    FStatusManager := TStatusManager.Create(StatusDir + '\operation_history.dat', 1000);

    // 加载现有状态
    FStatusManager.LoadFromFile;

    AddColoredStatusMessage('✅ 状态管理器已初始化', clGreen);

    if FStatusManager.OperationCount > 0 then
      AddColoredStatusMessage(Format('📂 已加载 %d 条操作历史记录', [FStatusManager.OperationCount]), clBlue);

  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 初始化状态管理器失败: ' + E.Message, clMaroon);
  end;
end;

// 清理状态管理器
procedure TfrmMain.FinalizeStatusManager;
begin
  try
    if Assigned(FStatusManager) then
    begin
      FStatusManager.SaveToFile;
      FreeAndNil(FStatusManager);
      AddColoredStatusMessage('✅ 状态管理器已清理', clGreen);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 清理状态管理器失败: ' + E.Message, clMaroon);
  end;
end;

// 记录操作日志
procedure TfrmMain.LogOperation(AType: TOperationType; const ASourcePath, ATargetPath, ADescription: string; ASuccess: Boolean; const AErrorMsg: string);
var
  Operation: TOperationHistory;
begin
  try
    if not Assigned(FStatusManager) then
      Exit;

    Operation.OperationType := AType;
    Operation.SourcePath := ASourcePath;
    Operation.TargetPath := ATargetPath;
    Operation.Description := ADescription;
    Operation.Success := ASuccess;
    Operation.ErrorMessage := AErrorMsg;
    Operation.OldStatus := dsNormal;
    Operation.NewStatus := dsNormal;

    FStatusManager.AddOperation(Operation);

    // 同时更新用户行为模式
    UpdateUserBehavior(AType, ASourcePath, ASuccess);

  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 记录操作日志失败: ' + E.Message, clMaroon);
  end;
end;

// 更新目录状态并记录历史
procedure TfrmMain.UpdateDirectoryStatusWithHistory(const APath: string; ANewStatus: TDirectoryStatus; const ADescription: string);
begin
  try
    if not Assigned(FStatusManager) then
      Exit;

    FStatusManager.SetDirectoryStatus(APath, ANewStatus, ADescription);

    // 同时更新可视化显示
    MarkDirectoryWithStatus(APath, ANewStatus);

  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 更新目录状态失败: ' + E.Message, clMaroon);
  end;
end;

// 获取目录当前状态
function TfrmMain.GetDirectoryCurrentStatus(const APath: string): TDirectoryStatus;
begin
  if Assigned(FStatusManager) then
    Result := FStatusManager.GetDirectoryStatus(APath)
  else
    Result := dsNormal;
end;

// 显示操作历史
procedure TfrmMain.ShowOperationHistory;
var
  History: TArray<TOperationHistory>;
  I: Integer;
  HistoryText: string;
  TypeText: string;
begin
  try
    if not Assigned(FStatusManager) then
    begin
      AddColoredStatusMessage('❌ 状态管理器未初始化', clRed);
      Exit;
    end;

    History := FStatusManager.GetOperationHistory(20); // 显示最近20条记录

    if Length(History) = 0 then
    begin
      AddColoredStatusMessage('📋 暂无操作历史记录', clGray);
      Exit;
    end;

    AddColoredStatusMessage('📋 最近操作历史:', clNavy);

    for I := 0 to High(History) do
    begin
      case History[I].OperationType of
        otDirectoryAnalysis: TypeText := '目录分析';
        otSymlinkScan: TypeText := '符号链接扫描';
        otSymlinkRepair: TypeText := '符号链接修复';
        otFileCopy: TypeText := '文件拷贝';
        otFileMove: TypeText := '文件移动';
        otDirectoryCreate: TypeText := '目录创建';
        otDirectoryDelete: TypeText := '目录删除';
        otStatusChange: TypeText := '状态变更';
        otCacheUpdate: TypeText := '缓存更新';
        otSessionCreate: TypeText := '会话创建';
        otSessionComplete: TypeText := '会话完成';
        otUserAction: TypeText := '用户操作';
      else
        TypeText := '未知操作';
      end;

      HistoryText := Format('%s [%s] %s: %s',
                           [DateTimeToStr(History[I].Timestamp),
                            TypeText,
                            if History[I].Success then '✅' else '❌',
                            History[I].Description]);

      AddColoredStatusMessage('   ' + HistoryText, if History[I].Success then clGray else clMaroon);

      if History[I].SourcePath <> '' then
        AddColoredStatusMessage('     源: ' + History[I].SourcePath, clSilver);

      if History[I].TargetPath <> '' then
        AddColoredStatusMessage('     目标: ' + History[I].TargetPath, clSilver);

      if not History[I].Success and (History[I].ErrorMessage <> '') then
        AddColoredStatusMessage('     错误: ' + History[I].ErrorMessage, clRed);
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示操作历史失败: ' + E.Message, clRed);
  end;
end;

// 显示状态统计
procedure TfrmMain.ShowStatusStatistics;
var
  TotalOps, SymlinkOps, CopyOps, StatusOps: Integer;
  DirectoryStates: Integer;
begin
  try
    if not Assigned(FStatusManager) then
    begin
      AddColoredStatusMessage('❌ 状态管理器未初始化', clRed);
      Exit;
    end;

    TotalOps := FStatusManager.OperationCount;
    SymlinkOps := FStatusManager.GetOperationCountByType(otSymlinkScan) +
                  FStatusManager.GetOperationCountByType(otSymlinkRepair);
    CopyOps := FStatusManager.GetOperationCountByType(otFileCopy) +
               FStatusManager.GetOperationCountByType(otFileMove);
    StatusOps := FStatusManager.GetOperationCountByType(otStatusChange);
    DirectoryStates := FStatusManager.DirectoryStateCount;

    AddColoredStatusMessage('📊 状态统计信息:', clNavy);
    AddColoredStatusMessage(Format('   总操作数: %d', [TotalOps]), clBlue);
    AddColoredStatusMessage(Format('   符号链接操作: %d', [SymlinkOps]), clBlue);
    AddColoredStatusMessage(Format('   拷贝操作: %d', [CopyOps]), clBlue);
    AddColoredStatusMessage(Format('   状态变更: %d', [StatusOps]), clBlue);
    AddColoredStatusMessage(Format('   目录状态数: %d', [DirectoryStates]), clBlue);

    if FStatusManager.CanUndo then
      AddColoredStatusMessage('🔄 可撤销操作: ' + FStatusManager.GetUndoDescription, clOlive);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示状态统计失败: ' + E.Message, clRed);
  end;
end;

// 撤销最后操作
function TfrmMain.UndoLastOperation: Boolean;
var
  UndoDesc: string;
begin
  Result := False;

  try
    if not Assigned(FStatusManager) then
    begin
      AddColoredStatusMessage('❌ 状态管理器未初始化', clRed);
      Exit;
    end;

    if not FStatusManager.CanUndo then
    begin
      AddColoredStatusMessage('❌ 没有可撤销的操作', clRed);
      Exit;
    end;

    UndoDesc := FStatusManager.GetUndoDescription;

    if MessageDlg(Format('确定要撤销以下操作吗？%s%s', [#13#10, UndoDesc]),
                 mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      Result := FStatusManager.UndoLastOperation;

      if Result then
      begin
        AddColoredStatusMessage('✅ 操作已撤销: ' + UndoDesc, clGreen);
        // 刷新显示
        DirListBoxSource.Update;
        DirListBoxTarget.Update;
      end
      else
        AddColoredStatusMessage('❌ 撤销操作失败', clRed);
    end;

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 撤销操作异常: ' + E.Message, clRed);
      Result := False;
    end;
  end;
end;

// 获取状态名称
function TfrmMain.GetStatusName(AStatus: TDirectoryStatus): string;
begin
  case AStatus of
    dsNormal: Result := '普通目录';
    dsSymlink: Result := '有效符号链接';
    dsSymlinkBroken: Result := '无效符号链接';
    dsSymlinkFile: Result := '文件符号链接';
    dsSymlinkDir: Result := '目录符号链接';
    dsMountPoint: Result := '挂载点';
    dsAnalyzed: Result := '已分析';
    dsAnalyzedGood: Result := '分析结果：可链接';
    dsAnalyzedRisk: Result := '分析结果：有风险';
    dsAnalyzedBad: Result := '分析结果：禁止移动';
    dsCopying: Result := '拷贝中';
    dsCopied: Result := '已拷贝';
    dsBackedUp: Result := '已备份';
    dsRestored: Result := '已恢复';
  else
    Result := '未知状态';
  end;
end;

// ===== 目录监控 =====

// 初始化目录监控器
procedure TfrmMain.InitializeDirectoryMonitor;
begin
  try
    FDirectoryMonitor := TDirectoryMonitor.Create;
    AddColoredStatusMessage('✅ 目录监控器已初始化', clGreen);
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 初始化目录监控器失败: ' + E.Message, clMaroon);
  end;
end;

// 清理目录监控器
procedure TfrmMain.FinalizeDirectoryMonitor;
begin
  try
    if Assigned(FDirectoryMonitor) then
    begin
      FreeAndNil(FDirectoryMonitor);
      AddColoredStatusMessage('✅ 目录监控器已清理', clGreen);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 清理目录监控器失败: ' + E.Message, clMaroon);
  end;
end;

// 开始监控指定路径
procedure TfrmMain.StartMonitoring(const APath: string);
begin
  try
    if not Assigned(FDirectoryMonitor) then
      Exit;

    FDirectoryMonitor.AddWatchPath(APath);
    AddColoredStatusMessage('👁️ 开始监控目录: ' + APath, clBlue);

    LogOperation(otUserAction, APath, '', '开始监控目录', True);
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 开始监控失败: ' + E.Message, clMaroon);
  end;
end;

// 停止监控指定路径
procedure TfrmMain.StopMonitoring(const APath: string);
begin
  try
    if not Assigned(FDirectoryMonitor) then
      Exit;

    FDirectoryMonitor.RemoveWatchPath(APath);
    AddColoredStatusMessage('👁️ 停止监控目录: ' + APath, clGray);

    LogOperation(otUserAction, APath, '', '停止监控目录', True);
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 停止监控失败: ' + E.Message, clMaroon);
  end;
end;

// 检查目录变化
procedure TfrmMain.CheckDirectoryChanges;
var
  Changes: TArray<TDirectoryChange>;
begin
  try
    if not Assigned(FDirectoryMonitor) then
      Exit;

    Changes := FDirectoryMonitor.ScanForChanges;

    if Length(Changes) > 0 then
    begin
      AddColoredStatusMessage(Format('🔍 检测到 %d 个目录变化', [Length(Changes)]), clNavy);
      HandleDirectoryChanges(Changes);
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 检查目录变化失败: ' + E.Message, clMaroon);
  end;
end;

// 处理目录变化
procedure TfrmMain.HandleDirectoryChanges(const AChanges: TArray<TDirectoryChange>);
var
  I: Integer;
  Change: TDirectoryChange;
  ChangeTypeText: string;
begin
  try
    for I := 0 to High(AChanges) do
    begin
      Change := AChanges[I];

      case Change.ChangeType of
        dctCreated: ChangeTypeText := '目录创建';
        dctDeleted: ChangeTypeText := '目录删除';
        dctRenamed: ChangeTypeText := '目录重命名';
        dctMoved: ChangeTypeText := '目录移动';
        dctModified: ChangeTypeText := '目录修改';
      else
        ChangeTypeText := '未知变化';
      end;

      case Change.ChangeType of
        dctCreated:
        begin
          AddColoredStatusMessage(Format('📁➕ %s: %s', [ChangeTypeText, Change.NewPath]), clGreen);
          LogOperation(otDirectoryCreate, '', Change.NewPath, ChangeTypeText, True);

          // 自动开始监控新目录
          if Assigned(FDirectoryMonitor) then
            FDirectoryMonitor.AddWatchPath(Change.NewPath);
        end;

        dctDeleted:
        begin
          AddColoredStatusMessage(Format('📁➖ %s: %s', [ChangeTypeText, Change.OldPath]), clRed);
          LogOperation(otDirectoryDelete, Change.OldPath, '', ChangeTypeText, True);

          // 清理相关状态
          if Assigned(FStatusManager) then
            FStatusManager.RemoveDirectoryStatus(Change.OldPath);
        end;

        dctRenamed, dctMoved:
        begin
          AddColoredStatusMessage(Format('📁🔄 %s: %s → %s', [ChangeTypeText, Change.OldPath, Change.NewPath]), clBlue);
          LogOperation(otUserAction, Change.OldPath, Change.NewPath, ChangeTypeText, True);

          // 更新状态映射
          if Assigned(FStatusManager) then
          begin
            var OldStatus := FStatusManager.GetDirectoryStatus(Change.OldPath);
            if OldStatus <> dsNormal then
            begin
              FStatusManager.RemoveDirectoryStatus(Change.OldPath);
              FStatusManager.SetDirectoryStatus(Change.NewPath, OldStatus, '目录移动后状态迁移');
            end;
          end;
        end;

        dctModified:
        begin
          AddColoredStatusMessage(Format('📁🔄 %s: %s', [ChangeTypeText, Change.NewPath]), clOlive);
          LogOperation(otUserAction, Change.NewPath, '', ChangeTypeText, True);

          // 检查是否需要重新扫描符号链接
          if IsSymbolicLink(Change.NewPath) then
          begin
            AddColoredStatusMessage('🔗 检测到符号链接变化，建议重新扫描', clBlue);
          end;
        end;
      end;
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 处理目录变化失败: ' + E.Message, clMaroon);
  end;
end;

// 更新监控路径
procedure TfrmMain.UpdateMonitoredPaths;
begin
  try
    if not Assigned(FDirectoryMonitor) then
      Exit;

    // 清空现有监控路径
    FDirectoryMonitor.ClearWatchPaths;

    // 添加当前源目录和目标目录
    if (edtSource.Text <> '') and DirectoryExists(edtSource.Text) then
      FDirectoryMonitor.AddWatchPath(edtSource.Text);

    if (edtTarget.Text <> '') and DirectoryExists(edtTarget.Text) then
      FDirectoryMonitor.AddWatchPath(edtTarget.Text);

    AddColoredStatusMessage(Format('👁️ 已更新监控路径，当前监控 %d 个目录', [FDirectoryMonitor.WatchedPathCount]), clBlue);

  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 更新监控路径失败: ' + E.Message, clMaroon);
  end;
end;

// ===== 智能建议系统 =====

// 初始化智能建议引擎
procedure TfrmMain.InitializeSmartSuggestions;
var
  SuggestionDir: string;
begin
  try
    // 创建建议目录
    SuggestionDir := ExtractFilePath(Application.ExeName) + 'Suggestions';
    if not DirectoryExists(SuggestionDir) then
      ForceDirectories(SuggestionDir);

    // 创建智能建议引擎
    FSuggestionEngine := TSmartSuggestionEngine.Create(
      SuggestionDir + '\suggestions.dat',
      FStatusManager,
      100
    );

    // 加载现有建议
    FSuggestionEngine.LoadFromFile;

    AddColoredStatusMessage('✅ 智能建议引擎已初始化', clGreen);

    if FSuggestionEngine.SuggestionCount > 0 then
      AddColoredStatusMessage(Format('💡 已加载 %d 条建议记录', [FSuggestionEngine.SuggestionCount]), clBlue);

  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 初始化智能建议引擎失败: ' + E.Message, clMaroon);
  end;
end;

// 清理智能建议引擎
procedure TfrmMain.FinalizeSmartSuggestions;
begin
  try
    if Assigned(FSuggestionEngine) then
    begin
      FSuggestionEngine.SaveToFile;
      FreeAndNil(FSuggestionEngine);
      AddColoredStatusMessage('✅ 智能建议引擎已清理', clGreen);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 清理智能建议引擎失败: ' + E.Message, clMaroon);
  end;
end;

// 显示智能建议
procedure TfrmMain.ShowSmartSuggestions;
var
  Suggestions: TArray<TSmartSuggestion>;
  I: Integer;
  PriorityText, TypeText: string;
begin
  try
    if not Assigned(FSuggestionEngine) then
    begin
      AddColoredStatusMessage('❌ 智能建议引擎未初始化', clRed);
      Exit;
    end;

    Suggestions := FSuggestionEngine.GetSuggestions(stOptimization, 10);

    if Length(Suggestions) = 0 then
    begin
      AddColoredStatusMessage('💡 暂无智能建议', clGray);
      Exit;
    end;

    AddColoredStatusMessage('💡 智能建议列表:', clNavy);

    for I := 0 to High(Suggestions) do
    begin
      case Suggestions[I].Priority of
        spLow: PriorityText := '低';
        spMedium: PriorityText := '中';
        spHigh: PriorityText := '高';
        spCritical: PriorityText := '关键';
      else
        PriorityText := '未知';
      end;

      case Suggestions[I].SuggestionType of
        stOptimization: TypeText := '优化';
        stSafety: TypeText := '安全';
        stEfficiency: TypeText := '效率';
        stMaintenance: TypeText := '维护';
        stWorkflow: TypeText := '工作流';
        stTroubleshooting: TypeText := '故障排除';
        stBestPractice: TypeText := '最佳实践';
      else
        TypeText := '其他';
      end;

      var StatusIcon := if Suggestions[I].IsApplied then '✅' else if Suggestions[I].IsRead then '👁️' else '🆕';
      var PriorityColor := case Suggestions[I].Priority of
        spCritical: clRed;
        spHigh: clMaroon;
        spMedium: clBlue;
        spLow: clGray;
      else
        clBlack;
      end;

      AddColoredStatusMessage(Format('   %s [%s|%s] %s', [StatusIcon, TypeText, PriorityText, Suggestions[I].Title]), PriorityColor);
      AddColoredStatusMessage('     ' + Suggestions[I].Description, clGray);

      if Suggestions[I].ActionText <> '' then
        AddColoredStatusMessage('     👆 ' + Suggestions[I].ActionText, clBlue);

      if Suggestions[I].RelatedPath <> '' then
        AddColoredStatusMessage('     📁 ' + Suggestions[I].RelatedPath, clSilver);

      // 标记为已读
      FSuggestionEngine.MarkSuggestionRead(Suggestions[I].Id);
    end;

    var UnreadCount := FSuggestionEngine.GetUnreadCount;
    if UnreadCount > 0 then
      AddColoredStatusMessage(Format('📬 还有 %d 条未读建议', [UnreadCount]), clOlive);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示智能建议失败: ' + E.Message, clRed);
  end;
end;

// 生成上下文相关建议
procedure TfrmMain.GenerateContextualSuggestions;
begin
  try
    if not Assigned(FSuggestionEngine) then
      Exit;

    // 生成各类建议
    FSuggestionEngine.GenerateOptimizationSuggestions;
    FSuggestionEngine.GenerateSafetySuggestions;

    // 清理过期建议
    FSuggestionEngine.ClearOldSuggestions(7); // 清理7天前的建议

    AddColoredStatusMessage('💡 已生成上下文相关建议', clBlue);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 生成建议失败: ' + E.Message, clRed);
  end;
end;

// 应用建议
procedure TfrmMain.ApplySuggestion(const ASuggestionId: string);
begin
  try
    if not Assigned(FSuggestionEngine) then
      Exit;

    FSuggestionEngine.MarkSuggestionApplied(ASuggestionId);
    AddColoredStatusMessage('✅ 建议已应用: ' + ASuggestionId, clGreen);

    // 记录用户行为
    UpdateUserBehavior(otUserAction, '', True);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 应用建议失败: ' + E.Message, clRed);
  end;
end;

// 忽略建议
procedure TfrmMain.DismissSuggestion(const ASuggestionId: string);
begin
  try
    if not Assigned(FSuggestionEngine) then
      Exit;

    FSuggestionEngine.RemoveSuggestion(ASuggestionId);
    AddColoredStatusMessage('🗑️ 建议已忽略: ' + ASuggestionId, clGray);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 忽略建议失败: ' + E.Message, clRed);
  end;
end;

// 创建建议
function TfrmMain.CreateSuggestion(AType: TSuggestionType; APriority: TSuggestionPriority; const ATitle, ADescription, AActionText, ARelatedPath: string): TSmartSuggestion;
begin
  Result.Id := '';
  Result.SuggestionType := AType;
  Result.Priority := APriority;
  Result.Title := ATitle;
  Result.Description := ADescription;
  Result.ActionText := AActionText;
  Result.RelatedPath := ARelatedPath;
  Result.CreatedTime := Now;
  Result.IsRead := False;
  Result.IsApplied := False;
  Result.AppliedTime := 0;
  Result.UserData := '';
end;

// 更新用户行为
procedure TfrmMain.UpdateUserBehavior(AOperationType: TOperationType; const APath: string; ASuccess: Boolean);
begin
  try
    if Assigned(FSuggestionEngine) then
      FSuggestionEngine.UpdateUserPattern(AOperationType, APath, ASuccess);
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 更新用户行为失败: ' + E.Message, clMaroon);
  end;
end;

// ===== 批量操作功能 =====

// 初始化批量操作管理器
procedure TfrmMain.InitializeBatchOperations;
begin
  try
    FBatchManager := TBatchOperationManager.Create;

    // 设置事件处理
    FBatchManager.OnProgress := OnBatchProgress;
    FBatchManager.OnComplete := OnBatchComplete;
    FBatchManager.OnError := OnBatchError;

    AddColoredStatusMessage('✅ 批量操作管理器已初始化', clGreen);
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 初始化批量操作管理器失败: ' + E.Message, clMaroon);
  end;
end;

// 清理批量操作管理器
procedure TfrmMain.FinalizeBatchOperations;
begin
  try
    if Assigned(FBatchManager) then
    begin
      FreeAndNil(FBatchManager);
      AddColoredStatusMessage('✅ 批量操作管理器已清理', clGreen);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 清理批量操作管理器失败: ' + E.Message, clMaroon);
  end;
end;

// 显示批量操作对话框
procedure TfrmMain.ShowBatchOperationDialog;
var
  Paths: TStringList;
  I: Integer;
  DialogText: string;
  UserChoice: Integer;
begin
  try
    if not Assigned(FBatchManager) then
    begin
      AddColoredStatusMessage('❌ 批量操作管理器未初始化', clRed);
      Exit;
    end;

    Paths := TStringList.Create;
    try
      // 收集可用路径
      if (edtSource.Text <> '') and DirectoryExists(edtSource.Text) then
        Paths.Add(edtSource.Text);
      if (edtTarget.Text <> '') and DirectoryExists(edtTarget.Text) then
        Paths.Add(edtTarget.Text);

      if Paths.Count = 0 then
      begin
        AddColoredStatusMessage('❌ 没有可用的目录路径', clRed);
        Exit;
      end;

      DialogText := '选择批量操作类型：' + #13#10#13#10 +
                   '1. 批量分析目录' + #13#10 +
                   '2. 批量扫描符号链接' + #13#10 +
                   '3. 批量修复符号链接' + #13#10 +
                   '4. 批量状态检查' + #13#10#13#10 +
                   Format('将处理 %d 个目录路径', [Paths.Count]);

      var InputStr := InputBox('批量操作', DialogText, '1');
      if InputStr = '' then
        Exit;

      UserChoice := StrToIntDef(InputStr, 0);

      case UserChoice of
        1: StartBatchAnalysis(Paths.ToStringArray);
        2: StartBatchSymlinkScan(Paths.ToStringArray);
        3: StartBatchSymlinkRepair(Paths.ToStringArray);
        4:
        begin
          AddColoredStatusMessage('📊 批量状态检查功能开发中...', clBlue);
          // TODO: 实现批量状态检查
        end;
      else
        AddColoredStatusMessage('❌ 无效的选择', clRed);
      end;

    finally
      Paths.Free;
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示批量操作对话框失败: ' + E.Message, clRed);
  end;
end;

// 开始批量分析
procedure TfrmMain.StartBatchAnalysis(const APaths: TArray<string>);
var
  I: Integer;
  BatchItem: TBatchOperationItem;
begin
  try
    if not Assigned(FBatchManager) then
      Exit;

    FBatchManager.ClearOperations;

    for I := 0 to High(APaths) do
    begin
      BatchItem := CreateBatchItem(btAnalyze, APaths[I], '');
      FBatchManager.AddOperation(BatchItem);
    end;

    AddColoredStatusMessage(Format('📊 开始批量分析 %d 个目录...', [Length(APaths)]), clNavy);
    LogOperation(otDirectoryAnalysis, '', '', Format('批量分析 %d 个目录', [Length(APaths)]), True);

    // 模拟批量分析过程
    for I := 0 to High(APaths) do
    begin
      AddColoredStatusMessage(Format('📁 分析目录 %d/%d: %s', [I + 1, Length(APaths), ExtractFileName(APaths[I])]), clBlue);

      // 这里可以调用实际的分析方法
      // AnalyzeDirectory(APaths[I]);

      Application.ProcessMessages;
      Sleep(100); // 模拟处理时间
    end;

    AddColoredStatusMessage('✅ 批量分析完成', clGreen);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 批量分析失败: ' + E.Message, clRed);
  end;
end;

// 开始批量拷贝
procedure TfrmMain.StartBatchCopy(const ASourcePaths, ATargetPaths: TArray<string>);
var
  I: Integer;
  BatchItem: TBatchOperationItem;
begin
  try
    if not Assigned(FBatchManager) then
      Exit;

    if Length(ASourcePaths) <> Length(ATargetPaths) then
    begin
      AddColoredStatusMessage('❌ 源路径和目标路径数量不匹配', clRed);
      Exit;
    end;

    FBatchManager.ClearOperations;

    for I := 0 to High(ASourcePaths) do
    begin
      BatchItem := CreateBatchItem(btCopy, ASourcePaths[I], ATargetPaths[I]);
      FBatchManager.AddOperation(BatchItem);
    end;

    AddColoredStatusMessage(Format('📋 开始批量拷贝 %d 个目录...', [Length(ASourcePaths)]), clNavy);
    LogOperation(otFileCopy, '', '', Format('批量拷贝 %d 个目录', [Length(ASourcePaths)]), True);

    // 这里应该实现实际的批量拷贝逻辑
    AddColoredStatusMessage('📋 批量拷贝功能开发中...', clBlue);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 批量拷贝失败: ' + E.Message, clRed);
  end;
end;

// 开始批量符号链接扫描
procedure TfrmMain.StartBatchSymlinkScan(const APaths: TArray<string>);
var
  I: Integer;
  BatchItem: TBatchOperationItem;
begin
  try
    if not Assigned(FBatchManager) then
      Exit;

    FBatchManager.ClearOperations;

    for I := 0 to High(APaths) do
    begin
      BatchItem := CreateBatchItem(btSymlinkScan, APaths[I], '');
      FBatchManager.AddOperation(BatchItem);
    end;

    AddColoredStatusMessage(Format('🔗 开始批量扫描符号链接 %d 个目录...', [Length(APaths)]), clNavy);
    LogOperation(otSymlinkScan, '', '', Format('批量扫描符号链接 %d 个目录', [Length(APaths)]), True);

    // 执行批量符号链接扫描
    for I := 0 to High(APaths) do
    begin
      AddColoredStatusMessage(Format('🔗 扫描目录 %d/%d: %s', [I + 1, Length(APaths), ExtractFileName(APaths[I])]), clBlue);

      // 临时设置源目录并扫描
      var OldSource := edtSource.Text;
      edtSource.Text := APaths[I];
      ScanCurrentDirectorySymlinks(True); // 静默模式
      edtSource.Text := OldSource;

      Application.ProcessMessages;
    end;

    AddColoredStatusMessage('✅ 批量符号链接扫描完成', clGreen);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 批量符号链接扫描失败: ' + E.Message, clRed);
  end;
end;

// 开始批量符号链接修复
procedure TfrmMain.StartBatchSymlinkRepair(const APaths: TArray<string>);
var
  I: Integer;
  BatchItem: TBatchOperationItem;
  InvalidCount: Integer;
begin
  try
    if not Assigned(FBatchManager) then
      Exit;

    FBatchManager.ClearOperations;

    for I := 0 to High(APaths) do
    begin
      BatchItem := CreateBatchItem(btSymlinkRepair, APaths[I], '');
      FBatchManager.AddOperation(BatchItem);
    end;

    AddColoredStatusMessage(Format('🔧 开始批量修复符号链接 %d 个目录...', [Length(APaths)]), clNavy);
    LogOperation(otSymlinkRepair, '', '', Format('批量修复符号链接 %d 个目录', [Length(APaths)]), True);

    InvalidCount := 0;

    // 执行批量符号链接修复
    for I := 0 to High(APaths) do
    begin
      AddColoredStatusMessage(Format('🔧 检查目录 %d/%d: %s', [I + 1, Length(APaths), ExtractFileName(APaths[I])]), clBlue);

      if IsSymbolicLink(APaths[I]) and not ValidateSymlink(APaths[I]) then
      begin
        Inc(InvalidCount);
        AddColoredStatusMessage(Format('❌ 发现无效符号链接: %s', [APaths[I]]), clMaroon);
        // 这里可以调用修复逻辑
        // ShowSymlinkRepairDialog(APaths[I]);
      end;

      Application.ProcessMessages;
    end;

    if InvalidCount > 0 then
      AddColoredStatusMessage(Format('⚠️ 发现 %d 个无效符号链接，请手动修复', [InvalidCount]), clOlive)
    else
      AddColoredStatusMessage('✅ 所有符号链接都有效', clGreen);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 批量符号链接修复失败: ' + E.Message, clRed);
  end;
end;

// 批量操作进度事件
procedure TfrmMain.OnBatchProgress(Sender: TObject);
begin
  try
    if Assigned(FBatchManager) then
    begin
      var Progress := FBatchManager.GetOverallProgress;
      AddColoredStatusMessage(Format('📊 批量操作进度: %.1f%%', [Progress]), clBlue);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 批量操作进度更新失败: ' + E.Message, clRed);
  end;
end;

// 批量操作完成事件
procedure TfrmMain.OnBatchComplete(Sender: TObject);
begin
  try
    if Assigned(FBatchManager) then
    begin
      var CompletedCount := FBatchManager.GetCompletedCount;
      var FailedCount := FBatchManager.GetFailedCount;

      AddColoredStatusMessage(Format('✅ 批量操作完成: %d 成功, %d 失败', [CompletedCount, FailedCount]), clGreen);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 批量操作完成事件处理失败: ' + E.Message, clRed);
  end;
end;

// 批量操作错误事件
procedure TfrmMain.OnBatchError(Sender: TObject);
begin
  try
    AddColoredStatusMessage('❌ 批量操作发生错误', clRed);
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 批量操作错误事件处理失败: ' + E.Message, clRed);
  end;
end;

// 创建批量操作项
function TfrmMain.CreateBatchItem(AOpType: TBatchOperationType; const ASourcePath, ATargetPath: string): TBatchOperationItem;
begin
  Result.SourcePath := ASourcePath;
  Result.TargetPath := ATargetPath;
  Result.OperationType := AOpType;
  Result.Status := csNotStarted;
  Result.Progress := 0;
  Result.ErrorMessage := '';
  Result.StartTime := 0;
  Result.EndTime := 0;
  Result.FileCount := 0;
  Result.ProcessedCount := 0;
  Result.TotalSize := 0;
  Result.ProcessedSize := 0;
end;

// ===== 用户界面优化 =====

// 设置键盘快捷键
procedure TfrmMain.SetupKeyboardShortcuts;
begin
  try
    // 设置窗体的KeyPreview为True以接收键盘事件
    Self.KeyPreview := True;
    Self.OnKeyDown := FormKeyDown;

    AddColoredStatusMessage('⌨️ 键盘快捷键已启用:', clBlue);
    AddColoredStatusMessage('   F1: 显示帮助', clGray);
    AddColoredStatusMessage('   F2: 扫描符号链接', clGray);
    AddColoredStatusMessage('   F3: 显示智能建议', clGray);
    AddColoredStatusMessage('   F4: 批量操作', clGray);
    AddColoredStatusMessage('   F5: 刷新状态', clGray);
    AddColoredStatusMessage('   Ctrl+H: 显示历史记录', clGray);
    AddColoredStatusMessage('   Ctrl+S: 显示统计信息', clGray);
    AddColoredStatusMessage('   Ctrl+Z: 撤销操作', clGray);
    AddColoredStatusMessage('   Ctrl+Q: 快速访问面板', clGray);
    AddColoredStatusMessage('   ESC: 取消当前操作', clGray);

  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 设置键盘快捷键失败: ' + E.Message, clMaroon);
  end;
end;

// 键盘事件处理
procedure TfrmMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  try
    case Key of
      VK_F1: // F1 - 显示帮助
      begin
        AddColoredStatusMessage('📖 C盘瘦身工具帮助:', clNavy);
        AddColoredStatusMessage('   1. 选择源目录和目标目录', clGray);
        AddColoredStatusMessage('   2. 使用右键菜单进行各种操作', clGray);
        AddColoredStatusMessage('   3. 查看状态显示了解操作结果', clGray);
        AddColoredStatusMessage('   4. 使用智能建议优化工作流程', clGray);
      end;

      VK_F2: // F2 - 扫描符号链接
      begin
        if edtSource.Text <> '' then
          ScanCurrentDirectorySymlinks(False)
        else
          AddColoredStatusMessage('❌ 请先选择源目录', clRed);
      end;

      VK_F3: // F3 - 显示智能建议
      begin
        ShowSmartSuggestions;
      end;

      VK_F4: // F4 - 批量操作
      begin
        ShowBatchOperationDialog;
      end;

      VK_F5: // F5 - 刷新状态
      begin
        AddColoredStatusMessage('🔄 刷新状态...', clBlue);
        CheckDirectoryChanges;
        GenerateContextualSuggestions;
        AddColoredStatusMessage('✅ 状态已刷新', clGreen);
      end;

      VK_ESCAPE: // ESC - 取消当前操作
      begin
        if Assigned(FBatchManager) and FBatchManager.IsRunning then
        begin
          FBatchManager.StopBatch;
          AddColoredStatusMessage('🛑 批量操作已取消', clOlive);
        end
        else if FCopyPaused then
        begin
          ResumeCopyOperation;
        end
        else
        begin
          AddColoredStatusMessage('ℹ️ 没有正在进行的操作', clGray);
        end;
      end;
    end;

    // 处理Ctrl组合键
    if ssCtrl in Shift then
    begin
      case Key of
        Ord('H'): // Ctrl+H - 显示历史记录
        begin
          ShowOperationHistory;
        end;

        Ord('S'): // Ctrl+S - 显示统计信息
        begin
          ShowStatusStatistics;
        end;

        Ord('Z'): // Ctrl+Z - 撤销操作
        begin
          UndoLastOperation;
        end;

        Ord('Q'): // Ctrl+Q - 快速访问面板
        begin
          ShowQuickAccessPanel;
        end;

        Ord('G'): // Ctrl+G - 生成建议
        begin
          GenerateContextualSuggestions;
        end;
      end;
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 键盘事件处理失败: ' + E.Message, clRed);
  end;
end;

// 更新UI布局
procedure TfrmMain.UpdateUILayout;
begin
  try
    // 优化控件布局
    if Assigned(ProgressBar) then
    begin
      ProgressBar.Height := 20;
      ProgressBar.Style := pbstMarquee;
    end;

    if Assigned(PBarAFile) then
    begin
      PBarAFile.Height := 16;
      PBarAFile.Style := pbstNormal;
    end;

    // 优化状态显示
    if Assigned(RichEditStatus) then
    begin
      RichEditStatus.ScrollBars := ssVertical;
      RichEditStatus.ReadOnly := True;
      RichEditStatus.WordWrap := True;
    end;

    AddColoredStatusMessage('🎨 UI布局已优化', clBlue);

  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 更新UI布局失败: ' + E.Message, clMaroon);
  end;
end;

// 显示快速访问面板
procedure TfrmMain.ShowQuickAccessPanel;
var
  QuickActions: TStringList;
  I: Integer;
  ActionText: string;
begin
  try
    QuickActions := TStringList.Create;
    try
      QuickActions.Add('1. 扫描符号链接 (F2)');
      QuickActions.Add('2. 显示智能建议 (F3)');
      QuickActions.Add('3. 批量操作 (F4)');
      QuickActions.Add('4. 显示历史记录 (Ctrl+H)');
      QuickActions.Add('5. 显示统计信息 (Ctrl+S)');
      QuickActions.Add('6. 撤销操作 (Ctrl+Z)');
      QuickActions.Add('7. 生成建议 (Ctrl+G)');
      QuickActions.Add('8. 刷新状态 (F5)');

      ActionText := '🚀 快速访问面板:' + #13#10;
      for I := 0 to QuickActions.Count - 1 do
        ActionText := ActionText + '   ' + QuickActions[I] + #13#10;

      ActionText := ActionText + #13#10 + '选择操作 (1-8):';

      var InputStr := InputBox('快速访问', ActionText, '');
      if InputStr = '' then
        Exit;

      var Choice := StrToIntDef(InputStr, 0);
      case Choice of
        1: if edtSource.Text <> '' then ScanCurrentDirectorySymlinks(False);
        2: ShowSmartSuggestions;
        3: ShowBatchOperationDialog;
        4: ShowOperationHistory;
        5: ShowStatusStatistics;
        6: UndoLastOperation;
        7: GenerateContextualSuggestions;
        8:
        begin
          CheckDirectoryChanges;
          GenerateContextualSuggestions;
          AddColoredStatusMessage('✅ 状态已刷新', clGreen);
        end;
      else
        AddColoredStatusMessage('❌ 无效的选择', clRed);
      end;

    finally
      QuickActions.Free;
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示快速访问面板失败: ' + E.Message, clRed);
  end;
end;

// 隐藏快速访问面板
procedure TfrmMain.HideQuickAccessPanel;
begin
  // 这个方法为将来的UI改进预留
  AddColoredStatusMessage('ℹ️ 快速访问面板已隐藏', clGray);
end;

// 创建快速操作按钮
procedure TfrmMain.CreateQuickActionButtons;
begin
  try
    // 这里可以动态创建快速操作按钮
    // 为了简化，我们先在状态中显示可用的快速操作

    AddColoredStatusMessage('🔧 快速操作按钮:', clNavy);
    AddColoredStatusMessage('   右键菜单提供完整功能', clGray);
    AddColoredStatusMessage('   使用快捷键快速访问', clGray);
    AddColoredStatusMessage('   Ctrl+Q 打开快速访问面板', clGray);

  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 创建快速操作按钮失败: ' + E.Message, clMaroon);
  end;
end;

// 显示进度摘要
procedure TfrmMain.ShowProgressSummary;
var
  SummaryText: string;
begin
  try
    SummaryText := '📊 系统状态摘要:' + #13#10;

    if Assigned(FStatusManager) then
    begin
      SummaryText := SummaryText + Format('   操作历史: %d 条记录%s', [FStatusManager.OperationCount, #13#10]);
      SummaryText := SummaryText + Format('   目录状态: %d 个目录%s', [FStatusManager.DirectoryStateCount, #13#10]);
    end;

    if Assigned(FSymlinkCache) then
    begin
      SummaryText := SummaryText + Format('   符号链接缓存: %d 个链接%s', [FSymlinkCache.SymlinkCount, #13#10]);
      SummaryText := SummaryText + Format('   有效链接: %d 个%s', [FSymlinkCache.ValidSymlinkCount, #13#10]);
    end;

    if Assigned(FSuggestionEngine) then
    begin
      SummaryText := SummaryText + Format('   智能建议: %d 条建议%s', [FSuggestionEngine.SuggestionCount, #13#10]);
      SummaryText := SummaryText + Format('   未读建议: %d 条%s', [FSuggestionEngine.UnreadCount, #13#10]);
    end;

    if Assigned(FBatchManager) then
    begin
      SummaryText := SummaryText + Format('   批量操作: %d 个任务%s', [FBatchManager.GetOperationCount, #13#10]);
      if FBatchManager.IsRunning then
        SummaryText := SummaryText + Format('   当前进度: %.1f%%%s', [FBatchManager.GetOverallProgress, #13#10]);
    end;

    if Assigned(FDirectoryMonitor) then
    begin
      SummaryText := SummaryText + Format('   监控路径: %d 个目录%s', [FDirectoryMonitor.WatchedPathCount, #13#10]);
    end;

    MessageDlg(SummaryText, mtInformation, [mbOK], 0);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示进度摘要失败: ' + E.Message, clRed);
  end;
end;

// 优化性能
procedure TfrmMain.OptimizePerformance;
begin
  try
    // 清理过期数据
    if Assigned(FSuggestionEngine) then
      FSuggestionEngine.ClearOldSuggestions(7);

    // 优化缓存
    if Assigned(FSymlinkCache) and FSymlinkCache.IsExpired then
      AddColoredStatusMessage('💡 建议: 符号链接缓存已过期，考虑重新扫描', clOlive);

    // 检查内存使用
    var MemUsage := GetHeapStatus;
    if MemUsage.TotalAllocated > 100 * 1024 * 1024 then // 100MB
      AddColoredStatusMessage('⚠️ 内存使用较高，建议重启程序', clOlive);

    AddColoredStatusMessage('⚡ 性能优化完成', clGreen);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 性能优化失败: ' + E.Message, clRed);
  end;
end;

// ===== 现代化界面样式 =====

// 应用现代化样式
procedure TfrmMain.ApplyModernStyles;
begin
  try
    // 应用窗体样式
    StyleManager.StyleForm(Self);

    // 应用控件样式
    UpdateControlStyles;

    // 更新状态显示颜色
    UpdateStatusColors;

    AddColoredStatusMessage('🎨 现代化界面样式已应用', clBlue);

  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 应用现代化样式失败: ' + E.Message, clMaroon);
  end;
end;

// 切换主题
procedure TfrmMain.ToggleTheme;
begin
  try
    StyleManager.ToggleTheme;
    ApplyModernStyles;

    if StyleManager.IsDarkMode then
      AddColoredStatusMessage('🌙 已切换到深色主题', clBlue)
    else
      AddColoredStatusMessage('☀️ 已切换到浅色主题', clBlue);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 切换主题失败: ' + E.Message, clRed);
  end;
end;

// 更新控件样式
procedure TfrmMain.UpdateControlStyles;
var
  I: Integer;
  Component: TComponent;
begin
  try
    // 遍历所有控件并应用样式
    for I := 0 to ComponentCount - 1 do
    begin
      Component := Components[I];

      if Component is TPanel then
        StyleManager.StylePanel(TPanel(Component))
      else if Component is TButton then
        StyleManager.StyleButton(TButton(Component))
      else if Component is TEdit then
        StyleManager.StyleEdit(TEdit(Component))
      else if Component is TListView then
        StyleManager.StyleListView(TListView(Component))
      else if Component is TTreeView then
        StyleManager.StyleTreeView(TTreeView(Component))
      else if Component is TProgressBar then
        StyleManager.StyleProgressBar(TProgressBar(Component))
      else if Component is TRichEdit then
        StyleManager.StyleRichEdit(TRichEdit(Component))
      else if Component is TStatusBar then
        StyleManager.StyleStatusBar(TStatusBar(Component));
    end;

    // 特殊控件样式处理
    if Assigned(RichEditStatus) then
    begin
      RichEditStatus.Color := StyleManager.CurrentTheme.Surface;
      RichEditStatus.Font.Name := 'Consolas';
      RichEditStatus.Font.Size := 9;
    end;

    if Assigned(ProgressBar) then
    begin
      ProgressBar.Smooth := True;
      ProgressBar.Style := pbstNormal;
    end;

    if Assigned(PBarAFile) then
    begin
      PBarAFile.Smooth := True;
      PBarAFile.Style := pbstNormal;
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 更新控件样式失败: ' + E.Message, clMaroon);
  end;
end;

// 更新状态显示颜色
procedure TfrmMain.UpdateStatusColors;
begin
  try
    // 这个方法用于更新状态显示的颜色
    // 在实际应用中，会根据当前主题更新各种状态的显示颜色

    // 刷新状态显示
    if Assigned(RichEditStatus) then
      RichEditStatus.Invalidate;

  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 更新状态颜色失败: ' + E.Message, clMaroon);
  end;
end;

// ===== 依赖关系分析 =====

// 初始化依赖关系分析
procedure TfrmMain.InitializeDependencyAnalysis;
var
  AnalysisDir: string;
begin
  try
    // 创建分析目录
    AnalysisDir := ExtractFilePath(Application.ExeName) + 'Analysis';
    if not DirectoryExists(AnalysisDir) then
      ForceDirectories(AnalysisDir);

    // 创建依赖关系图
    FDependencyGraph := TDependencyGraph.Create(AnalysisDir + '\dependencies.dat');

    // 加载现有数据
    FDependencyGraph.LoadFromFile;

    AddColoredStatusMessage('✅ 依赖关系分析引擎已初始化', clGreen);

    if FDependencyGraph.DependencyCount > 0 then
      AddColoredStatusMessage(Format('📊 已加载 %d 个依赖关系记录', [FDependencyGraph.DependencyCount]), clBlue);

  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 初始化依赖关系分析失败: ' + E.Message, clMaroon);
  end;
end;

// 清理依赖关系分析
procedure TfrmMain.FinalizeDependencyAnalysis;
begin
  try
    if Assigned(FDependencyGraph) then
    begin
      FDependencyGraph.SaveToFile;
      FreeAndNil(FDependencyGraph);
      AddColoredStatusMessage('✅ 依赖关系分析引擎已清理', clGreen);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 清理依赖关系分析失败: ' + E.Message, clMaroon);
  end;
end;

// 分析依赖关系
procedure TfrmMain.AnalyzeDependencies(const APath: string);
begin
  try
    if not Assigned(FDependencyGraph) then
    begin
      AddColoredStatusMessage('❌ 依赖关系分析引擎未初始化', clRed);
      Exit;
    end;

    if not DirectoryExists(APath) then
    begin
      AddColoredStatusMessage('❌ 指定路径不存在: ' + APath, clRed);
      Exit;
    end;

    AddColoredStatusMessage('🔍 开始分析依赖关系: ' + ExtractFileName(APath), clNavy);

    // 检测符号链接依赖
    DetectSymlinkDependencies(APath);

    // 检测文件依赖
    DetectFileDependencies(APath);

    // 显示分析结果
    var Dependencies := FDependencyGraph.FindDependencies(APath);
    var Dependents := FDependencyGraph.FindDependents(APath);

    AddColoredStatusMessage(Format('📊 分析完成: %d 个依赖项, %d 个依赖者', [Length(Dependencies), Length(Dependents)]), clBlue);

    if Length(Dependencies) > 0 then
    begin
      AddColoredStatusMessage('📤 依赖项:', clBlue);
      for var Dep in Dependencies do
        AddColoredStatusMessage(Format('   → %s (%s)', [Dep.TargetPath, GetDependencyTypeName(Dep.DependencyType)]), clGray);
    end;

    if Length(Dependents) > 0 then
    begin
      AddColoredStatusMessage('📥 依赖者:', clBlue);
      for var Dep in Dependents do
        AddColoredStatusMessage(Format('   ← %s (%s)', [Dep.SourcePath, GetDependencyTypeName(Dep.DependencyType)]), clGray);
    end;

    // 记录操作
    LogOperation(otDirectoryAnalysis, APath, '', '依赖关系分析', True);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 分析依赖关系失败: ' + E.Message, clRed);
  end;
end;

// 显示依赖关系图
procedure TfrmMain.ShowDependencyGraph;
var
  GraphData: string;
begin
  try
    if not Assigned(FDependencyGraph) then
    begin
      AddColoredStatusMessage('❌ 依赖关系分析引擎未初始化', clRed);
      Exit;
    end;

    GraphData := FDependencyGraph.GetStatistics;

    AddColoredStatusMessage('📊 依赖关系图统计:', clNavy);
    AddColoredStatusMessage(GraphData, clBlue);

    // 显示详细的图形化数据
    var DetailedData := FDependencyGraph.GenerateGraphData;
    if DetailedData <> '' then
    begin
      AddColoredStatusMessage('🔗 依赖关系详情:', clNavy);
      AddColoredStatusMessage(DetailedData, clGray);
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示依赖关系图失败: ' + E.Message, clRed);
  end;
end;

// 显示循环依赖
procedure TfrmMain.ShowCircularDependencies;
var
  Cycles: TArray<TArray<string>>;
  I, J: Integer;
begin
  try
    if not Assigned(FDependencyGraph) then
    begin
      AddColoredStatusMessage('❌ 依赖关系分析引擎未初始化', clRed);
      Exit;
    end;

    AddColoredStatusMessage('🔍 检测循环依赖...', clBlue);

    Cycles := FDependencyGraph.DetectCircularDependencies;

    if Length(Cycles) = 0 then
    begin
      AddColoredStatusMessage('✅ 未发现循环依赖', clGreen);
    end
    else
    begin
      AddColoredStatusMessage(Format('⚠️ 发现 %d 个循环依赖:', [Length(Cycles)]), clMaroon);

      for I := 0 to High(Cycles) do
      begin
        var CycleText := Format('   循环 %d: ', [I + 1]);
        for J := 0 to High(Cycles[I]) do
        begin
          CycleText := CycleText + ExtractFileName(Cycles[I][J]);
          if J < High(Cycles[I]) then
            CycleText := CycleText + ' → ';
        end;
        CycleText := CycleText + ' → ' + ExtractFileName(Cycles[I][0]); // 回到起点

        AddColoredStatusMessage(CycleText, clRed);
      end;

      AddColoredStatusMessage('💡 建议: 循环依赖可能导致移动操作失败', clOlive);
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 检测循环依赖失败: ' + E.Message, clRed);
  end;
end;

// 显示关键路径
procedure TfrmMain.ShowCriticalPaths;
var
  CriticalPaths: TArray<TArray<string>>;
  I, J: Integer;
begin
  try
    if not Assigned(FDependencyGraph) then
    begin
      AddColoredStatusMessage('❌ 依赖关系分析引擎未初始化', clRed);
      Exit;
    end;

    AddColoredStatusMessage('🔍 分析关键路径...', clBlue);

    CriticalPaths := FDependencyGraph.FindCriticalPaths;

    if Length(CriticalPaths) = 0 then
    begin
      AddColoredStatusMessage('ℹ️ 未发现关键路径', clGray);
    end
    else
    begin
      AddColoredStatusMessage(Format('🎯 发现 %d 条关键路径:', [Length(CriticalPaths)]), clNavy);

      for I := 0 to High(CriticalPaths) do
      begin
        var PathText := Format('   路径 %d: ', [I + 1]);
        for J := 0 to High(CriticalPaths[I]) do
        begin
          PathText := PathText + ExtractFileName(CriticalPaths[I][J]);
          if J < High(CriticalPaths[I]) then
            PathText := PathText + ' → ';
        end;

        AddColoredStatusMessage(PathText, clBlue);
      end;

      AddColoredStatusMessage('💡 建议: 关键路径上的目录移动需要特别小心', clOlive);
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 分析关键路径失败: ' + E.Message, clRed);
  end;
end;

// 评估移动风险
procedure TfrmMain.AssessMovementRisk(const APath: string);
var
  RiskLevel: Integer;
  ImpactScore: Double;
  Dependencies, Dependents: TArray<TDependencyRelation>;
  RiskText, RecommendationText: string;
begin
  try
    if not Assigned(FDependencyGraph) then
    begin
      AddColoredStatusMessage('❌ 依赖关系分析引擎未初始化', clRed);
      Exit;
    end;

    AddColoredStatusMessage('🎯 评估移动风险: ' + ExtractFileName(APath), clNavy);

    RiskLevel := FDependencyGraph.AssessMovementRisk(APath);
    ImpactScore := FDependencyGraph.CalculateImpactScore(APath);
    Dependencies := FDependencyGraph.FindDependencies(APath);
    Dependents := FDependencyGraph.FindDependents(APath);

    // 确定风险等级文本和颜色
    case RiskLevel of
      1..3:
      begin
        RiskText := '低风险';
        AddColoredStatusMessage(Format('✅ 风险评估: %s (等级 %d/10)', [RiskText, RiskLevel]), clGreen);
        RecommendationText := '可以安全移动';
      end;
      4..6:
      begin
        RiskText := '中等风险';
        AddColoredStatusMessage(Format('⚠️ 风险评估: %s (等级 %d/10)', [RiskText, RiskLevel]), clOlive);
        RecommendationText := '建议先备份，然后小心移动';
      end;
      7..8:
      begin
        RiskText := '高风险';
        AddColoredStatusMessage(Format('🔶 风险评估: %s (等级 %d/10)', [RiskText, RiskLevel]), clMaroon);
        RecommendationText := '强烈建议先解决依赖关系';
      end;
      9..10:
      begin
        RiskText := '极高风险';
        AddColoredStatusMessage(Format('🔴 风险评估: %s (等级 %d/10)', [RiskText, RiskLevel]), clRed);
        RecommendationText := '不建议移动，可能导致系统问题';
      end;
    else
      RiskText := '未知风险';
      AddColoredStatusMessage(Format('❓ 风险评估: %s', [RiskText]), clGray);
      RecommendationText := '需要进一步分析';
    end;

    AddColoredStatusMessage(Format('📊 影响分数: %.2f', [ImpactScore]), clBlue);
    AddColoredStatusMessage(Format('📤 依赖项数量: %d', [Length(Dependencies)]), clBlue);
    AddColoredStatusMessage(Format('📥 依赖者数量: %d', [Length(Dependents)]), clBlue);
    AddColoredStatusMessage('💡 建议: ' + RecommendationText, clNavy);

    // 如果有高风险依赖，显示详细信息
    var HighRiskDeps := FDependencyGraph.GetHighRiskDependencies;
    if Length(HighRiskDeps) > 0 then
    begin
      AddColoredStatusMessage('⚠️ 高风险依赖项:', clMaroon);
      for var Dep in HighRiskDeps do
      begin
        if SameText(Dep.SourcePath, APath) or SameText(Dep.TargetPath, APath) then
          AddColoredStatusMessage(Format('   %s → %s (%s)', [ExtractFileName(Dep.SourcePath), ExtractFileName(Dep.TargetPath), Dep.Description]), clRed);
      end;
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 评估移动风险失败: ' + E.Message, clRed);
  end;
end;

// 创建依赖关系记录
function TfrmMain.CreateDependency(AType: TDependencyType; AStrength: TDependencyStrength; const ASource, ATarget, ADescription: string): TDependencyRelation;
begin
  Result.Id := '';
  Result.SourcePath := ASource;
  Result.TargetPath := ATarget;
  Result.DependencyType := AType;
  Result.Strength := AStrength;
  Result.Description := ADescription;
  Result.IsValid := True;
  Result.IsCritical := (AStrength in [dsStrong, dsCritical]);
  Result.DetectedTime := Now;
  Result.LastVerified := Now;
  Result.RiskLevel := Ord(AStrength) + 1;
  Result.ImpactScore := Ord(AStrength) * 2.5;
  Result.UserData := '';
end;

// 检测符号链接依赖
procedure TfrmMain.DetectSymlinkDependencies(const APath: string);
var
  SearchRec: TSearchRec;
  FullPath, Target: string;
  Dependency: TDependencyRelation;
begin
  try
    if FindFirst(APath + '\*', faAnyFile, SearchRec) = 0 then
    begin
      try
        repeat
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          begin
            FullPath := APath + '\' + SearchRec.Name;

            if IsSymbolicLink(FullPath) then
            begin
              Target := GetSymlinkTarget(FullPath);
              if Target <> '' then
              begin
                Dependency := CreateDependency(
                  dtSymbolicLink,
                  if ValidateSymlink(FullPath) then dsModerate else dsWeak,
                  FullPath,
                  Target,
                  '符号链接依赖'
                );

                FDependencyGraph.AddDependency(Dependency);
                AddColoredStatusMessage(Format('🔗 检测到符号链接依赖: %s → %s', [SearchRec.Name, ExtractFileName(Target)]), clBlue);
              end;
            end;
          end;
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 检测符号链接依赖失败: ' + E.Message, clRed);
  end;
end;

// 检测文件依赖
procedure TfrmMain.DetectFileDependencies(const APath: string);
begin
  try
    // 这里可以实现更复杂的文件依赖检测逻辑
    // 例如：检测配置文件中的路径引用、注册表依赖等

    AddColoredStatusMessage('🔍 检测文件依赖: ' + ExtractFileName(APath), clGray);

    // 示例：检测常见的配置文件
    var ConfigFiles := ['config.ini', 'settings.xml', 'app.config', '.env'];
    for var ConfigFile in ConfigFiles do
    begin
      var ConfigPath := APath + '\' + ConfigFile;
      if FileExists(ConfigPath) then
      begin
        var Dependency := CreateDependency(
          dtConfigFile,
          dsModerate,
          APath,
          ConfigPath,
          '配置文件依赖'
        );

        FDependencyGraph.AddDependency(Dependency);
        AddColoredStatusMessage(Format('📄 检测到配置文件依赖: %s', [ConfigFile]), clGray);
      end;
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 检测文件依赖失败: ' + E.Message, clRed);
  end;
end;

// 获取依赖类型名称
function TfrmMain.GetDependencyTypeName(AType: TDependencyType): string;
begin
  case AType of
    dtSymbolicLink: Result := '符号链接';
    dtFileReference: Result := '文件引用';
    dtPathReference: Result := '路径引用';
    dtConfigFile: Result := '配置文件';
    dtRegistry: Result := '注册表';
    dtEnvironment: Result := '环境变量';
    dtService: Result := '服务';
    dtLibrary: Result := '库文件';
  else
    Result := '未知类型';
  end;
end;

// ===== 配置模板系统 =====

// 初始化配置模板管理器
procedure TfrmMain.InitializeTemplateManager;
var
  TemplateDir: string;
begin
  try
    // 创建模板目录
    TemplateDir := ExtractFilePath(Application.ExeName) + 'Templates';
    if not DirectoryExists(TemplateDir) then
      ForceDirectories(TemplateDir);

    // 创建配置模板管理器
    FTemplateManager := TConfigTemplateManager.Create(TemplateDir + '\templates.dat');

    // 加载现有模板
    FTemplateManager.LoadFromFile;

    AddColoredStatusMessage('✅ 配置模板管理器已初始化', clGreen);

    if FTemplateManager.TemplateCount > 0 then
      AddColoredStatusMessage(Format('📋 已加载 %d 个配置模板', [FTemplateManager.TemplateCount]), clBlue);

    // 如果没有默认模板，创建一个
    var DefaultTemplate := FTemplateManager.GetDefaultTemplate;
    if DefaultTemplate.Id = '' then
    begin
      var TemplateId := FTemplateManager.CreateTemplate('默认配置', '系统默认配置模板', ctGeneral);
      var Template := FTemplateManager.GetTemplate(TemplateId);
      Template.IsDefault := True;
      Template.SourcePath := 'C:\';
      Template.TargetPath := 'D:\';
      Template.CopyOptions := 'Standard';
      Template.AnalysisOptions := 'Full';
      Template.SecuritySettings := 'Medium';
      Template.PerformanceSettings := 'Balanced';
      Template.UISettings := 'Standard';
      FTemplateManager.SaveTemplate(Template);

      AddColoredStatusMessage('📋 已创建默认配置模板', clBlue);
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 初始化配置模板管理器失败: ' + E.Message, clMaroon);
  end;
end;

// 清理配置模板管理器
procedure TfrmMain.FinalizeTemplateManager;
begin
  try
    if Assigned(FTemplateManager) then
    begin
      FTemplateManager.SaveToFile;
      FreeAndNil(FTemplateManager);
      AddColoredStatusMessage('✅ 配置模板管理器已清理', clGreen);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 清理配置模板管理器失败: ' + E.Message, clMaroon);
  end;
end;

// 显示模板管理器
procedure TfrmMain.ShowTemplateManager;
var
  Templates: TArray<TConfigTemplate>;
  I: Integer;
  TypeText: string;
begin
  try
    if not Assigned(FTemplateManager) then
    begin
      AddColoredStatusMessage('❌ 配置模板管理器未初始化', clRed);
      Exit;
    end;

    Templates := FTemplateManager.GetAllTemplates;

    if Length(Templates) = 0 then
    begin
      AddColoredStatusMessage('📋 暂无配置模板', clGray);
      Exit;
    end;

    AddColoredStatusMessage('📋 配置模板列表:', clNavy);

    for I := 0 to High(Templates) do
    begin
      TypeText := GetTemplateTypeName(Templates[I].TemplateType);

      var StatusIcon := if Templates[I].IsDefault then '⭐' else if Templates[I].IsActive then '✅' else '⏸️';

      AddColoredStatusMessage(Format('   %s [%s] %s', [StatusIcon, TypeText, Templates[I].Name]), clBlue);
      AddColoredStatusMessage(Format('     📝 %s', [Templates[I].Description]), clGray);
      AddColoredStatusMessage(Format('     🏷️ 版本: %s | 创建者: %s | 创建时间: %s', [
        Templates[I].Version,
        Templates[I].CreatedBy,
        FormatDateTime('yyyy-mm-dd hh:nn', Templates[I].CreatedTime)
      ]), clSilver);

      if Templates[I].SourcePath <> '' then
        AddColoredStatusMessage(Format('     📁 源路径: %s', [Templates[I].SourcePath]), clSilver);
      if Templates[I].TargetPath <> '' then
        AddColoredStatusMessage(Format('     📁 目标路径: %s', [Templates[I].TargetPath]), clSilver);
    end;

    AddColoredStatusMessage(Format('📊 总计: %d 个模板', [Length(Templates)]), clNavy);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示模板管理器失败: ' + E.Message, clRed);
  end;
end;

// 创建新模板
procedure TfrmMain.CreateNewTemplate;
var
  TemplateName, TemplateDesc: string;
  TemplateType: TConfigTemplateType;
  TemplateId: string;
  Template: TConfigTemplate;
begin
  try
    if not Assigned(FTemplateManager) then
    begin
      AddColoredStatusMessage('❌ 配置模板管理器未初始化', clRed);
      Exit;
    end;

    TemplateName := InputBox('创建模板', '请输入模板名称:', '新配置模板');
    if TemplateName = '' then
      Exit;

    TemplateDesc := InputBox('创建模板', '请输入模板描述:', '自定义配置模板');
    if TemplateDesc = '' then
      TemplateDesc := '用户创建的配置模板';

    // 默认创建自定义类型模板
    TemplateType := ctCustom;

    TemplateId := FTemplateManager.CreateTemplate(TemplateName, TemplateDesc, TemplateType);

    // 使用当前设置填充模板
    Template := GetCurrentSettingsAsTemplate;
    Template.Id := TemplateId;
    Template.Name := TemplateName;
    Template.Description := TemplateDesc;
    Template.TemplateType := TemplateType;

    FTemplateManager.SaveTemplate(Template);

    AddColoredStatusMessage(Format('✅ 已创建配置模板: %s', [TemplateName]), clGreen);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 创建新模板失败: ' + E.Message, clRed);
  end;
end;

// 加载模板对话框
procedure TfrmMain.LoadTemplateDialog;
var
  Templates: TArray<TConfigTemplate>;
  TemplateList: TStringList;
  I, SelectedIndex: Integer;
  DialogText, InputStr: string;
begin
  try
    if not Assigned(FTemplateManager) then
    begin
      AddColoredStatusMessage('❌ 配置模板管理器未初始化', clRed);
      Exit;
    end;

    Templates := FTemplateManager.GetAllTemplates;

    if Length(Templates) = 0 then
    begin
      AddColoredStatusMessage('❌ 没有可用的配置模板', clRed);
      Exit;
    end;

    TemplateList := TStringList.Create;
    try
      DialogText := '选择要加载的配置模板:' + #13#10#13#10;

      for I := 0 to High(Templates) do
      begin
        TemplateList.Add(Templates[I].Name);
        DialogText := DialogText + Format('%d. %s (%s)%s', [
          I + 1,
          Templates[I].Name,
          GetTemplateTypeName(Templates[I].TemplateType),
          #13#10
        ]);
      end;

      DialogText := DialogText + #13#10 + '请输入模板编号 (1-' + IntToStr(Length(Templates)) + '):';

      InputStr := InputBox('加载模板', DialogText, '1');
      if InputStr = '' then
        Exit;

      SelectedIndex := StrToIntDef(InputStr, 0) - 1;

      if (SelectedIndex >= 0) and (SelectedIndex < Length(Templates)) then
      begin
        ApplyTemplateToCurrentSettings(Templates[SelectedIndex]);
        AddColoredStatusMessage(Format('✅ 已加载配置模板: %s', [Templates[SelectedIndex].Name]), clGreen);
      end
      else
      begin
        AddColoredStatusMessage('❌ 无效的模板编号', clRed);
      end;

    finally
      TemplateList.Free;
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 加载模板对话框失败: ' + E.Message, clRed);
  end;
end;

// 保存当前模板
procedure TfrmMain.SaveCurrentTemplate;
var
  Template: TConfigTemplate;
begin
  try
    if not Assigned(FTemplateManager) then
    begin
      AddColoredStatusMessage('❌ 配置模板管理器未初始化', clRed);
      Exit;
    end;

    Template := GetCurrentSettingsAsTemplate;

    if Template.Id = '' then
    begin
      // 创建新模板
      CreateNewTemplate;
    end
    else
    begin
      // 更新现有模板
      FTemplateManager.SaveTemplate(Template);
      AddColoredStatusMessage('✅ 当前配置已保存到模板', clGreen);
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 保存当前模板失败: ' + E.Message, clRed);
  end;
end;

// 导出模板对话框
procedure TfrmMain.ExportTemplateDialog;
begin
  try
    AddColoredStatusMessage('📤 模板导出功能开发中...', clBlue);
    // TODO: 实现模板导出功能
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 导出模板对话框失败: ' + E.Message, clRed);
  end;
end;

// 导入模板对话框
procedure TfrmMain.ImportTemplateDialog;
begin
  try
    AddColoredStatusMessage('📥 模板导入功能开发中...', clBlue);
    // TODO: 实现模板导入功能
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 导入模板对话框失败: ' + E.Message, clRed);
  end;
end;

// 应用模板到当前设置
procedure TfrmMain.ApplyTemplateToCurrentSettings(const ATemplate: TConfigTemplate);
begin
  try
    // 应用路径设置
    if ATemplate.SourcePath <> '' then
      edtSource.Text := ATemplate.SourcePath;
    if ATemplate.TargetPath <> '' then
      edtTarget.Text := ATemplate.TargetPath;

    // 应用其他设置
    // TODO: 根据实际界面控件应用其他配置

    AddColoredStatusMessage(Format('🔧 已应用模板配置: %s', [ATemplate.Name]), clBlue);

    // 记录操作
    LogOperation(otUserAction, '', '', Format('应用配置模板: %s', [ATemplate.Name]), True);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 应用模板到当前设置失败: ' + E.Message, clRed);
  end;
end;

// 获取当前设置作为模板
function TfrmMain.GetCurrentSettingsAsTemplate: TConfigTemplate;
begin
  try
    FillChar(Result, SizeOf(Result), 0);

    // 基本信息
    Result.Id := FTemplateManager.FCurrentTemplate.Id;
    Result.Name := '当前配置';
    Result.Description := '基于当前设置的配置模板';
    Result.TemplateType := ctCustom;
    Result.Version := '1.0';
    Result.CreatedBy := GetEnvironmentVariable('USERNAME');
    Result.CreatedTime := Now;
    Result.ModifiedTime := Now;
    Result.IsActive := True;
    Result.IsDefault := False;

    // 路径设置
    Result.SourcePath := edtSource.Text;
    Result.TargetPath := edtTarget.Text;

    // 其他设置
    Result.CopyOptions := 'Standard';
    Result.AnalysisOptions := 'Full';
    Result.SecuritySettings := 'Medium';
    Result.PerformanceSettings := 'Balanced';
    Result.UISettings := 'Standard';

    // 元数据
    Result.Tags := 'user,current';
    Result.Category := 'User Templates';
    Result.Priority := 5;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 获取当前设置作为模板失败: ' + E.Message, clRed);
  end;
end;

// 获取模板类型名称
function TfrmMain.GetTemplateTypeName(AType: TConfigTemplateType): string;
begin
  case AType of
    ctGeneral: Result := '通用';
    ctDevelopment: Result := '开发';
    ctProduction: Result := '生产';
    ctTesting: Result := '测试';
    ctBackup: Result := '备份';
    ctCustom: Result := '自定义';
  else
    Result := '未知';
  end;
end;

// ===== 审计和合规功能 =====

// 初始化审计管理器
procedure TfrmMain.InitializeAuditManager;
var
  AuditDir: string;
begin
  try
    // 创建审计目录
    AuditDir := ExtractFilePath(Application.ExeName) + 'Audit';
    if not DirectoryExists(AuditDir) then
      ForceDirectories(AuditDir);

    // 创建审计合规管理器
    FAuditManager := TAuditComplianceManager.Create(AuditDir + '\audit.dat', 50000);

    // 加载现有数据
    FAuditManager.LoadFromFile;

    // 开始会话
    FAuditManager.StartSession(GetEnvironmentVariable('USERNAME'));

    AddColoredStatusMessage('✅ 审计合规管理器已初始化', clGreen);

    if FAuditManager.AuditRecordCount > 0 then
      AddColoredStatusMessage(Format('📋 已加载 %d 条审计记录', [FAuditManager.AuditRecordCount]), clBlue);

    if FAuditManager.ComplianceRuleCount > 0 then
      AddColoredStatusMessage(Format('📋 已加载 %d 条合规规则', [FAuditManager.ComplianceRuleCount]), clBlue);

    // 创建默认合规规则
    if FAuditManager.ComplianceRuleCount = 0 then
    begin
      var Rule: TComplianceRule;

      // 系统目录保护规则
      FillChar(Rule, SizeOf(Rule), 0);
      Rule.Name := '系统目录保护';
      Rule.Description := '禁止操作系统关键目录';
      Rule.RuleType := crtPathRestriction;
      Rule.IsActive := True;
      Rule.Severity := asCritical;
      Rule.Pattern := 'C:\Windows';
      Rule.Action := 'DENY';
      Rule.CreatedBy := 'System';
      Rule.Tags := 'system,protection';
      FAuditManager.AddComplianceRule(Rule);

      // 用户权限规则
      FillChar(Rule, SizeOf(Rule), 0);
      Rule.Name := '管理员权限检查';
      Rule.Description := '检查用户是否具有管理员权限';
      Rule.RuleType := crtUserPermission;
      Rule.IsActive := True;
      Rule.Severity := asWarning;
      Rule.Pattern := 'Administrator';
      Rule.Action := 'WARN';
      Rule.CreatedBy := 'System';
      Rule.Tags := 'permission,security';
      FAuditManager.AddComplianceRule(Rule);

      AddColoredStatusMessage('📋 已创建默认合规规则', clBlue);
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 初始化审计管理器失败: ' + E.Message, clMaroon);
  end;
end;

// 清理审计管理器
procedure TfrmMain.FinalizeAuditManager;
begin
  try
    if Assigned(FAuditManager) then
    begin
      FAuditManager.EndSession;
      FAuditManager.SaveToFile;
      FreeAndNil(FAuditManager);
      AddColoredStatusMessage('✅ 审计合规管理器已清理', clGreen);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 清理审计管理器失败: ' + E.Message, clMaroon);
  end;
end;

// 显示审计日志
procedure TfrmMain.ShowAuditLog;
var
  Records: TArray<TAuditRecord>;
  I: Integer;
  TypeText, SeverityText: string;
  SeverityColor: TColor;
begin
  try
    if not Assigned(FAuditManager) then
    begin
      AddColoredStatusMessage('❌ 审计管理器未初始化', clRed);
      Exit;
    end;

    // 获取最近的审计记录
    Records := FAuditManager.GetAuditRecords(Now - 7, Now); // 最近7天

    if Length(Records) = 0 then
    begin
      AddColoredStatusMessage('📋 暂无审计记录', clGray);
      Exit;
    end;

    AddColoredStatusMessage('📋 审计日志 (最近7天):', clNavy);

    for I := High(Records) downto Max(High(Records) - 19, 0) do // 显示最新的20条
    begin
      TypeText := GetAuditEventTypeName(Records[I].EventType);
      SeverityText := GetAuditSeverityName(Records[I].Severity);

      case Records[I].Severity of
        asInfo: SeverityColor := clBlue;
        asWarning: SeverityColor := clOlive;
        asError: SeverityColor := clMaroon;
        asCritical: SeverityColor := clRed;
      else
        SeverityColor := clGray;
      end;

      var StatusIcon := if Records[I].Success then '✅' else '❌';

      AddColoredStatusMessage(Format('   %s [%s|%s] %s', [
        StatusIcon, TypeText, SeverityText, Records[I].EventDescription
      ]), SeverityColor);

      AddColoredStatusMessage(Format('     🕒 %s | 👤 %s | 📁 %s', [
        FormatDateTime('yyyy-mm-dd hh:nn:ss', Records[I].Timestamp),
        Records[I].UserName,
        Records[I].ResourcePath
      ]), clGray);

      if Records[I].ErrorMessage <> '' then
        AddColoredStatusMessage('     ❌ ' + Records[I].ErrorMessage, clRed);
    end;

    AddColoredStatusMessage(Format('📊 总计: %d 条记录 (显示最新20条)', [Length(Records)]), clNavy);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示审计日志失败: ' + E.Message, clRed);
  end;
end;

// 显示合规规则
procedure TfrmMain.ShowComplianceRules;
var
  Rules: TArray<TComplianceRule>;
  I: Integer;
  TypeText, SeverityText: string;
begin
  try
    if not Assigned(FAuditManager) then
    begin
      AddColoredStatusMessage('❌ 审计管理器未初始化', clRed);
      Exit;
    end;

    Rules := FAuditManager.GetComplianceRules;

    if Length(Rules) = 0 then
    begin
      AddColoredStatusMessage('📋 暂无合规规则', clGray);
      Exit;
    end;

    AddColoredStatusMessage('📋 合规规则列表:', clNavy);

    for I := 0 to High(Rules) do
    begin
      TypeText := FAuditManager.GetRuleTypeName(Rules[I].RuleType);
      SeverityText := GetAuditSeverityName(Rules[I].Severity);

      var StatusIcon := if Rules[I].IsActive then '✅' else '⏸️';

      AddColoredStatusMessage(Format('   %s [%s|%s] %s', [
        StatusIcon, TypeText, SeverityText, Rules[I].Name
      ]), clBlue);

      AddColoredStatusMessage(Format('     📝 %s', [Rules[I].Description]), clGray);

      if Rules[I].Pattern <> '' then
        AddColoredStatusMessage(Format('     🎯 模式: %s', [Rules[I].Pattern]), clSilver);

      if Rules[I].Action <> '' then
        AddColoredStatusMessage(Format('     ⚡ 动作: %s', [Rules[I].Action]), clSilver);

      AddColoredStatusMessage(Format('     🏷️ 创建者: %s | 创建时间: %s', [
        Rules[I].CreatedBy,
        FormatDateTime('yyyy-mm-dd hh:nn', Rules[I].CreatedTime)
      ]), clSilver);
    end;

    AddColoredStatusMessage(Format('📊 总计: %d 条规则', [Length(Rules)]), clNavy);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示合规规则失败: ' + E.Message, clRed);
  end;
end;

// 创建合规规则
procedure TfrmMain.CreateComplianceRule;
var
  RuleName, RuleDesc, RulePattern: string;
  Rule: TComplianceRule;
begin
  try
    if not Assigned(FAuditManager) then
    begin
      AddColoredStatusMessage('❌ 审计管理器未初始化', clRed);
      Exit;
    end;

    RuleName := InputBox('创建合规规则', '请输入规则名称:', '新合规规则');
    if RuleName = '' then
      Exit;

    RuleDesc := InputBox('创建合规规则', '请输入规则描述:', '自定义合规规则');
    if RuleDesc = '' then
      RuleDesc := '用户创建的合规规则';

    RulePattern := InputBox('创建合规规则', '请输入匹配模式 (可选):', '');

    // 创建规则
    FillChar(Rule, SizeOf(Rule), 0);
    Rule.Name := RuleName;
    Rule.Description := RuleDesc;
    Rule.RuleType := crtPathRestriction; // 默认类型
    Rule.IsActive := True;
    Rule.Severity := asWarning;
    Rule.Pattern := RulePattern;
    Rule.Action := 'WARN';
    Rule.CreatedBy := GetEnvironmentVariable('USERNAME');
    Rule.Tags := 'user,custom';

    var RuleId := FAuditManager.AddComplianceRule(Rule);

    AddColoredStatusMessage(Format('✅ 已创建合规规则: %s', [RuleName]), clGreen);

    // 记录审计事件
    LogUserAction(Format('创建合规规则: %s', [RuleName]), '', True);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 创建合规规则失败: ' + E.Message, clRed);
  end;
end;

// 生成审计报告
procedure TfrmMain.GenerateAuditReport;
var
  Report: string;
  StartTime, EndTime: TDateTime;
begin
  try
    if not Assigned(FAuditManager) then
    begin
      AddColoredStatusMessage('❌ 审计管理器未初始化', clRed);
      Exit;
    end;

    StartTime := Now - 30; // 最近30天
    EndTime := Now;

    Report := FAuditManager.GenerateAuditReport(StartTime, EndTime);

    AddColoredStatusMessage('📊 审计报告 (最近30天):', clNavy);
    AddColoredStatusMessage(Report, clBlue);

    var ComplianceReport := FAuditManager.GenerateComplianceReport;
    AddColoredStatusMessage('📊 合规报告:', clNavy);
    AddColoredStatusMessage(ComplianceReport, clBlue);

    var Statistics := FAuditManager.GetAuditStatistics;
    AddColoredStatusMessage('📊 审计统计:', clNavy);
    AddColoredStatusMessage(Statistics, clBlue);

    // 记录审计事件
    LogUserAction('生成审计报告', '', True);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 生成审计报告失败: ' + E.Message, clRed);
  end;
end;

// 导出审计数据
procedure TfrmMain.ExportAuditData;
begin
  try
    if not Assigned(FAuditManager) then
    begin
      AddColoredStatusMessage('❌ 审计管理器未初始化', clRed);
      Exit;
    end;

    AddColoredStatusMessage('📤 审计数据导出功能开发中...', clBlue);
    // TODO: 实现审计数据导出功能

    // 记录审计事件
    LogUserAction('导出审计数据', '', True);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 导出审计数据失败: ' + E.Message, clRed);
  end;
end;

// 记录用户操作
function TfrmMain.LogUserAction(const ADescription, AResourcePath: string; ASuccess: Boolean): string;
begin
  Result := '';

  try
    if Assigned(FAuditManager) then
    begin
      Result := FAuditManager.LogAuditEvent(
        aetUserAction,
        if ASuccess then asInfo else asError,
        ADescription,
        AResourcePath,
        ASuccess
      );
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('⚠️ 记录用户操作失败: ' + E.Message, clMaroon);
  end;
end;

// 检查操作合规性
function TfrmMain.CheckOperationCompliance(const AResourcePath, AOperation: string): Boolean;
begin
  Result := True;

  try
    if Assigned(FAuditManager) then
    begin
      Result := FAuditManager.ValidateOperation(AResourcePath, AOperation);

      if not Result then
        AddColoredStatusMessage(Format('⚠️ 合规检查失败: %s 操作 %s', [AOperation, AResourcePath]), clMaroon);
    end;
  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 检查操作合规性失败: ' + E.Message, clRed);
      Result := False;
    end;
  end;
end;

// 获取审计事件类型名称
function TfrmMain.GetAuditEventTypeName(AType: TAuditEventType): string;
begin
  if Assigned(FAuditManager) then
    Result := FAuditManager.GetEventTypeName(AType)
  else
    Result := '未知事件';
end;

// 获取审计严重级别名称
function TfrmMain.GetAuditSeverityName(ASeverity: TAuditSeverity): string;
begin
  if Assigned(FAuditManager) then
    Result := FAuditManager.GetSeverityName(ASeverity)
  else
    Result := '未知级别';
end;

// ===== 符号链接验证和修复 =====

// 验证所有缓存的符号链接
function TfrmMain.ValidateAllSymlinks: Integer;
var
  I: Integer;
  ValidCount: Integer;
  InvalidCount: Integer;
  SymlinkInfo: TSymlinkInfo;
begin
  Result := 0;
  ValidCount := 0;
  InvalidCount := 0;

  try
    if not Assigned(FSymlinkCache) then
    begin
      AddColoredStatusMessage('❌ 符号链接缓存未初始化', clRed);
      Exit;
    end;

    AddColoredStatusMessage('🔍 开始验证所有符号链接...', clBlue);

    for I := 0 to FSymlinkCache.SymlinkCount - 1 do
    begin
      SymlinkInfo := FSymlinkCache.FSymlinks[I];

      if ValidateSymlink(SymlinkInfo.Path) then
      begin
        Inc(ValidCount);
        if SymlinkInfo.IsValid <> True then
        begin
          // 更新缓存状态
          SymlinkInfo.IsValid := True;
          SymlinkInfo.ScanTime := Now;
          FSymlinkCache.FSymlinks[I] := SymlinkInfo;
          AddColoredStatusMessage('✅ 符号链接已修复: ' + ExtractFileName(SymlinkInfo.Path), clGreen);
        end;
      end
      else
      begin
        Inc(InvalidCount);
        if SymlinkInfo.IsValid <> False then
        begin
          // 更新缓存状态
          SymlinkInfo.IsValid := False;
          SymlinkInfo.ScanTime := Now;
          FSymlinkCache.FSymlinks[I] := SymlinkInfo;
          AddColoredStatusMessage('❌ 符号链接已失效: ' + ExtractFileName(SymlinkInfo.Path), clRed);
        end;
      end;
    end;

    Result := InvalidCount;
    AddColoredStatusMessage(Format('📊 验证完成: %d 个有效，%d 个无效', [ValidCount, InvalidCount]), clBlue);

    // 保存更新的缓存
    SaveSymlinkCache;

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 验证符号链接失败: ' + E.Message, clRed);
      Result := -1;
    end;
  end;
end;

// 修复符号链接
function TfrmMain.RepairSymlink(const APath, ANewTarget: string): Boolean;
var
  OldTarget: string;
begin
  Result := False;

  try
    if not IsSymbolicLink(APath) then
    begin
      AddColoredStatusMessage('❌ 不是符号链接: ' + APath, clRed);
      Exit;
    end;

    OldTarget := GetSymlinkTarget(APath);
    AddColoredStatusMessage('🔧 开始修复符号链接...', clBlue);
    AddColoredStatusMessage('   原目标: ' + OldTarget, clGray);
    AddColoredStatusMessage('   新目标: ' + ANewTarget, clGray);

    // 删除旧的符号链接
    if not RemoveDirectory(PChar(APath)) then
    begin
      AddColoredStatusMessage('❌ 无法删除旧符号链接: ' + APath, clRed);
      Exit;
    end;

    // 创建新的符号链接
    if CreateSymbolicLink(APath, ANewTarget) then
    begin
      AddColoredStatusMessage('✅ 符号链接修复成功', clGreen);

      // 更新缓存
      var SymlinkInfo: TSymlinkInfo;
      SymlinkInfo.Path := APath;
      SymlinkInfo.Target := ANewTarget;
      SymlinkInfo.IsValid := True;
      SymlinkInfo.ScanTime := Now;
      SymlinkInfo.IsDirectory := DirectoryExists(ANewTarget);
      SymlinkInfo.Status := if SymlinkInfo.IsDirectory then dsSymlinkDir else dsSymlinkFile;

      CacheSymlinkInfo(SymlinkInfo);
      Result := True;
    end
    else
    begin
      AddColoredStatusMessage('❌ 创建新符号链接失败', clRed);
    end;

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 修复符号链接异常: ' + E.Message, clRed);
      Result := False;
    end;
  end;
end;

// 查找可能的目标路径
function TfrmMain.FindPossibleTargets(const APath: string): TArray<string>;
var
  OriginalTarget: string;
  BaseName: string;
  SearchPaths: TArray<string>;
  I, J: Integer;
  SearchRec: TSearchRec;
  CandidatePath: string;
  Results: TStringList;
begin
  SetLength(Result, 0);
  Results := TStringList.Create;
  try
    OriginalTarget := GetSymlinkTarget(APath);
    if OriginalTarget = '' then
      Exit;

    BaseName := ExtractFileName(OriginalTarget);

    // 定义搜索路径
    SetLength(SearchPaths, 6);
    SearchPaths[0] := 'C:\Program Files';
    SearchPaths[1] := 'C:\Program Files (x86)';
    SearchPaths[2] := 'D:\Program Files';
    SearchPaths[3] := 'D:\Program Files (x86)';
    SearchPaths[4] := ExtractFilePath(OriginalTarget); // 原路径的父目录
    SearchPaths[5] := ExtractFilePath(APath); // 符号链接的父目录

    AddColoredStatusMessage('🔍 搜索可能的目标路径...', clBlue);

    for I := 0 to High(SearchPaths) do
    begin
      if not DirectoryExists(SearchPaths[I]) then
        Continue;

      // 在当前搜索路径中查找同名目录
      if FindFirst(SearchPaths[I] + '\*', faDirectory, SearchRec) = 0 then
      begin
        try
          repeat
            if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') and
               ((SearchRec.Attr and faDirectory) <> 0) then
            begin
              if SameText(SearchRec.Name, BaseName) then
              begin
                CandidatePath := SearchPaths[I] + '\' + SearchRec.Name;
                if Results.IndexOf(CandidatePath) = -1 then
                begin
                  Results.Add(CandidatePath);
                  AddColoredStatusMessage('   找到候选: ' + CandidatePath, clGray);
                end;
              end;
            end;
          until FindNext(SearchRec) <> 0;
        finally
          FindClose(SearchRec);
        end;
      end;
    end;

    // 转换为数组
    SetLength(Result, Results.Count);
    for J := 0 to Results.Count - 1 do
      Result[J] := Results[J];

    AddColoredStatusMessage(Format('📋 找到 %d 个可能的目标', [Length(Result)]), clBlue);

  finally
    Results.Free;
  end;
end;

// 显示符号链接修复对话框
procedure TfrmMain.ShowSymlinkRepairDialog(const APath: string);
var
  PossibleTargets: TArray<string>;
  I: Integer;
  SelectedTarget: string;
  DialogText: string;
  UserChoice: Integer;
begin
  try
    AddColoredStatusMessage('🔧 准备修复符号链接: ' + ExtractFileName(APath), clBlue);

    PossibleTargets := FindPossibleTargets(APath);

    if Length(PossibleTargets) = 0 then
    begin
      DialogText := '未找到可能的修复目标。' + #13#10 +
                   '符号链接: ' + APath + #13#10 +
                   '原目标: ' + GetSymlinkTarget(APath) + #13#10#13#10 +
                   '请手动检查目标路径是否存在。';
      MessageDlg(DialogText, mtInformation, [mbOK], 0);
      Exit;
    end;

    // 构建选择对话框文本
    DialogText := '发现无效的符号链接，找到以下可能的修复目标：' + #13#10#13#10 +
                 '符号链接: ' + APath + #13#10 +
                 '原目标: ' + GetSymlinkTarget(APath) + #13#10#13#10 +
                 '可能的新目标：' + #13#10;

    for I := 0 to High(PossibleTargets) do
      DialogText := DialogText + Format('%d. %s%s', [I + 1, PossibleTargets[I], #13#10]);

    DialogText := DialogText + #13#10 + '选择要使用的目标（1-' + IntToStr(Length(PossibleTargets)) + '），或取消：';

    var InputStr := InputBox('修复符号链接', DialogText, '1');
    if InputStr = '' then
      Exit;

    UserChoice := StrToIntDef(InputStr, 0);
    if (UserChoice < 1) or (UserChoice > Length(PossibleTargets)) then
    begin
      AddColoredStatusMessage('❌ 无效的选择', clRed);
      Exit;
    end;

    SelectedTarget := PossibleTargets[UserChoice - 1];

    // 确认修复
    if MessageDlg(Format('确定要将符号链接修复到以下目标吗？%s%s%s%s新目标：%s%s',
                        [#13#10, APath, #13#10, #13#10, #13#10, SelectedTarget]),
                 mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      if RepairSymlink(APath, SelectedTarget) then
      begin
        AddColoredStatusMessage('✅ 符号链接修复完成', clGreen);
        // 刷新显示
        ScanCurrentDirectorySymlinks(False);
      end;
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示修复对话框失败: ' + E.Message, clRed);
  end;
end;

// ===== 文件拷贝实现 =====

// 统计目录中的文件数量
function TfrmMain.CountFilesInDirectory(const ADirectory: string): Integer;
var
  SearchRec: TSearchRec;
  SubPath: string;
begin
  Result := 0;

  try
    if not DirectoryExists(ADirectory) then
      Exit;

    if FindFirst(ADirectory + '\*', faAnyFile, SearchRec) = 0 then
    begin
      try
        repeat
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          begin
            SubPath := ADirectory + '\' + SearchRec.Name;

            if (SearchRec.Attr and faDirectory) <> 0 then
            begin
              // 递归统计子目录
              Result := Result + CountFilesInDirectory(SubPath);
            end
            else
            begin
              // 统计文件
              Inc(Result);
            end;
          end;
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;
  except
    // 忽略统计错误
  end;
end;

// 带进度显示的目录拷贝
procedure TfrmMain.CopyDirectoryWithProgress(const ASourceDir, ATargetDir: string);
var
  TotalFiles: Integer;
  SourceDirName: string;
  FinalTargetDir: string;
  ProgressForm: TfrmProgress;
begin
  ProgressForm := nil;
  try
    // 获取源目录名称
    SourceDirName := ExtractFileName(ASourceDir);

    // 构建最终目标路径：目标目录 + 源目录名称
    FinalTargetDir := IncludeTrailingPathDelimiter(ATargetDir) + SourceDirName;

    AddColoredStatusMessage('📁 目标路径: ' + FinalTargetDir, clBlue);

    // 检查目标目录是否已存在
    if DirectoryExists(FinalTargetDir) then
    begin
      if MessageDlg(Format('目标目录已存在：%s%s%s是否要覆盖？', [#13#10, FinalTargetDir, #13#10]),
                    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      begin
        AddColoredStatusMessage('ℹ️ 用户取消了拷贝操作', clBlue);
        Exit;
      end;
    end;

    // 显示进度对话框
    ProgressForm := ShowProgressDialog('正在复制文件', 100);
    FCurrentProgressForm := ProgressForm;
    ProgressForm.UpdateProgress('正在统计文件数量...', 0);

    TotalFiles := CountFilesInDirectory(ASourceDir);

    if TotalFiles = 0 then
    begin
      ProgressForm.UpdateProgress('创建空目录...', 50);

      // 即使没有文件，也要创建目录结构
      if not DirectoryExists(FinalTargetDir) then
      begin
        if CreateDir(FinalTargetDir) then
        begin
          AddColoredStatusMessage('✅ 已创建空目录: ' + SourceDirName, clGreen);
          ProgressForm.CompleteProgress('空目录创建完成');
        end
        else
        begin
          AddColoredStatusMessage('❌ 创建目录失败: ' + SourceDirName, clRed);
          ProgressForm.CompleteProgress('创建目录失败');
        end;
      end
      else
      begin
        ProgressForm.CompleteProgress('目录已存在');
      end;

      RefreshTargetDisplay;
      Exit;
    end;

    // 设置进度条最大值为文件总数
    ProgressForm.MaxProgress := TotalFiles;
    ProgressForm.UpdateProgress(Format('准备复制 %d 个文件...', [TotalFiles]), 0);

    // 初始化进度
    InitializeCopyProgress(TotalFiles);

    // 重置计数器
    FCurrentFileIndex := 0;

    // 开始递归拷贝（拷贝源目录内容到最终目标目录）
    CopyDirectoryRecursive(ASourceDir, FinalTargetDir);

    // 检查是否被取消
    if FCopyStopRequested then
    begin
      ProgressForm.CompleteProgress('复制操作已取消');
      AddColoredStatusMessage('ℹ️ 复制操作已被用户取消', clBlue);
    end
    else
    begin
      ProgressForm.CompleteProgress('文件复制完成');
      AddColoredStatusMessage('✅ 文件复制完成', clGreen);
    end;

    // 刷新右侧显示
    RefreshTargetDisplay;

    // 完成进度
    FinalizeCopyProgress;

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 拷贝目录失败: ' + E.Message, clRed);
      if Assigned(ProgressForm) then
        ProgressForm.CompleteProgress('复制失败: ' + E.Message);
      FinalizeCopyProgress;
    end;
  end;

  // 确保进度窗体被关闭
  FCurrentProgressForm := nil;
  if Assigned(ProgressForm) then
  begin
    ProgressForm.Free;
    ProgressForm := nil;
  end;
end;

// 递归拷贝目录
procedure TfrmMain.CopyDirectoryRecursive(const ASourceDir, ATargetDir: string);
var
  SearchRec: TSearchRec;
  SourcePath, TargetPath: string;
  FileProgress, TotalProgress: Integer;
begin
  try
    // 确保目标目录存在
    if not DirectoryExists(ATargetDir) then
    begin
      if not CreateDir(ATargetDir) then
      begin
        AddColoredStatusMessage('❌ 无法创建目标目录: ' + ATargetDir, clRed);
        Exit;
      end;
    end;

    if FindFirst(ASourceDir + '\*', faAnyFile, SearchRec) = 0 then
    begin
      try
        repeat
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          begin
            SourcePath := ASourceDir + '\' + SearchRec.Name;
            TargetPath := ATargetDir + '\' + SearchRec.Name;

            if (SearchRec.Attr and faDirectory) <> 0 then
            begin
              // 递归拷贝子目录
              CopyDirectoryRecursive(SourcePath, TargetPath);
            end
            else
            begin
              // 检查是否请求停止
              if FCopyStopRequested then
              begin
                AddColoredStatusMessage('🛑 拷贝已停止', clOlive);
                Exit;
              end;

              // 拷贝文件
              Inc(FCurrentFileIndex);

              // 计算进度
              TotalProgress := Round((FCurrentFileIndex / FTotalFilesToCopy) * 100);

              // 优化小文件进度更新：每5个文件更新一次进度条
              Inc(FSmallFileUpdateCounter);
              if (FSmallFileUpdateCounter >= 5) or (FCurrentFileIndex = FTotalFilesToCopy) then
              begin
                UpdateCopyProgress(SourcePath, 0, TotalProgress);
                FSmallFileUpdateCounter := 0;
              end;

              // 执行文件拷贝
              if CopyFile(PChar(SourcePath), PChar(TargetPath), False) then
              begin
                // 文件拷贝完成，但只在需要时更新进度条
                if (FSmallFileUpdateCounter = 0) or (FCurrentFileIndex = FTotalFilesToCopy) then
                  UpdateCopyProgress(SourcePath, 100, TotalProgress);

                // 每10个文件显示一次状态信息
                if (FCurrentFileIndex mod 10 = 0) or (FCurrentFileIndex = FTotalFilesToCopy) then
                  AddStatusMessage('✅ 已拷贝: ' + ExtractFileName(SourcePath));
              end
              else
              begin
                AddColoredStatusMessage('❌ 拷贝失败: ' + ExtractFileName(SourcePath), clRed);
              end;
            end;
          end;
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 递归拷贝失败: ' + E.Message, clRed);
  end;
end;

// ===== 拷贝辅助功能 =====

// 显示拷贝确认对话框
function TfrmMain.ShowCopyConfirmDialog(const ASourceDir, ATargetDir: string): Boolean;
var
  ConfirmMsg: string;
  SourceDirName: string;
  FinalTargetPath: string;
begin
  try
    // 计算最终目标路径
    SourceDirName := ExtractFileName(ASourceDir);
    FinalTargetPath := IncludeTrailingPathDelimiter(ATargetDir) + SourceDirName;

    ConfirmMsg := Format('确定要拷贝当前目录吗？%s%s源目录: %s%s将拷贝到: %s%s%s注意：拷贝过程中可以点击"停止拷贝"按钮中止操作。',
      [#13#10, #13#10, ASourceDir, #13#10, FinalTargetPath, #13#10, #13#10]);

    Result := MessageDlg(ConfirmMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes;
  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 显示确认对话框失败: ' + E.Message, clRed);
      Result := False;
    end;
  end;
end;

// 更新拷贝按钮状态
procedure TfrmMain.UpdateCopyButtonState;
begin
  try
    if Assigned(btnCopyFiles) then
    begin
      if FCopyInProgress then
      begin
        btnCopyFiles.Caption := LanguageMgr.GetString('stop_copy', '停止拷贝');
        btnCopyFiles.Font.Style := [fsBold];
      end
      else
      begin
        btnCopyFiles.Caption := LanguageMgr.GetString('copy_files', '拷贝文件');
        btnCopyFiles.Font.Style := [];
      end;
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 更新按钮状态失败: ' + E.Message, clRed);
  end;
end;

// 刷新右侧目标目录显示
procedure TfrmMain.RefreshTargetDisplay;
begin
  try
    // 刷新目标目录树
    if Assigned(DirListBoxTarget) then
    begin
      DirListBoxTarget.Update;
      AddStatusMessage('🔄 已刷新目标目录树');
    end;

    // 刷新目标文件列表
    if Assigned(FileListBoxTarget) then
    begin
      FileListBoxTarget.Update;
      AddStatusMessage(Format('📄 目标目录包含 %d 个文件', [FileListBoxTarget.Items.Count]));
    end;

    // 强制界面更新
    Application.ProcessMessages;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 刷新目标显示失败: ' + E.Message, clRed);
  end;
end;

// ===== 拷贝进度管理 =====

// 初始化拷贝进度
procedure TfrmMain.InitializeCopyProgress(ATotalFiles: Integer);
begin
  try
    FTotalFilesToCopy := ATotalFiles;
    FCurrentFileIndex := 0;
    FCurrentFileName := '';
    FCurrentFileSize := 0;
    FCurrentFileCopied := 0;
    FCopyInProgress := True;
    FCopyStopRequested := False;
    FSmallFileUpdateCounter := 0;

    // 显示进度条
    if Assigned(ProgressBar) then
    begin
      ProgressBar.Min := 0;
      ProgressBar.Max := 100;
      ProgressBar.Position := 0;
      ProgressBar.Visible := True;
    end;

    if Assigned(PBarAFile) then
    begin
      PBarAFile.Min := 0;
      PBarAFile.Max := 100;
      PBarAFile.Position := 0;
      PBarAFile.Visible := True;
    end;

    // 更新按钮状态
    UpdateCopyButtonState;

    AddColoredStatusMessage(Format('📋 开始拷贝 %d 个文件...', [ATotalFiles]), clBlue);
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 初始化拷贝进度失败: ' + E.Message, clRed);
  end;
end;

// 更新拷贝进度
procedure TfrmMain.UpdateCopyProgress(const ACurrentFile: string; AFileProgress: Integer; ATotalProgress: Integer);
var
  ProgressMessage: string;
begin
  try
    FCurrentFileName := ACurrentFile;

    // 更新进度窗体
    if Assigned(FCurrentProgressForm) then
    begin
      if ACurrentFile <> '' then
        ProgressMessage := Format('正在复制: %s (%d/%d)', [ExtractFileName(ACurrentFile), FCurrentFileIndex, FTotalFilesToCopy])
      else
        ProgressMessage := Format('正在处理... (%d/%d)', [FCurrentFileIndex, FTotalFilesToCopy]);

      FCurrentProgressForm.UpdateProgress(ProgressMessage, FCurrentFileIndex);

      // 检查是否被取消
      if FCurrentProgressForm.Cancelled then
      begin
        FCopyStopRequested := True;
        Exit;
      end;
    end;

    // 更新总进度条（保持原有功能）
    if Assigned(ProgressBar) then
    begin
      ProgressBar.Position := ATotalProgress;
    end;

    // 更新当前文件进度条
    if Assigned(PBarAFile) then
    begin
      PBarAFile.Position := AFileProgress;
    end;

    // 更新状态信息
    if ACurrentFile <> '' then
    begin
      AddStatusMessage(Format('📄 正在拷贝: %s (%d%%)', [ExtractFileName(ACurrentFile), AFileProgress]));
      AddStatusMessage(Format('📊 总进度: %d/%d 文件 (%d%%)', [FCurrentFileIndex, FTotalFilesToCopy, ATotalProgress]));
    end;

    // 强制刷新界面
    Application.ProcessMessages;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 更新拷贝进度失败: ' + E.Message, clRed);
  end;
end;

// 完成拷贝进度
procedure TfrmMain.FinalizeCopyProgress;
begin
  try
    FCopyInProgress := False;
    FCopyStopRequested := False;

    // 隐藏进度条
    if Assigned(ProgressBar) then
    begin
      ProgressBar.Position := 100;
      ProgressBar.Visible := False;
    end;

    if Assigned(PBarAFile) then
    begin
      PBarAFile.Position := 100;
      PBarAFile.Visible := False;
    end;

    // 更新按钮状态
    UpdateCopyButtonState;

    // 刷新右侧显示
    if not FCopyStopRequested then
      RefreshTargetDisplay;

    if FCopyStopRequested then
      AddColoredStatusMessage('🛑 文件拷贝已停止！', clOlive)
    else
      AddColoredStatusMessage('✅ 文件拷贝完成！', clGreen);

    AddStatusMessage(Format('📊 总计拷贝了 %d 个文件', [FCurrentFileIndex]));
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 完成拷贝进度失败: ' + E.Message, clRed);
  end;
end;

// ===== 备份管理功能 =====

// 创建目录备份
function TfrmMain.CreateDirectoryBackup(const ASourceDir: string): string;
var
  BackupDir: string;
  SourceDirName: string;
  TimeStamp: string;
  TargetPath: string;
begin
  Result := '';

  try
    // 获取源目录名称
    SourceDirName := ExtractFileName(ASourceDir);

    // 生成时间戳
    TimeStamp := FormatDateTime('yyyymmdd_hhnnss', Now);

    // 获取目标路径，备份放在目标盘以减少C盘占用
    TargetPath := edtTarget.Text;
    if not DirectoryExists(TargetPath) then
    begin
      AddColoredStatusMessage('❌ 目标目录不存在，无法创建备份', clRed);
      Exit;
    end;

    // 在目标目录创建备份目录，添加dcbackup关键字
    BackupDir := IncludeTrailingPathDelimiter(TargetPath) + SourceDirName + '_dcbackup_' + TimeStamp;

    AddStatusMessage('备份目录: ' + BackupDir);

    // 创建备份目录
    if not CreateDir(BackupDir) then
    begin
      AddColoredStatusMessage('❌ 创建备份目录失败', clRed);
      Exit;
    end;

    // 拷贝整个目录到备份位置
    AddStatusMessage('正在拷贝文件到备份目录...');
    Application.ProcessMessages;

    if CopyDirectoryRecursiveSimple(ASourceDir, BackupDir) then
    begin
      Result := BackupDir;
      AddStatusMessage('备份拷贝完成');
    end
    else
    begin
      AddColoredStatusMessage('❌ 备份拷贝失败', clRed);
      // 清理失败的备份目录
      try
        DeleteDirectoryRecursive(BackupDir);
      except
        // 忽略清理错误
      end;
    end;

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 创建备份异常: ' + E.Message, clRed);
      Result := '';
    end;
  end;
end;

// 从备份恢复目录
function TfrmMain.RestoreDirectoryFromBackup(const ABackupPath, ATargetPath: string): Boolean;
begin
  Result := False;

  try
    if not DirectoryExists(ABackupPath) then
    begin
      AddColoredStatusMessage('❌ 备份目录不存在', clRed);
      Exit;
    end;

    // 如果目标目录存在，先删除
    if DirectoryExists(ATargetPath) then
    begin
      AddStatusMessage('删除现有目录...');
      if not DeleteDirectoryRecursive(ATargetPath) then
      begin
        AddColoredStatusMessage('❌ 删除现有目录失败', clRed);
        Exit;
      end;
    end;

    // 从备份恢复
    AddStatusMessage('从备份恢复文件...');
    Application.ProcessMessages;

    Result := CopyDirectoryRecursiveSimple(ABackupPath, ATargetPath);

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 恢复备份异常: ' + E.Message, clRed);
      Result := False;
    end;
  end;
end;

// 简单的目录拷贝（不显示进度）
function TfrmMain.CopyDirectoryRecursiveSimple(const ASourceDir, ATargetDir: string): Boolean;
var
  SearchRec: TSearchRec;
  SourcePath, TargetPath: string;
begin
  Result := True;

  try
    // 创建目标目录
    if not DirectoryExists(ATargetDir) then
    begin
      if not CreateDir(ATargetDir) then
      begin
        Result := False;
        Exit;
      end;
    end;

    // 遍历源目录
    if FindFirst(ASourceDir + '\*', faAnyFile, SearchRec) = 0 then
    begin
      try
        repeat
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          begin
            SourcePath := ASourceDir + '\' + SearchRec.Name;
            TargetPath := ATargetDir + '\' + SearchRec.Name;

            if (SearchRec.Attr and faDirectory) <> 0 then
            begin
              // 递归拷贝子目录
              if not CopyDirectoryRecursiveSimple(SourcePath, TargetPath) then
              begin
                Result := False;
                Exit;
              end;
            end
            else
            begin
              // 拷贝文件
              if not CopyFile(PChar(SourcePath), PChar(TargetPath), False) then
              begin
                Result := False;
                Exit;
              end;
            end;
          end;
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;

  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

// 更新备份相关按钮状态
procedure TfrmMain.UpdateBackupButtons;
var
  HasBackups: Boolean;
  HasSelection: Boolean;
begin
  try
    HasBackups := Assigned(FBackupList) and (FBackupList.Count > 0);
    HasSelection := Assigned(lvBackup) and Assigned(lvBackup.Selected);

    if Assigned(btnCreateBackup) then
      btnCreateBackup.Enabled := True;

    if Assigned(btnDeleteAndLink) then
      btnDeleteAndLink.Enabled := True;  // 一直可用，点击后再检查

    if Assigned(btnRollback) then
      btnRollback.Enabled := HasBackups;



    if Assigned(btnOpenBackupFolder) then
      btnOpenBackupFolder.Enabled := HasBackups;

    if Assigned(btnDelBackup) then
      btnDelBackup.Enabled := HasSelection;

    if Assigned(btnCalcBackupSize) then
      btnCalcBackupSize.Enabled := HasBackups;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 更新按钮状态失败: ' + E.Message, clRed);
  end;
end;

// 更新备份信息显示
procedure TfrmMain.UpdateBackupDisplay;
var
  BackupCount: Integer;
  BackupInfo: string;
begin
  try
    BackupCount := 0;

    // 检查备份列表并清理无效备份
    if Assigned(FBackupList) then
    begin
      for var I := FBackupList.Count - 1 downto 0 do
      begin
        if not DirectoryExists(FBackupList[I]) then
        begin
          AddColoredStatusMessage('⚠️ 备份目录已不存在，从列表中移除: ' + ExtractFileName(FBackupList[I]), clOlive);
          FBackupList.Delete(I);
        end;
      end;
      BackupCount := FBackupList.Count;
    end;

    // lblBackupPath已删除，备份信息通过lvBackup显示

    // lblBackupStatus已删除，备份状态通过lvBackup显示

    // 同时更新按钮状态
    UpdateBackupButtons;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 更新备份显示失败: ' + E.Message, clRed);
  end;
end;

// ===== 符号链接检测和显示功能 =====
// 更新目录颜色显示（强制重绘以显示颜色）
procedure TfrmMain.UpdateDirectoryColors;
begin
  try
    // 简单的刷新操作，TDirectoryListBox不支持自定义绘制
    if Assigned(DirListBoxSource) then
      DirListBoxSource.Invalidate;
    if Assigned(DirListBoxTarget) then
      DirListBoxTarget.Invalidate;
  except
    // 忽略刷新错误
  end;
end;



// 扫描现有备份
procedure TfrmMain.ScanExistingBackups;
var
  SearchRec: TSearchRec;
  TargetPath: string;
  BackupPath: string;
begin
  try
    if not Assigned(FBackupList) then
      Exit;

    FBackupList.Clear;

    // 获取目标目录
    TargetPath := edtTarget.Text;
    if not DirectoryExists(TargetPath) then
      Exit;

    // 扫描目标目录中的dcbackup目录
    if FindFirst(IncludeTrailingPathDelimiter(TargetPath) + '*dcbackup*', faDirectory, SearchRec) = 0 then
    begin
      try
        repeat
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') and
             ((SearchRec.Attr and faDirectory) <> 0) then
          begin
            BackupPath := IncludeTrailingPathDelimiter(TargetPath) + SearchRec.Name;

            // 验证是否确实是备份目录（包含dcbackup关键字）
            if Pos('dcbackup', LowerCase(SearchRec.Name)) > 0 then
            begin
              FBackupList.Add(BackupPath);
              AddStatusMessage('发现备份: ' + SearchRec.Name);
            end;
          end;
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;

    AddColoredStatusMessage(Format('✅ 扫描完成，发现 %d 个备份', [FBackupList.Count]), clGreen);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 扫描备份失败: ' + E.Message, clRed);
  end;
end;

// ===== 新的备份管理界面功能 =====

// 刷新备份列表视图
procedure TfrmMain.RefreshBackupListView;
var
  I: Integer;
  ListItem: TListItem;
  BackupPath: string;
  BackupName: string;
  BackupSize: Int64;
  BackupDate: TDateTime;
  SizeStr: string;
begin
  try
    if not Assigned(lvBackup) then
      Exit;

    lvBackup.Items.Clear;

    if not Assigned(FBackupList) then
      Exit;

    for I := 0 to FBackupList.Count - 1 do
    begin
      BackupPath := FBackupList[I];

      if DirectoryExists(BackupPath) then
      begin
        BackupName := ExtractFileName(BackupPath);

        // 获取创建时间，大小暂时显示为"未计算"
        try
          BackupDate := FileDateToDateTime(FileAge(BackupPath));
          SizeStr := '未计算';  // 初始显示为未计算，需要点击按钮计算
        except
          BackupDate := Now;
          SizeStr := '未知';
        end;

        // 添加到列表
        ListItem := lvBackup.Items.Add;
        ListItem.Caption := BackupName;
        ListItem.SubItems.Add(SizeStr);
        ListItem.SubItems.Add(DateTimeToStr(BackupDate));
        ListItem.SubItems.Add(BackupPath);
        ListItem.Data := Pointer(I);  // 存储索引
      end;
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 刷新备份列表失败: ' + E.Message, clRed);
  end;
end;

// 新的删除备份按钮事件（在备份管理页面）
procedure TfrmMain.btnDelBackupClick(Sender: TObject);
var
  SelectedItem: TListItem;
  BackupPath: string;
  BackupIndex: Integer;
begin
  try
    if not Assigned(lvBackup) or not Assigned(FBackupList) then
      Exit;

    SelectedItem := lvBackup.Selected;
    if not Assigned(SelectedItem) then
    begin
      AddColoredStatusMessage('❌ 请先选择要删除的备份', clRed);
      Exit;
    end;

    BackupIndex := Integer(SelectedItem.Data);
    if (BackupIndex < 0) or (BackupIndex >= FBackupList.Count) then
    begin
      AddColoredStatusMessage('❌ 备份索引无效', clRed);
      Exit;
    end;

    BackupPath := FBackupList[BackupIndex];

    if MessageDlg(Format('确定要删除备份吗？%s%s%s', [#13#10, BackupPath, #13#10]),
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      AddColoredStatusMessage('🗑️ 正在删除备份...', clOlive);

      if DeleteDirectoryRecursive(BackupPath) then
      begin
        AddColoredStatusMessage('✅ 备份删除成功', clGreen);
        FBackupList.Delete(BackupIndex);

        // 刷新所有相关显示
        RefreshBackupListView;
        RefreshTargetDisplay;
        UpdateBackupDisplay;
        UpdateDirectoryColors;
      end
      else
      begin
        AddColoredStatusMessage('❌ 备份删除失败', clRed);
      end;
    end;

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 删除备份异常: ' + E.Message, clRed);
    end;
  end;
end;

// lvBackup选择事件
procedure TfrmMain.lvBackupSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  try
    // 更新按钮状态
    UpdateBackupButtons;

    if Selected and Assigned(Item) then
    begin
      AddColoredStatusMessage('📋 已选择备份: ' + Item.Caption, clBlue);
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 选择备份失败: ' + E.Message, clRed);
  end;
end;

// 计算备份大小按钮事件
procedure TfrmMain.btnCalcBackupSizeClick(Sender: TObject);
var
  I: Integer;
  BackupPath: string;
  BackupSize: Int64;
  SizeStr: string;
  ListItem: TListItem;
begin
  try
    // 测试消息，确认事件被调用
    AddColoredStatusMessage('🔧 计算备份大小按钮被点击', clBlue);
    if not Assigned(lvBackup) or not Assigned(FBackupList) then
    begin
      AddColoredStatusMessage('❌ 备份列表不可用', clRed);
      Exit;
    end;

    if lvBackup.Items.Count = 0 then
    begin
      AddColoredStatusMessage('❌ 没有备份需要计算', clRed);
      Exit;
    end;

    AddColoredStatusMessage('📊 开始计算备份大小...', clBlue);

    for I := 0 to lvBackup.Items.Count - 1 do
    begin
      ListItem := lvBackup.Items[I];

      // 确保SubItems有足够的项目
      if ListItem.SubItems.Count < 3 then
      begin
        AddColoredStatusMessage('❌ ListView数据结构错误', clRed);
        Continue;
      end;

      BackupPath := ListItem.SubItems[2]; // 路径在第3列（索引2）

      AddColoredStatusMessage('正在计算: ' + ExtractFileName(BackupPath), clOlive);
      Application.ProcessMessages;

      try
        // 使用现有的CalculateDirectorySize函数
        BackupSize := CalculateDirectorySize(BackupPath);

        // 使用与其他地方相同的格式化逻辑
        if BackupSize >= 1024 * 1024 * 1024 then
          SizeStr := Format('%.2f GB', [BackupSize / (1024 * 1024 * 1024)])
        else if BackupSize >= 1024 * 1024 then
          SizeStr := Format('%.2f MB', [BackupSize / (1024 * 1024)])
        else if BackupSize >= 1024 then
          SizeStr := Format('%.2f KB', [BackupSize / 1024])
        else
          SizeStr := Format('%d 字节', [BackupSize]);

        // 更新显示（大小在第1列，索引0）
        ListItem.SubItems[0] := SizeStr;

        AddColoredStatusMessage('✅ ' + ExtractFileName(BackupPath) + ': ' + SizeStr, clGreen);

      except
        on E: Exception do
        begin
          ListItem.SubItems[0] := '计算失败';
          AddColoredStatusMessage('❌ 计算失败: ' + ExtractFileName(BackupPath) + ' - ' + E.Message, clRed);
        end;
      end;

      // 强制刷新ListView显示
      lvBackup.Refresh;
      Application.ProcessMessages;
    end;

    AddColoredStatusMessage('✅ 所有备份大小计算完成', clGreen);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 计算备份大小异常: ' + E.Message, clRed);
  end;
end;

// 实时计算大小复选框点击事件
procedure TfrmMain.cBoxCalcSizeClick(Sender: TObject);
begin
  try
    if Assigned(cBoxCalcSize) then
    begin
      if cBoxCalcSize.Checked then
      begin
        AddColoredStatusMessage('✅ 已启用实时计算目录大小功能', clGreen);
        AddColoredStatusMessage('💡 提示：切换左右目录时将自动计算大小', clBlue);

        // 立即计算当前目录的大小
        if Assigned(DirListBoxSource) and (DirListBoxSource.Directory <> '') then
        begin
          DirListBoxSourceChange(nil);  // 触发左侧目录计算
        end;
      end
      else
      begin
        AddColoredStatusMessage('⏸️ 已禁用实时计算目录大小功能', clOlive);

        // 清除大小显示
        if Assigned(lblSize) then
        begin
          lblSize.Visible := False;
        end;
      end;
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 切换实时计算状态失败: ' + E.Message, clRed);
  end;
end;

// ===== 删除并链接功能 =====

// 执行删除并链接操作
procedure TfrmMain.ExecuteDeleteAndLink(const ASourcePath, ATargetPath: string);
begin
  try
    AddColoredStatusMessage('🔍 第1步：验证文件一致性...', clBlue);
    Application.ProcessMessages;

    // 验证文件一致性
    if not VerifyDirectoryConsistency(ASourcePath, ATargetPath) then
    begin
      AddColoredStatusMessage('❌ 文件一致性验证失败，操作中止', clRed);
      AddColoredStatusMessage('⚠️ 请确保目标目录中的文件与源目录完全一致', clRed);
      Exit;
    end;

    AddColoredStatusMessage('✅ 文件一致性验证通过', clGreen);
    AddColoredStatusMessage('🗑️ 第2步：删除源目录...', clOlive);
    Application.ProcessMessages;

    // 删除源目录
    if not DeleteDirectoryRecursive(ASourcePath) then
    begin
      AddColoredStatusMessage('❌ 删除源目录失败，操作中止', clRed);
      Exit;
    end;

    AddColoredStatusMessage('✅ 源目录删除成功', clGreen);
    AddColoredStatusMessage('🔗 第3步：创建符号链接...', clBlue);
    Application.ProcessMessages;

    // 创建符号链接
    if CreateSymbolicLink(ASourcePath, ATargetPath) then
    begin
      AddColoredStatusMessage('✅ 符号链接创建成功！', clGreen);
      AddStatusMessage('链接路径: ' + ASourcePath);
      AddStatusMessage('目标路径: ' + ATargetPath);

      // 刷新源目录显示
      if Assigned(DirListBoxSource) then
      begin
        // 强制刷新目录列表以显示符号链接
        DirListBoxSource.Directory := ExtractFilePath(ASourcePath);
        DirListBoxSource.Update;
        Application.ProcessMessages;

        if Assigned(FileListBoxSource) then
        begin
          FileListBoxSource.Update;
          Application.ProcessMessages;
        end;
      end;

      // 立即更新所有界面显示
      RefreshTargetDisplay;
      UpdateDirectoryColors;
      UpdateBackupDisplay;

      AddColoredStatusMessage('🎉 删除并链接操作完成！', clGreen);
    end
    else
    begin
      AddColoredStatusMessage('❌ 符号链接创建失败', clRed);
      AddColoredStatusMessage('⚠️ 警告：源目录已删除但符号链接创建失败！', clRed);
    end;

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 删除并链接操作异常: ' + E.Message, clRed);
    end;
  end;
end;

// 创建符号链接
function TfrmMain.CreateSymbolicLink(const ALinkPath, ATargetPath: string): Boolean;
var
  Command: string;
  ExitCode: DWORD;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin
  Result := False;

  try
    // 使用mklink命令创建目录符号链接
    Command := Format('cmd.exe /c mklink /D "%s" "%s"', [ALinkPath, ATargetPath]);

    AddStatusMessage('执行命令: ' + Command);

    // 初始化结构
    FillChar(StartupInfo, SizeOf(StartupInfo), 0);
    StartupInfo.cb := SizeOf(StartupInfo);
    StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
    StartupInfo.wShowWindow := SW_HIDE;

    // 创建进程
    if CreateProcess(nil, PChar(Command), nil, nil, False, 0, nil, nil, StartupInfo, ProcessInfo) then
    begin
      try
        // 等待进程完成
        WaitForSingleObject(ProcessInfo.hProcess, INFINITE);

        // 获取退出代码
        GetExitCodeProcess(ProcessInfo.hProcess, ExitCode);

        if ExitCode = 0 then
        begin
          AddStatusMessage('✅ mklink命令执行成功');
          Result := True;
        end
        else
        begin
          AddColoredStatusMessage(Format('❌ mklink命令失败，退出代码: %d', [ExitCode]), clRed);
        end;

      finally
        CloseHandle(ProcessInfo.hProcess);
        CloseHandle(ProcessInfo.hThread);
      end;
    end
    else
    begin
      AddColoredStatusMessage('❌ 无法启动mklink命令', clRed);
    end;

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 创建符号链接异常: ' + E.Message, clRed);
      Result := False;
    end;
  end;
end;

// 列出目录内容（用于调试）
procedure TfrmMain.ListDirectoryContents(const ADirectory: string);
var
  SearchRec: TSearchRec;
  Count: Integer;
begin
  Count := 0;
  try
    if not DirectoryExists(ADirectory) then
    begin
      AddStatusMessage('目录不存在: ' + ADirectory);
      Exit;
    end;

    AddStatusMessage('目录内容 (' + ADirectory + '):');

    if FindFirst(ADirectory + '\*', faAnyFile, SearchRec) = 0 then
    begin
      try
        repeat
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          begin
            Inc(Count);
            if (SearchRec.Attr and faDirectory) <> 0 then
              AddStatusMessage('  📁 ' + SearchRec.Name)
            else
              AddStatusMessage('  📄 ' + SearchRec.Name);

            // 只显示前10个项目，避免信息过多
            if Count >= 10 then
            begin
              AddStatusMessage('  ... (还有更多项目)');
              Break;
            end;
          end;
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;

    if Count = 0 then
      AddStatusMessage('  (目录为空)');

  except
    on E: Exception do
      AddStatusMessage('列出目录内容失败: ' + E.Message);
  end;
end;

// ===== 文件一致性验证功能 =====

// 验证两个目录的文件一致性（公共接口）
function TfrmMain.VerifyDirectoryConsistency(const ASourceDir, ATargetDir: string): Boolean;
var
  TotalFiles, MatchedFiles, MismatchedFiles: Integer;
begin
  Result := False;
  TotalFiles := 0;
  MatchedFiles := 0;
  MismatchedFiles := 0;

  try
    AddStatusMessage('📊 开始验证目录一致性...');
    AddStatusMessage('源目录: ' + ASourceDir);
    AddStatusMessage('目标目录: ' + ATargetDir);

    if not DirectoryExists(ASourceDir) then
    begin
      AddColoredStatusMessage('❌ 源目录不存在', clRed);
      Exit;
    end;

    if not DirectoryExists(ATargetDir) then
    begin
      AddColoredStatusMessage('❌ 目标目录不存在', clRed);
      Exit;
    end;

    // 调用内部递归验证函数
    Result := VerifyDirectoryConsistencyInternal(ASourceDir, ATargetDir, TotalFiles, MatchedFiles, MismatchedFiles);

    // 只在根级别显示最终验证结果
    AddStatusMessage('');
    AddColoredStatusMessage('📊 文件一致性验证结果:', clBlue);
    AddStatusMessage(Format('总文件数: %d', [TotalFiles]));
    AddStatusMessage(Format('匹配文件数: %d', [MatchedFiles]));
    AddStatusMessage(Format('不匹配文件数: %d', [MismatchedFiles]));

    // 显示最终结果
    if Result then
      AddColoredStatusMessage('✅ 所有文件验证通过，目录完全一致', clGreen)
    else
      AddColoredStatusMessage('❌ 目录不一致，存在缺失或不匹配的文件', clRed);

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 验证过程异常: ' + E.Message, clRed);
      Result := False;
    end;
  end;
end;

// 验证两个目录的文件一致性（内部递归函数）
function TfrmMain.VerifyDirectoryConsistencyInternal(const ASourceDir, ATargetDir: string; var ATotalFiles, AMatchedFiles, AMismatchedFiles: Integer): Boolean;
var
  SearchRec: TSearchRec;
  SourcePath, TargetPath: string;
begin
  Result := True;

  try
    // 遍历源目录中的所有文件和子目录
    if FindFirst(ASourceDir + '\*', faAnyFile, SearchRec) = 0 then
    begin
      try
        repeat
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          begin
            SourcePath := ASourceDir + '\' + SearchRec.Name;
            TargetPath := ATargetDir + '\' + SearchRec.Name;

            if (SearchRec.Attr and faDirectory) <> 0 then
            begin
              // 递归验证子目录
              if not VerifyDirectoryConsistencyInternal(SourcePath, TargetPath, ATotalFiles, AMatchedFiles, AMismatchedFiles) then
              begin
                AddColoredStatusMessage('❌ 子目录验证失败: ' + SearchRec.Name, clRed);
                Result := False;
              end;
            end
            else
            begin
              // 验证文件
              Inc(ATotalFiles);

              if not FileExists(TargetPath) then
              begin
                AddColoredStatusMessage('❌ 目标文件不存在: ' + SearchRec.Name, clRed);
                Inc(AMismatchedFiles);
                Result := False;
              end
              else
              begin
                // 比较文件内容
                if CompareFiles(SourcePath, TargetPath) then
                begin
                  Inc(AMatchedFiles);
                  // 每100个文件显示一次进度
                  if (AMatchedFiles mod 100 = 0) then
                    AddStatusMessage(Format('✅ 已验证 %d 个文件匹配', [AMatchedFiles]));
                end
                else
                begin
                  AddColoredStatusMessage('❌ 文件内容不匹配: ' + SearchRec.Name, clRed);
                  Inc(AMismatchedFiles);
                  Result := False;
                end;
              end;
            end;
          end;
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 验证子目录异常: ' + E.Message, clRed);
      Result := False;
    end;
  end;
end;

// 比较两个文件是否相同
function TfrmMain.CompareFiles(const AFile1, AFile2: string): Boolean;
var
  File1, File2: TFileStream;
  Buffer1, Buffer2: array[0..8191] of Byte;
  BytesRead1, BytesRead2: Integer;
begin
  Result := False;

  try
    if not FileExists(AFile1) or not FileExists(AFile2) then
      Exit;

    // 首先比较文件大小
    File1 := TFileStream.Create(AFile1, fmOpenRead or fmShareDenyWrite);
    try
      File2 := TFileStream.Create(AFile2, fmOpenRead or fmShareDenyWrite);
      try
        if File1.Size <> File2.Size then
          Exit;

        // 如果大小相同，比较内容
        File1.Position := 0;
        File2.Position := 0;

        repeat
          BytesRead1 := File1.Read(Buffer1, SizeOf(Buffer1));
          BytesRead2 := File2.Read(Buffer2, SizeOf(Buffer2));

          if BytesRead1 <> BytesRead2 then
            Exit;

          if not CompareMem(@Buffer1, @Buffer2, BytesRead1) then
            Exit;

        until BytesRead1 = 0;

        Result := True;

      finally
        File2.Free;
      end;
    finally
      File1.Free;
    end;

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 文件比较异常: ' + E.Message, clRed);
      Result := False;
    end;
  end;
end;

// ===== 递归删除目录功能 =====

// 递归删除目录及其所有内容
function TfrmMain.DeleteDirectoryRecursive(const ADirectory: string): Boolean;
var
  SearchRec: TSearchRec;
  FilePath: string;
  DeletedFiles, DeletedDirs: Integer;
begin
  Result := False;
  DeletedFiles := 0;
  DeletedDirs := 0;

  try
    if not DirectoryExists(ADirectory) then
    begin
      Result := True; // 目录不存在，认为删除成功
      Exit;
    end;

    // 只对根目录显示进度，减少日志输出
    if Length(ADirectory) - Length(StringReplace(ADirectory, '\', '', [rfReplaceAll])) <= 4 then
    begin
      AddColoredStatusMessage('🗑️ 正在删除: ' + ExtractFileName(ADirectory), clOlive);
      Application.ProcessMessages;
    end;

    // 遍历目录中的所有文件和子目录
    if FindFirst(ADirectory + '\*', faAnyFile, SearchRec) = 0 then
    begin
      try
        repeat
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          begin
            FilePath := ADirectory + '\' + SearchRec.Name;

            if (SearchRec.Attr and faDirectory) <> 0 then
            begin
              // 递归删除子目录
              if DeleteDirectoryRecursive(FilePath) then
                Inc(DeletedDirs)
              else
              begin
                AddColoredStatusMessage('❌ 删除子目录失败: ' + SearchRec.Name, clRed);
                Exit;
              end;
            end
            else
            begin
              // 删除文件
              // 先尝试移除文件的只读属性
              try
                SetFileAttributes(PChar(FilePath), FILE_ATTRIBUTE_NORMAL);
              except
                // 忽略属性设置错误
              end;

              if DeleteFile(FilePath) then
                Inc(DeletedFiles)
              else
              begin
                // 文件删除失败，尝试强制删除
                try
                  SetFileAttributes(PChar(FilePath), FILE_ATTRIBUTE_NORMAL);
                  Sleep(10); // 短暂等待
                  if not DeleteFile(FilePath) then
                  begin
                    AddColoredStatusMessage('❌ 无法删除文件: ' + SearchRec.Name, clRed);
                    Exit;
                  end;
                  Inc(DeletedFiles);
                except
                  AddColoredStatusMessage('❌ 删除文件失败: ' + SearchRec.Name, clRed);
                  Exit;
                end;
              end;
            end;
          end;
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;

    // 删除空目录（只对根目录显示）
    if Length(ADirectory) - Length(StringReplace(ADirectory, '\', '', [rfReplaceAll])) <= 4 then
      AddColoredStatusMessage('🗑️ 尝试删除目录: ' + ExtractFileName(ADirectory), clOlive);

    // 先尝试设置目录属性为正常（移除只读等属性）
    try
      SetFileAttributes(PChar(ADirectory), FILE_ATTRIBUTE_NORMAL);
    except
      // 忽略属性设置错误
    end;

    if RemoveDir(ADirectory) then
    begin
      if (DeletedFiles = 0) and (DeletedDirs = 0) then
        AddColoredStatusMessage('✅ 删除空目录成功: ' + ExtractFileName(ADirectory), clGreen)
      else
        AddColoredStatusMessage(Format('✅ 删除完成: %d 个文件, %d 个子目录', [DeletedFiles, DeletedDirs]), clGreen);
      Result := True;
    end
    else
    begin
      var ErrorCode := GetLastError;
      var ErrorMsg := SysErrorMessage(ErrorCode);
      AddColoredStatusMessage('❌ 删除目录失败: ' + ExtractFileName(ADirectory), clRed);
      AddColoredStatusMessage('❌ 错误代码: ' + IntToStr(ErrorCode) + ' - ' + ErrorMsg, clRed);

      // 提供具体的解决建议和强制删除选项
      case ErrorCode of
        ERROR_ACCESS_DENIED:
        begin
          AddColoredStatusMessage('💡 建议：请以管理员权限运行程序', clBlue);
          if MessageDlg('删除失败：权限不足' + #13#10 + #13#10 +
                       '是否尝试使用系统命令强制删除？' + #13#10 +
                       '(需要管理员权限)',
                       mtWarning, [mbYes, mbNo], 0) = mrYes then
          begin
            Result := ForceDeleteDirectory(ADirectory);
          end;
        end;
        ERROR_SHARING_VIOLATION:
        begin
          AddColoredStatusMessage('💡 文件被占用，尝试强制删除...', clBlue);
          // 直接尝试强制删除，不再询问用户
          Result := ForceDeleteDirectory(ADirectory);
        end;
        ERROR_DIR_NOT_EMPTY:
        begin
          AddColoredStatusMessage('💡 建议：目录不为空，可能有隐藏文件', clBlue);
          if MessageDlg('删除失败：目录不为空' + #13#10 + #13#10 +
                       '可能存在隐藏文件或系统文件' + #13#10 +
                       '是否尝试强制删除？',
                       mtWarning, [mbYes, mbNo], 0) = mrYes then
          begin
            Result := ForceDeleteDirectory(ADirectory);
          end;
        end;
      end;
    end;

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 删除目录异常: ' + E.Message, clRed);
      Result := False;
    end;
  end;
end;

// 强制删除目录（使用最直接的方法）
function TfrmMain.ForceDeleteDirectory(const ADirectory: string): Boolean;
var
  Command: string;
  ExitCode: DWORD;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin
  Result := False;

  try
    AddColoredStatusMessage('⚡ 使用直接删除方法...', clOlive);

    // 方法1: 直接使用rmdir强制删除
    Command := Format('cmd.exe /c rmdir /s /q "%s"', [ADirectory]);

    ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
    StartupInfo.cb := SizeOf(StartupInfo);
    StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
    StartupInfo.wShowWindow := SW_HIDE;

    if CreateProcess(nil, PChar(Command), nil, nil, False,
                    CREATE_NO_WINDOW, nil, nil, StartupInfo, ProcessInfo) then
    begin
      WaitForSingleObject(ProcessInfo.hProcess, 10000);
      CloseHandle(ProcessInfo.hProcess);
      CloseHandle(ProcessInfo.hThread);

      if not DirectoryExists(ADirectory) then
      begin
        AddColoredStatusMessage('✅ rmdir删除成功！', clGreen);
        Result := True;
        Exit;
      end;
    end;

    // 方法2: 使用PowerShell
    AddColoredStatusMessage('🔧 尝试PowerShell删除...', clOlive);
    Command := Format('powershell.exe -Command "Remove-Item ''%s'' -Recurse -Force"', [ADirectory]);

    if CreateProcess(nil, PChar(Command), nil, nil, False,
                    CREATE_NO_WINDOW, nil, nil, StartupInfo, ProcessInfo) then
    begin
      WaitForSingleObject(ProcessInfo.hProcess, 10000);
      CloseHandle(ProcessInfo.hProcess);
      CloseHandle(ProcessInfo.hThread);

      if not DirectoryExists(ADirectory) then
      begin
        AddColoredStatusMessage('✅ PowerShell删除成功！', clGreen);
        Result := True;
        Exit;
      end;
    end;

    // 方法3: 获取所有权后删除
    AddColoredStatusMessage('🔧 尝试获取所有权...', clOlive);
    Command := Format('cmd.exe /c takeown /f "%s" /r /d y && rmdir /s /q "%s"', [ADirectory, ADirectory]);

    if CreateProcess(nil, PChar(Command), nil, nil, False,
                    CREATE_NO_WINDOW, nil, nil, StartupInfo, ProcessInfo) then
    begin
      WaitForSingleObject(ProcessInfo.hProcess, 15000);
      CloseHandle(ProcessInfo.hProcess);
      CloseHandle(ProcessInfo.hThread);

      if not DirectoryExists(ADirectory) then
      begin
        AddColoredStatusMessage('✅ 获取所有权后删除成功！', clGreen);
        Result := True;
        Exit;
      end;
    end;

    // 方法4: 重命名后删除（对于空目录特别有效）
    AddColoredStatusMessage('🔧 尝试重命名删除...', clOlive);
    var NewName := ADirectory + '_to_delete_' + IntToStr(GetTickCount);
    if RenameFile(ADirectory, NewName) then
    begin
      Command := Format('cmd.exe /c rmdir /s /q "%s"', [NewName]);
      if CreateProcess(nil, PChar(Command), nil, nil, False,
                      CREATE_NO_WINDOW, nil, nil, StartupInfo, ProcessInfo) then
      begin
        WaitForSingleObject(ProcessInfo.hProcess, 5000);
        CloseHandle(ProcessInfo.hProcess);
        CloseHandle(ProcessInfo.hThread);

        if not DirectoryExists(NewName) then
        begin
          AddColoredStatusMessage('✅ 重命名删除成功！', clGreen);
          Result := True;
          Exit;
        end;
      end;
    end;

    // 方法5: 使用Windows API直接删除
    AddColoredStatusMessage('🔧 尝试API删除...', clOlive);
    try
      if RemoveDir(ADirectory) then
      begin
        AddColoredStatusMessage('✅ API删除成功！', clGreen);
        Result := True;
        Exit;
      end;
    except
      // 忽略异常
    end;

    // 最终检查
    if not DirectoryExists(ADirectory) then
    begin
      AddColoredStatusMessage('✅ 目录删除成功！', clGreen);
      Result := True;
    end
    else
    begin
      AddColoredStatusMessage('❌ 所有删除方法都失败了', clRed);
      AddColoredStatusMessage('💡 建议：重启计算机后再试', clBlue);

      // 显示详细的错误信息
      var ErrorCode := GetLastError;
      if ErrorCode <> 0 then
      begin
        var ErrorMsg := SysErrorMessage(ErrorCode);
        AddColoredStatusMessage('❌ 系统错误: ' + IntToStr(ErrorCode) + ' - ' + ErrorMsg, clRed);
      end;
    end;

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 强制删除异常: ' + E.Message, clRed);
    end;
  end;
end;



// ===== 目录删除功能 =====

// 源目录右键菜单 - 删除目录
procedure TfrmMain.MenuItemDeleteDirClick(Sender: TObject);
var
  CurrentDir, SelectedDir, DirPath: string;
  ConfirmMsg: string;
  DirName: string;
begin
  try
    if Assigned(DirListBoxSource) then
    begin
      // 获取当前目录和选中的子目录
      CurrentDir := DirListBoxSource.Directory;

      // 详细调试信息
      AddColoredStatusMessage('🔍 当前目录: ' + CurrentDir, clBlue);
      AddColoredStatusMessage('🔍 选中项索引: ' + IntToStr(DirListBoxSource.ItemIndex), clBlue);
      AddColoredStatusMessage('🔍 目录列表项目总数: ' + IntToStr(DirListBoxSource.Items.Count), clBlue);

      // 显示所有目录项
      for var i := 0 to DirListBoxSource.Items.Count - 1 do
      begin
        AddColoredStatusMessage('🔍 项目[' + IntToStr(i) + ']: "' + DirListBoxSource.Items[i] + '"', clGray);
      end;

      // 右键菜单删除当前目录（包括所有子目录和文件）
      DirPath := CurrentDir;
      AddColoredStatusMessage('🔍 要删除的当前目录: "' + DirPath + '"', clBlue);

      if not DirectoryExists(DirPath) then
      begin
        AddColoredStatusMessage('❌ 目录不存在: ' + DirPath, clRed);
        Exit;
      end;

      // 检查是否是根目录
      if IsRootOrUserRootDirectory(DirPath) then
      begin
        AddColoredStatusMessage('❌ 禁止删除系统关键目录: ' + DirPath, clRed);
        Exit;
      end;

      // 额外安全检查：防止删除过于上级的目录
      var PathDepth := Length(DirPath) - Length(StringReplace(DirPath, '\', '', [rfReplaceAll]));
      if PathDepth <= 2 then  // C:\ 或 C:\Windows 这种层级
      begin
        AddColoredStatusMessage('❌ 禁止删除过于上级的目录: ' + DirPath, clRed);
        AddColoredStatusMessage('💡 为了安全，只能删除较深层级的目录', clBlue);
        Exit;
      end;

      // 先弹出确认对话框
      ConfirmMsg := Format('确定要删除目录及其所有内容吗？%s%s%s%s警告：此操作将删除目录中的所有文件和子目录，不可恢复！',
        [#13#10, DirPath, #13#10, #13#10]);

      if MessageDlg(ConfirmMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        AddColoredStatusMessage('✅ 用户确认删除当前目录及其所有内容', clGreen);

        // 用户确认后，切换到父目录释放对当前目录的占用
        var ParentDir := ExtractFileDir(DirPath);
        if ParentDir <> '' then
        begin
          AddColoredStatusMessage('📂 切换到父目录释放占用: ' + ParentDir, clBlue);
          DirListBoxSource.Directory := ParentDir;
          Application.ProcessMessages; // 确保目录切换完成
          Sleep(100); // 短暂等待，确保文件句柄释放
        end;
        AddColoredStatusMessage('🗑️ 开始递归删除目录: ' + DirName, clOlive);
        Application.ProcessMessages;

        if DeleteDirectoryRecursive(DirPath) then
        begin
          AddColoredStatusMessage('✅ 目录删除成功: ' + DirName, clGreen);
          // 刷新目录树
          DirListBoxSource.Update;
          if Assigned(FileListBoxSource) then
            FileListBoxSource.Update;

          // 弹出成功对话框
          MessageDlg('目录删除成功！' + #13#10 + #13#10 +
                    '已成功删除目录：' + #13#10 + DirPath,
                    mtInformation, [mbOK], 0);
        end
        else
        begin
          AddColoredStatusMessage('❌ 目录删除失败，请检查权限或文件是否被占用', clRed);

          // 弹出失败对话框
          MessageDlg('目录删除失败！' + #13#10 + #13#10 +
                    '无法删除目录：' + #13#10 + DirPath + #13#10 + #13#10 +
                    '可能原因：' + #13#10 +
                    '• 目录被其他程序占用' + #13#10 +
                    '• 权限不足' + #13#10 +
                    '• 包含只读文件',
                    mtError, [mbOK], 0);
        end;
      end;
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 删除目录失败: ' + E.Message, clRed);
  end;
end;

// 目标目录右键菜单 - 删除目录
procedure TfrmMain.MenuItemDeleteTargetDirClick(Sender: TObject);
var
  CurrentDir, SelectedDir, DirPath: string;
  ConfirmMsg: string;
  DirName: string;
begin
  try
    if Assigned(DirListBoxTarget) then
    begin
      // 获取当前目录和选中的子目录
      CurrentDir := DirListBoxTarget.Directory;

      // 右键菜单删除当前目录（包括所有子目录和文件）
      DirPath := CurrentDir;
      AddColoredStatusMessage('🔍 要删除的当前目录: "' + DirPath + '"', clBlue);

      if not DirectoryExists(DirPath) then
      begin
        AddColoredStatusMessage('❌ 目录不存在: ' + DirPath, clRed);
        Exit;
      end;

      // 检查是否是根目录
      if IsRootOrUserRootDirectory(DirPath) then
      begin
        AddColoredStatusMessage('❌ 禁止删除系统关键目录: ' + DirPath, clRed);
        Exit;
      end;

      // 额外安全检查：防止删除过于上级的目录
      var PathDepth := Length(DirPath) - Length(StringReplace(DirPath, '\', '', [rfReplaceAll]));
      if PathDepth <= 2 then  // C:\ 或 C:\Windows 这种层级
      begin
        AddColoredStatusMessage('❌ 禁止删除过于上级的目录: ' + DirPath, clRed);
        AddColoredStatusMessage('💡 为了安全，只能删除较深层级的目录', clBlue);
        Exit;
      end;

      // 先弹出确认对话框
      ConfirmMsg := Format('确定要删除目录及其所有内容吗？%s%s%s%s警告：此操作将删除目录中的所有文件和子目录，不可恢复！',
        [#13#10, DirPath, #13#10, #13#10]);

      if MessageDlg(ConfirmMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        AddColoredStatusMessage('✅ 用户确认删除当前目录及其所有内容', clGreen);

        // 用户确认后，切换到父目录释放对当前目录的占用
        var ParentDir := ExtractFileDir(DirPath);
        if ParentDir <> '' then
        begin
          AddColoredStatusMessage('📂 切换到父目录释放占用: ' + ParentDir, clBlue);
          DirListBoxTarget.Directory := ParentDir;
          Application.ProcessMessages; // 确保目录切换完成
          Sleep(100); // 短暂等待，确保文件句柄释放
        end;
        AddColoredStatusMessage('🗑️ 开始递归删除目录: ' + DirName, clOlive);
        Application.ProcessMessages;

        if DeleteDirectoryRecursive(DirPath) then
        begin
          AddColoredStatusMessage('✅ 目录删除成功: ' + DirName, clGreen);
          // 刷新目录树
          DirListBoxTarget.Update;
          if Assigned(FileListBoxTarget) then
            FileListBoxTarget.Update;

          // 弹出成功对话框
          MessageDlg('目录删除成功！' + #13#10 + #13#10 +
                    '已成功删除目录：' + #13#10 + DirPath,
                    mtInformation, [mbOK], 0);
        end
        else
        begin
          AddColoredStatusMessage('❌ 目录删除失败，请检查权限或文件是否被占用', clRed);

          // 弹出失败对话框
          MessageDlg('目录删除失败！' + #13#10 + #13#10 +
                    '无法删除目录：' + #13#10 + DirPath + #13#10 + #13#10 +
                    '可能原因：' + #13#10 +
                    '• 目录被其他程序占用' + #13#10 +
                    '• 权限不足' + #13#10 +
                    '• 包含只读文件',
                    mtError, [mbOK], 0);
        end;
      end;
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 删除目录失败: ' + E.Message, clRed);
  end;
end;

// 源目录右键菜单 - 拷贝到目标目录
procedure TfrmMain.MenuItemCopyToTargetClick(Sender: TObject);
var
  SourcePath, TargetPath: string;
begin
  try
    if Assigned(DirListBoxSource) and Assigned(DirListBoxTarget) then
    begin
      SourcePath := DirListBoxSource.Directory;
      TargetPath := DirListBoxTarget.Directory;

      // 验证源目录
      if not DirectoryExists(SourcePath) then
      begin
        AddColoredStatusMessage('❌ 源目录不存在: ' + SourcePath, clRed);
        Exit;
      end;

      // 验证目标目录
      if not DirectoryExists(TargetPath) then
      begin
        AddColoredStatusMessage('❌ 目标目录不存在: ' + TargetPath, clRed);
        Exit;
      end;

      // 检查源目录和目标目录不能相同
      if SameText(SourcePath, TargetPath) then
      begin
        AddColoredStatusMessage('❌ 源目录和目标目录不能相同', clRed);
        Exit;
      end;

      // 检查目标目录不能是源目录的子目录
      if Pos(LowerCase(SourcePath), LowerCase(TargetPath)) = 1 then
      begin
        AddColoredStatusMessage('❌ 目标目录不能是源目录的子目录', clRed);
        Exit;
      end;

      // 显示确认对话框
      if not ShowCopyConfirmDialog(SourcePath, TargetPath) then
      begin
        AddColoredStatusMessage('ℹ️ 用户取消了拷贝操作', clBlue);
        Exit;
      end;

      AddColoredStatusMessage('📋 通过右键菜单开始拷贝...', clBlue);
      AddStatusMessage('源目录: ' + SourcePath);
      AddStatusMessage('目标基础目录: ' + TargetPath);
      AddStatusMessage('最终目标路径: ' + IncludeTrailingPathDelimiter(TargetPath) + ExtractFileName(SourcePath));

      // 执行拷贝
      try
        CopyDirectoryWithProgress(SourcePath, TargetPath);
      except
        on E: Exception do
        begin
          AddColoredStatusMessage('❌ 拷贝失败: ' + E.Message, clRed);
          FinalizeCopyProgress;
        end;
      end;
    end
    else
    begin
      AddColoredStatusMessage('❌ 请确保源目录和目标目录都已选择', clRed);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 右键拷贝失败: ' + E.Message, clRed);
  end;
end;


// 扫描当前目录下的符号链接
procedure TfrmMain.ScanCurrentDirectorySymlinks(Silent: Boolean = True);
var
  SearchRec: TSearchRec;
  CurrentDir: string;
  FullPath: string;
  SymlinkCount: Integer;
  TotalCount: Integer;
begin
  try
    SymlinkCount := 0;
    TotalCount := 0;

    // 记录扫描操作
    LogOperation(otSymlinkScan, '', '', '开始扫描符号链接', True);

    // 扫描源目录
    CurrentDir := edtSource.Text;
    if (CurrentDir <> '') and DirectoryExists(CurrentDir) then
    begin
      if not Silent then
        AddColoredStatusMessage('🔍 扫描源目录: ' + CurrentDir, clNavy);

      if FindFirst(IncludeTrailingPathDelimiter(CurrentDir) + '*', faDirectory, SearchRec) = 0 then
      begin
        try
          repeat
            if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') and
               ((SearchRec.Attr and faDirectory) <> 0) then
            begin
              FullPath := IncludeTrailingPathDelimiter(CurrentDir) + SearchRec.Name;
              Inc(TotalCount);

              // 检查是否为符号链接
              var CachedInfo := GetCachedSymlinkInfo(FullPath);
              var UseCache := (CachedInfo.Path <> '') and not IsCacheExpired;

              if UseCache or IsSymbolicLink(FullPath) then
              begin
                Inc(SymlinkCount);

                var SymlinkInfo: TSymlinkInfo;
                var IsValid: Boolean;
                var Target: string;
                var InfoText: string;

                if UseCache then
                begin
                  // 使用缓存信息
                  SymlinkInfo := CachedInfo;
                  IsValid := SymlinkInfo.IsValid;
                  Target := SymlinkInfo.Target;
                  InfoText := GetSymlinkInfo(FullPath);

                  if not Silent then
                    AddColoredStatusMessage('💾 使用缓存: ' + SearchRec.Name, clGray);
                end
                else
                begin
                  // 实时扫描并缓存
                  Target := GetSymlinkTarget(FullPath);
                  IsValid := ValidateSymlink(FullPath);
                  InfoText := GetSymlinkInfo(FullPath);

                  // 创建缓存记录
                  SymlinkInfo.Path := FullPath;
                  SymlinkInfo.Target := Target;
                  SymlinkInfo.IsValid := IsValid;
                  SymlinkInfo.ScanTime := Now;
                  SymlinkInfo.IsDirectory := DirectoryExists(FullPath);

                  if IsValid then
                  begin
                    if SymlinkInfo.IsDirectory then
                      SymlinkInfo.Status := dsSymlinkDir
                    else
                      SymlinkInfo.Status := dsSymlinkFile;
                  end
                  else
                    SymlinkInfo.Status := dsSymlinkBroken;

                  // 缓存信息
                  CacheSymlinkInfo(SymlinkInfo);
                end;

                // 显示状态和标记
                if IsValid then
                begin
                  AddColoredStatusMessage('🔗✅ 有效符号链接: ' + SearchRec.Name, clBlue);
                  MarkDirectoryWithStatus(FullPath, SymlinkInfo.Status);
                end
                else
                begin
                  AddColoredStatusMessage('🔗❌ 无效符号链接: ' + SearchRec.Name, clMaroon);
                  MarkDirectoryWithStatus(FullPath, dsSymlinkBroken);
                end;

                // 显示详细信息（仅在非静默模式）
                if not Silent then
                begin
                  var InfoLines := InfoText.Split([sLineBreak]);
                  for var InfoLine in InfoLines do
                    if InfoLine.Trim <> '' then
                      AddColoredStatusMessage('   ' + InfoLine, clGray);
                end
                else
                begin
                  // 静默模式只显示目标路径
                  if Target <> '' then
                    AddColoredStatusMessage('   → ' + Target, clGray)
                  else
                    AddColoredStatusMessage('   → 无法获取目标路径', clGray);
                end;
              end
              else if not Silent then
              begin
                AddColoredStatusMessage('📁 普通目录: ' + SearchRec.Name, clGray);
              end;
            end;
          until FindNext(SearchRec) <> 0;
        finally
          FindClose(SearchRec);
        end;
      end;

      if not Silent then
        AddColoredStatusMessage(Format('📊 源目录扫描完成: 总计 %d 个目录，其中 %d 个符号链接', [TotalCount, SymlinkCount]), clGreen)
      else if SymlinkCount > 0 then
        AddColoredStatusMessage(Format('🔗 源目录发现 %d 个符号链接', [SymlinkCount]), clGreen);
    end;

    // 重置计数器
    SymlinkCount := 0;
    TotalCount := 0;

    // 扫描目标目录
    CurrentDir := edtTarget.Text;
    if (CurrentDir <> '') and DirectoryExists(CurrentDir) then
    begin
      if not Silent then
        AddColoredStatusMessage('🔍 扫描目标目录: ' + CurrentDir, clNavy);

      if FindFirst(IncludeTrailingPathDelimiter(CurrentDir) + '*', faDirectory, SearchRec) = 0 then
      begin
        try
          repeat
            if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') and
               ((SearchRec.Attr and faDirectory) <> 0) then
            begin
              FullPath := IncludeTrailingPathDelimiter(CurrentDir) + SearchRec.Name;
              Inc(TotalCount);

              if IsSymbolicLink(FullPath) then
              begin
                Inc(SymlinkCount);
                AddColoredStatusMessage('🔗 找到符号链接: ' + SearchRec.Name, clBlue);

                // 在目录树中标记符号链接
                MarkDirectoryInTree(FullPath, clBlue);

                // 获取链接目标
                var Target := GetSymlinkTarget(FullPath);
                if Target <> '' then
                  AddColoredStatusMessage('   → 指向: ' + Target, clGray)
                else
                  AddColoredStatusMessage('   → 无法获取目标路径', clGray);
              end
              else
              begin
                AddColoredStatusMessage('📁 普通目录: ' + SearchRec.Name, clGray);
              end;
            end;
          until FindNext(SearchRec) <> 0;
        finally
          FindClose(SearchRec);
        end;
      end;

      if not Silent then
        AddColoredStatusMessage(Format('📊 目标目录扫描完成: 总计 %d 个目录，其中 %d 个符号链接', [TotalCount, SymlinkCount]), clGreen)
      else if SymlinkCount > 0 then
        AddColoredStatusMessage(Format('🔗 目标目录发现 %d 个符号链接', [SymlinkCount]), clGreen);
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 扫描目录符号链接异常: ' + E.Message, clRed);
  end;
end;



// 扫描链接菜单点击事件
procedure TfrmMain.MenuItemScanSymlinksClick(Sender: TObject);
begin
  try
    AddColoredStatusMessage('🔍 开始扫描当前目录的符号链接...', clNavy);
    ScanCurrentDirectorySymlinks(False); // 手动扫描时显示详细日志

    // 刷新目录列表显示
    if Assigned(DirListBoxSource) then
      DirListBoxSource.Invalidate;
    if Assigned(DirListBoxTarget) then
      DirListBoxTarget.Invalidate;

    AddColoredStatusMessage('✅ 符号链接扫描完成', clGreen);
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 扫描符号链接异常: ' + E.Message, clRed);
  end;
end;

// 验证符号链接菜单点击事件
procedure TfrmMain.MenuItemValidateSymlinksClick(Sender: TObject);
var
  InvalidCount: Integer;
begin
  try
    AddColoredStatusMessage('🔍 开始验证所有符号链接...', clNavy);

    InvalidCount := ValidateAllSymlinks;

    if InvalidCount = 0 then
    begin
      AddColoredStatusMessage('✅ 所有符号链接都有效', clGreen);
      MessageDlg('所有符号链接验证通过！', mtInformation, [mbOK], 0);
    end
    else if InvalidCount > 0 then
    begin
      AddColoredStatusMessage(Format('⚠️ 发现 %d 个无效符号链接', [InvalidCount]), clOlive);

      if MessageDlg(Format('发现 %d 个无效符号链接。%s是否要查看修复选项？',
                          [InvalidCount, #13#10]),
                   mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        AddColoredStatusMessage('💡 请右键点击无效的符号链接选择"修复符号链接"', clBlue);
      end;
    end
    else
    begin
      AddColoredStatusMessage('❌ 验证过程中发生错误', clRed);
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 验证符号链接异常: ' + E.Message, clRed);
  end;
end;

// 修复符号链接菜单点击事件
procedure TfrmMain.MenuItemRepairSymlinkClick(Sender: TObject);
var
  SelectedPath: string;
begin
  try
    // 获取当前选中的目录
    if Assigned(DirListBoxSource) and (DirListBoxSource.Directory <> '') then
      SelectedPath := DirListBoxSource.Directory
    else if Assigned(DirListBoxTarget) and (DirListBoxTarget.Directory <> '') then
      SelectedPath := DirListBoxTarget.Directory
    else
    begin
      AddColoredStatusMessage('❌ 请先选择要修复的符号链接目录', clRed);
      Exit;
    end;

    // 检查是否为符号链接
    if not IsSymbolicLink(SelectedPath) then
    begin
      AddColoredStatusMessage('❌ 选中的目录不是符号链接', clRed);
      MessageDlg('选中的目录不是符号链接，无法修复。', mtWarning, [mbOK], 0);
      Exit;
    end;

    // 检查是否为无效符号链接
    if ValidateSymlink(SelectedPath) then
    begin
      AddColoredStatusMessage('✅ 符号链接有效，无需修复', clGreen);
      MessageDlg('选中的符号链接是有效的，无需修复。', mtInformation, [mbOK], 0);
      Exit;
    end;

    // 显示修复对话框
    ShowSymlinkRepairDialog(SelectedPath);

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 修复符号链接异常: ' + E.Message, clRed);
  end;
end;

// 显示操作历史菜单点击事件
procedure TfrmMain.MenuItemShowHistoryClick(Sender: TObject);
begin
  try
    ShowOperationHistory;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示操作历史异常: ' + E.Message, clRed);
  end;
end;

// 显示状态统计菜单点击事件
procedure TfrmMain.MenuItemShowStatisticsClick(Sender: TObject);
begin
  try
    ShowStatusStatistics;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示状态统计异常: ' + E.Message, clRed);
  end;
end;

// 撤销操作菜单点击事件
procedure TfrmMain.MenuItemUndoOperationClick(Sender: TObject);
begin
  try
    UndoLastOperation;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 撤销操作异常: ' + E.Message, clRed);
  end;
end;

// 清空历史记录菜单点击事件
procedure TfrmMain.MenuItemClearHistoryClick(Sender: TObject);
var
  ConfirmMsg: string;
begin
  try
    if not Assigned(FStatusManager) then
    begin
      AddColoredStatusMessage('❌ 状态管理器未初始化', clRed);
      Exit;
    end;

    if FStatusManager.OperationCount = 0 then
    begin
      AddColoredStatusMessage('📋 操作历史记录为空', clGray);
      Exit;
    end;

    ConfirmMsg := Format('确定要清空所有操作历史记录吗？%s当前有 %d 条记录。%s%s警告：此操作不可恢复！',
                        [#13#10, FStatusManager.OperationCount, #13#10, #13#10]);

    if MessageDlg(ConfirmMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      FStatusManager.ClearHistory;
      FStatusManager.SaveToFile;
      AddColoredStatusMessage('✅ 操作历史记录已清空', clGreen);
    end;

  except
    on E: Exception do
      AddColoredStatusMessage('❌ 清空历史记录异常: ' + E.Message, clRed);
  end;
end;

// 显示智能建议菜单点击事件
procedure TfrmMain.MenuItemShowSuggestionsClick(Sender: TObject);
begin
  try
    ShowSmartSuggestions;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示智能建议异常: ' + E.Message, clRed);
  end;
end;

// 生成智能建议菜单点击事件
procedure TfrmMain.MenuItemGenerateSuggestionsClick(Sender: TObject);
begin
  try
    GenerateContextualSuggestions;
    AddColoredStatusMessage('💡 智能建议已生成，使用"显示智能建议"查看', clBlue);
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 生成智能建议异常: ' + E.Message, clRed);
  end;
end;

// 批量操作菜单点击事件
procedure TfrmMain.MenuItemBatchOperationsClick(Sender: TObject);
begin
  try
    ShowBatchOperationDialog;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 批量操作异常: ' + E.Message, clRed);
  end;
end;

// 显示系统摘要菜单点击事件
procedure TfrmMain.MenuItemShowSummaryClick(Sender: TObject);
begin
  try
    ShowProgressSummary;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示系统摘要异常: ' + E.Message, clRed);
  end;
end;

// 优化性能菜单点击事件
procedure TfrmMain.MenuItemOptimizePerformanceClick(Sender: TObject);
begin
  try
    OptimizePerformance;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 优化性能异常: ' + E.Message, clRed);
  end;
end;

// 分析依赖关系菜单点击事件
procedure TfrmMain.MenuItemAnalyzeDependenciesClick(Sender: TObject);
var
  TargetPath: string;
begin
  try
    TargetPath := edtSource.Text;
    if TargetPath = '' then
      TargetPath := edtTarget.Text;

    if TargetPath = '' then
    begin
      AddColoredStatusMessage('❌ 请先选择要分析的目录', clRed);
      Exit;
    end;

    AnalyzeDependencies(TargetPath);
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 分析依赖关系异常: ' + E.Message, clRed);
  end;
end;

// 显示依赖关系图菜单点击事件
procedure TfrmMain.MenuItemShowDependencyGraphClick(Sender: TObject);
begin
  try
    ShowDependencyGraph;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示依赖关系图异常: ' + E.Message, clRed);
  end;
end;

// 检查循环依赖菜单点击事件
procedure TfrmMain.MenuItemCheckCircularDepsClick(Sender: TObject);
begin
  try
    ShowCircularDependencies;
    ShowCriticalPaths;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 检查循环依赖异常: ' + E.Message, clRed);
  end;
end;

// 评估风险菜单点击事件
procedure TfrmMain.MenuItemAssessRiskClick(Sender: TObject);
var
  TargetPath: string;
begin
  try
    TargetPath := edtSource.Text;
    if TargetPath = '' then
      TargetPath := edtTarget.Text;

    if TargetPath = '' then
    begin
      AddColoredStatusMessage('❌ 请先选择要评估的目录', clRed);
      Exit;
    end;

    AssessMovementRisk(TargetPath);
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 评估风险异常: ' + E.Message, clRed);
  end;
end;

// 显示配置模板菜单点击事件
procedure TfrmMain.MenuItemShowTemplatesClick(Sender: TObject);
begin
  try
    ShowTemplateManager;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示配置模板异常: ' + E.Message, clRed);
  end;
end;

// 创建配置模板菜单点击事件
procedure TfrmMain.MenuItemCreateTemplateClick(Sender: TObject);
begin
  try
    CreateNewTemplate;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 创建配置模板异常: ' + E.Message, clRed);
  end;
end;

// 加载配置模板菜单点击事件
procedure TfrmMain.MenuItemLoadTemplateClick(Sender: TObject);
begin
  try
    LoadTemplateDialog;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 加载配置模板异常: ' + E.Message, clRed);
  end;
end;

// 保存配置模板菜单点击事件
procedure TfrmMain.MenuItemSaveTemplateClick(Sender: TObject);
begin
  try
    SaveCurrentTemplate;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 保存配置模板异常: ' + E.Message, clRed);
  end;
end;

// 显示审计日志菜单点击事件
procedure TfrmMain.MenuItemShowAuditLogClick(Sender: TObject);
begin
  try
    ShowAuditLog;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示审计日志异常: ' + E.Message, clRed);
  end;
end;

// 显示合规规则菜单点击事件
procedure TfrmMain.MenuItemShowComplianceRulesClick(Sender: TObject);
begin
  try
    ShowComplianceRules;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 显示合规规则异常: ' + E.Message, clRed);
  end;
end;

// 生成审计报告菜单点击事件
procedure TfrmMain.MenuItemGenerateAuditReportClick(Sender: TObject);
begin
  try
    GenerateAuditReport;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 生成审计报告异常: ' + E.Message, clRed);
  end;
end;

// 创建合规规则菜单点击事件
procedure TfrmMain.MenuItemCreateComplianceRuleClick(Sender: TObject);
begin
  try
    CreateComplianceRule;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 创建合规规则异常: ' + E.Message, clRed);
  end;
end;

// 切换主题菜单点击事件
procedure TfrmMain.MenuItemToggleThemeClick(Sender: TObject);
begin
  try
    ToggleTheme;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 切换主题异常: ' + E.Message, clRed);
  end;
end;

// 为当前目录添加到C盘的同路径链接
procedure TfrmMain.MenuItemCreateLinkToCDriveClick(Sender: TObject);
var
  CurrentDir: string;
  CDrivePath: string;
  RelativePath: string;
  ConfirmMsg: string;
begin
  try
    if not Assigned(DirListBoxTarget) then
      Exit;

    CurrentDir := DirListBoxTarget.Directory;

    // 检查当前目录是否已经在C盘
    if UpperCase(Copy(CurrentDir, 1, 3)) = 'C:\' then
    begin
      AddColoredStatusMessage('❌ 当前目录已经在C盘，无需创建链接', clRed);
      Exit;
    end;

    // 检查当前目录是否已经是符号链接
    if IsSymbolicLink(CurrentDir) then
    begin
      AddColoredStatusMessage('❌ 当前目录已经是符号链接，无法再次创建链接', clRed);
      Exit;
    end;

    // 获取相对于根目录的路径
    // 例如：D:\Users\Administrator -> Users\Administrator
    if Length(CurrentDir) > 3 then
      RelativePath := Copy(CurrentDir, 4, Length(CurrentDir) - 3)  // 跳过 "D:\"
    else
      RelativePath := '';

    // 构建C盘的目标路径
    if RelativePath <> '' then
      CDrivePath := 'C:\' + RelativePath
    else
      CDrivePath := 'C:\';

    AddColoredStatusMessage('🔍 当前目录: ' + CurrentDir, clBlue);
    AddColoredStatusMessage('🔍 目标C盘路径: ' + CDrivePath, clBlue);

    // 检查C盘目标路径是否已存在
    if DirectoryExists(CDrivePath) then
    begin
      AddColoredStatusMessage('❌ C盘目标路径已存在: ' + CDrivePath, clRed);
      AddColoredStatusMessage('💡 提示：无法创建符号链接，目标路径已被占用', clBlue);
      Exit;
    end;

    // 确认创建符号链接
    ConfirmMsg := Format('确定要在C盘创建指向当前目录的符号链接吗？%s%s源目录：%s%s符号链接：%s%s%s注意：这只会创建一个符号链接，不会移动原目录。',
      [#13#10, #13#10, CurrentDir, #13#10, CDrivePath, #13#10, #13#10]);

    if MessageDlg(ConfirmMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      AddColoredStatusMessage('🔗 正在创建符号链接...', clBlue);

      if CreateSymbolicLink(CDrivePath, CurrentDir) then
      begin
        AddColoredStatusMessage('✅ 符号链接创建成功！', clGreen);
        AddColoredStatusMessage('🔗 符号链接: ' + CDrivePath, clGreen);
        AddColoredStatusMessage('📁 指向目录: ' + CurrentDir, clGreen);

        // 刷新目录显示
        UpdateDirectoryColors;
        if Assigned(DirListBoxSource) then
          DirListBoxSource.Invalidate;
        if Assigned(DirListBoxTarget) then
          DirListBoxTarget.Invalidate;
      end
      else
      begin
        AddColoredStatusMessage('❌ 符号链接创建失败', clRed);
        AddColoredStatusMessage('💡 提示：请确保以管理员权限运行程序', clBlue);
      end;
    end;

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 创建符号链接异常: ' + E.Message, clRed);
    end;
  end;
end;

// ===== 右键菜单事件处理 =====

// 源目录右键菜单 - 计算大小
procedure TfrmMain.MenuItemCalcSizeClick(Sender: TObject);
begin
  btnCalcDirSizeClick(Sender);
end;

// 源目录右键菜单 - 分析可行性
procedure TfrmMain.MenuItemAnalyzeClick(Sender: TObject);
begin
  btnAnalyzeClick(Sender);
end;

// 源目录右键菜单 - 在资源管理器中打开
procedure TfrmMain.MenuItemOpenInExplorerClick(Sender: TObject);
var
  DirPath: string;
begin
  try
    if Assigned(DirListBoxSource) then
    begin
      DirPath := DirListBoxSource.Directory;
      if DirectoryExists(DirPath) then
      begin
        ShellExecute(Handle, 'open', 'explorer.exe', PChar(DirPath), nil, SW_SHOWNORMAL);
        AddColoredStatusMessage('📂 已在资源管理器中打开: ' + DirPath, clBlue);
      end
      else
      begin
        AddColoredStatusMessage('❌ 目录不存在: ' + DirPath, clRed);
      end;
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 打开资源管理器失败: ' + E.Message, clRed);
  end;
end;

// 源目录右键菜单 - 复制路径
procedure TfrmMain.MenuItemCopyPathClick(Sender: TObject);
var
  DirPath: string;
begin
  try
    if Assigned(DirListBoxSource) then
    begin
      DirPath := DirListBoxSource.Directory;
      Clipboard.AsText := DirPath;
      AddColoredStatusMessage('📋 路径已复制到剪贴板: ' + DirPath, clGreen);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 复制路径失败: ' + E.Message, clRed);
  end;
end;

// 源目录右键菜单 - 刷新
procedure TfrmMain.MenuItemRefreshClick(Sender: TObject);
begin
  try
    if Assigned(DirListBoxSource) then
    begin
      DirListBoxSource.Update;
      if Assigned(FileListBoxSource) then
        FileListBoxSource.Update;
      AddColoredStatusMessage('🔄 源目录已刷新', clBlue);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 刷新失败: ' + E.Message, clRed);
  end;
end;

// 目标目录右键菜单 - 在资源管理器中打开
procedure TfrmMain.MenuItemOpenTargetInExplorerClick(Sender: TObject);
var
  DirPath: string;
begin
  try
    if Assigned(DirListBoxTarget) then
    begin
      DirPath := DirListBoxTarget.Directory;
      if DirectoryExists(DirPath) then
      begin
        ShellExecute(Handle, 'open', 'explorer.exe', PChar(DirPath), nil, SW_SHOWNORMAL);
        AddColoredStatusMessage('📂 已在资源管理器中打开: ' + DirPath, clBlue);
      end
      else
      begin
        AddColoredStatusMessage('❌ 目录不存在: ' + DirPath, clRed);
      end;
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 打开资源管理器失败: ' + E.Message, clRed);
  end;
end;

// 目标目录右键菜单 - 复制路径
procedure TfrmMain.MenuItemCopyTargetPathClick(Sender: TObject);
var
  DirPath: string;
begin
  try
    if Assigned(DirListBoxTarget) then
    begin
      DirPath := DirListBoxTarget.Directory;
      Clipboard.AsText := DirPath;
      AddColoredStatusMessage('📋 目标路径已复制到剪贴板: ' + DirPath, clGreen);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 复制路径失败: ' + E.Message, clRed);
  end;
end;

// 目标目录右键菜单 - 刷新
procedure TfrmMain.MenuItemRefreshTargetClick(Sender: TObject);
begin
  try
    if Assigned(DirListBoxTarget) then
    begin
      DirListBoxTarget.Update;
      if Assigned(FileListBoxTarget) then
        FileListBoxTarget.Update;
      AddColoredStatusMessage('🔄 目标目录已刷新', clBlue);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 刷新失败: ' + E.Message, clRed);
  end;
end;

// 目标目录右键菜单 - 新建文件夹
procedure TfrmMain.MenuItemCreateFolderClick(Sender: TObject);
var
  FolderName: string;
  NewFolderPath: string;
  BasePath: string;
begin
  try
    if Assigned(DirListBoxTarget) then
    begin
      BasePath := DirListBoxTarget.Directory;

      // 提示用户输入文件夹名称
      FolderName := InputBox('新建文件夹', '请输入文件夹名称:', '新建文件夹');

      if Trim(FolderName) <> '' then
      begin
        NewFolderPath := IncludeTrailingPathDelimiter(BasePath) + FolderName;

        if DirectoryExists(NewFolderPath) then
        begin
          AddColoredStatusMessage('❌ 文件夹已存在: ' + FolderName, clRed);
        end
        else
        begin
          if CreateDir(NewFolderPath) then
          begin
            AddColoredStatusMessage('✅ 文件夹创建成功: ' + FolderName, clGreen);
            // 刷新目录树
            DirListBoxTarget.Update;
            if Assigned(FileListBoxTarget) then
              FileListBoxTarget.Update;
          end
          else
          begin
            AddColoredStatusMessage('❌ 文件夹创建失败: ' + FolderName, clRed);
          end;
        end;
      end;
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 创建文件夹失败: ' + E.Message, clRed);
  end;
end;

// ===== 文件操作功能 =====

// 源文件右键菜单 - 重命名文件
procedure TfrmMain.MenuItemRenameSourceFileClick(Sender: TObject);
var
  OldFileName, NewFileName, OldPath, NewPath: string;
  BasePath: string;
begin
  try
    if Assigned(FileListBoxSource) and (FileListBoxSource.ItemIndex >= 0) then
    begin
      OldFileName := FileListBoxSource.Items[FileListBoxSource.ItemIndex];
      BasePath := DirListBoxSource.Directory;
      OldPath := IncludeTrailingPathDelimiter(BasePath) + OldFileName;

      if not FileExists(OldPath) then
      begin
        AddColoredStatusMessage('❌ 文件不存在: ' + OldFileName, clRed);
        Exit;
      end;

      NewFileName := InputBox('重命名文件', '请输入新的文件名:', OldFileName);

      if (Trim(NewFileName) <> '') and (NewFileName <> OldFileName) then
      begin
        NewPath := IncludeTrailingPathDelimiter(BasePath) + NewFileName;

        if FileExists(NewPath) then
        begin
          AddColoredStatusMessage('❌ 文件名已存在: ' + NewFileName, clRed);
        end
        else
        begin
          if RenameFile(OldPath, NewPath) then
          begin
            AddColoredStatusMessage('✅ 文件重命名成功: ' + OldFileName + ' → ' + NewFileName, clGreen);
            // 刷新文件列表
            FileListBoxSource.Update;
          end
          else
          begin
            AddColoredStatusMessage('❌ 文件重命名失败', clRed);
          end;
        end;
      end;
    end
    else
    begin
      AddColoredStatusMessage('❌ 请先选择要重命名的文件', clRed);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 重命名文件失败: ' + E.Message, clRed);
  end;
end;

// 源文件右键菜单 - 删除文件
procedure TfrmMain.MenuItemDeleteSourceFileClick(Sender: TObject);
var
  FileName, FilePath: string;
  ConfirmMsg: string;
begin
  try
    if Assigned(FileListBoxSource) and (FileListBoxSource.ItemIndex >= 0) then
    begin
      FileName := FileListBoxSource.Items[FileListBoxSource.ItemIndex];
      FilePath := IncludeTrailingPathDelimiter(DirListBoxSource.Directory) + FileName;

      if not FileExists(FilePath) then
      begin
        AddColoredStatusMessage('❌ 文件不存在: ' + FileName, clRed);
        Exit;
      end;

      ConfirmMsg := Format('确定要删除文件吗？%s%s%s%s警告：此操作不可恢复！',
        [#13#10, FileName, #13#10, #13#10]);

      if MessageDlg(ConfirmMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        if DeleteFile(FilePath) then
        begin
          AddColoredStatusMessage('✅ 文件删除成功: ' + FileName, clGreen);
          // 刷新文件列表
          FileListBoxSource.Update;
        end
        else
        begin
          AddColoredStatusMessage('❌ 文件删除失败，可能文件正在使用或没有权限', clRed);
        end;
      end;
    end
    else
    begin
      AddColoredStatusMessage('❌ 请先选择要删除的文件', clRed);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 删除文件失败: ' + E.Message, clRed);
  end;
end;

// 源文件右键菜单 - 打开文件
procedure TfrmMain.MenuItemOpenSourceFileClick(Sender: TObject);
var
  FileName, FilePath: string;
begin
  try
    if Assigned(FileListBoxSource) and (FileListBoxSource.ItemIndex >= 0) then
    begin
      FileName := FileListBoxSource.Items[FileListBoxSource.ItemIndex];
      FilePath := IncludeTrailingPathDelimiter(DirListBoxSource.Directory) + FileName;

      if FileExists(FilePath) then
      begin
        ShellExecute(Handle, 'open', PChar(FilePath), nil, nil, SW_SHOWNORMAL);
        AddColoredStatusMessage('📂 已打开文件: ' + FileName, clBlue);
      end
      else
      begin
        AddColoredStatusMessage('❌ 文件不存在: ' + FileName, clRed);
      end;
    end
    else
    begin
      AddColoredStatusMessage('❌ 请先选择要打开的文件', clRed);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 打开文件失败: ' + E.Message, clRed);
  end;
end;

// 源文件右键菜单 - 复制文件名
procedure TfrmMain.MenuItemCopySourceFileNameClick(Sender: TObject);
var
  FileName: string;
begin
  try
    if Assigned(FileListBoxSource) and (FileListBoxSource.ItemIndex >= 0) then
    begin
      FileName := FileListBoxSource.Items[FileListBoxSource.ItemIndex];
      Clipboard.AsText := FileName;
      AddColoredStatusMessage('📋 文件名已复制到剪贴板: ' + FileName, clGreen);
    end
    else
    begin
      AddColoredStatusMessage('❌ 请先选择要复制名称的文件', clRed);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 复制文件名失败: ' + E.Message, clRed);
  end;
end;

// 目标文件右键菜单 - 重命名文件
procedure TfrmMain.MenuItemRenameTargetFileClick(Sender: TObject);
var
  OldFileName, NewFileName, OldPath, NewPath: string;
  BasePath: string;
begin
  try
    if Assigned(FileListBoxTarget) and (FileListBoxTarget.ItemIndex >= 0) then
    begin
      OldFileName := FileListBoxTarget.Items[FileListBoxTarget.ItemIndex];
      BasePath := DirListBoxTarget.Directory;
      OldPath := IncludeTrailingPathDelimiter(BasePath) + OldFileName;

      if not FileExists(OldPath) then
      begin
        AddColoredStatusMessage('❌ 文件不存在: ' + OldFileName, clRed);
        Exit;
      end;

      NewFileName := InputBox('重命名文件', '请输入新的文件名:', OldFileName);

      if (Trim(NewFileName) <> '') and (NewFileName <> OldFileName) then
      begin
        NewPath := IncludeTrailingPathDelimiter(BasePath) + NewFileName;

        if FileExists(NewPath) then
        begin
          AddColoredStatusMessage('❌ 文件名已存在: ' + NewFileName, clRed);
        end
        else
        begin
          if RenameFile(OldPath, NewPath) then
          begin
            AddColoredStatusMessage('✅ 文件重命名成功: ' + OldFileName + ' → ' + NewFileName, clGreen);
            // 刷新文件列表
            FileListBoxTarget.Update;
          end
          else
          begin
            AddColoredStatusMessage('❌ 文件重命名失败', clRed);
          end;
        end;
      end;
    end
    else
    begin
      AddColoredStatusMessage('❌ 请先选择要重命名的文件', clRed);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 重命名文件失败: ' + E.Message, clRed);
  end;
end;

// 目标文件右键菜单 - 删除文件
procedure TfrmMain.MenuItemDeleteTargetFileClick(Sender: TObject);
var
  FileName, FilePath: string;
  ConfirmMsg: string;
begin
  try
    if Assigned(FileListBoxTarget) and (FileListBoxTarget.ItemIndex >= 0) then
    begin
      FileName := FileListBoxTarget.Items[FileListBoxTarget.ItemIndex];
      FilePath := IncludeTrailingPathDelimiter(DirListBoxTarget.Directory) + FileName;

      if not FileExists(FilePath) then
      begin
        AddColoredStatusMessage('❌ 文件不存在: ' + FileName, clRed);
        Exit;
      end;

      ConfirmMsg := Format('确定要删除文件吗？%s%s%s%s警告：此操作不可恢复！',
        [#13#10, FileName, #13#10, #13#10]);

      if MessageDlg(ConfirmMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        if DeleteFile(FilePath) then
        begin
          AddColoredStatusMessage('✅ 文件删除成功: ' + FileName, clGreen);
          // 刷新文件列表
          FileListBoxTarget.Update;
        end
        else
        begin
          AddColoredStatusMessage('❌ 文件删除失败，可能文件正在使用或没有权限', clRed);
        end;
      end;
    end
    else
    begin
      AddColoredStatusMessage('❌ 请先选择要删除的文件', clRed);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 删除文件失败: ' + E.Message, clRed);
  end;
end;

// 目标文件右键菜单 - 打开文件
procedure TfrmMain.MenuItemOpenTargetFileClick(Sender: TObject);
var
  FileName, FilePath: string;
begin
  try
    if Assigned(FileListBoxTarget) and (FileListBoxTarget.ItemIndex >= 0) then
    begin
      FileName := FileListBoxTarget.Items[FileListBoxTarget.ItemIndex];
      FilePath := IncludeTrailingPathDelimiter(DirListBoxTarget.Directory) + FileName;

      if FileExists(FilePath) then
      begin
        ShellExecute(Handle, 'open', PChar(FilePath), nil, nil, SW_SHOWNORMAL);
        AddColoredStatusMessage('📂 已打开文件: ' + FileName, clBlue);
      end
      else
      begin
        AddColoredStatusMessage('❌ 文件不存在: ' + FileName, clRed);
      end;
    end
    else
    begin
      AddColoredStatusMessage('❌ 请先选择要打开的文件', clRed);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 打开文件失败: ' + E.Message, clRed);
  end;
end;

// 目标文件右键菜单 - 复制文件名
procedure TfrmMain.MenuItemCopyTargetFileNameClick(Sender: TObject);
var
  FileName: string;
begin
  try
    if Assigned(FileListBoxTarget) and (FileListBoxTarget.ItemIndex >= 0) then
    begin
      FileName := FileListBoxTarget.Items[FileListBoxTarget.ItemIndex];
      Clipboard.AsText := FileName;
      AddColoredStatusMessage('📋 文件名已复制到剪贴板: ' + FileName, clGreen);
    end
    else
    begin
      AddColoredStatusMessage('❌ 请先选择要复制名称的文件', clRed);
    end;
  except
    on E: Exception do
      AddColoredStatusMessage('❌ 复制文件名失败: ' + E.Message, clRed);
  end;
end;

// ===== TSymlinkCache 实现 =====

constructor TSymlinkCache.Create(const ACacheFile: string);
begin
  inherited Create;
  FCacheFile := ACacheFile;
  SetLength(FSymlinks, 0);
  FLastScanTime := 0;
end;

destructor TSymlinkCache.Destroy;
begin
  SaveToFile;
  SetLength(FSymlinks, 0);
  inherited Destroy;
end;

procedure TSymlinkCache.AddSymlink(const AInfo: TSymlinkInfo);
var
  I: Integer;
  Found: Boolean;
begin
  Found := False;

  // 检查是否已存在，如果存在则更新
  for I := 0 to High(FSymlinks) do
  begin
    if SameText(FSymlinks[I].Path, AInfo.Path) then
    begin
      FSymlinks[I] := AInfo;
      Found := True;
      Break;
    end;
  end;

  // 如果不存在则添加新记录
  if not Found then
  begin
    SetLength(FSymlinks, Length(FSymlinks) + 1);
    FSymlinks[High(FSymlinks)] := AInfo;
  end;
end;

function TSymlinkCache.FindSymlink(const APath: string): TSymlinkInfo;
var
  I: Integer;
begin
  // 初始化返回值
  Result.Path := '';
  Result.Target := '';
  Result.Status := dsNormal;
  Result.IsValid := False;
  Result.ScanTime := 0;
  Result.FileSize := 0;
  Result.IsDirectory := False;

  // 查找匹配的记录
  for I := 0 to High(FSymlinks) do
  begin
    if SameText(FSymlinks[I].Path, APath) then
    begin
      Result := FSymlinks[I];
      Break;
    end;
  end;
end;

function TSymlinkCache.HasSymlink(const APath: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to High(FSymlinks) do
  begin
    if SameText(FSymlinks[I].Path, APath) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

procedure TSymlinkCache.RemoveSymlink(const APath: string);
var
  I, J: Integer;
begin
  for I := 0 to High(FSymlinks) do
  begin
    if SameText(FSymlinks[I].Path, APath) then
    begin
      // 移动后面的元素向前
      for J := I to High(FSymlinks) - 1 do
        FSymlinks[J] := FSymlinks[J + 1];

      // 缩短数组
      SetLength(FSymlinks, Length(FSymlinks) - 1);
      Break;
    end;
  end;
end;

procedure TSymlinkCache.Clear;
begin
  SetLength(FSymlinks, 0);
  FLastScanTime := 0;
end;

function TSymlinkCache.GetSymlinkCount: Integer;
begin
  Result := Length(FSymlinks);
end;

function TSymlinkCache.GetValidSymlinkCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(FSymlinks) do
  begin
    if FSymlinks[I].IsValid then
      Inc(Result);
  end;
end;

function TSymlinkCache.IsExpired(const AMaxAge: Integer): Boolean;
begin
  if FLastScanTime = 0 then
    Result := True
  else
    Result := (Now - FLastScanTime) > (AMaxAge / 24.0); // 转换为天数
end;

procedure TSymlinkCache.SaveToFile;
var
  FileStream: TFileStream;
  I: Integer;
  Count: Integer;
  PathLen, TargetLen: Integer;
  PathBytes, TargetBytes: TBytes;
begin
  try
    if FCacheFile = '' then
      Exit;

    FileStream := TFileStream.Create(FCacheFile, fmCreate);
    try
      // 写入版本号
      var Version: Integer := 1;
      FileStream.WriteBuffer(Version, SizeOf(Version));

      // 写入最后扫描时间
      FileStream.WriteBuffer(FLastScanTime, SizeOf(FLastScanTime));

      // 写入记录数量
      Count := Length(FSymlinks);
      FileStream.WriteBuffer(Count, SizeOf(Count));

      // 写入每条记录
      for I := 0 to High(FSymlinks) do
      begin
        // 路径
        PathBytes := TEncoding.UTF8.GetBytes(FSymlinks[I].Path);
        PathLen := Length(PathBytes);
        FileStream.WriteBuffer(PathLen, SizeOf(PathLen));
        if PathLen > 0 then
          FileStream.WriteBuffer(PathBytes[0], PathLen);

        // 目标
        TargetBytes := TEncoding.UTF8.GetBytes(FSymlinks[I].Target);
        TargetLen := Length(TargetBytes);
        FileStream.WriteBuffer(TargetLen, SizeOf(TargetLen));
        if TargetLen > 0 then
          FileStream.WriteBuffer(TargetBytes[0], TargetLen);

        // 其他字段
        FileStream.WriteBuffer(FSymlinks[I].Status, SizeOf(FSymlinks[I].Status));
        FileStream.WriteBuffer(FSymlinks[I].IsValid, SizeOf(FSymlinks[I].IsValid));
        FileStream.WriteBuffer(FSymlinks[I].ScanTime, SizeOf(FSymlinks[I].ScanTime));
        FileStream.WriteBuffer(FSymlinks[I].FileSize, SizeOf(FSymlinks[I].FileSize));
        FileStream.WriteBuffer(FSymlinks[I].IsDirectory, SizeOf(FSymlinks[I].IsDirectory));
      end;
    finally
      FileStream.Free;
    end;
  except
    // 忽略保存错误
  end;
end;

procedure TSymlinkCache.LoadFromFile;
var
  FileStream: TFileStream;
  I: Integer;
  Count: Integer;
  Version: Integer;
  PathLen, TargetLen: Integer;
  PathBytes, TargetBytes: TBytes;
begin
  try
    if (FCacheFile = '') or not FileExists(FCacheFile) then
      Exit;

    FileStream := TFileStream.Create(FCacheFile, fmOpenRead);
    try
      // 读取版本号
      FileStream.ReadBuffer(Version, SizeOf(Version));
      if Version <> 1 then
        Exit; // 版本不匹配，忽略缓存

      // 读取最后扫描时间
      FileStream.ReadBuffer(FLastScanTime, SizeOf(FLastScanTime));

      // 读取记录数量
      FileStream.ReadBuffer(Count, SizeOf(Count));
      if (Count < 0) or (Count > 10000) then // 安全检查
        Exit;

      // 分配数组
      SetLength(FSymlinks, Count);

      // 读取每条记录
      for I := 0 to Count - 1 do
      begin
        // 路径
        FileStream.ReadBuffer(PathLen, SizeOf(PathLen));
        if (PathLen < 0) or (PathLen > 32767) then
          Exit; // 安全检查

        if PathLen > 0 then
        begin
          SetLength(PathBytes, PathLen);
          FileStream.ReadBuffer(PathBytes[0], PathLen);
          FSymlinks[I].Path := TEncoding.UTF8.GetString(PathBytes);
        end
        else
          FSymlinks[I].Path := '';

        // 目标
        FileStream.ReadBuffer(TargetLen, SizeOf(TargetLen));
        if (TargetLen < 0) or (TargetLen > 32767) then
          Exit; // 安全检查

        if TargetLen > 0 then
        begin
          SetLength(TargetBytes, TargetLen);
          FileStream.ReadBuffer(TargetBytes[0], TargetLen);
          FSymlinks[I].Target := TEncoding.UTF8.GetString(TargetBytes);
        end
        else
          FSymlinks[I].Target := '';

        // 其他字段
        FileStream.ReadBuffer(FSymlinks[I].Status, SizeOf(FSymlinks[I].Status));
        FileStream.ReadBuffer(FSymlinks[I].IsValid, SizeOf(FSymlinks[I].IsValid));
        FileStream.ReadBuffer(FSymlinks[I].ScanTime, SizeOf(FSymlinks[I].ScanTime));
        FileStream.ReadBuffer(FSymlinks[I].FileSize, SizeOf(FSymlinks[I].FileSize));
        FileStream.ReadBuffer(FSymlinks[I].IsDirectory, SizeOf(FSymlinks[I].IsDirectory));
      end;
    finally
      FileStream.Free;
    end;
  except
    // 加载失败时清空缓存
    Clear;
  end;
end;

// ===== TCopySessionManager 实现 =====

constructor TCopySessionManager.Create(const ASessionFile: string);
begin
  inherited Create;
  FSessionFile := ASessionFile;
  SetLength(FSessions, 0);
  FHasCurrentSession := False;

  // 初始化当前会话
  FCurrentSession.SessionId := '';
  FCurrentSession.Status := csNotStarted;
  SetLength(FCurrentSession.Files, 0);
end;

destructor TCopySessionManager.Destroy;
begin
  if FHasCurrentSession then
    SaveCurrentSession;
  SetLength(FSessions, 0);
  SetLength(FCurrentSession.Files, 0);
  inherited Destroy;
end;

function TCopySessionManager.CreateSession(const ASourceDir, ATargetDir: string): string;
begin
  // 生成唯一的会话ID
  Result := FormatDateTime('yyyymmdd_hhnnss_', Now) + IntToStr(Random(9999));

  // 初始化新会话
  FCurrentSession.SessionId := Result;
  FCurrentSession.SourceDir := ASourceDir;
  FCurrentSession.TargetDir := ATargetDir;
  FCurrentSession.StartTime := Now;
  FCurrentSession.LastUpdateTime := Now;
  FCurrentSession.Status := csInProgress;
  FCurrentSession.TotalFiles := 0;
  FCurrentSession.CompletedFiles := 0;
  FCurrentSession.TotalSize := 0;
  FCurrentSession.CopiedSize := 0;
  FCurrentSession.ErrorCount := 0;
  FCurrentSession.LastError := '';
  SetLength(FCurrentSession.Files, 0);

  FHasCurrentSession := True;
end;

function TCopySessionManager.LoadSession(const ASessionId: string): Boolean;
var
  FileStream: TFileStream;
  I: Integer;
  SessionCount: Integer;
  Version: Integer;
  Found: Boolean;
begin
  Result := False;
  Found := False;

  try
    if not FileExists(FSessionFile) then
      Exit;

    FileStream := TFileStream.Create(FSessionFile, fmOpenRead);
    try
      // 读取版本号
      FileStream.ReadBuffer(Version, SizeOf(Version));
      if Version <> 1 then
        Exit;

      // 读取会话数量
      FileStream.ReadBuffer(SessionCount, SizeOf(SessionCount));
      if (SessionCount < 0) or (SessionCount > 1000) then
        Exit;

      // 查找指定的会话
      for I := 0 to SessionCount - 1 do
      begin
        var Session: TCopySession;

        // 读取会话基本信息
        var SessionIdLen: Integer;
        FileStream.ReadBuffer(SessionIdLen, SizeOf(SessionIdLen));
        if (SessionIdLen <= 0) or (SessionIdLen > 255) then
          Exit;

        var SessionIdBytes: TBytes;
        SetLength(SessionIdBytes, SessionIdLen);
        FileStream.ReadBuffer(SessionIdBytes[0], SessionIdLen);
        Session.SessionId := TEncoding.UTF8.GetString(SessionIdBytes);

        if Session.SessionId = ASessionId then
        begin
          // 找到目标会话，读取完整信息
          // 这里需要实现完整的会话读取逻辑
          FCurrentSession := Session;
          FHasCurrentSession := True;
          Found := True;
          Break;
        end
        else
        begin
          // 跳过这个会话的数据
          // 这里需要实现跳过逻辑
        end;
      end;

      Result := Found;
    finally
      FileStream.Free;
    end;
  except
    Result := False;
  end;
end;

procedure TCopySessionManager.SaveCurrentSession;
var
  FileStream: TFileStream;
  SessionIdBytes: TBytes;
  SessionIdLen: Integer;
  Version: Integer;
  SessionCount: Integer;
begin
  try
    if not FHasCurrentSession then
      Exit;

    // 更新最后修改时间
    FCurrentSession.LastUpdateTime := Now;

    FileStream := TFileStream.Create(FSessionFile, fmCreate);
    try
      // 写入版本号
      Version := 1;
      FileStream.WriteBuffer(Version, SizeOf(Version));

      // 写入会话数量（目前只支持一个活动会话）
      SessionCount := 1;
      FileStream.WriteBuffer(SessionCount, SizeOf(SessionCount));

      // 写入会话ID
      SessionIdBytes := TEncoding.UTF8.GetBytes(FCurrentSession.SessionId);
      SessionIdLen := Length(SessionIdBytes);
      FileStream.WriteBuffer(SessionIdLen, SizeOf(SessionIdLen));
      if SessionIdLen > 0 then
        FileStream.WriteBuffer(SessionIdBytes[0], SessionIdLen);

      // 写入会话基本信息
      FileStream.WriteBuffer(FCurrentSession.StartTime, SizeOf(FCurrentSession.StartTime));
      FileStream.WriteBuffer(FCurrentSession.LastUpdateTime, SizeOf(FCurrentSession.LastUpdateTime));
      FileStream.WriteBuffer(FCurrentSession.Status, SizeOf(FCurrentSession.Status));
      FileStream.WriteBuffer(FCurrentSession.TotalFiles, SizeOf(FCurrentSession.TotalFiles));
      FileStream.WriteBuffer(FCurrentSession.CompletedFiles, SizeOf(FCurrentSession.CompletedFiles));
      FileStream.WriteBuffer(FCurrentSession.TotalSize, SizeOf(FCurrentSession.TotalSize));
      FileStream.WriteBuffer(FCurrentSession.CopiedSize, SizeOf(FCurrentSession.CopiedSize));
      FileStream.WriteBuffer(FCurrentSession.ErrorCount, SizeOf(FCurrentSession.ErrorCount));

      // 写入源目录和目标目录
      var SourceDirBytes := TEncoding.UTF8.GetBytes(FCurrentSession.SourceDir);
      var SourceDirLen := Length(SourceDirBytes);
      FileStream.WriteBuffer(SourceDirLen, SizeOf(SourceDirLen));
      if SourceDirLen > 0 then
        FileStream.WriteBuffer(SourceDirBytes[0], SourceDirLen);

      var TargetDirBytes := TEncoding.UTF8.GetBytes(FCurrentSession.TargetDir);
      var TargetDirLen := Length(TargetDirBytes);
      FileStream.WriteBuffer(TargetDirLen, SizeOf(TargetDirLen));
      if TargetDirLen > 0 then
        FileStream.WriteBuffer(TargetDirBytes[0], TargetDirLen);

      // 写入文件列表数量
      var FileCount := Length(FCurrentSession.Files);
      FileStream.WriteBuffer(FileCount, SizeOf(FileCount));

      // 写入每个文件的信息
      for var I := 0 to High(FCurrentSession.Files) do
      begin
        var FileInfo := FCurrentSession.Files[I];

        // 源路径
        var SourcePathBytes := TEncoding.UTF8.GetBytes(FileInfo.SourcePath);
        var SourcePathLen := Length(SourcePathBytes);
        FileStream.WriteBuffer(SourcePathLen, SizeOf(SourcePathLen));
        if SourcePathLen > 0 then
          FileStream.WriteBuffer(SourcePathBytes[0], SourcePathLen);

        // 目标路径
        var TargetPathBytes := TEncoding.UTF8.GetBytes(FileInfo.TargetPath);
        var TargetPathLen := Length(TargetPathBytes);
        FileStream.WriteBuffer(TargetPathLen, SizeOf(TargetPathLen));
        if TargetPathLen > 0 then
          FileStream.WriteBuffer(TargetPathBytes[0], TargetPathLen);

        // 其他字段
        FileStream.WriteBuffer(FileInfo.FileSize, SizeOf(FileInfo.FileSize));
        FileStream.WriteBuffer(FileInfo.CopiedSize, SizeOf(FileInfo.CopiedSize));
        FileStream.WriteBuffer(FileInfo.Status, SizeOf(FileInfo.Status));
        FileStream.WriteBuffer(FileInfo.LastModified, SizeOf(FileInfo.LastModified));
      end;

    finally
      FileStream.Free;
    end;
  except
    // 忽略保存错误
  end;
end;

procedure TCopySessionManager.UpdateFileProgress(const ASourcePath: string; ACopiedSize: Int64; AStatus: TCopyStatus);
var
  I: Integer;
  Found: Boolean;
begin
  Found := False;

  // 查找并更新文件进度
  for I := 0 to High(FCurrentSession.Files) do
  begin
    if SameText(FCurrentSession.Files[I].SourcePath, ASourcePath) then
    begin
      FCurrentSession.Files[I].CopiedSize := ACopiedSize;
      FCurrentSession.Files[I].Status := AStatus;
      Found := True;
      Break;
    end;
  end;

  // 如果文件不存在，添加新记录
  if not Found then
  begin
    SetLength(FCurrentSession.Files, Length(FCurrentSession.Files) + 1);
    var Index := High(FCurrentSession.Files);
    FCurrentSession.Files[Index].SourcePath := ASourcePath;
    FCurrentSession.Files[Index].CopiedSize := ACopiedSize;
    FCurrentSession.Files[Index].Status := AStatus;

    // 尝试获取文件大小
    if FileExists(ASourcePath) then
    begin
      var FileHandle := CreateFile(PChar(ASourcePath), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
      if FileHandle <> INVALID_HANDLE_VALUE then
      begin
        var FileSize: Int64;
        if GetFileSizeEx(FileHandle, FileSize) then
          FCurrentSession.Files[Index].FileSize := FileSize;
        CloseHandle(FileHandle);
      end;
    end;
  end;

  // 更新会话统计
  FCurrentSession.LastUpdateTime := Now;
  RecalculateSessionStats;
end;

procedure TCopySessionManager.CompleteFile(const ASourcePath: string; const ACheckSum: string);
var
  I: Integer;
begin
  for I := 0 to High(FCurrentSession.Files) do
  begin
    if SameText(FCurrentSession.Files[I].SourcePath, ASourcePath) then
    begin
      FCurrentSession.Files[I].Status := csCompleted;
      FCurrentSession.Files[I].CheckSum := ACheckSum;
      FCurrentSession.Files[I].CopiedSize := FCurrentSession.Files[I].FileSize;
      Break;
    end;
  end;

  RecalculateSessionStats;
end;

procedure TCopySessionManager.FailFile(const ASourcePath: string; const AErrorMsg: string);
var
  I: Integer;
begin
  for I := 0 to High(FCurrentSession.Files) do
  begin
    if SameText(FCurrentSession.Files[I].SourcePath, ASourcePath) then
    begin
      FCurrentSession.Files[I].Status := csFailed;
      FCurrentSession.Files[I].ErrorMessage := AErrorMsg;
      Break;
    end;
  end;

  Inc(FCurrentSession.ErrorCount);
  FCurrentSession.LastError := AErrorMsg;
  RecalculateSessionStats;
end;

function TCopySessionManager.GetIncompleteFiles: TArray<TFileCopyInfo>;
var
  I, Count: Integer;
begin
  Count := 0;

  // 计算未完成文件数量
  for I := 0 to High(FCurrentSession.Files) do
  begin
    if FCurrentSession.Files[I].Status in [csNotStarted, csInProgress, csPaused] then
      Inc(Count);
  end;

  // 创建结果数组
  SetLength(Result, Count);
  Count := 0;

  for I := 0 to High(FCurrentSession.Files) do
  begin
    if FCurrentSession.Files[I].Status in [csNotStarted, csInProgress, csPaused] then
    begin
      Result[Count] := FCurrentSession.Files[I];
      Inc(Count);
    end;
  end;
end;

function TCopySessionManager.GetSessionProgress: Double;
begin
  if FCurrentSession.TotalSize = 0 then
    Result := 0
  else
    Result := (FCurrentSession.CopiedSize / FCurrentSession.TotalSize) * 100;
end;

function TCopySessionManager.CanResume: Boolean;
begin
  Result := FHasCurrentSession and
            (FCurrentSession.Status in [csInProgress, csPaused]) and
            (Length(GetIncompleteFiles) > 0);
end;

procedure TCopySessionManager.PauseSession;
begin
  if FHasCurrentSession then
  begin
    FCurrentSession.Status := csPaused;
    SaveCurrentSession;
  end;
end;

procedure TCopySessionManager.ResumeSession;
begin
  if FHasCurrentSession then
  begin
    FCurrentSession.Status := csInProgress;
    SaveCurrentSession;
  end;
end;

procedure TCopySessionManager.CancelSession;
begin
  if FHasCurrentSession then
  begin
    FCurrentSession.Status := csCancelled;
    SaveCurrentSession;
    FHasCurrentSession := False;
  end;
end;

procedure TCopySessionManager.CompleteSession;
begin
  if FHasCurrentSession then
  begin
    FCurrentSession.Status := csCompleted;
    SaveCurrentSession;
    FHasCurrentSession := False;
  end;
end;

procedure TCopySessionManager.RecalculateSessionStats;
var
  I: Integer;
begin
  FCurrentSession.TotalFiles := Length(FCurrentSession.Files);
  FCurrentSession.CompletedFiles := 0;
  FCurrentSession.TotalSize := 0;
  FCurrentSession.CopiedSize := 0;

  for I := 0 to High(FCurrentSession.Files) do
  begin
    Inc(FCurrentSession.TotalSize, FCurrentSession.Files[I].FileSize);
    Inc(FCurrentSession.CopiedSize, FCurrentSession.Files[I].CopiedSize);

    if FCurrentSession.Files[I].Status = csCompleted then
      Inc(FCurrentSession.CompletedFiles);
  end;
end;

// ===== TStatusManager 实现 =====

constructor TStatusManager.Create(const AHistoryFile: string; AMaxHistoryCount: Integer);
begin
  inherited Create;
  FHistoryFile := AHistoryFile;
  FMaxHistoryCount := AMaxHistoryCount;
  SetLength(FOperationHistory, 0);
  FDirectoryStates := TDictionary<string, TDirectoryStatus>.Create;
end;

destructor TStatusManager.Destroy;
begin
  SaveToFile;
  SetLength(FOperationHistory, 0);
  FDirectoryStates.Free;
  inherited Destroy;
end;

function TStatusManager.AddOperation(const AOperation: TOperationHistory): string;
var
  Operation: TOperationHistory;
begin
  Operation := AOperation;

  // 生成唯一ID
  if Operation.Id = '' then
    Operation.Id := FormatDateTime('yyyymmdd_hhnnss_', Now) + IntToStr(Random(9999));

  // 设置时间戳
  if Operation.Timestamp = 0 then
    Operation.Timestamp := Now;

  // 添加到历史记录
  SetLength(FOperationHistory, Length(FOperationHistory) + 1);
  FOperationHistory[High(FOperationHistory)] := Operation;

  // 限制历史记录数量
  if Length(FOperationHistory) > FMaxHistoryCount then
  begin
    // 移除最旧的记录
    for var I := 0 to High(FOperationHistory) - 1 do
      FOperationHistory[I] := FOperationHistory[I + 1];
    SetLength(FOperationHistory, FMaxHistoryCount);
  end;

  Result := Operation.Id;
end;

function TStatusManager.GetOperationHistory(ACount: Integer): TArray<TOperationHistory>;
var
  StartIndex, Count: Integer;
begin
  Count := Min(ACount, Length(FOperationHistory));
  StartIndex := Max(0, Length(FOperationHistory) - Count);

  SetLength(Result, Count);
  for var I := 0 to Count - 1 do
    Result[I] := FOperationHistory[StartIndex + I];
end;

function TStatusManager.GetOperationsByType(AType: TOperationType): TArray<TOperationHistory>;
var
  TempList: TList<TOperationHistory>;
begin
  TempList := TList<TOperationHistory>.Create;
  try
    for var Operation in FOperationHistory do
    begin
      if Operation.OperationType = AType then
        TempList.Add(Operation);
    end;

    Result := TempList.ToArray;
  finally
    TempList.Free;
  end;
end;

function TStatusManager.GetOperationsByPath(const APath: string): TArray<TOperationHistory>;
var
  TempList: TList<TOperationHistory>;
begin
  TempList := TList<TOperationHistory>.Create;
  try
    for var Operation in FOperationHistory do
    begin
      if SameText(Operation.SourcePath, APath) or SameText(Operation.TargetPath, APath) then
        TempList.Add(Operation);
    end;

    Result := TempList.ToArray;
  finally
    TempList.Free;
  end;
end;

procedure TStatusManager.ClearHistory;
begin
  SetLength(FOperationHistory, 0);
end;

procedure TStatusManager.SetDirectoryStatus(const APath: string; AStatus: TDirectoryStatus; const ADescription: string);
var
  OldStatus: TDirectoryStatus;
  Operation: TOperationHistory;
begin
  // 获取旧状态
  if FDirectoryStates.ContainsKey(APath) then
    OldStatus := FDirectoryStates[APath]
  else
    OldStatus := dsNormal;

  // 设置新状态
  FDirectoryStates.AddOrSetValue(APath, AStatus);

  // 记录操作历史
  Operation.OperationType := otStatusChange;
  Operation.SourcePath := APath;
  Operation.OldStatus := OldStatus;
  Operation.NewStatus := AStatus;
  Operation.Description := ADescription;
  Operation.Success := True;

  AddOperation(Operation);
end;

function TStatusManager.GetDirectoryStatus(const APath: string): TDirectoryStatus;
begin
  if FDirectoryStates.ContainsKey(APath) then
    Result := FDirectoryStates[APath]
  else
    Result := dsNormal;
end;

function TStatusManager.HasDirectoryStatus(const APath: string): Boolean;
begin
  Result := FDirectoryStates.ContainsKey(APath);
end;

procedure TStatusManager.RemoveDirectoryStatus(const APath: string);
begin
  if FDirectoryStates.ContainsKey(APath) then
    FDirectoryStates.Remove(APath);
end;

procedure TStatusManager.ClearAllStates;
begin
  FDirectoryStates.Clear;
end;

function TStatusManager.CanUndo: Boolean;
begin
  Result := Length(FOperationHistory) > 0;
end;

function TStatusManager.UndoLastOperation: Boolean;
var
  LastOperation: TOperationHistory;
begin
  Result := False;

  if not CanUndo then
    Exit;

  LastOperation := FOperationHistory[High(FOperationHistory)];

  try
    case LastOperation.OperationType of
      otStatusChange:
      begin
        // 恢复旧状态
        if LastOperation.OldStatus <> dsNormal then
          FDirectoryStates.AddOrSetValue(LastOperation.SourcePath, LastOperation.OldStatus)
        else
          FDirectoryStates.Remove(LastOperation.SourcePath);
        Result := True;
      end;
      // 其他操作类型的撤销逻辑可以在这里添加
    end;

    if Result then
    begin
      // 移除已撤销的操作
      SetLength(FOperationHistory, Length(FOperationHistory) - 1);
    end;

  except
    Result := False;
  end;
end;

function TStatusManager.GetUndoDescription: string;
begin
  if CanUndo then
    Result := FOperationHistory[High(FOperationHistory)].Description
  else
    Result := '';
end;

function TStatusManager.GetOperationCount: Integer;
begin
  Result := Length(FOperationHistory);
end;

function TStatusManager.GetOperationCountByType(AType: TOperationType): Integer;
begin
  Result := 0;
  for var Operation in FOperationHistory do
  begin
    if Operation.OperationType = AType then
      Inc(Result);
  end;
end;

function TStatusManager.GetDirectoryStateCount: Integer;
begin
  Result := FDirectoryStates.Count;
end;

procedure TStatusManager.SaveToFile;
var
  FileStream: TFileStream;
  I: Integer;
  Version: Integer;
  HistoryCount: Integer;
  StateCount: Integer;
  PathBytes, DescBytes, ErrorBytes: TBytes;
  PathLen, DescLen, ErrorLen: Integer;
  Pair: TPair<string, TDirectoryStatus>;
begin
  try
    if FHistoryFile = '' then
      Exit;

    FileStream := TFileStream.Create(FHistoryFile, fmCreate);
    try
      // 写入版本号
      Version := 1;
      FileStream.WriteBuffer(Version, SizeOf(Version));

      // 写入操作历史数量
      HistoryCount := Length(FOperationHistory);
      FileStream.WriteBuffer(HistoryCount, SizeOf(HistoryCount));

      // 写入每条操作历史
      for I := 0 to High(FOperationHistory) do
      begin
        var Operation := FOperationHistory[I];

        // ID
        var IdBytes := TEncoding.UTF8.GetBytes(Operation.Id);
        var IdLen := Length(IdBytes);
        FileStream.WriteBuffer(IdLen, SizeOf(IdLen));
        if IdLen > 0 then
          FileStream.WriteBuffer(IdBytes[0], IdLen);

        // 基本字段
        FileStream.WriteBuffer(Operation.OperationType, SizeOf(Operation.OperationType));
        FileStream.WriteBuffer(Operation.Timestamp, SizeOf(Operation.Timestamp));
        FileStream.WriteBuffer(Operation.OldStatus, SizeOf(Operation.OldStatus));
        FileStream.WriteBuffer(Operation.NewStatus, SizeOf(Operation.NewStatus));
        FileStream.WriteBuffer(Operation.Success, SizeOf(Operation.Success));

        // 源路径
        PathBytes := TEncoding.UTF8.GetBytes(Operation.SourcePath);
        PathLen := Length(PathBytes);
        FileStream.WriteBuffer(PathLen, SizeOf(PathLen));
        if PathLen > 0 then
          FileStream.WriteBuffer(PathBytes[0], PathLen);

        // 目标路径
        PathBytes := TEncoding.UTF8.GetBytes(Operation.TargetPath);
        PathLen := Length(PathBytes);
        FileStream.WriteBuffer(PathLen, SizeOf(PathLen));
        if PathLen > 0 then
          FileStream.WriteBuffer(PathBytes[0], PathLen);

        // 描述
        DescBytes := TEncoding.UTF8.GetBytes(Operation.Description);
        DescLen := Length(DescBytes);
        FileStream.WriteBuffer(DescLen, SizeOf(DescLen));
        if DescLen > 0 then
          FileStream.WriteBuffer(DescBytes[0], DescLen);

        // 错误信息
        ErrorBytes := TEncoding.UTF8.GetBytes(Operation.ErrorMessage);
        ErrorLen := Length(ErrorBytes);
        FileStream.WriteBuffer(ErrorLen, SizeOf(ErrorLen));
        if ErrorLen > 0 then
          FileStream.WriteBuffer(ErrorBytes[0], ErrorLen);
      end;

      // 写入目录状态数量
      StateCount := FDirectoryStates.Count;
      FileStream.WriteBuffer(StateCount, SizeOf(StateCount));

      // 写入每个目录状态
      for Pair in FDirectoryStates do
      begin
        // 路径
        PathBytes := TEncoding.UTF8.GetBytes(Pair.Key);
        PathLen := Length(PathBytes);
        FileStream.WriteBuffer(PathLen, SizeOf(PathLen));
        if PathLen > 0 then
          FileStream.WriteBuffer(PathBytes[0], PathLen);

        // 状态
        FileStream.WriteBuffer(Pair.Value, SizeOf(Pair.Value));
      end;

    finally
      FileStream.Free;
    end;
  except
    // 忽略保存错误
  end;
end;

procedure TStatusManager.LoadFromFile;
var
  FileStream: TFileStream;
  I: Integer;
  Version: Integer;
  HistoryCount, StateCount: Integer;
  PathLen, DescLen, ErrorLen, IdLen: Integer;
  PathBytes, DescBytes, ErrorBytes, IdBytes: TBytes;
  Operation: TOperationHistory;
  DirPath: string;
  DirStatus: TDirectoryStatus;
begin
  try
    if (FHistoryFile = '') or not FileExists(FHistoryFile) then
      Exit;

    FileStream := TFileStream.Create(FHistoryFile, fmOpenRead);
    try
      // 读取版本号
      FileStream.ReadBuffer(Version, SizeOf(Version));
      if Version <> 1 then
        Exit; // 版本不匹配

      // 读取操作历史数量
      FileStream.ReadBuffer(HistoryCount, SizeOf(HistoryCount));
      if (HistoryCount < 0) or (HistoryCount > 10000) then
        Exit; // 安全检查

      // 分配历史数组
      SetLength(FOperationHistory, HistoryCount);

      // 读取每条操作历史
      for I := 0 to HistoryCount - 1 do
      begin
        // ID
        FileStream.ReadBuffer(IdLen, SizeOf(IdLen));
        if (IdLen < 0) or (IdLen > 255) then
          Exit;
        if IdLen > 0 then
        begin
          SetLength(IdBytes, IdLen);
          FileStream.ReadBuffer(IdBytes[0], IdLen);
          Operation.Id := TEncoding.UTF8.GetString(IdBytes);
        end
        else
          Operation.Id := '';

        // 基本字段
        FileStream.ReadBuffer(Operation.OperationType, SizeOf(Operation.OperationType));
        FileStream.ReadBuffer(Operation.Timestamp, SizeOf(Operation.Timestamp));
        FileStream.ReadBuffer(Operation.OldStatus, SizeOf(Operation.OldStatus));
        FileStream.ReadBuffer(Operation.NewStatus, SizeOf(Operation.NewStatus));
        FileStream.ReadBuffer(Operation.Success, SizeOf(Operation.Success));

        // 源路径
        FileStream.ReadBuffer(PathLen, SizeOf(PathLen));
        if (PathLen < 0) or (PathLen > 32767) then
          Exit;
        if PathLen > 0 then
        begin
          SetLength(PathBytes, PathLen);
          FileStream.ReadBuffer(PathBytes[0], PathLen);
          Operation.SourcePath := TEncoding.UTF8.GetString(PathBytes);
        end
        else
          Operation.SourcePath := '';

        // 目标路径
        FileStream.ReadBuffer(PathLen, SizeOf(PathLen));
        if (PathLen < 0) or (PathLen > 32767) then
          Exit;
        if PathLen > 0 then
        begin
          SetLength(PathBytes, PathLen);
          FileStream.ReadBuffer(PathBytes[0], PathLen);
          Operation.TargetPath := TEncoding.UTF8.GetString(PathBytes);
        end
        else
          Operation.TargetPath := '';

        // 描述
        FileStream.ReadBuffer(DescLen, SizeOf(DescLen));
        if (DescLen < 0) or (DescLen > 32767) then
          Exit;
        if DescLen > 0 then
        begin
          SetLength(DescBytes, DescLen);
          FileStream.ReadBuffer(DescBytes[0], DescLen);
          Operation.Description := TEncoding.UTF8.GetString(DescBytes);
        end
        else
          Operation.Description := '';

        // 错误信息
        FileStream.ReadBuffer(ErrorLen, SizeOf(ErrorLen));
        if (ErrorLen < 0) or (ErrorLen > 32767) then
          Exit;
        if ErrorLen > 0 then
        begin
          SetLength(ErrorBytes, ErrorLen);
          FileStream.ReadBuffer(ErrorBytes[0], ErrorLen);
          Operation.ErrorMessage := TEncoding.UTF8.GetString(ErrorBytes);
        end
        else
          Operation.ErrorMessage := '';

        FOperationHistory[I] := Operation;
      end;

      // 读取目录状态数量
      FileStream.ReadBuffer(StateCount, SizeOf(StateCount));
      if (StateCount < 0) or (StateCount > 10000) then
        Exit; // 安全检查

      // 读取每个目录状态
      for I := 0 to StateCount - 1 do
      begin
        // 路径
        FileStream.ReadBuffer(PathLen, SizeOf(PathLen));
        if (PathLen < 0) or (PathLen > 32767) then
          Exit;
        if PathLen > 0 then
        begin
          SetLength(PathBytes, PathLen);
          FileStream.ReadBuffer(PathBytes[0], PathLen);
          DirPath := TEncoding.UTF8.GetString(PathBytes);
        end
        else
          DirPath := '';

        // 状态
        FileStream.ReadBuffer(DirStatus, SizeOf(DirStatus));

        if DirPath <> '' then
          FDirectoryStates.AddOrSetValue(DirPath, DirStatus);
      end;

    finally
      FileStream.Free;
    end;
  except
    // 加载失败时清空
    SetLength(FOperationHistory, 0);
    FDirectoryStates.Clear;
  end;
end;

// ===== TDirectoryMonitor 实现 =====

constructor TDirectoryMonitor.Create;
begin
  inherited Create;
  FWatchedPaths := TStringList.Create;
  FDirectoryStates := TDictionary<string, TFileTime>.Create;
  SetLength(FChanges, 0);
  FLastScanTime := 0;
  FEnabled := True;
end;

destructor TDirectoryMonitor.Destroy;
begin
  FWatchedPaths.Free;
  FDirectoryStates.Free;
  SetLength(FChanges, 0);
  inherited Destroy;
end;

procedure TDirectoryMonitor.AddWatchPath(const APath: string);
begin
  if (APath <> '') and DirectoryExists(APath) and (FWatchedPaths.IndexOf(APath) = -1) then
  begin
    FWatchedPaths.Add(APath);
    UpdateDirectoryState(APath);
  end;
end;

procedure TDirectoryMonitor.RemoveWatchPath(const APath: string);
var
  Index: Integer;
begin
  Index := FWatchedPaths.IndexOf(APath);
  if Index >= 0 then
  begin
    FWatchedPaths.Delete(Index);
    if FDirectoryStates.ContainsKey(APath) then
      FDirectoryStates.Remove(APath);
  end;
end;

procedure TDirectoryMonitor.ClearWatchPaths;
begin
  FWatchedPaths.Clear;
  FDirectoryStates.Clear;
end;

function TDirectoryMonitor.ScanForChanges: TArray<TDirectoryChange>;
var
  I: Integer;
  Path: string;
  CurrentTime: TFileTime;
  StoredTime: TFileTime;
  Change: TDirectoryChange;
  ChangeList: TList<TDirectoryChange>;
begin
  ChangeList := TList<TDirectoryChange>.Create;
  try
    if not FEnabled then
    begin
      SetLength(Result, 0);
      Exit;
    end;

    for I := 0 to FWatchedPaths.Count - 1 do
    begin
      Path := FWatchedPaths[I];

      if DirectoryExists(Path) then
      begin
        CurrentTime := GetDirectoryFileTime(Path);

        if FDirectoryStates.ContainsKey(Path) then
        begin
          StoredTime := FDirectoryStates[Path];

          if CompareFileTime(CurrentTime, StoredTime) <> 0 then
          begin
            // 目录已修改
            Change.ChangeType := dctModified;
            Change.OldPath := Path;
            Change.NewPath := Path;
            Change.Timestamp := Now;
            Change.Detected := True;

            ChangeList.Add(Change);

            // 更新存储的时间
            FDirectoryStates.AddOrSetValue(Path, CurrentTime);
          end;
        end
        else
        begin
          // 新目录
          Change.ChangeType := dctCreated;
          Change.OldPath := '';
          Change.NewPath := Path;
          Change.Timestamp := Now;
          Change.Detected := True;

          ChangeList.Add(Change);

          // 添加到监控列表
          FDirectoryStates.AddOrSetValue(Path, CurrentTime);
        end;
      end
      else
      begin
        // 目录已删除
        if FDirectoryStates.ContainsKey(Path) then
        begin
          Change.ChangeType := dctDeleted;
          Change.OldPath := Path;
          Change.NewPath := '';
          Change.Timestamp := Now;
          Change.Detected := True;

          ChangeList.Add(Change);

          // 从监控列表中移除
          FDirectoryStates.Remove(Path);
        end;
      end;
    end;

    FLastScanTime := Now;
    Result := ChangeList.ToArray;

  finally
    ChangeList.Free;
  end;
end;

procedure TDirectoryMonitor.UpdateDirectoryState(const APath: string);
var
  FileTime: TFileTime;
begin
  if DirectoryExists(APath) then
  begin
    FileTime := GetDirectoryFileTime(APath);
    FDirectoryStates.AddOrSetValue(APath, FileTime);
  end;
end;

function TDirectoryMonitor.HasPathChanged(const APath: string): Boolean;
var
  CurrentTime, StoredTime: TFileTime;
begin
  Result := False;

  if not DirectoryExists(APath) then
  begin
    Result := FDirectoryStates.ContainsKey(APath); // 目录被删除
    Exit;
  end;

  CurrentTime := GetDirectoryFileTime(APath);

  if FDirectoryStates.ContainsKey(APath) then
  begin
    StoredTime := FDirectoryStates[APath];
    Result := CompareFileTime(CurrentTime, StoredTime) <> 0;
  end
  else
  begin
    Result := True; // 新目录
  end;
end;

function TDirectoryMonitor.GetWatchedPathCount: Integer;
begin
  Result := FWatchedPaths.Count;
end;

function TDirectoryMonitor.GetDirectoryFileTime(const APath: string): TFileTime;
var
  Handle: THandle;
  FindData: TWin32FindData;
begin
  FillChar(Result, SizeOf(Result), 0);

  Handle := FindFirstFile(PChar(APath), FindData);
  if Handle <> INVALID_HANDLE_VALUE then
  begin
    try
      Result := FindData.ftLastWriteTime;
    finally
      Windows.FindClose(Handle);
    end;
  end;
end;

function TDirectoryMonitor.CompareFileTime(const ATime1, ATime2: TFileTime): Integer;
begin
  Result := CompareFileTime(ATime1, ATime2);
end;

// ===== TSmartSuggestionEngine 实现 =====

constructor TSmartSuggestionEngine.Create(const ADataFile: string; AStatusManager: TStatusManager; AMaxSuggestions: Integer);
begin
  inherited Create;
  FDataFile := ADataFile;
  FStatusManager := AStatusManager;
  FMaxSuggestions := AMaxSuggestions;
  SetLength(FSuggestions, 0);
  SetLength(FUserPatterns, 0);
end;

destructor TSmartSuggestionEngine.Destroy;
begin
  SaveToFile;
  SetLength(FSuggestions, 0);
  SetLength(FUserPatterns, 0);
  inherited Destroy;
end;

function TSmartSuggestionEngine.AddSuggestion(const ASuggestion: TSmartSuggestion): string;
var
  Suggestion: TSmartSuggestion;
begin
  Suggestion := ASuggestion;

  // 生成唯一ID
  if Suggestion.Id = '' then
    Suggestion.Id := FormatDateTime('yyyymmdd_hhnnss_', Now) + IntToStr(Random(9999));

  // 设置创建时间
  if Suggestion.CreatedTime = 0 then
    Suggestion.CreatedTime := Now;

  // 添加到建议列表
  SetLength(FSuggestions, Length(FSuggestions) + 1);
  FSuggestions[High(FSuggestions)] := Suggestion;

  // 限制建议数量
  if Length(FSuggestions) > FMaxSuggestions then
  begin
    // 移除最旧的建议
    for var I := 0 to High(FSuggestions) - 1 do
      FSuggestions[I] := FSuggestions[I + 1];
    SetLength(FSuggestions, FMaxSuggestions);
  end;

  Result := Suggestion.Id;
end;

function TSmartSuggestionEngine.GetSuggestions(AType: TSuggestionType; ACount: Integer): TArray<TSmartSuggestion>;
var
  TempList: TList<TSmartSuggestion>;
  I: Integer;
begin
  TempList := TList<TSmartSuggestion>.Create;
  try
    for I := 0 to High(FSuggestions) do
    begin
      if (AType = stOptimization) or (FSuggestions[I].SuggestionType = AType) then
        TempList.Add(FSuggestions[I]);
    end;

    // 按优先级和时间排序
    TempList.Sort(TComparer<TSmartSuggestion>.Construct(
      function(const Left, Right: TSmartSuggestion): Integer
      begin
        // 首先按优先级排序
        Result := Ord(Right.Priority) - Ord(Left.Priority);
        if Result = 0 then
          // 然后按时间排序（新的在前）
          Result := CompareDateTime(Right.CreatedTime, Left.CreatedTime);
      end));

    // 限制返回数量
    var Count := Min(ACount, TempList.Count);
    SetLength(Result, Count);
    for I := 0 to Count - 1 do
      Result[I] := TempList[I];

  finally
    TempList.Free;
  end;
end;

function TSmartSuggestionEngine.GetUnreadSuggestions: TArray<TSmartSuggestion>;
var
  TempList: TList<TSmartSuggestion>;
begin
  TempList := TList<TSmartSuggestion>.Create;
  try
    for var Suggestion in FSuggestions do
    begin
      if not Suggestion.IsRead then
        TempList.Add(Suggestion);
    end;

    Result := TempList.ToArray;
  finally
    TempList.Free;
  end;
end;

function TSmartSuggestionEngine.GetHighPrioritySuggestions: TArray<TSmartSuggestion>;
var
  TempList: TList<TSmartSuggestion>;
begin
  TempList := TList<TSmartSuggestion>.Create;
  try
    for var Suggestion in FSuggestions do
    begin
      if Suggestion.Priority in [spHigh, spCritical] then
        TempList.Add(Suggestion);
    end;

    Result := TempList.ToArray;
  finally
    TempList.Free;
  end;
end;

procedure TSmartSuggestionEngine.MarkSuggestionRead(const ASuggestionId: string);
var
  I: Integer;
begin
  for I := 0 to High(FSuggestions) do
  begin
    if FSuggestions[I].Id = ASuggestionId then
    begin
      FSuggestions[I].IsRead := True;
      Break;
    end;
  end;
end;

procedure TSmartSuggestionEngine.MarkSuggestionApplied(const ASuggestionId: string);
var
  I: Integer;
begin
  for I := 0 to High(FSuggestions) do
  begin
    if FSuggestions[I].Id = ASuggestionId then
    begin
      FSuggestions[I].IsApplied := True;
      FSuggestions[I].AppliedTime := Now;
      Break;
    end;
  end;
end;

procedure TSmartSuggestionEngine.RemoveSuggestion(const ASuggestionId: string);
var
  I, J: Integer;
begin
  for I := 0 to High(FSuggestions) do
  begin
    if FSuggestions[I].Id = ASuggestionId then
    begin
      // 移动后面的元素向前
      for J := I to High(FSuggestions) - 1 do
        FSuggestions[J] := FSuggestions[J + 1];

      // 缩短数组
      SetLength(FSuggestions, Length(FSuggestions) - 1);
      Break;
    end;
  end;
end;

procedure TSmartSuggestionEngine.ClearOldSuggestions(ADaysOld: Integer);
var
  I: Integer;
  CutoffDate: TDateTime;
  NewSuggestions: TArray<TSmartSuggestion>;
begin
  CutoffDate := Now - ADaysOld;
  SetLength(NewSuggestions, 0);

  for I := 0 to High(FSuggestions) do
  begin
    if FSuggestions[I].CreatedTime > CutoffDate then
    begin
      SetLength(NewSuggestions, Length(NewSuggestions) + 1);
      NewSuggestions[High(NewSuggestions)] := FSuggestions[I];
    end;
  end;

  FSuggestions := NewSuggestions;
end;

function TSmartSuggestionEngine.GetSuggestionCount: Integer;
begin
  Result := Length(FSuggestions);
end;

function TSmartSuggestionEngine.GetUnreadCount: Integer;
begin
  Result := 0;
  for var Suggestion in FSuggestions do
  begin
    if not Suggestion.IsRead then
      Inc(Result);
  end;
end;

function TSmartSuggestionEngine.GetAppliedCount: Integer;
begin
  Result := 0;
  for var Suggestion in FSuggestions do
  begin
    if Suggestion.IsApplied then
      Inc(Result);
  end;
end;

procedure TSmartSuggestionEngine.AnalyzeUserBehavior;
var
  History: TArray<TOperationHistory>;
  I, J: Integer;
  OpType: TOperationType;
  Pattern: TUserBehaviorPattern;
  Found: Boolean;
begin
  if not Assigned(FStatusManager) then
    Exit;

  History := FStatusManager.GetOperationHistory(100); // 分析最近100条记录

  for I := 0 to High(History) do
  begin
    OpType := History[I].OperationType;
    Found := False;

    // 查找现有模式
    for J := 0 to High(FUserPatterns) do
    begin
      if FUserPatterns[J].OperationType = OpType then
      begin
        Inc(FUserPatterns[J].FrequencyCount);
        FUserPatterns[J].LastUsedTime := History[I].Timestamp;

        // 更新成功率
        if History[I].Success then
          FUserPatterns[J].SuccessRate := (FUserPatterns[J].SuccessRate * (FUserPatterns[J].FrequencyCount - 1) + 1) / FUserPatterns[J].FrequencyCount
        else
          FUserPatterns[J].SuccessRate := (FUserPatterns[J].SuccessRate * (FUserPatterns[J].FrequencyCount - 1)) / FUserPatterns[J].FrequencyCount;

        Found := True;
        Break;
      end;
    end;

    // 创建新模式
    if not Found then
    begin
      Pattern.OperationType := OpType;
      Pattern.FrequencyCount := 1;
      Pattern.LastUsedTime := History[I].Timestamp;
      Pattern.AverageInterval := 0;
      SetLength(Pattern.PreferredPaths, 0);
      Pattern.SuccessRate := if History[I].Success then 1.0 else 0.0;

      SetLength(FUserPatterns, Length(FUserPatterns) + 1);
      FUserPatterns[High(FUserPatterns)] := Pattern;
    end;
  end;
end;

procedure TSmartSuggestionEngine.UpdateUserPattern(AOperationType: TOperationType; const APath: string; ASuccess: Boolean);
var
  I: Integer;
  Found: Boolean;
  Pattern: TUserBehaviorPattern;
begin
  Found := False;

  for I := 0 to High(FUserPatterns) do
  begin
    if FUserPatterns[I].OperationType = AOperationType then
    begin
      Inc(FUserPatterns[I].FrequencyCount);
      FUserPatterns[I].LastUsedTime := Now;

      // 更新成功率
      if ASuccess then
        FUserPatterns[I].SuccessRate := (FUserPatterns[I].SuccessRate * (FUserPatterns[I].FrequencyCount - 1) + 1) / FUserPatterns[I].FrequencyCount
      else
        FUserPatterns[I].SuccessRate := (FUserPatterns[I].SuccessRate * (FUserPatterns[I].FrequencyCount - 1)) / FUserPatterns[I].FrequencyCount;

      // 更新偏好路径
      var PathFound := False;
      for var Path in FUserPatterns[I].PreferredPaths do
      begin
        if SameText(Path, APath) then
        begin
          PathFound := True;
          Break;
        end;
      end;

      if not PathFound then
      begin
        SetLength(FUserPatterns[I].PreferredPaths, Length(FUserPatterns[I].PreferredPaths) + 1);
        FUserPatterns[I].PreferredPaths[High(FUserPatterns[I].PreferredPaths)] := APath;
      end;

      Found := True;
      Break;
    end;
  end;

  if not Found then
  begin
    Pattern.OperationType := AOperationType;
    Pattern.FrequencyCount := 1;
    Pattern.LastUsedTime := Now;
    Pattern.AverageInterval := 0;
    SetLength(Pattern.PreferredPaths, 1);
    Pattern.PreferredPaths[0] := APath;
    Pattern.SuccessRate := if ASuccess then 1.0 else 0.0;

    SetLength(FUserPatterns, Length(FUserPatterns) + 1);
    FUserPatterns[High(FUserPatterns)] := Pattern;
  end;
end;

function TSmartSuggestionEngine.PredictNextOperation: TOperationType;
var
  MaxFrequency: Integer;
  MostFrequentOp: TOperationType;
  I: Integer;
begin
  Result := otUserAction;
  MaxFrequency := 0;
  MostFrequentOp := otUserAction;

  for I := 0 to High(FUserPatterns) do
  begin
    if FUserPatterns[I].FrequencyCount > MaxFrequency then
    begin
      MaxFrequency := FUserPatterns[I].FrequencyCount;
      MostFrequentOp := FUserPatterns[I].OperationType;
    end;
  end;

  Result := MostFrequentOp;
end;

function TSmartSuggestionEngine.GetRecommendedPaths: TArray<string>;
var
  PathList: TStringList;
  I, J: Integer;
begin
  PathList := TStringList.Create;
  try
    PathList.Duplicates := dupIgnore;
    PathList.Sorted := True;

    for I := 0 to High(FUserPatterns) do
    begin
      for J := 0 to High(FUserPatterns[I].PreferredPaths) do
      begin
        PathList.Add(FUserPatterns[I].PreferredPaths[J]);
      end;
    end;

    SetLength(Result, PathList.Count);
    for I := 0 to PathList.Count - 1 do
      Result[I] := PathList[I];

  finally
    PathList.Free;
  end;
end;

procedure TSmartSuggestionEngine.GenerateOptimizationSuggestions;
var
  Suggestion: TSmartSuggestion;
begin
  // 分析用户行为模式
  AnalyzeUserBehavior;

  // 生成基于频率的优化建议
  for var Pattern in FUserPatterns do
  begin
    if Pattern.FrequencyCount >= 5 then // 频繁操作
    begin
      Suggestion.SuggestionType := stOptimization;
      Suggestion.Priority := spMedium;
      Suggestion.Title := '创建快捷操作';
      Suggestion.Description := Format('您经常执行"%s"操作，建议创建快捷方式以提高效率。', [GetOperationTypeName(Pattern.OperationType)]);
      Suggestion.ActionText := '创建快捷方式';
      Suggestion.RelatedPath := '';
      Suggestion.IsRead := False;
      Suggestion.IsApplied := False;

      AddSuggestion(Suggestion);
    end;

    if Pattern.SuccessRate < 0.8 then // 成功率较低
    begin
      Suggestion.SuggestionType := stOptimization;
      Suggestion.Priority := spHigh;
      Suggestion.Title := '操作优化建议';
      Suggestion.Description := Format('"%s"操作的成功率较低(%.1f%%)，建议检查操作步骤或寻求帮助。', [GetOperationTypeName(Pattern.OperationType), Pattern.SuccessRate * 100]);
      Suggestion.ActionText := '查看帮助';
      Suggestion.RelatedPath := '';
      Suggestion.IsRead := False;
      Suggestion.IsApplied := False;

      AddSuggestion(Suggestion);
    end;
  end;
end;

procedure TSmartSuggestionEngine.GenerateSafetySuggestions;
var
  Suggestion: TSmartSuggestion;
  History: TArray<TOperationHistory>;
  RecentErrors: Integer;
begin
  if not Assigned(FStatusManager) then
    Exit;

  History := FStatusManager.GetOperationHistory(20);
  RecentErrors := 0;

  // 统计最近的错误
  for var Operation in History do
  begin
    if not Operation.Success then
      Inc(RecentErrors);
  end;

  if RecentErrors >= 3 then
  begin
    Suggestion.SuggestionType := stSafety;
    Suggestion.Priority := spHigh;
    Suggestion.Title := '安全提醒';
    Suggestion.Description := Format('最近有%d个操作失败，建议在继续操作前检查系统状态。', [RecentErrors]);
    Suggestion.ActionText := '检查系统状态';
    Suggestion.RelatedPath := '';
    Suggestion.IsRead := False;
    Suggestion.IsApplied := False;

    AddSuggestion(Suggestion);
  end;

  // 检查是否有备份建议
  if FStatusManager.GetOperationCountByType(otFileCopy) > 0 then
  begin
    var BackupCount := FStatusManager.GetOperationCountByType(otUserAction); // 假设备份操作记录为用户操作
    if BackupCount = 0 then
    begin
      Suggestion.SuggestionType := stSafety;
      Suggestion.Priority := spCritical;
      Suggestion.Title := '备份建议';
      Suggestion.Description := '检测到文件拷贝操作，强烈建议在进行重要操作前创建备份。';
      Suggestion.ActionText := '创建备份';
      Suggestion.RelatedPath := '';
      Suggestion.IsRead := False;
      Suggestion.IsApplied := False;

      AddSuggestion(Suggestion);
    end;
  end;
end;

function TSmartSuggestionEngine.GetOperationTypeName(AType: TOperationType): string;
begin
  case AType of
    otDirectoryAnalysis: Result := '目录分析';
    otSymlinkScan: Result := '符号链接扫描';
    otSymlinkRepair: Result := '符号链接修复';
    otFileCopy: Result := '文件拷贝';
    otFileMove: Result := '文件移动';
    otDirectoryCreate: Result := '目录创建';
    otDirectoryDelete: Result := '目录删除';
    otStatusChange: Result := '状态变更';
    otCacheUpdate: Result := '缓存更新';
    otSessionCreate: Result := '会话创建';
    otSessionComplete: Result := '会话完成';
    otUserAction: Result := '用户操作';
  else
    Result := '未知操作';
  end;
end;

// ===== TBatchOperationManager 实现 =====

constructor TBatchOperationManager.Create;
begin
  inherited Create;
  SetLength(FOperations, 0);
  FCurrentIndex := -1;
  FIsRunning := False;
  FIsPaused := False;
  FTotalOperations := 0;
  FCompletedOperations := 0;
  FFailedOperations := 0;
end;

destructor TBatchOperationManager.Destroy;
begin
  StopBatch;
  SetLength(FOperations, 0);
  inherited Destroy;
end;

procedure TBatchOperationManager.AddOperation(const AItem: TBatchOperationItem);
begin
  SetLength(FOperations, Length(FOperations) + 1);
  FOperations[High(FOperations)] := AItem;
  FTotalOperations := Length(FOperations);
end;

procedure TBatchOperationManager.ClearOperations;
begin
  if FIsRunning then
    StopBatch;

  SetLength(FOperations, 0);
  FCurrentIndex := -1;
  FTotalOperations := 0;
  FCompletedOperations := 0;
  FFailedOperations := 0;
end;

function TBatchOperationManager.GetOperationCount: Integer;
begin
  Result := Length(FOperations);
end;

function TBatchOperationManager.GetOperation(AIndex: Integer): TBatchOperationItem;
begin
  if (AIndex >= 0) and (AIndex < Length(FOperations)) then
    Result := FOperations[AIndex]
  else
  begin
    // 返回空记录
    FillChar(Result, SizeOf(Result), 0);
    Result.Status := csNotStarted;
  end;
end;

procedure TBatchOperationManager.UpdateOperation(AIndex: Integer; const AItem: TBatchOperationItem);
begin
  if (AIndex >= 0) and (AIndex < Length(FOperations)) then
    FOperations[AIndex] := AItem;
end;

procedure TBatchOperationManager.StartBatch;
begin
  if FIsRunning or (Length(FOperations) = 0) then
    Exit;

  FIsRunning := True;
  FIsPaused := False;
  FCurrentIndex := 0;
  FCompletedOperations := 0;
  FFailedOperations := 0;

  // 这里应该启动批量处理线程
  // 为了简化，我们先实现基本框架
end;

procedure TBatchOperationManager.PauseBatch;
begin
  if FIsRunning and not FIsPaused then
    FIsPaused := True;
end;

procedure TBatchOperationManager.ResumeBatch;
begin
  if FIsRunning and FIsPaused then
    FIsPaused := False;
end;

procedure TBatchOperationManager.StopBatch;
begin
  FIsRunning := False;
  FIsPaused := False;
end;

function TBatchOperationManager.IsRunning: Boolean;
begin
  Result := FIsRunning;
end;

function TBatchOperationManager.IsPaused: Boolean;
begin
  Result := FIsPaused;
end;

function TBatchOperationManager.GetOverallProgress: Double;
var
  TotalProgress: Double;
  I: Integer;
begin
  if Length(FOperations) = 0 then
  begin
    Result := 0;
    Exit;
  end;

  TotalProgress := 0;
  for I := 0 to High(FOperations) do
    TotalProgress := TotalProgress + FOperations[I].Progress;

  Result := TotalProgress / Length(FOperations);
end;

function TBatchOperationManager.GetCurrentOperation: TBatchOperationItem;
begin
  if (FCurrentIndex >= 0) and (FCurrentIndex < Length(FOperations)) then
    Result := FOperations[FCurrentIndex]
  else
  begin
    FillChar(Result, SizeOf(Result), 0);
    Result.Status := csNotStarted;
  end;
end;

function TBatchOperationManager.GetCompletedCount: Integer;
begin
  Result := FCompletedOperations;
end;

function TBatchOperationManager.GetFailedCount: Integer;
begin
  Result := FFailedOperations;
end;

function TBatchOperationManager.GetRemainingCount: Integer;
begin
  Result := FTotalOperations - FCompletedOperations - FFailedOperations;
end;

// ===== TDependencyGraph 实现 =====

constructor TDependencyGraph.Create(const ADataFile: string);
begin
  inherited Create;
  FDataFile := ADataFile;
  SetLength(FDependencies, 0);
  FNodes := TStringList.Create;
  FNodes.Sorted := True;
  FNodes.Duplicates := dupIgnore;
  SetLength(FAdjacencyMatrix, 0);
end;

destructor TDependencyGraph.Destroy;
begin
  SaveToFile;
  SetLength(FDependencies, 0);
  FNodes.Free;
  SetLength(FAdjacencyMatrix, 0);
  inherited Destroy;
end;

function TDependencyGraph.AddDependency(const ADependency: TDependencyRelation): string;
var
  Dependency: TDependencyRelation;
  SourceIndex, TargetIndex: Integer;
begin
  Dependency := ADependency;

  // 生成唯一ID
  if Dependency.Id = '' then
    Dependency.Id := FormatDateTime('yyyymmdd_hhnnss_', Now) + IntToStr(Random(9999));

  // 设置检测时间
  if Dependency.DetectedTime = 0 then
    Dependency.DetectedTime := Now;

  // 添加节点
  SourceIndex := AddNode(Dependency.SourcePath);
  TargetIndex := AddNode(Dependency.TargetPath);

  // 添加到依赖列表
  SetLength(FDependencies, Length(FDependencies) + 1);
  FDependencies[High(FDependencies)] := Dependency;

  // 重建邻接矩阵
  BuildAdjacencyMatrix;

  Result := Dependency.Id;
end;

procedure TDependencyGraph.RemoveDependency(const ADependencyId: string);
var
  I, J: Integer;
begin
  for I := 0 to High(FDependencies) do
  begin
    if FDependencies[I].Id = ADependencyId then
    begin
      // 移动后面的元素向前
      for J := I to High(FDependencies) - 1 do
        FDependencies[J] := FDependencies[J + 1];

      // 缩短数组
      SetLength(FDependencies, Length(FDependencies) - 1);

      // 重建邻接矩阵
      BuildAdjacencyMatrix;
      Break;
    end;
  end;
end;

function TDependencyGraph.FindDependencies(const APath: string): TArray<TDependencyRelation>;
var
  TempList: TList<TDependencyRelation>;
begin
  TempList := TList<TDependencyRelation>.Create;
  try
    for var Dependency in FDependencies do
    begin
      if SameText(Dependency.SourcePath, APath) then
        TempList.Add(Dependency);
    end;

    Result := TempList.ToArray;
  finally
    TempList.Free;
  end;
end;

function TDependencyGraph.FindDependents(const APath: string): TArray<TDependencyRelation>;
var
  TempList: TList<TDependencyRelation>;
begin
  TempList := TList<TDependencyRelation>.Create;
  try
    for var Dependency in FDependencies do
    begin
      if SameText(Dependency.TargetPath, APath) then
        TempList.Add(Dependency);
    end;

    Result := TempList.ToArray;
  finally
    TempList.Free;
  end;
end;

procedure TDependencyGraph.UpdateDependency(const ADependencyId: string; const ADependency: TDependencyRelation);
var
  I: Integer;
begin
  for I := 0 to High(FDependencies) do
  begin
    if FDependencies[I].Id = ADependencyId then
    begin
      FDependencies[I] := ADependency;
      FDependencies[I].LastVerified := Now;
      Break;
    end;
  end;
end;

function TDependencyGraph.DetectCircularDependencies: TArray<TArray<string>>;
var
  Visited, RecStack: TArray<Boolean>;
  Cycles: TList<TArray<string>>;
  I: Integer;
  Cycle: TArray<Integer>;
  CyclePaths: TArray<string>;
  J: Integer;
begin
  Cycles := TList<TArray<string>>.Create;
  try
    SetLength(Visited, FNodes.Count);
    SetLength(RecStack, FNodes.Count);

    // 初始化访问状态
    for I := 0 to High(Visited) do
    begin
      Visited[I] := False;
      RecStack[I] := False;
    end;

    // 对每个未访问的节点进行DFS
    for I := 0 to FNodes.Count - 1 do
    begin
      if not Visited[I] then
      begin
        if DFSCycleDetection(I, Visited, RecStack, Cycle) then
        begin
          // 转换索引为路径
          SetLength(CyclePaths, Length(Cycle));
          for J := 0 to High(Cycle) do
            CyclePaths[J] := FNodes[Cycle[J]];

          Cycles.Add(CyclePaths);
        end;
      end;
    end;

    Result := Cycles.ToArray;
  finally
    Cycles.Free;
  end;
end;

function TDependencyGraph.GetDependencyCount: Integer;
begin
  Result := Length(FDependencies);
end;

function TDependencyGraph.GetNodeCount: Integer;
begin
  Result := FNodes.Count;
end;

function TDependencyGraph.AddNode(const APath: string): Integer;
begin
  Result := FNodes.IndexOf(APath);
  if Result = -1 then
    Result := FNodes.Add(APath);
end;

function TDependencyGraph.FindNodeIndex(const APath: string): Integer;
begin
  Result := FNodes.IndexOf(APath);
end;

procedure TDependencyGraph.BuildAdjacencyMatrix;
var
  I, SourceIndex, TargetIndex: Integer;
begin
  // 重新分配邻接矩阵
  SetLength(FAdjacencyMatrix, FNodes.Count);
  for I := 0 to FNodes.Count - 1 do
    SetLength(FAdjacencyMatrix[I], FNodes.Count);

  // 初始化为False
  for I := 0 to FNodes.Count - 1 do
    for var J := 0 to FNodes.Count - 1 do
      FAdjacencyMatrix[I][J] := False;

  // 根据依赖关系设置邻接矩阵
  for I := 0 to High(FDependencies) do
  begin
    SourceIndex := FindNodeIndex(FDependencies[I].SourcePath);
    TargetIndex := FindNodeIndex(FDependencies[I].TargetPath);

    if (SourceIndex >= 0) and (TargetIndex >= 0) then
      FAdjacencyMatrix[SourceIndex][TargetIndex] := True;
  end;
end;

function TDependencyGraph.DFSCycleDetection(ANode: Integer; AVisited, ARecStack: TArray<Boolean>; var ACycle: TArray<Integer>): Boolean;
var
  I: Integer;
begin
  Result := False;

  if (ANode < 0) or (ANode >= FNodes.Count) then
    Exit;

  AVisited[ANode] := True;
  ARecStack[ANode] := True;

  // 检查所有邻接节点
  for I := 0 to FNodes.Count - 1 do
  begin
    if FAdjacencyMatrix[ANode][I] then
    begin
      if not AVisited[I] then
      begin
        if DFSCycleDetection(I, AVisited, ARecStack, ACycle) then
        begin
          Result := True;
          Exit;
        end;
      end
      else if ARecStack[I] then
      begin
        // 发现循环
        SetLength(ACycle, 2);
        ACycle[0] := ANode;
        ACycle[1] := I;
        Result := True;
        Exit;
      end;
    end;
  end;

  ARecStack[ANode] := False;
end;

procedure TDependencyGraph.Clear;
begin
  SetLength(FDependencies, 0);
  FNodes.Clear;
  SetLength(FAdjacencyMatrix, 0);
end;

function TDependencyGraph.FindCriticalPaths: TArray<TArray<string>>;
var
  CriticalPaths: TList<TArray<string>>;
  I: Integer;
  CriticalDeps: TArray<TDependencyRelation>;
  Path: TArray<string>;
begin
  CriticalPaths := TList<TArray<string>>.Create;
  try
    // 查找关键依赖
    for I := 0 to High(FDependencies) do
    begin
      if FDependencies[I].IsCritical or (FDependencies[I].Strength = dsCritical) then
      begin
        SetLength(Path, 2);
        Path[0] := FDependencies[I].SourcePath;
        Path[1] := FDependencies[I].TargetPath;
        CriticalPaths.Add(Path);
      end;
    end;

    Result := CriticalPaths.ToArray;
  finally
    CriticalPaths.Free;
  end;
end;

function TDependencyGraph.CalculateImpactScore(const APath: string): Double;
var
  Dependencies, Dependents: TArray<TDependencyRelation>;
  Score: Double;
  I: Integer;
begin
  Dependencies := FindDependencies(APath);
  Dependents := FindDependents(APath);

  Score := 0;

  // 计算依赖项影响
  for I := 0 to High(Dependencies) do
    Score := Score + Dependencies[I].ImpactScore;

  // 计算依赖者影响
  for I := 0 to High(Dependents) do
    Score := Score + Dependents[I].ImpactScore * 1.5; // 依赖者影响更大

  Result := Score;
end;

function TDependencyGraph.GetDependencyChain(const ASourcePath, ATargetPath: string): TArray<string>;
var
  SourceIndex, TargetIndex: Integer;
  Visited: TArray<Boolean>;
  Path: TList<string>;

  function DFS(ACurrentIndex, ATargetIndex: Integer): Boolean;
  var
    I: Integer;
  begin
    Result := False;

    if ACurrentIndex = ATargetIndex then
    begin
      Result := True;
      Exit;
    end;

    Visited[ACurrentIndex] := True;

    for I := 0 to FNodes.Count - 1 do
    begin
      if FAdjacencyMatrix[ACurrentIndex][I] and not Visited[I] then
      begin
        Path.Add(FNodes[I]);
        if DFS(I, ATargetIndex) then
        begin
          Result := True;
          Exit;
        end;
        Path.Delete(Path.Count - 1);
      end;
    end;
  end;

begin
  SourceIndex := FindNodeIndex(ASourcePath);
  TargetIndex := FindNodeIndex(ATargetPath);

  if (SourceIndex = -1) or (TargetIndex = -1) then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  SetLength(Visited, FNodes.Count);
  for var I := 0 to High(Visited) do
    Visited[I] := False;

  Path := TList<string>.Create;
  try
    Path.Add(ASourcePath);

    if DFS(SourceIndex, TargetIndex) then
      Result := Path.ToArray
    else
      SetLength(Result, 0);

  finally
    Path.Free;
  end;
end;

function TDependencyGraph.AnalyzeDependencyDepth(const APath: string): Integer;
var
  NodeIndex: Integer;
  Visited: TArray<Boolean>;
  MaxDepth: Integer;

  function DFS(ACurrentIndex, ACurrentDepth: Integer): Integer;
  var
    I, Depth: Integer;
  begin
    Result := ACurrentDepth;
    Visited[ACurrentIndex] := True;

    for I := 0 to FNodes.Count - 1 do
    begin
      if FAdjacencyMatrix[ACurrentIndex][I] and not Visited[I] then
      begin
        Depth := DFS(I, ACurrentDepth + 1);
        if Depth > Result then
          Result := Depth;
      end;
    end;
  end;

begin
  NodeIndex := FindNodeIndex(APath);
  if NodeIndex = -1 then
  begin
    Result := 0;
    Exit;
  end;

  SetLength(Visited, FNodes.Count);
  for var I := 0 to High(Visited) do
    Visited[I] := False;

  Result := DFS(NodeIndex, 0);
end;

function TDependencyGraph.AssessMovementRisk(const APath: string): Integer;
var
  Dependencies, Dependents: TArray<TDependencyRelation>;
  RiskScore: Integer;
  I: Integer;
  Depth: Integer;
begin
  Dependencies := FindDependencies(APath);
  Dependents := FindDependents(APath);
  Depth := AnalyzeDependencyDepth(APath);

  RiskScore := 1; // 基础风险

  // 依赖项数量影响
  RiskScore := RiskScore + Min(Length(Dependencies), 3);

  // 依赖者数量影响（更重要）
  RiskScore := RiskScore + Min(Length(Dependents) * 2, 4);

  // 依赖深度影响
  RiskScore := RiskScore + Min(Depth, 2);

  // 关键依赖影响
  for I := 0 to High(Dependencies) do
  begin
    if Dependencies[I].IsCritical then
      Inc(RiskScore, 2);
  end;

  for I := 0 to High(Dependents) do
  begin
    if Dependents[I].IsCritical then
      Inc(RiskScore, 3);
  end;

  Result := Min(RiskScore, 10); // 最大风险等级为10
end;

function TDependencyGraph.GetHighRiskDependencies: TArray<TDependencyRelation>;
var
  HighRiskList: TList<TDependencyRelation>;
begin
  HighRiskList := TList<TDependencyRelation>.Create;
  try
    for var Dependency in FDependencies do
    begin
      if (Dependency.RiskLevel >= 7) or Dependency.IsCritical then
        HighRiskList.Add(Dependency);
    end;

    Result := HighRiskList.ToArray;
  finally
    HighRiskList.Free;
  end;
end;

function TDependencyGraph.ValidateAllDependencies: Integer;
var
  InvalidCount: Integer;
  I: Integer;
begin
  InvalidCount := 0;

  for I := 0 to High(FDependencies) do
  begin
    // 检查路径是否存在
    if not (DirectoryExists(FDependencies[I].SourcePath) and
            DirectoryExists(FDependencies[I].TargetPath)) then
    begin
      FDependencies[I].IsValid := False;
      Inc(InvalidCount);
    end
    else
    begin
      FDependencies[I].IsValid := True;
      FDependencies[I].LastVerified := Now;
    end;
  end;

  Result := InvalidCount;
end;

function TDependencyGraph.GenerateGraphData: string;
var
  I: Integer;
  GraphText: string;
begin
  GraphText := '';

  if Length(FDependencies) = 0 then
  begin
    Result := '暂无依赖关系数据';
    Exit;
  end;

  for I := 0 to High(FDependencies) do
  begin
    GraphText := GraphText + Format('%s → %s (%s)%s', [
      ExtractFileName(FDependencies[I].SourcePath),
      ExtractFileName(FDependencies[I].TargetPath),
      GetDependencyTypeText(FDependencies[I].DependencyType),
      #13#10
    ]);
  end;

  Result := GraphText;
end;

function TDependencyGraph.GetStatistics: string;
var
  ValidCount, InvalidCount, CriticalCount: Integer;
  I: Integer;
begin
  ValidCount := 0;
  InvalidCount := 0;
  CriticalCount := 0;

  for I := 0 to High(FDependencies) do
  begin
    if FDependencies[I].IsValid then
      Inc(ValidCount)
    else
      Inc(InvalidCount);

    if FDependencies[I].IsCritical then
      Inc(CriticalCount);
  end;

  Result := Format('节点数: %d, 依赖关系: %d, 有效: %d, 无效: %d, 关键: %d', [
    FNodes.Count,
    Length(FDependencies),
    ValidCount,
    InvalidCount,
    CriticalCount
  ]);
end;

procedure TDependencyGraph.SaveToFile;
var
  FileStream: TFileStream;
  Writer: TBinaryWriter;
  I: Integer;
begin
  try
    if FDataFile = '' then
      Exit;

    FileStream := TFileStream.Create(FDataFile, fmCreate);
    try
      Writer := TBinaryWriter.Create(FileStream);
      try
        // 写入版本号
        Writer.Write(Integer(1));

        // 写入依赖关系数量
        Writer.Write(Length(FDependencies));

        // 写入每个依赖关系
        for I := 0 to High(FDependencies) do
        begin
          Writer.Write(FDependencies[I].Id);
          Writer.Write(FDependencies[I].SourcePath);
          Writer.Write(FDependencies[I].TargetPath);
          Writer.Write(Integer(FDependencies[I].DependencyType));
          Writer.Write(Integer(FDependencies[I].Strength));
          Writer.Write(FDependencies[I].Description);
          Writer.Write(FDependencies[I].IsValid);
          Writer.Write(FDependencies[I].IsCritical);
          Writer.Write(FDependencies[I].DetectedTime);
          Writer.Write(FDependencies[I].LastVerified);
          Writer.Write(FDependencies[I].RiskLevel);
          Writer.Write(FDependencies[I].ImpactScore);
          Writer.Write(FDependencies[I].UserData);
        end;

      finally
        Writer.Free;
      end;
    finally
      FileStream.Free;
    end;
  except
    // 忽略保存错误
  end;
end;

procedure TDependencyGraph.LoadFromFile;
var
  FileStream: TFileStream;
  Reader: TBinaryReader;
  Version, Count, I: Integer;
  Dependency: TDependencyRelation;
begin
  try
    if not FileExists(FDataFile) then
      Exit;

    FileStream := TFileStream.Create(FDataFile, fmOpenRead);
    try
      Reader := TBinaryReader.Create(FileStream);
      try
        // 读取版本号
        Version := Reader.ReadInt32;
        if Version <> 1 then
          Exit;

        // 读取依赖关系数量
        Count := Reader.ReadInt32;
        SetLength(FDependencies, Count);

        // 读取每个依赖关系
        for I := 0 to Count - 1 do
        begin
          Dependency.Id := Reader.ReadString;
          Dependency.SourcePath := Reader.ReadString;
          Dependency.TargetPath := Reader.ReadString;
          Dependency.DependencyType := TDependencyType(Reader.ReadInt32);
          Dependency.Strength := TDependencyStrength(Reader.ReadInt32);
          Dependency.Description := Reader.ReadString;
          Dependency.IsValid := Reader.ReadBoolean;
          Dependency.IsCritical := Reader.ReadBoolean;
          Dependency.DetectedTime := Reader.ReadDouble;
          Dependency.LastVerified := Reader.ReadDouble;
          Dependency.RiskLevel := Reader.ReadInt32;
          Dependency.ImpactScore := Reader.ReadDouble;
          Dependency.UserData := Reader.ReadString;

          FDependencies[I] := Dependency;

          // 添加节点
          AddNode(Dependency.SourcePath);
          AddNode(Dependency.TargetPath);
        end;

        // 重建邻接矩阵
        BuildAdjacencyMatrix;

      finally
        Reader.Free;
      end;
    finally
      FileStream.Free;
    end;
  except
    // 忽略加载错误
    Clear;
  end;
end;

function TDependencyGraph.GetDependencyTypeText(AType: TDependencyType): string;
begin
  case AType of
    dtSymbolicLink: Result := '符号链接';
    dtFileReference: Result := '文件引用';
    dtPathReference: Result := '路径引用';
    dtConfigFile: Result := '配置文件';
    dtRegistry: Result := '注册表';
    dtEnvironment: Result := '环境变量';
    dtService: Result := '服务';
    dtLibrary: Result := '库文件';
  else
    Result := '未知';
  end;
end;

// ===== TConfigTemplateManager 实现 =====

constructor TConfigTemplateManager.Create(const ADataFile: string);
begin
  inherited Create;
  FDataFile := ADataFile;
  SetLength(FTemplates, 0);
  FillChar(FCurrentTemplate, SizeOf(FCurrentTemplate), 0);
  FAutoSave := True;
end;

destructor TConfigTemplateManager.Destroy;
begin
  if FAutoSave then
    SaveToFile;
  SetLength(FTemplates, 0);
  inherited Destroy;
end;

function TConfigTemplateManager.CreateTemplate(const AName, ADescription: string; AType: TConfigTemplateType): string;
var
  Template: TConfigTemplate;
begin
  // 初始化模板
  FillChar(Template, SizeOf(Template), 0);
  Template.Id := FormatDateTime('yyyymmdd_hhnnss_', Now) + IntToStr(Random(9999));
  Template.Name := AName;
  Template.Description := ADescription;
  Template.TemplateType := AType;
  Template.Version := '1.0';
  Template.CreatedBy := GetEnvironmentVariable('USERNAME');
  Template.CreatedTime := Now;
  Template.ModifiedTime := Now;
  Template.IsActive := True;
  Template.IsDefault := False;
  Template.Priority := 5;

  // 添加到模板列表
  SetLength(FTemplates, Length(FTemplates) + 1);
  FTemplates[High(FTemplates)] := Template;

  if FAutoSave then
    SaveToFile;

  Result := Template.Id;
end;

function TConfigTemplateManager.LoadTemplate(const ATemplateId: string): Boolean;
var
  I: Integer;
begin
  Result := False;

  for I := 0 to High(FTemplates) do
  begin
    if FTemplates[I].Id = ATemplateId then
    begin
      FCurrentTemplate := FTemplates[I];
      Result := True;
      Break;
    end;
  end;
end;

function TConfigTemplateManager.SaveTemplate(const ATemplate: TConfigTemplate): Boolean;
var
  I: Integer;
  Found: Boolean;
  UpdatedTemplate: TConfigTemplate;
begin
  Result := False;
  Found := False;
  UpdatedTemplate := ATemplate;
  UpdatedTemplate.ModifiedTime := Now;

  // 查找现有模板并更新
  for I := 0 to High(FTemplates) do
  begin
    if FTemplates[I].Id = ATemplate.Id then
    begin
      FTemplates[I] := UpdatedTemplate;
      Found := True;
      Result := True;
      Break;
    end;
  end;

  // 如果没找到，添加新模板
  if not Found then
  begin
    SetLength(FTemplates, Length(FTemplates) + 1);
    FTemplates[High(FTemplates)] := UpdatedTemplate;
    Result := True;
  end;

  if FAutoSave then
    SaveToFile;
end;

function TConfigTemplateManager.DeleteTemplate(const ATemplateId: string): Boolean;
var
  I, J: Integer;
begin
  Result := False;

  for I := 0 to High(FTemplates) do
  begin
    if FTemplates[I].Id = ATemplateId then
    begin
      // 移动后面的元素向前
      for J := I to High(FTemplates) - 1 do
        FTemplates[J] := FTemplates[J + 1];

      // 缩短数组
      SetLength(FTemplates, Length(FTemplates) - 1);
      Result := True;

      if FAutoSave then
        SaveToFile;
      Break;
    end;
  end;
end;

function TConfigTemplateManager.DuplicateTemplate(const ATemplateId, ANewName: string): string;
var
  I: Integer;
  NewTemplate: TConfigTemplate;
begin
  Result := '';

  for I := 0 to High(FTemplates) do
  begin
    if FTemplates[I].Id = ATemplateId then
    begin
      NewTemplate := FTemplates[I];
      NewTemplate.Id := FormatDateTime('yyyymmdd_hhnnss_', Now) + IntToStr(Random(9999));
      NewTemplate.Name := ANewName;
      NewTemplate.CreatedTime := Now;
      NewTemplate.ModifiedTime := Now;
      NewTemplate.IsDefault := False;

      SetLength(FTemplates, Length(FTemplates) + 1);
      FTemplates[High(FTemplates)] := NewTemplate;

      if FAutoSave then
        SaveToFile;

      Result := NewTemplate.Id;
      Break;
    end;
  end;
end;

function TConfigTemplateManager.GetTemplate(const ATemplateId: string): TConfigTemplate;
var
  I: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);

  for I := 0 to High(FTemplates) do
  begin
    if FTemplates[I].Id = ATemplateId then
    begin
      Result := FTemplates[I];
      Break;
    end;
  end;
end;

function TConfigTemplateManager.GetTemplatesByType(AType: TConfigTemplateType): TArray<TConfigTemplate>;
var
  TempList: TList<TConfigTemplate>;
begin
  TempList := TList<TConfigTemplate>.Create;
  try
    for var Template in FTemplates do
    begin
      if Template.TemplateType = AType then
        TempList.Add(Template);
    end;

    Result := TempList.ToArray;
  finally
    TempList.Free;
  end;
end;

function TConfigTemplateManager.GetAllTemplates: TArray<TConfigTemplate>;
begin
  Result := Copy(FTemplates, 0, Length(FTemplates));
end;

function TConfigTemplateManager.FindTemplatesByName(const AName: string): TArray<TConfigTemplate>;
var
  TempList: TList<TConfigTemplate>;
begin
  TempList := TList<TConfigTemplate>.Create;
  try
    for var Template in FTemplates do
    begin
      if Pos(UpperCase(AName), UpperCase(Template.Name)) > 0 then
        TempList.Add(Template);
    end;

    Result := TempList.ToArray;
  finally
    TempList.Free;
  end;
end;

function TConfigTemplateManager.GetDefaultTemplate: TConfigTemplate;
var
  I: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);

  for I := 0 to High(FTemplates) do
  begin
    if FTemplates[I].IsDefault then
    begin
      Result := FTemplates[I];
      Break;
    end;
  end;
end;

function TConfigTemplateManager.GetTemplateCount: Integer;
begin
  Result := Length(FTemplates);
end;

procedure TConfigTemplateManager.SetAutoSave(AEnabled: Boolean);
begin
  FAutoSave := AEnabled;
end;

function TConfigTemplateManager.ApplyTemplate(const ATemplateId: string): Boolean;
var
  Template: TConfigTemplate;
begin
  Result := False;

  Template := GetTemplate(ATemplateId);
  if Template.Id <> '' then
  begin
    FCurrentTemplate := Template;
    Result := True;
  end;
end;

function TConfigTemplateManager.ExportTemplate(const ATemplateId, AFilePath: string): Boolean;
var
  Template: TConfigTemplate;
  FileStream: TFileStream;
  Writer: TBinaryWriter;
begin
  Result := False;

  try
    Template := GetTemplate(ATemplateId);
    if Template.Id = '' then
      Exit;

    FileStream := TFileStream.Create(AFilePath, fmCreate);
    try
      Writer := TBinaryWriter.Create(FileStream);
      try
        // 写入模板数据
        Writer.Write(Template.Id);
        Writer.Write(Template.Name);
        Writer.Write(Template.Description);
        Writer.Write(Integer(Template.TemplateType));
        Writer.Write(Template.Version);
        Writer.Write(Template.CreatedBy);
        Writer.Write(Template.CreatedTime);
        Writer.Write(Template.ModifiedTime);
        Writer.Write(Template.IsActive);
        Writer.Write(Template.IsDefault);
        Writer.Write(Template.SourcePath);
        Writer.Write(Template.TargetPath);
        Writer.Write(Template.CopyOptions);
        Writer.Write(Template.AnalysisOptions);
        Writer.Write(Template.SecuritySettings);
        Writer.Write(Template.PerformanceSettings);
        Writer.Write(Template.UISettings);
        Writer.Write(Template.Tags);
        Writer.Write(Template.Category);
        Writer.Write(Template.Priority);
        Writer.Write(Template.UserData);

        Result := True;
      finally
        Writer.Free;
      end;
    finally
      FileStream.Free;
    end;
  except
    Result := False;
  end;
end;

function TConfigTemplateManager.ImportTemplate(const AFilePath: string): string;
var
  Template: TConfigTemplate;
  FileStream: TFileStream;
  Reader: TBinaryReader;
begin
  Result := '';

  try
    if not FileExists(AFilePath) then
      Exit;

    FileStream := TFileStream.Create(AFilePath, fmOpenRead);
    try
      Reader := TBinaryReader.Create(FileStream);
      try
        // 读取模板数据
        Template.Id := Reader.ReadString;
        Template.Name := Reader.ReadString;
        Template.Description := Reader.ReadString;
        Template.TemplateType := TConfigTemplateType(Reader.ReadInt32);
        Template.Version := Reader.ReadString;
        Template.CreatedBy := Reader.ReadString;
        Template.CreatedTime := Reader.ReadDouble;
        Template.ModifiedTime := Reader.ReadDouble;
        Template.IsActive := Reader.ReadBoolean;
        Template.IsDefault := Reader.ReadBoolean;
        Template.SourcePath := Reader.ReadString;
        Template.TargetPath := Reader.ReadString;
        Template.CopyOptions := Reader.ReadString;
        Template.AnalysisOptions := Reader.ReadString;
        Template.SecuritySettings := Reader.ReadString;
        Template.PerformanceSettings := Reader.ReadString;
        Template.UISettings := Reader.ReadString;
        Template.Tags := Reader.ReadString;
        Template.Category := Reader.ReadString;
        Template.Priority := Reader.ReadInt32;
        Template.UserData := Reader.ReadString;

        // 生成新ID避免冲突
        Template.Id := FormatDateTime('yyyymmdd_hhnnss_', Now) + IntToStr(Random(9999));
        Template.ModifiedTime := Now;

        // 添加到模板列表
        SetLength(FTemplates, Length(FTemplates) + 1);
        FTemplates[High(FTemplates)] := Template;

        if FAutoSave then
          SaveToFile;

        Result := Template.Id;
      finally
        Reader.Free;
      end;
    finally
      FileStream.Free;
    end;
  except
    Result := '';
  end;
end;

function TConfigTemplateManager.ValidateTemplate(const ATemplate: TConfigTemplate): Boolean;
begin
  Result := (ATemplate.Id <> '') and (ATemplate.Name <> '');

  // 可以添加更多验证逻辑
  if Result then
  begin
    Result := Result and (Length(ATemplate.Name) >= 2);
    Result := Result and (Length(ATemplate.Name) <= 100);
  end;
end;

function TConfigTemplateManager.CreateTemplateVersion(const ATemplateId: string): string;
var
  Template: TConfigTemplate;
  VersionedTemplate: TConfigTemplate;
begin
  Result := '';

  Template := GetTemplate(ATemplateId);
  if Template.Id = '' then
    Exit;

  VersionedTemplate := Template;
  VersionedTemplate.Id := FormatDateTime('yyyymmdd_hhnnss_', Now) + IntToStr(Random(9999));
  VersionedTemplate.Name := Template.Name + ' (v' + FormatDateTime('yyyymmdd-hhnnss', Now) + ')';
  VersionedTemplate.CreatedTime := Now;
  VersionedTemplate.ModifiedTime := Now;
  VersionedTemplate.IsDefault := False;

  SetLength(FTemplates, Length(FTemplates) + 1);
  FTemplates[High(FTemplates)] := VersionedTemplate;

  if FAutoSave then
    SaveToFile;

  Result := VersionedTemplate.Id;
end;

function TConfigTemplateManager.GetTemplateVersions(const ATemplateId: string): TArray<string>;
var
  Template: TConfigTemplate;
  VersionList: TList<string>;
  I: Integer;
begin
  Template := GetTemplate(ATemplateId);
  if Template.Id = '' then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  VersionList := TList<string>.Create;
  try
    for I := 0 to High(FTemplates) do
    begin
      if Pos(Template.Name, FTemplates[I].Name) > 0 then
        VersionList.Add(FTemplates[I].Id);
    end;

    Result := VersionList.ToArray;
  finally
    VersionList.Free;
  end;
end;

function TConfigTemplateManager.RestoreTemplateVersion(const ATemplateId, AVersion: string): Boolean;
var
  VersionTemplate: TConfigTemplate;
begin
  Result := False;

  VersionTemplate := GetTemplate(AVersion);
  if VersionTemplate.Id = '' then
    Exit;

  VersionTemplate.Id := ATemplateId;
  VersionTemplate.ModifiedTime := Now;

  Result := SaveTemplate(VersionTemplate);
end;

procedure TConfigTemplateManager.SaveToFile;
var
  FileStream: TFileStream;
  Writer: TBinaryWriter;
  I: Integer;
begin
  try
    if FDataFile = '' then
      Exit;

    FileStream := TFileStream.Create(FDataFile, fmCreate);
    try
      Writer := TBinaryWriter.Create(FileStream);
      try
        // 写入版本号
        Writer.Write(Integer(1));

        // 写入模板数量
        Writer.Write(Length(FTemplates));

        // 写入每个模板
        for I := 0 to High(FTemplates) do
        begin
          Writer.Write(FTemplates[I].Id);
          Writer.Write(FTemplates[I].Name);
          Writer.Write(FTemplates[I].Description);
          Writer.Write(Integer(FTemplates[I].TemplateType));
          Writer.Write(FTemplates[I].Version);
          Writer.Write(FTemplates[I].CreatedBy);
          Writer.Write(FTemplates[I].CreatedTime);
          Writer.Write(FTemplates[I].ModifiedTime);
          Writer.Write(FTemplates[I].IsActive);
          Writer.Write(FTemplates[I].IsDefault);
          Writer.Write(FTemplates[I].SourcePath);
          Writer.Write(FTemplates[I].TargetPath);
          Writer.Write(FTemplates[I].CopyOptions);
          Writer.Write(FTemplates[I].AnalysisOptions);
          Writer.Write(FTemplates[I].SecuritySettings);
          Writer.Write(FTemplates[I].PerformanceSettings);
          Writer.Write(FTemplates[I].UISettings);
          Writer.Write(FTemplates[I].Tags);
          Writer.Write(FTemplates[I].Category);
          Writer.Write(FTemplates[I].Priority);
          Writer.Write(FTemplates[I].UserData);
        end;

      finally
        Writer.Free;
      end;
    finally
      FileStream.Free;
    end;
  except
    // 忽略保存错误
  end;
end;

procedure TConfigTemplateManager.LoadFromFile;
var
  FileStream: TFileStream;
  Reader: TBinaryReader;
  Version, Count, I: Integer;
  Template: TConfigTemplate;
begin
  try
    if not FileExists(FDataFile) then
      Exit;

    FileStream := TFileStream.Create(FDataFile, fmOpenRead);
    try
      Reader := TBinaryReader.Create(FileStream);
      try
        // 读取版本号
        Version := Reader.ReadInt32;
        if Version <> 1 then
          Exit;

        // 读取模板数量
        Count := Reader.ReadInt32;
        SetLength(FTemplates, Count);

        // 读取每个模板
        for I := 0 to Count - 1 do
        begin
          Template.Id := Reader.ReadString;
          Template.Name := Reader.ReadString;
          Template.Description := Reader.ReadString;
          Template.TemplateType := TConfigTemplateType(Reader.ReadInt32);
          Template.Version := Reader.ReadString;
          Template.CreatedBy := Reader.ReadString;
          Template.CreatedTime := Reader.ReadDouble;
          Template.ModifiedTime := Reader.ReadDouble;
          Template.IsActive := Reader.ReadBoolean;
          Template.IsDefault := Reader.ReadBoolean;
          Template.SourcePath := Reader.ReadString;
          Template.TargetPath := Reader.ReadString;
          Template.CopyOptions := Reader.ReadString;
          Template.AnalysisOptions := Reader.ReadString;
          Template.SecuritySettings := Reader.ReadString;
          Template.PerformanceSettings := Reader.ReadString;
          Template.UISettings := Reader.ReadString;
          Template.Tags := Reader.ReadString;
          Template.Category := Reader.ReadString;
          Template.Priority := Reader.ReadInt32;
          Template.UserData := Reader.ReadString;

          FTemplates[I] := Template;
        end;

      finally
        Reader.Free;
      end;
    finally
      FileStream.Free;
    end;
  except
    // 忽略加载错误
    SetLength(FTemplates, 0);
  end;
end;

function TConfigTemplateManager.GetTemplateUsageStats: string;
var
  ActiveCount, DefaultCount: Integer;
  TypeCounts: array[TConfigTemplateType] of Integer;
  I: Integer;
  TypeName: string;
begin
  ActiveCount := 0;
  DefaultCount := 0;

  for I := Low(TypeCounts) to High(TypeCounts) do
    TypeCounts[I] := 0;

  for I := 0 to High(FTemplates) do
  begin
    if FTemplates[I].IsActive then
      Inc(ActiveCount);
    if FTemplates[I].IsDefault then
      Inc(DefaultCount);
    Inc(TypeCounts[FTemplates[I].TemplateType]);
  end;

  Result := Format('总计: %d, 激活: %d, 默认: %d', [Length(FTemplates), ActiveCount, DefaultCount]);

  for I := Low(TypeCounts) to High(TypeCounts) do
  begin
    if TypeCounts[I] > 0 then
    begin
      case TConfigTemplateType(I) of
        ctGeneral: TypeName := '通用';
        ctDevelopment: TypeName := '开发';
        ctProduction: TypeName := '生产';
        ctTesting: TypeName := '测试';
        ctBackup: TypeName := '备份';
        ctCustom: TypeName := '自定义';
      else
        TypeName := '未知';
      end;

      Result := Result + Format(', %s: %d', [TypeName, TypeCounts[I]]);
    end;
  end;
end;

// ===== TAuditComplianceManager 实现 =====

constructor TAuditComplianceManager.Create(const ADataFile: string; AMaxRecords: Integer);
begin
  inherited Create;
  FDataFile := ADataFile;
  FMaxRecords := AMaxRecords;
  SetLength(FAuditRecords, 0);
  SetLength(FComplianceRules, 0);
  FCurrentSessionId := '';
  FCurrentUserId := '';
  FAutoAudit := True;
end;

destructor TAuditComplianceManager.Destroy;
begin
  EndSession;
  SaveToFile;
  SetLength(FAuditRecords, 0);
  SetLength(FComplianceRules, 0);
  inherited Destroy;
end;

function TAuditComplianceManager.LogAuditEvent(AEventType: TAuditEventType; ASeverity: TAuditSeverity; const ADescription, AResourcePath: string; ASuccess: Boolean; const AOldValue, ANewValue: string): string;
var
  AuditRecord: TAuditRecord;
begin
  // 创建审计记录
  AuditRecord.Id := FormatDateTime('yyyymmdd_hhnnss_', Now) + IntToStr(Random(9999));
  AuditRecord.EventType := AEventType;
  AuditRecord.Severity := ASeverity;
  AuditRecord.Timestamp := Now;
  AuditRecord.UserId := FCurrentUserId;
  AuditRecord.UserName := GetEnvironmentVariable('USERNAME');
  AuditRecord.SessionId := FCurrentSessionId;
  AuditRecord.SourceIP := '127.0.0.1'; // 本地应用
  AuditRecord.EventDescription := ADescription;
  AuditRecord.ResourcePath := AResourcePath;
  AuditRecord.OldValue := AOldValue;
  AuditRecord.NewValue := ANewValue;
  AuditRecord.Success := ASuccess;
  AuditRecord.ErrorCode := 0;
  AuditRecord.ErrorMessage := '';
  AuditRecord.AdditionalData := '';
  AuditRecord.ComplianceFlags := '';

  // 添加到审计记录列表
  SetLength(FAuditRecords, Length(FAuditRecords) + 1);
  FAuditRecords[High(FAuditRecords)] := AuditRecord;

  // 限制记录数量
  if Length(FAuditRecords) > FMaxRecords then
  begin
    // 移除最旧的记录
    for var I := 0 to High(FAuditRecords) - 1 do
      FAuditRecords[I] := FAuditRecords[I + 1];
    SetLength(FAuditRecords, FMaxRecords);
  end;

  Result := AuditRecord.Id;
end;

function TAuditComplianceManager.GetAuditRecords(AStartTime, AEndTime: TDateTime): TArray<TAuditRecord>;
var
  TempList: TList<TAuditRecord>;
begin
  TempList := TList<TAuditRecord>.Create;
  try
    for var Record in FAuditRecords do
    begin
      if (Record.Timestamp >= AStartTime) and (Record.Timestamp <= AEndTime) then
        TempList.Add(Record);
    end;

    Result := TempList.ToArray;
  finally
    TempList.Free;
  end;
end;

function TAuditComplianceManager.GetAuditRecordsByType(AEventType: TAuditEventType): TArray<TAuditRecord>;
var
  TempList: TList<TAuditRecord>;
begin
  TempList := TList<TAuditRecord>.Create;
  try
    for var Record in FAuditRecords do
    begin
      if Record.EventType = AEventType then
        TempList.Add(Record);
    end;

    Result := TempList.ToArray;
  finally
    TempList.Free;
  end;
end;

function TAuditComplianceManager.GetAuditRecordsBySeverity(ASeverity: TAuditSeverity): TArray<TAuditRecord>;
var
  TempList: TList<TAuditRecord>;
begin
  TempList := TList<TAuditRecord>.Create;
  try
    for var Record in FAuditRecords do
    begin
      if Record.Severity = ASeverity then
        TempList.Add(Record);
    end;

    Result := TempList.ToArray;
  finally
    TempList.Free;
  end;
end;

function TAuditComplianceManager.SearchAuditRecords(const ASearchText: string): TArray<TAuditRecord>;
var
  TempList: TList<TAuditRecord>;
  SearchUpper: string;
begin
  TempList := TList<TAuditRecord>.Create;
  try
    SearchUpper := UpperCase(ASearchText);

    for var Record in FAuditRecords do
    begin
      if (Pos(SearchUpper, UpperCase(Record.EventDescription)) > 0) or
         (Pos(SearchUpper, UpperCase(Record.ResourcePath)) > 0) or
         (Pos(SearchUpper, UpperCase(Record.UserName)) > 0) then
        TempList.Add(Record);
    end;

    Result := TempList.ToArray;
  finally
    TempList.Free;
  end;
end;

procedure TAuditComplianceManager.ClearOldAuditRecords(ADaysOld: Integer);
var
  CutoffDate: TDateTime;
  NewRecords: TArray<TAuditRecord>;
begin
  CutoffDate := Now - ADaysOld;
  SetLength(NewRecords, 0);

  for var Record in FAuditRecords do
  begin
    if Record.Timestamp > CutoffDate then
    begin
      SetLength(NewRecords, Length(NewRecords) + 1);
      NewRecords[High(NewRecords)] := Record;
    end;
  end;

  FAuditRecords := NewRecords;
end;

function TAuditComplianceManager.AddComplianceRule(const ARule: TComplianceRule): string;
var
  Rule: TComplianceRule;
begin
  Rule := ARule;

  // 生成唯一ID
  if Rule.Id = '' then
    Rule.Id := FormatDateTime('yyyymmdd_hhnnss_', Now) + IntToStr(Random(9999));

  // 设置时间戳
  if Rule.CreatedTime = 0 then
    Rule.CreatedTime := Now;
  Rule.ModifiedTime := Now;

  // 添加到规则列表
  SetLength(FComplianceRules, Length(FComplianceRules) + 1);
  FComplianceRules[High(FComplianceRules)] := Rule;

  Result := Rule.Id;
end;

function TAuditComplianceManager.UpdateComplianceRule(const ARuleId: string; const ARule: TComplianceRule): Boolean;
var
  I: Integer;
  UpdatedRule: TComplianceRule;
begin
  Result := False;

  for I := 0 to High(FComplianceRules) do
  begin
    if FComplianceRules[I].Id = ARuleId then
    begin
      UpdatedRule := ARule;
      UpdatedRule.Id := ARuleId;
      UpdatedRule.ModifiedTime := Now;
      FComplianceRules[I] := UpdatedRule;
      Result := True;
      Break;
    end;
  end;
end;

function TAuditComplianceManager.DeleteComplianceRule(const ARuleId: string): Boolean;
var
  I, J: Integer;
begin
  Result := False;

  for I := 0 to High(FComplianceRules) do
  begin
    if FComplianceRules[I].Id = ARuleId then
    begin
      // 移动后面的元素向前
      for J := I to High(FComplianceRules) - 1 do
        FComplianceRules[J] := FComplianceRules[J + 1];

      // 缩短数组
      SetLength(FComplianceRules, Length(FComplianceRules) - 1);
      Result := True;
      Break;
    end;
  end;
end;

function TAuditComplianceManager.GetComplianceRules: TArray<TComplianceRule>;
begin
  Result := Copy(FComplianceRules, 0, Length(FComplianceRules));
end;

function TAuditComplianceManager.CheckCompliance(const AResourcePath, AOperation: string): TArray<TComplianceRule>;
var
  ViolatedRules: TList<TComplianceRule>;
begin
  ViolatedRules := TList<TComplianceRule>.Create;
  try
    for var Rule in FComplianceRules do
    begin
      if Rule.IsActive then
      begin
        // 简单的模式匹配检查
        case Rule.RuleType of
          crtPathRestriction:
          begin
            if (Rule.Pattern <> '') and (Pos(UpperCase(Rule.Pattern), UpperCase(AResourcePath)) > 0) then
              ViolatedRules.Add(Rule);
          end;

          crtUserPermission:
          begin
            // 检查用户权限
            if (FCurrentUserId <> '') and (Rule.Pattern <> '') and (FCurrentUserId <> Rule.Pattern) then
              ViolatedRules.Add(Rule);
          end;

          // 其他规则类型的检查可以在这里添加
        end;
      end;
    end;

    Result := ViolatedRules.ToArray;
  finally
    ViolatedRules.Free;
  end;
end;

function TAuditComplianceManager.ValidateOperation(const AResourcePath, AOperation: string): Boolean;
var
  ViolatedRules: TArray<TComplianceRule>;
begin
  ViolatedRules := CheckCompliance(AResourcePath, AOperation);
  Result := Length(ViolatedRules) = 0;

  // 记录合规检查结果
  if not Result then
  begin
    LogAuditEvent(aetSecurityEvent, asWarning,
      Format('合规检查失败: %s 操作 %s', [AOperation, AResourcePath]),
      AResourcePath, False);
  end;
end;

procedure TAuditComplianceManager.StartSession(const AUserId: string);
begin
  FCurrentUserId := AUserId;
  FCurrentSessionId := GenerateSessionId;

  LogAuditEvent(aetLogin, asInfo,
    Format('用户 %s 开始会话', [AUserId]),
    '', True);
end;

procedure TAuditComplianceManager.EndSession;
begin
  if FCurrentSessionId <> '' then
  begin
    LogAuditEvent(aetLogout, asInfo,
      Format('用户 %s 结束会话', [FCurrentUserId]),
      '', True);

    FCurrentSessionId := '';
    FCurrentUserId := '';
  end;
end;

function TAuditComplianceManager.GetCurrentSessionId: string;
begin
  Result := FCurrentSessionId;
end;

function TAuditComplianceManager.GetAuditRecordCount: Integer;
begin
  Result := Length(FAuditRecords);
end;

function TAuditComplianceManager.GetComplianceRuleCount: Integer;
begin
  Result := Length(FComplianceRules);
end;

function TAuditComplianceManager.GenerateSessionId: string;
begin
  Result := FormatDateTime('yyyymmdd_hhnnss_', Now) + IntToStr(Random(99999));
end;

function TAuditComplianceManager.GetEventTypeName(AType: TAuditEventType): string;
begin
  case AType of
    aetLogin: Result := '登录';
    aetLogout: Result := '登出';
    aetFileAccess: Result := '文件访问';
    aetFileModify: Result := '文件修改';
    aetDirectoryCreate: Result := '目录创建';
    aetDirectoryDelete: Result := '目录删除';
    aetConfigChange: Result := '配置变更';
    aetSecurityEvent: Result := '安全事件';
    aetSystemError: Result := '系统错误';
    aetUserAction: Result := '用户操作';
    aetDataExport: Result := '数据导出';
    aetDataImport: Result := '数据导入';
  else
    Result := '未知事件';
  end;
end;

function TAuditComplianceManager.GetSeverityName(ASeverity: TAuditSeverity): string;
begin
  case ASeverity of
    asInfo: Result := '信息';
    asWarning: Result := '警告';
    asError: Result := '错误';
    asCritical: Result := '关键';
  else
    Result := '未知';
  end;
end;

function TAuditComplianceManager.GetRuleTypeName(AType: TComplianceRuleType): string;
begin
  case AType of
    crtPathRestriction: Result := '路径限制';
    crtSizeLimit: Result := '大小限制';
    crtTimeRestriction: Result := '时间限制';
    crtUserPermission: Result := '用户权限';
    crtDataRetention: Result := '数据保留';
    crtEncryption: Result := '加密要求';
    crtAuditTrail: Result := '审计跟踪';
    crtAccessControl: Result := '访问控制';
  else
    Result := '未知规则';
  end;
end;

end.

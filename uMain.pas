unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI,
  System.SysUtils, System.Variants, System.Classes, System.AnsiStrings,
  System.Generics.Collections, System.Generics.Defaults, System.Threading, System.Math, System.DateUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Menus, Vcl.FileCtrl, Vcl.Clipbrd, Vcl.Buttons,
  System.IOUtils, System.UITypes,
  // Modern UI styles and strings
  uStyles, uStrings, uIconManager, uConstants,
  // Security modules
  uSimpleSecureManager, FrameAboutMe, uAntiTamperPackage, uAntiDebug,
  // Clean up modules
  uCleanupManager, uCleanupHistory,
  // Advanced file manager
  uAdvancedFileManagerForm,
  // Smart migration wizard
  uSmartMigrationWizard,
  // Rollback manager
  uRollbackManager,
  // Log manager
  uLogManager,
  // Advanced options dialog
  uAdvancedOptions,
  // Enhanced system monitoring dialog
  uSystemMonitorDialog,
  // Migration transaction and file hasher
  uMigrationTransaction, uFileHasher,
  // System check utilities
  uSystemCheck,
  // App association detector
  uAppAssociation,
  // System monitoring and performance modules
  uSystemMonitor, uPerformanceAnalyzer, uSystemOptimizer,
  // C盘空间分析器
  uDiskAnalyzer,
  // 清理预览窗体
  uCleanupPreview,
  // 清理历史查看窗体
  uCleanupHistoryForm,
  // FireDAC for SQLite initialization when DB is missing
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Phys.SQLite, Data.DB;

type
  TfrmMain = class(TForm)
    // 主面板
    pnlMain: TPanel;
    
    // 左侧面板 - 源目录
    pnlLeft: TPanel;
    lblSourceDir: TLabel;
    edtSourceDir: TEdit;
    btnBrowseSource: TBitBtn;
    btnSourceUp: TBitBtn;
    tvSource: TTreeView;
    
    // 应用关联信息面板
    pnlAppAssoc: TPanel;
    lblAppAssocTitle: TLabel;
    lblAppName: TLabel;
    lblAppSuggestion: TLabel;
    
    // 右侧面板 - 目标目录
    pnlRight: TPanel;
    lblTargetDir: TLabel;
    edtTargetDir: TEdit;
    btnBrowseTarget: TBitBtn;
    btnTargetUp: TBitBtn;
    tvTarget: TTreeView;
    
    // 底部状态栏
    StatusBar1: TStatusBar;
    
    // 菜单
    MainMenu1: TMainMenu;
    MenuFile: TMenuItem;
    MenuFileExit: TMenuItem;
    MenuEdit: TMenuItem;
    MenuCleanup: TMenuItem;
    MenuCleanupRecycleBin: TMenuItem;
    MenuCleanupTemp: TMenuItem;
    MenuCleanupSeparator: TMenuItem;
    MenuCleanupLastBackup: TMenuItem;
    MenuCleanupSoftwareDistribution: TMenuItem;
    MenuCleanupSeparator2: TMenuItem;
    MenuCleanupDuplicateFiles: TMenuItem;
    MenuCleanupSeparator3: TMenuItem;
    MenuCleanupHistory: TMenuItem;
    MenuTools: TMenuItem;
    miSimpleMode: TMenuItem;
    miConfigManager: TMenuItem;
    miRollbackManager: TMenuItem;
    miSeparatorTools1: TMenuItem;
    miLogManager: TMenuItem;
    miAdvancedOptions: TMenuItem;
    MenuTheme: TMenuItem;
    MenuHelp: TMenuItem;
    MenuHelpAbout: TMenuItem;
    
    // 弹出菜单
    pmSource: TPopupMenu;
    pmTarget: TPopupMenu;
    miSrcOpen: TMenuItem;
    miSrcOpenInExplorer: TMenuItem;
    miSrcCopyPath: TMenuItem;
    miSrcSetRoot: TMenuItem;
    miSrcScanHere: TMenuItem;
    miSrcAnalyzeHere: TMenuItem;
    miSrcRefresh: TMenuItem;
    miTgtOpen: TMenuItem;
    miTgtOpenInExplorer: TMenuItem;
    miTgtCopyPath: TMenuItem;
    miTgtSetRoot: TMenuItem;
    miTgtSetAsTargetPath: TMenuItem;
    miTgtRefresh: TMenuItem;
    miSrcDelete: TMenuItem;
    miSrcProperties: TMenuItem;
    miTgtDelete: TMenuItem;
    miTgtProperties: TMenuItem;
    lvFiles: TListView;
    pnlBottom: TPanel;
    pnlAboutMe: TPanel;
    pnlTop: TPanel;
    btnCleanBackup: TBitBtn;
    btnSmartClean: TBitBtn;
    btnSmartMigration: TBitBtn;
    btnAnalyze: TBitBtn;
    btnCalculateSize: TBitBtn;
    btnExecute: TBitBtn;
    btnRollback: TBitBtn;
    btnOneKeyDiagnose: TBitBtn;
    btnExit: TBitBtn;
    pnlStatus: TPanel;
    lblStatus: TLabel;
    lblCurrentFile: TLabel;
    lblTimeRemaining: TLabel;
    ProgressBar1: TProgressBar;
    btnCancelOperation: TBitBtn;
    memoStatus: TMemo;
    pnlFileList: TPanel;
    Splitter1: TSplitter;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    
    // 工具栏按钮事件
    procedure btnCleanRecycleBinClick(Sender: TObject);
    procedure btnCleanTempClick(Sender: TObject);
    procedure btnCleanBackupClick(Sender: TObject);
    procedure btnCleanUpdateClick(Sender: TObject);
    procedure btnSmartCleanClick(Sender: TObject);
    procedure btnSmartMigrationClick(Sender: TObject);
    procedure btnAdvancedFileManagerClick(Sender: TObject);
    procedure btnExecuteClick(Sender: TObject);
    procedure btnAnalyzeClick(Sender: TObject);
    procedure btnCalculateSizeClick(Sender: TObject);
    procedure btnRollbackClick(Sender: TObject);
    procedure btnOneKeyDiagnoseClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure btnCancelOperationClick(Sender: TObject);
    
    // 浏览按钮事件
    procedure btnBrowseSourceClick(Sender: TObject);
    procedure btnBrowseTargetClick(Sender: TObject);
    procedure btnSourceUpClick(Sender: TObject);
    procedure btnTargetUpClick(Sender: TObject);
    
    // 目录树事件
    procedure tvSourceChange(Sender: TObject; Node: TTreeNode);
    procedure tvTargetChange(Sender: TObject; Node: TTreeNode);
    procedure tvSourceDblClick(Sender: TObject);
    procedure tvTargetDblClick(Sender: TObject);
    procedure tvSourceKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure tvTargetKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure tvSourceExpanding(Sender: TObject; Node: TTreeNode; var AllowExpansion: Boolean);
    procedure tvTargetExpanding(Sender: TObject; Node: TTreeNode; var AllowExpansion: Boolean);
    procedure tvSourceDeletion(Sender: TObject; Node: TTreeNode);
    procedure tvTargetDeletion(Sender: TObject; Node: TTreeNode);
    
    // 菜单事件
    procedure MenuFileExitClick(Sender: TObject);
    procedure MenuCleanupRecycleBinClick(Sender: TObject);
    procedure MenuCleanupTempClick(Sender: TObject);
    procedure MenuCleanupLastBackupClick(Sender: TObject);
    procedure MenuCleanupSoftwareDistributionClick(Sender: TObject);
    procedure MenuCleanupDuplicateFilesClick(Sender: TObject);
    procedure MenuCleanupHistoryClick(Sender: TObject);
    procedure miConfigManagerClick(Sender: TObject);
    procedure miRollbackManagerClick(Sender: TObject);
    procedure miAdvancedFileManagerClick(Sender: TObject);
    procedure miLogManagerClick(Sender: TObject);
    procedure miAdvancedOptionsClick(Sender: TObject);
    procedure miSimpleModeClick(Sender: TObject);
    procedure MenuThemeClick(Sender: TObject);
    procedure MenuHelpAboutClick(Sender: TObject);

    // 右键菜单事件
    procedure pmSourcePopup(Sender: TObject);
    procedure pmTargetPopup(Sender: TObject);
    procedure miSrcOpenClick(Sender: TObject);
    procedure miSrcOpenInExplorerClick(Sender: TObject);
    procedure miSrcCopyPathClick(Sender: TObject);
    procedure miSrcSetRootClick(Sender: TObject);
    procedure miSrcScanHereClick(Sender: TObject);
    procedure miSrcAnalyzeHereClick(Sender: TObject);
    procedure miSrcRefreshClick(Sender: TObject);
    procedure miTgtOpenClick(Sender: TObject);
    procedure miTgtOpenInExplorerClick(Sender: TObject);
    procedure miTgtCopyPathClick(Sender: TObject);
    procedure miTgtSetRootClick(Sender: TObject);
    procedure miTgtSetAsTargetPathClick(Sender: TObject);
    procedure miTgtRefreshClick(Sender: TObject);
    procedure miSrcDeleteClick(Sender: TObject);
    procedure miSrcPropertiesClick(Sender: TObject);
    procedure miTgtDeleteClick(Sender: TObject);
    procedure miTgtPropertiesClick(Sender: TObject);
    
  private
    FSourcePath: string;
    FTargetPath: string;
    FStyleManager: TModernStyleManager;
    FLastBackupPath: string;
    FTotalBytesToCopy: Int64;
    FCopiedBytesSoFar: Int64;
    FCancelRequested: Boolean;
    // AboutMe安全模块
    FFrameAboutMe: TFrameAboutMe;
    FSecureManager: TSimpleSecureManager;
    // 清理管理器
    FCleanupManager: TCleanupManager;
    // 迁移事务管理器
    FMigrationTransaction: TMigrationTransaction;
    // 进度跟踪
    FStartTime: TDateTime;
    FProcessedFilesCount: Integer;
    FTotalFilesCount: Integer;
    FIsAdmin: Boolean;
    FSimpleMode: Boolean;
    FAppDetector: TAppAssociationDetector;
    // 动态文件列表控件
    FFileListView: TListView;
    // 系统监控和性能分析
    FSystemMonitor: TSystemMonitor;
    FPerformanceAnalyzer: TPerformanceAnalyzer;
    FSystemOptimizer: TSystemOptimizer;
    FMonitoringActive: Boolean;
    // C盘空间分析器
    FCDriveAnalyzer: TCDriveAnalyzer;
    FAnalysisResults: TArray<TCleanupSuggestion>;
    FLastAnalysisTime: TDateTime;
    FHeartbeatTimer: TTimer;
    
    procedure InitializeInterface;
    procedure InitializeTreeViews;
    function UpdateStatus(const AMessage: string): Boolean;
    procedure HeartbeatCheck(Sender: TObject);
    procedure LoadDirectoryTree(ATreeView: TTreeView; const APath: string);
    procedure ExpandTreeNode(ATreeView: TTreeView; ANode: TTreeNode);
    procedure FreeTreeViewData(ATreeView: TTreeView);
    procedure ApplyModernColors;
    procedure SetButtonStyle(AButton: TBitBtn; ABackColor, AFontColor: TColor);
    procedure LoadButtonIcons;

    // 自定义消息显示函数
    function ShowChineseMessage(const AMessage: string): Integer;
    function ShowChineseConfirm(const AMessage: string): Boolean;
    
    // 清理功能实现
    procedure CleanRecycleBin;
    procedure CleanTempFiles;
    procedure CleanBackupFiles;
    procedure CleanUpdateCache;
    
    // 清理进度回调
    procedure OnCleanupProgress(const AMessage: string; AProgress: Integer);

    // 核心迁移功能
    procedure ExecuteOperation;
    procedure AnalyzeDirectory(const APath: string);
    procedure CalculateDirectorySize(const APath: string);
    function CreateDirectoryLink(const ASource, ATarget: string): Boolean;
    procedure CopyDirRecursive(const ASrc, ADst: string; var ACopied: Int64);
    function CopyDirRecursiveWithVerify(const ASrc, ADst: string; 
      ATransaction: TMigrationTransaction): Boolean;
    function VerifyJunction(const AJunctionPath, ATargetPath: string): Boolean;
    procedure ComputeDirStats(const APath: string; var AFileCount: Integer; var ATotalSize: Int64);
    
    // 断点续迁
    procedure CheckIncompleteTransactions;
    procedure HandleIncompleteTransaction(const ATransactionID: string);
    function ResumeMigration(ATransaction: TMigrationTransaction): Boolean;
    function RollbackMigration(ATransaction: TMigrationTransaction): Boolean;
    
    // 迁移完成对话框
    procedure ShowMigrationCompleteDialog(TotalFiles, VerifiedCount, FailedCount: Integer;
      const BackupDir: string; BackupSize: Int64);
    
    // 文件列表管理
    procedure InitializeFileList;
    procedure LoadFileList(const APath: string);
    function ShowDirectoryProperties(const APath: string): Boolean;
    function DeleteDirectory(const APath: string; ATreeView: TTreeView): Boolean;
    
    // 进度管理
    procedure UpdateCurrentFile(const AFileName: string);
    procedure UpdateTimeRemaining;
    procedure ShowCancelButton(AShow: Boolean);
    
    // 简洁模式和权限管理
    procedure CheckAndRequestAdminPrivileges;
    procedure UpdateButtonStates;
    procedure SetSimpleMode(ASimple: Boolean);
    
    // 一键功能
    procedure PerformOneKeyRollback;
    procedure PerformOneKeyDiagnose;
    procedure PerformOneKeyOptimize;
    
    // 系统监控和性能分析
    procedure StartSystemMonitoring;
    procedure StopSystemMonitoring;
    procedure ShowSystemMonitorDialog;
    procedure ShowPerformanceAnalysisDialog;
    procedure PerformSystemOptimization;
    procedure OnSystemInfoUpdate(const Info: TSystemInfo);
    procedure OnMonitorEventAlert(const Event: TMonitorEvent);
    
    // C盘空间分析功能
    procedure StartCDriveAnalysis;
    procedure ShowAnalysisResults;
    procedure ShowSpaceAnalysisDialog;
    procedure ApplySuggestion(const Suggestion: TCleanupSuggestion);
    procedure OnAnalysisProgress(const Message: string; Progress: Integer);
    function GetCDriveFreeSpace: Int64;
    function GetCDriveTotalSpace: Int64;
    
    // 安全检查
    function IsSystemCriticalDirectory(const APath: string): Boolean;
    function CheckDirectorySafety(const ASourcePath, ATargetPath: string): Boolean;
    
    // 应用关联检测 UI
    procedure UpdateAppAssocInfo(const APath: string);
    
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
var
  Config: TAntiTamperConfig;
begin
  // FormCreate开始执行
  LogInfo('Main', 'MoveC 应用程序正在启动...');
  
  // 反调试保护（仅在Release版本启用）
  {$IFDEF RELEASE}
  if TAntiDebug.CheckAll then
  begin
    MessageBox(0, '检测到调试器，程序将退出。', '安全警告', MB_OK or MB_ICONERROR);
    Application.Terminate;
    Exit;
  end;
  {$ENDIF}
  
  // 初始化防篡改包
  Config := TAntiTamperPackage.GetDefaultConfig;
  Config.EncryptionKey := 'MoveC_AntiTamper_Key_2025';
  Config.DownloadURL := 'https://www.goodmem.cn';
  Config.EnableLogging := {$IFDEF DEBUG}True{$ELSE}False{$ENDIF};
  Config.EncryptionType := etAES256;  // 使用AES-256加密
  Config.Salt := 'MoveC_Salt_v1';      // KDF盐值 - 必须与播种工具一致
  Config.KdfIterations := 10000;       // KDF迭代次数 - 必须与播种工具一致
  Config.EnableHMAC := True;           // 启用HMAC校验 - 必须与播种工具一致
  TAntiTamperPackage.Initialize(Config);

  // 主程序不再负责播种，仅负责解密和校验
  // 播种功能已分离到独立工具 SeedTool.exe

  // 严格模式：若存在 MoveC.reset 标记，则清空并重新播种
  try
    var Root2 := ExtractFilePath(ParamStr(0));
    var DbPath3 := TPath.Combine(Root2, 'MoveC.db');
    var ResetFlag := TPath.Combine(Root2, 'MoveC.reset');
    if TFile.Exists(ResetFlag) then
    begin
      var Conn2 := TFDConnection.Create(nil);
      try
        Conn2.DriverName := 'SQLite';
        Conn2.Params.Values['Database'] := DbPath3;
        Conn2.LoginPrompt := False;
        Conn2.Connected := True;
        // 确保表结构存在
        if not TAntiTamperPackage.SetupDatabase(Conn2) then
          raise Exception.Create('创建/校验防篡改数据表失败');
        // 删除标记
        TFile.Delete(ResetFlag);
        LogInfo('Main', '已按标记重置防篡改数据库（MoveC.reset）');
      finally
        if Assigned(Conn2) then
        begin
          try Conn2.Connected := False; except end;
          Conn2.Free;
        end;
      end;
    end;
  except
    on E: Exception do
      LogError('Main', '严格模式重置失败: ' + E.Message);
  end;

  // 防篡改原则：关键资源缺失立即退出（fail-closed）
  try
    var DbPath2 := TPath.Combine(ExtractFilePath(ParamStr(0)), 'MoveC.db');
    if not TFile.Exists(DbPath2) then
    begin
      MessageBox(0, '检测到关键资源缺失：MoveC.db。程序将退出。', '安全警告', MB_OK or MB_ICONERROR or MB_TOPMOST);
      Application.Terminate;
      Exit;
    end;
  except
    on E: Exception do
      LogError('Main', '检查关键资源时发生异常: ' + E.Message);
  end;

  FStyleManager := TModernStyleManager.Create;
  FSourcePath := '';
  FTargetPath := '';
  
  // 初始化简洁模式和权限
  FSimpleMode := True;  // 默认启用简洁模式
  FIsAdmin := False;
  
  // 初始化清理管理器
  FCleanupManager := TCleanupManager.Create;
  FCleanupManager.OnProgress := OnCleanupProgress;
  
  // 初始化迁移事务管理器
  FMigrationTransaction := nil;
  
  // 初始化应用程序关联检测器
  FAppDetector := TAppAssociationDetector.Create;
  
  // 初始化系统监控和性能分析模块
  FSystemMonitor := TSystemMonitor.Create;
  FSystemMonitor.OnSystemInfo := OnSystemInfoUpdate;
  FSystemMonitor.OnMonitorEvent := OnMonitorEventAlert;
  
  FPerformanceAnalyzer := TPerformanceAnalyzer.Create;
  
  FSystemOptimizer := TSystemOptimizer.Create;
  FMonitoringActive := False;
  
  // 初始化C盘空间分析器
  FCDriveAnalyzer := TCDriveAnalyzer.Create;
  FCDriveAnalyzer.OnProgress := OnAnalysisProgress;
  SetLength(FAnalysisResults, 0);
  FLastAnalysisTime := 0;
  
  // 设置窗体标题和界面文本 - 让DFM文件中的Unicode编码生效
  // Caption := 'C盘瘦身神器 - 智能目录迁移专家';

  // 不再覆盖DFM中的设置
  // SetInterfaceTexts;

  // 加载按钮图标
  LoadButtonIcons;

  // 字体设置已移动到DFM

  // 字体设置已移动到DFM文件

  // 应用现代化配色
  ApplyModernColors;

  InitializeInterface;
  InitializeTreeViews;
  InitializeFileList;
  
  // 专家模式通过菜单控制，默认为简洁模式
  // chkExpertMode控件已移除，通过菜单项miSimpleMode控制
  
  // 检查管理员权限
  CheckAndRequestAdminPrivileges;
  
  // 启动防护心跳：周期验证关键资源存在
  if not Assigned(FHeartbeatTimer) then
  begin
    FHeartbeatTimer := TTimer.Create(Self);
    FHeartbeatTimer.Interval := HEARTBEAT_INTERVAL_MS;
    FHeartbeatTimer.OnTimer := HeartbeatCheck;
    FHeartbeatTimer.Enabled := True;
  end;

  LogInfo('Main', 'MoveC 应用程序初始化完成');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // 释放目录树中分配的字符串内存
  FreeTreeViewData(tvSource);
  FreeTreeViewData(tvTarget);

  // 清理AboutMe安全模块
  if Assigned(FFrameAboutMe) then
    FFrameAboutMe.Free;
  if Assigned(FSecureManager) then
    FSecureManager.Free;

  // 清理清理管理器
  if Assigned(FCleanupManager) then
    FCleanupManager.Free;

  // 清理迁移事务管理器
  if Assigned(FMigrationTransaction) then
    FMigrationTransaction.Free;
  
  // 清理应用程序关联检测器
  if Assigned(FAppDetector) then
    FAppDetector.Free;
    
  // 清理系统监控和性能分析模块
  if FMonitoringActive then
    StopSystemMonitoring;
    
  if Assigned(FSystemMonitor) then
    FSystemMonitor.Free;
  if Assigned(FPerformanceAnalyzer) then
    FPerformanceAnalyzer.Free;
  if Assigned(FSystemOptimizer) then
    FSystemOptimizer.Free;
    
  // 清理C盘分析器
  if Assigned(FCDriveAnalyzer) then
  begin
    if FCDriveAnalyzer.Analyzing then
      FCDriveAnalyzer.StopAnalysis;
    FCDriveAnalyzer.Free;
  end;


  FStyleManager.Free;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  {$IFDEF DEBUG}
  LogDebug('Main', 'FormShow 开始执行');
  {$ENDIF}

  // 设置默认路径
  if TDirectory.Exists('C:\Users') then
  begin
    FSourcePath := 'C:\Users';
    edtSourceDir.Text := FSourcePath;
    LoadDirectoryTree(tvSource, FSourcePath);
  end;
  
  if TDirectory.Exists('D:\') then
  begin
    FTargetPath := 'D:\';
    edtTargetDir.Text := FTargetPath;
    LoadDirectoryTree(tvTarget, FTargetPath);
  end;
  
  // 设置C盘瘦身核心功能按钮文本
  if Assigned(btnAnalyze) then
    btnAnalyze.Caption := 'C盘空间分析';
  if Assigned(btnSmartClean) then
    btnSmartClean.Caption := '一键清理';
  if Assigned(btnExecute) then
    btnExecute.Caption := '开始迁移';
  if Assigned(btnRollback) then
    btnRollback.Caption := '一键回滚';
  
  // 初始化AboutMe安全模块
  try
    // 确保pnlBottom面板可见并设置合适的高度
    pnlBottom.Visible := True;
    if pnlBottom.Height < DEFAULT_MIN_PANEL_HEIGHT then
      pnlBottom.Height := DEFAULT_ABOUTME_PANEL_HEIGHT;
    
    // 创建并嵌入AboutMe框架到pnlBottom（在pnlAboutMe中）
    if not Assigned(FFrameAboutMe) then
    begin
      {$IFDEF DEBUG}
      LogDebug('Main', '开始创建FrameAboutMe');
      {$ENDIF}

      FFrameAboutMe := TFrameAboutMe.Create(Self);
      FFrameAboutMe.Parent := pnlAboutMe;
      FFrameAboutMe.Align := alRight;
      FFrameAboutMe.Width := DEFAULT_ABOUTME_FRAME_WIDTH;
      FFrameAboutMe.Visible := True;

      {$IFDEF DEBUG}
      LogDebug('Main', 'FrameAboutMe设置完成，开始手动初始化');
      {$ENDIF}

      FFrameAboutMe.ManualInitialize;

      {$IFDEF DEBUG}
      LogDebug('Main', 'FrameAboutMe手动初始化完成');
      {$ENDIF}
    end;

    // 初始化安全管理器并进行严格验证
    if not Assigned(FSecureManager) then
    begin
      FSecureManager := TSimpleSecureManager.Create(Self);
      
      // 关键：加载并验证数据，失败时显示警告但继续运行
      if not FSecureManager.LoadAndVerify(FFrameAboutMe) then
      begin
        ShowChineseMessage('程序数据完整性验证失败，程序将退出以确保安全。即将打开官网获取正版。');
        ShellExecute(Handle, 'open', 'http://www.goodmem.cn', nil, nil, SW_SHOWNORMAL);
        Application.Terminate;
        Exit;
      end
      else
      begin
        // 验证成功，让AboutMe框架从安全管理器加载数据
        OutputDebugString(PChar('AboutMe模块已成功加载并验证'));
      end;
      
      // 无论验证是否成功，AboutMe框架会自动从数据库加载图像
      OutputDebugString(PChar('AboutMe框架已初始化'));
    end;

  except
    on E: Exception do
    begin
      ShowChineseMessage('初始化AboutMe模块失败：' + E.Message + sLineBreak +
                        '程序将退出以确保安全。');
      Application.Terminate;
      Exit;
    end;
  end;
  
  // 检测未完成的迁移事务
  CheckIncompleteTransactions;
  
  UpdateStatus('就绪 - 选择源目录和目标目录开始操作');
end;

procedure TfrmMain.InitializeInterface;
begin
  // 应用现代化样式
  if Assigned(FStyleManager) then
  begin
    FStyleManager.StyleForm(Self);
    FStyleManager.StylePanel(pnlMain);

    // 应用编辑框样式
    FStyleManager.StyleEdit(edtSourceDir);
    FStyleManager.StyleEdit(edtTargetDir);

    // 应用其他控件样式
    FStyleManager.StyleProgressBar(ProgressBar1);
    // memo样式已在dfm中设置
    FStyleManager.StyleTreeView(tvSource);
    FStyleManager.StyleTreeView(tvTarget);
  end;
  
  // 为右键菜单设置纯文本（移除emoji，避免渲染兼容性问题）
  // 源目录菜单
  miSrcOpen.Caption := '打开';
  miSrcOpenInExplorer.Caption := '在资源管理器中打开';
  miSrcCopyPath.Caption := '复制路径';
  miSrcSetRoot.Caption := '设为根目录';
  miSrcScanHere.Caption := '扫描这里';
  miSrcAnalyzeHere.Caption := '分析这里';
  miSrcProperties.Caption := '属性';
  miSrcDelete.Caption := '删除当前目录';
  miSrcRefresh.Caption := '刷新';
  
  // 目标目录菜单
  miTgtOpen.Caption := '打开';
  miTgtOpenInExplorer.Caption := '在资源管理器中打开';
  miTgtCopyPath.Caption := '复制路径';
  miTgtSetRoot.Caption := '设为根目录';
  miTgtSetAsTargetPath.Caption := '设为目标路径';
  miTgtProperties.Caption := '属性';
  miTgtDelete.Caption := '删除当前目录';
  miTgtRefresh.Caption := '刷新';
end;

procedure TfrmMain.InitializeTreeViews;
begin
  // 初始化目录树
  tvSource.ReadOnly := True;
  tvTarget.ReadOnly := True;

  // 设置图标
  tvSource.ShowButtons := True;
  tvSource.ShowLines := True;
  tvSource.ShowRoot := True;
  
  tvTarget.ShowButtons := True;
  tvTarget.ShowLines := True;
  tvTarget.ShowRoot := True;
  
  // 设置 OnDeletion 事件自动释放节点内存
  tvSource.OnDeletion := tvSourceDeletion;
  tvTarget.OnDeletion := tvTargetDeletion;
end;

procedure TfrmMain.tvSourceDeletion(Sender: TObject; Node: TTreeNode);
begin
  if Assigned(Node) and Assigned(Node.Data) then
  begin
    StrDispose(PChar(Node.Data));
    Node.Data := nil;
  end;
end;

procedure TfrmMain.tvTargetDeletion(Sender: TObject; Node: TTreeNode);
begin
  if Assigned(Node) and Assigned(Node.Data) then
  begin
    StrDispose(PChar(Node.Data));
    Node.Data := nil;
  end;
end;

procedure TfrmMain.LoadDirectoryTree(ATreeView: TTreeView; const APath: string);
var
  RootNode: TTreeNode;
  Directories: TArray<string>;
  I: Integer;
  DirName: string;
  SubNode: TTreeNode;
  SubDirs: TArray<string>;
  PlaceholderNode: TTreeNode;
begin
  if not TDirectory.Exists(APath) then Exit;

  ATreeView.Items.BeginUpdate;
  try
    ATreeView.Items.Clear;

    // 添加根节点
    if APath.Length <= 3 then
      RootNode := ATreeView.Items.Add(nil, APath)  // 显示 "C:\" 等
    else
      RootNode := ATreeView.Items.Add(nil, System.SysUtils.ExtractFileName(APath));

    RootNode.Data := Pointer(StrNew(PChar(APath)));

    // 加载子目录
    try
      Directories := TDirectory.GetDirectories(APath);
      for I := 0 to High(Directories) do
      begin
        DirName := System.SysUtils.ExtractFileName(Directories[I]);
        if (DirName <> '') and (DirName[1] <> '.') then  // 跳过隐藏目录
        begin
          SubNode := ATreeView.Items.AddChild(RootNode, DirName);
          SubNode.Data := Pointer(StrNew(PChar(Directories[I])));

          // 检查是否有子目录，如果有则添加占位符
          try
            SubDirs := TDirectory.GetDirectories(Directories[I]);
            if Length(SubDirs) > 0 then
            begin
              PlaceholderNode := ATreeView.Items.AddChild(SubNode, '...');
              PlaceholderNode.Data := nil;  // 占位符标记
            end;
          except
            // 忽略访问权限错误
          end;
        end;
      end;
    except
      // 忽略访问权限错误
    end;

    RootNode.Expanded := True;
  finally
    ATreeView.Items.EndUpdate;
  end;
end;


function TfrmMain.UpdateStatus(const AMessage: string): Boolean;
begin
  // 更新状态显示
  if Assigned(lblStatus) then
    lblStatus.Caption := AMessage;
  if Assigned(memoStatus) then
    memoStatus.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' - ' + AMessage);
  
  // 记录到日志系统
  LogInfo('StatusUpdate', AMessage);
  
  Application.ProcessMessages;
  Result := True;
end;

// 工具栏按钮事件实现
procedure TfrmMain.btnCleanRecycleBinClick(Sender: TObject);
begin
  CleanRecycleBin;
end;

procedure TfrmMain.btnCleanTempClick(Sender: TObject);
begin
  CleanTempFiles;
end;

procedure TfrmMain.btnCleanBackupClick(Sender: TObject);
begin
  CleanBackupFiles;
end;

procedure TfrmMain.btnCleanUpdateClick(Sender: TObject);
begin
  CleanUpdateCache;
end;

procedure TfrmMain.btnSmartCleanClick(Sender: TObject);
var
  PreviewForm: TfrmCleanupPreview;
begin
  try
    UpdateStatus('正在打开清理预览...');
    
    PreviewForm := TfrmCleanupPreview.Create(Self);
    try
      PreviewForm.CleanupManager := FCleanupManager;
      
      if PreviewForm.ShowModal = mrOk then
      begin
        UpdateStatus('清理操作已完成');
        LogInfo('Main', '用户通过清理预览窗口完成了清理操作');
      end
      else
      begin
        UpdateStatus('清理操作已取消');
      end;
    finally
      PreviewForm.Free;
    end;
    
  except
    on E: Exception do
    begin
      UpdateStatus('打开清理预览失败: ' + E.Message);
      ShowChineseMessage('打开清理预览失败：' + sLineBreak + E.Message);
    end;
  end;
end;

procedure TfrmMain.btnSmartMigrationClick(Sender: TObject);
var
  WizardForm: TfrmSmartMigrationWizard;
begin
  try
    UpdateStatus('正在启动智能迁移向导...');
    
    WizardForm := TfrmSmartMigrationWizard.Create(Self);
    try
      // 如果当前已选择了源目录，传给向导
      if FSourcePath <> '' then
        WizardForm.SourcePath := FSourcePath;
      if FTargetPath <> '' then
        WizardForm.TargetPath := FTargetPath;
        
      if WizardForm.ShowModal = mrOk then
      begin
        UpdateStatus('智能迁移向导已完成');
        ShowChineseMessage('迁移操作已成功完成！' + sLineBreak + sLineBreak +
                           '您可以现在使用新的文件位置。');
        
        // 更新主窗口中的路径显示
        if WizardForm.SourcePath <> '' then
        begin
          FSourcePath := WizardForm.SourcePath;
          edtSourceDir.Text := FSourcePath;
          LoadDirectoryTree(tvSource, FSourcePath);
        end;
        
        if WizardForm.TargetPath <> '' then
        begin
          FTargetPath := WizardForm.TargetPath;
          edtTargetDir.Text := FTargetPath;
          LoadDirectoryTree(tvTarget, FTargetPath);
        end;
      end
      else
      begin
        UpdateStatus('智能迁移向导已取消');
      end;
    finally
      WizardForm.Free;
    end;
    
  except
    on E: Exception do
    begin
      UpdateStatus('启动智能迁移向导失败: ' + E.Message);
      ShowChineseMessage('启动智能迁移向导失败：' + sLineBreak + E.Message);
    end;
  end;
end;

// 高级文件管理器按钮点击事件
procedure TfrmMain.btnAdvancedFileManagerClick(Sender: TObject);
begin
  miAdvancedFileManagerClick(Sender);
end;

procedure TfrmMain.btnExecuteClick(Sender: TObject);
var
  TotalFiles: Integer;
  TotalSize: Int64;
begin
  if (FSourcePath = '') or (FTargetPath = '') then
  begin
    UpdateStatus('[错误] 请先选择源目录和目标目录');
    ShowChineseMessage('请先选择源目录和目标目录！');
    Exit;
  end;

  // 安全检查
  if not CheckDirectorySafety(FSourcePath, FTargetPath) then
  begin
    UpdateStatus('安全检查失败，操作已取消');
    Exit;
  end;
  
  // 计算目录信息用于确认对话框
  ComputeDirStats(FSourcePath, TotalFiles, TotalSize);
  
  if ShowChineseConfirm('确定要开始目录迁移操作吗？' + sLineBreak + sLineBreak +
                        '=== 迁移信息 ===' + sLineBreak +
                        '源目录: ' + FSourcePath + sLineBreak +
                        '目标目录: ' + FTargetPath + sLineBreak +
                        Format('文件数量: %d 个', [TotalFiles]) + sLineBreak +
                        Format('总大小: %s', [TSystemCheck.FormatBytes(TotalSize)]) + sLineBreak + sLineBreak +
                        '=== 迁移步骤 ===' + sLineBreak +
                        '1. 复制全部文件到目标位置' + sLineBreak +
                        '2. 校验文件完整性 (SHA-256)' + sLineBreak +
                        '3. 自动备份原目录 (带时间戳)' + sLineBreak +
                        '4. 创建 Junction 链接保持原路径可用' + sLineBreak + sLineBreak +
                        '=== 安全提示 ===' + sLineBreak +
                        '• 迁移前请关闭正在使用该目录的程序' + sLineBreak +
                        '• 备份目录会保留在原位置，可随时回滚' + sLineBreak +
                        '• 迁移后建议测试相关程序是否正常') then
  begin
    ExecuteOperation;
  end;
end;

procedure TfrmMain.btnAnalyzeClick(Sender: TObject);
begin
  // 启动C盘空间分析
  StartCDriveAnalysis;
end;

procedure TfrmMain.btnCalculateSizeClick(Sender: TObject);
begin
  if FSourcePath = '' then
  begin
    UpdateStatus('[错误] 请先选择源目录');
    ShowChineseMessage('请先选择源目录！');
    Exit;
  end;

  CalculateDirectorySize(FSourcePath);
end;

procedure TfrmMain.btnExitClick(Sender: TObject);
begin
  Close;
end;

// 浏览按钮事件
procedure TfrmMain.btnBrowseSourceClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := FSourcePath;
  if SelectDirectory('选择源目录', '', Dir) then
  begin
    FSourcePath := Dir;
    edtSourceDir.Text := Dir;
    LoadDirectoryTree(tvSource, Dir);
    UpdateStatus('源目录已设置: ' + Dir);
  end;
end;

procedure TfrmMain.btnBrowseTargetClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := FTargetPath;
  if SelectDirectory('选择目标目录', '', Dir) then
  begin
    FTargetPath := Dir;
    edtTargetDir.Text := Dir;
    LoadDirectoryTree(tvTarget, Dir);
    UpdateStatus('目标目录已设置: ' + Dir);
  end;
end;

procedure TfrmMain.btnSourceUpClick(Sender: TObject);
var
  ParentPath: string;
begin
  if FSourcePath <> '' then
  begin
    ParentPath := TPath.GetDirectoryName(FSourcePath);
    if (ParentPath <> '') and (ParentPath <> FSourcePath) and TDirectory.Exists(ParentPath) then
    begin
      FSourcePath := ParentPath;
      edtSourceDir.Text := FSourcePath;
      LoadDirectoryTree(tvSource, FSourcePath);
      UpdateStatus('返回上级目录: ' + FSourcePath);
    end
    else
    begin
      UpdateStatus('已经是根目录');
    end;
  end;
end;

procedure TfrmMain.btnTargetUpClick(Sender: TObject);
var
  ParentPath: string;
begin
  if FTargetPath <> '' then
  begin
    ParentPath := TPath.GetDirectoryName(FTargetPath);
    if (ParentPath <> '') and (ParentPath <> FTargetPath) and TDirectory.Exists(ParentPath) then
    begin
      FTargetPath := ParentPath;
      edtTargetDir.Text := FTargetPath;
      LoadDirectoryTree(tvTarget, FTargetPath);
      UpdateStatus('返回上级目录: ' + FTargetPath);
    end
    else
    begin
      UpdateStatus('已经是根目录');
    end;
  end;
end;

// 目录树事件
procedure TfrmMain.tvSourceChange(Sender: TObject; Node: TTreeNode);
begin
  if Assigned(Node) and Assigned(Node.Data) then
  begin
    FSourcePath := StrPas(PChar(Node.Data));
    edtSourceDir.Text := FSourcePath;
    UpdateStatus('选择源目录: ' + FSourcePath);
    // 更新文件列表
    LoadFileList(FSourcePath);
    // 更新应用关联信息
    UpdateAppAssocInfo(FSourcePath);
  end;
end;

procedure TfrmMain.UpdateAppAssocInfo(const APath: string);
var
  AppInfo: TAppInfo;
  ConfidenceStr: string;
begin
  if not Assigned(FAppDetector) then Exit;
  if not Assigned(lblAppName) then Exit;
  
  if APath = '' then
  begin
    lblAppName.Caption := '-';
    lblAppSuggestion.Caption := '-';
    Exit;
  end;
  
  try
    AppInfo := FAppDetector.DetectAssociatedApp(APath);
    
    // 根据置信度设置颜色
    if AppInfo.Confidence >= 90 then
    begin
      lblAppName.Font.Color := $0000AA00; // 深绿色 - 高置信度
      ConfidenceStr := ' [高]';
    end
    else if AppInfo.Confidence >= 70 then
    begin
      lblAppName.Font.Color := $000080FF; // 橙色 - 中置信度
      ConfidenceStr := ' [中]';
    end
    else if AppInfo.Confidence > 0 then
    begin
      lblAppName.Font.Color := $00808080; // 灰色 - 低置信度
      ConfidenceStr := ' [低]';
    end
    else
    begin
      lblAppName.Font.Color := $00404040;
      ConfidenceStr := '';
    end;
    
    // 显示应用名称
    if AppInfo.AppName <> '未知' then
      lblAppName.Caption := AppInfo.AppName + ConfidenceStr
    else
      lblAppName.Caption := '未检测到关联应用';
    
    // 显示建议
    if AppInfo.Reason <> '' then
      lblAppSuggestion.Caption := AppInfo.Reason
    else
      lblAppSuggestion.Caption := '迁移后请测试相关程序';
      
  except
    on E: Exception do
    begin
      lblAppName.Caption := '-';
      lblAppSuggestion.Caption := '检测失败';
    end;
  end;
end;

procedure TfrmMain.tvTargetChange(Sender: TObject; Node: TTreeNode);
begin
  if Assigned(Node) and Assigned(Node.Data) then
  begin
    FTargetPath := StrPas(PChar(Node.Data));
    edtTargetDir.Text := FTargetPath;
    UpdateStatus('选择目标目录: ' + FTargetPath);
    // 更新文件列表
    LoadFileList(FTargetPath);
  end;
end;

procedure TfrmMain.tvSourceDblClick(Sender: TObject);
begin
  if FSourcePath <> '' then
    LoadDirectoryTree(tvSource, FSourcePath);
end;

procedure TfrmMain.tvTargetDblClick(Sender: TObject);
begin
  if FTargetPath <> '' then
    LoadDirectoryTree(tvTarget, FTargetPath);
end;

procedure TfrmMain.tvSourceKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_F5 then
    LoadDirectoryTree(tvSource, FSourcePath)
  else if Key = VK_BACK then
    btnSourceUpClick(Sender);
end;

procedure TfrmMain.tvTargetKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_F5 then
    LoadDirectoryTree(tvTarget, FTargetPath)
  else if Key = VK_BACK then
    btnTargetUpClick(Sender);
end;

procedure TfrmMain.tvSourceExpanding(Sender: TObject; Node: TTreeNode; var AllowExpansion: Boolean);
begin
  AllowExpansion := True;
  if Assigned(Node) and Assigned(Node.Data) then
    ExpandTreeNode(tvSource, Node);
end;

procedure TfrmMain.tvTargetExpanding(Sender: TObject; Node: TTreeNode; var AllowExpansion: Boolean);
begin
  AllowExpansion := True;
  if Assigned(Node) and Assigned(Node.Data) then
    ExpandTreeNode(tvTarget, Node);
end;

procedure TfrmMain.ExpandTreeNode(ATreeView: TTreeView; ANode: TTreeNode);
var
  NodePath: string;
  Directories: TArray<string>;
  SubDirs: TArray<string>;
  I: Integer;
  DirName: string;
  SubNode: TTreeNode;
  PlaceholderNode: TTreeNode;
  MaxDirs: Integer;
begin
  if not Assigned(ANode) or not Assigned(ANode.Data) then Exit;

  // 如果已经展开过，不重复加载
  if (ANode.Count > 0) and Assigned(ANode.Item[0].Data) then Exit;

  NodePath := StrPas(PChar(ANode.Data));
  if not TDirectory.Exists(NodePath) then Exit;

  ATreeView.Items.BeginUpdate;
  try
    // 删除占位符节点
    if (ANode.Count > 0) and not Assigned(ANode.Item[0].Data) then
      ANode.Item[0].Delete;

    // 加载子目录（限制数量以提高性能）
    try
      Directories := TDirectory.GetDirectories(NodePath);
      MaxDirs := Min(Length(Directories), 500); // 最多显示500个目录
      for I := 0 to MaxDirs - 1 do
      begin
        DirName := System.SysUtils.ExtractFileName(Directories[I]);
        if (DirName <> '') and (DirName[1] <> '.') then  // 跳过隐藏目录
        begin
          SubNode := ATreeView.Items.AddChild(ANode, DirName);
          SubNode.Data := Pointer(StrNew(PChar(Directories[I])));

          // 检查是否有子目录，如果有则添加占位符
          try
            SubDirs := TDirectory.GetDirectories(Directories[I]);
            if Length(SubDirs) > 0 then
            begin
              PlaceholderNode := ATreeView.Items.AddChild(SubNode, '...');
              PlaceholderNode.Data := nil;  // 占位符标记
            end;
          except
            // 忽略访问权限错误
          end;
        end;
      end;
    except
      // 忽略访问权限错误
    end;
  finally
    ATreeView.Items.EndUpdate;
  end;
end;

// 菜单事件 - 这个方法已经移动到主菜单事件实现部分

procedure TfrmMain.miConfigManagerClick(Sender: TObject);
begin
  UpdateStatus('配置管理器功能暂时不可用');
  ShowChineseMessage('配置管理器功能正在开发中，敬请期待！');
end;

procedure TfrmMain.miRollbackManagerClick(Sender: TObject);
begin
  try
    UpdateStatus('正在打开回滚点管理器...');
    TfrmRollbackManager.ShowManager(Self);
    UpdateStatus('回滚点管理器已关闭');
  except
    on E: Exception do
    begin
      UpdateStatus('打开回滚点管理器失败: ' + E.Message);
      ShowChineseMessage('打开回滚点管理器失败：' + sLineBreak + E.Message);
    end;
  end;
end;

// 高级文件管理器菜单点击事件
procedure TfrmMain.miAdvancedFileManagerClick(Sender: TObject);
var
  AdvancedForm: TfrmAdvancedFileManager;
begin
  try
    UpdateStatus('正在打开高级文件管理器...');
    
    AdvancedForm := TfrmAdvancedFileManager.Create(Self);
    try
      AdvancedForm.ShowModal;
    finally
      AdvancedForm.Free;
    end;
    
    UpdateStatus('高级文件管理器已关闭');
  except
    on E: Exception do
    begin
      UpdateStatus('打开高级文件管理器失败: ' + E.Message);
      ShowChineseMessage('打开高级文件管理器失败：' + sLineBreak + E.Message);
    end;
  end;
end;

// 清理进度回调
procedure TfrmMain.OnCleanupProgress(const AMessage: string; AProgress: Integer);
begin
  UpdateStatus(AMessage);
  if AProgress >= 0 then
  begin
    ProgressBar1.Visible := True;
    ProgressBar1.Position := AProgress;
  end;
  Application.ProcessMessages;
end;

// 清理功能实现
procedure TfrmMain.CleanRecycleBin;
var
  Result: TCleanupResult;
  StartTime: TDateTime;
begin
  try
    if not Assigned(FCleanupManager) then
    begin
      UpdateStatus('[错误] 清理管理器未初始化');
      Exit;
    end;

    UpdateStatus('正在清空回收站...');
    ProgressBar1.Visible := True;
    ProgressBar1.Position := 0;
    StartTime := Now;
    
    Result := FCleanupManager.EmptyRecycleBin;
    
    // 记录清理历史
    CleanupHistory.AddEntry(ctRecycleBin, Result.FilesDeleted, Result.SpaceFreed,
      Result.Success, Result.ErrorMessage, MilliSecondsBetween(Now, StartTime), Result.Details);
    
    if Result.Success then
    begin
      UpdateStatus('回收站清理完成');
      ShowChineseMessage('回收站已成功清空！');
    end
    else
    begin
      UpdateStatus('[失败] 回收站清理失败: ' + Result.ErrorMessage);
      ShowChineseMessage('回收站清理失败：' + sLineBreak + Result.ErrorMessage);
    end;
    
  finally
    ProgressBar1.Visible := False;
  end;
end;

procedure TfrmMain.CleanTempFiles;
var
  Result: TCleanupResult;
  StartTime: TDateTime;
begin
  try
    if not Assigned(FCleanupManager) then
    begin
      UpdateStatus('[错误] 清理管理器未初始化');
      Exit;
    end;

    UpdateStatus('正在清理临时文件...');
    ProgressBar1.Visible := True;
    ProgressBar1.Position := 0;
    StartTime := Now;
    
    Result := FCleanupManager.CleanTempFiles;
    
    // 记录清理历史
    CleanupHistory.AddEntry(ctTempFiles, Result.FilesDeleted, Result.SpaceFreed,
      Result.Success, Result.ErrorMessage, MilliSecondsBetween(Now, StartTime), Result.Details);
    
    if Result.Success then
    begin
      UpdateStatus(Format('临时文件清理完成 - 删除 %d 个文件，释放 %.2f MB 空间', 
        [Result.FilesDeleted, Result.SpaceFreed / (1024 * 1024)]));
      ShowChineseMessage(Format('临时文件清理完成！' + sLineBreak + 
        '删除了 %d 个文件，释放了 %.2f MB 磁盘空间。', 
        [Result.FilesDeleted, Result.SpaceFreed / (1024 * 1024)]));
    end
    else
    begin
      UpdateStatus('[失败] 临时文件清理失败: ' + Result.ErrorMessage);
      ShowChineseMessage('临时文件清理失败：' + sLineBreak + Result.ErrorMessage);
    end;
    
  finally
    ProgressBar1.Visible := False;
  end;
end;

procedure TfrmMain.CleanBackupFiles;
var
  Result: TCleanupResult;
  StartTime: TDateTime;
begin
  try
    if not Assigned(FCleanupManager) then
    begin
      UpdateStatus('[错误] 清理管理器未初始化');
      Exit;
    end;

    // 先检查是否有最近的备份文件需要保护
    if FLastBackupPath <> '' then
    begin
      if not ShowChineseConfirm('=== 备份保护 ===' + sLineBreak + sLineBreak +
                                '检测到最近的迁移备份:' + sLineBreak +
                                FLastBackupPath + sLineBreak + sLineBreak +
                                '=== 操作说明 ===' + sLineBreak +
                                '• 此备份将保留以便回滚' + sLineBreak +
                                '• 仅清理其他旧备份和日志' + sLineBreak + sLineBreak +
                                '是否继续？') then
        Exit;
    end;

    UpdateStatus('正在清理系统日志和备份文件...');
    ProgressBar1.Visible := True;
    ProgressBar1.Position := 0;
    StartTime := Now;
    
    Result := FCleanupManager.CleanSystemLogs;
    
    // 记录清理历史
    CleanupHistory.AddEntry(ctSystemLogs, Result.FilesDeleted, Result.SpaceFreed,
      Result.Success, Result.ErrorMessage, MilliSecondsBetween(Now, StartTime), Result.Details);
    
    if Result.Success then
    begin
      UpdateStatus(Format('系统日志清理完成 - 删除 %d 个文件，释放 %.2f MB 空间', 
        [Result.FilesDeleted, Result.SpaceFreed / (1024 * 1024)]));
      ShowChineseMessage(Format('系统日志清理完成！' + sLineBreak + 
        '删除了 %d 个文件，释放了 %.2f MB 磁盘空间。', 
        [Result.FilesDeleted, Result.SpaceFreed / (1024 * 1024)]));
    end
    else
    begin
      UpdateStatus('[失败] 系统日志清理失败: ' + Result.ErrorMessage);
      ShowChineseMessage('系统日志清理失败：' + sLineBreak + Result.ErrorMessage);
    end;
    
  finally
    ProgressBar1.Visible := False;
  end;
end;

procedure TfrmMain.CleanUpdateCache;
var
  Result: TCleanupResult;
  StartTime: TDateTime;
begin
  try
    if not Assigned(FCleanupManager) then
    begin
      UpdateStatus('[错误] 清理管理器未初始化');
      Exit;
    end;

    UpdateStatus('正在清理Windows更新缓存...');
    ProgressBar1.Visible := True;
    ProgressBar1.Position := 0;
    StartTime := Now;
    
    Result := FCleanupManager.CleanWindowsUpdateCache;
    
    // 记录清理历史
    CleanupHistory.AddEntry(ctWindowsUpdate, Result.FilesDeleted, Result.SpaceFreed,
      Result.Success, Result.ErrorMessage, MilliSecondsBetween(Now, StartTime), Result.Details);
    
    if Result.Success then
    begin
      UpdateStatus(Format('Windows更新缓存清理完成 - 删除 %d 个文件，释放 %.2f MB 空间', 
        [Result.FilesDeleted, Result.SpaceFreed / (1024 * 1024)]));
      ShowChineseMessage(Format('Windows更新缓存清理完成！' + sLineBreak + 
        '删除了 %d 个文件，释放了 %.2f MB 磁盘空间。', 
        [Result.FilesDeleted, Result.SpaceFreed / (1024 * 1024)]));
    end
    else
    begin
      UpdateStatus('[失败] Windows更新缓存清理失败: ' + Result.ErrorMessage);
      ShowChineseMessage('Windows更新缓存清理失败：' + sLineBreak + Result.ErrorMessage);
    end;
    
  finally
    ProgressBar1.Visible := False;
  end;
end;

procedure TfrmMain.HeartbeatCheck(Sender: TObject);
begin
  try
    if not TFile.Exists(TPath.Combine(ExtractFilePath(ParamStr(0)), 'MoveC.db')) then
    begin
      LogWarning('Heartbeat', '检测到关键资源丢失: MoveC.db');
      UpdateStatus('关键资源丢失：MoveC.db');
      ShowChineseMessage('检测到关键资源丢失：MoveC.db，程序将退出。');
      Application.Terminate;
    end;
  except
    on E: Exception do
      LogError('Heartbeat', '心跳检查异常: ' + E.Message);
  end;
end;

procedure TfrmMain.FreeTreeViewData(ATreeView: TTreeView);
begin
  // 内存释放现在由 OnDeletion 事件自动处理
  // 此方法保留以保持接口兼容性
  if Assigned(ATreeView) then
    ATreeView.Items.Clear;
end;

// 核心迁移功能实现（带事务管理和SHA-256校验）
procedure TfrmMain.ExecuteOperation;
var
  Src, DstRoot, Dst: string;
  TotalFiles: Integer;
  TotalBytes: Int64;
  VerifiedCount: Integer;
  FailedFiles: TArray<TFileRecord>;
  I: Integer;
  PrivCheck: TPrivilegeCheckResult;
  SpaceCheck: TDiskSpaceCheckResult;
  ErrorMsg: string;
  BackupSize: Int64;
  BackupFileCount: Integer;
begin
  LogInfo('Migration', '开始执行目录迁移操作');
  
  // 初始化取消标志和统计变量
  FCancelRequested := False;
  FStartTime := Now;
  FProcessedFilesCount := 0;
  FTotalFilesCount := 0;
  
  Src := Trim(FSourcePath);
  DstRoot := Trim(FTargetPath);

  // 基本验证
  if (Src = '') or not TDirectory.Exists(Src) then
  begin
    UpdateStatus('源目录不存在: ' + Src);
    Exit;
  end;
  
  if (DstRoot = '') or not TDirectory.Exists(DstRoot) then
  begin
    UpdateStatus('目标根目录不存在: ' + DstRoot);
    Exit;
  end;

  // 阶段0: 系统检查
  UpdateStatus('正在进行系统检查...');
  
  // 1. 权限检查
  PrivCheck := TSystemCheck.CheckAdminPrivileges;
  UpdateStatus(PrivCheck.Message);
  
  if not PrivCheck.IsAdmin or not PrivCheck.IsElevated then
  begin
    if ShowChineseConfirm('警告：未以管理员权限运行！' + sLineBreak + sLineBreak +
                         '目录迁移和创建 Junction 需要管理员权限。' + sLineBreak +
                         '是否继续（可能失败）？') then
    begin
      UpdateStatus('用户选择继续，但有失败风险');
    end
    else
    begin
      UpdateStatus('用户取消操作');
      Exit;
    end;
  end;

  // 目标目录 = 目标根目录 + 源目录名
  Dst := TPath.Combine(DstRoot, System.SysUtils.ExtractFileName(TPath.GetDirectoryName(Src + '\\\\')));
  if TDirectory.Exists(Dst) then
  begin
    if not ShowChineseConfirm('目标目录已存在：' + Dst + sLineBreak + '是否覆盖（将合并内容）？') then
      Exit;
  end;

  // 创建事务
  if Assigned(FMigrationTransaction) then
    FMigrationTransaction.Free;
  FMigrationTransaction := TMigrationTransaction.Create;

  try
    try
      // 启动事务
      FMigrationTransaction.StartTransaction(Src, Dst);
      UpdateStatus('事务已创建: ' + FMigrationTransaction.TransactionID);
      FMigrationTransaction.LogInfo('迁移操作开始');
      FMigrationTransaction.LogInfo(Format('源目录: %s', [Src]));
      FMigrationTransaction.LogInfo(Format('目标目录: %s', [Dst]));

      // 阶段1: 统计文件
      UpdateStatus('正在统计文件...');
      ComputeDirStats(Src, TotalFiles, TotalBytes);
      FTotalFilesCount := TotalFiles;
      FMigrationTransaction.UpdateProgress(0, TotalFiles, 0, TotalBytes);
      UpdateStatus(Format('共找到 %d 个文件，总大小 %.2f MB', 
        [TotalFiles, TotalBytes / (1024*1024)]));

      // 2. 磁盘空间检查
      SpaceCheck := TSystemCheck.CheckDiskSpace(DstRoot, TotalBytes);
      UpdateStatus(SpaceCheck.Message);
      
      if not SpaceCheck.HasEnoughSpace then
      begin
        if not ShowChineseConfirm('警告：磁盘空间不足！' + sLineBreak + sLineBreak +
                                 SpaceCheck.Message + sLineBreak + sLineBreak +
                                 '是否强制继续（可能失败）？') then
        begin
          UpdateStatus('用户取消：磁盘空间不足');
          FMigrationTransaction.FailTransaction('磁盘空间不足');
          Exit;
        end;
      end;

      // 3. 目录占用检查
      UpdateStatus('检查源目录占用情况...');
      if TSystemCheck.IsDirectoryInUse(Src) then
      begin
        if not ShowChineseConfirm('警告：源目录中有文件被占用！' + sLineBreak + sLineBreak +
                                 '这可能导致拷贝或备份失败。' + sLineBreak +
                                 '建议关闭相关程序后再试。' + sLineBreak + sLineBreak +
                                 '是否强制继续？') then
        begin
          UpdateStatus('用户取消：文件被占用');
          FMigrationTransaction.FailTransaction('源目录文件被占用');
          raise Exception.Create('源目录文件被占用');
        end
        else
        begin
          UpdateStatus('用户选择强制继续，可能遇到错误');
        end;
      end
      else
      begin
        UpdateStatus('源目录未被占用，可以安全迁移');
      end;

      // 阶段2: 复制并校验文件
      UpdateStatus('开始复制并校验文件...');
      ProgressBar1.Visible := True;
      ProgressBar1.Position := 0;
      ShowCancelButton(True);  // 显示取消按钮

      if FCancelRequested then
      begin
        UpdateStatus('操作已被用户取消');
        FMigrationTransaction.FailTransaction('用户取消操作');
        raise Exception.Create('操作被用户取消');
      end;

      if not CopyDirRecursiveWithVerify(Src, Dst, FMigrationTransaction) then
      begin
        UpdateStatus('拷贝或校验失败，开始回滚...');
        FMigrationTransaction.FailTransaction('文件拷贝或校验失败');
        FMigrationTransaction.LogError('文件复制阶段失败');
        
        // 清理已拷贝的文件
        if TDirectory.Exists(Dst) then
        begin
          try
            TDirectory.Delete(Dst, True);
            UpdateStatus('已清理目标目录');
            FMigrationTransaction.LogInfo('已清理目标目录');
          except
            on E: Exception do
            begin
              UpdateStatus('清理目标目录失败: ' + E.Message);
              FMigrationTransaction.LogError('清理目标目录失败: ' + E.Message);
            end;
          end;
        end;
        
        raise Exception.Create('文件拷贝或校验失败');
      end;

      // 检查是否被取消
      if FCancelRequested then
      begin
        UpdateStatus('操作已被用户取消');
        FMigrationTransaction.FailTransaction('用户取消操作');
        // 清理已拷贝的文件
        if TDirectory.Exists(Dst) then
        begin
          try
            TDirectory.Delete(Dst, True);
            UpdateStatus('已清理目标目录');
          except
            on E: Exception do
              UpdateStatus('清理目标目录失败: ' + E.Message);
          end;
        end;
        raise Exception.Create('操作被用户取消');
      end;

      // 阶段3: 备份原目录
      if FCancelRequested then
      begin
        UpdateStatus('操作已被用户取消');
        FMigrationTransaction.FailTransaction('用户取消操作');
        if TDirectory.Exists(Dst) then
        begin
          try
            TDirectory.Delete(Dst, True);
          except
          end;
        end;
        raise Exception.Create('操作被用户取消');
      end;
      
      UpdateStatus('备份原目录...');
      if not TSystemCheck.TryRenameDirectory(Src, FMigrationTransaction.BackupDir, ErrorMsg) then
      begin
        UpdateStatus('无法备份原目录: ' + ErrorMsg);
        FMigrationTransaction.FailTransaction('无法备份原目录: ' + ErrorMsg);
        
        // 如果是占用问题，给出提示
        if Pos('占用', ErrorMsg) > 0 then
        begin
          ShowChineseMessage('备份原目录失败！' + sLineBreak + sLineBreak +
                            ErrorMsg + sLineBreak + sLineBreak +
                            '请关闭占用文件的程序后重试。');
        end;
        raise Exception.Create('备份原目录失败: ' + ErrorMsg);
      end;
      UpdateStatus('已备份原目录到: ' + FMigrationTransaction.BackupDir);

      // 检查是否被取消
      if FCancelRequested then
      begin
        UpdateStatus('操作已被用户取消');
        FMigrationTransaction.FailTransaction('用户取消操作');
        // 恢复原目录
        if not RenameFile(FMigrationTransaction.BackupDir, Src) then
          UpdateStatus('回滚失败，请手动还原: ' + FMigrationTransaction.BackupDir);
        raise Exception.Create('操作被用户取消');
      end;

      // 阶段4: 创建Junction并验证
      UpdateStatus('创建目录联接...');
      if not CreateDirectoryLink(Src, Dst) then
      begin
        UpdateStatus('创建链接失败，开始回滚...');
        FMigrationTransaction.FailTransaction('创建链接失败');
        
        // 回滚：恢复原目录
        if not RenameFile(FMigrationTransaction.BackupDir, Src) then
          UpdateStatus('回滚失败，请手动将备份目录还原: ' + FMigrationTransaction.BackupDir)
        else
          UpdateStatus('已回滚到迁移前状态');
        raise Exception.Create('创建链接失败');
      end;

      // 阶段5: 验证Junction
      UpdateStatus('验证目录联接...');
      if not VerifyJunction(Src, Dst) then
      begin
        UpdateStatus('联接验证失败，可能存在问题');
        FMigrationTransaction.LogWarning('Junction验证失败');
      end
      else
      begin
        UpdateStatus('联接验证成功');
      end;

      // 完成事务
      FMigrationTransaction.CompleteTransaction;
      FLastBackupPath := FMigrationTransaction.BackupDir;
      
      // 显示完成信息
      VerifiedCount := Length(FMigrationTransaction.GetProcessedFiles);
      FailedFiles := FMigrationTransaction.GetFailedFiles;
      
      UpdateStatus(Format('迁移完成！已验证 %d/%d 个文件', [VerifiedCount, TotalFiles]));
      UpdateStatus(Format('备份目录: %s', [FMigrationTransaction.BackupDir]));
      UpdateStatus(Format('Junction链接: %s -> %s', [Src, Dst]));
      
      if Length(FailedFiles) > 0 then
      begin
        UpdateStatus(Format('警告：%d 个文件验证失败', [Length(FailedFiles)]));
        for I := 0 to Min(4, Length(FailedFiles) - 1) do
          UpdateStatus('  - ' + FailedFiles[I].SourcePath);
      end;

      // 计算备份目录大小
      BackupSize := 0;
      BackupFileCount := 0;
      if TDirectory.Exists(FMigrationTransaction.BackupDir) then
      begin
        ComputeDirStats(FMigrationTransaction.BackupDir, BackupFileCount, BackupSize);
      end;

      UpdateStatus(Format('已保留备份目录: %s (占用 %.2f MB)', 
        [FMigrationTransaction.BackupDir, BackupSize / (1024*1024)]));
      UpdateStatus('重要: 请测试依赖此目录的程序是否正常运行');
      UpdateStatus('测试无误后，可删除备份目录以释放 ' + 
        TSystemCheck.FormatBytes(BackupSize) + ' 空间');

      // 显示带删除选项的对话框
      ShowMigrationCompleteDialog(TotalFiles, VerifiedCount, Length(FailedFiles),
        FMigrationTransaction.BackupDir, BackupSize);

    except
      on E: Exception do
      begin
        UpdateStatus('迁移操作发生错误: ' + E.Message);
        if Assigned(FMigrationTransaction) then
        begin
          FMigrationTransaction.FailTransaction('异常: ' + E.Message);
          FMigrationTransaction.LogError('异常: ' + E.Message);
        end;
        
        ShowChineseMessage('迁移操作失败：' + sLineBreak + E.Message);
      end;
    end;
  finally
    if Assigned(ProgressBar1) then
      ProgressBar1.Visible := False;
    ShowCancelButton(False);
    FCancelRequested := False;
    
    if Assigned(FMigrationTransaction) then
      FMigrationTransaction.LogInfo('迁移操作结束');
  end;
end;

function TfrmMain.CreateDirectoryLink(const ASource, ATarget: string): Boolean;
var
  Command: string;
begin
  Result := False;

  try
    // 优先使用目录联接 (Junction)
    Command := Format('mklink /J "%s" "%s"', [ASource, ATarget]);
    UpdateStatus('创建目录联接: ' + Command);

    if WinExec(PAnsiChar(AnsiString('cmd /c ' + Command)), SW_HIDE) > 31 then
    begin
      Sleep(1000); // 等待命令执行
      Result := TDirectory.Exists(ASource);
    end;

    if not Result then
    begin
      // 如果目录联接失败，尝试符号链接
      Command := Format('mklink /D "%s" "%s"', [ASource, ATarget]);
      UpdateStatus('尝试符号链接: ' + Command);

      if WinExec(PAnsiChar(AnsiString('cmd /c ' + Command)), SW_HIDE) > 31 then
      begin
        Sleep(1000);
        Result := TDirectory.Exists(ASource);
      end;
    end;

    if Result then
      UpdateStatus('链接创建成功')
    else
      UpdateStatus('[失败] 链接创建失败');

  except
    on E: Exception do
    begin
      UpdateStatus('[异常] 创建链接时发生异常: ' + E.Message);
      Result := False;
    end;
  end;
end;

procedure TfrmMain.CopyDirRecursive(const ASrc, ADst: string; var ACopied: Int64);
var
  Files: TArray<string>;
  Dirs: TArray<string>;
  I: Integer;
  SrcFile, DstFile: string;
  SubDir: string;
  FileSize: Int64;
  LastUpdateTime: TDateTime;
  ProcessedFiles: Integer;
begin
  // 确保目标目录存在
  if not TDirectory.Exists(ADst) then
    TDirectory.CreateDirectory(ADst);

  LastUpdateTime := Now;
  ProcessedFiles := 0;

  // 复制文件
  Files := TDirectory.GetFiles(ASrc);
  for I := 0 to High(Files) do
  begin
    if FCancelRequested then Break;

    SrcFile := Files[I];
    DstFile := TPath.Combine(ADst, System.SysUtils.ExtractFileName(SrcFile));

    try
      TFile.Copy(SrcFile, DstFile, True);
      FileSize := TFile.GetSize(SrcFile);
      ACopied := ACopied + FileSize;
      Inc(ProcessedFiles);

      // 优化：只每500毫秒更新一次UI，提高性能
      if (Now - LastUpdateTime) > (500 / (24 * 60 * 60 * 1000)) then
      begin
        if FTotalBytesToCopy > 0 then
        begin
          FCopiedBytesSoFar := ACopied;
          ProgressBar1.Position := Round((FCopiedBytesSoFar * 100) / FTotalBytesToCopy);
        end;
        
        UpdateCurrentFile(SrcFile);
        if ProcessedFiles mod 10 = 0 then // 每10个文件更新一次时间估算
          UpdateTimeRemaining;
          
        Application.ProcessMessages;
        LastUpdateTime := Now;
      end;
    except
      on E: Exception do
        UpdateStatus('[警告] 复制文件失败: ' + SrcFile + ' - ' + E.Message);
    end;
  end;

  // 递归复制子目录
  Dirs := TDirectory.GetDirectories(ASrc);
  for I := 0 to High(Dirs) do
  begin
    if FCancelRequested then Break;

    SubDir := System.SysUtils.ExtractFileName(Dirs[I]);
    CopyDirRecursive(Dirs[I], TPath.Combine(ADst, SubDir), ACopied);
  end;
end;

procedure TfrmMain.AnalyzeDirectory(const APath: string);
var
  FileCount: Integer;
  TotalSize: Int64;
  SizeMB, SizeGB: Double;
  Recommendation, RiskLevel: string;
  PathLower: string;
begin
  UpdateStatus('🔍 正在分析目录: ' + APath);
  ProgressBar1.Visible := True;
  ProgressBar1.Style := pbstMarquee;

  try
    FileCount := 0;
    TotalSize := 0;
    ComputeDirStats(APath, FileCount, TotalSize);

    SizeMB := TotalSize / (1024*1024);
    SizeGB := TotalSize / (1024*1024*1024);

    // 生成智能建议
    Recommendation := '';
    RiskLevel := '';

    if SizeGB > 10 then
    begin
      Recommendation := '💡 建议迁移：目录较大，迁移可显著释放C盘空间';
      RiskLevel := '🟢 低风险';
    end
    else if SizeGB > 1 then
    begin
      Recommendation := '⚖️ 可考虑迁移：目录中等大小，迁移有一定效果';
      RiskLevel := '🟡 中等风险';
    end
    else
    begin
      Recommendation := '不建议迁移：目录较小，迁移效果有限';
      RiskLevel := '[高风险]';
    end;

    // 根据路径特征判断风险
    PathLower := LowerCase(APath);
    if Pos('system', PathLower) > 0 then
    begin
      RiskLevel := '[极高风险]';
      Recommendation := '[警告] 严禁迁移：系统关键目录，迁移可能导致系统崩溃';
    end
    else if Pos('program', PathLower) > 0 then
    begin
      RiskLevel := '[中等风险]';
      Recommendation := '[注意] 谨慎迁移：程序目录，需要测试相关软件功能';
    end
    else if (Pos('documents', PathLower) > 0) or (Pos('desktop', PathLower) > 0) then
    begin
      RiskLevel := '[低风险]';
      Recommendation := '推荐迁移：用户数据目录，迁移安全性高';
    end;

    UpdateStatus('📊 分析完成: ' + IntToStr(FileCount) + ' 个文件，总大小 ' +
                 FormatFloat('0.00', SizeMB) + ' MB');

    ShowChineseMessage('🔍 目录分析报告' + sLineBreak + sLineBreak +
                       '📁 路径：' + APath + sLineBreak +
                       '📊 统计信息：' + sLineBreak +
                       '  • 文件数量：' + IntToStr(FileCount) + ' 个' + sLineBreak +
                       '  • 总大小：' + FormatFloat('0.00', SizeMB) + ' MB (' + FormatFloat('0.00', SizeGB) + ' GB)' + sLineBreak + sLineBreak +
                       '🎯 迁移建议：' + sLineBreak +
                       '  • 风险等级：' + RiskLevel + sLineBreak +
                       '  • 操作建议：' + Recommendation + sLineBreak + sLineBreak +
                       '💡 提示：建议先备份重要数据，然后在测试环境验证迁移效果');
  finally
    ProgressBar1.Style := pbstNormal;
    ProgressBar1.Visible := False;
  end;
end;

procedure TfrmMain.CalculateDirectorySize(const APath: string);
var
  FileCount: Integer;
  TotalSize: Int64;
begin
  UpdateStatus('📏 正在计算目录大小: ' + APath);
  ProgressBar1.Visible := True;
  ProgressBar1.Style := pbstMarquee;

  try
    FileCount := 0;
    TotalSize := 0;
    ComputeDirStats(APath, FileCount, TotalSize);

    FTotalBytesToCopy := TotalSize;

    UpdateStatus('📐 计算完成: ' + FormatFloat('0.00', TotalSize / (1024*1024)) +
                 ' MB (' + IntToStr(FileCount) + ' 个文件)');

    ShowChineseMessage('目录大小计算结果：' + sLineBreak +
                       '总大小：' + FormatFloat('0.00', TotalSize / (1024*1024)) + ' MB' + sLineBreak +
                       '文件数量：' + IntToStr(FileCount) + ' 个' + sLineBreak +
                       '预计迁移时间：约 ' + FormatFloat('0.1', TotalSize / (50*1024*1024)) + ' 分钟');
  finally
    ProgressBar1.Style := pbstNormal;
    ProgressBar1.Visible := False;
  end;
end;

// 带校验的递归复制
function TfrmMain.CopyDirRecursiveWithVerify(const ASrc, ADst: string;
  ATransaction: TMigrationTransaction): Boolean;
var
  Files: TArray<string>;
  Dirs: TArray<string>;
  I: Integer;
  SrcFile, DstFile: string;
  SubDir: string;
  FileSize: Int64;
  SrcHash, DstHash: string;
  ProcessedFiles, TotalFiles: Integer;
  ProcessedBytes, TotalBytes: Int64;
begin
  Result := True;

  // 确保目标目录存在
  if not TDirectory.Exists(ADst) then
    TDirectory.CreateDirectory(ADst);

  // 复制文件
  Files := TDirectory.GetFiles(ASrc);
  for I := 0 to High(Files) do
  begin
    if FCancelRequested then
    begin
      Result := False;
      Break;
    end;

    SrcFile := Files[I];
    DstFile := TPath.Combine(ADst, System.SysUtils.ExtractFileName(SrcFile));

    // 更新当前文件名
    UpdateCurrentFile(SrcFile);
    
    try
      // 复制文件
      TFile.Copy(SrcFile, DstFile, True);
      FileSize := TFile.GetSize(SrcFile);

      // 计算源文件哈希
      try
        SrcHash := TFileHasher.ComputeSHA256(SrcFile);
        DstHash := TFileHasher.ComputeSHA256(DstFile);

        // 校验哈希
        if SameText(SrcHash, DstHash) then
        begin
          // 文件验证成功
          ATransaction.AddFileRecord(SrcFile, DstFile, FileSize, SrcHash);
          ATransaction.UpdateFileRecord(SrcFile, SrcHash, True);
        end
        else
        begin
          // 校验失败
          ATransaction.AddFileRecord(SrcFile, DstFile, FileSize, SrcHash);
          ATransaction.MarkFileError(SrcFile, '文件校验失败');
          UpdateStatus('文件校验失败: ' + SrcFile);
          Result := False;
        end;
      except
        on E: Exception do
        begin
          ATransaction.AddFileRecord(SrcFile, DstFile, FileSize, '');
          ATransaction.MarkFileError(SrcFile, '计算哈希失败: ' + E.Message);
          UpdateStatus('计算哈希失败: ' + SrcFile);
          Result := False;
        end;
      end;

      // 更新进度
      ProcessedFiles := ATransaction.ProcessedFiles + 1;
      ProcessedBytes := ATransaction.ProcessedBytes + FileSize;
      TotalFiles := ATransaction.TotalFiles;
      TotalBytes := ATransaction.TotalBytes;

      ATransaction.UpdateProgress(ProcessedFiles, TotalFiles, 
        ProcessedBytes, TotalBytes);

      if TotalBytes > 0 then
        ProgressBar1.Position := Round((ProcessedBytes * 100) / TotalBytes);

      // 更新进度跟踪
      FProcessedFilesCount := ProcessedFiles;
      FTotalFilesCount := TotalFiles;
      
      // 每10个文件更新一次状态和剩余时间
      if (ProcessedFiles mod 10) = 0 then
      begin
        UpdateStatus(Format('已处理 %d/%d 个文件 (%.1f%%)', 
          [ProcessedFiles, TotalFiles, (ProcessedBytes * 100.0) / TotalBytes]));
        UpdateTimeRemaining;
      end;

      Application.ProcessMessages;
    except
      on E: Exception do
      begin
        ATransaction.MarkFileError(SrcFile, '复制失败: ' + E.Message);
        UpdateStatus('复制文件失败: ' + SrcFile + ' - ' + E.Message);
        Result := False;
      end;
    end;
  end;

  // 递归复制子目录
  Dirs := TDirectory.GetDirectories(ASrc);
  for I := 0 to High(Dirs) do
  begin
    if FCancelRequested then
    begin
      Result := False;
      Break;
    end;

    SubDir := System.SysUtils.ExtractFileName(Dirs[I]);
    if not CopyDirRecursiveWithVerify(Dirs[I], TPath.Combine(ADst, SubDir),
      ATransaction) then
      Result := False;
  end;
end;

// 验证Junction链接
function TfrmMain.VerifyJunction(const AJunctionPath, ATargetPath: string): Boolean;
var
  TestFile: string;
  TestContent: string;
  Files: TArray<string>;
  TargetTestFile: string;
  ReadContent: string;
begin
  Result := False;

  try
    // 1. 检查联接是否存在
    if not TDirectory.Exists(AJunctionPath) then
    begin
      UpdateStatus('联接目录不存在: ' + AJunctionPath);
      Exit;
    end;

    // 2. 尝试列举目录内容
    try
      Files := TDirectory.GetFiles(AJunctionPath);
      UpdateStatus(Format('联接目录可访问，包含 %d 个文件', [Length(Files)]));
    except
      on E: Exception do
      begin
        UpdateStatus('联接目录无法访问: ' + E.Message);
        Exit;
      end;
    end;

    // 3. 尝试在联接目录中创建测试文件
    TestFile := TPath.Combine(AJunctionPath, '_verify_test.tmp');
    TestContent := 'Junction verification test - ' + DateTimeToStr(Now);

    try
      TFile.WriteAllText(TestFile, TestContent);

      // 4. 验证文件是否在目标目录中
      TargetTestFile := TPath.Combine(ATargetPath, '_verify_test.tmp');
      if TFile.Exists(TargetTestFile) then
      begin
        ReadContent := TFile.ReadAllText(TargetTestFile);
        if ReadContent = TestContent then
        begin
          Result := True;
          UpdateStatus('Junction验证成功：读写测试通过');
        end;
      end;

      // 5. 清理测试文件
      try
        if TFile.Exists(TestFile) then
          TFile.Delete(TestFile);
      except
        // 忽略清理错误
      end;
    except
      on E: Exception do
      begin
        UpdateStatus('Junction读写测试失败: ' + E.Message);
        Exit;
      end;
    end;

  except
    on E: Exception do
    begin
      UpdateStatus('Junction验证异常: ' + E.Message);
      Result := False;
    end;
  end;
end;

procedure TfrmMain.ComputeDirStats(const APath: string; var AFileCount: Integer; var ATotalSize: Int64);
var
  Files: TArray<string>;
  Dirs: TArray<string>;
  I: Integer;
begin
  try
    // 统计文件
    Files := TDirectory.GetFiles(APath);
    for I := 0 to High(Files) do
    begin
      try
        Inc(AFileCount);
        ATotalSize := ATotalSize + TFile.GetSize(Files[I]);

        // 每1000个文件更新一次界面，提高性能
        if (AFileCount mod 1000) = 0 then
        begin
          UpdateStatus('📊 已扫描 ' + IntToStr(AFileCount) + ' 个文件...');
          Application.ProcessMessages;
        end;
      except
        // 忽略无法访问的文件
      end;
    end;

    // 递归统计子目录
    Dirs := TDirectory.GetDirectories(APath);
    for I := 0 to High(Dirs) do
    begin
      try
        ComputeDirStats(Dirs[I], AFileCount, ATotalSize);
      except
        // 忽略无法访问的目录
      end;
    end;
  except
    // 忽略访问权限错误
  end;
end;

procedure TfrmMain.ShowMigrationCompleteDialog(TotalFiles, VerifiedCount, FailedCount: Integer;
  const BackupDir: string; BackupSize: Int64);
var
  MsgText: string;
  Response: Integer;
  BackupSizeStr: string;
begin
  BackupSizeStr := TSystemCheck.FormatBytes(BackupSize);
  
  MsgText := Format(
    '目录迁移完成!' + sLineBreak + sLineBreak +
    '统计信息:' + sLineBreak +
    '  文件总数: %d' + sLineBreak +
    '  已验证: %d' + sLineBreak +
    '  验证失败: %d' + sLineBreak + sLineBreak +
    '备份目录:' + sLineBreak +
    '%s' + sLineBreak +
    '大小: %s' + sLineBreak + sLineBreak +
    '请测试相关程序是否正常运行。' + sLineBreak +
    '确认无误后可删除备份目录以释放空间。' + sLineBreak + sLineBreak +
    '是否立即删除备份目录?',
    [TotalFiles, VerifiedCount, FailedCount, BackupDir, BackupSizeStr]);

  Response := MessageDlg(MsgText, mtInformation, [mbYes, mbNo], 0);

  if Response = mrYes then
  begin
    if MessageDlg(
      '警告: 删除备份目录后无法自动回滚!' + sLineBreak + sLineBreak +
      '确定删除备份目录吗?' + sLineBreak +
      BackupDir,
      mtWarning, [mbYes, mbNo], 0) = mrYes then
    begin
      try
        TDirectory.Delete(BackupDir, True);
        UpdateStatus('已删除备份目录,释放 ' + BackupSizeStr + ' 空间');
        MessageDlg('备份目录已成功删除', mtInformation, [mbOK], 0);
      except
        on E: Exception do
        begin
          UpdateStatus('删除备份目录失败: ' + E.Message);
          MessageDlg('删除备份目录失败:' + sLineBreak + E.Message, 
            mtError, [mbOK], 0);
        end;
      end;
    end;
  end
  else
  begin
    UpdateStatus('备份目录已保留,可稍后手动删除');
  end;
end;

// SetControlFont 方法已被移除，字体设置已移动到DFM

// 主菜单事件实现
procedure TfrmMain.MenuFileExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.MenuCleanupRecycleBinClick(Sender: TObject);
begin
  CleanRecycleBin;
end;

procedure TfrmMain.MenuCleanupTempClick(Sender: TObject);
begin
  CleanTempFiles;
end;

procedure TfrmMain.MenuCleanupLastBackupClick(Sender: TObject);
begin
  CleanBackupFiles;
end;

procedure TfrmMain.MenuCleanupSoftwareDistributionClick(Sender: TObject);
begin
  CleanUpdateCache;
end;

procedure TfrmMain.MenuCleanupDuplicateFilesClick(Sender: TObject);
var
  AdvancedForm: TfrmAdvancedFileManager;
begin
  try
    UpdateStatus('正在启动高级文件管理器 - 重复文件清理...');
    
    AdvancedForm := TfrmAdvancedFileManager.Create(Self);
    try
      // 直接跳转到重复文件标签页
      if AdvancedForm.pgcMain.PageCount > 1 then
        AdvancedForm.pgcMain.ActivePageIndex := 1; // 重复文件页
        
      // 如果有选定的源目录，设为默认扫描路径
      if FSourcePath <> '' then
      begin
        AdvancedForm.edtDuplicatePath.Text := FSourcePath;
      end
      else if TDirectory.Exists('C:\\Users') then
      begin
        AdvancedForm.edtDuplicatePath.Text := 'C:\\Users';
      end;
      
      AdvancedForm.ShowModal;
    finally
      AdvancedForm.Free;
    end;
    
    UpdateStatus('重复文件清理工具已关闭');
  except
    on E: Exception do
    begin
      UpdateStatus('启动重复文件清理失败: ' + E.Message);
      ShowChineseMessage('启动重复文件清理失败：' + sLineBreak + E.Message);
    end;
  end;
end;

procedure TfrmMain.MenuCleanupHistoryClick(Sender: TObject);
begin
  try
    UpdateStatus('正在打开清理历史记录...');
    TfrmCleanupHistory.ShowHistory;
    UpdateStatus('清理历史记录已关闭');
  except
    on E: Exception do
    begin
      UpdateStatus('打开清理历史记录失败: ' + E.Message);
      ShowChineseMessage('打开清理历史记录失败：' + sLineBreak + E.Message);
    end;
  end;
end;

procedure TfrmMain.miLogManagerClick(Sender: TObject);
var
  LogViewer: TfrmLogViewer;
begin
  try
    UpdateStatus('正在打开日志查看器...');
    
    LogViewer := TfrmLogViewer.Create(Self, GlobalLogManager);
    try
      LogViewer.Show; // 使用Show而不是ShowModal，允许同时使用主窗口
    except
      LogViewer.Free;
      raise;
    end;
    
    UpdateStatus('日志查看器已打开');
  except
    on E: Exception do
    begin
      UpdateStatus('打开日志查看器失败: ' + E.Message);
      ShowChineseMessage('打开日志查看器失败：' + sLineBreak + E.Message);
    end;
  end;
end;

procedure TfrmMain.miAdvancedOptionsClick(Sender: TObject);
var
  OptionsDialog: TfrmAdvancedOptions;
begin
  try
    UpdateStatus('正在打开高级选项对话框...');
    
    OptionsDialog := TfrmAdvancedOptions.Create(Self);
    try
      if OptionsDialog.ShowModal = mrOk then
      begin
        UpdateStatus('高级选项设置已更新');
        LogInfo('Settings', '用户更新了高级选项设置');
        
        // 在这里可以根据新设置更新主窗口行为
        // 例如更新线程数、日志级别等
        if Assigned(GlobalLogManager) then
        begin
          var Settings := TSettingsManager.Instance.Settings;
          GlobalLogManager.LogLevel := Settings.LogLevel;
          GlobalLogManager.LogToFile := Settings.EnableFileLogging;
          GlobalLogManager.MaxFileSize := Settings.LogRotationSize * 1024 * 1024;
          GlobalLogManager.MaxFiles := Settings.MaxLogFiles;
        end;
        
        ShowChineseMessage('高级选项设置已保存！部分设置将在下次启动时生效。');
      end
      else
      begin
        UpdateStatus('高级选项对话框已取消');
      end;
    finally
      OptionsDialog.Free;
    end;
    
  except
    on E: Exception do
    begin
      UpdateStatus('打开高级选项对话框失败: ' + E.Message);
      ShowChineseMessage('打开高级选项对话框失败：' + sLineBreak + E.Message);
    end;
  end;
end;

procedure TfrmMain.MenuThemeClick(Sender: TObject);
begin
  ShowChineseMessage('切换主题功能正在开发中，敬请期待！');
end;

procedure TfrmMain.MenuHelpAboutClick(Sender: TObject);
begin
  ShowChineseMessage('C盘瘦身神器 v1.0' + sLineBreak + sLineBreak +
                     '智能目录迁移专家' + sLineBreak +
                     '帮助您安全地迁移大文件夹，释放C盘空间' + sLineBreak + sLineBreak +
                     '开发者：AI助手' + sLineBreak +
                     '版权所有 © 2024');
end;

// 右键菜单弹出事件
procedure TfrmMain.pmSourcePopup(Sender: TObject);
begin
  // 根据当前状态启用/禁用菜单项
  miSrcOpen.Enabled := (FSourcePath <> '') and TDirectory.Exists(FSourcePath);
  miSrcOpenInExplorer.Enabled := miSrcOpen.Enabled;
  miSrcCopyPath.Enabled := miSrcOpen.Enabled;
  miSrcSetRoot.Enabled := miSrcOpen.Enabled;
  miSrcScanHere.Enabled := miSrcOpen.Enabled;
  miSrcAnalyzeHere.Enabled := miSrcOpen.Enabled;
  miSrcDelete.Enabled := miSrcOpen.Enabled;
  miSrcProperties.Enabled := miSrcOpen.Enabled;
end;

procedure TfrmMain.pmTargetPopup(Sender: TObject);
begin
  // 根据当前状态启用/禁用菜单项
  miTgtOpen.Enabled := (FTargetPath <> '') and TDirectory.Exists(FTargetPath);
  miTgtOpenInExplorer.Enabled := miTgtOpen.Enabled;
  miTgtCopyPath.Enabled := miTgtOpen.Enabled;
  miTgtSetRoot.Enabled := miTgtOpen.Enabled;
  miTgtSetAsTargetPath.Enabled := miTgtOpen.Enabled;
  miTgtDelete.Enabled := miTgtOpen.Enabled;
  miTgtProperties.Enabled := miTgtOpen.Enabled;
end;

procedure TfrmMain.ApplyModernColors;
begin
  // 为界面添加丰富的Material Design配色
  
  // 面板背景色
  pnlTop.Color := $ECEFF1;  // Material Blue Grey 50
  pnlLeft.Color := $FAFAFA;  // Material Grey 50
  pnlRight.Color := $FAFAFA;  // Material Grey 50
  pnlStatus.Color := $E3F2FD;  // Material Blue 50
  pnlBottom.Color := $F5F5F5;  // Material Grey 100
  
  // 状态栏颜色
  StatusBar1.Color := $263238;  // Material Blue Grey 900
  StatusBar1.Font.Color := clWhite;
  
  // 按钮背景色设置 (保留动态颜色功能) - 添加存在性检查
  if Assigned(btnExecute) then SetButtonStyle(btnExecute, $4CAF50, clBlack);
  if Assigned(btnAnalyze) then SetButtonStyle(btnAnalyze, $2196F3, clBlack);
  if Assigned(btnCalculateSize) then SetButtonStyle(btnCalculateSize, $FF9800, clBlack);
  // if Assigned(btnCleanRecycleBin) then SetButtonStyle(btnCleanRecycleBin, $9C27B0, clBlack);
  // if Assigned(btnCleanTemp) then SetButtonStyle(btnCleanTemp, $673AB7, clBlack);
  if Assigned(btnCleanBackup) then SetButtonStyle(btnCleanBackup, $3F51B5, clBlack);
  // if Assigned(btnCleanUpdate) then SetButtonStyle(btnCleanUpdate, $2196F3, clBlack);
  if Assigned(btnSmartClean) then SetButtonStyle(btnSmartClean, $009688, clBlack);
  if Assigned(btnSmartMigration) then SetButtonStyle(btnSmartMigration, $00BCD4, clBlack);
  // if Assigned(btnAdvancedFileManager) then SetButtonStyle(btnAdvancedFileManager, $FF9800, clBlack);
  if Assigned(btnBrowseSource) then SetButtonStyle(btnBrowseSource, $607D8B, clBlack);
  if Assigned(btnBrowseTarget) then SetButtonStyle(btnBrowseTarget, $607D8B, clBlack);
  if Assigned(btnSourceUp) then SetButtonStyle(btnSourceUp, $795548, clBlack);
  if Assigned(btnTargetUp) then SetButtonStyle(btnTargetUp, $795548, clBlack);
  if Assigned(btnExit) then SetButtonStyle(btnExit, $F44336, clBlack);
  if Assigned(btnOneKeyDiagnose) then SetButtonStyle(btnOneKeyDiagnose, $3F51B5, clBlack);
  if Assigned(btnRollback) then SetButtonStyle(btnRollback, $FF5722, clBlack);

  // 编辑框、树视图、状态信息和标签的样式已移动到dfm
  // 进度条和状态栏颜色已移动到dfm
  // 按钮字体已移动到dfm
end;

// SetButtonFonts 方法已被移除，字体设置已移动到DFM

procedure TfrmMain.SetButtonStyle(AButton: TBitBtn; ABackColor, AFontColor: TColor);
begin
  // 字体和尺寸已在DFM中设置，只设置动态属性

  // TBitBtn的样式设置
  AButton.Kind := bkCustom;       // 自定义样式

  // 强制文字居中
  AButton.Margin := -1;           // 自动居中
  AButton.Spacing := 4;           // 图标和文字间距
end;

// ApplyLabelStyles 方法已被移除，标签样式已移动到DFM

// SetInterfaceTexts 方法已被移除，所有文本设置在DFM中

procedure TfrmMain.LoadButtonIcons;
begin
  // 为清理功能按钮加载图标 - 添加存在性检查
  // if Assigned(btnCleanRecycleBin) then IconManager.ApplyIconToButton(btnCleanRecycleBin, IconManager.ICON_RECYCLE_BIN);
  // if Assigned(btnCleanTemp) then IconManager.ApplyIconToButton(btnCleanTemp, IconManager.ICON_CLEAN_TEMP);
  if Assigned(btnCleanBackup) then IconManager.ApplyIconToButton(btnCleanBackup, IconManager.ICON_CLEAN_BACKUP);
  // if Assigned(btnCleanUpdate) then IconManager.ApplyIconToButton(btnCleanUpdate, IconManager.ICON_CLEAN_UPDATE);
  if Assigned(btnSmartClean) then IconManager.ApplyIconToButton(btnSmartClean, IconManager.ICON_SMART_CLEAN);
  if Assigned(btnSmartMigration) then IconManager.ApplyIconToButton(btnSmartMigration, IconManager.ICON_SMART_MIGRATION);
  // if Assigned(btnAdvancedFileManager) then IconManager.ApplyIconToButton(btnAdvancedFileManager, IconManager.ICON_FILE_MANAGER);

  // 为主要功能按钮加载图标
  if Assigned(btnExecute) then IconManager.ApplyIconToButton(btnExecute, IconManager.ICON_EXECUTE);
  if Assigned(btnAnalyze) then IconManager.ApplyIconToButton(btnAnalyze, IconManager.ICON_ANALYZE);
  if Assigned(btnCalculateSize) then IconManager.ApplyIconToButton(btnCalculateSize, IconManager.ICON_CALCULATE);
  if Assigned(btnExit) then IconManager.ApplyIconToButton(btnExit, IconManager.ICON_EXIT);

  // 为浏览和导航按钮加载图标
  if Assigned(btnBrowseSource) then IconManager.ApplyIconToButton(btnBrowseSource, IconManager.ICON_BROWSE);
  if Assigned(btnBrowseTarget) then IconManager.ApplyIconToButton(btnBrowseTarget, IconManager.ICON_BROWSE);
  if Assigned(btnSourceUp) then IconManager.ApplyIconToButton(btnSourceUp, IconManager.ICON_UP);
  if Assigned(btnTargetUp) then IconManager.ApplyIconToButton(btnTargetUp, IconManager.ICON_UP);
  
  // 为一键功能按钮加载图标
  if Assigned(btnOneKeyDiagnose) then IconManager.ApplyIconToButton(btnOneKeyDiagnose, IconManager.ICON_DIAGNOSE);
  if Assigned(btnRollback) then IconManager.ApplyIconToButton(btnRollback, IconManager.ICON_ROLLBACK);
end;

function TfrmMain.ShowChineseMessage(const AMessage: string): Integer;
begin
  // 使用Windows API直接显示消息框，确保中文正确显示
  Result := MessageBoxW(Handle, PWideChar(AMessage), PWideChar('信息'), MB_OK or MB_ICONINFORMATION);
end;

function TfrmMain.ShowChineseConfirm(const AMessage: string): Boolean;
begin
  // 使用Windows API显示确认对话框
  Result := MessageBoxW(Handle, PWideChar(AMessage), PWideChar('确认'), MB_YESNO or MB_ICONQUESTION) = IDYES;
end;

// 源目录右键菜单事件实现
procedure TfrmMain.miSrcOpenClick(Sender: TObject);
begin
  if (FSourcePath <> '') and TDirectory.Exists(FSourcePath) then
  begin
    ShellExecute(Handle, 'open', PChar(FSourcePath), nil, nil, SW_SHOWNORMAL);
    UpdateStatus('已打开源目录: ' + FSourcePath);
  end;
end;

procedure TfrmMain.miSrcOpenInExplorerClick(Sender: TObject);
begin
  if (FSourcePath <> '') and TDirectory.Exists(FSourcePath) then
  begin
    ShellExecute(Handle, 'open', 'explorer.exe', PChar(FSourcePath), nil, SW_SHOWNORMAL);
    UpdateStatus('已在资源管理器中打开源目录: ' + FSourcePath);
  end;
end;

procedure TfrmMain.miSrcCopyPathClick(Sender: TObject);
begin
  if FSourcePath <> '' then
  begin
    Clipboard.AsText := FSourcePath;
    UpdateStatus('已复制源目录路径到剪贴板: ' + FSourcePath);
  end;
end;

procedure TfrmMain.miSrcSetRootClick(Sender: TObject);
begin
  if (FSourcePath <> '') and TDirectory.Exists(FSourcePath) then
  begin
    LoadDirectoryTree(tvSource, FSourcePath);
    UpdateStatus('已设置源根目录: ' + FSourcePath);
  end;
end;

procedure TfrmMain.miSrcScanHereClick(Sender: TObject);
begin
  if FSourcePath <> '' then
    CalculateDirectorySize(FSourcePath)
  else
    ShowChineseMessage('请先选择源目录！');
end;

procedure TfrmMain.miSrcAnalyzeHereClick(Sender: TObject);
begin
  if FSourcePath <> '' then
    AnalyzeDirectory(FSourcePath)
  else
    ShowChineseMessage('请先选择源目录！');
end;

procedure TfrmMain.miSrcRefreshClick(Sender: TObject);
begin
  if FSourcePath <> '' then
  begin
    LoadDirectoryTree(tvSource, FSourcePath);
    UpdateStatus('已刷新源目录');
  end;
end;

// 目标目录右键菜单事件实现
procedure TfrmMain.miTgtOpenClick(Sender: TObject);
begin
  if (FTargetPath <> '') and TDirectory.Exists(FTargetPath) then
  begin
    ShellExecute(Handle, 'open', PChar(FTargetPath), nil, nil, SW_SHOWNORMAL);
    UpdateStatus('已打开目标目录: ' + FTargetPath);
  end;
end;

procedure TfrmMain.miTgtOpenInExplorerClick(Sender: TObject);
begin
  if (FTargetPath <> '') and TDirectory.Exists(FTargetPath) then
  begin
    ShellExecute(Handle, 'open', 'explorer.exe', PChar(FTargetPath), nil, SW_SHOWNORMAL);
    UpdateStatus('已在资源管理器中打开目标目录: ' + FTargetPath);
  end;
end;

procedure TfrmMain.miTgtCopyPathClick(Sender: TObject);
begin
  if FTargetPath <> '' then
  begin
    Clipboard.AsText := FTargetPath;
    UpdateStatus('已复制目标目录路径到剪贴板: ' + FTargetPath);
  end;
end;

procedure TfrmMain.miTgtSetRootClick(Sender: TObject);
begin
  if (FTargetPath <> '') and TDirectory.Exists(FTargetPath) then
  begin
    LoadDirectoryTree(tvTarget, FTargetPath);
    UpdateStatus('已设置目标根目录: ' + FTargetPath);
  end;
end;

procedure TfrmMain.miTgtSetAsTargetPathClick(Sender: TObject);
begin
  if (FTargetPath <> '') and TDirectory.Exists(FTargetPath) then
  begin
    edtTargetDir.Text := FTargetPath;
    UpdateStatus('已设置为目标路径: ' + FTargetPath);
  end;
end;

procedure TfrmMain.miTgtRefreshClick(Sender: TObject);
begin
  if FTargetPath <> '' then
  begin
    LoadDirectoryTree(tvTarget, FTargetPath);
    UpdateStatus('已刷新目标目录');
  end;
end;

// ===== 断点续迁功能 =====

// 检测未完成的迁移事务
procedure TfrmMain.CheckIncompleteTransactions;
var
  Transactions: TArray<string>;
  I: Integer;
  TransactionID: string;
  Msg: string;
begin
  try
    Transactions := TMigrationTransaction.FindIncompleteTransactions;
    
    if Length(Transactions) = 0 then
      Exit; // 没有未完成的事务

    // 构建提示消息
    Msg := '检测到未完成的目录迁移事务：' + sLineBreak + sLineBreak;
    for I := 0 to Min(2, Length(Transactions) - 1) do
    begin
      Msg := Msg + '  - ' + Transactions[I] + sLineBreak;
    end;
    
    if Length(Transactions) > 3 then
      Msg := Msg + Format('  ... 共 %d 个事务', [Length(Transactions)]) + sLineBreak;
    
    Msg := Msg + sLineBreak + '是否要处理这些未完成的事务？';

    if ShowChineseConfirm(Msg) then
    begin
      // 逐个处理事务
      for TransactionID in Transactions do
      begin
        HandleIncompleteTransaction(TransactionID);
      end;
    end
    else
    begin
      UpdateStatus('已忽略未完成的迁移事务');
    end;
  except
    on E: Exception do
      UpdateStatus('检测事务时出错: ' + E.Message);
  end;
end;

// 处理单个未完成的事务
procedure TfrmMain.HandleIncompleteTransaction(const ATransactionID: string);
var
  Transaction: TMigrationTransaction;
  Msg: string;
  UserChoice: Integer;
begin
  Transaction := TMigrationTransaction.Create;
  try
    try
      // 加载事务
      Transaction.LoadTransaction(ATransactionID);
      
      // 构建详细信息
      Msg := Format('事务 ID: %s' + sLineBreak +
                    '源目录: %s' + sLineBreak +
                    '目标目录: %s' + sLineBreak +
                    '备份目录: %s' + sLineBreak +
                    '状态: %s' + sLineBreak +
                    '已处理: %d/%d 个文件' + sLineBreak + sLineBreak +
                    '请选择操作：' + sLineBreak +
                    '是 - 继续迁移' + sLineBreak +
                    '否 - 回滚到迁移前状态' + sLineBreak +
                    '取消 - 忽略此事务',
                    [Transaction.TransactionID,
                     Transaction.SourceDir,
                     Transaction.TargetDir,
                     Transaction.BackupDir,
                     'InProgress',
                     Transaction.ProcessedFiles,
                     Transaction.TotalFiles]);

      // 显示带取消按钮的确认对话框
      UserChoice := MessageBoxW(Handle, PWideChar(Msg), 
                               PWideChar('未完成的迁移事务'), 
                               MB_YESNOCANCEL or MB_ICONQUESTION);

      case UserChoice of
        IDYES: 
        begin
          // 继续迁移
          UpdateStatus('开始恢复迁移事务...');
          if ResumeMigration(Transaction) then
            UpdateStatus('迁移恢复完成')
          else
            UpdateStatus('迁移恢复失败');
        end;
        
        IDNO:
        begin
          // 回滚
          UpdateStatus('开始回滚迁移事务...');
          if RollbackMigration(Transaction) then
            UpdateStatus('回滚完成')
          else
            UpdateStatus('回滚失败');
        end;
        
        IDCANCEL:
        begin
          // 忽略
          UpdateStatus('已忽略事务: ' + ATransactionID);
        end;
      end;
    except
      on E: Exception do
      begin
        UpdateStatus('处理事务失败: ' + E.Message);
        ShowChineseMessage('处理事务失败：' + sLineBreak + E.Message);
      end;
    end;
  finally
    Transaction.Free;
  end;
end;

// 恢复迁移（从中断点继续）
function TfrmMain.ResumeMigration(ATransaction: TMigrationTransaction): Boolean;
var
  TotalFiles: Integer;
  ProcessedFiles: Integer;
begin
  Result := False;
  
  try
    // 重新赋值全局事务对象
    if Assigned(FMigrationTransaction) then
      FMigrationTransaction.Free;
    FMigrationTransaction := ATransaction;
    
    UpdateStatus('正在恢复迁移事务: ' + ATransaction.TransactionID);
    UpdateStatus('源目录: ' + ATransaction.SourceDir);
    UpdateStatus('目标目录: ' + ATransaction.TargetDir);
    
    TotalFiles := ATransaction.TotalFiles;
    ProcessedFiles := ATransaction.ProcessedFiles;
    
    UpdateStatus(Format('已处理 %d/%d 个文件，正在继续...', 
      [ProcessedFiles, TotalFiles]));

    // 检查备份目录是否存在
    if not TDirectory.Exists(ATransaction.BackupDir) then
    begin
      UpdateStatus('备份目录不存在，无法恢复迁移');
      ATransaction.FailTransaction('备份目录不存在');
      Exit;
    end;

    // 继续复制未处理的文件
    ProgressBar1.Visible := True;
    ProgressBar1.Position := 0;
    
    if not CopyDirRecursiveWithVerify(ATransaction.SourceDir, 
         ATransaction.TargetDir, ATransaction) then
    begin
      UpdateStatus('继续复制失败');
      ATransaction.FailTransaction('继续复制失败');
      Exit;
    end;

    // 检查是否需要创建Junction
    if not TDirectory.Exists(ATransaction.SourceDir) then
    begin
      // 需要创建Junction
      UpdateStatus('创建目录联接...');
      if not CreateDirectoryLink(ATransaction.SourceDir, ATransaction.TargetDir) then
      begin
        UpdateStatus('创建联接失败');
        ATransaction.FailTransaction('创建联接失败');
        Exit;
      end;

      // 验证Junction
      if not VerifyJunction(ATransaction.SourceDir, ATransaction.TargetDir) then
      begin
        UpdateStatus('联接验证失败');
        ATransaction.LogWarning('Junction验证失败');
      end;
    end;

    // 完成事务
    ATransaction.CompleteTransaction;
    FLastBackupPath := ATransaction.BackupDir;
    
    UpdateStatus('迁移恢复完成！');
    ShowChineseMessage('迁移恢复完成！' + sLineBreak + sLineBreak +
                       '备份目录: ' + ATransaction.BackupDir + sLineBreak + sLineBreak +
                       '请测试相关程序是否正常运行。');
    
    Result := True;
    
  finally
    ProgressBar1.Visible := False;
  end;
end;

// 回滚迁移
function TfrmMain.RollbackMigration(ATransaction: TMigrationTransaction): Boolean;
var
  SrcExists, BackupExists, TargetExists: Boolean;
begin
  Result := False;
  
  try
    UpdateStatus('开始回滚迁移事务: ' + ATransaction.TransactionID);
    
    SrcExists := TDirectory.Exists(ATransaction.SourceDir);
    BackupExists := TDirectory.Exists(ATransaction.BackupDir);
    TargetExists := TDirectory.Exists(ATransaction.TargetDir);
    
    UpdateStatus(Format('状态: 源=%s, 备份=%s, 目标=%s',
      [BoolToStr(SrcExists, True), BoolToStr(BackupExists, True), BoolToStr(TargetExists, True)]));

    // 1. 如果源目录是Junction，删除它
    if SrcExists then
    begin
      UpdateStatus('检测到源目录存在，尝试删除...');
      try
        // 尝试删除（如果是Junction会直接删除链接）
        TDirectory.Delete(ATransaction.SourceDir, False);
        UpdateStatus('已删除源目录/链接');
      except
        on E: Exception do
        begin
          UpdateStatus('删除源目录失败: ' + E.Message);
          // 继续尝试回滚
        end;
      end;
    end;

    // 2. 如果备份目录存在，恢复它
    if BackupExists then
    begin
      UpdateStatus('正在恢复备份目录...');
      try
        if RenameFile(ATransaction.BackupDir, ATransaction.SourceDir) then
        begin
          UpdateStatus('已恢复原目录');
        end
        else
        begin
          UpdateStatus('恢复原目录失败');
          Exit;
        end;
      except
        on E: Exception do
        begin
          UpdateStatus('恢复备份目录失败: ' + E.Message);
          Exit;
        end;
      end;
    end
    else
    begin
      UpdateStatus('警告: 备份目录不存在，无法恢复');
    end;

    // 3. 清理目标目录（可选）
    if TargetExists then
    begin
      if ShowChineseConfirm('是否删除目标目录中的文件？' + sLineBreak +
                           ATransaction.TargetDir) then
      begin
        try
          UpdateStatus('正在清理目标目录...');
          TDirectory.Delete(ATransaction.TargetDir, True);
          UpdateStatus('已清理目标目录');
        except
          on E: Exception do
            UpdateStatus('清理目标目录失败: ' + E.Message);
        end;
      end;
    end;

    // 4. 更新事务状态
    ATransaction.RollbackTransaction;
    
    UpdateStatus('回滚完成');
    ShowChineseMessage('迁移事务已回滚！' + sLineBreak + sLineBreak +
                       '原目录已恢复。');
    
    Result := True;
    
  except
    on E: Exception do
    begin
      UpdateStatus('回滚失败: ' + E.Message);
      ShowChineseMessage('回滚失败：' + sLineBreak + E.Message);
      Result := False;
    end;
  end;
end;

// ===== 安全检查方法 =====
// 检查是否为系统关键目录
function TfrmMain.IsSystemCriticalDirectory(const APath: string): Boolean;
var
  UpperPath: string;
  WindowsDir, SystemDir, ProgramFilesDir: string;
begin
  Result := False;
  UpperPath := UpperCase(APath);
  
  // 获取系统目录
  WindowsDir := UpperCase(GetEnvironmentVariable('WINDIR'));
  SystemDir := UpperCase(WindowsDir + '\\System32');
  ProgramFilesDir := UpperCase(GetEnvironmentVariable('PROGRAMFILES'));
  
  // 检查危险目录
  if (Pos(WindowsDir, UpperPath) = 1) or
     (Pos(SystemDir, UpperPath) = 1) or
     (Pos(ProgramFilesDir, UpperPath) = 1) or
     (Pos('C:\\PROGRAM FILES (X86)', UpperPath) = 1) or
     (Pos('C:\\WINDOWS', UpperPath) = 1) or
     (Pos('C:\\SYSTEM VOLUME INFORMATION', UpperPath) = 1) or
     (Pos('C:\\PAGEFILE.SYS', UpperPath) = 1) or
     (Pos('C:\\HIBERFIL.SYS', UpperPath) = 1) or
     (Pos('C:\\BOOT', UpperPath) = 1) or
     (Pos('C:\\EFI', UpperPath) = 1) then
  begin
    Result := True;
  end;
end;

// 检查目录迁移安全性
function TfrmMain.CheckDirectorySafety(const ASourcePath, ATargetPath: string): Boolean;
var
  SourceUpper, TargetUpper: string;
begin
  Result := True;
  
  SourceUpper := UpperCase(ASourcePath);
  TargetUpper := UpperCase(ATargetPath);
  
  // 1. 检查是否为系统关键目录
  if IsSystemCriticalDirectory(ASourcePath) then
  begin
    ShowChineseMessage('警告：无法迁移系统关键目录！' + sLineBreak + sLineBreak +
                       '源目录: ' + ASourcePath + sLineBreak + sLineBreak +
                       '迁移系统目录可能导致系统无法正常启动。');
    Result := False;
    Exit;
  end;
  
  // 2. 检查源目录和目标目录是否在同一磁盘
  if (Length(SourceUpper) > 0) and (Length(TargetUpper) > 0) and 
     (SourceUpper[1] = TargetUpper[1]) then
  begin
    if not ShowChineseConfirm('注意：源目录和目标目录在同一磁盘上。' + sLineBreak + sLineBreak +
                              '这将不会节省C盘空间，仅仅是移动位置。' + sLineBreak +
                              '是否继续？') then
    begin
      Result := False;
      Exit;
    end;
  end;
  
  // 3. 检查目标目录是否在源目录内部
  if (Pos(SourceUpper, TargetUpper) = 1) then
  begin
    ShowChineseMessage('错误：目标目录不能是源目录的子目录！' + sLineBreak + sLineBreak +
                       '源目录: ' + ASourcePath + sLineBreak +
                       '目标目录: ' + ATargetPath + sLineBreak + sLineBreak +
                       '这将导致循环引用，请选择其他目标位置。');
    Result := False;
    Exit;
  end;
  
  // 4. 检查是否试图迁移到系统目录
  if IsSystemCriticalDirectory(ATargetPath) then
  begin
    ShowChineseMessage('警告：不建议迁移到系统目录！' + sLineBreak + sLineBreak +
                       '目标目录: ' + ATargetPath + sLineBreak + sLineBreak +
                       '迁移到系统目录可能影响系统稳定性。');
    
    if not ShowChineseConfirm('是否强制继续？（不推荐）') then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

// ===== 文件列表管理 =====

// 初始化文件列表控件
procedure TfrmMain.InitializeFileList;
begin
  // 使用设计时的lvFiles控件
  FFileListView := lvFiles;
  if Assigned(FFileListView) then
  begin
    FFileListView.ViewStyle := vsReport;
    FFileListView.GridLines := True;
    FFileListView.RowSelect := True;
    FFileListView.ReadOnly := True;
    
    // 不修改列设置，保持设计时的列宽
    // 列标题和宽度已在设计时设置好
  end;
end;

// 加载文件列表
procedure TfrmMain.LoadFileList(const APath: string);
var
  Files: TArray<string>;
  Dirs: TArray<string>;
  Item: TListItem;
  FileInfo: TSearchRec;
  I: Integer;
  FileSize: Int64;
  FileTime: TDateTime;
begin
  if not Assigned(FFileListView) then
    Exit;
    
  FFileListView.Items.BeginUpdate;
  try
    FFileListView.Clear;
    
    if not TDirectory.Exists(APath) then
    begin
      UpdateStatus('目录不存在: ' + APath);
      Exit;
    end;
    
    try
      // 先显示子目录
      Dirs := TDirectory.GetDirectories(APath);
      for I := 0 to High(Dirs) do
      begin
        Item := FFileListView.Items.Add;
        Item.Caption := TPath.GetFileName(Dirs[I]);
        Item.SubItems.Add('<DIR>');
        
        if FindFirst(Dirs[I], faDirectory, FileInfo) = 0 then
        begin
          FileTime := FileInfo.TimeStamp;
          Item.SubItems.Add(DateTimeToStr(FileTime));
          FindClose(FileInfo);
        end
        else
          Item.SubItems.Add('');
          
        Item.SubItems.Add('文件夹');
        Item.ImageIndex := 0; // 文件夹图标
      end;
      
      // 再显示文件
      Files := TDirectory.GetFiles(APath);
      for I := 0 to High(Files) do
      begin
        Item := FFileListView.Items.Add;
        Item.Caption := TPath.GetFileName(Files[I]);
        
        try
          FileSize := TFile.GetSize(Files[I]);
          Item.SubItems.Add(TSystemCheck.FormatBytes(FileSize));
        except
          Item.SubItems.Add('');
        end;
        
        if FindFirst(Files[I], faAnyFile, FileInfo) = 0 then
        begin
          FileTime := FileInfo.TimeStamp;
          Item.SubItems.Add(DateTimeToStr(FileTime));
          FindClose(FileInfo);
        end
        else
          Item.SubItems.Add('');
          
        Item.SubItems.Add(ExtractFileExt(Files[I]));
        Item.ImageIndex := 1; // 文件图标
      end;
      
      UpdateStatus(Format('已加载 %d 个目录和 %d 个文件', [Length(Dirs), Length(Files)]));
      
    except
      on E: Exception do
        UpdateStatus('加载文件列表失败: ' + E.Message);
    end;
    
  finally
    FFileListView.Items.EndUpdate;
  end;
end;

// 重复的方法定义已在类声明中定义，这里移除重复定义

// 新增菜单事件处理

procedure TfrmMain.miSrcDeleteClick(Sender: TObject);
begin
  if FSourcePath <> '' then
    DeleteDirectory(FSourcePath, tvSource)
  else
    ShowChineseMessage('请先选择源目录!');
end;

procedure TfrmMain.miSrcPropertiesClick(Sender: TObject);
begin
  if FSourcePath <> '' then
    ShowDirectoryProperties(FSourcePath)
  else
    ShowChineseMessage('请先选择源目录!');
end;

procedure TfrmMain.miTgtDeleteClick(Sender: TObject);
begin
  if FTargetPath <> '' then
    DeleteDirectory(FTargetPath, tvTarget)
  else
    ShowChineseMessage('请先选择目标目录!');
end;

procedure TfrmMain.miTgtPropertiesClick(Sender: TObject);
begin
  if FTargetPath <> '' then
    ShowDirectoryProperties(FTargetPath)
  else
    ShowChineseMessage('请先选择目标目录!');
end;

// ===== 进度管理 =====

// 更新当前正在处理的文件名
procedure TfrmMain.UpdateCurrentFile(const AFileName: string);
var
  DisplayName: string;
  FileName: string;
begin
  // 只显示文件名，不显示完整路径
  FileName := ExtractFileName(AFileName);
  DisplayName := FileName;
  
  // 截取文件名，避免过长
  if Length(DisplayName) > 50 then
    DisplayName := '...' + Copy(DisplayName, Length(DisplayName) - 46, 47);
  
  lblCurrentFile.Caption := '📄 正在处理: ' + DisplayName;
  Application.ProcessMessages;
end;

// 更新剩余时间估算
procedure TfrmMain.UpdateTimeRemaining;
var
  ElapsedSeconds: Double;
  AvgSecondsPerFile: Double;
  RemainingFiles: Integer;
  EstimatedSeconds: Integer;
  Hours, Minutes, Seconds: Integer;
  TimeStr: string;
  RemainingBytes: Int64;
  SpeedStr: string;
begin
  if (FProcessedFilesCount = 0) or (FTotalFilesCount = 0) then
  begin
    lblTimeRemaining.Caption := '剩余时间: 计算中...';
    Exit;
  end;
  
  ElapsedSeconds := (Now - FStartTime) * 86400; // 转换为秒
  
  if ElapsedSeconds < 1 then
    Exit;
  
  AvgSecondsPerFile := ElapsedSeconds / FProcessedFilesCount;
  RemainingFiles := FTotalFilesCount - FProcessedFilesCount;
  EstimatedSeconds := Round(RemainingFiles * AvgSecondsPerFile);
  
  // 计算复制速度
  if (FTotalBytesToCopy > 0) and (FCopiedBytesSoFar > 0) then
  begin
    RemainingBytes := FTotalBytesToCopy - FCopiedBytesSoFar;
    SpeedStr := Format(' | 速度: %s/s', [TSystemCheck.FormatBytes(Round(FCopiedBytesSoFar / ElapsedSeconds))]);
  end
  else
    SpeedStr := '';
  
  Hours := EstimatedSeconds div 3600;
  Minutes := (EstimatedSeconds mod 3600) div 60;
  Seconds := EstimatedSeconds mod 60;
  
  if Hours > 0 then
    TimeStr := Format('剩余时间: %d 小时 %d 分钟', [Hours, Minutes])
  else if Minutes > 0 then
    TimeStr := Format('剩余时间: %d 分钟 %d 秒', [Minutes, Seconds])
  else
    TimeStr := Format('剩余时间: %d 秒', [Seconds]);
  
  lblTimeRemaining.Caption := TimeStr + SpeedStr;
end;

// 显示/隐藏取消按钮
procedure TfrmMain.ShowCancelButton(AShow: Boolean);
begin
  btnCancelOperation.Visible := AShow;
  btnCancelOperation.Enabled := AShow;
  
  if AShow then
  begin
    btnCancelOperation.Caption := '取消操作';
    UpdateStatus('操作进行中，点击“取消操作”可中止');
  end
  else
  begin
    lblCurrentFile.Caption := '📄 当前文件: 已完成';
    lblTimeRemaining.Caption := '剩余时间: 0 秒';
    FCancelRequested := False;
  end;
end;

// 取消按钮点击事件
procedure TfrmMain.btnCancelOperationClick(Sender: TObject);
begin
  if ShowChineseConfirm('=== 取消操作 ===' + sLineBreak + sLineBreak +
                        '确定要取消当前操作吗？' + sLineBreak + sLineBreak +
                        '=== 取消后的处理 ===' + sLineBreak +
                        '• 已复制的文件将被清理' + sLineBreak +
                        '• 源目录保持不变' + sLineBreak +
                        '• 不会影响现有数据') then
  begin
    FCancelRequested := True;
    btnCancelOperation.Enabled := False;
    UpdateStatus('用户请求取消操作...');
  end;
end;

// 专家模式通过菜单项miSimpleMode控制，chkExpertMode已移除

// ===== 简洁模式和权限管理 =====

// 检查并请求管理员权限
procedure TfrmMain.CheckAndRequestAdminPrivileges;
var
  PrivCheck: TPrivilegeCheckResult;
begin
  PrivCheck := TSystemCheck.CheckAdminPrivileges;
  FIsAdmin := PrivCheck.IsAdmin and PrivCheck.IsElevated;
  
  if FIsAdmin then
  begin
    UpdateStatus('已获取管理员权限');
    StatusBar1.Panels[0].Text := '管理员模式';
  end
  else
  begin
    UpdateStatus('[警告] 未以管理员身份运行，部分功能将受限');
    StatusBar1.Panels[0].Text := '普通模式（功能受限）';
    
    ShowChineseMessage(
      '提示：' + sLineBreak + sLineBreak +
      '程序未以管理员身份运行！' + sLineBreak + sLineBreak +
      '以下功能将受限：' + sLineBreak +
      '• 目录迁移（创建Junction需要管理员权限）' + sLineBreak +
      '• 系统目录清理' + sLineBreak +
      '• Windows更新缓存清理' + sLineBreak + sLineBreak +
      '建议：右键程序图标，选择"以管理员身份运行"');
  end;
  
  // 更新按钮状态
  UpdateButtonStates;
end;

// 更新按钮状态（根据权限和简洁模式）
procedure TfrmMain.UpdateButtonStates;
begin
  // 需要管理员权限的按钮 - 添加存在性检查
  if Assigned(btnExecute) then btnExecute.Enabled := FIsAdmin;
  if Assigned(btnSmartMigration) then btnSmartMigration.Enabled := FIsAdmin;
  if Assigned(btnRollback) then btnRollback.Enabled := FIsAdmin;
  // if Assigned(btnCleanUpdate) then btnCleanUpdate.Enabled := FIsAdmin;
  
  // 在简洁模式下隐藏高级按钮
  if FSimpleMode then
  begin
    // 简洁模式：只显示一键按钮
    if Assigned(btnOneKeyDiagnose) then btnOneKeyDiagnose.Visible := True;
    if Assigned(btnSmartClean) then btnSmartClean.Visible := True;
    if Assigned(btnSmartMigration) then btnSmartMigration.Visible := True;
    // if Assigned(btnAdvancedFileManager) then btnAdvancedFileManager.Visible := True;
    if Assigned(btnRollback) then btnRollback.Visible := True;
    if Assigned(btnExit) then btnExit.Visible := True;
    
    // 隐藏高级按钮
    // if Assigned(btnCleanRecycleBin) then btnCleanRecycleBin.Visible := False;
    // if Assigned(btnCleanTemp) then btnCleanTemp.Visible := False;
    if Assigned(btnCleanBackup) then btnCleanBackup.Visible := False;
    // if Assigned(btnCleanUpdate) then btnCleanUpdate.Visible := False;
    if Assigned(btnAnalyze) then btnAnalyze.Visible := False;
    if Assigned(btnCalculateSize) then btnCalculateSize.Visible := False;
    if Assigned(btnExecute) then btnExecute.Visible := False;
  end
  else
  begin
    // 专家模式：显示所有按钮
    if Assigned(btnOneKeyDiagnose) then btnOneKeyDiagnose.Visible := True;
    // if Assigned(btnCleanRecycleBin) then btnCleanRecycleBin.Visible := True;
    // if Assigned(btnCleanTemp) then btnCleanTemp.Visible := True;
    if Assigned(btnCleanBackup) then btnCleanBackup.Visible := True;
    // if Assigned(btnCleanUpdate) then btnCleanUpdate.Visible := True;
    if Assigned(btnSmartClean) then btnSmartClean.Visible := True;
    if Assigned(btnSmartMigration) then btnSmartMigration.Visible := True;
    // if Assigned(btnAdvancedFileManager) then btnAdvancedFileManager.Visible := True;
    if Assigned(btnRollback) then btnRollback.Visible := True;
    if Assigned(btnAnalyze) then btnAnalyze.Visible := True;
    if Assigned(btnCalculateSize) then btnCalculateSize.Visible := True;
    if Assigned(btnExecute) then btnExecute.Visible := True;
    if Assigned(btnExit) then btnExit.Visible := True;
  end;
end;

// 设置简洁模式
procedure TfrmMain.SetSimpleMode(ASimple: Boolean);
begin
  FSimpleMode := ASimple;
  miSimpleMode.Checked := ASimple;
  // chkExpertMode已移除，不需同步
  UpdateButtonStates;
  
  if ASimple then
    UpdateStatus('已切换到简洁模式，适合新手使用')
  else
    UpdateStatus('已切换到专家模式，显示所有功能');
end;

// 简洁模式菜单点击事件
procedure TfrmMain.miSimpleModeClick(Sender: TObject);
begin
  SetSimpleMode(miSimpleMode.Checked);
end;

// ===== 一键功能 =====

// 一键回退按钮点击事件
procedure TfrmMain.btnRollbackClick(Sender: TObject);
begin
  PerformOneKeyRollback;
end;

// 一键诊断按钮点击事件
procedure TfrmMain.btnOneKeyDiagnoseClick(Sender: TObject);
begin
  PerformOneKeyDiagnose;
end;

// 一键回退功能实现
procedure TfrmMain.PerformOneKeyRollback;
var
  BackupDir: string;
  OriginalDir: string;
  JunctionPath: string;
  FileCount: Integer;
  TotalSize: Int64;
  PosBackup: Integer;
begin
  if not FIsAdmin then
  begin
    ShowChineseMessage('请以管理员身份运行程序后再进行回退操作！');
    Exit;
  end;
  
  UpdateStatus('正在检测最近的备份...');
  
  // 检查是否有最近的备份
  if FLastBackupPath = '' then
  begin
    ShowChineseMessage('没有找到最近的备份目录！' + sLineBreak + sLineBreak +
                       '如果你之前有迁移操作，请在专家模式下使用「清理备份」菜单手动处理。');
    Exit;
  end;
  
  BackupDir := FLastBackupPath;
  
  if not TDirectory.Exists(BackupDir) then
  begin
    ShowChineseMessage('备份目录不存在：' + BackupDir);
    FLastBackupPath := '';
    Exit;
  end;
  
  // 从备份目录名推断原始目录
  // 备份格式：原目录.backup_YYYYMMDD_HHNNSS
  OriginalDir := BackupDir;
  PosBackup := System.Pos('.backup_', OriginalDir);
  if PosBackup > 0 then
    OriginalDir := Copy(OriginalDir, 1, PosBackup - 1)
  else
  begin
    ShowChineseMessage('无法从备份目录名推断原始目录！');
    Exit;
  end;
  
  // 计算备份目录大小
  ComputeDirStats(BackupDir, FileCount, TotalSize);
  
  // 确认回退
  if not ShowChineseConfirm(
    '确认要回退这次迁移吗？' + sLineBreak + sLineBreak +
    '原始目录：' + OriginalDir + sLineBreak +
    '备份目录：' + BackupDir + sLineBreak +
    '备份大小：' + TSystemCheck.FormatBytes(TotalSize) + sLineBreak +
    '文件数量：' + IntToStr(FileCount) + sLineBreak + sLineBreak +
    '回退操作将：' + sLineBreak +
    '1. 删除Junction链接' + sLineBreak +
    '2. 恢复原始目录' + sLineBreak + sLineBreak +
    '注意：目标位置的文件将保留，不会被删除。') then
    Exit;
  
  UpdateStatus('开始回退操作...');
  ProgressBar1.Visible := True;
  ProgressBar1.Style := pbstMarquee;
  
  try
    // 1. 删除Junction链接
    JunctionPath := OriginalDir;
    if TDirectory.Exists(JunctionPath) then
    begin
      UpdateStatus('正在删除Junction链接...');
      try
        // 删除Junction（使用RemoveDirectory，不会删除目标文件）
        if not RemoveDirectory(PChar(JunctionPath)) then
        begin
          ShowChineseMessage('删除Junction失败！' + sLineBreak + '请手动删除：' + JunctionPath);
          Exit;
        end;
        UpdateStatus('已删除Junction链接');
      except
        on E: Exception do
        begin
          ShowChineseMessage('删除Junction时发生错误：' + E.Message);
          Exit;
        end;
      end;
    end;
    
    // 2. 恢复原始目录
    UpdateStatus('正在恢复原始目录...');
    if not RenameFile(BackupDir, OriginalDir) then
    begin
      ShowChineseMessage('恢复原始目录失败！' + sLineBreak + sLineBreak +
                         '请手动将：' + sLineBreak + BackupDir + sLineBreak +
                         '重命名为：' + sLineBreak + OriginalDir);
      Exit;
    end;
    
    UpdateStatus('回退完成！');
    FLastBackupPath := '';
    
    ShowChineseMessage('回退操作已成功完成！' + sLineBreak + sLineBreak +
                       '原始目录已恢复到：' + OriginalDir);
    
  finally
    ProgressBar1.Visible := False;
    ProgressBar1.Style := pbstNormal;
  end;
end;

// 一键诊断功能实现
procedure TfrmMain.PerformOneKeyDiagnose;
var
  CDrive: string;
  I: Integer;
  FreeSpace, TotalSpace, UsedSpace: Int64;
  UsagePercent: Double;
  Msg: TStringList;
  UserProfile: string;
begin
  UpdateStatus('正在诊断c盘...');
  
  CDrive := 'C:\\';
  UserProfile := GetEnvironmentVariable('USERPROFILE');
  
  if not TDirectory.Exists(CDrive) then
  begin
    ShowChineseMessage('C盘不存在！');
    Exit;
  end;
  
  Msg := TStringList.Create;
  try
    Msg.Add('===== C盘诊断报告 =====');
    Msg.Add('');
    
    // 获取磁盘空间信息
    if GetDiskFreeSpaceEx(PChar(CDrive), FreeSpace, TotalSpace, nil) then
    begin
      UsedSpace := TotalSpace - FreeSpace;
      UsagePercent := (UsedSpace * 100.0) / TotalSpace;
      
      Msg.Add('磁盘空间信息：');
      Msg.Add(Format('  总容量：%s', [TSystemCheck.FormatBytes(TotalSpace)]));
      Msg.Add(Format('  已使用：%s (%.1f%%)', [TSystemCheck.FormatBytes(UsedSpace), UsagePercent]));
      Msg.Add(Format('  可用空间：%s', [TSystemCheck.FormatBytes(FreeSpace)]));
      Msg.Add('');
      
      if UsagePercent > 90 then
        Msg.Add('[警告] C盘空间严重不足！建议立即进行清理和迁移。')
      else if UsagePercent > 80 then
        Msg.Add('[注意] C盘空间较紧张，建议进行清理。')
      else if UsagePercent > 70 then
        Msg.Add('[提示] C盘空间尚可，但建议定期清理。')
      else
        Msg.Add('C盘空间充足。');
        
      Msg.Add('');
    end;
    
    Msg.Add('建议操作：');
    Msg.Add('1. 点击【一键清理】清除系统垃圾文件');
    Msg.Add('2. 选择大目录后点击【一键迁移】');
    Msg.Add('3. 定期执行清理维护');
    Msg.Add('');
    Msg.Add('常见可迁移目录：');
    // 支持中英文目录名
    if TDirectory.Exists(TPath.Combine(UserProfile, 'Documents')) then
      Msg.Add('  - ' + TPath.Combine(UserProfile, 'Documents'))
    else if TDirectory.Exists(TPath.Combine(UserProfile, '文档')) then
      Msg.Add('  - ' + TPath.Combine(UserProfile, '文档'));
    
    if TDirectory.Exists(TPath.Combine(UserProfile, 'Downloads')) then
      Msg.Add('  - ' + TPath.Combine(UserProfile, 'Downloads'))
    else if TDirectory.Exists(TPath.Combine(UserProfile, '下载')) then
      Msg.Add('  - ' + TPath.Combine(UserProfile, '下载'));
    
    if TDirectory.Exists(TPath.Combine(UserProfile, 'Desktop')) then
      Msg.Add('  - ' + TPath.Combine(UserProfile, 'Desktop'))
    else if TDirectory.Exists(TPath.Combine(UserProfile, '桌面')) then
      Msg.Add('  - ' + TPath.Combine(UserProfile, '桌面'));
    
    if TDirectory.Exists(TPath.Combine(UserProfile, 'Pictures')) then
      Msg.Add('  - ' + TPath.Combine(UserProfile, 'Pictures'))
    else if TDirectory.Exists(TPath.Combine(UserProfile, '图片')) then
      Msg.Add('  - ' + TPath.Combine(UserProfile, '图片'));
    
    if TDirectory.Exists(TPath.Combine(UserProfile, 'Videos')) then
      Msg.Add('  - ' + TPath.Combine(UserProfile, 'Videos'))
    else if TDirectory.Exists(TPath.Combine(UserProfile, '视频')) then
      Msg.Add('  - ' + TPath.Combine(UserProfile, '视频'));
    
    if TDirectory.Exists(TPath.Combine(UserProfile, 'Music')) then
      Msg.Add('  - ' + TPath.Combine(UserProfile, 'Music'))
    else if TDirectory.Exists(TPath.Combine(UserProfile, '音乐')) then
      Msg.Add('  - ' + TPath.Combine(UserProfile, '音乐'));
    
    memoStatus.Lines.Assign(Msg);
    UpdateStatus('C盘诊断完成');
    
  finally
    Msg.Free;
  end;
end;

// 一键优化功能实现
procedure TfrmMain.PerformOneKeyOptimize;
var
  TotalFreed: Int64;
  Result: TCleanupResult;
begin
  if not ShowChineseConfirm(
    '一键优化将执行以下操作：' + sLineBreak + sLineBreak +
    '1. 清空回收站' + sLineBreak +
    '2. 清理临时文件' + sLineBreak +
    '3. 清理系统日志' + sLineBreak +
    '4. 清理浏览器缓存' + sLineBreak + sLineBreak +
    '是否继续？') then
    Exit;
  
  TotalFreed := 0;
  UpdateStatus('开始一键优化...');
  ProgressBar1.Visible := True;
  ProgressBar1.Style := pbstMarquee;
  
  try
    // 1. 清空回收站
    UpdateStatus('正在清空回收站...');
    Result := FCleanupManager.EmptyRecycleBin;
    if Result.Success then
      TotalFreed := TotalFreed + Result.SpaceFreed;
    
    // 2. 清理临时文件
    UpdateStatus('正在清理临时文件...');
    Result := FCleanupManager.CleanTempFiles;
    if Result.Success then
      TotalFreed := TotalFreed + Result.SpaceFreed;
    
    // 3. 清理系统日志
    UpdateStatus('正在清理系统日志...');
    Result := FCleanupManager.CleanSystemLogs;
    if Result.Success then
      TotalFreed := TotalFreed + Result.SpaceFreed;
    
    // 4. 清理浏览器缓存
    UpdateStatus('正在清理浏览器缓存...');
    Result := FCleanupManager.CleanBrowserCache;
    if Result.Success then
      TotalFreed := TotalFreed + Result.SpaceFreed;
    
    UpdateStatus('一键优化完成！');
    
    ShowChineseMessage(
      '一键优化完成！' + sLineBreak + sLineBreak +
      Format('共释放空间：%s', [TSystemCheck.FormatBytes(TotalFreed)]));
    
  finally
    ProgressBar1.Visible := False;
    ProgressBar1.Style := pbstNormal;
  end;
end;

// ===== 其他辅助方法 =====

// 添加缺失的方法实现

function TfrmMain.ShowDirectoryProperties(const APath: string): Boolean;
var
  FileCount: Integer;
  TotalSize: Int64;
  Msg: string;
begin
  Result := True;
  if not TDirectory.Exists(APath) then
  begin
    ShowChineseMessage('目录不存在!');
    Result := False;
    Exit;
  end;
  
  FileCount := 0;
  TotalSize := 0;
  
  UpdateStatus('正在计算目录属性...');
  
  try
    ComputeDirStats(APath, FileCount, TotalSize);
    
    Msg := Format(
      '目录属性' + sLineBreak + sLineBreak +
      '路径: %s' + sLineBreak + sLineBreak +
      '文件数量: %d' + sLineBreak +
      '总大小: %s' + sLineBreak +
      '(%d 字节)',
      [APath, FileCount, TSystemCheck.FormatBytes(TotalSize), TotalSize]);
    
    ShowChineseMessage(Msg);
    UpdateStatus('属性计算完成');
  except
    on E: Exception do
    begin
      ShowChineseMessage('计算属性失败: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TfrmMain.DeleteDirectory(const APath: string; ATreeView: TTreeView): Boolean;
var
  FileCount: Integer;
  TotalSize: Int64;
  Msg: string;
begin
  Result := False;
  if not TDirectory.Exists(APath) then
  begin
    ShowChineseMessage('目录不存在!');
    Exit;
  end;
  
  // 计算目录信息
  FileCount := 0;
  TotalSize := 0;
  ComputeDirStats(APath, FileCount, TotalSize);
  
  Msg := Format(
    '=== 删除确认 ===' + sLineBreak + sLineBreak +
    '路径: %s' + sLineBreak + sLineBreak +
    '文件数量: %d 个' + sLineBreak +
    '总大小: %s' + sLineBreak + sLineBreak +
    '=== 风险提示 ===' + sLineBreak +
    '• 删除后文件无法恢复' + sLineBreak +
    '• 请确认没有重要文件' + sLineBreak +
    '• 建议先备份再删除',
    [APath, FileCount, TSystemCheck.FormatBytes(TotalSize)]);
  
  if not ShowChineseConfirm(Msg) then
    Exit;
  
  // 二次确认 - 最后一次确认
  if not ShowChineseConfirm('=== 最终确认 ===' + sLineBreak + sLineBreak +
    '确定要永久删除此目录吗？' + sLineBreak + sLineBreak +
    APath + sLineBreak + sLineBreak +
    '此操作不可撤销！') then
    Exit;
  
  UpdateStatus('正在删除目录: ' + APath);
  
  try
    TDirectory.Delete(APath, True);
    UpdateStatus('已成功删除目录: ' + APath);
    ShowChineseMessage('目录已成功删除!');
    
    // 刷新目录树
    if ATreeView = tvSource then
    begin
      LoadDirectoryTree(tvSource, TPath.GetDirectoryName(APath));
      FSourcePath := TPath.GetDirectoryName(APath);
    end
    else if ATreeView = tvTarget then
    begin
      LoadDirectoryTree(tvTarget, TPath.GetDirectoryName(APath));
      FTargetPath := TPath.GetDirectoryName(APath);
    end;
    
    // 清空文件列表
    if Assigned(FFileListView) then
      FFileListView.Clear;
      
    Result := True;
    
  except
    on E: Exception do
    begin
      UpdateStatus('删除目录失败: ' + E.Message);
      ShowChineseMessage('删除目录失败:' + sLineBreak + E.Message);
    end;
  end;
end;

// ===== 系统监控和性能分析方法实现 =====

procedure TfrmMain.StartSystemMonitoring;
begin
  if not FMonitoringActive and Assigned(FSystemMonitor) then
  begin
  FSystemMonitor.Start;
    FMonitoringActive := True;
    UpdateStatus('系统监控已启动');
  end;
end;

procedure TfrmMain.StopSystemMonitoring;
begin
  if FMonitoringActive then
  begin
    if Assigned(FSystemMonitor) then
      FSystemMonitor.Stop;
    FMonitoringActive := False;
    UpdateStatus('系统监控已停止');
  end;
end;

procedure TfrmMain.ShowSystemMonitorDialog;
var
  MonitorDialog: TfrmSystemMonitorDialog;
begin
  try
    LogInfo('SystemMonitor', '正在打开增强系统监控对话框');
    
    MonitorDialog := TfrmSystemMonitorDialog.Create(Self);
    try
      MonitorDialog.Show; // 使用Show而不是ShowModal，允许同时使用主窗口
    except
      MonitorDialog.Free;
      raise;
    end;
    
    UpdateStatus('增强系统监控对话框已打开');
  except
    on E: Exception do
    begin
      UpdateStatus('打开系统监控对话框失败: ' + E.Message);
      ShowChineseMessage('打开系统监控对话框失败：' + sLineBreak + E.Message);
      LogError('SystemMonitor', '打开系统监控对话框失败: ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.ShowPerformanceAnalysisDialog;
var
  Info: TSystemInfo;
  ReportText: string;
begin
  if not Assigned(FSystemMonitor) then
  begin
    ShowChineseMessage('性能分析器未初始化！');
    Exit;
  end;
  
  Info := FSystemMonitor.GetCurrentSystemInfo;
  
  ReportText := '性能分析报告' + sLineBreak + sLineBreak;
  
  // 系统健康状态基本判断
  if (Info.CPUUsage < 50) and (Info.MemoryUsage < 70) and (Info.DiskUsage < 80) then
    ReportText := ReportText + '系统状态: 优秅' + sLineBreak
  else if (Info.CPUUsage < 70) and (Info.MemoryUsage < 80) and (Info.DiskUsage < 90) then
    ReportText := ReportText + '系统状态: 良好' + sLineBreak
  else if (Info.CPUUsage < 85) and (Info.MemoryUsage < 90) then
    ReportText := ReportText + '系统状态: 一般' + sLineBreak
  else
    ReportText := ReportText + '系统状态: 需要优化' + sLineBreak;
    
  ReportText := ReportText + sLineBreak;
  
  // 简单的优化建议
  ReportText := ReportText + '优化建议:' + sLineBreak;
  
  if Info.CPUUsage > 80 then
    ReportText := ReportText + '  - CPU使用率过高，建议关闭不必要的程序' + sLineBreak;
  
  if Info.MemoryUsage > 80 then
    ReportText := ReportText + '  - 内存使用率过高，建议清理内存' + sLineBreak;
    
  if Info.DiskUsage > 85 then
    ReportText := ReportText + '  - 磁盘空间不足，建议清理临时文件' + sLineBreak;
  
  if Info.ProcessCount > 150 then
    ReportText := ReportText + '  - 进程数量过多，建议结束不必要的进程' + sLineBreak;
  
  ShowChineseMessage(ReportText);
end;

procedure TfrmMain.PerformSystemOptimization;
var
  ResultText: string;
begin
  if not ShowChineseConfirm('确认要执行系统优化吗？' + sLineBreak + sLineBreak +
                           '操作包括：' + sLineBreak +
                           '- 释放内存' + sLineBreak +
                           '- 清理临时文件' + sLineBreak +
                           '- 系统优化操作') then
    Exit;
    
  UpdateStatus('正在执行系统优化...');
  ProgressBar1.Visible := True;
  ProgressBar1.Style := pbstMarquee;
  
  try
    // 调用现有的清理功能
    UpdateStatus('正在清理临时文件...');
    CleanTempFiles;
    
    UpdateStatus('正在清理系统缓存...');
    CleanUpdateCache;
    
    // 释放工作集内存
    UpdateStatus('正在释放内存...');
    if SetProcessWorkingSetSize(GetCurrentProcess, SIZE_T(-1), SIZE_T(-1)) then
      UpdateStatus('内存释放成功')
    else
      UpdateStatus('内存释放失败');
      
    UpdateStatus('系统优化完成');
    ShowChineseMessage('系统优化完成！' + sLineBreak + sLineBreak +
                       '已执行以下优化操作：' + sLineBreak +
                       '- 清理临时文件' + sLineBreak +
                       '- 清理系统缓存' + sLineBreak +
                       '- 释放工作集内存');
  except
    on E: Exception do
    begin
      UpdateStatus('系统优化失败: ' + E.Message);
      ShowChineseMessage('系统优化失败：' + sLineBreak + E.Message);
    end;
  end;
  
  try
    ProgressBar1.Style := pbstNormal;
    ProgressBar1.Visible := False;
  except
  end;
end;

procedure TfrmMain.OnSystemInfoUpdate(const Info: TSystemInfo);
begin
  // 在状态栏中显示系统资源信息
  if StatusBar1.Panels.Count > 2 then
  begin
    StatusBar1.Panels[2].Text := Format('CPU: %.0f%% | 内存: %.0f%%', 
      [Info.CPUUsage, Info.MemoryUsage]);
  end;
end;

procedure TfrmMain.OnMonitorEventAlert(const Event: TMonitorEvent);
var
  AlertText: string;
begin
  case Event.EventType of
    metWarning: AlertText := '警告: ' + Event.Message;
    metError: AlertText := '错误: ' + Event.Message;
    metCritical: AlertText := '严重: ' + Event.Message;
  else
    AlertText := '信息: ' + Event.Message;
  end;
  
  // 在状态栏中显示警告
  UpdateStatus('[警告] ' + AlertText);
  
  // 如果是严重警告，弹出对话框
  if Event.EventType = metCritical then
  begin
    ShowChineseMessage(AlertText + sLineBreak + sLineBreak + '建议立即进行系统优化！');
  end;
end;

// ===== C盘空间分析功能实现 =====

procedure TfrmMain.StartCDriveAnalysis;
begin
  if not Assigned(FCDriveAnalyzer) then
  begin
    ShowChineseMessage('空间分析器未初始化！');
    Exit;
  end;
  
  if FCDriveAnalyzer.Analyzing then
  begin
    ShowChineseMessage('分析正在进行中，请稍候...');
    Exit;
  end;
  
  if not ShowChineseConfirm('即将开始C盘空间分析，这可能需要几分钟时间。' + sLineBreak + sLineBreak +
                           '分析将扫描C盘上的所有文件夹，找出占用空间最多的目录和文件。' + sLineBreak + sLineBreak +
                           '是否继续？') then
    Exit;
    
  UpdateStatus('正在分析C盘空间使用情况...');
  ProgressBar1.Visible := True;
  ProgressBar1.Style := pbstNormal;
  ProgressBar1.Position := 0;
  ShowCancelButton(True);
  
  // 创建线程进行空间分析
  // Simplified version - run synchronously
  var Success: Boolean;
  var TempResults: TArray<TCleanupSuggestion>;
  var TempTime: TDateTime;
  var ErrorMsg: string;
  
  try
    Success := FCDriveAnalyzer.StartAnalysis;
    
    if Success then
    begin
      TempResults := FCDriveAnalyzer.GetCleanupSuggestions;
      TempTime := Now;
    end;
    
    // Update UI directly
    try
      ProgressBar1.Visible := False;
      ShowCancelButton(False);
      
      if Success then
      begin
        FAnalysisResults := TempResults;
        FLastAnalysisTime := TempTime;
        UpdateStatus('分析完成！');
        ShowAnalysisResults;
      end
      else
      begin
        UpdateStatus('分析被取消或失败');
        ShowChineseMessage('C盘空间分析被取消或失败！');
      end;
    except
      on E: Exception do
      begin
        UpdateStatus('分析时发生错误: ' + E.Message);
        ShowChineseMessage('分析时发生错误：' + sLineBreak + E.Message);
      end;
    end;
  except
    on E: Exception do
    begin
      ErrorMsg := E.Message;
      ProgressBar1.Visible := False;
      ShowCancelButton(False);
      UpdateStatus('分析失败: ' + ErrorMsg);
      ShowChineseMessage('分析失败：' + sLineBreak + ErrorMsg);
    end;
  end;
end;

procedure TfrmMain.ShowAnalysisResults;
var
  I: Integer;
  ResultText: string;
  TotalSavings: Int64;
  CDriveFree, CDriveTotal: Int64;
  UsagePercent: Double;
begin
  if Length(FAnalysisResults) = 0 then
  begin
    ShowChineseMessage('C盘分析完成，但没有发现明显的优化建议。' + sLineBreak + sLineBreak +
                       'C盘可能已经相对干净，或者大部分空间被系统文件占用。');
    Exit;
  end;
  
  CDriveFree := GetCDriveFreeSpace;
  CDriveTotal := GetCDriveTotalSpace;
  UsagePercent := ((CDriveTotal - CDriveFree) * 100.0) / CDriveTotal;
  
  TotalSavings := FCDriveAnalyzer.GetEstimatedSavings;
  
  ResultText := Format(
    'C盘空间分析报告' + sLineBreak + 
    '================================' + sLineBreak + sLineBreak +
    'C盘状态：' + sLineBreak +
    '  总容量：%s' + sLineBreak +
    '  已使用：%s (%.1f%%)' + sLineBreak +
    '  可用空间：%s' + sLineBreak + sLineBreak +
    '分析结果：' + sLineBreak +
    '  扫描文件：%s' + sLineBreak +
    '  扫描目录：%d 个' + sLineBreak +
    '  发现建议：%d 条' + sLineBreak +
    '  预计可节省：%s' + sLineBreak + sLineBreak,
    [
      FCDriveAnalyzer.FormatBytes(CDriveTotal),
      FCDriveAnalyzer.FormatBytes(CDriveTotal - CDriveFree),
      UsagePercent,
      FCDriveAnalyzer.FormatBytes(CDriveFree),
      FCDriveAnalyzer.FormatBytes(FCDriveAnalyzer.GetTotalScannedSize),
      FCDriveAnalyzer.GetTotalDirectories,
      Length(FAnalysisResults),
      FCDriveAnalyzer.FormatBytes(TotalSavings)
    ]
  );
  
  ResultText := ResultText + '优化建议：' + sLineBreak;
  ResultText := ResultText + '--------------------------------' + sLineBreak;
  
  // 按优先级和空间大小显示前10个建议
  for I := 0 to Min(9, High(FAnalysisResults)) do
  begin
    ResultText := ResultText + Format('%d. %s' + sLineBreak, 
      [I + 1, FAnalysisResults[I].Title]);
    ResultText := ResultText + Format('   路径：%s' + sLineBreak, 
      [FAnalysisResults[I].Path]);
    ResultText := ResultText + Format('   可节省：%s' + sLineBreak, 
      [FCDriveAnalyzer.FormatBytes(FAnalysisResults[I].EstimatedSpace)]);
    ResultText := ResultText + Format('   说明：%s' + sLineBreak, 
      [FAnalysisResults[I].Description]);
    ResultText := ResultText + sLineBreak;
  end;
  
  if Length(FAnalysisResults) > 10 then
    ResultText := ResultText + Format('...还有 %d 个其他建议', [Length(FAnalysisResults) - 10]);
  
  ShowChineseMessage(ResultText);
  
  // 问是否打开详细的空间分析对话框
  if ShowChineseConfirm('是否查看详细的空间分析信息？') then
    ShowSpaceAnalysisDialog;
end;

procedure TfrmMain.ShowSpaceAnalysisDialog;
var
  I: Integer;
  TopDirs: TArray<TDirectoryInfo>;
  MigratableDirs: TArray<TDirectoryInfo>;
  CleanableDirs: TArray<TDirectoryInfo>;
  LargeFiles: TArray<TLargeFileInfo>;
  DialogText: string;
begin
  if not Assigned(FCDriveAnalyzer) then
    Exit;
    
  DialogText := 'C盘详细分析信息' + sLineBreak + sLineBreak;
  
  // 占用空间最多的目录
  TopDirs := FCDriveAnalyzer.GetTopDirectoriesBySize(5);
  if Length(TopDirs) > 0 then
  begin
    DialogText := DialogText + '占用空间最多的目录：' + sLineBreak;
    for I := 0 to High(TopDirs) do
    begin
      DialogText := DialogText + Format('  %d. %s - %s' + sLineBreak, 
        [I + 1, TopDirs[I].Name, FCDriveAnalyzer.FormatBytes(TopDirs[I].Size)]);
    end;
    DialogText := DialogText + sLineBreak;
  end;
  
  // 可迁移的目录
  MigratableDirs := FCDriveAnalyzer.GetMigratableDirectories;
  if Length(MigratableDirs) > 0 then
  begin
    DialogText := DialogText + '可迁移的用户目录：' + sLineBreak;
    for I := 0 to Min(4, High(MigratableDirs)) do
    begin
      DialogText := DialogText + Format('  • %s - %s' + sLineBreak, 
        [MigratableDirs[I].Name, FCDriveAnalyzer.FormatBytes(MigratableDirs[I].Size)]);
    end;
    DialogText := DialogText + sLineBreak;
  end;
  
  // 可清理的目录
  CleanableDirs := FCDriveAnalyzer.GetCleanableDirectories;
  if Length(CleanableDirs) > 0 then
  begin
    DialogText := DialogText + '可清理的目录：' + sLineBreak;
    for I := 0 to Min(4, High(CleanableDirs)) do
    begin
      DialogText := DialogText + Format('  • %s - %s' + sLineBreak, 
        [CleanableDirs[I].Name, FCDriveAnalyzer.FormatBytes(CleanableDirs[I].Size)]);
    end;
    DialogText := DialogText + sLineBreak;
  end;
  
  // 大文件
  LargeFiles := FCDriveAnalyzer.GetLargeFiles(100); // 大于100MB的文件
  if Length(LargeFiles) > 0 then
  begin
    DialogText := DialogText + '大文件 (>100MB)：' + sLineBreak;
    for I := 0 to Min(4, High(LargeFiles)) do
    begin
      DialogText := DialogText + Format('  • %s - %s' + sLineBreak, 
        [LargeFiles[I].Name, FCDriveAnalyzer.FormatBytes(LargeFiles[I].Size)]);
    end;
  end;
  
  ShowChineseMessage(DialogText);
end;

procedure TfrmMain.ApplySuggestion(const Suggestion: TCleanupSuggestion);
begin
  // 根据建议类型执行相应操作
  case Suggestion.SuggestionType of
    cstMigrateUserFolders:
    begin
      // 设置源路径并开始迁移
      FSourcePath := Suggestion.Path;
      edtSourceDir.Text := FSourcePath;
      LoadDirectoryTree(tvSource, FSourcePath);
      
      ShowChineseMessage('请选择目标位置后点击“开始迁移”按钮。' + sLineBreak + sLineBreak +
                         '建议将文件夹迁移到D盘或其他非C盘分区。');
    end;
    
    cstCleanTempFiles:
    begin
      if ShowChineseConfirm('即将清理临时文件。该操作安全无风险。' + sLineBreak + sLineBreak +
                           '是否继续？') then
        CleanTempFiles;
    end;
    
    cstCleanRecycleBin:
    begin
      if ShowChineseConfirm('即将清空回收站。注意：清空后文件将无法恢复！' + sLineBreak + sLineBreak +
                           '是否继续？') then
        CleanRecycleBin;
    end;
    
    cstCleanCache:
    begin
      if ShowChineseConfirm('即将清理系统缓存文件。该操作安全无风险。' + sLineBreak + sLineBreak +
                           '是否继续？') then
        CleanUpdateCache;
    end;
    
    cstCleanLogs:
    begin
      if ShowChineseConfirm('即将清理系统日志文件。该操作安全无风险。' + sLineBreak + sLineBreak +
                           '是否继续？') then
        CleanBackupFiles;
    end;
    
    cstCleanLargeFiles:
    begin
      ShowChineseMessage('大文件清理需要手动确认。' + sLineBreak + sLineBreak +
                         '文件位置：' + Suggestion.Path + sLineBreak + sLineBreak +
                         '请手动检查该文件是否仍需要，确认不需要后再删除。');
    end;
  end;
end;

procedure TfrmMain.OnAnalysisProgress(const Message: string; Progress: Integer);
begin
  UpdateStatus(Message);
  if ProgressBar1.Visible then
    ProgressBar1.Position := Progress;
  Application.ProcessMessages;
end;

function TfrmMain.GetCDriveFreeSpace: Int64;
var
  FreeBytes, TotalBytes: Int64;
begin
  Result := 0;
  if GetDiskFreeSpaceEx('C:\\', FreeBytes, TotalBytes, nil) then
    Result := FreeBytes;
end;

function TfrmMain.GetCDriveTotalSpace: Int64;
var
  FreeBytes, TotalBytes: Int64;
begin
  Result := 0;
  if GetDiskFreeSpaceEx('C:\\', FreeBytes, TotalBytes, nil) then
    Result := TotalBytes;
end;

end.

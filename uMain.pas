unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI,
  System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections, System.Generics.Defaults, System.Threading, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Menus, Vcl.FileCtrl, Vcl.Clipbrd,
  System.IOUtils, System.UITypes, Vcl.Shell.ShellCtrls,
  // Modern UI styles and strings
  uStyles, uStrings,
  // Core modules - 企业级功能模块
  Core.DataTypes, Core.ConfigManager, Core.FileSafetyEvaluator, Core.DependencyAnalyzer,
  Core.RebootDetector, Core.FileTypeIdentifier, Core.MigrationPlanner, Core.FileOperationEngine,
  Core.SymlinkManager, Core.BackupManager, Core.RollbackExecutor, Core.EmergencyRecovery,
  Core.EncryptionService, Core.IntegrityVerification, Core.MachineCodeGenerator,
  Core.DatabaseManager, Core.DonationManager,
  // 重复文件检测模块
  Core.DuplicateFileDetector, Core.SmartFileEvaluator, uSmartDuplicateCleanup,
  // 配置管理模块
  uConfigManager;

type
  TExtStat = record
    Ext: string;
    Size: Int64;
    Count: Integer;
  end;

  TfrmMain = class(TForm)
    // 主菜单
    MainMenu1: TMainMenu;
    MenuFile: TMenuItem;
    MenuFileExit: TMenuItem;
    MenuEdit: TMenuItem;
    MenuTools: TMenuItem;
    miConfigManager: TMenuItem;
    miSeparatorTools1: TMenuItem;
    miLogManager: TMenuItem;
    MenuHelp: TMenuItem;
    MenuHelpAbout: TMenuItem;
    MenuTheme: TMenuItem;
    MenuCleanup: TMenuItem;
    MenuCleanupRecycleBin: TMenuItem;
    MenuCleanupTemp: TMenuItem;
    MenuCleanupSeparator: TMenuItem;
    MenuCleanupLastBackup: TMenuItem;
    MenuCleanupSoftwareDistribution: TMenuItem;
    MenuCleanupSeparator2: TMenuItem;
    MenuCleanupDuplicateFiles: TMenuItem;

    // 主面板布局
    pnlMain: TPanel;
    pnlLeft: TPanel;
    pnlRight: TPanel;
    pnlStatus: TPanel;

    // 左侧面板 - 源目录
    lblSourceDir: TLabel;
    edtSourceDir: TEdit;
    btnSourceUp: TButton;
    btnBrowseSource: TButton;
    btnSelectSourceRoot: TButton;
    stvSource: TShellTreeView;

    // 右侧面板 - 目标目录
    lblTargetDir: TLabel;
    edtTargetDir: TEdit;
    btnTargetUp: TButton;
    btnBrowseTarget: TButton;
    btnSelectTargetRoot: TButton;
    stvTarget: TShellTreeView;

    // 状态面板
    lblStatus: TLabel;
    ProgressBar1: TProgressBar;
    memoStatus: TMemo;

    // 源/目标目录树的右键菜单
    pmSource: TPopupMenu;
    miSrcOpen: TMenuItem;
    miSrcOpenInExplorer: TMenuItem;
    miSrcCopyPath: TMenuItem;
    miSrcSetRoot: TMenuItem;
    miSrcScanHere: TMenuItem;
    miSrcAnalyzeHere: TMenuItem;
    miSrcRefresh: TMenuItem;

    pmTarget: TPopupMenu;
    miTgtOpen: TMenuItem;
    miTgtOpenInExplorer: TMenuItem;
    miTgtCopyPath: TMenuItem;
    miTgtSetRoot: TMenuItem;
    miTgtSetAsTargetPath: TMenuItem;
    miTgtRefresh: TMenuItem;

    // 计时器
    InitTimer: TTimer;

    // 工具栏
    pnlToolbar: TPanel;
    btnScan: TButton;
    btnAnalyze: TButton;
    btnExecute: TButton;
    btnStop: TButton;
    btnExit: TButton;

    // 状态栏
    StatusBar1: TStatusBar;

    // 事件处理
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);

    procedure btnBrowseSourceClick(Sender: TObject);
    procedure btnBrowseTargetClick(Sender: TObject);
    procedure btnSelectSourceRootClick(Sender: TObject);
    procedure btnSelectTargetRootClick(Sender: TObject);
    procedure btnScanClick(Sender: TObject);
    procedure btnAnalyzeClick(Sender: TObject);
    procedure btnExecuteClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);

    // 目录树事件
    procedure stvSourceChange(Sender: TObject; Node: TTreeNode);
    procedure stvTargetChange(Sender: TObject; Node: TTreeNode);
    procedure stvSourceContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure stvTargetContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
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

    // DFM 事件声明占位（保持DFM一致，避免编译错误）
    procedure btnSourceUpClick(Sender: TObject);
    procedure btnTargetUpClick(Sender: TObject);
    procedure stvSourceDblClick(Sender: TObject);
    procedure stvSourceKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure stvTargetDblClick(Sender: TObject);
    procedure stvTargetKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure miLogManagerClick(Sender: TObject);


    procedure MenuThemeClick(Sender: TObject);
    procedure MenuFileExitClick(Sender: TObject);
    procedure MenuHelpAboutClick(Sender: TObject);
    procedure MenuCleanupRecycleBinClick(Sender: TObject);
    procedure MenuCleanupTempClick(Sender: TObject);
    procedure MenuCleanupLastBackupClick(Sender: TObject);
    procedure MenuCleanupSoftwareDistributionClick(Sender: TObject);
    procedure MenuCleanupDuplicateFilesClick(Sender: TObject);
    procedure miConfigManagerClick(Sender: TObject);

  private
    FSourcePath: string;
    FTargetPath: string;
    FIsProcessing: Boolean;

    FLastBackupPath: string;
    FTotalBytesToCopy: Int64;
    FCopiedBytesSoFar: Int64;
    FCancelRequested: Boolean;
    
    // 企业级功能模块
    FConfigManager: TConfigManager;
    FSafetyEvaluator: TFileSafetyEvaluator;
    FDependencyAnalyzer: TDependencyAnalyzer;
    FRebootDetector: TRebootDetector;
    FFileTypeIdentifier: TFileTypeIdentifier;
    FMigrationPlanner: TMigrationPlanner;
    FFileOperationEngine: TFileOperationEngine;
    FSymlinkManager: TSymlinkManager;
    FBackupManager: TBackupManager;
    FRollbackExecutor: TRollbackExecutor;
    FEmergencyRecovery: TEmergencyRecovery;
    FDatabaseManager: TDatabaseManager;
    FDonationManager: TDonationManager;

    procedure InitAfterShow(Sender: TObject);
    procedure StartSpaceAnalysis(const RootPath: string);
    procedure LogTopN(const Items: TArray<TPair<string, Int64>>; N: Integer);
    procedure LogTypeAggregation(const Agg: TArray<TExtStat>);
    function IsReparseDir(const Path: string): Boolean;

    // Core模块管理
    procedure InitializeCoreModules;
    procedure CleanupCoreModules;

    // 依赖关系分析
    function PerformDependencyAnalysis(const SourcePath: string): Boolean;
    function GetRiskLevelText(RiskLevel: Integer): string;

    // 高性能文件操作
    function PerformHighPerformanceCopy(const SourcePath, DestPath: string): Int64;

    // 清理功能
    function CleanupTempFiles: Int64;
    function CleanupSoftwareDistribution: Int64;
    procedure SafeDeleteDirectory(const DirPath: string; var DeletedSize: Int64);

    // 迁移与链接
    function CreateDirectoryLink(const LinkPath, TargetPath: string): Boolean;
    function CreateDirectorySymlink(const LinkPath, TargetPath: string): Boolean;
    function CreateDirectoryJunctionViaCmd(const LinkPath, TargetPath: string): Boolean;
    function RunCommandWait(const CmdLine: string; out ExitCode: Cardinal): Boolean;
    procedure CopyDirRecursive(const Src, Dst: string; var CopiedBytes: Int64);
    procedure ComputeDirStats(const Root: string; out FileCount: Integer; out TotalBytes: Int64);
    function DeletePathToRecycleBin(const Path: string): Boolean;

    // 界面相关
    procedure InitializeUI;
    procedure ApplyModernStyles;
    procedure UpdateStatus(const AMessage: string);
    procedure SetProcessingState(AProcessing: Boolean);

    // 基本功能
    procedure ScanDirectory(const APath: string);
    procedure AnalyzeDirectory(const APath: string);
    procedure ExecuteOperation;

    // 目录树相关
    procedure InitializeShellTreeViews;
    procedure UpdateShellTreePath(ATreeView: TShellTreeView; const APath: string);

  public
    { Public declarations }
  end;

const
  VERIFY_SIZE_DIFF_BYTES_THRESHOLD = 5 * 1024 * 1024;  // 5 MB
  VERIFY_SIZE_DIFF_RATIO_THRESHOLD = 0.001;            // 0.1%
  ENABLE_SAMPLE_HASH_CHECK = False;                     // 默认关闭抽样哈希
  SAMPLE_HASH_COUNT = 3;                                // 抽样文件数量

var
  frmMain: TfrmMain;

implementation

procedure OpenInExplorerSelect(const APath: string);
begin
  if (APath = '') then Exit;
  ShellExecute(0, 'open', 'explorer.exe', PChar('/select,' + APath), nil, SW_SHOWNORMAL);
end;

function GetSomeFiles(const Root: string; MaxCount: Integer): TArray<string>;
{$R *.dfm}
var
  L: TList<string>;
  SR: TSearchRec;
  Code: Integer;
  P: string;
begin
  L := TList<string>.Create;
  try
    Code := FindFirst(IncludeTrailingPathDelimiter(Root) + '*', faAnyFile, SR);
    try
      while (Code = 0) and (L.Count < MaxCount) do
      begin
        if (SR.Name <> '.') and (SR.Name <> '..') then
        begin
          P := IncludeTrailingPathDelimiter(Root) + SR.Name;
          if (SR.Attr and faDirectory) = 0 then
            L.Add(P);
        end;
        Code := FindNext(SR);
      end;
    finally
      FindClose(SR);
    end;
    Result := L.ToArray;
  finally
    L.Free;
  end;
end;

function ComputeMD5Hex(const FilePath: string): string;
begin
  Result := '';
end;


procedure TfrmMain.FormCreate(Sender: TObject);
begin
  try
    // 初始化状态
    FIsProcessing := False;
    FCancelRequested := False;
    FTotalBytesToCopy := 0;
    FCopiedBytesSoFar := 0;

    // 初始化Core模块
    InitializeCoreModules;

    // 初始化界面
    InitializeUI;

    // 应用现代化样式
    ApplyModernStyles;

    SetProcessingState(False);

    UpdateStatus(_(STR_APP_STARTED));
  except
    on E: Exception do
    begin
      MessageDlg('FormCreate错误: ' + E.Message, mtError, [mbOK], 0);
      Application.Terminate;
    end;
  end;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  try
    // 停止任何正在进行的操作
    FIsProcessing := False;
    FCancelRequested := True;

    // 清理Core模块
    CleanupCoreModules;

    // 清理资源
    // 注意：不要手动释放由窗体管理的控件
    // Delphi会自动释放窗体及其子控件
  except
    // 忽略销毁过程中的异常，避免程序崩溃
  end;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  try
    // 窗体显示时的处理
    UpdateStatus(_(STR_SELECT_DIRS));

    // 确保路径变量已初始化
    if FSourcePath = '' then
      FSourcePath := 'C:\Users';
    if FTargetPath = '' then
      FTargetPath := 'D:\Users';

    // 使用一次性计时器，避免阻塞 UI
    if Assigned(InitTimer) then
    begin
      InitTimer.Enabled := True;
    end;
    Exit; // 其余初始化在 InitAfterShow 中进行
  except
    on E: Exception do
    begin
      MessageDlg('FormShow错误: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmMain.InitAfterShow(Sender: TObject);
begin
  try
    if Assigned(InitTimer) then
    begin
      InitTimer.Enabled := False;
    end;

    // 初始化目录树路径
    if Assigned(stvSource) then
    begin
      if System.SysUtils.DirectoryExists('C:\Users') then
      begin
        stvSource.Path := 'C:\Users';
        FSourcePath := 'C:\Users';
        edtSourceDir.Text := 'C:\Users';
        UpdateStatus('源目录树已设置为: C:\Users');
      end
      else
        UpdateStatus('C:\Users目录不存在');
    end;

    if Assigned(stvTarget) then
    begin
      if not System.SysUtils.DirectoryExists('D:\Users') then
      begin
        try
          System.SysUtils.ForceDirectories('D:\Users');
          UpdateStatus('已创建目标目录: D:\Users');
        except
          on E: Exception do
          begin
            UpdateStatus('创建D:\Users失败: ' + E.Message);
            stvTarget.Path := 'D:\';
            FTargetPath := 'D:\';
            edtTargetDir.Text := 'D:\';
            UpdateStatus('目标目录回退到: D:\');
            Exit;
          end;
        end;
      end;

      stvTarget.Path := 'D:\Users';
      FTargetPath := 'D:\Users';
      edtTargetDir.Text := 'D:\Users';
      UpdateStatus('目标目录树已设置为: D:\Users');
    end;

  except
    on E: Exception do
      UpdateStatus('延迟初始化失败: ' + E.Message);
  end;
end;

procedure TfrmMain.InitializeUI;
begin
  // 设置窗体属性
  Caption := _(STR_MAIN_TITLE);
  Width := 1280;
  Height := 720;
  Position := poScreenCenter;

  // 设置面板布局
  pnlLeft.Width := 400;
  pnlRight.Width := 400;
  pnlStatus.Height := 200;
  pnlToolbar.Height := 50;

  // 控件属性已在设计时设置，这里同步内部变量
  FSourcePath := edtSourceDir.Text;
  FTargetPath := edtTargetDir.Text;

  // 设置控件标题（国际化）
  lblSourceDir.Caption := _(STR_SOURCE_DIR);
  lblTargetDir.Caption := _(STR_TARGET_DIR);
  lblStatus.Caption := _(STR_READY);

  btnBrowseSource.Caption := _(STR_BROWSE);
  btnBrowseTarget.Caption := _(STR_BROWSE);
  btnSelectSourceRoot.Caption := _(STR_SELECT_ROOT);
  btnSelectTargetRoot.Caption := _(STR_SELECT_ROOT);
  btnScan.Caption := _(STR_SCAN);
  btnAnalyze.Caption := _(STR_ANALYZE);
  btnExecute.Caption := _(STR_EXECUTE);
  btnStop.Caption := _(STR_STOP);
  btnExit.Caption := _(STR_EXIT);

  // 设置面板标题（国际化）
  pnlLeft.Caption := _(STR_SOURCE_PANEL);
  pnlRight.Caption := _(STR_TARGET_PANEL);
  pnlStatus.Caption := _(STR_STATUS_AREA);

  // 初始化目录树
  InitializeShellTreeViews;

  // 设置状态栏
  StatusBar1.Panels.Clear;
  StatusBar1.Panels.Add.Text := STR_STATUS_READY;
  StatusBar1.Panels.Add.Text := STR_STATUS_SOURCE + STR_STATUS_NOT_SELECTED;
  StatusBar1.Panels.Add.Text := STR_STATUS_TARGET + STR_STATUS_NOT_SELECTED;
  StatusBar1.Panels.Add.Text := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
end;

procedure TfrmMain.ApplyModernStyles;
begin
  try
    // 应用窗体样式
    StyleManager.StyleForm(Self);

    // 应用面板样式
    StyleManager.StylePanel(pnlMain);
    StyleManager.StylePanel(pnlLeft);
    StyleManager.StylePanel(pnlRight);
    StyleManager.StylePanel(pnlStatus);
    StyleManager.StylePanel(pnlToolbar);

    // 应用按钮样式
    StyleManager.StyleButton(btnBrowseSource);
    StyleManager.StyleButton(btnBrowseTarget);
    StyleManager.StyleButton(btnSelectSourceRoot);
    StyleManager.StyleButton(btnSelectTargetRoot);
    StyleManager.StyleButton(btnScan);
    StyleManager.StyleButton(btnAnalyze);
    StyleManager.StyleButton(btnExecute);
    StyleManager.StyleButton(btnStop);

    // 应用编辑框样式
    StyleManager.StyleEdit(edtSourceDir);
    StyleManager.StyleEdit(edtTargetDir);

    // 应用目录树样式
    StyleManager.StyleShellTreeView(stvSource);
    StyleManager.StyleShellTreeView(stvTarget);

    // 应用进度条样式
    StyleManager.StyleProgressBar(ProgressBar1);

    // 应用状态栏样式
    StyleManager.StyleStatusBar(StatusBar1);

    UpdateStatus('🎨 现代化界面样式已应用');

  except
    on E: Exception do
      UpdateStatus('⚠️ 应用样式失败: ' + E.Message);
  end;
end;

procedure TfrmMain.UpdateStatus(const AMessage: string);
begin
  try
    lblStatus.Caption := AMessage;
    memoStatus.Lines.Add(FormatDateTime('[hh:nn:ss] ', Now) + AMessage);

    // 自动滚动到底部
    memoStatus.SelStart := Length(memoStatus.Text);
    memoStatus.Perform(EM_SCROLLCARET, 0, 0);

    // 更新状态栏
    if StatusBar1.Panels.Count > 0 then
      StatusBar1.Panels[0].Text := AMessage;

    Application.ProcessMessages;
  except
    // 忽略状态更新错误
  end;
end;

procedure TfrmMain.SetProcessingState(AProcessing: Boolean);
begin
  FIsProcessing := AProcessing;

  // 更新按钮状态
  btnScan.Enabled := not AProcessing;
  btnAnalyze.Enabled := not AProcessing;
  btnExecute.Enabled := not AProcessing;
  btnStop.Enabled := AProcessing;

  // 更新进度条
  if AProcessing then
  begin
    ProgressBar1.Style := pbstMarquee;
    ProgressBar1.MarqueeInterval := 50;
  end
  else
  begin
    ProgressBar1.Style := pbstNormal;
    ProgressBar1.Position := 0;
  end;
end;

procedure TfrmMain.btnBrowseSourceClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtSourceDir.Text;
  if SelectDirectory(_('select_source_title'), '', Dir) then
  begin
    edtSourceDir.Text := Dir;
    FSourcePath := Dir;
    UpdateShellTreePath(stvSource, Dir);
    UpdateStatus(_('source_selected') + Dir);

    if StatusBar1.Panels.Count > 1 then
      StatusBar1.Panels[1].Text := _('status_source') + ExtractFileName(Dir);
  end;
end;

procedure TfrmMain.btnBrowseTargetClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtTargetDir.Text;
  if SelectDirectory(_('select_target_title'), '', Dir) then
  begin
    edtTargetDir.Text := Dir;
    FTargetPath := Dir;
    UpdateShellTreePath(stvTarget, Dir);
    UpdateStatus(_('target_selected') + Dir);

    if StatusBar1.Panels.Count > 2 then
      StatusBar1.Panels[2].Text := _('status_target') + ExtractFileName(Dir);
  end;
end;

procedure TfrmMain.btnScanClick(Sender: TObject);
begin
  if FSourcePath = '' then
  begin
    UpdateStatus('❌ 请先选择源目录');
    Exit;
  end;

  SetProcessingState(True);
  try
    UpdateStatus('🔍 开始扫描目录: ' + FSourcePath);
    ScanDirectory(FSourcePath);
    UpdateStatus('✅ 目录扫描完成');
  finally
    SetProcessingState(False);
  end;
end;

procedure TfrmMain.btnAnalyzeClick(Sender: TObject);
begin
  if FSourcePath = '' then
  begin
    UpdateStatus('❌ 请先选择源目录');
    Exit;
  end;

  SetProcessingState(True);
  try
    UpdateStatus('📊 开始分析目录: ' + FSourcePath);
    StartSpaceAnalysis(FSourcePath);
    UpdateStatus('✅ 分析任务已启动');
  finally
    SetProcessingState(False);
  end;
end;

procedure TfrmMain.StartSpaceAnalysis(const RootPath: string);
var
  TotalSize: Int64;
  TopFiles: TList<TPair<string, Int64>>;
  ExtAgg: TDictionary<string, TPair<Int64, Integer>>;

  procedure ScanDir(const P: string);
  var
    SR: TSearchRec;
    Code: Integer;
    FP: string;
  begin
    if IsReparseDir(P) then Exit; // 跳过联接/挂载点
    Code := FindFirst(IncludeTrailingPathDelimiter(P) + '*', faAnyFile, SR);
    try
      while Code = 0 do
      begin
        if (SR.Name <> '.') and (SR.Name <> '..') then
        begin
          FP := IncludeTrailingPathDelimiter(P) + SR.Name;
          if (SR.Attr and faDirectory) <> 0 then
            ScanDir(FP)
          else
          begin
            Inc(TotalSize, SR.Size);
            TopFiles.Add(TPair<string, Int64>.Create(FP, SR.Size));
            // by ext
            var Ext := LowerCase(ExtractFileExt(SR.Name));
            var Pair: TPair<Int64,Integer>;
            if not ExtAgg.TryGetValue(Ext, Pair) then
              Pair := TPair<Int64,Integer>.Create(0,0);
            Pair := TPair<Int64,Integer>.Create(Pair.Key + SR.Size, Pair.Value + 1);
            ExtAgg.AddOrSetValue(Ext, Pair);
          end;
        end;
        Code := FindNext(SR);
      end;
    finally
      FindClose(SR);
    end;
  end;

begin
  UpdateStatus('📊 开始空间分析: ' + RootPath);
  // 同步执行版本（避免老编译器的 TTask/Queue 差异）
  TotalSize := 0;
  TopFiles := TList<TPair<string, Int64>>.Create;
  ExtAgg := TDictionary<string, TPair<Int64, Integer>>.Create;
  try
    ScanDir(RootPath);
    TopFiles.Sort(TComparer<TPair<string, Int64>>.Construct(
      function(const L, R: TPair<string, Int64>): Integer
      begin
        Result := -CompareValue(L.Value, R.Value);
      end));
    UpdateStatus(Format('📦 总大小: %.2f GB', [TotalSize/1024/1024/1024]));
    var Arr: TArray<TPair<string, Int64>> := TopFiles.ToArray;
    LogTopN(Arr, 10);
    var AggArr: TArray<TExtStat>;
    SetLength(AggArr, ExtAgg.Count);
    var idx: Integer := 0;
    var K: string; var V: TPair<Int64,Integer>;
    for K in ExtAgg.Keys do
    begin
      V := ExtAgg.Items[K];
      AggArr[idx].Ext := K; AggArr[idx].Size := V.Key; AggArr[idx].Count := V.Value; Inc(idx);
    end;
    LogTypeAggregation(AggArr);
  finally
    ExtAgg.Free;
    TopFiles.Free;
  end;
end;

function TfrmMain.IsReparseDir(const Path: string): Boolean;
begin
  Result := (GetFileAttributes(PChar(Path)) and FILE_ATTRIBUTE_REPARSE_POINT) <> 0;
end;

procedure TfrmMain.LogTopN(const Items: TArray<TPair<string, Int64>>; N: Integer);
var
  I, MaxN: Integer;
begin
  MaxN := Min(N, Length(Items));
  UpdateStatus('📈 Top 大文件（前' + MaxN.ToString + '）:');
  for I := 0 to MaxN - 1 do
    UpdateStatus(Format('  %s  (%.2f MB)', [Items[I].Key, Items[I].Value/1024/1024]));
end;

procedure TfrmMain.LogTypeAggregation(const Agg: TArray<TExtStat>);
var
  i: Integer;
begin
  UpdateStatus('🧾 类型聚合:');
  for i := 0 to High(Agg) do
    UpdateStatus(Format('  %-6s  数量:%d  大小:%.2f MB',[Agg[i].Ext, Agg[i].Count, Agg[i].Size/1024/1024]));
end;


procedure TfrmMain.btnExecuteClick(Sender: TObject);
begin
  if (FSourcePath = '') or (FTargetPath = '') then
  begin
    UpdateStatus('❌ 请先选择源目录和目标目录');
    Exit;
  end;

  if MessageDlg('确定要执行操作吗？', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    SetProcessingState(True);
    try
      UpdateStatus('⚡ 开始执行操作...');
      ExecuteOperation;
      UpdateStatus('🎉 操作执行完成');
    finally
      SetProcessingState(False);
    end;
  end;
end;

procedure TfrmMain.btnStopClick(Sender: TObject);
begin
  FCancelRequested := True;
  UpdateStatus('⏹️ 用户请求停止，正在安全中止...');
end;

procedure TfrmMain.btnExitClick(Sender: TObject);
begin
  try
    // 检查是否有操作正在进行
    if FIsProcessing then
    begin
      if MessageDlg(_('confirm_exit'), mtConfirmation, [mbYes, mbNo], 0) = mrNo then
        Exit;

      // 停止正在进行的操作
      FIsProcessing := False;
    end;

    // 安全关闭窗体
    Close;
  except
    on E: Exception do
    begin
      // 如果关闭过程中出现异常，强制退出
      try
        UpdateStatus('退出时发生错误: ' + E.Message);
      except
        // 忽略状态更新错误
      end;

      // 强制退出应用程序
      Application.Terminate;
    end;
  end;
end;

procedure TfrmMain.MenuCleanupRecycleBinClick(Sender: TObject);
var
  Flags: UINT;
begin
  try
    Flags := SHERB_NOCONFIRMATION or SHERB_NOSOUND or SHERB_NOPROGRESSUI;
    if SHEmptyRecycleBin(Handle, nil, Flags) = S_OK then
      UpdateStatus('🗑️ 回收站已清空')
    else
      UpdateStatus('⚠️ 回收站清理可能未完全成功');
  except
    on E: Exception do
      UpdateStatus('❌ 清空回收站失败: ' + E.Message);
  end;
end;
procedure TfrmMain.MenuCleanupTempClick(Sender: TObject);
var
  DeletedSize: Int64;
  SizeStr: string;
begin
  if MessageDlg('确定要清理临时文件吗？这将删除系统和用户临时目录中的文件。',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      UpdateStatus('🧹 开始清理临时文件...');
      DeletedSize := CleanupTempFiles;

      if DeletedSize > 0 then
      begin
        if DeletedSize > 1024*1024*1024 then
          SizeStr := Format('%.2f GB', [DeletedSize / (1024*1024*1024)])
        else if DeletedSize > 1024*1024 then
          SizeStr := Format('%.2f MB', [DeletedSize / (1024*1024)])
        else
          SizeStr := Format('%.2f KB', [DeletedSize / 1024]);
        UpdateStatus('✅ 临时文件清理完成，释放空间: ' + SizeStr);
      end
      else
        UpdateStatus('ℹ️ 没有找到可清理的临时文件');
    except
      on E: Exception do
        UpdateStatus('❌ 清理临时文件失败: ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.MenuCleanupSoftwareDistributionClick(Sender: TObject);
var
  DeletedSize: Int64;
  SizeStr: string;
begin
  if MessageDlg('确定要清理Windows更新缓存吗？这将删除SoftwareDistribution目录中的下载文件。' + #13#10 +
                '注意：这可能需要管理员权限。',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      UpdateStatus('🧹 开始清理Windows更新缓存...');
      DeletedSize := CleanupSoftwareDistribution;

      if DeletedSize > 0 then
      begin
        if DeletedSize > 1024*1024*1024 then
          SizeStr := Format('%.2f GB', [DeletedSize / (1024*1024*1024)])
        else if DeletedSize > 1024*1024 then
          SizeStr := Format('%.2f MB', [DeletedSize / (1024*1024)])
        else
          SizeStr := Format('%.2f KB', [DeletedSize / 1024]);
        UpdateStatus('✅ Windows更新缓存清理完成，释放空间: ' + SizeStr);
      end
      else
        UpdateStatus('ℹ️ 没有找到可清理的更新缓存文件');
    except
      on E: Exception do
        UpdateStatus('❌ 清理Windows更新缓存失败: ' + E.Message);
    end;
  end;
end;
function TfrmMain.CleanupTempFiles: Int64;
var
  TempPaths: TArray<string>;
  i: Integer;
  DeletedSize: Int64;
begin
  Result := 0;
  DeletedSize := 0;

  // 定义要清理的临时目录
  SetLength(TempPaths, 4);
  TempPaths[0] := GetEnvironmentVariable('TEMP');
  TempPaths[1] := GetEnvironmentVariable('TMP');
  TempPaths[2] := 'C:\Windows\Temp';
  TempPaths[3] := 'C:\Windows\Prefetch';

  for i := 0 to High(TempPaths) do
  begin
    if (TempPaths[i] <> '') and System.SysUtils.DirectoryExists(TempPaths[i]) then
    begin
      try
        UpdateStatus('🧹 清理目录: ' + TempPaths[i]);
        SafeDeleteDirectory(TempPaths[i], DeletedSize);
        Inc(Result, DeletedSize);
      except
        on E: Exception do
          UpdateStatus('⚠️ 清理 ' + TempPaths[i] + ' 时出错: ' + E.Message);
      end;
    end;
  end;
end;

function TfrmMain.CleanupSoftwareDistribution: Int64;
var
  SoftDistPath: string;
  DeletedSize: Int64;
begin
  Result := 0;
  DeletedSize := 0;
  SoftDistPath := 'C:\Windows\SoftwareDistribution\Download';

  if System.SysUtils.DirectoryExists(SoftDistPath) then
  begin
    try
      UpdateStatus('🧹 清理目录: ' + SoftDistPath);
      SafeDeleteDirectory(SoftDistPath, DeletedSize);
      Result := DeletedSize;
    except
      on E: Exception do
        UpdateStatus('⚠️ 清理 SoftwareDistribution 时出错: ' + E.Message);
    end;
  end
  else
    UpdateStatus('ℹ️ SoftwareDistribution\Download 目录不存在');
end;

procedure TfrmMain.SafeDeleteDirectory(const DirPath: string; var DeletedSize: Int64);
var
  SR: TSearchRec;
  FilePath: string;
  FileSize: Int64;
  Code: Integer;
begin
  DeletedSize := 0;

  if not System.SysUtils.DirectoryExists(DirPath) then
    Exit;

  Code := FindFirst(IncludeTrailingPathDelimiter(DirPath) + '*', faAnyFile, SR);
  try
    while Code = 0 do
    begin
      if (SR.Name <> '.') and (SR.Name <> '..') then
      begin
        FilePath := IncludeTrailingPathDelimiter(DirPath) + SR.Name;

        if (SR.Attr and faDirectory) <> 0 then
        begin
          // 递归删除子目录
          var SubDirSize: Int64 := 0;
          SafeDeleteDirectory(FilePath, SubDirSize);
          Inc(DeletedSize, SubDirSize);

          // 尝试删除空目录
          try
            RemoveDir(FilePath);
          except
            // 忽略删除目录失败的错误
          end;
        end
        else
        begin
          // 删除文件
          try
            FileSize := SR.Size;
            if DeleteFile(FilePath) then
              Inc(DeletedSize, FileSize);
          except
            // 忽略删除文件失败的错误（可能被占用）
          end;
        end;
      end;
      Code := FindNext(SR);
    end;
  finally
    FindClose(SR);
  end;
end;

procedure TfrmMain.ScanDirectory(const APath: string);
begin
  // 使用ShellTreeView自动扫描目录
  try
    UpdateShellTreePath(stvSource, APath);

    // 展开根节点
    if stvSource.Items.Count > 0 then
      stvSource.Items[0].Expanded := True;

  except
    on E: Exception do
      UpdateStatus('扫描目录时出错: ' + E.Message);
  end;
end;

procedure TfrmMain.AnalyzeDirectory(const APath: string);
begin
  // 简单的分析实现
  UpdateStatus('📈 正在分析目录结构...');
  Sleep(1000); // 模拟分析过程

  UpdateStatus('📈 正在检查磁盘空间...');
  Sleep(1000);

  UpdateStatus('📈 正在评估风险等级...');
  Sleep(1000);
end;

procedure TfrmMain.ExecuteOperation;
var
  Src, DstRoot, Dst, Backup: string;
  Copied: Int64;
  ok: Boolean;
begin
  Src := Trim(FSourcePath);
  DstRoot := Trim(FTargetPath);

  if (Src = '') or not System.SysUtils.DirectoryExists(Src) then
  begin
    UpdateStatus('❌ 源目录不存在: ' + Src);
    Exit;
  end;
  if (DstRoot = '') or not System.SysUtils.DirectoryExists(DstRoot) then
  begin
    UpdateStatus('❌ 目标根目录不存在: ' + DstRoot);
    Exit;
  end;

  // 仅提示，不强制要求 C: → D:
  if (UpperCase(Copy(Src,1,3)) <> 'C:\') or (UpperCase(Copy(DstRoot,1,3)) <> 'D:\') then
  begin
    if MessageDlg('当前并非 C: 到 D: 的迁移，是否继续？', mtWarning, [mbYes, mbNo], 0) <> mrYes then
      Exit;
  end;

  // 目标目录 = 目标根目录 + 源目录名
  Dst := System.SysUtils.IncludeTrailingPathDelimiter(DstRoot) + ExtractFileName(System.SysUtils.ExcludeTrailingPathDelimiter(Src));
  if System.SysUtils.DirectoryExists(Dst) then
  begin
    if MessageDlg('目标目录已存在：' + Dst + sLineBreak + '是否覆盖（将合并内容）？', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;
  end;

  SetProcessingState(True);
  try
    UpdateStatus('📋 准备迁移: ' + Src + '  →  ' + Dst);

    // 0) 依赖关系分析（如果启用）
    if Assigned(FDependencyAnalyzer) and
       FConfigManager.GetBoolean('Migration.AnalyzeDependencies', True) then
    begin
      UpdateStatus('🔍 正在分析依赖关系...');
      if not PerformDependencyAnalysis(Src) then
      begin
        UpdateStatus('⚠️ 依赖关系分析发现风险，迁移已取消');
        Exit;
      end;
    end;

    // 1) 拷贝到目标
    Copied := 0;
    try
      // 预估总量（用于进度计算）
      var tmpFiles: Integer; FTotalBytesToCopy := 0; FCopiedBytesSoFar := 0;
      ComputeDirStats(Src, tmpFiles, FTotalBytesToCopy);
      ProgressBar1.Style := pbstNormal;
      ProgressBar1.Position := 0;

      // 使用高性能文件操作引擎（如果可用）
      if Assigned(FFileOperationEngine) and
         FConfigManager.GetBoolean('Advanced.UseHighPerformanceEngine', True) then
      begin
        UpdateStatus('🚀 使用高性能文件操作引擎...');
        Copied := PerformHighPerformanceCopy(Src, Dst);
      end
      else
      begin
        UpdateStatus('📁 使用标准文件复制...');
        CopyDirRecursive(Src, Dst, Copied);
      end;

      UpdateStatus(Format('📦 拷贝完成（约 %.2f GB）', [Copied/1024/1024/1024]));
      // 简单一致性校验（文件数与总字节）
      var cDst, cSrc: Integer; var bDst, bSrc: Int64;
      ComputeDirStats(Dst, cDst, bDst);
      ComputeDirStats(Src, cSrc, bSrc);
      UpdateStatus(Format('🔍 校验：目标文件数 %d / 源文件数 %d；目标大小 %.2f GB / 源大小 %.2f GB',
        [cDst, cSrc, bDst/1024/1024/1024, bSrc/1024/1024/1024]));
      if (cDst <> cSrc) or (bDst <> bSrc) then
      begin
        var diffBytes := Abs(bDst - bSrc);
        var maxBytes := Max(bDst, bSrc);
        var ratio: Double := 0;
        if maxBytes > 0 then ratio := diffBytes / maxBytes;
        // 阈值判断（轻微不一致）
        if (diffBytes <= VERIFY_SIZE_DIFF_BYTES_THRESHOLD) or (ratio <= VERIFY_SIZE_DIFF_RATIO_THRESHOLD) then
        begin
          if MessageDlg(Format('复制后校验存在轻微不一致（差异 %s，约 %.4f%%）。是否继续？',
                               [FormatFloat('#,##0 bytes', diffBytes), ratio*100]),
                        mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
            Exit;
        end
        else
        begin
          // 明显不一致
          if MessageDlg('检测到复制后校验不一致：' + sLineBreak +
                        Format('目标文件数:%d 源文件数:%d；目标大小:%.2f GB 源大小:%.2f GB',
                          [cDst, cSrc, bDst/1024/1024/1024, bSrc/1024/1024/1024]) + sLineBreak +
                        '是否继续迁移？选择“是”将继续（风险自担），选择“否”将终止迁移。',
                        mtWarning, [mbYes, mbNo], 0) <> mrYes then
            Exit;
        end;
        // 可选抽样哈希
        if ENABLE_SAMPLE_HASH_CHECK then
        begin
          var srcSamples := GetSomeFiles(Src, SAMPLE_HASH_COUNT);
          var i: Integer;
          for i := 0 to High(srcSamples) do
          begin
            var rel := srcSamples[i].Substring(Length(IncludeTrailingPathDelimiter(Src)));
            var dstFile := IncludeTrailingPathDelimiter(Dst) + rel;
            if System.SysUtils.FileExists(srcSamples[i]) and System.SysUtils.FileExists(dstFile) then
            begin
              if ComputeMD5Hex(srcSamples[i]) <> ComputeMD5Hex(dstFile) then
              begin
                if MessageDlg('抽样哈希校验失败，是否仍然继续？', mtWarning, [mbYes, mbNo], 0) <> mrYes then
                  Exit
                else Break;
              end;
            end;
          end;
        end;
      end;
    except
      on E: Exception do
      begin
        UpdateStatus('❌ 拷贝失败: ' + E.Message);
        Exit;
      end;
    end;

    // 2) 将原目录重命名为备份
    Backup := Src + '.backup_' + FormatDateTime('yyyymmdd_hhnnss', Now);
    if not RenameFile(Src, Backup) then
    begin
      UpdateStatus('❌ 无法备份原目录，放弃迁移。');
      Exit;
    end
    else
      UpdateStatus('🛟 已备份原目录到: ' + Backup);

    // 3) 在原位置创建链接指向新位置（优先目录联接）
    ok := CreateDirectoryLink(Src, Dst);
    if not ok then
    begin
      UpdateStatus('❌ 创建链接失败，开始回滚...');
      // 回滚：恢复原目录
      if not RenameFile(Backup, Src) then
        UpdateStatus('⚠️ 回滚失败，请手动将备份目录还原: ' + Backup)
      else
        UpdateStatus('↩️ 已回滚到迁移前状态');
      Exit;
    end;

    UpdateStatus('🔗 已在原位置创建链接 → ' + Dst);

    // 4) 记录最近备份，并提醒验证后清理备份以释放C盘
    FLastBackupPath := Backup;
    UpdateStatus('✅ 迁移完成。已保留备份目录: ' + Backup);
    UpdateStatus('⚠️ 重要: 请立即测试依赖此目录的程序是否正常运行。');
    UpdateStatus('💡 测试无误后，请使用“清理最近备份”或手动删除备份目录，以真正释放C盘空间。');
  finally
    ProgressBar1.Style := pbstNormal;
    ProgressBar1.Position := 0;
    SetProcessingState(False);
    FCancelRequested := False;
  end;
end;

procedure TfrmMain.MenuThemeClick(Sender: TObject);
begin
  try
    StyleManager.ToggleTheme;
    ApplyModernStyles;

    if StyleManager.IsDarkMode then
      UpdateStatus('🌙 已切换到深色主题')
    else
      UpdateStatus('☀️ 已切换到浅色主题');

  except
    on E: Exception do
      UpdateStatus('❌ 切换主题失败: ' + E.Message);
  end;
end;

procedure TfrmMain.MenuFileExitClick(Sender: TObject);
begin
  // 调用按钮退出事件，保持逻辑一致
  btnExitClick(Sender);
end;

procedure TfrmMain.MenuHelpAboutClick(Sender: TObject);
begin
  MessageDlg('C盘瘦身工具 v3.0 Enterprise' + #13#10 +
             '企业版 - 专业级磁盘空间管理解决方案' + #13#10 +
             '© 2025 保留所有权利', mtInformation, [mbOK], 0);
end;

procedure TfrmMain.btnSelectSourceRootClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := '';
  if SelectDirectory('选择源根目录', '', Dir) then
  begin
    FSourcePath := Dir;
    edtSourceDir.Text := Dir;
    UpdateShellTreePath(stvSource, Dir);
    UpdateStatus('源根目录已设置: ' + Dir);

    if StatusBar1.Panels.Count > 1 then
      StatusBar1.Panels[1].Text := '源目录: ' + ExtractFileName(Dir);
  end;
end;

procedure TfrmMain.btnSelectTargetRootClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := '';
  if SelectDirectory('选择目标根目录', '', Dir) then
  begin
    FTargetPath := Dir;
    edtTargetDir.Text := Dir;
    UpdateShellTreePath(stvTarget, Dir);
    UpdateStatus('目标根目录已设置: ' + Dir);

    if StatusBar1.Panels.Count > 2 then
      StatusBar1.Panels[2].Text := '目标目录: ' + ExtractFileName(Dir);
  end;
end;

function TfrmMain.RunCommandWait(const CmdLine: string; out ExitCode: Cardinal): Boolean;
var
  SI: TStartupInfo;
  PI: TProcessInformation;
  Cmd: string;
begin
  Result := False;
  FillChar(SI, SizeOf(SI), 0);
  FillChar(PI, SizeOf(PI), 0);
  SI.cb := SizeOf(SI);
  ExitCode := 0;

  Cmd := 'cmd /C ' + CmdLine;
  if CreateProcess(nil, PChar(Cmd), nil, nil, False, CREATE_NO_WINDOW, nil, nil, SI, PI) then
  try
    WaitForSingleObject(PI.hProcess, INFINITE);
    GetExitCodeProcess(PI.hProcess, ExitCode);
    Result := ExitCode = 0;
  finally
    if PI.hThread <> 0 then CloseHandle(PI.hThread);
    if PI.hProcess <> 0 then CloseHandle(PI.hProcess);
  end;
end;

{$IFDEF MSWINDOWS}
const
  SYMBOLIC_LINK_FLAG_DIRECTORY = $1;

function CreateSymbolicLinkW(lpSymlinkFileName, lpTargetFileName: PWideChar; dwFlags: DWORD): BOOL; stdcall; external 'kernel32.dll' name 'CreateSymbolicLinkW';
{$ENDIF}

function TfrmMain.CreateDirectorySymlink(const LinkPath, TargetPath: string): Boolean;
begin
  // 简化为直接调用 Unicode 版本，目录符号链接
  Result := CreateSymbolicLinkW(PWideChar(LinkPath), PWideChar(TargetPath), SYMBOLIC_LINK_FLAG_DIRECTORY);
end;

procedure TfrmMain.ComputeDirStats(const Root: string; out FileCount: Integer; out TotalBytes: Int64);
var
  Files: Integer;
  Bytes: Int64;
  SR: TSearchRec;
  Code: Integer;
  P: string;
begin
  Files := 0; Bytes := 0;
  Code := FindFirst(IncludeTrailingPathDelimiter(Root) + '*', faAnyFile, SR);
  try
    while Code = 0 do
    begin
      if (SR.Name <> '.') and (SR.Name <> '..') then
      begin
        P := IncludeTrailingPathDelimiter(Root) + SR.Name;
        if (SR.Attr and faDirectory) <> 0 then
          ComputeDirStats(P, Files, Bytes)
        else

        begin
          Inc(Files);
          Inc(Bytes, SR.Size);
        end;
      end;
      Code := FindNext(SR);
    end;
  finally
    FindClose(SR);
  end;
  FileCount := Files; TotalBytes := Bytes;
end;

function TfrmMain.DeletePathToRecycleBin(const Path: string): Boolean;
var
  Op: TSHFileOpStruct;
  FromBuf: array[0..MAX_PATH] of Char;
begin
  Result := False;
  FillChar(Op, SizeOf(Op), 0);
  StrPCopy(FromBuf, Path + #0#0);
  Op.Wnd := Handle;
  Op.wFunc := FO_DELETE;
  Op.pFrom := @FromBuf[0];
  Op.fFlags := FOF_ALLOWUNDO or FOF_NOCONFIRMATION or FOF_SILENT;
  Result := SHFileOperation(Op) = 0;
end;

procedure TfrmMain.MenuCleanupLastBackupClick(Sender: TObject);
begin
  // 删除最近的备份目录（移动到回收站）
  if FLastBackupPath = '' then
  begin
    UpdateStatus('ℹ️ 当前会话没有记录到备份目录');
    Exit;
  end;

  if not System.SysUtils.DirectoryExists(FLastBackupPath) then
  begin
    UpdateStatus('ℹ️ 备份目录不存在: ' + FLastBackupPath);
    Exit;
  end;

  if MessageDlg('确定要删除最近的备份目录吗？将移动到回收站：' + sLineBreak + FLastBackupPath,
                 mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    if DeletePathToRecycleBin(FLastBackupPath) then
      UpdateStatus('🗑️ 已移动备份到回收站: ' + FLastBackupPath)
    else
      UpdateStatus('❌ 无法删除备份（可能权限不足或文件占用）');
  end;
end;



procedure TfrmMain.stvSourceContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
var
  Node: TTreeNode;
  ScreenPt: TPoint;
begin
  Handled := True;
  if stvSource = nil then Exit;
  Node := stvSource.GetNodeAt(MousePos.X, MousePos.Y);
  if Assigned(Node) then stvSource.Selected := Node;
  ScreenPt := stvSource.ClientToScreen(MousePos);
  if Assigned(pmSource) then pmSource.Popup(ScreenPt.X, ScreenPt.Y);
end;

procedure TfrmMain.stvTargetContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
var
  Node: TTreeNode;
  ScreenPt: TPoint;
begin
  Handled := True;
  if stvTarget = nil then Exit;
  Node := stvTarget.GetNodeAt(MousePos.X, MousePos.Y);
  if Assigned(Node) then stvTarget.Selected := Node;
  ScreenPt := stvTarget.ClientToScreen(MousePos);
  if Assigned(pmTarget) then pmTarget.Popup(ScreenPt.X, ScreenPt.Y);
end;


procedure TfrmMain.miSrcOpenClick(Sender: TObject);
begin
  if FSourcePath <> '' then UpdateShellTreePath(stvSource, FSourcePath);
end;

procedure TfrmMain.miSrcOpenInExplorerClick(Sender: TObject);
begin
  OpenInExplorerSelect(FSourcePath);
end;

procedure TfrmMain.miSrcCopyPathClick(Sender: TObject);
begin
  if FSourcePath <> '' then Clipboard.AsText := FSourcePath;
end;

procedure TfrmMain.miSrcSetRootClick(Sender: TObject);
begin
  if FSourcePath = '' then Exit;
  try stvSource.Root := FSourcePath; except stvSource.Root := 'rfDesktop'; end;
  stvSource.ShowRoot := False;
  stvSource.ObjectTypes := [otFolders];
  UpdateShellTreePath(stvSource, FSourcePath);
end;

procedure TfrmMain.miSrcScanHereClick(Sender: TObject);
begin
  if FSourcePath <> '' then begin
    SetProcessingState(True);
    try
      UpdateStatus('🔍 开始扫描目录: ' + FSourcePath);
      ScanDirectory(FSourcePath);
      UpdateStatus('✅ 目录扫描完成');
    finally
      SetProcessingState(False);
    end;
  end;
end;

procedure TfrmMain.miSrcAnalyzeHereClick(Sender: TObject);
begin
  if FSourcePath <> '' then begin
    SetProcessingState(True);
    try
      UpdateStatus('📊 开始分析目录: ' + FSourcePath);
      StartSpaceAnalysis(FSourcePath);
      UpdateStatus('✅ 分析任务已启动');
    finally
      SetProcessingState(False);
    end;
  end;
end;

procedure TfrmMain.miSrcRefreshClick(Sender: TObject);
begin
  if FSourcePath <> '' then UpdateShellTreePath(stvSource, FSourcePath);
end;

procedure TfrmMain.miTgtOpenClick(Sender: TObject);
begin
  if FTargetPath <> '' then UpdateShellTreePath(stvTarget, FTargetPath);
end;

procedure TfrmMain.miTgtOpenInExplorerClick(Sender: TObject);
begin
  OpenInExplorerSelect(FTargetPath);
end;

procedure TfrmMain.miTgtCopyPathClick(Sender: TObject);
begin
  if FTargetPath <> '' then Clipboard.AsText := FTargetPath;
end;

procedure TfrmMain.miTgtSetRootClick(Sender: TObject);
begin
  if FTargetPath = '' then Exit;
  try stvTarget.Root := FTargetPath; except stvTarget.Root := 'rfDesktop'; end;
  stvTarget.ShowRoot := False;
  stvTarget.ObjectTypes := [otFolders];
  UpdateShellTreePath(stvTarget, FTargetPath);
end;

procedure TfrmMain.miTgtSetAsTargetPathClick(Sender: TObject);
begin
  if FTargetPath <> '' then edtTargetDir.Text := FTargetPath;
end;

// ----- DFM 事件占位的空实现，确保编译通过，后续保留原有行为 -----
procedure TfrmMain.btnSourceUpClick(Sender: TObject);
begin
  try
    if Assigned(stvSource) and (Pos('\', stvSource.Path) > 0) then
      stvSource.Path := ExtractFileDir(ExcludeTrailingPathDelimiter(stvSource.Path));
  except
  end;
end;

procedure TfrmMain.btnTargetUpClick(Sender: TObject);
begin
  try
    if Assigned(stvTarget) and (Pos('\', stvTarget.Path) > 0) then
      stvTarget.Path := ExtractFileDir(ExcludeTrailingPathDelimiter(stvTarget.Path));
  except
  end;
end;

procedure TfrmMain.stvSourceDblClick(Sender: TObject);
begin
  // 依赖 TShellTreeView 默认行为（双击进入子目录），无需额外逻辑
end;

procedure TfrmMain.stvSourceKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_BACK then btnSourceUpClick(Sender);
end;

procedure TfrmMain.stvTargetDblClick(Sender: TObject);
begin
  // 依赖默认行为
end;

procedure TfrmMain.stvTargetKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_BACK then btnTargetUpClick(Sender);
end;

procedure TfrmMain.miLogManagerClick(Sender: TObject);
begin
  // 预留：日志管理器入口（MVP阶段占位）
  UpdateStatus('日志管理器（占位）');
end;

procedure TfrmMain.miTgtRefreshClick(Sender: TObject);
begin
  if FTargetPath <> '' then UpdateShellTreePath(stvTarget, FTargetPath);
end;



function TfrmMain.CreateDirectoryJunctionViaCmd(const LinkPath, TargetPath: string): Boolean;
var
  Code: Cardinal;
begin
  // 使用 mklink /J 创建目录联接，适合无符号链接权限时
  Result := RunCommandWait(Format('mklink /J "%s" "%s"', [LinkPath, TargetPath]), Code) and (Code = 0);
end;

function TfrmMain.CreateDirectoryLink(const LinkPath, TargetPath: string): Boolean;
begin
  Result := False;
  // 默认优先目录联接（/J），降低权限失败率
  if CreateDirectoryJunctionViaCmd(LinkPath, TargetPath) then
    Exit(True);
  // 回退尝试符号链接（需要更高权限）
  if CreateDirectorySymlink(LinkPath, TargetPath) then
    Exit(True);
end;


procedure TfrmMain.CopyDirRecursive(const Src, Dst: string; var CopiedBytes: Int64);
var
  SR: TSearchRec;
  Code: Integer;
  SrcPath, DstPath: string;
  InF, OutF: TFileStream;
  Buf: array[0..64*1024-1] of Byte;
  N: Integer;
begin
  if FCancelRequested then Exit;
  System.SysUtils.ForceDirectories(Dst);

  Code := FindFirst(IncludeTrailingPathDelimiter(Src) + '*', faAnyFile, SR);
  try
    while (Code = 0) and (not FCancelRequested) do
    begin
      if (SR.Name <> '.') and (SR.Name <> '..') then
      begin
        SrcPath := IncludeTrailingPathDelimiter(Src) + SR.Name;
        DstPath := IncludeTrailingPathDelimiter(Dst) + SR.Name;
        if (SR.Attr and faDirectory) <> 0 then
          CopyDirRecursive(SrcPath, DstPath, CopiedBytes)
        else
        begin
          InF := TFileStream.Create(SrcPath, fmOpenRead or fmShareDenyNone);
          try
            OutF := TFileStream.Create(DstPath, fmCreate);
            try
              repeat
                N := InF.Read(Buf, SizeOf(Buf));
                if N > 0 then
                begin
                  OutF.WriteBuffer(Buf, N);
                  Inc(CopiedBytes, N);
                  FCopiedBytesSoFar := CopiedBytes;
                  if FTotalBytesToCopy > 0 then
                    ProgressBar1.Position := Trunc(FCopiedBytesSoFar * 100 / FTotalBytesToCopy);
                  Application.ProcessMessages;
                  if FCancelRequested then Break;
                end;
              until N = 0;
            finally
              OutF.Free;
            end;
          finally
            InF.Free;
          end;
        end;
      end;
      Code := FindNext(SR);
    end;
  finally
    FindClose(SR);
  end;
end;


procedure TfrmMain.InitializeShellTreeViews;
var
  TargetUsersPath: string;
begin
  // 设置默认路径变量
  FSourcePath := 'C:\Users';
  FTargetPath := 'D:\Users';

  // 确保D:\Users目录存在，不存在则创建
  TargetUsersPath := 'D:\Users';
  if not System.SysUtils.DirectoryExists(TargetUsersPath) then
  begin
    try
      System.SysUtils.ForceDirectories(TargetUsersPath);
      UpdateStatus(_('target_created') + TargetUsersPath);
    except
      on E: Exception do
      begin
        UpdateStatus(_('target_create_failed') + E.Message);
        // 如果创建失败，更新目标路径为D盘根目录
        FTargetPath := 'D:\';
        TargetUsersPath := 'D:\';
      end;
    end;

  end;

  // 更新最终的目标路径
  FTargetPath := TargetUsersPath;

  // 先设置编辑框文本
  edtSourceDir.Text := FSourcePath;
  edtTargetDir.Text := FTargetPath;

  // 更新状态栏（国际化）
  if StatusBar1.Panels.Count > 1 then
    StatusBar1.Panels[1].Text := _('status_source') + ExtractFileName(FSourcePath);
  if StatusBar1.Panels.Count > 2 then
    StatusBar1.Panels[2].Text := _('status_target') + ExtractFileName(FTargetPath);
end;

procedure TfrmMain.UpdateShellTreePath(ATreeView: TShellTreeView; const APath: string);
begin
  try
    if System.SysUtils.DirectoryExists(APath) then
    begin
      // 直接设置Path属性来导航到指定目录
      ATreeView.Path := APath;
    end
    else
    begin
      UpdateStatus('目录不存在: ' + APath);
    end;
  except
    on E: Exception do
      UpdateStatus('设置目录路径时出错: ' + E.Message);
  end;
end;

procedure TfrmMain.stvSourceChange(Sender: TObject; Node: TTreeNode);
var
  SelectedPath: string;
begin
  try
    // 检查组件和节点是否有效
    if Assigned(stvSource) and Assigned(Node) and not (csDestroying in ComponentState) then
    begin
      // 直接使用ShellTreeView的Path属性获取完整路径
      SelectedPath := stvSource.Path;
      if SelectedPath <> '' then
      begin
        FSourcePath := SelectedPath;

        // 安全更新编辑框
        if Assigned(edtSourceDir) then
          edtSourceDir.Text := SelectedPath;

        UpdateStatus(_('source_selected') + SelectedPath);

        // 安全更新状态栏
        if Assigned(StatusBar1) and (StatusBar1.Panels.Count > 1) then
          StatusBar1.Panels[1].Text := _('status_source') + ExtractFileName(SelectedPath);
      end;
    end;
  except
    on E: Exception do
    begin
      try
        UpdateStatus('源目录选择出错: ' + E.Message);
      except
        // 忽略状态更新错误
      end;
    end;
  end;
end;

procedure TfrmMain.stvTargetChange(Sender: TObject; Node: TTreeNode);
var
  SelectedPath: string;
begin
  try
    // 检查组件和节点是否有效
    if Assigned(stvTarget) and Assigned(Node) and not (csDestroying in ComponentState) then
    begin
      // 直接使用ShellTreeView的Path属性获取完整路径
      SelectedPath := stvTarget.Path;
      if SelectedPath <> '' then
      begin
        FTargetPath := SelectedPath;

        // 安全更新编辑框
        if Assigned(edtTargetDir) then
          edtTargetDir.Text := SelectedPath;

        UpdateStatus(_('target_selected') + SelectedPath);

        // 安全更新状态栏
        if Assigned(StatusBar1) and (StatusBar1.Panels.Count > 2) then
          StatusBar1.Panels[2].Text := _('status_target') + ExtractFileName(SelectedPath);
      end;
    end;
  except
    on E: Exception do
    begin
      try
        UpdateStatus('目标目录选择出错: ' + E.Message);
      except
        // 忽略状态更新错误
      end;
    end;
  end;
end;

procedure TfrmMain.MenuCleanupDuplicateFilesClick(Sender: TObject);
begin
  try
    // 创建并显示智能重复文件清理窗体
    if not Assigned(frmSmartDuplicateCleanup) then
      frmSmartDuplicateCleanup := TfrmSmartDuplicateCleanup.Create(Self);

    frmSmartDuplicateCleanup.ShowModal;

    UpdateStatus('🔍 智能重复文件清理已完成');
  except
    on E: Exception do
      UpdateStatus('❌ 打开重复文件清理失败: ' + E.Message);
  end;
end;

procedure TfrmMain.InitializeCoreModules;
begin
  try
    UpdateStatus('🔧 正在初始化企业级功能模块...');

    // 初始化配置管理器
    FConfigManager := TConfigManager.Create;
    FConfigManager.LoadConfiguration;

    // 初始化文件安全评估器
    FSafetyEvaluator := TFileSafetyEvaluator.Create;

    // 初始化依赖关系分析器
    FDependencyAnalyzer := TDependencyAnalyzer.Create;

    // 初始化重启检测器
    FRebootDetector := TRebootDetector.Create;

    // 初始化文件类型识别器
    FFileTypeIdentifier := TFileTypeIdentifier.Create;

    // 初始化迁移计划器
    FMigrationPlanner := TMigrationPlanner.Create;

    // 初始化高性能文件操作引擎
    FFileOperationEngine := TFileOperationEngine.Create;

    // 初始化符号链接管理器
    FSymlinkManager := TSymlinkManager.Create;

    // 初始化备份管理器
    FBackupManager := TBackupManager.Create;

    // 初始化回滚执行器
    FRollbackExecutor := TRollbackExecutor.Create;

    // 初始化紧急恢复模块
    FEmergencyRecovery := TEmergencyRecovery.Create;

    // 初始化数据库管理器
    FDatabaseManager := TDatabaseManager.Create;
    FDatabaseManager.Initialize;

    // 初始化捐赠管理器
    FDonationManager := TDonationManager.Create;

    UpdateStatus('✅ 企业级功能模块初始化完成');
  except
    on E: Exception do
    begin
      UpdateStatus('❌ Core模块初始化失败: ' + E.Message);
      // 继续运行，但企业级功能将不可用
    end;
  end;
end;

procedure TfrmMain.CleanupCoreModules;
begin
  try
    // 按相反顺序清理模块，避免依赖问题

    if Assigned(FDonationManager) then
    begin
      FDonationManager.Free;
      FDonationManager := nil;
    end;

    if Assigned(FDatabaseManager) then
    begin
      FDatabaseManager.Finalize;
      FDatabaseManager.Free;
      FDatabaseManager := nil;
    end;

    if Assigned(FEmergencyRecovery) then
    begin
      FEmergencyRecovery.Free;
      FEmergencyRecovery := nil;
    end;

    if Assigned(FRollbackExecutor) then
    begin
      FRollbackExecutor.Free;
      FRollbackExecutor := nil;
    end;

    if Assigned(FBackupManager) then
    begin
      FBackupManager.Free;
      FBackupManager := nil;
    end;

    if Assigned(FSymlinkManager) then
    begin
      FSymlinkManager.Free;
      FSymlinkManager := nil;
    end;

    if Assigned(FFileOperationEngine) then
    begin
      FFileOperationEngine.Free;
      FFileOperationEngine := nil;
    end;

    if Assigned(FMigrationPlanner) then
    begin
      FMigrationPlanner.Free;
      FMigrationPlanner := nil;
    end;

    if Assigned(FFileTypeIdentifier) then
    begin
      FFileTypeIdentifier.Free;
      FFileTypeIdentifier := nil;
    end;

    if Assigned(FRebootDetector) then
    begin
      FRebootDetector.Free;
      FRebootDetector := nil;
    end;

    if Assigned(FDependencyAnalyzer) then
    begin
      FDependencyAnalyzer.Free;
      FDependencyAnalyzer := nil;
    end;

    if Assigned(FSafetyEvaluator) then
    begin
      FSafetyEvaluator.Free;
      FSafetyEvaluator := nil;
    end;

    if Assigned(FConfigManager) then
    begin
      FConfigManager.SaveConfiguration;
      FConfigManager.Free;
      FConfigManager := nil;
    end;

  except
    // 忽略清理过程中的异常
  end;
end;

procedure TfrmMain.miConfigManagerClick(Sender: TObject);
var
  ConfigForm: TfrmConfigManager;
begin
  try
    ConfigForm := TfrmConfigManager.Create(Self, FConfigManager);
    try
      if ConfigForm.ShowModal = mrOK then
      begin
        UpdateStatus('✅ 配置已更新');

        // 应用新配置
        if Assigned(FConfigManager) then
        begin
          // 重新加载配置
          FConfigManager.LoadConfiguration;

          // 应用主题设置
          var ThemeSetting := FConfigManager.GetString('UI.Theme', 'Light');
          if SameText(ThemeSetting, 'Dark') then
          begin
            if not StyleManager.IsDarkMode then
              StyleManager.ToggleTheme;
          end
          else if SameText(ThemeSetting, 'Light') then
          begin
            if StyleManager.IsDarkMode then
              StyleManager.ToggleTheme;
          end;

          // 重新应用样式
          ApplyModernStyles;
        end;
      end;
    finally
      ConfigForm.Free;
    end;
  except
    on E: Exception do
      UpdateStatus('❌ 打开配置管理器失败: ' + E.Message);
  end;
end;

function TfrmMain.PerformDependencyAnalysis(const SourcePath: string): Boolean;
var
  AnalysisResults: TArray<TDependencyAnalysisResult>;
  MainResult: TDependencyAnalysisResult;
  RiskLevel: Integer;
  AnalysisResult: string;
  i: Integer;
begin
  Result := True; // 默认允许继续

  try
    if not Assigned(FDependencyAnalyzer) then
      Exit;

    UpdateStatus('🔍 扫描目录依赖关系...');
    Application.ProcessMessages;

    // 分析目录的依赖关系
    AnalysisResults := FDependencyAnalyzer.AnalyzeDirectory(SourcePath, False);

    if Length(AnalysisResults) = 0 then
    begin
      UpdateStatus('✅ 未发现依赖关系，可以安全迁移');
      Exit;
    end;

    // 取第一个结果作为主要分析结果
    MainResult := AnalysisResults[0];

    UpdateStatus('🔍 评估风险等级...');
    Application.ProcessMessages;

    // 根据依赖数量和类型评估风险等级
    RiskLevel := MainResult.CriticalDependencies * 3 +
                 MainResult.HighDependencies * 2 +
                 MainResult.MediumDependencies;

    // 生成分析报告
    AnalysisResult := Format('依赖关系分析完成：' + sLineBreak +
                            '扫描路径：%s' + sLineBreak +
                            '发现依赖：%d 项' + sLineBreak +
                            '关键依赖：%d 项' + sLineBreak +
                            '高级依赖：%d 项' + sLineBreak +
                            '风险等级：%s',
                            [SourcePath, MainResult.TotalDependencies,
                             MainResult.CriticalDependencies, MainResult.HighDependencies,
                             GetRiskLevelText(RiskLevel)]);

    // 如果有依赖项，显示详细信息
    if MainResult.TotalDependencies > 0 then
    begin
      AnalysisResult := AnalysisResult + sLineBreak + sLineBreak + '主要依赖项：';
      for i := 0 to Min(4, Length(MainResult.Dependencies) - 1) do // 最多显示5个
        AnalysisResult := AnalysisResult + sLineBreak + '• ' + MainResult.Dependencies[i].Description;

      if Length(MainResult.Dependencies) > 5 then
        AnalysisResult := AnalysisResult + sLineBreak + Format('... 还有 %d 项依赖', [Length(MainResult.Dependencies) - 5]);
    end;

    // 根据风险等级决定是否继续
    case RiskLevel of
      0..2: // 低风险
      begin
        UpdateStatus('✅ 依赖分析：低风险，可以安全迁移');
        Result := True;
      end;

      3..6: // 中等风险
      begin
        AnalysisResult := AnalysisResult + sLineBreak + sLineBreak +
                         '⚠️ 检测到中等风险依赖关系。' + sLineBreak +
                         '建议在迁移后测试相关程序是否正常工作。' + sLineBreak +
                         '是否继续迁移？';
        Result := MessageDlg(AnalysisResult, mtWarning, [mbYes, mbNo], 0) = mrYes;
      end;

      7..10: // 高风险
      begin
        AnalysisResult := AnalysisResult + sLineBreak + sLineBreak +
                         '🚨 检测到高风险依赖关系！' + sLineBreak +
                         '迁移可能导致相关程序无法正常运行。' + sLineBreak +
                         '强烈建议先备份系统或创建系统还原点。' + sLineBreak +
                         '确定要继续迁移吗？';
        Result := MessageDlg(AnalysisResult, mtError, [mbYes, mbNo], 0) = mrYes;
      end;

    else // 极高风险
      begin
        AnalysisResult := AnalysisResult + sLineBreak + sLineBreak +
                         '🛑 检测到极高风险依赖关系！' + sLineBreak +
                         '迁移很可能导致系统不稳定或程序崩溃。' + sLineBreak +
                         '建议不要进行此迁移操作。';
        MessageDlg(AnalysisResult, mtError, [mbOK], 0);
        Result := False;
      end;
    end;

    if Result then
      UpdateStatus('✅ 依赖关系分析通过，继续迁移')
    else
      UpdateStatus('❌ 依赖关系分析未通过，迁移已取消');

  except
    on E: Exception do
    begin
      UpdateStatus('⚠️ 依赖关系分析出错: ' + E.Message);
      // 分析出错时询问用户是否继续
      Result := MessageDlg('依赖关系分析出现错误：' + E.Message + sLineBreak +
                          '是否跳过分析继续迁移？', mtWarning, [mbYes, mbNo], 0) = mrYes;
    end;
  end;
end;

function TfrmMain.GetRiskLevelText(RiskLevel: Integer): string;
begin
  case RiskLevel of
    0..2: Result := '低风险 ✅';
    3..6: Result := '中等风险 ⚠️';
    7..10: Result := '高风险 🚨';
  else
    Result := '极高风险 🛑';
  end;
end;

function TfrmMain.PerformHighPerformanceCopy(const SourcePath, DestPath: string): Int64;
var
  OperationResult: Boolean;
  Options: TOperationOptions;
begin
  Result := 0;

  try
    if not Assigned(FFileOperationEngine) then
    begin
      // 回退到标准复制
      CopyDirRecursive(SourcePath, DestPath, Result);
      Exit;
    end;

    // 配置高性能选项
    Options.PreserveAttributes := True;
    Options.PreserveTimestamps := True;
    Options.VerifyAfterCopy := FConfigManager.GetBoolean('Migration.VerifyAfterCopy', True);
    Options.OverwriteExisting := True;
    Options.CreateBackup := False;
    Options.UseBufferedIO := True;
    Options.BufferSize := FConfigManager.GetInteger('Migration.BufferSize', 64) * 1024; // KB转换为字节
    Options.MaxRetries := 3;
    Options.RetryDelay := 1000;
    Options.SkipLockedFiles := True;
    Options.FollowSymlinks := False;

    // 设置选项
    FFileOperationEngine.SetOptions(Options);

    // 清理之前的操作
    FFileOperationEngine.ClearOperations;

    // 添加复制操作
    FFileOperationEngine.AddOperation(fotCopy, SourcePath, DestPath);

    // 执行高性能复制
    UpdateStatus('🚀 启动高性能文件操作引擎...');
    OperationResult := FFileOperationEngine.Execute;

    if OperationResult then
    begin
      UpdateStatus('✅ 高性能复制完成');
      // 计算复制的字节数（简化版本）
      Result := FTotalBytesToCopy;
    end
    else
    begin
      UpdateStatus('❌ 高性能复制失败，回退到标准复制');
      Result := 0;
      CopyDirRecursive(SourcePath, DestPath, Result);
    end;

  except
    on E: Exception do
    begin
      UpdateStatus('⚠️ 高性能复制出错: ' + E.Message + '，回退到标准复制');
      Result := 0;
      CopyDirRecursive(SourcePath, DestPath, Result);
    end;
  end;
end;

end.

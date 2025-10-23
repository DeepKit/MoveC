unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI,
  System.SysUtils, System.Variants, System.Classes, System.AnsiStrings,
  System.Generics.Collections, System.Generics.Defaults, System.Threading, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Menus, Vcl.FileCtrl, Vcl.Clipbrd, Vcl.Buttons,
  System.IOUtils, System.UITypes,
  // Modern UI styles and strings
  uStyles, uStrings, uIconManager,
  // Security modules
  uSimpleSecureManager, FrameAboutMe, uAntiTamperPackage, uAntiDebug,
  // Cleanup manager
  uCleanupManager,
  // Migration transaction and file hasher
  uMigrationTransaction, uFileHasher,
  // System check utilities
  uSystemCheck;

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
    MenuTools: TMenuItem;
    miSimpleMode: TMenuItem;
    miConfigManager: TMenuItem;
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
    btnCleanRecycleBin: TBitBtn;
    btnCleanTemp: TBitBtn;
    btnCleanBackup: TBitBtn;
    btnCleanUpdate: TBitBtn;
    btnSmartClean: TBitBtn;
    btnSmartMigration: TBitBtn;
    btnAnalyze: TBitBtn;
    btnCalculateSize: TBitBtn;
    btnExecute: TBitBtn;
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
    procedure btnExecuteClick(Sender: TObject);
    procedure btnAnalyzeClick(Sender: TObject);
    procedure btnCalculateSizeClick(Sender: TObject);
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
    
    // 菜单事件
    procedure MenuFileExitClick(Sender: TObject);
    procedure MenuCleanupRecycleBinClick(Sender: TObject);
    procedure MenuCleanupTempClick(Sender: TObject);
    procedure MenuCleanupLastBackupClick(Sender: TObject);
    procedure MenuCleanupSoftwareDistributionClick(Sender: TObject);
    procedure MenuCleanupDuplicateFilesClick(Sender: TObject);
    procedure miConfigManagerClick(Sender: TObject);
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

    procedure InitializeInterface;
    procedure InitializeTreeViews;
    procedure UpdateTreeViewPath(ATreeView: TTreeView; const APath: string);
    procedure UpdateStatus(const AMessage: string);
    procedure LoadDirectoryTree(ATreeView: TTreeView; const APath: string);
    procedure ExpandTreeNode(ATreeView: TTreeView; ANode: TTreeNode);
    procedure FreeTreeViewData(ATreeView: TTreeView);
    procedure ApplyModernColors;
    procedure SetButtonStyle(AButton: TBitBtn; ABackColor, AFontColor: TColor);
    procedure SetInterfaceTexts;
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
    procedure ShowDirectoryProperties(const APath: string);
    procedure DeleteDirectory(const APath: string; ATreeView: TTreeView);
    
    // 进度管理
    procedure UpdateCurrentFile(const AFileName: string);
    procedure UpdateTimeRemaining;
    procedure ShowCancelButton(AShow: Boolean);
    
    // 简洁模式和权限管理
    procedure CheckAndRequestAdminPrivileges;
    procedure UpdateButtonStates;
    procedure SetSimpleMode(ASimple: Boolean);
    
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}


procedure TfrmMain.FormCreate(Sender: TObject);
var
  LogFile: TextFile;
begin
  // FormCreate开始执行
  
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
  var Config := TAntiTamperPackage.GetDefaultConfig;
  Config.EncryptionKey := 'MoveC_AntiTamper_Key_2025';
  Config.DownloadURL := 'http://www.goodmem.cn';
  Config.EnableLogging := {$IFDEF DEBUG}True{$ELSE}False{$ENDIF};
  Config.EncryptionType := etAES256; // 使用AES-256加密
  TAntiTamperPackage.Initialize(Config);

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
  
  // 检查管理员权限
  CheckAndRequestAdminPrivileges;
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

  FStyleManager.Free;
end;

procedure TfrmMain.FormShow(Sender: TObject);
var
  LogFile: TextFile;
begin
  // 强制写入日志确认FormShow被调用
  try
    AssignFile(LogFile, 'MAIN_FORMSHOW_DEBUG.log');
    Rewrite(LogFile);
    WriteLn(LogFile, Format('[%s] FormShow 开始执行', [DateTimeToStr(Now)]));
    CloseFile(LogFile);
  except
  end;

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
  
  // 初始化AboutMe安全模块
  try
    // 确保pnlBottom面板可见并设置合适的高度
    pnlBottom.Visible := True;
    if pnlBottom.Height < 200 then
      pnlBottom.Height := 250; // 设置足够的高度显示AboutMe内容
    
    // 创建并嵌入AboutMe框架到pnlBottom（在pnlAboutMe中）
    if not Assigned(FFrameAboutMe) then
    begin
      try
        AssignFile(LogFile, 'MAIN_FORMSHOW_DEBUG.log');
        Append(LogFile);
        WriteLn(LogFile, Format('[%s] 开始创建FrameAboutMe', [DateTimeToStr(Now)]));
        CloseFile(LogFile);
      except
      end;

      FFrameAboutMe := TFrameAboutMe.Create(Self);

      try
        AssignFile(LogFile, 'MAIN_FORMSHOW_DEBUG.log');
        Append(LogFile);
        WriteLn(LogFile, Format('[%s] FrameAboutMe创建完成', [DateTimeToStr(Now)]));
        CloseFile(LogFile);
      except
      end;

      FFrameAboutMe.Parent := pnlAboutMe; // pnlAboutMe是pnlBottom的子面板
      FFrameAboutMe.Align := alRight; // 在右侧显示，左侧留给memoStatus
      FFrameAboutMe.Width := 640; // 设置合适宽度
      FFrameAboutMe.Visible := True;

      try
        AssignFile(LogFile, 'MAIN_FORMSHOW_DEBUG.log');
        Append(LogFile);
        WriteLn(LogFile, Format('[%s] FrameAboutMe设置完成', [DateTimeToStr(Now)]));
        CloseFile(LogFile);
      except
      end;

      // 手动初始化Frame
      try
        AssignFile(LogFile, 'MAIN_FORMSHOW_DEBUG.log');
        Append(LogFile);
        WriteLn(LogFile, Format('[%s] 开始手动初始化FrameAboutMe', [DateTimeToStr(Now)]));
        CloseFile(LogFile);
      except
      end;

      FFrameAboutMe.ManualInitialize;

      try
        AssignFile(LogFile, 'MAIN_FORMSHOW_DEBUG.log');
        Append(LogFile);
        WriteLn(LogFile, Format('[%s] FrameAboutMe手动初始化完成', [DateTimeToStr(Now)]));
        CloseFile(LogFile);
      except
      end;
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
    // memo样式已在DFM中设置
    FStyleManager.StyleTreeView(tvSource);
    FStyleManager.StyleTreeView(tvTarget);
  end;
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
end;

procedure TfrmMain.LoadDirectoryTree(ATreeView: TTreeView; const APath: string);
var
  RootNode: TTreeNode;
  Directories: TArray<string>;
  I: Integer;
  DirName: string;
  SubNode: TTreeNode;
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
            var SubDirs := TDirectory.GetDirectories(Directories[I]);
            if Length(SubDirs) > 0 then
            begin
              var PlaceholderNode := ATreeView.Items.AddChild(SubNode, '...');
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

procedure TfrmMain.UpdateTreeViewPath(ATreeView: TTreeView; const APath: string);
begin
  LoadDirectoryTree(ATreeView, APath);
end;

procedure TfrmMain.UpdateStatus(const AMessage: string);
begin
  lblStatus.Caption := AMessage;
  memoStatus.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' - ' + AMessage);
  Application.ProcessMessages;
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
  Result: TCleanupResult;
begin
  try
    if not Assigned(FCleanupManager) then
    begin
      UpdateStatus('❌ 清理管理器未初始化');
      Exit;
    end;

    if ShowChineseConfirm('智能清理将执行以下操作：' + sLineBreak + sLineBreak +
                          '• 清空回收站' + sLineBreak +
                          '• 清理临时文件' + sLineBreak +
                          '• 清理浏览器缓存' + sLineBreak +
                          '• 清理系统日志' + sLineBreak +
                          '• 清理预取文件' + sLineBreak + sLineBreak +
                          '是否继续执行智能清理？') then
    begin
      UpdateStatus('🤖 开始智能清理...');
      ProgressBar1.Visible := True;
      ProgressBar1.Position := 0;
      
      Result := FCleanupManager.PerformSmartCleanup;
      
      if Result.Success then
      begin
        UpdateStatus(Format('✅ 智能清理完成 - 删除 %d 个文件，释放 %.2f MB 空间', 
          [Result.FilesDeleted, Result.SpaceFreed / (1024 * 1024)]));
        ShowChineseMessage(Format('智能清理完成！' + sLineBreak + sLineBreak +
          '清理结果：' + sLineBreak +
          '• 删除文件：%d 个' + sLineBreak +
          '• 释放空间：%.2f MB' + sLineBreak + sLineBreak +
          '您的系统运行速度应该有所提升！', 
          [Result.FilesDeleted, Result.SpaceFreed / (1024 * 1024)]));
      end
      else
      begin
        UpdateStatus('❌ 智能清理失败: ' + Result.ErrorMessage);
        ShowChineseMessage('智能清理失败：' + sLineBreak + Result.ErrorMessage);
      end;
    end;
    
  finally
    ProgressBar1.Visible := False;
    if Assigned(Result.Details) then
      Result.Details.Free;
  end;
end;

procedure TfrmMain.btnSmartMigrationClick(Sender: TObject);
begin
  UpdateStatus('迁移向导功能暂时不可用');
  ShowChineseMessage('迁移向导功能正在开发中！' + sLineBreak + sLineBreak +
    '当前请使用“开始迁移”按钮执行迁移操作。');
end;

procedure TfrmMain.btnExecuteClick(Sender: TObject);
begin
  if (FSourcePath = '') or (FTargetPath = '') then
  begin
    UpdateStatus('❌ 请先选择源目录和目标目录');
    ShowChineseMessage('请先选择源目录和目标目录！');
    Exit;
  end;

  if ShowChineseConfirm('确定要开始目录迁移操作吗？' + sLineBreak + sLineBreak +
                        '📁 源目录: ' + FSourcePath + sLineBreak +
                        '📂 目标目录: ' + FTargetPath + sLineBreak + sLineBreak +
                        '✅ 迁移步骤：' + sLineBreak +
                        '1️⃣ 复制全部文件到目标位置' + sLineBreak +
                        '2️⃣ 自动备份原目录' + sLineBreak +
                        '3️⃣ 创建Junction链接保证兼容' + sLineBreak + sLineBreak +
                        '⚠️ 重要提示：迁移前请确保关闭正在使用该目录的程序！') then
  begin
    ExecuteOperation;
  end;
end;

procedure TfrmMain.btnAnalyzeClick(Sender: TObject);
begin
  if FSourcePath = '' then
  begin
    UpdateStatus('❌ 请先选择源目录');
    ShowChineseMessage('请先选择源目录！');
    Exit;
  end;

  AnalyzeDirectory(FSourcePath);
end;

procedure TfrmMain.btnCalculateSizeClick(Sender: TObject);
begin
  if FSourcePath = '' then
  begin
    UpdateStatus('❌ 请先选择源目录');
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
  I: Integer;
  DirName: string;
  SubNode: TTreeNode;
  PlaceholderNode: TTreeNode;
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

    // 加载子目录
    try
      Directories := TDirectory.GetDirectories(NodePath);
      for I := 0 to High(Directories) do
      begin
        DirName := System.SysUtils.ExtractFileName(Directories[I]);
        if (DirName <> '') and (DirName[1] <> '.') then  // 跳过隐藏目录
        begin
          SubNode := ATreeView.Items.AddChild(ANode, DirName);
          SubNode.Data := Pointer(StrNew(PChar(Directories[I])));

          // 检查是否有子目录，如果有则添加占位符
          try
            var SubDirs := TDirectory.GetDirectories(Directories[I]);
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
begin
  try
    if not Assigned(FCleanupManager) then
    begin
      UpdateStatus('❌ 清理管理器未初始化');
      Exit;
    end;

    UpdateStatus('🗑️ 开始清空回收站...');
    ProgressBar1.Visible := True;
    ProgressBar1.Position := 0;
    
    Result := FCleanupManager.EmptyRecycleBin;
    
    if Result.Success then
    begin
      UpdateStatus('✅ 回收站清理完成');
      ShowChineseMessage('回收站已成功清空！');
    end
    else
    begin
      UpdateStatus('❌ 回收站清理失败: ' + Result.ErrorMessage);
      ShowChineseMessage('回收站清理失败：' + sLineBreak + Result.ErrorMessage);
    end;
    
  finally
    ProgressBar1.Visible := False;
    if Assigned(Result.Details) then
      Result.Details.Free;
  end;
end;

procedure TfrmMain.CleanTempFiles;
var
  Result: TCleanupResult;
begin
  try
    if not Assigned(FCleanupManager) then
    begin
      UpdateStatus('❌ 清理管理器未初始化');
      Exit;
    end;

    UpdateStatus('🧹 开始清理临时文件...');
    ProgressBar1.Visible := True;
    ProgressBar1.Position := 0;
    
    Result := FCleanupManager.CleanTempFiles;
    
    if Result.Success then
    begin
      UpdateStatus(Format('✅ 临时文件清理完成 - 删除 %d 个文件，释放 %.2f MB 空间', 
        [Result.FilesDeleted, Result.SpaceFreed / (1024 * 1024)]));
      ShowChineseMessage(Format('临时文件清理完成！' + sLineBreak + 
        '删除了 %d 个文件，释放了 %.2f MB 磁盘空间。', 
        [Result.FilesDeleted, Result.SpaceFreed / (1024 * 1024)]));
    end
    else
    begin
      UpdateStatus('❌ 临时文件清理失败: ' + Result.ErrorMessage);
      ShowChineseMessage('临时文件清理失败：' + sLineBreak + Result.ErrorMessage);
    end;
    
  finally
    ProgressBar1.Visible := False;
    if Assigned(Result.Details) then
      Result.Details.Free;
  end;
end;

procedure TfrmMain.CleanBackupFiles;
var
  Result: TCleanupResult;
begin
  try
    if not Assigned(FCleanupManager) then
    begin
      UpdateStatus('❌ 清理管理器未初始化');
      Exit;
    end;

    // 先检查是否有最近的备份文件需要保护
    if FLastBackupPath <> '' then
    begin
      if not ShowChineseConfirm('检测到最近的迁移备份文件：' + sLineBreak + FLastBackupPath + sLineBreak + sLineBreak +
                                '此操作不会删除最近的备份文件，是否继续清理其他备份文件？') then
        Exit;
    end;

    UpdateStatus('🗃️ 开始清理系统日志和备份文件...');
    ProgressBar1.Visible := True;
    ProgressBar1.Position := 0;
    
    Result := FCleanupManager.CleanSystemLogs;
    
    if Result.Success then
    begin
      UpdateStatus(Format('✅ 系统日志清理完成 - 删除 %d 个文件，释放 %.2f MB 空间', 
        [Result.FilesDeleted, Result.SpaceFreed / (1024 * 1024)]));
      ShowChineseMessage(Format('系统日志清理完成！' + sLineBreak + 
        '删除了 %d 个文件，释放了 %.2f MB 磁盘空间。', 
        [Result.FilesDeleted, Result.SpaceFreed / (1024 * 1024)]));
    end
    else
    begin
      UpdateStatus('❌ 系统日志清理失败: ' + Result.ErrorMessage);
      ShowChineseMessage('系统日志清理失败：' + sLineBreak + Result.ErrorMessage);
    end;
    
  finally
    ProgressBar1.Visible := False;
    if Assigned(Result.Details) then
      Result.Details.Free;
  end;
end;

procedure TfrmMain.CleanUpdateCache;
var
  Result: TCleanupResult;
begin
  try
    if not Assigned(FCleanupManager) then
    begin
      UpdateStatus('❌ 清理管理器未初始化');
      Exit;
    end;

    UpdateStatus('🔄 开始清理Windows更新缓存...');
    ProgressBar1.Visible := True;
    ProgressBar1.Position := 0;
    
    Result := FCleanupManager.CleanWindowsUpdateCache;
    
    if Result.Success then
    begin
      UpdateStatus(Format('✅ Windows更新缓存清理完成 - 删除 %d 个文件，释放 %.2f MB 空间', 
        [Result.FilesDeleted, Result.SpaceFreed / (1024 * 1024)]));
      ShowChineseMessage(Format('Windows更新缓存清理完成！' + sLineBreak + 
        '删除了 %d 个文件，释放了 %.2f MB 磁盘空间。', 
        [Result.FilesDeleted, Result.SpaceFreed / (1024 * 1024)]));
    end
    else
    begin
      UpdateStatus('❌ Windows更新缓存清理失败: ' + Result.ErrorMessage);
      ShowChineseMessage('Windows更新缓存清理失败：' + sLineBreak + Result.ErrorMessage);
    end;
    
  finally
    ProgressBar1.Visible := False;
    if Assigned(Result.Details) then
      Result.Details.Free;
  end;
end;

procedure TfrmMain.FreeTreeViewData(ATreeView: TTreeView);
var
  I: Integer;
  Node: TTreeNode;
begin
  if not Assigned(ATreeView) then Exit;

  for I := 0 to ATreeView.Items.Count - 1 do
  begin
    Node := ATreeView.Items[I];
    if Assigned(Node.Data) then
    begin
      StrDispose(PChar(Node.Data));
      Node.Data := nil;
    end;
  end;
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
begin
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
  Dst := TPath.Combine(DstRoot, System.SysUtils.ExtractFileName(TPath.GetDirectoryName(Src + '\\')));
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
    // 启动事务
    FMigrationTransaction.StartTransaction(Src, Dst);
    UpdateStatus('事务已创建: ' + FMigrationTransaction.TransactionID);

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
        Exit;
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
      ShowCancelButton(False);
      Exit;
    end;

    if not CopyDirRecursiveWithVerify(Src, Dst, FMigrationTransaction) then
    begin
      UpdateStatus('拷贝或校验失败，开始回滚...');
      FMigrationTransaction.FailTransaction('文件拷贝或校验失败');
      
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
      
      ShowCancelButton(False);  // 隐藏取消按钮
      Exit;
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
      ShowCancelButton(False);
      Exit;
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
      ShowCancelButton(False);
      Exit;
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
      ShowCancelButton(False);
      Exit;
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
      ShowCancelButton(False);
      Exit;
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
      ShowCancelButton(False);
      Exit;
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
    
    if Length(FailedFiles) > 0 then
    begin
      UpdateStatus(Format('警告：%d 个文件验证失败', [Length(FailedFiles)]));
      for I := 0 to Min(4, Length(FailedFiles) - 1) do
        UpdateStatus('  - ' + FailedFiles[I].SourcePath);
    end;

    // 计算备份目录大小
    var BackupSize: Int64 := 0;
    var BackupFileCount: Integer := 0;
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

  finally
    ProgressBar1.Visible := False;
    ShowCancelButton(False);  // 隐藏取消按钮
    FCancelRequested := False;
  end;
end;

function TfrmMain.CreateDirectoryLink(const ASource, ATarget: string): Boolean;
var
  Command: string;
  ExitCode: DWORD;
begin
  Result := False;

  try
    // 优先使用目录联接 (Junction)
    Command := Format('mklink /J "%s" "%s"', [ASource, ATarget]);
    UpdateStatus('🔗 创建目录联接: ' + Command);

    ExitCode := 0;
    if WinExec(PAnsiChar(AnsiString('cmd /c ' + Command)), SW_HIDE) > 31 then
    begin
      Sleep(1000); // 等待命令执行
      Result := TDirectory.Exists(ASource);
    end;

    if not Result then
    begin
      // 如果目录联接失败，尝试符号链接
      Command := Format('mklink /D "%s" "%s"', [ASource, ATarget]);
      UpdateStatus('🔗 尝试符号链接: ' + Command);

      if WinExec(PAnsiChar(AnsiString('cmd /c ' + Command)), SW_HIDE) > 31 then
      begin
        Sleep(1000);
        Result := TDirectory.Exists(ASource);
      end;
    end;

    if Result then
      UpdateStatus('✅ 链接创建成功')
    else
      UpdateStatus('❌ 链接创建失败');

  except
    on E: Exception do
    begin
      UpdateStatus('❌ 创建链接时发生异常: ' + E.Message);
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
  FileSize: Int64;
begin
  // 确保目标目录存在
  if not TDirectory.Exists(ADst) then
    TDirectory.CreateDirectory(ADst);

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

      // 更新进度
      if FTotalBytesToCopy > 0 then
      begin
        FCopiedBytesSoFar := ACopied;
        ProgressBar1.Position := Round((FCopiedBytesSoFar * 100) / FTotalBytesToCopy);
      end;

      Application.ProcessMessages;
    except
      on E: Exception do
        UpdateStatus('⚠️ 复制文件失败: ' + SrcFile + ' - ' + E.Message);
    end;
  end;

  // 递归复制子目录
  Dirs := TDirectory.GetDirectories(ASrc);
  for I := 0 to High(Dirs) do
  begin
    if FCancelRequested then Break;

    var SubDir := System.SysUtils.ExtractFileName(Dirs[I]);
    CopyDirRecursive(Dirs[I], TPath.Combine(ADst, SubDir), ACopied);
  end;
end;

procedure TfrmMain.AnalyzeDirectory(const APath: string);
var
  FileCount: Integer;
  TotalSize: Int64;
  SizeMB, SizeGB: Double;
  Recommendation, RiskLevel: string;
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
      Recommendation := '❌ 不建议迁移：目录较小，迁移效果有限';
      RiskLevel := '🔴 高风险';
    end;

    // 根据路径特征判断风险
    var PathLower := LowerCase(APath);
    if Pos('system', PathLower) > 0 then
    begin
      RiskLevel := '🔴 极高风险';
      Recommendation := '⚠️ 严禁迁移：系统关键目录，迁移可能导致系统崩溃';
    end
    else if Pos('program', PathLower) > 0 then
    begin
      RiskLevel := '🟡 中等风险';
      Recommendation := '⚠️ 谨慎迁移：程序目录，需要测试相关软件功能';
    end
    else if (Pos('documents', PathLower) > 0) or (Pos('desktop', PathLower) > 0) then
    begin
      RiskLevel := '🟢 低风险';
      Recommendation := '✅ 推荐迁移：用户数据目录，迁移安全性高';
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

      // 计算源文件哈希（样本哈希以加速）
      try
        SrcHash := TFileHasher.ComputeSHA256(SrcFile, hoSampleHash);
        DstHash := TFileHasher.ComputeSHA256(DstFile, hoSampleHash);

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

    var SubDir := System.SysUtils.ExtractFileName(Dirs[I]);
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
      var Files := TDirectory.GetFiles(AJunctionPath);
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
      var TargetTestFile := TPath.Combine(ATargetPath, '_verify_test.tmp');
      if TFile.Exists(TargetTestFile) then
      begin
        var ReadContent := TFile.ReadAllText(TargetTestFile);
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
begin
  ShowChineseMessage('智能重复文件清理功能正在开发中，敬请期待！');
end;

procedure TfrmMain.miLogManagerClick(Sender: TObject);
begin
  ShowChineseMessage('日志管理功能正在开发中，敬请期待！');
end;

procedure TfrmMain.miAdvancedOptionsClick(Sender: TObject);
begin
  ShowChineseMessage('高级功能正在开发中，敬请期待！');
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
  // 基本颜色设置已移动到DFM，只保留动态颜色设置

  // 按钮背景色设置 (保留动态颜色功能)
  SetButtonStyle(btnExecute, $4CAF50, clBlack);      // Material Green
  SetButtonStyle(btnAnalyze, $2196F3, clBlack);      // Material Blue
  SetButtonStyle(btnCalculateSize, $FF9800, clBlack); // Material Orange
  SetButtonStyle(btnCleanRecycleBin, $9C27B0, clBlack); // Material Purple
  SetButtonStyle(btnCleanTemp, $673AB7, clBlack);       // Material Deep Purple
  SetButtonStyle(btnCleanBackup, $3F51B5, clBlack);     // Material Indigo
  SetButtonStyle(btnCleanUpdate, $2196F3, clBlack);     // Material Blue
  SetButtonStyle(btnSmartClean, $009688, clBlack);      // Material Teal
  SetButtonStyle(btnSmartMigration, $00BCD4, clBlack);  // Material Cyan
  SetButtonStyle(btnBrowseSource, $607D8B, clBlack);    // Material Blue Grey
  SetButtonStyle(btnBrowseTarget, $607D8B, clBlack);    // Material Blue Grey
  SetButtonStyle(btnSourceUp, $795548, clBlack);        // Material Brown
  SetButtonStyle(btnTargetUp, $795548, clBlack);        // Material Brown
  SetButtonStyle(btnExit, $F44336, clBlack);            // Material Red

  // 编辑框、树视图、状态信息和标签的样式已移动到DFM
  // 进度条和状态栏颜色已移动到DFM
  // 按钮字体已移动到DFM
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

procedure TfrmMain.SetInterfaceTexts;
begin
  // 设置按钮文本
  btnCleanRecycleBin.Caption := '清空回收站';
  btnCleanTemp.Caption := '清理临时文件';
  btnCleanBackup.Caption := '清理备份';
  btnCleanUpdate.Caption := '清理更新缓存';
  btnSmartClean.Caption := '智能清理';
  btnSmartMigration.Caption := '迁移向导';
  btnExecute.Caption := '开始迁移';
  btnAnalyze.Caption := '分析目录';
  btnCalculateSize.Caption := '计算大小';
  btnExit.Caption := '退出';

  // 设置浏览和导航按钮
  btnBrowseSource.Caption := '浏览...';
  btnBrowseTarget.Caption := '浏览...';
  btnSourceUp.Caption := '上级';
  btnTargetUp.Caption := '上级';

  // 设置标签文本
  lblSourceDir.Caption := '源目录：';
  lblTargetDir.Caption := '目标目录：';
  lblStatus.Caption := '状态信息';

  // 设置面板标题
  // pnlLeft.Caption := '源目录';
  // pnlRight.Caption := '目标目录';
  // pnlStatus.Caption := '状态信息';

  // 菜单文本已在DFM中设置，不需要在代码中重复设置
end;

procedure TfrmMain.LoadButtonIcons;
begin
  // 为清理功能按钮加载图标
  IconManager.ApplyIconToButton(btnCleanRecycleBin, IconManager.ICON_RECYCLE_BIN);
  IconManager.ApplyIconToButton(btnCleanTemp, IconManager.ICON_CLEAN_TEMP);
  IconManager.ApplyIconToButton(btnCleanBackup, IconManager.ICON_CLEAN_BACKUP);
  IconManager.ApplyIconToButton(btnCleanUpdate, IconManager.ICON_CLEAN_UPDATE);
  IconManager.ApplyIconToButton(btnSmartClean, IconManager.ICON_SMART_CLEAN);
  IconManager.ApplyIconToButton(btnSmartMigration, IconManager.ICON_SMART_MIGRATION);

  // 为主要功能按钮加载图标
  IconManager.ApplyIconToButton(btnExecute, IconManager.ICON_EXECUTE);
  IconManager.ApplyIconToButton(btnAnalyze, IconManager.ICON_ANALYZE);
  IconManager.ApplyIconToButton(btnCalculateSize, IconManager.ICON_CALCULATE);
  IconManager.ApplyIconToButton(btnExit, IconManager.ICON_EXIT);

  // 为浏览和导航按钮加载图标
  IconManager.ApplyIconToButton(btnBrowseSource, IconManager.ICON_BROWSE);
  IconManager.ApplyIconToButton(btnBrowseTarget, IconManager.ICON_BROWSE);
  IconManager.ApplyIconToButton(btnSourceUp, IconManager.ICON_UP);
  IconManager.ApplyIconToButton(btnTargetUp, IconManager.ICON_UP);
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
  TotalBytes: Int64;
  ProcessedBytes: Int64;
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
    TotalBytes := ATransaction.TotalBytes;
    ProcessedBytes := ATransaction.ProcessedBytes;
    
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

// ===== 文件列表管理 =====

// 初始化文件列表控件
procedure TfrmMain.InitializeFileList;
begin
  // lvFiles已在设计时创建，无需额外初始化
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
  if not Assigned(lvFiles) then
    Exit;
    
  lvFiles.Items.BeginUpdate;
  try
    lvFiles.Clear;
    
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
        Item := lvFiles.Items.Add;
        Item.Caption := TPath.GetFileName(Dirs[I]);
        Item.SubItems.Add('<DIR>');
        
        if FindFirst(Dirs[I], faDirectory, FileInfo) = 0 then
        begin
          FileTime := FileDateToDateTime(FileInfo.Time);
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
        Item := lvFiles.Items.Add;
        Item.Caption := TPath.GetFileName(Files[I]);
        
        try
          FileSize := TFile.GetSize(Files[I]);
          Item.SubItems.Add(TSystemCheck.FormatBytes(FileSize));
        except
          Item.SubItems.Add('');
        end;
        
        if FindFirst(Files[I], faAnyFile, FileInfo) = 0 then
        begin
          FileTime := FileDateToDateTime(FileInfo.Time);
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
    lvFiles.Items.EndUpdate;
  end;
end;

// 显示目录属性
procedure TfrmMain.ShowDirectoryProperties(const APath: string);
var
  FileCount: Integer;
  TotalSize: Int64;
  Msg: string;
begin
  if not TDirectory.Exists(APath) then
  begin
    ShowChineseMessage('目录不存在!');
    Exit;
  end;
  
  FileCount := 0;
  TotalSize := 0;
  
  UpdateStatus('正在计算目录属性...');
  ProgressBar1.Visible := True;
  ProgressBar1.Style := pbstMarquee;
  
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
    
  finally
    ProgressBar1.Visible := False;
    ProgressBar1.Style := pbstNormal;
  end;
end;

// 删除目录
procedure TfrmMain.DeleteDirectory(const APath: string; ATreeView: TTreeView);
var
  FileCount: Integer;
  TotalSize: Int64;
  Msg: string;
begin
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
    '确认删除该目录吗?' + sLineBreak + sLineBreak +
    '路径: %s' + sLineBreak +
    '文件数量: %d' + sLineBreak +
    '总大小: %s' + sLineBreak + sLineBreak +
    '警告: 该操作不可恢复!',
    [APath, FileCount, TSystemCheck.FormatBytes(TotalSize)]);
  
  if not ShowChineseConfirm(Msg) then
    Exit;
  
  // 二次确认
  if not ShowChineseConfirm('再次确认: 确定要删除此目录吗?' + sLineBreak + APath) then
    Exit;
  
  UpdateStatus('正在删除目录: ' + APath);
  ProgressBar1.Visible := True;
  ProgressBar1.Style := pbstMarquee;
  
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
    if Assigned(lvFiles) then
      lvFiles.Clear;
    
  except
    on E: Exception do
    begin
      UpdateStatus('删除目录失败: ' + E.Message);
      ShowChineseMessage('删除目录失败:' + sLineBreak + E.Message);
    end;
  end;
  
  ProgressBar1.Visible := False;
  ProgressBar1.Style := pbstNormal;
end;

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
begin
  // 截取文件名，避免过长
  DisplayName := AFileName;
  if Length(DisplayName) > 80 then
    DisplayName := '...' + Copy(DisplayName, Length(DisplayName) - 76, 77);
  
  lblCurrentFile.Caption := '当前文件: ' + DisplayName;
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
  
  Hours := EstimatedSeconds div 3600;
  Minutes := (EstimatedSeconds mod 3600) div 60;
  Seconds := EstimatedSeconds mod 60;
  
  if Hours > 0 then
    TimeStr := Format('剩余时间: %d 小时 %d 分钟', [Hours, Minutes])
  else if Minutes > 0 then
    TimeStr := Format('剩余时间: %d 分钟 %d 秒', [Minutes, Seconds])
  else
    TimeStr := Format('剩余时间: %d 秒', [Seconds]);
  
  lblTimeRemaining.Caption := TimeStr;
end;

// 显示/隐藏取消按钮
procedure TfrmMain.ShowCancelButton(AShow: Boolean);
begin
  btnCancelOperation.Visible := AShow;
  if not AShow then
  begin
    lblCurrentFile.Caption := '当前文件: ';
    lblTimeRemaining.Caption := '剩余时间: ';
  end;
end;

// 取消按钮点击事件
procedure TfrmMain.btnCancelOperationClick(Sender: TObject);
begin
  if ShowChineseConfirm('确定要取消当前操作吗？' + sLineBreak + sLineBreak +
                        '取消后将停止当前进度，已处理的数据不会丢失。') then
  begin
    FCancelRequested := True;
    btnCancelOperation.Enabled := False;
    UpdateStatus('用户请求取消操作...');
  end;
end;

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
    UpdateStatus('✅ 已获取管理员权限');
    StatusBar1.Panels[0].Text := '管理员模式';
  end
  else
  begin
    UpdateStatus('⚠️ 警告：未以管理员身份运行，部分功能将受限');
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
  // 需要管理员权限的按钮
  btnExecute.Enabled := FIsAdmin;
  btnSmartMigration.Enabled := FIsAdmin;
  btnCleanUpdate.Enabled := FIsAdmin;
  
  // 在简洁模式下隐藏高级按钮
  if FSimpleMode then
  begin
    // 简洁模式：只显示一键按钮
    btnSmartClean.Visible := True;
    btnSmartMigration.Visible := True;
    btnExit.Visible := True;
    
    // 隐藏高级按钮
    btnCleanRecycleBin.Visible := False;
    btnCleanTemp.Visible := False;
    btnCleanBackup.Visible := False;
    btnCleanUpdate.Visible := False;
    btnAnalyze.Visible := False;
    btnCalculateSize.Visible := False;
    btnExecute.Visible := False;
  end
  else
  begin
    // 专家模式：显示所有按钮
    btnCleanRecycleBin.Visible := True;
    btnCleanTemp.Visible := True;
    btnCleanBackup.Visible := True;
    btnCleanUpdate.Visible := True;
    btnSmartClean.Visible := True;
    btnSmartMigration.Visible := True;
    btnAnalyze.Visible := True;
    btnCalculateSize.Visible := True;
    btnExecute.Visible := True;
    btnExit.Visible := True;
  end;
end;

// 设置简洁模式
procedure TfrmMain.SetSimpleMode(ASimple: Boolean);
begin
  FSimpleMode := ASimple;
  miSimpleMode.Checked := ASimple;
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

end.

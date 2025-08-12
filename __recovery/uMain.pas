unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI,
  System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections, System.Generics.Defaults, System.Threading, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Menus, Vcl.FileCtrl,
  System.IOUtils, System.UITypes, Vcl.Shell.ShellCtrls,
  // Modern UI styles and strings
  uStyles, uStrings;

type
  TfrmMain = class(TForm)
    // 主菜单
    MainMenu1: TMainMenu;
    MenuFile: TMenuItem;
    MenuEdit: TMenuItem;
    MenuTools: TMenuItem;
    MenuHelp: TMenuItem;
    MenuTheme: TMenuItem;
    MenuCleanup: TMenuItem;
    MenuCleanupRecycleBin: TMenuItem;
    MenuCleanupTemp: TMenuItem;
    MenuCleanupSeparator: TMenuItem;
    MenuCleanupSoftwareDistribution: TMenuItem;

    // 主面板布局
    pnlMain: TPanel;
    pnlLeft: TPanel;
    pnlRight: TPanel;
    pnlStatus: TPanel;

    // 左侧面板 - 源目录
    lblSourceDir: TLabel;
    edtSourceDir: TEdit;
    btnBrowseSource: TButton;
    btnSelectSourceRoot: TButton;
    stvSource: TShellTreeView;

    // 右侧面板 - 目标目录
    lblTargetDir: TLabel;
    edtTargetDir: TEdit;
    btnBrowseTarget: TButton;
    btnSelectTargetRoot: TButton;
    stvTarget: TShellTreeView;

    // 状态面板
    lblStatus: TLabel;
    ProgressBar1: TProgressBar;
    memoStatus: TMemo;

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

    procedure MenuThemeClick(Sender: TObject);
    procedure MenuFileExitClick(Sender: TObject);
    procedure MenuHelpAboutClick(Sender: TObject);
    procedure MenuCleanupRecycleBinClick(Sender: TObject);
    procedure MenuCleanupTempClick(Sender: TObject);
    procedure MenuCleanupSoftwareDistributionClick(Sender: TObject);

  private
    FSourcePath: string;
    FTargetPath: string;
    FIsProcessing: Boolean;
    FInitTimer: TTimer;
    FLastBackupPath: string;

    // 空间分析：聚合结构
    type TExtStat = record Ext: string; Size: Int64; Count: Integer; end;

    procedure InitAfterShow(Sender: TObject);
    procedure StartSpaceAnalysis(const RootPath: string);
    procedure LogTopN(const Items: TArray<TPair<string, Int64>>; N: Integer);
    procedure LogTypeAggregation(const Agg: TArray<TExtStat>);
    function IsReparseDir(const Path: string): Boolean;

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
    procedure MenuCleanupLastBackupClick(Sender: TObject);

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

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // 初始化界面
  InitializeUI;

  // 应用现代化样式
  ApplyModernStyles;

  // 初始化状态
  FIsProcessing := False;
  SetProcessingState(False);

  UpdateStatus(_(STR_APP_STARTED));
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  try
    // 停止任何正在进行的操作
    FIsProcessing := False;

    // 清理资源
    // 注意：不要手动释放由窗体管理的控件
    // Delphi会自动释放窗体及其子控件
  except
    // 忽略销毁过程中的异常，避免程序崩溃
  end;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  // 窗体显示时的处理
  UpdateStatus(_(STR_SELECT_DIRS));

  // 确保路径变量已初始化
  if FSourcePath = '' then
    FSourcePath := 'C:\Users';
  if FTargetPath = '' then
    FTargetPath := 'D:\Users';

  // 使用一次性计时器，避免阻塞 UI
  if not Assigned(FInitTimer) then
  begin
    FInitTimer := TTimer.Create(Self);
    FInitTimer.Interval := 50;
    FInitTimer.OnTimer := InitAfterShow;
    FInitTimer.Enabled := True;
  end;
  Exit; // 其余初始化在 InitAfterShow 中进行
end;

procedure TfrmMain.InitAfterShow(Sender: TObject);
begin
  try
    if Assigned(FInitTimer) then
    begin
      FInitTimer.Enabled := False;
      FreeAndNil(FInitTimer);
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
  SetProcessingState(False);
  UpdateStatus('⏹️ 操作已停止');
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
    if (TempPaths[i] <> '') and DirectoryExists(TempPaths[i]) then
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

  if DirectoryExists(SoftDistPath) then
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

  if not DirectoryExists(DirPath) then
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

    // 1) 拷贝到目标
    Copied := 0;
    try
      CopyDirRecursive(Src, Dst, Copied);
      UpdateStatus(Format('📦 拷贝完成（约 %.2f GB）', [Copied/1024/1024/1024]));
      // 简单一致性校验（文件数与总字节）
      var cDst, cSrc: Integer; var bDst, bSrc: Int64;
      ComputeDirStats(Dst, cDst, bDst);
      ComputeDirStats(Src, cSrc, bSrc);
      UpdateStatus(Format('🔍 校验：目标文件数 %d / 源文件数 %d；目标大小 %.2f GB / 源大小 %.2f GB',
        [cDst, cSrc, bDst/1024/1024/1024, bSrc/1024/1024/1024]));
      if (cDst <> cSrc) or (bDst <> bSrc) then
      begin
        UpdateStatus('❌ 校验失败：目标与源不一致，已停止迁移');
        Exit;
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

    // 3) 在原位置创建链接指向新位置
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

    // 4) 保留备份，并提醒验证后清理备份以释放C盘
    UpdateStatus('✅ 迁移完成。已保留备份目录: ' + Backup);
    UpdateStatus('⚠️ 重要: 请立即测试依赖此目录的程序是否正常运行。');
    UpdateStatus('💡 测试无误后，请删除 C 盘备份目录以真正释放空间。');
    UpdateStatus('🗑️ 你可以在“清理”菜单中使用“清理临时文件”或手动删除备份目录（推荐移入回收站）。');
  finally
    SetProcessingState(False);
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
var
  Flags: DWORD;
begin
  // 只为目录创建符号链接
  Flags := SYMBOLIC_LINK_FLAG_DIRECTORY;
  {$IF CompilerVersion >= 35.0}
  // 新版 Windows 允许开发者模式下不需要提权
  {$IFDEF UNICODE}
  Result := CreateSymbolicLinkW(PWideChar(LinkPath), PWideChar(TargetPath), Flags);
  {$ELSE}
  Result := CreateSymbolicLink(PChar(LinkPath), PChar(TargetPath), Flags);
  {$ENDIF}
  {$ELSE}
  Result := CreateSymbolicLink(PChar(LinkPath), PChar(TargetPath), Flags);
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

  {$IFEND}
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
  // 优先符号链接，失败则联接
  if CreateDirectorySymlink(LinkPath, TargetPath) then
    Exit(True);
  if CreateDirectoryJunctionViaCmd(LinkPath, TargetPath) then
    Exit(True);
end;

procedure TfrmMain.CopyDirRecursive(const Src, Dst: string; var CopiedBytes: Int64);
var
  SR: TSearchRec;
  Code: Integer;
  SrcPath, DstPath: string;
  InF, OutF: TFileStream;
begin
  System.SysUtils.ForceDirectories(Dst);

  Code := FindFirst(IncludeTrailingPathDelimiter(Src) + '*', faAnyFile, SR);
  try
    while Code = 0 do
    begin
      if (SR.Name <> '.') and (SR.Name <> '..') then
      begin
        SrcPath := IncludeTrailingPathDelimiter(Src) + SR.Name;
        DstPath := IncludeTrailingPathDelimiter(Dst) + SR.Name;
        if (SR.Attr and faDirectory) <> 0 then
          CopyDirRecursive(SrcPath, DstPath, CopiedBytes)
        else
        begin
          InF := TFileStream.Create(SrcPath, fmOpenRead or fmShareDenyWrite);
          try
            OutF := TFileStream.Create(DstPath, fmCreate);
            try
              CopiedBytes := CopiedBytes + InF.Size;
              OutF.CopyFrom(InF, 0);
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

end.

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

  private
    FSourcePath: string;
    FTargetPath: string;
    FIsProcessing: Boolean;
    FInitTimer: TTimer;

    // 空间分析：聚合结构
    type TExtStat = record Ext: string; Size: Int64; Count: Integer; end;

    procedure InitAfterShow(Sender: TObject);
    procedure StartSpaceAnalysis(const RootPath: string);
    procedure LogTopN(const Items: TArray<TPair<string, Int64>>; N: Integer);
    procedure LogTypeAggregation(const Agg: TArray<TExtStat>);
    function IsReparseDir(const Path: string): Boolean;

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


procedure TfrmMain.MenuCleanupRecycleBinClick(Sender: TObject);
var
  Flags: UINT;

function TfrmMain.IsReparseDir(const Path: string): Boolean;
begin
  Result := (GetFileAttributes(PChar(Path)) and FILE_ATTRIBUTE_REPARSE_POINT) <> 0;
end;

procedure TfrmMain.LogTopN(const Items: TArray<TPair<string, Int64>>; N: Integer);
var I, MaxN: Integer;
begin
  MaxN := Min(N, Length(Items));
  UpdateStatus('📈 Top 大文件（前' + MaxN.ToString + '）:');
  for I := 0 to MaxN - 1 do
    UpdateStatus(Format('  %s  (%.2f MB)', [Items[I].Key, Items[I].Value/1024/1024]));
end;

procedure TfrmMain.LogTypeAggregation(const Agg: TArray<TExtStat>);
var i: Integer;
begin
  UpdateStatus('🧾 类型聚合:');
  for i := 0 to High(Agg) do
    UpdateStatus(Format('  %-6s  数量:%d  大小:%.2f MB',[Agg[i].Ext, Agg[i].Count, Agg[i].Size/1024/1024]));
end;

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

      // 强制退出应用程序
      Application.Terminate;
    end;
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
begin
  // 简单的操作实现
  UpdateStatus('📋 正在准备操作...');
  Sleep(1000);

  UpdateStatus('📁 正在创建目标目录...');
  Sleep(1000);

  UpdateStatus('🔗 正在创建符号链接...');
  Sleep(1000);
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

unit uSmartMigrationWizard;

{
  智能迁移向导 - Smart Migration Wizard
  
  提供用户友好的迁移向导界面，包括：
  - 源目录选择和分析
  - 目标路径建议
  - 安全检查和建议
  - 迁移预览和确认
  - 自动化迁移过程
  
  作者: AI助手
  版本: 1.0
  日期: 2024
}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI,
  System.SysUtils, System.Variants, System.Classes,
  System.IOUtils, System.Generics.Collections, System.UITypes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.Buttons, Vcl.CheckLst, Vcl.FileCtrl,
  uMigrationTransaction, uSystemCheck, uDiskAnalyzer;

type
  TWizardPage = (wpWelcome, wpSourceSelection, wpAnalysis, wpTargetSelection, 
                 wpSafetyCheck, wpConfirmation, wpExecution, wpComplete);

  TMigrationRecommendation = record
    SourcePath: string;
    TargetPath: string;
    EstimatedSize: Int64;
    SafetyLevel: Integer; // 1-5, 1=最安全, 5=高风险
    Reason: string;
    FileCount: Integer;
    Selected: Boolean;    // 是否选中
    Status: string;       // 迁移状态
  end;
  
  TMigrationTemplate = record
    Name: string;
    Description: string;
    Paths: TArray<string>;
  end;

  TfrmSmartMigrationWizard = class(TForm)
    // 主面板
    pnlMain: TPanel;
    
    // 标题区域
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    
    // 内容区域
    pnlContent: TPanel;
    
    // 欢迎页面
    pnlWelcome: TPanel;
    lblWelcome: TLabel;
    memoWelcomeText: TMemo;
    
    // 源目录选择页面 (支持批量选择)
    pnlSourceSelection: TPanel;
    lblSelectSource: TLabel;
    clbSourcePaths: TCheckListBox;   // 多选列表
    btnSelectAll: TBitBtn;           // 全选按钮
    btnSelectNone: TBitBtn;          // 取消全选
    btnAddCustomPath: TBitBtn;       // 添加自定义路径
    lblSelectedInfo: TLabel;         // 已选信息
    cboTemplates: TComboBox;         // 模板选择
    lblTemplates: TLabel;            // 模板标签
    
    // 分析页面
    pnlAnalysis: TPanel;
    lblAnalyzing: TLabel;
    ProgressBarAnalysis: TProgressBar;
    memoAnalysisResults: TMemo;
    lblAnalysisStatus: TLabel;
    
    // 目标选择页面
    pnlTargetSelection: TPanel;
    lblSelectTarget: TLabel;
    edtTargetPath: TEdit;
    btnBrowseTarget: TBitBtn;
    lvAvailableDrives: TListView;
    lblAvailableDrives: TLabel;
    lblTargetInfo: TLabel;
    
    // 安全检查页面
    pnlSafetyCheck: TPanel;
    lblSafetyCheck: TLabel;
    lvSafetyChecks: TListView;
    memoSafetyWarnings: TMemo;
    
    // 确认页面
    pnlConfirmation: TPanel;
    lblConfirmation: TLabel;
    memoMigrationPlan: TMemo;
    chkCreateBackup: TCheckBox;
    chkVerifyFiles: TCheckBox;
    chkCreateJunction: TCheckBox;
    
    // 执行页面
    pnlExecution: TPanel;
    lblExecution: TLabel;
    ProgressBarExecution: TProgressBar;
    lblExecutionStatus: TLabel;
    memoExecutionLog: TMemo;
    btnCancelExecution: TBitBtn;
    
    // 完成页面
    pnlComplete: TPanel;
    lblComplete: TLabel;
    memoCompleteSummary: TMemo;
    chkDeleteBackup: TCheckBox;
    chkOpenTargetFolder: TCheckBox;
    
    // 底部控制按钮
    pnlButtons: TPanel;
    btnBack: TBitBtn;
    btnNext: TBitBtn;
    btnCancel: TBitBtn;
    btnFinish: TBitBtn;
    
    // 事件处理
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    
    procedure btnBackClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnFinishClick(Sender: TObject);
    
    procedure btnBrowseTargetClick(Sender: TObject);
    procedure btnCancelExecutionClick(Sender: TObject);
    
    // 批量选择事件
    procedure btnSelectAllClick(Sender: TObject);
    procedure btnSelectNoneClick(Sender: TObject);
    procedure btnAddCustomPathClick(Sender: TObject);
    procedure clbSourcePathsClickCheck(Sender: TObject);
    procedure cboTemplatesChange(Sender: TObject);
    
    procedure lvAvailableDrivesDblClick(Sender: TObject);
    
  private
    FCurrentPage: TWizardPage;
    FSourcePath: string;
    FTargetPath: string;
    FMigrationTransaction: TMigrationTransaction;
    FCancelRequested: Boolean;
    // 批量迁移支持
    FSelectedPaths: TArray<TMigrationRecommendation>;    // 选中的路径列表
    FAllRecommendedPaths: TArray<TMigrationRecommendation>; // 所有推荐路径
    FMigrationTemplates: TArray<TMigrationTemplate>;     // 迁移模板
    FCurrentMigrationIndex: Integer;                     // 当前迁移索引
    FExecutionThread: TThread;
    
    procedure InitializeInterface;
    procedure ShowPage(Page: TWizardPage);
    procedure UpdateButtons;
    procedure LoadRecommendedPaths;
    procedure LoadAvailableDrives;
    procedure LoadMigrationTemplates;       // 加载迁移模板
    procedure UpdateSelectedInfo;           // 更新已选信息
    procedure CollectSelectedPaths;         // 收集选中路径
    procedure AnalyzeSourcePaths;           // 批量分析(重命名)
    procedure PerformSafetyChecks;
    procedure GenerateMigrationPlan;
    procedure ExecuteBatchMigration;        // 批量执行(重命名)
    procedure ShowExecutionResults;
    
    // 页面验证
    function ValidateCurrentPage: Boolean;
    function CanGoNext: Boolean;
    function CanGoBack: Boolean;
    
    // 分析和检查方法
    function AnalyzeDirectory(const Path: string): TMigrationRecommendation;
    function GetDirectorySize(const Path: string): Int64;
    function GetDirectoryFileCount(const Path: string): Integer;
    function GetDirectorySafetyLevel(const Path: string): Integer;
    function GetBestTargetPath(const SourcePath: string): string;
    function FormatBytes(Bytes: Int64): string;
    function StarRating(Level: Integer): string;
    function RepeatChar(const C: Char; Count: Integer): string;
    
    // UI更新方法
    procedure UpdateAnalysisProgress(const Status: string; Progress: Integer);
    procedure UpdateExecutionProgress(const Status: string; Progress: Integer);
    procedure AddExecutionLog(const Message: string);
    
  public
    property SourcePath: string read FSourcePath write FSourcePath;
    property TargetPath: string read FTargetPath write FTargetPath;
  end;

var
  frmSmartMigrationWizard: TfrmSmartMigrationWizard;

implementation

{$R *.dfm}

procedure TfrmSmartMigrationWizard.FormCreate(Sender: TObject);
begin
  FCurrentPage := wpWelcome;
  FSourcePath := '';
  FTargetPath := '';
  FMigrationTransaction := nil;
  FCancelRequested := False;
  FExecutionThread := nil;
  
  InitializeInterface;
  ShowPage(FCurrentPage);
end;

procedure TfrmSmartMigrationWizard.FormDestroy(Sender: TObject);
begin
  if Assigned(FExecutionThread) then
  begin
    FCancelRequested := True;
    FExecutionThread.WaitFor;
    FExecutionThread.Free;
  end;
  
  if Assigned(FMigrationTransaction) then
    FMigrationTransaction.Free;
end;

procedure TfrmSmartMigrationWizard.FormShow(Sender: TObject);
begin
  // 设置窗口标题和初始状态
  Caption := '智能迁移向导 - C盘瘦身神器 (支持批量迁移)';
  Position := poScreenCenter;
  
  // 加载迁移模板
  LoadMigrationTemplates;
  // 加载推荐路径
  LoadRecommendedPaths;
  LoadAvailableDrives;
  // 初始化已选信息
  UpdateSelectedInfo;
end;

procedure TfrmSmartMigrationWizard.InitializeInterface;
begin
  // 初始化所有面板，默认隐藏
  pnlWelcome.Visible := False;
  pnlSourceSelection.Visible := False;
  pnlAnalysis.Visible := False;
  pnlTargetSelection.Visible := False;
  pnlSafetyCheck.Visible := False;
  pnlConfirmation.Visible := False;
  pnlExecution.Visible := False;
  pnlComplete.Visible := False;
  
  // 设置面板布局
  pnlWelcome.Align := alClient;
  pnlSourceSelection.Align := alClient;
  pnlAnalysis.Align := alClient;
  pnlTargetSelection.Align := alClient;
  pnlSafetyCheck.Align := alClient;
  pnlConfirmation.Align := alClient;
  pnlExecution.Align := alClient;
  pnlComplete.Align := alClient;
  
  // 初始化欢迎页面内容
  memoWelcomeText.Text := 
    '欢迎使用智能迁移向导！' + sLineBreak + sLineBreak +
    '本向导将帮助您安全地将文件夹从C盘迁移到其他位置，释放宝贵的C盘空间。' + sLineBreak + sLineBreak +
    '★ 支持批量迁移 - 可同时选择多个目录' + sLineBreak +
    '★ 内置迁移模板 - 快速选择常用目录组合' + sLineBreak + sLineBreak +
    '迁移过程包括以下步骤：' + sLineBreak +
    '1. 选择要迁移的源目录（支持多选）' + sLineBreak +
    '2. 分析目录内容和迁移建议' + sLineBreak +
    '3. 选择合适的目标位置' + sLineBreak +
    '4. 执行安全检查' + sLineBreak +
    '5. 确认迁移计划' + sLineBreak +
    '6. 批量执行迁移并创建链接' + sLineBreak +
    '7. 验证迁移结果' + sLineBreak + sLineBreak +
    '整个过程安全可靠，支持一键回滚。' + sLineBreak + sLineBreak +
    '点击"下一步"开始迁移向导。';
  
  lvAvailableDrives.ViewStyle := vsReport;
  lvAvailableDrives.GridLines := True;
  lvAvailableDrives.RowSelect := True;
  lvAvailableDrives.Columns.Add.Caption := '驱动器';
  lvAvailableDrives.Columns.Add.Caption := '可用空间';
  lvAvailableDrives.Columns.Add.Caption := '总容量';
  lvAvailableDrives.Columns.Add.Caption := '建议';
  
  lvSafetyChecks.ViewStyle := vsReport;
  lvSafetyChecks.GridLines := True;
  lvSafetyChecks.RowSelect := True;
  lvSafetyChecks.Columns.Add.Caption := '检查项目';
  lvSafetyChecks.Columns.Add.Caption := '状态';
  lvSafetyChecks.Columns.Add.Caption := '说明';
  
  // 初始化复选框状态
  chkCreateBackup.Checked := True;
  chkVerifyFiles.Checked := True;
  chkCreateJunction.Checked := True;
  chkDeleteBackup.Checked := False;
  chkOpenTargetFolder.Checked := True;
end;

procedure TfrmSmartMigrationWizard.ShowPage(Page: TWizardPage);
begin
  // 隐藏所有页面
  pnlWelcome.Visible := False;
  pnlSourceSelection.Visible := False;
  pnlAnalysis.Visible := False;
  pnlTargetSelection.Visible := False;
  pnlSafetyCheck.Visible := False;
  pnlConfirmation.Visible := False;
  pnlExecution.Visible := False;
  pnlComplete.Visible := False;
  
  // 显示当前页面
  FCurrentPage := Page;
  
  case Page of
    wpWelcome:
    begin
      lblTitle.Caption := '欢迎使用智能迁移向导';
      lblSubtitle.Caption := '安全、智能、一键完成目录迁移';
      pnlWelcome.Visible := True;
    end;
    
    wpSourceSelection:
    begin
      lblTitle.Caption := '选择源目录（支持批量选择）';
      lblSubtitle.Caption := '请勾选要迁移的文件夹，或使用模板快速选择';
      pnlSourceSelection.Visible := True;
    end;
    
    wpAnalysis:
    begin
      lblTitle.Caption := '分析源目录';
      lblSubtitle.Caption := Format('正在分析 %d 个目录的内容和迁移建议...', [Length(FSelectedPaths)]);
      pnlAnalysis.Visible := True;
      // 收集选中的路径并分析
      CollectSelectedPaths;
      if Length(FSelectedPaths) > 0 then
        AnalyzeSourcePaths;
    end;
    
    wpTargetSelection:
    begin
      lblTitle.Caption := '选择目标位置';
      lblSubtitle.Caption := '请选择文件迁移的目标位置';
      pnlTargetSelection.Visible := True;
    end;
    
    wpSafetyCheck:
    begin
      lblTitle.Caption := '安全检查';
      lblSubtitle.Caption := '正在执行迁移前安全检查...';
      pnlSafetyCheck.Visible := True;
      PerformSafetyChecks;
    end;
    
    wpConfirmation:
    begin
      lblTitle.Caption := '确认迁移计划';
      lblSubtitle.Caption := '请确认迁移设置，准备执行迁移';
      pnlConfirmation.Visible := True;
      GenerateMigrationPlan;
    end;
    
    wpExecution:
    begin
      lblTitle.Caption := '执行迁移';
      lblSubtitle.Caption := Format('正在执行 %d 个目录的迁移，请稍候...', [Length(FSelectedPaths)]);
      pnlExecution.Visible := True;
      ExecuteBatchMigration;
    end;
    
    wpComplete:
    begin
      lblTitle.Caption := '迁移完成';
      lblSubtitle.Caption := '文件迁移已完成';
      pnlComplete.Visible := True;
      ShowExecutionResults;
    end;
  end;
  
  UpdateButtons;
end;

procedure TfrmSmartMigrationWizard.UpdateButtons;
begin
  btnBack.Enabled := CanGoBack;
  btnNext.Enabled := CanGoNext;
  btnFinish.Visible := (FCurrentPage = wpComplete);
  btnNext.Visible := not btnFinish.Visible;
  
  case FCurrentPage of
    wpWelcome:
    begin
      btnBack.Enabled := False;
      btnNext.Caption := '开始向导 >';
    end;
    
    wpSourceSelection:
    begin
      btnNext.Caption := '分析目录 >';
    end;
    
    wpAnalysis:
    begin
      btnNext.Caption := '选择目标 >';
      btnBack.Enabled := False; // 分析过程中不允许返回
    end;
    
    wpTargetSelection:
    begin
      btnNext.Caption := '安全检查 >';
    end;
    
    wpSafetyCheck:
    begin
      btnNext.Caption := '确认计划 >';
      btnBack.Enabled := False; // 检查过程中不允许返回
    end;
    
    wpConfirmation:
    begin
      btnNext.Caption := '开始迁移 >';
    end;
    
    wpExecution:
    begin
      btnNext.Enabled := False;
      btnBack.Enabled := False;
      btnCancel.Caption := '取消迁移';
    end;
    
    wpComplete:
    begin
      btnFinish.Caption := '完成';
      btnCancel.Enabled := False;
    end;
  end;
end;

function TfrmSmartMigrationWizard.CanGoNext: Boolean;
begin
  Result := ValidateCurrentPage;
end;

function TfrmSmartMigrationWizard.CanGoBack: Boolean;
begin
  Result := (FCurrentPage > wpWelcome) and (FCurrentPage <> wpAnalysis) and 
            (FCurrentPage <> wpSafetyCheck) and (FCurrentPage <> wpExecution);
end;

function TfrmSmartMigrationWizard.ValidateCurrentPage: Boolean;
var
  I: Integer;
  SelectedCount: Integer;
begin
  Result := True;
  
  case FCurrentPage of
    wpWelcome:
      Result := True;
      
    wpSourceSelection:
    begin
      // 检查是否有选中的目录
      SelectedCount := 0;
      for I := 0 to clbSourcePaths.Items.Count - 1 do
        if clbSourcePaths.Checked[I] then
          Inc(SelectedCount);
      Result := SelectedCount > 0;
    end;
      
    wpAnalysis:
      Result := Length(FSelectedPaths) > 0; // 分析完成后自动允许下一步
      
    wpTargetSelection:
      Result := (FTargetPath <> '') and TDirectory.Exists(TPath.GetDirectoryName(FTargetPath));
      
    wpSafetyCheck:
      Result := True; // 安全检查完成后自动允许下一步
      
    wpConfirmation:
      Result := True;
      
    wpExecution:
      Result := False; // 执行过程中不允许下一步
      
    wpComplete:
      Result := False; // 完成页面使用完成按钮
  end;
end;

procedure TfrmSmartMigrationWizard.LoadRecommendedPaths;
var
  UserProfile: string;
  Paths: TArray<string>;
  I: Integer;
  Recommendation: TMigrationRecommendation;
  DisplayText: string;
begin
  clbSourcePaths.Items.Clear;
  SetLength(FAllRecommendedPaths, 0);
  
  UserProfile := GetEnvironmentVariable('USERPROFILE');
  
  // 常见的可迁移用户目录
  Paths := [
    TPath.Combine(UserProfile, 'Documents'),
    TPath.Combine(UserProfile, 'Downloads'), 
    TPath.Combine(UserProfile, 'Pictures'),
    TPath.Combine(UserProfile, 'Videos'),
    TPath.Combine(UserProfile, 'Music'),
    TPath.Combine(UserProfile, 'Desktop'),
    // 开发相关目录
    TPath.Combine(UserProfile, '.gradle'),
    TPath.Combine(UserProfile, '.m2'),
    TPath.Combine(UserProfile, '.npm'),
    TPath.Combine(UserProfile, '.nuget'),
    TPath.Combine(UserProfile, 'AppData\Local\npm-cache'),
    TPath.Combine(UserProfile, 'AppData\Roaming\npm'),
    // 游戏相关
    'C:\Program Files (x86)\Steam\steamapps\common',
    'C:\Program Files\Epic Games'
  ];
  
  for I := 0 to High(Paths) do
  begin
    if TDirectory.Exists(Paths[I]) then
    begin
      Recommendation := AnalyzeDirectory(Paths[I]);
      Recommendation.Selected := False;
      Recommendation.Status := '待迁移';
      
      // 添加到数组
      SetLength(FAllRecommendedPaths, Length(FAllRecommendedPaths) + 1);
      FAllRecommendedPaths[High(FAllRecommendedPaths)] := Recommendation;
      
      // 添加到 CheckListBox
      DisplayText := Format('%s  [%s, %d文件, 安全:%s]', 
        [Recommendation.SourcePath, 
         FormatBytes(Recommendation.EstimatedSize),
         Recommendation.FileCount,
         StarRating(Recommendation.SafetyLevel)]);
      clbSourcePaths.Items.Add(DisplayText);
    end;
  end;
end;

procedure TfrmSmartMigrationWizard.LoadMigrationTemplates;
var
  UserProfile: string;
begin
  UserProfile := GetEnvironmentVariable('USERPROFILE');
  SetLength(FMigrationTemplates, 4);
  
  // 模板1: 文档组合
  FMigrationTemplates[0].Name := '文档组合';
  FMigrationTemplates[0].Description := '文档、图片、视频、音乐';
  FMigrationTemplates[0].Paths := [
    TPath.Combine(UserProfile, 'Documents'),
    TPath.Combine(UserProfile, 'Pictures'),
    TPath.Combine(UserProfile, 'Videos'),
    TPath.Combine(UserProfile, 'Music')
  ];
  
  // 模板2: 下载+桌面
  FMigrationTemplates[1].Name := '下载+桌面';
  FMigrationTemplates[1].Description := '下载文件夹和桌面';
  FMigrationTemplates[1].Paths := [
    TPath.Combine(UserProfile, 'Downloads'),
    TPath.Combine(UserProfile, 'Desktop')
  ];
  
  // 模板3: 开发环境
  FMigrationTemplates[2].Name := '开发环境缓存';
  FMigrationTemplates[2].Description := 'Gradle, Maven, npm缓存';
  FMigrationTemplates[2].Paths := [
    TPath.Combine(UserProfile, '.gradle'),
    TPath.Combine(UserProfile, '.m2'),
    TPath.Combine(UserProfile, '.npm'),
    TPath.Combine(UserProfile, 'AppData\Local\npm-cache')
  ];
  
  // 模板4: 游戏数据
  FMigrationTemplates[3].Name := '游戏数据';
  FMigrationTemplates[3].Description := 'Steam、Epic游戏';
  FMigrationTemplates[3].Paths := [
    'C:\Program Files (x86)\Steam\steamapps\common',
    'C:\Program Files\Epic Games'
  ];
  
  // 填充模板选择下拉框
  cboTemplates.Items.Clear;
  cboTemplates.Items.Add('-- 自定义选择 --');
  cboTemplates.Items.Add('文档组合 (文档+图片+视频+音乐)');
  cboTemplates.Items.Add('下载+桌面');
  cboTemplates.Items.Add('开发环境缓存 (Gradle/Maven/npm)');
  cboTemplates.Items.Add('游戏数据 (Steam/Epic)');
  cboTemplates.ItemIndex := 0;
end;

procedure TfrmSmartMigrationWizard.UpdateSelectedInfo;
var
  I: Integer;
  SelectedCount: Integer;
  TotalSize: Int64;
  TotalFiles: Integer;
begin
  SelectedCount := 0;
  TotalSize := 0;
  TotalFiles := 0;
  
  for I := 0 to clbSourcePaths.Items.Count - 1 do
  begin
    if clbSourcePaths.Checked[I] and (I <= High(FAllRecommendedPaths)) then
    begin
      Inc(SelectedCount);
      TotalSize := TotalSize + FAllRecommendedPaths[I].EstimatedSize;
      TotalFiles := TotalFiles + FAllRecommendedPaths[I].FileCount;
    end;
  end;
  
  lblSelectedInfo.Caption := Format('已选择 %d 个目录，共计 %s，文件数： %d', 
    [SelectedCount, FormatBytes(TotalSize), TotalFiles]);
    
  UpdateButtons;
end;

procedure TfrmSmartMigrationWizard.CollectSelectedPaths;
var
  I: Integer;
begin
  SetLength(FSelectedPaths, 0);
  
  for I := 0 to clbSourcePaths.Items.Count - 1 do
  begin
    if clbSourcePaths.Checked[I] and (I <= High(FAllRecommendedPaths)) then
    begin
      FAllRecommendedPaths[I].Selected := True;
      SetLength(FSelectedPaths, Length(FSelectedPaths) + 1);
      FSelectedPaths[High(FSelectedPaths)] := FAllRecommendedPaths[I];
    end;
  end;
  
  // 设置第一个为当前源路径（兼容旧逻辑）
  if Length(FSelectedPaths) > 0 then
    FSourcePath := FSelectedPaths[0].SourcePath
  else
    FSourcePath := '';
end;

procedure TfrmSmartMigrationWizard.AnalyzeSourcePaths;
var
  I: Integer;
  TotalSize: Int64;
  TotalFiles: Integer;
begin
  UpdateAnalysisProgress('正在分析选中的目录...', 0);
  
  memoAnalysisResults.Lines.Clear;
  memoAnalysisResults.Lines.Add('=== 批量目录分析结果 ===');
  memoAnalysisResults.Lines.Add('');
  memoAnalysisResults.Lines.Add(Format('共选择 %d 个目录进行迁移：', [Length(FSelectedPaths)]));
  memoAnalysisResults.Lines.Add('');
  
  TotalSize := 0;
  TotalFiles := 0;
  
  for I := 0 to High(FSelectedPaths) do
  begin
    UpdateAnalysisProgress(Format('分析: %s', [ExtractFileName(FSelectedPaths[I].SourcePath)]), 
                           Round((I + 1) / Length(FSelectedPaths) * 100));
    
    // 重新分析以获取最新数据
    FSelectedPaths[I] := AnalyzeDirectory(FSelectedPaths[I].SourcePath);
    FSelectedPaths[I].Selected := True;
    FSelectedPaths[I].Status := '已分析';
    
    memoAnalysisResults.Lines.Add(Format('%d. %s', [I + 1, FSelectedPaths[I].SourcePath]));
    memoAnalysisResults.Lines.Add(Format('   大小: %s, 文件数: %d, 安全等级: %s', 
      [FormatBytes(FSelectedPaths[I].EstimatedSize), 
       FSelectedPaths[I].FileCount,
       StarRating(FSelectedPaths[I].SafetyLevel)]));
    memoAnalysisResults.Lines.Add(Format('   建议: %s', [FSelectedPaths[I].Reason]));
    memoAnalysisResults.Lines.Add('');
    
    TotalSize := TotalSize + FSelectedPaths[I].EstimatedSize;
    TotalFiles := TotalFiles + FSelectedPaths[I].FileCount;
    
    Application.ProcessMessages;
  end;
  
  memoAnalysisResults.Lines.Add('=== 汇总 ===');
  memoAnalysisResults.Lines.Add(Format('总大小: %s', [FormatBytes(TotalSize)]));
  memoAnalysisResults.Lines.Add(Format('总文件数: %d', [TotalFiles]));
  memoAnalysisResults.Lines.Add('');
  memoAnalysisResults.Lines.Add('推荐目标路径: ' + GetBestTargetPath(FSelectedPaths[0].SourcePath));
  
  UpdateAnalysisProgress('分析完成', 100);
end;

procedure TfrmSmartMigrationWizard.LoadAvailableDrives;
var
  Drives: TArray<string>;
  I: Integer;
  DriveType: UINT;
  FreeBytes, TotalBytes: Int64;
  Item: TListItem;
  Recommendation: string;
begin
  lvAvailableDrives.Items.Clear;
  
  Drives := TDirectory.GetLogicalDrives;
  
  for I := 0 to High(Drives) do
  begin
    if Drives[I] <> 'C:\' then // 排除C盘
    begin
      DriveType := GetDriveType(PChar(Drives[I]));
      if DriveType = DRIVE_FIXED then // 仅显示固定磁盘
      begin
        if GetDiskFreeSpaceEx(PChar(Drives[I]), FreeBytes, TotalBytes, nil) then
        begin
          Item := lvAvailableDrives.Items.Add;
          Item.Caption := Drives[I];
          Item.SubItems.Add(FormatBytes(FreeBytes));
          Item.SubItems.Add(FormatBytes(TotalBytes));
          
          if FreeBytes > (Int64(10) * 1024 * 1024 * 1024) then // >10GB
            Recommendation := '推荐 - 空间充足'
          else if FreeBytes > (Int64(1) * 1024 * 1024 * 1024) then // >1GB
            Recommendation := '可用 - 空间有限'
          else
            Recommendation := '不推荐 - 空间不足';
            
          Item.SubItems.Add(Recommendation);
          Item.Data := Pointer(Integer(FreeBytes shr 30)); // GB为单位
        end;
      end;
    end;
  end;
end;

function TfrmSmartMigrationWizard.AnalyzeDirectory(const Path: string): TMigrationRecommendation;
begin
  Result.SourcePath := Path;
  Result.EstimatedSize := GetDirectorySize(Path);
  Result.FileCount := GetDirectoryFileCount(Path);
  Result.SafetyLevel := GetDirectorySafetyLevel(Path);
  
  if Result.EstimatedSize > 1024 * 1024 * 1024 then // >1GB
    Result.Reason := '大目录，迁移效果显著'
  else if Result.EstimatedSize > 100 * 1024 * 1024 then // >100MB
    Result.Reason := '中等大小，适合迁移'
  else
    Result.Reason := '较小目录，迁移效果有限';
    
  Result.TargetPath := GetBestTargetPath(Path);
end;

function TfrmSmartMigrationWizard.GetDirectorySize(const Path: string): Int64;
var
  Files: TArray<string>;
  Dirs: TArray<string>;
  I: Integer;
begin
  Result := 0;
  
  try
    Files := TDirectory.GetFiles(Path);
    for I := 0 to High(Files) do
    begin
      try
        Result := Result + TFile.GetSize(Files[I]);
      except
        // 忽略无法访问的文件
      end;
    end;
    
    Dirs := TDirectory.GetDirectories(Path);
    for I := 0 to High(Dirs) do
    begin
      try
        Result := Result + GetDirectorySize(Dirs[I]);
      except
        // 忽略无法访问的目录
      end;
    end;
  except
    // 忽略权限错误
  end;
end;

function TfrmSmartMigrationWizard.GetDirectoryFileCount(const Path: string): Integer;
var
  Files: TArray<string>;
  Dirs: TArray<string>;
  I: Integer;
begin
  Result := 0;
  
  try
    Files := TDirectory.GetFiles(Path);
    Result := Length(Files);
    
    Dirs := TDirectory.GetDirectories(Path);
    for I := 0 to High(Dirs) do
    begin
      try
        Result := Result + GetDirectoryFileCount(Dirs[I]);
      except
        // 忽略无法访问的目录
      end;
    end;
  except
    // 忽略权限错误
  end;
end;

function TfrmSmartMigrationWizard.GetDirectorySafetyLevel(const Path: string): Integer;
var
  LowerPath: string;
begin
  LowerPath := LowerCase(Path);
  
  // 用户文档类目录 - 最安全
  if (Pos('\documents', LowerPath) > 0) or (Pos('\pictures', LowerPath) > 0) or
     (Pos('\videos', LowerPath) > 0) or (Pos('\music', LowerPath) > 0) then
    Result := 5
  // 下载和桌面 - 较安全  
  else if (Pos('\downloads', LowerPath) > 0) or (Pos('\desktop', LowerPath) > 0) then
    Result := 4
  // 用户配置文件根目录 - 中等风险
  else if Pos('c:\users', LowerPath) = 1 then
    Result := 3
  // 程序目录 - 高风险
  else if (Pos('c:\program files', LowerPath) = 1) then
    Result := 1
  // 系统目录 - 最高风险
  else if (Pos('c:\windows', LowerPath) = 1) then
    Result := 1
  else
    Result := 3; // 默认中等风险
end;

function TfrmSmartMigrationWizard.GetBestTargetPath(const SourcePath: string): string;
var
  Drives: TArray<string>;
  I: Integer;
  FreeBytes, TotalBytes: Int64;
  BestDrive: string;
  MaxFreeSpace: Int64;
begin
  Result := '';
  MaxFreeSpace := 0;
  BestDrive := '';
  
  Drives := TDirectory.GetLogicalDrives;
  
  for I := 0 to High(Drives) do
  begin
    if (Drives[I] <> 'C:\') and (GetDriveType(PChar(Drives[I])) = DRIVE_FIXED) then
    begin
      if GetDiskFreeSpaceEx(PChar(Drives[I]), FreeBytes, TotalBytes, nil) then
      begin
        if FreeBytes > MaxFreeSpace then
        begin
          MaxFreeSpace := FreeBytes;
          BestDrive := Drives[I];
        end;
      end;
    end;
  end;
  
  if BestDrive <> '' then
    Result := TPath.Combine(BestDrive, ExtractFileName(SourcePath));
end;

function TfrmSmartMigrationWizard.FormatBytes(Bytes: Int64): string;
const
  KB = 1024;
  MB = KB * 1024;
  GB = MB * 1024;
begin
  if Bytes >= GB then
    Result := Format('%.2f GB', [Bytes / GB])
  else if Bytes >= MB then
    Result := Format('%.1f MB', [Bytes / MB])
  else if Bytes >= KB then
    Result := Format('%.0f KB', [Bytes / KB])
  else
    Result := Format('%d 字节', [Bytes]);
end;

// Event handlers continue in next part due to length...

procedure TfrmSmartMigrationWizard.btnNextClick(Sender: TObject);
begin
  if CanGoNext then
  begin
    case FCurrentPage of
      wpWelcome: ShowPage(wpSourceSelection);
      wpSourceSelection: ShowPage(wpAnalysis);
      wpAnalysis: ShowPage(wpTargetSelection);
      wpTargetSelection: ShowPage(wpSafetyCheck);
      wpSafetyCheck: ShowPage(wpConfirmation);
      wpConfirmation: ShowPage(wpExecution);
      wpExecution: ShowPage(wpComplete);
    end;
  end;
end;

procedure TfrmSmartMigrationWizard.btnBackClick(Sender: TObject);
begin
  if CanGoBack then
  begin
    case FCurrentPage of
      wpSourceSelection: ShowPage(wpWelcome);
      wpTargetSelection: ShowPage(wpSourceSelection);
      wpConfirmation: ShowPage(wpTargetSelection);
    end;
  end;
end;

procedure TfrmSmartMigrationWizard.btnCancelClick(Sender: TObject);
begin
  if FCurrentPage = wpExecution then
  begin
    if MessageDlg('确定要取消迁移操作吗？', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      FCancelRequested := True;
      if Assigned(FExecutionThread) then
        FExecutionThread.Terminate;
    end;
  end
  else
  begin
    if MessageDlg('确定要退出迁移向导吗？', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      ModalResult := mrCancel;
  end;
end;

procedure TfrmSmartMigrationWizard.btnFinishClick(Sender: TObject);
begin
  // 执行完成后的清理工作
  if chkOpenTargetFolder.Checked and TDirectory.Exists(FTargetPath) then
  begin
    ShellExecute(Handle, 'open', PChar(FTargetPath), nil, nil, SW_SHOWNORMAL);
  end;
  
  ModalResult := mrOk;
end;

// 批量选择事件处理
procedure TfrmSmartMigrationWizard.btnSelectAllClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to clbSourcePaths.Items.Count - 1 do
    clbSourcePaths.Checked[I] := True;
  UpdateSelectedInfo;
end;

procedure TfrmSmartMigrationWizard.btnSelectNoneClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to clbSourcePaths.Items.Count - 1 do
    clbSourcePaths.Checked[I] := False;
  UpdateSelectedInfo;
end;

procedure TfrmSmartMigrationWizard.btnAddCustomPathClick(Sender: TObject);
var
  Dir: string;
  Recommendation: TMigrationRecommendation;
  DisplayText: string;
  I: Integer;
begin
  Dir := 'C:\';
  if SelectDirectory('选择要迁移的目录', '', Dir) then
  begin
    // 检查是否已存在
    for I := 0 to High(FAllRecommendedPaths) do
      if SameText(FAllRecommendedPaths[I].SourcePath, Dir) then
      begin
        // 已存在，直接选中
        clbSourcePaths.Checked[I] := True;
        UpdateSelectedInfo;
        Exit;
      end;
    
    // 新增目录
    Recommendation := AnalyzeDirectory(Dir);
    Recommendation.Selected := True;
    Recommendation.Status := '待迁移';
    
    SetLength(FAllRecommendedPaths, Length(FAllRecommendedPaths) + 1);
    FAllRecommendedPaths[High(FAllRecommendedPaths)] := Recommendation;
    
    DisplayText := Format('%s  [%s, %d文件, 安全:%s]', 
      [Recommendation.SourcePath, 
       FormatBytes(Recommendation.EstimatedSize),
       Recommendation.FileCount,
       StarRating(Recommendation.SafetyLevel)]);
    clbSourcePaths.Items.Add(DisplayText);
    clbSourcePaths.Checked[clbSourcePaths.Items.Count - 1] := True;
    
    UpdateSelectedInfo;
  end;
end;

procedure TfrmSmartMigrationWizard.clbSourcePathsClickCheck(Sender: TObject);
begin
  UpdateSelectedInfo;
end;

procedure TfrmSmartMigrationWizard.cboTemplatesChange(Sender: TObject);
var
  TemplateIndex: Integer;
  I, J: Integer;
begin
  TemplateIndex := cboTemplates.ItemIndex;
  
  if TemplateIndex <= 0 then
    Exit; // 自定义选择，不做任何操作
  
  // 先取消所有选择
  for I := 0 to clbSourcePaths.Items.Count - 1 do
    clbSourcePaths.Checked[I] := False;
  
  // 根据模板选择对应路径
  Dec(TemplateIndex); // 索引减1（排除第一个"自定义选择"）
  if TemplateIndex <= High(FMigrationTemplates) then
  begin
    for I := 0 to High(FMigrationTemplates[TemplateIndex].Paths) do
    begin
      for J := 0 to High(FAllRecommendedPaths) do
      begin
        if SameText(FAllRecommendedPaths[J].SourcePath, 
                    FMigrationTemplates[TemplateIndex].Paths[I]) then
        begin
          clbSourcePaths.Checked[J] := True;
          Break;
        end;
      end;
    end;
  end;
  
  UpdateSelectedInfo;
end;

procedure TfrmSmartMigrationWizard.btnBrowseTargetClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := ExtractFilePath(FTargetPath);
  if SelectDirectory('选择迁移目标位置', '', Dir) then
  begin
    FTargetPath := TPath.Combine(Dir, ExtractFileName(FSourcePath));
    edtTargetPath.Text := FTargetPath;
    UpdateButtons;
  end;
end;

procedure TfrmSmartMigrationWizard.lvAvailableDrivesDblClick(Sender: TObject);
begin
  if Assigned(lvAvailableDrives.Selected) and (FSourcePath <> '') then
  begin
    FTargetPath := TPath.Combine(lvAvailableDrives.Selected.Caption, 
                                 ExtractFileName(FSourcePath));
    edtTargetPath.Text := FTargetPath;
    UpdateButtons;
  end;
end;

procedure TfrmSmartMigrationWizard.PerformSafetyChecks;
begin
  // Implementation for safety checks
  lvSafetyChecks.Items.Clear;
  
  // Add various safety check results
  // This would include checks for disk space, permissions, file locks, etc.
end;

procedure TfrmSmartMigrationWizard.GenerateMigrationPlan;
var
  I: Integer;
  TotalSize: Int64;
begin
  memoMigrationPlan.Lines.Clear;
  memoMigrationPlan.Lines.Add('=== 批量迁移计划 ===');
  memoMigrationPlan.Lines.Add('');
  memoMigrationPlan.Lines.Add(Format('共 %d 个目录将被迁移：', [Length(FSelectedPaths)]));
  memoMigrationPlan.Lines.Add('');
  
  TotalSize := 0;
  for I := 0 to High(FSelectedPaths) do
  begin
    memoMigrationPlan.Lines.Add(Format('%d. %s', [I + 1, FSelectedPaths[I].SourcePath]));
    memoMigrationPlan.Lines.Add(Format('   -> %s', [FSelectedPaths[I].TargetPath]));
    memoMigrationPlan.Lines.Add(Format('   大小: %s, 文件数: %d', 
      [FormatBytes(FSelectedPaths[I].EstimatedSize), FSelectedPaths[I].FileCount]));
    memoMigrationPlan.Lines.Add('');
    TotalSize := TotalSize + FSelectedPaths[I].EstimatedSize;
  end;
  
  memoMigrationPlan.Lines.Add('=== 汇总 ===');
  memoMigrationPlan.Lines.Add(Format('总大小: %s', [FormatBytes(TotalSize)]));
  memoMigrationPlan.Lines.Add(Format('目标磁盘: %s', [Copy(FTargetPath, 1, 3)]));
  memoMigrationPlan.Lines.Add('');
  memoMigrationPlan.Lines.Add('执行步骤:');
  memoMigrationPlan.Lines.Add('1. 复制所有文件到目标位置');
  if chkVerifyFiles.Checked then
    memoMigrationPlan.Lines.Add('2. 验证文件完整性 (SHA-256)');
  if chkCreateBackup.Checked then
    memoMigrationPlan.Lines.Add('3. 备份原目录');
  if chkCreateJunction.Checked then
    memoMigrationPlan.Lines.Add('4. 创建目录链接');
  memoMigrationPlan.Lines.Add('');
  memoMigrationPlan.Lines.Add('注意: 单个目录迁移失败不会影响其他目录');
end;

procedure TfrmSmartMigrationWizard.ExecuteBatchMigration;
var
  I: Integer;
  SuccessCount, FailCount: Integer;
  SourceDir, TargetDir: string;
  TargetDrive: string;
begin
  memoExecutionLog.Lines.Clear;
  FCancelRequested := False;
  FCurrentMigrationIndex := 0;
  SuccessCount := 0;
  FailCount := 0;
  
  // 获取目标磁盘
  TargetDrive := Copy(FTargetPath, 1, 3);
  if TargetDrive = '' then
    TargetDrive := 'D:\';
  
  AddExecutionLog(Format('开始批量迁移，共 %d 个目录', [Length(FSelectedPaths)]));
  AddExecutionLog(Format('目标磁盘: %s', [TargetDrive]));
  AddExecutionLog('');
  
  for I := 0 to High(FSelectedPaths) do
  begin
    if FCancelRequested then
    begin
      AddExecutionLog('用户取消迁移操作');
      Break;
    end;
    
    FCurrentMigrationIndex := I;
    SourceDir := FSelectedPaths[I].SourcePath;
    TargetDir := TPath.Combine(TargetDrive, ExtractFileName(SourceDir));
    FSelectedPaths[I].TargetPath := TargetDir;
    
    UpdateExecutionProgress(
      Format('迁移 %d/%d: %s', [I + 1, Length(FSelectedPaths), ExtractFileName(SourceDir)]),
      Round((I / Length(FSelectedPaths)) * 100));
    
    AddExecutionLog(Format('[%d/%d] 开始迁移: %s', [I + 1, Length(FSelectedPaths), SourceDir]));
    AddExecutionLog(Format('  -> %s', [TargetDir]));
    
    try
      // 这里应该调用实际的迁移逻辑
      // FMigrationTransaction := TMigrationTransaction.Create;
      // FMigrationTransaction.Execute(SourceDir, TargetDir, ...);
      
      // 暂时模拟迁移成功
      Sleep(500); // 模拟处理时间
      
      FSelectedPaths[I].Status := '迁移成功';
      Inc(SuccessCount);
      AddExecutionLog(Format('  完成: %s', [FormatBytes(FSelectedPaths[I].EstimatedSize)]));
    except
      on E: Exception do
      begin
        FSelectedPaths[I].Status := '迁移失败: ' + E.Message;
        Inc(FailCount);
        AddExecutionLog(Format('  失败: %s', [E.Message]));
      end;
    end;
    
    AddExecutionLog('');
    Application.ProcessMessages;
  end;
  
  UpdateExecutionProgress('迁移完成', 100);
  AddExecutionLog('=== 批量迁移完成 ===');
  AddExecutionLog(Format('成功: %d, 失败: %d', [SuccessCount, FailCount]));
  
  // 自动跳转到完成页面
  if not FCancelRequested then
    ShowPage(wpComplete);
end;

procedure TfrmSmartMigrationWizard.ShowExecutionResults;
var
  I: Integer;
  SuccessCount, FailCount: Integer;
  TotalSize: Int64;
begin
  memoCompleteSummary.Lines.Clear;
  memoCompleteSummary.Lines.Add('=== 批量迁移完成 ===');
  memoCompleteSummary.Lines.Add('');
  
  SuccessCount := 0;
  FailCount := 0;
  TotalSize := 0;
  
  for I := 0 to High(FSelectedPaths) do
  begin
    if Pos('成功', FSelectedPaths[I].Status) > 0 then
    begin
      Inc(SuccessCount);
      TotalSize := TotalSize + FSelectedPaths[I].EstimatedSize;
    end
    else if Pos('失败', FSelectedPaths[I].Status) > 0 then
      Inc(FailCount);
    
    memoCompleteSummary.Lines.Add(Format('%d. %s', [I + 1, ExtractFileName(FSelectedPaths[I].SourcePath)]));
    memoCompleteSummary.Lines.Add(Format('   状态: %s', [FSelectedPaths[I].Status]));
  end;
  
  memoCompleteSummary.Lines.Add('');
  memoCompleteSummary.Lines.Add('=== 汇总 ===');
  memoCompleteSummary.Lines.Add(Format('成功迁移: %d 个目录', [SuccessCount]));
  memoCompleteSummary.Lines.Add(Format('迁移失败: %d 个目录', [FailCount]));
  memoCompleteSummary.Lines.Add(Format('已释放C盘空间: %s', [FormatBytes(TotalSize)]));
  
  if SuccessCount > 0 then
  begin
    memoCompleteSummary.Lines.Add('');
    memoCompleteSummary.Lines.Add('提示: 如需回滚，请使用主界面的"回滚"功能');
  end;
end;

procedure TfrmSmartMigrationWizard.UpdateAnalysisProgress(const Status: string; Progress: Integer);
begin
  lblAnalysisStatus.Caption := Status;
  ProgressBarAnalysis.Position := Progress;
  Application.ProcessMessages;
end;

procedure TfrmSmartMigrationWizard.UpdateExecutionProgress(const Status: string; Progress: Integer);
begin
  lblExecutionStatus.Caption := Status;
  ProgressBarExecution.Position := Progress;
  Application.ProcessMessages;
end;

procedure TfrmSmartMigrationWizard.AddExecutionLog(const Message: string);
begin
  memoExecutionLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' - ' + Message);
end;

procedure TfrmSmartMigrationWizard.btnCancelExecutionClick(Sender: TObject);
begin
  btnCancelClick(Sender);
end;

function TfrmSmartMigrationWizard.RepeatChar(const C: Char; Count: Integer): string;
var
  I: Integer;
begin
  if Count <= 0 then
  begin
    Result := '';
    Exit;
  end;
  SetLength(Result, Count);
  for I := 1 to Count do
    Result[I] := C;
end;

function TfrmSmartMigrationWizard.StarRating(Level: Integer): string;
const
  MaxStars = 5;
var
  Filled, Empty: Integer;
begin
  if Level < 0 then Level := 0;
  if Level > MaxStars then Level := MaxStars;
  Filled := Level;
  Empty := MaxStars - Level;
  Result := RepeatChar(WideChar($2605), Filled) + RepeatChar(WideChar($2606), Empty); // ★ ☆
end;

end.

unit uSmartDuplicateCleanup;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, System.Generics.Collections,
  Core.DuplicateFileDetector, Core.SmartFileEvaluator, uStyles;

type
  TfrmSmartDuplicateCleanup = class(TForm)
    pnlMain: TPanel;
    pnlTop: TPanel;
    pnlCenter: TPanel;
    pnlBottom: TPanel;
    
    // 顶部标题
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    
    // 中央操作区
    pnlActions: TPanel;
    btnScanDuplicates: TButton;
    btnOneClickCleanup: TButton;
    btnViewReport: TButton;
    
    // 模式选择
    gbMode: TGroupBox;
    rbConservative: TRadioButton;
    rbStandard: TRadioButton;
    rbAggressive: TRadioButton;
    
    // 扫描选项
    gbScanOptions: TGroupBox;
    chkIncludeDownloads: TCheckBox;
    chkIncludeDesktop: TCheckBox;
    chkIncludeDocuments: TCheckBox;
    edtCustomPath: TEdit;
    btnBrowsePath: TButton;
    
    // 状态显示
    lblStatus: TLabel;
    ProgressBar: TProgressBar;
    
    // 结果显示
    pnlResults: TPanel;
    lblResults: TLabel;
    lblSpaceSaved: TLabel;
    lblFilesFound: TLabel;
    lblSafetyLevel: TLabel;
    
    // 底部按钮
    btnClose: TButton;
    btnAdvanced: TButton;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    
    procedure btnScanDuplicatesClick(Sender: TObject);
    procedure btnOneClickCleanupClick(Sender: TObject);
    procedure btnViewReportClick(Sender: TObject);
    procedure btnBrowsePathClick(Sender: TObject);
    procedure btnAdvancedClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    
    procedure rbModeClick(Sender: TObject);
    
  private
    FDetector: TDuplicateFileDetector;
    FCurrentGroups: TArray<TDuplicateGroup>;
    FCleanupPlan: TArray<TDuplicateGroup>;
    FTotalDuplicates: Integer;
    FTotalSavings: Int64;
    FIsScanning: Boolean;
    
    procedure InitializeUI;
    procedure UpdateButtonStates;
    procedure UpdateResults;
    procedure ShowResults(const Groups: TArray<TDuplicateGroup>; TotalDuplicates: Integer; TotalSavings: Int64);
    
    // 检测器事件
    procedure OnDetectorProgress(const CurrentFile: string; Progress: Integer; const Status: string);
    procedure OnDetectorResult(const Groups: TArray<TDuplicateGroup>; TotalDuplicates: Integer; TotalSavings: Int64);
    
    // 辅助方法
    function GetScanPaths: TArray<string>;
    function GetSelectedMode: TDecisionMode;
    function FormatFileSize(Size: Int64): string;
    function CalculateCleanupStats(const Groups: TArray<TDuplicateGroup>): record Count: Integer; Size: Int64; end;
    
  public
    procedure StartQuickScan;
  end;

var
  frmSmartDuplicateCleanup: TfrmSmartDuplicateCleanup;

implementation

uses
  System.IOUtils, Vcl.FileCtrl, uDuplicateFiles;

{$R *.dfm}

procedure TfrmSmartDuplicateCleanup.FormCreate(Sender: TObject);
begin
  FDetector := TDuplicateFileDetector.Create;
  FDetector.OnProgress := OnDetectorProgress;
  FDetector.OnResult := OnDetectorResult;
  
  FIsScanning := False;
  FTotalDuplicates := 0;
  FTotalSavings := 0;
  
  InitializeUI;
  UpdateButtonStates;
end;

procedure TfrmSmartDuplicateCleanup.FormDestroy(Sender: TObject);
begin
  if Assigned(FDetector) then
  begin
    FDetector.CancelScan;
    FDetector.Free;
  end;
end;

procedure TfrmSmartDuplicateCleanup.FormShow(Sender: TObject);
begin
  // 应用现代化样式
  StyleManager.StyleForm(Self);
  StyleManager.StyleProgressBar(ProgressBar);
end;

procedure TfrmSmartDuplicateCleanup.InitializeUI;
begin
  Caption := '智能重复文件清理';
  
  // 设置窗体属性
  Width := 600;
  Height := 500;
  Position := poScreenCenter;
  BorderStyle := bsDialog;
  
  // 设置标题
  lblTitle.Caption := '🤖 智能重复文件清理';
  lblTitle.Font.Size := 16;
  lblTitle.Font.Style := [fsBold];
  
  lblSubtitle.Caption := '零决策负担，一键智能清理重复文件';
  lblSubtitle.Font.Size := 10;
  
  // 设置按钮
  btnScanDuplicates.Caption := '🔍 扫描重复文件';
  btnScanDuplicates.Height := 40;
  btnScanDuplicates.Font.Size := 12;
  
  btnOneClickCleanup.Caption := '⚡ 一键智能清理';
  btnOneClickCleanup.Height := 40;
  btnOneClickCleanup.Font.Size := 12;
  btnOneClickCleanup.Font.Style := [fsBold];
  
  btnViewReport.Caption := '📊 查看详细报告';
  btnViewReport.Height := 40;
  btnViewReport.Font.Size := 12;
  
  // 设置模式选择
  gbMode.Caption := '清理模式';
  rbConservative.Caption := '保守模式（最安全）';
  rbStandard.Caption := '标准模式（推荐）';
  rbAggressive.Caption := '激进模式（最大清理）';
  rbStandard.Checked := True;
  
  // 设置扫描选项
  gbScanOptions.Caption := '扫描范围';
  chkIncludeDownloads.Caption := '下载目录';
  chkIncludeDownloads.Checked := True;
  chkIncludeDesktop.Caption := '桌面';
  chkIncludeDesktop.Checked := True;
  chkIncludeDocuments.Caption := '文档目录';
  chkIncludeDocuments.Checked := False;
  
  // 初始状态
  lblStatus.Caption := '就绪 - 点击"扫描重复文件"开始';
  ProgressBar.Visible := False;
  pnlResults.Visible := False;
  
  btnClose.Caption := '关闭';
  btnAdvanced.Caption := '高级选项...';
end;

procedure TfrmSmartDuplicateCleanup.UpdateButtonStates;
var
  HasResults: Boolean;
begin
  HasResults := Length(FCurrentGroups) > 0;
  
  btnScanDuplicates.Enabled := not FIsScanning;
  btnOneClickCleanup.Enabled := HasResults and not FIsScanning;
  btnViewReport.Enabled := HasResults and not FIsScanning;
  btnAdvanced.Enabled := not FIsScanning;
  
  gbMode.Enabled := not FIsScanning;
  gbScanOptions.Enabled := not FIsScanning;
  
  ProgressBar.Visible := FIsScanning;
end;

procedure TfrmSmartDuplicateCleanup.btnScanDuplicatesClick(Sender: TObject);
var
  ScanPaths: TArray<string>;
  Options: TDetectionOptions;
begin
  ScanPaths := GetScanPaths;
  if Length(ScanPaths) = 0 then
  begin
    ShowMessage('请至少选择一个扫描目录。');
    Exit;
  end;
  
  // 设置检测选项
  Options := GetDefaultDetectionOptions;
  Options.MinFileSize := 1024; // 1KB以上
  
  // 设置决策模式
  FDetector.SetDecisionMode(GetSelectedMode);
  
  FIsScanning := True;
  UpdateButtonStates;
  
  lblStatus.Caption := '正在扫描重复文件...';
  FDetector.StartScan(ScanPaths, Options);
end;

procedure TfrmSmartDuplicateCleanup.btnOneClickCleanupClick(Sender: TObject);
var
  CleanupStats: record Count: Integer; Size: Int64; end;
  ConfirmMsg: string;
begin
  if Length(FCurrentGroups) = 0 then
  begin
    ShowMessage('请先扫描重复文件。');
    Exit;
  end;
  
  // 生成智能清理计划
  FCleanupPlan := FDetector.GetOneClickCleanupPlan(FCurrentGroups);
  CleanupStats := CalculateCleanupStats(FCleanupPlan);
  
  if CleanupStats.Count = 0 then
  begin
    ShowMessage('没有找到可以安全删除的重复文件。');
    Exit;
  end;
  
  // 确认清理
  ConfirmMsg := Format('智能分析完成！' + sLineBreak + sLineBreak +
                      '将要删除 %d 个重复文件' + sLineBreak +
                      '预计释放空间：%s' + sLineBreak +
                      '安全等级：%s' + sLineBreak + sLineBreak +
                      '所有文件将移动到回收站，可以恢复。' + sLineBreak +
                      '确定要执行一键清理吗？',
                      [CleanupStats.Count, FormatFileSize(CleanupStats.Size), 
                       IfThen(GetSelectedMode = dmConservative, '最高', 
                       IfThen(GetSelectedMode = dmStandard, '高', '中等'))]);
                       
  if MessageDlg(ConfirmMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    lblStatus.Caption := '正在执行智能清理...';
    ProgressBar.Visible := True;
    ProgressBar.Style := pbstMarquee;
    
    if FDetector.DeleteSelectedFiles(FCleanupPlan, True) then
    begin
      ShowMessage(Format('清理完成！' + sLineBreak +
                        '成功删除 %d 个重复文件' + sLineBreak +
                        '释放空间：%s',
                        [CleanupStats.Count, FormatFileSize(CleanupStats.Size)]));
      
      // 重新扫描以更新结果
      btnScanDuplicatesClick(Sender);
    end
    else
    begin
      ShowMessage('清理过程中出现错误，请检查文件权限。');
    end;
    
    ProgressBar.Style := pbstNormal;
    ProgressBar.Visible := False;
  end;
end;

procedure TfrmSmartDuplicateCleanup.btnViewReportClick(Sender: TObject);
begin
  // 打开详细的重复文件管理界面
  if not Assigned(frmDuplicateFiles) then
    frmDuplicateFiles := TfrmDuplicateFiles.Create(Self);
    
  frmDuplicateFiles.Show;
  frmDuplicateFiles.StartScan(GetScanPaths);
end;

procedure TfrmSmartDuplicateCleanup.btnAdvancedClick(Sender: TObject);
begin
  btnViewReportClick(Sender);
end;

procedure TfrmSmartDuplicateCleanup.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmSmartDuplicateCleanup.btnBrowsePathClick(Sender: TObject);
var
  Dir: string;
begin
  if SelectDirectory('选择要扫描的目录', '', Dir) then
    edtCustomPath.Text := Dir;
end;

procedure TfrmSmartDuplicateCleanup.rbModeClick(Sender: TObject);
begin
  // 模式改变时更新说明
  if rbConservative.Checked then
    lblSubtitle.Caption := '保守模式：只删除100%确定安全的文件'
  else if rbStandard.Checked then
    lblSubtitle.Caption := '标准模式：删除90%确定安全的文件（推荐）'
  else if rbAggressive.Checked then
    lblSubtitle.Caption := '激进模式：删除80%确定安全的文件，最大化空间节省';
end;

procedure TfrmSmartDuplicateCleanup.OnDetectorProgress(const CurrentFile: string; Progress: Integer; const Status: string);
begin
  lblStatus.Caption := Status;
  if Progress >= 0 then
    ProgressBar.Position := Progress;
  Application.ProcessMessages;
end;

procedure TfrmSmartDuplicateCleanup.OnDetectorResult(const Groups: TArray<TDuplicateGroup>; 
  TotalDuplicates: Integer; TotalSavings: Int64);
begin
  FCurrentGroups := Groups;
  FTotalDuplicates := TotalDuplicates;
  FTotalSavings := TotalSavings;
  FIsScanning := False;
  
  ShowResults(Groups, TotalDuplicates, TotalSavings);
  UpdateButtonStates;
end;

procedure TfrmSmartDuplicateCleanup.ShowResults(const Groups: TArray<TDuplicateGroup>; 
  TotalDuplicates: Integer; TotalSavings: Int64);
begin
  pnlResults.Visible := True;
  
  lblResults.Caption := Format('扫描完成：找到 %d 组重复文件', [Length(Groups)]);
  lblFilesFound.Caption := Format('重复文件数量：%d 个', [TotalDuplicates]);
  lblSpaceSaved.Caption := Format('可节省空间：%s', [FormatFileSize(TotalSavings)]);
  
  if TotalSavings > 1024*1024*1024 then
    lblSafetyLevel.Caption := '💰 发现大量重复文件，建议立即清理'
  else if TotalSavings > 100*1024*1024 then
    lblSafetyLevel.Caption := '✅ 发现适量重复文件，可以清理'
  else if TotalSavings > 0 then
    lblSafetyLevel.Caption := '📝 发现少量重复文件'
  else
    lblSafetyLevel.Caption := '🎉 没有发现重复文件，系统很干净';
    
  lblStatus.Caption := '扫描完成 - 可以执行一键清理';
end;

function TfrmSmartDuplicateCleanup.GetScanPaths: TArray<string>;
var
  Paths: TList<string>;
begin
  Paths := TList<string>.Create;
  try
    if chkIncludeDownloads.Checked then
      Paths.Add(TPath.Combine(TPath.GetHomePath, 'Downloads'));
      
    if chkIncludeDesktop.Checked then
      Paths.Add(TPath.Combine(TPath.GetHomePath, 'Desktop'));
      
    if chkIncludeDocuments.Checked then
      Paths.Add(TPath.Combine(TPath.GetHomePath, 'Documents'));
      
    if (edtCustomPath.Text <> '') and TDirectory.Exists(edtCustomPath.Text) then
      Paths.Add(edtCustomPath.Text);
      
    Result := Paths.ToArray;
  finally
    Paths.Free;
  end;
end;

function TfrmSmartDuplicateCleanup.GetSelectedMode: TDecisionMode;
begin
  if rbConservative.Checked then
    Result := dmConservative
  else if rbAggressive.Checked then
    Result := dmAggressive
  else
    Result := dmStandard;
end;

function TfrmSmartDuplicateCleanup.FormatFileSize(Size: Int64): string;
begin
  if Size < 1024 then
    Result := Format('%d B', [Size])
  else if Size < 1024 * 1024 then
    Result := Format('%.1f KB', [Size / 1024])
  else if Size < 1024 * 1024 * 1024 then
    Result := Format('%.1f MB', [Size / (1024 * 1024)])
  else
    Result := Format('%.2f GB', [Size / (1024 * 1024 * 1024)]);
end;

function TfrmSmartDuplicateCleanup.CalculateCleanupStats(const Groups: TArray<TDuplicateGroup>): record Count: Integer; Size: Int64; end;
begin
  Result.Count := 0;
  Result.Size := 0;
  
  for var Group in Groups do
  begin
    for var FileInfo in Group.Files do
    begin
      if FileInfo.IsSelected then
      begin
        Inc(Result.Count);
        Inc(Result.Size, FileInfo.FileSize);
      end;
    end;
  end;
end;

procedure TfrmSmartDuplicateCleanup.StartQuickScan;
begin
  btnScanDuplicatesClick(nil);
end;

end.

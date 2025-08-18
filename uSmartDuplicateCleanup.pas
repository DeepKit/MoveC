unit uSmartDuplicateCleanup;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, System.Generics.Collections,
  uStyles;

type
  // 简化的决策模式枚举
  TDecisionMode = (dmConservative, dmStandard, dmAggressive);

  // 简化的重复文件组类型
  TDuplicateGroup = record
    Files: TArray<string>;
    Size: Int64;
  end;

  // 清理统计类型
  TCleanupStats = record
    Count: Integer;
    Size: Int64;
  end;

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
    // 简化版本 - 暂时移除复杂功能
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
    function CalculateCleanupStats(const Groups: TArray<TDuplicateGroup>): TCleanupStats;
    
  public
    procedure StartQuickScan;
  end;

var
  frmSmartDuplicateCleanup: TfrmSmartDuplicateCleanup;

implementation

uses
  System.IOUtils, Vcl.FileCtrl;

{$R *.dfm}

procedure TfrmSmartDuplicateCleanup.FormCreate(Sender: TObject);
begin
  // 简化版本 - 暂时移除复杂功能
  FIsScanning := False;
  FTotalDuplicates := 0;
  FTotalSavings := 0;
  
  InitializeUI;
  UpdateButtonStates;
end;

procedure TfrmSmartDuplicateCleanup.FormDestroy(Sender: TObject);
begin
  // 简化版本 - 无需清理
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
  HasResults := False; // 简化版本 - 无结果
  
  btnScanDuplicates.Enabled := not FIsScanning;
  btnOneClickCleanup.Enabled := HasResults and not FIsScanning;
  btnViewReport.Enabled := HasResults and not FIsScanning;
  btnAdvanced.Enabled := not FIsScanning;
  
  gbMode.Enabled := not FIsScanning;
  gbScanOptions.Enabled := not FIsScanning;
  
  ProgressBar.Visible := FIsScanning;
end;

procedure TfrmSmartDuplicateCleanup.btnScanDuplicatesClick(Sender: TObject);
begin
  // 简化版本 - 显示功能开发中的消息
  ShowMessage('智能重复文件清理功能正在开发中...' + sLineBreak +
              '当前版本提供基础的目录迁移和系统清理功能。' + sLineBreak +
              '重复文件清理功能将在后续版本中完善。');
end;

procedure TfrmSmartDuplicateCleanup.btnOneClickCleanupClick(Sender: TObject);
begin
  // 简化版本 - 显示功能开发中的消息
  ShowMessage('一键智能清理功能正在开发中...' + sLineBreak +
              '请使用主界面的系统清理功能进行基础清理。');

end;

procedure TfrmSmartDuplicateCleanup.btnViewReportClick(Sender: TObject);
begin
  // 简化版本 - 显示功能开发中的消息
  ShowMessage('详细报告功能正在开发中...');
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
  // 简化版本 - 不处理结果
  FTotalDuplicates := TotalDuplicates;
  FTotalSavings := TotalSavings;
  FIsScanning := False;
  UpdateButtonStates;
end;

procedure TfrmSmartDuplicateCleanup.ShowResults(const Groups: TArray<TDuplicateGroup>;
  TotalDuplicates: Integer; TotalSavings: Int64);
begin
  // 简化版本 - 不显示结果
end;


function TfrmSmartDuplicateCleanup.GetScanPaths: TArray<string>;
begin
  // 简化版本 - 返回空数组
  SetLength(Result, 0);
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

function TfrmSmartDuplicateCleanup.CalculateCleanupStats(const Groups: TArray<TDuplicateGroup>): TCleanupStats;
begin
  // 简化版本 - 返回空统计
  Result.Count := 0;
  Result.Size := 0;
end;

procedure TfrmSmartDuplicateCleanup.StartQuickScan;
begin
  btnScanDuplicatesClick(nil);
end;

// 添加缺少的方法实现
procedure TfrmSmartDuplicateCleanup.UpdateResults;
begin
  // 简化版本 - 不更新结果
end;





end.

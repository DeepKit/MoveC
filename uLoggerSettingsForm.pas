unit uLoggerSettingsForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.Samples.Spin, uLogger;

type
  TfrmLoggerSettings = class(TForm)
    pnlMain: TPanel;
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlSettings: TPanel;
    pgcSettings: TPageControl;
    tsGeneral: TTabSheet;
    tsAdvanced: TTabSheet;
    grpLogOutput: TGroupBox;
    chkLogToFile: TCheckBox;
    chkLogToDebug: TCheckBox;
    chkLogToConsole: TCheckBox;
    grpLogLevel: TGroupBox;
    rbDebug: TRadioButton;
    rbInfo: TRadioButton;
    rbWarning: TRadioButton;
    rbError: TRadioButton;
    rbCritical: TRadioButton;
    grpLogFiles: TGroupBox;
    lblLogDirectory: TLabel;
    edtLogDirectory: TEdit;
    btnBrowseDirectory: TButton;
    lblLogFileName: TLabel;
    edtLogFileName: TEdit;
    lblMaxFileSize: TLabel;
    edtMaxFileSize: TEdit;
    lblMaxFileSizeUnit: TLabel;
    lblMaxFiles: TLabel;
    sedMaxFiles: TSpinEdit;
    grpPerformance: TGroupBox;
    chkEnableCache: TCheckBox;
    lblCacheSize: TLabel;
    sedCacheSize: TSpinEdit;
    lblAutoFlushInterval: TLabel;
    sedAutoFlushInterval: TSpinEdit;
    lblAutoFlushUnit: TLabel;
    grpStatistics: TGroupBox;
    lblCurrentLogCount: TLabel;
    lblLogFilesCount: TLabel;
    btnClearLogs: TButton;
    btnViewLogs: TButton;
    btnExportLogs: TButton;
    pnlButtons: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    btnApply: TButton;
    btnReset: TButton;
    btnTest: TButton;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure btnTestClick(Sender: TObject);
    procedure btnBrowseDirectoryClick(Sender: TObject);
    procedure btnClearLogsClick(Sender: TObject);
    procedure btnViewLogsClick(Sender: TObject);
    procedure btnExportLogsClick(Sender: TObject);
    procedure chkEnableCacheClick(Sender: TObject);
    procedure chkLogToFileClick(Sender: TObject);
    
  private
    FOriginalConfig: TLoggerConfig;
    FCurrentConfig: TLoggerConfig;
    
    procedure LoadCurrentConfig;
    procedure SaveCurrentConfig;
    procedure ApplyCurrentConfig;
    procedure ResetToDefaults;
    procedure UpdateControlStates;
    procedure UpdateStatistics;
    function GetFileSizeInMB(const ASize: Int64): Double;
    function SetFileSizeFromMB(const AMB: Double): Int64;
    procedure TestLogging;
    
  public
    procedure Initialize;
  end;

var
  frmLoggerSettings: TfrmLoggerSettings;

implementation

{$R *.dfm}

uses
  Vcl.FileCtrl, uLogManager;

{ TfrmLoggerSettings }

procedure TfrmLoggerSettings.FormCreate(Sender: TObject);
begin
  Caption := '日志设置';
  Width := 500;
  Height := 600;
  Position := poScreenCenter;
  BorderStyle := bsDialog;
  
  Initialize;
end;

procedure TfrmLoggerSettings.FormDestroy(Sender: TObject);
begin
  // 保存配置
  SaveCurrentConfig;
end;

procedure TfrmLoggerSettings.Initialize;
begin
  LoadCurrentConfig;
  FOriginalConfig := FCurrentConfig;
  UpdateControlStates;
  UpdateStatistics;
end;

procedure TfrmLoggerSettings.LoadCurrentConfig;
begin
  FCurrentConfig := GetLoggerConfig;
  
  // 常规设置
  chkLogToFile.Checked := FCurrentConfig.LogToFile;
  chkLogToDebug.Checked := FCurrentConfig.LogToDebug;
  chkLogToConsole.Checked := FCurrentConfig.LogToConsole;
  
  // 日志级别
  case FCurrentConfig.LogLevel of
    llDebug: rbDebug.Checked := True;
    llInfo: rbInfo.Checked := True;
    llWarning: rbWarning.Checked := True;
    llError: rbError.Checked := True;
    llCritical: rbCritical.Checked := True;
  else
    rbInfo.Checked := True;
  end;
  
  // 文件设置
  edtLogDirectory.Text := FCurrentConfig.LogDirectory;
  edtLogFileName.Text := FCurrentConfig.LogFileName;
  edtMaxFileSize.Text := Format('%.1f', [GetFileSizeInMB(FCurrentConfig.MaxFileSize)]);
  sedMaxFiles.Value := FCurrentConfig.MaxFiles;
  
  // 性能设置
  chkEnableCache.Checked := FCurrentConfig.EnableCache;
  sedCacheSize.Value := FCurrentConfig.CacheSize;
  sedAutoFlushInterval.Value := FCurrentConfig.AutoFlushInterval;
end;

procedure TfrmLoggerSettings.SaveCurrentConfig;
begin
  // 常规设置
  FCurrentConfig.LogToFile := chkLogToFile.Checked;
  FCurrentConfig.LogToDebug := chkLogToDebug.Checked;
  FCurrentConfig.LogToConsole := chkLogToConsole.Checked;
  
  // 日志级别
  if rbDebug.Checked then
    FCurrentConfig.LogLevel := llDebug
  else if rbInfo.Checked then
    FCurrentConfig.LogLevel := llInfo
  else if rbWarning.Checked then
    FCurrentConfig.LogLevel := llWarning
  else if rbError.Checked then
    FCurrentConfig.LogLevel := llError
  else if rbCritical.Checked then
    FCurrentConfig.LogLevel := llCritical;
  
  // 文件设置
  FCurrentConfig.LogDirectory := edtLogDirectory.Text;
  FCurrentConfig.LogFileName := edtLogFileName.Text;
  FCurrentConfig.MaxFileSize := SetFileSizeFromMB(StrToFloatDef(edtMaxFileSize.Text, 10));
  FCurrentConfig.MaxFiles := sedMaxFiles.Value;
  
  // 性能设置
  FCurrentConfig.EnableCache := chkEnableCache.Checked;
  FCurrentConfig.CacheSize := sedCacheSize.Value;
  FCurrentConfig.AutoFlushInterval := sedAutoFlushInterval.Value;
end;

procedure TfrmLoggerSettings.ApplyCurrentConfig;
begin
  SetLoggerConfig(FCurrentConfig);
end;

procedure TfrmLoggerSettings.ResetToDefaults;
begin
  // 默认配置
  FCurrentConfig.LogDirectory := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Logs');
  FCurrentConfig.LogFileName := 'MoveC.log';
  FCurrentConfig.LogLevel := llInfo;
  FCurrentConfig.LogToFile := True;
  FCurrentConfig.LogToDebug := IsDebugMode;
  FCurrentConfig.LogToConsole := False;
  FCurrentConfig.MaxFileSize := 10 * 1024 * 1024; // 10MB
  FCurrentConfig.MaxFiles := 5;
  FCurrentConfig.EnableCache := True;
  FCurrentConfig.CacheSize := 1000;
  FCurrentConfig.AutoFlushInterval := 30;
  
  LoadCurrentConfig;
  UpdateControlStates;
end;

procedure TfrmLoggerSettings.UpdateControlStates;
begin
  // 文件相关控件状态
  edtLogDirectory.Enabled := chkLogToFile.Checked;
  btnBrowseDirectory.Enabled := chkLogToFile.Checked;
  edtLogFileName.Enabled := chkLogToFile.Checked;
  edtMaxFileSize.Enabled := chkLogToFile.Checked;
  lblMaxFileSizeUnit.Enabled := chkLogToFile.Checked;
  sedMaxFiles.Enabled := chkLogToFile.Checked;
  lblMaxFiles.Enabled := chkLogToFile.Checked;
  
  // 缓存相关控件状态
  sedCacheSize.Enabled := chkEnableCache.Checked;
  lblCacheSize.Enabled := chkEnableCache.Checked;
  
  // 自动刷新相关控件状态
  sedAutoFlushInterval.Enabled := chkEnableCache.Checked;
  lblAutoFlushInterval.Enabled := chkEnableCache.Checked;
  lblAutoFlushUnit.Enabled := chkEnableCache.Checked;
end;

procedure TfrmLoggerSettings.UpdateStatistics;
begin
  try
    lblCurrentLogCount.Caption := Format('当前缓存日志: %d 条', [TUnifiedLogger.Instance.GetLogCount]);
    lblLogFilesCount.Caption := Format('日志文件数量: %d 个', [Length(TUnifiedLogger.Instance.GetLogFiles)]);
  except
    on E: Exception do
    begin
      lblCurrentLogCount.Caption := '当前缓存日志: 未知';
      lblLogFilesCount.Caption := '日志文件数量: 未知';
    end;
  end;
end;

function TfrmLoggerSettings.GetFileSizeInMB(const ASize: Int64): Double;
begin
  Result := ASize / (1024.0 * 1024.0);
end;

function TfrmLoggerSettings.SetFileSizeFromMB(const AMB: Double): Int64;
begin
  Result := Round(AMB * 1024 * 1024);
end;

procedure TfrmLoggerSettings.TestLogging;
begin
  try
    LogInfo('LoggerSettings', '这是一条信息日志测试');
    LogWarning('LoggerSettings', '这是一条警告日志测试');
    LogError('LoggerSettings', '这是一条错误日志测试');
    if IsDebugMode then
      LogDebug('LoggerSettings', '这是一条调试日志测试');
    
    UpdateStatistics;
    ShowMessage('测试日志已写入！请检查日志输出。');
  except
    on E: Exception do
    begin
      ShowMessage('测试日志写入失败：' + E.Message);
    end;
  end;
end;

// 事件处理

procedure TfrmLoggerSettings.btnOKClick(Sender: TObject);
begin
  SaveCurrentConfig;
  ApplyCurrentConfig;
  ModalResult := mrOk;
end;

procedure TfrmLoggerSettings.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmLoggerSettings.btnApplyClick(Sender: TObject);
begin
  SaveCurrentConfig;
  ApplyCurrentConfig;
  UpdateStatistics;
  ShowMessage('设置已应用！');
end;

procedure TfrmLoggerSettings.btnResetClick(Sender: TObject);
begin
  if MessageDlg('确定要重置为默认设置吗？', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    ResetToDefaults;
    ShowMessage('已重置为默认设置！');
  end;
end;

procedure TfrmLoggerSettings.btnTestClick(Sender: TObject);
begin
  TestLogging;
end;

procedure TfrmLoggerSettings.btnBrowseDirectoryClick(Sender: TObject);
var
  Dir: string;
begin
  if SelectDirectory('选择日志目录', '', Dir) then
  begin
    edtLogDirectory.Text := Dir;
  end;
end;

procedure TfrmLoggerSettings.btnClearLogsClick(Sender: TObject);
begin
  if MessageDlg('确定要清空所有日志吗？此操作不可撤销！', mtWarning, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      TUnifiedLogger.Instance.Clear;
      UpdateStatistics;
      ShowMessage('日志已清空！');
    except
      on E: Exception do
      begin
        ShowMessage('清空日志失败：' + E.Message);
      end;
    end;
  end;
end;

procedure TfrmLoggerSettings.btnViewLogsClick(Sender: TObject);
begin
  try
    // 这里可以打开日志查看器
    ShowMessage('日志查看器功能将在后续版本中实现。');
  except
    on E: Exception do
    begin
      ShowMessage('无法打开日志查看器：' + E.Message);
    end;
  end;
end;

procedure TfrmLoggerSettings.btnExportLogsClick(Sender: TObject);
begin
  try
    // 这里可以实现日志导出功能
    ShowMessage('日志导出功能将在后续版本中实现。');
  except
    on E: Exception do
    begin
      ShowMessage('无法导出日志：' + E.Message);
    end;
  end;
end;

procedure TfrmLoggerSettings.chkEnableCacheClick(Sender: TObject);
begin
  UpdateControlStates;
end;

procedure TfrmLoggerSettings.chkLogToFileClick(Sender: TObject);
begin
  UpdateControlStates;
end;

end.

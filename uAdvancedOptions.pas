unit uAdvancedOptions;

{
  高级选项/设置对话框 - Advanced Options Dialog
  
  提供高级设置和配置选项，包括：
  - 迁移设置
  - 清理选项
  - 日志配置  
  - 安全设置
  - 界面主题
  - 性能调优
  
  作者: AI助手
  版本: 1.0
  日期: 2024
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.IOUtils, System.IniFiles, Vcl.Graphics, Vcl.Controls, Vcl.Forms, 
  Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons, 
  Vcl.CheckLst, Vcl.FileCtrl, Vcl.Samples.Spin, uLogManager;

type
  TAdvancedSettings = record
    // 迁移设置
    CreateBackupByDefault: Boolean;
    VerifyFilesAfterCopy: Boolean;
    UseMultiThreading: Boolean;
    MaxConcurrentOperations: Integer;
    BufferSize: Integer;
    
    // 清理设置
    AutoCleanupTemp: Boolean;
    AutoCleanupRecycleBin: Boolean;
    KeepRecentBackups: Boolean;
    BackupRetentionDays: Integer;
    
    // 日志设置
    LogLevel: TLogLevel;
    EnableFileLogging: Boolean;
    LogRotationSize: Integer;
    MaxLogFiles: Integer;
    
    // 安全设置
    RequireConfirmation: Boolean;
    RestrictedModeEnabled: Boolean;
    AllowSystemDirectories: Boolean;
    
    // 界面设置
    WindowStyle: string;
    UseModernColors: Boolean;
    ShowDetailedProgress: Boolean;
    AutoRefreshInterval: Integer;
    
    // 性能设置
    EnableSystemMonitoring: Boolean;
    PerformanceOptimization: Boolean;
    MemoryUsageLimit: Integer;
  end;

  TfrmAdvancedOptions = class(TForm)
    // 主面板
    pnlMain: TPanel;
    
    // 标签页控制
    pgcSettings: TPageControl;
    
    // 迁移设置页
    tsMigration: TTabSheet;
    gbMigrationDefaults: TGroupBox;
    chkCreateBackupByDefault: TCheckBox;
    chkVerifyFilesAfterCopy: TCheckBox;
    chkUseMultiThreading: TCheckBox;
    lblMaxConcurrentOps: TLabel;
    seMaxConcurrentOps: TSpinEdit;
    lblBufferSize: TLabel;
    seBufferSize: TSpinEdit;
    lblBufferSizeKB: TLabel;
    
    // 清理设置页
    tsCleaning: TTabSheet;
    gbAutoCleanup: TGroupBox;
    chkAutoCleanupTemp: TCheckBox;
    chkAutoCleanupRecycleBin: TCheckBox;
    chkKeepRecentBackups: TCheckBox;
    lblBackupRetentionDays: TLabel;
    seBackupRetentionDays: TSpinEdit;
    lblDays: TLabel;
    
    // 日志设置页
    tsLogging: TTabSheet;
    gbLogSettings: TGroupBox;
    lblLogLevel: TLabel;
    cmbLogLevel: TComboBox;
    chkEnableFileLogging: TCheckBox;
    lblLogRotationSize: TLabel;
    seLogRotationSize: TSpinEdit;
    lblMB: TLabel;
    lblMaxLogFiles: TLabel;
    seMaxLogFiles: TSpinEdit;
    btnOpenLogFolder: TBitBtn;
    btnClearLogs: TBitBtn;
    
    // 安全设置页
    tsSecurity: TTabSheet;
    gbSecurityOptions: TGroupBox;
    chkRequireConfirmation: TCheckBox;
    chkRestrictedMode: TCheckBox;
    chkAllowSystemDirectories: TCheckBox;
    lblSecurityWarning: TLabel;
    
    // 界面设置页
    tsInterface: TTabSheet;
    gbAppearance: TGroupBox;
    lblWindowStyle: TLabel;
    cmbWindowStyle: TComboBox;
    chkUseModernColors: TCheckBox;
    chkShowDetailedProgress: TCheckBox;
    lblAutoRefreshInterval: TLabel;
    seAutoRefreshInterval: TSpinEdit;
    lblSeconds: TLabel;
    btnPreviewTheme: TBitBtn;
    
    // 性能设置页
    tsPerformance: TTabSheet;
    gbPerformanceOptions: TGroupBox;
    chkEnableSystemMonitoring: TCheckBox;
    chkPerformanceOptimization: TCheckBox;
    lblMemoryUsageLimit: TLabel;
    seMemoryUsageLimit: TSpinEdit;
    lblMBMemory: TLabel;
    btnOptimizeNow: TBitBtn;
    
    // 底部按钮
    pnlButtons: TPanel;
    btnOK: TBitBtn;
    btnCancel: TBitBtn;
    btnApply: TBitBtn;
    btnReset: TBitBtn;
    btnExport: TBitBtn;
    btnImport: TBitBtn;
    
    // 保存/加载对话框
    SaveDialog: TSaveDialog;
    OpenDialog: TOpenDialog;
    
    // 事件处理
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure btnImportClick(Sender: TObject);
    
    procedure btnOpenLogFolderClick(Sender: TObject);
    procedure btnClearLogsClick(Sender: TObject);
    procedure btnPreviewThemeClick(Sender: TObject);
    procedure btnOptimizeNowClick(Sender: TObject);
    
    procedure chkRestrictedModeClick(Sender: TObject);
    procedure cmbWindowStyleChange(Sender: TObject);
    
  private
    FSettings: TAdvancedSettings;
    FOriginalSettings: TAdvancedSettings;
    FSettingsFile: string;
    
    procedure InitializeInterface;
    procedure LoadSettings;
    procedure SaveSettings;
    procedure LoadSettingsFromControls;
    procedure ApplySettingsToControls;
    procedure ResetToDefaults;
    procedure ExportSettings;
    procedure ImportSettings;
    
    function GetSettingsFileName: string;
    function ValidateSettings: Boolean;
    procedure ShowSecurityWarning;
    
  public
    constructor Create(AOwner: TComponent); override;
    property Settings: TAdvancedSettings read FSettings;
  end;

  // 全局设置管理
  TSettingsManager = class
  private
    class var FInstance: TSettingsManager;
    FSettings: TAdvancedSettings;
    FSettingsFile: string;
    function GetSettings: TAdvancedSettings;
    procedure SetSettings(const Value: TAdvancedSettings);
    function GetSettingsFile: string;
  public
    constructor Create;
    destructor Destroy; override;
    
    class function Instance: TSettingsManager;
    
    procedure LoadSettings;
    procedure SaveSettings;
    procedure ResetToDefaults;
    
    property Settings: TAdvancedSettings read GetSettings write SetSettings;
    property SettingsFile: string read GetSettingsFile;
  end;

var
  frmAdvancedOptions: TfrmAdvancedOptions;

implementation

uses System.UITypes, Winapi.ShellAPI;

{$R *.dfm}

// TSettingsManager 实现

constructor TSettingsManager.Create;
begin
  inherited Create;
  FSettingsFile := TPath.Combine(ExtractFilePath(ParamStr(0)), 'MoveC.ini');
  ResetToDefaults;
  LoadSettings;
end;

destructor TSettingsManager.Destroy;
begin
  SaveSettings;
  inherited Destroy;
end;

class function TSettingsManager.Instance: TSettingsManager;
begin
  if not Assigned(FInstance) then
    FInstance := TSettingsManager.Create;
  Result := FInstance;
end;

function TSettingsManager.GetSettings: TAdvancedSettings;
begin
  Result := FSettings;
end;

procedure TSettingsManager.SetSettings(const Value: TAdvancedSettings);
begin
  FSettings := Value;
end;

function TSettingsManager.GetSettingsFile: string;
begin
  Result := FSettingsFile;
end;

procedure TSettingsManager.ResetToDefaults;
begin
  // 迁移设置默认值
  FSettings.CreateBackupByDefault := True;
  FSettings.VerifyFilesAfterCopy := True;
  FSettings.UseMultiThreading := True;
  FSettings.MaxConcurrentOperations := 4;
  FSettings.BufferSize := 1024; // 1MB
  
  // 清理设置默认值
  FSettings.AutoCleanupTemp := False;
  FSettings.AutoCleanupRecycleBin := False;
  FSettings.KeepRecentBackups := True;
  FSettings.BackupRetentionDays := 30;
  
  // 日志设置默认值
  FSettings.LogLevel := llInfo;
  FSettings.EnableFileLogging := True;
  FSettings.LogRotationSize := 10; // 10MB
  FSettings.MaxLogFiles := 5;
  
  // 安全设置默认值
  FSettings.RequireConfirmation := True;
  FSettings.RestrictedModeEnabled := False;
  FSettings.AllowSystemDirectories := False;
  
  // 界面设置默认值
  FSettings.WindowStyle := 'Modern';
  FSettings.UseModernColors := True;
  FSettings.ShowDetailedProgress := True;
  FSettings.AutoRefreshInterval := 5;
  
  // 性能设置默认值
  FSettings.EnableSystemMonitoring := True;
  FSettings.PerformanceOptimization := True;
  FSettings.MemoryUsageLimit := 512; // 512MB
end;

procedure TSettingsManager.LoadSettings;
var
  Ini: TIniFile;
begin
  if not TFile.Exists(FSettingsFile) then
  begin
    SaveSettings; // 创建默认设置文件
    Exit;
  end;
    
  Ini := TIniFile.Create(FSettingsFile);
  try
    // 迁移设置
    FSettings.CreateBackupByDefault := Ini.ReadBool('Migration', 'CreateBackupByDefault', FSettings.CreateBackupByDefault);
    FSettings.VerifyFilesAfterCopy := Ini.ReadBool('Migration', 'VerifyFilesAfterCopy', FSettings.VerifyFilesAfterCopy);
    FSettings.UseMultiThreading := Ini.ReadBool('Migration', 'UseMultiThreading', FSettings.UseMultiThreading);
    FSettings.MaxConcurrentOperations := Ini.ReadInteger('Migration', 'MaxConcurrentOperations', FSettings.MaxConcurrentOperations);
    FSettings.BufferSize := Ini.ReadInteger('Migration', 'BufferSize', FSettings.BufferSize);
    
    // 清理设置
    FSettings.AutoCleanupTemp := Ini.ReadBool('Cleanup', 'AutoCleanupTemp', FSettings.AutoCleanupTemp);
    FSettings.AutoCleanupRecycleBin := Ini.ReadBool('Cleanup', 'AutoCleanupRecycleBin', FSettings.AutoCleanupRecycleBin);
    FSettings.KeepRecentBackups := Ini.ReadBool('Cleanup', 'KeepRecentBackups', FSettings.KeepRecentBackups);
    FSettings.BackupRetentionDays := Ini.ReadInteger('Cleanup', 'BackupRetentionDays', FSettings.BackupRetentionDays);
    
    // 日志设置
    FSettings.LogLevel := TLogLevel(Ini.ReadInteger('Logging', 'LogLevel', Integer(FSettings.LogLevel)));
    FSettings.EnableFileLogging := Ini.ReadBool('Logging', 'EnableFileLogging', FSettings.EnableFileLogging);
    FSettings.LogRotationSize := Ini.ReadInteger('Logging', 'LogRotationSize', FSettings.LogRotationSize);
    FSettings.MaxLogFiles := Ini.ReadInteger('Logging', 'MaxLogFiles', FSettings.MaxLogFiles);
    
    // 安全设置
    FSettings.RequireConfirmation := Ini.ReadBool('Security', 'RequireConfirmation', FSettings.RequireConfirmation);
    FSettings.RestrictedModeEnabled := Ini.ReadBool('Security', 'RestrictedModeEnabled', FSettings.RestrictedModeEnabled);
    FSettings.AllowSystemDirectories := Ini.ReadBool('Security', 'AllowSystemDirectories', FSettings.AllowSystemDirectories);
    
    // 界面设置
    FSettings.WindowStyle := Ini.ReadString('Interface', 'WindowStyle', FSettings.WindowStyle);
    FSettings.UseModernColors := Ini.ReadBool('Interface', 'UseModernColors', FSettings.UseModernColors);
    FSettings.ShowDetailedProgress := Ini.ReadBool('Interface', 'ShowDetailedProgress', FSettings.ShowDetailedProgress);
    FSettings.AutoRefreshInterval := Ini.ReadInteger('Interface', 'AutoRefreshInterval', FSettings.AutoRefreshInterval);
    
    // 性能设置
    FSettings.EnableSystemMonitoring := Ini.ReadBool('Performance', 'EnableSystemMonitoring', FSettings.EnableSystemMonitoring);
    FSettings.PerformanceOptimization := Ini.ReadBool('Performance', 'PerformanceOptimization', FSettings.PerformanceOptimization);
    FSettings.MemoryUsageLimit := Ini.ReadInteger('Performance', 'MemoryUsageLimit', FSettings.MemoryUsageLimit);
  finally
    Ini.Free;
  end;
end;

procedure TSettingsManager.SaveSettings;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FSettingsFile);
  try
    // 迁移设置
    Ini.WriteBool('Migration', 'CreateBackupByDefault', FSettings.CreateBackupByDefault);
    Ini.WriteBool('Migration', 'VerifyFilesAfterCopy', FSettings.VerifyFilesAfterCopy);
    Ini.WriteBool('Migration', 'UseMultiThreading', FSettings.UseMultiThreading);
    Ini.WriteInteger('Migration', 'MaxConcurrentOperations', FSettings.MaxConcurrentOperations);
    Ini.WriteInteger('Migration', 'BufferSize', FSettings.BufferSize);
    
    // 清理设置
    Ini.WriteBool('Cleanup', 'AutoCleanupTemp', FSettings.AutoCleanupTemp);
    Ini.WriteBool('Cleanup', 'AutoCleanupRecycleBin', FSettings.AutoCleanupRecycleBin);
    Ini.WriteBool('Cleanup', 'KeepRecentBackups', FSettings.KeepRecentBackups);
    Ini.WriteInteger('Cleanup', 'BackupRetentionDays', FSettings.BackupRetentionDays);
    
    // 日志设置
    Ini.WriteInteger('Logging', 'LogLevel', Integer(FSettings.LogLevel));
    Ini.WriteBool('Logging', 'EnableFileLogging', FSettings.EnableFileLogging);
    Ini.WriteInteger('Logging', 'LogRotationSize', FSettings.LogRotationSize);
    Ini.WriteInteger('Logging', 'MaxLogFiles', FSettings.MaxLogFiles);
    
    // 安全设置
    Ini.WriteBool('Security', 'RequireConfirmation', FSettings.RequireConfirmation);
    Ini.WriteBool('Security', 'RestrictedModeEnabled', FSettings.RestrictedModeEnabled);
    Ini.WriteBool('Security', 'AllowSystemDirectories', FSettings.AllowSystemDirectories);
    
    // 界面设置
    Ini.WriteString('Interface', 'WindowStyle', FSettings.WindowStyle);
    Ini.WriteBool('Interface', 'UseModernColors', FSettings.UseModernColors);
    Ini.WriteBool('Interface', 'ShowDetailedProgress', FSettings.ShowDetailedProgress);
    Ini.WriteInteger('Interface', 'AutoRefreshInterval', FSettings.AutoRefreshInterval);
    
    // 性能设置
    Ini.WriteBool('Performance', 'EnableSystemMonitoring', FSettings.EnableSystemMonitoring);
    Ini.WriteBool('Performance', 'PerformanceOptimization', FSettings.PerformanceOptimization);
    Ini.WriteInteger('Performance', 'MemoryUsageLimit', FSettings.MemoryUsageLimit);
  finally
    Ini.Free;
  end;
end;

// TfrmAdvancedOptions 实现

constructor TfrmAdvancedOptions.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSettingsFile := GetSettingsFileName;
  InitializeInterface;
  LoadSettings;
end;

procedure TfrmAdvancedOptions.FormCreate(Sender: TObject);
begin
  Caption := '高级选项 - C盘瘦身神器';
  Position := poScreenCenter;
  
  // 初始化对话框
  SaveDialog.Filter := '配置文件 (*.ini)|*.ini|所有文件 (*.*)|*.*';
  SaveDialog.DefaultExt := 'ini';
  OpenDialog.Filter := SaveDialog.Filter;
  OpenDialog.DefaultExt := SaveDialog.DefaultExt;
end;

procedure TfrmAdvancedOptions.FormShow(Sender: TObject);
begin
  // 显示当前设置
  ApplySettingsToControls;
end;

procedure TfrmAdvancedOptions.InitializeInterface;
begin
  // 初始化日志级别下拉框
  cmbLogLevel.Items.Clear;
  cmbLogLevel.Items.Add('调试');
  cmbLogLevel.Items.Add('信息');
  cmbLogLevel.Items.Add('警告');
  cmbLogLevel.Items.Add('错误');
  cmbLogLevel.Items.Add('严重');
  
  // 初始化窗口样式下拉框
  cmbWindowStyle.Items.Clear;
  cmbWindowStyle.Items.Add('Classic');
  cmbWindowStyle.Items.Add('Modern');
  cmbWindowStyle.Items.Add('Dark');
  cmbWindowStyle.Items.Add('Light');
  
  // 设置数值范围
  seMaxConcurrentOps.MinValue := 1;
  seMaxConcurrentOps.MaxValue := 16;
  
  seBufferSize.MinValue := 64;
  seBufferSize.MaxValue := 8192;
  
  seBackupRetentionDays.MinValue := 1;
  seBackupRetentionDays.MaxValue := 365;
  
  seLogRotationSize.MinValue := 1;
  seLogRotationSize.MaxValue := 100;
  
  seMaxLogFiles.MinValue := 1;
  seMaxLogFiles.MaxValue := 50;
  
  seAutoRefreshInterval.MinValue := 1;
  seAutoRefreshInterval.MaxValue := 60;
  
  seMemoryUsageLimit.MinValue := 128;
  seMemoryUsageLimit.MaxValue := 4096;
  
  // 设置安全警告文本
  lblSecurityWarning.Caption := 
    '警告: 启用系统目录访问或禁用受限模式可能带来安全风险。' + sLineBreak +
    '请仅在完全了解风险的情况下修改这些设置。';
  lblSecurityWarning.Font.Color := clRed;
  lblSecurityWarning.Font.Style := [fsBold];
end;

function TfrmAdvancedOptions.GetSettingsFileName: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'MoveC.ini');
end;

procedure TfrmAdvancedOptions.LoadSettings;
begin
  FSettings := TSettingsManager.Instance.Settings;
  FOriginalSettings := FSettings;
end;

procedure TfrmAdvancedOptions.SaveSettings;
begin
  TSettingsManager.Instance.Settings := FSettings;
  TSettingsManager.Instance.SaveSettings;
  LogInfo('Settings', '高级选项设置已保存');
end;

procedure TfrmAdvancedOptions.ApplySettingsToControls;
begin
  // 迁移设置
  chkCreateBackupByDefault.Checked := FSettings.CreateBackupByDefault;
  chkVerifyFilesAfterCopy.Checked := FSettings.VerifyFilesAfterCopy;
  chkUseMultiThreading.Checked := FSettings.UseMultiThreading;
  seMaxConcurrentOps.Value := FSettings.MaxConcurrentOperations;
  seBufferSize.Value := FSettings.BufferSize;
  
  // 清理设置
  chkAutoCleanupTemp.Checked := FSettings.AutoCleanupTemp;
  chkAutoCleanupRecycleBin.Checked := FSettings.AutoCleanupRecycleBin;
  chkKeepRecentBackups.Checked := FSettings.KeepRecentBackups;
  seBackupRetentionDays.Value := FSettings.BackupRetentionDays;
  
  // 日志设置
  cmbLogLevel.ItemIndex := Integer(FSettings.LogLevel);
  chkEnableFileLogging.Checked := FSettings.EnableFileLogging;
  seLogRotationSize.Value := FSettings.LogRotationSize;
  seMaxLogFiles.Value := FSettings.MaxLogFiles;
  
  // 安全设置
  chkRequireConfirmation.Checked := FSettings.RequireConfirmation;
  chkRestrictedMode.Checked := FSettings.RestrictedModeEnabled;
  chkAllowSystemDirectories.Checked := FSettings.AllowSystemDirectories;
  
  // 界面设置
  cmbWindowStyle.Text := FSettings.WindowStyle;
  chkUseModernColors.Checked := FSettings.UseModernColors;
  chkShowDetailedProgress.Checked := FSettings.ShowDetailedProgress;
  seAutoRefreshInterval.Value := FSettings.AutoRefreshInterval;
  
  // 性能设置
  chkEnableSystemMonitoring.Checked := FSettings.EnableSystemMonitoring;
  chkPerformanceOptimization.Checked := FSettings.PerformanceOptimization;
  seMemoryUsageLimit.Value := FSettings.MemoryUsageLimit;
end;

procedure TfrmAdvancedOptions.LoadSettingsFromControls;
begin
  // 迁移设置
  FSettings.CreateBackupByDefault := chkCreateBackupByDefault.Checked;
  FSettings.VerifyFilesAfterCopy := chkVerifyFilesAfterCopy.Checked;
  FSettings.UseMultiThreading := chkUseMultiThreading.Checked;
  FSettings.MaxConcurrentOperations := seMaxConcurrentOps.Value;
  FSettings.BufferSize := seBufferSize.Value;
  
  // 清理设置
  FSettings.AutoCleanupTemp := chkAutoCleanupTemp.Checked;
  FSettings.AutoCleanupRecycleBin := chkAutoCleanupRecycleBin.Checked;
  FSettings.KeepRecentBackups := chkKeepRecentBackups.Checked;
  FSettings.BackupRetentionDays := seBackupRetentionDays.Value;
  
  // 日志设置
  FSettings.LogLevel := TLogLevel(cmbLogLevel.ItemIndex);
  FSettings.EnableFileLogging := chkEnableFileLogging.Checked;
  FSettings.LogRotationSize := seLogRotationSize.Value;
  FSettings.MaxLogFiles := seMaxLogFiles.Value;
  
  // 安全设置
  FSettings.RequireConfirmation := chkRequireConfirmation.Checked;
  FSettings.RestrictedModeEnabled := chkRestrictedMode.Checked;
  FSettings.AllowSystemDirectories := chkAllowSystemDirectories.Checked;
  
  // 界面设置
  FSettings.WindowStyle := cmbWindowStyle.Text;
  FSettings.UseModernColors := chkUseModernColors.Checked;
  FSettings.ShowDetailedProgress := chkShowDetailedProgress.Checked;
  FSettings.AutoRefreshInterval := seAutoRefreshInterval.Value;
  
  // 性能设置
  FSettings.EnableSystemMonitoring := chkEnableSystemMonitoring.Checked;
  FSettings.PerformanceOptimization := chkPerformanceOptimization.Checked;
  FSettings.MemoryUsageLimit := seMemoryUsageLimit.Value;
end;

function TfrmAdvancedOptions.ValidateSettings: Boolean;
begin
  Result := True;
  
  // 可以在这里添加设置验证逻辑
  if FSettings.MaxConcurrentOperations > 8 then
  begin
    if MessageDlg('并发操作数设置较高，可能影响系统性能。是否继续？', 
                  mtWarning, [mbYes, mbNo], 0) <> mrYes then
    begin
      Result := False;
      Exit;
    end;
  end;
  
  if FSettings.AllowSystemDirectories and not FSettings.RequireConfirmation then
  begin
    MessageDlg('警告：启用系统目录访问但禁用确认对话框是不安全的。', 
               mtError, [mbOK], 0);
    Result := False;
    Exit;
  end;
end;

procedure TfrmAdvancedOptions.btnOKClick(Sender: TObject);
begin
  LoadSettingsFromControls;
  if ValidateSettings then
  begin
    SaveSettings;
    ModalResult := mrOk;
  end;
end;

procedure TfrmAdvancedOptions.btnCancelClick(Sender: TObject);
begin
  FSettings := FOriginalSettings;
  ModalResult := mrCancel;
end;

procedure TfrmAdvancedOptions.btnApplyClick(Sender: TObject);
begin
  LoadSettingsFromControls;
  if ValidateSettings then
  begin
    SaveSettings;
    FOriginalSettings := FSettings;
  end;
end;

procedure TfrmAdvancedOptions.btnResetClick(Sender: TObject);
begin
  if MessageDlg('确定要重置所有设置为默认值吗？', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    ResetToDefaults;
    ApplySettingsToControls;
  end;
end;

procedure TfrmAdvancedOptions.ResetToDefaults;
begin
  TSettingsManager.Instance.ResetToDefaults;
  FSettings := TSettingsManager.Instance.Settings;
end;

procedure TfrmAdvancedOptions.btnExportClick(Sender: TObject);
begin
  ExportSettings;
end;

procedure TfrmAdvancedOptions.btnImportClick(Sender: TObject);
begin
  ImportSettings;
end;

procedure TfrmAdvancedOptions.ExportSettings;
begin
  SaveDialog.FileName := 'MoveC_Settings_' + FormatDateTime('yyyymmdd', Now) + '.ini';
  if SaveDialog.Execute then
  begin
    try
      LoadSettingsFromControls;
      TFile.Copy(FSettingsFile, SaveDialog.FileName, True);
      MessageDlg('设置已成功导出到：' + sLineBreak + SaveDialog.FileName, 
                 mtInformation, [mbOK], 0);
      LogInfo('Settings', '设置已导出到: ' + SaveDialog.FileName);
    except
      on E: Exception do
        MessageDlg('导出设置失败：' + sLineBreak + E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmAdvancedOptions.ImportSettings;
begin
  if OpenDialog.Execute then
  begin
    try
      if MessageDlg('确定要导入设置吗？当前设置将被覆盖。', 
                    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        TFile.Copy(OpenDialog.FileName, FSettingsFile, True);
        LoadSettings;
        ApplySettingsToControls;
        MessageDlg('设置已成功导入。', mtInformation, [mbOK], 0);
        LogInfo('Settings', '设置已从文件导入: ' + OpenDialog.FileName);
      end;
    except
      on E: Exception do
        MessageDlg('导入设置失败：' + sLineBreak + E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmAdvancedOptions.btnOpenLogFolderClick(Sender: TObject);
var
  LogFolder: string;
begin
  LogFolder := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Logs');
  if TDirectory.Exists(LogFolder) then
    ShellExecute(Handle, 'open', PChar(LogFolder), nil, nil, SW_SHOWNORMAL)
  else
    MessageDlg('日志文件夹不存在：' + LogFolder, mtInformation, [mbOK], 0);
end;

procedure TfrmAdvancedOptions.btnClearLogsClick(Sender: TObject);
begin
  if MessageDlg('确定要清除所有日志文件吗？', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    if Assigned(GlobalLogManager) then
    begin
      GlobalLogManager.ClearLogs;
      MessageDlg('日志文件已清除。', mtInformation, [mbOK], 0);
      LogInfo('Settings', '日志文件已被用户清除');
    end;
  end;
end;

procedure TfrmAdvancedOptions.btnPreviewThemeClick(Sender: TObject);
begin
  MessageDlg('主题预览功能开发中...', mtInformation, [mbOK], 0);
end;

procedure TfrmAdvancedOptions.btnOptimizeNowClick(Sender: TObject);
begin
  MessageDlg('性能优化功能开发中...', mtInformation, [mbOK], 0);
end;

procedure TfrmAdvancedOptions.chkRestrictedModeClick(Sender: TObject);
begin
  if not chkRestrictedMode.Checked then
    ShowSecurityWarning;
end;

procedure TfrmAdvancedOptions.ShowSecurityWarning;
begin
  if MessageDlg('警告：禁用受限模式会降低程序的安全性。' + sLineBreak + sLineBreak +
                '在受限模式下，程序会阻止访问系统关键目录和执行高风险操作。' + sLineBreak + 
                '禁用此模式后，您需要更加谨慎地操作。' + sLineBreak + sLineBreak +
                '确定要禁用受限模式吗？', 
                mtWarning, [mbYes, mbNo], 0) <> mrYes then
  begin
    chkRestrictedMode.Checked := True;
  end;
end;

procedure TfrmAdvancedOptions.cmbWindowStyleChange(Sender: TObject);
begin
  // 根据选择的样式启用/禁用相关选项
  case cmbWindowStyle.ItemIndex of
    0: // Classic
    begin
      chkUseModernColors.Enabled := False;
      chkUseModernColors.Checked := False;
    end;
    1, 2, 3: // Modern, Dark, Light
    begin
      chkUseModernColors.Enabled := True;
    end;
  end;
end;

initialization
  // 创建全局设置管理器实例
  TSettingsManager.Instance;

finalization
  if Assigned(TSettingsManager.FInstance) then
    TSettingsManager.FInstance.Free;

end.
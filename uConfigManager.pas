unit uConfigManager;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.CheckLst, System.Generics.Collections,
  ConfigManager, uStyles;

type
  TfrmConfigManager = class(TForm)
    pnlMain: TPanel;
    pnlTop: TPanel;
    pnlBottom: TPanel;
    pnlCenter: TPanel;
    
    // 顶部标题
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    
    // 配置页面控制
    PageControl: TPageControl;
    
    // 常规设置页
    tsGeneral: TTabSheet;
    gbLanguage: TGroupBox;
    cbLanguage: TComboBox;
    gbTheme: TGroupBox;
    rbLightTheme: TRadioButton;
    rbDarkTheme: TRadioButton;
    rbAutoTheme: TRadioButton;
    
    // 迁移设置页
    tsMigration: TTabSheet;
    gbMigrationOptions: TGroupBox;
    chkCreateBackup: TCheckBox;
    chkVerifyAfterCopy: TCheckBox;
    chkUseJunctionFirst: TCheckBox;
    chkShowProgress: TCheckBox;
    lblBufferSize: TLabel;
    edtBufferSize: TEdit;
    udBufferSize: TUpDown;
    
    // 清理设置页
    tsCleanup: TTabSheet;
    gbCleanupOptions: TGroupBox;
    chkConfirmCleanup: TCheckBox;
    chkMoveToRecycleBin: TCheckBox;
    chkCleanupLogs: TCheckBox;
    lblMaxLogSize: TLabel;
    edtMaxLogSize: TEdit;
    udMaxLogSize: TUpDown;
    
    // 高级设置页
    tsAdvanced: TTabSheet;
    gbPerformance: TGroupBox;
    chkEnableMultiThread: TCheckBox;
    chkEnableCompression: TCheckBox;
    chkEnableEncryption: TCheckBox;
    lblThreadCount: TLabel;
    edtThreadCount: TEdit;
    udThreadCount: TUpDown;
    
    gbSecurity: TGroupBox;
    chkRequireElevation: TCheckBox;
    chkAuditOperations: TCheckBox;
    chkSecureDelete: TCheckBox;
    
    // 底部按钮
    btnOK: TButton;
    btnCancel: TButton;
    btnApply: TButton;
    btnReset: TButton;
    
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    
    procedure cbLanguageChange(Sender: TObject);
    procedure rbThemeClick(Sender: TObject);
    
  private
    FConfigManager: TConfigManager;
    FModified: Boolean;
    
    procedure LoadSettings;
    procedure SaveSettings;
    procedure ApplySettings;
    procedure ResetToDefaults;
    procedure UpdateUI;
    procedure SetModified(Value: Boolean);
    
    // 配置项访问方法
    function GetSelectedLanguage: string;
    function GetSelectedTheme: string;
    procedure SetLanguageSelection(const Language: string);
    procedure SetThemeSelection(const Theme: string);
    
  public
    constructor Create(AOwner: TComponent; AConfigManager: TConfigManager); reintroduce;
    property Modified: Boolean read FModified write SetModified;
  end;

var
  frmConfigManager: TfrmConfigManager;

implementation

uses
  System.IOUtils, uStrings;

{$R *.dfm}

constructor TfrmConfigManager.Create(AOwner: TComponent; AConfigManager: TConfigManager);
begin
  inherited Create(AOwner);
  FConfigManager := AConfigManager;
  FModified := False;
end;

procedure TfrmConfigManager.FormCreate(Sender: TObject);
begin
  // 设置窗体属性
  Caption := '配置管理器';
  Width := 600;
  Height := 500;
  Position := poScreenCenter;
  
  // 设置标题
  lblTitle.Caption := '⚙️ 系统配置管理';
  lblTitle.Font.Size := 14;
  lblTitle.Font.Style := [fsBold];
  
  lblSubtitle.Caption := '自定义应用程序行为和外观设置';
  
  // 初始化语言选项
  cbLanguage.Items.Clear;
  cbLanguage.Items.Add('简体中文');
  cbLanguage.Items.Add('English');
  cbLanguage.Items.Add('日本語');
  cbLanguage.Items.Add('한국어');
  cbLanguage.Items.Add('Français');
  cbLanguage.Items.Add('Deutsch');
  cbLanguage.Items.Add('Español');
  cbLanguage.Items.Add('Italiano');
  cbLanguage.Items.Add('Português');
  cbLanguage.Items.Add('Русский');
  
  // 设置默认值
  udBufferSize.Min := 1;
  udBufferSize.Max := 100;
  udBufferSize.Position := 64; // 64KB默认缓冲区
  
  udMaxLogSize.Min := 1;
  udMaxLogSize.Max := 1000;
  udMaxLogSize.Position := 10; // 10MB默认日志大小
  
  udThreadCount.Min := 1;
  udThreadCount.Max := 16;
  udThreadCount.Position := 4; // 4线程默认
  
  // 设置页面标题
  tsGeneral.Caption := '常规';
  tsMigration.Caption := '迁移';
  tsCleanup.Caption := '清理';
  tsAdvanced.Caption := '高级';
  
  // 设置分组框标题
  gbLanguage.Caption := '语言设置';
  gbTheme.Caption := '主题设置';
  gbMigrationOptions.Caption := '迁移选项';
  gbCleanupOptions.Caption := '清理选项';
  gbPerformance.Caption := '性能设置';
  gbSecurity.Caption := '安全设置';
  
  // 设置控件标题
  rbLightTheme.Caption := '浅色主题';
  rbDarkTheme.Caption := '深色主题';
  rbAutoTheme.Caption := '跟随系统';
  
  chkCreateBackup.Caption := '迁移前创建备份';
  chkVerifyAfterCopy.Caption := '复制后验证完整性';
  chkUseJunctionFirst.Caption := '优先使用目录联接';
  chkShowProgress.Caption := '显示详细进度';
  
  chkConfirmCleanup.Caption := '清理前确认';
  chkMoveToRecycleBin.Caption := '移动到回收站';
  chkCleanupLogs.Caption := '自动清理日志';
  
  chkEnableMultiThread.Caption := '启用多线程';
  chkEnableCompression.Caption := '启用压缩';
  chkEnableEncryption.Caption := '启用加密';
  
  chkRequireElevation.Caption := '需要管理员权限';
  chkAuditOperations.Caption := '审计所有操作';
  chkSecureDelete.Caption := '安全删除';
  
  lblBufferSize.Caption := '缓冲区大小 (KB):';
  lblMaxLogSize.Caption := '最大日志大小 (MB):';
  lblThreadCount.Caption := '线程数量:';
  
  btnOK.Caption := '确定';
  btnCancel.Caption := '取消';
  btnApply.Caption := '应用';
  btnReset.Caption := '重置';
end;

procedure TfrmConfigManager.FormShow(Sender: TObject);
begin
  // 应用样式
  StyleManager.StyleForm(Self);
  
  // 加载当前设置
  LoadSettings;
  UpdateUI;
end;

procedure TfrmConfigManager.FormDestroy(Sender: TObject);
begin
  // 清理资源
end;

procedure TfrmConfigManager.LoadSettings;
begin
  if not Assigned(FConfigManager) then
    Exit;
    
  try
    // 加载语言设置
    SetLanguageSelection(FConfigManager.GetString('UI.Language', '简体中文'));
    
    // 加载主题设置
    SetThemeSelection(FConfigManager.GetString('UI.Theme', 'Light'));
    
    // 加载迁移设置
    chkCreateBackup.Checked := FConfigManager.GetBoolean('Migration.CreateBackup', True);
    chkVerifyAfterCopy.Checked := FConfigManager.GetBoolean('Migration.VerifyAfterCopy', True);
    chkUseJunctionFirst.Checked := FConfigManager.GetBoolean('Migration.UseJunctionFirst', True);
    chkShowProgress.Checked := FConfigManager.GetBoolean('Migration.ShowProgress', True);
    udBufferSize.Position := FConfigManager.GetInteger('Migration.BufferSize', 64);
    
    // 加载清理设置
    chkConfirmCleanup.Checked := FConfigManager.GetBoolean('Cleanup.ConfirmBeforeCleanup', True);
    chkMoveToRecycleBin.Checked := FConfigManager.GetBoolean('Cleanup.MoveToRecycleBin', True);
    chkCleanupLogs.Checked := FConfigManager.GetBoolean('Cleanup.AutoCleanupLogs', False);
    udMaxLogSize.Position := FConfigManager.GetInteger('Cleanup.MaxLogSize', 10);
    
    // 加载高级设置
    chkEnableMultiThread.Checked := FConfigManager.GetBoolean('Advanced.EnableMultiThread', True);
    chkEnableCompression.Checked := FConfigManager.GetBoolean('Advanced.EnableCompression', False);
    chkEnableEncryption.Checked := FConfigManager.GetBoolean('Advanced.EnableEncryption', False);
    udThreadCount.Position := FConfigManager.GetInteger('Advanced.ThreadCount', 4);
    
    // 加载安全设置
    chkRequireElevation.Checked := FConfigManager.GetBoolean('Security.RequireElevation', False);
    chkAuditOperations.Checked := FConfigManager.GetBoolean('Security.AuditOperations', True);
    chkSecureDelete.Checked := FConfigManager.GetBoolean('Security.SecureDelete', False);
    
    FModified := False;
  except
    on E: Exception do
      ShowMessage('加载配置失败: ' + E.Message);
  end;
end;

procedure TfrmConfigManager.SaveSettings;
begin
  if not Assigned(FConfigManager) then
    Exit;
    
  try
    // 保存语言设置
    FConfigManager.SetString('UI.Language', GetSelectedLanguage);
    
    // 保存主题设置
    FConfigManager.SetString('UI.Theme', GetSelectedTheme);
    
    // 保存迁移设置
    FConfigManager.SetBoolean('Migration.CreateBackup', chkCreateBackup.Checked);
    FConfigManager.SetBoolean('Migration.VerifyAfterCopy', chkVerifyAfterCopy.Checked);
    FConfigManager.SetBoolean('Migration.UseJunctionFirst', chkUseJunctionFirst.Checked);
    FConfigManager.SetBoolean('Migration.ShowProgress', chkShowProgress.Checked);
    FConfigManager.SetInteger('Migration.BufferSize', udBufferSize.Position);
    
    // 保存清理设置
    FConfigManager.SetBoolean('Cleanup.ConfirmBeforeCleanup', chkConfirmCleanup.Checked);
    FConfigManager.SetBoolean('Cleanup.MoveToRecycleBin', chkMoveToRecycleBin.Checked);
    FConfigManager.SetBoolean('Cleanup.AutoCleanupLogs', chkCleanupLogs.Checked);
    FConfigManager.SetInteger('Cleanup.MaxLogSize', udMaxLogSize.Position);
    
    // 保存高级设置
    FConfigManager.SetBoolean('Advanced.EnableMultiThread', chkEnableMultiThread.Checked);
    FConfigManager.SetBoolean('Advanced.EnableCompression', chkEnableCompression.Checked);
    FConfigManager.SetBoolean('Advanced.EnableEncryption', chkEnableEncryption.Checked);
    FConfigManager.SetInteger('Advanced.ThreadCount', udThreadCount.Position);
    
    // 保存安全设置
    FConfigManager.SetBoolean('Security.RequireElevation', chkRequireElevation.Checked);
    FConfigManager.SetBoolean('Security.AuditOperations', chkAuditOperations.Checked);
    FConfigManager.SetBoolean('Security.SecureDelete', chkSecureDelete.Checked);
    
    // 保存到文件
    FConfigManager.SaveConfiguration;
    
    FModified := False;
  except
    on E: Exception do
      ShowMessage('保存配置失败: ' + E.Message);
  end;
end;

procedure TfrmConfigManager.ApplySettings;
begin
  SaveSettings;
  // 这里可以添加立即应用设置的代码
  ShowMessage('设置已应用');
end;

procedure TfrmConfigManager.ResetToDefaults;
begin
  if MessageDlg('确定要重置所有设置为默认值吗？', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    // 重置为默认值
    SetLanguageSelection('简体中文');
    SetThemeSelection('Light');
    
    chkCreateBackup.Checked := True;
    chkVerifyAfterCopy.Checked := True;
    chkUseJunctionFirst.Checked := True;
    chkShowProgress.Checked := True;
    udBufferSize.Position := 64;
    
    chkConfirmCleanup.Checked := True;
    chkMoveToRecycleBin.Checked := True;
    chkCleanupLogs.Checked := False;
    udMaxLogSize.Position := 10;
    
    chkEnableMultiThread.Checked := True;
    chkEnableCompression.Checked := False;
    chkEnableEncryption.Checked := False;
    udThreadCount.Position := 4;
    
    chkRequireElevation.Checked := False;
    chkAuditOperations.Checked := True;
    chkSecureDelete.Checked := False;
    
    FModified := True;
    UpdateUI;
  end;
end;

procedure TfrmConfigManager.UpdateUI;
begin
  // 更新编辑框显示
  edtBufferSize.Text := IntToStr(udBufferSize.Position);
  edtMaxLogSize.Text := IntToStr(udMaxLogSize.Position);
  edtThreadCount.Text := IntToStr(udThreadCount.Position);
  
  // 更新按钮状态
  btnApply.Enabled := FModified;
end;

procedure TfrmConfigManager.SetModified(Value: Boolean);
begin
  FModified := Value;
  UpdateUI;
end;

function TfrmConfigManager.GetSelectedLanguage: string;
begin
  if cbLanguage.ItemIndex >= 0 then
    Result := cbLanguage.Items[cbLanguage.ItemIndex]
  else
    Result := '简体中文';
end;

function TfrmConfigManager.GetSelectedTheme: string;
begin
  if rbLightTheme.Checked then
    Result := 'Light'
  else if rbDarkTheme.Checked then
    Result := 'Dark'
  else
    Result := 'Auto';
end;

procedure TfrmConfigManager.SetLanguageSelection(const Language: string);
var
  Index: Integer;
begin
  Index := cbLanguage.Items.IndexOf(Language);
  if Index >= 0 then
    cbLanguage.ItemIndex := Index
  else
    cbLanguage.ItemIndex := 0; // 默认选择第一个
end;

procedure TfrmConfigManager.SetThemeSelection(const Theme: string);
begin
  if SameText(Theme, 'Dark') then
    rbDarkTheme.Checked := True
  else if SameText(Theme, 'Auto') then
    rbAutoTheme.Checked := True
  else
    rbLightTheme.Checked := True;
end;

// 事件处理
procedure TfrmConfigManager.btnOKClick(Sender: TObject);
begin
  SaveSettings;
  ModalResult := mrOK;
end;

procedure TfrmConfigManager.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmConfigManager.btnApplyClick(Sender: TObject);
begin
  ApplySettings;
end;

procedure TfrmConfigManager.btnResetClick(Sender: TObject);
begin
  ResetToDefaults;
end;

procedure TfrmConfigManager.cbLanguageChange(Sender: TObject);
begin
  SetModified(True);
end;

procedure TfrmConfigManager.rbThemeClick(Sender: TObject);
begin
  SetModified(True);
end;

end.

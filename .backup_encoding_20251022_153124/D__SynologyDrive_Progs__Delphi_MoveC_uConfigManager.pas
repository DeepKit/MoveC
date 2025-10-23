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
    
    // 椤堕儴鏍囬
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    
    // 閰嶇疆椤甸潰鎺у埗
    PageControl: TPageControl;
    
    // 甯歌璁剧疆椤?    tsGeneral: TTabSheet;
    gbLanguage: TGroupBox;
    cbLanguage: TComboBox;
    gbTheme: TGroupBox;
    rbLightTheme: TRadioButton;
    rbDarkTheme: TRadioButton;
    rbAutoTheme: TRadioButton;
    
    // 杩佺Щ璁剧疆椤?    tsMigration: TTabSheet;
    gbMigrationOptions: TGroupBox;
    chkCreateBackup: TCheckBox;
    chkVerifyAfterCopy: TCheckBox;
    chkUseJunctionFirst: TCheckBox;
    chkShowProgress: TCheckBox;
    lblBufferSize: TLabel;
    edtBufferSize: TEdit;
    udBufferSize: TUpDown;
    
    // 娓呯悊璁剧疆椤?    tsCleanup: TTabSheet;
    gbCleanupOptions: TGroupBox;
    chkConfirmCleanup: TCheckBox;
    chkMoveToRecycleBin: TCheckBox;
    chkCleanupLogs: TCheckBox;
    lblMaxLogSize: TLabel;
    edtMaxLogSize: TEdit;
    udMaxLogSize: TUpDown;
    
    // 楂樼骇璁剧疆椤?    tsAdvanced: TTabSheet;
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
    
    // 搴曢儴鎸夐挳
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
    
    // 閰嶇疆椤硅闂柟娉?    function GetSelectedLanguage: string;
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
  // 璁剧疆绐椾綋灞炴€?  Caption := '閰嶇疆绠＄悊鍣?;
  Width := 600;
  Height := 500;
  Position := poScreenCenter;
  
  // 璁剧疆鏍囬
  lblTitle.Caption := '鈿欙笍 绯荤粺閰嶇疆绠＄悊';
  lblTitle.Font.Size := 14;
  lblTitle.Font.Style := [fsBold];
  
  lblSubtitle.Caption := '鑷畾涔夊簲鐢ㄧ▼搴忚涓哄拰澶栬璁剧疆';
  
  // 鍒濆鍖栬瑷€閫夐」
  cbLanguage.Items.Clear;
  cbLanguage.Items.Add('绠€浣撲腑鏂?);
  cbLanguage.Items.Add('English');
  cbLanguage.Items.Add('鏃ユ湰瑾?);
  cbLanguage.Items.Add('頃滉淡鞏?);
  cbLanguage.Items.Add('Fran莽ais');
  cbLanguage.Items.Add('Deutsch');
  cbLanguage.Items.Add('Espa帽ol');
  cbLanguage.Items.Add('Italiano');
  cbLanguage.Items.Add('Portugu锚s');
  cbLanguage.Items.Add('袪褍褋褋泻懈泄');
  
  // 璁剧疆榛樿鍊?  udBufferSize.Min := 1;
  udBufferSize.Max := 100;
  udBufferSize.Position := 64; // 64KB榛樿缂撳啿鍖?  
  udMaxLogSize.Min := 1;
  udMaxLogSize.Max := 1000;
  udMaxLogSize.Position := 10; // 10MB榛樿鏃ュ織澶у皬
  
  udThreadCount.Min := 1;
  udThreadCount.Max := 16;
  udThreadCount.Position := 4; // 4绾跨▼榛樿
  
  // 璁剧疆椤甸潰鏍囬
  tsGeneral.Caption := '甯歌';
  tsMigration.Caption := '杩佺Щ';
  tsCleanup.Caption := '娓呯悊';
  tsAdvanced.Caption := '楂樼骇';
  
  // 璁剧疆鍒嗙粍妗嗘爣棰?  gbLanguage.Caption := '璇█璁剧疆';
  gbTheme.Caption := '涓婚璁剧疆';
  gbMigrationOptions.Caption := '杩佺Щ閫夐」';
  gbCleanupOptions.Caption := '娓呯悊閫夐」';
  gbPerformance.Caption := '鎬ц兘璁剧疆';
  gbSecurity.Caption := '瀹夊叏璁剧疆';
  
  // 璁剧疆鎺т欢鏍囬
  rbLightTheme.Caption := '娴呰壊涓婚';
  rbDarkTheme.Caption := '娣辫壊涓婚';
  rbAutoTheme.Caption := '璺熼殢绯荤粺';
  
  chkCreateBackup.Caption := '杩佺Щ鍓嶅垱寤哄浠?;
  chkVerifyAfterCopy.Caption := '澶嶅埗鍚庨獙璇佸畬鏁存€?;
  chkUseJunctionFirst.Caption := '浼樺厛浣跨敤鐩綍鑱旀帴';
  chkShowProgress.Caption := '鏄剧ず璇︾粏杩涘害';
  
  chkConfirmCleanup.Caption := '娓呯悊鍓嶇‘璁?;
  chkMoveToRecycleBin.Caption := '绉诲姩鍒板洖鏀剁珯';
  chkCleanupLogs.Caption := '鑷姩娓呯悊鏃ュ織';
  
  chkEnableMultiThread.Caption := '鍚敤澶氱嚎绋?;
  chkEnableCompression.Caption := '鍚敤鍘嬬缉';
  chkEnableEncryption.Caption := '鍚敤鍔犲瘑';
  
  chkRequireElevation.Caption := '闇€瑕佺鐞嗗憳鏉冮檺';
  chkAuditOperations.Caption := '瀹¤鎵€鏈夋搷浣?;
  chkSecureDelete.Caption := '瀹夊叏鍒犻櫎';
  
  lblBufferSize.Caption := '缂撳啿鍖哄ぇ灏?(KB):';
  lblMaxLogSize.Caption := '鏈€澶ф棩蹇楀ぇ灏?(MB):';
  lblThreadCount.Caption := '绾跨▼鏁伴噺:';
  
  btnOK.Caption := '纭畾';
  btnCancel.Caption := '鍙栨秷';
  btnApply.Caption := '搴旂敤';
  btnReset.Caption := '閲嶇疆';
end;

procedure TfrmConfigManager.FormShow(Sender: TObject);
begin
  // 搴旂敤鏍峰紡
  StyleManager.StyleForm(Self);
  
  // 鍔犺浇褰撳墠璁剧疆
  LoadSettings;
  UpdateUI;
end;

procedure TfrmConfigManager.FormDestroy(Sender: TObject);
begin
  // 娓呯悊璧勬簮
end;

procedure TfrmConfigManager.LoadSettings;
begin
  if not Assigned(FConfigManager) then
    Exit;
    
  try
    // 鍔犺浇璇█璁剧疆
    SetLanguageSelection(FConfigManager.GetString('UI.Language', '绠€浣撲腑鏂?));
    
    // 鍔犺浇涓婚璁剧疆
    SetThemeSelection(FConfigManager.GetString('UI.Theme', 'Light'));
    
    // 鍔犺浇杩佺Щ璁剧疆
    chkCreateBackup.Checked := FConfigManager.GetBoolean('Migration.CreateBackup', True);
    chkVerifyAfterCopy.Checked := FConfigManager.GetBoolean('Migration.VerifyAfterCopy', True);
    chkUseJunctionFirst.Checked := FConfigManager.GetBoolean('Migration.UseJunctionFirst', True);
    chkShowProgress.Checked := FConfigManager.GetBoolean('Migration.ShowProgress', True);
    udBufferSize.Position := FConfigManager.GetInteger('Migration.BufferSize', 64);
    
    // 鍔犺浇娓呯悊璁剧疆
    chkConfirmCleanup.Checked := FConfigManager.GetBoolean('Cleanup.ConfirmBeforeCleanup', True);
    chkMoveToRecycleBin.Checked := FConfigManager.GetBoolean('Cleanup.MoveToRecycleBin', True);
    chkCleanupLogs.Checked := FConfigManager.GetBoolean('Cleanup.AutoCleanupLogs', False);
    udMaxLogSize.Position := FConfigManager.GetInteger('Cleanup.MaxLogSize', 10);
    
    // 鍔犺浇楂樼骇璁剧疆
    chkEnableMultiThread.Checked := FConfigManager.GetBoolean('Advanced.EnableMultiThread', True);
    chkEnableCompression.Checked := FConfigManager.GetBoolean('Advanced.EnableCompression', False);
    chkEnableEncryption.Checked := FConfigManager.GetBoolean('Advanced.EnableEncryption', False);
    udThreadCount.Position := FConfigManager.GetInteger('Advanced.ThreadCount', 4);
    
    // 鍔犺浇瀹夊叏璁剧疆
    chkRequireElevation.Checked := FConfigManager.GetBoolean('Security.RequireElevation', False);
    chkAuditOperations.Checked := FConfigManager.GetBoolean('Security.AuditOperations', True);
    chkSecureDelete.Checked := FConfigManager.GetBoolean('Security.SecureDelete', False);
    
    FModified := False;
  except
    on E: Exception do
      ShowMessage('鍔犺浇閰嶇疆澶辫触: ' + E.Message);
  end;
end;

procedure TfrmConfigManager.SaveSettings;
begin
  if not Assigned(FConfigManager) then
    Exit;
    
  try
    // 淇濆瓨璇█璁剧疆
    FConfigManager.SetString('UI.Language', GetSelectedLanguage);
    
    // 淇濆瓨涓婚璁剧疆
    FConfigManager.SetString('UI.Theme', GetSelectedTheme);
    
    // 淇濆瓨杩佺Щ璁剧疆
    FConfigManager.SetBoolean('Migration.CreateBackup', chkCreateBackup.Checked);
    FConfigManager.SetBoolean('Migration.VerifyAfterCopy', chkVerifyAfterCopy.Checked);
    FConfigManager.SetBoolean('Migration.UseJunctionFirst', chkUseJunctionFirst.Checked);
    FConfigManager.SetBoolean('Migration.ShowProgress', chkShowProgress.Checked);
    FConfigManager.SetInteger('Migration.BufferSize', udBufferSize.Position);
    
    // 淇濆瓨娓呯悊璁剧疆
    FConfigManager.SetBoolean('Cleanup.ConfirmBeforeCleanup', chkConfirmCleanup.Checked);
    FConfigManager.SetBoolean('Cleanup.MoveToRecycleBin', chkMoveToRecycleBin.Checked);
    FConfigManager.SetBoolean('Cleanup.AutoCleanupLogs', chkCleanupLogs.Checked);
    FConfigManager.SetInteger('Cleanup.MaxLogSize', udMaxLogSize.Position);
    
    // 淇濆瓨楂樼骇璁剧疆
    FConfigManager.SetBoolean('Advanced.EnableMultiThread', chkEnableMultiThread.Checked);
    FConfigManager.SetBoolean('Advanced.EnableCompression', chkEnableCompression.Checked);
    FConfigManager.SetBoolean('Advanced.EnableEncryption', chkEnableEncryption.Checked);
    FConfigManager.SetInteger('Advanced.ThreadCount', udThreadCount.Position);
    
    // 淇濆瓨瀹夊叏璁剧疆
    FConfigManager.SetBoolean('Security.RequireElevation', chkRequireElevation.Checked);
    FConfigManager.SetBoolean('Security.AuditOperations', chkAuditOperations.Checked);
    FConfigManager.SetBoolean('Security.SecureDelete', chkSecureDelete.Checked);
    
    // 淇濆瓨鍒版枃浠?    FConfigManager.SaveConfiguration;
    
    FModified := False;
  except
    on E: Exception do
      ShowMessage('淇濆瓨閰嶇疆澶辫触: ' + E.Message);
  end;
end;

procedure TfrmConfigManager.ApplySettings;
begin
  SaveSettings;
  // 杩欓噷鍙互娣诲姞绔嬪嵆搴旂敤璁剧疆鐨勪唬鐮?  ShowMessage('璁剧疆宸插簲鐢?);
end;

procedure TfrmConfigManager.ResetToDefaults;
begin
  if MessageDlg('纭畾瑕侀噸缃墍鏈夎缃负榛樿鍊煎悧锛?, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    // 閲嶇疆涓洪粯璁ゅ€?    SetLanguageSelection('绠€浣撲腑鏂?);
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
  // 鏇存柊缂栬緫妗嗘樉绀?  edtBufferSize.Text := IntToStr(udBufferSize.Position);
  edtMaxLogSize.Text := IntToStr(udMaxLogSize.Position);
  edtThreadCount.Text := IntToStr(udThreadCount.Position);
  
  // 鏇存柊鎸夐挳鐘舵€?  btnApply.Enabled := FModified;
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
    Result := '绠€浣撲腑鏂?;
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
    cbLanguage.ItemIndex := 0; // 榛樿閫夋嫨绗竴涓?end;

procedure TfrmConfigManager.SetThemeSelection(const Theme: string);
begin
  if SameText(Theme, 'Dark') then
    rbDarkTheme.Checked := True
  else if SameText(Theme, 'Auto') then
    rbAutoTheme.Checked := True
  else
    rbLightTheme.Checked := True;
end;

// 浜嬩欢澶勭悊
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

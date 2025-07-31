unit LanguageSelectionForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  MultiLanguageDatabaseManager, MultiLanguageConstants;

type
  TfrmLanguageSelection = class(TForm)
    pnlMain: TPanel;
    lblTitle: TLabel;
    lstLanguages: TListBox;
    pnlButtons: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure lstLanguagesDblClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FDatabaseManager: TMultiLanguageDatabaseManager;
    FSelectedLanguage: TLanguageCode;
    FOriginalLanguage: TLanguageCode;
    
    procedure LoadLanguages;
    procedure UpdateUI;
    procedure SelectLanguage(LanguageCode: TLanguageCode);
    
  public
    constructor Create(AOwner: TComponent; DatabaseManager: TMultiLanguageDatabaseManager); reintroduce;
    
    property SelectedLanguage: TLanguageCode read FSelectedLanguage;
  end;

implementation

{$R *.dfm}

constructor TfrmLanguageSelection.Create(AOwner: TComponent; DatabaseManager: TMultiLanguageDatabaseManager);
begin
  inherited Create(AOwner);
  FDatabaseManager := DatabaseManager;
  FSelectedLanguage := lcEnglish;
  FOriginalLanguage := lcEnglish;
  
  if Assigned(FDatabaseManager) then
  begin
    FSelectedLanguage := FDatabaseManager.GetCurrentLanguage;
    FOriginalLanguage := FSelectedLanguage;
  end;
end;

procedure TfrmLanguageSelection.FormCreate(Sender: TObject);
begin
  // 设置窗口属性
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  Width := 400;
  Height := 350;
  
  // 创建主面板
  pnlMain := TPanel.Create(Self);
  pnlMain.Parent := Self;
  pnlMain.Align := alClient;
  pnlMain.BevelOuter := bvNone;
  pnlMain.Padding.Left := 16;
  pnlMain.Padding.Right := 16;
  pnlMain.Padding.Top := 16;
  pnlMain.Padding.Bottom := 16;
  
  // 创建标题标签
  lblTitle := TLabel.Create(Self);
  lblTitle.Parent := pnlMain;
  lblTitle.Align := alTop;
  lblTitle.Height := 30;
  lblTitle.Font.Size := 12;
  lblTitle.Font.Style := [fsBold];
  lblTitle.Alignment := taCenter;
  lblTitle.Caption := 'Language Settings';
  
  // 创建语言列表
  lstLanguages := TListBox.Create(Self);
  lstLanguages.Parent := pnlMain;
  lstLanguages.Align := alClient;
  lstLanguages.Font.Size := 10;
  lstLanguages.ItemHeight := 24;
  lstLanguages.Style := lbOwnerDrawFixed;
  lstLanguages.OnDblClick := lstLanguagesDblClick;
  
  // 创建按钮面板
  pnlButtons := TPanel.Create(Self);
  pnlButtons.Parent := pnlMain;
  pnlButtons.Align := alBottom;
  pnlButtons.Height := 50;
  pnlButtons.BevelOuter := bvNone;
  
  // 创建确定按钮
  btnOK := TButton.Create(Self);
  btnOK.Parent := pnlButtons;
  btnOK.Width := 80;
  btnOK.Height := 30;
  btnOK.Left := pnlButtons.Width - 180;
  btnOK.Top := 10;
  btnOK.Anchors := [akTop, akRight];
  btnOK.Caption := 'OK';
  btnOK.Default := True;
  btnOK.OnClick := btnOKClick;
  
  // 创建取消按钮
  btnCancel := TButton.Create(Self);
  btnCancel.Parent := pnlButtons;
  btnCancel.Width := 80;
  btnCancel.Height := 30;
  btnCancel.Left := pnlButtons.Width - 90;
  btnCancel.Top := 10;
  btnCancel.Anchors := [akTop, akRight];
  btnCancel.Caption := 'Cancel';
  btnCancel.Cancel := True;
  btnCancel.OnClick := btnCancelClick;
  
  LoadLanguages;
end;

procedure TfrmLanguageSelection.FormDestroy(Sender: TObject);
begin
  // 清理资源
end;

procedure TfrmLanguageSelection.FormShow(Sender: TObject);
begin
  UpdateUI;
  
  // 选中当前语言
  if Assigned(FDatabaseManager) then
  begin
    SelectLanguage(FDatabaseManager.GetCurrentLanguage);
  end;
end;

procedure TfrmLanguageSelection.LoadLanguages;
var
  Languages: TArray<TLanguageCode>;
  I: Integer;
  LanguageCode: TLanguageCode;
  DisplayName: string;
begin
  lstLanguages.Items.Clear;
  
  Languages := [lcEnglish, lcChineseSimplified, lcChineseTraditional, lcJapanese, 
                lcKorean, lcGerman, lcFrench, lcSpanish, lcItalian, lcPortuguese,
                lcRussian, lcDutch, lcSwedish, lcNorwegian, lcDanish, lcFinnish];
  
  for I := 0 to High(Languages) do
  begin
    LanguageCode := Languages[I];
    DisplayName := GetLanguageDisplayName(LanguageCode);
    lstLanguages.Items.AddObject(DisplayName, TObject(Ord(LanguageCode)));
  end;
end;

procedure TfrmLanguageSelection.UpdateUI;
begin
  if not Assigned(FDatabaseManager) then
  begin
    // 如果没有数据库管理器，使用默认英文
    Caption := 'Language Settings';
    lblTitle.Caption := 'Language Settings';
    btnOK.Caption := 'OK';
    btnCancel.Caption := 'Cancel';
    Exit;
  end;

  // 更新窗口标题和控件文本为当前语言
  Caption := FDatabaseManager.GetLanguageWindowTitle;
  lblTitle.Caption := FDatabaseManager.GetLanguageWindowTitle;
  btnOK.Caption := FDatabaseManager.GetOKButtonText;
  btnCancel.Caption := FDatabaseManager.GetCancelButtonText;
end;

procedure TfrmLanguageSelection.SelectLanguage(LanguageCode: TLanguageCode);
var
  I: Integer;
begin
  for I := 0 to lstLanguages.Items.Count - 1 do
  begin
    if TLanguageCode(lstLanguages.Items.Objects[I]) = LanguageCode then
    begin
      lstLanguages.ItemIndex := I;
      FSelectedLanguage := LanguageCode;
      Break;
    end;
  end;
end;

procedure TfrmLanguageSelection.lstLanguagesDblClick(Sender: TObject);
begin
  if lstLanguages.ItemIndex >= 0 then
  begin
    FSelectedLanguage := TLanguageCode(lstLanguages.Items.Objects[lstLanguages.ItemIndex]);
    ModalResult := mrOk;
  end;
end;

procedure TfrmLanguageSelection.btnOKClick(Sender: TObject);
var
  OldLanguage: TLanguageCode;
  SelectPrompt, WindowTitle: string;
begin
  if lstLanguages.ItemIndex >= 0 then
  begin
    FSelectedLanguage := TLanguageCode(lstLanguages.Items.Objects[lstLanguages.ItemIndex]);

    // 如果语言发生了变化
    if FSelectedLanguage <> FOriginalLanguage then
    begin
      if Assigned(FDatabaseManager) then
      begin
        // 保存旧语言，用于获取当前语言的提示信息
        OldLanguage := FDatabaseManager.GetCurrentLanguage;

        // 设置新语言
        FDatabaseManager.SetCurrentLanguage(FSelectedLanguage);

        // 使用新语言显示提示信息
        MessageBox(Handle,
                  PChar(FDatabaseManager.GetLanguageChangedMessage),
                  PChar(FDatabaseManager.GetLanguageWindowTitle),
                  MB_OK or MB_ICONINFORMATION);

        // 更新窗口界面为新语言
        UpdateUI;
      end;
    end;

    ModalResult := mrOk;
  end
  else
  begin
    // 使用当前语言显示选择提示
    if Assigned(FDatabaseManager) then
    begin
      SelectPrompt := FDatabaseManager.GetLanguageString(FDatabaseManager.GetCurrentLanguage, 'select_language_prompt', 'Please select a language.');
      WindowTitle := FDatabaseManager.GetLanguageWindowTitle;
    end
    else
    begin
      SelectPrompt := 'Please select a language.';
      WindowTitle := 'Language Settings';
    end;

    MessageBox(Handle, PChar(SelectPrompt), PChar(WindowTitle), MB_OK or MB_ICONWARNING);
  end;
end;

procedure TfrmLanguageSelection.btnCancelClick(Sender: TObject);
begin
  FSelectedLanguage := FOriginalLanguage; // 恢复原始语言
  ModalResult := mrCancel;
end;

end.

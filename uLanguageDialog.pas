unit uLanguageDialog;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  LanguageTypes, LanguageManager;

type
  TfrmLanguageDialog = class(TForm)
    pnlMain: TPanel;
    lblTitle: TLabel;
    lblDescription: TLabel;
    cmbLanguage: TComboBox;
    pnlButtons: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    lblCurrentLanguage: TLabel;
    
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure cmbLanguageChange(Sender: TObject);
    
  private
    FSelectedLanguage: TLanguageCode;
    procedure LoadLanguageList;
    procedure UpdateUI;
    
  public
    class function ShowLanguageDialog(var ALanguage: TLanguageCode): Boolean;
    property SelectedLanguage: TLanguageCode read FSelectedLanguage write FSelectedLanguage;
  end;

implementation

{$R *.dfm}

class function TfrmLanguageDialog.ShowLanguageDialog(var ALanguage: TLanguageCode): Boolean;
var
  Dialog: TfrmLanguageDialog;
begin
  Result := False;
  Dialog := TfrmLanguageDialog.Create(nil);
  try
    Dialog.FSelectedLanguage := ALanguage;
    Dialog.LoadLanguageList;
    Dialog.UpdateUI;
    
    if Dialog.ShowModal = mrOK then
    begin
      ALanguage := Dialog.FSelectedLanguage;
      Result := True;
    end;
    
  finally
    Dialog.Free;
  end;
end;

procedure TfrmLanguageDialog.FormCreate(Sender: TObject);
begin
  // 设置窗体属性
  Position := poScreenCenter;
  BorderStyle := bsDialog;
  BorderIcons := [biSystemMenu];
  
  // 设置默认语言
  FSelectedLanguage := LanguageMgr.GetCurrentLanguage;
end;

procedure TfrmLanguageDialog.LoadLanguageList;
var
  Languages: TArray<TLanguageInfo>;
  I: Integer;
  LanguageInfo: TLanguageInfo;
  DisplayName: string;
begin
  cmbLanguage.Items.Clear;

  Languages := LanguageMgr.GetAvailableLanguages;

  for I := 0 to Length(Languages) - 1 do
  begin
    LanguageInfo := Languages[I];

    // 根据语言代码获取本地化的显示名称
    case LanguageInfo.Code of
      lcChineseSimplified: DisplayName := LanguageMgr.GetString('lang_chinese_simplified');
      lcChineseTraditional: DisplayName := LanguageMgr.GetString('lang_chinese_traditional');
      lcEnglish: DisplayName := LanguageMgr.GetString('lang_english');
      lcJapanese: DisplayName := LanguageMgr.GetString('lang_japanese');
      else DisplayName := LanguageInfo.Name;
    end;

    cmbLanguage.Items.AddObject(DisplayName, TObject(Ord(LanguageInfo.Code)));

    // 设置当前选中项
    if LanguageInfo.Code = FSelectedLanguage then
      cmbLanguage.ItemIndex := I;
  end;

  if cmbLanguage.ItemIndex = -1 then
    cmbLanguage.ItemIndex := 0;
end;

procedure TfrmLanguageDialog.UpdateUI;
begin
  // 使用数据库中的字符串更新界面文本
  Caption := LanguageMgr.GetString('language_settings');
  lblTitle.Caption := LanguageMgr.GetString('select_interface_language');
  lblDescription.Caption := LanguageMgr.GetString('select_language_description');
  lblCurrentLanguage.Caption := LanguageMgr.GetString('current_language') + ': ' + LanguageMgr.GetCurrentLanguageName;
  btnOK.Caption := LanguageMgr.GetString('btn_ok');
  btnCancel.Caption := LanguageMgr.GetString('btn_cancel');
end;

procedure TfrmLanguageDialog.cmbLanguageChange(Sender: TObject);
begin
  if cmbLanguage.ItemIndex >= 0 then
  begin
    FSelectedLanguage := TLanguageCode(Integer(cmbLanguage.Items.Objects[cmbLanguage.ItemIndex]));
  end;
end;

procedure TfrmLanguageDialog.btnOKClick(Sender: TObject);
begin
  ModalResult := mrOK;
end;

procedure TfrmLanguageDialog.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

end.

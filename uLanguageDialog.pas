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
    FSelectedLanguage: TLanguageType;
    procedure LoadLanguageList;
    procedure UpdateUI;

  public
    class function ShowLanguageDialog(var ALanguage: TLanguageType): Boolean;
    property SelectedLanguage: TLanguageType read FSelectedLanguage write FSelectedLanguage;
  end;

implementation

{$R *.dfm}

class function TfrmLanguageDialog.ShowLanguageDialog(var ALanguage: TLanguageType): Boolean;
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
  FSelectedLanguage := GetLanguageManager.GetCurrentLanguage;
end;

procedure TfrmLanguageDialog.LoadLanguageList;
var
  LangType: TLanguageType;
  LanguageInfo: TLanguageInfo;
  DisplayName: string;
begin
  cmbLanguage.Items.Clear;

  // 遍历所有支持的语言类型
  for LangType := Low(TLanguageType) to High(TLanguageType) do
  begin
    LanguageInfo := GetLanguageInfo(LangType);
    DisplayName := LanguageInfo.LanguageName;

    cmbLanguage.Items.AddObject(DisplayName, TObject(Ord(LangType)));

    // 设置当前选中项
    if LangType = FSelectedLanguage then
      cmbLanguage.ItemIndex := cmbLanguage.Items.Count - 1;
  end;

  if cmbLanguage.ItemIndex = -1 then
    cmbLanguage.ItemIndex := 0;
end;

procedure TfrmLanguageDialog.UpdateUI;
begin
  // 使用数据库中的字符串更新界面文本
  Caption := _T('language_settings', '语言设置');
  lblTitle.Caption := _T('select_interface_language', '选择界面语言:');
  lblDescription.Caption := _T('select_language_description', '更改语言设置后需要重启程序才能生效。');
  lblCurrentLanguage.Caption := _T('current_language', '当前语言') + ': ' + GetLanguageManager.GetCurrentLanguageInfo.LanguageName;
  btnOK.Caption := _T('btn_ok', '确定');
  btnCancel.Caption := _T('btn_cancel', '取消');
end;

procedure TfrmLanguageDialog.cmbLanguageChange(Sender: TObject);
begin
  if cmbLanguage.ItemIndex >= 0 then
  begin
    FSelectedLanguage := TLanguageType(Integer(cmbLanguage.Items.Objects[cmbLanguage.ItemIndex]));
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

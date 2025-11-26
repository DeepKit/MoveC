unit uMessageBox;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons;

type
  TMessageType = (mtInfo, mtWarning, mtError, mtConfirm, mtQuestion);
  TMessageResult = Integer;

const
  mrOK = 1;
  mrCancel = 2;
  mrYes = 6;
  mrNo = 7;

  TfrmMessageBox = class(TForm)
    pnlMain: TPanel;
    pnlIcon: TPanel;
    imgIcon: TImage;
    pnlContent: TPanel;
    lblTitle: TLabel;
    lblMessage: TLabel;
    pnlButtons: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    btnYes: TButton;
    btnNo: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnYesClick(Sender: TObject);
    procedure btnNoClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FResult: TMessageResult;
    procedure SetupUI(AMessageType: TMessageType; const ATitle, AMessage: string; AButtons: array of TMessageResult);
    procedure ApplyModernStyle;
  public
    class function ShowMessage(const ATitle, AMessage: string; AMessageType: TMessageType = mtInfo): TMessageResult;
    class function ShowConfirm(const ATitle, AMessage: string): TMessageResult;
    class function ShowQuestion(const ATitle, AMessage: string): TMessageResult;
    class function ShowInfo(const AMessage: string): TMessageResult;
    class function ShowWarning(const AMessage: string): TMessageResult;
    class function ShowError(const AMessage: string): TMessageResult;
  end;

// 全局函数，替代系统的ShowMessage
function SafeShowMessage(const AMessage: string): TMessageResult;
function SafeShowConfirm(const ATitle, AMessage: string): TMessageResult;
function SafeShowInfo(const AMessage: string): TMessageResult;
function SafeShowWarning(const AMessage: string): TMessageResult;
function SafeShowError(const AMessage: string): TMessageResult;

implementation

{$R *.dfm}

class function TfrmMessageBox.ShowMessage(const ATitle, AMessage: string; AMessageType: TMessageType): TMessageResult;
var
  Form: TfrmMessageBox;
  Buttons: array of TMessageResult;
begin
  Form := TfrmMessageBox.Create(nil);
  try
    case AMessageType of
      mtInfo, mtWarning, mtError:
        Buttons := [mrOK];
      mtConfirm:
        Buttons := [mrYes, mrNo];
      mtQuestion:
        Buttons := [mrYes, mrNo, mrCancel];
    end;
    
    Form.SetupUI(AMessageType, ATitle, AMessage, Buttons);
    Form.ShowModal;
    Result := Form.FResult;
  finally
    Form.Free;
  end;
end;

class function TfrmMessageBox.ShowConfirm(const ATitle, AMessage: string): TMessageResult;
begin
  Result := ShowMessage(ATitle, AMessage, mtConfirm);
end;

class function TfrmMessageBox.ShowQuestion(const ATitle, AMessage: string): TMessageResult;
begin
  Result := ShowMessage(ATitle, AMessage, mtQuestion);
end;

class function TfrmMessageBox.ShowInfo(const AMessage: string): TMessageResult;
begin
  Result := ShowMessage('信息', AMessage, mtInfo);
end;

class function TfrmMessageBox.ShowWarning(const AMessage: string): TMessageResult;
begin
  Result := ShowMessage('警告', AMessage, mtWarning);
end;

class function TfrmMessageBox.ShowError(const AMessage: string): TMessageResult;
begin
  Result := ShowMessage('错误', AMessage, mtError);
end;

procedure TfrmMessageBox.FormCreate(Sender: TObject);
begin
  FResult := mrCancel;
  ApplyModernStyle;
end;

procedure TfrmMessageBox.SetupUI(AMessageType: TMessageType; const ATitle, AMessage: string; AButtons: array of TMessageResult);
var
  I: Integer;
  ButtonCount: Integer;
  ButtonWidth: Integer;
  StartX: Integer;
begin
  // 设置标题和消息
  lblTitle.Caption := ATitle;
  lblMessage.Caption := AMessage;
  Caption := ATitle;
  
  // 设置图标颜色
  case AMessageType of
    mtInfo:
      begin
        pnlIcon.Color := $4CAF50; // 绿色
        lblTitle.Font.Color := $4CAF50;
      end;
    mtWarning:
      begin
        pnlIcon.Color := $FF9800; // 橙色
        lblTitle.Font.Color := $FF9800;
      end;
    mtError:
      begin
        pnlIcon.Color := $F44336; // 红色
        lblTitle.Font.Color := $F44336;
      end;
    mtConfirm, mtQuestion:
      begin
        pnlIcon.Color := $2196F3; // 蓝色
        lblTitle.Font.Color := $2196F3;
      end;
  end;
  
  // 隐藏所有按钮
  btnOK.Visible := False;
  btnCancel.Visible := False;
  btnYes.Visible := False;
  btnNo.Visible := False;
  
  // 显示需要的按钮
  ButtonCount := Length(AButtons);
  ButtonWidth := 80;
  StartX := (pnlButtons.Width - (ButtonCount * ButtonWidth + (ButtonCount - 1) * 10)) div 2;
  
  for I := 0 to High(AButtons) do
  begin
    case AButtons[I] of
      mrOK:
        begin
          btnOK.Visible := True;
          btnOK.Left := StartX + I * (ButtonWidth + 10);
          btnOK.Caption := '确定';
        end;
      mrCancel:
        begin
          btnCancel.Visible := True;
          btnCancel.Left := StartX + I * (ButtonWidth + 10);
          btnCancel.Caption := '取消';
        end;
      mrYes:
        begin
          btnYes.Visible := True;
          btnYes.Left := StartX + I * (ButtonWidth + 10);
          btnYes.Caption := '是';
        end;
      mrNo:
        begin
          btnNo.Visible := True;
          btnNo.Left := StartX + I * (ButtonWidth + 10);
          btnNo.Caption := '否';
        end;
    end;
  end;
  
  // 调整窗体大小
  Height := pnlMain.Height + 40;
  Width := Max(400, lblMessage.Width + 100);
  
  // 居中显示
  Position := poScreenCenter;
end;

procedure TfrmMessageBox.ApplyModernStyle;
begin
  // 设置字体
  Font.Name := 'Microsoft YaHei UI';
  Font.Size := 9;
  Font.Charset := DEFAULT_CHARSET;
  
  // 主面板样式
  pnlMain.Color := clWhite;
  pnlMain.BevelOuter := bvNone;
  
  // 图标面板样式
  pnlIcon.BevelOuter := bvNone;
  pnlIcon.Width := 60;
  
  // 内容面板样式
  pnlContent.Color := clWhite;
  pnlContent.BevelOuter := bvNone;
  
  // 标题样式
  lblTitle.Font.Name := 'Microsoft YaHei UI';
  lblTitle.Font.Size := 12;
  lblTitle.Font.Style := [fsBold];
  lblTitle.Font.Charset := DEFAULT_CHARSET;
  
  // 消息样式
  lblMessage.Font.Name := 'Microsoft YaHei UI';
  lblMessage.Font.Size := 9;
  lblMessage.Font.Charset := DEFAULT_CHARSET;
  lblMessage.Color := $424242;
  lblMessage.WordWrap := True;
  
  // 按钮面板样式
  pnlButtons.Color := $F5F5F5;
  pnlButtons.BevelOuter := bvNone;
  pnlButtons.Height := 50;
  
  // 按钮样式
  btnOK.Font.Name := 'Microsoft YaHei UI';
  btnOK.Font.Charset := DEFAULT_CHARSET;
  btnCancel.Font.Name := 'Microsoft YaHei UI';
  btnCancel.Font.Charset := DEFAULT_CHARSET;
  btnYes.Font.Name := 'Microsoft YaHei UI';
  btnYes.Font.Charset := DEFAULT_CHARSET;
  btnNo.Font.Name := 'Microsoft YaHei UI';
  btnNo.Font.Charset := DEFAULT_CHARSET;
end;

procedure TfrmMessageBox.btnOKClick(Sender: TObject);
begin
  FResult := mrOK;
  ModalResult := Vcl.Forms.mrOK;
end;

procedure TfrmMessageBox.btnCancelClick(Sender: TObject);
begin
  FResult := mrCancel;
  ModalResult := Vcl.Forms.mrCancel;
end;

procedure TfrmMessageBox.btnYesClick(Sender: TObject);
begin
  FResult := mrYes;
  ModalResult := Vcl.Forms.mrYes;
end;

procedure TfrmMessageBox.btnNoClick(Sender: TObject);
begin
  FResult := mrNo;
  ModalResult := Vcl.Forms.mrNo;
end;

procedure TfrmMessageBox.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    FResult := mrCancel;
    ModalResult := Vcl.Forms.mrCancel;
  end;
end;

// 全局函数实现
function SafeShowMessage(const AMessage: string): TMessageResult;
begin
  Result := TfrmMessageBox.ShowInfo(AMessage);
end;

function SafeShowConfirm(const ATitle, AMessage: string): TMessageResult;
begin
  Result := TfrmMessageBox.ShowConfirm(ATitle, AMessage);
end;

function SafeShowInfo(const AMessage: string): TMessageResult;
begin
  Result := TfrmMessageBox.ShowInfo(AMessage);
end;

function SafeShowWarning(const AMessage: string): TMessageResult;
begin
  Result := TfrmMessageBox.ShowWarning(AMessage);
end;

function SafeShowError(const AMessage: string): TMessageResult;
begin
  Result := TfrmMessageBox.ShowError(AMessage);
end;

end.

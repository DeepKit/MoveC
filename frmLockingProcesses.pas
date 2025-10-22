unit frmLockingProcesses;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Controls, Vcl.CheckLst, System.Generics.Collections;

type
  TfrmLockingProcesses = class
  public
    class function ConfirmClose(const ProcessItems: TArray<string>): Boolean;
  end;

implementation

class function TfrmLockingProcesses.ConfirmClose(const ProcessItems: TArray<string>): Boolean;
var
  i: Integer;
  Form: TForm;
  pnlTop, pnlBottom: TPanel;
  lblInfo: TLabel;
  clbProcs: TCheckListBox;
  btnCloseAll, btnManual: TButton;
begin
  Result := False;
  while True do
  begin
    Form := TForm.CreateNew(nil);
    try
      Form.Caption := '占用进程列表';
      Form.Width := 560;
      Form.Height := 460;
      Form.Position := poScreenCenter;
      Form.BorderStyle := bsDialog;

      pnlTop := TPanel.Create(Form);
      pnlTop.Parent := Form;
      pnlTop.Align := alTop;
      pnlTop.Height := 80;

      lblInfo := TLabel.Create(Form);
      lblInfo.Parent := pnlTop;
      lblInfo.Align := alClient;
      lblInfo.Caption := '以下进程正在占用将要迁移/删除的文件或目录：' + sLineBreak +
                         '请保持全部勾选并点击“关闭全部并继续”。' + sLineBreak +
                         '如不希望自动关闭，请点击“我将手动关闭后重试”。';
      lblInfo.WordWrap := True;

      clbProcs := TCheckListBox.Create(Form);
      clbProcs.Parent := Form;
      clbProcs.Align := alClient;

      pnlBottom := TPanel.Create(Form);
      pnlBottom.Parent := Form;
      pnlBottom.Align := alBottom;
      pnlBottom.Height := 50;

      btnCloseAll := TButton.Create(Form);
      btnCloseAll.Parent := pnlBottom;
      btnCloseAll.Caption := '关闭全部并继续';
      btnCloseAll.Left := pnlBottom.Width - 220;
      btnCloseAll.Top := 10;
      btnCloseAll.Width := 130;
      btnCloseAll.Anchors := [akRight, akTop];
      btnCloseAll.ModalResult := mrOk;

      btnManual := TButton.Create(Form);
      btnManual.Parent := pnlBottom;
      btnManual.Caption := '我将手动关闭后重试';
      btnManual.Left := pnlBottom.Width - 360;
      btnManual.Top := 10;
      btnManual.Width := 130;
      btnManual.Anchors := [akRight, akTop];
      btnManual.ModalResult := mrCancel;

      clbProcs.Items.BeginUpdate;
      try
        for i := 0 to High(ProcessItems) do
        begin
          clbProcs.Items.Add(ProcessItems[i]);
          clbProcs.Checked[i] := True;
        end;
      finally
        clbProcs.Items.EndUpdate;
      end;

      if Form.ShowModal = mrOk then
      begin
        var AllChecked := True;
        for i := 0 to clbProcs.Items.Count - 1 do
          if not clbProcs.Checked[i] then
          begin
            AllChecked := False;
            Break;
          end;
        if AllChecked then
        begin
          Result := True;
          Exit;
        end
        else
          MessageDlg('为保证操作一致性，请保持全部进程勾选。您也可以选择“我将手动关闭后重试”。', mtWarning, [mbOK], 0);
      end
      else
      begin
        Result := False;
        Exit;
      end;
    finally
      Form.Free;
    end;
  end;
end;

end.

unit uMirrorSettings;

interface

uses
  System.SysUtils, System.Classes,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  uMain;

type
  TMirrorConfigArray = array[1..6] of TMirrorConfig;

  TfrmMirrorSettings = class(TForm)
  private
    FScrollBox: TScrollBox;
    FBtnOK: TButton;
    FBtnCancel: TButton;

    FGroupPanel: array[1..6] of TPanel;
    FHeaderCheck: array[1..6] of TCheckBox;
    FHeaderLabel: array[1..6] of TLabel;
    FToggleButton: array[1..6] of TButton;
    FBodyPanel: array[1..6] of TPanel;

    FEdtSource: array[1..6] of TEdit;
    FBtnBrowseSource: array[1..6] of TButton;
    FEdtBackup: array[1..6] of TEdit;
    FBtnBrowseBackup: array[1..6] of TButton;
    FCmbType: array[1..6] of TComboBox;
    FEdtInterval: array[1..6] of TEdit;
    FChkWeekly: array[1..6] of TCheckBox;
    FCmbWeeklyDay: array[1..6] of TComboBox;
    FEdtWeeklyTime: array[1..6] of TEdit;

    procedure BuildUI;
    procedure BuildGroup(Index: Integer; TopOffset: Integer);
    procedure ToggleGroup(Index: Integer);
    procedure ToggleButtonClick(Sender: TObject);
    procedure BrowseSourceClick(Sender: TObject);
    procedure BrowseBackupClick(Sender: TObject);
    procedure HeaderCheckClick(Sender: TObject);
    procedure BtnOKClick(Sender: TObject);
    procedure BtnCancelClick(Sender: TObject);

    procedure MirrorToControls(const Mirrors: TMirrorConfigArray);
    procedure ControlsToMirror(var Mirrors: TMirrorConfigArray);
    procedure LoadTypesToCombo(Cmb: TComboBox);
  public
    class function EditMirrors(var Mirrors): Boolean; static;
  end;

implementation

uses
  Vcl.Dialogs, Vcl.FileCtrl;

{ TfrmMirrorSettings }

type
  PMirrorConfigArray = ^TMirrorConfigArray;

class function TfrmMirrorSettings.EditMirrors(var Mirrors): Boolean;
var
  F: TfrmMirrorSettings;
  P: PMirrorConfigArray;
begin
  Result := False;
  F := TfrmMirrorSettings.Create(nil);
  try
    F.Position := poScreenCenter;
    F.Caption := '目录镜像设置';
    F.Width := 900;
    F.Height := 600;
    F.BorderStyle := bsSizeable;

    F.BuildUI;
    P := PMirrorConfigArray(@Mirrors);
    F.MirrorToControls(P^);

    if F.ShowModal = mrOk then
    begin
      F.ControlsToMirror(P^);
      Result := True;
    end;
  finally
    F.Free;
  end;
end;

procedure TfrmMirrorSettings.BuildUI;
var
  I: Integer;
  topOffset: Integer;
begin
  FScrollBox := TScrollBox.Create(Self);
  FScrollBox.Parent := Self;
  FScrollBox.Align := alClient;
  FScrollBox.VertScrollBar.Visible := True;
  FScrollBox.HorzScrollBar.Visible := False;

  FBtnOK := TButton.Create(Self);
  FBtnOK.Parent := Self;
  FBtnOK.Caption := '确定';
  FBtnOK.Default := True;
  FBtnOK.ModalResult := mrNone;
  FBtnOK.Top := ClientHeight - 40;
  FBtnOK.Left := ClientWidth - 180;
  FBtnOK.Anchors := [akRight, akBottom];
  FBtnOK.OnClick := BtnOKClick;

  FBtnCancel := TButton.Create(Self);
  FBtnCancel.Parent := Self;
  FBtnCancel.Caption := '取消';
  FBtnCancel.Cancel := True;
  FBtnCancel.ModalResult := mrCancel;
  FBtnCancel.Top := ClientHeight - 40;
  FBtnCancel.Left := ClientWidth - 90;
  FBtnCancel.Anchors := [akRight, akBottom];
  FBtnCancel.OnClick := BtnCancelClick;

  topOffset := 8;
  for I := 1 to 6 do
  begin
    BuildGroup(I, topOffset);
    Inc(topOffset, FGroupPanel[I].Height + 8);
  end;
end;

procedure TfrmMirrorSettings.BuildGroup(Index: Integer; TopOffset: Integer);
var
  L: TLabel;
  bodyHeight: Integer;
begin
  bodyHeight := 80;

  FGroupPanel[Index] := TPanel.Create(FScrollBox);
  with FGroupPanel[Index] do
  begin
    Parent := FScrollBox;
    Left := 8;
    Top := TopOffset;
    Width := FScrollBox.ClientWidth - 16;
    Height := 32 + bodyHeight;
    BevelOuter := bvRaised;
    Anchors := [akLeft, akTop, akRight];
  end;

  // 头部
  FHeaderCheck[Index] := TCheckBox.Create(FGroupPanel[Index]);
  with FHeaderCheck[Index] do
  begin
    Parent := FGroupPanel[Index];
    Left := 8;
    Top := 8;
    Caption := Format('启用 镜像组 %d', [Index]);
    OnClick := HeaderCheckClick;
  end;

  FHeaderLabel[Index] := TLabel.Create(FGroupPanel[Index]);
  with FHeaderLabel[Index] do
  begin
    Parent := FGroupPanel[Index];
    Left := 160;
    Top := 10;
    Caption := '';
    AutoSize := True;
  end;

  FToggleButton[Index] := TButton.Create(FGroupPanel[Index]);
  with FToggleButton[Index] do
  begin
    Parent := FGroupPanel[Index];
    Width := 60;
    Height := 22;
    Top := 6;
    Left := FGroupPanel[Index].Width - Width - 8;
    Anchors := [akTop, akRight];
    Caption := '折叠';
    Tag := Index;
    OnClick := ToggleButtonClick;
  end;

  // 内容
  FBodyPanel[Index] := TPanel.Create(FGroupPanel[Index]);
  with FBodyPanel[Index] do
  begin
    Parent := FGroupPanel[Index];
    Left := 4;
    Top := 32;
    Width := FGroupPanel[Index].Width - 8;
    Height := bodyHeight;
    Anchors := [akLeft, akTop, akRight];
    BevelOuter := bvNone;
  end;

  // 源目录
  L := TLabel.Create(FBodyPanel[Index]);
  L.Parent := FBodyPanel[Index];
  L.Left := 8;
  L.Top := 8;
  L.Caption := '源目录:';

  FEdtSource[Index] := TEdit.Create(FBodyPanel[Index]);
  with FEdtSource[Index] do
  begin
    Parent := FBodyPanel[Index];
    Left := 70;
    Top := 4;
    Width := 360;
  end;

  FBtnBrowseSource[Index] := TButton.Create(FBodyPanel[Index]);
  with FBtnBrowseSource[Index] do
  begin
    Parent := FBodyPanel[Index];
    Left := 440;
    Top := 2;
    Width := 60;
    Caption := '浏览';
    Tag := Index;
    OnClick := BrowseSourceClick;
  end;

  // 备份目录
  L := TLabel.Create(FBodyPanel[Index]);
  L.Parent := FBodyPanel[Index];
  L.Left := 8;
  L.Top := 34;
  L.Caption := '备份目录:';

  FEdtBackup[Index] := TEdit.Create(FBodyPanel[Index]);
  with FEdtBackup[Index] do
  begin
    Parent := FBodyPanel[Index];
    Left := 70;
    Top := 30;
    Width := 360;
  end;

  FBtnBrowseBackup[Index] := TButton.Create(FBodyPanel[Index]);
  with FBtnBrowseBackup[Index] do
  begin
    Parent := FBodyPanel[Index];
    Left := 440;
    Top := 28;
    Width := 60;
    Caption := '浏览';
    Tag := Index;
    OnClick := BrowseBackupClick;
  end;

  // 类型
  L := TLabel.Create(FBodyPanel[Index]);
  L.Parent := FBodyPanel[Index];
  L.Left := 520;
  L.Top := 8;
  L.Caption := '类型:';

  FCmbType[Index] := TComboBox.Create(FBodyPanel[Index]);
  with FCmbType[Index] do
  begin
    Parent := FBodyPanel[Index];
    Left := 560;
    Top := 4;
    Width := 180;
    Style := csDropDownList;
  end;
  LoadTypesToCombo(FCmbType[Index]);

  // 间隔
  L := TLabel.Create(FBodyPanel[Index]);
  L.Parent := FBodyPanel[Index];
  L.Left := 520;
  L.Top := 34;
  L.Caption := '间隔(分钟):';

  FEdtInterval[Index] := TEdit.Create(FBodyPanel[Index]);
  with FEdtInterval[Index] do
  begin
    Parent := FBodyPanel[Index];
    Left := 600;
    Top := 30;
    Width := 40;
  end;

  // 每周同步
  FChkWeekly[Index] := TCheckBox.Create(FBodyPanel[Index]);
  with FChkWeekly[Index] do
  begin
    Parent := FBodyPanel[Index];
    Left := 660;
    Top := 30;
    Caption := '每周同步';
  end;

  FCmbWeeklyDay[Index] := TComboBox.Create(FBodyPanel[Index]);
  with FCmbWeeklyDay[Index] do
  begin
    Parent := FBodyPanel[Index];
    Left := 740;
    Top := 28;
    Width := 70;
    Style := csDropDownList;
    Items.Add('周一');
    Items.Add('周二');
    Items.Add('周三');
    Items.Add('周四');
    Items.Add('周五');
    Items.Add('周六');
    Items.Add('周日');
    ItemIndex := 0;
  end;

  FEdtWeeklyTime[Index] := TEdit.Create(FBodyPanel[Index]);
  with FEdtWeeklyTime[Index] do
  begin
    Parent := FBodyPanel[Index];
    Left := 820;
    Top := 30;
    Width := 60;
    Text := '23:00';
  end;
end;

procedure TfrmMirrorSettings.ToggleGroup(Index: Integer);
begin
  if not Assigned(FBodyPanel[Index]) then Exit;

  FBodyPanel[Index].Visible := not FBodyPanel[Index].Visible;
  if FBodyPanel[Index].Visible then
    FToggleButton[Index].Caption := '折叠'
  else
    FToggleButton[Index].Caption := '展开';
end;

procedure TfrmMirrorSettings.ToggleButtonClick(Sender: TObject);
var
  idx: Integer;
begin
  idx := TButton(Sender).Tag;
  ToggleGroup(idx);
end;

procedure TfrmMirrorSettings.BrowseSourceClick(Sender: TObject);
var
  idx: Integer;
  dir: string;
begin
  idx := TButton(Sender).Tag;
  dir := FEdtSource[idx].Text;
  if dir = '' then
    dir := 'C:\\';
  if SelectDirectory('选择源目录', '', dir) then
    FEdtSource[idx].Text := dir;
end;

procedure TfrmMirrorSettings.BrowseBackupClick(Sender: TObject);
var
  idx: Integer;
  dir: string;
begin
  idx := TButton(Sender).Tag;
  dir := FEdtBackup[idx].Text;
  if dir = '' then
    dir := 'D:\\';
  if SelectDirectory('选择备份目录', '', dir) then
    FEdtBackup[idx].Text := dir;
end;

procedure TfrmMirrorSettings.HeaderCheckClick(Sender: TObject);
var
  idx: Integer;
begin
  idx := TCheckBox(Sender).Tag;
  // 目前只做简单占位，可在这里控制 body 是否可编辑
end;

procedure TfrmMirrorSettings.BtnOKClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfrmMirrorSettings.BtnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmMirrorSettings.MirrorToControls(const Mirrors: TMirrorConfigArray);
var
  I: Integer;
begin
  for I := 1 to 6 do
  begin
    FHeaderCheck[I].Checked := Mirrors[I].Enabled;
    FHeaderCheck[I].Tag := I;

    FEdtSource[I].Text := Mirrors[I].SourceDir;
    FEdtBackup[I].Text := Mirrors[I].BackupDir;
    FEdtInterval[I].Text := IntToStr(Mirrors[I].IntervalMinutes);

    FChkWeekly[I].Checked := Mirrors[I].WeeklyEnabled;
    if (Mirrors[I].WeeklyDayOfWeek >= 1) and (Mirrors[I].WeeklyDayOfWeek <= 7) then
      FCmbWeeklyDay[I].ItemIndex := Mirrors[I].WeeklyDayOfWeek - 1
    else
      FCmbWeeklyDay[I].ItemIndex := 0;

    if Mirrors[I].WeeklyTime > 0 then
      FEdtWeeklyTime[I].Text := TimeToStr(Mirrors[I].WeeklyTime)
    else
      FEdtWeeklyTime[I].Text := '23:00';

    if (Ord(Mirrors[I].MirrorType) >= 0) and (Ord(Mirrors[I].MirrorType) < FCmbType[I].Items.Count) then
      FCmbType[I].ItemIndex := Ord(Mirrors[I].MirrorType)
    else
      FCmbType[I].ItemIndex := 0;
  end;
end;

procedure TfrmMirrorSettings.ControlsToMirror(var Mirrors: TMirrorConfigArray);
var
  I: Integer;
  minutes: Integer;
  t: TDateTime;
begin
  for I := 1 to 6 do
  begin
    Mirrors[I].Enabled := FHeaderCheck[I].Checked;
    Mirrors[I].SourceDir := Trim(FEdtSource[I].Text);
    Mirrors[I].BackupDir := Trim(FEdtBackup[I].Text);

    minutes := StrToIntDef(FEdtInterval[I].Text, 60);
    if minutes < 1 then minutes := 1;
    Mirrors[I].IntervalMinutes := minutes;

    Mirrors[I].WeeklyEnabled := FChkWeekly[I].Checked;
    Mirrors[I].WeeklyDayOfWeek := FCmbWeeklyDay[I].ItemIndex + 1;

    try
      t := StrToTime(FEdtWeeklyTime[I].Text);
    except
      t := EncodeTime(23, 0, 0, 0);
    end;
    Mirrors[I].WeeklyTime := t;

    Mirrors[I].MirrorType := TMirrorType(FCmbType[I].ItemIndex);
  end;
end;

procedure TfrmMirrorSettings.LoadTypesToCombo(Cmb: TComboBox);
begin
  Cmb.Items.Clear;
  Cmb.Items.Add('临时文件清理（.tmp/.bak 等）');
  Cmb.Items.Add('日志清理（过期 .log/.trace）');
  Cmb.Items.Add('缓存目录清理（cache/temp 等）');
  Cmb.Items.Add('安装残留清理（旧安装包/镜像）');
  Cmb.Items.Add('大文件扫描（仅列出大文件）');
  Cmb.Items.Add('自定义白名单模式（高级）');
  Cmb.ItemIndex := 0;
end;

end.

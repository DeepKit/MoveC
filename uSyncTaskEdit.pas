unit uSyncTaskEdit;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  uSyncEngine, uSyncDatabase, uFileSystemWatcher;

type
  TfrmSyncTaskEdit = class(TForm)
    edtName: TEdit;
    edtSource: TEdit;
    edtTarget: TEdit;
    lblName: TLabel;
    lblSource: TLabel;
    lblTarget: TLabel;
    btnBrowseSrc: TButton;
    btnBrowseDst: TButton;
    cbCategory: TComboBox;
    lblCategory: TLabel;
    rgMode: TRadioGroup;
    chkEnabled: TCheckBox;
    btnOK: TButton;
    btnCancel: TButton;
    lblRealtime: TLabel;
    edtInterval: TEdit;
    lblInterval: TLabel;
    chkRecursive: TCheckBox;
    rgWatchMode: TRadioGroup;
    lblIgnore: TLabel;
    edtIgnoreRules: TEdit;
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnBrowseSrcClick(Sender: TObject);
    procedure btnBrowseDstClick(Sender: TObject);
  private
    FTask: uSyncEngine.TSyncTask;
    procedure LoadFromTask;
    procedure SaveToTask;
  public
    class function EditTask(AOwner: TComponent; ATask: uSyncEngine.TSyncTask): Boolean; static;
  end;

implementation

{$R *.dfm}

uses Vcl.FileCtrl;

class function TfrmSyncTaskEdit.EditTask(AOwner: TComponent; ATask: uSyncEngine.TSyncTask): Boolean;
var
  F: TfrmSyncTaskEdit;
begin
  Result := False;
  F := TfrmSyncTaskEdit.Create(AOwner);
  try
    F.FTask := ATask;
    F.LoadFromTask;
    if F.ShowModal = mrOk then
    begin
      F.SaveToTask;
      Result := True;
    end;
  finally
    F.Free;
  end;
end;

procedure TfrmSyncTaskEdit.LoadFromTask;
var
  idx: Integer;
begin
  if not Assigned(FTask) then Exit;
  edtName.Text := FTask.Name;
  edtSource.Text := FTask.SourcePath;
  edtTarget.Text := FTask.TargetPath;
  cbCategory.Items.Clear;
  cbCategory.Items.Add('文档');
  cbCategory.Items.Add('代码');
  cbCategory.Items.Add('媒体');
  cbCategory.Items.Add('备份');
  cbCategory.Items.Add('自定义');
  case FTask.Category of
    uSyncDatabase.scDocuments: cbCategory.ItemIndex := 0;
    uSyncDatabase.scCode: cbCategory.ItemIndex := 1;
    uSyncDatabase.scMedia: cbCategory.ItemIndex := 2;
    uSyncDatabase.scBackup: cbCategory.ItemIndex := 3;
  else
    cbCategory.ItemIndex := 4;
  end;
  rgMode.Items.Clear;
  rgMode.Items.Add('手动');
  rgMode.Items.Add('实时');
  if FTask.Mode = uSyncDatabase.smManual then rgMode.ItemIndex := 0 else rgMode.ItemIndex := 1;
  chkEnabled.Checked := FTask.Enabled;
  // Realtime parameters
  edtInterval.Text := IntToStr(Integer(FTask.RealtimeIntervalMs));
  chkRecursive.Checked := FTask.RealtimeRecursive;
  rgWatchMode.Items.Clear;
  rgWatchMode.Items.Add('轮询');
  rgWatchMode.Items.Add('原生');
  idx := 0;
  if FTask.WatchMode = uFileSystemWatcher.TWatchMode.wmNative then idx := 1;
  rgWatchMode.ItemIndex := idx;
  // Ignore rules
  edtIgnoreRules.Text := FTask.IgnoreRulesText;
end;

procedure TfrmSyncTaskEdit.SaveToTask;
var
  V: Integer;
begin
  if not Assigned(FTask) then Exit;
  FTask.Name := edtName.Text;
  FTask.SourcePath := edtSource.Text;
  FTask.TargetPath := edtTarget.Text;
  case cbCategory.ItemIndex of
    0: FTask.Category := uSyncDatabase.scDocuments;
    1: FTask.Category := uSyncDatabase.scCode;
    2: FTask.Category := uSyncDatabase.scMedia;
    3: FTask.Category := uSyncDatabase.scBackup;
  else
    FTask.Category := uSyncDatabase.scCustom;
  end;
  if rgMode.ItemIndex = 0 then FTask.Mode := uSyncDatabase.smManual else FTask.Mode := uSyncDatabase.smRealtime;
  FTask.Enabled := chkEnabled.Checked;
  // Realtime parameters
  V := StrToIntDef(edtInterval.Text, 300);
  if V < 50 then V := 50;
  FTask.RealtimeIntervalMs := V;
  FTask.RealtimeRecursive := chkRecursive.Checked;
  if rgWatchMode.ItemIndex = 1 then
    FTask.WatchMode := uFileSystemWatcher.TWatchMode.wmNative
  else
    FTask.WatchMode := uFileSystemWatcher.TWatchMode.wmPolling;
  // Ignore rules
  FTask.IgnoreRulesText := edtIgnoreRules.Text;
end;

procedure TfrmSyncTaskEdit.btnOKClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

procedure TfrmSyncTaskEdit.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmSyncTaskEdit.btnBrowseSrcClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtSource.Text;
  if SelectDirectory('选择源目录', '', Dir) then
    edtSource.Text := Dir;
end;

procedure TfrmSyncTaskEdit.btnBrowseDstClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtTarget.Text;
  if SelectDirectory('选择目标目录', '', Dir) then
    edtTarget.Text := Dir;
end;

end.

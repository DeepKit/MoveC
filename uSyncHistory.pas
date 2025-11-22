unit uSyncHistory;

interface

uses
  System.SysUtils, System.Classes, System.StrUtils,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Phys.SQLite, Data.DB, System.IOUtils;

type
  TfrmSyncHistory = class(TForm)
    cbTasks: TComboBox;
    lblTask: TLabel;
    lvHistory: TListView;
    btnClose: TButton;
    btnRefresh: TButton;
  private
    FConn: TFDConnection;
    FTaskId: string;
    FTaskIds: TStringList;
    procedure EnsureDatabase;
    procedure LoadTasks;
    procedure LoadHistory;
  public
    class procedure ShowHistory(AOwner: TComponent; const ATaskId: string = ''); static;
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbTasksChange(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
  end;

implementation

{$R *.dfm}

class procedure TfrmSyncHistory.ShowHistory(AOwner: TComponent; const ATaskId: string);
var
  F: TfrmSyncHistory;
begin
  F := TfrmSyncHistory.Create(AOwner);
  try
    F.FTaskId := ATaskId;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmSyncHistory.EnsureDatabase;
begin
  if not Assigned(FConn) then
  begin
    FConn := TFDConnection.Create(Self);
    FConn.DriverName := 'SQLite';
    FConn.LoginPrompt := False;
    FConn.Params.Values['Database'] := TPath.Combine(ExtractFilePath(ParamStr(0)), 'MoveC.db');
    FConn.Connected := True;
  end;
end;

procedure TfrmSyncHistory.FormShow(Sender: TObject);
begin
  EnsureDatabase;
  if not Assigned(FTaskIds) then
    FTaskIds := TStringList.Create;
  // setup columns
  lvHistory.ViewStyle := vsReport;
  lvHistory.Columns.Clear;
  with lvHistory.Columns.Add do Caption := '开始时间';
  with lvHistory.Columns.Add do Caption := '结束时间';
  with lvHistory.Columns.Add do Caption := '状态';
  with lvHistory.Columns.Add do Caption := '错误信息';
  LoadTasks;
  LoadHistory;
end;

procedure TfrmSyncHistory.FormDestroy(Sender: TObject);
begin
  if Assigned(FConn) then
  begin
    try FConn.Connected := False; except end;
    FreeAndNil(FConn);
  end;
  FreeAndNil(FTaskIds);
end;

procedure TfrmSyncHistory.LoadTasks;
var
  Q: TFDQuery;
  Id, Name: string;
  I, IndexToSelect: Integer;
begin
  cbTasks.Items.BeginUpdate;
  try
    cbTasks.Clear;
    if not Assigned(FTaskIds) then
      FTaskIds := TStringList.Create
    else
      FTaskIds.Clear;
    cbTasks.Items.Add('全部任务');
    FTaskIds.Add('');
    EnsureDatabase;
    Q := TFDQuery.Create(Self);
    try
      Q.Connection := FConn;
      Q.SQL.Text := 'SELECT task_id, task_name FROM sync_tasks ORDER BY task_name';
      Q.Open;
      while not Q.Eof do
      begin
        Id := Q.FieldByName('task_id').AsString;
        Name := Q.FieldByName('task_name').AsString;
        cbTasks.Items.Add(Name);
        FTaskIds.Add(Id);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    cbTasks.Items.EndUpdate;
  end;
  // preselect
  IndexToSelect := 0;
  if FTaskId <> '' then
  begin
    for I := 1 to FTaskIds.Count - 1 do
      if SameText(FTaskIds[I], FTaskId) then
      begin
        IndexToSelect := I;
        Break;
      end;
  end;
  cbTasks.ItemIndex := IndexToSelect;
end;

procedure TfrmSyncHistory.LoadHistory;
var
  Q: TFDQuery;
  It: TListItem;
  SelId: string;
begin
  lvHistory.Items.BeginUpdate;
  try
    lvHistory.Items.Clear;
    EnsureDatabase;
    // selected task id
    SelId := '';
    if (cbTasks.ItemIndex >= 0) and (cbTasks.ItemIndex < FTaskIds.Count) then
      SelId := FTaskIds[cbTasks.ItemIndex];
    Q := TFDQuery.Create(Self);
    try
      Q.Connection := FConn;
      if SelId <> '' then
      begin
        Q.SQL.Text := 'SELECT sync_start_time, sync_end_time, status, error_message FROM sync_history WHERE task_id = :id ORDER BY sync_start_time DESC';
        Q.ParamByName('id').AsString := SelId;
      end
      else
      begin
        Q.SQL.Text := 'SELECT sync_start_time, sync_end_time, status, error_message FROM sync_history ORDER BY sync_start_time DESC';
      end;
      Q.Open;
      while not Q.Eof do
      begin
        It := lvHistory.Items.Add;
        It.Caption := Q.FieldByName('sync_start_time').AsString;
        It.SubItems.Add(Q.FieldByName('sync_end_time').AsString);
        It.SubItems.Add(Q.FieldByName('status').AsString);
        It.SubItems.Add(Q.FieldByName('error_message').AsString);
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    lvHistory.Items.EndUpdate;
  end;
end;

procedure TfrmSyncHistory.cbTasksChange(Sender: TObject);
begin
  LoadHistory;
end;

procedure TfrmSyncHistory.btnRefreshClick(Sender: TObject);
begin
  LoadHistory;
end;

end.

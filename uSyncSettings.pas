unit uSyncSettings;

interface

uses
  System.SysUtils, System.Classes, System.StrUtils,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Dialogs,
  uSyncEngine, uSyncTaskEdit, uSyncDatabase, uFileSystemWatcher, uSyncHistory,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Phys.SQLite, Data.DB, System.IOUtils,
  Winapi.Windows, Vcl.ExtCtrls;

type
  TfrmSyncSettings = class(TForm)
    lvTasks: TListView;
    btnSyncNow: TButton;
    btnClose: TButton;
    lblHint: TLabel;
    btnNew: TButton;
    btnEdit: TButton;
    btnDelete: TButton;
    btnToggleEnable: TButton;
    cbFilter: TComboBox;
    lblFilter: TLabel;
    btnHistory: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnSyncNowClick(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnToggleEnableClick(Sender: TObject);
    procedure cbFilterChange(Sender: TObject);
    procedure btnHistoryClick(Sender: TObject);
    procedure lvTasksDblClick(Sender: TObject);
    procedure lvTasksKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FEngine: uSyncEngine.TSyncEngine;
    FConn: TFDConnection;
    FLastStartTime: TDateTime;
    FUiTimer: TTimer;
    procedure LoadTasks;
    function CategoryToString(C: uSyncDatabase.TSyncCategory): string;
    function ModeToString(M: uSyncDatabase.TSyncMode): string;
    function WatchModeToString(W: uFileSystemWatcher.TWatchMode): string;
    function GetSelectedTask: uSyncEngine.TSyncTask;
    procedure OnTaskProgress(const P: uSyncEngine.TSyncProgress);
    procedure OnTaskComplete(Success: Boolean; const Msg: string);
    function FilterMatch(T: uSyncEngine.TSyncTask): Boolean;
    procedure EnsureDatabase;
    procedure LoadTasksFromDb;
    procedure SaveTasksToDb;
    procedure UpsertTask(const T: uSyncEngine.TSyncTask);
    procedure DeleteTaskFromDb(const T: uSyncEngine.TSyncTask);
    procedure InsertHistory(const T: uSyncEngine.TSyncTask; Success: Boolean; const Msg: string);
    procedure UpdateListStatuses(Sender: TObject);
  public
    property Engine: TSyncEngine read FEngine write FEngine;
    class procedure ShowSettings(AOwner: TComponent); static;
  end;


implementation

{$R *.dfm}

procedure TfrmSyncSettings.FormCreate(Sender: TObject);
begin
  // 初始化同步引擎
  FEngine := uSyncEngine.TSyncEngine.Create(Self);
  
  // 准备筛选项
  cbFilter.Items.Clear;
  cbFilter.Items.Add('全部');
  cbFilter.Items.Add('文档');
  cbFilter.Items.Add('代码');
  cbFilter.Items.Add('媒体');
  cbFilter.Items.Add('备份');
  cbFilter.Items.Add('自定义');
  cbFilter.ItemIndex := 0;

  // 准备列
  lvTasks.ViewStyle := vsReport;
  lvTasks.Columns.Clear;
  with lvTasks.Columns.Add do Caption := '任务名称';
  with lvTasks.Columns.Add do Caption := '源路径';
  with lvTasks.Columns.Add do Caption := '目标路径';
  with lvTasks.Columns.Add do Caption := '分类';
  with lvTasks.Columns.Add do Caption := '模式';
  with lvTasks.Columns.Add do Caption := '监控方式';
  with lvTasks.Columns.Add do Caption := '间隔(ms)';
  with lvTasks.Columns.Add do Caption := '递归';
  with lvTasks.Columns.Add do Caption := '忽略规则';
  with lvTasks.Columns.Add do Caption := '状态';

  EnsureDatabase;

  // 启动UI状态刷新定时器
  if not Assigned(FUiTimer) then
  begin
    FUiTimer := TTimer.Create(Self);
    FUiTimer.Interval := 800; // 0.8秒刷新一次
    FUiTimer.OnTimer := UpdateListStatuses;
    FUiTimer.Enabled := True;
  end;
end;

procedure TfrmSyncSettings.FormShow(Sender: TObject);
begin
  LoadTasksFromDb;
  // 若数据库为空，则把引擎预置写入DB
  if (Assigned(FEngine)) and (FEngine.Tasks.Count > 0) and (lvTasks.Items.Count = 0) then
    SaveTasksToDb;
  LoadTasks;
end;

procedure TfrmSyncSettings.FormDestroy(Sender: TObject);
begin
  if Assigned(FUiTimer) then
  begin
    FUiTimer.Enabled := False;
    FreeAndNil(FUiTimer);
  end;
  if Assigned(FConn) then
  begin
    try FConn.Connected := False; except end;
    FreeAndNil(FConn);
  end;
  if Assigned(FEngine) then
  begin
    FreeAndNil(FEngine);
  end;
end;

function TfrmSyncSettings.CategoryToString(C: uSyncDatabase.TSyncCategory): string;
begin
  case C of
    scDocuments: Result := '文档';
    scCode: Result := '代码';
    scMedia: Result := '媒体';
    scBackup: Result := '备份';
  else
    Result := '自定义';
  end;
end;

function TfrmSyncSettings.ModeToString(M: uSyncDatabase.TSyncMode): string;
begin
  case M of
    smManual: Result := '手动';
    smRealtime: Result := '实时';
  end;
end;

function TfrmSyncSettings.WatchModeToString(W: TWatchMode): string;
begin
  case W of
    TWatchMode.wmPolling: Result := '轮询';
    TWatchMode.wmNative: Result := '原生';
  else
    Result := '';
  end;
end;

procedure TfrmSyncSettings.LoadTasks;
var
  I: Integer;
  It: TListItem;
  T: uSyncEngine.TSyncTask;
begin
  lvTasks.Items.BeginUpdate;
  try
    lvTasks.Items.Clear;
    if not Assigned(FEngine) then Exit;
    for I := 0 to FEngine.Tasks.Count - 1 do
    begin
      T := FEngine.Tasks[I];
      if not FilterMatch(T) then
        Continue;
      It := lvTasks.Items.Add;
      It.Caption := T.Name;
      It.SubItems.Add(T.SourcePath);
      It.SubItems.Add(T.TargetPath);
      It.SubItems.Add(CategoryToString(T.Category));
      It.SubItems.Add(ModeToString(T.Mode));
      It.SubItems.Add(WatchModeToString(T.WatchMode));
      It.SubItems.Add(IntToStr(Integer(T.RealtimeIntervalMs)));
      It.SubItems.Add(IfThen(T.RealtimeRecursive, '是', '否'));
      It.SubItems.Add(T.IgnoreRulesText);
      It.SubItems.Add(IfThen(T.Enabled, '启用', '禁用'));
      It.Data := T;
    end;
  finally
    lvTasks.Items.EndUpdate;
  end;
end;

function TfrmSyncSettings.GetSelectedTask: uSyncEngine.TSyncTask;
begin
  Result := nil;
  if Assigned(lvTasks.Selected) and Assigned(lvTasks.Selected.Data) then
    Result := uSyncEngine.TSyncTask(lvTasks.Selected.Data);
end;

procedure TfrmSyncSettings.OnTaskProgress(const P: uSyncEngine.TSyncProgress);
begin
  // 仅对“立即同步”的当前任务（选中项）显示进度；状态列索引为8（新增了4列）
  if Assigned(lvTasks.Selected) then
    lvTasks.Selected.SubItems[8] := Format('%.0f%%', [P.Percent]);
end;

procedure TfrmSyncSettings.OnTaskComplete(Success: Boolean; const Msg: string);
var
  T: uSyncEngine.TSyncTask;
begin
  // 仅对“立即同步”的当前任务（选中项）更新状态；统一状态列索引为8
  if Assigned(lvTasks.Selected) then
  begin
    if Success then
      lvTasks.Selected.SubItems[8] := '完成'
    else
      lvTasks.Selected.SubItems[8] := '失败: ' + Msg;
    // 记录历史
    T := GetSelectedTask;
    if Assigned(T) then
      InsertHistory(T, Success, Msg);
  end;
  Application.MessageBox(PChar(IfThen(Success, '同步完成', '同步失败：' + Msg)), '信息', MB_OK);
end;

procedure TfrmSyncSettings.btnSyncNowClick(Sender: TObject);
var
  Task: uSyncEngine.TSyncTask;
  PrevProg: uSyncEngine.TSyncProgressEvent;
  PrevComp: uSyncEngine.TSyncCompleteEvent;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then
  begin
    Application.MessageBox('请先选择一个任务。', '提示', MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  if not Task.Enabled then
  begin
    Application.MessageBox('该任务未启用。', '提示', MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  PrevProg := Task.OnProgress;
  PrevComp := Task.OnComplete;
  try
    FLastStartTime := Now;
    Task.OnProgress := OnTaskProgress;
    Task.OnComplete := OnTaskComplete;
    Task.Start;
  finally
    Task.OnProgress := PrevProg;
    Task.OnComplete := PrevComp;
  end;
end;

procedure TfrmSyncSettings.UpdateListStatuses(Sender: TObject);
var
  I: Integer;
  It: TListItem;
  T: uSyncEngine.TSyncTask;
  StatusText: string;
begin
  for I := 0 to lvTasks.Items.Count - 1 do
  begin
    It := lvTasks.Items[I];
    if not Assigned(It.Data) then Continue;
    T := uSyncEngine.TSyncTask(It.Data);
    case T.Status of
      ssRunning: StatusText := '运行中';
      ssIdle: StatusText := IfThen(T.Enabled, '启用', '禁用');
      ssPaused: StatusText := '暂停';
      ssError: StatusText := '错误';
      ssCompleted: StatusText := '完成';
    else
      StatusText := '';
    end;
    // 状态列索引为8
    if It.SubItems.Count >= 9 then
      It.SubItems[8] := StatusText;
  end;
end;

procedure TfrmSyncSettings.EnsureDatabase;
var
  DbPath: string;
  Q: TFDQuery;
begin
  if not Assigned(FConn) then
  begin
    FConn := TFDConnection.Create(Self);
    FConn.DriverName := 'SQLite';
    FConn.LoginPrompt := False;
    DbPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'MoveC.db');
    FConn.Params.Values['Database'] := DbPath;
    FConn.Connected := True;
  end;

  Q := TFDQuery.Create(Self);
  try
    Q.Connection := FConn;
    // 创建表（若不存在）- 使用与uSyncDatabase一致的列名
    Q.SQL.Text :=
      'CREATE TABLE IF NOT EXISTS sync_tasks ('+
      '  id INTEGER PRIMARY KEY AUTOINCREMENT,'+
      '  name TEXT NOT NULL,'+
      '  source_path TEXT NOT NULL,'+
      '  target_path TEXT NOT NULL,'+
      '  sync_mode INTEGER NOT NULL DEFAULT 0,'+
      '  conflict_strategy INTEGER NOT NULL DEFAULT 0,'+
      '  is_enabled BOOLEAN NOT NULL DEFAULT 1,'+
      '  filter_rules TEXT,'+
      '  preset_id INTEGER,'+
      '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,'+
      '  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP'+
      ');';
    Q.ExecSQL;

    Q.SQL.Text :=
      'CREATE TABLE IF NOT EXISTS sync_history ('+
      '  id INTEGER PRIMARY KEY AUTOINCREMENT,'+
      '  task_id INTEGER NOT NULL,'+
      '  sync_type TEXT NOT NULL,'+
      '  start_time DATETIME NOT NULL,'+
      '  end_time DATETIME,'+
      '  files_scanned INTEGER DEFAULT 0,'+
      '  files_copied INTEGER DEFAULT 0,'+
      '  files_updated INTEGER DEFAULT 0,'+
      '  files_deleted INTEGER DEFAULT 0,'+
      '  files_skipped INTEGER DEFAULT 0,'+
      '  bytes_transferred INTEGER DEFAULT 0,'+
      '  error_message TEXT,'+
      '  status TEXT NOT NULL DEFAULT ''running'','+
      '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP'+
      ');';
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TfrmSyncSettings.LoadTasksFromDb;
var
  Q: TFDQuery;
  T: uSyncEngine.TSyncTask;
  PresetId: Integer;
begin
  if not Assigned(FEngine) then Exit;
  if not Assigned(FConn) then EnsureDatabase;

  FEngine.Tasks.Clear; // 以数据库为准

  Q := TFDQuery.Create(Self);
  try
    Q.Connection := FConn;
    Q.SQL.Text := 'SELECT id, name, source_path, target_path, sync_mode, is_enabled, preset_id, filter_rules FROM sync_tasks';
    Q.Open;
    while not Q.Eof do
    begin
      T := uSyncEngine.TSyncTask.Create;
      T.TaskID := Q.FieldByName('id').AsInteger;
      T.Name := Q.FieldByName('name').AsString;
      T.SourcePath := Q.FieldByName('source_path').AsString;
      T.TargetPath := Q.FieldByName('target_path').AsString;
      if Q.FieldByName('sync_mode').AsInteger = 0 then T.Mode := uSyncDatabase.smManual else T.Mode := uSyncDatabase.smRealtime;
      T.Enabled := Q.FieldByName('is_enabled').AsBoolean;
      // 用 preset_id 存储分类 (INTEGER)
      PresetId := Q.FieldByName('preset_id').AsInteger;
      case PresetId of
        1: T.Category := uSyncDatabase.scDocuments;
        2: T.Category := uSyncDatabase.scCode;
        3: T.Category := uSyncDatabase.scMedia;
        4: T.Category := uSyncDatabase.scBackup;
      else
        T.Category := uSyncDatabase.scCustom;
      end;
      T.IgnoreRulesText := Q.FieldByName('filter_rules').AsString;
      FEngine.AddTask(T);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmSyncSettings.SaveTasksToDb;
var
  I: Integer;
begin
  if not Assigned(FConn) then EnsureDatabase;
  if not Assigned(FEngine) then Exit;
  for I := 0 to FEngine.Tasks.Count - 1 do
    UpsertTask(FEngine.Tasks[I]);
end;

procedure TfrmSyncSettings.UpsertTask(const T: uSyncEngine.TSyncTask);
var
  Q: TFDQuery;
  Cat: Integer;
begin
  case T.Category of
    uSyncDatabase.scDocuments: Cat := 1;
    uSyncDatabase.scCode: Cat := 2;
    uSyncDatabase.scMedia: Cat := 3;
    uSyncDatabase.scBackup: Cat := 4;
  else Cat := 0;
  end;

  Q := TFDQuery.Create(Self);
  try
    Q.Connection := FConn;
    if T.TaskID = 0 then
    begin
      // 新建任务
      Q.SQL.Text := 'INSERT INTO sync_tasks (name, source_path, target_path, sync_mode, is_enabled, preset_id, filter_rules) '+
                    'VALUES (:name, :src, :dst, :mode, :ena, :cat, :rules)';
      Q.ParamByName('name').AsString := T.Name;
      Q.ParamByName('src').AsString := T.SourcePath;
      Q.ParamByName('dst').AsString := T.TargetPath;
      Q.ParamByName('mode').AsInteger := Ord(T.Mode);
      Q.ParamByName('ena').AsBoolean := T.Enabled;
      Q.ParamByName('cat').AsInteger := Cat;
      Q.ParamByName('rules').AsString := T.IgnoreRulesText;
      Q.ExecSQL;
      // 获取新生成的ID
      T.TaskID := FConn.GetLastAutoGenValue('sync_tasks');
    end
    else
    begin
      // 更新现有任务
      Q.SQL.Text := 'UPDATE sync_tasks SET name = :name, source_path = :src, target_path = :dst, '+
                    'sync_mode = :mode, is_enabled = :ena, preset_id = :cat, filter_rules = :rules, '+
                    'updated_at = CURRENT_TIMESTAMP WHERE id = :id';
      Q.ParamByName('id').AsInteger := T.TaskID;
      Q.ParamByName('name').AsString := T.Name;
      Q.ParamByName('src').AsString := T.SourcePath;
      Q.ParamByName('dst').AsString := T.TargetPath;
      Q.ParamByName('mode').AsInteger := Ord(T.Mode);
      Q.ParamByName('ena').AsBoolean := T.Enabled;
      Q.ParamByName('cat').AsInteger := Cat;
      Q.ParamByName('rules').AsString := T.IgnoreRulesText;
      Q.ExecSQL;
    end;
  finally
    Q.Free;
  end;
end;

procedure TfrmSyncSettings.DeleteTaskFromDb(const T: uSyncEngine.TSyncTask);
var
  Q: TFDQuery;
begin
  if T.TaskID = 0 then Exit;
  Q := TFDQuery.Create(Self);
  try
    Q.Connection := FConn;
    Q.SQL.Text := 'DELETE FROM sync_tasks WHERE id = :id';
    Q.ParamByName('id').AsInteger := T.TaskID;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

procedure TfrmSyncSettings.InsertHistory(const T: uSyncEngine.TSyncTask; Success: Boolean; const Msg: string);
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(Self);
  try
    Q.Connection := FConn;
    Q.SQL.Text := 'INSERT INTO sync_history (task_id, sync_type, start_time, end_time, status, error_message) '+
                  'VALUES (:tid, :stype, :st, :et, :stt, :err)';
    Q.ParamByName('tid').AsInteger := T.TaskID;
    Q.ParamByName('stype').AsString := 'manual';
    Q.ParamByName('st').AsDateTime := FLastStartTime;
    Q.ParamByName('et').AsDateTime := Now;
    Q.ParamByName('stt').AsString := IfThen(Success, 'success', 'error');
    Q.ParamByName('err').AsString := Msg;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;


procedure TfrmSyncSettings.lvTasksDblClick(Sender: TObject);
begin
  btnEditClick(Sender);
end;

procedure TfrmSyncSettings.lvTasksKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_DELETE: btnDeleteClick(Sender);
    VK_SPACE: btnToggleEnableClick(Sender);
    VK_RETURN: btnEditClick(Sender);
  end;
end;

procedure TfrmSyncSettings.btnHistoryClick(Sender: TObject);
var
  Task: uSyncEngine.TSyncTask;
begin
  Task := GetSelectedTask;
  if Assigned(Task) then
    TfrmSyncHistory.ShowHistory(Self, IntToStr(Task.TaskID))
  else
    TfrmSyncHistory.ShowHistory(Self, '');
end;

function TfrmSyncSettings.FilterMatch(T: uSyncEngine.TSyncTask): Boolean;
begin
  case cbFilter.ItemIndex of
    0: Result := True; // 全部
    1: Result := T.Category = uSyncDatabase.scDocuments;
    2: Result := T.Category = uSyncDatabase.scCode;
    3: Result := T.Category = uSyncDatabase.scMedia;
    4: Result := T.Category = uSyncDatabase.scBackup;
    5: Result := T.Category = uSyncDatabase.scCustom;
  else
    Result := True;
  end;
end;

procedure TfrmSyncSettings.cbFilterChange(Sender: TObject);
begin
  LoadTasks;
end;

procedure TfrmSyncSettings.btnNewClick(Sender: TObject);
var
  NewTask: uSyncEngine.TSyncTask;
begin
  if not Assigned(FEngine) then Exit;
  NewTask := uSyncEngine.TSyncTask.Create;
  try
    NewTask.Name := '新建任务';
    NewTask.Mode := uSyncDatabase.smManual;
    NewTask.Category := uSyncDatabase.scCustom;
    NewTask.Enabled := True;
    if TfrmSyncTaskEdit.EditTask(Self, NewTask) then
    begin
      FEngine.AddTask(NewTask);
      UpsertTask(NewTask);
      LoadTasks;
      Exit; // 所有权交给引擎
    end;
  finally
    if (Assigned(NewTask)) and (FEngine.Tasks.IndexOf(NewTask) < 0) then
      NewTask.Free;
  end;
end;

procedure TfrmSyncSettings.btnEditClick(Sender: TObject);
var
  Task: uSyncEngine.TSyncTask;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then
  begin
    Application.MessageBox('请先选择一个任务。', '提示', MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  if TfrmSyncTaskEdit.EditTask(Self, Task) then
  begin
    UpsertTask(Task);
    LoadTasks;
  end;
end;

procedure TfrmSyncSettings.btnDeleteClick(Sender: TObject);
var
  Task: uSyncEngine.TSyncTask;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then
  begin
    Application.MessageBox('请先选择一个任务。', '提示', MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  if Application.MessageBox('确定要删除该任务吗？', '确认', MB_OKCANCEL or MB_ICONQUESTION) = IDOK then
  begin
    DeleteTaskFromDb(Task);
    FEngine.RemoveTask(Task);
    LoadTasks;
  end;
end;

procedure TfrmSyncSettings.btnToggleEnableClick(Sender: TObject);
var
  Task: uSyncEngine.TSyncTask;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then
  begin
    Application.MessageBox('请先选择一个任务。', '提示', MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  Task.Enabled := not Task.Enabled;
  UpsertTask(Task);
  LoadTasks;
end;

class procedure TfrmSyncSettings.ShowSettings(AOwner: TComponent);
var
  Form: TfrmSyncSettings;
begin
  Form := TfrmSyncSettings.Create(AOwner);
  try
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

end.

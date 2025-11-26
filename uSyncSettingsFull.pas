unit uSyncSettingsFull;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Controls, 
  Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs, Vcl.ComCtrls, Vcl.Grids,
  Vcl.Buttons, Vcl.Menus, Vcl.Graphics, System.IOUtils, System.Generics.Collections,
  uSyncEngine, uSyncDatabase, uSyncExecutorSimple;

type
  TfrmSyncSettingsFull = class(TForm)
    // 主面板
    pnlMain: TPanel;
    pnlHeader: TPanel;
    lblTitle: TLabel;
    lblDescription: TLabel;
    
    // 工具栏
    pnlToolbar: TPanel;
    btnNew: TBitBtn;
    btnEdit: TBitBtn;
    btnDelete: TBitBtn;
    btnToggleEnable: TBitBtn;
    btnSyncNow: TBitBtn;
    btnHistory: TBitBtn;
    btnPresets: TBitBtn;
    btnClose: TBitBtn;
    
    // 筛选面板
    pnlFilter: TPanel;
    lblFilter: TLabel;
    cbFilter: TComboBox;
    chkShowEnabled: TCheckBox;
    chkShowDisabled: TCheckBox;
    
    // 任务列表
    pnlTasks: TPanel;
    lvTasks: TListView;
    Splitter1: TSplitter;
    
    // 详情面板
    pnlDetails: TPanel;
    lblDetails: TLabel;
    memoDetails: TMemo;
    
    // 状态栏
    pnlStatus: TPanel;
    lblStatus: TLabel;
    ProgressBar1: TProgressBar;
    
    // 弹出菜单
    pmTasks: TPopupMenu;
    miNew: TMenuItem;
    miEdit: TMenuItem;
    miDelete: TMenuItem;
    miToggleEnable: TMenuItem;
    miSyncNow: TMenuItem;
    miViewHistory: TMenuItem;
    miCopyPath: TMenuItem;
    miOpenSource: TMenuItem;
    miOpenTarget: TMenuItem;
    
    // 事件处理
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    
    // 工具栏按钮事件
    procedure btnNewClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnToggleEnableClick(Sender: TObject);
    procedure btnSyncNowClick(Sender: TObject);
    procedure btnHistoryClick(Sender: TObject);
    procedure btnPresetsClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    
    // 筛选事件
    procedure cbFilterChange(Sender: TObject);
    procedure chkShowEnabledClick(Sender: TObject);
    procedure chkShowDisabledClick(Sender: TObject);
    
    // 列表事件
    procedure lvTasksSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure lvTasksDblClick(Sender: TObject);
    procedure lvTasksKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure lvTasksCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    
    // 弹出菜单事件
    procedure miNewClick(Sender: TObject);
    procedure miEditClick(Sender: TObject);
    procedure miDeleteClick(Sender: TObject);
    procedure miToggleEnableClick(Sender: TObject);
    procedure miSyncNowClick(Sender: TObject);
    procedure miViewHistoryClick(Sender: TObject);
    procedure miCopyPathClick(Sender: TObject);
    procedure miOpenSourceClick(Sender: TObject);
    procedure miOpenTargetClick(Sender: TObject);
    
  private
    FEngine: TSyncEngine;
    FExecutor: TSyncExecutor;
    FDatabase: TSyncDatabase;
    FTasks: TObjectList<TSyncTask>;
    FCurrentTask: TSyncTask;
    FIsUpdating: Boolean;
    
    // 内部方法
    procedure InitializeInterface;
    procedure LoadTasks;
    procedure LoadTaskFromDatabase(ATask: TSyncTask);
    procedure SaveTaskToDatabase(ATask: TSyncTask);
    procedure RefreshTaskList;
    procedure ApplyFilters;
    procedure UpdateTaskDetails;
    procedure UpdateStatus(const AMessage: string);
    procedure EnableControls(AEnabled: Boolean);
    
    // 同步操作
    procedure ExecuteTaskSync(ATask: TSyncTask);
    procedure OnSyncProgress(const AProgress: TSyncProgressInfo);
    procedure OnSyncOperation(const AResult: TSyncOperationResult);
    procedure OnSyncCompleted(const ASuccess: Boolean; const ASummary: string);
    
    // 辅助方法
    function GetSelectedTask: TSyncTask;
    function TaskMatchesFilter(ATask: TSyncTask): Boolean;
    procedure AddTaskToList(ATask: TSyncTask);
    procedure UpdateTaskInList(ATask: TSyncTask);
    procedure RemoveTaskFromList(ATask: TSyncTask);
    function FormatTaskStatus(ATask: TSyncTask): string;
    function FormatTaskMode(ATask: TSyncTask): string;
    function FormatTaskCategory(ATask: TSyncTask): string;
    procedure ShowTaskHistory(ATask: TSyncTask);
    
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    class procedure ShowSettings(AOwner: TComponent); static;
  end;

implementation

{$R *.dfm}

class procedure TfrmSyncSettingsFull.ShowSettings(AOwner: TComponent);
var
  Form: TfrmSyncSettingsFull;
begin
  Form := TfrmSyncSettingsFull.Create(AOwner);
  try
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

constructor TfrmSyncSettingsFull.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEngine := TSyncEngine.Create(Self);
  FExecutor := TSyncExecutor.Create;
  FDatabase := TSyncDatabase.Create;
  FTasks := TObjectList<TSyncTask>.Create(True);
  FCurrentTask := nil;
  FIsUpdating := False;
  
  // 设置事件处理器
  FExecutor.OnProgress := OnSyncProgress;
  FExecutor.OnOperation := OnSyncOperation;
  FExecutor.OnCompleted := OnSyncCompleted;
end;

destructor TfrmSyncSettingsFull.Destroy;
begin
  FTasks.Free;
  FDatabase.Free;
  FExecutor.Free;
  FEngine.Free;
  inherited Destroy;
end;

procedure TfrmSyncSettingsFull.FormCreate(Sender: TObject);
begin
  InitializeInterface;
  UpdateStatus('同步盘设置已初始化');
end;

procedure TfrmSyncSettingsFull.FormDestroy(Sender: TObject);
begin
  // 清理资源
end;

procedure TfrmSyncSettingsFull.FormShow(Sender: TObject);
begin
  try
    // 初始化数据库
    FDatabase.Initialize;
    
    // 加载任务
    LoadTasks;
    RefreshTaskList;
    
    UpdateStatus('已加载 ' + IntToStr(FTasks.Count) + ' 个同步任务');
  except
    on E: Exception do
    begin
      UpdateStatus('加载失败: ' + E.Message);
      ShowMessage('加载同步任务失败: ' + E.Message);
    end;
  end;
end;

procedure TfrmSyncSettingsFull.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // 保存所有任务状态
  try
    for var I := 0 to FTasks.Count - 1 do
    begin
      if FTasks[I].Enabled then
        SaveTaskToDatabase(FTasks[I]);
    end;
  except
    // 忽略保存错误
  end;
end;

procedure TfrmSyncSettingsFull.InitializeInterface;
begin
  // 设置窗体标题
  Caption := '同步盘设置';
  
  // 初始化筛选器
  cbFilter.Items.Clear;
  cbFilter.Items.Add('全部');
  cbFilter.Items.Add('文档');
  cbFilter.Items.Add('代码');
  cbFilter.Items.Add('媒体');
  cbFilter.Items.Add('备份');
  cbFilter.Items.Add('自定义');
  cbFilter.ItemIndex := 0;
  
  chkShowEnabled.Checked := True;
  chkShowDisabled.Checked := True;
  
  // 初始化列表视图
  lvTasks.ViewStyle := vsReport;
  lvTasks.GridLines := True;
  lvTasks.RowSelect := True;
  lvTasks.ReadOnly := True;
  
  // 设置列
  lvTasks.Columns.Clear;
  with lvTasks.Columns.Add do
  begin
    Caption := '任务名称';
    Width := 150;
  end;
  with lvTasks.Columns.Add do
  begin
    Caption := '源路径';
    Width := 200;
  end;
  with lvTasks.Columns.Add do
  begin
    Caption := '目标路径';
    Width := 200;
  end;
  with lvTasks.Columns.Add do
  begin
    Caption := '分类';
    Width := 60;
  end;
  with lvTasks.Columns.Add do
  begin
    Caption := '模式';
    Width := 60;
  end;
  with lvTasks.Columns.Add do
  begin
    Caption := '状态';
    Width := 80;
  end;
  with lvTasks.Columns.Add do
  begin
    Caption := '最后同步';
    Width := 120;
  end;
  
  // 设置状态栏
  lblStatus.Caption := '就绪';
  ProgressBar1.Visible := False;
end;

procedure TfrmSyncSettingsFull.LoadTasks;
var
  TaskRecords: TArray<TSyncTask>;
  Task: TSyncTask;
begin
  FTasks.Clear;
  
  try
    // 从数据库加载任务
    TaskRecords := FDatabase.LoadAllTasks;
    
    for var I := 0 to High(TaskRecords) do
    begin
      Task := TSyncTask.Create;
      Task.Assign(TaskRecords[I]);
      LoadTaskFromDatabase(Task);
      FTasks.Add(Task);
    end;
    
    // 添加默认的样例任务（如果没有任务）
    if FTasks.Count = 0 then
    begin
      Task := TSyncTask.Create;
      Task.Name := '文档同步示例';
      Task.SourcePath := IncludeTrailingPathDelimiter(GetEnvironmentVariable('USERPROFILE')) + 'Documents';
      Task.TargetPath := 'D:\Backup\Documents';
      Task.Mode := smManual;
      Task.Category := scDocuments;
      Task.Enabled := False;
      Task.ConflictStrategy := csAsk;
      FTasks.Add(Task);
    end;
  except
    on E: Exception do
      raise Exception.Create('加载任务失败: ' + E.Message);
  end;
end;

procedure TfrmSyncSettingsFull.LoadTaskFromDatabase(ATask: TSyncTask);
begin
  // 从数据库加载任务的详细配置
  try
    var TaskData := FDatabase.LoadTask(ATask.TaskID);
    if Assigned(TaskData) then
    begin
      ATask.Assign(TaskData);
    end;
  except
    // 忽略加载错误，使用默认值
  end;
end;

procedure TfrmSyncSettingsFull.SaveTaskToDatabase(ATask: TSyncTask);
begin
  try
    if ATask.TaskID = 0 then
      FDatabase.CreateTask(ATask)
    else
      FDatabase.UpdateTask(ATask);
  except
    on E: Exception do
      raise Exception.Create('保存任务失败: ' + E.Message);
  end;
end;

procedure TfrmSyncSettingsFull.RefreshTaskList;
begin
  if FIsUpdating then Exit;
  
  FIsUpdating := True;
  try
    lvTasks.Items.BeginUpdate;
    try
      lvTasks.Items.Clear;
      
      for var I := 0 to FTasks.Count - 1 do
      begin
        if TaskMatchesFilter(FTasks[I]) then
          AddTaskToList(FTasks[I]);
      end;
    finally
      lvTasks.Items.EndUpdate;
    end;
    
    UpdateStatus('显示 ' + IntToStr(lvTasks.Items.Count) + ' 个任务');
  finally
    FIsUpdating := False;
  end;
end;

procedure TfrmSyncSettingsFull.ApplyFilters;
begin
  RefreshTaskList;
end;

procedure TfrmSyncSettingsFull.UpdateTaskDetails;
begin
  memoDetails.Clear;
  
  if not Assigned(FCurrentTask) then
  begin
    memoDetails.Lines.Add('请选择一个任务查看详细信息');
    Exit;
  end;
  
  memoDetails.Lines.Add('任务名称: ' + FCurrentTask.Name);
  memoDetails.Lines.Add('源路径: ' + FCurrentTask.SourcePath);
  memoDetails.Lines.Add('目标路径: ' + FCurrentTask.TargetPath);
  memoDetails.Lines.Add('分类: ' + FormatTaskCategory(FCurrentTask));
  memoDetails.Lines.Add('模式: ' + FormatTaskMode(FCurrentTask));
  memoDetails.Lines.Add('状态: ' + FormatTaskStatus(FCurrentTask));
  memoDetails.Lines.Add('启用: ' + BoolToStr(FCurrentTask.Enabled, True));
  memoDetails.Lines.Add('');
  
  if FCurrentTask.Mode = smRealtime then
  begin
    memoDetails.Lines.Add('实时监控参数:');
    memoDetails.Lines.Add('  监控间隔: ' + IntToStr(FCurrentTask.RealtimeIntervalMs) + 'ms');
    memoDetails.Lines.Add('  递归监控: ' + BoolToStr(FCurrentTask.RealtimeRecursive, True));
    memoDetails.Lines.Add('  监控模式: ' + GetEnumName(TypeInfo(TWatchMode), Ord(FCurrentTask.WatchMode)));
    memoDetails.Lines.Add('');
  end;
  
  if FCurrentTask.IgnoreRulesText <> '' then
  begin
    memoDetails.Lines.Add('忽略规则:');
    memoDetails.Lines.Add('  ' + FCurrentTask.IgnoreRulesText);
    memoDetails.Lines.Add('');
  end;
  
  memoDetails.Lines.Add('冲突策略: ' + GetEnumName(TypeInfo(TConflictStrategy), Ord(FCurrentTask.ConflictStrategy)));
end;

procedure TfrmSyncSettingsFull.UpdateStatus(const AMessage: string);
begin
  lblStatus.Caption := AMessage;
  Application.ProcessMessages;
end;

procedure TfrmSyncSettingsFull.EnableControls(AEnabled: Boolean);
begin
  btnNew.Enabled := AEnabled;
  btnEdit.Enabled := AEnabled and Assigned(FCurrentTask);
  btnDelete.Enabled := AEnabled and Assigned(FCurrentTask);
  btnToggleEnable.Enabled := AEnabled and Assigned(FCurrentTask);
  btnSyncNow.Enabled := AEnabled and Assigned(FCurrentTask) and FCurrentTask.Enabled;
  btnHistory.Enabled := AEnabled and Assigned(FCurrentTask);
  btnPresets.Enabled := AEnabled;
end;

// 工具栏按钮事件
procedure TfrmSyncSettingsFull.btnNewClick(Sender: TObject);
var
  NewTask: TSyncTask;
  TaskName: string;
  SourcePath, TargetPath: string;
begin
  // 简化的任务创建对话框
  TaskName := InputBox('新建同步任务', '请输入任务名称:', '新同步任务');
  if TaskName = '' then Exit;
  
  SourcePath := InputBox('新建同步任务', '请输入源路径:', 'C:\Users\' + GetEnvironmentVariable('USERNAME') + '\Documents');
  if SourcePath = '' then Exit;
  
  TargetPath := InputBox('新建同步任务', '请输入目标路径:', 'D:\Backup\Documents');
  if TargetPath = '' then Exit;
  
  try
    NewTask := TSyncTask.Create;
    NewTask.Name := TaskName;
    NewTask.SourcePath := SourcePath;
    NewTask.TargetPath := TargetPath;
    NewTask.Mode := smManual;
    NewTask.Category := scDocuments;
    NewTask.Enabled := False;
    NewTask.ConflictStrategy := csAsk;
    
    FTasks.Add(NewTask);
    SaveTaskToDatabase(NewTask);
    RefreshTaskList;
    UpdateStatus('已创建新任务: ' + NewTask.Name);
  except
    on E: Exception do
    begin
      UpdateStatus('创建任务失败: ' + E.Message);
      ShowMessage('创建任务失败: ' + E.Message);
    end;
  end;
end;

procedure TfrmSyncSettingsFull.btnEditClick(Sender: TObject);
var
  Task: TSyncTask;
  TaskName: string;
  SourcePath, TargetPath: string;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then Exit;
  
  // 简化的任务编辑对话框
  TaskName := InputBox('编辑同步任务', '请输入任务名称:', Task.Name);
  if TaskName = '' then Exit;
  
  SourcePath := InputBox('编辑同步任务', '请输入源路径:', Task.SourcePath);
  if SourcePath = '' then Exit;
  
  TargetPath := InputBox('编辑同步任务', '请输入目标路径:', Task.TargetPath);
  if TargetPath = '' then Exit;
  
  try
    Task.Name := TaskName;
    Task.SourcePath := SourcePath;
    Task.TargetPath := TargetPath;
    
    SaveTaskToDatabase(Task);
    RefreshTaskList;
    UpdateStatus('已更新任务: ' + Task.Name);
  except
    on E: Exception do
    begin
      UpdateStatus('编辑任务失败: ' + E.Message);
      ShowMessage('编辑任务失败: ' + E.Message);
    end;
  end;
end;

procedure TfrmSyncSettingsFull.btnDeleteClick(Sender: TObject);
var
  Task: TSyncTask;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then Exit;
  
  if ShowMessage('确定要删除任务 "' + Task.Name + '" 吗？' + #13#10 + '此操作不可撤销。', 
                mtConfirmation, [mbYes, mbNo], 0) = mrNo then Exit;
  
  try
    // 从数据库删除
    FDatabase.DeleteTask(Task.TaskID);
    
    // 从列表删除
    FTasks.Remove(Task);
    RefreshTaskList;
    
    UpdateStatus('已删除任务: ' + Task.Name);
  except
    on E: Exception do
    begin
      UpdateStatus('删除任务失败: ' + E.Message);
      ShowMessage('删除任务失败: ' + E.Message);
    end;
  end;
end;

procedure TfrmSyncSettingsFull.btnToggleEnableClick(Sender: TObject);
var
  Task: TSyncTask;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then Exit;
  
  try
    Task.Enabled := not Task.Enabled;
    SaveTaskToDatabase(Task);
    
    if Task.Enabled then
    begin
      Task.Start;
      UpdateStatus('已启用任务: ' + Task.Name);
    end
    else
    begin
      Task.Stop;
      UpdateStatus('已禁用任务: ' + Task.Name);
    end;
    
    RefreshTaskList;
  except
    on E: Exception do
    begin
      UpdateStatus('切换任务状态失败: ' + E.Message);
      ShowMessage('操作失败: ' + E.Message);
    end;
  end;
end;

procedure TfrmSyncSettingsFull.btnSyncNowClick(Sender: TObject);
var
  Task: TSyncTask;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then Exit;
  
  if not Task.Enabled then
  begin
    ShowMessage('请先启用该任务后再执行同步。');
    Exit;
  end;
  
  ExecuteTaskSync(Task);
end;

procedure TfrmSyncSettingsFull.btnHistoryClick(Sender: TObject);
var
  Task: TSyncTask;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then Exit;
  
  ShowTaskHistory(Task);
end;

procedure TfrmSyncSettingsFull.btnPresetsClick(Sender: TObject);
begin
  ShowMessage('预设管理功能正在开发中...');
end;

procedure TfrmSyncSettingsFull.btnCloseClick(Sender: TObject);
begin
  Close;
end;

// 筛选事件
procedure TfrmSyncSettingsFull.cbFilterChange(Sender: TObject);
begin
  ApplyFilters;
end;

procedure TfrmSyncSettingsFull.chkShowEnabledClick(Sender: TObject);
begin
  ApplyFilters;
end;

procedure TfrmSyncSettingsFull.chkShowDisabledClick(Sender: TObject);
begin
  ApplyFilters;
end;

// 列表事件
procedure TfrmSyncSettingsFull.lvTasksSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if Selected and Assigned(Item.Data) then
  begin
    FCurrentTask := TSyncTask(Item.Data);
    UpdateTaskDetails;
  end
  else
  begin
    FCurrentTask := nil;
    UpdateTaskDetails;
  end;
  
  EnableControls(True);
end;

procedure TfrmSyncSettingsFull.lvTasksDblClick(Sender: TObject);
begin
  btnEditClick(Sender);
end;

procedure TfrmSyncSettingsFull.lvTasksKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_F2: btnEditClick(Sender);
    VK_DELETE: btnDeleteClick(Sender);
    VK_F5: RefreshTaskList;
    VK_RETURN: btnSyncNowClick(Sender);
  end;
end;

procedure TfrmSyncSettingsFull.lvTasksCustomDrawItem(Sender: TCustomListView; 
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  Task: TSyncTask;
begin
  if not Assigned(Item.Data) then Exit;
  
  Task := TSyncTask(Item.Data);
  
  // 根据状态设置颜色
  if not Task.Enabled then
  begin
    Sender.Canvas.Font.Color := clGray;
  end
  else if Task.Status = ssRunning then
  begin
    Sender.Canvas.Font.Color := clBlue;
  end
  else if Task.Status = ssError then
  begin
    Sender.Canvas.Font.Color := clRed;
  end
  else if Task.Status = ssCompleted then
  begin
    Sender.Canvas.Font.Color := clGreen;
  end;
end;

// 弹出菜单事件
procedure TfrmSyncSettingsFull.miNewClick(Sender: TObject);
begin
  btnNewClick(Sender);
end;

procedure TfrmSyncSettingsFull.miEditClick(Sender: TObject);
begin
  btnEditClick(Sender);
end;

procedure TfrmSyncSettingsFull.miDeleteClick(Sender: TObject);
begin
  btnDeleteClick(Sender);
end;

procedure TfrmSyncSettingsFull.miToggleEnableClick(Sender: TObject);
begin
  btnToggleEnableClick(Sender);
end;

procedure TfrmSyncSettingsFull.miSyncNowClick(Sender: TObject);
begin
  btnSyncNowClick(Sender);
end;

procedure TfrmSyncSettingsFull.miViewHistoryClick(Sender: TObject);
begin
  btnHistoryClick(Sender);
end;

procedure TfrmSyncSettingsFull.miCopyPathClick(Sender: TObject);
var
  Task: TSyncTask;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then Exit;
  
  Clipboard.AsText := Task.SourcePath + ' -> ' + Task.TargetPath;
  UpdateStatus('已复制路径到剪贴板');
end;

procedure TfrmSyncSettingsFull.miOpenSourceClick(Sender: TObject);
var
  Task: TSyncTask;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then Exit;
  
  if TDirectory.Exists(Task.SourcePath) then
    ShellExecute(0, 'open', PChar(Task.SourcePath), nil, nil, SW_SHOWNORMAL)
  else
    ShowMessage('源路径不存在: ' + Task.SourcePath);
end;

procedure TfrmSyncSettingsFull.miOpenTargetClick(Sender: TObject);
var
  Task: TSyncTask;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then Exit;
  
  if TDirectory.Exists(Task.TargetPath) then
    ShellExecute(0, 'open', PChar(Task.TargetPath), nil, nil, SW_SHOWNORMAL)
  else
    ShowMessage('目标路径不存在: ' + Task.TargetPath);
end;

// 同步操作
procedure TfrmSyncSettingsFull.ExecuteTaskSync(ATask: TSyncTask);
begin
  if not Assigned(ATask) then Exit;
  
  try
    UpdateStatus('开始同步任务: ' + ATask.Name);
    ProgressBar1.Visible := True;
    ProgressBar1.Position := 0;
    EnableControls(False);
    
    // 执行同步
    ATask.Execute;
    
  except
    on E: Exception do
    begin
      UpdateStatus('同步失败: ' + E.Message);
      ShowMessage('同步失败: ' + E.Message);
    end;
  finally
    ProgressBar1.Visible := False;
    EnableControls(True);
    RefreshTaskList;
  end;
end;

procedure TfrmSyncSettingsFull.OnSyncProgress(const AProgress: TSyncProgressInfo);
begin
  ProgressBar1.Position := Round(AProgress.PercentComplete);
  UpdateStatus(AProgress.CurrentOperation + ' - ' + AProgress.CurrentFile);
end;

procedure TfrmSyncSettingsFull.OnSyncOperation(const AResult: TSyncOperationResult);
begin
  // 可以在这里记录每个操作的详细信息
end;

procedure TfrmSyncSettingsFull.OnSyncCompleted(const ASuccess: Boolean; const ASummary: string);
begin
  if ASuccess then
    UpdateStatus('同步完成: ' + ASummary)
  else
    UpdateStatus('同步失败: ' + ASummary);
end;

// 辅助方法
function TfrmSyncSettingsFull.GetSelectedTask: TSyncTask;
begin
  Result := nil;
  if (lvTasks.Selected <> nil) and Assigned(lvTasks.Selected.Data) then
    Result := TSyncTask(lvTasks.Selected.Data);
end;

function TfrmSyncSettingsFull.TaskMatchesFilter(ATask: TSyncTask): Boolean;
var
  ShowEnabled, ShowDisabled: Boolean;
  FilterCategory: string;
begin
  Result := False;
  
  // 检查启用状态筛选
  ShowEnabled := chkShowEnabled.Checked;
  ShowDisabled := chkShowDisabled.Checked;
  
  if ATask.Enabled and not ShowEnabled then Exit;
  if not ATask.Enabled and not ShowDisabled then Exit;
  
  // 检查分类筛选
  if cbFilter.ItemIndex > 0 then
  begin
    FilterCategory := cbFilter.Items[cbFilter.ItemIndex];
    
    case ATask.Category of
      scDocuments: Result := FilterCategory = '文档';
      scCode: Result := FilterCategory = '代码';
      scMedia: Result := FilterCategory = '媒体';
      scBackup: Result := FilterCategory = '备份';
    else
      Result := FilterCategory = '自定义';
    end;
    
    if not Result then Exit;
  end;
  
  Result := True;
end;

procedure TfrmSyncSettingsFull.AddTaskToList(ATask: TSyncTask);
var
  Item: TListItem;
begin
  Item := lvTasks.Items.Add;
  Item.Caption := ATask.Name;
  Item.SubItems.Add(ATask.SourcePath);
  Item.SubItems.Add(ATask.TargetPath);
  Item.SubItems.Add(FormatTaskCategory(ATask));
  Item.SubItems.Add(FormatTaskMode(ATask));
  Item.SubItems.Add(FormatTaskStatus(ATask));
  Item.SubItems.Add(DateTimeToStr(ATask.LastSyncTime));
  Item.Data := ATask;
  
  // 设置图标
  if ATask.Enabled then
    Item.ImageIndex := 0  // 启用图标
  else
    Item.ImageIndex := 1; // 禁用图标
end;

procedure TfrmSyncSettingsFull.UpdateTaskInList(ATask: TSyncTask);
var
  I: Integer;
  Item: TListItem;
begin
  for I := 0 to lvTasks.Items.Count - 1 do
  begin
    Item := lvTasks.Items[I];
    if Assigned(Item.Data) and (TSyncTask(Item.Data) = ATask) then
    begin
      Item.Caption := ATask.Name;
      Item.SubItems[0] := ATask.SourcePath;
      Item.SubItems[1] := ATask.TargetPath;
      Item.SubItems[2] := FormatTaskCategory(ATask);
      Item.SubItems[3] := FormatTaskMode(ATask);
      Item.SubItems[4] := FormatTaskStatus(ATask);
      Item.SubItems[5] := DateTimeToStr(ATask.LastSyncTime);
      
      if ATask.Enabled then
        Item.ImageIndex := 0
      else
        Item.ImageIndex := 1;
      
      Break;
    end;
  end;
end;

procedure TfrmSyncSettingsFull.RemoveTaskFromList(ATask: TSyncTask);
var
  I: Integer;
begin
  for I := 0 to lvTasks.Items.Count - 1 do
  begin
    if Assigned(lvTasks.Items[I].Data) and (TSyncTask(lvTasks.Items[I].Data) = ATask) then
    begin
      lvTasks.Items.Delete(I);
      Break;
    end;
  end;
end;

function TfrmSyncSettingsFull.FormatTaskStatus(ATask: TSyncTask): string;
begin
  case ATask.Status of
    ssIdle: Result := '空闲';
    ssRunning: Result := '运行中';
    ssCompleted: Result := '已完成';
    ssError: Result := '错误';
    ssPaused: Result := '暂停';
  else
    Result := '未知';
  end;
end;

function TfrmSyncSettingsFull.FormatTaskMode(ATask: TSyncTask): string;
begin
  case ATask.Mode of
    smManual: Result := '手动';
    smRealtime: Result := '实时';
  else
    Result := '未知';
  end;
end;

function TfrmSyncSettingsFull.FormatTaskCategory(ATask: TSyncTask): string;
begin
  case ATask.Category of
    scDocuments: Result := '文档';
    scCode: Result := '代码';
    scMedia: Result := '媒体';
    scBackup: Result := '备份';
  else
    Result := '自定义';
  end;
end;

procedure TfrmSyncSettingsFull.ShowTaskHistory(ATask: TSyncTask);
begin
  TfrmSyncHistory.ShowHistory(Self, ATask.TaskID, ATask.Name);
end;

end.

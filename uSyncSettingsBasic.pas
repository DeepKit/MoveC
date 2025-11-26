unit uSyncSettingsBasic;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Controls, 
  Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs, Vcl.ComCtrls, Vcl.Grids,
  Vcl.Buttons, Vcl.Menus, Vcl.Graphics, System.IOUtils, Vcl.FileCtrl, System.UITypes,
  System.Types, uSyncDatabase;

type
  // 本地任务类，包装数据库记录
  TLocalSyncTask = class
  private
    FTaskID: Integer;
    FName: string;
    FSourcePath: string;
    FTargetPath: string;
    FEnabled: Boolean;
  public
    constructor Create;
    procedure LoadFromRecord(const ARecord: uSyncDatabase.TSyncTask);
    function ToRecord: uSyncDatabase.TSyncTask;
    property TaskID: Integer read FTaskID write FTaskID;
    property Name: string read FName write FName;
    property SourcePath: string read FSourcePath write FSourcePath;
    property TargetPath: string read FTargetPath write FTargetPath;
    property Enabled: Boolean read FEnabled write FEnabled;
  end;

  TfrmSyncSettingsBasic = class(TForm)
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
    btnClose: TBitBtn;
    
    // 任务列表
    lvTasks: TListView;
    
    // 编辑区域
    pnlEdit: TPanel;
    lblEditTitle: TLabel;
    lblTaskName: TLabel;
    lblSourcePath: TLabel;
    lblTargetPath: TLabel;
    edtTaskName: TEdit;
    edtSourcePath: TEdit;
    edtTargetPath: TEdit;
    btnBrowseSource: TButton;
    btnBrowseTarget: TButton;
    btnSaveTask: TButton;
    btnCancelEdit: TButton;
    chkEnabled: TCheckBox;
    
    // 状态栏
    pnlStatus: TPanel;
    lblStatus: TLabel;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnToggleEnableClick(Sender: TObject);
    procedure btnSyncNowClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure lvTasksSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure btnBrowseSourceClick(Sender: TObject);
    procedure btnBrowseTargetClick(Sender: TObject);
    procedure btnSaveTaskClick(Sender: TObject);
    procedure btnCancelEditClick(Sender: TObject);
    
  private
    FTasks: TList;
    FEditingTask: TLocalSyncTask;
    FIsNewTask: Boolean;
    FDatabase: TSyncDatabase;
    
    procedure LoadTasks;
    procedure RefreshTaskList;
    procedure UpdateStatus(const AMessage: string);
    function GetSelectedTask: TLocalSyncTask;
    
    // 编辑相关方法
    procedure ClearEditFields;
    procedure LoadTaskToEdit(ATask: TLocalSyncTask);
    procedure SaveTaskFromEdit;
    procedure EnableEditControls(AEnabled: Boolean);
    
    // 数据库操作
    procedure SaveTaskToDatabase(ATask: TLocalSyncTask);
    procedure DeleteTaskFromDatabase(ATaskID: Integer);
    
  public
    class procedure ShowSettings(AOwner: TComponent);
  end;

var
  frmSyncSettingsBasic: TfrmSyncSettingsBasic;

implementation

{$R *.dfm}

{ TLocalSyncTask }

constructor TLocalSyncTask.Create;
begin
  inherited Create;
  FTaskID := 0;
  FName := '';
  FSourcePath := '';
  FTargetPath := '';
  FEnabled := False;
end;

procedure TLocalSyncTask.LoadFromRecord(const ARecord: uSyncDatabase.TSyncTask);
begin
  FTaskID := ARecord.TaskID;
  FName := ARecord.Name;
  FSourcePath := ARecord.SourcePath;
  FTargetPath := ARecord.TargetPath;
  FEnabled := ARecord.IsEnabled;
end;

function TLocalSyncTask.ToRecord: uSyncDatabase.TSyncTask;
begin
  Result.TaskID := FTaskID;
  Result.Name := FName;
  Result.SourcePath := FSourcePath;
  Result.TargetPath := FTargetPath;
  Result.IsEnabled := FEnabled;
  Result.SyncMode := smManual;
  Result.ConflictStrategy := csAskUser;
  Result.FilterRules := '';
  Result.PresetID := 0;
  Result.CreatedAt := Now;
  Result.UpdatedAt := Now;
end;

{ TfrmSyncSettingsBasic }

class procedure TfrmSyncSettingsBasic.ShowSettings(AOwner: TComponent);
var
  Form: TfrmSyncSettingsBasic;
begin
  Form := TfrmSyncSettingsBasic.Create(AOwner);
  try
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

procedure TfrmSyncSettingsBasic.FormCreate(Sender: TObject);
var
  DbPath: string;
begin
  FTasks := TList.Create;
  FEditingTask := nil;
  FIsNewTask := False;
  
  // 初始化数据库连接
  DbPath := TSyncDatabase.GetProjectDatabasePath;
  FDatabase := TSyncDatabase.Create(DbPath);
  
  if not FDatabase.Connect then
  begin
    UpdateStatus('数据库连接失败: ' + DbPath);
    ShowMessage('数据库连接失败，路径: ' + DbPath);
  end
  else
  begin
    UpdateStatus('数据库已连接: ' + DbPath);
  end;
  
  LoadTasks;
  ClearEditFields;
  EnableEditControls(False);
  // 不覆盖LoadTasks的状态消息
end;

procedure TfrmSyncSettingsBasic.FormDestroy(Sender: TObject);
var
  I: Integer;
begin
  // 释放所有任务对象
  for I := 0 to FTasks.Count - 1 do
  begin
    if FTasks[I] <> nil then
      TLocalSyncTask(FTasks[I]).Free;
  end;
  FTasks.Free;
  
  // 释放数据库连接
  if Assigned(FDatabase) then
  begin
    FDatabase.Disconnect;
    FDatabase.Free;
  end;
end;


procedure TfrmSyncSettingsBasic.LoadTasks;
var
  Task: TLocalSyncTask;
  TaskRecords: TArray<uSyncDatabase.TSyncTask>;
  I: Integer;
begin
  // 清空现有列表
  for I := 0 to FTasks.Count - 1 do
  begin
    if FTasks[I] <> nil then
      TLocalSyncTask(FTasks[I]).Free;
  end;
  FTasks.Clear;
  
  // 确保数据库已连接
  if not Assigned(FDatabase) then
  begin
    UpdateStatus('数据库对象未初始化');
    RefreshTaskList;
    Exit;
  end;
  
  if not FDatabase.IsConnected then
  begin
    if not FDatabase.Connect then
    begin
      UpdateStatus('数据库连接失败');
      RefreshTaskList;
      Exit;
    end;
  end;
  
  // 从数据库加载任务
  try
    TaskRecords := FDatabase.GetAllSyncTasks;
    UpdateStatus('从数据库加载了 ' + IntToStr(Length(TaskRecords)) + ' 个任务');
    for I := 0 to High(TaskRecords) do
    begin
      Task := TLocalSyncTask.Create;
      Task.LoadFromRecord(TaskRecords[I]);
      FTasks.Add(Task);
    end;
  except
    on E: Exception do
      UpdateStatus('加载任务失败: ' + E.Message);
  end;
  
  RefreshTaskList;
end;

procedure TfrmSyncSettingsBasic.RefreshTaskList;
var
  I: Integer;
  Task: TLocalSyncTask;
  Item: TListItem;
begin
  lvTasks.Clear;
  
  for I := 0 to FTasks.Count - 1 do
  begin
    Task := TLocalSyncTask(FTasks[I]);
    Item := lvTasks.Items.Add;
    Item.Caption := Task.Name;
    Item.SubItems.Add(Task.SourcePath);
    Item.SubItems.Add(Task.TargetPath);
    if Task.Enabled then
      Item.SubItems.Add('已启用')
    else
      Item.SubItems.Add('已禁用');
    Item.Data := Task;
  end;
end;

procedure TfrmSyncSettingsBasic.UpdateStatus(const AMessage: string);
begin
  lblStatus.Caption := AMessage;
end;

function TfrmSyncSettingsBasic.GetSelectedTask: TLocalSyncTask;
var
  Item: TListItem;
begin
  Result := nil;
  if lvTasks.Selected <> nil then
  begin
    Item := lvTasks.Selected;
    Result := TLocalSyncTask(Item.Data);
  end;
end;

procedure TfrmSyncSettingsBasic.SaveTaskToDatabase(ATask: TLocalSyncTask);
var
  TaskRecord: uSyncDatabase.TSyncTask;
  NewID: Integer;
  VerifyTask: uSyncDatabase.TSyncTask;
begin
  if not Assigned(FDatabase) then
  begin
    UpdateStatus('数据库对象未初始化');
    ShowMessage('无法保存: 数据库对象未初始化');
    Exit;
  end;
  
  if not FDatabase.IsConnected then
  begin
    // 尝试重新连接
    UpdateStatus('尝试重新连接数据库...');
    if not FDatabase.Connect then
    begin
      UpdateStatus('数据库连接失败，无法保存');
      ShowMessage('无法保存: 数据库连接失败');
      Exit;
    end;
  end;
  
  try
    TaskRecord := ATask.ToRecord;
    
    if ATask.TaskID = 0 then
    begin
      // 新任务，创建
      UpdateStatus('正在创建新任务: ' + ATask.Name);
      NewID := FDatabase.CreateSyncTask(TaskRecord);
      if NewID > 0 then
      begin
        ATask.TaskID := NewID;
        
        // 验证是否真的写入了数据库
        VerifyTask := FDatabase.GetSyncTask(NewID);
        if VerifyTask.TaskID = NewID then
          UpdateStatus('任务已保存并验证 (ID: ' + IntToStr(NewID) + ')')
        else
        begin
          UpdateStatus('警告: 任务已创建但验证失败');
          ShowMessage('警告: 任务可能未正确保存到数据库');
        end;
      end
      else
      begin
        UpdateStatus('创建任务失败，返回ID: ' + IntToStr(NewID));
        ShowMessage('创建任务失败');
      end;
    end
    else
    begin
      // 现有任务，更新
      UpdateStatus('正在更新任务 (ID: ' + IntToStr(ATask.TaskID) + ')');
      if FDatabase.UpdateSyncTask(TaskRecord) then
      begin
        // 验证更新是否成功
        VerifyTask := FDatabase.GetSyncTask(ATask.TaskID);
        if VerifyTask.Name = ATask.Name then
          UpdateStatus('任务已更新并验证 (ID: ' + IntToStr(ATask.TaskID) + ')')
        else
          UpdateStatus('警告: 任务已更新但验证不匹配');
      end
      else
      begin
        UpdateStatus('更新任务失败');
        ShowMessage('更新任务失败 (ID: ' + IntToStr(ATask.TaskID) + ')');
      end;
    end;
  except
    on E: Exception do
    begin
      UpdateStatus('数据库操作失败: ' + E.Message);
      ShowMessage('数据库操作失败: ' + E.Message);
    end;
  end;
end;

procedure TfrmSyncSettingsBasic.DeleteTaskFromDatabase(ATaskID: Integer);
begin
  if not Assigned(FDatabase) or not FDatabase.IsConnected then
  begin
    UpdateStatus('数据库未连接，无法删除');
    Exit;
  end;
  
  try
    if FDatabase.DeleteSyncTask(ATaskID) then
      UpdateStatus('任务已从数据库删除')
    else
      UpdateStatus('删除任务失败');
  except
    on E: Exception do
      UpdateStatus('数据库操作失败: ' + E.Message);
  end;
end;

// 工具栏按钮事件
procedure TfrmSyncSettingsBasic.btnNewClick(Sender: TObject);
begin
  // 清空编辑区域并启用，准备创建新任务
  ClearEditFields;
  FIsNewTask := True;
  FEditingTask := nil;
  
  // 设置默认值
  edtTaskName.Text := '新同步任务';
  edtSourcePath.Text := 'C:\Users\' + GetEnvironmentVariable('USERNAME') + '\Documents';
  edtTargetPath.Text := 'D:\Backup\Documents';
  chkEnabled.Checked := False;
  
  EnableEditControls(True);
  edtTaskName.SetFocus;
  UpdateStatus('正在创建新任务');
  
  // 取消列表选择
  lvTasks.Selected := nil;
end;

procedure TfrmSyncSettingsBasic.btnEditClick(Sender: TObject);
var
  Task: TLocalSyncTask;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then 
  begin
    ShowMessage('请先选择要编辑的任务');
    Exit;
  end;
  
  // 加载选中任务到编辑区域
  LoadTaskToEdit(Task);
  FIsNewTask := False;
  EnableEditControls(True);
  edtTaskName.SetFocus;
  UpdateStatus('正在编辑任务: ' + Task.Name);
end;

procedure TfrmSyncSettingsBasic.btnDeleteClick(Sender: TObject);
var
  Task: TLocalSyncTask;
  TaskName: string;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then Exit;
  
  TaskName := Task.Name;
  if MessageDlg('确定要删除任务 "' + TaskName + '" 吗？', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    // 先从数据库删除
    if Task.TaskID > 0 then
      DeleteTaskFromDatabase(Task.TaskID);
    
    // 再从内存列表删除
    FTasks.Remove(Task);
    Task.Free;
    RefreshTaskList;
    UpdateStatus('已删除任务: ' + TaskName);
  end;
end;

procedure TfrmSyncSettingsBasic.btnToggleEnableClick(Sender: TObject);
var
  Task: TLocalSyncTask;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then Exit;
  
  Task.Enabled := not Task.Enabled;
  
  // 保存到数据库
  SaveTaskToDatabase(Task);
  
  RefreshTaskList;
  if Task.Enabled then
    UpdateStatus('任务 "' + Task.Name + '" 已启用')
  else
    UpdateStatus('任务 "' + Task.Name + '" 已禁用');
end;

procedure TfrmSyncSettingsBasic.btnSyncNowClick(Sender: TObject);
var
  Task: TLocalSyncTask;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then Exit;
  
  if not Task.Enabled then
  begin
    ShowMessage('请先启用该任务');
    Exit;
  end;
  
  UpdateStatus('正在执行任务: ' + Task.Name);
  // 这里可以添加实际的同步逻辑
  ShowMessage('同步功能演示 - 任务 "' + Task.Name + '" 将会从 ' + Task.SourcePath + ' 同步到 ' + Task.TargetPath);
  UpdateStatus('任务执行完成: ' + Task.Name);
end;

procedure TfrmSyncSettingsBasic.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmSyncSettingsBasic.lvTasksSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if Selected then
  begin
    UpdateStatus('已选择任务: ' + Item.Caption);
    LoadTaskToEdit(TLocalSyncTask(Item.Data));
    EnableEditControls(True);
  end
  else
  begin
    UpdateStatus('就绪');
    ClearEditFields;
    EnableEditControls(False);
  end;
end;

// 编辑相关方法实现
procedure TfrmSyncSettingsBasic.ClearEditFields;
begin
  edtTaskName.Text := '';
  edtSourcePath.Text := '';
  edtTargetPath.Text := '';
  chkEnabled.Checked := False;
  FEditingTask := nil;
  FIsNewTask := False;
end;

procedure TfrmSyncSettingsBasic.LoadTaskToEdit(ATask: TLocalSyncTask);
begin
  if Assigned(ATask) then
  begin
    FEditingTask := ATask;
    FIsNewTask := False;
    edtTaskName.Text := ATask.Name;
    edtSourcePath.Text := ATask.SourcePath;
    edtTargetPath.Text := ATask.TargetPath;
    chkEnabled.Checked := ATask.Enabled;
  end;
end;

procedure TfrmSyncSettingsBasic.SaveTaskFromEdit;
begin
  if FIsNewTask then
  begin
    // 创建新任务
    FEditingTask := TLocalSyncTask.Create;
    FEditingTask.TaskID := 0; // 新任务，ID为0
    FEditingTask.Name := edtTaskName.Text;
    FEditingTask.SourcePath := edtSourcePath.Text;
    FEditingTask.TargetPath := edtTargetPath.Text;
    FEditingTask.Enabled := chkEnabled.Checked;
    
    // 保存到数据库
    SaveTaskToDatabase(FEditingTask);
    
    FTasks.Add(FEditingTask);
    UpdateStatus('已创建新任务: ' + FEditingTask.Name);
  end
  else if Assigned(FEditingTask) then
  begin
    // 更新现有任务
    FEditingTask.Name := edtTaskName.Text;
    FEditingTask.SourcePath := edtSourcePath.Text;
    FEditingTask.TargetPath := edtTargetPath.Text;
    FEditingTask.Enabled := chkEnabled.Checked;
    
    // 保存到数据库
    SaveTaskToDatabase(FEditingTask);
    
    UpdateStatus('已更新任务: ' + FEditingTask.Name);
  end;
  
  RefreshTaskList;
end;

procedure TfrmSyncSettingsBasic.EnableEditControls(AEnabled: Boolean);
begin
  edtTaskName.Enabled := AEnabled;
  edtSourcePath.Enabled := AEnabled;
  edtTargetPath.Enabled := AEnabled;
  btnBrowseSource.Enabled := AEnabled;
  btnBrowseTarget.Enabled := AEnabled;
  btnSaveTask.Enabled := AEnabled;
  btnCancelEdit.Enabled := AEnabled;
  chkEnabled.Enabled := AEnabled;
end;

// 事件处理程序
procedure TfrmSyncSettingsBasic.btnBrowseSourceClick(Sender: TObject);
var
  FolderDialog: TFileOpenDialog;
begin
  FolderDialog := TFileOpenDialog.Create(nil);
  try
    FolderDialog.Title := '选择源目录';
    FolderDialog.Options := [fdoPickFolders, fdoPathMustExist];
    
    if FolderDialog.Execute then
    begin
      edtSourcePath.Text := FolderDialog.FileName;
    end;
  finally
    FolderDialog.Free;
  end;
end;

procedure TfrmSyncSettingsBasic.btnBrowseTargetClick(Sender: TObject);
var
  FolderDialog: TFileOpenDialog;
begin
  FolderDialog := TFileOpenDialog.Create(nil);
  try
    FolderDialog.Title := '选择目标目录';
    FolderDialog.Options := [fdoPickFolders, fdoPathMustExist];
    
    if FolderDialog.Execute then
    begin
      edtTargetPath.Text := FolderDialog.FileName;
    end;
  finally
    FolderDialog.Free;
  end;
end;

procedure TfrmSyncSettingsBasic.btnSaveTaskClick(Sender: TObject);
begin
  if Trim(edtTaskName.Text) = '' then
  begin
    ShowMessage('请输入任务名称');
    edtTaskName.SetFocus;
    Exit;
  end;
  
  if Trim(edtSourcePath.Text) = '' then
  begin
    ShowMessage('请选择源目录');
    edtSourcePath.SetFocus;
    Exit;
  end;
  
  if Trim(edtTargetPath.Text) = '' then
  begin
    ShowMessage('请选择目标目录');
    edtTargetPath.SetFocus;
    Exit;
  end;
  
  try
    SaveTaskFromEdit;
    ClearEditFields;
    EnableEditControls(False);
    lvTasks.Selected := nil;
  except
    on E: Exception do
    begin
      UpdateStatus('保存任务失败: ' + E.Message);
      ShowMessage('保存任务失败: ' + E.Message);
    end;
  end;
end;

procedure TfrmSyncSettingsBasic.btnCancelEditClick(Sender: TObject);
begin
  ClearEditFields;
  EnableEditControls(False);
  lvTasks.Selected := nil;
  UpdateStatus('已取消编辑');
end;

end.

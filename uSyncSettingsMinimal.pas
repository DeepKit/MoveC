unit uSyncSettingsMinimal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Controls, 
  Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs, Vcl.ComCtrls, Vcl.Grids,
  Vcl.Buttons, Vcl.Menus, Vcl.Graphics, System.IOUtils, System.Generics.Collections,
  System.Math, uSyncEngine, uSyncDatabase, uSyncExecutorSimple;

type
  TfrmSyncSettingsMinimal = class(TForm)
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
    pmTasks: TPopupMenu;
    
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
    
  private
    FEngine: TSyncEngine;
    FExecutor: TSyncExecutor;
    FDatabase: TSyncDatabase;
    FTasks: TObjectList<TSyncTask>;
    
    procedure InitializeInterface;
    procedure LoadTasks;
    procedure RefreshTaskList;
    procedure UpdateStatus(const AMessage: string);
    function GetSelectedTask: TSyncTask;
    
  public
    class procedure ShowSettings(AOwner: TComponent);
  end;

var
  frmSyncSettingsMinimal: TfrmSyncSettingsMinimal;

implementation

{$R *.dfm}

class procedure TfrmSyncSettingsMinimal.ShowSettings(AOwner: TComponent);
var
  Form: TfrmSyncSettingsMinimal;
begin
  Form := TfrmSyncSettingsMinimal.Create(AOwner);
  try
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

procedure TfrmSyncSettingsMinimal.FormCreate(Sender: TObject);
begin
  FEngine := TSyncEngine.Create(Self);
  FExecutor := TSyncExecutor.Create;
  FDatabase := TSyncDatabase.Create;
  FTasks := TObjectList<TSyncTask>.Create(True);
  
  InitializeInterface;
  LoadTasks;
  UpdateStatus('同步盘设置已初始化');
end;

procedure TfrmSyncSettingsMinimal.FormDestroy(Sender: TObject);
begin
  FTasks.Free;
  FDatabase.Free;
  FExecutor.Free;
  FEngine.Free;
end;

procedure TfrmSyncSettingsMinimal.InitializeInterface;
begin
  // 设置窗体属性
  Caption := '同步盘设置';
  Width := 800;
  Height := 600;
  
  // 创建主面板
  pnlMain := TPanel.Create(Self);
  pnlMain.Parent := Self;
  pnlMain.Align := alClient;
  pnlMain.BevelOuter := bvNone;
  
  // 创建标题面板
  pnlHeader := TPanel.Create(Self);
  pnlHeader.Parent := pnlMain;
  pnlHeader.Align := alTop;
  pnlHeader.Height := 60;
  pnlHeader.BevelOuter := bvNone;
  pnlHeader.Color := clWindow;
  
  lblTitle := TLabel.Create(Self);
  lblTitle.Parent := pnlHeader;
  lblTitle.Left := 16;
  lblTitle.Top := 12;
  lblTitle.Caption := '同步盘设置';
  lblTitle.Font.Style := [fsBold];
  lblTitle.Font.Size := 16;
  
  lblDescription := TLabel.Create(Self);
  lblDescription.Parent := pnlHeader;
  lblDescription.Left := 16;
  lblDescription.Top := 37;
  lblDescription.Caption := '管理文件同步任务，支持手动和实时同步模式';
  lblDescription.Font.Color := clGrayText;
  
  // 创建工具栏
  pnlToolbar := TPanel.Create(Self);
  pnlToolbar.Parent := pnlMain;
  pnlToolbar.Align := alTop;
  pnlToolbar.Height := 40;
  pnlToolbar.BevelOuter := bvNone;
  pnlToolbar.Top := 60;
  
  btnNew := TBitBtn.Create(Self);
  btnNew.Parent := pnlToolbar;
  btnNew.Left := 16;
  btnNew.Top := 8;
  btnNew.Caption := '新建';
  btnNew.OnClick := btnNewClick;
  
  btnEdit := TBitBtn.Create(Self);
  btnEdit.Parent := pnlToolbar;
  btnEdit.Left := 97;
  btnEdit.Top := 8;
  btnEdit.Caption := '编辑';
  btnEdit.OnClick := btnEditClick;
  
  btnDelete := TBitBtn.Create(Self);
  btnDelete.Parent := pnlToolbar;
  btnDelete.Left := 178;
  btnDelete.Top := 8;
  btnDelete.Caption := '删除';
  btnDelete.OnClick := btnDeleteClick;
  
  btnToggleEnable := TBitBtn.Create(Self);
  btnToggleEnable.Parent := pnlToolbar;
  btnToggleEnable.Left := 259;
  btnToggleEnable.Top := 8;
  btnToggleEnable.Caption := '启用/禁用';
  btnToggleEnable.OnClick := btnToggleEnableClick;
  
  btnSyncNow := TBitBtn.Create(Self);
  btnSyncNow.Parent := pnlToolbar;
  btnSyncNow.Left := 340;
  btnSyncNow.Top := 8;
  btnSyncNow.Caption := '立即同步';
  btnSyncNow.OnClick := btnSyncNowClick;
  
  btnClose := TBitBtn.Create(Self);
  btnClose.Parent := pnlToolbar;
  btnClose.Left := 709;
  btnClose.Top := 8;
  btnClose.Caption := '关闭';
  btnClose.OnClick := btnCloseClick;
  
  // 创建任务列表
  lvTasks := TListView.Create(Self);
  lvTasks.Parent := pnlMain;
  lvTasks.Align := alClient;
  lvTasks.Top := 100;
  lvTasks.ViewStyle := vsReport;
  lvTasks.ReadOnly := True;
  lvTasks.OnSelectItem := lvTasksSelectItem;
  
  // 添加列
  with lvTasks.Columns.Add do
  begin
    Width := 200;
    Caption := '任务名称';
  end;
  with lvTasks.Columns.Add do
  begin
    Width := 200;
    Caption := '源路径';
  end;
  with lvTasks.Columns.Add do
  begin
    Width := 200;
    Caption := '目标路径';
  end;
  with lvTasks.Columns.Add do
  begin
    Width := 80;
    Caption := '状态';
  end;
  with lvTasks.Columns.Add do
  begin
    Width := 80;
    Caption := '模式';
  end;
  
  // 创建状态栏
  pnlStatus := TPanel.Create(Self);
  pnlStatus.Parent := pnlMain;
  pnlStatus.Align := alBottom;
  pnlStatus.Height := 30;
  pnlStatus.BevelOuter := bvLowered;
  
  lblStatus := TLabel.Create(Self);
  lblStatus.Parent := pnlStatus;
  lblStatus.Left := 16;
  lblStatus.Top := 8;
  lblStatus.Caption := '就绪';
end;

procedure TfrmSyncSettingsMinimal.LoadTasks;
var
  Task: TSyncTask;
begin
  FTasks.Clear;
  
  // 添加一些示例任务
  Task := TSyncTask.Create;
  Task.Name := '文档备份';
  Task.SourcePath := 'C:\Users\' + GetEnvironmentVariable('USERNAME') + '\Documents';
  Task.TargetPath := 'D:\Backup\Documents';
  Task.Mode := uSyncDatabase.smManual;
  Task.Category := uSyncDatabase.scDocuments;
  Task.Enabled := False;
  Task.ConflictStrategy := uSyncDatabase.csAskUser;
  FTasks.Add(Task);
  
  Task := TSyncTask.Create;
  Task.Name := '图片同步';
  Task.SourcePath := 'C:\Users\' + GetEnvironmentVariable('USERNAME') + '\Pictures';
  Task.TargetPath := 'D:\Backup\Pictures';
  Task.Mode := uSyncDatabase.smManual;
  Task.Category := uSyncDatabase.scMedia;
  Task.Enabled := False;
  Task.ConflictStrategy := uSyncDatabase.csAskUser;
  FTasks.Add(Task);
  
  RefreshTaskList;
end;

procedure TfrmSyncSettingsMinimal.RefreshTaskList;
var
  Task: TSyncTask;
  Item: TListItem;
begin
  lvTasks.Clear;
  
  for Task in FTasks do
  begin
    Item := lvTasks.Items.Add;
    Item.Caption := Task.Name;
    Item.SubItems.Add(Task.SourcePath);
    Item.SubItems.Add(Task.TargetPath);
    Item.SubItems.Add(IfThen(Task.Enabled, '已启用', '已禁用'));
    Item.SubItems.Add(IfThen(Task.Mode = uSyncDatabase.smManual, '手动', '实时'));
    Item.Data := Pointer(Task);
  end;
end;

procedure TfrmSyncSettingsMinimal.UpdateStatus(const AMessage: string);
begin
  lblStatus.Caption := AMessage;
end;

function TfrmSyncSettingsMinimal.GetSelectedTask: TSyncTask;
var
  Item: TListItem;
begin
  Result := nil;
  if lvTasks.Selected <> nil then
  begin
    Item := lvTasks.Selected;
    Result := TSyncTask(Item.Data);
  end;
end;

// 工具栏按钮事件
procedure TfrmSyncSettingsMinimal.btnNewClick(Sender: TObject);
var
  NewTask: TSyncTask;
  TaskName: string;
  SourcePath, TargetPath: string;
begin
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
    NewTask.Mode := uSyncDatabase.smManual;
    NewTask.Category := uSyncDatabase.scDocuments;
    NewTask.Enabled := False;
    NewTask.ConflictStrategy := uSyncDatabase.csAskUser;
    
    FTasks.Add(NewTask);
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

procedure TfrmSyncSettingsMinimal.btnEditClick(Sender: TObject);
var
  Task: TSyncTask;
  TaskName: string;
  SourcePath, TargetPath: string;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then Exit;
  
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

procedure TfrmSyncSettingsMinimal.btnDeleteClick(Sender: TObject);
var
  Task: TSyncTask;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then Exit;
  
  if MessageDlg('确定要删除任务 "' + Task.Name + '" 吗？', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FTasks.Remove(Task);
    Task.Free;
    RefreshTaskList;
    UpdateStatus('已删除任务: ' + Task.Name);
  end;
end;

procedure TfrmSyncSettingsMinimal.btnToggleEnableClick(Sender: TObject);
var
  Task: TSyncTask;
begin
  Task := GetSelectedTask;
  if not Assigned(Task) then Exit;
  
  Task.Enabled := not Task.Enabled;
  RefreshTaskList;
  UpdateStatus('任务 "' + Task.Name + '" 已' + IfThen(Task.Enabled, '启用', '禁用'));
end;

procedure TfrmSyncSettingsMinimal.btnSyncNowClick(Sender: TObject);
var
  Task: TSyncTask;
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

procedure TfrmSyncSettingsMinimal.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmSyncSettingsMinimal.lvTasksSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if Selected then
    UpdateStatus('已选择任务: ' + Item.Caption)
  else
    UpdateStatus('就绪');
end;

end.

unit MainSyncForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Menus, Vcl.ToolWin, Vcl.Grids, Vcl.ValEdit, System.Generics.Collections,
  uSyncEngine, uSyncDatabase, uRealtimeSyncManager, uNetworkPathManager, uConflictResolver,
  uSyncExecutorSimple, uTrayIcon;

type
  TMainSyncForm = class(TForm)
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    NewTask1: TMenuItem;
    EditTask1: TMenuItem;
    DeleteTask1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    View1: TMenuItem;
    Refresh1: TMenuItem;
    Statistics1: TMenuItem;
    Logs1: TMenuItem;
    Help1: TMenuItem;
    About1: TMenuItem;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    StatusBar1: TStatusBar;
    Panel1: TPanel;
    Splitter1: TSplitter;
    ListView1: TListView;
    Panel2: TPanel;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    GroupBox2: TGroupBox;
    Memo1: TMemo;
    ProgressBar1: TProgressBar;
    Label5: TLabel;
    Timer1: TTimer;
    PopupMenu1: TPopupMenu;
    StartSync1: TMenuItem;
    StopSync1: TMenuItem;
    EditTask2: TMenuItem;
    DeleteTask2: TMenuItem;
    Properties1: TMenuItem;
    N2: TMenuItem;
    Refresh2: TMenuItem;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure NewTask1Click(Sender: TObject);
    procedure EditTask1Click(Sender: TObject);
    procedure DeleteTask1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure Refresh1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure ListView1DblClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure StartSync1Click(Sender: TObject);
    procedure StopSync1Click(Sender: TObject);
    procedure Properties1Click(Sender: TObject);
    procedure Refresh2Click(Sender: TObject);
    
  private
    FSyncEngine: TSyncEngine;
    FDatabase: TSyncDatabase;
    FRealtimeManager: TRealtimeSyncManager;
    FNetworkManager: TNetworkPathManager;
    FConflictResolver: TConflictResolver;
    FSelectedTask: TSyncTask;
    FTrayManager: TTrayManager;
    FMinimizeToTray: Boolean;
    FReallyClose: Boolean;
    
    procedure InitializeComponents;
    procedure LoadTasksToListView;
  public
    procedure RealClose;
    procedure UpdateTaskStatus(const ATask: TSyncTask);
    procedure UpdateStatistics;
    procedure RefreshTaskList;
    procedure SelectTask(const ATask: TSyncTask);
    procedure ShowTaskProperties(const ATask: TSyncTask);
    procedure ShowStatistics;
    procedure ShowAboutDialog;
    procedure HandleSyncProgress(const AProgress: TSyncProgressInfo);
    procedure HandleSyncEvent(const ATask: TSyncTask; const AEventInfo: string);
    procedure HandleSyncError(const ATask: TSyncTask; const AError: string);
    procedure HandleConflictDetected(const AConflict: TConflictRecord);
    procedure HandleNetworkStatusChange(const APath: string; const AStatus: TNetworkConnectionStatus);
    
  public
    { Public declarations }
  end;

var
  MainSyncForm: TMainSyncForm;

implementation

{$R *.dfm}

uses
  TaskEditForm, StatisticsForm, AboutForm, uSyncPresets;

{ TMainSyncForm }

procedure TMainSyncForm.FormCreate(Sender: TObject);
var
  DbPath: string;
begin
  InitializeComponents;
  
  // 初始化核心组件
  DbPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'MoveC.db');
  FDatabase := TSyncDatabase.Create(DbPath);
  
  // 连接数据库
  if not FDatabase.Connect then
  begin
    ShowMessage('数据库连接失败，程序可能无法正常工作');
    Memo1.Lines.Add('[错误] 数据库连接失败: ' + DbPath);
  end
  else
  begin
    Memo1.Lines.Add('[成功] 数据库已连接: ' + DbPath);
  end;
  
  FSyncEngine := TSyncEngine.CreateWithDatabase(Self, FDatabase);
  FRealtimeManager := TRealtimeSyncManager.Create(FDatabase);
  FNetworkManager := TNetworkPathManager.Create;
  FConflictResolver := TConflictResolver.Create(FDatabase);
  
  // 初始化托盘图标
  FTrayManager := TTrayManager.Create(Self);
  FTrayManager.Initialize(Self);
  FTrayManager.OnExit := RealClose; // 设置托盘退出事件
  FMinimizeToTray := True; // 默认启用最小化到托盘
  FReallyClose := False; // 初始化退出标志
  
  // 设置事件处理
  FRealtimeManager.OnSyncEvent := HandleSyncEvent;
  FRealtimeManager.OnSyncError := HandleSyncError;
  FNetworkManager.OnConnectionChange := HandleNetworkStatusChange;
  FConflictResolver.OnConflictDetected := HandleConflictDetected;
  
  // 加载任务（仅从数据库，不使用mock数据）
  FSyncEngine.LoadTasksFromDatabase;
  Memo1.Lines.Add(Format('[信息] 已从数据库加载 %d 个同步任务', [FSyncEngine.TaskCount]));
  LoadTasksToListView;
  
  // 启动定时器
  Timer1.Enabled := True;
  
  Caption := '文件同步工具 v1.0';
  StatusBar1.Panels[0].Text := '就绪';
end;

procedure TMainSyncForm.FormDestroy(Sender: TObject);
begin
  // 停止所有实时同步
  FRealtimeManager.StopAllRealtimeSync;
  
  // 释放组件
  FreeAndNil(FTrayManager);
  FreeAndNil(FConflictResolver);
  FreeAndNil(FNetworkManager);
  FreeAndNil(FRealtimeManager);
  FreeAndNil(FSyncEngine);
  FreeAndNil(FDatabase);
end;

procedure TMainSyncForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // 如果是真正退出，则允许关闭
  if FReallyClose then
  begin
    CanClose := True;
    Exit;
  end;
  
  // 如果启用了最小化到托盘，则关闭时最小化而不是退出
  if FMinimizeToTray then
  begin
    CanClose := False;
    Hide;
    if Assigned(FTrayManager) then
      FTrayManager.ShowBalloon('文件同步工具', '程序已最小化到系统托盘，双击托盘图标或右键菜单可显示主窗口');
  end
  else
  begin
    CanClose := True;
  end;
end;

procedure TMainSyncForm.InitializeComponents;
begin
  // 初始化ListView列
  ListView1.ViewStyle := vsReport;
  ListView1.Columns.Add.Caption := '任务名称';
  ListView1.Columns[0].Width := 150;
  ListView1.Columns.Add.Caption := '源路径';
  ListView1.Columns[1].Width := 200;
  ListView1.Columns.Add.Caption := '目标路径';
  ListView1.Columns[2].Width := 200;
  ListView1.Columns.Add.Caption := '同步模式';
  ListView1.Columns[3].Width := 80;
  ListView1.Columns.Add.Caption = '状态';
  ListView1.Columns[4].Width := 80;
  ListView1.Columns.Add.Caption := '最后同步';
  ListView1.Columns[5].Width := 120;
  
  // 初始化ComboBox
  ComboBox1.Items.Add('手动同步');
  ComboBox1.Items.Add('实时同步');
  ComboBox1.ItemIndex := 0;
  
  ComboBox2.Items.Add('代码同步');
  ComboBox2.Items.Add('文档备份');
  ComboBox2.Items.Add('媒体文件');
  ComboBox2.Items.Add('项目文件');
  ComboBox2.Items.Add('全量同步');
  ComboBox2.ItemIndex := 0;
  
  // 初始化状态栏
  StatusBar1.Panels.Add;
  StatusBar1.Panels.Add;
  StatusBar1.Panels.Add;
end;

procedure TMainSyncForm.LoadTasksToListView;
var
  Task: TSyncTask;
  ListItem: TListItem;
begin
  ListView1.Items.BeginUpdate;
  try
    ListView1.Items.Clear;
    
    for Task in FSyncEngine.Tasks do
    begin
      ListItem := ListView1.Items.Add;
      ListItem.Caption := Task.Name;
      ListItem.SubItems.Add(Task.SourcePath);
      ListItem.SubItems.Add(Task.TargetPath);
      ListItem.SubItems.Add(GetEnumName(TypeInfo(TSyncMode), Ord(Task.Mode)));
      ListItem.SubItems.Add(GetEnumName(TypeInfo(TSyncStatus), Ord(Task.Status)));
      ListItem.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn', Task.LastSyncTime));
      ListItem.Data := Pointer(Task);
    end;
  finally
    ListView1.Items.EndUpdate;
  end;
end;

procedure TMainSyncForm.UpdateTaskStatus(const ATask: TSyncTask);
var
  I: Integer;
  ListItem: TListItem;
begin
  for I := 0 to ListView1.Items.Count - 1 do
  begin
    ListItem := ListView1.Items[I];
    if ListItem.Data = Pointer(ATask) then
    begin
      ListItem.SubItems[3] := GetEnumName(TypeInfo(TSyncStatus), Ord(ATask.Status));
      ListItem.SubItems[4] := FormatDateTime('yyyy-mm-dd hh:nn', ATask.LastSyncTime);
      Break;
    end;
  end;
end;

procedure TMainSyncForm.UpdateStatistics;
var
  Stats: TDictionary<string, Integer>;
  TotalTasks, ActiveTasks, CompletedTasks: Integer;
begin
  TotalTasks := FSyncEngine.Tasks.Count;
  ActiveTasks := 0;
  CompletedTasks := 0;
  
  for var Task in FSyncEngine.Tasks do
  begin
    if Task.Status = ssRunning then
      Inc(ActiveTasks)
    else if Task.Status = ssCompleted then
      Inc(CompletedTasks);
  end;
  
  StatusBar1.Panels[1].Text := Format('总任务: %d', [TotalTasks]);
  StatusBar1.Panels[2].Text := Format('运行中: %d', [ActiveTasks]);
  
  // 更新统计信息到Memo
  Memo1.Lines.Clear;
  Memo1.Lines.Add('=== 同步统计 ===');
  Memo1.Lines.Add(Format('总任务数: %d', [TotalTasks]));
  Memo1.Lines.Add(Format('运行中: %d', [ActiveTasks]));
  Memo1.Lines.Add(Format('已完成: %d', [CompletedTasks]));
  Memo1.Lines.Add(Format('实时同步: %d', [FRealtimeManager.GetActiveTaskCount]));
  
  // 网络状态
  Memo1.Lines.Add('');
  Memo1.Lines.Add('=== 网络状态 ===');
  Memo1.Lines.Add('网络连接: ' + FNetworkManager.GetNetworkStatus);
end;

procedure TMainSyncForm.RefreshTaskList;
begin
  LoadTasksToListView;
  UpdateStatistics;
end;

procedure TMainSyncForm.SelectTask(const ATask: TSyncTask);
begin
  FSelectedTask := ATask;
  
  if Assigned(ATask) then
  begin
    Edit1.Text := ATask.Name;
    Edit2.Text := ATask.SourcePath;
    ComboBox1.ItemIndex := Ord(ATask.Mode);
    // TODO: 设置其他属性
  end
  else
  begin
    Edit1.Text := '';
    Edit2.Text := '';
    ComboBox1.ItemIndex := 0;
  end;
end;

procedure TMainSyncForm.ShowTaskProperties(const ATask: TSyncTask);
begin
  if not Assigned(ATask) then Exit;
  
  // TODO: 实现任务属性对话框
  ShowMessage(Format('任务属性: %s'#13#10'源路径: %s'#13#10'目标路径: %s'#13#10'状态: %s',
    [ATask.Name, ATask.SourcePath, ATask.TargetPath, 
     GetEnumName(TypeInfo(TSyncStatus), Ord(ATask.Status))]));
end;

procedure TMainSyncForm.ShowStatistics;
begin
  // TODO: 实现统计窗体
  ShowMessage('统计功能待实现');
end;

procedure TMainSyncForm.ShowAboutDialog;
begin
  // TODO: 实现关于对话框
  ShowMessage('文件同步工具 v1.0'#13#10#13#10'功能特性:'#13#10'• 手动/实时同步'#13#10'• 网络路径支持'#13#10'• 冲突检测与解决'#13#10'• 进度监控');
end;

procedure TMainSyncForm.HandleSyncProgress(const AProgress: TSyncProgressInfo);
begin
  ProgressBar1.Position := Trunc(AProgress.PercentComplete);
  Label5.Caption := Format('进度: %d%% (%d/%d)', 
    [Trunc(AProgress.PercentComplete), AProgress.ProcessedFiles, AProgress.TotalFiles]);
end;

procedure TMainSyncForm.HandleSyncEvent(const ATask: TSyncTask; const AEventInfo: string);
begin
  Memo1.Lines.Add(Format('[%s] %s: %s', 
    [FormatDateTime('hh:nn:ss', Now), ATask.Name, AEventInfo]));
end;

procedure TMainSyncForm.HandleSyncError(const ATask: TSyncTask; const AError: string);
begin
  Memo1.Lines.Add(Format('[%s] 错误 - %s: %s', 
    [FormatDateTime('hh:nn:ss', Now), ATask.Name, AError]));
  StatusBar1.Panels[0].Text := '错误: ' + AError;
end;

procedure TMainSyncForm.HandleConflictDetected(const AConflict: TConflictRecord);
begin
  Memo1.Lines.Add(Format('[%s] 冲突检测 - %s: %s', 
    [FormatDateTime('hh:nn:ss', Now), AConflict.FilePath, AConflict.Description]));
    
  // TODO: 显示冲突解决对话框
  if MessageDlg(Format('检测到文件冲突:'#13#10'%s'#13#10#13#10'%s', 
    [AConflict.FilePath, AConflict.Description]), 
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    // 用户选择解决冲突
    FConflictResolver.ResolveConflict(AConflict.ID, crsAskUser);
  end;
end;

procedure TMainSyncForm.HandleNetworkStatusChange(const APath: string; const AStatus: TNetworkConnectionStatus);
var
  StatusText: string;
begin
  case AStatus of
    ncsConnected: StatusText := '已连接';
    ncsDisconnected: StatusText := '已断开';
    ncsConnecting: StatusText := '连接中';
    ncsError: StatusText := '连接错误';
    else StatusText := '未知状态';
  end;
  
  Memo1.Lines.Add(Format('[%s] 网络状态变化 - %s: %s', 
    [FormatDateTime('hh:nn:ss', Now), APath, StatusText]));
end;

// 事件处理程序

procedure TMainSyncForm.NewTask1Click(Sender: TObject);
var
  NewTask: TSyncTask;
  EditForm: TTaskEditForm;
begin
  EditForm := TTaskEditForm.Create(Self, FDatabase);
  try
    if EditForm.ShowModal = mrOk then
    begin
      try
        Memo1.Lines.Add(Format('[%s] 正在创建任务...', [FormatDateTime('hh:nn:ss', Now)]));
        NewTask := EditForm.CreateTask;
        if Assigned(NewTask) then
        begin
          Memo1.Lines.Add(Format('[%s] 任务对象创建成功: %s', 
            [FormatDateTime('hh:nn:ss', Now), NewTask.Name]));
          
          FSyncEngine.AddTask(NewTask);
          Memo1.Lines.Add(Format('[%s] 任务已添加到引擎', [FormatDateTime('hh:nn:ss', Now)]));
          
          NewTask.Save;
          Memo1.Lines.Add(Format('[%s] 任务保存完成 (ID: %d)', 
            [FormatDateTime('hh:nn:ss', Now), NewTask.TaskID]));
            
          if NewTask.TaskID > 0 then
          begin
            Memo1.Lines.Add(Format('[%s] ✅ 新建任务成功: %s (ID: %d)', 
              [FormatDateTime('hh:nn:ss', Now), NewTask.Name, NewTask.TaskID]));
            RefreshTaskList;
          end
          else
          begin
            Memo1.Lines.Add(Format('[%s] ❌ 任务保存失败: TaskID = 0', 
              [FormatDateTime('hh:nn:ss', Now)]));
            ShowMessage('任务保存失败，请检查数据库连接');
          end;
        end
        else
        begin
          Memo1.Lines.Add(Format('[%s] ❌ 创建任务对象失败', [FormatDateTime('hh:nn:ss', Now)]));
          ShowMessage('创建任务失败');
        end;
      except
        on E: Exception do
        begin
          Memo1.Lines.Add(Format('[%s] ❌ 异常: %s', 
            [FormatDateTime('hh:nn:ss', Now), E.Message]));
          ShowMessage('创建任务时发生错误: ' + E.Message);
        end;
      end;
    end;
  finally
    EditForm.Free;
  end;
end;

procedure TMainSyncForm.EditTask1Click(Sender: TObject);
var
  EditForm: TTaskEditForm;
begin
  if not Assigned(FSelectedTask) then
  begin
    ShowMessage('请先选择一个任务');
    Exit;
  end;
  
  EditForm := TTaskEditForm.Create(Self, FDatabase);
  try
    EditForm.LoadTask(FSelectedTask);
    if EditForm.ShowModal = mrOk then
    begin
      FSelectedTask.Save;
      RefreshTaskList;
    end;
  finally
    EditForm.Free;
  end;
end;

procedure TMainSyncForm.DeleteTask1Click(Sender: TObject);
var
  TaskID: Integer;
  TaskName: string;
begin
  if not Assigned(FSelectedTask) then
  begin
    ShowMessage('请先选择一个任务');
    Exit;
  end;
  
  TaskName := FSelectedTask.Name;
  TaskID := FSelectedTask.TaskID;
  
  if MessageDlg(Format('确定要删除任务 "%s" 吗？', [TaskName]), 
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      Memo1.Lines.Add(Format('[%s] 正在删除任务: %s (ID: %d)', 
        [FormatDateTime('hh:nn:ss', Now), TaskName, TaskID]));
      
      // 停止实时同步
      FRealtimeManager.StopRealtimeSync(TaskID);
      Memo1.Lines.Add(Format('[%s] 已停止实时同步', [FormatDateTime('hh:nn:ss', Now)]));
      
      // 从内存删除
      FSyncEngine.RemoveTask(FSelectedTask);
      Memo1.Lines.Add(Format('[%s] 已从内存列表删除', [FormatDateTime('hh:nn:ss', Now)]));
      
      // 从数据库删除
      if Assigned(FDatabase) and (TaskID > 0) then
      begin
        if FDatabase.DeleteSyncTask(TaskID) then
        begin
          Memo1.Lines.Add(Format('[%s] ✅ 已从数据库删除', [FormatDateTime('hh:nn:ss', Now)]));
        end
        else
        begin
          Memo1.Lines.Add(Format('[%s] ❌ 数据库删除失败', [FormatDateTime('hh:nn:ss', Now)]));
          ShowMessage('数据库删除失败，任务仅从内存中移除');
        end;
      end
      else
      begin
        Memo1.Lines.Add(Format('[%s] ⚠️ 数据库未连接或TaskID无效，跳过数据库删除', 
          [FormatDateTime('hh:nn:ss', Now)]));
      end;
      
      RefreshTaskList;
      Memo1.Lines.Add(Format('[%s] ✅ 任务删除完成: %s', 
        [FormatDateTime('hh:nn:ss', Now), TaskName]));
        
    except
      on E: Exception do
      begin
        Memo1.Lines.Add(Format('[%s] ❌ 删除任务异常: %s', 
          [FormatDateTime('hh:nn:ss', Now), E.Message]));
        ShowMessage('删除任务时发生错误: ' + E.Message);
      end;
    end;
  end;
end;
  FMinimizeToTray := False;
  Close;
end;

procedure TMainSyncForm.Refresh1Click(Sender: TObject);
begin
  RefreshTaskList;
end;

procedure TMainSyncForm.About1Click(Sender: TObject);
begin
  ShowAboutDialog;
end;

procedure TMainSyncForm.ListView1DblClick(Sender: TObject);
begin
  if Assigned(ListView1.Selected) then
  begin
    var Task := TSyncTask(ListView1.Selected.Data);
    ShowTaskProperties(Task);
  end;
end;

procedure TMainSyncForm.Button1Click(Sender: TObject);
begin
  // 开始同步
  if Assigned(FSelectedTask) then
  begin
    if FSelectedTask.Mode = smManual then
    begin
      // 手动同步
      // TODO: 执行手动同步
      ShowMessage('开始手动同步: ' + FSelectedTask.Name);
    end
    else
    begin
      // 启动实时同步
      FRealtimeManager.StartRealtimeSync(FSelectedTask);
      HandleSyncEvent(FSelectedTask, '实时同步已启动');
    end;
  end;
end;

procedure TMainSyncForm.Button2Click(Sender: TObject);
begin
  // 停止同步
  if Assigned(FSelectedTask) then
  begin
    if FSelectedTask.Mode = smRealtime then
    begin
      FRealtimeManager.StopRealtimeSync(FSelectedTask.ID);
      HandleSyncEvent(FSelectedTask, '实时同步已停止');
    end;
  end;
end;

procedure TMainSyncForm.Button3Click(Sender: TObject);
begin
  // 暂停同步
  if Assigned(FSelectedTask) then
  begin
    if FSelectedTask.Mode = smRealtime then
    begin
      FRealtimeManager.PauseRealtimeSync(FSelectedTask.ID);
      HandleSyncEvent(FSelectedTask, '实时同步已暂停');
    end;
  end;
end;

procedure TMainSyncForm.Button4Click(Sender: TObject);
begin
  // 恢复同步
  if Assigned(FSelectedTask) then
  begin
    if FSelectedTask.Mode = smRealtime then
    begin
      FRealtimeManager.ResumeRealtimeSync(FSelectedTask.ID);
      HandleSyncEvent(FSelectedTask, '实时同步已恢复');
    end;
  end;
end;

procedure TMainSyncForm.Timer1Timer(Sender: TObject);
begin
  UpdateStatistics;
end;

procedure TMainSyncForm.StartSync1Click(Sender: TObject);
begin
  Button1Click(Sender);
end;

procedure TMainSyncForm.StopSync1Click(Sender: TObject);
begin
  Button2Click(Sender);
end;

procedure TMainSyncForm.Properties1Click(Sender: TObject);
begin
  if Assigned(FSelectedTask) then
    ShowTaskProperties(FSelectedTask);
end;

procedure TMainSyncForm.Refresh2Click(Sender: TObject);
begin
  RefreshTaskList;
end;

procedure TMainSyncForm.RealClose;
begin
  // 设置真正退出标志
  FReallyClose := True;
  // 关闭程序
  Close;
end;

end.

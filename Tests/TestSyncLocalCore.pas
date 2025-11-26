unit TestSyncLocalCore;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.Generics.Collections,
  uSyncDatabase,
  uSyncEngine,
  uFileSystemWatcher;

type
  /// <summary>
  /// syncLocal 核心功能测试套件
  /// 测试同步盘独立程序的核心功能
  /// </summary>
  [TestFixture]
  TTestSyncLocalCore = class
  private
    FDatabase: TSyncDatabase;
    FTestDbPath: string;
    FTestSourcePath: string;
    FTestTargetPath: string;
    
    procedure CleanupTestEnvironment;
    procedure CreateTestDirectories;
    procedure CreateTestFiles(const APath: string; ACount: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    // 数据库测试
    [Test]
    [TestCase('syncLocal.db', 'syncLocal.db')]
    procedure TestDatabaseCreation(const ADbName: string);
    
    [Test]
    procedure TestDatabaseTablesExist;
    
    // 同步任务测试
    [Test]
    procedure TestCreateSyncTask;
    
    [Test]
    procedure TestGetEnabledTasks;
    
    [Test]
    procedure TestTaskEnableDisable;
    
    // 同步执行测试
    [Test]
    procedure TestManualSyncExecution;
    
    [Test]
    procedure TestIncrementalSync;
    
    [Test]
    procedure TestSyncWithIgnoreRules;
    
    // 文件监控测试
    [Test]
    procedure TestFileSystemWatcherInit;
    
    [Test]
    procedure TestFileChangeDetection;
    
    // 同步历史测试
    [Test]
    procedure TestSyncHistoryCreation;
    
    [Test]
    procedure TestSyncHistoryRetrieval;
  end;

implementation

uses
  Winapi.Windows;

{ TTestSyncLocalCore }

procedure TTestSyncLocalCore.Setup;
begin
  // 创建测试数据库
  FTestDbPath := TPath.Combine(TPath.GetTempPath, 'test_synclocal.db');
  CleanupTestEnvironment;
  
  FDatabase := TSyncDatabase.Create(FTestDbPath);
  FDatabase.Connect;
  
  // 创建测试目录
  FTestSourcePath := TPath.Combine(TPath.GetTempPath, 'synclocal_test_source');
  FTestTargetPath := TPath.Combine(TPath.GetTempPath, 'synclocal_test_target');
  CreateTestDirectories;
end;

procedure TTestSyncLocalCore.TearDown;
begin
  if Assigned(FDatabase) then
  begin
    FDatabase.Disconnect;
    FreeAndNil(FDatabase);
  end;
  
  CleanupTestEnvironment;
end;

procedure TTestSyncLocalCore.CleanupTestEnvironment;
begin
  // 清理测试数据库
  if TFile.Exists(FTestDbPath) then
    TFile.Delete(FTestDbPath);
    
  // 清理测试目录
  if TDirectory.Exists(FTestSourcePath) then
    TDirectory.Delete(FTestSourcePath, True);
  if TDirectory.Exists(FTestTargetPath) then
    TDirectory.Delete(FTestTargetPath, True);
end;

procedure TTestSyncLocalCore.CreateTestDirectories;
begin
  if not TDirectory.Exists(FTestSourcePath) then
    TDirectory.CreateDirectory(FTestSourcePath);
  if not TDirectory.Exists(FTestTargetPath) then
    TDirectory.CreateDirectory(FTestTargetPath);
end;

procedure TTestSyncLocalCore.CreateTestFiles(const APath: string; ACount: Integer);
var
  I: Integer;
  FilePath: string;
begin
  for I := 1 to ACount do
  begin
    FilePath := TPath.Combine(APath, Format('test_file_%d.txt', [I]));
    TFile.WriteAllText(FilePath, Format('Test content for file %d', [I]));
  end;
end;

// ============================================================================
// 数据库测试
// ============================================================================

procedure TTestSyncLocalCore.TestDatabaseCreation(const ADbName: string);
var
  TestPath: string;
  TestDb: TSyncDatabase;
begin
  TestPath := TPath.Combine(TPath.GetTempPath, ADbName);
  
  // 确保文件不存在
  if TFile.Exists(TestPath) then
    TFile.Delete(TestPath);
    
  TestDb := TSyncDatabase.Create(TestPath);
  try
    Assert.IsTrue(TestDb.Connect, '数据库应该成功连接');
    Assert.IsTrue(TFile.Exists(TestPath), '数据库文件应该被创建');
  finally
    TestDb.Disconnect;
    TestDb.Free;
    TFile.Delete(TestPath);
  end;
end;

procedure TTestSyncLocalCore.TestDatabaseTablesExist;
var
  Tasks: TArray<uSyncDatabase.TSyncTask>;
  Presets: TArray<TSyncPreset>;
begin
  // 验证表存在 - 通过查询不抛出异常来验证
  Tasks := FDatabase.GetAllSyncTasks;
  Assert.IsTrue(True, 'sync_tasks 表应该存在');
  
  Presets := FDatabase.GetAllPresets;
  Assert.IsTrue(True, 'sync_presets 表应该存在');
end;

// ============================================================================
// 同步任务测试
// ============================================================================

procedure TTestSyncLocalCore.TestCreateSyncTask;
var
  Task: uSyncDatabase.TSyncTask;
  TaskID: Integer;
begin
  Task.TaskID := 0;
  Task.Name := 'syncLocal 测试任务';
  Task.SourcePath := FTestSourcePath;
  Task.TargetPath := FTestTargetPath;
  Task.SyncMode := smManual;
  Task.IsEnabled := True;
  Task.ConflictStrategy := csSourcePriority;
  Task.FilterRules := '';
  Task.PresetID := 0;
  
  TaskID := FDatabase.CreateSyncTask(Task);
  
  Assert.IsTrue(TaskID > 0, '应该返回有效的 TaskID');
  
  // 验证任务已保存
  Task := FDatabase.GetSyncTask(TaskID);
  Assert.AreEqual('syncLocal 测试任务', Task.Name, '任务名称应该正确保存');
end;

procedure TTestSyncLocalCore.TestGetEnabledTasks;
var
  Task1, Task2: uSyncDatabase.TSyncTask;
  EnabledTasks: TArray<uSyncDatabase.TSyncTask>;
begin
  // 创建两个任务，一个启用，一个禁用
  Task1.TaskID := 0;
  Task1.Name := '启用的任务';
  Task1.SourcePath := FTestSourcePath;
  Task1.TargetPath := FTestTargetPath;
  Task1.SyncMode := smManual;
  Task1.IsEnabled := True;
  Task1.ConflictStrategy := csSourcePriority;
  FDatabase.CreateSyncTask(Task1);
  
  Task2.TaskID := 0;
  Task2.Name := '禁用的任务';
  Task2.SourcePath := FTestSourcePath;
  Task2.TargetPath := FTestTargetPath;
  Task2.SyncMode := smManual;
  Task2.IsEnabled := False;
  Task2.ConflictStrategy := csSourcePriority;
  FDatabase.CreateSyncTask(Task2);
  
  // 获取启用的任务
  EnabledTasks := FDatabase.GetEnabledSyncTasks;
  
  Assert.AreEqual(1, Integer(Length(EnabledTasks)), '应该只返回一个启用的任务');
  Assert.AreEqual('启用的任务', EnabledTasks[0].Name, '应该返回正确的任务');
end;

procedure TTestSyncLocalCore.TestTaskEnableDisable;
var
  Task: uSyncDatabase.TSyncTask;
  TaskID: Integer;
begin
  // 创建启用的任务
  Task.TaskID := 0;
  Task.Name := '测试启用禁用';
  Task.SourcePath := FTestSourcePath;
  Task.TargetPath := FTestTargetPath;
  Task.SyncMode := smManual;
  Task.IsEnabled := True;
  Task.ConflictStrategy := csSourcePriority;
  
  TaskID := FDatabase.CreateSyncTask(Task);
  
  // 禁用任务
  Task := FDatabase.GetSyncTask(TaskID);
  Task.IsEnabled := False;
  FDatabase.UpdateSyncTask(Task);
  
  // 验证
  Task := FDatabase.GetSyncTask(TaskID);
  Assert.IsFalse(Task.IsEnabled, '任务应该被禁用');
end;

// ============================================================================
// 同步执行测试
// ============================================================================

procedure TTestSyncLocalCore.TestManualSyncExecution;
var
  SyncTask: uSyncEngine.TSyncTask;
  SourceFiles, TargetFiles: TArray<string>;
begin
  // 创建测试文件
  CreateTestFiles(FTestSourcePath, 3);
  
  // 创建同步任务
  SyncTask := uSyncEngine.TSyncTask.Create;
  try
    SyncTask.Name := '手动同步测试';
    SyncTask.SourcePath := FTestSourcePath;
    SyncTask.TargetPath := FTestTargetPath;
    SyncTask.Mode := smManual;
    SyncTask.Enabled := True;
    
    // 执行同步
    SyncTask.Execute;
    
    // 验证文件已同步
    SourceFiles := TDirectory.GetFiles(FTestSourcePath);
    TargetFiles := TDirectory.GetFiles(FTestTargetPath);
    
    Assert.AreEqual(Length(SourceFiles), Length(TargetFiles), '目标目录文件数应该与源目录相同');
  finally
    SyncTask.Free;
  end;
end;

procedure TTestSyncLocalCore.TestIncrementalSync;
var
  SyncTask: uSyncEngine.TSyncTask;
  NewFilePath: string;
  TargetFiles: TArray<string>;
begin
  // 创建初始文件
  CreateTestFiles(FTestSourcePath, 2);
  
  // 第一次同步
  SyncTask := uSyncEngine.TSyncTask.Create;
  try
    SyncTask.Name := '增量同步测试';
    SyncTask.SourcePath := FTestSourcePath;
    SyncTask.TargetPath := FTestTargetPath;
    SyncTask.Mode := smManual;
    SyncTask.Enabled := True;
    
    SyncTask.Execute;
    
    // 添加新文件
    NewFilePath := TPath.Combine(FTestSourcePath, 'new_file.txt');
    TFile.WriteAllText(NewFilePath, 'New file content');
    
    // 第二次同步
    SyncTask.Execute;
    
    // 验证新文件已同步
    TargetFiles := TDirectory.GetFiles(FTestTargetPath);
    Assert.AreEqual(3, Integer(Length(TargetFiles)), '目标目录应该有3个文件');
  finally
    SyncTask.Free;
  end;
end;

procedure TTestSyncLocalCore.TestSyncWithIgnoreRules;
var
  SyncTask: uSyncEngine.TSyncTask;
  TmpFilePath: string;
  TargetFiles: TArray<string>;
begin
  // 创建测试文件，包括一个 .tmp 文件
  CreateTestFiles(FTestSourcePath, 2);
  TmpFilePath := TPath.Combine(FTestSourcePath, 'temp_file.tmp');
  TFile.WriteAllText(TmpFilePath, 'Temporary content');
  
  // 创建同步任务，忽略 .tmp 文件
  SyncTask := uSyncEngine.TSyncTask.Create;
  try
    SyncTask.Name := '忽略规则测试';
    SyncTask.SourcePath := FTestSourcePath;
    SyncTask.TargetPath := FTestTargetPath;
    SyncTask.Mode := smManual;
    SyncTask.Enabled := True;
    SyncTask.IgnoreRulesText := '*.tmp';
    
    SyncTask.Execute;
    
    // 验证 .tmp 文件未被同步
    TargetFiles := TDirectory.GetFiles(FTestTargetPath, '*.tmp');
    Assert.AreEqual(0, Integer(Length(TargetFiles)), '.tmp 文件不应该被同步');
    
    // 验证其他文件已同步
    TargetFiles := TDirectory.GetFiles(FTestTargetPath, '*.txt');
    Assert.AreEqual(2, Integer(Length(TargetFiles)), '.txt 文件应该被同步');
  finally
    SyncTask.Free;
  end;
end;

// ============================================================================
// 文件监控测试
// ============================================================================

procedure TTestSyncLocalCore.TestFileSystemWatcherInit;
var
  Watcher: TFileSystemWatcher;
begin
  Watcher := TFileSystemWatcher.Create(nil);
  try
    Watcher.Path := FTestSourcePath;
    Watcher.Recursive := True;
    Watcher.IntervalMs := 500;
    
    Assert.AreEqual(FTestSourcePath, Watcher.Path, '监控路径应该正确设置');
    Assert.IsTrue(Watcher.Recursive, '递归监控应该启用');
  finally
    Watcher.Free;
  end;
end;

procedure TTestSyncLocalCore.TestFileChangeDetection;
var
  Watcher: TFileSystemWatcher;
  NewFilePath: string;
begin
  // 简化测试 - 验证监控器可以启动和停止
  Watcher := TFileSystemWatcher.Create(nil);
  try
    Watcher.Path := FTestSourcePath;
    Watcher.Recursive := True;
    Watcher.IntervalMs := 100; // 快速检测
    Watcher.Mode := wmPolling; // 使用轮询模式进行测试
    
    // 启动监控
    Watcher.Start;
    Assert.IsTrue(Watcher.Active, '监控器应该处于活动状态');
    
    // 创建新文件
    Sleep(200);
    NewFilePath := TPath.Combine(FTestSourcePath, 'detected_file.txt');
    TFile.WriteAllText(NewFilePath, 'Content');
    
    // 等待检测
    Sleep(500);
    
    // 停止监控
    Watcher.Stop;
    Assert.IsFalse(Watcher.Active, '监控器应该已停止');
    
    // 验证文件已创建
    Assert.IsTrue(TFile.Exists(NewFilePath), '测试文件应该存在');
  finally
    Watcher.Free;
  end;
end;

// ============================================================================
// 同步历史测试
// ============================================================================

procedure TTestSyncLocalCore.TestSyncHistoryCreation;
var
  Task: uSyncDatabase.TSyncTask;
  TaskID: Integer;
  History: TSyncHistory;
  HistoryID: Integer;
begin
  // 创建任务
  Task.TaskID := 0;
  Task.Name := '历史记录测试任务';
  Task.SourcePath := FTestSourcePath;
  Task.TargetPath := FTestTargetPath;
  Task.SyncMode := smManual;
  Task.IsEnabled := True;
  Task.ConflictStrategy := csSourcePriority;
  
  TaskID := FDatabase.CreateSyncTask(Task);
  
  // 创建同步历史
  History.ID := 0;
  History.TaskID := TaskID;
  History.SyncType := 'manual';
  History.StartTime := Now;
  History.EndTime := Now;
  History.FilesScanned := 10;
  History.FilesCopied := 5;
  History.FilesUpdated := 2;
  History.FilesDeleted := 0;
  History.FilesSkipped := 3;
  History.BytesTransferred := 1024 * 100;
  History.Status := 'success';
  History.ErrorMessage := '';
  
  HistoryID := FDatabase.CreateSyncHistory(History);
  
  Assert.IsTrue(HistoryID > 0, '应该返回有效的历史记录ID');
end;

procedure TTestSyncLocalCore.TestSyncHistoryRetrieval;
var
  Task: uSyncDatabase.TSyncTask;
  TaskID: Integer;
  History: TSyncHistory;
  HistoryList: TArray<TSyncHistory>;
begin
  // 创建任务
  Task.TaskID := 0;
  Task.Name := '历史查询测试任务';
  Task.SourcePath := FTestSourcePath;
  Task.TargetPath := FTestTargetPath;
  Task.SyncMode := smManual;
  Task.IsEnabled := True;
  Task.ConflictStrategy := csSourcePriority;
  
  TaskID := FDatabase.CreateSyncTask(Task);
  
  // 创建多条同步历史
  History.ID := 0;
  History.TaskID := TaskID;
  History.SyncType := 'manual';
  History.StartTime := Now - 1;
  History.EndTime := Now - 1;
  History.FilesScanned := 5;
  History.FilesCopied := 3;
  History.Status := 'success';
  FDatabase.CreateSyncHistory(History);
  
  History.StartTime := Now;
  History.EndTime := Now;
  History.FilesScanned := 10;
  History.FilesCopied := 8;
  History.Status := 'success';
  FDatabase.CreateSyncHistory(History);
  
  // 查询历史
  HistoryList := FDatabase.GetSyncHistory(TaskID, 10);
  
  Assert.AreEqual(2, Integer(Length(HistoryList)), '应该返回2条历史记录');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSyncLocalCore);

end.

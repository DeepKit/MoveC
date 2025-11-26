unit TestSyncTask;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  uSyncDatabase,
  uSyncEngine;

type
  [TestFixture]
  TTestSyncTask = class
  private
    FDatabase: TSyncDatabase;
    FTestDbPath: string;
    FTestSourceDir: string;
    FTestTargetDir: string;
    procedure CleanupTestFiles;
    procedure CreateTestFiles;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure TestCreateTaskWithDatabase;
    
    [Test]
    procedure TestTaskSaveToDatabase;
    
    [Test]
    procedure TestTaskLoadFromDatabase;
    
    [Test]
    procedure TestTaskSaveAndReload;
    
    [Test]
    procedure TestTaskUpdatePersistence;
    
    [Test]
    procedure TestTaskWithoutDatabase;
  end;

implementation

{ TTestSyncTask }

procedure TTestSyncTask.Setup;
begin
  FTestDbPath := TPath.Combine(TPath.GetTempPath, 'test_sync_task.db');
  FTestSourceDir := TPath.Combine(TPath.GetTempPath, 'test_source');
  FTestTargetDir := TPath.Combine(TPath.GetTempPath, 'test_target');
  
  CleanupTestFiles;
  CreateTestFiles;
  
  FDatabase := TSyncDatabase.Create(FTestDbPath);
  FDatabase.Connect;
end;

procedure TTestSyncTask.TearDown;
begin
  if Assigned(FDatabase) then
  begin
    FDatabase.Disconnect;
    FreeAndNil(FDatabase);
  end;
  
  CleanupTestFiles;
end;

procedure TTestSyncTask.CleanupTestFiles;
begin
  if TFile.Exists(FTestDbPath) then
    TFile.Delete(FTestDbPath);
    
  if TDirectory.Exists(FTestSourceDir) then
    TDirectory.Delete(FTestSourceDir, True);
    
  if TDirectory.Exists(FTestTargetDir) then
    TDirectory.Delete(FTestTargetDir, True);
end;

procedure TTestSyncTask.CreateTestFiles;
begin
  TDirectory.CreateDirectory(FTestSourceDir);
  TDirectory.CreateDirectory(FTestTargetDir);
  
  // 创建一些测试文件
  TFile.WriteAllText(TPath.Combine(FTestSourceDir, 'test1.txt'), 'Test content 1');
  TFile.WriteAllText(TPath.Combine(FTestSourceDir, 'test2.txt'), 'Test content 2');
end;

procedure TTestSyncTask.TestCreateTaskWithDatabase;
var
  Task: TSyncTask;
begin
  // Act
  Task := TSyncTask.CreateWithDatabase(FDatabase);
  try
    // Assert
    Assert.IsNotNull(Task, '任务应该被创建');
    Assert.IsTrue(Task.TaskID = 0, '新任务的 TaskID 应该是 0');
  finally
    Task.Free;
  end;
end;

procedure TTestSyncTask.TestTaskSaveToDatabase;
var
  Task: TSyncTask;
  SavedID: Integer;
begin
  // Arrange
  Task := TSyncTask.CreateWithDatabase(FDatabase);
  try
    Task.Name := 'Test Save Task';
    Task.SourcePath := FTestSourceDir;
    Task.TargetPath := FTestTargetDir;
    Task.Mode := smManual;
    Task.Enabled := True;
    
    // Act
    Task.Save;
    SavedID := Task.TaskID;
    
    // Assert
    Assert.IsTrue(SavedID > 0, '保存后应该有有效的 TaskID');
  finally
    Task.Free;
  end;
end;

procedure TTestSyncTask.TestTaskLoadFromDatabase;
var
  Task1, Task2: TSyncTask;
  TaskID: Integer;
begin
  // Arrange - 创建并保存任务
  Task1 := TSyncTask.CreateWithDatabase(FDatabase);
  try
    Task1.Name := 'Test Load Task';
    Task1.SourcePath := FTestSourceDir;
    Task1.TargetPath := FTestTargetDir;
    Task1.Mode := smRealtime;
    Task1.Enabled := False;
    Task1.ConflictStrategy := csNewerPriority;
    
    Task1.Save;
    TaskID := Task1.TaskID;
  finally
    Task1.Free;
  end;
  
  // Act - 加载任务
  Task2 := TSyncTask.CreateWithDatabase(FDatabase);
  try
    Task2.TaskID := TaskID;
    Task2.Load;
    
    // Assert
    Assert.AreEqual('Test Load Task', Task2.Name, '任务名称应该匹配');
    Assert.AreEqual(FTestSourceDir, Task2.SourcePath, '源路径应该匹配');
    Assert.AreEqual(FTestTargetDir, Task2.TargetPath, '目标路径应该匹配');
    Assert.AreEqual(Ord(smRealtime), Ord(Task2.Mode), '同步模式应该匹配');
    Assert.IsFalse(Task2.Enabled, '启用状态应该匹配');
    Assert.AreEqual(Ord(csNewerPriority), Ord(Task2.ConflictStrategy), '冲突策略应该匹配');
  finally
    Task2.Free;
  end;
end;

procedure TTestSyncTask.TestTaskSaveAndReload;
var
  Task: TSyncTask;
  TaskID: Integer;
  ReloadedTask: TSyncTask;
begin
  // Arrange & Act - 保存
  Task := TSyncTask.CreateWithDatabase(FDatabase);
  try
    Task.Name := 'Save and Reload Test';
    Task.SourcePath := FTestSourceDir;
    Task.TargetPath := FTestTargetDir;
    Task.Mode := smManual;
    
    Task.Save;
    TaskID := Task.TaskID;
  finally
    Task.Free;
  end;
  
  // Act - 重新加载
  ReloadedTask := TSyncTask.CreateWithDatabase(FDatabase);
  try
    ReloadedTask.TaskID := TaskID;
    ReloadedTask.Load;
    
    // Assert
    Assert.AreEqual('Save and Reload Test', ReloadedTask.Name, '重新加载后数据应该一致');
    Assert.AreEqual(Ord(smManual), Ord(ReloadedTask.Mode), '同步模式应该保持');
  finally
    ReloadedTask.Free;
  end;
end;

procedure TTestSyncTask.TestTaskUpdatePersistence;
var
  Task: TSyncTask;
  TaskID: Integer;
  UpdatedTask: TSyncTask;
begin
  // Arrange - 创建并保存
  Task := TSyncTask.CreateWithDatabase(FDatabase);
  try
    Task.Name := 'Original Name';
    Task.SourcePath := FTestSourceDir;
    Task.TargetPath := FTestTargetDir;
    Task.Save;
    TaskID := Task.TaskID;
    
    // Act - 更新
    Task.Name := 'Updated Name';
    Task.Mode := smRealtime;
    Task.Save;
  finally
    Task.Free;
  end;
  
  // Assert - 验证更新持久化
  UpdatedTask := TSyncTask.CreateWithDatabase(FDatabase);
  try
    UpdatedTask.TaskID := TaskID;
    UpdatedTask.Load;
    
    Assert.AreEqual('Updated Name', UpdatedTask.Name, '更新后的名称应该被保存');
    Assert.AreEqual(Ord(smRealtime), Ord(UpdatedTask.Mode), '更新后的模式应该被保存');
  finally
    UpdatedTask.Free;
  end;
end;

procedure TTestSyncTask.TestTaskWithoutDatabase;
var
  Task: TSyncTask;
begin
  // Arrange
  Task := TSyncTask.Create;
  try
    Task.Name := 'No Database Task';
    Task.SourcePath := FTestSourceDir;
    Task.TargetPath := FTestTargetDir;
    
    // Act & Assert - 不应该崩溃
    Task.Save; // 应该安全地不做任何事
    
    Assert.AreEqual(0, Task.TaskID, '没有数据库时 TaskID 应该保持 0');
  finally
    Task.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSyncTask);

end.

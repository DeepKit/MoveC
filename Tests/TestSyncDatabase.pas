unit TestSyncDatabase;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.IOUtils,
  uSyncDatabase,
  uSyncEngine;

type
  [TestFixture]
  TTestSyncDatabase = class
  private
    FDatabase: TSyncDatabase;
    FTestDbPath: string;
    procedure CleanupTestDatabase;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure TestDatabaseConnection;
    
    [Test]
    procedure TestCreateSyncTask;
    
    [Test]
    procedure TestUpdateSyncTask;
    
    [Test]
    procedure TestDeleteSyncTask;
    
    [Test]
    procedure TestGetSyncTask;
    
    [Test]
    procedure TestGetAllSyncTasks;
    
    [Test]
    procedure TestTaskPersistence;
  end;

implementation

{ TTestSyncDatabase }

procedure TTestSyncDatabase.Setup;
begin
  // 使用测试专用的数据库
  FTestDbPath := TPath.Combine(TPath.GetTempPath, 'test_sync.db');
  CleanupTestDatabase;
  
  FDatabase := TSyncDatabase.Create(FTestDbPath);
end;

procedure TTestSyncDatabase.TearDown;
begin
  if Assigned(FDatabase) then
  begin
    FDatabase.Disconnect;
    FreeAndNil(FDatabase);
  end;
  
  CleanupTestDatabase;
end;

procedure TTestSyncDatabase.CleanupTestDatabase;
begin
  if TFile.Exists(FTestDbPath) then
    TFile.Delete(FTestDbPath);
end;

procedure TTestSyncDatabase.TestDatabaseConnection;
var
  Connected: Boolean;
begin
  // Act
  Connected := FDatabase.Connect;
  
  // Assert
  Assert.IsTrue(Connected, '数据库应该成功连接');
  Assert.IsTrue(TFile.Exists(FTestDbPath), '数据库文件应该被创建');
end;

procedure TTestSyncDatabase.TestCreateSyncTask;
var
  Task: uSyncDatabase.TSyncTask;
  TaskID: Integer;
begin
  // Arrange
  FDatabase.Connect;
  Task.TaskID := 0;
  Task.Name := 'Test Task';
  Task.SourcePath := 'C:\Source';
  Task.TargetPath := 'D:\Target';
  Task.SyncMode := smManual;
  Task.IsEnabled := True;
  Task.ConflictStrategy := csSourcePriority;
  
  // Act
  TaskID := FDatabase.CreateSyncTask(Task);
  
  // Assert
  Assert.IsTrue(TaskID > 0, '应该返回有效的 TaskID');
end;

procedure TTestSyncDatabase.TestUpdateSyncTask;
var
  Task: uSyncDatabase.TSyncTask;
  TaskID: Integer;
  UpdatedTask: uSyncDatabase.TSyncTask;
begin
  // Arrange
  FDatabase.Connect;
  Task.TaskID := 0;
  Task.Name := 'Original Name';
  Task.SourcePath := 'C:\Source';
  Task.TargetPath := 'D:\Target';
  Task.SyncMode := smManual;
  Task.IsEnabled := True;
  Task.ConflictStrategy := csSourcePriority;
  
  TaskID := FDatabase.CreateSyncTask(Task);
  
  // Act
  Task.TaskID := TaskID;
  Task.Name := 'Updated Name';
  FDatabase.UpdateSyncTask(Task);
  
  // Assert
  UpdatedTask := FDatabase.GetSyncTask(TaskID);
  Assert.AreEqual('Updated Name', UpdatedTask.Name, '任务名称应该被更新');
end;

procedure TTestSyncDatabase.TestDeleteSyncTask;
var
  Task: uSyncDatabase.TSyncTask;
  TaskID: Integer;
  AllTasks: TArray<uSyncDatabase.TSyncTask>;
begin
  // Arrange
  FDatabase.Connect;
  Task.TaskID := 0;
  Task.Name := 'Task to Delete';
  Task.SourcePath := 'C:\Source';
  Task.TargetPath := 'D:\Target';
  Task.SyncMode := smManual;
  Task.IsEnabled := True;
  Task.ConflictStrategy := csSourcePriority;
  
  TaskID := FDatabase.CreateSyncTask(Task);
  
  // Act
  FDatabase.DeleteSyncTask(TaskID);
  
  // Assert
  AllTasks := FDatabase.GetAllSyncTasks;
  Assert.AreEqual(0, Integer(Length(AllTasks)), '删除后应该没有任务');
end;

procedure TTestSyncDatabase.TestGetSyncTask;
var
  Task: uSyncDatabase.TSyncTask;
  TaskID: Integer;
  RetrievedTask: uSyncDatabase.TSyncTask;
begin
  // Arrange
  FDatabase.Connect;
  Task.TaskID := 0;
  Task.Name := 'Test Task';
  Task.SourcePath := 'C:\Source';
  Task.TargetPath := 'D:\Target';
  Task.SyncMode := smRealtime;
  Task.ConflictStrategy := csNewerPriority;
  Task.IsEnabled := True;
  
  TaskID := FDatabase.CreateSyncTask(Task);
  
  // Act
  RetrievedTask := FDatabase.GetSyncTask(TaskID);
  
  // Assert
  Assert.AreEqual(TaskID, RetrievedTask.TaskID, 'TaskID 应该匹配');
  Assert.AreEqual('Test Task', RetrievedTask.Name, '任务名称应该匹配');
  Assert.AreEqual('C:\Source', RetrievedTask.SourcePath, '源路径应该匹配');
  Assert.AreEqual('D:\Target', RetrievedTask.TargetPath, '目标路径应该匹配');
  Assert.AreEqual(Integer(smRealtime), Integer(RetrievedTask.SyncMode), '同步模式应该匹配');
  Assert.AreEqual(Integer(csNewerPriority), Integer(RetrievedTask.ConflictStrategy), '冲突策略应该匹配');
end;

procedure TTestSyncDatabase.TestGetAllSyncTasks;
var
  Task1, Task2: uSyncDatabase.TSyncTask;
  AllTasks: TArray<uSyncDatabase.TSyncTask>;
begin
  // Arrange
  FDatabase.Connect;
  
  Task1.TaskID := 0;
  Task1.Name := 'Task 1';
  Task1.SourcePath := 'C:\Source1';
  Task1.TargetPath := 'D:\Target1';
  Task1.SyncMode := smManual;
  Task1.IsEnabled := True;
  Task1.ConflictStrategy := csSourcePriority;
  
  Task2.TaskID := 0;
  Task2.Name := 'Task 2';
  Task2.SourcePath := 'C:\Source2';
  Task2.TargetPath := 'D:\Target2';
  Task2.SyncMode := smManual;
  Task2.IsEnabled := True;
  Task2.ConflictStrategy := csSourcePriority;
  
  FDatabase.CreateSyncTask(Task1);
  FDatabase.CreateSyncTask(Task2);
  
  // Act
  AllTasks := FDatabase.GetAllSyncTasks;
  
  // Assert
  Assert.AreEqual(2, Integer(Length(AllTasks)), '应该返回 2 个任务');
end;

procedure TTestSyncDatabase.TestTaskPersistence;
var
  Task: uSyncDatabase.TSyncTask;
  TaskID: Integer;
  Database2: TSyncDatabase;
  RetrievedTask: uSyncDatabase.TSyncTask;
begin
  // Arrange
  FDatabase.Connect;
  Task.TaskID := 0;
  Task.Name := 'Persistent Task';
  Task.SourcePath := 'C:\Source';
  Task.TargetPath := 'D:\Target';
  Task.SyncMode := smManual;
  Task.IsEnabled := True;
  Task.ConflictStrategy := csSourcePriority;
  
  TaskID := FDatabase.CreateSyncTask(Task);
  FDatabase.Disconnect;
  FreeAndNil(FDatabase);
  
  // Act - 重新打开数据库
  Database2 := TSyncDatabase.Create(FTestDbPath);
  try
    Database2.Connect;
    RetrievedTask := Database2.GetSyncTask(TaskID);
    
    // Assert
    Assert.AreEqual('Persistent Task', RetrievedTask.Name, '重新打开后任务应该仍然存在');
  finally
    Database2.Disconnect;
    Database2.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSyncDatabase);

end.

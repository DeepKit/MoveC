unit TestSyncExecution;

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
  TTestSyncExecution = class
  private
    FDatabase: TSyncDatabase;
    FTestDbPath: string;
    FSourceDir: string;
    FTargetDir: string;
    procedure CleanupTestDirs;
    procedure CreateTestStructure;
    function CountFiles(const ADirectory: string): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    [Test]
    procedure TestBasicSync;
    
    [Test]
    procedure TestIncrementalSync;
    
    [Test]
    procedure TestIgnoreRules;
    
    [Test]
    procedure TestSubdirectorySync;
    
    [Test]
    procedure TestEmptyDirectoryHandling;
    
    [Test]
    procedure TestNonExistentSource;
  end;

implementation

{ TTestSyncExecution }

procedure TTestSyncExecution.Setup;
begin
  FTestDbPath := TPath.Combine(TPath.GetTempPath, 'test_sync_exec.db');
  FSourceDir := TPath.Combine(TPath.GetTempPath, 'sync_test_source');
  FTargetDir := TPath.Combine(TPath.GetTempPath, 'sync_test_target');
  
  CleanupTestDirs;
  CreateTestStructure;
  
  FDatabase := TSyncDatabase.Create(FTestDbPath);
  FDatabase.Connect;
end;

procedure TTestSyncExecution.TearDown;
begin
  if Assigned(FDatabase) then
  begin
    FDatabase.Disconnect;
    FreeAndNil(FDatabase);
  end;
  
  CleanupTestDirs;
end;

procedure TTestSyncExecution.CleanupTestDirs;
begin
  if TFile.Exists(FTestDbPath) then
    TFile.Delete(FTestDbPath);
    
  if TDirectory.Exists(FSourceDir) then
    TDirectory.Delete(FSourceDir, True);
    
  if TDirectory.Exists(FTargetDir) then
    TDirectory.Delete(FTargetDir, True);
end;

procedure TTestSyncExecution.CreateTestStructure;
begin
  TDirectory.CreateDirectory(FSourceDir);
  TDirectory.CreateDirectory(TPath.Combine(FSourceDir, 'subfolder'));
  
  // 创建测试文件
  TFile.WriteAllText(TPath.Combine(FSourceDir, 'file1.txt'), 'Content 1');
  TFile.WriteAllText(TPath.Combine(FSourceDir, 'file2.txt'), 'Content 2');
  TFile.WriteAllText(TPath.Combine(FSourceDir, 'subfolder', 'file3.txt'), 'Content 3');
  
  // 创建一些需要忽略的文件
  TFile.WriteAllText(TPath.Combine(FSourceDir, 'temp.tmp'), 'Temp file');
  TFile.WriteAllText(TPath.Combine(FSourceDir, 'debug.log'), 'Log file');
end;

function TTestSyncExecution.CountFiles(const ADirectory: string): Integer;
var
  Files: TArray<string>;
begin
  if not TDirectory.Exists(ADirectory) then
    Exit(0);
    
  Files := TDirectory.GetFiles(ADirectory, '*', TSearchOption.soAllDirectories);
  Result := Length(Files);
end;

procedure TTestSyncExecution.TestBasicSync;
var
  Task: TSyncTask;
  SyncCompleted: Boolean;
  SourceFileCount, TargetFileCount: Integer;
begin
  // Arrange
  Task := TSyncTask.CreateWithDatabase(FDatabase);
  try
    Task.Name := 'Basic Sync Test';
    Task.SourcePath := FSourceDir;
    Task.TargetPath := FTargetDir;
    Task.Mode := smManual;
    
    SyncCompleted := False;
    // Note: OnComplete requires 'of object' type, so we skip callback test here
    // Task.OnComplete := ...;
    
    // Act
    Task.Execute;
    
    // Assert
    Assert.IsTrue(SyncCompleted, '同步应该完成');
    Assert.IsTrue(TDirectory.Exists(FTargetDir), '目标目录应该被创建');
    
    SourceFileCount := CountFiles(FSourceDir);
    TargetFileCount := CountFiles(FTargetDir);
    
    Assert.AreEqual(SourceFileCount, TargetFileCount, '文件数量应该相同');
    
    // 验证特定文件存在
    Assert.IsTrue(TFile.Exists(TPath.Combine(FTargetDir, 'file1.txt')), 'file1.txt 应该被同步');
    Assert.IsTrue(TFile.Exists(TPath.Combine(FTargetDir, 'subfolder', 'file3.txt')), 'file3.txt 应该被同步');
  finally
    Task.Free;
  end;
end;

procedure TTestSyncExecution.TestIncrementalSync;
var
  Task: TSyncTask;
  InitialTargetTime, UpdatedTargetTime: TDateTime;
begin
  // Arrange - 首次同步
  Task := TSyncTask.CreateWithDatabase(FDatabase);
  try
    Task.Name := 'Incremental Sync Test';
    Task.SourcePath := FSourceDir;
    Task.TargetPath := FTargetDir;
    Task.Mode := smManual;
    
    Task.Execute;
    
    // 记录目标文件时间
    InitialTargetTime := TFile.GetLastWriteTime(TPath.Combine(FTargetDir, 'file1.txt'));
    
    // 等待一秒以确保时间戳不同
    Sleep(1100);
    
    // 修改源文件
    TFile.WriteAllText(TPath.Combine(FSourceDir, 'file1.txt'), 'Updated content');
    
    // Act - 增量同步
    Task.Execute;
    
    // Assert
    UpdatedTargetTime := TFile.GetLastWriteTime(TPath.Combine(FTargetDir, 'file1.txt'));
    Assert.IsTrue(UpdatedTargetTime > InitialTargetTime, '修改的文件应该被更新');
    
    // 验证内容
    Assert.AreEqual('Updated content', 
                    TFile.ReadAllText(TPath.Combine(FTargetDir, 'file1.txt')), 
                    '文件内容应该被更新');
  finally
    Task.Free;
  end;
end;

procedure TTestSyncExecution.TestIgnoreRules;
var
  Task: TSyncTask;
begin
  // Arrange
  Task := TSyncTask.CreateWithDatabase(FDatabase);
  try
    Task.Name := 'Ignore Rules Test';
    Task.SourcePath := FSourceDir;
    Task.TargetPath := FTargetDir;
    Task.Mode := smManual;
    Task.IgnoreRulesText := '*.tmp,*.log';
    
    // Act
    Task.Execute;
    
    // Assert
    Assert.IsTrue(TFile.Exists(TPath.Combine(FTargetDir, 'file1.txt')), '普通文件应该被同步');
    Assert.IsFalse(TFile.Exists(TPath.Combine(FTargetDir, 'temp.tmp')), '.tmp 文件应该被忽略');
    Assert.IsFalse(TFile.Exists(TPath.Combine(FTargetDir, 'debug.log')), '.log 文件应该被忽略');
  finally
    Task.Free;
  end;
end;

procedure TTestSyncExecution.TestSubdirectorySync;
var
  Task: TSyncTask;
begin
  // Arrange
  Task := TSyncTask.CreateWithDatabase(FDatabase);
  try
    Task.Name := 'Subdirectory Test';
    Task.SourcePath := FSourceDir;
    Task.TargetPath := FTargetDir;
    Task.Mode := smManual;
    
    // Act
    Task.Execute;
    
    // Assert
    Assert.IsTrue(TDirectory.Exists(TPath.Combine(FTargetDir, 'subfolder')), '子目录应该被创建');
    Assert.IsTrue(TFile.Exists(TPath.Combine(FTargetDir, 'subfolder', 'file3.txt')), '子目录中的文件应该被同步');
    
    // 验证内容
    Assert.AreEqual('Content 3', 
                    TFile.ReadAllText(TPath.Combine(FTargetDir, 'subfolder', 'file3.txt')), 
                    '子目录文件内容应该正确');
  finally
    Task.Free;
  end;
end;

procedure TTestSyncExecution.TestEmptyDirectoryHandling;
var
  Task: TSyncTask;
  EmptySourceDir, EmptyTargetDir: string;
begin
  // Arrange
  EmptySourceDir := TPath.Combine(TPath.GetTempPath, 'empty_source');
  EmptyTargetDir := TPath.Combine(TPath.GetTempPath, 'empty_target');
  
  try
    TDirectory.CreateDirectory(EmptySourceDir);
    
    Task := TSyncTask.CreateWithDatabase(FDatabase);
    try
      Task.Name := 'Empty Directory Test';
      Task.SourcePath := EmptySourceDir;
      Task.TargetPath := EmptyTargetDir;
      Task.Mode := smManual;
      
      // Act
      Task.Execute;
      
      // Assert
      Assert.IsTrue(TDirectory.Exists(EmptyTargetDir), '空源目录同步后目标目录应该存在');
      Assert.AreEqual(0, CountFiles(EmptyTargetDir), '目标目录应该是空的');
    finally
      Task.Free;
    end;
  finally
    if TDirectory.Exists(EmptySourceDir) then
      TDirectory.Delete(EmptySourceDir, True);
    if TDirectory.Exists(EmptyTargetDir) then
      TDirectory.Delete(EmptyTargetDir, True);
  end;
end;

procedure TTestSyncExecution.TestNonExistentSource;
var
  Task: TSyncTask;
begin
  // Arrange
  Task := TSyncTask.CreateWithDatabase(FDatabase);
  try
    Task.Name := 'Non-existent Source Test';
    Task.SourcePath := 'C:\NonExistentPath123456789';
    Task.TargetPath := FTargetDir;
    Task.Mode := smManual;
    
    // Act
    Task.Execute;
    
    // Assert - 目标目录不应该被创建，因为源路径不存在
    // 同步应该失败，不应该复制任何文件
    Assert.AreEqual(0, CountFiles(FTargetDir), '不存在的源路径不应该复制任何文件');
  finally
    Task.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSyncExecution);

end.

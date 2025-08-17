unit TestBackupManager;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, BackupManager, ConfigManager;

type
  TTestBackupManager = class
  public
    class procedure RunAllTests;
    class procedure TestBackupCreation;
    class procedure TestBackupVerification;
    class procedure TestManifestSaveLoad;
  end;

implementation

uses
  Vcl.Dialogs;

class procedure TTestBackupManager.RunAllTests;
begin
  try
    ShowMessage('开始运行备份管理器测试...');
    
    TestBackupCreation;
    ShowMessage('✓ 备份创建测试通过');
    
    TestBackupVerification;
    ShowMessage('✓ 备份验证测试通过');
    
    TestManifestSaveLoad;
    ShowMessage('✓ 清单保存加载测试通过');
    
    ShowMessage('所有备份管理器测试通过！');
  except
    on E: Exception do
      ShowMessage('测试失败: ' + E.Message);
  end;
end;

class procedure TTestBackupManager.TestBackupCreation;
var
  Manager: TBackupManager;
  ConfigManager: TConfigManager;
  TestFile: string;
  BackupId: string;
  TestPaths: TArray<string>;
begin
  ConfigManager := TConfigManager.Create;
  try
    Manager := TBackupManager.Create(ConfigManager);
    try
      TestFile := TPath.Combine(TPath.GetTempPath, 'backup_test.txt');
      TFile.WriteAllText(TestFile, 'Backup test content');
      
      try
        SetLength(TestPaths, 1);
        TestPaths[0] := TestFile;
        
        BackupId := Manager.CreateBackup(TestPaths, 'Test backup');
        
        if Length(BackupId) = 0 then
          raise Exception.Create('备份创建失败');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Manager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestBackupManager.TestBackupVerification;
var
  Manager: TBackupManager;
  ConfigManager: TConfigManager;
begin
  ConfigManager := TConfigManager.Create;
  try
    Manager := TBackupManager.Create(ConfigManager);
    try
      // 简化测试：验证不存在的备份应该失败
      if Manager.VerifyBackup('non_existent_backup') then
        raise Exception.Create('不存在的备份不应该验证通过');
      
    finally
      Manager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestBackupManager.TestManifestSaveLoad;
var
  Manager: TBackupManager;
  ConfigManager: TConfigManager;
  Manifest: TBackupManifest;
  TestFile: string;
  LoadedManifest: TBackupManifest;
begin
  ConfigManager := TConfigManager.Create;
  try
    Manager := TBackupManager.Create(ConfigManager);
    try
      // 创建测试清单
      FillChar(Manifest, SizeOf(Manifest), 0);
      Manifest.BackupId := 'test_manifest';
      Manifest.CreatedTime := Now;
      Manifest.Description := 'Test manifest';
      Manifest.TotalItems := 0;
      Manifest.TotalSize := 0;
      
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_manifest.json');
      
      try
        if not Manager.SaveManifest(Manifest, TestFile) then
          raise Exception.Create('清单保存失败');
        
        LoadedManifest := Manager.LoadManifest(TestFile);
        
        if LoadedManifest.BackupId <> Manifest.BackupId then
          raise Exception.Create('加载的清单ID不匹配');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Manager.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

end.
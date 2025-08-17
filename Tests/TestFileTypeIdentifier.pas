unit TestFileTypeIdentifier;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, FileTypeIdentifier, ConfigManager;

type
  // 文件类型识别器测试类
  TTestFileTypeIdentifier = class
  public
    class procedure RunAllTests;
    class procedure TestExtensionIdentification;
    class procedure TestSystemFileIdentification;
    class procedure TestExecutableFileIdentification;
    class procedure TestConfigFileIdentification;
    class procedure TestTempFileIdentification;
    class procedure TestMediaFileIdentification;
    class procedure TestSourceCodeIdentification;
    class procedure TestFileProperties;
  end;

implementation

uses
  Vcl.Dialogs, Vcl.Forms;

class procedure TTestFileTypeIdentifier.RunAllTests;
begin
  try
    ShowMessage('开始运行文件类型识别器测试...');
    
    TestExtensionIdentification;
    ShowMessage('✓ 扩展名识别测试通过');
    
    TestSystemFileIdentification;
    ShowMessage('✓ 系统文件识别测试通过');
    
    TestExecutableFileIdentification;
    ShowMessage('✓ 可执行文件识别测试通过');
    
    TestConfigFileIdentification;
    ShowMessage('✓ 配置文件识别测试通过');
    
    TestTempFileIdentification;
    ShowMessage('✓ 临时文件识别测试通过');
    
    TestMediaFileIdentification;
    ShowMessage('✓ 媒体文件识别测试通过');
    
    TestSourceCodeIdentification;
    ShowMessage('✓ 源代码识别测试通过');
    
    TestFileProperties;
    ShowMessage('✓ 文件属性测试通过');
    
    ShowMessage('所有文件类型识别器测试通过！');
  except
    on E: Exception do
      ShowMessage('测试失败: ' + E.Message);
  end;
end;

class procedure TTestFileTypeIdentifier.TestExtensionIdentification;
var
  Identifier: TFileTypeIdentifier;
  ConfigManager: TConfigManager;
  TestFile: string;
  Result: TFileIdentificationResult;
begin
  ConfigManager := TConfigManager.Create;
  try
    Identifier := TFileTypeIdentifier.Create(ConfigManager);
    try
      // 测试可执行文件扩展名
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_file.exe');
      TFile.WriteAllText(TestFile, 'test executable content');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftExecutable then
          raise Exception.Create('EXE文件类型识别错误');
        
        if not Result.IsExecutable then
          raise Exception.Create('EXE文件应该标记为可执行');
        
        if Result.Confidence < 50 then
          raise Exception.Create('识别置信度过低');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
      // 测试DLL文件扩展名
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_file.dll');
      TFile.WriteAllText(TestFile, 'test library content');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftLibrary then
          raise Exception.Create('DLL文件类型识别错误');
        
        if Result.Category <> fcSystem then
          raise Exception.Create('DLL文件类别识别错误');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
      // 测试临时文件扩展名
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_file.tmp');
      TFile.WriteAllText(TestFile, 'test temp content');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftTempFile then
          raise Exception.Create('TMP文件类型识别错误');
        
        if not Result.IsSafeToDelete then
          raise Exception.Create('临时文件应该标记为可安全删除');
        
        if Result.Category <> fcTemp then
          raise Exception.Create('临时文件类别识别错误');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Identifier.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestFileTypeIdentifier.TestSystemFileIdentification;
var
  Identifier: TFileTypeIdentifier;
  ConfigManager: TConfigManager;
  TestFile: string;
  Result: TFileIdentificationResult;
begin
  ConfigManager := TConfigManager.Create;
  try
    Identifier := TFileTypeIdentifier.Create(ConfigManager);
    try
      // 测试系统DLL文件
      TestFile := GetEnvironmentVariable('WINDIR') + '\System32\kernel32.dll';
      if FileExists(TestFile) then
      begin
        Result := Identifier.IdentifyFile(TestFile);
        
        if not Result.IsSystemFile then
          raise Exception.Create('系统文件应该标记为系统文件');
        
        if Result.IsSafeToDelete then
          raise Exception.Create('系统文件不应该标记为可安全删除');
        
        if Result.Importance <> fiCritical then
          raise Exception.Create('系统文件应该是严重重要性级别');
        
        if not Result.RequiresBackup then
          raise Exception.Create('系统文件应该需要备份');
      end;
      
      // 测试系统可执行文件
      TestFile := GetEnvironmentVariable('WINDIR') + '\System32\notepad.exe';
      if FileExists(TestFile) then
      begin
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftExecutable then
          raise Exception.Create('记事本应该识别为可执行文件');
        
        if not Result.IsSystemFile then
          raise Exception.Create('系统目录中的文件应该标记为系统文件');
        
        if not Result.IsExecutable then
          raise Exception.Create('EXE文件应该标记为可执行');
      end;
      
    finally
      Identifier.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestFileTypeIdentifier.TestExecutableFileIdentification;
var
  Identifier: TFileTypeIdentifier;
  ConfigManager: TConfigManager;
  TestFile: string;
  Result: TFileIdentificationResult;
begin
  ConfigManager := TConfigManager.Create;
  try
    Identifier := TFileTypeIdentifier.Create(ConfigManager);
    try
      // 测试EXE文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_executable.exe');
      TFile.WriteAllText(TestFile, 'test executable content');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftExecutable then
          raise Exception.Create('EXE文件类型识别错误');
        
        if Result.Category <> fcApplication then
          raise Exception.Create('可执行文件类别应该是应用程序');
        
        if not Result.IsExecutable then
          raise Exception.Create('EXE文件应该标记为可执行');
        
        if not Result.RequiresBackup then
          raise Exception.Create('可执行文件应该需要备份');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
      // 测试MSI安装程序
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_installer.msi');
      TFile.WriteAllText(TestFile, 'test installer content');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftInstaller then
          raise Exception.Create('MSI文件类型识别错误');
        
        if not Result.IsExecutable then
          raise Exception.Create('安装程序应该标记为可执行');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
      // 测试批处理文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_batch.bat');
      TFile.WriteAllText(TestFile, '@echo off' + sLineBreak + 'echo test');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftExecutable then
          raise Exception.Create('BAT文件类型识别错误');
        
        if not Result.IsExecutable then
          raise Exception.Create('批处理文件应该标记为可执行');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Identifier.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;cla
ss procedure TTestFileTypeIdentifier.TestConfigFileIdentification;
var
  Identifier: TFileTypeIdentifier;
  ConfigManager: TConfigManager;
  TestFile: string;
  Result: TFileIdentificationResult;
begin
  ConfigManager := TConfigManager.Create;
  try
    Identifier := TFileTypeIdentifier.Create(ConfigManager);
    try
      // 测试INI配置文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_config.ini');
      TFile.WriteAllText(TestFile, '[Settings]' + sLineBreak + 'Key=Value');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftConfigFile then
          raise Exception.Create('INI文件类型识别错误');
        
        if Result.Category <> fcData then
          raise Exception.Create('配置文件类别应该是数据');
        
        if Result.IsSafeToDelete then
          raise Exception.Create('配置文件不应该标记为可安全删除');
        
        if not Result.RequiresBackup then
          raise Exception.Create('配置文件应该需要备份');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
      // 测试XML配置文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_config.xml');
      TFile.WriteAllText(TestFile, '<?xml version="1.0"?><config></config>');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftConfigFile then
          raise Exception.Create('XML文件类型识别错误');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
      // 测试JSON配置文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_config.json');
      TFile.WriteAllText(TestFile, '{"setting": "value"}');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftConfigFile then
          raise Exception.Create('JSON文件类型识别错误');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Identifier.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestFileTypeIdentifier.TestTempFileIdentification;
var
  Identifier: TFileTypeIdentifier;
  ConfigManager: TConfigManager;
  TestFile: string;
  Result: TFileIdentificationResult;
begin
  ConfigManager := TConfigManager.Create;
  try
    Identifier := TFileTypeIdentifier.Create(ConfigManager);
    try
      // 测试TMP临时文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_temp.tmp');
      TFile.WriteAllText(TestFile, 'temporary content');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftTempFile then
          raise Exception.Create('TMP文件类型识别错误');
        
        if Result.Category <> fcTemp then
          raise Exception.Create('临时文件类别识别错误');
        
        if not Result.IsSafeToDelete then
          raise Exception.Create('临时文件应该标记为可安全删除');
        
        if Result.RequiresBackup then
          raise Exception.Create('临时文件不应该需要备份');
        
        if Result.Importance <> fiLow then
          raise Exception.Create('临时文件重要性应该是低');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
      // 测试备份文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_backup.bak');
      TFile.WriteAllText(TestFile, 'backup content');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftBackupFile then
          raise Exception.Create('BAK文件类型识别错误');
        
        if not Result.IsSafeToDelete then
          raise Exception.Create('备份文件应该标记为可安全删除');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
      // 测试日志文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_log.log');
      TFile.WriteAllText(TestFile, '2024-01-01 12:00:00 - Log entry');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftLogFile then
          raise Exception.Create('LOG文件类型识别错误');
        
        if not Result.IsSafeToDelete then
          raise Exception.Create('日志文件应该标记为可安全删除');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Identifier.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestFileTypeIdentifier.TestMediaFileIdentification;
var
  Identifier: TFileTypeIdentifier;
  ConfigManager: TConfigManager;
  TestFile: string;
  Result: TFileIdentificationResult;
begin
  ConfigManager := TConfigManager.Create;
  try
    Identifier := TFileTypeIdentifier.Create(ConfigManager);
    try
      // 测试图像文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_image.jpg');
      TFile.WriteAllText(TestFile, 'fake image content');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftImage then
          raise Exception.Create('JPG文件类型识别错误');
        
        if Result.Category <> fcMedia then
          raise Exception.Create('图像文件类别应该是媒体');
        
        if Result.IsSafeToDelete then
          raise Exception.Create('图像文件不应该标记为可安全删除');
        
        if not Result.RequiresBackup then
          raise Exception.Create('图像文件应该需要备份');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
      // 测试音频文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_audio.mp3');
      TFile.WriteAllText(TestFile, 'fake audio content');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftAudio then
          raise Exception.Create('MP3文件类型识别错误');
        
        if Result.Category <> fcMedia then
          raise Exception.Create('音频文件类别应该是媒体');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
      // 测试视频文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_video.mp4');
      TFile.WriteAllText(TestFile, 'fake video content');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftVideo then
          raise Exception.Create('MP4文件类型识别错误');
        
        if Result.Category <> fcMedia then
          raise Exception.Create('视频文件类别应该是媒体');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Identifier.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestFileTypeIdentifier.TestSourceCodeIdentification;
var
  Identifier: TFileTypeIdentifier;
  ConfigManager: TConfigManager;
  TestFile: string;
  Result: TFileIdentificationResult;
begin
  ConfigManager := TConfigManager.Create;
  try
    Identifier := TFileTypeIdentifier.Create(ConfigManager);
    try
      // 测试Pascal源代码
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_source.pas');
      TFile.WriteAllText(TestFile, 'unit TestUnit;' + sLineBreak + 'interface' + sLineBreak + 'implementation' + sLineBreak + 'end.');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftSource then
          raise Exception.Create('PAS文件类型识别错误');
        
        if Result.Category <> fcDevelopment then
          raise Exception.Create('源代码文件类别应该是开发');
        
        if Result.IsSafeToDelete then
          raise Exception.Create('源代码文件不应该标记为可安全删除');
        
        if not Result.RequiresBackup then
          raise Exception.Create('源代码文件应该需要备份');
        
        if Result.Importance <> fiHigh then
          raise Exception.Create('源代码文件重要性应该是高');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
      // 测试脚本文件
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_script.js');
      TFile.WriteAllText(TestFile, 'function test() { console.log("test"); }');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftScript then
          raise Exception.Create('JS文件类型识别错误');
        
        if Result.Category <> fcDevelopment then
          raise Exception.Create('脚本文件类别应该是开发');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
      // 测试Python脚本
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_script.py');
      TFile.WriteAllText(TestFile, 'print("Hello, World!")');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if Result.FileType <> ftScript then
          raise Exception.Create('PY文件类型识别错误');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
      
    finally
      Identifier.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

class procedure TTestFileTypeIdentifier.TestFileProperties;
var
  Identifier: TFileTypeIdentifier;
  ConfigManager: TConfigManager;
  TestFile: string;
  Result: TFileIdentificationResult;
begin
  ConfigManager := TConfigManager.Create;
  try
    Identifier := TFileTypeIdentifier.Create(ConfigManager);
    try
      // 测试文件属性获取
      TestFile := TPath.Combine(TPath.GetTempPath, 'test_properties.txt');
      TFile.WriteAllText(TestFile, 'test content for properties');
      try
        Result := Identifier.IdentifyFile(TestFile);
        
        if not Assigned(Result.Properties) then
          raise Exception.Create('文件属性字典未创建');
        
        if not Result.Properties.ContainsKey('Size') then
          raise Exception.Create('文件大小属性缺失');
        
        if not Result.Properties.ContainsKey('Modified') then
          raise Exception.Create('修改时间属性缺失');
        
        var FileSize := StrToIntDef(Result.Properties['Size'], -1);
        if FileSize <= 0 then
          raise Exception.Create('文件大小属性值异常');
        
        if Length(Result.DetectionMethods) = 0 then
          raise Exception.Create('检测方法信息缺失');
        
        if Result.Confidence <= 0 then
          raise Exception.Create('识别置信度应该大于0');
        
        if Length(Result.Description) = 0 then
          raise Exception.Create('文件描述缺失');
        
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
        if Assigned(Result.Properties) then
          Result.Properties.Free;
      end;
      
      // 测试不存在文件的处理
      TestFile := TPath.Combine(TPath.GetTempPath, 'non_existent_file.txt');
      Result := Identifier.IdentifyFile(TestFile);
      
      if Result.FileType <> ftUnknown then
        raise Exception.Create('不存在的文件应该返回未知类型');
      
      if not ContainsText(Result.Description, '不存在') then
        raise Exception.Create('不存在文件的描述应该包含"不存在"');
      
      if Assigned(Result.Properties) then
        Result.Properties.Free;
      
    finally
      Identifier.Free;
    end;
  finally
    ConfigManager.Free;
  end;
end;

end.
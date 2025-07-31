unit TestFileClassificationSystem;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, FileClassificationSystem;

type
  // 文件分类系统测试类
  TTestFileClassificationSystem = class
  public
    class procedure RunAllTests;
    class procedure TestExtensionBasedClassification;
    class procedure TestPathBasedClassification;
    class procedure TestFileNameBasedClassification;
    class procedure TestComprehensiveClassification;
    class procedure TestSafetyAttributes;
    class procedure TestCategoryConversion;
  end;

implementation

uses
  Vcl.Dialogs, Vcl.Forms;

class procedure TTestFileClassificationSystem.RunAllTests;
begin
  try
    ShowMessage('开始运行文件分类系统测试...');
    
    TestExtensionBasedClassification;
    ShowMessage('✓ 扩展名分类测试通过');
    
    TestPathBasedClassification;
    ShowMessage('✓ 路径分类测试通过');
    
    TestFileNameBasedClassification;
    ShowMessage('✓ 文件名分类测试通过');
    
    TestComprehensiveClassification;
    ShowMessage('✓ 综合分类测试通过');
    
    TestSafetyAttributes;
    ShowMessage('✓ 安全属性测试通过');
    
    TestCategoryConversion;
    ShowMessage('✓ 分类转换测试通过');
    
    ShowMessage('所有文件分类系统测试通过！');
  except
    on E: Exception do
      ShowMessage('测试失败: ' + E.Message);
  end;
end;

class procedure TTestFileClassificationSystem.TestExtensionBasedClassification;
var
  Classifier: TFileClassificationSystem;
  TestFile: string;
  Result: TFileClassificationResult;
  FileStream: TFileStream;
begin
  Classifier := TFileClassificationSystem.Create;
  try
    // 测试系统文件扩展名
    TestFile := TPath.GetTempPath + 'test_system.dll';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('测试DLL文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Result := Classifier.ClassifyFile(TestFile);
      if Result.Category <> fcSystemFile then
        raise Exception.Create('DLL文件分类错误');
      
      if Result.Confidence <= 0 then
        raise Exception.Create('分类置信度应该大于0');
        
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
    // 测试程序文件扩展名
    TestFile := TPath.GetTempPath + 'test_program.exe';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('测试EXE文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Result := Classifier.ClassifyFile(TestFile);
      if Result.Category <> fcProgramFile then
        raise Exception.Create('EXE文件分类错误');
        
      if Result.SubCategory <> fscExecutable then
        raise Exception.Create('EXE文件子分类错误');
        
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
    // 测试用户文档扩展名
    TestFile := TPath.GetTempPath + 'test_document.docx';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('测试文档文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Result := Classifier.ClassifyFile(TestFile);
      if Result.Category <> fcUserDocument then
        raise Exception.Create('DOCX文件分类错误');
        
      if Result.SubCategory <> fscTextDocument then
        raise Exception.Create('DOCX文件子分类错误');
        
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
    // 测试媒体文件扩展名
    TestFile := TPath.GetTempPath + 'test_image.jpg';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('测试图片文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Result := Classifier.ClassifyFile(TestFile);
      if Result.Category <> fcMediaFile then
        raise Exception.Create('JPG文件分类错误');
        
      if Result.SubCategory <> fscImage then
        raise Exception.Create('JPG文件子分类错误');
        
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
    // 测试临时文件扩展名
    TestFile := TPath.GetTempPath + 'test_temp.tmp';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('测试临时文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Result := Classifier.ClassifyFile(TestFile);
      if Result.Category <> fcTemporaryFile then
        raise Exception.Create('TMP文件分类错误');
        
      if Result.SubCategory <> fscTempFile then
        raise Exception.Create('TMP文件子分类错误');
        
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
  finally
    Classifier.Free;
  end;
end;cla
ss procedure TTestFileClassificationSystem.TestPathBasedClassification;
var
  Classifier: TFileClassificationSystem;
  TestFile: string;
  Result: TFileClassificationResult;
  TempDir: string;
  FileStream: TFileStream;
begin
  Classifier := TFileClassificationSystem.Create;
  try
    // 测试临时目录中的文件
    TempDir := GetEnvironmentVariable('TEMP');
    TestFile := TempDir + '\path_test_file.txt';
    
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('路径测试文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Result := Classifier.ClassifyFile(TestFile);
      // 临时目录中的文件应该被分类为临时文件
      if Result.Category <> fcTemporaryFile then
        raise Exception.Create('临时目录中的文件分类错误');
        
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
    // 测试用户文档目录中的文件
    var UserProfile := GetEnvironmentVariable('USERPROFILE');
    var DocumentsDir := UserProfile + '\Documents';
    
    if DirectoryExists(DocumentsDir) then
    begin
      TestFile := DocumentsDir + '\path_test_document.txt';
      
      FileStream := TFileStream.Create(TestFile, fmCreate);
      try
        var TestData := TEncoding.UTF8.GetBytes('文档测试文件');
        FileStream.WriteBuffer(TestData[0], Length(TestData));
      finally
        FileStream.Free;
      end;
      
      try
        Result := Classifier.ClassifyFile(TestFile);
        // 文档目录中的文件应该被分类为用户文档
        if Result.Category <> fcUserDocument then
          raise Exception.Create('文档目录中的文件分类错误');
          
      finally
        if FileExists(TestFile) then
          DeleteFile(TestFile);
      end;
    end;
    
    // 测试系统目录中的文件（如果存在）
    var SystemFile := GetEnvironmentVariable('WINDIR') + '\System32\kernel32.dll';
    if FileExists(SystemFile) then
    begin
      Result := Classifier.ClassifyFile(SystemFile);
      if Result.Category <> fcSystemFile then
        raise Exception.Create('系统目录中的文件分类错误');
    end;
    
  finally
    Classifier.Free;
  end;
end;

class procedure TTestFileClassificationSystem.TestFileNameBasedClassification;
var
  Classifier: TFileClassificationSystem;
  TestFile: string;
  Result: TFileClassificationResult;
  FileStream: TFileStream;
begin
  Classifier := TFileClassificationSystem.Create;
  try
    // 测试以~开头的临时文件
    TestFile := TPath.GetTempPath + '~temp_file.txt';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('临时文件内容');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Result := Classifier.ClassifyFile(TestFile);
      if Result.Category <> fcTemporaryFile then
        raise Exception.Create('以~开头的文件应该被分类为临时文件');
        
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
    // 测试包含temp的文件名
    TestFile := TPath.GetTempPath + 'my_temp_data.dat';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('临时数据文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Result := Classifier.ClassifyFile(TestFile);
      if Result.Category <> fcTemporaryFile then
        raise Exception.Create('包含temp的文件名应该被分类为临时文件');
        
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
    // 测试包含cache的文件名
    TestFile := TPath.GetTempPath + 'app_cache_data.dat';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('缓存数据文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Result := Classifier.ClassifyFile(TestFile);
      if Result.Category <> fcCacheFile then
        raise Exception.Create('包含cache的文件名应该被分类为缓存文件');
        
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
    // 测试包含log的文件名
    TestFile := TPath.GetTempPath + 'application_log.txt';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('日志文件内容');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Result := Classifier.ClassifyFile(TestFile);
      if Result.Category <> fcLogFile then
        raise Exception.Create('包含log的文件名应该被分类为日志文件');
        
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
    // 测试包含backup的文件名
    TestFile := TPath.GetTempPath + 'data_backup.dat';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('备份文件内容');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Result := Classifier.ClassifyFile(TestFile);
      if Result.Category <> fcBackupFile then
        raise Exception.Create('包含backup的文件名应该被分类为备份文件');
        
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
  finally
    Classifier.Free;
  end;
end;cl
ass procedure TTestFileClassificationSystem.TestComprehensiveClassification;
var
  Classifier: TFileClassificationSystem;
  TestFile: string;
  Result: TFileClassificationResult;
  FileStream: TFileStream;
begin
  Classifier := TFileClassificationSystem.Create;
  try
    // 测试综合分类：临时目录中的.tmp文件
    TestFile := GetEnvironmentVariable('TEMP') + '\comprehensive_test.tmp';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('综合测试文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Result := Classifier.ClassifyFile(TestFile);
      
      // 应该被分类为临时文件
      if Result.Category <> fcTemporaryFile then
        raise Exception.Create('综合分类测试失败：分类错误');
      
      // 置信度应该较高（扩展名+路径双重确认）
      if Result.Confidence < 70 then
        raise Exception.Create('综合分类测试失败：置信度过低');
      
      // 应该有描述信息
      if Trim(Result.Description) = '' then
        raise Exception.Create('综合分类测试失败：缺少描述信息');
      
      // 应该有标签
      if Length(Result.Tags) = 0 then
        raise Exception.Create('综合分类测试失败：缺少标签');
      
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
    // 测试不存在的文件
    TestFile := 'C:\NonExistentFile.xyz';
    Result := Classifier.ClassifyFile(TestFile);
    
    if Result.Category <> fcUnknown then
      raise Exception.Create('不存在的文件应该返回未知分类');
    
    if not ContainsText(Result.Description, '不存在') then
      raise Exception.Create('不存在的文件应该有相应的描述');
    
    // 测试无扩展名文件
    TestFile := TPath.GetTempPath + 'no_extension_file';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('无扩展名文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Result := Classifier.ClassifyFile(TestFile);
      
      // 应该基于路径分类为临时文件
      if Result.Category <> fcTemporaryFile then
        raise Exception.Create('无扩展名文件分类错误');
      
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
  finally
    Classifier.Free;
  end;
end;

class procedure TTestFileClassificationSystem.TestSafetyAttributes;
var
  Classifier: TFileClassificationSystem;
  TestFile: string;
  Result: TFileClassificationResult;
  FileStream: TFileStream;
begin
  Classifier := TFileClassificationSystem.Create;
  try
    // 测试系统文件的安全属性
    TestFile := TPath.GetTempPath + 'test_system.dll';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('测试系统文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Result := Classifier.ClassifyFile(TestFile);
      
      // 系统文件不应该允许删除和移动
      if Result.SafeToDelete then
        raise Exception.Create('系统文件不应该允许删除');
      
      if Result.SafeToMove then
        raise Exception.Create('系统文件不应该允许移动');
      
      if not Result.RequiresBackup then
        raise Exception.Create('系统文件应该需要备份');
        
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
    // 测试临时文件的安全属性
    TestFile := TPath.GetTempPath + 'test_temp.tmp';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('测试临时文件');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Result := Classifier.ClassifyFile(TestFile);
      
      // 临时文件应该允许删除和移动
      if not Result.SafeToDelete then
        raise Exception.Create('临时文件应该允许删除');
      
      if not Result.SafeToMove then
        raise Exception.Create('临时文件应该允许移动');
      
      if Result.RequiresBackup then
        raise Exception.Create('临时文件不应该需要备份');
        
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
    // 测试用户文档的安全属性
    TestFile := TPath.GetTempPath + 'test_document.docx';
    FileStream := TFileStream.Create(TestFile, fmCreate);
    try
      var TestData := TEncoding.UTF8.GetBytes('测试用户文档');
      FileStream.WriteBuffer(TestData[0], Length(TestData));
    finally
      FileStream.Free;
    end;
    
    try
      Result := Classifier.ClassifyFile(TestFile);
      
      // 用户文档应该允许删除和移动，但需要备份
      if not Result.SafeToDelete then
        raise Exception.Create('用户文档应该允许删除');
      
      if not Result.SafeToMove then
        raise Exception.Create('用户文档应该允许移动');
      
      if not Result.RequiresBackup then
        raise Exception.Create('用户文档应该需要备份');
        
    finally
      if FileExists(TestFile) then
        DeleteFile(TestFile);
    end;
    
  finally
    Classifier.Free;
  end;
end;

class procedure TTestFileClassificationSystem.TestCategoryConversion;
begin
  // 测试分类转换为字符串
  if TFileClassificationSystem.CategoryToString(fcSystemFile) <> '系统文件' then
    raise Exception.Create('系统文件分类转换错误');
  
  if TFileClassificationSystem.CategoryToString(fcProgramFile) <> '程序文件' then
    raise Exception.Create('程序文件分类转换错误');
  
  if TFileClassificationSystem.CategoryToString(fcUserDocument) <> '用户文档' then
    raise Exception.Create('用户文档分类转换错误');
  
  if TFileClassificationSystem.CategoryToString(fcMediaFile) <> '媒体文件' then
    raise Exception.Create('媒体文件分类转换错误');
  
  if TFileClassificationSystem.CategoryToString(fcTemporaryFile) <> '临时文件' then
    raise Exception.Create('临时文件分类转换错误');
  
  if TFileClassificationSystem.CategoryToString(fcCacheFile) <> '缓存文件' then
    raise Exception.Create('缓存文件分类转换错误');
  
  if TFileClassificationSystem.CategoryToString(fcLogFile) <> '日志文件' then
    raise Exception.Create('日志文件分类转换错误');
  
  if TFileClassificationSystem.CategoryToString(fcBackupFile) <> '备份文件' then
    raise Exception.Create('备份文件分类转换错误');
  
  if TFileClassificationSystem.CategoryToString(fcConfigFile) <> '配置文件' then
    raise Exception.Create('配置文件分类转换错误');
  
  if TFileClassificationSystem.CategoryToString(fcDatabaseFile) <> '数据库文件' then
    raise Exception.Create('数据库文件分类转换错误');
  
  if TFileClassificationSystem.CategoryToString(fcArchiveFile) <> '压缩文件' then
    raise Exception.Create('压缩文件分类转换错误');
  
  if TFileClassificationSystem.CategoryToString(fcDevelopmentFile) <> '开发文件' then
    raise Exception.Create('开发文件分类转换错误');
  
  if TFileClassificationSystem.CategoryToString(fcWebFile) <> '网页文件' then
    raise Exception.Create('网页文件分类转换错误');
  
  if TFileClassificationSystem.CategoryToString(fcFontFile) <> '字体文件' then
    raise Exception.Create('字体文件分类转换错误');
  
  if TFileClassificationSystem.CategoryToString(fcDriverFile) <> '驱动文件' then
    raise Exception.Create('驱动文件分类转换错误');
  
  if TFileClassificationSystem.CategoryToString(fcUnknown) <> '未知类型' then
    raise Exception.Create('未知类型分类转换错误');
end;

end.
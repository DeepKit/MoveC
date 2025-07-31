program CreateCorrectChineseFile;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  System.Classes;

procedure CreateChineseFileWithCorrectEncoding;
var
  JsonObj: TJSONObject;
  JsonText: string;
  FileStream: TFileStream;
  UTF8Bytes: TBytes;
  UTF8BOM: TBytes;
begin
  // 创建JSON对象，直接使用Unicode字符串常量
  JsonObj := TJSONObject.Create;
  try
    // 使用Unicode字符串常量，这些在Delphi中是正确的
    JsonObj.AddPair('app_title', 'C盘超级清理');
    JsonObj.AddPair('app_version', '版本');
    JsonObj.AddPair('menu_file', '文件(&F)');
    JsonObj.AddPair('menu_exit', '退出(&X)');
    JsonObj.AddPair('menu_tools', '工具(&T)');
    JsonObj.AddPair('menu_system_check', '系统检查(&S)');
    JsonObj.AddPair('menu_language', '语言设置(&L)');
    JsonObj.AddPair('menu_help', '帮助(&H)');
    JsonObj.AddPair('menu_about', '关于(&A)');
    JsonObj.AddPair('btn_copy', '复制文件');
    JsonObj.AddPair('btn_delete', '删除并链接');
    JsonObj.AddPair('btn_backup', '创建备份');
    JsonObj.AddPair('btn_cancel', '取消');
    JsonObj.AddPair('btn_ok', '确定');
    JsonObj.AddPair('btn_yes', '是');
    JsonObj.AddPair('btn_no', '否');
    JsonObj.AddPair('btn_close', '关闭');
    JsonObj.AddPair('tab_backup', '备份管理');
    JsonObj.AddPair('tab_about', '关于开发者');
    JsonObj.AddPair('status_ready', '就绪');
    JsonObj.AddPair('status_copying', '正在复制...');
    JsonObj.AddPair('status_complete', '操作完成');
    JsonObj.AddPair('progress_title', '操作进度');
    JsonObj.AddPair('confirm_delete', '确定要删除选中的文件吗？');
    JsonObj.AddPair('language_changed', '语言设置已更改，部分界面将在重启后生效。');
    JsonObj.AddPair('donation_title', '支持开发者');
    JsonObj.AddPair('machine_code', '机器码');
    
    // 格式化JSON
    JsonText := JsonObj.Format;
    
    // 方法1: 使用TFile.WriteAllText with UTF8
    TFile.WriteAllText('Languages\zh-CN-method1.json', JsonText, TEncoding.UTF8);
    
    // 方法2: 手动写入UTF-8 BOM + 内容
    FileStream := TFileStream.Create('Languages\zh-CN-method2.json', fmCreate);
    try
      // 写入UTF-8 BOM
      UTF8BOM := TEncoding.UTF8.GetPreamble;
      FileStream.WriteBuffer(UTF8BOM[0], Length(UTF8BOM));
      
      // 转换为UTF-8字节并写入
      UTF8Bytes := TEncoding.UTF8.GetBytes(JsonText);
      FileStream.WriteBuffer(UTF8Bytes[0], Length(UTF8Bytes));
    finally
      FileStream.Free;
    end;
    
    // 方法3: 使用TStringList
    var StringList: TStringList;
    StringList := TStringList.Create;
    try
      StringList.Text := JsonText;
      StringList.SaveToFile('Languages\zh-CN-method3.json', TEncoding.UTF8);
    finally
      StringList.Free;
    end;
    
    Writeln('已创建三个测试文件:');
    Writeln('- zh-CN-method1.json (TFile.WriteAllText)');
    Writeln('- zh-CN-method2.json (FileStream + BOM)');
    Writeln('- zh-CN-method3.json (TStringList)');
    
  finally
    JsonObj.Free;
  end;
end;

procedure TestReadFiles;
var
  Content1, Content2, Content3: string;
begin
  Writeln('');
  Writeln('测试读取文件内容:');
  
  try
    Content1 := TFile.ReadAllText('Languages\zh-CN-method1.json', TEncoding.UTF8);
    Writeln('Method 1 读取成功');
  except
    on E: Exception do
      Writeln('Method 1 读取失败: ' + E.Message);
  end;
  
  try
    Content2 := TFile.ReadAllText('Languages\zh-CN-method2.json', TEncoding.UTF8);
    Writeln('Method 2 读取成功');
  except
    on E: Exception do
      Writeln('Method 2 读取失败: ' + E.Message);
  end;
  
  try
    Content3 := TFile.ReadAllText('Languages\zh-CN-method3.json', TEncoding.UTF8);
    Writeln('Method 3 读取成功');
  except
    on E: Exception do
      Writeln('Method 3 读取失败: ' + E.Message);
  end;
end;

begin
  try
    Writeln('=== 创建正确编码的中文文件 ===');
    
    // 确保目录存在
    if not TDirectory.Exists('Languages') then
      TDirectory.CreateDirectory('Languages');
    
    CreateChineseFileWithCorrectEncoding;
    TestReadFiles;
    
    Writeln('');
    Writeln('请检查生成的文件，选择显示正确的版本。');
    
  except
    on E: Exception do
      Writeln('错误: ' + E.Message);
  end;
  
  Writeln('');
  Writeln('按任意键退出...');
  Readln;
end.

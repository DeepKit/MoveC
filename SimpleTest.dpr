program SimpleTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.IniFiles;

var
  IniFile: TMemIniFile;
  TestValue: string;
  ReadValue: string;
begin
  try
    Writeln('Simple Chinese Test');
    Writeln('==================');
    
    // 测试1: 直接输出中文
    Writeln('Test 1: Direct Chinese output');
    Writeln('Chinese text: 中文测试');
    Writeln('');
    
    // 测试2: 使用Unicode转义
    Writeln('Test 2: Unicode escape sequences');
    TestValue := #$4E2D#$6587#$6D4B#$8BD5;  // 中文测试
    Writeln('Unicode text: ' + TestValue);
    Writeln('');
    
    // 测试3: INI文件操作
    Writeln('Test 3: INI file operations');
    IniFile := TMemIniFile.Create('simple_test.ini', TEncoding.UTF8);
    try
      // 写入
      IniFile.WriteString('Test', 'unicode_value', TestValue);
      IniFile.WriteString('Test', 'direct_value', '直接中文');
      IniFile.UpdateFile;
      
      // 读取
      ReadValue := IniFile.ReadString('Test', 'unicode_value', '');
      Writeln('Written (Unicode): ' + TestValue);
      Writeln('Read (Unicode): ' + ReadValue);
      Writeln('Match: ' + BoolToStr(ReadValue = TestValue, True));
      
    finally
      IniFile.Free;
    end;
    
    Writeln('');
    Writeln('Check the generated simple_test.ini file');
    
  except
    on E: Exception do
      Writeln('Error: ' + E.Message);
  end;
  
  Writeln('');
  Writeln('Press Enter to exit...');
  Readln;
end.

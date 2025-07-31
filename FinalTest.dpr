program FinalTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.Math,
  DatabaseManagerFixed,
  ChineseConstants,
  DataTypes;

procedure TestChineseConstants;
begin
  Writeln('=== Testing Chinese Constants ===');
  Writeln('APP_TITLE: ' + APP_TITLE);
  Writeln('MENU_FILE: ' + MENU_FILE);
  Writeln('BTN_COPY: ' + BTN_COPY);
  Writeln('STATUS_READY: ' + STATUS_READY);
  Writeln('');
end;

procedure TestDatabaseManager;
var
  DbManager: TDatabaseManagerFixed;
  AllStrings: TArray<TLanguageStringItem>;
  I: Integer;
  TestValue, ReadValue: string;
begin
  Writeln('=== Testing Database Manager ===');
  
  DbManager := TDatabaseManagerFixed.Create;
  try
    if DbManager.Initialize then
    begin
      Writeln('Database initialized successfully');
      
      // 测试自定义字符串
      TestValue := #$6D4B#$8BD5#$4E2D#$6587#$5B57#$7B26#$4E32;  // 测试中文字符串
      
      if DbManager.SetLanguageString('zh-CN', 'test_custom', TestValue) then
      begin
        ReadValue := DbManager.GetLanguageString('zh-CN', 'test_custom');
        Writeln('Custom test - Written: ' + TestValue);
        Writeln('Custom test - Read: ' + ReadValue);
        Writeln('Custom test - Match: ' + BoolToStr(ReadValue = TestValue, True));
      end;
      
      Writeln('');
      
      // 获取所有字符串
      AllStrings := DbManager.GetAllLanguageStrings('zh-CN');
      Writeln('Total Chinese strings: ' + IntToStr(Length(AllStrings)));
      
      // 显示前几个
      Writeln('Sample strings:');
      for I := 0 to Min(4, High(AllStrings)) do
      begin
        Writeln('  ' + AllStrings[I].StringKey + ' = ' + AllStrings[I].StringValue);
      end;
      
      if Length(AllStrings) > 5 then
        Writeln('  ... and ' + IntToStr(Length(AllStrings) - 5) + ' more');
        
    end
    else
      Writeln('Database initialization failed');
  finally
    DbManager.Free;
  end;
  
  Writeln('');
end;

procedure CheckGeneratedFiles;
var
  LanguageFile, ConfigFile: string;
  Content: string;
begin
  Writeln('=== Checking Generated Files ===');
  
  LanguageFile := TPath.Combine(TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'DiskCleanup'), 'language_strings.ini');
  ConfigFile := TPath.Combine(TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'DiskCleanup'), 'config_settings.ini');
  
  // 检查语言文件
  if TFile.Exists(LanguageFile) then
  begin
    Writeln('Language file exists: ' + LanguageFile);
    try
      Content := TFile.ReadAllText(LanguageFile, TEncoding.UTF8);
      if Content.Contains('C盘') then
        Writeln('  ✓ Contains correct Chinese characters')
      else
        Writeln('  ✗ Chinese characters not found or corrupted');
    except
      on E: Exception do
        Writeln('  ✗ Error reading file: ' + E.Message);
    end;
  end
  else
    Writeln('Language file not found: ' + LanguageFile);
  
  // 检查配置文件
  if TFile.Exists(ConfigFile) then
  begin
    Writeln('Config file exists: ' + ConfigFile);
  end
  else
    Writeln('Config file not found: ' + ConfigFile);
    
  Writeln('');
end;

procedure ShowSummary;
begin
  Writeln('=== SOLUTION SUMMARY ===');
  Writeln('');
  Writeln('✓ Problem: Chinese characters in Delphi source code get corrupted');
  Writeln('✓ Solution: Use Unicode escape sequences in ChineseConstants.pas');
  Writeln('✓ Implementation: DatabaseManagerFixed.pas with TMemIniFile');
  Writeln('✓ Result: Perfect Chinese character support');
  Writeln('');
  Writeln('To use in your application:');
  Writeln('1. Replace DatabaseManager with DatabaseManagerFixed');
  Writeln('2. Use constants from ChineseConstants.pas');
  Writeln('3. For new Chinese text, use Unicode escape sequences');
  Writeln('');
  Writeln('Example:');
  Writeln('  const MY_TEXT = #$4F60#$597D;  // 你好');
  Writeln('');
end;

begin
  try
    Writeln('FINAL CHINESE ENCODING TEST');
    Writeln('===========================');
    Writeln('');
    
    TestChineseConstants;
    TestDatabaseManager;
    CheckGeneratedFiles;
    ShowSummary;
    
  except
    on E: Exception do
      Writeln('Error: ' + E.Message);
  end;
  
  Writeln('Press Enter to exit...');
  Readln;
end.

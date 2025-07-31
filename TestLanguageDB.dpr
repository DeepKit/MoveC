program TestLanguageDB;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Math,
  DatabaseManager in 'Core\DatabaseManager.pas',
  DataTypes in 'Core\DataTypes.pas',
  BasicProtection in 'Core\BasicProtection.pas',
  LanguageManager in 'Core\LanguageManager.pas',
  LanguageTypes in 'Core\LanguageTypes.pas';

var
  LangMgr: TLanguageManager;
  DbMgr: TDatabaseManager;
  
begin
  try
    WriteLn('=== 测试多语言数据库功能 ===');
    
    // 创建数据库管理器
    DbMgr := TDatabaseManager.Create;
    try
      WriteLn('初始化数据库...');
      if DbMgr.Initialize then
        WriteLn('数据库初始化成功')
      else
        WriteLn('数据库初始化失败');
      
      // 测试设置语言字符串
      WriteLn('设置中文字符串...');
      DbMgr.SetLanguageString('zh-CN', 'test_key', '测试中文字符串');
      DbMgr.SetLanguageString('zh-CN', 'app_title', 'C盘超级清理');
      
      // 测试获取语言字符串
      WriteLn('获取中文字符串...');
      WriteLn('test_key: ' + DbMgr.GetLanguageString('zh-CN', 'test_key'));
      WriteLn('app_title: ' + DbMgr.GetLanguageString('zh-CN', 'app_title'));
      
      // 测试语言管理器
      WriteLn('测试语言管理器...');
      LangMgr := TLanguageManager.Create;
      try
        WriteLn('当前语言: ' + LangMgr.GetCurrentLanguageName);
        WriteLn('app_title: ' + LangMgr.GetString('app_title'));
        WriteLn('menu_file: ' + LangMgr.GetString('menu_file'));
        
        // 获取所有语言字符串
        WriteLn('获取所有中文字符串...');
        var StringItems := DbMgr.GetAllLanguageStrings('zh-CN');
        WriteLn('找到 ' + IntToStr(Length(StringItems)) + ' 个字符串');
        
        for var I := 0 to Min(4, High(StringItems)) do
        begin
          WriteLn('  ' + StringItems[I].StringKey + ' = ' + StringItems[I].StringValue);
        end;
        
      finally
        LangMgr.Free;
      end;
      
    finally
      DbMgr.Free;
    end;
    
    WriteLn('=== 测试完成 ===');
    
  except
    on E: Exception do
      WriteLn('错误: ' + E.Message);
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.

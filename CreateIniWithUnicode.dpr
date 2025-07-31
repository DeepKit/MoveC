program CreateIniWithUnicode;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.IniFiles,
  System.Classes,
  System.Math;

procedure CreateCorrectChineseIni;
var
  IniFile: TMemIniFile;
  IniPath: string;
  TestValue: string;
begin
  Writeln('Creating Chinese INI file with Unicode escapes...');
  
  IniPath := 'chinese_correct.ini';
  
  // 删除旧文件
  if TFile.Exists(IniPath) then
    TFile.Delete(IniPath);
  
  IniFile := TMemIniFile.Create(IniPath, TEncoding.UTF8);
  try
    // 使用Unicode转义序列创建中文字符串
    IniFile.WriteString('Chinese', 'app_title', #$0043#$76D8#$8D85#$7EA7#$6E05#$7406);  // C盘超级清理
    IniFile.WriteString('Chinese', 'app_version', #$7248#$672C);  // 版本
    IniFile.WriteString('Chinese', 'menu_file', #$6587#$4EF6#$0028#$0026#$0046#$0029);  // 文件(&F)
    IniFile.WriteString('Chinese', 'menu_exit', #$9000#$51FA#$0028#$0026#$0058#$0029);  // 退出(&X)
    IniFile.WriteString('Chinese', 'menu_tools', #$5DE5#$5177#$0028#$0026#$0054#$0029);  // 工具(&T)
    IniFile.WriteString('Chinese', 'menu_system_check', #$7CFB#$7EDF#$68C0#$67E5#$0028#$0026#$0053#$0029);  // 系统检查(&S)
    IniFile.WriteString('Chinese', 'menu_language', #$8BED#$8A00#$8BBE#$7F6E#$0028#$0026#$004C#$0029);  // 语言设置(&L)
    IniFile.WriteString('Chinese', 'menu_help', #$5E2E#$52A9#$0028#$0026#$0048#$0029);  // 帮助(&H)
    IniFile.WriteString('Chinese', 'menu_about', #$5173#$4E8E#$0028#$0026#$0041#$0029);  // 关于(&A)
    IniFile.WriteString('Chinese', 'btn_copy', #$590D#$5236#$6587#$4EF6);  // 复制文件
    IniFile.WriteString('Chinese', 'btn_delete', #$5220#$9664#$5E76#$94FE#$63A5);  // 删除并链接
    IniFile.WriteString('Chinese', 'btn_backup', #$521B#$5EFA#$5907#$4EFD);  // 创建备份
    IniFile.WriteString('Chinese', 'btn_cancel', #$53D6#$6D88);  // 取消
    IniFile.WriteString('Chinese', 'btn_ok', #$786E#$5B9A);  // 确定
    IniFile.WriteString('Chinese', 'btn_yes', #$662F);  // 是
    IniFile.WriteString('Chinese', 'btn_no', #$5426);  // 否
    IniFile.WriteString('Chinese', 'btn_close', #$5173#$95ED);  // 关闭
    IniFile.WriteString('Chinese', 'tab_backup', #$5907#$4EFD#$7BA1#$7406);  // 备份管理
    IniFile.WriteString('Chinese', 'tab_about', #$5173#$4E8E#$5F00#$53D1#$8005);  // 关于开发者
    IniFile.WriteString('Chinese', 'status_ready', #$5C31#$7EEA);  // 就绪
    IniFile.WriteString('Chinese', 'status_copying', #$6B63#$5728#$590D#$5236#$002E#$002E#$002E);  // 正在复制...
    IniFile.WriteString('Chinese', 'status_complete', #$64CD#$4F5C#$5B8C#$6210);  // 操作完成
    IniFile.WriteString('Chinese', 'progress_title', #$64CD#$4F5C#$8FDB#$5EA6);  // 操作进度
    IniFile.WriteString('Chinese', 'confirm_delete', #$786E#$5B9A#$8981#$5220#$9664#$9009#$4E2D#$7684#$6587#$4EF6#$5417#$FF1F);  // 确定要删除选中的文件吗？
    IniFile.WriteString('Chinese', 'language_changed', #$8BED#$8A00#$8BBE#$7F6E#$5DF2#$66F4#$6539#$FF0C#$90E8#$5206#$754C#$9762#$5C06#$5728#$91CD#$542F#$540E#$751F#$6548#$3002);  // 语言设置已更改，部分界面将在重启后生效。
    IniFile.WriteString('Chinese', 'donation_title', #$652F#$6301#$5F00#$53D1#$8005);  // 支持开发者
    IniFile.WriteString('Chinese', 'machine_code', #$673A#$5668#$7801);  // 机器码
    
    // 保存文件
    IniFile.UpdateFile;
    
    Writeln('Chinese INI file created successfully!');
    
    // 测试读取
    TestValue := IniFile.ReadString('Chinese', 'app_title', '');
    Writeln('App title from INI: ' + TestValue);
    
  finally
    IniFile.Free;
  end;
end;

procedure TestReadingIniFile;
var
  IniFile: TMemIniFile;
  Sections, Keys: TStringList;
  I, J: Integer;
  Value: string;
begin
  Writeln('');
  Writeln('Testing reading from INI file...');
  
  if not TFile.Exists('chinese_correct.ini') then
  begin
    Writeln('INI file not found!');
    Exit;
  end;
  
  IniFile := TMemIniFile.Create('chinese_correct.ini', TEncoding.UTF8);
  Sections := TStringList.Create;
  Keys := TStringList.Create;
  try
    IniFile.ReadSections(Sections);
    
    for I := 0 to Sections.Count - 1 do
    begin
      Writeln('Section: [' + Sections[I] + ']');
      Keys.Clear;
      IniFile.ReadSection(Sections[I], Keys);
      
      for J := 0 to Min(4, Keys.Count - 1) do  // 只显示前5个
      begin
        Value := IniFile.ReadString(Sections[I], Keys[J], '');
        Writeln('  ' + Keys[J] + ' = ' + Value);
      end;
      
      if Keys.Count > 5 then
        Writeln('  ... (and ' + IntToStr(Keys.Count - 5) + ' more)');
    end;
    
  finally
    Keys.Free;
    Sections.Free;
    IniFile.Free;
  end;
end;

procedure CreateJsonToIniConverter;
var
  IniFile: TMemIniFile;
  IniPath: string;
begin
  Writeln('');
  Writeln('Creating JSON to INI converter data...');
  
  IniPath := 'language_strings.ini';
  
  // 删除旧文件
  if TFile.Exists(IniPath) then
    TFile.Delete(IniPath);
  
  IniFile := TMemIniFile.Create(IniPath, TEncoding.UTF8);
  try
    // zh-CN section
    IniFile.WriteString('zh-CN', 'app_title', #$0043#$76D8#$8D85#$7EA7#$6E05#$7406);  // C盘超级清理
    IniFile.WriteString('zh-CN', 'app_version', #$7248#$672C);  // 版本
    IniFile.WriteString('zh-CN', 'menu_file', #$6587#$4EF6#$0028#$0026#$0046#$0029);  // 文件(&F)
    IniFile.WriteString('zh-CN', 'menu_exit', #$9000#$51FA#$0028#$0026#$0058#$0029);  // 退出(&X)
    IniFile.WriteString('zh-CN', 'menu_tools', #$5DE5#$5177#$0028#$0026#$0054#$0029);  // 工具(&T)
    IniFile.WriteString('zh-CN', 'menu_system_check', #$7CFB#$7EDF#$68C0#$67E5#$0028#$0026#$0053#$0029);  // 系统检查(&S)
    IniFile.WriteString('zh-CN', 'menu_language', #$8BED#$8A00#$8BBE#$7F6E#$0028#$0026#$004C#$0029);  // 语言设置(&L)
    IniFile.WriteString('zh-CN', 'menu_help', #$5E2E#$52A9#$0028#$0026#$0048#$0029);  // 帮助(&H)
    IniFile.WriteString('zh-CN', 'menu_about', #$5173#$4E8E#$0028#$0026#$0041#$0029);  // 关于(&A)
    IniFile.WriteString('zh-CN', 'btn_copy', #$590D#$5236#$6587#$4EF6);  // 复制文件
    IniFile.WriteString('zh-CN', 'btn_delete', #$5220#$9664#$5E76#$94FE#$63A5);  // 删除并链接
    IniFile.WriteString('zh-CN', 'btn_backup', #$521B#$5EFA#$5907#$4EFD);  // 创建备份
    IniFile.WriteString('zh-CN', 'btn_cancel', #$53D6#$6D88);  // 取消
    IniFile.WriteString('zh-CN', 'btn_ok', #$786E#$5B9A);  // 确定
    IniFile.WriteString('zh-CN', 'btn_yes', #$662F);  // 是
    IniFile.WriteString('zh-CN', 'btn_no', #$5426);  // 否
    IniFile.WriteString('zh-CN', 'btn_close', #$5173#$95ED);  // 关闭
    IniFile.WriteString('zh-CN', 'tab_backup', #$5907#$4EFD#$7BA1#$7406);  // 备份管理
    IniFile.WriteString('zh-CN', 'tab_about', #$5173#$4E8E#$5F00#$53D1#$8005);  // 关于开发者
    IniFile.WriteString('zh-CN', 'status_ready', #$5C31#$7EEA);  // 就绪
    IniFile.WriteString('zh-CN', 'status_copying', #$6B63#$5728#$590D#$5236#$002E#$002E#$002E);  // 正在复制...
    IniFile.WriteString('zh-CN', 'status_complete', #$64CD#$4F5C#$5B8C#$6210);  // 操作完成
    IniFile.WriteString('zh-CN', 'progress_title', #$64CD#$4F5C#$8FDB#$5EA6);  // 操作进度
    IniFile.WriteString('zh-CN', 'confirm_delete', #$786E#$5B9A#$8981#$5220#$9664#$9009#$4E2D#$7684#$6587#$4EF6#$5417#$FF1F);  // 确定要删除选中的文件吗？
    IniFile.WriteString('zh-CN', 'language_changed', #$8BED#$8A00#$8BBE#$7F6E#$5DF2#$66F4#$6539#$FF0C#$90E8#$5206#$754C#$9762#$5C06#$5728#$91CD#$542F#$540E#$751F#$6548#$3002);  // 语言设置已更改，部分界面将在重启后生效。
    IniFile.WriteString('zh-CN', 'donation_title', #$652F#$6301#$5F00#$53D1#$8005);  // 支持开发者
    IniFile.WriteString('zh-CN', 'machine_code', #$673A#$5668#$7801);  // 机器码
    
    // 保存文件
    IniFile.UpdateFile;
    
    Writeln('Language strings INI file created successfully!');
    
  finally
    IniFile.Free;
  end;
end;

begin
  try
    Writeln('=== Unicode INI File Creator ===');
    Writeln('');
    
    // 创建正确的中文INI文件
    CreateCorrectChineseIni;
    
    // 测试读取
    TestReadingIniFile;
    
    // 创建语言字符串INI文件
    CreateJsonToIniConverter;
    
    Writeln('');
    Writeln('=== All files created successfully! ===');
    Writeln('');
    Writeln('Files created:');
    Writeln('- chinese_correct.ini (demo file)');
    Writeln('- language_strings.ini (for your application)');
    Writeln('');
    Writeln('These files contain properly encoded Chinese text.');
    
  except
    on E: Exception do
      Writeln('Error: ' + E.Message);
  end;
  
  Writeln('');
  Writeln('Press any key to exit...');
  Readln;
end.

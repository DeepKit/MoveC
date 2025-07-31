program FinalChineseFix;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  DatabaseManager,
  DataTypes;

function CreateChineseSimplifiedJSON: string;
var
  JsonObj: TJSONObject;
begin
  JsonObj := TJSONObject.Create;
  try
    JsonObj.AddPair('app_title', #$0043#$76D8#$8D85#$7EA7#$6E05#$7406);  // C盘超级清理
    JsonObj.AddPair('app_version', #$7248#$672C);  // 版本
    JsonObj.AddPair('menu_file', #$6587#$4EF6#$0028#$0026#$0046#$0029);  // 文件(&F)
    JsonObj.AddPair('menu_exit', #$9000#$51FA#$0028#$0026#$0058#$0029);  // 退出(&X)
    JsonObj.AddPair('menu_tools', #$5DE5#$5177#$0028#$0026#$0054#$0029);  // 工具(&T)
    JsonObj.AddPair('menu_system_check', #$7CFB#$7EDF#$68C0#$67E5#$0028#$0026#$0053#$0029);  // 系统检查(&S)
    JsonObj.AddPair('menu_language', #$8BED#$8A00#$8BBE#$7F6E#$0028#$0026#$004C#$0029);  // 语言设置(&L)
    JsonObj.AddPair('menu_help', #$5E2E#$52A9#$0028#$0026#$0048#$0029);  // 帮助(&H)
    JsonObj.AddPair('menu_about', #$5173#$4E8E#$0028#$0026#$0041#$0029);  // 关于(&A)
    JsonObj.AddPair('btn_copy', #$590D#$5236#$6587#$4EF6);  // 复制文件
    JsonObj.AddPair('btn_delete', #$5220#$9664#$5E76#$94FE#$63A5);  // 删除并链接
    JsonObj.AddPair('btn_backup', #$521B#$5EFA#$5907#$4EFD);  // 创建备份
    JsonObj.AddPair('btn_cancel', #$53D6#$6D88);  // 取消
    JsonObj.AddPair('btn_ok', #$786E#$5B9A);  // 确定
    JsonObj.AddPair('btn_yes', #$662F);  // 是
    JsonObj.AddPair('btn_no', #$5426);  // 否
    JsonObj.AddPair('btn_close', #$5173#$95ED);  // 关闭
    JsonObj.AddPair('tab_backup', #$5907#$4EFD#$7BA1#$7406);  // 备份管理
    JsonObj.AddPair('tab_about', #$5173#$4E8E#$5F00#$53D1#$8005);  // 关于开发者
    JsonObj.AddPair('status_ready', #$5C31#$7EEA);  // 就绪
    JsonObj.AddPair('status_copying', #$6B63#$5728#$590D#$5236#$002E#$002E#$002E);  // 正在复制...
    JsonObj.AddPair('status_complete', #$64CD#$4F5C#$5B8C#$6210);  // 操作完成
    JsonObj.AddPair('progress_title', #$64CD#$4F5C#$8FDB#$5EA6);  // 操作进度
    JsonObj.AddPair('confirm_delete', #$786E#$5B9A#$8981#$5220#$9664#$9009#$4E2D#$7684#$6587#$4EF6#$5417#$FF1F);  // 确定要删除选中的文件吗？
    JsonObj.AddPair('language_changed', #$8BED#$8A00#$8BBE#$7F6E#$5DF2#$66F4#$6539#$FF0C#$90E8#$5206#$754C#$9762#$5C06#$5728#$91CD#$542F#$540E#$751F#$6548#$3002);  // 语言设置已更改，部分界面将在重启后生效。
    JsonObj.AddPair('donation_title', #$652F#$6301#$5F00#$53D1#$8005);  // 支持开发者
    JsonObj.AddPair('machine_code', #$673A#$5668#$7801);  // 机器码
    
    Result := JsonObj.Format;
  finally
    JsonObj.Free;
  end;
end;

function CreateChineseTraditionalJSON: string;
var
  JsonObj: TJSONObject;
begin
  JsonObj := TJSONObject.Create;
  try
    JsonObj.AddPair('app_title', #$0043#$76E4#$8D85#$7D1A#$6E05#$7406);  // C盤超級清理
    JsonObj.AddPair('app_version', #$7248#$672C);  // 版本
    JsonObj.AddPair('menu_file', #$6A94#$6848#$0028#$0026#$0046#$0029);  // 檔案(&F)
    JsonObj.AddPair('menu_exit', #$9000#$51FA#$0028#$0026#$0058#$0029);  // 退出(&X)
    JsonObj.AddPair('menu_tools', #$5DE5#$5177#$0028#$0026#$0054#$0029);  // 工具(&T)
    JsonObj.AddPair('menu_system_check', #$7CFB#$7D71#$6AA2#$67E5#$0028#$0026#$0053#$0029);  // 系統檢查(&S)
    JsonObj.AddPair('menu_language', #$8A9E#$8A00#$8A2D#$5B9A#$0028#$0026#$004C#$0029);  // 語言設定(&L)
    JsonObj.AddPair('menu_help', #$8AAA#$660E#$0028#$0026#$0048#$0029);  // 說明(&H)
    JsonObj.AddPair('menu_about', #$95DC#$65BC#$0028#$0026#$0041#$0029);  // 關於(&A)
    JsonObj.AddPair('btn_copy', #$8907#$88FD#$6A94#$6848);  // 複製檔案
    JsonObj.AddPair('btn_delete', #$522A#$9664#$4E26#$9023#$7D50);  // 刪除並連結
    JsonObj.AddPair('btn_backup', #$5EFA#$7ACB#$5099#$4EFD);  // 建立備份
    JsonObj.AddPair('btn_cancel', #$53D6#$6D88);  // 取消
    JsonObj.AddPair('btn_ok', #$78BA#$5B9A);  // 確定
    JsonObj.AddPair('btn_yes', #$662F);  // 是
    JsonObj.AddPair('btn_no', #$5426);  // 否
    JsonObj.AddPair('btn_close', #$95DC#$9589);  // 關閉
    JsonObj.AddPair('tab_backup', #$5099#$4EFD#$7BA1#$7406);  // 備份管理
    JsonObj.AddPair('tab_about', #$95DC#$65BC#$958B#$767C#$8005);  // 關於開發者
    JsonObj.AddPair('status_ready', #$5C31#$7DD2);  // 就緒
    JsonObj.AddPair('status_copying', #$6B63#$5728#$8907#$88FD#$002E#$002E#$002E);  // 正在複製...
    JsonObj.AddPair('status_complete', #$64CD#$4F5C#$5B8C#$6210);  // 操作完成
    JsonObj.AddPair('progress_title', #$64CD#$4F5C#$9032#$5EA6);  // 操作進度
    JsonObj.AddPair('confirm_delete', #$78BA#$5B9A#$8981#$522A#$9664#$9078#$4E2D#$7684#$6A94#$6848#$55CE#$FF1F);  // 確定要刪除選中的檔案嗎？
    JsonObj.AddPair('language_changed', #$8A9E#$8A00#$8A2D#$5B9A#$5DF2#$66F4#$6539#$FF0C#$90E8#$5206#$4ECB#$9762#$5C07#$5728#$91CD#$555F#$5F8C#$751F#$6548#$3002);  // 語言設定已更改，部分介面將在重啟後生效。
    JsonObj.AddPair('donation_title', #$652F#$6301#$958B#$767C#$8005);  // 支持開發者
    JsonObj.AddPair('machine_code', #$6A5F#$5668#$78BC);  // 機器碼
    
    Result := JsonObj.Format;
  finally
    JsonObj.Free;
  end;
end;

procedure TestDatabaseChineseSupport;
var
  DbManager: TDatabaseManager;
  TestString, ReadString: string;
begin
  Writeln('Testing database Chinese support...');
  
  DbManager := TDatabaseManager.Create;
  try
    if DbManager.Initialize then
    begin
      // 测试字符串
      TestString := #$0043#$76D8#$8D85#$7EA7#$6E05#$7406#$5DE5#$5177;  // C盘超级清理工具
      
      // 写入测试
      if DbManager.SetLanguageString('zh-CN', 'test_final', TestString) then
      begin
        // 读取测试
        ReadString := DbManager.GetLanguageString('zh-CN', 'test_final');
        
        Writeln('Written: ' + TestString);
        Writeln('Read: ' + ReadString);
        
        if ReadString = TestString then
          Writeln('✓ Database Chinese support: SUCCESS')
        else
          Writeln('✗ Database Chinese support: FAILED - Mismatch');
      end
      else
        Writeln('✗ Database Chinese support: FAILED - Cannot write');
    end
    else
      Writeln('✗ Database Chinese support: FAILED - Cannot initialize');
  finally
    DbManager.Free;
  end;
end;

begin
  try
    Writeln('=== Final Chinese Encoding Fix ===');
    Writeln('');
    
    // 确保目录存在
    if not TDirectory.Exists('Languages') then
      TDirectory.CreateDirectory('Languages');
    
    // 创建简体中文文件
    Writeln('Creating Simplified Chinese file...');
    TFile.WriteAllText('Languages\zh-CN.json', CreateChineseSimplifiedJSON, TEncoding.UTF8);
    
    // 创建繁体中文文件
    Writeln('Creating Traditional Chinese file...');
    TFile.WriteAllText('Languages\zh-TW.json', CreateChineseTraditionalJSON, TEncoding.UTF8);
    
    Writeln('');
    
    // 测试数据库支持
    TestDatabaseChineseSupport;
    
    Writeln('');
    Writeln('=== Fix Complete ===');
    Writeln('');
    Writeln('Chinese language files have been fixed with correct UTF-8 encoding.');
    Writeln('Your application should now display Chinese characters correctly.');
    
  except
    on E: Exception do
      Writeln('Error: ' + E.Message);
  end;
  
  Writeln('');
  Writeln('Press any key to exit...');
  Readln;
end.

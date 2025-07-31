program CreateChineseWithUnicode;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON;

function CreateChineseJSON: string;
var
  JsonObj: TJSONObject;
begin
  JsonObj := TJSONObject.Create;
  try
    // 使用Unicode转义序列来避免编译器编码问题
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

begin
  try
    Writeln('Creating Chinese JSON with Unicode escapes...');
    
    // 确保目录存在
    if not TDirectory.Exists('Languages') then
      TDirectory.CreateDirectory('Languages');
    
    // 创建正确的中文JSON文件
    var JsonContent := CreateChineseJSON;
    TFile.WriteAllText('Languages\zh-CN-unicode.json', JsonContent, TEncoding.UTF8);
    
    Writeln('File created: Languages\zh-CN-unicode.json');
    
    // 测试读取
    var ReadContent := TFile.ReadAllText('Languages\zh-CN-unicode.json', TEncoding.UTF8);
    var JsonObj := TJSONObject.ParseJSONValue(ReadContent) as TJSONObject;
    
    if Assigned(JsonObj) then
    begin
      var AppTitle := JsonObj.GetValue('app_title').Value;
      Writeln('App title from file: ' + AppTitle);
      JsonObj.Free;
    end;
    
  except
    on E: Exception do
      Writeln('Error: ' + E.Message);
  end;
  
  Writeln('Press any key to exit...');
  Readln;
end.

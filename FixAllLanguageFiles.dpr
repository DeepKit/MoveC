program FixAllLanguageFiles;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.JSON,
  DatabaseManager,
  DataTypes;

procedure CreateChineseSimplifiedFile;
var
  JsonObj: TJSONObject;
  JsonText: string;
begin
  JsonObj := TJSONObject.Create;
  try
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
    
    JsonText := JsonObj.Format;
    TFile.WriteAllText('Languages\zh-CN.json', JsonText, TEncoding.UTF8);
    Writeln('简体中文语言文件已修复');
  finally
    JsonObj.Free;
  end;
end;

procedure CreateChineseTraditionalFile;
var
  JsonObj: TJSONObject;
  JsonText: string;
begin
  JsonObj := TJSONObject.Create;
  try
    JsonObj.AddPair('app_title', 'C盤超級清理');
    JsonObj.AddPair('app_version', '版本');
    JsonObj.AddPair('menu_file', '檔案(&F)');
    JsonObj.AddPair('menu_exit', '退出(&X)');
    JsonObj.AddPair('menu_tools', '工具(&T)');
    JsonObj.AddPair('menu_system_check', '系統檢查(&S)');
    JsonObj.AddPair('menu_language', '語言設定(&L)');
    JsonObj.AddPair('menu_help', '說明(&H)');
    JsonObj.AddPair('menu_about', '關於(&A)');
    JsonObj.AddPair('btn_copy', '複製檔案');
    JsonObj.AddPair('btn_delete', '刪除並連結');
    JsonObj.AddPair('btn_backup', '建立備份');
    JsonObj.AddPair('btn_cancel', '取消');
    JsonObj.AddPair('btn_ok', '確定');
    JsonObj.AddPair('btn_yes', '是');
    JsonObj.AddPair('btn_no', '否');
    JsonObj.AddPair('btn_close', '關閉');
    JsonObj.AddPair('tab_backup', '備份管理');
    JsonObj.AddPair('tab_about', '關於開發者');
    JsonObj.AddPair('status_ready', '就緒');
    JsonObj.AddPair('status_copying', '正在複製...');
    JsonObj.AddPair('status_complete', '操作完成');
    JsonObj.AddPair('progress_title', '操作進度');
    JsonObj.AddPair('confirm_delete', '確定要刪除選中的檔案嗎？');
    JsonObj.AddPair('language_changed', '語言設定已更改，部分介面將在重啟後生效。');
    JsonObj.AddPair('donation_title', '支持開發者');
    JsonObj.AddPair('machine_code', '機器碼');
    
    JsonText := JsonObj.Format;
    TFile.WriteAllText('Languages\zh-TW.json', JsonText, TEncoding.UTF8);
    Writeln('繁體中文語言文件已修復');
  finally
    JsonObj.Free;
  end;
end;

procedure CreateJapaneseFile;
var
  JsonObj: TJSONObject;
  JsonText: string;
begin
  JsonObj := TJSONObject.Create;
  try
    JsonObj.AddPair('app_title', 'ディスククリーンアップツール');
    JsonObj.AddPair('app_version', 'バージョン');
    JsonObj.AddPair('menu_file', 'ファイル(&F)');
    JsonObj.AddPair('menu_exit', '終了(&X)');
    JsonObj.AddPair('menu_tools', 'ツール(&T)');
    JsonObj.AddPair('menu_system_check', 'システムチェック(&S)');
    JsonObj.AddPair('menu_language', '言語(&L)');
    JsonObj.AddPair('menu_help', 'ヘルプ(&H)');
    JsonObj.AddPair('menu_about', 'について(&A)');
    JsonObj.AddPair('btn_copy', 'ファイルをコピー');
    JsonObj.AddPair('btn_delete', '削除してリンク');
    JsonObj.AddPair('btn_backup', 'バックアップ作成');
    JsonObj.AddPair('btn_cancel', 'キャンセル');
    JsonObj.AddPair('btn_ok', 'OK');
    JsonObj.AddPair('btn_yes', 'はい');
    JsonObj.AddPair('btn_no', 'いいえ');
    JsonObj.AddPair('btn_close', '閉じる');
    JsonObj.AddPair('tab_backup', 'バックアップ管理');
    JsonObj.AddPair('tab_about', '開発者について');
    JsonObj.AddPair('status_ready', '準備完了');
    JsonObj.AddPair('status_copying', 'コピー中...');
    JsonObj.AddPair('status_complete', '操作完了');
    JsonObj.AddPair('progress_title', '操作進行状況');
    JsonObj.AddPair('confirm_delete', '選択したファイルを削除しますか？');
    JsonObj.AddPair('language_changed', '言語設定が変更されました。一部のインターフェースは再起動後に有効になります。');
    JsonObj.AddPair('donation_title', '開発者をサポート');
    JsonObj.AddPair('machine_code', 'マシンコード');
    
    JsonText := JsonObj.Format;
    TFile.WriteAllText('Languages\ja-JP.json', JsonText, TEncoding.UTF8);
    Writeln('日本語言語文件已修復');
  finally
    JsonObj.Free;
  end;
end;

procedure TestDatabaseOperations;
var
  DbManager: TDatabaseManager;
  TestResult: string;
begin
  DbManager := TDatabaseManager.Create;
  try
    if DbManager.Initialize then
    begin
      Writeln('正在测试数据库中文支持...');
      
      // 测试中文字符串
      if DbManager.SetLanguageString('zh-CN', 'test_chinese', 'C盘超级清理') then
      begin
        TestResult := DbManager.GetLanguageString('zh-CN', 'test_chinese');
        if TestResult = 'C盘超级清理' then
          Writeln('数据库中文支持测试: 成功')
        else
          Writeln('数据库中文支持测试: 失败 - 读取结果不匹配');
      end
      else
        Writeln('数据库中文支持测试: 失败 - 无法写入');
    end
    else
      Writeln('数据库初始化失败');
  finally
    DbManager.Free;
  end;
end;

begin
  try
    Writeln('=== 语言文件修复工具 ===');
    Writeln('');
    
    // 创建语言文件目录（如果不存在）
    if not TDirectory.Exists('Languages') then
      TDirectory.CreateDirectory('Languages');
    
    // 修复各种语言文件
    CreateChineseSimplifiedFile;
    CreateChineseTraditionalFile;
    CreateJapaneseFile;
    
    Writeln('');
    
    // 测试数据库操作
    TestDatabaseOperations;
    
    Writeln('');
    Writeln('所有语言文件已修复完成！');
    Writeln('注意: 如果在终端中看到乱码，这是正常的显示问题。');
    Writeln('文件本身使用正确的UTF-8编码，程序运行时会正确显示中文。');
    
  except
    on E: Exception do
      Writeln('错误: ' + E.Message);
  end;
  
  Writeln('');
  Writeln('按任意键退出...');
  Readln;
end.

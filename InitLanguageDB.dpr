program InitLanguageDB;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Math,
  DatabaseManager in 'Core\DatabaseManager.pas',
  DataTypes in 'Core\DataTypes.pas',
  BasicProtection in 'Core\BasicProtection.pas',
  LanguageManager in 'Core\LanguageManager.pas',
  LanguageTypes in 'Core\LanguageTypes.pas';

var
  DbMgr: TDatabaseManager;
  
procedure InitializeChineseStrings(DbMgr: TDatabaseManager);
begin
  WriteLn('初始化简体中文字符串...');
  
  // 应用程序基本信息
  DbMgr.SetLanguageString('zh-CN', 'app_title', 'C盘超级清理');
  
  // 菜单项
  DbMgr.SetLanguageString('zh-CN', 'menu_file', '文件(&F)');
  DbMgr.SetLanguageString('zh-CN', 'menu_exit', '退出(&X)');
  DbMgr.SetLanguageString('zh-CN', 'menu_tools', '工具(&T)');
  DbMgr.SetLanguageString('zh-CN', 'menu_system_check', '系统检查(&S)');
  DbMgr.SetLanguageString('zh-CN', 'menu_language', '语言设置(&L)');
  DbMgr.SetLanguageString('zh-CN', 'menu_help', '帮助(&H)');
  DbMgr.SetLanguageString('zh-CN', 'menu_about', '关于(&A)');
  
  // 按钮
  DbMgr.SetLanguageString('zh-CN', 'btn_copy', '复制文件');
  DbMgr.SetLanguageString('zh-CN', 'btn_delete', '删除并链接');
  DbMgr.SetLanguageString('zh-CN', 'btn_backup', '创建备份');
  DbMgr.SetLanguageString('zh-CN', 'btn_cancel', '取消');
  DbMgr.SetLanguageString('zh-CN', 'btn_ok', '确定');
  DbMgr.SetLanguageString('zh-CN', 'btn_yes', '是');
  DbMgr.SetLanguageString('zh-CN', 'btn_no', '否');
  DbMgr.SetLanguageString('zh-CN', 'btn_close', '关闭');
  
  // 标签页
  DbMgr.SetLanguageString('zh-CN', 'tab_backup', '备份管理');
  DbMgr.SetLanguageString('zh-CN', 'tab_about', '关于开发者');
  
  // 状态信息
  DbMgr.SetLanguageString('zh-CN', 'status_ready', '就绪');
  DbMgr.SetLanguageString('zh-CN', 'status_copying', '正在复制...');
  DbMgr.SetLanguageString('zh-CN', 'status_complete', '操作完成');
  DbMgr.SetLanguageString('zh-CN', 'progress_title', '操作进度');
  
  // 对话框
  DbMgr.SetLanguageString('zh-CN', 'confirm_delete', '确定要删除选中的文件吗？');
  DbMgr.SetLanguageString('zh-CN', 'language_changed', '语言设置已更改，部分界面将在重启后生效。');
  DbMgr.SetLanguageString('zh-CN', 'donation_title', '支持开发者');
  DbMgr.SetLanguageString('zh-CN', 'machine_code', '机器码');

  // 语言设置对话框
  DbMgr.SetLanguageString('zh-CN', 'language_settings', '语言设置');
  DbMgr.SetLanguageString('zh-CN', 'select_interface_language', '选择界面语言');
  DbMgr.SetLanguageString('zh-CN', 'select_language_description', '请选择您希望使用的界面语言：');
  DbMgr.SetLanguageString('zh-CN', 'current_language', '当前语言');

  // 语言名称
  DbMgr.SetLanguageString('zh-CN', 'lang_chinese_simplified', '简体中文');
  DbMgr.SetLanguageString('zh-CN', 'lang_chinese_traditional', '繁体中文');
  DbMgr.SetLanguageString('zh-CN', 'lang_english', 'English');
  DbMgr.SetLanguageString('zh-CN', 'lang_japanese', '日本語');

  // 列表视图列标题
  DbMgr.SetLanguageString('zh-CN', 'col_backup_name', '备份名称');
  DbMgr.SetLanguageString('zh-CN', 'col_size', '大小');
  DbMgr.SetLanguageString('zh-CN', 'col_create_time', '创建时间');
  DbMgr.SetLanguageString('zh-CN', 'col_path', '路径');

  // 系统检查
  DbMgr.SetLanguageString('zh-CN', 'system_check_report', '系统兼容性检查报告');

  // 目录大小相关
  DbMgr.SetLanguageString('zh-CN', 'click_calc_size', '点击"计算目录大小"按钮获取大小信息');
  DbMgr.SetLanguageString('zh-CN', 'dir_size', '目录大小');
  DbMgr.SetLanguageString('zh-CN', 'dir_too_large', '目录过大，建议不要计算');
  DbMgr.SetLanguageString('zh-CN', 'calc_failed', '计算失败');

  // 按钮状态
  DbMgr.SetLanguageString('zh-CN', 'stop_copy', '停止拷贝');
  DbMgr.SetLanguageString('zh-CN', 'copy_files', '拷贝文件');

  // 状态消息
  DbMgr.SetLanguageString('zh-CN', 'ui_language_updated', '界面语言已更新为');

  // 主界面按钮和标签
  DbMgr.SetLanguageString('zh-CN', 'select_source_folder', '选择源文件夹');
  DbMgr.SetLanguageString('zh-CN', 'select_target_folder', '选择目标文件夹');
  DbMgr.SetLanguageString('zh-CN', 'calc_dir_size', '计算目录大小');
  DbMgr.SetLanguageString('zh-CN', 'target_dir', '目标目录');
  DbMgr.SetLanguageString('zh-CN', 'source_dir', '迁移源目录');

  // 状态栏
  DbMgr.SetLanguageString('zh-CN', 'analyze_stats', '分析并统计');
  DbMgr.SetLanguageString('zh-CN', 'add_to_migration', '添加到迁移列表');
  DbMgr.SetLanguageString('zh-CN', 'remove_from_migration', '移除迁移项目');
  DbMgr.SetLanguageString('zh-CN', 'clear_migration_list', '清空迁移列表');
  DbMgr.SetLanguageString('zh-CN', 'verify_action', '验证动作');

  // 文件列表相关
  DbMgr.SetLanguageString('zh-CN', 'filename', '文件名');
  DbMgr.SetLanguageString('zh-CN', 'filesize', '文件大小');
  DbMgr.SetLanguageString('zh-CN', 'migration_status', '迁移状态');
  DbMgr.SetLanguageString('zh-CN', 'last_modified', '修改时间');

  // 复选框
  DbMgr.SetLanguageString('zh-CN', 'calc_subdir_size', '计算子目录大小');
  DbMgr.SetLanguageString('zh-CN', 'show_large_files', '显示大文件');

  // 更多按钮
  DbMgr.SetLanguageString('zh-CN', 'btn_rollback', '回滚操作');
  DbMgr.SetLanguageString('zh-CN', 'btn_close', '关闭');
  DbMgr.SetLanguageString('zh-CN', 'stop_copy', '停止拷贝');
  DbMgr.SetLanguageString('zh-CN', 'copy_files', '拷贝文件');
  DbMgr.SetLanguageString('zh-CN', 'click_calc_size', '点击"计算目录大小"按钮获取大小信息');
  
  WriteLn('简体中文字符串初始化完成');
end;

procedure InitializeEnglishStrings(DbMgr: TDatabaseManager);
begin
  WriteLn('初始化英文字符串...');
  
  // 应用程序基本信息
  DbMgr.SetLanguageString('en-US', 'app_title', 'Disk Cleanup Tool');
  
  // 菜单项
  DbMgr.SetLanguageString('en-US', 'menu_file', 'File(&F)');
  DbMgr.SetLanguageString('en-US', 'menu_exit', 'Exit(&X)');
  DbMgr.SetLanguageString('en-US', 'menu_tools', 'Tools(&T)');
  DbMgr.SetLanguageString('en-US', 'menu_system_check', 'System Check(&S)');
  DbMgr.SetLanguageString('en-US', 'menu_language', 'Language(&L)');
  DbMgr.SetLanguageString('en-US', 'menu_help', 'Help(&H)');
  DbMgr.SetLanguageString('en-US', 'menu_about', 'About(&A)');
  
  // 按钮
  DbMgr.SetLanguageString('en-US', 'btn_copy', 'Copy Files');
  DbMgr.SetLanguageString('en-US', 'btn_delete', 'Delete & Link');
  DbMgr.SetLanguageString('en-US', 'btn_backup', 'Create Backup');
  DbMgr.SetLanguageString('en-US', 'btn_cancel', 'Cancel');
  DbMgr.SetLanguageString('en-US', 'btn_ok', 'OK');
  DbMgr.SetLanguageString('en-US', 'btn_yes', 'Yes');
  DbMgr.SetLanguageString('en-US', 'btn_no', 'No');
  DbMgr.SetLanguageString('en-US', 'btn_close', 'Close');
  
  // 标签页
  DbMgr.SetLanguageString('en-US', 'tab_backup', 'Backup Management');
  DbMgr.SetLanguageString('en-US', 'tab_about', 'About Developer');
  
  // 状态信息
  DbMgr.SetLanguageString('en-US', 'status_ready', 'Ready');
  DbMgr.SetLanguageString('en-US', 'status_copying', 'Copying...');
  DbMgr.SetLanguageString('en-US', 'status_complete', 'Operation Complete');
  DbMgr.SetLanguageString('en-US', 'progress_title', 'Operation Progress');
  
  // 对话框
  DbMgr.SetLanguageString('en-US', 'confirm_delete', 'Are you sure you want to delete the selected files?');
  DbMgr.SetLanguageString('en-US', 'language_changed', 'Language settings changed. Some interface will take effect after restart.');
  DbMgr.SetLanguageString('en-US', 'donation_title', 'Support Developer');
  DbMgr.SetLanguageString('en-US', 'machine_code', 'Machine Code');

  // 语言设置对话框
  DbMgr.SetLanguageString('en-US', 'language_settings', 'Language Settings');
  DbMgr.SetLanguageString('en-US', 'select_interface_language', 'Select Interface Language');
  DbMgr.SetLanguageString('en-US', 'select_language_description', 'Please select your preferred interface language:');
  DbMgr.SetLanguageString('en-US', 'current_language', 'Current Language');

  // 语言名称
  DbMgr.SetLanguageString('en-US', 'lang_chinese_simplified', '简体中文');
  DbMgr.SetLanguageString('en-US', 'lang_chinese_traditional', '繁体中文');
  DbMgr.SetLanguageString('en-US', 'lang_english', 'English');
  DbMgr.SetLanguageString('en-US', 'lang_japanese', '日本語');

  // 列表视图列标题
  DbMgr.SetLanguageString('en-US', 'col_backup_name', 'Backup Name');
  DbMgr.SetLanguageString('en-US', 'col_size', 'Size');
  DbMgr.SetLanguageString('en-US', 'col_create_time', 'Create Time');
  DbMgr.SetLanguageString('en-US', 'col_path', 'Path');

  // 系统检查
  DbMgr.SetLanguageString('en-US', 'system_check_report', 'System Compatibility Check Report');

  // 目录大小相关
  DbMgr.SetLanguageString('en-US', 'click_calc_size', 'Click "Calculate Directory Size" button to get size information');
  DbMgr.SetLanguageString('en-US', 'dir_size', 'Directory Size');
  DbMgr.SetLanguageString('en-US', 'dir_too_large', 'Directory too large, not recommended to calculate');
  DbMgr.SetLanguageString('en-US', 'calc_failed', 'Calculation Failed');

  // 按钮状态
  DbMgr.SetLanguageString('en-US', 'stop_copy', 'Stop Copy');
  DbMgr.SetLanguageString('en-US', 'copy_files', 'Copy Files');

  // 状态消息
  DbMgr.SetLanguageString('en-US', 'ui_language_updated', 'UI language updated to');

  // 主界面按钮和标签
  DbMgr.SetLanguageString('en-US', 'select_source_folder', 'Select Source Folder');
  DbMgr.SetLanguageString('en-US', 'select_target_folder', 'Select Target Folder');
  DbMgr.SetLanguageString('en-US', 'calc_dir_size', 'Calculate Directory Size');
  DbMgr.SetLanguageString('en-US', 'target_dir', 'Target Directory');
  DbMgr.SetLanguageString('en-US', 'source_dir', 'Source Directory');

  // 状态栏
  DbMgr.SetLanguageString('en-US', 'analyze_stats', 'Analyze & Statistics');
  DbMgr.SetLanguageString('en-US', 'add_to_migration', 'Add to Migration List');
  DbMgr.SetLanguageString('en-US', 'remove_from_migration', 'Remove Migration Item');
  DbMgr.SetLanguageString('en-US', 'clear_migration_list', 'Clear Migration List');
  DbMgr.SetLanguageString('en-US', 'verify_action', 'Verify Action');

  // 文件列表相关
  DbMgr.SetLanguageString('en-US', 'filename', 'Filename');
  DbMgr.SetLanguageString('en-US', 'filesize', 'File Size');
  DbMgr.SetLanguageString('en-US', 'migration_status', 'Migration Status');
  DbMgr.SetLanguageString('en-US', 'last_modified', 'Last Modified');

  // 复选框
  DbMgr.SetLanguageString('en-US', 'calc_subdir_size', 'Calculate Subdirectory Size');
  DbMgr.SetLanguageString('en-US', 'show_large_files', 'Show Large Files');

  // 更多按钮
  DbMgr.SetLanguageString('en-US', 'btn_rollback', 'Rollback Operation');
  DbMgr.SetLanguageString('en-US', 'btn_close', 'Close');
  DbMgr.SetLanguageString('en-US', 'stop_copy', 'Stop Copy');
  DbMgr.SetLanguageString('en-US', 'copy_files', 'Copy Files');
  DbMgr.SetLanguageString('en-US', 'click_calc_size', 'Click "Calculate Directory Size" button to get size information');
  
  WriteLn('英文字符串初始化完成');
end;

begin
  try
    WriteLn('=== 初始化多语言数据库 ===');
    
    // 创建数据库管理器
    DbMgr := TDatabaseManager.Create;
    try
      WriteLn('初始化数据库...');
      if DbMgr.Initialize then
        WriteLn('数据库初始化成功')
      else
      begin
        WriteLn('数据库初始化失败');
        Exit;
      end;
      
      // 初始化中文字符串
      InitializeChineseStrings(DbMgr);
      
      // 初始化英文字符串
      InitializeEnglishStrings(DbMgr);
      
      // 验证数据
      WriteLn('验证数据...');
      var ChineseStrings := DbMgr.GetAllLanguageStrings('zh-CN');
      var EnglishStrings := DbMgr.GetAllLanguageStrings('en-US');
      
      WriteLn('中文字符串数量: ' + IntToStr(Length(ChineseStrings)));
      WriteLn('英文字符串数量: ' + IntToStr(Length(EnglishStrings)));
      
      // 显示一些示例
      WriteLn('示例中文字符串:');
      WriteLn('  app_title: ' + DbMgr.GetLanguageString('zh-CN', 'app_title'));
      WriteLn('  menu_file: ' + DbMgr.GetLanguageString('zh-CN', 'menu_file'));
      WriteLn('  btn_copy: ' + DbMgr.GetLanguageString('zh-CN', 'btn_copy'));
      
      WriteLn('示例英文字符串:');
      WriteLn('  app_title: ' + DbMgr.GetLanguageString('en-US', 'app_title'));
      WriteLn('  menu_file: ' + DbMgr.GetLanguageString('en-US', 'menu_file'));
      WriteLn('  btn_copy: ' + DbMgr.GetLanguageString('en-US', 'btn_copy'));
      
    finally
      DbMgr.Free;
    end;
    
    WriteLn('=== 初始化完成 ===');
    
  except
    on E: Exception do
      WriteLn('错误: ' + E.Message);
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.

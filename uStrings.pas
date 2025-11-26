unit uStrings;

interface

type
  // 支持的语言类型
  TLanguageType = (ltChinese, ltEnglish, ltJapanese);

var
  // 当前语言设置
  CurrentLanguage: TLanguageType = ltChinese;

// 国际化函数
function _(const AKey: string): string;
function GetString(const AKey: string; ALang: TLanguageType = ltChinese): string;

const
  // 字符串键值常量
  // 窗体标题
  STR_MAIN_TITLE = 'main_title';
  STR_CONFIG_TITLE = 'config_title';
  STR_CLEANUP_TITLE = 'cleanup_title';
  STR_MIGRATION_TITLE = 'migration_title';
  
  // 按钮文本
  STR_BTN_CLEAN_RECYCLE = 'btn_clean_recycle';
  STR_BTN_CLEAN_TEMP = 'btn_clean_temp';
  STR_BTN_CLEAN_BACKUP = 'btn_clean_backup';
  STR_BTN_CLEAN_UPDATE = 'btn_clean_update';
  STR_BTN_SMART_CLEAN = 'btn_smart_clean';
  STR_BTN_SMART_MIGRATION = 'btn_smart_migration';
  STR_BTN_EXIT = 'btn_exit';
  STR_BTN_OK = 'btn_ok';
  STR_BTN_CANCEL = 'btn_cancel';
  STR_BTN_BROWSE = 'btn_browse';
  STR_BTN_SCAN = 'btn_scan';
  STR_BTN_MIGRATE = 'btn_migrate';
  
  // 标签文本
  STR_LBL_SOURCE_DIR = 'lbl_source_dir';
  STR_LBL_TARGET_DIR = 'lbl_target_dir';
  STR_LBL_STATUS = 'lbl_status';
  STR_LBL_PROGRESS = 'lbl_progress';
  
  // 状态消息
  STR_STATUS_READY = 'status_ready';
  STR_STATUS_SCANNING = 'status_scanning';
  STR_STATUS_CLEANING = 'status_cleaning';
  STR_STATUS_MIGRATING = 'status_migrating';
  STR_STATUS_COMPLETED = 'status_completed';
  STR_STATUS_CANCELLED = 'status_cancelled';
  STR_STATUS_ERROR = 'status_error';

implementation

// 中文字符串映射表
function GetChineseString(const AKey: string): string;
begin
  // 窗体标题
  if AKey = STR_MAIN_TITLE then Result := 'C盘瘦身神器 - 智能目录迁移专家'
  else if AKey = STR_CONFIG_TITLE then Result := '配置管理器'
  else if AKey = STR_CLEANUP_TITLE then Result := '智能重复文件清理'
  else if AKey = STR_MIGRATION_TITLE then Result := '智能目录迁移'
  
  // 按钮文本
  else if AKey = STR_BTN_CLEAN_RECYCLE then Result := '清空回收站'
  else if AKey = STR_BTN_CLEAN_TEMP then Result := '清理临时文件'
  else if AKey = STR_BTN_CLEAN_BACKUP then Result := '清理备份'
  else if AKey = STR_BTN_CLEAN_UPDATE then Result := '清理更新缓存'
  else if AKey = STR_BTN_SMART_CLEAN then Result := '智能清理'
  else if AKey = STR_BTN_SMART_MIGRATION then Result := '智能迁移'
  else if AKey = STR_BTN_EXIT then Result := '退出'
  else if AKey = STR_BTN_OK then Result := '确定'
  else if AKey = STR_BTN_CANCEL then Result := '取消'
  else if AKey = STR_BTN_BROWSE then Result := '浏览...'
  else if AKey = STR_BTN_SCAN then Result := '扫描'
  else if AKey = STR_BTN_MIGRATE then Result := '迁移'
  
  // 标签文本
  else if AKey = STR_LBL_SOURCE_DIR then Result := '源目录：'
  else if AKey = STR_LBL_TARGET_DIR then Result := '目标目录：'
  else if AKey = STR_LBL_STATUS then Result := '状态：'
  else if AKey = STR_LBL_PROGRESS then Result := '进度：'
  
  // 状态消息
  else if AKey = STR_STATUS_READY then Result := '就绪 - 选择源目录和目标目录开始操作'
  else if AKey = STR_STATUS_SCANNING then Result := '正在扫描目录...'
  else if AKey = STR_STATUS_CLEANING then Result := '正在清理文件...'
  else if AKey = STR_STATUS_MIGRATING then Result := '正在迁移目录...'
  else if AKey = STR_STATUS_COMPLETED then Result := '操作完成'
  else if AKey = STR_STATUS_CANCELLED then Result := '操作已取消'
  else if AKey = STR_STATUS_ERROR then Result := '操作出错'
  
  // 默认返回键值
  else Result := AKey;
end;

// 英文字符串映射表
function GetEnglishString(const AKey: string): string;
begin
  // 窗体标题
  if AKey = STR_MAIN_TITLE then Result := 'C Drive Slimmer - Smart Directory Migration Expert'
  else if AKey = STR_CONFIG_TITLE then Result := 'Configuration Manager'
  else if AKey = STR_CLEANUP_TITLE then Result := 'Smart Duplicate File Cleanup'
  else if AKey = STR_MIGRATION_TITLE then Result := 'Smart Directory Migration'
  
  // 按钮文本
  else if AKey = STR_BTN_CLEAN_RECYCLE then Result := 'Empty Recycle Bin'
  else if AKey = STR_BTN_CLEAN_TEMP then Result := 'Clean Temp Files'
  else if AKey = STR_BTN_CLEAN_BACKUP then Result := 'Clean Backup'
  else if AKey = STR_BTN_CLEAN_UPDATE then Result := 'Clean Update Cache'
  else if AKey = STR_BTN_SMART_CLEAN then Result := 'Smart Clean'
  else if AKey = STR_BTN_SMART_MIGRATION then Result := 'Smart Migration'
  else if AKey = STR_BTN_EXIT then Result := 'Exit'
  else if AKey = STR_BTN_OK then Result := 'OK'
  else if AKey = STR_BTN_CANCEL then Result := 'Cancel'
  else if AKey = STR_BTN_BROWSE then Result := 'Browse...'
  else if AKey = STR_BTN_SCAN then Result := 'Scan'
  else if AKey = STR_BTN_MIGRATE then Result := 'Migrate'
  
  // 标签文本
  else if AKey = STR_LBL_SOURCE_DIR then Result := 'Source Directory:'
  else if AKey = STR_LBL_TARGET_DIR then Result := 'Target Directory:'
  else if AKey = STR_LBL_STATUS then Result := 'Status:'
  else if AKey = STR_LBL_PROGRESS then Result := 'Progress:'
  
  // 状态消息
  else if AKey = STR_STATUS_READY then Result := 'Ready - Select source and target directories to start'
  else if AKey = STR_STATUS_SCANNING then Result := 'Scanning directories...'
  else if AKey = STR_STATUS_CLEANING then Result := 'Cleaning files...'
  else if AKey = STR_STATUS_MIGRATING then Result := 'Migrating directories...'
  else if AKey = STR_STATUS_COMPLETED then Result := 'Operation completed'
  else if AKey = STR_STATUS_CANCELLED then Result := 'Operation cancelled'
  else if AKey = STR_STATUS_ERROR then Result := 'Operation error'
  
  // 默认返回键值
  else Result := AKey;
end;

// 主要的国际化函数
function GetString(const AKey: string; ALang: TLanguageType = ltChinese): string;
begin
  case ALang of
    ltChinese: Result := GetChineseString(AKey);
    ltEnglish: Result := GetEnglishString(AKey);
    ltJapanese: Result := GetEnglishString(AKey); // 暂时使用英文
  else
    Result := AKey;
  end;
end;

// 简化的国际化函数
function _(const AKey: string): string;
begin
  Result := GetString(AKey, CurrentLanguage);
end;

end.

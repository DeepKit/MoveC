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
  STR_SPLASH_TITLE = 'splash_title';
  STR_SPLASH_VERSION = 'splash_version';
  STR_SPLASH_COPYRIGHT = 'splash_copyright';

  // 界面标签
  STR_SOURCE_DIR = 'source_dir';
  STR_TARGET_DIR = 'target_dir';
  STR_STATUS_AREA = 'status_area';
  STR_READY = 'ready';
  STR_SOURCE_PANEL = 'source_panel';
  STR_TARGET_PANEL = 'target_panel';

  // 按钮文本
  STR_BROWSE = 'browse';
  STR_SCAN = 'scan';
  STR_ANALYZE = 'analyze';
  STR_EXECUTE = 'execute';
  STR_STOP = 'stop';
  STR_EXIT = 'exit';
  STR_SELECT_ROOT = 'select_root';
  
  // 菜单文本
  STR_MENU_FILE = 'menu_file';
  STR_MENU_EDIT = 'menu_edit';
  STR_MENU_TOOLS = 'menu_tools';
  STR_MENU_HELP = 'menu_help';
  STR_MENU_EXIT = 'menu_exit';
  STR_MENU_THEME = 'menu_theme';
  STR_MENU_ABOUT = 'menu_about';
  
  // 状态消息
  STR_APP_STARTED = 'app_started';
  STR_SELECT_DIRS = 'select_dirs';
  STR_STYLES_APPLIED = 'styles_applied';
  STR_STYLES_FAILED = 'styles_failed';

  STR_SOURCE_SELECTED = 'source_selected';
  STR_TARGET_SELECTED = 'target_selected';
  STR_SELECT_SOURCE_FIRST = 'select_source_first';
  STR_SELECT_BOTH_DIRS = 'select_both_dirs';

  // 操作消息
  STR_SCAN_START = 'scan_start';
  STR_SCAN_COMPLETE = 'scan_complete';
  STR_ANALYZE_START = 'analyze_start';
  STR_ANALYZE_COMPLETE = 'analyze_complete';
  STR_EXECUTE_START = 'execute_start';
  STR_EXECUTE_COMPLETE = 'execute_complete';
  STR_OPERATION_STOPPED = 'operation_stopped';
  
  // 对话框
  STR_CONFIRM_EXECUTE = 'confirm_execute';
  STR_CONFIRM_EXIT = 'confirm_exit';
  STR_SELECT_SOURCE_TITLE = 'select_source_title';
  STR_SELECT_TARGET_TITLE = 'select_target_title';
  STR_SELECT_SOURCE_ROOT_TITLE = 'select_source_root_title';
  STR_SELECT_TARGET_ROOT_TITLE = 'select_target_root_title';

  // 主题切换
  STR_THEME_DARK = 'theme_dark';
  STR_THEME_LIGHT = 'theme_light';
  STR_THEME_FAILED = 'theme_failed';

  // 关于对话框
  STR_ABOUT_TEXT = 'about_text';

  // 启动画面步骤
  STR_SPLASH_STARTING = 'splash_starting';
  STR_STEP_1 = 'step_1';
  STR_STEP_2 = 'step_2';
  STR_STEP_3 = 'step_3';
  STR_STEP_4 = 'step_4';
  STR_STEP_5 = 'step_5';
  STR_STEP_6 = 'step_6';
  STR_STEP_7 = 'step_7';
  STR_STEP_8 = 'step_8';

  // 分析步骤
  STR_ANALYZING_STRUCTURE = 'analyzing_structure';
  STR_CHECKING_SPACE = 'checking_space';
  STR_EVALUATING_RISK = 'evaluating_risk';

  // 执行步骤
  STR_PREPARING_OP = 'preparing_op';
  STR_CREATING_DIRS = 'creating_dirs';
  STR_CREATING_LINKS = 'creating_links';

  // 状态栏文本
  STR_STATUS_READY = 'status_ready';
  STR_STATUS_SOURCE = 'status_source';
  STR_STATUS_TARGET = 'status_target';
  STR_STATUS_NOT_SELECTED = 'status_not_selected';

  // 其他
  STR_DIRECTORY_SUFFIX = 'directory_suffix';

implementation

uses
  System.SysUtils;

type
  // 语言字符串记录
  TLanguageStrings = record
    Key: string;
    Chinese: string;
    English: string;
    Japanese: string;
  end;

const
  // 多语言字符串数据库
  LanguageStrings: array[0..53] of TLanguageStrings = (
    // 窗体标题
    (Key: 'main_title'; Chinese: 'C盘瘦身工具 v3.0 Enterprise - 企业版'; English: 'C Drive Cleaner v3.0 Enterprise'; Japanese: 'Cドライブクリーナー v3.0 Enterprise'),
    (Key: 'splash_title'; Chinese: 'C盘瘦身工具 v3.0 Enterprise'; English: 'C Drive Cleaner v3.0 Enterprise'; Japanese: 'Cドライブクリーナー v3.0 Enterprise'),
    (Key: 'splash_version'; Chinese: '企业版 - 专业级磁盘空间管理解决方案'; English: 'Enterprise Edition - Professional Disk Space Management Solution'; Japanese: 'エンタープライズ版 - プロフェッショナルディスク容量管理ソリューション'),
    (Key: 'splash_copyright'; Chinese: '© 2025 C盘瘦身工具. 保留所有权利.'; English: '© 2025 C Drive Cleaner. All Rights Reserved.'; Japanese: '© 2025 Cドライブクリーナー. 全著作権所有.'),

    // 界面标签
    (Key: 'source_dir'; Chinese: '源目录:'; English: 'Source Directory:'; Japanese: 'ソースディレクトリ:'),
    (Key: 'target_dir'; Chinese: '目标目录:'; English: 'Target Directory:'; Japanese: 'ターゲットディレクトリ:'),
    (Key: 'status_area'; Chinese: '状态显示区'; English: 'Status Display'; Japanese: 'ステータス表示'),
    (Key: 'ready'; Chinese: '就绪'; English: 'Ready'; Japanese: '準備完了'),
    (Key: 'source_panel'; Chinese: '源目录'; English: 'Source Directory'; Japanese: 'ソースディレクトリ'),
    (Key: 'target_panel'; Chinese: '目标目录'; English: 'Target Directory'; Japanese: 'ターゲットディレクトリ'),

    // 按钮文本
    (Key: 'browse'; Chinese: '浏览...'; English: 'Browse...'; Japanese: '参照...'),
    (Key: 'scan'; Chinese: '扫描'; English: 'Scan'; Japanese: 'スキャン'),
    (Key: 'analyze'; Chinese: '分析'; English: 'Analyze'; Japanese: '分析'),
    (Key: 'execute'; Chinese: '执行'; English: 'Execute'; Japanese: '実行'),
    (Key: 'stop'; Chinese: '停止'; English: 'Stop'; Japanese: '停止'),
    (Key: 'exit'; Chinese: '退出'; English: 'Exit'; Japanese: '終了'),
    (Key: 'select_root'; Chinese: '选择根目录'; English: 'Select Root'; Japanese: 'ルート選択'),

    // 菜单文本
    (Key: 'menu_file'; Chinese: '文件(&F)'; English: '&File'; Japanese: 'ファイル(&F)'),
    (Key: 'menu_edit'; Chinese: '编辑(&E)'; English: '&Edit'; Japanese: '編集(&E)'),
    (Key: 'menu_tools'; Chinese: '工具(&T)'; English: '&Tools'; Japanese: 'ツール(&T)'),
    (Key: 'menu_help'; Chinese: '帮助(&H)'; English: '&Help'; Japanese: 'ヘルプ(&H)'),
    (Key: 'menu_exit'; Chinese: '退出(&X)'; English: 'E&xit'; Japanese: '終了(&X)'),
    (Key: 'menu_theme'; Chinese: '切换主题(&T)'; English: 'Toggle &Theme'; Japanese: 'テーマ切替(&T)'),
    (Key: 'menu_about'; Chinese: '关于(&A)'; English: '&About'; Japanese: 'バージョン情報(&A)'),

    // 状态消息
    (Key: 'app_started'; Chinese: 'C盘瘦身工具 v3.0 Enterprise 已启动 - 就绪'; English: 'C Drive Cleaner v3.0 Enterprise started - Ready'; Japanese: 'Cドライブクリーナー v3.0 Enterprise 開始 - 準備完了'),
    (Key: 'select_dirs'; Chinese: '请选择源目录和目标目录开始操作'; English: 'Please select source and target directories to begin'; Japanese: 'ソースとターゲットディレクトリを選択して開始してください'),
    (Key: 'styles_applied'; Chinese: '🎨 现代化界面样式已应用'; English: '🎨 Modern UI styles applied successfully'; Japanese: '🎨 モダンUIスタイルが適用されました'),
    (Key: 'styles_failed'; Chinese: '⚠️ 应用样式失败: '; English: '⚠️ Failed to apply styles: '; Japanese: '⚠️ スタイル適用失敗: '),

    (Key: 'source_selected'; Chinese: '源目录已选择: '; English: 'Source directory selected: '; Japanese: 'ソースディレクトリが選択されました: '),
    (Key: 'target_selected'; Chinese: '目标目录已选择: '; English: 'Target directory selected: '; Japanese: 'ターゲットディレクトリが選択されました: '),
    (Key: 'select_source_first'; Chinese: '❌ 请先选择源目录'; English: '❌ Please select source directory first'; Japanese: '❌ 最初にソースディレクトリを選択してください'),
    (Key: 'select_both_dirs'; Chinese: '❌ 请先选择源目录和目标目录'; English: '❌ Please select both source and target directories'; Japanese: '❌ ソースとターゲットディレクトリの両方を選択してください'),

    // 操作消息
    (Key: 'scan_start'; Chinese: '🔍 开始扫描目录: '; English: '🔍 Scanning directory: '; Japanese: '🔍 ディレクトリをスキャン中: '),
    (Key: 'scan_complete'; Chinese: '✅ 目录扫描完成'; English: '✅ Directory scan completed successfully'; Japanese: '✅ ディレクトリスキャンが完了しました'),
    (Key: 'analyze_start'; Chinese: '📊 开始分析目录: '; English: '📊 Analyzing directory: '; Japanese: '📊 ディレクトリを分析中: '),
    (Key: 'analyze_complete'; Chinese: '✅ 目录分析完成'; English: '✅ Directory analysis completed successfully'; Japanese: '✅ ディレクトリ分析が完了しました'),
    (Key: 'execute_start'; Chinese: '⚡ 开始执行操作...'; English: '⚡ Executing operation...'; Japanese: '⚡ 操作を実行中...'),
    (Key: 'execute_complete'; Chinese: '🎉 操作执行完成'; English: '🎉 Operation completed successfully'; Japanese: '🎉 操作が完了しました'),
    (Key: 'operation_stopped'; Chinese: '⏹️ 操作已停止'; English: '⏹️ Operation stopped by user'; Japanese: '⏹️ 操作が停止されました'),

    // 对话框
    (Key: 'confirm_execute'; Chinese: '确定要执行操作吗？'; English: 'Are you sure you want to execute the operation?'; Japanese: '操作を実行してもよろしいですか？'),
    (Key: 'confirm_exit'; Chinese: '操作正在进行中，确定要退出吗？'; English: 'Operation is in progress. Are you sure you want to exit?'; Japanese: '操作が進行中です。終了してもよろしいですか？'),
    (Key: 'select_source_title'; Chinese: '选择源目录'; English: 'Select Source Directory'; Japanese: 'ソースディレクトリを選択'),
    (Key: 'select_target_title'; Chinese: '选择目标目录'; English: 'Select Target Directory'; Japanese: 'ターゲットディレクトリを選択'),
    (Key: 'select_source_root_title'; Chinese: '选择源根目录'; English: 'Select Source Root Directory'; Japanese: 'ソースルートディレクトリを選択'),
    (Key: 'select_target_root_title'; Chinese: '选择目标根目录'; English: 'Select Target Root Directory'; Japanese: 'ターゲットルートディレクトリを選択'),

    // 其他
    (Key: 'directory_suffix'; Chinese: ' [目录]'; English: ' [DIR]'; Japanese: ' [ディレクトリ]'),
    (Key: 'target_created'; Chinese: '已创建目标目录: '; English: 'Target directory created: '; Japanese: 'ターゲットディレクトリが作成されました: '),
    (Key: 'target_create_failed'; Chinese: '创建目标目录失败: '; English: 'Failed to create target directory: '; Japanese: 'ターゲットディレクトリの作成に失敗しました: '),
    (Key: 'source_root_set'; Chinese: '源根目录已设置: '; English: 'Source root directory set: '; Japanese: 'ソースルートディレクトリが設定されました: '),
    (Key: 'target_root_set'; Chinese: '目标根目录已设置: '; English: 'Target root directory set: '; Japanese: 'ターゲットルートディレクトリが設定されました: '),
    (Key: 'status_source'; Chinese: '源目录: '; English: 'Source: '; Japanese: 'ソース: '),
    (Key: 'status_target'; Chinese: '目标目录: '; English: 'Target: '; Japanese: 'ターゲット: '),
    (Key: 'status_not_selected'; Chinese: '未选择'; English: 'Not selected'; Japanese: '未選択'),

    // 结束标记
    (Key: ''; Chinese: ''; English: ''; Japanese: '')
  );

// 国际化函数实现
function _(const AKey: string): string;
begin
  Result := GetString(AKey, CurrentLanguage);
end;

function GetString(const AKey: string; ALang: TLanguageType): string;
var
  I: Integer;
begin
  Result := AKey; // 默认返回键值

  for I := Low(LanguageStrings) to High(LanguageStrings) do
  begin
    if LanguageStrings[I].Key = AKey then
    begin
      case ALang of
        ltChinese: Result := LanguageStrings[I].Chinese;
        ltEnglish: Result := LanguageStrings[I].English;
        ltJapanese: Result := LanguageStrings[I].Japanese;
      end;
      Break;
    end;
  end;
end;

end.

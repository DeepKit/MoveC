unit uConstants;

{
  单元名称: uConstants
  功能描述: 应用程序常量定义，集中管理配置值
  作者: MoveC Team
  创建日期: 2025-12-01
  
  使用说明:
  - 所有魔法数字应定义在此处
  - 按功能模块分组组织常量
  - 常量名使用 UPPER_CASE_WITH_UNDERSCORES 格式
}

interface

const
  //============================================================================
  // 应用程序信息
  //============================================================================
  APP_NAME = 'C盘瘦身神器';
  APP_VERSION = '1.2.0';
  APP_AUTHOR = 'MoveC Team';
  APP_COPYRIGHT = '版权所有 © 2024-2025';
  APP_WEBSITE = 'http://www.goodmem.cn';
  
  //============================================================================
  // 定时器间隔 (毫秒)
  //============================================================================
  HEARTBEAT_INTERVAL_MS = 60000;         // 心跳检查间隔：60秒
  PROGRESS_UPDATE_INTERVAL_MS = 500;     // 进度更新间隔：500毫秒
  AUTO_FLUSH_INTERVAL_SEC = 30;          // 日志自动刷新间隔：30秒
  DEBOUNCE_INTERVAL_MS = 2000;           // 文件监控防抖间隔：2秒
  REALTIME_WATCH_INTERVAL_MS = 500;      // 实时监控间隔：500毫秒
  LINK_CREATE_WAIT_MS = 1000;            // 链接创建后等待时间：1秒
  
  //============================================================================
  // 文件操作
  //============================================================================
  FILE_COPY_BUFFER_SIZE = 65536;         // 文件复制缓冲区：64KB
  SAMPLE_HASH_SIZE = 1048576;            // 抽样哈希大小：1MB
  QUICK_HASH_SIZE = 65536;               // 快速哈希大小：64KB
  MAX_DIRECTORY_ITEMS = 500;             // 目录树最大显示项数
  MAX_FILE_RETRY_COUNT = 3;              // 文件操作最大重试次数
  
  //============================================================================
  // 日志配置
  //============================================================================
  DEFAULT_LOG_MAX_FILE_SIZE = 10485760;  // 日志文件最大大小：10MB
  DEFAULT_LOG_MAX_FILES = 5;             // 最大日志文件数
  DEFAULT_LOG_CACHE_SIZE = 1000;         // 日志缓存条目数
  
  //============================================================================
  // UI 配置
  //============================================================================
  DEFAULT_ABOUTME_PANEL_HEIGHT = 250;    // AboutMe面板默认高度
  DEFAULT_ABOUTME_FRAME_WIDTH = 640;     // AboutMe框架默认宽度
  DEFAULT_MIN_PANEL_HEIGHT = 200;        // 面板最小高度
  
  //============================================================================
  // 安全边际
  //============================================================================
  DISK_SPACE_SAFETY_MARGIN = 1.1;        // 磁盘空间安全边际：110%
  
  //============================================================================
  // 服务控制
  //============================================================================
  SERVICE_STOP_TIMEOUT_MS = 15000;       // 服务停止超时：15秒
  SERVICE_START_TIMEOUT_MS = 15000;      // 服务启动超时：15秒
  SERVICE_POLL_INTERVAL_MS = 200;        // 服务状态轮询间隔：200毫秒
  
  //============================================================================
  // 系统路径 (请使用 GetSystemPath 函数获取动态路径)
  //============================================================================
  WINDOWS_UPDATE_CACHE_SUBPATH = 'Windows\SoftwareDistribution\Download';
  WINDOWS_TEMP_SUBPATH = 'Windows\Temp';
  WINDOWS_PREFETCH_SUBPATH = 'Windows\Prefetch';
  WINDOWS_LOGS_SUBPATH = 'Windows\Logs';
  
  //============================================================================
  // 数据库
  //============================================================================
  DEFAULT_DB_NAME_MOVEC = 'MoveC.db';
  TRANSACTION_DIR_NAME = 'Transactions';
  LOGS_DIR_NAME = 'Logs';
  
  //============================================================================
  // 文件类型过滤
  //============================================================================
  TEMP_FILE_EXTENSIONS: array[0..5] of string = (
    '.tmp', '.temp', '.log', '.cache', '.bak', '.old'
  );
  
  IMAGE_FILE_EXTENSIONS: array[0..5] of string = (
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff'
  );
  
  DOCUMENT_FILE_EXTENSIONS: array[0..4] of string = (
    '.doc', '.docx', '.pdf', '.txt', '.rtf'
  );

  //============================================================================
  // Material Design 配色
  //============================================================================
  COLOR_BLUE_GREY_50 = $ECEFF1;
  COLOR_GREY_50 = $FAFAFA;
  COLOR_GREY_100 = $F5F5F5;
  COLOR_BLUE_50 = $E3F2FD;
  COLOR_BLUE_GREY_900 = $263238;
  COLOR_GREEN_500 = $4CAF50;
  COLOR_BLUE_500 = $2196F3;
  COLOR_ORANGE_500 = $FF9800;
  COLOR_RED_500 = $F44336;
  COLOR_TEAL_500 = $009688;
  COLOR_CYAN_500 = $00BCD4;
  COLOR_INDIGO_500 = $3F51B5;
  COLOR_BLUE_GREY_500 = $607D8B;
  COLOR_BROWN_500 = $795548;

/// <summary>获取系统特殊目录路径</summary>
function GetSystemDrivePath: string;
function GetWindowsTempPath: string;
function GetUserTempPath: string;
function GetRecycleBinPath: string;
function GetWindowsUpdateCachePath: string;
function GetPrefetchPath: string;
function GetSystemLogsPath: string;

implementation

uses
  Winapi.Windows, Winapi.ShlObj, System.SysUtils, System.IOUtils;

function GetSystemDrivePath: string;
begin
  Result := GetEnvironmentVariable('SystemDrive');
  if Result = '' then
    Result := 'C:';
end;

function GetWindowsTempPath: string;
begin
  Result := TPath.Combine(GetSystemDrivePath, WINDOWS_TEMP_SUBPATH);
end;

function GetUserTempPath: string;
var
  TempDir: array[0..MAX_PATH] of Char;
begin
  Winapi.Windows.GetTempPath(MAX_PATH, TempDir);
  Result := string(TempDir);
end;

function GetRecycleBinPath: string;
begin
  // Windows 回收站路径
  Result := TPath.Combine(GetSystemDrivePath, '$Recycle.Bin');
  if not TDirectory.Exists(Result) then
    Result := TPath.Combine(GetSystemDrivePath, 'RECYCLER');  // 旧版 Windows
end;

function GetWindowsUpdateCachePath: string;
begin
  Result := TPath.Combine(GetSystemDrivePath, WINDOWS_UPDATE_CACHE_SUBPATH);
end;

function GetPrefetchPath: string;
begin
  Result := TPath.Combine(GetSystemDrivePath, WINDOWS_PREFETCH_SUBPATH);
end;

function GetSystemLogsPath: string;
begin
  Result := TPath.Combine(GetSystemDrivePath, WINDOWS_LOGS_SUBPATH);
end;

end.

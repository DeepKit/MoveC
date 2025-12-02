unit uFriendlyErrors;

{
  友好错误提示模块 - Friendly Error Messages
  
  功能：
  - 统一管理错误消息
  - 为每种错误提供明确的原因和解决建议
  - 支持错误代码系统
  - 多语言支持预留
  
  作者: MoveC Team
  版本: 1.0
  日期: 2025-12-02
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Dialogs, Vcl.Forms;

type
  // 错误类别
  TErrorCategory = (
    ecGeneral,        // 通用错误
    ecFileSystem,     // 文件系统
    ecPermission,     // 权限问题
    ecDiskSpace,      // 磁盘空间
    ecNetwork,        // 网络相关
    ecDatabase,       // 数据库
    ecConfiguration,  // 配置
    ecSecurity,       // 安全相关
    ecMigration,      // 迁移操作
    ecCleanup,        // 清理操作
    ecSystem          // 系统级
  );
  
  // 错误严重程度
  TErrorSeverity = (
    esInfo,           // 信息
    esWarning,        // 警告
    esError,          // 错误
    esCritical        // 严重
  );
  
  // 友好错误信息
  TFriendlyError = record
    Code: string;           // 错误代码 (如 MC-FS-001)
    Category: TErrorCategory;
    Severity: TErrorSeverity;
    Title: string;          // 错误标题
    Message: string;        // 错误详情
    Reason: string;         // 可能原因
    Solution: string;       // 解决建议
    TechDetail: string;     // 技术细节（可选）
    HelpURL: string;        // 帮助链接（可选）
  end;
  
  TFriendlyErrorHelper = class
  private
    class var FErrors: TDictionary<string, TFriendlyError>;
    class procedure InitializeErrors;
    class function GetCategoryName(ACategory: TErrorCategory): string;
    class function GetSeverityIcon(ASeverity: TErrorSeverity): string;
  public
    class constructor Create;
    class destructor Destroy;
    
    // 注册错误
    class procedure RegisterError(const ACode, ATitle, AMessage, AReason, ASolution: string;
      ACategory: TErrorCategory = ecGeneral; ASeverity: TErrorSeverity = esError);
    
    // 获取友好错误信息
    class function GetError(const ACode: string): TFriendlyError;
    class function GetErrorByException(E: Exception): TFriendlyError;
    class function GetErrorByWinError(AWinError: Integer): TFriendlyError;
    
    // 显示友好错误
    class procedure ShowError(const ACode: string; const ATechDetail: string = '');
    class procedure ShowErrorEx(const AError: TFriendlyError);
    class procedure ShowException(E: Exception; const AContext: string = '');
    
    // 格式化错误消息
    class function FormatErrorMessage(const AError: TFriendlyError; AShowTechDetail: Boolean = False): string;
    class function FormatSimpleMessage(const ACode: string): string;
    
    // 辅助函数
    class function AnalyzeException(E: Exception): string;
    class function GetDiskSpaceAdvice(const ADrive: Char): string;
    class function GetPermissionAdvice: string;
  end;

// 全局快捷函数
procedure ShowFriendlyError(const ACode: string; const ATechDetail: string = '');
procedure ShowFriendlyException(E: Exception; const AContext: string = '');
function FormatFriendlyError(const ACode: string): string;

// 常用错误代码
const
  // 文件系统错误 (MC-FS-xxx)
  ERR_FILE_NOT_FOUND      = 'MC-FS-001';
  ERR_DIR_NOT_FOUND       = 'MC-FS-002';
  ERR_FILE_IN_USE         = 'MC-FS-003';
  ERR_DIR_IN_USE          = 'MC-FS-004';
  ERR_PATH_TOO_LONG       = 'MC-FS-005';
  ERR_INVALID_PATH        = 'MC-FS-006';
  ERR_FILE_EXISTS         = 'MC-FS-007';
  ERR_DIR_NOT_EMPTY       = 'MC-FS-008';
  ERR_COPY_FAILED         = 'MC-FS-009';
  ERR_DELETE_FAILED       = 'MC-FS-010';
  ERR_MOVE_FAILED         = 'MC-FS-011';
  ERR_RENAME_FAILED       = 'MC-FS-012';
  
  // 权限错误 (MC-PM-xxx)
  ERR_ACCESS_DENIED       = 'MC-PM-001';
  ERR_ADMIN_REQUIRED      = 'MC-PM-002';
  ERR_READONLY_FILE       = 'MC-PM-003';
  ERR_SYSTEM_FILE         = 'MC-PM-004';
  
  // 磁盘空间 (MC-DS-xxx)
  ERR_DISK_FULL           = 'MC-DS-001';
  ERR_DISK_SPACE_LOW      = 'MC-DS-002';
  ERR_QUOTA_EXCEEDED      = 'MC-DS-003';
  
  // 迁移错误 (MC-MG-xxx)
  ERR_MIGRATION_FAILED    = 'MC-MG-001';
  ERR_JUNCTION_FAILED     = 'MC-MG-002';
  ERR_BACKUP_FAILED       = 'MC-MG-003';
  ERR_ROLLBACK_FAILED     = 'MC-MG-004';
  ERR_VERIFY_FAILED       = 'MC-MG-005';
  ERR_SOURCE_INVALID      = 'MC-MG-006';
  ERR_TARGET_INVALID      = 'MC-MG-007';
  
  // 清理错误 (MC-CL-xxx)
  ERR_CLEANUP_PARTIAL     = 'MC-CL-001';
  ERR_CLEANUP_SKIP        = 'MC-CL-002';
  ERR_RECYCLE_BIN_FAILED  = 'MC-CL-003';
  
  // 数据库错误 (MC-DB-xxx)
  ERR_DB_CONNECT_FAILED   = 'MC-DB-001';
  ERR_DB_QUERY_FAILED     = 'MC-DB-002';
  ERR_DB_CORRUPT          = 'MC-DB-003';
  
  // 配置错误 (MC-CF-xxx)
  ERR_CONFIG_LOAD_FAILED  = 'MC-CF-001';
  ERR_CONFIG_SAVE_FAILED  = 'MC-CF-002';
  ERR_CONFIG_INVALID      = 'MC-CF-003';
  
  // 安全错误 (MC-SC-xxx)
  ERR_TAMPER_DETECTED     = 'MC-SC-001';
  ERR_SIGNATURE_INVALID   = 'MC-SC-002';
  ERR_DECRYPT_FAILED      = 'MC-SC-003';
  
  // 系统错误 (MC-SY-xxx)
  ERR_SYSTEM_CRITICAL     = 'MC-SY-001';
  ERR_MEMORY_LOW          = 'MC-SY-002';
  ERR_SERVICE_UNAVAILABLE = 'MC-SY-003';

implementation

uses
  Winapi.Windows, Vcl.Controls;

{ TFriendlyErrorHelper }

class constructor TFriendlyErrorHelper.Create;
begin
  FErrors := TDictionary<string, TFriendlyError>.Create;
  InitializeErrors;
end;

class destructor TFriendlyErrorHelper.Destroy;
begin
  FErrors.Free;
end;

class procedure TFriendlyErrorHelper.InitializeErrors;
begin
  // 文件系统错误
  RegisterError(ERR_FILE_NOT_FOUND, '文件不存在',
    '无法找到指定的文件。',
    '文件可能已被删除、移动或重命名。',
    '请检查文件路径是否正确，或使用搜索功能定位文件。',
    ecFileSystem, esError);
    
  RegisterError(ERR_DIR_NOT_FOUND, '目录不存在',
    '无法找到指定的目录。',
    '目录可能已被删除或移动。',
    '请检查目录路径是否正确，必要时重新创建目录。',
    ecFileSystem, esError);
    
  RegisterError(ERR_FILE_IN_USE, '文件被占用',
    '文件正在被其他程序使用，无法操作。',
    '另一个程序正在使用此文件，如 Office、浏览器、杀毒软件等。',
    '请关闭正在使用该文件的程序后重试。可以使用任务管理器查看哪些程序在使用该文件。',
    ecFileSystem, esWarning);
    
  RegisterError(ERR_DIR_IN_USE, '目录被占用',
    '目录中的文件正在被其他程序使用。',
    '该目录下有文件正在被打开或使用。',
    '请关闭所有使用该目录文件的程序，或重启资源管理器后重试。',
    ecFileSystem, esWarning);
    
  RegisterError(ERR_PATH_TOO_LONG, '路径过长',
    '文件或目录路径超出系统限制（260字符）。',
    'Windows 传统路径长度限制为 260 个字符。',
    '尝试将文件移动到路径较短的位置，或启用 Windows 长路径支持。',
    ecFileSystem, esError);
    
  RegisterError(ERR_INVALID_PATH, '路径无效',
    '指定的路径格式不正确。',
    '路径中包含非法字符或格式错误。',
    '请检查路径是否包含 < > : " | ? * 等非法字符。',
    ecFileSystem, esError);
    
  RegisterError(ERR_FILE_EXISTS, '文件已存在',
    '目标位置已存在同名文件。',
    '目标文件夹中已有相同名称的文件。',
    '请选择覆盖、重命名或取消操作。',
    ecFileSystem, esWarning);
    
  RegisterError(ERR_DIR_NOT_EMPTY, '目录非空',
    '目录不为空，无法删除。',
    '目录中仍有文件或子目录。',
    '请先清空目录内容，或选择递归删除。',
    ecFileSystem, esWarning);
    
  RegisterError(ERR_COPY_FAILED, '复制失败',
    '文件复制操作失败。',
    '可能是磁盘空间不足、文件被占用或权限不够。',
    '请检查目标磁盘空间、关闭占用的程序，或以管理员身份运行。',
    ecFileSystem, esError);
    
  RegisterError(ERR_DELETE_FAILED, '删除失败',
    '无法删除指定的文件或目录。',
    '文件可能被占用、受系统保护或权限不足。',
    '请关闭占用的程序，确认不是系统文件，或以管理员身份运行。',
    ecFileSystem, esError);
    
  RegisterError(ERR_MOVE_FAILED, '移动失败',
    '无法移动文件或目录。',
    '源文件被占用、目标位置权限不足或磁盘空间不够。',
    '请关闭占用的程序，检查目标位置权限和磁盘空间。',
    ecFileSystem, esError);
    
  RegisterError(ERR_RENAME_FAILED, '重命名失败',
    '无法重命名文件或目录。',
    '文件被占用或新名称已存在。',
    '请关闭占用的程序，确保新名称不与现有文件冲突。',
    ecFileSystem, esError);
  
  // 权限错误
  RegisterError(ERR_ACCESS_DENIED, '访问被拒绝',
    '没有权限访问指定的文件或目录。',
    '当前用户权限不足，或文件/目录受保护。',
    '请以管理员身份运行程序，或检查文件/目录的安全设置。',
    ecPermission, esError);
    
  RegisterError(ERR_ADMIN_REQUIRED, '需要管理员权限',
    '此操作需要管理员权限才能执行。',
    '操作涉及系统目录或需要更高权限。',
    '请右键点击程序，选择"以管理员身份运行"。',
    ecPermission, esWarning);
    
  RegisterError(ERR_READONLY_FILE, '只读文件',
    '文件设置为只读，无法修改。',
    '文件属性被设置为只读。',
    '请在文件属性中取消"只读"勾选后重试。',
    ecPermission, esWarning);
    
  RegisterError(ERR_SYSTEM_FILE, '系统文件保护',
    '此为系统关键文件，操作被阻止。',
    '为保护系统稳定性，关键系统文件不允许修改或删除。',
    '请勿尝试修改系统文件，这可能导致系统无法启动。',
    ecPermission, esCritical);
  
  // 磁盘空间错误
  RegisterError(ERR_DISK_FULL, '磁盘空间已满',
    '目标磁盘没有足够的可用空间。',
    '磁盘可用空间不足以完成操作。',
    '请清理磁盘空间后重试。可以使用本软件的清理功能释放空间。',
    ecDiskSpace, esError);
    
  RegisterError(ERR_DISK_SPACE_LOW, '磁盘空间不足',
    '磁盘剩余空间较低，操作可能失败。',
    '虽然有一定空间，但可能不够完成操作。',
    '建议先清理一些不必要的文件，确保有足够空间。',
    ecDiskSpace, esWarning);
    
  RegisterError(ERR_QUOTA_EXCEEDED, '超出配额',
    '已超出磁盘配额限制。',
    '您的账户已达到管理员设置的磁盘使用上限。',
    '请联系系统管理员增加配额，或删除不需要的文件。',
    ecDiskSpace, esError);
  
  // 迁移错误
  RegisterError(ERR_MIGRATION_FAILED, '迁移失败',
    '目录迁移操作未能完成。',
    '可能是文件被占用、权限不足或磁盘空间不够。',
    '请检查日志获取详细错误，解决问题后重试。已有更改将自动回滚。',
    ecMigration, esError);
    
  RegisterError(ERR_JUNCTION_FAILED, '创建链接失败',
    '无法创建目录联接（Junction）。',
    '可能是权限不足或目标路径问题。',
    '请确保以管理员身份运行，且源目录不存在。',
    ecMigration, esError);
    
  RegisterError(ERR_BACKUP_FAILED, '备份失败',
    '无法备份原目录。',
    '原目录可能被占用或磁盘空间不足。',
    '请关闭使用该目录的程序，确保有足够磁盘空间。',
    ecMigration, esError);
    
  RegisterError(ERR_ROLLBACK_FAILED, '回滚失败',
    '无法恢复到迁移前的状态。',
    '备份目录可能被删除或损坏。',
    '请手动检查备份目录（位于迁移记录中），尝试手动恢复。',
    ecMigration, esCritical);
    
  RegisterError(ERR_VERIFY_FAILED, '文件校验失败',
    '部分文件在复制后校验不匹配。',
    '文件在复制过程中可能损坏。',
    '请检查日志中列出的失败文件，必要时重新迁移。',
    ecMigration, esWarning);
    
  RegisterError(ERR_SOURCE_INVALID, '源目录无效',
    '指定的源目录不存在或无法访问。',
    '目录可能已被删除或路径错误。',
    '请检查源目录路径，确保目录存在且可访问。',
    ecMigration, esError);
    
  RegisterError(ERR_TARGET_INVALID, '目标目录无效',
    '指定的目标位置无效。',
    '目标驱动器不存在或路径格式错误。',
    '请选择有效的目标位置，确保目标驱动器可用。',
    ecMigration, esError);
  
  // 清理错误
  RegisterError(ERR_CLEANUP_PARTIAL, '部分清理失败',
    '清理操作部分完成，有些文件无法删除。',
    '某些文件被占用或权限不足。',
    '您可以稍后再次运行清理，或手动删除这些文件。',
    ecCleanup, esWarning);
    
  RegisterError(ERR_CLEANUP_SKIP, '清理被跳过',
    '清理操作被跳过。',
    '可能是目标不存在或无需清理。',
    '这通常不是问题，表示该项目已是干净状态。',
    ecCleanup, esInfo);
    
  RegisterError(ERR_RECYCLE_BIN_FAILED, '清空回收站失败',
    '无法完全清空回收站。',
    '回收站中可能有被占用的文件。',
    '请关闭可能占用回收站文件的程序后重试。',
    ecCleanup, esWarning);
  
  // 数据库错误
  RegisterError(ERR_DB_CONNECT_FAILED, '数据库连接失败',
    '无法连接到本地数据库。',
    '数据库文件可能损坏或被占用。',
    '请确保程序目录下的数据库文件完整，或重新安装程序。',
    ecDatabase, esError);
    
  RegisterError(ERR_DB_QUERY_FAILED, '数据库查询失败',
    '执行数据库操作时出错。',
    '可能是数据库结构不兼容或文件损坏。',
    '请尝试重启程序。如问题持续，请备份数据后重新安装。',
    ecDatabase, esError);
    
  RegisterError(ERR_DB_CORRUPT, '数据库损坏',
    '数据库文件已损坏，无法读取。',
    '可能是程序异常退出或存储设备故障。',
    '请删除损坏的数据库文件，程序将自动创建新数据库。历史记录将丢失。',
    ecDatabase, esCritical);
  
  // 配置错误
  RegisterError(ERR_CONFIG_LOAD_FAILED, '加载配置失败',
    '无法读取程序配置文件。',
    '配置文件可能不存在或格式错误。',
    '程序将使用默认设置。您可以在设置中重新配置。',
    ecConfiguration, esWarning);
    
  RegisterError(ERR_CONFIG_SAVE_FAILED, '保存配置失败',
    '无法保存程序配置。',
    '可能是程序目录没有写入权限。',
    '请确保程序目录有写入权限，或以管理员身份运行。',
    ecConfiguration, esWarning);
    
  RegisterError(ERR_CONFIG_INVALID, '配置无效',
    '配置文件包含无效设置。',
    '配置文件格式错误或版本不兼容。',
    '程序将重置为默认设置。建议删除配置文件后重启。',
    ecConfiguration, esWarning);
  
  // 安全错误
  RegisterError(ERR_TAMPER_DETECTED, '检测到篡改',
    '程序文件完整性校验失败。',
    '程序文件可能被修改或病毒感染。',
    '请从官方渠道重新下载程序，并使用杀毒软件扫描系统。',
    ecSecurity, esCritical);
    
  RegisterError(ERR_SIGNATURE_INVALID, '签名验证失败',
    '文件数字签名无效。',
    '文件可能被修改或来源不可信。',
    '请确保从官方渠道获取文件。',
    ecSecurity, esCritical);
    
  RegisterError(ERR_DECRYPT_FAILED, '解密失败',
    '无法解密受保护的数据。',
    '密钥不匹配或数据已损坏。',
    '请确保使用正确版本的程序。如问题持续，请联系技术支持。',
    ecSecurity, esError);
  
  // 系统错误
  RegisterError(ERR_SYSTEM_CRITICAL, '系统关键错误',
    '发生严重系统错误。',
    '可能是系统资源不足或严重故障。',
    '请保存工作并重启计算机。如问题持续，请检查系统日志。',
    ecSystem, esCritical);
    
  RegisterError(ERR_MEMORY_LOW, '内存不足',
    '系统可用内存过低。',
    '运行的程序过多，占用了大量内存。',
    '请关闭不需要的程序释放内存，或增加虚拟内存。',
    ecSystem, esWarning);
    
  RegisterError(ERR_SERVICE_UNAVAILABLE, '服务不可用',
    '所需的系统服务未运行。',
    '必要的 Windows 服务已停止或禁用。',
    '请检查并启用相关的 Windows 服务。',
    ecSystem, esError);
end;

class procedure TFriendlyErrorHelper.RegisterError(const ACode, ATitle, AMessage, AReason, ASolution: string;
  ACategory: TErrorCategory; ASeverity: TErrorSeverity);
var
  Error: TFriendlyError;
begin
  Error.Code := ACode;
  Error.Title := ATitle;
  Error.Message := AMessage;
  Error.Reason := AReason;
  Error.Solution := ASolution;
  Error.Category := ACategory;
  Error.Severity := ASeverity;
  Error.TechDetail := '';
  Error.HelpURL := '';
  
  FErrors.AddOrSetValue(ACode, Error);
end;

class function TFriendlyErrorHelper.GetError(const ACode: string): TFriendlyError;
begin
  if not FErrors.TryGetValue(ACode, Result) then
  begin
    // 返回通用错误
    Result.Code := ACode;
    Result.Title := '未知错误';
    Result.Message := '发生了一个未预期的错误。';
    Result.Reason := '错误原因未知。';
    Result.Solution := '请重试操作。如问题持续，请联系技术支持并提供错误代码：' + ACode;
    Result.Category := ecGeneral;
    Result.Severity := esError;
  end;
end;

class function TFriendlyErrorHelper.GetErrorByException(E: Exception): TFriendlyError;
var
  Msg: string;
begin
  Msg := E.Message.ToLower;
  
  // 根据异常消息匹配错误类型
  if E is EInOutError then
  begin
    if Pos('access denied', Msg) > 0 then
      Result := GetError(ERR_ACCESS_DENIED)
    else if Pos('file not found', Msg) > 0 then
      Result := GetError(ERR_FILE_NOT_FOUND)
    else if Pos('disk full', Msg) > 0 then
      Result := GetError(ERR_DISK_FULL)
    else
      Result := GetError(ERR_FILE_IN_USE);
  end
  else if E is EAccessViolation then
    Result := GetError(ERR_SYSTEM_CRITICAL)
  else if E is EOutOfMemory then
    Result := GetError(ERR_MEMORY_LOW)
  else
  begin
    // 通过消息内容分析
    if (Pos('拒绝访问', Msg) > 0) or (Pos('access denied', Msg) > 0) then
      Result := GetError(ERR_ACCESS_DENIED)
    else if (Pos('空间不足', Msg) > 0) or (Pos('disk full', Msg) > 0) then
      Result := GetError(ERR_DISK_FULL)
    else if (Pos('正在使用', Msg) > 0) or (Pos('in use', Msg) > 0) or (Pos('占用', Msg) > 0) then
      Result := GetError(ERR_FILE_IN_USE)
    else if (Pos('找不到', Msg) > 0) or (Pos('not found', Msg) > 0) or (Pos('不存在', Msg) > 0) then
      Result := GetError(ERR_FILE_NOT_FOUND)
    else if (Pos('路径', Msg) > 0) and (Pos('长', Msg) > 0) then
      Result := GetError(ERR_PATH_TOO_LONG)
    else
    begin
      // 默认错误
      Result.Code := 'MC-EX-000';
      Result.Title := '操作失败';
      Result.Message := E.Message;
      Result.Reason := '发生了一个异常。';
      Result.Solution := '请查看详细错误信息，尝试解决后重试。';
      Result.Category := ecGeneral;
      Result.Severity := esError;
    end;
  end;
  
  Result.TechDetail := E.ClassName + ': ' + E.Message;
end;

class function TFriendlyErrorHelper.GetErrorByWinError(AWinError: Integer): TFriendlyError;
begin
  case AWinError of
    ERROR_FILE_NOT_FOUND:
      Result := GetError(ERR_FILE_NOT_FOUND);
    ERROR_PATH_NOT_FOUND:
      Result := GetError(ERR_DIR_NOT_FOUND);
    ERROR_ACCESS_DENIED:
      Result := GetError(ERR_ACCESS_DENIED);
    ERROR_SHARING_VIOLATION, ERROR_LOCK_VIOLATION:
      Result := GetError(ERR_FILE_IN_USE);
    ERROR_DISK_FULL:
      Result := GetError(ERR_DISK_FULL);
    ERROR_HANDLE_DISK_FULL:
      Result := GetError(ERR_DISK_FULL);
    ERROR_NOT_ENOUGH_MEMORY:
      Result := GetError(ERR_MEMORY_LOW);
    ERROR_INVALID_NAME, ERROR_INVALID_PARAMETER:
      Result := GetError(ERR_INVALID_PATH);
  else
    begin
      Result.Code := Format('MC-WIN-%d', [AWinError]);
      Result.Title := '系统错误';
      Result.Message := SysErrorMessage(AWinError);
      Result.Reason := Format('Windows 错误代码: %d', [AWinError]);
      Result.Solution := '请搜索该错误代码获取更多帮助。';
      Result.Category := ecSystem;
      Result.Severity := esError;
    end;
  end;
end;

class function TFriendlyErrorHelper.GetCategoryName(ACategory: TErrorCategory): string;
begin
  case ACategory of
    ecFileSystem: Result := '文件系统';
    ecPermission: Result := '权限';
    ecDiskSpace: Result := '磁盘空间';
    ecNetwork: Result := '网络';
    ecDatabase: Result := '数据库';
    ecConfiguration: Result := '配置';
    ecSecurity: Result := '安全';
    ecMigration: Result := '迁移';
    ecCleanup: Result := '清理';
    ecSystem: Result := '系统';
  else
    Result := '通用';
  end;
end;

class function TFriendlyErrorHelper.GetSeverityIcon(ASeverity: TErrorSeverity): string;
begin
  case ASeverity of
    esInfo: Result := 'ℹ️';
    esWarning: Result := '⚠️';
    esError: Result := '❌';
    esCritical: Result := '🚨';
  else
    Result := '';
  end;
end;

class function TFriendlyErrorHelper.FormatErrorMessage(const AError: TFriendlyError;
  AShowTechDetail: Boolean): string;
var
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine(AError.Message);
    SB.AppendLine;
    
    SB.AppendLine('【可能原因】');
    SB.AppendLine(AError.Reason);
    SB.AppendLine;
    
    SB.AppendLine('【解决建议】');
    SB.AppendLine(AError.Solution);
    
    if AShowTechDetail and (AError.TechDetail <> '') then
    begin
      SB.AppendLine;
      SB.AppendLine('【技术详情】');
      SB.AppendLine(AError.TechDetail);
    end;
    
    SB.AppendLine;
    SB.Append('错误代码: ' + AError.Code);
    
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

class function TFriendlyErrorHelper.FormatSimpleMessage(const ACode: string): string;
var
  Error: TFriendlyError;
begin
  Error := GetError(ACode);
  Result := Error.Title + ': ' + Error.Message;
end;

class procedure TFriendlyErrorHelper.ShowError(const ACode: string; const ATechDetail: string);
var
  Error: TFriendlyError;
begin
  Error := GetError(ACode);
  Error.TechDetail := ATechDetail;
  ShowErrorEx(Error);
end;

class procedure TFriendlyErrorHelper.ShowErrorEx(const AError: TFriendlyError);
var
  DlgType: TMsgDlgType;
  Msg: string;
begin
  case AError.Severity of
    esInfo: DlgType := mtInformation;
    esWarning: DlgType := mtWarning;
    esCritical: DlgType := mtError;
  else
    DlgType := mtError;
  end;
  
  Msg := FormatErrorMessage(AError, AError.TechDetail <> '');
  
  MessageDlg(Msg, DlgType, [mbOK], 0);
end;

class procedure TFriendlyErrorHelper.ShowException(E: Exception; const AContext: string);
var
  Error: TFriendlyError;
begin
  Error := GetErrorByException(E);
  
  if AContext <> '' then
    Error.TechDetail := AContext + sLineBreak + Error.TechDetail;
    
  ShowErrorEx(Error);
end;

class function TFriendlyErrorHelper.AnalyzeException(E: Exception): string;
var
  Error: TFriendlyError;
begin
  Error := GetErrorByException(E);
  Result := Error.Code;
end;

class function TFriendlyErrorHelper.GetDiskSpaceAdvice(const ADrive: Char): string;
var
  FreeSpace, TotalSpace: Int64;
  FreeGB: Double;
begin
  Result := '';
  
  if GetDiskFreeSpaceEx(PChar(ADrive + ':\'), FreeSpace, TotalSpace, nil) then
  begin
    FreeGB := FreeSpace / (1024 * 1024 * 1024);
    
    if FreeGB < 1 then
      Result := Format('%s 盘剩余空间不足 1 GB（仅 %.0f MB），建议立即清理。', 
        [ADrive, FreeSpace / (1024 * 1024)])
    else if FreeGB < 5 then
      Result := Format('%s 盘剩余空间较低（%.1f GB），建议清理释放空间。',
        [ADrive, FreeGB])
    else
      Result := Format('%s 盘剩余空间: %.1f GB', [ADrive, FreeGB]);
  end;
end;

class function TFriendlyErrorHelper.GetPermissionAdvice: string;
begin
  Result := '请尝试以下方法：' + sLineBreak +
            '1. 右键点击程序，选择"以管理员身份运行"' + sLineBreak +
            '2. 检查文件或目录的权限设置' + sLineBreak +
            '3. 确认您的用户账户有足够权限';
end;

// 全局快捷函数
procedure ShowFriendlyError(const ACode: string; const ATechDetail: string);
begin
  TFriendlyErrorHelper.ShowError(ACode, ATechDetail);
end;

procedure ShowFriendlyException(E: Exception; const AContext: string);
begin
  TFriendlyErrorHelper.ShowException(E, AContext);
end;

function FormatFriendlyError(const ACode: string): string;
begin
  Result := TFriendlyErrorHelper.FormatSimpleMessage(ACode);
end;

end.

unit ChineseConstants;

interface

// 中文字符串常量单元
// 使用Unicode转义序列确保正确编码

const
  // 应用程序基本信息
  APP_TITLE = #$0043#$76D8#$8D85#$7EA7#$6E05#$7406;  // C盘超级清理
  APP_VERSION = #$7248#$672C;  // 版本
  
  // 菜单项
  MENU_FILE = #$6587#$4EF6#$0028#$0026#$0046#$0029;  // 文件(&F)
  MENU_EXIT = #$9000#$51FA#$0028#$0026#$0058#$0029;  // 退出(&X)
  MENU_TOOLS = #$5DE5#$5177#$0028#$0026#$0054#$0029;  // 工具(&T)
  MENU_SYSTEM_CHECK = #$7CFB#$7EDF#$68C0#$67E5#$0028#$0026#$0053#$0029;  // 系统检查(&S)
  MENU_LANGUAGE = #$8BED#$8A00#$8BBE#$7F6E#$0028#$0026#$004C#$0029;  // 语言设置(&L)
  MENU_HELP = #$5E2E#$52A9#$0028#$0026#$0048#$0029;  // 帮助(&H)
  MENU_ABOUT = #$5173#$4E8E#$0028#$0026#$0041#$0029;  // 关于(&A)
  
  // 按钮文本
  BTN_COPY = #$590D#$5236#$6587#$4EF6;  // 复制文件
  BTN_DELETE = #$5220#$9664#$5E76#$94FE#$63A5;  // 删除并链接
  BTN_BACKUP = #$521B#$5EFA#$5907#$4EFD;  // 创建备份
  BTN_CANCEL = #$53D6#$6D88;  // 取消
  BTN_OK = #$786E#$5B9A;  // 确定
  BTN_YES = #$662F;  // 是
  BTN_NO = #$5426;  // 否
  BTN_CLOSE = #$5173#$95ED;  // 关闭
  
  // 标签页
  TAB_BACKUP = #$5907#$4EFD#$7BA1#$7406;  // 备份管理
  TAB_ABOUT = #$5173#$4E8E#$5F00#$53D1#$8005;  // 关于开发者
  
  // 状态信息
  STATUS_READY = #$5C31#$7EEA;  // 就绪
  STATUS_COPYING = #$6B63#$5728#$590D#$5236#$002E#$002E#$002E;  // 正在复制...
  STATUS_COMPLETE = #$64CD#$4F5C#$5B8C#$6210;  // 操作完成
  
  // 对话框
  PROGRESS_TITLE = #$64CD#$4F5C#$8FDB#$5EA6;  // 操作进度
  CONFIRM_DELETE = #$786E#$5B9A#$8981#$5220#$9664#$9009#$4E2D#$7684#$6587#$4EF6#$5417#$FF1F;  // 确定要删除选中的文件吗？
  LANGUAGE_CHANGED = #$8BED#$8A00#$8BBE#$7F6E#$5DF2#$66F4#$6539#$FF0C#$90E8#$5206#$754C#$9762#$5C06#$5728#$91CD#$542F#$540E#$751F#$6548#$3002;  // 语言设置已更改，部分界面将在重启后生效。
  
  // 其他
  DONATION_TITLE = #$652F#$6301#$5F00#$53D1#$8005;  // 支持开发者
  MACHINE_CODE = #$673A#$5668#$7801;  // 机器码
  
  // 错误信息
  ERROR_INIT_FAILED = #$521D#$59CB#$5316#$5931#$8D25;  // 初始化失败
  ERROR_FILE_NOT_FOUND = #$6587#$4EF6#$672A#$627E#$5230;  // 文件未找到
  ERROR_ACCESS_DENIED = #$8BBF#$95EE#$88AB#$62D2#$7EDD;  // 访问被拒绝
  ERROR_DISK_FULL = #$78C1#$76D8#$7A7A#$95F4#$4E0D#$8DB3;  // 磁盘空间不足
  
  // 成功信息
  SUCCESS_OPERATION_COMPLETE = #$64CD#$4F5C#$5B8C#$6210;  // 操作完成
  SUCCESS_FILE_COPIED = #$6587#$4EF6#$590D#$5236#$6210#$529F;  // 文件复制成功
  SUCCESS_BACKUP_CREATED = #$5907#$4EFD#$521B#$5EFA#$6210#$529F;  // 备份创建成功

implementation

end.

# MoveC 变更与里程碑（History）

更新时间：2025-12-02

## 2025-12-02 V1.2.0-Beta 发布准备完成

### 安全测试 ✅ 28/28 通过
- 关键路径保护验证（System32/Program Files/WinSxS/Boot等）
- 根目录保护验证（C:\/D:\）
- 用户目录保护验证（Users/Default/Public）
- 用户配置保护验证（Start Menu/Explorer/NTUSER.DAT）
- 清理目标安全验证（Temp/Prefetch/Cache/Logs）
- 测试脚本: `tests/Test-CleanupSafety.ps1`

### 双平台编译 ✅
- Win32: 6.98 MB (`Win32\Debug\C盘超级瘦身.exe`)
- Win64: 28.9 MB (`Win64\Debug\C盘超级瘦身.exe`)
- 编译器: dcc32.exe / dcc64.exe

### 文档更新 ✅
- README.md: 添加 V1.2.0-Beta 更新日志和新功能说明
- html/index.html: 更新版本号和功能卡片
- docs/用户手册.md: 完整用户手册（安装、功能、回滚、FAQ、安全说明）

### P1 应用关联检测 UI ✅
- 新增 pnlAppAssoc 面板，在源目录树下方显示关联应用信息
- 根据置信度用不同颜色标识（绿=高、橙=中、灰=低）
- 显示关联原因和测试建议

### P1 确认文案优化 ✅
- 迁移前确认：添加迁移步骤说明、安全提示、备份回滚说明
- 删除目录确认：添加风险提示、二次确认、不可撤销警告
- 清理备份确认：说明哪些备份会保留
- 取消操作确认：说明取消后清理已复制文件、源目录不受影响

### P2 批量迁移向导 ✅ (2025-12-02)
- uSmartMigrationWizard.pas 支持多目录选择 (CheckListBox)
- 内置4个迁移模板：文档组合、下载+桌面、开发环境缓存、游戏数据
- 批量分析和批量执行，单个失败不影响其他

### P2 大文件分析增强 ✅ (2025-12-02)
- uDiskAnalysis.pas 添加文件类型列
- 支持按大小/类型/日期筛选（最小MB参数）
- 点击列标题排序（升序/降序切换）

### P2 磁盘空间可视化 ✅ (2025-12-02)
- 饼图显示顶层目录占比
- 柱状图+图例显示各目录大小对比
- HTML报告导出功能

### P2 后台扫描 ✅ (2025-12-02)
- 使用 TTask 实现异步扫描，不阻塞UI
- 实时显示扫描进度（文件数/目录数）
- 支持取消扫描操作

### P2 回滚点管理 ✅ (2025-12-02)
- 新增 uRollbackManager.pas + dfm
- 支持查看所有迁移事务记录
- 支持回滚、删除、清理旧记录
- 集成到主菜单 工具 -> 回滚点管理

### P2 清理定时任务 ✅ (2025-12-02)
- 新增 uCleanupScheduler.pas
- 支持每天/每周/每月/启动时执行
- 可配置清理类型（回收站、临时文件、缓存等）
- 支持最小磁盘空间触发条件
- 任务配置持久化到 CleanupScheduler.ini

### P2 扫描结果缓存 ✅ (2025-12-02)
- 新增 uScanCache.pas
- 内存+磁盘两级缓存
- 基于目录修改时间判断缓存有效性
- 可配置过期时间和最大缓存条数
- 提供缓存命中率统计

### P2 自定义排除规则 ✅ (2025-12-02)
- 新增 uExclusionRules.pas
- 支持精确路径、通配符、正则、扩展名、大小、日期规则
- 内置系统关键目录保护规则
- 支持规则导入导出
- 规则按优先级排序匹配

### P2 HMAC-SHA256签名 ✅ (2025-12-02)
- 扩展 uFileHasher.pas
- 新增 ComputeHMACSHA256 方法
- 支持字节数组和文件的 HMAC 计算
- 新增 VerifyHMACSHA256 验证方法

### Bug修复
- uCleanupHistoryForm.pas: 修复 `Exchange` 方法不存在错误，改用 TArray.Sort
- uCleanupHistoryForm.pas: 添加 System.DateUtils 单元

---

## 2025-12-02 Phase 3 清理功能全部完成 + 历史查看 UI 新增

### Phase 3.1 服务控制 ✅
- 停止/恢复 Windows Update 相关服务（wuauserv/bits），在 Windows 更新缓存清理前后自动处理

### Phase 3.2 清理预览 ✅
- 新增 `uCleanupPreviewForm.pas`/DFM：
  - 预览列表支持排序（列点击切换 ASC/DESC）
  - 按风险过滤（默认隐藏高风险，勾选显示）
  - 默认勾选安全项，支持“全选/仅安全/全不选”
  - 执行清理前二次确认

### Phase 3.5 清理历史查看 UI ✅
- 新增 `uCleanupHistoryForm.pas`/DFM：
  - 列表展示清理历史（时间/类型/状态/删除文件/释放空间/耗时/错误）
  - 按类型筛选与列排序
  - 导出 TXT 报告与 JSON 历史

---

## 2025-12-01 代码质量重构与安全增强完成

### Phase 3.3 安全增强 ✅
**完成工作**:
- [x] 扩展 `IsSafeToDelete` 白名单（.tmp/.temp/.log/.cache/.bak 等 15+ 扩展名）
- [x] 允许的目录关键字：cache/temp/tmp/logs/thumbnails 等
- [x] 黑名单机制 `IsSystemCriticalPath`
  - Windows 系统目录（System32/SysWOW64/Boot/Fonts/WinSxS等）
  - 程序目录（Program Files等）
  - 用户关键配置（Start Menu/Recent/ntuser.dat等）
  - NTFS 系统文件（$MFT/$LogFile等）
  - 禁止删除根目录和用户根目录

### Phase 3.4 清理历史 ✅
**完成工作**:
- [x] 创建 `uCleanupHistory.pas` 清理历史管理模块（含 TCleanupType 枚举、TCleanupHistoryEntry、TCleanupHistoryManager）
- [x] 生成清理报告 JSON（cleanup_history.json）
- [x] 集成到 CleanRecycleBin/CleanTempFiles/CleanBackupFiles/CleanUpdateCache/btnSmartCleanClick

### Phase R1-R3 代码质量重构 ✅
**完成工作**:
- [x] **R1.1** 拆分 TfrmMain 巨型类 - 创建 `uMigrationService.pas`，定义 `IMigrationProgress` 接口和 `EMigrationException` 异常类
- [x] **R1.2** 移除调试代码残留 - 清理 FormShow 中的 AssignFile/WriteLn，使用 `{$IFDEF DEBUG}` 包裹
- [x] **R2.1** 统一异常处理策略 - 修复 HeartbeatCheck、资源检查中的空异常处理
- [x] **R2.2** 修复 TreeView 节点内存管理 - 实现 OnDeletion 事件自动释放 StrNew 分配的内存
- [x] **R2.3** 修复 TCleanupResult.Details 内存泄漏风险 - TStringList 改为 TArray<string>
- [x] **R3.1** 提取硬编码常量 - 创建 `uConstants.pas`，替换魔法数字和硬编码路径
- [x] **R3.2** 日志框架审查 - 确认 uLogger.pas 与 uLogManager.pas 分层设计合理

### UI/UX 改进 ✅
**完成工作**:
- [x] 去除 `uMain.pas` 中的状态消息 Emoji
- [x] DFM 文件使用 Unicode 转义，无 Emoji 问题
- [x] 统一日志接口（uLogger.pas）

### Bug 修复 ✅
- [x] uCleanupManager.pas: CRITICAL_PATHS 数组大小从 [0..24] 改为 [0..23]
- [x] uCleanupHistory.pas: 添加缺失的 System.Math, System.StrUtils 引用

---

## 2025-11-22 新增已完成任务归档

### Phase 2: 智能重复文件清理（已完成）
- **核心引擎完成**: `uSmartDuplicateCleanup.pas` - 三阶段扫描引擎（大小→部分哈希→全量哈希）
- **检测器模块**: `uDuplicateFileDetector.pas` - 并发哈希计算、进度报告、性能优化
- **UI界面完成**: `uDuplicateFiles.pas` + DFM - 重复文件组列表、文件详情、智能推荐算法
- **主菜单集成**: 在 `uMain.pas` 中添加重复文件清理菜单入口和事件处理
- **编译错误修复**: 补充了缺失的字段定义和类型声明，确保项目可编译

### 统一日志系统（已完成）
- **uLogger.pas**: 统一日志接口单元，支持Debug/Release模式自动切换
- **配置化日志**: 支持文件、调试器、控制台多种输出目标
- **线程安全**: 实现线程安全的日志记录和自动轮转
- **性能优化**: 缓存机制和批量处理提升性能

### UI优化初步完成（进行中）
- **Emoji移除**: 已在主菜单和右键菜单中去除Emoji，使用纯文本
- **样式统一**: 开始实施按钮字体和样式统一化
- **兼容性提升**: 避免低版本IDE/资源编译器的兼容性问题

## 2025-11-21 任务整理与归档
- 完成项目文档结构优化，已完成任务归档至 History
- 待办任务整理至 tasks.md，按优先级分类
- Bug修复记录已完整记录在 bugfix.md
- 文档整理与归档（从 tasks.md 迁移，已完成）

## 近期改动（自上次提交回退后）
- 同步并修复 `uDirectoryMigration.dfm` 与 PAS 声明结构。
- 为迁移列表 `clbMigrationItems` 增加右键菜单“删除源目录…”，删除到回收站（可撤回）。
- 恢复并补齐 `uSmartDuplicateCleanup.pas` 的最小可运行骨架：
  - 枚举文件、分阶段哈希（大小→部分哈希→全量哈希）分组重复。
  - 兼容旧编译器的哈希与集合写法；移除内联 var。
  - 基础清理流程（模拟项）与结果展示。

## 2025-11-18 已完成归档

### 已完成功能与里程碑
- 基本清理动作：回收站/临时文件/浏览器缓存/系统日志/预取文件（uCleanupManager）。
- 迁移演示流程：复制→重命名备份→mklink（uMain.ExecuteOperation）。
- 智能清理聚合入口（PerformSmartCleanup）。
- 防篡改框架基础：图像加密/校验、AboutMe 框架（待持续强化）。
- 现代化 UI 样式管理器。

### Phase 1（目录迁移生产化）已完成项
- 1.1 文件校验与事务管理：事务管理单元、哈希计算单元、拷贝前中后校验与失败回滚、事务日志与状态持久化。
- 1.2 Junction 验证与健壮性：VerifyJunction、权限与样本校验、失败回滚。
- 1.3 断点续迁：启动检测、用户选项、断点恢复、Resume/Rollback。
- 1.4 权限与占用处理：管理员检测、文件/目录占用检测、空间检查、安全重命名。
- 1.5 用户体验：备份大小显示、删除备份、进度与剩余时间、取消链路。
- 1.6 简洁/专家模式与权限管理：模式切换、按钮重命名、权限提示与禁用、状态栏提示、UAC 提示。
- 1.7 一键功能：一键回退/诊断/优化、自动检测最近备份、C 盘诊断报告。

### Phase 2：智能重复文件清理（引擎基础已完成）
- 三阶段扫描引擎基础实现（uSmartDuplicateCleanup.pas）：
  - 第一阶段：按文件大小分桶。
  - 第二阶段：部分哈希过滤。
  - 第三阶段：全量 SHA-256 确认。

### 防篡改与发布打磨（本次提交完成）
- 修复 SimpleSecureManager 恒真漏洞：强制校验 MoveC.db、images 表与关键键，任一失败安全退出。
- 将 AntiTamper 下载地址切换为 HTTPS（https://www.goodmem.cn）。

## 里程碑：打赏防篡改系统（已完成）
- 统一加解密：集成 `uAntiTamperPackage`，运行时解密展示图像。
- 完整性校验：由 MD5 升级为 SHA-256（字段名仍沿用 `md5_hash`）。
- 反调试保护：新增 `uAntiDebug.pas`，Release 开启多层检测。
- 生产配置：Release 禁用详细日志，Debug 保留日志。
- 数据自愈：`FrameAboutMe` 首次启动自愈补齐缺失图片（idempotent）。
- 文档沉淀：
  - `PROJECT_SUMMARY.md` 项目总结
  - `UPGRADE_GUIDE.md` 升级指南
  - `UPGRADE_SUMMARY.md` 升级完成总结
  - `SECURITY_AND_MIGRATION.md` 安全与迁移设计

## 里程碑：网站与文档（已完成）
- `html/` 网站静态页：功能亮点、指南与下载入口。
- 项目结构与流程文档：`IFLOW.md` 等。

## 历史缺陷修复（节选）
- About 页面仅显示首图：通过自愈与绑定修复（见 `bugfix.md`）。
- Win64 编译兼容：移除内联 var、BLOB 用流写入。

## 注意事项
- 某些 DFM/文本仍含 Emoji，低版本 IDE/资源编译器可能不兼容，建议逐步替换为纯文本。
- 目录迁移当前为演示/骨架版（大小估算与迁移过程使用模拟），发布前需落地真实流程。

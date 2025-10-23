# MoveC 变更与里程碑（History）

更新时间：2025-10-22 14:56

## 近期改动（自上次提交回退后）
- 同步并修复 `uDirectoryMigration.dfm` 与 PAS 声明结构。
- 为迁移列表 `clbMigrationItems` 增加右键菜单“删除源目录…”，删除到回收站（可撤回）。
- 恢复并补齐 `uSmartDuplicateCleanup.pas` 的最小可运行骨架：
  - 枚举文件、分阶段哈希（大小→部分哈希→全量哈希）分组重复。
  - 兼容旧编译器的哈希与集合写法；移除内联 var。
  - 基础清理流程（模拟项）与结果展示。

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

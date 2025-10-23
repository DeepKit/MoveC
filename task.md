# MoveC 开发任务规划（Task Board）

更新时间：2025-10-22 14:56

## 版本目标
- 近期目标：发布“可用 Beta 版”（基础功能可跑通，风险操作有明确提示，可回退）。
- 中期目标：发布“稳定版 v1.2.0”（目录迁移真实流程 + 断点续迁 + 回滚 + 日志 + 取消机制 + 网站完善）。

## 待办（Backlog）

- [ ] 目录迁移：从“演示/骨架版”升级为“真实迁移流程”
  - [ ] 实现复制→SHA-256 校验→删除源→清理空目录→创建联接（junction）
  - [ ] 异常回退：创建联接后 VerifyJunction 审计，不通过标记 needs_junction，并引导自愈
  - [ ] 断点续迁与状态：INI 事务（开始/进度/完成/失败），UI 按钮随状态启用
  - [ ] 回滚流程：移除联接→迁回文件→可选清空目标目录（回收站）
  - [ ] 取消与节流：长任务支持“取消”，UI 更新使用 Queue 节流
  - [ ] 权限检查：管理员/开发者模式提示，文件占用处理（可结合 Restart Manager）

- [ ] 重复文件清理：从“骨架版”升级为“可用”
  - [ ] 扫描结果列表化展示（分组/选择保留/定位打开）
  - [ ] 一键清理串联 RealPerformCleanup（同卷优先硬链接替换，否则回收站）
  - [ ] 并发 FullHash（TParallel.For）+ 临界区保护（TStringList 写入）
  - [ ] 取消与进度：扫描/清理均可中止，进度与剩余时间估算

- [ ] UI/资源兼容性
  - [ ] 去除 DFM 与字符串中的 Emoji（标题、按钮等）
  - [ ] 统一字体与样式（运行时不频繁改字体）

- [ ] 日志与安全
  - [ ] 统一日志接口（Info/Warn/Error）写入文件（Debug），Release 可选关闭
  - [ ] 关键操作前二次确认文案与风险提示

- [ ] 文档与网站
  - [ ] `html/` 网站：替换占位图/丰富案例/SEO 元信息
  - [ ] 发布说明、使用指南与常见问题更新

- [ ] 防篡改体系后续（参考 SECURITY_AND_MIGRATION.md）
  - [ ] 字段更名：`md5_hash` → `sha256_hash`，并回填迁移脚本
  - [ ] 增加 `hmac_sha256` 并在解密前校验
  - [ ] 可选：KDF（PBKDF2/Argon2id）+ per-database salt

## 进行中（In Progress）

- [ ] 迁移列表右键菜单（已完成：删除到回收站）→ 扩展更多项（打开源目录/目标目录、复制路径、在资源管理器中定位）

## 已完成（Moved to History）

- 已迁移至 `history.md`。

## 清理与归档建议

- 建议删除/归档的“测试/临时/过时”文件（请确认后执行）：

  - __测试工具（可归档至 `tools/` 或 `archive/`）__
    - `TestDatabase.dpr`
    - `TestDecrypt.dpr`
    - `TestImport.dpr`
    - `TestLogger.dpr`
    - `SimpleCheck.dpr`
    - `DirectInsert.dpr`
    - `CheckDB.dpr`
    - `CountRecords.dpr`
    - `CreateDB.dpr`
    - `ExtractImagesToFiles.dpr`

  - __日志/输出（可直接删除）__
    - `aboutme_debug.log`
    - `FRAME_CONSTRUCTOR_DEBUG.log`
    - `MAIN_FORMSHOW_DEBUG.log`
    - `antitamper_debug.log`
    - `test_log.txt`
    - `compile_output.txt`
    - `compilation_errors.txt`
    - `test_output.txt`
    - `checkdb_output.txt`
    - `test_decrypt_output.txt`
    - `test_import_output.txt`
    - `count_output.txt`
    - `direct_insert_output.txt`

  - __批处理脚本（如仍需保留，请移动至 `scripts/` 并更新 README）__
    - `compile_*.bat`
    - `import_*.bat`
    - `run_*.bat`
    - `test*.bat`

  - __可能已废弃的代码（请确认）__
    - `uImageSecurity.pas`（若全部迁移至 `uAntiTamperPackage` 则可废弃）

  - __资源/网站__
    - `html/` 目录建议保留；占位图与文案需要按网站计划升级。

> 以上清单为建议，请确认后我可自动执行“移动至 archive/ + 删除临时输出”的操作，并提交一次 `chore(cleanup): prune tests, logs and scripts`。

## 发布前检查清单（Beta）

- [ ] 去 Emoji、界面一致性检查
- [ ] 迁移/清理操作的二次确认 & 风险提示
- [ ] 关键路径异常处理（权限/占用/路径无效）
- [ ] 日志开关（Debug/Release）验证
- [ ] 文档与官网更新

# Bug Fix: Only First Image Displayed in About Page

- Date: 2025-10-12
- Module(s): `FrameAboutMe.pas`, `uImageDatabase.pas`
- Impact: About page only displayed the first image (`wechat`), other four images were missing.

## Symptoms
- App successfully connected to SQLite and decrypted `wechat` image.
- Logs showed records for the other keys were "not found".
- External import tools (ImportImages/DirectInsert) were unreliable on the target environment (silent failures, driver registration, console encoding). As a result, database contained only the first image.

## Root Cause
- Data ingestion was not robust: the database often lacked `alipay/btc/usdt/aboutme` records due to import tool issues.
- At runtime, the UI strictly read from the database and therefore could not show absent images.
- Additionally, 64-bit compilation errors and BLOB assignment style caused friction during fixes.

## Fix Summary
1. Frame self-healing insert (idempotent):
   - Added `EnsureDefaultImagesPresent` in `FrameAboutMe.pas`.
   - On startup, after DB connection and before display, it checks for each required key and inserts any missing image from `assets/`.
   - Uses the same working encryption path as display: AES-256-CBC with fixed password `@2241114` (via `TBasicProtection.EncryptBinaryData`) and stores SHA-256 in column `md5_hash` (legacy column name).
   - BLOBs are written via `TMemoryStream` + `ParamByName('data').LoadFromStream(..., ftBlob)` to ensure FireDAC compatibility.

2. Table binding and logging:
   - In `InitializeDataManager` (`FrameAboutMe.pas`), explicitly set `FDTable1.Connection := FDConnection1` and `FDTable1.TableName := 'images'` and log these values to avoid design-time misbinding.

3. Win64 compile fixes:
   - Removed inline `var :=` declarations and replaced with explicit `var` section.
   - Avoided `AsBytes` direct assignment to BLOB parameters; used stream loading instead.

## Files and Key Changes
- `FrameAboutMe.pas`
  - Added: `EnsureDefaultImagesPresent` (idempotent insertion of `alipay`, `btc`, `usdt`, `aboutme`).
  - Updated: `ManualInitialize`, `OnInitTimerTimer`, and `InitializeDataManager` to call self-heal before loading images.
  - Updated: bind `FDTable1.TableName := 'images'` and log.
  - Fixed: Win64 compilation (no inline `var`, BLOB via stream).
- `uImageDatabase.pas`
  - Confirmed unified schema and AES-256-CBC usage with password `@2241114`. Logging remains in English.

## Validation
- Rebuilt application (Win64).
- On startup, logs show:
  - DB connected, table activated, `FDTable1.TableName: images`.
  - `EnsureDefaultImagesPresent` reports current record count and "inserted ..." lines for any missing keys.
  - Each key logs encrypted length, decrypted length, and successful load.
- Result: All five images display correctly.

## Migration Notes
- Schema used by runtime: table `images` with columns
  - `image_key TEXT UNIQUE`, `image_data BLOB`, `address_text TEXT`, `description TEXT`, `md5_hash TEXT (stores SHA-256)`, timestamps.
- Encryption: AES-256-CBC with fixed password `@2241114`.
- Integrity: SHA-256 stored in `md5_hash` (legacy name retained). Future plan: rename to `sha256_hash` or add HMAC-SHA256 column.
- Startup self-heal is idempotent: safe to run every launch; it only inserts missing keys. Can be disabled in production if a dedicated import pipeline is preferred.

## Future Hardening (Recommended)
- Add HMAC-SHA256 over ciphertext for tamper-evidence.
- Rename `md5_hash` to `sha256_hash` with a simple migration.
- Keep ingestion separated as a dedicated tool; ensure driver link units and logging are robust on target machines.

---

## 修复：SimpleSecureManager 恒真漏洞导致安全检查失效

- 日期：2025-11-18
- 模块：`uSimpleSecureManager.pas`（或相关安全校验路径）、`uMain.pas`
- 影响：关键资源缺失时未按预期触发安全退出，存在被绕过风险。

### 现象
- 即使缺失 `MoveC.db`、缺失 `images` 表或缺少关键键（`wechat/alipay/btc`），依然返回 True，程序继续运行。

### 根因
- 安全检查函数逻辑存在“恒真”路径：未对所有关键条件进行强制短路判定并返回 False。

### 修复摘要
1. 强制校验关键资源：
   - 必须存在 `MoveC.db` 文件。
   - 必须存在 `images` 表。
   - 必须存在关键键记录：`wechat/alipay/btc`（最少集）。
   - 任一条件失败即返回 False，并记录日志；在主流程触发安全退出。
2. 下载地址切换为 HTTPS：
   - `DownloadURL` 指向 `https://www.goodmem.cn`，拒绝明文 HTTP。

### 关键改动
- 安全校验函数：补充硬性条件判断，移除或修正导致恒真的逻辑分支。
- `uMain.pas`：调用点根据返回值决定安全退出。

### 验证
- 在 Debug 下：
  - 分别模拟三类缺失（数据库/表/关键键），均返回 False，日志包含原因。
  - 正常路径下返回 True，程序继续。
- 在 Release 下：
  - 详细日志最小化，但可通过用户提示与退出码确认行为。

### 后续建议
- 增加 HMAC-SHA256 完整性校验；
- 字段重命名为 `sha256_hash` 并保留迁移兼容；
- 启动早期（DPR）自检，防止 UI 早期加载绕过.

---

## 修复：重复文件清理模块编译错误

- 日期：2025-11-22
- 模块：`uDuplicateFiles.pas`、`uSmartDuplicateCleanup.pas`、`uDuplicateFileDetector.pas`
- 影响：重复文件清理功能模块存在编译错误，无法正常构建和运行

### 现象
- `uDuplicateFiles.pas` 中缺少 `FDetector: TDuplicateFileDetector` 字段定义
- `FDuplicateGroups: TArray<TDuplicateGroup>` 字段缺失
- 类型声明不匹配导致的编译失败

### 根因
- 模块间依赖关系未正确建立
- 字段定义在interface部分缺失
- 类型单元引用不完整

### 修复摘要
1. **补充字段定义**：在 `uDuplicateFiles.pas` 中添加缺失的私有字段
2. **完善类型引用**：确保所有相关单元正确引用
3. **模块集成**：建立正确的模块间依赖关系
4. **编译测试**：确保所有相关模块可正常编译

### 关键改动
- `uDuplicateFiles.pas`：补充 `FDetector` 和 `FDuplicateGroups` 字段定义
- 完善单元引用：添加 `uDuplicateFileDetector` 到 uses 子句
- 类型兼容：确保 `TDuplicateGroup` 类型定义一致

### 验证
- 项目编译成功，无编译错误
- 重复文件清理菜单可正常启动
- 扫描引擎基础功能正常

---

## 修复：UI Emoji兼容性问题

- 日期：2025-11-22
- 模块：`uMain.pas`、相关DFM文件
- 影响：低版本IDE/资源编译器可能无法正确渲染Emoji字符，导致显示异常

### 现象
- 菜单和按钮中的Emoji在某些环境下显示为方块或乱码
- DFM文件中的Unicode字符编译时出现问题

### 根因
- Emoji字符需要特殊的Unicode支持
- 低版本Delphi编译器对某些Unicode字符支持不完整
- 资源编译器版本兼容性问题

### 修复摘要
1. **移除Emoji字符**：将所有菜单项和按钮文本中的Emoji替换为纯文本
2. **统一样式**：使用统一的文本描述替代图形符号
3. **兼容性提升**：确保在所有目标编译环境下正常显示

### 关键改动
- `uMain.pas`：主菜单和右键菜单文本纯文本化
- DFM文件：更新界面元素的Caption属性
- 文本描述：使用"打开"、"复制路径"等纯文本描述

### 验证
- 所有菜单项在各种环境下正常显示
- 编译过程无Unicode相关错误
- 用户界面简洁一致

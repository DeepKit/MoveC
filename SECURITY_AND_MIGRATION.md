### Anti-Tamper Architecture (Updated 2025-10-12)

This document outlines the finalized anti-tamper architecture used by `MoveC` and serves as a reference for porting the design to other Delphi applications.

#### Goals

- Ensure images are protected at rest (AES-256-CBC) with a fixed password `@2241114`.
- Detect accidental corruption or malicious tampering of image data (SHA-256, with planned HMAC-SHA256).
- Separate responsibilities: ingestion (write) vs. display (read-only) to minimize runtime write surface.
- Be resilient on different environments (Win32/Win64), with clear logging and fail-closed behavior.

#### Components

- `uBasicProtection.pas`
  - Provides AES-256-CBC encryption/decryption with PKCS7 padding.
  - Key derivation from fixed password `@2241114`.

- `uImageDatabase.pas`
  - SQLite access via FireDAC.
  - Runtime schema creation and upgrade.
  - Saves `image_data` (ciphertext BLOB) and `md5_hash` column, which stores a SHA-256 of plaintext (legacy column name retained; plan to rename to `sha256_hash`).

- `FrameAboutMe.pas`
  - Read-only consumption: connects to DB, loads ciphertext, decrypts, verifies integrity, and displays images.
  - Self-heal at startup: `EnsureDefaultImagesPresent` checks required keys and inserts any missing ones from `assets/` using the same encryption routine. This is idempotent and safe to run; it only fills missing records. It can be disabled in production if desired.

#### Integrity Strategy

- Current: SHA-256 of plaintext stored in `md5_hash`.
- Recommended enhancement: add `hmac_sha256` over ciphertext using a key derived from `@2241114`. Runtime verification should check HMAC before decryption.

#### Operational Notes

- Logging: English messages for clarity and consistent diagnostics.
- Table binding: Ensure runtime binds `FDTable1.TableName := 'images'` to avoid accidental design-time misconfiguration.
- BLOB writes: Use `TMemoryStream` + `LoadFromStream(..., ftBlob)` for FireDAC compatibility across Win32/Win64.

---

### Migration Guide (Porting to Another App)

1. **Database Schema**

   Create a table `images` with columns:
   - `image_key TEXT UNIQUE`
   - `image_data BLOB`
   - `address_text TEXT`
   - `description TEXT`
   - `md5_hash TEXT` (stores SHA-256)
   - `created_at DATETIME DEFAULT CURRENT_TIMESTAMP`
   - `updated_at DATETIME DEFAULT CURRENT_TIMESTAMP`

2. **Encryption/Decryption**

   - Use `uBasicProtection.EncryptBinaryData(plainBytes, '@2241114')` when writing.
   - Use `uBasicProtection.DecryptBinaryData(cipherBytes, '@2241114')` when reading.
   - Calculate integrity: `TAntiTamperPackage.CalculateSHA256(plainBytes)` and store to `md5_hash`.

3. **Write Path (Import Tool or Startup Self-Heal)**

   - Prefer a dedicated import tool to write image rows.
   - Alternatively, enable a one-time self-heal on first run to auto-fill missing records from an `assets/` folder, identical to `EnsureDefaultImagesPresent` in `FrameAboutMe.pas`.

4. **Read Path (Main App)**

   - Bind the dataset to `images` table explicitly and log the binding.
   - For each `image_key`, select `image_data` and `md5_hash`, decrypt, verify SHA-256, and display.

5. **Hardening (Optional but Recommended)**

   - Add an `hmac_sha256` column with ciphertext HMAC.
   - Verify HMAC prior to decryption to detect tampering early.
   - Plan a migration that keeps old SHA-256 for a transitional period.

6. **Win64 Compatibility**

   - Avoid inline `var :=` declarations in Delphi code that must compile under Win64.
   - Use stream-based BLOB assignment (not `AsBytes`).

7. **Troubleshooting Checklist**

   - Confirm `assets/` filenames match exactly (e.g., `AliPay.png` vs `alipay.png`).
   - Confirm runtime `Database path` and `FDTable1.TableName` in logs.
   - If images are missing, run self-heal once or the import tool.

---

### Future Work

- Rename `md5_hash` -> `sha256_hash` and backfill values.
- Introduce HMAC-SHA256 and enforce verification before decryption.
- Add a feature flag to disable self-heal in production builds.

### Security Model

- Rename `md5_hash` -> `sha256_hash` and backfill values.
- Introduce HMAC-SHA256 and enforce verification before decryption.
- Add a feature flag to disable self-heal in production builds.
# 安全与迁移设计说明（固定口令方案｜一次性迁移｜后续加强路线）

本文件描述当前版本的加密/解密策略、一次性迁移流程，以及建议的后续强化路线，确保导入工具与主程序密钥一致，修复“图像无法解密显示”的问题。

## 现行方案（本次上线）

- 固定口令：`@2241114`
- 加密逻辑（`uBasicProtection.pas`）
  - 仅使用固定口令派生密钥（不再拼接 `GetDynamicKey`，亦无任何回退路径）。
  - 算法：AES-256-CBC + PKCS7 填充（Windows CryptoAPI）。
  - 数据布局：`IV(16字节) | CIPHERTEXT` 写入 `images.image_data`。
- 解密逻辑
  - 仅使用固定口令派生密钥进行解密。
- 完整性校验
  - 字段名：`md5_hash`（历史沿用名称），实际存放 SHA-256 值。
  - 由 `TAntiTamperPackage.CalculateSHA256` 计算。

## 一次性迁移流程（FrameAboutMe.pas）

- 触发时机：About/打赏页加载前，`InitializeDataManager` 激活数据表后调用 `MigrateEncryptedImages`。
- 迁移步骤：
  1. 遍历 `images` 每条记录，读取 `image_data`。
  2. 使用“仅固定口令”解密旧数据（若无法解密，需用当前 Import 工具重新导入）。
  3. 成功后用“仅固定口令”重新加密并写回 BLOB。
  4. 重新计算 SHA-256，写入 `md5_hash`。
- 标记文件：`migration.fixedkey.done`
  - 首次迁移完成后生成该文件，避免重复迁移；删除该文件可强制再次迁移。
- 日志：`aboutme_debug.log` 记录迁移统计与异常。

## UI 与编码

- 统一在设计时设置控件字体（不在运行时改）：
  - 窗体字体：`Segoe UI, 7pt`（Font.Height=-10）。
  - 按钮 `ParentFont=True`；`memoStatus` 使用 `DEFAULT_CHARSET`。
- 日志：UTF-8 文本（若编辑器显示异常，可切换为 Unicode 查看）。

## 现状与收益

- 导入工具与主程序使用同一密钥策略（固定口令），从根本上解决“跨工具密钥不一致导致的解密失败”。
- 旧数据通过一次性迁移平滑过渡到新规则，不影响现有数据库与业务。

## 后续强化路线（建议）

1. KDF（PBKDF2/Argon2id）+ per-database salt（存元信息表）
   - 由 `password + salt` 派生 `masterKey`，不同数据库使用不同盐，提高泄露后的横向风险成本。
   - 迭代次数：PBKDF2 建议≥100,000；Argon2id 按硬件调参。
2. 密文鉴别（AEAD 或 CBC+HMAC）
   - 优选：AES-GCM/ChaCha20-Poly1305（一次性机密+完整性）。
   - 兼容：AES-256-CBC + HMAC-SHA256，对 `IV|Cipher` 做 MAC，解密前先验 MAC。
3. salt 放置策略
   - 便携：salt 存在数据库元表；
   - 防拷贝：salt 存在本机（注册表/文件），但牺牲便携性；可采用“库内盐 + 本机盐”二段方案。
4. 可执行自校验与反调试
   - 保持并强化 `uAntiTamperPackage` / `uAntiDebug`；必要时对代码段/资源段进行签名验签。

## 迁移/回滚说明

- 如需对新的数据库再次迁移（例如替换数据库文件后），删除 `migration.fixedkey.done` 并重新打开 About/打赏页即可。
- 如需切换到 KDF/AEAD 方案：
  - 先实现新方案（派生与加密格式），
  - 再按上述迁移流程对现有数据逐条重写。

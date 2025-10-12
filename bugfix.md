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

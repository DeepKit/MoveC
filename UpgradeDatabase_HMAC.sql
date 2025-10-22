-- 升级脚本：为 images 表添加防篡改所需列（hmac_sha256、salt、sha256_hash）
-- 说明：
-- 1) 请确保 MoveC 程序与任何数据库查看器均已关闭，以避免“database is locked”。
-- 2) 先备份 MoveC.db 后再执行本脚本（与 MoveC.db 同目录的备份：MoveC_backup_YYYYMMDD_HHMMSS.db）。
-- 3) 本脚本在列不存在时执行成功；如列已存在，单独执行该 ALTER 语句会报错，忽略即可。

PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA foreign_keys = ON;
PRAGMA busy_timeout = 8000;

-- 添加新列（若已存在请忽略该语句错误）
ALTER TABLE images ADD COLUMN hmac_sha256 TEXT;
ALTER TABLE images ADD COLUMN salt TEXT;
ALTER TABLE images ADD COLUMN sha256_hash TEXT;

-- 为 sha256_hash 回填（当前 md5_hash 列历史上实际保存的是 SHA-256 值）
UPDATE images
SET sha256_hash = md5_hash
WHERE (sha256_hash IS NULL OR sha256_hash = '')
  AND (md5_hash IS NOT NULL AND md5_hash <> '');

-- 索引（存在则忽略）
CREATE INDEX IF NOT EXISTS idx_images_key ON images(image_key);
CREATE INDEX IF NOT EXISTS idx_images_sha256 ON images(sha256_hash);

-- 可选：记录一次版本升级
CREATE TABLE IF NOT EXISTS db_version (
  version INTEGER PRIMARY KEY,
  applied_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  description TEXT
);
INSERT INTO db_version (version, description)
VALUES (3, 'Add columns: hmac_sha256, salt, sha256_hash; backfill sha256_hash.');

-- 检查结果
PRAGMA table_info(images);
SELECT id, image_key, LENGTH(image_data) AS blob_len, sha256_hash, hmac_sha256, salt FROM images LIMIT 10;

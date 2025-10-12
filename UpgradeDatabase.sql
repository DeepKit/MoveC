-- 数据库升级脚本：从MD5升级到SHA-256
-- 执行日期：2025-10-10
-- 用途：为防篡改系统添加SHA-256支持

-- 注意：此脚本保留md5_hash字段以保持向后兼容性
-- 新字段sha256_hash将用于更强的完整性校验

-- 步骤1：添加sha256_hash字段（如果不存在）
ALTER TABLE images ADD COLUMN sha256_hash TEXT;

-- 步骤2：为现有记录添加索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_images_key ON images(image_key);
CREATE INDEX IF NOT EXISTS idx_images_sha256 ON images(sha256_hash);

-- 步骤3：添加版本信息表（用于跟踪数据库版本）
CREATE TABLE IF NOT EXISTS db_version (
  version INTEGER PRIMARY KEY,
  applied_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  description TEXT
);

-- 记录此次升级
INSERT INTO db_version (version, description) 
VALUES (2, 'Added SHA-256 hash support for enhanced security');

-- 查询当前数据库状态
SELECT 'Database upgrade completed successfully' as status;
SELECT * FROM db_version ORDER BY version DESC LIMIT 1;

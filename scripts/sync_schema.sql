-- Sync schema for MoveC
CREATE TABLE IF NOT EXISTS sync_tasks (
  task_id TEXT PRIMARY KEY,
  task_name TEXT NOT NULL,
  source_path TEXT NOT NULL,
  target_path TEXT NOT NULL,
  sync_mode INTEGER NOT NULL,
  is_enabled INTEGER NOT NULL DEFAULT 1,
  preset_id TEXT,
  filter_rules TEXT,
  last_sync_time TEXT,
  last_sync_status TEXT,
  last_error_message TEXT,
  files_synced INTEGER DEFAULT 0,
  bytes_synced INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS sync_presets (
  preset_id TEXT PRIMARY KEY,
  preset_name TEXT NOT NULL,
  description TEXT,
  filter_rules TEXT,
  sync_mode INTEGER,
  is_system INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS sync_history (
  history_id TEXT PRIMARY KEY,
  task_id TEXT NOT NULL,
  sync_start_time TEXT,
  sync_end_time TEXT,
  status TEXT,
  files_added INTEGER,
  files_modified INTEGER,
  files_deleted INTEGER,
  bytes_transferred INTEGER,
  error_message TEXT
);

CREATE TABLE IF NOT EXISTS sync_file_states (
  state_id TEXT PRIMARY KEY,
  task_id TEXT NOT NULL,
  file_relative_path TEXT NOT NULL,
  file_hash TEXT,
  file_size INTEGER,
  last_modified TEXT,
  sync_status TEXT,
  last_sync_time TEXT
);

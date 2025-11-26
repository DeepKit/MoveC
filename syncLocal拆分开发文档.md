# syncLocal 独立程序拆分开发文档

> 📅 **创建时间**: 2025-11-27  
> 📌 **版本**: V1.0  
> 🎯 **目标**: 将同步盘和托盘功能从 MoveC 拆分为独立程序 syncLocal.exe

---

## 一、概述

### 1.1 拆分目标
将 MoveC 中的文件同步和系统托盘功能拆分为独立程序 **syncLocal.exe**，实现：
- 职责分离：主程序专注清理/迁移，syncLocal 专注后台同步
- 轻量运行：syncLocal 可开机自启、常驻托盘，资源占用更低
- 独立维护：两个程序边界清晰，便于独立开发和测试
- 用户体验：符合同步盘类软件的使用习惯

### 1.2 程序定位

| 程序 | 定位 | 运行方式 |
|------|------|----------|
| **MoveC.exe** | C盘清理/迁移/分析工具 | 按需启动，完成后退出 |
| **syncLocal.exe** | 本地文件同步服务 | 开机自启，后台常驻托盘 |

---

## 二、架构设计

### 2.1 syncLocal.exe 模块组成

```
syncLocal.exe
├── 核心模块
│   ├── uSyncDatabase.pas      -- 数据库访问层（独立数据库）
│   ├── uSyncEngine.pas        -- 同步引擎核心
│   ├── uFileSystemWatcher.pas -- 文件系统监控
│   ├── uNativeFileWatcher.pas -- Windows原生监控API
│   ├── uRealtimeSyncManager.pas -- 实时同步管理
│   ├── uSyncExecutor.pas      -- 同步执行器
│   └── uFileSyncComparer.pas  -- 文件比较器
│
├── 托盘模块
│   ├── uTrayIcon.pas          -- 基础托盘图标
│   ├── uEnhancedTrayIcon.pas  -- 增强托盘功能
│   └── uTraySettingsForm.pas  -- 托盘设置窗体
│
├── UI模块
│   ├── uSyncSettingsBasic.pas -- 同步设置主窗体
│   ├── uSyncTaskEdit.pas      -- 任务编辑窗体
│   └── uSyncHistory.pas       -- 同步历史窗体
│
└── 辅助模块
    ├── uLogger.pas            -- 日志系统
    ├── uConflictResolver.pas  -- 冲突处理
    ├── uNetworkPathManager.pas -- 网络路径管理
    └── uSyncPresets.pas       -- 同步预设
```

### 2.2 数据库拆分

**原数据库**: `MoveC.db`  
**新数据库**: `syncLocal.db`

需要迁移的表：
- `sync_tasks` - 同步任务配置
- `sync_presets` - 预设模板
- `sync_history` - 同步历史记录
- `file_states` - 文件状态跟踪

### 2.3 程序间通信

```
┌─────────────┐                    ┌──────────────┐
│   MoveC     │ ←── 共享配置 ───→  │  syncLocal   │
│             │                    │              │
│ - 清理工具  │  Windows消息/命令行  │ - 实时同步   │
│ - 迁移向导  │ ←─────────────────→ │ - 托盘常驻   │
│ - 磁盘分析  │                    │ - 后台服务   │
└─────────────┘                    └──────────────┘
        │                                  │
        └───────────── syncLocal.db ───────┘
```

---

## 三、功能规格

### 3.1 托盘功能

#### 3.1.1 托盘图标状态
| 状态 | 图标 | 说明 |
|------|------|------|
| 空闲 | 蓝色图标 | 所有任务已同步完成 |
| 同步中 | 绿色旋转 | 正在执行同步操作 |
| 暂停 | 黄色暂停 | 同步已暂停 |
| 错误 | 红色感叹号 | 存在同步错误 |

#### 3.1.2 托盘右键菜单
```
┌─────────────────────────┐
│ 📊 同步状态: 空闲       │
├─────────────────────────┤
│ 📁 打开同步设置...      │
│ 🔄 立即全部同步         │
│ ⏸️  暂停所有同步        │
├─────────────────────────┤
│ 📋 查看同步历史...      │
│ 📝 查看日志...          │
├─────────────────────────┤
│ ⚙️  设置                │
│ ❓ 关于                 │
├─────────────────────────┤
│ ❌ 退出                 │
└─────────────────────────┘
```

#### 3.1.3 托盘交互
- **双击**: 打开同步设置主窗口
- **左键单击**: 显示简要状态气泡
- **右键**: 显示菜单

### 3.2 同步功能

#### 3.2.1 支持的同步模式
- **手动同步**: 用户触发，执行全量或增量同步
- **实时同步**: 监控文件变化，自动同步

#### 3.2.2 同步任务限制
- 最多 6 个同步任务
- 支持本地路径和局域网路径

#### 3.2.3 过滤规则
- 支持通配符（*.tmp, *.log）
- 支持目录排除（.git, node_modules）
- 支持预设模板（代码同步、文档备份等）

### 3.3 启动参数

```bash
# 正常启动（显示托盘图标）
syncLocal.exe

# 静默启动（最小化到托盘）
syncLocal.exe /silent

# 打开设置窗口
syncLocal.exe /config

# 立即执行同步
syncLocal.exe /sync

# 指定数据库路径
syncLocal.exe /db:"D:\Data\syncLocal.db"
```

---

## 四、开发步骤

### Phase 1: 项目初始化（1天）

#### 1.1 创建项目文件
- [ ] 创建 `syncLocal.dpr` 项目文件
- [ ] 创建 `syncLocal.dproj` 项目配置
- [ ] 配置编译输出路径
- [ ] 设置应用程序图标

#### 1.2 复制核心模块
- [ ] 复制同步相关 pas 文件
- [ ] 复制托盘相关 pas 文件
- [ ] 复制辅助模块
- [ ] 调整 uses 引用

### Phase 2: 数据库独立化（1-2天）

#### 2.1 修改 uSyncDatabase.pas
- [ ] 修改默认数据库路径为 `syncLocal.db`
- [ ] 添加数据库迁移方法
- [ ] 移除 MoveC 特定的表依赖

#### 2.2 数据库迁移工具
- [ ] 创建 `uDatabaseMigration.pas`
- [ ] 实现从 MoveC.db 导出同步数据
- [ ] 实现导入到 syncLocal.db
- [ ] 处理升级场景

### Phase 3: 托盘功能完善（2-3天）

#### 3.1 增强 uTrayIcon.pas
- [ ] 实现多状态图标切换
- [ ] 实现气泡通知
- [ ] 实现菜单动态更新

#### 3.2 主程序逻辑
- [ ] 创建 `uSyncLocalMain.pas` 主窗体
- [ ] 实现开机自启动设置
- [ ] 实现单实例运行
- [ ] 实现命令行参数解析

### Phase 4: UI 适配（1-2天）

#### 4.1 简化设置界面
- [ ] 适配 `uSyncSettingsBasic.pas`
- [ ] 添加托盘相关设置选项
- [ ] 优化小窗口布局

#### 4.2 状态显示
- [ ] 实现同步进度窗口
- [ ] 实现错误提示窗口

### Phase 5: 集成测试（2-3天）

#### 5.1 功能测试
- [ ] 托盘图标显示正常
- [ ] 右键菜单功能完整
- [ ] 同步任务执行正确
- [ ] 实时监控工作正常

#### 5.2 场景测试
- [ ] 开机自启动
- [ ] 网络路径断开重连
- [ ] 大文件同步
- [ ] 冲突处理

---

## 五、修改清单

### 5.1 需要复制的文件

```
核心同步模块：
├── uSyncDatabase.pas      (需修改)
├── uSyncEngine.pas        (可直接复用)
├── uFileSystemWatcher.pas (可直接复用)
├── uNativeFileWatcher.pas (可直接复用)
├── uRealtimeSyncManager.pas (可直接复用)
├── uSyncExecutor.pas      (可直接复用)
├── uSyncExecutorSimple.pas (可直接复用)
├── uFileSyncComparer.pas  (可直接复用)
├── uFileSyncComparerSimple.pas (可直接复用)
└── uConflictResolver.pas  (可直接复用)

托盘模块：
├── uTrayIcon.pas          (需增强)
├── uEnhancedTrayIcon.pas  (可直接复用)
└── uTraySettingsForm.pas  (需修改)
└── TraySettingsForm.dfm   (需修改)

UI模块：
├── uSyncSettingsBasic.pas (需修改)
├── uSyncSettingsBasic.dfm (需修改)
├── uSyncTaskEdit.pas      (可直接复用)
├── uSyncTaskEdit.dfm      (可直接复用)
├── uSyncHistory.pas       (可直接复用)
└── uSyncHistory.dfm       (可直接复用)

辅助模块：
├── uLogger.pas            (可直接复用)
├── uNetworkPathManager.pas (可直接复用)
├── uNetworkConnectionMonitor.pas (可直接复用)
└── uSyncPresets.pas       (可直接复用)
```

### 5.2 需要新建的文件

```
├── syncLocal.dpr          -- 项目主文件
├── syncLocal.dproj        -- 项目配置
├── uSyncLocalMain.pas     -- 主窗体单元
├── uSyncLocalMain.dfm     -- 主窗体资源
├── uDatabaseMigration.pas -- 数据库迁移工具
└── syncLocal.res          -- 资源文件(图标等)
```

### 5.3 MoveC.exe 需要的修改

```
修改 uMain.pas：
- [ ] 移除托盘相关代码引用
- [ ] 添加启动 syncLocal 的菜单项
- [ ] 保留"同步设置"菜单（跳转到 syncLocal）

修改 C盘超级瘦身.dpr：
- [ ] 移除同步相关模块的 uses
- [ ] 移除托盘相关模块的 uses
```

---

## 六、数据库迁移方案

### 6.1 syncLocal.db 表结构

```sql
-- 同步任务表
CREATE TABLE sync_tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  source_path TEXT NOT NULL,
  target_path TEXT NOT NULL,
  sync_mode INTEGER NOT NULL DEFAULT 0,
  conflict_strategy INTEGER NOT NULL DEFAULT 0,
  is_enabled BOOLEAN NOT NULL DEFAULT 1,
  filter_rules TEXT,
  preset_id INTEGER,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 预设模板表
CREATE TABLE sync_presets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  filter_rules TEXT,
  conflict_strategy INTEGER NOT NULL DEFAULT 0,
  is_system BOOLEAN NOT NULL DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 同步历史表
CREATE TABLE sync_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id INTEGER NOT NULL,
  sync_type TEXT NOT NULL,
  start_time DATETIME NOT NULL,
  end_time DATETIME,
  files_scanned INTEGER DEFAULT 0,
  files_copied INTEGER DEFAULT 0,
  files_updated INTEGER DEFAULT 0,
  files_deleted INTEGER DEFAULT 0,
  files_skipped INTEGER DEFAULT 0,
  bytes_transferred INTEGER DEFAULT 0,
  error_message TEXT,
  status TEXT NOT NULL DEFAULT 'running',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (task_id) REFERENCES sync_tasks(id) ON DELETE CASCADE
);

-- 文件状态表
CREATE TABLE file_states (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id INTEGER NOT NULL,
  file_path TEXT NOT NULL,
  file_hash TEXT,
  file_size INTEGER DEFAULT 0,
  modified_time DATETIME,
  last_sync_time DATETIME,
  sync_status TEXT NOT NULL DEFAULT 'pending',
  exists_in_source BOOLEAN NOT NULL DEFAULT 0,
  exists_in_target BOOLEAN NOT NULL DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (task_id) REFERENCES sync_tasks(id) ON DELETE CASCADE
);

-- 应用设置表 (新增)
CREATE TABLE app_settings (
  key TEXT PRIMARY KEY,
  value TEXT,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 索引
CREATE INDEX idx_sync_tasks_name ON sync_tasks(name);
CREATE INDEX idx_sync_tasks_enabled ON sync_tasks(is_enabled);
CREATE INDEX idx_sync_history_task_id ON sync_history(task_id);
CREATE INDEX idx_file_states_task_id ON file_states(task_id);
CREATE INDEX idx_file_states_path ON file_states(task_id, file_path);
```

### 6.2 应用设置项

```sql
-- 默认设置
INSERT INTO app_settings (key, value) VALUES
  ('auto_start', 'false'),           -- 开机自启
  ('minimize_to_tray', 'true'),      -- 最小化到托盘
  ('show_notifications', 'true'),    -- 显示通知
  ('sync_on_startup', 'true'),       -- 启动时同步
  ('log_level', 'info'),             -- 日志级别
  ('debounce_interval', '500'),      -- 防抖间隔(ms)
  ('max_concurrent_syncs', '2');     -- 最大并发同步数
```

---

## 七、测试计划

### 7.1 单元测试

```
Tests/
├── TestSyncDatabase.pas     -- 数据库操作测试
├── TestSyncEngine.pas       -- 同步引擎测试
├── TestFileWatcher.pas      -- 文件监控测试
├── TestSyncExecutor.pas     -- 同步执行器测试
└── TestTrayIcon.pas         -- 托盘功能测试
```

### 7.2 集成测试场景

| 场景 | 测试项 | 预期结果 |
|------|--------|----------|
| 正常启动 | 双击exe启动 | 显示托盘图标，加载任务 |
| 静默启动 | /silent参数 | 仅显示托盘图标 |
| 手动同步 | 右键-立即同步 | 执行同步，显示进度 |
| 实时同步 | 修改源目录文件 | 自动同步到目标 |
| 网络断开 | 断开网络路径 | 显示错误，自动重试 |
| 冲突处理 | 两端同时修改 | 按策略处理冲突 |
| 开机自启 | 重启系统 | 自动启动到托盘 |

### 7.3 性能测试

| 测试项 | 指标 | 目标 |
|--------|------|------|
| 内存占用 | 空闲时 | < 30MB |
| CPU占用 | 空闲时 | < 1% |
| 启动时间 | 冷启动 | < 3秒 |
| 同步延迟 | 实时同步 | < 2秒 |

---

## 八、发布计划

### 8.1 版本号
- syncLocal 首版: **V1.0.0**
- 对应 MoveC: **V1.3.0** (移除同步/托盘功能)

### 8.2 发布物
```
Release/
├── syncLocal.exe           -- 主程序
├── syncLocal.db            -- 空数据库模板
├── syncLocal.ini           -- 默认配置
├── README-syncLocal.md     -- 使用说明
└── migrate_sync_data.bat   -- 数据迁移脚本
```

### 8.3 升级策略
1. 用户运行迁移脚本，从 MoveC.db 导出同步数据
2. 导入到 syncLocal.db
3. 配置 syncLocal 开机自启
4. 升级 MoveC 到新版本

---

## 九、风险与缓解

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 数据库并发访问 | 数据损坏 | syncLocal 独立数据库 |
| 用户迁移失败 | 丢失配置 | 提供备份/恢复工具 |
| 两程序版本不匹配 | 功能异常 | 版本兼容性检查 |
| 开机自启权限不足 | 启动失败 | 提示用户授权 |

---

## 十、参考资料

- 现有同步功能文档: `文件同步功能架构设计.md`
- 同步功能验证报告: `同步功能实现验证报告.md`
- 托盘功能修复说明: `托盘功能修复说明.md`

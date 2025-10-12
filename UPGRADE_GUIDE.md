# 防篡改系统升级指南

## 📋 升级概述

本次升级实施了**方案一：快速修复**，主要改进包括：

### ✅ 已完成的升级

1. **升级哈希算法** - MD5 → SHA-256
2. **统一加密模块** - 使用 `uAntiTamperPackage`
3. **生产环境优化** - 禁用详细日志
4. **反调试保护** - 新增 `uAntiDebug.pas` 模块

---

## 🔧 升级步骤

### 步骤1：备份现有数据库

**重要：在升级前务必备份数据库！**

```bash
# 备份MoveC.db
copy MoveC.db MoveC.db.backup_%date:~0,10%
```

### 步骤2：更新代码文件

以下文件已被修改，请确保使用最新版本：

- ✅ `uAntiTamperPackage.pas` - 添加SHA-256支持和编译指令
- ✅ `FrameAboutMe.pas` - 统一使用 `uAntiTamperPackage`
- ✅ `uAntiDebug.pas` - 新增反调试模块（新文件）

### 步骤3：重新导入打赏图像

**重要：由于哈希算法升级，需要重新导入所有打赏图像！**

使用 `ImportImages.exe` 重新导入图像：

```bash
# 编译ImportImages项目
dcc32 ImportImages.dpr

# 运行导入工具
ImportImages.exe
```

或者在Delphi IDE中：
1. 打开 `ImportImages.dpr`
2. 按 F9 运行
3. 选择图像文件并导入

### 步骤4：配置项目编译选项

#### Debug配置（开发环境）
- 不定义 `RELEASE` 符号
- 启用详细日志
- 禁用反调试保护

#### Release配置（生产环境）
1. 打开项目选项 (Project → Options)
2. 选择 "Delphi Compiler" → "Compiling"
3. 在 "Conditional defines" 中添加：`RELEASE`
4. 保存配置

这将自动：
- ✅ 禁用详细日志输出
- ✅ 启用反调试保护
- ✅ 优化性能

### 步骤5：集成反调试保护（可选）

在主程序 `uMain.pas` 中添加反调试检测：

```pascal
uses
  // ... 其他单元
  uAntiDebug;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // 在程序启动时检测调试器
  {$IFDEF RELEASE}
  if TAntiDebug.CheckAll then
  begin
    ShowMessage('检测到调试器，程序将退出。');
    Application.Terminate;
    Exit;
  end;
  {$ENDIF}
  
  // ... 其他初始化代码
end;
```

### 步骤6：初始化防篡改包

确保在使用前初始化 `TAntiTamperPackage`：

```pascal
// 在主窗体或Frame的初始化代码中
var
  Config: TAntiTamperConfig;
begin
  Config := TAntiTamperPackage.GetDefaultConfig;
  Config.EncryptionKey := 'YourStrongKey_2025';  // 使用强密钥
  Config.DownloadURL := 'http://www.goodmem.cn';
  Config.EnableLogging := {$IFDEF DEBUG}True{$ELSE}False{$ENDIF};
  
  TAntiTamperPackage.Initialize(Config);
end;
```

---

## 🔍 验证升级

### 1. 编译测试

```bash
# Debug版本
dcc32 C盘瘦身.dpr

# Release版本
dcc32 -DRELEASE C盘瘦身.dpr
```

### 2. 功能测试

- [ ] 程序正常启动
- [ ] 打赏页面正常显示
- [ ] 微信收款码显示正常
- [ ] 支付宝收款码显示正常
- [ ] BTC地址显示正常
- [ ] USDT地址显示正常
- [ ] 关于我页面显示正常
- [ ] 复制地址功能正常

### 3. 安全测试

- [ ] Release版本无详细日志输出
- [ ] 使用调试器时程序正确退出（Release版本）
- [ ] 篡改检测正常工作
- [ ] SHA-256校验正常工作

---

## 📊 升级前后对比

| 项目 | 升级前 | 升级后 | 改进 |
|------|--------|--------|------|
| 哈希算法 | MD5 | SHA-256 | ✅ 更安全 |
| 加密模块 | 分散 | 统一 | ✅ 易维护 |
| 日志输出 | 始终启用 | 可控制 | ✅ 更安全 |
| 反调试 | 无 | 多层检测 | ✅ 更安全 |
| 代码质量 | 重复代码 | 统一接口 | ✅ 更清晰 |

---

## ⚠️ 重要注意事项

### 1. 数据库兼容性

- ✅ 保留了 `md5_hash` 字段以保持向后兼容
- ⚠️ 新版本使用 `md5_hash` 字段存储SHA-256值（字段名未改变）
- ⚠️ 旧数据库的图像将无法加载（需要重新导入）

### 2. 密钥管理

- ⚠️ 默认密钥仍然硬编码，建议后续版本改进
- ✅ 已统一密钥管理位置
- 💡 建议：在 `uAntiTamperPackage.Initialize` 时设置强密钥

### 3. 日志文件

Debug版本会生成以下日志文件：
- `antitamper_debug.log` - 防篡改包日志
- `aboutme_debug.log` - AboutMe框架日志
- `FRAME_CONSTRUCTOR_DEBUG.log` - 构造函数日志

Release版本不会生成这些文件。

### 4. 性能影响

- SHA-256比MD5略慢（约10-20%）
- 对用户体验影响可忽略不计
- 反调试检测耗时 < 100ms

---

## 🐛 常见问题

### Q1: 升级后图像无法显示？

**原因**：数据库中的哈希值是MD5，但新代码使用SHA-256验证。

**解决**：重新导入所有图像。

```bash
ImportImages.exe
```

### Q2: Release版本仍然生成日志文件？

**原因**：未正确定义 `RELEASE` 编译符号。

**解决**：
1. 检查项目选项中的 "Conditional defines"
2. 确保包含 `RELEASE`
3. 重新编译

### Q3: 反调试保护不工作？

**原因**：未定义 `RELEASE` 符号，或在Debug模式下运行。

**解决**：使用Release配置编译和运行。

### Q4: 编译错误 "Undeclared identifier: TAntiDebug"？

**原因**：未添加 `uAntiDebug` 到uses子句。

**解决**：
```pascal
uses
  // ... 其他单元
  uAntiDebug;
```

---

## 📝 回滚步骤

如果升级出现问题，可以回滚：

### 1. 恢复数据库

```bash
copy MoveC.db.backup MoveC.db
```

### 2. 恢复代码

使用版本控制系统恢复到升级前的版本：

```bash
git checkout HEAD~1 uAntiTamperPackage.pas
git checkout HEAD~1 FrameAboutMe.pas
```

### 3. 删除新文件

```bash
del uAntiDebug.pas
del UpgradeDatabase.sql
```

---

## 🎯 下一步计划

升级到**方案二：标准升级**时需要：

1. ✅ 集成 `uBasicProtection.pas` 的AES-256加密
2. ✅ 实现动态密钥生成
3. ✅ 添加数据库加密
4. ✅ 实现多层校验机制
5. ✅ 添加程序自身完整性检查

预计时间：1-2周

---

## 📞 技术支持

如遇到问题，请检查：

1. **日志文件**（Debug版本）
   - `antitamper_debug.log`
   - `aboutme_debug.log`

2. **编译输出**
   - 查看编译警告和错误

3. **数据库状态**
   - 使用SQLite工具检查表结构

---

## ✅ 升级检查清单

完成升级后，请确认：

- [ ] 已备份原数据库
- [ ] 已更新所有代码文件
- [ ] 已重新导入打赏图像
- [ ] Debug版本编译成功
- [ ] Release版本编译成功
- [ ] 所有功能测试通过
- [ ] 反调试保护工作正常
- [ ] 无详细日志泄露（Release版本）
- [ ] 已删除旧的备份文件

---

**升级完成日期**: _____________

**升级执行人**: _____________

**版本号**: v1.1.0 (SHA-256升级版)

**上一版本**: v1.0.0 (MD5版本)

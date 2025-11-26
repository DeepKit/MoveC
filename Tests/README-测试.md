# 单元测试框架

## 概述

本测试框架使用 **DUnitX** 对文件同步系统的核心功能进行自动化测试。

## 测试覆盖范围

### 1. 数据库测试 (`TestSyncDatabase.pas`)

✅ **数据库连接**
- 测试数据库文件创建
- 测试连接成功性

✅ **任务 CRUD 操作**
- 创建任务 (Create)
- 读取任务 (Read)
- 更新任务 (Update)
- 删除任务 (Delete)

✅ **持久化测试**
- 测试关闭重开后数据仍然存在
- 测试多个任务的保存和检索

### 2. 任务对象测试 (`TestSyncTask.pas`)

✅ **任务创建**
- 带数据库的任务创建
- 不带数据库的任务创建

✅ **任务保存和加载**
- Save 方法测试
- Load 方法测试
- 保存后重新加载数据一致性

✅ **任务更新**
- 更新任务属性
- 验证更新持久化

### 3. 同步执行测试 (`TestSyncExecution.pas`)

✅ **基本同步功能**
- 完整同步测试
- 文件数量验证
- 目录结构验证

✅ **增量同步**
- 修改文件检测
- 仅更新变化的文件

✅ **忽略规则**
- *.tmp, *.log 等文件过滤
- 通配符规则测试

✅ **子目录处理**
- 递归同步
- 子目录文件验证

✅ **错误处理**
- 不存在的源路径
- 空目录处理

---

## 运行测试

### 方法 1：使用批处理脚本（推荐）

```cmd
cd Tests
RunTests.bat
```

**输出示例：**
```
========================================
  编译并运行单元测试
========================================

[1/3] 编译测试项目...
Embarcadero Delphi for Win64 compiler version 36.0
...

[2/3] 运行测试...
========================================

DUnitX - Delphi Unit Testing Framework
Copyright (C) 2013 Vincent Parrett

[TestSyncDatabase.TestDatabaseConnection] PASS (12 ms)
[TestSyncDatabase.TestCreateSyncTask] PASS (8 ms)
[TestSyncDatabase.TestUpdateSyncTask] PASS (10 ms)
[TestSyncDatabase.TestDeleteSyncTask] PASS (7 ms)
...

Tests Found    : 18
Tests Passed   : 18
Tests Failed   : 0
Tests Errored  : 0

========================================
[3/3] 测试完成
========================================

✓ 所有测试通过！
```

### 方法 2：使用 Delphi IDE

1. 打开 `Tests\SyncTests.dpr`
2. 按 **F9** 运行
3. 查看控制台输出

### 方法 3：命令行直接运行

```cmd
cd Tests
dcc64 SyncTests.dpr
SyncTests.exe --console
```

---

## 测试结果解读

### 成功输出

```
Tests Found    : 18
Tests Passed   : 18
Tests Failed   : 0
```

✅ **所有测试通过** = 核心功能正常工作

### 失败输出

```
[TestSyncDatabase.TestTaskPersistence] FAIL (15 ms)
  Expected: 'Persistent Task'
  Actual  : ''
  Message : 重新打开后任务应该仍然存在

Tests Found    : 18
Tests Passed   : 17
Tests Failed   : 1
```

❌ **测试失败** = 发现 Bug，需要修复

---

## 测试驱动开发 (TDD) 流程

### 1. 发现问题时

**不要手工测试！** 应该：

```
步骤 1: 编写失败的测试
步骤 2: 运行测试，确认失败
步骤 3: 修复代码
步骤 4: 运行测试，确认通过
步骤 5: 重构（如需要）
```

### 2. 添加新功能时

```
步骤 1: 先写测试（描述预期行为）
步骤 2: 运行测试（应该失败）
步骤 3: 实现功能
步骤 4: 运行测试（应该通过）
```

---

## 示例：如何添加新测试

### 场景：测试大文件同步

```pascal
[Test]
procedure TestLargeFileSync;
var
  Task: TSyncTask;
  LargeFile: string;
  SourceSize, TargetSize: Int64;
begin
  // Arrange - 创建大文件
  LargeFile := TPath.Combine(FSourceDir, 'large.bin');
  CreateLargeFile(LargeFile, 100 * 1024 * 1024); // 100 MB
  
  Task := TSyncTask.CreateWithDatabase(FDatabase);
  try
    Task.SourcePath := FSourceDir;
    Task.TargetPath := FTargetDir;
    
    // Act
    Task.Execute;
    
    // Assert
    Assert.IsTrue(TFile.Exists(TPath.Combine(FTargetDir, 'large.bin')));
    
    SourceSize := TFile.GetSize(LargeFile);
    TargetSize := TFile.GetSize(TPath.Combine(FTargetDir, 'large.bin'));
    
    Assert.AreEqual(SourceSize, TargetSize, '大文件大小应该匹配');
  finally
    Task.Free;
  end;
end;
```

---

## 持续集成 (CI)

### 自动化测试脚本

可以在 CI 环境中运行：

```cmd
@echo off
cd Tests
dcc64 SyncTests.dpr
if %ERRORLEVEL% NEQ 0 exit /b 1

SyncTests.exe --console --xml=test-results.xml
if %ERRORLEVEL% NEQ 0 exit /b 1

echo All tests passed!
exit /b 0
```

### GitHub Actions 示例

```yaml
name: Run Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Tests
        run: |
          cd Tests
          RunTests.bat
```

---

## 测试覆盖的 Bug

### Bug 1: 数据库未连接 ✅
**测试：** `TestDatabaseConnection`  
**发现：** FDatabase.Connect 未被调用  
**修复：** MainSyncForm.pas FormCreate 中添加 Connect 调用

### Bug 2: 任务未持久化 ✅
**测试：** `TestTaskPersistence`, `TestTaskSaveAndReload`  
**发现：** Save 方法未正确调用  
**修复：** NewTask1Click 中添加 NewTask.Save

### Bug 3: 删除未持久化 ✅
**测试：** `TestDeleteSyncTask`  
**发现：** DeleteTask1Click 未调用数据库删除  
**修复：** 添加 FDatabase.DeleteSyncTask(TaskID)

### Bug 4: TaskEditForm 类型错误 ✅
**测试：** `TestTaskSaveToDatabase`  
**发现：** FTask 指针类型导致访问错误  
**修复：** 改回对象类型

---

## 性能基准

测试执行时间参考：

| 测试套件 | 测试数 | 平均时间 |
|---------|--------|---------|
| TestSyncDatabase | 7 | ~50 ms |
| TestSyncTask | 6 | ~80 ms |
| TestSyncExecution | 6 | ~200 ms |
| **总计** | **19** | **~330 ms** |

✅ 测试应该在 1 秒内完成

---

## 故障排查

### Q: 测试编译失败

**检查：**
1. DUnitX 是否正确安装
2. 路径引用是否正确
3. 依赖单元是否存在

### Q: 测试运行时崩溃

**检查：**
1. Setup 和 TearDown 是否正确清理
2. 临时文件是否有权限访问
3. 数据库连接是否正常

### Q: 某个测试失败

**步骤：**
1. 查看失败的测试名称
2. 查看 Expected vs Actual 值
3. 在 IDE 中调试该测试
4. 修复代码或测试

---

## 最佳实践

### ✅ DO

- 每个功能都写测试
- 测试应该独立运行
- 使用 Setup/TearDown 清理
- 测试名称要清晰描述意图
- Assert 消息要明确

### ❌ DON'T

- 不要依赖测试执行顺序
- 不要使用生产数据库
- 不要跳过失败的测试
- 不要写没有 Assert 的测试
- 不要让测试依赖外部资源

---

## 下一步

1. ✅ 运行现有测试，确保全部通过
2. 📝 为新功能添加测试
3. 🐛 发现 Bug 时先写测试重现
4. 🔄 定期运行测试（每次提交前）
5. 📊 关注测试覆盖率

---

## 参考资源

- [DUnitX GitHub](https://github.com/VSoftTechnologies/DUnitX)
- [Delphi Unit Testing](https://docwiki.embarcadero.com/RADStudio/en/Unit_Testing)
- [Test-Driven Development](https://en.wikipedia.org/wiki/Test-driven_development)

---

**记住：测试是代码质量的保障！** 🎯

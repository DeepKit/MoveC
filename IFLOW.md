# MoveC 项目概览

## 项目简介

MoveC 是一个使用 Delphi 开发的 Windows 应用程序，主要用于磁盘空间管理和文件迁移。该项目包含一个核心的图形用户界面应用程序（`C盘瘦身.exe`）以及多个辅助工具，如图像导入工具（`ImportImages.exe`）、数据库检查工具等。

项目的核心安全特性是其防篡改机制，该机制使用 AES-256 加密和 SHA-256 哈希来保护敏感数据（如支付二维码图像），防止数据被篡改。

## 技术栈

- **编程语言**: Delphi (Object Pascal)
- **数据库**: SQLite
- **加密库**: Windows CryptoAPI (用于 AES-256 加密)
- **GUI 框架**: VCL (Visual Component Library)
- **数据库访问**: FireDAC

## 项目结构

```
D:\SynologyDrive\Progs\_Delphi\MoveC\
├── 核心应用源码
│   ├── C盘瘦身.dpr              // 主程序项目文件
│   ├── uMain.pas                // 主窗体逻辑
│   ├── uMain.dfm                // 主窗体设计
│   ├── uConfigManager.pas       // 配置管理
│   ├── uConfigManager.dfm       // 配置管理窗体
│   ├── uDirectoryMigration.pas  // 目录迁移逻辑
│   ├── uDuplicateFiles.pas      // 重复文件处理
│   ├── uSmartDuplicateCleanup.pas // 智能重复文件清理
│   ├── uCleanupManager.pas      // 清理管理器
│   ├── uImageDatabase.pas       // 图像数据库操作
│   ├── uAntiTamperPackage.pas   // 防篡改核心包
│   ├── uBasicProtection.pas     // 基础加密保护
│   ├── uImageSecurity.pas       // 图像安全（可能已废弃）
│   ├── uMessageBox.pas          // 自定义消息框
│   ├── uMessageBox.dfm          // 自定义消息框窗体
│   ├── uSplash.pas              // 启动画面
│   ├── uSplash.dfm              // 启动画面窗体
│   ├── uStyles.pas              // 样式管理
│   ├── uStrings.pas             // 字符串资源
│   ├── uIconManager.pas         // 图标管理
│   ├── uRestartManager.pas      // 重启管理器
│   ├── uPostRebootRepair.pas    // 重启后修复
│   └── uSimpleSecureManager.pas // 简单安全管理
├── 辅助工具
│   ├── ImportImages.dpr         // 图像导入工具
│   ├── BackfillTool.dpr         // 数据库回填工具
│   ├── TestDatabase.dpr         // 数据库测试工具
│   ├── TestDecrypt.dpr          // 解密测试工具
│   ├── TestImport.dpr           // 导入测试工具
│   ├── TestLogger.dpr           // 日志测试工具
│   ├── SimpleCheck.dpr          // 简单检查工具
│   ├── DirectInsert.dpr         // 直接插入工具
│   ├── CheckDB.dpr              // 数据库检查工具
│   ├── CountRecords.dpr         // 记录计数工具
│   ├── CreateDB.dpr             // 数据库创建工具
│   └── ExtractImagesToFiles.dpr // 图像导出工具
├── 资源文件
│   ├── Images.RES               // 图像资源文件
│   ├── Images.rc                // 资源编译脚本
│   └── assets\                  // 图像资产目录
├── 数据库文件
│   ├── MoveC.db                 // 主数据库文件
│   ├── MoveC.db-shm             // SQLite 共享内存文件
│   └── MoveC.db-wal             // SQLite 预写日志文件
├── 构建输出
│   ├── Win32\                   // 32位构建输出目录
│   └── Win64\                   // 64位构建输出目录
└── 文档
    ├── 快速开始指南.md           // 快速入门指南
    ├── 方案二升级指南_AES256.md  // AES-256 升级指南
    ├── ImportImages使用说明.md   // 图像导入工具说明
    ├── SECURITY_AND_MIGRATION.md // 安全与迁移文档
    └── ...                      // 其他文档
```

## 核心模块分析

### 1. 防篡改系统 (`uAntiTamperPackage.pas`)

这是项目的核心安全模块，负责图像数据的加密、解密和完整性校验。

- **加密算法**: 支持 XOR（已废弃）和 AES-256-CBC。
- **哈希算法**: 使用 SHA-256 进行数据完整性校验。
- **密钥管理**: 支持静态密钥和动态密钥生成。
- **数据库集成**: 与 SQLite 数据库集成，自动创建和升级表结构。

### 2. 基础保护模块 (`uBasicProtection.pas`)

提供底层的加密和哈希功能，基于 Windows CryptoAPI 实现。

- **AES-256 加密/解密**: 使用 CBC 模式和 PKCS7 填充。
- **随机 IV 生成**: 每次加密都生成新的随机初始化向量。
- **HMAC 计算**: 用于数据完整性验证。
- **Salted Encryption**: 使用 salt 派生密钥，增强安全性。

### 3. 图像数据库模块 (`uImageDatabase.pas`)

负责图像数据的存储和检索，以及数据库连接管理。

- **数据库连接**: 使用 FireDAC 连接 SQLite 数据库。
- **数据加密**: 在保存和加载图像时调用防篡改模块进行加解密。
- **完整性校验**: 在加载图像时进行 SHA-256 校验。
- **安全存储**: 使用 DPAPI 加密存储数据库密码。

### 4. 图像导入工具 (`ImportImages.dpr`)

一个命令行工具，用于将图像文件导入到 SQLite 数据库中。

- **命令行参数**: 接受图像键、图像路径和地址文本作为参数。
- **加密存储**: 使用 AES-256 加密图像数据后存储到数据库。
- **日志记录**: 记录导入过程中的详细信息。

## 构建和运行

### 构建主程序

1. 打开 `C盘瘦身.dproj` 项目文件。
2. 在 Delphi IDE 中配置构建选项（Debug/Release）。
3. 编译项目生成可执行文件。

### 运行图像导入工具

1. 编译 `ImportImages.dpr` 生成 `ImportImages.exe`。
2. 在命令行中运行：
   ```
   ImportImages.exe <image_key> <image_path> <address_text>
   ```
   例如：
   ```
   ImportImages.exe wechat assets\wechat.png "微信收款码"
   ```

### 数据库配置

数据库文件 `MoveC.db` 位于项目根目录。数据库密码可以通过以下方式提供：
1. 环境变量 `MOVEC_PASSWORD`
2. 同目录下的 `MoveC.secure.ini` 配置文件
3. 程序代码中硬编码（不推荐）

## 安全特性

1. **AES-256 加密**: 图像数据在存储前使用 AES-256 加密。
2. **SHA-256 校验**: 加载图像时进行完整性校验，防止数据被篡改。
3. **动态密钥**: 结合程序信息生成动态密钥，增加破解难度。
4. **HMAC 验证**: 使用 HMAC 验证数据完整性，防止重放攻击。
5. **DPAPI 保护**: 数据库密码使用 Windows DPAPI 进行加密存储。

## 开发约定

1. **编码规范**: 遵循 Delphi 的编码规范。
2. **命名约定**: 使用 PascalCase 命名类和方法，使用 camelCase 命名变量。
3. **注释**: 在关键代码处添加注释，解释实现逻辑。
4. **异常处理**: 对可能出错的操作进行异常处理，确保程序稳定性。
5. **日志记录**: 在关键操作处添加日志记录，便于调试和问题排查。
# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

项目语言与平台
- Delphi (VCL/Console)，Windows
- 数据库：SQLite（通过 FireDAC）

一、常用命令（PowerShell 或 CMD 下）
- 编译图像导入工具（优先使用已提供脚本）
  - 运行脚本（自动探测 dcc32/dcc64）：
    - .\\compile_importimages.bat
    - .\\compile_checkdb.bat
    - .\\compile_extractimages.bat
  - 或直接用编译器：
    - dcc32 .\\ImportImages.dpr
    - dcc32 .\\CheckDB.dpr
    - dcc32 .\\ExtractImagesToFiles.dpr
- 运行工具：
  - .\\ImportImages.exe        将 assets 目录图片导入数据库
  - .\\CheckDB.exe            检查数据库中 5 个关键图片是否存在并导出校验文件
  - .\\ExtractImagesToFiles.exe 从数据库导出图片为文件（已切换至 FireDAC/uImageDatabase，统一使用 MoveC.db 与小写键）
- 打包防篡改模块：
  - .\PackageAntiTamper.bat   在 AntiTamperPackage/ 下生成可迁移的包与示例
- Lint/格式化：本仓库未配置专用 lint/格式化命令
- 测试：本仓库未集成 DUnit/DUnitX 等测试框架
  - 建议用以下“功能验证”替代单测执行：
    - 导入数据：先运行 .\ImportImages.exe
    - 单次验证：运行 .\CheckDB.exe（会针对 wechat/alipay/btc/usdt/aboutme 做完整性验证并导出 check_*.dat）

二、关键运行前置
- 需要安装 Delphi（dcc32/dcc64 在 PATH）
- FireDAC SQLite 驱动可用
- 数据库文件路径由代码自动推断（见 TImageDatabase.GetProjectDatabasePath），通常位于项目根目录 MoveC.db

三、架构总览（大图景）
1) 应用层（UI 与交互）
- 主窗体：uMain.pas（VCL Form TfrmMain）
  - 左右目录树浏览、空间分析、迁移执行、清理工具条、状态栏
  - AboutMe 子面板：承载 FrameAboutMe（个人/项目信息与关联图片）
  - 集成安全与校验：通过 TSimpleSecureManager.LoadAndVerify(FFrameAboutMe) 在 FormShow 时加载 AboutMe 内容并做完整性校验（失败路径当前为“提示后继续运行”）
  - 清理能力：委托 uCleanupManager 执行清空回收站、清理临时/日志/Windows 更新缓存等操作
  - 迁移能力：执行复制、备份、创建链接（优先 mklink /J，失败回退 mklink /D），并记录最近备份路径
  - 多处菜单/按钮“正在开发中”占位（智能迁移、重复文件清理、配置管理、日志管理、主题切换等）

2) 安全层（防篡改与完整性）
- AntiTamperPackage/
  - uAntiTamperPackage.pas：对外统一接口（初始化、库表准备、保存/加载安全图像、校验失败时的安全响应）
  - uImageSecurity.pas：图像加解密与 MD5（XOR 对称加密 + MD5 校验）
  - AntiTamper_README.md：给出 TAntiTamperConfig、Setup/UpgradeDatabase、SaveSecureImage/LoadSecureImage 等标准用法
- 工程内使用：
  - PROJECT_SUMMARY.md 描述已将 AboutMe 模块接入防篡改流程（加密存储 + MD5 校验 + 安全响应）

3) 数据访问层（SQLite + FireDAC）
- uImageDatabase.pas：FireDAC 封装
  - Connect/Disconnect/IsConnected
  - CreateTables：建 images 表并尝试补充 md5_hash 字段与索引
  - SaveImageData / LoadImageData / LoadImageAndText / ImageExists / GetImageList
  - GetProjectDatabasePath：定位项目根路径数据库（MoveC.db）
  - 日志：当前直接 Writeln/OutputDebugString（控制台与调试器下可见）
- （已简化）仅保留 uImageDatabase.pas（FireDAC/SQLite）作为统一数据访问层
- 数据模型（见 AntiTamper README 与建表语句）：
  - images(id, image_key UNIQUE, image_data BLOB, address_text, description, md5_hash, created_at, updated_at)

4) 辅助控制台工具
- ImportImages.dpr：从 assets 目录将图像与附带文本导入数据库（使用 uImageDatabase，键值 wechat/alipay/btc/usdt/aboutme）
- CheckDB.dpr：连接 MoveC.db，按固定键依次加载、输出大小、导出 check_*.dat 用于人工校验
- ExtractImagesToFiles.dpr：使用 uImageDatabase（FireDAC）连接 MoveC.db，按统一小写键导出为文件
- 打包脚本：PackageAntiTamper.bat 生成 AntiTamperPackage/ 并包含示例单元

四、与现有文档的要点同步
- PROJECT_SUMMARY.md：
  - 已完成：图像显示系统重构（设计时 FireDAC）、数据库连接优化、路径自动发现、防篡改机制（加密+MD5+响应）、统一加载逻辑
- AntiTamper_README.md：
  - 配置项（EncryptionKey/DownloadURL/TableName/Logging）与标准调用流程（Initialize/Setup/Upgrade/Save/Load）

五、已知差异与注意事项（供后续工作快速对齐）
- 已统一安全策略：篡改校验失败将打开官网并退出程序（uMain.pas 已调整为严格模式）。
- 已统一数据契约：统一使用小写键（wechat/alipay/btc/usdt/aboutme）。
- 已统一数据库文件名：工具与应用均使用 MoveC.db。
- 已收敛数据访问栈：移除 uSQLiteDB，统一使用 uImageDatabase（FireDAC）。
- 已移除默认敏感字面量：TImageDatabase.Create 默认密码参数改为空字符串。

六、后续可选改进（非泛化，均针对本仓库现状）
- 统一安全策略：将 uMain 中 FSecureManager 验证失败逻辑与 AntiTamper_README 的“强制退出与跳转”保持一致，或在配置中显式开关。
- 统一数据契约：
  - 规范 image_key 大小写（统一小写或大写），并在工具侧校验；统一数据库文件名（建议 MoveC.db）。
- 构建脚本补齐：
  - 参照 compile_importimages.bat，为 CheckDB/ExtractImagesToFiles 增补同类脚本；或补充 .dproj 以便 msbuild。
- 加密算法升级（如后续对安全性有更高要求）：
  - 从 XOR 迁移到 AES-CTR/GCM 等（结合 System.Hash 与 OpenSSL/Delphi 加解密库），并以版本号做平滑升级。
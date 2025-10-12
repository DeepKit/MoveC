# ImportImages 图像导入工具使用说明

**版本**: v1.2.0 (AES-256加密版)  
**更新日期**: 2025-10-10  
**适用场景**: 导入打赏二维码图像到数据库

---

## 📋 工具概述

`ImportImages.exe` 是一个命令行工具，用于将打赏二维码图像导入到数据库中，并使用**AES-256加密**和**SHA-256哈希**保护数据。

### 核心功能

- ✅ 读取assets目录下的图像文件
- ✅ 使用AES-256-CBC加密图像数据
- ✅ 计算SHA-256哈希值
- ✅ 保存到SQLite数据库
- ✅ 自动初始化防篡改包
- ✅ 详细的日志输出

---

## 🔧 编译工具

### 方法一：使用批处理脚本

```bash
compile_importimages.bat
```

### 方法二：手动编译

```bash
dcc32 ImportImages.dpr
```

### 编译输出

- `ImportImages.exe` - 可执行文件
- 位置：项目根目录或Win32\Debug目录

---

## 🚀 使用步骤

### 步骤1：准备图像文件

确保以下图像文件存在于 `assets\` 目录：

| 文件名 | 用途 | 必需 |
|--------|------|------|
| `wechat.png` | 微信收款码 | ✅ |
| `AliPay.png` | 支付宝收款码 | ✅ |
| `btc.png` | 比特币地址二维码 | ✅ |
| `usdt.png` | USDT地址二维码 | ✅ |
| `itsMe.jpg` | 关于我页面图片 | ✅ |

### 步骤2：运行导入工具

```bash
# 直接运行
ImportImages.exe

# 或从Win32\Debug目录运行
Win32\Debug\ImportImages.exe
```

### 步骤3：查看输出

工具会显示详细的导入过程：

```
=== 图像数据导入工具 (AES-256加密版) ===

初始化防篡改包...
防篡改包初始化完成 - 使用AES-256加密

初始化FireDAC驱动...
数据库路径: D:\...\MoveC.db
正在连接数据库...
数据库连接成功

开始导入图像文件和地址文本...
[INFO] 图像 wechat 的SHA-256: abc123...
[INFO] 使用AES-256加密，数据长度: 12345 bytes
成功导入图像: wechat (12000 字节, 地址: 微信收款码)
...

图像导入完成

数据库中的图像列表:
  - wechat
  - alipay
  - btc
  - usdt
  - aboutme

按回车键退出...
```

---

## 🔐 加密详解

### AES-256加密流程

```
原始图像文件
    ↓
读取为字节数组
    ↓
计算SHA-256哈希
    ↓
PKCS7填充（16字节对齐）
    ↓
生成随机IV（16字节）
    ↓
AES-256-CBC加密
    ↓
保存到数据库（加密数据 + SHA-256哈希）
```

### 密钥配置

```pascal
Config.EncryptionKey := 'MoveC_AntiTamper_Key_2025';
Config.EncryptionType := etAES256;
```

**重要**: 密钥必须与主程序一致！

---

## 📊 数据库结构

### images表

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER | 主键 |
| image_key | TEXT | 图像标识（唯一） |
| image_data | BLOB | 加密的图像数据 |
| address_text | TEXT | 收款地址文本 |
| description | TEXT | 描述信息 |
| md5_hash | TEXT | SHA-256哈希（字段名保留兼容） |
| created_at | DATETIME | 创建时间 |
| updated_at | DATETIME | 更新时间 |

**注意**: `md5_hash` 字段实际存储的是SHA-256哈希值。

---

## 🎯 导入的图像列表

### 1. wechat - 微信收款码
- **文件**: `assets\wechat.png`
- **标识**: `wechat`
- **地址**: `微信收款码`

### 2. alipay - 支付宝收款码
- **文件**: `assets\AliPay.png`
- **标识**: `alipay`
- **地址**: `支付宝收款码`

### 3. btc - 比特币地址
- **文件**: `assets\btc.png`
- **标识**: `btc`
- **地址**: `bc1qze0ggsrdtjqwjpjfufydsuyjxc08tgcq5xkct3`

### 4. usdt - USDT地址
- **文件**: `assets\usdt.png`
- **标识**: `usdt`
- **地址**: `TH1NazpoEpUqcEotGzLPHs13SbLDJKKCys`

### 5. aboutme - 关于我
- **文件**: `assets\itsMe.jpg`
- **标识**: `aboutme`
- **地址**: `C盘瘦身工具 - 开发者: 好记忆管理工作室 - 官网: www.goodmem.cn`

---

## ⚠️ 重要注意事项

### 1. 何时需要重新导入？

必须重新导入的情况：
- ✅ 升级到AES-256加密后（首次）
- ✅ 更换了加密密钥
- ✅ 修改了图像文件
- ✅ 数据库损坏或丢失

### 2. 加密密钥一致性

**关键**: ImportImages和主程序必须使用相同的密钥！

```pascal
// ImportImages.dpr
Config.EncryptionKey := 'MoveC_AntiTamper_Key_2025';

// uMain.pas
Config.EncryptionKey := 'MoveC_AntiTamper_Key_2025';
```

### 3. 数据库备份

导入前建议备份：
```bash
copy MoveC.db MoveC.db.backup
```

### 4. 文件路径

- 工具会自动查找项目根目录下的 `MoveC.db`
- 图像文件必须在 `assets\` 目录
- 支持从 `Win32\Debug` 目录运行

---

## 🐛 常见问题

### Q1: 提示"图像文件不存在"？

**原因**: assets目录中缺少图像文件。

**解决**:
1. 检查 `assets\` 目录是否存在
2. 确认所有图像文件都在目录中
3. 检查文件名大小写（区分大小写）

### Q2: 提示"无法连接到数据库"？

**原因**: 数据库文件不存在或权限不足。

**解决**:
1. 确认 `MoveC.db` 存在
2. 检查文件权限
3. 关闭其他占用数据库的程序

### Q3: 导入后主程序无法显示图像？

**原因**: 加密密钥不一致。

**解决**:
1. 检查ImportImages和主程序的密钥配置
2. 确保都使用 `etAES256` 加密类型
3. 重新导入图像

### Q4: 提示"SHA-256校验失败"？

**原因**: 数据库中的数据损坏或被篡改。

**解决**:
1. 删除数据库文件
2. 重新运行ImportImages导入

---

## 📝 日志说明

### 日志级别

- `[INFO]` - 信息日志
- `[ERROR]` - 错误日志

### 关键日志

```
[INFO] 图像 wechat 的SHA-256: abc123...
```
- 显示计算的SHA-256哈希值

```
[INFO] 使用AES-256加密，数据长度: 12345 bytes
```
- 显示加密算法和数据大小

```
[INFO] 图像数据已保存: wechat (12000 字节)
```
- 确认保存成功

---

## 🔄 版本历史

### v1.2.0 (2025-10-10)
- ✅ 升级到AES-256-CBC加密
- ✅ 使用SHA-256哈希
- ✅ 集成防篡改包
- ✅ 动态密钥支持

### v1.1.0 (2025-10-10)
- ✅ 升级到SHA-256哈希
- ✅ 保留XOR加密

### v1.0.0
- ✅ 初始版本
- ✅ MD5哈希
- ✅ XOR加密

---

## 🚀 高级用法

### 自定义密钥

修改 `ImportImages.dpr` 中的密钥配置：

```pascal
Config.EncryptionKey := 'YourCustomKey2025';
```

**注意**: 主程序也需要同步修改！

### 添加新图像

在 `ImportImages.dpr` 中添加：

```pascal
ImportImageFile(Database, 'assets\newimage.png', 'newkey', '新图像地址');
```

### 批量导入

可以编写循环批量导入：

```pascal
var
  Files: TStringDynArray;
  FileName: string;
begin
  Files := TDirectory.GetFiles('assets', '*.png');
  for FileName in Files do
  begin
    ImportImageFile(Database, FileName, 
      ChangeFileExt(ExtractFileName(FileName), ''), 
      '自动导入');
  end;
end;
```

---

## 📚 相关文档

| 文档 | 说明 |
|------|------|
| `方案二升级指南_AES256.md` | AES-256技术详解 |
| `防篡改系统完整升级报告.md` | 完整升级总结 |
| `UPGRADE_GUIDE.md` | 方案一升级指南 |

---

## ✅ 导入检查清单

### 导入前
- [ ] 已备份数据库
- [ ] 所有图像文件就绪
- [ ] 已编译ImportImages.exe
- [ ] 已关闭主程序

### 导入中
- [ ] 工具正常启动
- [ ] 显示"AES-256加密版"
- [ ] 所有图像导入成功
- [ ] 无错误日志

### 导入后
- [ ] 数据库文件已更新
- [ ] 启动主程序测试
- [ ] 打赏页面显示正常
- [ ] 所有图像加载成功

---

**工具版本**: v1.2.0  
**加密算法**: AES-256-CBC  
**哈希算法**: SHA-256  
**安全等级**: 🔐 军事级

**升级完成！** 🎉

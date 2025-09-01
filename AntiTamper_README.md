# 防篡改机制包 (Anti-Tamper Package)

## 概述

这是一个完整的图像防篡改解决方案，提供加密存储、完整性校验和安全响应功能。

## 核心文件

- `uAntiTamperPackage.pas` - 主要的防篡改包
- `uImageSecurity.pas` - 图像安全工具类（可选，功能已集成到主包中）

## 功能特性

### 🔐 加密保护
- XOR对称加密算法
- 可配置的加密密钥
- 自动加密存储，自动解密加载

### 🔍 完整性校验
- MD5哈希验证
- 检测数据篡改
- 自动校验解密后的数据

### 🚨 安全响应
- 篡改检测时立即停止程序
- 显示安全警告对话框
- 自动导航到官方下载页面

### 📊 数据库集成
- 自动创建表结构
- 支持现有数据库升级
- 兼容FireDAC组件

## 使用方法

### 1. 初始化配置

```pascal
uses uAntiTamperPackage;

var
  Config: TAntiTamperConfig;
begin
  // 获取默认配置
  Config := TAntiTamperPackage.GetDefaultConfig;
  
  // 自定义配置
  Config.EncryptionKey := 'YourCustomKey2025';
  Config.DownloadURL := 'https://yoursite.com/download';
  Config.TableName := 'secure_images';
  Config.EnableLogging := True;
  Config.LogFileName := 'security.log';
  
  // 初始化
  TAntiTamperPackage.Initialize(Config);
end;
```

### 2. 设置数据库

```pascal
// 创建新的防篡改表
TAntiTamperPackage.SetupDatabase(FDConnection1);

// 或升级现有数据库
TAntiTamperPackage.UpgradeDatabase(FDConnection1);
```

### 3. 保存安全图像

```pascal
var
  ImageData: TBytes;
begin
  // 从文件读取图像数据
  ImageData := TFile.ReadAllBytes('image.png');
  
  // 保存为加密图像
  TAntiTamperPackage.SaveSecureImage(FDConnection1, 'my_image', ImageData, 
    'Some address text', 'Image description');
end;
```

### 4. 加载安全图像

```pascal
var
  AddressText: string;
begin
  // 加载并校验图像
  if TAntiTamperPackage.LoadSecureImage(FDTable1, 'my_image', Image1, AddressText) then
  begin
    // 图像加载成功，已通过完整性校验
    Label1.Caption := AddressText;
  end
  else
  begin
    // 加载失败或校验失败
    ShowMessage('图像加载失败');
  end;
end;
```

## 数据库表结构

```sql
CREATE TABLE images (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  image_key TEXT NOT NULL UNIQUE,      -- 图像标识符
  image_data BLOB NOT NULL,            -- 加密的图像数据
  address_text TEXT,                   -- 关联的地址文本
  description TEXT,                    -- 图像描述
  md5_hash TEXT NOT NULL,              -- 原始图像的MD5校验值
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## 安全机制

### 加密流程
1. 计算原始图像数据的MD5值
2. 使用XOR算法加密图像数据
3. 将加密数据和MD5值存储到数据库

### 解密和校验流程
1. 从数据库读取加密数据和MD5值
2. 解密图像数据
3. 计算解密数据的MD5值
4. 与存储的MD5值比较
5. 如果不匹配，触发安全响应

### 安全响应
- 显示安全警告对话框
- 提供官方下载链接
- 强制退出程序（ExitProcess(1)）

## 迁移到其他项目

### 步骤1：复制文件
- 复制 `uAntiTamperPackage.pas` 到目标项目
- 在项目文件(.dpr)中添加引用

### 步骤2：添加依赖
确保项目包含以下单元：
```pascal
uses
  System.SysUtils, System.Classes, System.Hash, System.NetEncoding,
  Vcl.Dialogs, Vcl.Graphics, Vcl.ExtCtrls, Winapi.ShellAPI, Winapi.Windows,
  FireDAC.Comp.Client, FireDAC.Stan.Param, Data.DB;
```

### 步骤3：初始化和使用
按照上述使用方法进行配置和调用。

## 注意事项

1. **加密密钥安全**：请使用强密钥并妥善保管
2. **数据库备份**：加密后的数据无法直接查看，请做好备份
3. **版本兼容**：升级时确保MD5字段正确迁移
4. **性能考虑**：大图像的加密解密可能需要时间

## 版本历史

- v1.0 (2025-01-XX): 初始版本，支持XOR加密和MD5校验

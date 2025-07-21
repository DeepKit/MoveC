# C盘瘦身工具 - API文档

## 📚 核心方法参考

### TfrmMain 主窗体类

#### 目录大小计算

##### CalculateDirectorySize
```pascal
function CalculateDirectorySize(const APath: string): Int64;
```

**功能**: 递归计算目录及所有子目录的总大小

**参数**:
- `APath`: 要计算的目录路径

**返回值**: 
- `Int64`: 目录总大小（字节）

**特点**:
- 完全递归遍历所有子目录
- 包含所有文件的实际大小
- 自动处理访问权限异常
- 适用于获取完整的磁盘占用信息

**使用示例**:
```pascal
var
  DirSize: Int64;
begin
  DirSize := CalculateDirectorySize('C:\Users\Username\Documents');
  // 返回 Documents 目录及所有子目录的总大小
end;
```

---

#### 目录可行性分析

##### AnalyzeDirectoryFeasibility
```pascal
function AnalyzeDirectoryFeasibility(const ADirectoryPath: string): TFileAnalysisResult;
```

**功能**: 分析目录移动的符号链接可行性

**参数**:
- `ADirectoryPath`: 要分析的目录路径

**返回值**: 
- `TFileAnalysisResult`: 分析结果结构体

**分析范围**:
- 基于目录路径和类型判断
- 不递归分析子目录内容
- 快速响应，性能优化

**判断结果**:
- `sfCanLink`: 可以安全移动并创建符号链接
- `sfRisky`: 移动有风险，但符号链接通常可以解决
- `sfCannotMove`: 禁止移动，会严重影响系统运行

**使用示例**:
```pascal
var
  Result: TFileAnalysisResult;
begin
  Result := AnalyzeDirectoryFeasibility('C:\Program Files\SomeApp');
  case Result.SymlinkFeasibility of
    sfCanLink: ShowMessage('可以安全移动');
    sfRisky: ShowMessage('移动有风险');
    sfCannotMove: ShowMessage('禁止移动');
  end;
end;
```

---

#### 根目录检测

##### IsRootOrUserRootDirectory
```pascal
function IsRootOrUserRootDirectory(const APath: string): Boolean;
```

**功能**: 检测是否为根目录或用户根目录

**参数**:
- `APath`: 要检测的目录路径

**返回值**: 
- `Boolean`: True表示是根目录，False表示不是

**检测范围**:
- 驱动器根目录: `C:`, `D:`, `E:` 等
- 用户根目录: `C:\Users`
- 程序根目录: `C:\Program Files`, `C:\Program Files (x86)`
- 系统根目录: `C:\Windows`

**使用示例**:
```pascal
if IsRootOrUserRootDirectory('C:\Users') then
  ShowMessage('这是用户根目录，文件数量巨大');
```

---

#### 状态消息管理

##### AddStatusMessage
```pascal
procedure AddStatusMessage(const AMessage: string);
```

**功能**: 添加普通状态消息

**参数**:
- `AMessage`: 要添加的消息内容

**特点**:
- 自动添加时间戳
- 限制消息数量（最大100条）
- 兼容原有的消息系统

##### AddColoredStatusMessage
```pascal
procedure AddColoredStatusMessage(const AMessage: string; AColor: TColor);
```

**功能**: 添加彩色状态消息

**参数**:
- `AMessage`: 要添加的消息内容
- `AColor`: 消息颜色

**特点**:
- 直接添加到RichEdit控件
- 支持彩色文本显示
- 自动滚动到最新消息

**颜色方案**:
- `clGreen`: 成功、可链接
- `clOlive`: 警告、有风险
- `clRed`: 错误、禁止移动
- `clBlue`: 信息、计算结果
- `clPurple`: 目标相关信息

**使用示例**:
```pascal
AddColoredStatusMessage('✅ 分析完成', clGreen);
AddColoredStatusMessage('⚠️ 移动有风险', clOlive);
AddColoredStatusMessage('❌ 禁止移动', clRed);
```

---

#### 字符串格式化

##### PadRight
```pascal
function PadRight(const AText: string; ALength: Integer): string;
```

**功能**: 字符串右填充，用于格式化显示

**参数**:
- `AText`: 原始文本
- `ALength`: 目标长度

**返回值**: 
- `string`: 填充后的字符串

**特点**:
- 不足长度用空格填充
- 超出长度自动截断并添加省略号
- 用于表格式显示的对齐

---

### 事件处理方法

#### btnCalcDirSizeClick
```pascal
procedure btnCalcDirSizeClick(Sender: TObject);
```

**功能**: 计算目录大小按钮点击事件

**处理流程**:
1. 验证源目录存在性
2. 检测根目录并给出警告
3. 执行目录大小计算
4. 格式化并显示结果
5. 更新lblSize控件

**安全机制**:
- 根目录警告但不阻止
- 异常处理和错误提示
- 进度显示和用户反馈

#### DirListBoxSourceDblClick
```pascal
procedure DirListBoxSourceDblClick(Sender: TObject);
```

**功能**: 源目录双击事件

**处理流程**:
1. 立即更新文件列表显示
2. 同步更新路径编辑框
3. 清除之前的分析结果
4. 提示使用专用按钮计算大小

**优化特点**:
- 响应速度优先
- 不执行耗时操作
- 功能职责分离

---

### 数据结构

#### TFileAnalysisResult
```pascal
type
  TSymlinkFeasibility = (sfCanLink, sfRisky, sfCannotMove);
  
  TFileAnalysisResult = record
    FilePath: string;
    Size: Int64;
    SymlinkFeasibility: TSymlinkFeasibility;
    IsSystemFile: Boolean;
    CanCreateSymlink: Boolean;
    RequiresRestart: Boolean;
    Dependencies: array of string;
    Reason: string;
  end;
```

**字段说明**:
- `FilePath`: 文件或目录路径
- `Size`: 文件或目录大小
- `SymlinkFeasibility`: 符号链接可行性级别
- `IsSystemFile`: 是否为系统文件
- `CanCreateSymlink`: 是否可以创建符号链接
- `RequiresRestart`: 是否需要重启程序
- `Dependencies`: 依赖关系数组
- `Reason`: 判断原因说明

---

### 常量定义

#### 颜色常量
```pascal
const
  COLOR_SUCCESS = clGreen;      // 成功、可链接
  COLOR_WARNING = clOlive;      // 警告、有风险  
  COLOR_ERROR = clRed;          // 错误、禁止移动
  COLOR_INFO = clBlue;          // 信息、计算结果
  COLOR_TARGET = clPurple;      // 目标相关信息
```

#### 消息限制
```pascal
const
  MAX_STATUS_MESSAGES = 100;    // 最大状态消息数量
```

---

### 使用最佳实践

#### 1. 目录大小计算
```pascal
// 推荐：先检查根目录
if IsRootOrUserRootDirectory(DirPath) then
begin
  // 给出警告
  AddColoredStatusMessage('警告：此目录文件数量巨大', clRed);
end;

// 然后执行计算
DirSize := CalculateDirectorySize(DirPath);
```

#### 2. 可行性分析
```pascal
// 推荐：先分析可行性，再决定是否计算大小
Result := AnalyzeDirectoryFeasibility(DirPath);
if Result.SymlinkFeasibility = sfCanLink then
begin
  // 安全的目录，可以计算大小
  DirSize := CalculateDirectorySize(DirPath);
end;
```

#### 3. 状态消息显示
```pascal
// 推荐：使用彩色消息增强用户体验
AddColoredStatusMessage('开始分析...', clBlue);
// 执行操作
AddColoredStatusMessage('✅ 分析完成', clGreen);
```

#### 4. 异常处理
```pascal
try
  Result := AnalyzeDirectoryFeasibility(DirPath);
except
  on E: Exception do
  begin
    AddColoredStatusMessage('❌ 分析失败: ' + E.Message, clRed);
    // 设置安全的默认值
    Result.SymlinkFeasibility := sfCannotMove;
  end;
end;
```

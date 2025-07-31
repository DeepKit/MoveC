unit uStyles;

interface

uses
  Winapi.Windows, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons;

type
  // 现代化主题颜色
  TModernColors = record
    // 主色调
    Background: TColor;        // 背景色
    Surface: TColor;           // 表面色
    Primary: TColor;           // 主色
    Secondary: TColor;         // 次色
    Accent: TColor;            // 强调色
    
    // 文字颜色
    TextPrimary: TColor;       // 主要文字
    TextSecondary: TColor;     // 次要文字
    TextDisabled: TColor;      // 禁用文字
    
    // 状态颜色
    Success: TColor;           // 成功
    Warning: TColor;           // 警告
    Error: TColor;             // 错误
    Info: TColor;              // 信息
    
    // 符号链接状态颜色
    SymlinkValid: TColor;      // 有效符号链接
    SymlinkInvalid: TColor;    // 无效符号链接
    SymlinkBroken: TColor;     // 损坏符号链接
    
    // 操作状态颜色
    Processing: TColor;        // 处理中
    Completed: TColor;         // 已完成
    Paused: TColor;           // 已暂停
    Cancelled: TColor;        // 已取消
  end;

  // 现代化样式管理器
  TModernStyleManager = class
  private
    FLightTheme: TModernColors;
    FDarkTheme: TModernColors;
    FCurrentTheme: TModernColors;
    FIsDarkMode: Boolean;
  public
    constructor Create;
    
    // 主题管理
    procedure ApplyLightTheme;
    procedure ApplyDarkTheme;
    procedure ToggleTheme;
    
    // 控件样式应用
    procedure StyleForm(AForm: TForm);
    procedure StylePanel(APanel: TPanel);
    procedure StyleButton(AButton: TButton);
    procedure StyleEdit(AEdit: TEdit);
    procedure StyleListView(AListView: TListView);
    procedure StyleTreeView(ATreeView: TTreeView);
    procedure StyleProgressBar(AProgressBar: TProgressBar);
    procedure StyleRichEdit(ARichEdit: TRichEdit);
    procedure StyleStatusBar(AStatusBar: TStatusBar);
    
    // 颜色获取
    function GetStatusColor(const AStatus: string): TColor;
    function GetSeverityColor(const ASeverity: string): TColor;
    
    // 属性
    property CurrentTheme: TModernColors read FCurrentTheme;
    property IsDarkMode: Boolean read FIsDarkMode;
  end;

var
  StyleManager: TModernStyleManager;

implementation

constructor TModernStyleManager.Create;
begin
  inherited Create;
  
  // 浅色主题配置
  FLightTheme.Background := $F0F0F0;      // 浅灰背景
  FLightTheme.Surface := $FFFFFF;         // 白色表面
  FLightTheme.Primary := $D47800;         // 微软蓝
  FLightTheme.Secondary := $8B5CF6;       // 紫色
  FLightTheme.Accent := $FF6B35;          // 橙色强调
  
  FLightTheme.TextPrimary := $333333;     // 深灰文字
  FLightTheme.TextSecondary := $666666;   // 中灰文字
  FLightTheme.TextDisabled := $CCCCCC;    // 浅灰文字
  
  FLightTheme.Success := $10C710;         // 绿色
  FLightTheme.Warning := $008CFF;         // 橙色
  FLightTheme.Error := $3834D1;           // 红色
  FLightTheme.Info := $D47800;            // 蓝色
  
  FLightTheme.SymlinkValid := $D47800;    // 蓝色
  FLightTheme.SymlinkInvalid := $008CFF;  // 橙色
  FLightTheme.SymlinkBroken := $3834D1;   // 红色
  
  FLightTheme.Processing := $8B5CF6;      // 紫色
  FLightTheme.Completed := $10C710;       // 绿色
  FLightTheme.Paused := $008CFF;          // 橙色
  FLightTheme.Cancelled := $666666;       // 灰色
  
  // 深色主题配置
  FDarkTheme.Background := $2D2D30;       // 深灰背景
  FDarkTheme.Surface := $3E3E42;          // 深灰表面
  FDarkTheme.Primary := $0078D4;          // 亮蓝色
  FDarkTheme.Secondary := $9A4DFF;        // 亮紫色
  FDarkTheme.Accent := $FF7B54;           // 亮橙色
  
  FDarkTheme.TextPrimary := $FFFFFF;      // 白色文字
  FDarkTheme.TextSecondary := $CCCCCC;    // 浅灰文字
  FDarkTheme.TextDisabled := $666666;     // 深灰文字
  
  FDarkTheme.Success := $4CAF50;          // 亮绿色
  FDarkTheme.Warning := $FF9800;          // 亮橙色
  FDarkTheme.Error := $F44336;            // 亮红色
  FDarkTheme.Info := $2196F3;             // 亮蓝色
  
  FDarkTheme.SymlinkValid := $2196F3;     // 亮蓝色
  FDarkTheme.SymlinkInvalid := $FF9800;   // 亮橙色
  FDarkTheme.SymlinkBroken := $F44336;    // 亮红色
  
  FDarkTheme.Processing := $9A4DFF;       // 亮紫色
  FDarkTheme.Completed := $4CAF50;        // 亮绿色
  FDarkTheme.Paused := $FF9800;           // 亮橙色
  FDarkTheme.Cancelled := $999999;        // 亮灰色
  
  // 默认使用浅色主题
  ApplyLightTheme;
end;

procedure TModernStyleManager.ApplyLightTheme;
begin
  FCurrentTheme := FLightTheme;
  FIsDarkMode := False;
end;

procedure TModernStyleManager.ApplyDarkTheme;
begin
  FCurrentTheme := FDarkTheme;
  FIsDarkMode := True;
end;

procedure TModernStyleManager.ToggleTheme;
begin
  if FIsDarkMode then
    ApplyLightTheme
  else
    ApplyDarkTheme;
end;

procedure TModernStyleManager.StyleForm(AForm: TForm);
begin
  AForm.Color := FCurrentTheme.Background;
  AForm.Font.Name := 'Microsoft YaHei UI';
  AForm.Font.Size := 10;
  AForm.Font.Color := FCurrentTheme.TextPrimary;
end;

procedure TModernStyleManager.StylePanel(APanel: TPanel);
begin
  APanel.Color := FCurrentTheme.Surface;
  APanel.Font.Color := FCurrentTheme.TextPrimary;
  APanel.BevelOuter := bvNone;
  APanel.BorderStyle := bsNone;
end;

procedure TModernStyleManager.StyleButton(AButton: TButton);
begin
  AButton.Font.Name := 'Microsoft YaHei UI';
  AButton.Font.Size := 9;
  AButton.Font.Style := [];
  AButton.Font.Color := clWhite;
  // 注意：在实际应用中，可能需要使用第三方控件或自绘来实现现代化按钮样式
end;

procedure TModernStyleManager.StyleEdit(AEdit: TEdit);
begin
  AEdit.Font.Name := 'Microsoft YaHei UI';
  AEdit.Font.Size := 9;
  AEdit.Font.Color := FCurrentTheme.TextPrimary;
  AEdit.Color := FCurrentTheme.Surface;
  AEdit.BorderStyle := bsSingle;
end;

procedure TModernStyleManager.StyleListView(AListView: TListView);
begin
  AListView.Font.Name := 'Microsoft YaHei UI';
  AListView.Font.Size := 9;
  AListView.Font.Color := FCurrentTheme.TextPrimary;
  AListView.Color := FCurrentTheme.Surface;
  AListView.BorderStyle := bsNone;
end;

procedure TModernStyleManager.StyleTreeView(ATreeView: TTreeView);
begin
  ATreeView.Font.Name := 'Microsoft YaHei UI';
  ATreeView.Font.Size := 9;
  ATreeView.Font.Color := FCurrentTheme.TextPrimary;
  ATreeView.Color := FCurrentTheme.Surface;
  ATreeView.BorderStyle := bsNone;
end;

procedure TModernStyleManager.StyleProgressBar(AProgressBar: TProgressBar);
begin
  // 进度条样式（可能需要自绘或第三方控件）
  AProgressBar.Smooth := True;
end;

procedure TModernStyleManager.StyleRichEdit(ARichEdit: TRichEdit);
begin
  ARichEdit.Font.Name := 'Consolas';
  ARichEdit.Font.Size := 9;
  ARichEdit.Color := FCurrentTheme.Surface;
  ARichEdit.BorderStyle := bsNone;
  ARichEdit.ScrollBars := ssVertical;
end;

procedure TModernStyleManager.StyleStatusBar(AStatusBar: TStatusBar);
begin
  AStatusBar.Font.Name := 'Microsoft YaHei UI';
  AStatusBar.Font.Size := 8;
  AStatusBar.Font.Color := FCurrentTheme.TextSecondary;
  AStatusBar.Color := FCurrentTheme.Background;
end;

function TModernStyleManager.GetStatusColor(const AStatus: string): TColor;
begin
  if AStatus = 'Success' then
    Result := FCurrentTheme.Success
  else if AStatus = 'Warning' then
    Result := FCurrentTheme.Warning
  else if AStatus = 'Error' then
    Result := FCurrentTheme.Error
  else if AStatus = 'Info' then
    Result := FCurrentTheme.Info
  else if AStatus = 'Processing' then
    Result := FCurrentTheme.Processing
  else if AStatus = 'Completed' then
    Result := FCurrentTheme.Completed
  else if AStatus = 'SymlinkValid' then
    Result := FCurrentTheme.SymlinkValid
  else if AStatus = 'SymlinkInvalid' then
    Result := FCurrentTheme.SymlinkInvalid
  else if AStatus = 'SymlinkBroken' then
    Result := FCurrentTheme.SymlinkBroken
  else
    Result := FCurrentTheme.TextPrimary;
end;

function TModernStyleManager.GetSeverityColor(const ASeverity: string): TColor;
begin
  if ASeverity = 'Critical' then
    Result := FCurrentTheme.Error
  else if ASeverity = 'High' then
    Result := FCurrentTheme.Warning
  else if ASeverity = 'Medium' then
    Result := FCurrentTheme.Info
  else if ASeverity = 'Low' then
    Result := FCurrentTheme.Success
  else
    Result := FCurrentTheme.TextSecondary;
end;

initialization
  StyleManager := TModernStyleManager.Create;

finalization
  StyleManager.Free;

end.

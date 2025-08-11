unit uSplash;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls;

type
  TfrmSplash = class(TForm)
    pnlMain: TPanel;
    lblTitle: TLabel;
    lblVersion: TLabel;
    lblStatus: TLabel;
    ProgressBar: TProgressBar;
    lblCopyright: TLabel;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FProgress: Integer;
    FSteps: TArray<string>;
    FCurrentStep: Integer;
    procedure UpdateProgress;
    procedure SetModernStyle;
  public
    procedure ShowProgress(const AMessage: string; APercent: Integer);
  end;

var
  frmSplash: TfrmSplash;

implementation

{$R *.dfm}

procedure TfrmSplash.FormCreate(Sender: TObject);
begin
  // 设置现代化样式
  SetModernStyle;
  
  // 初始化进度步骤
  SetLength(FSteps, 8);
  FSteps[0] := '正在初始化系统组件...';
  FSteps[1] := '正在加载符号链接缓存...';
  FSteps[2] := '正在初始化状态管理器...';
  FSteps[3] := '正在启动智能建议引擎...';
  FSteps[4] := '正在初始化依赖关系分析...';
  FSteps[5] := '正在加载配置模板...';
  FSteps[6] := '正在启动审计系统...';
  FSteps[7] := '正在应用现代化界面...';
  
  FProgress := 0;
  FCurrentStep := 0;
  
  // 设置窗体属性
  BorderStyle := bsNone;
  Position := poScreenCenter;
  FormStyle := fsStayOnTop;
  
  // 启动定时器
  Timer1.Interval := 300;
  Timer1.Enabled := True;
end;

procedure TfrmSplash.FormShow(Sender: TObject);
begin
  // 窗体显示时开始动画
  UpdateProgress;
end;

procedure TfrmSplash.SetModernStyle;
begin
  // 设置现代化颜色方案
  Color := $F0F0F0;  // 浅灰背景
  
  // 主面板样式
  pnlMain.Color := $FFFFFF;  // 白色表面
  pnlMain.BevelOuter := bvNone;
  pnlMain.BorderStyle := bsSingle;
  pnlMain.BorderWidth := 1;
  
  // 标题样式
  lblTitle.Font.Name := 'Microsoft YaHei UI';
  lblTitle.Font.Size := 18;
  lblTitle.Font.Style := [fsBold];
  lblTitle.Font.Color := $333333;
  lblTitle.Caption := 'C盘瘦身工具 v3.0 Enterprise';

  // 版本标签样式
  lblVersion.Font.Name := 'Microsoft YaHei UI';
  lblVersion.Font.Size := 10;
  lblVersion.Font.Color := $666666;
  lblVersion.Caption := '企业版 - 专业级磁盘空间管理解决方案';
  
  // 状态标签样式
  lblStatus.Font.Name := 'Microsoft YaHei UI';
  lblStatus.Font.Size := 9;
  lblStatus.Font.Color := $0078D4;  // 微软蓝
  lblStatus.Caption := '正在启动...';

  // 版权标签样式
  lblCopyright.Font.Name := 'Microsoft YaHei UI';
  lblCopyright.Font.Size := 8;
  lblCopyright.Font.Color := $999999;
  lblCopyright.Caption := '© 2025 C盘瘦身工具. 保留所有权利.';
  
  // 进度条样式
  ProgressBar.Style := pbstNormal;
  ProgressBar.Smooth := True;
  ProgressBar.Min := 0;
  ProgressBar.Max := 100;
  ProgressBar.Position := 0;
end;

procedure TfrmSplash.Timer1Timer(Sender: TObject);
begin
  UpdateProgress;
end;

procedure TfrmSplash.UpdateProgress;
begin
  Inc(FProgress, 12);
  
  if FProgress > 100 then
    FProgress := 100;
  
  ProgressBar.Position := FProgress;
  
  // 更新状态文本
  if FCurrentStep < Length(FSteps) then
  begin
    lblStatus.Caption := FSteps[FCurrentStep];
    Inc(FCurrentStep);
  end;
  
  // 完成后关闭
  if FProgress >= 100 then
  begin
    Timer1.Enabled := False;
    Sleep(500);  // 稍微停留一下
    ModalResult := mrOK;
  end;
end;

procedure TfrmSplash.ShowProgress(const AMessage: string; APercent: Integer);
begin
  lblStatus.Caption := AMessage;
  ProgressBar.Position := APercent;
  Application.ProcessMessages;
end;

end.

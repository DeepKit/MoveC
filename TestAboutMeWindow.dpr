program TestAboutMeWindow;

uses
  Vcl.Forms,
  System.SysUtils,
  Vcl.Controls,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  FrameAboutMe in 'FrameAboutMe.pas' {FrameAboutMe: TFrame},
  ControllerIntf,
  MultiLanguageDatabaseManager,
  MultiLanguageConstants,
  DataTypes;

{$R *.res}

type
  // 简单的控制器实现（用于测试）
  TTestController = class(TInterfacedObject, IControllerMain)
  public
    // IControllerMain 接口实现
    function GetCurrentLanguage: TLanguageCode;
    procedure SetCurrentLanguage(const ALanguage: TLanguageCode);
    function GetLocalizedString(const AKey: string): string;
    procedure LogMessage(const AMessage: string);
    procedure ShowMessage(const AMessage: string);
    function GetDatabasePath: string;
  end;

  // 测试窗口
  TTestForm = class(TForm)
  private
    FAboutMeFrame: TFrameAboutMe;
    FController: IControllerMain;
    FStatusLabel: TLabel;
    
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure UpdateStatus(const AMessage: string);
  end;

var
  TestForm: TTestForm;

// TTestController 实现

function TTestController.GetCurrentLanguage: TLanguageCode;
begin
  Result := lcChineseSimplified;
end;

procedure TTestController.SetCurrentLanguage(const ALanguage: TLanguageCode);
begin
  // 测试实现，不做实际操作
end;

function TTestController.GetLocalizedString(const AKey: string): string;
begin
  // 简单的本地化实现
  if AKey = 'wechat_tip' then
    Result := '微信收款码'
  else if AKey = 'alipay_tip' then
    Result := '支付宝收款码'
  else if AKey = 'btc_tip' then
    Result := 'BTC打赏地址'
  else if AKey = 'usdt_tip' then
    Result := 'USDT打赏地址'
  else if AKey = 'aboutme_tip' then
    Result := '关于开发者'
  else
    Result := AKey;
end;

procedure TTestController.LogMessage(const AMessage: string);
begin
  if Assigned(TestForm) then
    TestForm.UpdateStatus(AMessage);
  OutputDebugString(PChar(AMessage));
end;

procedure TTestController.ShowMessage(const AMessage: string);
begin
  Vcl.Dialogs.ShowMessage(AMessage);
end;

function TTestController.GetDatabasePath: string;
begin
  Result := '';
end;

// TTestForm 实现

constructor TTestForm.Create(AOwner: TComponent);
begin
  inherited;
  
  // 设置窗口属性
  Caption := 'AboutMe Window Test - 图像显示测试';
  Width := 700;
  Height := 350;
  Position := poScreenCenter;
  
  // 创建状态标签
  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := Self;
  FStatusLabel.Left := 10;
  FStatusLabel.Top := Height - 50;
  FStatusLabel.Width := Width - 20;
  FStatusLabel.Height := 30;
  FStatusLabel.Caption := '正在初始化...';
  FStatusLabel.Font.Color := clBlue;
  FStatusLabel.Anchors := [akLeft, akRight, akBottom];
  
  // 创建控制器
  FController := TTestController.Create;
  
  // 创建AboutMe框架
  try
    UpdateStatus('正在创建AboutMe框架...');
    FAboutMeFrame := TFrameAboutMe.Create(Self, FController);
    FAboutMeFrame.Parent := Self;
    FAboutMeFrame.Align := alClient;
    FAboutMeFrame.Anchors := [akLeft, akTop, akRight, akBottom];
    
    UpdateStatus('AboutMe框架创建成功！检查各个tab的图像显示...');
    
  except
    on E: Exception do
    begin
      UpdateStatus('错误: ' + E.Message);
      raise;
    end;
  end;
end;

destructor TTestForm.Destroy;
begin
  if Assigned(FAboutMeFrame) then
    FAboutMeFrame.Free;
  inherited;
end;

procedure TTestForm.UpdateStatus(const AMessage: string);
begin
  if Assigned(FStatusLabel) then
  begin
    FStatusLabel.Caption := AMessage;
    FStatusLabel.Update;
  end;
end;

procedure ShowInstructions;
begin
  Vcl.Dialogs.ShowMessage(
    'AboutMe窗口图像显示测试' + #13#10 +
    '========================' + #13#10 +
    '' + #13#10 +
    '请检查以下内容：' + #13#10 +
    '' + #13#10 +
    '1. 微信打赏 tab - 应显示微信收款二维码' + #13#10 +
    '2. 支付宝打赏 tab - 应显示支付宝收款二维码' + #13#10 +
    '3. BTC打赏 tab - 应显示比特币地址二维码' + #13#10 +
    '4. USDT打赏 tab - 应显示USDT地址二维码' + #13#10 +
    '5. 关于我 tab - 应显示开发者个人照片' + #13#10 +
    '' + #13#10 +
    '所有图像都是从加密数据库中安全加载的。' + #13#10 +
    '如果某个图像没有显示，请检查底部的状态信息。'
  );
end;

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  
  try
    // 显示使用说明
    ShowInstructions;
    
    // 创建并显示测试窗口
    TestForm := TTestForm.Create(nil);
    try
      Application.Run;
    finally
      TestForm.Free;
    end;
    
  except
    on E: Exception do
    begin
      Vcl.Dialogs.ShowMessage('程序启动失败: ' + E.Message);
    end;
  end;
end.

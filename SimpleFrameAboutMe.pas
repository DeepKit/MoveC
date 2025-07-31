unit SimpleFrameAboutMe;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, System.Hash, Vcl.Clipbrd, BasicProtection;

type
  // 打赏地址类型
  TDonationAddressType = (datWechat, datAlipay, datBTC, datUSDT);

  // 打赏地址信息
  TDonationAddressInfo = record
    AddressType: TDonationAddressType;
    Address: string;
    Description: string;
    IsValid: Boolean;
  end;

  TFrameAboutMe = class(TFrame)
    pcAboutMe: TPageControl;
    tsWechat: TTabSheet;
    tsAlipay: TTabSheet;
    tsBTC: TTabSheet;
    tsUSDT: TTabSheet;
    tsAboutMe: TTabSheet;
    
    // 微信页面
    lblWechatTip: TLabel;
    lblWechatAddress: TLabel;
    
    // 支付宝页面
    lblAlipayTip: TLabel;
    lblAlipayAddress: TLabel;
    
    // BTC页面
    lblBTCTip: TLabel;
    lblBTCAddress: TLabel;
    btnCopyBTC: TButton;
    
    // USDT页面
    lblUSDTTip: TLabel;
    lblUSDTAddress: TLabel;
    btnCopyUSDT: TButton;
    
    // 关于我页面
    lblAboutMeTip: TLabel;
    lblMachineCode: TLabel;
    lblMachineCodeValue: TLabel;
    
    procedure btnCopyBTCClick(Sender: TObject);
    procedure btnCopyUSDTClick(Sender: TObject);
    procedure lblMachineCodeValueClick(Sender: TObject);
    
  private
    FDonationAddresses: array[TDonationAddressType] of TDonationAddressInfo;
    
    // 硬编码备用地址（安全防线）
    const
      BACKUP_BTC_ADDRESS = 'bc1qze0ggsrdtjqwjpjfufydsuyjxc08tgcq5xkct3';
      BACKUP_USDT_ADDRESS = 'TH1NazpoEpUqcEotGzLPHs13SbLDJKKCys';
      BACKUP_WECHAT_DESC = '微信收款码';
      BACKUP_ALIPAY_DESC = '支付宝收款码';
    
    procedure InitializeDonationAddresses;
    procedure LoadDonationAddressFromConfig(AddressType: TDonationAddressType);
    procedure UpdateDonationPageUI(AddressType: TDonationAddressType);
    procedure CopyAddressToClipboard(const Address: string; const AddressName: string);
    function GenerateMachineCode: string;
    function GetHardwareInfo: string;
    procedure UpdateMachineCodeDisplay;
    procedure LogMessage(const Msg: string);
    
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    // 公共接口
    procedure LoadAllDonationAddresses;
    procedure RotateToNextPage;
    function GetCurrentPageIndex: Integer;
    procedure SetActivePage(PageIndex: Integer);
  end;

implementation

{$R *.dfm}

constructor TFrameAboutMe.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  
  // 初始化打赏地址
  InitializeDonationAddresses;
  
  // 加载所有打赏地址
  LoadAllDonationAddresses;
  
  // 更新机器码显示
  UpdateMachineCodeDisplay;
  
  LogMessage('SimpleFrameAboutMe: 初始化完成');
end;

destructor TFrameAboutMe.Destroy;
begin
  inherited;
end;

// 初始化打赏地址数组
procedure TFrameAboutMe.InitializeDonationAddresses;
begin
  // 微信
  FDonationAddresses[datWechat].AddressType := datWechat;
  FDonationAddresses[datWechat].Address := '';
  FDonationAddresses[datWechat].Description := BACKUP_WECHAT_DESC;
  FDonationAddresses[datWechat].IsValid := False;
  
  // 支付宝
  FDonationAddresses[datAlipay].AddressType := datAlipay;
  FDonationAddresses[datAlipay].Address := '';
  FDonationAddresses[datAlipay].Description := BACKUP_ALIPAY_DESC;
  FDonationAddresses[datAlipay].IsValid := False;
  
  // BTC
  FDonationAddresses[datBTC].AddressType := datBTC;
  FDonationAddresses[datBTC].Address := BACKUP_BTC_ADDRESS;
  FDonationAddresses[datBTC].Description := 'BTC收款地址';
  FDonationAddresses[datBTC].IsValid := True;
  
  // USDT
  FDonationAddresses[datUSDT].AddressType := datUSDT;
  FDonationAddresses[datUSDT].Address := BACKUP_USDT_ADDRESS;
  FDonationAddresses[datUSDT].Description := 'USDT收款地址';
  FDonationAddresses[datUSDT].IsValid := True;
end;

// 从配置加载打赏地址
procedure TFrameAboutMe.LoadDonationAddressFromConfig(AddressType: TDonationAddressType);
var
  ConfigFile: string;
  ConfigData: TStringList;
  I: Integer;
  Line, Key, Value: string;
  AddressKey: string;
begin
  try
    ConfigFile := ChangeFileExt(Application.ExeName, '.donation');
    
    if not FileExists(ConfigFile) then
      Exit;
    
    // 确定配置键名
    case AddressType of
      datWechat: AddressKey := 'WECHAT_DESC';
      datAlipay: AddressKey := 'ALIPAY_DESC';
      datBTC: AddressKey := 'BTC';
      datUSDT: AddressKey := 'USDT';
    end;
    
    ConfigData := TStringList.Create;
    try
      ConfigData.LoadFromFile(ConfigFile);
      
      for I := 0 to ConfigData.Count - 1 do
      begin
        Line := ConfigData[I];
        if Line.Contains('=') then
        begin
          Key := Copy(Line, 1, Pos('=', Line) - 1);
          Value := Copy(Line, Pos('=', Line) + 1, MaxInt);
          
          if SameText(Key, AddressKey) then
          begin
            if (AddressType = datBTC) or (AddressType = datUSDT) then
            begin
              // 解密地址
              try
                FDonationAddresses[AddressType].Address := TBasicProtection.DecryptSensitiveData(Value);
                FDonationAddresses[AddressType].IsValid := True;
              except
                // 解密失败，使用备用地址
                LogMessage('解密' + AddressKey + '失败，使用备用地址');
              end;
            end
            else
            begin
              FDonationAddresses[AddressType].Description := Value;
              FDonationAddresses[AddressType].IsValid := True;
            end;
            Break;
          end;
        end;
      end;
      
    finally
      ConfigData.Free;
    end;
    
  except
    on E: Exception do
      LogMessage('加载' + AddressKey + '配置失败: ' + E.Message);
  end;
end;

// 加载所有打赏地址
procedure TFrameAboutMe.LoadAllDonationAddresses;
var
  AddressType: TDonationAddressType;
begin
  for AddressType := Low(TDonationAddressType) to High(TDonationAddressType) do
  begin
    LoadDonationAddressFromConfig(AddressType);
    UpdateDonationPageUI(AddressType);
  end;
end;

// 更新打赏页面UI
procedure TFrameAboutMe.UpdateDonationPageUI(AddressType: TDonationAddressType);
var
  AddressInfo: TDonationAddressInfo;
begin
  AddressInfo := FDonationAddresses[AddressType];

  case AddressType of
    datWechat:
    begin
      if Assigned(lblWechatTip) then
        lblWechatTip.Caption := AddressInfo.Description;
      if Assigned(lblWechatAddress) then
        lblWechatAddress.Caption := '请扫描二维码';
    end;
    datAlipay:
    begin
      if Assigned(lblAlipayTip) then
        lblAlipayTip.Caption := AddressInfo.Description;
      if Assigned(lblAlipayAddress) then
        lblAlipayAddress.Caption := '请扫描二维码';
    end;
    datBTC:
    begin
      if Assigned(lblBTCTip) then
        lblBTCTip.Caption := AddressInfo.Description;
      if Assigned(lblBTCAddress) then
        lblBTCAddress.Caption := AddressInfo.Address;
    end;
    datUSDT:
    begin
      if Assigned(lblUSDTTip) then
        lblUSDTTip.Caption := AddressInfo.Description;
      if Assigned(lblUSDTAddress) then
        lblUSDTAddress.Caption := AddressInfo.Address;
    end;
  end;
end;

// 复制BTC地址
procedure TFrameAboutMe.btnCopyBTCClick(Sender: TObject);
begin
  CopyAddressToClipboard(FDonationAddresses[datBTC].Address, 'BTC地址');
end;

// 复制USDT地址
procedure TFrameAboutMe.btnCopyUSDTClick(Sender: TObject);
begin
  CopyAddressToClipboard(FDonationAddresses[datUSDT].Address, 'USDT地址');
end;

// 复制地址到剪贴板
procedure TFrameAboutMe.CopyAddressToClipboard(const Address: string; const AddressName: string);
begin
  try
    Clipboard.AsText := Address;
    ShowMessage(AddressName + ' 已复制到剪贴板');
    LogMessage('复制' + AddressName + ': ' + Address);
  except
    on E: Exception do
    begin
      ShowMessage('复制失败: ' + E.Message);
      LogMessage('复制' + AddressName + '失败: ' + E.Message);
    end;
  end;
end;

// 生成机器码
function TFrameAboutMe.GenerateMachineCode: string;
var
  HardwareInfo: string;
  HashValue: string;
begin
  try
    // 获取硬件信息
    HardwareInfo := GetHardwareInfo;
    
    // 使用SHA256生成哈希
    HashValue := THashSHA2.GetHashString(HardwareInfo, SHA256);
    
    // 取前16位作为机器码，并格式化为易读格式
    Result := Copy(HashValue, 1, 16).ToUpper;
    
    // 格式化为 XXXX-XXXX-XXXX-XXXX 格式
    if Length(Result) >= 16 then
    begin
      Result := Copy(Result, 1, 4) + '-' +
                Copy(Result, 5, 4) + '-' +
                Copy(Result, 9, 4) + '-' +
                Copy(Result, 13, 4);
    end;
    
    LogMessage('机器码生成成功: ' + Result);
  except
    on E: Exception do
    begin
      LogMessage('机器码生成失败: ' + E.Message);
      Result := 'ERROR-GENE-RATE-CODE';
    end;
  end;
end;

// 获取硬件信息
function TFrameAboutMe.GetHardwareInfo: string;
begin
  Result := GetEnvironmentVariable('COMPUTERNAME') + '|' +
            GetEnvironmentVariable('USERNAME') + '|' +
            IntToStr(GetTickCount);
end;

// 更新机器码显示
procedure TFrameAboutMe.UpdateMachineCodeDisplay;
var
  MachineCode: string;
begin
  try
    MachineCode := GenerateMachineCode;
    
    if Assigned(lblMachineCode) then
      lblMachineCode.Caption := '机器码:';
      
    if Assigned(lblMachineCodeValue) then
    begin
      lblMachineCodeValue.Caption := MachineCode;
      lblMachineCodeValue.Cursor := crHandPoint;
      lblMachineCodeValue.Font.Color := clBlue;
      lblMachineCodeValue.Font.Style := [fsUnderline];
    end;
    
  except
    on E: Exception do
      LogMessage('更新机器码显示失败: ' + E.Message);
  end;
end;

// 机器码点击事件
procedure TFrameAboutMe.lblMachineCodeValueClick(Sender: TObject);
begin
  CopyAddressToClipboard(lblMachineCodeValue.Caption, '机器码');
end;

// 切换到下一页
procedure TFrameAboutMe.RotateToNextPage;
var
  NextIndex: Integer;
begin
  if Assigned(pcAboutMe) then
  begin
    NextIndex := (pcAboutMe.ActivePageIndex + 1) mod pcAboutMe.PageCount;
    pcAboutMe.ActivePageIndex := NextIndex;
    LogMessage(Format('切换到页面 %d', [NextIndex]));
  end;
end;

// 获取当前页面索引
function TFrameAboutMe.GetCurrentPageIndex: Integer;
begin
  if Assigned(pcAboutMe) then
    Result := pcAboutMe.ActivePageIndex
  else
    Result := -1;
end;

// 设置活动页面
procedure TFrameAboutMe.SetActivePage(PageIndex: Integer);
begin
  if Assigned(pcAboutMe) and (PageIndex >= 0) and (PageIndex < pcAboutMe.PageCount) then
  begin
    pcAboutMe.ActivePageIndex := PageIndex;
    LogMessage(Format('设置活动页面为 %d', [PageIndex]));
  end;
end;

// 日志记录
procedure TFrameAboutMe.LogMessage(const Msg: string);
begin
  OutputDebugString(PChar('SimpleFrameAboutMe: ' + Msg));
end;

end.

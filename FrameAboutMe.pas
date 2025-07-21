unit FrameAboutMe;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, System.Skia, Vcl.Skia, ControllerIntf, System.NetEncoding, System.Hash,
  DatabaseSecurity, uDM, Vcl.Clipbrd;

type
  // 打赏地址类型
  TDonationAddressType = (datWechat, datAlipay, datBTC, datUSDT);

  // 打赏地址信息
  TDonationAddressInfo = record
    AddressType: TDonationAddressType;
    Address: string;
    Description: string;
    QRCodeData: TBytes;
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
    imgWechat: TSkAnimatedImage;
    lblWechatTip: TLabel;
    lblWechatAddress: TLabel;
    
    // 支付宝页面
    imgAlipay: TSkAnimatedImage;
    lblAlipayTip: TLabel;
    lblAlipayAddress: TLabel;
    
    // BTC页面
    imgBTC: TSkAnimatedImage;
    lblBTCTip: TLabel;
    lblBTCAddress: TLabel;
    btnCopyBTC: TButton;
    
    // USDT页面
    imgUSDT: TSkAnimatedImage;
    lblUSDTTip: TLabel;
    lblUSDTAddress: TLabel;
    btnCopyUSDT: TButton;
    
    // 关于我页面
    imgAboutMe: TSkAnimatedImage;
    lblAboutMeTip: TLabel;
    lblMachineCode: TLabel;
    lblMachineCodeValue: TLabel;
    
    procedure btnCopyBTCClick(Sender: TObject);
    procedure btnCopyUSDTClick(Sender: TObject);
    procedure lblMachineCodeValueClick(Sender: TObject);

    // PageControl Tab高亮绘制事件
    procedure pcAboutMeDrawTab(Control: TCustomTabControl; TabIndex: Integer;
      const Rect: TRect; Active: Boolean);
    
  private
    FController: IControllerMain;
    FSecurityManager: TDatabaseSecurityManager;
    FDonationAddresses: array[TDonationAddressType] of TDonationAddressInfo;
    
    // 硬编码备用地址（安全防线）
    const
      BACKUP_BTC_ADDRESS = 'bc1qze0ggsrdtjqwjpjfufydsuyjxc08tgcq5xkct3';
      BACKUP_USDT_ADDRESS = 'TH1NazpoEpUqcEotGzLPHs13SbLDJKKCys';
      BACKUP_WECHAT_DESC = '微信收款码';
      BACKUP_ALIPAY_DESC = '支付宝收款码';
    
    // 内部方法
    procedure InitializeDonationAddresses;
    procedure InitializeDefaultAddresses;
    procedure LoadDonationAddressFromDB(AddressType: TDonationAddressType);
    procedure SaveDonationAddressToDB(const AddressInfo: TDonationAddressInfo);
    procedure ValidateDonationAddresses;
    procedure HandleAddressTampering(AddressType: TDonationAddressType);
    
    // 加密相关
    function GenerateEncryptionKey: string;
    function EncryptAddress(const Address: string): string;
    function DecryptAddress(const EncryptedAddress: string): string;
    function ValidateAddressIntegrity(const Address, Hash: string): Boolean;
    function GenerateAddressHash(const Address: string): string;
    
    // UI更新
    procedure UpdateDonationPageUI(AddressType: TDonationAddressType);
    procedure DisplayQRCode(const Data: string; TargetImage: TSkAnimatedImage);
    procedure CopyAddressToClipboard(const Address: string; const AddressName: string);

    // 图片加载
    procedure LoadImageFromDB(const ImageKey: string; TargetImage: TSkAnimatedImage);
    procedure LoadAllImages;

    // 机器码生成
    function GenerateMachineCode: string;
    function GetHardwareInfo: string;
    procedure UpdateMachineCodeDisplay;
    
    // 日志记录
    procedure LogMessage(const Msg: string);
    
  public
    constructor Create(AOwner: TComponent; AController: IControllerMain); reintroduce;
    destructor Destroy; override;
    
    // 公共接口
    procedure LoadAllDonationAddresses;
    procedure RotateToNextPage;
    function GetCurrentPageIndex: Integer;
    procedure SetActivePage(PageIndex: Integer);
    
    // 属性
    property Controller: IControllerMain read FController;
  end;

implementation

uses
  System.IOUtils;

{$R *.dfm}

constructor TFrameAboutMe.Create(AOwner: TComponent; AController: IControllerMain);
begin
  inherited Create(AOwner);
  FController := AController;

  // 初始化安全管理器
  FSecurityManager := TDatabaseSecurityManager.Create('TwoKeyRun.db', nil, nil);

  // 初始化打赏地址
  InitializeDonationAddresses;

  // 加载所有打赏地址
  LoadAllDonationAddresses;

  // 加载所有图片
  LoadAllImages;

  // 设置PageControl的OnDrawTab事件以实现tab高亮显示
  pcAboutMe.OwnerDraw := True;
  pcAboutMe.OnDrawTab := pcAboutMeDrawTab;

  // 更新机器码显示
  UpdateMachineCodeDisplay;

  LogMessage('FrameAboutMe: 初始化完成');
end;

destructor TFrameAboutMe.Destroy;
begin
  FSecurityManager.Free;
  inherited;
end;

procedure TFrameAboutMe.InitializeDonationAddresses;
var
  AddressType: TDonationAddressType;
begin
  // 初始化所有地址信息
  for AddressType := Low(TDonationAddressType) to High(TDonationAddressType) do
  begin
    FDonationAddresses[AddressType].AddressType := AddressType;
    FDonationAddresses[AddressType].IsValid := False;

    case AddressType of
      datWechat:
      begin
        FDonationAddresses[AddressType].Description := BACKUP_WECHAT_DESC;
      end;
      datAlipay:
      begin
        FDonationAddresses[AddressType].Description := BACKUP_ALIPAY_DESC;
      end;
      datBTC:
      begin
        FDonationAddresses[AddressType].Address := BACKUP_BTC_ADDRESS;
        FDonationAddresses[AddressType].Description := 'BTC打赏地址';
      end;
      datUSDT:
      begin
        FDonationAddresses[AddressType].Address := BACKUP_USDT_ADDRESS;
        FDonationAddresses[AddressType].Description := 'USDT打赏地址（波场链TRON）';
      end;
    end;
  end;
end;

procedure TFrameAboutMe.InitializeDefaultAddresses;
var
  AddressType: TDonationAddressType;
  AddressTypeStr: string;
begin
  // 检查数据库中是否已有地址，如果没有则初始化默认地址
  for AddressType := Low(TDonationAddressType) to High(TDonationAddressType) do
  begin
    case AddressType of
      datWechat: AddressTypeStr := 'WECHAT';
      datAlipay: AddressTypeStr := 'ALIPAY';
      datBTC: AddressTypeStr := 'BTC';
      datUSDT: AddressTypeStr := 'USDT';
    end;

    // 如果数据库中不存在该地址类型，则保存默认地址
    if Assigned(DM) and not DM.DonationAddressExists(AddressTypeStr) then
    begin
      SaveDonationAddressToDB(FDonationAddresses[AddressType]);
      LogMessage(Format('FrameAboutMe: 初始化默认%s地址', [AddressTypeStr]));
    end;
  end;
end;

procedure TFrameAboutMe.LoadAllDonationAddresses;
var
  AddressType: TDonationAddressType;
begin
  try
    // 首次运行时初始化默认地址
    InitializeDefaultAddresses;

    // 验证数据完整性
    ValidateDonationAddresses;

    // 加载所有地址
    for AddressType := Low(TDonationAddressType) to High(TDonationAddressType) do
    begin
      LoadDonationAddressFromDB(AddressType);
      UpdateDonationPageUI(AddressType);
    end;

    LogMessage('FrameAboutMe: 所有打赏地址加载完成');
  except
    on E: Exception do
    begin
      LogMessage('FrameAboutMe: 加载打赏地址失败: ' + E.Message);
    end;
  end;
end;

procedure TFrameAboutMe.LoadDonationAddressFromDB(AddressType: TDonationAddressType);
var
  AddressTypeStr: string;
  EncryptedAddress, AddressHash, Description: string;
  QRCodeData: TBytes;
  DecryptedAddress: string;
begin
  // 转换枚举为字符串
  case AddressType of
    datWechat: AddressTypeStr := 'WECHAT';
    datAlipay: AddressTypeStr := 'ALIPAY';
    datBTC: AddressTypeStr := 'BTC';
    datUSDT: AddressTypeStr := 'USDT';
  end;

  try
    if Assigned(DM) and DM.LoadDonationAddress(AddressTypeStr, EncryptedAddress, AddressHash, Description, QRCodeData) then
    begin
      // 解密地址
      DecryptedAddress := DecryptAddress(EncryptedAddress);

      // 验证完整性
      if ValidateAddressIntegrity(DecryptedAddress, AddressHash) then
      begin
        FDonationAddresses[AddressType].Address := DecryptedAddress;
        FDonationAddresses[AddressType].Description := Description;
        FDonationAddresses[AddressType].QRCodeData := QRCodeData;
        FDonationAddresses[AddressType].IsValid := True;
        LogMessage(Format('FrameAboutMe: 从数据库加载%s地址成功', [AddressTypeStr]));
      end
      else
      begin
        // 完整性验证失败，使用备用地址
        HandleAddressTampering(AddressType);
      end;
    end
    else
    begin
      // 数据库中没有记录，使用备用地址并保存到数据库
      SaveDonationAddressToDB(FDonationAddresses[AddressType]);
      FDonationAddresses[AddressType].IsValid := True;
      LogMessage(Format('FrameAboutMe: 使用备用%s地址并保存到数据库', [AddressTypeStr]));
    end;
  except
    on E: Exception do
    begin
      LogMessage(Format('FrameAboutMe: 加载%s地址失败: %s，使用备用地址', [AddressTypeStr, E.Message]));
      FDonationAddresses[AddressType].IsValid := True;
    end;
  end;
end;

procedure TFrameAboutMe.UpdateDonationPageUI(AddressType: TDonationAddressType);
var
  AddressInfo: TDonationAddressInfo;
begin
  AddressInfo := FDonationAddresses[AddressType];

  case AddressType of
    datWechat:
    begin
      lblWechatTip.Caption := AddressInfo.Description;
      // 微信二维码已从数据库加载
    end;
    datAlipay:
    begin
      lblAlipayTip.Caption := AddressInfo.Description;
      // 支付宝二维码已从数据库加载
    end;
    datBTC:
    begin
      lblBTCTip.Caption := AddressInfo.Description;
      lblBTCAddress.Caption := AddressInfo.Address;
      // BTC二维码已从数据库加载
    end;
    datUSDT:
    begin
      lblUSDTTip.Caption := AddressInfo.Description;
      lblUSDTAddress.Caption := AddressInfo.Address;
      // USDT二维码已从数据库加载
    end;
  end;
end;

procedure TFrameAboutMe.btnCopyBTCClick(Sender: TObject);
begin
  CopyAddressToClipboard(FDonationAddresses[datBTC].Address, 'BTC地址');
end;

procedure TFrameAboutMe.btnCopyUSDTClick(Sender: TObject);
begin
  CopyAddressToClipboard(FDonationAddresses[datUSDT].Address, 'USDT地址');
end;

procedure TFrameAboutMe.CopyAddressToClipboard(const Address: string; const AddressName: string);
begin
  try
    Clipboard.AsText := Address;
    LogMessage(Format('FrameAboutMe: %s已复制到剪贴板', [AddressName]));
  except
    on E: Exception do
    begin
      LogMessage(Format('FrameAboutMe: 复制%s失败: %s', [AddressName, E.Message]));
    end;
  end;
end;

procedure TFrameAboutMe.RotateToNextPage;
var
  NextIndex: Integer;
begin
  NextIndex := (pcAboutMe.ActivePageIndex + 1) mod pcAboutMe.PageCount;
  pcAboutMe.ActivePageIndex := NextIndex;
  LogMessage(Format('FrameAboutMe: 切换到页面 %d', [NextIndex]));
end;

function TFrameAboutMe.GetCurrentPageIndex: Integer;
begin
  Result := pcAboutMe.ActivePageIndex;
end;

procedure TFrameAboutMe.SetActivePage(PageIndex: Integer);
begin
  if (PageIndex >= 0) and (PageIndex < pcAboutMe.PageCount) then
  begin
    pcAboutMe.ActivePageIndex := PageIndex;
    LogMessage(Format('FrameAboutMe: 设置活动页面为 %d', [PageIndex]));
  end;
end;

// 实现具体方法
procedure TFrameAboutMe.ValidateDonationAddresses;
var
  AddressType: TDonationAddressType;
begin
  for AddressType := Low(TDonationAddressType) to High(TDonationAddressType) do
  begin
    LoadDonationAddressFromDB(AddressType);
  end;
  LogMessage('FrameAboutMe: 地址完整性验证完成');
end;

procedure TFrameAboutMe.HandleAddressTampering(AddressType: TDonationAddressType);
var
  AddressTypeStr: string;
begin
  case AddressType of
    datWechat: AddressTypeStr := 'WECHAT';
    datAlipay: AddressTypeStr := 'ALIPAY';
    datBTC: AddressTypeStr := 'BTC';
    datUSDT: AddressTypeStr := 'USDT';
  end;

  LogMessage(Format('FrameAboutMe: 检测到%s地址被篡改，使用备用地址', [AddressTypeStr]));

  // 重置为备用地址
  case AddressType of
    datBTC: FDonationAddresses[AddressType].Address := BACKUP_BTC_ADDRESS;
    datUSDT: FDonationAddresses[AddressType].Address := BACKUP_USDT_ADDRESS;
  end;

  FDonationAddresses[AddressType].IsValid := True;

  // 重新保存到数据库
  SaveDonationAddressToDB(FDonationAddresses[AddressType]);
end;

function TFrameAboutMe.GenerateEncryptionKey: string;
var
  HardwareInfo: string;
begin
  // 使用硬件信息生成密钥
  HardwareInfo := GetEnvironmentVariable('COMPUTERNAME') + GetEnvironmentVariable('USERNAME');
  Result := THashSHA2.GetHashString(HardwareInfo + '@2241114'); // 结合数据库密码
end;

function TFrameAboutMe.EncryptAddress(const Address: string): string;
var
  Key: string;
begin
  if Address = '' then
  begin
    Result := '';
    Exit;
  end;

  try
    Key := GenerateEncryptionKey;
    if Assigned(FSecurityManager) and Assigned(FSecurityManager.DataEncryption) then
      Result := FSecurityManager.DataEncryption.EncryptData(Address)
    else
      Result := TNetEncoding.Base64.Encode(Address); // 简单编码作为备用
  except
    on E: Exception do
    begin
      LogMessage('FrameAboutMe: 地址加密失败: ' + E.Message);
      Result := TNetEncoding.Base64.Encode(Address);
    end;
  end;
end;

function TFrameAboutMe.DecryptAddress(const EncryptedAddress: string): string;
var
  Key: string;
begin
  if EncryptedAddress = '' then
  begin
    Result := '';
    Exit;
  end;

  try
    Key := GenerateEncryptionKey;
    if Assigned(FSecurityManager) and Assigned(FSecurityManager.DataEncryption) then
      Result := FSecurityManager.DataEncryption.DecryptData(EncryptedAddress)
    else
      Result := TNetEncoding.Base64.Decode(EncryptedAddress); // 简单解码作为备用
  except
    on E: Exception do
    begin
      LogMessage('FrameAboutMe: 地址解密失败: ' + E.Message);
      Result := TNetEncoding.Base64.Decode(EncryptedAddress);
    end;
  end;
end;

function TFrameAboutMe.ValidateAddressIntegrity(const Address, Hash: string): Boolean;
var
  CalculatedHash: string;
  SecurityValidation: Boolean;
begin
  try
    // 第一层验证：使用原有的哈希验证
    CalculatedHash := GenerateAddressHash(Address);
    Result := SameText(CalculatedHash, Hash);

    // 第二层验证：使用数据库安全管理器的验证（暂时禁用）
    SecurityValidation := True;
    // TODO: 集成数据库安全管理器验证
    // if Assigned(DM) and Assigned(DM.SecurityManager) and Assigned(DM.SecurityManager.IntegrityValidator) then
    // begin
    //   SecurityValidation := DM.SecurityManager.IntegrityValidator.VerifyDonationAddressIntegrity(AddressType, Address);
    // end;

    Result := Result and SecurityValidation;

    if not Result then
      LogMessage(Format('FrameAboutMe: 地址完整性验证失败，期望: %s，实际: %s', [Hash, CalculatedHash]));
  except
    on E: Exception do
    begin
      LogMessage('FrameAboutMe: 地址完整性验证异常: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TFrameAboutMe.GenerateAddressHash(const Address: string): string;
begin
  Result := THashSHA2.GetHashString(Address + GenerateEncryptionKey());
end;

procedure TFrameAboutMe.SaveDonationAddressToDB(const AddressInfo: TDonationAddressInfo);
var
  AddressTypeStr: string;
  EncryptedAddress, AddressHash: string;
begin
  case AddressInfo.AddressType of
    datWechat: AddressTypeStr := 'WECHAT';
    datAlipay: AddressTypeStr := 'ALIPAY';
    datBTC: AddressTypeStr := 'BTC';
    datUSDT: AddressTypeStr := 'USDT';
  end;

  try
    EncryptedAddress := EncryptAddress(AddressInfo.Address);
    AddressHash := GenerateAddressHash(AddressInfo.Address);

    if Assigned(DM) then
    begin
      DM.SaveDonationAddress(AddressTypeStr, EncryptedAddress, AddressHash, AddressInfo.QRCodeData, AddressInfo.Description);
      LogMessage(Format('FrameAboutMe: 保存%s地址到数据库成功', [AddressTypeStr]));
    end;
  except
    on E: Exception do
    begin
      LogMessage(Format('FrameAboutMe: 保存%s地址到数据库失败: %s', [AddressTypeStr, E.Message]));
    end;
  end;
end;

procedure TFrameAboutMe.DisplayQRCode(const Data: string; TargetImage: TSkAnimatedImage);
begin
  // 暂时显示文本，后续可以集成二维码生成库
  LogMessage(Format('FrameAboutMe: 显示二维码数据: %s', [Data]));
  // TODO: 集成二维码生成库，如DelphiZXingQRCode或在线API
end;

// 从数据库加载图片
procedure TFrameAboutMe.LoadImageFromDB(const ImageKey: string; TargetImage: TSkAnimatedImage);
var
  ImageStream: TMemoryStream;
begin
  LogMessage(Format('LoadImageFromDB: 开始加载图片 - %s', [ImageKey]));

  if not Assigned(TargetImage) then
  begin
    LogMessage(Format('LoadImageFromDB: 目标图片控件不可用 - %s', [ImageKey]));
    Exit;
  end;

  if not Assigned(DM) then
  begin
    LogMessage(Format('LoadImageFromDB: 数据库管理器不可用 - %s', [ImageKey]));
    Exit;
  end;

  ImageStream := TMemoryStream.Create;
  try
    LogMessage(Format('LoadImageFromDB: 尝试从数据库加载 - %s', [ImageKey]));
    if DM.LoadAppImage(ImageKey, ImageStream) then
    begin
      LogMessage(Format('LoadImageFromDB: 从数据库加载图像成功 - %s, 大小: %d 字节', [ImageKey, ImageStream.Size]));

      if ImageStream.Size > 0 then
      begin
        // 验证图片完整性（暂时禁用）
        // TODO: 集成数据库安全管理器验证
        // if Assigned(DM.SecurityManager) and Assigned(DM.SecurityManager.IntegrityValidator) then
        // begin
        //   if DM.SecurityManager.IntegrityValidator.VerifyImageIntegrity(ImageKey, ImageStream) then
        //   begin
        //     LogMessage(Format('LoadImageFromDB: 图像完整性验证通过 - %s', [ImageKey]));
        //   end
        //   else
        //   begin
        //     LogMessage(Format('LoadImageFromDB: 图像完整性验证失败 - %s', [ImageKey]));
        //     // 可以选择不显示被篡改的图片
        //     Exit;
        //   end;
        // end;

        try
          ImageStream.Position := 0;
          TargetImage.LoadFromStream(ImageStream);
          LogMessage(Format('LoadImageFromDB: 图像显示成功 - %s', [ImageKey]));
        except
          on E: Exception do
          begin
            LogMessage(Format('LoadImageFromDB: 图像显示失败 - %s: %s', [ImageKey, E.Message]));
          end;
        end;
      end
      else
      begin
        LogMessage(Format('LoadImageFromDB: 图像数据为空 - %s', [ImageKey]));
      end;
    end
    else
    begin
      LogMessage(Format('LoadImageFromDB: 从数据库加载图像失败 - %s', [ImageKey]));
    end;
  finally
    ImageStream.Free;
  end;
end;

// 加载所有图片
procedure TFrameAboutMe.LoadAllImages;
begin
  LogMessage('FrameAboutMe: 开始加载所有图片');

  // 加载微信二维码
  LoadImageFromDB('wechat_qr', imgWechat);

  // 加载支付宝二维码
  LoadImageFromDB('alipay_qr', imgAlipay);

  // 加载开发者照片
  LoadImageFromDB('aboutme_photo', imgAboutMe);

  // 加载BTC二维码
  LoadImageFromDB('btc_qr', imgBTC);

  // 加载USDT二维码
  LoadImageFromDB('usdt_qr', imgUSDT);

  LogMessage('FrameAboutMe: 所有图片加载完成');
end;

procedure TFrameAboutMe.LogMessage(const Msg: string);
begin
  // 🔧 修复：输出到调试控制台
  OutputDebugString(PChar('FrameAboutMe: ' + Msg));
end;

// PageControl Tab高亮绘制 - pcAboutMe
procedure TFrameAboutMe.pcAboutMeDrawTab(Control: TCustomTabControl; TabIndex: Integer;
  const Rect: TRect; Active: Boolean);
var
  TabControl: TPageControl;
  Canvas: TCanvas;
  TabRect: TRect;
  TextRect: TRect;
  TabText: string;
  ThemeColors: TThemeColors;
  ActiveColor, InactiveColor, TextColor: TColor;
begin
  TabControl := Control as TPageControl;
  Canvas := TabControl.Canvas;
  TabRect := Rect;

  // 获取当前主题颜色（简化版本）
  // TODO: 从主窗体获取主题信息
  // 使用默认颜色
  begin
    // 默认颜色 - 使用打赏主题的橙色
    ActiveColor := $FF6B35;  // 橙色高亮
    InactiveColor := clBtnFace;
    TextColor := clWindowText;
  end;

  // 绘制tab背景
  if Active then
  begin
    // 活动tab - 使用高亮颜色和渐变效果
    Canvas.Brush.Color := ActiveColor;
    Canvas.Pen.Color := ActiveColor;
    Canvas.FillRect(TabRect);

    // 添加顶部高亮线条
    Canvas.Pen.Color := RGB(255, 255, 255);
    Canvas.Pen.Width := 2;
    Canvas.MoveTo(TabRect.Left, TabRect.Top);
    Canvas.LineTo(TabRect.Right, TabRect.Top);
  end
  else
  begin
    // 非活动tab - 使用普通颜色
    Canvas.Brush.Color := InactiveColor;
    Canvas.Pen.Color := InactiveColor;
    Canvas.FillRect(TabRect);
  end;

  // 绘制tab文本
  if (TabIndex >= 0) and (TabIndex < TabControl.PageCount) then
  begin
    TabText := TabControl.Pages[TabIndex].Caption;
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Color := TextColor;

    if Active then
    begin
      Canvas.Font.Style := [fsBold];  // 活动tab使用粗体
      Canvas.Font.Color := clWhite;   // 活动tab使用白色文字
    end
    else
    begin
      Canvas.Font.Style := [];
    end;

    // 计算文本居中位置
    TextRect := TabRect;
    DrawText(Canvas.Handle, PChar(TabText), Length(TabText), TextRect,
             DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  end;
end;

// 获取硬件信息
function TFrameAboutMe.GetHardwareInfo: string;
var
  SystemInfo: TSystemInfo;
  ComputerName: array[0..MAX_COMPUTERNAME_LENGTH] of Char;
  Size: DWORD;
  WindowsDir: array[0..MAX_PATH] of Char;
  SystemDir: array[0..MAX_PATH] of Char;
  VersionInfo: TOSVersionInfo;
begin
  Result := '';

  try
    // 获取计算机名
    Size := SizeOf(ComputerName);
    if GetComputerName(ComputerName, Size) then
      Result := Result + string(ComputerName) + '|';

    // 获取系统信息
    GetSystemInfo(SystemInfo);
    Result := Result + IntToStr(SystemInfo.dwProcessorType) + '|';
    Result := Result + IntToStr(SystemInfo.dwNumberOfProcessors) + '|';
    Result := Result + IntToStr(SystemInfo.wProcessorArchitecture) + '|';

    // 获取Windows目录
    if GetWindowsDirectory(WindowsDir, SizeOf(WindowsDir)) > 0 then
      Result := Result + string(WindowsDir) + '|';

    // 获取系统目录
    if GetSystemDirectory(SystemDir, SizeOf(SystemDir)) > 0 then
      Result := Result + string(SystemDir) + '|';

    // 获取版本信息
    VersionInfo.dwOSVersionInfoSize := SizeOf(VersionInfo);
    if GetVersionEx(VersionInfo) then
    begin
      Result := Result + IntToStr(VersionInfo.dwMajorVersion) + '.' +
                IntToStr(VersionInfo.dwMinorVersion) + '.' +
                IntToStr(VersionInfo.dwBuildNumber) + '|';
    end;

    // 添加当前用户名
    Size := SizeOf(ComputerName);
    if GetUserName(ComputerName, Size) then
      Result := Result + string(ComputerName) + '|';

    // 添加时间戳作为唯一性保证
    Result := Result + IntToStr(GetTickCount64) + '|';

  except
    on E: Exception do
    begin
      LogMessage('获取硬件信息失败: ' + E.Message);
      // 使用备用方案
      Result := 'BACKUP_' + IntToStr(GetTickCount) + '_' + FormatDateTime('yyyymmddhhnnss', Now);
    end;
  end;

  // 确保有基本信息
  if Result = '' then
    Result := 'DEFAULT_' + IntToStr(GetTickCount) + '_' + FormatDateTime('yyyymmddhhnnss', Now);
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

// 更新机器码显示
procedure TFrameAboutMe.UpdateMachineCodeDisplay;
begin
  try
    lblMachineCodeValue.Caption := GenerateMachineCode;
    lblMachineCodeValue.Hint := '点击复制机器码到剪贴板';
  except
    on E: Exception do
    begin
      LogMessage('更新机器码显示失败: ' + E.Message);
      lblMachineCodeValue.Caption := 'ERROR-DISPLAY';
    end;
  end;
end;

// 机器码标签点击事件
procedure TFrameAboutMe.lblMachineCodeValueClick(Sender: TObject);
begin
  try
    Clipboard.AsText := lblMachineCodeValue.Caption;

    // 显示复制成功提示
    Vcl.Dialogs.ShowMessage('机器码已复制到剪贴板: ' + lblMachineCodeValue.Caption);

    LogMessage('机器码已复制到剪贴板: ' + lblMachineCodeValue.Caption);
  except
    on E: Exception do
    begin
      LogMessage('复制机器码失败: ' + E.Message);
      Vcl.Dialogs.ShowMessage('复制机器码失败: ' + E.Message);
    end;
  end;
end;

end.

unit FrameAboutMe;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, System.NetEncoding, System.Hash, Vcl.Imaging.pngimage,
  Vcl.Clipbrd, System.IOUtils, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.VCLUI.Wait, FireDAC.Phys.SQLiteWrapper.Stat, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.DataSet, uAntiTamperPackage, uBasicProtection;

type
  // 打赏地址类型
  TDonationAddressType = (datWechat, datAlipay, datBTC, datUSDT, datAboutMe);

  // 图像映射记录类型（修复E2169：不能在字段处定义匿名record）
  TImageMapping = record
    Key: string;
    Image: TImage;
    AddressLabel: TLabel;
    DefaultAddress: string;
  end;
  { MigrateEncryptedImages implementation moved to implementation section }

  TFrameAboutMe = class(TFrame)
    pcAboutMe: TPageControl;
    tsWechat: TTabSheet;
    tsAlipay: TTabSheet;
    tsBTC: TTabSheet;
    tsUSDT: TTabSheet;
    tsAboutMe: TTabSheet;
    
    // 微信页面
    imgWechat: TImage;
    lblWechatTip: TLabel;
    lblWechatAddress: TLabel;

    // 支付宝页面
    imgAlipay: TImage;
    lblAlipayTip: TLabel;
    lblAlipayAddress: TLabel;

    // BTC页面
    imgBTC: TImage;
    lblBTCTip: TLabel;
    lblBTCAddress: TLabel;
    btnCopyBTC: TButton;

    // USDT页面
    imgUSDT: TImage;
    lblUSDTTip: TLabel;
    lblUSDTAddress: TLabel;
    btnCopyUSDT: TButton;

    // 关于我页面
    imgAboutMe: TImage;
    lblAboutMeTip: TLabel;
    lblMachineCode: TLabel;
    lblMachineCodeValue: TLabel;
    FDConnection1: TFDConnection;
    FDPhysSQLiteDriverLink1: TFDPhysSQLiteDriverLink;
    FDTable1: TFDTable;
    
    procedure btnCopyBTCClick(Sender: TObject);
    procedure btnCopyUSDTClick(Sender: TObject);
    procedure lblMachineCodeValueClick(Sender: TObject);
    procedure pcAboutMeDrawTab(Control: TCustomTabControl; TabIndex: Integer;
      const Rect: TRect; Active: Boolean);

  private
    // 字段应在方法之前声明，避免E2169
    FInitTimer: TTimer;
    FImageMappings: array[0..4] of TImageMapping;

    // 日志与内部方法
    procedure Log(const Msg: string);
    procedure InitializeDataManager;
    procedure MigrateEncryptedImages; // 迁移旧加密数据为固定口令方案
    procedure LoadAndDisplayImages;
    procedure InitializeImageMappings;
    procedure EnsureDefaultImagesPresent;
    procedure OnInitTimerTimer(Sender: TObject);
    function GetProjectRootPath: string;

    // UI更新
    procedure CopyAddressToClipboard(const Address: string; const AddressName: string);
    function GenerateMachineCode: string;
    procedure UpdateMachineCodeDisplay;
    
  public
    constructor Create(AOwner: TComponent); override;
    procedure AfterConstruction; override;
    destructor Destroy; override;
    procedure ManualInitialize;
    
    // 公共接口
    procedure RotateToNextPage;
    function GetCurrentPageIndex: Integer;
    procedure SetActivePage(PageIndex: Integer);
  end;

implementation

{$R *.dfm}

procedure TFrameAboutMe.Log(const Msg: string);
var
  LogFileName: string;
  Writer: TStreamWriter;
begin
  try
    LogFileName := GetProjectRootPath + 'aboutme_debug.log';
    Writer := TStreamWriter.Create(LogFileName, True, TEncoding.UTF8);
    try
      Writer.WriteLine(Format('[%s] %s', [DateTimeToStr(Now), Msg]));
    finally
      Writer.Free;
    end;
  except
    // 静默失败，防止日志记录本身导致崩溃
  end;
end;

constructor TFrameAboutMe.Create(AOwner: TComponent);
var
  LogFile: TextFile;
begin
  inherited Create(AOwner);

  Log('FrameAboutMe.Create 开始执行');

  // 设置PageControl的OnDrawTab事件
  pcAboutMe.OwnerDraw := True;
  pcAboutMe.OnDrawTab := pcAboutMeDrawTab;

  // 更新机器码显示
  UpdateMachineCodeDisplay;

  Log('基本设置完成，创建Timer');

  // 创建延迟初始化Timer
  FInitTimer := TTimer.Create(Self);
  FInitTimer.Interval := 1000; // 1秒后初始化
  FInitTimer.OnTimer := OnInitTimerTimer;
  FInitTimer.Enabled := True;

  Log('FrameAboutMe.Create 完成');
end;

procedure TFrameAboutMe.AfterConstruction;
begin
  inherited AfterConstruction;

  // 不在这里初始化，等待主窗体手动调用
end;

procedure TFrameAboutMe.ManualInitialize;
begin
  // 手动初始化方法，由主窗体调用
  InitializeDataManager;
  EnsureDefaultImagesPresent;
  LoadAndDisplayImages;
end;

procedure TFrameAboutMe.OnInitTimerTimer(Sender: TObject);
var
  LogFile: TextFile;
begin
  // 停止Timer
  FInitTimer.Enabled := False;

  Log('Timer触发，开始延迟初始化');

  // 执行延迟初始化
  InitializeDataManager;
  EnsureDefaultImagesPresent;
  LoadAndDisplayImages;

  Log('延迟初始化完成');
end;

destructor TFrameAboutMe.Destroy;
begin
  // 设计时组件会自动释放，无需手动释放
  inherited;
end;

procedure TFrameAboutMe.InitializeDataManager;
var
  LogFile: TextFile;
  LogFileName: string;
  DatabasePath: string;
begin
  try
    LogFileName := GetProjectRootPath + 'aboutme_debug.log';
    
    // 启动时强制清空日志文件（截断为0字节）
    try
      TFile.WriteAllText(LogFileName, '');
    except
      // 忽略清空日志的异常
    end;

    Log('InitializeDataManager started');
    Log('Project root directory: ' + GetProjectRootPath);

    // 设置动态数据库路径
    DatabasePath := GetProjectRootPath + 'MoveC.db';
    Log('Setting database path: ' + DatabasePath);

    // 检查数据库文件是否存在
    if not TFile.Exists(DatabasePath) then
    begin
      Log('Database file does not exist: ' + DatabasePath);
      raise Exception.Create('Database file not found');
    end;

    // 设置数据库连接字符串
    Log('Setting up database connection');
    FDConnection1.Params.Values['Database'] := DatabasePath;
    // Note: Password is not set here as encryption is handled at application level

    // 绑定表到 images（防止设计时指向错误的表）
    FDTable1.Connection := FDConnection1;
    FDTable1.TableName := 'images';

    // 检查设计时数据库组件状态
    Log('Checking design-time database components:');
    Log('  FDConnection1.Connected: ' + BoolToStr(FDConnection1.Connected, True));
    Log('  FDTable1.Active: ' + BoolToStr(FDTable1.Active, True));
    Log('  Database path: ' + FDConnection1.Params.Values['Database']);
    Log('  FDTable1.TableName: ' + FDTable1.TableName);

    // 如果连接未激活，尝试激活
    if not FDConnection1.Connected then
    begin
      Log('Attempting to activate database connection');
      try
        FDConnection1.Connected := True;
        Log('Database connection activated successfully');
      except
        on E: Exception do
        begin
          Log('Database connection activation failed: ' + E.Message);
          raise;
        end;
      end;
    end;

    // 如果表未激活，尝试激活
    if not FDTable1.Active then
    begin
      Log('Attempting to activate data table');
      try
        FDTable1.Active := True;
        Log('Data table activated successfully');
      except
        on E: Exception do
        begin
          Log('Data table activation failed: ' + E.Message);
          raise;
        end;
      end;
    end;

    // 在加载图像前执行一次性迁移（将旧加密改为“仅固定口令”方案）
    MigrateEncryptedImages;

    // 初始化图像映射数组
    InitializeImageMappings;

    // 自愈：确保默认5张图像存在
    EnsureDefaultImagesPresent;

  except
    on E: Exception do
    begin
      // 记录错误但不中断程序
      Log('InitializeDataManager failed: ' + E.Message);
    end;
  end;
end;

function TFrameAboutMe.GetProjectRootPath: string;
var
  CurrentPath: string;
  TestPath: string;
  SearchCount: Integer;
begin
  // 获取当前程序路径
  CurrentPath := ExtractFilePath(ParamStr(0));
  SearchCount := 0;

  // 向上查找项目根目录，直到找到MoveC.db文件
  while (CurrentPath <> '') and (SearchCount < 5) do
  begin
    TestPath := IncludeTrailingPathDelimiter(CurrentPath) + 'MoveC.db';
    if TFile.Exists(TestPath) then
    begin
      Result := IncludeTrailingPathDelimiter(CurrentPath);
      Exit;
    end;

    // 向上一级目录
    CurrentPath := ExtractFilePath(ExcludeTrailingPathDelimiter(CurrentPath));
    Inc(SearchCount);
  end;

  // 如果没找到，使用程序当前目录
  Result := ExtractFilePath(ParamStr(0));
end;

procedure TFrameAboutMe.MigrateEncryptedImages;
begin
  // 迁移功能已废弃，不再需要兼容旧加密方式
  // 所有图像应使用ImportImages工具重新导入
end;

procedure TFrameAboutMe.EnsureDefaultImagesPresent;
var
  Q: TFDQuery;
  Total: Integer;

  procedure InsertOne(const AKey, AFileName, AAddress: string);
  var
    Q2: TFDQuery;
    Cnt: Integer;
    AssetPath: string;
    Plain, Encrypted: TBytes;
    SHA: string;
    MS: TMemoryStream;
  begin
    try
      if not FDConnection1.Connected then
      begin
        Log('EnsureDefaultImagesPresent: database not connected');
        Exit;
      end;

      Q2 := TFDQuery.Create(nil);
      try
        Q2.Connection := FDConnection1;

        // Check existence
        Q2.SQL.Text := 'SELECT COUNT(*) FROM images WHERE image_key = :key';
        Q2.ParamByName('key').AsString := AKey;
        Q2.Open;
        try
          Cnt := Q2.Fields[0].AsInteger;
        finally
          Q2.Close;
        end;

        if Cnt > 0 then
        begin
          Log(Format('EnsureDefaultImagesPresent: %s already exists, skip', [AKey]));
          Exit;
        end;

        // Load asset file
        AssetPath := GetProjectRootPath + 'assets\' + AFileName;
        if not TFile.Exists(AssetPath) then
        begin
          Log(Format('EnsureDefaultImagesPresent: asset not found: %s', [AssetPath]));
          Exit;
        end;

        Plain := TFile.ReadAllBytes(AssetPath);
        SHA := TAntiTamperPackage.CalculateSHA256(Plain);
        Encrypted := TBasicProtection.EncryptBinaryData(Plain, '@2241114');

        // Insert row (write encrypted bytes as BLOB)
        Q2.SQL.Text := 'INSERT INTO images (image_key, image_data, address_text, description, md5_hash) ' +
                      'VALUES (:key, :data, :addr, :desc, :md5)';
        Q2.ParamByName('key').AsString := AKey;
        Q2.ParamByName('addr').AsString := AAddress;
        Q2.ParamByName('desc').AsString := 'Auto-insert on startup';
        Q2.ParamByName('md5').AsString := SHA;
        MS := TMemoryStream.Create;
        try
          if Length(Encrypted) > 0 then
            MS.WriteBuffer(Encrypted[0], Length(Encrypted));
          MS.Position := 0;
          Q2.ParamByName('data').LoadFromStream(MS, ftBlob);
        finally
          MS.Free;
        end;
        Q2.ExecSQL;
        Log(Format('EnsureDefaultImagesPresent: inserted %s (%d bytes encrypted)', [AKey, Length(Encrypted)]));
      finally
        Q2.Free;
      end;
    except
      on E: Exception do
        Log(Format('EnsureDefaultImagesPresent error on %s: %s', [AKey, E.Message]));
    end;
  end;

begin
  // 自愈插入：若某些记录缺失，仅补齐缺失项（幂等，不重复写入）
  try
    if FDConnection1.Connected then
    begin
      // 可选：记录当前行数到日志，便于诊断
      Q := TFDQuery.Create(nil);
      try
        Q.Connection := FDConnection1;
        Q.SQL.Text := 'SELECT COUNT(*) FROM images';
        Q.Open;
        try
          Total := Q.Fields[0].AsInteger;
          Log(Format('EnsureDefaultImagesPresent: current records = %d', [Total]));
        finally
          Q.Close;
        end;
      finally
        Q.Free;
      end;
    end
    else
    begin
      Log('EnsureDefaultImagesPresent: database not connected, skip');
      Exit;
    end;
  except
    on E: Exception do
    begin
      Log('EnsureDefaultImagesPresent: failed to count records - ' + E.Message);
      // 统计失败不影响后续按键检查
    end;
  end;

  // Insert remaining images if missing (wechat may already be present)
  InsertOne('alipay', 'AliPay.png', '支付宝收款码');
  InsertOne('btc', 'btc.png', 'bc1qze0ggsrdtjqwjpjfufydsuyjxc08tgcq5xkct3');
  InsertOne('usdt', 'usdt.png', 'TH1NazpoEpUqcEotGzLPHs13SbLDJKKCys');
  InsertOne('aboutme', 'itsMe.jpg', '');
end;

procedure TFrameAboutMe.InitializeImageMappings;
var
  LogFile: TextFile;
  LogFileName: string;
begin
  LogFileName := GetProjectRootPath + 'aboutme_debug.log';

  Log('开始初始化图像映射数组');
  Log('验证Image控件分配状态:');
  Log(Format('  imgWechat: %s (地址: %p)', [BoolToStr(Assigned(imgWechat), True), Pointer(imgWechat)]));
  Log(Format('  imgAlipay: %s (地址: %p)', [BoolToStr(Assigned(imgAlipay), True), Pointer(imgAlipay)]));
  Log(Format('  imgBTC: %s (地址: %p)', [BoolToStr(Assigned(imgBTC), True), Pointer(imgBTC)]));
  Log(Format('  imgUSDT: %s (地址: %p)', [BoolToStr(Assigned(imgUSDT), True), Pointer(imgUSDT)]));
  Log(Format('  imgAboutMe: %s (地址: %p)', [BoolToStr(Assigned(imgAboutMe), True), Pointer(imgAboutMe)]));
  Log('Frame状态检查:');
  Log(Format('  Frame.Parent: %s', [BoolToStr(Assigned(Parent), True)]));
  Log(Format('  Frame.Visible: %s', [BoolToStr(Visible, True)]));
  Log(Format('  Frame.ComponentCount: %d', [ComponentCount]));

  FImageMappings[0].Key := 'wechat';
  FImageMappings[0].Image := imgWechat;
  FImageMappings[0].AddressLabel := lblWechatAddress;
  FImageMappings[0].DefaultAddress := '微信收款码';

  FImageMappings[1].Key := 'alipay';
  FImageMappings[1].Image := imgAlipay;
  FImageMappings[1].AddressLabel := lblAlipayAddress;
  FImageMappings[1].DefaultAddress := '支付宝收款码';

  FImageMappings[2].Key := 'btc';
  FImageMappings[2].Image := imgBTC;
  FImageMappings[2].AddressLabel := lblBTCAddress;
  FImageMappings[2].DefaultAddress := 'BTC地址';

  FImageMappings[3].Key := 'usdt';
  FImageMappings[3].Image := imgUSDT;
  FImageMappings[3].AddressLabel := lblUSDTAddress;
  FImageMappings[3].DefaultAddress := 'USDT地址';

  FImageMappings[4].Key := 'aboutme';
  FImageMappings[4].Image := imgAboutMe;
  FImageMappings[4].AddressLabel := nil;
  FImageMappings[4].DefaultAddress := '';

  Log('图像映射数组初始化完成');
end;

procedure TFrameAboutMe.LoadAndDisplayImages;
var
  I: Integer;
  LogFileName: string;
  ImageField, AddressField, SHAField: TField;
  MemoryStream: TMemoryStream;
  EncryptedData, DecryptedData: TBytes;
begin
  LogFileName := GetProjectRootPath + 'aboutme_debug.log';
  Log('开始加载和显示图像');

  try
    for I := 0 to High(FImageMappings) do
    begin
      Log(Format('处理图像 %d: %s', [I, FImageMappings[I].Key]));

      if FDTable1.Active and Assigned(FImageMappings[I].Image) then
      begin
        try
          if FDTable1.Locate('image_key', FImageMappings[I].Key, []) then
          begin
            Log(Format('在数据库中找到记录: %s', [FImageMappings[I].Key]));

            ImageField := FDTable1.FieldByName('image_data');
            AddressField := FDTable1.FieldByName('address_text');
            // 数据库列名为 md5_hash（实际存储为SHA-256值）
            SHAField := FDTable1.FieldByName('md5_hash');

            if not ImageField.IsNull then
            begin
              MemoryStream := TMemoryStream.Create;
              try
                TBlobField(ImageField).SaveToStream(MemoryStream);
                MemoryStream.Position := 0;

                SetLength(EncryptedData, MemoryStream.Size);
                if MemoryStream.Size > 0 then
                  MemoryStream.ReadBuffer(EncryptedData[0], MemoryStream.Size);

                Log(Format('加密数据长度: %d bytes', [Length(EncryptedData)]));

                DecryptedData := TBasicProtection.DecryptBinaryData(EncryptedData, '@2241114');
                Log(Format('解密数据长度: %d bytes', [Length(DecryptedData)]));

                if not TAntiTamperPackage.VerifyImageIntegrity(DecryptedData, SHAField.AsString) then
                begin
                  Log(Format('SHA-256校验失败: %s', [FImageMappings[I].Key]));
                  TAntiTamperPackage.HandleSecurityViolation(FImageMappings[I].Key, 'SHA-256校验失败');
                  Exit;
                end;

                MemoryStream.Clear;
                if Length(DecryptedData) > 0 then
                  MemoryStream.WriteBuffer(DecryptedData[0], Length(DecryptedData));
                MemoryStream.Position := 0;

                if MemoryStream.Size > 0 then
                begin
                  FImageMappings[I].Image.Picture.LoadFromStream(MemoryStream);
                  Log(Format('数据库图像加载成功: %s, 数据大小: %d bytes',
                    [FImageMappings[I].Key, MemoryStream.Size]));

                  if Assigned(FImageMappings[I].AddressLabel) then
                  begin
                    if not AddressField.IsNull and (AddressField.AsString <> '') then
                      FImageMappings[I].AddressLabel.Caption := AddressField.AsString
                    else
                      FImageMappings[I].AddressLabel.Caption := FImageMappings[I].DefaultAddress;
                  end;
                end
                else
                begin
                  Log(Format('图像数据为空: %s', [FImageMappings[I].Key]));
                end;
              finally
                MemoryStream.Free;
              end;
            end
            else
            begin
              Log(Format('图像字段为空: %s', [FImageMappings[I].Key]));
            end;
          end
          else
          begin
            Log(Format('未找到图像记录: %s', [FImageMappings[I].Key]));
          end;
        except
          on E: Exception do
            Log(Format('处理图像时异常: %s - %s', [FImageMappings[I].Key, E.Message]));
        end;
      end
      else
      begin
        Log(Format('数据表未激活或Image控件未分配: %s', [FImageMappings[I].Key]));
      end;
    end;
  except
    on E: Exception do
      Log(Format('LoadAndDisplayImages顶层异常: %s', [E.Message]));
  end;
end;

// 旧方法已删除



// 旧方法已删除

// SaveImageToDebugFolder方法已删除

procedure TFrameAboutMe.btnCopyBTCClick(Sender: TObject);
var
  BTCAddress: string;
  AddressField: TField;
begin
  if FDTable1.Active then
  begin
    if FDTable1.Locate('image_key', 'btc', []) then
    begin
      AddressField := FDTable1.FieldByName('address_text');
      if not AddressField.IsNull and (AddressField.AsString <> '') then
        BTCAddress := AddressField.AsString
      else
        BTCAddress := 'BTC地址未配置';
    end
    else
      BTCAddress := 'BTC记录未找到';

    CopyAddressToClipboard(BTCAddress, 'BTC地址');
  end
  else
    CopyAddressToClipboard('数据库未连接', 'BTC地址');
end;

procedure TFrameAboutMe.btnCopyUSDTClick(Sender: TObject);
var
  USDTAddress: string;
  AddressField: TField;
begin
  if FDTable1.Active then
  begin
    if FDTable1.Locate('image_key', 'usdt', []) then
    begin
      AddressField := FDTable1.FieldByName('address_text');
      if not AddressField.IsNull and (AddressField.AsString <> '') then
        USDTAddress := AddressField.AsString
      else
        USDTAddress := 'USDT地址未配置';
    end
    else
      USDTAddress := 'USDT记录未找到';

    CopyAddressToClipboard(USDTAddress, 'USDT地址');
  end
  else
    CopyAddressToClipboard('数据库未连接', 'USDT地址');
end;

procedure TFrameAboutMe.CopyAddressToClipboard(const Address: string; const AddressName: string);
begin
  try
    Clipboard.AsText := Address;
    // 地址已复制到剪贴板
  except
    on E: Exception do
      // 复制失败，但不显示错误
  end;
end;

procedure TFrameAboutMe.RotateToNextPage;
var
  NextIndex: Integer;
begin
  NextIndex := (pcAboutMe.ActivePageIndex + 1) mod pcAboutMe.PageCount;
  pcAboutMe.ActivePageIndex := NextIndex;
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
  end;
end;

function TFrameAboutMe.GenerateMachineCode: string;
var
  ComputerName: array[0..MAX_COMPUTERNAME_LENGTH] of Char;
  Size: DWORD;
  HashValue: string;
begin
  try
    Size := SizeOf(ComputerName);
    if GetComputerName(ComputerName, Size) then
    begin
      HashValue := THashSHA2.GetHashString(string(ComputerName) + IntToStr(GetTickCount64), SHA256);
      Result := Copy(HashValue, 1, 16).ToUpper;
      Result := Copy(Result, 1, 4) + '-' + Copy(Result, 5, 4) + '-' + 
                Copy(Result, 9, 4) + '-' + Copy(Result, 13, 4);
    end
    else
      Result := 'ERROR-GENE-RATE-CODE';
  except
    Result := 'ERROR-GENE-RATE-CODE';
  end;
end;

procedure TFrameAboutMe.UpdateMachineCodeDisplay;
begin
  try
    lblMachineCodeValue.Caption := GenerateMachineCode;
    lblMachineCodeValue.Hint := '点击复制机器码到剪贴板';
  except
    lblMachineCodeValue.Caption := 'ERROR-DISPLAY';
  end;
end;

procedure TFrameAboutMe.lblMachineCodeValueClick(Sender: TObject);
begin
  try
    Clipboard.AsText := lblMachineCodeValue.Caption;
    ShowMessage('机器码已复制到剪贴板: ' + lblMachineCodeValue.Caption);
  except
    on E: Exception do
    begin
      ShowMessage('复制机器码失败: ' + E.Message);
    end;
  end;
end;

procedure TFrameAboutMe.pcAboutMeDrawTab(Control: TCustomTabControl; TabIndex: Integer;
  const Rect: TRect; Active: Boolean);
var
  TabControl: TPageControl;
  Canvas: TCanvas;
  TabRect: TRect;
  TextRect: TRect;
  TabText: string;
  ActiveColor, InactiveColor, TextColor: TColor;
begin
  TabControl := Control as TPageControl;
  Canvas := TabControl.Canvas;
  TabRect := Rect;

  // 设置颜色
  ActiveColor := $FF6B35;  // 橙色高亮
  InactiveColor := clBtnFace;
  TextColor := clWindowText;

  // 绘制tab背景
  if Active then
  begin
    Canvas.Brush.Color := ActiveColor;
    Canvas.Pen.Color := ActiveColor;
    Canvas.FillRect(TabRect);
    Canvas.Pen.Color := RGB(255, 255, 255);
    Canvas.Pen.Width := 2;
    Canvas.MoveTo(TabRect.Left, TabRect.Top);
    Canvas.LineTo(TabRect.Right, TabRect.Top);
  end
  else
  begin
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
      Canvas.Font.Style := [fsBold];
      Canvas.Font.Color := clWhite;
    end
    else
    begin
      Canvas.Font.Style := [];
    end;

    TextRect := TabRect;
    DrawText(Canvas.Handle, PChar(TabText), Length(TabText), TextRect,
             DT_CENTER or DT_VCENTER or DT_SINGLELINE);
  end;
end;

// LogMessage方法已删除

end.
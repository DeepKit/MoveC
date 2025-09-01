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
  FireDAC.DApt, FireDAC.Comp.DataSet;

type
  // 打赏地址类型
  TDonationAddressType = (datWechat, datAlipay, datBTC, datUSDT, datAboutMe);

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
    FInitTimer: TTimer;
    FImageMappings: array[0..4] of record
      Key: string;
      Image: TImage;
      AddressLabel: TLabel;
      DefaultAddress: string;
    end;

    // 内部方法
    procedure InitializeDataManager;
    procedure LoadAndDisplayImages;
    procedure InitializeImageMappings;
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

constructor TFrameAboutMe.Create(AOwner: TComponent);
var
  LogFile: TextFile;
begin
  inherited Create(AOwner);

  // 立即写入日志确认Constructor被调用
  try
    AssignFile(LogFile, 'FRAME_CONSTRUCTOR_DEBUG.log');
    Rewrite(LogFile);
    WriteLn(LogFile, Format('[%s] FrameAboutMe.Create 开始执行', [DateTimeToStr(Now)]));
    CloseFile(LogFile);
  except
  end;

  // 设置PageControl的OnDrawTab事件
  pcAboutMe.OwnerDraw := True;
  pcAboutMe.OnDrawTab := pcAboutMeDrawTab;

  // 更新机器码显示
  UpdateMachineCodeDisplay;

  try
    AssignFile(LogFile, 'FRAME_CONSTRUCTOR_DEBUG.log');
    Append(LogFile);
    WriteLn(LogFile, Format('[%s] 基本设置完成，创建Timer', [DateTimeToStr(Now)]));
    CloseFile(LogFile);
  except
  end;

  // 创建延迟初始化Timer
  FInitTimer := TTimer.Create(Self);
  FInitTimer.Interval := 1000; // 1秒后初始化
  FInitTimer.OnTimer := OnInitTimerTimer;
  FInitTimer.Enabled := True;

  try
    AssignFile(LogFile, 'FRAME_CONSTRUCTOR_DEBUG.log');
    Append(LogFile);
    WriteLn(LogFile, Format('[%s] FrameAboutMe.Create 完成', [DateTimeToStr(Now)]));
    CloseFile(LogFile);
  except
  end;
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
  LoadAndDisplayImages;
end;

procedure TFrameAboutMe.OnInitTimerTimer(Sender: TObject);
var
  LogFile: TextFile;
begin
  // 停止Timer
  FInitTimer.Enabled := False;

  try
    AssignFile(LogFile, 'FRAME_CONSTRUCTOR_DEBUG.log');
    Append(LogFile);
    WriteLn(LogFile, Format('[%s] Timer触发，开始延迟初始化', [DateTimeToStr(Now)]));
    CloseFile(LogFile);
  except
  end;

  // 执行延迟初始化
  InitializeDataManager;
  LoadAndDisplayImages;

  try
    AssignFile(LogFile, 'FRAME_CONSTRUCTOR_DEBUG.log');
    Append(LogFile);
    WriteLn(LogFile, Format('[%s] 延迟初始化完成', [DateTimeToStr(Now)]));
    CloseFile(LogFile);
  except
  end;
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
begin
  try
    LogFileName := GetProjectRootPath + 'aboutme_debug.log';

    // 启动时清理旧日志
    try
      if TFile.Exists(LogFileName) then
        TFile.Delete(LogFileName);
    except
    end;

    // 写入日志
    try
      AssignFile(LogFile, LogFileName);
      Rewrite(LogFile);
      WriteLn(LogFile, Format('[%s] InitializeDataManager 开始', [DateTimeToStr(Now)]));
      WriteLn(LogFile, Format('[%s] 项目根目录: %s', [DateTimeToStr(Now), GetProjectRootPath]));
      CloseFile(LogFile);
    except
    end;

    // 设置动态数据库路径
    var DatabasePath := GetProjectRootPath + 'MoveC.db';
    try
      AssignFile(LogFile, LogFileName);
      Append(LogFile);
      WriteLn(LogFile, Format('[%s] 设置数据库路径: %s', [DateTimeToStr(Now), DatabasePath]));
      CloseFile(LogFile);
    except
    end;

    // 检查数据库文件是否存在
    if not TFile.Exists(DatabasePath) then
    begin
      try
        AssignFile(LogFile, LogFileName);
        Append(LogFile);
        WriteLn(LogFile, Format('[%s] 错误: 数据库文件不存在', [DateTimeToStr(Now)]));
        CloseFile(LogFile);
      except
      end;
      Exit;
    end;

    // 设置连接参数
    FDConnection1.Params.Values['Database'] := DatabasePath;

    // 检查设计时数据库组件状态
    try
      AssignFile(LogFile, LogFileName);
      Append(LogFile);
      WriteLn(LogFile, Format('[%s] 检查设计时数据库组件:', [DateTimeToStr(Now)]));
      WriteLn(LogFile, Format('[%s]   FDConnection1.Connected: %s', [DateTimeToStr(Now), BoolToStr(FDConnection1.Connected, True)]));
      WriteLn(LogFile, Format('[%s]   FDTable1.Active: %s', [DateTimeToStr(Now), BoolToStr(FDTable1.Active, True)]));
      WriteLn(LogFile, Format('[%s]   数据库路径: %s', [DateTimeToStr(Now), FDConnection1.Params.Values['Database']]));
      CloseFile(LogFile);
    except
      on E: Exception do
      begin
        try
          AssignFile(LogFile, LogFileName);
          Append(LogFile);
          WriteLn(LogFile, Format('[%s] 检查数据库组件时出错: %s', [DateTimeToStr(Now), E.Message]));
          CloseFile(LogFile);
        except
        end;
      end;
    end;

    // 如果连接未激活，尝试激活
    if not FDConnection1.Connected then
    begin
      try
        AssignFile(LogFile, LogFileName);
        Append(LogFile);
        WriteLn(LogFile, Format('[%s] 尝试激活数据库连接', [DateTimeToStr(Now)]));
        CloseFile(LogFile);
      except
      end;

      try
        FDConnection1.Connected := True;

        try
          AssignFile(LogFile, LogFileName);
          Append(LogFile);
          WriteLn(LogFile, Format('[%s] 数据库连接激活成功', [DateTimeToStr(Now)]));
          CloseFile(LogFile);
        except
        end;
      except
        on E: Exception do
        begin
          try
            AssignFile(LogFile, LogFileName);
            Append(LogFile);
            WriteLn(LogFile, Format('[%s] 数据库连接激活失败: %s', [DateTimeToStr(Now), E.Message]));
            CloseFile(LogFile);
          except
          end;
        end;
      end;
    end;

    // 如果表未激活，尝试激活
    if not FDTable1.Active then
    begin
      try
        AssignFile(LogFile, LogFileName);
        Append(LogFile);
        WriteLn(LogFile, Format('[%s] 尝试激活数据表', [DateTimeToStr(Now)]));
        CloseFile(LogFile);
      except
      end;

      try
        FDTable1.Active := True;

        try
          AssignFile(LogFile, LogFileName);
          Append(LogFile);
          WriteLn(LogFile, Format('[%s] 数据表激活成功', [DateTimeToStr(Now)]));
          CloseFile(LogFile);
        except
        end;
      except
        on E: Exception do
        begin
          try
            AssignFile(LogFile, LogFileName);
            Append(LogFile);
            WriteLn(LogFile, Format('[%s] 数据表激活失败: %s', [DateTimeToStr(Now), E.Message]));
            CloseFile(LogFile);
          except
          end;
        end;
      end;
    end;

    // 初始化图像映射数组
    InitializeImageMappings;

  except
    on E: Exception do
    begin
      // 记录错误但不中断程序
      try
        AssignFile(LogFile, LogFileName);
        Append(LogFile);
        WriteLn(LogFile, Format('[%s] 初始化数据管理器失败: %s', [DateTimeToStr(Now), E.Message]));
        CloseFile(LogFile);
      except
      end;
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

procedure TFrameAboutMe.InitializeImageMappings;
var
  LogFile: TextFile;
  LogFileName: string;
begin
  LogFileName := GetProjectRootPath + 'aboutme_debug.log';

  try
    AssignFile(LogFile, LogFileName);
    Append(LogFile);
    WriteLn(LogFile, Format('[%s] 开始初始化图像映射数组', [DateTimeToStr(Now)]));

    // 验证Image控件是否分配
    WriteLn(LogFile, Format('[%s] 验证Image控件分配状态:', [DateTimeToStr(Now)]));
    WriteLn(LogFile, Format('[%s]   imgWechat: %s (地址: %p)', [DateTimeToStr(Now), BoolToStr(Assigned(imgWechat), True), Pointer(imgWechat)]));
    WriteLn(LogFile, Format('[%s]   imgAlipay: %s (地址: %p)', [DateTimeToStr(Now), BoolToStr(Assigned(imgAlipay), True), Pointer(imgAlipay)]));
    WriteLn(LogFile, Format('[%s]   imgBTC: %s (地址: %p)', [DateTimeToStr(Now), BoolToStr(Assigned(imgBTC), True), Pointer(imgBTC)]));
    WriteLn(LogFile, Format('[%s]   imgUSDT: %s (地址: %p)', [DateTimeToStr(Now), BoolToStr(Assigned(imgUSDT), True), Pointer(imgUSDT)]));
    WriteLn(LogFile, Format('[%s]   imgAboutMe: %s (地址: %p)', [DateTimeToStr(Now), BoolToStr(Assigned(imgAboutMe), True), Pointer(imgAboutMe)]));

    // 验证Frame本身的状态
    WriteLn(LogFile, Format('[%s] Frame状态检查:', [DateTimeToStr(Now)]));
    WriteLn(LogFile, Format('[%s]   Frame.Parent: %s', [DateTimeToStr(Now), BoolToStr(Assigned(Parent), True)]));
    WriteLn(LogFile, Format('[%s]   Frame.Visible: %s', [DateTimeToStr(Now), BoolToStr(Visible, True)]));
    WriteLn(LogFile, Format('[%s]   Frame.ComponentCount: %d', [DateTimeToStr(Now), ComponentCount]));

    CloseFile(LogFile);
  except
  end;

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

  try
    AssignFile(LogFile, LogFileName);
    Append(LogFile);
    WriteLn(LogFile, Format('[%s] 图像映射数组初始化完成', [DateTimeToStr(Now)]));
    CloseFile(LogFile);
  except
  end;
end;

procedure TFrameAboutMe.LoadAndDisplayImages;
var
  I: Integer;
  LogFile: TextFile;
  LogFileName: string;
  FilePath: string;
  ImageData: TBytes;
  AddressText: string;
  MemoryStream: TMemoryStream;
begin
  LogFileName := GetProjectRootPath + 'aboutme_debug.log';

  try
    AssignFile(LogFile, LogFileName);
    Append(LogFile);
    WriteLn(LogFile, Format('[%s] 开始加载和显示图像', [DateTimeToStr(Now)]));
    CloseFile(LogFile);
  except
  end;

  try
    // 加载所有图像
    for I := 0 to High(FImageMappings) do
    begin
      try
        AssignFile(LogFile, LogFileName);
        Append(LogFile);
        WriteLn(LogFile, Format('[%s] 处理图像 %d: %s', [DateTimeToStr(Now), I, FImageMappings[I].Key]));
        CloseFile(LogFile);
      except
      end;

      // 所有图像都从数据库加载（包括微信）
      if FDTable1.Active and Assigned(FImageMappings[I].Image) then
        begin
          try
            // 查找指定image_key的记录
            if FDTable1.Locate('image_key', FImageMappings[I].Key, []) then
            begin
              try
                AssignFile(LogFile, LogFileName);
                Append(LogFile);
                WriteLn(LogFile, Format('[%s] 在数据库中找到记录: %s', [DateTimeToStr(Now), FImageMappings[I].Key]));
                CloseFile(LogFile);
              except
              end;

              // 获取图像数据
              var ImageField := FDTable1.FieldByName('image_data');
              var AddressField := FDTable1.FieldByName('address_text');

              if not ImageField.IsNull then
              begin
                try
                  MemoryStream := TMemoryStream.Create;
                  try
                    // 从Blob字段加载图像数据
                    TBlobField(ImageField).SaveToStream(MemoryStream);
                    MemoryStream.Position := 0;

                    if MemoryStream.Size > 0 then
                    begin
                      FImageMappings[I].Image.Picture.LoadFromStream(MemoryStream);

                      try
                        AssignFile(LogFile, LogFileName);
                        Append(LogFile);
                        WriteLn(LogFile, Format('[%s] 数据库图像加载成功: %s, 尺寸: %dx%d, 数据大小: %d bytes',
                          [DateTimeToStr(Now), FImageMappings[I].Key, FImageMappings[I].Image.Picture.Width,
                           FImageMappings[I].Image.Picture.Height, MemoryStream.Size]));
                        CloseFile(LogFile);
                      except
                      end;

                      // 设置地址文本
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
                      try
                        AssignFile(LogFile, LogFileName);
                        Append(LogFile);
                        WriteLn(LogFile, Format('[%s] 图像数据为空: %s', [DateTimeToStr(Now), FImageMappings[I].Key]));
                        CloseFile(LogFile);
                      except
                      end;
                    end;
                  finally
                    MemoryStream.Free;
                  end;
                except
                  on E: Exception do
                  begin
                    try
                      AssignFile(LogFile, LogFileName);
                      Append(LogFile);
                      WriteLn(LogFile, Format('[%s] 数据库图像加载失败: %s - %s', [DateTimeToStr(Now), FImageMappings[I].Key, E.Message]));
                      CloseFile(LogFile);
                    except
                    end;
                  end;
                end;
              end
              else
              begin
                try
                  AssignFile(LogFile, LogFileName);
                  Append(LogFile);
                  WriteLn(LogFile, Format('[%s] 图像字段为空: %s', [DateTimeToStr(Now), FImageMappings[I].Key]));
                  CloseFile(LogFile);
                except
                end;
              end;
            end
            else
            begin
              try
                AssignFile(LogFile, LogFileName);
                Append(LogFile);
                WriteLn(LogFile, Format('[%s] 数据库中未找到记录: %s', [DateTimeToStr(Now), FImageMappings[I].Key]));
                CloseFile(LogFile);
              except
              end;
            end;
          except
            on E: Exception do
            begin
              try
                AssignFile(LogFile, LogFileName);
                Append(LogFile);
                WriteLn(LogFile, Format('[%s] 查询数据库时出错: %s - %s', [DateTimeToStr(Now), FImageMappings[I].Key, E.Message]));
                CloseFile(LogFile);
              except
              end;
            end;
          end;
        end
        else
        begin
          try
            AssignFile(LogFile, LogFileName);
            Append(LogFile);
            WriteLn(LogFile, Format('[%s] 数据表未激活或Image控件未分配: %s', [DateTimeToStr(Now), FImageMappings[I].Key]));
            CloseFile(LogFile);
          except
          end;
        end;
    end;

  except
    on E: Exception do
    begin
      try
        AssignFile(LogFile, LogFileName);
        Append(LogFile);
        WriteLn(LogFile, Format('[%s] 加载图像失败: %s', [DateTimeToStr(Now), E.Message]));
        CloseFile(LogFile);
      except
      end;
    end;
  end;
end;

// 旧方法已删除



// 旧方法已删除

// SaveImageToDebugFolder方法已删除

procedure TFrameAboutMe.btnCopyBTCClick(Sender: TObject);
var
  BTCAddress: string;
begin
  if FDTable1.Active then
  begin
    if FDTable1.Locate('image_key', 'btc', []) then
    begin
      var AddressField := FDTable1.FieldByName('address_text');
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
begin
  if FDTable1.Active then
  begin
    if FDTable1.Locate('image_key', 'usdt', []) then
    begin
      var AddressField := FDTable1.FieldByName('address_text');
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
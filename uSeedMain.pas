unit uSeedMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Buttons, System.IOUtils, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.Stan.Def, FireDAC.Stan.Async,
  FireDAC.DApt, FireDAC.UI.Intf, FireDAC.VCLUI.Wait, FireDAC.Comp.UI,
  FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteWrapper.Stat,
  uAntiTamperPackage;

type
  TfrmSeedMain = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    pnlCenter: TPanel;
    gbPassword: TGroupBox;
    edtPassword: TEdit;
    lblPasswordHint: TLabel;
    gbImages: TGroupBox;
    lstImages: TListBox;
    btnAddImage: TBitBtn;
    btnRemoveImage: TBitBtn;
    btnClearAll: TBitBtn;
    pnlBottom: TPanel;
    btnSeed: TBitBtn;
    btnClose: TBitBtn;
    memoLog: TMemo;
    lblImageCount: TLabel;
    OpenDialog: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure btnAddImageClick(Sender: TObject);
    procedure btnRemoveImageClick(Sender: TObject);
    procedure btnClearAllClick(Sender: TObject);
    procedure btnSeedClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FImageFiles: TStringList;
    procedure Log(const Msg: string);
    function ValidateInputs: Boolean;
    function ConnectDatabase: TFDConnection;
    function SeedImage(AConn: TFDConnection; const AImagePath: string): Boolean;
    procedure UpdateImageCount;
  public
    { Public declarations }
  end;

var
  frmSeedMain: TfrmSeedMain;

implementation

{$R *.dfm}

procedure TfrmSeedMain.FormCreate(Sender: TObject);
begin
  // 防篡改配置将在播种时根据用户输入的密码初始化
  
  FImageFiles := TStringList.Create;
  
  Caption := '防篡改播种工具 - MoveC';
  lblTitle.Caption := '图像资源加密播种工具';
  edtPassword.PasswordChar := '*';
  edtPassword.TextHint := '请输入管理员密码';
  lblPasswordHint.Caption := '提示：此密码将用于加密图像数据。请输入与主程序 uMain.pas Config.EncryptionKey 一致的密码';
  
  btnSeed.Enabled := False;
  UpdateImageCount;
  
  Log('播种工具已启动');
  Log('严格模式：将写入 sha256_hash + hmac_sha256 字段');
end;

procedure TfrmSeedMain.btnAddImageClick(Sender: TObject);
var
  I: Integer;
  FileName: string;
begin
  OpenDialog.Filter := '图像文件|*.png;*.jpg;*.jpeg;*.bmp;*.gif|所有文件|*.*';
  OpenDialog.Options := OpenDialog.Options + [ofAllowMultiSelect];
  
  if OpenDialog.Execute then
  begin
    for I := 0 to OpenDialog.Files.Count - 1 do
    begin
      if FImageFiles.Values[OpenDialog.Files[I]] <> '' then
        Continue; // 跳过重复
      
      FileName := TPath.GetFileNameWithoutExtension(OpenDialog.Files[I]);
      FImageFiles.Add(FileName + '=' + OpenDialog.Files[I]);
      lstImages.Items.Add(Format('%s -> %s', [FileName, TPath.GetFileName(OpenDialog.Files[I])]));
    end;
    
    UpdateImageCount;
    Log(Format('已添加 %d 个图像文件', [OpenDialog.Files.Count]));
  end;
end;

procedure TfrmSeedMain.btnRemoveImageClick(Sender: TObject);
begin
  if lstImages.ItemIndex >= 0 then
  begin
    FImageFiles.Delete(lstImages.ItemIndex);
    lstImages.Items.Delete(lstImages.ItemIndex);
    UpdateImageCount;
    Log('已移除选中的图像');
  end;
end;

procedure TfrmSeedMain.btnClearAllClick(Sender: TObject);
begin
  if MessageDlg('确定要清空所有图像吗？', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FImageFiles.Clear;
    lstImages.Clear;
    UpdateImageCount;
    Log('已清空所有图像');
  end;
end;

procedure TfrmSeedMain.btnSeedClick(Sender: TObject);
var
  Conn: TFDConnection;
  I, SuccessCount, FailCount: Integer;
  Config: TAntiTamperConfig;
begin
  if not ValidateInputs then
    Exit;
    
  btnSeed.Enabled := False;
  Screen.Cursor := crHourGlass;
  try
    Log('===== 开始播种 =====');
    
    // 使用用户输入的密码初始化防篡改包
    Config := TAntiTamperPackage.GetDefaultConfig;
    Config.EncryptionKey := edtPassword.Text; // 使用用户输入的密码
    Config.DownloadURL := 'https://www.goodmem.cn';
    Config.EnableLogging := True;
    Config.EncryptionType := etAES256;
    Config.Salt := 'MoveC_Salt_v1';
    Config.KdfIterations := 10000;
    Config.EnableHMAC := True;
    TAntiTamperPackage.Initialize(Config);
    Log(Format('✓ 已使用管理员密码初始化防篡改包（密码长度：%d）', [Length(edtPassword.Text)]));
    
    // 连接数据库
    Conn := ConnectDatabase;
    if not Assigned(Conn) then
    begin
      Log('❌ 数据库连接失败');
      Exit;
    end;
    
    try
      // 确保表结构
      if not TAntiTamperPackage.SetupDatabase(Conn) then
      begin
        Log('❌ 创建/校验数据表失败');
        Exit;
      end;
      
      Log('✓ 数据库表结构准备完成');
      
      // 播种每个图像
      SuccessCount := 0;
      FailCount := 0;
      for I := 0 to FImageFiles.Count - 1 do
      begin
        if SeedImage(Conn, FImageFiles.ValueFromIndex[I]) then
          Inc(SuccessCount)
        else
          Inc(FailCount);
      end;
      
      Log('===== 播种完成 =====');
      Log(Format('成功：%d，失败：%d', [SuccessCount, FailCount]));
      
      if FailCount = 0 then
        MessageDlg('所有图像播种成功！', mtInformation, [mbOK], 0)
      else
        MessageDlg(Format('播种完成：成功 %d 个，失败 %d 个', [SuccessCount, FailCount]), 
          mtWarning, [mbOK], 0);
          
    finally
      Conn.Free;
    end;
    
  finally
    Screen.Cursor := crDefault;
    btnSeed.Enabled := True;
  end;
end;

procedure TfrmSeedMain.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmSeedMain.Log(const Msg: string);
begin
  memoLog.Lines.Add(Format('[%s] %s', [FormatDateTime('hh:nn:ss', Now), Msg]));
  Application.ProcessMessages;
end;

function TfrmSeedMain.ValidateInputs: Boolean;
begin
  Result := False;
  
  if Trim(edtPassword.Text) = '' then
  begin
    MessageDlg('请输入管理员密码！', mtWarning, [mbOK], 0);
    edtPassword.SetFocus;
    Exit;
  end;
  
  if Length(edtPassword.Text) < 8 then
  begin
    MessageDlg('密码长度不能少于8位！', mtWarning, [mbOK], 0);
    edtPassword.SetFocus;
    Exit;
  end;
  
  if FImageFiles.Count = 0 then
  begin
    MessageDlg('请至少添加一个图像文件！', mtWarning, [mbOK], 0);
    Exit;
  end;
  
  Result := True;
end;

function TfrmSeedMain.ConnectDatabase: TFDConnection;
var
  DbPath: string;
begin
  Result := nil;
  
  DbPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'MoveC.db');
  
  try
    Result := TFDConnection.Create(nil);
    Result.DriverName := 'SQLite';
    Result.Params.Values['Database'] := DbPath;
    Result.LoginPrompt := False;
    Result.Connected := True;
    
    Log('✓ 已连接数据库: ' + DbPath);
  except
    on E: Exception do
    begin
      Log('❌ 数据库连接失败: ' + E.Message);
      if Assigned(Result) then
        FreeAndNil(Result);
    end;
  end;
end;

function TfrmSeedMain.SeedImage(AConn: TFDConnection; const AImagePath: string): Boolean;
var
  ImageData: TBytes;
  ImageKey: string;
  MS: TMemoryStream;
begin
  Result := False;
  ImageKey := TPath.GetFileNameWithoutExtension(AImagePath);
  
  try
    Log(Format('播种图像: %s', [ImageKey]));
    
    // 读取图像文件
    if not TFile.Exists(AImagePath) then
    begin
      Log(Format('  ❌ 文件不存在: %s', [AImagePath]));
      Exit;
    end;
    
    MS := TMemoryStream.Create;
    try
      MS.LoadFromFile(AImagePath);
      SetLength(ImageData, MS.Size);
      MS.Position := 0;
      MS.Read(ImageData[0], MS.Size);
      
      Log(Format('  读取文件: %d 字节', [Length(ImageData)]));
      
      // 使用 TAntiTamperPackage.SaveSecureImage 加密并保存
      // 注意：这里会使用派生密钥加密，并计算 SHA-256 + HMAC
      try
        if TAntiTamperPackage.SaveSecureImage(AConn, ImageKey, ImageData, '', 'Seeded by SeedTool') then
        begin
          Log(Format('  ✓ 播种成功: %s', [ImageKey]));
          Result := True;
        end
        else
        begin
          Log(Format('  ❌ 播种失败: %s （SaveSecureImage 返回 False，检查 antitamper_debug.log）', [ImageKey]));
        end;
      except
        on E: Exception do
        begin
          Log(Format('  ❌ SaveSecureImage 抛出异常: %s - %s', [ImageKey, E.Message]));
        end;
      end;
      
    finally
      MS.Free;
    end;
    
  except
    on E: Exception do
    begin
      Log(Format('  ❌ 异常: %s - %s', [ImageKey, E.Message]));
    end;
  end;
end;

procedure TfrmSeedMain.UpdateImageCount;
begin
  lblImageCount.Caption := Format('已添加 %d 个图像', [FImageFiles.Count]);
  btnSeed.Enabled := (FImageFiles.Count > 0) and (Trim(edtPassword.Text) <> '');
end;

end.

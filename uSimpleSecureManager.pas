unit uSimpleSecureManager;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, Vcl.Forms, Vcl.Dialogs,
  System.NetEncoding, System.Hash, Winapi.ShellAPI,
  uBasicProtection, uSimpleSQLiteDB;

type
  TSimpleSecureManager = class
  private
    FOwner: TComponent;
    FDatabase: TSimpleSQLiteDatabase;
    FPassword: string;
    
    function GetDatabasePath: string;
    procedure LogError(const AMessage: string);
    procedure LogInfo(const AMessage: string);
    
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;
    
    // 核心验证方法
    function LoadAndVerify(AFrameAboutMe: TObject): Boolean;
    
    // 篡改处理
    procedure ShowTamperAlertAndRedirect(const ARedirectURL: string = 'http://www.goodmem.cn');
    
    // 图像和文本加载
    function LoadImageData(const AImageKey: string; out AImageData: TBytes): Boolean;
    function LoadTextData(const ATextKey: string; out ATextData: string): Boolean;
    
    // 属性
    property Database: TSimpleSQLiteDatabase read FDatabase;
  end;

implementation

constructor TSimpleSecureManager.Create(AOwner: TComponent);
begin
  inherited Create;
  FOwner := AOwner;
  FPassword := '@2241114';
  
  LogInfo('简化安全管理器初始化完成');
end;

destructor TSimpleSecureManager.Destroy;
begin
  if Assigned(FDatabase) then
    FDatabase.Free;
  inherited;
end;

function TSimpleSecureManager.GetDatabasePath: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'data.db');
end;

function TSimpleSecureManager.LoadAndVerify(AFrameAboutMe: TObject): Boolean;
var
  DatabasePath: string;
begin
  Result := False;
  
  try
    LogInfo('开始加载并验证AboutMe数据');
    
    DatabasePath := GetDatabasePath;
    
    // 检查数据库文件是否存在
    if not TFile.Exists(DatabasePath) then
    begin
      LogError('数据库文件不存在: ' + DatabasePath);
      ShowTamperAlertAndRedirect;
      Exit;
    end;
    
    // 初始化数据库
    if Assigned(FDatabase) then
      FDatabase.Free;
      
    FDatabase := TSimpleSQLiteDatabase.Create(DatabasePath, FPassword);
    
    if not FDatabase.Connect then
    begin
      LogError('无法连接到数据库');
      ShowTamperAlertAndRedirect;
      Exit;
    end;
    
    // 简单验证 - 检查是否有数据
    if not FDatabase.ValidateAllData then
    begin
      LogError('数据验证失败');
      ShowTamperAlertAndRedirect;
      Exit;
    end;
    
    Result := True;
    LogInfo('AboutMe数据加载和验证完成 - 所有安全检查通过');
    
  except
    on E: Exception do
    begin
      LogError('加载AboutMe数据时发生异常: ' + E.Message);
      ShowTamperAlertAndRedirect;
      Result := False;
    end;
  end;
end;

function TSimpleSecureManager.LoadImageData(const AImageKey: string; out AImageData: TBytes): Boolean;
begin
  Result := False;
  SetLength(AImageData, 0);
  
  if Assigned(FDatabase) then
    Result := FDatabase.LoadImageData(AImageKey, AImageData);
end;

function TSimpleSecureManager.LoadTextData(const ATextKey: string; out ATextData: string): Boolean;
begin
  Result := False;
  ATextData := '';
  
  if Assigned(FDatabase) then
    Result := FDatabase.LoadTextData(ATextKey, ATextData);
end;

procedure TSimpleSecureManager.ShowTamperAlertAndRedirect(const ARedirectURL: string = 'http://www.goodmem.cn');
var
  AlertMessage: string;
begin
  AlertMessage := '检测到程序数据可能被篡改或损坏！' + sLineBreak + sLineBreak +
                  '为了您的安全，程序将退出。' + sLineBreak +
                  '请访问官方网站下载正版软件：' + sLineBreak + sLineBreak +
                  ARedirectURL + sLineBreak + sLineBreak +
                  '点击"确定"将自动打开官方网站。';
  
  if MessageBox(0, PChar(AlertMessage), PChar('安全警告'), MB_OK or MB_ICONWARNING) = IDOK then
  begin
    try
      ShellExecute(0, 'open', PChar(ARedirectURL), nil, nil, SW_SHOWNORMAL);
    except
      // 忽略打开浏览器的错误
    end;
  end;
  
  // 强制退出程序
  if Assigned(Application) then
    Application.Terminate
  else
    ExitProcess(1);
end;

procedure TSimpleSecureManager.LogError(const AMessage: string);
begin
  OutputDebugString(PChar('[ERROR] SimpleSecureManager: ' + AMessage));
end;

procedure TSimpleSecureManager.LogInfo(const AMessage: string);
begin
  OutputDebugString(PChar('[INFO] SimpleSecureManager: ' + AMessage));
end;

end.

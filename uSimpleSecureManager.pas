unit uSimpleSecureManager;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, FrameAboutMe;

type
  TSimpleSecureManager = class
  private
    FOwner: TComponent;
    FVerified: Boolean;
    
  public
    constructor Create(AOwner: TComponent);
    destructor Destroy; override;
    
    // 主要方法
    function LoadAndVerify(AFrameAboutMe: TFrameAboutMe): Boolean;
    procedure ShowTamperAlertAndRedirect(const AURL: string);
    
    // 属性
    property Verified: Boolean read FVerified;
  end;

implementation

uses
  Winapi.Windows, Winapi.ShellAPI, Vcl.Dialogs, System.IOUtils, Data.DB, FireDAC.Comp.Client;

constructor TSimpleSecureManager.Create(AOwner: TComponent);
begin
  inherited Create;
  FOwner := AOwner;
  FVerified := False;
end;

destructor TSimpleSecureManager.Destroy;
begin
  inherited;
end;

function TSimpleSecureManager.LoadAndVerify(AFrameAboutMe: TFrameAboutMe): Boolean;
var
  DbPath: string;
  Conn: TFDConnection;
  Q: TFDQuery;
  Cnt: Integer;
  function RequireKeyExists(const Key: string): Boolean;
  begin
    Result := False;
    Q.SQL.Text := 'SELECT COUNT(*) FROM images WHERE image_key = :k';
    Q.ParamByName('k').AsString := Key;
    Q.Open;
    try
      Result := Q.Fields[0].AsInteger > 0;
    finally
      Q.Close;
    end;
  end;
begin
  Result := False;
  try
    OutputDebugString(PChar('SimpleSecureManager: 开始验证'));

    if not Assigned(AFrameAboutMe) then
    begin
      OutputDebugString(PChar('SimpleSecureManager: FrameAboutMe未分配'));
      Exit;
    end;

    // 1) 数据库存在性检查（强制 fail-closed）
    DbPath := AFrameAboutMe.FDConnection1.Params.Values['Database'];
    if DbPath = '' then
      DbPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'MoveC.db');

    if not TFile.Exists(DbPath) then
    begin
      OutputDebugString(PChar('SimpleSecureManager: MoveC.db 缺失 - 触发防护'));
      Exit; // 返回 False，主程序将终止
    end;

    // 2) 连接与表记录校验
    Conn := AFrameAboutMe.FDConnection1;
    if not Conn.Connected then
    begin
      try
        Conn.Connected := True;
      except
        on E: Exception do
        begin
          OutputDebugString(PChar('SimpleSecureManager: 连接数据库失败 - ' + E.Message));
          Exit;
        end;
      end;
    end;

    Q := TFDQuery.Create(nil);
    try
      Q.Connection := Conn;
      Q.SQL.Text := 'SELECT COUNT(*) FROM sqlite_master WHERE type=''table'' AND name=''images''';
      Q.Open;
      try
        if (Q.Fields[0].AsInteger = 0) then
        begin
          OutputDebugString(PChar('SimpleSecureManager: 缺少 images 表'));
          Exit;
        end;
      finally
        Q.Close;
      end;

      Q.SQL.Text := 'SELECT COUNT(*) FROM images';
      Q.Open;
      try
        Cnt := Q.Fields[0].AsInteger;
        if Cnt < 3 then
        begin
          OutputDebugString(PChar('SimpleSecureManager: images 记录数过少: ' + IntToStr(Cnt)));
          Exit;
        end;
      finally
        Q.Close;
      end;

      // 3) 关键键存在性（提高篡改成本）
      if not (RequireKeyExists('wechat') and RequireKeyExists('alipay') and RequireKeyExists('btc')) then
      begin
        OutputDebugString(PChar('SimpleSecureManager: 关键记录缺失'));
        Exit;
      end;
    finally
      Q.Free;
    end;

    // 通过基础校验
    FVerified := True;
    Result := True;
    OutputDebugString(PChar('SimpleSecureManager: 验证通过'));
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('SimpleSecureManager: 验证异常 - ' + E.Message));
      FVerified := False;
      Result := False;
    end;
  end;
end;

procedure TSimpleSecureManager.ShowTamperAlertAndRedirect(const AURL: string);
begin
  try
    MessageBox(0,
      PChar('检测到程序文件可能被篡改！' + #13#10 +
            '为了您的安全，建议从官方网站重新下载。' + #13#10 + #13#10 +
            '即将打开官方网站...'),
      PChar('安全警告'),
      MB_OK or MB_ICONWARNING);

    if AURL <> '' then
      ShellExecute(0, 'open', PChar(AURL), nil, nil, SW_SHOWNORMAL);
  except
    on E: Exception do
      OutputDebugString(PChar('SimpleSecureManager: 显示警告失败 - ' + E.Message));
  end;
end;

end.

unit TestSecurity;

interface

uses
  SysUtils, Classes, IOUtils, Dialogs, Forms;

type
  TTestSecurityManager = class
  private
    FPassword: string;
    procedure LogInfo(const AMessage: string);
    procedure LogError(const AMessage: string);
  public
    constructor Create;
    function LoadAndVerify: Boolean;
    procedure ShowTamperAlert;
    function LoadImageData(const AImageKey: string; out AImageData: TBytes): Boolean;
    function LoadTextData(const ATextKey: string; out ATextData: string): Boolean;
  end;

implementation

constructor TTestSecurityManager.Create;
begin
  inherited;
  FPassword := '@2241114';
  LogInfo('测试安全管理器初始化完成');
end;

function TTestSecurityManager.LoadAndVerify: Boolean;
var
  DatabasePath: string;
begin
  Result := False;
  
  try
    LogInfo('开始验证数据');
    
    DatabasePath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'data.db');
    
    // 简单检查：如果数据库文件存在且大小>0，认为验证通过
    if TFile.Exists(DatabasePath) and (TFile.GetSize(DatabasePath) > 0) then
    begin
      Result := True;
      LogInfo('数据验证通过');
    end
    else
    begin
      LogError('数据验证失败 - 文件不存在或为空');
      ShowTamperAlert;
    end;
    
  except
    on E: Exception do
    begin
      LogError('验证过程发生异常: ' + E.Message);
      ShowTamperAlert;
    end;
  end;
end;

function TTestSecurityManager.LoadImageData(const AImageKey: string; out AImageData: TBytes): Boolean;
begin
  Result := False;
  SetLength(AImageData, 0);
  
  // 模拟成功加载
  if AImageKey <> '' then
  begin
    SetLength(AImageData, 100); // 假数据
    FillChar(AImageData[0], 100, $FF);
    Result := True;
    LogInfo('模拟加载图像: ' + AImageKey);
  end;
end;

function TTestSecurityManager.LoadTextData(const ATextKey: string; out ATextData: string): Boolean;
begin
  Result := False;
  ATextData := '';
  
  // 模拟成功加载
  if ATextKey <> '' then
  begin
    ATextData := '模拟文本数据: ' + ATextKey;
    Result := True;
    LogInfo('模拟加载文本: ' + ATextKey);
  end;
end;

procedure TTestSecurityManager.ShowTamperAlert;
begin
  ShowMessage('检测到程序数据异常！程序将退出。');
  if Assigned(Application) then
    Application.Terminate;
end;

procedure TTestSecurityManager.LogInfo(const AMessage: string);
begin
  // 简单输出到调试
  OutputDebugString(PChar('[INFO] TestSecurity: ' + AMessage));
end;

procedure TTestSecurityManager.LogError(const AMessage: string);
begin
  // 简单输出到调试
  OutputDebugString(PChar('[ERROR] TestSecurity: ' + AMessage));
end;

end.

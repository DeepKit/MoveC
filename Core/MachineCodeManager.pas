unit MachineCodeManager;

interface

uses
  System.SysUtils, System.Classes, Vcl.Clipbrd, SecurityManager, ConfigManager;

type
  // 机器码管理器类
  TMachineCodeManager = class
  private
    FSecurityManager: TSecurityManager;
    FConfigManager: TConfigManager;
    FMachineCode: string;
    FLastGeneratedTime: TDateTime;
    
    procedure GenerateMachineCode;
    function ValidateMachineCode(const ACode: string): Boolean;
    
  public
    constructor Create(ASecurityManager: TSecurityManager; AConfigManager: TConfigManager);
    destructor Destroy; override;
    
    // 获取机器码
    function GetMachineCode: string;
    function GetFormattedMachineCode: string;
    
    // 复制到剪贴板
    procedure CopyToClipboard;
    
    // 验证和稳定性检查
    function IsMachineCodeStable: Boolean;
    function GetMachineCodeInfo: string;
    
    // 属性
    property MachineCode: string read GetMachineCode;
    property LastGeneratedTime: TDateTime read FLastGeneratedTime;
  end;

implementation

uses
  Vcl.Dialogs, System.DateUtils;

constructor TMachineCodeManager.Create(ASecurityManager: TSecurityManager; AConfigManager: TConfigManager);
begin
  inherited Create;
  FSecurityManager := ASecurityManager;
  FConfigManager := AConfigManager;
  FMachineCode := '';
  FLastGeneratedTime := 0;
  
  // 初始化时生成机器码
  GenerateMachineCode;
end;

destructor TMachineCodeManager.Destroy;
begin
  // 不需要释放FSecurityManager和FConfigManager，它们由外部管理
  inherited;
end;

// 生成机器码
procedure TMachineCodeManager.GenerateMachineCode;
begin
  try
    if Assigned(FSecurityManager) then
    begin
      FMachineCode := FSecurityManager.GenerateMachineFingerprint;
      FLastGeneratedTime := Now;
      
      // 记录生成事件
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('MACHINE_CODE', 'Machine code generated', 
          '', '', 'SUCCESS', 'Code: ' + FMachineCode);
    end
    else
      raise Exception.Create('SecurityManager未初始化');
  except
    on E: Exception do
    begin
      FMachineCode := 'ERROR-GENE-RATE-CODE';
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('MACHINE_CODE', 'Machine code generation failed', 
          '', '', 'ERROR', E.Message);
    end;
  end;
end;

// 验证机器码格式
function TMachineCodeManager.ValidateMachineCode(const ACode: string): Boolean;
var
  Parts: TArray<string>;
  I, J: Integer;
begin
  Result := False;
  
  try
    // 检查格式：XXXX-XXXX-XXXX-XXXX
    if Length(ACode) <> 19 then // 16个字符 + 3个连字符
      Exit;
    
    Parts := ACode.Split(['-']);
    if Length(Parts) <> 4 then
      Exit;
    
    // 检查每个部分都是4个字符且都是字母数字
    for I := 0 to 3 do
    begin
      if Length(Parts[I]) <> 4 then
        Exit;
      
      for J := 1 to 4 do
      begin
        if not CharInSet(Parts[I][J], ['0'..'9', 'A'..'Z']) then
          Exit;
      end;
    end;
    
    Result := True;
  except
    Result := False;
  end;
end;

// 获取机器码
function TMachineCodeManager.GetMachineCode: string;
begin
  // 如果机器码为空或者生成时间过久，重新生成
  if (FMachineCode = '') or (SecondsBetween(Now, FLastGeneratedTime) > 3600) then
    GenerateMachineCode;
  
  Result := FMachineCode;
end;

// 获取格式化的机器码（用于显示）
function TMachineCodeManager.GetFormattedMachineCode: string;
var
  Code: string;
begin
  Code := GetMachineCode;
  
  if ValidateMachineCode(Code) then
    Result := Code
  else
    Result := 'INVALID-MACHINE-CODE';
end;

// 复制到剪贴板
procedure TMachineCodeManager.CopyToClipboard;
var
  Code: string;
begin
  try
    Code := GetMachineCode;
    
    if Code <> '' then
    begin
      Clipboard.AsText := Code;
      
      // 记录复制事件
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('MACHINE_CODE', 'Machine code copied to clipboard', 
          '', '', 'SUCCESS', 'Code: ' + Code);
      
      ShowMessage('机器码已复制到剪贴板：' + Code);
    end
    else
      ShowMessage('无法获取机器码');
  except
    on E: Exception do
    begin
      ShowMessage('复制机器码失败：' + E.Message);
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('MACHINE_CODE', 'Failed to copy machine code', 
          '', '', 'ERROR', E.Message);
    end;
  end;
end;

// 检查机器码稳定性
function TMachineCodeManager.IsMachineCodeStable: Boolean;
var
  Code1, Code2: string;
begin
  Result := False;
  
  try
    // 生成两次机器码，应该相同
    Code1 := GetMachineCode;
    Sleep(100); // 短暂延迟
    
    // 强制重新生成
    FMachineCode := '';
    Code2 := GetMachineCode;
    
    Result := (Code1 = Code2) and (Code1 <> '') and ValidateMachineCode(Code1);
    
    // 记录稳定性检查结果
    if Assigned(FConfigManager) then
    begin
      if Result then
        FConfigManager.LogOperation('MACHINE_CODE', 'Machine code stability check passed', 
          '', '', 'SUCCESS', 'Code: ' + Code1)
      else
        FConfigManager.LogOperation('MACHINE_CODE', 'Machine code stability check failed', 
          '', '', 'FAILED', 'Code1: ' + Code1 + ', Code2: ' + Code2);
    end;
  except
    on E: Exception do
    begin
      Result := False;
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('MACHINE_CODE', 'Machine code stability check error', 
          '', '', 'ERROR', E.Message);
    end;
  end;
end;

// 获取机器码详细信息
function TMachineCodeManager.GetMachineCodeInfo: string;
var
  Code: string;
  Info: TStringList;
begin
  Info := TStringList.Create;
  try
    Code := GetMachineCode;
    
    Info.Add('机器码信息：');
    Info.Add('─────────────────────────');
    Info.Add('机器码：' + Code);
    Info.Add('格式验证：' + BoolToStr(ValidateMachineCode(Code), True));
    Info.Add('生成时间：' + DateTimeToStr(FLastGeneratedTime));
    Info.Add('稳定性：' + BoolToStr(IsMachineCodeStable, True));
    Info.Add('─────────────────────────');
    Info.Add('说明：此机器码基于硬件信息生成，');
    Info.Add('用于技术支持和软件授权验证。');
    
    Result := Info.Text;
  finally
    Info.Free;
  end;
end;

end.
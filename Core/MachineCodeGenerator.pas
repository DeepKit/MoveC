unit MachineCodeGenerator;

interface

uses
  System.SysUtils, System.Classes, DataTypes, ConfigManager;

type
  TMachineCodeGenerator = class
  private
    FConfigManager: TConfigManager;
    
    function GetCPUInfo: string;
    function GetDiskInfo: string;
    function GetSystemInfo: string;
    function GetNetworkInfo: string;
    
  public
    constructor Create(AConfigManager: TConfigManager = nil);
    destructor Destroy; override;
    
    function GenerateMachineCode: string;
    function GetHardwareFingerprint: string;
    function ValidateMachineCode(const AMachineCode: string): Boolean;
  end;

implementation

uses
  System.Hash, Winapi.Windows, System.Win.Registry;

constructor TMachineCodeGenerator.Create(AConfigManager: TConfigManager);
begin
  inherited Create;
  
  if Assigned(AConfigManager) then
    FConfigManager := AConfigManager
  else
    FConfigManager := TConfigManager.Create;
end;

destructor TMachineCodeGenerator.Destroy;
begin
  if Assigned(FConfigManager) then
    FConfigManager.Free;
    
  inherited;
end;

function TMachineCodeGenerator.GetCPUInfo: string;
var
  Reg: TRegistry;
begin
  Result := 'CPU_INFO';
  
  try
    Reg := TRegistry.Create(KEY_READ);
    try
      Reg.RootKey := HKEY_LOCAL_MACHINE;
      if Reg.OpenKeyReadOnly('HARDWARE\DESCRIPTION\System\CentralProcessor\0') then
      begin
        if Reg.ValueExists('ProcessorNameString') then
          Result := Reg.ReadString('ProcessorNameString');
        Reg.CloseKey;
      end;
    finally
      Reg.Free;
    end;
  except
    Result := 'CPU_UNKNOWN';
  end;
end;

function TMachineCodeGenerator.GetDiskInfo: string;
var
  VolumeSerialNumber: DWORD;
begin
  Result := 'DISK_INFO';
  
  try
    if GetVolumeInformation('C:\', nil, 0, @VolumeSerialNumber, nil, nil, nil, 0) then
      Result := IntToHex(VolumeSerialNumber, 8);
  except
    Result := 'DISK_UNKNOWN';
  end;
end;

function TMachineCodeGenerator.GetSystemInfo: string;
var
  ComputerName: array[0..MAX_COMPUTERNAME_LENGTH] of Char;
  Size: DWORD;
begin
  Result := 'SYSTEM_INFO';
  
  try
    Size := SizeOf(ComputerName);
    if GetComputerName(ComputerName, Size) then
      Result := ComputerName;
  except
    Result := 'SYSTEM_UNKNOWN';
  end;
end;

function TMachineCodeGenerator.GetNetworkInfo: string;
begin
  Result := 'NETWORK_INFO'; // 简化实现
end;

function TMachineCodeGenerator.GenerateMachineCode: string;
var
  HardwareInfo: string;
  Hash: THashSHA256;
begin
  try
    HardwareInfo := GetCPUInfo + '|' + GetDiskInfo + '|' + GetSystemInfo + '|' + GetNetworkInfo;
    
    Hash := THashSHA256.Create;
    Hash.Update(HardwareInfo);
    Result := Hash.HashAsString;
    
    if Assigned(FConfigManager) then
      FConfigManager.LogOperation('MACHINE_CODE', 'Machine code generated', '', '', 'SUCCESS', 
        'Length: ' + IntToStr(Length(Result)));
    
  except
    on E: Exception do
    begin
      Result := '';
      if Assigned(FConfigManager) then
        FConfigManager.LogOperation('MACHINE_CODE', 'Generation error', '', '', 'ERROR', E.Message);
    end;
  end;
end;

function TMachineCodeGenerator.GetHardwareFingerprint: string;
begin
  Result := GenerateMachineCode;
end;

function TMachineCodeGenerator.ValidateMachineCode(const AMachineCode: string): Boolean;
var
  CurrentCode: string;
begin
  CurrentCode := GenerateMachineCode;
  Result := SameText(CurrentCode, AMachineCode);
end;

end.
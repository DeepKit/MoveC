unit EmergencyRecovery;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DataTypes, ConfigManager, 
  BackupManager, RollbackExecutor;

type
  // 紧急恢复系统
  TEmergencyRecovery = class
  private
    FConfigManager: TConfigManager;
    FBackupManager: TBackupManager;
    FRollbackExecutor: TRollbackExecutor;
    
  public
    constructor Create(AConfigManager: TConfigManager = nil);
    destructor Destroy; override;
    
    function CreateEmergencyScript(const ABackupId: string): string;
    function CreateRecoveryUSB(const ABackupId, AUSBPath: string): Boolean;
    function ValidateRecoveryEnvironment: Boolean;
    function ExecuteEmergencyRecovery(const ABackupId: string): Boolean;
  end;

implementation

constructor TEmergencyRecovery.Create(AConfigManager: TConfigManager);
begin
  inherited Create;
  
  if Assigned(AConfigManager) then
    FConfigManager := AConfigManager
  else
    FConfigManager := TConfigManager.Create;
    
  FBackupManager := TBackupManager.Create(FConfigManager);
  FRollbackExecutor := TRollbackExecutor.Create(FConfigManager);
end;

destructor TEmergencyRecovery.Destroy;
begin
  FRollbackExecutor.Free;
  FBackupManager.Free;
  
  if Assigned(FConfigManager) then
    FConfigManager.Free;
    
  inherited;
end;

function TEmergencyRecovery.CreateEmergencyScript(const ABackupId: string): string;
var
  Plan: TRollbackPlan;
begin
  Result := '';
  
  try
    Plan := FRollbackExecutor.CreateRollbackPlan(ABackupId);
    if Plan.TotalOperations > 0 then
      Result := FRollbackExecutor.GenerateRollbackScript(Plan);
  except
    Result := '';
  end;
end;

function TEmergencyRecovery.CreateRecoveryUSB(const ABackupId, AUSBPath: string): Boolean;
var
  RecoveryDir: string;
  ScriptContent: string;
begin
  Result := False;
  
  try
    if not TDirectory.Exists(AUSBPath) then
      Exit;
    
    RecoveryDir := TPath.Combine(AUSBPath, 'DiskCleanup_Recovery');
    TDirectory.CreateDirectory(RecoveryDir);
    
    // 创建恢复脚本
    ScriptContent := CreateEmergencyScript(ABackupId);
    if Length(ScriptContent) > 0 then
    begin
      TFile.WriteAllText(TPath.Combine(RecoveryDir, 'emergency_recovery.bat'), ScriptContent);
      Result := True;
    end;
    
  except
    Result := False;
  end;
end;

function TEmergencyRecovery.ValidateRecoveryEnvironment: Boolean;
begin
  Result := True; // 简化实现
end;

function TEmergencyRecovery.ExecuteEmergencyRecovery(const ABackupId: string): Boolean;
var
  Plan: TRollbackPlan;
begin
  Result := False;
  
  try
    if not ValidateRecoveryEnvironment then
      Exit;
    
    Plan := FRollbackExecutor.CreateRollbackPlan(ABackupId);
    if Plan.TotalOperations > 0 then
      Result := FRollbackExecutor.ExecuteRollback(Plan);
    
  except
    Result := False;
  end;
end;

end.
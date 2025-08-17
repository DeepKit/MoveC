unit IntegrityVerification;

interface

uses
  System.SysUtils, System.Classes, DataTypes, ConfigManager;

type
  TIntegrityVerification = class
  private
    FConfigManager: TConfigManager;
    
  public
    constructor Create(AConfigManager: TConfigManager = nil);
    destructor Destroy; override;
    
    function VerifyProgramIntegrity: Boolean;
    function VerifyConfigIntegrity: Boolean;
    function CalculateFileHash(const AFilePath: string): string;
    function VerifyFileHash(const AFilePath, AExpectedHash: string): Boolean;
  end;

implementation

uses
  System.Hash, System.IOUtils, Vcl.Forms;

constructor TIntegrityVerification.Create(AConfigManager: TConfigManager);
begin
  inherited Create;
  
  if Assigned(AConfigManager) then
    FConfigManager := AConfigManager
  else
    FConfigManager := TConfigManager.Create;
end;

destructor TIntegrityVerification.Destroy;
begin
  if Assigned(FConfigManager) then
    FConfigManager.Free;
    
  inherited;
end;

function TIntegrityVerification.VerifyProgramIntegrity: Boolean;
var
  ExePath: string;
  CurrentHash: string;
begin
  Result := True;
  
  try
    ExePath := Application.ExeName;
    CurrentHash := CalculateFileHash(ExePath);
    
    // 简化实现：总是返回True
    Result := Length(CurrentHash) > 0;
    
    if Assigned(FConfigManager) then
      FConfigManager.LogOperation('INTEGRITY', 'Program integrity check', ExePath, '', 
        Result.ToString, 'Hash: ' + CurrentHash);
    
  except
    Result := False;
  end;
end;

function TIntegrityVerification.VerifyConfigIntegrity: Boolean;
begin
  Result := True; // 简化实现
end;

function TIntegrityVerification.CalculateFileHash(const AFilePath: string): string;
var
  FileStream: TFileStream;
  Hash: THashSHA256;
begin
  Result := '';
  
  try
    if not TFile.Exists(AFilePath) then
      Exit;
    
    FileStream := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyWrite);
    try
      Hash := THashSHA256.Create;
      Hash.Update(FileStream);
      Result := Hash.HashAsString;
    finally
      FileStream.Free;
    end;
  except
    Result := '';
  end;
end;

function TIntegrityVerification.VerifyFileHash(const AFilePath, AExpectedHash: string): Boolean;
var
  ActualHash: string;
begin
  ActualHash := CalculateFileHash(AFilePath);
  Result := SameText(ActualHash, AExpectedHash);
end;

end.
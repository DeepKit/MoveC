unit ModelConfig;

interface

uses
  System.Classes, System.SysUtils, System.IniFiles;

type
  TConfigManager = class
  private
    FConfigFile: string;
    FIniFile: TIniFile;
  public
    constructor Create(const AConfigFile: string);
    destructor Destroy; override;
    
    function GetSourcePath: string;
    procedure SetSourcePath(const APath: string);
    function GetTargetPath: string;
    procedure SetTargetPath(const APath: string);
    
    function GetLastAnalysisPath: string;
    procedure SetLastAnalysisPath(const APath: string);
    
    procedure SaveSettings;
    procedure LoadSettings;
  end;

implementation

constructor TConfigManager.Create(const AConfigFile: string);
begin
  inherited Create;
  FConfigFile := AConfigFile;
  FIniFile := TIniFile.Create(FConfigFile);
  LoadSettings;
end;

destructor TConfigManager.Destroy;
begin
  SaveSettings;
  FIniFile.Free;
  inherited Destroy;
end;

function TConfigManager.GetSourcePath: string;
begin
  Result := FIniFile.ReadString('Paths', 'Source', '');
end;

procedure TConfigManager.SetSourcePath(const APath: string);
begin
  FIniFile.WriteString('Paths', 'Source', APath);
end;

function TConfigManager.GetTargetPath: string;
begin
  Result := FIniFile.ReadString('Paths', 'Target', '');
end;

procedure TConfigManager.SetTargetPath(const APath: string);
begin
  FIniFile.WriteString('Paths', 'Target', APath);
end;

function TConfigManager.GetLastAnalysisPath: string;
begin
  Result := FIniFile.ReadString('Analysis', 'LastPath', '');
end;

procedure TConfigManager.SetLastAnalysisPath(const APath: string);
begin
  FIniFile.WriteString('Analysis', 'LastPath', APath);
end;

procedure TConfigManager.SaveSettings;
begin
  if Assigned(FIniFile) then
    FIniFile.UpdateFile;
end;

procedure TConfigManager.LoadSettings;
begin
  // 配置已在读取时自动加载
end;

end.

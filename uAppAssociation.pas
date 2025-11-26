unit uAppAssociation;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.IOUtils, Winapi.Windows, System.Win.Registry;

type
  // 应用程序信息
  TAppInfo = record
    AppName: string;        // 应用程序名称
    AppPath: string;        // 应用程序路径
    IconPath: string;       // 图标路径
    Confidence: Integer;    // 置信度 (0-100)
    Reason: string;         // 关联原因
  end;

  // 应用程序关联检测器
  TAppAssociationDetector = class
  private
    FKnownApps: TDictionary<string, TAppInfo>;
    
    procedure InitializeKnownApps;
    function CheckRegistryAssociation(const APath: string): TAppInfo;
    function CheckCommonPaths(const APath: string): TAppInfo;
    function CheckByPathPattern(const APath: string): TAppInfo;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 检测目录关联的应用程序
    function DetectAssociatedApp(const ADirectoryPath: string): TAppInfo;
    
    // 获取建议的测试说明
    function GetTestSuggestion(const AAppInfo: TAppInfo): string;
  end;

implementation

{ TAppAssociationDetector }

constructor TAppAssociationDetector.Create;
begin
  inherited;
  FKnownApps := TDictionary<string, TAppInfo>.Create;
  InitializeKnownApps;
end;

destructor TAppAssociationDetector.Destroy;
begin
  FKnownApps.Free;
  inherited;
end;

procedure TAppAssociationDetector.InitializeKnownApps;
var
  AppInfo: TAppInfo;
begin
  // Documents - Office
  AppInfo.AppName := 'Microsoft Office';
  AppInfo.Reason := '常用文档目录';
  AppInfo.Confidence := 80;
  FKnownApps.Add('Documents', AppInfo);
  FKnownApps.Add('我的文档', AppInfo);
  
  // Downloads
  AppInfo.AppName := '浏览器下载';
  AppInfo.Reason := '浏览器默认下载目录';
  AppInfo.Confidence := 90;
  FKnownApps.Add('Downloads', AppInfo);
  FKnownApps.Add('下载', AppInfo);
  
  // Desktop
  AppInfo.AppName := 'Windows桌面';
  AppInfo.Reason := '系统桌面目录';
  AppInfo.Confidence := 100;
  FKnownApps.Add('Desktop', AppInfo);
  FKnownApps.Add('桌面', AppInfo);
  
  // Pictures
  AppInfo.AppName := '照片查看器';
  AppInfo.Reason := '图片存储目录';
  AppInfo.Confidence := 80;
  FKnownApps.Add('Pictures', AppInfo);
  FKnownApps.Add('图片', AppInfo);
  
  // Videos
  AppInfo.AppName := '视频播放器';
  AppInfo.Reason := '视频存储目录';
  AppInfo.Confidence := 80;
  FKnownApps.Add('Videos', AppInfo);
  FKnownApps.Add('视频', AppInfo);
  
  // Music
  AppInfo.AppName := '音乐播放器';
  AppInfo.Reason := '音乐存储目录';
  AppInfo.Confidence := 80;
  FKnownApps.Add('Music', AppInfo);
  FKnownApps.Add('音乐', AppInfo);
  
  // Steam
  AppInfo.AppName := 'Steam';
  AppInfo.Reason := 'Steam游戏安装目录';
  AppInfo.Confidence := 95;
  FKnownApps.Add('Steam', AppInfo);
  
  // node_modules
  AppInfo.AppName := 'Node.js / npm';
  AppInfo.Reason := 'Node.js项目依赖目录';
  AppInfo.Confidence := 100;
  FKnownApps.Add('node_modules', AppInfo);
  
  // .gradle
  AppInfo.AppName := 'Android Studio / Gradle';
  AppInfo.Reason := 'Gradle构建缓存';
  AppInfo.Confidence := 95;
  FKnownApps.Add('.gradle', AppInfo);
  
  // .m2
  AppInfo.AppName := 'Maven';
  AppInfo.Reason := 'Maven本地仓库';
  AppInfo.Confidence := 95;
  FKnownApps.Add('.m2', AppInfo);
  
  // .vscode
  AppInfo.AppName := 'Visual Studio Code';
  AppInfo.Reason := 'VS Code配置目录';
  AppInfo.Confidence := 90;
  FKnownApps.Add('.vscode', AppInfo);
end;

function TAppAssociationDetector.CheckByPathPattern(const APath: string): TAppInfo;
var
  DirName: string;
  Key: string;
begin
  Result.AppName := '';
  Result.Confidence := 0;
  
  // 提取目录名
  DirName := ExtractFileName(ExcludeTrailingPathDelimiter(APath));
  
  // 检查已知应用
  for Key in FKnownApps.Keys do
  begin
    if Pos(Key, DirName) > 0 then
    begin
      Result := FKnownApps[Key];
      Exit;
    end;
  end;
  
  // 检查常见模式
  if Pos('Game', DirName) > 0 then
  begin
    Result.AppName := '游戏';
    Result.Reason := '可能是游戏安装目录';
    Result.Confidence := 60;
  end
  else if Pos('Program', DirName) > 0 then
  begin
    Result.AppName := '应用程序';
    Result.Reason := '可能是程序安装目录';
    Result.Confidence := 50;
  end
  else if Pos('Cache', DirName) > 0 then
  begin
    Result.AppName := '缓存数据';
    Result.Reason := '缓存目录';
    Result.Confidence := 70;
  end
  else if Pos('Temp', DirName) > 0 then
  begin
    Result.AppName := '临时文件';
    Result.Reason := '临时目录';
    Result.Confidence := 80;
  end;
end;

function TAppAssociationDetector.CheckCommonPaths(const APath: string): TAppInfo;
var
  UserProfile: string;
begin
  Result.AppName := '';
  Result.Confidence := 0;
  
  UserProfile := GetEnvironmentVariable('USERPROFILE');
  
  // 检查是否在用户目录下
  if Pos(UserProfile, APath) = 1 then
  begin
    // AppData目录
    if Pos('AppData\Local', APath) > 0 then
    begin
      Result.AppName := '应用程序数据';
      Result.Reason := '应用程序本地数据目录';
      Result.Confidence := 70;
    end
    else if Pos('AppData\Roaming', APath) > 0 then
    begin
      Result.AppName := '应用程序配置';
      Result.Reason := '应用程序漫游配置目录';
      Result.Confidence := 70;
    end;
  end;
end;

function TAppAssociationDetector.CheckRegistryAssociation(const APath: string): TAppInfo;
var
  Reg: TRegistry;
  Keys: TStringList;
  I: Integer;
  InstallPath: string;
begin
  Result.AppName := '';
  Result.Confidence := 0;
  
  Reg := TRegistry.Create(KEY_READ);
  Keys := TStringList.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    
    // 检查已安装程序
    if Reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall') then
    begin
      Reg.GetKeyNames(Keys);
      for I := 0 to Keys.Count - 1 do
      begin
        if Reg.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\' + Keys[I]) then
        begin
          if Reg.ValueExists('InstallLocation') then
          begin
            InstallPath := Reg.ReadString('InstallLocation');
            if (InstallPath <> '') and (Pos(InstallPath, APath) = 1) then
            begin
              if Reg.ValueExists('DisplayName') then
              begin
                Result.AppName := Reg.ReadString('DisplayName');
                Result.Reason := '在注册表中找到关联';
                Result.Confidence := 90;
                
                if Reg.ValueExists('DisplayIcon') then
                  Result.IconPath := Reg.ReadString('DisplayIcon');
                
                Exit;
              end;
            end;
          end;
          Reg.CloseKey;
        end;
      end;
    end;
  finally
    Keys.Free;
    Reg.Free;
  end;
end;

function TAppAssociationDetector.DetectAssociatedApp(const ADirectoryPath: string): TAppInfo;
var
  TempResult: TAppInfo;
begin
  Result.AppName := '未知';
  Result.Reason := '';
  Result.Confidence := 0;
  Result.IconPath := '';
  
  // 1. 首先检查注册表
  TempResult := CheckRegistryAssociation(ADirectoryPath);
  if TempResult.Confidence > Result.Confidence then
    Result := TempResult;
  
  // 2. 检查路径模式
  TempResult := CheckByPathPattern(ADirectoryPath);
  if TempResult.Confidence > Result.Confidence then
    Result := TempResult;
  
  // 3. 检查常见路径
  TempResult := CheckCommonPaths(ADirectoryPath);
  if TempResult.Confidence > Result.Confidence then
    Result := TempResult;
  
  // 如果没有找到，给个默认值
  if Result.AppName = '未知' then
  begin
    Result.Reason := '无法自动检测，请手动测试';
    Result.Confidence := 0;
  end;
end;

function TAppAssociationDetector.GetTestSuggestion(const AAppInfo: TAppInfo): string;
begin
  if AAppInfo.Confidence = 0 then
  begin
    Result := '建议：迁移后请测试所有可能使用此目录的程序';
    Exit;
  end;
  
  case AAppInfo.Confidence of
    90..100:
      Result := Format('建议测试：%s（置信度：高）', [AAppInfo.AppName]);
    70..89:
      Result := Format('建议测试：%s（置信度：中）', [AAppInfo.AppName]);
    50..69:
      Result := Format('可能需要测试：%s（置信度：低）', [AAppInfo.AppName]);
  else
    Result := Format('建议测试：%s', [AAppInfo.AppName]);
  end;
  
  if AAppInfo.Reason <> '' then
    Result := Result + sLineBreak + '原因：' + AAppInfo.Reason;
end;

end.

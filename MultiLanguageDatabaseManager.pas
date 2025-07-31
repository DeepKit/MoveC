unit MultiLanguageDatabaseManager;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.IniFiles,
  System.Generics.Collections, Winapi.Windows, BasicProtection, DataTypes,
  MultiLanguageConstants;

type
  // 完整的多语言数据库管理器
  TMultiLanguageDatabaseManager = class
  private
    FDatabasePath: string;
    FIsInitialized: Boolean;
    FLanguageIni: TMemIniFile;
    FConfigIni: TMemIniFile;
    FCurrentLanguage: TLanguageCode;
    
    function GetDatabasePath: string;
    procedure InitializeAllLanguages;
    procedure InitializeLanguage(LanguageCode: TLanguageCode);
    function LanguageStringsFile: string;
    function ConfigSettingsFile: string;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    // 数据库初始化
    function Initialize: Boolean;
    procedure Finalize;
    
    // 语言管理
    function SetCurrentLanguage(LanguageCode: TLanguageCode): Boolean;
    function GetCurrentLanguage: TLanguageCode;
    function GetSupportedLanguages: TArray<TLanguageCode>;
    
    // 多语言字符串管理
    function SetLanguageString(const LanguageCode: TLanguageCode; const StringKey, StringValue: string): Boolean; overload;
    function SetLanguageString(const LanguageCodeStr, StringKey, StringValue: string): Boolean; overload;
    function GetLanguageString(const LanguageCode: TLanguageCode; const StringKey: string; const DefaultValue: string = ''): string; overload;
    function GetLanguageString(const LanguageCodeStr, StringKey: string; const DefaultValue: string = ''): string; overload;
    function GetCurrentLanguageString(const StringKey: string; const DefaultValue: string = ''): string;
    
    // 配置管理
    function SetConfig(const Category, Key, Value: string): Boolean;
    function GetConfig(const Category, Key: string; const DefaultValue: string = ''): string;
    
    // 语言窗口专用方法
    function GetLanguageWindowTitle: string;
    function GetOKButtonText: string;
    function GetCancelButtonText: string;
    function GetLanguageChangedMessage: string;
    function GetAppTitle: string;
    
    // 属性
    property DatabasePath: string read FDatabasePath;
    property IsInitialized: Boolean read FIsInitialized;
    property CurrentLanguage: TLanguageCode read GetCurrentLanguage;
  end;

implementation

constructor TMultiLanguageDatabaseManager.Create;
begin
  inherited;
  FDatabasePath := '';
  FIsInitialized := False;
  FLanguageIni := nil;
  FConfigIni := nil;
  FCurrentLanguage := lcEnglish; // 默认英语
end;

destructor TMultiLanguageDatabaseManager.Destroy;
begin
  Finalize;
  inherited;
end;

function TMultiLanguageDatabaseManager.GetDatabasePath: string;
var
  AppDataPath: string;
begin
  AppDataPath := GetEnvironmentVariable('LOCALAPPDATA');
  if AppDataPath = '' then
    AppDataPath := TPath.Combine(GetEnvironmentVariable('USERPROFILE'), 'AppData\Local');
  Result := TPath.Combine(AppDataPath, 'DiskCleanup');
end;

function TMultiLanguageDatabaseManager.LanguageStringsFile: string;
begin
  Result := TPath.Combine(FDatabasePath, 'language_strings.ini');
end;

function TMultiLanguageDatabaseManager.ConfigSettingsFile: string;
begin
  Result := TPath.Combine(FDatabasePath, 'config_settings.ini');
end;

function TMultiLanguageDatabaseManager.Initialize: Boolean;
var
  SavedLanguage: string;
begin
  Result := False;
  try
    if FIsInitialized then
      Exit(True);
      
    FDatabasePath := GetDatabasePath;
    
    // 创建数据目录
    if not TDirectory.Exists(FDatabasePath) then
      TDirectory.CreateDirectory(FDatabasePath);
    
    // 初始化INI文件对象
    FLanguageIni := TMemIniFile.Create(LanguageStringsFile, TEncoding.UTF8);
    FConfigIni := TMemIniFile.Create(ConfigSettingsFile, TEncoding.UTF8);
    
    // 读取保存的语言设置
    SavedLanguage := GetConfig('app', 'current_language', 'en-US');
    FCurrentLanguage := GetLanguageCodeFromString(SavedLanguage);
    
    // 初始化所有语言
    InitializeAllLanguages;
    
    FIsInitialized := True;
    Result := True;
    
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('Multi-language database initialization failed: ' + E.Message));
      Finalize;
    end;
  end;
end;

procedure TMultiLanguageDatabaseManager.Finalize;
begin
  try
    if Assigned(FLanguageIni) then
    begin
      FLanguageIni.UpdateFile;
      FLanguageIni.Free;
      FLanguageIni := nil;
    end;
    
    if Assigned(FConfigIni) then
    begin
      FConfigIni.UpdateFile;
      FConfigIni.Free;
      FConfigIni := nil;
    end;
  except
    // 忽略错误
  end;
  
  FIsInitialized := False;
end;

procedure TMultiLanguageDatabaseManager.InitializeAllLanguages;
var
  Lang: TLanguageCode;
begin
  for Lang := Low(TLanguageCode) to High(TLanguageCode) do
  begin
    InitializeLanguage(Lang);
  end;
end;

procedure TMultiLanguageDatabaseManager.InitializeLanguage(LanguageCode: TLanguageCode);
var
  LangCode: string;
begin
  LangCode := GetLanguageCodeString(LanguageCode);
  
  // 强制初始化所有语言字符串（覆盖现有的）
  begin
    case LanguageCode of
      lcEnglish:
        begin
          SetLanguageString(LanguageCode, 'app_title', APP_TITLE_EN);
          SetLanguageString(LanguageCode, 'language_window_title', LANGUAGE_WINDOW_TITLE_EN);
          SetLanguageString(LanguageCode, 'btn_ok', BTN_OK_EN);
          SetLanguageString(LanguageCode, 'btn_cancel', BTN_CANCEL_EN);
          SetLanguageString(LanguageCode, 'language_changed', LANGUAGE_CHANGED_EN);
        end;
      lcChineseSimplified:
        begin
          SetLanguageString(LanguageCode, 'app_title', APP_TITLE_ZH_CN);
          SetLanguageString(LanguageCode, 'language_window_title', LANGUAGE_WINDOW_TITLE_ZH_CN);
          SetLanguageString(LanguageCode, 'btn_ok', BTN_OK_ZH_CN);
          SetLanguageString(LanguageCode, 'btn_cancel', BTN_CANCEL_ZH_CN);
          SetLanguageString(LanguageCode, 'language_changed', LANGUAGE_CHANGED_ZH_CN);
        end;
      lcChineseTraditional:
        begin
          SetLanguageString(LanguageCode, 'app_title', APP_TITLE_ZH_TW);
          SetLanguageString(LanguageCode, 'language_window_title', LANGUAGE_WINDOW_TITLE_ZH_TW);
          SetLanguageString(LanguageCode, 'btn_ok', BTN_OK_ZH_TW);
          SetLanguageString(LanguageCode, 'btn_cancel', BTN_CANCEL_ZH_TW);
          SetLanguageString(LanguageCode, 'language_changed', LANGUAGE_CHANGED_ZH_TW);
        end;
      lcJapanese:
        begin
          SetLanguageString(LanguageCode, 'app_title', APP_TITLE_JA);
          SetLanguageString(LanguageCode, 'language_window_title', LANGUAGE_WINDOW_TITLE_JA);
          SetLanguageString(LanguageCode, 'btn_ok', BTN_OK_JA);
          SetLanguageString(LanguageCode, 'btn_cancel', BTN_CANCEL_JA);
          SetLanguageString(LanguageCode, 'language_changed', LANGUAGE_CHANGED_JA);
        end;
      lcKorean:
        begin
          SetLanguageString(LanguageCode, 'app_title', APP_TITLE_KO);
          SetLanguageString(LanguageCode, 'language_window_title', LANGUAGE_WINDOW_TITLE_KO);
          SetLanguageString(LanguageCode, 'btn_ok', BTN_OK_KO);
          SetLanguageString(LanguageCode, 'btn_cancel', BTN_CANCEL_KO);
          SetLanguageString(LanguageCode, 'language_changed', LANGUAGE_CHANGED_KO);
        end;
      lcGerman:
        begin
          SetLanguageString(LanguageCode, 'app_title', APP_TITLE_DE);
          SetLanguageString(LanguageCode, 'language_window_title', LANGUAGE_WINDOW_TITLE_DE);
          SetLanguageString(LanguageCode, 'btn_ok', BTN_OK_DE);
          SetLanguageString(LanguageCode, 'btn_cancel', BTN_CANCEL_DE);
          SetLanguageString(LanguageCode, 'language_changed', 'Spracheinstellungen wurden ge' + #$00E4 + 'ndert. Einige Oberfl' + #$00E4 + 'chenelemente werden nach dem Neustart wirksam.');
        end;
      lcFrench:
        begin
          SetLanguageString(LanguageCode, 'app_title', APP_TITLE_FR);
          SetLanguageString(LanguageCode, 'language_window_title', LANGUAGE_WINDOW_TITLE_FR);
          SetLanguageString(LanguageCode, 'btn_ok', BTN_OK_FR);
          SetLanguageString(LanguageCode, 'btn_cancel', BTN_CANCEL_FR);
          SetLanguageString(LanguageCode, 'language_changed', 'Les param' + #$00E8 + 'tres de langue ont ' + #$00E9 + 't' + #$00E9 + ' modifi' + #$00E9 + 's. Certains ' + #$00E9 + 'l' + #$00E9 + 'ments d''interface prendront effet apr' + #$00E8 + 's le red' + #$00E9 + 'marrage.');
        end;
      lcSpanish:
        begin
          SetLanguageString(LanguageCode, 'app_title', APP_TITLE_ES);
          SetLanguageString(LanguageCode, 'language_window_title', LANGUAGE_WINDOW_TITLE_ES);
          SetLanguageString(LanguageCode, 'btn_ok', BTN_OK_ES);
          SetLanguageString(LanguageCode, 'btn_cancel', BTN_CANCEL_ES);
          SetLanguageString(LanguageCode, 'language_changed', 'La configuraci' + #$00F3 + 'n de idioma ha sido cambiada. Algunos elementos de la interfaz tendr' + #$00E1 + 'n efecto despu' + #$00E9 + 's del reinicio.');
        end;
      lcItalian:
        begin
          SetLanguageString(LanguageCode, 'app_title', APP_TITLE_IT);
          SetLanguageString(LanguageCode, 'language_window_title', LANGUAGE_WINDOW_TITLE_IT);
          SetLanguageString(LanguageCode, 'btn_ok', BTN_OK_IT);
          SetLanguageString(LanguageCode, 'btn_cancel', BTN_CANCEL_IT);
          SetLanguageString(LanguageCode, 'language_changed', 'Le impostazioni della lingua sono state modificate. Alcuni elementi dell''interfaccia avranno effetto dopo il riavvio.');
        end;
      lcPortuguese:
        begin
          SetLanguageString(LanguageCode, 'app_title', APP_TITLE_PT);
          SetLanguageString(LanguageCode, 'language_window_title', LANGUAGE_WINDOW_TITLE_PT);
          SetLanguageString(LanguageCode, 'btn_ok', BTN_OK_PT);
          SetLanguageString(LanguageCode, 'btn_cancel', BTN_CANCEL_PT);
          SetLanguageString(LanguageCode, 'language_changed', 'As configura' + #$00E7 + #$00F5 + 'es de idioma foram alteradas. Alguns elementos da interface ter' + #$00E3 + 'o efeito ap' + #$00F3 + 's a reinicializa' + #$00E7 + #$00E3 + 'o.');
        end;
      lcRussian:
        begin
          SetLanguageString(LanguageCode, 'app_title', APP_TITLE_RU);
          SetLanguageString(LanguageCode, 'language_window_title', LANGUAGE_WINDOW_TITLE_RU);
          SetLanguageString(LanguageCode, 'btn_ok', BTN_OK_RU);
          SetLanguageString(LanguageCode, 'btn_cancel', BTN_CANCEL_RU);
          SetLanguageString(LanguageCode, 'language_changed', #$041D#$0430#$0441#$0442#$0440#$043E#$0439#$043A#$0438#$0020#$044F#$0437#$044B#$043A#$0430#$0020#$0438#$0437#$043C#$0435#$043D#$0435#$043D#$044B#$002E#$0020#$041D#$0435#$043A#$043E#$0442#$043E#$0440#$044B#$0435#$0020#$044D#$043B#$0435#$043C#$0435#$043D#$0442#$044B#$0020#$0438#$043D#$0442#$0435#$0440#$0444#$0435#$0439#$0441#$0430#$0020#$0432#$0441#$0442#$0443#$043F#$044F#$0442#$0020#$0432#$0020#$0441#$0438#$043B#$0443#$0020#$043F#$043E#$0441#$043B#$0435#$0020#$043F#$0435#$0440#$0435#$0437#$0430#$043F#$0443#$0441#$043A#$0430#$002E);
        end;
      lcDutch:
        begin
          SetLanguageString(LanguageCode, 'app_title', APP_TITLE_NL);
          SetLanguageString(LanguageCode, 'language_window_title', LANGUAGE_WINDOW_TITLE_NL);
          SetLanguageString(LanguageCode, 'btn_ok', BTN_OK_NL);
          SetLanguageString(LanguageCode, 'btn_cancel', BTN_CANCEL_NL);
          SetLanguageString(LanguageCode, 'language_changed', 'Taalinstellingen zijn gewijzigd. Sommige interface-elementen worden van kracht na herstart.');
        end;
      lcSwedish:
        begin
          SetLanguageString(LanguageCode, 'app_title', APP_TITLE_SV);
          SetLanguageString(LanguageCode, 'language_window_title', LANGUAGE_WINDOW_TITLE_SV);
          SetLanguageString(LanguageCode, 'btn_ok', BTN_OK_SV);
          SetLanguageString(LanguageCode, 'btn_cancel', BTN_CANCEL_SV);
          SetLanguageString(LanguageCode, 'language_changed', 'Spr' + #$00E5 + 'kinst' + #$00E4 + 'llningar har ' + #$00E4 + 'ndrats. Vissa gr' + #$00E4 + 'nssnittselement tr' + #$00E4 + 'der i kraft efter omstart.');
        end;
      lcNorwegian:
        begin
          SetLanguageString(LanguageCode, 'app_title', APP_TITLE_NO);
          SetLanguageString(LanguageCode, 'language_window_title', LANGUAGE_WINDOW_TITLE_NO);
          SetLanguageString(LanguageCode, 'btn_ok', BTN_OK_NO);
          SetLanguageString(LanguageCode, 'btn_cancel', BTN_CANCEL_NO);
          SetLanguageString(LanguageCode, 'language_changed', 'Spr' + #$00E5 + 'kinnstillinger er endret. Noen grensesnittelementer vil tre i kraft etter omstart.');
        end;
      lcDanish:
        begin
          SetLanguageString(LanguageCode, 'app_title', APP_TITLE_DA);
          SetLanguageString(LanguageCode, 'language_window_title', LANGUAGE_WINDOW_TITLE_DA);
          SetLanguageString(LanguageCode, 'btn_ok', BTN_OK_DA);
          SetLanguageString(LanguageCode, 'btn_cancel', BTN_CANCEL_DA);
          SetLanguageString(LanguageCode, 'language_changed', 'Sprogindstillinger er blevet ' + #$00E6 + 'ndret. Nogle gr' + #$00E6 + 'nsefladeelementer tr' + #$00E6 + 'der i kraft efter genstart.');
        end;
      lcFinnish:
        begin
          SetLanguageString(LanguageCode, 'app_title', APP_TITLE_FI);
          SetLanguageString(LanguageCode, 'language_window_title', LANGUAGE_WINDOW_TITLE_FI);
          SetLanguageString(LanguageCode, 'btn_ok', BTN_OK_FI);
          SetLanguageString(LanguageCode, 'btn_cancel', BTN_CANCEL_FI);
          SetLanguageString(LanguageCode, 'language_changed', 'Kieliasetukset on muutettu. Jotkin k' + #$00E4 + 'ytt' + #$00F6 + 'liittym' + #$00E4 + 'n elementit tulevat voimaan uudelleenk' + #$00E4 + 'ynnistyksen j' + #$00E4 + 'lkeen.');
        end;
    end;
  end;
end;

// 设置当前语言
function TMultiLanguageDatabaseManager.SetCurrentLanguage(LanguageCode: TLanguageCode): Boolean;
begin
  Result := False;
  if not FIsInitialized then
    Exit;

  try
    FCurrentLanguage := LanguageCode;
    SetConfig('app', 'current_language', GetLanguageCodeString(LanguageCode));
    Result := True;
  except
    on E: Exception do
      OutputDebugString(PChar('SetCurrentLanguage failed: ' + E.Message));
  end;
end;

// 获取当前语言
function TMultiLanguageDatabaseManager.GetCurrentLanguage: TLanguageCode;
begin
  Result := FCurrentLanguage;
end;

// 获取支持的语言列表
function TMultiLanguageDatabaseManager.GetSupportedLanguages: TArray<TLanguageCode>;
var
  I: TLanguageCode;
  Languages: TArray<TLanguageCode>;
begin
  SetLength(Languages, Ord(High(TLanguageCode)) - Ord(Low(TLanguageCode)) + 1);
  for I := Low(TLanguageCode) to High(TLanguageCode) do
  begin
    Languages[Ord(I)] := I;
  end;
  Result := Languages;
end;

// 设置语言字符串（使用枚举）
function TMultiLanguageDatabaseManager.SetLanguageString(const LanguageCode: TLanguageCode; const StringKey, StringValue: string): Boolean;
begin
  Result := SetLanguageString(GetLanguageCodeString(LanguageCode), StringKey, StringValue);
end;

// 设置语言字符串（使用字符串）
function TMultiLanguageDatabaseManager.SetLanguageString(const LanguageCodeStr, StringKey, StringValue: string): Boolean;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FLanguageIni) then
    Exit;

  try
    FLanguageIni.WriteString(LanguageCodeStr, StringKey, StringValue);
    FLanguageIni.UpdateFile;
    Result := True;
  except
    on E: Exception do
      OutputDebugString(PChar('SetLanguageString failed: ' + E.Message));
  end;
end;

// 获取语言字符串（使用枚举）
function TMultiLanguageDatabaseManager.GetLanguageString(const LanguageCode: TLanguageCode; const StringKey: string; const DefaultValue: string = ''): string;
begin
  Result := GetLanguageString(GetLanguageCodeString(LanguageCode), StringKey, DefaultValue);
end;

// 获取语言字符串（使用字符串）
function TMultiLanguageDatabaseManager.GetLanguageString(const LanguageCodeStr, StringKey: string; const DefaultValue: string = ''): string;
begin
  Result := DefaultValue;
  if not FIsInitialized or not Assigned(FLanguageIni) then
    Exit;

  try
    Result := FLanguageIni.ReadString(LanguageCodeStr, StringKey, DefaultValue);
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('GetLanguageString failed: ' + E.Message));
      Result := DefaultValue;
    end;
  end;
end;

// 获取当前语言的字符串
function TMultiLanguageDatabaseManager.GetCurrentLanguageString(const StringKey: string; const DefaultValue: string = ''): string;
begin
  Result := GetLanguageString(FCurrentLanguage, StringKey, DefaultValue);
end;

// 设置配置
function TMultiLanguageDatabaseManager.SetConfig(const Category, Key, Value: string): Boolean;
begin
  Result := False;
  if not FIsInitialized or not Assigned(FConfigIni) then
    Exit;

  try
    FConfigIni.WriteString(Category, Key, Value);
    FConfigIni.UpdateFile;
    Result := True;
  except
    on E: Exception do
      OutputDebugString(PChar('SetConfig failed: ' + E.Message));
  end;
end;

// 获取配置
function TMultiLanguageDatabaseManager.GetConfig(const Category, Key: string; const DefaultValue: string = ''): string;
begin
  Result := DefaultValue;
  if not FIsInitialized or not Assigned(FConfigIni) then
    Exit;

  try
    Result := FConfigIni.ReadString(Category, Key, DefaultValue);
  except
    on E: Exception do
    begin
      OutputDebugString(PChar('GetConfig failed: ' + E.Message));
      Result := DefaultValue;
    end;
  end;
end;

// 语言窗口专用方法
function TMultiLanguageDatabaseManager.GetLanguageWindowTitle: string;
begin
  Result := GetCurrentLanguageString('language_window_title', 'Language Settings');
end;

function TMultiLanguageDatabaseManager.GetOKButtonText: string;
begin
  Result := GetCurrentLanguageString('btn_ok', 'OK');
end;

function TMultiLanguageDatabaseManager.GetCancelButtonText: string;
begin
  Result := GetCurrentLanguageString('btn_cancel', 'Cancel');
end;

function TMultiLanguageDatabaseManager.GetLanguageChangedMessage: string;
begin
  Result := GetCurrentLanguageString('language_changed', 'Language settings have been changed. Some interface elements will take effect after restart.');
end;

function TMultiLanguageDatabaseManager.GetAppTitle: string;
begin
  Result := GetCurrentLanguageString('app_title', 'C Drive Super Cleaner');
end;

end.

unit LanguageTypes;

interface

type
  // 支持的语言类型
  TLanguageType = (
    ltChinese,      // 中文
    ltEnglish,      // 英文
    ltJapanese,     // 日文
    ltKorean,       // 韩文
    ltGerman,       // 德文
    ltFrench,       // 法文
    ltSpanish,      // 西班牙文
    ltRussian,      // 俄文
    ltItalian,      // 意大利文
    ltPortuguese    // 葡萄牙文
  );

  // 语言信息记录
  TLanguageInfo = record
    LanguageType: TLanguageType;
    LanguageName: string;
    LanguageCode: string;
    LocaleID: Integer;
    IsRightToLeft: Boolean;
    FontName: string;
    FontCharset: Integer;
  end;

  // 语言资源接口
  ILanguageResource = interface
    ['{B8F5E2A1-9C4D-4E5F-8A7B-1234567890AB}']
    function GetString(const AKey: string): string;
    function GetFormattedString(const AKey: string; const AArgs: array of const): string;
    function HasString(const AKey: string): Boolean;
    function GetLanguageInfo: TLanguageInfo;
  end;

const
  // 默认语言信息
  DefaultLanguageInfos: array[TLanguageType] of TLanguageInfo = (
    // 中文
    (LanguageType: ltChinese; LanguageName: '中文'; LanguageCode: 'zh-CN'; 
     LocaleID: $0804; IsRightToLeft: False; FontName: 'Microsoft YaHei UI'; FontCharset: 134),
    // 英文
    (LanguageType: ltEnglish; LanguageName: 'English'; LanguageCode: 'en-US'; 
     LocaleID: $0409; IsRightToLeft: False; FontName: 'Segoe UI'; FontCharset: 0),
    // 日文
    (LanguageType: ltJapanese; LanguageName: '日本語'; LanguageCode: 'ja-JP'; 
     LocaleID: $0411; IsRightToLeft: False; FontName: 'Yu Gothic UI'; FontCharset: 128),
    // 韩文
    (LanguageType: ltKorean; LanguageName: '한국어'; LanguageCode: 'ko-KR'; 
     LocaleID: $0412; IsRightToLeft: False; FontName: 'Malgun Gothic'; FontCharset: 129),
    // 德文
    (LanguageType: ltGerman; LanguageName: 'Deutsch'; LanguageCode: 'de-DE'; 
     LocaleID: $0407; IsRightToLeft: False; FontName: 'Segoe UI'; FontCharset: 0),
    // 法文
    (LanguageType: ltFrench; LanguageName: 'Français'; LanguageCode: 'fr-FR'; 
     LocaleID: $040C; IsRightToLeft: False; FontName: 'Segoe UI'; FontCharset: 0),
    // 西班牙文
    (LanguageType: ltSpanish; LanguageName: 'Español'; LanguageCode: 'es-ES'; 
     LocaleID: $0C0A; IsRightToLeft: False; FontName: 'Segoe UI'; FontCharset: 0),
    // 俄文
    (LanguageType: ltRussian; LanguageName: 'Русский'; LanguageCode: 'ru-RU'; 
     LocaleID: $0419; IsRightToLeft: False; FontName: 'Segoe UI'; FontCharset: 204),
    // 意大利文
    (LanguageType: ltItalian; LanguageName: 'Italiano'; LanguageCode: 'it-IT'; 
     LocaleID: $0410; IsRightToLeft: False; FontName: 'Segoe UI'; FontCharset: 0),
    // 葡萄牙文
    (LanguageType: ltPortuguese; LanguageName: 'Português'; LanguageCode: 'pt-BR'; 
     LocaleID: $0416; IsRightToLeft: False; FontName: 'Segoe UI'; FontCharset: 0)
  );

// 辅助函数
function GetLanguageInfo(ALanguageType: TLanguageType): TLanguageInfo;
function GetLanguageTypeByCode(const ALanguageCode: string): TLanguageType;
function GetLanguageTypeByName(const ALanguageName: string): TLanguageType;
function GetSystemLanguageType: TLanguageType;

implementation

uses
  System.SysUtils, Winapi.Windows;

function GetLanguageInfo(ALanguageType: TLanguageType): TLanguageInfo;
begin
  Result := DefaultLanguageInfos[ALanguageType];
end;

function GetLanguageTypeByCode(const ALanguageCode: string): TLanguageType;
var
  LangType: TLanguageType;
begin
  Result := ltChinese; // 默认中文
  
  for LangType := Low(TLanguageType) to High(TLanguageType) do
  begin
    if SameText(DefaultLanguageInfos[LangType].LanguageCode, ALanguageCode) then
    begin
      Result := LangType;
      Break;
    end;
  end;
end;

function GetLanguageTypeByName(const ALanguageName: string): TLanguageType;
var
  LangType: TLanguageType;
begin
  Result := ltChinese; // 默认中文
  
  for LangType := Low(TLanguageType) to High(TLanguageType) do
  begin
    if SameText(DefaultLanguageInfos[LangType].LanguageName, ALanguageName) then
    begin
      Result := LangType;
      Break;
    end;
  end;
end;

function GetSystemLanguageType: TLanguageType;
var
  LangID: Word;
  PrimaryLang: Word;
begin
  Result := ltChinese; // 默认中文
  
  try
    LangID := GetSystemDefaultLCID and $3FF;
    PrimaryLang := LangID and $3FF;
    
    case PrimaryLang of
      $04: Result := ltChinese;   // LANG_CHINESE
      $09: Result := ltEnglish;   // LANG_ENGLISH
      $11: Result := ltJapanese;  // LANG_JAPANESE
      $12: Result := ltKorean;    // LANG_KOREAN
      $07: Result := ltGerman;    // LANG_GERMAN
      $0C: Result := ltFrench;    // LANG_FRENCH
      $0A: Result := ltSpanish;   // LANG_SPANISH
      $19: Result := ltRussian;   // LANG_RUSSIAN
      $10: Result := ltItalian;   // LANG_ITALIAN
      $16: Result := ltPortuguese; // LANG_PORTUGUESE
    else
      Result := ltEnglish; // 其他语言默认英文
    end;
  except
    Result := ltChinese; // 异常时默认中文
  end;
end;

end.

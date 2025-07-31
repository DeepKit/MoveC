unit MultiLanguageConstants;

interface

// 完整的16种语言常量定义
// 使用Unicode转义序列确保正确编码

type
  // 语言代码枚举（增加东南亚语言）
  TLanguageCode = (
    lcEnglish,           // en-US
    lcChineseSimplified, // zh-CN
    lcChineseTraditional,// zh-TW
    lcJapanese,          // ja-JP
    lcKorean,            // ko-KR
    lcGerman,            // de-DE
    lcFrench,            // fr-FR
    lcSpanish,           // es-ES
    lcItalian,           // it-IT
    lcPortuguese,        // pt-PT
    lcRussian,           // ru-RU
    lcDutch,             // nl-NL
    lcSwedish,           // sv-SE
    lcNorwegian,         // no-NO
    lcDanish,            // da-DK
    lcFinnish,           // fi-FI
    // 东南亚语言
    lcThai,              // th-TH 泰语
    lcVietnamese,        // vi-VN 越南语
    lcIndonesian,        // id-ID 印尼语
    lcMalay,             // ms-MY 马来语
    lcTagalog,           // tl-PH 菲律宾语
    lcBurmese            // my-MM 缅甸语
  );

const
  // 语言代码映射（增加东南亚语言）
  LANGUAGE_CODES: array[TLanguageCode] of string = (
    'en-US', 'zh-CN', 'zh-TW', 'ja-JP', 'ko-KR', 'de-DE', 'fr-FR', 'es-ES',
    'it-IT', 'pt-PT', 'ru-RU', 'nl-NL', 'sv-SE', 'no-NO', 'da-DK', 'fi-FI',
    'th-TH', 'vi-VN', 'id-ID', 'ms-MY', 'tl-PH', 'my-MM'
  );

  // 语言显示名称（用于语言选择窗口）- 使用各自的本国语言
  LANGUAGE_NAMES: array[TLanguageCode] of string = (
    'English',                                                    // 英语
    #$7B80#$4F53#$4E2D#$6587,                                   // 简体中文
    #$7E41#$9AD4#$4E2D#$6587,                                   // 繁體中文
    #$65E5#$672C#$8A9E,                                         // 日本語
    #$D55C#$AD6D#$C5B4,                                         // 한국어
    'Deutsch',                                                    // 德语
    #$0046#$0072#$0061#$006E#$00E7#$0061#$0069#$0073,          // Français
    #$0045#$0073#$0070#$0061#$00F1#$006F#$006C,                // Español
    'Italiano',                                                   // 意大利语
    #$0050#$006F#$0072#$0074#$0075#$0067#$0075#$00EA#$0073,    // Português
    #$0420#$0443#$0441#$0441#$043A#$0438#$0439,                // Русский
    'Nederlands',                                                 // 荷兰语
    'Svenska',                                                    // 瑞典语
    'Norsk',                                                      // 挪威语
    'Dansk',                                                      // 丹麦语
    'Suomi',                                                      // 芬兰语
    // 东南亚语言（使用本国文字）
    #$0E20#$0E32#$0E29#$0E32#$0E44#$0E17#$0E22,                // ภาษาไทย (泰语)
    #$0054#$0069#$1EBF#$006E#$0067#$0020#$0056#$0069#$1EC7#$0074, // Tiếng Việt (越南语)
    'Bahasa Indonesia',                                           // 印尼语
    'Bahasa Melayu',                                             // 马来语
    'Tagalog',                                                    // 菲律宾语
    #$1019#$103C#$1014#$103A#$1019#$102C#$1005#$102C            // မြန်မာစာ (缅甸语)
  );

  // 应用程序标题 - 各语言版本
  APP_TITLE_EN = 'C Drive Super Cleaner';
  APP_TITLE_ZH_CN = #$0043#$76D8#$8D85#$7EA7#$6E05#$7406;                    // C盘超级清理
  APP_TITLE_ZH_TW = #$0043#$76E4#$8D85#$7D1A#$6E05#$7406;                    // C盤超級清理
  APP_TITLE_JA = #$0043#$30C9#$30E9#$30A4#$30D6#$30AF#$30EA#$30FC#$30CA#$30FC; // Cドライブクリーナー
  APP_TITLE_KO = #$0043#$B4DC#$B77C#$C774#$BE0C#$D074#$B9AC#$B108;           // C드라이브클리너
  APP_TITLE_DE = 'C-Laufwerk Super Reiniger';
  APP_TITLE_FR = 'Nettoyeur Super C';
  APP_TITLE_ES = 'Limpiador Super C';
  APP_TITLE_IT = 'Pulitore Super C';
  APP_TITLE_PT = 'Limpador Super C';
  APP_TITLE_RU = #$041E#$0447#$0438#$0441#$0442#$0438#$0442#$0435#$043B#$044C#$0020#$0434#$0438#$0441#$043A#$0430#$0020#$0043; // Очиститель диска C
  APP_TITLE_NL = 'C-Schijf Super Reiniger';
  APP_TITLE_SV = 'C-Enhet Super Rengörare';
  APP_TITLE_NO = 'C-Disk Super Rengjører';
  APP_TITLE_DA = 'C-Drev Super Renser';
  APP_TITLE_FI = 'C-Asema Super Puhdistaja';

  // 语言选择窗口标题
  LANGUAGE_WINDOW_TITLE_EN = 'Language Settings';
  LANGUAGE_WINDOW_TITLE_ZH_CN = #$8BED#$8A00#$8BBE#$7F6E;                     // 语言设置
  LANGUAGE_WINDOW_TITLE_ZH_TW = #$8A9E#$8A00#$8A2D#$5B9A;                     // 語言設定
  LANGUAGE_WINDOW_TITLE_JA = #$8A00#$8A9E#$8A2D#$5B9A;                        // 言語設定
  LANGUAGE_WINDOW_TITLE_KO = #$C5B8#$C5B4#$C124#$C815;                        // 언어설정
  LANGUAGE_WINDOW_TITLE_DE = 'Spracheinstellungen';
  LANGUAGE_WINDOW_TITLE_FR = #$0050#$0061#$0072#$0061#$006D#$00E8#$0074#$0072#$0065#$0073#$0020#$0064#$0065#$0020#$006C#$0061#$006E#$0067#$0075#$0065; // Paramètres de langue
  LANGUAGE_WINDOW_TITLE_ES = #$0043#$006F#$006E#$0066#$0069#$0067#$0075#$0072#$0061#$0063#$0069#$00F3#$006E#$0020#$0064#$0065#$0020#$0069#$0064#$0069#$006F#$006D#$0061; // Configuración de idioma
  LANGUAGE_WINDOW_TITLE_IT = 'Impostazioni Lingua';
  LANGUAGE_WINDOW_TITLE_PT = #$0043#$006F#$006E#$0066#$0069#$0067#$0075#$0072#$0061#$00E7#$00F5#$0065#$0073#$0020#$0064#$0065#$0020#$0049#$0064#$0069#$006F#$006D#$0061; // Configurações de Idioma
  LANGUAGE_WINDOW_TITLE_RU = #$041D#$0430#$0441#$0442#$0440#$043E#$0439#$043A#$0438#$0020#$044F#$0437#$044B#$043A#$0430; // Настройки языка
  LANGUAGE_WINDOW_TITLE_NL = 'Taalinstellingen';
  LANGUAGE_WINDOW_TITLE_SV = #$0053#$0070#$0072#$00E5#$006B#$0069#$006E#$0073#$0074#$00E4#$006C#$006C#$006E#$0069#$006E#$0067#$0061#$0072; // Språkinställningar
  LANGUAGE_WINDOW_TITLE_NO = #$0053#$0070#$0072#$00E5#$006B#$0069#$006E#$006E#$0073#$0074#$0069#$006C#$006C#$0069#$006E#$0067#$0065#$0072; // Språkinnstillinger
  LANGUAGE_WINDOW_TITLE_DA = 'Sprogindstillinger';
  LANGUAGE_WINDOW_TITLE_FI = 'Kieliasetukset';

  // 确定按钮
  BTN_OK_EN = 'OK';
  BTN_OK_ZH_CN = #$786E#$5B9A;                                                 // 确定
  BTN_OK_ZH_TW = #$78BA#$5B9A;                                                 // 確定
  BTN_OK_JA = #$004F#$004B;                                                    // OK
  BTN_OK_KO = #$D655#$C778;                                                    // 확인
  BTN_OK_DE = 'OK';
  BTN_OK_FR = 'OK';
  BTN_OK_ES = 'Aceptar';
  BTN_OK_IT = 'OK';
  BTN_OK_PT = 'OK';
  BTN_OK_RU = #$041E#$041A;                                                    // ОК
  BTN_OK_NL = 'OK';
  BTN_OK_SV = 'OK';
  BTN_OK_NO = 'OK';
  BTN_OK_DA = 'OK';
  BTN_OK_FI = 'OK';

  // 取消按钮
  BTN_CANCEL_EN = 'Cancel';
  BTN_CANCEL_ZH_CN = #$53D6#$6D88;                                             // 取消
  BTN_CANCEL_ZH_TW = #$53D6#$6D88;                                             // 取消
  BTN_CANCEL_JA = #$30AD#$30E3#$30F3#$30BB#$30EB;                            // キャンセル
  BTN_CANCEL_KO = #$CE90#$C18C;                                                // 취소
  BTN_CANCEL_DE = 'Abbrechen';
  BTN_CANCEL_FR = 'Annuler';
  BTN_CANCEL_ES = 'Cancelar';
  BTN_CANCEL_IT = 'Annulla';
  BTN_CANCEL_PT = 'Cancelar';
  BTN_CANCEL_RU = #$041E#$0442#$043C#$0435#$043D#$0430;                       // Отмена
  BTN_CANCEL_NL = 'Annuleren';
  BTN_CANCEL_SV = 'Avbryt';
  BTN_CANCEL_NO = 'Avbryt';
  BTN_CANCEL_DA = 'Annuller';
  BTN_CANCEL_FI = 'Peruuta';

  // 语言更改提示信息
  LANGUAGE_CHANGED_EN = 'Language settings have been changed. Some interface elements will take effect after restart.';
  LANGUAGE_CHANGED_ZH_CN = #$8BED#$8A00#$8BBE#$7F6E#$5DF2#$66F4#$6539#$FF0C#$90E8#$5206#$754C#$9762#$5C06#$5728#$91CD#$542F#$540E#$751F#$6548#$3002; // 语言设置已更改，部分界面将在重启后生效。
  LANGUAGE_CHANGED_ZH_TW = #$8A9E#$8A00#$8A2D#$5B9A#$5DF2#$66F4#$6539#$FF0C#$90E8#$5206#$4ECB#$9762#$5C07#$5728#$91CD#$555F#$5F8C#$751F#$6548#$3002; // 語言設定已更改，部分介面將在重啟後生效。
  LANGUAGE_CHANGED_JA = #$8A00#$8A9E#$8A2D#$5B9A#$304C#$5909#$66F4#$3055#$308C#$307E#$3057#$305F#$3002#$4E00#$90E8#$306E#$30A4#$30F3#$30BF#$30FC#$30D5#$30A7#$30FC#$30B9#$306F#$518D#$8D77#$52D5#$5F8C#$306B#$6709#$52B9#$306B#$306A#$308A#$307E#$3059#$3002; // 言語設定が変更されました。一部のインターフェースは再起動後に有効になります。
  LANGUAGE_CHANGED_KO = #$C5B8#$C5B4#$C124#$C815#$C774#$BCC0#$ACBD#$B418#$C5C8#$C2B5#$B2C8#$B2E4#$002E#$C77C#$BD80#$C778#$D130#$D398#$C774#$C2A4#$B294#$C7AC#$C2DC#$C791#$D6C4#$C5D0#$C801#$C6A9#$B429#$B2C8#$B2E4#$002E; // 언어설정이 변경되었습니다. 일부 인터페이스는 재시작후에 적용됩니다.

function GetLanguageDisplayName(LanguageCode: TLanguageCode): string;
function GetLanguageCodeString(LanguageCode: TLanguageCode): string;
function GetLanguageCodeFromString(const CodeStr: string): TLanguageCode;

implementation

function GetLanguageDisplayName(LanguageCode: TLanguageCode): string;
begin
  Result := LANGUAGE_NAMES[LanguageCode];
end;

function GetLanguageCodeString(LanguageCode: TLanguageCode): string;
begin
  Result := LANGUAGE_CODES[LanguageCode];
end;

function GetLanguageCodeFromString(const CodeStr: string): TLanguageCode;
var
  I: TLanguageCode;
begin
  Result := lcEnglish; // 默认值
  for I := Low(TLanguageCode) to High(TLanguageCode) do
  begin
    if LANGUAGE_CODES[I] = CodeStr then
    begin
      Result := I;
      Break;
    end;
  end;
end;

end.

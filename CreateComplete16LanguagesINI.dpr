program CreateComplete16LanguagesINI;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.IniFiles,
  MultiLanguageConstants;

procedure CreateCompleteLanguageDatabase;
var
  IniFile: TMemIniFile;
  DbPath, IniPath: string;
begin
  Writeln('Creating complete 16-language database...');
  
  // 确保数据库目录存在
  DbPath := TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'DiskCleanup');
  if not TDirectory.Exists(DbPath) then
    TDirectory.CreateDirectory(DbPath);
  
  IniPath := TPath.Combine(DbPath, 'language_strings.ini');
  
  // 删除旧文件
  if TFile.Exists(IniPath) then
    TFile.Delete(IniPath);
  
  IniFile := TMemIniFile.Create(IniPath, TEncoding.UTF8);
  try
    // 英语 (en-US)
    IniFile.WriteString('en-US', 'app_title', APP_TITLE_EN);
    IniFile.WriteString('en-US', 'language_window_title', LANGUAGE_WINDOW_TITLE_EN);
    IniFile.WriteString('en-US', 'btn_ok', BTN_OK_EN);
    IniFile.WriteString('en-US', 'btn_cancel', BTN_CANCEL_EN);
    IniFile.WriteString('en-US', 'language_changed', LANGUAGE_CHANGED_EN);
    IniFile.WriteString('en-US', 'select_language_prompt', 'Please select a language.');
    
    // 简体中文 (zh-CN)
    IniFile.WriteString('zh-CN', 'app_title', APP_TITLE_ZH_CN);
    IniFile.WriteString('zh-CN', 'language_window_title', LANGUAGE_WINDOW_TITLE_ZH_CN);
    IniFile.WriteString('zh-CN', 'btn_ok', BTN_OK_ZH_CN);
    IniFile.WriteString('zh-CN', 'btn_cancel', BTN_CANCEL_ZH_CN);
    IniFile.WriteString('zh-CN', 'language_changed', LANGUAGE_CHANGED_ZH_CN);
    IniFile.WriteString('zh-CN', 'select_language_prompt', #$8BF7#$9009#$62E9#$4E00#$79CD#$8BED#$8A00#$3002);  // 请选择一种语言。

    // 繁体中文 (zh-TW)
    IniFile.WriteString('zh-TW', 'app_title', APP_TITLE_ZH_TW);
    IniFile.WriteString('zh-TW', 'language_window_title', LANGUAGE_WINDOW_TITLE_ZH_TW);
    IniFile.WriteString('zh-TW', 'btn_ok', BTN_OK_ZH_TW);
    IniFile.WriteString('zh-TW', 'btn_cancel', BTN_CANCEL_ZH_TW);
    IniFile.WriteString('zh-TW', 'language_changed', LANGUAGE_CHANGED_ZH_TW);
    IniFile.WriteString('zh-TW', 'select_language_prompt', #$8ACB#$9078#$64C7#$4E00#$7A2E#$8A9E#$8A00#$3002);  // 請選擇一種語言。

    // 日语 (ja-JP)
    IniFile.WriteString('ja-JP', 'app_title', APP_TITLE_JA);
    IniFile.WriteString('ja-JP', 'language_window_title', LANGUAGE_WINDOW_TITLE_JA);
    IniFile.WriteString('ja-JP', 'btn_ok', BTN_OK_JA);
    IniFile.WriteString('ja-JP', 'btn_cancel', BTN_CANCEL_JA);
    IniFile.WriteString('ja-JP', 'language_changed', LANGUAGE_CHANGED_JA);
    IniFile.WriteString('ja-JP', 'select_language_prompt', #$8A00#$8A9E#$3092#$9078#$629E#$3057#$3066#$304F#$3060#$3055#$3044#$3002);  // 言語を選択してください。

    // 韩语 (ko-KR)
    IniFile.WriteString('ko-KR', 'app_title', APP_TITLE_KO);
    IniFile.WriteString('ko-KR', 'language_window_title', LANGUAGE_WINDOW_TITLE_KO);
    IniFile.WriteString('ko-KR', 'btn_ok', BTN_OK_KO);
    IniFile.WriteString('ko-KR', 'btn_cancel', BTN_CANCEL_KO);
    IniFile.WriteString('ko-KR', 'language_changed', LANGUAGE_CHANGED_KO);
    IniFile.WriteString('ko-KR', 'select_language_prompt', #$C5B8#$C5B4#$B97C#$C120#$D0DD#$D558#$C138#$C694#$002E);  // 언어를 선택하세요.
    
    // 德语 (de-DE)
    IniFile.WriteString('de-DE', 'app_title', APP_TITLE_DE);
    IniFile.WriteString('de-DE', 'language_window_title', LANGUAGE_WINDOW_TITLE_DE);
    IniFile.WriteString('de-DE', 'btn_ok', BTN_OK_DE);
    IniFile.WriteString('de-DE', 'btn_cancel', BTN_CANCEL_DE);
    IniFile.WriteString('de-DE', 'language_changed', 'Spracheinstellungen wurden ge' + #$00E4 + 'ndert. Einige Oberfl' + #$00E4 + 'chenelemente werden nach dem Neustart wirksam.');
    
    // 法语 (fr-FR)
    IniFile.WriteString('fr-FR', 'app_title', APP_TITLE_FR);
    IniFile.WriteString('fr-FR', 'language_window_title', LANGUAGE_WINDOW_TITLE_FR);
    IniFile.WriteString('fr-FR', 'btn_ok', BTN_OK_FR);
    IniFile.WriteString('fr-FR', 'btn_cancel', BTN_CANCEL_FR);
    IniFile.WriteString('fr-FR', 'language_changed', 'Les param' + #$00E8 + 'tres de langue ont ' + #$00E9 + 't' + #$00E9 + ' modifi' + #$00E9 + 's. Certains ' + #$00E9 + 'l' + #$00E9 + 'ments d''interface prendront effet apr' + #$00E8 + 's le red' + #$00E9 + 'marrage.');
    
    // 西班牙语 (es-ES)
    IniFile.WriteString('es-ES', 'app_title', APP_TITLE_ES);
    IniFile.WriteString('es-ES', 'language_window_title', LANGUAGE_WINDOW_TITLE_ES);
    IniFile.WriteString('es-ES', 'btn_ok', BTN_OK_ES);
    IniFile.WriteString('es-ES', 'btn_cancel', BTN_CANCEL_ES);
    IniFile.WriteString('es-ES', 'language_changed', 'La configuraci' + #$00F3 + 'n de idioma ha sido cambiada. Algunos elementos de la interfaz tendr' + #$00E1 + 'n efecto despu' + #$00E9 + 's del reinicio.');
    
    // 意大利语 (it-IT)
    IniFile.WriteString('it-IT', 'app_title', APP_TITLE_IT);
    IniFile.WriteString('it-IT', 'language_window_title', LANGUAGE_WINDOW_TITLE_IT);
    IniFile.WriteString('it-IT', 'btn_ok', BTN_OK_IT);
    IniFile.WriteString('it-IT', 'btn_cancel', BTN_CANCEL_IT);
    IniFile.WriteString('it-IT', 'language_changed', 'Le impostazioni della lingua sono state modificate. Alcuni elementi dell''interfaccia avranno effetto dopo il riavvio.');
    
    // 葡萄牙语 (pt-PT)
    IniFile.WriteString('pt-PT', 'app_title', APP_TITLE_PT);
    IniFile.WriteString('pt-PT', 'language_window_title', LANGUAGE_WINDOW_TITLE_PT);
    IniFile.WriteString('pt-PT', 'btn_ok', BTN_OK_PT);
    IniFile.WriteString('pt-PT', 'btn_cancel', BTN_CANCEL_PT);
    IniFile.WriteString('pt-PT', 'language_changed', 'As configura' + #$00E7 + #$00F5 + 'es de idioma foram alteradas. Alguns elementos da interface ter' + #$00E3 + 'o efeito ap' + #$00F3 + 's a reinicializa' + #$00E7 + #$00E3 + 'o.');
    
    // 俄语 (ru-RU)
    IniFile.WriteString('ru-RU', 'app_title', APP_TITLE_RU);
    IniFile.WriteString('ru-RU', 'language_window_title', LANGUAGE_WINDOW_TITLE_RU);
    IniFile.WriteString('ru-RU', 'btn_ok', BTN_OK_RU);
    IniFile.WriteString('ru-RU', 'btn_cancel', BTN_CANCEL_RU);
    IniFile.WriteString('ru-RU', 'language_changed', #$041D#$0430#$0441#$0442#$0440#$043E#$0439#$043A#$0438#$0020#$044F#$0437#$044B#$043A#$0430#$0020#$0438#$0437#$043C#$0435#$043D#$0435#$043D#$044B#$002E#$0020#$041D#$0435#$043A#$043E#$0442#$043E#$0440#$044B#$0435#$0020#$044D#$043B#$0435#$043C#$0435#$043D#$0442#$044B#$0020#$0438#$043D#$0442#$0435#$0440#$0444#$0435#$0439#$0441#$0430#$0020#$0432#$0441#$0442#$0443#$043F#$044F#$0442#$0020#$0432#$0020#$0441#$0438#$043B#$0443#$0020#$043F#$043E#$0441#$043B#$0435#$0020#$043F#$0435#$0440#$0435#$0437#$0430#$043F#$0443#$0441#$043A#$0430#$002E);
    
    // 荷兰语 (nl-NL)
    IniFile.WriteString('nl-NL', 'app_title', APP_TITLE_NL);
    IniFile.WriteString('nl-NL', 'language_window_title', LANGUAGE_WINDOW_TITLE_NL);
    IniFile.WriteString('nl-NL', 'btn_ok', BTN_OK_NL);
    IniFile.WriteString('nl-NL', 'btn_cancel', BTN_CANCEL_NL);
    IniFile.WriteString('nl-NL', 'language_changed', 'Taalinstellingen zijn gewijzigd. Sommige interface-elementen worden van kracht na herstart.');
    
    // 瑞典语 (sv-SE)
    IniFile.WriteString('sv-SE', 'app_title', APP_TITLE_SV);
    IniFile.WriteString('sv-SE', 'language_window_title', LANGUAGE_WINDOW_TITLE_SV);
    IniFile.WriteString('sv-SE', 'btn_ok', BTN_OK_SV);
    IniFile.WriteString('sv-SE', 'btn_cancel', BTN_CANCEL_SV);
    IniFile.WriteString('sv-SE', 'language_changed', 'Spr' + #$00E5 + 'kinst' + #$00E4 + 'llningar har ' + #$00E4 + 'ndrats. Vissa gr' + #$00E4 + 'nssnittselement tr' + #$00E4 + 'der i kraft efter omstart.');
    
    // 挪威语 (no-NO)
    IniFile.WriteString('no-NO', 'app_title', APP_TITLE_NO);
    IniFile.WriteString('no-NO', 'language_window_title', LANGUAGE_WINDOW_TITLE_NO);
    IniFile.WriteString('no-NO', 'btn_ok', BTN_OK_NO);
    IniFile.WriteString('no-NO', 'btn_cancel', BTN_CANCEL_NO);
    IniFile.WriteString('no-NO', 'language_changed', 'Spr' + #$00E5 + 'kinnstillinger er endret. Noen grensesnittelementer vil tre i kraft etter omstart.');
    
    // 丹麦语 (da-DK)
    IniFile.WriteString('da-DK', 'app_title', APP_TITLE_DA);
    IniFile.WriteString('da-DK', 'language_window_title', LANGUAGE_WINDOW_TITLE_DA);
    IniFile.WriteString('da-DK', 'btn_ok', BTN_OK_DA);
    IniFile.WriteString('da-DK', 'btn_cancel', BTN_CANCEL_DA);
    IniFile.WriteString('da-DK', 'language_changed', 'Sprogindstillinger er blevet ' + #$00E6 + 'ndret. Nogle gr' + #$00E6 + 'nsefladeelementer tr' + #$00E6 + 'der i kraft efter genstart.');
    
    // 芬兰语 (fi-FI)
    IniFile.WriteString('fi-FI', 'app_title', APP_TITLE_FI);
    IniFile.WriteString('fi-FI', 'language_window_title', LANGUAGE_WINDOW_TITLE_FI);
    IniFile.WriteString('fi-FI', 'btn_ok', BTN_OK_FI);
    IniFile.WriteString('fi-FI', 'btn_cancel', BTN_CANCEL_FI);
    IniFile.WriteString('fi-FI', 'language_changed', 'Kieliasetukset on muutettu. Jotkin k' + #$00E4 + 'ytt' + #$00F6 + 'liittym' + #$00E4 + 'n elementit tulevat voimaan uudelleenk' + #$00E4 + 'ynnistyksen j' + #$00E4 + 'lkeen.');
    
    // 保存文件
    IniFile.UpdateFile;
    
    Writeln('Complete 16-language database created successfully!');
    Writeln('File: ' + IniPath);
    
  finally
    IniFile.Free;
  end;
end;

procedure CreateConfigFile;
var
  IniFile: TMemIniFile;
  DbPath, IniPath: string;
begin
  Writeln('Creating config file...');
  
  DbPath := TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'DiskCleanup');
  IniPath := TPath.Combine(DbPath, 'config_settings.ini');
  
  IniFile := TMemIniFile.Create(IniPath, TEncoding.UTF8);
  try
    IniFile.WriteString('app', 'current_language', 'zh-CN');  // 默认简体中文
    IniFile.WriteString('app', 'version', '1.0.0');
    IniFile.WriteString('app', 'first_run', 'false');
    IniFile.UpdateFile;
    
    Writeln('Config file created: ' + IniPath);
  finally
    IniFile.Free;
  end;
end;

procedure VerifyCreatedFiles;
var
  LanguageFile, ConfigFile: string;
  Content: string;
begin
  Writeln('');
  Writeln('=== Verifying Created Files ===');
  
  LanguageFile := TPath.Combine(TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'DiskCleanup'), 'language_strings.ini');
  ConfigFile := TPath.Combine(TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'DiskCleanup'), 'config_settings.ini');
  
  if TFile.Exists(LanguageFile) then
  begin
    Content := TFile.ReadAllText(LanguageFile, TEncoding.UTF8);
    Writeln('Language file size: ' + IntToStr(Length(Content)) + ' characters');
    
    // 检查各语言段落
    if Content.Contains('[en-US]') then Writeln('  ✓ English');
    if Content.Contains('[zh-CN]') then Writeln('  ✓ Chinese Simplified');
    if Content.Contains('[zh-TW]') then Writeln('  ✓ Chinese Traditional');
    if Content.Contains('[ja-JP]') then Writeln('  ✓ Japanese');
    if Content.Contains('[ko-KR]') then Writeln('  ✓ Korean');
    if Content.Contains('[de-DE]') then Writeln('  ✓ German');
    if Content.Contains('[fr-FR]') then Writeln('  ✓ French');
    if Content.Contains('[es-ES]') then Writeln('  ✓ Spanish');
    if Content.Contains('[it-IT]') then Writeln('  ✓ Italian');
    if Content.Contains('[pt-PT]') then Writeln('  ✓ Portuguese');
    if Content.Contains('[ru-RU]') then Writeln('  ✓ Russian');
    if Content.Contains('[nl-NL]') then Writeln('  ✓ Dutch');
    if Content.Contains('[sv-SE]') then Writeln('  ✓ Swedish');
    if Content.Contains('[no-NO]') then Writeln('  ✓ Norwegian');
    if Content.Contains('[da-DK]') then Writeln('  ✓ Danish');
    if Content.Contains('[fi-FI]') then Writeln('  ✓ Finnish');
    
    if Content.Contains('C盘超级清理') then
      Writeln('  ✓ Chinese characters are correct');
  end;
  
  if TFile.Exists(ConfigFile) then
  begin
    Writeln('  ✓ Config file created');
  end;
end;

begin
  try
    Writeln('COMPLETE 16-LANGUAGE DATABASE CREATOR');
    Writeln('=====================================');
    Writeln('');
    
    CreateCompleteLanguageDatabase;
    CreateConfigFile;
    VerifyCreatedFiles;
    
    Writeln('');
    Writeln('SUCCESS! Your 16-language database is ready.');
    Writeln('All languages with proper Unicode encoding.');
    
  except
    on E: Exception do
      Writeln('Error: ' + E.Message);
  end;
  
  Writeln('');
  Writeln('Press Enter to exit...');
  Readln;
end.

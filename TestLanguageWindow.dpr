program TestLanguageWindow;

uses
  Vcl.Forms,
  System.SysUtils,
  MultiLanguageDatabaseManager,
  MultiLanguageConstants,
  LanguageSelectionForm,
  DataTypes;

{$R *.res}

var
  DbManager: TMultiLanguageDatabaseManager;
  LanguageForm: TfrmLanguageSelection;
  I: Integer;

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  
  try
    Writeln('Testing Language Selection Window...');
    
    // 确保数据库存在
    DbManager := TMultiLanguageDatabaseManager.Create;
    try
      if DbManager.Initialize then
      begin
        Writeln('Database initialized successfully');
        Writeln('Current language: ' + GetLanguageDisplayName(DbManager.GetCurrentLanguage));
        Writeln('');
        
        // 测试不同语言下的窗口显示
        Writeln('Testing window in different languages:');
        
        // 测试中文
        DbManager.SetCurrentLanguage(lcChineseSimplified);
        Writeln('Set to Chinese: ' + DbManager.GetLanguageWindowTitle);
        
        // 测试日语
        DbManager.SetCurrentLanguage(lcJapanese);
        Writeln('Set to Japanese: ' + DbManager.GetLanguageWindowTitle);
        
        // 测试德语
        DbManager.SetCurrentLanguage(lcGerman);
        Writeln('Set to German: ' + DbManager.GetLanguageWindowTitle);
        
        // 测试俄语
        DbManager.SetCurrentLanguage(lcRussian);
        Writeln('Set to Russian: ' + DbManager.GetLanguageWindowTitle);
        
        Writeln('');
        Writeln('Opening language selection window...');
        Writeln('Window should display in current language (Russian)');
        Writeln('Language list should show all 16 languages in their native names');
        
        // 创建并显示语言选择窗口
        LanguageForm := TfrmLanguageSelection.Create(nil, DbManager);
        try
          if LanguageForm.ShowModal = mrOk then
          begin
            Writeln('User selected: ' + GetLanguageDisplayName(LanguageForm.SelectedLanguage));
            Writeln('New app title: ' + DbManager.GetAppTitle);
          end
          else
            Writeln('User cancelled language selection');
        finally
          LanguageForm.Free;
        end;
        
      end
      else
        Writeln('Database initialization failed');
    finally
      DbManager.Free;
    end;
    
  except
    on E: Exception do
      Writeln('Error: ' + E.Message);
  end;
  
  Writeln('Press Enter to exit...');
  Readln;
end.

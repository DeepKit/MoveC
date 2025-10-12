program TestImport;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  uImageDatabase,
  uBasicProtection,
  uAntiTamperPackage;

var
  Database: TImageDatabase;
  DatabasePath: string;
  ImageData: TBytes;
  ImagePath: string;
begin
  try
    Writeln('=== Test Image Import ===');
    Writeln;
    
    // Initialize anti-tamper
    var Config := TAntiTamperPackage.GetDefaultConfig;
    Config.EncryptionKey := 'MoveC_AntiTamper_Key_2025';
    Config.EncryptionType := etAES256;
    Config.EnableLogging := False;
    TAntiTamperPackage.Initialize(Config);
    
    DatabasePath := TImageDatabase.GetProjectDatabasePath;
    Writeln('Database: ', DatabasePath);
    
    Database := TImageDatabase.Create(DatabasePath, '@2241114');
    try
      Writeln('Connecting...');
      if not Database.Connect then
      begin
        Writeln('ERROR: Cannot connect to database');
        Exit;
      end;
      Writeln('Connected!');
      Writeln;
      
      // Test importing alipay
      ImagePath := 'assets\AliPay.png';
      Writeln('Testing import of: ', ImagePath);
      
      if not TFile.Exists(ImagePath) then
      begin
        Writeln('ERROR: File not found');
        Exit;
      end;
      
      ImageData := TFile.ReadAllBytes(ImagePath);
      Writeln('File size: ', Length(ImageData), ' bytes');
      
      Writeln('Calling SaveImageData...');
      if Database.SaveImageData('alipay', ImageData, 'Test import', '支付宝收款码') then
      begin
        Writeln('SUCCESS: Image saved!');
      end
      else
      begin
        Writeln('FAILED: Image not saved (no exception)');
      end;
      
    finally
      Database.Free;
    end;
    
  except
    on E: Exception do
      Writeln('EXCEPTION: ', E.ClassName, ': ', E.Message);
  end;
  
  Writeln;
  Writeln('Press Enter...');
  Readln;
end.

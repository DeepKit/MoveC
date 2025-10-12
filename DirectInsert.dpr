program DirectInsert;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  Data.DB,
  FireDAC.Comp.Client,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Def,
  FireDAC.Stan.Param,
  FireDAC.Stan.Intf,
  FireDAC.UI.Intf,
  FireDAC.ConsoleUI.Wait,
  FireDAC.DApt,
  uBasicProtection,
  uAntiTamperPackage;

procedure InsertImage(Query: TFDQuery; const ImageKey, ImagePath, AddressText: string);
var
  ImageData, EncryptedData: TBytes;
  MemStream: TMemoryStream;
  HashValue: string;
begin
  Writeln('Inserting: ', ImageKey);
  
  if not TFile.Exists(ImagePath) then
  begin
    Writeln('  ERROR: File not found');
    Exit;
  end;
  
  // Read image file
  ImageData := TFile.ReadAllBytes(ImagePath);
  Writeln('  File size: ', Length(ImageData), ' bytes');
  
  // Encrypt with fixed password
  EncryptedData := TBasicProtection.EncryptBinaryData(ImageData, '@2241114');
  Writeln('  Encrypted size: ', Length(EncryptedData), ' bytes');
  
  // Calculate SHA256 hash
  HashValue := TAntiTamperPackage.CalculateSHA256(ImageData);
  
  // Insert into database
  Query.SQL.Text := 
    'INSERT OR REPLACE INTO donation_images (image_key, image_data, md5_hash, address_text, description) ' +
    'VALUES (:key, :data, :hash, :address, :desc)';
  
  Query.ParamByName('key').AsString := ImageKey;
  Query.ParamByName('hash').AsString := HashValue;
  Query.ParamByName('address').AsString := AddressText;
  Query.ParamByName('desc').AsString := 'Direct insert';
  
  MemStream := TMemoryStream.Create;
  try
    MemStream.WriteBuffer(EncryptedData[0], Length(EncryptedData));
    MemStream.Position := 0;
    Query.ParamByName('data').LoadFromStream(MemStream, ftBlob);
  finally
    MemStream.Free;
  end;
  
  Query.ExecSQL;
  Writeln('  SUCCESS!');
end;

var
  Conn: TFDConnection;
  Query: TFDQuery;
  Config: TAntiTamperConfig;
begin
  try
    Writeln('=== Direct Image Insert Tool ===');
    Writeln;
    
    // Initialize anti-tamper
    Config := TAntiTamperPackage.GetDefaultConfig;
    Config.EncryptionKey := 'MoveC_AntiTamper_Key_2025';
    Config.EncryptionType := etAES256;
    Config.EnableLogging := False;
    TAntiTamperPackage.Initialize(Config);
    
    Conn := TFDConnection.Create(nil);
    try
      Conn.DriverName := 'SQLite';
      Conn.Params.Clear;
      Conn.Params.Add('DriverID=SQLite');
      Conn.Params.Add('Database=MoveC.db');
      Conn.Connected := True;
      Writeln('Database connected');
      Writeln;
      
      Query := TFDQuery.Create(nil);
      try
        Query.Connection := Conn;
        
        // Insert 4 remaining images
        InsertImage(Query, 'alipay', 'assets\AliPay.png', '支付宝收款码');
        InsertImage(Query, 'btc', 'assets\btc.png', 'bc1qze0ggsrdtjqwjpjfufydsuyjxc08tgcq5xkct3');
        InsertImage(Query, 'usdt', 'assets\usdt.png', 'TH1NazpoEpUqcEotGzLPHs13SbLDJKKCys');
        InsertImage(Query, 'aboutme', 'assets\itsMe.jpg', 'C盘瘦身工具 - 开发者: 好记忆管理工作室 - 官网: www.goodmem.cn');
        
        Writeln;
        Writeln('All images inserted successfully!');
        
      finally
        Query.Free;
      end;
    finally
      Conn.Free;
    end;
    
  except
    on E: Exception do
      Writeln('ERROR: ', E.ClassName, ': ', E.Message);
  end;
  
  Writeln;
  Writeln('Press Enter...');
  Readln;
end.

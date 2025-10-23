program TestDecrypt;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs,
  Data.DB,
  FireDAC.Comp.Client,
  uBasicProtection in 'uBasicProtection.pas';

var
  Connection: TFDConnection;
  Query: TFDQuery;
  EncryptedData, DecryptedData: TBytes;
  MemStream: TMemoryStream;
begin
  try
    Writeln('=== 娴嬭瘯鏁版嵁搴撳浘鍍忚В瀵?===');
    Writeln;
    
    // 鍒涘缓杩炴帴
    Connection := TFDConnection.Create(nil);
    Query := TFDQuery.Create(nil);
    try
      Connection.DriverName := 'SQLite';
      Connection.Params.Values['Database'] := 'MoveC.db';
      Connection.Connected := True;
      
      Writeln('鉁?鏁版嵁搴撹繛鎺ユ垚鍔?);
      Writeln;
      
      Query.Connection := Connection;
      Query.SQL.Text := 'SELECT image_key, image_data FROM images WHERE image_key = ''wechat''';
      Query.Open;
      
      if not Query.Eof then
      begin
        Writeln('鉁?鎵惧埌wechat璁板綍');
        
        // 璇诲彇鍔犲瘑鏁版嵁
        MemStream := TMemoryStream.Create;
        try
          TBlobField(Query.FieldByName('image_data')).SaveToStream(MemStream);
          SetLength(EncryptedData, MemStream.Size);
          MemStream.Position := 0;
          MemStream.ReadBuffer(EncryptedData[0], MemStream.Size);
          
          Writeln('鍔犲瘑鏁版嵁澶у皬: ', Length(EncryptedData), ' bytes');
          Writeln('鍓?6瀛楄妭 (IV): ', 
            Format('%02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X',
            [EncryptedData[0], EncryptedData[1], EncryptedData[2], EncryptedData[3],
             EncryptedData[4], EncryptedData[5], EncryptedData[6], EncryptedData[7],
             EncryptedData[8], EncryptedData[9], EncryptedData[10], EncryptedData[11],
             EncryptedData[12], EncryptedData[13], EncryptedData[14], EncryptedData[15]]));
          Writeln;
          
          // 娴嬭瘯瑙ｅ瘑
          Writeln('寮€濮嬭В瀵嗭紙瀵嗙爜: @2241114锛?..');
          try
            DecryptedData := TBasicProtection.DecryptBinaryData(EncryptedData, '@2241114');
            Writeln('鉁?瑙ｅ瘑鎴愬姛');
            Writeln('瑙ｅ瘑鏁版嵁澶у皬: ', Length(DecryptedData), ' bytes');
            Writeln('鍓?瀛楄妭: ', 
              Format('%02X %02X %02X %02X',
              [DecryptedData[0], DecryptedData[1], DecryptedData[2], DecryptedData[3]]));
            
            // 妫€鏌NG鏂囦欢澶?            if (Length(DecryptedData) >= 4) and 
               (DecryptedData[0] = $89) and 
               (DecryptedData[1] = $50) and 
               (DecryptedData[2] = $4E) and 
               (DecryptedData[3] = $47) then
              Writeln('鉁?PNG鏂囦欢澶存纭?)
            else
              Writeln('鉁?PNG鏂囦欢澶翠笉姝ｇ‘');
              
          except
            on E: Exception do
              Writeln('鉁?瑙ｅ瘑澶辫触: ', E.Message);
          end;
          
        finally
          MemStream.Free;
        end;
      end
      else
        Writeln('鉁?鏈壘鍒皐echat璁板綍');
        
    finally
      Query.Free;
      Connection.Free;
    end;
    
  except
    on E: Exception do
      Writeln('閿欒: ', E.Message);
  end;
  
  Writeln;
  Writeln('鎸夊洖杞﹂敭閫€鍑?..');
  Readln;
end.


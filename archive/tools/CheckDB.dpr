program CheckDB;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  FireDAC.Comp.Client,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Stan.Def,
  FireDAC.UI.Intf,
  FireDAC.ConsoleUI.Wait,
  FireDAC.DApt,
  uImageDatabase;

var
  Database: TImageDatabase;
  DatabasePath: string;
  ImageData: TBytes;
  AddressText: string;
  ImageKeys: array[0..4] of string = ('wechat', 'alipay', 'btc', 'usdt', 'aboutme');
  I: Integer;
begin
  try
    Writeln('=== 鏁版嵁搴撳浘鍍忔鏌ュ伐鍏?===');
    Writeln;
    
    // 浣跨敤椤圭洰鏍圭洰褰曚笅鐨凪oveC.db
    DatabasePath := TImageDatabase.GetProjectDatabasePath;
    Writeln('鏁版嵁搴撹矾寰? ', DatabasePath);
    
    if not TFile.Exists(DatabasePath) then
    begin
      Writeln('閿欒: 鏁版嵁搴撴枃浠朵笉瀛樺湪!');
      Exit;
    end;
    
    // 鍒涘缓骞惰繛鎺ユ暟鎹簱
    Database := TImageDatabase.Create(DatabasePath);
    try
      Writeln('姝ｅ湪杩炴帴鏁版嵁搴?..');
      if not Database.Connect then
      begin
        Writeln('閿欒: 鏃犳硶杩炴帴鍒版暟鎹簱');
        Exit;
      end;
      
      Writeln('鏁版嵁搴撹繛鎺ユ垚鍔?);
      Writeln;
      
      // 妫€鏌ユ瘡涓浘鍍?      for I := 0 to High(ImageKeys) do
      begin
        Writeln('妫€鏌ュ浘鍍? ', ImageKeys[I]);
        
        if Database.LoadImageAndText(ImageKeys[I], ImageData, AddressText) then
        begin
          Writeln('  鉁?鍥惧儚瀛樺湪');
          Writeln('  - 鏁版嵁澶у皬: ', Length(ImageData), ' 瀛楄妭');
          Writeln('  - 鍦板潃鏂囨湰: ', AddressText);
          
          // 淇濆瓨鍒版枃浠堕獙璇?          TFile.WriteAllBytes('check_' + ImageKeys[I] + '.dat', ImageData);
          Writeln('  - 宸蹭繚瀛樺埌: check_', ImageKeys[I], '.dat');
        end
        else
        begin
          Writeln('  鉁?鍥惧儚涓嶅瓨鍦ㄦ垨鍔犺浇澶辫触');
        end;
        Writeln;
      end;
      
    finally
      Database.Free;
    end;
    
  except
    on E: Exception do
      Writeln('閿欒: ', E.Message);
  end;
  
  Writeln('鎸変换鎰忛敭閫€鍑?..');
  Readln;
end.


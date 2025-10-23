program ExtractImagesToFiles;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  uImageDatabase;

var
  Database: TImageDatabase;
  ImageData: TBytes;
  ImageKeys: array[0..4] of string = ('wechat', 'alipay', 'btc', 'usdt', 'aboutme');
  Extensions: array[0..4] of string = ('.png', '.png', '.png', '.png', '.jpg');
  i: Integer;
  FileName: string;
  DatabasePath: string;

begin
  try
    WriteLn('姝ｅ湪浠庢暟鎹簱鎻愬彇鍥惧儚鏂囦欢...');
    
    // 缁熶竴浣跨敤椤圭洰鏍圭洰褰曚笅鐨勬暟鎹簱锛圡oveC.db锛?
    DatabasePath := TImageDatabase.GetProjectDatabasePath;
    
    if not TFile.Exists(DatabasePath) then
    begin
      WriteLn('閿欒锛氭壘涓嶅埌鏁版嵁搴撴枃浠? ' + DatabasePath);
      Exit;
    end;
    
    // 鍒涘缓鏁版嵁搴撹繛鎺ワ紙FireDAC 灏佽锛?
    Database := TImageDatabase.Create(DatabasePath);
    
    try
      if not Database.Connect then
      begin
        WriteLn('閿欒锛氭棤娉曡繛鎺ュ埌鏁版嵁搴?);
        Exit;
      end;
      
      WriteLn('鏁版嵁搴撹繛鎺ユ垚鍔?);
      
      // 鎻愬彇姣忎釜鍥惧儚锛堢粺涓€灏忓啓閿級
      for i := 0 to Length(ImageKeys) - 1 do
      begin
        WriteLn('姝ｅ湪鎻愬彇: ' + ImageKeys[i]);
        
        if Database.LoadImageData(ImageKeys[i], ImageData) then
        begin
          FileName := ImageKeys[i] + Extensions[i];
          TFile.WriteAllBytes(FileName, ImageData);
          WriteLn('  鉁?宸蹭繚瀛? ' + FileName + ' (' + IntToStr(Length(ImageData)) + ' 瀛楄妭)');
        end
        else
        begin
          WriteLn('  鉁?鎻愬彇澶辫触: ' + ImageKeys[i]);
        end;
      end;
      
      WriteLn('鍥惧儚鎻愬彇瀹屾垚锛?);
      
    finally
      Database.Free;
    end;
    
  except
    on E: Exception do
      WriteLn('鍙戠敓寮傚父: ' + E.Message);
  end;
  
  WriteLn('鎸夊洖杞﹂敭閫€鍑?..');
  ReadLn;
end.


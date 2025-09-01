program ExtractImagesToFiles;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  uSQLiteDB;

var
  DB: TSQLiteDatabase;
  ImageData: TBytes;
  ImageKeys: array[0..4] of string = ('WECHAT', 'ALIPAY', 'BTC', 'USDT', 'ABOUTME');
  Extensions: array[0..4] of string = ('.png', '.png', '.png', '.jpg', '.jpg');
  i: Integer;
  FileName: string;
  DBPath: string;

begin
  try
    WriteLn('正在从数据库提取图像文件...');
    
    // 数据库路径
    DBPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'data.db');
    
    if not TFile.Exists(DBPath) then
    begin
      WriteLn('错误：找不到数据库文件: ' + DBPath);
      Exit;
    end;
    
    // 创建数据库连接
    DB := TSQLiteDatabase.Create(DBPath);
    
    try
      if not DB.Connect then
      begin
        WriteLn('错误：无法连接到数据库');
        Exit;
      end;
      
      WriteLn('数据库连接成功');
      
      // 提取每个图像
      for i := 0 to Length(ImageKeys) - 1 do
      begin
        WriteLn('正在提取: ' + ImageKeys[i]);
        
        if DB.LoadImageData(ImageKeys[i], ImageData) then
        begin
          FileName := ImageKeys[i] + Extensions[i];
          TFile.WriteAllBytes(FileName, ImageData);
          WriteLn('  ✓ 已保存: ' + FileName + ' (' + IntToStr(Length(ImageData)) + ' 字节)');
        end
        else
        begin
          WriteLn('  ✗ 提取失败: ' + ImageKeys[i]);
        end;
      end;
      
      WriteLn('图像提取完成！');
      
    finally
      DB.Free;
    end;
    
  except
    on E: Exception do
      WriteLn('发生异常: ' + E.Message);
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.


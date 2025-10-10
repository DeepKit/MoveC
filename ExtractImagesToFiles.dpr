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
    WriteLn('正在从数据库提取图像文件...');
    
    // 统一使用项目根目录下的数据库（MoveC.db）
    DatabasePath := TImageDatabase.GetProjectDatabasePath;
    
    if not TFile.Exists(DatabasePath) then
    begin
      WriteLn('错误：找不到数据库文件: ' + DatabasePath);
      Exit;
    end;
    
    // 创建数据库连接（FireDAC 封装）
    Database := TImageDatabase.Create(DatabasePath);
    
    try
      if not Database.Connect then
      begin
        WriteLn('错误：无法连接到数据库');
        Exit;
      end;
      
      WriteLn('数据库连接成功');
      
      // 提取每个图像（统一小写键）
      for i := 0 to Length(ImageKeys) - 1 do
      begin
        WriteLn('正在提取: ' + ImageKeys[i]);
        
        if Database.LoadImageData(ImageKeys[i], ImageData) then
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
      Database.Free;
    end;
    
  except
    on E: Exception do
      WriteLn('发生异常: ' + E.Message);
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.

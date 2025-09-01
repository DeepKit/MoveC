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
    Writeln('=== 数据库图像检查工具 ===');
    Writeln;
    
    // 使用项目根目录下的MoveC.db
    DatabasePath := TImageDatabase.GetProjectDatabasePath;
    Writeln('数据库路径: ', DatabasePath);
    
    if not TFile.Exists(DatabasePath) then
    begin
      Writeln('错误: 数据库文件不存在!');
      Exit;
    end;
    
    // 创建并连接数据库
    Database := TImageDatabase.Create(DatabasePath);
    try
      Writeln('正在连接数据库...');
      if not Database.Connect then
      begin
        Writeln('错误: 无法连接到数据库');
        Exit;
      end;
      
      Writeln('数据库连接成功');
      Writeln;
      
      // 检查每个图像
      for I := 0 to High(ImageKeys) do
      begin
        Writeln('检查图像: ', ImageKeys[I]);
        
        if Database.LoadImageAndText(ImageKeys[I], ImageData, AddressText) then
        begin
          Writeln('  ✓ 图像存在');
          Writeln('  - 数据大小: ', Length(ImageData), ' 字节');
          Writeln('  - 地址文本: ', AddressText);
          
          // 保存到文件验证
          TFile.WriteAllBytes('check_' + ImageKeys[I] + '.dat', ImageData);
          Writeln('  - 已保存到: check_', ImageKeys[I], '.dat');
        end
        else
        begin
          Writeln('  ✗ 图像不存在或加载失败');
        end;
        Writeln;
      end;
      
    finally
      Database.Free;
    end;
    
  except
    on E: Exception do
      Writeln('错误: ', E.Message);
  end;
  
  Writeln('按任意键退出...');
  Readln;
end.

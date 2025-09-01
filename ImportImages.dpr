program ImportImages;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Def,
  FireDAC.UI.Intf,
  FireDAC.ConsoleUI.Wait,
  FireDAC.Comp.Client,
  FireDAC.Stan.Pool,
  FireDAC.DApt,
  uImageDatabase,
  uBasicProtection;

procedure ImportImageFile(Database: TImageDatabase; const ImagePath, ImageKey, AddressText: string);
var
  ImageData: TBytes;
  FileStream: TFileStream;
begin
  if not TFile.Exists(ImagePath) then
  begin
    Writeln('错误: 图像文件不存在: ', ImagePath);
    Exit;
  end;

  try
    // 读取图像文件
    FileStream := TFileStream.Create(ImagePath, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(ImageData, FileStream.Size);
      FileStream.ReadBuffer(ImageData[0], FileStream.Size);
    finally
      FileStream.Free;
    end;

    // 保存到数据库（包含地址文本）
    if Database.SaveImageData(ImageKey, ImageData, '从文件导入: ' + ExtractFileName(ImagePath), AddressText) then
    begin
      Writeln('成功导入图像: ', ImageKey, ' (', Length(ImageData), ' 字节, 地址: ', AddressText, ')');
    end
    else
    begin
      Writeln('导入图像失败: ', ImageKey);
    end;

  except
    on E: Exception do
    begin
      Writeln('导入图像时发生异常: ', ImageKey, ' - ', E.Message);
    end;
  end;
end;

var
  Database: TImageDatabase;
  DatabasePath: string;
begin
  try
    Writeln('=== 图像数据导入工具 ===');
    Writeln;

    // 初始化FireDAC（通过简单的方式注册驱动）
    Writeln('初始化FireDAC驱动...');
    // 通过引用单元自动注册SQLite驱动

    // 使用项目根目录下的MoveC.db
    DatabasePath := TImageDatabase.GetProjectDatabasePath;
    Writeln('数据库路径: ', DatabasePath);

    // 创建并连接数据库
    Database := TImageDatabase.Create(DatabasePath);
    try
      Writeln('正在连接数据库...');
      if not Database.Connect then
      begin
        Writeln('错误: 无法连接到数据库');
        Writeln('请检查数据库文件路径是否正确，以及是否有足够的权限');
        Exit;
      end;

      Writeln('数据库连接成功');
      Writeln;

      // 导入各个图像文件和对应的地址文本
      Writeln('开始导入图像文件和地址文本...');

      // 导入assets目录下的图像文件，包含对应的地址文本
      ImportImageFile(Database, 'assets\wechat.png', 'wechat', '微信收款码');
      ImportImageFile(Database, 'assets\AliPay.png', 'alipay', '支付宝收款码');
      ImportImageFile(Database, 'assets\btc.png', 'btc', 'bc1qze0ggsrdtjqwjpjfufydsuyjxc08tgcq5xkct3');
      ImportImageFile(Database, 'assets\usdt.png', 'usdt', 'TH1NazpoEpUqcEotGzLPHs13SbLDJKKCys');
      ImportImageFile(Database, 'assets\itsMe.jpg', 'aboutme', 'C盘瘦身工具 - 开发者: 好记忆管理工作室 - 官网: www.goodmem.cn');
      
      Writeln;
      Writeln('图像导入完成');
      
      // 显示数据库中的图像列表
      var ImageList := Database.GetImageList;
      try
        if ImageList.Count > 0 then
        begin
          Writeln;
          Writeln('数据库中的图像列表:');
          for var i := 0 to ImageList.Count - 1 do
          begin
            Writeln('  - ', ImageList[i]);
          end;
        end;
      finally
        ImageList.Free;
      end;
      
    finally
      Database.Free;
    end;
    
     except
     on E: Exception do
     begin
       Writeln('程序异常: ', E.ClassName, ': ', E.Message);
       Writeln('异常位置: ', E.StackTrace);
     end;
   end;
  
  Writeln;
  Writeln('按回车键退出...');
  Readln;
end.

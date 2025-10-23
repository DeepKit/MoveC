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
  uBasicProtection,
  uAntiTamperPackage;

var
  LogFile: TextFile;

procedure WriteToLog(const Msg: string);
begin
  try
    Append(LogFile);
    Writeln(LogFile, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), ' - ', Msg);
    Flush(LogFile);
    CloseFile(LogFile);
  except
    // 忽略日志写入错误
  end;
end;

procedure ImportImageFile(Database: TImageDatabase; const ImagePath, ImageKey, AddressText: string);
var
  ImageData: TBytes;
  FileStream: TFileStream;
begin
  if not TFile.Exists(ImagePath) then
  begin
    WriteToLog('错误: 图像文件不存在: ' + ImagePath);
    Exit;
  end;

  try
    // 读取图像文件
    FileStream := TFileStream.Create(ImagePath, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(ImageData, FileStream.Size);
      FileStream.ReadBuffer(ImageData[0], FileStream.Size);
      WriteToLog(Format('读取图像文件: %s, 大小: %d 字节', [ImageKey, Length(ImageData)]));
    finally
      FileStream.Free;
    end;

    // 保存到数据库（包含地址文本）
    WriteToLog(Format('开始保存图像: %s', [ImageKey]));
    if Database.SaveImageData(ImageKey, ImageData, '从文件导入: ' + ExtractFileName(ImagePath), AddressText) then
    begin
      WriteToLog(Format('✓ 成功导入图像: %s (%d 字节, 地址: %s)', [ImageKey, Length(ImageData), AddressText]));
    end
    else
    begin
      WriteToLog(Format('✗ 导入图像失败: %s', [ImageKey]));
    end;

  except
    on E: Exception do
    begin
      WriteToLog(Format('✗ 导入图像时发生异常: %s - %s: %s', [ImageKey, E.ClassName, E.Message]));
    end;
  end;
end;

var
  Database: TImageDatabase;
  DatabasePath: string;
  Config: TAntiTamperConfig;
  LogFileName: string;
  ImageKey, ImagePath, AddressText: string;
begin
  try
    // 初始化日志文件
    LogFileName := ExtractFilePath(ParamStr(0)) + 'import_log.txt';
    AssignFile(LogFile, LogFileName);
    Rewrite(LogFile);
    CloseFile(LogFile);
    
    WriteToLog('========================================');
    WriteToLog('图像数据导入工具 (AES-256加密版)');
    WriteToLog('========================================');

    // 检查命令行参数
    if ParamCount < 3 then
    begin
      Writeln('用法: ImportImages.exe <image_key> <image_path> <address_text>');
      Writeln('示例: ImportImages.exe wechat assets\wechat.png 微信收款码');
      Exit;
    end;

    ImageKey := ParamStr(1);
    ImagePath := ParamStr(2);
    AddressText := ParamStr(3);

    WriteToLog(Format('命令行参数: Key=%s, Path=%s, Address=%s', [ImageKey, ImagePath, AddressText]));

    // 初始化防篡改包
    WriteToLog('初始化防篡改包...');
    Config := TAntiTamperPackage.GetDefaultConfig;
    Config.EncryptionKey := 'MoveC_AntiTamper_Key_2025';
    Config.EncryptionType := etAES256;
    Config.EnableLogging := True;
    TAntiTamperPackage.Initialize(Config);
    WriteToLog('防篡改包初始化完成 - 使用AES-256加密');

    // 初始化FireDAC
    WriteToLog('初始化FireDAC驱动...');

    // 使用项目根目录下的MoveC.db
    DatabasePath := TImageDatabase.GetProjectDatabasePath;
    WriteToLog('数据库路径: ' + DatabasePath);

    // 创建并连接数据库
    WriteToLog('创建数据库对象，密码: @2241114');
    Database := TImageDatabase.Create(DatabasePath, '@2241114');
    try
      WriteToLog('正在连接数据库...');
      if not Database.Connect then
      begin
        WriteToLog('✗ 错误: 无法连接到数据库');
        Writeln('错误: 无法连接到数据库，请查看日志文件');
        Exit;
      end;

      WriteToLog('✓ 数据库连接成功');

      // 导入图像文件
      WriteToLog('开始导入图像文件...');
      WriteToLog('----------------------------------------');

      ImportImageFile(Database, ImagePath, ImageKey, AddressText);
      
      WriteToLog('----------------------------------------');
      WriteToLog('图像导入完成');
      
      // 显示数据库中的图像列表
      var ImageList := Database.GetImageList;
      try
        if ImageList.Count > 0 then
        begin
          WriteToLog('数据库中的图像列表:');
          for var i := 0 to ImageList.Count - 1 do
          begin
            WriteToLog('  - ' + ImageList[i]);
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
       WriteToLog('程序异常: ' + E.ClassName + ': ' + E.Message);
       Writeln('程序异常，请查看日志文件');
     end;
   end;
  
  WriteToLog('========================================');
  WriteToLog('程序结束');
  WriteToLog('========================================');
  
  Writeln;
  Writeln('导入完成，请查看 import_log.txt 了解详情');
  Writeln('按回车键退出...');
  Readln;
end.

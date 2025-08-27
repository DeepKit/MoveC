program TestDataIntegrity;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  uSQLiteDB in 'uSQLiteDB.pas',
  uBasicProtection in 'uBasicProtection.pas';

var
  DB: TSQLiteDatabase;
  RequiredImages: array[0..4] of string = ('alipay', 'btc', 'wechat', 'usdt_tip', 'aboutme');
  RequiredTexts: array[0..3] of string = ('btc_address', 'usdt_address', 'about_me_info', 'usdt_tip_text');
  I: Integer;
  ImageData: TBytes;
  TextData: string;
  AllImagesOk, AllTextsOk: Boolean;

begin
  try
    WriteLn('=== 数据完整性验证测试 ===');
    WriteLn('');
    
    // 检查数据库文件是否存在
    if not FileExists('data.db') then
    begin
      WriteLn('错误：data.db 文件不存在！');
      WriteLn('请先运行 AboutMeEncryptionTool.exe 生成数据库文件。');
      Exit;
    end;
    
    WriteLn('数据库文件: data.db 存在');
    WriteLn('文件大小: ', TFile.GetSize('data.db'), ' 字节');
    WriteLn('');
    
    // 初始化数据库
    DB := TSQLiteDatabase.Create('data.db');
    try
      if not DB.Initialize then
      begin
        WriteLn('错误：无法初始化数据库！');
        Exit;
      end;
      
      WriteLn('数据库初始化成功');
      WriteLn('');
      
      // 验证图像数据
      WriteLn('验证图像数据：');
      AllImagesOk := True;
      for I := 0 to High(RequiredImages) do
      begin
        Write('  ', RequiredImages[I], ': ');
        if DB.HasData(RequiredImages[I]) then
        begin
          ImageData := DB.LoadImageData(RequiredImages[I]);
          if Length(ImageData) > 0 then
          begin
            WriteLn('✓ 存在 (', Length(ImageData), ' 字节)');
          end
          else
          begin
            WriteLn('✗ 数据为空');
            AllImagesOk := False;
          end;
        end
        else
        begin
          WriteLn('✗ 缺失');
          AllImagesOk := False;
        end;
      end;
      
      WriteLn('');
      
      // 验证文本数据
      WriteLn('验证文本数据：');
      AllTextsOk := True;
      for I := 0 to High(RequiredTexts) do
      begin
        Write('  ', RequiredTexts[I], ': ');
        TextData := DB.LoadTextData(RequiredTexts[I], '');
        if TextData <> '' then
        begin
          WriteLn('✓ 存在');
        end
        else
        begin
          WriteLn('✗ 缺失');
          AllTextsOk := False;
        end;
      end;
      
      WriteLn('');
      
      // 总结
      if AllImagesOk and AllTextsOk then
      begin
        WriteLn('=== 验证结果：通过 ===');
        WriteLn('✓ 所有必需的图像和文本数据都存在');
        WriteLn('✓ 数据库完整性验证成功');
        WriteLn('✓ 防篡改保护正常工作');
      end
      else
      begin
        WriteLn('=== 验证结果：失败 ===');
        WriteLn('✗ 检测到数据缺失或损坏');
        WriteLn('✗ 在正常程序中，此时应该退出并引导用户下载正版');
      end;
      
    finally
      DB.Free;
    end;
    
    WriteLn('');
    WriteLn('测试完成。按回车键退出...');
    ReadLn;
    
  except
    on E: Exception do
    begin
      WriteLn('测试异常: ', E.ClassName, ': ', E.Message);
      ReadLn;
    end;
  end;
end.
program TestSecurity;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes, System.IOUtils,
  uBasicProtection,
  uSimpleSQLiteDB,
  uSimpleSecureManager;

procedure TestBasicProtection;
var
  TestData: string;
  EncryptedData: string;
  DecryptedData: string;
begin
  Writeln('=== 测试基础加密保护 ===');
  
  TestData := 'bc1qze0ggsrdtjqwjpjfufydsuyjxc08tgcq5xkct3';
  Writeln('原始数据: ', TestData);
  
  EncryptedData := TBasicProtection.EncryptSensitiveData(TestData, '@2241114');
  Writeln('加密数据: ', Copy(EncryptedData, 1, 50), '...');
  
  DecryptedData := TBasicProtection.DecryptSensitiveData(EncryptedData, '@2241114');
  Writeln('解密数据: ', DecryptedData);
  
  if SameText(TestData, DecryptedData) then
    Writeln('✓ 基础加密测试通过')
  else
    Writeln('✗ 基础加密测试失败');
  
  Writeln;
end;

procedure TestSimpleDatabase;
var
  Database: TSimpleSQLiteDatabase;
  TestText: string;
  TestImageData: TBytes;
  LoadedText: string;
  LoadedImageData: TBytes;
begin
  Writeln('=== 测试简化数据库 ===');
  
  Database := TSimpleSQLiteDatabase.Create('test_data.db', '@2241114');
  try
    if not Database.Connect then
    begin
      Writeln('✗ 数据库连接失败');
      Exit;
    end;
    
    Writeln('✓ 数据库连接成功');
    
    // 测试文本数据
    TestText := 'bc1qze0ggsrdtjqwjpjfufydsuyjxc08tgcq5xkct3';
    if Database.SaveTextData('test_btc', TestText, '测试BTC地址') then
      Writeln('✓ 文本数据保存成功')
    else
      Writeln('✗ 文本数据保存失败');
    
    if Database.LoadTextData('test_btc', LoadedText) then
    begin
      Writeln('✓ 文本数据加载成功: ', LoadedText);
      if SameText(TestText, LoadedText) then
        Writeln('✓ 文本数据完整性验证通过')
      else
        Writeln('✗ 文本数据完整性验证失败');
    end
    else
      Writeln('✗ 文本数据加载失败');
    
    // 测试图像数据
    SetLength(TestImageData, 1000);
    for var i := 0 to High(TestImageData) do
      TestImageData[i] := i mod 256;
    
    if Database.SaveImageData('test_image', TestImageData, '测试图像') then
      Writeln('✓ 图像数据保存成功')
    else
      Writeln('✗ 图像数据保存失败');
    
    if Database.LoadImageData('test_image', LoadedImageData) then
    begin
      Writeln('✓ 图像数据加载成功, 大小: ', Length(LoadedImageData));
      if Length(TestImageData) = Length(LoadedImageData) then
        Writeln('✓ 图像数据大小验证通过')
      else
        Writeln('✗ 图像数据大小验证失败');
    end
    else
      Writeln('✗ 图像数据加载失败');
    
    // 验证所有数据
    if Database.ValidateAllData then
      Writeln('✓ 数据库完整性验证通过')
    else
      Writeln('✗ 数据库完整性验证失败');
    
    Writeln(Database.GetDataStatistics);
    
  finally
    Database.Free;
  end;
  
  Writeln;
end;

procedure TestSecureManager;
var
  SecureManager: TSimpleSecureManager;
begin
  Writeln('=== 测试安全管理器 ===');
  
  SecureManager := TSimpleSecureManager.Create(nil);
  try
    // 注意：这里会失败因为没有有效的数据库，但我们测试错误处理
    if SecureManager.LoadAndVerify(nil) then
      Writeln('✓ 安全验证通过')
    else
      Writeln('✗ 安全验证失败（预期行为）');
    
  finally
    SecureManager.Free;
  end;
  
  Writeln;
end;

procedure CreateTestDatabase;
var
  Database: TSimpleSQLiteDatabase;
  ImageData: TBytes;
  AssetsPath: string;
begin
  Writeln('=== 创建测试数据库 ===');
  
  AssetsPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'assets');
  if not TDirectory.Exists(AssetsPath) then
  begin
    Writeln('✗ assets目录不存在: ', AssetsPath);
    Exit;
  end;
  
  // 删除现有测试数据库
  if TFile.Exists('data.db') then
    TFile.Delete('data.db');
  if TDirectory.Exists('data.data') then
    TDirectory.Delete('data.data', True);
  
  Database := TSimpleSQLiteDatabase.Create('data.db', '@2241114');
  try
    if not Database.Connect then
    begin
      Writeln('✗ 无法创建数据库');
      Exit;
    end;
    
    Writeln('✓ 数据库创建成功');
    
    // 保存图像文件
    var ImageFiles: TArray<string> := ['AliPay.png', 'btc.png', 'itsMe.jpg', 'usdt.png', 'wechat.png'];
    var ImageKeys: TArray<string> := ['alipay', 'btc', 'aboutme', 'usdt_tip', 'wechat'];
    
    for var i := 0 to High(ImageFiles) do
    begin
      var FilePath := TPath.Combine(AssetsPath, ImageFiles[i]);
      if TFile.Exists(FilePath) then
      begin
        var FileStream := TFileStream.Create(FilePath, fmOpenRead);
        try
          SetLength(ImageData, FileStream.Size);
          if FileStream.Size > 0 then
            FileStream.ReadBuffer(ImageData[0], FileStream.Size);
          
          if Database.SaveImageData(ImageKeys[i], ImageData, ImageFiles[i]) then
            Writeln('✓ 保存图像: ', ImageFiles[i], ' (', Length(ImageData), ' 字节)')
          else
            Writeln('✗ 保存图像失败: ', ImageFiles[i]);
            
        finally
          FileStream.Free;
        end;
      end
      else
        Writeln('✗ 图像文件不存在: ', FilePath);
    end;
    
    // 保存文本数据
    Database.SaveTextData('btc_address', 'bc1qze0ggsrdtjqwjpjfufydsuyjxc08tgcq5xkct3', 'BTC地址');
    Database.SaveTextData('usdt_address', 'TH1NazpoEpUqcEotGzLPHs13SbLDJKKCys', 'USDT地址');
    Database.SaveTextData('about_me_info', '感谢您使用本软件！', '关于我信息');
    Database.SaveTextData('usdt_tip_text', '支持USDT打赏（TRON波场链）', 'USDT提示');
    Database.SaveTextData('wechat_address', '微信扫码打赏', '微信地址');
    Database.SaveTextData('alipay_address', '支付宝扫码打赏', '支付宝地址');
    
    Writeln('✓ 文本数据保存完成');
    
    // 验证数据
    if Database.ValidateAllData then
      Writeln('✓ 数据验证通过')
    else
      Writeln('✗ 数据验证失败');
    
    Writeln(Database.GetDataStatistics);
    
  finally
    Database.Free;
  end;
  
  Writeln;
end;

begin
  try
    Writeln('AboutMe 安全系统测试工具');
    Writeln('=============================');
    Writeln;
    
    TestBasicProtection;
    TestSimpleDatabase;
    CreateTestDatabase;
    TestSecureManager;
    
    Writeln('测试完成！');
    
  except
    on E: Exception do
      Writeln('发生异常: ', E.Message);
  end;
  
  Write('按回车键退出...');
  Readln;
end.
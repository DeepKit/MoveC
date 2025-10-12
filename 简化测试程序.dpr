program TestEncryption;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  uBasicProtection;

var
  TestData, Encrypted, Decrypted: TBytes;
  Password: string;
  i: Integer;
begin
  try
    Writeln('=== AES-256 加密测试 ===');
    Writeln;
    
    // 创建测试数据
    SetLength(TestData, 1000);
    for i := 0 to 999 do
      TestData[i] := Byte(i mod 256);
    
    Password := '@2241114';
    
    Writeln('原始数据大小: ', Length(TestData), ' 字节');
    Writeln('密码: ', Password);
    Writeln;
    
    // 测试加密
    Writeln('开始加密...');
    try
      Encrypted := TBasicProtection.EncryptBinaryData(TestData, Password);
      Writeln('✓ 加密成功');
      Writeln('加密后大小: ', Length(Encrypted), ' 字节');
    except
      on E: Exception do
      begin
        Writeln('✗ 加密失败: ', E.Message);
        Readln;
        Exit;
      end;
    end;
    
    Writeln;
    
    // 测试解密
    Writeln('开始解密...');
    try
      Decrypted := TBasicProtection.DecryptBinaryData(Encrypted, Password);
      Writeln('✓ 解密成功');
      Writeln('解密后大小: ', Length(Decrypted), ' 字节');
    except
      on E: Exception do
      begin
        Writeln('✗ 解密失败: ', E.Message);
        Readln;
        Exit;
      end;
    end;
    
    Writeln;
    
    // 验证数据
    Writeln('验证数据...');
    if Length(TestData) = Length(Decrypted) then
    begin
      var Match := True;
      for i := 0 to Length(TestData) - 1 do
      begin
        if TestData[i] <> Decrypted[i] then
        begin
          Match := False;
          Break;
        end;
      end;
      
      if Match then
        Writeln('✓ 数据完全匹配')
      else
        Writeln('✗ 数据不匹配');
    end
    else
      Writeln('✗ 数据长度不匹配');
    
    Writeln;
    Writeln('=== 测试完成 ===');
    
  except
    on E: Exception do
      Writeln('程序异常: ', E.Message);
  end;
  
  Writeln;
  Writeln('按回车键退出...');
  Readln;
end.

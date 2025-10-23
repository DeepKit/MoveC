program TestDecrypt;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs,
  Data.DB,
  FireDAC.Comp.Client,
  uBasicProtection in 'uBasicProtection.pas';

var
  Connection: TFDConnection;
  Query: TFDQuery;
  EncryptedData, DecryptedData: TBytes;
  MemStream: TMemoryStream;
begin
  try
    Writeln('=== 测试数据库图像解密 ===');
    Writeln;
    
    // 创建连接
    Connection := TFDConnection.Create(nil);
    Query := TFDQuery.Create(nil);
    try
      Connection.DriverName := 'SQLite';
      Connection.Params.Values['Database'] := 'MoveC.db';
      Connection.Connected := True;
      
      Writeln('✓ 数据库连接成功');
      Writeln;
      
      Query.Connection := Connection;
      Query.SQL.Text := 'SELECT image_key, image_data FROM images WHERE image_key = ''wechat''';
      Query.Open;
      
      if not Query.Eof then
      begin
        Writeln('✓ 找到wechat记录');
        
        // 读取加密数据
        MemStream := TMemoryStream.Create;
        try
          TBlobField(Query.FieldByName('image_data')).SaveToStream(MemStream);
          SetLength(EncryptedData, MemStream.Size);
          MemStream.Position := 0;
          MemStream.ReadBuffer(EncryptedData[0], MemStream.Size);
          
          Writeln('加密数据大小: ', Length(EncryptedData), ' bytes');
          Writeln('前16字节 (IV): ', 
            Format('%02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X',
            [EncryptedData[0], EncryptedData[1], EncryptedData[2], EncryptedData[3],
             EncryptedData[4], EncryptedData[5], EncryptedData[6], EncryptedData[7],
             EncryptedData[8], EncryptedData[9], EncryptedData[10], EncryptedData[11],
             EncryptedData[12], EncryptedData[13], EncryptedData[14], EncryptedData[15]]));
          Writeln;
          
          // 测试解密
          Writeln('开始解密（密码: @2241114）...');
          try
            DecryptedData := TBasicProtection.DecryptBinaryData(EncryptedData, '@2241114');
            Writeln('✓ 解密成功');
            Writeln('解密数据大小: ', Length(DecryptedData), ' bytes');
            Writeln('前4字节: ', 
              Format('%02X %02X %02X %02X',
              [DecryptedData[0], DecryptedData[1], DecryptedData[2], DecryptedData[3]]));
            
            // 检查PNG文件头
            if (Length(DecryptedData) >= 4) and 
               (DecryptedData[0] = $89) and 
               (DecryptedData[1] = $50) and 
               (DecryptedData[2] = $4E) and 
               (DecryptedData[3] = $47) then
              Writeln('✓ PNG文件头正确')
            else
              Writeln('✗ PNG文件头不正确');
              
          except
            on E: Exception do
              Writeln('✗ 解密失败: ', E.Message);
          end;
          
        finally
          MemStream.Free;
        end;
      end
      else
        Writeln('✗ 未找到wechat记录');
        
    finally
      Query.Free;
      Connection.Free;
    end;
    
  except
    on E: Exception do
      Writeln('错误: ', E.Message);
  end;
  
  Writeln;
  Writeln('按回车键退出...');
  Readln;
end.

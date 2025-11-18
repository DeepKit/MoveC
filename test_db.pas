program test_db;

uses
  System.SysUtils,
  System.IOUtils,
  FireDAC.Comp.Client,
  FireDAC.Stan.Def,
  FireDAC.Phys.SQLite;

var
  Conn: TFDConnection;
begin
  try
    Conn := TFDConnection.Create(nil);
    try
      Conn.DriverName := 'SQLite';
      Conn.Params.Values['Database'] := 'MoveC.db';
      Conn.LoginPrompt := False;
      Conn.Connected := True;
      WriteLn('数据库连接成功');
      Conn.Connected := False;
    finally
      Conn.Free;
    end;
  except
    on E: Exception do
      WriteLn('数据库连接失败: ' + E.Message);
  end;
end.

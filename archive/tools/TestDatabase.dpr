program TestDatabase;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Def,
  FireDAC.UI.Intf,
  FireDAC.ConsoleUI.Wait;

var
  Connection: TFDConnection;
  Query: TFDQuery;
begin
  try
    Writeln('Testing database creation...');
    
    Connection := TFDConnection.Create(nil);
    try
      Connection.DriverName := 'SQLite';
      Connection.Params.Clear;
      Connection.Params.Add('DriverID=SQLite');
      Connection.Params.Add('Database=TestDB.db');
      Connection.Params.Add('OpenMode=CreateUTF8');
      
      Writeln('Connecting to database...');
      Connection.Connected := True;
      Writeln('Database connected successfully!');
      
      Query := TFDQuery.Create(nil);
      try
        Query.Connection := Connection;
        Query.SQL.Text := 'CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY, name TEXT)';
        Query.ExecSQL;
        Writeln('Table created successfully!');
        
        Query.SQL.Text := 'INSERT INTO test (name) VALUES (''Test'')';
        Query.ExecSQL;
        Writeln('Data inserted successfully!');
      finally
        Query.Free;
      end;
      
      Connection.Connected := False;
      Writeln('Database test completed successfully!');
    finally
      Connection.Free;
    end;
    
  except
    on E: Exception do
    begin
      Writeln('ERROR: ', E.ClassName, ': ', E.Message);
    end;
  end;
  
  Writeln('Press Enter to exit...');
  Readln;
end.


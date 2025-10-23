program CreateDB;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  FireDAC.Phys.SQLite,
  FireDAC.Stan.Def,
  FireDAC.DApt;

var
  Connection: TFDConnection;
  Query: TFDQuery;
begin
  try
    Writeln('Creating MoveC.db database...');
    
    Connection := TFDConnection.Create(nil);
    try
      Connection.DriverName := 'SQLite';
      Connection.Params.Values['Database'] := 'MoveC.db';
      
      Writeln('Connecting...');
      Connection.Connected := True;
      Writeln('Connected!');
      
      Query := TFDQuery.Create(nil);
      try
        Query.Connection := Connection;
        
        Writeln('Creating donation_images table...');
        Query.SQL.Text := 
          'CREATE TABLE IF NOT EXISTS donation_images (' +
          '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
          '  image_key TEXT UNIQUE NOT NULL,' +
          '  image_data BLOB NOT NULL,' +
          '  md5_hash TEXT,' +
          '  address_text TEXT,' +
          '  description TEXT,' +
          '  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,' +
          '  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP' +
          ')';
        Query.ExecSQL;
        Writeln('Table created successfully!');
        
      finally
        Query.Free;
      end;
      
      Connection.Connected := False;
      Writeln('Database created successfully!');
    finally
      Connection.Free;
    end;
    
  except
    on E: Exception do
      Writeln('ERROR: ', E.Message);
  end;
  
  Writeln('Press Enter...');
  Readln;
end.


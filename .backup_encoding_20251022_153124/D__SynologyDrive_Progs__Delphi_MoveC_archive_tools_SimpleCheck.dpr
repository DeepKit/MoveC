program SimpleCheck;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  FireDAC.Phys.SQLite,
  FireDAC.Stan.Def;

var
  Conn: TFDConnection;
  Query: TFDQuery;
begin
  try
    Writeln('Checking database...');
    
    Conn := TFDConnection.Create(nil);
    try
      Conn.DriverName := 'SQLite';
      Conn.Params.Values['Database'] := 'MoveC.db';
      Conn.Connected := True;
      
      Query := TFDQuery.Create(nil);
      try
        Query.Connection := Conn;
        Query.SQL.Text := 'SELECT image_key, length(image_data) as size FROM donation_images ORDER BY image_key';
        Query.Open;
        
        Writeln('Records in database:');
        while not Query.Eof do
        begin
          Writeln(Format('  %s: %d bytes', [Query.FieldByName('image_key').AsString, Query.FieldByName('size').AsInteger]));
          Query.Next;
        end;
        
        Writeln('Total records: ', Query.RecordCount);
      finally
        Query.Free;
      end;
    finally
      Conn.Free;
    end;
    
  except
    on E: Exception do
      Writeln('ERROR: ', E.Message);
  end;
  
  Writeln('Press Enter...');
  Readln;
end.

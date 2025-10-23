program CountRecords;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Def,
  FireDAC.Stan.Intf,
  FireDAC.UI.Intf,
  FireDAC.ConsoleUI.Wait,
  FireDAC.DApt;

var
  Conn: TFDConnection;
  Query: TFDQuery;
begin
  Conn := TFDConnection.Create(nil);
  try
    Conn.DriverName := 'SQLite';
    Conn.Params.Clear;
    Conn.Params.Add('DriverID=SQLite');
    Conn.Params.Add('Database=MoveC.db');
    Conn.Connected := True;
    
    Query := TFDQuery.Create(nil);
    try
      Query.Connection := Conn;
      Query.SQL.Text := 'SELECT image_key, length(image_data) as size FROM donation_images';
      Query.Open;
      
      Writeln('Records in database:');
      while not Query.Eof do
      begin
        Writeln('  ', Query.FieldByName('image_key').AsString, ': ', Query.FieldByName('size').AsInteger, ' bytes');
        Query.Next;
      end;
      Writeln('Total: ', Query.RecordCount, ' records');
    finally
      Query.Free;
    end;
  finally
    Conn.Free;
  end;
  
  Readln;
end.


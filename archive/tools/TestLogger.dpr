program TestLogger;

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.IOUtils, System.Classes;

procedure Log(const Msg: string);
var
  LogFileName: string;
  Writer: TStreamWriter;
begin
  try
    LogFileName := ExtractFilePath(ParamStr(0)) + 'test_log.txt';
    if FileExists(LogFileName) then
      DeleteFile(LogFileName);

    Writer := TStreamWriter.Create(LogFileName, False, TEncoding.Unicode);
    try
      Writer.WriteLine(Format('[%s] %s', [DateTimeToStr(Now), Msg]));
      Writeln('Log file written to: ', LogFileName);
    finally
      Writer.Free;
    end;
  except
    on E: Exception do
      Writeln('Error writing log: ', E.Message);
  end;
end;

begin
  try
    Log('浣犲ソ锛屼笘鐣?- Hello, World!');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Writeln('Press Enter to exit.');
  Readln;
end.


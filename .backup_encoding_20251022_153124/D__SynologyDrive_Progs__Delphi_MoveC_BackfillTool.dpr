program BackfillTool;
{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  uImageDatabase;

// 用法：
// BackfillTool.exe [maxCount]
//  - maxCount 可选，默认处理全部；如指定数字则最多处理该数量的记录。
// 注意：执行前请关闭 Navicat/应用，避免数据库被占用（database is locked）。

var
  DBPath: string;
  Password: string;
  MaxCount: Integer;
  ImgDB: TImageDatabase;
  Processed: Integer;
begin
  Password := '@2241114';
  MaxCount := 0;
  if ParamCount >= 1 then
  begin
    try
      MaxCount := StrToInt(ParamStr(1));
    except
      on E: Exception do
      begin
        Writeln('参数 maxCount 非法，忽略并处理全部。详情：', E.Message);
        MaxCount := 0;
      end;
    end;
  end;

  try
    // 由库函数自动计算项目根目录下的 MoveC.db 路径
    DBPath := TImageDatabase.GetProjectDatabasePath;
    Writeln('数据库：', DBPath);

    ImgDB := TImageDatabase.Create(DBPath, Password);
    try
      if not ImgDB.Connect then
      begin
        Writeln('连接数据库失败');
        Halt(1);
      end;

      Writeln('开始回填（maxCount=', MaxCount, ') ...');
      Processed := ImgDB.BackfillLegacyHMACSalt(MaxCount);
      Writeln('回填完成，成功条数：', Processed);

      ImgDB.Disconnect;
    finally
      ImgDB.Free;
    end;
  except
    on E: Exception do
    begin
      Writeln('发生异常：', E.ClassName, ' - ', E.Message);
      Halt(2);
    end;
  end;
end.

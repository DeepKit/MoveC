unit uDatabaseConfig;

interface

uses
  System.SysUtils, System.IOUtils;

type
  TDatabaseConfig = class
  public
    /// <summary>
    /// 获取应该使用的数据库路径
    /// 如果程序是 syncLocal.exe，返回 syncLocal.db
    /// 如果程序是 MoveC.exe 或其他，返回 MoveC.db
    /// </summary>
    class function GetDatabasePath: string;
    
    /// <summary>
    /// 判断当前程序是否为 syncLocal
    /// </summary>
    class function IsSyncLocalProgram: Boolean;
    
    /// <summary>
    /// 获取当前程序的完整路径
    /// </summary>
    class function GetProgramPath: string;
    
    /// <summary>
    /// 获取程序执行目录
    /// </summary>
    class function GetProgramDir: string;
  end;

implementation

class function TDatabaseConfig.GetProgramPath: string;
begin
  Result := ParamStr(0);
end;

class function TDatabaseConfig.GetProgramDir: string;
begin
  Result := TPath.GetDirectoryName(GetProgramPath);
end;

class function TDatabaseConfig.IsSyncLocalProgram: Boolean;
var
  ExeName: string;
begin
  ExeName := TPath.GetFileName(GetProgramPath).ToLower;
  Result := (ExeName = 'synclocal.exe') or (ExeName = 'synclocal.rar');
end;

class function TDatabaseConfig.GetDatabasePath: string;
begin
  if IsSyncLocalProgram then
    Result := TPath.Combine(GetProgramDir, 'syncLocal.db')
  else
    Result := TPath.Combine(GetProgramDir, 'MoveC.db');
end;

end.

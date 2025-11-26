unit uRestartManager;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, Winapi.Windows;

type
  TRmProcessInfo = record
    ProcessId: DWORD;
    AppName: string;
    ServiceShortName: string;
  end;

  TRestartManager = class
  public
    class function GetLockingProcesses(const Paths: TArray<string>): TArray<TRmProcessInfo>;
    class function PromptAndShutdown(const Paths: TArray<string>): Boolean;
  end;

implementation

uses
  Winapi.PsAPI, Vcl.Dialogs, frmLockingProcesses;

const
  RmRebootReasonNone = 0;

type
  RmUniqueProcess = record
    dwProcessId: DWORD;
    ProcessStartTime: TFileTime;
  end;

  RM_APP_TYPE = (
    RmUnknownApp   = 0,
    RmMainWindow   = 1,
    RmOtherWindow  = 2,
    RmService      = 3,
    RmExplorer     = 4,
    RmConsole      = 5,
    RmCritical     = 1000
  );

  RmProcessInfo = record
    Process: RmUniqueProcess;
    strAppName: array[0..255] of WideChar;
    strServiceShortName: array[0..63] of WideChar;
    ApplicationType: RM_APP_TYPE;
    AppStatus: ULONG;
    TSSessionId: DWORD;
    bRestartable: BOOL;
  end;

function RmStartSession(var pSessionHandle: DWORD; dwSessionFlags: DWORD; strSessionKey: PWideChar): DWORD; stdcall; external 'Rstrtmgr.dll';
function RmEndSession(dwSessionHandle: DWORD): DWORD; stdcall; external 'Rstrtmgr.dll';
function RmRegisterResources(dwSessionHandle: DWORD; nFiles: UINT; rgsFilenames: PPWideChar; nApplications: UINT; rgApplications: Pointer; nServices: UINT; rgsServiceNames: PPWideChar): DWORD; stdcall; external 'Rstrtmgr.dll';
function RmGetList(dwSessionHandle: DWORD; var pnProcInfoNeeded: UINT; var pnProcInfo: UINT; rgAffectedApps: PRmProcessInfo; var lpdwRebootReasons: DWORD): DWORD; stdcall; external 'Rstrtmgr.dll';
function RmShutdown(dwSessionHandle: DWORD; lActionFlags: ULONG; fnStatus: Pointer): DWORD; stdcall; external 'Rstrtmgr.dll';

class function TRestartManager.GetLockingProcesses(const Paths: TArray<string>): TArray<TRmProcessInfo>;
var
  Session: DWORD;
  Key: array[0..RM_SESSION_KEY_LEN] of WideChar;
  WidePaths: array of PWideChar;
  I: Integer;
  Needed, Count: UINT;
  Reasons: DWORD;
  Infos: array of RmProcessInfo;
  ResultList: TList<TRmProcessInfo>;
  Info: TRmProcessInfo;
  Status: DWORD;
const
  CKey: PWideChar = 'MoveC_RM_Session';
begin
  SetLength(Result, 0);
  ResultList := TList<TRmProcessInfo>.Create;
  try
    Session := 0;
    Status := RmStartSession(Session, 0, CKey);
    if Status <> 0 then Exit;
    try
      SetLength(WidePaths, Length(Paths));
      for I := 0 to High(Paths) do
        WidePaths[I] := PWideChar(WideString(Paths[I]));
      Status := RmRegisterResources(Session, Length(WidePaths), @WidePaths[0], 0, nil, 0, nil);
      if Status <> 0 then Exit;

      Needed := 0;
      Count := 0;
      Reasons := 0;
      Status := RmGetList(Session, Needed, Count, nil, Reasons);
      if (Status = ERROR_MORE_DATA) and (Needed > 0) then
      begin
        SetLength(Infos, Needed);
        Count := Needed;
        Status := RmGetList(Session, Needed, Count, @Infos[0], Reasons);
        if Status = 0 then
        begin
          for I := 0 to Count - 1 do
          begin
            Info.ProcessId := Infos[I].Process.dwProcessId;
            Info.AppName := Infos[I].strAppName;
            Info.ServiceShortName := Infos[I].strServiceShortName;
            ResultList.Add(Info);
          end;
        end;
      end;
      Result := ResultList.ToArray;
    finally
      RmEndSession(Session);
    end;
  finally
    ResultList.Free;
  end;
end;

class function TRestartManager.PromptAndShutdown(const Paths: TArray<string>): Boolean;
var
  Procs: TArray<TRmProcessInfo>;
  Msg: string;
  I: Integer;
  Session: DWORD;
  Status: DWORD;
  Items: TArray<string>;
const
  CKey: PWideChar = 'MoveC_RM_Session';
begin
  Result := False;
  Procs := GetLockingProcesses(Paths);
  if Length(Procs) = 0 then Exit(True);

  SetLength(Items, Length(Procs));
  for I := 0 to High(Procs) do
    Items[I] := Format('[%d] %s', [Procs[I].ProcessId, Procs[I].AppName]);

  if TfrmLockingProcesses.ConfirmClose(Items) then
  begin
    // 启动新会话并直接关闭占用进程
    Session := 0;
    Status := RmStartSession(Session, 0, CKey);
    if Status <> 0 then Exit(False);
    try
      // 只需注册路径
      var WidePaths: array of PWideChar;
      SetLength(WidePaths, Length(Paths));
      for I := 0 to High(Paths) do
        WidePaths[I] := PWideChar(WideString(Paths[I]));
      Status := RmRegisterResources(Session, Length(WidePaths), @WidePaths[0], 0, nil, 0, nil);
      if Status <> 0 then Exit(False);
      // 关停进程（不强制重启应用，可根据需要拓展）
      Status := RmShutdown(Session, 0, nil);
      Result := (Status = 0);
    finally
      RmEndSession(Session);
    end;
  end
  else
    Result := False;
end;

end.

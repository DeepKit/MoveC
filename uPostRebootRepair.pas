unit uPostRebootRepair;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils;

type
  TPostRebootRepair = class
  public
    class procedure Run;
  end;

implementation

uses
  System.IniFiles, Winapi.Windows;

const
  TXN_FILE = 'MoveC.migration.ini';

function CreateDirectoryJunction(const LinkPath, TargetPath: string): Boolean;
const
  FILE_FLAG_OPEN_REPARSE_POINT = $00200000;
  FSCTL_SET_REPARSE_POINT = $000900A4;
  IO_REPARSE_TAG_MOUNT_POINT = $A0000003;
type
  TREPARSE_DATA_BUFFER = packed record
    ReparseTag: Cardinal;
    ReparseDataLength: Word;
    Reserved: Word;
    SubstituteNameOffset: Word;
    SubstituteNameLength: Word;
    PrintNameOffset: Word;
    PrintNameLength: Word;
    PathBuffer: array[0..(MAX_PATH * 2) - 1] of WideChar;
  end;
var
  h: THandle;
  Data: TREPARSE_DATA_BUFFER;
  BytesReturned: DWORD;
  Target, Prefix, Substitute: UnicodeString;
begin
  Result := False;
  try
    if TDirectory.Exists(LinkPath) then
      TDirectory.Delete(LinkPath);
  except
    // 忽略
  end;
  if not TDirectory.Exists(ExtractFileDir(LinkPath)) then
    TDirectory.CreateDirectory(ExtractFileDir(LinkPath));
  if not CreateDirectory(PChar(LinkPath), nil) then Exit(False);

  h := CreateFile(PChar(LinkPath), GENERIC_WRITE, 0, nil, OPEN_EXISTING,
                  FILE_FLAG_BACKUP_SEMANTICS or FILE_FLAG_OPEN_REPARSE_POINT, 0);
  if h = INVALID_HANDLE_VALUE then Exit(False);
  try
    ZeroMemory(@Data, SizeOf(Data));
    Data.ReparseTag := IO_REPARSE_TAG_MOUNT_POINT;
    Prefix := '\\?\';
    Target := Prefix + ExcludeTrailingPathDelimiter(TargetPath);
    Substitute := Target + #0#0;
    Move(PWideChar(Substitute)^, Data.PathBuffer[0], Length(Substitute) * SizeOf(WideChar));
    Data.SubstituteNameOffset := 0;
    Data.SubstituteNameLength := (Length(Target) * SizeOf(WideChar));
    Data.PrintNameOffset := Data.SubstituteNameLength + SizeOf(WideChar);
    Data.PrintNameLength := 0;
    Data.ReparseDataLength := Data.SubstituteNameLength + SizeOf(WideChar) + 8;

    Result := DeviceIoControl(h, FSCTL_SET_REPARSE_POINT, @Data,
                              Data.ReparseDataLength + 8, nil, 0, BytesReturned, nil);
  finally
    CloseHandle(h);
  end;
end;

class procedure TPostRebootRepair.Run;
var
  Root: string;
  TxnPath: string;
  Ini: TIniFile;
  Sections: TStringList;
  I: Integer;
  State, SrcRoot, DstRoot: string;
  QuarantineDir: string;
begin
  try
    Root := ExtractFilePath(ParamStr(0));
    TxnPath := TPath.Combine(Root, TXN_FILE);
    if not TFile.Exists(TxnPath) then Exit;

    Ini := TIniFile.Create(TxnPath);
    Sections := TStringList.Create;
    try
      Ini.ReadSections(Sections);
      for I := 0 to Sections.Count - 1 do
      begin
        State := Ini.ReadString(Sections[I], 'state', '');
        SrcRoot := Ini.ReadString(Sections[I], 'src_root', '');
        DstRoot := Ini.ReadString(Sections[I], 'dst_root', '');
        QuarantineDir := Ini.ReadString(Sections[I], 'quarantine', '');

        // 若状态为 pending_finalize，尝试清理隔离区；若源根已清空则尝试创建联接
        if SameText(State, 'pending_finalize') then
        begin
          try
            if (QuarantineDir <> '') and TDirectory.Exists(QuarantineDir) and TDirectory.IsEmpty(QuarantineDir) then
              TDirectory.Delete(QuarantineDir);
          except
            // 忽略
          end;
          // 如果源根目录存在且为空，尝试创建联接
          if (SrcRoot <> '') and (DstRoot <> '') then
          begin
            try
              if TDirectory.Exists(SrcRoot) and TDirectory.IsEmpty(SrcRoot) then
              begin
                TDirectory.Delete(SrcRoot);
                if CreateDirectoryJunction(SrcRoot, DstRoot) then
                  Ini.WriteString(Sections[I], 'state', 'completed');
              end;
            except
              // 忽略
            end;
          end;
        end;

        // 若状态为 needs_junction，尝试创建联接
        if SameText(State, 'needs_junction') then
        begin
          if (SrcRoot <> '') and (DstRoot <> '') then
          begin
            try
              if TDirectory.Exists(SrcRoot) then
                TDirectory.Delete(SrcRoot);
              if CreateDirectoryJunction(SrcRoot, DstRoot) then
                Ini.WriteString(Sections[I], 'state', 'completed');
            except
              // 忽略
            end;
          end;
        end;
      end;
    finally
      Sections.Free;
      Ini.Free;
    end;
  except
    // 静默，不阻碍程序启动
  end;
end;

end.

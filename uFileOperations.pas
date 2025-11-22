unit uFileOperations;

interface

uses
  Winapi.Windows, Winapi.ShellAPI, System.SysUtils, System.IOUtils;

function DeleteFileToRecycleBin(const FilePath: string): Boolean;
function CreateHardLinkSafeReplace(const LinkFileName, ExistingFileName: string): Boolean;
function SameVolume(const Path1, Path2: string): Boolean;

implementation

function DeleteFileToRecycleBin(const FilePath: string): Boolean;
var
  FileOp: TSHFileOpStruct;
  Buffer: array[0..MAX_PATH] of Char;
begin
  FillChar(Buffer, SizeOf(Buffer), 0);
  StrPCopy(Buffer, FilePath + #0#0);
  
  FillChar(FileOp, SizeOf(FileOp), 0);
  FileOp.Wnd := 0;
  FileOp.wFunc := FO_DELETE;
  FileOp.pFrom := @Buffer[0];
  FileOp.fFlags := FOF_ALLOWUNDO or FOF_NOCONFIRMATION or FOF_SILENT;
  
  Result := (SHFileOperation(FileOp) = 0);
end;

function CreateHardLinkSafeReplace(const LinkFileName, ExistingFileName: string): Boolean;
begin
  // 删除现有文件
  if TFile.Exists(LinkFileName) then
    TFile.Delete(LinkFileName);
    
  // 创建硬链接
  Result := CreateHardLink(PChar(LinkFileName), PChar(ExistingFileName), nil);
  
  if not Result then
  begin
    // 如果硬链接失败，尝试复制文件
    try
      TFile.Copy(ExistingFileName, LinkFileName, True);
      Result := True;
    except
      Result := False;
    end;
  end;
end;

function SameVolume(const Path1, Path2: string): Boolean;
var
  Drive1, Drive2: string;
begin
  Drive1 := ExtractFileDrive(Path1);
  Drive2 := ExtractFileDrive(Path2);
  Result := SameText(Drive1, Drive2);
end;

end.

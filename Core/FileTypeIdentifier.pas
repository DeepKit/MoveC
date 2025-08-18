unit FileTypeIdentifier;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DataTypes;

type
  TFileTypeIdentifier = class
  private
    // 私有方法
  public
    constructor Create;
    destructor Destroy; override;

    // 文件类型识别
    function IdentifyFileType(const AFilePath: string): TFileType;
    function GetFileCategory(const AFilePath: string): string;
    function IsExecutableFile(const AFilePath: string): Boolean;
    function IsSystemFile(const AFilePath: string): Boolean;
  end;

implementation

constructor TFileTypeIdentifier.Create;
begin
  inherited Create;
end;

destructor TFileTypeIdentifier.Destroy;
begin
  inherited Destroy;
end;

function TFileTypeIdentifier.IdentifyFileType(const AFilePath: string): TFileType;
var
  Ext: string;
begin
  Result := ftUnknown;

  if not TFile.Exists(AFilePath) then
    Exit;

  Ext := LowerCase(ExtractFileExt(AFilePath));

  if (Ext = '.exe') or (Ext = '.dll') or (Ext = '.sys') then
    Result := ftExecutable
  else if (Ext = '.txt') or (Ext = '.log') or (Ext = '.ini') then
    Result := ftText
  else if (Ext = '.jpg') or (Ext = '.png') or (Ext = '.bmp') then
    Result := ftImage
  else if (Ext = '.mp3') or (Ext = '.wav') or (Ext = '.mp4') then
    Result := ftMedia
  else if (Ext = '.doc') or (Ext = '.pdf') or (Ext = '.xls') then
    Result := ftDocument;
end;

function TFileTypeIdentifier.GetFileCategory(const AFilePath: string): string;
begin
  case IdentifyFileType(AFilePath) of
    ftExecutable: Result := 'Executable';
    ftText: Result := 'Text';
    ftImage: Result := 'Image';
    ftMedia: Result := 'Media';
    ftDocument: Result := 'Document';
    else Result := 'Unknown';
  end;
end;

function TFileTypeIdentifier.IsExecutableFile(const AFilePath: string): Boolean;
begin
  Result := IdentifyFileType(AFilePath) = ftExecutable;
end;

function TFileTypeIdentifier.IsSystemFile(const AFilePath: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(AFilePath));
  Result := (Ext = '.sys') or (Ext = '.dll') or
            (Pos('system32', LowerCase(AFilePath)) > 0) or
            (Pos('windows', LowerCase(AFilePath)) > 0);
end;

end.
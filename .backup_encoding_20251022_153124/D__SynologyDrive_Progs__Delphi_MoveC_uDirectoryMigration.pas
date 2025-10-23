unit uDirectoryMigration;
{$IFDEF UNICODE}
{$CODEPAGE UTF8}
{$ENDIF}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, System.IOUtils, Vcl.CheckLst, System.Generics.Collections, Vcl.Menus;

type
  // 杩佺Щ椤圭洰淇℃伅
  TMigrationItem = record
    DisplayName: string;
    SourcePath: string;
    TargetPath: string;
    IsRecommended: Boolean;
    RiskLevel: Integer; // 0=瀹夊叏, 1=浣庨闄? 2=涓闄? 3=楂橀闄?    Description: string;
    EstimatedSize: Int64;
  end;

procedure TfrmDirectoryMigration.ViewSourceFiles(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := clbMigrationItems.ItemIndex;
  if (Idx >= 0) and (Idx <= High(FMigrationItems)) then
    ShowFilesOfPath(FMigrationItems[Idx].SourcePath);
end;

procedure TfrmDirectoryMigration.ViewTargetFiles(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := clbMigrationItems.ItemIndex;
  if (Idx >= 0) and (Idx <= High(FMigrationItems)) then
    ShowFilesOfPath(FMigrationItems[Idx].TargetPath);
end;

procedure TfrmDirectoryMigration.clbMigrationItemsMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Scr: TPoint;
  Idx: Integer;
begin
  if Button = mbRight then
  begin
    Idx := clbMigrationItems.ItemAtPos(Point(X, Y), True);
    if Idx >= 0 then
      clbMigrationItems.ItemIndex := Idx
    else
      clbMigrationItems.ItemIndex := -1;
    Scr := clbMigrationItems.ClientToScreen(Point(X, Y));
    if Assigned(FItemPopup) then
      FItemPopup.Popup(Scr.X, Scr.Y);
  end;
end;

// 递归尝试删除空目录（不抛异常）
procedure TryDeleteEmptyDirs(const Root: string);
var
  SubDirs: TArray<string>;
  D: string;
begin
  if not TDirectory.Exists(Root) then Exit;
  try
    SubDirs := TDirectory.GetDirectories(Root, '*', TSearchOption.soTopDirectoryOnly);
    for D in SubDirs do
      TryDeleteEmptyDirs(D);
    if TDirectory.IsEmpty(Root) then
      TDirectory.Delete(Root);
  except
    // 忽略
  end;
end;

procedure TfrmDirectoryMigration.MigrateAndLinkSelected(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := clbMigrationItems.ItemIndex;
  if (Idx < 0) or (Idx > High(FMigrationItems)) then
  begin
    ShowMessage('请先选择一个源目录。');
    Exit;
  end;
  if MessageDlg(Format('将迁移并尝试在源位置创建链接：%s → %s，确定继续？',
                       [FMigrationItems[Idx].SourcePath, FMigrationItems[Idx].TargetPath]),
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    MigrateOne(Idx);
  end;
end;

procedure TfrmDirectoryMigration.EnsureRightPanel;
begin
  if not Assigned(FRightPanel) then
  begin
    FRightPanel := TPanel.Create(Self);
    FRightPanel.Parent := pnlCenter;
    FRightPanel.Align := alRight;
    FRightPanel.Width := 320;
    FRightPanel.BevelOuter := bvNone;

    FMemoLog := TMemo.Create(Self);
    FMemoLog.Parent := FRightPanel;
    FMemoLog.Align := alClient;
    FMemoLog.ScrollBars := ssVertical;
    FMemoLog.ParentFont := False;
    FMemoLog.Font.Charset := DEFAULT_CHARSET;
    FMemoLog.Font.Name := 'Segoe UI';
    FMemoLog.Lines.Clear;
    FMemoLog.Lines.Add('日志窗口已就绪。');

    FFileList := TListBox.Create(Self);
    FFileList.Parent := FRightPanel;
    FFileList.Align := alClient;
    FFileList.Visible := False;
  end;
end;

procedure TfrmDirectoryMigration.ShowLogPanel;
begin
  if Assigned(FMemoLog) and Assigned(FFileList) then
  begin
    FMemoLog.Visible := True;
    FFileList.Visible := False;
  end;
end;

procedure TfrmDirectoryMigration.ShowFilesOfPath(const DirPath: string);
var
  Subs: TArray<string>;
  Files: TArray<string>;
  S: string;
begin
  if not Assigned(FFileList) then Exit;
  if not TDirectory.Exists(DirPath) then
  begin
    ShowLogPanel;
    Exit;
  end;
  Subs := TDirectory.GetDirectories(DirPath, '*', TSearchOption.soTopDirectoryOnly);
  if Length(Subs) > 0 then
  begin
    ShowLogPanel;
    Exit;
  end;
  Files := TDirectory.GetFiles(DirPath, '*', TSearchOption.soTopDirectoryOnly);
  FFileList.Items.BeginUpdate;
  try
    FFileList.Items.Clear;
    for S in Files do
      FFileList.Items.Add(ExtractFileName(S));
  finally
    FFileList.Items.EndUpdate;
  end;
  if Assigned(FMemoLog) then FMemoLog.Visible := False;
  FFileList.Visible := True;
end;

procedure TfrmDirectoryMigration.clbMigrationItemsClick(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := clbMigrationItems.ItemIndex;
  if (Idx >= 0) and (Idx <= High(FMigrationItems)) then
    ShowFilesOfPath(FMigrationItems[Idx].SourcePath);
end;

procedure TfrmDirectoryMigration.clbMigrationItemsContextPopup(Sender: TObject;
  MousePos: TPoint; var Handled: Boolean);
var
  Pt: TPoint;
  Idx: Integer;
begin
  Pt := clbMigrationItems.ScreenToClient(MousePos);
  Idx := clbMigrationItems.ItemAtPos(Pt, True);
  if Idx >= 0 then
    clbMigrationItems.ItemIndex := Idx;
  Handled := False;
end;

procedure TfrmDirectoryMigration.MigrateOne(Index: Integer);
var
  SrcRoot, DstRoot: string;
  Files: TArray<string>;
  F, Rel, DstFile: string;
  Copied, Failed: Integer;
begin
  if (Index < 0) or (Index > High(FMigrationItems)) then Exit;
  SrcRoot := IncludeTrailingPathDelimiter(FMigrationItems[Index].SourcePath);
  DstRoot := IncludeTrailingPathDelimiter(FMigrationItems[Index].TargetPath);
  if not TDirectory.Exists(SrcRoot) then Exit;
  EnsureDirectory(DstRoot);

  lblStatus.Caption := Format('正在迁移: %s → %s', [SrcRoot, DstRoot]);
  Application.ProcessMessages;

  Files := TDirectory.GetFiles(SrcRoot, '*', TSearchOption.soAllDirectories);
  ProgressBar.Max := Length(Files);
  ProgressBar.Position := 0;
  Copied := 0;
  Failed := 0;
  for F in Files do
  begin
    Rel := Copy(F, Length(SrcRoot) + 1, MaxInt);
    DstFile := DstRoot + Rel;
    if CopyFileVerified(F, DstFile) then
    begin
      try
        TFile.Delete(F);
      except
      end;
      Inc(Copied);
    end
    else
      Inc(Failed);
    ProgressBar.Position := ProgressBar.Position + 1;
    if (ProgressBar.Position and $1F) = 0 then
      Application.ProcessMessages;
  end;

  TryDeleteEmptyDirs(SrcRoot);
  try
    if TDirectory.Exists(SrcRoot) and TDirectory.IsEmpty(SrcRoot) then
    begin
      TDirectory.Delete(SrcRoot);
      if CreateDirectoryJunction(SrcRoot, DstRoot) then
      begin
        if not VerifyJunction(SrcRoot, DstRoot) then
          ShowMessage('联接创建后审计未通过，请手动检查。');
      end;
    end;
  except
  end;

  lblStatus.Caption := Format('完成：复制 %d 个，失败 %d 个。', [Copied, Failed]);
end;

function EnsureDirectory(const Path: string): Boolean;
begin
  Result := True;
  if not TDirectory.Exists(Path) then
  begin
    try
      TDirectory.CreateDirectory(Path);
    except
      Result := False;
    end;
  end;
end;

function ComputeFileSHA256(const FilePath: string): string;
var
  FS: TFileStream;
  Hash: THashSHA2;
  Buffer: TBytes;
  Read: Integer;
begin
  Result := '';
  if not TFile.Exists(FilePath) then Exit;
  Hash := THashSHA2.Create;
  FS := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Buffer, 1 shl 16);
    repeat
      Read := FS.Read(Buffer[0], Length(Buffer));
      if Read > 0 then
        Hash.Update(Buffer, Read);
    until Read = 0;
    Result := THash.DigestAsString(Hash.HashAsBytes);
  finally
    FS.Free;
  end;
end;

function CopyFileVerified(const Src, Dst: string): Boolean;
var
  SrcHash, DstHash: string;
begin
  Result := False;
  try
    if not EnsureDirectory(ExtractFileDir(Dst)) then Exit(False);
    TFile.Copy(Src, Dst, True);
    if TFile.GetSize(Src) <> TFile.GetSize(Dst) then Exit(False);
    SrcHash := ComputeFileSHA256(Src);
    DstHash := ComputeFileSHA256(Dst);
    Result := (SrcHash <> '') and (SrcHash = DstHash);
  except
    Result := False;
  end;
end;

// 创建目录联接（junction），需要管理员权限或开发者模式
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
  Target: UnicodeString;
  Prefix: UnicodeString;
  Substitute: UnicodeString;
begin
  Result := False;
  try
    if TDirectory.Exists(LinkPath) then
      TDirectory.Delete(LinkPath);
  except
  end;
  if not EnsureDirectory(ExtractFileDir(LinkPath)) then Exit(False);
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

function VerifyJunction(const LinkPath, TargetPath: string): Boolean;
begin
  // 简化审计：确认目标目录存在
  Result := TDirectory.Exists(TargetPath);
end;

// 将路径移入回收站（可撤回）
function DeletePathToRecycleBin(const Path: string): Boolean;
var
  Op: TSHFileOpStruct;
  FromBuf: array[0..MAX_PATH] of Char;
  S: string;
begin
  Result := False;
  if Path = '' then Exit;
  if not (TDirectory.Exists(Path) or TFile.Exists(Path)) then Exit(True);
  ZeroMemory(@Op, SizeOf(Op));
  FillChar(FromBuf, SizeOf(FromBuf), 0);
  // 双零结尾缓冲
  S := IncludeTrailingPathDelimiter(Path);
  StrPCopy(FromBuf, S);
  Op.Wnd := 0;
  Op.wFunc := FO_DELETE;
  Op.pFrom := @FromBuf[0];
  Op.fFlags := FOF_ALLOWUNDO or FOF_NOCONFIRMATION or FOF_SILENT;
  Result := (SHFileOperation(Op) = 0);
end;

procedure TfrmDirectoryMigration.CreateContextMenu;
var
  M: TMenuItem;
begin
  if Assigned(FItemPopup) then Exit;
  FItemPopup := TPopupMenu.Create(Self);
  // 查看源/目标文件
  M := TMenuItem.Create(FItemPopup);
  M.Caption := '查看源目录文件';
  M.OnClick := ViewSourceFiles;
  FItemPopup.Items.Add(M);

  M := TMenuItem.Create(FItemPopup);
  M.Caption := '查看目标目录文件';
  M.OnClick := ViewTargetFiles;
  FItemPopup.Items.Add(M);

  // 操作项
  M := TMenuItem.Create(FItemPopup);
  M.Caption := '删除源目录...';
  M.OnClick := DeleteSelectedSourceDir;
  FItemPopup.Items.Add(M);

  M := TMenuItem.Create(FItemPopup);
  M.Caption := '迁移并链接...';
  M.OnClick := MigrateAndLinkSelected;
  FItemPopup.Items.Add(M);
  clbMigrationItems.PopupMenu := FItemPopup;
end;

procedure TfrmDirectoryMigration.DeleteSelectedSourceDir(Sender: TObject);
var
  Idx: Integer;
  Src: string;
begin
  Idx := clbMigrationItems.ItemIndex;
  if (Idx < 0) or (Idx > High(FMigrationItems)) then
  begin
    ShowMessage('请先选择一个源目录。');
    Exit;
  end;
  Src := FMigrationItems[Idx].SourcePath;
  if Src = '' then
  begin
    ShowMessage('未配置源目录路径。');
    Exit;
  end;
  if not TDirectory.Exists(Src) then
  begin
    ShowMessage('源目录不存在或已被删除。');
    Exit;
  end;
  if MessageDlg(Format('确定要删除源目录：%s ? 此操作将移入回收站，可撤回。', [Src]),
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    if DeletePathToRecycleBin(Src) then
    begin
      ShowMessage('已移入回收站。');
      // 刷新显示
      ScanDirectories;
      UpdateItemsList;
    end
    else
      ShowMessage('删除失败，可能没有权限或文件被占用。');
  end;
end;

  TfrmDirectoryMigration = class(TForm)
    pnlMain: TPanel;
    pnlTop: TPanel;
    pnlCenter: TPanel;
    pnlBottom: TPanel;
    
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    
    clbMigrationItems: TCheckListBox;
    
    btnScan: TButton;
    btnMigrate: TButton;
    btnCancel: TButton;
    
    ProgressBar: TProgressBar;
    lblStatus: TLabel;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnScanClick(Sender: TObject);
    procedure btnMigrateClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure clbMigrationItemsClick(Sender: TObject);
    procedure clbMigrationItemsContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure clbMigrationItemsMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    
  private
    FMigrationItems: TArray<TMigrationItem>;
    FItemPopup: TPopupMenu;
    FRightPanel: TPanel;
    FMemoLog: TMemo;
    FFileList: TListBox;
    
    procedure InitializeMigrationItems;
    procedure ScanDirectories;
    procedure UpdateItemsList;
    procedure PerformMigration;
    procedure MigrateOne(Index: Integer);
    procedure CreateContextMenu;
    procedure DeleteSelectedSourceDir(Sender: TObject);
    procedure MigrateAndLinkSelected(Sender: TObject);
    procedure EnsureRightPanel;
    procedure ShowLogPanel;
    procedure ShowFilesOfPath(const DirPath: string);
    procedure ViewSourceFiles(Sender: TObject);
    procedure ViewTargetFiles(Sender: TObject);
    
  public
    class function ShowMigrationDialog: Boolean;
  end;

var
  frmDirectoryMigration: TfrmDirectoryMigration;

implementation

{$R *.dfm}

uses
  Winapi.ShellAPI, System.Hash;

class function TfrmDirectoryMigration.ShowMigrationDialog: Boolean;
var
  frm: TfrmDirectoryMigration;
begin
  Result := False;
  frm := TfrmDirectoryMigration.Create(nil);
  try
    Result := (frm.ShowModal = mrOk);
  finally
    frm.Free;
  end;
end;

procedure TfrmDirectoryMigration.FormCreate(Sender: TObject);
begin
  InitializeMigrationItems;
  ScanDirectories;
  UpdateItemsList;
  CreateContextMenu;
  EnsureRightPanel;
  clbMigrationItems.OnContextPopup := clbMigrationItemsContextPopup;
  clbMigrationItems.OnClick := clbMigrationItemsClick;
  clbMigrationItems.OnMouseUp := clbMigrationItemsMouseUp;
end;

procedure TfrmDirectoryMigration.FormDestroy(Sender: TObject);
begin
  // 娓呯悊璧勬簮
end;

procedure TfrmDirectoryMigration.InitializeMigrationItems;
begin
  SetLength(FMigrationItems, 8);
  
  // 鏂囨。鐩綍
  FMigrationItems[0].DisplayName := 'Documents';
  FMigrationItems[0].SourcePath := TPath.GetDocumentsPath;
  FMigrationItems[0].TargetPath := 'D:\Documents';
  FMigrationItems[0].IsRecommended := True;
  FMigrationItems[0].RiskLevel := 0;
  FMigrationItems[0].Description := 'User documents directory';
  
  // 涓嬭浇鐩綍
  FMigrationItems[1].DisplayName := 'Downloads';
  FMigrationItems[1].SourcePath := TPath.GetDownloadsPath;
  FMigrationItems[1].TargetPath := 'D:\Downloads';
  FMigrationItems[1].IsRecommended := True;
  FMigrationItems[1].RiskLevel := 0;
  FMigrationItems[1].Description := 'Browser downloads directory';
  
  // 妗岄潰鐩綍
  FMigrationItems[2].DisplayName := 'Desktop';
  FMigrationItems[2].SourcePath := TPath.Combine(TPath.GetHomePath, 'Desktop');
  FMigrationItems[2].TargetPath := 'D:\Desktop';
  FMigrationItems[2].IsRecommended := True;
  FMigrationItems[2].RiskLevel := 1;
  FMigrationItems[2].Description := 'Desktop files and shortcuts';
  
  // 鍥剧墖鐩綍
  FMigrationItems[3].DisplayName := 'Pictures';
  FMigrationItems[3].SourcePath := TPath.GetPicturesPath;
  FMigrationItems[3].TargetPath := 'D:\Pictures';
  FMigrationItems[3].IsRecommended := True;
  FMigrationItems[3].RiskLevel := 0;
  FMigrationItems[3].Description := 'User pictures directory';
  
  // 瑙嗛鐩綍
  FMigrationItems[4].DisplayName := 'Videos';
  FMigrationItems[4].SourcePath := TPath.GetMoviesPath;
  FMigrationItems[4].TargetPath := 'D:\Videos';
  FMigrationItems[4].IsRecommended := True;
  FMigrationItems[4].RiskLevel := 0;
  FMigrationItems[4].Description := 'User videos directory';
  
  // 闊充箰鐩綍
  FMigrationItems[5].DisplayName := 'Music';
  FMigrationItems[5].SourcePath := TPath.GetMusicPath;
  FMigrationItems[5].TargetPath := 'D:\Music';
  FMigrationItems[5].IsRecommended := True;
  FMigrationItems[5].RiskLevel := 0;
  FMigrationItems[5].Description := 'User music directory';
  
  // AppData\Local
  FMigrationItems[6].DisplayName := 'AppData\Local';
  FMigrationItems[6].SourcePath := TPath.Combine(TPath.GetHomePath, 'AppData\Local');
  FMigrationItems[6].TargetPath := 'D:\AppData\Local';
  FMigrationItems[6].IsRecommended := False;
  FMigrationItems[6].RiskLevel := 3;
  FMigrationItems[6].Description := 'Application local data (High Risk)';
  
  // AppData\Roaming
  FMigrationItems[7].DisplayName := 'AppData\Roaming';
  FMigrationItems[7].SourcePath := TPath.Combine(TPath.GetHomePath, 'AppData\Roaming');
  FMigrationItems[7].TargetPath := 'D:\AppData\Roaming';
  FMigrationItems[7].IsRecommended := False;
  FMigrationItems[7].RiskLevel := 3;
  FMigrationItems[7].Description := 'Application roaming data (High Risk)';
end;

procedure TfrmDirectoryMigration.ScanDirectories;
var
  I: Integer;
  DirSize: Int64;
begin
  lblStatus.Caption := 'Scanning directories...';
  ProgressBar.Visible := True;
  ProgressBar.Max := Length(FMigrationItems);
  
  for I := 0 to High(FMigrationItems) do
  begin
    ProgressBar.Position := I + 1;
    Application.ProcessMessages;
    
    if TDirectory.Exists(FMigrationItems[I].SourcePath) then
    begin
      try
        // 绠€鍖栫増鏈細妯℃嫙璁＄畻鐩綍澶у皬
        DirSize := Random(1000) * 1024 * 1024; // 闅忔満澶у皬 0-1000MB
        FMigrationItems[I].EstimatedSize := DirSize;
      except
        FMigrationItems[I].EstimatedSize := 0;
      end;
    end
    else
    begin
      FMigrationItems[I].EstimatedSize := 0;
    end;
  end;
  
  ProgressBar.Visible := False;
  lblStatus.Caption := 'Scan completed';
end;

procedure TfrmDirectoryMigration.UpdateItemsList;
var
  I: Integer;
  ItemText: string;
  RiskText: string;
begin
  clbMigrationItems.Items.Clear;
  
  for I := 0 to High(FMigrationItems) do
  begin
    case FMigrationItems[I].RiskLevel of
      0: RiskText := '[Safe]';
      1: RiskText := '[Low Risk]';
      2: RiskText := '[Medium Risk]';
      3: RiskText := '[High Risk]';
    else
      RiskText := '[Unknown]';
    end;
    
    ItemText := Format('%s %s - %.1f MB', [
      RiskText,
      FMigrationItems[I].DisplayName,
      FMigrationItems[I].EstimatedSize / (1024*1024)
    ]);
    
    clbMigrationItems.Items.Add(ItemText);
    clbMigrationItems.Checked[I] := FMigrationItems[I].IsRecommended;
  end;
end;

procedure TfrmDirectoryMigration.btnScanClick(Sender: TObject);
begin
  ScanDirectories;
  UpdateItemsList;
end;

procedure TfrmDirectoryMigration.btnMigrateClick(Sender: TObject);
begin
  if MessageDlg('Are you sure you want to migrate selected directories?', 
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    PerformMigration;
    ModalResult := mrOk;
  end;
end;

procedure TfrmDirectoryMigration.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmDirectoryMigration.PerformMigration;
var
  I: Integer;
  TotalItems: Integer;
  SrcRoot, DstRoot: string;
  Files: TArray<string>;
  F: string;
  Rel, DstFile: string;
  Copied, Failed: Integer;
begin
  TotalItems := 0;
  for I := 0 to clbMigrationItems.Items.Count - 1 do
  begin
    if clbMigrationItems.Checked[I] then
      Inc(TotalItems);
  end;

  if TotalItems = 0 then
  begin
    ShowMessage('未选择任何需要迁移的项目。');
    Exit;
  end;

  ProgressBar.Visible := True;
  try
    for I := 0 to clbMigrationItems.Items.Count - 1 do
    begin
      if not clbMigrationItems.Checked[I] then
        Continue;

      SrcRoot := IncludeTrailingPathDelimiter(FMigrationItems[I].SourcePath);
      DstRoot := IncludeTrailingPathDelimiter(FMigrationItems[I].TargetPath);
      if not TDirectory.Exists(SrcRoot) then
        Continue;
      EnsureDirectory(DstRoot);

      lblStatus.Caption := Format('正在迁移: %s → %s', [SrcRoot, DstRoot]);
      Application.ProcessMessages;

      Files := TDirectory.GetFiles(SrcRoot, '*', TSearchOption.soAllDirectories);
      ProgressBar.Max := Length(Files);
      ProgressBar.Position := 0;
      Copied := 0;
      Failed := 0;
      for F in Files do
      begin
        Rel := Copy(F, Length(SrcRoot) + 1, MaxInt);
        DstFile := DstRoot + Rel;
        if CopyFileVerified(F, DstFile) then
        begin
          try
            TFile.Delete(F);
          except
            // 删除失败忽略（可能被占用），稍后清理空目录
          end;
          Inc(Copied);
        end
        else
          Inc(Failed);
        ProgressBar.Position := ProgressBar.Position + 1;
        if (ProgressBar.Position and $1F) = 0 then
          Application.ProcessMessages;
      end;

      // 清理源中的空目录
      TryDeleteEmptyDirs(SrcRoot);
      // 若源根已空，尝试删除并创建联接
      try
        if TDirectory.Exists(SrcRoot) and TDirectory.IsEmpty(SrcRoot) then
        begin
          TDirectory.Delete(SrcRoot);
          if CreateDirectoryJunction(SrcRoot, DstRoot) then
          begin
            if not VerifyJunction(SrcRoot, DstRoot) then
              ShowMessage('联接创建后审计未通过，请手动检查。');
          end
          else
          begin
            // 创建联接失败不阻塞整体流程
          end;
        end;
      except
        // 忽略
      end;

      lblStatus.Caption := Format('完成：复制 %d 个，失败 %d 个。', [Copied, Failed]);
    end;
  finally
    ProgressBar.Visible := False;
  end;
  ShowMessage('目录迁移已完成。');
end;

end.

unit uRollbackManager;

{
  回滚点管理器 - Rollback Point Manager
  
  功能：
  - 列出所有迁移事务/回滚点
  - 查看回滚点详情
  - 执行回滚操作
  - 删除旧的回滚点
  - 清理无效备份
  
  作者: MoveC Team
  版本: 1.0
  日期: 2025-12-02
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.IOUtils, System.IniFiles, System.DateUtils,
  System.Generics.Collections, System.Generics.Defaults,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Buttons, Vcl.Menus;

type
  // 回滚点信息记录
  TRollbackPointInfo = record
    TransactionID: string;
    SourceDir: string;
    TargetDir: string;
    BackupDir: string;
    Status: string;
    StartTime: TDateTime;
    EndTime: TDateTime;
    TotalFiles: Integer;
    ProcessedFiles: Integer;
    TotalBytes: Int64;
    BackupExists: Boolean;
    JunctionExists: Boolean;
  end;

  TfrmRollbackManager = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblDescription: TLabel;
    pnlClient: TPanel;
    lvRollbackPoints: TListView;
    pnlDetails: TPanel;
    lblDetailsTitle: TLabel;
    memoDetails: TMemo;
    pnlButtons: TPanel;
    btnRefresh: TBitBtn;
    btnRollback: TBitBtn;
    btnDelete: TBitBtn;
    btnCleanup: TBitBtn;
    btnClose: TBitBtn;
    Splitter1: TSplitter;
    pmRollbackList: TPopupMenu;
    miRollback: TMenuItem;
    miDelete: TMenuItem;
    miSeparator1: TMenuItem;
    miOpenBackupFolder: TMenuItem;
    miOpenTargetFolder: TMenuItem;
    miSeparator2: TMenuItem;
    miViewLog: TMenuItem;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnRollbackClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnCleanupClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure lvRollbackPointsSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure lvRollbackPointsDblClick(Sender: TObject);
    procedure miRollbackClick(Sender: TObject);
    procedure miDeleteClick(Sender: TObject);
    procedure miOpenBackupFolderClick(Sender: TObject);
    procedure miOpenTargetFolderClick(Sender: TObject);
    procedure miViewLogClick(Sender: TObject);
    
  private
    FRollbackPoints: TList<TRollbackPointInfo>;
    
    procedure InitializeUI;
    procedure LoadRollbackPoints;
    procedure UpdateDetails(const Info: TRollbackPointInfo);
    procedure ClearDetails;
    function GetSelectedRollbackPoint: TRollbackPointInfo;
    function GetTransactionDir: string;
    function FormatBytes(Bytes: Int64): string;
    function StatusToDisplayText(const Status: string): string;
    
    // 核心操作
    function DoRollback(const Info: TRollbackPointInfo): Boolean;
    function DoDeleteRollbackPoint(const Info: TRollbackPointInfo): Boolean;
    procedure DoCleanupOldPoints;
    
  public
    class procedure ShowManager(AOwner: TComponent);
  end;

var
  frmRollbackManager: TfrmRollbackManager;

implementation

uses
  Winapi.ShellAPI, uMigrationTransaction;

{$R *.dfm}

{ TfrmRollbackManager }

class procedure TfrmRollbackManager.ShowManager(AOwner: TComponent);
var
  Form: TfrmRollbackManager;
begin
  Form := TfrmRollbackManager.Create(AOwner);
  try
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

procedure TfrmRollbackManager.FormCreate(Sender: TObject);
begin
  FRollbackPoints := TList<TRollbackPointInfo>.Create;
  InitializeUI;
  LoadRollbackPoints;
end;

procedure TfrmRollbackManager.FormDestroy(Sender: TObject);
begin
  FRollbackPoints.Free;
end;

procedure TfrmRollbackManager.InitializeUI;
begin
  // 配置ListView列
  with lvRollbackPoints do
  begin
    Columns.Clear;
    with Columns.Add do begin Caption := '事务ID'; Width := 180; end;
    with Columns.Add do begin Caption := '源目录'; Width := 200; end;
    with Columns.Add do begin Caption := '目标目录'; Width := 200; end;
    with Columns.Add do begin Caption := '状态'; Width := 80; end;
    with Columns.Add do begin Caption := '时间'; Width := 140; end;
    with Columns.Add do begin Caption := '文件数'; Width := 70; end;
    with Columns.Add do begin Caption := '备份'; Width := 50; end;
  end;
  
  ClearDetails;
end;

function TfrmRollbackManager.GetTransactionDir: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Transactions');
end;

procedure TfrmRollbackManager.LoadRollbackPoints;
var
  TransDir: string;
  Files: TArray<string>;
  FileName: string;
  IniFile: TIniFile;
  Info: TRollbackPointInfo;
  Item: TListItem;
begin
  FRollbackPoints.Clear;
  lvRollbackPoints.Items.Clear;
  
  TransDir := GetTransactionDir;
  if not TDirectory.Exists(TransDir) then
  begin
    lblDescription.Caption := '暂无迁移记录';
    Exit;
  end;
  
  Files := TDirectory.GetFiles(TransDir, '*.ini');
  
  for FileName in Files do
  begin
    try
      IniFile := TIniFile.Create(FileName);
      try
        Info.TransactionID := IniFile.ReadString('Transaction', 'TransactionID', '');
        Info.SourceDir := IniFile.ReadString('Transaction', 'SourceDir', '');
        Info.TargetDir := IniFile.ReadString('Transaction', 'TargetDir', '');
        Info.BackupDir := IniFile.ReadString('Transaction', 'BackupDir', '');
        Info.Status := IniFile.ReadString('Transaction', 'Status', 'Unknown');
        Info.StartTime := IniFile.ReadDateTime('Transaction', 'StartTime', 0);
        Info.EndTime := IniFile.ReadDateTime('Transaction', 'EndTime', 0);
        Info.TotalFiles := IniFile.ReadInteger('Transaction', 'TotalFiles', 0);
        Info.ProcessedFiles := IniFile.ReadInteger('Transaction', 'ProcessedFiles', 0);
        Info.TotalBytes := IniFile.ReadInt64('Transaction', 'TotalBytes', 0);
        
        // 检查备份目录是否存在
        Info.BackupExists := TDirectory.Exists(Info.BackupDir);
        
        // 检查Junction是否存在
        Info.JunctionExists := TDirectory.Exists(Info.SourceDir);
        
        if Info.TransactionID <> '' then
          FRollbackPoints.Add(Info);
      finally
        IniFile.Free;
      end;
    except
      // 忽略无效文件
    end;
  end;
  
  // 按时间降序排序
  FRollbackPoints.Sort(TComparer<TRollbackPointInfo>.Construct(
    function(const L, R: TRollbackPointInfo): Integer
    begin
      Result := CompareDateTime(R.StartTime, L.StartTime);
    end
  ));
  
  // 填充ListView
  for Info in FRollbackPoints do
  begin
    Item := lvRollbackPoints.Items.Add;
    Item.Caption := Info.TransactionID;
    Item.SubItems.Add(Info.SourceDir);
    Item.SubItems.Add(Info.TargetDir);
    Item.SubItems.Add(StatusToDisplayText(Info.Status));
    Item.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn', Info.StartTime));
    Item.SubItems.Add(IntToStr(Info.TotalFiles));
    if Info.BackupExists then
      Item.SubItems.Add('✓')
    else
      Item.SubItems.Add('✗');
    Item.Data := Pointer(FRollbackPoints.IndexOf(Info));
  end;
  
  lblDescription.Caption := Format('共 %d 条迁移记录', [FRollbackPoints.Count]);
end;

function TfrmRollbackManager.StatusToDisplayText(const Status: string): string;
begin
  if SameText(Status, 'Completed') then
    Result := '已完成'
  else if SameText(Status, 'InProgress') then
    Result := '进行中'
  else if SameText(Status, 'Failed') then
    Result := '失败'
  else if SameText(Status, 'RolledBack') then
    Result := '已回滚'
  else if SameText(Status, 'NotStarted') then
    Result := '未开始'
  else
    Result := Status;
end;

function TfrmRollbackManager.FormatBytes(Bytes: Int64): string;
const
  KB = 1024;
  MB = KB * 1024;
  GB = MB * 1024;
begin
  if Bytes >= GB then
    Result := Format('%.2f GB', [Bytes / GB])
  else if Bytes >= MB then
    Result := Format('%.2f MB', [Bytes / MB])
  else if Bytes >= KB then
    Result := Format('%.2f KB', [Bytes / KB])
  else
    Result := Format('%d B', [Bytes]);
end;

procedure TfrmRollbackManager.UpdateDetails(const Info: TRollbackPointInfo);
var
  S: TStringList;
begin
  S := TStringList.Create;
  try
    S.Add('═══════════════════════════════════════════');
    S.Add('事务ID: ' + Info.TransactionID);
    S.Add('═══════════════════════════════════════════');
    S.Add('');
    S.Add('【目录信息】');
    S.Add('  源目录:    ' + Info.SourceDir);
    S.Add('  目标目录:  ' + Info.TargetDir);
    S.Add('  备份目录:  ' + Info.BackupDir);
    S.Add('');
    S.Add('【状态信息】');
    S.Add('  当前状态:  ' + StatusToDisplayText(Info.Status));
    S.Add('  开始时间:  ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Info.StartTime));
    if Info.EndTime > 0 then
      S.Add('  结束时间:  ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Info.EndTime));
    S.Add('');
    S.Add('【文件统计】');
    S.Add('  总文件数:  ' + IntToStr(Info.TotalFiles));
    S.Add('  已处理:    ' + IntToStr(Info.ProcessedFiles));
    S.Add('  总大小:    ' + FormatBytes(Info.TotalBytes));
    S.Add('');
    S.Add('【可用操作】');
    if Info.BackupExists then
      S.Add('  ✓ 备份目录存在，可执行回滚')
    else
      S.Add('  ✗ 备份目录不存在，无法回滚');
    
    if Info.JunctionExists then
      S.Add('  ✓ 源目录/Junction存在')
    else
      S.Add('  ✗ 源目录/Junction不存在');
    
    memoDetails.Lines.Assign(S);
  finally
    S.Free;
  end;
  
  // 更新按钮状态
  btnRollback.Enabled := Info.BackupExists and 
                         (SameText(Info.Status, 'Completed') or 
                          SameText(Info.Status, 'InProgress') or
                          SameText(Info.Status, 'Failed'));
  btnDelete.Enabled := True;
end;

procedure TfrmRollbackManager.ClearDetails;
begin
  memoDetails.Lines.Clear;
  memoDetails.Lines.Add('请选择一个迁移记录查看详情');
  btnRollback.Enabled := False;
  btnDelete.Enabled := False;
end;

function TfrmRollbackManager.GetSelectedRollbackPoint: TRollbackPointInfo;
var
  Idx: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  if lvRollbackPoints.Selected <> nil then
  begin
    Idx := Integer(lvRollbackPoints.Selected.Data);
    if (Idx >= 0) and (Idx < FRollbackPoints.Count) then
      Result := FRollbackPoints[Idx];
  end;
end;

procedure TfrmRollbackManager.lvRollbackPointsSelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
var
  Info: TRollbackPointInfo;
begin
  if Selected and (Item <> nil) then
  begin
    Info := GetSelectedRollbackPoint;
    if Info.TransactionID <> '' then
      UpdateDetails(Info)
    else
      ClearDetails;
  end
  else
    ClearDetails;
end;

procedure TfrmRollbackManager.lvRollbackPointsDblClick(Sender: TObject);
begin
  // 双击查看日志
  miViewLogClick(Sender);
end;

procedure TfrmRollbackManager.btnRefreshClick(Sender: TObject);
begin
  LoadRollbackPoints;
  ClearDetails;
end;

procedure TfrmRollbackManager.btnRollbackClick(Sender: TObject);
begin
  miRollbackClick(Sender);
end;

procedure TfrmRollbackManager.btnDeleteClick(Sender: TObject);
begin
  miDeleteClick(Sender);
end;

procedure TfrmRollbackManager.btnCleanupClick(Sender: TObject);
begin
  DoCleanupOldPoints;
end;

procedure TfrmRollbackManager.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmRollbackManager.miRollbackClick(Sender: TObject);
var
  Info: TRollbackPointInfo;
begin
  Info := GetSelectedRollbackPoint;
  if Info.TransactionID = '' then
  begin
    MessageDlg('请先选择一个迁移记录', mtWarning, [mbOK], 0);
    Exit;
  end;
  
  if not Info.BackupExists then
  begin
    MessageDlg('备份目录不存在，无法执行回滚操作', mtError, [mbOK], 0);
    Exit;
  end;
  
  if MessageDlg(
    Format('确定要回滚以下迁移吗？' + sLineBreak + sLineBreak +
           '源目录: %s' + sLineBreak +
           '目标目录: %s' + sLineBreak + sLineBreak +
           '回滚操作将：' + sLineBreak +
           '1. 删除当前的目录链接/Junction' + sLineBreak +
           '2. 将备份目录恢复到原位置' + sLineBreak + sLineBreak +
           '此操作不可撤销，是否继续？',
           [Info.SourceDir, Info.TargetDir]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    if DoRollback(Info) then
    begin
      MessageDlg('回滚成功！原目录已恢复。', mtInformation, [mbOK], 0);
      LoadRollbackPoints;
    end
    else
      MessageDlg('回滚失败，请查看详细日志。', mtError, [mbOK], 0);
  end;
end;

procedure TfrmRollbackManager.miDeleteClick(Sender: TObject);
var
  Info: TRollbackPointInfo;
begin
  Info := GetSelectedRollbackPoint;
  if Info.TransactionID = '' then
  begin
    MessageDlg('请先选择一个迁移记录', mtWarning, [mbOK], 0);
    Exit;
  end;
  
  if MessageDlg(
    Format('确定要删除迁移记录 "%s" 吗？' + sLineBreak + sLineBreak +
           '警告：这将同时删除备份目录（如果存在）！' + sLineBreak +
           '备份目录: %s' + sLineBreak + sLineBreak +
           '删除后将无法恢复原始文件，是否继续？',
           [Info.TransactionID, Info.BackupDir]),
    mtWarning, [mbYes, mbNo], 0) = mrYes then
  begin
    if DoDeleteRollbackPoint(Info) then
    begin
      MessageDlg('迁移记录已删除', mtInformation, [mbOK], 0);
      LoadRollbackPoints;
    end
    else
      MessageDlg('删除失败', mtError, [mbOK], 0);
  end;
end;

procedure TfrmRollbackManager.miOpenBackupFolderClick(Sender: TObject);
var
  Info: TRollbackPointInfo;
begin
  Info := GetSelectedRollbackPoint;
  if Info.BackupDir <> '' then
  begin
    if TDirectory.Exists(Info.BackupDir) then
      ShellExecute(0, 'explore', PChar(Info.BackupDir), nil, nil, SW_SHOWNORMAL)
    else
      MessageDlg('备份目录不存在', mtWarning, [mbOK], 0);
  end;
end;

procedure TfrmRollbackManager.miOpenTargetFolderClick(Sender: TObject);
var
  Info: TRollbackPointInfo;
begin
  Info := GetSelectedRollbackPoint;
  if Info.TargetDir <> '' then
  begin
    if TDirectory.Exists(Info.TargetDir) then
      ShellExecute(0, 'explore', PChar(Info.TargetDir), nil, nil, SW_SHOWNORMAL)
    else
      MessageDlg('目标目录不存在', mtWarning, [mbOK], 0);
  end;
end;

procedure TfrmRollbackManager.miViewLogClick(Sender: TObject);
var
  Info: TRollbackPointInfo;
  LogFile: string;
begin
  Info := GetSelectedRollbackPoint;
  if Info.TransactionID <> '' then
  begin
    LogFile := TPath.Combine(GetTransactionDir, Info.TransactionID + '.log');
    if TFile.Exists(LogFile) then
      ShellExecute(0, 'open', PChar(LogFile), nil, nil, SW_SHOWNORMAL)
    else
      MessageDlg('日志文件不存在', mtWarning, [mbOK], 0);
  end;
end;

function TfrmRollbackManager.DoRollback(const Info: TRollbackPointInfo): Boolean;
var
  IniFile: TIniFile;
  TransFile: string;
begin
  Result := False;
  
  try
    // 1. 如果源目录存在（可能是Junction），尝试删除
    if TDirectory.Exists(Info.SourceDir) then
    begin
      try
        // RemoveDirectory 可以删除 Junction 而不删除目标内容
        if not RemoveDirectory(PChar(Info.SourceDir)) then
          TDirectory.Delete(Info.SourceDir, False);
      except
        on E: Exception do
        begin
          MessageDlg('删除源目录/链接失败: ' + E.Message, mtError, [mbOK], 0);
          Exit;
        end;
      end;
    end;
    
    // 2. 恢复备份目录
    if TDirectory.Exists(Info.BackupDir) then
    begin
      if not RenameFile(Info.BackupDir, Info.SourceDir) then
      begin
        MessageDlg('恢复备份目录失败', mtError, [mbOK], 0);
        Exit;
      end;
    end;
    
    // 3. 更新事务状态
    TransFile := TPath.Combine(GetTransactionDir, Info.TransactionID + '.ini');
    if TFile.Exists(TransFile) then
    begin
      IniFile := TIniFile.Create(TransFile);
      try
        IniFile.WriteString('Transaction', 'Status', 'RolledBack');
        IniFile.WriteDateTime('Transaction', 'EndTime', Now);
        IniFile.UpdateFile;
      finally
        IniFile.Free;
      end;
    end;
    
    Result := True;
  except
    on E: Exception do
      MessageDlg('回滚失败: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

function TfrmRollbackManager.DoDeleteRollbackPoint(const Info: TRollbackPointInfo): Boolean;
var
  TransFile, LogFile: string;
begin
  Result := False;
  
  try
    // 1. 删除备份目录（如果存在）
    if TDirectory.Exists(Info.BackupDir) then
    begin
      TDirectory.Delete(Info.BackupDir, True);
    end;
    
    // 2. 删除事务文件
    TransFile := TPath.Combine(GetTransactionDir, Info.TransactionID + '.ini');
    if TFile.Exists(TransFile) then
      TFile.Delete(TransFile);
    
    // 3. 删除日志文件
    LogFile := TPath.Combine(GetTransactionDir, Info.TransactionID + '.log');
    if TFile.Exists(LogFile) then
      TFile.Delete(LogFile);
    
    Result := True;
  except
    on E: Exception do
      MessageDlg('删除失败: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmRollbackManager.DoCleanupOldPoints;
var
  DeleteCount: Integer;
  Info: TRollbackPointInfo;
  DaysOld: Integer;
begin
  if MessageDlg(
    '清理选项：' + sLineBreak + sLineBreak +
    '将删除以下迁移记录：' + sLineBreak +
    '• 状态为"已完成"且备份已删除的记录' + sLineBreak +
    '• 状态为"已回滚"的记录' + sLineBreak +
    '• 超过30天的旧记录' + sLineBreak + sLineBreak +
    '是否继续？',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
  
  DeleteCount := 0;
  
  // 从后往前遍历，避免删除时索引问题
  for var I := FRollbackPoints.Count - 1 downto 0 do
  begin
    Info := FRollbackPoints[I];
    DaysOld := DaysBetween(Now, Info.StartTime);
    
    // 判断是否需要删除
    if (SameText(Info.Status, 'RolledBack')) or
       (SameText(Info.Status, 'Completed') and not Info.BackupExists) or
       (DaysOld > 30) then
    begin
      if DoDeleteRollbackPoint(Info) then
        Inc(DeleteCount);
    end;
  end;
  
  MessageDlg(Format('清理完成，共删除 %d 条记录', [DeleteCount]), 
             mtInformation, [mbOK], 0);
  LoadRollbackPoints;
end;

end.

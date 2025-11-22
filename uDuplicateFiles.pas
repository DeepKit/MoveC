unit uDuplicateFiles;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.CheckLst, Vcl.Menus, System.Generics.Collections,
  uStyles, uDuplicateFileDetector;

type
  TfrmDuplicateFiles = class(TForm)
    pnlMain: TPanel;
    pnlTop: TPanel;
    pnlBottom: TPanel;
    pnlLeft: TPanel;
    pnlRight: TPanel;
    
    // 顶部控制面板
    lblTitle: TLabel;
    btnStartScan: TButton;
    btnStopScan: TButton;
    btnSelectAll: TButton;
    btnSelectNone: TButton;
    btnSelectRecommended: TButton;
    btnDeleteSelected: TButton;
    chkMoveToRecycleBin: TCheckBox;
    
    // 左侧：重复文件组列表
    lblGroups: TLabel;
    lvGroups: TListView;
    
    // 右侧：选中组的文件详情
    lblFiles: TLabel;
    lvFiles: TListView;
    
    // 底部状态
    lblStatus: TLabel;
    ProgressBar: TProgressBar;
    lblStats: TLabel;
    
    // 右键菜单
    pmGroups: TPopupMenu;
    miSelectGroup: TMenuItem;
    miDeselectGroup: TMenuItem;
    miSeparator1: TMenuItem;
    miOpenLocation: TMenuItem;
    
    pmFiles: TPopupMenu;
    miSelectFile: TMenuItem;
    miDeselectFile: TMenuItem;
    miSeparator2: TMenuItem;
    miOpenFile: TMenuItem;
    miOpenFileLocation: TMenuItem;
    miFileProperties: TMenuItem;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnStartScanClick(Sender: TObject);
    procedure btnStopScanClick(Sender: TObject);
    procedure btnSelectAllClick(Sender: TObject);
    procedure btnSelectNoneClick(Sender: TObject);
    procedure btnSelectRecommendedClick(Sender: TObject);
    procedure btnDeleteSelectedClick(Sender: TObject);
    procedure lvGroupsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure lvFilesChange(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure lvGroupsColumnClick(Sender: TObject; Column: TListColumn);
    procedure lvFilesColumnClick(Sender: TObject; Column: TListColumn);
    procedure lvGroupsCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
    procedure lvFilesCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
    procedure lvGroupsDblClick(Sender: TObject);
    procedure lvFilesDblClick(Sender: TObject);
    
    // 右键菜单事件
    procedure miSelectGroupClick(Sender: TObject);
    procedure miDeselectGroupClick(Sender: TObject);
    procedure miOpenLocationClick(Sender: TObject);
    procedure miSelectFileClick(Sender: TObject);
    procedure miDeselectFileClick(Sender: TObject);
    procedure miOpenFileClick(Sender: TObject);
    procedure miOpenFileLocationClick(Sender: TObject);
    procedure miFilePropertiesClick(Sender: TObject);
    
  private
    // 简化版本 - 移除复杂功能
    FCurrentGroupIndex: Integer;
    FTotalDuplicates: Integer;
    FTotalSavings: Int64;
    FDetector: TDuplicateFileDetector;
    FDuplicateGroups: TArray<TDuplicateGroup>;
    FGroupSortColumn: Integer;
    FGroupSortAsc: Boolean;
    FFileSortColumn: Integer;
    FFileSortAsc: Boolean;
    
    procedure InitializeUI;
    procedure SetupListViews;
    procedure UpdateButtonStates;
    procedure UpdateStats;
    
    // 检测器事件处理
    procedure OnScanProgress(const CurrentFile: string; Progress: Integer; const Status: string);
    procedure OnScanResult(const Groups: TArray<TDuplicateGroup>; TotalDuplicates: Integer; TotalSavings: Int64);
    
    // 辅助方法
    procedure UpdateGroupItem(Index: Integer; const Group: TDuplicateGroup);
    procedure UpdateFileItem(Index: Integer; const FileInfo: TDuplicateFileInfo);
    function GetFileIcon(const FilePath: string): Integer;
    
  public
    procedure StartScan(const RootPaths: TArray<string>);
  end;

var
  frmDuplicateFiles: TfrmDuplicateFiles;

implementation

uses
  System.IOUtils, System.StrUtils, Winapi.ShellAPI, System.Math;

{$R *.dfm}

{ TfrmDuplicateFiles }

procedure TfrmDuplicateFiles.FormCreate(Sender: TObject);
begin
  FCurrentGroupIndex := -1;
  FTotalDuplicates := 0;
  FTotalSavings := 0;
  FGroupSortColumn := 0;
  FGroupSortAsc := True;
  FFileSortColumn := 0;
  FFileSortAsc := True;
  
  FDetector := TDuplicateFileDetector.Create;
  FDetector.OnProgress := OnScanProgress;
  FDetector.OnResult := OnScanResult;
  
  InitializeUI;
  SetupListViews;
  UpdateButtonStates;
  UpdateStats;
end;

procedure TfrmDuplicateFiles.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FDetector);
end;

procedure TfrmDuplicateFiles.InitializeUI;
begin
  Caption := '重复文件清理';
  lblTitle.Caption := '重复文件清理';
  
  // 设置按钮文本
  btnStartScan.Caption := '开始扫描';
  btnStopScan.Caption := '停止扫描';
  btnSelectAll.Caption := '全选';
  btnSelectNone.Caption := '全不选';
  btnSelectRecommended.Caption := '选择推荐';
  btnDeleteSelected.Caption := '删除选中';
  chkMoveToRecycleBin.Caption := '移动到回收站';
  
  // 设置标签文本
  lblGroups.Caption := '重复文件组';
  lblFiles.Caption := '文件详情';
  lblStatus.Caption := '就绪';
  lblStats.Caption := '';
  
  // 初始状态
  btnStopScan.Enabled := False;
  btnDeleteSelected.Enabled := False;
end;

procedure TfrmDuplicateFiles.SetupListViews;
begin
  // 设置组列表
  lvGroups.ViewStyle := vsReport;
  lvGroups.Columns.Clear;
  with lvGroups.Columns.Add do Caption := '文件大小';
  with lvGroups.Columns.Add do Caption := '重复数量';
  with lvGroups.Columns.Add do Caption := '可节省空间';
  with lvGroups.Columns.Add do Caption := '文件路径';
  lvGroups.OnColumnClick := lvGroupsColumnClick;
  lvGroups.OnCompare := lvGroupsCompare;
  lvGroups.OnChange := lvGroupsChange;
  lvGroups.OnDblClick := lvGroupsDblClick;
  
  // 设置文件列表
  lvFiles.ViewStyle := vsReport;
  lvFiles.Columns.Clear;
  with lvFiles.Columns.Add do Caption := '文件名';
  with lvFiles.Columns.Add do Caption := '路径';
  with lvFiles.Columns.Add do Caption := '大小';
  with lvFiles.Columns.Add do Caption := '修改时间';
  with lvFiles.Columns.Add do Caption := '选中';
  lvFiles.OnColumnClick := lvFilesColumnClick;
  lvFiles.OnCompare := lvFilesCompare;
  lvFiles.OnChange := lvFilesChange;
  lvFiles.OnDblClick := lvFilesDblClick;
end;

procedure TfrmDuplicateFiles.UpdateButtonStates;
begin
  btnStartScan.Enabled := not FDetector.IsScanning;
  btnStopScan.Enabled := FDetector.IsScanning;
  btnDeleteSelected.Enabled := (lvGroups.Items.Count > 0) and not FDetector.IsScanning;
end;

procedure TfrmDuplicateFiles.UpdateStats;
begin
  if FTotalDuplicates > 0 then
    lblStats.Caption := Format('发现 %d 个重复文件，可节省 %s', 
      [FTotalDuplicates, FormatFloat('#,##0.00', FTotalSavings / 1024.0 / 1024.0) + ' MB'])
  else
    lblStats.Caption := '未发现重复文件';
end;

procedure TfrmDuplicateFiles.btnStartScanClick(Sender: TObject);
var
  RootPaths: TArray<string>;
begin
  // 简化版本 - 扫描常用目录
  SetLength(RootPaths, 3);
  RootPaths[0] := ExtractFilePath(ParamStr(0));
  RootPaths[1] := TPath.Combine(TPath.GetDocumentsPath, '');
  RootPaths[2] := TPath.GetDownloadsPath;
  
  StartScan(RootPaths);
end;

procedure TfrmDuplicateFiles.btnStopScanClick(Sender: TObject);
begin
  FDetector.CancelScan;
  lblStatus.Caption := '扫描已取消';
end;

procedure TfrmDuplicateFiles.btnSelectAllClick(Sender: TObject);
var
  I, J: Integer;
begin
  for I := 0 to High(FDuplicateGroups) do
  begin
    for J := 0 to High(FDuplicateGroups[I].Files) do
    begin
      FDuplicateGroups[I].Files[J].IsSelected := True;
    end;
  end;
  
  // 刷新列表显示
  if FCurrentGroupIndex >= 0 then
    lvGroupsChange(lvGroups, lvGroups.Selected, ctState);
    
  UpdateButtonStates;
end;

procedure TfrmDuplicateFiles.btnSelectNoneClick(Sender: TObject);
var
  I, J: Integer;
begin
  for I := 0 to High(FDuplicateGroups) do
  begin
    for J := 0 to High(FDuplicateGroups[I].Files) do
    begin
      FDuplicateGroups[I].Files[J].IsSelected := False;
    end;
  end;
  
  // 刷新列表显示
  if FCurrentGroupIndex >= 0 then
    lvGroupsChange(lvGroups, lvGroups.Selected, ctState);
    
  UpdateButtonStates;
end;

procedure TfrmDuplicateFiles.btnSelectRecommendedClick(Sender: TObject);
var
  RecommendedGroups: TArray<TDuplicateGroup>;
  I, J: Integer;
begin
  RecommendedGroups := FDetector.GetRecommendedDeletions(FDuplicateGroups);
  
  // 清除所有选择
  for I := 0 to High(FDuplicateGroups) do
  begin
    for J := 0 to High(FDuplicateGroups[I].Files) do
    begin
      FDuplicateGroups[I].Files[J].IsSelected := False;
    end;
  end;
  
  // 应用推荐选择
  for I := 0 to High(RecommendedGroups) do
  begin
    for J := 0 to High(RecommendedGroups[I].Files) do
    begin
      var FilePath := RecommendedGroups[I].Files[J].FilePath;
      // 在原始组中查找并标记
      for var K := 0 to High(FDuplicateGroups) do
      begin
        for var L := 0 to High(FDuplicateGroups[K].Files) do
        begin
          if FDuplicateGroups[K].Files[L].FilePath = FilePath then
          begin
            FDuplicateGroups[K].Files[L].IsSelected := True;
            FDuplicateGroups[K].Files[L].DeleteReason := RecommendedGroups[I].Files[J].DeleteReason;
            Break;
          end;
        end;
      end;
    end;
  end;
  
  // 刷新列表显示
  if FCurrentGroupIndex >= 0 then
    lvGroupsChange(lvGroups, lvGroups.Selected, ctState);
    
  UpdateButtonStates;
end;

procedure TfrmDuplicateFiles.btnDeleteSelectedClick(Sender: TObject);
var
  SelectedCount: Integer;
  I, J: Integer;
begin
  SelectedCount := 0;
  for I := 0 to High(FDuplicateGroups) do
  begin
    for J := 0 to High(FDuplicateGroups[I].Files) do
    begin
      if FDuplicateGroups[I].Files[J].IsSelected then
        Inc(SelectedCount);
    end;
  end;
  
  if SelectedCount = 0 then
  begin
    ShowMessage('请先选择要删除的文件。');
    Exit;
  end;
  
  if Application.MessageBox(
    PChar(Format('确定要删除选中的 %d 个文件吗？', [SelectedCount])),
    '确认删除', MB_OKCANCEL or MB_ICONWARNING) <> IDOK then
    Exit;
    
  // 执行删除
  if FDetector.DeleteSelectedFiles(FDuplicateGroups, chkMoveToRecycleBin.Checked) then
  begin
    ShowMessage('文件删除成功。');
    // 重新扫描或刷新列表
    lvGroups.Items.Clear;
    lvFiles.Items.Clear;
    FDuplicateGroups := [];
    FTotalDuplicates := 0;
    FTotalSavings := 0;
    UpdateStats;
    UpdateButtonStates;
  end
  else
  begin
    ShowMessage('文件删除失败，请检查权限。');
  end;
end;

procedure TfrmDuplicateFiles.lvGroupsColumnClick(Sender: TObject; Column: TListColumn);
begin
  if FGroupSortColumn = Column.Index then
    FGroupSortAsc := not FGroupSortAsc
  else
  begin
    FGroupSortColumn := Column.Index;
    FGroupSortAsc := True;
  end;
  lvGroups.AlphaSort;
end;

procedure TfrmDuplicateFiles.lvGroupsCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
var
  I1, I2: Integer;
  V1, V2: Int64;
  S1, S2: string;
begin
  Compare := 0;
  if (Item1 = nil) or (Item2 = nil) then Exit;
  I1 := Integer(Item1.Data);
  I2 := Integer(Item2.Data);
  if (I1 < 0) or (I2 < 0) or (I1 >= Length(FDuplicateGroups)) or (I2 >= Length(FDuplicateGroups)) then Exit;

  case FGroupSortColumn of
    0: begin // 文件大小
         V1 := FDuplicateGroups[I1].Files[0].FileSize;
         V2 := FDuplicateGroups[I2].Files[0].FileSize;
         if V1 < V2 then Compare := -1 else if V1 > V2 then Compare := 1 else Compare := 0;
       end;
    1: begin // 重复数量
         V1 := FDuplicateGroups[I1].FileCount;
         V2 := FDuplicateGroups[I2].FileCount;
         if V1 < V2 then Compare := -1 else if V1 > V2 then Compare := 1 else Compare := 0;
       end;
    2: begin // 可节省空间
         V1 := FDuplicateGroups[I1].PotentialSavings;
         V2 := FDuplicateGroups[I2].PotentialSavings;
         if V1 < V2 then Compare := -1 else if V1 > V2 then Compare := 1 else Compare := 0;
       end;
  else
    S1 := ExtractFileName(FDuplicateGroups[I1].Files[0].FilePath);
    S2 := ExtractFileName(FDuplicateGroups[I2].Files[0].FilePath);
    Compare := CompareText(S1, S2);
  end;

  if not FGroupSortAsc then
    Compare := -Compare;
end;

procedure TfrmDuplicateFiles.lvFilesColumnClick(Sender: TObject; Column: TListColumn);
begin
  if FFileSortColumn = Column.Index then
    FFileSortAsc := not FFileSortAsc
  else
  begin
    FFileSortColumn := Column.Index;
    FFileSortAsc := True;
  end;
  lvFiles.AlphaSort;
end;

procedure TfrmDuplicateFiles.lvFilesCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
var
  F1, F2: Integer;
  G: TDuplicateGroup;
  S1, S2: string;
  D1, D2: TDateTime;
begin
  Compare := 0;
  if (FCurrentGroupIndex < 0) or (FCurrentGroupIndex >= Length(FDuplicateGroups)) then Exit;
  G := FDuplicateGroups[FCurrentGroupIndex];
  F1 := Integer(Item1.Data);
  F2 := Integer(Item2.Data);
  if (F1 < 0) or (F2 < 0) or (F1 >= Length(G.Files)) or (F2 >= Length(G.Files)) then Exit;

  case FFileSortColumn of
    0: begin // 文件名
         S1 := ExtractFileName(G.Files[F1].FilePath);
         S2 := ExtractFileName(G.Files[F2].FilePath);
         Compare := CompareText(S1, S2);
       end;
    1: begin // 路径
         S1 := ExtractFilePath(G.Files[F1].FilePath);
         S2 := ExtractFilePath(G.Files[F2].FilePath);
         Compare := CompareText(S1, S2);
       end;
    2: begin // 大小
         if G.Files[F1].FileSize < G.Files[F2].FileSize then Compare := -1
         else if G.Files[F1].FileSize > G.Files[F2].FileSize then Compare := 1
         else Compare := 0;
       end;
    3: begin // 修改时间
         D1 := G.Files[F1].LastWriteTime;
         D2 := G.Files[F2].LastWriteTime;
         if D1 < D2 then Compare := -1
         else if D1 > D2 then Compare := 1
         else Compare := 0;
       end;
    4: begin // 选中状态
         if G.Files[F1].IsSelected = G.Files[F2].IsSelected then Compare := 0
         else if G.Files[F1].IsSelected then Compare := -1
         else Compare := 1;
       end;
  end;

  if not FFileSortAsc then
    Compare := -Compare;
end;

procedure TfrmDuplicateFiles.lvGroupsChange(Sender: TObject; Item: TListItem; Change: TItemChange);
var
  GroupIndex: Integer;
  Group: TDuplicateGroup;
  I: Integer;
begin
  if lvGroups.Selected = nil then
  begin
    FCurrentGroupIndex := -1;
    lvFiles.Items.Clear;
    Exit;
  end;
  
  GroupIndex := Integer(lvGroups.Selected.Data);
  if (GroupIndex < 0) or (GroupIndex >= Length(FDuplicateGroups)) then Exit;
  
  FCurrentGroupIndex := GroupIndex;
  Group := FDuplicateGroups[GroupIndex];
  
  lvFiles.Items.BeginUpdate;
  try
    lvFiles.Items.Clear;
    for I := 0 to High(Group.Files) do
    begin
      UpdateFileItem(I, Group.Files[I]);
    end;
  finally
    lvFiles.Items.EndUpdate;
  end;
end;

procedure TfrmDuplicateFiles.lvFilesChange(Sender: TObject; Item: TListItem; Change: TItemChange);
var
  FileIndex: Integer;
  Group: TDuplicateGroup;
begin
  if (FCurrentGroupIndex < 0) or (FCurrentGroupIndex >= Length(FDuplicateGroups)) then Exit;
  if lvFiles.Selected = nil then Exit;
  
  FileIndex := Integer(lvFiles.Selected.Data);
  Group := FDuplicateGroups[FCurrentGroupIndex];
  if (FileIndex < 0) or (FileIndex >= Length(Group.Files)) then Exit;
  
  // 更新选中状态
  Group.Files[FileIndex].IsSelected := lvFiles.Selected.Checked;
  
  // 更新显示
  if lvFiles.Selected.SubItems.Count > 4 then
    lvFiles.Selected.SubItems[4] := IfThen(Group.Files[FileIndex].IsSelected, '是', '否');
end;

procedure TfrmDuplicateFiles.lvGroupsDblClick(Sender: TObject);
begin
  miOpenLocationClick(Sender);
end;

procedure TfrmDuplicateFiles.lvFilesDblClick(Sender: TObject);
begin
  miOpenFileClick(Sender);
end;

procedure TfrmDuplicateFiles.miSelectGroupClick(Sender: TObject);
var
  I: Integer;
  Group: TDuplicateGroup;
begin
  if (FCurrentGroupIndex < 0) or (FCurrentGroupIndex >= Length(FDuplicateGroups)) then Exit;
  
  Group := FDuplicateGroups[FCurrentGroupIndex];
  for I := 0 to High(Group.Files) do
  begin
    Group.Files[I].IsSelected := True;
  end;
  
  lvGroupsChange(lvGroups, lvGroups.Selected, ctState);
end;

procedure TfrmDuplicateFiles.miDeselectGroupClick(Sender: TObject);
var
  I: Integer;
  Group: TDuplicateGroup;
begin
  if (FCurrentGroupIndex < 0) or (FCurrentGroupIndex >= Length(FDuplicateGroups)) then Exit;
  
  Group := FDuplicateGroups[FCurrentGroupIndex];
  for I := 0 to High(Group.Files) do
  begin
    Group.Files[I].IsSelected := False;
  end;
  
  lvGroupsChange(lvGroups, lvGroups.Selected, ctState);
end;

procedure TfrmDuplicateFiles.miOpenLocationClick(Sender: TObject);
var
  GroupIndex: Integer;
  FilePath: string;
begin
  if lvGroups.Selected = nil then Exit;
  
  GroupIndex := Integer(lvGroups.Selected.Data);
  if (GroupIndex < 0) or (GroupIndex >= Length(FDuplicateGroups)) then Exit;
  
  FilePath := ExtractFilePath(FDuplicateGroups[GroupIndex].Files[0].FilePath);
  ShellExecute(0, 'explore', PChar(FilePath), nil, nil, SW_SHOWNORMAL);
end;

procedure TfrmDuplicateFiles.miSelectFileClick(Sender: TObject);
begin
  if lvFiles.Selected = nil then Exit;
  lvFiles.Selected.Checked := True;
  lvFilesChange(lvFiles, lvFiles.Selected, ctState);
end;

procedure TfrmDuplicateFiles.miDeselectFileClick(Sender: TObject);
begin
  if lvFiles.Selected = nil then Exit;
  lvFiles.Selected.Checked := False;
  lvFilesChange(lvFiles, lvFiles.Selected, ctState);
end;

procedure TfrmDuplicateFiles.miOpenFileClick(Sender: TObject);
var
  FileIndex: Integer;
  Group: TDuplicateGroup;
  FilePath: string;
begin
  if (FCurrentGroupIndex < 0) or (FCurrentGroupIndex >= Length(FDuplicateGroups)) then Exit;
  if lvFiles.Selected = nil then Exit;
  
  FileIndex := Integer(lvFiles.Selected.Data);
  Group := FDuplicateGroups[FCurrentGroupIndex];
  if (FileIndex < 0) or (FileIndex >= Length(Group.Files)) then Exit;
  
  FilePath := Group.Files[FileIndex].FilePath;
  ShellExecute(0, 'open', PChar(FilePath), nil, nil, SW_SHOWNORMAL);
end;

procedure TfrmDuplicateFiles.miOpenFileLocationClick(Sender: TObject);
var
  FileIndex: Integer;
  Group: TDuplicateGroup;
  FilePath: string;
begin
  if (FCurrentGroupIndex < 0) or (FCurrentGroupIndex >= Length(FDuplicateGroups)) then Exit;
  if lvFiles.Selected = nil then Exit;
  
  FileIndex := Integer(lvFiles.Selected.Data);
  Group := FDuplicateGroups[FCurrentGroupIndex];
  if (FileIndex < 0) or (FileIndex >= Length(Group.Files)) then Exit;
  
  FilePath := ExtractFilePath(Group.Files[FileIndex].FilePath);
  ShellExecute(0, 'explore', PChar(FilePath), nil, nil, SW_SHOWNORMAL);
end;

procedure TfrmDuplicateFiles.miFilePropertiesClick(Sender: TObject);
begin
  // 简化版本 - 暂不实现
  ShowMessage('文件属性功能暂未实现。');
end;

procedure TfrmDuplicateFiles.StartScan(const RootPaths: TArray<string>);
var
  Options: TDetectionOptions;
begin
  lblStatus.Caption := '正在扫描...';
  ProgressBar.Position := 0;
  
  Options := GetDefaultDetectionOptions;
  FDetector.StartScan(RootPaths, Options);
  
  UpdateButtonStates;
end;

procedure TfrmDuplicateFiles.OnScanProgress(const CurrentFile: string; Progress: Integer; const Status: string);
begin
  if Progress >= 0 then
    ProgressBar.Position := Progress;
  lblStatus.Caption := Status;
  
  if CurrentFile <> '' then
    lblStatus.Caption := lblStatus.Caption + ' - ' + ExtractFileName(CurrentFile);
    
  Application.ProcessMessages;
end;

procedure TfrmDuplicateFiles.OnScanResult(const Groups: TArray<TDuplicateGroup>; TotalDuplicates: Integer; TotalSavings: Int64);
var
  I: Integer;
begin
  FDuplicateGroups := Groups;
  FTotalDuplicates := TotalDuplicates;
  FTotalSavings := TotalSavings;
  
  lvGroups.Items.BeginUpdate;
  try
    lvGroups.Items.Clear;
    for I := 0 to High(Groups) do
    begin
      UpdateGroupItem(I, Groups[I]);
    end;
  finally
    lvGroups.Items.EndUpdate;
  end;
  
  lblStatus.Caption := '扫描完成';
  ProgressBar.Position := 100;
  UpdateStats;
  UpdateButtonStates;
end;

procedure TfrmDuplicateFiles.UpdateGroupItem(Index: Integer; const Group: TDuplicateGroup);
var
  Item: TListItem;
begin
  Item := lvGroups.Items.Add;
  Item.Caption := FormatFloat('#,##0', Group.Files[0].FileSize / 1024.0) + ' KB';
  Item.SubItems.Add(IntToStr(Group.FileCount));
  Item.SubItems.Add(FormatFloat('#,##0.00', Group.PotentialSavings / 1024.0 / 1024.0) + ' MB');
  Item.SubItems.Add(ExtractFileName(Group.Files[0].FilePath));
  Item.Data := Pointer(Index);
end;

procedure TfrmDuplicateFiles.UpdateFileItem(Index: Integer; const FileInfo: TDuplicateFileInfo);
var
  Item: TListItem;
begin
  Item := lvFiles.Items.Add;
  Item.Caption := ExtractFileName(FileInfo.FilePath);
  Item.SubItems.Add(ExtractFilePath(FileInfo.FilePath));
  Item.SubItems.Add(FormatFloat('#,##0', FileInfo.FileSize / 1024.0) + ' KB');
  Item.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn', FileInfo.LastWriteTime));
  Item.SubItems.Add(IfThen(FileInfo.IsSelected, '是', '否'));
  Item.Checked := FileInfo.IsSelected;
  Item.Data := Pointer(Index);
end;

function TfrmDuplicateFiles.GetFileIcon(const FilePath: string): Integer;
begin
  // 简化版本 - 返回默认图标
  Result := 0;
end;

end.

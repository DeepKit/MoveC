unit uDuplicateFiles;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.CheckLst, Vcl.Menus, System.Generics.Collections,
  uStyles;

type
  // 简化的重复文件组类型
  TDuplicateGroup = record
    Files: TArray<string>;
    Size: Int64;
  end;

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
    procedure FormShow(Sender: TObject);
    
    procedure btnStartScanClick(Sender: TObject);
    procedure btnStopScanClick(Sender: TObject);
    procedure btnSelectAllClick(Sender: TObject);
    procedure btnSelectNoneClick(Sender: TObject);
    procedure btnSelectRecommendedClick(Sender: TObject);
    procedure btnDeleteSelectedClick(Sender: TObject);
    
    procedure lvGroupsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure lvFilesItemChecked(Sender: TObject; Item: TListItem);
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
    
    procedure InitializeUI;
    procedure SetupListViews;
    procedure UpdateButtonStates;
    procedure UpdateStats;
    
    // 检测器事件处理
    procedure OnDetectorProgress(const CurrentFile: string; Progress: Integer; const Status: string);
    procedure OnDetectorResult(const Groups: TArray<TDuplicateGroup>; TotalDuplicates: Integer; TotalSavings: Int64);
    
    // UI更新方法
    procedure PopulateGroupsList;
    procedure PopulateFilesList(GroupIndex: Integer);
    procedure UpdateGroupItem(GroupIndex: Integer);
    procedure UpdateFileItem(FileIndex: Integer);
    
    // 辅助方法
    function GetSelectedGroupIndex: Integer;
    function GetSelectedFileIndex: Integer;
    function FormatFileSize(Size: Int64): string;
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

procedure TfrmDuplicateFiles.FormCreate(Sender: TObject);
begin
  FDetector := TDuplicateFileDetector.Create;
  FDetector.OnProgress := OnDetectorProgress;
  FDetector.OnResult := OnDetectorResult;
  
  FCurrentGroupIndex := -1;
  FTotalDuplicates := 0;
  FTotalSavings := 0;
  
  InitializeUI;
  SetupListViews;
  UpdateButtonStates;
end;

procedure TfrmDuplicateFiles.FormDestroy(Sender: TObject);
begin
  if Assigned(FDetector) then
  begin
    FDetector.CancelScan;
    FDetector.Free;
  end;
end;

procedure TfrmDuplicateFiles.FormShow(Sender: TObject);
begin
  // 应用现代化样式
  StyleManager.StyleForm(Self);
  StyleManager.StyleListView(lvGroups);
  StyleManager.StyleListView(lvFiles);
  StyleManager.StyleProgressBar(ProgressBar);
end;

procedure TfrmDuplicateFiles.InitializeUI;
begin
  Caption := '重复文件检测器';
  
  // 设置窗体属性
  Width := 1000;
  Height := 700;
  Position := poScreenCenter;
  
  // 设置面板属性
  pnlTop.Height := 50;
  pnlBottom.Height := 60;
  pnlLeft.Width := 400;
  
  // 设置控件属性
  lblTitle.Caption := '重复文件检测与清理';
  lblTitle.Font.Size := 12;
  lblTitle.Font.Style := [fsBold];
  
  btnStartScan.Caption := '开始扫描';
  btnStopScan.Caption := '停止扫描';
  btnSelectAll.Caption := '全选';
  btnSelectNone.Caption := '全不选';
  btnSelectRecommended.Caption := '选择推荐';
  btnDeleteSelected.Caption := '删除选中';
  
  chkMoveToRecycleBin.Caption := '移动到回收站（推荐）';
  chkMoveToRecycleBin.Checked := True;
  
  lblGroups.Caption := '重复文件组';
  lblFiles.Caption := '文件详情';
  lblStatus.Caption := '就绪';
  lblStats.Caption := '';
  
  ProgressBar.Visible := False;
end;

procedure TfrmDuplicateFiles.SetupListViews;
begin
  // 设置重复文件组列表
  lvGroups.ViewStyle := vsReport;
  lvGroups.RowSelect := True;
  lvGroups.FullDrag := True;
  lvGroups.GridLines := True;
  
  with lvGroups.Columns.Add do
  begin
    Caption := '文件大小';
    Width := 100;
  end;
  with lvGroups.Columns.Add do
  begin
    Caption := '重复数量';
    Width := 80;
  end;
  with lvGroups.Columns.Add do
  begin
    Caption := '可节省空间';
    Width := 100;
  end;
  with lvGroups.Columns.Add do
  begin
    Caption := '示例文件';
    Width := 200;
  end;
  
  // 设置文件详情列表
  lvFiles.ViewStyle := vsReport;
  lvFiles.RowSelect := True;
  lvFiles.Checkboxes := True;
  lvFiles.FullDrag := True;
  lvFiles.GridLines := True;
  
  with lvFiles.Columns.Add do
  begin
    Caption := '文件名';
    Width := 200;
  end;
  with lvFiles.Columns.Add do
  begin
    Caption := '路径';
    Width := 300;
  end;
  with lvFiles.Columns.Add do
  begin
    Caption := '修改时间';
    Width := 120;
  end;
  with lvFiles.Columns.Add do
  begin
    Caption := '建议';
    Width := 150;
  end;
end;

procedure TfrmDuplicateFiles.UpdateButtonStates;
var
  IsScanning: Boolean;
  HasGroups: Boolean;
  HasSelection: Boolean;
begin
  IsScanning := FDetector.IsScanning;
  HasGroups := Length(FDuplicateGroups) > 0;
  HasSelection := GetSelectedGroupIndex >= 0;
  
  btnStartScan.Enabled := not IsScanning;
  btnStopScan.Enabled := IsScanning;
  btnSelectAll.Enabled := HasGroups and not IsScanning;
  btnSelectNone.Enabled := HasGroups and not IsScanning;
  btnSelectRecommended.Enabled := HasGroups and not IsScanning;
  btnDeleteSelected.Enabled := HasGroups and not IsScanning;
  
  lvGroups.Enabled := not IsScanning;
  lvFiles.Enabled := not IsScanning;
  
  ProgressBar.Visible := IsScanning;
end;

procedure TfrmDuplicateFiles.UpdateStats;
var
  SelectedCount: Integer;
  SelectedSize: Int64;
begin
  SelectedCount := 0;
  SelectedSize := 0;
  
  for var Group in FDuplicateGroups do
  begin
    for var FileInfo in Group.Files do
    begin
      if FileInfo.IsSelected then
      begin
        Inc(SelectedCount);
        Inc(SelectedSize, FileInfo.FileSize);
      end;
    end;
  end;
  
  lblStats.Caption := Format('总计: %d 组重复文件，%d 个文件，可节省 %s | 已选择: %d 个文件，%s',
    [Length(FDuplicateGroups), FTotalDuplicates, FormatFileSize(FTotalSavings),
     SelectedCount, FormatFileSize(SelectedSize)]);
end;

procedure TfrmDuplicateFiles.OnDetectorProgress(const CurrentFile: string; Progress: Integer; const Status: string);
begin
  lblStatus.Caption := Status;
  if Progress >= 0 then
    ProgressBar.Position := Progress;
  Application.ProcessMessages;
end;

procedure TfrmDuplicateFiles.OnDetectorResult(const Groups: TArray<TDuplicateGroup>; 
  TotalDuplicates: Integer; TotalSavings: Int64);
begin
  FDuplicateGroups := Groups;
  FTotalDuplicates := TotalDuplicates;
  FTotalSavings := TotalSavings;
  
  PopulateGroupsList;
  UpdateButtonStates;
  UpdateStats;
  
  lblStatus.Caption := Format('扫描完成：找到 %d 组重复文件', [Length(Groups)]);
end;

procedure TfrmDuplicateFiles.PopulateGroupsList;
var
  Item: TListItem;
  i: Integer;
begin
  lvGroups.Items.BeginUpdate;
  try
    lvGroups.Items.Clear;
    
    for i := 0 to Length(FDuplicateGroups) - 1 do
    begin
      Item := lvGroups.Items.Add;
      Item.Data := Pointer(i);
      Item.Caption := FormatFileSize(FDuplicateGroups[i].Files[0].FileSize);
      Item.SubItems.Add(IntToStr(FDuplicateGroups[i].FileCount));
      Item.SubItems.Add(FormatFileSize(FDuplicateGroups[i].PotentialSavings));
      Item.SubItems.Add(ExtractFileName(FDuplicateGroups[i].Files[0].FilePath));
    end;
  finally
    lvGroups.Items.EndUpdate;
  end;
end;

procedure TfrmDuplicateFiles.PopulateFilesList(GroupIndex: Integer);
var
  Item: TListItem;
  Group: TDuplicateGroup;
  i: Integer;
begin
  if (GroupIndex < 0) or (GroupIndex >= Length(FDuplicateGroups)) then
    Exit;
    
  Group := FDuplicateGroups[GroupIndex];
  
  lvFiles.Items.BeginUpdate;
  try
    lvFiles.Items.Clear;
    
    for i := 0 to Length(Group.Files) - 1 do
    begin
      Item := lvFiles.Items.Add;
      Item.Data := Pointer(i);
      Item.Caption := ExtractFileName(Group.Files[i].FilePath);
      Item.SubItems.Add(ExtractFileDir(Group.Files[i].FilePath));
      Item.SubItems.Add(DateTimeToStr(Group.Files[i].LastWriteTime));
      Item.SubItems.Add(Group.Files[i].DeleteReason);
      Item.Checked := Group.Files[i].IsSelected;
    end;
  finally
    lvFiles.Items.EndUpdate;
  end;
end;

function TfrmDuplicateFiles.FormatFileSize(Size: Int64): string;
begin
  if Size < 1024 then
    Result := Format('%d B', [Size])
  else if Size < 1024 * 1024 then
    Result := Format('%.1f KB', [Size / 1024])
  else if Size < 1024 * 1024 * 1024 then
    Result := Format('%.1f MB', [Size / (1024 * 1024)])
  else
    Result := Format('%.2f GB', [Size / (1024 * 1024 * 1024)]);
end;

function TfrmDuplicateFiles.GetSelectedGroupIndex: Integer;
begin
  Result := -1;
  if Assigned(lvGroups.Selected) then
    Result := Integer(lvGroups.Selected.Data);
end;

function TfrmDuplicateFiles.GetSelectedFileIndex: Integer;
begin
  Result := -1;
  if Assigned(lvFiles.Selected) then
    Result := Integer(lvFiles.Selected.Data);
end;

procedure TfrmDuplicateFiles.StartScan(const RootPaths: TArray<string>);
var
  Options: TDetectionOptions;
begin
  Options := GetDefaultDetectionOptions;

  // 可以在这里添加选项配置对话框

  FDetector.StartScan(RootPaths, Options);
  UpdateButtonStates;
end;

// 按钮事件处理
procedure TfrmDuplicateFiles.btnStartScanClick(Sender: TObject);
var
  RootPaths: TArray<string>;
begin
  // 这里应该弹出目录选择对话框，暂时使用默认路径
  SetLength(RootPaths, 1);
  RootPaths[0] := 'C:\Users';

  StartScan(RootPaths);
end;

procedure TfrmDuplicateFiles.btnStopScanClick(Sender: TObject);
begin
  FDetector.CancelScan;
  lblStatus.Caption := '扫描已取消';
  UpdateButtonStates;
end;

procedure TfrmDuplicateFiles.btnSelectAllClick(Sender: TObject);
var
  i, j: Integer;
begin
  for i := 0 to Length(FDuplicateGroups) - 1 do
  begin
    for j := 0 to Length(FDuplicateGroups[i].Files) - 1 do
      FDuplicateGroups[i].Files[j].IsSelected := True;
  end;

  // 更新当前显示的文件列表
  if FCurrentGroupIndex >= 0 then
    PopulateFilesList(FCurrentGroupIndex);

  UpdateStats;
end;

procedure TfrmDuplicateFiles.btnSelectNoneClick(Sender: TObject);
var
  i, j: Integer;
begin
  for i := 0 to Length(FDuplicateGroups) - 1 do
  begin
    for j := 0 to Length(FDuplicateGroups[i].Files) - 1 do
      FDuplicateGroups[i].Files[j].IsSelected := False;
  end;

  // 更新当前显示的文件列表
  if FCurrentGroupIndex >= 0 then
    PopulateFilesList(FCurrentGroupIndex);

  UpdateStats;
end;

procedure TfrmDuplicateFiles.btnSelectRecommendedClick(Sender: TObject);
var
  RecommendedGroups: TArray<TDuplicateGroup>;
  i, j: Integer;
begin
  RecommendedGroups := FDetector.GetRecommendedDeletions(FDuplicateGroups);

  for i := 0 to Length(RecommendedGroups) - 1 do
  begin
    for j := 0 to Length(RecommendedGroups[i].Files) - 1 do
      FDuplicateGroups[i].Files[j].IsSelected := RecommendedGroups[i].Files[j].IsSelected;
  end;

  // 更新当前显示的文件列表
  if FCurrentGroupIndex >= 0 then
    PopulateFilesList(FCurrentGroupIndex);

  UpdateStats;
end;

procedure TfrmDuplicateFiles.btnDeleteSelectedClick(Sender: TObject);
var
  SelectedCount: Integer;
  TotalSize: Int64;
  MoveToRecycleBin: Boolean;
begin
  // 计算选中的文件数和大小
  SelectedCount := 0;
  TotalSize := 0;
  for var Group in FDuplicateGroups do
  begin
    for var FileInfo in Group.Files do
    begin
      if FileInfo.IsSelected then
      begin
        Inc(SelectedCount);
        Inc(TotalSize, FileInfo.FileSize);
      end;
    end;
  end;

  if SelectedCount = 0 then
  begin
    ShowMessage('请先选择要删除的文件。');
    Exit;
  end;

  MoveToRecycleBin := chkMoveToRecycleBin.Checked;

  var ConfirmMsg := Format('确定要删除 %d 个重复文件吗？' + sLineBreak +
                          '总大小：%s' + sLineBreak +
                          '删除方式：%s',
                          [SelectedCount, FormatFileSize(TotalSize),
                           IfThen(MoveToRecycleBin, '移动到回收站', '永久删除')]);

  if MessageDlg(ConfirmMsg, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    lblStatus.Caption := '正在删除文件...';
    ProgressBar.Visible := True;
    ProgressBar.Position := 0;

    if FDetector.DeleteSelectedFiles(FDuplicateGroups, MoveToRecycleBin) then
    begin
      ShowMessage(Format('成功删除 %d 个重复文件，释放空间 %s',
        [SelectedCount, FormatFileSize(TotalSize)]));

      // 重新扫描以更新结果
      btnStartScanClick(Sender);
    end
    else
    begin
      ShowMessage('删除过程中出现错误，请检查文件是否被占用。');
    end;

    ProgressBar.Visible := False;
  end;
end;

// 列表视图事件处理
procedure TfrmDuplicateFiles.lvGroupsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if Selected and Assigned(Item) then
  begin
    FCurrentGroupIndex := Integer(Item.Data);
    PopulateFilesList(FCurrentGroupIndex);
  end;
end;

procedure TfrmDuplicateFiles.lvFilesItemChecked(Sender: TObject; Item: TListItem);
var
  FileIndex: Integer;
begin
  if (FCurrentGroupIndex >= 0) and Assigned(Item) then
  begin
    FileIndex := Integer(Item.Data);
    if (FileIndex >= 0) and (FileIndex < Length(FDuplicateGroups[FCurrentGroupIndex].Files)) then
    begin
      FDuplicateGroups[FCurrentGroupIndex].Files[FileIndex].IsSelected := Item.Checked;
      UpdateStats;
    end;
  end;
end;

procedure TfrmDuplicateFiles.lvFilesDblClick(Sender: TObject);
var
  FileIndex: Integer;
  FilePath: string;
begin
  FileIndex := GetSelectedFileIndex;
  if (FCurrentGroupIndex >= 0) and (FileIndex >= 0) then
  begin
    FilePath := FDuplicateGroups[FCurrentGroupIndex].Files[FileIndex].FilePath;
    ShellExecute(Handle, 'open', PChar(FilePath), nil, nil, SW_SHOWNORMAL);
  end;
end;

// 右键菜单事件处理
procedure TfrmDuplicateFiles.miSelectGroupClick(Sender: TObject);
var
  GroupIndex: Integer;
  i: Integer;
begin
  GroupIndex := GetSelectedGroupIndex;
  if GroupIndex >= 0 then
  begin
    for i := 0 to Length(FDuplicateGroups[GroupIndex].Files) - 1 do
      FDuplicateGroups[GroupIndex].Files[i].IsSelected := True;

    PopulateFilesList(GroupIndex);
    UpdateStats;
  end;
end;

procedure TfrmDuplicateFiles.miDeselectGroupClick(Sender: TObject);
var
  GroupIndex: Integer;
  i: Integer;
begin
  GroupIndex := GetSelectedGroupIndex;
  if GroupIndex >= 0 then
  begin
    for i := 0 to Length(FDuplicateGroups[GroupIndex].Files) - 1 do
      FDuplicateGroups[GroupIndex].Files[i].IsSelected := False;

    PopulateFilesList(GroupIndex);
    UpdateStats;
  end;
end;

procedure TfrmDuplicateFiles.miOpenLocationClick(Sender: TObject);
var
  GroupIndex: Integer;
  FilePath: string;
begin
  GroupIndex := GetSelectedGroupIndex;
  if GroupIndex >= 0 then
  begin
    FilePath := FDuplicateGroups[GroupIndex].Files[0].FilePath;
    ShellExecute(Handle, 'explore', PChar(ExtractFileDir(FilePath)), nil, nil, SW_SHOWNORMAL);
  end;
end;

procedure TfrmDuplicateFiles.miSelectFileClick(Sender: TObject);
var
  FileIndex: Integer;
begin
  FileIndex := GetSelectedFileIndex;
  if (FCurrentGroupIndex >= 0) and (FileIndex >= 0) then
  begin
    FDuplicateGroups[FCurrentGroupIndex].Files[FileIndex].IsSelected := True;
    lvFiles.Items[FileIndex].Checked := True;
    UpdateStats;
  end;
end;

procedure TfrmDuplicateFiles.miDeselectFileClick(Sender: TObject);
var
  FileIndex: Integer;
begin
  FileIndex := GetSelectedFileIndex;
  if (FCurrentGroupIndex >= 0) and (FileIndex >= 0) then
  begin
    FDuplicateGroups[FCurrentGroupIndex].Files[FileIndex].IsSelected := False;
    lvFiles.Items[FileIndex].Checked := False;
    UpdateStats;
  end;
end;

procedure TfrmDuplicateFiles.miOpenFileClick(Sender: TObject);
begin
  lvFilesDblClick(Sender);
end;

procedure TfrmDuplicateFiles.miOpenFileLocationClick(Sender: TObject);
var
  FileIndex: Integer;
  FilePath: string;
begin
  FileIndex := GetSelectedFileIndex;
  if (FCurrentGroupIndex >= 0) and (FileIndex >= 0) then
  begin
    FilePath := FDuplicateGroups[FCurrentGroupIndex].Files[FileIndex].FilePath;
    ShellExecute(Handle, 'explore', PChar(ExtractFileDir(FilePath)), nil, nil, SW_SHOWNORMAL);
  end;
end;

procedure TfrmDuplicateFiles.miFilePropertiesClick(Sender: TObject);
var
  FileIndex: Integer;
  FilePath: string;
begin
  FileIndex := GetSelectedFileIndex;
  if (FCurrentGroupIndex >= 0) and (FileIndex >= 0) then
  begin
    FilePath := FDuplicateGroups[FCurrentGroupIndex].Files[FileIndex].FilePath;
    ShellExecute(Handle, 'properties', PChar(FilePath), nil, nil, SW_SHOWNORMAL);
  end;
end;

end.

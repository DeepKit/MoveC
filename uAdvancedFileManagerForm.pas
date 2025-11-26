unit uAdvancedFileManagerForm;

{
  高级文件管理界面 - Phase 2.1
  
  功能包括：
  - 文件搜索界面
  - 重复文件查找界面
  - 大文件分析界面
  - 批量操作界面
  - 文件分类展示
  
  作者: AI助手
  版本: 2.1.0
  日期: 2024
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections, System.IOUtils, System.Threading,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.Buttons, Vcl.CheckLst, Vcl.Menus,
  uAdvancedFileManager;

type
  TfrmAdvancedFileManager = class(TForm)
    // 主面板
    pnlMain: TPanel;
    
    // 标签页控制
    pgcMain: TPageControl;
    
    // 文件搜索页
    tsFileSearch: TTabSheet;
    pnlSearchCriteria: TPanel;
    lblSearchPath: TLabel;
    edtSearchPath: TEdit;
    btnBrowseSearchPath: TBitBtn;
    lblNamePattern: TLabel;
    edtNamePattern: TEdit;
    chkUseRegex: TCheckBox;
    lblSizeRange: TLabel;
    edtMinSize: TEdit;
    lblSizeTo: TLabel;
    edtMaxSize: TEdit;
    cmbSizeUnit: TComboBox;
    lblDateRange: TLabel;
    dtpDateFrom: TDateTimePicker;
    lblDateTo: TLabel;
    dtpDateTo: TDateTimePicker;
    chkIncludeSubdirs: TCheckBox;
    chkIncludeHidden: TCheckBox;
    chkIncludeSystem: TCheckBox;
    btnStartSearch: TBitBtn;
    btnCancelSearch: TBitBtn;
    lvSearchResults: TListView;
    
    // 重复文件页
    tsDuplicateFiles: TTabSheet;
    pnlDuplicateControls: TPanel;
    lblDuplicatePath: TLabel;
    edtDuplicatePath: TEdit;
    btnBrowseDuplicatePath: TBitBtn;
    btnFindDuplicates: TBitBtn;
    btnCancelDuplicate: TBitBtn;
    tvDuplicateGroups: TTreeView;
    pnlDuplicateInfo: TPanel;
    lblDuplicateInfo: TLabel;
    btnDeleteSelected: TBitBtn;
    btnKeepNewest: TBitBtn;
    btnKeepLargest: TBitBtn;
    
    // 大文件页
    tsLargeFiles: TTabSheet;
    pnlLargeFileControls: TPanel;
    lblLargePath: TLabel;
    edtLargePath: TEdit;
    btnBrowseLargePath: TBitBtn;
    lblMinFileSize: TLabel;
    edtMinFileSize: TEdit;
    cmbFileSizeUnit: TComboBox;
    btnFindLargeFiles: TBitBtn;
    btnCancelLarge: TBitBtn;
    lvLargeFiles: TListView;
    
    // 批量操作页
    tsBatchOp: TTabSheet;
    pnlBatchControls: TPanel;
    lblBatchOperation: TLabel;
    cmbBatchOperation: TComboBox;
    lblTargetPath: TLabel;
    edtTargetPath: TEdit;
    btnBrowseTargetPath: TBitBtn;
    chkOverwrite: TCheckBox;
    btnAddFiles: TBitBtn;
    btnRemoveFiles: TBitBtn;
    btnClearFiles: TBitBtn;
    btnExecuteBatch: TBitBtn;
    lvBatchFiles: TListView;
    
    // 状态栏和进度
    pnlBottom: TPanel;
    lblStatus: TLabel;
    ProgressBar: TProgressBar;
    btnCancel: TBitBtn;
    
    // 右键菜单
    pmFileList: TPopupMenu;
    miOpenFile: TMenuItem;
    miOpenFolder: TMenuItem;
    miCopyPath: TMenuItem;
    miSeparator1: TMenuItem;
    miProperties: TMenuItem;
    miDelete: TMenuItem;
    
    // 事件处理
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    
    // 搜索功能
    procedure btnBrowseSearchPathClick(Sender: TObject);
    procedure btnStartSearchClick(Sender: TObject);
    procedure btnCancelSearchClick(Sender: TObject);
    procedure lvSearchResultsDblClick(Sender: TObject);
    
    // 重复文件功能
    procedure btnBrowseDuplicatePathClick(Sender: TObject);
    procedure btnFindDuplicatesClick(Sender: TObject);
    procedure btnCancelDuplicateClick(Sender: TObject);
    procedure btnDeleteSelectedClick(Sender: TObject);
    procedure btnKeepNewestClick(Sender: TObject);
    procedure btnKeepLargestClick(Sender: TObject);
    procedure tvDuplicateGroupsChange(Sender: TObject; Node: TTreeNode);
    
    // 大文件功能
    procedure btnBrowseLargePathClick(Sender: TObject);
    procedure btnFindLargeFilesClick(Sender: TObject);
    procedure btnCancelLargeClick(Sender: TObject);
    procedure lvLargeFilesDblClick(Sender: TObject);
    
    // 批量操作功能
    procedure btnBrowseTargetPathClick(Sender: TObject);
    procedure btnAddFilesClick(Sender: TObject);
    procedure btnRemoveFilesClick(Sender: TObject);
    procedure btnClearFilesClick(Sender: TObject);
    procedure btnExecuteBatchClick(Sender: TObject);
    procedure cmbBatchOperationChange(Sender: TObject);
    
    // 右键菜单
    procedure miOpenFileClick(Sender: TObject);
    procedure miOpenFolderClick(Sender: TObject);
    procedure miCopyPathClick(Sender: TObject);
    procedure miPropertiesClick(Sender: TObject);
    procedure miDeleteClick(Sender: TObject);
    
    // 通用操作
    procedure btnCancelClick(Sender: TObject);
    
  private
    FFileManager: TAdvancedFileManager;
    FCurrentTask: TThread;
    FDuplicateGroups: TArray<TDuplicateFileGroup>;
    FLargeFiles: TArray<TAdvancedFileInfo>;
    FSearchResults: TArray<TAdvancedFileInfo>;
    
    procedure InitializeInterface;
    procedure UpdateStatus(const Message: string; Progress: Integer);
    procedure OnFileManagerProgress(const Message: string; Progress: Integer; Cancel: Boolean);
    
    // 界面更新方法
    procedure PopulateSearchResults(const Results: TArray<TAdvancedFileInfo>);
    procedure PopulateDuplicateGroups(const Groups: TArray<TDuplicateFileGroup>);
    procedure PopulateLargeFiles(const Files: TArray<TAdvancedFileInfo>);
    procedure UpdateDuplicateInfo(const Group: TDuplicateFileGroup);
    
    // 工具方法
    function GetCurrentListView: TListView;
    function GetSelectedFiles: TArray<string>;
    function ParseFileSize(const SizeText: string; SizeUnit: Integer): Int64;
    function FormatFileInfo(const FileInfo: TAdvancedFileInfo): string;
    
    // 批量操作相关
    procedure UpdateBatchControls;
    function GetBatchOperationParams: TBatchOperationParams;
    
  public
    { Public declarations }
  end;

var
  frmAdvancedFileManager: TfrmAdvancedFileManager;

implementation

{$R *.dfm}

uses
  System.UITypes, Vcl.FileCtrl, Vcl.Clipbrd, Winapi.ShellAPI;

{ TfrmAdvancedFileManager }

procedure TfrmAdvancedFileManager.FormCreate(Sender: TObject);
begin
  FFileManager := TAdvancedFileManager.Create;
  FFileManager.OnProgress := OnFileManagerProgress;
  
  InitializeInterface;
end;

procedure TfrmAdvancedFileManager.FormDestroy(Sender: TObject);
begin
  if Assigned(FCurrentTask) then
  begin
    FFileManager.CancelOperation;
    if not FCurrentTask.Finished then
    begin
      FCurrentTask.WaitFor;
    end;
  end;
  
  FFileManager.Free;
end;

procedure TfrmAdvancedFileManager.FormShow(Sender: TObject);
begin
  // 设置默认搜索路径为C盘用户目录
  edtSearchPath.Text := GetEnvironmentVariable('USERPROFILE');
  edtDuplicatePath.Text := edtSearchPath.Text;
  edtLargePath.Text := edtSearchPath.Text;
  
  // 设置默认值
  cmbSizeUnit.ItemIndex := 2; // MB
  cmbFileSizeUnit.ItemIndex := 2; // MB
  edtMinFileSize.Text := '100'; // 100MB
  
  // 设置日期范围
  dtpDateFrom.Date := Now - 30; // 30天前
  dtpDateTo.Date := Now;
  
  UpdateStatus('就绪', 0);
end;

procedure TfrmAdvancedFileManager.InitializeInterface;
begin
  // 设置界面
  Caption := '高级文件管理器';
  Position := poScreenCenter;
  WindowState := wsMaximized;
  
  // 设置标签页
  pgcMain.ActivePageIndex := 0;
  
  // 初始化组合框
  cmbSizeUnit.Items.Clear;
  cmbSizeUnit.Items.AddStrings(['B', 'KB', 'MB', 'GB']);
  
  cmbFileSizeUnit.Items.Clear;
  cmbFileSizeUnit.Items.AddStrings(['B', 'KB', 'MB', 'GB']);
  
  cmbBatchOperation.Items.Clear;
  cmbBatchOperation.Items.AddStrings(['复制文件', '移动文件', '删除文件', '重命名文件']);
  cmbBatchOperation.ItemIndex := 0;
  
  // 设置ListView
  with lvSearchResults do
  begin
    ViewStyle := vsReport;
    RowSelect := True;
    GridLines := True;
    
    Columns.Clear;
    with Columns.Add do
    begin
      Caption := '文件名';
      Width := 200;
    end;
    with Columns.Add do
    begin
      Caption := '路径';
      Width := 300;
    end;
    with Columns.Add do
    begin
      Caption := '大小';
      Width := 100;
    end;
    with Columns.Add do
    begin
      Caption := '修改时间';
      Width := 150;
    end;
    with Columns.Add do
    begin
      Caption := '类型';
      Width := 100;
    end;
  end;
  
  // 设置大文件ListView
  with lvLargeFiles do
  begin
    ViewStyle := vsReport;
    RowSelect := True;
    GridLines := True;
    
    Columns.Clear;
    with Columns.Add do
    begin
      Caption := '文件名';
      Width := 200;
    end;
    with Columns.Add do
    begin
      Caption := '路径';
      Width := 300;
    end;
    with Columns.Add do
    begin
      Caption := '大小';
      Width := 100;
    end;
    with Columns.Add do
    begin
      Caption := '修改时间';
      Width := 150;
    end;
  end;
  
  // 设置批量操作ListView
  with lvBatchFiles do
  begin
    ViewStyle := vsReport;
    RowSelect := True;
    GridLines := True;
    CheckBoxes := True;
    
    Columns.Clear;
    with Columns.Add do
    begin
      Caption := '文件名';
      Width := 200;
    end;
    with Columns.Add do
    begin
      Caption := '路径';
      Width := 400;
    end;
    with Columns.Add do
    begin
      Caption := '大小';
      Width := 100;
    end;
  end;
  
  // 设置重复文件TreeView
  tvDuplicateGroups.ReadOnly := True;
  tvDuplicateGroups.ShowLines := True;
  tvDuplicateGroups.ShowButtons := True;
  
  UpdateBatchControls;
end;

procedure TfrmAdvancedFileManager.UpdateStatus(const Message: string; Progress: Integer);
begin
  lblStatus.Caption := Message;
  
  if Progress >= 0 then
  begin
    ProgressBar.Visible := True;
    ProgressBar.Position := Progress;
  end
  else
  begin
    ProgressBar.Visible := False;
  end;
  
  Application.ProcessMessages;
end;

procedure TfrmAdvancedFileManager.OnFileManagerProgress(const Message: string; 
  Progress: Integer; Cancel: Boolean);
begin
  // 在主线程中更新界面
  TThread.Queue(nil, 
    procedure
    begin
      UpdateStatus(Message, Progress);
      btnCancel.Enabled := not Cancel;
    end);
end;

// 文件搜索功能实现

procedure TfrmAdvancedFileManager.btnBrowseSearchPathClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtSearchPath.Text;
  if SelectDirectory('选择搜索目录', '', Dir) then
    edtSearchPath.Text := Dir;
end;

procedure TfrmAdvancedFileManager.btnStartSearchClick(Sender: TObject);
var
  Criteria: TFileSearchCriteria;
begin
  if Trim(edtSearchPath.Text) = '' then
  begin
    ShowMessage('请选择搜索路径！');
    Exit;
  end;
  
  // 设置搜索条件
  ZeroMemory(@Criteria, SizeOf(Criteria));
  Criteria.SearchPath := Trim(edtSearchPath.Text);
  Criteria.NamePattern := Trim(edtNamePattern.Text);
  Criteria.UseRegex := chkUseRegex.Checked;
  Criteria.IncludeSubdirs := chkIncludeSubdirs.Checked;
  Criteria.IncludeHidden := chkIncludeHidden.Checked;
  Criteria.IncludeSystem := chkIncludeSystem.Checked;
  
  // 解析大小范围
  if Trim(edtMinSize.Text) <> '' then
    Criteria.MinSize := ParseFileSize(edtMinSize.Text, cmbSizeUnit.ItemIndex);
  if Trim(edtMaxSize.Text) <> '' then
    Criteria.MaxSize := ParseFileSize(edtMaxSize.Text, cmbSizeUnit.ItemIndex);
  
  // 设置日期范围
  Criteria.DateFrom := dtpDateFrom.Date;
  Criteria.DateTo := dtpDateTo.Date;
  
  btnStartSearch.Enabled := False;
  btnCancelSearch.Enabled := True;
  
  FCurrentTask := TThread.CreateAnonymousThread(
    procedure
    var
      Results: TArray<TAdvancedFileInfo>;
    begin
      try
        Results := FFileManager.SearchFiles(Criteria);
        
        TThread.Queue(nil,
          procedure
          begin
            FSearchResults := Results;
            PopulateSearchResults(Results);
            btnStartSearch.Enabled := True;
            btnCancelSearch.Enabled := False;
          end);
      except
        on E: Exception do
          TThread.Queue(nil,
            procedure
            begin
              UpdateStatus('搜索失败: ' + E.Message, -1);
              btnStartSearch.Enabled := True;
              btnCancelSearch.Enabled := False;
            end);
      end;
    end);
  FCurrentTask.Start;
end;

procedure TfrmAdvancedFileManager.btnCancelSearchClick(Sender: TObject);
begin
  FFileManager.CancelOperation;
  btnCancelSearch.Enabled := False;
end;

procedure TfrmAdvancedFileManager.PopulateSearchResults(const Results: TArray<TAdvancedFileInfo>);
var
  I: Integer;
  Item: TListItem;
begin
  lvSearchResults.Items.BeginUpdate;
  try
    lvSearchResults.Items.Clear;
    
    for I := 0 to High(Results) do
    begin
      Item := lvSearchResults.Items.Add;
      Item.Caption := Results[I].FileName;
      Item.SubItems.Add(ExtractFilePath(Results[I].FullPath));
      Item.SubItems.Add(FFileManager.FormatFileSize(Results[I].FileSize));
      Item.SubItems.Add(DateTimeToStr(Results[I].LastWriteTime));
      Item.SubItems.Add(Results[I].Category);
      Item.Data := Pointer(I);
    end;
    
    UpdateStatus(Format('搜索完成，找到 %d 个文件', [Length(Results)]), 100);
    
  finally
    lvSearchResults.Items.EndUpdate;
  end;
end;

// 重复文件功能实现

procedure TfrmAdvancedFileManager.btnBrowseDuplicatePathClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtDuplicatePath.Text;
  if SelectDirectory('选择扫描目录', '', Dir) then
    edtDuplicatePath.Text := Dir;
end;

procedure TfrmAdvancedFileManager.btnFindDuplicatesClick(Sender: TObject);
begin
  if Trim(edtDuplicatePath.Text) = '' then
  begin
    ShowMessage('请选择扫描路径！');
    Exit;
  end;
  
  btnFindDuplicates.Enabled := False;
  btnCancelDuplicate.Enabled := True;
  
  FCurrentTask := TThread.CreateAnonymousThread(
    procedure
    var
      Groups: TArray<TDuplicateFileGroup>;
    begin
      try
        Groups := FFileManager.FindDuplicateFiles(edtDuplicatePath.Text);
        
        TThread.Queue(nil,
          procedure
          begin
            FDuplicateGroups := Groups;
            PopulateDuplicateGroups(Groups);
            btnFindDuplicates.Enabled := True;
            btnCancelDuplicate.Enabled := False;
          end);
      except
        on E: Exception do
          TThread.Queue(nil,
            procedure
            begin
              UpdateStatus('扫描失败: ' + E.Message, -1);
              btnFindDuplicates.Enabled := True;
              btnCancelDuplicate.Enabled := False;
            end);
      end;
    end);
  FCurrentTask.Start;
end;

procedure TfrmAdvancedFileManager.PopulateDuplicateGroups(const Groups: TArray<TDuplicateFileGroup>);
var
  I, J: Integer;
  GroupNode, FileNode: TTreeNode;
  Group: TDuplicateFileGroup;
  TotalWastedSpace: Int64;
begin
  tvDuplicateGroups.Items.BeginUpdate;
  try
    tvDuplicateGroups.Items.Clear;
    TotalWastedSpace := 0;
    
    for I := 0 to High(Groups) do
    begin
      Group := Groups[I];
      
      GroupNode := tvDuplicateGroups.Items.Add(nil, 
        Format('重复组 %d - %d 个文件 - %s', 
        [I + 1, Group.FileCount, FFileManager.FormatFileSize(Group.TotalSize)]));
      GroupNode.Data := Pointer(I);
      
      for J := 0 to High(Group.Files) do
      begin
        FileNode := tvDuplicateGroups.Items.AddChild(GroupNode,
          Format('%s (%s)', [Group.Files[J].FileName, 
          FFileManager.FormatFileSize(Group.Files[J].FileSize)]));
        FileNode.Data := Pointer(J);
      end;
      
      // 计算浪费的空间（除了一个文件，其他都是重复的）
      TotalWastedSpace := TotalWastedSpace + (Group.TotalSize - Group.Files[0].FileSize);
    end;
    
    UpdateStatus(Format('找到 %d 组重复文件，可节省空间 %s', 
      [Length(Groups), FFileManager.FormatFileSize(TotalWastedSpace)]), 100);
    
  finally
    tvDuplicateGroups.Items.EndUpdate;
  end;
end;

// 批量操作功能实现

procedure TfrmAdvancedFileManager.btnAddFilesClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  I: Integer;
  Item: TListItem;
  FileInfo: TAdvancedFileInfo;
begin
  OpenDialog := TOpenDialog.Create(Self);
  try
    OpenDialog.Options := [ofAllowMultiSelect, ofFileMustExist];
    OpenDialog.Title := '选择要添加的文件';
    
    if OpenDialog.Execute then
    begin
      lvBatchFiles.Items.BeginUpdate;
      try
        for I := 0 to OpenDialog.Files.Count - 1 do
        begin
          FileInfo := FFileManager.GetFileInfo(OpenDialog.Files[I]);
          
          Item := lvBatchFiles.Items.Add;
          Item.Caption := FileInfo.FileName;
          Item.SubItems.Add(FileInfo.FullPath);
          Item.SubItems.Add(FFileManager.FormatFileSize(FileInfo.FileSize));
          Item.Checked := True;
        end;
      finally
        lvBatchFiles.Items.EndUpdate;
      end;
      
      UpdateStatus(Format('已添加 %d 个文件到批量操作列表', [OpenDialog.Files.Count]), -1);
    end;
  finally
    OpenDialog.Free;
  end;
end;

procedure TfrmAdvancedFileManager.btnExecuteBatchClick(Sender: TObject);
var
  Files: TArray<string>;
  Params: TBatchOperationParams;
  I: Integer;
  FileList: TStringList;
begin
  // 收集选中的文件
  FileList := TStringList.Create;
  try
    for I := 0 to lvBatchFiles.Items.Count - 1 do
    begin
      if lvBatchFiles.Items[I].Checked then
        FileList.Add(lvBatchFiles.Items[I].SubItems[0]); // 完整路径
    end;
    
    if FileList.Count = 0 then
    begin
      ShowMessage('请选择要操作的文件！');
      Exit;
    end;
    
    Files := FileList.ToStringArray;
  finally
    FileList.Free;
  end;
  
  // 获取操作参数
  Params := GetBatchOperationParams;
  
  btnExecuteBatch.Enabled := False;
  
  FCurrentTask := TThread.CreateAnonymousThread(
    procedure
    var
      Success: Boolean;
    begin
      try
        Success := FFileManager.BatchOperation(Files, Params);
        
        TThread.Queue(nil,
          procedure
          begin
            if Success then
              UpdateStatus('批量操作完成', 100)
            else
              UpdateStatus('批量操作失败', -1);
            btnExecuteBatch.Enabled := True;
          end);
      except
        on E: Exception do
          TThread.Queue(nil,
            procedure
            begin
              UpdateStatus('批量操作异常: ' + E.Message, -1);
              btnExecuteBatch.Enabled := True;
            end);
      end;
    end);
  FCurrentTask.Start;
end;

function TfrmAdvancedFileManager.GetBatchOperationParams: TBatchOperationParams;
begin
  ZeroMemory(@Result, SizeOf(Result));
  
  case cmbBatchOperation.ItemIndex of
    0: Result.OperationType := botCopy;
    1: Result.OperationType := botMove;
    2: Result.OperationType := botDelete;
    3: Result.OperationType := botRename;
  else
    Result.OperationType := botNone;
  end;
  
  Result.TargetPath := Trim(edtTargetPath.Text);
  Result.OverwriteExisting := chkOverwrite.Checked;
end;

// 工具方法实现

function TfrmAdvancedFileManager.ParseFileSize(const SizeText: string; SizeUnit: Integer): Int64;
var
  Size: Double;
begin
  try
    Size := StrToFloat(SizeText);
    
    case SizeUnit of
      0: Result := Round(Size);                    // Bytes
      1: Result := Round(Size * 1024);             // KB
      2: Result := Round(Size * 1024 * 1024);      // MB
      3: Result := Round(Size * 1024 * 1024 * 1024); // GB
    else
      Result := Round(Size);
    end;
  except
    Result := 0;
  end;
end;

procedure TfrmAdvancedFileManager.UpdateBatchControls;
begin
  case cmbBatchOperation.ItemIndex of
    0, 1: // 复制、移动
    begin
      lblTargetPath.Visible := True;
      edtTargetPath.Visible := True;
      btnBrowseTargetPath.Visible := True;
      chkOverwrite.Visible := True;
    end;
    2: // 删除
    begin
      lblTargetPath.Visible := False;
      edtTargetPath.Visible := False;
      btnBrowseTargetPath.Visible := False;
      chkOverwrite.Visible := False;
    end;
    3: // 重命名
    begin
      lblTargetPath.Visible := False;
      edtTargetPath.Visible := False;
      btnBrowseTargetPath.Visible := False;
      chkOverwrite.Visible := True;
    end;
  end;
end;

// 事件处理方法

procedure TfrmAdvancedFileManager.cmbBatchOperationChange(Sender: TObject);
begin
  UpdateBatchControls;
end;

procedure TfrmAdvancedFileManager.btnBrowseTargetPathClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtTargetPath.Text;
  if SelectDirectory('选择目标目录', '', Dir) then
    edtTargetPath.Text := Dir;
end;

procedure TfrmAdvancedFileManager.btnRemoveFilesClick(Sender: TObject);
var
  I: Integer;
begin
  for I := lvBatchFiles.Items.Count - 1 downto 0 do
  begin
    if lvBatchFiles.Items[I].Selected then
      lvBatchFiles.Items.Delete(I);
  end;
end;

procedure TfrmAdvancedFileManager.btnClearFilesClick(Sender: TObject);
begin
  lvBatchFiles.Items.Clear;
end;

procedure TfrmAdvancedFileManager.btnCancelClick(Sender: TObject);
begin
  FFileManager.CancelOperation;
end;

// 其他未实现的事件处理方法的占位符

procedure TfrmAdvancedFileManager.lvSearchResultsDblClick(Sender: TObject);
begin
  // TODO: 实现双击打开文件
end;

procedure TfrmAdvancedFileManager.btnCancelDuplicateClick(Sender: TObject);
begin
  FFileManager.CancelOperation;
  btnCancelDuplicate.Enabled := False;
end;

procedure TfrmAdvancedFileManager.btnDeleteSelectedClick(Sender: TObject);
begin
  // TODO: 实现删除选中的重复文件
end;

procedure TfrmAdvancedFileManager.btnKeepNewestClick(Sender: TObject);
begin
  // TODO: 实现保留最新文件，删除其他重复文件
end;

procedure TfrmAdvancedFileManager.btnKeepLargestClick(Sender: TObject);
begin
  // TODO: 实现保留最大文件，删除其他重复文件
end;

procedure TfrmAdvancedFileManager.tvDuplicateGroupsChange(Sender: TObject; Node: TTreeNode);
begin
  // TODO: 实现重复文件组信息显示
end;

procedure TfrmAdvancedFileManager.btnBrowseLargePathClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtLargePath.Text;
  if SelectDirectory('选择扫描目录', '', Dir) then
    edtLargePath.Text := Dir;
end;

procedure TfrmAdvancedFileManager.btnFindLargeFilesClick(Sender: TObject);
var
  MinSize: Int64;
begin
  if Trim(edtLargePath.Text) = '' then
  begin
    ShowMessage('请选择扫描路径！');
    Exit;
  end;
  
  MinSize := ParseFileSize(edtMinFileSize.Text, cmbFileSizeUnit.ItemIndex);
  if MinSize <= 0 then
  begin
    ShowMessage('请输入有效的最小文件大小！');
    Exit;
  end;
  
  btnFindLargeFiles.Enabled := False;
  btnCancelLarge.Enabled := True;
  
  FCurrentTask := TThread.CreateAnonymousThread(
    procedure
    var
      Files: TArray<TAdvancedFileInfo>;
    begin
      try
        Files := FFileManager.FindLargeFiles(edtLargePath.Text, MinSize);
        
        TThread.Queue(nil,
          procedure
          begin
            FLargeFiles := Files;
            PopulateLargeFiles(Files);
            btnFindLargeFiles.Enabled := True;
            btnCancelLarge.Enabled := False;
          end);
      except
        on E: Exception do
          TThread.Queue(nil,
            procedure
            begin
              UpdateStatus('扫描失败: ' + E.Message, -1);
              btnFindLargeFiles.Enabled := True;
              btnCancelLarge.Enabled := False;
            end);
      end;
    end);
  FCurrentTask.Start;
end;

procedure TfrmAdvancedFileManager.PopulateLargeFiles(const Files: TArray<TAdvancedFileInfo>);
var
  I: Integer;
  Item: TListItem;
begin
  lvLargeFiles.Items.BeginUpdate;
  try
    lvLargeFiles.Items.Clear;
    
    for I := 0 to High(Files) do
    begin
      Item := lvLargeFiles.Items.Add;
      Item.Caption := Files[I].FileName;
      Item.SubItems.Add(ExtractFilePath(Files[I].FullPath));
      Item.SubItems.Add(FFileManager.FormatFileSize(Files[I].FileSize));
      Item.SubItems.Add(DateTimeToStr(Files[I].LastWriteTime));
      Item.Data := Pointer(I);
    end;
    
    UpdateStatus(Format('找到 %d 个大文件', [Length(Files)]), 100);
    
  finally
    lvLargeFiles.Items.EndUpdate;
  end;
end;

procedure TfrmAdvancedFileManager.btnCancelLargeClick(Sender: TObject);
begin
  FFileManager.CancelOperation;
  btnCancelLarge.Enabled := False;
end;

procedure TfrmAdvancedFileManager.lvLargeFilesDblClick(Sender: TObject);
begin
  // TODO: 实现双击打开大文件
end;

// 右键菜单事件处理方法
procedure TfrmAdvancedFileManager.miOpenFileClick(Sender: TObject);
begin
  // TODO: 实现打开文件
end;

procedure TfrmAdvancedFileManager.miOpenFolderClick(Sender: TObject);
begin
  // TODO: 实现打开文件夹
end;

procedure TfrmAdvancedFileManager.miCopyPathClick(Sender: TObject);
begin
  // TODO: 实现复制路径到剪贴板
end;

procedure TfrmAdvancedFileManager.miPropertiesClick(Sender: TObject);
begin
  // TODO: 实现显示文件属性
end;

procedure TfrmAdvancedFileManager.miDeleteClick(Sender: TObject);
begin
  // TODO: 实现删除文件
end;

// 工具方法的占位符实现

function TfrmAdvancedFileManager.GetCurrentListView: TListView;
begin
  case pgcMain.ActivePageIndex of
    0: Result := lvSearchResults;
    2: Result := lvLargeFiles;
    3: Result := lvBatchFiles;
  else
    Result := nil;
  end;
end;

function TfrmAdvancedFileManager.GetSelectedFiles: TArray<string>;
begin
  // TODO: 实现获取当前选中的文件列表
  SetLength(Result, 0);
end;

function TfrmAdvancedFileManager.FormatFileInfo(const FileInfo: TAdvancedFileInfo): string;
begin
  Result := Format('%s (%s)', [FileInfo.FileName, FFileManager.FormatFileSize(FileInfo.FileSize)]);
end;

procedure TfrmAdvancedFileManager.UpdateDuplicateInfo(const Group: TDuplicateFileGroup);
begin
  // TODO: 实现重复文件组详细信息显示
end;

end.
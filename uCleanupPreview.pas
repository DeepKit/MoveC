unit uCleanupPreview;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI,
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  System.Generics.Defaults, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Buttons, Vcl.Menus, Vcl.CheckLst,
  uCleanupManager;

type
  // 清理项目类型
  TCleanupItemType = (
    citRecycleBin,
    citTempFiles,
    citBrowserCache,
    citWindowsUpdate,
    citSystemLogs,
    citPrefetch
  );

  // 可清理文件记录
  TCleanupItem = record
    FilePath: string;
    FileSize: Int64;
    ItemType: TCleanupItemType;
    IsDirectory: Boolean;
    ModifiedTime: TDateTime;
    Selected: Boolean;
  end;

  // 清理预览窗体
  TfrmCleanupPreview = class(TForm)
  private
    // 面板布局
    pnlTop: TPanel;
    pnlCenter: TPanel;
    pnlBottom: TPanel;
    pnlFilter: TPanel;
    
    // 顶部控件
    lblTitle: TLabel;
    lblScanStatus: TLabel;
    pbScan: TProgressBar;
    
    // 过滤控件
    lblFilter: TLabel;
    chkRecycleBin: TCheckBox;
    chkTempFiles: TCheckBox;
    chkBrowserCache: TCheckBox;
    chkWindowsUpdate: TCheckBox;
    chkSystemLogs: TCheckBox;
    chkPrefetch: TCheckBox;
    btnSelectAll: TButton;
    btnSelectNone: TButton;
    
    // 列表
    lvItems: TListView;
    
    // 底部控件
    lblSummary: TLabel;
    btnScan: TBitBtn;
    btnClean: TBitBtn;
    btnCancel: TBitBtn;
    
    // 右键菜单
    pmItems: TPopupMenu;
    miOpenLocation: TMenuItem;
    miCopyPath: TMenuItem;
    miSelectSimilar: TMenuItem;
    
    // 内部数据
    FItems: TList<TCleanupItem>;
    FCleanupManager: TCleanupManager;
    FScanning: Boolean;
    FCancelled: Boolean;
    FTotalSize: Int64;
    FSelectedSize: Int64;
    FSelectedCount: Integer;
    FSortColumn: Integer;
    FSortAscending: Boolean;
    
    // 事件处理
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnScanClick(Sender: TObject);
    procedure btnCleanClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnSelectAllClick(Sender: TObject);
    procedure btnSelectNoneClick(Sender: TObject);
    procedure lvItemsColumnClick(Sender: TObject; Column: TListColumn);
    procedure lvItemsItemChecked(Sender: TObject; Item: TListItem);
    procedure chkFilterChange(Sender: TObject);
    procedure miOpenLocationClick(Sender: TObject);
    procedure miCopyPathClick(Sender: TObject);
    procedure miSelectSimilarClick(Sender: TObject);
    
    // 内部方法
    procedure CreateControls;
    procedure ScanForCleanableItems;
    procedure ScanDirectory(const APath: string; AType: TCleanupItemType);
    procedure ScanRecycleBin;
    procedure UpdateListView;
    procedure UpdateSummary;
    procedure UpdateProgress(const AMessage: string; AProgress: Integer);
    function GetTypeDisplayName(AType: TCleanupItemType): string;
    function FormatFileSize(ASize: Int64): string;
    function IsTypeSelected(AType: TCleanupItemType): Boolean;
    procedure ExecuteCleanup;
    procedure SortItems(AColumn: Integer; AAscending: Boolean);
    
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    // 返回清理结果
    property CleanupManager: TCleanupManager read FCleanupManager write FCleanupManager;
  end;

var
  frmCleanupPreview: TfrmCleanupPreview;

implementation

uses
  Vcl.Clipbrd, uLogger;

{ TfrmCleanupPreview }

constructor TfrmCleanupPreview.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  
  FItems := TList<TCleanupItem>.Create;
  FScanning := False;
  FCancelled := False;
  FTotalSize := 0;
  FSelectedSize := 0;
  FSelectedCount := 0;
  FSortColumn := -1;
  FSortAscending := True;
  
  // 窗体属性
  Caption := '清理预览 - 选择要清理的项目';
  Width := 900;
  Height := 650;
  Position := poMainFormCenter;
  BorderStyle := bsSizeable;
  Font.Name := 'Microsoft YaHei UI';
  Font.Size := 9;
  
  CreateControls;
end;

destructor TfrmCleanupPreview.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TfrmCleanupPreview.CreateControls;
var
  Col: TListColumn;
begin
  // 顶部面板
  pnlTop := TPanel.Create(Self);
  pnlTop.Parent := Self;
  pnlTop.Align := alTop;
  pnlTop.Height := 80;
  pnlTop.BevelOuter := bvNone;
  pnlTop.Color := $F5F5F5;
  
  lblTitle := TLabel.Create(Self);
  lblTitle.Parent := pnlTop;
  lblTitle.Left := 16;
  lblTitle.Top := 12;
  lblTitle.Caption := '清理预览';
  lblTitle.Font.Size := 14;
  lblTitle.Font.Style := [fsBold];
  
  lblScanStatus := TLabel.Create(Self);
  lblScanStatus.Parent := pnlTop;
  lblScanStatus.Left := 16;
  lblScanStatus.Top := 40;
  lblScanStatus.Caption := '点击"扫描"按钮开始扫描可清理的文件...';
  lblScanStatus.Font.Color := clGray;
  
  pbScan := TProgressBar.Create(Self);
  pbScan.Parent := pnlTop;
  pbScan.Left := 16;
  pbScan.Top := 60;
  pbScan.Width := pnlTop.Width - 32;
  pbScan.Height := 12;
  pbScan.Anchors := [akLeft, akTop, akRight];
  pbScan.Visible := False;
  
  // 过滤面板
  pnlFilter := TPanel.Create(Self);
  pnlFilter.Parent := Self;
  pnlFilter.Align := alTop;
  pnlFilter.Height := 50;
  pnlFilter.BevelOuter := bvNone;
  pnlFilter.Color := $FAFAFA;
  
  lblFilter := TLabel.Create(Self);
  lblFilter.Parent := pnlFilter;
  lblFilter.Left := 16;
  lblFilter.Top := 16;
  lblFilter.Caption := '显示类型:';
  
  chkRecycleBin := TCheckBox.Create(Self);
  chkRecycleBin.Parent := pnlFilter;
  chkRecycleBin.Left := 90;
  chkRecycleBin.Top := 14;
  chkRecycleBin.Caption := '回收站';
  chkRecycleBin.Checked := True;
  chkRecycleBin.OnClick := chkFilterChange;
  
  chkTempFiles := TCheckBox.Create(Self);
  chkTempFiles.Parent := pnlFilter;
  chkTempFiles.Left := 170;
  chkTempFiles.Top := 14;
  chkTempFiles.Caption := '临时文件';
  chkTempFiles.Checked := True;
  chkTempFiles.OnClick := chkFilterChange;
  
  chkBrowserCache := TCheckBox.Create(Self);
  chkBrowserCache.Parent := pnlFilter;
  chkBrowserCache.Left := 260;
  chkBrowserCache.Top := 14;
  chkBrowserCache.Caption := '浏览器缓存';
  chkBrowserCache.Checked := True;
  chkBrowserCache.OnClick := chkFilterChange;
  
  chkWindowsUpdate := TCheckBox.Create(Self);
  chkWindowsUpdate.Parent := pnlFilter;
  chkWindowsUpdate.Left := 370;
  chkWindowsUpdate.Top := 14;
  chkWindowsUpdate.Caption := '更新缓存';
  chkWindowsUpdate.Checked := True;
  chkWindowsUpdate.OnClick := chkFilterChange;
  
  chkSystemLogs := TCheckBox.Create(Self);
  chkSystemLogs.Parent := pnlFilter;
  chkSystemLogs.Left := 470;
  chkSystemLogs.Top := 14;
  chkSystemLogs.Caption := '系统日志';
  chkSystemLogs.Checked := True;
  chkSystemLogs.OnClick := chkFilterChange;
  
  chkPrefetch := TCheckBox.Create(Self);
  chkPrefetch.Parent := pnlFilter;
  chkPrefetch.Left := 560;
  chkPrefetch.Top := 14;
  chkPrefetch.Caption := '预取文件';
  chkPrefetch.Checked := True;
  chkPrefetch.OnClick := chkFilterChange;
  
  btnSelectAll := TButton.Create(Self);
  btnSelectAll.Parent := pnlFilter;
  btnSelectAll.Left := 680;
  btnSelectAll.Top := 12;
  btnSelectAll.Width := 80;
  btnSelectAll.Caption := '全选';
  btnSelectAll.OnClick := btnSelectAllClick;
  
  btnSelectNone := TButton.Create(Self);
  btnSelectNone.Parent := pnlFilter;
  btnSelectNone.Left := 770;
  btnSelectNone.Top := 12;
  btnSelectNone.Width := 80;
  btnSelectNone.Caption := '全不选';
  btnSelectNone.OnClick := btnSelectNoneClick;
  
  // 底部面板
  pnlBottom := TPanel.Create(Self);
  pnlBottom.Parent := Self;
  pnlBottom.Align := alBottom;
  pnlBottom.Height := 60;
  pnlBottom.BevelOuter := bvNone;
  pnlBottom.Color := $F5F5F5;
  
  lblSummary := TLabel.Create(Self);
  lblSummary.Parent := pnlBottom;
  lblSummary.Left := 16;
  lblSummary.Top := 22;
  lblSummary.Caption := '共 0 项，总计 0 B';
  
  btnScan := TBitBtn.Create(Self);
  btnScan.Parent := pnlBottom;
  btnScan.Left := pnlBottom.Width - 320;
  btnScan.Top := 14;
  btnScan.Width := 90;
  btnScan.Height := 32;
  btnScan.Caption := '扫描';
  btnScan.Anchors := [akTop, akRight];
  btnScan.OnClick := btnScanClick;
  
  btnClean := TBitBtn.Create(Self);
  btnClean.Parent := pnlBottom;
  btnClean.Left := pnlBottom.Width - 220;
  btnClean.Top := 14;
  btnClean.Width := 90;
  btnClean.Height := 32;
  btnClean.Caption := '清理选中';
  btnClean.Anchors := [akTop, akRight];
  btnClean.Enabled := False;
  btnClean.OnClick := btnCleanClick;
  
  btnCancel := TBitBtn.Create(Self);
  btnCancel.Parent := pnlBottom;
  btnCancel.Left := pnlBottom.Width - 120;
  btnCancel.Top := 14;
  btnCancel.Width := 90;
  btnCancel.Height := 32;
  btnCancel.Caption := '关闭';
  btnCancel.Anchors := [akTop, akRight];
  btnCancel.OnClick := btnCancelClick;
  
  // 中间列表面板
  pnlCenter := TPanel.Create(Self);
  pnlCenter.Parent := Self;
  pnlCenter.Align := alClient;
  pnlCenter.BevelOuter := bvNone;
  pnlCenter.Padding.Left := 8;
  pnlCenter.Padding.Right := 8;
  pnlCenter.Padding.Top := 4;
  pnlCenter.Padding.Bottom := 4;
  
  // 列表视图
  lvItems := TListView.Create(Self);
  lvItems.Parent := pnlCenter;
  lvItems.Align := alClient;
  lvItems.ViewStyle := vsReport;
  lvItems.RowSelect := True;
  lvItems.GridLines := True;
  lvItems.Checkboxes := True;
  lvItems.ReadOnly := True;
  lvItems.OnColumnClick := lvItemsColumnClick;
  lvItems.OnItemChecked := lvItemsItemChecked;
  
  // 添加列
  Col := lvItems.Columns.Add;
  Col.Caption := '文件路径';
  Col.Width := 400;
  
  Col := lvItems.Columns.Add;
  Col.Caption := '大小';
  Col.Width := 100;
  Col.Alignment := taRightJustify;
  
  Col := lvItems.Columns.Add;
  Col.Caption := '类型';
  Col.Width := 100;
  
  Col := lvItems.Columns.Add;
  Col.Caption := '修改时间';
  Col.Width := 140;
  
  // 右键菜单
  pmItems := TPopupMenu.Create(Self);
  lvItems.PopupMenu := pmItems;
  
  miOpenLocation := TMenuItem.Create(pmItems);
  miOpenLocation.Caption := '打开所在位置';
  miOpenLocation.OnClick := miOpenLocationClick;
  pmItems.Items.Add(miOpenLocation);
  
  miCopyPath := TMenuItem.Create(pmItems);
  miCopyPath.Caption := '复制路径';
  miCopyPath.OnClick := miCopyPathClick;
  pmItems.Items.Add(miCopyPath);
  
  miSelectSimilar := TMenuItem.Create(pmItems);
  miSelectSimilar.Caption := '选中同类型项目';
  miSelectSimilar.OnClick := miSelectSimilarClick;
  pmItems.Items.Add(miSelectSimilar);
end;

procedure TfrmCleanupPreview.FormCreate(Sender: TObject);
begin
  // 空实现
end;

procedure TfrmCleanupPreview.FormDestroy(Sender: TObject);
begin
  // 空实现
end;

procedure TfrmCleanupPreview.FormShow(Sender: TObject);
begin
  // 自动开始扫描
  // btnScanClick(nil);
end;

procedure TfrmCleanupPreview.btnScanClick(Sender: TObject);
begin
  if FScanning then
  begin
    // 取消扫描
    FCancelled := True;
    btnScan.Caption := '扫描';
    Exit;
  end;
  
  FCancelled := False;
  FScanning := True;
  btnScan.Caption := '取消';
  btnClean.Enabled := False;
  pbScan.Visible := True;
  pbScan.Position := 0;
  
  try
    ScanForCleanableItems;
  finally
    FScanning := False;
    btnScan.Caption := '扫描';
    pbScan.Visible := False;
    btnClean.Enabled := FItems.Count > 0;
    UpdateSummary;
  end;
end;

procedure TfrmCleanupPreview.btnCleanClick(Sender: TObject);
begin
  if FSelectedCount = 0 then
  begin
    MessageBox(Handle, '请先选择要清理的项目！', '提示', MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  
  if MessageBox(Handle,
    PChar(Format('确定要清理选中的 %d 个项目吗？' + #13#10 + #13#10 +
                 '预计释放空间：%s' + #13#10 + #13#10 +
                 '此操作不可撤销！',
                 [FSelectedCount, FormatFileSize(FSelectedSize)])),
    '确认清理',
    MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2) = IDYES then
  begin
    ExecuteCleanup;
    ModalResult := mrOk;
  end;
end;

procedure TfrmCleanupPreview.btnCancelClick(Sender: TObject);
begin
  if FScanning then
  begin
    FCancelled := True;
  end
  else
  begin
    ModalResult := mrCancel;
  end;
end;

procedure TfrmCleanupPreview.btnSelectAllClick(Sender: TObject);
var
  I: Integer;
begin
  lvItems.Items.BeginUpdate;
  try
    for I := 0 to lvItems.Items.Count - 1 do
      lvItems.Items[I].Checked := True;
  finally
    lvItems.Items.EndUpdate;
  end;
  UpdateSummary;
end;

procedure TfrmCleanupPreview.btnSelectNoneClick(Sender: TObject);
var
  I: Integer;
begin
  lvItems.Items.BeginUpdate;
  try
    for I := 0 to lvItems.Items.Count - 1 do
      lvItems.Items[I].Checked := False;
  finally
    lvItems.Items.EndUpdate;
  end;
  UpdateSummary;
end;

procedure TfrmCleanupPreview.lvItemsColumnClick(Sender: TObject; Column: TListColumn);
begin
  if FSortColumn = Column.Index then
    FSortAscending := not FSortAscending
  else
  begin
    FSortColumn := Column.Index;
    FSortAscending := True;
  end;
  SortItems(FSortColumn, FSortAscending);
end;

procedure TfrmCleanupPreview.lvItemsItemChecked(Sender: TObject; Item: TListItem);
var
  Idx: Integer;
  CleanupItem: TCleanupItem;
begin
  if Item.Data <> nil then
  begin
    Idx := Integer(Item.Data);
    if (Idx >= 0) and (Idx < FItems.Count) then
    begin
      CleanupItem := FItems[Idx];
      CleanupItem.Selected := Item.Checked;
      FItems[Idx] := CleanupItem;
    end;
  end;
  UpdateSummary;
end;

procedure TfrmCleanupPreview.chkFilterChange(Sender: TObject);
begin
  UpdateListView;
end;

procedure TfrmCleanupPreview.miOpenLocationClick(Sender: TObject);
var
  Item: TListItem;
  FilePath: string;
begin
  Item := lvItems.Selected;
  if Item <> nil then
  begin
    FilePath := Item.Caption;
    ShellExecute(Handle, 'explore', PChar(ExtractFilePath(FilePath)), nil, nil, SW_SHOWNORMAL);
  end;
end;

procedure TfrmCleanupPreview.miCopyPathClick(Sender: TObject);
var
  Item: TListItem;
begin
  Item := lvItems.Selected;
  if Item <> nil then
  begin
    Clipboard.AsText := Item.Caption;
  end;
end;

procedure TfrmCleanupPreview.miSelectSimilarClick(Sender: TObject);
var
  Item: TListItem;
  I, Idx: Integer;
  ItemType: TCleanupItemType;
begin
  Item := lvItems.Selected;
  if (Item <> nil) and (Item.Data <> nil) then
  begin
    Idx := Integer(Item.Data);
    if (Idx >= 0) and (Idx < FItems.Count) then
    begin
      ItemType := FItems[Idx].ItemType;
      
      lvItems.Items.BeginUpdate;
      try
        for I := 0 to lvItems.Items.Count - 1 do
        begin
          Idx := Integer(lvItems.Items[I].Data);
          if (Idx >= 0) and (Idx < FItems.Count) and (FItems[Idx].ItemType = ItemType) then
            lvItems.Items[I].Checked := True;
        end;
      finally
        lvItems.Items.EndUpdate;
      end;
      UpdateSummary;
    end;
  end;
end;

procedure TfrmCleanupPreview.ScanForCleanableItems;
var
  UserProfile: string;
begin
  FItems.Clear;
  FTotalSize := 0;
  
  UserProfile := GetEnvironmentVariable('USERPROFILE');
  
  // 扫描回收站
  UpdateProgress('正在扫描回收站...', 0);
  if not FCancelled then
    ScanRecycleBin;
  
  // 扫描临时文件
  UpdateProgress('正在扫描临时文件...', 15);
  if not FCancelled then
  begin
    ScanDirectory(GetEnvironmentVariable('TEMP'), citTempFiles);
    ScanDirectory('C:\Windows\Temp', citTempFiles);
  end;
  
  // 扫描浏览器缓存
  UpdateProgress('正在扫描浏览器缓存...', 30);
  if not FCancelled then
  begin
    ScanDirectory(TPath.Combine(UserProfile, 'AppData\Local\Google\Chrome\User Data\Default\Cache'), citBrowserCache);
    ScanDirectory(TPath.Combine(UserProfile, 'AppData\Local\Microsoft\Edge\User Data\Default\Cache'), citBrowserCache);
    ScanDirectory(TPath.Combine(UserProfile, 'AppData\Local\Microsoft\Windows\INetCache'), citBrowserCache);
  end;
  
  // 扫描 Windows 更新缓存
  UpdateProgress('正在扫描 Windows 更新缓存...', 50);
  if not FCancelled then
    ScanDirectory('C:\Windows\SoftwareDistribution\Download', citWindowsUpdate);
  
  // 扫描系统日志
  UpdateProgress('正在扫描系统日志...', 70);
  if not FCancelled then
  begin
    ScanDirectory('C:\Windows\Logs', citSystemLogs);
    ScanDirectory('C:\Windows\Debug', citSystemLogs);
  end;
  
  // 扫描预取文件
  UpdateProgress('正在扫描预取文件...', 85);
  if not FCancelled then
    ScanDirectory('C:\Windows\Prefetch', citPrefetch);
  
  UpdateProgress(Format('扫描完成，共发现 %d 个可清理项目', [FItems.Count]), 100);
  
  UpdateListView;
end;

procedure TfrmCleanupPreview.ScanDirectory(const APath: string; AType: TCleanupItemType);
var
  Files: TArray<string>;
  Dirs: TArray<string>;
  FilePath: string;
  Item: TCleanupItem;
  I: Integer;
begin
  if not TDirectory.Exists(APath) then
    Exit;
    
  try
    // 扫描文件
    Files := TDirectory.GetFiles(APath);
    for I := 0 to High(Files) do
    begin
      if FCancelled then Exit;
      
      FilePath := Files[I];
      try
        Item.FilePath := FilePath;
        Item.FileSize := TFile.GetSize(FilePath);
        Item.ItemType := AType;
        Item.IsDirectory := False;
        Item.ModifiedTime := TFile.GetLastWriteTime(FilePath);
        Item.Selected := True;
        
        FItems.Add(Item);
        FTotalSize := FTotalSize + Item.FileSize;
      except
        // 忽略无法访问的文件
      end;
      
      // 每100个文件更新一次界面
      if (I mod 100) = 0 then
        Application.ProcessMessages;
    end;
    
    // 递归扫描子目录
    Dirs := TDirectory.GetDirectories(APath);
    for I := 0 to High(Dirs) do
    begin
      if FCancelled then Exit;
      ScanDirectory(Dirs[I], AType);
    end;
  except
    // 忽略访问权限错误
  end;
end;

procedure TfrmCleanupPreview.ScanRecycleBin;
var
  RecyclePath: string;
  DriveLetters: string;
  I: Integer;
  SID: string;
begin
  // 获取当前用户 SID（简化处理，扫描所有回收站子目录）
  DriveLetters := 'CDEFGHIJ';
  
  for I := 1 to Length(DriveLetters) do
  begin
    if FCancelled then Exit;
    
    RecyclePath := DriveLetters[I] + ':\$Recycle.Bin';
    if TDirectory.Exists(RecyclePath) then
    begin
      try
        // 扫描回收站中的所有文件
        ScanDirectory(RecyclePath, citRecycleBin);
      except
        // 忽略访问错误
      end;
    end;
  end;
end;

procedure TfrmCleanupPreview.UpdateListView;
var
  I: Integer;
  Item: TCleanupItem;
  ListItem: TListItem;
begin
  lvItems.Items.BeginUpdate;
  try
    lvItems.Items.Clear;
    
    for I := 0 to FItems.Count - 1 do
    begin
      Item := FItems[I];
      
      // 检查过滤条件
      if not IsTypeSelected(Item.ItemType) then
        Continue;
      
      ListItem := lvItems.Items.Add;
      ListItem.Caption := Item.FilePath;
      ListItem.SubItems.Add(FormatFileSize(Item.FileSize));
      ListItem.SubItems.Add(GetTypeDisplayName(Item.ItemType));
      ListItem.SubItems.Add(FormatDateTime('yyyy-mm-dd hh:nn', Item.ModifiedTime));
      ListItem.Checked := Item.Selected;
      ListItem.Data := Pointer(I);  // 存储索引
    end;
  finally
    lvItems.Items.EndUpdate;
  end;
  
  UpdateSummary;
end;

procedure TfrmCleanupPreview.UpdateSummary;
var
  I: Integer;
  Item: TCleanupItem;
begin
  FSelectedCount := 0;
  FSelectedSize := 0;
  
  for I := 0 to FItems.Count - 1 do
  begin
    Item := FItems[I];
    if Item.Selected and IsTypeSelected(Item.ItemType) then
    begin
      Inc(FSelectedCount);
      FSelectedSize := FSelectedSize + Item.FileSize;
    end;
  end;
  
  lblSummary.Caption := Format('共 %d 项，选中 %d 项，可释放空间：%s',
    [FItems.Count, FSelectedCount, FormatFileSize(FSelectedSize)]);
    
  btnClean.Enabled := FSelectedCount > 0;
end;

procedure TfrmCleanupPreview.UpdateProgress(const AMessage: string; AProgress: Integer);
begin
  lblScanStatus.Caption := AMessage;
  if AProgress >= 0 then
    pbScan.Position := AProgress;
  Application.ProcessMessages;
end;

function TfrmCleanupPreview.GetTypeDisplayName(AType: TCleanupItemType): string;
begin
  case AType of
    citRecycleBin:    Result := '回收站';
    citTempFiles:     Result := '临时文件';
    citBrowserCache:  Result := '浏览器缓存';
    citWindowsUpdate: Result := '更新缓存';
    citSystemLogs:    Result := '系统日志';
    citPrefetch:      Result := '预取文件';
  else
    Result := '其他';
  end;
end;

function TfrmCleanupPreview.FormatFileSize(ASize: Int64): string;
begin
  if ASize < 1024 then
    Result := Format('%d B', [ASize])
  else if ASize < 1024 * 1024 then
    Result := Format('%.1f KB', [ASize / 1024])
  else if ASize < 1024 * 1024 * 1024 then
    Result := Format('%.2f MB', [ASize / (1024 * 1024)])
  else
    Result := Format('%.2f GB', [ASize / (1024 * 1024 * 1024)]);
end;

function TfrmCleanupPreview.IsTypeSelected(AType: TCleanupItemType): Boolean;
begin
  case AType of
    citRecycleBin:    Result := chkRecycleBin.Checked;
    citTempFiles:     Result := chkTempFiles.Checked;
    citBrowserCache:  Result := chkBrowserCache.Checked;
    citWindowsUpdate: Result := chkWindowsUpdate.Checked;
    citSystemLogs:    Result := chkSystemLogs.Checked;
    citPrefetch:      Result := chkPrefetch.Checked;
  else
    Result := True;
  end;
end;

procedure TfrmCleanupPreview.ExecuteCleanup;
var
  I: Integer;
  Item: TCleanupItem;
  DeletedCount: Integer;
  DeletedSize: Int64;
  FailedCount: Integer;
begin
  DeletedCount := 0;
  DeletedSize := 0;
  FailedCount := 0;
  
  pbScan.Visible := True;
  pbScan.Position := 0;
  
  try
    for I := 0 to FItems.Count - 1 do
    begin
      Item := FItems[I];
      
      if not Item.Selected then
        Continue;
        
      UpdateProgress(Format('正在清理: %s', [ExtractFileName(Item.FilePath)]),
        Round((I + 1) * 100 / FItems.Count));
      
      try
        if Item.IsDirectory then
        begin
          if TDirectory.Exists(Item.FilePath) then
            TDirectory.Delete(Item.FilePath, True);
        end
        else
        begin
          if TFile.Exists(Item.FilePath) then
            TFile.Delete(Item.FilePath);
        end;
        
        Inc(DeletedCount);
        DeletedSize := DeletedSize + Item.FileSize;
      except
        Inc(FailedCount);
        LogWarning('CleanupPreview', '删除失败: ' + Item.FilePath);
      end;
      
      Application.ProcessMessages;
    end;
    
    UpdateProgress('清理完成', 100);
    
    MessageBox(Handle,
      PChar(Format('清理完成！' + #13#10 + #13#10 +
                   '成功删除：%d 项' + #13#10 +
                   '释放空间：%s' + #13#10 +
                   '失败项目：%d 个',
                   [DeletedCount, FormatFileSize(DeletedSize), FailedCount])),
      '清理结果',
      MB_OK or MB_ICONINFORMATION);
      
    LogInfo('CleanupPreview', Format('清理完成: 删除 %d 项, 释放 %s, 失败 %d 项',
      [DeletedCount, FormatFileSize(DeletedSize), FailedCount]));
      
  finally
    pbScan.Visible := False;
  end;
end;

procedure TfrmCleanupPreview.SortItems(AColumn: Integer; AAscending: Boolean);
var
  Sign: Integer;
begin
  // AAscending = True 表示升序，False 表示降序
  if AAscending then Sign := 1 else Sign := -1;
  
  case AColumn of
    0: // 按路径排序
      FItems.Sort(TComparer<TCleanupItem>.Construct(
        function(const Left, Right: TCleanupItem): Integer
        begin
          Result := Sign * CompareText(Left.FilePath, Right.FilePath);
        end));
    1: // 按大小排序
      FItems.Sort(TComparer<TCleanupItem>.Construct(
        function(const Left, Right: TCleanupItem): Integer
        begin
          if Left.FileSize = Right.FileSize then Result := 0
          else if Left.FileSize < Right.FileSize then Result := -1 * Sign
          else Result := 1 * Sign;
        end));
    2: // 按类型排序
      FItems.Sort(TComparer<TCleanupItem>.Construct(
        function(const Left, Right: TCleanupItem): Integer
        begin
          Result := Sign * (Ord(Left.ItemType) - Ord(Right.ItemType));
        end));
    3: // 按修改时间排序
      FItems.Sort(TComparer<TCleanupItem>.Construct(
        function(const Left, Right: TCleanupItem): Integer
        begin
          if Left.ModifiedTime = Right.ModifiedTime then Result := 0
          else if Left.ModifiedTime < Right.ModifiedTime then Result := -1 * Sign
          else Result := 1 * Sign;
        end));
  end;
  
  UpdateListView;
end;

end.

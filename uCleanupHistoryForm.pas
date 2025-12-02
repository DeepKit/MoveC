unit uCleanupHistoryForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, System.Generics.Collections,
  uCleanupHistory;

type
  TfrmCleanupHistory = class(TForm)
    pnlMain: TPanel;
    pnlTop: TPanel;
    lblTitle: TLabel;
    pnlSummary: TPanel;
    lblTotalSpace: TLabel;
    lblTotalFiles: TLabel;
    lblTotalRecords: TLabel;
    pnlFilter: TPanel;
    lblFilter: TLabel;
    cbFilterType: TComboBox;
    btnRefresh: TButton;
    pnlList: TPanel;
    lvHistory: TListView;
    pnlButtons: TPanel;
    btnExportText: TButton;
    btnExportJSON: TButton;
    btnClear: TButton;
    btnClose: TButton;
    SaveDialog: TSaveDialog;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnExportTextClick(Sender: TObject);
    procedure btnExportJSONClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure cbFilterTypeChange(Sender: TObject);
    procedure lvHistoryCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure lvHistoryColumnClick(Sender: TObject; Column: TListColumn);
    
  private
    FSortColumn: Integer;
    FSortAscending: Boolean;
    
    procedure InitializeUI;
    procedure LoadHistory;
    procedure UpdateSummary;
    procedure SortListView(AColumn: Integer);
    function FormatSpaceFreed(ASize: Int64): string;
    
  public
    class procedure ShowHistory;
  end;

var
  frmCleanupHistory: TfrmCleanupHistory;

implementation

{$R *.dfm}

uses
  System.Math, System.StrUtils, System.IOUtils, System.DateUtils,
  Winapi.CommCtrl, System.Generics.Defaults;

{ TfrmCleanupHistory }

class procedure TfrmCleanupHistory.ShowHistory;
var
  Form: TfrmCleanupHistory;
begin
  Form := TfrmCleanupHistory.Create(Application);
  try
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

procedure TfrmCleanupHistory.FormCreate(Sender: TObject);
begin
  FSortColumn := -1;
  FSortAscending := False; // Default: newest first
  
  InitializeUI;
  LoadHistory;
  UpdateSummary;
end;

procedure TfrmCleanupHistory.FormDestroy(Sender: TObject);
begin
  // Nothing to cleanup
end;

procedure TfrmCleanupHistory.InitializeUI;
begin
  // Form properties
  Caption := '清理历史记录';
  Width := 900;
  Height := 600;
  Position := poScreenCenter;
  BorderStyle := bsSizeable;
  
  // Initialize filter combo
  cbFilterType.Items.Clear;
  cbFilterType.Items.Add('全部类型');
  cbFilterType.Items.Add('回收站清理');
  cbFilterType.Items.Add('临时文件清理');
  cbFilterType.Items.Add('浏览器缓存清理');
  cbFilterType.Items.Add('Windows更新缓存清理');
  cbFilterType.Items.Add('系统日志清理');
  cbFilterType.Items.Add('预取文件清理');
  cbFilterType.Items.Add('智能清理');
  cbFilterType.ItemIndex := 0;
  
  // Initialize ListView columns
  with lvHistory do
  begin
    Columns.Clear;
    
    with Columns.Add do
    begin
      Caption := '时间';
      Width := 150;
    end;
    
    with Columns.Add do
    begin
      Caption := '类型';
      Width := 140;
    end;
    
    with Columns.Add do
    begin
      Caption := '状态';
      Width := 60;
    end;
    
    with Columns.Add do
    begin
      Caption := '删除文件';
      Width := 80;
      Alignment := taRightJustify;
    end;
    
    with Columns.Add do
    begin
      Caption := '释放空间';
      Width := 100;
      Alignment := taRightJustify;
    end;
    
    with Columns.Add do
    begin
      Caption := '耗时';
      Width := 80;
      Alignment := taRightJustify;
    end;
    
    with Columns.Add do
    begin
      Caption := '错误信息';
      Width := 250;
    end;
    
    ViewStyle := vsReport;
    RowSelect := True;
    GridLines := True;
  end;
end;

procedure TfrmCleanupHistory.LoadHistory;
var
  Entries: TArray<TCleanupHistoryEntry>;
  Entry: TCleanupHistoryEntry;
  ListItem: TListItem;
  FilterType: Integer;
  I: Integer;
  SortCol: Integer;
  SortAsc: Boolean;
begin
  lvHistory.Items.BeginUpdate;
  try
    lvHistory.Clear;
    
    FilterType := cbFilterType.ItemIndex;
    
    // Get entries based on filter
    if FilterType = 0 then
      Entries := CleanupHistory.GetAllEntries
    else
      Entries := CleanupHistory.GetEntriesByType(TCleanupType(FilterType - 1));
    
    // Sort entries if needed
    SortCol := FSortColumn;
    SortAsc := FSortAscending;
    if (SortCol >= 0) and (Length(Entries) > 1) then
    begin
      TArray.Sort<TCleanupHistoryEntry>(Entries, TComparer<TCleanupHistoryEntry>.Construct(
        function(const A, B: TCleanupHistoryEntry): Integer
        begin
          case SortCol of
            0: Result := CompareDateTime(A.Timestamp, B.Timestamp); // Time
            1: Result := CompareText(A.TypeName, B.TypeName); // Type
            2: Result := Ord(A.Success) - Ord(B.Success); // Status
            3: Result := A.FilesDeleted - B.FilesDeleted; // Files
            4: begin // Space
                 if A.SpaceFreed < B.SpaceFreed then Result := -1
                 else if A.SpaceFreed > B.SpaceFreed then Result := 1
                 else Result := 0;
               end;
            5: Result := A.Duration - B.Duration; // Duration
            6: Result := CompareText(A.ErrorMessage, B.ErrorMessage); // Error
          else
            Result := 0;
          end;
          if not SortAsc then Result := -Result;
        end));
    end;
    
    // Add to ListView
    for I := 0 to High(Entries) do
    begin
      Entry := Entries[I];
      
      ListItem := lvHistory.Items.Add;
      ListItem.Caption := FormatDateTime('yyyy-mm-dd hh:nn:ss', Entry.Timestamp);
      ListItem.SubItems.Add(Entry.TypeName);
      ListItem.SubItems.Add(IfThen(Entry.Success, '成功', '失败'));
      ListItem.SubItems.Add(IntToStr(Entry.FilesDeleted));
      ListItem.SubItems.Add(FormatSpaceFreed(Entry.SpaceFreed));
      ListItem.SubItems.Add(Entry.GetDurationStr);
      ListItem.SubItems.Add(Entry.ErrorMessage);
      
      // Store success status in Data for custom drawing
      ListItem.Data := Pointer(NativeInt(Ord(Entry.Success)));
    end;
    
  finally
    lvHistory.Items.EndUpdate;
  end;
end;

procedure TfrmCleanupHistory.UpdateSummary;
var
  TotalSpace: Int64;
  TotalFiles: Integer;
  RecordCount: Integer;
begin
  TotalSpace := CleanupHistory.GetTotalSpaceFreed;
  TotalFiles := CleanupHistory.GetTotalFilesDeleted;
  RecordCount := CleanupHistory.GetEntryCount;
  
  lblTotalRecords.Caption := Format('总记录: %d 条', [RecordCount]);
  lblTotalFiles.Caption := Format('累计删除: %d 个文件', [TotalFiles]);
  lblTotalSpace.Caption := Format('累计释放: %s', [FormatSpaceFreed(TotalSpace)]);
end;

function TfrmCleanupHistory.FormatSpaceFreed(ASize: Int64): string;
begin
  if ASize < 1024 then
    Result := Format('%d B', [ASize])
  else if ASize < 1024 * 1024 then
    Result := Format('%.2f KB', [ASize / 1024])
  else if ASize < 1024 * 1024 * 1024 then
    Result := Format('%.2f MB', [ASize / (1024 * 1024)])
  else
    Result := Format('%.2f GB', [ASize / (1024 * 1024 * 1024)]);
end;

procedure TfrmCleanupHistory.btnRefreshClick(Sender: TObject);
begin
  LoadHistory;
  UpdateSummary;
end;

procedure TfrmCleanupHistory.cbFilterTypeChange(Sender: TObject);
begin
  LoadHistory;
end;

procedure TfrmCleanupHistory.btnExportTextClick(Sender: TObject);
begin
  SaveDialog.Filter := '文本文件 (*.txt)|*.txt';
  SaveDialog.DefaultExt := 'txt';
  SaveDialog.FileName := Format('清理历史报告_%s.txt', [FormatDateTime('yyyymmdd_hhnnss', Now)]);
  
  if SaveDialog.Execute then
  begin
    if CleanupHistory.ExportToText(SaveDialog.FileName) then
      ShowMessage('报告已导出到: ' + SaveDialog.FileName)
    else
      ShowMessage('导出失败!');
  end;
end;

procedure TfrmCleanupHistory.btnExportJSONClick(Sender: TObject);
begin
  SaveDialog.Filter := 'JSON文件 (*.json)|*.json';
  SaveDialog.DefaultExt := 'json';
  SaveDialog.FileName := Format('清理历史_%s.json', [FormatDateTime('yyyymmdd_hhnnss', Now)]);
  
  if SaveDialog.Execute then
  begin
    if CleanupHistory.ExportToJSON(SaveDialog.FileName) then
      ShowMessage('历史记录已导出到: ' + SaveDialog.FileName)
    else
      ShowMessage('导出失败!');
  end;
end;

procedure TfrmCleanupHistory.btnClearClick(Sender: TObject);
begin
  if MessageDlg('确定要清空所有清理历史记录吗？' + sLineBreak + '此操作不可撤销！',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    CleanupHistory.ClearHistory;
    LoadHistory;
    UpdateSummary;
    ShowMessage('历史记录已清空');
  end;
end;

procedure TfrmCleanupHistory.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmCleanupHistory.lvHistoryCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  Success: Boolean;
begin
  Success := Boolean(NativeInt(Item.Data));
  
  if not Success then
    Sender.Canvas.Brush.Color := $E0E0FF // Light red for failures
  else
    Sender.Canvas.Brush.Color := clWhite;
  
  if cdsSelected in State then
    Sender.Canvas.Brush.Color := clHighlight;
end;

procedure TfrmCleanupHistory.lvHistoryColumnClick(Sender: TObject; Column: TListColumn);
begin
  SortListView(Column.Index);
end;

procedure TfrmCleanupHistory.SortListView(AColumn: Integer);
begin
  if lvHistory.Items.Count < 2 then Exit;
  
  // Toggle sort direction if same column clicked
  if FSortColumn = AColumn then
    FSortAscending := not FSortAscending
  else
  begin
    FSortColumn := AColumn;
    FSortAscending := True;
  end;
  
  // Reload data to apply sort (simpler approach)
  LoadHistory;
end;

end.

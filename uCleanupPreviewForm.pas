unit uCleanupPreviewForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.Grids, Vcl.Buttons, System.Generics.Collections,
  uEnhancedCleanupManager;

type
  TfrmCleanupPreview = class(TForm)
    pnlMain: TPanel;
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlSafety: TPanel;
    lblSafety: TLabel;
    cbSafetyLevel: TComboBox;
    btnPreview: TButton;
    pnlProgress: TPanel;
    ProgressBar: TProgressBar;
    lblProgress: TLabel;
    pnlResults: TPanel;
    pnlSummary: TPanel;
    lblTotalItems: TLabel;
    lblTotalSize: TLabel;
    lblSafeItems: TLabel;
    lblRiskyItems: TLabel;
    lblEstimatedTime: TLabel;
    pnlItems: TPanel;
    lvItems: TListView;
    pnlButtons: TPanel;
    btnSelectAll: TButton;
    btnSelectSafe: TButton;
    btnDeselectAll: TButton;
    btnCleanSelected: TButton;
    btnCancel: TButton;
    btnClose: TButton;
    chkShowRisky: TCheckBox;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnPreviewClick(Sender: TObject);
    procedure btnSelectAllClick(Sender: TObject);
    procedure btnSelectSafeClick(Sender: TObject);
    procedure btnDeselectAllClick(Sender: TObject);
    procedure btnCleanSelectedClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure cbSafetyLevelChange(Sender: TObject);
    procedure chkShowRiskyClick(Sender: TObject);
    procedure lvItemsCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure lvItemsColumnClick(Sender: TObject; Column: TListColumn);
    
  private
    FCleanupManager: TEnhancedCleanupManager;
    FCurrentPreview: TCleanupPreview;
    FIsPreviewing: Boolean;
    FIsCleaning: Boolean;
    FSelectedItems: TList<Integer>;
    
    procedure UpdateSafetyLevel;
    procedure DisplayPreviewResults;
    procedure UpdateItemSelection;
    procedure UpdateButtonStates;
    procedure FormatFileSizeLabel(ALabel: TLabel; ASize: Int64);
    procedure OnPreviewProgress(const AMessage: string; AProgress: Integer; const ACurrentItem: string);
    function OnCleanupConfirm(const AItem: TCleanupItem): Boolean;
    procedure ShowCleanupResult(const AResult: TCleanupResult);
    
  public
    procedure InitializePreview;
  end;

var
  frmCleanupPreview: TfrmCleanupPreview;

implementation

{$R *.dfm}

uses
  System.Math, System.StrUtils, Vcl.Themes, Vcl.GraphUtil;

{ TfrmCleanupPreview }

procedure TfrmCleanupPreview.FormCreate(Sender: TObject);
begin
  FCleanupManager := TEnhancedCleanupManager.Create;
  FSelectedItems := TList<Integer>.Create;
  FIsPreviewing := False;
  FIsCleaning := False;
  
  // 设置窗体属性
  Caption := '清理预览';
  Width := 800;
  Height := 600;
  Position := poScreenCenter;
  BorderStyle := bsSizeable;
  
  // 初始化安全级别
  cbSafetyLevel.Items.Add('保守模式（最安全）');
  cbSafetyLevel.Items.Add('标准模式（推荐）');
  cbSafetyLevel.Items.Add('激进模式（最大清理）');
  cbSafetyLevel.ItemIndex := 1; // 默认标准模式
  
  // 初始化列表视图
  InitializeListView;
  
  // 设置回调
  FCleanupManager.OnPreviewProgress := OnPreviewProgress;
  FCleanupManager.OnCleanupConfirm := OnCleanupConfirm;
  
  UpdateButtonStates;
end;

procedure TfrmCleanupPreview.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FCleanupManager);
  FreeAndNil(FSelectedItems);
end;

procedure TfrmCleanupPreview.InitializeListView;
begin
  with lvItems do
  begin
    Columns.BeginUpdate;
    try
      Clear;
      Columns.Add;
      Columns[0].Caption := '项目名称';
      Columns[0].Width := 200;
      
      Columns.Add;
      Columns[1].Caption := '类型';
      Columns[1].Width := 100;
      
      Columns.Add;
      Columns[2].Caption := '大小';
      Columns[2].Width := 120;
      Columns[2].Alignment := taRightJustify;
      
      Columns.Add;
      Columns[3].Caption := '文件数量';
      Columns[3].Width := 80;
      Columns[3].Alignment := taRightJustify;
      
      Columns.Add;
      Columns[4].Caption := '风险等级';
      Columns[4].Width := 80;
      
      Columns.Add;
      Columns[5].Caption := '描述';
      Columns[5].Width := 200;
      
      CheckBoxes := True;
      GridLines := True;
      RowSelect := True;
      ViewStyle := vsReport;
    finally
      Columns.EndUpdate;
    end;
  end;
end;

procedure TfrmCleanupPreview.InitializePreview;
begin
  UpdateSafetyLevel;
  btnPreview.Click;
end;

procedure TfrmCleanupPreview.UpdateSafetyLevel;
begin
  case cbSafetyLevel.ItemIndex of
    0: FCleanupManager.SafetyLevel := slConservative;
    1: FCleanupManager.SafetyLevel := slStandard;
    2: FCleanupManager.SafetyLevel := slAggressive;
  end;
end;

procedure TfrmCleanupPreview.btnPreviewClick(Sender: TObject);
var
  StartTime: TDateTime;
begin
  if FIsPreviewing or FIsCleaning then Exit;
  
  FIsPreviewing := True;
  UpdateButtonStates;
  
  try
    UpdateSafetyLevel;
    
    pnlResults.Visible := False;
    pnlProgress.Visible := True;
    ProgressBar.Position := 0;
    lblProgress.Caption := '开始预览...';
    
    StartTime := Now;
    Application.ProcessMessages;
    
    FCurrentPreview := FCleanupManager.PreviewAllCleanup;
    
    DisplayPreviewResults;
    
  finally
    FIsPreviewing := False;
    pnlProgress.Visible := False;
    UpdateButtonStates;
  end;
end;

procedure TfrmCleanupPreview.DisplayPreviewResults;
var
  I: Integer;
  Item: TCleanupItem;
  ListItem: TListItem;
begin
  // 更新摘要信息
  lblTotalItems.Caption := Format('清理项目: %d 个', [FCurrentPreview.TotalItems]);
  FormatFileSizeLabel(lblTotalSize, FCurrentPreview.TotalSize);
  lblSafeItems.Caption := Format('安全项目: %d 个', [FCurrentPreview.SafeItems]);
  lblRiskyItems.Caption := Format('风险项目: %d 个', [FCurrentPreview.RiskyItems]);
  lblEstimatedTime.Caption := Format('预计时间: %d 秒', [FCurrentPreview.EstimatedTime]);
  
  // 清空列表
  lvItems.Clear;
  FSelectedItems.Clear;
  
  // 添加项目到列表
  for I := 0 to High(FCurrentPreview.Items) do
  begin
    Item := FCurrentPreview.Items[I];
    
    ListItem := lvItems.Items.Add;
    ListItem.Caption := Item.ItemName;
    ListItem.SubItems.Add(CleanupItemTypeToString(Item.ItemType));
    ListItem.SubItems.Add(FormatFileSize(Item.ItemSize));
    ListItem.SubItems.Add(IntToStr(Item.FileCount));
    ListItem.SubItems.Add(Format('%d/10', [Item.RiskLevel]));
    ListItem.SubItems.Add(Item.Description);
    ListItem.Checked := Item.IsSafe; // 默认选中安全项目
    ListItem.Data := Pointer(I);
    
    if Item.IsSafe then
      FSelectedItems.Add(I);
  end;
  
  pnlResults.Visible := True;
end;

procedure TfrmCleanupPreview.btnSelectAllClick(Sender: TObject);
var
  I: Integer;
begin
  FSelectedItems.Clear;
  for I := 0 to lvItems.Items.Count - 1 do
  begin
    lvItems.Items[I].Checked := True;
    FSelectedItems.Add(Integer(lvItems.Items[I].Data));
  end;
  UpdateButtonStates;
end;

procedure TfrmCleanupPreview.btnSelectSafeClick(Sender: TObject);
var
  I: Integer;
  Item: TCleanupItem;
begin
  FSelectedItems.Clear;
  for I := 0 to lvItems.Items.Count - 1 do
  begin
    Item := FCurrentPreview.Items[Integer(lvItems.Items[I].Data)];
    lvItems.Items[I].Checked := Item.IsSafe;
    if Item.IsSafe then
      FSelectedItems.Add(Integer(lvItems.Items[I].Data));
  end;
  UpdateButtonStates;
end;

procedure TfrmCleanupPreview.btnDeselectAllClick(Sender: TObject);
var
  I: Integer;
begin
  FSelectedItems.Clear;
  for I := 0 to lvItems.Items.Count - 1 do
    lvItems.Items[I].Checked := False;
  UpdateButtonStates;
end;

procedure TfrmCleanupPreview.btnCleanSelectedClick(Sender: TObject);
var
  SelectedPreview: TCleanupPreview;
  SelectedIndices: TArray<Integer>;
  I: Integer;
  Result: TCleanupResult;
begin
  if FIsCleaning or FIsPreviewing then Exit;
  
  if FSelectedItems.Count = 0 then
  begin
    ShowMessage('请先选择要清理的项目！');
    Exit;
  end;
  
  if not (MessageDlg('确定要清理选中的 ' + IntToStr(FSelectedItems.Count) + ' 个项目吗？' + sLineBreak +
                    '此操作不可撤销！', mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
    Exit;
  
  FIsCleaning := True;
  UpdateButtonStates;
  
  try
    // 准备选中的项目
    SelectedIndices := FSelectedItems.ToArray;
    SetLength(SelectedPreview.Items, Length(SelectedIndices));
    
    for I := 0 to High(SelectedIndices) do
      SelectedPreview.Items[I] := FCurrentPreview.Items[SelectedIndices[I]];
    
    SelectedPreview.TotalItems := Length(SelectedIndices);
    SelectedPreview.SafeItems := FSelectedItems.Count;
    SelectedPreview.RiskyItems := 0;
    
    // 执行清理
    pnlProgress.Visible := True;
    ProgressBar.Position := 0;
    lblProgress.Caption := '开始清理...';
    Application.ProcessMessages;
    
    Result := FCleanupManager.PerformEnhancedCleanup(SelectedPreview);
    
    pnlProgress.Visible := False;
    ShowCleanupResult(Result);
    
    // 清理完成后重新预览
    btnPreview.Click;
    
  finally
    FIsCleaning := False;
    UpdateButtonStates;
  end;
end;

procedure TfrmCleanupPreview.btnCancelClick(Sender: TObject);
begin
  if FIsPreviewing then
    FCleanupManager.Cancel
  else if FIsCleaning then
    FCleanupManager.Cancel;
end;

procedure TfrmCleanupPreview.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmCleanupPreview.cbSafetyLevelChange(Sender: TObject);
begin
  if not FIsPreviewing and not FIsCleaning then
    btnPreview.Click;
end;

procedure TfrmCleanupPreview.chkShowRiskyClick(Sender: TObject);
var
  I: Integer;
  Item: TCleanupItem;
  ListItem: TListItem;
begin
  for I := 0 to lvItems.Items.Count - 1 do
  begin
    ListItem := lvItems.Items[I];
    Item := FCurrentPreview.Items[Integer(ListItem.Data)];
    
    if not chkShowRisky.Checked and (Item.RiskLevel > 5) then
      ListItem.Visible := False
    else
      ListItem.Visible := True;
  end;
end;

procedure TfrmCleanupPreview.lvItemsCustomDrawItem(Sender: TCustomListView; 
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  CleanupItem: TCleanupItem;
  ItemColor: TColor;
begin
  if not Assigned(Item.Data) then Exit;
  
  CleanupItem := FCurrentPreview.Items[Integer(Item.Data)];
  
  // 根据风险等级设置颜色
  case CleanupItem.RiskLevel of
    0..2: ItemColor := $E8F5E8; // 浅绿色 - 安全
    3..5: ItemColor := $FFF8E8; // 浅黄色 - 中等
    6..8: ItemColor := $FFE8E8; // 浅红色 - 风险
    9..10: ItemColor := $F0E8FF; // 浅紫色 - 危险
  else
    ItemColor := clWhite;
  end;
  
  Sender.Canvas.Brush.Color := ItemColor;
  
  if cdsSelected in State then
    Sender.Canvas.Brush.Color := clHighlight;
end;

procedure TfrmCleanupPreview.lvItemsColumnClick(Sender: TObject; 
  Column: TListColumn);
begin
  // 可以添加排序功能
end;

procedure TfrmCleanupPreview.UpdateButtonStates;
begin
  btnPreview.Enabled := not FIsPreviewing and not FIsCleaning;
  cbSafetyLevel.Enabled := not FIsPreviewing and not FIsCleaning;
  
  btnSelectAll.Enabled := (lvItems.Items.Count > 0) and not FIsCleaning;
  btnSelectSafe.Enabled := (lvItems.Items.Count > 0) and not FIsCleaning;
  btnDeselectAll.Enabled := (lvItems.Items.Count > 0) and not FIsCleaning;
  btnCleanSelected.Enabled := (FSelectedItems.Count > 0) and not FIsCleaning;
  
  btnCancel.Enabled := FIsPreviewing or FIsCleaning;
  btnClose.Enabled := not FIsPreviewing and not FIsCleaning;
  
  chkShowRisky.Enabled := (lvItems.Items.Count > 0) and not FIsCleaning;
end;

procedure TfrmCleanupPreview.FormatFileSizeLabel(ALabel: TLabel; ASize: Int64);
begin
  if ASize < 1024 then
    ALabel.Caption := Format('总大小: %d 字节', [ASize])
  else if ASize < 1024 * 1024 then
    ALabel.Caption := Format('总大小: %.1f KB', [ASize / 1024.0])
  else if ASize < 1024 * 1024 * 1024 then
    ALabel.Caption := Format('总大小: %.1f MB', [ASize / (1024.0 * 1024.0)])
  else
    ALabel.Caption := Format('总大小: %.2f GB', [ASize / (1024.0 * 1024.0 * 1024.0)]);
end;

procedure TfrmCleanupPreview.OnPreviewProgress(const AMessage: string; 
  AProgress: Integer; const ACurrentItem: string);
begin
  ProgressBar.Position := AProgress;
  lblProgress.Caption := AMessage;
  if ACurrentItem <> '' then
    lblProgress.Caption := lblProgress.Caption + ' - ' + ACurrentItem;
  Application.ProcessMessages;
end;

function TfrmCleanupPreview.OnCleanupConfirm(const AItem: TCleanupItem): Boolean;
begin
  // 可以添加确认对话框
  Result := True; // 暂时自动确认
end;

procedure TfrmCleanupPreview.ShowCleanupResult(const AResult: TCleanupResult);
begin
  if AResult.Success then
  begin
    ShowMessage(Format('清理完成！' + sLineBreak + sLineBreak +
                      '删除文件: %d 个' + sLineBreak +
                      '释放空间: %s' + sLineBreak +
                      '清理项目: %d 个',
                      [AResult.FilesDeleted, FormatFileSize(AResult.SpaceFreed), 
                       AResult.Details.Count]));
  end
  else
  begin
    ShowMessage('清理失败：' + sLineBreak + AResult.ErrorMessage);
  end;
end;

procedure TfrmCleanupPreview.UpdateItemSelection;
var
  I: Integer;
begin
  FSelectedItems.Clear;
  for I := 0 to lvItems.Items.Count - 1 do
  begin
    if lvItems.Items[I].Checked then
      FSelectedItems.Add(Integer(lvItems.Items[I].Data));
  end;
  UpdateButtonStates;
end;

end.

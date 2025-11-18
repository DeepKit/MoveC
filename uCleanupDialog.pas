unit uCleanupDialog;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.IOUtils,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs, Vcl.FileCtrl,
  uCleanupManager;

type
  TfrmCleanupDialog = class(TForm)
  private
    FDirectoryEdit: TEdit;
    FBrowseButton: TButton;
    FTypeCombo: TComboBox;
    FPreviewButton: TButton;
    FCleanButton: TButton;
    FCloseButton: TButton;
    FPreviewMemo: TMemo;
    FStatusLabel: TLabel;
    FProgressBar: TProgressBar;

    FCleanup: TCleanupManager;

    procedure BtnBrowseClick(Sender: TObject);
    procedure BtnPreviewClick(Sender: TObject);
    procedure BtnCleanClick(Sender: TObject);
    procedure BtnCloseClick(Sender: TObject);
    procedure CleanupProgress(const Msg: string; Progress: Integer);

    procedure BuildUI;
    function GetDirectory: string;
    procedure SetDirectory(const Value: string);
    function GetSelectedKind: TCleanupKind;
    procedure FillTypeCombo;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Directory: string read GetDirectory write SetDirectory;
  end;

implementation

{ TfrmCleanupDialog }

constructor TfrmCleanupDialog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := '清理无用文件';
  Position := poScreenCenter;
  Width := 800;
  Height := 500;
  BorderStyle := bsDialog;

  FCleanup := TCleanupManager.Create;
  // 为简化兼容性，此处暂不绑定进度回调，
  // 清理和预览过程中的主要进度在界面中通过结果展示。

  BuildUI;
end;

destructor TfrmCleanupDialog.Destroy;
begin
  FCleanup.Free;
  inherited Destroy;
end;

procedure TfrmCleanupDialog.BuildUI;
var
  topPanel, bottomPanel: TPanel;
begin
  topPanel := TPanel.Create(Self);
  topPanel.Parent := Self;
  topPanel.Align := alTop;
  topPanel.Height := 80;

  bottomPanel := TPanel.Create(Self);
  bottomPanel.Parent := Self;
  bottomPanel.Align := alBottom;
  bottomPanel.Height := 60;

  // 目录选择
  with TLabel.Create(Self) do
  begin
    Parent := topPanel;
    Left := 16;
    Top := 16;
    Caption := '目标目录：';
  end;

  FDirectoryEdit := TEdit.Create(Self);
  FDirectoryEdit.Parent := topPanel;
  FDirectoryEdit.Left := 80;
  FDirectoryEdit.Top := 12;
  FDirectoryEdit.Width := 520;

  FBrowseButton := TButton.Create(Self);
  FBrowseButton.Parent := topPanel;
  FBrowseButton.Left := 610;
  FBrowseButton.Top := 10;
  FBrowseButton.Width := 80;
  FBrowseButton.Caption := '浏览...';
  FBrowseButton.OnClick := BtnBrowseClick;

  // 类型选择
  with TLabel.Create(Self) do
  begin
    Parent := topPanel;
    Left := 16;
    Top := 48;
    Caption := '清理类型：';
  end;

  FTypeCombo := TComboBox.Create(Self);
  FTypeCombo.Parent := topPanel;
  FTypeCombo.Left := 80;
  FTypeCombo.Top := 44;
  FTypeCombo.Width := 260;
  FTypeCombo.Style := csDropDownList;
  FillTypeCombo;

  FPreviewButton := TButton.Create(Self);
  FPreviewButton.Parent := topPanel;
  FPreviewButton.Left := 360;
  FPreviewButton.Top := 42;
  FPreviewButton.Width := 90;
  FPreviewButton.Caption := '预览';
  FPreviewButton.OnClick := BtnPreviewClick;

  FCleanButton := TButton.Create(Self);
  FCleanButton.Parent := topPanel;
  FCleanButton.Left := 460;
  FCleanButton.Top := 42;
  FCleanButton.Width := 120;
  FCleanButton.Caption := '开始清理';
  FCleanButton.OnClick := BtnCleanClick;

  // 预览区域
  FPreviewMemo := TMemo.Create(Self);
  FPreviewMemo.Parent := Self;
  FPreviewMemo.Align := alClient;
  FPreviewMemo.ScrollBars := ssVertical;
  FPreviewMemo.WordWrap := False;

  // 底部状态和按钮
  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := bottomPanel;
  FStatusLabel.Left := 16;
  FStatusLabel.Top := 12;
  FStatusLabel.Caption := '就绪';

  FProgressBar := TProgressBar.Create(Self);
  FProgressBar.Parent := bottomPanel;
  FProgressBar.Left := 16;
  FProgressBar.Top := 30;
  FProgressBar.Width := 500;
  FProgressBar.Height := 16;
  FProgressBar.Min := 0;
  FProgressBar.Max := 100;
  FProgressBar.Position := 0;

  FCloseButton := TButton.Create(Self);
  FCloseButton.Parent := bottomPanel;
  FCloseButton.Left := 600;
  FCloseButton.Top := 18;
  FCloseButton.Width := 80;
  FCloseButton.Caption := '关闭';
  FCloseButton.OnClick := BtnCloseClick;
end;

procedure TfrmCleanupDialog.FillTypeCombo;
begin
  FTypeCombo.Items.Clear;
  FTypeCombo.Items.Add('临时文件清理（.tmp/.bak 等）');    // ckTemp
  FTypeCombo.Items.Add('日志清理（过期 .log/.trace）');      // ckLogs
  FTypeCombo.Items.Add('缓存目录清理（cache/temp 等）');    // ckCache
  FTypeCombo.Items.Add('安装残留清理（旧安装包/镜像）');    // ckInstall
  FTypeCombo.Items.Add('大文件扫描（仅列出大文件）');      // ckLarge
  FTypeCombo.Items.Add('自定义白名单模式（高级）');        // ckCustom
  FTypeCombo.ItemIndex := 0;
end;

function TfrmCleanupDialog.GetDirectory: string;
begin
  Result := Trim(FDirectoryEdit.Text);
end;

procedure TfrmCleanupDialog.SetDirectory(const Value: string);
begin
  FDirectoryEdit.Text := Value;
end;

function TfrmCleanupDialog.GetSelectedKind: TCleanupKind;
begin
  if (FTypeCombo.ItemIndex < 0) or (FTypeCombo.ItemIndex > Ord(High(TCleanupKind))) then
    Result := ckTemp
  else
    Result := TCleanupKind(FTypeCombo.ItemIndex);
end;

procedure TfrmCleanupDialog.BtnBrowseClick(Sender: TObject);
var
  dir: string;
begin
  dir := Directory;
  if dir = '' then
    dir := 'C:\';
  if SelectDirectory('选择要清理的目录', '', dir) then
    Directory := dir;
end;

procedure TfrmCleanupDialog.CleanupProgress(const Msg: string; Progress: Integer);
begin
  FStatusLabel.Caption := Msg;
  if (Progress >= 0) and (Progress <= 100) then
  begin
    FProgressBar.Position := Progress;
  end;
  Application.ProcessMessages;
end;

procedure TfrmCleanupDialog.BtnPreviewClick(Sender: TObject);
var
  dir: string;
  res: TCleanupResult;
  kind: TCleanupKind;
begin
  dir := Directory;
  if (dir = '') or (not TDirectory.Exists(dir)) then
  begin
    MessageDlg('请选择一个有效的目录。', mtWarning, [mbOK], 0);
    Exit;
  end;

  FPreviewMemo.Clear;
  FStatusLabel.Caption := '正在预览可清理的无用文件...';
  FProgressBar.Position := 0;

  kind := GetSelectedKind;

  // 使用 CleanupManager 的预览接口，只统计可删除文件，不做任何修改
  res := FCleanup.PreviewDirectoryByKind(dir, kind);
  try
    if res.Success then
    begin
      FPreviewMemo.Lines.Add(Format('可删除文件总数: %d，预计可释放空间: %.2f MB',
        [res.FilesDeleted, res.SpaceFreed / (1024 * 1024)]));
      FPreviewMemo.Lines.Add('详细记录:');
      FPreviewMemo.Lines.AddStrings(res.Details);
      FPreviewMemo.Lines.Add('');
      if kind = ckLarge then
        FPreviewMemo.Lines.Add('（当前为大文件扫描模式，仅列出大文件，不会自动删除。）')
      else
        FPreviewMemo.Lines.Add('（当前根据所选清理类型的安全规则进行预览，不会修改任何文件。）');
      FStatusLabel.Caption := '预览完成（未执行实际删除）。';
    end
    else
    begin
      FStatusLabel.Caption := '预览过程中有错误：' + res.ErrorMessage;
      FPreviewMemo.Lines.Add('预览失败：' + res.ErrorMessage);
    end;
  finally
    if Assigned(res.Details) then
      res.Details.Free;
    FProgressBar.Position := 100;
  end;
end;

procedure TfrmCleanupDialog.BtnCleanClick(Sender: TObject);
var
  dir: string;
  res: TCleanupResult;
  kind: TCleanupKind;
begin
  dir := Directory;
  if (dir = '') or (not TDirectory.Exists(dir)) then
  begin
    MessageDlg('请选择一个有效的目录。', mtWarning, [mbOK], 0);
    Exit;
  end;

  kind := GetSelectedKind;

  if MessageDlg('即将根据当前类型规则清理目录中的无用文件：' + sLineBreak + dir + sLineBreak +
                '请确认已经备份重要数据。是否继续？', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  FPreviewMemo.Clear;
  FStatusLabel.Caption := '正在清理无用文件...';
  FProgressBar.Position := 0;

  // 根据所选类型调用按类型的清理规则。
  // 对于“大文件扫描”类型，内部实现只会统计，不会自动删除。
  res := FCleanup.CleanDirectoryByKind(dir, kind);
  try
    FPreviewMemo.Lines.Add(Format('删除文件总数: %d，释放空间: %.2f MB',
      [res.FilesDeleted, res.SpaceFreed / (1024 * 1024)]));
    FPreviewMemo.Lines.Add('详细记录:');
    FPreviewMemo.Lines.AddStrings(res.Details);

    if res.Success then
      FStatusLabel.Caption := '清理完成。'
    else
      FStatusLabel.Caption := '清理过程中有错误：' + res.ErrorMessage;
  finally
    if Assigned(res.Details) then
      res.Details.Free;
    FProgressBar.Position := 100;
  end;
end;

procedure TfrmCleanupDialog.BtnCloseClick(Sender: TObject);
begin
  Close;
end;

end.

unit uCleanupRulesPreview;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.IOUtils, System.Types, System.DateUtils,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs;

type
  TfrmCleanupRulesPreview = class(TForm)
  private
    pnlTop: TPanel;
    lblRoot: TLabel;
    edtRoot: TEdit;
    btnBrowse: TButton;

    lblPatterns: TLabel;
    memPatterns: TMemo;  // 包含模式，glob-like: *.log, *.tmp

    lblWhitelist: TLabel;
    memWhitelist: TMemo; // 白名单目录（逐行）

    lblMinDays: TLabel;
    edtMinDays: TEdit;   // 最小修改天数

    btnPreview: TButton;
    btnExportCSV: TButton;

    lvResult: TListView;
    lblHint: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure BtnBrowseClick(Sender: TObject);
    procedure BtnPreviewClick(Sender: TObject);
    procedure BtnExportCSVClick(Sender: TObject);

    function MatchAnyPattern(const FileName: string; const Patterns: TArray<string>): Boolean;
    function IsInWhitelist(const FilePath: string; const Whitelist: TArray<string>): Boolean;
    function ShouldInclude(const FilePath: string; const LastWrite: TDateTime;
      const Patterns, White: TArray<string>; const MinDays: Integer): Boolean;
    procedure ExportListViewToCSV(LV: TListView; const FileName: string);
  public
    class procedure ShowPreview; static;
  end;

implementation

class procedure TfrmCleanupRulesPreview.ShowPreview;
var
  F: TfrmCleanupRulesPreview;
begin
  F := TfrmCleanupRulesPreview.Create(nil);
  try
    F.Position := poScreenCenter;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmCleanupRulesPreview.FormCreate(Sender: TObject);
begin
  Caption := '清理规则预览（只读）';
  Width := 900;
  Height := 620;

  pnlTop := TPanel.Create(Self);
  pnlTop.Parent := Self;
  pnlTop.Align := alTop;
  pnlTop.Height := 180;

  lblRoot := TLabel.Create(Self);
  lblRoot.Parent := pnlTop;
  lblRoot.Left := 8;
  lblRoot.Top := 12;
  lblRoot.Caption := '根目录:';

  edtRoot := TEdit.Create(Self);
  edtRoot.Parent := pnlTop;
  edtRoot.Left := 64;
  edtRoot.Top := 8;
  edtRoot.Width := 520;
  edtRoot.Text := 'C:\\Users\\';

  btnBrowse := TButton.Create(Self);
  btnBrowse.Parent := pnlTop;
  btnBrowse.Left := edtRoot.Left + edtRoot.Width + 8;
  btnBrowse.Top := 6;
  btnBrowse.Width := 80;
  btnBrowse.Caption := '浏览...';
  btnBrowse.OnClick := BtnBrowseClick;

  lblPatterns := TLabel.Create(Self);
  lblPatterns.Parent := pnlTop;
  lblPatterns.Left := 8;
  lblPatterns.Top := 44;
  lblPatterns.Caption := '包含模式(每行一个，如 *.log):';

  memPatterns := TMemo.Create(Self);
  memPatterns.Parent := pnlTop;
  memPatterns.Left := 8;
  memPatterns.Top := 64;
  memPatterns.Width := 300;
  memPatterns.Height := 88;
  memPatterns.ScrollBars := ssVertical;
  memPatterns.Lines.Text := '*.log' + sLineBreak + '*.tmp';

  lblWhitelist := TLabel.Create(Self);
  lblWhitelist.Parent := pnlTop;
  lblWhitelist.Left := memPatterns.Left + memPatterns.Width + 8;
  lblWhitelist.Top := 44;
  lblWhitelist.Caption := '白名单目录(不清理,每行一个):';

  memWhitelist := TMemo.Create(Self);
  memWhitelist.Parent := pnlTop;
  memWhitelist.Left := lblWhitelist.Left;
  memWhitelist.Top := 64;
  memWhitelist.Width := 300;
  memWhitelist.Height := 88;
  memWhitelist.ScrollBars := ssVertical;

  lblMinDays := TLabel.Create(Self);
  lblMinDays.Parent := pnlTop;
  lblMinDays.Left := memWhitelist.Left + memWhitelist.Width + 8;
  lblMinDays.Top := 44;
  lblMinDays.Caption := '最小天数(只预览早于此天数):';

  edtMinDays := TEdit.Create(Self);
  edtMinDays.Parent := pnlTop;
  edtMinDays.Left := lblMinDays.Left;
  edtMinDays.Top := 64;
  edtMinDays.Width := 100;
  edtMinDays.Text := '30';

  btnPreview := TButton.Create(Self);
  btnPreview.Parent := pnlTop;
  btnPreview.Left := edtMinDays.Left;
  btnPreview.Top := 100;
  btnPreview.Width := 100;
  btnPreview.Caption := '预览';
  btnPreview.OnClick := BtnPreviewClick;

  btnExportCSV := TButton.Create(Self);
  btnExportCSV.Parent := pnlTop;
  btnExportCSV.Left := btnPreview.Left + btnPreview.Width + 8;
  btnExportCSV.Top := 100;
  btnExportCSV.Width := 110;
  btnExportCSV.Caption := '导出CSV';
  btnExportCSV.OnClick := BtnExportCSVClick;

  lblHint := TLabel.Create(Self);
  lblHint.Parent := pnlTop;
  lblHint.Left := btnExportCSV.Left + btnExportCSV.Width + 12;
  lblHint.Top := 104;
  lblHint.Caption := '说明：本窗口仅预览与导出，不进行删除操作。';

  lvResult := TListView.Create(Self);
  lvResult.Parent := Self;
  lvResult.Align := alClient;
  lvResult.ViewStyle := vsReport;
  lvResult.ReadOnly := True;
  lvResult.RowSelect := True;
  lvResult.Columns.Add.Caption := '文件路径';
  lvResult.Columns[0].Width := 600;
  lvResult.Columns.Add.Caption := '大小';
  lvResult.Columns[1].Width := 140;
  lvResult.Columns.Add.Caption := '修改时间';
  lvResult.Columns[2].Width := 140;
end;

procedure TfrmCleanupRulesPreview.BtnBrowseClick(Sender: TObject);
var
  dlg: TFileOpenDialog;
begin
  dlg := TFileOpenDialog.Create(nil);
  try
    dlg.Options := dlg.Options + [fdoPickFolders];
    dlg.Title := '选择根目录';
    if dlg.Execute then
      edtRoot.Text := dlg.FileName;
  finally
    dlg.Free;
  end;
end;

function TfrmCleanupRulesPreview.MatchAnyPattern(const FileName: string; const Patterns: TArray<string>): Boolean;
var
  p, patt: string;
begin
  if Length(Patterns) = 0 then Exit(True);
  Result := False;
  for p in Patterns do
  begin
    patt := Trim(p);
    if patt = '' then Continue;
    // 简易匹配：只支持前后通配 *
    if (patt = '*') or
       (patt = ExtractFileName(FileName)) or
       (patt.StartsWith('*.') and SameText(ExtractFileExt(FileName), Copy(patt, 2, MaxInt))) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TfrmCleanupRulesPreview.IsInWhitelist(const FilePath: string; const Whitelist: TArray<string>): Boolean;
var
  w: string;
begin
  Result := False;
  for w in Whitelist do
  begin
    var ww := Trim(w);
    if ww = '' then Continue;
    if FilePath.StartsWith(IncludeTrailingPathDelimiter(ww), True) then
    begin
      Result := True; Exit;
    end;
  end;
end;

function TfrmCleanupRulesPreview.ShouldInclude(const FilePath: string; const LastWrite: TDateTime;
  const Patterns, White: TArray<string>; const MinDays: Integer): Boolean;
var
  days: Integer;
begin
  if IsInWhitelist(FilePath, White) then
    Exit(False);
  if not MatchAnyPattern(FilePath, Patterns) then
    Exit(False);
  if (MinDays > 0) and (LastWrite > 1) then
  begin
    days := DaysBetween(Now, LastWrite);
    if days < MinDays then
      Exit(False);
  end;
  Result := True;
end;

procedure TfrmCleanupRulesPreview.BtnPreviewClick(Sender: TObject);
var
  stack: TStack<string>;
  dir: string;
  files: TStringDynArray;
  f: string;
  size: Int64;
  latest: TDateTime;
  patt, white: TArray<string>;
  minDays: Integer;
  item: TListItem;
begin
  if not TDirectory.Exists(edtRoot.Text) then
  begin
    MessageDlg('根目录不存在：' + edtRoot.Text, mtError, [mbOK], 0);
    Exit;
  end;

  patt := memPatterns.Lines.ToStringArray;
  white := memWhitelist.Lines.ToStringArray;
  if not TryStrToInt(Trim(edtMinDays.Text), minDays) then
    minDays := 0;

  Screen.Cursor := crHourGlass;
  try
    lvResult.Items.BeginUpdate;
    try
      lvResult.Items.Clear;
      stack := TStack<string>.Create;
      try
        stack.Push(ExcludeTrailingPathDelimiter(edtRoot.Text));
        while stack.Count > 0 do
        begin
          dir := stack.Pop;
          // 子目录
          for var sub in TDirectory.GetDirectories(dir) do
            stack.Push(sub);
          // 文件
          files := TDirectory.GetFiles(dir);
          for f in files do
          begin
            try size := TFile.GetSize(f); except size := 0; end;
            try latest := TFile.GetLastWriteTime(f); except latest := 0; end;
            if ShouldInclude(f, latest, patt, white, minDays) then
            begin
              item := lvResult.Items.Add;
              item.Caption := f;
              item.SubItems.Add(Format('%.2f MB', [size / (1024*1024)]));
              if latest > 0 then
                item.SubItems.Add(DateTimeToStr(latest)) else item.SubItems.Add('-');
            end;
          end;
        end;
      finally
        stack.Free;
      end;
    finally
      lvResult.Items.EndUpdate;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmCleanupRulesPreview.ExportListViewToCSV(LV: TListView; const FileName: string);
var
  SL: TStringList; i, j: Integer; line: string;
  function Esc(const S: string): string;
  begin
    Result := '"' + StringReplace(S, '"', '""', [rfReplaceAll]) + '"';
  end;
begin
  SL := TStringList.Create;
  try
    // header
    if LV.Columns.Count > 0 then
    begin
      line := Esc(LV.Columns[0].Caption);
      for i := 1 to LV.Columns.Count - 1 do
        line := line + ',' + Esc(LV.Columns[i].Caption);
      SL.Add(line);
    end;
    // rows
    for i := 0 to LV.Items.Count - 1 do
    begin
      line := Esc(LV.Items[i].Caption);
      for j := 0 to LV.Items[i].SubItems.Count - 1 do
        line := line + ',' + Esc(LV.Items[i].SubItems[j]);
      SL.Add(line);
    end;
    SL.SaveToFile(FileName, TEncoding.UTF8);
  finally
    SL.Free;
  end;
end;

procedure TfrmCleanupRulesPreview.BtnExportCSVClick(Sender: TObject);
var
  dlg: TSaveDialog;
begin
  if lvResult.Items.Count = 0 then
  begin
    MessageDlg('没有数据可导出，请先预览。', mtInformation, [mbOK], 0);
    Exit;
  end;
  dlg := TSaveDialog.Create(nil);
  try
    dlg.Filter := 'CSV文件 (*.csv)|*.csv|所有文件 (*.*)|*.*';
    dlg.DefaultExt := 'csv';
    dlg.FileName := 'CleanupPreview.csv';
    if dlg.Execute then
    begin
      ExportListViewToCSV(lvResult, dlg.FileName);
      MessageDlg('已导出到：' + dlg.FileName, mtInformation, [mbOK], 0);
    end;
  finally
    dlg.Free;
  end;
end;

end.

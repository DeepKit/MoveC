unit uDiskAnalysis;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.StrUtils,
  System.IOUtils, System.Types, System.DateUtils, System.Math,
  Winapi.Windows, Winapi.ShellAPI,
  Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs, Vcl.Graphics;

type
  TDirStat = record
    Path: string;
    FileCount: Integer;
    TotalSize: Int64;
    LatestWrite: TDateTime;
  end;

  TfrmDiskAnalysis = class(TForm)
  private
    pnlTop: TPanel;
    btnScanC: TButton;
    edtRoot: TEdit;
    btnBrowse: TButton;
    lblHint: TLabel;
    lblStatus: TLabel;
    btnExport: TButton;
    btnExportHtml: TButton;

    // 轻量筛选
    lblExts: TLabel;
    edtExts: TEdit;        // 逗号分隔扩展名：如 jpg,png,mp4；空表示不过滤
    lblMinDays: TLabel;
    edtMinDays: TEdit;     // 最小修改天数，空或0表示不过滤
    btnApply: TButton;

    pgc: TPageControl;
    tsSummary: TTabSheet;
    tsBigFiles: TTabSheet;
    tsOverview: TTabSheet; // 概览（饼图）

    lvSummary: TListView;
    lvBig: TListView;
    pbChart: TPaintBox;

    // 图表数据快照（按顶层目录聚合）
    FChartSlices: TArray<TPair<string, Int64>>;
    FChartTotal: Int64;

    procedure FormCreate(Sender: TObject);
    procedure BtnScanClick(Sender: TObject);
    procedure BtnBrowseClick(Sender: TObject);
    procedure lvSummaryDblClick(Sender: TObject);
    procedure lvBigDblClick(Sender: TObject);
    procedure BtnExportClick(Sender: TObject);
    procedure BtnExportHtmlClick(Sender: TObject);
    procedure BtnApplyClick(Sender: TObject);
    procedure pbChartPaint(Sender: TObject);

    procedure DoScanRoot(const Root: string);
    function FormatSize(const Bytes: Int64): string;
    procedure OpenFolderInExplorer(const Folder: string);
    procedure SelectFileInExplorer(const FilePath: string);
    procedure ExportListViewToCSV(LV: TListView; const FileName: string);
    procedure ExportReportHtml(const FileName: string);
    function ShouldInclude(const FilePath: string; const LastWrite: TDateTime): Boolean;
  public
    class procedure ShowAnalysis; static;
  end;

implementation

class procedure TfrmDiskAnalysis.ShowAnalysis;
var
  F: TfrmDiskAnalysis;
begin
  F := TfrmDiskAnalysis.Create(nil);
  try
    F.Position := poScreenCenter;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

procedure TfrmDiskAnalysis.FormCreate(Sender: TObject);
begin
  Caption := '磁盘分析（MVP）';
  Width := 900;
  Height := 600;

  pnlTop := TPanel.Create(Self);
  pnlTop.Parent := Self;
  pnlTop.Align := alTop;
  pnlTop.Height := 52;

  edtRoot := TEdit.Create(Self);
  edtRoot.Parent := pnlTop;
  edtRoot.Align := alLeft;
  edtRoot.Width := 420;
  edtRoot.Text := 'C:\';

  btnBrowse := TButton.Create(Self);
  btnBrowse.Parent := pnlTop;
  btnBrowse.Caption := '浏览...';
  btnBrowse.Left := edtRoot.Left + edtRoot.Width + 8;
  btnBrowse.Top := 10;
  btnBrowse.Width := 80;
  btnBrowse.OnClick := BtnBrowseClick;

  btnScanC := TButton.Create(Self);
  btnScanC.Parent := pnlTop;
  btnScanC.Caption := '扫描';
  btnScanC.Left := btnBrowse.Left + btnBrowse.Width + 8;
  btnScanC.Top := 10;
  btnScanC.Width := 80;
  btnScanC.OnClick := BtnScanClick;

  lblExts := TLabel.Create(Self);
  lblExts.Parent := pnlTop;
  lblExts.Left := btnScanC.Left + btnScanC.Width + 12;
  lblExts.Top := 12;
  lblExts.Caption := '类型(扩展名):';

  edtExts := TEdit.Create(Self);
  edtExts.Parent := pnlTop;
  edtExts.Left := lblExts.Left + 80;
  edtExts.Top := 8;
  edtExts.Width := 140;
  edtExts.TextHint := '如: jpg,png,mp4';

  lblMinDays := TLabel.Create(Self);
  lblMinDays.Parent := pnlTop;
  lblMinDays.Left := edtExts.Left + edtExts.Width + 12;
  lblMinDays.Top := 12;
  lblMinDays.Caption := '最小天数:';

  edtMinDays := TEdit.Create(Self);
  edtMinDays.Parent := pnlTop;
  edtMinDays.Left := lblMinDays.Left + 64;
  edtMinDays.Top := 8;
  edtMinDays.Width := 60;
  edtMinDays.TextHint := '0(不过滤)';

  btnApply := TButton.Create(Self);
  btnApply.Parent := pnlTop;
  btnApply.Caption := '应用筛选';
  btnApply.Left := edtMinDays.Left + edtMinDays.Width + 8;
  btnApply.Top := 8;
  btnApply.Width := 90;
  btnApply.OnClick := BtnApplyClick;

  lblHint := TLabel.Create(Self);
  lblHint.Parent := pnlTop;
  lblHint.Left := btnApply.Left + btnApply.Width + 12;
  lblHint.Top := 16;
  lblHint.Caption := '提示：默认扫描 C:\ ，结果包含聚合统计与 Top100 大文件（只读分析，不进行删除）。';

  lblStatus := TLabel.Create(Self);
  lblStatus.Parent := pnlTop;
  lblStatus.Left := lblHint.Left;
  lblStatus.Top := 30;
  lblStatus.Caption := '就绪';

  btnExport := TButton.Create(Self);
  btnExport.Parent := pnlTop;
  btnExport.Caption := '导出CSV';
  btnExport.Left := lblHint.Left + 360;
  btnExport.Top := 10;
  btnExport.Width := 90;
  btnExport.OnClick := BtnExportClick;

  btnExportHtml := TButton.Create(Self);
  btnExportHtml.Parent := pnlTop;
  btnExportHtml.Caption := '导出HTML报告';
  btnExportHtml.Left := btnExport.Left + btnExport.Width + 8;
  btnExportHtml.Top := 10;
  btnExportHtml.Width := 120;
  btnExportHtml.OnClick := BtnExportHtmlClick;

  pgc := TPageControl.Create(Self);
  pgc.Parent := Self;
  pgc.Align := alClient;

  tsSummary := TTabSheet.Create(Self);
  tsSummary.PageControl := pgc;
  tsSummary.Caption := '聚合统计';

  tsBigFiles := TTabSheet.Create(Self);
  tsBigFiles.PageControl := pgc;
  tsBigFiles.Caption := '大文件 Top100';

  tsOverview := TTabSheet.Create(Self);
  tsOverview.PageControl := pgc;
  tsOverview.Caption := '概览(占比)';

  lvSummary := TListView.Create(Self);
  lvSummary.Parent := tsSummary;
  lvSummary.Align := alClient;
  lvSummary.ViewStyle := vsReport;
  lvSummary.ReadOnly := True;
  lvSummary.RowSelect := True;
  lvSummary.OnDblClick := lvSummaryDblClick;
  lvSummary.Columns.Add.Caption := '目录';
  lvSummary.Columns[0].Width := 450;
  lvSummary.Columns.Add.Caption := '文件数';
  lvSummary.Columns[1].Width := 80;
  lvSummary.Columns.Add.Caption := '总大小';
  lvSummary.Columns[2].Width := 120;
  lvSummary.Columns.Add.Caption := '最近写入时间';
  lvSummary.Columns[3].Width := 160;

  lvBig := TListView.Create(Self);
  lvBig.Parent := tsBigFiles;
  lvBig.Align := alClient;
  lvBig.ViewStyle := vsReport;
  lvBig.ReadOnly := True;
  lvBig.RowSelect := True;
  lvBig.OnDblClick := lvBigDblClick;
  lvBig.Columns.Add.Caption := '文件路径';
  lvBig.Columns[0].Width := 600;
  lvBig.Columns.Add.Caption := '大小';
  lvBig.Columns[1].Width := 140;
  lvBig.Columns.Add.Caption := '修改时间';
  lvBig.Columns[2].Width := 140;

  pbChart := TPaintBox.Create(Self);
  pbChart.Parent := tsOverview;
  pbChart.Align := alClient;
  pbChart.OnPaint := pbChartPaint;
end;

procedure TfrmDiskAnalysis.BtnBrowseClick(Sender: TObject);
var
  dlg: TFileOpenDialog;
begin
  dlg := TFileOpenDialog.Create(nil);
  try
    dlg.Options := dlg.Options + [fdoPickFolders];
    dlg.Title := '选择要分析的根目录';
    if dlg.Execute then
      edtRoot.Text := dlg.FileName;
  finally
    dlg.Free;
  end;
end;

procedure TfrmDiskAnalysis.BtnScanClick(Sender: TObject);
begin
  lblStatus.Caption := '扫描中...';
  DoScanRoot(edtRoot.Text);
  lblStatus.Caption := '扫描完成';
end;

function TfrmDiskAnalysis.FormatSize(const Bytes: Int64): string;
const
  KB = 1024.0;
  MB = KB * 1024;
  GB = MB * 1024;
begin
  if Bytes >= Trunc(GB) then
    Result := Format('%.2f GB', [Bytes / GB])
  else if Bytes >= Trunc(MB) then
    Result := Format('%.2f MB', [Bytes / MB])
  else if Bytes >= Trunc(KB) then
    Result := Format('%.2f KB', [Bytes / KB])
  else
    Result := Format('%d B', [Bytes]);
end;

procedure TfrmDiskAnalysis.DoScanRoot(const Root: string);
var
  agg: TDictionary<string, TDirStat>;
  big: TList<TPair<string, Int64>>;
  stack: TStack<string>;
  dir, filePath, topDir: string;
  files: TStringDynArray;
  size: Int64;
  item: TListItem;
  latest: TDateTime;
  function TopLevelOf(const base, path: string): string;
  var
    p: string;
  begin
    p := path;
    if p.StartsWith(base, True) then
      p := p.Substring(Length(base));
    if p <> '' then
    begin
      if p[1] in ['\', '/'] then
        p := p.Substring(1);
      if p.Contains('\') then
        Result := IncludeTrailingPathDelimiter(base) + p.Substring(0, p.IndexOf('\'))
      else
        Result := IncludeTrailingPathDelimiter(base) + p;
    end
    else
      Result := ExcludeTrailingPathDelimiter(base);
  end;
begin
  if not TDirectory.Exists(Root) then
  begin
    MessageDlg('根目录不存在：' + Root, mtError, [mbOK], 0);
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    agg := TDictionary<string, TDirStat>.Create;
    big := TList<TPair<string, Int64>>.Create;
    stack := TStack<string>.Create;
    try
      stack.Push(ExcludeTrailingPathDelimiter(Root));
      while stack.Count > 0 do
      begin
        dir := stack.Pop;
        // 枚举子目录
        for var sub in TDirectory.GetDirectories(dir) do
          stack.Push(sub);
        // 枚举文件
        files := TDirectory.GetFiles(dir);
        for filePath in files do
        begin
          try
            size := TFile.GetSize(filePath);
          except
            size := 0;
          end;
          // 最近写入时间
          try
            latest := TFile.GetLastWriteTime(filePath);
          except
            latest := 0;
          end;

          // 应用筛选（类型/时间）
          if not ShouldInclude(filePath, latest) then
            Continue;

          // 记录 Top100 大文件
          big.Add(TPair<string, Int64>.Create(filePath, size));
          // 聚合到顶层目录
          topDir := TopLevelOf(ExcludeTrailingPathDelimiter(Root), filePath);
          if not agg.ContainsKey(topDir) then
          begin
            var v: TDirStat;
            v.Path := topDir;
            v.FileCount := 0;
            v.TotalSize := 0;
            v.LatestWrite := 0;
            agg.Add(topDir, v);
          end;
          var st := agg.Items[topDir];
          Inc(st.FileCount);
          Inc(st.TotalSize, size);
          if (latest > 0) and (latest > st.LatestWrite) then
            st.LatestWrite := latest;
          agg.Items[topDir] := st;
        end;
      end;

      // 填充聚合统计
      lvSummary.Items.BeginUpdate;
      try
        lvSummary.Items.Clear;
        for var pair in agg do
        begin
          item := lvSummary.Items.Add;
          item.Caption := pair.Value.Path;
          item.SubItems.Add(pair.Value.FileCount.ToString);
          item.SubItems.Add(FormatSize(pair.Value.TotalSize));
          if pair.Value.LatestWrite > 0 then
            item.SubItems.Add(DateTimeToStr(pair.Value.LatestWrite))
          else
            item.SubItems.Add('-');
        end;
      finally
        lvSummary.Items.EndUpdate;
      end;

      // Top100 大文件
      big.Sort(TComparer<TPair<string, Int64>>.Construct(
        function(const A, B: TPair<string, Int64>): Integer
        begin
          if A.Value < B.Value then Exit(1);
          if A.Value > B.Value then Exit(-1);
          Result := 0;
        end));
      lvBig.Items.BeginUpdate;
      try
        lvBig.Items.Clear;
        for var idx := 0 to Min(99, big.Count - 1) do
        begin
          item := lvBig.Items.Add;
          item.Caption := big[idx].Key;
          item.SubItems.Add(FormatSize(big[idx].Value));
          try
            item.SubItems.Add(DateTimeToStr(TFile.GetLastWriteTime(big[idx].Key)));
          except
            item.SubItems.Add('-');
          end;
        end;
      finally
        lvBig.Items.EndUpdate;
      end;

      // 准备概览图数据（取前8个目录，其余合并为“其他”）
      var arr := agg.ToArray;
      TArray.Sort<TPair<string,TDirStat>>(arr, TComparer<TPair<string,TDirStat>>.Construct(
        function(const A, B: TPair<string,TDirStat>): Integer
        begin
          if A.Value.TotalSize < B.Value.TotalSize then Exit(1);
          if A.Value.TotalSize > B.Value.TotalSize then Exit(-1);
          Result := 0;
        end));
      SetLength(FChartSlices, 0);
      FChartTotal := 0;
      for var it in arr do
        Inc(FChartTotal, it.Value.TotalSize);
      var limit := Min(Length(arr), 8);
      SetLength(FChartSlices, limit + (Ord(Length(arr) > 8)));
      for var i := 0 to limit - 1 do
        FChartSlices[i] := TPair<string,Int64>.Create(IntToStr(i) + ':' + arr[i].Key, arr[i].Value.TotalSize);
      if Length(arr) > 8 then
      begin
        var others: Int64 := 0;
        for var i := 8 to Length(arr) - 1 do
          Inc(others, arr[i].Value.TotalSize);
        FChartSlices[limit] := TPair<string,Int64>.Create('其他', others);
      end;
      pbChart.Invalidate;

    finally
      agg.Free;
      big.Free;
      stack.Free;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmDiskAnalysis.OpenFolderInExplorer(const Folder: string);
begin
  if Folder = '' then Exit;
  ShellExecute(0, 'open', 'explorer.exe', PChar(Folder), nil, SW_SHOWNORMAL);
end;

procedure TfrmDiskAnalysis.SelectFileInExplorer(const FilePath: string);
var
  Param: string;
begin
  if (FilePath = '') or (not TFile.Exists(FilePath)) then Exit;
  Param := '/select,"' + FilePath + '"';
  ShellExecute(0, 'open', 'explorer.exe', PChar(Param), nil, SW_SHOWNORMAL);
end;

procedure TfrmDiskAnalysis.lvSummaryDblClick(Sender: TObject);
var
  Sel: TListItem;
begin
  Sel := lvSummary.Selected;
  if Assigned(Sel) then
    OpenFolderInExplorer(Sel.Caption);
end;

procedure TfrmDiskAnalysis.lvBigDblClick(Sender: TObject);
var
  Sel: TListItem;
begin
  Sel := lvBig.Selected;
  if Assigned(Sel) then
    SelectFileInExplorer(Sel.Caption);
end;

procedure TfrmDiskAnalysis.ExportListViewToCSV(LV: TListView; const FileName: string);
var
  SL: TStringList;
  i, j: Integer;
  line: string;
  function Esc(const S: string): string;
  begin
    // 简单转义，使用双引号包裹并替换内部双引号
    Result := '"' + StringReplace(S, '"', '""', [rfReplaceAll]) + '"';
  end;
begin
  SL := TStringList.Create;
  try
    // 头部
    line := '';
    if LV.Columns.Count > 0 then
    begin
      line := Esc(LV.Columns[0].Caption);
      for i := 1 to LV.Columns.Count - 1 do
        line := line + ',' + Esc(LV.Columns[i].Caption);
      SL.Add(line);
    end;
    // 内容
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

procedure TfrmDiskAnalysis.BtnExportClick(Sender: TObject);
var
  dlg: TSaveDialog;
  fn: string;
  lv: TListView;
begin
  if pgc.ActivePage = tsSummary then
    lv := lvSummary
  else
    lv := lvBig;

  dlg := TSaveDialog.Create(nil);
  try
    dlg.Filter := 'CSV文件 (*.csv)|*.csv|所有文件 (*.*)|*.*';
    dlg.DefaultExt := 'csv';
    dlg.FileName := IfThen(pgc.ActivePage = tsSummary, 'Summary.csv', 'Top100.csv');
    if dlg.Execute then
    begin
      fn := dlg.FileName;
      ExportListViewToCSV(lv, fn);
      MessageDlg('已导出到：' + fn, mtInformation, [mbOK], 0);
    end;
  finally
    dlg.Free;
  end;
end;

end.

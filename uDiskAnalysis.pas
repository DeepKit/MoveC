unit uDiskAnalysis;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.StrUtils,
  System.IOUtils, System.Types, System.DateUtils, System.Math, System.Threading,
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
    lblMinSize: TLabel;    // 最小文件大小 (MB)
    edtMinSize: TEdit;
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
    
    // 排序支持
    FBigFileSortColumn: Integer;
    FBigFileSortAsc: Boolean;
    FSummarySortColumn: Integer;
    FSummarySortAsc: Boolean;
    
    // 后台扫描支持
    FScanTask: ITask;
    FScanCancelled: Boolean;
    FScannedFiles: Integer;
    FScannedDirs: Integer;
    btnCancelScan: TButton;
    ProgressBar1: TProgressBar;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnCancelScanClick(Sender: TObject);
    procedure BtnScanClick(Sender: TObject);
    procedure BtnBrowseClick(Sender: TObject);
    procedure lvSummaryDblClick(Sender: TObject);
    procedure lvBigDblClick(Sender: TObject);
    procedure BtnExportClick(Sender: TObject);
    procedure BtnExportHtmlClick(Sender: TObject);
    procedure BtnApplyClick(Sender: TObject);
    procedure pbChartPaint(Sender: TObject);
    procedure lvBigColumnClick(Sender: TObject; Column: TListColumn);
    procedure lvSummaryColumnClick(Sender: TObject; Column: TListColumn);

    procedure DoScanRoot(const Root: string);
    procedure DoScanRootAsync(const Root: string);
    procedure UpdateScanProgress(const Status: string; FilesScanned, DirsScanned: Integer);
    procedure OnScanComplete(const Agg: TDictionary<string, TDirStat>; Big: TList<TPair<string, Int64>>);
    function FormatSize(const Bytes: Int64): string;
    function ParseSizeString(const SizeStr: string): Int64;
    procedure OpenFolderInExplorer(const Folder: string);
    procedure SelectFileInExplorer(const FilePath: string);
    procedure ExportListViewToCSV(LV: TListView; const FileName: string);
    procedure ExportReportHtml(const FileName: string);
    function ShouldInclude(const FilePath: string; const LastWrite: TDateTime; const FileSize: Int64): Boolean;
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
  btnScanC.Caption := '后台扫描';
  btnScanC.Left := btnBrowse.Left + btnBrowse.Width + 8;
  btnScanC.Top := 10;
  btnScanC.Width := 80;
  btnScanC.OnClick := BtnScanClick;
  
  btnCancelScan := TButton.Create(Self);
  btnCancelScan.Parent := pnlTop;
  btnCancelScan.Caption := '取消';
  btnCancelScan.Left := btnScanC.Left + btnScanC.Width + 4;
  btnCancelScan.Top := 10;
  btnCancelScan.Width := 50;
  btnCancelScan.Enabled := False;
  btnCancelScan.OnClick := BtnCancelScanClick;

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
  edtMinDays.Width := 50;
  edtMinDays.TextHint := '0';

  lblMinSize := TLabel.Create(Self);
  lblMinSize.Parent := pnlTop;
  lblMinSize.Left := edtMinDays.Left + edtMinDays.Width + 8;
  lblMinSize.Top := 12;
  lblMinSize.Caption := '最小MB:';

  edtMinSize := TEdit.Create(Self);
  edtMinSize.Parent := pnlTop;
  edtMinSize.Left := lblMinSize.Left + 50;
  edtMinSize.Top := 8;
  edtMinSize.Width := 50;
  edtMinSize.TextHint := '0';

  btnApply := TButton.Create(Self);
  btnApply.Parent := pnlTop;
  btnApply.Caption := '应用筛选';
  btnApply.Left := edtMinSize.Left + edtMinSize.Width + 8;
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
  lvBig.OnColumnClick := lvBigColumnClick;
  lvBig.Columns.Add.Caption := '文件路径';
  lvBig.Columns[0].Width := 500;
  lvBig.Columns.Add.Caption := '大小';
  lvBig.Columns[1].Width := 100;
  lvBig.Columns.Add.Caption := '修改时间';
  lvBig.Columns[2].Width := 130;
  lvBig.Columns.Add.Caption := '类型';
  lvBig.Columns[3].Width := 80;
  
  // 初始化排序状态
  FBigFileSortColumn := 1; // 默认按大小排序
  FBigFileSortAsc := False;
  FSummarySortColumn := 2; // 默认按总大小排序
  FSummarySortAsc := False;

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
  // 启动后台扫描
  DoScanRootAsync(edtRoot.Text);
end;

procedure TfrmDiskAnalysis.FormDestroy(Sender: TObject);
begin
  // 取消运行中的任务
  if Assigned(FScanTask) and (FScanTask.Status = TTaskStatus.Running) then
  begin
    FScanCancelled := True;
    FScanTask.Wait(3000);
  end;
end;

procedure TfrmDiskAnalysis.BtnCancelScanClick(Sender: TObject);
begin
  FScanCancelled := True;
  lblStatus.Caption := '正在取消...';
end;

procedure TfrmDiskAnalysis.UpdateScanProgress(const Status: string; FilesScanned, DirsScanned: Integer);
begin
  lblStatus.Caption := Format('%s (已扫描 %d 个文件, %d 个目录)', [Status, FilesScanned, DirsScanned]);
  Application.ProcessMessages;
end;

procedure TfrmDiskAnalysis.DoScanRootAsync(const Root: string);
var
  ExtFilter, MinDaysStr, MinSizeStr: string;
begin
  if not TDirectory.Exists(Root) then
  begin
    MessageDlg('根目录不存在：' + Root, mtError, [mbOK], 0);
    Exit;
  end;
  
  // 检查是否有正在运行的任务
  if Assigned(FScanTask) and (FScanTask.Status = TTaskStatus.Running) then
  begin
    MessageDlg('扫描正在进行中，请稍候或取消当前扫描', mtWarning, [mbOK], 0);
    Exit;
  end;
  
  // 保存筛选参数
  ExtFilter := edtExts.Text;
  MinDaysStr := edtMinDays.Text;
  MinSizeStr := edtMinSize.Text;
  
  // 更新UI状态
  FScanCancelled := False;
  FScannedFiles := 0;
  FScannedDirs := 0;
  btnScanC.Enabled := False;
  btnCancelScan.Enabled := True;
  lblStatus.Caption := '正在启动后台扫描...';
  
  // 创建后台任务
  FScanTask := TTask.Run(
    procedure
    var
      Agg: TDictionary<string, TDirStat>;
      Big: TList<TPair<string, Int64>>;
      Stack: TStack<string>;
      Dir, FilePath, TopDir: string;
      Files: TStringDynArray;
      Size: Int64;
      Latest: TDateTime;
      MinDays, MinSizeMB: Integer;
      Exts: TArray<string>;
      FileExt: string;
      MatchExt: Boolean;
      I: Integer;
      
      function TopLevelOf(const Base, Path: string): string;
      var
        P: string;
      begin
        P := Path;
        if P.StartsWith(Base, True) then
          P := P.Substring(Length(Base));
        if P <> '' then
        begin
          if P[1] in ['\', '/'] then
            P := P.Substring(1);
          if P.Contains('\') then
            Result := IncludeTrailingPathDelimiter(Base) + P.Substring(0, P.IndexOf('\'))
          else
            Result := IncludeTrailingPathDelimiter(Base) + P;
        end
        else
          Result := ExcludeTrailingPathDelimiter(Base);
      end;
      
      function ShouldIncludeFile(const FPath: string; const FLastWrite: TDateTime; const FSize: Int64): Boolean;
      var
        FExt: string;
        Match: Boolean;
        J: Integer;
      begin
        Result := True;
        
        // 扩展名筛选
        if Length(Exts) > 0 then
        begin
          FExt := LowerCase(ExtractFileExt(FPath));
          if (FExt <> '') and (FExt[1] = '.') then
            FExt := Copy(FExt, 2, MaxInt);
          
          Match := False;
          for J := 0 to High(Exts) do
            if SameText(Trim(Exts[J]), FExt) then
            begin
              Match := True;
              Break;
            end;
          if not Match then
            Exit(False);
        end;
        
        // 最小天数筛选
        if (MinDays > 0) and (FLastWrite > 0) then
          if DaysBetween(Now, FLastWrite) < MinDays then
            Exit(False);
        
        // 最小文件大小筛选
        if (MinSizeMB > 0) and (FSize < Int64(MinSizeMB) * 1024 * 1024) then
          Exit(False);
      end;
      
    begin
      Agg := TDictionary<string, TDirStat>.Create;
      Big := TList<TPair<string, Int64>>.Create;
      Stack := TStack<string>.Create;
      
      // 解析筛选参数
      if Trim(ExtFilter) <> '' then
        Exts := ExtFilter.Split([',', ';', ' '])
      else
        SetLength(Exts, 0);
      MinDays := StrToIntDef(MinDaysStr, 0);
      MinSizeMB := StrToIntDef(MinSizeStr, 0);
      
      try
        Stack.Push(ExcludeTrailingPathDelimiter(Root));
        
        while (Stack.Count > 0) and (not FScanCancelled) do
        begin
          Dir := Stack.Pop;
          Inc(FScannedDirs);
          
          // 每100个目录更新一次UI
          if FScannedDirs mod 100 = 0 then
            TThread.Synchronize(nil,
              procedure
              begin
                UpdateScanProgress('扫描中', FScannedFiles, FScannedDirs);
              end);
          
          // 枚举子目录
          try
            for var Sub in TDirectory.GetDirectories(Dir) do
              Stack.Push(Sub);
          except
            // 忽略无权限目录
          end;
          
          // 枚举文件
          try
            Files := TDirectory.GetFiles(Dir);
          except
            SetLength(Files, 0);
          end;
          
          for FilePath in Files do
          begin
            if FScanCancelled then Break;
            
            Inc(FScannedFiles);
            
            try
              Size := TFile.GetSize(FilePath);
            except
              Size := 0;
            end;
            
            try
              Latest := TFile.GetLastWriteTime(FilePath);
            except
              Latest := 0;
            end;
            
            // 应用筛选
            if not ShouldIncludeFile(FilePath, Latest, Size) then
              Continue;
            
            // 记录大文件
            Big.Add(TPair<string, Int64>.Create(FilePath, Size));
            
            // 聚合到顶层目录
            TopDir := TopLevelOf(ExcludeTrailingPathDelimiter(Root), FilePath);
            if not Agg.ContainsKey(TopDir) then
            begin
              var V: TDirStat;
              V.Path := TopDir;
              V.FileCount := 0;
              V.TotalSize := 0;
              V.LatestWrite := 0;
              Agg.Add(TopDir, V);
            end;
            var St := Agg.Items[TopDir];
            Inc(St.FileCount);
            Inc(St.TotalSize, Size);
            if (Latest > 0) and (Latest > St.LatestWrite) then
              St.LatestWrite := Latest;
            Agg.Items[TopDir] := St;
          end;
        end;
        
        // 完成后回到主线程更新UI
        if not FScanCancelled then
        begin
          TThread.Synchronize(nil,
            procedure
            begin
              OnScanComplete(Agg, Big);
            end);
        end
        else
        begin
          TThread.Synchronize(nil,
            procedure
            begin
              lblStatus.Caption := '扫描已取消';
              btnScanC.Enabled := True;
              btnCancelScan.Enabled := False;
            end);
        end;
        
      finally
        Agg.Free;
        Big.Free;
        Stack.Free;
      end;
    end);
end;

procedure TfrmDiskAnalysis.OnScanComplete(const Agg: TDictionary<string, TDirStat>; Big: TList<TPair<string, Int64>>);
var
  Item: TListItem;
begin
  // 恢复按钮状态
  btnScanC.Enabled := True;
  btnCancelScan.Enabled := False;
  
  // 填充聚合统计
  lvSummary.Items.BeginUpdate;
  try
    lvSummary.Items.Clear;
    for var Pair in Agg do
    begin
      Item := lvSummary.Items.Add;
      Item.Caption := Pair.Value.Path;
      Item.SubItems.Add(Pair.Value.FileCount.ToString);
      Item.SubItems.Add(FormatSize(Pair.Value.TotalSize));
      if Pair.Value.LatestWrite > 0 then
        Item.SubItems.Add(DateTimeToStr(Pair.Value.LatestWrite))
      else
        Item.SubItems.Add('-');
    end;
  finally
    lvSummary.Items.EndUpdate;
  end;
  
  // 大文件排序
  Big.Sort(TComparer<TPair<string, Int64>>.Construct(
    function(const A, B: TPair<string, Int64>): Integer
    begin
      if A.Value < B.Value then Exit(1);
      if A.Value > B.Value then Exit(-1);
      Result := 0;
    end));
  
  // 填充Top100大文件
  lvBig.Items.BeginUpdate;
  try
    lvBig.Items.Clear;
    for var Idx := 0 to Min(99, Big.Count - 1) do
    begin
      Item := lvBig.Items.Add;
      Item.Caption := Big[Idx].Key;
      Item.SubItems.Add(FormatSize(Big[Idx].Value));
      try
        Item.SubItems.Add(DateTimeToStr(TFile.GetLastWriteTime(Big[Idx].Key)));
      except
        Item.SubItems.Add('-');
      end;
      Item.SubItems.Add(UpperCase(Copy(ExtractFileExt(Big[Idx].Key), 2, 10)));
    end;
  finally
    lvBig.Items.EndUpdate;
  end;
  
  // 准备饼图数据
  var Arr := Agg.ToArray;
  TArray.Sort<TPair<string,TDirStat>>(Arr, TComparer<TPair<string,TDirStat>>.Construct(
    function(const A, B: TPair<string,TDirStat>): Integer
    begin
      if A.Value.TotalSize < B.Value.TotalSize then Exit(1);
      if A.Value.TotalSize > B.Value.TotalSize then Exit(-1);
      Result := 0;
    end));
  
  SetLength(FChartSlices, 0);
  FChartTotal := 0;
  for var It in Arr do
    Inc(FChartTotal, It.Value.TotalSize);
  
  var Limit := Min(Length(Arr), 8);
  SetLength(FChartSlices, Limit + Ord(Length(Arr) > 8));
  for var I := 0 to Limit - 1 do
    FChartSlices[I] := TPair<string,Int64>.Create(IntToStr(I) + ':' + Arr[I].Key, Arr[I].Value.TotalSize);
  if Length(Arr) > 8 then
  begin
    var Others: Int64 := 0;
    for var I := 8 to Length(Arr) - 1 do
      Inc(Others, Arr[I].Value.TotalSize);
    FChartSlices[Limit] := TPair<string,Int64>.Create('其他', Others);
  end;
  pbChart.Invalidate;
  
  lblStatus.Caption := Format('扫描完成 - 共 %d 个文件, %d 个目录, 总大小: %s', 
    [FScannedFiles, FScannedDirs, FormatSize(FChartTotal)]);
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

          // 应用筛选（类型/时间/大小）
          if not ShouldInclude(filePath, latest, size) then
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
          // 添加文件类型列
          item.SubItems.Add(UpperCase(Copy(ExtractFileExt(big[idx].Key), 2, 10)));
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

function TfrmDiskAnalysis.ShouldInclude(const FilePath: string; const LastWrite: TDateTime; const FileSize: Int64): Boolean;
var
  Exts: TArray<string>;
  ExtFilter, FileExt: string;
  MinDays, MinSizeMB: Integer;
  I: Integer;
  MatchExt: Boolean;
begin
  Result := True;
  
  // 扩展名筛选
  ExtFilter := Trim(edtExts.Text);
  if ExtFilter <> '' then
  begin
    Exts := ExtFilter.Split([',', ';', ' ']);
    FileExt := LowerCase(ExtractFileExt(FilePath));
    if (FileExt <> '') and (FileExt[1] = '.') then
      FileExt := Copy(FileExt, 2, MaxInt);
    
    MatchExt := False;
    for I := 0 to High(Exts) do
    begin
      if SameText(Trim(Exts[I]), FileExt) then
      begin
        MatchExt := True;
        Break;
      end;
    end;
    if not MatchExt then
      Exit(False);
  end;
  
  // 最小天数筛选
  MinDays := StrToIntDef(edtMinDays.Text, 0);
  if (MinDays > 0) and (LastWrite > 0) then
  begin
    if DaysBetween(Now, LastWrite) < MinDays then
      Exit(False);
  end;
  
  // 最小文件大小筛选 (MB)
  MinSizeMB := StrToIntDef(edtMinSize.Text, 0);
  if (MinSizeMB > 0) and (FileSize < Int64(MinSizeMB) * 1024 * 1024) then
    Exit(False);
end;

function TfrmDiskAnalysis.ParseSizeString(const SizeStr: string): Int64;
var
  S: string;
  V: Double;
begin
  // 解析 "1.23 GB", "456 MB", "789 KB", "123 B" 格式
  S := Trim(SizeStr);
  if S = '' then Exit(0);
  
  if Pos('GB', UpperCase(S)) > 0 then
  begin
    S := StringReplace(S, 'GB', '', [rfIgnoreCase]);
    V := StrToFloatDef(Trim(S), 0);
    Result := Round(V * 1024 * 1024 * 1024);
  end
  else if Pos('MB', UpperCase(S)) > 0 then
  begin
    S := StringReplace(S, 'MB', '', [rfIgnoreCase]);
    V := StrToFloatDef(Trim(S), 0);
    Result := Round(V * 1024 * 1024);
  end
  else if Pos('KB', UpperCase(S)) > 0 then
  begin
    S := StringReplace(S, 'KB', '', [rfIgnoreCase]);
    V := StrToFloatDef(Trim(S), 0);
    Result := Round(V * 1024);
  end
  else if Pos('B', UpperCase(S)) > 0 then
  begin
    S := StringReplace(S, 'B', '', [rfIgnoreCase]);
    Result := StrToInt64Def(Trim(S), 0);
  end
  else
    Result := StrToInt64Def(S, 0);
end;

procedure TfrmDiskAnalysis.lvBigColumnClick(Sender: TObject; Column: TListColumn);
var
  ColIdx: Integer;
begin
  ColIdx := Column.Index;
  
  // 切换排序方向
  if FBigFileSortColumn = ColIdx then
    FBigFileSortAsc := not FBigFileSortAsc
  else
  begin
    FBigFileSortColumn := ColIdx;
    FBigFileSortAsc := (ColIdx = 0); // 路径默认升序，其他默认降序
  end;
  
  // 执行排序
  lvBig.CustomSort(@BigFileCompare, Integer(Self));
end;

procedure TfrmDiskAnalysis.lvSummaryColumnClick(Sender: TObject; Column: TListColumn);
var
  ColIdx: Integer;
begin
  ColIdx := Column.Index;
  
  if FSummarySortColumn = ColIdx then
    FSummarySortAsc := not FSummarySortAsc
  else
  begin
    FSummarySortColumn := ColIdx;
    FSummarySortAsc := (ColIdx = 0);
  end;
  
  lvSummary.CustomSort(@SummaryCompare, Integer(Self));
end;

function BigFileCompare(Item1, Item2: TListItem; lParam: Integer): Integer; stdcall;
var
  Form: TfrmDiskAnalysis;
  S1, S2: string;
  Size1, Size2: Int64;
  D1, D2: TDateTime;
begin
  Form := TfrmDiskAnalysis(Pointer(lParam));
  Result := 0;
  
  case Form.FBigFileSortColumn of
    0: // 路径
      Result := CompareText(Item1.Caption, Item2.Caption);
    1: // 大小
    begin
      if Item1.SubItems.Count > 0 then S1 := Item1.SubItems[0] else S1 := '0';
      if Item2.SubItems.Count > 0 then S2 := Item2.SubItems[0] else S2 := '0';
      Size1 := Form.ParseSizeString(S1);
      Size2 := Form.ParseSizeString(S2);
      if Size1 > Size2 then Result := 1
      else if Size1 < Size2 then Result := -1
      else Result := 0;
    end;
    2: // 修改时间
    begin
      if Item1.SubItems.Count > 1 then S1 := Item1.SubItems[1] else S1 := '';
      if Item2.SubItems.Count > 1 then S2 := Item2.SubItems[1] else S2 := '';
      if TryStrToDateTime(S1, D1) and TryStrToDateTime(S2, D2) then
      begin
        if D1 > D2 then Result := 1
        else if D1 < D2 then Result := -1
        else Result := 0;
      end
      else
        Result := CompareText(S1, S2);
    end;
    3: // 类型
    begin
      if Item1.SubItems.Count > 2 then S1 := Item1.SubItems[2] else S1 := '';
      if Item2.SubItems.Count > 2 then S2 := Item2.SubItems[2] else S2 := '';
      Result := CompareText(S1, S2);
    end;
  end;
  
  if not Form.FBigFileSortAsc then
    Result := -Result;
end;

function SummaryCompare(Item1, Item2: TListItem; lParam: Integer): Integer; stdcall;
var
  Form: TfrmDiskAnalysis;
  S1, S2: string;
  N1, N2: Integer;
  Size1, Size2: Int64;
  D1, D2: TDateTime;
begin
  Form := TfrmDiskAnalysis(Pointer(lParam));
  Result := 0;
  
  case Form.FSummarySortColumn of
    0: // 目录
      Result := CompareText(Item1.Caption, Item2.Caption);
    1: // 文件数
    begin
      if Item1.SubItems.Count > 0 then N1 := StrToIntDef(Item1.SubItems[0], 0) else N1 := 0;
      if Item2.SubItems.Count > 0 then N2 := StrToIntDef(Item2.SubItems[0], 0) else N2 := 0;
      if N1 > N2 then Result := 1
      else if N1 < N2 then Result := -1
      else Result := 0;
    end;
    2: // 总大小
    begin
      if Item1.SubItems.Count > 1 then S1 := Item1.SubItems[1] else S1 := '0';
      if Item2.SubItems.Count > 1 then S2 := Item2.SubItems[1] else S2 := '0';
      Size1 := Form.ParseSizeString(S1);
      Size2 := Form.ParseSizeString(S2);
      if Size1 > Size2 then Result := 1
      else if Size1 < Size2 then Result := -1
      else Result := 0;
    end;
    3: // 最近写入
    begin
      if Item1.SubItems.Count > 2 then S1 := Item1.SubItems[2] else S1 := '';
      if Item2.SubItems.Count > 2 then S2 := Item2.SubItems[2] else S2 := '';
      if TryStrToDateTime(S1, D1) and TryStrToDateTime(S2, D2) then
      begin
        if D1 > D2 then Result := 1
        else if D1 < D2 then Result := -1
        else Result := 0;
      end
      else
        Result := CompareText(S1, S2);
    end;
  end;
  
  if not Form.FSummarySortAsc then
    Result := -Result;
end;

procedure TfrmDiskAnalysis.pbChartPaint(Sender: TObject);
const
  Colors: array[0..8] of TColor = (
    $FF6B6B,  // 红
    $4ECDC4,  // 青
    $45B7D1,  // 蓝
    $96CEB4,  // 绿
    $FFEAA7,  // 黄
    $DDA0DD,  // 紫
    $F39C12,  // 橙
    $9B59B6,  // 深紫
    $95A5A6   // 灰
  );
var
  Canvas: TCanvas;
  CenterX, CenterY, Radius: Integer;
  StartAngle, SweepAngle: Double;
  I: Integer;
  Pct: Double;
  LegendX, LegendY: Integer;
  LabelText: string;
  BarLeft, BarWidth, BarHeight, MaxBarHeight: Integer;
  MaxSize: Int64;
begin
  Canvas := pbChart.Canvas;
  Canvas.Brush.Color := clWhite;
  Canvas.FillRect(pbChart.ClientRect);
  
  if (Length(FChartSlices) = 0) or (FChartTotal = 0) then
  begin
    Canvas.Font.Size := 12;
    Canvas.TextOut(20, 20, '请先扫描磁盘以查看空间占用分布');
    Exit;
  end;
  
  // 左侧绘制饼图
  CenterX := 200;
  CenterY := pbChart.Height div 2;
  Radius := Min(CenterX - 20, CenterY - 40);
  
  StartAngle := 0;
  for I := 0 to High(FChartSlices) do
  begin
    Pct := FChartSlices[I].Value / FChartTotal;
    SweepAngle := Pct * 360;
    
    Canvas.Brush.Color := Colors[I mod Length(Colors)];
    Canvas.Pen.Color := clWhite;
    Canvas.Pen.Width := 2;
    
    // 绘制饼图扇形
    Canvas.Pie(
      CenterX - Radius, CenterY - Radius,
      CenterX + Radius, CenterY + Radius,
      CenterX + Round(Radius * Cos(DegToRad(StartAngle))),
      CenterY - Round(Radius * Sin(DegToRad(StartAngle))),
      CenterX + Round(Radius * Cos(DegToRad(StartAngle + SweepAngle))),
      CenterY - Round(Radius * Sin(DegToRad(StartAngle + SweepAngle)))
    );
    
    StartAngle := StartAngle + SweepAngle;
  end;
  
  // 右侧绘制柱状图 + 图例
  LegendX := 420;
  LegendY := 30;
  BarLeft := 440;
  BarWidth := 200;
  MaxBarHeight := 25;
  
  // 找到最大值用于缩放
  MaxSize := 0;
  for I := 0 to High(FChartSlices) do
    if FChartSlices[I].Value > MaxSize then
      MaxSize := FChartSlices[I].Value;
  
  Canvas.Font.Size := 9;
  Canvas.Font.Color := clBlack;
  
  for I := 0 to High(FChartSlices) do
  begin
    // 颜色块
    Canvas.Brush.Color := Colors[I mod Length(Colors)];
    Canvas.FillRect(Rect(LegendX, LegendY, LegendX + 16, LegendY + 16));
    
    // 柱状图
    if MaxSize > 0 then
      BarHeight := Round((FChartSlices[I].Value / MaxSize) * BarWidth)
    else
      BarHeight := 0;
    Canvas.FillRect(Rect(BarLeft, LegendY, BarLeft + BarHeight, LegendY + MaxBarHeight - 5));
    
    // 标签
    Pct := FChartSlices[I].Value / FChartTotal * 100;
    if Pos(':', FChartSlices[I].Key) > 0 then
      LabelText := Copy(FChartSlices[I].Key, Pos(':', FChartSlices[I].Key) + 1, 30)
    else
      LabelText := FChartSlices[I].Key;
    if Length(LabelText) > 25 then
      LabelText := Copy(LabelText, 1, 22) + '...';
    
    Canvas.Brush.Color := clWhite;
    Canvas.TextOut(BarLeft + BarHeight + 8, LegendY + 2, 
      Format('%s (%.1f%%, %s)', [LabelText, Pct, FormatSize(FChartSlices[I].Value)]));
    
    LegendY := LegendY + MaxBarHeight + 5;
  end;
  
  // 总计
  Canvas.Font.Style := [fsBold];
  Canvas.TextOut(BarLeft, LegendY + 10, Format('总计: %s', [FormatSize(FChartTotal)]));
end;

procedure TfrmDiskAnalysis.BtnApplyClick(Sender: TObject);
begin
  // 重新扫描并应用筛选
  BtnScanClick(Sender);
end;

procedure TfrmDiskAnalysis.ExportReportHtml(const FileName: string);
var
  SL: TStringList;
  I: Integer;
begin
  SL := TStringList.Create;
  try
    SL.Add('<!DOCTYPE html>');
    SL.Add('<html><head>');
    SL.Add('<meta charset="UTF-8">');
    SL.Add('<title>磁盘分析报告</title>');
    SL.Add('<style>');
    SL.Add('body { font-family: "Microsoft YaHei", sans-serif; margin: 20px; }');
    SL.Add('table { border-collapse: collapse; width: 100%; margin-top: 20px; }');
    SL.Add('th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }');
    SL.Add('th { background-color: #4CAF50; color: white; }');
    SL.Add('tr:nth-child(even) { background-color: #f2f2f2; }');
    SL.Add('h1 { color: #333; }');
    SL.Add('.summary { background: #f9f9f9; padding: 15px; border-radius: 5px; }');
    SL.Add('</style>');
    SL.Add('</head><body>');
    SL.Add('<h1>磁盘分析报告</h1>');
    SL.Add(Format('<p>生成时间: %s</p>', [DateTimeToStr(Now)]));
    SL.Add(Format('<p>扫描路径: %s</p>', [edtRoot.Text]));
    
    // 汇总信息
    SL.Add('<div class="summary">');
    SL.Add(Format('<p><strong>总大小:</strong> %s</p>', [FormatSize(FChartTotal)]));
    SL.Add(Format('<p><strong>目录数:</strong> %d</p>', [lvSummary.Items.Count]));
    SL.Add(Format('<p><strong>大文件数:</strong> %d</p>', [lvBig.Items.Count]));
    SL.Add('</div>');
    
    // 目录统计表
    SL.Add('<h2>目录统计</h2>');
    SL.Add('<table>');
    SL.Add('<tr><th>目录</th><th>文件数</th><th>总大小</th><th>最近写入</th></tr>');
    for I := 0 to Min(19, lvSummary.Items.Count - 1) do
    begin
      SL.Add(Format('<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>',
        [lvSummary.Items[I].Caption,
         lvSummary.Items[I].SubItems[0],
         lvSummary.Items[I].SubItems[1],
         lvSummary.Items[I].SubItems[2]]));
    end;
    SL.Add('</table>');
    
    // 大文件表
    SL.Add('<h2>Top 20 大文件</h2>');
    SL.Add('<table>');
    SL.Add('<tr><th>文件路径</th><th>大小</th><th>修改时间</th><th>类型</th></tr>');
    for I := 0 to Min(19, lvBig.Items.Count - 1) do
    begin
      SL.Add(Format('<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>',
        [lvBig.Items[I].Caption,
         lvBig.Items[I].SubItems[0],
         lvBig.Items[I].SubItems[1],
         IfThen(lvBig.Items[I].SubItems.Count > 2, lvBig.Items[I].SubItems[2], '')]));
    end;
    SL.Add('</table>');
    
    SL.Add('</body></html>');
    SL.SaveToFile(FileName, TEncoding.UTF8);
  finally
    SL.Free;
  end;
end;

procedure TfrmDiskAnalysis.BtnExportHtmlClick(Sender: TObject);
var
  dlg: TSaveDialog;
  fn: string;
begin
  dlg := TSaveDialog.Create(nil);
  try
    dlg.Filter := 'HTML文件 (*.html)|*.html|所有文件 (*.*)|*.*';
    dlg.DefaultExt := 'html';
    dlg.FileName := 'DiskAnalysisReport.html';
    if dlg.Execute then
    begin
      fn := dlg.FileName;
      ExportReportHtml(fn);
      MessageDlg('已导出到：' + fn, mtInformation, [mbOK], 0);
      // 打开报告
      ShellExecute(0, 'open', PChar(fn), nil, nil, SW_SHOWNORMAL);
    end;
  finally
    dlg.Free;
  end;
end;

end.

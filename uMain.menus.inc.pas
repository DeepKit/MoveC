// Right-click menu handlers for source and target trees
// This include contains light-weight handlers only; heavy operations are avoided.

procedure OpenInExplorerSelect(const APath: string);
begin
  if (APath = '') then Exit;
  ShellExecute(0, 'open', 'explorer.exe', PChar('/select,' + APath), nil, SW_SHOWNORMAL);
end;

// Context hubs
procedure TfrmMain.stvSourceContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
var
  Node: TTreeNode;
  ScreenPt: TPoint;
begin
  Handled := True;
  if stvSource = nil then Exit;
  Node := stvSource.GetNodeAt(MousePos.X, MousePos.Y);
  if Assigned(Node) then stvSource.Selected := Node;
  ScreenPt := stvSource.ClientToScreen(MousePos);
  if Assigned(pmSource) then pmSource.Popup(ScreenPt.X, ScreenPt.Y);
end;

procedure TfrmMain.stvTargetContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
var
  Node: TTreeNode;
  ScreenPt: TPoint;
begin
  Handled := True;
  if stvTarget = nil then Exit;
  Node := stvTarget.GetNodeAt(MousePos.X, MousePos.Y);
  if Assigned(Node) then stvTarget.Selected := Node;
  ScreenPt := stvTarget.ClientToScreen(MousePos);
  if Assigned(pmTarget) then pmTarget.Popup(ScreenPt.X, ScreenPt.Y);
end;

// Source menu
procedure TfrmMain.miSrcOpenClick(Sender: TObject);
begin
  if FSourcePath <> '' then UpdateShellTreePath(stvSource, FSourcePath);
end;

procedure TfrmMain.miSrcOpenInExplorerClick(Sender: TObject);
begin
  OpenInExplorerSelect(FSourcePath);
end;

procedure TfrmMain.miSrcCopyPathClick(Sender: TObject);
begin
  if FSourcePath <> '' then Clipboard.AsText := FSourcePath;
end;

procedure TfrmMain.miSrcSetRootClick(Sender: TObject);
begin
  if FSourcePath = '' then Exit;
  try stvSource.Root := FSourcePath; except stvSource.Root := 'rfDesktop'; end;
  stvSource.ShowRoot := False;
  stvSource.ObjectTypes := [otFolders];
  UpdateShellTreePath(stvSource, FSourcePath);
end;

procedure TfrmMain.miSrcScanHereClick(Sender: TObject);
begin
  if FSourcePath <> '' then begin
    SetProcessingState(True);
    try
      UpdateStatus('🔍 开始扫描目录: ' + FSourcePath);
      ScanDirectory(FSourcePath);
      UpdateStatus('✅ 目录扫描完成');
    finally
      SetProcessingState(False);
    end;
  end;
end;

procedure TfrmMain.miSrcAnalyzeHereClick(Sender: Object);
begin
  if FSourcePath <> '' then begin
    SetProcessingState(True);
    try
      UpdateStatus('📊 开始分析目录: ' + FSourcePath);
      StartSpaceAnalysis(FSourcePath);
      UpdateStatus('✅ 分析任务已启动');
    finally
      SetProcessingState(False);
    end;
  end;
end;

procedure TfrmMain.miSrcRefreshClick(Sender: TObject);
begin
  if FSourcePath <> '' then UpdateShellTreePath(stvSource, FSourcePath);
end;

// Target menu
procedure TfrmMain.miTgtOpenClick(Sender: TObject);
begin
  if FTargetPath <> '' then UpdateShellTreePath(stvTarget, FTargetPath);
end;

procedure TfrmMain.miTgtOpenInExplorerClick(Sender: TObject);
begin
  OpenInExplorerSelect(FTargetPath);
end;

procedure TfrmMain.miTgtCopyPathClick(Sender: TObject);
begin
  if FTargetPath <> '' then Clipboard.AsText := FTargetPath;
end;

procedure TfrmMain.miTgtSetRootClick(Sender: TObject);
begin
  if FTargetPath = '' then Exit;
  try stvTarget.Root := FTargetPath; except stvTarget.Root := 'rfDesktop'; end;
  stvTarget.ShowRoot := False;
  stvTarget.ObjectTypes := [otFolders];
  UpdateShellTreePath(stvTarget, FTargetPath);
end;

procedure TfrmMain.miTgtSetAsTargetPathClick(Sender: TObject);
begin
  if FTargetPath <> '' then begin
    edtTargetDir.Text := FTargetPath;
  end;
end;

procedure TfrmMain.miTgtRefreshClick(Sender: TObject);
begin
  if FTargetPath <> '' then UpdateShellTreePath(stvTarget, FTargetPath);
end;


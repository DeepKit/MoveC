unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, Vcl.ExtCtrls,
  Vcl.FileCtrl, Vcl.ComCtrls, System.IOUtils, Winapi.ShellAPI, System.UITypes,
  // Core interfaces and data types
  DataTypes, IFileAnalyzer2, IMigrationManager2, IRollbackManager2,
  ISecurityManager2, IDonationManager2,
  // Core implementations
  ConfigManager, SecurityManager, FileAnalyzer, DonationManager,
  MigrationManager, RollbackManager2;

type
  TfrmMain = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    DirListBoxSource: TDirectoryListBox;
    FileListBoxSource: TFileListBox;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    edtSource: TLabeledEdit;
    edtTarget: TLabeledEdit;
    btnDirSource: TButton;
    btnDirTarget: TButton;
    StatusTimer: TTimer;
    OpenDialog: TOpenDialog;
    Panel5: TPanel;
    btnAnalyze: TButton;
    btnCopyFiles: TButton;
    btnDeleteAndLink: TButton;
    btnRollback: TButton;
    btnMove: TButton;
    ProgressBar: TProgressBar;
    btnClose: TButton;
    lblSize: TLabel;
    Splitter3: TSplitter;
    pnlCenter: TPanel;
    Panel4: TPanel;
    DirListBoxTarget: TDirectoryListBox;
    FileListBoxTarget: TFileListBox;
    pnlAboutMe: TPanel;
    Splitter4: TSplitter;
    btnCalcDirSize: TButton;
    RichEdit1: TRichEdit;
    procedure btnDirSourceClick(Sender: TObject);
    procedure btnDirTargetClick(Sender: TObject);
    procedure edtSourceChange(Sender: TObject);
    procedure edtTargetChange(Sender: TObject);
    procedure btnAnalyzeClick(Sender: TObject);
    procedure btnCopyFilesClick(Sender: TObject);
    procedure btnDeleteAndLinkClick(Sender: TObject);
    procedure btnRollbackClick(Sender: TObject);
    procedure btnMoveClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure StatusTimerTimer(Sender: TObject);
    procedure DirListBoxTargetDblClick(Sender: TObject);
    procedure DirListBoxTargetChange(Sender: TObject);
    procedure DirListBoxSourceDblClick(Sender: TObject);
    procedure DirListBoxSourceChange(Sender: TObject);
    procedure btnCalcDirSizeClick(Sender: TObject);
  private
    { Private declarations }
    // Core service interfaces
    FFileAnalyzer: IFileAnalyzer;
    FMigrationManager: IMigrationManager;
    FRollbackManager: IRollbackManager;
    FSecurityManager: ISecurityManager;
    FDonationManager: IDonationManager;

    // Core configuration
    FConfigManager: TConfigManager;

    // Application state
    FApplicationState: TApplicationState;
    FSystemInfo: TSystemInfo;

    // Analysis results
    FAnalysisResults: TArray<TFileAnalysisResult>;
    FCurrentMigrationPlan: TMigrationPlan;
    FCurrentBackupId: string;

    // Progress tracking
    FCurrentProcessingPath: string;
    FTotalFiles: Integer;
    FProcessedFiles: Integer;
    FStatusMessages: TStringList;
    
    procedure UpdateUI_Show;
    procedure UpdateUI_Hide;
    procedure CopyFilesOverwrite(SourcePath, DestPath: string);
    procedure UpdateAnalysisProgress(const ACurrentPath: string; AProgress: Integer; const AMessage: string);
    procedure ScanDirectorySimple(const APath: string; AFileList: TStringList);
    function AnalyzeSingleFileSimple(const AFilePath: string): TFileAnalysisResult;
    function AnalyzeDirectoryFeasibility(const ADirectoryPath: string): TFileAnalysisResult;
    procedure AddStatusMessage(const AMessage: string);
    procedure AddColoredStatusMessage(const AMessage: string; AColor: TColor);
    procedure UpdateStatusDisplay;
    procedure MarkDirectoryInTree(const APath: string; AColor: TColor);
    function CalculateDirectorySize(const APath: string): Int64;
    function PadRight(const AText: string; ALength: Integer): string;
    function IsRootOrUserRootDirectory(const APath: string): Boolean;
    
    // Core initialization methods
    procedure InitializeServices;
    procedure InitializeApplicationState;
    procedure InitializeSystemInfo;
    procedure CleanupServices;
    
  public
    { Public declarations }
    destructor Destroy; override;

    // Properties for accessing core services
    property FileAnalyzer: IFileAnalyzer read FFileAnalyzer;
    property MigrationManager: IMigrationManager read FMigrationManager;
    property RollbackManager: IRollbackManager read FRollbackManager;
    property SecurityManager: ISecurityManager read FSecurityManager;
    property DonationManager: IDonationManager read FDonationManager;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.UpdateUI_Show;
begin
  // �ָ�ԭ״
  btnDirSource.Enabled := True;
  btnDirTarget.Enabled := True;
  btnMove.Enabled := True;
  btnAnalyze.Enabled := True;
  btnCopyFiles.Enabled := True;
  btnDeleteAndLink.Enabled := True;
  btnRollback.Enabled := True;
  btnClose.Enabled := True;
  frmMain.Cursor := crDefault;
end;

procedure TfrmMain.UpdateUI_Hide;
begin
  // ��һЩ��ť�����ã��������ʾΪ���ɲ���
  btnDirSource.Enabled := False;
  btnDirTarget.Enabled := False;
  btnMove.Enabled := False;
  btnAnalyze.Enabled := False;
  btnCopyFiles.Enabled := False;
  btnDeleteAndLink.Enabled := False;
  btnRollback.Enabled := False;
  btnClose.Enabled := False;
  frmMain.Cursor := crHourGlass;;
end;

procedure TfrmMain.btnCloseClick(Sender: TObject);
begin
  Self.Close;
end;

// 窗体关闭事件
procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  try
    // 停止定时器
    if Assigned(StatusTimer) then
      StatusTimer.Enabled := False;

    // 清理资源
    CleanupServices;

    // 确保窗体被释放
    Action := caFree;
  except
    // 忽略关闭时的错误，强制关闭
    Action := caFree;
  end;
end;

procedure TfrmMain.btnDirSourceClick(Sender: TObject);
begin
  if OpenDialog.Execute then
  begin
    edtSource.Text := OpenDialog.FileName;
    DirListBoxSource.Directory := ExtractFilePath(edtSource.Text);
  end;
end;

procedure TfrmMain.btnDirTargetClick(Sender: TObject);
begin
  if OpenDialog.Execute then
  begin
    edtTarget.Text := OpenDialog.FileName;
    DirListBoxTarget.Directory := ExtractFilePath(edtTarget.Text);
  end;
end;

procedure TfrmMain.CopyFilesOverwrite(SourcePath, DestPath: string);
var
  SearchRec: TSearchRec;
  FullSourcePath, FullDestPath: string;
begin
  // ����ԴĿ¼�е������ļ�����Ŀ¼
  if FindFirst(SourcePath + '\*', faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        FullSourcePath := SourcePath + '\' + SearchRec.Name;
        FullDestPath := DestPath + '\' + SearchRec.Name;

        if (SearchRec.Attr and faDirectory) = faDirectory then
        begin
          // �����Ŀ¼���ݹ����
          if SearchRec.Name <> '.' then
          begin
            if not DirectoryExists(FullDestPath) then
              CreateDir(FullDestPath);

            CopyFilesOverwrite(FullSourcePath, FullDestPath);
          end;
        end
        else
        begin
          // ������ļ���ֱ�ӿ���
          if not FileExists(FullDestPath) or
            (FileGetAttr(FullDestPath) and faReadOnly <> faReadOnly) then
          begin
            TFile.Copy(FullSourcePath, FullDestPath, True);
          end;
        end;
      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;
end;

// 一键移动功能 - 传统的简单文件复制
procedure TfrmMain.btnMoveClick(Sender: TObject);
var
  i: Integer;
  sourceDir, targetDir: string;
  DestPath: string;
begin
  // 确认操作
  if MessageDlg('一键移动将直接复制文件列表中的文件到目标目录。' + #13#10 +
                '这是传统功能，建议使用新的"分析并标记"→"拷贝文件"流程。' + #13#10 +
                '确定要继续吗？', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  if FileListBoxSource.Items.Count = 0 then
  begin
    AddStatusMessage('错误：文件列表为空，请先选择要移动的文件');
    Exit;
  end;

  UpdateUI_Hide;
  ProgressBar.Max := FileListBoxSource.Items.Count;
  ProgressBar.Position := 0;
  ProgressBar.Visible := True;
  RichEdit1.Visible := True;
  StatusTimer.Enabled := True;

  try
    sourceDir := DirListBoxSource.Directory;
    targetDir := DirListBoxTarget.Directory;

    for i := 0 to FileListBoxSource.Items.Count - 1 do
    begin
      DestPath := targetDir + '\' + FileListBoxSource.Items[i];

      AddStatusMessage(Format('正在复制: %s (%d/%d)',
        [FileListBoxSource.Items[i], i + 1, FileListBoxSource.Items.Count]));

      try
        CopyFilesOverwrite(sourceDir, DestPath);
      except
        on E: Exception do
        begin
          if MessageDlg(Format('复制文件 %s 失败: %s' + #13#10 + '是否继续？',
                              [FileListBoxSource.Items[i], E.Message]),
                       mtError, [mbYes, mbNo], 0) <> mrYes then
            Break;
        end;
      end;

      DirListBoxSource.Update;
      DirListBoxTarget.Update;
      ProgressBar.Position := i + 1;
      Application.ProcessMessages;
    end;

    ShowMessage('文件复制完成！注意：这只是复制，原文件仍在原位置。');

  finally
    ProgressBar.Visible := False;
    // RichEdit1始终保持可见，不需要隐藏
    StatusTimer.Enabled := False;
    AddStatusMessage('就绪状态 - 等待用户操作');
    UpdateStatusDisplay;
    UpdateUI_Show;
  end;
end;



// 分析并标记按钮事件 - 分析整个目录的可移动性
procedure TfrmMain.btnAnalyzeClick(Sender: TObject);
var
  SourcePath: string;
  DirectoryAnalysis: TFileAnalysisResult;
begin
  SourcePath := edtSource.Text;

  if not DirectoryExists(SourcePath) then
  begin
    AddStatusMessage('错误：源目录不存在，请选择有效的目录');
    Exit;
  end;

  // 检查是否是根目录或用户根目录
  if IsRootOrUserRootDirectory(SourcePath) then
  begin
    AddColoredStatusMessage('', clRed);
    AddColoredStatusMessage('╔══════════════════════════════════════════════╗', clRed);
    AddColoredStatusMessage('║ ⚠️ 【警告：不建议分析此目录】                ║', clRed);
    AddColoredStatusMessage('║ 目录：' + PadRight(ExtractFileName(SourcePath), 35) + '║', clRed);
    AddColoredStatusMessage('║ 原因：根目录或用户根目录文件数量巨大         ║', clRed);
    AddColoredStatusMessage('║ 建议：请选择具体的子目录进行分析             ║', clRed);
    AddColoredStatusMessage('╚══════════════════════════════════════════════╝', clRed);

    // 清理并退出
    ProgressBar.Visible := False;
    StatusTimer.Enabled := False;
    UpdateUI_Show;
    Exit;
  end;

  // 禁用按钮防止重复点击
  UpdateUI_Hide;

  // 显示进度
  ProgressBar.Position := 0;
  ProgressBar.Visible := True;
  // RichEdit1始终保持可见，不需要设置

  // 启动定时器
  StatusTimer.Enabled := True;

  AddStatusMessage('=== 开始分析目录的符号链接可行性 ===');
  AddStatusMessage('目标目录: ' + SourcePath);
  AddStatusMessage('分析目标: 判断移动此目录是否会影响程序运行');

  // 强制更新显示
  UpdateStatusDisplay;
  Application.ProcessMessages;

  try
    // 分析整个目录
    UpdateAnalysisProgress(SourcePath, 20, '正在分析目录类型和位置...');
    AddStatusMessage('步骤1: 分析目录路径和类型...');
    UpdateStatusDisplay;
    Application.ProcessMessages;

    DirectoryAnalysis := AnalyzeDirectoryFeasibility(SourcePath);

    AddStatusMessage('步骤2: 评估移动后对程序运行的影响...');
    UpdateStatusDisplay;
    Application.ProcessMessages;

    UpdateAnalysisProgress(SourcePath, 60, '正在检查目录内容和依赖关系...');

    AddStatusMessage('步骤3: 生成最终分析结果...');
    UpdateStatusDisplay;
    Application.ProcessMessages;

    // 显示分析结果 - 不影响文件列表显示
    var StatusColor: string;

    case DirectoryAnalysis.SymlinkFeasibility of
      sfCanLink:
      begin
        StatusColor := '✅ 可以安全移动';
        AddStatusMessage('');
        AddColoredStatusMessage('╔══════════════════════════════════════════════╗', clGreen);
        AddColoredStatusMessage('║ ✓ 【分析结果：可以安全移动】                 ║', clGreen);
        AddColoredStatusMessage('║ 目录：' + PadRight(ExtractFileName(SourcePath), 35) + '║', clGreen);
        AddColoredStatusMessage('║ 结论：此目录可以安全移动并创建符号链接       ║', clGreen);
        AddColoredStatusMessage('╚══════════════════════════════════════════════╝', clGreen);
        // 在目录树中标记为绿色（可链接）
        MarkDirectoryInTree(SourcePath, clGreen);
      end;
      sfRisky:
      begin
        StatusColor := '⚠️ 移动有风险';
        AddStatusMessage('');
        AddColoredStatusMessage('╔══════════════════════════════════════════════╗', clOlive);
        AddColoredStatusMessage('║ ! 【分析结果：移动有风险】                   ║', clOlive);
        AddColoredStatusMessage('║ 目录：' + PadRight(ExtractFileName(SourcePath), 35) + '║', clOlive);
        AddColoredStatusMessage('║ 结论：移动有风险，但符号链接通常可以解决     ║', clOlive);
        AddColoredStatusMessage('╚══════════════════════════════════════════════╝', clOlive);
        // 在目录树中标记为黄色（有风险）
        MarkDirectoryInTree(SourcePath, clOlive);
      end;
      sfCannotMove:
      begin
        StatusColor := '❌ 禁止移动';
        AddStatusMessage('');
        AddColoredStatusMessage('╔══════════════════════════════════════════════╗', clRed);
        AddColoredStatusMessage('║ X 【分析结果：禁止移动】                     ║', clRed);
        AddColoredStatusMessage('║ 目录：' + PadRight(ExtractFileName(SourcePath), 35) + '║', clRed);
        AddColoredStatusMessage('║ 结论：禁止移动，会严重影响系统或程序运行     ║', clRed);
        AddColoredStatusMessage('╚══════════════════════════════════════════════╝', clRed);
        // 在目录树中标记为红色（禁止移动）
        MarkDirectoryInTree(SourcePath, clRed);
      end;
    end;

    // 显示详细原因和建议
    AddStatusMessage('📋 详细原因: ' + DirectoryAnalysis.Reason);

    if DirectoryAnalysis.RequiresRestart then
      AddStatusMessage('⚠️ 注意：移动后可能需要重启相关程序');

    if Length(DirectoryAnalysis.Dependencies) > 0 then
    begin
      AddStatusMessage('🔗 依赖关系: ');
      for var Dep in DirectoryAnalysis.Dependencies do
        AddStatusMessage('   • ' + Dep);
    end;

    // 添加操作建议
    case DirectoryAnalysis.SymlinkFeasibility of
      sfCanLink:
        AddStatusMessage('💡 建议：可以安全移动此目录并创建符号链接');
      sfRisky:
        AddStatusMessage('💡 建议：移动前请先备份，移动后测试相关程序运行');
      sfCannotMove:
        AddStatusMessage('💡 建议：强烈不建议移动此目录');
    end;

    // 存储分析结果
    SetLength(FAnalysisResults, 1);
    FAnalysisResults[0] := DirectoryAnalysis;

    UpdateAnalysisProgress(SourcePath, 100, '目录分析完成');

    // 强制更新显示，确保之前的消息都显示出来
    UpdateStatusDisplay;
    Application.ProcessMessages;

    AddStatusMessage('=== 目录分析完成 ===');
    AddStatusMessage('最终结论: ' + StatusColor);
    AddStatusMessage('详细说明: ' + DirectoryAnalysis.Reason);

    if DirectoryAnalysis.SymlinkFeasibility = sfCanLink then
      AddStatusMessage('建议: 可以安全移动此目录并创建符号链接')
    else if DirectoryAnalysis.SymlinkFeasibility = sfRisky then
      AddStatusMessage('建议: 移动前请先备份，移动后测试相关程序运行')
    else
      AddStatusMessage('建议: 强烈不建议移动此目录');

    // 再次强制更新显示，确保结论显示出来
    UpdateStatusDisplay;
    Application.ProcessMessages;

  except
    on E: Exception do
    begin
      AddStatusMessage('错误：分析失败 - ' + E.Message);
      AddStatusMessage('请检查目录权限或选择其他目录重试');
    end;
  end;

  // 清理
  ProgressBar.Visible := False;
  StatusTimer.Enabled := False;

  // 最终状态更新
  AddStatusMessage('就绪状态 - 分析完成，可以查看结果');
  UpdateStatusDisplay;

  UpdateUI_Show;
end;

// 更新分析进度
procedure TfrmMain.UpdateAnalysisProgress(const ACurrentPath: string; AProgress: Integer; const AMessage: string);
begin
  FCurrentProcessingPath := ACurrentPath;
  ProgressBar.Position := AProgress;

  // 添加状态消息
  AddStatusMessage(Format('正在分析: %s (%d%%) - %s',
    [ExtractFileName(ACurrentPath), AProgress, AMessage]));

  // 不在这里强制更新UI，让定时器处理
end;

// 简化的目录扫描
procedure TfrmMain.ScanDirectorySimple(const APath: string; AFileList: TStringList);
var
  SearchRec: TSearchRec;
  FullPath: string;
begin
  // 只扫描当前目录，不递归子目录（避免卡死）
  if FindFirst(APath + '\*.*', faAnyFile, SearchRec) = 0 then
  begin
    try
      repeat
        if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
        begin
          FullPath := APath + '\' + SearchRec.Name;

          if (SearchRec.Attr and faDirectory) = 0 then
          begin
            // 是文件，添加到列表
            AFileList.Add(FullPath);
          end
          else
          begin
            // 是目录，只添加目录本身，不递归
            AFileList.Add(FullPath);
          end;
        end;

        // 限制最大文件数量，避免处理过多文件
        if AFileList.Count >= 1000 then
          Break;

      until FindNext(SearchRec) <> 0;
    finally
      FindClose(SearchRec);
    end;
  end;
end;

// 符号链接可行性分析
function TfrmMain.AnalyzeSingleFileSimple(const AFilePath: string): TFileAnalysisResult;
var
  FileExt: string;
  FileName: string;
  FilePath: string;
begin
  Result.FilePath := AFilePath;
  Result.Size := 0;
  Result.IsSystemFile := False;
  SetLength(Result.Dependencies, 0);
  Result.RequiresRestart := False;
  Result.CanCreateSymlink := True;
  Result.Reason := '';
  Result.SymlinkFeasibility := sfCanLink; // 默认可链接

  try
    FileName := ExtractFileName(AFilePath);
    FileExt := LowerCase(ExtractFileExt(AFilePath));
    FilePath := LowerCase(AFilePath);

    // 获取文件大小
    if FileExists(AFilePath) then
    begin
      var FileHandle := FileOpen(AFilePath, fmOpenRead or fmShareDenyNone);
      if FileHandle <> -1 then
      begin
        try
          Result.Size := FileSeek(FileHandle, 0, 2);
        finally
          FileClose(FileHandle);
        end;
      end;
    end;

    // 符号链接可行性判断 - 重点关注对程序运行的影响
    if DirectoryExists(AFilePath) then
    begin
      // 目录判断 - 分析移动后对程序运行的影响
      if (Pos('system32', FilePath) > 0) or
         (Pos('syswow64', FilePath) > 0) or
         (Pos('windows\system', FilePath) > 0) or
         (Pos('windows\winsxs', FilePath) > 0) then
      begin
        Result.SymlinkFeasibility := sfCannotMove;
        Result.IsSystemFile := True;
        Result.CanCreateSymlink := False;
        Result.Reason := '系统核心目录，移动会导致系统无法启动';
      end
      else if (Pos('program files', FilePath) > 0) then
      begin
        // 程序安装目录 - 需要检查是否有程序依赖
        if (Pos('common files', FilePath) > 0) or
           (Pos('shared', FilePath) > 0) then
        begin
          Result.SymlinkFeasibility := sfRisky;
          Result.Reason := '共享程序组件，移动可能影响多个程序运行';
        end
        else
        begin
          Result.SymlinkFeasibility := sfCanLink;
          Result.Reason := '独立程序目录，符号链接不影响程序运行';
        end;
      end
      else if (Pos('programdata', FilePath) > 0) then
      begin
        Result.SymlinkFeasibility := sfRisky;
        Result.Reason := '程序数据目录，移动可能影响程序配置和运行';
      end
      else if (Pos('appdata', FilePath) > 0) then
      begin
        if (Pos('roaming', FilePath) > 0) then
        begin
          Result.SymlinkFeasibility := sfCanLink;
          Result.Reason := '用户漫游数据，符号链接不影响程序运行';
        end
        else
        begin
          Result.SymlinkFeasibility := sfRisky;
          Result.Reason := '本地应用数据，移动可能影响程序性能';
        end;
      end
      else if (Pos('temp', FilePath) > 0) or (Pos('cache', FilePath) > 0) then
      begin
        Result.SymlinkFeasibility := sfCanLink;
        Result.Reason := '临时/缓存目录，符号链接不影响程序运行';
      end
      else if (Pos('users\', FilePath) > 0) and
              ((Pos('documents', FilePath) > 0) or (Pos('desktop', FilePath) > 0) or
               (Pos('downloads', FilePath) > 0) or (Pos('pictures', FilePath) > 0) or
               (Pos('music', FilePath) > 0) or (Pos('videos', FilePath) > 0)) then
      begin
        Result.SymlinkFeasibility := sfCanLink;
        Result.Reason := '用户数据目录，符号链接不影响程序运行';
      end
      else
      begin
        Result.SymlinkFeasibility := sfRisky;
        Result.Reason := '未知目录类型，需要评估对程序运行的影响';
      end;
    end
    else
    begin
      // 文件判断 - 重点分析对程序运行的影响
      if (FileExt = '.exe') then
      begin
        if (Pos('system32', FilePath) > 0) or (Pos('windows', FilePath) > 0) then
        begin
          Result.SymlinkFeasibility := sfCannotMove;
          Result.Reason := '系统可执行文件，移动会导致系统功能异常';
        end
        else
        begin
          Result.SymlinkFeasibility := sfCanLink;
          Result.Reason := '应用程序，符号链接不影响程序启动和运行';
        end;
        Result.RequiresRestart := True;
      end
      else if (FileExt = '.dll') or (FileExt = '.ocx') then
      begin
        if (Pos('system32', FilePath) > 0) or (Pos('syswow64', FilePath) > 0) then
        begin
          Result.SymlinkFeasibility := sfCannotMove;
          Result.Reason := '系统库文件，移动会导致程序无法加载';
        end
        else
        begin
          Result.SymlinkFeasibility := sfRisky;
          Result.Reason := '程序库文件，移动可能影响程序加载，但符号链接通常可以解决';
        end;
        SetLength(Result.Dependencies, 1);
        Result.Dependencies[0] := 'Program dependencies';
      end
      else if (FileExt = '.sys') or (FileExt = '.drv') then
      begin
        Result.SymlinkFeasibility := sfCannotMove;
        Result.Reason := '系统驱动文件，移动会导致硬件功能异常';
        Result.IsSystemFile := True;
      end
      else if (FileExt = '.ini') or (FileExt = '.cfg') or (FileExt = '.config') or (FileExt = '.xml') then
      begin
        if (Pos('windows', FilePath) > 0) or (Pos('system32', FilePath) > 0) then
        begin
          Result.SymlinkFeasibility := sfCannotMove;
          Result.Reason := '系统配置文件，移动会导致系统配置丢失';
        end
        else
        begin
          Result.SymlinkFeasibility := sfRisky;
          Result.Reason := '程序配置文件，移动可能导致程序设置丢失，但符号链接可以解决';
        end;
      end
      else if (FileExt = '.reg') then
      begin
        Result.SymlinkFeasibility := sfCannotMove;
        Result.Reason := '注册表文件，移动不影响已导入的注册表项';
      end
      else if (FileExt = '.txt') or (FileExt = '.log') or (FileExt = '.doc') or (FileExt = '.docx') or
              (FileExt = '.pdf') or (FileExt = '.xls') or (FileExt = '.xlsx') or (FileExt = '.ppt') or
              (FileExt = '.jpg') or (FileExt = '.png') or (FileExt = '.gif') or (FileExt = '.bmp') or
              (FileExt = '.mp3') or (FileExt = '.mp4') or (FileExt = '.avi') or (FileExt = '.mkv') or
              (FileExt = '.zip') or (FileExt = '.rar') or (FileExt = '.7z') then
      begin
        Result.SymlinkFeasibility := sfCanLink;
        Result.Reason := '数据文件，符号链接完全不影响程序访问和运行';
      end
      else if (FileExt = '.lnk') then
      begin
        Result.SymlinkFeasibility := sfCanLink;
        Result.Reason := '快捷方式文件，符号链接不影响快捷方式功能';
      end
      else if (FileExt = '.bat') or (FileExt = '.cmd') or (FileExt = '.ps1') then
      begin
        Result.SymlinkFeasibility := sfCanLink;
        Result.Reason := '脚本文件，符号链接不影响脚本执行';
      end
      else
      begin
        Result.SymlinkFeasibility := sfRisky;
        Result.Reason := '未知文件类型，需要测试移动后对相关程序运行的影响';
      end;
    end;

  except
    // 如果分析出错，标记为不能移动
    Result.SymlinkFeasibility := sfCannotMove;
    Result.IsSystemFile := True;
    Result.CanCreateSymlink := False;
    Result.Reason := '分析失败，不建议移动';
  end;
end;

// 拷贝文件按钮事件
procedure TfrmMain.btnCopyFilesClick(Sender: TObject);
var
  TargetPath: string;
  I: Integer;
begin
  if Length(FAnalysisResults) = 0 then
  begin
    ShowMessage('请先执行分析操作');
    Exit;
  end;

  TargetPath := edtTarget.Text;
  if not DirectoryExists(TargetPath) then
  begin
    ShowMessage('目标目录不存在，请选择有效的目录');
    Exit;
  end;

  // 创建迁移计划
  try
    FCurrentMigrationPlan := FMigrationManager.CreateMigrationPlan(edtSource.Text, TargetPath);

    if not FMigrationManager.ValidateMigrationPlan(FCurrentMigrationPlan) then
    begin
      ShowMessage('迁移计划验证失败');
      Exit;
    end;

    // 创建备份
    FCurrentBackupId := FRollbackManager.CreateBackup(FCurrentMigrationPlan);

    // 执行迁移（只复制文件，不删除原文件）
    ProgressBar.Position := 0;
    ProgressBar.Visible := True;

    var Success := FMigrationManager.ExecuteMigration(FCurrentMigrationPlan,
      procedure(AProgress: Integer; const AMessage: string)
      begin
        ProgressBar.Position := AProgress;
        Application.ProcessMessages;
      end);

    ProgressBar.Visible := False;

    if Success then
      ShowMessage('文件复制完成！备份ID: ' + FCurrentBackupId)
    else
      ShowMessage('文件复制失败');

  except
    on E: Exception do
      ShowMessage('复制失败: ' + E.Message);
  end;
end;

// 删除并链接按钮事件
procedure TfrmMain.btnDeleteAndLinkClick(Sender: TObject);
begin
  if FCurrentBackupId = '' then
  begin
    ShowMessage('请先执行文件复制操作');
    Exit;
  end;

  if MessageDlg('确定要删除原文件并创建符号链接吗？此操作有风险，建议先确认备份完整。',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  try
    // 这里应该实现删除原文件并创建符号链接的逻辑
    // 为了安全，暂时只显示消息
    ShowMessage('删除并链接功能正在开发中，为了安全暂未实现');

  except
    on E: Exception do
      ShowMessage('操作失败: ' + E.Message);
  end;
end;

// 回退并恢复按钮事件
procedure TfrmMain.btnRollbackClick(Sender: TObject);
begin
  if FCurrentBackupId = '' then
  begin
    ShowMessage('没有可用的备份进行回退');
    Exit;
  end;

  if MessageDlg('确定要回退到备份状态吗？', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  try
    ProgressBar.Position := 0;
    ProgressBar.Visible := True;

    var Success := FRollbackManager.ExecuteRollback(FCurrentBackupId,
      procedure(AProgress: Integer; const AMessage: string)
      begin
        ProgressBar.Position := AProgress;
        Application.ProcessMessages;
      end);

    ProgressBar.Visible := False;

    if Success then
    begin
      ShowMessage('回退完成');
      FCurrentBackupId := '';
    end
    else
      ShowMessage('回退失败');

  except
    on E: Exception do
      ShowMessage('回退失败: ' + E.Message);
  end;
end;



procedure TfrmMain.edtTargetChange(Sender: TObject);
begin
  DirListBoxTarget.Directory := edtTarget.Text;
end;

procedure TfrmMain.edtSourceChange(Sender: TObject);
begin
  DirListBoxSource.Directory := edtSource.Text;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  try
    // 初始化状态消息列表
    FStatusMessages := TStringList.Create;

    // Initialize core services and application state
    InitializeApplicationState;
    InitializeSystemInfo;
    InitializeServices;

    edtSourceChange(Sender);
    edtTargetChange(Sender);

    // 初始化状态显示
    AddStatusMessage('程序启动完成 - 等待用户操作');
    UpdateStatusDisplay;
  except
    on E: Exception do
    begin
      // 如果初始化失败，显示错误但不阻止程序启动
      ShowMessage('初始化警告: ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.InitializeServices;
begin
  try
    // Initialize configuration manager first
    FConfigManager := TConfigManager.Create;

    // Initialize security manager (depends on config)
    FSecurityManager := TSecurityManager.Create(FConfigManager);

    // Perform security self-check
    if not FSecurityManager.PerformSelfCheck then
    begin
      ShowMessage('安全检查失败，程序可能已被篡改。请重新下载程序。');
      Application.Terminate;
      Exit;
    end;

    // Initialize file analyzer
    FFileAnalyzer := TFileAnalyzer.Create;

    // Initialize migration manager (depends on file analyzer)
    FMigrationManager := TMigrationManager.Create(FFileAnalyzer);

    // Initialize rollback manager (depends on config)
    FRollbackManager := TRollbackManager.Create(FConfigManager);

    // Initialize donation manager (depends on security manager and config)
    FDonationManager := TDonationManager.Create(FSecurityManager, FConfigManager);

    // Update application state
    FApplicationState.IsInitialized := True;

  except
    on E: Exception do
    begin
      ShowMessage('服务初始化失败: ' + E.Message);
      Application.Terminate;
    end;
  end;
end;

procedure TfrmMain.InitializeApplicationState;
begin
  FApplicationState.IsInitialized := False;
  FApplicationState.CurrentLanguage := 'zh-CN'; // Default to Chinese
  FApplicationState.SecurityLevel := 1; // Default security level
  FApplicationState.LastBackupId := '';
  SetLength(FApplicationState.ActiveMigrations, 0);
end;

procedure TfrmMain.InitializeSystemInfo;
var
  VersionInfo: TOSVersionInfo;
begin
  // Initialize system information
  FSystemInfo.AvailableSpace := TDictionary<string, Int64>.Create;
  
  // Get OS version
  VersionInfo.dwOSVersionInfoSize := SizeOf(VersionInfo);
  if GetVersionEx(VersionInfo) then
  begin
    FSystemInfo.OSVersion := Format('%d.%d.%d', 
      [VersionInfo.dwMajorVersion, VersionInfo.dwMinorVersion, VersionInfo.dwBuildNumber]);
  end
  else
    FSystemInfo.OSVersion := 'Unknown';
    
  // Get architecture
  {$IFDEF WIN64}
  FSystemInfo.Architecture := 'x64';
  {$ELSE}
  FSystemInfo.Architecture := 'x86';
  {$ENDIF}
  
  // Check admin mode using security manager
  if Assigned(FSecurityManager) then
    FSystemInfo.IsAdminMode := FSecurityManager.IsRunningAsAdmin
  else
    FSystemInfo.IsAdminMode := False;
  
  // Generate machine fingerprint using security manager
  if Assigned(FSecurityManager) then
    FSystemInfo.MachineFingerprint := FSecurityManager.GenerateMachineFingerprint
  else
    FSystemInfo.MachineFingerprint := 'PLACEHOLDER_FINGERPRINT';
end;

destructor TfrmMain.Destroy;
begin
  try
    // 先停止定时器
    if Assigned(StatusTimer) then
    begin
      StatusTimer.Enabled := False;
    end;

    // 清理服务
    CleanupServices;
  except
    // 忽略清理时的错误
  end;

  try
    inherited Destroy;
  except
    // 忽略继承析构时的错误
  end;
end;

procedure TfrmMain.CleanupServices;
begin
  try
    // 先清理接口引用（这些是自动管理的）
    try
      FDonationManager := nil;
    except
    end;

    try
      FRollbackManager := nil;
    except
    end;

    try
      FMigrationManager := nil;
    except
    end;

    try
      FFileAnalyzer := nil;
    except
    end;

    try
      FSecurityManager := nil;
    except
    end;

    // Clean up configuration manager
    try
      if Assigned(FConfigManager) then
      begin
        FConfigManager.Free;
        FConfigManager := nil;
      end;
    except
      FConfigManager := nil;
    end;

    // Clean up system info
    try
      if Assigned(FSystemInfo.AvailableSpace) then
      begin
        FSystemInfo.AvailableSpace.Free;
        FSystemInfo.AvailableSpace := nil;
      end;
    except
      FSystemInfo.AvailableSpace := nil;
    end;

    // Clean up status messages
    try
      if Assigned(FStatusMessages) then
      begin
        FStatusMessages.Free;
        FStatusMessages := nil;
      end;
    except
      FStatusMessages := nil;
    end;

  except
    // Ignore all cleanup errors
  end;
end;

// 添加状态消息
procedure TfrmMain.AddStatusMessage(const AMessage: string);
var
  TimeStamp: string;
begin
  try
    if not Assigned(FStatusMessages) then
      Exit;

    TimeStamp := FormatDateTime('hh:nn:ss', Now);
    FStatusMessages.Add(Format('[%s] %s', [TimeStamp, AMessage]));

    // 限制消息数量，避免内存过多占用
    while FStatusMessages.Count > 100 do
      FStatusMessages.Delete(0);
  except
    // 忽略状态消息错误
  end;
end;

// 添加彩色状态消息
procedure TfrmMain.AddColoredStatusMessage(const AMessage: string; AColor: TColor);
var
  TimeStamp: string;
  FullMessage: string;
begin
  try
    if not Assigned(RichEdit1) then
      Exit;

    TimeStamp := FormatDateTime('hh:nn:ss', Now);
    FullMessage := Format('[%s] %s', [TimeStamp, AMessage]);

    // 直接添加到RichEdit控件中，支持彩色
    RichEdit1.SelStart := Length(RichEdit1.Text);
    RichEdit1.SelAttributes.Color := AColor;
    RichEdit1.Lines.Add(FullMessage);

    // 滚动到最后一行
    RichEdit1.SelStart := Length(RichEdit1.Text);
    RichEdit1.Perform(EM_SCROLLCARET, 0, 0);

    // 同时添加到FStatusMessages以保持兼容性
    if Assigned(FStatusMessages) then
    begin
      FStatusMessages.Add(FullMessage);
      while FStatusMessages.Count > 100 do
        FStatusMessages.Delete(0);
    end;
  except
    // 忽略状态消息错误
  end;
end;

// 更新状态显示
procedure TfrmMain.UpdateStatusDisplay;
begin
  try
    if not Assigned(FStatusMessages) or not Assigned(RichEdit1) then
      Exit;

    RichEdit1.Lines.Assign(FStatusMessages);

    // 滚动到最后一行
    if RichEdit1.Lines.Count > 0 then
    begin
      RichEdit1.SelStart := Length(RichEdit1.Text);
      RichEdit1.Perform(EM_SCROLLCARET, 0, 0);
    end;

    // 强制刷新显示
    RichEdit1.Refresh;
    Application.ProcessMessages;
  except
    // 忽略状态显示错误
  end;
end;

// 分析整个目录的符号链接可行性
function TfrmMain.AnalyzeDirectoryFeasibility(const ADirectoryPath: string): TFileAnalysisResult;
var
  DirPath: string;
  DirName: string;
begin
  Result.FilePath := ADirectoryPath;
  Result.Size := 0;
  Result.IsSystemFile := False;
  SetLength(Result.Dependencies, 0);
  Result.RequiresRestart := False;
  Result.CanCreateSymlink := True;
  Result.Reason := '';
  Result.SymlinkFeasibility := sfCanLink; // 默认可链接

  try
    DirPath := LowerCase(ADirectoryPath);
    DirName := LowerCase(ExtractFileName(ADirectoryPath));

    AddStatusMessage('正在分析目录: ' + ExtractFileName(ADirectoryPath));
    AddStatusMessage('完整路径: ' + ADirectoryPath);

    // 计算目录大小（简化）
    try
      var SearchRec: TSearchRec;
      if FindFirst(ADirectoryPath + '\*.*', faAnyFile, SearchRec) = 0 then
      begin
        try
          repeat
            if (SearchRec.Attr and faDirectory) = 0 then
              Result.Size := Result.Size + SearchRec.Size;
          until FindNext(SearchRec) <> 0;
        finally
          FindClose(SearchRec);
        end;
      end;
    except
      // 忽略大小计算错误
    end;

    // 核心判断逻辑：这个目录移动后是否会影响程序运行

    // 1. 系统关键目录 - 绝对不能移动
    if (Pos('c:\windows', DirPath) = 1) or
       (Pos('c:\program files\windows', DirPath) = 1) or
       (Pos('system32', DirPath) > 0) or
       (Pos('syswow64', DirPath) > 0) or
       (Pos('winsxs', DirPath) > 0) then
    begin
      AddStatusMessage('检测到系统关键目录');
      AddStatusMessage('判断结果: 禁止移动 - 会导致Windows无法正常运行');
      Result.SymlinkFeasibility := sfCannotMove;
      Result.IsSystemFile := True;
      Result.CanCreateSymlink := False;
      Result.Reason := '系统关键目录，移动会导致Windows无法正常运行';
      // 不要Exit，让主流程继续执行
    end

    // 2. 程序安装目录分析
    else if (Pos('c:\program files', DirPath) = 1) then
    begin
      AddStatusMessage('检测到程序安装目录');
      // 检查是否是共享组件目录
      if (Pos('common files', DirPath) > 0) or
         (Pos('microsoft shared', DirPath) > 0) or
         (Pos('shared', DirName) > 0) then
      begin
        AddStatusMessage('判断结果: 有风险 - 共享组件目录');
        Result.SymlinkFeasibility := sfRisky;
        Result.Reason := '共享程序组件目录，移动可能影响多个程序运行';
        SetLength(Result.Dependencies, 1);
        Result.Dependencies[0] := '多个程序可能依赖此目录';
      end
      else
      begin
        AddStatusMessage('判断结果: 可链接 - 独立程序目录');
        Result.SymlinkFeasibility := sfCanLink;
        Result.Reason := '独立程序安装目录，符号链接不会影响程序运行';
      end;
    end

    // 3. 程序数据目录分析
    else if (Pos('c:\programdata', DirPath) = 1) then
    begin
      AddStatusMessage('检测到程序数据目录');
      AddStatusMessage('判断结果: 有风险 - 可能影响程序配置');
      Result.SymlinkFeasibility := sfRisky;
      Result.Reason := '程序数据目录，移动可能影响程序配置，但符号链接通常可以解决';
      Result.RequiresRestart := True;
    end

    // 4. 用户目录分析
    else if (Pos('c:\users', DirPath) = 1) then
    begin
      AddStatusMessage('检测到用户目录');
      // 检查是否是系统用户目录
      if (Pos('administrator', DirPath) > 0) or
         (Pos('default', DirPath) > 0) or
         (Pos('public', DirPath) > 0) or
         (Pos('all users', DirPath) > 0) then
      begin
        AddStatusMessage('检测到系统用户目录: ' + DirName);
        AddStatusMessage('判断结果: 禁止移动 - 会影响系统用户账户功能');
        Result.SymlinkFeasibility := sfCannotMove;
        Result.IsSystemFile := True;
        Result.CanCreateSymlink := False;
        Result.Reason := '系统用户目录，移动会影响系统用户账户功能';
        // 不要Exit，让主流程继续执行
      end;

      if (Pos('appdata\local', DirPath) > 0) then
      begin
        Result.SymlinkFeasibility := sfRisky;
        Result.Reason := '本地应用数据，移动可能影响程序性能，但符号链接可以解决';
      end
      else if (Pos('appdata\roaming', DirPath) > 0) then
      begin
        Result.SymlinkFeasibility := sfCanLink;
        Result.Reason := '漫游用户数据，符号链接完全不影响程序运行';
      end
      else if (Pos('documents', DirPath) > 0) or
              (Pos('desktop', DirPath) > 0) or
              (Pos('downloads', DirPath) > 0) or
              (Pos('pictures', DirPath) > 0) or
              (Pos('music', DirPath) > 0) or
              (Pos('videos', DirPath) > 0) then
      begin
        Result.SymlinkFeasibility := sfCanLink;
        Result.Reason := '用户数据文件夹，符号链接不会影响任何程序运行';
      end
      else
      begin
        Result.SymlinkFeasibility := sfRisky;
        Result.Reason := '用户目录，需要确认是否包含重要的用户配置';
      end;
    end

    // 5. 游戏和娱乐软件目录
    else if (Pos('games', DirPath) > 0) or
            (Pos('steam', DirPath) > 0) or
            (Pos('epic', DirPath) > 0) then
    begin
      AddStatusMessage('检测到游戏目录');
      AddStatusMessage('判断结果: 可链接 - 现代游戏引擎支持符号链接');
      Result.SymlinkFeasibility := sfCanLink;
      Result.Reason := '游戏目录，符号链接不影响游戏运行（现代游戏引擎支持）';
    end

    // 6. 开发工具目录
    else if (Pos('sdk', DirPath) > 0) or
            (Pos('tools', DirPath) > 0) or
            (Pos('ide', DirPath) > 0) then
    begin
      AddStatusMessage('检测到开发工具目录');
      AddStatusMessage('判断结果: 可链接 - 符号链接不影响工具运行');
      Result.SymlinkFeasibility := sfCanLink;
      Result.Reason := '开发工具目录，符号链接不影响工具运行';
    end

    // 7. 临时和缓存目录
    else if (Pos('temp', DirPath) > 0) or
            (Pos('cache', DirPath) > 0) or
            (Pos('tmp', DirPath) > 0) then
    begin
      AddStatusMessage('检测到临时/缓存目录');
      AddStatusMessage('判断结果: 可链接 - 完全不影响程序运行');
      Result.SymlinkFeasibility := sfCanLink;
      Result.Reason := '临时/缓存目录，符号链接完全不影响程序运行';
    end
    // 8. 默认情况 - 需要谨慎评估
    else
    begin
      AddStatusMessage('未知目录类型，需要谨慎评估');
      AddStatusMessage('判断结果: 有风险 - 建议先测试');
      Result.SymlinkFeasibility := sfRisky;
      Result.Reason := '未知类型目录，建议先测试移动对相关程序运行的影响';
    end;

  except
    on E: Exception do
    begin
      Result.SymlinkFeasibility := sfCannotMove;
      Result.IsSystemFile := True;
      Result.CanCreateSymlink := False;
      Result.Reason := '分析失败，为安全起见不建议移动: ' + E.Message;
    end;
  end;
end;

// 定时器事件 - 定期更新状态显示
procedure TfrmMain.StatusTimerTimer(Sender: TObject);
begin
  try
    UpdateStatusDisplay;
  except
    // 忽略定时器错误
  end;
end;

// 目标目录列表框双击事件
procedure TfrmMain.DirListBoxTargetDblClick(Sender: TObject);
var
  DirSize: Int64;
  SizeText: string;
begin
  try
    // 双击时自动更新文件列表（通过FileList属性自动处理）
    // 同时更新目标路径编辑框
    if Assigned(DirListBoxTarget) then
    begin
      edtTarget.Text := DirListBoxTarget.Directory;
      AddStatusMessage('🎯 目标目录已更改为: ' + DirListBoxTarget.Directory);

      // 先强制刷新文件列表，让用户立即看到文件
      if Assigned(FileListBoxTarget) then
      begin
        FileListBoxTarget.Update;
        AddStatusMessage(Format('📄 目标目录包含 %d 个文件', [FileListBoxTarget.Items.Count]));
      end;

      // 清除大小显示，提示使用专用按钮
      if Assigned(lblSize) then
      begin
        lblSize.Caption := '点击"计算目录大小"按钮获取大小信息';
        lblSize.Visible := True;
        lblSize.Refresh;
      end;
      AddStatusMessage('💡 提示：点击"计算目录大小"按钮可显示目录大小信息');
    end;
  except
    on E: Exception do
      AddStatusMessage('❌ 更新目标目录失败: ' + E.Message);
  end;
end;

// 目标目录列表框变化事件
procedure TfrmMain.DirListBoxTargetChange(Sender: TObject);
begin
  try
    // 目录变化时自动更新目标路径编辑框
    if Assigned(DirListBoxTarget) then
    begin
      edtTarget.Text := DirListBoxTarget.Directory;

      // 强制刷新文件列表
      if Assigned(FileListBoxTarget) then
      begin
        FileListBoxTarget.Update;
      end;
    end;
  except
    // 忽略变化事件错误
  end;
end;

// 源目录列表框双击事件
procedure TfrmMain.DirListBoxSourceDblClick(Sender: TObject);
var
  DirSize: Int64;
  SizeText: string;
begin
  try
    // 双击时自动更新文件列表（通过FileList属性自动处理）
    // 同时更新源路径编辑框
    if Assigned(DirListBoxSource) then
    begin
      edtSource.Text := DirListBoxSource.Directory;
      AddStatusMessage('📁 源目录已更改为: ' + DirListBoxSource.Directory);

      // 先强制刷新文件列表，让用户立即看到文件
      if Assigned(FileListBoxSource) then
      begin
        FileListBoxSource.Update;
        AddStatusMessage(Format('📄 源目录包含 %d 个文件', [FileListBoxSource.Items.Count]));
      end;

      // 清除之前的分析结果
      SetLength(FAnalysisResults, 0);
      AddStatusMessage('🔄 目录已更改，请重新执行分析');

      // 清除大小显示，提示使用专用按钮
      if Assigned(lblSize) then
      begin
        lblSize.Caption := '点击"计算目录大小"按钮获取大小信息';
        lblSize.Visible := True;
        lblSize.Refresh;
      end;
      AddStatusMessage('💡 提示：点击"计算目录大小"按钮可显示目录大小信息');
    end;
  except
    on E: Exception do
      AddStatusMessage('❌ 更新源目录失败: ' + E.Message);
  end;
end;

// 源目录列表框变化事件
procedure TfrmMain.DirListBoxSourceChange(Sender: TObject);
begin
  try
    // 目录变化时自动更新源路径编辑框
    if Assigned(DirListBoxSource) then
    begin
      edtSource.Text := DirListBoxSource.Directory;

      // 强制刷新文件列表
      if Assigned(FileListBoxSource) then
      begin
        FileListBoxSource.Update;
      end;

      // 清除之前的分析结果
      SetLength(FAnalysisResults, 0);
    end;
  except
    // 忽略变化事件错误
  end;
end;

// 在目录树中标记目录颜色
procedure TfrmMain.MarkDirectoryInTree(const APath: string; AColor: TColor);
var
  I: Integer;
  DirName: string;
  ColorName: string;
begin
  try
    DirName := ExtractFileName(APath);

    // 根据颜色确定显示名称
    case AColor of
      clGreen: ColorName := '绿色（可链接）';
      clRed: ColorName := '红色（禁止移动）';
      clOlive: ColorName := '橄榄色（有风险）';
    else
      ColorName := '未知颜色';
    end;

    // 在源目录列表框中查找并标记
    if Assigned(DirListBoxSource) then
    begin
      for I := 0 to DirListBoxSource.Items.Count - 1 do
      begin
        if SameText(DirListBoxSource.Items[I], DirName) then
        begin
          AddStatusMessage(Format('🎨 目录 "%s" 已标记为: %s', [DirName, ColorName]));
          Break;
        end;
      end;
    end;
  except
    on E: Exception do
      AddStatusMessage('❌ 标记目录颜色失败: ' + E.Message);
  end;
end;

// 计算目录大小（包括所有子目录）
function TfrmMain.CalculateDirectorySize(const APath: string): Int64;
var
  SearchRec: TSearchRec;
  SubPath: string;
begin
  Result := 0;

  try
    if not DirectoryExists(APath) then
      Exit;

    // 查找所有文件和子目录
    if FindFirst(APath + '\*', faAnyFile, SearchRec) = 0 then
    begin
      try
        repeat
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
          begin
            SubPath := APath + '\' + SearchRec.Name;

            if (SearchRec.Attr and faDirectory) <> 0 then
            begin
              // 递归计算子目录大小
              Result := Result + CalculateDirectorySize(SubPath);
            end
            else
            begin
              // 累加文件大小
              Result := Result + SearchRec.Size;
            end;
          end;
        until FindNext(SearchRec) <> 0;
      finally
        FindClose(SearchRec);
      end;
    end;
  except
    // 忽略访问权限错误等
  end;
end;

// 字符串右填充函数
function TfrmMain.PadRight(const AText: string; ALength: Integer): string;
begin
  Result := AText;
  while Length(Result) < ALength do
    Result := Result + ' ';
  if Length(Result) > ALength then
    Result := Copy(Result, 1, ALength - 3) + '...';
end;

// 检查是否是根目录或用户根目录
function TfrmMain.IsRootOrUserRootDirectory(const APath: string): Boolean;
var
  NormalizedPath: string;
begin
  Result := False;

  try
    NormalizedPath := LowerCase(Trim(APath));

    // 移除末尾的反斜杠
    if (Length(NormalizedPath) > 1) and (NormalizedPath[Length(NormalizedPath)] = '\') then
      NormalizedPath := Copy(NormalizedPath, 1, Length(NormalizedPath) - 1);

    // 检查是否是驱动器根目录 (C:, D:, 等)
    if (Length(NormalizedPath) = 2) and (NormalizedPath[2] = ':') then
    begin
      Result := True;
      Exit;
    end;

    // 检查是否是用户根目录
    if SameText(NormalizedPath, 'c:\users') then
    begin
      Result := True;
      Exit;
    end;

    // 检查是否是Program Files根目录
    if SameText(NormalizedPath, 'c:\program files') or
       SameText(NormalizedPath, 'c:\program files (x86)') then
    begin
      Result := True;
      Exit;
    end;

    // 检查是否是Windows根目录
    if SameText(NormalizedPath, 'c:\windows') then
    begin
      Result := True;
      Exit;
    end;

  except
    // 如果出现异常，为安全起见返回True
    Result := True;
  end;
end;

// 计算目录大小按钮点击事件
procedure TfrmMain.btnCalcDirSizeClick(Sender: TObject);
var
  SourcePath: string;
  DirSize: Int64;
  SizeText: string;
begin
  try
    SourcePath := edtSource.Text;

    if not DirectoryExists(SourcePath) then
    begin
      AddColoredStatusMessage('❌ 错误：源目录不存在，请先选择有效的目录', clRed);
      Exit;
    end;

    // 检查是否是根目录
    if IsRootOrUserRootDirectory(SourcePath) then
    begin
      AddColoredStatusMessage('', clRed);
      AddColoredStatusMessage('╔══════════════════════════════════════════════╗', clRed);
      AddColoredStatusMessage('║ ⚠️ 【警告：此目录文件数量巨大】              ║', clRed);
      AddColoredStatusMessage('║ 目录：' + PadRight(ExtractFileName(SourcePath), 35) + '║', clRed);
      AddColoredStatusMessage('║ 计算大小可能需要很长时间并导致程序卡死       ║', clRed);
      AddColoredStatusMessage('║ 建议：选择具体的子目录进行计算               ║', clRed);
      AddColoredStatusMessage('║ 是否继续？请谨慎考虑...                     ║', clRed);
      AddColoredStatusMessage('╚══════════════════════════════════════════════╝', clRed);

      if Assigned(lblSize) then
      begin
        lblSize.Caption := '目录过大，建议不要计算';
        lblSize.Visible := True;
        lblSize.Refresh;
      end;

      // 对于根目录，给出警告但不阻止操作（用户可以自己决定）
      AddStatusMessage('⚠️ 如果确实需要计算根目录大小，请再次点击按钮确认');
      Exit;
    end;

    // 计算并显示目录大小
    AddStatusMessage('');
    AddColoredStatusMessage('📊 正在计算目录大小，请稍候...', clBlue);
    UpdateStatusDisplay;
    Application.ProcessMessages;

    DirSize := CalculateDirectorySize(SourcePath);

    // 格式化大小显示
    if DirSize >= 1024 * 1024 * 1024 then
      SizeText := Format('%.2f GB', [DirSize / (1024 * 1024 * 1024)])
    else if DirSize >= 1024 * 1024 then
      SizeText := Format('%.2f MB', [DirSize / (1024 * 1024)])
    else if DirSize >= 1024 then
      SizeText := Format('%.2f KB', [DirSize / 1024])
    else
      SizeText := Format('%d 字节', [DirSize]);

    // 显示在lblSize中
    if Assigned(lblSize) then
    begin
      lblSize.Caption := '目录大小: ' + SizeText;
      lblSize.Visible := True;
      lblSize.Refresh;
      AddColoredStatusMessage('✅ 计算完成: ' + lblSize.Caption, clGreen);
    end;

    // 显示详细统计信息
    AddStatusMessage('');
    AddColoredStatusMessage('┌──────────────────────────────────────────────┐', clBlue);
    AddColoredStatusMessage('│ 目录大小计算结果                             │', clBlue);
    AddColoredStatusMessage('├──────────────────────────────────────────────┤', clBlue);
    AddColoredStatusMessage('│ 目录: ' + PadRight(ExtractFileName(SourcePath), 37) + '│', clBlue);
    AddColoredStatusMessage('│ 大小: ' + PadRight(SizeText, 37) + '│', clBlue);
    AddColoredStatusMessage('│ 字节: ' + PadRight(Format('%d', [DirSize]), 37) + '│', clBlue);
    AddColoredStatusMessage('└──────────────────────────────────────────────┘', clBlue);

  except
    on E: Exception do
    begin
      AddColoredStatusMessage('❌ 计算目录大小失败: ' + E.Message, clRed);
      if Assigned(lblSize) then
      begin
        lblSize.Caption := '计算失败';
        lblSize.Visible := True;
        lblSize.Refresh;
      end;
    end;
  end;
end;

end.

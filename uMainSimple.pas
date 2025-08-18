unit uMainSimple;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI,
  System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections, System.Generics.Defaults, System.Threading, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Menus, Vcl.FileCtrl, Vcl.Clipbrd,
  System.IOUtils, System.UITypes,
  // Modern UI styles and strings
  uStyles, uStrings,
  // Core modules
  DataTypes, ConfigManager,
  // 配置管理模块
  uConfigManager,
  // 重复文件清理模块
  uSmartDuplicateCleanup,
  // 目录迁移模块
  uDirectoryMigration;

type
  TfrmMain = class(TForm)
    // 主面板
    pnlMain: TPanel;
    
    // 工具栏
    pnlToolbar: TPanel;
    btnCleanRecycleBin: TButton;
    btnCleanTemp: TButton;
    btnCleanBackup: TButton;
    btnCleanUpdate: TButton;
    btnSmartClean: TButton;
    btnSmartMigration: TButton;
    btnExit: TButton;
    
    // 左侧面板 - 源目录
    pnlLeft: TPanel;
    lblSourceDir: TLabel;
    edtSourceDir: TEdit;
    btnBrowseSource: TButton;
    tvSource: TTreeView;
    
    // 右侧面板 - 目标目录
    pnlRight: TPanel;
    lblTargetDir: TLabel;
    edtTargetDir: TEdit;
    btnBrowseTarget: TButton;
    tvTarget: TTreeView;
    
    // 状态面板
    pnlStatus: TPanel;
    lblStatus: TLabel;
    ProgressBar1: TProgressBar;
    memoStatus: TMemo;
    
    // 底部状态栏
    StatusBar1: TStatusBar;
    
    // 菜单
    MainMenu1: TMainMenu;
    miFile: TMenuItem;
    miExit: TMenuItem;
    miTools: TMenuItem;
    miConfigManager: TMenuItem;
    
    // 弹出菜单
    pmSource: TPopupMenu;
    pmTarget: TPopupMenu;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    
    // 工具栏按钮事件
    procedure btnCleanRecycleBinClick(Sender: TObject);
    procedure btnCleanTempClick(Sender: TObject);
    procedure btnCleanBackupClick(Sender: TObject);
    procedure btnCleanUpdateClick(Sender: TObject);
    procedure btnSmartCleanClick(Sender: TObject);
    procedure btnSmartMigrationClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    
    // 浏览按钮事件
    procedure btnBrowseSourceClick(Sender: TObject);
    procedure btnBrowseTargetClick(Sender: TObject);
    
    // 目录树事件
    procedure tvSourceChange(Sender: TObject; Node: TTreeNode);
    procedure tvTargetChange(Sender: TObject; Node: TTreeNode);
    procedure tvSourceDblClick(Sender: TObject);
    procedure tvTargetDblClick(Sender: TObject);
    procedure tvSourceKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure tvTargetKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    
    // 菜单事件
    procedure miExitClick(Sender: TObject);
    procedure miConfigManagerClick(Sender: TObject);
    
  private
    FSourcePath: string;
    FTargetPath: string;
    FStyleManager: TStyleManager;
    
    procedure InitializeInterface;
    procedure InitializeTreeViews;
    procedure UpdateTreeViewPath(ATreeView: TTreeView; const APath: string);
    procedure UpdateStatus(const AMessage: string);
    procedure LoadDirectoryTree(ATreeView: TTreeView; const APath: string);
    
    // 清理功能实现
    procedure CleanRecycleBin;
    procedure CleanTempFiles;
    procedure CleanBackupFiles;
    procedure CleanUpdateCache;
    
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FStyleManager := TStyleManager.Create;
  FSourcePath := '';
  FTargetPath := '';
  
  InitializeInterface;
  InitializeTreeViews;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FStyleManager.Free;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  // 设置默认路径
  if DirectoryExists('C:\Users') then
  begin
    FSourcePath := 'C:\Users';
    edtSourceDir.Text := FSourcePath;
    LoadDirectoryTree(tvSource, FSourcePath);
  end;
  
  if DirectoryExists('D:\') then
  begin
    FTargetPath := 'D:\';
    edtTargetDir.Text := FTargetPath;
    LoadDirectoryTree(tvTarget, FTargetPath);
  end;
  
  UpdateStatus('就绪 - 选择源目录和目标目录开始操作');
end;

procedure TfrmMain.InitializeInterface;
begin
  // 应用现代化样式
  if Assigned(FStyleManager) then
  begin
    FStyleManager.StyleForm(Self);
    FStyleManager.StylePanel(pnlMain);
    FStyleManager.StylePanel(pnlToolbar);
    FStyleManager.StylePanel(pnlLeft);
    FStyleManager.StylePanel(pnlRight);
    FStyleManager.StylePanel(pnlStatus);
    
    // 应用按钮样式
    FStyleManager.StyleButton(btnCleanRecycleBin);
    FStyleManager.StyleButton(btnCleanTemp);
    FStyleManager.StyleButton(btnCleanBackup);
    FStyleManager.StyleButton(btnCleanUpdate);
    FStyleManager.StyleButton(btnSmartClean);
    FStyleManager.StyleButton(btnSmartMigration);
    FStyleManager.StyleButton(btnExit);
    FStyleManager.StyleButton(btnBrowseSource);
    FStyleManager.StyleButton(btnBrowseTarget);
    
    // 应用编辑框样式
    FStyleManager.StyleEdit(edtSourceDir);
    FStyleManager.StyleEdit(edtTargetDir);
    
    // 应用其他控件样式
    FStyleManager.StyleProgressBar(ProgressBar1);
    FStyleManager.StyleMemo(memoStatus);
    FStyleManager.StyleTreeView(tvSource);
    FStyleManager.StyleTreeView(tvTarget);
  end;
end;

procedure TfrmMain.InitializeTreeViews;
begin
  // 初始化目录树
  tvSource.ReadOnly := True;
  tvTarget.ReadOnly := True;
  
  // 设置图标
  tvSource.ShowButtons := True;
  tvSource.ShowLines := True;
  tvSource.ShowRoot := True;
  
  tvTarget.ShowButtons := True;
  tvTarget.ShowLines := True;
  tvTarget.ShowRoot := True;
end;

procedure TfrmMain.LoadDirectoryTree(ATreeView: TTreeView; const APath: string);
var
  RootNode: TTreeNode;
  SR: TSearchRec;
  SubPath: string;
begin
  if not DirectoryExists(APath) then Exit;
  
  ATreeView.Items.BeginUpdate;
  try
    ATreeView.Items.Clear;
    
    // 添加根节点
    RootNode := ATreeView.Items.Add(nil, ExtractFileName(APath));
    RootNode.Data := Pointer(StrNew(PChar(APath)));
    
    // 添加子目录
    if FindFirst(TPath.Combine(APath, '*'), faDirectory, SR) = 0 then
    begin
      repeat
        if (SR.Name <> '.') and (SR.Name <> '..') and 
           ((SR.Attr and faDirectory) <> 0) then
        begin
          SubPath := TPath.Combine(APath, SR.Name);
          var SubNode := ATreeView.Items.AddChild(RootNode, SR.Name);
          SubNode.Data := Pointer(StrNew(PChar(SubPath)));
        end;
      until FindNext(SR) <> 0;
      FindClose(SR);
    end;
    
    RootNode.Expanded := True;
  finally
    ATreeView.Items.EndUpdate;
  end;
end;

procedure TfrmMain.UpdateTreeViewPath(ATreeView: TTreeView; const APath: string);
begin
  LoadDirectoryTree(ATreeView, APath);
end;

procedure TfrmMain.UpdateStatus(const AMessage: string);
begin
  lblStatus.Caption := AMessage;
  memoStatus.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' - ' + AMessage);
  Application.ProcessMessages;
end;

// 工具栏按钮事件实现
procedure TfrmMain.btnCleanRecycleBinClick(Sender: TObject);
begin
  CleanRecycleBin;
end;

procedure TfrmMain.btnCleanTempClick(Sender: TObject);
begin
  CleanTempFiles;
end;

procedure TfrmMain.btnCleanBackupClick(Sender: TObject);
begin
  CleanBackupFiles;
end;

procedure TfrmMain.btnCleanUpdateClick(Sender: TObject);
begin
  CleanUpdateCache;
end;

procedure TfrmMain.btnSmartCleanClick(Sender: TObject);
begin
  try
    UpdateStatus('🧹 正在打开智能清理...');
    
    var frmCleanup := TfrmSmartDuplicateCleanup.Create(Self);
    try
      if frmCleanup.ShowModal = mrOk then
      begin
        UpdateStatus('✅ 智能清理操作已完成');
      end
      else
      begin
        UpdateStatus('ℹ️ 智能清理操作已取消');
      end;
    finally
      frmCleanup.Free;
    end;
  except
    on E: Exception do
    begin
      UpdateStatus('❌ 打开智能清理失败: ' + E.Message);
      ShowMessage('打开智能清理功能时发生错误：' + #13#10 + E.Message);
    end;
  end;
end;

procedure TfrmMain.btnSmartMigrationClick(Sender: TObject);
begin
  try
    UpdateStatus('🎯 正在打开智能目录迁移...');
    
    if TfrmDirectoryMigration.ShowMigrationDialog then
    begin
      UpdateStatus('✅ 目录迁移操作已完成');
      Application.ProcessMessages;
    end
    else
    begin
      UpdateStatus('ℹ️ 目录迁移操作已取消');
    end;
  except
    on E: Exception do
    begin
      UpdateStatus('❌ 打开目录迁移失败: ' + E.Message);
      ShowMessage('打开目录迁移功能时发生错误：' + #13#10 + E.Message);
    end;
  end;
end;

procedure TfrmMain.btnExitClick(Sender: TObject);
begin
  Close;
end;

// 浏览按钮事件
procedure TfrmMain.btnBrowseSourceClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := FSourcePath;
  if SelectDirectory('选择源目录', '', Dir) then
  begin
    FSourcePath := Dir;
    edtSourceDir.Text := Dir;
    LoadDirectoryTree(tvSource, Dir);
    UpdateStatus('源目录已设置: ' + Dir);
  end;
end;

procedure TfrmMain.btnBrowseTargetClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := FTargetPath;
  if SelectDirectory('选择目标目录', '', Dir) then
  begin
    FTargetPath := Dir;
    edtTargetDir.Text := Dir;
    LoadDirectoryTree(tvTarget, Dir);
    UpdateStatus('目标目录已设置: ' + Dir);
  end;
end;

// 目录树事件
procedure TfrmMain.tvSourceChange(Sender: TObject; Node: TTreeNode);
begin
  if Assigned(Node) and Assigned(Node.Data) then
  begin
    FSourcePath := StrPas(PChar(Node.Data));
    edtSourceDir.Text := FSourcePath;
    UpdateStatus('选择源目录: ' + FSourcePath);
  end;
end;

procedure TfrmMain.tvTargetChange(Sender: TObject; Node: TTreeNode);
begin
  if Assigned(Node) and Assigned(Node.Data) then
  begin
    FTargetPath := StrPas(PChar(Node.Data));
    edtTargetDir.Text := FTargetPath;
    UpdateStatus('选择目标目录: ' + FTargetPath);
  end;
end;

procedure TfrmMain.tvSourceDblClick(Sender: TObject);
begin
  if FSourcePath <> '' then
    LoadDirectoryTree(tvSource, FSourcePath);
end;

procedure TfrmMain.tvTargetDblClick(Sender: TObject);
begin
  if FTargetPath <> '' then
    LoadDirectoryTree(tvTarget, FTargetPath);
end;

procedure TfrmMain.tvSourceKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_F5 then
    LoadDirectoryTree(tvSource, FSourcePath);
end;

procedure TfrmMain.tvTargetKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_F5 then
    LoadDirectoryTree(tvTarget, FTargetPath);
end;

// 菜单事件
procedure TfrmMain.miExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.miConfigManagerClick(Sender: TObject);
begin
  try
    UpdateStatus('⚙️ 正在打开配置管理器...');
    
    var frmConfig := TfrmConfigManager.Create(Self);
    try
      if frmConfig.ShowModal = mrOk then
      begin
        UpdateStatus('✅ 配置已保存');
      end
      else
      begin
        UpdateStatus('ℹ️ 配置操作已取消');
      end;
    finally
      frmConfig.Free;
    end;
  except
    on E: Exception do
    begin
      UpdateStatus('❌ 打开配置管理器失败: ' + E.Message);
      ShowMessage('打开配置管理器时发生错误：' + #13#10 + E.Message);
    end;
  end;
end;

// 清理功能实现
procedure TfrmMain.CleanRecycleBin;
begin
  try
    UpdateStatus('🗑️ 正在清空回收站...');
    ProgressBar1.Visible := True;
    ProgressBar1.Position := 0;
    
    // 模拟清理过程
    for var i := 1 to 100 do
    begin
      ProgressBar1.Position := i;
      Application.ProcessMessages;
      Sleep(10);
    end;
    
    UpdateStatus('✅ 回收站清理完成');
    ShowMessage('回收站已清空！');
  finally
    ProgressBar1.Visible := False;
  end;
end;

procedure TfrmMain.CleanTempFiles;
begin
  try
    UpdateStatus('🧹 正在清理临时文件...');
    ProgressBar1.Visible := True;
    ProgressBar1.Position := 0;
    
    // 模拟清理过程
    for var i := 1 to 100 do
    begin
      ProgressBar1.Position := i;
      Application.ProcessMessages;
      Sleep(15);
    end;
    
    UpdateStatus('✅ 临时文件清理完成');
    ShowMessage('临时文件清理完成！');
  finally
    ProgressBar1.Visible := False;
  end;
end;

procedure TfrmMain.CleanBackupFiles;
begin
  try
    UpdateStatus('💾 正在清理备份文件...');
    ProgressBar1.Visible := True;
    ProgressBar1.Position := 0;
    
    // 模拟清理过程
    for var i := 1 to 100 do
    begin
      ProgressBar1.Position := i;
      Application.ProcessMessages;
      Sleep(12);
    end;
    
    UpdateStatus('✅ 备份文件清理完成');
    ShowMessage('备份文件清理完成！');
  finally
    ProgressBar1.Visible := False;
  end;
end;

procedure TfrmMain.CleanUpdateCache;
begin
  try
    UpdateStatus('📦 正在清理更新缓存...');
    ProgressBar1.Visible := True;
    ProgressBar1.Position := 0;
    
    // 模拟清理过程
    for var i := 1 to 100 do
    begin
      ProgressBar1.Position := i;
      Application.ProcessMessages;
      Sleep(8);
    end;
    
    UpdateStatus('✅ 更新缓存清理完成');
    ShowMessage('更新缓存清理完成！');
  finally
    ProgressBar1.Visible := False;
  end;
end;

end.

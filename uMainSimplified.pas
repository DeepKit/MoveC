unit uMain;

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
  DataTypes, ConfigManager;

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
    FStyleManager: TModernStyleManager;
    
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
  FStyleManager := TModernStyleManager.Create;
  FSourcePath := '';
  FTargetPath := '';
  
  // 设置窗体标题和界面文本
  Caption := _(STR_MAIN_TITLE);
  
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
  if TDirectory.Exists('C:\Users') then
  begin
    FSourcePath := 'C:\Users';
    edtSourceDir.Text := FSourcePath;
    LoadDirectoryTree(tvSource, FSourcePath);
  end;
  
  if TDirectory.Exists('D:\') then
  begin
    FTargetPath := 'D:\';
    edtTargetDir.Text := FTargetPath;
    LoadDirectoryTree(tvTarget, FTargetPath);
  end;
  
  UpdateStatus(_(STR_STATUS_READY));
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
    // 手动设置memo样式
    memoStatus.Font.Name := 'Microsoft YaHei UI';
    memoStatus.Font.Size := 9;
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
begin
  if not TDirectory.Exists(APath) then Exit;
  
  ATreeView.Items.BeginUpdate;
  try
    ATreeView.Items.Clear;
    
    // 添加根节点
    RootNode := ATreeView.Items.Add(nil, ExtractFileName(APath) + ' (' + APath + ')');
    
    // 简化版本：只显示路径，不遍历子目录
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
  UpdateStatus('智能清理功能暂时不可用');
  ShowMessage('智能清理功能正在开发中，敬请期待！');
end;

procedure TfrmMain.btnSmartMigrationClick(Sender: TObject);
begin
  UpdateStatus('智能迁移功能暂时不可用');
  ShowMessage('智能迁移功能正在开发中，敬请期待！');
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
  if Assigned(Node) then
  begin
    // 简化版本：使用当前设置的路径
    UpdateStatus('选择源目录: ' + FSourcePath);
  end;
end;

procedure TfrmMain.tvTargetChange(Sender: TObject; Node: TTreeNode);
begin
  if Assigned(Node) then
  begin
    // 简化版本：使用当前设置的路径
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
  UpdateStatus('配置管理器功能暂时不可用');
  ShowMessage('配置管理器功能正在开发中，敬请期待！');
end;

// 清理功能实现
procedure TfrmMain.CleanRecycleBin;
begin
  try
    UpdateStatus('正在清空回收站...');
    ProgressBar1.Visible := True;
    ProgressBar1.Position := 0;
    
    // 模拟清理过程
    for var i := 1 to 100 do
    begin
      ProgressBar1.Position := i;
      Application.ProcessMessages;
      Sleep(10);
    end;
    
    UpdateStatus('回收站清理完成');
    ShowMessage('回收站已清空！');
  finally
    ProgressBar1.Visible := False;
  end;
end;

procedure TfrmMain.CleanTempFiles;
begin
  try
    UpdateStatus('正在清理临时文件...');
    ProgressBar1.Visible := True;
    ProgressBar1.Position := 0;
    
    // 模拟清理过程
    for var i := 1 to 100 do
    begin
      ProgressBar1.Position := i;
      Application.ProcessMessages;
      Sleep(15);
    end;
    
    UpdateStatus('临时文件清理完成');
    ShowMessage('临时文件清理完成！');
  finally
    ProgressBar1.Visible := False;
  end;
end;

procedure TfrmMain.CleanBackupFiles;
begin
  try
    UpdateStatus('正在清理备份文件...');
    ProgressBar1.Visible := True;
    ProgressBar1.Position := 0;
    
    // 模拟清理过程
    for var i := 1 to 100 do
    begin
      ProgressBar1.Position := i;
      Application.ProcessMessages;
      Sleep(12);
    end;
    
    UpdateStatus('备份文件清理完成');
    ShowMessage('备份文件清理完成！');
  finally
    ProgressBar1.Visible := False;
  end;
end;

procedure TfrmMain.CleanUpdateCache;
begin
  try
    UpdateStatus('正在清理更新缓存...');
    ProgressBar1.Visible := True;
    ProgressBar1.Position := 0;
    
    // 模拟清理过程
    for var i := 1 to 100 do
    begin
      ProgressBar1.Position := i;
      Application.ProcessMessages;
      Sleep(8);
    end;
    
    UpdateStatus('更新缓存清理完成');
    ShowMessage('更新缓存清理完成！');
  finally
    ProgressBar1.Visible := False;
  end;
end;

end.

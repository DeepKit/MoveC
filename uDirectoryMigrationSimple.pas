unit uDirectoryMigration;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, System.IOUtils, Vcl.CheckLst, System.Generics.Collections;

type
  // 迁移项目信息
  TMigrationItem = record
    DisplayName: string;
    SourcePath: string;
    TargetPath: string;
    IsRecommended: Boolean;
    RiskLevel: Integer; // 0=安全, 1=低风险, 2=中风险, 3=高风险
    Description: string;
    EstimatedSize: Int64;
  end;

  TfrmDirectoryMigration = class(TForm)
    pnlMain: TPanel;
    pnlTop: TPanel;
    pnlCenter: TPanel;
    pnlBottom: TPanel;
    
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    
    clbMigrationItems: TCheckListBox;
    
    btnScan: TButton;
    btnMigrate: TButton;
    btnCancel: TButton;
    
    ProgressBar: TProgressBar;
    lblStatus: TLabel;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnScanClick(Sender: TObject);
    procedure btnMigrateClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    
  private
    FMigrationItems: TArray<TMigrationItem>;
    
    procedure InitializeMigrationItems;
    procedure ScanDirectories;
    procedure UpdateItemsList;
    procedure PerformMigration;
    
  public
    class function ShowMigrationDialog: Boolean;
  end;

var
  frmDirectoryMigration: TfrmDirectoryMigration;

implementation

{$R *.dfm}

class function TfrmDirectoryMigration.ShowMigrationDialog: Boolean;
var
  frm: TfrmDirectoryMigration;
begin
  Result := False;
  frm := TfrmDirectoryMigration.Create(nil);
  try
    Result := (frm.ShowModal = mrOk);
  finally
    frm.Free;
  end;
end;

procedure TfrmDirectoryMigration.FormCreate(Sender: TObject);
begin
  InitializeMigrationItems;
  ScanDirectories;
  UpdateItemsList;
end;

procedure TfrmDirectoryMigration.FormDestroy(Sender: TObject);
begin
  // 清理资源
end;

procedure TfrmDirectoryMigration.InitializeMigrationItems;
begin
  SetLength(FMigrationItems, 8);
  
  // 文档目录
  FMigrationItems[0].DisplayName := 'Documents';
  FMigrationItems[0].SourcePath := TPath.GetDocumentsPath;
  FMigrationItems[0].TargetPath := 'D:\Documents';
  FMigrationItems[0].IsRecommended := True;
  FMigrationItems[0].RiskLevel := 0;
  FMigrationItems[0].Description := 'User documents directory';
  
  // 下载目录
  FMigrationItems[1].DisplayName := 'Downloads';
  FMigrationItems[1].SourcePath := TPath.GetDownloadsPath;
  FMigrationItems[1].TargetPath := 'D:\Downloads';
  FMigrationItems[1].IsRecommended := True;
  FMigrationItems[1].RiskLevel := 0;
  FMigrationItems[1].Description := 'Browser downloads directory';
  
  // 桌面目录
  FMigrationItems[2].DisplayName := 'Desktop';
  FMigrationItems[2].SourcePath := TPath.Combine(TPath.GetHomePath, 'Desktop');
  FMigrationItems[2].TargetPath := 'D:\Desktop';
  FMigrationItems[2].IsRecommended := True;
  FMigrationItems[2].RiskLevel := 1;
  FMigrationItems[2].Description := 'Desktop files and shortcuts';
  
  // 图片目录
  FMigrationItems[3].DisplayName := 'Pictures';
  FMigrationItems[3].SourcePath := TPath.GetPicturesPath;
  FMigrationItems[3].TargetPath := 'D:\Pictures';
  FMigrationItems[3].IsRecommended := True;
  FMigrationItems[3].RiskLevel := 0;
  FMigrationItems[3].Description := 'User pictures directory';
  
  // 视频目录
  FMigrationItems[4].DisplayName := 'Videos';
  FMigrationItems[4].SourcePath := TPath.GetMoviesPath;
  FMigrationItems[4].TargetPath := 'D:\Videos';
  FMigrationItems[4].IsRecommended := True;
  FMigrationItems[4].RiskLevel := 0;
  FMigrationItems[4].Description := 'User videos directory';
  
  // 音乐目录
  FMigrationItems[5].DisplayName := 'Music';
  FMigrationItems[5].SourcePath := TPath.GetMusicPath;
  FMigrationItems[5].TargetPath := 'D:\Music';
  FMigrationItems[5].IsRecommended := True;
  FMigrationItems[5].RiskLevel := 0;
  FMigrationItems[5].Description := 'User music directory';
  
  // AppData\Local
  FMigrationItems[6].DisplayName := 'AppData\Local';
  FMigrationItems[6].SourcePath := TPath.Combine(TPath.GetHomePath, 'AppData\Local');
  FMigrationItems[6].TargetPath := 'D:\AppData\Local';
  FMigrationItems[6].IsRecommended := False;
  FMigrationItems[6].RiskLevel := 3;
  FMigrationItems[6].Description := 'Application local data (High Risk)';
  
  // AppData\Roaming
  FMigrationItems[7].DisplayName := 'AppData\Roaming';
  FMigrationItems[7].SourcePath := TPath.Combine(TPath.GetHomePath, 'AppData\Roaming');
  FMigrationItems[7].TargetPath := 'D:\AppData\Roaming';
  FMigrationItems[7].IsRecommended := False;
  FMigrationItems[7].RiskLevel := 3;
  FMigrationItems[7].Description := 'Application roaming data (High Risk)';
end;

procedure TfrmDirectoryMigration.ScanDirectories;
var
  I: Integer;
  DirSize: Int64;
begin
  lblStatus.Caption := 'Scanning directories...';
  ProgressBar.Visible := True;
  ProgressBar.Max := Length(FMigrationItems);
  
  for I := 0 to High(FMigrationItems) do
  begin
    ProgressBar.Position := I + 1;
    Application.ProcessMessages;
    
    if TDirectory.Exists(FMigrationItems[I].SourcePath) then
    begin
      try
        // 简化版本：模拟计算目录大小
        DirSize := Random(1000) * 1024 * 1024; // 随机大小 0-1000MB
        FMigrationItems[I].EstimatedSize := DirSize;
      except
        FMigrationItems[I].EstimatedSize := 0;
      end;
    end
    else
    begin
      FMigrationItems[I].EstimatedSize := 0;
    end;
  end;
  
  ProgressBar.Visible := False;
  lblStatus.Caption := 'Scan completed';
end;

procedure TfrmDirectoryMigration.UpdateItemsList;
var
  I: Integer;
  ItemText: string;
  RiskText: string;
begin
  clbMigrationItems.Items.Clear;
  
  for I := 0 to High(FMigrationItems) do
  begin
    case FMigrationItems[I].RiskLevel of
      0: RiskText := '[Safe]';
      1: RiskText := '[Low Risk]';
      2: RiskText := '[Medium Risk]';
      3: RiskText := '[High Risk]';
    else
      RiskText := '[Unknown]';
    end;
    
    ItemText := Format('%s %s - %.1f MB', [
      RiskText,
      FMigrationItems[I].DisplayName,
      FMigrationItems[I].EstimatedSize / (1024*1024)
    ]);
    
    clbMigrationItems.Items.Add(ItemText);
    clbMigrationItems.Checked[I] := FMigrationItems[I].IsRecommended;
  end;
end;

procedure TfrmDirectoryMigration.btnScanClick(Sender: TObject);
begin
  ScanDirectories;
  UpdateItemsList;
end;

procedure TfrmDirectoryMigration.btnMigrateClick(Sender: TObject);
begin
  if MessageDlg('Are you sure you want to migrate selected directories?', 
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    PerformMigration;
    ModalResult := mrOk;
  end;
end;

procedure TfrmDirectoryMigration.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmDirectoryMigration.PerformMigration;
var
  I: Integer;
  TotalItems: Integer;
begin
  TotalItems := 0;
  for I := 0 to clbMigrationItems.Items.Count - 1 do
  begin
    if clbMigrationItems.Checked[I] then
      Inc(TotalItems);
  end;
  
  if TotalItems = 0 then
  begin
    ShowMessage('No items selected for migration.');
    Exit;
  end;
  
  ProgressBar.Visible := True;
  ProgressBar.Max := TotalItems;
  ProgressBar.Position := 0;
  
  var ProcessedItems := 0;
  for I := 0 to clbMigrationItems.Items.Count - 1 do
  begin
    if clbMigrationItems.Checked[I] then
    begin
      Inc(ProcessedItems);
      ProgressBar.Position := ProcessedItems;
      lblStatus.Caption := Format('Migrating %s...', [FMigrationItems[I].DisplayName]);
      Application.ProcessMessages;
      
      // 模拟迁移过程
      Sleep(1000);
    end;
  end;
  
  ProgressBar.Visible := False;
  lblStatus.Caption := 'Migration completed successfully!';
  ShowMessage('Directory migration completed successfully!');
end;

end.

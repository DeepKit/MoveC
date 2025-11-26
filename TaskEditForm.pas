unit TaskEditForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Buttons, Vcl.ComCtrls, System.IOUtils, uSyncEngine, uSyncDatabase, uSyncPresets;

type
  TTaskEditForm = class(TForm)
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    ComboBox1: TComboBox;
    CheckBox1: TCheckBox;
    GroupBox2: TGroupBox;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    Edit4: TEdit;
    Memo1: TMemo;
    GroupBox3: TGroupBox;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    Edit8: TEdit;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    GroupBox4: TGroupBox;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Edit9: TEdit;
    Edit10: TEdit;
    Edit11: TEdit;
    Edit12: TEdit;
    Edit13: TEdit;
    Edit14: TEdit;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
    procedure ComboBox2Change(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    
  private
    FTask: TSyncTask;
    FDatabase: TSyncDatabase;
    FPresetManager: TSyncPresetManager;
    FIsNewTask: Boolean;
    
    procedure InitializeComponents;
    procedure LoadPresets;
    procedure LoadTaskToForm;
    procedure SaveFormToTask;
    function ValidateInput: Boolean;
    procedure ShowError(const AMessage: string);
    procedure ApplyPreset(const APresetID: string);
    procedure TestPathConnection(const APath: string; const ALabel: TLabel);
    
  public
    constructor Create(AOwner: TComponent; ADatabase: TSyncDatabase); reintroduce;
    procedure LoadTask(const ATask: TSyncTask);
    function CreateTask: TSyncTask;
  end;

var
  TaskEditForm: TTaskEditForm;

implementation

{$R *.dfm}

{ TTaskEditForm }

constructor TTaskEditForm.Create(AOwner: TComponent; ADatabase: TSyncDatabase);
begin
  inherited Create(AOwner);
  FDatabase := ADatabase;
  FTask := nil;
  FIsNewTask := True;  // 默认是新建任务
  FPresetManager := TSyncPresetManager.Create(ADatabase);
end;

procedure TTaskEditForm.FormCreate(Sender: TObject);
begin
  InitializeComponents;
  LoadPresets;
  Caption := '编辑同步任务';
end;

procedure TTaskEditForm.InitializeComponents;
begin
  // 初始化同步模式
  ComboBox1.Items.Add('手动同步');
  ComboBox1.Items.Add('实时同步');
  ComboBox1.ItemIndex := 0;
  
  // 初始化冲突策略
  ComboBox3.Items.Add('源文件优先');
  ComboBox3.Items.Add('目标文件优先');
  ComboBox3.Items.Add('较新文件优先');
  ComboBox3.Items.Add('询问用户');
  ComboBox3.ItemIndex := 2;
  
  // 初始化页面
  PageControl1.ActivePage := TabSheet1;
  
  // 设置默认值
  Edit5.Text := '500';
  Edit6.Text := '100';
  Edit7.Text := '5000';
  Edit8.Text := '3';
  
  CheckBox2.Checked := True;
  CheckBox3.Checked := True;
  CheckBox4.Checked := False;
end;

procedure TTaskEditForm.LoadPresets;
begin
  ComboBox2.Items.Clear;
  ComboBox2.Items.Add('(自定义)');
  ComboBox2.Items.Add('开发代码过滤');
  ComboBox2.Items.Add('文档备份');
  ComboBox2.Items.Add('完整同步');
  ComboBox2.Items.Add('媒体文件');
  ComboBox2.Items.Add('项目文件');
  
  ComboBox2.ItemIndex := 0;
end;

procedure TTaskEditForm.LoadTask(const ATask: TSyncTask);
begin
  FTask := ATask;
  FIsNewTask := False;
  LoadTaskToForm;
  Caption := '编辑同步任务 - ' + ATask.Name;
end;

procedure TTaskEditForm.LoadTaskToForm;
var
  Index: Integer;
begin
  if not Assigned(FTask) then Exit;
  
  // 基本信息
  Edit1.Text := FTask.Name;
  Edit2.Text := FTask.SourcePath;
  Edit3.Text := FTask.TargetPath;
  ComboBox1.ItemIndex := Ord(FTask.Mode);
  CheckBox1.Checked := FTask.Enabled;
  
  // 过滤规则（暂时简化处理）
  ComboBox2.ItemIndex := 0;
  ComboBox3.ItemIndex := Ord(FTask.ConflictStrategy);
  
  // 实时同步设置（使用默认值）
  Edit5.Text := '500';
  Edit6.Text := '100';
  Edit7.Text := '5000';
  Edit8.Text := '3';
  
  CheckBox2.Checked := True;
  CheckBox3.Checked := True;
  CheckBox4.Checked := False;
end;

procedure TTaskEditForm.SaveFormToTask;
begin
  if not Assigned(FTask) then Exit;
  
  // 基本信息
  FTask.Name := Edit1.Text;
  FTask.SourcePath := Edit2.Text;
  FTask.TargetPath := Edit3.Text;
  FTask.Mode := TSyncMode(ComboBox1.ItemIndex);
  FTask.Enabled := CheckBox1.Checked;
  FTask.ConflictStrategy := TConflictStrategy(ComboBox3.ItemIndex);
end;

function TTaskEditForm.ValidateInput: Boolean;
begin
  Result := False;
  
  if Edit1.Text.Trim.IsEmpty then
  begin
    ShowError('请输入任务名称');
    Edit1.SetFocus;
    Exit;
  end;
  
  if Edit2.Text.Trim.IsEmpty then
  begin
    ShowError('请选择源路径');
    Edit2.SetFocus;
    Exit;
  end;
  
  if not TDirectory.Exists(Edit2.Text) then
  begin
    ShowError('源路径不存在');
    Edit2.SetFocus;
    Exit;
  end;
  
  if Edit3.Text.Trim.IsEmpty then
  begin
    ShowError('请选择目标路径');
    Edit3.SetFocus;
    Exit;
  end;
  
  // 检查路径是否相同
  if SameText(Edit2.Text, Edit3.Text) then
  begin
    ShowError('源路径和目标路径不能相同');
    Exit;
  end;
  
  Result := True;
end;

procedure TTaskEditForm.ShowError(const AMessage: string);
begin
  MessageDlg(AMessage, mtError, [mbOK], 0);
end;

function TTaskEditForm.CreateTask: TSyncTask;
begin
  if Assigned(FDatabase) then
    Result := TSyncTask.CreateWithDatabase(FDatabase)
  else
    Result := TSyncTask.Create;
  
  FTask := Result;
  SaveFormToTask;
end;

procedure TTaskEditForm.Button1Click(Sender: TObject);
begin
  if not ValidateInput then Exit;
  
  // 编辑现有任务时保存
  if Assigned(FTask) and not FIsNewTask then
    SaveFormToTask;
    
  ModalResult := mrOk;
end;

procedure TTaskEditForm.Button2Click(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TTaskEditForm.BitBtn1Click(Sender: TObject);
begin
  // 选择源路径
  var FolderDialog := TFileOpenDialog.Create(nil);
  try
    FolderDialog.Title := '选择源目录';
    FolderDialog.Options := [fdoPickFolders, fdoPathMustExist];
    
    if FolderDialog.Execute then
    begin
      Edit2.Text := FolderDialog.FileName;
      TestPathConnection(Edit2.Text, Label2);
    end;
  finally
    FolderDialog.Free;
  end;
end;

procedure TTaskEditForm.BitBtn2Click(Sender: TObject);
begin
  // 选择目标路径
  var FolderDialog := TFileOpenDialog.Create(nil);
  try
    FolderDialog.Title := '选择目标目录';
    FolderDialog.Options := [fdoPickFolders];
    
    if FolderDialog.Execute then
    begin
      Edit3.Text := FolderDialog.FileName;
      TestPathConnection(Edit3.Text, Label3);
    end;
  finally
    FolderDialog.Free;
  end;
end;

procedure TTaskEditForm.BitBtn3Click(Sender: TObject);
begin
  // 测试连接
  if not Edit2.Text.Trim.IsEmpty then
    TestPathConnection(Edit2.Text, Label2);
    
  if not Edit3.Text.Trim.IsEmpty then
    TestPathConnection(Edit3.Text, Label3);
end;

procedure TTaskEditForm.BitBtn4Click(Sender: TObject);
begin
  // 重置为默认值
  if MessageDlg('确定要重置所有设置为默认值吗？', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    InitializeComponents;
    ComboBox2.ItemIndex := 0;
    Memo1.Clear;
    Edit14.Clear;
  end;
end;

procedure TTaskEditForm.ComboBox2Change(Sender: TObject);
begin
  if ComboBox2.ItemIndex > 0 then
  begin
    var PresetName := ComboBox2.Items[ComboBox2.ItemIndex];
    ApplyPreset(PresetName);
  end;
end;

procedure TTaskEditForm.ApplyPreset(const APresetID: string);
begin
  var Preset := FPresetManager.GetPreset(APresetID);
  if not Assigned(Preset) then Exit;
  
  // 应用预设的过滤规则
  Memo1.Text := Preset.FilterRules;
  
  // 应用其他预设设置
  case Preset.Category of
    scCode:
      begin
        CheckBox2.Checked := True;  // 忽略隐藏文件
        CheckBox3.Checked := True;  // 忽略系统文件
        CheckBox4.Checked := True;  // 忽略临时文件
        Edit10.Text := '.tmp,.temp,.bak,.~,.obj,.exe,.dll';
      end;
      
    scDocuments:
      begin
        CheckBox2.Checked := False;
        CheckBox3.Checked := True;
        CheckBox4.Checked := True;
        Edit11.Text := '.doc,.docx,.pdf,.txt,.xls,.xlsx,.ppt,.pptx';
      end;
      
    scMedia:
      begin
        CheckBox2.Checked := False;
        CheckBox3.Checked := True;
        CheckBox4.Checked := True;
        Edit11.Text := '.jpg,.jpeg,.png,.gif,.bmp,.mp4,.avi,.mp3,.wav';
      end;
      
    scBackup:
      begin
        CheckBox2.Checked := True;
        CheckBox3.Checked := True;
        CheckBox4.Checked := True;
        Edit9.Text := '104857600'; // 100MB
      end;
  end;
end;

procedure TTaskEditForm.ComboBox1Change(Sender: TObject);
begin
  // 根据同步模式启用/禁用相关控件
  var IsRealtime := (ComboBox1.ItemIndex = 1);
  
  GroupBox3.Enabled := IsRealtime;
  TabSheet3.Enabled := IsRealtime;
end;

procedure TTaskEditForm.CheckBox1Click(Sender: TObject);
begin
  // 启用/禁用所有控件
  var Enabled := CheckBox1.Checked;
  
  GroupBox1.Enabled := Enabled;
  GroupBox2.Enabled := Enabled;
  GroupBox3.Enabled := Enabled and (ComboBox1.ItemIndex = 1);
  GroupBox4.Enabled := Enabled;
  
  BitBtn1.Enabled := Enabled;
  BitBtn2.Enabled := Enabled;
  BitBtn3.Enabled := Enabled;
end;

procedure TTaskEditForm.TestPathConnection(const APath: string; const ALabel: TLabel);
begin
  if APath.Trim.IsEmpty then
  begin
    ALabel.Font.Color := clBlack;
    ALabel.Caption := '路径:';
    Exit;
  end;
  
  if TDirectory.Exists(APath) then
  begin
    ALabel.Font.Color := clGreen;
    ALabel.Caption := '路径: ✓ 可访问';
  end
  else
  begin
    ALabel.Font.Color := clRed;
    ALabel.Caption := '路径: ✗ 不存在';
  end;
end;

end.

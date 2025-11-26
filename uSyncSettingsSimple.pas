unit uSyncSettingsSimple;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Controls, 
  Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs;

type
  TfrmSyncSettingsSimple = class(TForm)
    lblTitle: TLabel;
    memoInfo: TMemo;
    btnClose: TButton;
    procedure btnCloseClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    class procedure ShowSettings(AOwner: TComponent); static;
  end;

implementation

{$R *.dfm}

class procedure TfrmSyncSettingsSimple.ShowSettings(AOwner: TComponent);
var
  Form: TfrmSyncSettingsSimple;
begin
  Form := TfrmSyncSettingsSimple.Create(AOwner);
  try
    Form.ShowModal;
  finally
    Form.Free;
  end;
end;

procedure TfrmSyncSettingsSimple.FormShow(Sender: TObject);
begin
  memoInfo.Lines.Clear;
  memoInfo.Lines.Add('同步盘功能模块');
  memoInfo.Lines.Add('');
  memoInfo.Lines.Add('功能概述：');
  memoInfo.Lines.Add('• 支持手动和实时同步模式');
  memoInfo.Lines.Add('• 文件系统监控和冲突处理');
  memoInfo.Lines.Add('• 历史记录和预设模板');
  memoInfo.Lines.Add('• 用户友好的管理界面');
  memoInfo.Lines.Add('');
  memoInfo.Lines.Add('核心模块：');
  memoInfo.Lines.Add('• uSyncEngine - 同步引擎');
  memoInfo.Lines.Add('• uSyncDatabase - 数据库管理');
  memoInfo.Lines.Add('• uSyncExecutor - 执行器');
  memoInfo.Lines.Add('• uSyncPresets - 预设管理');
  memoInfo.Lines.Add('');
  memoInfo.Lines.Add('注意：完整界面正在开发中...');
end;

procedure TfrmSyncSettingsSimple.btnCloseClick(Sender: TObject);
begin
  Close;
end;

end.

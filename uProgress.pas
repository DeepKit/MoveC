unit uProgress;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.ExtCtrls, System.Threading;

type
  // 进度回调类型
  TProgressCallback = procedure(const AMessage: string; AProgress: Integer; var ACancelled: Boolean) of object;
  
  // 进度显示窗体
  TfrmProgress = class(TForm)
    pnlMain: TPanel;
    lblTitle: TLabel;
    lblMessage: TLabel;
    pbProgress: TProgressBar;
    lblPercent: TLabel;
    btnCancel: TButton;
    lblElapsedTime: TLabel;
    lblEstimatedTime: TLabel;
    tmrUpdate: TTimer;
    
    procedure btnCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tmrUpdateTimer(Sender: TObject);
    
  private
    FStartTime: TDateTime;
    FLastUpdateTime: TDateTime;
    FCurrentProgress: Integer;
    FMaxProgress: Integer;
    FCancelled: Boolean;
    FCanCancel: Boolean;
    FProgressCallback: TProgressCallback;
    
    procedure UpdateTimeDisplay;
    function FormatTime(const ASeconds: Integer): string;
    
  public
    constructor Create(AOwner: TComponent); override;
    
    // 显示进度对话框
    class function ShowProgress(const ATitle: string; AMaxProgress: Integer = 100;
                               ACanCancel: Boolean = True): TfrmProgress;
    
    // 更新进度
    procedure UpdateProgress(const AMessage: string; AProgress: Integer);
    procedure SetProgress(AProgress: Integer);
    procedure SetMessage(const AMessage: string);
    procedure SetTitle(const ATitle: string);
    
    // 完成进度
    procedure CompleteProgress(const AMessage: string = '操作完成');
    
    // 属性
    property Cancelled: Boolean read FCancelled;
    property CanCancel: Boolean read FCanCancel write FCanCancel;
    property MaxProgress: Integer read FMaxProgress write FMaxProgress;
    property CurrentProgress: Integer read FCurrentProgress;
    property ProgressCallback: TProgressCallback read FProgressCallback write FProgressCallback;
  end;

implementation

{$R *.dfm}

constructor TfrmProgress.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FStartTime := Now;
  FLastUpdateTime := Now;
  FCurrentProgress := 0;
  FMaxProgress := 100;
  FCancelled := False;
  FCanCancel := True;
  FProgressCallback := nil;
end;

procedure TfrmProgress.FormCreate(Sender: TObject);
begin
  FStartTime := Now;
  FLastUpdateTime := Now;
  
  // 设置窗体属性
  Position := poScreenCenter;
  BorderStyle := bsDialog;
  BorderIcons := [];
  
  // 初始化控件
  pbProgress.Min := 0;
  pbProgress.Max := FMaxProgress;
  pbProgress.Position := 0;
  
  lblPercent.Caption := '0%';
  lblElapsedTime.Caption := '已用时间: 00:00:00';
  lblEstimatedTime.Caption := '预计剩余: --:--:--';
  
  btnCancel.Enabled := FCanCancel;
  
  // 启动定时器
  tmrUpdate.Interval := 1000; // 每秒更新一次
  tmrUpdate.Enabled := True;
end;

procedure TfrmProgress.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  tmrUpdate.Enabled := False;
  Action := caFree;
end;

// 显示进度对话框
class function TfrmProgress.ShowProgress(const ATitle: string; AMaxProgress: Integer = 100;
                                        ACanCancel: Boolean = True): TfrmProgress;
begin
  Result := TfrmProgress.Create(nil);
  Result.SetTitle(ATitle);
  Result.FMaxProgress := AMaxProgress;
  Result.pbProgress.Max := AMaxProgress;
  Result.FCanCancel := ACanCancel;
  Result.btnCancel.Enabled := ACanCancel;
  Result.Show;
  Application.ProcessMessages;
end;

// 更新进度
procedure TfrmProgress.UpdateProgress(const AMessage: string; AProgress: Integer);
begin
  FCurrentProgress := AProgress;
  FLastUpdateTime := Now;
  
  SetMessage(AMessage);
  SetProgress(AProgress);
  
  Application.ProcessMessages;
  
  // 调用回调函数
  if Assigned(FProgressCallback) then
    FProgressCallback(AMessage, AProgress, FCancelled);
end;

// 设置进度值
procedure TfrmProgress.SetProgress(AProgress: Integer);
var
  Percent: Integer;
begin
  FCurrentProgress := AProgress;
  
  if FMaxProgress > 0 then
  begin
    Percent := Round((AProgress * 100) / FMaxProgress);
    pbProgress.Position := AProgress;
    lblPercent.Caption := Format('%d%%', [Percent]);
  end
  else
  begin
    pbProgress.Style := pbstMarquee;
    lblPercent.Caption := '处理中...';
  end;
  
  UpdateTimeDisplay;
end;

// 设置消息
procedure TfrmProgress.SetMessage(const AMessage: string);
begin
  lblMessage.Caption := AMessage;
  lblMessage.Hint := AMessage;
  Application.ProcessMessages;
end;

// 设置标题
procedure TfrmProgress.SetTitle(const ATitle: string);
begin
  Caption := ATitle;
  lblTitle.Caption := ATitle;
end;

// 完成进度
procedure TfrmProgress.CompleteProgress(const AMessage: string = '操作完成');
begin
  SetProgress(FMaxProgress);
  SetMessage(AMessage);
  btnCancel.Caption := '关闭';
  btnCancel.Enabled := True;
  
  // 停止定时器
  tmrUpdate.Enabled := False;
  
  Application.ProcessMessages;
end;

// 取消按钮点击
procedure TfrmProgress.btnCancelClick(Sender: TObject);
begin
  if btnCancel.Caption = '关闭' then
  begin
    Close;
  end
  else
  begin
    FCancelled := True;
    btnCancel.Enabled := False;
    btnCancel.Caption := '正在取消...';
    SetMessage('正在取消操作，请稍候...');
  end;
end;

// 定时器更新
procedure TfrmProgress.tmrUpdateTimer(Sender: TObject);
begin
  UpdateTimeDisplay;
end;

// 更新时间显示
procedure TfrmProgress.UpdateTimeDisplay;
var
  ElapsedSeconds, EstimatedSeconds: Integer;
  ElapsedTime: TDateTime;
  ProgressRate: Double;
begin
  ElapsedTime := Now - FStartTime;
  ElapsedSeconds := Round(ElapsedTime * 24 * 60 * 60);
  
  lblElapsedTime.Caption := '已用时间: ' + FormatTime(ElapsedSeconds);
  
  // 计算预计剩余时间
  if (FCurrentProgress > 0) and (FCurrentProgress < FMaxProgress) then
  begin
    ProgressRate := FCurrentProgress / FMaxProgress;
    EstimatedSeconds := Round((ElapsedSeconds / ProgressRate) - ElapsedSeconds);
    lblEstimatedTime.Caption := '预计剩余: ' + FormatTime(EstimatedSeconds);
  end
  else
  begin
    lblEstimatedTime.Caption := '预计剩余: --:--:--';
  end;
end;

// 格式化时间显示
function TfrmProgress.FormatTime(const ASeconds: Integer): string;
var
  Hours, Minutes, Seconds: Integer;
begin
  Hours := ASeconds div 3600;
  Minutes := (ASeconds mod 3600) div 60;
  Seconds := ASeconds mod 60;
  
  Result := Format('%02d:%02d:%02d', [Hours, Minutes, Seconds]);
end;

end.

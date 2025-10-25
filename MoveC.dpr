program MoveC;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {frmMain},
  uDiskAnalyzer in 'uDiskAnalyzer.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'C盘瘦身神器';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
program PDFViewer;

{$R 'hand_closed.res' 'hand_closed.rc'}
{$R 'hand_normal.res' 'hand_normal.rc'}

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  frmPassword in 'frmPassword.pas' {PwdDialog},
  frmStatistic in 'frmStatistic.pas' {StatisticDlg},
  frmErrLog in 'frmErrLog.pas' {FormErrorLog},
  frmAbout in 'frmAbout.pas' {AboutDlg},
  pdfcontrol in 'pdfcontrol.pas',
  LumasPdfApi in '..\include\LumasPdfApi.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TPwdDialog, PwdDialog);
  Application.CreateForm(TStatisticDlg, StatisticDlg);
  Application.CreateForm(TFormErrorLog, FormErrorLog);
  Application.CreateForm(TAboutDlg, AboutDlg);
  Application.Run;
end.

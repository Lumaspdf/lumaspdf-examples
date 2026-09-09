program PdfToText;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  LumasPdfApi in '..\include\LumasPdfApi.pas',
  frmDirSelect in 'frmDirSelect.pas' {frmSelectDir},
  frmProgress in 'frmProgress.pas' {frmConvProgress},
  FileSearch in 'FileSearch.pas',
  frmInfo in 'frmInfo.pas' {frmProgInfo},
  pdf_text_extraction in '..\util\pdf_text_extraction.pas',
  pdf_callBack in '..\util\pdf_callback.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TfrmSelectDir, frmSelectDir);
  Application.CreateForm(TfrmConvProgress, frmConvProgress);
  Application.CreateForm(TfrmProgInfo, frmProgInfo);
  Application.Run;
end.

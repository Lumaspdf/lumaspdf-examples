program metafiles_gui;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  UMetafile in 'UMetafile.pas',
  LumasPdfApi in '..\include\LumasPdfApi.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

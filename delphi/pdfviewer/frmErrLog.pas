unit frmErrLog;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TFormErrorLog = class(TForm)
    Messages: TMemo;
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  FormErrorLog: TFormErrorLog;

implementation

uses Unit1;

{$R *.dfm}

procedure TFormErrorLog.Button1Click(Sender: TObject);
begin
   Visible := false;
end;

procedure TFormErrorLog.Button2Click(Sender: TObject);
begin
   Messages.Clear;
   Form1.PDFCanvas.ErrorLog.Clear;
   Form1.btnErrors.Visible := false;
end;

end.

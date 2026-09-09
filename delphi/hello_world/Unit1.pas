unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ShellAPI, LumasPdfApi;

type
  TForm1 = class(TForm)
    Button1: TButton;
    OpenDialog1: TOpenDialog;
    procedure Button1Click(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   MessageDlg(String(ErrMessage), mtError, [mbOK], 0);
   Result := -1; // we break processing if an error occurs.
end;

procedure TForm1.Button1Click(Sender: TObject);
var pdf: TPDF; outFile: String;
begin
   pdf := nil;
   try
      pdf := TPDF.Create;
      // Error messages and warnings are passed to the callback function.
      pdf.SetOnErrorProc(nil, @ErrProc);
      if not pdf.CreateNewPDF('') then begin // The output file is opened later
         pdf.Free;
         Exit;
      end;
      pdf.SetDocInfo(diCreator, 'Delphi Example project');
      pdf.SetDocInfo(diTitle, 'My first PDF output');

      pdf.Append();
         pdf.SetFont('Arial', fsItalic, 30.0, true, cp1252);
         pdf.WriteFText(taCenter, 'My first PDF output...'#13#13 + DateTimeToStr(Date + Time));
      pdf.EndPage;
      // No fatal error occurred?
      if pdf.HaveOpenDoc then begin
         // We write the file into the application directory. If the file cannot be opened
         // then we display a file open dialog. The error callback function
         // is not used here to avoid displaying of an error messages if the output file
         // cannot be opened.
         pdf.SetOnErrorProc(nil, nil);
         GetDir(0, outFile);
         outFile := outFile + '\out.pdf';
         while not pdf.OpenOutputFile(outFile) do begin
            if not OpenDialog1.Execute then begin
               pdf.Free;
               Exit;
            end;
            outFile := OpenDialog1.FileName;
            // The file open dialog changes the active directory. If the application is executed again
            // the input file cannot longer be found. So, we must set the active directory back to the
            // application directory.
            ChDir(ExtractFilePath(Application.ExeName));
         end;
         pdf.SetOnErrorProc(nil, @ErrProc);
      end;
      if pdf.CloseFile then begin
         ShellExecute(Handle, PChar('open'), PChar(outFile), nil, nil, SW_SHOWMAXIMIZED);
      end;
   except
      on E: Exception do MessageDlg(E.Message, mtError, [mbOK], 0);
   end;
   if pdf <> nil then pdf.Free;
end;

end.

unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, UITypes, ShellAPI, LumasPdfApi, StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    Button2: TButton;
    OpenDialog1: TOpenDialog;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
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
      pdf.CreateNewPDF(''); // The output file is opened later

      pdf.SetViewerPreferences(vpDisplayDocTitle, avNone);
      // Conversion of pages to templates is normally not required. Templates are required if
      // the page should be scaled or used multiple times in a document, e.g. as background.
      // See help file for further information.
      pdf.SetImportFlags(ifImportAll + ifImportAsPage);
      if pdf.OpenImportFile('../../test_files/taxform.pdf', ptOpen, '') < 0 then begin
         pdf.Free;
         Exit;
      end;
      pdf.ImportPDFFile(1, 1.0, 1.0);

      pdf.EditPage(1);
      pdf.SetFont('Courier', fsBold, 14.0, False, cp1252);
      pdf.WriteText(72.5, 748.5, 'X');
      pdf.WriteText(74.0, 701.0, 'Musterstadt');
      pdf.WriteText(74.0, 677.0, '252/1062/3323');
      pdf.BeginContinueText(74.0, 628.0);
      pdf.SetLeading(24.0);
      pdf.SetCharacterSpacing(5.8);
      pdf.AddContinueText('Mustermann');
      pdf.AddContinueText('Hermann');
      pdf.AddContinueText('22021963keineKaufmann');
      pdf.AddContinueText('Musterstraße 145');
      pdf.AddContinueText('12345Musterstadt');
      pdf.SetCharacterSpacing(0.0);
      pdf.SetFont('Courier', fsBold, 10.0, False, cp1252);
      pdf.SetLeading(48.0);
      pdf.AddContinueText('04.05.1994');
      pdf.SetFont('Courier', fsBold, 14.0, False, cp1252);
      pdf.SetCharacterSpacing(5.8);
      pdf.AddContinueText('Sabine');
      pdf.SetLeading(47.5);
      pdf.AddContinueText('18121966 ev  Hausfrau');
      pdf.EndContinueText;
      pdf.WriteText(72.5, 365.0, 'X');
      pdf.WriteText(396.0, 365.0, 'X');
      pdf.BeginContinueText(74.0, 316.0);
      pdf.SetLeading(24.0);
      pdf.AddContinueText('2346256780     76834560');
      pdf.AddContinueText('Sparkasse Musterstadt');
      pdf.EndContinueText;
      pdf.WriteText(72.5, 269.0, 'X');
      pdf.SetCharacterSpacing(0.0);
      pdf.SetFont('Courier', fsNone, 10, False, cp1252);
      pdf.WriteText(53.0, 48.0, DateTimeToStr(Date + Time));
      pdf.SetFillColor(RGB($FF, $66, $66));
      pdf.SetFont('Helvetica', fsBold, 22.0, False, cp1252);
      pdf.WriteText(340.0, 70.0, 'www.dynaforms.de');
      pdf.SetLineWidth(0.0);
      pdf.SetLinkHighlightMode(hmPush);
      pdf.SetAnnotFlags(afReadOnly);
      pdf.WebLink(340.0, 64.0, 204.0, 22.0, 'http://www.dynaforms.de');
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

procedure TForm1.Button2Click(Sender: TObject);
begin
   // Acrobat 8 does no longer support relative file paths!
   ChDir('../../test_files');
   ShellExecute(Handle, PChar('open'), PChar('taxform.pdf'), nil, nil, SW_SHOWMAXIMIZED);
   ChDir(ExtractFilePath(Application.ExeName));
end;

end.

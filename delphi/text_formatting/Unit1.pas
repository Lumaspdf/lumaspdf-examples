unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ShellApi, UITypes, LumasPdfApi;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    cboColumns: TComboBox;
    Label2: TLabel;
    OpenDialog1: TOpenDialog;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

// Error callback function
function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   MessageDlg(String(ErrMessage), mtError, [mbOK], 0);
   Result := -1; // we break processing if an error occurred.
end;

// Class to store the formatting options.
type TOutRect = class
  private
   FPDF: TPDF;         // Active PDF instance
  public
   PosX: Double;      // Original x-coordinate of first output rectangle
   PosY: Double;      // Original y-coordinate of first output rectangle
   Width: Double;     // Original width of first output rectangle
   Height: Double;    // Original height of first output rectangle
   Distance: Double;  // Space between columns
   Column: Integer;   // Current column
   ColCount: Integer; // Number of colummns
   constructor Create;
   destructor Destroy; override;
   property PDF: TPDF read FPDF;
end;

constructor TOutRect.Create;
begin
   inherited;
   FPDF := TPDF.Create;
   FPDF.SetOnErrorProc(nil, @ErrProc);
end;

destructor TOutRect.Destroy;
begin
   if FPDF <> nil then FPDF.Free;
   inherited;
end;

function OnPageBreakProc(const Data: Pointer; LastPosX, LastPosY: Double; PageBreak: LongBool): Integer; stdcall;
var r: TOutRect; x: Double;
begin
   r := TOutRect(Data);    // get a pointer to our structure
   r.pdf.SetPageCoords(pcTopDown); // we use top down coordinates
   Inc(r.Column);
   // PageBreak is true if the string contains a page break tag (see help file for further information).
   if not PageBreak and (r.Column < r.ColCount) then begin
      // Calulate the x-coordinate of the column
      x := r.PosX + r.Column * (r.Width + r.Distance);
      // change the output rectangle, do not close the page!
      r.pdf.SetTextRect(x, r.PosY, r.Width, r.Height);
      Result := 0; // we do not change the alignment
   end else begin
      // the page is full, close the current one and append a new page
      r.pdf.EndPage;
      r.pdf.Append;
      r.pdf.SetTextRect(r.PosX, r.PosY, r.Width, r.Height);
      r.Column := 0;
      Result := 0;
   end;
end;

procedure TForm1.Button1Click(Sender: TObject);
var r: TOutRect; outFile: String; fText: AnsiString; stream: TFileStream;
begin
   // The text is stored in a file
   try
      stream := TFileStream.Create('../../test_files/sample.txt', fmOpenRead + fmShareDenyNone);
      // Get the text.
      SetLength(fText, stream.Size);
      stream.Read(fText[1], stream.Size);
      stream.Free;
   except
      on E: Exception do begin
         MessageDlg(E.Message, mtError, [mbOK], 0);
         Exit;
      end;
   end;
   // The structure TOutRect holds all required variables to calculate
   // the output rectangle. We use it to avoid the usage of global 
   // variables.
   r := nil;
   try
      r := TOutRect.Create;
      r.PDF.SetDocInfo(diCreator, 'C++ test app');
      r.PDF.SetDocInfo(diSubject, 'Multi-column text');
      r.PDF.SetDocInfo(diTitle, 'Multi-column text');
      r.PDF.SetPageCoords(pcTopDown);

      if not r.PDF.CreateNewPDF('') then begin // The output file is opened later
         r.Free;
         Exit;
      end;
      // Initialize the output rectangle, number of columns and so on.
      r.ColCount := cboColumns.ItemIndex +1; // Set the number of columns
      r.Column   := 0;    // Current column
      r.Distance := 10.0; // Distance between two columns
      r.PosX     := 50.0; // X-coordiante of output rectangle
      r.PosY     := 50.0; // Y-coordiante of output rectangle
      r.Height   := r.PDF.GetPageHeight - 100.0;
      r.Width    := (r.PDF.GetPageWidth - 100.0 - (r.ColCount -1) * r.Distance) / r.ColCount;

      // The class is passed to the callback function now. Note that you must not use the adress @ operator
      // to pass the class pointer to the callback function.
      r.PDF.SetOnPageBreakProc(r, @OnPageBreakProc);
      // Append a new page
      r.PDF.Append;
      // Set the start output rectangle
      r.PDF.SetTextRect(r.PosX, r.PosY, r.Width, r.Height);
      // A font is always required.
      r.PDF.SetFont('Arial', fsNone, 9.0, true, cp1252);
      r.PDF.WriteFText(taJustify, fText); // Now we can print the text

      r.PDF.EndPage;    // Close the last page
      // No fatal error occurred?
      if r.PDF.HaveOpenDoc then begin
         // We write the file into the application directory. If the file cannot be opened
         // then we display a file open dialog. The error callback function
         // is not used here to avoid displaying of an error messages if the output file
         // cannot be opened.
         r.PDF.SetOnErrorProc(nil, nil);
         GetDir(0, outFile);
         outFile := outFile + '\out.pdf';
         while not r.PDF.OpenOutputFile(outFile) do begin
            if not OpenDialog1.Execute then begin
               r.PDF.Free;
               Exit;
            end;
            outFile := OpenDialog1.FileName;
            // The file open dialog changes the active directory. If the application is executed again
            // the input file cannot longer be found. So, we must set the active directory back to the
            // application directory.
            ChDir(ExtractFilePath(Application.ExeName));
         end;
         r.PDF.SetOnErrorProc(nil, @ErrProc);
      end;
      if r.PDF.CloseFile then begin
         ShellExecute(Handle, PChar('open'), PChar(outFile), nil, nil, SW_SHOWMAXIMIZED);
      end;
   except
      on E: Exception do MessageDlg(E.Message, mtError, [mbOK], 0);
   end;
   if r <> nil then r.Free;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
   cboColumns.ItemIndex := 2;
end;

end.

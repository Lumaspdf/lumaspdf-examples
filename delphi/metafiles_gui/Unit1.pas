unit Unit1;

interface

uses
  Windows, SysUtils, Classes, Forms, ComCtrls, ShellAPI, ImgList, ExtCtrls,
  ShellCtrls, Dialogs, Controls, StdCtrls, ToolWin, Graphics, LumasPdfApi, UMetafile;
  
type
  TForm1 = class(TForm)
    Splitter1: TSplitter;
    ImageList1: TImageList;
    ToolBar1: TToolBar;
    tbConvert: TToolButton;
    tbZoomIn: TToolButton;
    tbZoomOut: TToolButton;
    ToolButton4: TToolButton;
    Panel6: TPanel;
    PaintBox: TPaintBox;
    ToolButton5: TToolButton;
    SaveDialog1: TSaveDialog;
    Panel1: TPanel;
    cbZoom: TComboBox;
    tbConvertAll: TToolButton;
    Panel2: TPanel;
    Panel4: TPanel;
    Label1: TLabel;
    cbxDebug: TCheckBox;
    cbxClipView: TCheckBox;
    cbxUseRclBounds: TCheckBox;
    cbxNoTextScale: TCheckBox;
    cbxUnicode: TCheckBox;
    cbxCompress: TCheckBox;
    cbxUseTextScaling: TCheckBox;
    Tree: TShellTreeView;
    Panel3: TPanel;
    Panel5: TPanel;
    ProgressBar: TProgressBar;
    lbProgress: TLabel;
    lbCurrent: TLabel;
    cbxClippingRgn: TCheckBox;
    cbxJPEG: TCheckBox;
    cbxCMYK: TCheckBox;
    cbxNoUnicode: TCheckBox;
    cbxScale: TCheckBox;
    cbxUseRclFrame: TCheckBox;
    cbxBkTransparent: TCheckBox;
    cbxGDIFontSelection: TCheckBox;
    cbxRclFrameEx: TCheckBox;
    cbxDisableRasterEMF: TCheckBox;
    cbxClipRclBounds: TCheckBox;
    cbxNoBBoxCheck: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PaintBoxPaint(Sender: TObject);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure TreeClick(Sender: TObject);
    procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
    procedure cbxDebugClick(Sender: TObject);
    procedure cbxCompressClick(Sender: TObject);
    procedure tbConvertClick(Sender: TObject);
    procedure tbZoomInClick(Sender: TObject);
    procedure tbZoomOutClick(Sender: TObject);
    procedure ToolButton4Click(Sender: TObject);
    procedure cbZoomChange(Sender: TObject);
    procedure tbConvertAllClick(Sender: TObject);
    procedure cbxUnicodeClick(Sender: TObject);
    procedure cbxNoUnicodeClick(Sender: TObject);
    procedure cbxClipViewMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure cbxUseRclBoundsClick(Sender: TObject);
    procedure cbxUseRclFrameClick(Sender: TObject);
    procedure cbxRclFrameExClick(Sender: TObject);
  private
    PDF: TPDF;
    FDC: HDC;
    FBMP: HBITMAP;
    FBMPInfo: tagBITMAPINFO;
    FBuffer: Pointer;
    FView: TRect;
    FX, FY, FLastX, FLastY: Integer;
    FZoom: Double;
    MFile: TMetafileEx;
    FWidth: Integer;
    function GetFlags: Integer;
  public
end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

// LumasPDF error callback function
function ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   if MessageDlg(String(ErrMessage), mtError, [mbOK, mbCancel], 0) = mrCancel then
      Result := -1
   else
      Result := 0;
end;

// Callback function to initialize the progress bar. This function is executed by the classic API before the
// the callback function Progress is called the first time.
function InitProgress(const Data: Pointer; ProgType: TProgType; MaxCount: Integer): Integer; stdcall;
begin
   case ProgType of
      ptImportPage: Form1.lbProgress.Caption := 'Read page: ';  // Occurs only when importing an external PDF file
      ptWritePage:  Form1.lbProgress.Caption := 'Write page: '; // Writing a page to the file.
   end;
   Form1.ProgressBar.Position := 0;
   Form1.ProgressBar.Max      := MaxCount;
   Result := 0;
end;

// This callback function is called by the classic API before writing a page to the file. The reading case
// cannot occur because we do not import an external PDF file in this application.
function Progress(const Data: Pointer; ActivePage: Integer): Integer; stdcall;
begin
   Form1.lbCurrent.Caption := Format('%d of %d', [ActivePage, Form1.ProgressBar.Max]);
   Form1.ProgressBar.StepIt;
   Application.ProcessMessages; // Update the label and progress bar
   Result := 0;
end;

const MARGIN: Integer = 10;

procedure PlaceEMFCentered(PDF: TPDF; const MFile: TMetafileEx; Width, Height: Double); overload;
var x, y, w, h, sx: Double; r: TRectL;
begin
   PDF.GetLogMetafileSizeEx(MFile.Buffer, MFile.BufSize, r);
   w      := r.Right - r.Left;
   h      := r.Bottom - r.Top;
   Width  := Width  - 2.0 * MARGIN;
   Height := Height - 2.0 * MARGIN;
   sx := Width / w;
   if (h * sx <= Height) then begin
      x := MARGIN;
      y := MARGIN;
      PDF.InsertMetafileEx(MFile.Buffer, MFile.BufSize, x, y, Width, 0.0);
      h := h * sx;
      PDF.SetStrokeColor(clRed);
      PDF.Rectangle(x, y, Width, h, fmStroke);
   end else begin
      sx := Height / h;
      w  := w * sx;
      x  := MARGIN + (Width - w) / 2.0;
      y  := MARGIN;
      PDF.InsertMetafileEx(MFile.Buffer, MFile.BufSize, x, y, 0.0, Height);
      PDF.SetStrokeColor(clRed);
      PDF.Rectangle(x, y, w, Height, fmStroke);
   end;
end;

procedure PlaceEMFCentered(PDF: TPDF; const MFile: String; Width, Height: Double); overload;
var x, y, w, h, sx: Double; r: TRectL;
begin
   PDF.GetLogMetafileSize(AnsiString(MFile), r);
   w      := r.Right - r.Left;
   h      := r.Bottom - r.Top;
   Width  := Width  - 2.0 * MARGIN;
   Height := Height - 2.0 * MARGIN;
   sx := Width / w;
   if (h * sx <= Height) then begin
      x := MARGIN;
      y := MARGIN;
      PDF.InsertMetafile(AnsiString(MFile), x, y, Width, 0.0);
      //PDF.SetStrokeColor(clRed);
      //PDF.Rectangle(x, y, Width, h, fmStroke);
   end else begin
      sx := Height / h;
      w  := w * sx;
      x  := MARGIN + (Width - w) / 2.0;
      y  := MARGIN;
      PDF.InsertMetafile(AnsiString(MFile), x, y, 0.0, Height);
      //PDF.SetStrokeColor(clRed);
      //PDF.Rectangle(x, y, w, Height, fmStroke);
   end;
end;

function TForm1.GetFlags(): Integer;
begin
   Result := 0;
   if cbxDebug.Checked then Inc(Result, mfDebug);
   if cbxClipView.Checked then Inc(Result, mfClipView);
   if cbxClipRclBounds.Checked then Inc(Result, mfClipRclBounds);
   if cbxGDIFontSelection.Checked then Inc(Result, mfGDIFontSelection);
   if cbxUnicode.Checked then Inc(Result, mfUseUnicode);
   if cbxNoUnicode.Checked then Inc(Result, mfNoUnicode);
   if cbxScale.Checked then Inc(Result, mfFullScale);
   if cbxDisableRasterEMF.Checked then Inc(Result, mfDisableRasterEMF);
   if cbxNoBBoxCheck.Checked then Inc(Result, mfNoBBoxCheck);

   if cbxClippingRgn.Checked then Inc(Result, mfNoClippingRgn);
   if cbxNoTextScale.Checked then Inc(Result, mfNoTextScaling);
   if cbxUseTextScaling.Checked then Inc(Result, mfUseTextScaling);
   if cbxUseRclBounds.Checked then Inc(Result, mfUseRclBounds);
   if cbxUseRclFrame.Checked then Inc(Result, mfUseRclFrame);
   if cbxRclFrameEx.Checked then Inc(Result, mfRclFrameEx);

   if cbxBkTransparent.Checked then Inc(Result, mfDefBkModeTransp);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
   try
      PDF := TPDF.Create;
   except
      on E: Exception do MessageDlg(E.Message, mtError, [mbOK], 0);
   end;
   if PDF <> nil then begin
      PDF.SetOnErrorProc(nil, @ErrProc);
      // We use flate compression for better transparency support.
      // Due to the color interpolation when using JPEG compression
      // it is not possible to mask an image exactly with this filter.
      // Flate is a loss-less filter that produces no side effects.
      PDF.SetCompressionFilter(cfFlate);
      PDF.SetJPEGQuality(70);
   end;
   // Memory DC and DIB to render a metafile in background to avoid flicker.
   FDC  := CreateCompatibleDC(0);
   FillChar(FBMPInfo, sizeof(FBMPInfo), 0);
   FBMPInfo.bmiHeader.biBitCount := 24;
   FBMPInfo.bmiHeader.biPlanes   := 1;
   FBMPInfo.bmiHeader.biWidth    :=  Screen.Width;
   FBMPInfo.bmiHeader.biHeight   := -Screen.Height;
   FBMPInfo.bmiHeader.biSize     := 40;
   FBMP := CreateDIBSection(FDC, FBMPInfo, DIB_RGB_COLORS, FBuffer, 0, 0);
   SelectObject(FDC, FBMP);
   FZoom  := 1.0;
   FX     := 0;
   FY     := 0;
   FLastX := 0;
   FLastY := 0;
   FView  := ClientRect;
   MFile  := nil;
   cbZoom.ItemIndex := 3;
   Application.HintHidePause := -1;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
   DeleteDC(FDC);
   DeleteObject(FBMP);
   if PDF <> nil then PDF.Free;
end;

procedure TForm1.PaintBoxPaint(Sender: TObject);
var bw, bh, frw, frh, ow, oh, iw, ih, sw, sh, op, x, y: Integer; sx, sy: Double; r: TRectL; xf: TXFORM; pen: HPEN; oldObj: HGDIOBJ;
begin
   FillRect(FDC, PaintBox.ClientRect, GetStockObject(WHITE_BRUSH));
   if MFile = nil then Exit;
   pdf.SetMetaConvFlags(GetFlags());
   pdf.GetLogMetafileSizeEx(MFile.Buffer, MFile.BufSize, r);
   with r do begin
      ow := Right - Left;
      oh := Bottom - Top;
   end;
   with MFile.Header.rclBounds do begin
      bw := Right -Left;
      bh := Bottom - Top;
   end;
   with MFile.Header.rclFrame do begin
      frw := Right -Left;
      frh := Bottom - Top;
   end;

   sx := (PaintBox.ClientWidth - 20) / ow;
   iw := Trunc(ow * sx * FZoom);
   ih := Trunc(oh * sx * FZoom);

   FWidth := iw;
   x := MARGIN - FX;
   y := MARGIN - FY;

   op := SaveDC(FDC);
   if cbxClipView.Checked then begin
      IntersectClipRect(FDC, x, y, iw+x, ih+y);
   end;

   {
      This calculation does not consider the flags mfUseRclBounds, mfUseRclFrame, or mfRclFrameEx.
   }

   // Check whether the header is valid. This computation fails in very rare cases.
   if cbxNoBBoxCheck.Checked or (bw < frw * 75 / 100) or (bh < frh * 75 / 100) then begin
      xf.eM11 := sx * FZoom;
      xf.eM12 := 0.0;
      xf.eM21 := 0.0;
      xf.eM22 := sx * FZoom;
      xf.eDx  := -r.Left * sx * FZoom + x;
      xf.eDy  := -r.Top  * sx * FZoom + y;
      SetGraphicsMode(FDC, GM_ADVANCED);
      ModifyWorldTransform(FDC, xf, MWT_LEFTMULTIPLY);
      PlayEnhMetafile(FDC, MFile.Handle, TRect(r));
   end else begin
      // The rclFrame rectangle seems to be invalid. We try to compute the correct image size.
      with MFile.Header.szlMillimeters do begin
         sw := cx * 100;
         sh := cy * 100;
      end;
      sx := frw / sw;
      sy := frh / sh;
      sw := Trunc(MFile.Header.szlDevice.cx * sx);
      sh := Trunc(MFile.Header.szlDevice.cy * sy);

      SetMapMode(FDC, MM_ANISOTROPIC);
      SetWindowExtEx(FDC, ow, oh, nil);
      SetViewPortOrgEx(FDC, x, y, nil);
      SetViewPortExtEx(FDC, sw, sh, nil);
      PlayEnhMetafile(FDC, MFile.Handle, Rect(0,0,iw,ih));
   end;
   RestoreDC(FDC, op);

   SelectObject(FDC, GetStockObject(NULL_BRUSH));
   pen := CreatePen(PS_SOLID, 1, 255);
   oldObj := SelectObject(FDC, pen);
   Rectangle(FDC, x, y, iw+x, ih+y);
   DeleteObject(SelectObject(FDC, oldObj));

   GDIFlush;
   SetDIBitsToDevice(PaintBox.Canvas.Handle, 0, 0, PaintBox.ClientWidth, PaintBox.ClientHeight, 0, 0, 0, PaintBox.ClientHeight, FBuffer, FBMPInfo, DIB_RGB_COLORS);
end;

procedure TForm1.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
   FView.Left   := X;
   FView.Top    := Y;
   FView.Right  := X;
   FView.Bottom := Y;
   FLastX       := FX;
   FLastY       := FY;
   if ssRight in Shift then begin
      FZoom  := 1.0;
      FX     := 0;
      FY     := 0;
      FLastX := 0;
      FLastY := 0;
      cbZoom.ItemIndex  := 3;
      tbZoomIn.Enabled  := true;
      tbZoomOut.Enabled := true;
      PaintBoxPaint(nil);
   end;
end;

procedure TForm1.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
   if (ssLeft in Shift) then begin
      FX := FView.Left - X + FLastX;
      FY := FView.Top - Y + FLastY;
      FView.Right  := X;
      FView.Bottom := Y;
      PaintBoxPaint(nil);
   end;
end;

procedure TForm1.FormMouseWheelDown(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
   if MousePos.X < Form1.Left + Splitter1.Left + Splitter1.Width then Exit;
   Inc(FY, 40);
   Handled := true;
   PaintBoxPaint(nil);
end;

procedure TForm1.FormMouseWheelUp(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
   if MousePos.X < Form1.Left + Splitter1.Left + Splitter1.Width then Exit;
   if FY = 0 then begin
      Handled := true;
      Exit;
   end;
   Dec(FY, 40);
   if FY < 0 then FY := 0;
   Handled := true;
   PaintBoxPaint(nil);
end;

procedure TForm1.cbxDebugClick(Sender: TObject);
begin
   cbxCompress.OnClick := nil;
   cbxCompress.Checked := false;
   cbxCompress.OnClick := cbxCompressClick;
end;

procedure TForm1.cbxCompressClick(Sender: TObject);
begin
   cbxDebug.OnClick := nil;
   cbxDebug.Checked := false;
   cbxDebug.OnClick := cbxDebugClick;
end;

procedure TForm1.TreeClick(Sender: TObject);
var ext: String;
begin
   ext := LowerCase(ExtractFileExt(Tree.Path));
   if (ext = '.emf') or (ext = '.wmf') then begin
      FZoom  := 1.0;
      FX     := 0;
      FY     := 0;
      FLastX := 0;
      FLastY := 0;
      cbZoom.ItemIndex := 3;
      tbZoomIn.Enabled  := true;
      tbZoomOut.Enabled := true;
      if MFile <> nil then MFile.Free;
      MFile := TMetafileEx.Create;
      try
         MFile.LoadFromFile(Tree.Path);
         tbConvert.Enabled    := true;
         tbConvertAll.Enabled := true;
         PaintBoxPaint(nil);
      except
         MFile.Free;
         MFile := nil;
      end;
   end else begin
      tbConvert.Enabled    := false;
      tbConvertAll.Enabled := false;
   end;
end;

procedure TForm1.tbConvertClick(Sender: TObject);
var s: String;
begin
   if PDF = nil then begin
      MessageDlg('No active PDF instance!'#13'Forgotten to copy the LumasPdf.dll into a Windows search path?', mtError, [mbOK], 0);
      Exit;
   end;
   s := Tree.Path;
   s := ChangeFileExt(s, '.pdf');
   SaveDialog1.FileName := s;
   if SaveDialog1.Execute = false then Exit;
   if not PDF.CreateNewPDF('') then Exit;

   if (cbxCompress.Checked) then
      PDF.SetCompressionLevel(LumasPdfApi.clDefault)
   else
      PDF.SetCompressionLevel(LumasPdfApi.clNone);
   if cbxJPEG.Checked then
      PDF.SetCompressionFilter(cfJPEG)
   else
      PDF.SetCompressionFilter(cfFlate);
   if cbxCMYK.Checked then
      PDF.SetColorSpace(csDeviceCMYK)
   else
      PDF.SetColorSpace(csDeviceRGB);
   Application.ProcessMessages;
   PDF.SetMetaConvFlags(GetFlags());
   PDF.SetPageCoords(pcTopDown);
   PDF.Append;
   PDF.SetResolution(300);
   PDF.SetJPEGQuality(70);
   PlaceEMFCentered(PDF, MFile, PDF.GetPageWidth, PDF.GetPageHeight);
   PDF.EndPage;
   if PDF.HaveOpenDoc then begin
      while not PDF.OpenOutputFile(SaveDialog1.FileName) do begin
         if SaveDialog1.Execute = false then begin
            PDF.FreePDF;
            Exit;
         end;
      end;
      if PDF.CloseFile = true then
         ShellExecute(Handle, PChar('open'), PChar(SaveDialog1.FileName), nil, nil, SW_SHOWMAXIMIZED);
   end;
end;

procedure TForm1.tbZoomInClick(Sender: TObject);
begin
   cbZoom.ItemIndex := cbZoom.ItemIndex +1;
   if cbZoom.ItemIndex = 11 then tbZoomIn.Enabled := false;
   tbZoomOut.Enabled := true;
   cbZoomChange(nil);
end;

procedure TForm1.tbZoomOutClick(Sender: TObject);
begin
   cbZoom.ItemIndex := cbZoom.ItemIndex -1;
   if cbZoom.ItemIndex = 0 then tbZoomOut.Enabled := false;
   tbZoomIn.Enabled := true;
   cbZoomChange(nil);
end;

procedure TForm1.ToolButton4Click(Sender: TObject);
begin
   FZoom  := 1.0;
   FX     := 0;
   FY     := 0;
   FLastX := 0;
   FLastY := 0;
   cbZoom.ItemIndex  := 3;
   tbZoomIn.Enabled  := true;
   tbZoomOut.Enabled := true;
   PaintBoxPaint(nil);
end;

procedure TForm1.cbZoomChange(Sender: TObject);
var oldZoom: Double;
begin
   oldZoom := FZoom;
   case cbZoom.ItemIndex of
      0: FZoom := 0.125;
      1: FZoom := 0.25;
      2: FZoom := 0.5;
      3: FZoom := 1.0;
      4: FZoom := 1.5;
      5: FZoom := 2.0;
      6: FZoom := 4.0;
      7: FZoom := 8.0;
      8: FZoom := 16.0;
      9: FZoom := 32.0;
      10: FZoom := 64.0;
      11: FZoom := 128.0;
   end;
   FX := Trunc(FX / oldZoom * FZoom);
   FY := Trunc(FY / oldZoom * FZoom);
   PaintBoxPaint(nil);
end;

procedure TForm1.tbConvertAllClick(Sender: TObject);
var i, count, nextAlloc: Integer; s, ext: String; sr: TSearchRec; paths: array of String;
begin
   if PDF = nil then begin
      MessageDlg('No active PDF instance!'#13'Forgotten to copy the LumasPdf.dll into a Windows search path?', mtError, [mbOK], 0);
      Exit;
   end;
   s := ExtractFilePath(Tree.Path);
   SaveDialog1.FileName := s + 'EmfFiles.pdf';
   if SaveDialog1.Execute = false then Exit;

   if not PDF.CreateNewPDF(SaveDialog1.FileName) then Exit;

   if (cbxCompress.Checked) then
      PDF.SetCompressionLevel(LumasPdfApi.clDefault)
   else
      PDF.SetCompressionLevel(LumasPdfApi.clNone);
   if cbxCMYK.Checked then
      PDF.SetColorSpace(csDeviceCMYK)
   else
      PDF.SetColorSpace(csDeviceRGB);
   PDF.SetMetaConvFlags(GetFlags());
   PDF.SetPageCoords(pcTopDown);
   // The resolution is used to convert images from the metafile, not to convert the metafile itself.
   PDF.SetResolution(300);

   if FindFirst(s + '*.*', faAnyFile, sr) <> 0 then begin
      PDF.FreePDF;
      MessageDlg('No Metafiles found!', mtError, [mbOK], 0);
      Exit;
   end;
   // We disconnect the error callback to avoid multiple warnings if more than one metafile is corrupt.
   PDF.SetOnErrorProc(nil, nil);
   // We count the files first so that we can initialize the progress bar.
   count := 0;
   nextAlloc := 100;
   SetLength(paths, nextAlloc);
   try
      repeat
         if sr.Name[1] = '.' then continue;
         ext := LowerCase(ExtractFileExt(sr.Name));
         if (StrComp(PChar(ext), PChar('.emf')) <> 0) and (StrComp(PChar(ext), PChar('.wmf')) <> 0) then continue;
         paths[count] := sr.Name;
         Inc(count);
         if (count = nextAlloc) then begin
            Inc(nextAlloc, 100);
            SetLength(paths, nextAlloc);
         end;
      until (FindNext(sr) <> 0);
   finally
      FindClose(sr);
   end;
   ProgressBar.Position := 0;
   ProgressBar.Max      := count;
   ProgressBar.Step     := 1;
   ProgressBar.Visible  := true;
   lbProgress.Caption   := 'In progress:';
   for i := 0 to count -1 do begin
      lbCurrent.Caption := paths[i];
      ProgressBar.StepIt;
      Application.ProcessMessages;
      PDF.Append;
      PlaceEMFCentered(PDF, s + paths[i], 595.0, 842.0);
      PDF.EndPage;
   end;
   // Connect the error callback now again.
   PDF.SetOnErrorProc(nil, @ErrProc);
   // We connect also the progress bar because the file can be large.
   PDF.SetProgressProc(nil, @InitProgress, @Progress);
   PDF.CloseFile;
   // It makes no sense to use a progress bar for single page files, so we disconnect it.
   PDF.SetProgressProc(nil, nil, nil);
   lbProgress.Caption := '';
   lbCurrent.Caption  := '';
   ProgressBar.Visible := false;
   ShellExecute(Handle, PChar('open'), PChar(SaveDialog1.FileName), nil, nil, SW_SHOWMAXIMIZED);
end;

procedure TForm1.cbxUnicodeClick(Sender: TObject);
begin
   cbxNoUnicode.Checked := false;  
end;

procedure TForm1.cbxNoUnicodeClick(Sender: TObject);
begin
   cbxUnicode.Checked := false;
end;

procedure TForm1.cbxClipViewMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
   PaintBoxPaint(nil);
end;

procedure TForm1.cbxUseRclBoundsClick(Sender: TObject);
begin
   PaintBoxPaint(nil);
end;

procedure TForm1.cbxUseRclFrameClick(Sender: TObject);
begin
   PaintBoxPaint(nil);
end;

procedure TForm1.cbxRclFrameExClick(Sender: TObject);
begin
   PaintBoxPaint(nil);
end;

end.

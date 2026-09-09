unit Unit1;

interface

uses
  Windows, Messages, Math, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, LumasPdfApi;

type
  TForm1 = class(TForm)
   OpenDialog: TOpenDialog;
   procedure FormCreate(Sender: TObject);
   procedure FormDestroy(Sender: TObject);
   procedure FormResize(Sender: TObject);
   procedure RenderPage;
   procedure FormPaint(Sender: TObject);
   procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
   procedure FormShow(Sender: TObject);
   procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  public
   procedure CreateParams(var Params: TCreateParams); override;
   procedure UpdateArea(var Area: TIntRect);
  protected
   FAdjWindow:    Boolean;
   FBMPInfo:      PBitmapInfo;
   FBorderX:      Integer;
   FBorderY:      Integer;
   FBuffer:       PByte;
   FBufSize:      Integer;
   FCurrPage:     Integer;
   FCurrPageObj:  Pointer;
   FDC:           HDC;
   FDPIX:         Integer;
   FDPIY:         Integer;
   FImpPages:     PByte;
   FPageCount:    Integer;
   FImgH:         Integer;
   FImgW:         Integer;
   FPDF:          TPDF;
   FPixFmt:       TPDFPixFormat;
   FRAS:          Pointer;
   FRasImage:     TPDFRasterImage;
   FRenderThread: THandle;
   FScreenH:      Integer;
   FScreenW:      Integer;
   FUpdate:       Boolean;
   procedure AddPage(PageNum: Integer);
   procedure InitImpPageArray;
   function  IsPageAvailable(PageNum: Integer): Boolean;
   procedure RenderCurrPage;
   procedure RenderNextPage(PageNum: Integer);
   procedure ShowOpenFileDialog;
   procedure StartRenderThread;
   procedure StopRenderThread;
   procedure UpdateBitmapInfo;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

const APP_BACK_COLOR     = $00505050;
const APP_CLIENT_BORDER  = 6;
const APP_CLIENT_BORDER2 = 3;

function PDFError(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   MessageDlg(String(AnsiString(ErrMessage)), mtError, [mbOK], 0);
   Result := 0; // We try to continue
end;

// This function is called if the path or image coverage limit was reached.
// It is quite important to set this callback function since it makes sure that
// we can see something if a complex page will be rendered.
function OnUpdateWindow(const Data: Pointer; var Area: TIntRect): Integer; stdcall;
begin
   TForm1(Data).UpdateArea(Area);
   Result := 0;
end;

function RenderPageFunc(Param: Pointer): Integer;
begin
   TForm1(Param).RenderPage;
   Result := 0;               
end;

{ ----------------------------------------------------------------------------------------- }

procedure TForm1.AddPage(PageNum: Integer);
var p: PByte;
begin
   p := FImpPages;
   Inc(p, PageNum shr 3);
   p^ := p^ or ($80 shr (PageNum and 7));
end;

procedure TForm1.CreateParams(var Params: TCreateParams);
begin
   inherited CreateParams(Params);
   // We need a private DC! The flag CS_OWNDC is required.
   Params.Style             := WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX or WS_THICKFRAME;
   Params.WindowClass.style := CS_OWNDC or CS_VREDRAW or CS_HREDRAW;
end;

procedure TForm1.FormCreate(Sender: TObject);
var dc: HDC; p: TPDFColorProfiles; mProfile: PWideChar; size: Cardinal;
begin
   FDC                             := GetDC(WindowHandle);
   FBorderX                        := Width - (ClientRect.Right - ClientRect.left)  + APP_CLIENT_BORDER;
   FBorderY                        := Height - (ClientRect.bottom - ClientRect.top) + APP_CLIENT_BORDER;
   FPixFmt                         := pxfBGRA;
   FPDF                            := TPDF.Create();
   FRasImage.StructSize            := sizeof(FRasImage);
   FRasImage.DefScale              := psFitBest;
   FRasImage.InitWhite             := true;
   // We draw the image with SetDIBitsToDevice() and this function does not support alpha transparency.
   // To get a correct result we pre-blend the image with a white background.
   FRasImage.Flags                 := TRasterFlags(rfDefault or rfCompositeWhite);
   FRasImage.Matrix.a              := 1.0;
   FRasImage.Matrix.d              := 1.0;
   // The OnUpdateWindow callback function makes sure that we don't see a gray or white screen for a long time when rendering complex pages.
   FRasImage.OnUpdateWindow        := OnUpdateWindow;
   FRasImage.UpdateOnImageCoverage := 0.5;
   FRasImage.UpdateOnPathCount     := 1000;
   FRasImage.UserData              := self;

   dc       := GetDC(0);
   FDPIX    := GetDeviceCaps(dc, LOGPIXELSX);
   FDPIY    := GetDeviceCaps(dc, LOGPIXELSY);
   FScreenW := GetDeviceCaps(dc, HORZRES);
   FScreenH := GetDeviceCaps(dc, VERTRES);

   // Get the monitor profile
   GetMem(mProfile, 1024);
   mProfile[0] := #0;
   size := 511;
   GetICMProfileW(dc, size, mProfile);

   ReleaseDC(0, dc);

   FPDF.SetOnErrorProc(self, @PDFError);
   // It is important to set an absolute path here since a relative path
   // doesn't work if the working directory will be changed at runtime.
   // The flag lcmDelayed makes sure that the cmaps will only be loaded
   // if necessary.
   FPDF.SetCMapDir(ExpandFileName('../../../../Resource/CMap/'), lcmRecursive or lcmDelayed);
   // Initialize color management
   FillChar(p, SizeOf(p), 0);
   p.StructSize     := SizeOf(p);
   p.DefInCMYKW     := PWideChar(WideString(ExpandFileName('../../../test_files/ISOcoated_v2_bas.ICC')));
   p.DeviceProfileW := mProfile;
   FPDF.InitColorManagement(@p, csDeviceRGB, icmBPCompensation or icmCheckBlackPoint);
   FreeMem(mProfile);
   // Delphi enables floating point exceptions and this conflicts with the C++ exception handling of LumasPDF.
   SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
   if FBMPInfo <> nil then FreeMem(FBMPInfo);
   if FBuffer  <> nil then FreeMem(FBuffer);
   if FPDF <> nil then begin
      if FRAS <> nil then FPDF.DeleteRasterizer(@FRAS);
      FPDF.Free;
   end;
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
   if (Key = 79) and (ssCtrl in Shift) then
      ShowOpenFileDialog
   else if Key = VK_UP then
      RenderNextPage(FCurrPage-1)
   else if Key = VK_DOWN then
      RenderNextPage(FCurrPage+1);
end;

procedure TForm1.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
   if WheelDelta < 0 then
      RenderNextPage(FCurrPage+1)
   else
      RenderNextPage(FCurrPage-1);
end;

procedure TForm1.FormPaint(Sender: TObject);
var r: TRect;
begin
   SetBkColor(FDC, APP_BACK_COLOR);
   // Left
   r.left   := 0;
   r.right  := APP_CLIENT_BORDER2;
   r.bottom := ClientRect.bottom;
   r.top    := ClientRect.top;
   ExtTextOut(FDC, 0, 0, ETO_OPAQUE, @r, nil, 0, nil);
   // Bottom
   r.left   := APP_CLIENT_BORDER2;
   r.right  := ClientRect.right;
   r.bottom := ClientRect.bottom;
   r.top    := ClientRect.bottom - APP_CLIENT_BORDER2;
   ExtTextOut(FDC, 0, 0, ETO_OPAQUE, @r, nil, 0, nil);
   // Right
   r.left   := APP_CLIENT_BORDER2;
   r.right  := ClientRect.right;
   r.bottom := ClientRect.top + APP_CLIENT_BORDER2;
   r.top    := ClientRect.top;
   // Top
   ExtTextOut(FDC, 0, 0, ETO_OPAQUE, @r, nil, 0, nil);
   r.left   := ClientRect.right - APP_CLIENT_BORDER2;
   r.right  := ClientRect.right;
   r.bottom := ClientRect.bottom;
   r.top    := ClientRect.top;
   ExtTextOut(FDC, 0, 0, ETO_OPAQUE, @r, nil, 0, nil);
   if FUpdate then begin
      if FRenderThread = 0 then StartRenderThread;
   end else if FCurrPage > 0 then
      SetDIBitsToDevice(FDC, APP_CLIENT_BORDER2, APP_CLIENT_BORDER2, FImgW, FImgH, 0, 0, 0, FImgH, FBuffer, FBMPInfo^, 0);
end;

procedure TForm1.FormResize(Sender: TObject);
var r: TRect;
begin
   r := ClientRect;
   SetBkColor(FDC, APP_BACK_COLOR);
   ExtTextOut(FDC, 0, 0, ETO_OPAQUE, @r, nil, 0, nil);
   FAdjWindow := true;
   RenderCurrPage;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
   ShowOpenFileDialog;
end;

procedure TForm1.InitImpPageArray;
var size: Integer;
begin
   if FImpPages <> nil then begin
      FreeMem(FImpPages);
      FImpPages := nil;
   end;
   size := (FPageCount shr 3) + 1;
   GetMem(FImpPages, size);
   FillChar(FImpPages^, size, 0);
end;

function TForm1.IsPageAvailable(PageNum: Integer): Boolean;
var p: PByte;
begin
   p := FImpPages;
   Inc(p, PageNum shr 3);
   Result := (p^ and ($80 shr (PageNum and 7))) <> 0;
end;

procedure TForm1.RenderCurrPage;
var w, h: Integer;
begin
   StopRenderThread;
   if FCurrPage > 0 then begin
      w := 0;
      h := 0;
      if not IsPageAvailable(FCurrPage) then begin
         // No need to check the return value of ImportPageEx(). Nothing critical happens
         // if the function fails. We get just an empty page in this case.
         FPDF.EditPage(FCurrPage);
            FPDF.ImportPageEx(FCurrPage, 1.0, 1.0);
         FPDF.EndPage;
         AddPage(FCurrPage);
      end;
      // This check is required to avoid critical errors.
      FCurrPageObj := FPDF.GetPageObject(FCurrPage);
      if FCurrPageObj = nil then Exit;
      FPDF.CalcPagePixelSize(FCurrPageObj, psFitBest, 1.0, FScreenW-FBorderX, FScreenH-FBorderY, FRasImage.Flags, Cardinal(w), Cardinal(h));
      if (w <> FImgW) or (h <> FImgH) then begin
         FImgW := w;
         FImgH := h;
         if FBuffer <> nil then begin
            FreeMem(FBuffer);
            FBuffer := nil;
         end;
         FBufSize := FImgW * 4 * FImgH;
         GetMem(FBuffer, FBufSize);
         if FRAS = nil then begin
            FRAS := FPDF.CreateRasterizer(nil, FBuffer, FImgW, FImgH, FImgW * 4, FPixFmt);
            if (FRAS = nil) then raise Exception.Create('Out of memory!');
         end else begin
            if not FPDF.AttachImageBuffer(FRAS, nil, FBuffer, FImgW, FImgH, FImgW * 4) then raise Exception.Create('Out of memory!');
         end;
         UpdateBitmapInfo;
      end;
      if FAdjWindow then begin
         w := FImgW + FBorderX;
         h := FImgH + FBorderY;
         if (ClientWidth - APP_CLIENT_BORDER <> FImgW) or (ClientHeight - APP_CLIENT_BORDER <> FImgH) then begin
            FAdjWindow := false;
            MoveWindow(WindowHandle, (FScreenW-w) shr 1, (FScreenH-h) shr 1, w, h, true);
         end;
      end;
      FUpdate := true;
      InvalidateRect(WindowHandle, nil, false);
   end;
end;

procedure TForm1.RenderNextPage(PageNum: Integer);
begin
   if (PageNum < 1) or (PageNum > FPageCount) or (PageNum = FCurrPage) then Exit;
   FCurrPage  := PageNum;
   FAdjWindow := true;
   RenderCurrPage;
end;

procedure TForm1.RenderPage;
begin
   FPDF.RenderPage(FCurrPageObj, FRAS, FRasImage);
   FUpdate := false;
   InvalidateRect(WindowHandle, nil, false);
end;

procedure TForm1.ShowOpenFileDialog;
begin
   FCurrPage  := 0;
   FPageCount := 0;
   StopRenderThread;
   InvalidateRect(WindowHandle, nil, false);
   if OpenDialog.Execute then begin
      if FPDF.HaveOpenDoc then FPDF.FreePDF;
      FPDF.CreateNewPDF(''); // We create no PDF file in this example

      if FPDF.OpenImportFile(OpenDialog.FileName, ptOpen, '') < 0 then Exit;

      // We import pages manually in this example and therefore, no global objects will
      // be imported as it would be the case if ImportPDFFile() would be used.
      // However, the one and only thing we need is the output intent for correct
      // color management. Anything else can be discarded.
      FPDF.SetImportFlags(ifContentOnly);
      FPDF.ImportCatalogObjects;
      // Reset the import flags so that form fields, annotation and so will be loaded
      FPDF.SetImportFlags(ifImportAll or ifImportAsPage); // The flag ifImportAsPage makes sure that pages will not be converted to templates.
      FPDF.SetImportFlags2(if2UseProxy);                  // The flag if2UseProxy reduces the memory usage.

      FPageCount := FPDF.GetInPageCount;
      
      InitImpPageArray;

      FAdjWindow := true;
      FCurrPage  := 1;
      RenderCurrPage;
   end;
end;

procedure TForm1.StartRenderThread;
var id: Cardinal;
begin
   StopRenderThread;
   FUpdate := false;
   FRenderThread := BeginThread(nil, 0, @RenderPageFunc, self, CREATE_SUSPENDED, id);
   if (FRenderThread = 0) then raise Exception.Create('Cannot create render thread!');
   SetThreadPriority(FRenderThread, THREAD_PRIORITY_LOWEST);
   ResumeThread(FRenderThread);
end;

procedure TForm1.StopRenderThread;
begin
   if FRenderThread <> 0 then begin
      FPDF.Abort(FRAS);
      WaitForSingleObject(FRenderThread, INFINITE);
      CloseHandle(FRenderThread);
      FRenderThread := 0;
   end;
end;

procedure TForm1.UpdateArea(var Area: TIntRect);
begin
   SetDIBitsToDevice(FDC,
                     Area.x1+APP_CLIENT_BORDER2,
                     Area.y1+APP_CLIENT_BORDER2,
                     Area.x2-Area.x1,
                     Area.y2-Area.y1,
                     Area.x1,
                     FImgH-Area.y2,
                     0,
                     FImgH,
                     FBuffer,
                     FBMPInfo^,
                     DIB_RGB_COLORS);
end;

procedure TForm1.UpdateBitmapInfo;
var i, count, bits, size: Integer; buf: PByte;
begin
   case FPixFmt of
      pxf1Bit: bits := 1;
      pxfGray: bits := 8;
      pxfBGR:  bits := 24;
      pxfBGRA: bits := 32;
      else     raise Exception.Create('Unknown error!');
   end;
   if FBMPInfo = nil then begin
      size := 40;
      if (bits = 8) then
         Inc(size, 1024)
      else if (bits = 1) then
         Inc(size, 8);

      GetMem(FBMPInfo, size + 4);
      FillChar(FBMPInfo^, size + 4, 0);
      FBMPInfo^.bmiHeader.biBitCount := bits;
      FBMPInfo^.bmiHeader.biPlanes   := 1;
      FBMPInfo^.bmiHeader.biSize     := 40;
      if (size > 40) then begin
         buf := PByte(FBMPInfo);
         Inc(buf, 40);
         count := (1 shl bits) - 1;
         for i := 0 to count do begin
            FillChar(buf^, 3, (i * 255) div count);
            Inc(buf, 3);
            buf^ := 0;
            Inc(buf);
         end;
      end;
   end;
   FBMPInfo^.bmiHeader.biSizeImage :=  FImgH * (((FImgW * bits + 31) and not 31) shr 3);
   FBMPInfo^.bmiHeader.biWidth     :=  FImgW;
   FBMPInfo^.bmiHeader.biHeight    := -FImgH;
end;

end.

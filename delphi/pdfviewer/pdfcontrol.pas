unit pdfcontrol;

interface

{$FINITEFLOAT OFF}

uses
  Windows, Messages, Graphics, Forms, Math, SysUtils, Classes, Controls, ExtCtrls, LumasPdfApi;

type TOnAfterUpdateScreen = procedure(Sender: TObject; DC: HDC; var Area: TIntRect) of object;
type TOnNewPDFPage        = procedure(Sender: TObject; NewPage: Integer) of object;
type TOnPDFPaint          = procedure(Sender: TObject; DC: HDC; CurrPage: Integer) of object;
type TPDFScrollEvent      = procedure(Sender: TObject; Vertical: Boolean; ScrollCode, NewPos, NewPageNum: Integer) of object;

// Cursors
const crHandNormal = 1;
const crHandClosed = 2;

// Private error message
const WM_DISPLAYERRORS = WM_USER + 1;

{
   The page cache is the owner of the main PDF instance that loads a PDF file. It is safe to access this instance at runtime since
   it is only used to caluculate the page size and orientation. The corresponding code runs in the main process so that you can safely
   access it without side effects. From the view of the caller this instance is single threaded.
   The main PDF instance has the same life time as the PDFCanvas. It is safe to store a reference of the main instance in a variable in
   the FormCreate event and to use it until the application becomes terminated. 
   The page cache doesn't load pages into the main instance, so, the page count of this instance is always zero. The rendering thread(s)
   use their own PDF instance that cannot be accessed from outside.
   When it is required to modify or to store the PDF file on disk then use another PDF instance for this purpose.
}
type
  TPDFCanvas = class(TWinControl)
  private
    FAutoScroll:           Boolean;
    FBackColor:            TColor;
    FCache:                TPDFPageCache;
    FColorManagement:      Boolean;
    FErrMaxCount:          Integer;
    FErrors:               TStringList;
    FFirstPage:            Integer;
    FHandle:               HWND;
    FHavePos:              Boolean;
    FHeight:               Integer;
    FInitError:            String;
    FInitialized:          Boolean;
    FOldPage:              Integer;
    FOnAfterUpdateScreen:  TOnAfterUpdateScreen;
    FOnError:              TNotifyEvent;
    FOnMouseDown:          TMouseEvent;
    FOnMouseMove:          TMouseMoveEvent;
    FOnMouseUp:            TMouseEvent;
    FOnMouseWheel:         TMouseWheelEvent;
    FOnNewPage:            TOnNewPDFPage;
    FOnPaint:              TOnPDFPaint;
    FOnResize:             TNotifyEvent;
    FOnScroll:             TPDFScrollEvent;
    FPageCount:            Integer;
    FPDF:                  TPDF;
    FRedraw:               Boolean;
    FResolution:           Integer;
    FScrollLine:           Integer;
    FScrollVMax:           Integer;
    FWidth:                Integer;
    FScrollWindow:         Boolean;
    FWheelLines:           Integer;
    FZoomMode:             Boolean;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    function  GetDefPageLayout(): TPageLayout;
    function  GetPageLayout(): TPageLayout;
    function  GetPageScale(): TPDFPageScale;
    function  Scroll(Vertical: Boolean; ScrollCode: Integer; var ScrollPos, NewPageNum: Integer): Boolean;
    procedure SetAutoScroll(Value: Boolean);
    procedure SetBackColor(Color: TColor);
    procedure SetDefPageLayout(Value: TPageLayout);
    procedure SetPageLayout(Value: TPageLayout);
    procedure SetPageScale(Value: TPDFPageScale);
    procedure UpdateScrollBars;
    procedure UpdateScrollBarsEx;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure AddError(ErrMessage: String);
    property  AlignDisabled;
    property  CacheInstance: TPDFPageCache read FCache;
    procedure CloseFile;
    property  DefPageLayout: TPageLayout   read GetDefPageLayout write SetDefPageLayout;
    procedure DisableScrollBars;
    procedure DisplayFirstPage;
    property  ErrorLog:      TStringList   read FErrors;
    function  ExecBookmark(Index: Cardinal): TUpdBmkAction;
    property  FirstPage:     Integer       read FFirstPage;
    function  GetDC: HDC;
    // GetPageMatrix() returns the page number at the curser position on success, as well the exact position and size of the rendered page.
    // You must check whether the return value is greater 0. Otherwise there is no page at the cursor coordinates or the page was not loaded yet.
    // The x-coordinate of the cursor is currently not taken into account because only one page can occur in horizontal direction at this time.
    // The matrix transforms PDF space to device space. DestX/Y must be added to get final device coordinates.
    function  GetPageMatrix(CursorX, CursorY: Integer; var DestX, DestY, Width, Height: Integer; var Matrix: TCTM): Integer;
    function  GetRotate:     Integer;
    function  GetScrollLineDelta(Vertical: Boolean): Cardinal;
    function  GetScrollPos(Vertical: Boolean): Integer;
    property  Handle:        HWND          read FHandle;
    property  Height:        Integer       read FHeight;
    function  InitBaseObjects(Flags: TInitCacheFlags): Boolean;
    property  InitError:     String        read FInitError;
    procedure InitScrollBar(Vertical: Boolean; Max, SmallChange, LargeChange: Integer);
    procedure Loaded; override;
    procedure Lock;
    property  PageCount:     Integer       read FPageCount;
    property  PageLayout:    TPageLayout   read GetPageLayout write SetPageLayout;
    property  PageScale:     TPDFPageScale read GetPageScale  write SetPageScale;
    property  PDFInstance:   TPDF          read FPDF;
    procedure ProcessErrors(UpdateWindow: Boolean);
    procedure Redraw;
    property  Resolution:    Integer       read FResolution;
    procedure ScrollTo(PageNum: Integer);
    function  SetOCGState(Handle: Cardinal; Visible, SaveState: Boolean): Boolean;
    procedure SetRotate(Value: Integer);
    function  SetScrollLineDelta(Vertical: Boolean; Value: Cardinal): Boolean;
    procedure SetScrollPos(Vertical: Boolean; NewPos: Integer; RedrawScrollBar: Boolean);
    procedure SetThreadPriority(UpdateThread, RenderThread: TPDFThreadPriority);
    procedure UnLock;
    procedure UpdateCache(PageNum: Integer);
    property  Width:         Integer       read FWidth;
    procedure Zoom(Value: Single);
    property  ZoomMode:      Boolean       read FZoomMode;
    procedure WMButtonLDown(var Msg: TWMMouse);     message WM_LBUTTONDOWN;
    procedure WMButtonLUp(var Msg: TWMMouse);       message WM_LBUTTONUP;
    procedure WMError(var Msg: TMessage);           message WM_DISPLAYERRORS; 
    procedure WMEraseBackground(var Msg: TMessage); message WM_ERASEBKGND;
    procedure WMHandleDlgCode(var Msg: TMessage);   message WM_GETDLGCODE;
    procedure WMKeyDown(var Msg: TWMKey);           message WM_KEYDOWN;
    procedure WMMouseMove(var Msg: TWMMouseMove);   message WM_MOUSEMOVE;
    procedure WMMouseWheel(var Msg: TCMMouseWheel); message WM_MOUSEWHEEL;
    procedure WMPaint(var Msg: TMessage);           message WM_PAINT;
    procedure WMResize(var Msg: TMessage);          message WM_SIZE;
    procedure WMScrollHorz(var Msg: TMessage);      message WM_HSCROLL;
    procedure WMScrollVert(var Msg: TMessage);      message WM_VSCROLL;
  published
    property Align;
    property AutoScroll:            Boolean              read FAutoScroll           write SetAutoScroll        default true;
    property BackColor:             TColor               read FBackColor            write SetBackColor         default clAppWorkSpace;
    property ColorManagement:       Boolean              read FColorManagement      write FColorManagement     default true;
    property Constraints;
    property Enabled;
    property MaxErrCount:           Integer              read FErrMaxCount          write FErrMaxCount         default 100;
    property OnAfterUpdateScreen:   TOnAfterUpdateScreen read FOnAfterUpdateScreen  write FOnAfterUpdateScreen;
    property OnEnter;
    property OnError:               TNotifyEvent         read FOnError              write FOnError;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnPaint:               TOnPDFPaint          read FOnPaint              write FOnPaint;
    property OnMouseDown:           TMouseEvent          read FOnMouseDown          write FOnMouseDown;
    property OnMouseUp:             TMouseEvent          read FOnMouseUp            write FOnMouseUp;
    property OnMouseMove:           TMouseMoveEvent      read FOnMouseMove          write FOnMouseMove;
    property OnMouseWheel:          TMouseWheelEvent     read FOnMouseWheel         write FOnMouseWheel;
    property OnNewPage:             TOnNewPDFPage        read FOnNewPage            write FOnNewPage;
    property OnResize:              TNotifyEvent         read FOnResize             write FOnResize;
    property OnScroll:              TPDFScrollEvent      read FOnScroll             write FOnScroll;
    property TabOrder;
    property TabStop;
    property UseScrollWindow:       Boolean              read FScrollWindow         write FScrollWindow        default true;
    property WheelLines:            Integer              read FWheelLines;
end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('PDF', [TPDFCanvas]);
end;

{ TPDFCanvas }

{
   The error callback function works differently with the page cache. It does not return error messages since all error
   messages are stored in the error log. The error callback function is called when it is safe to access the error log
   and if new messages are available.
   The parameter ErrCode is set to the page number that produced the error or to -1 if the error occurred during loading
   the top level objects.
   The rendering thread (if running) waits until the error callback function returns. So, it is not required to synchronize
   anything since no competing threads are running.
}
function PDFErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
var i, count: Integer; canvas: TPDFCanvas; list: TStringList; pdf: TPDF; msg: TPDFError;
begin
   Result := 0;
   canvas := TPDFCanvas(Data);
   pdf    := canvas.PDFInstance;
   list   := canvas.ErrorLog;
   count  := pdf.GetErrLogMessageCount;
   if list.Count + count > canvas.MaxErrCount then
      count := canvas.MaxErrCount - list.Count;
   if count < 1 then Exit;
   msg.StructSize := sizeof(msg);
   try
      for i := 0 to count - 1 do begin
         if pdf.GetErrLogMessage(i, msg) then begin
            // ErrCode is set to the page number if the errors occurred during rendering a page!
            if ErrCode > 0 then
               list.Add(Format('Page %.5d: %s, ObjNum: %d, Offset: %d', [ErrCode, String(msg.Msg), msg.ObjNum, msg.Offset]))
            else
               list.Add(Format('%s, ObjNum: %d, Offset: %d', [String(msg.Msg), msg.ObjNum, msg.Offset]));
         end;
      end;
      // Clear the error log so that we don't receive the same messages again
      pdf.ClearErrorLog;
      // Generate an error event so that the application can process the error messages.
      // Let the function return and don't use SendMessage() to generate the error event.
      Windows.PostMessage(canvas.Handle, WM_DISPLAYERRORS, 0, 0);
   except
      Result := -1;
   end;
end;

procedure TPDFCanvas.CreateParams(var Params: TCreateParams);
begin
   inherited CreateParams(Params);
   Params.Style             := Params.Style or WS_HSCROLL or WS_VSCROLL;
   Params.WindowClass.style := Params.WindowClass.style and not (CS_PARENTDC or CS_CLASSDC) or CS_OWNDC or CS_VREDRAW or CS_HREDRAW; // We need a private dc and we need resize events
end;

{
   // In the FormCreate event the application must check whether the InitError string is set. If this is the case then
   // we have no valid PDF instance in memory and the application should either be terminated or all PDF related functions
   // must be be disabled.
   // Example:
   if PDFCanvas.InitError <> '' then begin
      // Display the error messaage and terminate
      MessageDlg(PDFCanvas.InitError, mtError, [mbOK], 0);
      Application.Terminate;
      Exit;
   end;
}
constructor TPDFCanvas.Create(AOwner: TComponent);
begin
   inherited;
   FAutoScroll      := true;
   BevelOuter       := bvNone;
   FBackColor       := $303030;
   FColorManagement := true;
   FErrMaxCount     := 100;
   FRedraw          := true;
   FScrollWindow    := true;
   Screen.Cursors[crHandNormal] := LoadCursor(hInstance,'HAND_NORMAL');
   Screen.Cursors[crHandClosed] := LoadCursor(hInstance,'HAND_CLOSED');
   Cursor := crArrow;
   SystemParametersInfo(SPI_GETWHEELSCROLLLINES, 0, FWheelLines, 0);
   if FWheelLines < 1 then FWheelLines := 3;
   // Delphi enables floating point exceptions and this conflicts with the C++ exception handling of LumasPDF.
   SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
   Set8087CW($133f);
end;

procedure TPDFCanvas.AddError(ErrMessage: String);
begin
   if FErrors.Count + 1 <= MaxErrCount then begin
      FErrors.Add(ErrMessage);
      if Assigned(FOnError) then FOnError(Self);
   end;
end;

procedure TPDFCanvas.CloseFile;
begin
   FCache.CloseFile;
   FErrors.Clear;
   Cursor     := crArrow;
   FFirstPage := 0;
   FPageCount := 0;
   DisableScrollBars;
   InvalidateRect(FHandle, nil, false);
end;

destructor TPDFCanvas.Destroy;
begin
   if FCache  <> nil then FreeAndNil(FCache);
   if FErrors <> nil then FreeAndNil(FErrors);
   if FPDF    <> nil then FreeAndNil(FPDF);
  inherited;
end;

procedure TPDFCanvas.DisableScrollBars;
var si: TScrollInfo;
begin
   FillChar(si, sizeof(si), 0);
   si.cbSize := sizeof(si);
   si.fMask  := SIF_ALL;
   SetScrollPos(true, 0, false);
   SetScrollPos(false, 0, false);
   SetScrollInfo(FHandle, SB_HORZ, si, true);
   SetScrollInfo(FHandle, SB_VERT, si, true);
   ShowScrollBar(FHandle, SB_VERT, true);
   ShowScrollBar(FHandle, SB_HORZ, true);
   EnableScrollBar(FHandle, SB_VERT, ESB_DISABLE_BOTH);
   EnableScrollBar(FHandle, SB_HORZ, ESB_DISABLE_BOTH);
end;

procedure TPDFCanvas.DisplayFirstPage;
begin
   ScrollTo(FFirstPage);
end;

function TPDFCanvas.ExecBookmark(Index: Cardinal): TUpdBmkAction;
var x, y, max, small, large: Integer; z: Single; ps: TPDFPageScale;
begin
   FOldPage := 0;
   Result := FCache.ExecBookmark(Index, x, y, z, ps, nil);
   if (Result and ubaOpenPage) = ubaOpenPage then begin
      if (Result and ubaZoom) = ubaZoom then begin
         FCache.Zoom(z * 72.0 / FResolution, x, y);
         FZoomMode := true;
         FCache.GetScrollRange(true, max, small, large);
         SetScrollPos(true, y, true);
         if FCache.GetScrollRange(false, max, small, large) then begin
            InitScrollBar(false, max, small, large);
            SetScrollPos(false, x, true);
         end else begin
            SetScrollPos(false, 0, true);
            EnableScrollBar(FHandle, SB_HORZ, ESB_DISABLE_BOTH);
         end;
      end else begin
         if (Result and ubaPageScale) = ubaPageScale then begin
            if FZoomMode or (ps <> FCache.GetPageScale) then begin
               FZoomMode := false;
               FCache.SetPageScale(ps);
               UpdateScrollBarsEx;
            end;
         end;
         SetScrollPos(true, y, true);
         SetScrollPos(false, x, true);
      end;
   end; 
   InvalidateRect(FHandle, nil, false);
end;

function TPDFCanvas.GetDC: HDC;
begin
   Result := Windows.GetDC(FHandle);
end;

function TPDFCanvas.GetRotate: Integer;
begin
   Result := FCache.GetRotate;
end;

function TPDFCanvas.GetDefPageLayout: TPageLayout;
begin
   Result := FCache.GetDefPageLayout;
end;

function TPDFCanvas.GetPageLayout: TPageLayout;
begin
   Result := FCache.GetPageLayout;
end;

function TPDFCanvas.GetPageMatrix(CursorX, CursorY: Integer; var DestX, DestY, Width, Height: Integer; var Matrix: TCTM): Integer;
begin
   Result := FCache.GetPageMatrix(CursorX, CursorY, DestX, DestY, Width, Height, Matrix);
end;

function TPDFCanvas.GetPageScale: TPDFPageScale;
begin
   Result := FCache.GetPageScale;
end;

function TPDFCanvas.GetScrollLineDelta(Vertical: Boolean): Cardinal;
begin
   Result := FCache.GetScrollLineDelta(Vertical);
end;

function TPDFCanvas.GetScrollPos(Vertical: Boolean): Integer;
var si: TScrollInfo;
begin
   si.cbSize := sizeof(si);
   si.fMask  := SIF_POS;
   si.nPos   := 0;
   if Vertical then
      GetScrollInfo(FHandle, SB_VERT, si)
   else
      GetScrollInfo(FHandle, SB_HORZ, si);
   Result := si.nPos;
end;

function TPDFCanvas.InitBaseObjects(Flags: TInitCacheFlags): Boolean;
var max, small, large: Integer;
begin
   Result   := false;
   FHavePos := false;
   if FCache = nil then Exit;
   FErrors.Clear;
   FOldPage    := 0;
   FZoomMode   := false;
   FPageCount  := FPDF.GetInPageCount;
   FFirstPage  := FCache.InitBaseObjects(FWidth, FHeight, Flags);
   FScrollLine := 120 * FWheelLines * 96 div FResolution;
   if (FFirstPage < 1) or (FPageCount < 1) then Exit;
   FCache.SetScrollLineDelta(true, FScrollLine);
   if FAutoScroll then begin
      FCache.GetScrollRange(true, max, small, large);
      InitScrollBar(true, max, small, large);
      InitScrollBar(false, 0, 0, 0);
      small := FCache.GetScrollPos(true, FFirstPage);
      SetScrollPos(true, small, true);
   end;
   Cursor := crHandNormal;
   Result := true;
end;

procedure TPDFCanvas.InitScrollBar(Vertical: Boolean; Max, SmallChange, LargeChange: Integer);
var si: TScrollInfo;
begin
   si.cbSize := sizeof(si);
   si.fMask  := SIF_POS or SIF_RANGE or SIF_PAGE or SIF_DISABLENOSCROLL;
   si.nMin   := 0;
   si.nMax   := Max;
   si.nPage  := LargeChange;
   si.nPos   := 0;
   if Vertical then begin
      FScrollVMax := Max - LargeChange + 1;
      SetScrollInfo(Handle, SB_VERT, si, false)
   end else
      SetScrollInfo(Handle, SB_HORZ, si, false);
end;

procedure TPDFCanvas.Loaded;
var dc: HDC;
begin
   inherited;
   if (FPDF <> nil) or (csDesigning in ComponentState) then Exit;
   try
      HandleNeeded;
      FHandle := WindowHandle;
      FPDF := TPDF.Create;

      FPDF.SetErrorMode(FPDF.GetErrorMode() or emUseErrLog);
      // Min version 4.0.53.147
      if FPDF.GetLumasPDFVersionInt() < 40200000 then raise Exception.Create(Format('Wrong LumasPdf.dll version!'#10'Found %s'#10'Require 4.2.0 or higher', [FPDF.GetLumasPDFVersion]));
      FPDF.SetOnErrorProc(Self, @PDFErrProc);
   
      dc          := GetDC;
      FResolution := GetDeviceCaps(dc, LOGPIXELSX);
      ReleaseDC(FHandle, dc);
      // Palette colors like clBackground are not supported!
      FCache  := TPDFPageCache.Create(FPDF, pxfBGRA, 4, 8, Cardinal(FBackColor), ttpLowest);
      FErrors := TStringList.Create;
   except
      on E: Exception do begin
         FInitError := E.Message;
         Exit;
      end;
   end;
   if FResolution < 72 then FResolution := 72;
end;

procedure TPDFCanvas.Lock;
begin
   if FCache = nil then Exit;
   FCache.Lock;
end;

{
   This callback is excuted from the rendering thread whenever the screen was updated. The rendering
   thread waits until the function returns.
   However, note that the rendering thread calls this function and not the main thread! Be careful
   what you do here since most Delphi components are not necessarily thread-safe.
   If you want to draw additional controls on the canvas then draw them in the OnAfterUpdateScreen event.
   The provided dc is the one of the PDFCanvas. This is a private device context. Changes made on this dc
   are not restored among paint events! So, make sure that you restore important changes, e.g. the coordinate
   system or clipping region if necessary.
}
function OnUpdateWindow(const Data: Pointer; var Area: TIntRect): Integer; stdcall;
var canvas: TPDFCanvas;
begin
   Result := 0;
   canvas := TPDFCanvas(Data);
   if Assigned(canvas.OnAfterUpdateScreen) then
      canvas.OnAfterUpdateScreen(canvas, canvas.GetDC(), Area);
end;

procedure TPDFCanvas.ProcessErrors(UpdateWindow: Boolean);
begin
   // If we have errors in the pipe then ProcessErrors() stops the rendering thread and calls then
   // the error callback function so that we can safely access the error log. If the return value
   // is true then the error callback function was called and the rendering thread was stopped.
   if FCache.ProcessErrors and UpdateWindow then
      InvalidateRect(FHandle, nil, false);
end;

procedure TPDFCanvas.Redraw;
begin
   InvalidateRect(FHandle, nil, false);
end;

function TPDFCanvas.Scroll(Vertical: Boolean; ScrollCode: Integer; var ScrollPos, NewPageNum: Integer): Boolean;
var x, y, max, small, large: Integer; retval: TUpdScrollbar;
begin
   if Vertical then begin
      x := GetScrollPos(false);
      y := ScrollPos;
   end else begin
      x := ScrollPos;
      y := GetScrollPos(true);
   end;
   retval := FCache.Scroll(Vertical, ScrollCode, x, y);
   if (retval and usbVertRange) <> 0 then begin
      FCache.GetScrollRange(true, max, small, large);
      InitScrollBar(true, max, small, large);
   end;
   if (retval and usbHorzRange) <> 0 then begin
      FCache.GetScrollRange(false, max, small, large);
      InitScrollBar(false, max, small, large);
   end;
   if (Vertical) then
      ScrollPos := y
   else
      ScrollPos := x;
   NewPageNum := FCache.GetPageAt(x, y, 0, 0);
   Result := retval <> 0;
end;

procedure TPDFCanvas.ScrollTo(PageNum: Integer);
var y: Integer;
begin
   if FCache = nil then Exit;
   y := FCache.GetScrollPos(true, pageNum);
   FCache.ResetMousePos;
   SetScrollPos(true, y, true);
   InvalidateRect(FHandle, nil, false);
end;

procedure TPDFCanvas.SetRotate(Value: Integer);
var pos, max, small, large: Integer;
begin
   // We must update the scroll bars when we rotate the pages
   FOldPage := 0; // Make sure that a NewPage event is raised
   pos := FCache.GetScrollPos(true, FCache.GetCurrPage);
   FCache.SetRotate(Value);
   FCache.GetScrollRange(true, max, small, large);
   FCache.ResetMousePos;
   InitScrollBar(true, max, small, large);
   FCache.GetScrollRange(false, max, small, large);
   InitScrollBar(false, max, small, large);
   SetScrollPos(true, pos, true);
   InvalidateRect(FHandle, nil, false);
end;

procedure TPDFCanvas.SetAutoScroll(Value: Boolean);
begin
   FAutoScroll := Value;
   if not FAutoScroll then begin
      ShowScrollBar(FHandle, SB_VERT, false);
      ShowScrollBar(FHandle, SB_HORZ, false);
   end else begin
      ShowScrollBar(FHandle, SB_VERT, true);
      ShowScrollBar(FHandle, SB_HORZ, true);
   end;
   EnableScrollBar(FHandle, SB_VERT, ESB_DISABLE_BOTH);
   EnableScrollBar(FHandle, SB_HORZ, ESB_DISABLE_BOTH);
end;

procedure TPDFCanvas.SetBackColor(Color: TColor);
begin
   FBackColor := Color;
   if FCache <> nil then FCache.ChangeBackColor(Cardinal(Color));
   InvalidateRect(FHandle, nil, false);
end;

procedure TPDFCanvas.SetDefPageLayout(Value: TPageLayout);
begin
   FCache.SetDefPageLayout(Value);
end;

function TPDFCanvas.SetOCGState(Handle: Cardinal; Visible, SaveState: Boolean): Boolean;
begin
   Result := FCache.SetOCGState(Handle, Visible, SaveState);
   if Result then InvalidateRect(FHandle, nil, false);
end;

procedure TPDFCanvas.SetPageLayout(Value: TPageLayout);
var pos: Integer;
begin
   if Value <> FCache.GetPageLayout then begin
      FCache.SetPageLayout(Value);
      if Value = plSinglePage then begin
         FCache.ResetMousePos;
         pos := FCache.GetScrollPos(true, FCache.GetCurrPage);
         SetScrollPos(true, pos, true);
      end;
      InvalidateRect(FHandle, nil, false);
   end;
end;

procedure TPDFCanvas.SetPageScale(Value: TPDFPageScale);
begin
   if FZoomMode or (Value <> FCache.GetPageScale) then begin
      FOldPage  := 0;
      FZoomMode := false;
      FCache.SetPageScale(Value);
      FCache.ResetMousePos;
      UpdateScrollBars;
   end;
end;

function TPDFCanvas.SetScrollLineDelta(Vertical: Boolean; Value: Cardinal): Boolean;
var y, max, small, large: Integer;
begin
   y           := GetScrollPos(true);
   FScrollLine := Integer(Value) * FWheelLines * FResolution div 120;
   Result      := FCache.SetScrollLineDelta(Vertical, FScrollLine);
   if Result then begin
      FCache.GetScrollRange(true, max, small, large); 
      InitScrollbar(true, max, small, large);
      SetScrollPos(true, y, true);
   end;
end;

procedure TPDFCanvas.SetScrollPos(Vertical: Boolean; NewPos: Integer; RedrawScrollBar: Boolean);
var si: TScrollInfo;
begin
   si.cbSize := sizeof(si);
   si.fMask  := SIF_POS;
   si.nPos   := NewPos;
   if Vertical then
      SetScrollInfo(FHandle, SB_VERT, si, RedrawScrollBar)
   else
      SetScrollInfo(FHandle, SB_HORZ, si, RedrawScrollBar);
   FRedraw := true;
end;

procedure TPDFCanvas.SetThreadPriority(UpdateThread, RenderThread: TPDFThreadPriority);
begin
   if FCache <> nil then FCache.SetThreadPriority(UpdateThread, RenderThread);
end;

procedure TPDFCanvas.UnLock;
begin
   FCache.UnLock;
   InvalidateRect(FHandle, nil, false);
end;

procedure TPDFCanvas.UpdateCache(PageNum: Integer);
begin
   FCache.Update(PageNum);
   InvalidateRect(FHandle, nil, false);
end;

procedure TPDFCanvas.UpdateScrollBars;
var pageNum: Integer;
begin
   pageNum := FCache.GetCurrPage;
   UpdateScrollBarsEx;
   SetScrollPos(false, 0, true);
   ScrollTo(pageNum);
end;

procedure TPDFCanvas.UpdateScrollBarsEx;
var max, small, large: Integer;
begin
   FCache.GetScrollRange(true, max, small, large);
   InitScrollBar(true, max, small, large);
   FCache.GetScrollRange(false, max, small, large);
   InitScrollBar(false, max, small, large);
end;

procedure TPDFCanvas.WMButtonLDown(var Msg: TWMMouse);
begin
   SetFocus;
   if FPageCount = 0 then
      Cursor := crArrow
   else begin
      FHavePos := true;
      case FCache.MouseDown(Msg.XPos, Msg.YPos) of
         pcrHandClosed: Cursor := crHandClosed;
         pcrHandPoint:  Cursor := crHandPoint;
      end;
   end;
   if Assigned(FOnMouseDown) then
      FOnMouseDown(Self, mbLeft, KeysToShiftState(Msg.Keys), Msg.XPos, Msg.YPos)
end;

procedure TPDFCanvas.WMButtonLUp(var Msg: TWMMouse);
begin
   FHavePos := false;
   if FPageCount = 0 then
      Cursor := crArrow
   else
      Cursor := crHandNormal;
   if Assigned(FOnMouseUp) then
      FOnMouseUp(Self, mbLeft, KeysToShiftState(Msg.Keys), Msg.XPos, Msg.YPos)
end;

procedure TPDFCanvas.WMEraseBackground(var Msg: TMessage);
begin
   FRedraw    := true;
   Msg.Result := 1;
end;

procedure TPDFCanvas.WMError(var Msg: TMessage);
begin
   if Assigned(FOnError) then begin
      if FErrors.Count > 0 then FOnError(Self);
   end;
end;

procedure TPDFCanvas.WMHandleDlgCode(var Msg: TMessage);
var M: PMsg;
begin
   Msg.Result := DLGC_WANTARROWS;
   if Msg.lParam <> 0 then begin
      M := PMsg(Msg.lParam);
      case M.message of
         WM_KEYDOWN, WM_KEYUP, WM_CHAR: begin
            Perform(M.message, M.wParam, M.lParam);
            Msg.Result := Msg.Result or DLGC_WANTMESSAGE or CM_COLORCHANGED;
         end;
      end;
   end else
      Msg.Result := Msg.Result or DLGC_WANTMESSAGE;
end;

procedure TPDFCanvas.WMKeyDown(var Msg: TWMKey);
var pos: Integer; shiftState: TShiftState; scale: single;
begin
   if FCache = nil then Exit;
   shiftState := KeyDataToShiftState(Msg.KeyData);
   if shiftState = [] then begin
      case Msg.CharCode of
         VK_DOWN:  SendMessage(FHandle, WM_VSCROLL, SB_LINEDOWN, 0);
         VK_UP:    SendMessage(FHandle, WM_VSCROLL, SB_LINEUP, 0);
         VK_RIGHT: SendMessage(FHandle, WM_HSCROLL, SB_LINELEFT, 0);
         VK_LEFT:  SendMessage(FHandle, WM_HSCROLL, SB_LINERIGHT, 0);
         // Note that the scroll messages SB_PAGEUP or SB_PAGEDOWN scroll maybe more than one page up or down. So, we use
         // the scroll message only if the file contains one page. Otherwise we calculate the scroll position and scroll
         // one page forward or backward as needed.
         VK_PRIOR: begin
            if FCache.GetCurrPage > 1 then begin
               pos := FCache.GetScrollPos(true, FCache.GetCurrPage - 1);
               SetScrollPos(true, pos, true);
               InvalidateRect(FHandle, nil, false);
            end else
               SendMessage(FHandle, WM_VSCROLL, SB_PAGEUP, 0);
         end;
         VK_NEXT: begin
            if FCache.GetCurrPage < FPageCount then begin
               pos := FCache.GetScrollPos(true, FCache.GetCurrPage + 1);
               SetScrollPos(true, pos, true);
               InvalidateRect(FHandle, nil, false);
            end else
               SendMessage(FHandle, WM_VSCROLL, SB_PAGEDOWN, 0);
         end;
         VK_HOME: begin
            FCache.ResetMousePos;
            pos := FCache.GetScrollPos(true, 1);
            SetScrollPos(true, pos, true);
            InvalidateRect(FHandle, nil, false);
         end;
         VK_END: begin
            FCache.ResetMousePos;
            if FPageCount > 1 then
               pos := FCache.GetScrollPos(true, FPageCount)
            else
               pos := FScrollVMax;
            SetScrollPos(true, pos, true);
            InvalidateRect(FHandle, nil, false);
         end;
         VK_OEM_PLUS: begin
            scale := FCache.GetCurrZoom * 72.0 / Resolution * 1.25;
            Zoom(scale * Resolution / 72.0);
         end;
         VK_OEM_MINUS: begin
            scale := FCache.GetCurrZoom * 72.0 / Resolution * 0.75;
            Zoom(scale * Resolution / 72.0);
         end;
      end;
      Msg.Result := 1;
      if Assigned(OnKeyDown) then
         OnKeyDown(Self, Msg.CharCode, shiftState)
   end else begin
      if Assigned(OnKeyDown) then begin
         Msg.Result := 1;
         OnKeyDown(Self, Msg.CharCode, shiftState);
      end;
   end;
end;

procedure TPDFCanvas.WMMouseMove(var Msg: TWMMouseMove);
var sx, sy, max, small, large: Integer; retval: TUpdScrollbar;
begin
   Msg.Result := 0;
   if (FPageCount > 0) and FHavePos then begin
      if Msg.Keys = 0 then begin
         sx := GetScrollPos(false);
         sy := GetScrollPos(true);
         retval := FCache.MouseMove(0, false, sx, sy, Msg.XPos, Msg.YPos);
         case (retval and usbCursorMask) of
            usbCursorHandNormal: Cursor := crHandNormal;
            usbCursorHandClosed: Cursor := crHandClosed;
            usbCursorHandPoint:  Cursor := crHandPoint;
            usbCursorIBeam:      Cursor := crIBeam;
         end;
      end else if Msg.Keys = MK_LBUTTON then begin
         sx := GetScrollPos(false);
         sy := GetScrollPos(true);
         if FScrollWindow then
            retval := FCache.MouseMove(FHandle, true, sx, sy, Msg.XPos, Msg.YPos)
         else
            retval := FCache.MouseMove(0, true, sx, sy, Msg.XPos, Msg.YPos);
         if (retval and usbVertRange) <> 0 then begin
            FCache.GetScrollRange(true, max, small, large);
            InitScrollBar(true, max, small, large);
         end;
         if (retval and usbHorzRange) <> 0 then begin
            FCache.GetScrollRange(false, max, small, large);
            InitScrollBar(false, max, small, large);
         end;
         case (retval and usbCursorMask) of
            usbCursorHandNormal: Cursor := crHandNormal;
            usbCursorHandClosed: Cursor := crHandClosed;
            usbCursorHandPoint:  Cursor := crHandPoint;
            usbCursorIBeam:      Cursor := crIBeam;
         end;
         if not FScrollWindow then InvalidateRect(FHandle, nil, false);
         SetScrollPos(false, sx, true);
         SetScrollPos(true, sy, true);
      end;
   end;
   if Assigned(FOnMouseMove) then
      FOnMouseMove(Self, KeysToShiftState(Msg.Keys), Msg.XPos, Msg.YPos)
end;

procedure TPDFCanvas.WMMouseWheel(var Msg: TCMMouseWheel);
var x, y, gap, max, smallChange, largeChange, newX, newY: Integer; scale: Single; update: TUpdScrollbar;
begin
   if FCache = nil then Exit;
   if ssCtrl in Msg.ShiftState then begin
      scale := FCache.GetCurrZoom;
      if Msg.WheelDelta < 0 then
         scale := scale / -(Msg.WheelDelta div FResolution)
      else
         scale := scale * (Msg.WheelDelta div FResolution);
      if FCache.Zoom(scale, newX, newY) then begin
         FZoomMode := true;
         FCache.GetScrollRange(true, max, smallChange, largeChange);
         InitScrollBar(true, max, smallChange, largeChange);
         SetScrollPos(true, newY, true);
         if FCache.GetScrollRange(false, max, smallChange, largeChange) then begin
            InitScrollBar(false, max, smallChange, largeChange);
            SetScrollPos(false, newX, true);
         end else
            EnableScrollBar(FHandle, SB_HORZ, ESB_DISABLE_BOTH);
      end;
   end else begin
      if (FCache.GetPageScale = psFitBest) and (FCache.GetPageLayout = plSinglePage) then begin
         FCache.GetScrollRange(true, max, smallChange, largeChange);
         gap := smallChange;
         x   := GetScrollPos(false);
         if Msg.WheelDelta < 0 then
            y := GetScrollPos(true) + gap
         else
            y := GetScrollPos(true) - gap;
      end else begin
         scale := 1.5 / FCache.GetCurrZoom;
         gap   := Trunc((Msg.WheelDelta * FScrollLine div 120) * scale);
         x     := GetScrollPos(false);
         y     := GetScrollPos(true) - gap;
      end;
      if y < 0 then y := 0;
      update := FCache.Scroll(true, SB_THUMBPOSITION, x, y);
      if update and usbVertRange = usbVertRange then begin
         FCache.GetScrollRange(true, max, smallChange, largeChange);
         InitScrollBar(true, max, smallChange, largeChange);
      end;
      if update and usbHorzRange = usbHorzRange then begin
         FCache.GetScrollRange(false, max, smallChange, largeChange);
         InitScrollBar(false, max, smallChange, largeChange);
      end;
      SetScrollPos(true, y, update <> 0);
   end;
   InvalidateRect(FHandle, nil, false);
end;

procedure TPDFCanvas.WMPaint(var Msg: TMessage);
var x, y, max, small, large, pageNum: Integer; retval: TUpdScrollbar; dc: HDC; ps: TPaintStruct; r: TRect;
begin
   {
      The drawing speed on Windows 7 is very limited because Microsoft changed the way how SetDIBitsToDevice()
      copies a bitmap into the video buffer. The function works now mostly without hardware acceleration and
      this makes it of course incredible slow. The new way to copy a bitmap into the video buffer is Direct2D.
      The usage is more than complicated and a lot of compatibility problems must be taken into account. Maybe
      Direct2D will be supported in future, or LumasPDF will provide API functions to enable the usage of arbitrary
      blend functions.
   }
   if FCache <> nil then begin
      FillChar(ps, sizeof(ps), 0);
      dc := BeginPaint(FHandle, ps);
      if ps.fErase or FRedraw then begin
         x := GetScrollPos(false);
         y := GetScrollPos(true);
         retval  := FCache.Paint(dc, x, y);
         pageNum := FCache.GetCurrPage;
         if retval <> usbNoUpdate then begin
            if (retval and usbVertRange) <> 0 then begin
               FCache.GetScrollRange(true, max, small, large);
               InitScrollBar(true, max, small, large);
            end;
            if (retval and usbHorzRange) <> 0 then begin
               FCache.GetScrollRange(false, max, small, large);
               InitScrollBar(false, max, small, large);
               SetScrollPos(false, x, true);
             end else begin
               SetScrollPos(false, 0, false);
               EnableScrollBar(FHandle, SB_HORZ, ESB_DISABLE_BOTH);
            end;
            SetScrollPos(true, y, true);
         end;
         EndPaint(FHandle, ps);
         if Assigned(FOnPaint) then FOnPaint(Self, dc, pageNum);
         if FOldPage <> pageNum then begin
            FOldPage := pageNum;
            if Assigned(FOnNewPage) then FOnNewPage(Self, pageNum);
         end;
      end else
         EndPaint(FHandle, ps);
   end else begin
      dc := BeginPaint(FHandle, ps);
      if ps.fErase or FRedraw then begin
         SetBkColor(dc, Cardinal(FBackColor));
         r := ClientRect;
         ExtTextOut(dc, 0, 0, ETO_OPAQUE, @r, nil, 0, nil);
         if Assigned(FOnPaint) then FOnPaint(Self, dc, 0);
      end;
      EndPaint(FHandle, ps);
   end;
   FRedraw := false;
end;

procedure TPDFCanvas.WMResize(var Msg: TMessage);
var max, small, large, page, pos: Integer; saved: TPDFPageCache;
begin
   FWidth  := LOWORD(Msg.lParam);
   FHeight := HIWORD(Msg.lParam);
   if FHeight > 0 then begin
      FHandle := WindowHandle;
      if not FInitialized then begin
         FInitialized := true;
         if FAutoScroll then begin
            ShowScrollBar(FHandle, SB_VERT, true);
            ShowScrollBar(FHandle, SB_HORZ, true);
            EnableScrollBar(FHandle, SB_VERT, ESB_DISABLE_BOTH);
            EnableScrollBar(FHandle, SB_HORZ, ESB_DISABLE_BOTH);
         end else begin
            // Hidding the scrollbars causes two new resize events.
            saved  := FCache;
            FCache := nil;
            ShowScrollBar(FHandle, SB_VERT, false);
            ShowScrollBar(FHandle, SB_HORZ, false);
            FCache := saved;
         end;
      end;
      if FCache <> nil then begin
         FOldPage := 0;
         page     := FCache.GetCurrPage;
         FCache.Resize(FWidth, FHeight);
         // If AutoScroll is disabled then you must initialize your scroll bars in the very same way in
         // the OnResize event.
         if FAutoScroll then begin
            pos := FCache.GetScrollPos(true, page);
            FCache.GetScrollRange(true, max, small, large);
            InitScrollBar(true, max, small, large);
            SetScrollPos(true, pos, true);
            FCache.GetScrollRange(false, max, small, large);
            InitScrollBar(false, max, small, large);
         end;
         if Assigned(FOnResize) then
            FOnResize(Self);
      end;
   end else if csDesigning in ComponentState then begin
      FHandle := WindowHandle;
      SetAutoScroll(FAutoScroll);
   end;
end;

procedure TPDFCanvas.WMScrollHorz(var Msg: TMessage);
var code, pos, pageNum: Integer; si: TScrollInfo; update: Boolean;
begin
   if FCache = nil then Exit;
   if FAutoScroll then begin
      pos          := 0;
      si.cbSize    := sizeof(si);
      si.fMask     := SIF_ALL;
      si.nTrackPos := 0;
      code         := LOWORD(Msg.wParam);
      GetScrollInfo(FHandle, SB_HORZ, si);
      case code of
         SB_BOTTOM:        pos := si.nMax - (Integer(si.nPage) - 1);
         SB_TOP:           pos := 0;
         SB_LINEDOWN:      pos := si.nPos;
         SB_LINEUP:        pos := si.nPos;
         SB_PAGEDOWN:      pos := si.nPos;
         SB_PAGEUP:        pos := si.nPos;
         SB_THUMBTRACK:    pos := si.nTrackPos;
         SB_THUMBPOSITION: pos := si.nPos;
         SB_ENDSCROLL:     Exit; // can be ignored
      else
         pos := si.nPos;
      end;
      update := Scroll(false, code, pos, pageNum);
      SetScrollPos(false, pos, update);
      if Assigned(FOnScroll) then
         FOnScroll(Self, false, code, pos, pageNum);
      InvalidateRect(FHandle, nil, false);
   end;
end;

procedure TPDFCanvas.WMScrollVert(var Msg: TMessage);
var code, pos, pageNum: Integer; si: TScrollInfo; update: Boolean;
begin
   if FCache = nil then Exit;
   if FAutoScroll then begin
      pos          := 0;
      si.cbSize    := sizeof(si);
      si.fMask     := SIF_ALL;
      si.nTrackPos := 0;
      code         := LOWORD(Msg.wParam);
      GetScrollInfo(FHandle, SB_VERT, si);
      case code of
         SB_BOTTOM:        pos := si.nMax - (Integer(si.nPage) - 1);
         SB_TOP:           pos := 0;
         SB_LINEDOWN:      pos := si.nPos;
         SB_LINEUP:        pos := si.nPos;
         SB_PAGEDOWN:      pos := si.nPos;
         SB_PAGEUP:        pos := si.nPos;
         SB_THUMBTRACK:    pos := si.nTrackPos;
         SB_THUMBPOSITION: pos := si.nPos;
         SB_ENDSCROLL:     pos := si.nPos;
      else
         pos := si.nPos;
      end;
      update := Scroll(true, code, pos, pageNum);
      SetScrollPos(true, pos, update);
      if Assigned(FOnScroll) then
         FOnScroll(Self, true, code, pos, pageNum);
      InvalidateRect(FHandle, nil, false);
   end;
end;

procedure TPDFCanvas.Zoom(Value: Single);
var x, y, max, small, large: Integer;
begin
   x := GetScrollPos(false);
   y := GetScrollPos(true);
   FCache.Zoom(Value, x, y);
   FCache.GetScrollRange(true, max, small, large);
   InitScrollBar(true, max, small, large);
   SetScrollPos(true, y, true);
   if FCache.GetScrollRange(false, max, small, large) then begin
      InitScrollBar(false, max, small, large);
      SetScrollPos(false, x, true);
   end else begin
      SetScrollPos(false, 0, true);
      EnableScrollBar(FHandle, SB_HORZ, ESB_DISABLE_BOTH);
   end;
   FOldPage  := 0;
   FZoomMode := true;
   InvalidateRect(FHandle, nil, false);
end;

end.

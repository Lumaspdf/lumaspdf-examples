unit Unit1;

interface

uses
  Windows, Messages, SysUtils, StrUtils, Variants, Classes, Graphics, Controls, Forms,
  CommDlg, Menus, LumasPdfApi, StdCtrls, ImgList, ExtCtrls, ToolWin, frmPassword,
  frmStatistic, frmErrLog, frmAbout, SyncObjs, ActnList, ActnCtrls, ActnMan, ActnMenus,
  StdActns, pdfcontrol, ComCtrls, CustomizeDlg, Dialogs,
  XPStyleActnCtrls, PlatformDefaultStyleActnCtrls, System.Actions, System.ImageList, System.UITypes;

type TBmk = record
   BmkIndex:   Integer;
   Flags:      Cardinal;
   ChildCount: Integer;
   Parent:     TTreeNode;
   PrntIndex:  Integer;
end;

type PBmk = ^TBmk;
  
type
  TForm1 = class(TForm)
    ImageList: TImageList;
    Splitter: TSplitter;
    ActionManager: TActionManager;
    ActionFileOpen: TAction;
    ActionFileClose: TAction;
    ActionFileExit: TAction;
    ActionZoomFitBest: TAction;
    ActionZoomFitWidth: TAction;
    ActionZoomFitHeight: TAction;
    PageControl: TPageControl;
    TabBookmarks: TTabSheet;
    TabLayers: TTabSheet;
    TreeBookmarks: TTreeView;
    TreeLayers: TTreeView;
    ActionViewContinous: TAction;
    ActionViewSingle: TAction;
    ActionPDFStatistic: TAction;
    ActionPDFErrors: TAction;
    ActionAbout: TAction;
    ActionViewBookmarks: TAction;
    ActionViewLayers: TAction;
    ActionZoomIn: TAction;
    ActionZoomOut: TAction;
    ActionMainMenuBar1: TActionMainMenuBar;
    ToolBar1: TToolBar;
    BtnFitWidth: TToolButton;
    BtnFitBest: TToolButton;
    BtnFitHeight: TToolButton;
    ToolButton1: TToolButton;
    BtnViewContinous: TToolButton;
    BtnViewSinglePage: TToolButton;
    ToolButton2: TToolButton;
    Panel1: TPanel;
    LblCurrPage: TLabel;
    EdtPageNum: TEdit;
    LblPageCount: TLabel;
    BtnErrors: TToolButton;
    BtnZoomOut: TToolButton;
    BtnZoomIn: TToolButton;
    CbZoom: TComboBox;
    Panel2: TPanel;
    Panel3: TPanel;
    OpenDialog: TOpenDialog;
    ActionCustomPageLayout: TAction;
    ActionNoOpenAction: TAction;
    PDFCanvas: TPDFCanvas;
    BtnRotate90: TToolButton;
    BtnRotateM90: TToolButton;
    ActionRotate90: TAction;
    ActionRotateM90: TAction;
    ActionRotate180: TAction;
    ActionRotate0: TAction;
    BtnRotate180: TToolButton;
    ToolButton3: TToolButton;
    ToolBar2: TToolBar;
    BtnExpandBmks: TToolButton;
    BtnCollapseBmks: TToolButton;
    BtnHidePanel1: TToolButton;
    ToolBar3: TToolBar;
    BtnExpandLayers: TToolButton;
    BtnCollapseLayers: TToolButton;
    BtnHidePanel2: TToolButton;
    ScrollDelta10: TAction;
    ScrollDelta30: TAction;
    ScrollDelta60: TAction;
    ScrollDelta120: TAction;
    ScrollDelta180: TAction;
    ScrollDelta240: TAction;
    procedure ActionAboutExecute(Sender: TObject);
    procedure ActionCustomPageLayoutExecute(Sender: TObject);
    procedure ActionFileCloseExecute(Sender: TObject);
    procedure ActionFileExitExecute(Sender: TObject);
    procedure ActionFileOpenExecute(Sender: TObject);
    procedure ActionNoOpenActionExecute(Sender: TObject);
    procedure ActionPDFErrorsExecute(Sender: TObject);
    procedure ActionRotate90Execute(Sender: TObject);
    procedure ActionRotateM90Execute(Sender: TObject);
    procedure ActionRotate180Execute(Sender: TObject);
    procedure ActionRotate0Execute(Sender: TObject);
    procedure ActionViewBookmarksExecute(Sender: TObject);
    procedure ActionViewContinousExecute(Sender: TObject);
    procedure ActionViewLayersExecute(Sender: TObject);
    procedure ActionViewSingleExecute(Sender: TObject);
    procedure ActionZoomFitBestExecute(Sender: TObject);
    procedure ActionZoomFitWidthExecute(Sender: TObject);
    procedure ActionZoomFitHeightExecute(Sender: TObject);
    procedure ActionZoomInExecute(Sender: TObject);
    procedure ActionZoomOutExecute(Sender: TObject);
    procedure CbZoomChange(Sender: TObject);
    procedure EdtPageNumKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PDFCanvasError(Sender: TObject);
    procedure PDFCanvasNewPage(Sender: TObject; NewPage: Integer);

    procedure TabBookmarksShow(Sender: TObject);
    procedure TreeBookmarksChange(Sender: TObject; Node: TTreeNode);
    procedure TreeBookmarksCustomDrawItem(Sender: TCustomTreeView; Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure TreeBookmarksExpanding(Sender: TObject; Node: TTreeNode; var AllowExpansion: Boolean);
    procedure BtnHidePanel1Click(Sender: TObject);
    procedure BtnExpandBmksClick(Sender: TObject);
    procedure BtnCollapseBmksClick(Sender: TObject);
    procedure BtnExpandLayersClick(Sender: TObject);
    procedure BtnCollapseLayersClick(Sender: TObject);
    procedure ScrollDeltaChange(Sender: TObject);
  private
    FBookmarkCount: Integer;
    FBookmarks:     Array of TBmk;
    FCache:         TPDFPageCache;
    FOpenFlags:     TInitCacheFlags;
    FPDF:           TPDF;
    procedure ClearOutlineTree;
    procedure EnableControls(Enable: Boolean);
    procedure OpenPDFFile(const FileName: String);
    function  RemoveControls(StrPtr: Pointer; Unicode: Boolean): String;
    procedure UnCheckZoomButtons;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

{ ---------------------------------------------------------------------------------------------------- }

// Constants for the outline tree (bookmarks)
const BMK_ITALIC = 1 shl 25;
const BMK_BOLD   = 2 shl 25;
const BMK_OPEN   = 4 shl 25;

procedure TForm1.ActionAboutExecute(Sender: TObject);
begin
   AboutDlg.ShowModal;
end;

procedure TForm1.ActionCustomPageLayoutExecute(Sender: TObject);
begin
   if ActionCustomPageLayout.Checked then
      FOpenFlags := FOpenFlags or icfIgnorePageLayout
   else
      FOpenFlags := FOpenFlags and not icfIgnorePageLayout; 
end;

procedure TForm1.ActionFileCloseExecute(Sender: TObject);
begin
   PDFCanvas.CloseFile;
   ClearOutlineTree;
   LblPageCount.Caption := '0 of 0 ';
   //TreeLayers.Items.Clear;
   EnableControls(false);
   BtnErrors.Visible   := false;
   PageControl.Visible := false;
   Splitter.Visible    := false;
   if not ActionZoomFitWidth.Checked and not ActionZoomFitBest.Checked and not ActionZoomFitHeight.Checked then
      ActionZoomFitWidth.Checked := true;
   if PDFCanvas.DefPageLayout = plSinglePage then
      ActionViewSingle.Checked := true
   else
      ActionViewContinous.Checked := true;
end;

procedure TForm1.ActionFileExitExecute(Sender: TObject);
begin
   Application.Terminate;
end;

procedure TForm1.ActionFileOpenExecute(Sender: TObject);
begin
   if OpenDialog.Execute then begin
      OpenPDFFile(OpenDialog.FileName);
   end;
end;

procedure TForm1.ActionNoOpenActionExecute(Sender: TObject);
begin
   if ActionNoOpenAction.Checked then
      FOpenFlags := FOpenFlags or icfIgnoreOpenAction
   else
      FOpenFlags := FOpenFlags and not icfIgnoreOpenAction;
end;

procedure TForm1.ActionPDFErrorsExecute(Sender: TObject);
var i: Integer; list: TStringList;
begin
   FormErrorLog.Show;
   FormErrorLog.Messages.SetFocus;
   // If the error log of the PDFCanvas is empty then OpenPDFFile added an error
   // message to the error form. In this case display the error log as is.
   if PDFCanvas.ErrorLog.Count > 0 then begin
      FormErrorLog.Messages.Clear;
      list := PDFCanvas.ErrorLog;
      for i := 0 to list.Count - 1 do begin
         FormErrorLog.Messages.Lines.Add(list.Strings[i]);
      end;
   end;
end;

procedure TForm1.ActionRotate90Execute(Sender: TObject);
begin
   PDFCanvas.SetRotate(PDFCanvas.GetRotate + 90);
end;

procedure TForm1.ActionRotateM90Execute(Sender: TObject);
begin
   PDFCanvas.SetRotate(PDFCanvas.GetRotate - 90);
end;

procedure TForm1.ActionRotate180Execute(Sender: TObject);
begin
   PDFCanvas.SetRotate(PDFCanvas.GetRotate + 180);
end;

procedure TForm1.ActionRotate0Execute(Sender: TObject);
begin
   PDFCanvas.SetRotate(0);
end;

procedure TForm1.ActionViewBookmarksExecute(Sender: TObject);
begin
   Splitter.Visible       := true;
   PageControl.Visible    := true;
   PageControl.ActivePage := TabBookmarks;
   TabBookmarksShow(nil);
end;

procedure TForm1.ActionViewContinousExecute(Sender: TObject);
begin
   PDFCanvas.PageLayout     := plOneColumn;
   ActionViewSingle.Checked := false;
   BtnViewSinglePage.Down   := false;
end;

procedure TForm1.ActionViewLayersExecute(Sender: TObject);
begin
   Splitter.Visible       := true;
   PageControl.Visible    := true;
   PageControl.ActivePage := TabLayers;
end;

procedure TForm1.ActionViewSingleExecute(Sender: TObject);
begin
   PDFCanvas.PageLayout     := plSinglePage;
   ActionViewSingle.Checked := true;
   BtnViewSinglePage.Down   := true;
end;

procedure TForm1.ActionZoomFitBestExecute(Sender: TObject);
begin
   PDFCanvas.PageScale := psFitBest;
end;

procedure TForm1.ActionZoomFitHeightExecute(Sender: TObject);
begin
   PDFCanvas.PageScale := psFitHeight;
end;

procedure TForm1.ActionZoomFitWidthExecute(Sender: TObject);
begin
   PDFCanvas.PageScale := psFitWidth;
end;

procedure TForm1.ActionZoomInExecute(Sender: TObject);
var zoom: Single;
begin
   // Consider the resolutiuon of the output device
   zoom := FCache.GetCurrZoom * 72.0 / PDFCanvas.Resolution * 1.25;
   if zoom <= 0.25 then
      zoom := 0.25
   else if zoom <= 0.5 then
      zoom := 0.5
   else if zoom <= 0.75 then
      zoom := 0.75
   else if zoom <= 1.0 then
      zoom := 1.0
   else if zoom <= 1.25 then
      zoom := 1.25
   else if zoom <= 1.5 then
      zoom := 1.5
   else if zoom <= 2.0 then
      zoom := 2.0
   else if zoom <= 3.0 then
      zoom := 3.0
   else if zoom <= 4.0 then
      zoom := 4.0
   else if zoom <= 8.0 then
      zoom := 8.0
   else if zoom <= 16.0 then
      zoom := 16.0
   else if zoom <= 24.0 then
      zoom := 24.0
   else if zoom <= 32.0 then
      zoom := 32.0
   else
      zoom := 64.0;

   CbZoom.Text := Format('%.1n%%', [zoom * 100.0]);
   PDFCanvas.Zoom(zoom * PDFCanvas.Resolution / 72.0);
   // If the zoom factor is large then DynaPDF falls back into zoom mode and this mode works with the
   // page layout plSinglePage. The previous mode will be restored when the zoom factor becomes small
   // enough to render the pages as usual.
   if PDFCanvas.PageLayout = plSinglePage then
      ActionViewSingle.Checked := true;

   UnCheckZoomButtons;
end;

procedure TForm1.ActionZoomOutExecute(Sender: TObject);
var zoom: Single;
begin
   // Consider the resolution of the ouput device
   zoom := FCache.GetCurrZoom * 72.0 / PDFCanvas.Resolution * 100.0;
   // 10% tolerance to avoid rounding errors
   if (zoom > 3550.0) then
      zoom := 32.0
   else if (zoom > 2650.0) then
      zoom := 24.0
   else if (zoom > 1750.0) then
      zoom := 16.0
   else if (zoom > 880.0) then
      zoom := 8.0
   else if (zoom > 440.0) then
      zoom := 4.0
   else if (zoom > 330.0) then
      zoom := 3.0
   else if (zoom > 220.0) then
      zoom := 2.0
   else if (zoom > 165.0) then
      zoom := 1.5
   else if (zoom > 132.5) then
      zoom := 1.25
   else if (zoom > 110.0) then
      zoom := 1.0
   else if (zoom > 82.5) then
      zoom := 0.75
   else if (zoom > 55.0) then
      zoom := 0.5
   else if (zoom > 27.5) then
      zoom := 0.25
   else
      zoom := 0.1;

   CbZoom.Text := Format('%.1n%%', [zoom * 100.0]);
   // The zoom factor that we have calculated is measured in 1/72 inch units.
   // We must multiply the value with the resolution of the output device divided by 72 to get the value we need.
   PDFCanvas.Zoom(zoom * PDFCanvas.Resolution / 72.0);
   // Restore the page layout if necessary
   if PDFCanvas.PageLayout = plOneColumn then begin
      ActionViewContinous.Checked := true;
      BtnViewContinous.Down       := true;
   end;
   UnCheckZoomButtons;
end;

procedure TForm1.BtnCollapseBmksClick(Sender: TObject);
begin
   TreeBookmarks.FullCollapse;
end;

procedure TForm1.BtnCollapseLayersClick(Sender: TObject);
begin
   TreeLayers.FullCollapse;
end;

procedure TForm1.BtnExpandBmksClick(Sender: TObject);
begin
   TreeBookmarks.FullExpand;
end;

procedure TForm1.BtnExpandLayersClick(Sender: TObject);
begin
   TreeLayers.FullExpand;
end;

procedure TForm1.BtnHidePanel1Click(Sender: TObject);
begin
   Splitter.Visible    := false;
   PageControl.Visible := false;
end;

procedure TForm1.CbZoomChange(Sender: TObject);
var zoom: Single;
begin
   case cbZoom.ItemIndex of
      0:  zoom := 0.1;
      1:  zoom := 0.25;
      2:  zoom := 0.5;
      3:  zoom := 0.75;
      4:  zoom := 1.0;
      5:  zoom := 1.25;
      6:  zoom := 1.5;
      7:  zoom := 2.0;
      8:  zoom := 3.0;
      9:  zoom := 4.0;
      10: zoom := 8.0;
      11: zoom := 16.0;
      12: zoom := 24.0;
      13: zoom := 32.0;
      14: zoom := 64.0;
   else
      Exit;
   end;
   // Consider the resolution of the ouput device
   PDFCanvas.Zoom(zoom * PDFCanvas.Resolution / 72.0);
   case PDFCanvas.PageLayout of
      plSinglePage: ActionViewSingle.Checked    := true;
      plOneColumn:  ActionViewContinous.Checked := true;
   end;
   UnCheckZoomButtons;
end;

procedure TForm1.ClearOutlineTree;
begin
   // Warning: The TreeView produces OnChange and OnExpanding events for every node when the items will be deleted!
   // We must disconnect the event functions to avoid errors.
   TreeBookmarks.OnChange    := nil;
   TreeBookmarks.OnExpanding := nil;
   TreeBookmarks.Items.Clear;
   TreeBookmarks.OnChange    := TreeBookmarksChange;
   TreeBookmarks.OnExpanding := TreeBookmarksExpanding;
   if FBookmarkCount > 0 then begin
      SetLength(FBookmarks, 0);
      FBookmarkCount := 0;
   end;
end;

procedure TForm1.EdtPageNumKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
var pageNum: Integer;
begin
   if Key = VK_RETURN then begin
      if EdtPageNum.Text = '' then Exit;
      try
         pageNum := StrToInt(EdtPageNum.Text);
         if pageNum > PDFCanvas.PageCount then
            pageNum := PDFCanvas.PageCount
         else if pageNum < 1 then
            pageNum := 1;

         PDFCanvas.ScrollTo(pageNum);
      except
      end;
   end;
end;

procedure TForm1.EnableControls(Enable: Boolean);
begin
   CbZoom.Enabled              := Enable;
   EdtPageNum.Enabled          := Enable;
   ActionPDFStatistic.Enabled  := Enable;
   ActionViewBookmarks.Enabled := Enable;
   ActionViewContinous.Enabled := Enable;
   ActionViewLayers.Enabled    := Enable;
   ActionViewSingle.Enabled    := Enable;
   ActionRotate0.Enabled       := Enable;
   ActionRotate90.Enabled      := Enable;
   ActionRotateM90.Enabled     := Enable;
   ActionRotate180.Enabled     := Enable;
   ActionZoomFitBest.Enabled   := Enable;
   ActionZoomFitWidth.Enabled  := Enable;
   ActionZoomFitHeight.Enabled := Enable;
   ActionZoomIn.Enabled        := Enable;
   ActionZoomOut.Enabled       := Enable;
end;

procedure TForm1.FormCreate(Sender: TObject);
var profiles: TPDFColorProfiles; dc: HDC; mProfile: PWideChar; size: Cardinal;
begin
   // If the PDFCanvas was not able to load the dynapdf.dll, i.e. when it finds a wrong version, then it sets
   // the InitError string to the last error message. If this string is set then return the error message and
   // terminate the application.
   if PDFCanvas.InitError <> '' then begin
      MessageDlg(PDFCanvas.InitError, mtError, [mbOK], 0);
      Application.Terminate;
      Exit;
   end;
   FCache     := PDFCanvas.CacheInstance;
   FPDF       := PDFCanvas.PDFInstance;
   FOpenFlags := icfIgnoreOpenAction or icfIgnorePageLayout;
   if PDFCanvas.ColorManagement then begin
      // Gray and RGB profiles are automatically created if not provided. The default RGB profile is sRGB.
      // It is possible to set all profiles just to nil. In this case, CMYK colors will only be rendered with
      // color management if the PDF file contains ICCBased color spaces or a CMYK Output Intent.
      // If you want to disable color management (if it was enabled) then set the parameter Profiles to nil, e.g.
      // FCache.InitColorManagement(nil, icmBPCompensation);
      FillChar(profiles, sizeof(profiles), 0);
      profiles.StructSize := sizeof(profiles);
      profiles.DefInCMYKW := PWideChar(WideString(ExpandFileName('../../test_files/ISOcoated_v2_bas.ICC')));
      GetMem(mProfile, 1024);
      mProfile[0] := #0;
      dc := GetDC(Form1.Handle);
      size := 511;
      GetICMProfileW(dc, size, mProfile);
      ReleaseDC(Form1.Handle, dc);
      profiles.DeviceProfileW := mProfile;
      FCache.InitColorManagement(@profiles, icmBPCompensation);
      FreeMem(mProfile);
   end;
   // Skip anything that is not required to display a page.
   // Independent of the used flags this instance is not used to load pages! The page cache uses
   // this instance only to fetch the page's bounding boxes and orientation.
   FPDF.SetImportFlags(ifContentOnly or ifImportAsPage or ifAllAnnots or ifFormFields);
   FPDF.SetImportFlags2(if2UseProxy or if2NoResNameCheck);
   // Load external CMaps delayed. Note that the cache contains its own functions to load the CMaps. Loading the
   // CMaps into the main PDF instance is useless because this instance is not used to render pages...
   FCache.SetCMapDir(ExpandFileName('../../../Resource/CMap/'), lcmRecursive or lcmDelayed);
   if PDFCanvas.Resolution < 144 then begin
      ActionMainMenuBar1.Font.Name := 'Tahoma';
      PageControl.Font.Name        := 'Tahoma';
      ToolBar1.Font.Name           := 'Tahoma';
   end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
   // The PDFCanvas is the owner of these instances!
   FCache := nil;
   FPDF   := nil;
   // This is really somewhat idotic! If we don't disconnect the OnChange and OnExpanding events from
   // the treeview then Items.Clear() causes an access violation since it fires OnChange and OnExpanding
   // events for all nodes! I really don't understand why a Clear() function should fire an event at all.
   if FBookmarkCount > 0 then begin
      TreeBookmarks.OnChange    := nil;
      TreeBookmarks.OnExpanding := nil;
      TreeBookmarks.Items.Clear;
      SetLength(FBookmarks, 0);
      FBookmarkCount := 0;
   end;
end;

procedure TForm1.OpenPDFFile(const FileName: String);
var retval: Integer; err: TPDFError;
begin
   // Clean up if necessary
   ActionFileCloseExecute(nil);
   FPDF.CreateNewPDF('');
   retval := FPDF.OpenImportFile(FileName, ptOpen, '');
   if retval < 0 then begin
      while FPDF.IsWrongPwd(retval) do begin
         FPDF.ClearErrorLog; // Remove the "Wrong password error message"
         if PwdDialog.ShowModal = mrOK then begin
            retval := FPDF.OpenImportFile(FileName, ptOpen, AnsiString(PwdDialog.txtPassword.Text));
            if FPDF.IsWrongPwd(retval) then begin
               FPDF.ClearErrorLog; // Remove the "Wrong password error message"
               retval := FPDF.OpenImportFile(FileName, ptOwner, AnsiString(PwdDialog.txtPassword.Text));
            end;
         end else begin
            break;
         end;
      end;
      if retval < 0 then begin
         ActionFileCloseExecute(nil);
         // At this point the page cache doesn't notice when an error occurs.
         // The error message are still available after the file was already closed.
         if FPDF.GetErrLogMessageCount > 0 then begin
            err.StructSize := sizeof(err);
            if FPDF.GetErrLogMessage(0, err) then begin
               FormErrorLog.Messages.Lines.Add(String(AnsiString(err.Msg)));
               BtnErrors.Visible := true;
            end;
         end;
         Exit;
      end;
   end;
   // Display the bookmarks panel if necessary. Because this action causes a new resize event the panel
   // should be displayed before we load the first page.
   if FPDF.GetPageMode = Integer(pmUseOutLines) then begin
      PageControl.Visible := true;
      Splitter.Visible    := true;
   end;
   // Initialize the page cache
   if not PDFCanvas.InitBaseObjects(FOpenFlags) then begin
      ActionFileCloseExecute(nil);
      Exit;
   end;
   if FPDF.GetInRepairMode then begin
      PDFCanvas.AddError('Opened damaged PDF file in repair mode!');
   end;
   // Process the errors of the top level objects if any
   PDFCanvas.ProcessErrors(false);
   LblPageCount.Caption := Format(' of %d ', [PDFCanvas.PageCount]);
   Form1.Caption        := FileName;
   EnableControls(true);
   if PDFCanvas.PageLayout = plSinglePage then
      ActionViewSingle.Checked := true
   else
      ActionViewContinous.Checked := true;
   PDFCanvas.DisplayFirstPage;
   if FPDF.GetPageMode = Integer(pmUseOutLines) then begin
      ActionViewBookmarks.Execute;
   end;
end;

procedure TForm1.PDFCanvasError(Sender: TObject);
begin
   BtnErrors.Enabled := true;
   BtnErrors.Visible := true;
end;

procedure TForm1.PDFCanvasNewPage(Sender: TObject; NewPage: Integer);
begin
   EdtPageNum.Text := IntToStr(NewPage);
   CbZoom.Text     := Format('%.1n %%', [(FCache.GetCurrZoom * 72.0 / PDFCanvas.Resolution) * 100.0]); // Consider the resolution of the ouput device
end;

function TForm1.RemoveControls(StrPtr: Pointer; Unicode: Boolean): String;
var i: Integer; ansi: AnsiString; wide: WideString;
begin
   // Bookmarks contain sometimes control characters like line feeds or carriage returns.
   // Adobe's Acrobat doesn't display such characters, so, we do the same...
   if Unicode then begin
      // Note that the typecast to PAnsiChar or PWideChar is required!
      // If you pass an opaque pointer to an Ansi- or WideString variable then Delphi tries to identify the string format
      // and this code produces a buffer overrun!
      wide := WideString(PWideChar(StrPtr));
      for i := 1 to Length(wide) do begin
         if wide[i] < #32 then
            wide[i] := ' ';
      end;
      Result := wide;
   end else begin
      ansi := AnsiString(PAnsiChar(StrPtr));
      for i := 1 to Length(ansi) do begin
         if ansi[i] < #32 then
            ansi[i] := ' ';
      end;
      Result := String(ansi);
   end;
end;

procedure TForm1.TabBookmarksShow(Sender: TObject);
var i: Integer; flags: Cardinal; bmk: TBookmark; bmkNode: PBmk; node, parent: TTreeNode;
begin
   if TreeBookmarks.Items.Count > 0 then Exit;
   Screen.Cursor          := crHourGlass;
   TreeBookmarks.OnChange := nil;
   FPDF.ImportBookmarks;
   FBookmarkCount := FPDF.GetBookmarkCount;
   // Add a dummy node so that we don't import the bookmarks multiple times
   if FBookmarkCount = 0 then
      TreeBookmarks.Items.Add(nil, '')
   else begin
      try
         TreeBookmarks.Items.BeginUpdate;
         SetLength(FBookmarks, FBookmarkCount);
         // Users of Delphi below 2009 should use a treeview control that supports Unicode...

         // The standard treeview is really much too slow. To speed up things this code loads only the visible nodes. Currently
         // invisible children are loaded in the OnExpanding event. We load only what is really required but the code is still
         // at least four times slower in comparison to the C# example and this example loads the enitre tree in just one pass!

         // You'll find a lot of free treeview controls which are many times faster! So, don't use this ugly standard control!
         // Due to some reason ShowHint does not work with Delphi 2009...
         for i := 0 to FBookmarkCount - 1 do begin
            if FPDF.GetBookmark(i, bmk) then begin
               bmkNode := @FBookmarks[i];
               if bmk.Parent > -1 then begin
                  // This check is just for safety.
                  if bmk.Parent < FBookmarkCount then begin
                     // bmkNode^.Flags: Bits 1..24 = font color, Bits 25 and 26 = font styles, Bit 27 = Open flag.
                     parent              := FBookmarks[bmk.Parent].Parent;
                     bmkNode^.BmkIndex   := i;
                     bmkNode^.Flags      := (((Cardinal(bmk.Open) shl 2) or (bmk.Style and 3)) shl 25) or (bmk.Color and $FFFFFF);
                     bmkNode^.PrntIndex  := bmk.Parent;
                     bmkNode^.ChildCount := 0;
                     Inc(FBookmarks[bmk.Parent].ChildCount);
                     if parent <> nil then begin
                        flags  := PBmk(parent.Data)^.Flags and $FF000000;
                        if ((flags and BMK_OPEN) = BMK_OPEN) or (parent.HasChildren = false) then begin
                           node            := TreeBookmarks.Items.AddChildObject(parent, RemoveControls(bmk.Title, bmk.Unicode), bmkNode);
                           bmkNode^.Parent := node;
                           // Check whether the node must be expandet but expand it only one time!
                           if ((flags and BMK_OPEN) = BMK_OPEN) and (parent.Count = 1) then
                              parent.Expand(false);
                        end;
                     end;
                  end else begin
                     // This section should never be executed...
                     bmkNode^.BmkIndex   := i;
                     bmkNode^.Flags      := 0;
                     bmkNode^.PrntIndex  := -1;
                     bmkNode^.ChildCount := 0;
                  end;
               end else begin
                  node := TreeBookmarks.Items.AddChildObject(nil, RemoveControls(bmk.Title, bmk.Unicode), bmkNode);
                  // bmkNode^.Flags: Bits 1..24 = font color, Bits 25 and 26 = font styles, Bit 27 = Open flag.
                  bmkNode^.BmkIndex   := i;
                  bmkNode^.Flags      := (((Cardinal(bmk.Open) shl 2) or (bmk.Style and 3)) shl 25) or (bmk.Color and $FFFFFF);
                  bmkNode^.Parent     := node;
                  bmkNode^.PrntIndex  := -1;
                  bmkNode^.ChildCount := 0;
               end;
            end;
         end;
      finally
         TreeBookmarks.Items.EndUpdate;
      end;
   end;
   Screen.Cursor          := crDefault;
   TreeBookmarks.OnChange := TreeBookmarksChange;
   // Check for errors. It is not allowed to access the error log directly with pdfGetErrLogMessage()
   // because this can cause collusions with the rendering thread!
   PDFCanvas.ProcessErrors(true);
end;

procedure TForm1.TreeBookmarksChange(Sender: TObject; Node: TTreeNode);
var retval: TUpdBmkAction; bmk: PBmk;
begin
   if (Node = nil) or (Node.Data = nil) then Exit; // For safety...
   bmk    := Node.Data;
   retval := PDFCanvas.ExecBookmark(bmk^.BmkIndex);
   if (retval and ubaZoom) = ubaZoom then
      UnCheckZoomButtons
   else if (retval and ubaPageScale) = ubaPageScale then begin
      case PDFCanvas.PageScale of
         psFitWidth:  ActionZoomFitWidth.Checked  := true;
         psFitHeight: ActionZoomFitHeight.Checked := true;
         psFitBest:   ActionZoomFitBest.Checked   := true;
      end;
   end;
end;

procedure TForm1.TreeBookmarksCustomDrawItem(Sender: TCustomTreeView; Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
var flags: Cardinal; r: TRect; bmk: PBmk;
begin
   if Node.Data = nil then Exit;
   with TreeBookmarks.Canvas do begin
      if cdsSelected in State then begin
         Brush.Color := rgb(165, 190, 233);
         Brush.Style := Graphics.bsSolid;
         r := Node.DisplayRect(True);
         FillRect(r);
      end;
      bmk        := Node.Data;
      flags      := bmk^.Flags;
      Font.Color := flags and $FFFFFF;
      flags      := flags and $FF000000;
      if (flags and BMK_ITALIC) = BMK_ITALIC then begin
         if cdsHot in State then
            Font.Style := [Graphics.fsUnderline, Graphics.fsItalic]
         else
            Font.Style := [Graphics.fsItalic];
      end else if (flags and BMK_BOLD) = BMK_BOLD then begin
         if cdsHot in State then
            Font.Style := [Graphics.fsUnderline, Graphics.fsBold]
         else
            Font.Style := [Graphics.fsBold];
      end else if cdsHot in State then
         Font.Style := [Graphics.fsUnderline];
   end;
end;

procedure TForm1.TreeBookmarksExpanding(Sender: TObject; Node: TTreeNode; var AllowExpansion: Boolean);
var i, count, flags: Integer; current, bmkNode, prntNode: PBmk; bmk: TBookmark; parent: TTreeNode;
begin
   if Node.Data = nil then Exit;
   current := Node.Data;
   // The first child was already loaded
   if current^.ChildCount < 2 then Exit;
   try
      TreeBookmarks.Items.BeginUpdate;
      count := current^.ChildCount;
      // Make sure that we don't load the same children again
      current^.ChildCount := 0;
      // We load only the visible nodes in the current hierarchy. Every sub node can in turn contain further children.
      // The first child of a sub node must be loaded, otherwise the node cannot be expanded...
      for i := current^.BmkIndex + 2 to FBookmarkCount - 1 do begin
         bmkNode := @FBookmarks[i];
         if (bmkNode^.PrntIndex = current^.BmkIndex) or (bmkNode^.Parent = nil) then begin
            if FPDF.GetBookmark(i, bmk) then begin
               prntNode := @FBookmarks[bmk.Parent];
               parent   := prntNode^.Parent;
               flags    := prntNode^.Flags and $FF000000;
               if bmk.Parent = current^.BmkIndex then begin
                  if bmkNode^.Parent <> nil then begin
                     // If the node contains only one child then it was already fully loaded
                     if bmkNode^.ChildCount < 2 then Dec(count);
                     continue;
                  end;
                  node            := TreeBookmarks.Items.AddChildObject(parent, RemoveControls(bmk.Title, bmk.Unicode), bmkNode);
                  bmkNode^.Parent := node;
                  // If the bookmark contains children then we must load the first child!
                  if bmkNode^.ChildCount = 0 then Dec(count);
               end else if (parent <> nil) and (((flags and BMK_OPEN) = BMK_OPEN) or (parent.Count = 0)) then begin
                  node            := TreeBookmarks.Items.AddChildObject(parent, RemoveControls(bmk.Title, bmk.Unicode), bmkNode);
                  bmkNode^.Parent := node;
                  if bmkNode^.ChildCount > 0 then Inc(count);
                  // Check whether the node must be expandet but expand it only one time!
                  if ((flags and BMK_OPEN) = BMK_OPEN) and (parent.Count = 1) then
                     parent.Expand(false);
               end;
               if count < 2 then break;
            end;
         end;
      end;
   finally
      TreeBookmarks.Items.EndUpdate;
   end;
end;

procedure TForm1.UnCheckZoomButtons;
begin
   // AutoSelect does not work with a button group if AllowUp is false. So, we must manually
   // uncheck the zoom buttons. Sometimes it is still not possible to uncheck all three buttons.
   BtnFitWidth.Down            := false;
   BtnFitBest.Down             := false;
   BtnFitHeight.Down           := false;
   ActionZoomFitWidth.Checked  := false;
   ActionZoomFitBest.Checked   := false;
   ActionZoomFitHeight.Checked := false;
end;

procedure TForm1.ScrollDeltaChange(Sender: TObject);
begin
   PDFCanvas.SetScrollLineDelta(true, TAction(Sender).Tag);
end;

end.

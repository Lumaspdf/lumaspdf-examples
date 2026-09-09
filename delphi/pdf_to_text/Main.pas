unit Main;

interface

uses
  Windows, SysUtils, Classes, Forms, Dialogs, StdCtrls, ShellApi,
  frmProgress, frmDirSelect, frmInfo, LumasPdfApi, pdf_callBack, pdf_text_extraction, FileSearch, Controls,
  ComCtrls, ShellCtrls, ExtCtrls, ToolWin, ImgList, Menus;

type
  TMainForm = class(TForm)
    Panel1: TPanel;
    ShellTreeView1: TShellTreeView;
    Splitter1: TSplitter;
    Panel3: TPanel;
    ToolBar1: TToolBar;
    tbSaveAsText: TToolButton;
    ImageList1: TImageList;
    tbConvertAll: TToolButton;
    SaveDialog1: TSaveDialog;
    ShellListView1: TShellListView;
    StatusBar1: TStatusBar;
    PopupMenu1: TPopupMenu;
    mnuSaveastext: TMenuItem;
    mnuConvertall: TMenuItem;
    Open1: TMenuItem;
    N2: TMenuItem;
    N1: TMenuItem;
    Selectall1: TMenuItem;
    Deselect1: TMenuItem;
    tbInfo: TToolButton;
    procedure tbSaveAsTextClick(Sender: TObject);
    procedure ShellListView1KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure tbConvertAllClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ShellListView1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Open1Click(Sender: TObject);
    procedure Deselect1Click(Sender: TObject);
    procedure ShellListView1Click(Sender: TObject);
    procedure ShellTreeView1Click(Sender: TObject);
    procedure Selectall1Click(Sender: TObject);
    procedure tbInfoClick(Sender: TObject);
  private
    FCurrent:    String;
    FFileSearch: CFileSearch;
    FHaveError:  Boolean;
    FMaxCount:   Integer;
    FPDF:        TPDF;
    FSelCount:   Integer;
    function  ConvertFile(var Stack: TPDFParseInterface; TextStack: CPDFToText; const TopDir, InFile: String; PathFromDlg: Boolean): Boolean;
    procedure ConvertFiles(var Stack: TPDFParseInterface; TextStack: CPDFToText; const TopDir, SubDir: String);
    procedure FinishSearch(Sender: TObject);
    procedure GetSelCount(Recursive: Boolean; CreateThread: Boolean);
    procedure GetFileCount(const Path: String; CreateThread: Boolean);
    function  GetFileCountEx(const Path: String): Integer;
    { Private-Deklarationen }
  public
    property CurrentFile: String read FCurrent;
    property HaveError: Boolean read FHaveError write FHaveError;
    property MaxCount: Integer read FMaxCount write FMaxCount;
    { Public-Deklarationen }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

function ExtractBaseDir(const Path: String):String;
var i: Integer; c: Char;
begin
   i := Length(Path);
   c := AnsiLastChar(Path)^;
   if (c = '/') or (c = '\') then Dec(i);
   Result := Path;
   while i > 0 do begin
      if (Path[i] = '/') or (Path[i] = '\') then begin
         SetLength(Result, i);
         break;
      end;
      Dec(i);
   end;
end;

function ExtractSubDir(const Path: String):String;
var i, j, len: Integer; c: Char;
begin
   i := Length(Path);
   c := AnsiLastChar(Path)^;
   if (c = '/') or (c = '\') then Dec(i);
   while i > 0 do begin
      if (Path[i] = '/') or (Path[i] = '\') then begin
         len := Length(Path) - i;
         SetLength(Result, len);
         Inc(i);
         for j := 1 to len do begin
            Result[j] := Path[i];
            Inc(i);
         end;
         break;
      end;
      Dec(i);
   end;
end;

function CreateSubDir(const TopDir, Path: String):String;
var i, p, len1, len2: Integer; baseDir: String;
begin
   baseDir := ExtractBaseDir(TopDir);
   len1 := Length(baseDir);
   len2 := Length(Path) - len1 - 1;
   Result := TopDir;
   p := Length(TopDir) + 1;
   SetLength(Result, p + len2);
   for i := len1 + 1 to len2 + len1 + 1 do begin
      Result[p] := Path[i];
      Inc(p);
   end;
end;

function pdf_ErrProc(const Data: Pointer; ErrCode: Integer; const ErrMessage: PAnsiChar; ErrType: Integer): Integer; stdcall;
begin
   MainForm.HaveError := true;
   frmConvProgress.AddLine(MainForm.CurrentFile, ErrMessage);
   Result := 0; // we try to continue.
end;

function pdf_InitProgress(const Data: Pointer; ProgType: TProgType; MaxCount: Integer): Integer; stdcall;
begin
   // Only the "Read" case occurs in this example because we do not save the PDF file.
   case ProgType of
      ptImportPage: frmConvProgress.lbState.Caption := 'Read Page';
      ptWritePage:  frmConvProgress.lbState.Caption := 'Write Page'; // Cannot occur
   end;
   frmConvProgress.prgPage.Position := 0;
   frmConvProgress.prgPage.Max      := MaxCount;
   MainForm.MaxCount                := MaxCount;
   Result := 0;
end;

function pdf_Progress(const Data: Pointer; ActivePage: Integer): Integer; stdcall;
begin
   frmConvProgress.lbActivePage.Caption := Format('%d of %d', [ActivePage, MainForm.MaxCount]);
   Result := 0;
   frmConvProgress.prgPage.StepIt;
   Application.ProcessMessages;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
   FPDF := TPDF.Create;
   FPDF.SetErrorMode(emNoFuncNames); // Do not print function names in error messages
   // External cmaps should always be loaded when extracting text from PDF files.
   // See the description of ParseContent() for further information.
   FPDF.SetCMapDir(ExpandFileName('../../../Resource/CMap'), lcmRecursive or lcmDelayed);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
   if FPDF <> nil then FPDF.Free;
   if FFileSearch <> nil then begin
      FFileSearch.Terminate;
      FFileSearch.Free;
   end;
end;

function TMainForm.ConvertFile(var Stack: TPDFParseInterface; TextStack: CPDFToText; const TopDir, InFile: String; PathFromDlg: Boolean): Boolean;
var i, count: Integer; fileName, outFile: String;
begin
   Result     := false;
   FHaveError := false;
   FCurrent   := InFile;
   fileName   := ExtractFileName(FCurrent);
   if not PathFromDlg then
      outFile := TopDir + ChangeFileExt(fileName, '.txt')
   else
      outFile := SaveDialog1.FileName;
   frmConvProgress.lbFileName.Caption   := FCurrent;
   frmConvProgress.lbState.Caption      := 'Read document...';
   frmConvProgress.lbActivePage.Caption := '';
   Application.ProcessMessages;

   if not FPDF.CreateNewPDF('') then Exit; // We do not produce a PDF file in this example
   // We import the page contents only. Enything else makes no sense because such things are
   // ignored during conversion to text.
   FPDF.SetImportFlags(ifContentOnly or ifImportAsPage);
   if FPDF.OpenImportFile(FCurrent, ptOpen, '') < 0 then begin
      FPDF.FreePDF;
      frmConvProgress.prgFile.StepIt;
      frmConvProgress.StatusBar1.Panels[3].Text := Format('%d', [frmConvProgress.prgFile.Position]);
      Exit;
   end;
   Application.ProcessMessages;
   if FPDF.ImportPDFFile(1, 1.0, 1.0) < 0 then begin
      FPDF.FreePDF;
      frmConvProgress.prgFile.StepIt;
      frmConvProgress.StatusBar1.Panels[3].Text := Format('%d', [frmConvProgress.prgFile.Position]);
      Exit;
   end;
   FPDF.CloseImportFile;
   if not textStack.OpenEx(outFile) then begin
      frmConvProgress.AddLine(FCurrent, 'Cannot open file!');
      FPDF.FreePDF;
      frmConvProgress.prgFile.StepIt;
      frmConvProgress.StatusBar1.Panels[3].Text := Format('%d', [frmConvProgress.prgFile.Position]);
      Exit;
   end;
   count := FPDF.GetPageCount;
   frmConvProgress.lbState.Caption  := 'Convert page';
   frmConvProgress.prgPage.Position := 0;
   frmConvProgress.prgPage.Max      := count;
   for i := 1 to count do begin
      frmConvProgress.lbActivePage.Caption := Format('%d of %d', [i, count]);
      Application.ProcessMessages;
      if frmConvProgress.Cancel then begin
         FPDF.FreePDF;
         Exit;
      end;
      FPDF.EditPage(i); // Open the page
      textStack.Init;
      textStack.WritePageIdentifier(i);
      FPDF.ParseContent(TextStack, Stack, pfNone);
      FPDF.EndPage; // Close the page
      frmConvProgress.prgPage.StepIt;
   end;
   textStack.Close;
   if not FHaveError then begin
      frmConvProgress.AddLine(fileName, 'OK');
      Result := true;
   end;
   FPDF.FreePDF;
   frmConvProgress.prgFile.StepIt;
   frmConvProgress.StatusBar1.Panels[3].Text := Format('%d', [frmConvProgress.prgFile.Position]);
end;

procedure TMainForm.ConvertFiles(var Stack: TPDFParseInterface; TextStack: CPDFToText; const TopDir, SubDir: String);
var sr: TSearchRec; inDir, outDir: String; haveDir: Boolean;
begin
   inDir   := SubDir;
   outDir  := CreateSubDir(TopDir, SubDir);
   haveDir := false;
   if AnsiLastChar(inDir)^ <> '\' then inDir := inDir + '\';
   if FindFirst(inDir + '*.*', faAnyFile, sr) <> 0 then Exit;
   if AnsiLastChar(outDir)^ <> '\' then outDir := outDir + '\';
   repeat
      if (sr.Attr and faDirectory) <> 0 then begin
         if sr.Name[1] = '.' then continue;
         ConvertFiles(Stack, TextStack, TopDir, inDir + sr.Name);
      end else begin
         if LowerCase(ExtractFileExt(sr.Name)) = '.pdf' then begin
            if not haveDir and not DirectoryExists(outDir) then begin
               if not ForceDirectories(outDir) then begin
                  frmConvProgress.AddLine(inDir, 'Cannot create output directory!');
                  break;
               end;
            end;
            haveDir := true;
            ConvertFile(Stack, TextStack, outDir, inDir + sr.Name, false);
            if frmConvProgress.Cancel then break;
         end;
      end;
   until FindNext(sr) <> 0;
   FindCLose(sr);
end;

procedure TMainForm.FinishSearch(Sender: TObject);
begin
   FSelCount := CFileSearch(Sender).FileCount;
   if FSelCount > 0 then begin
      tbConvertAll.Enabled  := FSelCount > 1;
      tbSaveAsText.Enabled  := FSelCount = 1;
      mnuSaveAsText.Enabled := FSelCount = 1;
      mnuConvertAll.Enabled := FSelCount > 1;
   end else begin
      tbConvertAll.Enabled  := false;
      tbSaveAsText.Enabled  := false;
      mnuSaveAsText.Enabled := false;
      mnuConvertAll.Enabled := false;
   end;
   StatusBar1.Panels[0].Text := 'PDF files found';
   StatusBar1.Panels[1].Text := Format('%d', [FSelCount]);
end;

procedure TMainForm.GetFileCount(const Path: String; CreateThread: Boolean);
begin
   // Make sure that only one thread is executed
   if FFileSearch <> nil then begin
      FFileSearch.Terminate;
      FFileSearch.Free;
      FFileSearch := nil;
   end;
   if CreateThread then begin
      FFileSearch := CFileSearch.Create(Path);
      FFileSearch.OnTerminate     := FinishSearch;
      FFileSearch.FreeOnTerminate := false;
      FFileSearch.Priority        := tpLowest;
      FFileSearch.Resume;
   end else begin
      Inc(FSelCount, GetFileCountEx(Path));
   end;
end;

function TMainForm.GetFileCountEx(const Path: String): Integer;
var sr: TSearchRec; filePath: String;
begin
   Result := 0;
   try
      filePath := Path;
      if AnsiLastChar(Path)^ <> '\' then filePath := Path + '\';
      if FindFirst(filePath + '*.*', faAnyFile, sr) <> 0 then Exit;
   except
      Exit;
   end;
   try
      repeat
         if (sr.Attr and faDirectory) <> 0 then begin
            if sr.Name[1] = '.' then continue;
            inc(Result, GetFileCountEx(filePath + sr.Name));
         end else begin
            if LowerCase(ExtractFileExt(sr.Name)) = '.pdf' then Inc(Result);
         end;
      until FindNext(sr) <> 0;
   finally
      FindCLose(sr);
   end;
end;

procedure TMainForm.GetSelCount(Recursive: Boolean; CreateThread: Boolean);
var i: Integer;
begin
   FSelCount := 0;
   if not Recursive then begin
      for i := 0 to ShellListView1.Items.Count -1 do begin
         if ShellListView1.Items[i].Selected
         and (LowerCase(ExtractFileExt(ShellListView1.Folders[i].PathName)) = '.pdf') then
            Inc(FSelCount);
      end;
   end else begin
      if ShellListView1.SelCount > 1 then CreateThread := false;
      for i := 0 to ShellListView1.Items.Count -1 do begin
         if ShellListView1.Items[i].Selected then begin
            if ShellListView1.Folders[i].IsFolder then begin
               GetFileCount(ShellListView1.Folders[i].PathName, CreateThread);
            end else if (LowerCase(ExtractFileExt(ShellListView1.Folders[i].PathName)) = '.pdf') then
               Inc(FSelCount);
         end;
      end;
      tbConvertAll.Enabled  := FSelCount > 1;
      tbSaveAsText.Enabled  := FSelCount = 1;
      mnuSaveAsText.Enabled := FSelCount = 1;
      mnuConvertAll.Enabled := FSelCount > 1;
      StatusBar1.Panels[0].Text := 'PDF files selected';
      StatusBar1.Panels[1].Text := Format('%d', [FSelCount]);
   end;
end;

procedure TMainForm.tbConvertAllClick(Sender: TObject);
var i: Integer; recursive: Boolean; topDir: String;
stack: TPDFParseInterface; textStack: CPDFToText;
begin
   textStack := nil;
   if ShellListView1.SelCount = 0 then begin
      FSelCount             := 0;
      tbConvertAll.Enabled  := false;
      tbSaveAsText.Enabled  := false;
      mnuSaveAsText.Enabled := false;
      mnuConvertAll.Enabled := false;
      StatusBar1.Panels[0].Text := 'PDF files selected';
      StatusBar1.Panels[1].Text := '0';
      Exit;
   end;
   for i := 0 to ShellListView1.Items.Count -1 do begin
      if ShellListView1.Items[i].Selected then begin
         if ShellListView1.Folders[i].IsFolder then begin
            topDir := ExtractFilePath(ShellListView1.Folders[i].PathName);
            break;
         end else if (LowerCase(ExtractFileExt(ShellListView1.Folders[i].PathName)) = '.pdf') then begin
            topDir := ExtractFilePath(ShellListView1.Folders[i].PathName);
            break;
         end;
      end;
   end;
   frmSelectDir.edtPath.Text := topDir + 'New Files\';
   frmSelectDir.ShowModal;
   if frmSelectDir.ModalResult = mrOK then begin
      recursive := frmSelectDir.chkRecursive.Checked;
      topDir := frmSelectDir.edtPath.Text;
      if topDir = '' then Exit;
      if not DirectoryExists(topDir) then begin
         if MessageDlg('Directory "' + topDir + '" does not exist.'#13'Create it?', mtConfirmation, [mbYes, mbCancel], 0) = mrCancel then
            Exit
         else if not CreateDir(topDir) then begin
            MessageDlg('Directory "' + topDir + '" could not be created!'#13'Please choose another directory name.', mtError, [mbOK], 0);
            Exit;
         end;
      end;
      FPDF.SetProgressProc(nil, @pdf_InitProgress, @pdf_Progress);
      FPDF.SetOnErrorProc(nil, @pdf_ErrProc);
      FillChar(stack, sizeof(stack), 0);
      stack.BeginTemplate       := parseBeginTemplate;
      stack.RestoreGraphicState := parseRestoreGraphicState;
      stack.SaveGraphicState    := parseSaveGraphicState;
      stack.MulMatrix           := parseMulMatrix;
      stack.SetCharSpacing      := parseSetCharSpacing;
      stack.SetFont             := parseSetFont;
      stack.SetTextDrawMode     := parseSetTextDrawMode;
      stack.SetTextScale        := parseSetTextScale;
      stack.SetWordSpacing      := parseSetWordSpacing;
      stack.ShowTextArrayW      := parseShowTextArrayW;
      frmConvProgress.lstErrorLog.Strings.Clear;
      frmConvProgress.prgFile.Position := 0;
      frmConvProgress.Show;
      try
         textStack := CPDFToText.Create(FPDF);
         Application.ProcessMessages;
         if recursive then
            GetSelCount(true, false)
         else
            GetSelCount(false, false);
         frmConvProgress.prgFile.Max := FSelCount;
         frmConvProgress.StatusBar1.Panels[1].Text := Format('%d', [FSelCount]);
         Application.ProcessMessages;
         for i := 0 to ShellListView1.Items.Count -1 do begin
            if ShellListView1.Items[i].Selected then begin
               if ShellListView1.Folders[i].IsFolder then begin
                  if not recursive then continue;
                  ConvertFiles(stack, textStack, topDir, ShellListView1.Folders[i].PathName);
                  if frmConvProgress.Cancel then break;
               end else if (LowerCase(ExtractFileExt(ShellListView1.Folders[i].PathName)) = '.pdf') then begin
                  ConvertFile(stack, textStack, topDir, ShellListView1.Folders[i].PathName, false);
                  if frmConvProgress.Cancel then break;
               end;
            end;
         end;
      except
         on E: Exception do MessageDlg(E.Message, mtError, [mbOK], 0);
      end;
      frmConvProgress.SetFinish;
      Application.ProcessMessages;
      FSelCount             := 0;
      tbConvertAll.Enabled  := false;
      tbSaveAsText.Enabled  := false;
      mnuSaveAsText.Enabled := false;
      mnuConvertAll.Enabled := false;
      ShellTreeView1.Refresh(ShellTreeView1.TopItem);
   end;
   if textStack <> nil then textStack.Free;
end;

procedure TMainForm.tbSaveAsTextClick(Sender: TObject);
var stack: TPDFParseInterface; textStack: CPDFToText; haveFile: Boolean;
begin
   FCurrent := ShellListView1.SelectedFolder.PathName;
   SaveDialog1.FileName := ChangeFileExt(FCurrent, '.txt');
   if not SaveDialog1.Execute then Exit;
   textStack := nil;
   FPDF.SetProgressProc(nil, @pdf_InitProgress, @pdf_Progress);
   FPDF.SetOnErrorProc(nil, @pdf_ErrProc);
   FillChar(stack, sizeof(stack), 0);
   stack.BeginTemplate       := parseBeginTemplate;
   stack.RestoreGraphicState := parseRestoreGraphicState;
   stack.SaveGraphicState    := parseSaveGraphicState;
   stack.MulMatrix           := parseMulMatrix;
   stack.SetCharSpacing      := parseSetCharSpacing;
   stack.SetFont             := parseSetFont;
   stack.SetTextDrawMode     := parseSetTextDrawMode;
   stack.SetTextScale        := parseSetTextScale;
   stack.SetWordSpacing      := parseSetWordSpacing;
   stack.ShowTextArrayW      := parseShowTextArrayW;
   frmConvProgress.lstErrorLog.Strings.Clear;
   frmConvProgress.prgFile.Position := 0;
   frmConvProgress.Show;
   try
      textStack := CPDFToText.Create(FPDF);
      frmConvProgress.prgFile.Max := 1;
      frmConvProgress.StatusBar1.Panels[1].Text := '1';
      Application.ProcessMessages;
      haveFile := ConvertFile(stack, textStack, ExtractFilePath(FCurrent), FCurrent, true);
   except
      on E: Exception do begin
         MessageDlg(E.Message, mtError, [mbOK], 0);
         haveFile := false;
      end;
   end;
   frmConvProgress.SetFinish;
   Application.ProcessMessages;
   FSelCount             := 0;
   tbConvertAll.Enabled  := false;
   tbSaveAsText.Enabled  := false;
   mnuSaveAsText.Enabled := false;
   mnuConvertAll.Enabled := false;
   ShellTreeView1.Refresh(ShellTreeView1.TopItem);
   if textStack <> nil then textStack.Free;
   if haveFile then ShellExecute(Handle, PChar('open'), PChar(SaveDialog1.FileName), nil, nil, SW_SHOWMAXIMIZED);
end;

procedure TMainForm.Selectall1Click(Sender: TObject);
begin
   ShellListView1.SelectAll;
   ShellListView1Click(nil);
end;

procedure TMainForm.ShellListView1KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
   if (ssCtrl in Shift) and (Key = 65) then begin
      ShellListView1.SelectAll;
      GetSelCount(true, true);
      tbConvertAll.Enabled  := FSelCount > 1;
      tbSaveAsText.Enabled  := FSelCount = 1;
      mnuSaveAsText.Enabled := FSelCount = 1;
      mnuConvertAll.Enabled := FSelCount > 1;
      StatusBar1.Panels[0].Text := 'PDF files selected';
      StatusBar1.Panels[1].Text := Format('%d', [FSelCount]);
      Exit;
   end;
   if not ((ssRight in Shift) or (ssLeft in Shift)) then Exit;
   if ShellListView1.SelCount < 1 then
      Exit
   else if ShellListView1.SelCount = 1 then begin
      if ShellListView1.SelectedFolder.IsFolder then begin
         GetSelCount(true, false);
      end;
   end else
      GetSelCount(true, false);
end;

procedure TMainForm.ShellListView1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
   if ShellListView1.SelCount < 1 then begin
      StatusBar1.Panels[0].Text := 'PDF files found';
      StatusBar1.Panels[1].Text := '0';
      Exit
   end else if ShellListView1.SelCount = 1 then begin
      if ShellListView1.SelectedFolder.IsFolder then begin
         GetSelCount(true, true);
      end else begin
         if LowerCase(ExtractFileExt(ShellListView1.SelectedFolder.PathName)) = '.pdf' then
            FSelCount := 1
         else
            FSelCount := 0;
      end;
   end else
      GetSelCount(true, true);
end;

procedure TMainForm.Open1Click(Sender: TObject);
begin
   if ShellListView1.SelCount < 1 then Exit;
   ShellExecute(Handle, PChar('open'), PChar(ShellListView1.SelectedFolder.PathName), nil, nil, SW_SHOWMAXIMIZED);
end;

procedure TMainForm.Deselect1Click(Sender: TObject);
var i: Integer;
begin
   for i := 0 to ShellListView1.Items.Count -1 do begin
      ShellListView1.Items[i].Selected := not ShellListView1.Items[i].Selected;
   end;
   ShellListView1.Repaint;
end;

procedure TMainForm.ShellListView1Click(Sender: TObject);
begin
   GetSelCount(Sender = nil, false);
   if FSelCount = 1 then begin
      if not ShellListView1.SelectedFolder.IsFolder then begin
         if LowerCase(ExtractFileExt(ShellListView1.SelectedFolder.PathName)) = '.pdf' then
            FSelCount := 1
         else
            FSelCount := 0;
      end;
   end;
   if (FSelCount > 0) and ShellListView1.SelectedFolder.IsFolder then begin
      tbSaveAsText.Enabled  := false;
      mnuSaveAsText.Enabled := false;
      tbConvertAll.Enabled  := FSelCount > 0;
      mnuConvertAll.Enabled := FSelCount > 0;
   end else begin
      tbSaveAsText.Enabled  := FSelCount = 1;
      mnuSaveAsText.Enabled := FSelCount = 1;
      tbConvertAll.Enabled  := FSelCount > 1;
      mnuConvertAll.Enabled := FSelCount > 1;
   end;
   StatusBar1.Panels[0].Text := 'PDF files selected';
   StatusBar1.Panels[1].Text := Format('%d', [FSelCount]);
end;

procedure TMainForm.ShellTreeView1Click(Sender: TObject);
begin
   FSelCount             := 0;
   tbConvertAll.Enabled  := false;
   tbSaveAsText.Enabled  := false;
   mnuSaveAsText.Enabled := false;
   mnuConvertAll.Enabled := false;
   StatusBar1.Panels[0].Text := 'PDF files selected';
   StatusBar1.Panels[1].Text := '0';
end;

procedure TMainForm.tbInfoClick(Sender: TObject);
begin
   frmProgInfo.ShowModal;
end;

end.

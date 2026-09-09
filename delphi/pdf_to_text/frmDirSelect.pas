unit frmDirSelect;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, Buttons, ShlObj, ActiveX;

type
  TfrmSelectDir = class(TForm)
    edtPath: TEdit;
    Label1: TLabel;
    BitBtn1: TBitBtn;
    Button1: TButton;
    Button2: TButton;
    chkRecursive: TCheckBox;
    procedure BitBtn1Click(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  frmSelectDir: TfrmSelectDir;

implementation

{$R *.dfm}

function BrowseCallbackProc(hwnd: HWND; uMsg: UINT; lParam, lpData: LPARAM): Integer; stdcall;
var
  Path: array[0..MAX_PATH] of Char;
  X, Y: Integer;
  R: TRect;
begin
  case uMsg of
      BFFM_INITIALIZED: begin
        // Initialization has been done, now set our initial directory which is passed in lpData
        // (and set btw. the status text too).
        // Note: There's no need to cast lpData to a PChar since the following call needs a
        //       LPARAM parameter anyway.
        SendMessage(hwnd, BFFM_SETSELECTION, 1, lpData);
        SendMessage(hwnd, BFFM_SETSTATUSTEXT, 0, lpData);
        // place the dialog screen centered
        GetWindowRect(hwnd, R);
        X := (Screen.Width - (R.Right - R.Left)) div 2;
        Y := (Screen.Height - (R.Bottom - R.Top)) div 2;
        SetWindowPos(hwnd, 0, X, Y, 0, 0, SWP_NOSIZE or SWP_NOZORDER);
      end;
      BFFM_SELCHANGED: begin
        // Set the status window to the currently selected path.
        if SHGetPathFromIDList(Pointer(lParam), Path) then SendMessage(hwnd, BFFM_SETSTATUSTEXT, 0, Integer(@Path));
      end;
  end;
  Result := 0;
end;

//----------------------------------------------------------------------------------------------------------------------

function SelectDirectory(const Caption, InitialDir: String; const Root: WideString; ShowStatus: Boolean; out Directory: String): Boolean;
var
   BrowseInfo: TBrowseInfo;
   Buffer: PChar;
   RootItemIDList,
   ItemIDList: PItemIDList;
   ShellMalloc: IMalloc;
   IDesktopFolder: IShellFolder;
   Eaten, Flags: LongWord;
   Windows: Pointer;
   Path: String;
begin
   Result := False;
   Directory := '';
   Path := InitialDir;
   if (Length(Path) > 0) and (Path[Length(Path)] = '\') then Delete(Path, Length(Path), 1);
   FillChar(BrowseInfo, SizeOf(BrowseInfo), 0);
   if (ShGetMalloc(ShellMalloc) = S_OK) and (ShellMalloc <> nil) then begin
      Buffer := ShellMalloc.Alloc(MAX_PATH);
      try
         SHGetDesktopFolder(IDesktopFolder);
         IDesktopFolder.ParseDisplayName(Application.Handle, nil, PWideChar(Root), Eaten, RootItemIDList, Flags);
         with BrowseInfo do begin
            hwndOwner := Application.Handle;
            pidlRoot := RootItemIDList;
            pszDisplayName := Buffer;
            lpszTitle := PChar(Caption);
            ulFlags := BIF_RETURNONLYFSDIRS;
            if ShowStatus then ulFlags := ulFlags or BIF_STATUSTEXT;
            lParam := Integer(PChar(Path));
            lpfn := BrowseCallbackProc;
         end;
         // make the browser dialog modal
         Windows := DisableTaskWindows(Application.Handle);
         try
            ItemIDList := ShBrowseForFolder(BrowseInfo);
         finally
            EnableTaskWindows(Windows);
         end;
         Result := ItemIDList <> nil;
         if Result then begin
            ShGetPathFromIDList(ItemIDList, Buffer);
            ShellMalloc.Free(ItemIDList);
            Directory := Buffer;
         end;
      finally
         ShellMalloc.Free(Buffer);
      end;
   end;
end;

procedure TfrmSelectDir.BitBtn1Click(Sender: TObject);
var dir: String;
begin
   if SelectDirectory('Select Output Directory', 'c:/', 'c:/', true, dir) then begin
      edtPath.Text := dir;
   end;
end;

end.

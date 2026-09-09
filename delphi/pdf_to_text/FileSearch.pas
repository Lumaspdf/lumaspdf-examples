unit FileSearch;

interface

uses
  Classes, SysUtils;

type
  CFileSearch = class(TThread)
  private
    FFileCount: Integer;
    FPath:      String;
    procedure GetFileCount(const Path: String);
    { Private-Deklarationen }
  protected
    procedure Execute; override;
  public
    constructor Create(const Path: String);
    property FileCount: Integer read FFileCount;
    property Path: String read FPath write FPath;
  end;

implementation

{ CFileSearch }

constructor CFileSearch.Create(const Path: String);
begin
   FPath := Path;
   inherited Create(true);
end;

procedure CFileSearch.Execute;
begin
   FFileCount := 0;
   GetFileCount(FPath);
end;

procedure CFileSearch.GetFileCount(const Path: String);
var sr: TSearchRec; filePath: String;
begin
   try
      filePath := Path;
      if AnsiLastChar(Path)^ <> '\' then filePath := Path + '\';
      if FindFirst(filePath + '*.*', faAnyFile, sr) <> 0 then Exit;
   except
      Exit;
   end;
   try
      repeat
         if Terminated then break;
         if (sr.Attr and faDirectory) <> 0 then begin
            if sr.Name[1] = '.' then continue;
            GetFileCount(filePath + sr.Name);
         end else begin
            if LowerCase(ExtractFileExt(sr.Name)) = '.pdf' then Inc(FFileCount);
         end;
      until FindNext(sr) <> 0;
   finally
      FindCLose(sr);
   end;
end;

end.
 
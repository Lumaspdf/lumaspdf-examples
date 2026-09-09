{
   Simple Metafile class. Note that the class TMetafile, which is delivered with
   Borland Delphi, contains many bugs.
}

unit UMetafile;

interface

uses Windows, SysUtils, Classes;

type TMetafileEx = class
  protected
   FBuffer: PByte;
   FBufSize: Integer;
   FHandle: HENHMETAFILE;
   FHeader: TEnhMetaHeader;
   FStream: TFileStream;
   function IsEMF: Boolean;
  public
   destructor Destroy; override;
   procedure LoadFromFile(const FileName: String);
   property Buffer:  PByte read FBuffer;
   property BufSize: Integer read FBufSize;
   property Handle:  HENHMETAFILE read FHandle;
   property Header:  TEnhMetaHeader read FHeader;
end;

implementation

const WMFKey = Integer($9AC6CDD7);

type
  PMetafileHeader = ^TMetafileHeader;
  TMetafileHeader = packed record
    Key: Longint;
    Handle: SmallInt;
    Box: TSmallRect;
    Inch: Word;
    Reserved: Longint;
    CheckSum: Word;
  end;

function ComputeAldusChecksum(var WMF: TMetafileHeader): Word;
type PWord = ^Word;
var pW: PWord; pEnd: PWord;
begin
   // 2026-08-02: was `while Longint(pW) < Longint(pEnd)` +
   // `Inc(Longint(pW), sizeof(Word))`. Both are 32-bit-only idioms: Longint is
   // 32 bits on every target, so on Win64 the comparison truncates a 64-bit
   // pointer and the Inc does not compile at all ("E2064 Left side cannot be
   // assigned to" -- you cannot Inc a typecast). NativeUInt is pointer-sized on
   // both, and Inc on a typed PWord already advances by sizeof(Word), which is
   // what the explicit step was spelling out.
   Result := 0;
   pW := @WMF;
   pEnd := @WMF.CheckSum;
   while NativeUInt(pW) < NativeUInt(pEnd) do begin
      Result := Result xor pW^;
      Inc(pW);
   end;
end;

{ TMetafileEx }

const HundredthMMPerInch = 2540;

destructor TMetafileEx.Destroy;
begin
   if FBuffer <> nil then FreeMem(FBuffer, FBufSize);
   if FHandle <> 0 then DeleteEnhMetaFile(FHandle);
   if FStream <> nil then FStream.Free;
   inherited;
end;

function TMetafileEx.IsEMF: Boolean;
begin
   if FStream.Size > sizeof(FHeader) then begin
      FStream.Read(FHeader, sizeof(FHeader));
      FStream.Seek(0, soFromBeginning);
   end else begin
      Result := false;
      Exit;
   end;
   Result := (FHeader.iType = EMR_HEADER) and (FHeader.dSignature = ENHMETA_SIGNATURE);
end;

procedure TMetafileEx.LoadFromFile(const FileName: String);
var w, h: Integer; wmf: TMetafileHeader; mfp: TMetaFilePict;
begin
   if FStream <> nil then FStream.Free;
   if FHandle <> 0 then DeleteEnhMetaFile(FHandle);
   if FBuffer <> nil then FreeMem(FBuffer, FBufSize);
   FStream := TFileStream.Create(FileName, fmOpenRead + fmShareDenyNone);
   FBufSize := FStream.Size;
   if IsEMF then begin
      GetMem(FBuffer, FBufSize);
      FStream.Read(FBuffer^, FHeader.nBytes);
      // The parameter p2 is declared as PChar in Delphi 6/7 and as PByte in newer versions!
      // Backward compatibility is something that does not exist in Delphi...
      FHandle := SetEnhMetaFileBits(FHeader.nBytes, PByte(FBuffer));
      if FHandle = 0 then raise Exception.Create('Invalid EMF file!');
   end else begin
      FStream.Read(wmf, sizeof(wmf));
      if (wmf.Key <> WMFKEY) then begin
         GetMem(FBuffer, FBufSize);
         mfp.hMF  := 0;
         mfp.mm   := MM_ANISOTROPIC;
         mfp.xExt := 0;
         mfp.yExt := 0;
         FStream.Seek(0, soFromBeginning);
         FStream.Read(FBuffer^, FBufSize);
         FHandle := SetWinMetaFileBits(FBufSize, PByte(FBuffer), 0, mfp);
         if FHandle = 0 then raise Exception.Create('Invalid WMF file!');
         if GetEnhMetaFileHeader(FHandle, sizeof(FHeader), @FHeader) = 0 then raise Exception.Create('Invalid WMF file!');
      end else begin
         if (ComputeAldusChecksum(wmf) <> wmf.CheckSum) then raise Exception.Create('This is not a Metafile!');
         Dec(FBufSize, sizeof(wmf));
         GetMem(FBuffer, FBufSize);
         FStream.Read(FBuffer^, FBufSize);
         if wmf.Inch = 0 then wmf.Inch := 96;
         w := MulDiv(wmf.Box.Right - wmf.Box.Left, HundredthMMPerInch, wmf.Inch);
         h := MulDiv(wmf.Box.Bottom - wmf.Box.Top, HundredthMMPerInch, wmf.Inch);
         with mfp do begin
            MM := MM_ANISOTROPIC;
            xExt := w;
            yExt := h;
            hmf  := 0;
         end;
         FHandle := SetWinMetaFileBits(FBufSize, PByte(FBuffer), 0, mfp);
         if FHandle = 0 then raise Exception.Create('Invalid WMF file!');
         if GetEnhMetaFileHeader(FHandle, sizeof(FHeader), @FHeader) = 0 then raise Exception.Create('Invalid WMF file!');
      end;
      FreeMem(FBuffer, FBufSize);
      FBufSize := GetEnhMetaFileBits(FHandle, 0, nil);
      GetMem(FBuffer, FBufSize);
      FBufSize := GetEnhMetaFileBits(FHandle, FBufSize, PByte(FBuffer));
   end;
   FStream.Free;
   FStream := nil;
end;

end.

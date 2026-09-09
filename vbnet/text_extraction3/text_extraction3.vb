' text_extraction3 -- VB.NET port of examples\Vb6\text_extraction3\text_extraction3.bas
' Imports a PDF and extracts its text page by page with pdfExtractText, then
' writes the result to out.txt as UTF-16LE (with BOM).
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports System.Text
Imports LumasPdfSdk

Module modTextExtraction3
    Private ErrDelegate As TErrorProc

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    ' ParamArray is UInteger, not Integer: the generated bindings type the
    ' flag constants as UInteger (they have the high bit set, e.g.
    ' ifImportAsPage = &H80000000UI), and passing one to an Integer
    ' parameter is BC30439 "Constant expression not representable in
    ' type 'Integer'". The arithmetic below is unchanged, so the value
    ' handed to the engine -- and therefore the output -- is identical.
    Function Fl(ParamArray vals() As UInteger) As UInteger
        Dim r As Long = 0
        For Each v In vals : r = r Or (CLng(v) And &HFFFFFFFFL) : Next
        Return CUInt(r And &HFFFFFFFFL)
    End Function

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0                       ' We try to continue if an error occurs
    End Function

    Private Sub WritePageIdentifier(ByVal fs As FileStream, ByVal PageNum As Integer)
        Dim b() As Byte
        If PageNum > 1 Then
            b = Encoding.Unicode.GetBytes(vbCrLf)
            fs.Write(b, 0, b.Length)
        End If
        b = Encoding.Unicode.GetBytes("%----------------------- Page " & PageNum & " -----------------------------" & vbCrLf)
        fs.Write(b, 0, b.Length)
    End Sub

    Private Sub WriteWCharsFromPtr(ByVal fs As FileStream, ByVal Ptr As IntPtr, ByVal WCharCount As Integer)
        If Ptr = IntPtr.Zero OrElse WCharCount <= 0 Then Return
        Dim b(WCharCount * 2 - 1) As Byte
        Marshal.Copy(Ptr, b, 0, WCharCount * 2)
        ' Write exactly the wchar count the engine reported; deliberately do NOT
        ' stop at a NUL. Until 2026-08-02 pdfExtractText could hand back a buffer
        ' with U+0000 embedded (a simple font's character code 0 decoded straight
        ' through CP1252), and the Delphi vendor wrapper's
        ' "Text := WideString(txt)" truncated the caller's text there -- this
        ' example lost every page after the first such glyph. The cause was fixed
        ' in the engine (Lumas.Pdf.Document.DecodeGIDString), so honouring the
        ' reported length is now both correct and byte-identical to the
        ' reference. Truncating here too would re-hide the bug if it returned.
        fs.Write(b, 0, WCharCount * 2)
    End Sub

    Sub Main()
        Dim pdf As IntPtr
        Dim outFile As String, inFile As String
        Dim textPtr As IntPtr, textLen As UInteger

        pdf = LumasPdf.pdfNewPDF()
        ErrDelegate = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, ErrDelegate)
        LumasPdf.pdfCreateNewPDFW(pdf, "")            ' We do not create a PDF file in this example

        ' External cmaps should always be loaded when extracting text from PDF files.
        LumasPdf.pdfSetCMapDirW(pdf, AppPath() & "\CMap", CUInt(LumasPdfConsts.lcmRecursive Or LumasPdfConsts.lcmDelayed))

        ' Import anything and don't convert pages to templates
        LumasPdf.pdfSetImportFlags(pdf, Fl(LumasPdfConsts.ifImportAll, LumasPdfConsts.ifImportAsPage))
        inFile = AppPath() & "\in.pdf"
        If LumasPdf.pdfOpenImportFileW(pdf, inFile, LumasPdfConsts.ptOpen, "") < 0 Then
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If
        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0)
        LumasPdf.pdfCloseImportFile(pdf)

        ' Flatten markup annotations and form fields so their text can be extracted too.
        LumasPdf.pdfFlattenAnnots(pdf, CUInt(LumasPdfConsts.affMarkupAnnots))
        LumasPdf.pdfFlattenForm(pdf)

        outFile = AppPath() & "\out.txt"
        Dim fs As New FileStream(outFile, FileMode.Create, FileAccess.Write)
        fs.Write(New Byte() {255, 254}, 0, 2)     ' UTF-16LE BOM

        Dim cnt As Integer = LumasPdf.pdfGetPageCount(pdf)
        For i As Integer = 1 To cnt
            WritePageIdentifier(fs, i)
            textPtr = IntPtr.Zero : textLen = 0
            ' It is not recommended to sort text on the y-axis since it sometimes causes strange results.
            If LumasPdf.pdfExtractText(pdf, CUInt(i), LumasPdfConsts.tefDeleteOverlappingText Or LumasPdfConsts.tefSortTextX, IntPtr.Zero, textPtr, textLen) Then
                If textLen > 0 Then WriteWCharsFromPtr(fs, textPtr, CInt(textLen))
            End If
        Next
        fs.Close()

        Console.WriteLine("Text successfully extracted to " & outFile)
        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

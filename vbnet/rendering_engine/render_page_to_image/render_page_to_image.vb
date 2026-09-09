' render_page_to_image -- VB.NET port of examples\Vb6\rendering_engine\render_page_to_image
Imports System
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module modRenderPageToImage
    Private ErrDelegate As TErrorProc

    <DllImport("gdi32.dll")> Private Function GetDeviceCaps(ByVal hdc As IntPtr, ByVal idx As Integer) As Integer
    End Function
    <DllImport("user32.dll")> Private Function GetDC(ByVal h As IntPtr) As IntPtr
    End Function
    <DllImport("user32.dll")> Private Function ReleaseDC(ByVal h As IntPtr, ByVal hdc As IntPtr) As Integer
    End Function
    Private Const HORZRES As Integer = 8

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

    Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Sub Main()
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        ErrDelegate = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, ErrDelegate)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        LumasPdf.pdfSetImportFlags(pdf, Fl(LumasPdfConsts.ifImportAll, LumasPdfConsts.ifImportAsPage))
        If LumasPdf.pdfOpenImportFileW(pdf, "../../../../dynapdf_help.pdf", LumasPdfConsts.ptOpen, "") < 0 Then
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If

        LumasPdf.pdfAppend(pdf)
        LumasPdf.pdfImportPageEx(pdf, 1, 1.0, 1.0)
        LumasPdf.pdfEndPage(pdf)

        Dim dc As IntPtr = GetDC(IntPtr.Zero)
        Dim w As Integer = GetDeviceCaps(dc, HORZRES)
        ReleaseDC(IntPtr.Zero, dc)

        Dim filePath As String = AppPath() & "\out.tif"
        If LumasPdf.pdfRenderPageToImageW(pdf, 1, filePath, 0, w, 0, LumasPdfConsts.rfDefault, TPDFPixFormat.pxfRGB, LumasPdfConsts.cfLZW, TImageFormat.ifmTIFF) Then
            Console.WriteLine("TIFF image """ & filePath & """ successfully created!")
        End If

        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

' image_extraction -- VB.NET port of examples\Vb6\content_parser\image_extraction\image_extraction.bas
Imports System
Imports System.IO
Imports System.Collections.Generic
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module ImageExtraction
    Private errDel As TErrorProc
    Private delBeginTemplate As TBeginTemplate
    Private delInsertImage As TInsertImage

    ' De-dup lists (Delphi used two TList of pointers)
    Private m_Images As New List(Of IntPtr)()
    Private m_Templates As New List(Of Integer)()

    Public Function ErrProc(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Public Function parseBeginTemplate(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByVal Handle As Integer, ByRef BBox As TPDFRect, ByVal Matrix As IntPtr) As Integer
        If m_Templates.Contains(Handle) Then
            Return 1                       ' Skip the template
        Else
            m_Templates.Add(Handle)
            Return 0
        End If
    End Function

    Public Function parseInsertImage(ByVal Data As IntPtr, ByRef Image As TPDFImage) As Integer
        If Not Image.InlineImage Then
            If m_Images.Contains(Image.ObjectPtr) Then Return 0   ' Already handled?
            m_Images.Add(Image.ObjectPtr)
        End If
        ' If an image cannot be decompressed we may get a compressed image here.
        If Image.Filter <> TDecodeFilter.dfNone Then Return 0
        ' Note that Flate compression is no standard filter.
        If Image.BitsPerPixel = 1 Then
            LumasPdf.pdfAddImage(Data, LumasPdfConsts.cfCCITT4, CUInt(LumasPdfConsts.icNone), Image)
        Else
            LumasPdf.pdfAddImage(Data, LumasPdfConsts.cfLZW, CUInt(LumasPdfConsts.icNone), Image)
        End If
        Return 0
    End Function

    Sub Main()
        Dim stack As New TPDFParseInterface()
        delBeginTemplate = New TBeginTemplate(AddressOf parseBeginTemplate)
        delInsertImage = New TInsertImage(AddressOf parseInsertImage)
        stack.BeginTemplate = Marshal.GetFunctionPointerForDelegate(delBeginTemplate)
        stack.InsertImage = Marshal.GetFunctionPointerForDelegate(delInsertImage)

        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf ErrProc)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        ' We avoid the conversion of pages to templates
        LumasPdf.pdfSetImportFlags(pdf, &H0FFFFFFEUI Or &H80000000UI)
        Dim inFile As String = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..\..\..\..\dynapdf_help.pdf")
        If LumasPdf.pdfOpenImportFileW(pdf, inFile, LumasPdfConsts.ptOpen, "") < 0 Then
            Console.WriteLine("Input file ""dynapdf_help.pdf"" not found!")
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If
        If LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0) < 0 Then
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If
        ' Flatten form fields so that we can extract images of these objects too.
        LumasPdf.pdfFlattenForm(pdf)

        Dim outFile As String = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.tif")

        ' We create a multi-page TIFF in this example
        If LumasPdf.pdfCreateImageW(pdf, outFile, TImageFormat.ifmTIFF) = 0 Then
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If
        For i As Integer = 1 To LumasPdf.pdfGetPageCount(pdf)
            LumasPdf.pdfEditPage(pdf, i)
            LumasPdf.pdfParseContent(pdf, pdf, stack, LumasPdfConsts.pfDecomprAllImages)
            LumasPdf.pdfEndPage(pdf)
        Next
        If LumasPdf.pdfCloseImage(pdf) <> 0 Then
            Console.WriteLine("TIFF image """ & outFile & """ successfully created!")
        End If

        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

' checkconformance -- VB.NET port of examples\Vb6\pdfa_extension\checkconformance
Imports System
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module modCheckConformance
    Private errDel As TErrorProc
    Private fontDel As TOnFontNotFoundProc
    Private iccDel As TOnReplaceICCProfile

    Private Function U(ByVal v As Long) As UInteger
        Return CUInt(v And &HFFFFFFFFL)
    End Function

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Public Function FontNotFoundProc(ByVal Data As IntPtr, ByVal PDFFont As IntPtr, ByVal FontName As String, ByVal Style As Integer, ByVal StdFontIndex As Integer, ByVal IsSymbolFont As Boolean) As Integer
        Return LumasPdf.pdfReplaceFontW(Data, PDFFont, "Arial", Style, True)
    End Function

    Public Function ReplaceICCProfileProc(ByVal Data As IntPtr, ByVal ProfileType As TICCProfileType, ByVal ColorSpace As Integer) As Integer
        Select Case ProfileType
            Case TICCProfileType.ictRGB
                Return LumasPdf.pdfReplaceICCProfileW(Data, U(ColorSpace), "../../../test_files/sRGB.icc")
            Case TICCProfileType.ictCMYK
                Return LumasPdf.pdfReplaceICCProfileW(Data, U(ColorSpace), "../../../test_files/ISOcoated_v2_bas.ICC")
            Case Else
                Return LumasPdf.pdfReplaceICCProfileW(Data, U(ColorSpace), "../../../test_files/gray.icc")
        End Select
    End Function

    Private Function ConvertFile(ByVal pdf As IntPtr, ByVal ConvType As Integer, ByVal InFile As String, ByVal OutFile As String) As Boolean
        ConvertFile = False
        LumasPdf.pdfCreateNewPDFW(pdf, "")
        LumasPdf.pdfSetDocInfoW(pdf, TDocumentInfo.diProducer, "")

        Dim convFlags As Integer
        Select Case ConvType
            Case CInt(TConformanceType.ctNormalize)
                convFlags = LumasPdfConsts.coAllowDeviceSpaces
            Case CInt(TConformanceType.ctPDFA_1b_2005)
                convFlags = LumasPdfConsts.coDefault Or LumasPdfConsts.coFlattenLayers
            Case CInt(TConformanceType.ctPDFA_2b), CInt(TConformanceType.ctPDFA_2u)
                convFlags = LumasPdfConsts.coDefault Or LumasPdfConsts.coDeletePresentation
            Case Else
                convFlags = (LumasPdfConsts.coDefault Or LumasPdfConsts.coDeletePresentation) And (Not LumasPdfConsts.coDeleteEmbeddedFiles)
        End Select
        convFlags = convFlags Or LumasPdfConsts.coCheckImages
        convFlags = convFlags Or LumasPdfConsts.coRepairDamagedImages

        If ConvType <> CInt(TConformanceType.ctNormalize) Then
            LumasPdf.pdfSetImportFlags(pdf, U(LumasPdfConsts.ifImportAll Or LumasPdfConsts.ifImportAsPage Or LumasPdfConsts.ifPrepareForPDFA))
            LumasPdf.pdfSetImportFlags2(pdf, U(LumasPdfConsts.if2UseProxy Or LumasPdfConsts.if2DuplicateCheck))
        Else
            LumasPdf.pdfSetImportFlags(pdf, U(LumasPdfConsts.ifImportAll Or LumasPdfConsts.ifImportAsPage))
            LumasPdf.pdfSetImportFlags2(pdf, U(LumasPdfConsts.if2UseProxy Or LumasPdfConsts.if2DuplicateCheck Or LumasPdfConsts.if2Normalize))
        End If

        If LumasPdf.pdfOpenImportFileW(pdf, InFile, LumasPdfConsts.ptOpen, "") < 0 Then
            Console.WriteLine("Could not open the import file (it may be encrypted)!")
            LumasPdf.pdfFreePDF(pdf)
            Return False
        End If
        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0)
        LumasPdf.pdfCloseImportFile(pdf)

        Dim retval As Integer = LumasPdf.pdfCheckConformance(pdf, ConvType, U(convFlags), pdf, fontDel, iccDel)
        Select Case retval
            Case 1 : LumasPdf.pdfAddOutputIntentW(pdf, "../../../test_files/sRGB.icc")
            Case 2 : LumasPdf.pdfAddOutputIntentW(pdf, "../../../test_files/ISOcoated_v2_bas.ICC")
            Case 3 : LumasPdf.pdfAddOutputIntentW(pdf, "../../../test_files/gray.icc")
        End Select

        Dim e As TPDFError
        e.StructSize = CUInt(Marshal.SizeOf(GetType(TPDFError)))
        For i As Integer = 0 To LumasPdf.pdfGetErrLogMessageCount(pdf) - 1
            LumasPdf.pdfGetErrLogMessage(pdf, CUInt(i), e)
            Console.WriteLine(Marshal.PtrToStringAnsi(e.Msg))
        Next

        If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
            If LumasPdf.pdfOpenOutputFileW(pdf, OutFile) = 0 Then
                Return False
            End If
            ConvertFile = (LumasPdf.pdfCloseFile(pdf) <> 0)
        End If
    End Function

    Sub Main()
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        errDel = New TErrorProc(AddressOf PDFError)
        fontDel = New TOnFontNotFoundProc(AddressOf FontNotFoundProc)
        iccDel = New TOnReplaceICCProfile(AddressOf ReplaceICCProfileProc)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)

        LumasPdf.pdfSetCMapDirW(pdf, AppPath() & "\..\..\..\Resource\CMap", U(LumasPdfConsts.lcmDelayed Or LumasPdfConsts.lcmRecursive))
        Dim filePath As String = AppPath() & "\out.pdf"

        If ConvertFile(pdf, CInt(TConformanceType.ctPDFA_3b), AppPath() & "\sample_multipage.pdf", filePath) Then
            Console.WriteLine("PDF file """ & filePath & """ successfully created!")
        End If

        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

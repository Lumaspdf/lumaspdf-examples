' conv_to_zugferd -- VB.NET port of examples\Vb6\...\attach_invoice_and_conv_to_zugferd\conv_to_zugferd.bas
' Converts a PDF to PDF/A-3 (FacturX Comfort), attaches the factur-x.xml e-invoice
' and adds an output intent. Uses font-not-found and ICC-profile replacement
' callbacks during conformance checking.
Imports System
Imports LumasPdfSdk

Module modConvToZugferd
    ' coDefault_PDFA_3 is not exported as a const; its computed value.
    Private Const coDefault_PDFA_3 As Integer = &H50EF7F

    Private ErrDelegate As TErrorProc
    Private FontDelegate As TOnFontNotFoundProc
    Private IccDelegate As TOnReplaceICCProfile

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
        Return 0                      ' We try to continue if an error occurs
    End Function

    ' WeightFromStyle is a client-side helper: (Style and $FFF00000) shr 20
    Private Function WeightFromStyle(ByVal Style As Integer) As Integer
        Dim w As Integer = (Style And &H7FF00000) \ &H100000
        If (Style And &H80000000) <> 0 Then w += &H800
        Return w
    End Function

    Public Function FontNotFoundProc(ByVal Data As IntPtr, ByVal PDFFont As IntPtr, ByVal FontName As String, ByVal Style As Integer, ByVal StdFontIndex As Integer, ByVal IsSymbolFont As Boolean) As Integer
        Dim s As Integer = Style
        If WeightFromStyle(s) < 500 Then s = (s And &HF) Or LumasPdfConsts.fsRegular
        Return LumasPdf.pdfReplaceFontW(Data, PDFFont, "Arial", s, True)
    End Function

    Public Function ReplaceICCProfileProc(ByVal Data As IntPtr, ByVal ProfileType As TICCProfileType, ByVal ColorSpace As Integer) As Integer
        ' The most important ICC profiles are available free of charge from Adobe.
        Select Case ProfileType
            Case TICCProfileType.ictRGB
                Return LumasPdf.pdfReplaceICCProfileW(Data, CUInt(ColorSpace), "../../../test_files/sRGB.icc")
            Case TICCProfileType.ictCMYK
                Return LumasPdf.pdfReplaceICCProfileW(Data, CUInt(ColorSpace), "../../../test_files/ISOcoated_v2_bas.ICC")
            Case Else
                Return LumasPdf.pdfReplaceICCProfileW(Data, CUInt(ColorSpace), "../../../test_files/gray.icc")
        End Select
    End Function

    Private Function ConvertFile(ByVal pdf As IntPtr, ByVal ConvType As TConformanceType, ByVal InFile As String, ByVal Invoice As String, ByVal OutFile As String) As Boolean
        Dim ef As Integer, retval As Integer, convFlags As UInteger

        ConvertFile = False
        LumasPdf.pdfCreateNewPDFW(pdf, "")              ' The output file is opened later
        LumasPdf.pdfSetDocInfoW(pdf, TDocumentInfo.diProducer, "")    ' No need to override the original producer

        Select Case ConvType
            Case TConformanceType.ctFacturX_Comfort, TConformanceType.ctFacturX_Extended, TConformanceType.ctFacturX_XRechnung
                convFlags = CUInt(coDefault_PDFA_3)
            Case Else
                Return False                 ' We create e-invoices in this example and nothing else.
        End Select

        LumasPdf.pdfCreateNewPDFW(pdf, "")              ' The output file will be created later
        LumasPdf.pdfSetDocInfoW(pdf, TDocumentInfo.diProducer, "")    ' No need to override the original producer

        ' These flags require some processing time but they are very useful.
        convFlags = CUInt(LumasPdfConsts.coCheckImages) Or CUInt(LumasPdfConsts.coRepairDamagedImages)

        ' The flag ifPrepareForPDFA is required. ifImportAsPage makes sure pages are not converted to templates.
        LumasPdf.pdfSetImportFlags(pdf, Fl(LumasPdfConsts.ifImportAll, LumasPdfConsts.ifImportAsPage, LumasPdfConsts.ifPrepareForPDFA))
        ' The flag if2UseProxy reduces the memory usage.
        LumasPdf.pdfSetImportFlags2(pdf, CUInt(LumasPdfConsts.if2UseProxy))

        LumasPdf.pdfOpenImportFileW(pdf, InFile, LumasPdfConsts.ptOpen, "")
        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0)
        LumasPdf.pdfCloseImportFile(pdf)

        ' The invoice should be the first attachment if further files must be attached.
        ef = LumasPdf.pdfAttachFileW(pdf, Invoice, "EN 16931 compliant invoice", False)
        If ConvType <> TConformanceType.ctFacturX_XRechnung Then
            LumasPdf.pdfAssociateEmbFile(pdf, TAFDestObject.adCatalog, -1, TAFRelationship.arAlternative, CUInt(ef))
        Else
            LumasPdf.pdfAssociateEmbFile(pdf, TAFDestObject.adCatalog, -1, TAFRelationship.arSource, CUInt(ef))
        End If

        ' An invoice should not use CMYK colors since a CMYK ICC profile must be embedded in this case.
        FontDelegate = New TOnFontNotFoundProc(AddressOf FontNotFoundProc)
        IccDelegate = New TOnReplaceICCProfile(AddressOf ReplaceICCProfileProc)
        retval = LumasPdf.pdfCheckConformance(pdf, CInt(ConvType), convFlags, pdf, FontDelegate, IccDelegate)
        Select Case retval
            Case 1 : LumasPdf.pdfAddOutputIntentW(pdf, "../../../test_files/sRGB.icc")
            Case 2 : LumasPdf.pdfAddOutputIntentW(pdf, "../../../test_files/ISOcoated_v2_bas.ICC")
            Case 3 : LumasPdf.pdfAddOutputIntentW(pdf, "../../../test_files/gray.icc")
        End Select

        ' No fatal error occurred?
        If LumasPdf.pdfHaveOpenDoc(pdf) Then
            ' We write the file into the application directory.
            If Not LumasPdf.pdfOpenOutputFileW(pdf, OutFile) Then
                LumasPdf.pdfDeletePDF(pdf)
                Return False
            End If
            ConvertFile = LumasPdf.pdfCloseFile(pdf)
        End If
    End Function

    Sub Main()
        Dim pdf As IntPtr, outFile As String

        pdf = LumasPdf.pdfNewPDF()
        ErrDelegate = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, ErrDelegate)

        ' Non embedded CID fonts depend usually on the availability of external cmaps.
        LumasPdf.pdfSetCMapDirW(pdf, "../../../Resource/CMap", CUInt(LumasPdfConsts.lcmDelayed Or LumasPdfConsts.lcmRecursive))

        outFile = AppPath() & "\out.pdf"

        ' The profiles Minimum, Basic, and Basic WL are not EN 16931 compliant.
        If ConvertFile(pdf, TConformanceType.ctFacturX_Comfort, "../../../test_files/test_invoice.pdf", "../../../test_files/factur-x.xml", outFile) Then
            Console.WriteLine("PDF file """ & outFile & """ successfully created!")
        End If

        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

' attach_invoice -- VB.NET port of examples\Vb6\...\attach_invoice\attach_invoice.bas
' Imports an existing PDF/A-3 invoice, attaches the factur-x.xml e-invoice,
' associates it with the catalog and sets the FacturX Comfort PDF version.
Imports System
Imports LumasPdfSdk

Module modAttachInvoice
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
        Return 0                      ' We try to continue if an error occurs
    End Function

    Sub Main()
        Dim ef As Integer, pdf As IntPtr, outFile As String

        pdf = LumasPdf.pdfNewPDF()
        ErrDelegate = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, ErrDelegate)
        LumasPdf.pdfCreateNewPDFW(pdf, "")              ' The output file is opened later

        ' We assume that the pdf invoice is already a valid PDF/A 3 file in this example.
        LumasPdf.pdfSetImportFlags(pdf, Fl(LumasPdfConsts.ifImportAsPage, LumasPdfConsts.ifImportAll))
        LumasPdf.pdfOpenImportFileW(pdf, "../../../test_files/test_invoice.pdf", LumasPdfConsts.ptOpen, "")

        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0)

        ef = LumasPdf.pdfAttachFileW(pdf, "../../../test_files/factur-x.xml", "EN 16931 compliant invoice", False)
        LumasPdf.pdfAssociateEmbFile(pdf, TAFDestObject.adCatalog, -1, TAFRelationship.arAlternative, CUInt(ef))

        ' Note that ZUGFeRD 2.1 or higher and FacturX is identically defined in PDF. Therefore, both formats
        ' share the same version constants.
        LumasPdf.pdfSetPDFVersion(pdf, LumasPdfConsts.pvFacturX_Comfort)

        ' No fatal error occurred?
        If LumasPdf.pdfHaveOpenDoc(pdf) Then
            ' We write the file into the application directory.
            outFile = AppPath() & "\out.pdf."
            If Not LumasPdf.pdfOpenOutputFileW(pdf, outFile) Then
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
            If LumasPdf.pdfCloseFile(pdf) Then
                Console.WriteLine("PDF file """ & outFile & """ successfully created!")
            End If
        End If
        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

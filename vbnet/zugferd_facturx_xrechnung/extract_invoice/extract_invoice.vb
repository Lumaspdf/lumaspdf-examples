' extract_invoice -- VB.NET port of examples\Vb6\...\extract_invoice\extract_invoice.bas
' Creates FacturX and XRechnung invoices (attaching factur-x.xml from a memory
' buffer via AttachFileEx) and then verifies the embedded e-invoice can be
' found and extracted again.
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module modExtractInvoice
    ' VCL TColor values used as case labels for console colouring.
    Private Const clRed As Integer = &HFF
    Private Const clGreen As Integer = &H8000
    Private Const clYellow As Integer = &HFFFF
    Private Const clWhite As Integer = &HFFFFFF

    Private ErrDelegate As TErrorProc

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Public Function PDFError(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0                      ' We try to continue if an error occurs
    End Function

    Private Sub SetColorConsole(ByVal AColor As Integer)
        Select Case AColor
            Case clRed : Console.ForegroundColor = ConsoleColor.Red
            Case clGreen : Console.ForegroundColor = ConsoleColor.Green
            Case clYellow : Console.ForegroundColor = ConsoleColor.Yellow
            Case clWhite : Console.ForegroundColor = ConsoleColor.White
        End Select
    End Sub

    Private Function GetFileBuffer(ByVal FileName As String, ByRef buf() As Byte) As Boolean
        Try
            buf = File.ReadAllBytes(FileName)
            Return (buf.Length > 0)
        Catch
            Return False
        End Try
    End Function

    Private Function HaveEInvoice(ByVal pdf As IntPtr, ByVal InFileName As String) As Boolean
        Dim ef As Integer
        Dim info As TPDFVersionInfo
        Dim fs As TPDFFileSpec
        Dim result As Boolean = False

        info.StructSize = CUInt(Marshal.SizeOf(GetType(TPDFVersionInfo)))

        LumasPdf.pdfCreateNewPDFW(pdf, "")
        ' We need the document info or metadata and embedded files only
        LumasPdf.pdfSetImportFlags(pdf, CUInt(LumasPdfConsts.ifDocInfo) Or CUInt(LumasPdfConsts.ifEmbeddedFiles))
        LumasPdf.pdfSetImportFlags2(pdf, CUInt(LumasPdfConsts.if2UseProxy))

        If LumasPdf.pdfOpenImportFileW(pdf, InFileName, LumasPdfConsts.ptOpen, "") < 0 Then GoTo cleanup

        ' Other stuff can be ignored
        LumasPdf.pdfImportCatalogObjects(pdf)

        If Not LumasPdf.pdfGetPDFVersionEx(pdf, info) Then GoTo cleanup

        If (info.PDFAVersion <> 3) OrElse (info.FXDocName = IntPtr.Zero) Then GoTo cleanup

        Dim docName As String = Marshal.PtrToStringAnsi(info.FXDocName)
        ef = LumasPdf.pdfFindEmbeddedFileW(pdf, docName)
        If ef < 0 Then
            SetColorConsole(clRed)
            Console.WriteLine("Invoice " & docName & " not found!")
            GoTo cleanup
        End If
        If ef <> 0 Then
            SetColorConsole(clYellow)
            Console.WriteLine("Warning: The invoice should be the first file attachment. This might cause unnecessary problems.")
        End If
        If LumasPdf.pdfGetEmbeddedFile(pdf, CUInt(ef), fs, True) Then
            result = (fs.BufSize > 0)
        End If
cleanup:
        LumasPdf.pdfFreePDF(pdf)
        Return result
    End Function

    Private Function CreateInvoice(ByVal pdf As IntPtr, ByVal FacturX As Boolean, ByVal InvoiceName As String, ByVal OutFile As String) As Boolean
        Dim ef As Integer
        Dim buffer() As Byte = Nothing
        Dim result As Boolean = False
        Dim gch As GCHandle = Nothing
        Dim pinned As Boolean = False

        LumasPdf.pdfCreateNewPDFW(pdf, "")              ' The output file is opened later
        LumasPdf.pdfSetDocInfoW(pdf, TDocumentInfo.diProducer, "")    ' No need to override the original producer

        If LumasPdf.pdfOpenImportFileW(pdf, "../../../test_files/test_invoice.pdf", LumasPdfConsts.ptOpen, "") < 0 Then GoTo done

        LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0)

        ' The test invoice has the file name factur-x.xml but we must be able to override the name since the
        ' German XRechnung requires the name xrechnung.xml. With AttachFileEx() we can specify the file name.
        If GetFileBuffer("../../../test_files/factur-x.xml", buffer) Then
            gch = GCHandle.Alloc(buffer, GCHandleType.Pinned)
            pinned = True
            ef = LumasPdf.pdfAttachFileExW(pdf, gch.AddrOfPinnedObject(), CUInt(buffer.Length), InvoiceName, "EN 19631 compliant invoice", False)
        Else
            ef = LumasPdf.pdfAttachFileExW(pdf, IntPtr.Zero, 0, InvoiceName, "EN 19631 compliant invoice", False)
        End If

        ' Note that ZUGFeRD 2.1 or higher and FacturX is identically defined in PDF and share the same version consts.
        If FacturX Then
            LumasPdf.pdfSetPDFVersion(pdf, LumasPdfConsts.pvFacturX_Comfort)
            LumasPdf.pdfAssociateEmbFile(pdf, TAFDestObject.adCatalog, -1, TAFRelationship.arAlternative, CUInt(ef))
        Else
            LumasPdf.pdfSetPDFVersion(pdf, LumasPdfConsts.pvFacturX_XRechnung)
            LumasPdf.pdfAssociateEmbFile(pdf, TAFDestObject.adCatalog, -1, TAFRelationship.arSource, CUInt(ef))
        End If

        ' No fatal error occurred?
        If LumasPdf.pdfHaveOpenDoc(pdf) Then
            If LumasPdf.pdfOpenOutputFileW(pdf, OutFile) Then
                result = LumasPdf.pdfCloseFile(pdf)
            End If
        End If
done:
        If pinned Then gch.Free()
        LumasPdf.pdfFreePDF(pdf)
        Return result
    End Function

    Sub Main()
        Dim pdf As IntPtr, outFile As String

        pdf = LumasPdf.pdfNewPDF()
        ErrDelegate = New TErrorProc(AddressOf PDFError)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, ErrDelegate)

        ' We write the test files into the application directory.
        outFile = AppPath() & "\out.pdf."

        ' Test cases: FacturX or XRechnung (invoice name must be xrechnung.xml)
        If (Not CreateInvoice(pdf, True, "factur-x.xml", outFile)) OrElse (Not HaveEInvoice(pdf, outFile)) _
           OrElse (Not CreateInvoice(pdf, False, "xrechnung.xml", outFile)) OrElse (Not HaveEInvoice(pdf, outFile)) Then
            SetColorConsole(clRed)
            Console.WriteLine("XML Invoice not found!")
        Else
            SetColorConsole(clGreen)
            Console.WriteLine("All tests passed!")
        End If
        Console.ResetColor()

        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

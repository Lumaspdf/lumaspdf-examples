Attribute VB_Name = "modExtractInvoice"
Option Explicit
' ============================================================================
'  extract_invoice -- ActiveX/COM version (LumasPdf.PDF, late-bound), mirrors
'  the plain-DLL example at
'  examples\Vb6\zugferd_facturx_xrechnung\extract_invoice (read-only
'  reference, not modified). Creates FacturX and XRechnung invoices
'  (attaching factur-x.xml from a memory buffer via AttachFileExA, renaming
'  it as needed) and then verifies the embedded e-invoice can be found and
'  extracted again.
'
'  AttachFileExA's Buffer parameter is an Int64 (a raw memory pointer) and
'  GetPDFVersionEx / GetEmbeddedFile marshal their C records as byte-array
'  OleVariants; since the whole module talks to the engine through the
'  mandated late-bound CreateObject("LumasPdf.PDF") object, both marshal
'  transparently with no early-bound workaround needed. VB6 packs/unpacks
'  the byte-array records via CopyMemory (a Long array mirrors each record)
'  and dereferences the FXDocName PAnsiChar pointer they carry.
' ============================================================================

Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (ByRef Dest As Any, ByRef Src As Any, ByVal Length As Long)
Private Declare Function lstrlenA Lib "kernel32" (ByVal lpString As Long) As Long

Private m_PDF As Object

Private Const ptOpen As Long = 0
Private Const if2UseProxy As Long = &H4          ' TImportFlags2
Private Const ifDocInfo As Long = &H8000&         ' TImportFlags
Private Const ifEmbeddedFiles As Long = &H200000
Private Const adCatalog As Long = 1               ' TAFDestObject
Private Const arAlternative As Long = 4           ' TAFRelationship
Private Const arSource As Long = 2
Private Const pvFacturX_Comfort As Long = &H400000    ' TPDFVersion
Private Const pvFacturX_XRechnung As Long = &H2000000

Private Function PtrToAnsi(ByVal p As Long) As String
    Dim n As Long, b() As Byte
    If p = 0 Then Exit Function
    n = lstrlenA(p)
    If n <= 0 Then Exit Function
    ReDim b(0 To n - 1)
    CopyMemory b(0), ByVal p, n
    PtrToAnsi = StrConv(b, vbUnicode)
End Function

Private Function GetFileBuffer(ByVal FileName As String, ByRef buf() As Byte, ByRef BufSize As Long) As Boolean
    Dim fnum As Long
    GetFileBuffer = False
    On Error GoTo done
    fnum = FreeFile
    Open FileName For Binary Access Read As #fnum
    BufSize = LOF(fnum)
    If BufSize > 0 Then
        ReDim buf(0 To BufSize - 1)
        Get #fnum, , buf
    End If
    Close #fnum
    GetFileBuffer = (BufSize > 0)
done:
End Function

' ---- record marshalling (a 17-element Long array mirrors each C record) ------
Private Function GetVersionInfo(ByRef info() As Long) As Boolean
    Dim v As Variant, b() As Byte
    info(0) = 17 * 4               ' StructSize
    ReDim b(0 To 17 * 4 - 1)
    CopyMemory b(0), info(0), 17 * 4
    v = b
    GetVersionInfo = m_PDF.GetPDFVersionEx(v)
    b = v
    CopyMemory info(0), b(0), 17 * 4
End Function

Private Function GetEmbFile(ByVal ef As Long, ByRef fs() As Long) As Boolean
    Dim v As Variant, b() As Byte
    ReDim b(0 To 17 * 4 - 1)       ' zero-filled TPDFFileSpec (no StructSize field)
    v = b
    GetEmbFile = m_PDF.GetEmbeddedFile(ef, v, True)
    b = v
    CopyMemory fs(0), b(0), 17 * 4
End Function

Private Function HaveEInvoice(ByVal InFileName As String) As Boolean
    Dim ef As Long
    Dim info(0 To 16) As Long      ' TPDFVersionInfo: PDFAVersion=idx6, FXDocName=idx13
    Dim fs(0 To 16) As Long        ' TPDFFileSpec: Buffer=idx0, BufSize=idx1
    Dim docName As String

    HaveEInvoice = False
    m_PDF.CreateNewPDFA ""
    ' We need the document info or metadata and embedded files only
    m_PDF.SetImportFlags ifDocInfo Or ifEmbeddedFiles
    m_PDF.SetImportFlags2 if2UseProxy

    If m_PDF.OpenImportFileA(InFileName, ptOpen, "") < 0 Then GoTo cleanup

    ' Other stuff can be ignored
    m_PDF.ImportCatalogObjects

    If GetVersionInfo(info) = False Then GoTo cleanup
    If (info(6) <> 3) Or (info(13) = 0) Then GoTo cleanup    ' PDFAVersion, FXDocName

    docName = PtrToAnsi(info(13))
    ef = m_PDF.FindEmbeddedFileA(docName)
    If ef < 0 Then
        Debug.Print "Invoice " & docName & " not found!"
        GoTo cleanup
    End If
    If ef <> 0 Then
        Debug.Print "Warning: The invoice should be the first file attachment. This might cause unnecessary problems."
    End If
    If GetEmbFile(ef, fs) Then
        HaveEInvoice = (fs(1) > 0)                            ' BufSize
    End If
cleanup:
    m_PDF.FreePDF
End Function

Private Function CreateInvoice(ByVal FacturX As Boolean, ByVal InvoiceName As String, ByVal OutFile As String) As Boolean
    Dim ef As Long, BufSize As Long
    Dim buffer() As Byte

    CreateInvoice = False
    m_PDF.CreateNewPDFA ""              ' The output file is opened later
    ' (SetDocInfoA diProducer, "" omitted: the engine rejects an empty value.)

    If m_PDF.OpenImportFileA(App.path & "\..\..\..\..\..\examples\test_files\test_invoice.pdf", ptOpen, "") < 0 Then GoTo done
    m_PDF.ImportPDFFile 1, 1#, 1#

    ' AttachFileEx lets us override the attachment name (XRechnung needs xrechnung.xml).
    BufSize = 0
    If GetFileBuffer(App.path & "\..\..\..\..\..\examples\test_files\factur-x.xml", buffer, BufSize) Then
        ef = m_PDF.AttachFileExA(VarPtr(buffer(0)), BufSize, InvoiceName, "EN 19631 compliant invoice", False)
    Else
        ef = m_PDF.AttachFileExA(0, 0, InvoiceName, "EN 19631 compliant invoice", False)
    End If

    ' ZUGFeRD 2.1+ and FacturX are identically defined in PDF and share version constants.
    If FacturX Then
        m_PDF.SetPDFVersion pvFacturX_Comfort
        m_PDF.AssociateEmbFile adCatalog, -1, arAlternative, ef
    Else
        m_PDF.SetPDFVersion pvFacturX_XRechnung
        m_PDF.AssociateEmbFile adCatalog, -1, arSource, ef
    End If

    ' No fatal error occurred?
    If m_PDF.HaveOpenDoc() Then
        If m_PDF.OpenOutputFileA(OutFile) Then
            CreateInvoice = CBool(m_PDF.CloseFile())
        End If
    End If
done:
    m_PDF.FreePDF
End Function

Public Sub Main()
    Dim outFile As String

    On Error GoTo ErrHandler
    Set m_PDF = CreateObject("LumasPdf.PDF")
    m_PDF.RaiseExceptions = True

    ' We write the test files into the application directory.
    outFile = App.path & "\out.pdf"

    ' Test cases: FacturX, then XRechnung (invoice name must be xrechnung.xml).
    If (Not CreateInvoice(True, "factur-x.xml", outFile)) Or (Not HaveEInvoice(outFile)) _
       Or (Not CreateInvoice(False, "xrechnung.xml", outFile)) Or (Not HaveEInvoice(outFile)) Then
        Debug.Print "XML Invoice not found!"
    Else
        Debug.Print "All tests passed!"
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not m_PDF Is Nothing Then extra = vbCrLf & "LumasPdf: " & m_PDF.LastErrorCode & " " & m_PDF.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "extract_invoice"
End Sub

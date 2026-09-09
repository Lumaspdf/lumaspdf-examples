Attribute VB_Name = "modBarcodes"
Option Explicit
' ============================================================================
'  barcodes -- LumasPdf ActiveX/COM component style (late-bound, no project
'  reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\barcodes -- same feature: writes every supported barcode
'  type onto a grid of pages.
'
'  The ActiveX server exposes InsertBarcodeStrA/W directly (BarcodeType +
'  Data string + ShowText, no native TPDFBarcode2 struct marshalling
'  needed), so it is called straight from pdf.InsertBarcodeStrA -- simpler
'  than the flat-DLL reference's helper indirection. Per-barcode errors are
'  tolerated (On Error Resume Next), same as the reference.
' ============================================================================

'--- TCellAlign -------------------------------------------------------------
Const taCenter As Long = 1
Const coCenter As Long = 2

'--- TPageCoord ---------------------------------------------------------------
Const pcTopDown As Long = 1

'--- TPathFillMode (fmStroke = 4) ----------------------------------------------
Const fmStroke As Long = 4

'--- TFStyle / TCodepage -------------------------------------------------------
Const fsRegular As Long = &H19000000
Const cp1252 As Long = 2

Private CODES() As Variant
Private nCodes As Long

Private Sub AddCode(ByVal bt As Long, ByVal nm As String, ByVal dat As String)
    CODES(nCodes) = Array(bt, nm, dat)
    nCodes = nCodes + 1
End Sub

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim outFile As String
    Dim x As Double, y As Double, w As Double, h As Double
    Dim pw As Double, ph As Double, incX As Double, incY As Double
    Dim i As Long, nx As Long, ny As Long, xx As Long, yy As Long

    nCodes = 0
    ReDim CODES(200)
    AddCode &H3F, "Australia Post", "12345678"
    AddCode &H44, "Australia Redirect Code", "12345678"
    AddCode &H42, "Australia Reply-Paid", "12345678"
    AddCode &H43, "Australia Routing Code", "12345678"
    AddCode &H5C, "Aztec binary mode", "123456789012"
    AddCode &H5C, "Aztec GS1 Mode", "[01]03453120000011[17]120508[10]ABCD1234[410]9501101020917"
    AddCode &H80, "Aztec Runes", "123"
    AddCode &H4, "Code 2 of 5 IATA", "1234567890"
    AddCode &H7, "Code 2 of 5 Industrial", "1234567890"
    AddCode &H3, "Code 2 of 5 Interleaved", "1234567890"
    AddCode &H6, "Code 2 of 5 Data Logic", "1234567890"
    AddCode &H2, "Code 2 of 5 Matrix", "1234567890"
    AddCode &H8C, "Channel Code", "1234567"
    AddCode &H12, "Codabar", "A123456789B"
    AddCode &H4A, "Codablock-F", "1234567890abcdefghijklmnopqrstuvwxyz"
    AddCode &H1, "Code 11", "1234567890"
    AddCode &H14, "Code 128", "1234567890"
    AddCode &H3C, "Code 128", "1234567890"
    AddCode &H17, "Code 16K binary mode", "[90]A1234567890"
    AddCode &H17, "Code 16K GS1 mode", "[90]A1234567890"
    AddCode &H81, "Code 32", "12345678"
    AddCode &H8, "Code 39", "1234567890"
    AddCode &H18, "Code 49", "1234567890"
    AddCode &H19, "Code 93", "1234567890"
    AddCode &H8D, "Code One", "1234567890"
    AddCode &H5D, "DAFT Code", "aftdaftdftaft"
    AddCode &H1D, "GS1 DataBar Omnidirectional", "0123456789012"
    AddCode &H51, "GS1 DataBar Stacked", "[90]1234567890"
    AddCode &H1F, "GS1 DataBar Expanded", "[90]1234567890"
    AddCode &H1E, "GS1 DataBar Limited", "0123456789012"
    AddCode &H4F, "GS1 DataBar Stacked", "0123456789012"
    AddCode &H50, "GS1 DataBar Stacked Omni", "0123456789012"
    AddCode &H47, "Data Matrix ISO 16022", "0123456789012"
    AddCode &H73, "DotCode", "0123456789012"
    AddCode &H60, "DPD Code", "1234567890123456789012345678"
    AddCode &H16, "Deutsche Post Identcode", "12345678901"
    AddCode &H15, "Deutsche Post Leitcode", "1234567890123"
    AddCode &H10, "EAN 128", "[90]0101234567890128TEC-IT"
    AddCode &H83, "EAN 128 Composite Code", "[10]1234-1234"
    AddCode &H48, "EAN 14", "1234567890"
    AddCode &HD, "EAN X", "1234567890"
    AddCode &H82, "EAN Composite Symbol", "[90]12341234"
    AddCode &HE, "EAN + Check Digit", "12345"
    AddCode &H9, "Ext. Code 3 of 9 (Code 39+)", "1234567890"
    AddCode &H31, "FIM", "d"
    AddCode &H1C, "Flattermarken", "11111111111111"
    AddCode &H70, "HIBC Aztec Code", "123456789012"
    AddCode &H6E, "HIBC Codablock-F", "1234567890abcdefghijklmnopqrstuvwxyz"
    AddCode &H62, "HIBC Code 128", "1234567890"
    AddCode &H63, "HIBC Code 39", "1234567890"
    AddCode &H66, "HIBC Data Matrix", "0123456789012"
    AddCode &H6C, "HIBC Micro PDF417", "01234567890abcde"
    AddCode &H6A, "HIBC PDF417", "01234567890abcde"
    AddCode &H68, "HIBC QR Code", "01234567890abcde"
    AddCode &H45, "ISBN (EAN-13 with validation)", "0123456789"
    AddCode &H59, "ITF-14", "0123456789"
    AddCode &H4C, "Japanese Postal Code", "0123456789"
    AddCode &H5A, "Dutch Post KIX Code", "0123456789"
    AddCode &H4D, "Korea Post", "123456"
    AddCode &H32, "LOGMARS", "1234567890abcdef"
    AddCode &H79, "Royal Mail 4-State Mailmark", "11210012341234567AB19XY1A"
    AddCode &H39, "Maxicode", "1234567890abcdef"
    AddCode &H54, "Micro PDF417", "1234567890abcdef"
    AddCode &H61, "Micro QR Code", "1234567890abcdef"
    AddCode &H47, "MSI Plessey", "12345678901"
    AddCode &H4B, "NVE-18", "1234567890123456"
    AddCode &H37, "PDF417", "1234567890abcdef"
    AddCode &H38, "PDF417 Truncated", "1234567890abcdef"
    AddCode &H33, "Pharmacode One-Track", "123456"
    AddCode &H35, "Pharmacode Two-Track", "123456"
    AddCode &H52, "PLANET", "12345678901"
    AddCode &H56, "Plessey", "12345678901"
    AddCode &H28, "PostNet", "12345678901"
    AddCode &H34, "PZN", "1234567"
    AddCode &H3A, "QR Code", "1234567890abcdef"
    AddCode &H91, "Rect. Micro QR Code (rMQR)", "1234567890abcdef"
    AddCode &H46, "Royal Mail 4 State (RM4SCC)", "1234567890abcdef"
    AddCode &H86, "CS GS1 DataBar Ext. component", "[90]12341234"
    AddCode &H8B, "CS GS1 DataBar Exp. Stacked", "[90]12341234"
    AddCode &H85, "CS GS1 DataBar Limited", "[90]12341234"
    AddCode &H84, "CS GS1 DataBar-14 Linear", "[90]12341234"
    AddCode &H89, "CS GS1 DataBar-14 Stacked", "[90]12341234"
    AddCode &H8A, "CS GS1 DataBar-14 Stacked Omni", "[90]12341234"
    AddCode &H20, "Telepen Alpha", "1234567890abcdef"
    AddCode &H90, "Ultracode", "1234567890abcdef"
    AddCode &H22, "UPC A", "1234567890"
    AddCode &H87, "CS UPC A linear", "[90]12341234"
    AddCode &H23, "UPC A + Check Digit", "12345678905"
    AddCode &H25, "UCP E", "1234567"
    AddCode &H88, "CS UPC E linear", "[90]12341234"
    AddCode &H26, "UCP E + Check Digit", "12345670"
    AddCode &H8F, "UPNQR (Univ. Placilni Nalog QR)", "1234567890abcdef"
    AddCode &H55, "USPS OneCode", "01234567094987654321"
    AddCode &H49, "Vehicle Ident Number (USA)", "01234567094987654"

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True

    pdf.CreateNewPDFW ""
    pdf.SetPageCoords pcTopDown

    pw = pdf.GetPageWidth - 100
    ph = pdf.GetPageHeight - 100
    w = 100
    h = 120
    nx = Int(pw / w)
    ny = Int(ph / h)
    incX = w + (pw - nx * w) / (nx - 1)
    incY = h + (ph - ny * h) / (ny - 1)
    h = 100
    i = 0

    Do While i < nCodes
        pdf.Append
        pdf.SetFontW "Helvetica", fsRegular, 6.5, True, cp1252
        pdf.SetLineWidth 0
        y = 50
        For yy = 1 To ny
            x = 50
            For xx = 1 To nx
                pdf.WriteFTextExW x, y - 10, w, -1, taCenter, CODES(i)(1)
                pdf.Rectangle x, y, w, h, fmStroke
                On Error Resume Next
                pdf.InsertBarcodeStrA x, y, w, h, coCenter, coCenter, CODES(i)(0), CODES(i)(2), True
                On Error GoTo ErrHandler
                i = i + 1
                x = x + incX
                If i = nCodes Then Exit For
            Next
            y = y + incY
            If i = nCodes Then Exit For
        Next
        pdf.EndPage
    Loop

    If pdf.HaveOpenDoc Then
        outFile = App.Path & "\out.pdf"
        If Not pdf.OpenOutputFileW(outFile) Then Exit Sub
    End If
    pdf.CloseFile
    Debug.Print "Barcodes """ & outFile & """ successfully created!"
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "barcodes (ActiveX)"
End Sub

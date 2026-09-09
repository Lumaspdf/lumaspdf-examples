Attribute VB_Name = "modProbeTest"
Option Explicit
' ============================================================================
'  probe_test -- LumasPdf ActiveX/COM component style (late-bound, no
'  project reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\probe_test -- same feature: step-by-step probe of the PDF
'  flow (in-memory CreateNewPDF + OpenOutputFile at the end + a table via
'  the Tbl* methods), logging each call's return value with Debug.Print.
'
'  Method mapping vs. the CPDF.cls/global-proc reference:
'    pdf.CreateNewPDF("")                          -> pdf.CreateNewPDFW("")
'    pdf.SetFont(...)                              -> pdf.SetFontW(...)   (Embed as VARIANT_BOOL)
'    pdf.WriteText(...)                             -> pdf.WriteTextW(...)
'    tblCreateTable(pdf.GetInstancePtr(), 3,3,W,H)  -> pdf.TblCreateTable(3,3,W,H)
'      (the instance-handle first argument is implicit via the pdf object and
'       is dropped -- every Tbl* global proc becomes a pdf.TblXxx instance
'       method the same way)
'    tblAddRow(tbl,-1!)                             -> pdf.TblAddRow(tbl,-1!)
'    tblSetCellTextA(tbl,r,0,taLeft,coTop,"cell",Len("cell"))
'                                                    -> pdf.TblSetCellTextA(tbl,r,0,taLeft,coTop,"cell",Len("cell"))
'    tblDrawTable(tbl,50!,80!,700!)                 -> pdf.TblDrawTable(tbl,50!,80!,700!)
'    tblHaveMore(tbl)                                -> pdf.TblHaveMore(tbl)
'    tblDeleteTable tbl                              -> pdf.TblDeleteTable delHandle  (ByRef Variant)
' ============================================================================

'--- TPageCoord ---------------------------------------------------------------------
Const pcTopDown As Long = 1

'--- TFStyle --------------------------------------------------------------------------
Const fsRegular As Long = &H19000000

'--- TCodepage (index 2 = cp1252) ------------------------------------------------------
Const cp1252 As Long = 2

'--- TCellAlign -------------------------------------------------------------------------
Const taLeft As Long = 0
Const coTop As Long = 0

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim tbl As Variant, r As Long
    Dim outFile As String

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True            ' turn engine errors into VB6 errors

    Debug.Print "Create ok"
    Debug.Print "CreateNewPDFW('') = " & pdf.CreateNewPDFW("")
    Debug.Print "SetPageCoords = " & pdf.SetPageCoords(pcTopDown)
    Debug.Print "Append = " & pdf.Append
    Debug.Print "SetFontW = " & pdf.SetFontW("Arial", fsRegular, 12#, True, cp1252)
    Debug.Print "WriteTextW = " & pdf.WriteTextW(50, 50, "probe")

    tbl = pdf.TblCreateTable(3, 3, 500!, 100!)
    Debug.Print "Table created"
    r = pdf.TblAddRow(tbl, -1!)
    Debug.Print "AddRow = " & r
    ' Pass the real string length (not -1): the AX marshaller passes a BSTR,
    ' so Len=-1 makes the engine over-read (access violation).
    Debug.Print "SetCellText = " & pdf.TblSetCellTextA(tbl, r, 0, taLeft, coTop, "cell", Len("cell"))
    Debug.Print "DrawTable = " & pdf.TblDrawTable(tbl, 50!, 80!, 700!)
    Debug.Print "HaveMore = " & pdf.TblHaveMore(tbl)
    Dim delHandle As Variant
    delHandle = tbl
    pdf.TblDeleteTable delHandle

    Debug.Print "EndPage = " & pdf.EndPage
    Debug.Print "GetPageCount = " & pdf.GetPageCount()
    Debug.Print "HaveOpenDoc = " & pdf.HaveOpenDoc
    outFile = App.Path & "\probe_out.pdf"
    Debug.Print "OpenOutputFileW = " & pdf.OpenOutputFileW(outFile)
    Debug.Print "CloseFile = " & pdf.CloseFile
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "probe_test (ActiveX)"
End Sub

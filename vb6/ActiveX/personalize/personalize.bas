Attribute VB_Name = "modPersonalize"
Option Explicit
' ============================================================================
'  personalize -- LumasPdf ActiveX/COM component style (late-bound, no
'  project reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\personalize -- same feature: import a tax form, fill in the
'  fields by direct text placement, add a web link.
'
'  Method mapping vs. the CPDF.cls reference (pdf.Xxx -> pdf.Xxx, same names,
'  just late-bound to the registered "LumasPdf.PDF" COM server instead of the
'  native wrapper class):
'    pdf.CreateNewPDF ""      -> pdf.CreateNewPDFW ""
'    pdf.OpenImportFile ...   -> pdf.OpenImportFileW ...
'    pdf.SetFont ...          -> pdf.SetFontW ...        (Embed is VARIANT_BOOL: False)
'    pdf.WriteText ...        -> pdf.WriteTextW ...
'    pdf.AddContinueTextA ... -> pdf.AddContinueTextA ... (unchanged)
'    pdf.WebLinkA ...         -> pdf.WebLinkA ...          (unchanged)
'    pdf.OpenOutputFile ...   -> pdf.OpenOutputFileW ...
' ============================================================================

'--- TViewerPreference ------------------------------------------------------------
Const vpDisplayDocTitle As Long = &H20
Const avNone As Long = &H0

'--- TImportFlags ------------------------------------------------------------------
Const ifImportAll As Long = &HFFFFFFE
Const ifImportAsPage As Long = &H80000000

'--- TPwdType -----------------------------------------------------------------------
Const ptOpen As Long = 0

'--- TFStyle (see src\Lumas.Pdf.Types.pas) -------------------------------------------
Const fsNone As Long = &H0
Const fsBold As Long = &H2BC00000

'--- TCodepage (index 2 = cp1252) ----------------------------------------------------
Const cp1252 As Long = 2

'--- THighlightMode -------------------------------------------------------------------
Const hmPush As Long = 3

'--- TAnnotationFlags ------------------------------------------------------------------
Const afReadOnly As Long = &H40

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim outFile As String, inFile As String

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True            ' turn engine errors into VB6 errors

    pdf.CreateNewPDFW ""                            ' output file opened later

    pdf.SetViewerPreferences vpDisplayDocTitle, avNone
    ' Conversion of pages to templates is normally not required.
    pdf.SetImportFlags ifImportAll Or ifImportAsPage
    inFile = App.Path & "\taxform.pdf"
    If pdf.OpenImportFileW(inFile, ptOpen, "") < 0 Then Exit Sub
    pdf.ImportPDFFile 1, 1#, 1#

    pdf.EditPage 1
    pdf.SetFontW "Courier", fsBold, 14#, False, cp1252
    pdf.WriteTextW 72.5, 748.5, "X"
    pdf.WriteTextW 74#, 701#, "Musterstadt"
    pdf.WriteTextW 74#, 677#, "252/1062/3323"
    pdf.BeginContinueText 74#, 628#
    pdf.SetLeading 24#
    pdf.SetCharacterSpacing 5.8
    pdf.AddContinueTextA "Mustermann"
    pdf.AddContinueTextA "Hermann"
    pdf.AddContinueTextA "22021963keineKaufmann"
    pdf.AddContinueTextA "Musterstra" & Chr$(223) & "e 145"   ' 223 = 'sharp s' in cp1252
    pdf.AddContinueTextA "12345Musterstadt"
    pdf.SetCharacterSpacing 0#
    pdf.SetFontW "Courier", fsBold, 10#, False, cp1252
    pdf.SetLeading 48#
    pdf.AddContinueTextA "04.05.1994"
    pdf.SetFontW "Courier", fsBold, 14#, False, cp1252
    pdf.SetCharacterSpacing 5.8
    pdf.AddContinueTextA "Sabine"
    pdf.SetLeading 47.5
    pdf.AddContinueTextA "18121966 ev  Hausfrau"
    pdf.EndContinueText
    pdf.WriteTextW 72.5, 365#, "X"
    pdf.WriteTextW 396#, 365#, "X"
    pdf.BeginContinueText 74#, 316#
    pdf.SetLeading 24#
    pdf.AddContinueTextA "2346256780     76834560"
    pdf.AddContinueTextA "Sparkasse Musterstadt"
    pdf.EndContinueText
    pdf.WriteTextW 72.5, 269#, "X"
    pdf.SetCharacterSpacing 0#
    pdf.SetFontW "Courier", fsNone, 10#, False, cp1252
    pdf.WriteTextW 53#, 48#, CStr(Now)
    pdf.SetFillColor RGB(&HFF, &H66, &H66)
    pdf.SetFontW "Helvetica", fsBold, 22#, False, cp1252
    pdf.WriteTextW 340#, 70#, "www.dynaforms.de"
    pdf.SetLineWidth 0#
    pdf.SetLinkHighlightMode hmPush
    pdf.SetAnnotFlags afReadOnly
    pdf.WebLinkA 340#, 64#, 204#, 22#, "http://www.dynaforms.de"
    pdf.EndPage

    ' No fatal error occurred?
    If CBool(pdf.HaveOpenDoc) Then
        outFile = App.Path & "\out.pdf"
        If CBool(pdf.OpenOutputFileW(outFile)) Then
            If CBool(pdf.CloseFile()) Then
                Debug.Print "PDF file """ & outFile & """ successfully created!"
            End If
        End If
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "personalize (ActiveX)"
End Sub

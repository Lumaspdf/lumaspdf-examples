Attribute VB_Name = "modPersonalize"
Option Explicit
' ============================================================================
'  personalize -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Imports a tax form, fills in the fields, adds a web link. The Delphi form UI
' pdf.RaiseExceptions = True
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim outFile As String, inFile As String
' pdf.RaiseExceptions = True

    pdf.CreateNewPDF ""                            ' output file opened later

    pdf.SetViewerPreferences vpDisplayDocTitle, avNone
    ' Conversion of pages to templates is normally not required.
    pdf.SetImportFlags ifImportAll Or ifImportAsPage
    inFile = App.Path & "\taxform.pdf"
    If pdf.OpenImportFile(inFile, ptOpen, "") < 0 Then Exit Sub
    pdf.ImportPDFFile 1, 1#, 1#

    pdf.EditPage 1
    pdf.SetFont "Courier", fsBold, 14#, 0, cp1252
    pdf.WriteText 72.5, 748.5, "X"
    pdf.WriteText 74#, 701#, "Musterstadt"
    pdf.WriteText 74#, 677#, "252/1062/3323"
    pdf.BeginContinueText 74#, 628#
    pdf.SetLeading 24#
    pdf.SetCharacterSpacing 5.8
    pdf.AddContinueTextA "Mustermann"
    pdf.AddContinueTextA "Hermann"
    pdf.AddContinueTextA "22021963keineKaufmann"
    pdf.AddContinueTextA "Musterstra" & Chr$(223) & "e 145"   ' 223 = 'sharp s' in cp1252
    pdf.AddContinueTextA "12345Musterstadt"
    pdf.SetCharacterSpacing 0#
    pdf.SetFont "Courier", fsBold, 10#, 0, cp1252
    pdf.SetLeading 48#
    pdf.AddContinueTextA "04.05.1994"
    pdf.SetFont "Courier", fsBold, 14#, 0, cp1252
    pdf.SetCharacterSpacing 5.8
    pdf.AddContinueTextA "Sabine"
    pdf.SetLeading 47.5
    pdf.AddContinueTextA "18121966 ev  Hausfrau"
    pdf.EndContinueText
    pdf.WriteText 72.5, 365#, "X"
    pdf.WriteText 396#, 365#, "X"
    pdf.BeginContinueText 74#, 316#
    pdf.SetLeading 24#
    pdf.AddContinueTextA "2346256780     76834560"
    pdf.AddContinueTextA "Sparkasse Musterstadt"
    pdf.EndContinueText
    pdf.WriteText 72.5, 269#, "X"
    pdf.SetCharacterSpacing 0#
    pdf.SetFont "Courier", fsNone, 10#, 0, cp1252
    pdf.WriteText 53#, 48#, CStr(Now)
    pdf.SetFillColor RGB(&HFF, &H66, &H66)
    pdf.SetFont "Helvetica", fsBold, 22#, 0, cp1252
    pdf.WriteText 340#, 70#, "www.dynaforms.de"
    pdf.SetLineWidth 0#
    pdf.SetLinkHighlightMode hmPush
    pdf.SetAnnotFlags afReadOnly
    pdf.WebLinkA 340#, 64#, 204#, 22#, "http://www.dynaforms.de"
    pdf.EndPage

    ' No fatal error occurred?
    If pdf.HaveOpenDoc <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) <> 0 Then
            If pdf.CloseFile <> 0 Then
                Debug.Print "PDF file """ & outFile & """ successfully created!"
            End If
        End If
    End If
End Sub

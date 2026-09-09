Attribute VB_Name = "modEditPage"
Option Explicit
' ============================================================================
'  edit_page -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Imports a rotated page, opens it for editing and writes a formatted text
' pdf.RaiseExceptions = True
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim f As Long, orientation As Long
    Dim inFile As String, outFile As String, s As String
    Dim B As String, CR As String

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""                          ' output file opened later

    ' Import anything and don't convert pages to templates
    pdf.SetImportFlags ifImportAll Or ifImportAsPage

    inFile = App.Path & "\rotated_270.pdf"
    If pdf.OpenImportFile(inFile, ptOpen, "") < 0 Then Exit Sub
    pdf.ImportPDFFile 1, 1#, 1#
    pdf.CloseImportFile

    pdf.SetPageCoords pcTopDown
    ' Move the coordinate origin into the visible area.
    pdf.SetUseVisibleCoords 1

    pdf.EditPage 1
        orientation = pdf.GetOrientation
        If orientation <> 0 Then pdf.SetOrientationEx orientation
        pdf.SetLeading 14#
        f = pdf.SetFont("Helvetica", fsRegular, 12#, 0, cp1252)
        pdf.SetListFont f

        ' We call the ANSI (A) export, so the bullet is code page 1252 char 144.
        B = Chr$(144)
        CR = Chr$(13)
        s = "It is not difficult to edit an imported page but two things must be considered:" & CR & CR & "\LI[20," & B & "]\LD[16]The page's " _
          & "orientation.\EL#\LI[20," & B & "]\LD[12]The coordinate origin. The coordinate origin can be taken from the crop box if present, or from the media box (Left and Bottom).\EL#" & CR & "\LD[12]" _
          & "Although it is possible to correct the coordinate origin manually, it is much easier to set the property SetUseVisibleCoords() to true. LumasPDF moves the zero point then automatically " _
          & "into the visible area of the page." & CR & CR _
          & "The functions GetPageWidth() and GetPageHeight() return then also the logical width or height of the page depending on the orientation and whether a crop box is present." & CR & CR _
          & "The handling of rotated pages is a bit more complicated since the orientation is just a property. That means there is no guarantee that the contents is rotated " _
          & "into the opposite direction like the contents in this page. Whether this is the case depends on the creator of the PDF file." & CR & CR _
          & "However, by default it is probably best to assume that the contents is rotated. SetOrientationEx() rotates the coordinate system so that we can work with the page as if it was " _
          & "not rotated. If this produces a wrong result then don't call SetOrientationEx()." & CR & CR _
          & "Now you ask probably yourself whether it is possible to identify the orientation of the contents in a page. The answer is maybe. It is possible to parse a page with ParseContent() " _
          & "and to inspect the transformation matrices but this can produce wrong results especially if a page contains not much contents."

        pdf.WriteFTextEx 50#, 200#, pdf.GetPageWidth - 100#, -1#, taJustify, s
    pdf.EndPage

    ' No fatal error occurred?
    If pdf.HaveOpenDoc <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile <> 0 Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
End Sub

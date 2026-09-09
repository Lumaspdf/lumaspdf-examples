Attribute VB_Name = "modAlphaTransparency"
Option Explicit
' ============================================================================
'  alpha_transparency -- ActiveX/COM version (LumasPdf.PDF, late-bound),
'  mirrors the plain-DLL example at
'  examples\Vb6\transparency\alpha_transparency (read-only reference, not
'  modified). Draws an image at fill alpha 0.5 and a second at the default
'  alpha 1.0 using extended graphics states.
'
'  CreateExtGState takes a positional Variant array overlay (index = the
'  TPDFExtGState field order; Empty = keep the InitExtGState default) and
'  returns the handle through the function result; FillAlpha is index 8.
' ============================================================================

Private Const clWhite As Long = &HFFFFFF   ' VCL TColor, not a PDF constant
Private Const clBlack As Long = &H0

Private Const fsRegular As Long = &H19000000
Private Const cp1252 As Long = 2
Private Const pcTopDown As Long = 1
Private Const fmFill As Long = 3           ' TPathFillMode (fmFill = 3, not 0)

Public Sub Main()
    Dim pdf As Object
    Dim gs As Long, img As Long
    Dim outFile As String
    Dim g As Variant

    On Error GoTo ErrHandler
    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True
    pdf.CreateNewPDFA ""              ' The output file is opened later

    pdf.SetPageCoords pcTopDown
    pdf.SetUseTransparency 0          ' Disable color key masking for images

    pdf.Append

    pdf.SetFontA "Helvetica", fsRegular, 12#, False, cp1252
    pdf.WriteTextA 50#, 50#, "Fill Alpha = 0.5"

    pdf.Rectangle 50#, 70#, 110#, 160#, fmFill
    pdf.SetFillColor clWhite
    pdf.WriteTextA 55#, 75#, "Background"

    ' FillAlpha = 0.5 (TPDFExtGState index 8).
    g = Array(Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, 0.5)
    gs = pdf.CreateExtGState(g)
    pdf.SetExtGState gs

    img = pdf.InsertImageEx(60#, 84#, 200#, 0#, App.path & "\..\..\..\..\..\examples\test_files\images\tree-frog-69813_640.jpg", 0)

    ' To restore an extended graphics state, create a second one that restores the changes.
    g = Array(Empty, Empty, Empty, Empty, Empty, Empty, Empty, Empty, 1#)
    gs = pdf.CreateExtGState(g)
    pdf.SetExtGState gs

    pdf.SetFillColor clBlack
    pdf.WriteTextA 340#, 50#, "Fill Alpha = 1.0 (default)"
    pdf.Rectangle 340#, 70#, 110#, 160#, fmFill
    pdf.SetFillColor clWhite
    pdf.WriteTextA 345#, 75#, "Background"
    pdf.PlaceImage img, 350#, 84#, 200#, 0#

    pdf.EndPage

    ' No fatal error occurred?
    If pdf.HaveOpenDoc() Then
        outFile = App.path & "\out.pdf"
        If Not pdf.OpenOutputFileA(outFile) Then Exit Sub
        If pdf.CloseFile() Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "alpha_transparency"
End Sub

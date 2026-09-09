Attribute VB_Name = "modOptimize"
Option Explicit
' ============================================================================
'  optimize -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Imports a PDF, runs Optimize() over it and writes the result. The Delphi
'  original's unregistered font/ICC callbacks and the error callback are
' pdf.RaiseExceptions = True
'  Optimize(Flags, Parms) takes the TOptimizeParams struct as a positional
'  Variant array -- Array() = all defaults.
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim outFile As String, inFile As String
' pdf.RaiseExceptions = True

    pdf.CreateNewPDF ""                               ' output file opened later

    ' ifImportAsPage avoids converting pages to templates; drop the piece info dictionary.
    pdf.SetImportFlags (ifImportAll Or ifImportAsPage) And Not ifPieceInfo
    ' if2UseProxy reduces memory usage; duplicate check + normalize recommended.
    pdf.SetImportFlags2 if2UseProxy Or if2DuplicateCheck Or if2Normalize Or if2NoResNameCheck

    inFile = App.Path & "\dynapdf_help.pdf"
    If pdf.OpenImportFile(inFile, ptOpen, "") < 0 Then
        Debug.Print "Could not open import file!"
        Exit Sub
    End If
    pdf.ImportPDFFile 1, 1#, 1#
    pdf.CloseImportFile

    ' Optimize with default parameters (Array() = keep defaults / zero).
    pdf.Optimize ofInMemory Or ofNewLinkNames Or ofDeleteInvPaths, Array()

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

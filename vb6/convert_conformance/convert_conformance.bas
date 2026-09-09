Attribute VB_Name = "modConvertConformance"
Option Explicit
' ============================================================================
'  convert_conformance -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules (VB6
'  mirror of examples\c\convert_conformance\convert_conformance.c). Early-bound
'  to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp): the OO object AND
'  all enums (ctPDFA_2b, ctPDFX_4) come from the typelib. plain PDF -> PDF/A and
'  PDF/X, each a SINGLE 7-arg ConvertFile call (VB6/COM cannot pass the native
' pdf.RaiseExceptions = True
'  A compiled GUI exe has no stdout, so the two rc lines are written to
'  result.txt (and Debug.Print'd in the IDE). Run the exe FROM this folder so
'  the ../../test_files/... relative paths resolve.
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim a As Long, x As Long, f As Integer
' pdf.RaiseExceptions = True

    ' ctPDFA_2b ; sRGB + ISOcoated CMYK profiles embedded
    a = pdfConvertFileA(pdf.GetInstancePtr(), "../../test_files/plain.pdf", "out_pdfa.pdf", ctPDFA_2b, 0, _
            "../../test_files/sRGB.icc", "../../test_files/ISOcoated_v2_bas.ICC", "", 0, 0, 0)
    Debug.Print "plain -> PDF/A (ctPDFA_2b) rc=" & a

    ' ctPDFX_4
    x = pdfConvertFileA(pdf.GetInstancePtr(), "../../test_files/plain.pdf", "out_pdfx.pdf", ctPDFX_4, 0, _
            "../../test_files/sRGB.icc", "../../test_files/ISOcoated_v2_bas.ICC", "", 0, 0, 0)
    Debug.Print "plain -> PDF/X (ctPDFX_4)  rc=" & x

    f = FreeFile
    Open App.Path & "\result.txt" For Output As #f
    Print #f, "plain -> PDF/A (ctPDFA_2b) rc=" & a
    Print #f, "plain -> PDF/X (ctPDFX_4)  rc=" & x
    Close #f
End Sub

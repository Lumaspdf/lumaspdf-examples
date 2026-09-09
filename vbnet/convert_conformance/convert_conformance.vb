' convert_conformance -- plain PDF -> PDF/A and PDF/X, each a SINGLE method call.
' VB.NET port of examples\c\convert_conformance\convert_conformance.c
Imports System
Imports LumasPdfSdk

Module ConvertConformance
    Function Main() As Integer
        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()

        Dim a As Integer = LumasPdf.pdfConvertFileW(pdf, _
            "../../test_files/plain.pdf", "out_pdfa.pdf", _
            CInt(TConformanceType.ctPDFA_2b), 0UI, _
            "../../test_files/sRGB.icc", _
            "../../test_files/ISOcoated_v2_bas.ICC", _
            Nothing, IntPtr.Zero, Nothing, Nothing)
        Console.WriteLine("plain -> PDF/A (ctPDFA_2b) rc=" & a)

        Dim x As Integer = LumasPdf.pdfConvertFileW(pdf, _
            "../../test_files/plain.pdf", "out_pdfx.pdf", _
            CInt(TConformanceType.ctPDFX_4), 0UI, _
            "../../test_files/sRGB.icc", _
            "../../test_files/ISOcoated_v2_bas.ICC", _
            Nothing, IntPtr.Zero, Nothing, Nothing)
        Console.WriteLine("plain -> PDF/X (ctPDFX_4)  rc=" & x)

        LumasPdf.pdfDeletePDF(pdf)
        Return If(a < 0 OrElse x < 0, 1, 0)
    End Function
End Module

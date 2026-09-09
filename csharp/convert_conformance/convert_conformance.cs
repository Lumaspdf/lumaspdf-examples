// ============================================================================
//  convert_conformance -- plain PDF -> PDF/A and PDF/X, each a SINGLE method call.
//  C# port of examples\c\convert_conformance\convert_conformance.c
// ============================================================================
using System;
using LumasPdfSdk;

class ConvertConformance
{
    static int Main()
    {
        IntPtr pdf = LumasPdf.pdfNewPDF();

        int a = LumasPdf.pdfConvertFileW(pdf,
            "../../test_files/plain.pdf", "out_pdfa.pdf",
            (int)TConformanceType.ctPDFA_2b, 0,
            "../../test_files/sRGB.icc",
            "../../test_files/ISOcoated_v2_bas.ICC",
            null, IntPtr.Zero, null, null);
        Console.WriteLine("plain -> PDF/A (ctPDFA_2b) rc=" + a);

        int x = LumasPdf.pdfConvertFileW(pdf,
            "../../test_files/plain.pdf", "out_pdfx.pdf",
            (int)TConformanceType.ctPDFX_4, 0,
            "../../test_files/sRGB.icc",
            "../../test_files/ISOcoated_v2_bas.ICC",
            null, IntPtr.Zero, null, null);
        Console.WriteLine("plain -> PDF/X (ctPDFX_4)  rc=" + x);

        LumasPdf.pdfDeletePDF(pdf);
        return (a < 0 || x < 0) ? 1 : 0;
    }
}

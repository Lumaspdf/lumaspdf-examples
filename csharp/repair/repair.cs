// ============================================================================
//  repair -- fix a damaged PDF with a SINGLE method: pdfConvertFileA(ctNormalize).
//  C# port of examples\c\repair\repair.c
// ============================================================================
using System;
using LumasPdfSdk;

class Repair
{
    static int Main()
    {
        IntPtr pdf = LumasPdf.pdfNewPDF();
        int rc = LumasPdf.pdfConvertFileW(pdf,
            "../../test_files/corrupt.pdf",   // 4-page damaged input (mangled xref)
            "repaired.pdf",
            (int)TConformanceType.ctNormalize, 0,
            null, null, null, IntPtr.Zero, null, null);

        // Native GetInRepairMode is a LongBool (-1 when true); mirror the C (int) cast.
        int mode = LumasPdf.pdfGetInRepairMode(pdf) ? -1 : 0;
        Console.WriteLine("pdfConvertFile(ctNormalize) rc=" + rc +
            "  (repair-mode used: " + mode + ")");

        LumasPdf.pdfDeletePDF(pdf);
        return rc < 0 ? 1 : 0;
    }
}

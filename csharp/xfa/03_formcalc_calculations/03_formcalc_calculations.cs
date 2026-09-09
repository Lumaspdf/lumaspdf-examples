// ============================================================================
//  03_formcalc_calculations -- C# port of examples\delphi\xfa\03_formcalc_calculations
//  XFA "flavor tour" example 3 of 10: the FormCalc engine (lexer -> parser ->
//  VM -> builtin catalog) end-to-end through pdfRenderXFAForm. A single-page
//  "Order Calculator": customer/date header, 3-line item table (bound qty +
//  unit price), and a calculated summary block (line totals, subtotal,
//  average price, item count, discount tier + amount, grand total) driven by
//  <calculate><script contentType="application/x-formcalc"> bodies.
//
//  Same pipeline as every example in this tour:
//    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
//    pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
// ============================================================================
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class FormCalcCalculations
{
    static int RenderExample(string exeDir, string baseName, string outPdfPath)
    {
        string templatePath = Path.Combine(exeDir, baseName + ".template.xml");
        string datasetsPath = Path.Combine(exeDir, baseName + ".datasets.xml");

        Console.WriteLine("=== " + baseName + " -> " + Path.GetFileName(outPdfPath) + " ===");
        if (!File.Exists(templatePath)) { Console.WriteLine("FILE-NOT-FOUND: " + templatePath); return -100; }

        byte[] templateBuf = File.ReadAllBytes(templatePath);
        byte[] datasetsBuf = File.Exists(datasetsPath) ? File.ReadAllBytes(datasetsPath) : new byte[0];
        Console.WriteLine("template packet bytes: " + templateBuf.Length);
        Console.WriteLine("datasets packet bytes: " + datasetsBuf.Length);

        IntPtr pdf = LumasPdf.pdfNewPDF();
        if (pdf == IntPtr.Zero) { Console.WriteLine("pdfNewPDF FAILED"); return -100; }
        try
        {
            if (!LumasPdf.pdfCreateNewPDFW(pdf, outPdfPath)) { Console.WriteLine("pdfCreateNewPDFA FAILED"); return -100; }

            GCHandle hTpl = GCHandle.Alloc(templateBuf, GCHandleType.Pinned);
            int idx;
            try { idx = LumasPdf.pdfCreateXFAStreamW(pdf, "template", hTpl.AddrOfPinnedObject(), (uint)templateBuf.Length); }
            finally { hTpl.Free(); }
            Console.WriteLine("pdfCreateXFAStreamA(template) -> index " + idx);
            if (idx < 0) { Console.WriteLine("pdfCreateXFAStreamA(template) FAILED"); return -100; }

            if (datasetsBuf.Length > 0)
            {
                GCHandle hDs = GCHandle.Alloc(datasetsBuf, GCHandleType.Pinned);
                try { idx = LumasPdf.pdfCreateXFAStreamW(pdf, "datasets", hDs.AddrOfPinnedObject(), (uint)datasetsBuf.Length); }
                finally { hDs.Free(); }
                Console.WriteLine("pdfCreateXFAStreamA(datasets) -> index " + idx);
                if (idx < 0) { Console.WriteLine("pdfCreateXFAStreamA(datasets) FAILED"); return -100; }
            }
            else
            {
                Console.WriteLine("(no datasets packet found -- template-only render)");
            }

            int rc = LumasPdf.pdfRenderXFAForm(pdf);
            Console.WriteLine("pdfRenderXFAForm -> " + rc + " (expected: page count >= 1)");
            if (rc < 1) { Console.WriteLine("RENDER-FAILED, code " + rc); return rc; }

            if (!LumasPdf.pdfCloseFile(pdf)) { Console.WriteLine("pdfCloseFile FAILED"); return -101; }
            Console.WriteLine("OK: wrote " + outPdfPath + " (" + rc + " page(s))");
            return rc;
        }
        finally
        {
            LumasPdf.pdfDeletePDF(pdf);
        }
    }

    static void Main()
    {
        try
        {
            string exeDir = AppDomain.CurrentDomain.BaseDirectory;
            int rc = RenderExample(exeDir, "03_formcalc_calculations", Path.Combine(exeDir, "03_formcalc_calculations.render.pdf"));
            Console.WriteLine();
            Console.WriteLine("RESULT|03_formcalc_calculations=" + rc);
            if (rc >= 1)
            {
                Console.WriteLine("OK: rendered " + rc + " page(s). Open the render and confirm (dataset: Alex Nguyen,");
                Console.WriteLine("Jul 15 2026, Widget 3x12.50 / Gadget 2x45.00 / Gizmo 5x8.00, threshold=100):");
                Console.WriteLine("  Item1Total       = 37.5   (3 x 12.50)");
                Console.WriteLine("  Item2Total       = 90     (2 x 45.00)");
                Console.WriteLine("  Item3Total       = 40     (5 x 8.00)");
                Console.WriteLine("  TotalQty         = 10     (Sum of 3,2,5)");
                Console.WriteLine("  Subtotal         = 167.5  (Sum of line totals)");
                Console.WriteLine("  AvgUnitPrice     = 21.83  (Round(Avg(12.50,45.00,8.00),2))");
                Console.WriteLine("  ItemCount        = 3      (Count())");
                Console.WriteLine("  DiscountLabel    = \"Bulk Discount\" (167.5 >= 100)");
                Console.WriteLine("  DiscountAmount   = 16.75  (Round(167.5*0.10,2))");
                Console.WriteLine("  GrandTotal       = 150.75 (167.5 - 16.75)");
                Console.WriteLine("  FullName         = \"Alex Nguyen\" (Concat)");
                Console.WriteLine("  CustomerInitial  = \"A\"    (Upper(Left(\"Alex\",1)))");
                Console.WriteLine("  OrderDateNum(disp) = 2026-07-15 (Date2Num/Num2Date epoch, bug #fixed 2026-07-24)");
                Console.WriteLine("  OrderDateFormatted = \"7/15/26\" (Num2Date(OrderDateNum, DateFmt(1)))");
            }
            else
            {
                Console.WriteLine("FAILED, see errors above.");
            }
        }
        catch (Exception e)
        {
            Console.WriteLine("EXCEPTION: " + e.GetType().Name + ": " + e.Message);
        }
    }
}

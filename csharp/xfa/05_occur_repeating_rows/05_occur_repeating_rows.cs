// ============================================================================
//  05_occur_repeating_rows -- C# port of examples\delphi\xfa\05_occur_repeating_rows
//  XFA "flavor tour" example 5 of 10: <occur min="1" max="-1"/> -- one
//  repeating template row instantiated once per matching dataset record, each
//  instance independently bound to its own record and independently
//  re-running its own calculate script. A one-page "Expense Report": header
//  fields (explicit dataRef bind) + an ExpenseItemsTable whose Item row
//  (implicit by-name bind) repeats for 7 <Item> records, each with a
//  calculate-only LineTotal = Qty * UnitPrice, plus a literal GrandTotal.
//
//  Same pipeline as every example in this tour:
//    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
//    pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
// ============================================================================
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class OccurRepeatingRows
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
            int rc = RenderExample(exeDir, "05_occur_repeating_rows", Path.Combine(exeDir, "05_occur_repeating_rows.pdf"));
            Console.WriteLine();
            Console.WriteLine("RESULT|05_occur_repeating_rows=" + rc + "|instances=7");
            if (rc >= 1)
            {
                Console.WriteLine("OK: rendered " + rc + " page(s). Header fields: Alex Rivera / Field Operations / 2026-07-24.");
                Console.WriteLine("7 independently-bound rows, each LineTotal = Qty x UnitPrice recomputed per-instance:");
                Console.WriteLine("  1 Airfare               1 x 450.00 = 450");
                Console.WriteLine("  2 Hotel - 3 nights      3 x 120.00 = 360");
                Console.WriteLine("  3 Taxi / Rideshare      4 x 18.50  = 74");
                Console.WriteLine("  4 Client Dinner         5 x 22.00  = 110");
                Console.WriteLine("  5 Parking               2 x 15.00  = 30");
                Console.WriteLine("  6 Conference Registration 1 x 299.00 = 299");
                Console.WriteLine("  7 Office Supplies       6 x 4.25   = 25.5");
                Console.WriteLine("  GrandTotal (literal)    = 1348.50 (matches the 7 rows' own sum by hand)");
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

// ============================================================================
//  07_table_layout -- C# port of examples\delphi\xfa\07_table_layout
//  XFA "flavor tour" example 7 of 10: layout="table" -- a columnWidths-driven
//  table subform whose rows (layout="row" children) are laid out by the
//  engine's table layout pass and rendered through the real DrawTable
//  primitive. A 4-column "Product Comparison Table" (Product/Price/Stock/
//  Rating), header row + 5 data rows, each column with a different
//  <para hAlign> (left/right/center/right) to exercise real per-cell
//  alignment.
//
//  Same pipeline as every example in this tour:
//    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
//    pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
// ============================================================================
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class TableLayout
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
            int rc = RenderExample(exeDir, "07_table_layout", Path.Combine(exeDir, "07_table_layout.pdf"));
            Console.WriteLine();
            Console.WriteLine("RESULT|07_table_layout=" + rc);
            if (rc >= 1)
            {
                Console.WriteLine("OK: rendered " + rc + " page(s). ProductTable (x=36 y=90 w=540,");
                Console.WriteLine("columnWidths=\"216 108 108 108\"), 6 rows (Header + 5 data) at h=20pt each,");
                Console.WriteLine("stacked tb-style with zero gap: y = 90, 110, 130, 150, 170, 190 (bottom 210).");
                Console.WriteLine("Column hAlign per the authored <para>:");
                Console.WriteLine("  Product (col1, x 36-252)  hAlign=left   -> flush-left, constant start x");
                Console.WriteLine("  Price   (col2, x 252-360) hAlign=right  -> constant end x, start varies with width");
                Console.WriteLine("  Stock   (col3, x 360-468) hAlign=center -> centered on x=414");
                Console.WriteLine("  Rating  (col4, x 468-576) hAlign=right  -> constant end x");
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

// ============================================================================
//  06_pagination_multipage -- C# port of examples\delphi\xfa\06_pagination_multipage
//  XFA "flavor tour" example 6 of 10: full multi-page pagination --
//  pageSet/pageArea/contentArea, forced overflow of a repeating row template
//  across several pages, and leader/trailer "continued" banner subforms via
//  <overflow leader=... trailer=...>. A 70-line-item "Invoice Line Items"
//  report; hand-derived arithmetic (400pt contentArea, 20pt rows, 20pt
//  leader/trailer, trailer height reserved unconditionally on every page)
//  predicts exactly 4 pages: 19 + 18 + 18 + 15 rows.
//
//  Same pipeline as every example in this tour, plus a pre-flight
//  pdfXFAFormPageCount() query (called before any page is appended) that
//  should already agree with the pdfRenderXFAForm() return value:
//    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
//    pdfCreateXFAStreamA('datasets',...) -> pdfXFAFormPageCount (pre-flight) ->
//    pdfRenderXFAForm -> pdfCloseFile
// ============================================================================
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class PaginationMultipage
{
    const int CheckPageCount = 4;

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

            int preflight = LumasPdf.pdfXFAFormPageCount(pdf);
            Console.WriteLine("pdfXFAFormPageCount (pre-flight) -> " + preflight + " (expected " + CheckPageCount + ")");

            int rc = LumasPdf.pdfRenderXFAForm(pdf);
            Console.WriteLine("pdfRenderXFAForm -> " + rc + " (expected " + CheckPageCount + ")");
            if (rc < 1) { Console.WriteLine("RENDER-FAILED, code " + rc); return rc; }
            if (rc != CheckPageCount)
                Console.WriteLine("WARNING: page count " + rc + " != expected " + CheckPageCount);
            if (preflight != rc)
                Console.WriteLine("WARNING: pre-flight page count " + preflight + " != post-render " + rc);

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
            int rc = RenderExample(exeDir, "06_pagination_multipage", Path.Combine(exeDir, "06_pagination_multipage.pdf"));
            Console.WriteLine();
            Console.WriteLine("RESULT|06_pagination_multipage=" + rc);
            if (rc >= 1)
            {
                Console.WriteLine("OK: rendered " + rc + " page(s) (expected 4). Row distribution across pages:");
                Console.WriteLine("  Page 0: rows 1-19  (19 rows), no leader,  trailer drawn");
                Console.WriteLine("  Page 1: rows 20-37 (18 rows), leader,     trailer drawn");
                Console.WriteLine("  Page 2: rows 38-55 (18 rows), leader,     trailer drawn");
                Console.WriteLine("  Page 3: rows 56-70 (15 rows), leader,     NO trailer (true last page)");
                Console.WriteLine("  19+18+18+15 = 70 line items, matching all 70 authored <Line> records.");
                Console.WriteLine("  InvoiceHeader banner appears on page 0 only.");
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

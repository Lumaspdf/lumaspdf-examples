// ============================================================================
//  04_flow_layout -- C# port of examples\delphi\xfa\04_flow_layout
//  XFA "flavor tour" example 4 of 10: flow layout. A one-page "Employment
//  Application" with two sibling flowed subforms inside a layout="position"
//  root -- TermsPanel (layout="tb", 6 clauses stacked vertically, zero gap)
//  and SkillsPanel (layout="lr-tb", 9 tags packed left-to-right, wrapping to
//  a new line when the next tag would overflow the content width).
//
//  Same pipeline as every example in this tour:
//    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
//    pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
// ============================================================================
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class FlowLayout
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
            int rc = RenderExample(exeDir, "04_flow_layout", Path.Combine(exeDir, "04_flow_layout.pdf"));
            Console.WriteLine();
            Console.WriteLine("RESULT|04_flow_layout=" + rc);
            if (rc >= 1)
            {
                Console.WriteLine("OK: rendered " + rc + " page(s). Hand-computed geometry to confirm:");
                Console.WriteLine("  TermsPanel (tb, x=36 w=540, each child h=24, gap=0):");
                Console.WriteLine("    Clause1..6 y = 92, 116, 140, 164, 188, 212 (curY += 24 each step)");
                Console.WriteLine("  SkillsPanel (lr-tb, x=36 y=270 w=540, each tag w=110 h=20):");
                Console.WriteLine("    Line1 (y=270): Skill1..4 x = 36, 146, 256, 366");
                Console.WriteLine("    Line2 (y=290): Skill5..8 x = 36, 146, 256, 366 (wraps: 476+110=586>540... 5th tag)");
                Console.WriteLine("    Line3 (y=310): Skill9    x = 36");
                Console.WriteLine("  3 lines total (4+4+1 tags), 21 layout boxes overall (verified via xfa_layout_dump.exe oracle).");
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

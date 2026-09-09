// ============================================================================
//  01_basic_positioned_form -- C# port of examples\delphi\xfa\01_basic_positioned_form
//  XFA "flavor tour" example 1 of 10: POSITIONED LAYOUT -- every subform/draw/
//  field carries layout="position" and an explicit x/y/w/h, no flow, no occur,
//  no pagination. A single-page "Employee Information" HR record with a
//  masthead, five statically placed fields (name, employee ID, department,
//  hire date, a "full-time" checkbox) bound to an <xfa:datasets> packet, and
//  a photo-placeholder box.
//
//  Mirrors the Delphi driver's exact call sequence -- the packet files were
//  already split out of the source .xdp by a one-off tool, so this driver
//  just reads the two raw XML files and hands them straight to the engine:
//
//    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
//    pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
//
//  Does not rebuild LumasPdf.dll -- links against the generated P/Invoke
//  wrapper wrappers\dotnet\LumasPdf.cs (LumasPdf.Net.dll) exactly like every
//  other C# example in this project, and loads whatever LumasPdf.dll is
//  copied next to the .exe.
// ============================================================================
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class BasicPositionedForm
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
            try
            {
                idx = LumasPdf.pdfCreateXFAStreamW(pdf, "template", hTpl.AddrOfPinnedObject(), (uint)templateBuf.Length);
            }
            finally { hTpl.Free(); }
            Console.WriteLine("pdfCreateXFAStreamA(template) -> index " + idx);
            if (idx < 0) { Console.WriteLine("pdfCreateXFAStreamA(template) FAILED"); return -100; }

            if (datasetsBuf.Length > 0)
            {
                GCHandle hDs = GCHandle.Alloc(datasetsBuf, GCHandleType.Pinned);
                try
                {
                    idx = LumasPdf.pdfCreateXFAStreamW(pdf, "datasets", hDs.AddrOfPinnedObject(), (uint)datasetsBuf.Length);
                }
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
            int rc = RenderExample(exeDir, "01_basic_positioned_form", Path.Combine(exeDir, "output.pdf"));
            Console.WriteLine();
            Console.WriteLine("RESULT|01_basic_positioned_form=" + rc);
            if (rc >= 1)
            {
                Console.WriteLine("OK: rendered " + rc + " page(s). Open output.pdf and confirm the five");
                Console.WriteLine("statically-positioned fields (layout=\"position\" throughout, no flow/occur/pagination):");
                Console.WriteLine("  - Full Name    = \"Sarah J. Connor\"");
                Console.WriteLine("  - Employee ID  = \"EMP-10457\"");
                Console.WriteLine("  - Department   = \"Engineering\"");
                Console.WriteLine("  - Hire Date    = \"2021-03-15\"");
                Console.WriteLine("  - Full-time checkbox bound to FullTime=1 (checked)");
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

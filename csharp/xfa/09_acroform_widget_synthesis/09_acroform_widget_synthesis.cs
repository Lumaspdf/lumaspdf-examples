// ============================================================================
//  09_acroform_widget_synthesis -- C# port of examples\delphi\xfa\09_acroform_widget_synthesis
//  XFA "flavor tour" example 9 of 10: pdfSetXFARenderMode(doc, 1) -- turning
//  an XFA form into a genuinely fillable AcroForm PDF, not just flattened
//  ink. Renders the SAME .xdp TWICE:
//    mode0.pdf -- Mode 0 (default, pdfSetXFARenderMode never called): flattened
//                 ink only, no /AcroForm/Fields.
//    mode1.pdf -- Mode 1 (pdfSetXFARenderMode(doc, 1) called AFTER both
//                 pdfCreateXFAStreamA calls and BEFORE pdfRenderXFAForm):
//                 flattened ink PLUS a real synthesized /AcroForm with 9
//                 fillable fields (textEdit/numericEdit/dateTimeEdit -> Tx,
//                 checkButton exclGroup -> one Btn w/ 3 Kids, choiceList ->
//                 Ch, button -> Btn pushbutton w/ real bevel /AP, and 3
//                 occur-repeated Employer[n].EmployerName Tx fields).
//
//  Same pipeline as every other example in this tour, with exactly one extra
//  call for the second pass:
//    pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
//    pdfCreateXFAStreamA('datasets',...) -> [pdfSetXFARenderMode(doc,1) only
//    for the second pass] -> pdfRenderXFAForm -> pdfCloseFile -> pdfDeletePDF
// ============================================================================
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class AcroformWidgetSynthesis
{
    // Mode: 0 = flatten-to-ink only (default, no pdfSetXFARenderMode call at
    // all -- exercises the untouched default path); 1 = also synthesize real
    // AcroForm fillable widgets.
    static int RenderExample(string exeDir, string baseName, string outPdfPath, int mode)
    {
        string templatePath = Path.Combine(exeDir, baseName + ".template.xml");
        string datasetsPath = Path.Combine(exeDir, baseName + ".datasets.xml");

        Console.WriteLine("=== " + baseName + " (mode=" + mode + ") -> " + Path.GetFileName(outPdfPath) + " ===");
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

            if (mode != 0)
            {
                int prev = LumasPdf.pdfSetXFARenderMode(pdf, mode);
                Console.WriteLine("pdfSetXFARenderMode(pdf, " + mode + ") -> previous=" + prev + " (expect 0, the default)");
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
            int r0 = RenderExample(exeDir, "09_acroform_widget_synthesis", Path.Combine(exeDir, "mode0.pdf"), 0);
            int r1 = RenderExample(exeDir, "09_acroform_widget_synthesis", Path.Combine(exeDir, "mode1.pdf"), 1);

            Console.WriteLine();
            Console.WriteLine("RESULT|mode0=" + r0 + "|mode1=" + r1);
            if (r0 >= 1 && r1 >= 1)
            {
                Console.WriteLine("OK: both renders succeeded.");
                Console.WriteLine("  mode0.pdf -- flattened ink only, NO /AcroForm/Fields.");
                Console.WriteLine("  mode1.pdf -- flattened ink PLUS a REAL fillable AcroForm, 9 top-level fields:");
                Console.WriteLine("    ApplicantName (Tx)=\"Jordan Rivera\", YearsExperience (Tx)=\"7\",");
                Console.WriteLine("    ApplicationDate (Tx)=\"2026-07-24\",");
                Console.WriteLine("    EmploymentType (Btn radio, 3 Kids: Full-time/Part-time/Contract, V=/Full-time),");
                Console.WriteLine("    Department (Ch combo, 6 options, V=\"Engineering\", Ff=131072 bit18 Combo),");
                Console.WriteLine("    SubmitButton (Btn pushbutton, real bevel /AP, no /V),");
                Console.WriteLine("    Employer[0].EmployerName=\"Acme Robotics\",");
                Console.WriteLine("    Employer[1].EmployerName=\"Nimbus Data Systems\",");
                Console.WriteLine("    Employer[2].EmployerName=\"BrightPath Logistics\".");
                Console.WriteLine("  Open mode1.pdf in a real PDF reader (Acrobat, Chrome, Edge, etc.) --");
                Console.WriteLine("  it is a genuinely fillable form: click into the fields and type.");
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

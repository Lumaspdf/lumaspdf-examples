// ============================================================================
//  comments -- C# port of examples\Vb6\incremental_updates\comments\comments.bas
//  Incremental updates: create a file with one square annotation in memory, then
//  repeatedly reply to the annotation (and to the reply) saving each step as an
//  incremental update, and finally write the result to disk.
// ============================================================================
using System;
using System.IO;
using System.Runtime.InteropServices;
using LumasPdfSdk;

class Comments
{
    static TErrorProc _err = PDFError;

    static int PDFError(IntPtr data, int errCode, string errMessage, int errType)
    {
        Console.WriteLine(errMessage);
        return 0;
    }

    static bool CreateTestFile(IntPtr pdf, ref byte[] buf)
    {
        LumasPdf.pdfCreateNewPDFW(pdf, "");
        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);

        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfSquareAnnotW(pdf, 50.0, 50.0, 200.0, 100.0, 3.0, LumasPdfConsts.NO_COLOR, 255,
            TPDFColorSpace.csDeviceRGB, "Jim", "Test", "Just a test...");
        LumasPdf.pdfEndPage(pdf);

        if (!LumasPdf.pdfCloseFile(pdf)) return false;
        uint bufSize = 0;
        IntPtr p = LumasPdf.pdfGetBuffer(pdf, ref bufSize);
        if (p == IntPtr.Zero || bufSize == 0) return false;
        buf = new byte[bufSize];
        Marshal.Copy(p, buf, 0, (int)bufSize);
        // Release the original buffer; this also resets the PDF instance.
        LumasPdf.pdfFreePDF(pdf);
        return true;
    }

    static bool LoadTestFile(IntPtr pdf, byte[] buf)
    {
        LumasPdf.pdfCreateNewPDFW(pdf, "");
        LumasPdf.pdfSetImportFlags2(pdf, LumasPdfConsts.if2IncrementalUpd);
        GCHandle h = GCHandle.Alloc(buf, GCHandleType.Pinned);
        try
        {
            if (LumasPdf.pdfOpenImportBuffer(pdf, h.AddrOfPinnedObject(), (uint)buf.Length,
                    (int)LumasPdfConsts.ptOpen, "") < 0) return false;
            return LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0) > 0;
        }
        finally { h.Free(); }
    }

    static bool SaveFile(IntPtr pdf, ref byte[] buf)
    {
        if (!LumasPdf.pdfCloseFile(pdf)) return false;
        uint bufSize = 0;
        IntPtr p = LumasPdf.pdfGetBuffer(pdf, ref bufSize);
        if (p == IntPtr.Zero || bufSize == 0) return false;
        buf = new byte[bufSize];
        Marshal.Copy(p, buf, 0, (int)bufSize);
        LumasPdf.pdfFreePDF(pdf);
        return true;
    }

    static void Main()
    {
        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);

        byte[] buf = null;
        if (!CreateTestFile(pdf, ref buf))
        {
            LumasPdf.pdfDeletePDF(pdf);
            return;
        }

        if (LoadTestFile(pdf, buf))
        {
            // The file contains only one annotation; its handle is zero (an array index).
            int reply = LumasPdf.pdfSetAnnotMigrationStateW(pdf, 0, TAnnotState.asCreateReply, "Harry");
            LumasPdf.pdfSetAnnotStringW(pdf, (uint)reply, (int)TAnnotString.asContent,
                "Hi Jim, your test annotation looks fine!");
            if (SaveFile(pdf, ref buf) && LoadTestFile(pdf, buf))
            {
                reply = LumasPdf.pdfSetAnnotMigrationStateW(pdf, (uint)reply, TAnnotState.asCreateReply, "Tommy");
                LumasPdf.pdfSetAnnotStringW(pdf, (uint)reply, (int)TAnnotString.asContent,
                    "Just a test whether I can reply to a reply...");
                if (SaveFile(pdf, ref buf) && LoadTestFile(pdf, buf))
                {
                    reply = LumasPdf.pdfSetAnnotMigrationStateW(pdf, (uint)reply, TAnnotState.asCreateReply, "Jim");
                    LumasPdf.pdfSetAnnotStringW(pdf, (uint)reply, (int)TAnnotString.asContent,
                        "Seems to work very well!");
                    if (LumasPdf.pdfHaveOpenDoc(pdf))
                    {
                        string filePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");
                        if (LumasPdf.pdfOpenOutputFileW(pdf, filePath))
                        {
                            if (LumasPdf.pdfCloseFile(pdf))
                                Console.WriteLine("PDF file \"" + filePath + "\" successfully created!");
                        }
                    }
                }
            }
        }

        LumasPdf.pdfDeletePDF(pdf);
    }
}

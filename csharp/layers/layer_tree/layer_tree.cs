// ============================================================================
//  layer_tree -- C# port of examples\Vb6\layers\layer_tree\layer_tree.bas
//  Creates three optional-content groups (layers) arranged in a display tree with
//  a titled group, and adds text (with a web link) and an image to the layers.
// ============================================================================
using System;
using System.IO;
using LumasPdfSdk;

class LayerTree
{
    const uint clBlue = 0xFF0000;
    const uint clBlack = 0x0;

    static TErrorProc _err = PDFError;

    static int PDFError(IntPtr data, int errCode, string errMessage, int errType)
    {
        Console.WriteLine(errMessage);
        return 0;
    }

    static void Main()
    {
        string exeDir = AppDomain.CurrentDomain.BaseDirectory;

        IntPtr pdf = LumasPdf.pdfNewPDF();
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(pdf, "");   // output file opened later

        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);

        // Disable color key masking for images
        LumasPdf.pdfSetUseTransparency(pdf, false);

        // Create three layers
        int oc1 = LumasPdf.pdfCreateOCGW(pdf, "All", false, true, LumasPdfConsts.oiAll);
        int oc2 = LumasPdf.pdfCreateOCGW(pdf, "Text and Annotations", false, true, LumasPdfConsts.oiAll);
        int oc3 = LumasPdf.pdfCreateOCGW(pdf, "Images", false, true, LumasPdfConsts.oiAll);

        IntPtr root = LumasPdf.pdfAddLayerToDisplTreeW(pdf, IntPtr.Zero, oc1, "A layer group with a title");
        IntPtr grp = LumasPdf.pdfAddLayerToDisplTreeW(pdf, root, -1, "");
        LumasPdf.pdfAddLayerToDisplTreeW(pdf, grp, oc2, "");
        LumasPdf.pdfAddLayerToDisplTreeW(pdf, grp, oc3, "");

        LumasPdf.pdfAppend(pdf);
        // The main layer controls the visibility of all three layers in this example.
        LumasPdf.pdfBeginLayer(pdf, (uint)oc1);
        LumasPdf.pdfBeginLayer(pdf, (uint)oc2);
        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 12.0, false, TCodepage.cp1252);
        string someText = "Some text with a link!!!";
        LumasPdf.pdfSetFillColor(pdf, clBlue);
        LumasPdf.pdfWriteTextW(pdf, 50.0, 50.0, someText);
        double tw = LumasPdf.pdfGetTextWidthW(pdf, someText);
        LumasPdf.pdfSetBorderStyle(pdf, (int)TBorderStyle.bsUnderline);
        LumasPdf.pdfSetStrokeColor(pdf, clBlue);
        int annot = LumasPdf.pdfWebLinkW(pdf, 50.0, 51.0, tw, 12.0, "www.lumaspdf.com");

        uint[] ocArray = new uint[] { (uint)oc1, (uint)oc2 };
        int ocmd = LumasPdf.pdfCreateOCMD(pdf, TOCVisibility.ovAllOn, ocArray, 2);
        LumasPdf.pdfAddObjectToLayer(pdf, (uint)ocmd, TOCObject.ooAnnotation, (uint)annot);
        LumasPdf.pdfEndLayer(pdf);

        LumasPdf.pdfBeginLayer(pdf, (uint)oc3);
        LumasPdf.pdfInsertImageExW(pdf, 50.0, 70.0, 300.0, 200.0,
            Path.Combine(exeDir, "margarita-102572_640.jpg"), 1);
        LumasPdf.pdfEndLayer(pdf);
        LumasPdf.pdfEndLayer(pdf);

        LumasPdf.pdfSetFillColor(pdf, clBlack);
        LumasPdf.pdfWriteTextW(pdf, 50.0, 300.0, "This text is not part of a layer!");
        LumasPdf.pdfEndPage(pdf);

        LumasPdf.pdfSetPageMode(pdf, (int)TPageMode.pmUseOC);

        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            string outFile = Path.Combine(exeDir, "out.pdf");
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile))
            {
                LumasPdf.pdfDeletePDF(pdf);
                return;
            }
            if (LumasPdf.pdfCloseFile(pdf))
                Console.WriteLine("PDF file \"" + outFile + "\" successfully created!");
        }
        LumasPdf.pdfDeletePDF(pdf);
    }
}

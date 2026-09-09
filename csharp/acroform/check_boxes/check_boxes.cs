//  check_boxes -- C# port of examples\Vb6\acroform\check_boxes\check_boxes.bas
//  Normal check boxes, field groups (radio-like), radio buttons and a reset action.
using System;
using System.IO;
using LumasPdfSdk;

class CheckBoxes
{
    const uint clLtGray = 12632256;   // VCL clLtGray (= clSilver)

    static readonly TErrorProc _err = PDFError;
    static int PDFError(IntPtr Data, int ErrCode, string ErrMessage, int ErrType) { return 0; }

    static void Main()
    {
        double y;
        IntPtr pdf = LumasPdf.pdfNewPDF();

        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(pdf, "");   // output file opened later

        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);

        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 10.0, false, TCodepage.cp1252);
        LumasPdf.pdfWriteTextW(pdf, 50, 50, "Normal check boxes.");

        LumasPdf.pdfChangeFontSize(pdf, 1.0);
        int f = LumasPdf.pdfCreateCheckBox(pdf, "N1", "C1", 1, -1, 50, 70, 20, 20);
        LumasPdf.pdfSetCheckBoxDefState(pdf, (uint)f, true);
        f = LumasPdf.pdfCreateCheckBox(pdf, "N2", "C2", 1, -1, 80, 70, 20, 20);
        LumasPdf.pdfSetCheckBoxDefState(pdf, (uint)f, true);
        f = LumasPdf.pdfCreateCheckBox(pdf, "N3", "C1", 1, -1, 110, 70, 20, 20);
        LumasPdf.pdfSetCheckBoxDefState(pdf, (uint)f, true);

        LumasPdf.pdfChangeFontSize(pdf, 10.0);
        LumasPdf.pdfWriteTextW(pdf, 50, 100, "Field group with check boxes.");

        LumasPdf.pdfChangeFontSize(pdf, 1.0);
        LumasPdf.pdfCreateCheckBox(pdf, "G1", "C1", 0, -1, 50, 120, 20, 20);
        LumasPdf.pdfCreateCheckBox(pdf, "G1", "C2", 0, -1, 80, 120, 20, 20);
        LumasPdf.pdfCreateCheckBox(pdf, "G1", "C1", 1, -1, 110, 120, 20, 20);

        LumasPdf.pdfChangeFontSize(pdf, 10.0);
        LumasPdf.pdfWriteFTextExW(pdf, 50, 150, 220, -1, (int)LumasPdfConsts.taLeft,
            "This group works like a radio button but only radio buttons get a round border if the check box character is set to ccCircle. No problem, set the border width to zero and draw the circle in background if needed.");

        y = LumasPdf.pdfGetPageHeight(pdf) - LumasPdf.pdfGetLastTextPosY(pdf) + 10.0;

        LumasPdf.pdfChangeFontSize(pdf, 1.0);
        LumasPdf.pdfSetCheckBoxChar(pdf, (int)TCheckBoxChar.ccCircle);
        LumasPdf.pdfCreateCheckBox(pdf, "G2", "C1", 0, -1, 50, y, 20, 20);
        LumasPdf.pdfCreateCheckBox(pdf, "G2", "C2", 0, -1, 80, y, 20, 20);
        LumasPdf.pdfCreateCheckBox(pdf, "G2", "C3", 1, -1, 110, y, 20, 20);

        LumasPdf.pdfChangeFontSize(pdf, 10.0);
        LumasPdf.pdfWriteFTextExW(pdf, 300, 50, 250, -1, (int)LumasPdfConsts.taLeft,
            "This is a radio button. Since Acrobat 7 it is no longer possible to deselect the active check box, except with a reset form or Javascript action.");

        y = LumasPdf.pdfGetPageHeight(pdf) - LumasPdf.pdfGetLastTextPosY(pdf) + 10.0;

        LumasPdf.pdfChangeFontSize(pdf, 15.0);
        int r = LumasPdf.pdfCreateRadioButton(pdf, "Radio1", "R1", 1, -1, 300, y, 20, 20);
        LumasPdf.pdfSetCheckBoxDefState(pdf, (uint)r, false);
        LumasPdf.pdfCreateCheckBox(pdf, "", "R2", 0, r, 330, y, 20, 20);
        LumasPdf.pdfCreateCheckBox(pdf, "", "R3", 0, r, 360, y, 20, 20);

        LumasPdf.pdfChangeFontSize(pdf, 10.0);
        f = LumasPdf.pdfCreateButtonW(pdf, "Reset", "Reset", -1, 400, y, 60, 20);
        LumasPdf.pdfSetFieldColor(pdf, (uint)f, (int)TFieldColor.fcBackColor, (int)TPDFColorSpace.csDeviceRGB, clLtGray);
        LumasPdf.pdfSetFieldBorderStyle(pdf, (uint)f, (int)TBorderStyle.bsBevelled);

        int act = LumasPdf.pdfCreateResetAction(pdf);
        LumasPdf.pdfAddActionToObj(pdf, (int)TObjType.otField, (int)TObjEvent.oeOnMouseUp, (uint)act, (uint)f);
        LumasPdf.pdfAddFieldToFormAction(pdf, (uint)act, (uint)r, true);

        y = y + 40.0;
        LumasPdf.pdfChangeFontSize(pdf, 10.0);
        LumasPdf.pdfWriteFTextExW(pdf, 300, y, 250, -1, (int)LumasPdfConsts.taLeft,
            "The RadioIsUnion flag has only an effect if at least two check boxes use the same export value.");
        y = LumasPdf.pdfGetPageHeight(pdf) - LumasPdf.pdfGetLastTextPosY(pdf) + 10.0;

        LumasPdf.pdfChangeFontSize(pdf, 15.0);
        r = LumasPdf.pdfCreateRadioButton(pdf, "Radio2", "R1", 1, -1, 300, y, 20, 20);
        LumasPdf.pdfSetFieldFlags(pdf, (uint)r, (int)LumasPdfConsts.ffRadioIsUnion, false);
        LumasPdf.pdfCreateCheckBox(pdf, "", "R2", 0, r, 330, y, 20, 20);
        LumasPdf.pdfCreateCheckBox(pdf, "", "R1", 1, r, 360, y, 20, 20);
        LumasPdf.pdfCreateCheckBox(pdf, "", "R2", 0, r, 390, y, 20, 20);
        LumasPdf.pdfEndPage(pdf);

        if (LumasPdf.pdfHaveOpenDoc(pdf))
        {
            string outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf");
            if (!LumasPdf.pdfOpenOutputFileW(pdf, outFile)) { LumasPdf.pdfDeletePDF(pdf); return; }
            if (LumasPdf.pdfCloseFile(pdf))
                Console.WriteLine("PDF file \"" + outFile + "\" successfully created!");
        }

        LumasPdf.pdfDeletePDF(pdf);
    }
}

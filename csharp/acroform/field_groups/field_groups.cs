//  field_groups -- C# port of examples\Vb6\acroform\field_groups\field_groups.bas
//  Several text fields sharing one value (a field group), auto-size vs fixed
//  font size, plus a reset button.
using System;
using System.IO;
using LumasPdfSdk;

class FieldGroups
{
    const uint clLtGray = 12632256;

    static readonly TErrorProc _err = PDFError;
    static int PDFError(IntPtr Data, int ErrCode, string ErrMessage, int ErrType) { return 0; }

    static void Main()
    {
        double baseY, y;
        string cr = "\r";
        IntPtr pdf = LumasPdf.pdfNewPDF();

        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(pdf, "");

        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);

        LumasPdf.pdfAppend(pdf);
        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 12.0, false, TCodepage.cp1252);
        LumasPdf.pdfSetLeading(pdf, 14.0);
        LumasPdf.pdfWriteFTextExW(pdf, 50, 50, LumasPdf.pdfGetPageWidth(pdf) - 100.0, -1, (int)LumasPdfConsts.taJustify,
            "The six text fields share the same value. Such an array of fields is called a field group. All fields in the group must be of the same type." + cr + cr +
            "A field group can be created in two different ways: either create two or more fields with the same name or pass the handle of the base field as Parent to the children. " +
            "The latter way is more efficient since it is not required to search for the parent field when a child will be created." + cr + cr +
            "Enter some more text into a field to see the difference between auto size and fixed font size.");

        baseY = LumasPdf.pdfGetPageHeight(pdf) - LumasPdf.pdfGetLastTextPosY(pdf) + 20.0;

        LumasPdf.pdfWriteFTextExW(pdf, 50, baseY, 200, -1, (int)LumasPdfConsts.taLeft, "Font size <= 1.0 means auto size.");

        y = LumasPdf.pdfGetPageHeight(pdf) - LumasPdf.pdfGetLastTextPosY(pdf) + 10.0;

        LumasPdf.pdfChangeFontSize(pdf, 1.0);
        int f = LumasPdf.pdfCreateTextField(pdf, "Auto", -1, 0, 0, 50, y, 200, 20);
        LumasPdf.pdfSetTextFieldValueW(pdf, (uint)f, "Some text...", "Some text...", LumasPdfConsts.taLeft);

        y = y + 30.0;
        LumasPdf.pdfCreateTextField(pdf, "", f, 0, 0, 50, y, 200, 30);

        y = y + 40.0;
        LumasPdf.pdfCreateTextField(pdf, "", f, 0, 0, 50, y, 200, 40);

        LumasPdf.pdfChangeFontSize(pdf, 12.0);
        LumasPdf.pdfWriteFTextExW(pdf, 345, baseY, 200, -1, (int)LumasPdfConsts.taLeft, "The same fields with a fixed font size.");

        y = LumasPdf.pdfGetPageHeight(pdf) - LumasPdf.pdfGetLastTextPosY(pdf) + 10.0;

        LumasPdf.pdfChangeFontSize(pdf, 12.0);
        LumasPdf.pdfCreateTextField(pdf, "", f, 0, 0, 345, y, 200, 20);

        y = y + 30.0;
        LumasPdf.pdfChangeFontSize(pdf, 24.0);
        LumasPdf.pdfCreateTextField(pdf, "", f, 0, 0, 345, y, 200, 30);

        y = y + 40.0;
        LumasPdf.pdfChangeFontSize(pdf, 34.0);
        LumasPdf.pdfCreateTextField(pdf, "", f, 0, 0, 345, y, 200, 40);

        LumasPdf.pdfChangeFontSize(pdf, 18.0);
        f = LumasPdf.pdfCreateButtonW(pdf, "Reset", "Reset", -1, 222.5, y + 80.0, 150, 25);
        LumasPdf.pdfSetFieldColor(pdf, (uint)f, (int)TFieldColor.fcBackColor, (int)TPDFColorSpace.csDeviceRGB, clLtGray);
        LumasPdf.pdfSetFieldBorderStyle(pdf, (uint)f, (int)TBorderStyle.bsBevelled);

        int act = LumasPdf.pdfCreateResetAction(pdf);
        LumasPdf.pdfAddActionToObj(pdf, (int)TObjType.otField, (int)TObjEvent.oeOnMouseUp, (uint)act, (uint)f);
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

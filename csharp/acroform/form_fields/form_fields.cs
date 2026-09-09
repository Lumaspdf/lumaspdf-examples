//  form_fields -- C# port of examples\Vb6\acroform\form_fields\form_fields.bas
//  Text fields (single/multi-line/password/comb), combo boxes, list boxes,
//  editable combo, check boxes and radio buttons.
using System;
using System.IO;
using LumasPdfSdk;

class FormFields
{
    static readonly TErrorProc _err = PDFError;
    static int PDFError(IntPtr Data, int ErrCode, string ErrMessage, int ErrType) { return 0; }

    static void Main()
    {
        double y;
        IntPtr pdf = LumasPdf.pdfNewPDF();

        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, _err);
        LumasPdf.pdfCreateNewPDFW(pdf, "");

        LumasPdf.pdfSetPageCoords(pdf, (int)TPageCoord.pcTopDown);

        LumasPdf.pdfAppend(pdf);
        y = 50.0;
        LumasPdf.pdfSetFontW(pdf, "Helvetica", LumasPdfConsts.fsRegular, 10.0, false, TCodepage.cp1252);
        LumasPdf.pdfWriteTextW(pdf, 50, y, "Text fields:");

        y = y + 15.0;
        int f = LumasPdf.pdfCreateTextField(pdf, "Text1", -1, 0, 0, 50, y, 200, 20);
        LumasPdf.pdfSetTextFieldValueW(pdf, (uint)f, "", "Single line text...", LumasPdfConsts.taLeft);

        y = y + 30.0;
        f = LumasPdf.pdfCreateTextField(pdf, "Text2", -1, 1, 0, 50, y, 200, 50);
        LumasPdf.pdfSetTextFieldValueW(pdf, (uint)f, "", "This field accepts multi-line text. The maximum text length can be restricted if necessary.", LumasPdfConsts.taLeft);

        y = y + 60.0;
        LumasPdf.pdfWriteTextW(pdf, 50, y, "A password field:");
        y = y + 15.0;
        f = LumasPdf.pdfCreateTextField(pdf, "Text3", -1, 0, 0, 50, y, 200, 20);
        LumasPdf.pdfSetFieldFlags(pdf, (uint)f, (int)LumasPdfConsts.ffPassword, false);
        LumasPdf.pdfSetTextFieldValueW(pdf, (uint)f, "", "**********", LumasPdfConsts.taLeft);

        y = y + 30.0;
        LumasPdf.pdfWriteTextW(pdf, 50, y, "A fixed length field separated into combs:");
        y = y + 15.0;
        f = LumasPdf.pdfCreateTextField(pdf, "Text4", -1, 0, 10, 50, y, 200, 20);
        LumasPdf.pdfSetFieldFlags(pdf, (uint)f, (int)LumasPdfConsts.ffComb, false);

        y = 50.0;
        LumasPdf.pdfWriteTextW(pdf, 350, y, "Choice fields:");
        y = y + 15.0;
        f = LumasPdf.pdfCreateComboBox(pdf, "Combo1", 1, -1, 350, y, 200, 20);
        LumasPdf.pdfAddValToChoiceFieldW(pdf, (uint)f, "", " Select a value...", 1);
        LumasPdf.pdfAddValToChoiceFieldW(pdf, (uint)f, "Apple", "Apple", 0);
        LumasPdf.pdfAddValToChoiceFieldW(pdf, (uint)f, "Banana", "Banana", 0);
        LumasPdf.pdfAddValToChoiceFieldW(pdf, (uint)f, "Pear", "Pear", 0);
        LumasPdf.pdfAddValToChoiceFieldW(pdf, (uint)f, "Grape", "Grape", 0);
        LumasPdf.pdfAddValToChoiceFieldW(pdf, (uint)f, "Orange", "Orange", 0);

        y = y + 30.0;
        f = LumasPdf.pdfCreateListBox(pdf, "List", true, -1, 350, y, 200, 50);
        LumasPdf.pdfAddValToChoiceFieldW(pdf, (uint)f, "Apple", "Apple", 0);
        LumasPdf.pdfAddValToChoiceFieldW(pdf, (uint)f, "Banana", "Banana", 1);
        LumasPdf.pdfAddValToChoiceFieldW(pdf, (uint)f, "Pear", "Pear", 0);
        LumasPdf.pdfAddValToChoiceFieldW(pdf, (uint)f, "Grape", "Grape", 0);
        LumasPdf.pdfAddValToChoiceFieldW(pdf, (uint)f, "Orange", "Orange", 0);

        y = y + 60.0;
        LumasPdf.pdfWriteTextW(pdf, 350, y, "Editable combo box:");
        y = y + 15.0;
        f = LumasPdf.pdfCreateComboBox(pdf, "Combo2", 1, -1, 350, y, 200, 20);
        LumasPdf.pdfAddValToChoiceFieldW(pdf, (uint)f, "Apple", "Apple", 0);
        LumasPdf.pdfAddValToChoiceFieldW(pdf, (uint)f, "Banana", "Banana", 0);
        LumasPdf.pdfAddValToChoiceFieldW(pdf, (uint)f, "Pear", "Pear", 0);
        LumasPdf.pdfAddValToChoiceFieldW(pdf, (uint)f, "Grape", "Grape", 0);
        LumasPdf.pdfAddValToChoiceFieldW(pdf, (uint)f, "Orange", "Orange", 0);
        LumasPdf.pdfSetFieldFlags(pdf, (uint)f, (int)LumasPdfConsts.ffEdit, false);
        LumasPdf.pdfSetFieldExpValueW(pdf, (uint)f, 1000, "Select or enter a value...", "", true);

        y = y + 30.0;
        LumasPdf.pdfWriteTextW(pdf, 350, y, "Check boxes / Radio buttons:");

        y = y + 15.0;
        LumasPdf.pdfChangeFontSize(pdf, 1.0);
        LumasPdf.pdfCreateCheckBox(pdf, "N1", "C1", 1, -1, 350, y, 20, 20);
        LumasPdf.pdfCreateCheckBox(pdf, "N2", "C2", 1, -1, 380, y, 20, 20);
        LumasPdf.pdfCreateCheckBox(pdf, "N3", "C1", 1, -1, 410, y, 20, 20);

        LumasPdf.pdfCreateCheckBox(pdf, "G1", "C1", 0, -1, 450, y, 20, 20);
        LumasPdf.pdfCreateCheckBox(pdf, "G1", "C2", 0, -1, 480, y, 20, 20);
        LumasPdf.pdfCreateCheckBox(pdf, "G1", "C1", 1, -1, 510, y, 20, 20);
        LumasPdf.pdfCreateCheckBox(pdf, "G1", "C2", 0, -1, 540, y, 20, 20);

        y = y + 30.0;
        LumasPdf.pdfChangeFontSize(pdf, 15.0);
        LumasPdf.pdfSetCheckBoxChar(pdf, (int)TCheckBoxChar.ccCircle);
        int r = LumasPdf.pdfCreateRadioButton(pdf, "Radio1", "R1", 1, -1, 350, y, 20, 20);
        LumasPdf.pdfSetCheckBoxDefState(pdf, (uint)r, false);
        LumasPdf.pdfCreateCheckBox(pdf, "", "R2", 0, r, 380, y, 20, 20);
        LumasPdf.pdfCreateCheckBox(pdf, "", "R3", 0, r, 410, y, 20, 20);

        r = LumasPdf.pdfCreateRadioButton(pdf, "Radio2", "R1", 1, -1, 450, y, 20, 20);
        LumasPdf.pdfSetFieldFlags(pdf, (uint)r, (int)LumasPdfConsts.ffRadioIsUnion, false);
        LumasPdf.pdfCreateCheckBox(pdf, "", "R2", 0, r, 480, y, 20, 20);
        LumasPdf.pdfCreateCheckBox(pdf, "", "R1", 1, r, 510, y, 20, 20);
        LumasPdf.pdfCreateCheckBox(pdf, "", "R2", 0, r, 540, y, 20, 20);
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

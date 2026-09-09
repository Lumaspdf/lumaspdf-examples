/* field_groups -- C (x64) port of examples\Vb6\acroform\field_groups.bas */
#include <stdio.h>
#include <string.h>
#include "lumaspdf.h"

#define clLtGray 12632256

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType)
{
    (void)Data; (void)ErrCode; (void)ErrType;
    if (ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static void exedir(const char* a0, char* out, size_t n){char* s;strncpy(out,a0,n-1);out[n-1]=0;s=strrchr(out,'\\');if(!s)s=strrchr(out,'/');if(s)*s=0;else strcpy(out,".");}

int main(int argc, char** argv)
{
    SI32 act, f;
    double base, y;
    PPDF pdf;
    char dir[1024], outFile[1200];

    exedir(argv[0], dir, sizeof(dir));
    (void)argc;

    pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, 0, ErrProc);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);
    pdfSetFontA(pdf, "Helvetica", fsRegular, 12.0, 0, cp1252);
    pdfSetLeading(pdf, 14.0);
    pdfWriteFTextExA(pdf, 50.0, 50.0, pdfGetPageWidth(pdf) - 100.0, -1.0, taJustify,
        "The six text fields share the same value. Such an array of fields is called a field group. All fields in the group must be of the same type.\r\r"
        "A field group can be created in two different ways: either create two or more fields with the same name or pass the handle of the base field as Parent to the children. "
        "The latter way is more efficient since it is not required to search for the parent field when a child will be created.\r\r"
        "Enter some more text into a field to see the difference between auto size and fixed font size.");

    base = pdfGetPageHeight(pdf) - pdfGetLastTextPosY(pdf) + 20.0;

    pdfWriteFTextExA(pdf, 50.0, base, 200.0, -1.0, taLeft, "Font size <= 1.0 means auto size.");

    y = pdfGetPageHeight(pdf) - pdfGetLastTextPosY(pdf) + 10.0;

    pdfChangeFontSize(pdf, 1.0);
    f = pdfCreateTextField(pdf, "Auto", -1, 0, 0, 50.0, y, 200.0, 20.0);
    pdfSetTextFieldValueA(pdf, f, "Some text...", "Some text...", taLeft);

    y = y + 30.0;
    pdfCreateTextField(pdf, "", f, 0, 0, 50.0, y, 200.0, 30.0);

    y = y + 40.0;
    pdfCreateTextField(pdf, "", f, 0, 0, 50.0, y, 200.0, 40.0);

    pdfChangeFontSize(pdf, 12.0);
    pdfWriteFTextExA(pdf, 345.0, base, 200.0, -1.0, taLeft, "The same fields with a fixed font size.");

    y = pdfGetPageHeight(pdf) - pdfGetLastTextPosY(pdf) + 10.0;

    pdfChangeFontSize(pdf, 12.0);
    pdfCreateTextField(pdf, "", f, 0, 0, 345.0, y, 200.0, 20.0);

    y = y + 30.0;
    pdfChangeFontSize(pdf, 24.0);
    pdfCreateTextField(pdf, "", f, 0, 0, 345.0, y, 200.0, 30.0);

    y = y + 40.0;
    pdfChangeFontSize(pdf, 34.0);
    pdfCreateTextField(pdf, "", f, 0, 0, 345.0, y, 200.0, 40.0);

    pdfChangeFontSize(pdf, 18.0);
    f = pdfCreateButtonA(pdf, "Reset", "Reset", -1, 222.5, y + 80.0, 150.0, 25.0);
    pdfSetFieldColor(pdf, f, fcBackColor, csDeviceRGB, clLtGray);
    pdfSetFieldBorderStyle(pdf, f, bsBevelled);

    act = pdfCreateResetAction(pdf);
    pdfAddActionToObj(pdf, otField, oeOnMouseUp, act, f);
    pdfEndPage(pdf);

    if (pdfHaveOpenDoc(pdf) != 0) {
        _snprintf(outFile, sizeof(outFile), "%s\\out.pdf", dir);
        if (pdfOpenOutputFileA(pdf, outFile) == 0) {
            pdfDeletePDF(pdf);
            return 0;
        }
        if (pdfCloseFile(pdf) != 0)
            printf("PDF file \"%s\" successfully created!\n", outFile);
    }

    pdfDeletePDF(pdf);
    return 0;
}

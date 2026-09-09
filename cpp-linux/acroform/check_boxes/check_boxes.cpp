// check_boxes -- C++ port of examples\Vb6\acroform\check_boxes\check_boxes.bas
#include <lumaspdf.h>
#include <cstdio>
#include <string>

static const long clLtGray = 12632256;   // VCL clLtGray (= clSilver)

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    return 0;   // try to continue if an error occurs
}

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

int main(int argc, char** argv){
    SI32 act, f, r;
    double y;

    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);
    pdfSetFontA(pdf, "Helvetica", fsRegular, 10.0, 0, cp1252);
    pdfWriteTextA(pdf, 50.0, 50.0, "Normal check boxes.");

    pdfChangeFontSize(pdf, 1.0);
    f = pdfCreateCheckBox(pdf, "N1", "C1", 1, -1, 50.0, 70.0, 20.0, 20.0);
    pdfSetCheckBoxDefState(pdf, f, 1);
    f = pdfCreateCheckBox(pdf, "N2", "C2", 1, -1, 80.0, 70.0, 20.0, 20.0);
    pdfSetCheckBoxDefState(pdf, f, 1);
    f = pdfCreateCheckBox(pdf, "N3", "C1", 1, -1, 110.0, 70.0, 20.0, 20.0);
    pdfSetCheckBoxDefState(pdf, f, 1);

    pdfChangeFontSize(pdf, 10.0);
    pdfWriteTextA(pdf, 50.0, 100.0, "Field group with check boxes.");

    pdfChangeFontSize(pdf, 1.0);
    pdfCreateCheckBox(pdf, "G1", "C1", 0, -1, 50.0, 120.0, 20.0, 20.0);
    pdfCreateCheckBox(pdf, "G1", "C2", 0, -1, 80.0, 120.0, 20.0, 20.0);
    pdfCreateCheckBox(pdf, "G1", "C1", 1, -1, 110.0, 120.0, 20.0, 20.0);

    pdfChangeFontSize(pdf, 10.0);
    pdfWriteFTextExA(pdf, 50.0, 150.0, 220.0, -1.0, taLeft, "This group works like a radio button but only radio buttons get a round border if the check box character is set to ccCircle. No problem, set the border width to zero and draw the circle in background if needed.");

    y = pdfGetPageHeight(pdf) - pdfGetLastTextPosY(pdf) + 10.0;

    pdfChangeFontSize(pdf, 1.0);
    pdfSetCheckBoxChar(pdf, ccCircle);
    pdfCreateCheckBox(pdf, "G2", "C1", 0, -1, 50.0, y, 20.0, 20.0);
    pdfCreateCheckBox(pdf, "G2", "C2", 0, -1, 80.0, y, 20.0, 20.0);
    pdfCreateCheckBox(pdf, "G2", "C3", 1, -1, 110.0, y, 20.0, 20.0);

    pdfChangeFontSize(pdf, 10.0);
    pdfWriteFTextExA(pdf, 300.0, 50.0, 250.0, -1.0, taLeft, "This is a radio button. Since Acrobat 7 it is no longer possible to deselect the active check box, except with a reset form or Javascript action.");

    y = pdfGetPageHeight(pdf) - pdfGetLastTextPosY(pdf) + 10.0;

    pdfChangeFontSize(pdf, 15.0);
    r = pdfCreateRadioButton(pdf, "Radio1", "R1", 1, -1, 300.0, y, 20.0, 20.0);
    pdfSetCheckBoxDefState(pdf, r, 0);
    pdfCreateCheckBox(pdf, "", "R2", 0, r, 330.0, y, 20.0, 20.0);
    pdfCreateCheckBox(pdf, "", "R3", 0, r, 360.0, y, 20.0, 20.0);

    pdfChangeFontSize(pdf, 10.0);
    f = pdfCreateButtonA(pdf, "Reset", "Reset", -1, 400.0, y, 60.0, 20.0);
    pdfSetFieldColor(pdf, f, fcBackColor, csDeviceRGB, clLtGray);
    pdfSetFieldBorderStyle(pdf, f, bsBevelled);

    act = pdfCreateResetAction(pdf);
    pdfAddActionToObj(pdf, otField, oeOnMouseUp, act, f);
    pdfAddFieldToFormAction(pdf, act, r, 1);

    y = y + 40.0;
    pdfChangeFontSize(pdf, 10.0);
    pdfWriteFTextExA(pdf, 300.0, y, 250.0, -1.0, taLeft, "The RadioIsUnion flag has only an effect if at least two check boxes use the same export value.");
    y = pdfGetPageHeight(pdf) - pdfGetLastTextPosY(pdf) + 10.0;

    pdfChangeFontSize(pdf, 15.0);
    r = pdfCreateRadioButton(pdf, "Radio2", "R1", 1, -1, 300.0, y, 20.0, 20.0);
    pdfSetFieldFlags(pdf, r, ffRadioIsUnion, 0);
    pdfCreateCheckBox(pdf, "", "R2", 0, r, 330.0, y, 20.0, 20.0);
    pdfCreateCheckBox(pdf, "", "R1", 1, r, 360.0, y, 20.0, 20.0);
    pdfCreateCheckBox(pdf, "", "R2", 0, r, 390.0, y, 20.0, 20.0);
    pdfEndPage(pdf);

    if(pdfHaveOpenDoc(pdf) != 0){
        std::string outFile = exeDir(argv[0]) + "/out.pdf";
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){
            pdfDeletePDF(pdf);
            return 0;
        }
        if(pdfCloseFile(pdf) != 0)
            printf("PDF file \"%s\" successfully created!\n", outFile.c_str());
    }

    pdfDeletePDF(pdf);
    return 0;
}

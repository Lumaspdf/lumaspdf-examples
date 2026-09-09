// form_fields -- C++ port of examples\Vb6\acroform\form_fields\form_fields.bas
#include <lumaspdf.h>
#include <cstdio>
#include <string>

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    return 0;
}

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

int main(int argc, char** argv){
    SI32 f, r;
    double y;

    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);
    pdfCreateNewPDFA(pdf, "");

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);
    y = 50.0;
    pdfSetFontW(pdf, (LWCHAR*)LUMAS_TEXT("Helvetica"), fsRegular, 10.0, 0, cp1252);
    pdfWriteTextW(pdf, 50.0, y, (LWCHAR*)LUMAS_TEXT("Text fields:"));

    y = y + 15.0;
    f = pdfCreateTextField(pdf, "Text1", -1, 0, 0, 50.0, y, 200.0, 20.0);
    pdfSetTextFieldValueW(pdf, f, (LWCHAR*)LUMAS_TEXT(""), (LWCHAR*)LUMAS_TEXT("Single line text..."), taLeft);

    y = y + 30.0;
    f = pdfCreateTextField(pdf, "Text2", -1, 1, 0, 50.0, y, 200.0, 50.0);
    pdfSetTextFieldValueW(pdf, f, (LWCHAR*)LUMAS_TEXT(""), (LWCHAR*)LUMAS_TEXT("This field accepts multi-line text. The maximum text length can be restricted if necessary."), taLeft);

    y = y + 60.0;
    pdfWriteTextW(pdf, 50.0, y, (LWCHAR*)LUMAS_TEXT("A password field:"));
    y = y + 15.0;
    f = pdfCreateTextField(pdf, "Text3", -1, 0, 0, 50.0, y, 200.0, 20.0);
    pdfSetFieldFlags(pdf, f, ffPassword, 0);
    pdfSetTextFieldValueW(pdf, f, (LWCHAR*)LUMAS_TEXT(""), (LWCHAR*)LUMAS_TEXT("**********"), taLeft);

    y = y + 30.0;
    pdfWriteTextW(pdf, 50.0, y, (LWCHAR*)LUMAS_TEXT("A fixed length field separated into combs:"));
    y = y + 15.0;
    f = pdfCreateTextField(pdf, "Text4", -1, 0, 10, 50.0, y, 200.0, 20.0);
    pdfSetFieldFlags(pdf, f, ffComb, 0);

    y = 50.0;
    pdfWriteTextW(pdf, 350.0, y, (LWCHAR*)LUMAS_TEXT("Choice fields:"));
    y = y + 15.0;
    f = pdfCreateComboBox(pdf, "Combo1", 1, -1, 350.0, y, 200.0, 20.0);
    pdfAddValToChoiceFieldW(pdf, f, "", (LWCHAR*)LUMAS_TEXT(" Select a value..."), 1);
    pdfAddValToChoiceFieldW(pdf, f, "Apple", (LWCHAR*)LUMAS_TEXT("Apple"), 0);
    pdfAddValToChoiceFieldW(pdf, f, "Banana", (LWCHAR*)LUMAS_TEXT("Banana"), 0);
    pdfAddValToChoiceFieldW(pdf, f, "Pear", (LWCHAR*)LUMAS_TEXT("Pear"), 0);
    pdfAddValToChoiceFieldW(pdf, f, "Grape", (LWCHAR*)LUMAS_TEXT("Grape"), 0);
    pdfAddValToChoiceFieldW(pdf, f, "Orange", (LWCHAR*)LUMAS_TEXT("Orange"), 0);

    y = y + 30.0;
    f = pdfCreateListBox(pdf, "List", 1, -1, 350.0, y, 200.0, 50.0);
    pdfAddValToChoiceFieldW(pdf, f, "Apple", (LWCHAR*)LUMAS_TEXT("Apple"), 0);
    pdfAddValToChoiceFieldW(pdf, f, "Banana", (LWCHAR*)LUMAS_TEXT("Banana"), 1);
    pdfAddValToChoiceFieldW(pdf, f, "Pear", (LWCHAR*)LUMAS_TEXT("Pear"), 0);
    pdfAddValToChoiceFieldW(pdf, f, "Grape", (LWCHAR*)LUMAS_TEXT("Grape"), 0);
    pdfAddValToChoiceFieldW(pdf, f, "Orange", (LWCHAR*)LUMAS_TEXT("Orange"), 0);

    y = y + 60.0;
    pdfWriteTextW(pdf, 350.0, y, (LWCHAR*)LUMAS_TEXT("Editable combo box:"));
    y = y + 15.0;
    f = pdfCreateComboBox(pdf, "Combo2", 1, -1, 350.0, y, 200.0, 20.0);
    pdfAddValToChoiceFieldW(pdf, f, "Apple", (LWCHAR*)LUMAS_TEXT("Apple"), 0);
    pdfAddValToChoiceFieldW(pdf, f, "Banana", (LWCHAR*)LUMAS_TEXT("Banana"), 0);
    pdfAddValToChoiceFieldW(pdf, f, "Pear", (LWCHAR*)LUMAS_TEXT("Pear"), 0);
    pdfAddValToChoiceFieldW(pdf, f, "Grape", (LWCHAR*)LUMAS_TEXT("Grape"), 0);
    pdfAddValToChoiceFieldW(pdf, f, "Orange", (LWCHAR*)LUMAS_TEXT("Orange"), 0);
    pdfSetFieldFlags(pdf, f, ffEdit, 0);
    pdfSetFieldExpValueW(pdf, f, 1000, (LWCHAR*)LUMAS_TEXT("Select or enter a value..."), "", 1);

    y = y + 30.0;
    pdfWriteTextW(pdf, 350.0, y, (LWCHAR*)LUMAS_TEXT("Check boxes / Radio buttons:"));

    y = y + 15.0;
    pdfChangeFontSize(pdf, 1.0);
    pdfCreateCheckBox(pdf, "N1", "C1", 1, -1, 350.0, y, 20.0, 20.0);
    pdfCreateCheckBox(pdf, "N2", "C2", 1, -1, 380.0, y, 20.0, 20.0);
    pdfCreateCheckBox(pdf, "N3", "C1", 1, -1, 410.0, y, 20.0, 20.0);

    pdfCreateCheckBox(pdf, "G1", "C1", 0, -1, 450.0, y, 20.0, 20.0);
    pdfCreateCheckBox(pdf, "G1", "C2", 0, -1, 480.0, y, 20.0, 20.0);
    pdfCreateCheckBox(pdf, "G1", "C1", 1, -1, 510.0, y, 20.0, 20.0);
    pdfCreateCheckBox(pdf, "G1", "C2", 0, -1, 540.0, y, 20.0, 20.0);

    y = y + 30.0;
    pdfChangeFontSize(pdf, 15.0);
    pdfSetCheckBoxChar(pdf, ccCircle);
    r = pdfCreateRadioButton(pdf, "Radio1", "R1", 1, -1, 350.0, y, 20.0, 20.0);
    pdfSetCheckBoxDefState(pdf, r, 0);
    pdfCreateCheckBox(pdf, "", "R2", 0, r, 380.0, y, 20.0, 20.0);
    pdfCreateCheckBox(pdf, "", "R3", 0, r, 410.0, y, 20.0, 20.0);

    r = pdfCreateRadioButton(pdf, "Radio2", "R1", 1, -1, 450.0, y, 20.0, 20.0);
    pdfSetFieldFlags(pdf, r, ffRadioIsUnion, 0);
    pdfCreateCheckBox(pdf, "", "R2", 0, r, 480.0, y, 20.0, 20.0);
    pdfCreateCheckBox(pdf, "", "R1", 1, r, 510.0, y, 20.0, 20.0);
    pdfCreateCheckBox(pdf, "", "R2", 0, r, 540.0, y, 20.0, 20.0);
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

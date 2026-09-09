// annotation_replies -- C++ port of examples\Vb6\annotations\annotation_replies\annotation_replies.bas
// A square annotation with a reply, and a reply to that reply.
#include <lumaspdf.h>
#include <cstdio>
#include <string>

// The Delphi original passes Delphi `string` (UnicodeString), so every call
// resolves to the WIDE overload; the *A twins used here before wrote
// PDFDocEncoding where the reference writes a UTF-16BE PDF text string. LWCHAR
// is wchar_t on Windows and char16_t elsewhere, so the literal must go through
// the header's own LUMAS_TEXT() macro -- a bare u"..." does not convert to
// LWCHAR* under MSVC, and a bare L"..." is 4 bytes wide off Windows.
#define W_(s) ((LWCHAR*)LUMAS_TEXT(s))
//
// ENGINE GAP (reported, not fixed here -- the engine DLL is shared).
// This example still lands short of the Delphi reference for two reasons that
// live in cpp/src/, not in this file:
//   1. TLumasPdfDoc::SetAnnotMigrationStateH (cpp/src/pdf/document.cpp) never
//      marks the reply annot as needing a /Popup. Delphi's counterpart in
//      src/Lumas.Pdf.Document.pas does `Reply.Put('LumasNeedPopup', ...)` and
//      also back-fills the parent, so the reference emits 6 annots (3 markup +
//      3 popups) where this produces 4.
//   2. pdfSquareAnnotW and its siblings in cpp/src/pdf/annot2_exports.cpp
//      narrow their wide arguments with WideToStr(), i.e. straight to bytes.
//      Delphi's pdfSquareAnnotW uses PWideToPdfText(), which emits a proper
//      UTF-16BE-with-BOM PDF text string. pdfSetAnnotStringW below already
//      uses the correct WideToPdfText() helper, which is why /Contents on the
//      replies now matches the reference while /T /Subj /Contents on the
//      square annot still does not.

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    return 0;
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);
    pdfCreateNewPDFW(pdf, W_(""));

    pdfSetPageCoords(pdf, pcTopDown);

    pdfAppend(pdf);
    // To see the reply click on the annotation
    SI32 annot = pdfSquareAnnotW(pdf, 50.0, 50.0, 200.0, 100.0, 3.0, NO_COLOR, 255, csDeviceRGB, W_("Jim"), W_("Test"), W_("Just test..."));
    SI32 reply = pdfSetAnnotMigrationStateW(pdf, annot, asCreateReply, W_("Harry"));
    pdfSetAnnotStringW(pdf, reply, asContent, W_("This is a reply!"));

    reply = pdfSetAnnotMigrationStateW(pdf, reply, asCreateReply, W_("Jim"));
    pdfSetAnnotStringW(pdf, reply, asContent, W_("This is a reply to a reply!"));
    pdfEndPage(pdf);

    if(pdfHaveOpenDoc(pdf) != 0){
        std::string outFile = exeDir(argv[0]) + "/out.pdf";
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){
            pdfDeletePDF(pdf);
            return 0;
        }
        if(pdfCloseFile(pdf) != 0){
            printf("PDF file \"%s\" successfully created!\n", outFile.c_str());
        }
    }

    pdfDeletePDF(pdf);
    return 0;
}

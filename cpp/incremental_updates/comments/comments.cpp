// comments -- C++ port of examples\Vb6\incremental_updates\comments\comments.bas
// Incremental updates: create a file with a square annotation, then reply to it
// (and to the reply) saving each step as an incremental update.
#include <lumaspdf.h>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

// The Delphi original passes `string` (UnicodeString), which binds to the
// WideString overload of CreateNewPDF/SquareAnnot/SetAnnotMigrationState/
// SetAnnotString/OpenOutputFile, so the reference writes those annotation
// strings as UTF-16. (OpenImportBuffer has ONLY an AnsiString overload in
// dynapdf.pas, so it correctly stays on the A entry point below.)
static std::basic_string<LWCHAR> W(const std::string& s){
    return std::basic_string<LWCHAR>(s.begin(), s.end());
}

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static bool CreateTestFile(PPDF pdf, std::vector<unsigned char>& buf){
    pdfCreateNewPDFW(pdf, (LWCHAR*)LUMAS_TEXT(""));
    pdfSetPageCoords(pdf, pcTopDown);
    pdfAppend(pdf);
        pdfSquareAnnotW(pdf, 50.0, 50.0, 200.0, 100.0, 3.0, NO_COLOR, 255, csDeviceRGB,
                        (LWCHAR*)LUMAS_TEXT("Jim"), (LWCHAR*)LUMAS_TEXT("Test"), (LWCHAR*)LUMAS_TEXT("Just a test..."));
    pdfEndPage(pdf);
    if(pdfCloseFile(pdf) == 0) return false;
    UI32 sz = 0;
    char* p = pdfGetBuffer(pdf, &sz);
    if(!p || sz == 0) return false;
    buf.assign((unsigned char*)p, (unsigned char*)p + sz);
    pdfFreePDF(pdf); // releases the original buffer and resets the instance
    return true;
}

static bool LoadTestFile(PPDF pdf, std::vector<unsigned char>& buf){
    pdfCreateNewPDFW(pdf, (LWCHAR*)LUMAS_TEXT(""));
    pdfSetImportFlags2(pdf, if2IncrementalUpd);
    if(pdfOpenImportBuffer(pdf, buf.data(), (UI32)buf.size(), ptOpen, "") < 0) return false;
    return pdfImportPDFFile(pdf, 1, 1.0, 1.0) > 0;
}

static bool SaveFile(PPDF pdf, std::vector<unsigned char>& buf){
    if(pdfCloseFile(pdf) == 0) return false;
    UI32 sz = 0;
    char* p = pdfGetBuffer(pdf, &sz);
    if(!p || sz == 0) return false;
    buf.assign((unsigned char*)p, (unsigned char*)p + sz);
    pdfFreePDF(pdf);
    return true;
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);

    std::vector<unsigned char> buf;
    if(!CreateTestFile(pdf, buf)){ pdfDeletePDF(pdf); return 1; }

    if(LoadTestFile(pdf, buf)){
        SI32 reply = pdfSetAnnotMigrationStateW(pdf, 0, asCreateReply, (LWCHAR*)LUMAS_TEXT("Harry"));
        pdfSetAnnotStringW(pdf, reply, asContent, (LWCHAR*)LUMAS_TEXT("Hi Jim, your test annotation looks fine!"));
        if(SaveFile(pdf, buf) && LoadTestFile(pdf, buf)){
            reply = pdfSetAnnotMigrationStateW(pdf, reply, asCreateReply, (LWCHAR*)LUMAS_TEXT("Tommy"));
            pdfSetAnnotStringW(pdf, reply, asContent, (LWCHAR*)LUMAS_TEXT("Just a test whether I can reply to a reply..."));
            if(SaveFile(pdf, buf) && LoadTestFile(pdf, buf)){
                reply = pdfSetAnnotMigrationStateW(pdf, reply, asCreateReply, (LWCHAR*)LUMAS_TEXT("Jim"));
                pdfSetAnnotStringW(pdf, reply, asContent, (LWCHAR*)LUMAS_TEXT("Seems to work very well!"));
                if(pdfHaveOpenDoc(pdf) != 0){
                    std::string filePath = exeDir(argv[0]) + "/out.pdf";
                    if(pdfOpenOutputFileW(pdf, (LWCHAR*)W(filePath).c_str()) != 0){
                        if(pdfCloseFile(pdf) != 0)
                            printf("PDF file \"%s\" successfully created!\n", filePath.c_str());
                    }
                }
            }
        }
    }
    pdfDeletePDF(pdf);
    return 0;
}

// comments -- C++ port of examples\Vb6\incremental_updates\comments\comments.bas
// Incremental updates: create a file with a square annotation, then reply to it
// (and to the reply) saving each step as an incremental update.
#include <lumaspdf.h>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static bool CreateTestFile(PPDF pdf, std::vector<unsigned char>& buf){
    pdfCreateNewPDFA(pdf, "");
    pdfSetPageCoords(pdf, pcTopDown);
    pdfAppend(pdf);
        pdfSquareAnnotA(pdf, 50.0, 50.0, 200.0, 100.0, 3.0, NO_COLOR, 255, csDeviceRGB, "Jim", "Test", "Just a test...");
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
    pdfCreateNewPDFA(pdf, "");
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
        SI32 reply = pdfSetAnnotMigrationStateA(pdf, 0, asCreateReply, "Harry");
        pdfSetAnnotStringA(pdf, reply, asContent, "Hi Jim, your test annotation looks fine!");
        if(SaveFile(pdf, buf) && LoadTestFile(pdf, buf)){
            reply = pdfSetAnnotMigrationStateA(pdf, reply, asCreateReply, "Tommy");
            pdfSetAnnotStringA(pdf, reply, asContent, "Just a test whether I can reply to a reply...");
            if(SaveFile(pdf, buf) && LoadTestFile(pdf, buf)){
                reply = pdfSetAnnotMigrationStateA(pdf, reply, asCreateReply, "Jim");
                pdfSetAnnotStringA(pdf, reply, asContent, "Seems to work very well!");
                if(pdfHaveOpenDoc(pdf) != 0){
                    std::string filePath = exeDir(argv[0]) + "/out.pdf";
                    if(pdfOpenOutputFileA(pdf, filePath.c_str()) != 0){
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

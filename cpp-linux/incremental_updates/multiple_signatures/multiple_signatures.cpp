// multiple_signatures -- C++ port of examples\Vb6\incremental_updates\multiple_signatures\multiple_signatures.bas
// Signs a PDF four times (two visible + two invisible) using incremental updates.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <cstring>
#include <string>

#ifdef _WIN32
extern "C" {
    __declspec(dllimport) unsigned long PDF_CALL GetTempFileNameA(const char*, const char*, unsigned int, char*);
    __declspec(dllimport) int PDF_CALL MoveFileExA(const char*, const char*, unsigned long);
    __declspec(dllimport) int PDF_CALL DeleteFileA(const char*);
}
static const unsigned long MOVEFILE_COPY_ALLOWED = 0x2;
static const unsigned long MOVEFILE_WRITE_THROUGH = 0x8;
#else
#include <unistd.h>
#include <cstdio>
// Portable equivalents: the Windows path pre-creates a unique temp file,
// deletes the real destination, then moves the temp file over it (guarding
// against in-place-signing a file that's also its own input). rename()
// already atomically replaces an existing destination on POSIX, so the
// explicit DeleteFileA-then-move sequencing collapses to a plain rename().
static inline unsigned long GetTempFileNameA(const char* dir, const char* prefix, unsigned int, char* out) {
    std::snprintf(out, 264, "%s/%s%d.tmp", dir, prefix, (int)getpid());
    return 1;
}
static inline int DeleteFileA(const char* path) { return unlink(path) == 0; }
static inline int MoveFileExA(const char* src, const char* dst, unsigned long) { return rename(src, dst) == 0; }
static const unsigned long MOVEFILE_COPY_ALLOWED = 0;
static const unsigned long MOVEFILE_WRITE_THROUGH = 0;
#endif

static const char* CERT = LUMAS_REPO_ROOT "/test_cert.pfx";
static const char* SRC  = LUMAS_REPO_ROOT "/sample_multipage.pdf";

static SI32 PDF_CALL PDFError(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return 0;
}

static bool SignFile(PPDF pdf, const std::string& inFile, const std::string& outFile,
                     const char* fieldName, const char* reason, double posX, bool visible){
    std::string outName = outFile;
    bool usedTemp = false;
    if(inFile == outFile){
        char tmp[264] = {0};
        if(GetTempFileNameA(".", "sig", 0, tmp) == 0) return false;
        outName = tmp;
        usedTemp = true;
    }

    pdfCreateNewPDFA(pdf, outName.c_str());
    // Avoids adding a demo string to each edited page (would invalidate signatures).
    pdfSetLicenseKey(pdf, "SigDemo");

    pdfSetImportFlags2(pdf, if2IncrementalUpd);
    if(pdfOpenImportFileA(pdf, inFile.c_str(), ptOpen, "") < 0) return false;
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);

    if(visible){
        pdfSetPageCoords(pdf, pcTopDown);
        pdfEditPage(pdf, 1);
            SI32 sig = pdfCreateSigField(pdf, fieldName, -1, posX, 30.0, 180.0, 40.0);
            pdfSetFieldBorderWidth(pdf, sig, 0.0);
        pdfEndPage(pdf);
    }

    bool ok = pdfCloseAndSignFile(pdf, CERT, "123456", reason, "") != 0;
    if(ok && usedTemp){
        DeleteFileA(outFile.c_str());
        ok = MoveFileExA(outName.c_str(), outFile.c_str(), MOVEFILE_COPY_ALLOWED | MOVEFILE_WRITE_THROUGH) != 0;
    }
    return ok;
}

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfSetOnErrorProc(pdf, nullptr, PDFError);

    std::string filePath = exeDir(argv[0]) + "/out.pdf";

    if(SignFile(pdf, SRC, filePath, "Signature1", "Test signature 1", 50.0, true))
    if(SignFile(pdf, filePath, filePath, "Signature2", "Test signature 2", 430.0, true))
    if(SignFile(pdf, filePath, filePath, "", "Test signature 3", 0.0, false))
    if(SignFile(pdf, filePath, filePath, "", "Test signature 4", 0.0, false))
        printf("PDF file \"%s\" successfully created!\n", filePath.c_str());

    pdfDeletePDF(pdf);
    return 0;
}

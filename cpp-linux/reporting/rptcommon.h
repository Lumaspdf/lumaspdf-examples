// Shared reporting-example boilerplate (1:1 port of the VB6 mirror helpers).
#ifndef LUMAS_RPTCOMMON_H
#define LUMAS_RPTCOMMON_H

#include "apputil.h"
#include <cstdio>
#include <cstring>
#include <string>

static const char* PDF_DEMO_KEY = "LUMAS-LumasReportExamples-DD5D40E0";
static const char* RPT_DEMO_KEY = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA";

static PPDF mPdf = nullptr;
static TRPT mEng = nullptr;

// TrimNull: VB6 helper trims at first NUL. C strings are already NUL-terminated,
// so returning the buffer pointer is equivalent for the fixed-size struct fields.
static inline const char* TrimNull(const char* s) { return s ? s : ""; }

static inline void WriteText(const char* Path, const std::string& Content) {
    FILE* f = fopen(Path, "wb");
    if (f) { fwrite(Content.data(), 1, Content.size(), f); fclose(f); }
}

static inline void DumpRptError(TRPT Eng) {
    TRptErrorInfoC Info; memset(&Info, 0, sizeof(Info));
    if (rptGetLastError(Eng, &Info) != 0) {
        if (Info.Code != 0) {
            printf("  ! rpt error %d [%s] at %s: %s\n",
                   (int)Info.Code, TrimNull(Info.Module_),
                   TrimNull(Info.Location), TrimNull(Info.Msg));
        }
    }
}

static inline bool BootEngine() {
    mPdf = pdfNewPDF();
    if (mPdf == 0) { printf("pdfNewPDF failed\n"); return false; }
    pdfSetLicenseKey(mPdf, PDF_DEMO_KEY);
    rptSetRptLicenseKeyA(mPdf, RPT_DEMO_KEY);
    mEng = rptCreateEngineA(mPdf, nullptr);
    if (mEng == 0) { printf("rptCreateEngine failed:\n"); DumpRptError(nullptr); return false; }
    return true;
}

#endif

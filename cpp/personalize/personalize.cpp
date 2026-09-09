// personalize -- C++ port of examples\Vb6\personalize\personalize.bas
// Imports a tax form, fills in the fields and adds a web link.
#include <lumaspdf.h>
#include "repo_root.h"
#include <cstdio>
#include <string>
#include <ctime>
// The Delphi original draws DateTimeToStr(Date + Time), which renders with the
// SYSTEM short-date + long-time patterns -- "02-08-2026 5:55:02 PM" here. A
// plain strftime layout is not an equivalent: dropping the AM/PM designator
// changes the number of whitespace-separated tokens on the page, and that word
// count is exactly what tools/compare_lang_outputs.py diffs, so the row read
// CONTENT_DIFF for a reason that had nothing to do with the engine. Read the
// same two locale values Delphi reads (LOCALE_SSHORTDATE / LOCALE_STIMEFORMAT,
// which is what GetDateFormat(DATE_SHORTDATE) / GetTimeFormat(0) expand).
//
// Declared by hand rather than via <windows.h>: lumaspdf.h rolls its own Win32
// types, and including the real SDK headers after it breaks wincrypt.h with
// ~100 syntax errors. Same reason print_pdf.cpp hand-declares its print dialog.
#ifdef _WIN32
namespace w32 {
    struct SYSTIME { unsigned short wYear, wMonth, wDayOfWeek, wDay,
                                    wHour, wMinute, wSecond, wMilliseconds; };
    extern "C" __declspec(dllimport) int __stdcall
        GetDateFormatA(unsigned long, unsigned long, const SYSTIME*, const char*, char*, int);
    extern "C" __declspec(dllimport) int __stdcall
        GetTimeFormatA(unsigned long, unsigned long, const SYSTIME*, const char*, char*, int);
    const unsigned long USER_DEFAULT = 0x0400;   // LOCALE_USER_DEFAULT
    const unsigned long SHORTDATE    = 0x0001;   // DATE_SHORTDATE
}
#endif

static std::string nowLikeDelphi(){
    time_t tt = time(nullptr);
    struct tm* lt = localtime(&tt);
#ifdef _WIN32
    w32::SYSTIME st = { (unsigned short)(lt->tm_year + 1900), (unsigned short)(lt->tm_mon + 1),
                        (unsigned short)lt->tm_wday, (unsigned short)lt->tm_mday,
                        (unsigned short)lt->tm_hour, (unsigned short)lt->tm_min,
                        (unsigned short)lt->tm_sec, 0 };
    char d[128] = {0}, t[128] = {0};
    w32::GetDateFormatA(w32::USER_DEFAULT, w32::SHORTDATE, &st, nullptr, d, (int)sizeof(d));
    w32::GetTimeFormatA(w32::USER_DEFAULT, 0,              &st, nullptr, t, (int)sizeof(t));
    return std::string(d) + " " + t;
#else
    char buf[64]; strftime(buf, sizeof(buf), "%d-%m-%Y %I:%M:%S %p", lt);
    std::string s(buf);                       // Delphi's 'h' does not pad the
    size_t h = s.find(' ') + 1;               // hour; strftime's %I does.
    if (h && h < s.size() && s[h] == '0') s.erase(h, 1);
    return s;
#endif
}

#ifndef RGB
#define RGB(r,g,b) ((UI32)(((unsigned char)(r))|(((unsigned char)(g))<<8)|(((unsigned char)(b))<<16)))
#endif

static std::string exeDir(const char* a0){ std::string s(a0); auto p=s.find_last_of("\\/"); return p==std::string::npos?".":s.substr(0,p); }

static SI32 PDF_CALL ErrProc(void* Data, SI32 ErrCode, const char* ErrMessage, SI32 ErrType){
    if(ErrMessage) printf("%s\n", ErrMessage);
    return -1; // break processing on error
}

int main(int argc, char** argv){
    PPDF pdf = pdfNewPDF();
    pdfCreateNewPDFA(pdf, "");

    pdfSetViewerPreferences(pdf, vpDisplayDocTitle, avNone);
    pdfSetImportFlags(pdf, ifImportAll | ifImportAsPage);
    const char* inFile = LUMAS_REPO_ROOT "/examples/test_files/taxform.pdf";
    if(pdfOpenImportFileA(pdf, inFile, ptOpen, "") < 0){ pdfDeletePDF(pdf); return 1; }
    pdfImportPDFFile(pdf, 1, 1.0, 1.0);

    pdfEditPage(pdf, 1);
    pdfSetFontA(pdf, "Courier", fsBold, 14.0, 0, cp1252);
    pdfWriteTextA(pdf, 72.5, 748.5, "X");
    pdfWriteTextA(pdf, 74.0, 701.0, "Musterstadt");
    pdfWriteTextA(pdf, 74.0, 677.0, "252/1062/3323");
    pdfBeginContinueText(pdf, 74.0, 628.0);
    pdfSetLeading(pdf, 24.0);
    pdfSetCharacterSpacing(pdf, 5.8);
    pdfAddContinueTextA(pdf, "Mustermann");
    pdfAddContinueTextA(pdf, "Hermann");
    pdfAddContinueTextA(pdf, "22021963keineKaufmann");
    pdfAddContinueTextA(pdf, "Musterstra\xDF" "e 145");   // 0xDF = 'sharp s' in cp1252 (split ends the hex escape)
    pdfAddContinueTextA(pdf, "12345Musterstadt");
    pdfSetCharacterSpacing(pdf, 0.0);
    pdfSetFontA(pdf, "Courier", fsBold, 10.0, 0, cp1252);
    pdfSetLeading(pdf, 48.0);
    pdfAddContinueTextA(pdf, "04.05.1994");
    pdfSetFontA(pdf, "Courier", fsBold, 14.0, 0, cp1252);
    pdfSetCharacterSpacing(pdf, 5.8);
    pdfAddContinueTextA(pdf, "Sabine");
    pdfSetLeading(pdf, 47.5);
    pdfAddContinueTextA(pdf, "18121966 ev  Hausfrau");
    pdfEndContinueText(pdf);
    pdfWriteTextA(pdf, 72.5, 365.0, "X");
    pdfWriteTextA(pdf, 396.0, 365.0, "X");
    pdfBeginContinueText(pdf, 74.0, 316.0);
    pdfSetLeading(pdf, 24.0);
    pdfAddContinueTextA(pdf, "2346256780     76834560");
    pdfAddContinueTextA(pdf, "Sparkasse Musterstadt");
    pdfEndContinueText(pdf);
    pdfWriteTextA(pdf, 72.5, 269.0, "X");
    pdfSetCharacterSpacing(pdf, 0.0);
    pdfSetFontA(pdf, "Courier", fsNone, 10.0, 0, cp1252);

    pdfWriteTextA(pdf, 53.0, 48.0, nowLikeDelphi().c_str());

    pdfSetFillColor(pdf, RGB(0xFF, 0x66, 0x66));
    pdfSetFontA(pdf, "Helvetica", fsBold, 22.0, 0, cp1252);
    pdfWriteTextA(pdf, 340.0, 70.0, "www.dynaforms.de");
    pdfSetLineWidth(pdf, 0.0);
    pdfSetLinkHighlightMode(pdf, hmPush);
    pdfSetAnnotFlags(pdf, afReadOnly);
    pdfWebLinkA(pdf, 340.0, 64.0, 204.0, 22.0, "http://www.dynaforms.de");
    pdfEndPage(pdf);

    std::string outFile = exeDir(argv[0]) + "/out.pdf";
    if(pdfHaveOpenDoc(pdf) != 0){
        pdfSetOnErrorProc(pdf, nullptr, nullptr); // silence errors while opening the output file
        if(pdfOpenOutputFileA(pdf, outFile.c_str()) == 0){ pdfDeletePDF(pdf); return 1; }
        pdfSetOnErrorProc(pdf, nullptr, ErrProc);
    }
    if(pdfCloseFile(pdf) != 0)
        printf("PDF file \"%s\" successfully created!\n", outFile.c_str());
    pdfDeletePDF(pdf);
    return 0;
}

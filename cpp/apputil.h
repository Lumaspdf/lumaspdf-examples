// Shared helpers for the C++ example ports.
// NOTE (Windows): we deliberately DO NOT include <windows.h> because lumaspdf.h
// defines its own HDC / HWND / PBITMAPINFO typedefs that collide with the
// Win32 SDK. The few Win32 entry points needed are declared manually below.
// NOTE (Linux/other): no such collision risk -- these are plain portable
// implementations using POSIX/libc equivalents, not declarations of a system
// API, so no extra system header fights with lumaspdf.h here either.
#ifndef LUMAS_APPUTIL_H
#define LUMAS_APPUTIL_H

#include "lumaspdf.h"
#include "repo_root.h"
#include <cstdio>
#include <cstring>

#ifndef RGB
#define RGB(r,g,b) ((unsigned long)(((unsigned char)(r))|(((unsigned char)(g))<<8)|(((unsigned char)(b))<<16)))
#endif

#ifdef _WIN32

extern "C" {
    __declspec(dllimport) unsigned long __stdcall GetModuleFileNameA(void*, char*, unsigned long);
    __declspec(dllimport) int  __stdcall SetCurrentDirectoryA(const char*);
    __declspec(dllimport) int  __stdcall CreateDirectoryA(const char*, void*);
    __declspec(dllimport) void* __stdcall GetDC(void*);
    __declspec(dllimport) int  __stdcall ReleaseDC(void*, void*);
    __declspec(dllimport) int  __stdcall GetDeviceCaps(void*, int);
    __declspec(dllimport) unsigned long __stdcall GetTickCount(void);
    __declspec(dllimport) void* __stdcall GetStdHandle(unsigned long);
    __declspec(dllimport) int  __stdcall SetConsoleTextAttribute(void*, unsigned short);
    __declspec(dllimport) unsigned long __stdcall GetFileAttributesA(const char*);
}

// Change the current directory to the folder holding the exe, so the relative
// fixture paths from the VB6 mirror (App.Path & "\x", "../../../x") resolve.
static inline void ChdirToExe() {
    char b[512];
    GetModuleFileNameA(0, b, sizeof(b));
    char* p = strrchr(b, '\\');
    if (p) { *p = 0; SetCurrentDirectoryA(b); }
}

#else // !_WIN32

#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <ctime>
#include <climits>
#include <cerrno>

// Same fixed constant on every Linux flavour (x64/x86/arm32/arm64) --
// there's no real display attached in a Docker build container, and the
// exact number only affects a couple examples' own preview-image width, not
// any PDF-structural output, so a shared constant keeps those examples'
// outputs byte-identical across architectures (the whole point of the
// cross-arch build being comparable at all).
#define LUMAS_LINUX_FAKE_SCREEN_WIDTH_PX 1920

static inline void* GetDC(void*) { return (void*)1; }
static inline int ReleaseDC(void*, void*) { return 1; }
static inline int GetDeviceCaps(void*, int) { return LUMAS_LINUX_FAKE_SCREEN_WIDTH_PX; }

static inline unsigned long GetTickCount() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (unsigned long)(ts.tv_sec * 1000ULL + ts.tv_nsec / 1000000ULL);
}

static inline void* GetStdHandle(unsigned long) { return (void*)1; }
static inline int SetConsoleTextAttribute(void*, unsigned short) { return 1; }

static inline int CreateDirectoryA(const char* path, void*) {
    return mkdir(path, 0777) == 0 || errno == EEXIST;
}

// Change the current directory to the folder holding the exe (argv[0]-free
// version -- Linux has no GetModuleFileNameA equivalent that doesn't need
// argv[0], so this resolves /proc/self/exe instead), matching ChdirToExe()'s
// Windows behaviour of putting cwd at the exe's own directory so the
// examples' relative fixture paths ("../../../x") resolve identically.
static inline void ChdirToExe() {
    char b[PATH_MAX];
    ssize_t n = readlink("/proc/self/exe", b, sizeof(b) - 1);
    if (n <= 0) return;
    b[n] = 0;
    char* p = strrchr(b, '/');
    if (p) { *p = 0; if (chdir(b) != 0) { /* ignore */ } }
}

#endif // _WIN32

#endif

/* shared helper: derive exe directory from argv[0] (no windows.h) */
#ifndef LUMAS_EX_COMMON_H
#define LUMAS_EX_COMMON_H
#include <string.h>
static void exedir(const char* a0, char* out, size_t n)
{
    char* s;
    strncpy(out, a0, n - 1); out[n - 1] = 0;
    s = strrchr(out, '\\'); if (!s) s = strrchr(out, '/');
    if (s) *s = 0; else strcpy(out, ".");
}
#endif

// Portable absolute path to the repo root, for the handful of examples that
// hardcode an absolute path to a shared fixture (dynapdf_help.pdf, license.pdf,
// examples/test_files/...). It defaults to the directory two levels above
// examples always assumed; on Linux it defaults to "/work" (the dev container
// mount point, see cpp/linux/<arch>/build.sh) but is OVERRIDABLE at compile
// time -- a shipped examples/cpp_linux package won't be unpacked at /work on
// a customer's machine, so its own build script passes
// -DLUMAS_REPO_ROOT='"<wherever the fixtures actually are>"' (an ABSOLUTE
// path is required: this expands via adjacent-string-literal concatenation,
// e.g. LUMAS_REPO_ROOT "/dynapdf_help.pdf", so it can't be computed at
// runtime without restructuring every call site's static-initialization --
// out of scope for this header; a relative/argv0-relative resolver is a
// documented future improvement if that's ever needed).
#ifndef LUMAS_REPO_ROOT_H
#define LUMAS_REPO_ROOT_H

#ifndef LUMAS_REPO_ROOT
#ifdef _WIN32
#define LUMAS_REPO_ROOT ".."     /* pass -DLUMAS_REPO_ROOT to override */
#else
#define LUMAS_REPO_ROOT "/work"
#endif
#endif

#endif

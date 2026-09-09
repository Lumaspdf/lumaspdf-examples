#!/bin/bash
# Build every example in this package against a LumasPdf shared library you
# provide -- LumasPdf.so on Linux, LumasPdf.dylib on macOS. Both work: the
# path is handed straight to the compiler driver as a link input, so the
# extension is never parsed here.
# Self-contained: this directory ships its own copy of lumaspdf.h
# (include/) and every fixture file the examples need (fixtures/, plus a
# few per-example sibling files like signature_ap/test_cert.pfx) -- no
# dependency on the rest of the LumasPDF SDK source tree.
#
# Usage:
#   ./build_all.sh /path/to/LumasPdf.so       # Linux
#   ./build_all.sh /path/to/LumasPdf.dylib    # macOS
#
# Each example is compiled INTO ITS OWN SOURCE DIRECTORY (not a flat bin/
# dir) because several of them locate sibling fixture files relative to
# their own exe path (exeDir(argv[0])) -- moving the binary away from its
# source dir would break those. Run any example with:
#   ./acroform/check_boxes/check_boxes_bin
#
# No LD_LIBRARY_PATH / DYLD_LIBRARY_PATH is needed: every binary is linked
# with -Wl,-rpath pointing at the library's directory. That is not a
# convenience on macOS, it is required -- cpp/CMakeLists.txt gives the dylib
# the install name "@rpath/LumasPdf.dylib" (MACOSX_RPATH + INSTALL_NAME_DIR
# "@rpath"), and a client with no LC_RPATH cannot resolve @rpath, so it
# fails at load with "Library not loaded: @rpath/LumasPdf.dylib" no matter
# what DYLD_LIBRARY_PATH says. On Linux the same flag is simply the tidier
# equivalent of exporting LD_LIBRARY_PATH.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SO="${1:?usage: build_all.sh /path/to/LumasPdf.so (or .dylib on macOS)}"
if [ ! -f "$SO" ]; then echo "not found: $SO" >&2; exit 1; fi
SODIR="$(cd "$(dirname "$SO")" && pwd)"
SO="$SODIR/$(basename "$SO")"

# g++ on macOS is a clang driver shim shipped by the Command Line Tools and
# accepts every flag used below, so the default stays g++ on both platforms;
# $CXX is honoured for the cross/toolchain cases where g++ is not on PATH.
CXX="${CXX:-g++}"

# ---- the ONE header (2026-09-02) ------------------------------------------
# This tree used to carry its own copy under include/, and that copy drifted
# five weeks behind the shipped ABI -- watermark_showcase stopped compiling
# and nobody noticed, because the zip carried TWO different lumaspdf.h and
# this script picked the stale one. There is no bundled copy any more: the
# header comes from the package root (zip layouts) or from the binding
# source of truth (repo), and a build against anything else cannot happen.
if [ -f "$HERE/../lumaspdf.h" ]; then
  HDRDIR="$(cd "$HERE/.." && pwd)"                       # linux/macos zip root
elif [ -f "$HERE/../../wrappers/c/lumaspdf.h" ]; then
  HDRDIR="$(cd "$HERE/../../wrappers/c" && pwd)"         # repository checkout
else
  echo "build_all.sh: cannot find lumaspdf.h (looked in $HERE/.. and" >&2
  echo "  $HERE/../../wrappers/c). The examples build against the package's" >&2
  echo "  own header; without it there is nothing correct to compile." >&2
  exit 1
fi

# ---- the ONE fixture root (2026-09-02) ------------------------------------
# LUMAS_REPO_ROOT is the directory that directly holds the GENERATED sample
# set (sample_*.pdf, images/, merge/, ...). It used to point at a tree of
# vendor-origin files that packaging rightly strips (gen_ship_fixtures.py:
# "not a single vendor byte ships") -- so every shipped example built and
# then died on a missing input. Examples now reference only generated names,
# resolvable in both layouts:
if [ -d "$HERE/../test_files" ]; then
  FIXTURES="$(cd "$HERE/../test_files" && pwd)"          # unpacked zip
elif [ -d "$HERE/../../ship/_fixtures" ]; then
  FIXTURES="$(cd "$HERE/../../ship/_fixtures" && pwd)"   # repository checkout
else
  echo "build_all.sh: no fixture set found. In a repository checkout run" >&2
  echo "  python tools/gen_ship_fixtures.py   first (writes ship/_fixtures);" >&2
  echo "  in an unpacked package, test_files/ sits beside the examples." >&2
  exit 1
fi
RESULTS="$HERE/_build_results.log"
: > "$RESULTS"

PASS=0; FAIL=0
while IFS= read -r -d '' src; do
  rel="${src#"$HERE"/}"
  dir="$(dirname "$src")"
  name="$(basename "$src" .cpp)"
  bin="${dir}/${name}_bin"

  if "$CXX" -std=c++17 -O2 \
        -DLUMAS_REPO_ROOT="\"$FIXTURES\"" \
        -I "$HERE" -I "$HDRDIR" \
        "$src" -o "$bin" "$SO" \
        -Wl,-rpath,"$SODIR" \
        > "${dir}/${name}.build.log" 2>&1; then
    echo "OK   $rel" | tee -a "$RESULTS"
    PASS=$((PASS+1))
  else
    echo "FAIL $rel (see ${dir}/${name}.build.log)" | tee -a "$RESULTS"
    FAIL=$((FAIL+1))
  fi
done < <(find "$HERE" -iname "*.cpp" -print0)

echo "=== ${PASS} built, ${FAIL} failed ===" | tee -a "$RESULTS"
echo ""
echo "Run any example, e.g.:"
echo "  ./hello_world/hello_world_bin"
echo "(each binary carries -Wl,-rpath $SODIR, so no library path variable"
echo " needs exporting on either Linux or macOS)"

# A build script that fails examples and exits 0 is how a broken example
# shipped once; the count above is the result, so it is the exit status too.
[ "$FAIL" -eq 0 ] || exit 1

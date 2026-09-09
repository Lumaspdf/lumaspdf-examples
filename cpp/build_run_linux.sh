#!/bin/bash
# Build + run every C++ example against a given Linux flavour's libLumasPdf.so,
# archiving each example's output artifact(s) so they can be byte-compared
# across all 4 flavours afterwards (see compare_linux_outputs.sh).
#
# Usage (run INSIDE the matching cpp/linux/<arch> Docker image, repo mounted
# at /work -- see cpp/linux/<arch>/build.sh for the exact docker run form):
#   bash examples/cpp/build_run_linux.sh x64|x86|arm32|arm64
set -u
ARCH="${1:?usage: build_run_linux.sh x64|x86|arm32|arm64}"
cd "$(dirname "${BASH_SOURCE[0]}")"
EXROOT="$(pwd)"
SO_DIR="/work/cpp/build/cmake_linux_${ARCH}"
ARCHIVE="/work/examples/cpp_linux_compare/${ARCH}"
mkdir -p "$ARCHIVE"

case "$ARCH" in
  x64)   CXX="g++";                        CXXFLAGS="";      RUNNER="" ;;
  x86)   CXX="g++";                        CXXFLAGS="-m32";  RUNNER="" ;;
  arm32) CXX="arm-linux-gnueabihf-g++";     CXXFLAGS="";      RUNNER="qemu-arm" ;;
  arm64) CXX="aarch64-linux-gnu-g++";       CXXFLAGS="";      RUNNER="qemu-aarch64" ;;
  *) echo "unknown arch: $ARCH" >&2; exit 1 ;;
esac

# Genuinely Windows-only or Windows-driver-only -- not a Linux gap, a real
# missing capability (in-process GDI viewer widget / Windows print spooler /
# Microsoft Access ODBC driver), matching CPP_PORT_CROSSPLATFORM_PLAN_2026-07-25.md
# section 4's disposition table.
EXCLUDE_REL=(
  "pdfviewer/pdfviewer.cpp"
  "rendering_engine/print_pdf/print_pdf.cpp"
  "reporting/16_data_odbc_northwind.cpp"
  "reporting/19_northwind_preview.cpp"
)
is_excluded() {
  local rel="$1"
  for ex in "${EXCLUDE_REL[@]}"; do [ "$rel" = "$ex" ] && return 0; done
  return 1
}

PASS=0; FAIL=0; SKIP=0
RESULTS_LOG="$ARCHIVE/_results.log"
: > "$RESULTS_LOG"

while IFS= read -r -d '' src; do
  rel="${src#./}"
  if is_excluded "$rel"; then
    echo "SKIP  $rel (Windows-only, see script header)" | tee -a "$RESULTS_LOG"
    SKIP=$((SKIP+1)); continue
  fi

  dir="$(dirname "$src")"
  name="$(basename "$src" .cpp)"
  bin="${dir}/${name}_bin_${ARCH}"

  # Link the .so by full path, not "-L$SO_DIR -lLumasPdf" -- CMakeLists.txt's
  # PREFIX "" strips the usual "lib" prefix (matches the Windows DLL name),
  # so it isn't findable via ld's "-lLumasPdf" -> "libLumasPdf.so" convention.
  if ! "$CXX" -std=c++17 $CXXFLAGS -I /work/wrappers/c -I "$EXROOT" \
        "$src" -o "$bin" "${SO_DIR}/LumasPdf.so" \
        > "${dir}/${name}.build_${ARCH}.log" 2>&1; then
    echo "BUILD_FAIL $rel" | tee -a "$RESULTS_LOG"
    FAIL=$((FAIL+1)); continue
  fi

  ( cd "$dir" && LD_LIBRARY_PATH="$SO_DIR" $RUNNER "./$(basename "$bin")" \
        > "${name}.run_${ARCH}.log" 2>&1 )
  rc=$?

  archdir="${ARCHIVE}/${dir#./}"
  mkdir -p "$archdir"
  copied=0
  for f in "$dir"/*; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in
      *.cpp|*.h|*.hpp|*.bat|*.dll|*.exe|*.obj|*.o|*_bin_*|*.build_*.log|*.run_*.log) continue ;;
    esac
    cp "$f" "$archdir/" && copied=$((copied+1))
  done

  if [ $rc -ne 0 ]; then
    echo "RUN_FAIL($rc) $rel" | tee -a "$RESULTS_LOG"
    FAIL=$((FAIL+1))
  elif [ $copied -eq 0 ]; then
    echo "NO_OUTPUT $rel" | tee -a "$RESULTS_LOG"
    FAIL=$((FAIL+1))
  else
    echo "OK    $rel ($copied output file(s))" | tee -a "$RESULTS_LOG"
    PASS=$((PASS+1))
  fi
done < <(find . -iname "*.cpp" -print0)

echo "=== ${ARCH}: ${PASS} ok, ${FAIL} fail, ${SKIP} skip ===" | tee -a "$RESULTS_LOG"

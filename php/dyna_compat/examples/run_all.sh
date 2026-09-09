#!/bin/bash
# Run every vendor example against the LumasPdf engine via the dynapdf shim.
P=/c/wamp64/bin/php/php8.4.15/php.exe
export LUMASPDF_LIB_DIR='E:\LUMASPDFSDK\cpp\build\x64_real'
SHIM='E:\LUMASPDFSDK\wrappers\php\dynapdf.php'
pass=0; fail=0
for f in *.php; do
  case "$f" in config.inc.php|pdf_headers.inc.php) continue;; esac
  out="../out/${f%.php}.pdf"
  if "$P" -d display_errors=stderr -d auto_prepend_file="$SHIM" "$f" > "$out" 2> "../out/${f%.php}.err"; then
    # examples emit the PDF via WriteBuffer; CLI header() calls are no-ops
    magic=$(head -c 5 "$out" 2>/dev/null)
    png=$(head -c 4 "$out" 2>/dev/null | tail -c 3)
    sz=$(stat -c%s "$out" 2>/dev/null || echo 0)
    if { [ "$magic" = "%PDF-" ] || [ "$png" = "PNG" ]; } && [ "$sz" -gt 400 ]; then
      printf "PASS  %-32s %8s bytes\n" "$f" "$sz"; pass=$((pass+1)); continue
    fi
  fi
  printf "FAIL  %-32s %s\n" "$f" "$(head -c 120 "../out/${f%.php}.err" 2>/dev/null | tr '\n' ' ')"
  fail=$((fail+1))
done
echo "TOTAL: pass=$pass fail=$fail"

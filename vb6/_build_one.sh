#!/bin/bash
# usage: _build_one.sh <relpath-without-ext under Vb6>
root="E:/LUMASPDFSDK/examples/Vb6"
n="$1"
win="E:\\LUMASPDFSDK\\examples\\Vb6\\$(echo "$n" | sed 's#/#\\\\#g')"
rm -f "$root/$n.exe" "$root/$n.build.log"
cmd //c "E:\\LUMASPDFSDK\\tools\\build_vb6.bat" "$win.vbp" "$win.build.log" >/dev/null 2>&1
if [ -f "$root/$n.exe" ] && grep -q "succeeded" "$root/$n.build.log" 2>/dev/null; then
  echo "BUILT: $n"
else
  echo "FAILED: $n"
  echo "----- build.log -----"
  cat "$root/$n.build.log" 2>/dev/null
  echo "---------------------"
fi

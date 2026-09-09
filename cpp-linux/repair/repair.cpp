// repair -- C++ port: fix a damaged PDF with a SINGLE method: pdfConvertFileA(..., ctNormalize).
#include <lumaspdf.h>
#include <cstdio>
int main(void){
  PPDF p = pdfNewPDF();
  int rc = pdfConvertFileA(p,
      LUMAS_REPO_ROOT "/corrupt.pdf",   // damaged input (mangled xref)
      "repaired.pdf",
      ctNormalize, 0, NULL, NULL, NULL, NULL, NULL, NULL);
  printf("pdfConvertFile(ctNormalize) rc=%d  (repair-mode used: %d)\n",
         rc, (int)pdfGetInRepairMode(p));
  pdfDeletePDF(p);
  return rc < 0 ? 1 : 0;
}

// repair -- fix a damaged PDF with a SINGLE method: pdfConvertFileA(..., ctNormalize).
#include <lumaspdf.h>
#include <stdio.h>
int main(void){
  PPDF p = pdfNewPDF();
  int rc = pdfConvertFileA(p,
      "../../test_files/corrupt.pdf",   /* 4-page damaged input (mangled xref) */
      "repaired.pdf",
      ctNormalize, 0, NULL, NULL, NULL, NULL, NULL, NULL);
  printf("pdfConvertFile(ctNormalize) rc=%d  (repair-mode used: %d)\n",
         rc, (int)pdfGetInRepairMode(p));
  pdfDeletePDF(p);
  return rc < 0 ? 1 : 0;
}

// convert_conformance -- plain PDF -> PDF/A and PDF/X, each a SINGLE method call.
#include <lumaspdf.h>
#include <stdio.h>
int main(void){
  PPDF p = pdfNewPDF();
  int a = pdfConvertFileA(p, "../../test_files/plain.pdf", "out_pdfa.pdf",
      ctPDFA_2b, 0, "../../test_files/sRGB.icc",
      "../../test_files/ISOcoated_v2_bas.ICC", NULL, NULL, NULL, NULL);
  printf("plain -> PDF/A (ctPDFA_2b) rc=%d\n", a);
  int x = pdfConvertFileA(p, "../../test_files/plain.pdf", "out_pdfx.pdf",
      ctPDFX_4, 0, "../../test_files/sRGB.icc",
      "../../test_files/ISOcoated_v2_bas.ICC", NULL, NULL, NULL, NULL);
  printf("plain -> PDF/X (ctPDFX_4)  rc=%d\n", x);
  pdfDeletePDF(p);
  return (a < 0 || x < 0) ? 1 : 0;
}

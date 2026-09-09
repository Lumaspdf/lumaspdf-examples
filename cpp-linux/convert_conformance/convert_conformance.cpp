// convert_conformance -- C++ port: plain PDF -> PDF/A and PDF/X, each a SINGLE method call.
#include <lumaspdf.h>
#include <cstdio>
int main(void){
  PPDF p = pdfNewPDF();
  int a = pdfConvertFileA(p, LUMAS_REPO_ROOT "/sample_pdfa.pdf", "out_pdfa.pdf",
      ctPDFA_2b, 0, LUMAS_REPO_ROOT "/sample_rgb.icc",
      NULL /* bring your own CMYK press profile */, NULL, NULL, NULL, NULL);
  printf("plain -> PDF/A (ctPDFA_2b) rc=%d\n", a);
  int x = pdfConvertFileA(p, LUMAS_REPO_ROOT "/sample_pdfa.pdf", "out_pdfx.pdf",
      ctPDFX_4, 0, LUMAS_REPO_ROOT "/sample_rgb.icc",
      NULL /* bring your own CMYK press profile */, NULL, NULL, NULL, NULL);
  printf("plain -> PDF/X (ctPDFX_4)  rc=%d\n", x);
  pdfDeletePDF(p);
  return (a < 0 || x < 0) ? 1 : 0;
}

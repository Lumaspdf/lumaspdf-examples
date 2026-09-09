// ============================================================================
//  PDFViewer -- C# port of examples\Vb6\pdfviewer\PDFViewer.bas
//  Opens 18_invoice.pdf in the SDK's EMBEDDED viewer window via the flat
//  export vwrShowFileW(FileName, Title). Both args are PWideChar (UTF-16).
//  The call BLOCKS until the user closes the window.
// ============================================================================
using System;
using System.IO;
using LumasPdfSdk;

namespace PDFViewerExample
{
    class Program
    {
        static void Main()
        {
            string exeDir = AppDomain.CurrentDomain.BaseDirectory;
            string pdf = Path.Combine(exeDir, "18_invoice.pdf");
            string title = "18_invoice.pdf - LumasPDF embedded preview";

            if (!File.Exists(pdf))
            {
                Console.WriteLine("Not found: " + pdf);
                return;
            }

            // Open the embedded viewer. Blocks until the window is closed.
            bool ok = LumasPdf.vwrShowFileW(pdf, title);

            if (!ok)
                Console.WriteLine("The embedded viewer could not be shown for: " + pdf);
        }
    }
}

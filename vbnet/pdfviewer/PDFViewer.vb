' ============================================================================
'  PDFViewer -- opens 18_invoice.pdf in the SDK's EMBEDDED viewer window.
'  Hands a PDF file to the built-in viewer via the flat export
'  vwrShowFileW(FileName, Title). The call BLOCKS until the window is closed.
' ============================================================================
Imports System
Imports System.IO
Imports LumasPdfSdk

Module PDFViewer
    Sub Main()
        Dim baseDir As String = AppDomain.CurrentDomain.BaseDirectory
        Dim pdf As String = Path.Combine(baseDir, "18_invoice.pdf")
        Dim title As String = "18_invoice.pdf - LumasPDF embedded preview"

        If Not File.Exists(pdf) Then
            Console.WriteLine("Not found: " & pdf)
            Return
        End If

        Console.WriteLine("Opening embedded viewer for: " & pdf)
        Dim ok As Boolean = LumasPdf.vwrShowFileW(pdf, title)
        If Not ok Then
            Console.WriteLine("The embedded viewer could not be shown for: " & pdf)
        Else
            Console.WriteLine("Viewer closed.")
        End If
    End Sub
End Module

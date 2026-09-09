' 05_occur_repeating_rows -- VB.NET port of examples\delphi\xfa\05_occur_repeating_rows
'
' "Flavor tour" example 5 of 10: OCCUR/REPEAT data-driven row cloning.
' Demonstrates <occur min="1" max="-1"/>: one repeating template row is
' instantiated once per matching dataset record, each instance independently
' bound to its own record and independently re-running its own calculate
' script. Renders a one-page "Expense Report": a title + three header fields
' (explicit dataRef binding), an ExpenseItemsTable whose Item row (implicit
' by-name binding) repeats once per each of 7 <Item> records, each instance
' computing its own LineTotal = Qty * UnitPrice via FormCalc, plus a
' TotalsRow showing a literal GrandTotal.
'
' Renders 05_occur_repeating_rows.template.xml / .datasets.xml (pre-split
' packet bytes) through the real LumasPdf.dll:
'
'   pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
'   pdfCreateXFAStreamA('datasets',...) -> pdfRenderXFAForm -> pdfCloseFile
'
' Does NOT rebuild LumasPdf.dll -- links only against the generated
' wrappers\vbnet\LumasPdf.vb P/Invoke binding (LumasPdf.VB.dll) and the
' already-built LumasPdf.dll copied next to this exe.
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module OccurRepeatingRows

    Function RenderExample(ByVal TemplatePath As String, ByVal DatasetsPath As String, ByVal OutPdfPath As String) As Integer
        RenderExample = -100
        Console.WriteLine("=== " & Path.GetFileName(TemplatePath) & " -> " & Path.GetFileName(OutPdfPath) & " ===")
        If Not File.Exists(TemplatePath) Then
            Console.WriteLine("FILE-NOT-FOUND: " & TemplatePath)
            Return RenderExample
        End If

        Dim TemplateBuf() As Byte = File.ReadAllBytes(TemplatePath)
        Dim DatasetsBuf() As Byte = If(File.Exists(DatasetsPath), File.ReadAllBytes(DatasetsPath), New Byte() {})
        Console.WriteLine("template packet bytes: " & TemplateBuf.Length)
        Console.WriteLine("datasets packet bytes: " & DatasetsBuf.Length)

        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        If pdf = IntPtr.Zero Then
            Console.WriteLine("pdfNewPDF FAILED")
            Return RenderExample
        End If

        Try
            If Not LumasPdf.pdfCreateNewPDFW(pdf, OutPdfPath) Then
                Console.WriteLine("pdfCreateNewPDFA FAILED")
                Return RenderExample
            End If

            Dim TplHandle As GCHandle = GCHandle.Alloc(TemplateBuf, GCHandleType.Pinned)
            Dim Idx As Integer
            Try
                Idx = LumasPdf.pdfCreateXFAStreamW(pdf, "template", TplHandle.AddrOfPinnedObject(), CUInt(TemplateBuf.Length))
            Finally
                TplHandle.Free()
            End Try
            Console.WriteLine("pdfCreateXFAStreamA(template) -> index " & Idx)
            If Idx < 0 Then
                Console.WriteLine("pdfCreateXFAStreamA(template) FAILED")
                Return RenderExample
            End If

            If DatasetsBuf.Length > 0 Then
                Dim DsHandle As GCHandle = GCHandle.Alloc(DatasetsBuf, GCHandleType.Pinned)
                Try
                    Idx = LumasPdf.pdfCreateXFAStreamW(pdf, "datasets", DsHandle.AddrOfPinnedObject(), CUInt(DatasetsBuf.Length))
                Finally
                    DsHandle.Free()
                End Try
                Console.WriteLine("pdfCreateXFAStreamA(datasets) -> index " & Idx)
                If Idx < 0 Then
                    Console.WriteLine("pdfCreateXFAStreamA(datasets) FAILED")
                    Return RenderExample
                End If
            Else
                Console.WriteLine("(no datasets packet found -- template-only render)")
            End If

            Dim Rc As Integer = LumasPdf.pdfRenderXFAForm(pdf)
            Console.WriteLine("pdfRenderXFAForm -> " & Rc)
            If Rc < 0 Then
                Console.WriteLine("pdfRenderXFAForm FAILED, code " & Rc)
                Return RenderExample
            End If

            If Not LumasPdf.pdfCloseFile(pdf) Then
                Console.WriteLine("pdfCloseFile FAILED")
                RenderExample = -101
                Return RenderExample
            End If
            Console.WriteLine("OK: wrote " & OutPdfPath)
            RenderExample = Rc
        Finally
            LumasPdf.pdfDeletePDF(pdf)
        End Try
    End Function

    Sub Main()
        Dim ExeDir As String = AppDomain.CurrentDomain.BaseDirectory
        Dim R1 As Integer = RenderExample(
            Path.Combine(ExeDir, "05_occur_repeating_rows.template.xml"),
            Path.Combine(ExeDir, "05_occur_repeating_rows.datasets.xml"),
            Path.Combine(ExeDir, "05_occur_repeating_rows.pdf"))
        Console.WriteLine("RESULT|05_occur_repeating_rows=" & R1)
        If R1 >= 1 Then
            Console.WriteLine("Expected 7 rows (verify with a PDF text extractor):")
            Console.WriteLine("  Airfare            1 x 450.00 = 450")
            Console.WriteLine("  Hotel - 3 nights   3 x 120.00 = 360")
            Console.WriteLine("  Taxi / Rideshare   4 x 18.50  = 74")
            Console.WriteLine("  Client Dinner      5 x 22.00  = 110")
            Console.WriteLine("  Parking            2 x 15.00  = 30")
            Console.WriteLine("  Conference Registration 1 x 299.00 = 299")
            Console.WriteLine("  Office Supplies    6 x 4.25   = 25.5")
            Console.WriteLine("  Header: Alex Rivera / Field Operations / 2026-07-24")
            Console.WriteLine("  GrandTotal = 1348.50")
        End If
    End Sub

End Module

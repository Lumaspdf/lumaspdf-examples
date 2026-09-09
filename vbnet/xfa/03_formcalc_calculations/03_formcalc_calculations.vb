' 03_formcalc_calculations -- VB.NET port of examples\delphi\xfa\03_formcalc_calculations
'
' "Flavor tour" example 3 of 10: FORMCALC CALCULATIONS. Demonstrates the XFA
' FormCalc engine (lexer -> parser -> VM -> builtin catalog) end-to-end
' through the real pdfRenderXFAForm export. The form is a single-page "Order
' Calculator": a customer/date header, a 3-line item table (Widget/Gadget/
' Gizmo, each with bound quantity + unit price), and a calculated summary
' block (line totals, subtotal, average price, item count, a discount tier +
' discount amount, grand total), all wired up with
' <calculate><script contentType="application/x-formcalc"> bodies.
'
' Renders 03_formcalc_calculations.template.xml / .datasets.xml (pre-split
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

Module FormCalcCalculations

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
            Path.Combine(ExeDir, "03_formcalc_calculations.template.xml"),
            Path.Combine(ExeDir, "03_formcalc_calculations.datasets.xml"),
            Path.Combine(ExeDir, "03_formcalc_calculations.render.pdf"))
        Console.WriteLine("RESULT|03_formcalc_calculations=" & R1)
        If R1 >= 1 Then
            Console.WriteLine("Expected calculated values (verify with a PDF text extractor):")
            Console.WriteLine("  Item1Total = 37.5   (3 x 12.50)")
            Console.WriteLine("  Item2Total = 90     (2 x 45.00)")
            Console.WriteLine("  Item3Total = 40     (5 x 8.00)")
            Console.WriteLine("  TotalQty   = 10     (Sum(3,2,5))")
            Console.WriteLine("  Subtotal   = 167.5  (Sum(37.5,90,40))")
            Console.WriteLine("  AvgUnitPrice = 21.83 (Round(Avg(12.50,45.00,8.00),2))")
            Console.WriteLine("  ItemCount  = 3      (Count(...))")
            Console.WriteLine("  DiscountLabel  = Bulk Discount (167.5 >= 100)")
            Console.WriteLine("  DiscountAmount = 16.75")
            Console.WriteLine("  GrandTotal = 150.75 (167.5 - 16.75)")
            Console.WriteLine("  FullName   = Alex Nguyen")
            Console.WriteLine("  CustomerInitial = A")
            Console.WriteLine("  OrderDateNum displayed as 2026-07-15 (fixed epoch-conversion bug)")
            Console.WriteLine("  OrderDateFormatted = 7/15/26")
        End If
    End Sub

End Module

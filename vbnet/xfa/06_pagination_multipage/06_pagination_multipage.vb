' 06_pagination_multipage -- VB.NET port of examples\delphi\xfa\06_pagination_multipage
'
' "Flavor tour" example 6 of 10: MULTI-PAGE PAGINATION. Demonstrates full
' pageSet/pageArea/contentArea pagination: a realistic "Invoice Line Items"
' report for Acme Robotics and Automation Inc., invoice INV-2026-0724, with
' 70 line items (occur min="1" max="-1"), a one-time InvoiceHeader banner on
' page 1 only, and leader/trailer "continued" banner subforms via
' <overflow leader=... trailer=...>. Hand-derived page count = 4
' (19 + 18 + 18 + 15 rows across 4 pages -- see the Delphi README.md for the
' full derivation).
'
' This driver also calls the pdfXFAFormPageCount pre-flight export BEFORE
' pdfRenderXFAForm and asserts it equals the expected page count, exactly
' like the Delphi original's CheckPageCount=4 convention.
'
' Renders 06_pagination_multipage.template.xml / .datasets.xml (pre-split
' packet bytes) through the real LumasPdf.dll:
'
'   pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
'   pdfCreateXFAStreamA('datasets',...) -> pdfXFAFormPageCount (pre-flight) ->
'   pdfRenderXFAForm -> pdfCloseFile
'
' Does NOT rebuild LumasPdf.dll -- links only against the generated
' wrappers\vbnet\LumasPdf.vb P/Invoke binding (LumasPdf.VB.dll) and the
' already-built LumasPdf.dll copied next to this exe.
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module PaginationMultipage

    ' CheckPageCount>=0: also calls the pdfXFAFormPageCount pre-flight export
    ' BEFORE rendering, asserting it matches CheckPageCount exactly.
    Function RenderExample(ByVal TemplatePath As String, ByVal DatasetsPath As String, ByVal OutPdfPath As String, Optional ByVal CheckPageCount As Integer = -1) As Integer
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

            If CheckPageCount >= 0 Then
                Dim Pre As Integer = LumasPdf.pdfXFAFormPageCount(pdf)
                Console.WriteLine("pdfXFAFormPageCount (pre-flight, before any AppendPage) -> " & Pre)
                If Pre <> CheckPageCount Then
                    Console.WriteLine("PAGECOUNT-MISMATCH: expected " & CheckPageCount & " got " & Pre)
                    RenderExample = -102
                    Return RenderExample
                End If
            End If

            Dim Rc As Integer = LumasPdf.pdfRenderXFAForm(pdf)
            Console.WriteLine("pdfRenderXFAForm -> " & Rc)
            If Rc < 0 Then
                Console.WriteLine("pdfRenderXFAForm FAILED, code " & Rc)
                Return RenderExample
            End If
            If CheckPageCount >= 0 AndAlso Rc <> CheckPageCount Then
                Console.WriteLine("RENDER-PAGECOUNT-MISMATCH: pre-flight said " & CheckPageCount & " but render produced " & Rc)
                RenderExample = -103
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
            Path.Combine(ExeDir, "06_pagination_multipage.template.xml"),
            Path.Combine(ExeDir, "06_pagination_multipage.datasets.xml"),
            Path.Combine(ExeDir, "06_pagination_multipage.pdf"), 4)
        Console.WriteLine("RESULT|06_pagination_multipage=" & R1)
        If R1 = 4 Then
            Console.WriteLine("Expected page layout (verify with pypdf's ContentStream/Tj extraction):")
            Console.WriteLine("  Page 1: header + rows 1-19  (19 rows), trailer, no leader")
            Console.WriteLine("  Page 2: leader + rows 20-37 (18 rows), trailer")
            Console.WriteLine("  Page 3: leader + rows 38-55 (18 rows), trailer")
            Console.WriteLine("  Page 4: leader + rows 56-70 (15 rows), NO trailer (true last page)")
        End If
    End Sub

End Module

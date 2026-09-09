' 07_table_layout -- VB.NET port of examples\delphi\xfa\07_table_layout
'
' "Flavor tour" example 7 of 10: TABLE LAYOUT (layout="table"). Demonstrates
' a columnWidths-driven table subform ("Product Comparison Table", 4 columns
' x 6 rows: 1 header + 5 data rows), laid out and rendered through the
' engine's real DrawTable primitive. Every cell authors its own <para
' hAlign> (left/right/center/right across the 4 columns) so all three
' alignments are exercised across every row.
'
' Renders 07_table_layout.template.xml / .datasets.xml (pre-split packet
' bytes) through the real LumasPdf.dll:
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

Module TableLayout

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
            Path.Combine(ExeDir, "07_table_layout.template.xml"),
            Path.Combine(ExeDir, "07_table_layout.datasets.xml"),
            Path.Combine(ExeDir, "07_table_layout.pdf"))
        Console.WriteLine("RESULT|07_table_layout=" & R1)
        If R1 >= 1 Then
            Console.WriteLine("Expected layout (verify with pypdf's raw Tj/text-position extraction):")
            Console.WriteLine("  6 rows stacked at y = 688,668,648,628,608,588 (20pt decrement, tb-style)")
            Console.WriteLine("  Column 1 (Product, hAlign=left):   every row starts at x=39")
            Console.WriteLine("  Column 2 (Price, hAlign=right):    every row ENDS at x~=356.99")
            Console.WriteLine("  Column 3 (Stock, hAlign=center):   centered on x=414")
            Console.WriteLine("  Column 4 (Rating, hAlign=right):   every row ENDS at x~=573.0")
        End If
    End Sub

End Module

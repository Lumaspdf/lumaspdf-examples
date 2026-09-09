' 08_picture_clause_formatting -- VB.NET port of examples\delphi\xfa\08_picture_clause_formatting
'
' "Flavor tour" example 8 of 10: PICTURE-CLAUSE FORMATTING. Demonstrates the
' XFA <format><picture> formatter: real num{}/date{}/text{} picture patterns
' applied both to plain bound data values and to a value produced by a
' FormCalc <calculate> script, proving the calculate-then-format pipeline
' order (the picture clause is applied to the calc script's RESULT, not
' skipped for calculated fields). The form is a one-page "Purchase Receipt".
'
' Renders 08_picture_clause_formatting.template.xml / .datasets.xml
' (pre-split packet bytes) through the real LumasPdf.dll:
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

Module PictureClauseFormatting

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
            If Rc < 1 Then
                Console.WriteLine("RENDER-FAILED, code " & Rc)
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
            Path.Combine(ExeDir, "08_picture_clause_formatting.template.xml"),
            Path.Combine(ExeDir, "08_picture_clause_formatting.datasets.xml"),
            Path.Combine(ExeDir, "08_picture_clause_formatting.pdf"))
        Console.WriteLine("RESULT|08_picture_clause_formatting=" & R1)
        If R1 >= 1 Then
            Console.WriteLine("Expected rendered text (verify with a PDF text extractor, e.g. pypdf):")
            Console.WriteLine("  Purchase Receipt -- Picture-Clause Formatting")
            Console.WriteLine("  Customer: Acme Corp")
            Console.WriteLine("  Unit Price: 1,875.50          (num{zzz,zz9.99})")
            Console.WriteLine("  Discount: ($125.00)           (num{($zzz,zz9.99)}, negative)")
            Console.WriteLine("  Date: July 24, 2026           (date{MMMM DD, YYYY})")
            Console.WriteLine("  Phone: 555-123-4567           (text{999-999-9999})")
            Console.WriteLine("  845.25 620.00 410.25          (raw calc inputs)")
            Console.WriteLine("  Grand Total: 1,875.50         (calculate result, THEN picture-formatted)")
        End If
    End Sub

End Module

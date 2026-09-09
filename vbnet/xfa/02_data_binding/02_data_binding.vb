' 02_data_binding -- VB.NET port of examples\delphi\xfa\02_data_binding
'
' "Flavor tour" example 2 of 10: DATA BINDING. Demonstrates the three
' data-binding modes an XFA form mixes in practice, all against one
' realistic, genuinely nested <xfa:datasets> packet:
'   1. Implicit binding (by-name, no <bind> element at all), including a
'      nested subform one level deeper.
'   2. Explicit <bind match="dataRef" ref="$data...."/> against a genuinely
'      nested SOM path (3 and 4 levels deep).
'   3. <bind match="none"/> -- pure literal, unaffected by same-named data.
'
' Renders 02_data_binding.template.xml / .datasets.xml (pre-split packet
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

Module DataBinding

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
            Path.Combine(ExeDir, "02_data_binding.template.xml"),
            Path.Combine(ExeDir, "02_data_binding.datasets.xml"),
            Path.Combine(ExeDir, "02_data_binding.render.pdf"))
        Console.WriteLine("RESULT|02_data_binding=" & R1)
        If R1 >= 1 Then
            Console.WriteLine("Expected field values (verify with a PDF text extractor):")
            Console.WriteLine("  Customer Name (implicit)            = Acme Robotics LLC")
            Console.WriteLine("  Account ID (implicit)               = ACCT-88213")
            Console.WriteLine("  Street (implicit, nested subform)   = 500 Innovation Way")
            Console.WriteLine("  State (implicit, nested subform)    = IL")
            Console.WriteLine("  Zip (implicit, nested subform)      = 62704")
            Console.WriteLine("  Shipping City (explicit dataRef, 3 deep)  = Springfield")
            Console.WriteLine("  Primary Contact Email (explicit dataRef, 4 deep) = ap@acmerobotics.example")
            Console.WriteLine("  Status (match=""none"", literal)       = Active - Verified (NOT PENDING_CLOSURE)")
        End If
    End Sub

End Module

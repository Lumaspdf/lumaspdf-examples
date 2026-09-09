' 10_javascript_scripting -- VB.NET port of examples\delphi\xfa\10_javascript_scripting
'
' "Flavor tour" example 10 of 10: JAVASCRIPT SCRIPTING. Demonstrates
' <script contentType="application/x-javascript"> calculate scripts -- the
' last piece of the XFA dynamic-form engine, wired minimally and XFA-only
' (this.rawValue getter/setter + xfa.resolveNode(path).rawValue via BESEN,
' already embedded in the engine). JS scripting needed no new export -- it
' plugs into the SAME pdfRenderXFAForm pipeline FormCalc already uses.
'
' Scope note: this exercises XFA-scoped JS only, not the full engine-wide
' document-level pdfExecuteJavaScript* JS execution (a separate feature).
'
' Renders 10_javascript_scripting.template.xml / .datasets.xml (pre-split
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

Module JavascriptScripting

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
            End If

            Dim Rc As Integer = LumasPdf.pdfRenderXFAForm(pdf)
            Console.WriteLine("pdfRenderXFAForm -> " & Rc & " (expected: page count >= 1)")
            If Rc < 1 Then
                Console.WriteLine("RENDER-FAILED, code " & Rc)
                Return RenderExample
            End If

            If Not LumasPdf.pdfCloseFile(pdf) Then
                Console.WriteLine("pdfCloseFile FAILED")
                Return RenderExample
            End If
            Console.WriteLine("Wrote " & OutPdfPath & " (" & Rc & " page(s))")
            RenderExample = Rc
        Finally
            LumasPdf.pdfDeletePDF(pdf)
        End Try
    End Function

    Sub Main()
        Try
            Dim ExeDir As String = AppDomain.CurrentDomain.BaseDirectory
            Dim Rc As Integer = RenderExample(
                Path.Combine(ExeDir, "10_javascript_scripting.template.xml"),
                Path.Combine(ExeDir, "10_javascript_scripting.datasets.xml"),
                Path.Combine(ExeDir, "output.pdf"))
            If Rc >= 1 Then
                Console.WriteLine("OK: JavaScript-scripted form rendered, " & Rc & " page(s). Open output.pdf and confirm:")
            Else
                Console.WriteLine("FAILED, see errors above.")
            End If
            Console.WriteLine("  - UnitPriceWithTax  ~= 21.59  (19.99 * 1.08)")
            Console.WriteLine("  - OrderSummary      = ""Purchase Order PO-1042 for Acme Robotics""")
            Console.WriteLine("  - 3 Line rows, Total = Qty*UnitCost per row (50.00 / 90.00 / 89.75)")
        Catch ex As Exception
            Console.WriteLine("EXCEPTION: " & ex.GetType().Name & ": " & ex.Message)
        End Try
    End Sub

End Module

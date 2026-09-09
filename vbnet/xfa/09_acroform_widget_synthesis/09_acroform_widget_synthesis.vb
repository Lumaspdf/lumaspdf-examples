' 09_acroform_widget_synthesis -- VB.NET port of examples\delphi\xfa\09_acroform_widget_synthesis
'
' "Flavor tour" example 9 of 10: ACROFORM WIDGET SYNTHESIS. Demonstrates
' pdfSetXFARenderMode(doc, 1) -- turning an XFA form into a genuinely
' fillable AcroForm PDF, not just flattened ink. The form is a one-page "Job
' Application Form" exercising every synthesizable widget type at once
' (textEdit/numericEdit/dateTimeEdit -> Tx, checkButton exclGroup -> one Btn
' radio field with 3 Kids, choiceList -> Ch combo, button -> Btn pushbutton
' with a real bevel /AP, and 3 occur-repeated textEdit rows -> unique
' bracket-indexed flat names).
'
' Renders the SAME .xdp packets TWICE through the real DLL's public export
' sequence:
'
'   pdfNewPDF -> pdfCreateNewPDFA -> pdfCreateXFAStreamA('template',...) ->
'   pdfCreateXFAStreamA('datasets',...) ->
'   [pdfSetXFARenderMode(doc,1) only for the second pass] ->
'   pdfRenderXFAForm -> pdfCloseFile -> pdfDeletePDF
'
'     mode0.pdf -- Mode 0 (default, no pdfSetXFARenderMode call at all):
'                  flattened ink only. /AcroForm/Fields is empty.
'     mode1.pdf -- Mode 1 (pdfSetXFARenderMode(doc, 1)): flattened ink PLUS
'                  a real synthesized /AcroForm with 9 fillable fields.
'
' Does NOT rebuild LumasPdf.dll -- links only against the generated
' wrappers\vbnet\LumasPdf.vb P/Invoke binding (LumasPdf.VB.dll) and the
' already-built LumasPdf.dll copied next to this exe.
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module AcroformWidgetSynthesis

    ' Mode: 0 = flatten-to-ink only (default, no pdfSetXFARenderMode call at
    ' all -- exercises the untouched default path); 1 = also synthesize real
    ' AcroForm fillable widgets.
    Function RenderExample(ByVal TemplatePath As String, ByVal DatasetsPath As String, ByVal OutPdfPath As String, ByVal Mode As Integer) As Integer
        RenderExample = -100
        Console.WriteLine("=== " & Path.GetFileName(TemplatePath) & " (mode=" & Mode & ") -> " & Path.GetFileName(OutPdfPath) & " ===")
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

            If Mode <> 0 Then
                Dim Prev As Integer = LumasPdf.pdfSetXFARenderMode(pdf, Mode)
                Console.WriteLine("pdfSetXFARenderMode(pdf, " & Mode & ") -> previous=" & Prev & " (expect 0, the default)")
            End If

            Dim Rc As Integer = LumasPdf.pdfRenderXFAForm(pdf)
            Console.WriteLine("pdfRenderXFAForm -> " & Rc & " (expected: page count >= 1)")
            If Rc < 1 Then
                Console.WriteLine("RENDER-FAILED, code " & Rc)
                Return RenderExample
            End If

            If Not LumasPdf.pdfCloseFile(pdf) Then
                Console.WriteLine("pdfCloseFile FAILED")
                RenderExample = -101
                Return RenderExample
            End If
            Console.WriteLine("OK: wrote " & OutPdfPath & " (" & Rc & " page(s))")
            RenderExample = Rc
        Finally
            LumasPdf.pdfDeletePDF(pdf)
        End Try
    End Function

    Sub Main()
        Dim ExeDir As String = AppDomain.CurrentDomain.BaseDirectory
        Dim TemplatePath As String = Path.Combine(ExeDir, "09_acroform_widget_synthesis.template.xml")
        Dim DatasetsPath As String = Path.Combine(ExeDir, "09_acroform_widget_synthesis.datasets.xml")

        Dim R0 As Integer = RenderExample(TemplatePath, DatasetsPath, Path.Combine(ExeDir, "mode0.pdf"), 0)
        Dim R1 As Integer = RenderExample(TemplatePath, DatasetsPath, Path.Combine(ExeDir, "mode1.pdf"), 1)

        Console.WriteLine()
        Console.WriteLine("RESULT|mode0=" & R0 & "|mode1=" & R1)
        If R0 >= 1 AndAlso R1 >= 1 Then
            Console.WriteLine("OK: both renders succeeded.")
            Console.WriteLine("  mode0.pdf -- flattened ink only, NO /AcroForm/Fields.")
            Console.WriteLine("  mode1.pdf -- flattened ink PLUS a REAL fillable AcroForm (9 top-level fields):")
            Console.WriteLine("    ApplicantName (Tx), YearsExperience (Tx), ApplicationDate (Tx),")
            Console.WriteLine("    EmploymentType (Btn radio, 3 Kids: Full-time/Part-time/Contract),")
            Console.WriteLine("    Department (Ch combo, 6 options), SubmitButton (Btn pushbutton, real bevel /AP),")
            Console.WriteLine("    Employer[0].EmployerName / Employer[1].EmployerName / Employer[2].EmployerName (Tx x3).")
            Console.WriteLine("  Open mode1.pdf in a real PDF reader (Acrobat, Chrome, Edge, etc.) --")
            Console.WriteLine("  it is a genuinely fillable form: click into the fields and type.")
        Else
            Console.WriteLine("FAILED, see errors above.")
        End If
    End Sub

End Module

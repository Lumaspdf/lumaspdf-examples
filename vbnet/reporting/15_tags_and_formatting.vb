' 15_tags_and_formatting -- VB.NET port of examples\Vb6\reporting\15_tags_and_formatting.bas
' Exercises the {{ }} interpolation namespace + text-formatting knobs, then proves
' (by exporting to plain TEXT and grepping it) that the interpolations resolved.
Imports System
Imports System.IO
Imports System.Text
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod15_tags_and_formatting
    Private Const PDF_DEMO_KEY As String = "LUMAS-LumasReportExamples-DD5D40E0"
    Private Const RPT_DEMO_KEY As String = "LRPT2-TFIwMgECAAIAAgIAAQADBAD___9_BAEAAAUBAAAGCAAAAAAAAAAAAAcQAEx1bWFzUnB0RXhhbXBsZXM.sneCg6LX_J59AcqzUZPx1WqQ7jGQZyji4z0WMm_vIoycNySw12vGVoKV76gk3-yQtx3LfZZepGxoDdQAgf5MAA"

    Private mPdf As IntPtr
    Private mEng As IntPtr

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    Function TrimNull(ByVal s As String) As String
        If s Is Nothing Then Return ""
        Dim p As Integer = s.IndexOf(ChrW(0))
        If p >= 0 Then Return s.Substring(0, p) Else Return s
    End Function

    Sub WriteTextFile(ByVal path As String, ByVal content As String)
        File.WriteAllText(path, content)
    End Sub

    Sub DumpRptError(ByVal eng As IntPtr)
        Dim sz As Integer = Marshal.SizeOf(GetType(TRptErrorInfoC))
        Dim p As IntPtr = Marshal.AllocHGlobal(sz)
        Try
            If LumasPdf.rptGetLastError(eng, p) Then
                Dim info As TRptErrorInfoC = CType(Marshal.PtrToStructure(p, GetType(TRptErrorInfoC)), TRptErrorInfoC)
                If info.Code <> 0 Then
                    Console.WriteLine("  ! rpt error " & info.Code & " [" & TrimNull(info.Module_) & _
                        "] at " & TrimNull(info.Location) & ": " & TrimNull(info.Msg))
                End If
            End If
        Finally
            Marshal.FreeHGlobal(p)
        End Try
    End Sub

    Function BootEngine() As Boolean
        mPdf = LumasPdf.pdfNewPDF()
        If mPdf = IntPtr.Zero Then Console.WriteLine("pdfNewPDF failed") : Return False
        LumasPdf.pdfSetLicenseKey(mPdf, PDF_DEMO_KEY)
        LumasPdf.rptSetRptLicenseKeyA(mPdf, RPT_DEMO_KEY)
        mEng = LumasPdf.rptCreateEngineA(mPdf, Nothing)
        If mEng = IntPtr.Zero Then Console.WriteLine("rptCreateEngine failed") : Return False
        Return True
    End Function

    Function CsvData() As String
        Dim s As String = ""
        s = s & "Col,Note" & vbLf
        s = s & "Alpha,first" & vbLf
        s = s & "Beta,second" & vbLf
        Return s
    End Function

    Function ReportTmpl() As String
        Dim s As String = ""
        s = s & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
        s = s & "<report name=""TagTour"" tagLangVersion=""1"">" & vbLf
        s = s & " <page width=""210"" height=""297"" marginLeft=""12"" marginTop=""12"" marginRight=""12"" marginBottom=""12""/>" & vbLf
        s = s & " <datasources>" & vbLf
        s = s & "  <datasource alias=""d"" provider=""csv"" conn=""%CSV%""/>" & vbLf
        s = s & " </datasources>" & vbLf
        s = s & " <params>" & vbLf
        s = s & "  <param name=""Name"" default=""(unset)""/>" & vbLf
        s = s & " </params>" & vbLf
        s = s & " <bands>" & vbLf
        s = s & "  <band kind=""reportheader"" name=""rh"" height=""120"">" & vbLf
        s = s & "   <text name=""h""   x=""0"" y=""0""  w=""186"" h=""8"" fontSize=""16"" hAlign=""center"">Tag &amp; formatting tour</text>" & vbLf
        s = s & "   <text name=""ex""  x=""0"" y=""12"" w=""186"" h=""6"" fontSize=""11"">expr 2+3*4 = {{expr: 2+3*4 }}</text>" & vbLf
        s = s & "   <text name=""vr""  x=""0"" y=""20"" w=""186"" h=""6"" fontSize=""11"">var:Name = {{var:Name}}</text>" & vbLf
        s = s & "   <text name=""fn""  x=""0"" y=""28"" w=""186"" h=""6"" fontSize=""11"">FORMATNUM = {{expr: FORMATNUM('#,##0.00', 1234.5) }}</text>" & vbLf
        s = s & "   <text name=""fd""  x=""0"" y=""36"" w=""186"" h=""6"" fontSize=""11"">FORMATDATE = {{expr: FORMATDATE('yyyy-mm-dd', TODAY()) }}</text>" & vbLf
        s = s & "   <text name=""esc"" x=""0"" y=""44"" w=""186"" h=""6"" fontSize=""11"">escape literal = {{{{ }}</text>" & vbLf
        s = s & "   <text name=""a0"" x=""0"" y=""56"" w=""186"" h=""6"" fontSize=""10"" hAlign=""0"">hAlign 0 = left</text>" & vbLf
        s = s & "   <text name=""a1"" x=""0"" y=""63"" w=""186"" h=""6"" fontSize=""10"" hAlign=""1"">hAlign 1 = center</text>" & vbLf
        s = s & "   <text name=""a2"" x=""0"" y=""70"" w=""186"" h=""6"" fontSize=""10"" hAlign=""2"">hAlign 2 = right</text>" & vbLf
        s = s & "   <text name=""a3"" x=""0"" y=""77"" w=""186"" h=""6"" fontSize=""10"" hAlign=""3"">hAlign 3 = justify this line so it spreads across the whole width of the box evenly</text>" & vbLf
        s = s & "   <text name=""v0"" x=""0""   y=""92"" w=""60"" h=""20"" fontSize=""9"" vAlign=""0"">vAlign 0 top</text>" & vbLf
        s = s & "   <text name=""v1"" x=""63""  y=""92"" w=""60"" h=""20"" fontSize=""9"" vAlign=""1"">vAlign 1 middle</text>" & vbLf
        s = s & "   <text name=""v2"" x=""126"" y=""92"" w=""60"" h=""20"" fontSize=""9"" vAlign=""2"">vAlign 2 bottom</text>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & "  <band kind=""detail"" name=""rows"" height=""7"" data=""d"">" & vbLf
        s = s & "   <text name=""r"" x=""0"" y=""0"" w=""186"" h=""6"" fontSize=""11"">row: fields.d.Col={{fields.d.Col}}  bare d.Col={{d.Col}}  note={{d.Note}}</text>" & vbLf
        s = s & "  </band>" & vbLf
        s = s & " </bands>" & vbLf
        s = s & "</report>" & vbLf
        Return s
    End Function

    Sub Prove(ByVal What As String, ByVal Needle As String, ByVal Hay As String)
        If Hay.IndexOf(Needle) >= 0 Then
            Console.WriteLine("  OK   " & What & " found """ & Needle & """")
        Else
            Console.WriteLine("  MISS " & What & " expected """ & Needle & """")
        End If
    End Sub

    Sub Main()
        If Not BootEngine() Then Return

        Dim Dir_ As String = AppPath() & "\"
        Dim Csv As String = Dir_ & "15_data.csv"
        Dim OutPdf As String = Dir_ & "15_tags.pdf"
        Dim OutTxt As String = Dir_ & "15_tags.txt"

        WriteTextFile(Csv, CsvData())

        Dim Xml As String = ReportTmpl().Replace("%CSV%", Csv)
        Dim bytes() As Byte = Encoding.UTF8.GetBytes(Xml)
        Dim buf As IntPtr = Marshal.AllocHGlobal(bytes.Length)
        Dim Job As IntPtr = IntPtr.Zero
        Try
            Marshal.Copy(bytes, 0, buf, bytes.Length)
            Job = LumasPdf.rptOpenReportMem(mEng, buf, bytes.Length)
            If Job = IntPtr.Zero Then Console.WriteLine("open failed") : DumpRptError(mEng) : GoTo Cleanup

            LumasPdf.rptSetParamStr(Job, "Name", "Ada_Lovelace")

            If Not LumasPdf.rptRender(Job) Then Console.WriteLine("render failed") : DumpRptError(mEng) : GoTo CloseJob
            Console.WriteLine("rendered " & LumasPdf.rptGetPageCount(Job) & " page(s)")

            If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf) Then Console.WriteLine("PDF export failed") : DumpRptError(mEng) : GoTo CloseJob
            Console.WriteLine("wrote " & OutPdf)
            If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_TEXT, OutTxt) Then Console.WriteLine("TEXT export failed") : DumpRptError(mEng) : GoTo CloseJob
            Console.WriteLine("wrote " & OutTxt)
CloseJob:
            LumasPdf.rptCloseReport(Job)
        Finally
            Marshal.FreeHGlobal(buf)
        End Try

        ' --- Proof: grep the TEXT export for each resolved interpolation --------
        Console.WriteLine("== Proof (grep the TEXT export) ==")
        Dim Txt As String = ""
        If File.Exists(OutTxt) Then Txt = File.ReadAllText(OutTxt)
        Dim IsoToday As String = DateTime.Now.ToString("yyyy-MM-dd")

        Prove("expr 2+3*4", "= 14", Txt)
        Prove("var:Name", "Ada_Lovelace", Txt)
        Prove("FORMATNUM", "1,234.50", Txt)
        Prove("FORMATDATE", IsoToday, Txt)
        Prove("escape {{}}", "{{ }}", Txt)
        Prove("fields.d.Col", "Alpha", Txt)
        Prove("bare d.Col", "Beta", Txt)
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
    End Sub
End Module

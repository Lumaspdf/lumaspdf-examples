' 05_elements -- VB.NET port of examples\Vb6\reporting\05_elements.bas
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module mod05_elements
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

    Function GetRptErr(ByVal eng As IntPtr, ByRef info As TRptErrorInfoC) As Boolean
        Dim sz As Integer = Marshal.SizeOf(GetType(TRptErrorInfoC))
        Dim p As IntPtr = Marshal.AllocHGlobal(sz)
        Try
            Dim ok As Boolean = LumasPdf.rptGetLastError(eng, p)
            If ok Then info = CType(Marshal.PtrToStructure(p, GetType(TRptErrorInfoC)), TRptErrorInfoC)
            Return ok
        Finally
            Marshal.FreeHGlobal(p)
        End Try
    End Function

    Sub DumpRptError(ByVal eng As IntPtr)
        Dim info As TRptErrorInfoC
        If GetRptErr(eng, info) Then
            If info.Code <> 0 Then
                Console.WriteLine("  ! rpt error " & info.Code & " [" & TrimNull(info.Module_) & _
                    "] at " & TrimNull(info.Location) & ": " & TrimNull(info.Msg))
            End If
        End If
    End Sub

    Function BootEngine() As Boolean
        mPdf = LumasPdf.pdfNewPDF()
        If mPdf = IntPtr.Zero Then
            Console.WriteLine("pdfNewPDF failed")
            Return False
        End If
        LumasPdf.pdfSetLicenseKey(mPdf, PDF_DEMO_KEY)
        LumasPdf.rptSetRptLicenseKeyA(mPdf, RPT_DEMO_KEY)
        mEng = LumasPdf.rptCreateEngineA(mPdf, Nothing)
        If mEng = IntPtr.Zero Then
            Console.WriteLine("rptCreateEngine failed:")
            DumpRptError(IntPtr.Zero)
            Return False
        End If
        Return True
    End Function

    Sub WriteBmp8x8(ByVal path As String)
        Using ms As New MemoryStream()
            Dim w As New BinaryWriter(ms)
            ' BITMAPFILEHEADER
            w.Write(CByte(Asc("B"))) : w.Write(CByte(Asc("M")))
            w.Write(CInt(54 + 192))
            w.Write(CInt(0))
            w.Write(CInt(54))
            ' BITMAPINFOHEADER
            w.Write(CInt(40))
            w.Write(CInt(8)) : w.Write(CInt(8))
            w.Write(CShort(1))
            w.Write(CShort(24))
            w.Write(CInt(0))
            w.Write(CInt(192))
            w.Write(CInt(2835)) : w.Write(CInt(2835))
            w.Write(CInt(0)) : w.Write(CInt(0))
            ' pixels bottom-up BGR
            Dim x As Integer, y As Integer
            For y = 0 To 7
                For x = 0 To 7
                    If ((x + y) And 1) = 0 Then
                        w.Write(CByte(0)) : w.Write(CByte(0)) : w.Write(CByte(255))
                    Else
                        w.Write(CByte(255)) : w.Write(CByte(0)) : w.Write(CByte(0))
                    End If
                Next
            Next
            w.Flush()
            File.WriteAllBytes(path, ms.ToArray())
        End Using
    End Sub

    Sub Main()
        If Not BootEngine() Then Return

        Dim Lrpt As String = AppPath() & "\05_elements.lrpt"
        Dim Sub_ As String = AppPath() & "\05_sub.lrpt"
        Dim Img As String = AppPath() & "\05_img.bmp"
        Dim OutPdf As String = AppPath() & "\05_elements.pdf"

        Dim Xml As String = ""
        Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
        Xml = Xml & "<report name=""Sub"" tagLangVersion=""1"">" & vbLf
        Xml = Xml & " <page width=""70"" height=""30"" marginLeft=""1"" marginTop=""1"" marginRight=""1"" marginBottom=""1""/>" & vbLf
        Xml = Xml & " <bands>" & vbLf
        Xml = Xml & "  <band kind=""reportheader"" name=""sh"" height=""10"">" & vbLf
        Xml = Xml & "   <text name=""st"" x=""0"" y=""0"" w=""66"" h=""6"" fontSize=""8"">Subreport content here.</text>" & vbLf
        Xml = Xml & "  </band>" & vbLf
        Xml = Xml & " </bands>" & vbLf
        Xml = Xml & "</report>" & vbLf
        WriteTextFile(Sub_, Xml)
        WriteBmp8x8(Img)
        Xml = ""
        Xml = Xml & "<?xml version=""1.0"" encoding=""UTF-8""?>" & vbLf
        Xml = Xml & "<report name=""Elements"" tagLangVersion=""1"">" & vbLf
        Xml = Xml & " <page width=""210"" height=""297"" marginLeft=""15"" marginTop=""15"" marginRight=""15"" marginBottom=""15""/>" & vbLf
        Xml = Xml & " <bands>" & vbLf
        Xml = Xml & "  <band kind=""reportheader"" name=""rh"" height=""150"">" & vbLf
        Xml = Xml & "   <text name=""title"" x=""0"" y=""0"" w=""180"" h=""10"" fontSize=""18"" hAlign=""center"">Every Element Kind</text>" & vbLf
        Xml = Xml & "   <text name=""note""  x=""0"" y=""12"" w=""180"" h=""6"" fontSize=""9"" hAlign=""center"">text / line / shape / image / barcode / subreport</text>" & vbLf
        Xml = Xml & "   <line  name=""rule"" x=""0"" y=""20"" w=""180"" h=""0.3"" toX=""180"" toY=""0""/>" & vbLf
        Xml = Xml & "   <shape name=""rect"" x=""0""  y=""26"" w=""55"" h=""22"" shape=""0""/>" & vbLf
        Xml = Xml & "   <shape name=""rrct"" x=""63"" y=""26"" w=""55"" h=""22"" shape=""1""/>" & vbLf
        Xml = Xml & "   <shape name=""elps"" x=""126"" y=""26"" w=""55"" h=""22"" shape=""2""/>" & vbLf
        Xml = Xml & "   <text name=""l1"" x=""0""   y=""49"" w=""55"" h=""5"" fontSize=""7"" hAlign=""center"">shape=0 rect</text>" & vbLf
        Xml = Xml & "   <text name=""l2"" x=""63""  y=""49"" w=""55"" h=""5"" fontSize=""7"" hAlign=""center"">shape=1 roundrect</text>" & vbLf
        Xml = Xml & "   <text name=""l3"" x=""126"" y=""49"" w=""55"" h=""5"" fontSize=""7"" hAlign=""center"">shape=2 ellipse</text>" & vbLf
        Xml = Xml & "   <image name=""pic"" x=""0"" y=""58"" w=""24"" h=""24"" source=""" & Img & """ stretch=""1""/>" & vbLf
        Xml = Xml & "   <text name=""il"" x=""0"" y=""83"" w=""40"" h=""5"" fontSize=""7"">8x8 BMP image</text>" & vbLf
        Xml = Xml & "   <barcode name=""qr""  x=""40""  y=""58"" w=""24"" h=""24"" type=""0"" text=""QR:LumasReport""/>" & vbLf
        Xml = Xml & "   <barcode name=""pdf"" x=""70""  y=""58"" w=""40"" h=""24"" type=""1"" text=""PDF417-DATA-001""/>" & vbLf
        Xml = Xml & "   <barcode name=""dm""  x=""116"" y=""58"" w=""24"" h=""24"" type=""2"" text=""DataMatrix99""/>" & vbLf
        Xml = Xml & "   <barcode name=""az""  x=""146"" y=""58"" w=""24"" h=""24"" type=""3"" text=""AZTEC-XYZ""/>" & vbLf
        Xml = Xml & "   <text name=""bl"" x=""40"" y=""83"" w=""140"" h=""5"" fontSize=""7"">barcodes: QR / PDF417 / DataMatrix / Aztec</text>" & vbLf
        Xml = Xml & "   <subreport name=""sub"" x=""0"" y=""92"" w=""90"" h=""30"" ref=""05_sub.lrpt""/>" & vbLf
        Xml = Xml & "   <text name=""sl"" x=""0"" y=""123"" w=""120"" h=""5"" fontSize=""7"">^ subreport (05_sub.lrpt) merged above</text>" & vbLf
        Xml = Xml & "  </band>" & vbLf
        Xml = Xml & " </bands>" & vbLf
        Xml = Xml & "</report>" & vbLf
        WriteTextFile(Lrpt, Xml)

        Dim Job As IntPtr = LumasPdf.rptOpenReportA(mEng, Lrpt)
        If Job = IntPtr.Zero Then
            Console.WriteLine("open failed")
            DumpRptError(mEng)
            GoTo Cleanup
        End If
        If Not LumasPdf.rptRender(Job) Then
            Console.WriteLine("render failed")
            DumpRptError(mEng)
            LumasPdf.rptCloseReport(Job)
            GoTo Cleanup
        End If
        Console.WriteLine("rendered " & LumasPdf.rptGetPageCount(Job) & " page(s)")
        If Not LumasPdf.rptExportA(Job, LumasPdfConsts.RPT_EXP_PDF, OutPdf) Then
            Console.WriteLine("export failed")
            DumpRptError(mEng)
            LumasPdf.rptCloseReport(Job)
            GoTo Cleanup
        End If
        Console.WriteLine("wrote " & OutPdf)
        LumasPdf.rptCloseReport(Job)
Cleanup:
        LumasPdf.rptDeleteEngine(mEng)
        LumasPdf.pdfDeletePDF(mPdf)
    End Sub
End Module

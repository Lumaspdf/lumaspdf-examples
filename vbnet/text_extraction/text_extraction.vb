' text_extraction -- VB.NET port of examples\Vb6\text_extraction\text_extraction.bas
' Imports a PDF and extracts its text with pdfGetPageText()/TPDFStack, rebuilding
' text lines and word boundaries by transforming each text record to user space.
' Output is written to out.txt as UTF-16LE (with BOM).
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports System.Text
Imports LumasPdfSdk

Module modTextExtraction
    ' TTextDir
    Private Const tfLeftToRight As Integer = 0
    Private Const tfRightToLeft As Integer = 1
    Private Const tfTopToBottom As Integer = 2
    Private Const tfBottomToTop As Integer = 4
    Private Const tfNotInitialized As Integer = 5

    Private Const MAX_LINE_ERROR As Double = 4.0   ' square of the allowed error (2 * 2)

    ' CPDFToText member fields
    Private m_PDF As IntPtr
    Private m_File As FileStream
    Private m_Stack As TPDFStack
    Private m_LastTextDir As Integer
    Private m_LastTextEndX As Double
    Private m_LastTextEndY As Double
    Private m_LastTextInfX As Double
    Private m_LastTextInfY As Double

    ' CIntList (template handle list)
    Private m_Templates() As Integer
    Private m_TemplCount As Integer

    Private ErrDelegate As TErrorProc

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    ' ParamArray is UInteger, not Integer: the generated bindings type the
    ' flag constants as UInteger (they have the high bit set, e.g.
    ' ifImportAsPage = &H80000000UI), and passing one to an Integer
    ' parameter is BC30439 "Constant expression not representable in
    ' type 'Integer'". The arithmetic below is unchanged, so the value
    ' handed to the engine -- and therefore the output -- is identical.
    Function Fl(ParamArray vals() As UInteger) As UInteger
        Dim r As Long = 0
        For Each v In vals : r = r Or (CLng(v) And &HFFFFFFFFL) : Next
        Return CUInt(r And &HFFFFFFFFL)
    End Function

    Public Function ErrProc(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0                        ' We try to continue if an error occurs
    End Function

    ' ------------------------- output helpers -------------------------
    Private Sub WriteWStr(ByVal s As String)
        If String.IsNullOrEmpty(s) Then Return
        Dim b() As Byte = Encoding.Unicode.GetBytes(s)   ' UTF-16LE
        m_File.Write(b, 0, b.Length)
    End Sub

    Private Sub WriteWCharsFromPtr(ByVal Ptr As IntPtr, ByVal WCharCount As Integer)
        If Ptr = IntPtr.Zero OrElse WCharCount <= 0 Then Return
        Dim b(WCharCount * 2 - 1) As Byte
        Marshal.Copy(Ptr, b, 0, WCharCount * 2)
        m_File.Write(b, 0, b.Length)
    End Sub

    ' ------------------------- CIntList -------------------------
    Private Sub ListClear()
        m_TemplCount = 0
    End Sub

    Private Sub ListAdd(ByVal Value As Integer)
        If m_Templates Is Nothing Then ReDim m_Templates(63)
        If m_TemplCount > UBound(m_Templates) Then ReDim Preserve m_Templates(m_TemplCount + 63)
        m_Templates(m_TemplCount) = Value
        m_TemplCount += 1
    End Sub

    Private Function ListFind(ByVal Value As Integer) As Integer
        For i As Integer = 0 To m_TemplCount - 1
            If m_Templates(i) = Value Then Return i
        Next
        Return -1
    End Function

    ' ------------------------- matrix helpers -------------------------
    Private Function MulMatrix(ByRef M1 As TCTM, ByRef M2 As TCTM) As TCTM
        Dim r As TCTM
        r.a = M2.a * M1.a + M2.b * M1.c
        r.b = M2.a * M1.b + M2.b * M1.d
        r.c = M2.c * M1.a + M2.d * M1.c
        r.d = M2.c * M1.b + M2.d * M1.d
        r.x = M2.x * M1.a + M2.y * M1.c + M1.x
        r.y = M2.x * M1.b + M2.y * M1.d + M1.y
        Return r
    End Function

    Private Sub Transform(ByRef M As TCTM, ByRef x As Double, ByRef y As Double)
        Dim tx As Double = x
        x = tx * M.a + y * M.c + M.x
        y = tx * M.b + y * M.d + M.y
    End Sub

    Private Function CalcDistance(ByVal x1 As Double, ByVal y1 As Double, ByVal x2 As Double, ByVal y2 As Double) As Double
        Dim dx As Double = x2 - x1
        Dim dy As Double = y2 - y1
        Return Math.Sqrt(dx * dx + dy * dy)
    End Function

    Private Function IsPointOnLine(ByVal x As Double, ByVal y As Double, ByVal x0 As Double, ByVal y0 As Double, ByVal x1 As Double, ByVal y1 As Double) As Boolean
        Dim dx As Double, dy As Double, di As Double
        x = x - x0
        y = y - y0
        dx = x1 - x0
        dy = y1 - y0
        di = (x * dx + y * dy) / (dx * dx + dy * dy)
        If di < 0.0 Then
            di = 0.0
        ElseIf di > 1.0 Then
            di = 1.0
        End If
        dx = x - di * dx
        dy = y - di * dy
        di = dx * dx + dy * dy
        Return (di < MAX_LINE_ERROR)
    End Function

    ' ------------------------- text reconstruction -------------------------
    Private Sub AddText()
        Dim x1 As Double, x2 As Double, x3 As Double
        Dim y1 As Double, y2 As Double, y3 As Double
        Dim distance As Double, spaceWidth As Double
        Dim textDir As Integer, m As TCTM, spw As Single
        Dim rec As TTextRecordW, base As IntPtr

        x1 = 0.0 : y1 = 0.0
        x2 = 0.0 : y2 = m_Stack.FontSize
        ' Transform the text matrix to user space
        m = MulMatrix(m_Stack.ctm, m_Stack.tm)
        Transform(m, x1, y1)                ' Start point of the text record
        Transform(m, x2, y2)                ' Second point -> text direction
        ' Determine the text direction
        If y1 = y2 Then
            textDir = (If(x1 > x2, 1, 0) + 1) * 2
        Else
            textDir = If(y1 > y2, 1, 0)
        End If

        ' Wrong direction or not on the same text line?
        If (textDir <> m_LastTextDir) OrElse (Not IsPointOnLine(x1, y1, m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY)) Then
            ' Extend the x-coordinate to an infinite point.
            m_LastTextInfX = 1000000.0
            m_LastTextInfY = 0.0
            Transform(m, m_LastTextInfX, m_LastTextInfY)
            If m_LastTextDir <> tfNotInitialized Then WriteWStr(vbCrLf)
        Else
            ' Space width is measured in text space, distance in user space -> transform.
            x3 = m_Stack.SpaceWidth
            y3 = 0.0
            Transform(m, x3, y3)
            spaceWidth = CalcDistance(x1, y1, x3, y3)
            distance = CalcDistance(m_LastTextEndX, m_LastTextEndY, x1, y1)
            If distance > spaceWidth Then WriteWStr(" ")
        End If

        ' Use the half space width to decide whether a space must be inserted.
        spw = CSng(-m_Stack.SpaceWidth * 0.5)
        base = m_Stack.Kerning
        Dim recSize As Integer = Marshal.SizeOf(GetType(TTextRecordW))
        For i As Integer = 0 To CInt(m_Stack.KerningCount) - 1
            rec = CType(Marshal.PtrToStructure(IntPtr.Add(base, i * recSize), GetType(TTextRecordW)), TTextRecordW)
            If rec.Advance < spw Then WriteWStr(" ")
            ' The Kerning array contains Unicode strings (two bytes per character).
            WriteWCharsFromPtr(rec.Text, rec.Length)
        Next

        ' Do not set the cursor to the real string end (see original comment).
        m_LastTextEndX = m_Stack.TextWidth + spw       ' spw is negative
        m_LastTextEndY = 0.0
        m_LastTextDir = textDir
        Transform(m, m_LastTextEndX, m_LastTextEndY)
    End Sub

    Private Sub ParseText()
        Dim haveMore As Boolean = LumasPdf.pdfGetPageText(m_PDF, m_Stack)
        If (Not haveMore) AndAlso (m_Stack.TextLen = 0) Then Return
        AddText()
        If haveMore Then
            Do While LumasPdf.pdfGetPageText(m_PDF, m_Stack)
                AddText()
            Loop
        End If
    End Sub

    Private Sub ParseTemplates()
        Dim tmpl As Integer, tmplCount As Integer, tmplCount2 As Integer
        tmplCount = LumasPdf.pdfGetTemplCount(m_PDF)
        For i As Integer = 0 To tmplCount - 1
            If Not LumasPdf.pdfEditTemplate(m_PDF, CUInt(i)) Then Return
            tmpl = LumasPdf.pdfGetTemplHandle(m_PDF)
            If ListFind(tmpl) < 0 Then
                ListAdd(tmpl)
                If Not LumasPdf.pdfInitStack(m_PDF, m_Stack) Then Return
                ParseText()
                tmplCount2 = LumasPdf.pdfGetTemplCount(m_PDF)
                For j As Integer = 0 To tmplCount2 - 1
                    ParseTemplates()
                Next
                LumasPdf.pdfEndTemplate(m_PDF)
            Else
                LumasPdf.pdfEndTemplate(m_PDF)
            End If
        Next
    End Sub

    Private Sub ParsePage()
        ListClear()
        If Not LumasPdf.pdfInitStack(m_PDF, m_Stack) Then
            Console.WriteLine(Marshal.PtrToStringAnsi(LumasPdf.pdfGetErrorMessage(m_PDF)))
            Return
        End If
        m_LastTextEndX = 0.0
        m_LastTextEndY = 0.0
        m_LastTextDir = tfNotInitialized
        m_LastTextInfX = 0.0
        m_LastTextInfY = 0.0
        ParseText()
        ParseTemplates()
    End Sub

    Sub Main()
        Dim outFile As String, inFile As String

        m_PDF = LumasPdf.pdfNewPDF()
        LumasPdf.pdfCreateNewPDFW(m_PDF, "")          ' We do not produce a PDF file in this example
        ErrDelegate = New TErrorProc(AddressOf ErrProc)
        LumasPdf.pdfSetOnErrorProc(m_PDF, IntPtr.Zero, ErrDelegate)

        ' External cmaps should always be loaded when extracting text from PDF files.
        LumasPdf.pdfSetCMapDirW(m_PDF, AppPath() & "\CMap", CUInt(LumasPdfConsts.lcmRecursive Or LumasPdfConsts.lcmDelayed))

        ' Avoid the conversion of pages to templates.
        LumasPdf.pdfSetImportFlags(m_PDF, Fl(LumasPdfConsts.ifImportAll, LumasPdfConsts.ifImportAsPage))
        inFile = AppPath() & "\in.pdf"
        If LumasPdf.pdfOpenImportFileW(m_PDF, inFile, LumasPdfConsts.ptOpen, "") < 0 Then
            LumasPdf.pdfDeletePDF(m_PDF)
            Return
        End If
        LumasPdf.pdfImportPDFFile(m_PDF, 1, 1.0, 1.0)
        LumasPdf.pdfCloseImportFile(m_PDF)

        ' Flatten markup annotations and form fields so their text can be extracted too.
        LumasPdf.pdfFlattenAnnots(m_PDF, CUInt(LumasPdfConsts.affMarkupAnnots))
        LumasPdf.pdfFlattenForm(m_PDF)

        ' Open the output file (out.txt in the application directory).
        outFile = AppPath() & "\out.txt"
        m_File = New FileStream(outFile, FileMode.Create, FileAccess.Write)
        m_File.Write(New Byte() {255, 254}, 0, 2)     ' UTF-16LE BOM

        ' Note that page numbering starts at 1!
        For i As Integer = 1 To LumasPdf.pdfGetPageCount(m_PDF)
            LumasPdf.pdfEditPage(m_PDF, i)           ' Open the page
            WriteWStr(If(i > 1, vbCrLf, "") & "%----------------------- Page " & i & " -----------------------------" & vbCrLf)
            ParsePage()
            LumasPdf.pdfEndPage(m_PDF)               ' Close the page
        Next
        m_File.Close()

        Console.WriteLine("Text successfully extracted to " & outFile)
        LumasPdf.pdfDeletePDF(m_PDF)
    End Sub
End Module

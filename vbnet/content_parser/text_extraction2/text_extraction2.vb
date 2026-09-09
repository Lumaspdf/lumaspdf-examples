' text_extraction2 -- VB.NET port of examples\Vb6\content_parser\text_extraction2
' Drives pdfParseContent() with a TPDFParseInterface of callbacks to reconstruct
' text. The VB6 flattened CPDFToText/CStack into module globals; we do the same.
' Output is written to out.txt as UTF-16LE (with BOM).
Imports System
Imports System.IO
Imports System.Text
Imports System.Collections.Generic
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module modTextExtraction2
    Private Const tfNotInitialized As Integer = 5
    Private Const MAX_LINE_ERROR As Double = 4.0

    ' --- TGState (flattened) ---
    Private m_ActiveFont As IntPtr
    Private m_CharSpacing As Single
    Private m_FontSize As Single
    Private m_FontType As Integer
    Private m_Matrix As TCTM
    Private m_SpaceWidth As Single
    Private m_TextDrawMode As Integer
    Private m_TextScale As Single
    Private m_WordSpacing As Single

    Private Structure TGState
        Public ActiveFont As IntPtr
        Public CharSpacing As Single
        Public FontSize As Single
        Public FontType As Integer
        Public Matrix As TCTM
        Public SpaceWidth As Single
        Public TextDrawMode As Integer
        Public TextScale As Single
        Public WordSpacing As Single
    End Structure

    Private m_PDF As IntPtr
    Private m_LastTextDir As Integer
    Private m_LastTextEndX As Double
    Private m_LastTextEndY As Double
    Private m_LastTextInfX As Double
    Private m_LastTextInfY As Double

    Private m_Stack As New List(Of TGState)
    Private m_sb As New StringBuilder()

    ' keep delegates alive
    Private dBeginTemplate As TBeginTemplate
    Private dEndTemplate As TEndTemplate
    Private dMulMatrix As TMulMatrix
    Private dRestoreGS As TRestoreGraphicState
    Private dSaveGS As TSaveGraphicState
    Private dSetCharSpacing As TSetCharSpacing
    Private dSetFont As TSetFont
    Private dSetTextDrawMode As TSetTextDrawMode
    Private dSetTextScale As TSetTextScale
    Private dSetWordSpacing As TSetWordSpacing
    Private dShowTextArrayW As TShowTextArrayW

    Private ErrDel As TErrorProc

    Function AppPath() As String
        Return AppDomain.CurrentDomain.BaseDirectory.TrimEnd("\"c)
    End Function

    ' UInteger, not Integer: the generated bindings type the flag constants as
    ' UInteger (high bit set, e.g. ifImportAsPage = &H80000000UI), and passing
    ' one to an Integer parameter is BC30439. The value is unchanged, so the
    ' output is unchanged.
    Function UFlag(ByVal v As UInteger) As UInteger
        Return CUInt(v And &HFFFFFFFFL)
    End Function

    Public Function ErrProc(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
    End Function

    Private Sub WriteWStr(ByVal s As String)
        m_sb.Append(s)
    End Sub

    ' ---------------- stack -----------------
    Private Function CaptureGState() As TGState
        Dim g As TGState
        g.ActiveFont = m_ActiveFont : g.CharSpacing = m_CharSpacing : g.FontSize = m_FontSize
        g.FontType = m_FontType : g.Matrix = m_Matrix : g.SpaceWidth = m_SpaceWidth
        g.TextDrawMode = m_TextDrawMode : g.TextScale = m_TextScale : g.WordSpacing = m_WordSpacing
        Return g
    End Function

    Private Sub ApplyGState(ByVal g As TGState)
        m_ActiveFont = g.ActiveFont : m_CharSpacing = g.CharSpacing : m_FontSize = g.FontSize
        m_FontType = g.FontType : m_Matrix = g.Matrix : m_SpaceWidth = g.SpaceWidth
        m_TextDrawMode = g.TextDrawMode : m_TextScale = g.TextScale : m_WordSpacing = g.WordSpacing
    End Sub

    Private Function DoRestoreGState() As Boolean
        If m_Stack.Count > 0 Then
            ApplyGState(m_Stack(m_Stack.Count - 1))
            m_Stack.RemoveAt(m_Stack.Count - 1)
            Return True
        End If
        Return False
    End Function

    Private Function DoSaveGState() As Integer
        m_Stack.Add(CaptureGState())
        Return 0
    End Function

    ' ---------------- matrix helpers -----------------
    Private Function MulMatrix(ByVal M1 As TCTM, ByVal M2 As TCTM) As TCTM
        Dim r As TCTM
        r.a = M2.a * M1.a + M2.b * M1.c
        r.b = M2.a * M1.b + M2.b * M1.d
        r.c = M2.c * M1.a + M2.d * M1.c
        r.d = M2.c * M1.b + M2.d * M1.d
        r.x = M2.x * M1.a + M2.y * M1.c + M1.x
        r.y = M2.x * M1.b + M2.y * M1.d + M1.y
        Return r
    End Function

    Private Sub Transform(ByVal M As TCTM, ByRef x As Double, ByRef y As Double)
        Dim tx As Double = x
        x = tx * M.a + y * M.c + M.x
        y = tx * M.b + y * M.d + M.y
    End Sub

    Private Function CalcDistance(ByVal x1 As Double, ByVal y1 As Double, ByVal x2 As Double, ByVal y2 As Double) As Double
        Dim dx As Double = x2 - x1, dy As Double = y2 - y1
        Return Math.Sqrt(dx * dx + dy * dy)
    End Function

    Private Function IsPointOnLine(ByVal x As Double, ByVal y As Double, ByVal x0 As Double, ByVal y0 As Double, ByVal x1 As Double, ByVal y1 As Double) As Boolean
        Dim dx As Double, dy As Double, di As Double
        x = x - x0 : y = y - y0
        dx = x1 - x0 : dy = y1 - y0
        Dim denom As Double = dx * dx + dy * dy
        If denom = 0.0 Then
            Return (x * x + y * y) < MAX_LINE_ERROR
        End If
        di = (x * dx + y * dy) / denom
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

    ' ---------------- CPDFToText methods -----------------
    Private Sub ResetGState()
        m_ActiveFont = IntPtr.Zero
        m_CharSpacing = 0.0F
        m_FontSize = 1.0F
        m_FontType = CInt(TFontType.ftType1)
        m_Matrix.a = 1.0 : m_Matrix.b = 0.0 : m_Matrix.c = 0.0
        m_Matrix.d = 1.0 : m_Matrix.x = 0.0 : m_Matrix.y = 0.0
        m_SpaceWidth = 0.0F
        m_TextDrawMode = CInt(TDrawMode.dmNormal)
        m_TextScale = 100.0F
        m_WordSpacing = 0.0F
    End Sub

    Private Sub DoInit()
        Do While DoRestoreGState()
        Loop
        ResetGState()
        m_LastTextDir = tfNotInitialized
        m_LastTextEndX = 0.0 : m_LastTextEndY = 0.0
        m_LastTextInfX = 0.0 : m_LastTextInfY = 0.0
    End Sub

    Private Sub DoSetFont(ByVal IFont As IntPtr, ByVal FontType As Integer, ByVal FontSize As Double)
        m_ActiveFont = IFont
        m_FontSize = CSng(FontSize)
        m_FontType = FontType
        m_SpaceWidth = CSng(LumasPdf.fntGetSpaceWidth(IFont, FontSize))
        If FontSize < 0.0 Then m_SpaceWidth = -m_SpaceWidth
    End Sub

    Private Sub DoWritePageIdentifier(ByVal PageNum As Integer)
        If PageNum > 1 Then WriteWStr(vbCrLf)
        WriteWStr("%----------------------- Page " & PageNum & " -----------------------------" & vbCrLf)
    End Sub

    Private Function DoAddText(ByVal Matrix As TCTM, ByVal Kerning As IntPtr, ByVal Count As Integer, ByVal Widen As Double, ByVal Decoded As Boolean) As Integer
        If Not Decoded Then Return 0

        Dim x1 As Double = 0.0, y1 As Double = 0.0
        Dim x2 As Double = 0.0, y2 As Double = m_FontSize
        Dim m As TCTM = MulMatrix(m_Matrix, Matrix)
        Transform(m, x1, y1)
        Transform(m, x2, y2)
        Dim textDir As Integer
        If y1 = y2 Then
            textDir = (If(x1 > x2, 1, 0) + 1) * 2
        Else
            textDir = If(y1 > y2, 1, 0)
        End If

        If (textDir <> m_LastTextDir) OrElse (Not IsPointOnLine(x1, y1, m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY)) Then
            m_LastTextInfX = 1000000.0
            m_LastTextInfY = 0.0
            Transform(m, m_LastTextInfX, m_LastTextInfY)
            If m_LastTextDir <> tfNotInitialized Then WriteWStr(vbCrLf)
        Else
            Dim x3 As Double = m_SpaceWidth, y3 As Double = 0.0
            Transform(m, x3, y3)
            Dim spaceWidth As Double = CalcDistance(x1, y1, x3, y3)
            Dim distance As Double = CalcDistance(m_LastTextEndX, m_LastTextEndY, x1, y1)
            If distance > spaceWidth Then WriteWStr(" ")
        End If

        Dim spw As Single = -m_SpaceWidth * 0.5F
        Dim recSize As Integer = Marshal.SizeOf(GetType(TTextRecordW))
        For i As Integer = 0 To Count - 1
            Dim rec As TTextRecordW = CType(Marshal.PtrToStructure(New IntPtr(Kerning.ToInt64() + i * recSize), GetType(TTextRecordW)), TTextRecordW)
            If rec.Advance < spw Then WriteWStr(" ")
            If rec.Text <> IntPtr.Zero AndAlso rec.Length > 0 Then
                WriteWStr(Marshal.PtrToStringUni(rec.Text, rec.Length))
            End If
        Next

        m_LastTextEndX = Widen + spw
        m_LastTextEndY = 0.0
        m_LastTextDir = textDir
        Transform(m, m_LastTextEndX, m_LastTextEndY)
        Return 0
    End Function

    ' ---------------- callbacks -----------------
    Public Function cbBeginTemplate(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByVal Handle As Integer, ByRef BBox As TPDFRect, ByVal Matrix As IntPtr) As Integer
        If DoSaveGState() < 0 Then Return -1
        If Matrix <> IntPtr.Zero Then
            Dim mtx As TCTM = CType(Marshal.PtrToStructure(Matrix, GetType(TCTM)), TCTM)
            m_Matrix = MulMatrix(m_Matrix, mtx)
        End If
        Return 0
    End Function

    Public Sub cbEndTemplate(ByVal Data As IntPtr)
        DoRestoreGState()
    End Sub

    Public Sub cbMulMatrix(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByRef Matrix As TCTM)
        m_Matrix = MulMatrix(m_Matrix, Matrix)
    End Sub

    Public Function cbRestoreGraphicState(ByVal Data As IntPtr) As Integer
        DoRestoreGState()
        Return 0
    End Function

    Public Function cbSaveGraphicState(ByVal Data As IntPtr) As Integer
        DoSaveGState()
        Return 0
    End Function

    Public Sub cbSetCharSpacing(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByVal Value As Double)
        m_CharSpacing = CSng(Value)
    End Sub

    Public Sub cbSetFont(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByVal FontType As TFontType, ByVal Embedded As Boolean, ByVal FontName As String, ByVal Style As Integer, ByVal FontSize As Double, ByVal Font As IntPtr)
        DoSetFont(Font, CInt(FontType), FontSize)
    End Sub

    Public Sub cbSetTextDrawMode(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByVal Mode As TDrawMode)
        m_TextDrawMode = CInt(Mode)
    End Sub

    Public Sub cbSetTextScale(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByVal Value As Double)
        m_TextScale = CSng(Value)
    End Sub

    Public Sub cbSetWordSpacing(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByVal Value As Double)
        m_WordSpacing = CSng(Value)
    End Sub

    Public Function cbShowTextArrayW(ByVal Data As IntPtr, ByVal Source As IntPtr, ByRef Matrix As TCTM, ByVal Kerning As IntPtr, ByVal Count As UInteger, ByVal Width As Double, ByVal Decoded As Boolean) As Integer
        Return DoAddText(Matrix, Kerning, CInt(Count), Width, Decoded)
    End Function

    Sub Main()
        m_PDF = LumasPdf.pdfNewPDF()
        ErrDel = New TErrorProc(AddressOf ErrProc)
        LumasPdf.pdfSetOnErrorProc(m_PDF, IntPtr.Zero, ErrDel)
        LumasPdf.pdfCreateNewPDFW(m_PDF, "")

        LumasPdf.pdfSetCMapDirW(m_PDF, AppPath() & "\CMap", CUInt(LumasPdfConsts.lcmRecursive Or LumasPdfConsts.lcmDelayed))
        LumasPdf.pdfSetImportFlags(m_PDF, UFlag(LumasPdfConsts.ifImportAll Or LumasPdfConsts.ifImportAsPage))

        Dim inFile As String = AppPath() & "\..\..\..\..\sample_multipage.pdf"
        If LumasPdf.pdfOpenImportFileW(m_PDF, inFile, LumasPdfConsts.ptOpen, "") < 0 Then
            Console.WriteLine("Input file """ & inFile & """ not found!")
            LumasPdf.pdfDeletePDF(m_PDF)
            Return
        End If
        If LumasPdf.pdfImportPDFFile(m_PDF, 1, 1.0, 1.0) < 0 Then
            LumasPdf.pdfDeletePDF(m_PDF)
            Return
        End If

        LumasPdf.pdfFlattenAnnots(m_PDF, CUInt(LumasPdfConsts.affMarkupAnnots))
        LumasPdf.pdfFlattenForm(m_PDF)

        dBeginTemplate = New TBeginTemplate(AddressOf cbBeginTemplate)
        dEndTemplate = New TEndTemplate(AddressOf cbEndTemplate)
        dMulMatrix = New TMulMatrix(AddressOf cbMulMatrix)
        dRestoreGS = New TRestoreGraphicState(AddressOf cbRestoreGraphicState)
        dSaveGS = New TSaveGraphicState(AddressOf cbSaveGraphicState)
        dSetCharSpacing = New TSetCharSpacing(AddressOf cbSetCharSpacing)
        dSetFont = New TSetFont(AddressOf cbSetFont)
        dSetTextDrawMode = New TSetTextDrawMode(AddressOf cbSetTextDrawMode)
        dSetTextScale = New TSetTextScale(AddressOf cbSetTextScale)
        dSetWordSpacing = New TSetWordSpacing(AddressOf cbSetWordSpacing)
        dShowTextArrayW = New TShowTextArrayW(AddressOf cbShowTextArrayW)

        Dim stack As New TPDFParseInterface()
        stack.BeginTemplate = Marshal.GetFunctionPointerForDelegate(dBeginTemplate)
        stack.EndTemplate = Marshal.GetFunctionPointerForDelegate(dEndTemplate)
        stack.MulMatrix = Marshal.GetFunctionPointerForDelegate(dMulMatrix)
        stack.RestoreGraphicState = Marshal.GetFunctionPointerForDelegate(dRestoreGS)
        stack.SaveGraphicState = Marshal.GetFunctionPointerForDelegate(dSaveGS)
        stack.SetCharSpacing = Marshal.GetFunctionPointerForDelegate(dSetCharSpacing)
        stack.SetFont = Marshal.GetFunctionPointerForDelegate(dSetFont)
        stack.SetTextDrawMode = Marshal.GetFunctionPointerForDelegate(dSetTextDrawMode)
        stack.SetTextScale = Marshal.GetFunctionPointerForDelegate(dSetTextScale)
        stack.SetWordSpacing = Marshal.GetFunctionPointerForDelegate(dSetWordSpacing)
        stack.ShowTextArrayW = Marshal.GetFunctionPointerForDelegate(dShowTextArrayW)

        For i As Integer = 1 To LumasPdf.pdfGetPageCount(m_PDF)
            LumasPdf.pdfEditPage(m_PDF, i)
            DoInit()
            DoWritePageIdentifier(i)
            LumasPdf.pdfParseContent(m_PDF, IntPtr.Zero, stack, LumasPdfConsts.pfNone)
            LumasPdf.pdfEndPage(m_PDF)
        Next

        Dim outFile As String = AppPath() & "\out.txt"
        Using fs As New FileStream(outFile, FileMode.Create, FileAccess.Write)
            Dim bom() As Byte = {255, 254}
            fs.Write(bom, 0, 2)
            Dim data() As Byte = Encoding.Unicode.GetBytes(m_sb.ToString())
            fs.Write(data, 0, data.Length)
        End Using

        Console.WriteLine("Text successfully extracted to " & outFile)
        LumasPdf.pdfDeletePDF(m_PDF)
    End Sub
End Module

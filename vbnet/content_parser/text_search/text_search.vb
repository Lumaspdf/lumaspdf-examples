' text_search -- VB.NET port of examples\Vb6\content_parser\text_search
' Imports dynapdf_help.pdf, searches for "PDF" via pdfParseContent + a flattened
' CTextSearch state machine, and draws yellow multiply-blend rectangles over each
' match. Output out.pdf. The div-by-zero guard in IsPointOnLine is kept, and the
' short-circuit (OrElse) that skips IsPointOnLine on a direction mismatch is used.
Imports System
Imports System.Text
Imports System.Collections.Generic
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module modTextSearch
    Private Const tfNotInitialized As Integer = 5
    Private Const MAX_LINE_ERROR As Double = 4.0

    <DllImport("LumasPdf.dll", EntryPoint:="fntTranslateRawCode", CallingConvention:=CallingConvention.StdCall)>
    Private Function fntTranslateRawCodeP(ByVal IFont As IntPtr, ByVal Text As IntPtr, ByVal Len_ As UInteger, ByRef Width_ As Double, ByVal OutText As IntPtr, ByRef OutLen As Integer, ByRef Decoded As Integer, ByVal CharSpacing As Single, ByVal WordSpacing As Single, ByVal TextScale As Single) As UInteger
    End Function

    Private Structure GStateT
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
    Private m_ActiveFont As IntPtr
    Private m_CharSpacing As Single
    Private m_FontSize As Single
    Private m_FontType As Integer
    Private m_Matrix As TCTM
    Private m_SpaceWidth As Single
    Private m_TextDrawMode As Integer
    Private m_TextScale As Single
    Private m_WordSpacing As Single

    Private m_Stack As New List(Of GStateT)

    Private m_EndX1 As Double, m_EndY1 As Double, m_EndX4 As Double, m_EndY4 As Double
    Private m_HavePos As Boolean
    Private m_LastTextDir As Integer
    Private m_LastTextInfX As Double, m_LastTextInfY As Double
    Private m_OutBuf As IntPtr                 ' 64 bytes (32 WideChars)
    Private m_SearchChars() As Integer
    Private m_SearchTextLen As Integer
    Private m_SearchPos As Integer
    Private m_SelCount As Integer
    Private m_x1 As Double, m_y1 As Double, m_x4 As Double, m_y4 As Double

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
    Private dShowTextArrayA As TShowTextArrayA
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

    ' ---------------- matrix / geometry -----------------
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

    ' ---------------- search string handling -----------------
    Private Sub SetSearchText(ByVal Txt As String)
        m_SearchTextLen = Txt.Length
        If m_SearchTextLen > 0 Then
            ReDim m_SearchChars(m_SearchTextLen - 1)
            For i As Integer = 0 To m_SearchTextLen - 1
                m_SearchChars(i) = AscW(Txt(i))
            Next
        End If
        m_SearchPos = 0
    End Sub

    Private Function SPCode() As Integer
        If m_SearchPos >= m_SearchTextLen Then
            Return 0
        Else
            Return m_SearchChars(m_SearchPos)
        End If
    End Function

    Private Sub Reset_()
        m_HavePos = False
        m_SearchPos = 0
    End Sub

    Private Function Compare(ByVal TextPtr As IntPtr, ByVal Len_ As Integer) As Boolean
        Dim p As Long = TextPtr.ToInt64()
        Dim endPtr As Long = p + Len_ * 2
        Do While p < endPtr
            Dim wc As Integer = Marshal.ReadInt16(New IntPtr(p)) And &HFFFF
            If SPCode() <> wc Then
                m_HavePos = False
                m_SearchPos = 0
                Return False
            End If
            p = p + 2
            m_SearchPos = m_SearchPos + 1
            If SPCode() = 0 Then
                m_SearchPos = 0
                Return (p = endPtr)
            End If
        Loop
        Return True
    End Function

    ' ---------------- graphics-state stack -----------------
    Private Function SaveGState() As Integer
        Dim g As GStateT
        g.ActiveFont = m_ActiveFont : g.CharSpacing = m_CharSpacing : g.FontSize = m_FontSize
        g.FontType = m_FontType : g.Matrix = m_Matrix : g.SpaceWidth = m_SpaceWidth
        g.TextDrawMode = m_TextDrawMode : g.TextScale = m_TextScale : g.WordSpacing = m_WordSpacing
        m_Stack.Add(g)
        Return 0
    End Function

    Private Function RestoreGState() As Boolean
        If m_Stack.Count > 0 Then
            Dim g As GStateT = m_Stack(m_Stack.Count - 1)
            m_Stack.RemoveAt(m_Stack.Count - 1)
            m_ActiveFont = g.ActiveFont : m_CharSpacing = g.CharSpacing : m_FontSize = g.FontSize
            m_FontType = g.FontType : m_Matrix = g.Matrix : m_SpaceWidth = g.SpaceWidth
            m_TextDrawMode = g.TextDrawMode : m_TextScale = g.TextScale : m_WordSpacing = g.WordSpacing
            Return True
        End If
        Return False
    End Function

    ' ---------------- rectangle drawing -----------------
    Private Sub SetStartCoord(ByVal Matrix As TCTM, ByVal x As Double)
        m_x1 = x : m_y1 = 0.0
        m_x4 = x : m_y4 = m_FontSize
        Transform(Matrix, m_x1, m_y1)
        Transform(Matrix, m_x4, m_y4)
        m_HavePos = True
    End Sub

    Private Function DrawRectEx(ByVal x2 As Double, ByVal y2 As Double, ByVal x3 As Double, ByVal y3 As Double) As Boolean
        LumasPdf.pdfMoveTo(m_PDF, m_x1, m_y1)
        LumasPdf.pdfLineTo(m_PDF, x2, y2)
        LumasPdf.pdfLineTo(m_PDF, x3, y3)
        LumasPdf.pdfLineTo(m_PDF, m_x4, m_y4)
        m_HavePos = False
        m_SelCount = m_SelCount + 1
        Return LumasPdf.pdfClosePath(m_PDF, TPathFillMode.fmFill)
    End Function

    Private Function DrawRect(ByVal Matrix As TCTM, ByVal EndX As Double) As Boolean
        Dim x2 As Double = EndX, y2 As Double = 0.0
        Dim x3 As Double = EndX, y3 As Double = m_FontSize
        Transform(Matrix, x2, y2)
        Transform(Matrix, x3, y3)
        Return DrawRectEx(x2, y2, x3, y3)
    End Function

    ' ---------------- init / reset -----------------
    Private Sub InitGState()
        Do While RestoreGState()
        Loop
        m_ActiveFont = IntPtr.Zero
        m_CharSpacing = 0.0F
        m_FontSize = 1.0F
        m_Matrix.a = 1.0 : m_Matrix.b = 0.0 : m_Matrix.c = 0.0
        m_Matrix.d = 1.0 : m_Matrix.x = 0.0 : m_Matrix.y = 0.0
        m_SpaceWidth = 0.0F
        m_TextDrawMode = CInt(TDrawMode.dmNormal)
        m_TextScale = 100.0F
        m_WordSpacing = 0.0F
        m_LastTextDir = tfNotInitialized
        m_LastTextInfX = 0.0 : m_LastTextInfY = 0.0
    End Sub

    Private Sub TS_Create()
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
        m_Stack.Clear()
    End Sub

    Private Sub TS_Init()
        InitGState()
        Reset_()
        m_SelCount = 0
    End Sub

    ' ---------------- text matching core -----------------
    Private Function MarkSubString(ByRef x As Double, ByVal Matrix As TCTM, ByVal SourcePtr As IntPtr) As Boolean
        Dim srec As TTextRecordA = CType(Marshal.PtrToStructure(SourcePtr, GetType(TTextRecordA)), TTextRecordA)
        Dim maxLen As Integer = srec.Length
        Dim srcPtr As Long = srec.Text.ToInt64()
        Dim spaceWidth2 As Single = -m_SpaceWidth * 6.0F

        If srec.Advance < -m_SpaceWidth Then
            If (srec.Advance > spaceWidth2) AndAlso (SPCode() = 32) Then
                If Not m_HavePos Then
                    SetStartCoord(Matrix, x)
                    m_SearchPos = m_SearchPos + 1
                    If SPCode() = 0 Then
                        If Not DrawRect(Matrix, x - srec.Advance) Then Return False
                        Reset_()
                    End If
                ElseIf SPCode() = 0 Then
                    If Not DrawRect(Matrix, 0.0) Then Return False
                    Reset_()
                Else
                    m_SearchPos = m_SearchPos + 1
                End If
            Else
                Reset_()
            End If
        End If
        x = x - srec.Advance

        Dim i As Integer = 0
        Dim outLen As Integer = 0
        Dim decoded As Integer = 0
        Dim w As Double = 0.0
        Do While i < maxLen
            Dim consumed As UInteger = fntTranslateRawCodeP(m_ActiveFont, New IntPtr(srcPtr + i), CUInt(maxLen - i), w, m_OutBuf, outLen, decoded, m_CharSpacing, m_WordSpacing, m_TextScale)
            If consumed <= 0 Then Exit Do        ' safety: never let i stall
            i = i + CInt(consumed)
            If decoded = 0 Then
                Return True
            End If
            If Compare(m_OutBuf, outLen) Then
                If Not m_HavePos Then
                    SetStartCoord(Matrix, x)
                End If
                x = x + w
                If m_SearchPos = 0 Then
                    If Not DrawRect(Matrix, x - m_CharSpacing) Then Return False
                End If
            Else
                x = x + w
            End If
        Loop
        Return True
    End Function

    Private Function MarkText(ByVal Matrix As TCTM, ByVal SourcePtr As IntPtr, ByVal Count As Integer, ByVal Width_ As Double) As Integer
        Dim x As Double, x1 As Double = 0.0, x2 As Double = 0.0
        Dim y1 As Double = 0.0, y2 As Double = m_FontSize
        Dim m As TCTM = MulMatrix(m_Matrix, Matrix)
        Transform(m, x1, y1)
        Transform(m, x2, y2)
        Dim textDir As Integer
        If y1 = y2 Then
            textDir = (If(x1 > x2, 1, 0) + 1) * 2
        Else
            textDir = If(y1 > y2, 1, 0)
        End If

        Dim wrongLine As Boolean = False
        If textDir <> m_LastTextDir Then
            wrongLine = True
        ElseIf Not IsPointOnLine(x1, y1, m_EndX1, m_EndY1, m_LastTextInfX, m_LastTextInfY) Then
            wrongLine = True
        End If
        If wrongLine Then
            m_LastTextInfX = 1000000.0
            m_LastTextInfY = 0.0
            Transform(m, m_LastTextInfX, m_LastTextInfY)
            Reset_()
        Else
            Dim x3 As Double = m_SpaceWidth, y3 As Double = 0.0
            Transform(m, x3, y3)
            Dim spaceWidth As Double = CalcDistance(x1, y1, x3, y3)
            Dim distance As Double = CalcDistance(m_EndX1, m_EndY1, x1, y1)
            If distance > spaceWidth Then
                If (distance < spaceWidth * 6.0) AndAlso (SPCode() = 32) Then
                    If Not m_HavePos Then
                        m_HavePos = True
                        m_SearchPos = m_SearchPos + 1
                        If SPCode() = 0 Then
                            m_x1 = m_EndX1 : m_y1 = m_EndY1
                            m_x4 = m_EndX4 : m_y4 = m_EndY4
                            If Not DrawRectEx(x1, y1, x2, y2) Then Return -1
                            Reset_()
                        End If
                    ElseIf SPCode() = 32 Then
                        If Not DrawRectEx(x1, y1, x2, y2) Then Return -1
                        Reset_()
                    Else
                        m_SearchPos = m_SearchPos + 1
                    End If
                Else
                    Reset_()
                End If
            End If
        End If

        x = 0.0
        Dim recPtr As Long = SourcePtr.ToInt64()
        Dim recSize As Integer = Marshal.SizeOf(GetType(TTextRecordA))
        For i As Integer = 0 To Count - 1
            If Not MarkSubString(x, m, New IntPtr(recPtr)) Then Return -1
            recPtr = recPtr + recSize
        Next
        m_LastTextDir = textDir
        m_EndX1 = Width_ : m_EndY1 = 0.0
        m_EndX4 = 0.0 : m_EndY4 = m_FontSize
        Transform(m, m_EndX1, m_EndY1)
        Transform(m, m_EndX4, m_EndY4)
        Return 0
    End Function

    Private Function BeginTemplate(ByVal MatrixPtr As IntPtr) As Integer
        If SaveGState() < 0 Then Return -1
        If MatrixPtr <> IntPtr.Zero Then
            Dim mtx As TCTM = CType(Marshal.PtrToStructure(MatrixPtr, GetType(TCTM)), TCTM)
            m_Matrix = MulMatrix(m_Matrix, mtx)
        End If
        Return 0
    End Function

    Private Sub TS_SetFont(ByVal IFont As IntPtr, ByVal FontType As Integer, ByVal FontSize As Double)
        m_ActiveFont = IFont
        m_FontSize = CSng(FontSize)
        m_FontType = FontType
        m_SpaceWidth = CSng(LumasPdf.fntGetSpaceWidth(IFont, FontSize) * 0.5)
    End Sub

    ' ---------------- callbacks -----------------
    Public Function cbBeginTemplate(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByVal Handle As Integer, ByRef BBox As TPDFRect, ByVal Matrix As IntPtr) As Integer
        Return BeginTemplate(Matrix)
    End Function

    Public Sub cbEndTemplate(ByVal Data As IntPtr)
        RestoreGState()
    End Sub

    Public Sub cbMulMatrix(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByRef Matrix As TCTM)
        m_Matrix = MulMatrix(m_Matrix, Matrix)
    End Sub

    Public Function cbRestoreGraphicState(ByVal Data As IntPtr) As Integer
        RestoreGState()
        Return 0
    End Function

    Public Function cbSaveGraphicState(ByVal Data As IntPtr) As Integer
        Return SaveGState()
    End Function

    Public Sub cbSetCharSpacing(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByVal Value As Double)
        m_CharSpacing = CSng(Value)
    End Sub

    Public Sub cbSetFont(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByVal FontType As TFontType, ByVal Embedded As Boolean, ByVal FontName As String, ByVal Style As Integer, ByVal FontSize As Double, ByVal Font As IntPtr)
        TS_SetFont(Font, CInt(FontType), FontSize)
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

    Public Function cbShowTextArrayA(ByVal Data As IntPtr, ByVal Obj As IntPtr, ByRef Matrix As TCTM, ByVal Source As IntPtr, ByVal Count As UInteger, ByVal Width As Double) As Integer
        Return MarkText(Matrix, Source, CInt(Count), Width)
    End Function

    Sub Main()
        Dim selCount As Integer = 0
        TS_Create()
        m_OutBuf = Marshal.AllocHGlobal(64)

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
        dShowTextArrayA = New TShowTextArrayA(AddressOf cbShowTextArrayA)

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
        stack.ShowTextArrayA = Marshal.GetFunctionPointerForDelegate(dShowTextArrayA)

        m_PDF = LumasPdf.pdfNewPDF()
        ErrDel = New TErrorProc(AddressOf ErrProc)
        LumasPdf.pdfSetOnErrorProc(m_PDF, IntPtr.Zero, ErrDel)
        LumasPdf.pdfCreateNewPDFW(m_PDF, "")

        LumasPdf.pdfSetCMapDirW(m_PDF, AppPath() & "\CMap", CUInt(LumasPdfConsts.lcmRecursive Or LumasPdfConsts.lcmDelayed))
        LumasPdf.pdfSetImportFlags(m_PDF, UFlag(LumasPdfConsts.ifImportAll Or LumasPdfConsts.ifImportAsPage))

        Dim inFile As String = AppPath() & "\..\..\..\..\dynapdf_help.pdf"
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

        SetSearchText("PDF")

        Dim g As TPDFExtGState
        LumasPdf.pdfInitExtGState(g)
        g.BlendMode = TBlendMode.bmMultiply
        Dim gs As Integer = LumasPdf.pdfCreateExtGState(m_PDF, g)

        For i As Integer = 1 To LumasPdf.pdfGetPageCount(m_PDF)
            LumasPdf.pdfEditPage(m_PDF, i)
            LumasPdf.pdfSetExtGState(m_PDF, CUInt(gs))
            LumasPdf.pdfSetFillColor(m_PDF, CUInt(255) Or (CUInt(255) << 8))   ' RGB(255,255,0)
            TS_Init()
            LumasPdf.pdfParseContent(m_PDF, IntPtr.Zero, stack, LumasPdfConsts.pfNone)
            LumasPdf.pdfEndPage(m_PDF)
            If m_SelCount > 0 Then
                selCount = selCount + m_SelCount
                Console.WriteLine("Found string on Page: " & i & " " & m_SelCount & " times!")
            End If
        Next

        Dim outFile As String = AppPath() & "\out.pdf"
        If LumasPdf.pdfHaveOpenDoc(m_PDF) <> 0 Then
            If LumasPdf.pdfOpenOutputFileW(m_PDF, outFile) = 0 Then
                LumasPdf.pdfDeletePDF(m_PDF)
                Return
            End If
        End If
        If LumasPdf.pdfCloseFile(m_PDF) <> 0 Then
            Console.WriteLine("PDF file """ & outFile & """ successfully created!")
        End If
        Console.WriteLine(vbLf & "Found string in the file " & selCount & " times!")
        Marshal.FreeHGlobal(m_OutBuf)
        LumasPdf.pdfDeletePDF(m_PDF)
    End Sub
End Module

' text_coordinates -- VB.NET port of examples\Vb6\content_parser\text_coordinates\text_coordinates.bas
Imports System
Imports System.IO
Imports System.Runtime.InteropServices
Imports LumasPdfSdk

Module TextCoordinates
    ' Raw-pointer overload of fntGetTextWidth (the wrapper's takes Text As String).
    <DllImport("LumasPdf.dll", EntryPoint:="fntGetTextWidth", CallingConvention:=CallingConvention.StdCall, ExactSpelling:=True)>
    Private Function fntGetTextWidthP(ByVal IFont As IntPtr, ByVal Text As IntPtr, ByVal Len_ As UInteger, ByVal CharSpacing As Single, ByVal WordSpacing As Single, ByVal TextScale As Single) As Double
    End Function

    Private Const clRed As UInteger = &HFFUI
    Private Const clBlue As UInteger = &HFF0000UI

    ' Flattened TGState.
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
    Private m_Count As Integer
    Private m_GState As TGState

    ' CStack state.
    Private m_Items As TGState()
    Private m_StackCap As Integer
    Private m_StackCount As Integer

    Private szTRW As Integer = Marshal.SizeOf(GetType(TTextRecordW))
    Private szTRA As Integer = Marshal.SizeOf(GetType(TTextRecordA))

    ' Keep delegate references alive.
    Private errDel As TErrorProc
    Private dBeginTemplate As TBeginTemplate
    Private dEndTemplate As TEndTemplate
    Private dMulMatrix As TMulMatrix
    Private dRestore As TRestoreGraphicState
    Private dSave As TSaveGraphicState
    Private dSetCharSpacing As TSetCharSpacing
    Private dSetFont As TSetFont
    Private dSetTextDrawMode As TSetTextDrawMode
    Private dSetTextScale As TSetTextScale
    Private dSetWordSpacing As TSetWordSpacing
    Private dShowTextArrayW As TShowTextArrayW

    Public Function ErrProc(ByVal Data As IntPtr, ByVal ErrCode As Integer, ByVal ErrMessage As String, ByVal ErrType As Integer) As Integer
        Console.WriteLine(ErrMessage)
        Return 0
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

    Private Sub Transform(ByRef m As TCTM, ByRef x As Double, ByRef y As Double)
        Dim tx As Double = x
        x = tx * m.a + y * m.c + m.x
        y = tx * m.b + y * m.d + m.y
    End Sub

    ' ------------------------- CStack -------------------------
    Private Function RestoreGState() As Boolean
        If m_StackCount > 0 Then
            m_StackCount -= 1
            m_GState = m_Items(m_StackCount)
            Return True
        End If
        Return False
    End Function

    Private Function SaveGState() As Integer
        If m_StackCount = m_StackCap Then
            m_StackCap += 28
            ReDim Preserve m_Items(m_StackCap - 1)
        End If
        m_Items(m_StackCount) = m_GState
        m_StackCount += 1
        Return 0
    End Function

    Private Sub ResetGState()
        m_GState.ActiveFont = IntPtr.Zero
        m_GState.CharSpacing = 0.0F
        m_GState.FontSize = 1.0F
        m_GState.FontType = TFontType.ftType1
        m_GState.Matrix.a = 1.0 : m_GState.Matrix.b = 0.0
        m_GState.Matrix.c = 0.0 : m_GState.Matrix.d = 1.0
        m_GState.Matrix.x = 0.0 : m_GState.Matrix.y = 0.0
        m_GState.TextDrawMode = TDrawMode.dmNormal
        m_GState.TextScale = 100.0F
        m_GState.WordSpacing = 0.0F
    End Sub

    Private Sub TCInit()
        Do While RestoreGState()
        Loop
        m_Count = 0
        ResetGState()
    End Sub

    Private Function BeginTemplateImpl(ByVal MatrixPtr As IntPtr) As Integer
        If SaveGState() < 0 Then Return -1
        If MatrixPtr <> IntPtr.Zero Then
            Dim tmp As TCTM = CType(Marshal.PtrToStructure(MatrixPtr, GetType(TCTM)), TCTM)
            m_GState.Matrix = MulMatrix(m_GState.Matrix, tmp)
        End If
        Return 0
    End Function

    Private Sub SetFontImpl(ByVal IFont As IntPtr, ByVal FontType As Integer, ByVal FontSize As Double)
        m_GState.ActiveFont = IFont
        m_GState.FontSize = CSng(FontSize)
        m_GState.FontType = FontType
        m_GState.SpaceWidth = CSng(LumasPdf.fntGetSpaceWidth(IFont, FontSize))
    End Sub

    Private Function ReadRecW(ByVal p As IntPtr) As TTextRecordW
        Return CType(Marshal.PtrToStructure(p, GetType(TTextRecordW)), TTextRecordW)
    End Function

    Private Function ReadRecA(ByVal p As IntPtr) As TTextRecordA
        Return CType(Marshal.PtrToStructure(p, GetType(TTextRecordA)), TTextRecordA)
    End Function

    Private Sub StrokeSeg(ByVal x1 As Double, ByVal y1 As Double, ByVal x2 As Double, ByVal y2 As Double)
        LumasPdf.pdfMoveTo(m_PDF, x1, y1)
        LumasPdf.pdfLineTo(m_PDF, x2, y2)
        If (m_Count And 1) <> 0 Then
            LumasPdf.pdfSetStrokeColor(m_PDF, clRed)
        Else
            LumasPdf.pdfSetStrokeColor(m_PDF, clBlue)
        End If
    End Sub

    ' CTextCoordinates.MarkText
    Private Function MarkText(ByRef Matrix As TCTM, ByVal Source As IntPtr, ByVal Kerning As IntPtr, ByVal Count As Integer, ByVal AWidth As Double, ByVal Decoded As Boolean) As Integer
        Dim i As Integer, j As Integer, last As Integer
        Dim x1 As Double, x2 As Double, y1 As Double, y2 As Double, textWidth As Double
        Dim m As TCTM

        If Not Decoded Then Return 0

        x1 = 0.0 : y1 = 0.0
        m = MulMatrix(m_GState.Matrix, Matrix)
        Transform(m, x1, y1)
        x2 = x1 : y2 = y1

        textWidth = 0.0
        If m_GState.FontType = TFontType.ftType0 Then
            ' Word spacing must be ignored if a CID font is selected!
            For i = 0 To Count - 1
                Dim krec As TTextRecordW = ReadRecW(IntPtr.Add(Kerning, i * szTRW))
                If krec.Advance <> 0.0F Then
                    textWidth -= krec.Advance
                    x1 = textWidth : y1 = 0.0
                    Transform(m, x1, y1)
                End If
                textWidth += krec.Width
                x2 = textWidth : y2 = 0.0
                Transform(m, x2, y2)
                StrokeSeg(x1, y1, x2, y2)
                If Not LumasPdf.pdfStrokePath(m_PDF) Then Return -1
                x1 = x2 : y1 = y2
            Next
        Else
            For i = 0 To Count - 1
                Dim srec As TTextRecordA = ReadRecA(IntPtr.Add(Source, i * szTRA))
                j = 0 : last = 0
                If srec.Advance <> 0.0F Then
                    textWidth -= srec.Advance
                    x1 = textWidth : y1 = 0.0
                    Transform(m, x1, y1)
                End If
                Dim rlen As Integer = srec.Length
                If srec.Text = IntPtr.Zero Then rlen = 0
                Dim srcBytes() As Byte = Nothing
                If rlen > 0 Then
                    ReDim srcBytes(rlen - 1)
                    Marshal.Copy(srec.Text, srcBytes, 0, rlen)
                End If
                Do While j < rlen
                    If srcBytes(j) <> 32 Then
                        j += 1
                    Else
                        If j > last Then
                            textWidth += fntGetTextWidthP(m_GState.ActiveFont, IntPtr.Add(srec.Text, last), CUInt(j - last), m_GState.CharSpacing, m_GState.WordSpacing, m_GState.TextScale)
                            x2 = textWidth : y2 = 0.0
                            Transform(m, x2, y2)
                            StrokeSeg(x1, y1, x2, y2)
                            If Not LumasPdf.pdfStrokePath(m_PDF) Then Return -1
                        End If
                        last = j
                        j += 1
                        Do While j < rlen
                            If srcBytes(j) = 32 Then
                                j += 1
                            Else
                                Exit Do
                            End If
                        Loop
                        textWidth += fntGetTextWidthP(m_GState.ActiveFont, IntPtr.Add(srec.Text, last), CUInt(j - last), m_GState.CharSpacing, m_GState.WordSpacing, m_GState.TextScale)
                        last = j
                        x1 = textWidth : y1 = 0.0
                        Transform(m, x1, y1)
                    End If
                Loop
                If j > last Then
                    textWidth += fntGetTextWidthP(m_GState.ActiveFont, IntPtr.Add(srec.Text, last), CUInt(j - last), m_GState.CharSpacing, m_GState.WordSpacing, m_GState.TextScale)
                    x2 = textWidth : y2 = 0.0
                    Transform(m, x2, y2)
                    StrokeSeg(x1, y1, x2, y2)
                    If Not LumasPdf.pdfStrokePath(m_PDF) Then Return -1
                End If
                x1 = x2 : y1 = y2
            Next
        End If
        m_Count += 1
        Return 0
    End Function

    ' ------------------------- parse* callback thunks -------------------------
    Public Function parseBeginTemplate(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByVal Handle As Integer, ByRef BBox As TPDFRect, ByVal Matrix As IntPtr) As Integer
        Return BeginTemplateImpl(Matrix)
    End Function

    Public Sub parseEndTemplate(ByVal Data As IntPtr)
        RestoreGState()
    End Sub

    Public Sub parseMulMatrix(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByRef Matrix As TCTM)
        m_GState.Matrix = MulMatrix(m_GState.Matrix, Matrix)
    End Sub

    Public Function parseRestoreGraphicState(ByVal Data As IntPtr) As Integer
        RestoreGState()
        Return 0
    End Function

    Public Function parseSaveGraphicState(ByVal Data As IntPtr) As Integer
        SaveGState()
        Return 0
    End Function

    Public Sub parseSetCharSpacing(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByVal Value As Double)
        m_GState.CharSpacing = CSng(Value)
    End Sub

    Public Sub parseSetFont(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByVal FontType As TFontType, ByVal Embedded As Boolean, ByVal FontName As String, ByVal Style As Integer, ByVal FontSize As Double, ByVal Font As IntPtr)
        SetFontImpl(Font, FontType, FontSize)
    End Sub

    Public Sub parseSetTextDrawMode(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByVal Mode As TDrawMode)
        m_GState.TextDrawMode = Mode
    End Sub

    Public Sub parseSetTextScale(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByVal Value As Double)
        m_GState.TextScale = CSng(Value)
    End Sub

    Public Sub parseSetWordSpacing(ByVal Data As IntPtr, ByVal PDFObject As IntPtr, ByVal Value As Double)
        m_GState.WordSpacing = CSng(Value)
    End Sub

    Public Function parseShowTextArrayW(ByVal Data As IntPtr, ByVal Source As IntPtr, ByRef Matrix As TCTM, ByVal Kerning As IntPtr, ByVal Count As UInteger, ByVal Width As Double, ByVal Decoded As Boolean) As Integer
        Return MarkText(Matrix, Source, Kerning, CInt(Count), Width, Decoded)
    End Function

    ' ------------------------- main -------------------------
    Sub Main()
        Dim stack As New TPDFParseInterface()
        dBeginTemplate = New TBeginTemplate(AddressOf parseBeginTemplate)
        dEndTemplate = New TEndTemplate(AddressOf parseEndTemplate)
        dMulMatrix = New TMulMatrix(AddressOf parseMulMatrix)
        dRestore = New TRestoreGraphicState(AddressOf parseRestoreGraphicState)
        dSave = New TSaveGraphicState(AddressOf parseSaveGraphicState)
        dSetCharSpacing = New TSetCharSpacing(AddressOf parseSetCharSpacing)
        dSetFont = New TSetFont(AddressOf parseSetFont)
        dSetTextDrawMode = New TSetTextDrawMode(AddressOf parseSetTextDrawMode)
        dSetTextScale = New TSetTextScale(AddressOf parseSetTextScale)
        dSetWordSpacing = New TSetWordSpacing(AddressOf parseSetWordSpacing)
        dShowTextArrayW = New TShowTextArrayW(AddressOf parseShowTextArrayW)

        stack.BeginTemplate = Marshal.GetFunctionPointerForDelegate(dBeginTemplate)
        stack.EndTemplate = Marshal.GetFunctionPointerForDelegate(dEndTemplate)
        stack.MulMatrix = Marshal.GetFunctionPointerForDelegate(dMulMatrix)
        stack.RestoreGraphicState = Marshal.GetFunctionPointerForDelegate(dRestore)
        stack.SaveGraphicState = Marshal.GetFunctionPointerForDelegate(dSave)
        stack.SetCharSpacing = Marshal.GetFunctionPointerForDelegate(dSetCharSpacing)
        stack.SetFont = Marshal.GetFunctionPointerForDelegate(dSetFont)
        stack.SetTextDrawMode = Marshal.GetFunctionPointerForDelegate(dSetTextDrawMode)
        stack.SetTextScale = Marshal.GetFunctionPointerForDelegate(dSetTextScale)
        stack.SetWordSpacing = Marshal.GetFunctionPointerForDelegate(dSetWordSpacing)
        stack.ShowTextArrayW = Marshal.GetFunctionPointerForDelegate(dShowTextArrayW)

        Dim pdf As IntPtr = LumasPdf.pdfNewPDF()
        m_PDF = pdf
        m_StackCount = 0
        m_StackCap = 0
        m_Count = 0
        ResetGState()

        errDel = New TErrorProc(AddressOf ErrProc)
        LumasPdf.pdfSetOnErrorProc(pdf, IntPtr.Zero, errDel)
        LumasPdf.pdfCreateNewPDFW(pdf, "")

        Dim cmapDir As String = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "CMap")
        LumasPdf.pdfSetCMapDirW(pdf, cmapDir, CUInt(LumasPdfConsts.lcmRecursive Or LumasPdfConsts.lcmDelayed))

        LumasPdf.pdfSetImportFlags(pdf, &H0FFFFFFEUI Or &H80000000UI)

        Dim inFile As String = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..\..\..\..\dynapdf_help.pdf")
        If LumasPdf.pdfOpenImportFileW(pdf, inFile, LumasPdfConsts.ptOpen, "") < 0 Then
            Console.WriteLine("Input file """ & inFile & """ not found!")
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If
        If LumasPdf.pdfImportPDFFile(pdf, 1, 1.0, 1.0) < 0 Then
            LumasPdf.pdfDeletePDF(pdf)
            Return
        End If

        LumasPdf.pdfFlattenAnnots(pdf, LumasPdfConsts.affMarkupAnnots)
        LumasPdf.pdfFlattenForm(pdf)

        For i As Integer = 1 To LumasPdf.pdfGetPageCount(pdf)
            LumasPdf.pdfEditPage(pdf, i)
            LumasPdf.pdfSetLineWidth(pdf, 0.5)
            TCInit()
            LumasPdf.pdfParseContent(pdf, IntPtr.Zero, stack, LumasPdfConsts.pfNone)
            LumasPdf.pdfEndPage(pdf)
        Next

        Dim outFile As String = ""
        If LumasPdf.pdfHaveOpenDoc(pdf) <> 0 Then
            outFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "out.pdf")
            If LumasPdf.pdfOpenOutputFileW(pdf, outFile) = 0 Then
                LumasPdf.pdfDeletePDF(pdf)
                Return
            End If
        End If
        If LumasPdf.pdfCloseFile(pdf) <> 0 Then
            Console.WriteLine("PDF file """ & outFile & """ successfully created!")
        End If
        LumasPdf.pdfDeletePDF(pdf)
    End Sub
End Module

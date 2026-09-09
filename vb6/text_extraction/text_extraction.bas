Attribute VB_Name = "modTextExtraction"
Option Explicit
' ============================================================================
'  text_extraction -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp).
'  Reconstructs page text from GetPageText()/TPDFStack: it walks the stack's
'  Kerning array (TTextRecordW records with raw PWideChar Text pointers),
'  multiplies text/ctm matrices, and copies the wchar runs out of engine memory.
'
'  The AX server marshals the TPDFStack record as a byte-array OleVariant (exactly
'  SizeOf(TPDFStack) bytes) through InitStack/GetPageText; VB6 (unlike the skipped
'  late-bound VBScript port) can pack/unpack that array via CopyMemory and then
'  dereference the in-process pointers it carries. Output is out.txt (UTF-16LE).
' pdf.RaiseExceptions = True
' ============================================================================

Private Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (ByRef Dest As Any, ByRef Src As Any, ByVal Length As Long)

' ---- local record layouts (mirror the engine's ApiTypes; not TLB enums) -----
Private Type TCTM
    a As Double
    b As Double
    c As Double
    d As Double
    x As Double
    y As Double
End Type

Private Type TTextRecordW
    Advance As Single
    Text As Long
    Length As Long
    Width_ As Single
End Type

Private Type TPDFStack
    ctm As TCTM
    tm As TCTM
    x As Double
    y As Double
    FontSize As Double
    CharSP As Double
    WordSP As Double
    HScale As Double
    TextRise As Double
    Leading As Double
    LineWidth As Double
    DrawMode As Long
    FillCS As Long
    StrokeCS As Long
    FillColor As Long
    StrokeColor As Long
    BaseObject As Long
    CIDFont As Long
    Text As Long
    TextLen As Long
    RawKern As Long
    Kerning As Long
    KerningCount As Long
    TextWidth As Single
    IFont As Long
    Embedded As Long
    SpaceWidth As Single
    ConvColors As Long
    DestSpace As Long
    DeleteKerningAt As Long
    FontFlags As Long
    Reserved1 As Long
    Reserved2 As Long
    Reserved3 As Long
    Reserved4 As Long
    Reserved5 As Long
    Reserved6 As Long
    Reserved7 As Long
    Reserved8 As Long
    Reserved9 As Long
    Reserved10 As Long
    Reserved11 As Long
    ContentPtr As Long
End Type

' TTextDir (not a TLB enum -- define locally)
Private Const tfNotInitialized As Long = 5
Private Const MAX_LINE_ERROR As Double = 4#   ' square of the allowed error (2*2)

' State (was the CPDFToText helper class)
Private m_PDF As CPDF
Private m_File As Integer
Private m_Stack As TPDFStack
Private m_LastTextDir As Long
Private m_LastTextEndX As Double
Private m_LastTextEndY As Double
Private m_LastTextInfX As Double
Private m_LastTextInfY As Double

' CIntList (template handle list)
Private m_Templates() As Long
Private m_TemplCount As Long

' ------------------------- TPDFStack <-> OleVariant byte array -------------------------
Private Function GetPageTextEx() As Boolean
    Dim v As Variant, b() As Byte
    ReDim b(0 To LenB(m_Stack) - 1)
    CopyMemory b(0), m_Stack, LenB(m_Stack)
    v = b
    GetPageTextEx = m_PDF.GetPageText(v)
    b = v
    CopyMemory m_Stack, b(0), LenB(m_Stack)
End Function

Private Function InitStackEx() As Boolean
    Dim v As Variant, b() As Byte
    ReDim b(0 To LenB(m_Stack) - 1)
    CopyMemory b(0), m_Stack, LenB(m_Stack)
    v = b
    InitStackEx = m_PDF.InitStack(v)
    b = v
    CopyMemory m_Stack, b(0), LenB(m_Stack)
End Function

' ------------------------- output helpers -------------------------
Private Sub WriteWStr(ByVal s As String)
    Dim b() As Byte
    If LenB(s) = 0 Then Exit Sub
    b = s                              ' VB strings are UTF-16LE internally
    Put #m_File, , b
End Sub

Private Sub WriteWCharsFromPtr(ByVal Ptr As Long, ByVal WCharCount As Long)
    Dim b() As Byte
    If Ptr = 0 Or WCharCount <= 0 Then Exit Sub
    ReDim b(0 To WCharCount * 2 - 1)
    CopyMemory b(0), ByVal Ptr, WCharCount * 2
    Put #m_File, , b
End Sub

' ------------------------- CIntList -------------------------
Private Sub ListClear()
    m_TemplCount = 0
End Sub

Private Sub ListAdd(ByVal Value As Long)
    If m_TemplCount = 0 Then ReDim m_Templates(0 To 63)
    If m_TemplCount > UBound(m_Templates) Then ReDim Preserve m_Templates(0 To m_TemplCount + 63)
    m_Templates(m_TemplCount) = Value
    m_TemplCount = m_TemplCount + 1
End Sub

Private Function ListFind(ByVal Value As Long) As Long
    Dim i As Long
    For i = 0 To m_TemplCount - 1
        If m_Templates(i) = Value Then
            ListFind = i
            Exit Function
        End If
    Next i
    ListFind = -1
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
    MulMatrix = r
End Function

Private Sub Transform(ByRef m As TCTM, ByRef x As Double, ByRef y As Double)
    Dim tx As Double
    tx = x
    x = tx * m.a + y * m.c + m.x
    y = tx * m.b + y * m.d + m.y
End Sub

Private Function CalcDistance(ByVal x1 As Double, ByVal y1 As Double, ByVal x2 As Double, ByVal y2 As Double) As Double
    Dim dx As Double, dy As Double
    dx = x2 - x1
    dy = y2 - y1
    CalcDistance = Sqr(dx * dx + dy * dy)
End Function

Private Function IsPointOnLine(ByVal x As Double, ByVal y As Double, ByVal x0 As Double, ByVal y0 As Double, ByVal x1 As Double, ByVal y1 As Double) As Boolean
    Dim dx As Double, dy As Double, di As Double
    x = x - x0
    y = y - y0
    dx = x1 - x0
    dy = y1 - y0
    If (dx * dx + dy * dy) = 0# Then
        IsPointOnLine = ((x * x + y * y) < MAX_LINE_ERROR)
        Exit Function
    End If
    di = (x * dx + y * dy) / (dx * dx + dy * dy)
    If di < 0# Then
        di = 0#
    ElseIf di > 1# Then
        di = 1#
    End If
    dx = x - di * dx
    dy = y - di * dy
    di = dx * dx + dy * dy
    IsPointOnLine = (di < MAX_LINE_ERROR)
End Function

' ------------------------- text reconstruction -------------------------
Private Sub AddText()
    Dim i As Long
    Dim x1 As Double, x2 As Double, x3 As Double
    Dim y1 As Double, y2 As Double, y3 As Double
    Dim distance As Double, spaceWidth As Double
    Dim textDir As Long, m As TCTM, spw As Single
    Dim rec As TTextRecordW, base As Long
    Dim wrongLine As Boolean

    x1 = 0#: y1 = 0#
    x2 = 0#: y2 = m_Stack.FontSize
    m = MulMatrix(m_Stack.ctm, m_Stack.tm)
    Transform m, x1, y1                ' Start point of the text record
    Transform m, x2, y2                ' Second point -> text direction
    If y1 = y2 Then
        textDir = (IIf(x1 > x2, 1, 0) + 1) * 2
    Else
        textDir = IIf(y1 > y2, 1, 0)
    End If

    ' Reproduce Delphi's short-circuit OR (VB6's Or does not short-circuit).
    wrongLine = False
    If textDir <> m_LastTextDir Then
        wrongLine = True
    ElseIf Not IsPointOnLine(x1, y1, m_LastTextEndX, m_LastTextEndY, m_LastTextInfX, m_LastTextInfY) Then
        wrongLine = True
    End If
    If wrongLine Then
        m_LastTextInfX = 1000000#
        m_LastTextInfY = 0#
        Transform m, m_LastTextInfX, m_LastTextInfY
        If m_LastTextDir <> tfNotInitialized Then WriteWStr vbCrLf
    Else
        x3 = m_Stack.SpaceWidth
        y3 = 0#
        Transform m, x3, y3
        spaceWidth = CalcDistance(x1, y1, x3, y3)
        distance = CalcDistance(m_LastTextEndX, m_LastTextEndY, x1, y1)
        If distance > spaceWidth Then WriteWStr " "
    End If

    spw = -m_Stack.SpaceWidth * 0.5
    base = m_Stack.Kerning
    For i = 0 To m_Stack.KerningCount - 1
        CopyMemory rec, ByVal base + i * 16, 16   ' sizeof(TTextRecordW) = 16
        If rec.Advance < spw Then WriteWStr " "
        WriteWCharsFromPtr rec.Text, rec.Length
    Next i

    m_LastTextEndX = m_Stack.TextWidth + spw       ' spw is negative
    m_LastTextEndY = 0#
    m_LastTextDir = textDir
    Transform m, m_LastTextEndX, m_LastTextEndY
End Sub

Private Sub ParseText()
    Dim haveMore As Boolean
    haveMore = GetPageTextEx()
    If (Not haveMore) And (m_Stack.TextLen = 0) Then Exit Sub
    AddText
    If haveMore Then
        Do While GetPageTextEx()
            AddText
        Loop
    End If
End Sub

Private Sub ParseTemplates()
    Dim i As Long, j As Long, tmpl As Long, tmplCount As Long, tmplCount2 As Long
    tmplCount = m_PDF.GetTemplCount()
    For i = 0 To tmplCount - 1
        If m_PDF.EditTemplate(i) = False Then Exit Sub
        tmpl = m_PDF.GetTemplHandle()
        If ListFind(tmpl) < 0 Then
            ListAdd tmpl
            If InitStackEx() = False Then Exit Sub
            ParseText
            tmplCount2 = m_PDF.GetTemplCount()
            For j = 0 To tmplCount2 - 1
                ParseTemplates
            Next j
            m_PDF.EndTemplate
        Else
            m_PDF.EndTemplate
        End If
    Next i
End Sub

Private Sub ParsePage()
    ListClear
    If InitStackEx() = False Then
        Debug.Print m_PDF.GetErrorMessage()
        Exit Sub
    End If
    m_LastTextEndX = 0#
    m_LastTextEndY = 0#
    m_LastTextDir = tfNotInitialized
    m_LastTextInfX = 0#
    m_LastTextInfY = 0#
    ParseText
    ParseTemplates
End Sub

Public Sub Main()
    Dim i As Long, outFile As String, inFile As String
    Dim bom(0 To 1) As Byte

    Set m_PDF = New CPDF
' pdf.RaiseExceptions = True
    m_PDF.CreateNewPDFA ""              ' We do not produce a PDF file in this example

    ' External cmaps should always be loaded when extracting text from PDF files.
    m_PDF.SetCMapDirA App.Path & "\CMap", lcmRecursive Or lcmDelayed

    ' Avoid the conversion of pages to templates.
    m_PDF.SetImportFlags ifImportAll Or ifImportAsPage
    inFile = App.Path & "\in.pdf"
    If m_PDF.OpenImportFileA(inFile, ptOpen, "") < 0 Then Exit Sub
    m_PDF.ImportPDFFile 1, 1#, 1#
    m_PDF.CloseImportFile

    ' Flatten markup annotations and form fields so their text can be extracted too.
    m_PDF.FlattenAnnots affMarkupAnnots
    m_PDF.FlattenForm

    outFile = App.Path & "\out.txt"
    m_File = FreeFile
    Open outFile For Binary Access Write As #m_File
    bom(0) = 255: bom(1) = 254         ' UTF-16LE BOM
    Put #m_File, , bom

    ' Note that page numbering starts at 1!
    For i = 1 To m_PDF.GetPageCount()
        m_PDF.EditPage i               ' Open the page
        WriteWStr IIf(i > 1, vbCrLf, "") & "%----------------------- Page " & i & " -----------------------------" & vbCrLf
        ParsePage
        m_PDF.EndPage                  ' Close the page
    Next i
    Close #m_File

    Debug.Print "Text successfully extracted to " & outFile
End Sub

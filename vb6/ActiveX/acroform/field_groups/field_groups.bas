Attribute VB_Name = "modFieldGroups"
Option Explicit
' ============================================================================
'  field_groups -- LumasPdf ActiveX/COM component style (late-bound, no
'  project reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\acroform\field_groups -- same feature: several text fields
'  sharing one value (a field group, built via the Parent handle of the base
'  field), auto-size vs. fixed font size, plus a Reset button.
'
'  Method mapping vs. the CPDF.cls reference (pdf.Xxx -> pdf.Xxx, same names,
'  just late-bound to the registered "LumasPdf.PDF" COM server instead of the
'  native wrapper class):
'    pdf.CreateNewPDF ""      -> pdf.CreateNewPDFW ""
'    pdf.SetFont ...          -> pdf.SetFontW ...
'    pdf.WriteFTextEx ...     -> pdf.WriteFTextExW ...
'    pdf.CreateButtonA ...    -> pdf.CreateButtonA ...   (kept -- explicit A in reference)
'    pdf.SetTextFieldValueA . -> pdf.SetTextFieldValueA . (kept -- explicit A in reference)
'    pdf.OpenOutputFile ...   -> pdf.OpenOutputFileW ...
'  All other calls (CreateTextField, SetFieldColor, SetFieldBorderStyle,
'  CreateResetAction, AddActionToObj, GetPageHeight, GetPageWidth,
'  GetLastTextPosY, ChangeFontSize, SetLeading, SetPageCoords, Append,
'  EndPage, HaveOpenDoc, CloseFile) map 1:1, just with the instance handle
'  dropped.
' ============================================================================

Private Const clLtGray As Long = 12632256   ' VCL clLtGray (= clSilver)

'--- TFStyle (see src\Lumas.Pdf.Types.pas) --------------------------------------
Const FS_REGULAR As Long = &H19000000   ' weight 400 -> same as "no bold/italic"

'--- TTextAlign -------------------------------------------------------------------
Const taLeft As Long = 0
Const taJustify As Long = 3

'--- TCodepage (index 2 = cp1252) -------------------------------------------------
Const CP_1252 As Long = 2

'--- TPageCoord --------------------------------------------------------------------
Const pcTopDown As Long = 1

'--- TFieldColor / TBorderStyle / TPDFColorSpace ------------------------------------
Const fcBackColor As Long = 0
Const bsBevelled As Long = 1
Const csDeviceRGB As Long = 0

'--- TObjType / TObjEvent ------------------------------------------------------------
Const otField As Long = 4
Const oeOnMouseUp As Long = 3

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim act As Long, f As Long
    Dim base As Double, y As Double
    Dim outFile As String
    Dim cr As String

    cr = Chr$(13)

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True           ' turn engine errors into VB6 errors

    pdf.CreateNewPDFW ""

    pdf.SetPageCoords pcTopDown

    pdf.Append
    pdf.SetFontW "Helvetica", FS_REGULAR, 12#, False, CP_1252
    pdf.SetLeading 14#
    pdf.WriteFTextExW 50#, 50#, pdf.GetPageWidth() - 100#, -1#, taJustify, _
        "The six text fields share the same value. Such an array of fields is called a field group. All fields in the group must be of the same type." & cr & cr & _
        "A field group can be created in two different ways: either create two or more fields with the same name or pass the handle of the base field as Parent to the children. " & _
        "The latter way is more efficient since it is not required to search for the parent field when a child will be created." & cr & cr & _
        "Enter some more text into a field to see the difference between auto size and fixed font size."

    ' GetLastTextPosY() returns bottom up coordinates. We must subtract from the page height.
    base = pdf.GetPageHeight() - pdf.GetLastTextPosY() + 20#

    pdf.WriteFTextExW 50#, base, 200#, -1#, taLeft, "Font size <= 1.0 means auto size."

    y = pdf.GetPageHeight() - pdf.GetLastTextPosY() + 10#

    pdf.ChangeFontSize 1#
    f = pdf.CreateTextField("Auto", -1, 0, 0, 50#, y, 200#, 20#)
    pdf.SetTextFieldValueA f, "Some text...", "Some text...", taLeft

    y = y + 30#
    pdf.CreateTextField "", f, 0, 0, 50#, y, 200#, 30#

    y = y + 40#
    pdf.CreateTextField "", f, 0, 0, 50#, y, 200#, 40#

    pdf.ChangeFontSize 12#
    pdf.WriteFTextExW 345#, base, 200#, -1#, taLeft, "The same fields with a fixed font size."

    y = pdf.GetPageHeight() - pdf.GetLastTextPosY() + 10#

    pdf.ChangeFontSize 12#
    pdf.CreateTextField "", f, 0, 0, 345#, y, 200#, 20#

    y = y + 30#
    pdf.ChangeFontSize 24#
    pdf.CreateTextField "", f, 0, 0, 345#, y, 200#, 30#

    y = y + 40#
    pdf.ChangeFontSize 34#
    pdf.CreateTextField "", f, 0, 0, 345#, y, 200#, 40#

    pdf.ChangeFontSize 18#
    f = pdf.CreateButtonA("Reset", "Reset", -1, 222.5, y + 80#, 150#, 25#)
    pdf.SetFieldColor f, fcBackColor, csDeviceRGB, clLtGray
    pdf.SetFieldBorderStyle f, bsBevelled

    act = pdf.CreateResetAction()
    pdf.AddActionToObj otField, oeOnMouseUp, act, f
    pdf.EndPage

    If CBool(pdf.HaveOpenDoc()) Then
        outFile = App.Path & "\out.pdf"
        pdf.OpenOutputFileW outFile
        pdf.CloseFile
        Debug.Print "PDF file """ & outFile & """ successfully created!"
    End If
    Exit Sub

ErrHandler:
    Dim extra As String
    If Not pdf Is Nothing Then extra = vbCrLf & "LumasPdf: " & pdf.LastErrorCode & " " & pdf.LastErrorMessage
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "field_groups (ActiveX)"
End Sub

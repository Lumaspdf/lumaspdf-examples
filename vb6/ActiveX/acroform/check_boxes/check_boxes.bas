Attribute VB_Name = "modCheckBoxes"
Option Explicit
' ============================================================================
'  check_boxes -- LumasPdf ActiveX/COM component style (late-bound, no
'  project reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\acroform\check_boxes -- same feature: normal check boxes,
'  a field group of check boxes sharing one export value (radio-button-like),
'  real radio buttons (round + circle character), the RadioIsUnion flag, and
'  a Reset action button wired to a form field via CreateResetAction /
'  AddActionToObj / AddFieldToFormAction.
'
'  Method mapping vs. the CPDF.cls reference (pdf.Xxx -> pdf.Xxx, same names,
'  just late-bound to the registered "LumasPdf.PDF" COM server instead of the
'  native wrapper class):
'    pdf.CreateNewPDF ""     -> pdf.CreateNewPDFW ""
'    pdf.SetFont ...         -> pdf.SetFontW ...
'    pdf.WriteText ...       -> pdf.WriteTextW ...
'    pdf.WriteFTextEx ...    -> pdf.WriteFTextExW ...
'    pdf.CreateButtonA ...   -> pdf.CreateButtonA ...   (kept -- explicit A in reference)
'    pdf.OpenOutputFile ...  -> pdf.OpenOutputFileW ...
'  All other calls (CreateCheckBox, SetCheckBoxDefState, SetCheckBoxChar,
'  CreateRadioButton, SetFieldColor, SetFieldBorderStyle, CreateResetAction,
'  AddActionToObj, AddFieldToFormAction, SetFieldFlags, GetPageHeight,
'  GetLastTextPosY, ChangeFontSize, SetPageCoords, Append, EndPage,
'  HaveOpenDoc, CloseFile) map 1:1, just with the instance handle dropped.
' ============================================================================

Private Const clLtGray As Long = 12632256   ' VCL clLtGray (= clSilver)

'--- TFStyle (see src\Lumas.Pdf.Types.pas) --------------------------------------
Const FS_REGULAR As Long = &H19000000   ' weight 400 -> same as "no bold/italic"

'--- TTextAlign -------------------------------------------------------------------
Const taLeft As Long = 0

'--- TCodepage (index 2 = cp1252) -------------------------------------------------
Const CP_1252 As Long = 2

'--- TPageCoord --------------------------------------------------------------------
Const pcTopDown As Long = 1

'--- TCheckBoxChar -----------------------------------------------------------------
Const ccCircle As Long = 1

'--- TFieldColor / TBorderStyle / TPDFColorSpace ------------------------------------
Const fcBackColor As Long = 0
Const bsBevelled As Long = 1
Const csDeviceRGB As Long = 0

'--- TFieldFlags ---------------------------------------------------------------------
Const ffRadioIsUnion As Long = &H2000000

'--- TObjType / TObjEvent ------------------------------------------------------------
Const otField As Long = 4
Const oeOnMouseUp As Long = 3

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim act As Long, f As Long, r As Long
    Dim y As Double
    Dim outFile As String

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True           ' turn engine errors into VB6 errors

    pdf.CreateNewPDFW ""                 ' the output file is opened later

    pdf.SetPageCoords pcTopDown

    pdf.Append
    pdf.SetFontW "Helvetica", FS_REGULAR, 10#, False, CP_1252
    pdf.WriteTextW 50#, 50#, "Normal check boxes."

    pdf.ChangeFontSize 1#
    f = pdf.CreateCheckBox("N1", "C1", 1, -1, 50#, 70#, 20#, 20#)
    pdf.SetCheckBoxDefState f, True
    f = pdf.CreateCheckBox("N2", "C2", 1, -1, 80#, 70#, 20#, 20#)
    pdf.SetCheckBoxDefState f, True
    f = pdf.CreateCheckBox("N3", "C1", 1, -1, 110#, 70#, 20#, 20#)
    pdf.SetCheckBoxDefState f, True

    pdf.ChangeFontSize 10#
    pdf.WriteTextW 50#, 100#, "Field group with check boxes."

    pdf.ChangeFontSize 1#
    pdf.CreateCheckBox "G1", "C1", 0, -1, 50#, 120#, 20#, 20#
    pdf.CreateCheckBox "G1", "C2", 0, -1, 80#, 120#, 20#, 20#
    pdf.CreateCheckBox "G1", "C1", 1, -1, 110#, 120#, 20#, 20#

    pdf.ChangeFontSize 10#
    pdf.WriteFTextExW 50#, 150#, 220#, -1#, taLeft, "This group works like a radio button but only radio buttons get a round border if the check box character is set to ccCircle. No problem, set the border width to zero and draw the circle in background if needed."

    y = pdf.GetPageHeight() - pdf.GetLastTextPosY() + 10#

    pdf.ChangeFontSize 1#
    pdf.SetCheckBoxChar ccCircle
    pdf.CreateCheckBox "G2", "C1", 0, -1, 50#, y, 20#, 20#
    pdf.CreateCheckBox "G2", "C2", 0, -1, 80#, y, 20#, 20#
    pdf.CreateCheckBox "G2", "C3", 1, -1, 110#, y, 20#, 20#

    pdf.ChangeFontSize 10#
    pdf.WriteFTextExW 300#, 50#, 250#, -1#, taLeft, "This is a radio button. Since Acrobat 7 it is no longer possible to deselect the active check box, except with a reset form or Javascript action."

    y = pdf.GetPageHeight() - pdf.GetLastTextPosY() + 10#

    pdf.ChangeFontSize 15#
    r = pdf.CreateRadioButton("Radio1", "R1", 1, -1, 300#, y, 20#, 20#)
    pdf.SetCheckBoxDefState r, False
    pdf.CreateCheckBox "", "R2", 0, r, 330#, y, 20#, 20#
    pdf.CreateCheckBox "", "R3", 0, r, 360#, y, 20#, 20#

    pdf.ChangeFontSize 10#
    f = pdf.CreateButtonA("Reset", "Reset", -1, 400#, y, 60#, 20#)
    pdf.SetFieldColor f, fcBackColor, csDeviceRGB, clLtGray
    pdf.SetFieldBorderStyle f, bsBevelled

    act = pdf.CreateResetAction()
    pdf.AddActionToObj otField, oeOnMouseUp, act, f
    pdf.AddFieldToFormAction act, r, True

    y = y + 40#
    pdf.ChangeFontSize 10#
    pdf.WriteFTextExW 300#, y, 250#, -1#, taLeft, "The RadioIsUnion flag has only an effect if at least two check boxes use the same export value."
    y = pdf.GetPageHeight() - pdf.GetLastTextPosY() + 10#

    pdf.ChangeFontSize 15#
    r = pdf.CreateRadioButton("Radio2", "R1", 1, -1, 300#, y, 20#, 20#)
    pdf.SetFieldFlags r, ffRadioIsUnion, False
    pdf.CreateCheckBox "", "R2", 0, r, 330#, y, 20#, 20#
    pdf.CreateCheckBox "", "R1", 1, r, 360#, y, 20#, 20#
    pdf.CreateCheckBox "", "R2", 0, r, 390#, y, 20#, 20#
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
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "check_boxes (ActiveX)"
End Sub

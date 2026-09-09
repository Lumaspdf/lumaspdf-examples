Attribute VB_Name = "modFormFields"
Option Explicit
' ============================================================================
'  form_fields -- LumasPdf ActiveX/COM component style (late-bound, no
'  project reference needed). Equivalent of the flat-DLL/CPDF.cls example at
'  examples\Vb6\acroform\form_fields -- same feature: text fields
'  (single/multi-line/password/comb), combo boxes, list boxes, an editable
'  combo box, check boxes and radio buttons.
'
'  Method mapping vs. the CPDF.cls reference (pdf.Xxx -> pdf.Xxx, same names,
'  just late-bound to the registered "LumasPdf.PDF" COM server instead of the
'  native wrapper class):
'    pdf.CreateNewPDF ""        -> pdf.CreateNewPDFW ""
'    pdf.SetFont ...            -> pdf.SetFontW ...
'    pdf.WriteText ...          -> pdf.WriteTextW ...
'    pdf.SetTextFieldValueA ... -> pdf.SetTextFieldValueA ...  (kept -- explicit A in reference)
'    pdf.AddValToChoiceFieldA . -> pdf.AddValToChoiceFieldA .. (kept -- explicit A in reference)
'    pdf.OpenOutputFile ...     -> pdf.OpenOutputFileW ...
'  All other calls (CreateTextField, CreateComboBox, CreateListBox,
'  CreateCheckBox, CreateRadioButton, SetFieldFlags, SetFieldExpValue,
'  SetCheckBoxChar, ChangeFontSize, SetPageCoords, Append, EndPage,
'  HaveOpenDoc, CloseFile) map 1:1, just with the instance handle dropped.
' ============================================================================

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

'--- TFieldFlags ---------------------------------------------------------------------
Const ffPassword As Long = &H2000
Const ffComb As Long = &H1000000
Const ffEdit As Long = &H40000
Const ffRadioIsUnion As Long = &H2000000

Public Sub Main()
    On Error GoTo ErrHandler

    Dim pdf As Object
    Dim f As Long, r As Long
    Dim y As Double
    Dim outFile As String

    Set pdf = CreateObject("LumasPdf.PDF")
    pdf.RaiseExceptions = True           ' turn engine errors into VB6 errors

    pdf.CreateNewPDFW ""

    pdf.SetPageCoords pcTopDown

    pdf.Append
    y = 50#
    pdf.SetFontW "Helvetica", FS_REGULAR, 10#, False, CP_1252
    pdf.WriteTextW 50#, y, "Text fields:"

    y = y + 15#
    f = pdf.CreateTextField("Text1", -1, 0, 0, 50#, y, 200#, 20#)
    pdf.SetTextFieldValueA f, "", "Single line text...", taLeft

    y = y + 30#
    f = pdf.CreateTextField("Text2", -1, 1, 0, 50#, y, 200#, 50#)
    pdf.SetTextFieldValueA f, "", "This field accepts multi-line text. The maximum text length can be restricted if necessary.", taLeft

    y = y + 60#
    pdf.WriteTextW 50#, y, "A password field:"
    y = y + 15#
    f = pdf.CreateTextField("Text3", -1, 0, 0, 50#, y, 200#, 20#)
    pdf.SetFieldFlags f, ffPassword, False
    pdf.SetTextFieldValueA f, "", "**********", taLeft

    y = y + 30#
    pdf.WriteTextW 50#, y, "A fixed length field separated into combs:"
    y = y + 15#
    f = pdf.CreateTextField("Text4", -1, 0, 10, 50#, y, 200#, 20#)
    pdf.SetFieldFlags f, ffComb, False

    y = 50#
    pdf.WriteTextW 350#, y, "Choice fields:"
    y = y + 15#
    f = pdf.CreateComboBox("Combo1", 1, -1, 350#, y, 200#, 20#)
    pdf.AddValToChoiceFieldA f, "", " Select a value...", True
    pdf.AddValToChoiceFieldA f, "Apple", "Apple", False
    pdf.AddValToChoiceFieldA f, "Banana", "Banana", False
    pdf.AddValToChoiceFieldA f, "Pear", "Pear", False
    pdf.AddValToChoiceFieldA f, "Grape", "Grape", False
    pdf.AddValToChoiceFieldA f, "Orange", "Orange", False

    y = y + 30#
    f = pdf.CreateListBox("List", 1, -1, 350#, y, 200#, 50#)
    pdf.AddValToChoiceFieldA f, "Apple", "Apple", False
    pdf.AddValToChoiceFieldA f, "Banana", "Banana", True
    pdf.AddValToChoiceFieldA f, "Pear", "Pear", False
    pdf.AddValToChoiceFieldA f, "Grape", "Grape", False
    pdf.AddValToChoiceFieldA f, "Orange", "Orange", False

    y = y + 60#
    pdf.WriteTextW 350#, y, "Editable combo box:"
    y = y + 15#
    f = pdf.CreateComboBox("Combo2", 1, -1, 350#, y, 200#, 20#)
    pdf.AddValToChoiceFieldA f, "Apple", "Apple", False
    pdf.AddValToChoiceFieldA f, "Banana", "Banana", False
    pdf.AddValToChoiceFieldA f, "Pear", "Pear", False
    pdf.AddValToChoiceFieldA f, "Grape", "Grape", False
    pdf.AddValToChoiceFieldA f, "Orange", "Orange", False
    pdf.SetFieldFlags f, ffEdit, False
    pdf.SetFieldExpValue f, 1000, "Select or enter a value...", "", True

    y = y + 30#
    pdf.WriteTextW 350#, y, "Check boxes / Radio buttons:"

    y = y + 15#
    pdf.ChangeFontSize 1#
    pdf.CreateCheckBox "N1", "C1", 1, -1, 350#, y, 20#, 20#
    pdf.CreateCheckBox "N2", "C2", 1, -1, 380#, y, 20#, 20#
    pdf.CreateCheckBox "N3", "C1", 1, -1, 410#, y, 20#, 20#

    pdf.CreateCheckBox "G1", "C1", 0, -1, 450#, y, 20#, 20#
    pdf.CreateCheckBox "G1", "C2", 0, -1, 480#, y, 20#, 20#
    pdf.CreateCheckBox "G1", "C1", 1, -1, 510#, y, 20#, 20#
    pdf.CreateCheckBox "G1", "C2", 0, -1, 540#, y, 20#, 20#

    y = y + 30#
    pdf.ChangeFontSize 15#
    pdf.SetCheckBoxChar ccCircle
    r = pdf.CreateRadioButton("Radio1", "R1", 1, -1, 350#, y, 20#, 20#)
    pdf.SetCheckBoxDefState r, False
    pdf.CreateCheckBox "", "R2", 0, r, 380#, y, 20#, 20#
    pdf.CreateCheckBox "", "R3", 0, r, 410#, y, 20#, 20#

    r = pdf.CreateRadioButton("Radio2", "R1", 1, -1, 450#, y, 20#, 20#)
    pdf.SetFieldFlags r, ffRadioIsUnion, False
    pdf.CreateCheckBox "", "R2", 0, r, 480#, y, 20#, 20#
    pdf.CreateCheckBox "", "R1", 1, r, 510#, y, 20#, 20#
    pdf.CreateCheckBox "", "R2", 0, r, 540#, y, 20#, 20#
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
    MsgBox "Failed: " & Err.Description & extra, vbCritical, "form_fields (ActiveX)"
End Sub

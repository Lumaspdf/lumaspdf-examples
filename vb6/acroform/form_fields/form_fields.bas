Attribute VB_Name = "modFormFields"
Option Explicit
' ============================================================================
'  form_fields -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules (early-bound to
'  CPDF). Text fields (single/multi-line/password/comb), combo boxes,
'  list boxes, editable combo, check boxes and radio buttons.
' ============================================================================

Public Sub Main()
    Dim pdf As New CPDF
    Dim f As Long, r As Long
    Dim y As Double
    Dim outFile As String

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""

    pdf.SetPageCoords pcTopDown

    pdf.Append
    y = 50#
    pdf.SetFont "Helvetica", fsRegular, 10#, False, cp1252
    pdf.WriteText 50#, y, "Text fields:"

    y = y + 15#
    f = pdf.CreateTextField("Text1", -1, 0, 0, 50#, y, 200#, 20#)
    pdf.SetTextFieldValueA f, "", "Single line text...", taLeft

    y = y + 30#
    f = pdf.CreateTextField("Text2", -1, 1, 0, 50#, y, 200#, 50#)
    pdf.SetTextFieldValueA f, "", "This field accepts multi-line text. The maximum text length can be restricted if necessary.", taLeft

    y = y + 60#
    pdf.WriteText 50#, y, "A password field:"
    y = y + 15#
    f = pdf.CreateTextField("Text3", -1, 0, 0, 50#, y, 200#, 20#)
    pdf.SetFieldFlags f, ffPassword, 0
    pdf.SetTextFieldValueA f, "", "**********", taLeft

    y = y + 30#
    pdf.WriteText 50#, y, "A fixed length field separated into combs:"
    y = y + 15#
    f = pdf.CreateTextField("Text4", -1, 0, 10, 50#, y, 200#, 20#)
    pdf.SetFieldFlags f, ffComb, 0

    y = 50#
    pdf.WriteText 350#, y, "Choice fields:"
    y = y + 15#
    f = pdf.CreateComboBox("Combo1", 1, -1, 350#, y, 200#, 20#)
    pdf.AddValToChoiceFieldA f, "", " Select a value...", 1
    pdf.AddValToChoiceFieldA f, "Apple", "Apple", 0
    pdf.AddValToChoiceFieldA f, "Banana", "Banana", 0
    pdf.AddValToChoiceFieldA f, "Pear", "Pear", 0
    pdf.AddValToChoiceFieldA f, "Grape", "Grape", 0
    pdf.AddValToChoiceFieldA f, "Orange", "Orange", 0

    y = y + 30#
    f = pdf.CreateListBox("List", 1, -1, 350#, y, 200#, 50#)
    pdf.AddValToChoiceFieldA f, "Apple", "Apple", 0
    pdf.AddValToChoiceFieldA f, "Banana", "Banana", 1
    pdf.AddValToChoiceFieldA f, "Pear", "Pear", 0
    pdf.AddValToChoiceFieldA f, "Grape", "Grape", 0
    pdf.AddValToChoiceFieldA f, "Orange", "Orange", 0

    y = y + 60#
    pdf.WriteText 350#, y, "Editable combo box:"
    y = y + 15#
    f = pdf.CreateComboBox("Combo2", 1, -1, 350#, y, 200#, 20#)
    pdf.AddValToChoiceFieldA f, "Apple", "Apple", 0
    pdf.AddValToChoiceFieldA f, "Banana", "Banana", 0
    pdf.AddValToChoiceFieldA f, "Pear", "Pear", 0
    pdf.AddValToChoiceFieldA f, "Grape", "Grape", 0
    pdf.AddValToChoiceFieldA f, "Orange", "Orange", 0
    pdf.SetFieldFlags f, ffEdit, 0
    pdf.SetFieldExpValue f, 1000, "Select or enter a value...", "", 1

    y = y + 30#
    pdf.WriteText 350#, y, "Check boxes / Radio buttons:"

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
    pdf.SetCheckBoxDefState r, 0
    pdf.CreateCheckBox "", "R2", 0, r, 380#, y, 20#, 20#
    pdf.CreateCheckBox "", "R3", 0, r, 410#, y, 20#, 20#

    r = pdf.CreateRadioButton("Radio2", "R1", 1, -1, 450#, y, 20#, 20#)
    pdf.SetFieldFlags r, ffRadioIsUnion, 0
    pdf.CreateCheckBox "", "R2", 0, r, 480#, y, 20#, 20#
    pdf.CreateCheckBox "", "R1", 1, r, 510#, y, 20#, 20#
    pdf.CreateCheckBox "", "R2", 0, r, 540#, y, 20#, 20#
    pdf.EndPage

    If pdf.HaveOpenDoc() <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile() <> 0 Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
End Sub

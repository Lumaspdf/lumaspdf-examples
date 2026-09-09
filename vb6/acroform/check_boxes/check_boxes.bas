Attribute VB_Name = "modCheckBoxes"
Option Explicit
' ============================================================================
'  check_boxes -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules.
'  Early-bound to the wrappers/vb6 native modules (CPDF / LumasPDFInt) (one Reference in the .vbp): the
'  OO object plus ALL enums/constants come straight from the typelib. Errors
' pdf.RaiseExceptions = True
'  Normal check boxes, field groups (radio-like), radio buttons and a reset
'  action.
' ============================================================================

Private Const clLtGray As Long = 12632256   ' VCL clLtGray (= clSilver)

Public Sub Main()
    Dim pdf As New CPDF
    Dim act As Long, f As Long, r As Long
    Dim y As Double
    Dim outFile As String

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""      ' The output file is opened later

    pdf.SetPageCoords pcTopDown

    pdf.Append
    pdf.SetFont "Helvetica", fsRegular, 10#, False, cp1252
    pdf.WriteText 50#, 50#, "Normal check boxes."

    pdf.ChangeFontSize 1#
    f = pdf.CreateCheckBox("N1", "C1", 1, -1, 50#, 70#, 20#, 20#)
    pdf.SetCheckBoxDefState f, 1
    f = pdf.CreateCheckBox("N2", "C2", 1, -1, 80#, 70#, 20#, 20#)
    pdf.SetCheckBoxDefState f, 1
    f = pdf.CreateCheckBox("N3", "C1", 1, -1, 110#, 70#, 20#, 20#)
    pdf.SetCheckBoxDefState f, 1

    pdf.ChangeFontSize 10#
    pdf.WriteText 50#, 100#, "Field group with check boxes."

    pdf.ChangeFontSize 1#
    pdf.CreateCheckBox "G1", "C1", 0, -1, 50#, 120#, 20#, 20#
    pdf.CreateCheckBox "G1", "C2", 0, -1, 80#, 120#, 20#, 20#
    pdf.CreateCheckBox "G1", "C1", 1, -1, 110#, 120#, 20#, 20#

    pdf.ChangeFontSize 10#
    pdf.WriteFTextEx 50#, 150#, 220#, -1#, taLeft, "This group works like a radio button but only radio buttons get a round border if the check box character is set to ccCircle. No problem, set the border width to zero and draw the circle in background if needed."

    y = pdf.GetPageHeight() - pdf.GetLastTextPosY() + 10#

    pdf.ChangeFontSize 1#
    pdf.SetCheckBoxChar ccCircle
    pdf.CreateCheckBox "G2", "C1", 0, -1, 50#, y, 20#, 20#
    pdf.CreateCheckBox "G2", "C2", 0, -1, 80#, y, 20#, 20#
    pdf.CreateCheckBox "G2", "C3", 1, -1, 110#, y, 20#, 20#

    pdf.ChangeFontSize 10#
    pdf.WriteFTextEx 300#, 50#, 250#, -1#, taLeft, "This is a radio button. Since Acrobat 7 it is no longer possible to deselect the active check box, except with a reset form or Javascript action."

    y = pdf.GetPageHeight() - pdf.GetLastTextPosY() + 10#

    pdf.ChangeFontSize 15#
    r = pdf.CreateRadioButton("Radio1", "R1", 1, -1, 300#, y, 20#, 20#)
    pdf.SetCheckBoxDefState r, 0
    pdf.CreateCheckBox "", "R2", 0, r, 330#, y, 20#, 20#
    pdf.CreateCheckBox "", "R3", 0, r, 360#, y, 20#, 20#

    pdf.ChangeFontSize 10#
    f = pdf.CreateButtonA("Reset", "Reset", -1, 400#, y, 60#, 20#)
    pdf.SetFieldColor f, fcBackColor, csDeviceRGB, clLtGray
    pdf.SetFieldBorderStyle f, bsBevelled

    act = pdf.CreateResetAction()
    pdf.AddActionToObj otField, oeOnMouseUp, act, f
    pdf.AddFieldToFormAction act, r, 1

    y = y + 40#
    pdf.ChangeFontSize 10#
    pdf.WriteFTextEx 300#, y, 250#, -1#, taLeft, "The RadioIsUnion flag has only an effect if at least two check boxes use the same export value."
    y = pdf.GetPageHeight() - pdf.GetLastTextPosY() + 10#

    pdf.ChangeFontSize 15#
    r = pdf.CreateRadioButton("Radio2", "R1", 1, -1, 300#, y, 20#, 20#)
    pdf.SetFieldFlags r, ffRadioIsUnion, 0
    pdf.CreateCheckBox "", "R2", 0, r, 330#, y, 20#, 20#
    pdf.CreateCheckBox "", "R1", 1, r, 360#, y, 20#, 20#
    pdf.CreateCheckBox "", "R2", 0, r, 390#, y, 20#, 20#
    pdf.EndPage

    If pdf.HaveOpenDoc() <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile() <> 0 Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
End Sub

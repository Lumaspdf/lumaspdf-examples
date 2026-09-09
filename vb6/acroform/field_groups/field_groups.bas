Attribute VB_Name = "modFieldGroups"
Option Explicit
' ============================================================================
'  field_groups -- Native C API DLL wrapper style (wrappers/vb6), ZERO wrapper modules (early-bound to
'  CPDF). Several text fields sharing one value (a field group), with
'  auto-size vs fixed font size, plus a reset button.
' ============================================================================

Private Const clLtGray As Long = 12632256   ' VCL clLtGray (= clSilver)

Public Sub Main()
    Dim pdf As New CPDF
    Dim act As Long, f As Long
    Dim base As Double, y As Double
    Dim outFile As String
    Dim cr As String

    cr = Chr$(13)

' pdf.RaiseExceptions = True
    pdf.CreateNewPDF ""

    pdf.SetPageCoords pcTopDown

    pdf.Append
    pdf.SetFont "Helvetica", fsRegular, 12#, False, cp1252
    pdf.SetLeading 14#
    pdf.WriteFTextEx 50#, 50#, pdf.GetPageWidth() - 100#, -1#, taJustify, _
        "The six text fields share the same value. Such an array of fields is called a field group. All fields in the group must be of the same type." & cr & cr & _
        "A field group can be created in two different ways: either create two or more fields with the same name or pass the handle of the base field as Parent to the children. " & _
        "The latter way is more efficient since it is not required to search for the parent field when a child will be created." & cr & cr & _
        "Enter some more text into a field to see the difference between auto size and fixed font size."

    ' GetLastTextPosY() returns bottom up coordinates. We must subtract from the page height.
    base = pdf.GetPageHeight() - pdf.GetLastTextPosY() + 20#

    pdf.WriteFTextEx 50#, base, 200#, -1#, taLeft, "Font size <= 1.0 means auto size."

    y = pdf.GetPageHeight() - pdf.GetLastTextPosY() + 10#

    pdf.ChangeFontSize 1#
    f = pdf.CreateTextField("Auto", -1, 0, 0, 50#, y, 200#, 20#)
    pdf.SetTextFieldValueA f, "Some text...", "Some text...", taLeft

    y = y + 30#
    pdf.CreateTextField "", f, 0, 0, 50#, y, 200#, 30#

    y = y + 40#
    pdf.CreateTextField "", f, 0, 0, 50#, y, 200#, 40#

    pdf.ChangeFontSize 12#
    pdf.WriteFTextEx 345#, base, 200#, -1#, taLeft, "The same fields with a fixed font size."

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

    If pdf.HaveOpenDoc() <> 0 Then
        outFile = App.Path & "\out.pdf"
        If pdf.OpenOutputFile(outFile) = 0 Then Exit Sub
        If pdf.CloseFile() <> 0 Then
            Debug.Print "PDF file """ & outFile & """ successfully created!"
        End If
    End If
End Sub
